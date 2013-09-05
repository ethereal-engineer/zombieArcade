//
//  ZATargetLogic_Zombie.m
//  ZombieArcade
//
//  Created by Adam Iredale on 23/11/09.
//  Copyright 2009 Stormforge Software. All rights reserved.
//

#import "ZATargetLogic_Zombie.h"
#import "ZATarget.h"
#import "SFUtils.h"
#import "SFGameEngine.h"
#import "SFScene.h"
#import "SFDebug.h"

#define REACH_DISTANCE 0.35f
#define NOTICABLE_MOVEMENT_DISTANCE 0.02f
#define ZOMBIE_AT_TARGET_IDLE 5
#define MAX_STALE_TIME 7.0f
#define PAINT_DESTINATION DEBUG_SFTARGETLOGIC_ZOMBIE

@implementation ZATargetLogic_Zombie

-(void)resetDestination{
    [_currentDestination release];
    [_currentAction release];
    _currentAction = nil;
    _currentDestination = nil;
    _atTarget = NO;
}

-(void)clearObjectives{
    [super clearObjectives];
    [self resetDestination];
}

-(void)performIdleFor:(float)seconds{
    [[self target] goIdle];
    [[self target] stopMoving];
    [self targetSleep:seconds];
}

-(void)goToDestination{
    
	//get the distance to the object (x,y only)
	float distanceToObject = [[self target] transform]->loc()->distanceFrom([_currentDestination transform]->loc(), 2);

    //if it is out of our reach we want to get closer
    if (_enemyAcquired) {
        _atTarget = YES;
        [[self target] attack];
        _enemyAcquired = NO;
    } else if ([[self target] continueTurn]) {
        //we have continued our turn - nothing else to do
        
    } else if (distanceToObject > REACH_DISTANCE) {
		_atTarget = NO;
        
        //we'll assume that the camera's clip distance represents the furthest a 
        //target can be away from us and scale the accuracy and speed accordingly
        if (!_furthestDistance) {
            _furthestDistance = [[[[self sm] currentScene] camera] clipEnd];
        }
        //get the directional difference to the object - that is,
        //the direction of the object from us subtracted from our own direction
        //again, that is... the amount we need to turn (in direction vector)
        vec3 dirDiff = [[self target] getTargetDirectionDiff:_currentDestination];
       
        SFVec *directionOfObject = [[self target] transform]->loc()->directionTo([_currentDestination transform]->loc());
        
        float targetAngle = atan2f(directionOfObject->y(), directionOfObject->x());
        
        float myAngle = atan2f([[self target] transform]->dir()->y(), [[self target] transform]->dir()->x());

        float scaledAccuracy = MIN((90.0f * SF_DEG_TO_RAD) / (distanceToObject * distanceToObject), 90.0f * SF_DEG_TO_RAD);
        
#if PAINT_DESTINATION
        vec4 destColour;
#endif
        
        delete directionOfObject;
        
        float actionAngle = targetAngle - myAngle;    

        if (ABS(actionAngle) > SF_PI) {
            //it's quicker the other way
            if (actionAngle < 0.0f) {
                actionAngle += (2 * SF_PI); 
            } else {
                actionAngle = (2 * SF_PI) - actionAngle;
            }

        }
        
        sfDebug(DEBUG_SFTARGETLOGIC_ZOMBIE, "ma: %.2f ta: %.2f aa: %.2f ang: %f\n", 
                myAngle, 
               targetAngle, 
               actionAngle,
               scaledAccuracy);
        
        if (ABS(actionAngle) > scaledAccuracy) {
            //the difference in angle is not within our requirements so we have to make a turn
            //printf("dif:%f ,dirdif:%f %f, scac: %f\n", distanceToObject, dirDiff.x, dirDiff.y, scaledAccuracy);
            //basic idea behind this complex line - 
            //we want to turn quicker if we are far from the the direction of the target, but not quicker
            //than max turn speed and we want to turn slower if we are closer so we don't overshoot
            //and we want to turn in the quickest direction - later

            //the number of steps we will break this up into
            //assuming the turnspeed info means seconds per rotation
            float renderPassesForOneRotation = [[[self sm] currentScene] timeToRenderPasses:_turnSpeed];
            float renderPassesForThisRotation = (actionAngle * renderPassesForOneRotation) / (2 * SF_PI);
            int stepCount = MAX(ABS(round(renderPassesForThisRotation)), 1);
            sfDebug(DEBUG_SFTARGETLOGIC_ZOMBIE, "stepc: %d", stepCount);
            [[self target] startTurn:actionAngle * SF_RAD_TO_DEG steps:stepCount];
#if PAINT_DESTINATION
            destColour = COLOUR_HOT_PINK;
#endif
        } else {
            float movementFromLast = _lastLoc->distanceFrom([[self target] transform]->loc(), 2);
            
            if (movementFromLast < NOTICABLE_MOVEMENT_DISTANCE) {
                sfDebug(DEBUG_SFTARGETLOGIC_ZOMBIE, "Stale move noted for %f distance", movementFromLast); 
                [self noteStaleMove];
                //don't be boring - check if we are stuck
                if ([self isStale]) {
                    sfDebug(DEBUG_SFTARGETLOGIC_ZOMBIE, "Move is stale, changing...");
                    [self resetDestination];
                    [self resetStaleCount];
                    return;
                }
            } else {
                [self resetStaleCount];
            }
            
            //keep track of our last location
            _lastLoc->setVector([[self target] transform]->loc());
            //we are at the correct angle to be facing our target - we should move forwards
            [[self target] moveForward:[[self scom] getGradeScaledAmount:_forwardSpeed delta:_forwardSpeedDelta]];
#if PAINT_DESTINATION
            destColour = COLOUR_GOLD;
#endif
        }
#if PAINT_DESTINATION
        //light it up so we can see
        GLfloat x, y, z;
        sio2Project([_currentDestination transform]->loc()->x(),
                    [_currentDestination transform]->loc()->y(),
                    [_currentDestination transform]->loc()->z(),
                    [[[self scene] selectedCamera] matModelView],
                    [[[self scene] selectedCamera] matProjection],
                    [[SFGameEngine mainViewController] matViewPort], &x, &y, &z);
        SFGL::instance()->glPushMatrix();
        SFGL::instance()->enter2d(0.0f, 1000.0f);
        [SFUtils drawGlBox:CGRectMake(x - 5, y + 5, 10, 10) colour:destColour];
        SFGL::instance()->leave2d();
        SFGL::instance()->glPopMatrix();
#endif
	} else {
		//at objective, but no enemy acquired... just idle, I guess... duuuuuuuhhhh brains....
        _atTarget = YES;
        //if the objective action is idle then we idle
        if ([_currentAction isEqualToString:objectiveActionIdle]) {
            [self performIdleFor:ZOMBIE_AT_TARGET_IDLE];
            [_objectiveActions pop];
            [_objectives pop];
        } else if ([_currentAction isEqualToString:objectiveActionMoveOn]) {
            //else if it is move on, we move on immediately
            //and pop the objective
            [_objectiveActions pop];
            [_objectives pop];
        }
        //in all cases, reset what we are doing
        [self resetDestination];
	}
}

