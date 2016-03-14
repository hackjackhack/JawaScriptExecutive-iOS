/*
 Copyright (c) 2016, Chi-Wei(Jack) Wang
 All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the intowow nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL Chi-Wei(Jack) Wang BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "JawaExecutor.h"
#import "JawaArray.h"
#import "JawaFunc.h"
#import "JawaNumber.h"
#import "JawaObjectRef.h"

int release_count;
int obj_count;

@implementation JawaObjectRef

-(id)initIn:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = NULL;
        _executor = ex;
        _obj_id = obj_count++;
        //printf("%d : null\n", _obj_id);
        [ex.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithNumber:(double)number in:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = [[JawaNumber alloc]init:number];
        _executor = ex;
        _obj_id = obj_count++;
        //printf("%d : number(%lf)\n", _obj_id, number);
        [ex.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithString:(NSString*)string in:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = [NSMutableString stringWithString:string];
        _executor = ex;
        _obj_id = obj_count++;
        //printf("%d : string(%s)\n", _obj_id, [string cStringUsingEncoding: NSUTF8StringEncoding]);
        [ex.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithBoolean:(bool)tf in:(JawaExecutor*)ex {
    self = [super init];
    if (self) {
        _object = [NSNumber numberWithBool:tf];
        _executor = ex;
        _obj_id = obj_count++;
        //printf("%d : bool(%d)\n", _obj_id, tf);
        [ex.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaArray:(JawaArray*)array {
    self = [super init];
    if (self) {
        _object = array;
        _executor = array.executor;
        _obj_id = obj_count++;
        //printf("%d : array\n", _obj_id);
        [_executor.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaFunc:(JawaFunc*)func {
    self = [super init];
    if (self) {
        _object = func;
        _appliedOn = nil;
        _executor = func.executor;
        _obj_id = obj_count++;
        //printf("%d : func(%s)\n", _obj_id, [[func.name description]cStringUsingEncoding:NSUTF8StringEncoding]);
        [_executor.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj {
    self = [super init];
    if (self) {
        _object = func;
        _appliedOn = obj;
        _executor = func.executor;
        _obj_id = obj_count++;
        //printf("%d : func(%s)\n", _obj_id, [[func.name description]cStringUsingEncoding:NSUTF8StringEncoding]);
        [_executor.jawaObjectPool addObject:self];
    }
    return self;
}

-(id)initWithJawaObject:(JawaObject*)obj {
    self = [super init];
    if (self) {
        _object = obj;
        _executor = obj.executor;
        _obj_id = obj_count++;
        //printf("%d : object\n", _obj_id);
        [_executor.jawaObjectPool addObject:self];
    }
    return self;
}

-(NSString*)description {
    if ([self.object isMemberOfClass: [JawaNumber class]]) {
        return [((JawaNumber*)self.object) description];
    } else if ([self.object isKindOfClass: [NSNumber class]]) {
        bool b = ((NSNumber*)self.object).boolValue;
        return b ? @"true" : @"false";
    } else if ([self.object isKindOfClass: [NSString class]]) {
        return [NSString stringWithString:((NSString*)self.object)];
    } else if ([self.object isKindOfClass:[JawaObject class]]) {
        return [((JawaObject*)self.object) description];
    }
    return nil;
}
-(id)transfer {
    if ([self.object isMemberOfClass:[JawaNumber class]]) {
        double d = ((JawaNumber*)self.object).value;
        return [JawaNumber numberWithDouble:d];
    } else if ([self.object isKindOfClass:[NSNumber class]]) {
        return [((NSNumber*)self.object) copy];
    } else if ([self.object isMemberOfClass: [NSMutableString class]]) {
        return [((NSMutableString*)self.object) mutableCopy];
    } else
        return self.object;
}

-(void)dealloc {
    release_count++;
        //printf("Releasing %s\n", [NSStringFromClass([self class]) cStringUsingEncoding:NSUTF8StringEncoding]);
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
