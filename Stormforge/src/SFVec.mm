/*
 *  SFVec.mm
 *  ZombieArcade
 *
 *  Created by Adam Iredale on 25/03/10.
 *  Copyright 2010 Stormforge Software. All rights reserved.
 *
 */

#include "SFVec.h"
#include "SFDefines.h"

bool SFVec::setFloatsUsingXYZW(){
    //returns true if this class uses
    //set floats in the order x,y,z,w
    //and false if in the order w,x,y,z
    return true;
}
   
int SFVec::size(){
    return this->_count * sizeof(GLfloat);
}

int SFVec::length(){
    return this->_count;
}

const char* SFVec::className(){
    return "SFVec";
}

SFVec::SFVec(vec2 vectorIn){
    this->setup(2);
    this->setVec2(vectorIn);
}

SFVec::SFVec(vec3 vectorIn){
    this->setup(3);
    this->setVec3(vectorIn);
}

SFVec::SFVec(vec4 vectorIn){
    this->setup(4);
    this->setVec4(vectorIn);
}

SFVec::SFVec(){
    this->setup(4); //default to 4
}

SFVec::SFVec(SFVec *vec){
    this->setup(vec->length());
    this->setVector(vec);
}

SFVec::SFVec(btVector3 vectorIn){
    this->setup(3);
    this->setBtVector3(vectorIn);
}

SFVec::SFVec(CGPoint pointIn){
    this->setup(2);
    this->setCGPoint(pointIn);
}

SFVec::SFVec(GLfloat *floats, int count){
    this->setup(count);
    this->setFloats(floats, count);
}

void SFVec::setup(int count){
    this->_floats = NULL;
    this->_count = count;
    this->_floats = (GLfloat*)malloc(count * sizeof(GLfloat));
    this->reset();
    this->_set = (int)&this->_floats;
}

SFVec::SFVec(int count){
    this->setup(count);
}

SFVec::~SFVec(){
    if (this->_set != (int)&this->_floats){
        printf("USE THIS TO FIX FREE/MALLOC ERRORS\n");
    }
    this->_set = 0;
    free(this->_floats);    
}


//manipulators
void SFVec::add(SFVec *vec){
    for (int i = 0; i < vec->length(); ++i) {
        this->_floats[i] += vec->floatArray()[i];
    }
}

void SFVec::subtract(SFVec *vec){
    for (int i = 0; i < vec->length(); ++i) {
        this->_floats[i] -= vec->floatArray()[i];
    }
}

bool SFVec::equals(SFVec *vec){
    return memcmp(this->_floats, vec->floatArray(), this->size()) == 0;
}

bool SFVec::equals(vec3 vectorIn){
    return memcmp(this->_floats, &vectorIn, sizeof(vec3)) == 0;
}

bool SFVec::equals(vec4 vectorIn){
    return memcmp(this->_floats, &vectorIn, this->size()) == 0;
}

void SFVec::scale(GLfloat factor){
    for (int i = 0; i < this->_count; ++i) {
        this->_floats[i] *= factor;
    }    
}

