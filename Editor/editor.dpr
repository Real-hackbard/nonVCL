program editor;

uses
  Windows,
  Messages,
  CommDlg,
  RichEdit,
  MSysUtils in 'MSysUtils.pas';

{$R resource.res}
{$R menu.res}



//
// for the help
//
const
  szHelpMsgArray : array[0..4]of string =
    ('Font dialog',
     'Search dialog',
     'Search and Replace dialog',
     'Open dialog',
     'Save dialog');
var
  HelpMsgId      : UINT = 0;
  iHelpContext   : integer = 0;


//
// Open & save files
//
const
  Filter        =
    'Textfiles (*.txt)'#0'*.txt'#0'Alle Dateien (*.*)'#0'*.*'#0#0;
  MEMSIZE       = 65535;
var
  ofn           : TOpenFileName;
  buffer        : array[0..260] of Char;
  hFile         : Cardinal;
  hMemory       : Cardinal;
  pMemory       : Pointer;
  SizeReadWrite : DWORD = 0;


procedure OpenFile(const wnd, hwndEdit: HWND);
begin
  // Empty text buffer
  ZeroMemory(@buffer,sizeof(buffer));

  // Initialize "TOpenFileName" record
  ZeroMemory(@ofn,sizeof(ofn));
  ofn.lStructSize := SizeOf(ofn);
  ofn.hWndOwner   := wnd;
  ofn.lpstrFilter := Filter;
  ofn.lpstrFile   := buffer;
  ofn.nMaxFile    := 256;
  ofn.Flags       := OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or
    OFN_LONGNAMES or OFN_SHOWHELP;

  // Context ID for help
  iHelpContext    := 3;

  // Open the "Open File" dialog box
  if(GetOpenFileName(ofn)) then begin
    // Open file
    hFile := CreateFile(buffer,GENERIC_READ  or GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL,0);
    // Request storage
    hMemory := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT,MEMSIZE);
    // Set pointer to memory address, ...
    pMemory := GlobalLock(hMemory);
    // ... & Read file
    ReadFile(hFile,pMemory^,MEMSIZE-1,SizeReadWrite,nil);

    // Load file into Edit
    SendMessage(hwndEdit,WM_SETTEXT,0,LPARAM(pMemory));
    SendMessage(hwndEdit,EM_SETSEL,0,0);

    // Clean up
    CloseHandle(hFile);
    GlobalUnlock(CARDINAL(pMemory));
    GlobalFree(hMemory);
  end;
end;

procedure SaveFile(const wnd, hwndEdit: HWND);
begin
  // Empty text buffer
  ZeroMemory(@buffer,sizeof(buffer));

  // Initialize "TOpenFileName" record
  ZeroMemory(@ofn,sizeof(ofn));
  ofn.lStructSize := SizeOf(TOpenFileName);
  ofn.hWndOwner   := wnd;
  ofn.lpstrFilter := Filter;
  ofn.lpstrFile   := buffer;
  ofn.lpstrDefExt := 'txt';
  ofn.nMaxFile    := 256;
  ofn.Flags       := OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or
    OFN_OVERWRITEPROMPT or OFN_SHOWHELP;

  // Context ID for help
  iHelpContext    := 4;

  // Open the "Save file as" dialog box
  if(GetSaveFileName(ofn)) then begin
    // Open file
    hFile := CreateFile(buffer,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ
      or FILE_SHARE_WRITE,nil,CREATE_NEW,FILE_ATTRIBUTE_NORMAL,0);
    // Request storage
    hMemory := GlobalAlloc(GMEM_MOVEABLE or GMEM_ZEROINIT, MEMSIZE);
    // Set pointer to memory address, ...
    pMemory := GlobalLock(hMemory);
    // ... Determine the number of bytes to be written, ...
    SizeReadWrite := SendMessage(hwndEdit,WM_GETTEXT,MEMSIZE-1,
      LPARAM(pMemory));
    // .... & Write file
    WriteFile(hFile,pMemory^,SizeReadWrite,SizeReadWrite,nil);

    // Clean up
    CloseHandle(hFile);
    GlobalUnlock(CARDINAL(pMemory));
    GlobalFree(hMemory);
  end;
end;


//
// Select font
//
var
  lf             : TLogFont;

function SelectFont(const hwndEdit: HWND): boolean;
var
  cf  : TChooseFont;
  mf  : HFONT;
