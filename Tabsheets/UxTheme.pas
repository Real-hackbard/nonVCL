unit UxTheme;

interface

uses
  Windows, CommCtrl;

//---------------------------------------------------------------------------
//
// uxtheme.h - theming API header file.
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//
//---------------------------------------------------------------------------

type
  HTHEME          = THandle;
  LPCRECT         = ^TRect;
  LPRECT          = ^TRect;
  PHRGN           = ^HRGN;
  PCOLORREF       = ^COLORREF;
  PHBITMAP        = ^HBITMAP;
  PHDC            = ^HDC;
  HINST           = LongInt;
const
  MAX_THEMECOLOR  = 64;
  MAX_THEMESIZE   = 64;


//---------------------------------------------------------------------------
// NOTE: PartId's and StateId's used in the theme API are defined in the
//       hdr file <vssym32.h> using the TM_PART and TM_STATE macros.  For
//       example, "TM_PART(BP, PUSHBUTTON)" defines the PartId "BP_PUSHBUTTON".

//---------------------------------------------------------------------------
//  OpenThemeData()     - Open the theme data for the specified HWND and
//                        semi-colon separated list of class names.
//
//                        OpenThemeData() will try each class name, one at
//                        a time, and use the first matching theme info
//                        found.  If a match is found, a theme handle
//                        to the data is returned.  If no match is found,
//                        a "NULL" handle is returned.
//
//                        When the window is destroyed or a WM_THEMECHANGED
//                        msg is received, "CloseThemeData()" should be
//                        called to close the theme handle.
//
//  hwnd                - window handle of the control/window to be themed
//
//  pszClassList        - class name (or list of names) to match to theme data
//                        section.  if the list contains more than one name,
//                        the names are tested one at a time for a match.
//                        If a match is found, OpenThemeData() returns a
//                        theme handle associated with the matching class.
//                        This param is a list (instead of just a single
//                        class name) to provide the class an opportunity
//                        to get the "best" match between the class and
//                        the current theme.  For example, a button might
//                        pass L"OkButton, Button" if its ID=ID_OK.  If
//                        the current theme has an entry for OkButton,
//                        that will be used.  Otherwise, we fall back on
//                        the normal Button entry.
//---------------------------------------------------------------------------

type
  TOpenThemeData = function(wnd: HWND; pszClassList: PwideChar): HTHEME; stdcall;
var
  OpenThemeData  : TOpenThemeData;

const
  OTD_FORCE_RECT_SIZING  = $00000001;          // make all parts size to rect
  OTD_NONCLIENT          = $00000002;          // set if hTheme to be used for nonclient area
  OTD_VALIDBITS          = OTD_FORCE_RECT_SIZING or OTD_NONCLIENT;


//---------------------------------------------------------------------------
//  OpenThemeDataEx     - Open the theme data for the specified HWND and
//                        semi-colon separated list of class names.
//
//                        OpenThemeData() will try each class name, one at
//                        a time, and use the first matching theme info
//                        found.  If a match is found, a theme handle
//                        to the data is returned.  If no match is found,
//                        a "NULL" handle is returned.
//
//                        When the window is destroyed or a WM_THEMECHANGED
//                        msg is received, "CloseThemeData()" should be
//                        called to close the theme handle.
//
//  hwnd                - window handle of the control/window to be themed
//
//  pszClassList        - class name (or list of names) to match to theme data
//                        section.  if the list contains more than one name,
//                        the names are tested one at a time for a match.
//                        If a match is found, OpenThemeData() returns a
//                        theme handle associated with the matching class.
//                        This param is a list (instead of just a single
//                        class name) to provide the class an opportunity
//                        to get the "best" match between the class and
//                        the current theme.  For example, a button might
//                        pass L"OkButton, Button" if its ID=ID_OK.  If
//                        the current theme has an entry for OkButton,
//                        that will be used.  Otherwise, we fall back on
//                        the normal Button entry.
//
//  dwFlags              - allows certain overrides of std features
//                         (see OTD_XXX defines above)
//---------------------------------------------------------------------------

type
  TOpenThemeDataEx = function(wnd: HWND; pszClassList: PWideChar;
    dwFlags: dword): HTHEME; stdcall;
var
  OpenThemeDataEx  : TOpenThemeDataEx;


//---------------------------------------------------------------------------
//  CloseThemeData()    - closes the theme data handle.  This should be done
//                        when the window being themed is destroyed or
//                        whenever a WM_THEMECHANGED msg is received
//                        (followed by an attempt to create a new Theme data
//                        handle).
//
//  hTheme              - open theme data handle (returned from prior call
//                        to OpenThemeData() API).
//---------------------------------------------------------------------------

type
  TCloseThemeData = function(theme: HTHEME): HRESULT; stdcall;
var
  CloseThemeData  : TCloseThemeData;


//---------------------------------------------------------------------------
//    functions for basic drawing support
//---------------------------------------------------------------------------
// The following methods are the theme-aware drawing services.
// Controls/Windows are defined in drawable "parts" by their author: a
// parent part and 0 or more child parts.  Each of the parts can be
// described in "states" (ex: disabled, hot, pressed).
//---------------------------------------------------------------------------
// For the list of all themed classes and the definition of all
// parts and states, see the file "tmschmea.h".
//---------------------------------------------------------------------------
// Each of the below methods takes a "iPartId" param to specify the
// part and a "iStateId" to specify the state of the part.
// "iStateId=0" refers to the root part.  "iPartId" = "0" refers to
// the root class.
//-----------------------------------------------------------------------
// Note: draw operations are always scaled to fit (and not to exceed)
// the specified "Rect".
//-----------------------------------------------------------------------

//------------------------------------------------------------------------
//  DrawThemeBackground()
//                      - draws the theme-specified border and fill for
//                        the "iPartId" and "iStateId".  This could be
//                        based on a bitmap file, a border and fill, or
//                        other image description.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part) to draw
//  pRect               - defines the size/location of the part
//  pClipRect           - optional clipping rect (don't draw outside it)
//------------------------------------------------------------------------

type
  TDrawThemeBackground = function(theme: HTHEME; dc: HDC; iPartId: integer;
    iStateId: integer; pRect: LPCRECT; pClipRect: LPCRECT): HRESULT; stdcall;
var
  DrawThemeBackground  : TDrawThemeBackground;


//------------------------------------------------------------------------
//---- bits used in dwFlags of DTBGOPTS ----
const
  DTBG_CLIPRECT           = $00000001;  // rcClip has been specified
  DTBG_DRAWSOLID          = $00000002;  // DEPRECATED: draw transparent/alpha images as solid
  DTBG_OMITBORDER         = $00000004;  // don't draw border of part
  DTBG_OMITCONTENT        = $00000008;  // don't draw content area of part
  DTBG_COMPUTINGREGION    = $00000010;  // TRUE if calling to compute region
  DTBG_MIRRORDC           = $00000020;  // assume the hdc is mirrorred and
                                        // flip images as appropriate (currently
                                        // only supported for bgtype=imagefile)
  DTBG_NOMIRROR           = $00000040;  // don't mirror the output, overrides everything else
  DTBG_VALIDBITS          = DTBG_CLIPRECT or
                            DTBG_DRAWSOLID or
                            DTBG_OMITBORDER or
                            DTBG_OMITCONTENT or
                            DTBG_COMPUTINGREGION or
                            DTBG_MIRRORDC or
                            DTBG_NOMIRROR;

type
  _DTBGOPTS = packed record
     dwSize,               // size of the struct
    dwFlags  : dword;      // which options have been specified
    rcClip   : TRect;      // clipping rectangle
  end;
  TDTBGOpts = _DTBGOPTS;
  PDTBGOpts = ^TDTBGOpts;


//------------------------------------------------------------------------
//  DrawThemeBackgroundEx()
//                      - draws the theme-specified border and fill for
//                        the "iPartId" and "iStateId".  This could be
//                        based on a bitmap file, a border and fill, or
//                        other image description.  NOTE: This will be
//                        merged back into DrawThemeBackground() after
//                        BETA 2.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part) to draw
//  pRect               - defines the size/location of the part
//  pOptions            - ptr to optional params
//------------------------------------------------------------------------

type
  TDrawThemeBackgroundEx = function(theme: HTHEME; dc: HDC;
    iPartId: integer; iStateId: integer; pRect: LPCRECT;
    pOptions: PDTBGOpts): HRESULT; stdcall;
var
  DrawThemeBackgroundEx  : TDrawThemeBackgroundEx;


//---------------------------------------------------------------------------
//----- DrawThemeText() flags ----
const
  DTT_GRAYED              = $00000001;          // draw a grayed-out string (this is deprecated)
  DTT_FLAGS2VALIDBITS     = DTT_GRAYED;


//-------------------------------------------------------------------------
//  DrawThemeText()     - draws the text using the theme-specified
//                        color and font for the "iPartId" and
//                        "iStateId".
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part) to draw
//  pszText             - actual text to draw
//  dwCharCount         - number of chars to draw (-1 for all)
//  dwTextFlags         - same as DrawText() "uFormat" param
//  dwTextFlags2        - additional drawing options
//  pRect               - defines the size/location of the part
//-------------------------------------------------------------------------

