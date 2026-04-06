

//++IMPORT
function OneFunction(param1, param2, param3: Cardinal): integer;
  external 'SampleDLL.DLL';
function OneFunction_CDECL(param1, param2, param3: Cardinal): integer; cdecl;
  external 'SampleDLL.DLL' index 2;
function OneFunction_STDCALL_(param1, param2, param3: Cardinal): integer; stdcall;
  external 'SampleDLL.DLL' name 'OneFunction_STDCALL';

function OneFunction_as_CDECL(param1, param2, param3: Cardinal): integer; cdecl; external 'SampleDLL.DLL' name 'OneFunction';
function OneFunction_CDECL_as_PASCAL(param1, param2, param3: Cardinal): integer; external 'SampleDLL.DLL' name 'OneFunction_CDECL';
function OneFunction_STDCALL_as_PASCAL(param1, param2, param3: Cardinal): integer; external 'SampleDLL.DLL' name 'OneFunction_STDCALL';

function OneFunction_as_STDCALL(param1, param2, param3: Cardinal): integer; stdcall; external 'SampleDLL.DLL' name 'OneFunction';

function OneFunction_CDECL_as_STDCALL(param1, param2, param3: Cardinal): integer; stdcall; external 'SampleDLL.DLL' name 'OneFunction_CDECL';

function OneFunction_STDCALL_as_CDECL(param1, param2, param3: Cardinal): integer; cdecl; external 'SampleDLL.DLL' name 'OneFunction_STDCALL';

procedure initDLL(window: Cardinal); external 'SampleDLL.DLL';
//--IMPORT
