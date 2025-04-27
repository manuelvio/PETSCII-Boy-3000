unit hardware;
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
* Various hardware references for use with MadPascal. 
* Inspired from equivalent Millfork library
*
*)

interface

var

[volatile] cia1Pra: byte absolute $DC00;
[volatile] cia1Prb: byte absolute $DC01;
cia1Ddra: byte absolute      $DC02;
cia1Ddrb: byte absolute      $DC03;
[volatile] cia2Pra: byte absolute $DD00;
[volatile] cia2Prb: byte absolute $DD01;
cia2Ddra: byte absolute $DD02;
cia2Ddrb: byte absolute $DD03;

implementation

end.
