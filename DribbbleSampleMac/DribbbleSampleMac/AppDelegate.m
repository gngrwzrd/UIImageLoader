
#import "AppDelegate.h"
#import "DribbbleCell.h"
#import "UIImageLoader.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property Dribbble * dribbble;
@property NSMutableArray * dribbbleShots;
@property NSInteger page;
@property NSInteger maxPage;
@end

@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
	
	UIImageLoader * loader = [UIImageLoader defaultLoader];
	NSLog(@"cache path: %@",loader.cacheDirectory);
	loader.cacheImagesInMemory = TRUE;
	loader.memoryCache.maxBytes = 50 * (1024 * 1024); //50MB
	[loader clearCachedFilesModifiedOlderThan1Week];
	
	self.page = 0;
	self.maxPage = 10;
	self.dribbbleShots = [NSMutableArray array];
	
	self.dribbble = [[Dribbble alloc] init];
	self.dribbble.accessToken = @"810c4b42e1b024288936ca1150ce3608faf22ce81fb046b12798f0b84767f22b";
	self.dribbble.clientSecret = @"7957361fe9c0f0e399712922e688101966e1eb243025f7d1dcb594a00f926104";
	self.dribbble.clientId = @"e5a423e0ea9b42d05d721ea29078f19b78804c11d9ed63b51db2c4081fe25228";
	
	//NSNib * nib = [[NSNib alloc] initWithNibNamed:@"DribbbleCell" bundle:[NSBundle mainBundle]];
	//[self.collectionView registerNib:nib forItemWithIdentifier:@"DribbbleCell"];
	[self.collectionView registerClass:[DribbbleCell class] forItemWithIdentifier:@"DribbbleCell"];
	
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	
	[self loadDribbbleShots];
}

- (void) loadDribbbleShots {
	[self.spinner startAnimation:nil];
	self.page++;
	
	//this loads 100 shots up to max pages.
	[self.dribbble listShotsWithParameters:@{@"per_page":@"100",@"page":[NSString stringWithFormat:@"%lu",self.page]} completion:^(DribbbleResponse *response) {
		
		if(response.error) {
			NSAlert * alert = [[NSAlert alloc] init];
			alert.messageText = response.error.localizedDescription;
			[alert addButtonWithTitle:@"OK"];
			[alert runModal];
			return;
		}
		
		[self.dribbbleShots addObjectsFromArray:response.data];
		
		if(self.page < self.maxPage) {
			[self performSelectorOnMainThread:@selector(loadDribbbleShots) withObject:nil waitUntilDone:FALSE];
		} else {
			[self finishedDribbbleLoad];
		}
	}];
}

- (void) finishedDribbbleLoad {
	self.loading.hidden = TRUE;
	self.spinner.hidden = TRUE;
	[self.spinner stopAnimation:nil];
	[self.collectionView reloadData];
}

- (NSInteger) numberOfSectionsInCollectionView:(NSCollectionView *)collectionView {
	return 1;
}

- (NSInteger) collectionView:(NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.dribbbleShots.count;
}

- (NSCollectionViewItem * ) collectionView:(NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(NSIndexPath *)indexPath {
	NSCollectionViewItem * cell = [collectionView makeItemWithIdentifier:@"DribbbleCell" forIndexPath:indexPath];
	cell.representedObject = [self.dribbbleShots objectAtIndex:indexPath.item];
	return cell;
}

@end
