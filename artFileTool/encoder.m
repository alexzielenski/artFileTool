
//  encoder.c
//  artFileTool
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 Alex Zielenski. All rights reserved.
//

#import "encoder.h"
#include "Defines.h"

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


unsigned char* dataFromRep(NSBitmapImageRep *bitmapImageRep, BOOL unpremultiply, BOOL abgr);

static int globalCounter;

unsigned char* bytesFromData(NSData *data, uint16_t *w, uint16_t *h) {
	if (!data) {
		NSLog(@"no data");
		return NULL;
	}
    // Create a bitmap from the source image data
	
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:data];
    NSInteger width = [imageRep pixelsWide];
    NSInteger height = [imageRep pixelsHigh];
    if (w != NULL) { *w = (uint16_t)width; }
    if (h != NULL) { *h = (uint16_t)height; }
    
    unsigned char *bytes = [imageRep bitmapData];
    for (NSUInteger y = 0; y < width * height * 4; y += 4) { // bgra little endian + alpha first
		uint8_t a, r, g, b;
		
		if (imageRep.bitmapFormat & NSAlphaFirstBitmapFormat) {
			a = bytes[y];
			r = bytes[y+1];
			g = bytes[y+2];
			b = bytes[y+3];
		} else {
			r = bytes[y+0];
			g = bytes[y+1];
			b = bytes[y+2];
			a = bytes[y+3];
		}
		
		// unpremultiply alpha if there is any
		if (a > 0) {
			if (!(imageRep.bitmapFormat & NSAlphaNonpremultipliedBitmapFormat)) {
				float factor = 255.0f/a;
				b *= factor;
				g *= factor;
				r *= factor;
			}
		} else {
			b = 0;
			g = 0;
			r = 0;
		}
		
		if (!legacy) {
			bytes[y]=b;
			bytes[y+1]=g;
			bytes[y+2]=r;
			bytes[y+3]=a;
		} else {
			bytes[y]=a;
			bytes[y+1]=r;
			bytes[y+2]=g;
			bytes[y+3]=b;
		}
	}
    return bytes;
}

static NSData * CreateDataFromCGImageRect(CGImageRef image, NSUInteger originX, NSUInteger originY, NSUInteger width, NSUInteger height) {
	if (!image)
		return NULL;
	
	CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image);
	size_t bytesPerRow = CGImageGetBytesPerRow(image);
    
	CGDataProviderRef provider = CGImageGetDataProvider(image);
	CFDataRef data = CGDataProviderCopyData(provider);
	const UInt8 *tbytes = CFDataGetBytePtr(data);
	
	uint8_t *bytes = (uint8_t *)malloc(width * height * 4);

	for (NSUInteger y = 0; y < width * height * 4; y += 4) { // bgra little endian + alpha first
		uint8_t a, r, g, b;
		
		NSUInteger offset = originX * 4 + originY * bytesPerRow + y / (width * 4) * (bytesPerRow - width * 4) + y;
		
		if (alphaInfo == kCGImageAlphaFirst) {
			a = tbytes[offset];
			r = tbytes[offset+1];
			g = tbytes[offset+2];
			b = tbytes[offset+3];
		} else {
			r = tbytes[offset];
			g = tbytes[offset+1];
			b = tbytes[offset+2];
			a = tbytes[offset+3];
		}
		
		 // this distorts the image even more without unpremultiplying the alpha for some reason.
		if ((alphaInfo == kCGImageAlphaPremultipliedFirst) || (alphaInfo == kCGImageAlphaPremultipliedLast)) {
			float factor = 255.0f/(float)a;
			r = r*factor;
			g = g*factor;
			b = b*factor;
		}
		if (a==0) {
			r = 0;
			g = 0;
			b = 0;
		}
		
		if (!legacy) {
			bytes[y]=b;
			bytes[y+1]=g;
			bytes[y+2]=r;
			bytes[y+3]=a;
		} else {
			bytes[y]=a;
			bytes[y+1]=r;
			bytes[y+2]=g;
			bytes[y+3]=b;
		} 
	}
	CFRelease(data);
	
	return [[NSData alloc] initWithBytesNoCopy:bytes length:(width * height * 4) freeWhenDone:YES];
}

/*static unsigned char* bytesFromBitmapImageRep(NSBitmapImageRep *imageRep, uint16_t *w, uint16_t *h) {
	CFDataRef data = (CFDataRef)[imageRep representationUsingType:NSPNGFileType properties:nil];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGImageRef imageRef = CGImageCreateWithPNGDataProvider(provider, NULL, false, kCGRenderingIntentDefault);
	unsigned char *bytes = bytesFromCGImage(imageRef, w, h);
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CFRelease(data);
	return bytes;
}*/

