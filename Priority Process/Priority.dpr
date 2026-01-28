program Priority;

uses
  windows, messages, CommCtrl, ShellAPI;

{$R resource.res}
{$INCLUDE AppTools.inc}

const
  FontName = 'Tahoma';
  FontSize = -18;

const

  IDC_CBPROCPRIO = 102;
  IDC_CBTHREADPRIO = 103;
  IDC_EDTSLEEP = 104;
  IDC_BTNSUSPEND = 105;
  IDC_LSTOUTPUT = 106;

  BELOW_NORMAL_PRIORITY_CLASS = $4000;  //  minimum OS: Windows
  ABOVE_NORMAL_PRIORITY_CLASS = $8000;  //  minimum OS: Windows
  THREAD_SUSPEND_RESUME = $0002;

var
  hApp: Cardinal;
  //  Prozess-Prioritäten
  ProcPrioText: array[0..4] of string = ('High', 'Higher than normal', 'Normal',
    'Lower than normal', 'idle');
  ProcPrioClasses: array[0..4] of Integer = (HIGH_PRIORITY_CLASS,
    ABOVE_NORMAL_PRIORITY_CLASS, NORMAL_PRIORITY_CLASS,
    BELOW_NORMAL_PRIORITY_CLASS, IDLE_PRIORITY_CLASS);
  //  Thread-Prioritäten
  ThreadPrioText: array[0..6] of string = ('Time critical', 'Maximum',
    'Higher than normal', 'Normal', 'Lower than normal', 'Minimum',
    'idle');
  ThreadPrioClasses: array[0..6] of Integer = (THREAD_PRIORITY_TIME_CRITICAL,
    THREAD_PRIORITY_HIGHEST, THREAD_PRIORITY_ABOVE_NORMAL,
    THREAD_PRIORITY_NORMAL,
    THREAD_PRIORITY_BELOW_NORMAL, THREAD_PRIORITY_LOWEST, THREAD_PRIORITY_IDLE);

  PPrimaryThreadHandle: ^THandle;  //  -> DuplicateHandle

  whitebrush: HBRUSH = 0;
  WhiteLB: TLogBrush =
  (
    lbStyle: BS_SOLID;
    lbColor: $00FFFFFF;
    lbHatch: 0
    );
////////////////////////////////////////////////////////////////////////////////
//  Little helper -> no SysUtils

function IntToStr(Int: integer): string;
begin
  Str(Int, result);
end;

////////////////////////////////////////////////////////////////////////////////
// Fill the combo box for the process priorities

procedure FillCBProcPrio;
var
  Loop, n: Integer;
begin
  for Loop := 0 to length(ProcPrioText) - 1 do
  begin
    //  Add entry from array
    n := SendDlgItemMessage(hApp, IDC_CBPROCPRIO, CB_ADDSTRING, 0,
      Integer(@ProcPrioText[Loop][1]));
    //  Save priority class as ObjectData
    SendDlgItemMessage(Happ, IDC_CBPROCPRIO, CB_SETITEMDATA, n,
      ProcPrioClasses[Loop]);
  end;
  SendDlgItemMessage(hApp, IDC_CBPROCPRIO, CB_SETCURSEL, 2, 0);
end;

////////////////////////////////////////////////////////////////////////////////
//  Fill combo box for thread priorities

procedure FillCBThreadPrio;
var
  Loop, n: Integer;
begin
  for Loop := 0 to length(ThreadPrioText) - 1 do
  begin
    //  Add entry from array
    n := SendDlgItemMessage(hApp, IDC_CBTHREADPRIO, CB_ADDSTRING, 0,
      Integer(@ThreadPrioText[Loop][1]));
    //  Save priority class as ObjectData
    SendDlgItemMessage(Happ, IDC_CBTHREADPRIO, CB_SETITEMDATA, n,
      ThreadPrioClasses[Loop]);
  end;
  SendDlgItemMessage(hApp, IDC_CBTHREADPRIO, CB_SETCURSEL, 3, 0);
end;

////////////////////////////////////////////////////////////////////////////////
//  Thread function for the second thread

function SecondaryThread(p: Pointer): Integer;
var
  hThread: THandle;
  s: string;
begin
  result := 0;
  hThread := THandle(p^);
  //  stop primary thread
  SuspendThread(hThread);
  //  Text for message box
  s := 'The primary thread [' + IntToStr(hThread) + '] was interrupted.'+
    #13#10;
  s := s + 'It neither responds to input nor has an output.' + #13#10#13#10;
  s := s + 'Click OK to return to the primary thread'+#13#10;
  s := s + 'and terminate the secondary thread.';
  Messagebox(hThread, pointer(s), 'Secondary thread', MB_ICONWARNING);
  //  restart primary thread
  ResumeThread(hThread);
  //  Close thread handle
  CloseHandle(hThread);
  EnableWindow(hApp, True);
end;

