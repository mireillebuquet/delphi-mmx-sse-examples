unit UBlinearResize;

interface

uses
  SysUtils, Dialogs, Windows;

type
  TBiLinearDouble = double;
  TBiLinearSingle = single;

  TByteArrayBiLinear = array[0..$effffff] of Byte;
  PByteArrayBiLinear = ^TByteArrayBiLinear;

  TBiLinearDoubleArray = array[0..$effffff] of TBiLinearDouble;
  PBiLinearDoubleArray = ^TBiLinearDoubleArray;

  TBiLinearSingleArray = array[0..$effffff] of TBiLinearSingle;
  PBiLinearSingleArray = ^TBiLinearSingleArray;


  TBiLinearOperacje = (obrocLewoPrawo, obrocGoraDol, zamienioneWierszeKolumny);
  TBiLinearOpcje = set of  TBiLinearOperacje;

  TBiLinearParametry = record
    in_width: integer;
    in_height: integer;
    out_width: integer;
    out_height: integer;
    in_image: pointer;
    out_image: pointer;
    opcje: TBiLinearOpcje;
  end;


  // wersja konwertujaca tablice BYTE
  TBiLinearByte = class
  private
    a_buf_in: PByteArrayBiLinear;
    a_buf_out: PByteArrayBiLinear;


    a_buf_S1: PBiLinearDoubleArray;
    a_buf_S2: PBiLinearDoubleArray;
    a_buf_S3: PBiLinearDoubleArray;
    a_buf_S4: PBiLinearDoubleArray;

    a_buf_S1_: PByteArrayBiLinear;
    a_buf_S2_: PByteArrayBiLinear;
    a_buf_S3_: PByteArrayBiLinear;
    a_buf_S4_: PByteArrayBiLinear;


    a_buf_P1: PIntegerArray;
    a_buf_P2: PIntegerArray;
    a_buf_P3: PIntegerArray;
    a_buf_P4: PIntegerArray;


    a_parametry: TBiLinearParametry;

    // wykorzystywane do obliczeñ
    a_max_adres_out: integer; // jaki bedzie maksymalny adres -1 bo tablice sa indeksowane od ZERO
    a_wsp_deltaTeta_deltaR: TBiLinearDouble;
    a_wsp_deltaTeta_deltaR_odwrotnosc: TBiLinearDouble;
    //a_enable: boolean;
  public
    constructor Create(p_parametry: TBiLinearParametry);
    procedure UstawWymiary(p_parametry: TBiLinearParametry);
    destructor Destroy; override;
    property pr_parametry: TBiLinearParametry read a_parametry;
    //property pr_enable: boolean read a_enable write a_enable;
    procedure ZrobBlinear1;
    procedure ZrobBlinear2;
    procedure ZrobBlinear3;
    procedure ZrobBlinear4;
    procedure ZrobBlinear5;
  end;



  TTestAsm = class
    tab1,tab2,tab3: Pointer;// PByteArray;
    procedure testuje;
  end;


var

    a_buf_S1_s_: Pointer;
    a_buf_S2_s_: Pointer;
    a_buf_S3_s_: Pointer;
    a_buf_S4_s_: Pointer;
    a_buf_S1_s: PBiLinearSingleArray;
    a_buf_S2_s: PBiLinearSingleArray;
    a_buf_S3_s: PBiLinearSingleArray;
    a_buf_S4_s: PBiLinearSingleArray;

  function asm_add(a,b: integer): integer; overload;
  function asm_add(a,b,c: integer): integer;  overload;
  function asm_add(a,b,c,d: integer): integer;  overload;
  function asm_add(a,b,c,d,e: integer): integer;  overload;

implementation


function asm_add(a,b: integer): integer;
begin
  result := a + b;
end;

function asm_add(a,b,c: integer): integer;
begin
  result := a + b + c;
end;

function asm_add(a,b,c,d: integer): integer;
begin
  result := a + b + d;
end;

function asm_add(a,b,c,d,e: integer): integer;  overload;
var
  x: integer;
begin
  x := a + b;
  x := x + c;
  x := x + d;
  x := x + e;
  Result := x;

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


