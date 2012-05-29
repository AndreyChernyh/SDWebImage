//
//  SDDiskCleaner.m
//  PicYou
//
//  Created by Ильдар Шайнуров on 29.05.12.
//  Copyright (c) 2012 Metastudio. All rights reserved.
//

#import "SDDiskCleaner.h"

static const NSUInteger kMaxCacheAge = 60*60*24*7; // 1 week

@interface SDDiskCleaner ()
@property (atomic, retain) NSFileManager *fileManager;
@property (atomic, assign) UIBackgroundTaskIdentifier bgTask;

@property (atomic, assign, getter = isInterrupted) BOOL interrupted;
@end

@implementation SDDiskCleaner

static SDDiskCleaner *sharedDiskCleaner = nil;

@synthesize fileManager = _fileManager;
@synthesize bgTask = _bgTask;

@synthesize interrupted = _interrupted;

@synthesize diskCachePath = _diskCachePath;

#pragma mark - Object lifecycle

+ (SDDiskCleaner *)sharedDiskCleaner
{
    if (sharedDiskCleaner == nil) {
        sharedDiskCleaner = [[SDDiskCleaner alloc] init];
    }
    return sharedDiskCleaner;
}

- (void)dealloc
{
    self.bgTask = UIBackgroundTaskInvalid;
    self.fileManager = nil;
    [super dealloc];
}

#pragma mark - Properties

- (void)cleanDisk
{
    if (self.bgTask != UIBackgroundTaskInvalid) {
        return;
    }

    self.interrupted = NO;
    self.fileManager = [[NSFileManager alloc] init];
    __block UIApplication *application = [UIApplication sharedApplication];
    self.bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        self.fileManager = nil;
        [application endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
    
    if (self.bgTask != UIBackgroundTaskInvalid) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-kMaxCacheAge];
            NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
            for (NSString *fileName in fileEnumerator)
            {
                if (self.isInterrupted) {
                    break;
                }
                NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
                NSDictionary *attrs = [self.fileManager attributesOfItemAtPath:filePath error:nil];
                if ([[[attrs fileModificationDate] laterDate:expirationDate] isEqualToDate:expirationDate])
                {
                    [self.fileManager removeItemAtPath:filePath error:nil];
                }
            }

            self.fileManager = nil;
            [application endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        });
    }
}

- (void)interrupt
{
    self.interrupted = YES;
}

@end