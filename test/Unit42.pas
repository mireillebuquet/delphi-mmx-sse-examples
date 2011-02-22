unit Unit42;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm42 = class(TForm)
    img1: TImage;
    btn1: TButton;
    img2: TImage;
    btn2: TButton;
    img3: TImage;
    btn3: TButton;
    btn4: TButton;
    Button1: TButton;
    btn5: TButton;
    rg1: TRadioGroup;
    btn6: TButton;
    btn7: TButton;
    btn8: TButton;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure btn5Click(Sender: TObject);
    procedure btn6Click(Sender: TObject);
    procedure btn7Click(Sender: TObject);
    procedure btn8Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form42: TForm42;

implementation

uses
  UBlinearResize, UAssemblerTest;


{$R *.dfm}


var
  StartTick,
  EndTick,
  Frequency : Int64;

function IsMMXAvailable: Boolean;
var
  Supported : Integer;
begin
  asm
    mov eax, 1 //using function 0x1 of cpuid
    cpuid
    and edx, 800000H //check the 23rd bit
    mov Supported, edx
  end;
  Result := (Supported <> 0); //If the bit is set we can use MMX
end;

function IsSSEAvailable: Boolean;
var
  Supported : Integer;
begin
  asm
    mov eax, 1 //using function 0x1 of cpuid
    cpuid
    and edx, 2000000H //check the 25th bit
    mov Supported, edx
  end;
  Result := (Supported <> 0); //If the bit is set we can use SSE
end;

//GetMem wrapper that aligns the pointer on a 16 bit boundry
procedure GetMemA(var P: Pointer; const Size: DWORD); inline;
var
  OriginalAddress : Pointer;
begin
  P := nil;
  GetMem(OriginalAddress,Size + 32); //Allocate users size plus extra for storage
  If OriginalAddress = nil Then Exit; //If not enough memory then exit
  P := PByte(OriginalAddress) + 4; //We want at least enough room for storage
  DWORD(P) := (DWORD(P) + (15)) And (Not(15)); //align the pointer
  If DWORD(P) < DWORD(OriginalAddress) Then Inc(PByte(P),16); //If we went into storage goto next boundry
  Dec(PDWORD(P)); //Move back 4 bytes so we can save original pointer
  PDWORD(P)^ := DWORD(OriginalAddress); //Save original pointer
  Inc(PDWORD(P)); //Back to the boundry
end;

//Freemem wrapper to free aligned memory
procedure FreeMemA(P: Pointer); inline;
begin
  Dec(PDWORD(P)); //Move back to where we saved the original pointer
  DWORD(P) := PDWORD(P)^; //Set P back to the original
  FreeMem(P); //Free the memory
end;

procedure TForm42.btn1Click(Sender: TObject);
var
  x,y: integer;
  b1,b2: TBitmap;
  v_img_in: PByteArray;
  v_img_out: PByteArray;

  sc: TBiLinearByte;
  scParametry:TBiLinearParametry;
  p: PIntegerArray;

  function rgb(p_byte: Byte): Integer; inline;
  begin
    result := p_byte + p_byte shl 8 + p_byte shl 16;
  end;
