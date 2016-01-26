//
//  JawaObjectRef.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/20.
//
//

#ifndef JawaObjectRef_h
#define JawaObjectRef_h

#define QUANTUM 0.0000000000000001

@class JawaArray;
@class JawaFunc;
@class JawaObject;

@interface JawaObjectRef : NSObject
{

}

@property (strong) NSObject* object;
@property (weak) JawaObjectRef* appliedOn;

-(id)init;
-(id)initWithNumber:(double)number;
-(id)initWithString:(NSString*)string;
-(id)initWithBoolean:(bool)tf;
-(id)initWithJawaArray:(JawaArray*)array;
-(id)initWithJawaFunc:(JawaFunc*)func;
-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj;
-(id)initWithJawaObject:(JawaObject*)obj;
-(NSString*)description;
-(id)transfer;

+(id)Ref;
+(id)RefWithNumber:(double)number;
+(id)RefWithString:(NSString*)string;
+(id)RefWithBoolean:(bool)tf;
+(id)RefWithJawaArray:(JawaArray*)array;
+(id)RefWithJawaFunc:(JawaFunc*)func;
+(id)RefWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj;
+(id)RefWithJawaObject:(JawaObject*)obj;

@end

#endif /* JawaObjectRef_h */
