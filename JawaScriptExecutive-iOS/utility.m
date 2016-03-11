//
//  utility.m
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/28.
//
//

#import <Foundation/Foundation.h>
#import "utility.h"

NSMutableArray* jsonToArray(NSString* str) {
    NSError *error;
    NSMutableArray * array = [NSJSONSerialization
                              JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                              options:kNilOptions
                              error:&error];
    return array;
}

NSMutableDictionary* jsonToDictionary(NSString* str) {
    NSError *error;
    NSMutableDictionary * dict = [NSJSONSerialization
                                  JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                  options:kNilOptions
                                  error:&error];
    return dict;
}

NSString* dictionaryToJSON(NSDictionary* dict) {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
    
    NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [json stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
}
