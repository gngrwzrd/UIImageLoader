
#import "ViewController.h"
#import "UIImageDiskCache.h"

@interface ViewController ()
@end

@implementation ViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	UIImageDiskCache * cache = [UIImageDiskCache defaultDiskCache];
	NSLog(@"cache path: %@",cache.cacheDirectory);
	[UIImageDiskCache defaultDiskCache].etagOnlyCacheControl = 604800;
	//[UIImageDiskCache defaultDiskCache].useServerCachePolicy = FALSE;
	//[UIImageDiskCache defaultDiskCache].logCacheMisses = FALSE;
	
	NSURL * imageURL = [NSURL URLWithString:@"http://cp91279.biography.com/1000509261001/1000509261001_1822941199001_BIO-Biography-31-Innovators-Steve-Jobs-115958-SF.jpg"];
	
	__weak ViewController * weakself = self;
	
	[self.imageView setImageWithURL:imageURL hasCache:^(UIImage *image, UIImageLoadSource loadedFromSource) {
		weakself.imageView.image = image;
	} sendRequest:^(BOOL didHaveCachedImage) {
		
	} requestCompleted:^(NSError *error, UIImage *image, UIImageLoadSource loadedFromSource) {
		if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
			weakself.imageView.image = image;
		}
	}];
	
//	imageURL = [NSURL URLWithString:@"http://i1-news.softpedia-static.com/images/news2/How-To-Change-the-Language-on-Your-iPhone-iPod-touch-2.png"];
//	[self.button setImageForControlState:UIControlStateNormal withURL:imageURL completion:^(NSError *error, UIImage *image, NSURL * url, UIImageLoadSource loadSource) {
//		
//	}];
}

@end
