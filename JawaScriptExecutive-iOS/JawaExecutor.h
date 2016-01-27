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
@property NSMutableArray* currentActivation;

-(JawaObjectRef*)evaluate:(NSDictionary*)tree;
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
    IN_EXPRESSINO,
    
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

typedef NS_ENUM(NSInteger, PropType) {
    PR_statements = 0,
    PR_valueType,
    PR_arguments,
    PR_id,
    PR_key,
    
    PR_expr,
    PR_properties,
    PR_elements,
    PR_literal,
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
    PR_params,
    PR_body,
    
    PR_test,
    PR_varName,
    PR_initialization,
    PR_iterable,
    PR_iterator,
    
    PR_init,
    PR_update,
    PR_argument,
    PR_declarations,
};

#endif /* JawaExecutor_h */
