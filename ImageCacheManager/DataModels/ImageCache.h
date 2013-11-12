//
//  ImageCache.h
//  apn
//
//  Created by Steven Woo on 9/24/13.
//  Copyright (c) 2013 Steven Woo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ImageCache : NSManagedObject

@property (nonatomic, retain) NSString * img_url;
@property (nonatomic, retain) NSString * img_local_path;
@property (nonatomic, retain) NSDate * last_loaded;

@end
