program Print;

uses
  Windows,
  Messages,
  WinSpool,
  CommCtrl,
  MpuTools,
  Constants;

{$R resource.res}

type
  TPrinterCallback = function(Printername: string): Boolean; stdcall;
  TStringDynArray = array of string;

var
  hApp              : THandle;

function GetDefaultPrinterA(prnName: LPTSTR; var bufSize: DWORD): BOOL;
    stdcall; external 'winspool.drv' name 'GetDefaultPrinterA';

{$INCLUDE 'helpers.inc'}

function PrinterCallback(PrinterName: string): Boolean; stdcall;
begin
  SendDlgItemMessage(hApp, IDC_CB_PRINTERS, CB_ADDSTRING, 0, Integer(@Printername[1]));
  result := True;
end;

procedure GetPrinters(Callback: TPrinterCallback);
var
  dwNeeded          : DWORD;
  dwReturn          : DWORD;
  pinfo4            : PPrinterInfo4;
  pWork             : PPrinterInfo4;
  i                 : Integer;
  s                 : string;
begin
  dwNeeded := 0;
  dwReturn := 0;
  EnumPrinters(PRINTER_ENUM_LOCAL, nil, 4, nil, 0, dwNeeded, dwReturn);
  GetMem(pinfo4, dwNeeded);
  try
    if EnumPrinters(PRINTER_ENUM_LOCAL, nil, 4, pinfo4, dwNeeded, dwNeeded, dwReturn) then
    begin
      pWork := pinfo4;
      for i := 0 to dwReturn - 1 do
      begin
        s := string(pWork.pPrinterName);
        if not Callback(s) then
          break;
        Inc(pWork);
      end;
    end
    else
      MessageBox(hApp, PChar(SysErrorMessage(GetLastError)), '', 0);
  finally
    FreeMem(pinfo4);
  end;
end;

procedure PrintDoc(Printer: string);
const
  // Information in mm
  BORDERLEFT        = 20;
  BORDERRIGHT       = 20;
  BORDERTOP         = 20;
  BORDERBOTTOM      = 20;

  FONTNAME          = 'Times New Roman';
  FONTSIZE          = 50;
var
  dc                : HDC;
  docinfo           : TDocInfo;
  PageW             : Integer;
  PageH             : Integer;
  MyFont            : HFONT;
  OldFont           : HFONT;
  Paragraphs        : Integer;
  i                 : Integer;
  s                 : string;
  size              : TSize;
  cntChars          : Integer;
  tm                : TTextMetric;
  TextHeight        : Integer;
  rect              : TRect;
  cntPage           : Integer;
  sa                : TStringDynArray;

