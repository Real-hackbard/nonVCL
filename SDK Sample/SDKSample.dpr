program SDKSample;

uses
  MiniGL,
{$ifdef win32}
  windows,
  messages;
{$else}
  Xlib;

{--Xutil--}
var
 argc:integer;
 argv:pchar;
 args:string;

function XSetStandardProperties(display: PDisplay; w: TWindow;
  const window_name, icon_name: PChar; icon_pixmap: TPixmap;
  argv: PPChar; argc: LongInt; hints: PXSizeHints): LongInt;
  cdecl; external 'libX11.so.6';

{$endif}

const
 BLACK_INDEX     =0;
 RED_INDEX       =13;
 GREEN_INDEX     =14;
 BLUE_INDEX      =16;
 WIDTH           =300;
 HEIGHT          =200;

(* OpenGL globals, defines, and prototypes *)
var
 latitude,longitude,latinc,longinc:single;
 radius:single;

const
 GLOBE    =1;
 CYLINDER =2;
 CONE     =3;

procedure createObjects;
 var
  quadObj:integer;
 begin
  glNewList(GLOBE, GL_COMPILE);
   quadObj:=gluNewQuadric;
   gluQuadricDrawStyle(quadObj, GLU_LINE);
   gluSphere(quadObj, 1.5, 16, 16);
   gluDeleteQuadric(quadObj);
  glEndList;

  glNewList(CONE, GL_COMPILE);
   quadObj:=gluNewQuadric;
   gluQuadricDrawStyle(quadObj, GLU_FILL);
   gluQuadricNormals(quadObj, GLU_SMOOTH);
   gluCylinder(quadObj, 0.3, 0.0, 0.6, 15, 10);
   gluDeleteQuadric(quadObj);
  glEndList;

  glNewList(CYLINDER, GL_COMPILE);
   glPushMatrix;
   glRotatef(90.0, 1.0, 0.0, 0.0);
   glTranslatef(0.0, 0.0, -1.0);
   quadObj:=gluNewQuadric;
   gluQuadricDrawStyle(quadObj, GLU_FILL);
   gluQuadricNormals(quadObj, GLU_SMOOTH);
   gluCylinder(quadObj, 0.3, 0.3, 0.6, 12, 2);
   gluDeleteQuadric(quadObj);
   glPopMatrix;
  glEndList;
 end;

procedure initializeGL(width,height:integer);
 var
  maxObjectSize,aspect:single;
  near_plane,far_plane:double;
 begin
  glClearIndex(BLACK_INDEX);
  glClearDepth(1.0);
  glEnable(GL_DEPTH_TEST);

  glMatrixMode( GL_PROJECTION );
  aspect := width / height;
  gluPerspective( 45.0, aspect, 3.0, 7.0 );
  glMatrixMode( GL_MODELVIEW );

  near_plane := 3.0;
//  far_plane := 7.0;
  maxObjectSize := 3.0;
  radius := near_plane + maxObjectSize/2.0;

  latitude := 0.0;
  longitude := 0.0;
  latinc := 6.0;

  longinc := 2.5;

  createObjects;
 end;

procedure resize(width,height:integer);
 var
  aspect:single;
 begin
  glViewport( 0, 0, width, height );
  aspect := width / height;
  glMatrixMode( GL_PROJECTION );
  glLoadIdentity;
  gluPerspective( 45.0, aspect, 3.0, 7.0 );
  glMatrixMode( GL_MODELVIEW );
 end;

procedure polarView(radius,twist,latitude,longitude:double);
 begin
  glTranslated(0.0, 0.0, -radius);
  glRotated(-twist, 0.0, 0.0, 1.0);
  glRotated(-latitude, 1.0, 0.0, 0.0);
  glRotated(longitude, 0.0, 0.0, 1.0);
 end;

procedure drawScene;
 begin
  glClear( GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT );
  glPushMatrix;
   latitude :=latitude +latinc;
   longitude:=longitude+longinc;
   polarView( radius, 0, latitude, longitude );
   glIndexi(RED_INDEX);
   glCallList(CONE);
   glIndexi(BLUE_INDEX);
   glCallList(GLOBE);
   glIndexi(GREEN_INDEX);
   glPushMatrix;
    glTranslatef(0.8, -0.65, 0.0);
    glRotatef(30.0, 1.0, 0.5, 1.0);
    glCallList(CYLINDER);
   glPopMatrix;
  glPopMatrix;
 end;

