

function IsRadionBtnChecked(Dlg: THandle; Id: Integer): Boolean;
begin
  Result := SendDlgItemMessage(Dlg, Id, BM_GETCHECK, 0, 0) = BST_CHECKED;
end;

function GetItemText(Dlg: THandle; Id: Integer): string;
var
  len: Integer;
begin
  len := SendDlgItemMessage(Dlg, Id, WM_GETTEXTLENGTH, 0, 0);
  SetLength(Result, len);
  GetDlgItemText(Dlg, Id, @Result[1], len + 1);
end;

procedure SetDlgItemText(Dlg: THandle; ID: Integer; Text: string);
begin
  SendDlgItemMessage(Dlg, ID, WM_SETTEXT, 0, Integer(@Text[1])); 
end;