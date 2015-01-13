//
//  HzImageLoadingHelper.m
//  HzImageLoadingDemo
//
//  Created by 何 峙 on 14-4-17.
//  Copyright (c) 2014年 何 峙. All rights reserved.
//

#import "HzImageLoadingHelper.h"
#import <AFNetworking/AFNetworking.h>

#define KevinDebug

static NSInteger const kMaxCacheCount = 80;
static NSInteger const kMaxCacheCostSize = 4 * 1024 * 1024;
static NSString *const kDirImage = @"kevinImages";

@interface HzImageLoadingHelper ()

@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, strong) NSString *imageFilePrefix;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

+ (instancetype)sharedInstance;
+ (NSString *)filenameFromUrl:(NSString *)urlStr;
+ (UIImage *)compressImage:(UIImage *)source;

@end

@implementation HzImageLoadingHelper

- (void)dealloc{
    [_imageCache release]; _imageCache = nil;
    [_imageFilePrefix release]; _imageFilePrefix = nil;
    [_downloadQueue release]; _downloadQueue = nil;
    
    self.delegate = nil;
    
    [super dealloc];
}

#pragma mark - Private methods

+ (instancetype)sharedInstance{
    static HzImageLoadingHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[self alloc] init];
        
        instance.imageCache = [[[NSCache alloc] init] autorelease];
        instance.imageCache.countLimit = kMaxCacheCount;
        instance.imageCache.totalCostLimit = kMaxCacheCostSize;
        
    });
    
    return instance;
}

+ (NSString *)filenameFromUrl:(NSString *)urlStr{
    if(urlStr){
        NSArray *components = [urlStr componentsSeparatedByString:@"://"];
        if(components.count == 2){
            NSString *temp = [components objectAtIndex:1];
            temp = [temp stringByReplacingOccurrencesOfString:@"/" withString:@"#"];
            return temp;
        }
    }
    
    return nil;
}

+ (UIImage *)compressImage:(UIImage *)source{
    if(!source){
        return nil;
    }
    
    CGFloat width = source.size.width;
    CGFloat height = source.size.height;
    if(width >= 1500 || height >= 1500){
        CGSize expectedSize = CGSizeMake(width * 0.4, height * 0.4);
        UIGraphicsBeginImageContext(expectedSize);
        CGRect expectedRect = CGRectMake(0.0, 0.0, expectedSize.width, expectedSize.height);
        [source drawInRect:expectedRect];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    
    return source;
}

#pragma mark - Public methods

+ (void)loadImageAtUrl:(NSURL *)url withPrefix:(NSString *)prefix completion:(HzImageLoadingCompletionBlock)handler{
    if(!url){
        return;
    }
    
    HzImageLoadingHelper *helper = [HzImageLoadingHelper sharedInstance];
    
    NSString *key = url.absoluteString;
    if(prefix){
        key = [NSString stringWithFormat:@"%@-%@", prefix, url.absoluteString];
    }
    
    if([helper.imageCache objectForKey:key]){
        NSData *data = [helper.imageCache objectForKey:key];
        handler(data);
    }else{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:kDirImage];
        NSString *fileName = nil;
        if(prefix){
            fileName = [NSString stringWithFormat:@"%@-%@", prefix, [HzImageLoadingHelper filenameFromUrl:url.absoluteString]];
        }
        else{
            fileName = [HzImageLoadingHelper filenameFromUrl:url.absoluteString];
        }
        NSString *filePath = [fileDir stringByAppendingPathComponent:fileName];
        if([fileManager fileExistsAtPath:filePath]){
            NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
            if(data){
                [helper.imageCache setObject:data forKey:key cost:data.length];
            }
            handler(data);
            [data release];
            
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                __block NSData *resultData = nil;
                
                dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    NSURLRequest *request = [NSURLRequest requestWithURL:url];
                    NSError *error = nil;
                    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
                    if(!error){
                        resultData = data;
                    }
                    
                });
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    if(resultData){
                        if(![fileManager fileExistsAtPath:fileDir]){
                            [fileManager createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:NULL];
                        }
                        [resultData writeToFile:filePath atomically:YES];
                        
                        [helper.imageCache setObject:resultData forKey:key cost:resultData.length];
                        handler(resultData);
                    }
                    else{
                        handler(nil);
                    }
                    
                });
                
            });
        }
    }
}

