program Project10;

uses
  Forms,
  Unit42 in 'Unit42.pas' {Form42},
  UAssemblerTest in 'UAssemblerTest.pas' {AssemblerTest};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm42, Form42);
  Application.CreateForm(TAssemblerTest, AssemblerTest);
  Application.Run;
end.
