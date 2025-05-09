program PetsciiBoy3000;

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

@type: program
@author: Manuel Vio <manuelvio74@gmail.com>
@name: PetsciiBoy3000
@version: 1.0

@description:
Based on a backpropagation neural network, recognizes hand written digits,
in a nuclear distopic style. 

*)

uses 
  crt,
  sysutils,
  c64,
  math,
  stringUtils,
  strutils,
  kernal,
  neuralnet,
  joystick in 'units\joystick.pas',
  mouse1531 in 'units\mouse1531.pas',
  lightpen in 'units\lightpen.pas';

type
  TSprite = array[0..63] of byte;
  TMenuString = string[15];
  PMenuString = ^TMenuString;
  TMenu = array[0..4] of TMenuString;

const
  DRIVE_NO = 8;
  CANVAS_X = 1;
  CANVAS_Y = 1;
  CANVAS_HEIGHT = 16;
  CANVAS_WIDTH = 16;
  BLANK: char = ' ';
  CANVAS_PIXEL_ON: char = '*';
  CANVAS_PIXEL_OFF: char = BLANK;
  KEY_Y: byte = 121;
  MENU_ITEMS = 5;
  BATCHES_COUNT = 16;

  INPUT_JOYSTICK = 0;
  INPUT_LIGHTPEN = 1;

  // Histogram levels are rendered using PETSCII chars, but some are available only in reversed mode
  // hence array values are not single chars, they're screen codes sequences
  ACTIVATION_HISTOGRAM_LEVELS: array [0..8] of string[3] = (
    ' '#0#0,
    #164#0#0,
    #175#0#0,
    #185#0#0,
    #162#0#0,
    #18#184#146,
    #18#183#146,
    #18#163#146,
    #18#32#146
  );

 MAIN_MENU: TMenu = (
  'F1-Train',
  'F2-Save params',
  'F3-Load params',
  'F4-Clear Canvas',
  'F5-Draw'
  );

  TRAINING_MENU: TMenu = (
  'Press any key',
  'to stop',
  '',
  '',
  '' 
  );

  DRAWING_MENU: TMenu = (
  'F1-Joystick',
  'F2-Light pen',
  '',
  '',
  'F5-Predict'
  );

var
  KeyboardBufferLength: byte absolute $00C6; // Used to "clear" keyboard buffer
  Sprite0AddrMult: byte absolute $07F8; // Sprite data mutiplicators address
  Sprite1AddrMult: byte absolute $07F9;
	screenRam  : array[0..1000-1] of char absolute $0400;
  currentColor: byte absolute $0286; // Current text color
  epoch, i, j, dx, dy: byte;
  
  batch : TBatch;
  currInput: TInput;
  batchIndexes: array[0..15] of byte = (15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0); // Batches "indexes", this array in going to be shuffled before an epoch starts
  batchIdx: byte;
  batchName: TString;
  correct: word;
  predicted : byte;
  cursorSpriteData: array of byte = [{$bin2csv cursor_sprite.bin}];
  cursorSprite: TSprite absolute $0380;
  digitSprite: TSprite absolute $0340;
  cursorX, cursorY: byte;
  oldCursorX, oldCursorY: byte;
  cursorMoved: boolean;
  row, bit: byte;
  chardata: array[0..7] of byte;
  inputMode: byte = INPUT_LIGHTPEN;


procedure moveCursor(x, y: shortint);
(*
* @description:
* Moves cursor sprite on the canvas
*
* @param: (byte) x - x coordinate (0-15).
* @param: (byte) y - y coordinate (0-15).
*)
begin
  cursorX := min(max(x, 0), CANVAS_WIDTH-1); // Limiting x and y values between 0-15 range
  cursorY := min(max(y, 0), CANVAS_HEIGHT-1);

// Sprite x to char: (sprx - 24) div 8
// Sprite y to char: (spry - 50) div 8
// Char to sprite x: (cx * 8) + 24
// Char to sprite y: (cy * 8) + 50

  Sprite1X := ((cursorX + CANVAS_X) * 8) + 24;
  Sprite1Y := ((cursorY + CANVAS_Y) * 8) + 50;
end;

