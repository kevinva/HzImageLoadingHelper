//
//  HzImageLoadingHelper.h
//  HzImageLoadingDemo
//
//  Created by 何 峙 on 14-4-17.
//  Copyright (c) 2014年 何 峙. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef void(^HzImageLoadingCompletionBlock)(NSData *data);

@protocol HzImageLoadingHelperDelegate;

@interface HzImageLoadingHelper : NSObject

@property (nonatomic, assign) id<HzImageLoadingHelperDelegate> delegate;

/**
 *  @brief  deprecated
 */
+ (void)loadImageAtUrl:(NSURL *)url withPrefix:(NSString *)prefix shouldCompress:(BOOL)compress completion:(HzImageLoadingCompletionBlock)handler; //debug

/**
 *  @brief 异步读取在线图片
 *
 *  @param url  图片地址
 *  @param prefix   添加前缀可能更容易标识图片，如无需要可设为nil
 *  @param handler  处理返回UIImage对象
 *
 */
+ (void)loadImageAtUrl:(NSURL *)url withPrefix:(NSString *)prefix completion:(HzImageLoadingCompletionBlock)handler;

- (void)loadImageWithProgressAtUrl:(NSURL *)url prefix:(NSString *)prefix;   //增加下载进度

+ (NSString *)generatePhotoHTMLWithfile:(NSString *)fileName;
+ (NSString *)formatImageLink:(NSString *)link;
+ (UIImage *)generateThumbnailWithImage:(UIImage *)source;
+ (void)clearAllCache;

@end

@protocol HzImageLoadingHelperDelegate <NSObject>

@required

- (void)helper:(HzImageLoadingHelper *)helper didLoadImage:(NSData *)imageData errDescription:(NSString *)errStr localBaseUrl:(NSURL *)url fileName:(NSString *)fileName;

@optional

- (void)helper:(HzImageLoadingHelper *)helper didLoadImageProgress:(float)progress;

@end
