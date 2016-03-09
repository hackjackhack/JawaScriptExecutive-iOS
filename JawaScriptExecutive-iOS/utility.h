//
//  utility.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/28.
//
//

#ifndef utility_h
#define utility_h

extern NSMutableArray* jsonToArray(NSString* str);
extern NSMutableDictionary* jsonToDictionary(NSString* str);
extern NSString* dictionaryToJSON(NSDictionary* dict);

#endif /* utility_h */
