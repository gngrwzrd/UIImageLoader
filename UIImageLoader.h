
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

/********************/
/* UIImageLoader */
/********************/

// UIImageLoaderImage - typedef for ios/mac compatibility
#if TARGET_OS_IPHONE
typedef UIImage UIImageLoaderImage;
#elif TARGET_OS_MAC
typedef NSImage UIImageLoaderImage;
#endif

//image source passed in completion callbacks.
typedef NS_ENUM(NSInteger,UIImageLoadSource) {
	UIImageLoadSourceNone,               //no image source as there was an error.
	
	//these will be passed to your hasCache callback
	UIImageLoadSourceDisk,               //image was cached on disk already and loaded from disk
	UIImageLoadSourceMemory,             //image was in memory cache
	
    //these will be passed to your requestCompleted callback
	UIImageLoadSourceNetworkNotModified, //a network request was sent but existing content is still valid
	UIImageLoadSourceNetworkToDisk,      //a network request was sent, image was updated on disk
	UIImageLoadSourceNetworkCancelled,   //a network request was sent, but the NSURLSessionDataTask was cancelled.
};

//forward
@class UIImageMemoryCache;

//completion block
typedef void(^UIImageLoader_HasCacheBlock)(UIImageLoaderImage * image, UIImageLoadSource loadedFromSource);
typedef void(^UIImageLoader_SendingRequestBlock)(BOOL didHaveCachedImage);
typedef void(^UIImageLoader_RequestCompletedBlock)(NSError * error, UIImageLoaderImage * image, UIImageLoadSource loadedFromSource);

//error constants
extern NSString * const UIImageLoaderErrorDomain;
extern const NSInteger UIImageLoaderErrorResponseCode;
extern const NSInteger UIImageLoaderErrorContentType;
extern const NSInteger UIImageLoaderErrorNilURL;

//use the +defaultLoader or create a new one to customize properties.
@interface UIImageLoader : NSObject <NSURLSessionDelegate>

//memory cache where images get stored if cacheImagesInMemory is on.
@property UIImageMemoryCache * memoryCache;

//the session object used to download data.
//If you change this then you are responsible for implementing delegate logic for acceptsAnySSLCertificate if needed.
@property (nonatomic) NSURLSession * session;

//default location is in home/Library/Caches/UIImageLoader
@property (readonly) NSURL * cacheDirectory;

//accepted content types (default = @[@"image/png",@"image/jpg",@"image/jpeg",@"image/bmp",@"image/gif",@"image/tiff"]).
@property NSArray * acceptedContentTypes;

//whether to use server cache policy. Default is TRUE
@property BOOL useServerCachePolicy;

//if useServerCachePolicy=true and response has only ETag header, cache the image for this amount of time. 0 = no cache.
@property NSTimeInterval etagOnlyCacheControl;

//whether to cache loaded images (from disk) into memory.
@property BOOL cacheImagesInMemory;

//Whether to trust any ssl certificate. Default is FALSE
@property BOOL trustAnySSLCertificate;

//Whether to NSLog image urls when there's a cache miss.
@property BOOL logCacheMisses;

//whether to log warnings about response headers.
@property BOOL logResponseWarnings;

//get the default configured loader.
+ (UIImageLoader *) defaultLoader;

//init with a disk cache url.
- (id) initWithCacheDirectory:(NSURL *) url;

//set the Authorization username/password. If set this gets added to every request. Use nil/nil to clear.
- (void) setAuthUsername:(NSString *) username password:(NSString *) password;

//these ignore cache policies and delete files where the modified date is older than specified amount of time.
- (void) clearCachedFilesOlderThan1Day;
- (void) clearCachedFilesOlderThan1Week;
- (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;

//load an image with URL.
- (NSURLSessionDataTask *) loadImageWithURL:(NSURL *) url
								   hasCache:(UIImageLoader_HasCacheBlock) hasCache
								sendRequest:(UIImageLoader_SendingRequestBlock) sendRequest
						   requestCompleted:(UIImageLoader_RequestCompletedBlock) requestCompleted;

//load an image with custom request.
//auth headers will be added to your request if needed.
- (NSURLSessionDataTask *) loadImageWithRequest:(NSURLRequest *) request
									   hasCache:(UIImageLoader_HasCacheBlock) hasCache
									sendRequest:(UIImageLoader_SendingRequestBlock) sendRequest
							   requestCompleted:(UIImageLoader_RequestCompletedBlock) requestCompleted;

@end

/************************/
/** UIImageMemoryCache **/
/************************/

@interface UIImageMemoryCache : NSObject

//max cache size in bytes.
@property (nonatomic) NSUInteger maxBytes;

//cache an image with URL as key.
- (void) cacheImage:(UIImageLoaderImage *) image forURL:(NSURL *) url;

//remove an image with url as key.
- (void) removeImageForURL:(NSURL *) url;

//delete all cache data.
- (void) purge;

@end