void SFVec::reset(){
    memset(this->_floats, 0, this->size());
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::addW(GLfloat w){
    this->setW(this->w() + w);
}

void SFVec::addX(GLfloat x){
    this->setX(this->x() + x);
}

void SFVec::addY(GLfloat y){
    this->setY(this->y() + y);
}

void SFVec::addZ(GLfloat z){
    this->setZ(this->z() + z);
}

void SFVec::rotate3D(GLfloat x, GLfloat z, GLfloat d){
    GLfloat cos_a_x = cosf(x * SF_DEG_TO_RAD );
    this->_floats[0] += d * cos_a_x * sinf(z * SF_DEG_TO_RAD); 
    this->_floats[1] -= d * cos_a_x * cosf(z * SF_DEG_TO_RAD);
    this->_floats[2] += d * sinf(x * SF_DEG_TO_RAD);
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::xySwap(){
    GLfloat tmp;
    tmp = this->_floats[0];
    this->_floats[0] = this->_floats[1];
    this->_floats[1] = tmp;
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

GLfloat SFVec::normalise(){
    //normalises the vector
    //i.e. - scales it to a magnitude of 1.0
    //and returns the magnitude
    GLfloat magnitude = this->magnitude();
    
    //don't try this on an empty vector
    if (!magnitude) {
        return 0.0f;
    }
	
    this->scale(1.0f / magnitude);
    
    return magnitude;    
}

void SFVec::screenRotation2D(){
    this->xySwap();
    this->_floats[1] *= -1;
    this->_floats[1] += 480.0f; //screen width
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

//copies
SFVec* SFVec::copy(){
    return new SFVec(this);
}

//news
SFVec* SFVec::directionTo(SFVec *vec){
    //returns a vector representing the direction
    //from this vector to the destination vector
    SFVec *direction = vec->copy();
    direction->subtract(this);
    direction->normalise();
    return direction;    
}

SFVec* SFVec::diff(SFVec *vec){
    SFVec *diffVec = this->copy();
    diffVec->subtract(vec);
    return diffVec;
}

//info
GLfloat SFVec::w(){
    assert(this->_count > 3);
    return this->_floats[3];
}

GLfloat SFVec::y(){
    assert(this->_count > 1);
    return this->_floats[1];
}

GLfloat SFVec::z(){
    assert(this->_count > 2);
    return this->_floats[2];
}

GLfloat SFVec::x(){
    return this->_floats[0];
}

GLfloat* SFVec::floatArray(){
    return this->_floats;
}

GLfloat SFVec::magnitude(int dimensions){
    GLfloat sum = 0;
    for (int i = 0; i < dimensions; ++i) {
        sum += (this->_floats[i] * this->_floats[i]);
    }
    return sqrt(sum);    
}

GLfloat SFVec::magnitude(){
    return this->magnitude(this->_count);
}

GLfloat SFVec::distanceFrom(SFVec *vec, int dimensions){
    if (!vec) {
        return -1;
    }
    SFVec *diffVec = this->diff(vec);
    GLfloat mag = diffVec->magnitude(dimensions);
    delete diffVec;
    return mag;    
}

GLfloat SFVec::distanceFrom(SFVec *vec){
    return this->distanceFrom(vec, this->_count);
}

void SFVec::printContent(){
    for (int i = 0; i < this->_count; ++i) {
        printf("%.2f\t", this->_floats[i]);
    }
}

btVector3 SFVec::getBtVector3(){
    return btVector3(this->_floats[0], this->_floats[1], this->_floats[2]);
}

vec2 SFVec::getVec2(){
    return Vec2Make(this->x(), this->y());
}

vec3 SFVec::getVec3(){
    return Vec3Make(this->x(), this->y(), this->z());
}

vec4 SFVec::getVec4(){
    return Vec4Make(this->x(), this->y(), this->z(), this->w());
}

void SFVec::setVec2(vec2 vectorIn){
    memcpy(this->_floats, &vectorIn, sizeof(vec2));
}

void SFVec::setVec3(vec3 vectorIn){
    memcpy(this->_floats, &vectorIn, sizeof(vec3));
}

void SFVec::setVec4(vec4 vectorIn){
    memcpy(this->_floats, &vectorIn, sizeof(vec4));
}

void SFVec::setVector(SFVec *vec){
    memcpy(this->_floats, vec->floatArray(), vec->size());
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::setBtVector3(btVector3 vectorIn){
    this->_floats[0] = vectorIn.getX();
    this->_floats[1] = vectorIn.getY();
    this->_floats[2] = vectorIn.getZ();
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}
void SFVec::setCGPoint(CGPoint pointIn){
    memcpy(this->_floats, &pointIn, sizeof(CGPoint));
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::setFloats(GLfloat* floats, int count){
    if (this->setFloatsUsingXYZW()) {
        memcpy(this->_floats, floats, sizeof(GLfloat) * count);
        //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
    } else {
        //need wxyz order
        int floatIndexOffset;
        for (int i = 0; i < count; ++i) {
            floatIndexOffset = (i + 3) % 4;
            this->_floats[floatIndexOffset] = floats[i];
            //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
        }   
    }
}

void SFVec::setX(GLfloat x){
    this->_floats[0] = x;
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::setY(GLfloat y){
    assert(this->_count > 1);
    this->_floats[1] = y;
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::setZ(GLfloat z){
    assert(this->_count > 2);
    this->_floats[2] = z;
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}

void SFVec::setW(GLfloat w){
    assert(this->_count > 3);
    this->_floats[3] = w; 
    //printf("%x floats now %x->%x\n", this, &this->_floats, this->_floats);
}