type
  TDrawThemeText = function(theme: HTHEME; dc: HDC; iPartId: integer;
    iStateId: integer; pszText: PWideChar; cchText: integer;
    dwTextFlags, dwTextFlags2: dword): HRESULT; stdcall;
var
  DrawThemeText  : TDrawThemeText;


//---------------------------------------------------------------------------
//
// DrawThemeTextEx
//

// Callback function used by DrawTextWithGlow instead of DrawTextW
(*
typedef
int
(WINAPI *DTT_CALLBACK_PROC)
(
    __in HDC hdc,
    __inout_ecount(cchText) LPWSTR pszText,
    __in int cchText,
    __inout LPRECT prc,
    __in UINT dwFlags,
    __in LPARAM lParam);
*)

//---- bits used in dwFlags of DTTOPTS ----
const
  DTT_TEXTCOLOR       = $00000001 shl 0;      // crText has been specified
  DTT_BORDERCOLOR     = $00000001 shl 1;      // crBorder has been specified
  DTT_SHADOWCOLOR     = $00000001 shl 2;      // crShadow has been specified
  DTT_SHADOWTYPE      = $00000001 shl 3;      // iTextShadowType has been specified
  DTT_SHADOWOFFSET    = $00000001 shl 4;      // ptShadowOffset has been specified
  DTT_BORDERSIZE      = $00000001 shl 5;      // iBorderSize has been specified
  DTT_FONTPROP        = $00000001 shl 6;      // iFontPropId has been specified
  DTT_COLORPROP       = $00000001 shl 7;      // iColorPropId has been specified
  DTT_STATEID         = $00000001 shl 8;      // IStateId has been specified
  DTT_CALCRECT        = $00000001 shl 9;      // Use pRect as and in/out parameter
  DTT_APPLYOVERLAY    = $00000001 shl 10;     // fApplyOverlay has been specified
  DTT_GLOWSIZE        = $00000001 shl 11;     // iGlowSize has been specified
  DTT_CALLBACK        = $00000001 shl 12;     // pfnDrawTextCallback has been specified
  DTT_COMPOSITED      = $00000001 shl 13;     // Draws text with antialiased alpha (needs a DIB section)
  DTT_VALIDBITS       = DTT_TEXTCOLOR or
                        DTT_BORDERCOLOR or
                        DTT_SHADOWCOLOR or
                        DTT_SHADOWTYPE or
                        DTT_SHADOWOFFSET or
                        DTT_BORDERSIZE or
                        DTT_FONTPROP or
                        DTT_COLORPROP or
                        DTT_STATEID or
                        DTT_CALCRECT or
                        DTT_APPLYOVERLAY or
                        DTT_GLOWSIZE or
                        DTT_COMPOSITED;
type
  _DTTOPTS = packed record
    dwSize,						            // size of the struct
    dwFlags : dword;						// which options have been specified
    crText,									// color to use for text fill
    crBorder,								// color to use for text outline
    crShadow : COLORREF;					// color to use for text shadow
    iTextShadowType : integer;				// TST_SINGLE or TST_CONTINUOUS
    ptShadowOffset : TPoint;				// where shadow is drawn (relative to text)
    iBorderSize,							// Border radius around text
    iFontPropId,							// Font property to use for the text instead of TMT_FONT
    iColorPropId,							// Color property to use for the text instead of TMT_TEXTCOLOR
    iStateId : integer;						// Alternate state id
    fApplyOverlay : bool;					// Overlay text on top of any text effect?
    iGlowSize : integer;					// Glow radious around text
    pfnDrawTextCallback : pointer;			// Callback for DrawText; s. DTT_CALLBACK_PROC
    Param : LPARAM;							// Parameter for callback
  end;
  TDTTOpts = _DTTOPTS;
  PDTTOpts = ^TDTTOpts;

  TDrawThemeTextEx = function(theme: HTHEME; dc: HDC; iPartId: integer;
    iStateId: integer; pszText: PWideChar; cchText: integer;
    dwTextFlags: dword; rect: PRect; pOptions: PDTTOpts): HRESULT; stdcall;
var
  DrawThemeTextEx  : TDrawThemeTextEx;


//-------------------------------------------------------------------------
//  GetThemeBackgroundContentRect()
//                      - gets the size of the content for the theme-defined
//                        background.  This is usually the area inside
//                        the borders or Margins.
//
//      hTheme          - theme data handle
//      hdc             - (optional) device content to be used for drawing
//      iPartId         - part number to draw
//      iStateId        - state number (of the part) to draw
//      pBoundingRect   - the outer RECT of the part being drawn
//      pContentRect    - RECT to receive the content area
//-------------------------------------------------------------------------

type
  TGetThemeBackgroundContentRect = function(theme: HTHEME; dc: HDC;
    iPartId, iStateId: integer; pBoundingRect, pContentRect: PRect): HRESULT;
    stdcall;
var
  GetThemeBackgroundContentRect  : TGetThemeBackgroundContentRect;


//-------------------------------------------------------------------------
//  GetThemeBackgroundExtent() - calculates the size/location of the theme-
//                               specified background based on the
//                               "pContentRect".
//
//      hTheme          - theme data handle
//      hdc             - (optional) device content to be used for drawing
//      iPartId         - part number to draw
//      iStateId        - state number (of the part) to draw
//      pContentRect    - RECT that defines the content area
//      pBoundingRect   - RECT to receive the overall size/location of part
//-------------------------------------------------------------------------

type
  TGetThemeBackgroundExtent = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; pContentRect, pExtentRect: PRect): HRESULT; stdcall;
var
  GetThemeBackgroundExtent  : TGetThemeBackgroundExtent;


//-------------------------------------------------------------------------
//  GetThemeBackgroundRegion()
//                      - computes the region for a regular or partially
//                        transparent theme-specified background that is
//                        bound by the specified "pRect".
//                        If the rectangle is empty, sets the HRGN to NULL
//                        and return S_FALSE.
//
//  hTheme              - theme data handle
//  hdc                 - optional HDC to draw into (DPI scaling)
//  iPartId             - part number to draw
//  iStateId            - state number (of the part)
//  pRect               - the RECT used to draw the part
//  pRegion             - receives handle to calculated region
//-------------------------------------------------------------------------

type
  TGetThemeBackgroundRegion = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; rect: LPCRECT; pRegion: PHRGN): HRESULT; stdcall;
var
  GetThemeBackgroundRegion  : TGetThemeBackgroundRegion;

const
//enum THEMESIZE
    TS_MIN     = 0;     // minimum size
    TS_TRUE    = 1;     // size without stretching
    TS_DRAW    = 2;     // size that theme mgr will use to draw part


//-------------------------------------------------------------------------
//  GetThemePartSize() - returns the specified size of the theme part
//
//  hTheme              - theme data handle
//  hdc                 - HDC to select font into & measure against
//  iPartId             - part number to retrieve size for
//  iStateId            - state number (of the part)
//  prc                 - (optional) rect for part drawing destination
//  eSize               - the type of size to be retreived
//  psz                 - receives the specified size of the part
//-------------------------------------------------------------------------

type
  TGetThemePartSize = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; prc: PRect; eSize: uint { THEMESIZE };
    psz: SIZE): HRESULT; stdcall;
var
  GetThemePartSize  : TGetThemePartSize;


//-------------------------------------------------------------------------
//  GetThemeTextExtent() - calculates the size/location of the specified
//                         text when rendered in the Theme Font.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to select font & measure into
//  iPartId             - part number to draw
//  iStateId            - state number (of the part)
//  pszText             - the text to be measured
//  dwCharCount         - number of chars to draw (-1 for all)
//  dwTextFlags         - same as DrawText() "uFormat" param
//  pszBoundingRect     - optional: to control layout of text
//  pszExtentRect       - receives the RECT for text size/location
//-------------------------------------------------------------------------

type
  TGetThemeTextExtent = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; pszText: PWideChar; cchCharCount: integer;
    dwTextFlags: dword; pBoundingRect, pExtentRect: LPCRECT): HRESULT;
    stdcall;
var
  GetThemeTextExtent  : TGetThemeTextExtent;


//-------------------------------------------------------------------------
//  GetThemeTextMetrics()
//                      - returns info about the theme-specified font
//                        for the part/state passed in.
//
//  hTheme              - theme data handle
//  hdc                 - optional: HDC for screen context
//  iPartId             - part number to draw
//  iStateId            - state number (of the part)
//  ptm                 - receives the font info
//-------------------------------------------------------------------------

type
  TGetThemeTextMetrics = function(theme: HTHEME;  dc: HDC; iPartId,
    iStateId: integer; ptm: PTextMetricW): HRESULT; stdcall;
var
  GetThemeTextMetrics  : TGetThemeTextMetrics;


//-------------------------------------------------------------------------
//----- HitTestThemeBackground, HitTestThemeBackgroundRegion flags ----

const
//  Theme background segment hit test flag (default). possible return values are:
//  HTCLIENT: hit test succeeded in the middle background segment
//  HTTOP, HTLEFT, HTTOPLEFT, etc:  // hit test succeeded in the the respective theme background segment.
  HTTB_BACKGROUNDSEG          = $00000000;
