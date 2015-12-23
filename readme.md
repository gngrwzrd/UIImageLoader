# UIImageLoader

UIImageLoader is a helper to load images from the web. It caches images on disk, and optionally in memory.

It makes it super simple to write handler code for cached images, set a placeholder image or show a loader when a network request is being made, and handle any errors on request completion.

It supports server cache control to re-download images when expired. Cache control logic is implemented manually instead of using an NSURLCache for performance reasons.

You can also completely ignore server cache control and manually clean-up images yourself.

It's very small at roughly 600+ lines of code in a single header / implementation file.

Everything is asynchronous and uses modern objective-c with libdispatch and NSURLSession.

## Server Cache Control

It works with servers that support ETag/If-None-Match and Cache-Control headers.

If the server responds with only ETag you can optionally cache the image for a default amount of time. Or let the loader make requests each time to check for new content.

If a response is 304 it uses the cached image available on disk.

## Installation

Download, fork, clone or submodule this repo. Then add UIImageLoader.h/m to your Xcode project.

## UIImageLoader Object

There's a default configured loader which you're free to configure how you like.

````
//this is default how everything is configued by default

//default cache dir -> ~/Library/Caches/UIImageLoader
NSURL * appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
NSURL * defaultCacheDir = [appSupport URLByAppendingPathComponent:@"UIImageLoader"];
[[NSFileManager defaultManager] createDirectoryAtURL:defaultCacheDir withIntermediateDirectories:TRUE attributes:nil error:nil];

//default image loader
UIImageLoader * loader = [UIImageLoader defaultLoader];
loader.cacheImagesInMemory = FALSE;
loader.trustAnySSLCertificate  = FALSE;
loader.useServerCachePolicy = TRUE;
loader.logCacheMisses = TRUE;
loader.logResponseWarnings = TRUE;
loader.etagOnlyCacheControl = 0;
loader.memoryCache.maxBytes = 25 * (1024 * 1024); //25MB;
loader.acceptedContentTypes = @[@"image/png",@"image/jpg",@"image/jpeg",@"image/bmp",@"image/gif",@"image/tiff"];
````

Or you can setup your own and configure it:

````
//create a directory for the disk cache
NSURL * appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
NSURL * defaultCacheDir = [appSupport URLByAppendingPathComponent:@"UIImageLoader"];
[[NSFileManager defaultManager] createDirectoryAtURL:defaultCacheDir withIntermediateDirectories:TRUE attributes:nil error:nil];

//create loader
UIImageLoader * loader = [[UIImageLoader alloc] initWithCacheDirectory:defaultCacheDir];
//set loader properties here.
````

### Loading an Image

It's easy to load an image:

````
NSURL * imageURL = myURL;	

[[UIImageLoader defaultLoader] loadImageWithURL:imageURL \

hasCache:^(UIImage *image, UIImageLoadSource loadedFromSource) {
	
	//there was a cached image available. use that.
	self.imageView.image = image;
	
} sendRequest:^(BOOL didHaveCachedImage) {
	
	//a request is being made for the image.
	
	if(!didHaveCachedImage) {
		
		//there was not a cached image available, set a placeholder or do nothing.
		self.loader.hidden = FALSE;
	    [self.loader startAnimating];
	    self.imageView.image = [UIImage imageNamed:@"placeholder"];
	}
	
} requestCompleted:^(NSError *error, UIImage *image, UIImageLoadSource loadedFromSource) {
	
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
	UIImageLoadSourceNone,               //no image source as there was an error.
	
	//these will be passed to your hasCache callback
	UIImageLoadSourceDisk,               //image was cached on disk already and loaded from disk
	UIImageLoadSourceMemory,             //image was in memory cache
	
    //these will be passed to your requestCompleted callback
	UIImageLoadSourceNetworkNotModified, //a network request was sent but existing content is still valid
	UIImageLoadSourceNetworkToDisk,      //a network request was sent, image was updated on disk
	UIImageLoadSourceNetworkCancelled,   //a network request was sent, but the NSURLSessionDataTask was cancelled
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

If load source is _UIImageLoadSourceNetworkToDisk_, it means a new image was downloaded. Either it was a new download, or existing cache was updated. You should use the new image provided.

If load source is _UIImageLoadSourceNetworkNotModified_, it means the cached image is still valid. You won't receive an image in this case as the image was already passed to your _hasCache_ callback.

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

# Dribbble Sample

There's a very simple sample application that shows loading images into a collection view. The app loads 1000 images from dribbble.

The sample app requires a submodule, if you want to test the sample app it's best to clone this repo:

````
git clone git@github.com:/gngrwzrd/UIImageLoader.git
cd UIImageLoader
git submodule init
git submodule update
````

The app demonstrates how to setup a cell to load images, but gracefully show spinners, and gracefully handle when a cell is reused but a request hasn't finished loading.

You will need to create a Dribbble API application in order to test it.

You can create a dribbble app very easily here (you'll at least need to signup):

[https://dribbble.com/account/applications/](https://dribbble.com/account/applications/)

Once you've created a dribbble application, update the ViewController.m file:

````
- (void) setupDribbble {
	//see README.md in the DribbbleSample folder.
	self.dribbble = [[Dribbble alloc] init];
	self.dribbble.accessToken = @"";
	self.dribbble.clientSecret = @"";
	self.dribbble.clientId = @"";
}
````

Here's the collection view cell source from the sample application:

````
//DribbbleShot.h
#import <UIKit/UIKit.h>

@interface DribbbleShotCell : UICollectionViewCell
@property IBOutlet UIImageView * imageView;
@property IBOutlet UIActivityIndicatorView * indicator;
- (void) setShot:(NSDictionary *) shot;
@end

````

````
//DribbbleShotCell.m
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
		
	} sendRequest:^(BOOL didHaveCachedImage) {
		
		if(!didHaveCachedImage) {
			//a cached image wasn't available, a network request is being sent, show spinner.
			[self.indicator startAnimating];
			self.indicator.hidden = FALSE;
		}
		
	} requestCompleted:^(NSError *error, UIImageLoaderImage *image, UIImageLoadSource loadedFromSource) {
		
		//request complete.
		
		//check if url above matches self.activeURL.
		//If they don't match this cells image is going to be different.
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