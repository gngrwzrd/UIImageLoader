# UIImageLoader

UIImageLoader is a helper to load images from the web. It caches images on disk, and optionally in memory.

It makes it super simple to write handler code for cached images, set a placeholder image or show a loader when a network request is being made, and handle any errors on request completion.

It supports server cache control to re-download images when expired. Cache control logic is implemented manually instead of using an NSURLCache for performance reasons.

You can also completely ignore server cache control and manually clean-up images yourself.

It's compatible with iOS and Mac. And very small at roughly 600+ lines of code in a single header / implementation file.

Everything is asynchronous and uses modern objective-c with libdispatch and NSURLSession.

## Swift Compatibility

Yes. Just import UIImageLoader.h into your Project-bridge-header.h file.

## Server Cache Control

It supports responses with Cache-Control max age, ETag, and Last-Modified headers.

It sends requests with If-None-Match, and If-Modified-Since.

If the server doesn't respond with a Cache-Control header, you can optionally set a default cache control max age in order to cache the image for a specified time.

If a response is 304 it uses the cached image available on disk.

## 4XX & 5XX Responses

For 4XX and 5XX responses you can specify a number of allowed tries to get the image. And a cache control max age - to prevent sending the same requests in the event of an error.

## Installation

* Download a zip of this repo
* Add UIImageLoader.h and UIImageLoader.m to your Xcode project

## Dribbble Samples

There's a very simple sample application for iOS/Mac that shows loading images into a collection view.

The app loads 1000 images from Dribbble.

The app demonstrates how to setup a cell to gracefully handle:

* Downloading images
* Using spinners for loading activity
* Cancelling an image download when a cell is reused
* Or letting the image download complete so it's cached

