//
//  XPageView.m
//  OneLucky
//
//  Created by mt on 16/5/16.
//  Copyright © 2016年 imakejoy. All rights reserved.
//

#import "XPageView.h"

@interface XPageView () <UICollectionViewDelegate ,UICollectionViewDataSource ,UIScrollViewDelegate ,UIGestureRecognizerDelegate>{
    NSInteger _oldIndex;
    NSInteger _currentIndex;
    CGFloat   _oldOffSetX;
}
// 用于处理重用和内容的显示
@property (weak, nonatomic) UICollectionView *collectionView;
// collectionView的布局
@property (strong, nonatomic) UICollectionViewFlowLayout *collectionViewLayout;
// 父类 用于处理添加子控制器  使用weak避免循环引用
@property (weak, nonatomic) UIViewController *parentViewController;
// 当这个属性设置为YES的时候 就不用处理 scrollView滚动的计算
@property (assign, nonatomic) BOOL forbidTouchToAdjustPosition;
// 所有的子控制器
@property (strong, nonatomic) NSArray *childVcs;

@end

static NSString *cellID = @"cell";

@implementation XPageView

-(instancetype)initWithFrame:(CGRect)frame childViewControllers:(NSArray *)childVCs parentController:(UIViewController *)parentController{
    if (self = [super initWithFrame:frame]) {
        self.childVcs = childVCs;
        self.parentViewController = parentController;
        _oldIndex = 0;
        _currentIndex = 1;
        _oldOffSetX = 0.0;
        self.forbidTouchToAdjustPosition = NO;
        // 触发懒加载
        self.collectionView.backgroundColor = [UIColor whiteColor];
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    for (UIViewController *childVc in self.childVcs) {
        
        NSAssert([childVc isKindOfClass:[UIViewController class]], @"只允许添加ViewController以及子类");
        
        NSAssert(self.parentViewController, @"请设置父控制器");
        
        if (self.parentViewController) {
            [self.parentViewController addChildViewController:childVc];
        }
    }
    
    if (self.parentViewController.parentViewController && [self.parentViewController.parentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navi = (UINavigationController *)self.parentViewController.parentViewController;
        
        if (navi.interactivePopGestureRecognizer) {
            navi.interactivePopGestureRecognizer.delegate = self;
            [self.collectionView.panGestureRecognizer requireGestureRecognizerToFail:navi.interactivePopGestureRecognizer];
        }
    }
}

- (void)dealloc {
    self.parentViewController = nil;
    XLog(@"XPageView---销毁");
}

#pragma mark - public helper

/** 给外界可以设置ContentOffSet的方法 */
- (void)setContentOffSet:(CGPoint)offset animated:(BOOL)animated {
    self.forbidTouchToAdjustPosition = YES;
    [self.collectionView setContentOffset:offset animated:animated];
}

/** 给外界刷新视图的方法 */
- (void)reloadAllViewsWithNewChildVcs:(NSArray *)newChileVcs {
    // 这种处理是结束子控制器和父控制器的关系
    for (UIViewController *childVc in self.childVcs) {
        [childVc willMoveToParentViewController:nil];
        [childVc.view removeFromSuperview];
        [childVc removeFromParentViewController];
    }
    
    self.childVcs = nil;
    self.childVcs = newChileVcs;
    [self commonInit];
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate --- UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.childVcs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellID forIndexPath:indexPath];
    // 移除subviews 避免重用内容显示错误
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 这里建立子控制器和父控制器的关系  -> 当然在这之前已经将对应的子控制器添加到了父控制器了, 只不过还没有建立完成
    UIViewController *vc = (UIViewController *)self.childVcs[indexPath.row];
    vc.view.frame = self.bounds;
    [cell.contentView addSubview:vc.view];
    [vc didMoveToParentViewController:self.parentViewController];
    
    return cell;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.forbidTouchToAdjustPosition) {
        return;
    }
    CGFloat offSetX = scrollView.contentOffset.x;
    CGFloat temp = offSetX / self.bounds.size.width;
    CGFloat progress = temp - floor(temp);
    if (offSetX - _oldOffSetX >= 0) {
        if (progress == 0.0) {
            return;
        }
        _oldIndex = (offSetX/self.bounds.size.width);
        _currentIndex = _oldIndex + 1;
        if (_currentIndex >= self.childVcs.count) {
            _currentIndex = self.childVcs.count -1;
            return;
        }
    } else {
        _currentIndex = (offSetX / self.bounds.size.width);
        _oldIndex = _currentIndex + 1;
        if (_oldIndex >= self.childVcs.count) {
            _oldIndex = self.childVcs.count - 1;
            return;
        }
        progress = 1.0 - progress;
        
    }
    
    
    
    [self contentViewDidMoveFromIndex:_oldIndex toIndex:_currentIndex progress:progress];
    
}

/**为了解决在滚动或接着点击title更换的时候因为index不同步而增加了下边的两个代理方法的判断
 
 */

/** 滚动减速完成时再更新title的位置 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentIndex = (scrollView.contentOffset.x / self.bounds.size.width);
    [self contentViewEndMoveToIndex:currentIndex];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _oldOffSetX = scrollView.contentOffset.x;
    self.forbidTouchToAdjustPosition = NO;
    
}

#pragma mark - private helper
- (void)contentViewDidMoveFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    
    if (self.contentViewDidMoveCallback) {
        self.contentViewDidMoveCallback(fromIndex ,toIndex ,progress);
    }
}

- (void)contentViewEndMoveToIndex:(NSInteger)currentIndex {
    
    if (self.contentViewEndMoveCallback) {
        self.contentViewEndMoveCallback(currentIndex);
    }
}

#pragma mark - getter --- setter
- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.collectionViewLayout];
        collectionView.pagingEnabled = YES;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellID];
        collectionView.bounces = NO;
        
        collectionView.scrollsToTop = NO;
        
        [self addSubview:collectionView];
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (UICollectionViewFlowLayout *)collectionViewLayout {
    if (_collectionViewLayout == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
//        layout.itemSize = self.bounds.size;
        layout.minimumLineSpacing = 0.0;
        layout.minimumInteritemSpacing = 0.0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionViewLayout = layout;
    }
    
    return _collectionViewLayout;
}

/**
 *  AutoLayout 与 Frame 的 汇合时机就是 layout以后的时候
 */
-(void)layoutSubviews{
    [super layoutSubviews];
    [self layoutIfNeeded];
    
    self.collectionViewLayout.itemSize = self.bounds.size;
    self.collectionView.frame = self.bounds;
}

@end
