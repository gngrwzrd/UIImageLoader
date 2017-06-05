
#import "UIImageLoader.h"
#import <objc/runtime.h>

/* UIImageMemoryCache */
@interface UIImageMemoryCache ()
@property NSCache * cache;
@end

@implementation UIImageMemoryCache

- (id) init {
	self = [super init];
	self.cache = [[NSCache alloc] init];
	self.cache.totalCostLimit = 25 * (1024 * 1024); //25MB
	return self;
}

- (void) cacheImage:(UIImageLoaderImage *) image forURL:(NSURL *) url; {
	if(image) {
		NSUInteger cost = (image.size.width * image.size.height) * 4;
		[self.cache setObject:image forKey:url.path cost:cost];
	}
}

- (void) removeImageForURL:(NSURL *) url; {
	[self.cache removeObjectForKey:url.path];
}

- (void) purge; {
	[self.cache removeAllObjects];
}

@end

/* UIImageCacheData */
@interface UIImageCacheData : NSObject <NSCoding>
@property NSTimeInterval maxage;
@property NSString * etag;
@property NSString * lastModified;
@property BOOL nocache;
//for errors 4XX,5XX
@property NSInteger errorAttempts;
@property NSTimeInterval errorMaxage;
@property NSError * errorLast;
@end

/* UIImageLoader */
typedef void(^UIImageLoadedBlock)(UIImageLoaderImage * image);
typedef void(^NSURLAndDataWriteBlock)(NSURL * url, NSData * data);
typedef void(^UIImageLoaderURLCompletion)(NSError * error, NSURL * diskURL, UIImageLoadSource loadedFromSource);
typedef void(^UIImageLoaderDiskURLCompletion)(NSURL * diskURL);

//errors
NSString * const UIImageLoaderErrorDomain = @"com.gngrwzrd.UIImageLoader";
const NSInteger UIImageLoaderErrorNilURL = 1;

//default loader
static UIImageLoader * _default;

//private loader properties
@interface UIImageLoader ()
@property NSURLSession * activeSession;
@property NSURL * activeCacheDirectory;
@property NSString * auth;
@end

/* UIImageLoader */
@implementation UIImageLoader

+ (UIImageLoader *) defaultLoader {
	if(!_default) {
		_default = [[UIImageLoader alloc] init];
	}
	return _default;
}

- (id) init {
	NSURL * appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
	NSString * bundleId = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
	NSURL * defaultCacheDir = appSupport;
	if(bundleId) {
		defaultCacheDir = [defaultCacheDir URLByAppendingPathComponent:bundleId];
	}
	defaultCacheDir = [defaultCacheDir URLByAppendingPathComponent:@"UIImageLoader"];
	self = [self initWithCacheDirectory:defaultCacheDir];
	return self;
}

- (id) initWithCacheDirectory:(NSURL *) url; {
	self = [super init];
	self.cacheImagesInMemory = FALSE;
	self.trustAnySSLCertificate = FALSE;
	self.useServerCachePolicy = TRUE;
	self.logCacheMisses = TRUE;
	self.defaultCacheControlMaxAge = 0;
	self.memoryCache = [[UIImageMemoryCache alloc] init];
	self.cacheDirectory = url;
	self.defaultCacheControlMaxAgeForErrors = 0;
	self.maxAtemptsForErrors = 0;
	return self;
}

- (void) setCacheDirectory:(NSURL *) cacheDirectory {
	self.activeCacheDirectory = cacheDirectory;
	[[NSFileManager defaultManager] createDirectoryAtURL:cacheDirectory withIntermediateDirectories:TRUE attributes:nil error:nil];
}

- (NSURL *) cacheDirectory {
	return self.activeCacheDirectory;
}

- (void) setAuthUsername:(NSString *) username password:(NSString *) password; {
	if(username == nil || password == nil) {
		self.auth = nil;
		return;
	}
	NSString * authString = [NSString stringWithFormat:@"%@:%@",username,password];
	NSData * authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
	NSString * encoded = [authData base64EncodedStringWithOptions:0];
	self.auth = [NSString stringWithFormat:@"Basic %@",encoded];
}

