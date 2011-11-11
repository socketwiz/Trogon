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
- (void)performTask:(NSString *)aTask 
      withArguments:(NSArray *)taskArguments 
             object:(NSObject *)anObject 
           selector:(SEL)aSelector 
        synchronous:(BOOL)isSynchronous;
- (void)readDataUsingArguments:(NSArray *)theArguments;
@end