////////////////////////////////////////////////////////////////////////////////
//  Dialog-Prozedure

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  MyFont: HFONT;
  s: string;
  ThreadHandle: THandle;
  ThreadID: LongWord;
  Index: Integer;
  PrioClass: DWORD;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hApp := hDlg;
        { icon }
        if SendMessage(hDlg, WM_SETICON, ICON_SMALL, Integer(LoadIcon(hInstance,
          MAKEINTRESOURCE(1)))) = 0 then
          SendMessage(hDlg, WM_SETICON, ICON_BIG, Integer(LoadIcon(hInstance,
            MAKEINTRESOURCE(1))));
        { font }
        MyFont := CreateFont(FontSize, 0, 0, 0, 900, 0, 0, 0, ANSI_CHARSET,
          OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
          DEFAULT_PITCH, FontName);
        if MyFont <> 0 then
          SendDlgItemMessage(hDlg, 999, WM_SETFONT, Integer(MyFont),
            Integer(true));
        SetDlgItemText(hDlg, 999, pointer(s));

        FillCBProcPrio();
        FillCBThreadPrio();
        SendDlgItemMessage(hDlg, IDC_EDTSLEEP, EM_LIMITTEXT, 4, 0);
      end;
    WM_CLOSE:
      begin
        DestroyWindow(hDlg);
        PostQuitMessage(0);
      end;
    WM_COMMAND:
      begin
        { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(hDlg, WM_CLOSE, 0, 0);
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            //  Stop primary thread and start secondary
            IDC_BTNSUSPEND:
            begin
              //  Duplicate handle. Duplicate refers to the same thing
              //  Object like the original
              DuplicateHandle(GetCurrentProcess(), GetCurrentThread(),
                GetCurrentProcess(), @PPrimaryThreadHandle, THREAD_SUSPEND_RESUME,
                False, DUPLICATE_SAME_ACCESS);
              //  Start thread and remember handle
              ThreadHandle := BeginThread(nil, 0, @SecondaryThread,
                @PPrimaryThreadHandle, 0, ThreadID);
              //  Thread could be started: thread handle <> 0
              if ThreadHandle <> 0 then
              begin
                //  Disable main window
                EnableWindow(hDlg, False);
                //  Close thread handle
                CloseHandle(ThreadHandle);
              end;
            end;
          end;
        end;
        if hiword(wParam) = CBN_SELCHANGE then
        begin
          case loword(wParam) of
            //  Changing the process priority when changing the CB selection
            IDC_CBPROCPRIO:
            begin
              Index := SendDlgItemMessage(hDlg, IDC_CBPROCPRIO, CB_GETCURSEL, 0, 0);
              // Priority is stored as ObjectData of the CB entries
              PrioClass := SendDlgItemMessage(hDlg, IDC_CBPROCPRIO, CB_GETITEMDATA, Index, 0);
              //  Change priority or issue an error message
              if not SetPriorityClass(GetCurrentProcess(), PrioClass) then
                RaiseLastError(hDlg);
            end;
            //  changing thread priority when CB selection changes
            IDC_CBTHREADPRIO:
            begin
              Index := SendDlgItemMessage(hDlg, IDC_CBTHREADPRIO, CB_GETCURSEL, 0, 0);
              // Priority is stored as ObjectData of the CB entries
              PrioClass := SendDlgItemMessage(hDlg, IDC_CBTHREADPRIO, CB_GETITEMDATA, Index, 0);
              //  Change priority or issue an error message
              if not SetThreadPriority(GetCurrentThread(), PrioClass) then
                RaiseLastError(hDlg);
            end;
          end;
        end;
      end
  else
    result := false;
  end;
end;

var
  msg: TMsg;
  bQuit: Boolean = FALSE;
  Count: Integer = -1;
  TransSuccess: Bool;

begin
  CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);

  while not bQuit do
  begin
    if PeekMessage(msg, 0, 0, 0, PM_REMOVE) then
    begin
      if IsDialogMessage(hApp, msg) = FALSE then
      begin
        if msg.message = WM_QUIT then
          bQuit := True
        else
        begin
          TranslateMessage(msg);
          DispatchMessage(msg);
        end;
      end;
    end
    //  no messages available -> fill listbox with values
    else
    begin
      Inc(Count);
      SendDlgItemMessage(hApp, IDC_LSTOUTPUT, LB_ADDSTRING, 0,
        Integer(@IntToStr(Count)[1]));
      SendDlgItemMessage(hApp, IDC_LSTOUTPUT, LB_SETCURSEL, Count, 0);
      //  Limit the number of list box entries to 25
      while SendDlgItemMessage(hApp, IDC_LSTOUTPUT, LB_GETCOUNT, 0, 0) > 25 do
        SendDlgItemMessage(hApp, IDC_LSTOUTPUT, LB_DELETESTRING, 0, 0);
      Sleep(GetDlgItemInt(hApp, IDC_EDTSLEEP, TransSuccess, False));
    end;
  end;
  ExitCode := msg.wParam;
end.

