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

#ifndef JawaObjectRef_h
#define JawaObjectRef_h

#import "JawaExecutor.h"

@class JawaArray;
@class JawaFunc;
@class JawaObject;

extern int release_count;
@interface JawaObjectRef : NSObject
{

}

@property bool marked;
@property bool discovered;
@property int obj_id;
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
-(void)dealloc;

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
