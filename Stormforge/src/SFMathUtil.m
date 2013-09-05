//
//  SFMathUtil.m
//  ZombieArcade
//
//  Created by Adam Iredale on 11/12/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "SFMathUtil.h"
#import "SFUtils.h"
#import "SF3DObject.h"

@implementation SFMathUtil

+(float)getHypotenuse:(float)sideA sideB:(float)sideB{
	return sqrt(powf(sideA, 2.0f) + powf(sideB, 2.0f));
}

//+(float)get2DDistance:(vec2 *)from to:(vec2 *)to{
//	return [self getHypotenuse:(to->y - from->y) 
//						 sideB:(to->x - from->x)];
//}

//+(void)sfbtVector3ToSFVec:(btVector3*)vecIn vecOut:(SFVec*)vecOut{
//	vecOut->x = vecIn->getX();
//	vecOut->y = vecIn->getY();
//	vecOut->z = vecIn->getZ();
//}

+(float)getFaceTargetRotationZ:(SF3DObject*)originObject targetObject:(SF3DObject*)targetObject{
    //mainly used for turning objects to meet another object -
    //this considers the current vector and the "other" vector
    //to represent direction only and hence calculates the 
    //difference in angle between them for the Z axis
    //(kinda like the angle between looking left or right with your head)
    
	//get origin forward vector
	SFVec *originForward = new SFVec([originObject forwardDirection]);
	//get target dir vector
    SFVec *targetDirection = [targetObject transform]->loc()->directionTo([originObject transform]->loc());
	//get angular difference on Z axis
	
    //difference between the two directions (current and where we want to be rotated to)
    //this is now the normalised difference between the two 
    //vectors - that is, the difference in angles only, not
    //magnitudes
    SFVec *diffVec = originForward->directionTo(targetDirection);
    delete originForward;
	float angDiffZ;
   
    SFVec *originLoc = [originObject transform]->loc();
    SFVec *targetLoc = [targetObject transform]->loc();
    
	//there's probably a better way (with more thought involved) but I just need this done!
	//A|B
	//_x_
	//D|C
	//also note that the X is the target
	
	float opp, adj, ang;
	
	if ((originLoc->x() > targetLoc->x()) and (originLoc->y() > targetLoc->y())) {
		//B 
		opp = originLoc->x() - targetLoc->x();
		adj = originLoc->y() - targetLoc->y();
		//B also needs -90 degrees!
		ang = 90 - (atan(opp/adj) * SF_RAD_TO_DEG);
	} else if ((originLoc->x() > targetLoc->x()) and (originLoc->y() < targetLoc->y())) {
		//C
		opp = targetLoc->y() - originLoc->y();
		adj = originLoc->x() - targetLoc->x();
		ang = 90 + (atan(opp/adj) * SF_RAD_TO_DEG);
	} else if ((originLoc->x() < targetLoc->x()) and (originLoc->y() < targetLoc->y())){
		//D
		opp = targetLoc->x() - originLoc->x();
		adj = targetLoc->y() - originLoc->y();
		ang = 180 + (atan(opp/adj) * SF_RAD_TO_DEG);
	} else if ((originLoc->x() < targetLoc->x()) and (originLoc->y() > targetLoc->y())){
		//A
		opp = originLoc->y() - targetLoc->y();
		adj = targetLoc->x() - originLoc->x();
		ang = 270 + (atan(opp/adj) * SF_RAD_TO_DEG);
	} else if ((originLoc->x() == targetLoc->x()) and (originLoc->y() > targetLoc->y())){
		//A|B
		ang = 0;
	} else if ((originLoc->y() == targetLoc->y()) and (originLoc->x() > targetLoc->x())){
		//B
		//_
		//C
		ang = 90;
	} else if ((originLoc->x() == targetLoc->x()) and (originLoc->y() < targetLoc->y())){
		//D|C
		ang = 180;
	} else if ((originLoc->y() == targetLoc->y()) and (originLoc->x() < targetLoc->x())){
		//A
		//_
		//D
		ang = 270;
	} else {
		//equal
		ang = 0;
	}

	if (ang > 180.0f) {
		ang = ang - 360.0f;
	}
	
	angDiffZ = ([originObject getOrientationYPR].x * SF_RAD_TO_DEG) + ang;
	return angDiffZ;
}

@end
