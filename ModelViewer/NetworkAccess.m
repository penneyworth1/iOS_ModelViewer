#import "NetworkAccess.h"

@implementation NetworkAccess

+(uint8_t*)receiveBytes:(int) numberOfBytesToRead : (NSInputStream*)inputStream
{
    uint8_t * input = malloc(sizeof(uint8_t)*numberOfBytesToRead);    
    int numberOfBytesRead = 0;
    int j;
    while(numberOfBytesToRead > numberOfBytesRead)
    {
        uint8_t buf[numberOfBytesToRead-numberOfBytesRead];
        
        NSUInteger bytesRead = [inputStream read:buf maxLength:(numberOfBytesToRead-numberOfBytesRead)];        
        for(j=0;j<bytesRead;j++)
            input[numberOfBytesRead+j] = buf[j];
        numberOfBytesRead += bytesRead;
    }    
    //for(i=0;i<numberOfBytesToRead;i++)
        //NSLog(@"received byte: %i",input[i]);
    
    return input;
}

+(int)getIntForFourUnsignedBytes:(uint8_t*) bytes
{
    int returnInt = pow(2,24)*bytes[0] +
    pow(2,16)*bytes[1] +
    pow(2,8) *bytes[2] +
    bytes[3];
    return returnInt;
}

+(void)loadModelFromServer:(BOOL*) returnBool
{
    *returnBool = NO;
    
    @try
    {
        NSInputStream *inputStream;
        NSOutputStream *outputStream;
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"gompka.selfip.com", 50000, &readStream, &writeStream);
                    
        if(readStream && writeStream)
        {            
            inputStream = (__bridge NSInputStream *)readStream;
            outputStream = (__bridge NSOutputStream *)writeStream;
            
            [inputStream open];
            [outputStream open];
                
            //send byte to declare that it is a mobile app model viewer that is connecting
            uint8_t output[1];
            output[0] = (uint8_t)1;
            [outputStream write:output maxLength:1];            
            
            //receive acknowledge
            uint8_t* input = [NetworkAccess receiveBytes:1 :inputStream];
            //we can check here if the right byte was received if we need to
            free(input);
            
            //send byte to request the model data byte count
            [outputStream write:output maxLength:1];
            
            //receive model data byte count
            input = [NetworkAccess receiveBytes:4 :inputStream];
            int modelDataByteCount = [NetworkAccess getIntForFourUnsignedBytes:input];
            //we can check here if the right byte was received if we need to
            NSLog(@"modeldata byte count: %i",modelDataByteCount);
            free(input);
            
            //ack
            [outputStream write:output maxLength:1];
            
            //receive model data
            input = [NetworkAccess receiveBytes:modelDataByteCount :inputStream];
            NSString* modelDataString = [NSString stringWithUTF8String:(const char*)input];
            
            [DBandFileAccess addModel:@"modelFromNetwork" :@"-" :modelDataString :0];
                        
            [inputStream close];
            [outputStream close];
            
            [DBandFileAccess loadModel:@"modelFromNetwork"];
            
            *returnBool = YES;
        }
        else
        {
            NSLog(@"ERROR - Failed to open readstream and/or writestream.");
        }
    }
    @catch (NSException *exception)
    {
        NSArray *backtrace = [exception callStackSymbols];
        NSLog(@"%@",backtrace);
    }
    @finally
    {
        // do something to keep the program still running properly
    }
    
}

+(void)checkNetwork
{
    //NSLog(@"network check thread starting");
    
    @try
    {        
        NSInputStream *inputStream;
        NSOutputStream *outputStream;
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"gompka.selfip.com", 50000, &readStream, &writeStream);
        
        
        if(readStream && writeStream)
        {
            NSLog(@"seems ok");
            
            inputStream = (__bridge NSInputStream *)readStream;
            outputStream = (__bridge NSOutputStream *)writeStream;
        
            [inputStream open];
            [outputStream open];
        
            //send data
            uint8_t output[1];
            output[0] = (uint8_t)1;            
            [outputStream write:output maxLength:1];
            
                
            int numberOfBytesToRead = 1;
            int numberOfBytesRead = 0;
            uint8_t input[numberOfBytesToRead];            
            int i,j;
            while(numberOfBytesToRead > numberOfBytesRead)
            {
                uint8_t buf[numberOfBytesToRead-numberOfBytesRead];
                NSUInteger bytesRead = [inputStream read:buf maxLength:(numberOfBytesToRead-numberOfBytesRead)];
                
                for(j=0;j<bytesRead;j++)
                    input[numberOfBytesRead+j] = buf[j];                
                
                numberOfBytesRead += bytesRead;
            }
            
            for(i=0;i<numberOfBytesToRead;i++)
                NSLog(@"%i",input[i]);
        
            [inputStream close];
            [outputStream close];
        }
        else
        {
            NSLog(@"ERROR - Failed to open readstream and/or writestream.");
        }
    }
    @catch (NSException *exception)
    {
        NSArray *backtrace = [exception callStackSymbols];
        NSLog(@"%@",backtrace);
    }
    @finally
    {
        // do something to keep the program still running properly
    }
    
    
    //NSLog(@"network check thread ending");
}

@end
