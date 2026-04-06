program VCL_call1;

{$APPTYPE CONSOLE}

uses
Forms,
Windows;

const
  dllname = 'VCL_SampleDLL.dll';

procedure FormShowModal(parent: Pointer); stdcall; external dllname;
function FormShowNormal(parent: Pointer): Pointer; stdcall; external dllname;

begin
  Writeln('Show modal form');
  FormShowModal(nil); ;
  Writeln('Show normal form. The window will not respond because no');
  Writeln('Message loop exists.');
  Writeln('Press ENTER to exit the application.');
  FormShowNormal(nil);
  Application.ProcessMessages ;
  Readln;
end.

