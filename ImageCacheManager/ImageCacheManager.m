//
//  ImageCacheManager.m
//  ImageCacheManager
//
//  Created by Steven Woo on 11/11/13.
//  Copyright (c) 2013 Steven Woo. All rights reserved.
//
//  The MIT License (MIT)
//
//  Copyright (c)  2013
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "ImageCacheManager.h"
#import "OperationDownloadImage.h"
@interface ImageCacheManager()<OperationDownloadImageProtocol>
@property   NSOperationQueue	* queue;
@property   NSMutableDictionary * dictionaryDelegates;
@property  id <ImageCacheDataProtocol> __weak delegateData;
@end
@implementation ImageCacheManager
-(id)init {
    self = [super init];
    if( !self ){
        return nil;
    }
    _queue = [[NSOperationQueue alloc]init];
    _dictionaryDelegates = [[NSMutableDictionary alloc]init];
    return self;
}


+ (id)sharedImageCacheManager {
    static ImageCacheManager *staticImageCacheManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticImageCacheManager = [[self alloc] init];
    });
    return staticImageCacheManager;
}



- (void)dealloc {
}


- (NSString *) getAppDocumentPath {
    NSArray       *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/DownloadedImages"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    return dataPath;
}
- (void) localDiskCleanup {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:[self getAppDocumentPath] error:&error];
    if( [directoryContents count] <100 ){
        return;
    }
    NSLog(@"never tested");
    NSDate *oldest = [NSDate date];
    NSString *oldestFileName = nil;
    for (NSString *file in directoryContents) {
        NSString *photoPath = [[self getAppDocumentPath] stringByAppendingPathComponent:file];
        
        NSDate *created = [[fileManager attributesOfItemAtPath:photoPath error:&error] objectForKey:@"NSFileCreationDate"];
        
        if([created compare:oldest] == NSOrderedAscending){
            oldestFileName = [NSString stringWithString:photoPath];
            oldest = created;
        }
    }
    [fileManager removeItemAtPath:oldestFileName error:&error];
    
}

- (NSString *) createRandomFilename: (int) inputLength {
    NSString *sourceCharacters = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSUInteger sourceLength = [sourceCharacters length];
    NSMutableString *outputRandomString = [NSMutableString stringWithCapacity: inputLength];
    
    for( int index=0; index<inputLength; ++index) {
        [outputRandomString appendFormat: @"%C", [sourceCharacters characterAtIndex: arc4random() % sourceLength]];
    }
    
    return outputRandomString;
}
- (UIImage *) getImage:(id)sender fromUrl:(NSString*)requestedUrl {
    if( requestedUrl == nil ){
        return nil;
    }
    if( !_delegateData ){
        return nil;
    }
    ImageCache *existingImageCache = [_delegateData getImageCacheFor:requestedUrl];
    BOOL flagDownload = NO;
    if( !existingImageCache) {
        if( [_delegateData saveImageCacheInfo:requestedUrl atDate:[NSDate date]]){
            flagDownload = YES;
        }
        else {
            NSLog(@"Error creating coredata record for image cache");
        }
    }
    else {
        if(existingImageCache.img_local_path && existingImageCache.img_local_path.length){
            // need to save file and make image from file
            NSString  *filePath = [NSString stringWithFormat:@"%@/%@", [self getAppDocumentPath], existingImageCache.img_local_path];
            if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ){
                UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                if( image ){
                    return image;
                }
                else {
                    //exists but invalid so try again
                    flagDownload = YES;
                }
            }
            else {
                flagDownload = YES;
            }
        }
        else {
            //need to download this...
            flagDownload = YES;
        }
        
    }
    if( flagDownload ){
        // verify not already in queue
        if( _queue.operationCount ){
            for(OperationDownloadImage *operationDownload in _queue.operations){
                if( [operationDownload.requestedUrl isEqualToString:requestedUrl]){
                    return nil;
                }
            }
        }
        OperationDownloadImage *operationDownloadImage = [[OperationDownloadImage alloc]init:self forUrl:requestedUrl];
        
        NSMutableArray *arrayExisting = [self.dictionaryDelegates objectForKey:requestedUrl];
        if( !arrayExisting ){
            arrayExisting = [[NSMutableArray alloc]init];
        }
        [arrayExisting addObject:sender];
        [self.dictionaryDelegates setObject:arrayExisting forKey:requestedUrl];
        [_queue addOperation:operationDownloadImage];
        // if more than N files, should delete the oldest files
        [self localDiskCleanup];
        
    }
    
    return nil;
}
- (void) cancelRequest:(id)sender fromUrl:(NSString*)requestedUrl {
    NSMutableArray *arrayDelegates = [self.dictionaryDelegates objectForKey:requestedUrl];
    if( arrayDelegates ){
        for( id delegateDownload in arrayDelegates ){
            if( delegateDownload == sender ){
                [arrayDelegates removeObject:delegateDownload];
                [self.dictionaryDelegates setObject:arrayDelegates forKey:requestedUrl];
            }
        }
    }
}
#pragma mark @protocol OperationDownloadImageProtocol
- (void)operationDownloadImageDidFinish:(OperationDownloadImage *)sender  withImage:(UIImage*)image withRawData:(NSData*)rawData forUrl:(NSString*)requestedUrl {
    NSLog(@"%@ was downloaded", requestedUrl);
    NSString *fileExtension = [requestedUrl pathExtension];//lastPathComponent?
    if( fileExtension.length > 3 ) {
        fileExtension = [fileExtension substringToIndex:3];
    }
    NSString *fileName = [self createRandomFilename:64];
    if( fileExtension && [fileExtension length]){
        fileName = [fileName stringByAppendingPathExtension:fileExtension];
    }
    
    NSString  *filePath = [NSString stringWithFormat:@"%@/%@", [self getAppDocumentPath], fileName];
    
    if( [rawData writeToFile:filePath atomically:YES] ){
        //update database record
        if( !_delegateData ){
            NSLog(@"Need to set data delegate");
            return;
        }
        
        if( _delegateData ){
            [_delegateData updateImageCacheInfo:requestedUrl atDate:[NSDate date] forDownloadedFile:fileName];
        }
    }
    NSMutableArray *arrayDelegates = [self.dictionaryDelegates objectForKey:requestedUrl];
    if( arrayDelegates ){
        UIImage *image = [UIImage imageWithData:rawData];
        for( id delegateDownload in arrayDelegates ){
            [delegateDownload imageDownloadDidFinish:image forUrl:requestedUrl];
        }
        
        [self.dictionaryDelegates removeObjectForKey:requestedUrl];
    }
}

-(void)setDataDelegate:(id)inputSender{
    _delegateData = inputSender;
}
@end