{$ifdef win32}
(* Windows globals, defines, and prototypes *)
Const
 AppName='Win OpenGL';
Var
 HWND,HDC,HRC:integer;

function bSetupPixelFormat(hdc:integer):boolean;
 var
   pfd:TPIXELFORMATDESCRIPTOR;
  ppfd:PPIXELFORMATDESCRIPTOR;
  pixelformat:integer;
 begin
  ppfd:=@pfd;
  pfd.nSize := sizeof(pfd);
  pfd.nVersion := 1;
  pfd.dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
  pfd.dwLayerMask := PFD_MAIN_PLANE;
  pfd.iPixelType := PFD_TYPE_COLORINDEX;
  pfd.cColorBits := 8;
  pfd.cDepthBits := 16;
  pfd.cAccumBits := 0;
  pfd.cStencilBits := 0;

  pixelformat := ChoosePixelFormat(hdc, ppfd);

  if ( pixelformat= 0 ) then begin
   MessageBox(0, 'ChoosePixelFormat failed', 'Error', MB_OK);
   result:=false;
   exit;
  end;

  if (SetPixelFormat(hdc, pixelformat, ppfd) = FALSE) then begin
   MessageBox(0, 'SetPixelFormat failed', 'Error', MB_OK);
   result:=FALSE;
   exit;
  end;

  result:=true;
 end;

(* main window procedure *)
function MainWndProc (hWnd,uMsg,wParam,lParam:integer):integer; stdcall;
 var
  ps:TPaintStruct;
  rect:TRect;
 begin
  Result:=1;
  case uMsg of
   WM_CREATE: begin
    HDC:=GetDC(hWnd);
    if not bSetupPixelFormat(HDC) then PostQuitMessage(0);
    HRC:=wglCreateContext(HDC);
    wglMakeCurrent(HDC, HRC);
    GetClientRect(hWnd, rect);
    initializeGL(rect.right, rect.bottom);
   end;
   WM_PAINT: begin
    BeginPaint(hWnd, ps);
    EndPaint(hWnd, ps);
   end;
   WM_SIZE: begin
    GetClientRect(hWnd, rect);
    resize(rect.right, rect.bottom);
   end;
   WM_CLOSE: begin
    if (HRC<>0) then wglDeleteContext(HRC);
    if (HDC<>0) then ReleaseDC(hWnd, HDC);
    HRC := 0;
    hDC := 0;
    DestroyWindow (hWnd);
   end;
   WM_DESTROY: begin
    if (HRC<>0) then wglDeleteContext(HRC);
    if (HDC<>0) then ReleaseDC(hWnd, HDC);
    PostQuitMessage(0);
   end;
   WM_KEYDOWN: begin
    case wParam of
     VK_LEFT : longinc:=longinc+0.5;
     VK_RIGHT: longinc:=longinc-0.5;
     VK_UP   : latinc :=latinc +0.5;
     VK_DOWN : latinc :=latinc -0.5;
    end;
   end;
   else Result:= DefWindowProc (hWnd, uMsg, wParam, lParam);
  end; // case msg
 end;

const Default8087CW: Word = $1332;{ Default 8087 control word.  FPU control
                                    register is set to this value.
                                    CAUTION:  Setting this to an invalid value
                                    could cause unpredictable behavior. }
procedure Set8087CW(NewCW: Word);
asm
        MOV     Default8087CW,AX
        FNCLEX  // don't raise pending exceptions enabled by the new flags
        FLDCW   Default8087CW
end;

var
 msg:TMsg;
 wndclass:TWndClass;
begin
 Set8087CW($133F);
