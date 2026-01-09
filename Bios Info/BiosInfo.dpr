program BiosInfo;

{$IFDEF WIN32}
  {$R res\BiosInfo.res}
{$ENDIF}

uses
{$IFDEF WIN32}
  Windows,
  CommCtrl,
  SysUtils,
  BiosHelp in 'BiosHelp.pas';
{$ELSE}
{$IFDEF LINUX}
  Libc,
  SysUtils,
  BiosHelp in 'BiosHelp.pas';
{$ENDIF}
{$ENDIF}


type
  PSmBiosEntryPoint = ^TSmBiosEntryPoint;
  TSmBiosEntryPoint = packed record
    AnchorString  : array [0..3] of AnsiChar;  // 00
    Checksum      : Byte;                      // 04
    Length        : Byte;                      // 05
    MajorVersion  : Byte;                      // 06
    MinorVersion  : Byte;                      // 07
    MaxStructSize : Word;                      // 08
    Revision      : Byte;                      // 0A
    FormattedArea : array [0..4] of Byte;      // 0B
    Intermediate  : packed record
      AnchorString: array [0..4] of AnsiChar;  // 10
      Checksum    : Byte;                      // 15
      TableLength : Word;                      // 16
      TableAddress: Longword;                  // 18
      NumStructs  : Word;                      // 1C
      Revision    : Byte;                      // 1E
    end;                                       // 1F
  end;

  PDmiHeader = ^TDmiHeader;
  TDmiHeader = packed record
    Type_ : Byte;
    Length: Byte;
    Handle: Word;
  end;

type
  PDmiType0 = ^TDmiType0;
  TDmiType0 = packed record
    Header         : TDmiHeader;
    Vendor         : Byte;
    Version        : Byte;
    StartingSegment: Word;
    ReleaseDate    : Byte;
    BiosRomSize    : Byte;
    Characteristics: Int64;
    ExtensionBytes : array [0..1] of Byte;
  end;

  PDmiType1 = ^TDmiType1;
  TDmiType1 = packed record
    Header      : TDmiHeader;
    Manufacturer: Byte;
    ProductName : Byte;
    Version     : Byte;
    SerialNumber: Byte;
    UUID        : array [0..15] of Byte;
    WakeUpType  : Byte;
  end;

  // ...
  // TDmiTypeX
  // ...

////////////////////////////////////////////////////////////////////////////////
// SMBIOS Utilities

function SmBiosGetEntryPoint(var Dump: TRomBiosDump;
  out SmEP: TSmBiosEntryPoint): PSmBiosEntryPoint;
var
  Addr: Pointer;
  Loop: Integer;
  Csum: Byte;
begin
  Result := nil;
  Addr := Pointer(RomBiosDumpBase - $10);
  while Cardinal(Addr) < RomBiosDumpEnd - SizeOf(TSmBiosEntryPoint) do
  begin
    Inc(Cardinal(Addr), $10);
    if PLongword(GetRomDumpAddr(Dump, Addr))^ = $5F4D535F then  // '_SM_'
    begin
      ReadRomDumpBuffer(Dump, Addr, SmEP, SizeOf(TSmBiosEntryPoint));
      if SmEP.Length < $1F then
        Continue;
      if SmEP.Length > SizeOf(TSmBiosEntryPoint) then
        Continue;
{$R-}
      Csum := 0;
      for Loop := 0 to SmEP.Length - 1 do
        Csum := Csum + PByteArray(@SmEP)^[Loop];
      if Csum <> 0 then
        Continue;
{$R+}
      if SmEP.Intermediate.AnchorString <> '_DMI_' then
        Continue;
{$R-}
      Csum := 0;
      for Loop := 0 to SizeOf(SmEP.Intermediate) - 1 do
        Csum := Csum + PByteArray(@SmEP.Intermediate)^[Loop];
      if Csum <> 0 then
        Continue;
{$R+}
      Result := Addr;
      Break;
    end;
  end;
end;

var
  //HACK: fix buggy tables
  FoundDmi0Hack: Boolean = False;

function SmBiosGetNextEntry(var Dump: TRomBiosDump; Entry: Pointer): Pointer;
var
  Head: TDmiHeader;
