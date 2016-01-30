//
//  Executor.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/20.
//
//

#ifndef JawaExecutor_h
#define JawaExecutor_h

@class JawaObjectRef;

@interface JawaExecutor : NSObject
@property (weak) NSMutableDictionary* env;
@property NSMutableDictionary* global;
@property NSMutableArray* activations;
@property NSMutableArray* currentActivation;
@property NSMutableDictionary* currentIterationScope;
@property BOOL isFromCallExpression;

-(id)init;
-(JawaObjectRef*)evaluate:(NSDictionary*)tree;
-(void)execute:(NSDictionary*)ast;
-(NSMutableDictionary*) invoke:(NSString*)funcName with:(NSMutableDictionary*)asInput;
-(JawaObjectRef*)dispatchBuiltin:(NSString*)funcName;
@end

#define QUANTUM 0.0000000000000001

typedef NS_ENUM(NSInteger, ASTType) {
    SCRIPT_BODY = 0,
    FUNCTION_DECLARATION,
    BLOCK_STATEMENT,
    EMPTY_STATEMENT,
    SEQUENCE_EXPRESSION,
    
    ASSIGNMENT_EXPRESSION,
    CONDITIONAL_EXPRESSION,
    LOGICAL_OR_EXPRESSION,
    LOGICAL_AND_EXPRESSION,
    INCLUSIVE_OR_EXPRESSION,
    
    EXCLUSIVE_OR_EXPRESSION,
    AND_EXPRESSION,
    EQUALITY_EXPRESSION,
    RELATIONAL_EXPRESSION,
    IN_EXPRESSION,
    
    SHIFT_EXPRESSION,
    ADDITIVE_EXPRESSION,
    MULTIPLICATIVE_EXPRESSION,
    UNARY_EXPRESSION,
    POSTFIX_EXPRESSION,
    
    STATIC_MEMBER_EXPRESSION,
    CALL_EXPRESSION,
    COMPUTED_MEMBER_EXPRESSION,
    NEW_EXPRESSION,
    IDENTIFIER,
    
    LITERAL,
    ARGUMENTS,
    ARRAY_EXPRESSION,
    OBJECT_EXPRESSION,
    BREAK_STATEMENT,
    
    CONTINUE_STATEMENT,
    DO_WHILE_STATEMENT,
    ITERATOR_DECLARATION,
    FOR_STATEMENT,
    VARIABLE_DECLARATION,
    
    IF_STATEMENT,
    RETURN_STATEMENT,
    VAR_STATEMENT,
    WHILE_STATEMENT,
    OBJECT_PROPERTY,
};

#define PR_statements @"0"
#define PR_id @"3"

#define PR_elements @"7"
#define PR_literal @"8"
#define PR_params @"23"
#define PR_body @"24"
#define PR_varName @"26"
#define PR_initialization @"27"
#define PR_declarations @"33"

typedef NS_ENUM(NSInteger, PropType) {
    PR_valueType,
    PR_arguments,
    
    PR_key,
    
    PR_expr,
    PR_properties,
    
    
    PR_constructor,
    
    PR_object,
    PR_property,
    PR_function,
    PR_subExpression,
    PR_op,
    
    PR_ops,
    PR_subExpressions,
    PR_condition,
    PR_onTrue,
    PR_onFalse,
    
    PR_left,
    PR_right,
    PR_expressions,

    
    
    PR_test,
    
    
    PR_iterable,
    PR_iterator,
    
    PR_init,
    PR_update,
    PR_argument,
    
};

#endif /* JawaExecutor_h */
