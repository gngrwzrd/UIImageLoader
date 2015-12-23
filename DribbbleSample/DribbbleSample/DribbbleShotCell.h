
#import <UIKit/UIKit.h>

@interface DribbbleShotCell : UICollectionViewCell
@property IBOutlet UIImageView * imageView;
@property IBOutlet UIActivityIndicatorView * indicator;
- (void) setShot:(NSDictionary *) shot;
@end
