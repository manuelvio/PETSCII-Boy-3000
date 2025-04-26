unit hardware;
(*
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