begin
//  caption := IntToStr(Trunc(1.0001));
//  Exit;

  //
  GetMem(v_img_in,4*4);
  GetMem(v_img_out,13*13);

  v_img_in^[0] := 0;    v_img_in^[1] := 255;   v_img_in^[2] := 255;   v_img_in^[3] := 127;
  v_img_in^[4] := 255;  v_img_in^[5] := 127;   v_img_in^[6] := 255;   v_img_in^[7] := 127;
  v_img_in^[8] := 0;    v_img_in^[9] := 255;   v_img_in^[10] := 255;   v_img_in^[11] := 127;
  v_img_in^[12] := 0;   v_img_in^[13] := 255;  v_img_in^[14] := 255;  v_img_in^[15] := 127;
  //
  v_img_in^[0] := 255;    v_img_in^[1] := 255;   v_img_in^[2] := 0;   v_img_in^[3] := 0;
  v_img_in^[4] := 255;  v_img_in^[5] := 255;   v_img_in^[6] := 0;   v_img_in^[7] := 0;
  v_img_in^[8] := 0;    v_img_in^[9] := 0;   v_img_in^[10] := 255;   v_img_in^[11] := 255;
  v_img_in^[12] := 0;   v_img_in^[13] := 0;  v_img_in^[14] := 255;  v_img_in^[15] := 255;


  //OutputDebugString();

  b1:= TBitmap.Create;
  b1.PixelFormat := pf32bit;
  b1.Width := 4;
  b1.Height := 4;


  for y := 0 to 4 - 1 do
  begin
    p := b1.ScanLine[y];
    for x := 0 to 4 - 1 do
    begin
      p^[x] := rgb(v_img_in^[ 4 * y + x  ]);
    end;
  end;




 { b1.Canvas.Pixels[0,0] := rgb( v_img_in^[0]);
  b1.Canvas.Pixels[0,1] := rgb( v_img_in^[1]);
  b1.Canvas.Pixels[1,0] := rgb( v_img_in^[2]);
  b1.Canvas.Pixels[1,1] := rgb( v_img_in^[3]);

}

  img1.Picture.Assign(b1);
  b1.Free;


  scParametry.in_width := 4;
  scParametry.in_height := 4;
  scParametry.in_image := v_img_in;
  scParametry.out_width := 13;
  scParametry.out_height := 13;
  scParametry.out_image := v_img_out;


  sc:= TBiLinearByte.Create(scParametry);

  sc.ZrobBlinear3;


  b2:= TBitmap.Create;
  b2.PixelFormat := pf32bit;
  b2.Width := 13;
  b2.Height := 13;



  for y := 0 to 13 - 1 do
  begin
    p := b2.ScanLine[y];
    for x := 0 to 13 - 1 do
    begin
      p^[x] := rgb(v_img_out^[ 13 * y + x  ]);
    end;
  end;


  img2.Stretch := True;
  img2.Picture.Assign(b2);
  b2.Free;

  sc.Free;

  freeMem(v_img_in);
  freeMem(v_img_out);

end;

procedure TForm42.btn2Click(Sender: TObject);
var
  //i: integer;
  x,y: integer;
  b1,b2,b3: TBitmap;
  v_img_in: PByteArrayBiLinear;
  v_img_out: PByteArrayBiLinear;
  v_img_out2: PByteArrayBiLinear;

  sc: TBiLinearByte;
  scParametry:TBiLinearParametry;
  p: PIntegerArray;

  nw,nh: Integer;
  nw2,nh2: Integer;

  t: LongWord;

  function rgb(p_byte: Byte): Integer; inline;
  begin
    result := p_byte + p_byte shl 8 + p_byte shl 16;
  end;

  var w,h: integer;

begin
  w := 4;
  h := 8;
  nw := 4;
  nh := 8;
  nw2 := 63;
  nh2 := 67;