-(void)wakeUp{
	_state = SF_TARGETLOGIC_NOP;
}

-(void)targetSleep:(int)sleepSeconds{
	//sets the target busy for a little bit and allows the game engine to do other things
	_state = SF_TARGETLOGIC_BUSY;
	[self resetStaleCount];
	[self performSelector:@selector(wakeUp) withObject:nil afterDelay:sleepSeconds];
}

-(void)chooseDestination{
    //if our objectives are empty, push on a random waypoint first
    if ([_objectives isEmpty]) {
        id randomWayPoint = [[[self sm] currentLogic] selectRandomWayPoint];
        if (randomWayPoint) {
            [self pushObjective:randomWayPoint objectiveAction:objectiveActionIdle];
        }
    }
    
    if (![_objectives isEmpty]) {
        //as soon as we have objectives, we execute them first
        _currentDestination = [[_objectives peek] retain];
        sfDebug(TRUE, "Chose new destination: %s", [_currentDestination UTF8Name]);
        _currentAction = [[_objectiveActions peek] retain];
    } else {
        //sleep this target for a little, putting it in idle animation
        sfDebug(TRUE, "No waypoints - sleeping for a little...");
        [[self target] goIdle];
        [[self target] stopMoving];
        [self targetSleep:10];
    }
}

-(void)makeChoices{
	[super makeChoices];
	//I am a zombie... what do I do?
	if (_state == SF_TARGETLOGIC_NOP) {
		
		if (![[self target] getOnGround]) { //only make moves on ground
			return;
		}
        
        if (!_currentDestination) {
            [self chooseDestination];
        }
        
        //go to our new destination
        if (_currentDestination) {
            [self goToDestination];
        }
	}
}

-(void)cleanUp{
    delete _lastLoc;
    [super cleanUp];
}

-(id)initWithDrone:(id)drone dictionary:(NSDictionary *)dictionary{
    self = [super initWithDrone:drone dictionary:dictionary];
    if (self != nil) {
        _lastLoc = new SFVec(3);
        _maxStaleCount = -1;
    }
    return self;
}

-(int)getMaxStaleCount{
    if (_maxStaleCount < 0) {
        _maxStaleCount = [[self scene] timeToRenderPasses:MAX_STALE_TIME];
    }
	return _maxStaleCount;
}

@end
