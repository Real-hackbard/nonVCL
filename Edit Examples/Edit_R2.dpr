//
// Edit-Demo Rev. 2.1
// Copyright (c) 2001, Michael (Luckie) Puff
// Ergänzungen, & Erweiterungen (c) 2003, Mathias Simmack
//
//
// Voraussetzungen der Original-Demo:
//   - Fenster-Demo
//   - Label-Demo
//   - Button-Demo
//
// Neu:
//   - WM_GETTEXT
//   - WM_SETTEXT
//   - EM_LINELENGTH
//   - EM_SETSEL
//   - EM_GETSEL
//
// Neu in Revision 2.1:
//   - UpDown-Integration als Vorschau auf die "Common Controls"
//       + UDM_SETRANGE32
//       + UDM_SETPOS
//       + UDN_DELTAPOS (Notification)
//   - Edit_SetCueBannerText
//   - Edit_ShowBalloonTip
//   - SHAutoComplete (min. IE5 erforderlich!)
//
program Edit_R2;

{$R resource.res}
{$R manifest.res}

uses
  Windows,
  Messages,
  CommCtrl,
  CommCtrl_Fragment in 'CommCtrl_Fragment.pas',
  ActiveX,
  DllVersion in 'DllVersion.pas',
  ShlObj_Fragment in 'ShlObj_Fragment.pas',
  MSysUtils in 'MSysUtils.pas';


//
// Help functions
//
const
  AppName   = 'Edit Rev.';
var
  buffer    : array[0..1024]of char;
  SelStart,
  SelEnd    : integer;
  ebt       : TEditBalloonTip;

procedure CopyText(hEdit1, hEdit2, hLabel : HWND);
var
  Textlen : integer;
begin
  GetWindowText(hEdit1,buffer,1024);
  Textlen := SendMessage(hEdit1,EM_LINELENGTH,0,0);
  SetWindowText(hEdit2,buffer);
  wvsprintf(buffer,'Copied characters: %d',PChar(@TextLen));
  SetWindowText(hLabel,buffer);
end;

function SelText(hEdit1, hEdit3, hEdit4: HWND): boolean;
begin
  // Reset selection
  SendMessage(hEdit1,EM_SETSEL,0,0);

  GetWindowText(hEdit3,buffer,1024);
  SelStart := strtointdef(buffer,-1);
  GetWindowText(hEdit4,buffer,1024);
  SelEnd   := strtointdef(buffer,-1);

  Result   := (SelStart <> -1) and (SelEnd <> -1) and (SelStart < SelEnd);
  if(Result) then
    SendMessage(hEdit1,EM_SETSEL,SelStart,SelEnd);

  // Balloon tip under Win
  if (IsWindowsXP) or (IsWindowsVista) then
  begin
    ebt.cbStruct := sizeof(ebt);
    ebt.pszTitle := AppName;
    ebt.pszText  := pwidechar(widestring(
      Format('%d characters have been highlighted in the upper edit control.',
      [SelEnd-SelStart])));
    ebt.ttiIcon  := TTI_INFO;
    Edit_ShowBalloonTip(hEdit1,@ebt);
  end;
end;

procedure CopySel(hEdit1, hEdit2, hLabel: HWND);
var
  Textlen : integer;
begin
  SendMessage(hEdit1,EM_GETSEL,WPARAM(@SelStart),LPARAM(@SelEnd));
  TextLen := SelEnd - SelStart;
  if TextLen = 0 then exit;

  wvsprintf(buffer,'Copied characters: %d',PChar(@TextLen));
  SetWindowText(hLabel,buffer);

  // Copy from the first edit and paste into the second edit.
  SendMessage(hEdit1,WM_COPY,0,0);
  SendMessage(hEdit2,WM_PASTE,0,0);

  // Reset selection
  SendMessage(hEdit1,EM_SETSEL,0,0);

  // Balloon tip under Win
  if (IsWindowsXP) or (IsWindowsVista) then
  begin
    ebt.cbStruct := sizeof(ebt);
    ebt.pszTitle := AppName;
    ebt.pszText  := pwidechar(widestring(
      Format('%d characters were copied into the lower edit control.',
      [Textlen])));
    ebt.ttiIcon  := TTI_INFO;
    Edit_ShowBalloonTip(hEdit2,@ebt);
  end;
