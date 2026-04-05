program CBEx;

uses
  Windows,
  Messages,
  CommCtrl,
  ShellAPI;

{$R CBEx.res}

{.$DEFINE THE_BIG_PICTURE}


//
// WndProc
//
const
  szClassName   = 'CBExWndClass';
  szAppName     = 'ComboBoxEx';
  IDC_CBEX      = 1;
  IDC_STATIC    = 2;
  IDC_ACTION    = 3;

{$IFDEF THE_BIG_PICTURE}
  IDC_IMAGES    = 200;
  iSize         = 32;
{$ELSE}
  IDC_IMAGES    = 100;
  iSize         = 16;
{$ENDIF}

var
  hCBEx,
  hStatusLabel,
  hActionLabel  : HWND;
  hImgList      : HIMAGELIST;
  hwndFont      : HGDIOBJ;

type
  TCBExItemInfo = record
    iImage,
    iIndent : integer;
    pszText : pchar;
  end;
var
  ItemInfo      : array[0..7]of TCBExItemInfo =
    ((iImage:0;
      iIndent:0;
      pszText:'Peter'),
     (iImage:1;
      iIndent:1;
      pszText:'Sam'),
     (iImage:2;
      iIndent:2;
      pszText:'John'),
     (iImage:0;
      iIndent:3;
      pszText:'James'),
     (iImage:1;
      iIndent:2;
      pszText:'Fritz'),
     (iImage:2;
      iIndent:1;
      pszText:'Thomas'),
     (iImage:0;
      iIndent:0;
      pszText:'DFonald'),
     (iImage:1;
      iIndent:4;
      pszText:'Andrea'));


function WndProc(wnd: HWND; uMsg: UINT; wp: wParam; lp: LParam):
  LRESULT; stdcall;
var
  i     : Integer;
  cbei  : TComboBoxExItem;
  hbmp  : HBITMAP;
  buf   : array[0..MAX_PATH]of char;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        // Create ComboBoxEx, ...
        hCBEx := CreateWindowEx(0,WC_COMBOBOXEX,nil,WS_BORDER or WS_CHILD or
          WS_VISIBLE or CBS_DROPDOWN,10,10,300,172,wnd,IDC_CBEX,hInstance,nil);
        if(hCBEx = 0) then SendMessage(wnd,WM_CLOSE,0,0);

        // Text, indentation, and images should be displayed.
        cbei.mask := CBEIF_TEXT or CBEIF_INDENT or CBEIF_IMAGE or
          CBEIF_SELECTEDIMAGE;

        // Insert items
        for i := low(ItemInfo) to high(ItemInfo) do begin
          // Item-Index
          cbei.iItem          := -1;
          // Text
          cbei.pszText        := ItemInfo[i].pszText;
          cbei.cchTextMax     := lstrlen(ItemInfo[i].pszText);
          // Einrückung
          cbei.iIndent        := ItemInfo[i].iIndent;
          // Image in the ComboBoxEx list
          cbei.iImage         := ItemInfo[i].iImage;
          // Image in the input field of ComboBoxEx
          cbei.iSelectedImage := ItemInfo[i].iImage;

          // Pass item to ComboBoxEx
          SendMessage(hCBEx,CBEM_INSERTITEM,0,LPARAM(@cbei));
        end;

        // 1. Item select
        SendMessage(hCBEx,CB_SETCURSEL,0,0);

        // Create an ImageList and assign it to ComboBoxEx.
        hbmp     := LoadBitmap(hInstance,MAKEINTRESOURCE(IDC_IMAGES));
        if(hbmp <> 0) then begin
          hImgList := ImageList_Create(iSize,iSize,ILC_COLOR,0,1);
          ImageList_Add(hImgList,hbmp,0);
          DeleteObject(hbmp);
          SendMessage(hCBEx,CBEM_SETIMAGELIST,0,LPARAM(hImgList));
        end;

        // Label for illustrative purposes only
        hStatusLabel := CreateWindowEx(0,'STATIC','selected entry:',
          WS_CHILD or WS_VISIBLE,10,56,125,20,wnd,IDC_STATIC,
          hInstance,nil);
        hActionLabel := CreateWindowEx(0,'STATIC',nil,WS_CHILD or
          WS_VISIBLE or SS_SUNKEN,140,54,169,20,wnd,IDC_ACTION,
          hInstance,nil);

        // Font load
        hwndFont := GetStockObject(DEFAULT_GUI_FONT);
        if(hwndFont <> 0) then begin
          SendMessage(hStatusLabel,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hActionLabel,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
        end;
      end;
    WM_DESTROY:
      begin
        // Release Font & Image List
        DeleteObject(hwndFont);
        ImageList_Destroy(hImgList);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      if(HIWORD(wp) = CBN_SELCHANGE) and
        (LOWORD(wp) = IDC_CBEX) then
      begin
        i := SendMessage(hCBEx,CB_GETCURSEL,0,0);
        if(i <> CB_ERR) then begin
          ZeroMemory(@buf,sizeof(buf));
          SendMessage(hCBEx,CB_GETLBTEXT,i,LPARAM(@buf));
          SetWindowText(hActionLabel,buf);
        end;
      end;
  else
    Result := DefWindowProc(wnd,uMsg,wp,lp);
  end;
end;


//
// WinMain
//
var
  iccex : TInitCommonControlsEx =
    (dwSize:sizeof(iccex);
     dwICC:ICC_USEREX_CLASSES;);
  wc    : TWndClassEx =
    (cbSize:sizeof(TWndClassEx);
     Style:CS_HREDRAW or CS_VREDRAW;
     lpfnWndProc:@WndProc;
     cbClsExtra:0;
     cbWndExtra:0;
     lpszMenuName:nil;
     lpszClassName:szClassName;
     hIconSm:0;);
  msg   : TMsg;
  aWnd  : HWND;
begin
  // Initialize ComboBoxEx
  InitCommonControlsEx(iccex);

  // Register window class, ...
  wc.hInstance     := hInstance;
  wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
  wc.hIcon         := LoadIcon(0,IDI_WINLOGO);
  wc.hCursor       := LoadCursor(0,IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  // ... & Create and display windows
  aWnd             := CreateWindowEx(0,szClassName,szAppName,WS_CAPTION or
    WS_VISIBLE or WS_SYSMENU,integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),
    330,110,0,0,hInstance,nil);
  if(aWnd = 0) then exit;
  ShowWindow(aWnd,SW_SHOW);
  UpdateWindow(aWnd);

  // Message loop
  while(GetMessage(msg,0,0,0)) do begin
    TranslateMessage(msg);
    DispatchMessage(msg);
  end;
end.
