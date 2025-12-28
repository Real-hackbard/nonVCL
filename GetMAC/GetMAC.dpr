{$WARNINGS OFF}

program GetMAC;

uses
  windows,
  messages,
  WinSock,
  SysUtils,
  Classes,
  CommCtrl,
  IpExport in 'units\IpExport.pas',
  IpHlpApi in 'units\IpHlpApi.pas',
  IpRtrMib in 'units\IpRtrMib.pas',
  IpTypes in 'units\IpTypes.pas',
  MpuTools in 'units\MpuTools.pas',
  MpuIPHelpers in 'units\MpuIPHelpers.pas';

{$R .\res\resource.res}

const
{$I .\res\resource.inc}
  FONTNAME = 'Tahoma';
  FONTSIZE = -18;
  TOOLTIPS: array[0..7] of string = (
    'View program information',
    '',
    'Name of the computer corresponding to the MAC address to be determined',
    '',
    'IP address of the computer corresponding to the MAC address to be determined',
    '',
    'Determine MAC address',
    'Copy MAC address to clipboard'
    );

{$I .\includes\tooltips.inc}
{$I .\includes\infobox.inc}
{$I .\includes\dialog.inc}
{$I .\includes\dlghelpers.inc}

procedure SetMACAdr(Dlg: THandle; MAC: string);
begin
  SetDlgItemText(Dlg, IDC_EDT_MAC, PChar(MAC));
end;

function dlgfunc(Dlg: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): BOOL; stdcall;
var
  IPStr: string;
  IPDW: DWORD;
  b0: Byte;
  b1: Byte;
  b2: Byte;
  b3: Byte;
begin
  result := true;
  case Msg of
    WM_INITDIALOG:
      begin
        SetDialogIcon(Dlg);
        SetBannerFont(Dlg);
        SetCaptions(Dlg);
        SetToolTips(Dlg);
        SendDlgItemMessage(Dlg, IDC_RB_NAME, BM_SETCHECK, BST_CHECKED, 0);
        EnableWindow(GetDlgItem(Dlg, IDC_IP_ADR), False);
        SetFocus(GetDlgItem(Dlg, IDC_EDT_NAME));
      end;
    WM_CTLCOLORSTATIC:
      begin
        case GetDlgCtrlId(lParam) of
          IDC_STC_BANNER:
            begin
              result := BOOL(GetStockObject(WHITE_BRUSH));
            end;
        else
          Result := False;
        end;
      end;
    WM_LBUTTONDOWN:
      begin
        MoveWindowWithMouse(Dlg, lParam);
      end;
    WM_SIZE:
      begin
        MoveClientWindows(Dlg, lParam, wParam);
        SetStatusbar(Dlg, lParam, wParam);
        InvalidateRect(Dlg, nil, False);
        RedrawWindow(Dlg, nil, 0, RDW_UPDATENOW);
      end;
    WM_CLOSE:
      begin
        EndDialog(Dlg, 0);
      end;
    WM_COMMAND:
      begin
        { accel for closing the dialog with ESC }
        if wParam = ID_CANCEL then
          SendMessage(Dlg, WM_CLOSE, 0, 0);
        { button and menu clicks }
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            IDC_BTN_ABOUT:
              begin
                InfoBox(Dlg);
              end;
            IDC_RB_NAME:
              begin
                EnableWindow(GetDlgItem(Dlg, IDC_EDT_NAME), True);
                EnableWindow(GetDlgItem(Dlg, IDC_IP_ADR), False);
                SetFocus(GetDlgItem(Dlg, IDC_EDT_NAME));
              end;
            IDC_RB_IP:
              begin
                EnableWindow(GetDlgItem(Dlg, IDC_IP_ADR), True);
                EnableWindow(GetDlgItem(Dlg, IDC_EDT_NAME), False);
                SetFocus(GetDlgItem(Dlg, IDC_IP_ADR));
              end;
            IDC_BTN_GETMAC:
              begin
                if IsRadionBtnChecked(Dlg, IDC_RB_NAME) then
                begin
                  try
                    SetMACAdr(Dlg, GetMACByName(GetItemText(Dlg, IDC_EDT_NAME)));
                    if GetWindowTextLength(GetDlgItem(Dlg, IDC_EDT_NAME)) = 0 then
                    begin
                      SetDlgItemText(Dlg, IDC_EDT_NAME, PChar(GetCompName));
                    end;
                    IpStr := GetIpByHost(GetItemText(Dlg, IDC_EDT_NAME));
                    IpStrToBytes(IpStr, b0, b1, b2, b3);
                    SendDlgItemMessage(Dlg, IDC_IP_ADR, IPM_SETADDRESS, 0, MAKEIPADDRESS(b0, b1, b2, b3));
                  except
                    on E: Exception do
                      MessageBox(Dlg, PChar(E.Message), PChar(GetFileInfo(ParamStr(0), 'ProductName')), MB_ICONSTOP);
                  end;
                end
                else
                begin
                  try
                    SendDlgItemMessage(Dlg, IDC_IP_ADR, IPM_GETADDRESS, 0, Integer(@IPDW));
                    IPStr := Format('%d.%d.%d.%d',
                      [FIRST_IPADDRESS(IPDW), SECOND_IPADDRESS(IPDW),
                      THIRD_IPADDRESS(IPDW), FOURTH_IPADDRESS(IPDW)]);
                    SetMACAdr(Dlg, GetMACByIP(IPStr));
                    SetDlgItemText(Dlg, IDC_EDT_NAME, GetHostByIP(IpStr));
                  except
                    on E: Exception do
                      MessageBox(Dlg, PChar(E.Message), PChar(GetFileInfo(ParamStr(0), 'ProductName')), MB_ICONSTOP);
                  end;
                end;
              end;
            IDC_BTN_COPY:
              begin
                SendDlgItemMessage(Dlg, IDC_EDT_MAC, EM_SETSEL, 0, 255);
                SendDlgItemMessage(Dlg, IDC_EDT_MAC, WM_COPY, 0, 0);
              end;
          end;
        end;
      end
  else
    result := false;
  end;
end;

begin
  InitCommonControls;
  DialogBox(hInstance, MAKEINTRESOURCE(100), 0, @dlgfunc);
end.

