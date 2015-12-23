
#import <UIKit/UIKit.h>

@interface DribbbleShotCell : UICollectionViewCell
@property IBOutlet UIImageView * imageView;
@property IBOutlet UIActivityIndicatorView * indicator;
@property BOOL cancelsTask;
- (void) setShot:(NSDictionary *) shot;
@end
