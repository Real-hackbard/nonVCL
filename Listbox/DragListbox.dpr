program DragListbox;

{$APPTYPE CONSOLE}
{$R resource.res}
{$R DragListbox.res}

uses
  Windows,
  Messages,
  CommCtrl;

const
  IDC_LISTBOX = 101;

var
  DL_MESSAGE: DWORD;
  IsDragging: Boolean = FALSE;
  ItemIdxBeginDrag, ItemIdxDragging, ItemIdxEndDrag: DWORD;

function IntToStr(Int: integer): string;
begin
  Str(Int, result);
end;

function dlgfunc(hDlg: hWnd; uMsg: dword; wParam: wParam; lParam: lParam): bool;
  stdcall;
var
  i: Integer;
  s: string;
  buffer: array[0..255] of Char;
begin
  result := TRUE;
  case uMsg of
    WM_INITDIALOG:
      begin
        // make it a drag listbox, CommonControls needed!
        MakeDragList(GetDlgItem(HDlg, IDC_LISTBOX));
        // register the drag-message AFTER it has been registered using MakeDragList}
        DL_MESSAGE := RegisterWindowMessage(DRAGLISTMSGSTRING);
        // DEBUGG
        writeln('DL_MESSAGE: ', DL_MESSAGE);
        for i := 0 to 20 do
        begin
          s := 'Item' + IntToStr(i);
          SendDlgItemMessage(hDlg, IDC_LISTBOX, LB_ADDSTRING, 0,
            Integer(@s[1]));
        end;
      end;
    WM_CLOSE: EndDialog(hDlg, 0);
  else
    begin
      result := FALSE;
      // message handling of the drag listbox comes here
      if DL_MESSAGE <> 0 then // DL_MESSAGE cannot be WM_NULL (=0)!
        if uMsg = DL_MESSAGE then
          case PDRAGLISTINFO(lParam)^.uNotification of
            DL_BEGINDRAG: // received when an item is selected
              begin
                // get the ItemIndex of the item to be dragged and save it}
                ItemIdxBeginDrag := LBItemFromPt(GetDlgItem(hDlg, IDC_LISTBOX),
                  PDRAGLISTINFO(lParam)^.ptCursor, TRUE);
                IsDragging := FALSE;
                // return the message result explicitly, otherwise we would not
                // recieve DL_DRAGGING
                SetWindowLong(hDlg, DWL_MSGRESULT, Integer(TRUE));
                //  message handled
                Result := True;
                // DEBUGG
                writeln('DL_BEGINDRAG -> Itemindex: ', ItemIdxBeginDrag);
              end;
            DL_DRAGGING: // received while dragging
              begin
                // change the cursor
                SetCursor(LoadCursor(0, IDC_SIZENS));
                // get the current item under the cursor
                ItemIdxDragging := LBItemFromPt(GetDlgItem(hDlg, IDC_LISTBOX),
                  PDRAGLISTINFO(lParam)^.ptCursor, TRUE);
                // draw a small arrow to show where the item is being inserted
                DrawInsert(hDlg, PDRAGLISTINFO(lParam)^.hWnd, ItemIdxDragging);
                // DEBUGG
                writeln('DL_DRAGGING -> over Item: ', ItemIdxDragging);
                // user started dragging
                IsDragging := TRUE;
              end;
            DL_CANCELDRAG: // user cancel dragging by pressing ESCAPE
              begin
                // remove insert icon
                DrawInsert(hDlg, PDRAGLISTINFO(lParam)^.hWnd, -1);
                // we do not drag anymore
                IsDragging := FALSE;
                // DEBUGG
                writeln('DL_CANCELDRAG');
              end;
            DL_DROPPED: // user finished dragging and dropped the item
              if IsDragging then // user has started dragging
              begin
                // where is the cursor?
                ItemIdxEndDrag := LBItemFromPt(GetDlgItem(hDlg, IDC_LISTBOX),
                  PDRAGLISTINFO(lParam)^.ptCursor, TRUE);
                // get the itemtext for old item
                SendDlgItemMessage(hDlg, IDC_LISTBOX, LB_GETTEXT,
                  ItemIdxBeginDrag, Integer(@buffer));
               // adjust item index - index of ItemIdxEndDrag might change if a pre-
               // ceeding item has been deleted. We have to handle this!
                if ItemIdxBeginDrag < ItemIdxEndDrag then
                  dec(ItemIdxEndDrag);
                // delete the old item
                SendDlgItemMessage(hDlg, IDC_LISTBOX, LB_DELETESTRING,
                  ItemIdxBeginDrag, 0);
                // insert the old item at the new position
                SendDlgItemMessage(hDlg, IDC_LISTBOX, LB_INSERTSTRING,
                  ItemIdxEndDrag, Integer(@buffer));
                // remove insert icon
                DrawInsert(hDlg, PDRAGLISTINFO(lParam)^.hWnd, -1);
                // DEBUGG
                writeln('DL_DROPPED -> Itemindex: ', ItemIdxEndDrag,
                  ', Itemtext: ', string(buffer));
              end;
          end; // case (PDRAGLISTINFO(lParam)^.uNotification of)
    end; // else (case uMsg of)
  end; // case (case uMsg of)
end;

begin
  InitCommonControls();
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

