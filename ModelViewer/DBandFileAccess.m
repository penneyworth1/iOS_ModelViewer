//
//  DBandFileAccess.m
//  ModelViewer
//
//  Created by Steven on 5/10/13.
//  Copyright (c) 2013 Steven. All rights reserved.
//

#import "DBandFileAccess.h"

@implementation DBandFileAccess

+ (int)getModelCountOfThisName:(NSString*)modelName
{
    int modelCount = 0;
    sqlite3* database = [DBandFileAccess getDb];    
    NSString *sql;
    sqlite3_stmt *compiledStatement;
    
    sql = [NSString stringWithFormat:@"select count(*) from tbl_Models where TXT_Name = '%@'",modelName] ;
    if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
    {
        while(sqlite3_step(compiledStatement) == SQLITE_ROW)
        {
            modelCount = sqlite3_column_int(compiledStatement, 0);
        }
    }
    else
        NSLog(@"ERROR with sql statement: %@",sql);
    sqlite3_reset(compiledStatement);
    
    //Release the compiled statement from memory
    sqlite3_finalize(compiledStatement);
    //MUST CLOSE DB AFTER CALLING getDb!
    sqlite3_close(database);
    
    return modelCount;
}

+ (void)addModel:(NSString*)modelName : (NSString*)textureFilename : (NSString*)modelData : (int)usesTexture
{
    int modelCountOfThisName = [DBandFileAccess getModelCountOfThisName:modelName];
    NSString *sql;
    sqlite3* database = [DBandFileAccess getDb];
    char *error;
    
    if(modelCountOfThisName>0)
    {
        sql = [NSString stringWithFormat:@"UPDATE tbl_Models "
                                          "SET TXT_TextureFilename = '%@', "
                                          "TXT_ModelData = '%@', "
                                          "INT_UsesTexture = %i "
                                          "WHERE TXT_Name = '%@' ",textureFilename,modelData,usesTexture,modelName];
        NSLog(@"using update");
    }
    else
    {
        sql = [NSString stringWithFormat:@"INSERT INTO tbl_Models "
                                          "(TXT_Name,TXT_TextureFilename,TXT_ModelData,INT_UsesTexture) "
                                          "VALUES ('%@','%@','%@',%i) "
                                          ,modelName,textureFilename,modelData,usesTexture];
        NSLog(@"using insert");
    }
    
    if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &error) == SQLITE_OK)
        NSLog(@"insert into table exec ok");
    else
        NSLog(@"ERROR - %s", error);
    
    
    //MUST CLOSE DB AFTER CALLING getDb!
    sqlite3_close(database);
}

