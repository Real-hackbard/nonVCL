unit MiniGL;

interface
{$define pure} { use GLU or pure pascal code }

{$ifdef win32}
const
 OpenGL='OpenGL32.DLL';
{$ifndef pure}
 GLU='GLU32.DLL';
{$endif}
 GLUT='GLUT32.DLL';
{$else}
uses
 Xlib;
const
 OpenGL='libGL.so'; // please make link to valid LIBName/Version
{$ifndef pure}
 GLU='libGLU.so';
{$endif}
 GLUT='libglut.so';
{$endif}

{$ifdef linux}
function glXQueryExtension(dpy:PDisplay;var err,event:integer):boolean; cdecl external OpenGL;
function glXChooseVisual(dpy: PDisplay; screen: Integer;out attribList:array of integer):PXVisualInfo; cdecl external OpenGL;
function glXCreateContext(dpy: PDisplay; vis: PXVisualInfo; shareList:integer; direct: Boolean):integer; cdecl external OpenGL;
// Tokens for glXChooseVisual and glXGetConfig:
const
  GLX_USE_GL                            = 1;
  GLX_BUFFER_SIZE                       = 2;
  GLX_LEVEL                             = 3;
  GLX_RGBA                              = 4;
  GLX_DOUBLEBUFFER                      = 5;
  GLX_STEREO                            = 6;
  GLX_AUX_BUFFERS                       = 7;
  GLX_RED_SIZE                          = 8;
  GLX_GREEN_SIZE                        = 9;
  GLX_BLUE_SIZE                         = 10;
  GLX_ALPHA_SIZE                        = 11;
  GLX_DEPTH_SIZE                        = 12;
  GLX_STENCIL_SIZE                      = 13;
  GLX_ACCUM_RED_SIZE                    = 14;
  GLX_ACCUM_GREEN_SIZE                  = 15;
  GLX_ACCUM_BLUE_SIZE                   = 16;
  GLX_ACCUM_ALPHA_SIZE                  = 17;
procedure glXMakeCurrent(dpy:PDisplay; glwin:TWindow; cx:integer); cdecl external OpenGL;
procedure glXSwapBuffers(dpy:PDisplay; glwin:TWindow); cdecl external OpenGL;
{$endif}

