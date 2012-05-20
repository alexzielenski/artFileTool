//
//  ArtFile.m
//  artFileTool
//
//  Copyright (c) 2011-2012, Alex Zielenski
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided 
//  that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this list of conditions and the 
//    following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
//    following disclaimer in the documentation and/or other materials provided with the distribution.
//  * Any redistribution, use, or modification is done solely for personal benefit and not for any commercial 
//    purpose or for monetary gain

//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
//  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#import "ArtFile.h"
#import "NSData+Byte.h"
#import "AFFileDescriptor.h"

@interface ArtFile ()
- (BOOL)_readFileData:(NSData *)data;
- (BOOL)_compileTagsListFromData:(NSData *)data;
- (BOOL)_readFileDescriptorsFromData:(NSData *)data;

- (NSString *)nameForDescriptor:(AFFileDescriptor *)descriptor;

- (NSString *)_tagForNumber:(NSNumber *)number;
@end

@implementation ArtFile
@synthesize tags            = _tags;
@synthesize art             = _art;
@synthesize header          = _header;
@synthesize majorOSVersion  = _majorOSVersion;
@synthesize minorOSVersion  = _minorOSVersion;
@synthesize bugFixOSVersion = _bugFixOSVersion;

+ (ArtFile *)artFileWithFolderAtURL:(NSURL *)url
{
    return [[[self alloc] initWithFolderAtURL:url] autorelease];
}

- (id)initWithFolderAtURL:(NSURL *)url
{
    if ((self = [self init])) {
        
    }
    
    return self;
}

+ (ArtFile *)artFileWithFileAtURL:(NSURL *)url
{
    return [[[self alloc] initWithFileAtURL:url] autorelease];
}

- (id)initWithFileAtURL:(NSURL *)url
{
    if ((self = [self init])) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        
        if (![self _readFileData:data]) {
            [self release];
            return nil;
        }
        
    }
    
    return self;
}

- (id)init
{
    if ((self = [super init])) {
        SInt32 major, minor, bugfix;
        Gestalt(gestaltSystemVersionMajor, &major);
        Gestalt(gestaltSystemVersionMinor, &minor);
        Gestalt(gestaltSystemVersionBugFix, &bugfix);
        
        _majorOSVersion  = major;
        _minorOSVersion  = minor;
        _bugFixOSVersion = bugfix;
    }
    
    return self;
}

+ (NSURL *)artFileURL
{
    return [NSURL fileURLWithPath:@"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/A/Resources/ArtFile.bin"];
}

+ (NSURL *)artFile200URL
{
    return [NSURL fileURLWithPath:@"/System/Library/PrivateFrameworks/CoreUI.framework/Versions/A/Resources/ArtFile200.bin"];    
}

- (NSData *)data
{
    return nil;
}

- (NSArray *)imageRepresentations
{
    return nil;
}

- (BOOL)_readFileData:(NSData *)data
{
    if (!data) {
        NSLog(@"No data");
        return NO;
    }
    
    self.header = [AFHeader headerWithData:data artFile:self];
    
    if (!self.header) {
        NSLog(@"Error reading header data.");
        return NO;
    }
    
    //    NSLog(@"%i, %i, %i, %i, %i, %i ,%i", self.header.fileAmount, self.header.maximumDepth, self.header.tagAmount, self.header.tagDescriptorsOffset, self.header.tagNamesOffset, self.header.fileDescriptorsOffset, self.header.fileDataOffset);
    
    if (![self _compileTagsListFromData:data]) {
        NSLog(@"Error reading tag list");
        return NO;
    }
    
    //    NSLog(@"%@", self.tags);
    
    if (![self _readFileDescriptorsFromData:data]) {
        NSLog(@"Error reading file descriptors");
        return NO;
    }
    
    return YES;
}

