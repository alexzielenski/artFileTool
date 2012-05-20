//
//  NSImageRep+Data.h
//  SArtFileTool
//
//  Created by Alex Zielenski on 5/17/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSPDFImageRep (DataAdditions)
@end

@interface NSBitmapImageRep (DataAdditions)

+ (NSBitmapImageRep *)imageRepWithArtFileData:(NSData *)data size:(NSSize)size;
- (id)initWithArtFileData:(NSData *)data size:(NSSize)size;

@end

@interface NSImageRep (DataAdditions)

- (NSData *)artFileData;

@end
