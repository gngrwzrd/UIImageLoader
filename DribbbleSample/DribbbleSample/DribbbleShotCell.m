
#import "DribbbleShotCell.h"
#import "UIImageLoader.h"

@interface DribbbleShotCell ()
@end

@implementation DribbbleShotCell

- (void) awakeFromNib {
	[super awakeFromNib];
	self.imageView.image = [UIImage imageNamed:@"dribbble_ball"];
	self.imageView.contentMode = UIViewContentModeCenter;
	[self.indicator startAnimating];
}

- (void) prepareForReuse {
	self.imageView.image = [UIImage imageNamed:@"dribbble_ball"];
	self.imageView.contentMode = UIViewContentModeCenter;
}

- (void) setShot:(NSDictionary *) shot {
	NSDictionary * images = shot[@"images"];
	NSURL * url = [NSURL URLWithString:images[@"normal"]];
	[self.imageView uiImageLoader_setSpinner:self.indicator];
	[self.imageView uiImageLoader_setCancelsRunningTask:false];
	[self.imageView uiImageLoader_setFinalContentMode:UIViewContentModeScaleAspectFit];
	[self.imageView uiImageLoader_setImageWithURL:url];
}

@end
