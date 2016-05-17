//
//  XPageView.h
//  OneLucky
//
//  Created by mt on 16/5/16.
//  Copyright © 2016年 imakejoy. All rights reserved.
//

#ifdef DEBUG
#define XLog(format, ...)  NSLog(format, ## __VA_ARGS__)
#else
#define XLog(...)
#endif

#import <UIKit/UIKit.h>


@interface XPageView : UIView

/**
 *  支持Autolayout 和 frame，利用collectionView的view复用回收机制
 *
 *  @param frame            CGRect 如果是AL可以为CGRectZero
 *  @param childVCs         <#childVCs description#>
 *  @param parentController 父控制器
 *
 *  @return <#return value description#>
 */
-(instancetype)initWithFrame:(CGRect)frame childViewControllers:(NSArray *)childVCs parentController:(UIViewController *)parentController;

/**
 *  给外界可以设置ContentOffSet的方法
 *
 *  @param offset   <#offset description#>
 *  @param animated <#animated description#>
 */
- (void)setContentOffSet:(CGPoint)offset animated:(BOOL)animated;
/**
 *  给外界刷新视图的方法
 *
 *  @param newChileVcs <#newChileVcs description#>
 */
- (void)reloadAllViewsWithNewChildVcs:(NSArray *)newChileVcs;

@property (nonatomic ,copy) void(^contentViewDidMoveCallback)(NSInteger fromIndex ,NSInteger toIndex ,CGFloat progress);

@property (nonatomic ,copy) void(^contentViewEndMoveCallback)(NSInteger currentIndex);
@end
