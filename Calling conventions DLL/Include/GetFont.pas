function GetFont(hwnd: Cardinal; pointsize, weight: integer; fixedwidth: boolean{$IFDEF DELPHI4UP} = false{$ENDIF}): THandle;
(*
  Functionality:
    This function returns the handle to the specified font, either Courier or
    Arial.
    [GENERIC]
*)
const
  arial = 'Arial';
  courier = 'Courier New';
var
  DC: HDC;
begin
// Get DC
  DC := GetWindowDC(hwnd);
  case fixedwidth of
    true:
// Create font w/ fixed width (eg.: Courier)
      result := CreateFont(-MulDiv(pointsize, GetDeviceCaps(DC, LOGPIXELSY),
        72), 0, 0, 0, weight, 0, 0, 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS,
        PROOF_QUALITY, FIXED_PITCH or FF_MODERN, @courier[1]);
  else
// Create font w/ variable width (eg.: Arial)
    result := CreateFont(-MulDiv(pointsize, GetDeviceCaps(DC, LOGPIXELSY), 72),
      0, 0, 0, weight, 0, 0, 0, ANSI_CHARSET, OUT_TT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY,
      VARIABLE_PITCH or FF_DONTCARE, @arial[1]);
  end;
// Free DC
  ReleaseDC(hwnd, DC);
end;