constructor TBiLinearByte.Create(p_parametry: TBiLinearParametry);
begin
  a_parametry := p_parametry;

  a_buf_in :=  a_parametry.in_image;
  a_buf_out :=  a_parametry.out_image;

  a_max_adres_out := a_parametry.out_width * a_parametry.out_height - 1;

  a_wsp_deltaTeta_deltaR := 1;
  a_wsp_deltaTeta_deltaR_odwrotnosc := 1;

  GetMem(a_buf_S1, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearDouble));
  GetMem(a_buf_S2, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearDouble));
  GetMem(a_buf_S3, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearDouble));
  GetMem(a_buf_S4, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearDouble));
  //
  GetMem(a_buf_S1_, a_parametry.out_width * a_parametry.out_height * 1);
  GetMem(a_buf_S2_, a_parametry.out_width * a_parametry.out_height * 1);
  GetMem(a_buf_S3_, a_parametry.out_width * a_parametry.out_height * 1);
  GetMem(a_buf_S4_, a_parametry.out_width * a_parametry.out_height * 1);
  //
  GetMemA(a_buf_S1_s_, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearSingle));
  GetMemA(a_buf_S2_s_, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearSingle));
  GetMemA(a_buf_S3_s_, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearSingle));
  GetMemA(a_buf_S4_s_, a_parametry.out_width * a_parametry.out_height * sizeof(TBiLinearSingle));
  a_buf_S1_s := a_buf_S1_s_;
  a_buf_S2_s := a_buf_S2_s_;
  a_buf_S3_s := a_buf_S3_s_;
  a_buf_S4_s := a_buf_S4_s_;

  //
  GetMem(a_buf_P1,  a_parametry.out_width * a_parametry.out_height * sizeof(integer));
  GetMem(a_buf_P2,  a_parametry.out_width * a_parametry.out_height * sizeof(integer));
  GetMem(a_buf_P3,  a_parametry.out_width * a_parametry.out_height * sizeof(integer));
  GetMem(a_buf_P4,  a_parametry.out_width * a_parametry.out_height * sizeof(integer));
  //
  UstawWymiary(a_parametry);
end;

destructor TBiLinearByte.Destroy;
begin
  FreeMem(a_buf_S1);
  FreeMem(a_buf_S2);
  FreeMem(a_buf_S3);
  FreeMem(a_buf_S4);
  //
  FreeMem(a_buf_S1_);
  FreeMem(a_buf_S2_);
  FreeMem(a_buf_S3_);
  FreeMem(a_buf_S4_);
  //
  FreeMem(a_buf_P1);
  FreeMem(a_buf_P2);
  FreeMem(a_buf_P3);
  FreeMem(a_buf_P4);
  //
  inherited;
end;

procedure TBiLinearByte.UstawWymiary(p_parametry: TBiLinearParametry);
type
  TPunkt = packed record
    x,y: TBiLinearDouble;
  end;

  TTabPunkty = array [0..$6ffffff] of TPunkt;
  PTabPunkty = ^TTabPunkty;

  //TTabPunkty13x13 = array[0..12,0..12] of TPunkt;
  //PTabPunkty13x13 = ^TTabPunkty13x13;

var
  tab_pozycje: PTabPunkty;

  v_jednaLiniaX: TBiLinearDouble;
  v_jednaLiniay: TBiLinearDouble;

  v_punkt: TPunkt;
  v_adres_linia: integer;
  v_adres_punkt: integer;


  x,y: Integer;  // do poruszania sie po tablicy

  x0,x1: integer;
  y0,y1: integer;

var
  v_in_width, v_in_height, v_out_width, v_out_height: Integer;


  function DajAdres(px,py: Integer): Integer;
  var
    v_x, v_y: integer;
    v_div, v_mod: integer;
  begin
    v_x := px;
    v_y := py;
    if obrocLewoPrawo in p_parametry.opcje  then
      v_x := v_in_width - px -1;
    if obrocGoraDol in p_parametry.opcje  then
      v_y := v_in_height - py -1;

    Result := v_in_width * v_y + v_x;

    if zamienioneWierszeKolumny in p_parametry.opcje then
    begin
      v_div := Result div v_in_width;
      v_mod := Result mod v_in_width;
      result := v_mod * a_parametry.in_width + v_div;
    end;
  end;
