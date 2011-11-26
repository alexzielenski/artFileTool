//
//  Defines.h
//  artfiledecoder
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 PCWiz Computer. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef __artfiledecoder__Defines__
#define __artfiledecoder__Defines__

struct file_header {
	uint16_t	file_count;
	uint16_t	maxDepth;
	uint32_t	tag_count;
	uint32_t	tag_descriptors_offset;
	uint32_t	tag_names_offset;
	uint32_t	file_descriptors_offset;
	uint32_t	file_data_section_offset;
};

struct tag_descriptor {
	uint32_t	tag_name_offset;
	uint8_t		tag_index;
	uint8_t		tag_flags;
	uint16_t	unknown;
};

struct file_descriptor {
	uint32_t	file_data_offset;
	uint8_t		tags[8];
};

struct art_header {
	uint16_t	art_rows;
	uint16_t	art_columns;
	uint8_t		unknown[28];
	uint32_t	subimage_offsets[9];
	uint16_t	subimage_widths[9];
	uint16_t	subimage_heights[9];
};

extern BOOL legacy;
extern BOOL connect;
extern BOOL verbose; 

extern NSData *artFileData;
extern NSMutableDictionary *tagNames;
extern struct file_header header;

extern uint32_t readInt32AtOffset(NSUInteger offset);
extern uint16_t readInt16AtOffset(NSUInteger offset);
extern uint8_t readInt8AtOffset(NSUInteger offset);
extern void readTagDescriptors(void);
extern struct file_descriptor descriptorForIndex(int idx); 
extern struct art_header artHeaderFromDescriptor(struct file_descriptor fd);

#endif
