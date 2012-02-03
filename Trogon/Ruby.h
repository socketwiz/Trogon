//
//  Ruby.h
//  Trogon
//
//  Created by Ricky Nelson on 10/16/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Ruby : NSObject {
    NSString *_interpreter;
}
@property (retain,readwrite) NSString *interpreter;

@end
