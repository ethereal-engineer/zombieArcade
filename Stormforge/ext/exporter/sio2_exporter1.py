#!BPY

"""
Name: 'SIO2 Exporter v1.4.1 (.sio2)...'
Blender: 249.2
Group: 'Export'
Tooltip: 'Export the current scene to SIO2 (.sio2)'
"""


"""

	Please take note that since 1.4.0, SIO2 have an optimizer
	to convert triangles to triangle strips. In order to use
	it with the OP button of the exporter do the following:
	
	Copy the executable and paste it inside the blender.app
	package in the same directory as the blender executable.

	Ex:
		
	/Applications/blender/blender.app/Contents/MacOS/optimizer

	In addition, sometimes triangle strips uses more indices than
	triangles, because all the strips are stiched together. In this
	case the exporter will automatically select the best result for
	the geometry. Also be carefull using the optimizer with physic,
	as the triangle might be degenerated. It is suggested to not
	use the optimizer on static triangle mesh.

"""


import os
import sys
import struct
import math
import Blender
import platform
import shutil
import bpy
import zipfile

from Blender 					 import Texture
from Blender 					 import Window
from Blender					 import Object
from Blender					 import Armature
from Blender					 import Mesh
from Blender				 	 import Mathutils
from Blender					 import Ipo
from Blender					 import IpoCurve
from Blender           import Constraint

from Blender.Draw			 import *
from Blender.BGL  		 import *
from Blender.Window 	 import *
from Blender.Mathutils import *


SIO2_INTERNAL_NAME	   					= "SFBlendExport"
SIO2_VERSION_MAJOR	   					= 1
SIO2_VERSION_MINOR	   					= 0
SIO2_VERSION_PATCH	   					= 0

EVENT_EXIT 					   					= 0
EVENT_PATH_CHANGE 	  				  = 1
EVENT_EXPORT				 					  = 2
EVENT_DIR_SELECT		  				  = 3
EVENT_TOGGLE_UPDATE	   					= 4
EVENT_TOGGLE_NORMALS   					= 5
EVENT_TOGGLE_OPTIMIZE  					= 6
EVENT_TOGGLE_VCOLOR						  = 7
EVENT_TOGGLE_ALLIPO						  = 8

RAD_TO_DEG 					   					= 57.295779

UPDATE							   					= 0
NORMALS						 	   					= 1
VCOLOR													= 0
OPTIMIZE												= 1
ALLIPO													= 1

PRECISION						   					= 3

#=========================================
# GLOBAL VARIABLES
#=========================================
error_str = ""
output		= ""


#=========================================
# DEFAULT OUTPUT PATH::REMOVE WHEN RELEASE
#=========================================
#directory = Create("/Users/adam/Desktop/")
directory = Create("")


#====================================
# VERTEX CLASS
#====================================
class vertex( object ):
	pass


#========================================
# REGISTER GUI
#========================================
def register_gui():
#========================================
	Register( draw_gui, None, event_gui )


#========================================
# DRAW RECTANGLE
#========================================
def draw_rectangle( x, y, w, h, r, g, b, a ):
#========================================

	glEnable( GL_BLEND )
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA )
	
	glColor4f( r,g,b,a )
	
	glBegin( GL_POLYGON )
	
	glVertex2i( x    , y     )
	glVertex2i( x    , y + h )
	glVertex2i( x + w, y + h )
	glVertex2i( x + w, y     )
	
	glEnd()	
	
	glDisable( GL_BLEND )


#=========================================
# RENDER THE EXPORTER GUI
#=========================================
def draw_gui():
#=========================================
	global directory


	glClearColor(0.74, 0.74, 0.74, 0.0)
	glClear(GL_COLOR_BUFFER_BIT)

	draw_rectangle( 5, 92, 400,  20, 0.6, 0.6, 0.6, 1.0 )
	draw_rectangle( 5,  6, 400,  86, 0.8, 0.8, 0.8, 1.0 )

	glColor3f( 1.0, 1.0, 1.0 )
	glRasterPos2i( 280, 98 )
	
	tmp = "%s v%d.%d.%d" % ( SIO2_INTERNAL_NAME,
													 SIO2_VERSION_MAJOR,
													 SIO2_VERSION_MINOR,
													 SIO2_VERSION_PATCH )
	Text( tmp )
	

	glPolygonMode( GL_FRONT_AND_BACK, GL_LINE )
	draw_rectangle( 5,  7, 399, 106, 0.5, 0.5, 0.5, 1.0 )
	draw_rectangle( 5,  7, 399,  86, 0.5, 0.5, 0.5, 1.0 )	
	glPolygonMode( GL_FRONT_AND_BACK, GL_FILL )

	
	glColor3f(0.0, 0.0, 0.0)
	glRasterPos2i(15, 72)
	Text("Output Directory:")

	dir_selected("/Users/adam/Desktop/")

	directory = String( "",
					   	EVENT_PATH_CHANGE,
					   	15, 45, 360, 20,
					   	directory.val, 255,
					   	"")
	
	Button( "..."   , EVENT_DIR_SELECT  	 , 375, 45,  20, 20 )
	Button( "Export", EVENT_EXPORT		     , 185, 16, 100, 20 )
	Button( "Exit"  , EVENT_EXIT           , 295, 16, 100, 20 )
	Toggle( "UP"		, EVENT_TOGGLE_UPDATE  , 15 , 16,  20, 20, UPDATE  , "Update the current SIO2 archive." )
	Toggle( "NO"		, EVENT_TOGGLE_NORMALS , 40 , 16,  20, 20, NORMALS , "Export smooth or solid normals." )
	Toggle( "OP"		, EVENT_TOGGLE_OPTIMIZE, 65 , 16,  20, 20, OPTIMIZE, "Optimize triangles to triangle strips." )
	Toggle( "VC"		, EVENT_TOGGLE_VCOLOR  , 90 , 16,  20, 20, VCOLOR  , "Bake vertex color based on the current lighting conditions." )
	Toggle( "IP"		, EVENT_TOGGLE_ALLIPO  , 115, 16,  20, 20, ALLIPO  , "Export all IPOs not only linked ones." )


#====================================
# GUI EVENTS CALLBACKS
#====================================
def event_gui( event ):
#====================================	
	global UPDATE
	global NORMALS
	global OPTIMIZE
	global VCOLOR
	global ALLIPO
	
	if( event == EVENT_EXIT					   ): Exit()
	if( event == EVENT_DIR_SELECT	 		 ): Blender.Window.FileSelector( dir_selected, "Select", "" )
	if( event == EVENT_EXPORT				   ): export()
	if( event == EVENT_TOGGLE_UPDATE   ): UPDATE   = not UPDATE
	if( event == EVENT_TOGGLE_NORMALS  ): NORMALS  = not NORMALS
	if( event == EVENT_TOGGLE_OPTIMIZE ): OPTIMIZE = not OPTIMIZE
	if( event == EVENT_TOGGLE_VCOLOR   ): VCOLOR   = not VCOLOR
	if( event == EVENT_TOGGLE_ALLIPO   ): ALLIPO   = not ALLIPO


#====================================
# DIRECTORY HAVE CHANGED
#====================================
def dir_selected( _dir ):
#====================================
	global directory

	directory.val = _dir


#====================================
# OPTIMIZE FLOAT FOR STRING
#====================================
def optimize_float( f ):
#====================================
	i = int( f )
	
	r = round( f, PRECISION )
	
	if i == r:	
		return i
	else:
		return r


#====================================
# CREATE ARCHITECTURE DIRECTORY
#====================================
def create_directory( d ):
#====================================
	
	try:
		os.mkdir( d )
		
	except:
		dummy = 0	


#====================================
# DISTANCE BETWEEN 2 VERTICES
#====================================
def distance( v1, v2 ):
#====================================

	v = []
	
	v.append( v1[0] - v2[0] )	
	v.append( v1[1] - v2[1] )		
	v.append( v1[2] - v2[2] )

	return math.sqrt( ( v[0] * v[0] ) + 
					  			  ( v[1] * v[1] ) +
								    ( v[2] * v[2] ) )	


