unit BrowseForFolderCls;

interface

uses
  ShlObj, ActiveX, Windows, Messages;

type
  TFolderBrowser = class
  private
    // alles private gemacht; geht niemanden was an,
    // da nachträglicher Zugriff sinnlos (Luckie)
    FHandle: THandle;
    FCaption: string;
    FShowFiles: boolean;
    FNewFolder: boolean;
    FStatusText: boolean;
    FNoTT: boolean;
    FInitFolder: string;
    FSelected: string;

    // Multiple filters must be separated by #0.
    // will be, for example, '*.txt'#0'*.*htm*'#0'*.xml'
    // The last filter can end with #0#0, but it must
    // not because the "CheckFilter" function includes these two
    // automatically appends characters
    FFilter: string;
    FRoot: PItemIdList;
    procedure FreeItemIDList(var pidl: pItemIDList);
  public
    constructor Create(Handle: THandle; const Caption: string;
      const PreSelectedFolder: string = ''; ShowFiles: Boolean = False;
      NewFolder: Boolean = False);
    destructor Destroy; override;
    function SetDefaultRoot: boolean;
    function SetRoot(const SpecialFolderId: integer): boolean; overload;
    function SetRoot(const Path: string): boolean; overload;
    function Execute: Boolean; overload;
    function TranslateLink(const LnkFile: string): string;

    property SelectedItem: string read FSelected;
    property Filter: string read FFilter write FFilter;
    property NewFolderButton: boolean read FNewFolder write FNewFolder;
    property ShowFiles: boolean read FShowFiles write FShowFiles;
    property StatusText: boolean read FStatusText write FStatusText;
    property NoTargetTranslation: boolean read FNoTT write FNoTT;
  end;

implementation

//
// extended SHBrowseForFolder properties
// (Declaration is necessary because it may not be available in every Delphi version.)
// known and available)
//
const
  BIF_NEWDIALOGSTYLE = $0040;
  BIF_USENEWUI = BIF_NEWDIALOGSTYLE or BIF_EDITBOX;
  BIF_BROWSEINCLUDEURLS = $0080;
  BIF_UAHINT = $0100;
  BIF_NONEWFOLDERBUTTON = $0200;
  BIF_NOTRANSLATETARGETS = $0400;
  BIF_SHAREABLE = $8000;

  BFFM_IUNKNOWN = 5;
  BFFM_SETOKTEXT = WM_USER + 105; // Unicode only
  BFFM_SETEXPANDED = WM_USER + 106; // Unicode only

// -- helper functions ---------------------------------------------------------

function fileexists(const FileName: string): boolean;
var
  Handle: THandle;
  FindData: TWin32FindData;
begin
  Handle := FindFirstFile(pchar(FileName), FindData);
  Result := (Handle <> INVALID_HANDLE_VALUE);

  if (Result) then
    FindClose(Handle);
end;

function CheckFilter(const Path, Filter: string): boolean;
var
  p: pchar;
