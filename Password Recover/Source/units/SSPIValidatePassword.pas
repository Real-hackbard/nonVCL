{$A+,B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
(*======================================================================*
 | SSPIValidatePassword                                                 |
 |                                                                      |
 | Validate NT passwords using the SSPI                                 |
 |                                                                      |
 | See MSDN article HOWTO: Validate User Credentials on Microsoft WinNT |
 | and Win95, and without Act As Part Of Operating System privilege     |
 |                                                                      |
 | nb.  Using this method is is analogous to calling the LogonUser API  |
 | with the LOGON32_LOGON_NETWORK logon type. The biggest downside to   |
 | this type of logon is that you cannot access remote network          |
 | resources after impersonating a network type logon.                  |
 |                                                                      |
 | Hence the function doesn't return an HTOKEN, like LogonUser does.    |
 |                                                                      |
 | Copyright (c) Colin Wilson 2001                                      |
 |                                                                      |
 | Version  Date        By    Description                               |
 | -------  ----------  ----  ------------------------------------------|
 | 1.0      01/03/2001  CPWW  Original                                  |
 *======================================================================*)


unit SSPIValidatePassword;


interface


uses Windows, SysUtils;


function SSPLogonUser(const DomainName, UserName, Password: string): boolean;


implementation

var
  Win32Platform: Integer = 0;

const


  //---------------------------------------------------------------------
  // Define SSPI constants


  SEC_WINNT_AUTH_IDENTITY_ANSI = $01;
  SECPKG_CRED_INBOUND    = $00000001;
  SECPKG_CRED_OUTBOUND   = $00000002;
  SECPKG_CRED_BOTH       = $00000003;
  SECPKG_CRED_DEFAULT    = $00000004;
  SECPKG_CRED_RESERVED   = $F0000000;


  SECBUFFER_VERSION      = 0;


  SECBUFFER_EMPTY        = 0; // Undefined, replaced by provider
  SECBUFFER_DATA         = 1; // Packet data
  SECBUFFER_TOKEN        = 2; // Security token
  SECBUFFER_PKG_PARAMS   = 3; // Package specific parameters
  SECBUFFER_MISSING      = 4; // Missing Data indicator
  SECBUFFER_EXTRA        = 5; // Extra data
  SECBUFFER_STREAM_TRAILER = 6; // Security Trailer
  SECBUFFER_STREAM_HEADER = 7; // Security Header
  SECBUFFER_NEGOTIATION_INFO = 8; // Hints from the negotiation pkg
  SECBUFFER_PADDING      = 9; // non-data padding
  SECBUFFER_STREAM       = 10; // whole encrypted message


  SECBUFFER_ATTRMASK     = $F0000000;
  SECBUFFER_READONLY     = $80000000; // Buffer is read-only
  SECBUFFER_RESERVED     = $40000000;


  SECURITY_NATIVE_DREP   = $00000010;
  SECURITY_NETWORK_DREP  = $00000000;


  SEC_I_CONTINUE_NEEDED  = $00090312;
  SEC_I_COMPLETE_NEEDED  = $00090313;
  SEC_I_COMPLETE_AND_CONTINUE = $00090314;


  //---------------------------------------------------------------------
  // Define SSPI types


type
  TSecWinntAuthIdentity = packed record
    User: PChar;
    UserLength: DWORD;
    Domain: PChar;
    DomainLength: DWORD;
    Password: PChar;
    PasswordLength: DWORD;
    Flags: DWORD
  end;
  PSecWinntAuthIdentity = ^TSecWinntAuthIdentity;


  TSecHandle = packed record
    dwLower: DWORD;
    dwUpper: DWORD
  end;
  PSecHandle = ^TSecHandle;


  TSecBuffer = packed record
    cbBuffer: DWORD;
    BufferType: DWORD; // Type of the buffer (below)
    pvBuffer: pointer;
  end;
  PSecBuffer = ^TSecBuffer;


  TSecBufferDesc = packed record
    ulVersion,
      cBuffers: DWORD; // Number of buffers
    pBuffers: PSecBuffer
  end;
  PSecBufferDesc = ^TSecBufferDesc;


  TCredHandle = TSecHandle;
  PCredHandle = PSecHandle;


  TCtxtHandle = TSecHandle;
  PCtxtHandle = PSecHandle;


  TAuthSeq = packed record
    _fNewConversation: BOOL;
    _hcred: TCredHandle;
    _fHaveCredHandle: BOOL;
    _fHaveCtxtHandle: BOOL;
    _hctxt: TSecHandle;
  end;
  PAuthSeq = ^TAuthSeq;


  PNode = ^TNode;
  TNode = record
    dwKey: DWORD;
    pData: pointer;
    pNext: PNode
  end;


  TSecPkgInfo = record
    fCapabilities: DWORD; // Capability bitmask
    wVersion: WORD; // Version of driver
    wRPCID: WORD; // ID for RPC Runtime
    cbMaxToken: DWORD; // Size of authentication token (max)
    Name: PChar;
    Comment: PChar; // Comment
  end;
  PSecPkgInfo = ^TSecPkgInfo;


  TSecurityStatus = LongInt;


  ENUMERATE_SECURITY_PACKAGES_FN_A = function(var cPackages: DWORD; var PackageInfo: PSecPkgInfo): TSecurityStatus;
  stdcall;
  QUERY_SECURITY_PACKAGE_INFO_FN_A = function(packageName: PChar; var info: PSecPkgInfo): TSecurityStatus; stdcall;
  QUERY_CREDENTIALS_ATTRIBUTES_FN_A = function(phCredential: pCredHandle; ulAttribute: DWORD; buffer: pointer):
    TSecurityStatus; stdcall;
  EXPORT_SECURITY_CONTEXT_FN = function(hContext: pCtxtHandle; flags: DWORD; pPackedContext: PSecBuffer; var token:
    pointer): TSecurityStatus;
  SEC_GET_KEY_FN = procedure(Arg, Principal: pointer; KeyVer: DWORD; var Key: pointer; var status: TSecurityStatus);


  ACQUIRE_CREDENTIALS_HANDLE_FN_A = function(
    pszPrincipal: PChar;
    pszPackage: PChar;
    fCredentialUse: DWORD;
    pvLogonID: pointer;
    pAuthData: pointer;
    pGetKeyFn: SEC_GET_KEY_FN;
    pvGetKeyArgument: pointer;
    var phCredential: TCredHandle;
    var ptsExpiry: TTimeStamp): TSecurityStatus; stdcall;


  FREE_CREDENTIALS_HANDLE_FN = function(credHandle: PCredHandle): TSecurityStatus; stdcall;


  INITIALIZE_SECURITY_CONTEXT_FN_A = function(
    phCredential: PCredHandle;
    phContent: PCtxtHandle;
    pszTargetName: PChar;
    fContextReq,
    Reserved1,
    TargetDataRep: DWORD;
    pInput: PSecBufferDesc;
    Reserved2: DWORD;
    phNewContext: PCtxtHandle;
    pOutput: PSecBufferDesc;
    var pfContextAttr: DWORD;
    var ptsExpiry: TTimeStamp): TSecurityStatus; stdcall;


  ACCEPT_SECURITY_CONTEXT_FN = function(
    phCredential: PCredHandle;
    phContext: PCtxtHandle;
    pInput: PSecBufferDesc;
    fContextReq,
    TargetDataRep: DWORD;
    phNewContext: PCtxtHandle;
    pOutput: PSecBufferDesc;
    var pfContextAttr: DWORD;
    var ptsExpiry: TTimeStamp): TSecurityStatus; stdcall;


  COMPLETE_AUTH_TOKEN_FN = function(phContext: PCtxtHandle; pToken: PSecBufferDesc): TSecurityStatus; stdcall;
  DELETE_SECURITY_CONTEXT_FN = function(phContext: PCtxtHandle): TSecurityStatus; stdcall;
  APPLY_CONTROL_TOKEN_FN = function(phContext: PCtxtHandle; pInput: PSecBufferDesc): TSecurityStatus; stdcall;
  QUERY_CONTEXT_ATTRIBUTES_FN_A = function(phContext: PCtxtHandle; alAttribute: DWORD; pBuffer: pointer):
    TSecurityStatus; stdcall;
  IMPERSONATE_SECURITY_CONTEXT_FN = function(phContext: PCtxtHandle): TSecurityStatus; stdcall;
  REVERT_SECURITY_CONTEXT_FN = function(phContext: PCtxtHandle): TSecurityStatus; stdcall;
  MAKE_SIGNATURE_FN = function(phContext: PCtxtHandle; fQOP: DWORD; pMessage: PSecBufferDesc; MessageSeqNo: DWORD):
    TSecurityStatus; stdcall;
  VERIFY_SIGNATURE_FN = function(phContext: PCtxtHandle; pMessage: PSecBufferDesc; MessageSeqNo: DWORD; var fQOP:
    DWORD): TSecurityStatus; stdcall;
  FREE_CONTEXT_BUFFER_FN = function(contextBuffer: pointer): TSecurityStatus; stdcall;
  IMPORT_SECURITY_CONTEXT_FN_A = function(pszPackage: PChar; pPackedContext: PSecBuffer; Token: pointer; phContext:
    PCtxtHandle): TSecurityStatus; stdcall;


  ADD_CREDENTIALS_FN_A = function(
    hCredentials: PCredHandle;
    pszPrincipal,
    pszPackage: PChar;
    fCredentialUse: DWORD;
    pAuthData: pointer;
    pGetKeyFn: SEC_GET_KEY_FN;
    pvGetKeyArgument: pointer;
    var ptsExpiry: TTimeStamp): TSecurityStatus; stdcall;


  QUERY_SECURITY_CONTEXT_TOKEN_FN = function(phContext: PCtxtHandle; var token: pointer): TSecurityStatus; stdcall;
  ENCRYPT_MESSAGE_FN = function(phContext: PCtxtHandle; fQOP: DWORD; pMessage: PSecBufferDesc; MessageSeqNo: DWORD):
    TSecurityStatus; stdcall;
  DECRYPT_MESSAGE_FN = function(phContext: PCtxtHandle; pMessage: PSecBufferDesc; MessageSeqNo: DWORD; fQOP: DWORD):
    TSecurityStatus; stdcall;


  TSecurityFunctionTable = record
    dwVersion: LongInt;
    EnumerateSecurityPackagesA: ENUMERATE_SECURITY_PACKAGES_FN_A;
    QueryCredentialsAttributesA: QUERY_CREDENTIALS_ATTRIBUTES_FN_A;
    AcquireCredentialsHandleA: ACQUIRE_CREDENTIALS_HANDLE_FN_A;
    FreeCredentialHandle: FREE_CREDENTIALS_HANDLE_FN;
    Reserved2: FARPROC;
    InitializeSecurityContextA: INITIALIZE_SECURITY_CONTEXT_FN_A;
    AcceptSecurityContext: ACCEPT_SECURITY_CONTEXT_FN;
    CompleteAuthToken: COMPLETE_AUTH_TOKEN_FN;
    DeleteSecurityContext: DELETE_SECURITY_CONTEXT_FN;
    ApplyControlToken: APPLY_CONTROL_TOKEN_FN;
    QueryContextAttributesA: QUERY_CONTEXT_ATTRIBUTES_FN_A;
    ImpersonateSecurityContext: IMPERSONATE_SECURITY_CONTEXT_FN;
    RevertSecurityContext: REVERT_SECURITY_CONTEXT_FN;
    MakeSignature: MAKE_SIGNATURE_FN;
    VerifySignature: VERIFY_SIGNATURE_FN;
    FreeContextBuffer: FREE_CONTEXT_BUFFER_FN;
    QuerySecurityPackageInfoA: QUERY_SECURITY_PACKAGE_INFO_FN_A;
    Reserved3: FARPROC;
    Reserved4: FARPROC;
    ExportSecurityContext: EXPORT_SECURITY_CONTEXT_FN;
    ImportSecurityContextA: IMPORT_SECURITY_CONTEXT_FN_A;
    AddCredentialsA: ADD_CREDENTIALS_FN_A;
    Reserved8: FARPROC;
    QuerySecurityContextToken: QUERY_SECURITY_CONTEXT_TOKEN_FN;
    EncryptMessage: ENCRYPT_MESSAGE_FN;
    DecryptMessage: DECRYPT_MESSAGE_FN;
  end;
  PSecurityFunctionTable = ^TSecurityFunctionTable;


const
  head                   : TNode = (dwKey: $FFFFFFFF; pData: nil; pNext: nil); // List of RPC entries


  (*----------------------------------------------------------------------*
   | function GetEntry : boolean                                          |
   |                                                                      |
   | Get entry in RPC list                                                |
   *----------------------------------------------------------------------*)

function GetEntry(dwKey: DWORD; var pData: pointer): boolean;
var
  pCurrent               : PNode;
begin
  result := False;
  pCurrent := Head.pNext;
  while Assigned(pCurrent) do
  begin
    if pCurrent^.dwKey = dwKey then
    begin
      pData := pCurrent^.pData;
      result := True;
      break
    end;
    pCurrent := pCurrent^.pNext
  end
end;


(*----------------------------------------------------------------------*
 | function AddEntry : boolean                                          |
 |                                                                      |
 | Add entry to RPC list                                                |
 *----------------------------------------------------------------------*)

function AddEntry(dwKey: DWORD; pData: pointer): boolean;
var
  pTemp                  : PNode;


begin
  GetMem(pTemp, sizeof(TNode));
  if Assigned(pTemp) then
  begin
    pTemp^.dwKey := dwKey;
    pTemp^.pData := pData;
    pTemp^.pNext := Head.pNext;
    Head.pNext := pTemp;
    result := True
  end
  else
    result := False
end;


(*----------------------------------------------------------------------*
 | function DeleteEntry : boolean                                       |
 |                                                                      |
 | Delete entry from RPC list                                           |
 *----------------------------------------------------------------------*)

function DeleteEntry(dwKey: DWORD; var ppData: pointer): boolean;
var
  pCurrent, pTemp        : PNode;
begin
  result := False;
  pTemp := @head;
  pCurrent := Head.pNext;
  while pCurrent <> nil do
  begin
    if dwKey = pCurrent^.dwKey then
    begin
      pTemp^.pNext := pCurrent^.pNext;
      ppData := pCurrent^.pData;
      FreeMem(pCurrent);
      result := True;
      break
    end
    else
    begin
      pTemp := pCurrent;
      pCurrent := pCurrent^.pNext
    end
  end
end;


(*----------------------------------------------------------------------*
 | InitSession                                                          |
 |                                                                      |
 | Initialize RPC session                                               |
 *----------------------------------------------------------------------*)

function InitSession(dwKey: DWORD): boolean;
var
  pAS                    : PAuthSeq;
begin
  result := False;
  GetMem(pAS, sizeof(TAuthSeq));
  if Assigned(pAS) then
  try
    pAS^._fNewConversation := TRUE;
    pAS^._fHaveCredHandle := FALSE;
    pAS^._fHaveCtxtHandle := FALSE;
    if not AddEntry(dwKey, pAS) then
      FreeMem(pAS)
    else
      result := True
  except
    FreeMem(pAS);
    //raise
  end
end;


(*----------------------------------------------------------------------*
 | InitPackage                                                          |
 |                                                                      |
 | Initialize the NTLM security package                                 |
 *----------------------------------------------------------------------*)

function InitPackage(var cbMaxMessage: DWORD; var funcs: PSecurityFunctionTable): THandle;
type
  INIT_SECURITY_ENTRYPOINT_FN_A = function: PSecurityFunctionTable;
var
  pInit                  : INIT_SECURITY_ENTRYPOINT_FN_A;
  ss                     : TSecurityStatus;
  pkgInfo                : PSecPkgInfo;
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
    result := LoadLibrary('security.dll')
  else
    result := LoadLibrary('Secur32.dll');
  if result <> 0 then
  try
    pInit := GetProcAddress(result, 'InitSecurityInterfaceA');
    if not Assigned(pInit) then
      raise Exception.CreateFmt('Couldn''t get sec init routine: %d', [GetLastError]);
    funcs := pInit;
    if not Assigned(funcs) then
      raise Exception.Create('Couldn''t init package');
    ss := funcs^.QuerySecurityPackageInfoA('NTLM', pkgInfo);
    if ss < 0 then
      raise Exception.CreateFmt('Couldn''t query package info for NTLM, error %d\n', [ss]);
    cbMaxMessage := pkgInfo^.cbMaxToken;
    funcs^.FreeContextBuffer(pkgInfo)
  except
    if result <> 0 then
      FreeLibrary(result);
    raise
  end
end;


(*----------------------------------------------------------------------*
 | GenClientContext                                                     |
 *----------------------------------------------------------------------*)

function GenClientContext(
  funcs: PSecurityFunctionTable;
  dwKey: DWORD;
  Auth: PSecWINNTAuthIdentity;
  pIn: PBYTE;
  cbIn: DWORD;
  pOut: PBYTE;
  var cbOut: DWORD;
  var fDone: boolean): boolean;
var
  ss                     : TSecurityStatus;
  lifeTime               : TTimeStamp;
  OutBuffDesc            : TSecBufferDesc;
  OutSecBuff             : TSecBuffer;
  InBuffDesc             : TSecBufferDesc;
  InSecBuff              : TSecBuffer;
  ContextAttributes      : DWORD;
  pAS                    : PAuthSeq;
  phctxt                 : PCtxtHandle;
  pBuffDesc              : PSecBufferDesc;
begin
  result := False;
  if GetEntry(dwKey, pointer(pAS)) then
  try
    if pAS^._fNewConversation then
    begin
      ss := funcs^.AcquireCredentialsHandleA(nil, 'NTLM', SECPKG_CRED_OUTBOUND, nil, Auth, nil, nil, pAS^._hcred,
        Lifetime);
      if ss < 0 then
        raise Exception.CreateFmt('AquireCredentials failed %d', [ss]);
      pAS^._fHaveCredHandle := TRUE
    end;
    OutBuffDesc.ulVersion := 0;
    OutBuffDesc.cBuffers := 1;
    OutBuffDesc.pBuffers := @OutSecBuff;
    OutSecBuff.cbBuffer := cbOut;
    OutSecBuff.BufferType := SECBUFFER_TOKEN;
    OutSecBuff.pvBuffer := pOut;
    // prepare input buffer
    //
    if not pAS^._fNewConversation then
    begin
      InBuffDesc.ulVersion := 0;
      InBuffDesc.cBuffers := 1;
      InBuffDesc.pBuffers := @InSecBuff;
      InSecBuff.cbBuffer := cbIn;
      InSecBuff.BufferType := SECBUFFER_TOKEN;
      InSecBuff.pvBuffer := pIn
    end;
    if pAS^._fNewConversation then
    begin
      pBuffDesc := nil;
      phctxt := nil
    end
    else
    begin
      phctxt := @pAS^._hctxt;
      pBuffDesc := @InBuffDesc
    end;
    ss := funcs^.InitializeSecurityContextA(@pAS^._hcred, phctxt, 'AuthSamp', 0, 0, SECURITY_NATIVE_DREP, pBuffDesc, 0,
      @pAS^._hctxt, @OutBuffDesc, ContextAttributes, Lifetime);
    if ss < 0 then
      raise Exception.CreateFmt('Init context failed: %d', [ss]);
    pAS^._fHaveCtxtHandle := TRUE;
    if (ss = SEC_I_COMPLETE_NEEDED) or (ss = SEC_I_COMPLETE_AND_CONTINUE) then
    begin
      if Assigned(funcs^.CompleteAuthToken) then
      begin
        ss := funcs^.CompleteAuthToken(@pAS^._hctxt, @OutBuffDesc);
        if ss < 0 then
          raise Exception.CreateFmt('Complete failed: %d', [ss])
      end
    end;
    cbOut := OutSecBuff.cbBuffer;
    if pAS^._fNewConversation then
      pAS^._fNewConversation := FALSE;
    fDone := (ss <> SEC_I_CONTINUE_NEEDED) and (ss <> SEC_I_COMPLETE_AND_CONTINUE);
    result := True
  except
  end
end;


(*----------------------------------------------------------------------*
 | GenServerContext                                                     |
 *----------------------------------------------------------------------*)

function GenServerContext(
  funcs: PSecurityFunctionTable;
  dwKey: DWORD;
  pIn: PByte;
  cbIn: DWORD;
  pOut: PByte;
  var cbOut: DWORD;
  var fDone: boolean): boolean;
var
  ss                     : TSecurityStatus;
  Lifetime               : TTimeStamp;
  OutBuffDesc, InBuffDesc: TSecBufferDesc;
  InSecBuff, OutSecBuff  : TSecBuffer;
  ContextAttributes      : DWORD;
  pAS                    : PAuthSeq;
  phctxt                 : PCtxtHandle;
begin
  result := False;
  if GetEntry(dwKey, pointer(pAS)) then
  try
    if pAS^._fNewConversation then
    begin
      ss := funcs^.AcquireCredentialsHandleA(nil, 'NTLM', SECPKG_CRED_INBOUND, nil, nil, nil, nil, pAS^._hcred, Lifetime);
      if ss < 0 then
        raise Exception.CreateFmt('AcquireCreds failed %d', [ss]);
      pAS^._fHaveCredHandle := TRUE
    end;
    // prepare output buffer
    //
    OutBuffDesc.ulVersion := 0;
    OutBuffDesc.cBuffers := 1;
    OutBuffDesc.pBuffers := @OutSecBuff;
    OutSecBuff.cbBuffer := cbOut;
    OutSecBuff.BufferType := SECBUFFER_TOKEN;
    OutSecBuff.pvBuffer := pOut;
    // prepare input buffer
    //
    InBuffDesc.ulVersion := 0;
    InBuffDesc.cBuffers := 1;
    InBuffDesc.pBuffers := @InSecBuff;
    InSecBuff.cbBuffer := cbIn;
    InSecBuff.BufferType := SECBUFFER_TOKEN;
    InSecBuff.pvBuffer := pIn;
    if pAS^._fNewConversation then
      phctxt := nil
    else
      phctxt := @pAS^._hctxt;
    ss := funcs^.AcceptSecurityContext(
      @pAS^._hcred,
      phctxt,
      @InBuffDesc,
      0, // context requirements
      SECURITY_NATIVE_DREP,
      @pAS^._hctxt,
      @OutBuffDesc,
      ContextAttributes,
      Lifetime
      );
    if ss < 0 then
      raise Exception.CreateFmt('init context failed: %d', [ss]);
    pAS^._fHaveCtxtHandle := TRUE;
    // Complete token -- if applicable
    //
    if (ss = SEC_I_COMPLETE_NEEDED) or (ss = SEC_I_COMPLETE_AND_CONTINUE) then
    begin
      if Assigned(funcs^.CompleteAuthToken) then
      begin
        ss := funcs^.CompleteAuthToken(@pAS^._hctxt, @OutBuffDesc);
        if ss < 0 then
          raise Exception.CreateFmt('complete failed: %d', [ss]);
      end
      else
        raise Exception.Create('Complete not supported.');
    end;
    cbOut := OutSecBuff.cbBuffer;
    if pAS^._fNewConversation then
      pAS^._fNewConversation := FALSE;
    fDone := (ss <> SEC_I_CONTINUE_NEEDED) and (ss <> SEC_I_COMPLETE_AND_CONTINUE);
    result := True
  except
  end
end;


(*----------------------------------------------------------------------*
 | TermSession                                                          |
 |                                                                      |
 | Tidy up RPC session                                                  |
 *----------------------------------------------------------------------*)

function TermSession(funcs: PSecurityFunctionTable; dwKey: DWORD): boolean;
var
  pAS                    : PAuthSeq;
begin
  result := False;
  if DeleteEntry(dwKey, pointer(pAS)) then
  begin
    if pAS^._fHaveCtxtHandle then
      funcs^.DeleteSecurityContext(@pAS^._hctxt);
    if pAS^._fHaveCredHandle then
      funcs^.FreeCredentialHandle(@pAS^._hcred);
    freemem(pAS);
    result := True
  end
end;


(*----------------------------------------------------------------------*
 | SSPLogonUser                                                         |
 |                                                                      |
 | Validate password for user/domain.  Returns true if the password is  |
 | valid.                                                               |
 *----------------------------------------------------------------------*)

function SSPLogonUser(const DomainName, UserName, Password: string): boolean;
var
  done                   : boolean;
  cbOut, cbIn            : DWORD;
  AuthIdentity           : TSecWINNTAuthIdentity;
  session0OK, session1OK : boolean;
  packageHandle          : THandle;
  pClientBuf             : PByte;
  pServerBuf             : PByte;
  cbMaxMessage           : DWORD;
  funcs                  : PSecurityFunctionTable;
begin
  result := False;
  try
    done := False;
    session1OK := False;
    packageHandle := 0;
    pClientBuf := nil;
    pServerBuf := nil;
    cbMaxMessage := 0;
    session0OK := InitSession(0);
    try
      session1OK := InitSession(1);
      packageHandle := InitPackage(cbMaxMessage, funcs);
      if session0OK and session1OK and (packageHandle <> 0) then
      begin
        GetMem(pClientBuf, cbMaxMessage);
        GetMem(pServerBuf, cbMaxMessage);
        FillChar(AuthIdentity, sizeof(AuthIdentity), 0);
        if DomainName <> '' then
        begin
          AuthIdentity.Domain := PChar(DomainName);
          AuthIdentity.DomainLength := Length(DomainName)
        end;
        if UserName <> '' then
        begin
          AuthIdentity.User := PChar(UserName);
          AuthIdentity.UserLength := Length(UserName);
        end;
        if Password <> '' then
        begin
          AuthIdentity.Password := PChar(Password);
          AuthIdentity.PasswordLength := Length(Password)
        end;
        AuthIdentity.Flags := SEC_WINNT_AUTH_IDENTITY_ANSI;
        //
        // Prepare client message (negotiate).
        //
        cbOut := cbMaxMessage;
        if not GenClientContext(funcs,
          0,
          @AuthIdentity,
          pServerBuf,
          0,
          pClientBuf,
          cbOut,
          done) then
          raise Exception.Create('GenClientContext Failed');
        cbIn := cbOut;
        cbOut := cbMaxMessage;
        if not GenServerContext(funcs,
          1,
          pClientBuf,
          cbIn,
          pServerBuf,
          cbOut,
          done) then
          raise Exception.Create('GenServerContext Failed');
        cbIn := cbOut;
        //
        // Prepare client message (authenticate).
        //
        cbOut := cbMaxMessage;
        if not GenClientContext(funcs,
          0,
          @AuthIdentity,
          pServerBuf,
          cbIn,
          pClientBuf,
          cbOut,
          done) then
          raise Exception.Create('GenClientContext failed');
        cbIn := cbOut;
        //
        // Prepare server message (authentication).
        //
        cbOut := cbMaxMessage;
        if not GenServerContext(funcs,
          1,
          pClientBuf,
          cbIn,
          pServerBuf,
          cbOut,
          done) then
          raise Exception.Create('GenServerContext failed');
        result := True
      end
    finally
      if Session0OK then
        TermSession(funcs, 0);
      if Session1OK then
        TermSession(funcs, 1);
      if packageHandle <> 0 then
        FreeLibrary(PackageHandle);
      ReallocMem(pClientBuf, 0);
      ReallocMem(pServerBuf, 0);
    end
  except
  end
end;

end.

