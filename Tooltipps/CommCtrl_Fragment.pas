unit CommCtrl_Fragment;

interface

uses
  Windows, Messages, CommCtrl;


const
  {$EXTERNALSYM ICC_STANDARD_CLASSES}
  ICC_STANDARD_CLASSES   = $00004000;
  {$EXTERNALSYM ICC_LINK_CLASS}
  ICC_LINK_CLASS         = $00008000;

  {$EXTERNALSYM CCM_SETWINDOWTHEME}
  CCM_SETWINDOWTHEME      = CCM_FIRST + $0b;

  {$EXTERNALSYM CCM_SETVERSION}
  CCM_SETVERSION          = CCM_FIRST + $07;
  {$EXTERNALSYM CCM_GETVERSION}
  CCM_GETVERSION          = CCM_FIRST + $08;

  {$EXTERNALSYM ECM_FIRST}
  ECM_FIRST               = $1500;      // Edit control messages
  {$EXTERNALSYM BCM_FIRST}
  BCM_FIRST               = $1600;      // Button control messages
  {$EXTERNALSYM CBM_FIRST}
  CBM_FIRST               = $1700;      // Combobox control messages


  IDI_SHIELD  = 32518;


(********************************
	PropertySheets
********************************)

const
  {$EXTERNALSYM PSP_USEFUSIONCONTEXT}
  PSP_USEFUSIONCONTEXT       = $00004000;

  {$EXTERNALSYM PSPCB_ADDREF}
  PSPCB_ADDREF               = $0;

  {$EXTERNALSYM PSH_WIZARD97_IE4}
  PSH_WIZARD97_IE4              = $00002000;
  {$EXTERNALSYM PSH_WIZARD97}
  PSH_WIZARD97                  = $01000000;
  {$EXTERNALSYM PSH_WIZARD_LITE}
  PSH_WIZARD_LITE               = $00400000;
  {$EXTERNALSYM PSH_NOCONTEXTHELP}
  PSH_NOCONTEXTHELP             = $02000000;
  {$EXTERNALSYM PSH_AEROWIZARD}
  PSH_AEROWIZARD                = $00004000;
  {$EXTERNALSYM PSH_RESIZABLE}
  PSH_RESIZABLE                 = $04000000;
  {$EXTERNALSYM PSH_HEADERBITMAP}
  PSH_HEADERBITMAP              = $08000000;
  {$EXTERNALSYM PSH_NOMARGIN}
  PSH_NOMARGIN                  = $10000000;


// PSCB_BUTTONPRESSED will be sent when the user clicks a button in the
// property dialog (OK, Cancel, Apply, or Close).  The message will be sent
// to PROPSHEETHEADER's pfnCallback if the PSH_USECALLBACK flag was specified.
// The LPARAM will be equal to one of the following based on the button pressed:
// This message is only supported on comctl32 v6.
// PSBTN_FINISH (Close), PSBTN_OK, PSBTN_APPLYNOW, or PSBTN_CANCEL

  {$EXTERNALSYM PSCB_BUTTONPRESSED}
  PSCB_BUTTONPRESSED            = $3;

type
  {$EXTERNALSYM _PSHNOTIFY}
  _PSHNOTIFY = packed record
    hdr : NMHdr;
    lParam : longint
  end;
  {$EXTERNALSYM TSHNotify}
  TSHNotify  = _PSHNOTIFY;
  {$EXTERNALSYM PSHNotify}
  PSHNotify  = ^TSHNotify;

const
  {$EXTERNALSYM PSN_TRANSLATEACCELERATOR}
  PSN_TRANSLATEACCELERATOR      = PSN_FIRST - 12;
  {$EXTERNALSYM PSN_QUERYINITIALFOCUS}
  PSN_QUERYINITIALFOCUS         = PSN_FIRST - 13;

  {$EXTERNALSYM PSNRET_MESSAGEHANDLED}
  PSNRET_MESSAGEHANDLED         = 3;


{$EXTERNALSYM PropSheet_SetCurSel}
function PropSheet_SetCurSel(hDlg: HWND; hpage: HPROPSHEETPAGE; index: integer): bool;
{$EXTERNALSYM PropSheet_RemovePage}
function PropSheet_RemovePage(hDlg: HWND; index: integer; hpage: HPROPSHEETPAGE): bool;
{$EXTERNALSYM PropSheet_AddPage}
function PropSheet_AddPage(hDlg: HWND; hpage: HPROPSHEETPAGE): bool;
{$EXTERNALSYM PropSheet_Changed}
function PropSheet_Changed(hDlg: HWND; hwndPage: HWND): bool;
{$EXTERNALSYM PropSheet_RestartWindows}
procedure PropSheet_RestartWindows(hDlg: HWND);
{$EXTERNALSYM PropSheet_RebootSystem}
procedure PropSheet_RebootSystem(hDlg: HWND);
{$EXTERNALSYM PropSheet_CancelToClose}
procedure PropSheet_CancelToClose(hDlg: HWND);
{$EXTERNALSYM PropSheet_QuerySiblings}
function PropSheet_QuerySiblings(hDlg: HWND; wp: WPARAM; lp: LPARAM): integer;
{$EXTERNALSYM PropSheet_UnChanged}
procedure PropSheet_UnChanged(hDlg: HWND; hwndPage: HWND);
{$EXTERNALSYM PropSheet_Apply}
function PropSheet_Apply(hDlg: HWND): bool;
{$EXTERNALSYM PropSheet_SetTitle}
procedure PropSheet_SetTitle(hPropSheetDlg: HWND; dwStyle: DWORD; lpszText: LPTSTR);
{$EXTERNALSYM PropSheet_SetWizButtons}
procedure PropSheet_SetWizButtons(hDlg: HWND; dwFlags: dword);
{$EXTERNALSYM PropSheet_PressButton}
function PropSheet_PressButton(hDlg: HWND; iButton: integer): bool;
{$EXTERNALSYM PropSheet_SetCurSelByID}
function PropSheet_SetCurSelByID(hDlg: HWND; id: integer): bool;
{$EXTERNALSYM PropSheet_SetFinishText}
procedure PropSheet_SetFinishText(hDlg: HWND; lpszText: LPTSTR);
{$EXTERNALSYM PropSheet_GetTabControl}
function PropSheet_GetTabControl(hDlg: HWND): HWND;
{$EXTERNALSYM PropSheet_IsDialogMessage}
function PropSheet_IsDialogMessage(hDlg: HWND; pMsg: TMsg): bool;

const
  {$EXTERNALSYM PSM_GETCURRENTPAGEHWND}
  PSM_GETCURRENTPAGEHWND      = WM_USER + 118;
  {$EXTERNALSYM PSM_INSERTPAGE}
  PSM_INSERTPAGE              = WM_USER + 119;

{$EXTERNALSYM PropSheet_GetCurrentPageHwnd}
function PropSheet_GetCurrentPageHwnd(hDlg: HWND): HWND;
{$EXTERNALSYM PropSheet_InsertPage}
function PropSheet_InsertPage(hDlg: HWND; index: integer; hPage: HPROPSHEETPAGE): bool;


const
  {$EXTERNALSYM PSM_SETHEADERTITLE}
  PSM_SETHEADERTITLE           = WM_USER + 125;
  {$EXTERNALSYM PSM_SETHEADERTITLEW}
  PSM_SETHEADERTITLEW          = WM_USER + 126;
  {$EXTERNALSYM PSM_SETHEADERSUBTITLE}
  PSM_SETHEADERSUBTITLE        = WM_USER + 127;
  {$EXTERNALSYM PSM_SETHEADERSUBTITLEW}
  PSM_SETHEADERSUBTITLEW       = WM_USER + 128;

{$EXTERNALSYM PropSheet_SetHeaderTitle}
function PropSheet_SetHeaderTitle(hDlg: HWND; index: integer; lpszText: LPCTSTR): integer;
{$EXTERNALSYM PropSheet_SetHeaderSubTitle}
procedure PropSheet_SetHeaderSubTitle(hDlg: HWND; index: integer; lpszText: LPCSTR);


const
  {$EXTERNALSYM PSM_HWNDTOINDEX}
  PSM_HWNDTOINDEX            = WM_USER + 129;
  {$EXTERNALSYM PSM_INDEXTOHWND}
  PSM_INDEXTOHWND            = WM_USER + 130;
  {$EXTERNALSYM PSM_PAGETOINDEX}
  PSM_PAGETOINDEX            = WM_USER + 131;
  {$EXTERNALSYM PSM_INDEXTOPAGE}
  PSM_INDEXTOPAGE            = WM_USER + 132;
  {$EXTERNALSYM PSM_IDTOINDEX}
  PSM_IDTOINDEX              = WM_USER + 133;
  {$EXTERNALSYM PSM_INDEXTOID}
  PSM_INDEXTOID              = WM_USER + 134;
  {$EXTERNALSYM PSM_GETRESULT}
  PSM_GETRESULT              = WM_USER + 135;
  {$EXTERNALSYM PSM_RECALCPAGESIZES}
  PSM_RECALCPAGESIZES        = WM_USER + 136;

{$EXTERNALSYM PropSheet_HwndToIndex}
function PropSheet_HwndToIndex(hDlg, hwndPage: HWND): integer;
{$EXTERNALSYM PropSheet_IndexToHwnd}
function PropSheet_IndexToHwnd(hDlg: HWND; i: integer): HWND;
{$EXTERNALSYM PropSheet_PageToIndex}
function PropSheet_PageToIndex(hDlg: HWND; hpage: HPROPSHEETPAGE): integer;
{$EXTERNALSYM PropSheet_IndexToPage}
function PropSheet_IndexToPage(hDlg: HWND; i: integer): HPROPSHEETPAGE;
{$EXTERNALSYM PropSheet_IdToIndex}
function PropSheet_IdToIndex(hDlg: HWND; id: integer): integer;
{$EXTERNALSYM PropSheet_IndexToId}
function PropSheet_IndexToId(hDlg: HWND; i: integer): integer;
{$EXTERNALSYM PropSheet_GetResult}
function PropSheet_GetResult(hDlg: HWND): integer;
{$EXTERNALSYM PropSheet_RecalcPageSizes}
function PropSheet_RecalcPageSizes(hDlg: HWND): bool;


const
  PSM_SETNEXTTEXTW     =  WM_USER + 137;
  PSM_SETNEXTTEXT      =  PSM_SETNEXTTEXTW;

function PropSheet_SetNextText(hDlg: HWND; lpszText: PWideChar): integer;

const
  PSWIZB_CANCEL          = $00000010;
  PSWIZB_SHOW           = 0;
  PSWIZB_RESTORE        = 1;
  PSM_SHOWWIZBUTTONS    = WM_USER + 138;

procedure PropSheet_ShowWizButtons(hDlg: HWND; dwFlag, dwButton: DWORD);

const
  PSM_ENABLEWIZBUTTONS  = WM_USER + 139;

procedure PropSheet_EnableWizButtons(hDlg: HWND; dwState, dwMask: DWORD);

const
  PSM_SETBUTTONTEXTW     = WM_USER + 140;
  PSM_SETBUTTONTEXT      = PSM_SETBUTTONTEXTW;

function PropSheet_SetButtonText(hDlg: HWND; dwButton: DWORD; lpszText: PWideChar): integer;

const
  PSWIZF_SETCOLOR        = uint(-1);


