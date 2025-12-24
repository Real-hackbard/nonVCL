program EuroCalc;

uses
  windows, messages, SysUtils, ShellAPI, CommCtrl;

{$R resource.res}
{$INCLUDE GUITools.inc}
{$INCLUDE AppTools.inc}

type
  TEuro = class(TObject)
  private
    Euro, Foreign: string;
  public
    procedure ToEuro(Handle: THandle);
    procedure ToForeign(Handle: THandle);
    function ReadEuro: string;
    function ReadForeign: string;
  end;

const
  IDC_ADD = 107;
  IDC_EDIT = 108;
  IDC_DEL = 109;
  IDC_VALUTA = 110;
  IDC_EURO = 111;
  IDC_ABOUT = 112;

  IDM_RESTORE = 96;
  IDM_ABOUT = 97;
  IDM_EXIT = 98;
  IDI_TRAY = 99;

  WM_SHELLNOTIFY = WM_USER + 5;

  Path = '.\Eurocalc.ini';

  APPNAME = 'Euro-Calculator';
  VER = '1.0';
  INFO_TEXT = APPNAME + ' ' + VER + ' ' +
    'Copyright © Your Name' + #13 + #10 +
    'All rights reserved.' + #13 + #10 + #13 + #10 +
    'https://github.com/';

  FontName = 'Tahoma';
  FontSize = -18;

var
  Value: Extended;
  OldWndProc: Pointer;

  Money: TEuro;

  nid: TNotifyIconData; // TNA-Icon-Struktur

  whitebrush: HBRUSH = 0;

  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

{ *** Class TEuro *** }

function TEuro.ReadEuro: string;
begin
  result := Euro;
end;

function TEuro.ReadForeign: string;
begin
  result := Foreign;
end;

procedure TEuro.ToEuro(Handle: Cardinal);
var
  buffer: array[0..255] of Char;
  s: string;
  dblValuta, dblEuro: Single;
begin
  SendMessage(GetDlgItem(Handle, 103), WM_GETTEXT, sizeof(buffer),
    Integer(@buffer));
  s := StrPas(buffer);
  dblValuta := StrToFloat(s);
  dblEuro := dblValuta / Value;
  Euro := SysUtils.Format('%0.2n', [dblEuro]);
end;

procedure TEuro.ToForeign(Handle: Cardinal);
var
  buffer: array[0..255] of Char;
  s: string;
  dblValuta, dblEuro: Single;
begin
  SendMessage(GetDlgItem(Handle, 104), WM_GETTEXT, sizeof(buffer),
    Integer(@buffer));
  s := string(buffer);
  dblEuro := StrToFloat(s);
  dblValuta := Value * dblEuro;
  Foreign := SysUtils.Format('%0.2n', [dblValuta]);
end;

{ ***************************************************************************** }

procedure DisplayErrorMsg(hWnd: THandle);
var
  szBuffer: array[0..255] of Char;
begin
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, GetLastError(), 0, szBuffer,
    sizeof(szBuffer), nil);
  MessageBox(hWnd, szBuffer, 'Error', MB_ICONSTOP);
end;

function GetValue(buffer: PChar): string;
var
  RPos: Integer;
begin
  RPos := Length(buffer);
  while not (buffer[RPos] in [' ']) and (RPos > 0) do
    Dec(RPos);
  Result := PChar(copy(buffer, RPos + 1, MaxInt));
end;

procedure FillLB(Handle: THandle);
var
  s: string;
  buffer: array[0..255] of Char;
  f: TextFile;
begin
  SendMessage(GetDlgItem(Handle, 101), LB_RESETCONTENT, 0, 0);
  if FileExists(ExtractFilePath(ParamStr(0)) + '\Eurocalc.ini') = TRUE then
  begin
    AssignFile(f, ExtractFilePath(ParamStr(0)) + '\Eurocalc.ini');
    Reset(f);
    while not EOF(f) do
    begin
      ReadLn(f, s);
      StrPCopy(buffer, s);
      SendMessage(GetDlgItem(Handle, 101), LB_ADDSTRING, 0, Integer(@buffer));
    end;
    CloseFile(f);
  end;
