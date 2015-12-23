
#import "ViewController.h"
#import "Dribbble.h"
#import "DribbbleShotCell.h"
#import "MBProgressHUD.h"

@interface ViewController ()
@property NSMutableArray * dribbbleShots;
@property NSInteger page;
@property NSInteger maxPage;
@property Dribbble * dribbble;
@end

@implementation ViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	self.page = 0;
	self.maxPage = 10;
	self.dribbbleShots = [[NSMutableArray alloc] init];
	
	UINib * nib = [UINib nibWithNibName:@"DribbbleShotCell" bundle:nil];
	[self.collectionView registerNib:nib forCellWithReuseIdentifier:@"DribbbleShotCell"];
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	
	[self setupDribbble];
	
	MBProgressHUD * hud = [MBProgressHUD showHUDAddedTo:self.view animated:TRUE];
	hud.labelText = @"Loading Dribbble Shots";
	
	[self loadDribbbleShots];
}

- (void) setupDribbble {
	//see README.md in the DribbbleSample folder.
	self.dribbble = [[Dribbble alloc] init];
	self.dribbble.accessToken = @"";
	self.dribbble.clientSecret = @"";
	self.dribbble.clientId = @"";
}

- (void) loadDribbbleShots {
	self.page++;
	
	//this loads 100 shots up to max pages.
	[self.dribbble listShotsWithParameters:@{@"per_page":@"100",@"page":[NSString stringWithFormat:@"%lu",self.page]} completion:^(DribbbleResponse *response) {
		[self.dribbbleShots addObjectsFromArray:response.data];
		if(self.page < self.maxPage) {
			[self performSelectorOnMainThread:@selector(loadDribbbleShots) withObject:nil waitUntilDone:FALSE];
		} else {
			[self finishedDribbbleLoad];
		}
	}];
}

- (void) finishedDribbbleLoad {
	[MBProgressHUD hideHUDForView:self.view animated:TRUE];
	[self.collectionView reloadData];
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.dribbbleShots.count;
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	DribbbleShotCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DribbbleShotCell" forIndexPath:indexPath];
	[cell setShot:[self.dribbbleShots objectAtIndex:indexPath.row]];
	return cell;
}

@end