+ (void)loadModel:(NSString*)modelName
{
    sqlite3* database = [DBandFileAccess getDb];
    NSString *sql;
    sqlite3_stmt *compiledStatement;
    //char *error;
    
    sql = [NSString stringWithFormat:@"select * from tbl_Models where TXT_Name = '%@'",modelName] ;
    if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
    {
    	while(sqlite3_step(compiledStatement) == SQLITE_ROW)
        {            
            NSArray* modelDataStrings =
            [[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 3)] componentsSeparatedByString:@","];
            
            int stringValueCount = [modelDataStrings count];
            NSMutableArray* vertexArray = [[NSMutableArray alloc] init];
            NSMutableArray* normalArray = [[NSMutableArray alloc] init];
            NSMutableArray* indexArray = [[NSMutableArray alloc] init];
            NSMutableArray* texCoordArray = [[NSMutableArray alloc] init];
            NSMutableArray* colorArray = [[NSMutableArray alloc] init];
            int i;
            NSString* writeMode = @"";
            NSString* stringAtIndex;
            for(i=0;i<stringValueCount;i++)
            {
                stringAtIndex = [modelDataStrings objectAtIndex:i];
                if([stringAtIndex isEqualToString:@"vertices"] ||
                   [stringAtIndex isEqualToString:@"normals"] ||
                   [stringAtIndex isEqualToString:@"indices"] ||
                   [stringAtIndex isEqualToString:@"texture coordinates"] ||
                   [stringAtIndex isEqualToString:@"colors"])
                    writeMode = stringAtIndex;
                else
                {
                    if([writeMode isEqualToString:@"vertices"])
                        [vertexArray addObject:stringAtIndex];
                    else if([writeMode isEqualToString:@"normals"])
                        [normalArray addObject:stringAtIndex];
                    else if([writeMode isEqualToString:@"indices"])
                        [indexArray addObject:stringAtIndex];
                    else if([writeMode isEqualToString:@"texture coordinates"])
                        [texCoordArray addObject:stringAtIndex];
                    else if([writeMode isEqualToString:@"colors"])
                        [colorArray addObject:stringAtIndex];
                }
            }
            int numberOfVertices = [vertexArray count];
            int numberOfIndices = [indexArray count];
            //int numberOfTexCoords = [texCoordArray count];
            int numberOfColors = [colorArray count];
            
            //c
            GLfloat * cVertexArray = malloc(sizeof(GLfloat) * numberOfVertices);
            GLfloat * cNormalArray = malloc(sizeof(GLfloat) * numberOfVertices);
            GLushort * cIndexArray = malloc(sizeof(GLushort) * numberOfIndices);
            //GLfloat * cTexCoordArray = malloc(sizeof(GLfloat) * numberOfTexCoords);
            GLubyte * cColorArray = malloc(sizeof(GLubyte) * numberOfColors);
            
            for(i=0;i<numberOfVertices;i++)
            {
                cVertexArray[i] = (GLfloat)[[vertexArray objectAtIndex:i] intValue] / 1000000;
                cNormalArray[i] = (GLfloat)[[normalArray objectAtIndex:i] intValue] / 1000000;
            }
            for(i=0;i<numberOfIndices;i++)
            {
                cIndexArray[i] = (GLushort)[[indexArray objectAtIndex:i] intValue];
            }
            for(i=0;i<numberOfColors;i++)
            {
                cColorArray[i] = (GLubyte)[[colorArray objectAtIndex:i] intValue];
            }
            
            loadModel(&cVertexArray[0],&cNormalArray[0],&cColorArray[0],&cIndexArray[0],numberOfIndices);
    	}
    }
    else
        NSLog(@"ERROR with sql statement: %@",sql);
    sqlite3_reset(compiledStatement);
    
    //Release the compiled statement from memory
    sqlite3_finalize(compiledStatement);
    //MUST CLOSE DB AFTER CALLING getDb!
    sqlite3_close(database);
}

+ (sqlite3*)getDb
{
    ////////////Hardcoded databse version////////////////////////
    int dbVersion = 2;
    /////////////////////////////////////////////////////////////
    ////////////Whether or not we must delete and recreate the db before returning it
    BOOL dbMustUpgrade = false;
    /////////////////////////////////////////////////////////////
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths lastObject];
    NSString* databasePath = [documentsDirectory stringByAppendingPathComponent:@"mydb.sqlite"];

    sqlite3 *database;
    
    if(sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK)
    {
        //NSLog(@"Opened sqlite database at %@", databasePath);
        
        NSString *sql;        
        sqlite3_stmt *compiledStatement;
        char *error;
        
        //First make sure the dbInfo table exists.
        //NSString *createStatement =
        sql =
        @"CREATE TABLE IF NOT EXISTS tbl_dbInfo (INT_Version INTEGER,TXT_Name TEXT)";        
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &error) == SQLITE_OK)
            ;//NSLog(@"create table exec ok");
        else
            NSLog(@"%s", error);
        
        //Next, make sure there is a record in the info table. If not, the db must be re-created.
        int infoRecordCount = 0;
        sql = @"SELECT * FROM tbl_dbInfo";
        if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
        {
			while(sqlite3_step(compiledStatement) == SQLITE_ROW)
            {
				int versionFromDB = sqlite3_column_int(compiledStatement, 0);
				//NSString *nameFromDB =
                //[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
                //NSLog(@"version: %i name: %@",versionFromDB,nameFromDB);
                infoRecordCount ++;
                if(versionFromDB != dbVersion)
                    dbMustUpgrade = YES; //delete and recreate the db if the version has changed
			}
		}
        else
            NSLog(@"ERROR with sql statement: %@",sql);        
        sqlite3_reset(compiledStatement); //allows us to reuse the compiledStatement object
        
        if(infoRecordCount<1)
            dbMustUpgrade = YES;        
        
        if(dbMustUpgrade)
            [DBandFileAccess upgradeDb:database :dbVersion]; //upgrade db if the version has changed
        else
            ;//NSLog(@"did not need to upgrade db");
        
		// Release the compiled statement from memory
		sqlite3_finalize(compiledStatement);
        
        return database;
    }
    else
    {
        NSLog(@"Failed to open database at %@ with error %s", databasePath, sqlite3_errmsg(database));
        sqlite3_close (database);
        return Nil;
    }
    
}