//  caption := IntToStr(Trunc(1.0001));
//  Exit;

  //
  GetMem(v_img_in, w*h );
  GetMem(v_img_out, nw*nh );
  GetMem(v_img_out2, nw2*nh2 );

  v_img_in^[0] := 255;    v_img_in^[1] := 255;   v_img_in^[2] := 0;   v_img_in^[3] := 0;
  v_img_in^[4] := 255;  v_img_in^[5] := 255;   v_img_in^[6] := 0;   v_img_in^[7] := 0;
  v_img_in^[8] := 0;    v_img_in^[9] := 0;   v_img_in^[10] := 255;   v_img_in^[11] := 255;
  v_img_in^[12] := 0;   v_img_in^[13] := 0;  v_img_in^[14] := 255;  v_img_in^[15] := 255;
  //
  v_img_in^[16] := 255;    v_img_in^[17] := 255;   v_img_in^[18] := 0;   v_img_in^[19] := 0;
  v_img_in^[20] := 255;  v_img_in^[21] := 255;   v_img_in^[22] := 0;   v_img_in^[23] := 0;
  v_img_in^[24] := 0;    v_img_in^[25] := 0;   v_img_in^[26] := 255;   v_img_in^[27] := 255;
  v_img_in^[28] := 0;   v_img_in^[29] := 0;  v_img_in^[30] := 255;  v_img_in^[31] := 255;


  //OutputDebugString();

  b1:= TBitmap.Create;
  b1.PixelFormat := pf32bit;
  b1.Width := w;
  b1.Height := h;


  for y := 0 to h - 1 do
  begin
    p := b1.ScanLine[y];
    for x := 0 to w - 1 do
    begin
      p^[x] := rgb(v_img_in^[ w * y + x  ]);
    end;
  end;




 { b1.Canvas.Pixels[0,0] := rgb( v_img_in^[0]);
  b1.Canvas.Pixels[0,1] := rgb( v_img_in^[1]);
  b1.Canvas.Pixels[1,0] := rgb( v_img_in^[2]);
  b1.Canvas.Pixels[1,1] := rgb( v_img_in^[3]);

}

  img1.Picture.Assign(b1);
  b1.Free;


  scParametry.in_width := w;
  scParametry.in_height := h;
  scParametry.in_image := v_img_in;
  scParametry.out_width := nw;
  scParametry.out_height := nh;
  scParametry.out_image := v_img_out;
  scParametry.opcje := [];

  //scParametry.dane_odwroc_90stopni_prawo := true;

  sc:= TBiLinearByte.Create(scParametry);


  t := GetTickCount;
  //for I := 0 to 100 - 1 do
    sc.ZrobBlinear1;

  Caption := IntToStr(GetTickCount - t);

  b2:= TBitmap.Create;
  b2.PixelFormat := pf32bit;
  b2.Width := nw;
  b2.Height := nh;



  for y := 0 to nh - 1 do
  begin
    p := b2.ScanLine[y];
    for x := 0 to nw - 1 do
    begin
      p^[x] := rgb(v_img_out^[ nw * y + x  ]);
    end;
  end;


  img2.Picture.Assign(b2);
  img2.Stretch := true;
  b2.Free;
    sc.Free;

  Exit;   ///////////////////////////////////////////////////


  scParametry.in_width := nw;
  scParametry.in_height := nh;
  scParametry.in_image := v_img_out;
  scParametry.out_width := nw2;
  scParametry.out_height := nh2;
  scParametry.out_image := v_img_out2;

  //scParametry.dane_odwroc_90stopni_prawo := false;
  scParametry.opcje := [obrocGoraDol];

  sc:= TBiLinearByte.Create(scParametry);
  sc.ZrobBlinear1;



  b3:= TBitmap.Create;
  b3.PixelFormat := pf32bit;
  b3.Width := nw2;
  b3.Height := nh2;

  for y := 0 to nh2 - 1 do
  begin
    p := b3.ScanLine[y];
    for x := 0 to nw2 - 1 do
    begin
      p^[x] := rgb(v_img_out2^[ nw2 * y + x  ]);
    end;
  end;

  img3.Picture.Assign(b3);

  freeMem(v_img_in);
  freeMem(v_img_out);
end;


procedure TForm42.btn3Click(Sender: TObject);
var
  i: integer;
  x,y: integer;
  b1,b2,b3: TBitmap;
  v_img_in: PByteArrayBiLinear;
  v_img_out: PByteArrayBiLinear;
  v_img_out2: PByteArrayBiLinear;

  sc: TBiLinearByte;
  scParametry:TBiLinearParametry;
  p: PIntegerArray;

  nw,nh: Integer;
  nw2,nh2: Integer;

  t: LongWord;

  function rgb(p_byte: Byte): Integer; inline;
  begin
    result := p_byte + p_byte shl 8 + p_byte shl 16;
  end;

  var w,h: integer;

begin
  w := 4;
  h := 8;
  nw := 512;// 8;
  nh := 512;//4;
  nw2 := 63;
  nh2 := 67;
//  caption := IntToStr(Trunc(1.0001));
//  Exit;

  //
  GetMem(v_img_in, w*h );
  GetMem(v_img_out, nw*nh );
  GetMem(v_img_out2, nw2*nh2 );

  b1:= TBitmap.Create;
  b1.PixelFormat := pf32bit;
  b1.Width := w;
  b1.Height := h;
  //
  b2:= TBitmap.Create;
  b2.PixelFormat := pf32bit;
  b2.Width := nw;
  b2.Height := nh;
  //
  b3:= TBitmap.Create;
  b3.PixelFormat := pf32bit;
  b3.Width := nw2;
  b3.Height := nh2;


  v_img_in^[0] := 127;    v_img_in^[1] := 100;   v_img_in^[2] := 0;   v_img_in^[3] := 0;
  v_img_in^[4] := 255;  v_img_in^[5] := 255;   v_img_in^[6] := 0;   v_img_in^[7] := 0;
  v_img_in^[8] := 0;    v_img_in^[9] := 0;   v_img_in^[10] := 255;   v_img_in^[11] := 255;
  v_img_in^[12] := 0;   v_img_in^[13] := 0;  v_img_in^[14] := 255;  v_img_in^[15] := 255;
  //
  v_img_in^[16] := 255;    v_img_in^[17] := 255;   v_img_in^[18] := 0;   v_img_in^[19] := 0;
  v_img_in^[20] := 255;  v_img_in^[21] := 255;   v_img_in^[22] := 0;   v_img_in^[23] := 0;
  v_img_in^[24] := 0;    v_img_in^[25] := 0;   v_img_in^[26] := 255;   v_img_in^[27] := 255;
  v_img_in^[28] := 0;   v_img_in^[29] := 0;  v_img_in^[30] := 255;  v_img_in^[31] := 255;
