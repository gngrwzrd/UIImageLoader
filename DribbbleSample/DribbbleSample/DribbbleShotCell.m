
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
