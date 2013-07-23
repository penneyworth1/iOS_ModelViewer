/////////iOS-specific inludes
#include <OpenGLES/ES1/gl.h>
/////////


#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <math.h>
#include <unistd.h>
#include <string.h>
#include <time.h>

float screenWidth;
float screenHeight;
float nearZ; //z value of the near clipping plane
float lastTouchX;
float lastTouchY;

GLfloat * vertices;
GLfloat * normals;
GLubyte * colors;
GLushort * indices;
int numberOfIndices;

void updateWorld(int,float,float,int);
void drawFrame();
void initView(float, float, float);
void loadModel(GLfloat * , GLfloat * , GLubyte * , GLushort * , int);
void freeMemory();