//  Fixed border hit test option.  possible return values are:
//  HTCLIENT: hit test succeeded in the middle background segment
//  HTBORDER: hit test succeeded in any other background segment
  HTTB_FIXEDBORDER            = $00000002;      // Return code may be either HTCLIENT or HTBORDER.
//  Caption hit test option.  Possible return values are:
//  HTCAPTION: hit test succeeded in the top, top left, or top right background segments
//  HTNOWHERE or another return code, depending on absence or presence of accompanying flags, resp.
  HTTB_CAPTION                = $00000004;
//  Resizing border hit test flags.  Possible return values are:
//  HTCLIENT: hit test succeeded in middle background segment
//  HTTOP, HTTOPLEFT, HTLEFT, HTRIGHT, etc:    hit test succeeded in the respective system resizing zone
//  HTBORDER: hit test failed in middle segment and resizing zones, but succeeded in a background border segment
  HTTB_RESIZINGBORDER_LEFT    = $00000010;      // Hit test left resizing border,
  HTTB_RESIZINGBORDER_TOP     = $00000020;      // Hit test top resizing border
  HTTB_RESIZINGBORDER_RIGHT   = $00000040;      // Hit test right resizing border
  HTTB_RESIZINGBORDER_BOTTOM  = $00000080;      // Hit test bottom resizing border
  HTTB_RESIZINGBORDER         = HTTB_RESIZINGBORDER_LEFT or
                                HTTB_RESIZINGBORDER_TOP or
                                HTTB_RESIZINGBORDER_RIGHT or
                                HTTB_RESIZINGBORDER_BOTTOM;
// Resizing border is specified as a template, not just window edges.
// This option is mutually exclusive with HTTB_SYSTEMSIZINGWIDTH; HTTB_SIZINGTEMPLATE takes precedence
  HTTB_SIZINGTEMPLATE         = $00000100;
// Use system resizing border width rather than theme content margins.
// This option is mutually exclusive with HTTB_SIZINGTEMPLATE, which takes precedence.
  HTTB_SYSTEMSIZINGMARGINS    = $00000200;

//-------------------------------------------------------------------------
//  HitTestThemeBackground()
//                      - returns a HitTestCode (a subset of the values
//                        returned by WM_NCHITTEST) for the point "ptTest"
//                        within the theme-specified background
//                        (bound by pRect).  "pRect" and "ptTest" should
//                        both be in the same coordinate system
//                        (client, screen, etc).
//
//      hTheme          - theme data handle
//      hdc             - HDC to draw into
//      iPartId         - part number to test against
//      iStateId        - state number (of the part)
//      pRect           - the RECT used to draw the part
//      hrgn            - optional region to use; must be in same coordinates as
//                      -    pRect and pTest.
//      ptTest          - the hit point to be tested
//      dwOptions       - HTTB_xxx constants
//      pwHitTestCode   - receives the returned hit test code - one of:
//
//                        HTNOWHERE, HTLEFT, HTTOPLEFT, HTBOTTOMLEFT,
//                        HTRIGHT, HTTOPRIGHT, HTBOTTOMRIGHT,
//                        HTTOP, HTBOTTOM, HTCLIENT
//-------------------------------------------------------------------------

type
  THitTestThemeBackground = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; dwOptions: dword; rect: LPCRECT; rgn: HRGN;
    pwHitTestCode: PWord): HRESULT; stdcall;
var
  HitTestThemeBackground  : THitTestThemeBackground;


//------------------------------------------------------------------------
//  DrawThemeEdge()     - Similar to the DrawEdge() API, but uses part colors
//                        and is high-DPI aware
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number of part
//  pDestRect           - the RECT used to draw the line(s)
//  uEdge               - Same as DrawEdge() API
//  uFlags              - Same as DrawEdge() API
//  pContentRect        - Receives the interior rect if (uFlags & BF_ADJUST)
//------------------------------------------------------------------------

type
  TDrawThemeEdge = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; pDestRect: LPCRECT; uEdge: uint;
    uFlags: uint; pContentRect: LPCRECT): HRESULT; stdcall;
var
  DrawThemeEdge  : TDrawThemeEdge;


//------------------------------------------------------------------------
//  DrawThemeIcon()     - draws an image within an imagelist based on
//                        a (possible) theme-defined effect.
//
//  hTheme              - theme data handle
//  hdc                 - HDC to draw into
//  iPartId             - part number to draw
//  iStateId            - state number of part
//  pRect               - the RECT to draw the image within
//  himl                - handle to IMAGELIST
//  iImageIndex         - index into IMAGELIST (which icon to draw)
//------------------------------------------------------------------------

type
  TDrawThemeIcon = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId: integer; pRect: LPCRECT; himl: HIMAGELIST;
    iImageIndex: integer): HRESULT; stdcall;
var
  DrawThemeIcon  : TDrawThemeIcon;


//---------------------------------------------------------------------------
//  IsThemePartDefined() - returns TRUE if the theme has defined parameters
//                         for the specified "iPartId" and "iStateId".
//
//  hTheme              - theme data handle
//  iPartId             - part number to find definition for
//  iStateId            - state number of part
//---------------------------------------------------------------------------
type
  TIsThemePartDefined = function(theme: HTHEME; iPartId, iStateId: integer):
    bool; stdcall;
var
  IsThemePartDefined  : TIsThemePartDefined;


//---------------------------------------------------------------------------
//  IsThemeBackgroundPartiallyTransparent()
//                      - returns TRUE if the theme specified background for
//                        the part/state has transparent pieces or
//                        alpha-blended pieces.
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//---------------------------------------------------------------------------

type
  TIsThemeBackgroundPartiallyTransparent = function(theme: HTHEME; iPartId,
    iStateId: integer): bool; stdcall;
var
  IsThemeBackgroundPartiallyTransparent  : TIsThemeBackgroundPartiallyTransparent;


//---------------------------------------------------------------------------
//    lower-level theme information services
//---------------------------------------------------------------------------
// The following methods are getter routines for each of the Theme Data types.
// Controls/Windows are defined in drawable "parts" by their author: a
// parent part and 0 or more child parts.  Each of the parts can be
// described in "states" (ex: disabled, hot, pressed).
//---------------------------------------------------------------------------
// Each of the below methods takes a "iPartId" param to specify the
// part and a "iStateId" to specify the state of the part.
// "iStateId=0" refers to the root part.  "iPartId" = "0" refers to
// the root class.
//-----------------------------------------------------------------------
// Each method also take a "iPropId" param because multiple instances of
// the same primitive type can be defined in the theme schema.
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
//  GetThemeColor()     - Get the value for the specified COLOR property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pColor              - receives the value of the property
//-----------------------------------------------------------------------

type
  TGetThemeColor = function(theme: HTHEME; iPartId, iStateId: integer;
    iPropId: integer; pColor: PCOLORREF): HRESULT; stdcall;
var
  GetThemeColor  : TGetThemeColor;


//-----------------------------------------------------------------------
//  GetThemeMetric()    - Get the value for the specified metric/size
//                        property
//
//  hTheme              - theme data handle
//  hdc                 - (optional) hdc to be drawn into (DPI scaling)
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  piVal               - receives the value of the property
//-----------------------------------------------------------------------

type
  TGetThemeMetric = function(theme: HTHEME; dc: HDC; iPartId,
    iStateId, iPropId: integer; piVal: PInteger): HRESULT; stdcall;
var
  GetThemeMetric  : TGetThemeMetric;


//-----------------------------------------------------------------------
//  GetThemeString()    - Get the value for the specified string property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pszBuff             - receives the string property value
//  cchMaxBuffChars     - max. number of chars allowed in pszBuff
//-----------------------------------------------------------------------

type
  TGetThemeString = function(theme: HTHEME; iPartId, iStateId, iPropId:
    integer; pszBuff: PWideChar; cchMaxBufChars: integer): HRESULT;
    stdcall;
var
  GetThemeString  : TGetThemeString;


//-----------------------------------------------------------------------
//  GetThemeBool()      - Get the value for the specified BOOL property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pfVal               - receives the value of the property
//-----------------------------------------------------------------------

type
  TGetThemeBool = function(theme: HTHEME; iPartId, iStateId, iPropId:
    integer; pfVal: PBOOL): HRESULT; stdcall;
var
  GetThemeBool  : TGetThemeBool;


//-----------------------------------------------------------------------
//  GetThemeInt()       - Get the value for the specified int property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  piVal               - receives the value of the property
//-----------------------------------------------------------------------

type
  TGetThemeInt = function(theme: HTHEME; iPartId, iStateId, iPropId:
    integer; piVal: PInteger): HRESULT; stdcall;
var
  GetThemeInt  : TGetThemeInt;


//-----------------------------------------------------------------------
//  GetThemeEnumValue() - Get the value for the specified ENUM property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  piVal               - receives the value of the enum (cast to int*)
//-----------------------------------------------------------------------

type
  TGetThemeEnumValue = function(theme: HTHEME; iPartId, iStateId,
    iPropId: integer; piVal: PInteger): HRESULT; stdcall;