end;

procedure SaveLB(Handle: THandle);
var
  i: Integer;
  s: string;
  buffer: array[0..255] of Char;
  f: TextFile;
begin
  if FileExists(ExtractFilePath(ParamStr(0)) + '\Eurocalc.ini') = TRUE then
    DeleteFile(ExtractFilePath(ParamStr(0)) + '\Eurocalc.ini');

  AssignFile(f, ExtractFilePath(ParamStr(0)) + '\Eurocalc.ini');
  Rewrite(f);
  for i := 0 to SendMessage(GetDlgItem(Handle, 101), LB_GETCOUNT, 0, 0) - 1 do
  begin
    SendMessage(GetDlgItem(Handle, 101), LB_GETTEXT, i, Integer(@buffer));
    s := StrPas(buffer);
    WriteLn(f, s);
  end;
  CloseFile(f);
end;

procedure Add(Handle: THandle);
var
  s: array[0..255] of Char;
  buffer1, buffer2: array[0..255] of Char;
begin
  SendMessage(GetDlgItem(Handle, 105), WM_GETTEXT, 255, Integer(@buffer1));
  SendMessage(GetDlgItem(Handle, 106), WM_GETTEXT, 255, Integer(@buffer2));
  if (buffer1 = '') or (buffer2 = '') then
  begin
    Messagebox(Handle, 'You must fill in both fields..', 'Error',
      MB_ICONWARNING);
    exit;
  end;

  lstrcpy(s, buffer1);
  lstrcat(s, ': ');
  lstrcat(s, buffer2);
  SendMessage(GetDlgItem(Handle, 101), LB_ADDSTRING, 0, Integer(@s));
  SendMessage(GetDlgItem(Handle, 105), WM_SETTEXT, 0, 0);
  SendMessage(GetDlgItem(Handle, 106), WM_SETTEXT, 0, 0);

  SaveLB(Handle);
  FillLB(Handle);
end;

procedure Edit(Handle: THandle);
var
  i: Integer;
  buffer1, buffer2: array[0..255] of Char;
  s: array[0..255] of Char;
begin
  i := SendMessage(GetDlgItem(Handle, 101), LB_GETCURSEL, 0, 0);
  SendMessage(GetDlgItem(Handle, 105), WM_GETTEXT, 255, Integer(@buffer1));
  SendMessage(GetDlgItem(Handle, 106), WM_GETTEXT, 255, Integer(@buffer2));

  lstrcpy(s, buffer1);
  lstrcat(s, ': ');
  lstrcat(s, buffer2);

  SendMessage(GetDlgItem(Handle, 101), LB_DELETESTRING, i, 0);
  SendMessage(GetDlgItem(Handle, 101), LB_ADDSTRING, 0, Integer(@s));

  EnableWindow(GetDlgItem(Handle, 108), FALSE);

  SaveLB(Handle);
  FillLB(Handle);
end;

procedure Del(Handle: THandle);
var
  i: Integer;
begin
  i := SendMessage(GetDlgItem(Handle, 101), LB_GETCURSEL, 0, 0);
  SendMessage(GetDlgItem(Handle, 101), LB_DELETESTRING, i, 0);
  SendMessage(GetDlgItem(Handle, 105), WM_SETTEXT, 0, 0);
  SendMessage(GetDlgItem(Handle, 106), WM_SETTEXT, 0, 0);

  SaveLB(Handle);
  FillLB(Handle);
end;

procedure GetItem(Handle: THandle);
var
  i: integer;
  buffer1, buffer2: array[0..255] of Char;
  s: string;
