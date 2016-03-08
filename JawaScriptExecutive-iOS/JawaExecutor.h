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
#define PR_valueType @"1"
#define PR_arguments @"2"
#define PR_id @"3"
#define PR_key @"4"
#define PR_expr @"5"
#define PR_properties @"6"
#define PR_elements @"7"
#define PR_literal @"8"
#define PR_constructor @"9"
#define PR_object @"10"
#define PR_property @"11"
#define PR_function @"12"
#define PR_subExpression @"13"
#define PR_op @"14"
#define PR_ops @"15"
#define PR_subExpressions @"16"
#define PR_condition @"17"
#define PR_onTrue @"18"
#define PR_onFalse @"19"
#define PR_left @"20"
#define PR_right @"21"
#define PR_expressions @"22"
#define PR_params @"23"
#define PR_body @"24"
#define PR_test @"25"
#define PR_varName @"26"
#define PR_initialization @"27"
#define PR_iterable @"28"
#define PR_iterator @"29"
#define PR_init @"30"
#define PR_update @"31"
#define PR_argument @"32"
#define PR_declarations @"33"

#endif /* JawaExecutor_h */