- (void) setAuthorization:(NSMutableURLRequest *) request {
	if(self.auth) {
		[request setValue:self.auth forHTTPHeaderField:@"Authorization"];
	}
}

- (void) clearCachedFilesModifiedOlderThan1Day; {
	[self clearCachedFilesModifiedOlderThan:86400];
}

- (void) clearCachedFilesModifiedOlderThan1Week; {
	[self clearCachedFilesModifiedOlderThan:604800];
}

- (void) clearCachedFilesModifiedOlderThan:(NSTimeInterval) timeInterval; {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(background, ^{
		NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory.path error:nil];
		for(NSString * file in files) {
			NSURL * path = [self.cacheDirectory URLByAppendingPathComponent:file];
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path.path error:nil];
			NSDate * modified = attributes[NSFileModificationDate];
			NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:modified];
			if(diff > timeInterval) {
				NSLog(@"deleting cached file: %@",path.path);
				[[NSFileManager defaultManager] removeItemAtPath:path.path error:nil];
			}
		}
	});
}

- (void) clearCachedFilesCreatedOlderThan1Day; {
	[self clearCachedFilesCreatedOlderThan:86400];
}

- (void) clearCachedFilesCreatedOlderThan1Week; {
	[self clearCachedFilesCreatedOlderThan:604800];
}

- (void) clearCachedFilesCreatedOlderThan:(NSTimeInterval) timeInterval; {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(background, ^{
		NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory.path error:nil];
		for(NSString * file in files) {
			NSURL * path = [self.cacheDirectory URLByAppendingPathComponent:file];
			NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path.path error:nil];
			NSDate * created = attributes[NSFileCreationDate];
			NSTimeInterval diff = [[NSDate date] timeIntervalSinceDate:created];
			if(diff > timeInterval) {
				NSLog(@"deleting cached file: %@",path.path);
				[[NSFileManager defaultManager] removeItemAtPath:path.path error:nil];
			}
		}
	});
}

- (void) purgeDiskCache; {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(background, ^{
		NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.cacheDirectory.path error:nil];
		for(NSString * file in files) {
			NSURL * path = [self.cacheDirectory URLByAppendingPathComponent:file];
			NSLog(@"deleting cached file: %@",path.path);
			[[NSFileManager defaultManager] removeItemAtPath:path.path error:nil];
		}
	});
}

- (void) purgeMemoryCache; {
	[self.memoryCache purge];
}

- (void) setMemoryCacheMaxBytes:(NSUInteger) maxBytes; {
	self.memoryCache.maxBytes = maxBytes;
}

- (void) setSession:(NSURLSession *) session {
	self.activeSession = session;
	if(session.delegate && self.trustAnySSLCertificate) {
		if(![session.delegate respondsToSelector:@selector(URLSession:didReceiveChallenge:completionHandler:)]) {
			NSLog(@"[UIImageLoader] WARNING: You set a custom NSURLSession and require trustAnySSLCertificate but your "
				  @"session delegate doesn't respond to URLSession:didReceiveChallenge:completionHandler:");
		}
	}
}

- (NSURLSession *) session {
	if(self.activeSession) {
		return self.activeSession;
	}
	
	NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
	self.activeSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
	
	return self.activeSession;
}

- (void) URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
	if(self.trustAnySSLCertificate) {
		completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
	} else {
		completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
	}
}

