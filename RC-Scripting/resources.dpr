program resources;

uses
  Windows,
  Messages,
  MSysUtils in 'MSysUtils.pas';

{$R resource.res}
{$R vi.res}


type
  // Record for the RCDATA resource
  TRCDataRec = packed record
    Value1: Word;
    Value2: LongWord;
    Str: packed array[0..10] of Char;
  end;
  PRCDataRec = ^TRCDataRec;


const
  CID_IMAGE = 102;      // The LTEXT for the image
  CID_ST1 = 104;        // The LTEXT for the first stringtable entry
  CID_ST2 = 105;        // The LTEXT for the second string table entry
  CID_RC1 = 107;        // The LTEXT for the first RCDATA value
  CID_RC2 = 108;        // The LTEXT for the second RCDATA value
  CID_RC3 = 109;        // The LTEXT for the third RCDATA value

  CID_ABOUT_OK = 152;   // The OK button in the About window
  CID_EXIT = 201;       // The Exit entry in the window menu
  CID_ABOUT = 202;      // The About entry in the window menu
  CID_MENU_HELLO = 301; // The Hello entry in the context menu

  CID_LABEL1 = 153;
  CID_LABEL2 = 154;


var
  hBMP: hBitmap;
  Buffer: PChar;

  hMod: hModule;
  hRes: HRSRC;
  hData: hGlobal;
  RCDataRec: TRCDataRec;



function aboutfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        SetDlgItemText(hDlg,CID_LABEL1,
          pchar(GetFileInfo(paramstr(0),'FileDescription')));
        SetDlgItemText(hDlg,CID_LABEL2,
          pchar(GetFileInfo(paramstr(0),'LegalCopyright')));
      end;
    WM_COMMAND:
      case HiWord(wParam) of
        BN_CLICKED:
          case LoWord(wParam) of
            // Close window when "OK" was pressed
            CID_ABOUT_OK: EndDialog(hDlg, 0);
          end;
      end;
    WM_CLOSE:
      EndDialog(hDlg, 0);
    else
      result := false;
  end;
end;



function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  Menu: HMenu;
  CPos: TPoint;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        // Load the image and assign it to the text control
        hBMP := LoadImage(hInstance, MAKEINTRESOURCE(1100), IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR);
        SendDlgItemMessage(hDlg, CID_IMAGE, STM_SETIMAGE, IMAGE_BITMAP, hBMP);

        // Load the icon and assign it to the window (in one line)
        SendMessage(hDlg, WM_SETICON, ICON_SMALL, LoadImage(hInstance, MAKEINTRESOURCE(1101), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR));

        // Read and display stringtable entries
        GetMem(Buffer, 33); // Length('A string from a string table") + 1
        LoadString(hInstance, 400, Buffer, 33);
        SendDlgItemMessage(hDlg, CID_ST1, WM_SETTEXT, 0, Integer(Buffer));

        GetMem(Buffer, 15); // Length('And another one") + 1
        LoadString(hInstance, 401, Buffer, 15);
        SendDlgItemMessage(hDlg, CID_ST2, WM_SETTEXT, 0, Integer(Buffer));


        // Read and display RCDATA data
        hMod := LoadLibrary(PChar(paramstr(0)));
        hRes := FindResource(hMod, MAKEINTRESOURCE(1102), RT_RCDATA);
        hData := LoadResource(hMod, hRes);
        RCDataRec := PRCDataRec(LockResource(hData))^;
        SendDlgItemMessage(hDlg, CID_RC1, WM_SETTEXT, 0, Integer(PChar(IntToStr(RCDataRec.Value1))));
        SendDlgItemMessage(hDlg, CID_RC2, WM_SETTEXT, 0, Integer(PChar(IntToStr(RCDataRec.Value2))));
        SendDlgItemMessage(hDlg, CID_RC3, WM_SETTEXT, 0, Integer(String(RCDataRec.Str)));
      end;

    WM_COMMAND:
      case HiWord(wParam) of
        BN_CLICKED:
          case LoWord(wParam) of
            CID_EXIT:
              PostQuitMessage(0);
            CID_ABOUT:
              DialogBox(hInstance, MAKEINTRESOURCE(150), 0, @aboutfunc);
            CID_MENU_HELLO:
              MessageBox(hDlg, 'Hello, world', 'Answer', MB_OK);
          end;
      end;

    WM_RBUTTONDOWN:
      begin
        // Load the context menu and display it at the current mouse position
        Menu := LoadMenu(hInstance, MAKEINTRESOURCE(300));
        GetCursorPos(CPos);
        TrackPopupMenu(GetSubMenu(Menu, 0), TPM_LeftAlign or TPM_TopAlign, CPos.X, CPos.Y, 0, hDlg, nil);
        DestroyMenu(Menu);
      end;

    WM_CLOSE:
      PostQuitMessage(0);

    else
      result := false;
  end;
end;



var
  hDialog: THandle;
  msg: TMsg;
begin
  hDialog := CreateDialog(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);

  while GetMessage(msg,0,0,0) do
  begin
    IsDialogMessage(hDialog, msg);
  end;
  ExitCode := msg.wParam;

  DestroyWindow(hDialog);
end.