(********************************
	Toolbar
********************************)
const
  {$EXTERNALSYM BTNS_BUTTON}
  BTNS_BUTTON             = TBSTYLE_BUTTON;      // 0x0000
  {$EXTERNALSYM BTNS_SEP}
  BTNS_SEP                = TBSTYLE_SEP;         // 0x0001
  {$EXTERNALSYM BTNS_CHECK}
  BTNS_CHECK              = TBSTYLE_CHECK;       // 0x0002
  {$EXTERNALSYM BTNS_GROUP}
  BTNS_GROUP              = TBSTYLE_GROUP;       // 0x0004
  {$EXTERNALSYM BTNS_CHECKGROUP}
  BTNS_CHECKGROUP         = TBSTYLE_CHECKGROUP;  // (TBSTYLE_GROUP | TBSTYLE_CHECK)
  {$EXTERNALSYM BTNS_DROPDOWN}
  BTNS_DROPDOWN           = TBSTYLE_DROPDOWN;    // 0x0008
  {$EXTERNALSYM BTNS_AUTOSIZE}
  BTNS_AUTOSIZE           = TBSTYLE_AUTOSIZE;    // 0x0010; automatically calculate the cx of the button
  {$EXTERNALSYM BTNS_NOPREFIX}
  BTNS_NOPREFIX           = TBSTYLE_NOPREFIX;    // 0x0020; this button should not have accel prefix
  {$EXTERNALSYM BTNS_SHOWTEXT}
  BTNS_SHOWTEXT           = $0040;               // ignored unless TBSTYLE_EX_MIXEDBUTTONS is set
  {$EXTERNALSYM BTNS_WHOLEDROPDOWN}
  BTNS_WHOLEDROPDOWN      = $0080;               // draw drop-down arrow, but without split arrow section
  {$EXTERNALSYM TBSTYLE_EX_MIXEDBUTTONS}
  TBSTYLE_EX_MIXEDBUTTONS             = $00000008;
  {$EXTERNALSYM TBSTYLE_EX_HIDECLIPPEDBUTTONS}
  TBSTYLE_EX_HIDECLIPPEDBUTTONS       = $00000010;  // don't show partially obscured buttons
  {$EXTERNALSYM TBSTYLE_EX_DOUBLEBUFFER}
  TBSTYLE_EX_DOUBLEBUFFER             = $00000080; // Double Buffer the toolbar

  {$EXTERNALSYM TBN_RESTORE}
  TBN_RESTORE         = TBN_FIRST - 21;
  {$EXTERNALSYM TBN_SAVE}
  TBN_SAVE            = TBN_FIRST - 22;
  {$EXTERNALSYM TBN_INITCUSTOMIZE}
  TBN_INITCUSTOMIZE   = TBN_FIRST - 23;
  {$EXTERNALSYM TBNRF_HIDEHELP}
  TBNRF_HIDEHELP      = $00000001;
  {$EXTERNALSYM TBNRF_ENDCUSTOMIZE}
  TBNRF_ENDCUSTOMIZE  = $00000002;

  {$EXTERNALSYM TBIF_BYINDEX}
  TBIF_BYINDEX        = $80000000;
  // this specifies that the wparam in Get/SetButtonInfo is an index, not id

  {$EXTERNALSYM TBCDRF_BLENDICON}
  TBCDRF_BLENDICON    = $00200000;  // Use ILD_BLEND50 on the icon image
  {$EXTERNALSYM TBCDRF_NOBACKGROUND}
  TBCDRF_NOBACKGROUND = $00400000;  // Use ILD_BLEND50 on the icon image


  {$EXTERNALSYM TB_GETSTRINGW}
  TB_GETSTRINGW       = (WM_USER + 91);
  {$EXTERNALSYM TB_GETSTRINGA}
  TB_GETSTRINGA       = (WM_USER + 92);
  {$EXTERNALSYM TB_GETSTRING}
  TB_GETSTRING        = TB_GETSTRINGA;


  {$EXTERNALSYM TBMF_PAD}
  TBMF_PAD                = $00000001;
  {$EXTERNALSYM TBMF_BARPAD}
  TBMF_BARPAD             = $00000002;
  {$EXTERNALSYM TBMF_BUTTONSPACING}
  TBMF_BUTTONSPACING      = $00000004;


type
  {$EXTERNALSYM TBMETRICS}
  TBMETRICS = packed record
    cbSize: UINT;
    dwMask: dword;

    cxPad,
    cyPad : integer; // PAD
    cxBarPad,
    cyBarPad : integer; // BARPAD
    cxButtonSpacing,
    cyButtonSpacing : integer; // BUTTONSPACING
  end;
  {$EXTERNALSYM TTBMetrics}
  TTBMetrics = TBMETRICS;
  {$EXTERNALSYM PTBMetrics}
  PTBMetrics = ^TTBMetrics;

const
  {$EXTERNALSYM TB_GETMETRICS}
  TB_GETMETRICS         = (WM_USER + 101);
  {$EXTERNALSYM TB_SETMETRICS}
  TB_SETMETRICS         = (WM_USER + 102);

  {$EXTERNALSYM TB_SETWINDOWTHEME}
  TB_SETWINDOWTHEME     = CCM_SETWINDOWTHEME;

type
  {$EXTERNALSYM tagNMTBSAVE}
  tagNMTBSAVE = packed record
    hdr : NMhdr;
    pData : PDWORD;
    pCurrent : PDWORD;
    cbData : UINT;
    iItem : integer;
    cButtons : integer;
    tbButton : TTBButton;
  end;
  NMTBSAVE = tagNMTBSAVE;
  TNMTBSave = tagNMTBSAVE;
  PNMTBSave = ^TNMTBSave;

  {$EXTERNALSYM tagNMTBRESTORE}
  tagNMTBRESTORE = packed record
    hdr : NMhdr;
    pData : PDWORD;
    pCurrent : PDWORD;
    cbData : UINT;
    iItem : integer;
    cButtons : integer;
    cbBytesPerRecord : integer;
    tbButton : TTBButton;
  end;
  NMTBRESTORE = tagNMTBRESTORE;
  TNMTBRestore = tagNMTBRESTORE;
  PNMTBRestore = TNMTBRestore;


  {$EXTERNALSYM tagNMTOOLBARA}
  tagNMTOOLBARA = packed record
    hdr: TNMHdr;
    iItem: Integer;
    tbButton: TTBButton;
    cchText: Integer;
    pszText: PAnsiChar;
    rcButton: TRect;
  end;
  {$EXTERNALSYM tagNMTOOLBARW}
  tagNMTOOLBARW = packed record
    hdr: TNMHdr;
    iItem: Integer;
    tbButton: TTBButton;
    cchText: Integer;
    pszText: PWideChar;
    rcButton: TRect;
  end;
  {$EXTERNALSYM tagNMTOOLBAR}
  tagNMTOOLBAR = tagNMTOOLBARA;
  PNMToolBarA = ^TNMToolBarA;
  PNMToolBarW = ^TNMToolBarW;
  PNMToolBar = PNMToolBarA;
  TNMToolBarA = tagNMTOOLBARA;
  TNMToolBarW = tagNMTOOLBARW;
  TNMToolBar = TNMToolBarA;



(********************************
	Rebar
********************************)


//====== REBAR CONTROL ========================================================

const
  {$EXTERNALSYM RBBS_USECHEVRON}
  RBBS_USECHEVRON     = $00000200;  // display drop-down button for this band if it's sized smaller than ideal width
  {$EXTERNALSYM RBBS_HIDETITLE}
  RBBS_HIDETITLE      = $00000400;  // keep band title hidden
  {$EXTERNALSYM RBBS_TOPALIGN}
  RBBS_TOPALIGN       = $00000800;  // keep band title hidden

const
  {$EXTERNALSYM RBSTR_CHANGERECT}
  RBSTR_CHANGERECT    = $0001;      // flags for RB_SIZETORECT

const
  {$EXTERNALSYM RB_GETBANDMARGINS}
  RB_GETBANDMARGINS   = WM_USER + 40;
  {$EXTERNALSYM RB_SETWINDOWTHEME}
  RB_SETWINDOWTHEME   = CCM_SETWINDOWTHEME;
  {$EXTERNALSYM RB_SETCOLORSCHEME}
  RB_SETCOLORSCHEME   = CCM_SETCOLORSCHEME;  // lParam is color scheme
  {$EXTERNALSYM RB_GETCOLORSCHEME}
  RB_GETCOLORSCHEME   = CCM_GETCOLORSCHEME;  // fills in COLORSCHEME pointed to by lParam
  {$EXTERNALSYM RB_PUSHCHEVRON}
  RB_PUSHCHEVRON      = WM_USER + 43;

const
  {$EXTERNALSYM RBN_CHEVRONPUSHED}
  RBN_CHEVRONPUSHED   = RBN_FIRST - 10;
  {$EXTERNALSYM RBN_MINMAX}
  RBN_MINMAX          = RBN_FIRST - 21;
  {$EXTERNALSYM RBN_AUTOBREAK}
  RBN_AUTOBREAK       = RBN_FIRST - 22;

type
  {$EXTERNALSYM tagNMREBARCHEVRON}
  tagNMREBARCHEVRON = packed record
    hdr: TNMHDR;
    uBand: UINT;
    wID: UINT;
    lparam: Longint;
    rc: TRect;
    lParamNM: Longint;
  end;
  {$EXTERNALSYM TNMRebarChevron}
  TNMRebarChevron = tagNMREBARCHEVRON;
  {$EXTERNALSYM PNMRebarChevron}
  PNMRebarChevron = ^TNMRebarChevron;

const
  {$EXTERNALSYM RBAB_AUTOSIZE}
  RBAB_AUTOSIZE   = $0001;   // These are not flags and are all mutually exclusive
  {$EXTERNALSYM RBAB_ADDBAND}
  RBAB_ADDBAND    = $0002;

type
  {$EXTERNALSYM tagNMREBARAUTOBREAK}
  tagNMREBARAUTOBREAK = packed record
    hdr : TNMHdr;
    uBand: UINT;
    wID: UINT;
    lparam: integer;
    uMsg: UINT;
    fStyleCurrent: UINT;
    fAutoBreak: bool;
  end;
  {$EXTERNALSYM TMNRebarAutoBreak}
  TMNRebarAutoBreak = tagNMREBARAUTOBREAK;
  {$EXTERNALSYM PMNRebarAutoBreak}
  PMNRebarAutoBreak = ^TMNRebarAutoBreak;

const
  {$EXTERNALSYM RBHT_CHEVRON}
  RBHT_CHEVRON    = $0008;


(********************************
	Tooltipps
********************************)
const
  {$EXTERNALSYM TTS_NOFADE}
  TTS_NOFADE              = $20;
  {$EXTERNALSYM TTS_BALLOON}
  TTS_BALLOON             = $40;
  {$EXTERNALSYM TTS_CLOSE}
  TTS_CLOSE               = $80;

  // ToolTip Icons (Set with TTM_SETTITLE)
  {$EXTERNALSYM TTI_NONE}
  TTI_NONE                = 0;
  {$EXTERNALSYM TTI_INFO}
  TTI_INFO                = 1;
  {$EXTERNALSYM TTI_WARNING}
  TTI_WARNING             = 2;
  {$EXTERNALSYM TTI_ERROR}
  TTI_ERROR               = 3;

  {$EXTERNALSYM TTM_GETBUBBLESIZE}
  TTM_GETBUBBLESIZE        = WM_USER + 30;
  {$EXTERNALSYM TTM_ADJUSTRECT}
  TTM_ADJUSTRECT           = WM_USER + 31;
  {$EXTERNALSYM TTM_SETTITLEA}
  TTM_SETTITLEA            = WM_USER + 32;  // wParam = TTI_*, lParam = char* szTitle
  {$EXTERNALSYM TTM_SETTITLEW}
  TTM_SETTITLEW            = WM_USER + 33;  // wParam = TTI_*, lParam = wchar* szTitle
  {$EXTERNALSYM TTM_POPUP}
  TTM_POPUP                = WM_USER + 34;
  {$EXTERNALSYM TTM_GETTITLE}
  TTM_GETTITLE             = WM_USER + 35; // wParam = 0, lParam = TTGETTITLE*
  {$EXTERNALSYM TTM_SETTITLE}
  TTM_SETTITLE             = TTM_SETTITLEA;

type
  _TGETTITLE = packed record
    dwSize : DWORD;
    uTitleBitmap : UINT;
    cch : UINT;
    pszTitle : PWideChar;
  end;
  TGetTitle = _TGETTITLE;
  PGetTitle = ^TGetTitle;


(********************************
	Listview
********************************)

const
  {$EXTERNALSYM LVS_EX_LABELTIP}
  LVS_EX_LABELTIP         = $00004000; // listview unfolds partly hidden labels if it does not have infotip text
  {$EXTERNALSYM LVS_EX_BORDERSELECT}
  LVS_EX_BORDERSELECT     = $00008000; // border selection style instead of highlight
  {$EXTERNALSYM LVS_EX_DOUBLEBUFFER}
  LVS_EX_DOUBLEBUFFER     = $00010000;
  {$EXTERNALSYM LVS_EX_HIDELABELS}
  LVS_EX_HIDELABELS       = $00020000;
  {$EXTERNALSYM LVS_EX_SINGLEROW}
  LVS_EX_SINGLEROW        = $00040000;
  {$EXTERNALSYM LVS_EX_SNAPTOGRID}
  LVS_EX_SNAPTOGRID       = $00080000;  // Icons automatically snap to grid.
  {$EXTERNALSYM LVS_EX_SIMPLESELECT}
  LVS_EX_SIMPLESELECT     = $00100000;  // Also changes overlay rendering to top right for icon mode.

