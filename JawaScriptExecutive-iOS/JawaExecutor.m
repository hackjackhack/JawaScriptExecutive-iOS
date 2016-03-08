//
//  Executor.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/15.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JawaExecutor.h"
#import "JawaArray.h"
#import "JawaFunc.h"
#import "JawaString.h"
#import "utility.h"

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
        // TODO: Add externalCallback
        
        jawaObjectPool = [[NSMutableArray alloc]init];
        
        arrayPrototype = [[NSMutableDictionary alloc]init];
        stringPrototype = [[NSMutableDictionary alloc]init];
        objectPrototype = [[NSMutableDictionary alloc]init];
        [self registerBuilitinProp:arrayPrototype propName:@"length"];
    }
    return self;
}

-(JawaObjectRef*)dispatchBuiltin:(NSString *)funcName {
    return nil;
}

-(void)execute:(NSDictionary*)ast {
    [self evaluate:ast];
}

-(NSMutableDictionary*)invoke:(NSString *)funcName with:(NSMutableDictionary*)asInput {
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
    printf("%s\n", [[[ret.object class]description]cStringUsingEncoding:NSUTF8StringEncoding]);
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
    } else if ([ret.object isMemberOfClass:[NSMutableString class]]) {
        [retJSON setObject:@"string" forKey:@"retType"];
        [retJSON setObject:[ret.object copy] forKey:@"retValue"];
    } else if ([ret.object isMemberOfClass:[NSDecimalNumber class]]) {
        [retJSON setObject:@"number" forKey:@"retType"];
        [retJSON setObject:[ret.object copy] forKey:@"retValue"];
    } else if ([ret.object isMemberOfClass:[NSNumber class]]) {
        [retJSON setObject:@"boolean" forKey:@"retType"];
        NSNumber *n = (NSNumber*)ret.object;
        [retJSON
         setObject:n.boolValue ? @"true" : @"false"
         forKey:@"retValue"];
    }
    
    return retJSON;
}

