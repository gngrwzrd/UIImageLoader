# UIImageLoader

UIImageLoader is a helper to load images from the web. It caches images on disk, and optionally in memory.

It makes it super simple to write handler code for cached images, set a placeholder image when a network request is being made, and handle any errors on request completion.

It supports server cache control to re-download images when expired. Cache control logic is implemented manually instead of using an NSURLCache for performance reasons.

You can also completely ignore server cache control and manually clean-up images yourself.

It's very small at roughly 600+ lines of code in a single header / implementation file.

Everything is asynchronous and uses modern objective-c with libdispatch and NSURLSession.

## Use Case

This isn't intended to compete with other frameworks that are optimized to provide fast scrolling for thousands or tens-of-thousands of images.

For average apps that would like to cache images on disk and have some options for control caching, this will make a noticeable difference.

My particular use case was a better disk cache that isn't NSURLCache. It provides better options for handling how server cache control is used. And get rid of delays or flickering that happens because of NSURLCache being slow.

Images that are cached and available on disk load almost immediatly. This is most noticeable on table view cells.

You can also cache images in memory for even faster loading.

## Server Cache Control

It works with servers that support ETag/If-None-Match and Cache-Control headers.

If the server responds with only ETag you can optionally cache the image for a default amount of time. Or let the loader make requests each time to check for new content.

If a response is 304 it uses the cached image available on disk.

## Installation

Download, fork, clone or submodule this repo. Then add UIImageLoader.h/m to your Xcode project.

## UIImageLoader Object

There's a default configured loader which you're free to configure how you like.

````
//this is default configuration:
UIImageLoader * loader = [UIImageLoader defaultLoader];
loader.cacheImagesInMemory = FALSE;
loader.trustAnySSLCertificate  = FALSE;
loader.useServerCachePolicy = TRUE;
loader.logCacheMisses = TRUE;
loader.logResponseWarnings = TRUE;
loader.etagOnlyCacheControl = 0;
loader.memoryCache.maxBytes = 25 * (1024 * 1024); //25MB;
````

Or you can setup your own and configure it:

````
UIImageLoader * loader = [[UIImageLoader alloc] init];
//set loader properties here.
````

### Loading an Image

It's easy to load an image:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];

NSURL * imageURL = myURL;	

[loader loadImageWithURL:imageURL \

hasCache:^(UIImage *image, UIImageLoadSource loadedFromSource) {
	
	//there was a cached image available. use that.
	self.imageView.image = image;
	
} sendRequest:^(BOOL didHaveCachedImage) {
	
	//a request is being made for the image.
	
	if(!didHaveCachedImage) {
		
		//there was not a cached image available, set a placeholder or do nothing.
	    self.imageView.image = [UIImage imageNamed:@"placeholder"];
	}
	
} requestCompleted:^(NSError *error, UIImage *image, UIImageLoadSource loadedFromSource) {
	
	//network request finished.
	
	if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
		//the image was downloaded and saved to disk.
		//since it was downloaded it has been updated since
		//last cached version, or is brand new
	
		self.imageView.image = image;
	}
}];
````

### Image Loaded Source

The enum UIImageLoadSource provides you with where the image was loaded from:

````
//image source passed in completion callbacks.
typedef NS_ENUM(NSInteger,UIImageLoadSource) {
	UIImageLoadSourceDisk,               //image was cached on disk already and loaded from disk
	UIImageLoadSourceMemory,             //image was in memory cache
	UIImageLoadSourceNone,               //no source as there was an error
	UIImageLoadSourceNetworkNotModified, //a network request was sent but existing content is still valid
	UIImageLoadSourceNetworkToDisk,      //a network request was sent, image was updated on disk
};
````

### Has Cache Callback

When you load an image with UIImageLoader, the first callback you can use is the _hasCache_ callback. It's defined as:

````
typedef void(^UIImageLoader_HasCacheBlock)(UIImage * image, UIImageLoadSource loadedFromSource);
````

If a cached image is available, you will get the image, and the source will be either UIImageLoadSourceDisk or UIImageLoadSourceMemory.

### Send Request Callback

You can use this callback to decide if you should show a placeholder or loader of some kind. If the image loader needs to make a request for the image, you will receive this callback. It's defined as:

````
typedef void(^UIImageLoader_SendingRequestBlock)(BOOL didHaveCachedImage);
````

The _didHaveCachedImage_ parameter tells you if a cached image was available (and that your _hasCache_ callback was called).

### Request Completed Callback

This callback runs when the request has finished. It's defined as:

````
typedef void(^UIImageLoader_RequestCompletedBlock)(NSError * error, UIImage * image, UIImageLoadSource loadedFromSource);
````

If a network error occurs, you'll receive an _error_ object and _UIImageLoadSourceNone_.

If load source is _UIImageLoadSourceNetworkToDisk_, it means a new image was downloaded. This can mean either it was a new download, or existing cache was updated. You should use the new image provided.

If load source is _UIImageLoadSourceNetworkNotModified_, it means the cached image is still valid. You won't receive an image in this case as the image was already passed to your _hasCache_ callback.

### Memory Cache

You can enable the memory cache easily:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];
loader.cacheImagesInMemory = TRUE;
````

You can change the memory limit with:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];
loader.memoryCache.maxBytes = 50 * (1024 * 1024); //50MB;
````

You can purge memory with:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];
[loader.memoryCache purge];
````

_Memory cache is not shared among loaders, each loader will have it's own cache._

### Manual Cache Cleanup

If you aren't using server cache control, you can use a few helper methods to cleanup images on disk:

````
- (void) clearCachedFilesOlderThan1Day;
- (void) clearCachedFilesOlderThan1Week;
- (void) clearCachedFilesOlderThan:(NSTimeInterval) timeInterval;
````

These methods use the file modified date to decide which to delete.

When an image is accessed using the loader the modified date is updated.

Images that are used frequently will not be removed. 

It's easy to put some cleanup in app delegate:

````
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIImageLoader * loader = [UIImageLoader defaultLoader];
    [loader clearCachedFilesOlderThan1Week];
}
````


### 304 Not Modified Images

For image responses that return a 304, but don't include a Cache-Control header (expiration), the default behavior is to always send requests to check for new content. Even if there's a cached version available, a network request would still be sent.

You can set a default cache time for this scenario in order to stop these requests.

````
myCache.etagOnlyCacheControl = 604800; //1 week;
myCache.etagOnlyCacheControl = 0;      //(default) always send request to see if there's new content.
````

### NSURLSession

You can customize the NSURLSession that's used to download images like this:

````
myCache.session = myNSURLSession;
````

If you do change the session, you are responsible for implementing it's delegate if required. And implementing SSL trust for self signed certificates if required.

### NSURLSessionDataTask

Each load method returns the NSURLSessionDataTask used for network requests. You can either ignore it, or keep it. It's useful for canceling requests if needed.

## Other Useful Features

### SSL

If you need to support self signed certificates you can use (false by default):

````
myLoader.trustAnySSLCertificate = TRUE;
````

### Auth Basic Password Protected Directories/Images

You can set default user/pass that gets sent in every request with:

````
[myLoader setAuthUsername:@"username" password:@"password"];
````


## License

The MIT License (MIT)
Copyright (c) 2016 Aaron Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.