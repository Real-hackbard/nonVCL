unit ShellAPI_Fragment;

interface

uses
  Windows, Messages;


(********************************
	SHFileOperation
********************************)
const
   {$EXTERNALSYM FOF_NOCOPYSECURITYATTRIBS}
   FOF_NOCOPYSECURITYATTRIBS  = $0800;  // dont copy NT file Security Attributes
   {$EXTERNALSYM FOF_NORECURSION}
   FOF_NORECURSION            = $1000;  // don't recurse into directories.
   {$EXTERNALSYM FOF_NO_CONNECTED_ELEMENTS}
   FOF_NO_CONNECTED_ELEMENTS  = $2000;  // don't operate on connected elements.
   {$EXTERNALSYM FOF_WANTNUKEWARNING}
   FOF_WANTNUKEWARNING        = $4000;  // during delete operation, warn if nuking instead of recycling
   									    // (partially overrides FOF_NOCONFIRMATION)
   {$EXTERNALSYM FOF_NORECURSEREPARSE}
   FOF_NORECURSEREPARSE       = $8000;  // treat reparse points as objects, not containers


(********************************
	ShellExecuteEx
********************************)
const
   {$EXTERNALSYM SEE_MASK_UNICODE}
   SEE_MASK_UNICODE           = $00040000; // !!! changed from previous SDK (was $00004000)
   {$EXTERNALSYM SEE_MASK_HMONITOR}
   SEE_MASK_HMONITOR          = $00200000;
   {$EXTERNALSYM SEE_MASK_NOZONECHECKS}
   SEE_MASK_NOZONECHECKS      = $00800000;
   {$EXTERNALSYM SEE_MASK_NOQUERYCLASSSTORE}
   SEE_MASK_NOQUERYCLASSSTORE = $01000000;
   {$EXTERNALSYM SEE_MASK_WAITFORINPUTIDLE}
   SEE_MASK_WAITFORINPUTIDLE  = $02000000;
   {$EXTERNALSYM SEE_MASK_FLAG_LOG_USAGE}
   SEE_MASK_FLAG_LOG_USAGE    = $04000000;


(********************************
	Recycle.Bin
********************************)
type
  {$EXTERNALSYM _SHQUERYRBINFO}
  _SHQUERYRBINFO =
    packed record
      cbSize  : DWORD;
      i64Size : int64;
      i64NumItems : int64;
    end;
  {$EXTERNALSYM TSHQueryRBInfo}
  TSHQueryRBInfo = _SHQUERYRBINFO;
  {$EXTERNALSYM PSHQueryRBInfo}
  PSHQueryRBInfo = ^TSHQueryRBInfo;

const
  {$EXTERNALSYM SHERB_NOCONFIRMATION}
  SHERB_NOCONFIRMATION    = $00000001;
  {$EXTERNALSYM SHERB_NOPROGRESSUI}
  SHERB_NOPROGRESSUI      = $00000002;
  {$EXTERNALSYM SHERB_NOSOUND}
  SHERB_NOSOUND           = $00000004;

  {$EXTERNALSYM SHQueryRecycleBinA}
  function SHQueryRecycleBinA(pszRootPath: LPCTSTR; var pSHQueryRBInfo: TSHQueryRBInfo): HRESULT; stdcall;
  {$EXTERNALSYM SHQueryRecycleBinW}
  function SHQueryRecycleBinW(pszRootPath: LPWSTR; var pSHQueryRBInfo: TSHQueryRBInfo): HRESULT; stdcall;
  {$EXTERNALSYM SHQueryRecycleBin}
  function SHQueryRecycleBin(pszRootPath: LPCTSTR; var pSHQueryRBInfo: TSHQueryRBInfo): HRESULT; stdcall;
  {$EXTERNALSYM SHEmptyRecycleBinA}
  function SHEmptyRecycleBinA(hwnd: HWND; pszRootPath: LPCTSTR; dwFlags: dword): HRESULT; stdcall;
  {$EXTERNALSYM SHEmptyRecycleBinW}
  function SHEmptyRecycleBinW(hwnd: HWND; pszRootPath: LPWSTR; dwFlags: dword): HRESULT; stdcall;
  {$EXTERNALSYM SHEmptyRecycleBin}
  function SHEmptyRecycleBin(hwnd: HWND; pszRootPath: LPCTSTR; dwFlags: dword): HRESULT; stdcall;


