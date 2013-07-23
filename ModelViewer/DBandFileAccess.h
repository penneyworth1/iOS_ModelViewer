//
//  DBandFileAccess.h
//  ModelViewer
//
//  Created by Steven on 5/10/13.
//  Copyright (c) 2013 Steven. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGLES/ES1/gl.h>
#import <sqlite3.h>
#include "corec.h"

@interface DBandFileAccess : NSObject
{
    
}

+ (sqlite3*)getDb;
+ (int)getModelCountOfThisName:(NSString*)modelName;
+ (void)loadModel:(NSString*)modelName;
+ (void)upgradeDb:(sqlite3*)database :(int)version;
+ (void)loadModelFromFileToDB:(sqlite3*)database :(NSString*)filename;
+ (void)addModel:(NSString*)modelName : (NSString*)textureFilename : (NSString*)modelData : (int)usesTexture;

//unused - we use sqlite instead
//+ (void)loadModelFromAsset:(NSString*)filename;

@end
