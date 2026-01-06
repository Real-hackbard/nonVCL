{$INCLUDE CompilerSwitches.inc}

unit constants;

interface

uses
  Messages;

const
  IDD_MAIN_DLG = 100;
  IDC_BTN_MACHINE = 110;
  IDC_BTN_DOMAIN = 111;
  IDC_BTN_SCAN = 115;
  IDC_BTN_CANCEL = 106;
  IDC_TRV = 105;
  IDC_BTN_ABOUT = 103;
  IDC_STC_BANNER = 101;
  IDC_STC_DEVIDER = 102;
  IDC_SBR = 114;
  IDC_STC_HINT = 104;
  IDC_BTN_SHUTDOWN = 116;
  IDC_ANI_SEARCH = 113;
  IDD_DLG_USERINFO = 200;
  IDC_EDT_USER = 201;
  IDC_STC8 = 210;
  IDC_STC2 = 208;
  IDD_DLG_MACHINEINFO = 300;
  IDC_STC9 = 301;
  IDC_STC11 = 302;
  IDC_EDT_MACHINE = 303;
  IDD_DLG_SHUTDOWN = 400;
  IDC_STC17 = 401;
  IDC_STC_MACHINE = 402;
  IDC_STC19 = 403;
  IDC_EDT_LOGIN = 404;
  IDC_STC20 = 405;
  IDC_EDT_PW = 406;
  IDC_STC21 = 407;
  IDC_EDT_MSG = 408;
  IDC_RBN_SHUTDOWN = 409;
  IDC_RBN_REBOOT = 410;
  IDC_CHK_FORCE = 411;
  IDC_EDT_TIMEOUT = 416;
  IDC_BTN_OK = 412;
  IDC_BTN_CANCEL1 = 413;
  IDC_STC22 = 414;
  IDC_STC23 = 415;
  ID_ACCEL_CLOSE = 4001;

  FONTNAME          = 'Tahoma';
  FONTSIZE          = -18;
  FONT_TV           = 'Courier New';
  FONTSIZE_TV       = -12;

const
  // ThreadMessages
  TM_DONE           = WM_USER + 1; // wParam: 0 -> no error / 1 -> error
  TM_START          = WM_USER + 2;

const
  APPNAME           = 'Logged On';
  COPYRIGHT         = 'Copyright © Your Name';
  HOMEPAGE          = 'https://github.com';

resourcestring
  rsErrorUnknown    = 'Unknown error.';
  rsErrorMsgTemplate = 'Error code: %d' + #13#10 + 'Error message: %s';
  rsScanMachine     = 'Scanning machine "%s"...';
  rsScanDomain      = 'Scanning domain "%s"...';
  rsFinishMachine   = 'Scan complete. Count logged on users: %d.';
  rsFinishDomain    = 'Scan complete. Machines scanned: %d.';
  rsTime            = 'Time elapsed: %s';
  rsShutdown        = 'Shutdown';

type
  TShutdownParams = record
    Machine: string[255];
  end;
  PShutdownParams = ^TShutdownParams;

implementation

end.

