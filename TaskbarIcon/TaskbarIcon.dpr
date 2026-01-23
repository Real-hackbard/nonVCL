program TaskbarIcon;

{.$DEFINE BALLONNOTIFICATION}


uses
  Windows,
  Messages,
  DllVersion in 'DllVersion.pas',
  ShellAPI,
  ShellAPI_Fragment in 'ShellAPI_Fragment.pas';

const
  szClassname   = 'TaskbarIcon';
  szCopyright   = szClassname + ', © Your Name';

  IDM_ABOUT     = 1;
  IDM_CLOSE     = 2;
  WM_TNAMSG     = WM_USER + 10;

var
  hm          : HMENU;
  p           : TPoint;
  shell32_ver : dword = 400; // Standardversion der "shell32.dll"
  dll         : DWORD = 0;
  ver         : TDllVersionInfo;
  NID         : TNotifyIconData =
    (uID:1;
     uFlags:NIF_MESSAGE or NIF_ICON or NIF_TIP;
     uCallbackMessage:WM_TNAMSG;
     hIcon:0;
     szTip:szClassname;);


function BalloonsEnabled: boolean;
const
  szBalloonPath  =
    'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced';
  szBalloonEntry = 'EnableBalloonTips';
var
  reg            : HKEY;
  res,
  lpType,
  dwSize         : dword;
begin
  // entsprechende "shell32.dll" wird vorausgesetzt
  Result := (shell32_ver >= 500);

  if(Result) then begin
    if(RegOpenKeyEx(HKEY_LOCAL_MACHINE,szBalloonPath,0,KEY_READ,
      reg) = ERROR_SUCCESS) then
    try
      lpType := REG_DWORD;
      dwSize := 4;

      // Eintrag existiert nicht, also müssen Balloon-Tipps
      // möglich sein
      Result := (RegQueryValueEx(reg,szBalloonEntry,nil,@lpType,
        @res,@dwSize) <> ERROR_SUCCESS);

      // Eintrag existiert, dann muss er "1" sein
      if(not Result) then
        Result := (dwSize = 4) and (res = 1);
    finally
      RegCloseKey(reg);
    end;
  end;
end;