begin
  ZeroMemory(@cf,sizeof(cf));
  cf.lStructSize  := sizeof(cf);
  cf.hWndOwner    := GetParent(hwndEdit);
  cf.lpLogFont    := @lf;
  cf.Flags        := CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT or
    CF_NOSCRIPTSEL or CF_SHOWHELP;

  // Context ID for help
  iHelpContext    := 0;

  // Open dialog
  Result          := ChooseFont(cf);
  if(Result) then begin
    mf            := CreateFontIndirect(lf);
    if(mf <> 0) then
      SendMessage(hwndEdit,WM_SETFONT,WPARAM(mf),LPARAM(false));
  end;
end;


//
// Search & Replace dialog (code snippets from NicoDE)
//
const
  IDC_EDIT       = 1;
var
  RichEdit10     : boolean = false;
  RichEdit20     : boolean = false;
  fnd            : TFindReplace;
  FindStr,
  ReplStr        : array[0..4096]of char;
  FindLen        : DWORD = sizeof(FindStr) - 1;
  FindTextMsgId  : UINT;
  hDlg           : HWND = 0;

procedure SearchText(const wnd: HWND; Text: pchar; Down, Sense, Whole: Bool);
var
  rEdit   : HWND;
  Flags   : integer;
  FindRec : TFindText;
  FindPos : integer;
  ErrMsg  : array[0..4096]of Char;
begin
  rEdit := GetDlgItem(wnd,IDC_EDIT);

  if(rEdit <> 0) then begin
    // is text highlighted?
    SendMessage(rEdit,EM_EXGETSEL,0,LPARAM(@FindRec.chrg));

    // Set new search position
    if(Down) then FindRec.chrg.cpMin := FindRec.chrg.cpMax;
    FindRec.chrg.cpMax   := -1;
    FindRec.lpstrText    := Text;

    // Flags
    Flags                := 0;
    if(Down) then Flags  := FR_DOWN;
    if(Sense) then Flags := Flags or FR_MATCHCASE;
    if(Whole) then Flags := Flags or FR_WHOLEWORD;

    // Text search
    FindPos              := SendMessage(rEdit,EM_FINDTEXT,
      Flags,LPARAM(@FindRec));

    // If found, then mark., ...
    if(FindPos > 0) then begin
      FindRec.chrg.cpMin := FindPos;
      FindRec.chrg.cpMax := FindPos + lstrlen(Text);
      SendMessage(rEdit,EM_EXSETSEL,0,LPARAM(@FindRec.chrg));
    // ... or display error message
    end else begin
      lstrcpy(ErrMsg,pchar('"' + Text + '"'));
      lstrcat(ErrMsg,' cannot be found.');
      MessageBox(wnd,ErrMsg,'editor',MB_ICONINFORMATION);
    end;
  end;
end;

procedure ReplText(const wnd: HWND; OldText, NewText: pchar;
  Down, Sense, Whole, ReplaceAll: Bool);
var
  rEdit   : HWND;
  Flags   : integer;
  FindRec : TFindText;
  FindPos : integer;
  ErrMsg  : array[0..4096]of Char;
  fFound  : boolean;
begin
  rEdit   := GetDlgItem(wnd,IDC_EDIT);
  fFound  := false;

  if(rEdit <> 0) then
    repeat
      // Set new search position
      SendMessage(rEdit,EM_EXGETSEL,0,LPARAM(@FindRec.chrg));
      FindRec.chrg.cpMin   := FindRec.chrg.cpMax;
      FindRec.chrg.cpMax   := -1;
      FindRec.lpstrText    := OldText;

      // Flags
      Flags                := 0;
      if(Down) then Flags  := FR_DOWN;
      if(Sense) then Flags := Flags or FR_MATCHCASE;
      if(Whole) then Flags := Flags or FR_WHOLEWORD;

      // search for old text
      FindPos              := SendMessage(rEdit,EM_FINDTEXT,
        Flags,LPARAM(@FindRec));

      if(FindPos > 0) then begin
        // Mark found text, ...
        FindRec.chrg.cpMin := FindPos;
        FindRec.chrg.cpMax := FindPos + lstrlen(OldText);
        SendMessage(rEdit,EM_EXSETSEL,0,LPARAM(@FindRec.chrg));

        // ... & substitute
        SendMessage(rEdit,EM_REPLACESEL,WPARAM(true),LPARAM(NewText));

        // Suppress error messages when something has been replaced!
        fFound := true;
      end else if(not fFound) then begin
        // or display error message
        lstrcpy(ErrMsg,pchar('"' + OldText + '"'));
        lstrcat(ErrMsg,' cannot be found.');
        MessageBox(wnd,ErrMsg,'editor',MB_ICONINFORMATION);
      end;
    until(FindPos <= 0) or (not ReplaceAll);
