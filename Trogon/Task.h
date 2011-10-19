//
//  Task.h
//  Trogon
//
//  Created by Ricky Nelson on 10/18/11.
//  Copyright (c) 2011 Lark Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Task : NSObject {
    
}

+ (Task *)sharedTask;
- (NSPipe *)performTask:(NSString *)aTask arguments:(NSArray *)taskArguments;
@end
