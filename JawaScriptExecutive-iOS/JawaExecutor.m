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
#import <UIKit/UIKit.h>
#import "JawaExecutor.h"
#import "JawaArray.h"
#import "JawaFunc.h"
#import "JawaString.h"
#import "JawaNumber.h"
#import "utility.h"

NSMutableDictionary* builtinFunctions;

@implementation JawaExecutor

-(id)init {
    self = [super init];
    if (self) {
        _global = [[NSMutableDictionary alloc]init];
        _activations = [[NSMutableArray alloc]init];
        _currentActivation = [[NSMutableArray alloc]init];
        [_currentActivation addObject:_global];
        [_activations addObject:_currentActivation];
        _currentIterationScope = nil;
        _isFromCallExpression = false;
        
        NULL_CONSTANT = [JawaObjectRef RefIn:self];
        
        _jawaObjectPool = [[NSMutableArray alloc]init];
        
        arrayPrototype = [[NSMutableDictionary alloc]init];
        stringPrototype = [[NSMutableDictionary alloc]init];
        objectPrototype = [[NSMutableDictionary alloc]init];
        builtinFunctions = [[NSMutableDictionary alloc]init];
        
        // Built-in functions
        [self registerBuilitinFunc:builtinFunctions funcName:@"alert" params:@[@"msg"]];
        [self registerBuilitinFunc:builtinFunctions funcName:@"getenv" params:@[@"varname"]];
        [self registerBuilitinFunc:builtinFunctions funcName:@"extern" params:@[@"functionName", @"argument"]];
        [self registerBuilitinFunc:builtinFunctions funcName:@"parseInt" params:@[@"string", @"radix"]];
        for (NSString* name in builtinFunctions) {
            JawaFunc* f = [builtinFunctions objectForKey:name];
            [self.global setObject:[JawaObjectRef RefWithJawaFunc:f] forKey:name];
        }
        
        // Array prototype
        [self registerBuilitinProp:arrayPrototype propName:@"length"];
        [self registerBuilitinFunc:arrayPrototype funcName:@"slice" params:@[@"start", @"end"]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"join" params:@[@"sep"]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"pop" params:@[]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"push" params:@[@"item"]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"reverse" params:@[]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"shift" params:@[]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"sort" params:@[@"compareFunction"]];
        [self registerBuilitinFunc:arrayPrototype funcName:@"unshift" params:@[@"item"]];
        
        // String prototype
        [self registerBuilitinFunc:stringPrototype funcName:@"split" params:@[@"delim"]];
        [self registerBuilitinProp:stringPrototype propName:@"length"];
        [self registerBuilitinFunc:stringPrototype funcName:@"substring" params:@[@"begin", @"end"]];
        [self registerBuilitinFunc:stringPrototype funcName:@"toLowerCase" params:@[]];
        [self registerBuilitinFunc:stringPrototype funcName:@"replace" params:@[@"searchvalue", @"newvalue"]];
        [self registerBuilitinFunc:stringPrototype funcName:@"charCodeAt" params:@[@"index"]];
        [self registerBuilitinFunc:stringPrototype funcName:@"indexOf" params:@[@"searchvalue", @"start"]];
        [self registerBuilitinFunc:stringPrototype funcName:@"lastIndexOf" params:@[@"searchvalue", @"start"]];
        [self registerBuilitinFunc:stringPrototype funcName:@"trim" params:@[]];
        
        // Object prototype
        [self registerBuilitinFunc:objectPrototype funcName:@"toJSON" params:@[]];
    }
    return self;
}

-(JawaObjectRef*)dispatchBuiltin:(NSString *)funcName {
    if ([builtinFunctions objectForKey:funcName] == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"No method %@().", funcName];
    NSUInteger funcId = ((JawaFunc*)[builtinFunctions objectForKey:funcName]).switchId;
    switch (funcId) {
        // alert()
        case 0: {
            JawaObjectRef *msg = [[[self.activations lastObject]lastObject]objectForKey:@"msg"];
            if (msg == nil)
                printf("undefined\n");
            else
                printf("%s\n", [[msg description]cStringUsingEncoding:NSUTF8StringEncoding]);
            return nil;
        }
        // getenv(varname)
        case 1: {
            NSString* varname = [[[self.currentActivation lastObject]objectForKey:@"varname"]description];
            if ([self.env objectForKey:varname] != nil) {
                return [self toJawa:[self.env objectForKey:varname]];
            } else
                return nil;
        }
        // extern(functionName, argument)
        case 2: {
            NSString* functionName = [[[self.currentActivation lastObject]objectForKey:@"functionName"]description];
            JawaObjectRef* arg = [[self.currentActivation lastObject]objectForKey:@"argument"];
            NSMutableDictionary* argJSON = nil;
            if (arg != nil) {
                if (![arg.object isMemberOfClass:[JawaObject class]])
                    [NSException raise:@"JawaScript Runtime Exception" format:@"The argument for extern() must be an object"];
                argJSON = jsonToDictionary([[(JawaObject*)arg.object toJSON:nil]description]);
            }
            return [self toJawaObject:[self.externalCallback call:functionName with: argJSON]];
        }
        // parseInt(string, radix)
        case 3: {
            NSString* str = [[[[[self.currentActivation lastObject]objectForKey:@"string"]description]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]lowercaseString];
            if (str.length == 0)
                return [JawaObjectRef RefWithNumber:0 in:self];
            
            // Sign
            int sign = 1;
            unichar sc = [str characterAtIndex:0];
            if (sc == '+' || sc == '-') {
                sign = (sc == '+' ? 1 : -1);
                str = [str substringFromIndex:1];
            }
            
            // Radix
            int radix = 10;
            JawaObjectRef* arg2 = [[self.currentActivation lastObject]objectForKey:@"radix"];
            if (arg2 != nil && [arg2.object isMemberOfClass:[JawaNumber class]])
                radix = ((JawaNumber*)arg2.object).intValue;
            else if (str.length >= 2 && ([str hasPrefix:@"0x"] || [str hasPrefix:@"0X"])) {
                radix = 16;
                str = [str substringFromIndex:2];
            }
            
            // Conversion
            if (radix > 36)
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid radix : %d", radix];
            int end;
            for (end = 0 ; end < str.length ; end++) {
                unichar c = [str characterAtIndex:end];
                if (c >= '0' && c <= '9') c -= '0';
                else if (c >= 'a' && c <= 'z') c = c - 'a' + 10;
                else break;
                if (c >= radix) break;
            }
            str = [str substringToIndex:end];
            if (str.length == 0)
                return [JawaObjectRef RefWithNumber:0 in:self];
            
            long long v = strtoll([str cStringUsingEncoding:NSUTF8StringEncoding], NULL, radix);
            return [JawaObjectRef RefWithNumber:v in:self];
        }
        default:
            [NSException raise:@"JawaScript Runtime Exception" format:@"Builtin function not found: %@", funcName];
    }
    return nil;
}

-(void)execute:(NSDictionary*)ast {
    [self evaluate:ast];
}