var
  GetThemeEnumValue  : TGetThemeEnumValue;


//-----------------------------------------------------------------------
//  GetThemePosition()  - Get the value for the specified position
//                        property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pPoint              - receives the value of the position property
//-----------------------------------------------------------------------

type
  TGetThemePosition = function(theme: HTHEME; iPartId, iStateId,
    iPropId: integer; point: PPoint): HRESULT; stdcall;
var
  GetThemePosition  : TGetThemePosition;


//-----------------------------------------------------------------------
//  GetThemeFont()      - Get the value for the specified font property
//
//  hTheme              - theme data handle
//  hdc                 - (optional) hdc to be drawn to (DPI scaling)
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pFont               - receives the value of the LOGFONT property
//                        (scaled for the current logical screen dpi)
//-----------------------------------------------------------------------

type
  TGetThemeFont = function(them: HTHEME; dc: HDC; iPartId, iStateId,
    iPropId: integer; pFont: PLOGFONTW): HRESULT; stdcall;
var
  GetThemeFont  : TGetThemeFont;


//-----------------------------------------------------------------------
//  GetThemeRect()      - Get the value for the specified RECT property
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to get the value for
//  pRect               - receives the value of the RECT property
//-----------------------------------------------------------------------

type
  TGetThemeRect = function(theme: HTHEME; iPartId, iStateId, iPropId:
    integer; rect: LPRECT): HRESULT; stdcall;
var
  GetThemeRect  : TGetThemeRect;

type
  _MARGINS = packed record
    cxLeftWidth,                // width of left border that retains its size
    cxRightWidth,               // width of right border that retains its size
    cyTopHeight,                // height of top border that retains its size
    cyBottomHeight : integer;   // height of bottom border that retains its size
  end;
  TMargins = _MARGINS;
  PMargins = ^TMargins;


//-----------------------------------------------------------------------
//  GetThemeMargins()   - Get the value for the specified MARGINS property
//
//      hTheme          - theme data handle
//      hdc             - (optional) hdc to be used for drawing
//      iPartId         - part number
//      iStateId        - state number of part
//      iPropId         - the property number to get the value for
//      prc             - RECT for area to be drawn into
//      pMargins        - receives the value of the MARGINS property
//-----------------------------------------------------------------------

type
  TGetThemeMargins = function(theme: HTHEME; iPartId, iStateId,
    iPropId: integer; prc: LPCRECT; margins: PMargins): HRESULT; stdcall;
var
  GetThemeMargins  : TGetThemeMargins;


const
  MAX_INTLIST_COUNT_VISTA = 402;
  MAX_INTLIST_COUNT = 10;
type
  _INTLIST_VISTA = packed record
    iValueCount : integer;      // number of values in iValues
    iValues : array[0..MAX_INTLIST_COUNT_VISTA - 1] of integer;
  end;
  TIntListVista = _INTLIST_VISTA;
  PIntListVista = ^TIntListVista;

  _INTLIST = packed record
    iValueCount : integer;      // number of values in iValues
    iValues : array[0..MAX_INTLIST_COUNT - 1] of integer;
  end;
  TIntList = _INTLIST;
  PIntList = ^TIntList;

//-----------------------------------------------------------------------
//  GetThemeIntList()   - Get the value for the specified INTLIST struct
//
//      hTheme          - theme data handle
//      iPartId         - part number
//      iStateId        - state number of part
//      iPropId         - the property number to get the value for
//      pIntList        - receives the value of the INTLIST property
//-----------------------------------------------------------------------

type
  TGetThemeIntList = function(theme: HTHEME; iPartId, iStateId,
    iPropId: integer; pil: pointer { PIntList(Vista) }): HRESULT;
    stdcall;
var
  GetThemeIntList  : TGetThemeIntList;

const
// enum PROPERTYORIGIN
    PO_STATE    = 0;         // property was found in the state section
    PO_PART     = 1;         // property was found in the part section
    PO_CLASS    = 2;         // property was found in the class section
    PO_GLOBAL   = 3;         // property was found in [globals] section
    PO_NOTFOUND = 4;         // property was not found


//-----------------------------------------------------------------------
//  GetThemePropertyOrigin()
//                      - searches for the specified theme property
//                        and sets "pOrigin" to indicate where it was
//                        found (or not found)
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to search for
//  pOrigin             - receives the value of the property origin
//-----------------------------------------------------------------------

type
  TGetThemePropertyOrigin = function(theme: HTHEME; iPartId, iStateId,
    iPropId: integer; pOrigin: PUINT): HRESULT; stdcall;
var
  GetThemePropertyOrigin  : TGetThemePropertyOrigin;


//---------------------------------------------------------------------------
//  SetWindowTheme()
//                      - redirects an existing Window to use a different
//                        section of the current theme information than its
//                        class normally asks for.
//
//  hwnd                - the handle of the window (cannot be NULL)
//
//  pszSubAppName       - app (group) name to use in place of the calling
//                        app's name.  If NULL, the actual calling app
//                        name will be used.
//
//  pszSubIdList        - semicolon separated list of class Id names to
//                        use in place of actual list passed by the
//                        window's class.  if NULL, the id list from the
//                        calling class is used.
//---------------------------------------------------------------------------
// The Theme Manager will remember the "pszSubAppName" and the
// "pszSubIdList" associations thru the lifetime of the window (even
// if themes are subsequently changed).  The window is sent a
// "WM_THEMECHANGED" msg at the end of this call, so that the new
// theme can be found and applied.
//---------------------------------------------------------------------------
// When "pszSubAppName" or "pszSubIdList" are NULL, the Theme Manager
// removes the previously remember association.  To turn off theme-ing for
// the specified window, you can pass an empty string (L"") so it
// won't match any section entries.
//---------------------------------------------------------------------------

type
  TSetWindowTheme = function(wnd: HWND; pszSubAppName, pszSubIdList:
    PWideChar): HRESULT; stdcall;
var
  SetWindowTheme  : TSetWindowTheme;


const
// enum WINDOWTHEMEATTRIBUTETYPE
  WTA_NONCLIENT = 1;
type
  _WTA_OPTIONS = packed record
    dwFlags,                // values for each style option specified in the bitmask
    dwMask  : dword;        // bitmask for flags that are changing
                            // valid options are: WTNCA_NODRAWCAPTION, WTNCA_NODRAWICON, WTNCA_NOSYSMENU
  end;
  TWtaOptions = _WTA_OPTIONS;
  PWtaOptions = ^TWtaOptions;
const
  WTNCA_NODRAWCAPTION       = $00000001;    // don't draw the window caption
  WTNCA_NODRAWICON          = $00000002;    // don't draw the system icon
  WTNCA_NOSYSMENU           = $00000004;    // don't expose the system menu icon functionality
  WTNCA_NOMIRRORHELP        = $00000008;    // don't mirror the question mark, even in RTL layout
  WTNCA_VALIDBITS           = WTNCA_NODRAWCAPTION or
                              WTNCA_NODRAWICON or
                              WTNCA_NOSYSMENU or
                              WTNCA_NOMIRRORHELP;

type
  TSetWindowThemeAttribute = function(wnd: HWND; eAttribute: uint;
    pvAttribute: pointer; cbAttribute: dword): HRESULT; stdcall;
var
  SetWindowThemeAttribute  : TSetWindowThemeAttribute;

  function SetWindowThemeNonClientAttributes(wnd: HWND; dwMask,
    dwAttributes: dword): HRESULT;


//---------------------------------------------------------------------------
//  GetThemeFilename()  - Get the value for the specified FILENAME property.
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateId            - state number of part
//  iPropId             - the property number to search for
//  pszThemeFileName    - output buffer to receive the filename
//  cchMaxBuffChars     - the size of the return buffer, in chars
//---------------------------------------------------------------------------

type
  TGetThemeFilename = function(theme: HTHEME; iPartId, iStateId, iPropId:
    integer; pszThemeFileName: PWideChar; cchMaxBuffChars: integer):
    HRESULT; stdcall;
var
  GetThemeFilename  : TGetThemeFilename;


//---------------------------------------------------------------------------
//  GetThemeSysColor()  - Get the value of the specified System color.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        color from [SysMetrics] section of theme.
//                        if NULL, will return the global system color.
//
//  iColorId            - the system color index defined in winuser.h
//---------------------------------------------------------------------------

type
  TGetThemeSysColor = function(theme: HTHEME; iColorId: integer):
    COLORREF; stdcall;
var
  GetThemeSysColor : TGetThemeSysColor;


//---------------------------------------------------------------------------
//  GetThemeSysColorBrush()
//                      - Get the brush for the specified System color.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        brush matching color from [SysMetrics] section of
//                        theme.  if NULL, will return the brush matching
//                        global system color.
//
//  iColorId            - the system color index defined in winuser.h
//---------------------------------------------------------------------------

type
  TGetThemeSysColorBrush = function(theme: HTHEME; iColorId: integer):
    HBRUSH; stdcall;
var
  GetThemeSysColorBrush  : TGetThemeSysColorBrush;