(*
 * The SHFormatDrive API provides access to the Shell
 *   format dialog. This allows apps which want to format disks
 *   to bring up the same dialog that the Shell does to do it.
 *
 *   This dialog is not sub-classable. You cannot put custom
 *   controls in it. If you want this ability, you will have
 *   to write your own front end for the DMaint_FormatDrive
 *   engine.
 *
 *   NOTE that the user can format as many diskettes in the specified
 *   drive, or as many times, as he/she wishes to. There is no way to
 *   force any specififc number of disks to format. If you want this
 *   ability, you will have to write your own front end for the
 *   DMaint_FormatDrive engine.
 *
 *   NOTE also that the format will not start till the user pushes the
 *   start button in the dialog. There is no way to do auto start. If
 *   you want this ability, you will have to write your own front end
 *   for the DMaint_FormatDrive engine.
 *
 *   PARAMETERS
 *
 *     hwnd    = The window handle of the window which will own the dialog
 *               NOTE that unlike SHCheckDrive, hwnd == NULL does not cause
 *               this dialog to come up as a "top level application" window.
 *               This parameter should always be non-null, this dialog is
 *               only designed to be the child of another window, not a
 *               stand-alone application.
 *     drive   = The 0 based (A: == 0) drive number of the drive to format
 *     fmtID   = The ID of the physical format to format the disk with
 *               NOTE: The special value SHFMT_ID_DEFAULT means "use the
 *                     default format specified by the DMaint_FormatDrive
 *                     engine". If you want to FORCE a particular format
 *                     ID "up front" you will have to call
 *                     DMaint_GetFormatOptions yourself before calling
 *                     this to obtain the valid list of phys format IDs
 *                     (contents of the PhysFmtIDList array in the
 *                     FMTINFOSTRUCT).
 *     options = There is currently only two option bits defined
 *
 *                SHFMT_OPT_FULL
 *                SHFMT_OPT_SYSONLY
 *
 *               The normal defualt in the Shell format dialog is
 *               "Quick Format", setting this option bit indicates that
 *               the caller wants to start with FULL format selected
 *               (this is useful for folks detecting "unformatted" disks
 *               and wanting to bring up the format dialog).
 *
 *               The SHFMT_OPT_SYSONLY initializes the dialog to
 *               default to just sys the disk.
 *
 *               All other bits are reserved for future expansion and
 *               must be 0.
 *
 *               Please note that this is a bit field and not a value
 *               and treat it accordingly.
 *
 *   RETURN
 *      The return is either one of the SHFMT_* values, or if the
 *      returned DWORD value is not == to one of these values, then
 *      the return is the physical format ID of the last succesful
 *      format. The LOWORD of this value can be passed on subsequent
 *      calls as the fmtID parameter to "format the same type you did
 *      last time".
 *
 *)

function SHFormatDrive(wnd: HWND; drive: UINT; fmtId: UINT;
  options: UINT): dword; stdcall;

//
// Special value of fmtID which means "use the default format"
//
const
  SHFMT_ID_DEFAULT    = $FFFF;

//
// Option bits for options parameter
//
  SHFMT_OPT_FULL      = $0001;
  SHFMT_OPT_SYSONLY   = $0002;

//
// Special return values. PLEASE NOTE that these are DWORD values.
//
  SHFMT_ERROR         = $FFFFFFFF;     // Error on last format, drive may be formatable
  SHFMT_CANCEL        = $FFFFFFFE;     // Last format was canceled
  SHFMT_NOFORMAT      = $FFFFFFFD;     // Drive is not formatable



(********************************
	Shell_NotifyIcon
********************************)
type
  PNotifyIconDataA = ^TNotifyIconDataA;
  PNotifyIconDataW = ^TNotifyIconDataW;
  PNotifyIconData = PNotifyIconDataA;
  {$EXTERNALSYM _NOTIFYICONDATAA}
  _NOTIFYICONDATAA = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array[0..127]of AnsiChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..255]of AnsiChar;
    case integer of
      0: (uTimeout: UINT);
      1: (uVersion: UINT;
          szInfoTitle: array[0..63]of AnsiChar;
          dwInfoFlags: DWORD;
          guidItem : TGuid;
         )
  end;
  {$EXTERNALSYM _NOTIFYICONDATAW}
  _NOTIFYICONDATAW = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array[0..127]of WideChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..255]of WideChar;
    case integer of
      0: (uTimeout: UINT);
      1: (uVersion: UINT;
          szInfoTitle: array[0..63]of WideChar;
          dwInfoFlags: DWORD;
          guidItem : TGuid;
         )
  end;
  {$EXTERNALSYM _NOTIFYICONDATA}
  _NOTIFYICONDATA = _NOTIFYICONDATAA;
  TNotifyIconDataA = _NOTIFYICONDATAA;
  TNotifyIconDataW = _NOTIFYICONDATAW;
  TNotifyIconData = TNotifyIconDataA;
  {$EXTERNALSYM NOTIFYICONDATAA}
  NOTIFYICONDATAA = _NOTIFYICONDATAA;
  {$EXTERNALSYM NOTIFYICONDATAW}
  NOTIFYICONDATAW = _NOTIFYICONDATAW;
  {$EXTERNALSYM NOTIFYICONDATA}
  NOTIFYICONDATA = NOTIFYICONDATAA;

