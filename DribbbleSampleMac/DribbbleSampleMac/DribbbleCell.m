
#import "DribbbleCell.h"
#import "UIImageLoader.h"

@interface DribbbleCell ()
@end

@implementation DribbbleCell

- (void) prepareForReuse {
	self.imageView.image = [NSImage imageNamed:@"dribbble_ball"];
	self.spinner.hidden = TRUE;
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

- (void) dealloc {
	[self.imageView uiImageLoader_setSpinner:nil];
}

@end
