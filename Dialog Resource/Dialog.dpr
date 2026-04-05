program Dialog;

{.$DEFINE USE_DIALOGBOX}
{.$DEFINE USE_PARAM}


{$R resource.res}
{$R dialog.res}

uses
  windows, messages;

const
  IDC_HELLO = 101;
  IDC_WORLD = 102;
  IDC_PUTTEXT = 103;
  IDC_CLOSE = 104;

var
  hStatic: Cardinal;

{ GetLastError }
procedure DisplayErrorMsg(hWnd: THandle);
var
  szBuffer: array[0..255] of Char;
begin
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, nil, GetLastError, 0, szBuffer,
    sizeof(szBuffer), nil);
  MessageBox(hWnd, szBuffer, 'Error', MB_ICONSTOP);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  szBuffer: array[0..255] of Char;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
    begin
      SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(100))));
      SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance, MAKEINTRESOURCE(100))));
      SetDlgItemText(hDlg, IDC_HELLO, '');
      SendDlgItemMessage(hDlg, IDC_WORLD, WM_SETTEXT, 0, 0);
    end;
    WM_CLOSE:
    {$IFDEF USE_DIALOGBOX}
      EndDialog(hDlg, 0);
    {$ELSE}
      PostQuitMessage(0);
    {$ENDIF}
    WM_COMMAND:
      if(wParam = IDCANCEL) then SendMessage(hDlg,WM_CLOSE,0,0)
        else if HIWORD(wParam) = BN_CLICKED then
          case LoWord(wParam) of
            IDC_PUTTEXT:
              begin
                lstrcpy(szBuffer, 'Hello');

                { Get handle from a DialogItem }
                hStatic := GetDlgItem(hDlg, IDC_HELLO);
                SendMessage(hStatic, WM_SETTEXT, 0, Integer(@szBuffer));
                SetDlgItemText(hDlg, IDC_WORLD, 'World!');
              end;
            IDC_CLOSE:
              SendMessage(hDlg, WM_CLOSE, 0, 0);
          end;
    else
      result := false;
  end;
end;

{$IFNDEF USE_DIALOGBOX}
var
  hDialog: THandle;
  msg: TMsg;
{$ENDIF}

begin
  {$IFDEF USE_DIALOGBOX}
    {$IFDEF USE_PARAM}
      MessageBox(0,'The demo uses "DialogBoxParam"','Dialog-Demo',MB_OK or MB_ICONINFORMATION);
    {$ELSE}
      MessageBox(0,'The demo uses "DialogBox"','Dialog-Demo',MB_OK or MB_ICONINFORMATION);
    {$ENDIF}
  {$ELSE}
    {$IFDEF USE_PARAM}
      MessageBox(0,'The demo uses "CreateDialogParam"','Dialog-Demo',MB_OK or MB_ICONINFORMATION);
    {$ELSE}
      MessageBox(0,'The demo uses "CreateDialog"','Dialog-Demo',MB_OK or MB_ICONINFORMATION);
    {$ENDIF}
  {$ENDIF}

  {$IFDEF USE_DIALOGBOX}
    {$IFDEF USE_PARAM}
      if(DialogBoxParam(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc, 0) = -1) then // modal
    {$ELSE}
      if(DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc) = -1) then // modal
    {$ENDIF}
        MessageBox(0,'Error displaying dialog','Dialog-Demo',MB_OK or MB_ICONERROR);
  {$ELSE}
    {$IFDEF USE_PARAM}
      hDialog := CreateDialogParam(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc, 0);  // nicht modal
    {$ELSE}
      hDialog := CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);  // nicht modal
    {$ENDIF}

    while GetMessage(msg,0,0,0) do
      begin
        IsDialogMessage(hDialog,msg);
      end;

    ExitCode := msg.wParam;

    DestroyWindow(hDialog);
  {$ENDIF}  
end.