begin
  i := SendMessage(GetDlgItem(Handle, 101), LB_GETCURSEL, 0, 0);
  if i <> LB_ERR then
    EnableWindow(GetDlgItem(Handle, 108), TRUE);

  SendMessage(GetDlgItem(Handle, 101), LB_GETTEXT, i, Integer(@buffer1));
  lstrcpy(buffer2, buffer1);
  try
    Value := StrToFloat(GetValue(buffer1));
  except
    MessageBox(Handle, 'invalid value', 'Error', MB_ICONSTOP);
    exit;
  end;

  s := copy(StrPas(buffer1), 0, length(StrPas(buffer1)) -
    length(GetValue(buffer1)) - 1);
  StrPCopy(buffer1, s);
  SendMessage(GetDlgItem(handle, 102), WM_SETTEXT, 0, Integer(@buffer1));
  SendMessage(GetDlgItem(handle, 105), WM_SETTEXT, 0, Integer(@buffer1));

  s := copy(GetValue(buffer2), 2, length(GetValue(buffer2)));
  StrPCopy(buffer1, s);
  SendMessage(GetDlgItem(handle, 106), WM_SETTEXT, 0, Integer(@buffer1));
end;

{ Edit SubClass (Numbers only) }

function EditWndProc(hEdit, uMsg, wParam, lParam: DWORD): DWORD; stdcall;
begin
  Result := 0;
  case uMsg of
    WM_CHAR:
      case Byte(wParam) of
        Byte('0')..Byte('9'),
          Byte(','), VK_DELETE,
          VK_BACK:
          CallWindowProc(OldWndProc, hEdit, uMsg, wParam, lParam);
      end;
  else
    Result := CallWindowProc(OldWndProc, hEdit, uMsg, wParam, lParam);
  end;
end;

