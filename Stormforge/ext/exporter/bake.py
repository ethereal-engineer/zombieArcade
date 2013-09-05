#!BPY

"""
Name: 'Bake'
Blender: 249
Group: 'Script'
Tooltip: 'Bake the current selected objects.'
"""

import os
import sys
import struct
import math
import string
import Blender
import platform
import shutil
import uvcalc_smart_project_Mod

from Blender 					 import Material
from Blender 					 import Texture
from Blender 					 import Window
from Blender					 import Object
from Blender 					 import NMesh
from Blender				 	 import Mathutils
from Blender.Scene	 	 import Render

from Blender.Draw			 import *
from Blender.BGL  		 import *
from Blender.Window 	 import *
from Blender.Mathutils import *


#=================================================================================
#
# -- HOW TO USE THIS SCRIPT --
#
#
# OUTPUT_DIR			: Wherever you want the baked textured to output.
#
# BAKE_SHADOW_MAP	: 0 or >= 1, specify if you want to bake shadow map only
#										or Full Render. Please take note that the bake result will
#										take in consideration your render & light settings ( Ambient
#										occlusion, shadow samples etc... )
#
# BAKE_TEX_CHANNEL: Any number between 0 to 9, in example if I do a full render
#										my engine is using the texture channel 0 as diffuse so I 
#										would set it to 0. If a want to bake shadow map I would put
#										the value to 1 cuz my engine use the 2th texture channel as
#										shadowmap.
#
# BAKE_MAX				: What is the biggest map size that can be used. Please take 
#										note that the script will calculate a factor based on the largest
#										object diameter in the scene, then apply this factor to every
#										other objects.
#
#
# If you want to run this script get the uvcalc_smart_project_Mod.py that I
# found at this address: http://blenderartists.org/forum/showthread.php?t=92364 
# and put it in your .script directory, then load this script then:
#
# - Select everything that you want to bake from Layer #1 (including lights).
#
# - Im assuming that the UV channel that you want to bake is called UVTex
#   (since nobody change that name anyway...)
#
# - I will do a copy of everything selected in Layer #1 to Layer #2 in order
#		to don't change the original scene (if something get messed up)
#
# - Then set the script settings then "Execute Script". If you choose to bake
#		shadowmap, the script will automatically link the shadow map to the appropriate
#		channel (BAKE_TEX_CHANNEL) of your original mesh. If you choose to do a full render,
#		the result scene will be in Layer #2 ( convenient for game exporter ~like mine~ since
#		everything is linked into a single layer )
#
# Please take note, since alot of people are abusing of the 20 char name limit,
# the script will rename the original objects to avoid duplicates (as every mesh
# and materials need to have a different name in order to be linked properly, as
# any mesh can share a the same shadowmap or full render result. By the way if
# someone want to create an interface for it be my guest ;)
#
# Enjoy!
#
# http://www.youtube.com/sio2interactive/
#
# For questions or (constructive) comments: sio2interactive@gmail.com
#=================================================================================

OUTPUT_DIR				= "/Users/adam/Documents/Projects/ZombieArcade/bake/"
BAKE_SHADOW_MAP	 	= 0
BAKE_TEX_CHANNEL	= 0
BAKE_MAX 			= 512
BAKE_STATIC_SIZE	= 0
BAKE_RATIO 			= 0.0

Blender.uvcontrol = 0
Blender.uvspli	  = 66
Blender.uvshsp		= 1
Blender.uvsa			= 1
Blender.uvim			= 0.01
Blender.uvfh			= 1
Blender.uvfhq			= 100
Blender.uvvi			= 1
Blender.uvaw			= 1


def distance3d(v1, v2):

	v = []
	v.append( v1[0] - v2[0] )	
	v.append( v1[1] - v2[1] )		
	v.append( v1[2] - v2[2] )

	return math.sqrt( ( v[0] * v[0] ) + ( v[1] * v[1] ) + ( v[2] * v[2] ) )


