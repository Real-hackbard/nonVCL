program ClipViewer;

{$R resource.res}

uses
  windows, messages;

const
  WM_RESETSELECTION = WM_USER + 1;

var
  hNextViewer: DWORD;

function DlgFunc(hWnd: hWnd; uMsg: dword; wParam: wparam; lParam: lParam):
  bool; stdcall;
var
  hClipbrdObj: THandle;
  pClipbrdObj: Pointer;
  rect: TRect;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
    begin
      { Assign icon to window }
      SendMessage(hWnd, WM_SETICON, ICON_BIG, Integer(LoadIcon(HInstance,
        MAKEINTRESOURCE(1))));
      { Insert program into the clipboard viewer chain }
      hNextViewer := SetClipBoardViewer(hWnd);
    end;
    WM_CHANGECBCHAIN:
    begin
      if wParam = hNextViewer then
        hNextViewer := lParam
      else if hNextViewer <> 0 then
        SendMessage(hNextViewer, uMSG, wParam, lParam);
    end;
    WM_SIZE:
    begin
      { Adjust edit to window size }
      if GetClientRect(hWnd, Rect) then
      SetWindowPos(GetDlgItem(hWnd, 101), 0, Rect.Left, Rect.Top,
        Rect.Right - Rect.Left, Rect.Bottom - Rect.Top, SWP_NOZORDER);
    end;
    WM_DRAWCLIPBOARD:
    begin
      { Open clipboard }
      OpenClipboard(hWnd);
      { Get handle onto clipboard object }
      hClipbrdObj := GetClipboardData(CF_TEXT);
      if hClipbrdObj <> 0 then
      begin
        { Get pointer to memory block }
        pClipbrdObj := GlobalLock(hClipbrdObj);
        { Show clipboard content }
        SendMessage(GetDlgItem(hWnd, 101), WM_SETTEXT, 0, Integer(pClipbrdObj));
        PostMessage(hWnd, WM_RESETSELECTION, 0, 0);
      end;
      { and clean up }
      GlobalUnlock(DWORD(pClipbrdObj));
      GlobalFree(hClipbrdObj);
      CloseClipBoard;
    end;
    WM_RESETSELECTION: SendMessage(GetDlgItem(hWnd, 101),EM_SETSEL, 0, 0);
    WM_CLOSE:
    begin
      { Remove the program from the clipboard viewer chain }
      ChangeClipBoardChain(hWnd, hNextViewer);
      EndDialog(hWnd, 0)
    end;
  else result := false;
  end;
end;

begin
  DialogBoxParam(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc, 0);
end.
