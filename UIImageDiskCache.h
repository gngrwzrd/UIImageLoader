
#import <UIKit/UIKit.h>

/** UIImageDiskCache **/

//completions
typedef void(^UIImageDiskCacheCompletion)(NSError * error, UIImage * image);
typedef void(^UIImageDiskCacheURLCompletion)(NSError * error, NSURL * diskURL);

//error constants
extern NSString * const UIImageDiskCacheErrorDomain;
extern const NSInteger UIImageDiskCacheErrorResponseCode;
extern const NSInteger UIImageDiskCacheErrorContentType;

//use the +defaultDiskCache or create a new one to customize properties.
@interface UIImageDiskCache : NSObject <NSURLSessionDelegate>

//the session object used to download data.
//If you change this then you are responsible for implementing delegate logic for acceptsAnySSLCertificate if needed.
@property (nonatomic) NSURLSession * session;

//default location is in home/Library/Application Support/UIImageDiskCache
@property (readonly) NSURL * cacheDirectory;

//whether to use server cache policy. Default is TRUE
@property BOOL useServerCachePolicy;

//Whether to trust any ssl certificate. Default is FALSE
@property BOOL acceptsAnySSLCertificate;

//Whether to NSLog image urls when there's a cache miss.
@property BOOL logCacheMisses;

//get the default configured disk cache.
+ (UIImageDiskCache *) defaultDiskCache;

//set the Authorization username/password. If set this gets added to every request. Use nil/nil to clear.
- (void) setAuthUsername:(NSString *) username password:(NSString *) password;

//these ignore cache policies and delete files where the modified date is older than specified amount of time.
- (void) clearCachedFilesOlderThan1Day;
- (void) clearCachedFilesOlderThan1Week;
- (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;

//cache an image with a request.
- (NSURLSessionDataTask *) cacheImageWithRequest:(NSMutableURLRequest *) request completion:(UIImageDiskCacheURLCompletion) completion;

@end

/*****************************/
/**  UIImageView Additions  **/
/*****************************/
 
@interface UIImageView (UIImageDiskCache) <NSURLSessionDelegate>

- (NSURLSessionDataTask *) setImageWithURL:(NSURL *) url completion:(UIImageDiskCacheCompletion) completion;
- (NSURLSessionDataTask *) setImageWithURL:(NSURL *) url customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
- (NSURLSessionDataTask *) setImageWithRequest:(NSURLRequest *) request completion:(UIImageDiskCacheCompletion) completion;
- (NSURLSessionDataTask *) setImageWithRequest:(NSURLRequest *) request customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;

@end

/****************************/
/**   UIButton Additions   **/
/****************************/

@interface UIButton (UIImageDiskCache)

- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withURL:(NSURL *) url completion:(UIImageDiskCacheCompletion) completion;
- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withURL:(NSURL *) url customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;
- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withRequest:(NSURLRequest *) request completion:(UIImageDiskCacheCompletion) completion;
- (NSURLSessionDataTask *) setImageForControlState:(UIControlState) controlState withRequest:(NSURLRequest *) request customCache:(UIImageDiskCache *) customCache completion:(UIImageDiskCacheCompletion) completion;

@end
