//
//  JawaFunc.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/27.
//
//

#import <Foundation/Foundation.h>
#import "JawaFunc.h"
#import "JawaString.h"

@implementation JawaFunc

-(id)initWithName:(NSString*)name in:(JawaExecutor*)ex taking:(NSArray*)params isBuiltin:(BOOL)builtin isPropertyWrapper:(BOOL)propertyWrapper and:(NSDictionary*)body {
    self = [super init];
    if (self) {
        _name = name;
        _params = params;
        _isBuiltIn = builtin;
        _isPropertyWrapper = propertyWrapper;
        _body = body;
        _executor = ex;
    }
    return self;
}

-(JawaObjectRef*)apply:(JawaObjectRef*)on {
    if (!self.isBuiltIn)
        return nil;
    if ([on.object isKindOfClass:[NSString class]])
        return dispatchStringBuiltin((NSString*)on.object, self.name, self.executor);
    if ([on.object isKindOfClass:[JawaObject class]])
        return [(JawaObject*)on.object invokeBuiltin:self.name];
    return nil;
}

-(JawaObjectRef*)apply {
    if (!self.isBuiltIn) {
        [self.executor evaluate:self.body];
        return [(NSDictionary*)[self.executor.currentActivation
                                objectAtIndex:0]
                objectForKey:@"return"];
    } else
        return [self.executor dispatchBuiltin:self.name];
}

-(NSString*)description {
    return @"function";
}


@end