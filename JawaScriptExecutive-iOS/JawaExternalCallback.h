//
//  JawaExternalCallback.h
//  JawaScriptExecutive-iOS
//
//  Created by Chi-Wei Wang on 2016/3/11.
//
//

#ifndef JawaExternalCallback_h
#define JawaExternalCallback_h

@protocol JawaExternalCallback 

-(NSMutableDictionary*)call:(NSString*)functionName with:(NSDictionary*)argument;

@end

#endif /* JawaExternalCallback_h */