///////////////

{  v_img_in^[0] := 127;    v_img_in^[1] := 255;   v_img_in^[2] := 0;   v_img_in^[3] := 0; v_img_in^[4] := 255;  v_img_in^[5] := 255;   v_img_in^[6] := 0;   v_img_in^[7] := 0;
  v_img_in^[8] := 100;    v_img_in^[9] := 255;   v_img_in^[10] := 0;   v_img_in^[11] := 0; v_img_in^[12] := 255;   v_img_in^[13] := 255;  v_img_in^[14] := 0;  v_img_in^[15] := 0;
  v_img_in^[16] := 0;    v_img_in^[17] := 0;   v_img_in^[18] := 255;   v_img_in^[19] := 255; v_img_in^[20] := 0;  v_img_in^[21] := 0;   v_img_in^[22] := 255;   v_img_in^[23] := 255;
  v_img_in^[24] := 0;    v_img_in^[25] := 0;   v_img_in^[26] := 255;   v_img_in^[27] := 255; v_img_in^[28] := 0;   v_img_in^[29] := 0;  v_img_in^[30] := 255;  v_img_in^[31] := 255;

}

  //OutputDebugString();



  for y := 0 to h - 1 do
  begin
    p := b1.ScanLine[y];
    for x := 0 to w - 1 do
    begin
      p^[x] := rgb(v_img_in^[ w * y + x  ]);
    end;
  end;




 { b1.Canvas.Pixels[0,0] := rgb( v_img_in^[0]);
  b1.Canvas.Pixels[0,1] := rgb( v_img_in^[1]);
  b1.Canvas.Pixels[1,0] := rgb( v_img_in^[2]);
  b1.Canvas.Pixels[1,1] := rgb( v_img_in^[3]);

}

  img1.Picture.Assign(b1);



  scParametry.in_width := w;
  scParametry.in_height := h;
  scParametry.in_image := v_img_in;
  scParametry.out_width := nw;
  scParametry.out_height := nh;
  scParametry.out_image := v_img_out;
  scParametry.opcje := [zamienioneWierszeKolumny];

  //scParametry.dane_odwroc_90stopni_prawo := true;

  sc:= TBiLinearByte.Create(scParametry);


  t := GetTickCount;
  for I := 0 to 100 - 1 do
    sc.ZrobBlinear3;


  Caption := IntToStr(GetTickCount - t);



  for y := 0 to nh - 1 do
  begin
    p := b2.ScanLine[y];
    for x := 0 to nw - 1 do
    begin
      p^[x] := rgb(v_img_out^[ nw * y + x  ]);
    end;
  end;


  img2.Picture.Assign(b2);
  img2.Stretch := true;


  scParametry.in_width := nw;
  scParametry.in_height := nh;
  scParametry.in_image := v_img_out;
  scParametry.out_width := nw2;
  scParametry.out_height := nh2;
  scParametry.out_image := v_img_out2;

  //scParametry.dane_odwroc_90stopni_prawo := false;
  scParametry.opcje := [obrocGoraDol, obrocLewoPrawo];


  sc.free;
  sc:= TBiLinearByte.Create(scParametry);
  sc.ZrobBlinear1;
  sc.Free;



  for y := 0 to nh2 - 1 do
  begin
    p := b3.ScanLine[y];
    for x := 0 to nw2 - 1 do
    begin
      p^[x] := rgb(v_img_out2^[ nw2 * y + x  ]);
    end;
  end;

  img3.Picture.Assign(b3);


  b1.free;
  b2.free;
  b3.free;

  //sc.free;
  freeMem(v_img_in);
  freeMem(v_img_out);
  freemem(v_img_out2);
