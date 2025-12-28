program WinInfo;

uses
  windows,
  messages,
  tlhelp32;

{$R 'resource.res'}
{$INCLUDE AppTools.inc}

const
  FontNameTitle = 'Tahoma';
  FontSizeTitle = -18;
  FontName = 'Courier New';
  FontSize = -14;

  IDC_BULLESEYE = 101;
  IDC_WNDCLASS = 102;
  IDC_HWND = 103;
  IDC_ID = 104;
  IDC_PROCID = 105;
  IDC_THREADID = 106;
  IDC_TITLE = 107;
  IDC_VISIBLE = 108;
  IDC_ENABLED = 109;
  IDC_ABOUT = 110;
  IDC_APPNAME = 111;


  APPNAME = 'WindowInfo';
  VER = '1.0';

  INFO_TEXT = APPNAME + ' ' + VER + #13#10 +
    'Copyright © Your Name' + #13#10 +
    'https://github.com';

var
  hdlg: DWORD = 0;
  AppIcon, EmptyIcon, DragIcon: DWORD;

  MyFont: HFONT;

  whitebrush: HBRUSH = 0;

  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );

  Target: Cardinal;
  WndStatus: Boolean = true;

function GetExeStringFromProcID(PID: DWORD): string;
var
  s: string;
  hProcSnap: THandle;
  pe32: TProcessEntry32;
begin
  s := '';
  hProcSnap := CreateToolHelp32SnapShot(TH32CS_SNAPPROCESS, 0);
  if hProcSnap <> INVALID_HANDLE_VALUE then
  begin
    pe32.dwSize := SizeOf(TProcessEntry32);
    if Process32First(hProcSnap, pe32) = true then
    begin
      if pe32.th32ProcessID = PID then
      begin
        s := string(pe32.szExeFile);
        result := s;
        CloseHandle(hProcSnap);
        exit;
      end;
      while Process32Next(hProcSnap, pe32) = true do
      begin
        if pe32.th32ProcessID = PID then
        begin
          s := string(pe32.szExeFile);
          break;
        end;
      end;
    end;
    CloseHandle(hProcSnap);
  end;
  result := s;
end;

function DlgFunc(hWnd: HWND; uMsg: Cardinal; wParam: wParam;
  lParam: lParam): bool; stdcall;
var
  s: string;
  pt: TPOINT;
  buffer1: array[0..255] of Char;
  ID: Cardinal;
  TID, PID: DWORD;
  Enabled: Boolean;