begin
  // Standard result
  Result := false;
  if (Path = '') or (Filter = '') then
    exit;

  // Append #0#0 to the filter so that the end is later
  // is recognized correctly
  p := pchar(Filter + #0#0);
  while (p[0] <> #0) do
  begin
    // A file matching the filter was found, ...
    if (fileexists(Path + '\' + p)) then
    begin
    // ... Set result to TRUE and break loop
      Result := true;
      break;
    end;

    // otherwise go to the next filter
    inc(p, lstrlen(p) + 1);
  end;
end;

function SHGetIDListFromPath(const Path: string; out pidl: PItemIDList):
  boolean;
var
  ppshf: IShellFolder;
  wpath: array[0..MAX_PATH] of widechar;
  pchEaten,
    dwAttributes: Cardinal;
begin
  // Standard result
  Result := false;

  // Get IShellFolder handle
  if (SHGetDesktopFolder(ppshf) = S_OK) then
  try
    if (StringToWideChar(Path, wpath, sizeof(wpath)) <> nil) then
    begin
      // Convert path name to "PItemIdList"
      ppshf.ParseDisplayName(0, nil, wpath, pchEaten, pidl, dwAttributes);
      Result := pidl <> nil;
    end;
  finally
    ppshf := nil;
  end;
end;

//
// "CreateComObject" (modified version; )
//

function CreateComObject(const ClassID: TGUID;
  out OleResult: HRESULT): IUnknown;
begin
  OleResult := CoCreateInstance(ClassID, nil, CLSCTX_INPROC_SERVER or
    CLSCTX_LOCAL_SERVER, IUnknown, Result);
end;

// -----------------------------------------------------------------------------
//
// TFolderBrowser-Klasse
//
// -----------------------------------------------------------------------------

function FolderCallback(wnd: HWND; uMsg: UINT; lp, lpData: LPARAM): LRESULT;
  stdcall;
var
  path: array[0..MAX_PATH + 1] of char;
  fb: TFolderBrowser;
begin
  fb := TFolderBrowser(lpData);

  case uMsg of
    // Dialog has been initialized
    BFFM_INITIALIZED:
      begin
        // Select folder, ...
        if (fb.FInitFolder <> '') then
          SendMessage(wnd, BFFM_SETSELECTION, WPARAM(true),
            LPARAM(pchar(fb.FInitFolder)));

        // ... & Disable the OK button when filters are used.
        SendMessage(wnd, BFFM_ENABLEOK, 0, LPARAM(fb.FFilter = ''));
        // Or in other words: activate the OK button if there are none
        // Filters are used. ;o)
      end;
    BFFM_SELCHANGED:
      if (PItemIdList(lp) <> nil) and (fb.FFilter <> '') then
      begin
        // retrieve the current path name, ...
        ZeroMemory(@path, sizeof(path));
        if (SHGetPathFromIdList(PItemIdList(lp), path)) then
        begin
        // ... & show
          SendMessage(wnd, BFFM_SETSTATUSTEXT, 0, LPARAM(@path));

        // Are there any files with the filter?
        // Only then will the OK button of the dialog be activated.
          SendMessage(wnd, BFFM_ENABLEOK, 0, LPARAM(CheckFilter(path,
            fb.FFilter)));
        end;
      end;
  end;

  Result := 0; // Added by Luckie, I forgot to mention that (oops)
end;

constructor TFolderBrowser.Create(Handle: THandle; const Caption: string;
  const PreSelectedFolder: string = ''; ShowFiles: Boolean = False;
  NewFolder: Boolean = False);
begin
  FHandle := Handle;
  FCaption := Caption;
  FInitFolder := PreSelectedFolder;
  FShowFiles := ShowFiles;
  FNewFolder := NewFolder;
  FStatusText := true;
  FNoTT := false;
  FFilter := '';
  FRoot := nil;
end;

destructor TFolderBrowser.Destroy;
begin
  // Release any occupied "PItemIdList"
  if (FRoot <> nil) then
    self.FreeItemIdList(FRoot);

  inherited Destroy;
end;

function TFolderBrowser.SetDefaultRoot: boolean;
begin
  // release old object
  if (FRoot <> nil) then
    self.FreeItemIDList(FRoot);

  // and reset everything
  FRoot := nil;
  Result := true;
end;

function TFolderBrowser.SetRoot(const SpecialFolderId: integer): boolean;
begin
  // release old object
  if (FRoot <> nil) then
    self.FreeItemIDList(FRoot);

  // SpecialFolderId can be one of the CSIDL_* constants,
  //   CSIDL_DESKTOP
  //   CSIDL_STARTMENU
  //   CSIDL_PERSONAL
  //   ...
  // s. PSDK

  // set new root
  Result := SHGetSpecialFolderLocation(FHandle, SpecialFolderId, FRoot) = S_OK;
end;

function TFolderBrowser.SetRoot(const Path: string): boolean;
begin
  // release old object
  if (FRoot <> nil) then
    self.FreeItemIDList(FRoot);

  // set new root
  Result := SHGetIDListFromPath(Path, FRoot);
end;

function TFolderBrowser.Execute: Boolean;
var
  BrowseInfo: TBrowseInfo;
  pidlResult: PItemIDList;
  DisplayName,
    Path: array[0..MAX_PATH + 1] of char;
begin
  Result := false;

  if (CoInitialize(nil) = S_OK) then
  try
    // "BrowseInfo" fill with values
    ZeroMemory(@BrowseInfo, sizeof(BrowseInfo));
    BrowseInfo.hwndOwner := FHandle;
    BrowseInfo.pidlRoot := FRoot;
    BrowseInfo.pszDisplayName := @Displayname;
    BrowseInfo.lpszTitle := pchar(FCaption);
    BrowseInfo.lpfn := @FolderCallBack;

    // TFolderBrowser class as a reference for callback function
    // handed over (PL)
    BrowseInfo.lParam := LPARAM(self);

    // Flags
    if (FStatusText) then
      BrowseInfo.ulFlags := BrowseInfo.ulFlags or BIF_STATUSTEXT;

    // BIF_USENEWUI ensures that said button is always displayed.
    // regardless of whether BIF_BROWSEINCLUDEFILES is set or not, therefore
    // removed
    if (FShowFiles) then
      BrowseInfo.ulFlags := BrowseInfo.ulFlags or BIF_BROWSEINCLUDEFILES;

    // Show button for creating new folders? (Luckie, PL)
    if (FNewFolder) then
      BrowseInfo.ulFlags := BrowseInfo.ulFlags or BIF_NEWDIALOGSTYLE
    else
      BrowseInfo.ulFlags := BrowseInfo.ulFlags or BIF_NONEWFOLDERBUTTON;

    // Windows automatically searches for the shortcut targets of
    // Shortcuts out; but instead, the name of the
    // The flag BIF_NOTRANSLATETARGETS is used to display the link.
    // required; only makes sense under Windows
    if (FNoTT) then
      BrowseInfo.ulFlags := BrowseInfo.ulFlags or BIF_NOTRANSLATETARGETS;
    // For older Windows versions, there is a function
    // "TranslateLink" (see below) is an equivalent to the
    // Determining the goals of shortcuts

    // Open dialog
    pidlResult := SHBrowseForFolder(BrowseInfo);
    if (pidlResult <> nil) then
    begin
      if (FSelected = '') then
        if (SHGetPathFromIdList(pidlResult, Path)) and
          (Path[0] <> #0) then
        begin
          FSelected := Path;
          Result := true;
        end;

      self.FreeItemIdList(pidlResult);
    end;
  finally
    CoUninitialize;
  end;
end;

function TFolderBrowser.TranslateLink(const LnkFile: string): string;

  function ExpandEnvStr(const szInput: string): string;
  const
    MAXSIZE = 32768;
  begin
    SetLength(Result, MAXSIZE);
    SetLength(Result, ExpandEnvironmentStrings(pchar(szInput),
      @Result[1], length(Result)));
  end;

var
  link: IShellLink;
  hr: HRESULT;
  afile: IPersistFile;
  pwcLnkFile: array[0..MAX_PATH] of widechar;
  szData: array[0..MAX_PATH] of char;
  FindData: TWin32FindData;
begin
  // Standard result
  Result := '';
  link := nil;
  afile := nil;

  if (CoInitialize(nil) = S_OK) then
  try
    // Create IShellLink interface, ...
    link := CreateComObject(CLSID_ShellLink, hr) as IShellLink;
    if (hr = S_OK) and (link <> nil) then
    begin
    // ... & Load shortcut
      StringToWideChar(LnkFile, pwcLnkFile, sizeof(pwcLnkFile));
      afile := link as IPersistFile;

      if (afile <> nil) and
        (afile.Load(pwcLnkFile, STGM_READ) = S_OK) then
      begin
        ZeroMemory(@szData, sizeof(szData));

    // Determine path and filename, ...
        if (link.GetPath(szData, sizeof(szData), FindData,
          SLGP_RAWPATH) = S_OK) then
        begin
          SetString(Result, szData, lstrlen(szData));
    // ... & Possibly filter environment variables
          Result := ExpandEnvStr(Result);
        end;
      end;
    end;
  finally
    if (afile <> nil) then
      afile := nil;
    if (link <> nil) then
      link := nil;

    CoUninitialize;
  end;
end;

procedure TFolderBrowser.FreeItemIDList(var pidl: pItemIDList);
var
  ppMalloc: iMalloc;
begin
  if (SHGetMalloc(ppMalloc) = S_OK) then
  try
    ppMalloc.Free(pidl);
    pidl := nil;
  finally
    ppMalloc := nil;
  end;
end;

end.

