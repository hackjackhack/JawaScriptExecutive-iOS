//
//  JawaArray.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/26.
//
//

#ifndef JawaArray_h
#define JawaArray_h

#import "JawaObject.h"

extern NSMutableDictionary* arrayPrototype;

@interface JawaArray : JawaObject
{
    
}
@property NSPointerArray* elements;

-(id) initIn:(JawaExecutor *)ex;
-(NSString*) description;
-(NSMutableString*) toJSON:(NSMutableString *)ret;
-(void)append:(JawaObjectRef*)element;
-(JawaObjectRef*)at:(int)index;
-(JawaObjectRef*)invokeBuiltin:(NSString*)funcName;


@end


#endif /* JawaArray_h */
