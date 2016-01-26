//
//  JawaObject.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/26.
//
//

#ifndef JawaObject_h
#define JawaObject_h

#import "JawaObjectRef.h"

extern NSMutableDictionary* objectPrototype;

@interface JawaObject : NSObject
{

}
@property (strong) NSMutableDictionary* properties;
@property (strong) NSMutableDictionary* prototype;

-(id) init;
-(void) setProp:(NSString*)key with:(JawaObjectRef*)value;
-(JawaObjectRef*) getProp:(NSString*)key;
-(int)getBuiltinID:(NSString*)funcName;
-(JawaObjectRef*)invokeBuiltin:(NSString*)funcName;
-(NSString*)description;
-(NSString*) toJSON:(NSMutableString*)ret;
@end

#endif /* JawaObject_h */
