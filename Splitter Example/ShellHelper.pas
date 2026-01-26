unit ShellHelper;

interface

uses
  Windows, ShlObj, ActiveX, ShellAPI;


  function GetIdFromPath(const iDesktopFolder: IShellFolder; Path: string;
    out pidl: PItemIdList): boolean;
  function GetShellImg(const pidl: PItemIdList; fOpen: boolean): integer;
    overload;
  function GetShellImg(const iDesktop: IShellFolder; pidl: PItemIdList;
    fOpen: boolean): integer; overload;
  function GetShellImg(const ItemPath: string; fOpen: boolean): integer;
    overload;

  function StrRetToString(const pidl: PItemIdList; StrRet: TStrRet): string;
  function GetDisplayName(const iDesktop: IShellFolder; pidl: PItemIdList;
    dwFlags: dword = SHGDN_NORMAL): string;
  function GetTypeName(const pidl: PItemIdList): string;

  function CopyPIDL(IDList: PItemIDList): PItemIDList;
  function AppendPIDL(const pidlBase, pidlAdd: PItemIdList): PItemIdList;


implementation


function GetIdFromPath(const iDesktopFolder: IShellFolder; Path: string;
  out pidl: PItemIdList): boolean;
var
  pchEaten,
  dwAttributes : dword;
  pcwPath      : array[0..MAX_PATH]of widechar;
begin
  Result       := false;
  if(iDesktopFolder <> nil) and
    (Path <> '') then
  begin
    StringToWideChar(Path,pcwPath,sizeof(pcwPath));
    iDesktopFolder.ParseDisplayName(0,nil,pcwPath,pchEaten,pidl,dwAttributes);
    Result     := (pidl <> nil);
  end;
end;

function GetShellImg(const pidl: PItemIdList; fOpen: boolean): integer;
  overload;
var
  fi        : TSHFileInfo;
  dwFlags   : dword;
begin
  Result    := -1;

  if(pidl <> nil) then
  begin
    dwFlags := SHGFI_PIDL or SHGFI_SYSICONINDEX;
    if(fOpen) then dwFlags := dwFlags or SHGFI_OPENICON;

    SHGetFileInfo(pchar(pidl),0,fi,sizeof(fi),dwFlags);
    Result  := fi.iIcon;
  end;
end;

function GetShellImg(const iDesktop: IShellFolder; pidl: PItemIdList;
  fOpen: boolean): integer; overload;
var
  isi    : IShellIcon;
  uFlags : uint;
begin
  Result := -1;
  if(iDesktop = nil) and (pidl = nil) then exit;

  if(iDesktop.QueryInterface(IID_IShellIcon,isi) = S_OK) then
  begin
    if(fOpen) then uFlags := GIL_OPENICON
      else uFlags := 0;

    if(isi <> nil) then
    begin
      if(isi.GetIconOf(pidl,uFlags,Result) <> NOERROR) then
        Result := GetShellImg(pidl,fOpen);

      isi  := nil;
    end;
  end
  else
    Result := GetShellImg(pidl,fOpen);
end;

function GetShellImg(const ItemPath: string; fOpen: boolean): integer; overload;
var
  fi        : TSHFileInfo;
  dwFlags   : dword;
begin
  Result    := -1;
  if(length(ItemPath) = 0) then exit;

  dwFlags   := SHGFI_SYSICONINDEX;
  if(fOpen) then dwFlags := dwFlags or SHGFI_OPENICON;

  SHGetFileInfo(pchar(ItemPath),0,fi,sizeof(fi),dwFlags);
  Result    := fi.iIcon;
end;

function StrRetToString(const pidl: PItemIdList; StrRet: TStrRet): string;
var
  p : pchar;
begin
  case StrRet.uType of
    STRRET_CSTR:
      SetString(Result,StrRet.cStr,lstrlen(StrRet.cStr));
    STRRET_OFFSET:
      begin
        p := @pidl.mkid.abID[StrRet.uOffset - sizeof(PIDL.mkid.cb)];
        SetString(Result,p,PIDL.mkid.cb - StrRet.uOffset);
      end;
    STRRET_WSTR:
      if(StrRet.pOleStr <> nil) then
        Result := WideCharToString(StrRet.pOleStr);
    else
      Result := '';
  end;
end;

function GetDisplayName(const iDesktop: IShellFolder; pidl: PItemIdList;
  dwFlags: dword = SHGDN_NORMAL): string;
var
  StrRet : TStrRet;
begin
  iDesktop.GetDisplayNameOf(pidl,dwFlags,StrRet);
  Result := StrRetToString(pidl,StrRet);
end;

function GetTypeName(const pidl: PItemIdList): string;
var
  fi : TSHFileInfo;
begin
  if(pidl <> nil) then
  begin
    SHGetFileInfo(pchar(pidl),0,fi,sizeof(fi),SHGFI_PIDL or SHGFI_TYPENAME);
    SetString(Result,fi.szTypeName,lstrlen(fi.szTypeName));
  end
  else
    Result := '';
end;


// -----------------------------------------------------------------------------

function GetPIDLSize(IDList: PItemIDList): Integer;
begin
  Result := 0;

  if Assigned(IDList) then
  begin
    Result := SizeOf(IDList^.mkid.cb);
    while IDList^.mkid.cb <> 0 do
    begin
      Result := Result + IDList^.mkid.cb;
      inc(pchar(IDList),IDList^.mkid.cb);
    end;
  end;
end;

function CopyPIDL(IDList: PItemIDList): PItemIDList;

  function CreatePIDL(Size: Integer): PItemIDList;
  var
    Malloc   : IMalloc;
  begin
    Result   := nil;
    if(SHGetMalloc(Malloc) = NOERROR) then
    try
      Result := Malloc.Alloc(Size);
      if Assigned(Result) then FillChar(Result^, Size, 0);
    finally
      Malloc := nil;
    end;
  end;

var
  size   : integer;
begin
  size   := GetPIDLSize(IDList);
  Result := CreatePIDL(size);
  if(Result <> nil) then CopyMemory(Result,IDList,size);
end;

function AppendPIDL(const pidlBase, pidlAdd: PItemIdList): PItemIdList;
var
  Malloc : IMalloc;
  cb1,
  cb2    : UINT;
begin
  Result := nil;
  if(pidlBase = nil) or (pidlAdd = nil) then exit;

  if(SHGetMalloc(Malloc) = NOERROR) then
  try
    cb1  := GetPIDLSize(pidlBase) - sizeof(pidlBase.mkid.cb);
    cb2  := GetPIDLSize(pidlAdd);

    Result := Malloc.Alloc(cb1 + cb2);
    if(Result <> nil) then
    begin
      CopyMemory(Result,pidlBase,cb1);
      CopyMemory(pchar(Result) + cb1,pidlAdd,cb2);
    end;
  finally
    Malloc := nil;
  end;
end;

end.