const
  {$EXTERNALSYM LVIF_GROUPID}
  LVIF_GROUPID            = $0100;
  {$EXTERNALSYM LVIF_COLUMNS}
  LVIF_COLUMNS            = $0200;

  {$EXTERNALSYM LVIS_GLOW}
  LVIS_GLOW               = $0010;


type
  PLVItem60A = ^TLVItemA;
  PLVItem60W = ^TLVItemW;
  PLVItem60 = PLVItemA;
  {$EXTERNALSYM tagLVITEM60A}
  tagLVITEM60A = packed record
    mask: UINT;
    iItem: Integer;
    iSubItem: Integer;
    state: UINT;
    stateMask: UINT;
    pszText: PAnsiChar;
    cchTextMax: Integer;
    iImage: Integer;
    lParam: LPARAM;
    iIndent: Integer;
    iGroupId : integer;
    cColumns : uint;
    puColumns : PUINT;
  end;
  {$EXTERNALSYM tagLVITEM60W}
  tagLVITEM60W = packed record
    mask: UINT;
    iItem: Integer;
    iSubItem: Integer;
    state: UINT;
    stateMask: UINT;
    pszText: PWideChar;
    cchTextMax: Integer;
    iImage: Integer;
    lParam: LPARAM;
    iIndent: Integer;
    iGroupId : integer;
    cColumns : uint;
    puColumns : PUINT;
  end;
  {$EXTERNALSYM tagLVITEM60}
  tagLVITEM60 = tagLVITEM60A;
  {$EXTERNALSYM _LV_ITEM60A}
  _LV_ITEM60A = tagLVITEM60A;
  {$EXTERNALSYM _LV_ITEM60W}
  _LV_ITEM60W = tagLVITEM60W;
  {$EXTERNALSYM _LV_ITEM60}
  _LV_ITEM60 = _LV_ITEM60A;
  TLVItem60A = tagLVITEM60A;
  TLVItem60W = tagLVITEM60W;
  TLVItem60 = TLVItem60A;
  {$EXTERNALSYM LV_ITEM60A}
  LV_ITEM60A = tagLVITEM60A;
  {$EXTERNALSYM LV_ITEM60W}
  LV_ITEM60W = tagLVITEM60W;
  {$EXTERNALSYM LV_ITEM60}
  LV_ITEM60 = LV_ITEM60A;


const
  {$EXTERNALSYM I_IMAGENONE}
  I_IMAGENONE             = -2;
  {$EXTERNALSYM I_COLUMNSCALLBACK}
  I_COLUMNSCALLBACK       = UINT(-1);

{$EXTERNALSYM ListView_SetExtendedListViewStyleEx}
function ListView_SetExtendedListViewStyleEx(hwndLV: HWND; dwMask, dw: DWORD): dword;

const
  {$EXTERNALSYM LVM_SORTITEMSEX}
  LVM_SORTITEMSEX         = LVM_FIRST + 81;

{$EXTERNALSYM ListView_SortItemsEx}
function ListView_SortItemsEx(hwndLV: HWND; pfnCompare: TLVCompare; lPrm: longint): bool;

const
  {$EXTERNALSYM LVBKIF_FLAG_TILEOFFSET}
  LVBKIF_FLAG_TILEOFFSET  = $00000100;
  {$EXTERNALSYM LVBKIF_TYPE_WATERMARK}
  LVBKIF_TYPE_WATERMARK   = $10000000;

const
  {$EXTERNALSYM LVM_SETSELECTEDCOLUMN}
  LVM_SETSELECTEDCOLUMN   = LVM_FIRST + 140;

{$EXTERNALSYM ListView_SetSelectedColumn}
procedure ListView_SetSelectedColumn(wnd: HWND; iCol: integer);

const
  {$EXTERNALSYM LVM_SETTILEWIDTH}
  LVM_SETTILEWIDTH        = LVM_FIRST + 141;

{$EXTERNALSYM ListView_SetTileWidth}
function ListView_SetTileWidth(wnd: HWND; cpWidth: integer): integer;

const
  {$EXTERNALSYM LV_VIEW_ICON}
  LV_VIEW_ICON            = $0000;
  {$EXTERNALSYM LV_VIEW_DETAILS}
  LV_VIEW_DETAILS         = $0001;
  {$EXTERNALSYM LV_VIEW_SMALLICON}
  LV_VIEW_SMALLICON       = $0002;
  {$EXTERNALSYM LV_VIEW_LIST}
  LV_VIEW_LIST            = $0003;
  {$EXTERNALSYM LV_VIEW_TILE}
  LV_VIEW_TILE            = $0004;
  {$EXTERNALSYM LV_VIEW_MAX}
  LV_VIEW_MAX             = $0004;
const
  {$EXTERNALSYM LVM_SETVIEW}
  LVM_SETVIEW             = LVM_FIRST + 142;
  {$EXTERNALSYM LVM_GETVIEW}
  LVM_GETVIEW             = LVM_FIRST + 143;

{$EXTERNALSYM ListView_SetView}
function ListView_SetView(wnd: HWND; iView: dword): dword;
{$EXTERNALSYM ListView_GetView}
function ListView_GetView(wnd: HWND): dword;

const
  {$EXTERNALSYM LVGF_NONE}
  LVGF_NONE           = $00000000;
  {$EXTERNALSYM LVGF_HEADER}
  LVGF_HEADER         = $00000001;
  {$EXTERNALSYM LVGF_FOOTER}
  LVGF_FOOTER         = $00000002;
  {$EXTERNALSYM LVGF_STATE}
  LVGF_STATE          = $00000004;
  {$EXTERNALSYM LVGF_ALIGN}
  LVGF_ALIGN          = $00000008;
  {$EXTERNALSYM LVGF_GROUPID}
  LVGF_GROUPID        = $00000010;

  {$EXTERNALSYM LVGS_NORMAL}
  LVGS_NORMAL         = $00000000;
  {$EXTERNALSYM LVGS_COLLAPSED}
  LVGS_COLLAPSED      = $00000001;
  {$EXTERNALSYM LVGS_HIDDEN}
  LVGS_HIDDEN         = $00000002;

  {$EXTERNALSYM LVGA_HEADER_LEFT}
  LVGA_HEADER_LEFT    = $00000001;
  {$EXTERNALSYM LVGA_HEADER_CENTER}
  LVGA_HEADER_CENTER  = $00000002;
  {$EXTERNALSYM LVGA_HEADER_RIGHT}
  LVGA_HEADER_RIGHT   = $00000004;  // Don't forget to validate exclusivity
  {$EXTERNALSYM LVGA_FOOTER_LEFT}
  LVGA_FOOTER_LEFT    = $00000008;
  {$EXTERNALSYM LVGA_FOOTER_CENTER}
  LVGA_FOOTER_CENTER  = $00000010;
  {$EXTERNALSYM LVGA_FOOTER_RIGHT}
  LVGA_FOOTER_RIGHT   = $00000020;  // Don't forget to validate exclusivity

type
  {$EXTERNALSYM tagLVGROUP}
  tagLVGROUP = packed record
    cbSize,
    mask      : UINT;
    pszHeader : LPWSTR;
    cchHeader : integer;
    pszFooter : LPWSTR;
    cchFooter : integer;
    iGroupId  : integer;
    stateMask : UINT;
    state     : UINT;
    uAlign    : UINT;
  end;
  {$EXTERNALSYM TLVGroup}
  TLVGroup = tagLVGROUP;
  {$EXTERNALSYM PLVGroup}
  PLVGroup = ^TLVGroup;

const
  {$EXTERNALSYM LVM_INSERTGROUP}
  LVM_INSERTGROUP         = LVM_FIRST + 145;

{$EXTERNALSYM ListView_InsertGroup}
function ListView_InsertGroup(wnd: HWND; index: integer; pgrp: TLVGroup): integer;

const
  {$EXTERNALSYM LVM_SETGROUPINFO}
  LVM_SETGROUPINFO        = LVM_FIRST + 147;
  {$EXTERNALSYM LVM_GETGROUPINFO}
  LVM_GETGROUPINFO        = LVM_FIRST + 149;

{$EXTERNALSYM ListView_SetGroupInfo}
function ListView_SetGroupInfo(wnd: HWND; iGroupId: integer; pgrp: TLVGroup): integer;
{$EXTERNALSYM ListView_GetGroupInfo}
function ListView_GetGroupInfo(wnd: HWND; iGroupId: integer; var pgrp: TLVGroup): integer;

const
  {$EXTERNALSYM LVM_REMOVEGROUP}
  LVM_REMOVEGROUP         = LVM_FIRST + 150;

{$EXTERNALSYM ListView_RemoveGroup}
function ListView_RemoveGroup(wnd: HWND; iGroupId: integer): integer;

const
  {$EXTERNALSYM LVM_MOVEGROUP}
  LVM_MOVEGROUP           = LVM_FIRST + 151;
  {$EXTERNALSYM LVM_MOVEITEMTOGROUP}
  LVM_MOVEITEMTOGROUP     = LVM_FIRST + 154;

{$EXTERNALSYM ListView_MoveGroup}
procedure ListView_MoveGroup(wnd: HWND; iGroupId, toIndex: integer);
{$EXTERNALSYM ListView_MoveItemToGroup}
procedure ListView_MoveItemToGroup(wnd: HWND; idItemFrom, idGroupTo: integer);

const
  {$EXTERNALSYM LVGMF_NONE}
  LVGMF_NONE          = $00000000;
  {$EXTERNALSYM LVGMF_BORDERSIZE}
  LVGMF_BORDERSIZE    = $00000001;
  {$EXTERNALSYM LVGMF_BORDERCOLOR}
  LVGMF_BORDERCOLOR   = $00000002;
  {$EXTERNALSYM LVGMF_TEXTCOLOR}
  LVGMF_TEXTCOLOR     = $00000004;

type
  {$EXTERNALSYM tagLVGROUPMETRICS}
  tagLVGROUPMETRICS = packed record
    cbSize,
    mask,
    Left,
    Top,
    Right,
    Bottom : UINT;
    crLeft,
    crTop,
    crRight,
    crBottom,
    crHeader,
    crFooter : COLORREF;
  end;
  {$EXTERNALSYM TLVGroupMetrics}
  TLVGroupMetrics = tagLVGROUPMETRICS;
  {$EXTERNALSYM PLVGroupMetrics}
  PLVGroupMetrics = ^TLVGroupMetrics;

const
  {$EXTERNALSYM LVM_SETGROUPMETRICS}
  LVM_SETGROUPMETRICS         = LVM_FIRST + 155;
  {$EXTERNALSYM LVM_GETGROUPMETRICS}
  LVM_GETGROUPMETRICS         = LVM_FIRST + 156;

{$EXTERNALSYM ListView_SetGroupMetrics}
procedure ListView_SetGroupMetrics(wnd: HWND; pGroupMetrics: TLVGroupMetrics);
{$EXTERNALSYM ListView_GetGroupMetrics}
procedure ListView_GetGroupMetrics(wnd: HWND; var pGroupMetrics: TLVGroupMetrics);

const
  {$EXTERNALSYM LVM_ENABLEGROUPVIEW}
  LVM_ENABLEGROUPVIEW         = LVM_FIRST + 157;

{$EXTERNALSYM ListView_EnableGroupView}
function ListView_EnableGroupView(wnd: HWND; fEnable: bool): integer;


type
  {$EXTERNALSYM PFNLVGROUPCOMPARE}
  PFNLVGROUPCOMPARE = function(lParam1, lParam2: integer; plv: pointer): integer; stdcall;
  TLVGroupCompare = PFNLVGROUPCOMPARE;

const
  {$EXTERNALSYM LVM_SORTGROUPS}
  LVM_SORTGROUPS              = LVM_FIRST + 158;

{$EXTERNALSYM ListView_SortGroups}
function ListView_SortGroups(wnd: HWND; fnGroupCompare: TLVGroupCompare; plv: pointer): integer;

