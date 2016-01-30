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
#import "utility.h"

@implementation JawaExecutor

-(id)init {
    self = [super init];
    if (self) {
        _global = [[NSMutableDictionary alloc]init];
        _activations = [[NSMutableArray alloc]init];
        _currentActivation = [[NSMutableArray alloc]init];
        [_currentActivation addObject:_global];
        _currentIterationScope = nil;
        _isFromCallExpression = false;
        // TODO: Add externalCallback
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

-(JawaObjectRef*)evalArrayExpression:(NSDictionary*)ast {
    NSArray* elements = [ast objectForKey:PR_elements];
    JawaArray* ret = [[JawaArray alloc]initIn:self];
    for (NSDictionary* element in elements) {
        [ret append:[self evaluate:element]];
    }
    return [JawaObjectRef RefWithJawaArray:ret];
}

-(void)declare:(NSString*)name with:(JawaObjectRef*)value {
    NSDictionary* currentScope = [self.currentActivation lastObject];
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
    JawaFunc* func = [[JawaFunc alloc]initWithName:name in:self taking:paramStrs is:false is:false and:body];
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

-(JawaObjectRef*)evalBlockStatement:(NSDictionary*)ast {
    printf("Running BLOCK_STATEMENT\n");
    BOOL oldIsFromCallExpression = self.isFromCallExpression;
    if (!self.isFromCallExpression) {
        // Create a new scope
        [self.currentActivation addObject:[[NSDictionary alloc]init]];
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

-(JawaObjectRef*)evalLiteral:(NSDictionary*)ast {
    printf("Running LITERAL\n");
    NSString* literal = [ast objectForKey:PR_literal];
    NSUInteger sp = [literal rangeOfString:@","].location;
    NSString* type = [literal substringWithRange:NSMakeRange(0, sp)];
    NSString* content = [literal substringFromIndex:sp + 1];
    if ([type isEqualToString:@"STRING_LITERAL"])
        return [JawaObjectRef RefWithString:content in:self];
    else if ([type isEqualToString:@"NUMERIC_LITERAL"])
        return [JawaObjectRef RefWithNumber:[content doubleValue] in:self];
    else if ([type isEqualToString:@"BOOLEAN"])
        return [JawaObjectRef RefWithBoolean:[content boolValue] in:self];
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
            break;
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
            break;
        case IN_EXPRESSION:
            break;
        case SHIFT_EXPRESSION:
            break;
        case ADDITIVE_EXPRESSION:
            break;
        case MULTIPLICATIVE_EXPRESSION:
            break;
        case UNARY_EXPRESSION:
            break;
        case POSTFIX_EXPRESSION:
            break;
        case STATIC_MEMBER_EXPRESSION:
            break;
        case CALL_EXPRESSION:
            break;
        case COMPUTED_MEMBER_EXPRESSION:
            break;
        case ARRAY_EXPRESSION:
            return [self evalArrayExpression:tree];
        case OBJECT_EXPRESSION:
            break;
        case IDENTIFIER:
            break;
        case IF_STATEMENT:
            break;
        case RETURN_STATEMENT:
            break;
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
            break;
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



@end