end;


procedure Test1;
const

  SIZE = 1024 * 1024;
  ILE_CYKLI = 1000;
var
  tab1,tab2,tab3: PByteArray;
  czas: Dword;
  i,j: integer;
begin
  getmem( tab1 , SIZE );
  getmem( tab2 , SIZE );
  getmem( tab3 , SIZE );


  czas := GetTickCount;
  for i := 0 to ILE_CYKLI - 1 do
  begin
    for j := 0 to SIZE - 1 do
    begin
      tab3^[j] := tab1^[j] + tab2^[j]
    end;

  end;
  showmessage('Czas wykonania:'+inttostr(GetTickCount - czas)+'ms');

  freemem( tab1 );
  freemem( tab2 );
  freemem( tab3 );
end;

procedure TForm42.btn4Click(Sender: TObject);
begin
  test1;
end;

procedure TForm42.btn5Click(Sender: TObject);
var
  i: integer;
  x,y: integer;
  b1,b2: TBitmap;
  v_img_in: PByteArrayBiLinear;
  v_img_out: PByteArrayBiLinear;
  v_img_out2: PByteArrayBiLinear;

  sc: TBiLinearByte;
  scParametry:TBiLinearParametry;
  p: PIntegerArray;

  nw,nh: Integer;
  nw2,nh2: Integer;

  t: LongWord;

  function rgb(p_byte: Byte): Integer; inline;
  begin
    result := p_byte + p_byte shl 8 + p_byte shl 16;
  end;

  var w,h: integer;

begin
  w := 4;
  h := 8;
  nw := 512;// 8;
  nh := 512;//4;
  nw2 := 63;
  nh2 := 67;
//  caption := IntToStr(Trunc(1.0001));
//  Exit;

  //
  GetMem(v_img_in, w*h );
  GetMem(v_img_out, nw*nh );
  GetMem(v_img_out2, nw2*nh2 );

  b1:= TBitmap.Create;
  b1.PixelFormat := pf32bit;
  b1.Width := w;
  b1.Height := h;
  //
  b2:= TBitmap.Create;
  b2.PixelFormat := pf32bit;
  b2.Width := nw;
  b2.Height := nh;
  //

  v_img_in^[0] := 127;    v_img_in^[1] := 100;   v_img_in^[2] := 0;   v_img_in^[3] := 0;
  v_img_in^[4] := 255;  v_img_in^[5] := 255;   v_img_in^[6] := 0;   v_img_in^[7] := 0;
  v_img_in^[8] := 0;    v_img_in^[9] := 0;   v_img_in^[10] := 255;   v_img_in^[11] := 255;
  v_img_in^[12] := 0;   v_img_in^[13] := 0;  v_img_in^[14] := 255;  v_img_in^[15] := 255;
  //
  v_img_in^[16] := 255;    v_img_in^[17] := 255;   v_img_in^[18] := 0;   v_img_in^[19] := 0;
  v_img_in^[20] := 255;  v_img_in^[21] := 255;   v_img_in^[22] := 0;   v_img_in^[23] := 0;
  v_img_in^[24] := 0;    v_img_in^[25] := 0;   v_img_in^[26] := 255;   v_img_in^[27] := 255;
  v_img_in^[28] := 0;   v_img_in^[29] := 0;  v_img_in^[30] := 255;  v_img_in^[31] := 255;
///////////////



  for y := 0 to h - 1 do
  begin
    p := b1.ScanLine[y];
    for x := 0 to w - 1 do
    begin
      p^[x] := rgb(v_img_in^[ w * y + x  ]);
    end;
  end;


  img1.Picture.Assign(b1);

  scParametry.in_width := w;
  scParametry.in_height := h;
  scParametry.in_image := v_img_in;
  scParametry.out_width := nw;
  scParametry.out_height := nh;
  scParametry.out_image := v_img_out;
  scParametry.opcje := [];// [zamienioneWierszeKolumny];

  //scParametry.dane_odwroc_90stopni_prawo := true;

  sc:= TBiLinearByte.Create(scParametry);


  t := GetTickCount;
  for I := 0 to 100 - 1 do
  begin
    case rg1.ItemIndex of
      0: sc.ZrobBlinear1;
      1: sc.ZrobBlinear2;
      2: sc.ZrobBlinear3;
      3: sc.ZrobBlinear4;
      4: sc.ZrobBlinear5;
    end;
  end;

  sc.free;

  Caption := IntToStr(GetTickCount - t);



  for y := 0 to nh - 1 do
  begin
    p := b2.ScanLine[y];
    for x := 0 to nw - 1 do
    begin
      p^[x] := rgb(v_img_out^[ nw * y + x  ]);
    end;
  end;


  img2.Picture.Assign(b2);
  img2.Stretch := true;



  b1.free;
  b2.free;

  freeMem(v_img_in);
  freeMem(v_img_out);
  freemem(v_img_out2);