-(NSMutableDictionary*)invoke:(NSString *)funcName with:(NSDictionary*)asInput {
    self.env = asInput;
    JawaObjectRef* func = [self.global objectForKey:funcName];
    JawaFunc* resolvedFunction = (JawaFunc*)func.object;
    NSMutableDictionary* scope = [[NSMutableDictionary alloc]init];
    NSMutableArray* activation = [[NSMutableArray alloc]init];
    [activation addObject:scope];
    bool oldIsFromCallExpression = self.isFromCallExpression;
    self.isFromCallExpression = true;
    [self.activations addObject:activation];
    self.currentActivation = activation;
    JawaObjectRef *ret = [resolvedFunction apply];
    [self.activations removeLastObject];
    self.currentActivation = [self.activations lastObject];
    self.isFromCallExpression = oldIsFromCallExpression;
    
    NSMutableDictionary* retJSON = [[NSMutableDictionary alloc]init];
    //printf("%s\n", [[[ret.object class]description]cStringUsingEncoding:NSUTF8StringEncoding]);
    if (ret == nil || ret.object == nil)
        [retJSON setObject:@"null" forKey:@"retType"];
    else if ([ret.object isMemberOfClass:[JawaArray class]]) {
        [retJSON setObject:@"array" forKey:@"retType"];
        NSString* json = [((JawaArray*)ret.object) toJSON:nil];
        [retJSON setObject:jsonToArray(json) forKey:@"retValue"];
    } else if ([ret.object isKindOfClass:[JawaObject class]]) {
        [retJSON setObject:@"object" forKey:@"retType"];
        NSString* json = [((JawaObject*)ret.object) toJSON:nil];
        [retJSON setObject:jsonToDictionary(json) forKey:@"retValue"];
    } else if ([ret.object isKindOfClass:[NSString class]]) {
        [retJSON setObject:@"string" forKey:@"retType"];
        [retJSON setObject:[ret.object copy] forKey:@"retValue"];
    } else if ([ret.object isMemberOfClass:[JawaNumber class]]) {
        [retJSON setObject:@"number" forKey:@"retType"];
        double d = ((JawaNumber*)ret.object).value;
        [retJSON setObject:[NSNumber numberWithDouble:d] forKey:@"retValue"];
    } else if ([ret.object isKindOfClass:[NSNumber class]]) {
        [retJSON setObject:@"boolean" forKey:@"retType"];
        NSNumber *n = (NSNumber*)ret.object;
        [retJSON
         setObject:n.boolValue ? @"true" : @"false"
         forKey:@"retValue"];
    }
    //printf("%lu objects are in pool.\n", _jawaObjectPool.count);
    [self gc];
    
    return retJSON;
}

-(void)gc {
    for (JawaObjectRef* obj in _jawaObjectPool) {
        obj.marked = false;
        obj.discovered = false;
    }
    for (NSString* key in self.global) {
        JawaObjectRef *objRef = [self.global objectForKey:key];
        [self markAndTraverse:objRef];
    }
    
    NSMutableArray *markedObj = [NSMutableArray array];
    for (JawaObjectRef* obj in _jawaObjectPool) {
        if (obj.marked)
            [markedObj addObject:obj];
        //else
        //    printf("Recycled: %d\n", obj.obj_id);
    }
    //printf("%lu objects recycled.\n", _jawaObjectPool.count - markedObj.count);
    [_jawaObjectPool setArray:markedObj];
}

-(void)markAndTraverse:(JawaObjectRef*)objRef {
    objRef.marked = true;
    objRef.discovered = true;
    
    if ([objRef.object isMemberOfClass:[JawaArray class]]) {
        JawaArray* arr = ((JawaArray*)objRef.object);
        for (JawaObjectRef* elementRef in arr.elements) {
            if (!elementRef.discovered)
                [self markAndTraverse:elementRef];
        }
    } else if ([objRef.object isMemberOfClass:[JawaObject class]]) {
        JawaObject* obj = ((JawaObject*)objRef.object);
        for (NSString* key in obj.properties) {
            JawaObjectRef *elementRef = [obj.properties objectForKey:key];
            if (!elementRef.discovered)
                [self markAndTraverse:elementRef];
        }
    }
}

