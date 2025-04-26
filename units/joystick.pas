unit joystick;
(*
* @type: unit
* @author: Manuel Vio <manuelvio74@gmail.com>
* @name: Joystick management library.
* @version: 0.1

* @description:
* Joystick management procedures and functions for use with MadPascal. 
* Inspired from equivalent Millfork library
*
*)

interface

uses hardware;

var

inputDx, inputDy: shortint;
inputButton: byte;
previousButtonState: byte;
buttonPressed: boolean;

procedure ResetJoystick();
procedure ReadJoystick1();
procedure ReadJoystick2();


implementation

procedure ResetJoystick();
begin
    inputDx := 0;
    inputDy := 0;
    inputButton := 0;
end;

procedure ReadJoystick1();
var
    value, bakCia: byte;
begin
    ResetJoystick();
	bakCia := cia1Ddrb;
	cia1Ddrb := 0;
	value := cia1Prb;
	if value AND 1 = 0 then Dec(inputDy);
	if value AND 2 = 0 then Inc(inputDy);
	if value AND 4 = 0 then Dec(inputDx);
	if value AND 8 = 0 then Inc(inputDx);
	if value AND 16 = 0 then Inc(inputButton);
	buttonPressed := ((previousButtonState = 0) and (inputButton = 1));
	previousButtonState := inputButton;
	cia1Ddrb := bakCia;
end;

procedure ReadJoystick2();
var
    value, bakCia: byte;
begin
    ResetJoystick();
	bakCia := cia1Ddra;
	cia1Ddra := 0;
	value := cia1Pra;
	if value AND 1 = 0 then Dec(inputDy);
	if value AND 2 = 0 then Inc(inputDy);
	if value AND 4 = 0 then Dec(inputDx);
	if value AND 8 = 0 then Inc(inputDx);
	if value AND 16 = 0 then Inc(inputButton);
	buttonPressed := ((previousButtonState = 0) and (inputButton = 1));
	previousButtonState := inputButton;
	cia1Ddra := bakCia;
end;


end.
