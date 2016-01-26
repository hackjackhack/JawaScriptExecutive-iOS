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

-(id)init { self = [super init]; _object = NULL; return self; }
-(id)initWithNumber:(double)number {
    self = [super init];
    if (self) {
        _object = [NSDecimalNumber numberWithDouble:number];
    }
    return self;
}
-(id)initWithString:(NSString*)string {
    self = [super init];
    if (self) {
        _object = [NSMutableString stringWithString:string];
    }
    return self;
}
-(id)initWithBoolean:(bool)tf {
    self = [super init];
    if (self) {
        _object = [NSNumber numberWithBool:tf];
    }
    return self;
}
-(id)initWithJawaArray:(JawaArray*)array {
    self = [super init];
    if (self) {
        _object = array;
    }
    return self;
}
-(id)initWithJawaFunc:(JawaFunc*)func {
    self = [super init];
    if (self) {
        _object = func;
        _appliedOn = nil;
    }
    return self;
}
-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj {
    self = [super init];
    if (self) {
        _object = func;
        _appliedOn = obj;
    }
    return self;
}
-(id)initWithJawaObject:(JawaObject*)obj {
    self = [super init];
    if (self) {
        _object = obj;
    }
    return self;
}
-(NSString*)description {
    if ([self.object isMemberOfClass: [NSDecimalNumber class]]) {
        double n = ((NSDecimalNumber*)self.object).doubleValue;
        if (fabs(n-round(n)) < QUANTUM) {
            return [NSString stringWithFormat:@"%ld", (long)n];
        }
        return [NSString stringWithFormat:@"%f", n];
    } else if ([self.object isMemberOfClass: [NSNumber class]]) {
        bool b = ((NSNumber*)self.object).boolValue;
        return b ? @"true" : @"false";
    } else if ([self.object isMemberOfClass: [NSMutableString class]]) {
        return [NSString stringWithString:((NSMutableString*)self.object)];
    } else if ([self.object isKindOfClass:[JawaObject class]]) {
        return [((JawaObject*)self.object) description];
    }
    return nil;
}
-(id)transfer {
    if ([self.object isKindOfClass:[NSNumber class]]) {
        return [((NSNumber*)self.object) copy];
    } else if ([self.object isMemberOfClass: [NSMutableString class]]) {
        return [((NSMutableString*)self.object) mutableCopy];
    } else
        return self.object;
}

+(id)Ref {
    return [[self alloc] init];
}
+(id)RefWithNumber:(double)number {
    return [[self alloc] initWithNumber:number];
}
+(id)RefWithString:(NSString*)string {
    return [[self alloc] initWithString:string];
}
+(id)RefWithBoolean:(bool)tf {
    return [[self alloc] initWithBoolean:tf];
}
+(id)RefWithJawaArray:(JawaArray*)array {
    return [[self alloc] initWithJawaArray:array];
}
+(id)RefWithJawaFunc:(JawaFunc*)func {
    return [[self alloc] initWithJawaFunc:func];
}
+(id)RefWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj {
    return [[self alloc] initWithJawaFunc:func on:obj];
}
+(id)RefWithJawaObject:(JawaObject*)obj {
    return [[self alloc] initWithJawaObject:obj];
}


@end
