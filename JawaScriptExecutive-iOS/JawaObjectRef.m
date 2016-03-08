//
//  JawaObjectRef.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/20.
//
//

#import <Foundation/Foundation.h>
#import "JawaExecutor.h"
#import "JawaArray.h"
#import "JawaFunc.h"
#import "JawaObjectRef.h"

NSMutableArray* jawaObjectPool;

@implementation JawaObjectRef

-(id)initIn:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = NULL;
        _executor = ex;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithNumber:(double)number in:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = [NSDecimalNumber numberWithDouble:number];
        _executor = ex;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithString:(NSString*)string in:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = [NSMutableString stringWithString:string];
        _executor = ex;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithBoolean:(bool)tf in:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = [NSNumber numberWithBool:tf];
        _executor = ex;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaArray:(JawaArray*)array {
    self = [super init];
    if (self) {
        _object = array;
        _executor = array.executor;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaFunc:(JawaFunc*)func {
    self = [super init];
    if (self) {
        _object = func;
        _appliedOn = nil;
        _executor = func.executor;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj {
    self = [super init];
    if (self) {
        _object = func;
        _appliedOn = obj;
        _executor = func.executor;
        [jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaObject:(JawaObject*)obj {
    self = [super init];
    if (self) {
        _object = obj;
        _executor = obj.executor;
        [jawaObjectPool addObject:self];
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
-(void)dealloc {
    printf("Releasing %s\n", [[self description]cStringUsingEncoding:NSUTF8StringEncoding]);
}

+(id)RefIn:(JawaExecutor *)ex {
    return [[self alloc] initIn:ex];
}
+(id)RefWithNumber:(double)number in:(JawaExecutor*)ex {
    return [[self alloc] initWithNumber:number in:ex];
}
+(id)RefWithString:(NSString*)string in:(JawaExecutor*)ex {
    return [[self alloc] initWithString:string in:ex];
}
+(id)RefWithBoolean:(bool)tf in:(JawaExecutor*)ex {
    return [[self alloc] initWithBoolean:tf in:ex];
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
