program ColorPicker;

{$R 'resource.res'}

uses
  windows,
  messages,
  CommCtrl,
  commdlg,
  SysUtils;

{$INCLUDE AppTools.pas}

const
  ID_TIMER      = 1;
  IDC_COPY      = 107;
  IDC_COLOR     = 108;
  IDC_FORMAT    = 109;
  IDC_COPYRIGHT = 110;
  IDC_STCTITLE  = 111;
  IDC_BTNABOUT  = 112;

  FontName    = 'Tahoma';
  FontSize    = -18;

const
  APPNAME = 'Color Picker';
  VER     = '1.0';
  INFO_TEXT =  APPNAME+' '+VER+' '+#13+#10+
               'Copyright © Your Name'+#13+#10+#13+#10+
               'https://github.com';

var
  hApp : Cardinal;
  EmptyIcon, DragIcon: HICON;

  hdcScreen    : HDC;
  cr, crlast   : COLORREF;
  pt           : TPOINT;
  szBuffer     : array[0..32] of Char;
  cc           : TCHOOSECOLOR;
  crCustColors : array[0..15] of COLORREF;
  Brush        : HBRUSH;

  MyFont       : HFONT;

  whitebrush   : HBRUSH = 0;
  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
  );

{ GetLastError }
procedure DisplayErrorMsg(hWnd: THandle);
var
  szBuffer: array[0..255] of Char;
begin
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NIL, GetLastError(), 0, szBuffer,
    sizeof(szBuffer), NIL);
  MessageBox(hWnd, szBuffer, 'Fehler', MB_ICONSTOP);
end;

procedure ShowInfo(hWnd: HWND);
var
  MsgInfo: TMsgBoxParams;
begin
  MsgInfo.cbSize := SizeOf(TMsgBoxParams);
  MsgInfo.hwndOwner := hWnd;
  {GetWindowLong: Retrieves the handle of the application instance}
  MsgInfo.hInstance := GetWindowLong(hWnd, GWL_HINSTANCE);
  MsgInfo.lpszText :=  INFO_TEXT;
  MsgInfo.lpszCaption := 'Information...';
  MsgInfo.dwStyle := MB_USERICON;
  MsgInfo.lpszIcon := MAKEINTRESOURCE(4);
  MessageBoxIndirect(MsgInfo);
end;

procedure DisplayClr;
var
  szColor: array[0..255] of Char;
  dc: HDC;
  Brush: HBRUSH;
  rc: TRect;
