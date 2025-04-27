unit kernal;
(*

MIT License

Copyright (c) 2025 Manuel Vio

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

* @type: unit
* @author: Manuel Vio <manuelvio74@gmail.com>
* @name: Hardware reference library.
* @version: 0.1

* @description:
* C64 Kernal functionso 
* Inspired from equivalent Millfork library
* Info from https://sta.c64.org/cbm64krnfunc.html
*)


interface

type
    TFileName = string[16];


function KernalSetnam(): boolean; assembler; overload;
function KernalSetnam(arg: TFileName): boolean; assembler; overload;
function KernalSetlfs(fd: byte; device:byte; secondary:byte): boolean; assembler;
function KernalOpen(): boolean; assembler;
function KernalClose(fd: byte): boolean; assembler;
procedure KernalChkin(fd: byte); assembler;
procedure KernalChkout(fd: byte); assembler;
function KernalReadst(): byte; assembler;
function KernalChrin(): byte; assembler;
function KernalChrout(c: byte): byte; assembler;
procedure KernalClrchn(); assembler;
procedure KernalCommand(arg: string; device: byte);
function KernalLoadMem(filename: TFileName; device: byte; destAddress: pointer): byte;
function KernalSaveMem(filename: TFileName; device: byte; startAddress: pointer; endAddress: pointer): byte;
procedure KernalPlot(x: byte; y: byte); assembler;
function GetError(device: byte): string;
procedure SaveBytes(fileName: TFileName; device: byte; source: pointer; size: word);
procedure LoadBytes(fileName: TFileName; device: byte; dest: pointer);
function KernalFileExist(fileName: string; device: byte):boolean;


implementation

uses stringUtils, sysutils;

const

KERNAL_SETNAM      = $FFBD;
KERNAL_SETLFS      = $FFBA;
KERNAL_OPEN        = $FFC0;
KERNAL_CLOSE       = $FFC3;
KERNAL_CLRCHN      = $FFCC;
KERNAL_LOAD        = $FFD5;
KERNAL_LISTEN      = $FFB1;
KERNAL_SECOND      = $FF93;
KERNAL_UNLSN       = $FFAE;
KERNAL_TALK        = $FFB4;
KERNAL_TKSA        = $FF96;
KERNAL_ACPTR       = $FFA5;
KERNAL_CHROUT      = $FFD2;
KERNAL_UNTLK       = $FFAB;
KERNAL_CHKIN       = $FFC6;
KERNAL_CHKOUT      = $FFC9;
KERNAL_READST      = $FFB7;
KERNAL_CHRIN       = $FFCF;     
KERNAL_SAVE        = $FFD8;
KERNAL_PLOT        = $FFD8;

var

lastError: byte;

procedure KernalPlot(x: byte; y: byte); assembler;
asm
    txa:pha
    clc
    ldx x
    ldy y
    jsr KERNAL_PLOT
    pla:tax
end;

procedure KernalCommand(arg: string; device: byte);
begin
    KernalSetnam(arg);
    KernalSetlfs(16, device, 15);
    KernalOpen();
    KernalClose(16);
end;

function KernalLoadMem(filename: TFileName; device: byte; destAddress: pointer): byte;
begin
    KernalSetnam(filename);
    KernalSetlfs(1, device, 0);
    asm
        ldx <destAddress
        ldy >destAddress
        lda #$00            ; $00 means: load to memory (not verify)
        jsr KERNAL_LOAD     ; call LOAD
        bcs error           ; carry set? branch to error
        rts
    error:
        sta Result
        rts
    end;
end;

function KernalSaveMem(filename: TFileName; device: byte; startAddress: pointer; endAddress: pointer): byte;
begin
    KernalSetnam(filename);
    KernalSetlfs(1, device, 0);
    asm
        mwa startAddress $C1

        ldx <endAddress
        ldy >endAddress
        lda #$C1                            ; $00 means: load to memory (not verify)
        jsr KERNAL_SAVE               ; call SAVE
        bcs error           ; carry set? branch to error
        lda #$01            ; otherwise return true
    close:
        sta Result
        pla:tax
        rts       
    error:  
        sta lastError       ; store accumulator in lastError
        lda #$00            ; return false
        jmp close
    end;
end;

function KernalSetnam(arg: TFileName): boolean; assembler; overload;
asm
        txa:pha
        lda adr.arg         ; load filename length
        ldx <adr.arg+1      ; load filename first byte address
        Ldy >adr.arg+1
        jsr KERNAL_SETNAM   ; call SETNAM
        bcs error           ; carry set? branch to error
        lda #$01            ; otherwise return true
    close:
        sta Result
        pla:tax
        rts       
    error:  
        sta lastError       ; store accumulator in lastError
        lda #$00            ; return false
        jmp close