end;


procedure test4;
const

  SIZE = 1024 * 1024;
  ILE_CYKLI = 1000;
var
  tab1,tab2,tab3: Pointer;// PByteArray;
  tab1_: PByteArray absolute tab1;
  tab2_: PByteArray absolute tab2;
  tab3_: PByteArray absolute tab3;
  i,j: Integer;
  b1, b2, b3: PByte;
begin
  If Not(IsMMXAvailable) Or Not(IsSSEAvailable) Then //Check to see if supported
    begin
    showmessage('MMX or SSE is not supported by your OS/CPU. Press any key to exit. . .');
    Readln;
    Exit;
  end;

  GetMemA(tab1,SIZE);
  GetMemA(tab2,SIZE);
  GetMemA(tab3,SIZE);
  FillChar(tab1^,SIZE,1);
  FillChar(tab2^,SIZE,2);
  FillChar(tab3^,SIZE,0);


  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(StartTick);
  for I := 0 to ILE_CYKLI - 1 do
  asm
    push eax //Save ebx  // tab1
    push ebx //Save edx  // tab2
    push ecx //Save edx  // tab3
    push edx //Save edx  // licznik petli

    mov edx, SIZE // ustawiam licznik petli
    //
    mov eax, tab1 //Set eax to tab1
    mov ebx, tab2 //Set ebx to tab2
    mov ecx, tab3 //Set ecx to tab3

    @@InnerLoop:
      movq mm0, [eax] //Move 8 bytes from eax mm0 register
      movq mm1, [ebx] //Move 8 bytes from eax mm1 register
      PADDB mm1,mm0   // wykonuje dodawanie
      {ADDPS} paddsb  xmm1, xmm0
      movq [ecx], mm1 //Put the data to ecx

      // przesuwam wskaznik
      add eax, 8  // tab1
      add ebx, 8  // tab2
      add ecx, 8  // tab3

      sub edx, 8  // zmniejszam licznik petli
    JNZ @@InnerLoop

    pop edx //Restore ecx
    pop ecx //Restore ecx
    pop ebx //Restore ebx
    pop eax //Restore eax
  end;

  //Sleep(500);
  QueryPerformanceCounter(EndTick);
  asm EMMS end; //Resets all mmX registers.
  showmessage(Format('MMX - %.2f ms',[((EndTick - StartTick) / Frequency) * 1000]));
  tab3_^[0] := tab1_^[0] + tab2_^[0];  // tylko ¿eby podejrzeæ zmienne
end;



procedure test3;
const

  SIZE = 1024 * 1024;
  ILE_CYKLI = 1000;
var
  tab1,tab2,tab3: Pointer;// PByteArray;
  tab1_: PByteArray absolute tab1;
  tab2_: PByteArray absolute tab2;
  tab3_: PByteArray absolute tab3;
  i,j: Integer;
  b1, b2, b3: PByte;
