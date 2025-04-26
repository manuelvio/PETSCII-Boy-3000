unit fileutils;

interface
const
    ERR_OK              = 0;
    ERR_FAIL            = 1;
    ERR_NUMBERFORMAT    = 2;
    ERR_OUTOFMEMORY     = 3;
    ERR_DOMAIN          = 4;
    ERR_RANGE           = 5;
    ERR_NOFILE          = 6;
    ERR_NODEVICE        = 7;
    ERR_EOF             = 8;

function Command(const command: string; const device: byte): byte; overload;
function CommandAsm(command: pointer; cmdLength: byte; device: byte): byte; assembler;

function LoadFile(const fileName: string; const device: byte): byte; overload;
function LoadFile(const fileName: string; const device: byte; const address: pointer): byte; overload;
//function SaveMem(const fileName: string; const device: byte; const address: pointer; const count: word): byte; overload;
function SaveMem(const fileName: string; const device: byte; const address: word; const count: word): byte; overload;
function SaveMem(const fileName: string; const device: byte; const address: pointer; const count: word): byte; overload;
//function SaveMem(const fileName: string; const device: byte; const address: pointer; const endAddress: pointer): byte; overload;
function DiskStatus(const deviceNumber:byte): byte; assembler;
function ReadStatus(): byte; assembler;

implementation
uses kernal in 'kernal.pas';

var
    [volatile] _lastUsedDevice: byte absolute $00ba;

function ReadStatus(): byte; assembler;
asm
        txa:pha
        jsr KERNAL.KERNAL_READST
        sta Result
        pla:tax
end;

function HandleError(): byte; assembler;
asm
        txa:pha
        bcs has_failed
        lda ERR_OK
        jmp ret_err_code
has_failed
        ora #$40
        jsr KERNAL.KERNAL_CHROUT
        and #$BF
        lsr
        eor #2
        bne other_err
        lda ERR_NOFILE
        bcc ret_err_code
        lda ERR_NODEVICE
        jmp ret_err_code
other_err:
        lda ERR_FAIL
ret_err_code:
        sta Result
        pla:tax
end;


function LastUsedDevice(): byte;
var device: byte;
begin
    device := _lastUsedDevice;
    if device = 0 then
    begin
        device := 8;
    end;
    Result := device;
end;

procedure SetNam(const fileName: string); assembler;
asm
        txa:pha
        lda adr.fileName        ; load filename length (address of byte 0)
        ldx <adr.fileName+1     ; load filename first byte address
        ldy >adr.fileName+1
        jsr KERNAL.KERNAL_SETNAM               ; call SETNAM
        pla:tax
end;


procedure SetLfs(const fileNumber: byte; const device: byte; const secondary: byte); assembler;
asm
        txa:pha
        lda fileNumber              ; load fileNumber in A
        ldx device                  ; load device in X
        ldy secondary               ; load secondary address in Y
        jsr KERNAL.KERNAL_SETLFS    ; call SETLFS
        pla:tax
end;

function Command(const command: string; const device: byte): byte; overload;
var output: byte;
begin
    SetNam(command);
    SetLfs(15, device, 15);
    asm
        jsr KERNAL.KERNAL_OPEN
        bcs erropen
        lda #ERR_OK
    erropen:
        sta output
    end;
    write('Registro a='); writeln(output);
    if output > ERR_OK then
        Result := output
    else
        begin
            asm
                lda #$0F
                jsr KERNAL.KERNAL_CLOSE
                bcs errclose
                lda #ERR_OK
            errclose:
                sta output
            end;
        end;
    Result := output;
end;

function CommandAsm(command: pointer; cmdLength: byte; device: byte): byte; assembler;
asm
        txa:pha
        lda cmdLength        ; load command length (address of byte 0)
        ldx #<command     ; load command first byte address
        ldy #>command
        jsr KERNAL.KERNAL_SETNAM               ; call SETNAM

        lda #$01
        ldx device
        ldy #$0F
        jsr KERNAL.KERNAL_SETLFS

        jsr KERNAL.KERNAL_OPEN
        bcs erropen
        lda #ERR_OK
    erropen:
        sta Result

        lda #$0F
        jsr KERNAL.KERNAL_CLOSE
        bcs errclose
        lda #ERR_OK
    errclose:
        sta Result
        pla:tax
end;


function LoadFile(const fileName: string; const device: byte): byte; overload;
begin
    SetNam(fileName);
    SetLfs(1, device, 1);
    asm
        lda #$00
        jsr KERNAL.KERNAL_LOAD
    end;
    Result := HandleError();
end;

function LoadFile(const fileName: string; const device: byte; const address: pointer): byte; overload;
begin
    SetNam(fileName);
    SetLfs(1, device, 1);
    asm
        lda #$00
        ldx address
        ldy address+1
        jsr KERNAL.KERNAL_LOAD
    end;
    Result := HandleError();
end;

function SaveMem(const fileName: string; const device: byte; const address: pointer; const count: word): byte; overload;
var endData: pointer;
begin
    SetNam(fileName);
    SetLfs(1, device, 0);
    endData := address + count;
    asm
        mva address $c1
        mva address+1 $c2
        ldx endData
        ldy endData+1
        lda #$c1
        jsr KERNAL.KERNAL_SAVE
    end;
    Result := HandleError();
end;


function SaveMem(const fileName: string; const device: byte; const address: word; const count: word): byte; overload;
var endData: word;
begin
    SetNam(fileName);
    SetLfs(1, device, 0);
    asm
        mva address $c1
        mva address+1 $c2
        ldx count
        ldy count+1
        lda #$c1
        clc
        jsr KERNAL.KERNAL_SAVE
    end;
    Result := HandleError();
end;


function DiskStatus(const deviceNumber:byte): byte; assembler;
asm
    txa:pha
    lda #$00
    sta $90             ; clear status flags
    lda deviceNumber    ; device number
    jsr KERNAL.KERNAL_LISTEN
    lda #$6f            ; secondary address
    jsr KERNAL.KERNAL_SECOND
    jsr KERNAL.KERNAL_UNLSN
    lda $90
    bne sds_devnp       ; device not present
    lda #$08
    jsr KERNAL.KERNAL_TALK
    lda #$6f            ; secondary address
    jsr KERNAL.KERNAL_TKSA
sds_loop:
    lda $90             ; get status flags
    bne sds_eof
    jsr KERNAL.KERNAL_ACPTR
    jsr KERNAL.KERNAL_CHROUT
    jmp sds_loop
sds_eof:
    jsr KERNAL.KERNAL_UNTLK
    STA Result
    pla:tax
    rts
sds_devnp:
    ; handle device not present error handling
    STA Result
    pla:tax
    rts
end;

end.