procedure togglePixel(pressed: boolean);
(*
* @description:
* Toggles a "pixel" on the canvas
*
* @param: (byte) pressed - 1 = joystick button is pressed, otherwise 0.
*)
var
  pixelChar: ^char; 
begin
  if pressed then
  begin
    pixelChar := @screenRam[((cursorY+CANVAS_Y)*40) + cursorX + CANVAS_X];
    if pixelChar^ = CANVAS_PIXEL_OFF then
      pixelChar^ := CANVAS_PIXEL_ON
    else
      pixelChar^ := CANVAS_PIXEL_OFF;
  end;
end;

procedure EnableCursor();
(*
* @description:
* Makes canvas cursor visible
*)
begin
  EnableSprites := EnableSprites OR %00000010;
  moveCursor(0,0);
end;

procedure DisableCursor();
(*
* @description:
* Hides canvas cursor
*)
begin
  EnableSprites := EnableSprites AND %11111101;
end;

procedure Log(entry: TString); overload;
(*
* @description:
* Adds a line of output to "terminal" scrolling the other to the top
*
* @param: (TString) entry - The text line.
*) 
var
  currX, currY :  byte;
begin
  currX := whereX();
  currY := whereY();
  move(@screenRam[20*40 + 1], @screenRam[19*40 + 1], 32);
  move(@screenRam[21*40 + 1], @screenRam[20*40 + 1], 32);
  move(@screenRam[22*40 + 1], @screenRam[21*40 + 1], 32);
  gotoxy(2,23);
  write(strCat(entry, Space(32-length(entry))));
  gotoxy(currX, currY);
end;

procedure Log(color: byte; entry: TString); overload;
(*
* @description:
* Adds a line of output to "terminal" scrolling the other to the top
*
* @param: (byte) color - The color of the text.
* @param: (TString) entry - The text line.
*) 
var
  bakColor : byte;
begin
  bakColor := currentColor;
  currentColor := color;
  Log(entry);
  currentColor := bakColor;
end;

function Confirm(msg: TString): boolean;
(*
* @description:
* Writes a message, expects a confirmation.
*
* @param: (TString) msg - The message to be written on screen.
* 
* @result: boolean - Whether Y (true) or any other key (false) was pressed
*)
begin
  KeyboardBufferLength := 0; // Clear keyboard buffer
  Log(LIGHT_GREEN, msg);
  repeat until keypressed;
  Result := (ord(ReadKey()) = KEY_Y);
end;

procedure LoadBackground(fileName: TFileName; device: byte);
(*
* @description:
* Loads and display background screen data in SEQ format
*
* @param: (TFileName) filename - The SEQ file name.
* @param: (byte) device - The disk device.
*) 
begin
  KernalSetnam(fileName);
  KernalSetlfs(1, device, 9);
  if KernalOpen() then
  begin
    KernalChkin(1);
    while KernalReadst() = 0 do
      write(chr(KernalChrin()));
  end;
  KernalClose(1);
  KernalClrchn();
end;

procedure LoadTrainingBatch(fileName: TFileName; device: byte; var destAddress: TBatch);
(*
* @description:
* Loads Training batch data in memory.
* File type can be USR or SEQ. Expected data structure is made of 33 bytes sequences.
* Destination address points to a TBatch
*
* @param: (TFileName) filename - The file name.
* @param: (destAddress) TBatch - The batch variable used to store input training data.
*) 
var
  i, j : byte;
begin
  i := 0;
  batchLength := 0;
  KernalSetnam(fileName);
  KernalSetlfs(1, device, 9);
  if KernalOpen() then
  begin
    KernalChkin(1);
    for j :=0 to BATCH_ROW_COUNT_MAX-1 do
    begin
      if KernalReadst() <> 0 then
        break;
      
      for i := 0 to 32 do
        destAddress[i, j] := KernalChrin();
      inc(batchLength);
    end;
  end;
  KernalClose(1);
  KernalClrchn();
end;

procedure SaveNetworkParameters(device: byte);
(*
* @description:
* Dumps weights and biases data to disk.
*
* @param: (byte) device - The disk device.
*) 
begin
  SaveBytes('@0:WH,U,W', device, @weightsHidden, length(weightsHidden)*sizeof(float));
  SaveBytes('@0:WO,U,W', device, @weightsOutput, length(weightsOutput)*sizeof(float));
  SaveBytes('@0:BH,U,W', device, @biasesHidden, length(biasesHidden)*sizeof(float));
  SaveBytes('@0:BO,U,W', device, @biasesOutput, length(biasesOutput)*sizeof(float));