begin
  If Not(IsMMXAvailable) Or Not(IsSSEAvailable) Then //Check to see if supported
    begin
    showmessage('MMX or SSE is not supported by your OS/CPU. Press any key to exit. . .');
    Readln;
    Exit;
  end;

  GetMemA(tab1,SIZE);
  GetMemA(tab2,SIZE);
  GetMemA(tab3,SIZE);
{  FillChar(tab1^,SIZE,1);
  FillChar(tab2^,SIZE,2);
  FillChar(tab3^,SIZE,0);
}

  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(StartTick);
  for I := 0 to ILE_CYKLI - 1 do
  asm
    push eax //Save ebx  // tab1
    push ebx //Save edx  // tab2
    push ecx //Save edx  // tab3
    push edx //Save edx  // licznik petli

    mov edx, SIZE // ustawiam licznik petli
    //
    mov eax, tab1 //Set eax to tab1
    mov ebx, tab2 //Set ebx to tab2
    mov ecx, tab3 //Set ecx to tab3

    @@InnerLoop:
      //[wersja 2]
      movaps xmm1, [eax] //Move 16 bytes from eax xmm0 register
      paddb xmm1, [ebx] // wykonuje dodawanie
      movaps [ecx], xmm1 //Put the data to ecx

      // [wersja 1]
      {movaps xmm0, [eax] //Move 16 bytes from eax xmm0 register
      movaps xmm1, [ebx] //Move 16 bytes from ebx xmm1 register
      paddb xmm1, xmm0 // wykonuje dodawanie
      movaps [ecx], xmm1 //Put the data to ecx
      }

      //ADDPS xmm1, [ebx] // wykonuje dodawanie
      //movaps [ecx], xmm1 //Put the data to ecx

      // przesuwam wskaznik
      add eax, 16  // tab1
      add ebx, 16  // tab2
      add ecx, 16  // tab3

      sub edx, 16  // zmniejszam licznik petli
    JNZ @@InnerLoop

    pop edx //Restore ecx
    pop ecx //Restore ecx
    pop ebx //Restore ebx
    pop eax //Restore eax
  end;

  //Sleep(500);
  QueryPerformanceCounter(EndTick);
  showmessage(Format('SSE2 - %.2f ms',[((EndTick - StartTick) / Frequency) * 1000]));
  tab3_^[0] := tab1_^[0] + tab2_^[0];  // tylko ¿eby podejrzeæ zmienne
end;

procedure TForm42.btn6Click(Sender: TObject);
begin
  test3;
end;


procedure TForm42.btn7Click(Sender: TObject);
begin
  test4;
end;

function IsSSEAvailable2: Boolean;
asm
  mov eax, 1 //using function 0x1 of cpuid
  cpuid
  and edx, 2000000H //check the 25th bit
  cmp edx, 0
  setnz al
end;


procedure TForm42.btn8Click(Sender: TObject);
//var  ob: TTestAsm;
begin
  AssemblerTest.show;
  IsSSEAvailable;
{
004B7BE8 55               push ebp
004B7BE9 8BEC             mov ebp,esp
004B7BEB 51               push ecx
004B7BEC B801000000       mov eax,$00000001  //Unit42.pas.74: mov eax, 1 //using function 0x1 of cpuid
004B7BF1 0FA2             cpuid  //Unit42.pas.75: cpuid
004B7BF3 81E200000002     and edx,$02000000  //Unit42.pas.76: and edx, 2000000H //check the 25th bit
004B7BF9 8955FC           mov [ebp-$04],edx  // Unit42.pas.77: mov Supported, edx
004B7BFC 837DFC00         cmp dword ptr [ebp-$04],$00  // Unit42.pas.79: Result := (Supported <> 0); //If the bit is set we can use SSE
004B7C00 0F95C0           setnz al
004B7C03 59               pop ecx // Unit42.pas.80: end;
004B7C04 5D               pop ebp
004B7C05 C3               ret }


  IsSSEAvailable2;
{
004B9220 B801000000       mov eax,$00000001  // Unit42.pas.884: mov eax, 1 //using function 0x1 of cpuid
004B9225 0FA2             cpuid  Unit42.pas.885: cpuid
004B9227 81E200000002     and edx,$02000000  // Unit42.pas.886: and edx, 2000000H //check the 25th bit
004B922D 83FA00           cmp edx,$00  // Unit42.pas.887: cmp edx, 0
004B9230 0F95C0           setnz al  // Unit42.pas.888: setnz al
004B9233 C3               ret // Unit42.pas.889: end;
}

//  ob:= TTestAsm.create;
//  ob.testuje;


asm_add(10,11);
asm_add(10,11,12);
asm_add(10,11,12,13,14);

end;

procedure Test2;
const

  SIZE = 1024 * 1024;
  ILE_CYKLI = 1000;
var
  tab1,tab2,tab3: PByteArray;
  b1, b2, b3: PByte;
  czas: Dword;
  i,j: integer;
