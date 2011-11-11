//
//  Gem.h
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Gem : NSObject  {
    NSString *_name;
    NSString *_nameWithoutVersion;
}
@property (retain,readwrite) NSString *name;
@property (readonly) NSString *nameWithoutVersion;

@end