//
// "WndProc"
//
function WndProc(wnd: HWND; uMsg: UINT; wp: wParam; lp: LParam): LRESULT;
  stdcall;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // Version der "shell32.dll" herausfinden
        dll := LoadLibrary('shell32.dll');
        if(dll <> 0) then begin
          DllGetVersion := GetProcAddress(dll,'DllGetVersion');
          if(@DllGetVersion <> nil) then begin
            ZeroMemory(@ver,sizeof(TDllVersionInfo));
            ver.cbSize := sizeof(TDllVersionInfo);
            if(DllGetVersion(@ver) = NOERROR) then
              shell32_ver := (ver.dwMajorVersion * 100) + ver.dwMinorVersion;
          end;

          FreeLibrary(dll);
        end;

        // abhängig von der "shell32.dll" die Recordgröße setzen!
        if(shell32_ver = 600) then NID.cbSize := sizeof(TNotifyIconData)
          else if(shell32_ver >= 500) then NID.cbSize := NOTIFYICONDATA_V2_SIZE
            else NID.cbSize := NOTIFYICONDATA_V1_SIZE;

        NID.wnd         := wnd;
        NID.hIcon       := LoadIcon(0,IDI_INFORMATION);

        // Balloon-Tipps nur ab "shell32.dll" Version 5.0
        if(shell32_ver >= 500) then begin
          if(BalloonsEnabled) then begin
            NID.uFlags      := NID.uFlags or NIF_INFO;
            NID.szInfo      := 'Ein Beispiel für einen neuen Balloon-Tipp,' +
              #13#10 + 'der auch mehrzeilig sein kann.';
            NID.szInfoTitle := szClassname;
            NID.dwInfoFlags := NIIF_INFO;
          end else
            MessageBox(wnd,'Balloon-Tipps sind bei Ihnen deaktiviert!',
            nil,MB_ICONERROR)
        end;

        Shell_NotifyIcon(NIM_ADD,@NID);
        DestroyIcon(NID.hIcon);
      end;
    WM_TNAMSG:
      case lp of
{$IFDEF BALLOONNOTIFICATION}
        NIN_BALLOONSHOW:
          MessageBox(0,'I see the balloon! :o)',szClassname,
          MB_OK or MB_ICONINFORMATION);
        NIN_BALLOONHIDE:
          MessageBox(0,'It´s gone ... :o(',szClassname,
          MB_OK or MB_ICONINFORMATION);
        NIN_BALLOONTIMEOUT:
          MessageBox(0,'KAWOOOM',szClassname,
          MB_OK or MB_ICONINFORMATION);
        NIN_BALLOONUSERCLICK:
          MessageBox(0,'U clicked the balloon',szClassname,
          MB_OK or MB_ICONINFORMATION);
{$ENDIF}
        WM_RBUTTONUP:
          begin
            hm := CreatePopupMenu;
            AppendMenu(hm,MF_STRING,IDM_ABOUT,'Information');
            AppendMenu(hm,MF_STRING,IDM_CLOSE,'Beenden');

            GetCursorPos(p);
            SetForegroundWindow(wnd);
            TrackPopupMenu(hm,TPM_RIGHTALIGN,p.X,p.Y,0,wnd,nil);

            DestroyMenu(hm);
          end;
        WM_LBUTTONDBLCLK:
          begin
            NID.hIcon := LoadIcon(0,IDI_WARNING);
            NID.szTip := 'geänderter Tooltipp-Text';

            if(shell32_ver >= 500) and (BalloonsEnabled) then begin
              NID.szInfo      := 'Hier hat sich der Balloon-Tipp geändert';
              NID.szInfoTitle := szClassname;
              NID.dwInfoFlags := NIIF_WARNING;
            end;

            Shell_NotifyIcon(NIM_MODIFY,@NID);
          end;
      end;
    WM_COMMAND:
      case wp of
        IDM_ABOUT:
          if(shell32_ver >= 500) and (BalloonsEnabled) then begin
            NID.szInfo      := szCopyright;
            NID.szInfoTitle := szClassname;
            NID.dwInfoFlags := NIIF_INFO;
            Shell_NotifyIcon(NIM_MODIFY,@NID);
          end else
            MessageBox(0,szCopyright,szClassname,
            MB_OK or MB_ICONINFORMATION);
        IDM_CLOSE:
          SendMessage(wnd,WM_CLOSE,0,0);
      end;
    WM_DESTROY:
      begin
        Shell_NotifyIcon(NIM_DELETE,@NID);
        PostQuitMessage(0);
      end;
    else
      Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;

//
// MAIN
//
var
  msg    : TMsg;
  tMutex : THandle;
  aWnd   : HWND;
  wc     : TWndClassEx =
    (cbSize:sizeof(TWndClassEx);
     Style:0;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     hIcon:0;
     hCursor:0;
     hbrBackground:0;
     lpszMenuName:nil;
     lpszClassName:szClassname;
     hIconSm:0;);

begin
  // nur eine Instanz des Programms darf aktiv sein
  tMutex := CreateMutex(nil,false,szClassname);
  if(GetLastError = ERROR_ALREADY_EXISTS) then begin
    MessageBox(0,'Die Demo läuft bereits.',szClassname,MB_OK or MB_ICONWARNING);
    Halt;
  end;

  // Fensterklasse registrieren, & Fenster erzeugen
  wc.hInstance := hInstance;
  if(RegisterClassEx(wc) = 0) then exit;

  aWnd := CreateWindowEx(0,szClassname,szClassname,
    0,0,0,0,0,0,0,hInstance,nil);
  if(aWnd = 0) then exit;

  ShowWindow(aWnd,SW_HIDE);
  UpdateWindow(aWnd);

  // Nachrichtenschleife
  while(GetMessage(msg,0,0,0)) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;

  // Mutex freigeben
  CloseHandle(tMutex);
end.