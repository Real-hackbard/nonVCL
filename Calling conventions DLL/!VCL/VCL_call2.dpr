program VCL_call2;

uses
  Forms,
  AppFormUnit1 in 'AppFormUnit1.pas' {Form1};

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