+ (void)loadImageAtUrl:(NSURL *)url withPrefix:(NSString *)prefix shouldCompress:(BOOL)compress completion:(HzImageLoadingCompletionBlock)handler{
    if(!url){
        return;
    }
    
    HzImageLoadingHelper *helper = [HzImageLoadingHelper sharedInstance];
    
    NSString *key = url.absoluteString;
    if(prefix){
        key = [NSString stringWithFormat:@"%@-%@", prefix, url.absoluteString];
    }
    
    if([helper.imageCache objectForKey:key]){
        NSData *data = [helper.imageCache objectForKey:key];
        handler(data);
    }else{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:kDirImage];
        NSString *fileName = nil;
        if(prefix){
            fileName = [NSString stringWithFormat:@"%@-%@", prefix, [HzImageLoadingHelper filenameFromUrl:url.absoluteString]];
        }
        else{
            fileName = [HzImageLoadingHelper filenameFromUrl:url.absoluteString];
        }
        NSString *filePath = [fileDir stringByAppendingPathComponent:fileName];
        if([fileManager fileExistsAtPath:filePath]){
            NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
            if(data){
                [helper.imageCache setObject:data forKey:key cost:data.length];
            }
            handler(data);
            [data release];
            
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                __block NSData *resultData = nil;
                
                dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    NSURLRequest *request = [NSURLRequest requestWithURL:url];
                    NSError *error = nil;
                    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
                    if(!error){
                        if(compress){
                            UIImage *image = [UIImage imageWithData:data];
                            UIImage *newImage = [HzImageLoadingHelper compressImage:image];
                            resultData = UIImageJPEGRepresentation(newImage, 1.0);
                        }
                        else{
                            resultData = data;
                        }
                    }
                    
                });
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    
                    if(resultData){
                        if(![fileManager fileExistsAtPath:fileDir]){
                            [fileManager createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:NULL];
                        }
                        [resultData writeToFile:filePath atomically:YES];
                        
                        [helper.imageCache setObject:resultData forKey:key cost:resultData.length];
                        handler(resultData);
                    }
                    else{
                        handler(nil);
                    }
                    
                });
                
            });
        }
    }
}


- (void)loadImageWithProgressAtUrl:(NSURL *)url prefix:(NSString *)prefix{
    if(!url || url.absoluteString.length == 0){
        if([_delegate respondsToSelector:@selector(helper:didLoadImage:errDescription:localBaseUrl:fileName:)]){
            [_delegate helper:self didLoadImage:nil errDescription:@"连接失败" localBaseUrl:nil fileName:nil];
        }
        
        return;
    }
    
    if(prefix){
        self.imageFilePrefix = prefix;
    }
    
    NSString *fileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:kDirImage];
    NSString *filename = nil;
    if(prefix){
        filename = [NSString stringWithFormat:@"%@-%@", _imageFilePrefix, [HzImageLoadingHelper formatImageLink:url.absoluteString]];
    }
    else{
        filename = [HzImageLoadingHelper formatImageLink:url.absoluteString];
    }
    
    NSString *key = url.absoluteString;
    
    if([_imageCache objectForKey:key]){
        NSData *data = [_imageCache objectForKey:key];
        if(_delegate){
            [_delegate helper:self didLoadImage:data errDescription:nil localBaseUrl:[NSURL fileURLWithPath:fileDir] fileName:filename];
        }
        
    }else{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filePath = [fileDir stringByAppendingPathComponent:filename];
        if(filename && [fileManager fileExistsAtPath:filePath]){
            NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
            if(data){
                [_imageCache setObject:data forKey:key cost:data.length];
                
                if([_delegate respondsToSelector:@selector(helper:didLoadImage:errDescription:localBaseUrl:fileName:)]){
                    [_delegate helper:self didLoadImage:data errDescription:nil localBaseUrl:[NSURL fileURLWithPath:fileDir] fileName:filename];
                }
            }else{
                if([_delegate respondsToSelector:@selector(helper:didLoadImage:errDescription:localBaseUrl:fileName:)]){
                    [_delegate helper:self didLoadImage:data errDescription:@"文件损坏" localBaseUrl:[NSURL fileURLWithPath:fileDir] fileName:filename];
                }
                [fileManager removeItemAtPath:filePath error:NULL];
            }
            [data release];
            
        }else{
            if(!_downloadQueue){
                self.downloadQueue = [[[NSOperationQueue alloc] init] autorelease];
            }
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSString *filePath = [fileDir stringByAppendingPathComponent:filename];
                if(![fileManager fileExistsAtPath:fileDir]){
                    [fileManager createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:NULL];
                }
                NSData *resultData = (NSData *)responseObject;
                [resultData writeToFile:filePath atomically:YES];
                
                NSString *key = url.absoluteString;
                [_imageCache setObject:resultData forKey:key cost:resultData.length];
                
                if([_delegate respondsToSelector:@selector(helper:didLoadImage:errDescription:localBaseUrl:fileName:)]){
                    [_delegate helper:self didLoadImage:resultData errDescription:nil localBaseUrl:[NSURL fileURLWithPath:fileDir] fileName:filename];
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
                if([_delegate respondsToSelector:@selector(helper:didLoadImage:errDescription:localBaseUrl:fileName:)]){
                    [_delegate helper:self didLoadImage:nil errDescription:@"连接失败" localBaseUrl:[NSURL fileURLWithPath:fileDir] fileName:filename];
                }
                
            }];
            [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                
                if([_delegate respondsToSelector:@selector(helper:didLoadImageProgress:)]){
                    [_delegate helper:self didLoadImageProgress:totalBytesRead * 1.0 / totalBytesExpectedToRead];
                }
                
            }];
            [_downloadQueue addOperation:operation];     
        
        }
    }
}