(* Register the frame class *)
 wndclass.style         := 0;
 wndclass.lpfnWndProc   := @MainWndProc;
 wndclass.cbClsExtra    := 0;
 wndclass.cbWndExtra    := 0;
 wndclass.hInstance     := hInstance;
 wndclass.hIcon         := 0;//LoadIcon (hInstance, AppName);
 wndclass.hCursor       := 0;//LoadCursor (NULL,IDC_ARROW);
 wndclass.hbrBackground := COLOR_WINDOW+1;
 wndclass.lpszMenuName  := AppName;
 wndclass.lpszClassName := AppName;

 if RegisterClass(wndclass)=0 then exit;

 (* Create the frame *)
 hWnd := CreateWindow (
  AppName,
  'Generic OpenGL Sample',
  WS_OVERLAPPEDWINDOW or WS_CLIPSIBLINGS or WS_CLIPCHILDREN,
  CW_USEDEFAULT, CW_USEDEFAULT, WIDTH, HEIGHT,
  0,0, hInstance, nil
 );

 (* make sure window was created *)
 if (hWnd=0) then exit;

 (* show and update main window *)
  ShowWindow(hWnd, CmdShow);
  UpdateWindow(hWnd);

 (* animation loop *)
  while true do begin
   (* Process all pending messages  *)
   while (PeekMessage(msg, 0, 0, 0, PM_NOREMOVE) = TRUE) do begin
    if (GetMessage(msg, 0, 0, 0) ) then begin
     TranslateMessage(msg);
     DispatchMessage(msg);
    end else exit;
   end;
   drawScene;
   SwapBuffers(HDC);
  end;

{$else}{----------------------------------------------------------------------}
var
 dpy:PDisplay;
 dummy:integer;
 vi:PXVisualInfo;
 attributes:array(.0..4.) of integer=(GLX_DEPTH_SIZE, 16, GLX_DOUBLEBUFFER,GLX_RGBA, None);
 cx:integer;
 cmap:TColorMap;
 swa:XSetWindowAttributes;
 glwin:TWindow;
 event:XEvent;
 key:KeySym;

function WaitForMapNotify(d:PDisplay;e:PXEvent;arg:PChar):Bool; cdecl;
 begin
  Result:=Integer(((e.xtype = MapNotify) and (e.xmap.xwindow = integer(arg))));
 end;

begin
 dpy:=XOpenDisplay(nil);
 if dpy=nil then begin
  writeln('could not open display (XOpenDisplay)');
  halt(1);
 end;
 if not glXQueryExtension(dpy,dummy,dummy) then begin
  writeln('could not open display (glXQueryExtension)');
  halt(1);
 end;
 (* find an OpenGL-capable Color Index visual with depth buffer *)
 vi:=glXChooseVisual(dpy, XDefaultScreen(dpy), attributes);
 if (vi=nil) then begin
  Writeln('could not get visual (glXChooseVisual)');
  halt(1);
 end;
 (* create an OpenGL rendering context *)
 cx := glXCreateContext(dpy, vi,  None, True);
 if (cx = 0) then begin
  WriteLn('could not create rendering context');
  Halt(1);
 end;
 (* create an X colormap since probably not using default visual *)
 cmap:=XCreateColormap(dpy, XRootWindow(dpy, vi.screen),vi.visual, AllocNone);
 swa.colormap := cmap;
 swa.border_pixel := 0;
 swa.event_mask := ExposureMask or KeyPressMask or StructureNotifyMask;
 glwin := XCreateWindow(
  dpy, XRootWindow(dpy, vi.screen),
  0, 0, WIDTH,	HEIGHT, 0, vi.depth, InputOutput, vi.visual,
  CWBorderPixel or CWColormap or CWEventMask, @swa
 );
 Args:=ParamStr(0);
 for argc:=1 to ParamCount do Args:=Args+' '+ParamStr(argc);
 argc:=ParamCount+1;
 argv:=pchar(Args);
 XSetStandardProperties(dpy, glwin, 'xogl', 'xogl', None, addr(Argv), Argc, nil);

 glXMakeCurrent(dpy, glwin, cx);

 XMapWindow(dpy, glwin);
 XIfEvent(dpy, addr(event), WaitForMapNotify, PChar(glwin));

 initializeGL(WIDTH, HEIGHT);
 resize(WIDTH, HEIGHT);

(* Animation loop *)
 repeat
  While (XPending(dpy)<>0) do begin
   XNextEvent(dpy, addr(event));
   case (event.xtype) of
    KeyPress: begin
     XLookupString(PXKeyEvent(addr(event)), nil, 0, addr(key), nil);
     case (key)  of
      XK_Left : longinc :=longinc+0.5;
      XK_Right: longinc :=longinc-0.5;
      XK_Up   : latinc  :=latinc +0.5;
      XK_Down : latinc  :=latinc -0.5;
     end;
    end;
    ConfigureNotify:begin
     resize(event.xconfigure.width, event.xconfigure.height);
    end;
   end;
  end;
  drawScene;
  glXSwapBuffers(dpy, glwin);
 until false;
{$endif}
end.