- (BOOL)_compileTagsListFromData:(NSData *)data
{
    NSMutableDictionary *tagNames = [NSMutableDictionary dictionaryWithCapacity:self.header.tagAmount];
	NSUInteger descOffset = self.header.tagDescriptorsOffset;
    
    data.currentOffset = descOffset;
    
    for (NSUInteger i = 0; i < self.header.tagAmount; i++) {
        
        uint32_t dNameOffset = data.nextInt;
        uint32_t tagIndex    = data.nextInt;
        
        uint32_t numberOfChars = 0;
        uint32_t tagNameOffset = self.header.tagNamesOffset + dNameOffset;
        
        while ([data byteAtOffset:tagNameOffset + numberOfChars] != 0) {
            numberOfChars++;
        }
        
        NSData *stringData = [data subdataWithRange:NSMakeRange(tagNameOffset, numberOfChars)];
        NSString *string = [[[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding] autorelease];
        
		[tagNames setObject:string
					 forKey:[NSString stringWithFormat:@"%i", tagIndex]];
    }
    
    self.tags = tagNames;
    
    return YES;
}

- (BOOL)_readFileDescriptorsFromData:(NSData *)data
{
    data.currentOffset = self.header.fileDescriptorsOffset;
    
    NSMutableArray *art = [NSMutableArray arrayWithCapacity:self.header.fileAmount];
    NSUInteger descriptorLength = [AFFileDescriptor expectedLengthForArtFile:self];
    
    for (int x = 0; x < self.header.fileAmount; x++) {
        AFFileDescriptor *descriptor = [AFFileDescriptor fileDescriptorWithData:data 
                                                                         offset:self.header.fileDescriptorsOffset + x * descriptorLength
                                                                        artFile:self];
        [art addObject:descriptor];
    }
    
    self.art = art;
    
    return YES;
}

- (NSString *)tagForIndex:(uint8_t)index
{
    return [self _tagForNumber:[NSNumber numberWithUnsignedChar:index]];
}

- (NSString *)_tagForNumber:(NSNumber *)number
{
    NSString *key = number.stringValue;
    return [self.tags objectForKey:key];
}

- (void)decodeToFolder:(NSURL *)url error:(NSError **)error
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL exists, isDir;
    exists = [manager fileExistsAtPath:url.path isDirectory:&isDir];
    
    if (exists && !isDir) {
        NSLog(@"Invalid export path");
        *error = [NSError errorWithDomain:@"com.alexzielenski.artFileTool.errror.domain" 
                                     code:1 
                                 userInfo:[NSDictionary dictionaryWithObject:@"The path specified exists but is not a directory." forKey:NSLocalizedFailureReasonErrorKey]];
        return;
    }
    
    [manager createDirectoryAtURL:url 
      withIntermediateDirectories:YES 
                       attributes:nil 
                            error:error];
    
    NSMutableDictionary *receipt = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithUnsignedInteger:self.majorOSVersion], @"majorOS",
                                    [NSNumber numberWithUnsignedInteger:self.minorOSVersion], @"minorOS",
                                    [NSNumber numberWithUnsignedInteger:self.bugFixOSVersion], @"bugFixOS", nil];
    
    NSMutableDictionary *buffer1Index = [NSMutableDictionary dictionary];
    NSMutableDictionary *buffer2Index = [NSMutableDictionary dictionary];

    static uint32_t filesWritten = 0;
    for (AFFileDescriptor *descriptor in self.art) {        
            NSString *fileName = [self nameForDescriptor:descriptor];
            
            [descriptor.artHeader.imageData writeToURL:[url URLByAppendingPathComponent:fileName] atomically:NO];
            
            
            [buffer1Index setObject:descriptor.artHeader.buffer1 forKey:fileName];
            [buffer2Index setObject:descriptor.artHeader.buffer2 forKey:fileName];
            
            filesWritten++;
            
            NSLog(@"Decoded file index: %d", [_art indexOfObject:descriptor]);
    }

    [receipt setObject:buffer1Index forKey:@"buffer1"];
    [receipt setObject:buffer2Index forKey:@"buffer2"];
    
    [receipt writeToURL:[url URLByAppendingPathComponent:@"_receipt.plist"] atomically:NO];

}

- (NSString *)nameForDescriptor:(AFFileDescriptor *)descriptor
{
    NSString *tags = @"";
    for (NSNumber *tag in descriptor.tagIndices) {
        tags = [tags stringByAppendingFormat:@".%@", [self _tagForNumber:tag]];
    }
    
    
    return [[tags substringFromIndex:1] stringByAppendingPathExtension:@"png"];
    
}

@end
