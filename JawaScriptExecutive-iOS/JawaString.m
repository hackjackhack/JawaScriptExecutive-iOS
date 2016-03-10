//
//  JawaString.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/27.
//
//

#import <Foundation/Foundation.h>
#import "JawaString.h"
#import "JawaArray.h"
#import "JawaFunc.h"

@class JawaExecutor;
// TODO: Initialize stringPrototype in Executor initialize()
NSDictionary* stringPrototype;

JawaObjectRef* dispatchStringBuiltin(NSString* str, NSString* funcName, JawaExecutor *ex) {
    if ([stringPrototype objectForKey:funcName] == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"string has no method %@()", funcName];
    NSUInteger funcId = ((JawaFunc*)[stringPrototype objectForKey:funcName]).switchId;
    switch (funcId) {
        // String.split(delim)
        case 0: {
            JawaArray *result = [[JawaArray alloc]initIn:ex];
            NSString* delim = [[[ex.currentActivation lastObject]objectForKey:@"delim"]description];
            if (delim.length == 0) {
                for (NSUInteger i = 0; i < str.length; i++) {
                    NSString* slice = [str substringWithRange:NSMakeRange(i, 1)];
                    JawaObjectRef *s = [JawaObjectRef RefWithString:slice in:ex];
                    [result append:s];
                }
            } else {
                NSArray* slices = [str componentsSeparatedByString:delim];
                for (NSString* slice in slices) {
                    JawaObjectRef *s = [JawaObjectRef RefWithString:slice in:ex];
                    [result append:s];
                }
            }
            return [JawaObjectRef RefWithJawaArray:result];
        }
        default:
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented"];
    }
    return nil;
}