(*-------------------------------------
 An X Windows System OpenGL Program
-------------------------------------
The following program is an X Windows System OpenGL program with the same OpenGL code used in the AUXEDEMO.C sample program supplied with the Win32 SDK. Compare this program with the Win32 OpenGL program in the next section.

/*
 * Example of an X Windows System OpenGL program.
 * OpenGL code is taken from auxdemo.c in the Win32 SDK.
 */
#include <GL/glx.h>
#include <GL/gl.h>
#include <GL/glu.h>
#include <X11/keysym.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>

/* X globals, defines, and prototypes */
Display *dpy;
Window glwin;
static int attributes[] = {GLX_DEPTH_SIZE, 16, GLX_DOUBLEBUFFER, None};

#define SWAPBUFFERS glXSwapBuffers(dpy, glwin)
#define BLACK_INDEX     0

#define RED_INDEX       1
#define GREEN_INDEX     2
#define BLUE_INDEX      4
#define WIDTH           300
#define HEIGHT          200


/* OpenGL globals, defines, and prototypes */
GLfloat latitude, longitude, latinc, longinc;
GLdouble radius;

#define GLOBE    1
#define CYLINDER 2
#define CONE     3

GLvoid resize(GLsizei, GLsizei);
GLvoid initializeGL(GLsizei, GLsizei);
GLvoid drawScene(GLvoid);
void polarView( GLdouble, GLdouble, GLdouble, GLdouble);


static Bool WaitForMapNotify(Display *d, XEvent *e, char *arg)
{
    if ((e->type == MapNotify) && (e->xmap.window == (Window)arg)) {
	return GL_TRUE;
    }
    return GL_FALSE;
}

void
main(int argc, char **argv)
{
    XVisualInfo    *vi;
    Colormap        cmap;
    XSetWindowAttributes swa;
    GLXContext      cx;
    XEvent          event;
    GLboolean       needRedraw = GL_FALSE, recalcModelView = GL_TRUE;
    int		    dummy;

    dpy = XOpenDisplay(NULL);

    if (dpy == NULL){
        fprintf(stderr, "could not open display\n");
        exit(1);
    }

    if(!glXQueryExtension(dpy, &dummy, &dummy)){
        fprintf(stderr, "could not open display");
        exit(1);
    }

    /* find an OpenGL-capable Color Index visual with depth buffer */
    vi = glXChooseVisual(dpy, DefaultScreen(dpy), attributes);
    if (vi == NULL) {
        fprintf(stderr, "could not get visual\n");
        exit(1);
    }

    /* create an OpenGL rendering context */

    cx = glXCreateContext(dpy, vi,  None, GL_TRUE);
    if (cx == NULL) {
        fprintf(stderr, "could not create rendering context\n");
        exit(1);
    }

    /* create an X colormap since probably not using default visual */
    cmap = XCreateColormap(dpy, RootWindow(dpy, vi->screen),
								vi->visual, AllocNone);
    swa.colormap = cmap;
    swa.border_pixel = 0;
    swa.event_mask = ExposureMask | KeyPressMask | StructureNotifyMask;
    glwin = XCreateWindow(dpy, RootWindow(dpy, vi->screen), 0, 0, WIDTH,

 						HEIGHT, 0, vi->depth, InputOutput, vi->visual, 						CWBorderPixel | CWColormap | CWEventMask, &swa);
    XSetStandardProperties(dpy, glwin, "xogl", "xogl", None, argv,
								argc, NULL);

    glXMakeCurrent(dpy, glwin, cx);

    XMapWindow(dpy, glwin);
    XIfEvent(dpy,  &event,  WaitForMapNotify,  (char * )glwin);

    initializeGL(WIDTH, HEIGHT);
    resize(WIDTH, HEIGHT);

    /* Animation loop */
    while (1) {
    KeySym key;


	while (XPending(dpy)) {
	    XNextEvent(dpy, &event);
	    switch (event.type) {
	    case KeyPress:
                XLookupString((XKeyEvent * )&event, NULL, 0, &key, NULL);
		switch (key) {
		case XK_Left:
		    longinc += 0.5;
		    break;
		case XK_Right:
		    longinc -= 0.5;
		    break;
		case XK_Up:
		    latinc += 0.5;
		    break;
		case XK_Down:
		    latinc -= 0.5;
		    break;
		}
		break;
	    case ConfigureNotify:

		resize(event.xconfigure.width, event.xconfigure.height);
		break;
	    }
	}
	drawScene();
    }
}

/* OpenGL code */

GLvoid resize( GLsizei width, GLsizei height )
{
    GLfloat aspect;

    glViewport( 0, 0, width, height );

    aspect = (GLfloat) width / height;

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluPerspective( 45.0, aspect, 3.0, 7.0 );
    glMatrixMode( GL_MODELVIEW );
}    

GLvoid createObjects()
{
    GLUquadricObj *quadObj;


    glNewList(GLOBE, GL_COMPILE);
        quadObj = gluNewQuadric ();
        gluQuadricDrawStyle (quadObj, GLU_LINE);
        gluSphere (quadObj, 1.5, 16, 16);
    glEndList();

    glNewList(CONE, GL_COMPILE);
        quadObj = gluNewQuadric ();
        gluQuadricDrawStyle (quadObj, GLU_FILL);
        gluQuadricNormals (quadObj, GLU_SMOOTH);
        gluCylinder(quadObj, 0.3, 0.0, 0.6, 15, 10);
    glEndList();

    glNewList(CYLINDER, GL_COMPILE);
        glPushMatrix ();

        glRotatef ((GLfloat)90.0, (GLfloat)1.0, (GLfloat)0.0, (GLfloat)0.0);
        glTranslatef ((GLfloat)0.0, (GLfloat)0.0, (GLfloat)-1.0);
        quadObj = gluNewQuadric ();
        gluQuadricDrawStyle (quadObj, GLU_FILL);
        gluQuadricNormals (quadObj, GLU_SMOOTH);
        gluCylinder (quadObj, 0.3, 0.3, 0.6, 12, 2);
        glPopMatrix ();
    glEndList();
}

GLvoid initializeGL(GLsizei width, GLsizei height)
{
    GLfloat	maxObjectSize, aspect;
    GLdouble	near_plane, far_plane;


    glClearIndex( (GLfloat)BLACK_INDEX);
    glClearDepth( 1.0 );

    glEnable(GL_DEPTH_TEST);

    glMatrixMode( GL_PROJECTION );
    aspect = (GLfloat) width / height;
    gluPerspective( 45.0, aspect, 3.0, 7.0 );
    glMatrixMode( GL_MODELVIEW );

    near_plane = 3.0;
    far_plane = 7.0;
    maxObjectSize = 3.0F;
    radius = near_plane + maxObjectSize/2.0;

    latitude = 0.0F;
    longitude = 0.0F;
    latinc = 6.0F;
    longinc = 2.5F;

    createObjects();

}

void polarView(GLdouble radius, GLdouble twist, GLdouble latitude,
	       GLdouble longitude)
{
    glTranslated(0.0, 0.0, -radius);
    glRotated(-twist, 0.0, 0.0, 1.0);
    glRotated(-latitude, 1.0, 0.0, 0.0);
    glRotated(longitude, 0.0, 0.0, 1.0);	 

}

GLvoid drawScene(GLvoid)
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glPushMatrix();

    	latitude += latinc;
    	longitude += longinc;

    	polarView( radius, 0, latitude, longitude );


        glIndexi(RED_INDEX);
        glCallList(CONE);

        glIndexi(BLUE_INDEX);
        glCallList(GLOBE);

   	glIndexi(GREEN_INDEX);
    	glPushMatrix();
            glTranslatef(0.8F, -0.65F, 0.0F);
            glRotatef(30.0F, 1.0F, 0.5F, 1.0F);
            glCallList(CYLINDER);
        glPopMatrix();

    glPopMatrix();

    SWAPBUFFERS;
}