#====================================
# CHECK TEXTURE
#====================================
def check_texture( t ):
#====================================

	global error_str
	global UPDATE
	
	t_name = ""

	if( t != None ):

		if( t.tex.type == Texture.Types.IMAGE ):

			if( t.tex.image != None ):
				
				#====================================
				# Check if the file exists
				#====================================				
				if( not os.path.exists( Blender.sys.expandpath( t.tex.image.filename ) ) ):
					
					error_str = "ERROR: Unable to find file: %s:" % t.tex.image.filename
					return "ERROR"
						
				#====================================
				# Check if the file is a valid file.
				#====================================
				t_name = t.tex.image.filename.split('\\')[-1].split('/')[-1]

				
				ogg_pos  = t_name.upper().rfind('.OGG'  )
				ogv_pos  = t_name.upper().rfind('.OGV'  )				
				tga_pos  = t_name.upper().rfind('.TGA'  )
				jpg_pos  = t_name.upper().rfind('.JPG'  )
				jpeg_pos = t_name.upper().rfind('.JPEG' )
				png_pos  = t_name.upper().rfind('.PNG'  )
				
				
				if( ogg_pos > -1 ):
						
					#====================================
					# Copy the sound file.
					#====================================
					tmp_name = output + "sound/" + t_name
								
					if( UPDATE or not os.path.exists( tmp_name ) ):
						
						shutil.copyfile( Blender.sys.expandpath( t.tex.image.filename ), tmp_name )
						
						return "sound/" + t_name


				if( ogv_pos > -1 or tga_pos   > -1 or
					  jpg_pos > -1 or  jpeg_pos > -1 or
						png_pos > -1 ):
				
					tmp_name = output + "image/" + t_name
											
					if( UPDATE or not os.path.exists( tmp_name ) ):
							
							shutil.copyfile( Blender.sys.expandpath( t.tex.image.filename ), tmp_name )

					return "image/" + t_name

	return ""


#====================================
# Function that return a vector in
# object space.
#====================================
def get_loc_obj( v, obj_mat ):
#====================================

	x  = v[0]	
	y  = v[1]
	z  = v[2]
	
	tx = 0.0
	ty = 0.0
	tz = 0.0		

	tx = ( x * obj_mat[0][0] ) + ( y * obj_mat[1][0] ) + ( z * obj_mat[2][0] )
	ty = ( x * obj_mat[0][1] ) + ( y * obj_mat[1][1] ) + ( z * obj_mat[2][1] )
	tz = ( x * obj_mat[0][2] ) + ( y * obj_mat[1][2] ) + ( z * obj_mat[2][2] )

	return tx, ty, tz


#====================================
# Get the DimXYZ of the object
# based on its bounding box, half size
# like radius.
#====================================
def get_dim( obj, mesh ):
#====================================

	dim		 = [    0.0,     0.0,     0.0 ]
	ubound = [-9999.0, -9999.0, -9999.0 ]
	lbound = [ 9999.0,  9999.0,  9999.0 ]
	
	tmp_mat = obj.getMatrix().copy()
	obj_mat = tmp_mat.identity()
	
	if( not len( mesh.verts ) ):
		dim = [ 1.0, 1.0, 1.0 ]
		return dim
	
	for v in mesh.verts:
	
		tmp = [ v.co[0], v.co[1], v.co[2] ]

		vloc = get_loc_obj( tmp , obj_mat )
	
		# min
		if vloc[0] < lbound[0]:
			lbound[0] = vloc[0]
			
		if vloc[1] < lbound[1]:
			lbound[1] = vloc[1]
			
		if vloc[2] < lbound[2]:
			lbound[2] = vloc[2]
	
	
		# max
		if vloc[0] > ubound[0]:
			ubound[0] = vloc[0]
	
		if vloc[1] > ubound[1]:
			ubound[1] = vloc[1]
			
		if vloc[2] > ubound[2]:
			ubound[2] = vloc[2]
	
	
	# DimX
	a = [ ubound[0], ubound[1], ubound[2] ]
	b = [ lbound[0], ubound[1], ubound[2] ]
	
	dim[0] = distance( a, b ) * 0.5


	# DimY
	a = [ ubound[0], ubound[1], ubound[2] ]
	b = [ ubound[0], lbound[1], ubound[2] ]
	
	dim[1] = distance( a, b ) * 0.5
	
	
	# DimZ
	a = [ ubound[0], ubound[1], ubound[2] ]
	b = [ ubound[0], ubound[1], lbound[2] ]
	
	dim[2] = distance( a, b ) * 0.5
	
	return dim


#====================================
# Function that return a if an object
# instance have been found.
#====================================
def get_instance( s ):
#====================================
	obj = 0
	us_pos = s.rfind('.')

	if( us_pos == -1 ):
		return obj

	else:
		
		try:	
			obj = Blender.Object.Get( s[:us_pos] )
		
		except:		
			obj = 0
		
	return obj


#====================================
# GET INDEX IN A SPECIFIED VBO ARRAY
#====================================
def get_index( lst, v ):
#====================================	

	for i in range( len( lst ) ):
		
		if( lst[ i ].ver == v.ver and
				lst[ i ].vno == v.vno and
				lst[ i ].vco == v.vco and				
				lst[ i ].uv0 == v.uv0 and
				lst[ i ].uv1 == v.uv1 ):
			return i
	
	return -1


#====================================
# CREATE AN OPENGL VBO
#====================================
def create_vbo( mesh ):
#====================================
	global NORMALS

	uv_channel = mesh.getUVLayerNames()

	vert_lst   = []
	vert_ind   = []	
	vbo_offset = [ 0, 0, 0, 0 ]
	vbo_size 	 = 0	
	
	cnt = 0
	for face in mesh.faces:

		for i in range( 3 ):
			
			tmp_vert = vertex()
			
			tmp_vert.cacheindex = -1

			tmp_vert.ver = Blender.Mathutils.Vector( optimize_float( face.v[i].co[0] ),
																						   optimize_float( face.v[i].co[1] ),
																							 optimize_float( face.v[i].co[2] ) )

						
			tmp_vert.vno = None
			
			if( NORMALS ):
				
				if( face.smooth ):
					tmp_vert.vno = Blender.Mathutils.Vector( optimize_float( face.v[i].no[0] ),
																									 optimize_float( face.v[i].no[1] ),
																									 optimize_float( face.v[i].no[2] ) )						
				else:
					tmp_vert.vno = Blender.Mathutils.Vector( optimize_float( face.no[0] ),
																									 optimize_float( face.no[1] ),
																									 optimize_float( face.no[2] ) )
	
			tmp_vert.vco = None
			
			if( mesh.vertexColors ):
				
				rgb = [ face.col[i][0],
								face.col[i][1],
								face.col[i][2] ]
								
				tmp_vert.vco = rgb
								
			
			tmp_vert.uv0 = None
			if( len( uv_channel ) ):
				mesh.activeUVLayer = uv_channel[0]
				tmp_vert.uv0 = Blender.Mathutils.Vector( optimize_float( face.uv[i][0] ),
																								 optimize_float( 1.0 - face.uv[i][1] ),
																								 0.0 )
			
						
			tmp_vert.uv1 = None
			if( len( uv_channel ) > 1 ):
				mesh.activeUVLayer = uv_channel[1]
				tmp_vert.uv1 = Blender.Mathutils.Vector( optimize_float( face.uv[i][0] ),
																								 optimize_float( 1.0 - face.uv[i][1] ),
																								 0.0 )
	
			if( get_index( vert_lst, tmp_vert ) == -1 ):
				vert_lst.append( tmp_vert )
				vert_ind.append( cnt      )

			cnt = cnt + 1


			#===============================
			# BOFFSET
			#===============================
			vbo_offset = [ 0, 0, 0, 0 ]
			vbo_size 	 = len( vert_lst ) * 12
			
		
			# Vertex Normals
			if( NORMALS ):
				vbo_offset[ 0 ] = vbo_size
				vbo_size = vbo_size + ( len( vert_lst ) * 12 )

			
			# Vertex Color
			if( mesh.vertexColors ):
				vbo_offset[ 1 ] = vbo_size
				vbo_size = vbo_size + ( len( vert_lst ) * 4 )
			
					
			# UV0
			if( len( uv_channel ) ):
				vbo_offset[ 2 ] = vbo_size
				vbo_size = vbo_size + ( len( vert_lst ) * 8 )

	
			# UV1			
			if( len( uv_channel ) > 1 ):
				vbo_offset[ 3 ] = vbo_size
				vbo_size = vbo_size + ( len( vert_lst ) * 8 )

	return vert_lst, vbo_size, vbo_offset, vert_ind


