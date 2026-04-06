const
  frmt_str = '0x%8.8X';
  IDD_DIALOG1 = 101;
  IDI_ICON1 = 1;
  IDC_EDIT1 = 1000;
  IDC_EDIT2 = 1001;
  IDC_EDIT3 = 1002;
  IDC_EDIT7 = 1006;
  IDC_EDIT8 = 1007;
  IDC_EDIT9 = 1008;
  IDC_EDIT10 = 1009;
  IDC_EDIT14 = 1013;
  IDC_BUTTON1 = 1014;
  IDC_BUTTON2 = 1015;
  IDC_BUTTON3 = 1016;
  IDC_BUTTON4 = 1017;
  IDC_BUTTON5 = 1018;
  IDC_BUTTON6 = 1019;
  IDC_BUTTON7 = 1020;
  IDC_BUTTON8 = 1021;
  IDC_BUTTON9 = 1022;
  IDC_EDIT15 = 1023;

const
//the more params, the more problems, if using the wrong calling convention
  param1 = 1;
  param2 = 2;
  param3 = 3;
  exc_text = 'Ausnahmefehler aufgetreten!';
  origproc = 'OrigWndProc';
  dll_notloaded = 'DLL nicht geladen.';
  noentry = 'Keinen Eintrittspunkt für die Funktion gefunden!';

const
(*
  Die Namen der zu importierenden Funktionen vordeklarieren.
  Name der DLL darf auch nicht fehlen.
*)
  szNameOneFunction = 'OneFunction';
  szNameOneFunction_CDECL = 'OneFunction_CDECL';
  szNameOneFunction_STDCALL = 'OneFunction_STDCALL';
  szNameDLL = 'SampleDLL.DLL';