//---------------------------------------------------------------------------
//  GetThemeSysBool()   - Get the boolean value of specified System metric.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        BOOL from [SysMetrics] section of theme.
//                        if NULL, will return the specified system boolean.
//
//  iBoolId             - the TMT_XXX BOOL number (first BOOL
//                        is TMT_FLATMENUS)
//---------------------------------------------------------------------------

type
  TGetThemeSysBool = function(theme: HTHEME; iBoolId: integer):
    BOOL; stdcall;
var
  GetThemeSysBool  : TGetThemeSysBool;


//---------------------------------------------------------------------------
//  GetThemeSysSize()   - Get the value of the specified System size metric.
//                        (scaled for the current logical screen dpi)
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        size from [SysMetrics] section of theme.
//                        if NULL, will return the global system metric.
//
//  iSizeId             - the following values are supported when
//                        hTheme is non-NULL:
//
//                          SM_CXBORDER       (border width)
//                          SM_CXVSCROLL      (scrollbar width)
//                          SM_CYHSCROLL      (scrollbar height)
//                          SM_CXSIZE         (caption width)
//                          SM_CYSIZE         (caption height)
//                          SM_CXSMSIZE       (small caption width)
//                          SM_CYSMSIZE       (small caption height)
//                          SM_CXMENUSIZE     (menubar width)
//                          SM_CYMENUSIZE     (menubar height)
//                          SM_CXPADDEDBORDER (padded border width)
//
//                        when hTheme is NULL, iSizeId is passed directly
//                        to the GetSystemMetrics() function
//---------------------------------------------------------------------------

type
  TGetThemeSysSize = function(theme: HTHEME; iSizeId: integer):
    integer; stdcall;
var
  GetThemeSysSize  : TGetThemeSysSize;


//---------------------------------------------------------------------------
//  GetThemeSysFont()   - Get the LOGFONT for the specified System font.
//
//  hTheme              - the theme data handle.  if non-NULL, will return
//                        font from [SysMetrics] section of theme.
//                        if NULL, will return the specified system font.
//
//  iFontId             - the TMT_XXX font number (first font
//                        is TMT_CAPTIONFONT)
//
//  plf                 - ptr to LOGFONT to receive the font value.
//                        (scaled for the current logical screen dpi)
//---------------------------------------------------------------------------

type
  TGetThemeSysFont = function(theme: HTHEME; iFontId: integer;
    plf: PLOGFONTW): HRESULT; stdcall;
var
  GetThemeSysFont  : TGetThemeSysFont;


//---------------------------------------------------------------------------
//  GetThemeSysString() - Get the value of specified System string metric.
//
//  hTheme              - the theme data handle (required)
//
//  iStringId           - must be one of the following values:
//
//                          TMT_CSSNAME
//                          TMT_XMLNAME
//
//  pszStringBuff       - the buffer to receive the string value
//
//  cchMaxStringChars   - max. number of chars that pszStringBuff can hold
//---------------------------------------------------------------------------

type
  TGetThemeSysString = function(theme: HTHEME; iStringId: integer;
    pszStringBuff: PWideChar; cchMaxStringChars: integer): HRESULT;
    stdcall;
var
  GetThemeSysString  : TGetThemeSysString;


//---------------------------------------------------------------------------
//  GetThemeSysInt() - Get the value of specified System int.
//
//  hTheme              - the theme data handle (required)
//
//  iIntId              - must be one of the following values:
//
//                          TMT_DPIX
//                          TMT_DPIY
//                          TMT_MINCOLORDEPTH
//
//  piValue             - ptr to int to receive value
//---------------------------------------------------------------------------

type
  TGetThemeSysInt = function(theme: HTHEME; iIntId: integer;
    piValue: PInteger): HRESULT; stdcall;
var
  GetThemeSysInt  : TGetThemeSysInt;


//---------------------------------------------------------------------------
//  IsThemeActive()     - can be used to test if a system theme is active
//                        for the current user session.
//
//                        use the API "IsAppThemed()" to test if a theme is
//                        active for the calling process.
//---------------------------------------------------------------------------

type
  TIsThemeActive = function: bool; stdcall;
var
  IsThemeActive  : TIsThemeActive;


//---------------------------------------------------------------------------
//  IsAppThemed()       - returns TRUE if a theme is active and available to
//                        the current process
//---------------------------------------------------------------------------

type
  TIsAppThemed = function: bool; stdcall;
var
  IsAppThemed  : TIsAppThemed;


//---------------------------------------------------------------------------
//  GetWindowTheme()    - if window is themed, returns its most recent
//                        HTHEME from OpenThemeData() - otherwise, returns
//                        NULL.
//
//      hwnd            - the window to get the HTHEME of
//---------------------------------------------------------------------------

type
  TGetWindowTheme = function(wnd: HWND): HTHEME; stdcall;
var
  GetWindowTheme  : TGetWindowTheme;


const
  ETDT_DISABLE                    = $00000001;
  ETDT_ENABLE                     = $00000002;
  ETDT_USETABTEXTURE              = $00000004;
  ETDT_USEAEROWIZARDTABTEXTURE    = $00000008;
  ETDT_ENABLETAB                  = ETDT_ENABLE or ETDT_USETABTEXTURE;
  ETDT_ENABLEAEROWIZARDTAB        = ETDT_ENABLE or ETDT_USEAEROWIZARDTABTEXTURE;
  ETDT_VALIDBITS                  = ETDT_DISABLE or
                                    ETDT_ENABLE or
                                    ETDT_USETABTEXTURE or
                                    ETDT_USEAEROWIZARDTABTEXTURE;

//---------------------------------------------------------------------------
//  EnableThemeDialogTexture()
//
//  - Enables/disables dialog background theme.  This method can be used to
//    tailor dialog compatibility with child windows and controls that
//    may or may not coordinate the rendering of their client area backgrounds
//    with that of their parent dialog in a manner that supports seamless
//    background texturing.
//
//      hdlg         - the window handle of the target dialog
//      dwFlags      - ETDT_ENABLE to enable the theme-defined dialog background texturing,
//                     ETDT_DISABLE to disable background texturing,
//                     ETDT_ENABLETAB to enable the theme-defined background
//                          texturing using the Tab texture
//---------------------------------------------------------------------------

type
  TEnableThemeDialogTexture = function(wnd: HWND; dwFlags : dword):
    HRESULT; stdcall;
var
  EnableThemeDialogTexture  : TEnableThemeDialogTexture;


//---------------------------------------------------------------------------
//  IsThemeDialogTextureEnabled()
//
//  - Reports whether the dialog supports background texturing.
//
//      hdlg         - the window handle of the target dialog
//---------------------------------------------------------------------------

type
  TIsThemeDialogTextureEnabled = function(wnd: HWND): bool; stdcall;
var
  IsThemeDialogTextureEnabled  : TIsThemeDialogTextureEnabled;


//---------------------------------------------------------------------------
//---- flags to control theming within an app ----
const
  STAP_ALLOW_NONCLIENT    = $00000001 shl 0;
  STAP_ALLOW_CONTROLS     = $00000001 shl 1;
  STAP_ALLOW_WEBCONTENT   = $00000001 shl 2;
  STAP_VALIDBITS          = STAP_ALLOW_NONCLIENT or
                            STAP_ALLOW_CONTROLS or
                            STAP_ALLOW_WEBCONTENT;

//---------------------------------------------------------------------------
//  GetThemeAppProperties()
//                      - returns the app property flags that control theming
//---------------------------------------------------------------------------

type
  TGetThemeAppProperties = function: dword; stdcall;
var
  GetThemeAppProperties  : TGetThemeAppProperties;


//---------------------------------------------------------------------------
//  SetThemeAppProperties()
//                      - sets the flags that control theming within the app
//
//      dwFlags         - the flag values to be set
//---------------------------------------------------------------------------

type
  TSetThemeAppProperties = procedure(dwFlags: dword); stdcall;
var
  SetThemeAppProperties  : TSetThemeAppProperties;


//---------------------------------------------------------------------------
//  GetCurrentThemeName()
//                      - Get the name of the current theme in-use.
//                        Optionally, return the ColorScheme name and the
//                        Size name of the theme.
//
//  pszThemeFileName    - receives the theme path & filename
//  cchMaxNameChars     - max chars allowed in pszNameBuff
//
//  pszColorBuff        - (optional) receives the canonical color scheme name
//                        (not the display name)
//  cchMaxColorChars    - max chars allowed in pszColorBuff
//
//  pszSizeBuff         - (optional) receives the canonical size name
//                        (not the display name)
//  cchMaxSizeChars     - max chars allowed in pszSizeBuff
//---------------------------------------------------------------------------

type
  TGetCurrentThemeName = function(pszThemeFileName: PWideChar; cchMaxNameChars: integer;
    pszColorBuff: PWideChar; cchMaxColorChars: integer; pszSizeBuff: PWideChar;
    cchMaxSizeChars: integer): HRESULT; stdcall;
var
  GetCurrentThemeName  : TGetCurrentThemeName;


