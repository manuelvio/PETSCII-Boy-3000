unit mouse1531;
(*
* @type: unit
* @author: Manuel Vio <manuelvio74@gmail.com>
* @name: 1531 Mouse management library.
* @version: 0.1

* @description:
* 1531 Mouse management procedures and functions for use with MadPascal. 
* Inspired from equivalent Millfork library
*
*)

interface

var
	mouseX: word = 0;
	mouseY: word = 0;
	deltaX, deltaY: smallint;
	mouseLbm, mouseRbm: boolean;

procedure CheckMouse();


implementation
uses 
	hardware,
	c64;

var
	oldX: word = 0;
	oldY: word = 0;
	oldPotX, oldPotY: byte;
	mouseXAlias: PByteArray;


function CalculateDelta(oldV, newV: byte): shortint;
var
	mouseDelta: shortint;
begin
	mouseDelta := newV - oldV;
	mouseDelta := mouseDelta AND $3F;
	if mouseDelta >= $20 then
		mouseDelta := mouseDelta OR $C0;
	Result := mouseDelta;
end;


procedure HandleX();
var 
	mouseDelta: shortint;
	newPotX: byte;
begin
	oldX := mouseX;
	newPotX := POTX shr 1;
	mouseDelta := CalculateDelta(oldPotX, newPotX);
	oldPotX := newPotX;
	mouseX := mouseX + mouseDelta;
	mouseXAlias := pointer(@mouseX);
	mouseXAlias[1] := mouseXAlias[1] AND $01;
	// mouseX := mouseX AND $01FF;
	if mouseX > 319 then
		if mouseDelta > 0 then
			mouseX := 319
		else
			mouseX := 0;
	deltaX := oldX - mouseX;
end;

procedure HandleY();
var 
	mouseDelta: shortint;
	newPotY: byte;
begin
	oldY := mouseY;
	newPotY := POTY shr 1;
	mouseDelta := CalculateDelta(oldPotY, newPotY);
	oldPotY := newPotY;
	mouseY := mouseY - mouseDelta;
	if mouseY > 199 then
		if mouseDelta > 0 then
			mouseY := 199
		else
			mouseY := 0;
	deltaY := oldY - mouseY;
end;


procedure CheckMouse();
var
	cia1PrbValue,
	prevCia1Pra,
	prevCia1Ddrb: byte;
begin
	prevCia1Pra := cia1Pra;
	cia1Pra := (cia1Pra AND $3F) OR $40;
    HandleX();
    HandleY();
	prevCia1Ddrb := cia1Ddrb;
	cia1Ddrb := 0;
	cia1PrbValue := cia1Prb;
	cia1Ddrb := prevCia1Ddrb;
	cia1Pra := prevCia1Pra;
	mouseRbm := boolean((cia1PrbValue AND $01) XOR $01);
	mouseLbm := (cia1PrbValue AND 16 = 0);
end;

end.
