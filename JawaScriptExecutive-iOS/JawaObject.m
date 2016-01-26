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

-(id) init {
    self = [super init];
    _properties = [[NSMutableDictionary alloc] init];
    _prototype = objectPrototype;
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

-(int)getBuiltinID:(NSString*)funcName {
    NSObject* v = [self.prototype objectForKey:funcName];
    if (v != nil) return ((JawaFunc*)v).switchId;
    return -1;
}

-(JawaObjectRef*)invokeBuiltin:(NSString*)funcName {
    int ID = [self getBuiltinID:funcName];
    switch(ID) {
            // toJSON()
        case 0: {
            return [JawaObjectRef RefWithString:[self toJSON:nil]];
        }
    }
    return nil;
}

-(NSString*) description {
    return [NSString stringWithFormat:@""];
}

-(NSString*) toJSON:(NSMutableString*)ret {
    return [NSString stringWithFormat:@""];
}

@end