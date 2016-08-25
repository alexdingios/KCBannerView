//
//  KCPictureRepeatView.m
//  无线循环图片轮播器demo
//
//  Created by xiliedu on 15/8/28.
//  Copyright (c) 2015年 xiliedu. All rights reserved.
//

#import "KCBannerView.h"
#import "KCBannerCell.h"
#import "KCBanner.h"
#import "KCBannerViewLayout.h"

NSString *const KCBannerViewContentOffsetDicChangeNotification = @"KCBannerViewContentOffsetDicChangeNotification";
NSString *const KCBannerViewDicChangeFrameKey = @"KCBannerViewDicChangeFrameKey";

@implementation NSTimer (KCExtension)

+ (void)kc_block:(NSTimer *)timer {
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        block(timer);
    }
}

+ (NSTimer *)kc_timerWithTimeInterval:(NSTimeInterval)ti block:(void(^)(NSTimer *timer))block repeats:(BOOL)yesOrNo
{
    return [NSTimer timerWithTimeInterval:ti target:self selector:@selector(kc_block:) userInfo:[block copy] repeats:yesOrNo];
}

@end


static const NSInteger KCMaxSection = 100;

@interface KCBannerView () <UICollectionViewDataSource, UICollectionViewDelegate>{
    UIPageControl *_pageControl;
    BOOL _repeat;
    UIImageView *_placeholderImageView;
}


@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) CGRect changeFrame;

@end

@implementation KCBannerView


- (void)dealloc
{
    [self removeTimer];
}

#pragma mark -内部方法

- (void)addTimer
{
    if (!self.isRepeat) return;
    
    [self removeTimer];
    
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer kc_timerWithTimeInterval:self.timeInterval block:^(NSTimer *timer) {
        [weakSelf nextPage];
    } repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode: NSRunLoopCommonModes];
}

- (void)removeTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)nextPage
{
    NSIndexPath *resetIndexPath = [self resetIndexPath];
    
    NSInteger item = resetIndexPath.item + 1;
    NSInteger section = resetIndexPath.section;
    
    if (item == [self.dataSource numberOfBannersInBannerView:self]) {
        item = 0;
        section++;
    }
    
    if (self.scrollDirection == KCBannerViewScrollDirectionHorizontal) {
        
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }else {
        
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    }
    
}

- (NSIndexPath *)resetIndexPath
{
    NSIndexPath *visibleIndexPath = [[self.collectionView indexPathsForVisibleItems] lastObject];
    
    NSIndexPath *resetIndexPath = [NSIndexPath indexPathForItem:visibleIndexPath.item inSection:KCMaxSection / 2];
    
    if (self.scrollDirection == KCBannerViewScrollDirectionHorizontal) {
        
        [self.collectionView scrollToItemAtIndexPath:resetIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }else {
        
        [self.collectionView scrollToItemAtIndexPath:resetIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    }
    
    
    return resetIndexPath;
}

#pragma mark -初始化

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setup];
}

- (void)setup
{
    _timeInterval = 5.0;
    _repeat = YES;
    _scrollDirection = KCBannerViewScrollDirectionHorizontal;
    
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.collectionView];
    [self addSubview:self.pageControl];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat pageWH = 15;
    CGFloat pageControlH = pageWH;
    CGFloat pageControlW = pageWH * self.pageControl.numberOfPages;
    
    CGFloat pageControlX = (self.frame.size.width - pageControlW) * 0.5;
    CGFloat pageControlY = self.frame.size.height - pageControlH;
    
    self.pageControl.frame = CGRectMake(pageControlX, pageControlY, pageControlW, pageControlH);
    
    self.collectionView.frame = self.bounds;
    
    self.changeFrame = self.bounds;
    
    self.placeholderImageView.frame = self.bounds;
    
}


#pragma mark -UICollectionViewdataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    NSInteger count = [self.dataSource numberOfBannersInBannerView:self];

    
    self.placeholderImageView.hidden = count != 0;
    
    return count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self.dataSource numberOfBannersInBannerView:self] <= 1 ? 1 : KCMaxSection;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KCBannerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:KCBannerCellReuseID forIndexPath:indexPath];
    
    cell.banner = [self.dataSource bannerView:self bannerForItemAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark -UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(bannerView:didSelectBannerAtIndex:)]) {
        [self.delegate bannerView:self didSelectBannerAtIndex:indexPath.row];
    }
}



