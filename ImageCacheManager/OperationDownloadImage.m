//
//  OperationDownloadImage.m
//  testbed
//
//  Created by Steven Woo on 9/24/13.
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
//

#import "OperationDownloadImage.h"
@interface OperationDownloadImage()
@property NSURLConnection		*connection;
@property NSMutableData         *data;
@property UIImage             *image;
@end

@implementation OperationDownloadImage
@synthesize requestedUrl;
@synthesize delegateDownloadImage;
@synthesize isExecuting;
@synthesize isFinished;

-(void)dealloc {
    _data = nil;
    _connection = nil;
    _image = nil;
    delegateDownloadImage = nil;
}
-(id)init:(id)sender forUrl:(NSString*)inputUrl {
    isExecuting = NO;
    isFinished = NO;
    self = [super init];
    if( !self ){
        return nil;
    }
    requestedUrl = [inputUrl copy];
    delegateDownloadImage = sender;
    return self;
}
-(void)cancel {
    delegateDownloadImage = nil;
    [_connection cancel];
    [super cancel];
}
-(void)start {
    if( ![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(start) withObject:self waitUntilDone:NO];
        return;
    }
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestedUrl]];
    if( !urlRequest ){
        [self finish];
        return;
    }
    [urlRequest setValue:@"application/x-www-form-urlencoded"  forHTTPHeaderField:@"content-type"];
    [urlRequest setHTTPMethod:@"GET"];
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    _connection = [[NSURLConnection alloc]initWithRequest:urlRequest delegate:self];
    if( !_connection ){
        [self finish];
        return;
    }
    
}
-(void)finish {
    _connection = nil;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
}
-(BOOL)isConcurrent {
    return YES;
}

-(void)delegateFinish {
    if( ![self isCancelled]){
        [delegateDownloadImage operationDownloadImageDidFinish:self withImage:_image withRawData:_data forUrl:requestedUrl];
    }
}

#pragma mark NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self performSelectorOnMainThread:@selector(delegateFinish) withObject:nil waitUntilDone:YES];
    [self finish];
}
#pragma mark NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)inputConnection didReceiveData:(NSData *)inputData {
    if( [self isCancelled]){
        [_connection cancel];
        delegateDownloadImage = nil;
        [self finish];
        return;
    }
    [_data appendData:inputData];
}
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [NSMutableData data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)inputConnection {
    if( [self isCancelled]){
        [_connection cancel];
        delegateDownloadImage = nil;
        [self finish];
        return;
    }
    _image = [[UIImage alloc] initWithData:_data];
    [self performSelectorOnMainThread:@selector(delegateFinish) withObject:nil waitUntilDone:YES];
    [self finish];
    
}
@end
