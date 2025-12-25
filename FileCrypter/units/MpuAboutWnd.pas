(*
 *
 *  How to use:
 *  1.) Fill out the Fileversion properties:
 *      - FileDescription
 *      - FileVersion
 *      - LegalCopyRight
 *      - Productname
 *      - Productversion
 *      because these properties will be displayed in the dialog.
 *
 *  2.) Adjust the value of the constant URI.
 *  3.) Replace the IconByteArray with the IconByteArray of your icon.
 *      (e.g. using my tool IconToDelphiByteArray.)
 *  4.) Call the class procedure ShowAboutWnd:
 *      TAboutWnd.ShowAboutWnd(Handle);
 *  5.) Enjoy the dialog. ;)
 *
 *
 *  Special thanks go to NicoDE and xaromz for their help.
 *
 *)

{*
 *  If you wonder why...
 *  Why don't use the VCL and formulars or at least a Dialog resource?
 *  I wanted a nice About-Dialog that is easy to handle. I used to use
 *  MessageBoxes and even customized MessageBoxes. But they are boring.
 *  So I decided to roll up my sleeves and write a piece of code that
 *  satisfies my needs: Nice to look at and easy to handle:
 *  Just add the unit and call the dialog. If you use the VCL you always
 *  have the dfm file that holds the formular. If you use dialog resource
 *  you have the resource file and you have to include the resource
 *  file into your source code. Now even the icon is in the sourcecode
 *  you don't have a resource file for the icon.
 *
 *}

unit MpuAboutWnd;

interface

uses
  Windows,
  Messages,
  ShellAPI;

type
  TAboutWnd = class(TObject)
  public
    class function GetFileInfo(const Filename, Info: string): string;
    class function GetFileVersion(const Filename: string): string;
    class procedure ShowAboutWnd(hParent: THandle);
    class procedure MsgBox(hParent: THandle; IconID: DWORD; AdditionalText: String = '');
    class procedure ShellAboutDlg(Handle: THandle; Inst: DWORD; IconID: DWORD);
  end;

implementation

const
  WNDCLASS          = 'WndClass';
  WINDOWWIDTH       = 300;
  WINDOWHEIGHT      = 193;

  PROP_PRODUCTFONT  = 'ProductFont';
  PROP_ICON         = 'Icon';
  PROP_BRUSH        = 'Brush';
  PROP_LINKFONTNONHOVER = 'LinkFontNonHover';
  PROP_LINKFONTHOVER = 'LinkFontHover';

const
  ID_BTN_OK         = 1001;
  ID_STC_PRODUCTNAME = 1002;
  ID_STC_DESCRIPTION = 1003;
  ID_STC_VER        = 1005;
  ID_STC_WEB        = 1006;
  ID_STC_IMAGE      = 1007;

  PRODUCTFONTNAME   = 'Tahoma';
  PRODUCTFONTSIZE   = -16;
  LINKFONTNAME      = 'MS Sans Serif';
  LINKFONTSIZE      = -11;

  URI               = 'https://github.com';

