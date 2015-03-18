//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAPOIHelper : NSObject

@property (nonatomic, readonly) NSArray *categories;
@property (nonatomic, readonly) NSArray *pois;

+ (OAPOIHelper *)sharedInstance;

- (NSArray *)categoryPOIs:(NSString *)category;

@end
