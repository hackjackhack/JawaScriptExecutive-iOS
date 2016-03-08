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
        default:
            [NSException raise:@"JavaScript Runtime Exception" format:@"%@ not implemented yet", funcName];
    }
    return nil;
}


@end