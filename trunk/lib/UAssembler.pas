unit UAssembler;

interface

uses SysUtils, Windows;

type
  TProc_AddByteArrays = procedure (Tab1,Tab2,Tab3:pointer; Size:Integer);


// Tab3 := Tab2 + Tab1
procedure AddByteArrays(Tab1,Tab2,Tab3:pointer; Size:Integer);
procedure AddByteArrays_pointer(Tab1,Tab2,Tab3:pointer; Size:Integer);
procedure AddByteArrays_mmx(Tab1,Tab2,Tab3:pointer; Size:Integer);


function Test_AddByteArrays(p_size: Integer; p_proc: TProc_AddByteArrays; mmx: Boolean = false ): string;

implementation

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



procedure AddByteArrays(Tab1,Tab2,Tab3:pointer; Size:Integer);
var
  i: Integer;
  t1: PByteArray absolute Tab1;
  t2: PByteArray absolute Tab2;
  t3: PByteArray absolute Tab3;
begin
  for I := 0 to Size - 1 do
  begin
    t3^[i] := t1^[i] + t2^[i]
  end;
end;

procedure AddByteArrays_pointer(Tab1,Tab2,Tab3:pointer; Size:Integer);
var
  i: Integer;
  t1: PByte ;
  t2: PByte ;
  t3: PByte ;
begin
  t1 := PByte(Tab1);
  t2 := PByte(Tab2);
  t3 := PByte(Tab3);
  for I := 0 to Size - 1 do
  begin
    t3^ := t1^ + t2^;
    Inc(t1);
    Inc(t2);
    Inc(t3);
  end;
end;


procedure AddByteArrays_mmx(Tab1,Tab2,Tab3:pointer; Size:Integer);
begin
  asm
    push eax //Save ebx  // tab1
    push ebx //Save edx  // tab2
    push ecx //Save edx  // tab3
    push edx //Save edx  // licznik petli

    mov edx, Size // ustawiam licznik petli

    mov eax, tab1 //Set eax to tab1
    mov ebx, tab2 //Set ebx to tab2
    mov ecx, tab3 //Set ecx to tab3

    @@InnerLoop:
      //[wersja 2]
      movaps xmm1, [eax] //Move 16 bytes from eax xmm0 register
      paddb xmm1, [ebx] // wykonuje dodawanie
      movaps [ecx], xmm1 //Put the data to ecx
      // przesuwam wskaznik
      add eax, 16  // tab1
      add ebx, 16  // tab2
      add ecx, 16  // tab3
      //
      sub edx, 16  // zmniejszam licznik petli
    JNZ @@InnerLoop


    pop edx //Restore ecx
    pop ecx //Restore ecx
    pop ebx //Restore ebx
    pop eax //Restore eax
  end;
end;

function Test_AddByteArrays(p_size: Integer; p_proc: TProc_AddByteArrays;  mmx: Boolean = false): string;
var
  t1,t2,t3: Pointer;
var
  StartTick,
  EndTick,
  Frequency : Int64;
  i: integer;
begin
  if mmx = true then
  begin
    GetMemA(t1,p_size);
    GetMemA(t2,p_size);
    GetMemA(t3,p_size);
  end
  else
  begin
    GetMem(t1,p_size);
    GetMem(t2,p_size);
    GetMem(t3,p_size);
  end;

  QueryPerformanceFrequency(Frequency);
  QueryPerformanceCounter(StartTick);
  //
  for I := 0 to 1000 - 1 do
    p_proc(t1,t2,t3,p_size);
  //
  QueryPerformanceCounter(EndTick);
  result := (Format('Time = %.2f ms'+sLineBreak +
                    'Transfer = %.2f MB/s',[((EndTick - StartTick) / Frequency) * 1000,
                                   (p_size/(1024*1024))  / ((EndTick - StartTick) / Frequency)   ]));



  if mmx = true then
  begin
    FreeMemA(t1);
    FreeMemA(t2);
    FreeMemA(t3);
  end
  else
  begin
    FreeMem(t1);
    FreeMem(t2);
    FreeMem(t3);
  end;
end;



end.
