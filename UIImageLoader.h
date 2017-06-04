
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

//https://github.com/gngrwzrd/UIImageLoader

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
typedef void(^UIImageLoader_HasCacheBlock)(UIImageLoaderImage * _Nullable image, UIImageLoadSource loadedFromSource);
typedef void(^UIImageLoader_SendingRequestBlock)(BOOL didHaveCachedImage);
typedef void(^UIImageLoader_RequestCompletedBlock)(NSError * _Nullable error, UIImageLoaderImage * _Nullable image, UIImageLoadSource loadedFromSource);

//error constants
extern NSString * _Nonnull const UIImageLoaderErrorDomain;
extern const NSInteger UIImageLoaderErrorNilURL;

//use the +defaultLoader or create a new one to customize properties.
@interface UIImageLoader : NSObject <NSURLSessionDelegate>

//memory cache where images get stored if cacheImagesInMemory is on.
@property UIImageMemoryCache * _Nullable memoryCache;

//the session object used to download data.
//If you change this then you are responsible for implementing delegate logic for acceptsAnySSLCertificate if needed.
@property (nonatomic) NSURLSession * _Nullable session;

//default location is in home/Library/Caches/my.bundle.id/UIImageLoader
@property (nonatomic) NSURL * _Nonnull cacheDirectory;

//whether to use server cache policy. Default is TRUE
@property BOOL useServerCachePolicy;

//if using server cache control, and the server doesn't return a Cache-Control max-age header, you can use this
//to provide your own max age for caching before the image is requested again.
@property NSTimeInterval defaultCacheControlMaxAge;

//if a response is 4XX, or 5XX. The max tries before a cache control max-age is set.
//The image will be requested again after the max-age for the image. Use this in
//conjunction with badRequestCacheControlMaxAge;
@property NSInteger maxAtemptsForErrors;      //default is 3

//the max cache time for error responses.
@property NSInteger defaultCacheControlMaxAgeForErrors; //default is 0 (no cache)

//Whether to trust any ssl certificate. Default is FALSE
@property BOOL trustAnySSLCertificate;

//whether to cache loaded images (from disk) into memory.
@property BOOL cacheImagesInMemory;

//Whether to NSLog image urls when there's a cache miss.
@property BOOL logCacheMisses;

//get the default configured loader.
+ (UIImageLoader * _Nonnull) defaultLoader;

//init with a disk cache url.
- (id _Nullable) initWithCacheDirectory:(NSURL * _Nonnull) url;

//set the Authorization username/password. If set this gets added to every request. Use nil/nil to clear.
- (void) setAuthUsername:(NSString * _Nonnull) username password:(NSString * _Nonnull) password;

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
- (NSURLSessionDataTask * _Nullable) loadImageWithURL:(NSURL * _Nullable) url
	hasCache:(UIImageLoader_HasCacheBlock _Nullable) hasCache
	sendingRequest:(UIImageLoader_SendingRequestBlock _Nullable) sendingRequest
	requestCompleted:(UIImageLoader_RequestCompletedBlock _Nullable) requestCompleted;

//load an image with custom request.
//auth headers will be added to your request if needed.
- (NSURLSessionDataTask * _Nullable) loadImageWithRequest:(NSURLRequest * _Nullable) request
	hasCache:(UIImageLoader_HasCacheBlock _Nullable) hasCache
	sendingRequest:(UIImageLoader_SendingRequestBlock _Nullable) sendingRequest
	requestCompleted:(UIImageLoader_RequestCompletedBlock _Nullable) requestCompleted;

@end

/************************/
/** UIImageMemoryCache **/
/************************/

@interface UIImageMemoryCache : NSObject

//max cache size in bytes.
@property (nonatomic) NSUInteger maxBytes;

//cache an image with URL as key.
- (void) cacheImage:(UIImageLoaderImage * _Nonnull) image forURL:(NSURL * _Nonnull) url;

//remove an image with url as key.
- (void) removeImageForURL:(NSURL * _Nonnull) url;

//delete all cache data.
- (void) purge;

@end
