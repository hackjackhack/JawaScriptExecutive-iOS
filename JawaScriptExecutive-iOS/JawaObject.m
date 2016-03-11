//
//  JawaObject.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/26.
//
//

#import <Foundation/Foundation.h>
#import "JawaObject.h"
#import "JawaFunc.h"

NSMutableDictionary* objectPrototype;

@implementation JawaObject

-(id) initIn:(JawaExecutor *)ex {
    self = [super init];
    if (self) {
        _properties = [NSMapTable strongToWeakObjectsMapTable];
        _prototype = objectPrototype;
        _executor = ex;
    }
    return self;
}

-(void) setProp:(NSString*)key with:(JawaObjectRef*)value {
    [self.properties setObject:value forKey:key];
}

-(JawaObjectRef*) getProp:(NSString*)key {
    NSObject* v = [self.properties objectForKey:key];
    if (v != nil) return (JawaObjectRef*)v;
    v = [self.prototype objectForKey:key];
    if (v != nil)
        return [JawaObjectRef
                RefWithJawaFunc:(JawaFunc*)v
                on:[JawaObjectRef RefWithJawaObject:self]];
    return nil;
}

-(NSUInteger)getBuiltinID:(NSString*)funcName {
    NSObject* v = [self.prototype objectForKey:funcName];
    if (v != nil) return ((JawaFunc*)v).switchId;
    return 0xFFFFFFFF;
}

-(JawaObjectRef*)invokeBuiltin:(NSString*)funcName {
    NSUInteger ID = [self getBuiltinID:funcName];
    switch(ID) {
        // toJSON()
        case 0: {
            return [JawaObjectRef RefWithString:[self toJSON:nil] in:self.executor];
        }
    }
    return nil;
}

-(NSString*) description {
    NSMutableString* ret = [NSMutableString stringWithString:@"{"];
    BOOL first = true;
    for (NSString* key in self.properties) {
        if (!first)
            [ret appendString:@","];
        first = false;
        [ret appendString:key];
        [ret appendString:@":"];
        JawaObjectRef* value = [self.properties objectForKey:key];
        if ([value.object isMemberOfClass:[NSMutableString class]]) {
            [ret appendString:@"'"];
            [ret appendString:[value description]];
            [ret appendString:@"'"];
        } else
            [ret appendString:[value description]];
    }
    [ret appendString:@"}"];
    return ret;
}

-(NSMutableString*) toJSON:(NSMutableString*)ret {
    if (ret == nil)
        ret = [NSMutableString stringWithString:@""];
    [ret appendString:@"{"];
    BOOL first = true;
    for (NSString* key in self.properties) {
        if (!first)
            [ret appendString:@","];
        first = false;
        [ret appendString:@"\""];
        [ret appendString:key];
        [ret appendString:@"\":"];
        JawaObjectRef* value = [self.properties objectForKey:key];
        if ([value.object isKindOfClass:[NSString class]]) {
            [ret appendString:@"\""];
            NSString* r = [[value description] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            [ret appendString:r];
            [ret appendString:@"\""];
        } else if ([value.object isKindOfClass:[JawaObject class]]) {
            [(JawaObject*)value.object toJSON:ret];
        } else
            [ret appendString:[value description]];
    }
    [ret appendString:@"}"];
    return ret;
}

@end