end;

function KernalSetnam(): boolean; assembler; overload;
asm
        txa:pha
        lda #$00            ; load filename length
        ldx #$00     ; load filename first byte address
        Ldy #$00
        jsr KERNAL_SETNAM          ; call SETNAM
        bcs error           ; carry set? branch to error
        lda #$01            ; otherwise return true
    close:
        sta Result
        pla:tax
        rts       
    error:  
        sta lastError       ; store accumulator in lastError
        lda #$00            ; return false
        jmp close
end;

function KernalSetlfs(fd: byte; device: byte; secondary: byte): boolean; assembler;
asm
        txa:pha
        lda fd            ; set parameters
        ldx device            
        ldy secondary
        jsr KERNAL_SETLFS          ; call SETLFS
        bcs error           ; carry set? branch to error
        lda #$01            ; otherwise return true
    close:
        sta Result
        pla:tax
        rts       
    error:  
        sta lastError       ; store accumulator in lastError
        lda #$00            ; return false
        jmp close
end;

function KernalOpen(): boolean; assembler;
asm
        txa:pha
        jsr KERNAL_OPEN     ; call OPEN
        bcs error           ; carry set? branch to error
        lda #$01            ; otherwise return true
    close:
        sta Result
        pla:tax
        rts       
    error:  
        sta lastError       ; store accumulator in lastError
        lda #$00            ; return false
        jmp close
end;

procedure KernalChkin(fd: byte); assembler;
asm
        txa:pha
        ldx fd
        jsr KERNAL_CHKIN     ; call CHKIN
        pla:tax
end;

procedure KernalChkout(fd: byte); assembler;
asm
        txa:pha
        ldx fd
        jsr KERNAL_CHKOUT     ; call CHKOUT
        pla:tax
end;

function KernalReadst(): byte; assembler;
asm
        txa:pha
        jsr KERNAL_READST     ; call READST
        sta Result
        pla:tax
end;

function KernalChrin(): byte; assembler;
asm
        txa:pha
        jsr KERNAL_CHRIN     ; call CHRIN
        sta Result
        pla:tax
end;

function KernalChrout(c: byte): byte; assembler;
asm
        txa:pha
        lda c
        jsr KERNAL_CHROUT     ; call CHROUT
        pla:tax
end;

function KernalClose(fd: byte): boolean; assembler;
asm
        txa:pha
        lda fd
        jsr KERNAL_CLOSE     ; call CLOSE
        bcs error           ; carry set? branch to error
        lda #$01            ; otherwise return true
    close:
        sta Result
        pla:tax
        rts       
    error:  
        sta lastError       ; store accumulator in lastError
        lda #$00            ; return false
        jmp close
end;

procedure KernalClrchn(); assembler;
asm
        txa:pha
        jsr KERNAL_CLRCHN     ; call CLRCHN
        pla:tax
end;

function GetError(device: byte): string;
var
  outResult: string;
begin
  outResult := '';
  KernalSetnam();
  KernalSetlfs(15, device, 15);
  if KernalOpen() then
  begin
    KernalChkin(15);
    while KernalReadst() = 0 do
    begin
      outResult := strCat(outResult, chr(KernalChrin));
    end;
  end;
  KernalClose(15);
  KernalClrchn();
  Result := outResult;
end;

procedure SaveBytes(fileName: TFileName; device: byte; source: pointer; size: word);
var
  i : word;
begin
  i := 0;
  KernalSetnam(fileName);
  KernalSetlfs(1, device, 9);
  if KernalOpen() then
  begin
    KernalChkout(1);
    for i := 0 to size-1 do
    begin
      if KernalReadst() <> 0 then
        break;
      begin
        KernalChrout(PByte(source + i)^);
      end;
    end;
  end;
  KernalClose(1);
  KernalClrchn();
end;

procedure LoadBytes(fileName: TFileName; device: byte; dest: pointer);
var
  i : word;
  b : byte;
begin
  i := 0;
  KernalSetnam(fileName);
  KernalSetlfs(1, device, 9);
  if KernalOpen() then
  begin
    KernalChkin(1);
    while KernalReadst() = 0 do
    begin
      Poke(dest+i, KernalChrin());
      inc(i);
    end;
  end;
  KernalClose(1);
  KernalClrchn();
end;

function KernalFileExist(fileName: string; device: byte):boolean;
var
 chrread: byte;
begin
  KernalSetnam(fileName);
  KernalSetlfs(1, device, 9);
  Result := false;
  if KernalOpen() then
  begin
    KernalChkin(1);
    KernalChrin();
    Result := (KernalReadst() = 0)
  end;
  KernalClose(1);
  KernalClrchn();
end;

end.