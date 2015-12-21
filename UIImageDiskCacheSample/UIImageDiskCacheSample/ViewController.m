
#import "ViewController.h"
#import "UIImageLoader.h"

@interface ViewController ()
@end

@implementation ViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	UIImageLoader * cache = [UIImageLoader defaultLoader];
	NSLog(@"cache path: %@",cache.cacheDirectory);
	cache.etagOnlyCacheControl = 604800;
	//[UIImageDiskCache defaultDiskCache].useServerCachePolicy = FALSE;
	//[UIImageDiskCache defaultDiskCache].logCacheMisses = FALSE;
	
	NSURL * imageURL = [NSURL URLWithString:@"http://cp91279.biography.com/1000509261001/1000509261001_1822941199001_BIO-Biography-31-Innovators-Steve-Jobs-115958-SF.jpg"];
	
	[cache loadImageWithURL:imageURL hasCache:^(UIImage *image, UIImageLoadSource loadedFromSource) {
		self.imageView.image = image;
	} sendRequest:^(BOOL didHaveCachedImage) {
		
	} requestCompleted:^(NSError *error, UIImage *image, UIImageLoadSource loadedFromSource) {
		if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
			self.imageView.image = image;
		}
	}];
	
	imageURL = [NSURL URLWithString:@"http://i1-news.softpedia-static.com/images/news2/How-To-Change-the-Language-on-Your-iPhone-iPod-touch-2.png"];
	
	[cache loadImageWithURL:imageURL hasCache:^(UIImage *image, UIImageLoadSource loadedFromSource) {
		[self.button setImage:image forState:UIControlStateNormal];
	} sendRequest:^(BOOL didHaveCachedImage) {
		
	} requestCompleted:^(NSError *error, UIImage *image, UIImageLoadSource loadedFromSource) {
		if(loadedFromSource == UIImageLoadSourceNetworkToDisk) {
			[self.button setImage:image forState:UIControlStateNormal];
		}
	}];
	
}

@end
