//
//  JawaNumber.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/3/10.
//
//

#ifndef JawaNumber_h
#define JawaNumber_h

@interface JawaNumber : NSObject
{
    
}
@property double value;

-(id) init:(double)value;
-(NSString*) description;
-(double) doubleValue;
-(int) intValue;
-(long) longValue;
-(long long) longlongValue;
-(unsigned int) unsignedIntValue;
-(unsigned long) unsignedLongValue;
-(unsigned long long) unsignedLongLongValue;

+(id)numberWithDouble:(double)number;
@end

#endif /* JawaNumber_h */
