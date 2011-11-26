//
//  decoder.m
//  artFileTool
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 Alex Zielenski. All rights reserved.
//

#include "decoder.h"
#import <Cocoa/Cocoa.h>

static int globalCounter; // used for naming the files
static CGImageRef cgImageFrom(NSData *data, uint16_t width, uint16_t height) {
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGImageAlphaFirst; // only include the little thing for Lion artfile
	
	if (!legacy) {
		bitmapInfo |= kCGBitmapByteOrder32Little;
	}
	
	CGImageRef cgImage = CGImageCreate(width, height, 8, 32, 4 * width, colorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return cgImage;
}

static NSData *bytesOfHeaderAtIndex(struct file_descriptor fd, struct art_header ah, int sd, uint16_t *w, uint16_t *h) {
	uint16_t imageWidth = ah.subimage_widths[sd];
	uint16_t imageHeight = ah.subimage_heights[sd];
	NSUInteger imageLength = 4 * imageWidth * imageHeight;
	NSUInteger imageOffset = header.file_data_section_offset + fd.file_data_offset + ah.subimage_offsets[sd];
	NSRange imageDataRange = NSMakeRange(imageOffset, imageLength);
	
	if ((NSMaxRange(imageDataRange) <= [artFileData length]) && (imageWidth > 0) && (imageHeight > 0)) {
		if (w != NULL)
			*w = imageWidth;
		if (h != NULL)
			*h = imageHeight;
		
		return [artFileData subdataWithRange:NSMakeRange(imageOffset, imageLength)];
	}
	return NULL;
}
static NSData *connectedBytesFromArt(struct file_descriptor fd, struct art_header ah, uint16_t* w, uint16_t *h) {
	int imageCount = ah.art_rows * ah.art_columns;
	// all we really need to do is piece the data together
	NSData *allImages[imageCount];
	uint16_t widths[imageCount];
	uint16_t heights[imageCount];
	
	uint16_t totalWidth = 0;
	uint16_t totalHeight = 0;
	for (NSUInteger sd = 0; sd < imageCount; sd++) {
		uint16_t currentImageWidth;
		uint16_t currentImageHeight;
		NSData *bytes = bytesOfHeaderAtIndex(fd, ah, (int)sd, &currentImageWidth, &currentImageHeight);
		if (bytes!=NULL) {
			allImages[sd] = bytes;
			widths[sd] = currentImageWidth;
			heights[sd] = currentImageHeight;
			
			totalWidth+=currentImageWidth;
			totalHeight+=currentImageHeight;
		}
	}
	totalWidth/=ah.art_rows;
	totalHeight/=ah.art_columns;
	
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																	pixelsWide:totalWidth 
																	pixelsHigh:totalHeight 
																 bitsPerSample:8 
															   samplesPerPixel:4
																	  hasAlpha:YES 
																	  isPlanar:NO 
																colorSpaceName:NSDeviceRGBColorSpace 
																  bitmapFormat:NSAlphaFirstBitmapFormat
																   bytesPerRow:4 * totalWidth
																  bitsPerPixel:32];
	NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
	// draw stuff
	
	int currentX = 0;
	int currentY = totalHeight;
	for (int x = 0; x<ah.art_rows; x++) {
		currentX=0;
		for (int y = 0; y<ah.art_columns; y++) {
			NSData *data = allImages[x*ah.art_columns+y];
			uint16_t width = widths[x*ah.art_columns+y];
			uint16_t height = heights[x*ah.art_columns+y];
			
			if (!data)
				continue;
			if (width>totalWidth)
				continue;
			if (height>totalHeight)
				continue;

			
			if (y==0)
				currentY-=height;
			
			CGImageRef image = cgImageFrom(data, width, height);
			CGContextDrawImage([ctx graphicsPort], 
							   CGRectMake(currentX, currentY, width, height), 
							   image);
			currentX+=width;
		}
	}
	
	*w = totalWidth;
	*h = totalHeight;
	
	return [rep representationUsingType:NSPNGFileType properties:nil];
}
static void writeImageToFolder(NSData *imageData, uint16_t imageWidth, uint16_t imageHeight, NSURL *imageURL) {
	CGImageRef cgImage = cgImageFrom(imageData, imageWidth, imageHeight);
	if (!connect)
		[[NSFileManager defaultManager] createDirectoryAtPath:imageURL.path 
								  withIntermediateDirectories:YES 
												   attributes:nil 
														error:nil];
	if (!connect)  {
		NSString *filename = [NSString stringWithFormat:@"%i.png", globalCounter];
		imageURL=[imageURL URLByAppendingPathComponent:filename];
	} else {
	}
	globalCounter++;
	
	CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)imageURL, CFSTR("public.png"), 1, NULL);
	CGImageDestinationAddImage(dest, cgImage, NULL);
	CGImageDestinationFinalize(dest);
	CGImageRelease(cgImage);
	CFRelease(dest);
}
static void writeDataToFolder(NSData *data, NSURL *imageURL) {
	if (!connect)
		[[NSFileManager defaultManager] createDirectoryAtPath:imageURL.path 
								  withIntermediateDirectories:YES 
												   attributes:nil 
														error:nil];
	if (!connect)  {
		NSString *filename = [NSString stringWithFormat:@"%i.png", globalCounter];
		imageURL=[imageURL URLByAppendingPathComponent:filename];
	} else {
	}
	globalCounter++;
	[data writeToURL:imageURL atomically:NO];
}
static BOOL writeImagesToFolder(NSString* folderPath) {
    for (NSUInteger i = 0; i < header.file_count; i++) {
		
        struct file_descriptor fd = descriptorForIndex((int)i);
        struct art_header ah = artHeaderFromDescriptor(fd);
		NSURL *imageURL = [NSURL fileURLWithPath:folderPath];
		NSString *filename = @"";
		for (int x = 0; x<sizeof(fd.tags); x++) {
			uint8_t y = fd.tags[x];
			if (y==0) {
				continue;
			}
			NSString *tagName = [tagNames objectForKey:[NSString stringWithFormat:@"%i", y]];
			if (!connect) {
				imageURL=[imageURL URLByAppendingPathComponent:tagName];
			} else {
				if ([filename isEqualToString:@""]) {
					filename=[filename stringByAppendingFormat:@"/%@", tagName];
				} else
					filename=[filename stringByAppendingFormat:@".%@", tagName];
			}
		}
		uint16_t imageWidth;
		uint16_t imageHeight;
		NSData *imageData;
		
		if (!connect) {
			int imageCount = ah.art_rows * ah.art_columns;
			for (NSUInteger sd = 0; sd < imageCount; sd++) {
				imageData = bytesOfHeaderAtIndex(fd, ah, (int)sd, &imageWidth, &imageHeight);
				if (imageData!=NULL&&imageWidth>0&&imageHeight>0) {
					writeImageToFolder(imageData, imageWidth, imageHeight, imageURL);
				}
			}
		} else {
			imageData = connectedBytesFromArt(fd, ah, &imageWidth, &imageHeight);
			imageURL=[NSURL fileURLWithPath:[[imageURL.path stringByAppendingString:filename] stringByAppendingPathExtension:@"png"]];
			if (imageData!=NULL&&imageWidth>0&&imageHeight>0) {
				writeDataToFolder(imageData, imageURL);
			}
		}
		printf("Decoded File Index : %i\n", (int)i);
		if (verbose) {
			printf("Tags: %s\n", imageURL.lastPathComponent.stringByDeletingPathExtension.UTF8String);
			printf("Size: (%i, %i). Cols x Rows: %i x %i\n", imageWidth, imageHeight, ah.art_columns, ah.art_rows);
		}
    }
	return YES;
}

