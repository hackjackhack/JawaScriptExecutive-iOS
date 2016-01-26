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
    NSObject* object;
    __weak JawaObjectRef* appliedOn;
}
-(id)init;
-(id)initWithNumber:(double)number;
-(id)initWithString:(NSString*)string;
-(id)initWithBoolean:(bool)tf;
-(id)initWithJawaArray:(JawaArray*)array;
-(id)initWithJawaFunc:(JawaFunc*)func;
-(id)initWithJawaFunc:(JawaFunc*)func on:(JawaObjectRef*)obj;
-(id)initWithJawaObject:(JawaObject*)obj;
-(NSString*)toString;
-(id)transfer;
@end

#endif /* JawaObjectRef_h */