type
  {$EXTERNALSYM tagLVINSERTGROUPSORTED}
  tagLVINSERTGROUPSORTED = packed record
    pfnGroupCompare : PFNLVGROUPCOMPARE;
    pvData : pointer;
    lvGroup : TLVGroup;
  end;
  {$EXTERNALSYM TVLInsertGroupSorted}
  TVLInsertGroupSorted = tagLVINSERTGROUPSORTED;
  {$EXTERNALSYM PVLInsertGroupSorted}
  PVLInsertGroupSorted = ^TVLInsertGroupSorted;

const
  {$EXTERNALSYM LVM_INSERTGROUPSORTED}
  LVM_INSERTGROUPSORTED       = LVM_FIRST + 159;

{$EXTERNALSYM ListView_InsertGroupSorted}
procedure ListView_InsertGroupSorted(wnd: HWND; structInsert: TVLInsertGroupSorted);

const
  {$EXTERNALSYM LVM_REMOVEALLGROUPS}
  LVM_REMOVEALLGROUPS             = LVM_FIRST + 160;

{$EXTERNALSYM ListView_RemoveAllGroups}
procedure ListView_RemoveAllGroups(wnd: HWND);

const
{$EXTERNALSYM LVM_HASGROUP}
  LVM_HASGROUP                    = LVM_FIRST + 161;

{$EXTERNALSYM ListView_HasGroup}
function ListView_HasGroup(wnd: HWND; dwGroupId: dword): bool;

const
  {$EXTERNALSYM LVTVIF_AUTOSIZE}
  LVTVIF_AUTOSIZE       = $00000000;
  {$EXTERNALSYM LVTVIF_FIXEDWIDTH}
  LVTVIF_FIXEDWIDTH     = $00000001;
  {$EXTERNALSYM LVTVIF_FIXEDHEIGHT}
  LVTVIF_FIXEDHEIGHT    = $00000002;
  {$EXTERNALSYM LVTVIF_FIXEDSIZE}
  LVTVIF_FIXEDSIZE      = $00000003;

  {$EXTERNALSYM LVTVIM_TILESIZE}
  LVTVIM_TILESIZE       = $00000001;
  {$EXTERNALSYM LVTVIM_COLUMNS}
  LVTVIM_COLUMNS        = $00000002;
  {$EXTERNALSYM LVTVIM_LABELMARGIN}
  LVTVIM_LABELMARGIN    = $00000004;

type
  {$EXTERNALSYM tagLVTILEVIEWINFO}
  tagLVTILEVIEWINFO = packed record
    cbSize : UINT;
    dwMask,
    dwFlags : dword;
    sizeTile : SIZE;
    cLines : integer;
    rcLabelMargin : TRect;
  end;
  {$EXTERNALSYM TLVTileViewInfo}
  TLVTileViewInfo = tagLVTILEVIEWINFO;
  {$EXTERNALSYM PLVTileViewInfo}
  PLVTileViewInfo = ^TLVTileViewInfo;

  {$EXTERNALSYM tagLVTILEINFO}
  tagLVTILEINFO = packed record
    cbSize : UINT;
    iItem : integer;
    cColumns : UINT;
    puColumns : PUINT;
  end;
  {$EXTERNALSYM TLVTileInfo}
  TLVTileInfo = tagLVTILEINFO;
  {$EXTERNALSYM PLVTileInfo}
  PLVTileInfo = ^TLVTileInfo;

const
  {$EXTERNALSYM LVM_SETTILEVIEWINFO}
  LVM_SETTILEVIEWINFO                 = LVM_FIRST + 162;
  {$EXTERNALSYM LVM_GETTILEVIEWINFO}
  LVM_GETTILEVIEWINFO                 = LVM_FIRST + 163;
  {$EXTERNALSYM LVM_SETTILEINFO}
  LVM_SETTILEINFO                     = LVM_FIRST + 164;
  {$EXTERNALSYM LVM_GETTILEINFO}
  LVM_GETTILEINFO                     = LVM_FIRST + 165;

{$EXTERNALSYM ListView_SetTileViewInfo}
function ListView_SetTileViewInfo(wnd: HWND; ptvi: TLVTileViewInfo): bool;
{$EXTERNALSYM ListView_GetTileViewInfo}
procedure ListView_GetTileViewInfo(wnd: HWND; var ptvi: TLVTileViewInfo);
{$EXTERNALSYM ListView_SetTileInfo}
function ListView_SetTileInfo(wnd: HWND; pti : TLVTileInfo): bool;
{$EXTERNALSYM ListView_GetTileInfo}
procedure ListView_GetTileInfo(wnd: HWND; var pti: TLVTileInfo);


type
  {$EXTERNALSYM LVINSERTMARK}
  LVINSERTMARK = packed record
    cbSize : UINT;
    dwFlags : dword;
    iItem : integer;
    dwReserved : dword;
  end;
  {$EXTERNALSYM TLVInsertMark}
  TLVInsertMark = LVINSERTMARK;
  {$EXTERNALSYM PLVInsertMark}
  PLVInsertMark = ^TLVInsertMark;

const
  {$EXTERNALSYM LVIM_AFTER}
  LVIM_AFTER      = $00000001; // TRUE = insert After iItem, otherwise before

const
  {$EXTERNALSYM LVM_SETINSERTMARK}
  LVM_SETINSERTMARK              = LVM_FIRST + 166;
  {$EXTERNALSYM LVM_GETINSERTMARK}
  LVM_GETINSERTMARK              = LVM_FIRST + 167;

{$EXTERNALSYM ListView_SetInsertMark}
function ListView_SetInsertMark(wnd: HWND; lvim: TLVInsertMark): bool;
{$EXTERNALSYM ListView_GetInsertMark}
function ListView_GetInsertMark(wnd: HWND; var lvim: TLVInsertMark): bool;


const
  {$EXTERNALSYM LVM_INSERTMARKHITTEST}
  LVM_INSERTMARKHITTEST          = LVM_FIRST + 168;
  {$EXTERNALSYM LVM_GETINSERTMARKRECT}
  LVM_GETINSERTMARKRECT          = LVM_FIRST + 169;
  {$EXTERNALSYM LVM_SETINSERTMARKCOLOR}
  LVM_SETINSERTMARKCOLOR         = LVM_FIRST + 170;
  {$EXTERNALSYM LVM_GETINSERTMARKCOLOR}
  LVM_GETINSERTMARKCOLOR         = LVM_FIRST + 171;

{$EXTERNALSYM ListView_InsertMarkHitTest}
function ListView_InsertMarkHitTest(wnd: HWND; point: TPoint; lvim: TLVInsertMark): integer;
{$EXTERNALSYM ListView_GetInsertMarkRect}
function ListView_GetInsertMarkRect(wnd: HWND; var rc: TRect): integer;
{$EXTERNALSYM ListView_SetInsertMarkColor}
function ListView_SetInsertMarkColor(wnd: HWND; color: COLORREF): COLORREF;
{$EXTERNALSYM ListView_GetInsertMarkColor}
function ListView_GetInsertMarkColor(wnd: HWND): COLORREF;


type
  {$EXTERNALSYM tagLVSETINFOTIP}
  tagLVSETINFOTIP = packed record
    cbSize : UINT;
    dwFlags : dword;
    pszText : LPWSTR;
    iItem : integer;
    iSubItem : integer;
  end;
  {$EXTERNALSYM TLVSetInfoTip}
  TLVSetInfoTip = tagLVSETINFOTIP;
  {$EXTERNALSYM PLVSetInfoTip}
  PLVSetInfoTip = ^TLVSetInfoTip;

const
  {$EXTERNALSYM LVM_SETINFOTIP}
  LVM_SETINFOTIP         = LVM_FIRST + 173;

{$EXTERNALSYM ListView_SetInfoTip}
function ListView_SetInfoTip(hwndLV: HWND; plvInfoTip: TLVSetInfoTip): bool;

const
  {$EXTERNALSYM LVM_GETSELECTEDCOLUMN}
  LVM_GETSELECTEDCOLUMN  = LVM_FIRST + 174;

{$EXTERNALSYM ListView_GetSelectedColumn}
function ListView_GetSelectedColumn(wnd: HWND): UINT;

const
  {$EXTERNALSYM LVM_ISGROUPVIEWENABLED}
  LVM_ISGROUPVIEWENABLED = LVM_FIRST + 175;

  {$EXTERNALSYM ListView_IsGroupViewEnabled}
function ListView_IsGroupViewEnabled(wnd: HWND): bool;

const
  {$EXTERNALSYM LVM_GETOUTLINECOLOR}
  LVM_GETOUTLINECOLOR    = LVM_FIRST + 176;

{$EXTERNALSYM ListView_GetOutlineColor}
function ListView_GetOutlineColor(wnd: HWND): COLORREF;

const
  {$EXTERNALSYM LVM_SETOUTLINECOLOR}
  LVM_SETOUTLINECOLOR    = LVM_FIRST + 177;

{$EXTERNALSYM ListView_SetOutlineColor}
function ListView_SetOutlineColor(wnd: HWND; color: COLORREF): COLORREF;

const
  {$EXTERNALSYM LVM_CANCELEDITLABEL}
  LVM_CANCELEDITLABEL    = LVM_FIRST + 179;

{$EXTERNALSYM ListView_CancelEditLabel}
procedure ListView_CancelEditLabel(wnd: HWND);


// These next to methods make it easy to identify an item that can be repositioned
// within listview. For example: Many developers use the lParam to store an identifier that is
// unique. Unfortunatly, in order to find this item, they have to iterate through all of the items
// in the listview. Listview will maintain a unique identifier.  The upper bound is the size of a DWORD.
const
  {$EXTERNALSYM LVM_MAPINDEXTOID}
  LVM_MAPINDEXTOID       = LVM_FIRST + 180;
  {$EXTERNALSYM LVM_MAPIDTOINDEX}
  LVM_MAPIDTOINDEX       = LVM_FIRST + 181;

{$EXTERNALSYM ListView_MapIndexToID}
function ListView_MapIndexToID(wnd: HWND; index: uint): UINT;
{$EXTERNALSYM ListView_MapIDToIndex}
function ListView_MapIDToIndex(wnd: HWND; id: uint): UINT;


const
  {$EXTERNALSYM NMLVCUSTOMDRAW_V3_SIZE}
  NMLVCUSTOMDRAW_V3_SIZE = sizeof(TNMCustomDraw) +
    (2 * sizeof(COLORREF));
  {$EXTERNALSYM NMLVCUSTOMDRAW_V4_SIZE}
  NMLVCUSTOMDRAW_V4_SIZE = NMLVCUSTOMDRAW_V3_SIZE +
    sizeof(integer);
type
  {$EXTERNALSYM tagNMLVCUSTOMDRAW}
  tagNMLVCUSTOMDRAW = packed record
    nmcd: TNMCustomDraw;
    clrText: COLORREF;
    clrTextBk: COLORREF;
    iSubItem: Integer;

    dwItemType : dword;

    // Item custom draw
    clrFace : COLORREF;
    iIconEffect,
    iIconPhase,
    iPartId,
    iStateId : integer;

    // Group Custom Draw
    rcText : TRect;
    uAlign : UINT; // Alignment. Use LVGA_HEADER_CENTER, LVGA_HEADER_RIGHT, LVGA_HEADER_LEFT
  end;
  {$EXTERNALSYM PNMLVCustomDraw}
  PNMLVCustomDraw = ^TNMLVCustomDraw;
  {$EXTERNALSYM TNMLVCustomDraw}
  TNMLVCustomDraw = tagNMLVCUSTOMDRAW;

// dwItemType
const
  {$EXTERNALSYM LVCDI_ITEM}
  LVCDI_ITEM                  = $00000000;
  {$EXTERNALSYM LVCDI_GROUP}
  LVCDI_GROUP                 = $00000001;

// ListView custom draw return values
  {$EXTERNALSYM LVCDRF_NOSELECT}
  LVCDRF_NOSELECT             = $00010000;
  {$EXTERNALSYM LVCDRF_NOGROUPFRAME}
  LVCDRF_NOGROUPFRAME         = $00020000;


type
  {$EXTERNALSYM tagNMLVSCROLL}
  tagNMLVSCROLL = packed record
    hdr : NMHDR;
    dx,
    dy : integer;
  end;
  {$EXTERNALSYM TNMLVScroll}
  TNMLVScroll = tagNMLVSCROLL;
  {$EXTERNALSYM PNMLVScroll}
  PNMLVScroll = ^TNMLVScroll;