var
  WindowHover       : Boolean = False;
  OldStcWndProc     : Pointer;

  IconByteArray     : array[0..3239] of Byte = (
    $28, $00, $00, $00, $20, $00, $00,
    $00, $40, $00, $00, $00, $01, $00, $18, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C2, $C2, $C2, $A8, $A8, $A8, $A8, $A8, $A8, $C2, $C2, $C2,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $CB, $CB, $CB, $98, $98, $98, $98, $98, $98,
    $98, $98, $98, $A8, $A8, $A8,
    $A8, $A8, $A8, $57, $57, $57, $C2, $C2, $C2, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $67, $67, $67,
    $98, $98, $98, $98, $98, $98,
    $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $D9, $D9, $D9, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $98, $98, $98, $98, $98, $98, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8,
    $A8, $A8, $A8, $A8, $67, $67,
    $67, $A8, $A8, $A8, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $CB, $CB, $CB, $98, $98, $98, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8,
    $A8, $B7, $B7, $B7, $B7, $B7,
    $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $46, $46, $46, $A8, $A8, $A8, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $CB, $CB, $CB, $98, $98, $98, $98, $98, $98, $98, $98,
    $98, $98, $98, $98, $98, $98,
    $98, $A8, $A8, $A8, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $46, $46, $46, $46,
    $46, $46, $A8, $A8, $A8, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C2, $C2, $C2, $67, $67,
    $67, $98, $98, $98, $98, $98,
    $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $A8, $A8, $A8, $B7, $B7, $B7, $B7, $B7, $B7, $B7,
    $B7, $B7, $C2, $C2, $C2, $79,
    $79, $79, $57, $57, $57, $57, $57, $57, $46, $46, $46, $46, $46, $46, $46, $46, $46, $79, $79, $79, $CB, $CB, $CB,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $CB, $CB,
    $CB, $98, $98, $98, $98, $98, $98, $88, $88, $88, $57, $57, $57, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $57, $57, $57, $57, $57, $57, $57, $57, $57, $46, $46, $46, $67, $67, $67, $46, $46, $46,
    $2B, $2B, $2B, $2B, $2B, $2B,
    $2B, $2B, $2B, $2B, $2B, $2B, $2B, $2B, $2B, $67, $67, $67, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $CB, $CB, $CB, $98, $98, $98, $98, $98, $98, $79, $79, $79, $67, $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $57, $57, $57, $57, $57, $57, $46, $46, $46,
    $46, $46, $46, $57, $57, $57,
    $57, $57, $57, $67, $67, $67, $67, $67, $67, $79, $79, $79, $3B, $3B, $3B, $2B, $2B, $2B, $2B, $2B, $2B, $98, $98,
    $98, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C2, $C2, $C2, $88, $88, $88, $98, $98, $98, $79,
    $79, $79, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $57, $57, $57,
    $57, $57, $57, $57, $57, $57,
    $46, $46, $46, $46, $46, $46, $57, $57, $57, $57, $57, $57, $67, $67, $67, $79, $79, $79, $79, $79, $79, $88, $88,
    $88, $88, $88, $88, $88, $88,
    $88, $2B, $2B, $2B, $98, $98, $98, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $CB,
    $CB, $CB, $98, $98, $98, $98,
    $98, $98, $79, $79, $79, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $57, $57, $57,
    $57, $57, $57, $57, $57, $57, $46, $46, $46, $46, $46, $46, $46, $46, $46, $57, $57, $57, $57, $57, $57, $67, $67,
    $67, $79, $79, $79, $88, $88,
    $88, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $B7, $B7, $B7, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $C2,
    $C2, $C2, $79, $79, $79, $98, $98, $98, $98, $98, $98, $79, $79, $79, $67, $67, $67, $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $67,
    $67, $67, $67, $67, $67, $67, $67, $67, $67, $57, $57, $57, $57, $57, $57, $46, $46, $46, $46, $46, $46, $46, $46,
    $46, $57, $57, $57, $67, $67,
    $67, $79, $79, $79, $79, $79, $79, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $A8, $A8, $A8, $98,
    $98, $98, $B7, $B7, $B7, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $CB, $CB, $CB, $98, $98, $98, $98, $98, $98, $79, $79, $79, $57, $57, $57,
    $57, $57, $57, $A8, $A8, $A8,
    $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $2B, $2B, $2B, $67, $67, $67, $C2, $C2,
    $C2, $88, $88, $88, $79, $79,
    $79, $67, $67, $67, $67, $67, $67, $79, $79, $79, $79, $79, $79, $88, $88, $88, $98, $98, $98, $98, $98, $98, $A8,
    $A8, $A8, $A8, $A8, $A8, $A8,
    $A8, $A8, $B7, $B7, $B7, $CB, $CB, $CB, $00, $00, $00, $00, $00, $00, $00, $00, $00, $CB, $CB, $CB, $98, $98, $98,
    $98, $98, $98, $79, $79, $79,
    $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $98, $98, $98, $2B, $2B, $2B, $2B, $2B, $2B, $2B, $2B,
    $2B, $2B, $2B, $2B, $67, $67,
    $67, $C2, $C2, $C2, $98, $98, $98, $67, $67, $67, $67, $67, $67, $67, $67, $67, $46, $46, $46, $2B, $2B, $2B, $67,
    $67, $67, $57, $57, $57, $A8,
    $A8, $A8, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $CB, $CB, $CB, $00, $00, $00,
    $00, $00, $00, $CB, $CB, $CB,
    $98, $98, $98, $98, $98, $98, $79, $79, $79, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $98, $98, $98, $2B, $2B,
    $2B, $A8, $A8, $A8, $A8, $A8,
    $A8, $2B, $2B, $2B, $67, $67, $67, $C2, $C2, $C2, $C2, $C2, $C2, $79, $79, $79, $79, $79, $79, $67, $67, $67, $67,
    $67, $67, $46, $46, $46, $2B,
    $2B, $2B, $2B, $2B, $2B, $3B, $3B, $3B, $57, $57, $57, $46, $46, $46, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7,
    $B7, $B7, $B7, $CB, $CB, $CB,
    $00, $00, $00, $C2, $C2, $C2, $79, $79, $79, $98, $98, $98, $98, $98, $98, $98, $98, $98, $79, $79, $79, $A8, $A8,
    $A8, $A8, $A8, $A8, $2B, $2B,
    $2B, $A8, $A8, $A8, $A8, $A8, $A8, $98, $98, $98, $88, $88, $88, $79, $79, $79, $C2, $C2, $C2, $C2, $C2, $C2, $79,
    $79, $79, $79, $79, $79, $67,
    $67, $67, $67, $67, $67, $46, $46, $46, $2B, $2B, $2B, $2B, $2B, $2B, $2B, $2B, $2B, $46, $46, $46, $88, $88, $88,
    $57, $57, $57, $B7, $B7, $B7,
    $B7, $B7, $B7, $CB, $CB, $CB, $00, $00, $00, $00, $00, $00, $D9, $D9, $D9, $A8, $A8, $A8, $A8, $A8, $A8, $98, $98,
    $98, $98, $98, $98, $98, $98,
    $98, $C2, $C2, $C2, $2B, $2B, $2B, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $98, $98, $98, $98, $98, $98, $79,
    $79, $79, $C2, $C2, $C2, $C2,
    $C2, $C2, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $57, $57, $57, $2B, $2B, $2B, $2B, $2B, $2B,
    $2B, $2B, $2B, $67, $67, $67,
    $57, $57, $57, $B7, $B7, $B7, $B7, $B7, $B7, $CB, $CB, $CB, $00, $00, $00, $00, $00, $00, $00, $00, $00, $D9, $D9,
    $D9, $A8, $A8, $A8, $A8, $A8,
    $A8, $A8, $A8, $A8, $98, $98, $98, $98, $98, $98, $00, $00, $00, $00, $00, $00, $C2, $C2, $C2, $A8, $A8, $A8, $A8,
    $A8, $A8, $98, $98, $98, $98,
    $98, $98, $67, $67, $67, $C2, $C2, $C2, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79, $79,
    $88, $88, $88, $88, $88, $88,
    $98, $98, $98, $98, $98, $98, $98, $98, $98, $A8, $A8, $A8, $A8, $A8, $A8, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $D9, $D9, $D9, $A8, $A8, $A8, $A8, $A8, $A8, $98, $98, $98, $98, $98, $98, $98, $98, $98, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $C2,
    $C2, $C2, $A8, $A8, $A8, $A8, $A8, $A8, $79, $79, $79, $C2, $C2, $C2, $C2, $C2, $C2, $98, $98, $98, $79, $79, $79,
    $79, $79, $79, $79, $79, $79,
    $79, $79, $79, $88, $88, $88, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $B7, $B7, $B7, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C2, $C2, $C2, $79, $79, $79, $A8, $A8, $A8, $A8, $A8, $A8, $98,
    $98, $98, $98, $98, $98, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $D9, $D9, $D9, $C2, $C2, $C2,
    $C2, $C2, $C2, $98, $98, $98,
    $79, $79, $79, $79, $79, $79, $79, $79, $79, $98, $98, $98, $B7, $B7, $B7, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C2, $C2, $C2, $79,
    $79, $79, $A8, $A8, $A8, $A8,
    $A8, $A8, $98, $98, $98, $98, $98, $98, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $D9, $D9, $D9, $C2, $C2, $C2,
    $C2, $C2, $C2, $A8, $A8, $A8, $88, $88, $88, $88, $88, $88, $88, $88, $88, $B7, $B7, $B7, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $D9, $D9, $D9, $B7, $B7, $B7, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $A8, $CB, $CB, $CB, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $D9, $D9, $D9, $B7, $B7, $B7, $C2, $C2, $C2, $79, $79, $79, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88,
    $88, $B7, $B7, $B7, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $D9, $D9, $D9, $B7, $B7, $B7, $A8, $A8, $A8, $A8, $A8, $A8,
    $A8, $A8, $A8, $A8, $A8, $A8,
    $A8, $A8, $A8, $A8, $A8, $A8, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $C2, $C2, $C2, $A8, $A8, $A8, $98, $98,
    $98, $88, $88, $88, $88, $88,
    $88, $C2, $C2, $C2, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $B7, $B7, $B7,
    $88, $88, $88, $B7, $B7, $B7,
    $B7, $B7, $B7, $B7, $B7, $B7, $A8, $A8, $A8, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $C2, $C2,
    $C2, $A8, $A8, $A8, $98, $98,
    $98, $98, $98, $98, $98, $98, $98, $88, $88, $88, $B7, $B7, $B7, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $C2, $C2, $C2, $79, $79, $79, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7, $B7,
    $B7, $C2, $C2, $C2, $C2, $C2,
    $C2, $B7, $B7, $B7, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $C2, $C2, $C2, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $B7, $B7, $B7, $67, $67, $67, $79, $79, $79, $B7, $B7,
    $B7, $B7, $B7, $B7, $B7, $B7,
    $B7, $B7, $B7, $B7, $79, $79, $79, $A8, $A8, $A8, $B7, $B7, $B7, $A8, $A8, $A8, $98, $98, $98, $98, $98, $98, $98,
    $98, $98, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $D9, $D9, $D9, $D9, $D9,
    $D9, $C2, $C2, $C2, $A8, $A8, $A8, $B7, $B7, $B7, $CB, $CB, $CB, $CB, $CB, $CB, $C2, $C2, $C2, $B7, $B7, $B7, $B7,
    $B7, $B7, $A8, $A8, $A8, $A8,
    $A8, $A8, $CB, $CB, $CB, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $D9, $CB,
    $CB, $CB, $C2, $C2, $C2, $C2,
    $C2, $C2, $B7, $B7, $B7, $B7, $B7, $B7, $CB, $CB, $CB, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $D9, $D9, $D9, $D9,
    $D9, $D9, $D9, $D9, $D9, $D9,
    $D9, $D9, $D9, $D9, $D9, $CB, $CB, $CB, $CB, $CB, $CB, $C2, $C2, $C2, $D9, $D9, $D9, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $B7, $B7, $B7, $B7, $B7, $B7, $D9, $D9, $D9, $D9, $D9, $D9, $B7, $B7, $B7, $B7, $B7, $B7, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00,
    $00, $00, $FF, $FF, $FF, $FF, $FF, $87, $FF, $FF, $FE, $01, $FF, $FF, $FC, $00, $FF, $FF, $FC, $00, $7F, $FF, $F8,
    $00, $3F, $FF, $F0, $00, $1F,
    $FF, $E0, $00, $00, $FF, $E0, $00, $00, $1F, $C0, $00, $00, $0F, $C0, $00, $00, $07, $C0, $00, $00, $07, $80, $00,
    $00, $03, $80, $00, $00, $03,
    $80, $00, $00, $01, $80, $00, $00, $01, $00, $00, $00, $03, $00, $00, $00, $07, $03, $00, $00, $1F, $03, $80, $00,
    $3F, $03, $F0, $07, $FF, $03,
    $E0, $1F, $FF, $81, $C0, $1F, $FF, $80, $00, $3F, $FF, $80, $00, $3F, $FF, $C0, $00, $7F, $FF, $C0, $00, $FF, $FF,
    $E0, $00, $FF, $FF, $F0, $01,
    $FF, $FF, $F8, $03, $FF, $FF, $FC, $0F, $FF, $FF, $FF, $FF, $FF, $FF);

