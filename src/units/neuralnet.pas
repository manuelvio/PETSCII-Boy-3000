unit neuralnet;
(*
* @type: unit
* @author: Manuel Vio <manuelvio74@gmail.com>
* @name: Platform agnostic backpropagation neural network implementation that recognizes hand written digits.
* @version: 0.1

* @description:
* A basic backpropagation neural network implementation written in Mad Pascal.
* It's optimized for digit recognizing purpose 
* Inpired from https://github.com/dlidstrom/NeuralNetworkInAllLangs
*
* 
*)
interface

const
  // Hyperparameters

  BATCH_ROW_COUNT_MAX = 100; // "Magic number" that evenly divides dataset
	BATCH_ROW_LENGTH = 33; // Record length = 16*2 (pixels) bytes + 1 (digit) byte

  // Every digit is drawn in a 16*16 pixel box, so our input layer is made of 256 sensors
  INPUT_LAYER_SIZE = 16*16; 
  
  HIDDEN_LAYER_SIZE = 14;

  // Every output neuron is a specific digit from 0 to 9
  OUTPUT_LAYER_SIZE = 10; 
  
  LEARNING_RATE: float = 0.5;

type
  // Every batch is kept in memory for performance reasons
  TBatch = array[0..BATCH_ROW_LENGTH-1, 0..BATCH_ROW_COUNT_MAX-1] of byte;
  
  // 32 bytes representing digit pixels, every bit is a specific pixel
  // We can cycle through pixels using the expression
  // input[i DIV 8] AND (1 shl (7-(i mod 8)))
  // where i is pixel index in loop from 0 to 255, starting from topmost left to bottom right pixel  
  TInput = array[0..BATCH_ROW_LENGTH-2] of byte;

var
  // Parameters

  // Hidden layer: weights, biases and activation values
  weightsHidden : array[0..(INPUT_LAYER_SIZE*HIDDEN_LAYER_SIZE)-1] of float;
  biasesHidden : array[0..HIDDEN_LAYER_SIZE-1] of float;
  activationsHidden : array[0..HIDDEN_LAYER_SIZE-1] of float;

  // Output layer: weights, biases and activation values
  weightsOutput : array[0..(HIDDEN_LAYER_SIZE*OUTPUT_LAYER_SIZE)-1] of float;
  biasesOutput : array[0..OUTPUT_LAYER_SIZE-1] of float;
  activationsOutput : array[0..OUTPUT_LAYER_SIZE-1] of float;

  // Gradients, array are actually static, so we can declare them here as well
  gradientsHidden : array[0..HIDDEN_LAYER_SIZE-1] of float;
  gradientsOutput : array[0..OUTPUT_LAYER_SIZE-1] of float;
  maxOutput: float;
  batchLength: byte;

function sigmoid(arg: float): float;
(*
* @description:
* Sigmoid activation function.
*)

function sigmoidPrim(arg: float): float;
(*
* @description:
* Sigmoid function derivative.
*)

procedure InitNetwork();
(*
* @description:
* Initializes network with random values.
*)

function Predict(var input: TInput): byte;
(*
* @description:
* Tries to recognize pixel sequence as a digit.
*
* @param: (TInput) input - The input pixel sequence.
*
* @returns: (byte) - The guessed digit (0-9).
*) 

procedure Train(var input: TInput; output: byte);
(*
* @description:
* Given a pixel sequence and the corresponding digit trains the network
* adjusting its parameters
*
* @param: (TInput) input - The input pixel sequence.
* @param: (byte) output - The actual digit.
*) 


implementation


function sigmoid(arg: float): float;
begin
  Result := 1.0 / (1.0 + exp(-arg))
end;

function sigmoidPrim(arg: float): float;
begin
  Result := arg * (1.0 - arg)
end;

