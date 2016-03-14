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
#import "JawaString.h"
#import "JawaArray.h"
#import "JawaFunc.h"
#import "JawaNumber.h"

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
        // String.length
        case 1: {
            return [JawaObjectRef RefWithNumber:str.length in:ex];
        }
        // String.substring(begin, end)
        case 2: {
            JawaObjectRef* begin = [[ex.currentActivation lastObject]objectForKey:@"begin"];
            if (![begin.object isMemberOfClass:[JawaNumber class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"First argument of substring() must be a number"];
            unsigned int beginInt = ((JawaNumber*)begin.object).unsignedIntValue;
            if (beginInt >= str.length)
                [NSException raise:@"JawaScript Runtime Exception" format:@"begin of substring() out of bound"];
            if ([[ex.currentActivation lastObject]objectForKey:@"end"] == nil)
                return [JawaObjectRef RefWithString:[str substringFromIndex:beginInt] in:ex];
            JawaObjectRef* end = [[ex.currentActivation lastObject]objectForKey:@"end"];
            if (![end.object isMemberOfClass:[JawaNumber class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"Second argument of substring() must be a number"];
            unsigned int endInt = ((JawaNumber*)end.object).unsignedIntValue;
            if (endInt > str.length)
                [NSException raise:@"JawaScript Runtime Exception" format:@"end of substring() out of bound"];
            return [JawaObjectRef RefWithString:[str substringWithRange:NSMakeRange(beginInt, endInt - beginInt)] in:ex];
        }
        // String.toLowerCase()
        case 3: {
            return [JawaObjectRef RefWithString:[str lowercaseString] in:ex];
        }
        // String.replace()
        case 4: {
            JawaObjectRef* searchValue = [[ex.currentActivation lastObject]objectForKey:@"searchvalue"];
            JawaObjectRef* newValue = [[ex.currentActivation lastObject]objectForKey:@"newvalue"];
            return [JawaObjectRef RefWithString:[str stringByReplacingOccurrencesOfString:[searchValue description] withString:[newValue description]] in:ex];
        }
        // String.charCodeAt(index)
        case 5: {
            JawaObjectRef* index = [[ex.currentActivation lastObject]objectForKey:@"index"];
            if (![index.object isMemberOfClass:[JawaNumber class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"index of charCodeAt() must be a number"];
            unsigned int indexInt = ((JawaNumber*)index.object).unsignedIntValue;
            if (indexInt > str.length)
                [NSException raise:@"JawaScript Runtime Exception" format:@"index of charCodeAt() out of bound"];
            return [JawaObjectRef RefWithNumber:[str characterAtIndex:indexInt] in:ex];
        }
        // String.indexOf(searchvalue, start)
        case 6: {
            JawaObjectRef* searchValue = [[ex.currentActivation lastObject]objectForKey:@"searchvalue"];
            if (![searchValue.object isKindOfClass:[NSString class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"searchvalue of indexOf() must be a string"];
            NSString* searchStr = [searchValue description];
            unsigned int startInt = 0;
            JawaObjectRef* start = [[ex.currentActivation lastObject]objectForKey:@"start"];
            if (start != nil) {
                if (![start.object isMemberOfClass:[JawaNumber class]])
                    [NSException raise:@"JawaScript Runtime Exception" format:@"start of indexOf() must be a number"];
                startInt = ((JawaNumber*)start.object).unsignedIntValue;
                if (startInt >= str.length)
                    [NSException raise:@"JawaScript Runtime Exception" format:@"start of indexOf() out of bound"];
            }
            
            NSUInteger loc = [str rangeOfString:searchStr options:0 range:NSMakeRange(startInt, str.length - startInt)].location;
            if (loc == NSNotFound)
                return [JawaObjectRef RefWithNumber:-1 in:ex];
            return [JawaObjectRef RefWithNumber:loc in:ex];
        }
        // String.lastIndexOf(searchvalue, start)
        case 7: {
            JawaObjectRef* searchValue = [[ex.currentActivation lastObject]objectForKey:@"searchvalue"];
            if (![searchValue.object isKindOfClass:[NSString class]])
                [NSException raise:@"JawaScript Runtime Exception" format:@"searchvalue of lastIndexOf() must be a string"];
            NSString* searchStr = [searchValue description];
            NSUInteger startInt = str.length;
            JawaObjectRef* start = [[ex.currentActivation lastObject]objectForKey:@"start"];
            if (start != nil) {
                if (![start.object isMemberOfClass:[JawaNumber class]])
                    [NSException raise:@"JawaScript Runtime Exception" format:@"start of lastIndexOf() must be a number"];
                startInt = ((JawaNumber*)start.object).unsignedIntValue;
                if (startInt >= str.length)
                    [NSException raise:@"JawaScript Runtime Exception" format:@"start of lastIndexOf() out of bound"];
            }
            NSUInteger loc = [str rangeOfString:searchStr options:NSBackwardsSearch range:NSMakeRange(0, startInt)].location;
            if (loc == NSNotFound)
                return [JawaObjectRef RefWithNumber:-1 in:ex];
            return [JawaObjectRef RefWithNumber:loc in:ex];
        }
        // String.trim()
        case 8: {
            return [JawaObjectRef RefWithString:[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] in:ex];
        }
        default:
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented"];
    }
    return nil;
}