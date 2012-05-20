//
//  ArtFile.h
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHeader.h"

@interface ArtFile : NSObject
@property (nonatomic, retain) NSDictionary *tags;
@property (nonatomic, retain) NSArray      *art;

@property (nonatomic, retain) AFHeader *header;

@property (nonatomic, assign) NSUInteger  majorOSVersion;
@property (nonatomic, assign) NSUInteger  minorOSVersion;
@property (nonatomic, assign) NSUInteger  bugFixOSVersion;

+ (ArtFile *)artFileWithFolderAtURL:(NSURL *)url;
- (id)initWithFolderAtURL:(NSURL *)url;

+ (ArtFile *)artFileWithFileAtURL:(NSURL *)url;
- (id)initWithFileAtURL:(NSURL *)url;

+ (NSURL *)artFileURL;
+ (NSURL *)artFile200URL;

- (NSData *)data;
- (NSArray *)imageRepresentations;

- (void)decodeToFolder:(NSURL *)url error:(NSError **)error;

- (NSString *)tagForIndex:(uint8_t)index;

@end