procedure glClear(m:integer);{$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const // attribute bits
  GL_CURRENT_BIT                             = $00000001;
  GL_POINT_BIT                               = $00000002;
  GL_LINE_BIT                                = $00000004;
  GL_POLYGON_BIT                             = $00000008;
  GL_POLYGON_STIPPLE_BIT                     = $00000010;
  GL_PIXEL_MODE_BIT                          = $00000020;
  GL_LIGHTING_BIT                            = $00000040;
  GL_FOG_BIT                                 = $00000080;
  GL_DEPTH_BUFFER_BIT                        = $00000100;
  GL_ACCUM_BUFFER_BIT                        = $00000200;
  GL_STENCIL_BUFFER_BIT                      = $00000400;
  GL_VIEWPORT_BIT                            = $00000800;
  GL_TRANSFORM_BIT                           = $00001000;
  GL_ENABLE_BIT                              = $00002000;
  GL_COLOR_BUFFER_BIT                        = $00004000;
  GL_HINT_BIT                                = $00008000;
  GL_EVAL_BIT                                = $00010000;
  GL_LIST_BIT                                = $00020000;
  GL_TEXTURE_BIT                             = $00040000;
  GL_SCISSOR_BIT                             = $00080000;
  GL_ALL_ATTRIB_BITS                         = $000FFFFF;
procedure glClearIndex(c:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glClearDepth(d:double); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

procedure glEnable(c:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const
 GL_DEPTH_TEST = $0B71;

procedure glDisable(c:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const
// Buffers, Pixel Drawing/Reading
  GL_NONE                               = 0;
  GL_LEFT                               = $0406;
  GL_RIGHT                              = $0407;
  //GL_FRONT                            = $0404;
  //GL_BACK                             = $0405;
  //GL_FRONT_AND_BACK                   = $0408;
  GL_FRONT_LEFT                         = $0400;
  GL_FRONT_RIGHT                        = $0401;
  GL_BACK_LEFT                          = $0402;
  GL_BACK_RIGHT                         = $0403;
  GL_AUX0                               = $0409;
  GL_AUX1                               = $040A;
  GL_AUX2                               = $040B;
  GL_AUX3                               = $040C;
  GL_COLOR_INDEX                        = $1900;
  GL_RED                                = $1903;
  GL_GREEN                              = $1904;
  GL_BLUE                               = $1905;
  GL_ALPHA                              = $1906;
  GL_LUMINANCE                          = $1909;
  GL_LUMINANCE_ALPHA                    = $190A;
  GL_ALPHA_BITS                         = $0D55;
  GL_RED_BITS                           = $0D52;
  GL_GREEN_BITS                         = $0D53;
  GL_BLUE_BITS                          = $0D54;
  GL_INDEX_BITS                         = $0D51;
  GL_SUBPIXEL_BITS                      = $0D50;
  GL_AUX_BUFFERS                        = $0C00;
  GL_READ_BUFFER                        = $0C02;
  GL_DRAW_BUFFER                        = $0C01;
  GL_DOUBLEBUFFER                       = $0C32;
  GL_STEREO                             = $0C33;
  GL_BITMAP                             = $1A00;
  GL_COLOR                              = $1800;
  GL_DEPTH                              = $1801;
  GL_STENCIL                            = $1802;
  GL_DITHER                             = $0BD0;
  GL_RGB                                = $1907;
  GL_RGBA                               = $1908;

procedure glCullFace(c:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const // Polygons
  GL_POINT                              = $1B00;
  GL_LINE                               = $1B01;
  GL_FILL                               = $1B02;
  GL_CCW                                = $0901;
  GL_CW                                 = $0900;
  GL_FRONT                              = $0404;
  GL_BACK                               = $0405;
  GL_CULL_FACE                          = $0B44;
  GL_CULL_FACE_MODE                     = $0B45;
  GL_POLYGON_SMOOTH                     = $0B41;
  GL_POLYGON_STIPPLE                    = $0B42;
  GL_FRONT_FACE                         = $0B46;
  GL_POLYGON_MODE                       = $0B40;
  GL_POLYGON_OFFSET_FACTOR              = $8038;
  GL_POLYGON_OFFSET_UNITS               = $2A00;
  GL_POLYGON_OFFSET_POINT               = $2A01;
  GL_POLYGON_OFFSET_LINE                = $2A02;
  GL_POLYGON_OFFSET_FILL                = $8037;
procedure glShadeModel(s:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const // Lighting
  GL_LIGHTING                           = $0B50;
  GL_LIGHT0                             = $4000;
  GL_LIGHT1                             = $4001;
  GL_LIGHT2                             = $4002;
  GL_LIGHT3                             = $4003;
  GL_LIGHT4                             = $4004;
  GL_LIGHT5                             = $4005;
  GL_LIGHT6                             = $4006;
  GL_LIGHT7                             = $4007;
  GL_SPOT_EXPONENT                      = $1205;
  GL_SPOT_CUTOFF                        = $1206;
  GL_CONSTANT_ATTENUATION               = $1207;
  GL_LINEAR_ATTENUATION                 = $1208;
  GL_QUADRATIC_ATTENUATION              = $1209;
  GL_AMBIENT                            = $1200;
  GL_DIFFUSE                            = $1201;
  GL_SPECULAR                           = $1202;
  GL_SHININESS                          = $1601;
  GL_EMISSION                           = $1600;
  GL_POSITION                           = $1203;
  GL_SPOT_DIRECTION                     = $1204;
  GL_AMBIENT_AND_DIFFUSE                = $1602;
  GL_COLOR_INDEXES                      = $1603;
  GL_LIGHT_MODEL_TWO_SIDE               = $0B52;
  GL_LIGHT_MODEL_LOCAL_VIEWER           = $0B51;
  GL_LIGHT_MODEL_AMBIENT                = $0B53;
  GL_FRONT_AND_BACK                     = $0408;
  GL_SHADE_MODEL                        = $0B54;
  GL_FLAT                               = $1D00;
  GL_SMOOTH                             = $1D01;
  GL_COLOR_MATERIAL                     = $0B57;
  GL_COLOR_MATERIAL_FACE                = $0B55;
  GL_COLOR_MATERIAL_PARAMETER           = $0B56;
  GL_NORMALIZE                          = $0BA1;

procedure glMatrixMode(m:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const // matrix modes
 GL_MATRIX_MODE = $0BA0;
 GL_MODELVIEW   = $1700;
 GL_PROJECTION  = $1701;
 GL_TEXTURE     = $1702;

procedure glNewList(list,mode:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const  // display lists
  GL_LIST_MODE                               = $0B30;
  GL_LIST_BASE                               = $0B32;
  GL_LIST_INDEX                              = $0B33;
  GL_COMPILE                                 = $1300;
  GL_COMPILE_AND_EXECUTE                     = $1301;
procedure glEndList; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glIndexi(i:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glCallList(l:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

procedure glPushMatrix; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glRotatef(angle,x,y,z:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glRotated(angle,x,y,z:double); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glTranslatef(x,y,z:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glTranslated(x,y,z:double); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glScalef(x,y,z:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glOrtho(left, right, bottom, top, near_val, far_val: Double); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glPopMatrix; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

function glGenLists(i:integer):integer; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glBegin(mode:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
const // Primitives
  GL_LINES                              = $0001;
  GL_POINTS                             = $0000;
  GL_LINE_STRIP                         = $0003;
  GL_LINE_LOOP                          = $0002;
  GL_TRIANGLES                          = $0004;
  GL_TRIANGLE_STRIP                     = $0005;
  GL_TRIANGLE_FAN                       = $0006;
  GL_QUADS                              = $0007;
  GL_QUAD_STRIP                         = $0008;
  GL_POLYGON                            = $0009;
  GL_EDGE_FLAG                          = $0B43;
procedure glColor3f(r,g,b:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glVertex2i(x,y:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glVertex2f(x,y:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glVertex3f(x,y,z:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glNormal3f(x,y,z:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glTexCoord2f(u,v:single); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glVertex3d(x,y,z:double); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glEnd; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

procedure glViewport(left,top,width,height:integer); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;
procedure glLoadIdentity; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

procedure glFlush; {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

procedure glFrustum(xmin,xmax,ymin,ymax,zNear,zFar:double); {$ifdef win32}stdcall{$else}cdecl{$endif} external OpenGL;

//---GLU---
procedure gluPerspective(fovy, aspect, zNear, zFar: double);
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}
function gluNewQuadric:integer;
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}
procedure gluDeleteQuadric(quadric:integer);
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}
procedure gluQuadricDrawStyle(quadric,style:integer);
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}
const  // QuadricDrawStyle
  GLU_POINT                                  = 100010;
  GLU_LINE                                   = 100011;
  GLU_FILL                                   = 100012;
  GLU_SILHOUETTE                             = 100013;
procedure gluQuadricNormals(quadric,normals:integer);
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}
const  // QuadricNormal
  GLU_SMOOTH                                 = 100000;
  GLU_FLAT                                   = 100001;
  GLU_NONE                                   = 100002;
procedure gluSphere(quad:integer; radius:double; slices, stacks:integer);
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}
procedure gluCylinder(quad:integer; baseRadius,topRadius,height:double; slices, stacks:integer);
{$ifndef pure}
 {$ifdef win32}stdcall{$else}cdecl{$endif} external GLU;
{$endif}

//---GLUT---
procedure glutInit(Var Count:integer;Var Parms:PChar);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutInitWindowPosition(x,y:integer);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutInitWindowSize(Width,Height:integer);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutInitDisplayMode(Mode:integer);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
const  // Display mode bit masks
  GLUT_RGB                      = 0;
  GLUT_RGBA                     = GLUT_RGB;
  GLUT_INDEX                    = 1;
  GLUT_SINGLE                   = 0;
  GLUT_DOUBLE                   = 2;
  GLUT_ACCUM                    = 4;
  GLUT_ALPHA                    = 8;
  GLUT_DEPTH                    = 16;
  GLUT_STENCIL                  = 32;
  GLUT_MULTISAMPLE              = 128;
  GLUT_STEREO                   = 256;
  GLUT_LUMINANCE                = 512;
procedure glutCreateWindow(Name:Pchar); {$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;

const // Visibility state
  GLUT_NOT_VISIBLE              = 0;
  GLUT_VISIBLE                  = 1;
type
 glutFunc=procedure; {$ifdef win33}stdcall{$else}cdecl{$endif};
procedure glutIdleFunc(f:glutFunc);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutDisplayFunc(f:glutFunc);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutReshapeFunc(f:glutFunc);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutVisibilityFunc(f:glutFunc);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutKeyboardFunc(f:glutFunc);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutSetColor(Index,R,G,B:single);{$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutSwapBuffers; {$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutPostRedisplay; {$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;
procedure glutMainLoop; {$ifdef win32}stdcall{$else}cdecl{$endif} external GLUT;

implementation

{$ifdef pure}

uses Math;

procedure gluPerspective(fovy, aspect, zNear, zFar: double);
 var
  xmin,xmax,ymin,ymax:double;
 begin
  ymax:=zNear*tan(fovy*PI/360);
  ymin:=-ymax;
  xmin:=ymin*aspect;
  xmax:=ymax*aspect;
  glFrustum(xmin,xmax,ymin,ymax,zNear,zFar);
 end;

(***************************************
truct GLUquadric {
GLenumDrawStyle;/* GLU_FILL, LINE, SILHOUETTE, or POINT */
GLenum Orientation;/* GLU_INSIDE or GLU_OUTSIDE */
GLboolean TextureFlag;/* Generate texture coords? */
GLenum Normals;/* GLU_NONE, GLU_FLAT, or GLU_SMOOTH */
void (GLCALLBACK *ErrorFunc)(GLenum err);/* Error handler callback function */
};
****************************************)
Type
 TQuadric=class
  Style  :integer;
  Normals:integer;
  Texture:boolean;
  Constructor Create(AStyle,ANormals:integer);
 end;

// Call glNormal3f after scaling normal to unit length.
procedure normal3f(x,y,z:single);
 var
  mag:double;
 begin
  mag := sqrt( x*x + y*y + z*z );
  if (mag>0.00001) then begin
   x:=x/mag;
   y:=y/mag;
   z:=z/mag;
  end;
  glNormal3f( x, y, z );
 end;
 
Constructor TQuadric.Create(AStyle,ANormals:integer);
 begin
  Style:=AStyle;
  Normals:=ANormals;
  Texture:=False;
 end;

function gluNewQuadric:integer;
 begin
  TQuadric(Result):=TQuadric.Create(GLU_FILL,GLU_SMOOTH);
 end;

procedure gluDeleteQuadric(quadric:integer);
 begin
  TQuadric(quadric).Free;
 end;

procedure gluQuadricDrawStyle(quadric,style:integer);
 begin
  TQuadric(quadric).Style:=style;
 end;

procedure gluQuadricNormals(quadric,normals:integer);
 begin
  TQuadric(quadric).Normals:=normals;
 end;

procedure gluSphere(quad:integer; radius:double; slices, stacks:integer);
 var
  rho,drho,theta,dtheta:single;
  x,y,z:single;
  s,t,ds,dt:single;
  i,j,imin,imax:integer;
  normals:boolean;
  nsign:single;
 begin
  normals:=TQuadric(quad).Normals<>GLU_NONE;
  nsign := 1.0; // GLU_OUTSIDE...
  drho := PI / stacks;
  dtheta := 2.0 * PI / slices;

  //* texturing: s goes from 0.0/0.25/0.5/0.75/1.0 at +y/+x/-y/-x/+y axis */
  //* t goes from -1.0/+1.0 at z = -radius/+radius (linear along longitudes) */
  //* cannot use triangle fan on texturing (s coord. at top/bottom tip varies) */

  if TQuadric(quad).Style=GLU_FILL then begin
   if not TQuadric(quad).Texture then begin
    //* draw +Z end as a triangle fan */
    glBegin( GL_TRIANGLE_FAN );
    glNormal3f( 0.0, 0.0, 1.0 );
    //--if TQuadric(quad).Texture then glTexCoord2f(0.5,1.0);
    glVertex3f( 0.0, 0.0, nsign * radius );
    for j:=0 to slices do begin
     if j=slices then theta := 0.0 else theta:= j * dtheta;
     x := -sin(theta) * sin(drho);
     y :=  cos(theta) * sin(drho);
     z := nsign * cos(drho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
     glVertex3f( x*radius, y*radius, z*radius );
    end;
    glEnd();
   end; // not texture
   ds := 1.0 / slices;
   dt := 1.0 / stacks;
   t := 1.0;  //* because loop now runs from 0 */
   if TQuadric(quad).Texture then begin
    imin := 0;
    imax := stacks;
   end else begin
    imin := 1;
    imax := stacks-1;
   end;
   //* draw intermediate stacks as quad strips */
   for i:=imin to imax-1 do begin
    rho := i * drho;
    glBegin( GL_QUAD_STRIP );
    s := 0.0;
    for j:=0 to slices do begin
     if j=slices then theta:=0.0 else theta:=j*dtheta;
     x := -sin(theta) * sin(rho);
     y := cos(theta) * sin(rho);
     z := nsign * cos(rho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
     if TQuadric(quad).Texture then glTexCoord2f(s,t);
     glVertex3f( x*radius, y*radius, z*radius );
     x := -sin(theta) * sin(rho+drho);
     y :=  cos(theta) * sin(rho+drho);
     z := nsign * cos(rho+drho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
     if TQuadric(quad).Texture then glTexCoord2f(s,t-dt);
     s :=s + ds;
     glVertex3f( x*radius, y*radius, z*radius );
    end;
    glEnd();
    t := t- dt;
   end;

   if not TQuadric(quad).Texture then begin
  //* draw -Z end as a triangle fan */
    glBegin( GL_TRIANGLE_FAN );
    glNormal3f( 0.0, 0.0, -1.0 );
   //--TXTR_COORD(0.5,0.0);
    glVertex3f( 0.0, 0.0, -radius*nsign );
    rho := PI - drho;
    s := 1.0;
    t := dt;
    for j:=slices downto 0 do begin
     if j=slices then theta := 0.0 else theta := j * dtheta;
     x := -sin(theta) * sin(rho);
     y :=  cos(theta) * sin(rho);
     z := nsign * cos(rho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
    //-TXTR_COORD(s,t);
     s := s- ds;
     glVertex3f( x*radius, y*radius, z*radius );
    end;
    glEnd();
   end;
  // GLU_FILL
  end else
  if (TQuadric(quad).Style=GLU_LINE) or (TQuadric(quad).style=GLU_SILHOUETTE) then begin
   //* draw stack lines */
   for i:=1 to stacks-1  do begin //* stack line at i==stacks-1 was missing here */
    rho := i * drho;
    glBegin( GL_LINE_LOOP );
    for j:=0 to slices-1 do begin
     theta := j * dtheta;
     x := cos(theta) * sin(rho);
     y := sin(theta) * sin(rho);
     z := cos(rho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
     glVertex3f( x*radius, y*radius, z*radius );
    end;
    glEnd();
   end;
   //* draw slice lines */
   for j:=0 to slices-1 do begin
    theta := j * dtheta;
    glBegin( GL_LINE_STRIP );
    for i:=0 to stacks do begin
     rho := i * drho;
     x := cos(theta) * sin(rho);
     y := sin(theta) * sin(rho);
     z := cos(rho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
     glVertex3f( x*radius, y*radius, z*radius );
    end;
    glEnd();
   end
  // GLU_LINE or GLU_SILHOUETTE
  end else
  if TQuadric(quad).Style=GLU_POINT then begin
   //* top and bottom-most points */
   glBegin( GL_POINTS );
   if (normals) then glNormal3f( 0.0, 0.0, nsign );
   glVertex3d( 0.0, 0.0, radius );
   if (normals) then glNormal3f( 0.0, 0.0, -nsign );
   glVertex3d( 0.0, 0.0, -radius );
   //* loop over stacks */
   for i:=1 to stacks-2 do begin
    rho := i * drho;
    for j:=0 to slices-1 do begin
     theta := j * dtheta;
     x := cos(theta) * sin(rho);
     y := sin(theta) * sin(rho);
     z := cos(rho);
     if (normals) then glNormal3f( x*nsign, y*nsign, z*nsign );
     glVertex3f( x*radius, y*radius, z*radius );
    end;
   end;
   glEnd();
  end;
 end;

procedure gluCylinder(quad:integer; baseRadius,topRadius,height:double; slices, stacks:integer);
 var
  da,r,dr,dz:double;
  x,y,z,nz,nsign:single;
  i,j:integer;
  ds,dt,t,s:single;
 begin
  nsign:=1.0; // GLU_OUTSIDE
  da := 2.0*PI / slices;
  dr := (topRadius-baseRadius) / stacks;
  dz := height / stacks;
  nz := (baseRadius-topRadius) / height;  //* Z component of normal vectors */
  if TQuadric(quad).Style=GLU_POINT then begin
   glBegin( GL_POINTS );
   for i:=0 to slices-1 do begin
    x := cos(i*da);
    y := sin(i*da);
    normal3f( x*nsign, y*nsign, nz*nsign );
    z := 0.0;
    r := baseRadius;
    for j:=0 to stacks do begin
     glVertex3f( x*r, y*r, z );
     z := z+ dz;
     r := r+ dr;
    end;
   end;
   glEnd();
  // GLU_POINT
  end else
  if (TQuadric(quad).Style=GLU_LINE) or (TQuadric(quad).Style=GLU_SILHOUETTE) then begin
   //* Draw rings */
   if TQuadric(quad).Style=GLU_LINE then begin
    z := 0.0;
    r := baseRadius;
    for j:=0 to stacks do begin
     glBegin( GL_LINE_LOOP );
     for i:=0 to slices-1 do begin
      x := cos(i*da);
      y := sin(i*da);
      normal3f( x*nsign, y*nsign, nz*nsign );
      glVertex3f( x*r, y*r, z );
     end;
     glEnd();
     z :=z + dz;
     r :=r + dr;
    end;
   end else
   //* draw one ring at each end */
   if (baseRadius<>0.0) then begin
    glBegin( GL_LINE_LOOP );
    for i:=0 to slices-1 do begin
     x := cos(i*da);
     y := sin(i*da);
     normal3f( x*nsign, y*nsign, nz*nsign );
     glVertex3f( x*baseRadius, y*baseRadius, 0.0 );
    end;
    glEnd();
    glBegin( GL_LINE_LOOP );
    for i:=0 to slices-1 do begin
     x := cos(i*da);
     y := sin(i*da);
     normal3f( x*nsign, y*nsign, nz*nsign );
     glVertex3f( x*topRadius, y*topRadius, height );
    end;
    glEnd();
   end;
  //* draw length lines */
   glBegin( GL_LINES );
   for i:=0 to slices-1 do begin
    x := cos(i*da);
    y := sin(i*da);
    normal3f( x*nsign, y*nsign, nz*nsign );
    glVertex3f( x*baseRadius, y*baseRadius, 0.0 );
    glVertex3f( x*topRadius, y*topRadius, height );
   end;
   glEnd();
  // GLU_LINE or GLU_SILHOUETTE
  end else
  if TQuadric(quad).Style=GLU_FILL then begin
   ds := 1.0 / slices;
   dt := 1.0 / stacks;
   t := 0.0;
   z := 0.0;
   r := baseRadius;
   for j:=0 to stacks-1 do begin
    s := 0.0;
    glBegin( GL_QUAD_STRIP );
    for i:=0 to slices do begin
     if (i = slices) then begin
      x := sin(0.0);
      y := cos(0.0);
     end else begin
      x := sin(i * da);
      y := cos(i * da);
     end;
     if (nsign=1.0) then begin
      normal3f( x*nsign, y*nsign, nz*nsign );
      if TQuadric(quad).Texture then glTexCoord2f(s,t);
      glVertex3f( x * r, y * r, z );
      normal3f( x*nsign, y*nsign, nz*nsign );
      if TQuadric(quad).Texture then glTexCoord2f(s,t+dt);
      glVertex3f( x * (r + dr), y * (r + dr), z + dz);
     end else begin
      normal3f( x*nsign, y*nsign, nz*nsign );
      if TQuadric(quad).Texture then glTexCoord2f(s,t);
      glVertex3f( x * r, y * r, z );
      normal3f( x*nsign, y*nsign, nz*nsign );
      if TQuadric(quad).Texture then glTexCoord2f(s,t+dt);
      glVertex3f( x * (r + dr), y * (r + dr), z + dz);
     end;
     s := s+ ds;
    end; //* for slices */
    glEnd();
    r:=r+dr;
    t:=t+dt;
    z:=z+dz;
   end; //* for stacks */
  end;
 end;
{$endif}
end.
