//
//  NSData+ByteAdditions.m
//  SArtFileTool
//
//  Created by Alex Zielenski on 5/17/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "NSData+Byte.h"
#import <objc/runtime.h>

@implementation NSData (ByteAdditions)

static char OFFSET;
- (NSUInteger)currentOffset
{
    NSNumber *value = objc_getAssociatedObject(self, &OFFSET);
    return value.unsignedIntegerValue;
}

- (void)setCurrentOffset:(NSUInteger)offset
{
    [self willChangeValueForKey:@"currentOffset"];
    objc_setAssociatedObject(self, &OFFSET, [NSNumber numberWithUnsignedInteger:offset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"currentOffset"];
}

- (uint8_t)nextByte
{
    uint8_t nextByte    = [self byteAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint8_t);
    return nextByte;
}

- (uint8_t)byteAtOffset:(NSUInteger)offset
{
    uint8_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return result;
}

- (uint16_t)nextShort
{
    uint16_t nextShort = [self shortAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint16_t);
    return nextShort;
}

- (uint16_t)shortAtOffset:(NSUInteger)offset
{
    uint16_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return CFSwapInt16LittleToHost(result);
}

- (uint32_t)nextInt
{
    uint32_t nextInt = [self intAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint32_t);
    return nextInt;
}

- (uint32_t)intAtOffset:(NSUInteger)offset
{
    uint32_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return CFSwapInt32LittleToHost(result);
}

- (uint64_t)nextLong
{
    uint64_t nextLong = [self longAtOffset:self.currentOffset];
    self.currentOffset += sizeof(uint64_t);
    return nextLong;
}

- (uint64_t)longAtOffset:(NSUInteger)offset;
{
    uint64_t result;
    [self getBytes:&result range:NSMakeRange(offset, sizeof(result))];
    return CFSwapInt64LittleToHost(result);
}

@end