begin
  a_parametry.in_width := p_parametry.in_width;
  a_parametry.in_height := p_parametry.in_height;
  a_parametry.out_width := p_parametry.out_width;
  a_parametry.out_height := p_parametry.out_height;

  v_in_width := a_parametry.in_width;
  v_in_height := a_parametry.in_height;
  v_out_width :=  a_parametry.out_width;
  v_out_height := a_parametry.out_height;

  //
  // na poczatek obliczam wierzcho³ki
  GetMem(tab_pozycje, v_out_width * v_out_height *  sizeof(TPunkt));
  try

    // podmieniam szerokosc i wysokosc
    if zamienioneWierszeKolumny in  p_parametry.opcje then
    begin
      v_in_width  := a_parametry.in_height;
      v_in_height :=  a_parametry.in_width;
    end;


    v_jednaLiniaX := (v_in_width -1 ) / (v_out_width - 1);
    v_jednaLiniaY := (v_in_height - 1) / (v_out_height - 1);

    for x := 0 to  v_out_width - 1 do
    begin
      for y := 0 to v_out_height - 1 do
      begin
        tab_pozycje^[ y * v_out_width + x].x := x * v_jednaLiniaX;
        tab_pozycje^[ y * v_out_width + x].y := y * v_jednaLiniaY;
      end;
    end;

    for y := 0 to  v_out_height - 1 do
    begin
      v_adres_linia := y * v_out_width;
      for x := 0 to v_out_width - 1 do
      begin
        v_adres_punkt := v_adres_linia + x;

        v_punkt := tab_pozycje^[ v_adres_punkt ];
        x0 := Trunc(v_punkt.x);
        x1 := x0 + 1;
        // poprawka na skraju
        if x1 > v_in_width - 1 then
        begin
          x1 := x0;
          x0 := x1 -1;
        end;
        //
        y0 := Trunc(v_punkt.y);
        y1 := y0 + 1;
        // poprawka na skraju
        if y1 > v_in_height - 1 then
        begin
          y1 := y0;
          y0 := y1 -1;
        end;


        a_buf_P1^[v_adres_punkt] := DajAdres(x1,y1);
        a_buf_P2^[v_adres_punkt] := DajAdres(x1,y0);
        a_buf_P3^[v_adres_punkt] := DajAdres(x0,y1);
        a_buf_P4^[v_adres_punkt] := DajAdres(x0,y0);
        //
        a_buf_S1^[v_adres_punkt] := (v_punkt.x - x0) * (v_punkt.y - y0);
        a_buf_S2^[v_adres_punkt] := (v_punkt.x - x0) * (y1 - v_punkt.y);
        a_buf_S3^[v_adres_punkt] := (x1 - v_punkt.x) * (v_punkt.y - y0);
        a_buf_S4^[v_adres_punkt] := (x1 - v_punkt.x) * (y1 - v_punkt.y);


        a_buf_S1_^[v_adres_punkt] := round((v_punkt.x - x0) * (v_punkt.y - y0)*256);
        a_buf_S2_^[v_adres_punkt] := round((v_punkt.x - x0) * (y1 - v_punkt.y)*256);
        a_buf_S3_^[v_adres_punkt] := round((x1 - v_punkt.x) * (v_punkt.y - y0)*256);
        a_buf_S4_^[v_adres_punkt] := round((x1 - v_punkt.x) * (y1 - v_punkt.y)*256);

        a_buf_S1_s^[v_adres_punkt] := ((v_punkt.x - x0) * (v_punkt.y - y0));
        a_buf_S2_s^[v_adres_punkt] := ((v_punkt.x - x0) * (y1 - v_punkt.y));
        a_buf_S3_s^[v_adres_punkt] := ((x1 - v_punkt.x) * (v_punkt.y - y0));
        a_buf_S4_s^[v_adres_punkt] := ((x1 - v_punkt.x) * (y1 - v_punkt.y));

        // poprawki dla maksimum w punkcie
        if a_buf_S1^[v_adres_punkt] = 1 then
          a_buf_S1_^[v_adres_punkt] := 255
        else
          a_buf_S1_^[v_adres_punkt] := round((v_punkt.x - x0) * (v_punkt.y - y0)*256);

        if a_buf_S2^[v_adres_punkt] = 1 then
          a_buf_S2_^[v_adres_punkt] := 255
        else
          a_buf_S2_^[v_adres_punkt] := round((v_punkt.x - x0) * (y1 - v_punkt.y)*256);

        if a_buf_S3^[v_adres_punkt] = 1  then
          a_buf_S3_^[v_adres_punkt] := 255
        else
          a_buf_S3_^[v_adres_punkt] := round((x1 - v_punkt.x) * (v_punkt.y - y0)*256);

        if a_buf_S4^[v_adres_punkt] = 1 then
          a_buf_S4_^[v_adres_punkt] := 255
        else
          a_buf_S4_^[v_adres_punkt] := round((x1 - v_punkt.x) * (y1 - v_punkt.y)*256);

       { a_buf_S1_^[v_adres_punkt] := round((v_punkt.x - x0) * (v_punkt.y - y0)*256);
        a_buf_S2_^[v_adres_punkt] := round((v_punkt.x - x0) * (y1 - v_punkt.y)*256);
        a_buf_S3_^[v_adres_punkt] := round((x1 - v_punkt.x) * (v_punkt.y - y0)*256);
        a_buf_S4_^[v_adres_punkt] := round((x1 - v_punkt.x) * (y1 - v_punkt.y)*256);
       }
      end;
    end;
  finally
    FreeMem(tab_pozycje);
  end;