#====================================
# CREATE SIO2 FILE
#====================================
def create_sio2( directory, filename ):
#====================================
	
	output = zipfile.ZipFile( filename, "w", compression = zipfile.ZIP_DEFLATED )

	for( apath, dir_names, fil_names ) in os.walk( directory ):
	
		for f in fil_names:
			
			fpath = os.path.join( apath, f )
			dpath = fpath.replace( directory + "/", "" )
			output.write( fpath, dpath )
	
	output.printdir()
	output.close()


#====================================
# EXPORT SCRIPT
#====================================
def export_script( obj ):
#====================================
	
	global UPDATE
	
	script = obj.getScriptLinks( "FrameChanged" )
	
	for s in script:
		
		tmp_name = output + "script/" + s
		t = Blender.Text.Get( s )
		
		if( UPDATE or not os.path.exists( tmp_name ) ):
			
			try:
				
				shutil.copyfile( t.getFilename(), tmp_name )
			except:
				
				error_str = "ERROR: Unable to locate %s. |" % t.getFilename()
				PupMenu( error_str )
				return
				


#====================================
# EXPORT
#====================================
def export():
#====================================
	global output
	global directory
	global error_str
	global VCOLOR
	global ALLIPO
	
	error_str = ""

	#====================================
	# Start the export process.
	#====================================
	start_time = Blender.sys.time()

	
	print
	print
	print "%s v%d.%d.%d\n%s\n" % ( SIO2_INTERNAL_NAME,
															   SIO2_VERSION_MAJOR,
													 		   SIO2_VERSION_MINOR,
																 SIO2_VERSION_PATCH,
																 "Copyright (C) 2009 SIO2 Interactive" )

	#====================================
	# Get the current scene and all the
	# objects related to it.
	#====================================	
	scene   = Blender.Scene.GetCurrent()
	ctx			= scene.getRenderingContext()
	layer		= scene.getLayers()
	objects = scene.objects
	ipos		= []


	#====================================
	# SWITCH TO OBJECT MODE
	#====================================
	Window.EditMode( 0 )


	#====================================
	# CONVERT QUAD AND REMOVE DOUBLES
	#====================================
	for obj in objects:
	
		if( obj.getType() == "Mesh" and obj.layers[0] == layer[0] and obj.isSelected() ):
			
			mesh = obj.getData( False, True )
			
			for face in mesh.faces:
				face.sel = 1
			
			mesh.quadToTriangle( 0 )
			mesh.remDoubles( 0.001 )
			mesh.update()
			

	#====================================
	# BAKE VERTEX COLOR OF SELECTED OBJ.
	#====================================
	if( VCOLOR ):
		
		for obj in objects:
		
			if( obj.getType() == "Mesh" and obj.layers[0] == layer[0] and obj.isSelected() ):		
					
					mesh = obj.getData( False, True )
					
					vc = mesh.getColorLayerNames()
					
					if( len( vc ) ):
						mesh.removeColorLayer( vc[ 0 ] )	
	
					mesh = obj.getData()
					mesh.update( 0, 0, 1 )
		
		
		#===============================
		# END
		#===============================
		error_str += "Vertex Color Bake: %.3f sec." % ( Blender.sys.time() - start_time )	
		PupMenu( error_str )
		return

	
	#====================================
	# VALIDATE AND CREATE SCENE DIRECTORY
	#====================================
	if( not len( directory.val ) ):
		error_str = "ERROR: Invalid output directory. |"
		PupMenu( error_str )
		return
	
	if( directory.val[ len(directory.val) - 1 ] != "/" ):
		directory.val = directory.val + "/"


	output = directory.val + scene.getName() + "/"


	#================================
	# REMOVE THE SCENE DIRECTORY AND
	# THE .SIO2 IF ANY.
	#================================
	if( not UPDATE ):

		try:
			
			shutil.rmtree( output )
			
		except:
			dummy = 0
		
	
	try:
		os.remove( directory.val + scene.getName() + ".sio2" )
	except:
		dummy = 0

	#================================
	# MAKE SUREE WE CREATE THE SCENE
	# DIRECTORY ARCHITECTURE
	#================================		
	create_directory( output               )
	create_directory( output + "material/" )
	create_directory( output + "image/" 	 )	
	create_directory( output + "object/"   )
	create_directory( output + "camera/"   )
	create_directory( output + "sound/"    )
	create_directory( output + "lamp/"     )
	create_directory( output + "script/"   )
	create_directory( output + "ipo/"   	 )
	create_directory( output + "action/" 	 )
	

	#================================
	# CAMERA
	#================================
	for obj in objects:
		
		if( obj.getType() == "Camera" and obj.layers[0] == layer[0] and obj.isSelected() ):
			
			#================================
			# CREATING CAMERA FILE
			#================================				
			if( UPDATE or not os.path.exists( output + "camera/" + obj.getName() ) ):
				
				f = open( output + "camera/" + obj.getName(), "wb")
	
				#====================================
				# Get access to the camera structure.
				#====================================
				cam = obj.getData( False, True )
				

				#================================
				# NAME
				#================================
				buffer = "camera( \"%s\")\n{\n" % ( "camera/" + obj.getName() )
				f.write( buffer )


				#================================
				# LOCATION
				#================================
				if( optimize_float( obj.LocX ) != 0.0 or
					  optimize_float( obj.LocY ) != 0.0 or
						optimize_float( obj.LocZ ) != 0.0 ):
				
					buffer = "\tl( %s %s %s )\n" % ( optimize_float( obj.LocX ),
															 			 			 optimize_float( obj.LocY ),
															 			 			 optimize_float( obj.LocZ ) )
					f.write( buffer )	
	

				#===============================
				# ROTATION (in degree)
				#===============================
				rot	= []

				rot.append( obj.rot[0] * RAD_TO_DEG )
				rot.append( obj.rot[1] * RAD_TO_DEG )
				rot.append( obj.rot[2] * RAD_TO_DEG )
		
				if( rot[0] < 0 ): rot[0] = rot[0] + 360.0
				if( rot[1] < 0 ): rot[1] = rot[1] + 360.0
				if( rot[2] < 0 ): rot[2] = rot[2] + 360.0	
		
				if( optimize_float( rot[0] ) != 0.0 or
	 	 			  optimize_float( rot[1] ) != 0.0 or
	 	 			  optimize_float( rot[2] ) != 0.0 ):
		
					buffer = "\tr( %s %s %s )\n" % ( 90.0 - optimize_float( rot[0] ),
																		 			 optimize_float( rot[1] ),
																		 			 optimize_float( rot[2] ) )
					f.write( buffer )	

				#================================
				# DIRECTION
				#================================
				tar = ( Blender.Mathutils.Vector( 0.0, 0.0, -1.0 ) * obj.matrixWorld )
				loc = Blender.Mathutils.Vector( obj.loc[0], obj.loc[1], obj.loc[2] )
				
				dir = tar - loc
				
				dir.normalize()
								
				buffer = "\td( %s %s %s )\n" % ( optimize_float( dir.x ),
														 			 			 optimize_float( dir.y ),
														 			 			 optimize_float( dir.z ) )
				f.write( buffer )	
	
	
				#================================
				# FOV
				#================================
				deg = 360.0 * math.atan( 16.0 / cam.getLens() ) / math.pi
				buffer = "\tf( %s )\n" % optimize_float( deg )
				f.write( buffer )		
		
		
				#================================
				# ZNEAR
				#================================
				buffer = "\tcs( %s )\n" % optimize_float( cam.getClipStart() )
				f.write( buffer )


				#================================
				# ZFAR
				#================================
				buffer = "\tce( %s )\n" % optimize_float( cam.getClipEnd() )
				f.write( buffer )				


				#===============================
				# IPO
				#===============================
				if( obj.getIpo() ):
					
					ipos.append( obj.getIpo() )
						
					buffer = "\tip( \"%s\" )\n" % ( "ipo/" + obj.getIpo().getName() )
					f.write( buffer )
					
					
				#===============================
				# USER PROPERTIES
				#===============================
				properties = obj.getAllProperties()
	
				for p in properties:
	
					if( p.getType() == "STRING" ):					
						buffer = "\t%s( \"%s\" )\n" % ( p.getName(), p.getData() )
						 
					else:
						buffer = "\t%s( %s )\n" % ( p.getName(), p.getData() )					
						
					f.write( buffer )					


				#====================================
				# SCRIPTS
				#====================================
				export_script( obj )

				
				#===============================
				# CLOSE CAMERA
				#===============================
				f.write( "}\n" )
				obj.select(0)
				Blender.Redraw(1)						
				f.close()	
		

	#====================================
	# MATERIALS
	#====================================
	for obj in objects:
		
		if( obj.getType() == "Mesh" and obj.layers[0] == layer[0] and obj.isSelected() ):
			
			mesh = obj.getData( False, True )	
						
			
			if( len( mesh.materials ) ):
				
				for mat in mesh.materials:
				
					#================================
					# CREATING MATERIAL FILES
					#================================
					if( mat == None ):
						continue
								
					if( UPDATE or not os.path.exists( output + "material/" + mat.getName() ) ):
						
						f = open( output + "material/" + mat.getName(), "wb")
						
						tex_channel = mat.getTextures()	
						st0 = check_texture( tex_channel[0] ) # Diffuse
						st1 = check_texture( tex_channel[1] ) # Shadowmap
						st2 = check_texture( tex_channel[2] ) # Sound (OGG)	
						
						if( st0 == "ERROR" or
								st1 == "ERROR" or
								st2 == "ERROR" ):
									
							error_str = error_str + obj.getName() + "|"
							PupMenu( error_str )
							return
	
						#================================
						# NAME
						#================================
						buffer = "material( \"%s\" )\n{\n" % ( "material/" + mat.getName() )
						f.write( buffer )
	
	
						#================================
						# TEX0
						#================================
						flags = 0
						
						if( len( st0 ) ):
							
							# Use Mipmap
							if( tex_channel[0].tex.imageFlags & Texture.ImageFlags["MIPMAP"] ):
								flags = flags | 1
								
							# Clamp to Edge
							if( tex_channel[0].tex.getExtend() == "Clip" ):
								flags = flags | 2

							buffer = "\ttfl0( %s )\n" % flags
							f.write( buffer )

							buffer = "\tt0( \"%s\" )\n" % ( st0 )
							f.write( buffer )


							# Clamp the filter range to 0.0 to 2.0
							filter = ( 2.0 / 49.0 ) * ( tex_channel[0].tex.filterSize - 1.0 )
							
							if( filter ):
								buffer = "\ttfi0( %s )\n" % optimize_float( filter )
								f.write( buffer )
							
	
						#================================
						# TEX1
						#================================
						flags = 0
						
						if( len( st1 ) ):
							
							# Use mipmap
							if( tex_channel[1].tex.imageFlags & Texture.ImageFlags["MIPMAP"] ):
								flags = flags | 1
								
							# Clamp to edge
							if( tex_channel[1].tex.getExtend() == "Clip" ):
								flags = flags | 2

							buffer = "\ttfl1( %s )\n" % flags
							f.write( buffer )

							buffer = "\tt1( \"%s\" )\n" % ( st1 )
							f.write( buffer )
	

							# Clamp the filter range to 0.0 to 2.0
							filter = ( 2.0 / 49.0 ) * ( tex_channel[1].tex.filterSize - 1.0 )
							
							if( filter ):
								buffer = "\ttfi1( %s )\n" % optimize_float( filter )
								f.write( buffer )
								
	
						
						#================================
						# SOUND
						#================================
						flags = 0
						
						if( len( st2 ) ):

							# Autoplay
							if( tex_channel[2].tex.imageFlags & Texture.ImageFlags["MIPMAP"] ):
								flags = flags | 1
								
							# Loop
							if( tex_channel[2].tex.getExtend() == "Repeat" ):
								flags = flags | 2
							
							# Stream (using double buffer)
							if( tex_channel[2].tex.imageFlags & Texture.ImageFlags["USEALPHA"] ):
								flags = flags | 16
							
							# Ambient
							if( tex_channel[2].tex.imageFlags & Texture.ImageFlags["INTERPOL"] ):
								flags = flags | 4
							
							# FX
							else:							
								flags = flags | 8

							buffer = "\tsfl( %s )\n" % flags
							f.write( buffer )
							
							buffer = "\tsb( \"%s\" )\n" % ( st2 )
							f.write( buffer )

	
						#================================
						# DIFFUSE
						#================================
						buffer = "\td( %s %s %s )\n" % ( optimize_float( mat.getRGBCol()[0] ),
																				  	 optimize_float( mat.getRGBCol()[1] ),
																						 optimize_float( mat.getRGBCol()[2] ) )
						f.write( buffer )
	
	
						#================================
						# SPECULAR
						#================================
						buffer = "\tsp( %s %s %s )\n" % ( optimize_float( mat.getSpecCol()[0] ),
																			 		 		optimize_float( mat.getSpecCol()[1] ),
																			 		 		optimize_float( mat.getSpecCol()[2] ) )
						f.write( buffer )


						#================================
						# ALPHA
						#================================
						if( mat.getAlpha() ):					
							buffer = "\ta( %s )\n" % optimize_float( mat.getAlpha() )
							f.write( buffer )


						#================================
						# SHININESS
						#================================
						if( mat.getHardness() ):
							buffer = "\tsh( %s )\n" % optimize_float( ( mat.getHardness() / 4 ) )
							f.write( buffer )

	
						#================================
						# FRICTION
						#================================
						if( mat.rbFriction ):
							buffer = "\tfr( %s )\n" % optimize_float( mat.rbFriction )
							f.write( buffer )
		
							
						#================================
						# RESTITUTION
						#================================
						if( mat.rbRestitution ):
							buffer = "\tre( %s )\n" % optimize_float( mat.rbRestitution )
							f.write( buffer )
						
						
						#================================
						# ALPHA LEVEL
						#================================
						if( mat.getTranslucency() ):
							buffer = "\tal( %s )\n" % optimize_float( mat.getTranslucency() )
							f.write( buffer )

	
						#================================
						# BLEND MODE
						#================================
						blend = 0
						
						if( len( st0 ) ):								
							blend = tex_channel[0].blendmode

						if( blend ):
							buffer = "\tb( %s )\n" % blend
							f.write( buffer )
	
	
						#================================
						# END MATERIAL
						#================================					
						f.write( "}\n" )			
						f.close()	


	#====================================
	# LAMP
	#====================================
	for obj in objects:
		
		if( obj.getType() == "Lamp" and obj.layers[0] == layer[0] and obj.isSelected() ):
			
			if( UPDATE or not os.path.exists( output + "lamp/" + obj.getName() ) ):	
				
				#====================================
				# Write the current lamp data.
				#====================================
				f = open( output + "lamp/" + obj.getName(), "wb")
	
				#================================
				# NAME
				#================================
				buffer = "lamp( \"%s\")\n{\n" % ( "lamp/" + obj.getName() )
				f.write( buffer )
	
	
				#===============================
				# TYPE
				#===============================	
				# 0 = Lamp
				# 1 = Sun
				# 2 = Spot
				# 3 = Hemi
				# 4 = Area
				#===============================
				lamp = obj.getData()
				
				if( lamp.getType() ):
					buffer = "\tt( %s )\n" % lamp.getType()
					f.write( buffer )
	
	
				#===============================
				# FLAGS
				#===============================
				flags = 0
				
				if( lamp.getMode() & Blender.Lamp.Modes["NoDiffuse"] ):
					flags = flags | 1
				
				if( lamp.getMode() & Blender.Lamp.Modes["NoSpecular"] ):
					flags = flags | 2
	
				if( flags ):
					buffer = "\tfl( %s )\n" % flags
					f.write( buffer )			
	
							
				#===============================
				# LOCATION
				#===============================
				if( optimize_float( obj.loc[ 0 ] ) != 0.0 or
					  optimize_float( obj.loc[ 1 ] ) != 0.0 or
						optimize_float( obj.loc[ 2 ] ) != 0.0 ):
											
					buffer = "\tl( %s %s %s )\n" % ( optimize_float( obj.loc[0] ),
																		 			 optimize_float( obj.loc[1] ),
																		 			 optimize_float( obj.loc[2] ) )
					f.write( buffer )
		
	
				#===============================
				# DIRECTION
				#===============================
				tar = ( Blender.Mathutils.Vector( 0.0, 0.0, -1.0 ) * obj.matrixWorld )
				loc = Blender.Mathutils.Vector( obj.loc[0], obj.loc[1], obj.loc[2] )
				
				dir = tar - loc

				dir.normalize()

				buffer = "\td( %s %s %s )\n" % ( optimize_float( dir.x ),
																	 			 optimize_float( dir.y ),
																	 			 optimize_float( dir.z ) )
				f.write( buffer )
	
	
				#===============================
				# COLOR
				#===============================
				buffer = "\tc( %s %s %s )\n" % ( optimize_float( lamp.col[0] ),
																	 			 optimize_float( lamp.col[1] ),
																	 			 optimize_float( lamp.col[2] ) )
				f.write( buffer )
				
	
				#===============================
				# ENERGY
				#===============================
				buffer = "\tn( %s )\n" % optimize_float( lamp.getEnergy() )
				f.write( buffer )
	
	
				#===============================
				# DISTANCE
				#===============================
				buffer = "\tds( %s )\n" % optimize_float( lamp.getDist() )
				f.write( buffer )			
	
	
				#===============================
				# FOV
				#===============================
				buffer = "\tf( %s )\n" % optimize_float( lamp.getSpotSize() )
				f.write( buffer )
	
	
				#===============================
				# SPOT BLEND
				#===============================
				buffer = "\tsb( %s )\n" % optimize_float( lamp.getSpotBlend() )
				f.write( buffer )
				
	
				#===============================
				# LINEAR ATTENUATION
				#===============================
				buffer = "\tat1( %s )\n" % optimize_float( lamp.getQuad1() )
				f.write( buffer )			
				
	
				#===============================
				# QUADRATIC ATTENUATION
				#===============================
				buffer = "\tat2( %s )\n" % optimize_float( lamp.getQuad2() )
				f.write( buffer )			
	

				#===============================
				# IPO
				#===============================
				if( obj.getIpo() ):
					
					ipos.append( obj.getIpo() )
					
					buffer = "\tip( \"%s\" )\n" % ( "ipo/" + obj.getIpo().getName() )
					f.write( buffer )


				#====================================
				# SCRIPTS
				#====================================
				export_script( obj )				

	
				#===============================
				# CLOSE LAMP
				#===============================
				f.write( "}\n" )
				obj.select(0)
				Blender.Redraw(1)		
				f.close()


	#====================================
	# OBJECT
	#====================================	
	for obj in objects:
					
		if( obj.getType() == "Mesh" and obj.layers[0] == layer[0] and obj.isSelected() ):	

			if( UPDATE or not os.path.exists( output + "object/" + obj.getName() ) ):
		
				print "object/" + obj.getName(),
				
				f = open( output + "object/" + obj.getName(), "wb" )

				#====================================
				# Get access to the mesh of this
				# object...
				#====================================			
				mesh = obj.getData( False, True )
				
				#================================
				# NAME
				#================================
				buffer = "object( \"%s\" )\n{\n" % ( "object/" + obj.getName() )
				f.write( buffer )
	
				
				#===============================
				# LOCATION
				#===============================
				loc = []
				
				if( obj.parent and obj.parent.getType() == "Armature" ):
					
					loc.append( optimize_float( obj.parent.loc[0] ) )
					loc.append( optimize_float( obj.parent.loc[1] ) )
					loc.append( optimize_float( obj.parent.loc[2] ) )
					
				else:
					
					loc.append( optimize_float( obj.loc[0] ) )
					loc.append( optimize_float( obj.loc[1] ) )
					loc.append( optimize_float( obj.loc[2] ) )
				
				
				if( loc[0] != 0.0 or
					  loc[1] != 0.0 or
						loc[2] != 0.0 ):
											
					buffer = "\tl( %s %s %s )\n" % ( loc[0], loc[1], loc[2] )
					f.write( buffer )
					
				
				#===============================
				# ROTATION (in degree)
				#===============================
				rot	= []

				if( obj.parent and obj.parent.getType() == "Armature" ):
			
					rot.append( obj.parent.rot[0] * RAD_TO_DEG )
					rot.append( obj.parent.rot[1] * RAD_TO_DEG )
					rot.append( obj.parent.rot[2] * RAD_TO_DEG )
				
				else:
				
					rot.append( obj.rot[0] * RAD_TO_DEG )
					rot.append( obj.rot[1] * RAD_TO_DEG )
					rot.append( obj.rot[2] * RAD_TO_DEG )
								

				if( rot[0] < 0.0 ): rot[0] = rot[0] + 360.0
				if( rot[1] < 0.0 ): rot[1] = rot[1] + 360.0
				if( rot[2] < 0.0 ): rot[2] = rot[2] + 360.0	

				rot[0] = optimize_float( rot[0] )
				rot[1] = optimize_float( rot[1] )
				rot[2] = optimize_float( rot[2] )

		
				if( rot[0] != 0.0 or
	 	 			  rot[1] != 0.0 or
	 	 			  rot[2] != 0.0 ):
		
					buffer = "\tr( %s %s %s )\n" % ( rot[0], rot[1], rot[2] )
					f.write( buffer )	
				
				
				#===============================
				# SCALE
				#===============================
				scl = []

				if( obj.parent and obj.parent.getType() == "Armature" ):

					scl.append( optimize_float( obj.parent.size[0] ) )					
					scl.append( optimize_float( obj.parent.size[1] ) )
					scl.append( optimize_float( obj.parent.size[2] ) )
					
					
				else:
					
					scl.append( optimize_float( obj.size[0] ) )					
					scl.append( optimize_float( obj.size[1] ) )
					scl.append( optimize_float( obj.size[2] ) )
			
										
				if( scl[0] != 1.0 or
	 	 				scl[1] != 1.0 or
	 	 				scl[2] != 1.0 ):
					
					buffer = "\ts( %s %s %s )\n" % ( scl[0], scl[1], scl[2] )
					f.write( buffer )

				
				#================================
				# BOUNDING SPHERE RADIUS
				#================================
				i = 0
				j = 1
				
				bb = obj.getBoundBox()				
		
				bs_radius = 0.0
		
				for i in range( 7 ):
		
					for j in range( 8 ):
		
						dd = ( distance( bb[i], bb[j] ) * 0.5 )
		
						if( dd > bs_radius ):
		
							bs_radius = dd
		
				buffer = "\tra( %s )\n" % optimize_float( bs_radius )
				f.write( buffer )
	
		
				#===============================
				# PHYSIC FLAGS
				#===============================
				flags = 0
				
				if( obj.rbFlags & Object.RBFlags["ACTOR"] ):
					flags = flags | 1
		
				if( obj.rbFlags & Object.RBFlags["GHOST"] ):
					flags = flags | 2	
				
				if( obj.rbFlags & Object.RBFlags["ACTOR"] and
						obj.rbFlags & Object.RBFlags["DYNAMIC"] ):
					
					flags = flags | 4
					
				if( obj.rbFlags & Object.RBFlags["ACTOR"] and
						obj.rbFlags & Object.RBFlags["DYNAMIC"] and
						obj.rbFlags & Object.RBFlags["RIGIDBODY"] ):
					flags = flags | 8
	
				if( obj.rbFlags & Object.RBFlags["ACTOR"] and
						obj.rbFlags & Object.RBFlags["DYNAMIC"] and
						obj.rbFlags & Object.RBFlags["SOFTBODY"] ):
				
					flags = flags & ~ 8
					flags = flags | 16
					flags = flags | 1024

				if( obj.parent and obj.parent.getType() == "Armature" ):
					flags = flags | 1024

				
				if( obj.rbFlags & Object.RBFlags["COLLISION_RESPONSE"] ):
					flags = flags | 256
				
				
				#===============================
				# MISC. FLAGS
				#===============================
				uv_channel = mesh.getUVLayerNames()
				
				for face in mesh.faces:
		
					if( not len( uv_channel ) ):
						break
					
					mesh.activeUVLayer = uv_channel[ 0 ]
	
					# Two Side
					if( face.mode & Mesh.FaceModes["TWOSIDE"] ):
						flags = flags | 128

					# Shadow Model
					if( face.mode & Mesh.FaceModes["SHADOW"] ):
						flags = flags | 512

					# Invisibe Model
					if( face.mode & Mesh.FaceModes["INVISIBLE"] ):
						flags = flags | 2048
						
					# Cylindrical Billboard			
					if( face.mode & Mesh.FaceModes["BILLBOARD"] ):
						flags = flags | 32
						break
		
					# Spherical Billboard
					if( face.mode & Mesh.FaceModes["HALO"] ):
						flags = flags | 64
						break
	
		
				if( flags ):		
					buffer = "\tfl( %s )\n" % flags
					f.write( buffer )


				if( obj.rbFlags & Object.RBFlags["ACTOR"] or
						obj.rbFlags & Object.RBFlags["GHOST"] ):			
		
					#====================================
					# OBJECT BOUNDS
					#
					# 0 - Cube
					# 1 - Sphere
					# 2 - Cylinder
					# 3 - Cone
					# 4 - Static Triangle Mesh
					# 5 - Convex Hull
					# 6 - Capsule
					#====================================
					
					bounds = obj.rbShapeBoundType
					
					props = obj.getAllProperties()
					
					print "\n%s\n" % props
					
					for prop in props:
						if ( prop.getName() == "useCapsule" ):	
							print "\nUsing capsule shape...\n"
							if ( prop.getData() == 1 ):
								bounds = 6
						
					mass   = optimize_float( obj.rbMass )

					if( not obj.rbFlags & Object.RBFlags["DYNAMIC"] ):
						mass = 0.0

					if( obj.rbFlags & Object.RBFlags["SOFTBODY"] and bounds != 5 ):
						bounds = 5
	
	
					#===============================
					# BOUNDS
					#===============================			
					if( bounds ):
						buffer = "\tb( %s )\n" % bounds
						f.write( buffer )
	
			
					#===============================
					# MASS
					#===============================
					if( mass ):
						buffer = "\tma( %s )\n" % optimize_float( mass )
						f.write( buffer )
		
	
					#===============================
					# Please take note that the 
					# following properties cannot
					# be accessed with python, you'll
					# have to manually enter them
					# to the object properties in
					# order for them to work.
					#===============================
					# For Dynamic & Rigid Body
					#===============================
					"""
					damping 				 = da <float>
					rotation damping = rd <float>
					margin					 = mr <float>
					"""
					#===============================
					# For Soft Body 
					#===============================
					"""
					linear stiffness    = ls <float>
					shape match			    = sm <float>
					cluster itteration  = ci <unsigned char>
					position itteration = pi <unsigned char>				
					"""
				
				#===============================
				# DIM XYZ
				#===============================
				dim = get_dim( obj, mesh )
				
				buffer = "\tdi( %s %s %s )\n" % ( optimize_float( dim[0] ),
																	 			  optimize_float( dim[1] ),
																	 			  optimize_float( dim[2] ) )
				f.write( buffer )
				
		
				#===============================
				# CONSTRAINTS
				#===============================
				
				const = obj.constraints
				
				for c in const:
					
					if(( c.type == Constraint.Type.RIGIDBODYJOINT ) & ( c[Constraint.Settings.CONSTR_RB_TYPE] == 12 )):
						
						
						#con_n( "name" )
						buffer = "\tcon_n( \"%s\" )\n" % (c.name)
						f.write( buffer )
						
						#con_i( influence )
						buffer = "\tcon_i( %s )\n" % (optimize_float(c.influence))	
						f.write( buffer )
						
						#con_t( "target name" )
						buffer = "\tcon_t( \"%s\" )\n" % (c[Constraint.Settings.TARGET].getName())
						f.write( buffer )
						
						#con_ax( %f %f %f ) - axis
						buffer = "\tcon_ax( %s %s %s )\n" % (optimize_float(c[Constraint.Settings.CONSTR_RB_AXX]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_AXY]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_AXZ]))
						f.write( buffer )
						
						#con_lmx( %f %f %f ) - locational max limit
						buffer = "\tcon_lmx( %s %s %s )\n" % (optimize_float(c[Constraint.Settings.CONSTR_RB_MAXLIMIT0]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MAXLIMIT1]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MAXLIMIT2]))
						f.write( buffer )
						
						#con_rmx( %f %f %f ) - rotational max limit
						buffer = "\tcon_rmx( %s %s %s )\n" % (optimize_float(c[Constraint.Settings.CONSTR_RB_MAXLIMIT3]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MAXLIMIT4]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MAXLIMIT5]))
						f.write( buffer )
						
						#con_lmn( %f %f %f ) - locational min limit
						buffer = "\tcon_lmn( %s %s %s )\n" % (optimize_float(c[Constraint.Settings.CONSTR_RB_MINLIMIT0]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MINLIMIT1]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MINLIMIT2]))
						f.write( buffer )
						
						#con_rmn( %f %f %f ) - rotational min limit
						buffer = "\tcon_rmn( %s %s %s )\n" % (optimize_float(c[Constraint.Settings.CONSTR_RB_MINLIMIT3]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MINLIMIT4]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_MINLIMIT5]))
						f.write( buffer )
						
						#con_p( %f %f %f ) - pivot
						buffer = "\tcon_p( %s %s %s )\n" % (optimize_float(c[Constraint.Settings.CONSTR_RB_PIVX]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_PIVY]),
																								 optimize_float(c[Constraint.Settings.CONSTR_RB_PIVZ]))
						f.write( buffer )
				
				#===============================
				# USER PROPERTIES
				#===============================
				
				properties = obj.getAllProperties()
	
				for p in properties:
					
					# don't include the useCapsule option
					if( p.getName() == "useCapsule"):
						continue
					
					if( p.getType() == "STRING" ):					
						buffer = "\t%s( \"%s\" )\n" % ( p.getName(), p.getData() )
						 
					else:
						buffer = "\t%s( %s )\n" % ( p.getName(), p.getData() )					
						
					f.write( buffer )
	

				#===============================
				# IPO
				#===============================
				if( obj.getIpo() ):
					
					ipos.append( obj.getIpo() )
					
					buffer = "\tip( \"%s\" )\n" % ( "ipo/" + obj.getIpo().getName() )
					f.write( buffer )


				#====================================
				# SCRIPTS
				#====================================
				export_script( obj )				
				
	
				#===============================
				# INSTANCE
				#===============================
				#
				# Cannot create instance if it is
				# a soft body, since they need an
				# independent VBO in order to work
				# properly
				#
				#===============================				
				if( not obj.rbFlags & Object.RBFlags["SOFTBODY"] ):
								
					inst = get_instance( obj.getName() )
					
					if( inst ):
						
						buffer = "\tin( \"%s\" )\n" % ( "object/" + inst.getName() )
						f.write( buffer )
					
					
						#===============================
						# CLOSE OBJECT
						#===============================
						f.write( "}\n" )
						obj.select(0)
						Blender.Redraw(1)	
						f.close()
						print ""
			
						continue
		
	
				#================================
				# CREATE VERTEX GROUP (IF NOT ANY)
				#================================			
				if( not len( mesh.getVertGroupNames() ) and len( mesh.verts ) ):
		
						mesh.addVertGroup( "null" )
						
						tmp_vert_lst = []
						
						for v in mesh.verts:
							tmp_vert_lst.append( v.index )
							
						mesh.assignVertsToGroup( "null", tmp_vert_lst, 1.0, Blender.Mesh.AssignModes.REPLACE )
						mesh.update()


				#===============================
				# CREATE THE VBO
				#===============================
				stats = "( 0:0:0% ) "
				vert_lst, vbo_size, vbo_offset, vert_ind = create_vbo( mesh )
		
				tot = len( mesh.faces ) * 3.0
	 			cur = len( vert_lst ) * 1.0

			
				if( tot ):

					#================================
					# OPTIMISATION STATISTICS
					#================================					
					stats = "( %d:%d:%.0f%% ) " % ( cur, tot, 100.0 - ( ( cur / tot ) * 100.0 ) )

					#===============================
					# WRITE BUFFER SIZE + OFFSET
					#===============================
					buffer = "\tvb( %s %s %s %s %s )\n" % ( vbo_size,
																						   		vbo_offset[0],
																						   		vbo_offset[1],
																						   		vbo_offset[2],
																						   		vbo_offset[3] )
					f.write( buffer )
		
				
					#===============================
					# VBO
					#===============================			
					
					# Vertex		
					for v in vert_lst:
						buffer = "\tv( %s %s %s )\n" % ( optimize_float( v.ver.x ),
																					   optimize_float( v.ver.y ),
																			 	 		 optimize_float( v.ver.z ) )
						f.write( buffer )				
		
				
					# Vertex Normals
					if( NORMALS ):
						
						for v in vert_lst:
							buffer = "\tn( %s %s %s )\n" % ( optimize_float( v.vno.x ),
																							 optimize_float( v.vno.y ),
																				 	 	   optimize_float( v.vno.z ) )
							f.write( buffer )																		


					# Vertex Color
					if( mesh.vertexColors ):
						
						for v in vert_lst:
							buffer = "\tc( %s %s %s )\n" % ( v.vco[ 0 ],
																							 v.vco[ 1 ],
																							 v.vco[ 2 ] )
							f.write( buffer )						
				
							
					# UV0
					if( len( uv_channel ) ):
											
						for v in vert_lst:
							buffer = "\tu0( %s %s )\n" % ( optimize_float( v.uv0.x ),
																		 			   optimize_float( v.uv0.y ) )
							f.write( buffer )
		
			
					# UV1			
					if( len( uv_channel ) > 1 ):
			
						for v in vert_lst:
							buffer = "\tu1( %s %s )\n" % ( optimize_float( v.uv1.x ),
																		 			   optimize_float( v.uv1.y ) )
							f.write( buffer )


					#================================
					# WRITE THE N VERTEX GROUPS
					#================================
					if( len( mesh.verts ) ):
						buffer = "\tng( %s )\n" % len( mesh.getVertGroupNames() )
						f.write( buffer )			
		
					
					#================================
					# WRITE THE VERTEX GROUPS BLOCKS
					#================================	
					for vg in mesh.getVertGroupNames():
						
						#skip the bone groups
						if(vg[:2] == "b."):
							continue
						
						# Unselect All
						for v in mesh.verts:
							v.sel = 0
							
						for face in mesh.faces:
							face.sel = 0					
			
						# Get vertex list
						v_lst = mesh.getVertsFromGroup( vg, 1 )
						
						if( not len( v_lst ) ):
							error_str = "ERROR: Invalid vertexgroup: %s:%s." % ( obj.getName(), vg )
							PupMenu( error_str )
							return												

					
						#===============================
						# NAME
						#===============================
						buffer = "\tg( \"%s\" )\n" % vg
						f.write( buffer )
			
								
						# Select all group vertices
						for v in v_lst:
							mesh.verts[ v[ 0 ] ].sel = 1										
					
					
						n_ind = 0
						for face in mesh.faces:
							
							if( face.v[ 0 ].sel == 1 and
									face.v[ 1 ].sel == 1 and
									face.v[ 2 ].sel == 1 ):
								
								face.sel = 1
								
								if( n_ind == 0 ):
									
									if( len( mesh.materials ) ):
	
										mat = mesh.materials[ face.mat ]
										
										try:

											buffer = "\tmt( \"%s\" )\n" % ( "material/" + mat.getName() )
											f.write( buffer )
													
										except:
											dummy = 0
								
								n_ind = n_ind + 3


						#===============================
						# TRIANGLE INDICES
						#===============================
						indices = []
						index = 0
						
						for face in mesh.faces:
			
							if( face.v[ 0 ].sel == 1 and
								  face.v[ 1 ].sel == 1 and
								  face.v[ 2 ].sel == 1 ):

								#===============================
								# INDICES
								#===============================										
								for i in range( 3 ):
									
									tmp_vert = vertex()
									
									tmp_vert.ver = Blender.Mathutils.Vector( optimize_float( face.v[i].co[0] ),
																												   optimize_float( face.v[i].co[1] ),
																													 optimize_float( face.v[i].co[2] ) )
									

									tmp_vert.vno = None
									
									if( NORMALS ):
										
										if( face.smooth ):
											tmp_vert.vno = Blender.Mathutils.Vector( optimize_float( face.v[i].no[0] ),
																															 optimize_float( face.v[i].no[1] ),
																															 optimize_float( face.v[i].no[2] ) )						
										else:
											tmp_vert.vno = Blender.Mathutils.Vector( optimize_float( face.no[0] ),
																															 optimize_float( face.no[1] ),
																															 optimize_float( face.no[2] ) )


									tmp_vert.vco = None
									
									if( mesh.vertexColors ):
										rgb = [ face.col[i][0],
														face.col[i][1],
														face.col[i][2] ]
														
										tmp_vert.vco = rgb

									
									tmp_vert.uv0 = None
									if( len( uv_channel ) ):
										mesh.activeUVLayer = uv_channel[0]
										tmp_vert.uv0 = Blender.Mathutils.Vector( optimize_float( face.uv[i][0] ),
																														 optimize_float( 1.0 - face.uv[i][1] ),
																														 0.0 )
									
												
									tmp_vert.uv1 = None
									if( len( uv_channel ) > 1 ):
										mesh.activeUVLayer = uv_channel[1]
										tmp_vert.uv1 = Blender.Mathutils.Vector( optimize_float( face.uv[i][0] ),
																														 optimize_float( 1.0 - face.uv[i][1] ),
																														 0.0 )
																																				
									index = get_index( vert_lst, tmp_vert )
									
									if( index == -1 ):
										
										error_str = "ERROR: Unable to find vertex indice: %s. |" % obj.getName()
										PupMenu( error_str )
										return
									
									indices.append( index )


						#===============================
						# OPTIMIZE THE ELEMENT ARRAY
						#===============================				
						mode = GL_TRIANGLES
						
						n_ind = len( indices )
						tot 	= n_ind * 1.0
						cur   = n_ind * 1.0
								
						
						if( OPTIMIZE and not ( obj.rbFlags & Object.RBFlags["SOFTBODY"] ) ):

							program_path = os.path.dirname( sys.argv[ 0 ] )
							program_path = os.path.abspath( program_path )
							program			 = program_path + "/optimizer"
							
							if( not os.path.exists( program ) ):
								
								error_str = "ERROR: Unable to find the optimizer.|Make sure it is located in this directory: %s |" % program_path
								PupMenu( error_str )
								return

							
							program = program + " "


							for e in indices:
								program = program + str( e ) + " "


							try:

								pipe = os.popen( program, "r" )
	
								new_indices = []
								
								
								for e in pipe:
								
									try:
									
										e = int( e )
										new_indices.append( e )
																
									except:
										#error_str = "WARNING: %s: %s |" % ( str( e ), obj.getName() ) 
										#PupMenu( error_str )
										error_str = ""
	
	
								if( new_indices[ 0 ] ):
									
									mode  = GL_TRIANGLE_STRIP
									n_ind = new_indices[ 0 ]
									cur   = new_indices[ 0 ] * 1.0
									
									indices = []				
									for i in range( n_ind ):
										indices.append( new_indices[ i + 1 ] )
							
							except:
								error_str = "ERROR: Unable to find the optimizer (Indie version only)."
								PupMenu( error_str )
								return							

						
						#===============================
						# N_INDICES
						#===============================
						stats = stats + "( %d:%d:%.0f%% ) " % ( cur, tot, 100.0 - ( ( cur / tot ) * 100.0 ) )
						
						buffer = "\tni( %s %d )\n" % ( n_ind, mode ) 
						f.write( buffer )
				
						
						i = 0
						buffer = ""
						for i in range( n_ind ):
						
							buffer = buffer + "%d " % indices[ i ]

							if( ( ( i + 1 ) % 3 ) == 0 ):
								buffer = "\ti( 3 %s)\n" % buffer
								f.write( buffer )
								buffer = ""

						n_left = ( ( i + 1 ) % 3 )
						
						if( n_left ):
							buffer = "\ti( %d %s)\n" % ( n_left, buffer )
							f.write( buffer )

				print stats


				#===============================
				# CLOSE OBJECT
				#===============================
				f.write( "}\n" )			
				obj.select(0)
				Blender.Redraw(1)	
				f.close()


				#===============================
				# ACTION FRAME
				#===============================
				if( obj.parent and obj.parent.getType() == "Armature" ):

					#===============================
					# TAG THE ONE THAT ARE VISIBLE
					#===============================
					o_flags = []
					for act in obj.parent.actionStrips:
						
						if( act.flag & Blender.Armature.NLA.Flags[ "MUTE" ] ):
						
							o_flags.append( 0 )
						
						else:
							o_flags.append( 1 )
					
					
					#===============================
					# ACTION STRIPS
					#===============================
					n = 0
					for act in obj.parent.actionStrips:


						#===============================
						# DO WE WANT TO EXPORT THAT ACTION?
						#===============================											
						
							#want to export ALL actions
							#if( o_flags[ n ] == 0 ):

							#n = n + 1
							#continue
						
						  #else:
						n = n + 1
						
						#====================================
						# Write the current action data.
						#====================================
						f = open( output + "action/" + act.action.getName(), "wb")
			
						#================================
						# NAME
						#================================
						buffer = "action( \"%s\")\n{\n" % ( "action/" + act.action.getName() )
						f.write( buffer )
						
						obj.parent.action = act.action
						
						#===============================
						# MUTE THE OTHER STRIPS
						#===============================						
						for a in obj.parent.actionStrips:
							
							if( a.action == act.action ):
								a.flag = a.flag & ~Blender.Armature.NLA.Flags[ "MUTE"   ]						
								a.flag = a.flag |  Blender.Armature.NLA.Flags[ "SELECT" ]						
								a.flag = a.flag |  Blender.Armature.NLA.Flags[ "ACTIVE" ]
							
							else:
								a.flag = a.flag |  Blender.Armature.NLA.Flags[ "MUTE"   ]						
								a.flag = a.flag & ~Blender.Armature.NLA.Flags[ "SELECT" ]						
								a.flag = a.flag & ~Blender.Armature.NLA.Flags[ "ACTIVE" ]					

					
						#===============================
						# N_FRAME
						#===============================
						s_frame = len( vert_lst ) * 12
						
						if( NORMALS ): s_frame = s_frame * 2
						
						buffer = "\tnf( %s %s )\n" % ( len( act.action.getFrameNumbers() ), s_frame )
						f.write( buffer )					

						
						for frame in act.action.getFrameNumbers():
					
							Blender.Set( "curframe", frame )
							Blender.Redraw()

							curr_mesh = obj.getData( False, True )	
							curr_mesh = mesh.__copy__();
							curr_mesh.getFromObject( obj.getName() )

							
							#===============================
							# FRAME
							#===============================
							buffer = "\tf( %s )\n" % frame
							f.write( buffer )
									
							
							#===============================
							# FRAME VERTS
							#===============================
							for i in vert_ind:
								
								face = int( i / 3 )
								indi = i % 3
								vert = curr_mesh.faces[ face ].v[ indi ].co
								
								buffer = "\tfv( %s %s %s )\n" % ( optimize_float( vert[0] ),
																					 		    optimize_float( vert[1] ),
																					 	 		  optimize_float( vert[2] ) )
								f.write( buffer )
		

							#===============================
							# FRAME NORMALS
							#===============================
							if( NORMALS ):
								
								for i in vert_ind:
									
									face = int( i / 3 )
									indi = i % 3
									
									if( mesh.faces[ face ].smooth ):
										norm = mesh.faces[ face ].v[ indi ].no
										
									else:
										norm = mesh.faces[ face ].no
										
									
									buffer = "\tfn( %s %s %s )\n" % ( optimize_float( norm[0] ),
																						 		    optimize_float( norm[1] ),
																						 	 			optimize_float( norm[2] ) )
									f.write( buffer )					

						#===============================
						# CLOSE ACTION
						#===============================
						f.write( "}\n" )			
						f.close()



	#================================
	# IPO
	#================================
	if( ALLIPO ):
		ipos = Blender.Ipo.Get()
	
	for ipo in ipos:

		#================================
		# VALIDATE THE IPO
		#================================
		invalid = 0
		
		if( not len( ipo ) ):
			invalid = 1
		
		for curve in ipo:
			
			if( not curve.getName() == "LocX"   and
					not curve.getName() == "LocY"   and
					not curve.getName() == "LocZ"   and
					not curve.getName() == "RotX"   and
					not curve.getName() == "RotY"   and
					not curve.getName() == "RotZ"   and
					not curve.getName() == "ScaleX" and
					not curve.getName() == "ScaleY" and
					not curve.getName() == "ScaleZ" or
					len( curve.getPoints() ) < 2 ):
					
					invalid = 1
					
					break
				
		if( invalid == 1 ):
			
			print "WARNING: Unsuported curve type: %s" % ipo.getName()
			continue
						
						
		#================================
		# CREATING THE IPO
		#================================				
		if( UPDATE or not os.path.exists( output + "ipo/" + ipo.getName() ) ):

				f = open( output + "ipo/" + ipo.getName(), "wb" )
							
				#================================
				# NAME
				#================================
				buffer = "ipo( \"%s\" )\n{\n" % ( "ipo/" + ipo.getName() )
				f.write( buffer )

				#================================
				# IPO CURVE
				#================================
				for curve in ipo:
					
					#================================
					# IPO TYPE & SCALE
					#================================					
					token = ""
					type  = -1
					scale = 1.0
					
					if( curve.getName() == "LocX" ):
						token = "lx"
						type  = 0
						
					elif( curve.getName() == "LocY" ):
						token = "ly"						
						type  = 1
						
					elif( curve.getName() == "LocZ" ):
						token = "lz"						
						type  = 2

					elif( curve.getName() == "RotX" ):
						token = "rx"						
						type  = 3
						scale = 10.0
						
					elif( curve.getName() == "RotY" ):
						token = "ry"						
						type  = 4
						scale = 10.0									

					elif( curve.getName() == "RotZ" ):
						token = "rz"						
						type  = 5
						scale = 10.0

					elif( curve.getName() == "ScaleX" ):
						token = "sx"						
						type = 6
						
					elif( curve.getName() == "ScaleY" ):
						token = "sy"						
						type = 7

					elif( curve.getName() == "ScaleZ" ):
						token = "sz"						
						type = 8

					#================================
					# POINT
					#================================
					for p in curve.getPoints():

						buffer = "\t%s( %s %s %s %s )\n" % ( token,
																					 			 optimize_float( p.vec[0][1] * scale ),					
																					 			 optimize_float( p.vec[1][0] * ( 1.0 / ctx.fps ) ),
																					 			 optimize_float( p.vec[1][1] * scale ),
																					 			 optimize_float( p.vec[2][1] * scale ) )
						f.write( buffer )

					
					#================================
					# INTERPOLATION
					#================================					
					#
					# 0 - Constant
					# 1 - Linear
					# 2 - Bezier
					#
					#================================
					interpolation = 0
					
					if( curve.getInterpolation() == "Linear" ):
						interpolation = 1
						
					elif( curve.getInterpolation() == "Bezier" ):
						interpolation = 2
						
					if( interpolation ):
						buffer = "\ti( %s )\n" % interpolation
						f.write( buffer )


					#================================
					# EXTRAPOLATION
					#================================					
					#
					# 0 - Constant
					# 1 - Extrapolation
					# 2 - Cyclic
					# 3 - Cyclic_extrapolation
					#
					#================================
					extrapolation = 0
					
					if( curve.getExtrapolation() == "Extrapolation" ):
						extrapolation = 1
						
					elif( curve.getExtrapolation() == "Cyclic" ):
						extrapolation = 2
					
					elif( curve.getExtrapolation() == "Cyclic_extrapolation" ):
						extrapolation = 3
					
					
					if( extrapolation ):
						buffer = "\te( %s )\n" % extrapolation
						f.write( buffer )


				#===============================
				# CLOSE IPO
				#===============================
				f.write( "}\n" )			
				obj.select(0)
				Blender.Redraw(1)	
				f.close()



	#====================================
	# CREATE/UPDATE THE ZIP ARCHIVE
	#====================================
	print
	
	create_sio2( directory.val + scene.getName(),
							 directory.val + scene.getName() + ".sio2" )

	#===============================
	# END
	#===============================
	error_str += "Export Successful: %.3f sec." % ( Blender.sys.time() - start_time )	
	PupMenu( error_str )
	
	#Exit()
		

#====================================
# MAIN
#====================================
register_gui()
													
					