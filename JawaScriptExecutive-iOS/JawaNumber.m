/*
 Copyright (c) 2016, Chi-Wei(Jack) Wang
 All rights reserved.
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the intowow nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL Chi-Wei(Jack) Wang BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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