BOOL artfile_decode(NSString *filePath, NSString *folderPath) {
	if (artFileData) {
		[artFileData release];
		artFileData = nil;
	}
	if (tagNames) {
		[tagNames release];
		tagNames = nil;
	}
	if (verbose)
		printf("Checking parameters…\n");
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	BOOL exists = [fm fileExistsAtPath:folderPath isDirectory:&isDir];
	if (exists&&!isDir) {
		printf("%s is a file.\n", [folderPath UTF8String]);
		return NO;
	} else if (!exists) {
		NSError *err = nil;
		[fm createDirectoryAtPath:folderPath 
	  withIntermediateDirectories:YES 
					   attributes:nil 
							error:&err];
		if (err) {
			printf("Cannot create directory, %s. May be a permissions issue.\n", [folderPath UTF8String]);
			return NO;
		}
	}
	exists = [fm fileExistsAtPath:filePath isDirectory:&isDir];
	if (exists&&isDir) {
		printf("%s is a directory.\n", [filePath UTF8String]);
	}
	if (verbose)
		printf("Initializing data…\n");
	artFileData = [[NSData alloc] initWithContentsOfFile:filePath];
	[artFileData getBytes:&header length:sizeof(struct file_header)];
	
	tagNames = [[NSMutableDictionary dictionaryWithCapacity:header.tag_count] retain];
	readTagDescriptors();
	if (verbose) {
	 	printf("Possible tags: %s\n", tagNames.description.UTF8String);
	}
	
	BOOL rtn = writeImagesToFolder(folderPath);
	[artFileData release];
	artFileData = nil;
	[tagNames release];
	tagNames = nil;
	return rtn;
}
