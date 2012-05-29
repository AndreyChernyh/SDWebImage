//
//  SDDiskCleaner.h
//  PicYou
//
//  Created by Ильдар Шайнуров on 29.05.12.
//  Copyright (c) 2012 Metastudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SDDiskCleaner : NSObject
@property (nonatomic, retain) NSString *diskCachePath;

+ (SDDiskCleaner *)sharedDiskCleaner;
- (void)cleanDisk;
- (void)interrupt;
@end
