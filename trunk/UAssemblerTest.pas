unit UAssemblerTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TAssemblerTest = class(TForm)
    btn1: TButton;
    btn2: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AssemblerTest: TAssemblerTest;

implementation

uses UAssembler;

{$R *.dfm}

procedure TAssemblerTest.btn1Click(Sender: TObject);
begin
  ShowMessage(Test_AddByteArrays(1024*1024*128, AddByteArrays));
  ShowMessage(Test_AddByteArrays(1024*1024*128, AddByteArrays_pointer));
  ShowMessage(Test_AddByteArrays(1024*1024*128, AddByteArrays_mmx, true));
end;

procedure TAssemblerTest.btn2Click(Sender: TObject);
var
  t1,t2,t3: Pointer;
begin
  AddByteArrays_mmx(t1,t2,t3,1024);
end;

end.