begin
  sa := nil;

  dc := CreateDC(nil, PChar(Printer), nil, nil);
  if dc <> 0 then
  begin
    // Change the unit of measurement to 1/10 mm and the coordinate system
    SetMapMode(dc, MM_LOMETRIC);

    // Determine page width and height
    // Attention: information in mm
    PageW := GetDeviceCaps(dc, HORZSIZE);
    PageH := GetDeviceCaps(dc, VERTSIZE);

    // Writing
    MyFont := CreateFont(FONTSIZE, 0, 0, 0, 400, 0, 0, 0, ANSI_CHARSET,
      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      DEFAULT_QUALITY, DEFAULT_PITCH, FONTNAME);
    OldFont := SelectObject(dc, MyFont);
    GetTextMetrics(dc, tm);

    // Start printing
    ZeroMemory(@docinfo, sizeof(docinfo));
    docinfo.cbSize := sizeof(docinfo);
    docinfo.lpszDocName := 'Very well done';
    StartDoc(dc, docinfo);

    // Output text
    SetBkMode(dc, TRANSPARENT);
    i := 1;
    cntPage := 1;
    sa := Explode(#13#10, TEXT);
    for Paragraphs := 0 to length(sa) - 1 do
    begin
      s := sa[Paragraphs];
      if s = '' then
        Continue;
      repeat
        // Page header
        MoveToEx(dc, BORDERLEFT * 10, -BORDERTOP * 10, nil);
        LineTo(dc, PageW * 10 - BORDERRIGHT * 10, -BORDERTOP * 10);
        rect.Left := BORDERLEFT * 10;
        rect.Top := -BORDERTOP * 10 + tm.tmHeight;
        rect.Right := PageW * 10 - BORDERRIGHT * 10;
        rect.Bottom := rect.Top - tm.tmHeight;
        DrawText(dc, PChar(APPNAME), length(APPNAME), rect, DT_CENTER);
        // Wrap text in lines
        GetTextExtentExPoint(dc, PChar(s), length(s), (PageW * 10) - (BORDERLEFT * 10) - (BORDERRIGHT * 10), @cntChars,
          nil, size);
        while (s[cntChars] <> ' ') do
          Dec(cntChars);
        // Output text
        // Attention: Information in 1/10 mm
        TextOut(dc, BORDERLEFT * 10, -(BORDERTOP * 10) + -i * (Size.cy + 8), PChar(s), cntChars);
        Delete(s, 1, cntChars);
        Inc(i);
        // If the height of all lines is greater than the page height, start a new page
        TextHeight := i * (tm.tmHeight div 10) + BORDERTOP + BORDERBOTTOM;
        if TextHeight >= PageH - BORDERTOP - BORDERBOTTOM then
        begin
          // Side foot
          MoveToEx(dc, BORDERLEFT * 10, -(PageH - BORDERTOP) * 10, nil);
          LineTo(dc, PageW * 10 - BORDERRIGHT * 10, -(PageH - BORDERTOP) * 10);
          rect.Left := BORDERLEFT * 10;
          rect.Top := -(PageH - BORDERTOP) * 10 - 10;
          rect.Right := PageW * 10 - BORDERRIGHT * 10;
          rect.Bottom := rect.Top - tm.tmHeight;
          DrawText(dc, PChar(IntToStr(cntPage)), length(IntToStr(cntPage)), rect, DT_RIGHT);
          // new page
          EndPage(dc);
          Inc(cntPage);
          // Reset line counter
          i := 1;
        end;
      until CntChars < 1;
    end;
    // Page footer of the last page
    MoveToEx(dc, BORDERLEFT * 10, -(PageH - BORDERTOP) * 10, nil);
    LineTo(dc, PageW * 10 - BORDERRIGHT * 10, -(PageH - BORDERTOP) * 10);
    rect.Left := BORDERLEFT * 10;
    rect.Top := -(PageH - BORDERTOP) * 10 - 10;
    rect.Right := PageW * 10 - BORDERRIGHT * 10;
    rect.Bottom := rect.Top - tm.tmHeight;
    DrawText(dc, PChar(IntToStr(cntPage)), length(IntToStr(cntPage)), rect, DT_RIGHT);
    // Complete printing
    EndDoc(dc);
    // Select the original font back into the DC
    SelectObject(dc, OldFont);
    // Clear DC
    DeleteDC(dc);
  end
  else
    Messagebox(hApp, PChar(SysErrorMessage(GetLastError)), 'Error', MB_ICONSTOP);
end;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam): lresult; stdcall;
var
  x, y              : integer;
  ps                : TPaintStruct;
  dc                : HDC;
  rect              : TRect;
  len               : DWORD;
  Buffer            : array[0..255] of Char;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        hApp := hWnd;
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(hWnd, (x div 2) - (WINDOWWIDTH div 2), (y div 2) -
          (WINDOWHEIGHT div 2), WINDOWWIDTH, WINDOWHEIGHT,
          True);

        CreateWindowEx(0, 'COMBOBOX', '', WS_CHILD or WS_VISIBLE or
                                          CBS_AUTOHSCROLL or CBS_DROPDOWNLIST or
                                          CBS_SORT or
          WS_VSCROLL, 10, WINDOWHEIGHT - 70, 250, 350, hWnd, IDC_CB_PRINTERS, hInstance, nil);
        CreateWindowEx(0, 'BUTTON', '&Print', WS_VISIBLE or WS_CHILD or WS_TABSTOP, WINDOWWIDTH - 115,
          WINDOWHEIGHT - 70, 100, 25, hWnd, IDC_BTN_PRINT, hInstance, nil);

        GetPrinters(PrinterCallback);

        len := sizeof(Buffer) + 1;
        if GetDefaultPrinterA(Buffer, len) then
        begin
          SendDlgItemMessage(hWnd, IDC_CB_PRINTERS, CB_SELECTSTRING, 0, Integer(@Buffer));
        end;
      end;
    WM_PAINT:
      begin
        BeginPaint(hWnd, ps);
        GetClientRect(hWnd, rect);
        rect.Left := rect.Left + 10;
        rect.Top := rect.Top + 10;
        rect.Right := rect.Right - 10;
        rect.Bottom := rect.Bottom - 50;
        dc := GetDC(hWnd);
        SetBKMode(dc, TRANSPARENT);
        DrawText(dc, PChar(TEXT), length(TEXT), rect, DT_LEFT or
                 DT_WORDBREAK or DT_END_ELLIPSIS);
        EndPaint(hWnd, ps);
        ReleaseDC(hWnd, dc);
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      begin
        if hiword(wParam) = BN_CLICKED then
          case loword(wParam) of
            IDC_BTN_PRINT:
              begin
                GetDlgItemText(hWnd, IDC_CB_PRINTERS, Buffer, sizeof(Buffer));
                PrintDoc(string(Buffer));
              end;
          end;
      end;
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var
  wc                : TWndClassEx = (
    cbSize: SizeOf(TWndClassEx);
    Style: CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc: @WndProc;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hbrBackground: COLOR_BTNFACE + 1;
    lpszMenuName: nil;
    lpszClassName: ClassName;
    hIconSm: 0;
    );
  msg               : TMsg;
begin
  InitCommonControls;

  wc.hInstance := hInstance;
  wc.hIcon := LoadIcon(0, IDI_APPLICATION);
  wc.hCursor := LoadCursor(0, IDC_ARROW);

  RegisterClassEx(wc);
  hApp := CreateWindowEx(0, CLASSNAME, APPNAME, WS_VISIBLE or
                            WS_SYSMENU, Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), WINDOWWIDTH, WINDOWHEIGHT, 0, 0, HInstance, nil);

  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    if IsDialogMessage(hApp, msg) = FALSE then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  ExitCode := msg.wParam;
end.

