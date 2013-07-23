#include "corec.h"

#define pi 3.14159265358979323846264338327

//temporary usage
float myFloat = 0;
float spinX = 0;
float spinY = 0;
float spinZ = 0;
clock_t start = 0;
clock_t end = 0;
unsigned long deltaTime = 0;
//end temporary usage



void logInt(int i, char strPar[])
{
	char str[15];
	sprintf(str, "%d", i);
    
}
void logFloat(float f, char strPar[])
{
	char str[25];
	sprintf(str, "%f", f);
    
}
void logChar(unsigned char c, char strPar[])
{
	char str[25];
	sprintf(str, "%c", c);
    
}

void loadModel(GLfloat * verticesPar, GLfloat * normalsPar, GLubyte * colorsPar, GLushort * indicesPar, int numberOfIndicesPar)
{
    //remove
    myFloat = 0;
    spinX = 0;
    spinY = 0;    
    
	vertices = verticesPar;
	normals = normalsPar;
	colors = colorsPar;
	indices = indicesPar;
	numberOfIndices = numberOfIndicesPar;
}

void freeMemory()
{
	free(vertices);
	free(normals);
	free(colors);
	free(indices);
}

void initView(float screenWidthPar, float screenHeightPar, float nearZpar)
{
	glViewport(0, 0, screenWidthPar, screenHeightPar);
	float aspect = (float)screenWidthPar / screenHeightPar;
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustumf(-aspect, aspect, -1.0f, 1.0f, 2.0f, 100.0f);
    
	glMatrixMode(GL_MODELVIEW);
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glEnable(GL_CULL_FACE); //3
	glCullFace(GL_BACK);
    
    glDepthRangef(0.0,100.0);
	glEnable(GL_DEPTH_TEST);
	    
    glShadeModel(GL_SMOOTH);
    
	glEnable(GL_LIGHTING);
	
    glEnable(GL_LIGHT0);
	static GLfloat position[] = {0.0f, 2.0f, -2.3f, 1.0f};
	static GLfloat diffuse[] = {1.0f, 1.0f, 1.0f, 1.0f};
	static GLfloat emission[] = {0.1f, 0.1f, 0.1f, 1.0f};
	static GLfloat diffuseMaterial[] = {1.0f, 1.0f, 1.0f, 1.0f};
	static GLfloat ambient[] = {0.01f, 0.01f, 0.01f, 1.0f};
	static GLfloat ambientMaterial[] = {0.01f, 0.01f, 0.01f, 1.0f};
	static GLfloat specular[] = {1.0f, 1.0f, 1.0f, 1.0f};
	static GLfloat specularMaterial[] = {1.0f, 1.0f, 1.0f, 1.0f};
	glLightfv(GL_LIGHT0, GL_POSITION, position);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, diffuseMaterial);
	glLightfv(GL_LIGHT0, GL_AMBIENT, ambient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ambientMaterial);
	glLightfv(GL_LIGHT0,GL_SPECULAR, specular);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specularMaterial);
	glMaterialf(GL_FRONT_AND_BACK,GL_SHININESS, 115.0f);
	glMaterialfv(GL_FRONT_AND_BACK,GL_EMISSION,emission);
	glLightf(GL_LIGHT0,GL_QUADRATIC_ATTENUATION,0.1f);
	glEnable(GL_COLOR_MATERIAL); //This allows lighting and colored vertices to work simultaneously.
    
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
}

//deltaTime is the number of millis since last update
//TouchType: 1=down, 2=up, 3=move
void updateWorld(int deltaTime, float touchX, float touchY, int touchType)
{
	if(touchType>0) //if touchType is zero, there was no touch to report
	{
		if(touchType==3)
		{
			spinY += (touchX-lastTouchX)/4;
			spinX += (touchY-lastTouchY)/4;
		}
        
		if(spinX>360 || spinX<-360)
			spinX = 0;
		if(spinY>360 || spinY<-360)
			spinY = 0;
		if(spinZ>360 || spinZ<-360)
			spinZ = 0;
        
		lastTouchX = touchX;
		lastTouchY = touchY;
        
        //printf("lastTouchX:%f lastTouchY: %f touchType: %i \n",lastTouchX,lastTouchY,touchType);
	}
	/*
     myFloat += .001 * deltaTime;
     if(myFloat>(2*pi))
     myFloat = 0;
     spinX += .01 * deltaTime;
     if(spinX>360)
     spinX = 0;
     spinY += .03 * deltaTime;
     if(spinY>360)
     spinY = 0;
     */
}

void drawFrame()
{
	
          
    
    
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	glPushMatrix();
	glLoadIdentity();
	//glTranslatef((GLfloat)(cosf(myFloat)/2.0f), (GLfloat)(sinf(myFloat)/2.0f), -8 + (GLfloat)(3*sinf(myFloat)));
	glTranslatef(0, 0, -6);
	glRotatef(spinX, 1.0, 0.0, 0.0);
	glRotatef(spinY, 0.0, 1.0, 0.0);
	glRotatef(spinZ, 0.0, 0.0, 1.0);
	glVertexPointer(3, GL_FLOAT, 0, vertices);
	glNormalPointer(GL_FLOAT, 0, normals);
	glColorPointer(4, GL_UNSIGNED_BYTE, 0, colors);
    
	//glEnable(GL_TEXTURE_2D);                                            //2
	//glEnable(GL_BLEND);                                                 //3
	//glBlendFunc(GL_ONE, GL_SRC_COLOR);                                  //4
	//glBindTexture(GL_TEXTURE_2D,0);                        //5
	//glTexCoordPointer(2, GL_FLOAT,0,textureCoords);                     //6
	//glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    
    
    /////////////////!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ////!!!!!!!!!!!!///
    //////////////////////!!!!!!!!!!!!!!!!!!!    
	glDrawElements(GL_TRIANGLES, numberOfIndices, GL_UNSIGNED_SHORT, indices);
    //glDrawElements(GL_TRIANGLES, sizeof(cubeIndices)/sizeof(cubeIndices[0]),GL_UNSIGNED_SHORT, cubeIndices);
	glPopMatrix();
}