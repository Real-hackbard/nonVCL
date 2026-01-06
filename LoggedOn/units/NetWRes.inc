function GetLANPCs: TStringArray;

  procedure EnumFunc(NetResource: PNetResource); 
  var 
    Enum: THandle; 
    Count, BufferSize: DWORD; 
    Buffer: array[0..16384 div SizeOf(TNetResource)] of TNetResource; 
    i: Integer; 
  begin 
    if WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_ANY, 0, NetResource, 
    Enum) = NO_ERROR then 
    try 
      Count := $FFFFFFFF; 
      BufferSize := SizeOf(Buffer); 
      while WNetEnumResource(Enum, Count, @Buffer, BufferSize) = NO_ERROR do
      begin
        setlength(result, Count);
        for i := 0 to Count - 1 do
        begin
          if Buffer[i].dwDisplayType = RESOURCEDISPLAYTYPE_SERVER then
            result[i] := Buffer[i].lpRemoteName;
          if (Buffer[i].dwUsage and RESOURCEUSAGE_CONTAINER) > 0 then
            EnumFunc(@Buffer[i])
        end;
      end;
    finally 
      WNetCloseEnum(Enum); 
    end; 
  end; 
begin 
  EnumFunc(nil); 
end;

function ConnectToNetworkDrive(LocalName: string;
  RemoteName: string; Username: string; Password: string;
  RestoreAtLogon: boolean ): DWORD;
var
  NetResource: TNetResource;
  dwFlags:     DWORD;
begin
  dwFlags := 0;
  ZeroMemory(@NetResource, sizeof(TNetResource));
  with NetResource do begin
    dwType := RESOURCETYPE_DISK;
    lpLocalName := PChar(LocalName);
    lpRemoteName := PChar(RemoteName);
    lpProvider := nil;
  end;

  if (RestoreAtLogon) then
    dwFlags := dwFlags or CONNECT_UPDATE_PROFILE;

  Result := WNetAddConnection2(NetResource,PChar(Password), PChar(Username),dwFlags);
end;

function DisconnectNetworkDrive(Name: String): DWORD;
begin
  result := WNetCancelConnection2(PChar(Name), CONNECT_UPDATE_PROFILE, True);
end;