begin
  getmem( tab1 , SIZE );
  getmem( tab2 , SIZE );
  getmem( tab3 , SIZE );

  czas := GetTickCount;
  for i := 0 to ILE_CYKLI - 1 do
  begin
    B1 := @tab1^;
    B2 := @tab2^;
    B3 := @tab3^;
    for j := 0 to SIZE - 1 do
    begin
      B1^ := B2^ + B3^;
      Inc(B1);
      Inc(B2);
      Inc(B3);
    end;
  end;
  showmessage('Czas wykonania:'+inttostr(GetTickCount - czas)+'ms');

  freemem( tab1 );
  freemem( tab2 );
  freemem( tab3 );
end;

procedure TForm42.Button1Click(Sender: TObject);
begin
  test2;
end;

procedure AddByteArrays(Size: Integer; Const Tab1, Tab2; Out Tab3);
asm

end;

procedure TForm42.FormCreate(Sender: TObject);
var
  p: PbyteArray;
begin
//
end;

procedure BGR24ToRGBA32(src, dest : Pointer; pixelCount : Integer); register;
// EAX stores src
// EDX stores dest
// ECX stores pixelCount
asm
         push  edi
         cmp   ecx, 0
         jle   @@Done
         mov   edi, eax
         dec   ecx
         jz    @@Last
@@Loop:
         mov   eax, [edi]
         shl   eax, 8
         or    eax, $FF
         bswap eax
         mov   [edx], eax
         add   edi, 3
         add   edx, 4
         dec   ecx
         jnz   @@Loop
@@Last:
         mov   cx, [edi+1]
         shl   ecx, 16
         mov   ah, [edi]
         mov   al, $FF
         and   eax, $FFFF
         or    eax, ecx
         bswap eax
         mov   [edx], eax
@@Done:
         pop   edi
end;

type
  TVector = Pointer;

procedure VectorCombine3(const V1, V2, V3: TVector; const F1, F2, F3: Single; var vr : TVector);
// EAX contains address of v1
// EDX contains address of v2
// ECX contains address of v3
// EBX contains address of vr
// ebp+$14 points to f1
// ebp+$10 points to f2
// ebp+$0c points to f3
begin
{$ifndef GEOMETRY_NO_ASM}
   asm
      //test vSIMD, 1
      jz @@FPU
@@3DNow:    // 197
      db $0F,$6E,$4D,$14       /// MOVD  MM1, [EBP+$14]
      db $0F,$62,$C9           /// PUNPCKLDQ MM1, MM1
      db $0F,$6E,$55,$10       /// MOVD  MM2, [EBP+$10]
      db $0F,$62,$D2           /// PUNPCKLDQ MM2, MM2
      db $0F,$6E,$5D,$0C       /// MOVD  MM3, [EBP+$0C]
      db $0F,$62,$DB           /// PUNPCKLDQ MM3, MM3

      db $0F,$6F,$20           /// MOVQ  MM4, [EAX]
      db $0F,$0F,$E1,$B4       /// PFMUL MM4, MM1
      db $0F,$6F,$2A           /// MOVQ  MM5, [EDX]
      db $0F,$0F,$EA,$B4       /// PFMUL MM5, MM2
      db $0F,$0F,$E5,$9E       /// PFADD MM4, MM5
      db $0F,$6F,$31           /// MOVQ  MM6, [ECX]
      db $0F,$0F,$F3,$B4       /// PFMUL MM6, MM3
      db $0F,$0F,$E6,$9E       /// PFADD MM4, MM6
      db $0F,$7F,$23           /// MOVQ  [EBX], MM4

      db $0F,$6F,$78,$08       /// MOVQ  MM7, [EAX+8]
      db $0F,$0F,$F9,$B4       /// PFMUL MM7, MM1
      db $0F,$6F,$42,$08       /// MOVQ  MM0, [EDX+8]
      db $0F,$0F,$C2,$B4       /// PFMUL MM0, MM2
      db $0F,$0F,$F8,$9E       /// PFADD MM7, MM0
      db $0F,$6F,$69,$08       /// MOVQ  MM5, [ECX+8]
      db $0F,$0F,$EB,$B4       /// PFMUL MM5, MM3
      db $0F,$0F,$FD,$9E       /// PFADD MM7, MM5
      db $0F,$7F,$7B,$08       /// MOVQ  [EBX+8], MM7

      db $0F,$0E               /// FEMMS
      pop ebx
      pop ebp
      ret $10
@@FPU:      // 263
   end;
{$endif}
end;


end.
