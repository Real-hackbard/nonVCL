(******************************************************************************
 *                                                                            *
 *  Project: FileCrypter - Tool for encrypting files                          *
 *  File   : constants, constant declarations                                 *
 *                                                                            *
 *  Copyright (c) Michael Puff  http://www.michael-puff.de                    *
 *                                                                            *
 ******************************************************************************)


unit constants;

interface

const
  IDC_STC_BANNER    = 101;
  IDC_STC_DEVIDER   = 102;
  IDC_CHK_DELSOURCE = 9;
  IDC_BTN_ENC       = 10;
  IDC_BTN_DEC       = 11;
  IDC_BTN_CANCEL    = 12;
  IDC_BTN_OPEN_IN   = 13;
  IDC_BTN_OPEN_OUT  = 14;
  IDC_BTN_ABOUT     = 15;
  IDC_STC_PWDQULTY  = 16;
  IDC_EDT_OWCOUNT   = 17;
  IDC_EDT_INPUT     = 104;
  IDC_EDT_OUTPUT    = 105;
  IDC_EDT_PWD1      = 106;
  IDC_EDT_PWD2      = 107;
  IDC_UD_OWCOUNT    = 108;
  IDC_STC_OWCOUNT   = 109;
  IDC_SB            = 114;
  IDC_PB            = 103;

  ID_ACCEL_CLOSE    = 4001;

  // font size of the banner font
  BANNERFONTSIZE          = -18;

const
  ABOUTEX = 'Used algorithm: AES/Rijndael'+#13#10+
    'Implemented by Hagen Reddmann,'+#13#10+'(Delphi Encrypten Compendium).';

resourcestring
  rsAbort = 'Process cancelled by user.';
  rsEncrypt = 'Encrypting file...';
  rsDecrypt = 'Decrypting file...';
  rsDelFile = 'Deleting file... Pass: %d of %d';

implementation

end.

