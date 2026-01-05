unit constants;

interface

const
  IDC_STC_BANNER    = 101;
  IDC_STC_DEVIDER   = 102;
  IDC_BTN_ABOUT     = 103;
  IDC_EDT_DIR       = 104;
  IDC_BTN_SELDIR    = 105;
  IDC_LV_FILES      = 106;
  IDC_EDT_ARCHIVE   = 107;
  IDC_BTN_SAVEAS    = 108;
  IDC_BTN_BUILD     = 109;
  IDC_BTN_GETFILES  = 110;
  IDC_PB            = 111;
  IDC_SB            = 191;

  ID_ACCEL_CLOSE    = 4001;

  // font size of the banner font
  BANNERFONTSIZE    = -18;

const
  TOOLTIPS          : array[0..7] of string = (
    'Program information',
    'Selected directory',
    'Select directory with files to add',
    'Found files to add',
    'Archive filename',
    'Select archive file',
    'Start build process',
    'Find files to add'
    );

  COLS              : array[0..1] of string = (
    'File',
    'Size'
    );

resourcestring
  rsOnFileFound     = 'Files: %d';
  rsOnFileFoundTotalFileSize = 'Total size: ';
  rsOnFillLV        = 'Filling listview... %d%%';
  rsOnAppendTOC     = 'Appending TOC...';
  rsOnAppendFile    = 'Appending file %i of %i files...';
  rsOnAppendingFile = 'Progress: %i%%';
  rsFinish          = 'Finish';

implementation

end.


