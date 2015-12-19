
#import "ViewController.h"
#import "UIImageDiskCache.h"

@interface ViewController ()
@end

@implementation ViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	NSLog(@"cache path: %@",[UIImageDiskCache defaultDiskCache].cacheDirectory);
	//[UIImageDiskCache defaultDiskCache].etagOnlyCacheControl = 604800;
	[UIImageDiskCache defaultDiskCache].useServerCachePolicy = FALSE;
	[UIImageDiskCache defaultDiskCache].logCacheMisses = FALSE;
	
	NSURL * image = [NSURL URLWithString:@"http://cp91279.biography.com/1000509261001/1000509261001_1822941199001_BIO-Biography-31-Innovators-Steve-Jobs-115958-SF.jpg"];
	
	[self.imageView setImageWithURL:image completion:^(NSError *error, UIImage *image) {
		
	}];
	
	image = [NSURL URLWithString:@"http://i1-news.softpedia-static.com/images/news2/How-To-Change-the-Language-on-Your-iPhone-iPod-touch-2.png"];
	
	[self.button setImageForControlState:UIControlStateNormal withURL:image completion:^(NSError *error, UIImage *image) {
		
	}];
}

@end