end;

procedure TBiLinearByte.ZrobBlinear1;
var
  i: integer;
  value: double;
  p1,p2,p3,p4: integer;
  s1,s2,s3,s4: double;
  v1,v2,v3,v4: byte;
begin
  for I := 0 to a_max_adres_out do
  begin
    // wspólczynniki dla ka¿dego punktu typ DOUBLE
    s1 := a_buf_S1^[i];
    s2 := a_buf_S2^[i];
    s3 := a_buf_S3^[i];
    s4 := a_buf_S4^[i];

    // wzpó³rzedne punktu w bufoorze IN typ INTEGER
    p1 := a_buf_P1^[i];
    p2 := a_buf_P2^[i];
    p3 := a_buf_P3^[i];
    p4 := a_buf_P4^[i];

    // wartosc punktu
    v1 := a_buf_in^[p1];
    v2 := a_buf_in^[p2];
    v3 := a_buf_in^[p3];
    v4 := a_buf_in^[p4];

    value := (
                 a_wsp_deltaTeta_deltaR_odwrotnosc
              )
              *
              (
                s1 * v1
               +s2 * v2
               +s3 * v3
               +s4 * v4
              );
    // zapisuje wynik do tablicy OUT
    a_buf_out^[i] :=Round(value);
  end;
end;

// to  samo co ZrobBlinear1 ale a_wsp_deltaTeta_deltaR_odwrotnosc = 1
// oraz bez zapisywania do zmiennych lokalnych
procedure TBiLinearByte.ZrobBlinear2;
var
  i: integer;
begin
  for I := 0 to a_max_adres_out do
  begin
    a_buf_out^[i] :=

              round(
                a_buf_S1^[i] * a_buf_in^[a_buf_P1^[i]]
               +a_buf_S2^[i] * a_buf_in^[a_buf_P2^[i]]
               +a_buf_S3^[i] * a_buf_in^[a_buf_P3^[i]]
               +a_buf_S4^[i] * a_buf_in^[a_buf_P4^[i]]
              );

  end;
end;

procedure TBiLinearByte.ZrobBlinear3;
var
  i: integer;
  value: byte;
  p1,p2,p3,p4: integer;
  v1,v2,v3,v4: byte;
  s1_,s2_,s3_,s4_: byte;
begin
  for I := 0 to a_max_adres_out do
  begin
    // wspólczynniki do wielomianu
    s1_ := a_buf_S1_^[i];
    s2_ := a_buf_S2_^[i];
    s3_ := a_buf_S3_^[i];
    s4_ := a_buf_S4_^[i];

    p1 := a_buf_P1^[i];
    p2 := a_buf_P2^[i];
    p3 := a_buf_P3^[i];
    p4 := a_buf_P4^[i];

    v1 := a_buf_in^[p1];
    v2 := a_buf_in^[p2];
    v3 := a_buf_in^[p3];
    v4 := a_buf_in^[p4];

    value :=
              (
                s1_ * v1  //    // ADDPS => Adds 4 single-precision (32bit) floating-point values to 4 other single-precision floating-point values.
               +
                 s2_ * v2    // MULPS Performs an SIMD multiply of the four packed single-precision floating-point values from the 'src' and the 'dest' and stores the packed single-precision floating-point results in the 'dest' operand.
               +
                 s3_ * v3
               +
                 s4_ * v4
              ) shr 8;

    a_buf_out^[i] := value;
  end;
end;

procedure TBiLinearByte.ZrobBlinear4;
var
  i: integer;
begin
  for I := 0 to a_max_adres_out do
  begin
    a_buf_out^[i] :=               (
                a_buf_S1_^[i] * a_buf_in^[a_buf_P1^[i]]
               +a_buf_S2_^[i] * a_buf_in^[a_buf_P2^[i]]
               +a_buf_S3_^[i] * a_buf_in^[a_buf_P3^[i]]
               +a_buf_S4_^[i] * a_buf_in^[a_buf_P4^[i]]
              ) shr 8;
  end;
end;

procedure TBiLinearByte.ZrobBlinear5;
var
  i: integer;
  value: single;
  p1,p2,p3,p4: integer;
  v1,v2,v3,v4: byte;
  s1_,s2_,s3_,s4_: TBiLinearSingle;

{const

  SIZE = 1024 * 1024;
  ILE_CYKLI = 1000;
var
  tab1,tab2,tab3: Pointer;// PByteArray;
  tab1_: PByteArray absolute tab1;
  tab2_: PByteArray absolute tab2;
  tab3_: PByteArray absolute tab3;
  j: Integer;
  b1, b2, b3: PByte;
 }

   buf: Pointer;
   buf_4I: PIntegerArray absolute buf;

