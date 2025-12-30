program ShowErrorMsg;

uses
  windows, messages, CommCtrl;

{$R resource.res}

{$INCLUDE GUITools.pas}
{$INCLUDE APPTools.pas}


const
  APPNAME = 'ShowErrorMessage';
  VER     = '1.0';

  INFO_TEXT =  APPNAME+' '+VER+' '+
               'Copyright © Your Name'+#13+#10+
               'All rights reserved.'+#13+#10+#13+#10+
               'https://github.com';

const
  IDC_EDTERRORCODE = 101;
  IDC_CHKAOT       = 102;
  IDC_STCERRORMSG  = 103;
  IDC_BTNSHOW      = 104;

function GetErrorText(dwCode: DWORD): String;
var
  buffer : array[0..1024] of Char;
  iOK    : Integer;
begin
  result := '';
  iOK := FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM , nil,
    dwCode, 0, buffer, sizeof(buffer), nil);
  if iOK = 0 then
    result := 'Error code not found.'
  else
    result := String(buffer);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  s      : String;
  buffer : array[0..4] of Char;
  dwCode : DWORD;
  icode  : Integer;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
    begin
      SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));
      SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));

      s := APPNAME+' '+VER;
      SetWindowText(hDlg, pointer(s));
      SetDlgItemText(hDlg, 999, pointer(s));

      CreateToolTips(hDlg);
      AddToolTip(hDlg, IDC_EDTERRORCODE, @ti, 'Enter the error number');
      AddToolTip(hDlg, IDC_CHKAOT, @ti, 'Always place windows at the top.');
      AddToolTip(hDlg, IDC_BTNSHOW, @ti, 'Show errors');

      SendDlgItemMessage(hDlg, IDC_EDTERRORCODE, EM_LIMITTEXT, 5, 0);
      EnableWindow(GetDlgItem(hDlg, IDC_BTNSHOW), FALSE);
    end;
    WM_CLOSE: EndDialog(hDlg, 0);
    WM_SYSCOMMAND:
    begin
      if wParam = SC_CONTEXTHELP then
        MyMessagebox(hDlg, INFO_TEXT, 2)
      else
        result := FALSE;
    end;
    WM_LBUTTONDOWN: SendMessage(hDlg, WM_NCLBUTTONDOWN, HTCAPTION, lParam);
    WM_COMMAND:
    begin
      if HIWORD(wParam) = BN_CLICKED then
      begin
        case LOWORD(wParam) of
          IDC_BTNSHOW:
          begin
            GetDlgItemText(hDlg, IDC_EDTERRORCODE, buffer, sizeof(buffer));
            val(String(buffer), dwCode, icode);
            SetDlgItemText(hDlg, IDC_STCERRORMSG, pointer(GetErrorText(dwCode)));
          end;
          IDC_CHKAOT:
          begin
            if IsDlgButtonChecked(hDlg,IDC_CHKAOT) = BST_CHECKED then
              SetWindowPos(hDlg,HWND_TOPMOST,0,0,0,0, SWP_NOSIZE or SWP_NOMOVE)
            else
              SetWindowPos(hDlg,HWND_NOTOPMOST,0,0,0,0, SWP_NOSIZE or SWP_NOMOVE)
          end;
        end;
      end;
      if HIWORD(wparam) = EN_CHANGE then
      begin
        GetDlgItemText(hDlg, IDC_EDTERRORCODE, buffer, sizeof(buffer));
        if lstrlen(buffer) > 0 then
          EnableWindow(GetDlgItem(hDlg, IDC_BTNSHOW), TRUE)
        else
          EnableWindow(GetDlgItem(hDlg, IDC_BTNSHOW), FALSE);
      end;
    end
  else result := false;
  end;
end;


begin
  InitCommonControls;
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