const
  {$EXTERNALSYM LVN_BEGINSCROLL}
  LVN_BEGINSCROLL          = LVN_FIRST-80;
  {$EXTERNALSYM LVN_ENDSCROLL}
  LVN_ENDSCROLL            = LVN_FIRST-81;


(********************************
	Tree-View
********************************)

const
  {$EXTERNALSYM TVSI_NOSINGLEEXPAND}
  TVSI_NOSINGLEEXPAND      = $8000; // Should not conflict with TVGN flags.


{$EXTERNALSYM TreeView_SetItemState}
function TreeView_SetItemState(hwndTV: HWND; hti: HTREEITEM;
  state, stateMask: UINT): UINT;

{$EXTERNALSYM TreeView_SetCheckState}
function TreeView_SetCheckState(hwndTV: HWND; hItem: HTREEITEM;
  fCheck: bool): UINT;

const
  {$EXTERNALSYM TVM_GETITEMSTATE}
  TVM_GETITEMSTATE         = TV_FIRST + 39;

{$EXTERNALSYM TreeView_GetItemState}
function TreeView_GetItemState(hwndTV: HWND; hti: HTREEITEM;
  mask: UINT): UINT;

{$EXTERNALSYM TreeView_GetCheckState}
function TreeView_GetCheckState(hwndTV: HWND; hti: HTREEITEM): UINT;

const
  {$EXTERNALSYM TVM_SETLINECOLOR}
  TVM_SETLINECOLOR         = TV_FIRST + 40;
  {$EXTERNALSYM TVM_GETLINECOLOR}
  TVM_GETLINECOLOR         = TV_FIRST + 41;

{$EXTERNALSYM TreeView_SetLineColor}
function TreeView_SetLineColor(hwnd: HWND; clr: COLORREF): COLORREF;
{$EXTERNALSYM TreeView_GetLineColor}
function TreeView_GetLineColor(hwnd: HWND): COLORREF;

const
  {$EXTERNALSYM TVM_MAPACCIDTOHTREEITEM}
  TVM_MAPACCIDTOHTREEITEM  = TV_FIRST + 42;
  {$EXTERNALSYM TVM_MAPHTREEITEMTOACCID}
  TVM_MAPHTREEITEMTOACCID  = TV_FIRST + 43;

{$EXTERNALSYM TreeView_MapAccIDToHTREEITEM}
function TreeView_MapAccIDToHTREEITEM(hwnd: HWND; id: UINT): HTREEITEM;
{$EXTERNALSYM TreeView_MapHTREEITEMToAccID}
function TreeView_MapHTREEITEMToAccID(hwnd: HWND; hti: HTREEITEM): UINT;


const
  {$EXTERNALSYM TVNRET_DEFAULT}
  TVNRET_DEFAULT          = 0;
  {$EXTERNALSYM TVNRET_SKIPOLD}
  TVNRET_SKIPOLD          = 1;
  {$EXTERNALSYM TVNRET_SKIPNEW}
  TVNRET_SKIPNEW          = 2;


(********************************
	SysLink
********************************)

const
  {$EXTERNALSYM INVALID_LINK_INDEX}
  INVALID_LINK_INDEX  = -1;
  {$EXTERNALSYM MAX_LINKID_TEXT}
  MAX_LINKID_TEXT     = 48;
  {$EXTERNALSYM L_MAX_URL_LENGTH}
  L_MAX_URL_LENGTH    = 2048 + 32 + length('://');

  {$EXTERNALSYM WC_LINK}
  WC_LINK             = 'SysLink';

  {$EXTERNALSYM LWS_TRANSPARENT}
  LWS_TRANSPARENT     = $0001;
  {$EXTERNALSYM LWS_IGNORERETURN}
  LWS_IGNORERETURN    = $0002;

  {$EXTERNALSYM LIF_ITEMINDEX}
  LIF_ITEMINDEX       = $00000001;
  {$EXTERNALSYM LIF_STATE}
  LIF_STATE           = $00000002;
  {$EXTERNALSYM LIF_ITEMID}
  LIF_ITEMID          = $00000004;
  {$EXTERNALSYM LIF_URL}
  LIF_URL             = $00000008;

  {$EXTERNALSYM LIS_FOCUSED}
  LIS_FOCUSED         = $00000001;
  {$EXTERNALSYM LIS_ENABLED}
  LIS_ENABLED         = $00000002;
  {$EXTERNALSYM LIS_VISITED}
  LIS_VISITED         = $00000004;

type
  {$EXTERNALSYM tagLITEM}
  tagLITEM = packed record
    mask      : uint;
    iLink     : integer;
    state,
    stateMask : uint;
    szId      : array[0..MAX_LINKID_TEXT]of widechar;
    szUrl     : array[0..L_MAX_URL_LENGTH]of widechar;
  end;
  {$EXTERNALSYM TLItem}
  TLItem = tagLITEM;
  {$EXTERNALSYM PLItem}
  PLItem = ^TLItem;

  {$EXTERNALSYM tagLHITTESTINFO}
  tagLHITTESTINFO = packed record
    pt   : TPoint;
    item : TLItem;
  end;
  {$EXTERNALSYM TLHitTestInfo}
  TLHitTestInfo = tagLHITTESTINFO;
  {$EXTERNALSYM PLHitTestInfo}
  PLHitTestInfo = ^TLHitTestInfo;

  {$EXTERNALSYM tagNMLINK}
  tagNMLINK = packed record
    hdr  : NMHDR;
    item : TLItem;
  end;
  {$EXTERNALSYM TNMLink}
  TNMLink = tagNMLINK;
  {$EXTERNALSYM PNMLink}
  PNMLink = ^TNMLink;

//  SysLink notifications
//  NM_CLICK   // wParam: control ID, lParam: PNMLINK, ret: ignored.

//  LinkWindow messages
const
  {$EXTERNALSYM LM_HITTEST}
  LM_HITTEST         = WM_USER+$300;  // wParam: n/a, lparam: PLHITTESTINFO, ret: BOOL
  {$EXTERNALSYM LM_GETIDEALHEIGHT}
  LM_GETIDEALHEIGHT  = WM_USER+$301;  // wParam: n/a, lparam: n/a, ret: cy
  {$EXTERNALSYM LM_SETITEM}
  LM_SETITEM         = WM_USER+$302;  // wParam: n/a, lparam: LITEM*, ret: BOOL
  {$EXTERNALSYM LM_GETITEM}
  LM_GETITEM         = WM_USER+$303;  // wParam: n/a, lparam: LITEM*, ret: BOOL


(********************************
	Header Control
********************************)

const
  {$EXTERNALSYM HDS_FLAT}
  HDS_FLAT                = $0200;

const
  {$EXTERNALSYM HDFT_ISSTRING}
  HDFT_ISSTRING           = $000;      // HD_ITEM.pvFilter points to a HD_TEXTFILTER
  {$EXTERNALSYM HDFT_ISNUMBER}
  HDFT_ISNUMBER           = $001;      // HD_ITEM.pvFilter points to a INT
  {$EXTERNALSYM HDFT_HASNOVALUE}
  HDFT_HASNOVALUE         = $8000;     // clear the filter, by setting this bit

type
  {$EXTERNALSYM _HD_TEXTFILTERA}
  _HD_TEXTFILTERA = packed record
    pszText: LPSTR;       // [in] pointer to the buffer containing the filter (ANSI)
    cchTextMax: integer;  // [in] max size of buffer/edit control buffer
  end;
  {$EXTERNALSYM THDTextFilterA}
  THDTextFilterA  = _HD_TEXTFILTERA;
  {$EXTERNALSYM PHDTextFilterA}
  PHDTextFilterA  = ^THDTextFilterA;

  {$EXTERNALSYM _HD_TEXTFILTERW}
  _HD_TEXTFILTERW = packed record
    pszText: LPWSTR;
    cchTextMax: integer;
  end;
  {$EXTERNALSYM THDTextFilterW}
  THDTextFilterW = _HD_TEXTFILTERW;
  {$EXTERNALSYM PHDTextFilterW}
  PHDTextFilterW = ^THDTextFilterW;

  {$EXTERNALSYM THDTextFilter}
  THDTextFilter = THDTextFilterA;

type
  PHDItemA = ^THDItemA;
  PHDItemW = ^THDItemW;
  PHDItem = PHDItemA;
  {$EXTERNALSYM _HD_ITEMA}
  _HD_ITEMA = packed record
    Mask: Cardinal;
    cxy: Integer;
    pszText: PAnsiChar;
    hbm: HBITMAP;
    cchTextMax: Integer;
    fmt: Integer;
    lParam: LPARAM;
    iImage: Integer;        // index of bitmap in ImageList
    iOrder: Integer;        // where to draw this item
    _type: UINT;            // [in] filter type (defined what pvFilter is a pointer to)
    pvFilter: pointer;      // [in] fillter data see above
  end;
  {$EXTERNALSYM _HD_ITEMW}
  _HD_ITEMW = packed record
    Mask: Cardinal;
    cxy: Integer;
    pszText: PWideChar;
    hbm: HBITMAP;
    cchTextMax: Integer;
    fmt: Integer;
    lParam: LPARAM;
    iImage: Integer;        // index of bitmap in ImageList
    iOrder: Integer;        // where to draw this item
    _type: UINT;            // [in] filter type (defined what pvFilter is a pointer to)
    pvFilter: pointer;      // [in] fillter data see above
  end;
  {$EXTERNALSYM _HD_ITEM}
  _HD_ITEM = _HD_ITEMA;
  THDItemA = _HD_ITEMA;
  THDItemW = _HD_ITEMW;
  THDItem = THDItemA;
  {$EXTERNALSYM HD_ITEMA}
  HD_ITEMA = _HD_ITEMA;
  {$EXTERNALSYM HD_ITEMW}
  HD_ITEMW = _HD_ITEMW;
  {$EXTERNALSYM HD_ITEM}
  HD_ITEM = HD_ITEMA;

{$EXTERNALSYM Header_GetItemCount}
function Header_GetItemCount(Header: HWnd): Integer;
{$EXTERNALSYM Header_InsertItem}
function Header_InsertItem(Header: HWnd; Index: Integer;
  const Item: THDItem): Integer;
{$EXTERNALSYM Header_DeleteItem}
function Header_DeleteItem(Header: HWnd; Index: Integer): Bool;
{$EXTERNALSYM Header_GetItem}
function Header_GetItem(Header: HWnd; Index: Integer; var Item: THDItem): Bool;
{$EXTERNALSYM Header_SetItem}
function Header_SetItem(Header: HWnd; Index: Integer; const Item: THDItem): Bool;


const
  {$EXTERNALSYM HDITEMA_V1_SIZE}
  HDITEMA_V1_SIZE = sizeof(THDItemA) - sizeof(UINT) - sizeof(pointer);
  {$EXTERNALSYM HDITEMW_V1_SIZE}
  HDITEMW_V1_SIZE = sizeof(THDItemW) - sizeof(UINT) - sizeof(pointer);

const
  {$EXTERNALSYM HDI_FILTER}
  HDI_FILTER              = $0100;

const
  {$EXTERNALSYM HDF_SORTUP}
  HDF_SORTUP              = $0400;
  {$EXTERNALSYM HDF_SORTDOWN}
  HDF_SORTDOWN            = $0200;

const
  {$EXTERNALSYM HHT_ONFILTER}
  HHT_ONFILTER            = $0010;
  {$EXTERNALSYM HHT_ONFILTERBUTTON}
  HHT_ONFILTERBUTTON      = $0020;


const
  {$EXTERNALSYM HDM_SETBITMAPMARGIN}
  HDM_SETBITMAPMARGIN         = HDM_FIRST + 20;
  {$EXTERNALSYM HDM_GETBITMAPMARGIN}
  HDM_GETBITMAPMARGIN         = HDM_FIRST + 21;

{$EXTERNALSYM Header_SetBitmapMargin}
function Header_SetBitmapMargin(wnd: HWND; iWidth: integer): integer;
{$EXTERNALSYM Header_GetBitmapMargin}
function Header_GetBitmapMargin(wnd: HWND): integer;

const
  {$EXTERNALSYM HDM_SETFILTERCHANGETIMEOUT}
  HDM_SETFILTERCHANGETIMEOUT  = HDM_FIRST + 22;

{$EXTERNALSYM Header_SetFilterChangeTimeout}
function Header_SetFilterChangeTimeout(wnd: HWND; i: integer): integer;