-(JawaObjectRef*)evalAssignmentExpression:(NSDictionary*)ast {
    printf("Running ASSIGNMENT_EXPRESSION");
    JawaObjectRef* left = [self evaluate:[ast objectForKey:PR_left]];
    NSString* op = [[[ast  objectForKey:PR_op]componentsSeparatedByString:@","]objectAtIndex:1];
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
        if ([left.object isMemberOfClass:[NSMutableString class]]) {
            NSMutableString* l = [NSMutableString stringWithString:[left.object description]];
            NSString* r = [right description];
            [l appendString:r];
            left.object = [JawaObjectRef RefWithString:l in:self];
        } else if ([left.object isMemberOfClass:[NSDecimalNumber class]] &&
                   [right.object isMemberOfClass:[NSDecimalNumber class]]) {
            double l = ((NSDecimalNumber*)left.object).doubleValue;
            double r = ((NSDecimalNumber*)right.object).doubleValue;
            left.object = [JawaObjectRef RefWithNumber:l + r in:self];
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
        if ([left.object isMemberOfClass:[NSDecimalNumber class]] &&
            [right.object isMemberOfClass:[NSDecimalNumber class]]) {
            double l = ((NSDecimalNumber*)left.object).doubleValue;
            double r = ((NSDecimalNumber*)right.object).doubleValue;
            unsigned char c = [op characterAtIndex:0];
            switch (c) {
                case '-':
                    left.object = [JawaObjectRef RefWithNumber:l - r in:self];
                    break;
                case '*':
                    left.object = [JawaObjectRef RefWithNumber:l * r in:self];
                    break;
                case '/':
                    left.object = [JawaObjectRef RefWithNumber:l / r in:self];
                    break;
                case '%':
                    left.object = [JawaObjectRef RefWithNumber:(long)l % (long)r in:self];
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
        if ([left.object isMemberOfClass:[NSDecimalNumber class]] &&
            [right.object isMemberOfClass:[NSDecimalNumber class]]) {
            long long l = ((NSDecimalNumber*)left.object).longLongValue;
            long long r = ((NSDecimalNumber*)right.object).longLongValue;
            unsigned char c = [op characterAtIndex:0];
            switch (c) {
                case '&':
                    left.object = [JawaObjectRef RefWithNumber:l & r in:self];
                    break;
                case '|':
                    left.object = [JawaObjectRef RefWithNumber:l | r in:self];
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
    printf("Running STATIC_MEMBER_EXPRESSION\n");
    JawaObjectRef* object = [self evaluate:[ast objectForKey:PR_object]];
    NSString* property = [[ast objectForKey:PR_property]objectForKey:PR_id];
    if (object == nil || object.object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Null cannot not have properties"];
    if ([object.object isKindOfClass:[JawaObject class]]) {
        printf("%s\n", [property cStringUsingEncoding:NSUTF8StringEncoding]);
        JawaObjectRef* prop = [((JawaObject*)object.object) getProp:property];
        if (prop == nil || ![prop.object isMemberOfClass:[JawaFunc class]]) {
            return prop;
        }
        if (((JawaFunc*)prop.object).isPropertyWrapper) {
            return [((JawaFunc*)prop.object) apply:object];
        }
        return prop;
    } else if ([object.object isMemberOfClass:[NSMutableString class]]) {
        JawaFunc* func = [stringPrototype objectForKey:property];
        if (func.isPropertyWrapper)
            return [func apply:object];
        return [JawaObjectRef RefWithJawaFunc:func on:object];
    } else
        [NSException raise:@"JawaScript Runtime Exception" format:@"Not implemented yet"];
    return nil;
}

-(JawaObjectRef*)evalComputedMemberExpression:(NSDictionary*)ast {
    printf("Running COMPUTED_MEMBER_EXPRESSION\n");
    JawaObjectRef* object = [self evaluate:[ast objectForKey:PR_object]];
    JawaObjectRef* property = [self evaluate:[ast objectForKey:PR_property]];
    if (object == nil || object.object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Null cannot have properties"];
    if (property == nil || property.object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Null Property name cannot compute to null"];
    if ([object.object isMemberOfClass:[JawaArray class]]) {
        if ([property.object isMemberOfClass:[NSDecimalNumber class]]) {
            double v = ((NSDecimalNumber*)property.object).doubleValue;
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
    } else if ([object.object isMemberOfClass:[NSMutableString class]]) {
        if ([property.object isMemberOfClass:[NSDecimalNumber class]]) {
            double v = ((NSDecimalNumber*)property.object).doubleValue;
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
    printf("Running CALL_EXPRESSION\n");
    NSDictionary* function = [ast objectForKey:PR_function];
    JawaObjectRef* object = [self evaluate:function];
    if (object == nil)
        [NSException raise:@"JawaScript Runtime Exception" format:@"Undefined function: %@", [ast description]];
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
    printf("Running ARRAY_EXPRESSION\n");
    NSArray* elements = [ast objectForKey:PR_elements];
    JawaArray* ret = [[JawaArray alloc]initIn:self];
    for (NSDictionary* element in elements) {
        [ret append:[self evaluate:element]];
    }
    return [JawaObjectRef RefWithJawaArray:ret];
}

-(JawaObjectRef*)evalAdditiveExpression:(NSDictionary*)ast {
    printf("Running ADDITIVE_EXPRESSION\n");
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
                NSMutableString* l = [NSMutableString stringWithString:(NSString*)firstOprnd.object];
                NSString* r = (NSString*)secondOprnd.object;
                [l appendString:r];
                firstOprnd = [JawaObjectRef RefWithString:l in:self];
            } else if ([firstOprnd.object isMemberOfClass:[NSDecimalNumber class]] && [secondOprnd.object isMemberOfClass:[NSDecimalNumber class]]) {
                NSDecimalNumber* l = (NSDecimalNumber*)firstOprnd.object;
                NSDecimalNumber* r = (NSDecimalNumber*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithNumber:l.doubleValue + r.doubleValue in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator +"];
        } else if ([op isEqualToString:@"-"]) {
            if ([firstOprnd.object isMemberOfClass:[NSDecimalNumber class]] && [secondOprnd.object isMemberOfClass:[NSDecimalNumber class]]) {
                NSDecimalNumber* l = (NSDecimalNumber*)firstOprnd.object;
                NSDecimalNumber* r = (NSDecimalNumber*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithNumber:l.doubleValue - r.doubleValue in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator -"];
        } else {
            [NSException raise:@"JawaScript Runtime Exception" format:@"Not implemented yet: %@", op];
        }
    }
    return firstOprnd;
}

-(JawaObjectRef*)evalRelationalExpression:(NSDictionary*)ast {
    printf("Running RELATIONAL_EXPRESSION\n");
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
            } else if ([firstOprnd.object isMemberOfClass:[NSDecimalNumber class]] && [secondOprnd.object isMemberOfClass:[NSDecimalNumber class]]) {
                NSDecimalNumber* l = (NSDecimalNumber*)firstOprnd.object;
                NSDecimalNumber* r = (NSDecimalNumber*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithBoolean:[l compare:r] == NSOrderedAscending in:self];
            } else
                [NSException raise:@"JawaScript Runtime Exception" format:@"Invalid type for operator <"];
        } else if ([op isEqualToString:@">"]) {
            if ([firstOprnd.object isKindOfClass:[NSString class]] &&
                [secondOprnd.object isKindOfClass:[NSString class]]) {
                NSString* l = (NSString*)firstOprnd.object;
                NSString* r = (NSString*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithBoolean:[l compare:r] == NSOrderedDescending in:self];
            } else if ([firstOprnd.object isMemberOfClass:[NSDecimalNumber class]] && [secondOprnd.object isMemberOfClass:[NSDecimalNumber class]]) {
                NSDecimalNumber* l = (NSDecimalNumber*)firstOprnd.object;
                NSDecimalNumber* r = (NSDecimalNumber*)secondOprnd.object;
                firstOprnd = [JawaObjectRef RefWithBoolean:[l compare:r] == NSOrderedDescending in:self];
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
            } else if ([firstOprnd.object isMemberOfClass:[NSDecimalNumber class]] && [secondOprnd.object isMemberOfClass:[NSDecimalNumber class]]) {
                NSDecimalNumber* l = (NSDecimalNumber*)firstOprnd.object;
                NSDecimalNumber* r = (NSDecimalNumber*)secondOprnd.object;
                NSComparisonResult result = [l compare:r];
                firstOprnd = [JawaObjectRef RefWithBoolean:
                              result == NSOrderedAscending ||
                              result == NSOrderedSame
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
            } else if ([firstOprnd.object isMemberOfClass:[NSDecimalNumber class]] && [secondOprnd.object isMemberOfClass:[NSDecimalNumber class]]) {
                NSDecimalNumber* l = (NSDecimalNumber*)firstOprnd.object;
                NSDecimalNumber* r = (NSDecimalNumber*)secondOprnd.object;
                NSComparisonResult result = [l compare:r];
                firstOprnd = [JawaObjectRef RefWithBoolean:
                              result == NSOrderedDescending ||
                              result == NSOrderedSame
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
    if (value == nil)
        [currentScope setValue:[JawaObjectRef RefIn:self] forKey:name];
    else
        [currentScope setValue:value forKey:name];
}

-(JawaObjectRef*)declareFunction:(NSDictionary*)ast {
    printf("Running FUNCTION_DECLARATION\n");
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
    printf("Running VARIABLE_DECLARATION\n");
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
    printf("Running VAR_STATEMENT\n");
    NSArray* declarations = (NSArray*)[ast objectForKey:PR_declarations];
    for (NSDictionary* declaration in declarations) {
        [self evaluate:declaration];
    }
    return nil;
}

-(JawaObjectRef*)execIfStatement:(NSDictionary*)ast {
    printf("Running IF_STATEMENT\n");
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
    printf("Running FOR_STATEMENT\n");
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
        if ([iterable.object isMemberOfClass:[NSMutableString class]]) {
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
    printf("Running RETURN_STATEMENT\n");
    if ([ast objectForKey:PR_argument]) {
        JawaObjectRef* retValue = [self evaluate:[ast objectForKey:PR_argument]];
        [self placeReturn:retValue];
    } else
        [self placeReturn:nil];
    return nil;
}

-(JawaObjectRef*)evalBlockStatement:(NSDictionary*)ast {
    printf("Running BLOCK_STATEMENT\n");
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
    printf("Running SCRIPT_BODY\n");
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
    printf("Running LITERAL\n");
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
            break;
        case SEQUENCE_EXPRESSION:
            break;
        case ASSIGNMENT_EXPRESSION:
            return [self evalAssignmentExpression:tree];
        case CONDITIONAL_EXPRESSION:
            break;
        case LOGICAL_OR_EXPRESSION:
            break;
        case LOGICAL_AND_EXPRESSION:
            break;
        case INCLUSIVE_OR_EXPRESSION:
            break;
        case EXCLUSIVE_OR_EXPRESSION:
            break;
        case AND_EXPRESSION:
            break;
        case EQUALITY_EXPRESSION:
            break;
        case RELATIONAL_EXPRESSION:
            return [self evalRelationalExpression:tree];
        case IN_EXPRESSION:
            break;
        case SHIFT_EXPRESSION:
            break;
        case ADDITIVE_EXPRESSION:
            return [self evalAdditiveExpression:tree];
        case MULTIPLICATIVE_EXPRESSION:
            break;
        case UNARY_EXPRESSION:
            break;
        case POSTFIX_EXPRESSION:
            break;
        case STATIC_MEMBER_EXPRESSION:
            return [self evalStaticMemberExpression:tree];
        case CALL_EXPRESSION:
            return [self evalCallExpression:tree];
        case COMPUTED_MEMBER_EXPRESSION:
            return [self evalComputedMemberExpression:tree];
        case ARRAY_EXPRESSION:
            return [self evalArrayExpression:tree];
        case OBJECT_EXPRESSION:
            break;
        case IDENTIFIER:
            return [self resolveIdentifier:tree];
        case IF_STATEMENT:
            return [self execIfStatement:tree];
        case RETURN_STATEMENT:
            return [self execReturnStatement:tree];
        case VAR_STATEMENT:
            return [self execVarStatement:tree];
        case WHILE_STATEMENT:
            break;
        case CONTINUE_STATEMENT:
            break;
        case BREAK_STATEMENT:
            break;
        case DO_WHILE_STATEMENT:
            break;
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


