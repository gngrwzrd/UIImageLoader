
#import "AppDelegate.h"
#import "ViewController.h"
#import "UIImageLoader.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	UIImageLoader * loader = [UIImageLoader defaultLoader];
	loader.useServerCachePolicy = TRUE;
	loader.cacheImagesInMemory = TRUE;
	loader.memoryCache.maxBytes = 50 * (1024 * 1024); //50MB
	
	[loader clearCachedFilesOlderThan1Day];
	
	NSLog(@"cache dir: %@",loader.cacheDirectory);
	
	self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.window.rootViewController = [[ViewController alloc] init];
	[self.window makeKeyAndVisible];
	
	return YES;
}

@end
