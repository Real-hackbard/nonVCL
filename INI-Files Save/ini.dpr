program ini;

uses
  Windows,
  Messages,
  MSysUtils in 'MSysUtils.pas';

{$R dialog.res}

const
  IDC_NAMELIST    = 110;
  IDC_LOCATION    = 120;
  IDC_AGE         = 130;
  IDC_NEWNAME     = 140;
  IDC_NEWLOCATION = 150;
  IDC_NEWAGE      = 160;
  IDC_ADDUSER     = 170;
  IDC_SHOWALL     = 180;
  IDC_ALLSECTIONS = 190;
  IDC_DELUSER     = 200;

const
  BUFSIZE   = 65535;
  szNameKey = 'names';
  szIniFile = 'userdata.ini';

function Load_IniNames(const hCombobox: HWND): integer;
var
  buf,
  p         : pchar;
  kl        : array of string;
  i         : integer;
begin
  // Combobox clera
  SendMessage(hCombobox,CB_RESETCONTENT,0,0);

  // Reading topic names from the INI file
  SetLength(kl,0);

  GetMem(buf,BUFSIZE);
  try
    if(GetPrivateProfileString(szNameKey,nil,nil,buf,BUFSIZE,
      pchar(ExtractFilePath(paramstr(0)) + szIniFile)) <> 0) then
    begin
      p := buf;
      while(p^ <> #0) do begin
        SetLength(kl,length(kl)+1);
        kl[length(kl)-1] := p;

        inc(p,lstrlen(p)+1);
      end;
    end;
  finally
    FreeMem(buf,BUFSIZE);
  end;

  // Function result
  Result := length(kl);

  // Read values ??from the INI file and enter them into the combobox.
  if(length(kl) > 0) then begin
    GetMem(buf,BUFSIZE);
    try
      for i := 0 to length(kl)-1 do begin
        ZeroMemory(buf,BUFSIZE);
        if(GetPrivateProfileString(szNameKey,@kl[i][1],nil,
          buf,BUFSIZE,pchar(ExtractFilePath(paramstr(0)) + szIniFile)) > 0) then
        SendMessage(hCombobox,CB_ADDSTRING,0,LPARAM(buf));
      end;
    finally
      FreeMem(buf,BUFSIZE);
    end;

    SetLength(kl,0);
  end;

  // are there any entries?
  if(SendMessage(hCombobox,CB_GETCOUNT,0,0) > 0) then begin
    SendMessage(hCombobox,CB_SETCURSEL,0,0);
    SendMessage(GetParent(hCombobox),WM_COMMAND,
      MAKEWPARAM(IDC_NAMELIST,CBN_SELCHANGE),0);
  end;
end;

procedure Load_UserInfo(const iIndex: integer; hCombobox, hLocation, hAge: HWND);
var
  buf,
  location : pchar;
  age      : integer;
begin
  GetMem(buf,BUFSIZE);
  try
    ZeroMemory(buf,BUFSIZE);
    if(SendMessage(hCombobox,CB_GETLBTEXT,iIndex,LPARAM(buf)) > 0) then begin
      GetMem(location,BUFSIZE);
      try
        // Get your place of residence
        ZeroMemory(location,BUFSIZE);
        GetPrivateProfileString(buf,'location',nil,location,
          BUFSIZE,pchar(ExtractFilePath(paramstr(0)) + szIniFile));
        SetWindowText(hLocation,location);

        // Get old
        age := GetPrivateProfileInt(buf,'age',-1,
          pchar(ExtractFilePath(paramstr(0)) + szIniFile));
        if(age = -1) then SetWindowText(hAge,'unbekannt')
          else SetWindowText(hAge,pchar(inttostr(age)));
      finally
        FreeMem(location,BUFSIZE);
      end;
    end;
  finally
    FreeMem(buf,BUFSIZE);
  end;
end;

function Save_NewUser(const hName, hLocation, hAge: HWND): boolean;
var
  username,
  s         : string;
begin
  Result := false;

  // Prepare string buffer for names, ...
  SetLength(username,MAX_PATH);
  // ... & Read out names
  SetLength(username,GetWindowText(hName,@username[1],MAX_PATH));

  if(username <> '') then begin
    // Save name
    Result := WritePrivateProfileString(szNameKey,@username[1],@username[1],
      pchar(ExtractFilePath(paramstr(0)) + szIniFile));

    // Place of residence
    SetLength(s,MAX_PATH);
    SetLength(s,GetWindowText(hLocation,@s[1],MAX_PATH));
    Result := (Result) and WritePrivateProfileString(@username[1],'location',@s[1],
      pchar(ExtractFilePath(paramstr(0)) + szIniFile));

    // Age
    SetLength(s,MAX_PATH);
    SetLength(s,GetWindowText(hAge,@s[1],MAX_PATH));
    Result := (Result) and WritePrivateProfileString(@username[1],'age',@s[1],
      pchar(ExtractFilePath(paramstr(0)) + szIniFile));
  end;

  if(Result) then begin
    // Reset fields
    SetWindowText(hName,nil);
    SetWindowText(hLocation,nil);
    SetWindowText(hAge,nil);

    // reload
    Load_IniNames(GetDlgItem(GetParent(hName),IDC_NAMELIST));
  end;
end;

procedure Show_AllTopicsAndValues(const wnd: HWND);
var
  wv    : TOSVersionInfo;
  dwLen : dword;
  buf,
  p     : pchar;
  kl    : array of string;
  i     : integer;
begin
  // Find out Windows platform
  wv.dwOSVersionInfoSize := sizeof(TOSVersionInfo);
  GetVersionEx(wv);

  // Maximum buffer size under Win = 32k
  if(wv.dwPlatformId = VER_PLATFORM_WIN32_NT) then dwLen := BUFSIZE
    else dwLen := BUFSIZE div 2;

  // Reserve memory
  SetLength(kl,0);

  GetMem(buf,dwLen);
  try
    // Read all topics and values ??into the buffer
    ZeroMemory(buf,dwLen);
    if(GetPrivateProfileSection(szNameKey,buf,dwLen,
      pchar(ExtractFilePath(paramstr(0)) + szIniFile)) <> dwLen - 2) then
    begin
      p := buf;
      while(p^ <> #0) do begin
        SetLength(kl,length(kl)+1);
        kl[length(kl)-1] := p;

        inc(p,lstrlen(p)+1);
      end;
    end;
  finally
    FreeMem(buf,dwLen);
  end;

  // Show read topics and values
  if(length(kl) > 0) then begin
    for i := 0 to length(kl) - 1 do
      MessageBox(wnd,pchar(kl[i]),pchar(inttostr(i+1)),0);

    SetLength(kl,0);
  end;
end;

procedure Show_AllSections(const wnd: HWND);
var
  buf,
  p     : pchar;
  kl    : array of string;
  i     : integer;
begin
  // Reserve memory
  SetLength(kl,0);

  GetMem(buf,BUFSIZE);
  try
    // read all names
    ZeroMemory(buf,BUFSIZE);
    if(GetPrivateProfileSectionNames(buf,BUFSIZE,
      pchar(ExtractFilePath(paramstr(0)) + szIniFile)) <> BUFSIZE - 2) then
    begin
      p := buf;
      while(p^ <> #0) do begin
        SetLength(kl,length(kl)+1);
        kl[length(kl)-1] := p;

        inc(p,lstrlen(p)+1);
      end;
    end;
  finally
    FreeMem(buf,BUFSIZE);
  end;

  // show all names
  if(length(kl) > 0) then begin
    for i := 0 to length(kl) - 1 do
      MessageBox(wnd,pchar(kl[i]),pchar(inttostr(i+1)),0);

    SetLength(kl,0);
  end;
end;

procedure Del_User(const iIndex: integer; hCombobox : HWND);
var
  buf,
  usernames,
  p         : pchar;
  kl        : array of string;
  i         : integer;
begin
  GetMem(buf,BUFSIZE);
  try
    ZeroMemory(buf,BUFSIZE);
    if(SendMessage(hCombobox,CB_GETLBTEXT,iIndex,LPARAM(buf)) > 0) then begin
      // Remove section
      WritePrivateProfileString(buf,nil,nil,
        pchar(ExtractFilePath(paramstr(0)) + szIniFile));

      // Find a topic name that matches the person
      SetLength(kl,0);

      GetMem(usernames,BUFSIZE);
      try
        if(GetPrivateProfileString(szNameKey,nil,nil,usernames,BUFSIZE,
          pchar(ExtractFilePath(paramstr(0)) + szIniFile)) <> 0) then
        begin
          p := usernames;
          while(p^ <> #0) do begin
            SetLength(kl,length(kl)+1);
            kl[length(kl)-1] := p;

            inc(p,lstrlen(p)+1);
          end;
        end;
      finally
        FreeMem(usernames,BUFSIZE);
      end;

      if(length(kl) > 0) then begin
        GetMem(usernames,BUFSIZE);
        try
          for i := 0 to length(kl)-1 do begin
            ZeroMemory(usernames,BUFSIZE);
            if(GetPrivateProfileString(szNameKey,@kl[i][1],nil,
              usernames,BUFSIZE,pchar(ExtractFilePath(paramstr(0)) + szIniFile)) > 0) and
              (lstrcmp(usernames,buf) = 0) then
            begin
              // Topic found, & delete
              WritePrivateProfileString(szNameKey,usernames,nil,
                pchar(ExtractFilePath(paramstr(0)) + szIniFile));

              // Exit the loop early
              break;
            end;
          end;
        finally
          FreeMem(usernames,BUFSIZE);
        end;

        SetLength(kl,0);
      end;
    end;
  finally
    FreeMem(buf,BUFSIZE);
  end;

  // reload
  Load_IniNames(hCombobox);
end;


// ---------------------------------------------------------------------------------
//
// "dlgproc"
//
function dlgproc(hwndDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): bool; stdcall;
var
  idx : integer;
begin
  Result := true;

  case uMsg of
    WM_INITDIALOG:
      begin
        // Read existing users
        Load_IniNames(GetDlgItem(hwndDlg,IDC_NAMELIST));

        // the edits on MAX_PATH,
        // or limit the age field to 2 digits
        SendDlgItemMessage(hwndDlg,IDC_NEWNAME,EM_LIMITTEXT,MAX_PATH,0);
        SendDlgItemMessage(hwndDlg,IDC_NEWLOCATION,EM_LIMITTEXT,MAX_PATH,0);
        SendDlgItemMessage(hwndDlg,IDC_NEWAGE,EM_LIMITTEXT,2,0);
      end;
    WM_CLOSE:
      EndDialog(hwndDlg,1);
    WM_COMMAND:
      case HIWORD(wp) of
        CBN_SELCHANGE:
          if(LOWORD(wp) = IDC_NAMELIST) then begin
            idx := SendDlgItemMessage(hwndDlg,IDC_NAMELIST,CB_GETCURSEL,0,0);
            if(idx <> CB_ERR) then
              Load_UserInfo(idx,GetDlgItem(hwndDlg,IDC_NAMELIST),
                GetDlgItem(hwndDlg,IDC_LOCATION),
                GetDlgItem(hwndDlg,IDC_AGE));

            // Activate the "Delete" button?
            EnableWindow(GetDlgItem(hwndDlg,IDC_DELUSER),idx <> CB_ERR);
          end;
        BN_CLICKED:
          case LOWORD(wp) of
            IDC_ADDUSER:
              Save_NewUser(GetDlgItem(hwndDlg,IDC_NEWNAME),
                GetDlgItem(hwndDlg,IDC_NEWLOCATION),
                GetDlgItem(hwndDlg,IDC_NEWAGE));
            IDC_SHOWALL:
              Show_AllTopicsAndValues(hwndDlg);
            IDC_ALLSECTIONS:
              Show_AllSections(hwndDlg);
            IDC_DELUSER:
              begin
                idx := SendDlgItemMessage(hwndDlg,IDC_NAMELIST,CB_GETCURSEL,0,0);
                if(idx <> CB_ERR) then
                  Del_User(idx,GetDlgItem(hwndDlg,IDC_NAMELIST));
              end;
          end;
        EN_CHANGE:
          EnableWindow(GetDlgItem(hwndDlg,IDC_ADDUSER),
            (GetWindowTextLength(GetDlgItem(hwndDlg,IDC_NEWNAME)) > 0) and
            (GetWindowTextLength(GetDlgItem(hwndDlg,IDC_NEWLOCATION)) > 0) and
            (GetWindowTextLength(GetDlgItem(hwndDlg,IDC_NEWAGE)) > 0));
      end;
    else
      Result := false;
  end;
end;

begin
  DialogBox(hInstance,MAKEINTRESOURCE(100),0,@dlgproc);
end.