-(NSInteger)compare:(JawaObjectRef*)o1 and:(JawaObjectRef*)o2 with:(JawaObjectRef*)comparator {
    if (comparator != nil && comparator.object != nil) {
        if (![comparator.object isMemberOfClass:[JawaFunc class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"Comparator must be a function"];
        JawaFunc* compFunc = ((JawaFunc*)comparator.object);
        NSMutableDictionary* scope = [[NSMutableDictionary alloc]init];
        [scope setObject:o1 forKey:[compFunc.params objectAtIndex:0]];
        [scope setObject:o2 forKey:[compFunc.params objectAtIndex:1]];
        NSMutableArray* activation = [[NSMutableArray alloc]init];
        [activation addObject:scope];
        bool oldIsFromCallExpression = self.isFromCallExpression;
        self.isFromCallExpression = true;
        [self.activations addObject:activation];
        self.currentActivation = activation;
        
        JawaObjectRef* ret = [compFunc apply];
        if (![ret.object isMemberOfClass:[JawaNumber class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"The return value of a comparator must be a number"];
        NSInteger compResult = ((JawaNumber*)ret.object).intValue;
        [self.activations removeLastObject];
        self.currentActivation = [self.activations lastObject];
        self.isFromCallExpression = oldIsFromCallExpression;
        return compResult;
    } else {
        return [[o1 description] compare:[o2 description]];
    }
}

-(void)registerExternalCallback:(id<JawaExternalCallback>)cb {
    self.externalCallback = cb;
}

-(int)toInteger:(JawaObjectRef*)o {
    if ([o.object isMemberOfClass:[JawaNumber class]]) {
        double d = ((JawaNumber*)o.object).doubleValue;
        int magnitude = (int)(long long)floor(fabs(d));
        int sign = d >= 0 ? 1 : -1;
        return magnitude * sign;
    }
    [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented conversion"];
    return -1;
}

-(JawaObjectRef*)toJawa:(NSObject*)obj {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self toJawaObject:(NSDictionary*)obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [self toJawaArray:(NSArray*)obj];
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [JawaObjectRef RefWithString:(NSString*)obj in:self];
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        double d = ((NSNumber*)obj).doubleValue;
        return [JawaObjectRef RefWithNumber:d in:self];
    }
    return nil;
}

-(JawaObjectRef*)toJawaObject:(NSDictionary*)dict {
    JawaObject* jawaObj = [[JawaObject alloc]initIn:self];
    for (NSString* key in dict) {
        NSObject* val = [dict objectForKey:key];
        [jawaObj setProp:key with:[self toJawa:val]];
    }
    return [JawaObjectRef RefWithJawaObject:jawaObj];
}

-(JawaObjectRef*)toJawaArray:(NSArray*)array {
    JawaArray* jawaArr = [[JawaArray alloc]initIn:self];
    for (NSObject* e in array) {
        [jawaArr append:[self toJawa:e]];
    }
    return [JawaObjectRef RefWithJawaArray:jawaArr];
}

//-(void)dealloc {
//    printf("Executor Recycled:\n");
//}

-(JawaObjectRef*)evalInExpression:(NSDictionary*)ast {
    NSArray* subExpressions = [ast objectForKey:PR_subExpressions];
    
    JawaObjectRef* firstOprnd = [self evaluate:[subExpressions objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < subExpressions.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[subExpressions objectAtIndex:i]];
        if (secondOprnd == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Second operand of in-expression mustn't be null"];
        if (firstOprnd == nil)
            firstOprnd = [JawaObjectRef RefWithBoolean:false in:self];
        
        bool found;
        if ([secondOprnd.object isMemberOfClass:[JawaArray class]]) {
            JawaArray* arr = ((JawaArray*)secondOprnd.object);
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double value = ((JawaNumber*)firstOprnd.object).doubleValue;
                if (fabs(round(value) - value) < QUANTUM) {
                    int index = (int)round(value);
                    found = index >= 0 && index < arr.elements.count;
                } else
                    found = false;
            } else
                found = [arr getProp:[firstOprnd description]] != nil;
        } else if ([secondOprnd.object isMemberOfClass:[JawaObject class]]) {
            JawaObject* obj = ((JawaObject*)secondOprnd.object);
            found = [obj getProp:[firstOprnd description]] != nil;
        } else
            [NSException raise:@"JawaScript Runtime Exception" format:@"Illegal operand for in-expression"];
        firstOprnd = [JawaObjectRef RefWithBoolean:found in:self];
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalUnaryExpression:(NSDictionary*)ast {
    NSString* op = [[((NSString*)[ast objectForKey:PR_op]) componentsSeparatedByString:@","]objectAtIndex:1];
    JawaObjectRef* subExpression = [self evaluate:[ast objectForKey:PR_subExpression]];
    if (subExpression == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Unary op cannot be applied to null"];
    if ([op isEqualToString:@"++"] || [op isEqualToString:@"--"]) {
        if (![subExpression.object isMemberOfClass:[JawaNumber class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"++ and -- only apply to numbers"];
        double d = ((JawaNumber*)subExpression.object).doubleValue;
        subExpression.object = [JawaNumber numberWithDouble:d + (([op isEqualToString:@"++"]) ? 1 : -1)];
        return subExpression;
    } else if([op isEqualToString:@"-"]) {
        if (![subExpression.object isMemberOfClass:[JawaNumber class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"- only applies to numbers"];
        double d = ((JawaNumber*)subExpression.object).doubleValue;
        return [JawaObjectRef RefWithNumber:-d in:self];
    } else if([op isEqualToString:@"~"]) {
        if (![subExpression.object isMemberOfClass:[JawaNumber class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"- only applies to numbers"];
        int truncated = [self toInteger:subExpression];
        return [JawaObjectRef RefWithNumber:~truncated in:self];
    } else if([op isEqualToString:@"!"]) {
        if (![subExpression.object isKindOfClass:[NSNumber class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"- only applies to numbers"];
        bool b = ((NSNumber*)subExpression.object).boolValue;
        return [JawaObjectRef RefWithBoolean:!b in:self];
    }
    return nil;
}

-(JawaObjectRef*)evalAndExpression:(NSDictionary*)ast {
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        if (firstOprnd == nil || secondOprnd == nil ||
            ![firstOprnd.object isMemberOfClass:[JawaNumber class]] ||
            ![secondOprnd.object isMemberOfClass:[JawaNumber class]    ])
            [NSException raise:@"JawaScript Runtime Exception" format:@"& applies to only numbers"];
        int l = [self toInteger:firstOprnd];
        int r = [self toInteger:secondOprnd];
        firstOprnd = [JawaObjectRef RefWithNumber:l & r in:self];
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalExclusiveOrExpression:(NSDictionary*)ast {
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        if (firstOprnd == nil || secondOprnd == nil ||
            ![firstOprnd.object isMemberOfClass:[JawaNumber class]] ||
            ![secondOprnd.object isMemberOfClass:[JawaNumber class]])
            [NSException raise:@"JawaScript Runtime Exception" format:@"^ applies to only numbers"];
        int l = [self toInteger:firstOprnd];
        int r = [self toInteger:secondOprnd];
        firstOprnd = [JawaObjectRef RefWithNumber:l ^ r in:self];
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalInclusiveOrExpression:(NSDictionary*)ast {
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        if (firstOprnd == nil || secondOprnd == nil ||
            ![firstOprnd.object isMemberOfClass:[JawaNumber class]] ||
            ![secondOprnd.object isMemberOfClass:[JawaNumber class]    ])
            [NSException raise:@"JawaScript Runtime Exception" format:@"| applies to only numbers"];
        int l = [self toInteger:firstOprnd];
        int r = [self toInteger:secondOprnd];
        firstOprnd = [JawaObjectRef RefWithNumber:l | r in:self];
    }
    return firstOprnd;
}

-(JawaObjectRef*)execContinueStatement:(NSDictionary*)ast {
    [self.currentIterationScope setObject:NULL_CONSTANT forKey:@"continue"];
    return nil;
}

-(JawaObjectRef*)execBreakStatement:(NSDictionary*)ast {
    [self.currentIterationScope setObject:NULL_CONSTANT forKey:@"break"];
    return nil;
}

-(JawaObjectRef*)execWhileStatement:(NSDictionary*)ast {
    NSDictionary* body = [ast objectForKey:PR_body];
    NSDictionary* test = [ast objectForKey:PR_test];
    NSMutableDictionary* scope = [[NSMutableDictionary alloc]init];
    [self.currentActivation addObject:scope];
    NSMutableDictionary* outerIterationScope = self.currentIterationScope;
    self.currentIterationScope = scope;

    while (true) {
        JawaObjectRef* cond = [self evaluate:test];
        if (!(cond != nil && [cond.object isKindOfClass:[NSNumber class]] && ((NSNumber*)cond.object).boolValue))
            break;
        [self evaluate:body];
        if ([[self.currentActivation objectAtIndex:0]objectForKey:@"return"] != nil)
            break;
        if ([self.currentIterationScope objectForKey:@"break"] != nil)
            break;
        if ([self.currentIterationScope objectForKey:@"continue"] != nil)
            [self.currentIterationScope removeObjectForKey:@"continue"];
    }
    
    self.currentIterationScope = outerIterationScope;
    [self.currentActivation removeLastObject];
    return nil;
}

-(JawaObjectRef*)execDoWhileStatement:(NSDictionary*)ast {
    NSDictionary* body = [ast objectForKey:PR_body];
    NSDictionary* test = [ast objectForKey:PR_test];
    NSMutableDictionary* scope = [[NSMutableDictionary alloc]init];
    [self.currentActivation addObject:scope];
    NSMutableDictionary* outerIterationScope = self.currentIterationScope;
    self.currentIterationScope = scope;
    
    JawaObjectRef* cond;
    do {
        [self evaluate:body];
        if ([[self.currentActivation objectAtIndex:0]objectForKey:@"return"] != nil)
            break;
        if ([self.currentIterationScope objectForKey:@"break"] != nil)
            break;
        if ([self.currentIterationScope objectForKey:@"continue"] != nil)
            [self.currentIterationScope removeObjectForKey:@"continue"];
        cond = [self evaluate:test];
    } while (cond != nil && [cond.object isKindOfClass:[NSNumber class]] && ((NSNumber*)cond.object).boolValue);
    self.currentIterationScope = outerIterationScope;
    [self.currentActivation removeLastObject];
    return nil;
}

-(JawaObjectRef*)evalSequenceExpression:(NSDictionary*)ast {
    NSArray* expressions = [ast objectForKey:PR_expressions];
    JawaObjectRef* ret = nil;
    for(NSDictionary *expr in expressions) {
        ret = [self evaluate:expr];
    }
    return ret;
}

-(JawaObjectRef*)evalConditionalExpression:(NSDictionary*)ast {
    JawaObjectRef* test = [self evaluate:[ast objectForKey:PR_condition]];
    if (test == nil)
        return [self evaluate:[ast objectForKey:PR_onFalse]];
    if ([test.object isKindOfClass:[NSNumber class]]) {
        bool b = ((NSNumber*)test.object).boolValue;
        if (b) {
            return [self evaluate:[ast objectForKey:PR_onTrue]];
        } else {
            return [self evaluate:[ast objectForKey:PR_onFalse]];
        }
    } else
        [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented"];
    return nil;
}

-(JawaObjectRef*)evalEqualityExpression:(NSDictionary*)ast {
    //printf("Running EQUALITY_EXPRESSION\n");
    NSArray* ops = [ast objectForKey:PR_ops];
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    if (ops.count < 1 || oprnds.count != ops.count + 1)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid equality expression"];
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        NSString* op = [(NSDictionary*)[ops objectAtIndex:i - 1] objectForKey:@"v"];
        bool inverse = [op characterAtIndex:0] == '!';
        if ([op isEqualToString:@"=="] || [op isEqualToString:@"!="]) {
            bool result;
            if (firstOprnd == nil) firstOprnd = NULL_CONSTANT;
            if (secondOprnd == nil) secondOprnd = NULL_CONSTANT;
            
            if (firstOprnd.object == nil || secondOprnd.object == nil) {
                result = firstOprnd.object == secondOprnd.object;
            } else if ([firstOprnd.object isKindOfClass:[NSString class]] && [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSString* l = (NSString*)firstOprnd.object;
                NSString* r = (NSString*)secondOprnd.object;
                result = [l isEqualToString:r];
            } else if([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                JawaNumber* l = (JawaNumber*)firstOprnd.object;
                JawaNumber* r = (JawaNumber*)secondOprnd.object;
                result = l.doubleValue == r.doubleValue;
            } else if([firstOprnd.object isKindOfClass:[NSNumber class]] && [secondOprnd.object isKindOfClass:[NSNumber class]]) {
                NSNumber* l = (NSNumber*)firstOprnd.object;
                NSNumber* r = (NSNumber*)secondOprnd.object;
                result = l.boolValue == r.boolValue;
            } else if([firstOprnd.object isKindOfClass:[NSNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                bool l = ((NSNumber*)firstOprnd.object).boolValue;
                double r = ((JawaNumber*)secondOprnd.object).doubleValue;
                result = l ? r != 0 : r == 0;
            } else if([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isKindOfClass:[NSNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).doubleValue;
                bool r = ((NSNumber*)secondOprnd.object).boolValue;
                result = r ? l != 0 : l == 0;
            } else if([firstOprnd.object isMemberOfClass:[JawaFunc class]] || [secondOprnd.object isMemberOfClass:[JawaFunc class]] || [firstOprnd.object isMemberOfClass:[JawaArray class]] || [secondOprnd.object isMemberOfClass:[JawaArray class]] || [firstOprnd.object isMemberOfClass:[JawaObject class]] || [secondOprnd.object isMemberOfClass:[JawaObject class]]) {
                
                result = firstOprnd.object == secondOprnd.object;
            } else
                result = false;
            firstOprnd = [JawaObjectRef RefWithBoolean:inverse ? !result : result in:self];
        } else
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented : %@", op];
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalLogicalAndExpression:(NSDictionary*)ast {
    NSArray* subExpressions = [ast objectForKey:PR_subExpressions];
    for (NSDictionary* expr in subExpressions) {
        JawaObjectRef* oprnd = [self evaluate:expr];
        if (oprnd == nil ||
            ([oprnd.object isMemberOfClass:[JawaNumber class]] && ((JawaNumber*)oprnd.object).doubleValue == 0) ||
            ([oprnd.object isKindOfClass:[NSNumber class]] && !((NSNumber*)oprnd.object).boolValue) ||
            ([oprnd.object isKindOfClass:[NSString class]] && ((NSString*)oprnd.object).length == 0))
            return oprnd;
    }
    return [JawaObjectRef RefWithBoolean:true in:self];
}

-(JawaObjectRef*)evalLogicalOrExpression:(NSDictionary*)ast {
    NSArray* subExpressions = [ast objectForKey:PR_subExpressions];
    for (NSDictionary* expr in subExpressions) {
        JawaObjectRef* oprnd = [self evaluate:expr];
        if (oprnd == nil ||
            ([oprnd.object isMemberOfClass:[JawaNumber class]] && ((JawaNumber*)oprnd.object).doubleValue != 0) ||
            ([oprnd.object isKindOfClass:[NSNumber class]] && ((NSNumber*)oprnd.object).boolValue) ||
            ([oprnd.object isKindOfClass:[NSString class]] && ((NSString*)oprnd.object).length > 0) ||
            ([oprnd.object isMemberOfClass:[JawaFunc class]]) ||
            ([oprnd.object isMemberOfClass:[JawaArray class]]) ||
            ([oprnd.object isMemberOfClass:[JawaObject class]]))
            return oprnd;
    }
    return [JawaObjectRef RefWithBoolean:false in:self];
}

-(JawaObjectRef*)evalMultiplicativeExpression:(NSDictionary*)ast {
    //printf("Running MULTIPLICATIVE_EXPRESSION\n");
    NSArray* ops = [ast objectForKey:PR_ops];
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    if (ops.count < 1 || oprnds.count != ops.count + 1)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid multiplicative expression"];
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        NSString* op = [(NSDictionary*)[ops objectAtIndex:i - 1] objectForKey:@"v"];
        if (firstOprnd == nil || secondOprnd == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Multiplicative ops cannot have null operands"];
        if ([op isEqualToString:@"*"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).doubleValue;
                double r = ((JawaNumber*)secondOprnd.object).doubleValue;
                firstOprnd = [JawaObjectRef RefWithNumber:l * r in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for *"];
        } else if ([op isEqualToString:@"/"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).doubleValue;
                double r = ((JawaNumber*)secondOprnd.object).doubleValue;
                if (r == 0)
                    [NSException raise:@"JawaScript Runtime Exception" format:@"Divided by zero"];
                firstOprnd = [JawaObjectRef RefWithNumber:l / r in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for /"];
        } else if ([op isEqualToString:@"%"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).doubleValue;
                double r = ((JawaNumber*)secondOprnd.object).doubleValue;
                if (r == 0)
                    [NSException raise:@"JawaScript Runtime Exception" format:@"Divided by zero"];
                firstOprnd = [JawaObjectRef RefWithNumber:fmod(l,r) in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for /"];
        } else
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented : %@", op];
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalShiftExpression:(NSDictionary*)ast {
    //printf("Running SHIFT_EXPRESSION\n");
    NSArray* ops = [ast objectForKey:PR_ops];
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    if (ops.count < 1 || oprnds.count != ops.count + 1)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid shift expression"];
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        NSString* op = [(NSDictionary*)[ops objectAtIndex:i - 1] objectForKey:@"v"];
        if (firstOprnd == nil || secondOprnd == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Shift ops cannot have null operands"];
        if ([op isEqualToString:@">>"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                long long shifted = ((JawaNumber*)firstOprnd.object).longlongValue;
                int shift = ((JawaNumber*)secondOprnd.object).intValue;
                firstOprnd = [JawaObjectRef RefWithNumber:shifted >> shift in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for shift op"];
        } else if ([op isEqualToString:@"<<"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                long long shifted = ((JawaNumber*)firstOprnd.object).longlongValue;
                int shift = ((JawaNumber*)secondOprnd.object).intValue;
                firstOprnd = [JawaObjectRef RefWithNumber:(int)(shifted << shift) in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for shift op"];
        } else if ([op isEqualToString:@">>>"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                long long shifted = ((JawaNumber*)firstOprnd.object).unsignedLongLongValue;
                int shift = ((JawaNumber*)secondOprnd.object).intValue;
                firstOprnd = [JawaObjectRef RefWithNumber:(((unsigned int)shifted) >> shift) in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for shift op"];
        } else
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented : %@", op];
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalObjectExpression:(NSDictionary*)ast {
    //printf("Running OBJECT_EXPRESSION\n");
    NSArray* properties = [ast objectForKey:PR_properties];
    JawaObject* ret = [[JawaObject alloc] initIn:self];
    for (NSDictionary* prop in properties) {
        NSString* key = [prop objectForKey:PR_key];
        JawaObjectRef* expr = [self evaluate:[prop objectForKey:PR_expr]];
        JawaObjectRef* obj = [JawaObjectRef RefIn:self];
        obj.object = expr != nil ? [expr transfer] : nil;
        [ret setProp:key with:obj];
    }
    
    return [JawaObjectRef RefWithJawaObject:ret];
}

-(JawaObjectRef*)evalPostfixExpression:(NSDictionary*)ast {
    //printf("Running POSTFIX_EXPRESSION\n");
    JawaObjectRef* subExpression = [self evaluate:[ast objectForKey:PR_subExpression]];
    if (subExpression == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Postfix op cannot be applied to null"];
    if (![subExpression.object isMemberOfClass:[JawaNumber class]])
        [NSException raise:@"JawaScript Runtime Exception"
            format:@"++ and -- must be applied to numbers"];
    JawaObjectRef* ret = [JawaObjectRef RefWithNumber:((JawaNumber*)subExpression.object).doubleValue in:self];
    NSString* op = [[[ast objectForKey:PR_op]componentsSeparatedByString:@","]objectAtIndex:1];
    double oldValue = ((JawaNumber*)subExpression.object).doubleValue;
    if ([op isEqualToString:@"++"]) {
        subExpression.object = [JawaNumber numberWithDouble:oldValue + 1];
    } else if ([op isEqualToString:@"--"]) {
        subExpression.object = [JawaNumber numberWithDouble:oldValue - 1];
    } else
        [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid postfix operator"];
    return ret;
}

-(JawaObjectRef*)evalAssignmentExpression:(NSDictionary*)ast {
    //printf("Running ASSIGNMENT_EXPRESSION\n");
    JawaObjectRef* left = [self evaluate:[ast objectForKey:PR_left]];
    NSString* op = [[[ast objectForKey:PR_op]componentsSeparatedByString:@","]objectAtIndex:1];
    JawaObjectRef* right = [self evaluate:[ast objectForKey:PR_right]];
    
    if ([op isEqualToString:@"="]) {
        if (left != nil) {
            left.object = right != nil ? [right transfer] : nil;
            return left;
        } else {
            NSDictionary* leftExpr = [ast objectForKey:PR_left];
            JawaObjectRef* obj = [self evaluate:[leftExpr objectForKey:PR_object]];
            if (obj != nil) {
                int t = ((NSNumber*)[leftExpr objectForKey:@"t"]).intValue;
                if (t == STATIC_MEMBER_EXPRESSION) {
                    if ([obj.object isMemberOfClass:[JawaObject class]]) {
                        NSString* property = [[leftExpr objectForKey:PR_property]objectForKey:PR_id];
                        [(JawaObject*)obj.object setProp:property with:right];
                        return right;
                    }
                } else if (t == COMPUTED_MEMBER_EXPRESSION) {
                    if ([obj.object isMemberOfClass:[JawaObject class]]) {
                        JawaObjectRef* computed = [self evaluate:[leftExpr objectForKey:PR_property]];
                        if (computed == nil)
                            [NSException raise:@"JawaScript Runtime Exception" format:@"Computed member for object is null"];
                        NSString* property = [computed description];
                        [(JawaObject*)obj.object setProp:property with:right];
                        return right;
                    }
                }
            }
        }
        [NSException raise:@"JawaScript Runtime Exception" format:@"Left operand of = is null."];
    } else if ([op isEqualToString:@"+="]) {
        if (left == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Left operand of += is null"];
        if (right == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Right operand of += is null"];
        if ([left.object isKindOfClass:[NSString class]]) {
            NSMutableString* l = [NSMutableString stringWithString:(NSString*)left.object];
            NSString* r = [right description];
            [l appendString:r];
            left.object = l;
        } else if ([left.object isMemberOfClass:[JawaNumber class]] &&
                   [right.object isMemberOfClass:[JawaNumber class]]) {
            double l = ((JawaNumber*)left.object).doubleValue;
            double r = ((JawaNumber*)right.object).doubleValue;
            left.object = [JawaNumber numberWithDouble:l + r];
        } else {
            [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for +="];
        }
    } else if ([op isEqualToString:@"-="] ||
               [op isEqualToString:@"*="] ||
               [op isEqualToString:@"/="] ||
               [op isEqualToString:@"%="]) {
        if (left == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Left operand of assignment is null"];
        if (right == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Right operand of assignment is null"];
        if ([left.object isMemberOfClass:[JawaNumber class]] &&
            [right.object isMemberOfClass:[JawaNumber class]]) {
            double l = ((JawaNumber*)left.object).doubleValue;
            double r = ((JawaNumber*)right.object).doubleValue;
            unsigned char c = [op characterAtIndex:0];
            switch (c) {
                case '-':
                    left.object = [JawaNumber numberWithDouble:l - r];
                    break;
                case '*':
                    left.object = [JawaNumber numberWithDouble:l * r];
                    break;
                case '/':
                    left.object = [JawaNumber numberWithDouble:l / r];
                    break;
                case '%':
                    left.object = [JawaNumber numberWithDouble:fmod(l, r)];
                    break;
            }
        } else {
            [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for assignment"];
        }
    } else if ([op isEqualToString:@"|="] ||
               [op isEqualToString:@"&="]) {
        if (left == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Left operand of |=,&= is null"];
        if (right == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Right operand of |=,&= is null"];
        if ([left.object isMemberOfClass:[JawaNumber class]] &&
            [right.object isMemberOfClass:[JawaNumber class]]) {
            int l = [self toInteger:left];
            int r = [self toInteger:right];
            unsigned char c = [op characterAtIndex:0];
            switch (c) {
                case '&':
                    left.object = [JawaNumber numberWithDouble:l & r];
                    break;
                case '|':
                    left.object = [JawaNumber numberWithDouble:l | r];
                    break;
            }
        } else {
            [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for &=, |="];
        }
    } else {
        [NSException raise:@"JawaScript Runtime Exception" format:@"%@ not implemented yet", op];
    }
    return nil;
}

-(JawaObjectRef*)evalStaticMemberExpression:(NSDictionary*)ast {
    //printf("Running STATIC_MEMBER_EXPRESSION\n");
    JawaObjectRef* object = [self evaluate:[ast objectForKey:PR_object]];
    NSString* property = [[ast objectForKey:PR_property]objectForKey:PR_id];
    if (object == nil || object.object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Null cannot not have properties"];
    if ([object.object isKindOfClass:[JawaObject class]]) {
        JawaObjectRef* prop = [((JawaObject*)object.object) getProp:property];
        if (prop == nil || ![prop.object isMemberOfClass:[JawaFunc class]]) {
            return prop;
        }
        if (((JawaFunc*)prop.object).isPropertyWrapper) {
            return [((JawaFunc*)prop.object) apply:object];
        }
        return prop;
    } else if ([object.object isKindOfClass:[NSString class]]) {
        JawaFunc* func = [stringPrototype objectForKey:property];
        if (func.isPropertyWrapper)
            return [func apply:object];
        return [JawaObjectRef RefWithJawaFunc:func on:object];
    } else
        [NSException raise:@"JawaScript Runtime Exception" format:@"Not implemented yet"];
    return nil;
}

-(JawaObjectRef*)evalComputedMemberExpression:(NSDictionary*)ast {
    //printf("Running COMPUTED_MEMBER_EXPRESSION\n");
    JawaObjectRef* object = [self evaluate:[ast objectForKey:PR_object]];
    JawaObjectRef* property = [self evaluate:[ast objectForKey:PR_property]];
    if (object == nil || object.object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Null cannot have properties\n%@", [ast description]];
    if (property == nil || property.object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Null Property name cannot compute to null"];
    if ([object.object isMemberOfClass:[JawaArray class]]) {
        if ([property.object isMemberOfClass:[JawaNumber class]]) {
            double v = ((JawaNumber*)property.object).doubleValue;
            if (fabs(v-round(v)) < QUANTUM) {
                long index = round(v);
                if (index > INT_MAX || index < 0)
                    return nil;
                JawaObjectRef* r = [((JawaArray*)object.object) at:(int)index];
                return r;
            }
            return nil;
        } else {
            return [((JawaArray*)object.object) getProp:[property description]];
        }
    } else if ([object.object isKindOfClass:[NSString class]]) {
        if ([property.object isMemberOfClass:[JawaNumber class]]) {
            double v = ((JawaNumber*)property.object).doubleValue;
            if (fabs(v-round(v)) < QUANTUM) {
                long index = round(v);
                if (index > INT_MAX || index < 0)
                    return nil;
                NSString* c = [[object description]substringWithRange:NSMakeRange(index, 1)];
                return [JawaObjectRef RefWithString:c in:self];
            }
            return nil;
        } else {
            JawaFunc* f = (JawaFunc*)[stringPrototype objectForKey:[property description]];
            return [JawaObjectRef RefWithJawaFunc:f];
        }
    } else {
        return [((JawaObject*)object.object) getProp:[property description]];
    }
}

-(JawaObjectRef*)evalCallExpression:(NSDictionary*)ast {
    //printf("Running CALL_EXPRESSION\n");
    NSDictionary* function = [ast objectForKey:PR_function];
    JawaObjectRef* object = [self evaluate:function];
    if (object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Undefined function: %@", [function description]];
    if (object.object == nil ||
        ![object.object isMemberOfClass:[JawaFunc class]])
        [NSException raise:@"JawaScript Runtime Exception"
            format:@"Call operator must be applied to functions"];
    JawaFunc *resolvedFunction = (JawaFunc*)object.object;
    NSArray* arguments = [(NSDictionary*)[ast objectForKey:PR_arguments] objectForKey:PR_arguments];
    if (resolvedFunction.params.count < arguments.count)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Arguments more than parameters"];
    
    NSMutableDictionary* scope = [[NSMutableDictionary alloc]init];
    int i = 0;
    for (NSDictionary* argument in arguments) {
        [scope setValue:[self evaluate:argument] forKey:[resolvedFunction.params objectAtIndex:i]];
        i++;
    }
    
    NSMutableArray* activation = [[NSMutableArray alloc]init];
    [activation addObject:scope];
    BOOL oldIsFromCallExpression = self.isFromCallExpression;
    self.isFromCallExpression = true;
    [self.activations addObject:activation];
    self.currentActivation = activation;
    JawaObjectRef* ret;
    if (object.appliedOn == nil)
        ret = [resolvedFunction apply];
    else
        ret = [resolvedFunction apply:object.appliedOn];
    [self.activations removeLastObject];
    self.currentActivation = [self.activations lastObject];
    self.isFromCallExpression = oldIsFromCallExpression;
    return ret;
}

-(JawaObjectRef*)evalArrayExpression:(NSDictionary*)ast {
    //printf("Running ARRAY_EXPRESSION\n");
    NSArray* elements = [ast objectForKey:PR_elements];
    JawaArray* ret = [[JawaArray alloc]initIn:self];
    for (NSDictionary* element in elements) {
        [ret append:[self evaluate:element]];
    }
    return [JawaObjectRef RefWithJawaArray:ret];
}

-(JawaObjectRef*)evalAdditiveExpression:(NSDictionary*)ast {
    //printf("Running ADDITIVE_EXPRESSION\n");
    NSArray* ops = [ast objectForKey:PR_ops];
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    
    if (ops == nil || ops.count < 1 || oprnds == nil || oprnds.count != ops.count + 1)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid relational expression"];
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        NSString* op = [(NSDictionary*)[ops objectAtIndex:i - 1] objectForKey:@"v"];
        if (firstOprnd == nil || firstOprnd.object == nil ||
            secondOprnd == nil || secondOprnd.object == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Additive ops cannot have null operands"];
        if ([op isEqualToString:@"+"]) {
            if ([firstOprnd.object isKindOfClass:[NSString class]] ||
                [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSMutableString* l = [NSMutableString stringWithString:[firstOprnd description]];
                NSString* r = [secondOprnd description];
                [l appendString:r];
                firstOprnd = [JawaObjectRef RefWithString:l in:self];
            } else if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                JawaNumber* l = (JawaNumber*)firstOprnd.object;
                JawaNumber* r = (JawaNumber*)secondOprnd.object;
                double result = l.doubleValue + r.doubleValue;
                if (fabs(round(result) - result) < QUANTUM)
                    result = round(result);
                firstOprnd = [JawaObjectRef RefWithNumber:result in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator +"];
        } else if ([op isEqualToString:@"-"]) {
            if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                JawaNumber* l = (JawaNumber*)firstOprnd.object;
                JawaNumber* r = (JawaNumber*)secondOprnd.object;
                double result = l.doubleValue - r.doubleValue;
                if (fabs(round(result) - result) < QUANTUM)
                    result = round(result);
                    firstOprnd = [JawaObjectRef RefWithNumber:result in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator -"];
        } else {
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not implemented yet: %@", op];
        }
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalRelationalExpression:(NSDictionary*)ast {
    //printf("Running RELATIONAL_EXPRESSION\n");
    NSArray* ops = [ast objectForKey:PR_ops];
    NSArray* oprnds = [ast objectForKey:PR_subExpressions];
    
    if (ops == nil || ops.count < 1 || oprnds == nil || oprnds.count != ops.count + 1)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid relational expression"];
    
    JawaObjectRef* firstOprnd = [self evaluate:[oprnds objectAtIndex:0]];
    for (NSUInteger i = 1 ; i < oprnds.count ; i++) {
        JawaObjectRef* secondOprnd = [self evaluate:[oprnds objectAtIndex:i]];
        NSString* op = [(NSDictionary*)[ops objectAtIndex:i - 1] objectForKey:@"v"];
        if (firstOprnd == nil || firstOprnd.object == nil)
            firstOprnd = [JawaObjectRef RefWithNumber:0 in:self];
        if (secondOprnd == nil || secondOprnd.object == nil)
            secondOprnd = [JawaObjectRef RefWithNumber:0 in:self];
        if ([op isEqualToString:@"<"]) {
            if ([firstOprnd.object isKindOfClass:[NSString class]] &&
                [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSString* l = (NSString*)firstOprnd.object;
                NSString* r = (NSString*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithBoolean:[l compare:r] == NSOrderedAscending in:self];
            } else if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).value;
                double r = ((JawaNumber*)secondOprnd.object).value;
                firstOprnd = [JawaObjectRef RefWithBoolean:l < r in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator <"];
        } else if ([op isEqualToString:@">"]) {
            if ([firstOprnd.object isKindOfClass:[NSString class]] &&
                [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSString* l = (NSString*)firstOprnd.object;
                NSString* r = (NSString*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithBoolean:[l compare:r] == NSOrderedDescending in:self];
            } else if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).value;
                double r = ((JawaNumber*)secondOprnd.object).value;
                firstOprnd = [JawaObjectRef RefWithBoolean:l > r in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator >"];
        } else if ([op isEqualToString:@"<="]) {
            if ([firstOprnd.object isKindOfClass:[NSString class]] &&
                [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSString* l = (NSString*)firstOprnd.object;
                NSString* r = (NSString*)secondOprnd.object;
                NSComparisonResult result = [l compare:r];
                firstOprnd = [JawaObjectRef RefWithBoolean:
                              result == NSOrderedAscending ||
                              result == NSOrderedSame
                                in:self];
            } else if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).value;
                double r = ((JawaNumber*)secondOprnd.object).value;
                firstOprnd = [JawaObjectRef RefWithBoolean:l <= r
                                in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator <="];
        } else if ([op isEqualToString:@">="]) {
            if ([firstOprnd.object isKindOfClass:[NSString class]] &&
                [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSString* l = (NSString*)firstOprnd.object;
                NSString* r = (NSString*)secondOprnd.object;
                NSComparisonResult result = [l compare:r];
                firstOprnd = [JawaObjectRef RefWithBoolean:
                              result == NSOrderedDescending ||
                              result == NSOrderedSame
                                in:self];
            } else if ([firstOprnd.object isMemberOfClass:[JawaNumber class]] && [secondOprnd.object isMemberOfClass:[JawaNumber class]]) {
                double l = ((JawaNumber*)firstOprnd.object).value;
                double r = ((JawaNumber*)secondOprnd.object).value;
                firstOprnd = [JawaObjectRef RefWithBoolean:l >= r
                                                        in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator ="];
        } else {
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not implemented yet: %@", op];
        }
    }
    return firstOprnd;
}

-(void)declare:(NSString*)name with:(JawaObjectRef*)value {
    NSMutableDictionary* currentScope = [self.currentActivation lastObject];
    if ([currentScope objectForKey:name] != nil)
        [NSException raise:@"JawaScript Runtime Error" format:@"Variable redeclaration (%@) in the current scope.", name];
    JawaObjectRef *obj = [JawaObjectRef RefIn:self];
    if (value != nil)
        obj.object = [value transfer];
    [currentScope setValue:obj forKey:name];
}

-(JawaObjectRef*)declareFunction:(NSDictionary*)ast {
    //printf("Running FUNCTION_DECLARATION\n");
    NSString *name = (NSString*)[ast objectForKey:PR_id];
    NSArray *params = (NSArray*)[ast objectForKey:PR_params];
    NSMutableArray *paramStrs = [[NSMutableArray alloc]init];
    for (NSString* paramStr in params) {
        [paramStrs addObject:paramStr];
    }
    NSDictionary* body = (NSDictionary*)[ast objectForKey:PR_body];
    JawaFunc* func = [[JawaFunc alloc]initWithName:name in:self taking:paramStrs isBuiltin:false isPropertyWrapper:false and:body];
    [self declare:name with:[JawaObjectRef RefWithJawaFunc:func]];
    return nil;
}

-(JawaObjectRef*)declareVar:(NSDictionary*)ast {
    //printf("Running VARIABLE_DECLARATION\n");
    NSString* name = (NSString*)[ast objectForKey:PR_varName];
    NSDictionary* init = (NSDictionary*)[ast objectForKey:PR_initialization];
    if (init == nil)
        [self declare:name with:nil];
    else {
        JawaObjectRef* value = [self evaluate:init];
        [self declare:name with:value];
    }
    return nil;
}

-(JawaObjectRef*)execVarStatement:(NSDictionary*)ast {
    //printf("Running VAR_STATEMENT\n");
    NSArray* declarations = (NSArray*)[ast objectForKey:PR_declarations];
    for (NSDictionary* declaration in declarations) {
        [self evaluate:declaration];
    }
    return nil;
}

-(JawaObjectRef*)execIfStatement:(NSDictionary*)ast {
    //printf("Running IF_STATEMENT\n");
    JawaObjectRef* test = [self evaluate:[ast objectForKey:PR_test]];
    if (test != nil && [test.object isKindOfClass:[NSNumber class]]) {
        if (((NSNumber*)test.object).boolValue)
            [self evaluate:[ast objectForKey:PR_onTrue]];
        else if ([ast objectForKey:PR_onFalse] != nil)
            [self evaluate:[ast objectForKey:PR_onFalse]];
    } else
        [NSException raise:@"JawaScript Runtime Exception" format:@"Not yet implemented"];
    return nil;
}

-(JawaObjectRef*)execForStatement:(NSDictionary*)ast {
    //printf("Running FOR_STATEMENT\n");
    NSDictionary* body = [ast objectForKey:PR_body];
    NSMutableDictionary* scope = [[NSMutableDictionary alloc]init];
    [self.currentActivation addObject:scope];
    NSMutableDictionary* outerIterationScope = self.currentIterationScope;
    self.currentIterationScope = scope;
    
    if ([ast objectForKey:PR_iterator] == nil) {
        NSDictionary* test = [ast objectForKey:PR_test];
        NSDictionary* update = [ast objectForKey:PR_update];
        NSObject* init = [ast objectForKey:PR_init];
        
        if (init != nil) {
            if ([init isKindOfClass:[NSArray class]]) {
                for (NSDictionary* i in (NSArray*)init)
                    [self evaluate:i];
            } else if ([init isKindOfClass:[NSDictionary class]]) {
                [self evaluate:(NSDictionary*)init];
            }
        }
        
        JawaObjectRef* _T = [JawaObjectRef RefWithBoolean:true in:self];
        JawaObjectRef* cond = test != nil ? [self evaluate:test] : _T;
        
        while (cond != nil && ((NSNumber*)cond.object).boolValue) {
            [self evaluate:body];
            if ([((NSDictionary*)[self.currentActivation objectAtIndex:0]) objectForKey:@"return"] != nil)
                break;
            if ([self.currentIterationScope objectForKey:@"break"] != nil)
                break;
            if ([self.currentIterationScope objectForKey:@"continue"] != nil)
                [self.currentIterationScope removeObjectForKey:@"continue"];
            if (update != nil)
                [self evaluate:update];
            cond = test != nil ? [self evaluate:test] : _T;
        }
    } else {
        NSDictionary* iteratorDeclaration = [ast objectForKey:PR_iterator];
        NSString* iterator = [iteratorDeclaration objectForKey:PR_varName];
        JawaObjectRef* iterable = [self evaluate:[iteratorDeclaration objectForKey:PR_iterable]];
        
        if (iterable == nil)
            [NSException raise:@"JawaScript Runtime Exception" format:@"Null is not iterable"];
        if ([iterable.object isKindOfClass:[NSString class]]) {
            NSUInteger len = ((NSString*)iterable.object).length;
            for (NSUInteger i = 0 ; i < len ; i++) {
                [scope setObject:[JawaObjectRef RefWithNumber:i in:self] forKey:iterator];
                [self evaluate:body];
                if ([((NSDictionary*)[self.currentActivation objectAtIndex:0]) objectForKey:@"return"] != nil)
                    break;
                if ([self.currentIterationScope objectForKey:@"break"] != nil)
                    break;
                if ([self.currentIterationScope objectForKey:@"continue"] != nil)
                    [self.currentIterationScope removeObjectForKey:@"continue"];
            }
        } else if ([iterable.object isMemberOfClass:[JawaArray class]]) {
            NSUInteger len = ((JawaArray*)iterable.object).elements.count;
            for (NSUInteger i = 0 ; i < len ; i++) {
                [scope setObject:[JawaObjectRef RefWithNumber:i in:self] forKey:iterator];
                [self evaluate:body];
                if ([((NSDictionary*)[self.currentActivation objectAtIndex:0]) objectForKey:@"return"] != nil)
                    break;
                if ([self.currentIterationScope objectForKey:@"break"] != nil)
                    break;
                if ([self.currentIterationScope objectForKey:@"continue"] != nil)
                    [self.currentIterationScope removeObjectForKey:@"continue"];
            }
        } else if ([iterable.object isMemberOfClass:[JawaObject class]]) {
            JawaObject* obj = (JawaObject*)iterable.object;
            for (NSString* key in obj.properties) {
                [scope setObject:[JawaObjectRef RefWithString:key in:self] forKey:iterator];
                [self evaluate:body];
                if ([((NSDictionary*)[self.currentActivation objectAtIndex:0]) objectForKey:@"return"] != nil)
                    break;
                if ([self.currentIterationScope objectForKey:@"break"] != nil)
                    break;
                if ([self.currentIterationScope objectForKey:@"continue"] != nil)
                    [self.currentIterationScope removeObjectForKey:@"continue"];
            }
        } else
            [NSException raise:@"JawaScript Runtime Exception" format:@"Non-iterable object in for-in statement."];
    }
    self.currentIterationScope = outerIterationScope;
    [self.currentActivation removeLastObject];
    return nil;
}

-(JawaObjectRef*)execReturnStatement:(NSDictionary*)ast {
    //printf("Running RETURN_STATEMENT\n");
    if ([ast objectForKey:PR_argument]) {
        JawaObjectRef* retValue = [self evaluate:[ast objectForKey:PR_argument]];
        [self placeReturn:retValue];
    } else
        [self placeReturn:[JawaObjectRef RefIn:self]];
    return nil;
}

-(JawaObjectRef*)evalBlockStatement:(NSDictionary*)ast {
    //printf("Running BLOCK_STATEMENT\n");
    BOOL oldIsFromCallExpression = self.isFromCallExpression;
    if (!self.isFromCallExpression) {
        // Create a new scope
        [self.currentActivation addObject:[[NSMutableDictionary alloc]init]];
    }
    self.isFromCallExpression = false;
    NSArray* statements = [ast objectForKey:PR_statements];
    for (NSDictionary* statement in statements) {
        [self evaluate:statement];
        if ([[self.currentActivation objectAtIndex:0] objectForKey:@"return"] != nil) {
            break;
        }
        if (self.currentIterationScope != nil &&
            ([self.currentIterationScope objectForKey:@"break"] != nil ||
             [self.currentIterationScope objectForKey:@"continue"] != nil))
            break;
    }
    self.isFromCallExpression = oldIsFromCallExpression;
    if (!self.isFromCallExpression)
        [self.currentActivation removeLastObject];
    return nil;
}

-(JawaObjectRef*)evalScriptBody:(NSDictionary*)ast {
    //printf("Running SCRIPT_BODY\n");
    NSArray* statements = (NSArray*)[ast objectForKey:PR_statements];
    for (NSDictionary* statement in statements) {
        [self evaluate:statement];
    }
    return nil;
}

-(JawaObjectRef*)resolveIdentifier:(NSDictionary*)ast {
    NSString* name = [ast objectForKey:PR_id];
    for (int i = (int)(self.currentActivation.count)-1 ; i >= 0 ; i--) {
        NSDictionary* scope = [self.currentActivation objectAtIndex:i];
        JawaObjectRef* ret = [scope objectForKey:name];
        if (ret != nil)
            return ret;
    }
    JawaObjectRef* ret = [self.global objectForKey:name];
    if (ret != nil)
        return ret;
    [NSException raise:@"JawaScript Runtime Exception" format:@"Unresolvable identifier: %@", name];
    return nil;
}

-(JawaObjectRef*)evalLiteral:(NSDictionary*)ast {
    //printf("Running LITERAL\n");
    NSString* literal = [ast objectForKey:PR_literal];
    NSUInteger sp = [literal rangeOfString:@","].location;
    NSString* type = [literal substringWithRange:NSMakeRange(0, sp)];
    NSString* content = [literal substringFromIndex:sp + 1];
    if ([type isEqualToString:@"STRING_LITERAL"])
        return [JawaObjectRef RefWithString:content in:self];
    else if ([type isEqualToString:@"NUMERIC_LITERAL"])
        return [JawaObjectRef RefWithNumber:content.doubleValue in:self];
    else if ([type isEqualToString:@"BOOLEAN"])
        return [JawaObjectRef RefWithBoolean:content.boolValue in:self];
    else if ([type isEqualToString:@"NULL"])
        return [JawaObjectRef RefIn:self];
    else
        [NSException raise:@"Unknown literal type" format:@"%@", literal];
    return nil;
}

-(JawaObjectRef*)evaluate:(NSDictionary *)tree {
    if (tree == nil)
        return nil;
    int astType = ((NSNumber*)[tree objectForKey:@"t"]).intValue;
    switch (astType) {
        case SCRIPT_BODY:
            return [self evalScriptBody:tree];
        case FUNCTION_DECLARATION:
            return [self declareFunction:tree];
        case BLOCK_STATEMENT:
            return [self evalBlockStatement:tree];
        case EMPTY_STATEMENT:
            return nil;
        case SEQUENCE_EXPRESSION:
            return [self evalSequenceExpression:tree];
        case ASSIGNMENT_EXPRESSION:
            return [self evalAssignmentExpression:tree];
        case CONDITIONAL_EXPRESSION:
            return [self evalConditionalExpression:tree];
        case LOGICAL_OR_EXPRESSION:
            return [self evalLogicalOrExpression:tree];
        case LOGICAL_AND_EXPRESSION:
            return [self evalLogicalAndExpression:tree];
        case INCLUSIVE_OR_EXPRESSION:
            return [self evalInclusiveOrExpression:tree];
        case EXCLUSIVE_OR_EXPRESSION:
            return [self evalExclusiveOrExpression:tree];
        case AND_EXPRESSION:
            return [self evalAndExpression:tree];
        case EQUALITY_EXPRESSION:
            return [self evalEqualityExpression:tree];
        case RELATIONAL_EXPRESSION:
            return [self evalRelationalExpression:tree];
        case IN_EXPRESSION:
            return [self evalInExpression:tree];
        case SHIFT_EXPRESSION:
            return [self evalShiftExpression:tree];
        case ADDITIVE_EXPRESSION:
            return [self evalAdditiveExpression:tree];
        case MULTIPLICATIVE_EXPRESSION:
            return [self evalMultiplicativeExpression:tree];
        case UNARY_EXPRESSION:
            return [self evalUnaryExpression:tree];
        case POSTFIX_EXPRESSION:
            return [self evalPostfixExpression:tree];
        case STATIC_MEMBER_EXPRESSION:
            return [self evalStaticMemberExpression:tree];
        case CALL_EXPRESSION:
            return [self evalCallExpression:tree];
        case COMPUTED_MEMBER_EXPRESSION:
            return [self evalComputedMemberExpression:tree];
        case ARRAY_EXPRESSION:
            return [self evalArrayExpression:tree];
        case OBJECT_EXPRESSION:
            return [self evalObjectExpression:tree];
        case IDENTIFIER:
            return [self resolveIdentifier:tree];
        case IF_STATEMENT:
            return [self execIfStatement:tree];
        case RETURN_STATEMENT:
            return [self execReturnStatement:tree];
        case VAR_STATEMENT:
            return [self execVarStatement:tree];
        case WHILE_STATEMENT:
            return [self execWhileStatement:tree];
        case CONTINUE_STATEMENT:
            return [self execContinueStatement:tree];
        case BREAK_STATEMENT:
            return [self execBreakStatement:tree];
        case DO_WHILE_STATEMENT:
            return [self execDoWhileStatement:tree];
        case FOR_STATEMENT:
            return [self execForStatement:tree];
        case VARIABLE_DECLARATION:
            return [self declareVar:tree];
        case LITERAL:
            return [self evalLiteral:tree];
        default:
            break;
    }
    [NSException raise:@"Not implemented" format:@"%d not implemented", astType];
    return nil;
}

-(void)placeReturn:(JawaObjectRef*)retValue {
    NSMutableDictionary* topScope = [self.currentActivation objectAtIndex:0];
    [topScope setObject:retValue forKey:@"return"];
}

-(void)registerBuiltinInPrototype:(NSDictionary*)prototype funcName:(NSString*)name params:(NSArray*)params isProperty:(BOOL)isProperty {
    JawaFunc* f = [[JawaFunc alloc]initWithName:name in:self taking:params isBuiltin:true isPropertyWrapper:isProperty and:nil];
    f.switchId = prototype.count;
    [prototype setValue:f forKey:name];
}

-(void)registerBuilitinFunc:(NSDictionary*)prototype funcName:(NSString*)name params:(NSArray*)params {
    [self registerBuiltinInPrototype:prototype funcName:name params:params isProperty:false];
}

-(void)registerBuilitinProp:(NSDictionary*)prototype propName:(NSString*)name {
    [self registerBuiltinInPrototype:prototype funcName:name params:nil isProperty:true];
}

@end