- (NSURL *) localFileURLForURL:(NSURL *) url {
	if(!url) {
		return NULL;
	}
	NSString * path = [url.absoluteString stringByRemovingPercentEncoding];
	NSString * path2 = [path stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"https://" withString:@""];
	path2 = [path2 stringByReplacingOccurrencesOfString:@":" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"?" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	path2 = [path2 stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return [self.cacheDirectory URLByAppendingPathComponent:path2];
}

- (NSURL *) localCacheControlFileURLForURL:(NSURL *) url {
	if(!url) {
		return NULL;
	}
	NSURL * localImageFile = [self localFileURLForURL:url];
	NSString * path = [localImageFile.path stringByAppendingString:@".cc"];
	return [NSURL fileURLWithPath:path];
}

- (NSDate *) createdDateForFileURL:(NSURL *) url {
	NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
	if(!attributes) {
		return nil;
	}
	return attributes[NSFileCreationDate];
}

- (void) writeData:(NSData *) data toFile:(NSURL *) cachedURL writeCompletion:(NSURLAndDataWriteBlock) writeCompletion {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(background, ^{
		[data writeToFile:cachedURL.path atomically:TRUE];
		if(writeCompletion) {
			writeCompletion(cachedURL,data);
		}
	});
}

- (void) writeCacheControlData:(UIImageCacheData *) cache toFile:(NSURL *) cachedURL {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(background, ^{
		NSData * data = [NSKeyedArchiver archivedDataWithRootObject:cache];
		[data writeToFile:cachedURL.path atomically:TRUE];
		NSDictionary * attributes = @{NSFileModificationDate:[NSDate date]};
		[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:cachedURL.path error:nil];
	});
}

- (void) loadImageInBackground:(NSURL *) diskURL completion:(UIImageLoadedBlock) completion {
	dispatch_queue_t background = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
	dispatch_async(background, ^{
		NSDate * modified = [NSDate date];
		NSDictionary * attributes = @{NSFileModificationDate:modified};
		[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:diskURL.path error:nil];
		NSURL * cachedInfoFile = [diskURL URLByAppendingPathExtension:@"cc"];
		[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:cachedInfoFile.path error:nil];
		UIImageLoaderImage * image = [[UIImageLoaderImage alloc] initWithContentsOfFile:diskURL.path];
		if(completion) {
			completion(image);
		}
	});
}

- (void) setCacheControlForCacheInfo:(UIImageCacheData *) cacheInfo fromCacheControlString:(NSString *) cacheControl {
	if([cacheControl isEqualToString:@"no-cache"]) {
		cacheInfo.nocache = TRUE;
		return;
	}
	
	NSScanner * scanner = [[NSScanner alloc] initWithString:cacheControl];
	NSString * prelim = nil;
	[scanner scanUpToString:@"=" intoString:&prelim];
	[scanner scanString:@"=" intoString:nil];
	
	double maxage = -1;
	[scanner scanDouble:&maxage];
	if(maxage > -1) {
		cacheInfo.maxage = (NSTimeInterval)maxage;
	}
}

- (NSURLSessionDataTask *) cacheImageWithRequestUsingCacheControl:(NSURLRequest *) request
	hasCache:(UIImageLoaderDiskURLCompletion) hasCache
	sendingRequest:(UIImageLoader_SendingRequestBlock) sendingRequest
	requestCompleted:(UIImageLoaderURLCompletion) requestCompleted {
	
	if(!request.URL || request.URL.absoluteString.length < 1) {
		requestCompleted([NSError errorWithDomain:UIImageLoaderErrorDomain code:UIImageLoaderErrorNilURL userInfo:@{NSLocalizedDescriptionKey:@"The request URL is nil or empty."}],nil,UIImageLoadSourceNone);
	}
	
	//make mutable request
	NSMutableURLRequest * mutableRequest = [request mutableCopy];
	[self setAuthorization:mutableRequest];
	
	//get cache file urls
	NSURL * cacheInfoFile = [self localCacheControlFileURLForURL:request.URL];
	NSURL * cachedImageURL = [self localFileURLForURL:request.URL];
	
	//setup blank cache object
	UIImageCacheData * cached = nil;
	
	//load cached info file if it exists.
	if([[NSFileManager defaultManager] fileExistsAtPath:cacheInfoFile.path]) {
		cached = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheInfoFile.path];
	} else {
		cached = [[UIImageCacheData alloc] init];
	}
	
	//check max age
	NSDate * now = [NSDate date];
	NSDate * createdDate = [self createdDateForFileURL:cachedImageURL];
	NSTimeInterval diff = [now timeIntervalSinceDate:createdDate];
	BOOL cacheValid = FALSE;
	
	//check cache expiration
	if(!cached.nocache && cached.maxage > 0 && diff < cached.maxage) {
		cacheValid = TRUE;
	}
	
	//check error attempts and max error age
	if(cached.errorLast) {
		NSDate * cacheInfoFileCreatedDate = [self createdDateForFileURL:cacheInfoFile];
		NSTimeInterval errorDiff = [now timeIntervalSinceDate:cacheInfoFileCreatedDate];
		if(!cached.nocache && cached.errorAttempts >= self.maxAtemptsForErrors && cached.errorMaxage > 0 && errorDiff < cached.errorMaxage) {
			requestCompleted(cached.errorLast,nil,UIImageLoadSourceNone);
			return nil;
		}
	}
	
	BOOL didSendCacheCompletion = FALSE;
	
	//file exists.
	if([[NSFileManager defaultManager] fileExistsAtPath:cachedImageURL.path]) {
		if(cacheValid) {
			hasCache(cachedImageURL);
			return nil;
		} else {
			didSendCacheCompletion = TRUE;
			//call hasCache completion and continue load below
			hasCache(cachedImageURL);
		}
	} else {
		if(self.logCacheMisses) {
			NSLog(@"[UIImageLoader] cache miss for url: %@",request.URL);
		}
	}
	
	//ignore built in cache from networking code. handled here instead.
	mutableRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	//add etag if available
	if(cached.etag) {
		[mutableRequest setValue:cached.etag forHTTPHeaderField:@"If-None-Match"];
	}
	
	//add last modified if available
	if(cached.lastModified) {
		[mutableRequest setValue:cached.lastModified forHTTPHeaderField:@"If-Modified-Since"];
	}
	
	//reset error cache info file if necessary.
	if(cached.errorLast) {
		cached.errorLast = nil;
	}
	if(cached.errorAttempts >= self.maxAtemptsForErrors) {
		cached.errorAttempts = 0;
	}
	
	sendingRequest(didSendCacheCompletion);
	
	NSURLSessionDataTask * task = [[self session] dataTaskWithRequest:mutableRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
		NSDictionary * headers = [httpResponse allHeaderFields];
		
		//304 Not Modified use cache
		if(httpResponse.statusCode == 304) {
			
			if(headers[@"Cache-Control"]) {
				
				[self setCacheControlForCacheInfo:cached fromCacheControlString:headers[@"Cache-Control"]];
				[self writeCacheControlData:cached toFile:cacheInfoFile];
			
			} else {
				
				cached.maxage = self.defaultCacheControlMaxAge;
				[self writeCacheControlData:cached toFile:cacheInfoFile];
				
			}
			
			requestCompleted(nil,cachedImageURL,UIImageLoadSourceNetworkNotModified);
			return;
		}
		
		//4XX, 5XX errors we can possibly cache.
		if(httpResponse.statusCode > 399 && httpResponse.statusCode < 600) {
			NSString * errorString = [NSString stringWithFormat:@"Request failed with error code %li", (long)httpResponse.statusCode];
			NSDictionary * info = @{NSLocalizedDescriptionKey:errorString};
			NSError * error = [[NSError alloc] initWithDomain:UIImageLoaderErrorDomain code:httpResponse.statusCode userInfo:info];
			if(self.defaultCacheControlMaxAgeForErrors > 0) {
				cached.errorAttempts++;
			}
			cached.errorLast = error;
			cached.errorMaxage = self.defaultCacheControlMaxAgeForErrors;
			[self writeCacheControlData:cached toFile:cacheInfoFile];
			requestCompleted(error,nil,UIImageLoadSourceNone);
			
			return;
		}
		
		//error
		if(httpResponse.statusCode < 200 && httpResponse.statusCode > 299 && error) {
			requestCompleted(error,nil,UIImageLoadSourceNone);
			return;
		}
		
		//check for Cache-Control
		if(headers[@"Cache-Control"]) {
			[self setCacheControlForCacheInfo:cached fromCacheControlString:headers[@"Cache-Control"]];
		} else {
			cached.maxage = self.defaultCacheControlMaxAge;
		}
		
		//check for ETag
		if(headers[@"ETag"]) {
			cached.etag = headers[@"ETag"];
		}
		
		//check for Last Modified
		if(headers[@"Last-Modified"]) {
			cached.lastModified = headers[@"Last-Modified"];
		}
		
		//save cached info file
		[self writeCacheControlData:cached toFile:cacheInfoFile];
		
		//save image to disk
		[self writeData:data toFile:cachedImageURL writeCompletion:^(NSURL *url, NSData *data) {
			requestCompleted(nil,cachedImageURL,UIImageLoadSourceNetworkToDisk);
		}];
	}];
	
	[task resume];
	
	return task;
}