const
  {$EXTERNALSYM NOTIFYICONDATAA_V1_SIZE}
  NOTIFYICONDATAA_V1_SIZE = 88;
  {$EXTERNALSYM NOTIFYICONDATAW_V1_SIZE}
  NOTIFYICONDATAW_V1_SIZE = 152;
  {$EXTERNALSYM NOTIFYICONDATA_V1_SIZE}
  NOTIFYICONDATA_V1_SIZE  = NOTIFYICONDATAA_V1_SIZE;
  {$EXTERNALSYM NOTIFYICONDATAA_V2_SIZE}
  NOTIFYICONDATAA_V2_SIZE = sizeof(NOTIFYICONDATAA) - (sizeof(TGUID));
  {$EXTERNALSYM NOTIFYICONDATAW_V2_SIZE}
  NOTIFYICONDATAW_V2_SIZE = sizeof(NOTIFYICONDATAW) - (sizeof(TGUID));
  {$EXTERNALSYM NOTIFYICONDATA_V2_SIZE}
  NOTIFYICONDATA_V2_SIZE  = NOTIFYICONDATAA_V2_SIZE;

  {$EXTERNALSYM NIN_SELECT}
  NIN_SELECT     = WM_USER + 0;
  {$EXTERNALSYM NINF_KEY}
  NINF_KEY       = $01;
  {$EXTERNALSYM NIN_KEYSELECT}
  NIN_KEYSELECT  = NIN_SELECT or NINF_KEY;
  {$EXTERNALSYM NIN_BALLOONSHOW}
  NIN_BALLOONSHOW      = WM_USER + 2;
  {$EXTERNALSYM NIN_BALLOONHIDE}
  NIN_BALLOONHIDE      = WM_USER + 3;
  {$EXTERNALSYM NIN_BALLOONTIMEOUT}
  NIN_BALLOONTIMEOUT   = WM_USER + 4;
  {$EXTERNALSYM NIN_BALLOONUSERCLICK}
  NIN_BALLOONUSERCLICK = WM_USER + 5;

  {$EXTERNALSYM NIM_SETFOCUS}
  NIM_SETFOCUS    = $00000003;
  {$EXTERNALSYM NIM_SETVERSION}
  NIM_SETVERSION  = $00000004;
  {$EXTERNALSYM NOTIFYICON_VERSION}
  NOTIFYICON_VERSION = 3;

  {$EXTERNALSYM NIF_STATE}
  NIF_STATE       = $00000008;
  {$EXTERNALSYM NIF_INFO}
  NIF_INFO        = $00000010;
  {$EXTERNALSYM NIF_GUID}
  NIF_GUID        = $00000020;
  {$EXTERNALSYM NIS_HIDDEN}
  NIS_HIDDEN       = $00000001;
  {$EXTERNALSYM NIS_SHAREDICON}
  NIS_SHAREDICON   = $00000002;
  // says this is the source of a shared icon
  // Notify Icon Infotip flags
  {$EXTERNALSYM NIIF_NONE}
  NIIF_NONE        = $00000000;
  // icon flags are mutualy exclusive
  // and take only the lowest 2 bits
  {$EXTERNALSYM NIIF_INFO}
  NIIF_INFO        = $00000001;
  {$EXTERNALSYM NIIF_WARNING}
  NIIF_WARNING     = $00000002;
  {$EXTERNALSYM NIIF_ERROR}
  NIIF_ERROR       = $00000003;
  {$EXTERNALSYM NIIF_ICON_MASK}
  NIIF_ICON_MASK   = $0000000F;
  {$EXTERNALSYM NIIF_NOSOUND}
  NIIF_NOSOUND     = $00000010;


(********************************
	SHGetFileInfo
********************************)
const
  {$EXTERNALSYM SHGFI_ADDOVERLAYS}
  SHGFI_ADDOVERLAYS       = $000000020;     // apply the appropriate overlays
  {$EXTERNALSYM SHGFI_OVERLAYINDEX}
  SHGFI_OVERLAYINDEX      = $000000040;     // Get the index of the overlay

  {$EXTERNALSYM SHGNLI_NOLNK}
  SHGNLI_NOLNK            = $000000008;     // don't add ".lnk" extension


implementation

const
  shell32 = 'shell32.dll';

function SHQueryRecycleBinA; external shell32 name 'SHQueryRecycleBinA';
function SHQueryRecycleBinW; external shell32 name 'SHQueryRecycleBinW';
function SHQueryRecycleBin; external shell32 name 'SHQueryRecycleBinA';
function SHEmptyRecycleBinA; external shell32 name 'SHEmptyRecycleBinA';
function SHEmptyRecycleBinW; external shell32 name 'SHEmptyRecycleBinW';
function SHEmptyRecycleBin; external shell32 name 'SHEmptyRecycleBinA';
function SHFormatDrive; external shell32 name 'SHFormatDrive';

end.