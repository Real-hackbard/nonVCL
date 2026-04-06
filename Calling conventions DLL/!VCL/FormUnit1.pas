unit FormUnit1;

interface

uses
  Windows, Forms, Classes, StdCtrls, Controls;

type
  TFormDLL = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormDLL: TFormDLL;

procedure FormShowModal(parent: Pointer); stdcall;
function FormShowNormal(parent: Pointer): Pointer; stdcall;

implementation

{$R *.DFM}

procedure TFormDLL.Button1Click(Sender: TObject);
begin
// Form schlieﬂen
  self.Close;
end;

procedure TFormDLL.FormClose(Sender: TObject; var Action: TCloseAction);
begin
// Form beim Schlieﬂen freigeben
  Action := caFree;
end;

procedure TFormDLL.FormCreate(Sender: TObject);
var
  pc: PChar;
begin
// Modul anzeigen
  GetMem(pc, MAX_PATH);
  if Assigned(pc) then
  try
    ZeroMemory(pc, MAX_PATH);
    GetModuleFileName(hInstance, pc, MAX_PATH);
    Label2.Caption := string(pc);
  finally
    FreeMem(pc);
  end
  else
    Label2.Caption := 'Konnte Modulnamen nicht ermitteln.';
end;

procedure FormShowModal(parent: Pointer); stdcall;
begin
  FormDLL := TFormDLL.Create(nil);
  if Assigned(parent) then
    FormDLL.SetParent(parent);
  FormDLL.Caption := FormDLL.Caption + ' Modal';
  FormDLL.ShowModal;
end;

function FormShowNormal(parent: Pointer): Pointer; stdcall;
begin
  FormDLL := TFormDLL.Create(nil);
  if Assigned(parent) then
    FormDLL.SetParent(parent);
  FormDLL.Caption := FormDLL.Caption + ' Normal';
  FormDLL.Show;
  result := FormDLL;
end;

end.