end;

procedure Find(const wnd: HWND; fReplaceMode: boolean);
const
  sFlag    : array[boolean]of cardinal =
    (FR_HIDEUPDOWN or FR_DOWN,FR_DOWN);
  sHelpCtx : array[boolean]of integer =
    (1,2);
begin
  fnd.lStructSize   := sizeof(TFindReplace);
  fnd.hWndOwner     := wnd;
  fnd.Flags         := sFlag[RichEdit20 and (not fReplaceMode)] or
    FR_SHOWHELP;
  fnd.lpstrFindWhat := FindStr;
  fnd.wFindWhatLen  := FindLen;

  if(fReplaceMode) then begin
    fnd.lpstrReplaceWith := ReplStr;
    fnd.wReplaceWithLen  := FindLen;
  end;

  // Context ID for help
  iHelpContext    := sHelpCtx[fReplaceMode];

  // "FINDMSGSTRING" for search/replace
  FindTextMsgId   := RegisterWindowMessage(FINDMSGSTRING);

  if(fReplaceMode) then hDlg := CommDlg.ReplaceText(fnd)
    else hDlg := CommDlg.FindText(fnd);
end;


//
// Message function
//
const
  ClassName    = 'WndClass';
  AppName      = 'Editor';
  WindowWidth  = 500;
  WindowHeight = 350;

  IDM_NEW      = 6001;
  IDM_OPEN     = 6002;
  IDM_SAVEAS   = 6003;
  IDM_CLOSE    = 6004;
  IDM_FONT     = 6005;
  IDM_SEARCH   = 6006;
  IDM_REPLACE  = 6007;

var
  hEdit        : HWND;


