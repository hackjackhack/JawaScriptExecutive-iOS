//
//  JawaNumber.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/3/10.
//
//

#import <Foundation/Foundation.h>
#import "JawaNumber.h"
#import "JawaExecutor.h"

@implementation JawaNumber

-(id) init:(double)value {
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

-(NSString*) description {
    if (fabs(self.value-round(self.value)) < QUANTUM) {
        return [NSString stringWithFormat:@"%ld", (long)self.value];
    }
    return [NSString stringWithFormat:@"%lf", self.value];
}

-(double) doubleValue {
    return self.value;
}

-(int) intValue {
    return (int)self.value;
}

-(long) longValue {
    return (long)self.value;
}

-(long long) longlongValue {
    return (long long)self.value;
}

-(unsigned int) unsignedIntValue {
    return (unsigned int)self.value;
}

-(unsigned long) unsignedLongValue {
    return (unsigned long)self.value;
}

-(unsigned long long) unsignedLongLongValue {
    return (unsigned long long)self.value;
}

+(id)numberWithDouble:(double)number {
    return [[self alloc] init:number];
}
@end