static BOOL encodeImages(NSString *folderPath, NSString *destinationPath) {
	NSMutableData *fileData = [[NSMutableData alloc] initWithCapacity:0];
	NSMutableData *headerData;
	
	headerData = [[artFileData subdataWithRange:NSMakeRange(0, header.file_data_section_offset)] mutableCopy];
	// really nothing to do here except change some file offsets and sizes
	for (int idx = 0; idx < header.file_count; idx++) {
		NSMutableData *currentFileData = [[NSMutableData alloc] initWithCapacity:0];
		
		// we need to get the tags of the file to find the actual file location
		struct file_descriptor fd = descriptorForIndex(idx);		
		struct art_header ah = artHeaderFromDescriptor(fd);
		
		// edit the file descriptor
		fd.file_data_offset = (uint32_t)[fileData length];
		
		// write the file descriptor
		[headerData replaceBytesInRange:NSMakeRange(header.file_descriptors_offset + sizeof(struct file_descriptor)*idx, sizeof(struct file_descriptor))
							  withBytes:&fd];
		// find the path where out images are
		NSString *currentFolderPath = folderPath;
		for (int x = 0; x<sizeof(fd.tags); x++) {
			uint8_t y = fd.tags[x];
			if (y==0) {
				continue;
			}
			NSString *key = [[NSNumber numberWithInt:y] stringValue];
			if (!connect)
				currentFolderPath = [currentFolderPath stringByAppendingPathComponent:[tagNames objectForKey:key]];
			else
				currentFolderPath = [currentFolderPath stringByAppendingFormat:@"%@%@", (x==0) ? @"/" : @".", [tagNames objectForKey:key]];
		}
		
		int subImageCount = ah.art_rows*ah.art_columns;
		if (!connect) {
			for (int x = 0; x < subImageCount; x++) {
				// write the details on
				NSString *filePath = [currentFolderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.png", globalCounter]];
				
				NSData *tempData = [NSData dataWithContentsOfFile:filePath];
				if (!tempData) {
					// apple sometimes says that there are images that don't exist
					continue;
				}
				
				uint16_t width;
				uint16_t height;
				
				unsigned char *bytes = bytesFromData(tempData, &width, &height);
				
				// set the goods
				ah.subimage_heights[x] = height;
				ah.subimage_widths[x] = width;
				ah.subimage_offsets[x] = (uint32_t)((int)[currentFileData length] + (int)sizeof(struct art_header));
				
				// append the data bytes
				[currentFileData appendBytes:bytes length:width*height*4];
				
				globalCounter++;
				
			}
		} else {
			NSString *filePath = [currentFolderPath stringByAppendingPathExtension:@"png"];
			NSData *tempData = [NSData dataWithContentsOfFile:filePath];
			if (!tempData)
				continue;
			
			
			// split into pieces
			int currentX;
			int currentY = 0;

			CGDataProviderRef prov = CGDataProviderCreateWithCFData((CFDataRef)tempData);
			CGImageRef totalImage = CGImageCreateWithPNGDataProvider(prov, NULL, false, kCGRenderingIntentDefault);
			CGDataProviderRelease(prov);
			
			for (int x = 0; x<ah.art_rows; x++) {
				uint32_t offset = ((int)[currentFileData length] + (int)sizeof(struct art_header));
				currentX=0;
				
				for (int y = 0; y<ah.art_columns; y++) {
					
					
					uint32_t ci = x*ah.art_columns + y;
					uint16_t width = ah.subimage_widths[ci];
					uint16_t height = ah.subimage_heights[ci];
					
					if (width<=0||height<=0) {
						ah.subimage_heights[ci] = (uint16_t)height;
						ah.subimage_widths[ci] = (uint16_t)width;
						ah.subimage_offsets[ci] = (uint32_t)offset;
						continue;
					}
					
					NSData *subdata = CreateDataFromCGImageRect(totalImage, currentX, currentY, width, height);
					[currentFileData appendData:subdata];
					[subdata release];
					
					currentX+=width;
					
					// set the goods
					ah.subimage_heights[ci] = height;
					ah.subimage_widths[ci] = width;
					ah.subimage_offsets[ci] = offset;
					
					offset+=4*width*height;
					
					if (y==ah.art_columns-1)
						currentY+=height;
					
				}

			}
			CGImageRelease(totalImage);
			
		}
		
		printf("Encoded File Index : %i\n", idx);
		
		[fileData appendBytes:&ah length:(int)sizeof(struct art_header)];
		[fileData appendData:currentFileData];
		[currentFileData release];
	}
	[headerData appendData:fileData];
	[headerData writeToFile:destinationPath atomically:NO];
	
	[fileData release];
	[headerData release];
	
	return YES;
}

BOOL artfile_encode(NSString *folderPath, NSString *originalPath, NSString *destinationPath) {
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	BOOL exists = [fm fileExistsAtPath:folderPath isDirectory:&isDir];
	if (!exists) {
		NSError *err = nil;
		[fm createDirectoryAtPath:folderPath 
	  withIntermediateDirectories:YES 
					   attributes:nil 
							error:&err];
		if (err!=nil) {
			printf("Error creating directory %s. May be a permissions issue\n", [folderPath UTF8String]);
		}
	} else if (exists&&!isDir) {
		printf("%s is not a directory.\n", [folderPath UTF8String]);
		return NO;
	}
	exists = [fm fileExistsAtPath:originalPath isDirectory:&isDir];
	if (exists&&isDir) {
		printf("%s is a directory.\n", [originalPath UTF8String]);
		return NO;
	} else if (!exists) {
		printf("%s doesn't exist.\n", [originalPath UTF8String]);
		return NO;
	}
	
	exists = [fm fileExistsAtPath:destinationPath isDirectory:&isDir];
	if (exists&&isDir) {
		printf("%s is a directory.\n", [destinationPath UTF8String]);
		return NO;
	}
	
	artFileData = [[NSData alloc] initWithContentsOfFile:originalPath];
	[artFileData getBytes:&header length:(int)sizeof(struct file_header)];
	
	tagNames = [[NSMutableDictionary dictionaryWithCapacity:(int)header.tag_count] retain];
	readTagDescriptors();
	
	encodeImages(folderPath, destinationPath);
	[artFileData release];
	artFileData = nil;
	[tagNames release];
	tagNames = nil;
	
	return YES;
}