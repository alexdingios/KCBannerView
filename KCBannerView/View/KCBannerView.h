//
//  KCPictureRepeatView.h
//  无线循环图片轮播器demo
//
//  Created by xiliedu on 15/8/28.
//  Copyright (c) 2015年 xiliedu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCBanner.h"

typedef NS_ENUM(NSInteger, KCBannerViewScrollDirection) {
    KCBannerViewScrollDirectionVertical,
    KCBannerViewScrollDirectionHorizontal
};

@class KCBannerView;

// banner数据需要提供协议的接口
// 数据源
@protocol KCBannerViewDataSource <NSObject>

- (NSInteger)numberOfBannersInBannerView:(KCBannerView *)bannerView;

- (KCBanner *)bannerView:(KCBannerView *)bannerView bannerForItemAtIndex:(NSInteger)index;

@end

// 代理协议
@protocol KCBannerViewDelegate <NSObject>

@optional
// 点击回调
- (void)bannerView:(KCBannerView *)bannerView didSelectBannerAtIndex:(NSInteger)index;

@end

@interface KCBannerView : UIView


// 页数控件
@property (nonatomic, strong, readonly) UIPageControl *pageControl;

// 占位图
@property (nonatomic, strong, readonly) UIImageView *placeholderImageView;

// 代理
@property (nonatomic, weak) id<KCBannerViewDelegate> delegate;

// 数据源
@property (nonatomic, weak) id<KCBannerViewDataSource> dataSource;

// 循环间隔
@property (nonatomic, assign) CGFloat timeInterval;

// 是否循环轮播，默认为YES，当数据个数少于等于1时此值为NO
@property (nonatomic, assign, getter=isRepeat) BOOL repeat;

@property (nonatomic, assign) KCBannerViewScrollDirection scrollDirection;

// 刷新数据
- (void)reloadData;

// 偏移量
@property (nonatomic, assign) CGPoint contentOffset;


@end