![sample screenshots](http://www.gngrwzrd.com/downloads/dribbble-samples-mac-ios-1.png)

## UIImageLoader Object

There's a default configured loader which you're free to configure how you like.

````
//this is the default configuration:

UIImageLoader * loader = [UIImageLoader defaultLoader];
loader.cacheImagesInMemory = FALSE;
loader.trustAnySSLCertificate = FALSE;
loader.useServerCachePolicy = TRUE;
loader.logCacheMisses = TRUE;
loader.defaultCacheControlMaxAge = 0;
loader.acceptedContentTypes = @[@"image/png",@"image/jpg",@"image/jpeg",@"image/bmp",@"image/gif",@"image/tiff"];
loader.defaultCacheControlMaxAgeForErrors = 0;
loader.maxAtemptsForErrors = 0;
[loader setMemoryCacheMaxBytes:25 * (1024 * 1024)]; //25 MB
````

The default cache directory is _~/Library/Caches/com.my.app.id/UIImageLoader/_

Or you can setup your own and configure it:

````
//create loader
UIImageLoader * loader = [[UIImageLoader alloc] initWithCacheDirectory:myCustomDiskURL];
//set loader properties here.
````

### Loading an Image

It's easy to load an image:

````
NSURL * imageURL = myURL;	

[[UIImageLoader defaultLoader] loadImageWithURL:imageURL \

hasCache:^(UIImageLoaderImage * image, UIImageLoadSource loadedFromSource) {
	
	//there was a cached image available. use that.
	self.imageView.image = image;
	
} sendingRequest:^(BOOL didHaveCachedImage) {
	
	//a request is being made for the image.
	
	if(!didHaveCachedImage) {
		
		//there was not a cached image available, set a placeholder or do nothing.
		self.loader.hidden = FALSE;
	    [self.loader startAnimating];
	    self.imageView.image = [UIImage imageNamed:@"placeholder"];
	}
	
} requestCompleted:^(NSError *error, UIImageLoaderImage * image, UIImageLoadSource loadedFromSource) {
	
	//network request finished.
	
	[self.loader stopAnimating];
	self.loader.hidden = TRUE;
	
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
	
	//this is passed to callbacks when there's an error, no image is provided.
	UIImageLoadSourceNone,               //no image source as there was an error.
	
	//these will be passed to your hasCache callback
	UIImageLoadSourceDisk,               //image was cached on disk already and loaded from disk
	UIImageLoadSourceMemory,             //image was in memory cache
	
    //these will be passed to your requestCompleted callback
	UIImageLoadSourceNetworkNotModified, //a network request was sent but existing content is still valid
	UIImageLoadSourceNetworkToDisk,      //a network request was sent, image was updated on disk
	
};
````

### Has Cache Callback

When you load an image with UIImageLoader, the first callback is the _hasCache_ callback. It's defined as:

````
typedef void(^UIImageLoader_HasCacheBlock)(UIImageLoaderImage * image, UIImageLoadSource loadedFromSource);
````

_If a cached image is available, you get an image, and the loadedFromSource will be either UIImageLoadSourceDisk or UIImageLoadSourceMemory._

_If no cached image was available, this callback isn't called._

_**If the cached image is still valid (not expired), this is the only callback that will be called.**_

### Sending Request Callback

The second callback is _sendingRequest._ This is called just before a network request will be sent for the image. You can use this to either show a placeholder image, or start a progress indicator. It's defined as:

````
typedef void(^UIImageLoader_SendingRequestBlock)(BOOL didHaveCachedImage);
````

_If a cached image wasn't avilable, this will be called with didHaveCachedImage=false, which indicates that the hasCache callback wasn't called._

_If a cached image was available but expired, this will be called with didHaveCachedImage=true._

### Request Completed Callback

The _requestCompleted_ callback runs when the request has finished. It's defined as:

````
typedef void(^UIImageLoader_RequestCompletedBlock)(NSError * error, UIImageLoaderImage * image, UIImageLoadSource loadedFromSource);
````

_If a network error occurs, you'll receive an error object and UIImageLoadSourceNone._

_If load source is UIImageLoadSourceNetworkToDisk, it means an image was downloaded._

_If load source is UIImageLoadSourceNetworkNotModified, it means the cached image is still valid and image=nil because it was already passed to your hasCache callback._

### Accepted Image Types

You can customize the accepted content-types types from servers with:

````
loader.acceptedContentTypes = @[@"image/png",@"image/jpg",@"image/jpeg",@"image/bmp",@"image/gif",@"image/tiff"];
````

### Memory Cache

You can enable the memory cache easily:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];
loader.cacheImagesInMemory = TRUE;
````

You can change the memory limit with:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];
[loader setMemoryCacheMaxBytes:50 * (1024 * 1024)]; //50MB
````

You can purge memory with:

````
UIImageLoader * loader = [UIImageLoader defaultLoader];
[loader purgeMemoryCache];
````

_Memory cache is not shared among loaders, each loader will have it's own cache._

### Manual Disk Cache Cleanup

When an image is accessed using UIImageLoader the file's modified date is updated.

These methods use the file modified date to decide which to delete. You can use these methods to ensure frequently used files will not be delete.

````
- (void) clearCachedFilesModifiedOlderThan1Day;
- (void) clearCachedFilesModifiedOlderThan1Week;
- (void) clearCachedFilesModifiedOlderThan:(NSTimeInterval) timeInterval;
````

These methods use the file created date to decide which to delete.

````
- (void) clearCachedFilesCreatedOlderThan1Day;
- (void) clearCachedFilesCreatedOlderThan1Week;
- (void) clearCachedFilesCreatedOlderThan:(NSTimeInterval) timeInterval;
````

You can purge the entire disk cache with:

````
- (void) purgeDiskCache;
````

It's easy to put some cleanup in app delegate. Using one of the methods available you can keep the disk cache clean, while keeping frequently used images.

````
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIImageLoader * loader = [UIImageLoader defaultLoader];
    [loader clearCachedFilesModifiedOlderThan1Week];
}
````

### 304 Not Modified Images

For image responses that return a 304, but don't include a Cache-Control header (expiration), the default behavior is to always send requests to check for new content. Even if there's a cached version available, a network request would still be sent.

You can set a default cache time for this scenario in order to stop these requests.

