//
//  JawaFunc.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/26.
//
//

#ifndef JawaFunc_h
#define JawaFunc_h

#import "JawaObject.h"
#import "JawaObjectProtected.h"

@interface JawaFunc : JawaObject
{
    
}
@property NSString* name;
@property NSDictionary* body;
@property NSArray* params;
@property BOOL isBuiltIn;
@property BOOL isPropertyWrapper;
@property NSUInteger switchId;

-(id)initWithName:(NSString*)name in:(JawaExecutor*)ex taking:(NSArray*)params isBuiltin:(BOOL)builtin isPropertyWrapper:(BOOL)propertyWrapper and:(NSDictionary*)body;
-(JawaObjectRef*)apply:(JawaObjectRef*)on;
-(JawaObjectRef*)apply;
-(NSString*)description;
@end


#endif /* JawaFunc_h */
