library VCL_SampleDLL;

uses
  Windows,
  FormUnit1 in 'FormUnit1.pas' {FormDLL};

var
  DLLProcNext: procedure(Reason: Integer); stdcall = nil;

exports
  FormShowModal,
  FormShowNormal;

procedure DLLMain(Reason: Integer); stdcall;
begin
// Hier tun wir unsern Job ...
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        DisableThreadLibraryCalls(hInstance);
      end;
    DLL_THREAD_ATTACH:
      begin
      end;
    DLL_THREAD_DETACH:
      begin
      end;
    DLL_PROCESS_DETACH:
      begin
      end;
  end;
// Wenn DLLProcNext <> nil dann rufen wir DLLProcNext auf.
  if Assigned(DLLProcNext) then try
    DLLProcNext(Reason);
  except
  end;
end;

begin
// We get the old value of DLLProc() into the variable DLLProcNext() and
// set the DLLProc() to the value of the address of DLLMain().
  DLLProcNext := Pointer(InterlockedExchange(Integer(DLLProc), Integer(@DLLMain)));
// DLLMain() is called with DLL_PROCESS_ATTACH, otherwise our DLLMain()
// would no longer come.
  DLLMain(DLL_PROCESS_ATTACH);
end.