- (NSURLSessionDataTask *) cacheImageWithRequest:(NSURLRequest *) request
	hasCache:(UIImageLoaderDiskURLCompletion) hasCache
	sendingRequest:(UIImageLoader_SendingRequestBlock) sendingRequest
	requestComplete:(UIImageLoaderURLCompletion) requestComplete {
	
	//if use server cache policies, use other method.
	if(self.useServerCachePolicy) {
		return [self cacheImageWithRequestUsingCacheControl:request hasCache:hasCache sendingRequest:sendingRequest requestCompleted:requestComplete];
	}
	
	if(!request.URL || request.URL.absoluteString.length < 1) {
		requestComplete([NSError errorWithDomain:UIImageLoaderErrorDomain code:UIImageLoaderErrorNilURL userInfo:@{NSLocalizedDescriptionKey:@"The request URL is nil or empty."}],nil,UIImageLoadSourceNone);
	}
	
	//make mutable request
	NSMutableURLRequest * mutableRequest = [request mutableCopy];
	[self setAuthorization:mutableRequest];
	
	NSURL * cachedURL = [self localFileURLForURL:mutableRequest.URL];
	if([[NSFileManager defaultManager] fileExistsAtPath:cachedURL.path]) {
		hasCache(cachedURL);
		return nil;
	}
	
	if(self.logCacheMisses) {
		NSLog(@"[UIImageLoader] cache miss for url: %@",mutableRequest.URL);
	}
	
	sendingRequest(FALSE);
	
	NSURLSessionDataTask * task = [[self session] dataTaskWithRequest:mutableRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		if(error) {
			requestComplete(error,nil,UIImageLoadSourceNone);
			return;
		}
		
		NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
		if(httpResponse.statusCode != 200) {
			requestComplete(error,nil,UIImageLoadSourceNone);
			return;
		}
		
		if(data) {
			[self writeData:data toFile:cachedURL writeCompletion:^(NSURL *url, NSData *data) {
				requestComplete(nil,cachedURL,UIImageLoadSourceNetworkToDisk);
			}];
		}
	}];
	
	[task resume];
	
	return task;
}

