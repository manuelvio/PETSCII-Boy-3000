unit lightpen;
(*
* @type: unit
* @author: Manuel Vio <manuelvio74@gmail.com>
* @name: Light pen management library.
* @version: 0.1

* @description:
* Light pen management procedures and functions for use with MadPascal. 
* Inspired from https://www.c64-wiki.com/wiki/Light_pen
*
*)

interface

var
	PenX: smallint;
	PenY: smallint;
	PenCharX, PenCharY: shortint;

procedure CheckPen();


implementation
uses 
	hardware,
	c64;

var

	oldX: word;
	oldY: word;


procedure CheckPen();
var i: byte;
begin
	for i := 1 to 5 do
		begin
		PenX := PenX + (LightPenX shl 1);
		PenY := PenY + LightPenY;
		end;
	PenX := LightPenX shl 1;
	PenY := LightPenY;
	PenCharX := (PenX-48) div 8;
	if PenCharX < 0 then PenCharX := 0;
	if PenCharX > 39 then PenCharX := 39;
	PenCharY := (PenY-50) div 8;
	if PenCharY < 0 then PenCharY := 0;
	if PenCharY > 24 then PenCharY := 24;
end;

end.