function dlgfunc(hWnd: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  s: string;
  MyFont: HFONT;
  buffer: array[0..255] of Char;
  iState: Integer;

  hPopup: THandle;
  pt: TPoint;
  MsgInfo: TMsgBoxParams;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        SendMessage(hWnd, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
          MAKEINTRESOURCE(1))));
        SendMessage(hWnd, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
          MAKEINTRESOURCE(1))));

        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hWnd, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));
        s := APPNAME + ' ' + VER;
        SetWindowText(hWnd, pointer(s));
        SetDlgItemText(hWnd, 999, pointer(s));

        SendMessage(GetDlgItem(hWnd, 111), BM_SETCHECK, Integer(TRUE), 0);
        EnableWindow(GetDlgItem(hWnd, 104), FALSE);

        CreateToolTips(hWnd);
        AddToolTip(hWnd, IDC_ABOUT, @ti, 'Information about the program');
        AddToolTip(hWnd, IDC_ADD, @ti, 'Adds a currency to the list');
        AddToolTip(hWnd, IDC_EDIT, @ti, 'Saves the changed entry');
        AddToolTip(hWnd, IDC_DEL, @ti,
          'Deletes the selected entry from the list.');

        OldWndProc := Pointer(SetWindowLong(GetDlgItem(hWnd, 103), GWL_WNDPROC,
          Integer(@EditWndProc)));
        OldWndProc := Pointer(SetWindowLong(GetDlgItem(hWnd, 104), GWL_WNDPROC,
          Integer(@EditWndProc)));
        OldWndProc := Pointer(SetWindowLong(GetDlgItem(hWnd, 106), GWL_WNDPROC,
          Integer(@EditWndProc)));

        FillLB(hWnd);
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          999:
            begin
              whitebrush := CreateBrushIndirect(WhiteLB);
              SetBkColor(wParam, WhiteLB.lbColor);
              result := BOOL(whitebrush);
            end;
        end;
      end;
    WM_SIZE:
      begin
        MoveWindow(GetDlgItem(hWnd, 999), 0, 0, loword(lParam), 75, TRUE);
        s := APPNAME + ' ' + VER;
        SetDlgItemText(hWnd, 999, pointer(s));
        SetWindowPos(GetDlgItem(hWnd, 112), GetDlgItem(hWnd, 999), loword(lParam)
          - 47, 7, 40, 22, 0);
        if wParam = SIZE_MINIMIZED then
        begin
          nid.cbSize := SizeOf(TNotifyIconData);
          nid.Wnd := hWnd;
          nid.uID := IDI_TRAY;
          nid.uFlags := NIF_ICON or NIF_MESSAGE or NIF_TIP;
          nid.uCallbackMessage := WM_SHELLNOTIFY;
          nid.hIcon := LoadIcon(hInstance, MAKEINTRESOURCE(1));
          lstrcpy(nid.szTip, 'EuroCalculator');
          Shell_NotifyIcon(NIM_ADD, @nid);
          ShowWindow(hWnd, SW_HIDE);
        end;
      end;
    WM_SHELLNOTIFY:
      if wParam = IDI_TRAY then
      begin
        case lParam of
          WM_LBUTTONDOWN:
            begin
              SetWindowPos(hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE
                or
                SWP_SHOWWINDOW);
              ShowWindow(hWnd, SW_RESTORE);
            end;
          WM_RBUTTONDOWN:
            begin
              GetCursorPos(pt);
            { PopupMenu }
              hPopup := CreatePopupMenu;
              AppendMenu(hPopup, MF_STRING, IDM_RESTORE, '&Show');
              AppendMenu(hPopup, MF_STRING, IDM_ABOUT, '&Info...');
              AppendMenu(hPopup, MF_SEPARATOR, 0, nil);
              AppendMenu(hPopup, MF_STRING, IDM_EXIT, '&End');
              SetForegroundWindow(hWnd);
              TrackPopupMenu(hPopup, TPM_RIGHTALIGN or TPM_RIGHTBUTTON,
                pt.x, pt.y, 0, hWnd, nil);
              PostMessage(hWnd, WM_NULL, 0, 0);
            end;
        end;
      end;
    WM_CLOSE:
      begin
        Shell_NotifyIcon(NIM_DELETE, @nid);
        EndDialog(hWnd, 0);
      end;
    WM_COMMAND:
      begin
        if HIWORD(wParam) = BN_CLICKED then
          case LOWORD(wParam) of
            IDC_ADD:
              begin
                Add(hWnd);
                SetFocus(getDlgItem(hWnd, 105));
              end;
            IDC_EDIT: Edit(hWnd);
            IDC_DEL:
              begin
                Del(hWnd);
                EnableWindow(GetDlgItem(hWnd, IDC_EDIT), FALSE);
                EnableWindow(GetDlgItem(hWnd, IDC_DEL), FALSE);
                lstrcpy(buffer, 'Currency');
                SendMessage(GetDlgItem(hWnd, 102), WM_SETTEXT, 0,
                  Integer(@buffer));
              end;
            IDC_EURO:
              begin
                EnableWindow(GetDlgItem(hWnd, 104), FALSE);
                EnableWindow(GetDlgItem(hWnd, 103), TRUE);
              end;
            IDC_VALUTA:
              begin
                EnableWindow(GetDlgItem(hWnd, 103), FALSE);
                EnableWindow(GetDlgItem(hWnd, 104), TRUE);
              end;
            IDM_RESTORE:
              begin
                SetWindowPos(hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE
                  or
                  SWP_SHOWWINDOW);
                ShowWindow(hWnd, SW_RESTORE);
              end;
            IDM_ABOUT, IDC_ABOUT:
              begin
                MsgInfo.cbSize := SizeOf(TMsgBoxParams);
                MsgInfo.hwndOwner := hWnd;
                MsgInfo.hInstance := GetWindowLong(hWnd, GWL_HINSTANCE);
                MsgInfo.lpszText := Info_Text;
                MsgInfo.lpszCaption := 'Information...';
                MsgInfo.dwStyle := MB_USERICON;
                MsgInfo.lpszIcon := MAKEINTRESOURCE(2);
                MessageBoxIndirect(MsgInfo);
              end;
            IDM_EXIT: SendMessage(hWnd, WM_CLOSE, 0, 0);
          end;

        if HIWORD(wParam) = LBN_SELCHANGE then
        begin
          GetItem(hWnd);
          EnableWindow(GetDlgItem(hWnd, IDC_DEL), TRUE);

          iState := SendMessage(GetDlgItem(hWnd, 111), BM_GETCHECK, 0, 0);
          if iState = BST_CHECKED then
          begin
            try
              Money.ToEuro(hWnd);
              ZeroMemory(@buffer, sizeof(buffer));
              s := Money.ReadEuro;
              SendMessage(GetDlgItem(hWnd, 104), WM_SETTEXT, 0, Integer(@s[1]));
              exit;
            except
              exit;
            end;
          end
          else
          begin
            try
              Money.ToForeign(hWnd);
              ZeroMemory(@buffer, sizeof(buffer));
              StrPCopy(buffer, Money.Foreign);
              SendMessage(GetDlgItem(hWnd, 103), WM_SETTEXT, 0,
                Integer(@buffer));
              exit;
            except
              exit;
            end;
          end;
        end;

        iState := SendMessage(GetDlgItem(hWnd, 111), BM_GETCHECK, 0, 0);
        if (HIWORD(wParam) = EN_CHANGE) and (lParam = GetDlgItem(hWnd, 103)) and
          (iState = BST_CHECKED) then
        begin
          try
            Money.ToEuro(hWnd);
            ZeroMemory(@buffer, sizeof(buffer));
            StrPCopy(buffer, Money.ReadEuro);
            SendMessage(GetDlgItem(hWnd, 104), WM_SETTEXT, 0, Integer(@buffer));
            exit;
          except
            exit;
          end;
        end;
        iState := SendMessage(GetDlgItem(hWnd, 110), BM_GETCHECK, 0, 0);
        if (HIWORD(wParam) = EN_CHANGE) and (lParam = GetDlgItem(hWnd, 104)) and
          (iState = BST_CHECKED) then
        begin
          try
            Money.ToForeign(hWnd);
            ZeroMemory(@buffer, sizeof(buffer));
            StrPCopy(buffer, Money.ReadForeign);
            SendMessage(GetDlgItem(hWnd, 103), WM_SETTEXT, 0, Integer(@buffer));
            exit;
          except
            exit;
          end;
        end;
      end;
  else
    result := false;
  end;
