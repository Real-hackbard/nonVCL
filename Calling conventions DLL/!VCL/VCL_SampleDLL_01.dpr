library VCL_SampleDLL_01;
uses
  ShareMem,
  SysUtils,
  Windows,
  Classes;

procedure DLLMain(Reason: Integer);
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
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
end;

begin
  DLLProc := @DLLMain;
  DLLMain(DLL_PROCESS_ATTACH);
end.

