//
//  NetworkAccess.h
//  ModelViewer
//
//  Created by Steven on 5/13/13.
//  Copyright (c) 2013 Steven. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBandFileAccess.h"

@interface NetworkAccess : NSObject

+(uint8_t*)receiveBytes:(int) numberOfBytesToRead : (NSInputStream*)readStream;
+(int)getIntForFourUnsignedBytes:(uint8_t*) bytes;
+(void)loadModelFromServer:(BOOL*) returnBool;
+(void)checkNetwork;

@end
