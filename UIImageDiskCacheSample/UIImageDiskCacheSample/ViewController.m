
#import "ViewController.h"
#import "UIImageDiskCache.h"

@interface ViewController ()
@end

@implementation ViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	UIImageDiskCache * cache = [UIImageDiskCache defaultDiskCache];
	NSLog(@"cache path: %@",cache.cacheDirectory);
	//[UIImageDiskCache defaultDiskCache].etagOnlyCacheControl = 604800;
	[UIImageDiskCache defaultDiskCache].useServerCachePolicy = FALSE;
	[UIImageDiskCache defaultDiskCache].logCacheMisses = FALSE;
	
	__weak ViewController * weakself = self;
	NSURL * imageURL = [NSURL URLWithString:@"http://cp91279.biography.com/1000509261001/1000509261001_1822941199001_BIO-Biography-31-Innovators-Steve-Jobs-115958-SF.jpg"];
	
	[self.imageView setImageWithURL:imageURL completion:^(NSError *error, UIImage *image, NSURL * url, UIImageLoadSource loadSource) {
		
		if(loadSource == UIImageLoadSourceDisk) {
			NSLog(@"steve from disk");
		} else if(loadSource == UIImageLoadSourceNetworkToDisk) {
			NSLog(@"steve from network");
		}
		[cache.memoryCache cacheImage:image forURL:url];
		
		[weakself.imageView setImageWithURL:imageURL completion:^(NSError *error, UIImage *image, NSURL * url, UIImageLoadSource loadSource) {
			if(loadSource == UIImageLoadSourceMemory) {
				NSLog(@"steve from memory");
			}
		}];
		
	}];
	
	
	
	imageURL = [NSURL URLWithString:@"http://i1-news.softpedia-static.com/images/news2/How-To-Change-the-Language-on-Your-iPhone-iPod-touch-2.png"];
	
	[self.button setImageForControlState:UIControlStateNormal withURL:imageURL completion:^(NSError *error, UIImage *image, NSURL * url, UIImageLoadSource loadSource) {
		
	}];
}

@end