- (NSURLSessionDataTask *) loadImageWithRequest:(NSURLRequest *) request
									   hasCache:(UIImageLoader_HasCacheBlock) hasCache
									sendingRequest:(UIImageLoader_SendingRequestBlock) sendingRequest
							   requestCompleted:(UIImageLoader_RequestCompletedBlock) requestCompleted; {
	
	//check memory cache
	UIImageLoaderImage * image = [self.memoryCache.cache objectForKey:request.URL.path];
	if(image) {
		dispatch_async(dispatch_get_main_queue(), ^{
			hasCache(image,UIImageLoadSourceMemory);
		});
		return nil;
	}
	
	return [self cacheImageWithRequest:request hasCache:^(NSURL *diskURL) {
		
		[self loadImageInBackground:diskURL completion:^(UIImageLoaderImage *image) {
			if(self.cacheImagesInMemory) {
				[self.memoryCache cacheImage:image forURL:request.URL];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				hasCache(image,UIImageLoadSourceDisk);
			});
		}];
		
	} sendingRequest:^(BOOL didHaveCache) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			sendingRequest(didHaveCache);
		});
		
	} requestComplete:^(NSError *error, NSURL *diskURL, UIImageLoadSource loadedFromSource) {
		
		if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
			[self loadImageInBackground:diskURL completion:^(UIImageLoaderImage *image) {
				if(self.cacheImagesInMemory) {
					[self.memoryCache cacheImage:image forURL:request.URL];
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					requestCompleted(error,image,loadedFromSource);
				});
			}];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^{
				requestCompleted(error,nil,loadedFromSource);
			});
		}
		
	}];
}

