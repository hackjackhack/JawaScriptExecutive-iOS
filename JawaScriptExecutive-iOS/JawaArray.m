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
#import "JawaArray.h"
#import "JawaObjectProtected.h"
#import "JawaNumber.h"

NSInteger jawa_array_compare(JawaObjectRef* o1, JawaObjectRef* o2, void* context) {
    NSArray* ctxt = (__bridge NSArray*)context;
    JawaExecutor* ex = [ctxt objectAtIndex:0];
    JawaObjectRef* comparator = [ctxt objectAtIndex:1];
    return [ex compare:o1 and:o2 with:comparator];
}

@implementation JawaArray

-(id)initIn:(JawaExecutor *)ex {
    self = [super init];
    if (self) {
        _prototype = ex.arrayPrototype;
        _elements = [NSPointerArray weakObjectsPointerArray];
        _executor = ex;
    }
    return self;
}


-(NSString*)description {
    BOOL first = true;
    NSMutableString* ret = [NSMutableString stringWithString:@"["];
    for (JawaObjectRef* obj in self.elements) {
        if (!first)
            [ret appendString:@","];
        first = false;
        [ret appendString:[obj description]];
    }
    [ret appendString:@"]"];
    return ret;
}

-(NSMutableString*) toJSON:(NSMutableString*)ret {
    if (ret == nil)
        ret = [NSMutableString stringWithString:@""];
    BOOL first = true;
    [ret appendString:@"["];
    for (JawaObjectRef* obj in self.elements) {
        if (!first)
            [ret appendString:@","];
        first = false;
        if ([obj.object isKindOfClass:[NSString class]]) {
            [ret appendString:@"\""];
            NSString* r = [[obj description] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            [ret appendString:r];
            [ret appendString:@"\""];
        } else if ([obj.object isKindOfClass:[JawaObject class]]) {
            [((JawaObject*)obj.object) toJSON:ret];
        } else
            [ret appendString:[obj description]];
    }
    [ret appendString:@"]"];
    return ret;
}

-(void)append:(JawaObjectRef*)element {
    // Need weak references (raw pointer) stored in the array.
    [self.elements addPointer:(__bridge void * _Nullable)(element)];
    //printf("count : %ld", CFGetRetainCount((__bridge CFTypeRef)element));
}

-(JawaObjectRef*)at:(int)index {
    if (index < 0 || index >= [self.elements count])
        return nil;
    return [self.elements pointerAtIndex:index];
}

-(JawaObjectRef*)invokeBuiltin:(NSString*)funcName {
    NSUInteger ID = [self getBuiltinID:funcName];
    switch(ID) {
        // Array.length
        case 0: {
            return [JawaObjectRef RefWithNumber:self.elements.count in:self.executor];
        }
        // Array.slice(start, end)
        case 1: {
            JawaObjectRef* start = [[self.executor.currentActivation lastObject]objectForKey:@"start"];
            if (![start.object isMemberOfClass:[JawaNumber class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"start of slice() must be a number"];
            NSUInteger startInt = ((JawaNumber*)start.object).unsignedIntValue;
            if (startInt >= self.elements.count)
                [NSException raise:@"JawaScript Runtime Exception" format:@"start of slice() out of bound"];
            NSUInteger endInt = self.elements.count;
            JawaObjectRef* end = [[self.executor.currentActivation lastObject]objectForKey:@"end"];
            if (end != nil) {
                if (![end.object isMemberOfClass:[JawaNumber class]])
                    [NSException raise:@"JawaScript Runtime Exception" format:@"end of slice() must be a number"];
                endInt = ((JawaNumber*)end.object).unsignedIntValue;
                if (endInt > self.elements.count)
                    [NSException raise:@"JawaScript Runtime Exception" format:@"end of slice() out of bound"];
            }
            JawaArray* slice = [[JawaArray alloc]initIn:self.executor];
            for (NSUInteger i = startInt ; i < endInt ; i++) {
                [slice.elements addPointer:[self.elements pointerAtIndex:i]];
            }
            return [JawaObjectRef RefWithJawaArray:slice];
        }
        // Array.join(sep)
        case 2: {
            JawaObjectRef* sep = [[self.executor.currentActivation lastObject]objectForKey:@"sep"];
            if (![sep.object isKindOfClass:[NSString class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"separator of join() must be a string"];
            NSString* sepStr = [sep description];
            NSMutableString* ret = [NSMutableString stringWithString:@""];
            bool first = true;
            for (JawaObjectRef* o in self.elements) {
                if (!first)
                    [ret appendString:sepStr];
                first = false;
                [ret appendString:[o description]];
            }
            return [JawaObjectRef RefWithString:ret in:self.executor];
        }
        // Array.pop()
        case 3: {
            if (self.elements.count <= 0)
                return nil;
            JawaObjectRef* ret = [self.elements pointerAtIndex:self.elements.count - 1];
            [self.elements removePointerAtIndex:self.elements.count - 1];
            return ret;
        }
        // Array.push(item)
        case 4: {
            JawaObjectRef* item = [[self.executor.currentActivation lastObject]objectForKey:@"item"];
            [self.elements addPointer:(__bridge void*)item];
            return [JawaObjectRef RefWithNumber:self.elements.count in:self.executor];
        }
        // Array.reverse()
        case 5: {
            NSUInteger n = self.elements.count;
            for (NSUInteger i = 0 ; i < n / 2 ; i++) {
                void *t = [self.elements pointerAtIndex:i];
                [self.elements replacePointerAtIndex:i withPointer:[self.elements pointerAtIndex:n - i - 1]];
                [self.elements replacePointerAtIndex:n - i - 1 withPointer:t];
            }
            return [JawaObjectRef RefWithJawaArray:self];
        }
        // Array.shift()
        case 6: {
            if (self.elements.count <= 0)
                return nil;
            JawaObjectRef* item = [self.elements pointerAtIndex:0];
            [self.elements removePointerAtIndex:0];
            return item;
        }
        // Array.sort(compareFunction)
        case 7: {
            JawaObjectRef* compareFunction = [[self.executor.currentActivation lastObject]objectForKey:@"compareFunction"];
            if (compareFunction == nil)
                compareFunction = [JawaObjectRef RefIn:self.executor];
            NSArray* tempArray = self.elements.allObjects;
            NSArray* sorted = [tempArray sortedArrayUsingFunction:jawa_array_compare context:(__bridge void * _Nullable)(@[self.executor, compareFunction])];
            for (NSUInteger i = 0 ; i < sorted.count ; i++) {
                [self.elements replacePointerAtIndex:i withPointer:(__bridge void * _Nullable)([sorted objectAtIndex:i])];
            }
            return [JawaObjectRef RefWithJawaArray:self];
        }
        // Array.unshift()
        case 8: {
            JawaObjectRef* item = [[self.executor.currentActivation lastObject]objectForKey:@"item"];
            [self.elements insertPointer:(__bridge void*)item atIndex:0];
            return [JawaObjectRef RefWithNumber:self.elements.count in:self.executor];
        }
        default:
            [NSException raise:@"JavaScript Runtime Exception" format:@"%@ not implemented yet", funcName];
    }
    return nil;
}


@end
