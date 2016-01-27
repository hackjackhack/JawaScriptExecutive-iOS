//
//  JawaString.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/27.
//
//

#ifndef JawaString_h
#define JawaString_h

#include "JawaObjectRef.h"

extern NSDictionary* stringPrototype;
extern JawaObjectRef* dispatchStringBuiltin(NSMutableString *str, NSString* funcName);

#endif /* JawaString_h */