function Format(fmt: string; params: array of const): string;
var
  pdw1, pdw2        : PDWORD;
  i                 : integer;
  pc                : PCHAR;
begin
  pdw1 := nil;
  if length(params) > 0 then
    GetMem(pdw1, length(params) * sizeof(Pointer));
  pdw2 := pdw1;
  for i := 0 to high(params) do
  begin
    pdw2^ := DWORD(PDWORD(@params[i])^);
    inc(pdw2);
  end;
  GetMem(pc, 1024 - 1);
  try
    ZeroMemory(pc, 1024 - 1);
    SetString(Result, pc, wvsprintf(pc, PCHAR(fmt), PCHAR(pdw1)));
  except
    Result := '';
  end;
  if (pdw1 <> nil) then
    FreeMem(pdw1);
  if (pc <> nil) then
    FreeMem(pc);
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TAboutWnd.GetFileInfo
// Comment   : Retrieves file information from the resource
//             Info can be one of the strings: 'ProductName', LegalCopyright', ...

class function TAboutWnd.GetFileInfo(const Filename, Info: string): string;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize       : DWORD;
  VerInfo           : Pointer;
  VerValueSize      : DWORD;
  LangInfo          : PDWORDArr;
  LangID            : DWORD;
  pInfo             : PChar;
  i                 : Integer;