// Note: RandomF returns a float in range 0-0.5 so we have to double it
procedure InitNetwork();
var i: word;
begin
  for i := 0 to (INPUT_LAYER_SIZE*HIDDEN_LAYER_SIZE)-1 do
    weightsHidden[i] := (RandomF()*2.0)-0.5;
  for i := 0 to HIDDEN_LAYER_SIZE-1 do
    biasesHidden[i] := 0.0;
  for i := 0 to (HIDDEN_LAYER_SIZE*OUTPUT_LAYER_SIZE)-1 do
    weightsOutput[i] := (RandomF()*2.0)-0.5;
  for i := 0 to OUTPUT_LAYER_SIZE-1 do
    biasesOutput[i] := 0.0;
end;

function Predict(var input: TInput): byte;
var
  i, h, o: byte;
  sumHidden: float;
  sumOutput: float;
  //maxOutput: float;

begin
  for h := 0 to HIDDEN_LAYER_SIZE-1 do
  begin
    sumHidden := 0.0;
    for i := 0 to INPUT_LAYER_SIZE-1 do
      if input[i DIV 8] AND (1 shl (7-(i mod 8))) > 0 then
        sumHidden := sumHidden + weightsHidden[i*HIDDEN_LAYER_SIZE + h];
    activationsHidden[h] := sigmoid(sumHidden + biasesHidden[h]);
  end;

  maxOutput := -1.0;
  for o := 0 to OUTPUT_LAYER_SIZE-1 do
  begin
    sumOutput := 0.0;
    
    for h := 0 to HIDDEN_LAYER_SIZE-1 do
      sumOutput := sumOutput + (activationsHidden[h] * weightsOutput[h*OUTPUT_LAYER_SIZE + o]);
    
    activationsOutput[o] := sigmoid(sumOutput + biasesOutput[o]);
    if activationsOutput[o] > maxOutput then
    begin
      Result := o;
      maxOutput := activationsOutput[o];
    end;
  end;
end;

procedure Train(var input: TInput; output: byte);
var 
  o, h, i: byte;
  outputBit: float;
  inputBit: float;
  gradientHiddenSum : float;
  predicted : byte;

begin
  predicted := Predict(input);
  for o := 0 to OUTPUT_LAYER_SIZE-1 do
  begin
    if o = output then
      outputBit := 1.0
    else
      outputBit := 0.0;
    gradientsOutput[o] := (activationsOutput[o] - outputBit) * sigmoidPrim(activationsOutput[o]);
  end;

  for h := 0 to HIDDEN_LAYER_SIZE-1 do
  begin
    gradientHiddenSum := 0.0;
    for o := 0 to OUTPUT_LAYER_SIZE-1 do
      gradientHiddenSum := gradientHiddenSum + gradientsOutput[o] * weightsOutput[h*OUTPUT_LAYER_SIZE + o];
    gradientsHidden[h] := gradientHiddenSum * sigmoidPrim(activationsHidden[h]);
  end;

  for h := 0 to HIDDEN_LAYER_SIZE-1 do
    for o := 0 to OUTPUT_LAYER_SIZE-1 do
      weightsOutput[h*OUTPUT_LAYER_SIZE + o] := weightsOutput[h*OUTPUT_LAYER_SIZE + o] - (LEARNING_RATE * gradientsOutput[o] * activationsHidden[h]); 

  for i := 0 to INPUT_LAYER_SIZE-1 do
  begin
    if input[i DIV 8] AND (1 shl (7-(i mod 8))) > 0 then
      inputBit := 1.0
    else
      inputBit := 0.0;

    for h := 0 to HIDDEN_LAYER_SIZE-1 do
      weightsHidden[i*HIDDEN_LAYER_SIZE + h] := weightsHidden[i*HIDDEN_LAYER_SIZE + h] - (LEARNING_RATE * gradientsHidden[h] * inputBit);
  end;

  for o := 0 to OUTPUT_LAYER_SIZE-1 do
    biasesOutput[o] := biasesOutput[o] - (LEARNING_RATE * gradientsOutput[o]);

  for h := 0 to HIDDEN_LAYER_SIZE-1 do
    biasesHidden[h] := biasesHidden[h] - (LEARNING_RATE * gradientsHidden[h]);
end;

end.