const
  {$EXTERNALSYM HDM_EDITFILTER}
  HDM_EDITFILTER              = HDM_FIRST + 23;

{$EXTERNALSYM Header_EditFilter}
function Header_EditFilter(wnd: HWND; i, fDiscardChanges: integer): integer;


// Clear filter takes -1 as a column value to indicate that all
// the filter should be cleared.  When this happens you will
// only receive a single filter changed notification.
const
  {$EXTERNALSYM HDM_CLEARFILTER}
  HDM_CLEARFILTER             = HDM_FIRST + 24;

{$EXTERNALSYM Header_ClearFilter}
function Header_ClearFilter(wnd: HWND; i: integer): integer;
{$EXTERNALSYM Header_ClearAllFilters}
function Header_ClearAllFilters(wnd: HWND): integer;

const
  {$EXTERNALSYM HDN_FILTERCHANGE}
  HDN_FILTERCHANGE            = HDN_FIRST - 12;
  {$EXTERNALSYM HDN_FILTERBTNCLICK}
  HDN_FILTERBTNCLICK          = HDN_FIRST - 13;

type
  {$EXTERNALSYM tagNMHDFILTERBTNCLICK}
  tagNMHDFILTERBTNCLICK = packed record
    hdr: TNMHdr;
    iItem: integer;
    rc: TRect;
  end;
  {$EXTERNALSYM TNMFilterBtnClick}
  TNMFilterBtnClick = tagNMHDFILTERBTNCLICK;
  {$EXTERNALSYM PNMFilterBtnClick}
  PNMFilterBtnClick = ^TNMFilterBtnClick;



(********************************
	Edit Control
********************************)

const
  {$EXTERNALSYM EM_SETCUEBANNER}
  EM_SETCUEBANNER                = ECM_FIRST + 1; // Set the cue banner with the lParm = LPCWSTR
  {$EXTERNALSYM EM_GETCUEBANNER}
  EM_GETCUEBANNER                = ECM_FIRST + 2; // Set the cue banner with the lParm = LPCWSTR

{$EXTERNALSYM Edit_SetCueBannerText}
function Edit_SetCueBannerText(hEdit: HWND; lpcwText: PWideChar): bool;
{$EXTERNALSYM Edit_GetCueBannerText}
function Edit_GetCueBannerText(hEdit: HWND; lpcwText: PWideChar;
  cchText: longint): bool;
{$EXTERNALSYM Edit_SetCueBannerTextFocused}
function Edit_SetCueBannerTextFocused(hEdit: HWND; lpcwText: PWideChar;
  fDrawFocused: bool): bool;

type
  _tagEDITBALLOONTIP = packed record
    cbStruct: DWORD;
    pszTitle,
    pszText : PWideChar;
    ttiIcon : integer;
  end;
  EDITBALLOONTIP  = _tagEDITBALLOONTIP;
  TEditBalloonTip = _tagEDITBALLOONTIP;
  PEditBalloonTip = ^TEditBalloonTip;

const
  EM_SHOWBALLOONTIP   = ECM_FIRST + 3; // Show a balloon tip associated to the edit control
  EM_HIDEBALLOONTIP   = ECM_FIRST + 4; // Hide any balloon tip associated with the edit control

function Edit_ShowBalloonTip(hEdit: HWND; pebt: PEditBalloonTip): bool;
function Edit_HideBalloonTip(hEdit: HWND): bool;



(********************************
	ComboBoxEx
********************************)

const
  {$EXTERNALSYM CBEM_SETWINDOWTHEME}
  CBEM_SETWINDOWTHEME     = CCM_SETWINDOWTHEME;


(********************************
	Progressbar
********************************)

const
  {$EXTERNALSYM PBS_MARQUEE}
  PBS_MARQUEE             = $08;
  {$EXTERNALSYM PBM_SETMARQUEE}
  PBM_SETMARQUEE          = WM_USER + 10;

  PBS_SMOOTHREVERSE       = $10;
  PBM_GETSTEP             = WM_USER+13;
  PBM_GETBKCOLOR          = WM_USER+14;
  PBM_GETBARCOLOR         = WM_USER+15;
  PBM_SETSTATE            = WM_USER+16; // wParam = PBST_[State] = NORMAL, ERROR, PAUSED;
  PBM_GETSTATE            = WM_USER+17;

  PBST_NORMAL             = $0001;
  PBST_ERROR              = $0002;
  PBST_PAUSED             = $0003;


(********************************
	TaskDialog
********************************)

// typedef HRESULT (CALLBACK *PFTASKDIALOGCALLBACK)(__in HWND hwnd, __in UINT msg, __in WPARAM wParam, __in LPARAM lParam, __in LONG_PTR lpRefData);

const
  // TASKDIALOG_FLAGS
  TDF_ENABLE_HYPERLINKS           = $0001;
  TDF_USE_HICON_MAIN              = $0002;
  TDF_USE_HICON_FOOTER            = $0004;
  TDF_ALLOW_DIALOG_CANCELLATION   = $0008;
  TDF_USE_COMMAND_LINKS           = $0010;
  TDF_USE_COMMAND_LINKS_NO_ICON   = $0020;
  TDF_EXPAND_FOOTER_AREA          = $0040;
  TDF_EXPANDED_BY_DEFAULT         = $0080;
  TDF_VERIFICATION_FLAG_CHECKED   = $0100;
  TDF_SHOW_PROGRESS_BAR           = $0200;
  TDF_SHOW_MARQUEE_PROGRESS_BAR   = $0400;
  TDF_CALLBACK_TIMER              = $0800;
  TDF_POSITION_RELATIVE_TO_WINDOW = $1000;
  TDF_RTL_LAYOUT                  = $2000;
  TDF_NO_DEFAULT_RADIO_BUTTON     = $4000;
  TDF_CAN_BE_MINIMIZED            = $8000;


  // TASKDIALOG_MESSAGES
  TDM_NAVIGATE_PAGE                   = WM_USER+101;
  TDM_CLICK_BUTTON                    = WM_USER+102; // wParam = Button ID
  TDM_SET_MARQUEE_PROGRESS_BAR        = WM_USER+103; // wParam = 0 (nonMarque) wParam != 0 (Marquee)
  TDM_SET_PROGRESS_BAR_STATE          = WM_USER+104; // wParam = new progress state
  TDM_SET_PROGRESS_BAR_RANGE          = WM_USER+105; // lParam = MAKELPARAM(nMinRange; nMaxRange)
  TDM_SET_PROGRESS_BAR_POS            = WM_USER+106; // wParam = new position
  TDM_SET_PROGRESS_BAR_MARQUEE        = WM_USER+107; // wParam = 0 (stop marquee); wParam != 0 (start marquee); lparam = speed (milliseconds between repaints)
  TDM_SET_ELEMENT_TEXT                = WM_USER+108; // wParam = element (TASKDIALOG_ELEMENTS); lParam = new element text (LPCWSTR)
  TDM_CLICK_RADIO_BUTTON              = WM_USER+110; // wParam = Radio Button ID
  TDM_ENABLE_BUTTON                   = WM_USER+111; // lParam = 0 (disable); lParam != 0 (enable); wParam = Button ID
  TDM_ENABLE_RADIO_BUTTON             = WM_USER+112; // lParam = 0 (disable); lParam != 0 (enable); wParam = Radio Button ID
  TDM_CLICK_VERIFICATION              = WM_USER+113; // wParam = 0 (unchecked); 1 (checked); lParam = 1 (set key focus)
  TDM_UPDATE_ELEMENT_TEXT             = WM_USER+114; // wParam = element (TASKDIALOG_ELEMENTS); lParam = new element text (LPCWSTR)
  TDM_SET_BUTTON_ELEVATION_REQUIRED_STATE = WM_USER+115; // wParam = Button ID; lParam = 0 (elevation not required); lParam != 0 (elevation required)
  TDM_UPDATE_ICON                     = WM_USER+116;  // wParam = icon element (TASKDIALOG_ICON_ELEMENTS); lParam = new icon (hIcon if TDF_USE_HICON_* was set; PCWSTR otherwise)


  // TASKDIALOG_NOTIFICATIONS
  TDN_CREATED                         = 0;
  TDN_NAVIGATED                       = 1;
  TDN_BUTTON_CLICKED                  = 2;            // wParam = Button ID
  TDN_HYPERLINK_CLICKED               = 3;            // lParam = (LPCWSTR)pszHREF
  TDN_TIMER                           = 4;            // wParam = Milliseconds since dialog created or timer reset
  TDN_DESTROYED                       = 5;
  TDN_RADIO_BUTTON_CLICKED            = 6;            // wParam = Radio Button ID
  TDN_DIALOG_CONSTRUCTED              = 7;
  TDN_VERIFICATION_CLICKED            = 8;             // wParam = 1 if checkbox checked; 0 if not; lParam is unused and always 0
  TDN_HELP                            = 9;
  TDN_EXPANDO_BUTTON_CLICKED          = 10;           // wParam = 0 (dialog is now collapsed); wParam != 0 (dialog is now expanded)

type
  TASKDIALOG_BUTTON = packed record
     nButtonId     : integer;
     pszButtonText : PWideChar;
  end;

const
  // TASKDIALOG_ELEMENTS
  TDE_CONTENT                  = 0;
  TDE_EXPANDED_INFORMATION     = 1;
  TDE_FOOTER                   = 2;
  TDE_MAIN_INSTRUCTION         = 3;

  // TASKDIALOG_ICON_ELEMENTS
  TDIE_ICON_MAIN               = 0;
  TDIE_ICON_FOOTER             = 1;

const
  TD_ICON_BLANK		       = 32512;
  TD_ICON_WARNING	       = 32515;
  TD_ICON_QUESTION	       = 32514;
  TD_ICON_ERROR		       = 32513;
  TD_ICON_INFORMATION	       = 32516;
  TD_ICON_BLANK_AGAIN	       = 32517;
  TD_ICON_SHIELD	       = 32518;

  // TASKDIALOG_COMMON_BUTTON_FLAGS
  TDCBF_OK_BUTTON            = $0001; // selected control return value IDOK
  TDCBF_YES_BUTTON           = $0002; // selected control return value IDYES
  TDCBF_NO_BUTTON            = $0004; // selected control return value IDNO
  TDCBF_CANCEL_BUTTON        = $0008; // selected control return value IDCANCEL
  TDCBF_RETRY_BUTTON         = $0010; // selected control return value IDRETRY
  TDCBF_CLOSE_BUTTON         = $0020; // selected control return value IDCLOSE

type
  TASKDIALOGCONFIG = packed record
    cbSize : uint;
    hwndParent : HWND;
    hInstance : longword;
    dwFlags : dword;
    dwCommonButtons : dword;
    pszWindowTitle : PWideChar;
    case integer of
      0 : (hMainIcon : HICON);
      1 : (pszMainIcon : PWideChar;
           pszMainInstruction : PWideChar;
           pszContent : PWideChar;
           cButtons : uint;
           pButtons : pointer;
           iDefaultButton : integer;
           cRadioButtons : uint;
           pRadioButtons : pointer;
           iDefaultRadioButton : integer;
           pszVerificationText,
           pszExpandedInformation,
           pszExpandedControlText,
           pszCollapsedControlText : PWideChar;
           case integer of
             0 : (hFooterIcon : HICON);
             1 : (pszFooterIcon : PWideChar;
                  pszFooterText : PWideChar;
                  pfCallback : pointer;
                  lpCallbackData : pointer;
                  cxWidth : uint;));
  end;
  PTaskDialogConfig = ^TASKDIALOGCONFIG;
  TTaskDialogConfig = TASKDIALOGCONFIG;



function TaskDialogIndirect(ptc : PTaskDialogConfig; pnButton: PInteger;
  pnRadioButton: PInteger; pfVerificationFlagChecked: PBool): HRESULT; stdcall;

function TaskDialog(hwndParent: HWND; hInstance: longword;
  pszWindowTitle: PWideChar; pszMainInstruction : PWideChar;
  pszContent: PWideChar; dwCommonButtons: dword; pszIcon : LPWSTR;
  var pnButton: integer): HRESULT; stdcall;


(********************************
		Buttons
********************************)

const
// BUTTON STATE FLAGS
  BST_DROPDOWNPUSHED      = $0400;

// BUTTON STYLES
  BS_SPLITBUTTON          = $0000000C;
  BS_DEFSPLITBUTTON       = $0000000D;
  BS_COMMANDLINK          = $0000000E;
  BS_DEFCOMMANDLINK       = $0000000F;

