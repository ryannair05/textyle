#import "TXTStyleSelectionController.h"
#import "TXTStyleCell.h"
#import "TXTStyleManager.h"
#import "TXTConstants.h"

@implementation TXTStyleSelectionController {
    NSArray *styles;
    NSString *activeStyle;
    NSIndexPath *selectedIndexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupMenuView];
    [self load];
}

- (void)load {
    TXTStyleManager *styleManager = [TXTStyleManager sharedManager];
    styles = [styleManager enabledStyles];
    activeStyle = [styleManager activeStyle][@"name"];

    [self selectActiveStyle];
}

- (void)reload {
    [self load];
    [self.collectionView reloadData];
}

- (void)selectActiveStyle {
    NSUInteger index = [styles indexOfObjectPassingTest:^BOOL (NSDictionary *dict, NSUInteger idx, BOOL *stop) {
        return [[dict objectForKey:@"name"] isEqual:activeStyle];
    }];

    selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:0];

    [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:selectedIndexPath];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupMenuView {

    CGSize size = self.view.frame.size;

    self.view.frame = CGRectMake(0, 0, kMenuWidth, kMenuHeight);

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];

    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.itemSize = CGSizeMake(230, 48);

    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[TXTStyleCell class] forCellWithReuseIdentifier:kCellReuseIdentifier];

    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.layer.cornerRadius = kCornerRadius;
    _collectionView.layer.shadowColor = [UIColor blackColor].CGColor;
    _collectionView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _collectionView.layer.shadowRadius = 10.0f;
    _collectionView.layer.shadowOpacity = 0.27f;

    UIView *blurMask = [[UIView alloc] initWithFrame:_collectionView.bounds];
    blurMask.layer.cornerRadius = kCornerRadius;
    blurMask.clipsToBounds = YES;

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame = blurMask.bounds;
    blurView.layer.masksToBounds = NO;
    [blurMask addSubview:blurView];

    [blurMask setCenter:CGPointMake(size.width / 2, (size.height + 230) / 3)];
    [_collectionView setCenter:CGPointMake(size.width / 2, (size.height + 230) / 3)];
    
    [self.view addSubview:blurMask];
    [self.view addSubview:_collectionView];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TXTStyleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];

    cell.name = styles[indexPath.row][@"name"];
    [cell.label setText:styles[indexPath.row][@"label"]];

    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return styles.count;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UIImpactFeedbackGenerator *hapticFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];

    [hapticFeedbackGenerator prepare];
    [hapticFeedbackGenerator impactOccurred];
    hapticFeedbackGenerator = nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    selectedIndexPath = indexPath;

    TXTStyleCell *cell = (TXTStyleCell *)[collectionView cellForItemAtIndexPath:indexPath];

    [UIView animateWithDuration:0.1
                     animations:^{
                         [cell setBackgroundColor:[UIColor colorWithRed:1.00 green:0.18 blue:0.33 alpha:1.0f]];
                     }
                     completion:^(BOOL finished) {
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
    ];

    if (cell.name && ![cell.name isEqualToString:activeStyle]) {
        [[TXTStyleManager sharedManager] selectStyle:cell.name];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    [UIView animateWithDuration:0.1
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
                         [cell setBackgroundColor:[UIColor clearColor]];
                     }
                     completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:selectedIndexPath]) {
        [cell setBackgroundColor:[UIColor colorWithRed:1.00 green:0.18 blue:0.33 alpha:1.0f]];
    } else {
        [cell setBackgroundColor:[UIColor clearColor]];
    }
}

@end