const
  SZ_THDOCPROP_DISPLAYNAME    : PWideChar = 'DisplayName';
  SZ_THDOCPROP_CANONICALNAME  : PWideChar = 'ThemeName';
  SZ_THDOCPROP_TOOLTIP        : PWideChar = 'ToolTip';
  SZ_THDOCPROP_AUTHOR         : PWideChar = 'author';

type
  TGetThemeDocumentationProperty = function(pszThemeName, pszPropteryName:
    PWideChar; pszValueBuff: PWideChar; cchMaxValueChars: integer): HRESULT;
    stdcall;
var
  GetThemeDocumentationProperty  : TGetThemeDocumentationProperty;


//---------------------------------------------------------------------------
//  Theme API Error Handling
//
//      All functions in the Theme API not returning an HRESULT (THEMEAPI_)
//      use the WIN32 function "SetLastError()" to record any call failures.
//
//      To retreive the error code of the last failure on the
//      current thread for these type of API's, use the WIN32 function
//      "GetLastError()".
//
//      All Theme API error codes (HRESULT's and GetLastError() values)
//      should be normal win32 errors which can be formatted into
//      strings using the Win32 API FormatMessage().
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
// DrawThemeParentBackground()
//                      - used by partially-transparent or alpha-blended
//                        child controls to draw the part of their parent
//                        that they appear in front of.
//
//  hwnd                - handle of the child control
//
//  hdc                 - hdc of the child control
//
//  prc                 - (optional) rect that defines the area to be
//                        drawn (CHILD coordinates)
//---------------------------------------------------------------------------

type
  TDrawThemeParentBackground = function(wnd: HWND; dc: HDC; prc: PRect):
    HRESULT; stdcall;
var
  DrawThemeParentBackground  : TDrawThemeParentBackground;


const
  DTPB_WINDOWDC           = $00000001;
  DTPB_USECTLCOLORSTATIC  = $00000002;
  DTPB_USEERASEBKGND      = $00000004;

//---------------------------------------------------------------------------
// DrawThemeParentBackgroundEx()
//                      - used by partially-transparent or alpha-blended
//                        child controls to draw the part of their parent
//                        that they appear in front of.
//                        Sends a WM_ERASEBKGND message followed by a WM_PRINTCLIENT.
//
//  hwnd                - handle of the child control
//
//  hdc                 - hdc of the child control
//
//  dwFlags             - if 0, only returns S_OK if the parent handled
//                        WM_PRINTCLIENT.
//                      - if DTPB_WINDOWDC is set, hdc is assumed to be a window DC,
//                        not a client DC.
//                      - if DTPB_USEERASEBKGND is set, the function will return S_OK
//                        without sending a WM_CTLCOLORSTATIC message if the parent
//                        actually painted on WM_ERASEBKGND.
//                      - if DTPB_CTLCOLORSTATIC is set, the function will send
//                        a WM_CTLCOLORSTATIC message to the parent and use the
//                        brush if one is provided, else COLOR_BTNFACE.
//
//  prc                 - (optional) rect that defines the area to be
//                        drawn (CHILD coordinates)
//
//  Return value        - S_OK if something was painted, S_FALSE if not.
//---------------------------------------------------------------------------

type
  TDrawThemeParentBackgroundEx = function(wnd: HWND; dc: HDC; dwFlags: dword;
    prc: PRect): HRESULT; stdcall;
var
  DrawThemeParentBackgroundEx  : TDrawThemeParentBackgroundEx;


//---------------------------------------------------------------------------
//  EnableTheming()     - enables or disables themeing for the current user
//                        in the current and future sessions.
//
//  fEnable             - if FALSE, disable theming & turn themes off.
//                      - if TRUE, enable themeing and, if user previously
//                        had a theme active, make it active now.
//---------------------------------------------------------------------------

type
  TEnableTheming = function(fEnable: bool): HRESULT; stdcall;
var
  EnableTheming  : TEnableTheming;



const
  GBF_DIRECT      = $00000001;      // direct dereferencing.
  GBF_COPY        = $00000002;      // create a copy of the bitmap
  GBF_VALIDBITS   = GBF_DIRECT or GBF_COPY;


type
  TGetThemeBitmap = function(theme: HTHEME; iPartId, iStateId,
    iPropId: integer; dwFlags: ulong; phBitmap: PHBITMAP): HRESULT;
    stdcall;
var
  GetThemeBitmap  : TGetThemeBitmap;


//-----------------------------------------------------------------------
//  GetThemeStream() - Get the value for the specified STREAM property
//
//      hTheme      - theme data handle
//      iPartId     - part number
//      iStateId    - state number of part
//      iPropId     - the property number to get the value for
//      ppvStream   - if non-null receives the value of the STREAM property (not to be freed)
//      pcbStream   - if non-null receives the size of the STREAM property
//      hInst       - NULL when iPropId==TMT_STREAM, HINSTANCE of a loaded msstyles
//                    file when iPropId==TMT_DISKSTREAM (use GetCurrentThemeName
//                    and LoadLibraryEx(LOAD_LIBRARY_AS_DATAFILE)
//-----------------------------------------------------------------------

type
  TGetThemeStream = function(theme: HTHEME; iPartId, iStateId, iPropId:
    integer; ppvStream: pointer; pcbStream: dword; hi: HINST):
    HRESULT; stdcall;
var
 GetThemeStream  : TGetThemeStream;


//------------------------------------------------------------------------
//  BufferedPaintInit() - Initialize the Buffered Paint API.
//                        Should be called prior to BeginBufferedPaint,
//                        and should have a matching BufferedPaintUnInit.
//------------------------------------------------------------------------

type
  TBufferedPaintInit = function: HRESULT; stdcall;
var
  BufferedPaintInit  : TBufferedPaintInit;


//------------------------------------------------------------------------
//  BufferedPaintUnInit() - Uninitialize the Buffered Paint API.
//                          Should be called once for each call to BufferedPaintInit,
//                          when calls to BeginBufferedPaint are no longer needed.
//------------------------------------------------------------------------

type
  TBufferedPaintUnInit = function: HRESULT; stdcall;
var
  BufferedPaintUnInit  : TBufferedPaintUnInit;


//------------------------------------------------------------------------
//  BeginBufferedPaint() - Begins a buffered paint operation.
//
//    hdcTarget          - Target DC on which the buffer will be painted
//    rcTarget           - Rectangle specifying the area of the target DC to paint to
//    dwFormat           - Format of the buffer (see BP_BUFFERFORMAT)
//    pPaintParams       - Paint operation parameters (see BP_PAINTPARAMS)
//    phBufferedPaint    - Pointer to receive handle to new buffered paint context
//------------------------------------------------------------------------

// HPAINTBUFFER
type
  HPAINTBUFFER = THandle    ;  // handle to a buffered paint context

const
// typedef enum _BP_BUFFERFORMAT
  BPBF_COMPATIBLEBITMAP = 0;   // Compatible bitmap
  BPBF_DIB              = 1;   // Device-independent bitmap
  BPBF_TOPDOWNDIB       = 2;   // Top-down device-independent bitmap
  BPBF_TOPDOWNMONODIB   = 3;   // Top-down monochrome device-independent bitmap
  BPBF_COMPOSITED       = BPBF_TOPDOWNDIB;

// typedef enum _BP_ANIMATIONSTYLE
  BPAS_NONE           = 0;    // No animation
  BPAS_LINEAR         = 1;    // Linear fade animation
  BPAS_CUBIC          = 2;    // Cubic fade animation
  BPAS_SINE           = 3;    // Sinusoid fade animation

type
  _BP_ANIMATIONPARAMS = packed record
    cbSize,
    dwFlags : dword; // BPBF_ flags
    style : uint;    // _BP_ANIMATIONSTYLE
    dwDuration : dword;
  end;
  TBpAnimationParams = _BP_ANIMATIONPARAMS;
  PBpAnimationParams = ^TBpAnimationParams;

const
  BPPF_ERASE               = $0001; // Empty the buffer during BeginBufferedPaint()
  BPPF_NOCLIP              = $0002; // Don't apply the target DC's clip region to the double buffer
  BPPF_NONCLIENT           = $0004; // Using a non-client DC

type
  _BP_PAINTPARAMS = packed record
    cbSize,
    dwFlags : dword; // BPPF_ flags
    prcExclude : PRect;
    pbf : PBlendFunction;
  end;
  TBpPaintParams = _BP_PAINTPARAMS;
  PBpPaintParams = ^TBpPaintParams;

  TBeginBufferedPaint = function(hdcTarget: HDC; prcTarget: PRect; dwFormat: dword;
    ppp : PBpPaintParams; phdc: PHDC): HPAINTBUFFER; stdcall;
var
  BeginBufferedPaint  : TBeginBufferedPaint;


//------------------------------------------------------------------------
//  EndBufferedPaint() - Ends a buffered paint operation.
//
//    hBufferedPaint   - handle to buffered paint context
//    fUpdateTarget    - update target DC
//------------------------------------------------------------------------

type
  TEndBufferedPaint = function(hBufferedPaint: HPAINTBUFFER; fUpdateTarget: bool):
    HRESULT; stdcall;
var
  EndBufferedPaint  : TEndBufferedPaint;


