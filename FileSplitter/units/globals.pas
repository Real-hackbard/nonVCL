unit globals;

interface

uses
  Windows,
  Messages;

const
  FontName          = 'Tahoma';
  FontSize          = -18;

  APPNAME           = 'File Splitter';

  INFO_TEXT         = APPNAME + ' %s' + #13#10 + '%s' + #13#10#13#10 +
    'Copyright © Your Name' + #13#10#13#10 +
    'https://github.com';

const
  IDC_LBLFILETOSPLIT = 102;
  IDC_EDTFILETOSPLIT = 103;
  IDC_BTNOPENSPLITFILE = 105;
  IDC_LBLTARGETFOLDER = 106;
  IDC_EDTTARGETFOLDER = 107;
  IDC_BTNSELFOLDER  = 108;
  IDC_CHKCOPYTODISK = 109;
  IDC_EDTFILESIZE   = 110;
  IDC_OPT_SIZE      = 130;
  IDC_OPT_PARTS     = 117;
  IDC_UDPARTS = 104;
  IDC_EDT_PARTS     = 131;
  IDC_EDT_SIZE      = 116;
  IDC_BTNSPLIT      = 115;
  IDC_BTNCANCEL     = 126;

  IDC_BTNABOUT      = 124;
  IDC_BTNHELP       = 129;

  IDC_STCSTATUSWND  = 101;

const
  FSM_PROGRESS      = WM_USER + 1974; // wParam: Progress [%], lParam: Filename
  FSM_FINISH        = WM_USER + 1975; // wParam: 0, lParam: Last error

const
  MYREGKEY          = 'Software\MichaelPuff\FileSplitter';

var
  { general variables }
  hApp              : HWND;
  { GUI variables }
  whitebrush        : HBRUSH = 0;
  WhiteLB           : TLogBrush =
    (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

  bRunning          : Integer = 1; // running: 1, stopped: 0
  FileToSplit       : string;
  TargetDir         : string;
  FileSize          : Int64 = 0;
  SizeOfParts       : Int64 = 0;
  CountParts        : Int64 = 0;
  Files             : array of string;
  PrevFile          : string = '';
  Idx               : Integer = 0;

resourcestring
  rsChooseFolder    = 'Wählen sie ein Zielverzeichnis aus.';
  rsFileNotExists   = 'Datei existiert nicht';
  rsFolderNotExists = 'Ordner exsitiert nicht';

implementation

end.

