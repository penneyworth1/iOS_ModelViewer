//
//  AppDelegate.m
//  ModelViewer
//
//  Created by Steven on 5/8/13.
//  Copyright (c) 2013 Steven. All rights reserved.
//

#import "AppDelegate.h"
#include "corec.h"
#include "DBandFileAccess.h"
#include "NetworkAccess.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    running = NO; //start running when app becomes active
    modelLoaded = NO; //when there is no model loaded, we should not try to use the resources needed for drawing
    //networkCheckInProgress = NO;
    
    
    
    
    
    /*
    const int maxNumberOfTouchEvents = 20;
	int touchEventWriteIndex = 0;
	int touchEventReadIndex = 0; //which of the stored touch events will be sent to the native code next
	float[] touchX = new float[maxNumberOfTouchEvents];
	float[] touchY = new float[maxNumberOfTouchEvents];
	int[] pointerIndex = new int[maxNumberOfTouchEvents];
	int[] touchEventType = new int[maxNumberOfTouchEvents]; //1=down, 2=up, 3=move
	bool[] touchEventProcessed = new boolean[maxNumberOfTouchEvents];
    */
    
    
    
    
    
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:context];
    
    GLKView *view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds] context:context];
    view.delegate = self;
    
    GLKViewController *controller = [[GLKViewController alloc] init];
    //controller.delegate = self;
    controller.view = view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [controller setPreferredFramesPerSecond:60];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    
    //NSLog(@"window: w: %f h %f", self.window.bounds.size.width, self.window.bounds.size.height);
    
	//[DBandFileAccess loadModel:@"model1"];
    //modelLoaded = YES;
    
    initView(self.window.bounds.size.width,self.window.bounds.size.height, -2.0f);
    
    
    
    
    //m_Texture=[self loadTexture:@"world.png"];
    
    return YES;
}

- (void)updateLoop
{
    //NSLog(@"update thread started");
    updateTheadActive = YES;
    while(running)
    {
        systemTime = CACurrentMediaTime();
        timeDifference = (long)((systemTime - lastUpdateTime)*1000);
        lastUpdateTime = CACurrentMediaTime();
        if(timeDifference>1000) timeDifference = 1000;        
        
        if(touchEventProcessed[touchEventReadIndex] == 0)
        {            
            updateWorld(timeDifference,touchX[touchEventReadIndex],
                                       touchY[touchEventReadIndex],
                                       touchEventType[touchEventReadIndex]);
            [self setTouchEventProcessed:touchEventReadIndex :1];
            touchEventReadIndex++;
            if(touchEventReadIndex>=maxNumberOfTouchEvents)
                touchEventReadIndex = 0;
        }
        else
        {
            updateWorld(timeDifference,0,0,0);
        }        
        
        [NSThread sleepForTimeInterval:0.015];
    }
    updateTheadActive = NO;
    //NSLog(@"update thread finished");
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //NSLog(@"in glkView:drawInRect: w: %f h %f", rect.size.width, rect.size.height);    
    if(modelLoaded)
        drawFrame();
    
    //NSLog(@"finished drawing a frame");
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouchEvent:1 :touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouchEvent:2 :touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self processTouchEvent:3 :touches];
}

- (void)processTouchEvent:(unsigned char)touchType :(NSSet *)touches
{
    float _x1,_y1;
    NSArray *touchesArray = [touches allObjects];
    for(int i=0; i<[touchesArray count]; i++)
    {
        UITouch *touch = (UITouch *)[touchesArray objectAtIndex:i];
        CGPoint point = [touch locationInView:nil];
        if(i==0)
        {
            _x1 = point.x;
            _y1 = point.y;
        }
        //NSLog(@"Touch event %f , %f", point.x, point.y);
    }   
    
    touchX[touchEventWriteIndex] = _x1;
    touchY[touchEventWriteIndex] = _y1;    
    touchEventType[touchEventWriteIndex] = touchType;
    
    //must come last so the update thread does not read an incomplete state of the touch event
    [self setTouchEventProcessed:touchEventWriteIndex :0]; 
    touchEventWriteIndex++;
    if(touchEventWriteIndex>=maxNumberOfTouchEvents)
        touchEventWriteIndex = 0;
}

- (void)setTouchEventProcessed:(int)index :(unsigned char)valuePar
{
    @synchronized(touchProcessedLock)
    {
        touchEventProcessed[index] = valuePar;
    }
}

//- (void)glkViewControllerUpdate:(GLKViewController *)controller
//{
//  NSLog(@"in glkViewControllerUpdate");
//}

-(GLKTextureInfo *)loadTexture:(NSString *)filename
{
    NSError *error;
    GLKTextureInfo *info;
    NSString *path=[[NSBundle mainBundle]pathForResource:filename ofType:NULL];
    
    info=[GLKTextureLoader textureWithContentsOfFile:path options:nil error:&error];
    if (info == nil)
    {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    }
    
    glBindTexture(GL_TEXTURE_2D, info.name);
    NSLog(@"texture id: %f", (float)info.name);
    
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT);
    
    return info;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    //NSLog(@"resigning active");
    
    running = NO;
    modelLoaded = NO;
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{    
    while(updateTheadActive)
        [NSThread sleepForTimeInterval:0.1]; //make sure not to release resources until this thread has terminated
    
    //free corec variables
    freeMemory();
    //free ios-specific variables
    free(touchX);
    free(touchY);
    free(touchEventType);
    free(touchEventProcessed);
    
    
    
    //NSLog(@"(did enter background) freeMemory called");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //NSLog(@"becoming active");    
    
    //Init touch event variables. The update thread uses these!
    maxNumberOfTouchEvents = 20;
	touchEventWriteIndex = 0;
	touchEventReadIndex = 0; //which of the stored touch events will be sent to the native code next
	touchX = malloc(sizeof(float)*maxNumberOfTouchEvents);
	touchY = malloc(sizeof(float)*maxNumberOfTouchEvents);
	touchEventType = malloc(sizeof(unsigned char)*maxNumberOfTouchEvents); //1=down, 2=up, 3=move
	touchEventProcessed = malloc(sizeof(unsigned char)*maxNumberOfTouchEvents);
    //clear the arrays of the garbage they might be pointing at
    int i;
    for(i=0;i<maxNumberOfTouchEvents;i++)
    {
        touchX[i]=0;touchY[i]=0;touchEventType[i]=0;touchEventProcessed[i]=0;
    }
    
    //start update thread
    if(!running)
    {
        running = YES;
        [NSThread detachNewThreadSelector:@selector(updateLoop) toTarget:self withObject:nil];
    }
    if(!modelLoaded)
    {
        downloadSuccessful = NO;
        [NetworkAccess loadModelFromServer:&downloadSuccessful];
        
        if(downloadSuccessful)
        {
            NSLog(@"Download successful.");
        }
        else
        {
            [DBandFileAccess loadModel:@"model1"];
            NSLog(@"Unable to load model from network. Loading base model");
        }
        modelLoaded = YES;
    } 
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