- (NSURLSessionDataTask *) loadImageWithURL:(NSURL *) url
									   hasCache:(UIImageLoader_HasCacheBlock) hasCache
									sendingRequest:(UIImageLoader_SendingRequestBlock) sendingRequest
							   requestCompleted:(UIImageLoader_RequestCompletedBlock) requestCompleted; {
	NSURLRequest * request = [NSURLRequest requestWithURL:url];
	return [self loadImageWithRequest:request hasCache:hasCache sendingRequest:sendingRequest requestCompleted:requestCompleted];
}

@end

/********************/
/* UIImageCacheData */
/********************/

@implementation UIImageCacheData

- (id) init {
	self = [super init];
	self.maxage = 0;
	self.etag = nil;
	self.lastModified = nil;
	self.errorMaxage = 0;
	self.errorLast = nil;
	self.errorAttempts = 0;
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	NSKeyedUnarchiver * un = (NSKeyedUnarchiver *)aDecoder;
	self.maxage = [un decodeDoubleForKey:@"maxage"];
	self.etag = [un decodeObjectForKey:@"etag"];
	self.nocache = [un decodeBoolForKey:@"nocache"];
	self.lastModified = [un decodeObjectForKey:@"lastModified"];
	self.errorLast = [un decodeObjectForKey:@"errorLast"];
	self.errorMaxage = [un decodeDoubleForKey:@"errorMaxage"];
	self.errorAttempts = [un decodeIntegerForKey:@"errorAttempts"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	NSKeyedArchiver * ar = (NSKeyedArchiver *)aCoder;
	[ar encodeObject:self.etag forKey:@"etag"];
	[ar encodeDouble:self.maxage forKey:@"maxage"];
	[ar encodeBool:self.nocache forKey:@"nocache"];
	[ar encodeObject:self.lastModified forKey:@"lastModified"];
	[ar encodeInteger:self.errorAttempts forKey:@"errorAttempts"];
	[ar encodeObject:self.errorLast forKey:@"errorLast"];
	[ar encodeDouble:self.errorMaxage forKey:@"errorMaxage"];
}

@end

#if TARGET_OS_IOS || TARGET_OS_TV
@implementation UIImageView (UIImageLoader)
#elif TARGET_OS_OSX
@implementation NSImageView (UIImageLoader)
#endif

static const char * _loadingURL = "uiImageLoader_loadingURL";
static const char * _runningTask = "uiImageLoader_runningTask";
static const char * _cancelsRunningTask = "uiImageLoader_cancelsRunningTask";
static const char * _completedContent = "uiImageLoader_completedContent";
static const char * _spinner = "uiImageLoader_spinner";

#if TARGET_OS_IOS || TARGET_OS_TV
- (void) uiImageLoader_setCompletedContentMode:(UIViewContentMode) completedContentMode; {
	objc_setAssociatedObject(self, _completedContent, [NSNumber numberWithInt:completedContentMode], OBJC_ASSOCIATION_ASSIGN);
}
#elif TARGET_OS_OSX
- (void) uiImageLoader_setCompletedImageScaling:(NSImageScaling) imageScaling; {
	[self setImageScaling:imageScaling];
}
#endif

- (void) uiImageLoader_setCancelsRunningTask:(BOOL) cancelsRunningTask;{
	objc_setAssociatedObject(self, _cancelsRunningTask, [NSNumber numberWithBool:cancelsRunningTask], OBJC_ASSOCIATION_ASSIGN);
}

- (void) uiImageLoader_setSpinner:(UIImageLoaderSpinner *) spinner; {
	objc_setAssociatedObject(self, _spinner, spinner, OBJC_ASSOCIATION_ASSIGN);
}

- (void) uiImageLoader_setImageWithURL:(NSURL *) url; {
	NSURLRequest * request = [NSURLRequest requestWithURL:url];
	[self uiImageLoader_setImageWithRequest:request];
}

- (void) uiImageLoader_setImageWithRequest:(NSURLRequest *) request; {
	
	if(!request.URL || [request.URL.absoluteString length] < 1) {
		return;
	}
	
	//get cancels task
	BOOL cancelsTasks = [objc_getAssociatedObject(self, _cancelsRunningTask) boolValue];
	
	//check if there's an existing task to cancel.
	NSURLSessionDataTask * task = (NSURLSessionDataTask *)objc_getAssociatedObject(self, _runningTask);
	if(task && cancelsTasks) {
		[task cancel];
	}
	
	//get spinner
	UIImageLoaderSpinner * spinner = objc_getAssociatedObject(self, _spinner);
	
	//set the last requested URL to load.
	objc_setAssociatedObject(self, _loadingURL, request.URL, OBJC_ASSOCIATION_COPY_NONATOMIC);
	
	//load image.
	task = [[UIImageLoader defaultLoader] loadImageWithRequest:request hasCache:^(UIImageLoaderImage * _Nullable image, UIImageLoadSource loadedFromSource) {
		
		if(image) {
			self.image = image;
		}
		
		if(spinner) {
			#if TARGET_OS_IOS || TARGET_OS_TV
			[spinner setHidden:YES];
			[spinner stopAnimating];
			#elif TARGET_OS_OSX
			[spinner setHidden:YES];
			[spinner stopAnimation:nil];
			#endif
		}
		
	} sendingRequest:^(BOOL didHaveCachedImage) {
		
		if(spinner && !didHaveCachedImage) {
			#if TARGET_OS_IOS || TARGET_OS_TV
			[spinner setHidden:NO];
			[spinner startAnimating];
			#elif TARGET_OS_OSX
			[spinner setHidden:NO];
			[spinner startAnimation:nil];
			#endif
		}
		
	} requestCompleted:^(NSError * _Nullable error, UIImageLoaderImage * _Nullable image, UIImageLoadSource loadedFromSource) {
		
		if(spinner) {
			#if TARGET_OS_IOS || TARGET_OS_TV
			[spinner setHidden:YES];
			[spinner stopAnimating];
			#elif TARGET_OS_OSX
			[spinner setHidden:YES];
			[spinner stopAnimation:nil];
			#endif
		}
		
		if(image) {
			
			//make sure the image completed matches the last requested image to display.
			//this is most useful for table cells which are recycled.
			NSURL * lastRequestedURL = objc_getAssociatedObject(self, _loadingURL);
			if(lastRequestedURL == nil || [lastRequestedURL isEqual:request.URL]) {
				NSNumber * completedImageScaling = objc_getAssociatedObject(self, _completedContent);
				#if TARGET_OS_IOS || TARGET_OS_TV
				self.contentMode = completedImageScaling.integerValue;
				#elif TARGET_OS_OSX
				[self setImageScaling:completedImageScaling.integerValue];
				#endif
				self.image = image;
			}
		}
	}];
	
	objc_setAssociatedObject(self, _runningTask, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
