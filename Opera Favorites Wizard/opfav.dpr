program opfav;

uses
  Windows,
  Messages,
  ShlObj,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  MSysUtils in 'MSysUtils.pas';

{$R wizard.res}


const
  // dialogs
  IDD_INTRODLG        = 100;
  IDD_OPVERDLG        = 200;
  IDD_SAVEPATHDLG     = 300;
  IDD_FINISHDLG       = 400;
  IDD_PROGRESSDLG     = 500;

  // controls
  IDC_INTROTITLE      = 110;
  IDC_OPERA3          = 210;
  IDC_OPERA35         = 211;
  IDC_OPERA5          = 212;
  IDC_OPERA6          = 213;
  IDC_SAVEEDIT        = 310;
  IDC_SAVEFOLDERBTN   = 320;
  IDC_FINISHTITLE     = 410;
  IDC_ACTIONTEXT      = 510;
  IDC_PROGRESS        = 511;

  // strings
  IDS_P1TITLE         = 2000;
  IDS_P1SUBTITLE      = 2001;
  IDS_P2TITLE         = 2010;
  IDS_P2SUBTITLE      = 2011;

  // bitmaps
  IDB_WATERMARKBMP    = 1000;
  IDB_HEADERBMP       = 1010;

  // supported files
  szHotlistFiles      : array[IDC_OPERA3..IDC_OPERA6]of string =
    ('Opera.adr','Opera3.adr','Opera5.adr','Opera6.adr');

// shared resources
var
  hTitleFont          : HFONT   = 0;
  iOpVer              : integer = IDC_OPERA6;
  szDestFile          : string  = '';

  
//
// GetResourceString
//
function GetResourceString(uId: UINT): string;
begin
  SetLength(Result, MAX_PATH);
  SetLength(Result, LoadString(hInstance, uId, @Result[1], length(Result)));
end;


//
// get special path
//
function GetSpecialPath(PathID: integer): string;
var
  lpItemId : PItemIdList;
  buf      : array[0..MAX_PATH]of char;