function WndProc(wnd: HWND; uMsg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
  stdcall;
const
  fSearchState : array[boolean]of cardinal = (MF_GRAYED,0);
  dwEditFlags  = WS_CHILD or WS_VISIBLE or WS_VSCROLL or
    ES_MULTILINE or ES_NOHIDESEL;
var
  x,
  y            : integer;
  FindParam    : PFindReplace;
  mf           : HFONT;
begin
  Result := 0;

  case uMsg of
    WM_CREATE:
      begin
        // Center window
        x := GetSystemMetrics(SM_CXSCREEN);
        y := GetSystemMetrics(SM_CYSCREEN);
        MoveWindow(wnd, (x div 2) - (WindowWidth div 2),
          (y div 2) - (WindowHeight div 2),
          WindowWidth, WindowHeight, true);

        // RichEdit 2.0 create
        hEdit := CreateWindowEx(WS_EX_CLIENTEDGE,'RichEdit20A',nil,
          dwEditFlags,0,0,0,0,wnd,IDC_EDIT,hInstance,nil);
        RichEdit20 := (hEdit <> 0);

        // RichEdit 1.0 generate if R2.0 is not possible
        if(not RichEdit20) then
          hEdit := CreateWindowEx(WS_EX_CLIENTEDGE,'RICHEDIT',nil,
            dwEditFlags,0,0,0,0,wnd,IDC_EDIT,hInstance,nil);
        RichEdit10 := (hEdit <> 0);

        // RichEdit 1.0 is also not possible., :o(
        if(not RichEdit10) and (not RichEdit20) then
          hEdit := CreateWindowEx(WS_EX_CLIENTEDGE,'Edit',nil,
            dwEditFlags,0,0,0,0,wnd,IDC_EDIT,hInstance,nil);

        // What's going on? Is nothing working at all? :o(
        if(hEdit = 0) then SendMessage(wnd,WM_CLOSE,0,0);

        // Focus on the input field
        SetFocus(hEdit);

        // Make search/replace disappear if no RichEdits are present.
        // could be generated
        if(not RichEdit10) and (not RichEdit20) then
          RemoveMenu(GetMenu(wnd),2,MF_BYPOSITION);

        // RichEdit should trigger "EN_CHANGE".
        // (to activate search/replace)
        if(RichEdit10) or (RichEdit20) then
          SendMessage(hEdit,EM_SETEVENTMASK,0,ENM_CHANGE);

        // Adjust font
        if(GetObject(GetStockObject(SYSTEM_FONT),sizeof(lf),@lf) =
          sizeof(lf)) then
        begin
          mf := CreateFontIndirect(lf);
          if(mf <> 0) then
            SendMessage(hEdit,WM_SETFONT,WPARAM(mf),LPARAM(false));
        end;

        // Register "HELPMSGSTRING"
        HelpMsgId := RegisterWindowMessage(HELPMSGSTRING);
      end;
    WM_SIZE:
      MoveWindow(hEdit,0,0,LOWORD(lp),HIWORD(lp),true);
    WM_DESTROY:
      PostQuitMessage(0);
    WM_COMMAND:
      case HIWORD(wp) of
        BN_CLICKED:
          case LOWORD(wp) of
            IDM_NEW:
              SetWindowText(hEdit,nil);
            IDM_OPEN:
              OpenFile(wnd, hEdit);
            IDM_SAVEAS:
              SaveFile(wnd, hEdit);
            IDM_CLOSE:
              SendMessage(wnd, WM_CLOSE, 0, 0);
            IDM_FONT:
              SelectFont(hEdit);
            IDM_SEARCH,
            IDM_REPLACE:
              Find(wnd,LOWORD(wp)=IDM_REPLACE);
          end;
        EN_CHANGE:
          begin
            EnableMenuItem(GetMenu(wnd),IDM_SEARCH,MF_BYCOMMAND or
              fSearchState[GetWindowTextLength(hEdit) > 0]);
            EnableMenuItem(GetMenu(wnd),IDM_REPLACE,MF_BYCOMMAND or
              fSearchState[GetWindowTextLength(hEdit) > 0]);
          end;
      end;
    // Search function
    else if(FindTextMsgId <> 0) and (uMsg = FindTextMsgId) then begin
      FindParam := PFindReplace(lp);

      if(FindParam.Flags and FR_FINDNEXT = FR_FINDNEXT) then
        SearchText(FindParam.hWndOwner,FindParam.lpstrFindWhat,
          FindParam.Flags and FR_DOWN = FR_DOWN,
          FindParam.Flags and FR_MATCHCASE = FR_MATCHCASE,
          FindParam.Flags and FR_WHOLEWORD = FR_WHOLEWORD)
      else if(FindParam.Flags and FR_REPLACE = FR_REPLACE) or
        (FindParam.Flags and FR_REPLACEALL = FR_REPLACEALL) then
        ReplText(FindParam.hWndOwner,FindParam.lpstrFindWhat,
          FindParam.lpstrReplaceWith,
          FindParam.Flags and FR_DOWN = FR_DOWN,
          FindParam.Flags and FR_MATCHCASE = FR_MATCHCASE,
          FindParam.Flags and FR_WHOLEWORD = FR_WHOLEWORD,
          FindParam.Flags and FR_REPLACEALL = FR_REPLACEALL);
    end
    // Show help for each dialog
    else if(HelpMsgId <> 0) and (uMsg = HelpMsgId) then
      MessageBox(wnd,pchar(Format('Your help for %s could appear here',
        [szHelpMsgArray[iHelpContext]])),nil,0)
    else
      Result := DefWindowProc(wnd, uMsg, wp, lp);
  end;
end;

var
  wc : TWndClassEx = (
    cbSize        : SizeOf(TWndClassEx);
    Style         : CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc   : @WndProc;
    cbClsExtra    : 0;
    cbWndExtra    : 0;
    hbrBackground : COLOR_APPWORKSPACE;
    lpszMenuName  : nil;
    lpszClassName : ClassName;
    hIconSm       : 0;
  );
  msg : TMsg;
begin
  LoadLibrary('riched20.dll'); // RichEdit 2.0
  LoadLibrary('riched32.dll'); // RichEdit

  // Register class
  wc.hInstance  := hInstance;
  wc.hIcon      := LoadIcon(hInstance,MAKEINTRESOURCE(100));
  wc.hCursor    := LoadCursor(0,IDC_ARROW);
  if(RegisterClassEx(wc) = 0) then exit;

  // Fcreate windows
  if(CreateWindowEx(0,ClassName,AppName,WS_CAPTION or WS_VISIBLE or
    WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SIZEBOX,
    Integer(CW_USEDEFAULT),Integer(CW_USEDEFAULT),WindowWidth,WindowHeight,
    0,LoadMenu(hInstance,MAKEINTRESOURCE(6000)),hInstance,nil) = 0) then exit;

  // Message loop
  while(GetMessage(msg,0,0,0)) do
    if(not IsDialogMessage(hDlg,msg)) then begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;

  ExitCode := msg.wParam;
end.
