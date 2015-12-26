
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
	
	//this is passed to callbacks when there's an error, no image is provided.
	UIImageLoadSourceNone,               //no image source as there was an error.
	
	//these will be passed to your hasCache callback
	UIImageLoadSourceDisk,               //image was cached on disk already and loaded from disk
	UIImageLoadSourceMemory,             //image was in memory cache
	
    //these will be passed to your requestCompleted callback
	UIImageLoadSourceNetworkNotModified, //a network request was sent but existing content is still valid
	UIImageLoadSourceNetworkToDisk,      //a network request was sent, image was updated on disk
	
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

//default location is in home/Library/Caches/my.bundle.id/UIImageLoader
@property (nonatomic) NSURL * cacheDirectory;

//accepted content types (default = @[@"image/png",@"image/jpg",@"image/jpeg",@"image/bmp",@"image/gif",@"image/tiff"]).
@property NSArray * acceptedContentTypes;

//whether to use server cache policy. Default is TRUE
@property BOOL useServerCachePolicy;

//if using server cache control, and the server doesn't return a Cache-Control max-age header, you can use this
//to provide your own max age for caching before the image is requested again.
@property NSTimeInterval defaultCacheControlMaxAge;

//Whether to trust any ssl certificate. Default is FALSE
@property BOOL trustAnySSLCertificate;

//whether to cache loaded images (from disk) into memory.
@property BOOL cacheImagesInMemory;

//Whether to NSLog image urls when there's a cache miss.
@property BOOL logCacheMisses;

//get the default configured loader.
+ (UIImageLoader *) defaultLoader;

//init with a disk cache url.
- (id) initWithCacheDirectory:(NSURL *) url;

//set the Authorization username/password. If set this gets added to every request. Use nil/nil to clear.
- (void) setAuthUsername:(NSString *) username password:(NSString *) password;

//these ignore cache policies and delete files where the modified date is older than specified amount of time.
- (void) clearCachedFilesModifiedOlderThan1Day;
- (void) clearCachedFilesModifiedOlderThan1Week;
- (void) clearCachedFilesModifiedOlderThan:(NSTimeInterval) timeInterval;

//these ignore cache policies and delete files where the created date is older than specified amount of time.
- (void) clearCachedFilesCreatedOlderThan1Day;
- (void) clearCachedFilesCreatedOlderThan1Week;
- (void) clearCachedFilesCreatedOlderThan:(NSTimeInterval) timeInterval;

//ignore cache policy and delete all disk cache files.
- (void) purgeDiskCache;

//purge the memory cache.
- (void) purgeMemoryCache;

//set memory cache max bytes.
- (void) setMemoryCacheMaxBytes:(NSUInteger) maxBytes;

//load an image with URL.
- (NSURLSessionDataTask *) loadImageWithURL:(NSURL *) url
								   hasCache:(UIImageLoader_HasCacheBlock) hasCache
								sendingRequest:(UIImageLoader_SendingRequestBlock) sendingRequest
						   requestCompleted:(UIImageLoader_RequestCompletedBlock) requestCompleted;

//load an image with custom request.
//auth headers will be added to your request if needed.
- (NSURLSessionDataTask *) loadImageWithRequest:(NSURLRequest *) request
									   hasCache:(UIImageLoader_HasCacheBlock) hasCache
									sendingRequest:(UIImageLoader_SendingRequestBlock) sendingRequest
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