begin
  Result := nil;
  ReadRomDumpBuffer(Dump, Entry, Head, SizeOf(TDmiHeader));
  if Head.Type_ = 0 then
    FoundDmi0Hack := True;
  if (Head.Type_ <> $7F) and (Head.Length <> 0) then
  begin
    Result := Pointer(Cardinal(Entry) + Head.Length);
    while PWord(GetRomDumpAddr(Dump, Result))^ <> 0 do
      Inc(Cardinal(Result));
    Inc(Cardinal(Result), 2);
    //HACK: fix buggy tables
    if FoundDmi0Hack then
      while PByte(GetRomDumpAddr(Dump, Result))^ = 0 do
        Inc(Cardinal(Result));
  end;
end;

function SmBiosGetString(var Dump: TRomBiosDump; Entry: Pointer;
  Index: Byte): string;
var
  Head: TDmiHeader;
  Addr: Pointer;
  Loop: Integer;
begin
  Result := '';
  ReadRomDumpBuffer(Dump, Entry, Head, SizeOf(TDmiHeader));
  if Head.Length <> 0 then
  begin
    Addr := Pointer(Cardinal(Entry) + Head.Length);
    for Loop := 1 to Index - 1 do
      Inc(Cardinal(Addr), Length(PChar(GetRomDumpAddr(Dump, Addr))) + 1);
    Result := StrPas(PChar(GetRomDumpAddr(Dump, Addr)));
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// BiosHelp Sample with SMBIOS

procedure DisplayMessage(const Text: string);
{$IFDEF WIN32}
const
  RES_MAINICON_ID = 1;
var
  MBox: TMsgBoxParams;
begin
  FillChar(MBox, SizeOf(TMsgBoxParams), 0);
  MBox.cbSize := SizeOf(TMsgBoxParams);
  MBox.hwndOwner := 0;
  MBox.hInstance := HInstance;
  MBox.lpszText := PChar(Text);
  MBox.lpszCaption := 'BIOS-Info';
  MBox.dwStyle := MB_OK or MB_USERICON;
  MBox.lpszIcon := MakeIntResource(RES_MAINICON_ID);
  MessageBoxIndirect(MBox);
{$ELSE}
{$IFDEF LINUX}
begin
  Writeln(Text);
{$ENDIF}
{$ENDIF}
end;