begin
  result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(Filename), LangID);
  if VerInfoSize <> 0 then
  begin
    VerInfo := Pointer(GlobalAlloc(GPTR, VerInfoSize));
    if Assigned(VerInfo) then
    try
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then
      begin
        // Description
        if VerQueryValue(VerInfo, '\VarFileInfo\Translation', Pointer(LangInfo), VerValueSize) then
        begin
          if (VerValueSize > 0) then
          begin
            // Divide by element size since this is an array
            VerValueSize := VerValueSize div sizeof(DWORD) * 2;
            // Number of language identifiers in the table
           (********************************************************************)
            for i := 0 to VerValueSize - 1 do
            begin
              // Swap words of this DWORD
              LangID := (LoWord(LangInfo[i]) shl 16) or HiWord(LangInfo[i]);
              // Query value ...
              if VerQueryValue(VerInfo, @Format('\StringFileInfo\%8.8x\' + Info, [LangID])[1], Pointer(pInfo),
                VerValueSize) then
                result := pInfo;
            end;
            (********************************************************************)
          end;
        end
        else
          result := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end
    else // GlobalAlloc
      result := '';
  end
  else // GetFileVersionInfoSize
    result := '';
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : TAboutWnd.GetFileVersion
// Comment   : Retrieves file version information from the resource

class function TAboutWnd.GetFileVersion(const Filename: string): string;
type
  PDWORDArr = ^DWORDArr;
  DWORDArr = array[0..0] of DWORD;
var
  VerInfoSize       : DWORD;
  VerInfo           : Pointer;
  VerValueSize      : DWORD;
  VerValue          : PVSFixedFileInfo;
  LangID            : DWORD;
begin
  result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(Filename), LangID);
  if VerInfoSize <> 0 then
  begin
    VerInfo := Pointer(GlobalAlloc(GPTR, VerInfoSize));
    if Assigned(VerInfo) then
    try
      if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then
      begin
        if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
        begin
          with VerValue^ do
          begin
            result := Format('%d.%d.%d.%d', [dwFileVersionMS shr 16, dwFileVersionMS and $FFFF,
              dwFileVersionLS shr 16, dwFileVersionLS and $FFFF]);
          end;
        end
        else
          result := '';
      end;
    finally
      GlobalFree(THandle(VerInfo));
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : LinkStcWndProc
// Comment   : WndClass for the "link" static.
//             Needed for the mouse messages to set the appropiate font

