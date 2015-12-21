
#import <UIKit/UIKit.h>

/** UIImageMemoryCache **/

@interface UIImageMemoryCache : NSObject

//max cache size in bytes.
@property (nonatomic) NSUInteger maxBytes;

//cache an image with URL as key.
- (void) cacheImage:(UIImage *) image forURL:(NSURL *) url;

//remove an image with url as key.
- (void) removeImageForURL:(NSURL *) url;

//delete all cache data.
- (void) purge;

@end

/** UIImageDiskCache **/

//image source passed in completion callbacks.
typedef NS_ENUM(NSInteger,UIImageLoadSource) {
	//these will be passed to your hasCacheBlock callback
	UIImageLoadSourceDisk,               //image was cached on disk already and loaded from disk
	UIImageLoadSourceMemory,             //image was in memory cache
	
    //these will be passed to your requestFinishedBlock callback
	UIImageLoadSourceNone,               //no source as there was an error
	UIImageLoadSourceNetworkNotModified, //a network request was sent but existing content is still valid
	UIImageLoadSourceNetworkToDisk,      //a network request was sent, image was updated on disk
};

//forward
@class UIImageDiskCache;

//completion block
typedef void(^UIImageDiskCache_HasCacheBlock)(UIImage * image, UIImageLoadSource loadedFromSource);
typedef void(^UIImageDiskCache_SendingRequestBlock)(BOOL didHaveCachedImage);
typedef void(^UIImageDiskCache_RequestCompletedBlock)(NSError * error, UIImage * image, UIImageLoadSource loadedFromSource);

//error constants
extern NSString * const UIImageDiskCacheErrorDomain;
extern const NSInteger UIImageDiskCacheErrorResponseCode;
extern const NSInteger UIImageDiskCacheErrorContentType;
extern const NSInteger UIImageDiskCacheErrorNilURL;

//use the +defaultDiskCache or create a new one to customize properties.
@interface UIImageDiskCache : NSObject <NSURLSessionDelegate>

//memory cache where images get stored if cacheImagesInMemory is on.
@property UIImageMemoryCache * memoryCache;

//the session object used to download data.
//If you change this then you are responsible for implementing delegate logic for acceptsAnySSLCertificate if needed.
@property (nonatomic) NSURLSession * session;

//default location is in home/Library/Caches/UIImageDiskCache
@property (readonly) NSURL * cacheDirectory;

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

//get the default configured disk cache.
+ (UIImageDiskCache *) defaultDiskCache;

//set the Authorization username/password. If set this gets added to every request. Use nil/nil to clear.
- (void) setAuthUsername:(NSString *) username password:(NSString *) password;

//these ignore cache policies and delete files where the modified date is older than specified amount of time.
- (void) clearCachedFilesOlderThan1Day;
- (void) clearCachedFilesOlderThan1Week;
- (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;

@end

/*****************************/
/**  UIImageView Additions  **/
/*****************************/

@interface UIImageView (UIImageDiskCache) <NSURLSessionDelegate>

- (NSURLSessionDataTask *) setImageWithURL:(NSURL *) url
									 cache:(UIImageDiskCache *) cache
								  hasCache:(UIImageDiskCache_HasCacheBlock) hasCache
							   sendRequest:(UIImageDiskCache_SendingRequestBlock) sendRequest
						  requestCompleted:(UIImageDiskCache_RequestCompletedBlock) requestCompleted;

- (NSURLSessionDataTask *) setImageWithURL:(NSURL *) url
								  hasCache:(UIImageDiskCache_HasCacheBlock) hasCache
							   sendRequest:(UIImageDiskCache_SendingRequestBlock) sendRequest
						  requestCompleted:(UIImageDiskCache_RequestCompletedBlock) requestCompleted;

- (NSURLSessionDataTask *) setImageWithRequest:(NSURLRequest *) request
										 cache:(UIImageDiskCache *) cache
									  hasCache:(UIImageDiskCache_HasCacheBlock) hasCache
								   sendRequest:(UIImageDiskCache_SendingRequestBlock) sendRequest
							  requestCompleted:(UIImageDiskCache_RequestCompletedBlock) requestCompleted;

- (NSURLSessionDataTask *) setImageWithRequest:(NSURLRequest *) request
									  hasCache:(UIImageDiskCache_HasCacheBlock) hasCache
								   sendRequest:(UIImageDiskCache_SendingRequestBlock) sendRequest
							  requestCompleted:(UIImageDiskCache_RequestCompletedBlock) requestCompleted;

@end

///****************************/
///**   UIButton Additions   **/
///****************************/
//
//
//@interface UIButton (UIImageDiskCache)
//
//- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withURL:(NSURL *) url completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withURL:(NSURL *) url customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withRequest:(NSURLRequest *) request completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withRequest:(NSURLRequest *) request customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
//
//- (NSURLSessionDataTask *) setBackgroundImageForControlState:(UIControlState) controlState withURL:(NSURL *) url completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) setBackgroundImageForControlState:(UIControlState) controlState withURL:(NSURL *) url customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) setBackgroundImageForControlState:(UIControlState) controlState withRequest:(NSURLRequest *) request completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) setBackgroundImageForControlState:(UIControlState) controlState withRequest:(NSURLRequest *) request customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
//
//@end
//
// 
///***************************/
///**   UIImage Additions   **/
///***************************/
//
//
//@interface UIImage (UIImageDiskCache)
//
//- (NSURLSessionDataTask *) downloadImageWithURL:(NSURL *) url completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) downloadImageWithURL:(NSURL *) url customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) downloadImageWithRequest:(NSURLRequest *) request completion:(UIImageDiskCacheCompletion) completion;
//- (NSURLSessionDataTask *) downloadImageWithRequest:(NSURLRequest *) request customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion)completion;
//
//@end