end;

procedure LoadNetworkParameters(device: byte);
(*
* @description:
* Loads weights and biases data from disk.
*
* @param: (byte) device - The disk device.
*) 
begin
  LoadBytes('WH,U,R', device, @weightsHidden);
  LoadBytes('WO,U,R', device, @weightsOutput);
  LoadBytes('BH,U,R', device, @biasesHidden);
  LoadBytes('BO,U,R', device, @biasesOutput);
end;

procedure Init();
(*
* @description:
* System initialization.
*)
begin
  Randomize();
  ClrScr();
  BorderColor := BLACK;
  Backgroundcolor0 := BLACK;
  LoadBackground('BACKGROUND,S,R', DRIVE_NO);
  // Initialize data for digit drawing sprite
  
  EnableSprites := $01;
  Sprite0AddrMult := 13; // 64 * 13 = 832, start address of sprite 0 data
  Sprite1AddrMult := 14; // 64 * 14 = 896, start address of sprite 1 data
  SpriteYExpansion := $01;
  SpriteXExpansion := $01;
  SpritesXmsb := 1;
  Sprite0X := 49; 
  Sprite0Y := 58;
  Sprite0Color := LIGHT_GREEN;
  Sprite1Color := YELLOW;
  
  Sprite1X := 32;
  Sprite1Y := 58;
  move(cursorSpriteData, cursorSprite, 64);
  currentColor := GREEN;
end;



procedure DrawDigit(var input: TInput);
(*
* @description:
* Builds sprite animation from input data.
*
* @param: (TInput) input - The input digit pixels.
*)
var
  dx, dy: byte;
begin
  for dy := 0 to 15 do
    for dx := 0 to 1 do
      digitSprite[(dy * 3) + dx] := input[(dy * 2) + dx]; 
end;

procedure ClearDigit();
(*
* @description:
* Clears sprite data.
*
* @param: (TInput) input - The input digit pixels.
*)
var
  dx, dy: byte;
begin
  for dy := 0 to 15 do
    for dx := 0 to 1 do
      digitSprite[(dy * 3) + dx] := 0; 
end;

procedure ShuffleBatchIndexes();
(*
* @description:
* Shuffles batches indexes used to fetch files from disk.
*)
var
  i, tmp, j: byte;
begin
    for i:=0 to BATCHES_COUNT-1 do
    begin
      j := RANDOM mod BATCHES_COUNT;
      tmp := batchIndexes[i];
      batchIndexes[i] := batchIndexes[j];
      batchIndexes[j] := tmp;
    end;
end;

procedure c64Randomize; assembler;
(*
* @description:
* Uses SID noise generator to obtain a random number.
*)
asm
  lda #$ff  ; maximum frequency value
  sta $D40E ; voice 3 frequency low byte
  sta $D40F ; voice 3 frequency high byte
  lda #$80  ; noise waveform, gate bit off
  sta $D412 ; voice 3 control register
end;

procedure ClearScreenArea(x1, y1, x2, y2:byte);
(*
* @description:
* Fills a rectangular screen area with blank characters.
*
* @param: (byte) x1 - The topmost left corner x coordinate (0-39).
* @param: (byte) y1 - The topmost left corner y coordinate (0-24).
* @param: (byte) x2 - The lowermost right corner x coordinate (0-39).
* @param: (byte) y2 - The lowermost right corner y coordinate (0-24).
*) 
var
  x, y: byte;
begin
  for y := y1 to y2 do
    for x := x1 to x2 do
      screenRam[y * 40 + x] := CANVAS_PIXEL_OFF
end;

procedure DisplayMenu(menuAddr: TMenu);
(*
* @description:
* Writes menu.
*)
var i: byte;
begin
  ClearScreenArea(19, 7, 38, 16);
  for i := 0 to MENU_ITEMS-1 do
  begin
    GotoXY(20, 8+i);
    write(menuAddr[i]);
  end;
end;

procedure CanvasToInput(var input: TInput);
(*
* @description:
* Converts canvas in TInput format compatible with predict function.
*
* @result (TInput): The drawing data
*) 
var
  byteValue, i, x, y: byte;