--------------------------------
 The Program Ported to Win32
--------------------------------
The following program is a Win32 OpenGL program with the same OpenGL code used in the AUXDEMO.C sample program supplied with the Win32 SDK. Compare this program with the X Windows System OpenGL program in the above  section.

/*
 * Example of a Win32 OpenGL program. 
 * The OpenGL code is the same as that used in 
 * the X Windows System sample.
 */
#include <windows.h>
#include <GL/gl.h>
#include <GL/glu.h>

/* Windows globals, defines, and prototypes */
CHAR szAppName[]="Win OpenGL";
HWND  ghWnd;
HDC   ghDC;
HGLRC ghRC;

#define SWAPBUFFERS SwapBuffers(ghDC)
#define BLACK_INDEX     0
#define RED_INDEX       13
#define GREEN_INDEX     14
#define BLUE_INDEX      16
#define WIDTH           300

#define HEIGHT          200

LONG WINAPI MainWndProc (HWND, UINT, WPARAM, LPARAM);
BOOL bSetupPixelFormat(HDC);

/* OpenGL globals, defines, and prototypes */
GLfloat latitude, longitude, latinc, longinc;
GLdouble radius;

#define GLOBE    1
#define CYLINDER 2
#define CONE     3

GLvoid resize(GLsizei, GLsizei);
GLvoid initializeGL(GLsizei, GLsizei);
GLvoid drawScene(GLvoid);
void polarView( GLdouble, GLdouble, GLdouble, GLdouble);

