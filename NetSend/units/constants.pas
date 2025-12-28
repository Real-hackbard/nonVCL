unit constants;

interface

const
  IDC_STC_BANNER         = 101;
  IDC_STC_DEVIDER        = 102;
  IDC_BTN_ABOUT          = 103;
  IDC_EDT_COMPUTER       = 104;
  IDC_BTN_COMPUTER       = 105;
  IDC_EDT_MSG            = 106;
  IDC_EDT_SENDER         = 107;
  IDC_BTN_SEND           = 108; 

  FONTNAME               = 'Tahoma';
  FONTSIZE               = -18;

const
  APPNAME                = 'Net Send';
  AUTHOR                 = 'Your Name';
  HOMEPAGE               = 'https://github.com';

  TOOLTIPS : array[0..5] of String = (
    'Display program information',
    'Receiver',
    'Select computer',
    'Message text',
    'Sender',
    'Send message'
  );

implementation

end.