begin
  byteValue := 0;
  for y := 0 to 15 do
    for x := 0 to 15 do
    begin
      i := (y * 16) + x;
      if screenRam[(CANVAS_Y + y)*40 + CANVAS_X + x] = CANVAS_PIXEL_ON then
        byteValue := byteValue OR (1 shl (7-(i mod 8)));
      if (i mod 8) = 7 then
      begin
        input[i DIV 8] := byteValue;
        byteValue := 0;
      end;
    end;
end;

procedure DrawHiddenActivations();
(*
* @description:
* Draws activation values of hidden layer as a PETSCII histogram.
*) 
var 
  i: byte;
  bakColor: byte;
begin
  bakColor := currentColor;
  gotoxy(20,3); currentColor := LIGHT_GREEN;
  for i:=0 to high(activationsHidden) do
    write(ACTIVATION_HISTOGRAM_LEVELS[round(activationsHidden[i]*8)]);
  currentColor := bakColor;
end;

procedure DrawOutputActivations();
(*
* @description:
* Draws activation values of output layer as a PETSCII histogram.
*) 
var 
  i: byte;
  bakColor: byte;
begin
  bakColor := currentColor;
  gotoxy(20,5); currentColor := 13;
  for i:=0 to high(activationsOutput) do
    write(ACTIVATION_HISTOGRAM_LEVELS[round(activationsOutput[i]*8)]);
  currentColor := bakColor;
end;

procedure DisplayChar(digit: byte);
(*
* @description:
* Renders a digit on the canvas using system font.
*
* @Param: (byte) digit - The digit to be displayed
*) 
begin
  ClearScreenArea(1, 1, 16, 16);
  CIACRA := CIACRA AND $FE; // Disable interrupt
  R6510 := R6510 AND $FB; // Enable Charset rom
  // Now read digit char bytes
  for row := 0 to 7 do
    chardata[row] := Peek($D000 + (48 + digit) * 8 + row);
  R6510 := R6510 OR $04;  // Disable charset rom
  CIACRA := CIACRA OR $01; // Re-enable interrupt
  
  // Character data is  
  for row := 0 to 7 do
    for bit := 0 to 7 do
      if chardata[row] AND (1 shl (7 - bit)) > 0 then
      begin
        screenRam[(CANVAS_Y + row * 2) * 40 + (CANVAS_X + bit * 2)] := CANVAS_PIXEL_ON;
        screenRam[(CANVAS_Y + (row * 2) + 1) * 40 + (CANVAS_X + bit * 2)] := CANVAS_PIXEL_ON;
        screenRam[(CANVAS_Y + row * 2) * 40 + (CANVAS_X + (bit * 2) + 1)] := CANVAS_PIXEL_ON;
        screenRam[(CANVAS_Y + (row * 2) + 1) * 40 + (CANVAS_X + (bit*2)+1)] := CANVAS_PIXEL_ON;
      end;
end;

procedure DrawAndPredict();
(*
* @description:
* Lets the user draw a digit (I hope) and tries to recognize it.
*)
var
  c, guessedDigit: byte;
  done, isNumber: boolean;
begin
  done := false; // Local variables values apparently are kept between calls, so here is an explicit assignment
  ClearScreenArea(1, 1, 16, 16);
  EnableCursor();
  repeat
    if inputMode = INPUT_JOYSTICK then
    begin
      ReadJoystick2();
      moveCursor(cursorX+inputDx, cursorY+inputDy);
      togglePixel(buttonPressed);
    end
    else if inputMode = INPUT_LIGHTPEN then
    begin
      oldCursorX := cursorX;
      oldCursorY := cursorY;
      CheckPen();
      cursorX := PenCharX-CANVAS_X;
      cursorY := PenCharY-CANVAS_Y;
      moveCursor(cursorX, cursorY);
      cursorMoved := (cursorX <> oldCursorX) OR (cursorY <> oldCursorY);
      togglePixel(cursorMoved);
    end;
    if KeyPressed then
    begin
      c := ord(ReadKey());
      case c of
      165: begin; inputMode := INPUT_JOYSTICK; Log('Input mode: Joystick'); end;
      169: begin; inputMode := INPUT_LIGHTPEN; Log('Input mode: Light pen'); end;
      167: done := Confirm('Exit drawing? (Y/N)');
      end;
    end;
    Pause(5); // Loop is too fast, added delay 
  until done;
  DisableCursor();
  CanvasToInput(currInput);
  DrawDigit(currInput);
  guessedDigit := Predict(currInput);
  DrawHiddenActivations();
  DrawOutputActivations();
  DisplayChar(guessedDigit);
  Log(strCat('I think you wrote a ', ByteToStr(guessedDigit)));
  if not Confirm('Am I right? (Y/N)') then
  begin
    repeat
    Log('Enter the correct digit:');
    repeat until KeyPressed;
    guessedDigit := StrToInt(ReadKey());
    isNumber := (guessedDigit > 0) AND (guessedDigit < 9);
    until isNumber;
  end;
  Log('Adjusting weights...');
  Train(currInput, guessedDigit);
