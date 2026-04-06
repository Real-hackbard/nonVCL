program Sample;

uses
  Windows,
  Messages;

(*
  This definition determines whether the program is static or dynamic with the DLL
  is linked.
  If the definition is removed (i.e. the "$" is deleted), then this occurs
  Integration dynamic. This is also the default setting.
*)

{$R .\main.res} // Ressourcen einbinden
{$INCLUDE .\Type.inc}
{$INCLUDE .\Include\Compilerswitches.pas} // Set some compiler options
{$INCLUDE .\Include\Constants.pas} // Incorporate constants (dialog, etc.)
{$INCLUDE .\Include\Common.pas} // General functions
{$INCLUDE .\Include\GetFont.pas} // Create and return font

var
  appIcon: HICON = 0;
  hDlg: HWND;

{$IFDEF STATIC}
{$INCLUDE .\Include\STATIC.pas}
{$ELSE}
{$INCLUDE .\Include\DYNAMIC.pas}
{$ENDIF STATIC}

function DlgFunc(hwnd: hwnd; umsg: Cardinal; wparam: wparam; lparam: lparam): bool; stdcall;
var
  font: HFONT;
begin
  Result := TRUE;
// Evaluate individual messages
  case umsg of
    WM_INITDIALOG:
      begin
// Set icon. Windows uses ICON_SMALL, all other versions use ICON_BIG
        SendMessage(hwnd, WM_SETICON, ICON_SMALL, appIcon);
        SendMessage(hwnd, WM_SETICON, ICON_BIG, appIcon);
// Get font handle. Fixed width (in this case "Courier New")
        font := GetFont(hwnd, 10, FW_NORMAL, true);
// Set fonts for text fields
        SendDlgItemMessage(hwnd, IDC_EDIT1, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT2, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT3, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT7, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT8, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT9, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT10, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT14, WM_SETFONT, font, LongInt(TRUE));
        SendDlgItemMessage(hwnd, IDC_EDIT15, WM_SETFONT, font, LongInt(TRUE));
// First, tell the DLL which window output should be sent to
        InitDLL(hwnd);
// Make the handle of this dialogue known globally
        hDlg := hwnd;
// WM_INITDIALIG requires that FALSE be returned when processed
        Result := FALSE;
      end;
    WM_CLOSE:
// Formally end the dialogue. Without this call you can only use DestroyWindow.
      EndDialog(hwnd, 0);
    WM_CTLCOLORSTATIC:
      begin
// Readonly text fields are treated as static elements
// Find out the control ID for the handle (handle in lParam)
        case GetDlgCtrlID(lParam) of
// The parameter fields
          IDC_EDIT1,
            IDC_EDIT2,
            IDC_EDIT3,
            IDC_EDIT7,
            IDC_EDIT8,
            IDC_EDIT9,
            IDC_EDIT10,
            IDC_EDIT14:
            SetTextColor(wParam, RGB($77, 0, 0)); // light red
// The text field that displays the name of the called function
          IDC_EDIT15:
            SetTextColor(wParam, RGB(0, $77, 0)); // leichtes Grün
// All other static elements.
        else
          SetTextColor(wParam, RGB(0, 0, $77)); // leichtes Blau
        end;
// Background opaque
        SetBkMode(wParam, OPAQUE);
// Set background color
        SetBkColor(wParam, GetSysColor(COLOR_BTNFACE));
// Set the brush with which the background is drawn
        result := BOOL(GetSysColorBrush(COLOR_BTNFACE));
      end;
    WM_COMMAND:
// Evaluate event type
      case HiWord(WParam) of
// A click event occurred
        BN_CLICKED:
// Evaluate Control ID
          case LoWord(wParam) of
// Evaluate messages to all buttons
            IDC_BUTTON1,
              IDC_BUTTON2,
              IDC_BUTTON3,
              IDC_BUTTON4,
              IDC_BUTTON5,
              IDC_BUTTON6,
              IDC_BUTTON7,
              IDC_BUTTON8,
              IDC_BUTTON9:
              try
// Empty output fields
                SetOutput_(hwnd, param1, param2, param3, '', false);
// Evaluate individual buttons and call the corresponding function
                case LoWord(wParam) of
                  IDC_BUTTON1: OneFunction(param1, param2, param3);
                  IDC_BUTTON2: OneFunction_CDECL(param1, param2, param3);
                  IDC_BUTTON3: OneFunction_STDCALL_(param1, param2, param3);
                  IDC_BUTTON4: OneFunction_as_CDECL(param1, param2, param3);
                  IDC_BUTTON5: OneFunction_CDECL_as_PASCAL(param1, param2, param3);
                  IDC_BUTTON6: OneFunction_STDCALL_as_PASCAL(param1, param2, param3);
                  IDC_BUTTON7: OneFunction_as_STDCALL(param1, param2, param3);
                  IDC_BUTTON8: OneFunction_CDECL_as_STDCALL(param1, param2, param3);
                  IDC_BUTTON9: OneFunction_STDCALL_as_CDECL(param1, param2, param3);
                end;
              except
// Output a message in the event of an exception
                MessageBox(hwnd, exc_text, nil, 0);
              end;
          end;
      end;
  else
    result := false;
  end;
end;

begin
{$IFNDEF STATIC}
// If dynamically linked then:
// Get function addresses. If failed, set error message and dummy address.
  GetEntryPoints;
{$ENDIF STATIC}
// Load icon and, as local variables in a window function, always reload
// ibe initialized, write handle to a global variable.
  appIcon := LoadIcon(hInstance, MAKEINTRESOURCE(1));
// Create dialog box and trigger message loop.
  DialogBoxParam(HInstance, MAKEINTRESOURCE(IDD_DIALOG1), 0, @dlgfunc, 0);
end.