begin
  result := true;

  case uMsg of
    WM_INITDIALOG:
      begin
        HideCaret(hWnd);

        SendMessage(hWnd, WM_SETICON, ICON_SMALL, AppIcon);
        SendMessage(hWnd, WM_SETICON, ICON_BIG, AppIcon);
        s := APPNAME + ' ' + VER;
        SetWindowText(hWnd, pointer(s));
        SetDlgItemText(hWnd, 999, pointer(s));

        MyFont := CreateFont(FontSizeTitle, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontNameTitle);
        if MyFont <> 0 then
          SendDlgItemMessage(hWnd, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));

        MyFont := CreateFont(FontSize, 0, 0, 0, 0, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
        begin
          SendDlgItemMessage(hWnd, IDC_WNDCLASS, WM_SETFONT, Integer(MyFont), Integer(true));
          SendDlgItemMessage(hWnd, IDC_HWND, WM_SETFONT, Integer(MyFont), Integer(true));
          SendDlgItemMessage(hWnd, IDC_ID, WM_SETFONT, Integer(MyFont), Integer(true));
          SendDlgItemMessage(hWnd, IDC_PROCID, WM_SETFONT, Integer(MyFont), Integer(true));
          SendDlgItemMessage(hWnd, IDC_THREADID, WM_SETFONT, Integer(MyFont), Integer(true));
          SendDlgItemMessage(hWnd, IDC_TITLE, WM_SETFONT, Integer(MyFont), Integer(true));
          SendDlgItemMessage(hWnd, IDC_APPNAME, WM_SETFONT, Integer(MyFont), Integer(true));
        end;
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
        SetWindowPos(GetDlgItem(hWnd, 110), GetDlgItem(hWnd, 999), loword(lParam)
          - 47, 7, 40, 22, 0);
      end;
    WM_COMMAND:
      begin
        if hiword(wParam) = BN_CLICKED then
          case loword(wParam) of
            IDC_ABOUT: Messagebox(hWnd, INFO_TEXT, APPNAME, MB_ICONINFORMATION);
          end;
      end;
    WM_LBUTTONDOWN:
      begin
        pt.x := Word(lParam);
        pt.y := Word(lParam shr 16);
        if ChildWindowFromPoint(hWnd, pt) = GetDlgItem(hWnd, IDC_BULLESEYE) then
        begin
          SetCapture(hWnd);
          SetCursor(LoadCursor(hInstance, MAKEINTRESOURCE(301)));
          SendMessage(GetDlgItem(hWnd, IDC_BULLESEYE), STM_SETIMAGE, IMAGE_ICON, EmptyIcon);
        end;
      end;
    WM_LBUTTONUP:
      begin
        if GetCapture = hWnd then
          ReleaseCapture;
      end;
    WM_CAPTURECHANGED:
      begin
        SetCursor(LoadCursor(hInstance, IDC_ARROW));
        SendMessage(GetDlgItem(hWnd, IDC_BULLESEYE), STM_SETIMAGE, IMAGE_ICON,
          DragIcon);
      end;
    WM_MOUSEMOVE:
      begin
        if ((GetCapture = hWnd) and GetCursorPos(pt)) then
        begin
          Target := WindowFromPoint(pt);
          ScreenToClient(Target, pt);
          Target := ChildWindowFromPoint(Target, pt);

          GetClassName(Target, buffer1, 256);
          SetWindowText(GetDlgItem(hWnd, IDC_WNDCLASS), buffer1);

          wvsprintf(buffer1, '0x%8.8X', PChar(@Target));
          SetWindowText(GetDlgItem(hWnd, IDC_HWND), buffer1);

          ID := GetDlgCtrlID(Target);
          wvsprintf(buffer1, '0x%8.8X', PChar(@ID));
          SetWindowText(GetDlgItem(hWnd, IDC_ID), buffer1);

          TID := GetWindowThreadProcessID(Target, @PID);

          wvsprintf(buffer1, '%8.8d', PChar(@PID));
          SetWindowText(GetDlgItem(hWnd, IDC_PROCID), buffer1);

          wvsprintf(buffer1, '0x%8.8X', PChar(@TID));
          SetWindowText(GetDlgItem(hWnd, IDC_THREADID), buffer1);

          SendMessage(Target, WM_GETTEXT, 256, Integer(@buffer1));
          SetWindowText(GetDlgItem(hWnd, IDC_TITLE), buffer1);

          s := GetExeStringFromProcID(PID);
          SetWindowText(GetDlgItem(hWnd, IDC_APPNAME), pointer(s));

          case IsDlgButtonChecked(hWnd, IDC_VISIBLE) of
            BST_CHECKED: Enabled := true
          else
            Enabled := false;
          end;
          if Enabled <> IsWindowVisible(Target) then
            case Enabled of
              true: CheckDlgButton(hWnd, IDC_VISIBLE, BST_UNCHECKED);
              false: CheckDlgButton(hWnd, IDC_VISIBLE, BST_CHECKED);
            end;

          case IsDlgButtonChecked(hWnd, IDC_ENABLED) of
            BST_CHECKED: Enabled := TRUE
          else
            Enabled := FALSE;
          end;
          if Enabled <> IsWindowEnabled(Target) then
            case Enabled of
              true: CheckDlgButton(hWnd, IDC_ENABLED, BST_UNCHECKED);
              false: CheckDlgButton(hWnd, IDC_ENABLED, BST_CHECKED);
            end;
        end;
      end;
    WM_CLOSE: EndDialog(hWnd, 0);
  else
    result := false;
  end;
end;

begin
  AppIcon := LoadIcon(hInstance, MAKEINTRESOURCE(200));
  EmptyIcon := LoadIcon(hInstance, MAKEINTRESOURCE(202));
  DragIcon := LoadIcon(hInstance, MAKEINTRESOURCE(203));
  DialogBoxParam(hInstance, MAKEINTRESOURCE(100), 0, @DlgFunc, 0);
end.

