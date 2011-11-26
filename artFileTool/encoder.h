//
//  encoder.h
//  artFileTool
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 Alex Zielenski. All rights reserved.
//
#include "Defines.h"
#import <Cocoa/Cocoa.h>
#ifndef artFileTool_encoder_h
#define artFileTool_encoder_h
BOOL artfile_encode(NSString *folderPath, NSString *originalPath, NSString *destinationPath);
unsigned char* bytesFromData(NSData *data, uint16_t *w, uint16_t *h);
NSBitmapImageRep *cropBitmapImageRep(NSBitmapImageRep *rep, NSRect rect);
#endif