+ (void)upgradeDb:(sqlite3*)database :(int)version
{
    NSString *sql;
    sqlite3_stmt *compiledStatement;
    char *error;
    
    //drop tables
    sql = @"DROP TABLE IF EXISTS tbl_dbInfo;"
           "DROP TABLE IF EXISTS tbl_Models;";
    if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &error) == SQLITE_OK)
        NSLog(@"drop tables exec ok");
    else
        NSLog(@"%s", error);
    
    sql = @"CREATE TABLE IF NOT EXISTS tbl_dbInfo (INT_Version INTEGER,TXT_Name TEXT);"
           "CREATE TABLE tbl_Models (PK_ModelID             INTEGER PRIMARY KEY , "
                                    "TXT_Name               TEXT                , "
                                    "TXT_TextureFilename    TEXT                , "
                                    "TXT_ModelData          TEXT                , "
                                    "INT_UsesTexture        INTEGER             );";
    if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &error) == SQLITE_OK)
        NSLog(@"create table exec ok");
    else
        NSLog(@"%s", error);
    
    sql = [NSString stringWithFormat:
    @"INSERT INTO tbl_dbInfo (INT_Version, TXT_Name) VALUES ('%i','%@')", version, @"MyDB"];
    if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &error) == SQLITE_OK)
        NSLog(@"insert into table exec ok");
    else
        NSLog(@"%s", error);
    
    sql = @"select * from tbl_dbInfo";
    if(sqlite3_prepare_v2(database, [sql UTF8String], -1, &compiledStatement, NULL) == SQLITE_OK)
    {
    	while(sqlite3_step(compiledStatement) == SQLITE_ROW)
        {
    		int versionFromDB = sqlite3_column_int(compiledStatement, 0);
    		NSString *nameFromDB =
            [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement, 1)];
            NSLog(@"(from upgrade method)  version: %i name: %@",versionFromDB,nameFromDB);
    	}
    }
    else
        NSLog(@"ERROR with sql statement: %@",sql);
    sqlite3_reset(compiledStatement);
    
    // Release the compiled statement from memory
    sqlite3_finalize(compiledStatement);
       
    //load a model from a file in the bundle into the db:
    [DBandFileAccess loadModelFromFileToDB:database :@"model1"];    
}

+ (void)loadModelFromFileToDB:(sqlite3*)database :(NSString*)filename
{
    NSString* path = [[NSBundle mainBundle] pathForResource:filename
                                                     ofType:@"txt"];    
    NSString* fileContent = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];    
    NSString* sql;
    //sqlite3_stmt *compiledStatement;
    char *error;
    sql = [NSString stringWithFormat:
           @"INSERT INTO tbl_Models (TXT_Name,"
                                    "TXT_TextureFilename,"
                                    "TXT_ModelData,"
                                    "INT_UsesTexture)"
                         "VALUES ('%@','%@','%@',%i);",
           filename,@"",fileContent,0];
    if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &error) == SQLITE_OK)
        NSLog(@"insert into model table from file exec ok");
    else
        NSLog(@"%s", error);
}




@end