// SPLIT BUTTON INFO mask flags
  BCSIF_GLYPH             = $0001;
  BCSIF_IMAGE             = $0002;
  BCSIF_STYLE             = $0004;
  BCSIF_SIZE              = $0008;

// SPLIT BUTTON STYLE flags
  BCSS_NOSPLIT            = $0001;
  BCSS_STRETCH            = $0002;
  BCSS_ALIGNLEFT          = $0004;
  BCSS_IMAGE              = $0008;

type
  tagBUTTON_SPLITINFO = packed record
    mask : uint;
    himlGlyph : HIMAGELIST;
    uSplitStyle : uint;
    size : SIZE;
  end;
  BUTTONSPLITINFO = tagBUTTON_SPLITINFO;
  TButtonSplitInfo = tagBUTTON_SPLITINFO;
  PButtonSplitInfo = ^TButtonSplitInfo;

// BUTTON MESSAGES
const
  BCM_SETDROPDOWNSTATE     = BCM_FIRST + $0006;
  BCM_SETSPLITINFO         = BCM_FIRST + $0007;
  BCM_GETSPLITINFO         = BCM_FIRST + $0008;
  BCM_SETNOTE              = BCM_FIRST + $0009;
  BCM_GETNOTE              = BCM_FIRST + $000A;
  BCM_GETNOTELENGTH        = BCM_FIRST + $000B;
  BCM_SETSHIELD            = BCM_FIRST + $000C;


  function Button_SetDropDownState(wnd: HWND; fDropDown: bool): bool;
  function Button_SetSplitInfo(wnd: HWND; pInfo: PButtonSplitInfo): bool;
  function Button_GetSplitInfo(wnd: HWND; pInfo: PButtonSplitInfo): bool;
  function Button_SetNote(wnd: HWND; pszNote: PWideChar): bool;
(*
#define Button_GetNote(hwnd, psz, pcc) \
    (BOOL)SNDMSG((hwnd), BCM_GETNOTE, (WPARAM)pcc, (LPARAM)psz)

#define Button_GetNoteLength(hwnd) \
    (LRESULT)SNDMSG((hwnd), BCM_GETNOTELENGTH, 0, 0)
*)
  function Button_GetNoteLength(wnd: HWND): LRESULT;
  function Button_SetElevationRequiredState(wnd: HWND; fRequired: bool):
    LRESULT;


const
// Value to pass to BCM_SETIMAGELIST to indicate that no glyph should be
// displayed
  BCCL_NOGLYPH = HIMAGELIST(-1);
  BCN_DROPDOWN = BCM_FIRST + $0002;

type
  tagNMBCDROPDOWN = packed record
    hdr: NMHDR;
    rcButton : TRect;
  end;
  NMBCDROPDOWN = tagNMBCDROPDOWN;
  TNMBCDropDown = tagNMBCDROPDOWN;
  PNMBCDropDown = ^TNMBCDropDown;


implementation

// Vista

const
  comctl32 = 'comctl32.dll';

function TaskDialogIndirect; external comctl32;
function TaskDialog; external comctl32;


// PropSheet

function PropSheet_SetCurSel(hDlg: HWND; hpage: HPROPSHEETPAGE;
  index: integer): bool;
begin
  Result := bool(SendMessage(hDlg,PSM_SETCURSEL,WPARAM(index),LPARAM(hpage)));
end;

function PropSheet_RemovePage(hDlg: HWND; index: integer;
  hpage: HPROPSHEETPAGE): bool;
begin
  Result := bool(SendMessage(hDlg,PSM_REMOVEPAGE,index,LPARAM(hpage)));
end;

function PropSheet_AddPage(hDlg: HWND; hpage: HPROPSHEETPAGE): bool;
begin
  Result := bool(SendMessage(hDlg,PSM_ADDPAGE,0,LPARAM(hpage)));
end;

function PropSheet_Changed(hDlg: HWND; hwndPage: HWND): bool;
begin
  Result := bool(SendMessage(hDlg,PSM_CHANGED,hwndPage,0));
end;

procedure PropSheet_RestartWindows(hDlg: HWND);
begin
  SendMessage(hDlg, PSM_RESTARTWINDOWS, 0, 0);
end;

procedure PropSheet_RebootSystem(hDlg: HWND);
begin
  SendMessage(hDlg, PSM_REBOOTSYSTEM, 0, 0);
end;

procedure PropSheet_CancelToClose(hDlg: HWND);
begin
  PostMessage(hDlg, PSM_CANCELTOCLOSE, 0, 0)
end;

function PropSheet_QuerySiblings(hDlg: HWND; wp: WPARAM; lp: LPARAM):
  integer;
begin
  Result := SendMessage(hDlg,PSM_QUERYSIBLINGS,wp,lp);
end;

procedure PropSheet_UnChanged(hDlg: HWND; hwndPage: HWND);
begin
  SendMessage(hDlg, PSM_UNCHANGED, WPARAM(hwndPage), 0);
end;

function PropSheet_Apply(hDlg: HWND): bool;
begin
  Result := bool(SendMessage(hDlg,PSM_APPLY,0,0));
end;

procedure PropSheet_SetTitle(hPropSheetDlg: HWND; dwStyle: DWORD;
  lpszText: LPTSTR);
begin
  SendMessage(hPropSheetDlg,PSM_SETTITLE,dwStyle,LPARAM(lpszText));
end;

procedure PropSheet_SetWizButtons(hDlg: HWND; dwFlags: dword);
begin
  PostMessage(hDlg, PSM_SETWIZBUTTONS, 0, LPARAM(dwFlags));
end;

function PropSheet_PressButton(hDlg: HWND; iButton: integer): bool;
begin
  Result := bool(PostMessage(hDlg, PSM_PRESSBUTTON, WPARAM(iButton), 0));
end;

function PropSheet_SetCurSelByID(hDlg: HWND; id: integer): bool;
begin
  Result := bool(SendMessage(hDlg, PSM_SETCURSELID, 0, LPARAM(id)));
end;

procedure PropSheet_SetFinishText(hDlg: HWND; lpszText: LPTSTR);
begin
  SendMessage(hDlg, PSM_SETFINISHTEXT, 0, LPARAM(lpszText));
end;

function PropSheet_GetTabControl(hDlg: HWND): HWND;
begin
  Result := HWND(SendMessage(hDlg, PSM_GETTABCONTROL, 0, 0));
end;

function PropSheet_IsDialogMessage(hDlg: HWND; pMsg: TMsg): bool;
begin
  Result := bool(SendMessage(hDlg, PSM_ISDIALOGMESSAGE, 0, LPARAM(@pMsg)));
end;

function PropSheet_GetCurrentPageHwnd(hDlg: HWND): HWND;
begin
  Result := HWND(SendMessage(hDlg, PSM_GETCURRENTPAGEHWND, 0, 0));
end;

function PropSheet_InsertPage(hDlg: HWND; index: integer; hPage: HPROPSHEETPAGE): bool;
begin
  Result := bool(SendMessage(hDlg, PSM_INSERTPAGE, WPARAM(index), LPARAM(hpage)));
end;

function PropSheet_SetHeaderTitle(hDlg: HWND; index: integer; lpszText: LPCTSTR): integer;
begin
  Result := SendMessage(hDlg, PSM_SETHEADERTITLE, WPARAM(index), LPARAM(lpszText));
end;

procedure PropSheet_SetHeaderSubTitle(hDlg: HWND; index: integer; lpszText: LPCSTR);
begin
  SendMessage(hDlg, PSM_SETHEADERSUBTITLE, WPARAM(index), LPARAM(lpszText));
end;

function PropSheet_HwndToIndex(hDlg, hwndPage: HWND): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_HWNDTOINDEX, WPARAM(hwndPage), 0));
end;

function PropSheet_IndexToHwnd(hDlg: HWND; i: integer): HWND;
begin
  Result := HWND(SendMessage(hDlg, PSM_INDEXTOHWND, WPARAM(i), 0));
end;

function PropSheet_PageToIndex(hDlg: HWND; hpage: HPROPSHEETPAGE): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_PAGETOINDEX, 0, LPARAM(hpage)));
end;

function PropSheet_IndexToPage(hDlg: HWND; i: integer): HPROPSHEETPAGE;
begin
  Result := HPROPSHEETPAGE(SendMessage(hDlg, PSM_INDEXTOPAGE,WPARAM(i), 0));
end;

function PropSheet_IdToIndex(hDlg: HWND; id: integer): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_IDTOINDEX, 0, LPARAM(id)));
end;

function PropSheet_IndexToId(hDlg: HWND; i: integer): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_INDEXTOID, WPARAM(i), 0));
end;

function PropSheet_GetResult(hDlg: HWND): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_GETRESULT, 0, 0));
end;

function PropSheet_RecalcPageSizes(hDlg: HWND): bool;
begin
  Result := bool(SendMessage(hDlg, PSM_RECALCPAGESIZES, 0, 0));
end;

function PropSheet_SetNextText(hDlg: HWND; lpszText: PWideChar): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_SETNEXTTEXT, 0, LPARAM(lpszText)));
end;

procedure PropSheet_ShowWizButtons(hDlg: HWND; dwFlag, dwButton: DWORD);
begin
  PostMessage(hDlg, PSM_SHOWWIZBUTTONS, WPARAM(dwFlag), LPARAM(dwButton));
end;

procedure PropSheet_EnableWizButtons(hDlg: HWND; dwState, dwMask: DWORD);
begin
  PostMessage(hDlg, PSM_ENABLEWIZBUTTONS, WPARAM(dwState), LPARAM(dwMask));
end;

function PropSheet_SetButtonText(hDlg: HWND; dwButton: DWORD; lpszText: PWideChar): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_SETBUTTONTEXT, WPARAM(dwButton),
    LPARAM(lpszText)));
end;

// List-View

function ListView_SetExtendedListViewStyleEx(hwndLV: HWND; dwMask, dw: DWORD): dword;
begin
  Result := dword(SendMessage(hwndLV,LVM_SETEXTENDEDLISTVIEWSTYLE,dwMask,dw));
end;

function ListView_SortItemsEx(hwndLV: HWND; pfnCompare: TLVCompare; lPrm: longint): bool;
begin
  Result := bool(SendMessage(hwndLV,LVM_SORTITEMSEX,WPARAM(lPrm),LPARAM(@pfnCompare)));
end;

procedure ListView_SetSelectedColumn(wnd: HWND; iCol: integer);
begin
  SendMessage(wnd,LVM_SETSELECTEDCOLUMN,WPARAM(iCol),0);
end;

function ListView_SetTileWidth(wnd: HWND; cpWidth: integer): integer;
begin
  Result := integer(SendMessage(wnd,LVM_SETTILEWIDTH,WPARAM(cpWidth),0));
end;

function ListView_SetView(wnd: HWND; iView: dword): dword;
begin
  Result := dword(SendMessage(wnd,LVM_SETVIEW,WPARAM(iView),0));
end;

function ListView_GetView(wnd: HWND): dword;
begin
  Result := dword(SendMessage(wnd,LVM_GETVIEW,0,0));
end;

function ListView_InsertGroup(wnd: HWND; index: integer; pgrp: TLVGroup): integer;
begin
  Result := integer(SendMessage(wnd,LVM_INSERTGROUP,index,LPARAM(@pgrp)));
end;

function ListView_SetGroupInfo(wnd: HWND; iGroupId: integer; pgrp: TLVGroup): integer;
begin
  Result := integer(SendMessage(wnd,LVM_SETGROUPINFO,iGroupId,LPARAM(@pgrp)));
end;

function ListView_GetGroupInfo(wnd: HWND; iGroupId: integer; var pgrp: TLVGroup): integer;
begin
  Result := integer(SendMessage(wnd,LVM_GETGROUPINFO,WPARAM(iGroupId),LPARAM(@pgrp)));
end;

function ListView_RemoveGroup(wnd: HWND; iGroupId: integer): integer;
begin
  Result := integer(SendMessage(wnd,LVM_REMOVEGROUP,WPARAM(iGroupId),0));
end;

procedure ListView_MoveGroup(wnd: HWND; iGroupId, toIndex: integer);
begin
  SendMessage(wnd,LVM_MOVEGROUP,WPARAM(iGroupId),LPARAM(toIndex));
end;