begin
  GetMemA(buf,4 * sizeof(Integer));

{  GetMemA(tab1,SIZE);
  GetMemA(tab2,SIZE);
  GetMemA(tab3,SIZE);
  FillChar(tab1^,SIZE,1);
  FillChar(tab2^,SIZE,2);
  FillChar(tab3^,SIZE,0);

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
    //mov eax, a_buf_S1_s_
    movaps xmm1, [eax] //Move 16 bytes from eax xmm0 register

    pop edx //Restore ecx
    pop ecx //Restore ecx
    pop ebx //Restore ebx
    pop eax //Restore eax
  end;

  showmessage(inttostr(integer(a_buf_S1_s_)));
  asm
     mov eax, a_buf_S1_s_
     movaps xmm1, [eax]

  end;

  a_buf_S1_s^[0] := a_buf_S1_s^[1];
  }

  for I := 0 to a_max_adres_out do
  begin
    buf_4I^[0] :=  a_buf_in^[a_buf_P1^[i]];
    buf_4I^[1] :=  a_buf_in^[a_buf_P2^[i]];
    buf_4I^[2] :=  a_buf_in^[a_buf_P3^[i]];
    buf_4I^[3] :=  a_buf_in^[a_buf_P4^[i]];
    asm
      push ebx

      mov ebx, buf        // adres wspolczynnikow
      movaps xmm2, [ebx]

      //
      mov ebx, buf        // adres BUF
      movaps xmm0, [ebx]
      cvtdq2ps xmm1, xmm0 // zamineiam integer na single
      //

      MULPS xmm0, xmm1      // mno¿enie
      //MULPS mm0, mm1      // mno¿enie
      //cvttpd2dq xmm3, xmm2     // cvttpd2dq - Converts 2 64bit doubles to 2 32bit integers using truncation.

      movaps [ebx], xmm3

      pop ebx
    end;
    (*asm
      push eax
      //
      mov ebx, a_buf_S1_s_
      movaps xmm0, [ebx]
      //
      mov ecx, a_buf_S2_s_
      movaps xmm1, [ebx]
      //
      mov ebx, a_buf_S3_s_
      movaps xmm2, [ebx]
      //
      mov eax, a_buf_S4_s_
      movaps xmm3, [eax]

      {mov eax, a_buf_S2_s
      movaps xmm0, [eax]
      //
      mov eax, a_buf_S3_s
      movaps xmm0, [eax]
      //
      mov eax, a_buf_S4_s
      movaps xmm0, [eax]
      }
      pop eax
    end;*)
    // wspólczynniki do wielomianu
    {s1_ := a_buf_S1_s^[i];
    s2_ := a_buf_S2_s^[i];
    s3_ := a_buf_S3_s^[i];
    s4_ := a_buf_S4_s^[i];

    p1 := a_buf_P1^[i];
    p2 := a_buf_P2^[i];
    p3 := a_buf_P3^[i];
    p4 := a_buf_P4^[i];

    v1 := a_buf_in^[p1];
    v2 := a_buf_in^[p2];
    v3 := a_buf_in^[p3];
    v4 := a_buf_in^[p4];

    value :=
              (
                s1_ * v1  // MULPS xmm0, [buf_v1]    // ADDPS => Adds 4 single-precision (32bit) floating-point values to 4 other single-precision floating-point values.
               +          //  xmm5 := xmm0 !!!!
                 s2_ * v2 // MULPS xmm1, [buf_v2]   // MULPS Performs an SIMD multiply of the four packed single-precision floating-point values from the 'src' and the 'dest' and stores the packed single-precision floating-point results in the 'dest' operand.
               +          // ADDPS xmm5, xmm1
                 s3_ * v3 // MULPS xmm2, [buf_v3]
               +          // ADDPS xmm5, xmm2
                 s4_ * v4 // MULPS xmm3, [buf_v4]
              ) ;    // ADDPS xmm5, xmm2

    a_buf_out^[i] := Round(value);
    }
  end;
end;


{ TTestAsm }

procedure TTestAsm.testuje;
const

  SIZE = 1024 * 1024;
  ILE_CYKLI = 1000;
begin
  GetMemA(tab1,SIZE);
  asm
    push eax //Save ebx  // tab1
    mov eax, tab1 //Set eax to tab1
    movaps xmm1, [eax] //Move 16 bytes from eax xmm0 register
    pop eax //Restore eax
  end;
end;

end.
