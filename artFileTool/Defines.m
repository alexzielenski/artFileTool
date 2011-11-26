//
//  Defines.c
//  artFileTool
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 Alex Zielenski. All rights reserved.
//

#include "Defines.h"

BOOL legacy;
BOOL connect;
BOOL verbose;

NSData *artFileData;
NSMutableDictionary *tagNames;
struct file_header header;

extern uint32_t readInt32AtOffset(NSUInteger offset) {
    if (!artFileData)
		return 0;
	uint32_t result;
    [artFileData getBytes:&result range:NSMakeRange(offset, sizeof(uint32_t))];
    return CFSwapInt32LittleToHost(result);
}

extern uint16_t readInt16AtOffset(NSUInteger offset) {
    if (!artFileData)
		return 0;
	
	uint16_t result;
    [artFileData getBytes:&result range:NSMakeRange(offset, sizeof(uint16_t))];
    return CFSwapInt16LittleToHost(result);
}

extern uint8_t readInt8AtOffset(NSUInteger offset) {
	if (!artFileData)
		return 0;
	
    uint8_t result;
    [artFileData getBytes:&result range:NSMakeRange(offset, sizeof(uint8_t))];
    return result;
}

extern void readTagDescriptors(void) {
	if (!tagNames)
		return;
	
	NSUInteger descOffset = header.tag_descriptors_offset;
    for (NSUInteger i = 0; i < header.tag_count; i++) {
        uint32_t dNameOffset = readInt32AtOffset(descOffset);
        descOffset += 4;
		uint8_t tagIndex = readInt8AtOffset(descOffset);
		descOffset += 4;
		
        uint32_t numberOfChars = 0;
        uint32_t tNameOffset = header.tag_names_offset + dNameOffset;
        while (readInt8AtOffset(tNameOffset + numberOfChars) != 0) {
            numberOfChars++;
        }
        NSData *stringData = [artFileData subdataWithRange:NSMakeRange(tNameOffset, numberOfChars)];
        NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding] autorelease];
		[tagNames setObject:string
					 forKey:[NSString stringWithFormat:@"%i", tagIndex]];
    }
	
}
extern struct file_descriptor descriptorForIndex(int idx) {
	static struct file_descriptor fd;
	int offset = (int)(header.file_descriptors_offset + sizeof(struct file_descriptor) * idx);
	[artFileData getBytes:&fd range:NSMakeRange(offset, sizeof(struct file_descriptor))];
	return fd;
}

extern struct art_header artHeaderFromDescriptor(struct file_descriptor fd) {
	NSUInteger headOffset = fd.file_data_offset+header.file_data_section_offset;
	struct art_header ah;
	[artFileData getBytes:&ah range:NSMakeRange(headOffset, sizeof(struct art_header))];
	return ah;
}