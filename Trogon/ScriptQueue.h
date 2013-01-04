//
//  ScriptQueue.h
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Cocoa/Cocoa.h>

@class ScriptStep;

@interface ScriptQueue : NSOperationQueue
{
	NSMutableDictionary *queueState;
	NSDictionary *textAttributes;
	NSDictionary *errorAttributes;
	NSDictionary *warningAttributes;
	NSMutableArray *cleanupSteps;
}

@property (nonatomic, copy) NSDictionary *textAttributes;
@property (nonatomic, copy) NSDictionary *errorAttributes;
@property (nonatomic, copy) NSDictionary *warningAttributes;

- (void)setStateValue:(id)value forKey:(NSString *)key;
- (id)stateValueForKey:(NSString *)key;
- (void)clearState;
- (void)addCleanupStep:(ScriptStep *)cleanupStep;
- (void)pushCleanupStep:(ScriptStep *)cleanupStep;
- (void)removeCleanupStep:(ScriptStep *)cleanupStep;
- (void)insertStepToRunImmediately:(ScriptStep *)scriptStep
	blockingDependentsOfStep:(ScriptStep *)dependeeStep;

@end

extern NSString * const ScriptQueueCancelledNotification;
