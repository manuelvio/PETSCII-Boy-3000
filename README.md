# PETSCII-Boy 3000

A neural network powered digit recognizer, written in Mad Pascal, runs on a Commodore 64

![Screenshot](https://github.com/user-attachments/assets/f23929d9-49ab-4de1-a8b4-bb5a7a51d05f)

## Introduction

The aim of this project is training and running a neural network in order to recognize handwritten digits. This is a very common and introductory task in neural network literature and it can be easily completed using modern languages and systems, but can become a challenge when implemented in a '80s machine.

It also tries to be as clear and as straightforward as possible in order to be understood by a neophyte (as I am).

The core functions (train and predict) are translated from https://github.com/dlidstrom/NeuralNetworkInAllLangs C# implementation, while some utility units are inspired from the https://github.com/KarolS/millfork counterpart.

## Why Pascal?

The first development iteration was meant to obtain a working predict function with common data structures, hence using floating point math was mandatory at that stage. A prototype was first written in BASIC, but due to its slowness it was soon ditched.

Turns out that there aren't many other Commodore 64 compatible languages out there with native floating point support, except for https://github.com/tebe6502/Mad-Pascal.

## Training data

The dataset used for training is a compressed version of the one available at https://archive.ics.uci.edu/dataset/178/semeion+handwritten+digit. The original file structure contained 1593 rows of 256 + 10 values: each row represented a handwritten digit in a 16x16 pixel matrix, where every pixel could be either on or off. In the dataset the two states were written as a 1.0 or a 0.0 respectively.

The remaining ten values (either 1 or 0) described the represented digit: a 1 in the fourth position meant that the row was representing a 5, and so on.