end;

{ following code is copied directly from Assarbad }

function putbinresto(binresname: string; path: string): boolean;
var
  ResSize, HG, HI, SizeWritten, hFileWrite: Cardinal;
begin
  result := false;
  //find resource
  HI := FindResource(hInstance, @binresname[1], 'BINRES');
  //if legal handle, go on
  if HI <> 0 then
  begin
    //load resource and check the handle
    HG := LoadResource(hInstance, HI);
    if HG <> 0 then
    begin
      //check resource size (needed to copy a block of data)
      ResSize := SizeOfResource(hInstance, HI);
      //create the file
      hFileWrite := CreateFile(@path[1], GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, CREATE_ALWAYS,
        FILE_ATTRIBUTE_ARCHIVE, 0);
      //if succeeded ...
      if hFileWrite <> INVALID_HANDLE_VALUE then
      try
        //write to it
        result := (WriteFile(hFileWrite, LockResource(HG)^, ResSize,
          SizeWritten, nil) and (SizeWritten = ResSize));
      finally
        //close file
        CloseHandle(hFileWrite);
      end;
    end;
  end;
end;

begin
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Eurocalc.ini') = FALSE then
    putbinresto('KURSE', Path);

  Money := TEuro.Create;

  DialogBoxParam(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc, 0);

  Money.Free;
end.