#pragma mark scrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self removeTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self addTimer];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger count = [self.dataSource numberOfBannersInBannerView:self];
    if (count == 0) return;
    
    NSInteger currentPage = 0;
    if (self.scrollDirection == KCBannerViewScrollDirectionHorizontal) {
        
        
       currentPage = (NSInteger)(scrollView.contentOffset.x / scrollView.bounds.size.width + 0.5) % count;
    }else {
        
        currentPage = (NSInteger)(scrollView.contentOffset.y / scrollView.bounds.size.height + 0.5) % count;
    }
    self.pageControl.currentPage = currentPage;
}

#pragma mark -公共方法

- (void)setContentOffset:(CGPoint)contentOffset
{
    _contentOffset = contentOffset;
    
    CGFloat offsetY = contentOffset.y;
    
    if (offsetY >= 0)
    {
        
        CGRect frame = self.changeFrame;
        frame.origin.y = 0;
        self.changeFrame = frame;
        self.collectionView.clipsToBounds = YES;
        
    }else {
        
        CGFloat delta = 0.0f;
        CGRect rect = self.bounds;
        delta = fabs(MIN(0.0f, offsetY));
        rect.origin.y -= delta;
        rect.size.height += delta;
        self.changeFrame = rect;
        self.collectionView.clipsToBounds = NO;
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KCBannerViewContentOffsetDicChangeNotification object:nil userInfo:@{KCBannerViewDicChangeFrameKey : [NSValue valueWithCGRect:self.changeFrame]}];

}

- (void)reloadData
{
    [self.collectionView reloadData];
    
    NSInteger count = [self.dataSource numberOfBannersInBannerView:self];
    self.pageControl.numberOfPages = count;
    
    [self addTimer];
    
    if (count > 1 && self.pageControl.currentPage < count) {
        // contentSize不为0
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.pageControl.currentPage inSection:KCMaxSection * 0.5];
                
                if (self.scrollDirection == KCBannerViewScrollDirectionHorizontal) {
                    
                    
                    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
                    
                }else {
                    
                    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                }
                
            
            
        });
    }
    
}

- (BOOL)isRepeat
{
    return [self.dataSource numberOfBannersInBannerView:self] <= 1 ? NO : _repeat;
}

- (void)setRepeat:(BOOL)repeat
{
    _repeat = repeat;
    
    if (repeat) {
        [self addTimer];
    }else {
        [self removeTimer];
    }
    
}

- (void)setdataSource:(id<KCBannerViewDataSource>)dataSource
{
    _dataSource = dataSource;
    
    [self reloadData];
}

- (void)setScrollDirection:(KCBannerViewScrollDirection)scrollDirection
{
    _scrollDirection = scrollDirection;
    
    KCBannerViewLayout *layout = (KCBannerViewLayout *)self.collectionView.collectionViewLayout;
    
    layout.scrollDirection = (UICollectionViewScrollDirection)scrollDirection;
}

#pragma mark -懒加载
- (UIPageControl *)pageControl
{
    if (!_pageControl) {
        
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.hidesForSinglePage = YES;
        _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.userInteractionEnabled = NO;
        
    }
    return _pageControl;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        
        KCBannerViewLayout *layout = [[KCBannerViewLayout alloc] init];
        layout.scrollDirection = (UICollectionViewScrollDirection)self.scrollDirection;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        
        [_collectionView registerClass:[KCBannerCell class] forCellWithReuseIdentifier:KCBannerCellReuseID];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
    }
    return _collectionView;
}

- (UIImageView *)placeholderImageView
{
    if (!_placeholderImageView) {
        _placeholderImageView = [UIImageView new];
        _placeholderImageView.contentMode = UIViewContentModeCenter;
        _placeholderImageView.clipsToBounds = YES;
    }
    return _placeholderImageView;
}



@end