def BAKE_ALL():

	scn = Blender.Scene.GetCurrent()
		
	scn.setLayers( [1] )
	Blender.Redraw()
	
	
	if( not len( Blender.Object.GetSelected() ) ):
		exit
		
	
	# Convert triangles to quads ( better to bake )
	for obj in scn.objects:
		
		if( obj.getType() == "Mesh" and obj.layers[0] == 1 and obj.isSelected() ):
			
			mesh = obj.getData( False, True )
			
			for face in mesh.faces:
				face.sel = 1
			
			mesh.triangleToQuad( 0 )
			mesh.remDoubles( 0.001 )
			mesh.update()
		

	obj_act = Blender.Object.GetSelected()
		
	if( len( obj_act ) ):	

		# Duplicate
		Blender.Object.Duplicate( 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 )
	else:
		return
		
	
	for obj in Blender.Object.GetSelected():
		obj.layers = [2]
		
	
	scn.setLayers( [2] )
	scn.objects.selected = []
	Blender.Redraw()
	
	scn = Blender.Scene.GetCurrent()



	# Bake Ratio
	if( not BAKE_STATIC_SIZE ):
		
		tmp = 0.0
		for obj in scn.objects:
	
			if( obj.getType() == "Mesh" and obj.layers[0] == 1 ):
			
				bb = obj.getBoundBox()
				
				i  = 0
				j  = 0
				l  = 0
				dd = 0
				
				for i in range( 7 ):
				
					for j in range( 8 ):
					
						dd = ( distance3d( bb[i], bb[j] ) )
					
						if( dd > l ):
							l = dd
			
				if( l > tmp ):
					tmp = l
		
		BAKE_RATIO = BAKE_MAX	/ tmp
	
	
	for obj in scn.objects:
		
		if( obj.getType() == "Mesh" and obj.layers[0] == 2 ):
		
			obj.select( 1 )

			me = obj.getData( False, True )
			
			try:
				
				for tex in me.materials[0].getTextures():
					
					if( tex != None ):
						
						tex.texco = Blender.Texture.TexCo["UV"]
						tex.uvlayer = "UVTex"	
			except:
				
				continue

			me.addUVLayer( "bake" )
			me.activeUVLayer = "bake"
			me.renderUVLayer = "bake"
			
			
			if( not BAKE_STATIC_SIZE ):
				
				bb = obj.getBoundBox()
				
				i  = 0
				j  = 0
				l  = 0
				dd = 0
				
				for i in range( 7 ):
				
					for j in range( 8 ):
					
						dd = ( distance3d( bb[i], bb[j] ) )
					
						if( dd > l ):
					
							l = dd
	
				
				l = l * BAKE_RATIO
				l = pow( 2, math.ceil( math.log( l ) / math.log( 2 ) ) )
				
	
				if( l == 32 ):
					s = 32
				
				elif( l == 64 ):
					s = 64
				
				elif( l == 128 ):
					s = 128
				
				elif( l == 256 ):
					s = 256
				
				elif( l == 512 ):
					s = 512
				
				else:
					s = 1024
	
			else:			
				
				# Static size			
				s = BAKE_MAX
			
			if( BAKE_SHADOW_MAP ):
				me.materials = []
			
			img = Blender.Image.New( obj.getName() + ".tga", s, s, 24 )
			img.setFilename( OUTPUT_DIR + obj.getName() + ".tga" )

			
			for f in me.faces:
				f.image = img			

			me.update()

			uvcalc_smart_project_Mod.main1( 1 )
			
			obj.select( 0 )			
			Blender.Redraw()
			

	for obj in scn.objects:
		if( obj.layers[0] == 2 ):
			obj.select( 1 )
	
	
	Blender.Redraw()
	
	ctx = scn.getRenderingContext()
	ctx.imageType = Render.TARGA
	ctx.bake()


	for obj in scn.objects:
		
		if( obj.getType() == "Mesh" and obj.layers[0] == 2 ):
			
			me = obj.getData( False, True )
									
			for f in me.faces:
				img = f.image
				
				try:
					img.save()
				
				except:
					print "ERROR: Unable to save image: %s", img.filename
					
				break	
			
			
			if( not BAKE_SHADOW_MAP ):
				
				for uv in me.getUVLayerNames():			
					if( uv != "bake" ):
						me.removeUVLayer( uv )
						
	
				me.activeUVLayer = "bake"
				me.renderUVLayer = "bake"
			
				i = 0
				for tex in me.materials[0].getTextures():
					me.materials[0].clearTexture(i)
					i = i + 1
			
			else:
								
				scn.setLayers( [1] )
				Blender.Redraw()
						
				name = obj.getName()
				tmp_obj = Blender.Object.Get( name[ :len(name)-4 ] )
								
				me = tmp_obj.getData( False, True )
				
				uv_channel = me.getUVLayerNames()
				for uv in uv_channel:
					if( uv == "bake" ):
						me.removeUVLayer( "bake" )	
				
				me.addUVLayer( "bake" )
				me.activeUVLayer = "bake"
				me.renderUVLayer = "bake"
				
				for f in me.faces:
					f.image = img			
	
				me.update()
	
				tmp_obj.select( 1 )
				uvcalc_smart_project_Mod.main1( 1 )	
				tmp_obj.select( 0 )		
				
				scn.setLayers( [2] )
				Blender.Redraw()							
			
			
			me.update()
			
			
			tex = Blender.Texture.New( obj.getName() )
			tex.setType("Image")
			
			try:
				
				img = Blender.Image.Load( img.filename )
				tex.image = img
				
			except:
				
				print "ERROR: Unable to load image: %s" % img.filename
			
			me.materials[0].setTexture( BAKE_TEX_CHANNEL, tex, 0, 0 )			
			me.update()
			
			obj.select( 0 )			
			Blender.Redraw()
			
BAKE_ALL()