function LinkStcWndProc(hLinkStc, uMsg: DWORD; wParam, lParam: integer): LRESULT; stdcall;
var
  LinkFontHover     : HFONT;
  LinkFontNonHover  : HFONT;
  EventTrack        : TTrackMouseEvent;
begin
  Result := 0;
  case uMsg of
    WM_MOUSELEAVE:
      if WindowHover then
      begin
        // reset state
        WindowHover := False;
        LinkFontHover := GetProp(hLinkStc, PROP_LINKFONTNONHOVER);
        if LinkFontHover = 0 then
        begin
          // create and set font
          LinkFontHover := CreateFont(-MulDiv(LINKFONTSIZE, GetDeviceCaps(GetDC(hLinkStc), LOGPIXELSY), 72), 0, 0, 0,
            400, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH,
            LINKFONTNAME);
          // save handle as a window property
          SetProp(hLinkStc, PROP_LINKFONTNONHOVER, LinkFontHover);
        end;
        SendMessage(hLinkStc, WM_SETFONT, Integer(LinkFontHover), Integer(true));
      end;
    WM_MOUSEMOVE:
      if not WindowHover then
      begin
        // save state
        WindowHover := True;
        LinkFontNonHover := GetProp(hLinkStc, PROP_LINKFONTHOVER);
        if LinkFontNonHover = 0 then
        begin
          // create and set font
          LinkFontNonHover := CreateFont(-MulDiv(LINKFONTSIZE, GetDeviceCaps(GetDC(hLinkStc), LOGPIXELSY), 72), 0, 0,
            0, 400, 0, 1, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH,
            LINKFONTNAME);
          // save the handle as a window property
          SetProp(hLinkStc, PROP_LINKFONTHOVER, LinkFontNonHover);
        end;
        SendMessage(hLinkStc, WM_SETFONT, Integer(LinkFontNonHover), Integer(true));
        // track WM_MOUSELEAVE
        EventTrack.cbSize := SizeOf(EventTrack);
        EventTrack.dwFlags := TME_LEAVE;
        EventTrack.hwndTrack := hLinkStc;
        EventTrack.dwHoverTime := HOVER_DEFAULT;
        TrackMouseEvent(EventTrack);
      end;
    WM_DESTROY:
      begin
        // delete objects and remove properties from the window property list
        DeleteObject(GetProp(hLinkStc, PROP_LINKFONTNONHOVER));
        RemoveProp(hLinkStc, PROP_LINKFONTNONHOVER);
        DeleteObject(GetProp(hLinkStc, PROP_LINKFONTHOVER));
        RemoveProp(hLinkStc, PROP_LINKFONTHOVER);
      end;
  else
    Result := CallWindowProc(OldStcWndProc, hLinkStc, uMsg, wParam, lParam);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Procedure : WndProc
