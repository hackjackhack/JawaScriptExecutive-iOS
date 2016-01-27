//
//  JawaObjectRef.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/20.
//
//

#ifndef JawaObjectRef_h
#define JawaObjectRef_h

#import "JawaExecutor.h"

@class JawaArray;
@class JawaFunc;
@class JawaObject;

@interface JawaObjectRef : NSObject
{

}

@property (strong) NSObject* object;
@property (weak) JawaObjectRef* appliedOn;
@property (weak) JawaExecutor* executor;

-(id)initIn:(JawaExecutor*)ex;
-(id)initWithNumber:(double)number in:(JawaExecutor*)ex;
-(id)initWithString:(NSString*)string in:(JawaExecutor*)ex;
-(id)initWithBoolean:(bool)tf in:(JawaExecutor*)ex;
-(id)initWithJawaArray:(JawaArray*)array;
-(id)initWithJawaFunc:(JawaFunc*)func;
-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj;
-(id)initWithJawaObject:(JawaObject*)obj;
-(NSString*)description;
-(id)transfer;

+(id)RefIn:(JawaExecutor*)ex;
+(id)RefWithNumber:(double)number in:(JawaExecutor*)ex;
+(id)RefWithString:(NSString*)string in:(JawaExecutor*)ex;
+(id)RefWithBoolean:(bool)tf in:(JawaExecutor*)ex;
+(id)RefWithJawaArray:(JawaArray*)array;
+(id)RefWithJawaFunc:(JawaFunc*)func;
+(id)RefWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj;
+(id)RefWithJawaObject:(JawaObject*)obj;

@end

#endif /* JawaObjectRef_h */