end;


//
// "WndProc"
//
const
  IDC_EDIT1    = 1;
  IDC_EDIT2    = 2;
  IDC_BUTTON1  = 3;
  IDC_LABEL1   = 4;
  iDC_LABEL2   = 5;
  IDC_LABEL3   = 6;
  IDC_BUTTON2  = 7;
  IDC_EDIT3    = 8;
  IDC_EDIT4    = 9;
  IDC_BUTTON3  = 10;
  IDC_TRACK1   = 11;
  IDC_TRACK2   = 12;
var
  hwndEdit1,
  hwndEdit2,
  hwndlabel2,
  hwndLabel3,
  hwndLabel1,
  hwndButton1,
  hwndButton2,
  hwndButton3,
  hwndEdit3,
  hwndEdit4,
  hTrack1,
  hTrack2      : HWND;
  hwndFont     : HGDIOBJ;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
begin
  Result := 0;
  case uMsg of
    WM_CREATE:
      begin
        // Create edit fields
        hwndEdit1 := CreateWindowEx(WS_EX_CLIENTEDGE,'EDIT','',
          WS_VISIBLE or WS_CHILD or ES_NOHIDESEL,10,20,400,20,wnd,
          IDC_EDIT1,hInstance,nil);
        hwndEdit2 := CreateWindowEx(WS_EX_CLIENTEDGE,'EDIT','',
          WS_VISIBLE or WS_CHILD,10,55,400,20,wnd,IDC_EDIT2,
          hInstance,nil);
        hwndEdit3 := CreateWindowEx(WS_EX_CLIENTEDGE,'EDIT','',
          WS_VISIBLE or WS_CHILD,130,100,55,19,wnd,IDC_EDIT3,
          hInstance,nil);

        // 1. Create "UpDown" for "hwndEdit3"
        hTrack1   := CreateWindowEx(0,UPDOWN_CLASS,'',WS_VISIBLE or
          WS_CHILD or UDS_ALIGNRIGHT or UDS_ARROWKEYS or UDS_SETBUDDYINT or
          UDS_AUTOBUDDY,10,10,30,20,wnd,IDC_TRACK1,hInstance,nil);
        // Set area ->
        // (from character zero to string length minus one)
        SendMessage(hTrack1,UDM_SETRANGE32,0,
          SendMessage(hwndEdit1,WM_GETTEXT,sizeof(buffer),LPARAM(@buffer)) - 1);


        hwndEdit4 := CreateWindowEx(WS_EX_CLIENTEDGE,'EDIT','',WS_VISIBLE or
          WS_CHILD,222,100,55,19,wnd,IDC_EDIT4,hInstance,nil);

        // 2. Create "UpDown" for "hwndEdit4"
        hTrack2   := CreateWindowEx(0,UPDOWN_CLASS,'',WS_VISIBLE or
          WS_CHILD or UDS_ALIGNRIGHT or UDS_ARROWKEYS or UDS_SETBUDDYINT or
          UDS_AUTOBUDDY,10,10,30,20,wnd,IDC_TRACK2,hInstance,nil);
        // Set area ->
        // (from character one to string length)
        SendMessage(hTrack2,UDM_SETRANGE32,1,
          SendMessage(hwndEdit1,WM_GETTEXT,sizeof(buffer),LPARAM(@buffer)));
        SendMessage(hTrack2,UDM_SETPOS,0,MAKELONG(1,0));

        // Create labels
        hwndLabel1 := CreateWindowEx(0,'STATIC','Copied characters: ',
          WS_VISIBLE or WS_CHILD,10,80,275,20,wnd,IDC_LABEL1,hInstance,
          nil);
        hwndLabel2 := CreateWindowEx(0,'STATIC','Mark characters from: ',
          WS_VISIBLE or WS_CHILD,10,100,117,20,wnd,IDC_LABEL2,hInstance,
          nil);
        hwndLabel3 := CreateWindowEx(0,'STATIC','to: ',WS_VISIBLE or
          WS_CHILD,190,100,30,20,wnd,IDC_LABEL3,hInstance,nil);

        // Create buttons
        hwndButton1 := CreateWindowEx(0,'BUTTON','Copy text',
          WS_VISIBLE or WS_CHILD or WS_DISABLED,10,130,125,25,wnd,IDC_BUTTON1,
          hInstance,nil);
        hwndButton2 := CreateWindowEx(0,'BUTTON','Mark',WS_VISIBLE or
          WS_CHILD or WS_DISABLED,145,130,125,25,wnd,IDC_BUTTON2,hInstance,nil);
        hwndButton3 := CreateWindowEx(0,'BUTTON','Copy selection',
          WS_VISIBLE or WS_CHILD or WS_DISABLED,280,130,125,25,wnd,
          IDC_BUTTON3,hInstance,nil);

        // Font
        hwndFont := GetStockObject(DEFAULT_GUI_FONT);
        if(hwndFont <> 0) then
        begin
          SendMessage(hwndButton3,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndButton2,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndButton1,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndLabel3,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndLabel2,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndLabel1,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndEdit4,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndEdit3,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndEdit2,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
          SendMessage(hwndEdit1,WM_SETFONT,WPARAM(hwndFont),LPARAM(true));
        end;

        // Display of a kind of "default" text
        if IsWindowsXP then
          Edit_SetCueBannerText(hwndEdit1, 'Enter something here')
        else if IsWindowsVista then
          Edit_SetCueBannerTextFocused(hwndEdit1, 'Enter something here',
          true);

        // Set AutoComplete for the first edit field
        SHAutoComplete(hwndEdit1,SHACF_DEFAULT);
      end;
    WM_DESTROY:
      begin
        // Release font
        DeleteObject(hwndFont);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      begin
        case HIWORD(wp) of
          BN_CLICKED:
            case loword(wp) of
              IDC_BUTTON1:
                CopyText(hwndEdit1,hwndEdit2,hwndLabel1);
              IDC_BUTTON2:
                begin
                  EnableWindow(hwndButton3,
                    SelText(hwndEdit1,hwndEdit3,hwndEdit4));
                end;
              IDC_BUTTON3:
                begin
                  CopySel(hwndEdit1,hwndEdit2,hwndLabel1);
                  EnableWindow(hwndButton3,false);
                end;
            end;
          EN_CHANGE:
            case LOWORD(wp) of
              IDC_EDIT1:
                begin
                  // Adjust the "UpDown" areas
                  SendMessage(hTrack1,UDM_SETRANGE32,0,
                    GetWindowTextLength(hwndEdit1) - 1);
                  SendMessage(hTrack2,UDM_SETRANGE32,1,
                    GetWindowTextLength(hwndEdit1));
                  SendMessage(hTrack2,UDM_SETPOS,0,MAKELONG(1,0));

                  // Activate the (Copy & Highlight) buttons
                  EnableWindow(hwndButton1,GetWindowTextLength(hwndEdit1) > 0);
		  EnableWindow(hwndButton2,GetWindowTextLength(hwndEdit1) > 0);
                end;
              IDC_EDIT3,
              IDC_EDIT4:
                begin
                  // Check the area and reset if necessary.
                  fillchar(buffer,sizeof(buffer),#0);
                  if(SendMessage(HWND(lp),WM_GETTEXT,sizeof(buffer),
                    LPARAM(@buffer)) > 0) then
                  begin
                    SelStart := strtointdef(buffer,-1);
                    if(HWND(lp) = hwndEdit3) then
                      SelEnd := LOWORD(SendMessage(hTrack1,UDM_GETPOS,0,0))
                    else
                      SelEnd := LOWORD(SendMessage(hTrack2,UDM_GETPOS,0,0));

                    // reset to maximum
                    if(SelStart > SelEnd) then
                    begin
                      SelStart := SelEnd;
                      fillchar(buffer,sizeof(buffer),#0);
                      lstrcpy(buffer,pchar(inttostr(SelStart)));
                      SendMessage(HWND(lp),WM_SETTEXT,0,LPARAM(@buffer));
                    end;

                    // If Edit3 is changed, then adjust the position of Edit4.
                    if(HWND(lp) = hwndEdit3) then
                    begin
                      SelEnd := LOWORD(SendMessage(hTrack2,UDM_GETPOS,0,0));
                      if(SelStart > SelEnd) then
                      begin
                        inc(SelStart);
                        fillchar(buffer,sizeof(buffer),#0);
                        wvsprintf(buffer,'%d',pchar(@SelStart));
                        SendMessage(hwndEdit4,WM_SETTEXT,0,LPARAM(@buffer));
                      end;
                    end
                    // If Edit4 is changed, then adjust the position of Edit3.
                    else if(HWND(lp) = hwndEdit4) then
                    begin
                      SelEnd := LOWORD(SendMessage(hTrack1,UDM_GETPOS,0,0));
                      if(SelStart < SelEnd) then
                      begin
                        dec(SelStart);
                        fillchar(buffer,sizeof(buffer),#0);
                        wvsprintf(buffer,'%d',pchar(@SelStart));
                        SendMessage(hwndEdit3,WM_SETTEXT,0,LPARAM(@buffer));
                      end;
                    end;
                  end;
                end;
            end;
        end;
      end;
    // Automatically adjust the positions of the Up/Down controls if necessary.
    WM_NOTIFY:
      with PNMUPDOWN(lp)^ do
        if(hdr.code = UDN_DELTAPOS) then
          // If the position in the first Up/Down control increases,
          // the position of the second Up/Down control must be checked
          // and increased if necessary.
          if(hdr.hwndFrom = hTrack1) then
          begin
            // "iDelta" is positive if the "Up" arrow
            // was clicked
            if(iDelta >= 0) then
            begin
              SelEnd := LOWORD(SendMessage(hTrack2,UDM_GETPOS,0,0));
              // "iPos" contains the current position, therefore
              // the successor must be used
              if(SelEnd <= iPos + 1) then
                // and since the position must be one larger
                // than the successor of "iPos",
                // we therefore set the successor of the successor ...
                SendMessage(hTrack2,UDM_SETPOS,0,MAKELONG(iPos + 2,0));
            end;
          end
          // On the other hand, the position of the 2nd
          // The Up/Down controls should not be smaller than the first one.
          else if(hdr.hwndFrom = hTrack2) then
          begin
            // "iDelta" is negative if the "down" arrow points
            // was clicked
            if(iDelta < 0) then
            begin
              SelEnd := LOWORD(SendMessage(hTrack1,UDM_GETPOS,0,0));
              if(SelEnd >= iPos - 1) then
                SendMessage(hTrack1,UDM_SETPOS,0,MAKELONG(iPos - 2,0));
            end;
          end;
    else
      Result := DefWindowProc(wnd, uMsg, wp, lp);
  end;
end;

//
// MAIN
//
const
  ClassName    = 'WndClass';
  WindowWidth  = 425;
  WindowHeight = 200;
var
  wc   : TWndClassEx = (
    cbSize          : SizeOf(TWndClassEx);
    Style           : CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc     : @WndProc;
    cbClsExtra      : 0;
    cbWndExtra      : 0;
    lpszMenuName    : nil;
    lpszClassName   : ClassName;
    hIconSm         : 0;
  );
  msg  : TMsg;
  aWnd : HWND;
begin
  if(CoInitializeEx(nil,COINIT_APARTMENTTHREADED) = S_OK) then
  try
    // for "UpDown"-Control
    InitCommonControls;

    // Register window class, & display window
    wc.hInstance     := hInstance;
    wc.hbrBackground := GetSysColorBrush(COLOR_3DFACE);
    wc.hIcon         := LoadIcon(hInstance, MAKEINTRESOURCE(100));
    wc.hCursor       := LoadCursor(0, IDC_ARROW);
    if(RegisterClassEx(wc) = 0) then exit;

    aWnd := CreateWindowEx(0,ClassName,AppName,WS_CAPTION or WS_VISIBLE or
      WS_SYSMENU,integer(CW_USEDEFAULT),integer(CW_USEDEFAULT),WindowWidth,
      WindowHeight,0,0,hInstance, nil);
    if(aWnd = 0) then exit;
    ShowWindow(aWnd,SW_SHOW);
    UpdateWindow(aWnd);

    // Message loop
    while(GetMessage(msg,0,0,0)) do
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;

    ExitCode := msg.wParam;
  finally
    CoUninitialize;
  end;
end.
