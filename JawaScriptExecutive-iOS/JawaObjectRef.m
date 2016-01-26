//
//  JawaObjectRef.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/20.
//
//

#import <Foundation/Foundation.h>
#import "JawaArray.h"
#import "JawaFunc.h"
#import "JawaObjectRef.h"

@implementation JawaObjectRef

-(id)init { self = [super init]; object = NULL; return self; }
-(id)initWithNumber:(double)number {
    self = [super init];
    object = [NSDecimalNumber numberWithDouble:number];
    return self;
}
-(id)initWithString:(NSString*)string {
    self = [super init];
    object = [NSMutableString stringWithString:string];
    return self;
}
-(id)initWithBoolean:(bool)tf {
    self = [super init];
    object = [NSNumber numberWithBool:tf];
    return self;
}
-(id)initWithJawaArray:(JawaArray*)array {
    self = [super init];
    object = array;
    return self;
}
-(id)initWithJawaFunc:(JawaFunc*)func {
    self = [super init];
    object = func;
    appliedOn = nil;
    return self;
}
-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj {
    self = [super init];
    object = func;
    appliedOn = obj;
    return self;
}
-(id)initWithJawaObject:(JawaObject*)obj {
    self = [super init];
    object = obj;
    return self;
}
-(NSString*)toString {
    if ([object class] == [NSDecimalNumber class]) {
        double n = ((NSDecimalNumber*)object).doubleValue;
        if (fabs(n-round(n)) < QUANTUM) {
            return [NSString stringWithFormat:@"%ld", (long)n];
        }
        return [NSString stringWithFormat:@"%f", n];
    } else if ([object class] == [NSNumber class]) {
        bool b = ((NSNumber*)object).boolValue;
        return b ? @"true" : @"false";
    } else if ([object class] == [NSMutableString class]) {
        return [NSString stringWithString:((NSMutableString*)object)];
    } else if ([object isKindOfClass:[JawaObject class]]) {
        return [((JawaObject*)object) toString];
    }
    return nil;
}
-(id)transfer {
    if ([object isKindOfClass:[NSNumber class]]) {
        return [((NSNumber*)object) copy];
    } else if ([object class] == [NSMutableString class]) {
        return [((NSMutableString*)object) mutableCopy];
    } else
        return object;
}

@end
