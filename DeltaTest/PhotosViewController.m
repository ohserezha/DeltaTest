//
//  PhotosViewController.m
//  DeltaTest
//
//  Created by ezkeemo on 1/20/17.
//  Copyright © 2017 ezkeemo. All rights reserved.
//

#import "PhotosViewController.h"

@interface PhotosViewController () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) PHFetchResult *photosFetchResult;
@property (strong, nonatomic) PHImageManager *imageManager;
@property (nonatomic, assign) PHAuthorizationStatus photoAuthStatus;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation PhotosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    self.photoAuthStatus = [PHPhotoLibrary authorizationStatus];
    __weak typeof(self) weakSelf = self;
    if (self.photoAuthStatus == PHAuthorizationStatusNotDetermined) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                weakSelf.photoAuthStatus = status;
                [weakSelf fetchPhotosFromLibrary];
            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
//                });
            }
        }];
        
    } else if (self.photoAuthStatus == PHAuthorizationStatusAuthorized) {
        
        [self fetchPhotosFromLibrary];
        
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Denied" message:@"You've denied access to photo library. Allow it in settings to be able to change photo" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDestructive handler:nil];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}


- (void)fetchPhotosFromLibrary {
    self.imageManager = [[PHCachingImageManager alloc] init];
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    self.photosFetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.collectionView reloadData];
    });
}

#pragma mark - UICollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photosFetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PHAsset *asset = self.photosFetchResult[indexPath.item];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    CGFloat cellWidth = collectionView.frame.size.width / 3.0 - 6;
    CGSize cellSize = CGSizeMake(cellWidth, cellWidth);
    [self.imageManager requestImageForAsset:asset
                                 targetSize:cellSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      UIImageView *thumbnailView = [[UIImageView alloc] initWithFrame:cell.contentView.frame];
                                      thumbnailView.image = result;
                                      thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
                                      [cell.contentView addSubview:thumbnailView];
                                  });
                              }];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.collectionView.frame.size.width / 3.0 - 6, self.collectionView.frame.size.width / 3.0 - 6);
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.photosFetchResult];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (changes) {
            self.photosFetchResult = [changes fetchResultAfterChanges];
            
            if (changes.hasIncrementalChanges) {
                
                NSArray <NSIndexPath *> *removedPaths = nil;
                NSArray <NSIndexPath *> *insertedPaths = nil;
                NSArray <NSIndexPath *> *changedPaths = nil;
                
                if (changes.removedIndexes.count) {
                    removedPaths = [self indexPathsFromIndexSet:changes.removedIndexes withSection:0];
                }
                if (changes.insertedIndexes) {
                    insertedPaths = [self indexPathsFromIndexSet:changes.insertedIndexes withSection:0];
                }
                if (changes.changedIndexes) {
                    changedPaths = [self indexPathsFromIndexSet:changes.changedIndexes withSection:0];
                }
                BOOL shouldReload = NO;
                if (changedPaths != nil && removedPaths != nil) {
                    for (NSIndexPath *changedPath in changedPaths) {
                        if ([removedPaths containsObject:changedPath]){
                            shouldReload = YES;
                            break;
                        }
                    }
                }
                
                if ([removedPaths lastObject].item  >= self.photosFetchResult.count) {
                    shouldReload = YES;
                }
                
                if (shouldReload) {
                    [self.collectionView reloadData];
                } else {
                    // Tell the collection view to animate insertions/deletions/moves
                    // and to refresh any cells that have changed content.
                    [self.collectionView performBatchUpdates:^{
                        if (removedPaths) {
                            [self.collectionView deleteItemsAtIndexPaths:removedPaths];
                        }
                        if (insertedPaths) {
                            [self.collectionView insertItemsAtIndexPaths:insertedPaths];
                        }
                        if (changedPaths) {
                            [self.collectionView reloadItemsAtIndexPaths:changedPaths];
                        }
                        if (changes.hasMoves) {
                            [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                                NSIndexPath *fromIndexPath = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                                NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
                                [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                            }];
                        }
                    } completion:nil];
                }
            } else {
                [self.collectionView reloadData];
            }
        }
    });
}

- (NSArray <NSIndexPath *> *)indexPathsFromIndexSet:(NSIndexSet *)indexSet withSection:(NSUInteger)section {
    if (indexSet == nil) {
        return nil;
    }
    NSMutableArray <NSIndexPath *> *indexPaths = [NSMutableArray array];
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
    }];
    
    return indexPaths;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
