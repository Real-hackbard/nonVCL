unit constants;

interface

const
  IDC_STC_BANNER    = 101;
  IDC_STC_DEVIDER   = 102;
  IDC_BTN_ABOUT     = 103;
  IDC_LV_FILES      = 104;
  IDC_EDT_DIR       = 105;
  IDC_BTN_SELDIR    = 106;
  IDC_BTN_EXTRACT   = 107;
  IDC_PB            = 108;
  IDC_SB            = 199;

  ID_ACCEL_CLOSE    = 4001;

  // font size of the banner font
  BANNERFONTSIZE    = -18;

const
  TOOLTIPS          : array[0..4] of string = (
    'Program information',
    'Files in archive',
    'Destination directory',
    'Destination directory',
    'Extract files'
    );

  COLS              : array[0..1] of string = (
    'File',
    'Size'
    );

resourcestring
  rsFilesInArchive  = 'Files: %d';
  rsOnAppendTOC     = 'Appending TOC...';
  rsOnExtractFile   = 'Extracting file %i of %i files...';
  rsOnExtractingFile = 'Progress: %i%%';
  rsFinish          = 'Finish';

implementation

end.


