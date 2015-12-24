
#import "DribbbleCell.h"
#import "UIImageLoader.h"

@interface DribbbleCell ()
@property BOOL cancelsTask;
@property NSURL * activeURL;
@property NSURLSessionDataTask * task;
@end

@implementation DribbbleCell

- (void) awakeFromNib {
	//set to FALSE to let images download even if this cells image has changed while scrolling.
	self.cancelsTask = FALSE;
	
	//set to TRUE to cause downloads to cancel if a cell is being reused.
	//self.cancelsTask = TRUE;
}

- (void) prepareForReuse {
	self.imageView.image = nil;
	self.spinner.hidden = TRUE;
	if(self.cancelsTask) {
		[self.task cancel];
	}
}

- (void) setRepresentedObject:(id)representedObject {
	NSDictionary * shot = (NSDictionary *)representedObject;
	NSDictionary * images = shot[@"images"];
	
	NSURL * url = [NSURL URLWithString:images[@"normal"]];
	self.activeURL = url;
	
	self.task = [[UIImageLoader defaultLoader] loadImageWithURL:self.activeURL hasCache:^(UIImageLoaderImage *image, UIImageLoadSource loadedFromSource) {
		
		self.imageView.image = image;
		self.spinner.hidden = TRUE;
		[self.spinner stopAnimation:nil];
		
	} sendRequest:^(BOOL didHaveCachedImage) {
		
		if(!didHaveCachedImage) {
			[self.spinner startAnimation:nil];
			self.spinner.hidden = FALSE;
		}
		
	} requestCompleted:^(NSError *error, UIImageLoaderImage *image, UIImageLoadSource loadedFromSource) {
		
		[self.spinner stopAnimation:nil];
		self.spinner.hidden = TRUE;
		
		if(!self.cancelsTask && ![self.activeURL.absoluteString isEqualToString:url.absoluteString]) {
			return;
		}
		
		if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
			self.imageView.image = image;
		}
	}];
}

@end
