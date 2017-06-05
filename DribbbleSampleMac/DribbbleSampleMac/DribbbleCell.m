
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
	self.imageView.image = [NSImage imageNamed:@"dribbble_ball"];
	self.spinner.hidden = TRUE;
	if(self.cancelsTask) {
		[self.task cancel];
	}
}

- (void) setRepresentedObject:(id)representedObject {
	self.imageView.image = [NSImage imageNamed:@"dribbble_ball"];
	NSDictionary * shot = (NSDictionary *)representedObject;
	NSDictionary * images = shot[@"images"];
	NSURL * url = [NSURL URLWithString:images[@"normal"]];
	[self.imageView uiImageLoader_setCancelsRunningTask:false];
	[self.imageView uiImageLoader_setSpinner:self.spinner];
	[self.imageView uiImageLoader_setImageWithURL:url];
}

@end