//------------------------------------------------------------------------
//  GetBufferedPaintTargetRect() - Returns the target rectangle specified during BeginBufferedPaint
//
//    hBufferedPaint             - handle to buffered paint context
//    prc                        - pointer to receive target rectangle
//------------------------------------------------------------------------

type
  TGetBufferedPaintTargetRect = function(hBufferedPaint : HPAINTBUFFER;
    prc: PRect): HRESULT; stdcall;
var
  GetBufferedPaintTargetRect  : TGetBufferedPaintTargetRect;


//------------------------------------------------------------------------
//  GetBufferedPaintTargetDC() - Returns the target DC specified during BeginBufferedPaint
//
//    hBufferedPaint           - handle to buffered paint context
//------------------------------------------------------------------------

type
  TGetBufferedPaintTargetDC = function(hBufferedPaint: HPAINTBUFFER):
    HDC; stdcall;
var
  GetBufferedPaintTargetDC  : TGetBufferedPaintTargetDC;


//------------------------------------------------------------------------
//  GetBufferedPaintDC() - Returns the same paint DC returned by BeginBufferedPaint
//
//    hBufferedPaint     - handle to buffered paint context
//------------------------------------------------------------------------

type
  TGetBufferedPaintDC = function(hBufferedPaint: HPAINTBUFFER):
    HDC; stdcall;
var
  GetBufferedPaintDC  : TGetBufferedPaintDC;


//------------------------------------------------------------------------
//  GetBufferedPaintBits() - Obtains a pointer to the buffer bitmap, if the buffer is a DIB
//
//    hBufferedPaint       - handle to buffered paint context
//    ppbBuffer            - pointer to receive pointer to buffer bitmap pixels
//    pcxRow               - pointer to receive width of buffer bitmap, in pixels;
//                           this value may not necessarily be equal to the buffer width
//------------------------------------------------------------------------

type
  TGetBufferedPaintBits = function(hBufferedPaint: HPAINTBUFFER;
    ppbBuffer: PRgbQuad; pcxRow: PInteger): HRESULT; stdcall;
var
  GetBufferedPaintBits  : TGetBufferedPaintBits;


//------------------------------------------------------------------------
//  BufferedPaintClear() - Clears given rectangle to ARGB = {0, 0, 0, 0}
//
//    hBufferedPaint     - handle to buffered paint context
//    prc                - rectangle to clear; NULL specifies entire buffer
//------------------------------------------------------------------------

type
  TBufferedPaintClear = function(hBufferedPaint: HPAINTBUFFER;
    prc: PRect): HRESULT; stdcall;
var
  BufferedPaintClear  : TBufferedPaintClear;


//------------------------------------------------------------------------
//  BufferedPaintSetAlpha() - Set alpha to given value in given rectangle
//
//    hBufferedPaint        - handle to buffered paint context
//    prc                   - rectangle to set alpha in; NULL specifies entire buffer
//    alpha                 - alpha value to set in the given rectangle
//------------------------------------------------------------------------

type
  TBufferedPaintSetAlpha = function(hBufferedPaint: HPAINTBUFFER;
    prc: PRect; alpha: byte): HRESULT; stdcall;
var
  BufferedPaintSetAlpha  : TBufferedPaintSetAlpha;

  function BufferedPaintMakeOpaque(hBufferedPaint: HPAINTBUFFER;
    prc: PRect): HRESULT;


//------------------------------------------------------------------------
//  BufferedPaintStopAllAnimations() - Stop all buffer animations for the given window
//
//    hwnd                           - window on which to stop all animations
//------------------------------------------------------------------------

type
  TBufferedPaintStopAllAnimations = function(wnd: HWND): HRESULT; stdcall;
var
  BufferedPaintStopAllAnimations  : TBufferedPaintStopAllAnimations;

type
  HANIMATIONBUFFER = THandle;  // handle to a buffered paint animation


  TBeginBufferedAnimation = function(wnd: HWND; hdcTarget: HDC; prcTarget: PRect;
    dwFormat: dword { BF_BUFFERFORMAT }; ppp: PBpPaintParams; pap:
    PBpAnimationParams; phdcFrom: PHDC; phdcTo: PHDC): HANIMATIONBUFFER; stdcall;
var
  BeginBufferedAnimation  : TBeginBufferedAnimation;

type
  TEndBufferedAnimation = function(hbpAnimation: HANIMATIONBUFFER;
    fUpdateTarget: bool): HRESULT; stdcall;
var
  EndBufferedAnimation  : TEndBufferedAnimation;

type
  TBufferedPaintRenderAnimation = function(wnd: HWND; hdcTarget: HDC): bool; stdcall;
var
  BufferedPaintRenderAnimation  : TBufferedPaintRenderAnimation;


//----------------------------------------------------------------------------
// Tells if the DWM is running, and composition effects are possible for this
// process (themes are active).
// Roughly equivalent to "DwmIsCompositionEnabled() && IsAppthemed()"
//----------------------------------------------------------------------------

type
  TIsCompositionActive = function: bool; stdcall;
var
  IsCompositionActive  : TIsCompositionActive;


//------------------------------------------------------------------------
//  GetThemeTransitionDuration()
//                      - Gets the duration for the specified transition
//
//  hTheme              - theme data handle
//  iPartId             - part number
//  iStateIdFrom        - starting state number of part
//  iStateIdTo          - ending state number of part
//  iPropId             - property id
//  pdwDuration         - receives the transition duration
//------------------------------------------------------------------------

type
  TGetThemeTransitionDuration = function(theme: HTHEME; iPartId,
    iStateIdFrom, iStateIdTo, iPropId: integer; pdwDuration: PDWord):
    HRESULT; stdcall;
var
  GetThemeTransitionDuration  : TGetThemeTransitionDuration;



  function IsThemeLibLoaded: boolean;

implementation


function SetWindowThemeNonClientAttributes(wnd: HWND; dwMask,
  dwAttributes: dword): HRESULT;
var
  wta : TWtaOptions;
begin
  if @SetWindowThemeAttribute = nil then
  begin
    Result := S_FALSE;
    exit;
  end;

  wta.dwFlags := dwAttributes;
  wta.dwMask  := dwMask;
  Result      := SetWindowThemeAttribute(wnd, WTA_NONCLIENT, @wta, sizeof(wta));
end;

function BufferedPaintMakeOpaque(hBufferedPaint: HPAINTBUFFER; prc: PRect): HRESULT;
begin
  if @BufferedPaintSetAlpha = nil then
  begin
    Result := S_FALSE;
    exit
  end;

  Result := BufferedPaintSetAlpha(hBufferedPaint, prc, 255);
end;


// ----------------------------------------------------------------------------

function IsWinVer6OrHigher: boolean;
var
  os : TOSVersionInfo;
begin
  ZeroMemory(@os, sizeof(os));
  os.dwOSVersionInfoSize := sizeof(os);

  Result :=
    (GetVersionEx(os)) and
    (os.dwPlatformId = VER_PLATFORM_WIN32_NT) and
    (os.dwMajorVersion >= 6);
end;


const
  uxthemedll = 'uxtheme.dll';
var
  dll        : dword;

