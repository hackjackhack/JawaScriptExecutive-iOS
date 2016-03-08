//
//  JawaObjectProtected.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei (Jack) Wang on 2016/1/27.
//
//

#ifndef JawaObjectProtected_h
#define JawaObjectProtected_h

@interface JawaObject () {
    @protected
    NSMapTable* _properties;
    NSMutableDictionary* _prototype;
    __weak JawaExecutor* _executor;
}

@end

#endif /* JawaObjectProtected_h */
