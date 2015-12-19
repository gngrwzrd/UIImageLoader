# UIImageView+DiskCache

UIImageView+DiskCache is an alternative to a subset of functionality from SDWebImage.

This allows you to cache images on disk and completely ignore the cache control policies from a server.

Or you can choose to use cache control policies from a server to manage re-downloading the images when cache has expired.

This class is roughly 400 lines of code and in one file. Uses modern NSURLSession for downloading so everything happens
in the background.

Server cache control policy logic is implemented manually instead of a NSURLCache. There's a noticeable difference in
performance without NSURLCache.

## No Flickering

Without NSURLCache there's a noticeable performance difference. This generally means you see no flickering, and images that are cached and available on disk load into the UIImageView almost immediatly.

This is most noticeable on table view cells. The slight delay that you may sometimes see before a cached image is loaded and displayed is entirely gone.

## Ignoring Cache Control

If you know your app downloads images that will never change this is useful.

If you're going to ignore cache control all together for images, make sure to at least put some cleanup in your app delegate:

    - (BOOL) application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
        [UIImageView clearCachedFilesOlderThan1Week];
    }

Or use one of these cleanup methods to your needs:

    + (void) clearCachedFilesOlderThan1Day;
    + (void) clearCachedFilesOlderThan1Week;
    + (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;

The easiest way to set an image ignoring server cache control is with this:

    [myImageView setImageForURL:myURL withCompletion:^(NSError *error, UIImage *image) {
	    if(error) {
		    //do something.
    		return;
	    }
    }];

## Using Server Cache Control Policies

If you are going to use cache control policies from the server then don't do any manual cleanup of the cache.

The easiest way to set an image that uses server cache control policies is with this:

    [myImageView setImageForURLWithCacheControl:myURL withCompletion:^(NSError * error, UIImage * image) {
	    if(error) {
		    //do something.
    		return;
   	    }
   	    
	    //do nothing. image is already set on myImageView.image, it's passed to you just in case you
    	//need to do something else with it.
    }];

## Other Useful Features

### SSL

If you need to support self signed certificates you can use:

````
+ (void) setAcceptsAnySSLCertificate:(BOOL) acceptsAnySSLCertificate;
````

### Auth Basic Password Protected Directories/Images

You can set a global default user/pass with this:

````
+ (void) setDefaultAuthBasicUsername:(NSString *) username password:(NSString *) password;
````

Then you set images with either of these:

````
- (void) setImageWithDefaultAuthBasicForURL:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForURLWithCacheControlAndDefaultAuthBasic:(NSURL *) url withCompletion:(UIImageViewDiskCacheCompletion) completion;
````

### Custom Requests

If you have other requirements for how the request is constructed you can use these:

````
- (void) setImageForRequestWithCacheControl:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion;
- (void) setImageForRequest:(NSURLRequest *) request withCompletion:(UIImageViewDiskCacheCompletion) completion;
````

*Note that if you are passing a custom request and you need http authorization, you can use this method to add it to a request:*

````
+ (void) setHTTPAuthorizationForRequest:(NSMutableURLRequest *) request;
````
