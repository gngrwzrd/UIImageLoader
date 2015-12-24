
#import <Cocoa/Cocoa.h>
#import "Dribbble.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSCollectionViewDataSource,NSCollectionViewDelegate>
@property IBOutlet NSCollectionView * collectionView;
@property IBOutlet NSProgressIndicator * spinner;
@property IBOutlet NSTextField * loading;
@end