function InitLib: dword;
begin
  Result := LoadLibrary(uxthemedll);
  if Result <> 0 then
  begin
    OpenThemeData := GetProcAddress(Result, 'OpenThemeData');
    CloseThemeData := GetProcAddress(Result, 'CloseThemeData');
    DrawThemeBackground := GetProcAddress(Result, 'DrawThemeBackground');
    DrawThemeBackgroundEx := GetProcAddress(Result, 'DrawThemeBackgroundEx');
    DrawThemeText := GetProcAddress(Result, 'DrawThemeText');
    GetThemeBackgroundContentRect := GetProcAddress(Result, 'GetThemeBackgroundContentRect');
    GetThemeBackgroundExtent := GetProcAddress(Result, 'GetThemeBackgroundExtent');
    GetThemeBackgroundRegion := GetProcAddress(Result, 'GetThemeBackgroundRegion');
    GetThemePartSize := GetProcAddress(Result, 'GetThemePartSize');
    GetThemeTextExtent := GetProcAddress(Result, 'GetThemeTextExtent');
    GetThemeTextMetrics := GetProcAddress(Result, 'GetThemeTextMetrics');
    HitTestThemeBackground := GetProcAddress(Result, 'HitTestThemeBackground');
    DrawThemeEdge := GetProcAddress(Result, 'DrawThemeEdge');
    DrawThemeIcon := GetProcAddress(Result, 'DrawThemeIcon');
    IsThemePartDefined := GetProcAddress(Result, 'IsThemePartDefined');
    IsThemeBackgroundPartiallyTransparent := GetProcAddress(Result, 'IsThemeBackgroundPartiallyTransparent');
    GetThemeColor := GetProcAddress(Result, 'GetThemeColor');
    GetThemeMetric := GetProcAddress(Result, 'GetThemeMetric');
    GetThemeString := GetProcAddress(Result, 'GetThemeString');
    GetThemeBool := GetProcAddress(Result, 'GetThemeBool');
    GetThemeInt := GetProcAddress(Result, 'GetThemeInt');
    GetThemeEnumValue := GetProcAddress(Result, 'GetThemeEnumValue');
    GetThemePosition := GetProcAddress(Result, 'GetThemePosition');
    GetThemeFont := GetProcAddress(Result, 'GetThemeFont');
    GetThemeRect := GetProcAddress(Result, 'GetThemeRect');
    GetThemeMargins := GetProcAddress(Result, 'GetThemeMargins');
    GetThemeIntList := GetProcAddress(Result, 'GetThemeIntList');
    GetThemePropertyOrigin := GetProcAddress(Result, 'GetThemePropertyOrigin');
    SetWindowTheme := GetProcAddress(Result, 'SetWindowTheme');
    GetThemeFilename := GetProcAddress(Result, 'GetThemeFilename');
    GetThemeSysColor := GetProcAddress(Result, 'GetThemeSysColor');
    GetThemeSysColorBrush := GetProcAddress(Result, 'GetThemeSysColorBrush');
    GetThemeSysBool := GetProcAddress(Result, 'GetThemeSysBool');
    GetThemeSysSize := GetProcAddress(Result, 'GetThemeSysSize');
    GetThemeSysFont := GetProcAddress(Result, 'GetThemeSysFont');
    GetThemeSysString := GetProcAddress(Result, 'GetThemeSysString');
    GetThemeSysInt := GetProcAddress(Result, 'GetThemeSysInt');
    IsThemeActive := GetProcAddress(Result, 'IsThemeActive');
    IsAppThemed := GetProcAddress(Result, 'IsAppThemed');
    GetWindowTheme := GetProcAddress(Result, 'GetWindowTheme');
    EnableThemeDialogTexture := GetProcAddress(Result, 'EnableThemeDialogTexture');
    IsThemeDialogTextureEnabled := GetProcAddress(Result, 'IsThemeDialogTextureEnabled');
    GetThemeAppProperties := GetProcAddress(Result, 'GetThemeAppProperties');
    SetThemeAppProperties := GetProcAddress(Result, 'SetThemeAppProperties');
    GetCurrentThemeName := GetProcAddress(Result, 'GetCurrentThemeName');
    GetThemeDocumentationProperty := GetProcAddress(Result, 'GetThemeDocumentationProperty');
    DrawThemeParentBackground := GetProcAddress(Result, 'DrawThemeParentBackground');
    EnableTheming := GetProcAddress(Result, 'EnableTheming');

    if IsWinVer6OrHigher then
    begin
      OpenThemeDataEx := GetProcAddress(Result, 'OpenThemeDataEx');
      DrawThemeTextEx := GetProcAddress(Result, 'DrawThemeTextEx');
      SetWindowThemeAttribute := GetProcAddress(Result, 'SetWindowThemeAttribute');
      DrawThemeParentBackgroundEx := GetProcAddress(Result, 'DrawThemeParentBackgroundEx');
      GetThemeBitmap := GetProcAddress(Result, 'GetThemeBitmap');
      GetThemeStream := GetProcAddress(Result, 'GetThemeStream');
      BufferedPaintInit := GetProcAddress(Result, 'BufferedPaintInit');
      BufferedPaintUnInit := GetProcAddress(Result, 'BufferedPaintUnInit');
      BeginBufferedPaint := GetProcAddress(Result, 'BeginBufferedPaint');
      EndBufferedPaint := GetProcAddress(Result, 'EndBufferedPaint');
      GetBufferedPaintTargetRect := GetProcAddress(Result, 'GetBufferedPaintTargetRect');
      GetBufferedPaintTargetDC := GetProcAddress(Result, 'GetBufferedPaintTargetDC');
      GetBufferedPaintDC := GetProcAddress(Result, 'GetBufferedPaintDC');
      GetBufferedPaintBits := GetProcAddress(Result, 'GetBufferedPaintBits');
      BufferedPaintClear := GetProcAddress(Result, 'BufferedPaintClear');
      BufferedPaintSetAlpha := GetProcAddress(Result, 'BufferedPaintSetAlpha');
      BufferedPaintStopAllAnimations := GetProcAddress(Result, 'BufferedPaintStopAllAnimations');
      BeginBufferedAnimation := GetProcAddress(Result, 'BeginBufferedAnimation');
      EndBufferedAnimation := GetProcAddress(Result, 'EndBufferedAnimation');
      BufferedPaintRenderAnimation := GetProcAddress(Result, 'BufferedPaintRenderAnimation');
      IsCompositionActive := GetProcAddress(Result, 'IsCompositionActive');
      GetThemeTransitionDuration := GetProcAddress(Result, 'GetThemeTransitionDuration');
    end;

    if (@OpenThemeData = nil) or
       (@CloseThemeData = nil) or
       (@DrawThemeBackground = nil) or
       (@DrawThemeBackgroundEx = nil) or
       (@DrawThemeText = nil) or
       (@GetThemeBackgroundContentRect = nil) or
       (@GetThemeBackgroundExtent = nil) or
       (@GetThemeBackgroundRegion = nil) or
       (@GetThemePartSize = nil) or
       (@GetThemeTextExtent = nil) or
       (@GetThemeTextMetrics = nil) or
       (@HitTestThemeBackground = nil) or
       (@DrawThemeEdge = nil) or
       (@DrawThemeIcon = nil) or
       (@IsThemePartDefined = nil) or
       (@IsThemeBackgroundPartiallyTransparent = nil) or
       (@GetThemeColor = nil) or
       (@GetThemeMetric = nil) or
       (@GetThemeString = nil) or
       (@GetThemeBool = nil) or
       (@GetThemeInt = nil) or
       (@GetThemeEnumValue = nil) or
       (@GetThemePosition = nil) or
       (@GetThemeFont = nil) or
       (@GetThemeRect = nil) or
       (@GetThemeMargins = nil) or
       (@GetThemeIntList = nil) or
       (@GetThemePropertyOrigin = nil) or
       (@SetWindowTheme = nil) or
       (@GetThemeFilename = nil) or
       (@GetThemeSysColor = nil) or
       (@GetThemeSysColorBrush = nil) or
       (@GetThemeSysBool = nil) or
       (@GetThemeSysSize = nil) or
       (@GetThemeSysFont = nil) or
       (@GetThemeSysString = nil) or
       (@GetThemeSysInt = nil) or
       (@IsThemeActive = nil) or
       (@IsAppThemed = nil) or
       (@GetWindowTheme = nil) or
       (@EnableThemeDialogTexture = nil) or
       (@IsThemeDialogTextureEnabled = nil) or
       (@GetThemeAppProperties = nil) or
       (@SetThemeAppProperties = nil) or
       (@GetCurrentThemeName = nil) or
       (@GetThemeDocumentationProperty = nil) or
       (@DrawThemeParentBackground = nil) or
       (@EnableTheming = nil) or

       // Vista
       ((@OpenThemeDataEx = nil) and IsWinVer6OrHigher) or
       ((@DrawThemeTextEx = nil) and IsWinVer6OrHigher) or
       ((@SetWindowThemeAttribute = nil) and IsWinVer6OrHigher) or
       ((@DrawThemeParentBackgroundEx = nil) and IsWinVer6OrHigher) or
       ((@GetThemeBitmap = nil) and IsWinVer6OrHigher) or
       ((@GetThemeStream = nil) and IsWinVer6OrHigher) or
       ((@BufferedPaintInit = nil) and IsWinVer6OrHigher) or
       ((@BufferedPaintUnInit = nil) and IsWinVer6OrHigher) or
       ((@BeginBufferedPaint = nil) and IsWinVer6OrHigher) or
       ((@EndBufferedPaint = nil) and IsWinVer6OrHigher) or
       ((@GetBufferedPaintTargetRect = nil) and IsWinVer6OrHigher) or
       ((@GetBufferedPaintTargetDC = nil) and IsWinVer6OrHigher) or
       ((@GetBufferedPaintDC = nil) and IsWinVer6OrHigher) or
       ((@GetBufferedPaintBits = nil) and IsWinVer6OrHigher) or
       ((@BufferedPaintClear = nil) and IsWinVer6OrHigher) or
       ((@BufferedPaintSetAlpha = nil) and IsWinVer6OrHigher) or
       ((@BufferedPaintStopAllAnimations = nil) and IsWinVer6OrHigher) or
       ((@BeginBufferedAnimation = nil) and IsWinVer6OrHigher) or
       ((@EndBufferedAnimation = nil) and IsWinVer6OrHigher) or
       ((@BufferedPaintRenderAnimation = nil) and IsWinVer6OrHigher) or
       ((@IsCompositionActive = nil) and IsWinVer6OrHigher) or
       ((@GetThemeTransitionDuration = nil) and IsWinVer6OrHigher) then
    begin
      FreeLibrary(Result);
      Result := 0;
      SetLastError(ERROR_INVALID_FUNCTION);
    end;
  end;
end;

procedure FreeLib(const dllhandle: dword);
begin
  if dllhandle <> 0 then FreeLibrary(dllhandle);
end;

function IsThemeLibLoaded: boolean;
begin
  Result := dll <> 0;
end;

initialization
  dll := InitLib;
finalization
  FreeLib(dll);
end.