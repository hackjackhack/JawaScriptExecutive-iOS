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

+(void)initialize {
    if (self == [JawaArray class]) {
        arrayPrototype = [[NSMutableDictionary alloc]init];
    }
}

-(id)initIn:(JawaExecutor *)ex {
    self = [super init];
    if (self) {
        _prototype = arrayPrototype;
        _elements = [[NSMutableArray alloc]init];
        _executor = ex;
    }
    return self;
}

-(NSString*)description {
    return @"";
}

-(NSMutableString*) toJSON:(NSMutableString*)ret {
    return [NSMutableString stringWithFormat: @""];
}

-(void)append:(JawaObjectRef*)element {
    // Need weak references stored in NSArray.
    NSValue* weakRef = [NSValue valueWithNonretainedObject:element];
    [self.elements addObject:weakRef];
}

-(JawaObjectRef*)at:(int)index {
    if (index < 0 || index >= [self.elements count])
        return nil;
    return [self.elements objectAtIndex:index];
}

-(JawaObjectRef*)invokeBuiltin:(NSString*)funcName {
    int ID = [self getBuiltinID:funcName];
    switch(ID) {
        default:
            break;
    }
    return nil;
}


@end