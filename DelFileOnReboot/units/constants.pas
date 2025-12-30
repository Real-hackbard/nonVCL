{$I ..\compilerswitches.inc}

unit constants;

interface

const
  IDC_STC_BANNER    = 101;
  IDC_STC_DEVIDER   = 102;
  IDC_SB            = 103;
  IDC_BTN_ABOUT     = 104;
  IDC_BTN_CLOSE     = 105;
  IDC_BTN_ADDFILES  = 106;
  IDC_BTN_DELFILE   = 107;
  IDC_LST_FILES     = 108;

  // font size of the banner font
  BANNERFONTSIZE          = -18;

const
  TOOLTIPS          : array[0..3] of string = (
    'Versioninformation',
    'Closes the program and deletes the file(s) on reboot',
    'Add files to the list of locked files to delete after reboot',
    'Removes the selected file from the list'
    );

implementation

end.
