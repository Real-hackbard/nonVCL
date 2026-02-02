{$DEFINE WIN_XP_DEBUG}

program VistaOpFav;

uses
  Windows,
  Messages,
  ShlObj,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  MSysUtils in 'MSysUtils.pas',
  fldbrows;

{$R VistaOpFav-en.res}
{$R VistaOpFav-de.res}
{$R manifest.res}


const
  // dialogs
  IDD_OPVERDLG        = 200;
  IDD_SAVEPATHDLG     = 300;
  IDD_CONVERTDLG      = 400;

  // controls
  IDC_OPERA3          = 210;
  IDC_OPERA35         = 211;
  IDC_OPERA5          = 212;
  IDC_OPERA6          = 213;
  IDC_SAVEEDIT        = 310;
  IDC_SAVEFOLDERBTN   = 320;
  IDC_ACTIONTEXT      = 420;

  // String resources
  IDS_TITLE           = 2000;
  IDS_VISTAONLY       = 2001;
  IDS_NEXT            = 2002;
  IDS_CONVERT         = 2003;
  IDS_SELECTFOLDER    = 2004;

  // supported files
  szHotlistFiles      : array[IDC_OPERA3..IDC_OPERA6]of string =
    ('Opera.adr', 'Opera3.adr', 'Opera5.adr', 'Opera6.adr');

// shared resources
var
  hTitleFont          : HFONT   = 0;
  OperaVersion        : integer = IDC_OPERA6;
  DestinationFile     : string  = '';

  
//
// GetResourceString
//
function GetResourceString(uId: UINT): string;
begin
  SetLength(Result, MAX_PATH);
  SetLength(Result, LoadString(hInstance, uId, @Result[1], length(Result)));
end;