procedure ListView_MoveItemToGroup(wnd: HWND; idItemFrom, idGroupTo: integer);
begin
  SendMessage(wnd,LVM_MOVEITEMTOGROUP,WPARAM(idItemFrom),LPARAM(idGroupTo));
end;

procedure ListView_SetGroupMetrics(wnd: HWND; pGroupMetrics: TLVGroupMetrics);
begin
  SendMessage(wnd,LVM_SETGROUPMETRICS,0,LPARAM(@pGroupMetrics));
end;

procedure ListView_GetGroupMetrics(wnd: HWND; var pGroupMetrics: TLVGroupMetrics);
begin
  SendMessage(wnd,LVM_GETGROUPMETRICS,0,LPARAM(@pGroupMetrics));
end;

function ListView_EnableGroupView(wnd: HWND; fEnable: bool): integer;
begin
  Result := integer(SendMessage(wnd,LVM_ENABLEGROUPVIEW,WPARAM(fEnable),0));
end;

function ListView_SortGroups(wnd: HWND; fnGroupCompare: TLVGroupCompare; plv: pointer): integer;
begin
  Result := integer(SendMessage(wnd,LVM_SORTGROUPS,WPARAM(@fnGroupCompare),LPARAM(plv)));
end;

procedure ListView_InsertGroupSorted(wnd: HWND; structInsert: TVLInsertGroupSorted);
begin
  SendMessage(wnd,LVM_INSERTGROUPSORTED,WPARAM(@structInsert),0);
end;

procedure ListView_RemoveAllGroups(wnd: HWND);
begin
  SendMessage(wnd,LVM_REMOVEALLGROUPS,0,0);
end;

function ListView_HasGroup(wnd: HWND; dwGroupId: dword): bool;
begin
  Result := bool(SendMessage(wnd,LVM_HASGROUP,WPARAM(dwGroupId),0));
end;

function ListView_SetTileViewInfo(wnd: HWND; ptvi: TLVTileViewInfo): bool;
begin
  Result := bool(SendMessage(wnd,LVM_SETTILEVIEWINFO,0,LPARAM(@ptvi)));
end;

procedure ListView_GetTileViewInfo(wnd: HWND; var ptvi: TLVTileViewInfo);
begin
  SendMessage(wnd,LVM_GETTILEVIEWINFO,0,LPARAM(@ptvi));
end;

function ListView_SetTileInfo(wnd: HWND; pti: TLVTileInfo): bool;
begin
  Result := bool(SendMessage(wnd,LVM_SETTILEINFO,0,LPARAM(@pti)));
end;

procedure ListView_GetTileInfo(wnd: HWND; var pti: TLVTileInfo);
begin
  SendMessage(wnd,LVM_GETTILEINFO,0,LPARAM(@pti));
end;

function ListView_SetInsertMark(wnd: HWND; lvim: TLVInsertMark): bool;
begin
  Result := bool(SendMessage(wnd,LVM_SETINSERTMARK,0,LPARAM(@lvim)));
end;

function ListView_GetInsertMark(wnd: HWND; var lvim: TLVInsertMark): bool;
begin
  Result := bool(SendMessage(wnd,LVM_GETINSERTMARK,0,LPARAM(@lvim)));
end;

function ListView_InsertMarkHitTest(wnd: HWND; point: TPoint; lvim: TLVInsertMark): integer;
begin
  Result := integer(SendMessage(wnd,LVM_INSERTMARKHITTEST,
    WPARAM(@point),LPARAM(@lvim)));
end;

function ListView_GetInsertMarkRect(wnd: HWND; var rc: TRect): integer;
begin
  Result := integer(SendMessage(wnd,LVM_GETINSERTMARKRECT,0,LPARAM(@rc)));
end;

function ListView_SetInsertMarkColor(wnd: HWND; color: COLORREF): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd,LVM_SETINSERTMARKCOLOR,0,color));
end;

function ListView_GetInsertMarkColor(wnd: HWND): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd,LVM_GETINSERTMARKCOLOR,0,0));
end;

function ListView_SetInfoTip(hwndLV: HWND; plvInfoTip: TLVSetInfoTip): bool;
begin
  Result := bool(SendMessage(hwndLV,LVM_SETINFOTIP,0,LPARAM(@plvInfoTip)));
end;

function ListView_GetSelectedColumn(wnd: HWND): UINT;
begin
  Result := UINT(SendMessage(wnd,LVM_GETSELECTEDCOLUMN,0,0));
end;

function ListView_IsGroupViewEnabled(wnd: HWND): bool;
begin
  Result := bool(SendMessage(wnd,LVM_ISGROUPVIEWENABLED,0,0));
end;

function ListView_GetOutlineColor(wnd: HWND): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd,LVM_GETOUTLINECOLOR,0,0));
end;

function ListView_SetOutlineColor(wnd: HWND; color: COLORREF): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd,LVM_SETOUTLINECOLOR,0,color));
end;

procedure ListView_CancelEditLabel(wnd: HWND);
begin
  SendMessage(wnd,LVM_CANCELEDITLABEL,0,0);
end;

function ListView_MapIndexToID(wnd: HWND; index: uint): UINT;
begin
  Result := UINT(SendMessage(wnd,LVM_MAPINDEXTOID,index,0));
end;

function ListView_MapIDToIndex(wnd: HWND; id: uint): UINT;
begin
  Result := UINT(SendMessage(wnd,LVM_MAPIDTOINDEX,id,0));
end;


// Tree-View

function TreeView_SetItemState(hwndTV: HWND; hti: HTREEITEM;
  state, stateMask: UINT): UINT;
var
  _ms_TVi : TTVItem;
begin
  _ms_TVi.mask      := TVIF_STATE;
  _ms_TVi.hItem     := hti;
  _ms_TVi.stateMask := stateMask;
  _ms_TVi.state     := state;
  Result            := SendMessage(hwndTV,TVM_SETITEM,0,LPARAM(@_ms_TVi));
end;

function TreeView_SetCheckState(hwndTV: HWND; hItem: HTREEITEM;
  fCheck: bool): UINT;
const
  iStateMask : array[boolean]of byte = (1,2);
begin
  Result := TreeView_SetItemState(hwndTV,hItem,iStateMask[fCheck],
    TVIS_STATEIMAGEMASK);
end;

function TreeView_GetItemState(hwndTV: HWND; hti: HTREEITEM;
  mask: UINT): UINT;
begin
  Result := SendMessage(hwndTV,TVM_GETITEMSTATE,WPARAM(hti),LPARAM(mask));
end;

function TreeView_GetCheckState(hwndTV: HWND; hti: HTREEITEM): UINT;
begin
  Result := ((SendMessage(hwndTV,TVM_GETITEMSTATE,WPARAM(hti),
    TVIS_STATEIMAGEMASK) shr 12) - 1);
end;

function TreeView_SetLineColor(hwnd: HWND; clr: COLORREF): COLORREF;
begin
  Result := COLORREF(SendMessage(hwnd,TVM_SETLINECOLOR,0,
    LPARAM(clr)));
end;

function TreeView_GetLineColor(hwnd: HWND): COLORREF;
begin
  Result := COLORREF(SendMessage(hwnd,TVM_GETLINECOLOR,0,0));
end;

function TreeView_MapAccIDToHTREEITEM(hwnd: HWND; id: UINT): HTREEITEM;
begin
  Result := HTREEITEM(SendMessage(hwnd,TVM_MAPACCIDTOHTREEITEM,0,id));
end;

function TreeView_MapHTREEITEMToAccID(hwnd: HWND; hti: HTREEITEM): UINT;
begin
  Result := UINT(SendMessage(hwnd,TVM_MAPHTREEITEMTOACCID,
    WPARAM(hti),0));
end;


// Header

function Header_SetBitmapMargin(wnd: HWND; iWidth: integer): integer;
begin
  Result := integer(SendMessage(wnd,HDM_SETBITMAPMARGIN,
    WPARAM(iWidth),0));
end;

function Header_GetBitmapMargin(wnd: HWND): integer;
begin
  Result := integer(SendMessage(wnd,HDM_GETBITMAPMARGIN,0,0));
end;

function Header_SetFilterChangeTimeout(wnd: HWND; i: integer): integer;
begin
  Result := integer(SendMessage(wnd,HDM_SETFILTERCHANGETIMEOUT,0,
    LPARAM(i)));
end;

function Header_EditFilter(wnd: HWND; i, fDiscardChanges: integer): integer;
begin
  Result := integer(SendMessage(wnd,HDM_EDITFILTER,WPARAM(i),
    MAKELPARAM(fDiscardChanges,0)));
end;

function Header_ClearFilter(wnd: HWND; i: integer): integer;
begin
  Result := integer(SendMessage(wnd,HDM_CLEARFILTER,WPARAM(i),0));
end;

function Header_ClearAllFilters(wnd: HWND): integer;
begin
  Result := integer(SendMessage(wnd,HDM_CLEARFILTER,-1,0));
end;

function Header_GetItemCount(Header: HWnd): Integer;
begin
  Result := SendMessage(Header, HDM_GETITEMCOUNT, 0, 0);
end;

// patched

function Header_InsertItem(Header: HWnd; Index: Integer;
  const Item: THDItem): Integer;
begin
  Result := SendMessage(Header, HDM_INSERTITEM, Index, Longint(@Item));
end;

function Header_DeleteItem(Header: HWnd; Index: Integer): Bool;
begin
  Result := Bool( SendMessage(Header, HDM_DELETEITEM, Index, 0) );
end;

function Header_GetItem(Header: HWnd; Index: Integer; var Item: THDItem): Bool;
begin
  Result := Bool( SendMessage(Header, HDM_GETITEM, Index, Longint(@Item)) );
end;

function Header_SetItem(Header: HWnd; Index: Integer; const Item: THDItem): Bool;
begin
  Result := Bool( SendMessage(Header, HDM_SETITEM, Index, Longint(@Item)) );
end;


// Edit

function Edit_SetCueBannerText(hEdit: HWND; lpcwText: PWideChar): bool;
begin
  Result := Bool(SendMessage(hEdit,EM_SETCUEBANNER,0,LPARAM(lpcwText)));
end;

function Edit_GetCueBannerText(hEdit: HWND; lpcwText: PWideChar;
  cchText: longint): bool;
begin
  Result := Bool(SendMessage(hEdit,EM_GETCUEBANNER,WPARAM(lpcwText),
    LPARAM(cchText)));
end;

function Edit_SetCueBannerTextFocused(hEdit: HWND; lpcwText: PWideChar;
  fDrawFocused: bool): bool;
begin
  Result := bool(SendMessage(hEdit, EM_SETCUEBANNER, WPARAM(fDrawFocused),
    LPARAM(lpcwText)));
end;

function Edit_ShowBalloonTip(hEdit: HWND; pebt: PEditBalloonTip): bool;
begin
  Result := Bool(SendMessage(hEdit,EM_SHOWBALLOONTIP,0,LPARAM(pebt)));
end;

function Edit_HideBalloonTip(hEdit: HWND): bool;
begin
  Result := Bool(SendMessage(hEdit,EM_HIDEBALLOONTIP,0,0));
end;


// Button

function Button_SetDropDownState(wnd: HWND; fDropDown: bool): bool;
begin
  Result := bool(SendMessage(wnd, BCM_SETDROPDOWNSTATE, WPARAM(fDropDown), 0));
end;

function Button_SetSplitInfo(wnd: HWND; pInfo: PButtonSplitInfo): bool;
begin
  Result := bool(SendMessage(wnd, BCM_SETSPLITINFO, 0, LPARAM(pInfo)));
end;

function Button_GetSplitInfo(wnd: HWND; pInfo: PButtonSplitInfo): bool;
begin
  Result := bool(SendMessage(wnd, BCM_GETSPLITINFO, 0, LPARAM(pInfo)));
end;

function Button_SetNote(wnd: HWND; pszNote: PWideChar): bool;
begin
  Result := bool(SendMessage(wnd, BCM_SETNOTE, 0, LPARAM(pszNote)));
end;

function Button_GetNoteLength(wnd: HWND): LRESULT;
begin
  Result := SendMessage(wnd, BCM_GETNOTELENGTH, 0, 0);
end;

function Button_SetElevationRequiredState(wnd: HWND; fRequired: bool): LRESULT;
begin
  Result := SendMessage(wnd, BCM_SETSHIELD, 0, LPARAM(fRequired));
end;

end.
