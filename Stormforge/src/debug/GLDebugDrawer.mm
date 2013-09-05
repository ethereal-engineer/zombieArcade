/*
 *  GLDebugDrawer.mm
 *  Untitled
 *
 *  Created by rom on 5/9/09.
 *  Copyright 2009 SIO2 Interactive. All rights reserved.
 *
 */


#include "GLDebugDrawer.h"
#include "SFGL.h"
#include "SFColour.h"

GLDebugDrawer::GLDebugDrawer()
:m_debugMode(0)
{
   
}


void GLDebugDrawer::drawLine(const btVector3& from,const btVector3& to,const btVector3& color)
{
	float tmp[ 6 ] = { from.getX(), from.getY(), from.getZ(),
					   to.getX()  , to.getY()  , to.getZ() };
    
	glLineWidth( 1.0f );
	
    SFGL::instance()->glPushMatrix();
	{  
        SFGL::instance()->glColor4f(Vec4Make(color.getX(), color.getY(), color.getZ(), 1.0f));
        SFGL::instance()->glVertexPointer(3, GL_FLOAT, 0, &tmp);
		SFGL::instance()->glDrawArrays(GL_LINES, 0, 2);
	}
	SFGL::instance()->glPopMatrix();      
}


void GLDebugDrawer::setDebugMode(int debugMode)
{
   m_debugMode = debugMode;
}


void GLDebugDrawer::draw3dText(const btVector3& location,const char* textString)
{

}


void GLDebugDrawer::reportErrorWarning(const char* warningString)
{
   printf("\n%s\n",warningString);
}

void GLDebugDrawer::drawContactPoint(const btVector3& pointOnB,const btVector3& normalOnB,btScalar distance,int lifeTime,const btVector3& color)
{

}
