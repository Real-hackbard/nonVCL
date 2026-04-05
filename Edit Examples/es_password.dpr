program EsPasswordTest;

uses
  Windows,
  Messages;

const
  IDC_DIALOG   = 100;
  IDC_EDIT     = 110;
  IDC_BUTTON   = 120;

{$R es_password.res}


function dlgfunc(hDlg: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): bool;
  stdcall;
begin
  Result := true;

  case uMsg of
    WM_CLOSE:
      EndDialog(hDlg, 0);
    WM_COMMAND:
      if(HIWORD(wp) = BN_CLICKED) and (LOWORD(wp) = IDC_BUTTON) then
        SendMessage(hDlg, WM_CLOSE, 0, 0);
    else
      Result := false;
  end;
end;

begin
  DialogBox(hInstance,MAKEINTRESOURCE(IDC_DIALOG),0,@dlgfunc);
end.