begin
  if SendMessage(GetDlgItem(hAPP, IDC_FORMAT), CB_GETCURSEL, 0, 0) = 1 then
    begin
      crLast := cr;
      Zeromemory(@szBuffer, sizeof(szBuffer));
      lstrcpy(szColor, 'RGB(');
      lstrcpy(szBuffer, PChar(IntToStr(GetRValue(cr))));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 101), WM_SETTEXT, 0, Integer(@szBuffer));
      lstrcat(szColor, ',');
      lstrcpy(szBuffer, PChar(IntToStr(GetGValue(cr))));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 102), WM_SETTEXT, 0, Integer(@szBuffer));
      lstrcat(szColor, ',');
      lstrcpy(szBuffer, PChar(IntToStr(GetBValue(cr))));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 103), WM_SETTEXT, 0, Integer(@szBuffer));

      lstrcat(szColor, ')');
      SendMessage(GetDlgItem(hApp, 105), WM_SETTEXT, 0, Integer(@szColor));
    end
    else
    begin
      crLast := cr;

      lstrcpy(szBuffer, '$');
      lstrcat(szBuffer, PChar(IntToHex(GetRValue(cr),2)));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 101), WM_SETTEXT, 0, Integer(@szBuffer));
      lstrcpy(szBuffer, '$');
      lstrcat(szBuffer, PChar(IntToHex(GetGValue(cr),2)));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 102), WM_SETTEXT, 0, Integer(@szBuffer));
      lstrcpy(szBuffer, '$');
      lstrcat(szBuffer, PChar(IntToHex(GetBValue(cr),2)));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 103), WM_SETTEXT, 0, Integer(@szBuffer));

      lstrcpy(szColor, '$');
      lstrcpy(szBuffer, PChar(IntToHex(GetBValue(cr),2)));
      lstrcat(szColor, szBuffer);
      lstrcpy(szBuffer, PChar(IntToHex(GetGValue(cr),2)));
      lstrcat(szColor, szBuffer);
      lstrcpy(szBuffer, PChar(IntToHex(GetRValue(cr),2)));
      lstrcat(szColor, szBuffer);
      SendMessage(GetDlgItem(hApp, 105), WM_SETTEXT, 0, Integer(@szColor));
    end;

    //GetClientRect(GetDlgItem(hAPP, IDC_COLOR), rc);
    dc := GetDC(hApp);
    Brush := CreateSolidBrush(cr);
    rc.Left := 159;
    rc.Top := 74;
    rc.Right := 224;
    rc.Bottom := 136;
    SelectObject(dc, Brush);
    FillRect(dc, rc, Brush);
    ReleaseDC(hApp, dc);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  szX, szY: array[0..5] of Char;
  s : String;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
    begin
      hApp := hDlg;
      SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));
      SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
        MAKEINTRESOURCE(1))));
      SetWindowPos(hDlg, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

      MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
        DEFAULT_PITCH, FontName);
      if MyFont <> 0 then
        SendDlgItemMessage(hDlg, IDC_STCTITLE, WM_SETFONT, Integer(MyFont),Integer(true));
      s := '     '+APPNAME+' '+VER;
      SetWindowText(hDlg, pointer(s));
      SetDlgItemText(hDlg, 111, pointer(s));

      lstrcpy(szBuffer, 'RGB(rrr,ggg,bbb)');
      SendMessage(GetDlgItem(hDlg, IDC_FORMAT), CB_ADDSTRING, 0, Integer(@szBuffer));
      lstrcpy(szBuffer, '$bbggrr');
      SendMessage(GetDlgItem(hDlg, IDC_FORMAT), CB_ADDSTRING, 0, Integer(@szBuffer));
      SendMessage(GetDlgItem(hDlg, IDC_FORMAT), CB_SETCURSEL, 1, 0);

      SetFocus(GetDlgItem(hDlg, 107));

      hdcScreen := CreateDC ('DISPLAY', NIL, NIL, NIL);
    end;
    WM_CTLCOLORSTATIC:
    begin
      case GetDlgCtrlId(lParam) of
        IDC_STCTITLE:
        begin
          whitebrush := CreateBrushIndirect(WhiteLB);
          SetBkColor(wParam, WhiteLB.lbColor);
          result := BOOL(whitebrush);
        end;
      end;
    end;
    WM_LBUTTONDOWN:
      begin
        pt.x := Word(lParam);
        pt.y := Word(lParam shr 16);
        if ChildWindowFromPoint(hDlg, pt) = GetDlgItem(hDlg, 106) then
        begin
          SetCapture(hDlg);
          SetCursor(LoadCursor(hInstance, MAKEINTRESOURCE(1)));
          SendMessage(GetDlgItem(hDlg, 106), STM_SETIMAGE, IMAGE_ICON,
            EmptyIcon);
        end;
      end;
    WM_LBUTTONUP:
      begin
        if GetCapture = hDlg then
          ReleaseCapture;
      end;
    WM_CAPTURECHANGED:
      begin
        SetCursor(LoadCursor(hInstance, IDC_ARROW));
        SendMessage(GetDlgItem(hDlg, 106), STM_SETIMAGE, IMAGE_ICON,
          DragIcon);
      end;
     WM_MOUSEMOVE:
      begin
        if ((GetCapture = hDlg) and GetCursorPos(pt)) then
        begin
          lstrcpy(szBuffer, 'What Color - x: ');
          wvsprintf(szX, '%d', PChar(@pt.x));
          lstrcat(szBuffer, szX);
          wvsprintf(szY, '%d', PChar(@pt.y));
          lstrcat(szBuffer, ', y: ');
          lstrcat(szBuffer, szY);
          SetWindowText(hDlg, szBuffer);
          cr := GetPixel(hdcScreen, pt.x, pt.y);
          if cr <> crLast then
            DisplayClr;
        end;
      end;
    WM_COMMAND:
    begin
      if HIWORD(wParam) = BN_CLICKED then
        case LOWORD(wParam) of
          IDC_COPY:
          begin
            SendMessage(GetDlgItem(hDlg, 105), EM_SETSEL, 0, -1);
            SendMessage(GetDlgItem(hDlg, 105), WM_COPY, 0, 0);
          end;
          IDC_COLOR:
          begin
            cc.lStructSize := sizeof(TCHOOSECOLOR);
            cc.hWndOwner := hDlg;
            cc.hInstance := hInstance;
            cc.rgbResult := RGB(0,0,0);
            cc.lpCustColors := @crCustColors;
            cc.Flags := CC_FULLOPEN or CC_RGBINIT;
            cc.lCustData := 0;
            cc.lpfnHook := NIL;
            cc.lpTemplateName := NIL;

            if ChooseColor(cc) = TRUE then
            begin
              cr := cc.rgbResult;
              DisplayClr;
            end;
          end;
          IDC_BTNABOUT: MyMessagebox(hDlg, INFO_TEXT, 5);
        end;
      if HIWORD(wParam) = CBN_SELCHANGE then
        case LOWORD(wParam) of
          IDC_FORMAT: DisplayClr;
        end;
    end;
    WM_CLOSE:
    begin
      DeleteObject(Brush);
      DeleteDC(hdcScreen);
      DestroyWindow(hDlg);
      PostQuitMessage(0);
    end;
  else result := false;
  end;
end;

begin
  InitCommonControls;
  EmptyIcon := LoadIcon(hInstance, MAKEINTRESOURCE(2));
  DragIcon := LoadIcon(hInstance, MAKEINTRESOURCE(3));
  DialogBoxParam(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc, 0);
end.

