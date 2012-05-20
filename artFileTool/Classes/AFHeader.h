//
//  AFHeader.h
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ArtFile;
@interface AFHeader : NSObject
@property (nonatomic, assign) ArtFile *artFile;

@property (assign) uint16_t fileAmount;
@property (assign) uint16_t maximumDepth;
@property (assign) uint32_t tagAmount;
@property (assign) uint32_t tagDescriptorsOffset;
@property (assign) uint32_t tagNamesOffset;
@property (assign) uint32_t fileDescriptorsOffset;
@property (assign) uint32_t fileDataOffset;

+ (AFHeader *)headerWithData:(NSData *)data artFile:(ArtFile *)file;
- (id)initWithData:(NSData *)data artFile:(ArtFile *)file;

@end
