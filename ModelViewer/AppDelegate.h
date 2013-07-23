//
//  AppDelegate.h
//  ModelViewer
//
//  Created by Steven on 5/8/13.
//  Copyright (c) 2013 Steven. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,GLKViewDelegate>//,GLKViewControllerDelegate>
{
    GLKTextureInfo *m_Texture;
    BOOL running;
    BOOL updateTheadActive;
    BOOL modelLoaded;
    BOOL networkCheckInProgress;
    BOOL downloadSuccessful;
    double systemTime;
    double lastUpdateTime;
    long timeDifference;
    
    unsigned char maxNumberOfTouchEvents;
	unsigned char touchEventWriteIndex;
	unsigned char touchEventReadIndex; //which of the stored touch events will be sent to the native code next
	float * touchX;
	float * touchY;
	unsigned char * touchEventType; //1=down, 2=up, 3=move
	unsigned char * touchEventProcessed;
    NSObject* touchProcessedLock;
}

- (GLKTextureInfo *)loadTexture:(NSString *)filename;
- (void)updateLoop;
- (void)processTouchEvent:(unsigned char)touchType :(NSSet *)touches;
- (void)setTouchEventProcessed:(int)index :(unsigned char)valuePar;

@property (strong, nonatomic) UIWindow *window;

@end

//testing
