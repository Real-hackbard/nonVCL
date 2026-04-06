unit AppFormUnit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

const
  dllname = 'VCL_SampleDLL.dll';

{
procedure FormShowModal(parent: Pointer); stdcall; external dllname;
function FormShowNormal(parent: Pointer): Pointer; stdcall; external dllname;
}
type
  TFNFormShowModal = procedure(parent: Pointer); stdcall;
  TFNFormShowNormal = function(parent: Pointer): Pointer; stdcall;
var
  FormShowModal: TFNFormShowModal = nil;
  FormShowNormal: TFNFormShowNormal = nil;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if Assigned(FormShowModal) then
    FormShowModal(nil)
  else
    MessageDlg('Problem calling FormShowModal()',mtError,[mbOk],0);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if Assigned(FormShowNormal) then
    FormShowNormal(nil)
  else
    MessageDlg('Problem calling FormShowNormal()',mtError,[mbOk],0);
end;

var lib: HMODULE;
initialization
  lib := LoadLibrary(@dllname[1]);
  if lib <> 0 then
  begin
    @FormShowModal := GetProcAddress(lib, 'FormShowModal');
    @FormShowNormal := GetProcAddress(lib, 'FormShowNormal');
  end;
finalization
  if lib <> 0 then
    FreeLibrary(lib);
end.