int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)

{
    MSG        msg;
    WNDCLASS   wndclass;

    /* Register the frame class */
    wndclass.style         = 0;
    wndclass.lpfnWndProc   = (WNDPROC)MainWndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon (hInstance, szAppName);
    wndclass.hCursor       = LoadCursor (NULL,IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wndclass.lpszMenuName  = szAppName;

    wndclass.lpszClassName = szAppName;

    if (!RegisterClass (&wndclass) )
        return FALSE;

    /* Create the frame */
    ghWnd = CreateWindow (szAppName,
             "Generic OpenGL Sample",
	     WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
             CW_USEDEFAULT,
             CW_USEDEFAULT,
             WIDTH,
             HEIGHT,
             NULL,
             NULL,
             hInstance,
             NULL);

    /* make sure window was created */

    if (!ghWnd)
        return FALSE;

    /* show and update main window */
    ShowWindow (ghWnd, nCmdShow);

    UpdateWindow (ghWnd);

    /* animation loop */
    while (1) {
        /*
         *  Process all pending messages
         */

        while (PeekMessage(&msg, NULL, 0, 0, PM_NOREMOVE) == TRUE)
        {
            if (GetMessage(&msg, NULL, 0, 0) )
            {
                TranslateMessage(&msg);
                DispatchMessage(&msg);

            } else {
                return TRUE;
            }
        }
        drawScene();
    }
}

/* main window procedure */
LONG WINAPI MainWndProc (
    HWND    hWnd,
    UINT    uMsg,
    WPARAM  wParam,
    LPARAM  lParam)
{
    LONG    lRet = 1;
    PAINTSTRUCT    ps;
    RECT rect;

    switch (uMsg) {

    case WM_CREATE:
        ghDC = GetDC(hWnd);
        if (!bSetupPixelFormat(ghDC))
            PostQuitMessage (0);

        ghRC = wglCreateContext(ghDC);

        wglMakeCurrent(ghDC, ghRC);
        GetClientRect(hWnd, &rect);
        initializeGL(rect.right, rect.bottom);
        break;

    case WM_PAINT:
        BeginPaint(hWnd, &ps);
        EndPaint(hWnd, &ps);
        break;

    case WM_SIZE:
        GetClientRect(hWnd, &rect);
        resize(rect.right, rect.bottom);
        break;

    case WM_CLOSE:
        if (ghRC)
            wglDeleteContext(ghRC);
        if (ghDC)
            ReleaseDC(hWnd, ghDC);

        ghRC = 0;
        ghDC = 0;

        DestroyWindow (hWnd);
        break;

    case WM_DESTROY:
        if (ghRC)
            wglDeleteContext(ghRC);
        if (ghDC)
            ReleaseDC(hWnd, ghDC);

        PostQuitMessage (0);
        break;

    case WM_KEYDOWN:
        switch (wParam) {
        case VK_LEFT:
            longinc += 0.5F;
            break;
        case VK_RIGHT:
            longinc -= 0.5F;
            break;
        case VK_UP:

            latinc += 0.5F;
            break;
        case VK_DOWN:
            latinc -= 0.5F;
            break;
        }

    default:
        lRet = DefWindowProc (hWnd, uMsg, wParam, lParam);
        break;
    }

    return lRet;
}

BOOL bSetupPixelFormat(HDC hdc)
{
    PIXELFORMATDESCRIPTOR pfd, *ppfd;
    int pixelformat;

    ppfd = &pfd;

    ppfd->nSize = sizeof(PIXELFORMATDESCRIPTOR);
    ppfd->nVersion = 1;
    ppfd->dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | 

						PFD_DOUBLEBUFFER;
    ppfd->dwLayerMask = PFD_MAIN_PLANE;
    ppfd->iPixelType = PFD_TYPE_COLORINDEX;
    ppfd->cColorBits = 8;
    ppfd->cDepthBits = 16;
    ppfd->cAccumBits = 0;
    ppfd->cStencilBits = 0;

    pixelformat = ChoosePixelFormat(hdc, ppfd);

    if ( (pixelformat = ChoosePixelFormat(hdc, ppfd)) == 0 )
    {
        MessageBox(NULL, "ChoosePixelFormat failed", "Error", MB_OK);
        return FALSE;
    }

    if (SetPixelFormat(hdc, pixelformat, ppfd) == FALSE)

    {
        MessageBox(NULL, "SetPixelFormat failed", "Error", MB_OK);
        return FALSE;
    }

    return TRUE;
}

/* OpenGL code */

GLvoid resize( GLsizei width, GLsizei height )
{
    GLfloat aspect;

    glViewport( 0, 0, width, height );

    aspect = (GLfloat) width / height;

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluPerspective( 45.0, aspect, 3.0, 7.0 );
    glMatrixMode( GL_MODELVIEW );
}

GLvoid createObjects()

{
    GLUquadricObj *quadObj;

    glNewList(GLOBE, GL_COMPILE);
        quadObj = gluNewQuadric ();
        gluQuadricDrawStyle (quadObj, GLU_LINE);
        gluSphere (quadObj, 1.5, 16, 16);
    glEndList();

    glNewList(CONE, GL_COMPILE);
        quadObj = gluNewQuadric ();
        gluQuadricDrawStyle (quadObj, GLU_FILL);
        gluQuadricNormals (quadObj, GLU_SMOOTH);
        gluCylinder(quadObj, 0.3, 0.0, 0.6, 15, 10);
    glEndList();

    glNewList(CYLINDER, GL_COMPILE);

        glPushMatrix ();
        glRotatef ((GLfloat)90.0, (GLfloat)1.0, (GLfloat)0.0, (GLfloat)0.0);
        glTranslatef ((GLfloat)0.0, (GLfloat)0.0, (GLfloat)-1.0);
        quadObj = gluNewQuadric ();
        gluQuadricDrawStyle (quadObj, GLU_FILL);
        gluQuadricNormals (quadObj, GLU_SMOOTH);
        gluCylinder (quadObj, 0.3, 0.3, 0.6, 12, 2);
        glPopMatrix ();
    glEndList();
}

GLvoid initializeGL(GLsizei width, GLsizei height)
{
   	GLfloat	maxObjectSize, aspect;

	GLdouble	near_plane, far_plane;

    glClearIndex( (GLfloat)BLACK_INDEX);
    glClearDepth( 1.0 );

    glEnable(GL_DEPTH_TEST);

    glMatrixMode( GL_PROJECTION );
    aspect = (GLfloat) width / height;
    gluPerspective( 45.0, aspect, 3.0, 7.0 );
    glMatrixMode( GL_MODELVIEW );

    near_plane = 3.0;
    far_plane = 7.0;
    maxObjectSize = 3.0F;
    radius = near_plane + maxObjectSize/2.0;

    latitude = 0.0F;
    longitude = 0.0F;
    latinc = 6.0F;

    longinc = 2.5F;

    createObjects();
}

void polarView(GLdouble radius, GLdouble twist, GLdouble latitude,
	       GLdouble longitude)
{
    glTranslated(0.0, 0.0, -radius);
    glRotated(-twist, 0.0, 0.0, 1.0);
    glRotated(-latitude, 1.0, 0.0, 0.0);
    glRotated(longitude, 0.0, 0.0, 1.0);	 

}

GLvoid drawScene(GLvoid)
{
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glPushMatrix();

    	latitude += latinc;
    	longitude += longinc;


    	polarView( radius, 0, latitude, longitude );

        glIndexi(RED_INDEX);
        glCallList(CONE);

        glIndexi(BLUE_INDEX);
        glCallList(GLOBE);

   	glIndexi(GREEN_INDEX);
    	glPushMatrix();
            glTranslatef(0.8F, -0.65F, 0.0F);
            glRotatef(30.0F, 1.0F, 0.5F, 1.0F);
            glCallList(CYLINDER);
        glPopMatrix();

    glPopMatrix();

    SWAPBUFFERS;
}

*)

