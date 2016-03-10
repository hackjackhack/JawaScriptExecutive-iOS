//
//  JawaArray.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/27.
//
//

#import <Foundation/Foundation.h>
#import "JawaArray.h"
#import "JawaObjectProtected.h"
#import "JawaNumber.h"

NSMutableDictionary* arrayPrototype;

@implementation JawaArray

-(id)initIn:(JawaExecutor *)ex {
    self = [super init];
    if (self) {
        _prototype = arrayPrototype;
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
        if ([obj.object isMemberOfClass:[NSMutableString class]]) {
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
            NSUInteger startInt = ((NSNumber*)start.object).unsignedIntValue;
            if (startInt >= self.elements.count)
                [NSException raise:@"JawaScript Runtime Exception" format:@"start of slice() out of bound"];
            NSUInteger endInt = self.elements.count;
            JawaObjectRef* end = [[self.executor.currentActivation lastObject]objectForKey:@"end"];
            if (end != nil) {
                if (![end.object isKindOfClass:[NSNumber class]])
                    [NSException raise:@"JawaScript Runtime Exception" format:@"end of slice() must be a number"];
                endInt = ((NSNumber*)end.object).unsignedIntValue;
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
        default:
            [NSException raise:@"JavaScript Runtime Exception" format:@"%@ not implemented yet", funcName];
    }
    return nil;
}


@end