+ (NSString *)generatePhotoHTMLWithfile:(NSString *)fileName{
    if(!fileName){
        return nil;
    }
    
    NSMutableString *html = [[NSMutableString alloc] init];
    [html appendString:@"<html>"];
    [html appendString:@"<head>"];
    [html appendString:@"<meta content=\"width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=1;\" name=\"viewport\" />"];
    [html appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=gb2312\" />"];
    [html appendString:@"<style type=\"text/css\">"];
    [html appendString:@"html,body { margin:0; height:100%;overflow:hidden; background:#000000}"];
    [html appendString:@".miao{width:100%;height:100%;display:table;text-align:center}"];
    [html appendString:@".miao span{display:table-cell;vertical-align:middle;}"];
    [html appendString:@".miao span img{border:0}"];
    [html appendString:@"</style>"];
    [html appendString:@"</head>"];
    [html appendString:@"<body class=\"miao\">"];
    [html appendFormat:@"<span><img src=\"%@\" style=\"width:100%%\"/></span>", fileName];
    [html appendString:@"</body>"];
    [html appendString:@"</html>"];
    
    return [html autorelease];
}

+ (NSString *)formatImageLink:(NSString *)link{
    if(!link || link.length == 0){
        return nil;
    }

    NSArray *components = [link componentsSeparatedByString:@"://"];
    if(components.count == 2){
        NSString *temp = [components objectAtIndex:1];
        NSString *result = [temp stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        result = [result stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        if([result hasSuffix:@"jpg"] || [result hasSuffix:@"JPG"]){
            result = [NSString stringWithFormat:@"%@.jpg", result];
        }
        else if([result hasSuffix:@"gif"] || [result hasSuffix:@"GIF"]){
            result = [NSString stringWithFormat:@"%@.gif", result];
        }
        else if([result hasSuffix:@"bmp"] || [result hasSuffix:@"BMP"]){
            result = [NSString stringWithFormat:@"%@.bmp", result];
        }
        else if([result hasSuffix:@"jpeg"] || [result hasSuffix:@"JPEG"]){
            result = [NSString stringWithFormat:@"%@.jpeg", result];
        }
        else{
            result = [NSString stringWithFormat:@"%@.png", result];
        }
        return result;
    }
    
    return nil;
}

+ (UIImage *)generateThumbnailWithImage:(UIImage *)source{
    if(!source){
        return nil;
    }
    
    CGFloat expectedSize = 250.0f;
    CGSize imageSize = CGSizeMake(expectedSize, expectedSize);
    UIGraphicsBeginImageContext(imageSize);
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    [source drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    return newImage;
}


+ (void)clearAllCache{
    HzImageLoadingHelper *imageHelper = [HzImageLoadingHelper sharedInstance];
    [imageHelper.imageCache removeAllObjects];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:kDirImage];
    [fileManager removeItemAtPath:fileDir error:NULL];
}

@end