end;

procedure TrainLoop(epochs: byte);
(*
* @description:
* Main Training loop.
*
* @param: (byte) epochs - How many times (epochs) our network must be trained with a complete set of data.
*)
var
  processed, total: word;
  stop: boolean;

begin
  Log('It will take a lot of time');
  Log('Make a cup of tea');
  Log('Put a record on');
  InitNetwork();
  total := epochs * 1593;
  for epoch := 0 to epochs-1 do
  begin
    if stop then break;
    ShuffleBatchIndexes();
    correct := 0; processed := 0; // Keep track of correct predictions, used to measure network accuracy
    for batchIdx in batchIndexes do
    begin
      if stop then break;
      batchName := strCat('NEURAL', IntToHex(batchIdx, 2));
      batchName := strCat(batchName, ',U,R');
      LoadTrainingBatch(batchName, DRIVE_NO, batch);

      // Actual training with batch data
      for j := 0 to batchLength-1 do
      begin
        if keypressed then
          stop := Confirm('Stop training? (Y/N)');
        if stop then break;

        for i := 0 to BATCH_ROW_LENGTH-2 do
          currInput[i] := batch[i, j];
        DrawDigit(currInput);
        Train(currInput, batch[BATCH_ROW_LENGTH-1, j]);
        Log(strCat('Records remaining:', IntToStr(total)));
        dec(total);
      end;

      // Check prediction accuracy against training data
      for j := 0 to batchLength-1 do
      begin
        if keypressed then
          stop := Confirm('Stop training? (Y/N)');
        if stop then break;
        for i := 0 to BATCH_ROW_LENGTH-2 do
          currInput[i] := batch[i, j];
        DrawDigit(currInput);
        predicted := Predict(currInput);
        DrawHiddenActivations();
        DrawOutputActivations();
        inc(processed);
        if batch[BATCH_ROW_LENGTH-1, j] = predicted then
          inc(correct);
        Log(strCat('Accuracy=', FloatToStr((correct/processed)*100)));
      end;
    end;
  end;
  if stop then Log('Training stopped');
  stop := false;
end;

procedure ScanKey();
(*
* @description:
* Main Menu actions.
*) 
var
  c: byte;
begin
    c := ord(ReadKey());
    case c of
      165:  begin // F1
              DisplayMenu(TRAINING_MENU);
              TrainLoop(2);
              DisplayMenu(MAIN_MENU);
            end;
      169:  if Confirm('Are you sure? (Y/N)') then // F2
            begin
              Log('Saving parameters...');
              SaveNetworkParameters(8);
              Log('...done');
            end;
      166:  if Confirm('Are you sure? (Y/N)') then // F3
            begin
              Log('Loading parameters...');
              LoadNetworkParameters(8);
              Log('...done');
            end;
      170: begin ClearScreenArea(1, 1, 16, 16); ClearDigit(); end;
      167: begin DisplayMenu(DRAWING_MENU); DrawAndPredict(); DisplayMenu(MAIN_MENU); end;// F5
      // 171: // F6 
      // 168: // F8
    end;
    KeyboardBufferLength := 0; // Resets buffer length to 0, same effect as emptying it
end;



begin
  c64Randomize();
  Init();
  DisplayMenu(MAIN_MENU);
  repeat // Main loop
    if KeyPressed then ScanKey();
  until false;
end.