// Comment   : Main WndProc

function WndProc(hWnd: HWND; uMsg: UINT; wParam: wParam; lParam: LParam): LRESULT; stdcall;
var
  cs                : PCreateStruct;
  x, y              : Integer;
  hIcon             : THandle;
  ProductFont       : HFONT;
  rect              : TRect;
  Brush             : HBRUSH;
  LinkFontNonHover  : HFONT;
  hstcWeb           : THandle;
begin
  result := 0;
  case uMsg of
    WM_CREATE:
      begin
        // center the window on the parent
        cs := PCreateStruct(lParam);
        GetWindowRect(cs.hwndParent, rect);
        x := rect.Right - rect.Left;
        y := rect.Bottom - rect.Top;
        MoveWindow(hWnd, (x div 2) - (WINDOWWIDTH div 2) + rect.Left, (y div 2) - (WINDOWHEIGHT div 2) + rect.Top,
          WINDOWWIDTH, WINDOWHEIGHT, True);

        // caption text
        SetWindowText(hWnd, PChar(TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName')));

        // product name
        CreateWindowEx(0, 'STATIC', '', WS_CHILD or WS_VISIBLE or SS_CENTER, 5, 10, WINDOWWIDTH - 15, 27, hWnd,
          ID_STC_PRODUCTNAME, HInstance, nil);
        // create and set font
        ProductFont := CreateFont(-MulDiv(PRODUCTFONTSIZE, GetDeviceCaps(GetDC(hWnd), LOGPIXELSY), 72), 0, 0, 0, 900,
          1, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH,
          PRODUCTFONTNAME);
        // save handle as a window property
        SetProp(hWnd, PROP_PRODUCTFONT, ProductFont);
        SendDlgItemMessage(hWnd, ID_STC_PRODUCTNAME, WM_SETFONT, Integer(ProductFont), Integer(true));
        SetDlgItemText(hWnd, ID_STC_PRODUCTNAME, PChar(TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName')));

        // description, version and copyright
        CreateWindowEx(0, 'STATIC', '', WS_CHILD or WS_VISIBLE or SS_CENTER, 5, 40, WINDOWWIDTH - 15, 55, hWnd,
          ID_STC_DESCRIPTION, HInstance, nil);
        SendMessage(GetDlgItem(hWnd, ID_STC_DESCRIPTION), WM_SETFONT, Integer(GetStockObject(DEFAULT_GUI_FONT)),
          Integer(true)); // stock objects needn't be freed
        SetDlgItemText(hWnd, ID_STC_DESCRIPTION, PChar(TAboutWnd.GetFileInfo(ParamStr(0), 'FileDescription') + #13#10 +
          TAboutWnd.GetFileVersion(ParamStr(0)) + #13#10#13#10 + 'Copyright © ' + TAboutWnd.GetFileInfo(ParamStr(0),
          'LegalCopyright')));

        // static for icon
        CreateWindowEx(0, 'STATIC', nil, WS_VISIBLE or WS_CHILD or SS_ICON, 12, 8, 32, 32, hWnd, ID_STC_IMAGE,
          hInstance, nil);
        // create icon from byte array
        hIcon := CreateIconFromResource(PByte(@IconByteArray[0]), SizeOf(IconByteArray), True, $00030000);
        if hIcon <> 0 then
        begin
          // save handle as a window property
          SetProp(hWnd, PROP_ICON, hIcon);
          SendMessage(GetDlgItem(hWnd, ID_STC_IMAGE), STM_SETIMAGE, IMAGE_ICON, hIcon);
        end;

        // "Link" static
        hstcWeb := CreateWindowEx(0, 'STATIC', PCHar(URI), WS_CHILD or WS_VISIBLE or SS_NOTIFY or SS_CENTER, 5, 97,
          WINDOWWIDTH -
          15, 18, hWnd, ID_STC_WEB, HInstance, nil);
        LinkFontNonHover := CreateFont(-MulDiv(LINKFONTSIZE, GetDeviceCaps(GetDC(hWnd), LOGPIXELSY), 72), 0, 0, 0,
          400, 0, 0, 0, ANSI_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH,
          LINKFONTNAME);
        SetClassLong(hstcWeb, GCL_HCURSOR, LoadCursor(0, IDC_HAND));
        SetProp(hWnd, PROP_LINKFONTNONHOVER, LinkFontNonHover);
        SendMessage(GetDlgItem(hWnd, ID_STC_WEB), WM_SETFONT, Integer(LinkFontNonHover), Integer(true));
        // subclass the static window. Needed for mouse messages.
        OldStcWndProc := Pointer(SetWindowLong(GetDlgItem(hWnd, ID_STC_WEB), GWL_WNDPROC, Integer(@LinkStcWndProc)));

        // devider
        CreateWindowEx(0, 'STATIC', '', WS_CHILD or WS_VISIBLE or SS_SUNKEN, 0, 119, 300, 2, hWnd, 0, HInstance, nil);

        // OK button
        CreateWindowEx(0, 'BUTTON', 'OK', WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 210, 129, 75, 24, hWnd,
          ID_BTN_OK, HInstance, nil);
        SendMessage(GetDlgItem(hWnd, ID_BTN_OK), WM_SETFONT, Integer(GetStockObject(DEFAULT_GUI_FONT)),
          Integer(true));
        SetFocus(GetDlgItem(hWnd, ID_BTN_OK));
      end;
    WM_CTLCOLORSTATIC:
      begin
        // set textcolor of "Link" tatic
        if lParam = Integer(GetDlgItem(hWnd, ID_STC_WEB)) then
        begin
          SetTextColor(DWORD(wParam), RGB(0, 0, 255));
          SetBkColor(DWORD(wParam), GetSysColor(COLOR_BTNFACE));
          Brush := GetSysColorBrush(COLOR_BTNFACE);
          // save brush as a window property
          SetProp(hWnd, PROP_BRUSH, Brush);
          // return brush
          Result := Brush;
        end
        else
          result := DefWindowProc(hWnd, uMsg, wParam, lParam);
      end;
    WM_COMMAND:
      begin
        // close window on ESC
        if wParam = ID_CANCEL then
          SendMessage(hWnd, WM_CLOSE, 0, 0);
        if hiword(wParam) = BN_CLICKED then
        begin
          case LoWord(wParam) of
            ID_BTN_OK: SendMessage(hWnd, WM_CLOSE, 0, 0);
          end;
        end;
        if HiWord(wParam) = STN_CLICKED then
        begin
          case LoWord(wParam) of
            ID_STC_WEB:
              begin
                if WindowHover then
                  Shellexecute(hWnd, 'open', PChar(URI), nil, nil, SW_SHOWNORMAL);
              end;
          end;
        end;
      end;
    WM_CLOSE:
      begin
        // delete objects and remove properties from window property list
        DeleteObject(GetProp(hWnd, PROP_PRODUCTFONT));
        RemoveProp(hWnd, PROP_PRODUCTFONT);
        DestroyIcon(GetProp(hWnd, PROP_ICON));
        RemoveProp(hWnd, PROP_ICON);
        DeleteObject(GetProp(hWnd, PROP_BRUSH));
        RemoveProp(hWnd, PROP_BRUSH);
        DeleteObject(GetProp(hWnd, PROP_LINKFONTNONHOVER));
        RemoveProp(hWnd, PROP_LINKFONTNONHOVER);
        // close window
        DestroyWindow(hWnd);
      end;
    WM_DESTROY:
      begin
        PostQuitMessage(hWnd);
      end;
  else
    Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
  end;
end;

var
  hAboutWnd         : THandle;
  wc                : TWndClassEx = (
    cbSize: SizeOf(TWndClassEx);
    Style: CS_HREDRAW or CS_VREDRAW;
    lpfnWndProc: @WndProc;
    cbClsExtra: 0;
    cbWndExtra: 0;
    hbrBackground: COLOR_BTNFACE + 1;
    lpszMenuName: nil;
    lpszClassName: WNDCLASS;
    hIconSm: 0;
    );
  msg               : TMsg;

class procedure TAboutWnd.ShowAboutWnd(hParent: THandle);
begin
  wc.hInstance := hInstance;
  wc.hIcon := LoadIcon(0, IDI_APPLICATION);
  wc.hCursor := LoadCursor(0, IDC_ARROW);
  RegisterClassEx(wc);
  // disable parent window (ShowModal)
  EnableWindow(hParent, False);
  // create "About" window
  hAboutWnd := CreateWindowEx(0, WNDCLASS, nil, WS_VISIBLE, Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),
    WINDOWWIDTH, WINDOWHEIGHT, hParent, 0, hInstance, nil);

  while true do
  begin
    if not GetMessage(msg, 0, 0, 0) then
      break;
    if IsDialogMessage(hAboutWnd, msg) = FALSE then
    begin
      TranslateMessage(msg);
      DispatchMessage(msg);
    end;
  end;
  // enable parent window
  EnableWindow(hParent, True);
  // set parent window into foreground
  SetForeGroundWindow(hParent);
end;

class procedure TAboutWnd.MsgBox(hParent: THandle; IconID: DWORD; AdditionalText: String = '');
var
  MsgInfo           : TMsgBoxParams;
  s                 : string;
begin
  if AdditionalText <> '' then
    s := Format('%s - %s' + #13#10#13#10 + 'Copyright © %s' + #13#10 + '%s' + #13#10#13#10 + '%s',
      [TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName'), TAboutWnd.GetFileVersion(ParamStr(0)),
      TAboutWnd.GetFileInfo(ParamStr(0), 'LegalCopyright'), URI, Additionaltext])
  else
    s := Format('%s - %s' + #13#10#13#10 + 'Copyright © %s' + #13#10 + '%s', [TAboutWnd.GetFileInfo(ParamStr(0),
      'ProductName'), TAboutWnd.GetFileVersion(ParamStr(0)), TAboutWnd.GetFileInfo(ParamStr(0), 'LegalCopyright'), URI]);
  MsgInfo.cbSize := SizeOf(TMsgBoxParams);
  MsgInfo.hwndOwner := hParent;
  MsgInfo.hInstance := GetWindowLong(hParent, GWL_HINSTANCE);
  MsgInfo.lpszText := PChar(s);
  MsgInfo.lpszCaption := PChar(TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName'));
  MsgInfo.dwStyle := MB_USERICON;
  MsgInfo.lpszIcon := MAKEINTRESOURCE(IconID);
  MessageBoxIndirect(MsgInfo);
end;

class procedure TAboutWnd.ShellAboutDlg(Handle: THandle; Inst: DWORD; IconID: DWORD);
var
  s                 : string;
  hIcon             : THandle;
begin
  s := Format('%s' + #13#10 + 'Copyright © %s %s', [TAboutWnd.GetFileVersion(ParamStr(0)),
    TAboutWnd.GetFileInfo(ParamStr(0), 'LegalCopyright'), URI]);
  hIcon := LoadIcon(Inst, MAKEINTRESOURCE(IconID));
  ShellAbout(Handle, PChar(TAboutWnd.GetFileInfo(ParamStr(0), 'ProductName')), PChar(s), hIcon);
end;

end.

