{$INCLUDE .\Include\FormatString.pas}

Procedure SetOutput_(hwnd:HWND; param1, param2, param3: Cardinal; const name: String; fromDLL: boolean);
begin
  case fromDLL of
    TRUE:
      begin
        SendMessage(GetDlgItem(hwnd, IDC_EDIT8),WM_SETTEXT, 0, Longint(@Format(frmt_str, [param1])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT9), WM_SETTEXT, 0, Longint(@Format(frmt_str, [param2])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT10), WM_SETTEXT, 0, Longint(@Format(frmt_str, [param3])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT14), WM_SETTEXT, 0, Longint(@Format(frmt_str, [hwnd])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT15), WM_SETTEXT, 0, Longint(@name[1]));
      end;
    FALSE:
      begin
        SendMessage(GetDlgItem(hwnd, IDC_EDIT1), WM_SETTEXT, 0, Longint(@Format(frmt_str, [param1])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT2), WM_SETTEXT, 0, Longint(@Format(frmt_str, [param2])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT3), WM_SETTEXT, 0, Longint(@Format(frmt_str, [param3])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT7), WM_SETTEXT, 0, Longint(@Format(frmt_str, [hwnd])[1]));
        SendMessage(GetDlgItem(hwnd, IDC_EDIT15), WM_SETTEXT, 0, Longint(@name[1]));
      end;
  end;
end;