function GetResourceStringW(uId: UINT): WideString;
begin
  SetLength(Result, MAX_PATH * 2);
  SetLength(Result, LoadStringW(hInstance, uId, @Result[1], length(Result)));
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
    if(SHGetPathFromIdList(lpItemId,buf)) then
    begin
      Result := string(buf);

      while(Result[length(Result)] = '\') do
        SetLength(Result,length(Result)-1);
    end;
end;

//
// create Hotlist file
//
function GoAhead(const hwndActionText: HWND): boolean;
var
  opf         : TextFile;
  szFavFolder : string;

  procedure scanPath(const s : string);
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
      while(res <> ERROR_NO_MORE_FILES) do
      begin
        // update label
        SetWindowText(hwndActionText,pchar(ds.cFileName +
          ' -> ' + dummy));

        if(ds.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and
          ((lstrcmp(ds.cFileName,'.') <> 0) and
           (lstrcmp(ds.cFileName,'..') <> 0)) then
        begin
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
          scanPath(s);
        end
        else begin
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

        if(not(FindNextFile(res, ds))) then break;
      end;
    finally
      FindClose(res);
    end;

    // End-sign for Opera
    WriteLn(opf,'-');

    // one level up!
    if(path <> s) then ChDir('..'); // 1 level up
  end;

begin
  Result      := false;
  szFavFolder := GetSpecialPath(CSIDL_FAVORITES);
  if(DestinationFile  = '') or
    (szFavFolder = '') then exit;

  {$I+}
  ChDir     (szFavFolder);
  if(IoResult = 0) then
  begin
    AssignFile(opf, DestinationFile + '\' + szHotlistFiles[OperaVersion]);
    ReWrite   (opf);
    WriteLn   (opf, 'Opera Hotlist version 2.0' + #13#10);
    scanPath  (szFavFolder);
    CloseFile (opf);
  end;

  Result := (IoResult = 0);
  {$I+}

  SetWindowText(hWndActionText, nil);
end;


// -- Wizard dialog procedures -------------------------------------------------

function SelectOpVerDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
begin
  Result := false;

  case uMsg of
    WM_COMMAND:
      if HIWORD(wp) = BN_CLICKED then
        case LOWORD(wp) of
          IDC_OPERA3,
          IDC_OPERA35,
          IDC_OPERA5,
          IDC_OPERA6:
            begin
              OperaVersion := LOWORD(wp);
              PropSheet_SetCurSelbyID(hwndDlg, 300);
            end;
        end;
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          begin
            PropSheet_SetWizButtons(hwndDlg, 0);
            PropSheet_ShowWizButtons(hwndDlg, PSWIZB_CANCEL,
              PSWIZB_CANCEL or PSWIZB_NEXT);
          end;
      end;
  end;
end;

function DestPathDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
var
  fl       : TFolderBrowser;
begin
  Result := false;

  case uMsg of
    WM_INITDIALOG:
      DestinationFile := GetSpecialPath(CSIDL_PERSONAL);
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) and
        (LOWORD(wp) = IDC_SAVEFOLDERBTN) then
      begin
        fl := TFolderBrowser.Create(hwndDlg,
          GetResourceString(IDS_SELECTFOLDER), DestinationFile);
        if fl <> nil then
        try
          if fl.Execute then
          begin
            DestinationFile := fl.SelectedItem;
            if(DestinationFile[length(DestinationFile)] = '\') then
              SetLength(DestinationFile,length(DestinationFile)-1);
            SetDlgItemText(hwndDlg, IDC_SAVEEDIT, pointer(DestinationFile +
              '\' + szHotlistFiles[OperaVersion]));
          end;
        finally
          fl.Free;
        end;
      end;
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          begin
            // enable Back and Next buttons
            PropSheet_SetWizButtons(hwndDlg, PSWIZB_BACK or PSWIZB_NEXT);
            PropSheet_SetNextText(hwndDlg, pwidechar(GetResourceStringW(IDS_NEXT)));

            // show file name
            if(DestinationFile[length(DestinationFile)] = '\') then
              SetLength(DestinationFile,length(DestinationFile)-1);
            SetDlgItemText(hwndDlg,IDC_SAVEEDIT,
              pointer(DestinationFile + '\' + szHotlistFiles[OperaVersion] ));
          end;
      end;
  end;
end;

function ConvertDlgProc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM):
  bool; stdcall;
begin
  Result := false;

  case uMsg of
    WM_NOTIFY:
      case PNMHdr(lp)^.code of
        PSN_SETACTIVE:
          begin
            PropSheet_SetWizButtons(hwndDlg, PSWIZB_NEXT or PSWIZB_BACK);
            PropSheet_SetNextText(hwndDlg, pwidechar(GetResourceStringW(IDS_CONVERT)));
          end;
        PSN_WIZNEXT:
          begin
            // disable custom buttons
            PropSheet_SetWizButtons(hwndDlg, 0);

            // convert
            GoAhead(GetDlgItem(hwndDlg, IDC_ACTIONTEXT));

            // show Cancel button only!
            PropSheet_ShowWizButtons(hwndDlg, PSWIZB_CANCEL,
              PSWIZB_CANCEL or PSWIZB_NEXT);
          end;
      end;
  end;
end;


//
// WinMain
//
const
  szUniqueId = 'VistaOpFavWnd_E9A440E0FA8111D7A488B5A9825F5053';
var
  hm         : THandle;
  psp        : TPropSheetPageW;
  ahpsp      : array[0..2]of HPROPSHEETPAGE;
  psh        : TPropSheetHeaderW;
begin
{$IFNDEF WIN_XP_DEBUG}
  if not IsWindowsVista then
  begin
    MessageBoxW(0, pwidechar(GetResourceStringW(IDS_VISTAONLY)), nil,
      MB_ICONWARNING);
    exit;
  end;
{$ENDIF}

  hm                    := CreateSemaphore(nil,0,1,szUniqueId);
  if(GetLastError = ERROR_ALREADY_EXISTS) then
    exit;

  //
  // create the Wizard pages
  //
  ZeroMemory(@psp, sizeof(psp));
  psp.dwSize            := sizeof(psp);
  psp.hInstance         := hInstance;
  psp.pszTemplate       := MAKEINTRESOURCEW(IDD_OPVERDLG);
  psp.pfnDlgProc        := @SelectOpVerDlgProc;
  ahpsp[0]              := CreatePropertySheetPageW(psp);

  psp.pszTemplate       := MAKEINTRESOURCEW(IDD_SAVEPATHDLG);
  psp.pfnDlgProc        := @DestPathDlgProc;
  ahpsp[1]              := CreatePropertySheetPageW(psp);

  psp.pszTemplate       := MAKEINTRESOURCEW(IDD_CONVERTDLG);
  psp.pfnDlgProc        := @ConvertDlgProc;
  ahpsp[2]              := CreatePropertySheetPageW(psp);

  //
  // create the Property sheet
  //
  ZeroMemory(@psh,sizeof(psh));
  psh.dwSize            := sizeof(psh);
  psh.dwFlags           := PSH_AEROWIZARD or PSH_WIZARD;
  psh.hInstance         := hInstance;
  psh.hwndParent        := 0;
  psh.phpage            := @ahpsp[0];
  psh.nPages            := length(ahpsp);
  psh.nStartPage        := 0;
  psh.pszCaption        := pwidechar(GetResourceStringW(IDS_TITLE));

  // display the wizard
  PropertySheetW(psh);

  CloseHandle(hm);
end.