````
myLoader.defaultCacheControlMaxAge = 604800; //1 week;
myLoader.defaultCacheControlMaxAge = 0;      //(default) always send request to see if there's new content.
````

### 4XX & 5XX Errors

For image responses that return errors, you can configure what to do in those cases.

You can allow any number of attempts to retrieve images that have received error responses:

````
myLoader.maxAttemptsForErrors = 3; (default) Allow three attempts to get the image.
myLoader.maxAttemptsforErrors = 1; Only allow one error before the cache takes effect.
````

You can set a default max age for error caching:

````
myLoader.defaultCacheControlMaxAgeForErrors = 604800; //1 week;
myLoader.defaultCacheControlMaxAgeForErrors = 0; //(default) always send request to try and get the image.

````

### NSURLSession

You can customize the NSURLSession that's used to download images like this:

````
myLoader.session = myNSURLSession;
````

If you do customize the session. Make sure to use a session that runs on a background thread:

````
NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
loader.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
````

You are responsible for implementing it's delegate if required. And implementing SSL trust for self signed certificates if required.

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

### UIImageLoaderImage For Mac OS X

For compatibility between platforms, there's a typedef that UIImageLoader uses to switch out image types.

````
// UIImageLoaderImage - typedef for ios/mac compatibility
#if TARGET_OS_IPHONE
typedef UIImage UIImageLoaderImage;
#elif TARGET_OS_MAC
typedef NSImage UIImageLoaderImage;
#endif
````

### Table or Collection Cell Example

This is taken from the DribbbleSample in the repo.

Header:

````

#import <UIKit/UIKit.h>

@interface DribbbleShotCell : UICollectionViewCell
@property IBOutlet UIImageView * imageView;
@property IBOutlet UIActivityIndicatorView * indicator;
- (void) setShot:(NSDictionary *) shot;
@end

````

Implementation:

````

#import "DribbbleShotCell.h"
#import "UIImageLoader.h"

@interface DribbbleShotCell ()
@property BOOL cancelsTask;
@property NSURLSessionDataTask * task;
@property NSURL * activeImageURL;
@end

@implementation DribbbleShotCell

- (void) awakeFromNib {
	//set to FALSE to let images download even if this cells image has changed while scrolling.
	self.cancelsTask = FALSE;
	
	//set to TRUE to cause downloads to cancel if a cell is being reused.
	//self.cancelsTask = TRUE;
}

- (void) prepareForReuse {
	self.imageView.image = nil;
	if(self.cancelsTask) {
		[self.task cancel];
	}
}

- (void) setShot:(NSDictionary *) shot {
	NSDictionary * images = shot[@"images"];
	NSURL * url = [NSURL URLWithString:images[@"normal"]];
	self.activeImageURL = url;
	
	self.task = [[UIImageLoader defaultLoader] loadImageWithURL:url hasCache:^(UIImageLoaderImage *image, UIImageLoadSource loadedFromSource) {
		
		//hide indicator as we have a cached image available.
		self.indicator.hidden = TRUE;
		
		//use cached image
		self.imageView.image = image;
		
	} sendingRequest:^(BOOL didHaveCachedImage) {
		
		if(!didHaveCachedImage) {
			//a cached image wasn't available, a network request is being sent, show spinner.
			[self.indicator startAnimating];
			self.indicator.hidden = FALSE;
		}
		
	} requestCompleted:^(NSError *error, UIImageLoaderImage *image, UIImageLoadSource loadedFromSource) {
		
		//request complete.
		
		//check if url above matches self.activeURL.
		//If they don't match it means the request that finished was for a previous image. don't use it.
		if(!self.cancelsTask && ![self.activeImageURL.absoluteString isEqualToString:url.absoluteString]) {
			//NSLog(@"request finished, but images don't match.");
			return;
		}
		
		//hide spinner
		self.indicator.hidden = TRUE;
		[self.indicator stopAnimating];
		
		//if image was downloaded, use it.
		if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
			self.imageView.image = image;
		}
	}];
	
}

@end
````

# License

The MIT License (MIT)
Copyright (c) 2016 Aaron Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.