begin
  Result := '';

  if(SHGetSpecialFolderLocation(0,PathId,lpItemId) = NOERROR) then
    if(SHGetPathFromIdList(lpItemId,buf)) then begin
      Result := string(buf);

      while(Result[length(Result)] = '\') do
        SetLength(Result,length(Result)-1);
    end;
end;

//
// create Hotlist file
//
function GoAhead(const hwndPB, hwndActionText: HWND): boolean;
var
  opf         : TextFile;
  szFavFolder : string;
  pMax,
  pCurrent    : integer;

  procedure scanPath(const s : string; hLabel, hPB: HWND);
  var
    path  : string;
    ds    : TWin32FindData;
    res   : cardinal;
    dummy : array[0..MAX_PATH]of char;
  begin
    GetDir(0,path);

    res := FindFirstFile(pchar(path + '\*.*'),ds);
    if(res <> INVALID_HANDLE_VALUE) then
    try
      while(res <> ERROR_NO_MORE_FILES) do begin
            // update label
            SetWindowText(hLabel,pchar(ds.cFileName +
              ' -> ' + dummy));


        if(ds.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
          ((lstrcmp(ds.cFileName,'.') <> 0) and
           (lstrcmp(ds.cFileName,'..') <> 0)) then
        begin
          inc(pMax);

          // write current folder to "opf" file
          WriteLn(opf,'#FOLDER');
          WriteLn(opf,#9 + 'NAME=' + ds.cFileName);
          WriteLn(opf,#9 + 'CREATED=' +
            inttostr(MAKELONG(ds.ftCreationTime.dwLowDateTime,
            ds.ftCreationTime.dwHighDateTime)));
          WriteLn(opf,#9 + 'VISITED=0');
          WriteLn(opf,#9 + 'ORDER=0');
          WriteLn(opf,#9 + 'DESCRIPTION=');
          WriteLn(opf,#9 + 'SHORT NAME=');
          WriteLn(opf,#9 + '');

          // jump into it, & scan again
          ChDir(ds.cFilename);
          scanPath(s,hLabel,hPB);
        end else begin
          // open .URL file
          ZeroMemory(@dummy,sizeof(dummy));

          // write to hotlist
          if(GetPrivateProfileString('InternetShortcut','URL',nil,
            dummy,MAX_PATH,
            pchar(path + '\' + ds.cAlternateFileName)) > 0) then
          begin
            WriteLn(opf,'#URL');
            WriteLn(opf,#9 + 'NAME=' + CutFileExt(ds.cFileName));
            WriteLn(opf,#9 + 'URL=' + dummy);
            WriteLn(opf,#9 + 'CREATED=' +
              inttostr(MAKELONG(ds.ftCreationTime.dwLowDateTime,
              ds.ftCreationTime.dwHighDateTime)));
            WriteLn(opf,#9 + 'VISITED=0');
            WriteLn(opf,#9 + 'ORDER=0');
            WriteLn(opf,#9 + 'DESCRIPTION=');
            WriteLn(opf,#9 + 'SHORT NAME=');
            WriteLn(opf,#9 + '');
          end;
        end;

        if(not(FindNextFile(res,ds))) then break;
      end;
    finally
      FindClose(res);
    end;

    // End-sign for Opera
    WriteLn(opf,'-');

    // update progressbar
    SendMessage(hPB,PBM_SETPOS,MulDiv(pCurrent,100,pMax),pMax);
    inc(pCurrent);

    // one level up!
    if(path <> s) then ChDir('..'); // 1 level up
  end;

begin
  Result      := false;
  szFavFolder := GetSpecialPath(CSIDL_FAVORITES);
  if(szDestFile  = '') or
    (szFavFolder = '') then exit;

  pMax        := 0;
  pCurrent    := 0;

  // this application covers your favorites ;o)
  {$I+}
  ChDir     (szFavFolder);
  if(IoResult = 0) then begin
    AssignFile(opf,szDestFile + '\' + szHotlistFiles[iOpVer]);
    ReWrite   (opf);
    WriteLn   (opf,'Opera Hotlist version 2.0' + #13#10);
    scanPath  (szFavFolder,hwndActionText,hwndPB);
    CloseFile (opf);
  end;

  Result := (IoResult = 0);
  {$I+}
end;


// -- Wizard dialog procedures -------------------------------------------------

function IntroDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
begin
  Result := false;

  case uMsg of
    WM_INITDIALOG:
      SendDlgItemMessage(hwndDlg,IDC_INTROTITLE,WM_SETFONT,
      WPARAM(hTitleFont),LPARAM(true));
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          // enable Next button
          PropSheet_SetWizButtons(GetParent(hwndDlg),PSWIZB_NEXT);
      end;
  end;
end;

function SelectOpVerDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
var
  i : integer;
begin
  Result := false;

  case uMsg of
    WM_INITDIALOG:
      begin
        // pre-select default Opera version
        SendDlgItemMessage(hwndDlg,iOpVer,BM_SETCHECK,BST_CHECKED,0);
      end;
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          // enable Back and Next buttons
          PropSheet_SetWizButtons(GetParent(hwndDlg),
            PSWIZB_BACK or PSWIZB_NEXT);
        PSN_WIZNEXT:
          // what Opera version is selected?
          for i := 210 to 213 do
            if(SendDlgItemMessage(hwndDlg,i,BM_GETCHECK,0,0) =
              BST_CHECKED) then
            begin
              iOpVer := i;
              break;
            end;
      end;
  end;
end;

function DestPathDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
var
  bi       : TBrowseInfo;
  lpItemId : PItemIdList;
  p        : array[0..MAX_PATH]of char;
begin
  Result := false;

  case uMsg of
    WM_INITDIALOG:
      begin
        // get "My Documents" path
        szDestFile := GetSpecialPath(CSIDL_PERSONAL);
      end;
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) and
        (LOWORD(wp) = IDC_SAVEFOLDERBTN) then
      begin
        // use SHBrowseForFolder
        ZeroMemory(@bi,sizeof(bi));
        bi.hwndOwner := hwndDlg;
        bi.lpszTitle := 'Select destination folder';

        // get new path, & build new filename
        lpItemId     := SHBrowseForFolder(bi);
        if(lpItemId <> nil) then begin
          ZeroMemory(@p,sizeof(p));
          if(SHGetPathFromIdList(lpItemid,p)) then
            szDestFile := string(p);

          // show file name
          if(szDestFile[length(szDestFile)] = '\') then
            SetLength(szDestFile,length(szDestFile)-1);
          SetDlgItemText(hwndDlg,IDC_SAVEEDIT,
            pointer(szDestFile + '\' + szHotlistFiles[iOpVer]));
        end;
      end;
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          begin
            // enable Back and Next buttons
            PropSheet_SetWizButtons(GetParent(hwndDlg),
              PSWIZB_BACK or PSWIZB_NEXT);

            // show file name
            if(szDestFile[length(szDestFile)] = '\') then
              SetLength(szDestFile,length(szDestFile)-1);
            SetDlgItemText(hwndDlg,IDC_SAVEEDIT,
              pointer(szDestFile + '\' + szHotlistFiles[iOpVer] ));
          end;
      end;
  end;
end;


function progressdlg(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
begin
  if(uMsg = WM_INITDIALOG) then begin
    SetDlgItemText(hwndDlg,IDC_ACTIONTEXT,nil);
    Result := true;
  end else
    Result := false;
end;

function EndDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
var
  hDlg : HWND;
begin
  Result   := false;

  case uMsg of
    WM_INITDIALOG:
      // set title font
      SendDlgItemMessage(hwndDlg,IDC_FINISHTITLE,WM_SETFONT,
        WPARAM(hTitleFont),LPARAM(true));
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          // enable Back and Finish buttons
          PropSheet_SetWizButtons(GetParent(hwndDlg),
            PSWIZB_BACK or PSWIZB_FINISH);
        PSN_WIZFINISH:
          // Finish pressed
          begin
            hDlg     := CreateDialog(hInstance,
              MAKEINTRESOURCE(IDD_PROGRESSDLG),hwndDlg,@progressdlg);

            if(szDestFile <> '') then GoAhead(GetDlgItem(hDlg,IDC_PROGRESS),
              GetDlgItem(hDlg,IDC_ACTIONTEXT));

            // Enable progress dialog
            DestroyWindow(hDlg);
          end;
      end;
  end;
end;


// -- MAIN ---------------------------------------------------------------------


const
  szUniqueId            = 'OpFavWnd_E9A440E0FA8111D7A488B5A9825F5053';
var
  hm                    : THandle;
  psp                   : TPropSheetPage;
  ahpsp                 : array[0..3]of HPROPSHEETPAGE;
  psh                   : TPropSheetHeader;
  ncm                   : NonClientMetrics;
  TitleFont             : TLogFont;
  dc                    : HDC;
  iFontSize             : integer;
begin
  // only 1 instance is allowed
  hm                    := CreateSemaphore(nil,0,1,szUniqueId);
  if(GetLastError = ERROR_ALREADY_EXISTS) then
    exit;

  //
  // create the Wizard pages
  //

  // opening titles
  psp.dwSize            := sizeof(psp);
  psp.dwFlags           := PSP_DEFAULT or PSP_HIDEHEADER;
  psp.hInstance         := hInstance;
  psp.pfnDlgProc        := @IntroDlgProc;
  psp.pszTemplate       := MAKEINTRESOURCE(IDD_INTRODLG);
  ahpsp[0]              := CreatePropertySheetPage(psp);

  // 1st page (select Opera version)
  psp.dwFlags           := PSP_DEFAULT or PSP_USEHEADERTITLE or
    PSP_USEHEADERSUBTITLE;
  psp.pszHeaderTitle    := MAKEINTRESOURCE(IDS_P1TITLE);
  psp.pszHeaderSubTitle := MAKEINTRESOURCE(IDS_P1SUBTITLE);
  psp.pszTemplate       := MAKEINTRESOURCE(IDD_OPVERDLG);
  psp.pfnDlgProc        := @SelectOpVerDlgProc;
  ahpsp[1]              := CreatePropertySheetPage(psp);

  // 2nd page (select destination folder)
  psp.dwFlags           := PSP_DEFAULT or PSP_USEHEADERTITLE or
    PSP_USEHEADERSUBTITLE or PSP_HASHELP;
  psp.pszHeaderTitle    := MAKEINTRESOURCE(IDS_P2TITLE);
  psp.pszHeaderSubTitle := MAKEINTRESOURCE(IDS_P2SUBTITLE);
  psp.pszTemplate       := MAKEINTRESOURCE(IDD_SAVEPATHDLG);
  psp.pfnDlgProc        := @DestPathDlgProc;
  ahpsp[2]              := CreatePropertySheetPage(psp);

  // final page
  psp.dwFlags           := PSP_DEFAULT or PSP_HIDEHEADER;
  psp.pszTemplate       := MAKEINTRESOURCE(IDD_FINISHDLG);
  psp.pfnDlgProc        := @EndDlgProc;
  ahpsp[3]              := CreatePropertySheetPage(psp);


  // set up font for title (Intro, & Ending pages)
  ncm.cbSize            := sizeof(ncm);
  SystemParametersInfo(SPI_GETNONCLIENTMETRICS,0,@ncm,0);

  TitleFont             := ncm.lfMessageFont;
  TitleFont.lfWeight    := FW_BOLD;
  dc                    := GetDC(0);
  iFontSize             := 12;
  TitleFont.lfHeight    := 0 - GetDeviceCaps(dc,LOGPIXELSY) *
    (iFontSize div 72);
  hTitleFont            := CreateFontIndirect(TitleFont);
  ReleaseDC(0,dc);


  //
  // create the Property sheet
  //
  ZeroMemory(@psh,sizeof(psh));
  psh.dwSize            := sizeof(psh);
  psh.hInstance         := hInstance;
  psh.hwndParent        := 0;
  psh.phpage            := @ahpsp[0];
  psh.nStartPage        := 0;
  psh.nPages            := length(ahpsp);
  psh.pszbmWatermark    := MAKEINTRESOURCE(IDB_WATERMARKBMP);
  psh.pszbmHeader       := MAKEINTRESOURCE(IDB_HEADERBMP);
  psh.dwFlags           := PSH_WIZARD97 or PSH_WATERMARK or PSH_HEADER;

  // display the wizard
  PropertySheet(psh);

  // delete font
  DeleteObject(hTitleFont);

  CloseHandle(hm);
end.