const
  RES_MAINICON_ID = 1;
  UuidNone: array[0..15] of Byte = (
    $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00);
  UuidUnset: array[0..15] of Byte = (
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
const
  DateOffset = Pointer($000FFFF5);
var
  Dump: TRomBiosDump;
  Text: string;
  SmEP: TSmBiosEntryPoint;
  Addr: Pointer;
  TEnd: Cardinal;
  Dmi0: TDmiType0;
  Dmi1: TDmiType1;
  Loop: Integer;
begin
{$IFDEF WIN32}
  // Windows XP Visual Styles
  InitCommonControls();
{$ENDIF}

  // dump the ROM-BIOS
  if not DumpRomBios(Dump) then
  begin
{$IFDEF LINUX}
    Text := 'Error on reading BIOS!'#10;
    Text := Text + '(errno: ' + strerror(errno) + ')';
    if errno = EACCES then
      Text := Text + #10'(should run as root/kmem)';
{$ELSE}
    Text := 'Error on reading BIOS!'#10 + SysErrorMessage(GetLastError);
{$ENDIF}
    DisplayMessage(Text);
    Exit;
  end;

  Text := '[SMBIOS]'#10;

  // find SMBIOS Entry Point Structure
  if SmBiosGetEntryPoint(Dump, SmEP) = nil then
    // not found - display hardcoded date string at the end of ROM-BIOS
    Text := Text + '(SMBIOS not found)'#10#10 +
      '[BIOS Information]'#10 +
      'BIOS Release Date: ' + PChar(GetRomDumpAddr(Dump, DateOffset)) + #10
  else
  begin
    // display SMBIOS Version
    Text := Text + 'Version: ' +
      IntToStr(SmEP.MajorVersion) + '.' + IntToStr(SmEP.MinorVersion) + #10;

    // validate table address
    if (SmEP.Intermediate.TableAddress >= RomBiosDumpBase) and
      (SmEP.Intermediate.TableAddress <= RomBiosDumpEnd) then
    with SmEP do
    begin

      // scan through the table
      Addr := Pointer(Intermediate.TableAddress);
      TEnd := Intermediate.TableAddress + Intermediate.TableLength;
      repeat

        // read DMI header
        ReadRomDumpBuffer(Dump, Addr, Dmi0.Header, SizeOf(TDmiHeader));

        // BIOS Information
        if Dmi0.Header.Type_ = 0 then
        begin
          // read the full entry
          ReadRomDumpBuffer(Dump, Addr, Dmi0, SizeOf(TDmiType0));
          // validate length
          if Dmi0.Header.Length < $12 then
          begin
            Addr := SmBiosGetNextEntry(Dump, Addr);
            Continue;
          end;
          // build info text
          Text := Text + #10'[BIOS Information]'#10;
          Text := Text + 'BIOS Vendor       : ' +
            SmBiosGetString(Dump, Addr, Dmi0.Vendor) + #10;
          Text := Text + 'BIOS Version      : ' +
            SmBiosGetString(Dump, Addr, Dmi0.Version) + #10;
          Text := Text + 'BIOS Release Date : ' +
            SmBiosGetString(Dump, Addr, Dmi0.ReleaseDate) + #10;
          Text := Text + 'BIOS Start Address: ' +
            IntToHex(Dmi0.StartingSegment, 4) + ':0000 (' +
            IntToStr(($10000 - Dmi0.StartingSegment) div 64) + ' KB)'#10;
          Text := Text + 'ROM-BIOS Size     : ' +
            IntToStr((Dmi0.BiosRomSize + 1) * 64) + ' KB'#10;
        end

        // System Information
        else if Dmi0.Header.Type_ = 1 then
        begin
          // read the full entry
          ReadRomDumpBuffer(Dump, Addr, Dmi1, SizeOf(TDmiType1));
          // validate length
          if Dmi1.Header.Length < $08 then
          begin
            Addr := SmBiosGetNextEntry(Dump, Addr);
            Continue;
          end;
          // build info text
          Text := Text + #10'[System Information]'#10;
          Text := Text + 'Manufacturer       : ' +
            SmBiosGetString(Dump, Addr, Dmi1.Manufacturer) + #10;
          Text := Text + 'Product Name       : ' +
            SmBiosGetString(Dump, Addr, Dmi1.ProductName) + #10;
          Text := Text + 'System Version     : ' +
            SmBiosGetString(Dump, Addr, Dmi1.Version) + #10;
          Text := Text + 'Serial Number      : ' +
            SmBiosGetString(Dump, Addr, Dmi1.SerialNumber) + #10;
          if (Dmi1.Header.Length >= $19) then
          begin
            Text := Text + 'Universal Unique ID: ';
            if CompareMem(@Dmi1.UUID, @UuidNone, SizeOf(Dmi1.UUID)) then
              Text := Text + '<not present>'
            else if CompareMem(@Dmi1.UUID, @UuidUnset, SizeOf(Dmi1.UUID)) then
              Text := Text + '<not set>'
            else
            begin
              for Loop := 0 to 7 do
                Text := Text + IntTohex(Dmi1.UUID[Loop], 2) + ' ';
              Text := Text + '- ';
              for Loop := 8 to 15 do
                Text := Text + IntTohex(Dmi1.UUID[Loop], 2) + ' ';
            end;
            Text := Text + #10;
            Text := Text + 'Wake-up Type       : ';
            case Dmi1.WakeUpType of
              0: Text := Text + 'Reserved'#10;
              1: Text := Text + 'Other'#10;
              2: Text := Text + 'Unknown'#10;
              3: Text := Text + 'APM Timer'#10;
              4: Text := Text + 'Modem Ring'#10;
              5: Text := Text + 'LAN Remote'#10;
              6: Text := Text + 'Power Switch'#10;
              7: Text := Text + 'PCI PME#'#10;
              8: Text := Text + 'AC Power Restored'#10;
            else
              Text := Text + '<unknown> (' +
                IntToStr(Dmi1.WakeUpType) + ')'#10;
            end;
          end;
        end;

        // next entry
        Addr := SmBiosGetNextEntry(Dump, Addr);
        if Addr = nil then
          Break;

      // until end-of-table-entry found or end of table reached
      until (Dmi0.Header.Type_ = $7F) or (Cardinal(Addr) >= TEnd);

    end;
  end;

  // display whole message
  Text := Text + #10;
  Text := Text + 'BIOS related utilities for Win32'#10 +
          'BiosHelp.pas for Delphi and Kylix'#10 +
          'Copyright (c) Your Name'#10 +
          'https://github.com';

  DisplayMessage(Text);
end.
