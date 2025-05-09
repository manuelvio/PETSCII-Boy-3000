unit lightpen;
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
