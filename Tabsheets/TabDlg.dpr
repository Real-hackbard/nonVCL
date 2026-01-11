program TabDlg;

uses
  Windows,
  Messages,
  CommCtrl,
  MSysUtils in 'MSysUtils.pas',
  UxTheme in 'UxTheme.pas';

{$R TabDlg.res}

const
  IDC_CLOSE = 102;
  IDC_TAB = 101;

  CNT_TABS = 2; // number of tabs

var
  hTab: THandle; // tab-control handle
  tcItem: TTcItem; // tab-control item structure

  // array for the tabsheet captions
  TabSheetCaptions: array[0..CNT_TABS - 1] of string = ('Tab1', 'Tab2');
  // array for the tabsheet dialog handles
  hTabDlgs: array of Cardinal;

////////////////////////////////////////////////////////////////////////////////
// one window procedure for all tabsheet dialogs

function tabdlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam):
  bool;
  stdcall;
begin
  result := true;
  case uMsg of
    WM_COMMAND:
      begin
        if hiword(wParam) = BN_CLICKED then
        begin
          case loword(wParam) of
            203: Messagebox(hDlg, 'Hello, I am a button on Tab1.', 'Test',
                0);
            301, 302: Messagebox(hDlg,
              'Hello, and I am a button on Tab2.', 'Test', 0);
          end;
        end;
      end;
  else
    result := false;
  end;
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  i, index: Integer;
  hdr: PNMHDR;
  rect: TRect;
begin
  result := true;
  case uMsg of
    WM_INITDIALOG:
      begin
        hTab := GetDlgItem(hDlg, IDC_TAB);
        for i := 0 to CNT_TABS - 1 do
        begin
          // fill TcItem structure
          tcItem.mask := TCIF_TEXT;
          tcItem.pszText := pointer(tabSheetCaptions[i]);
          // insert tab
          SendMessage(hTab, TCM_INSERTITEM, i, Integer(@tcItem));
        end;
        // set length of handle array for the dialog procedures
        setlength(hTabDlgs, CNT_TABS);
        // create dialogs for each tabsheet and assign them to one window procedure
        for i := 0 to length(hTabDlgs) - 1 do
        begin
          hTabDlgs[i] := CreateDialog(hInstance, MAKEINTRESOURCE((i + 2) * 100),
            hDlg, @tabdlgfunc);

          if IsManifestAvailable(paramstr(0)) then
            EnableThemeDialogTexture(hTabDlgs[i], ETDT_ENABLETAB);
        end;
        // find out the rectangle of the first tabsheet
        SendMessage(hTab, TCM_GETITEMRECT, 0, Longint(@rect));
        // position the first dialog in the first tabsheet and make it visible
        SetWindowPos(hTabDlgs[0], 0, 50, (rect.Bottom - rect.Top) + 50, 0, 0,
          SWP_NOSIZE or SWP_NOZORDER or SWP_SHOWWINDOW);
      end;
    WM_CLOSE: EndDialog(hDlg, 0);
    WM_NOTIFY:
      begin
        hdr := PNMHDR(lParam);
        case hdr^.code of
          TCN_SELCHANGE: // tabsheet selection has changed
            begin
              // which tabsheet is selected
              index := SendMessage(hTab, TCM_GETCURSEL, 0, 0);
              // enum all available tabsheets
              for i := 0 to length(hTabDlgs) - 1 do
              begin
                // number of tabsheet does not equal selected tabsheet -> hide it
                if i <> index then
                  ShowWindow(hTabDlgs[i], SW_HIDE)
                else // else make dialog visible
                begin
                  SendMessage(hdr^.hwndFrom, TCM_GETITEMRECT, i,
                    Longint(@rect));
                  SetWindowPos(hTabDlgs[index], 0, 50, (rect.Bottom - rect.Top)
                    + 50, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_SHOWWINDOW);
                end;
              end; // for (enum tabsheets)
            end; // case (TCN_SELCHANGE)
        end; // hdr^.code
      end // WM_NOTIFY
  else
    result := false;
  end;
end;

begin
  if (not IsThemeLibLoaded) and (IsWindowsXp) then
  begin
    MessageBox(0,
      'The "uxtheme.dll" file was not loaded correctly. ' +
        'Some features seem to be missing..',
      nil,
      MB_ICONEXCLAMATION);
    exit;
  end;

  // because of the tabsheet control!!!
  InitCommonControls;

  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.