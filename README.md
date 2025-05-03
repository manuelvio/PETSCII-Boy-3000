# PETSCII-Boy 3000

A neural network powered digit recognizer, written in Mad Pascal, runs on a Commodore 64

![Screenshot](https://github.com/user-attachments/assets/f23929d9-49ab-4de1-a8b4-bb5a7a51d05f)

## Introduction

The aim of this project is training and running a neural network in order to recognize handwritten digits. This is a very common and introductory task in neural network literature and it can be easily completed using modern languages and systems, but can become a challenge when implemented in a '80s machine.

It also tries to be as clear and as straightforward as possible in order to be understood by a neophyte (as I am).

The core functions (train and predict) are translated from https://github.com/dlidstrom/NeuralNetworkInAllLangs C# implementation, while some utility units are inspired from the https://github.com/KarolS/millfork counterpart.

## Why Pascal?

The first development iteration was meant to obtain a working predict function with common data structures, hence using floating point math was mandatory at that stage. A prototype was first written in BASIC, but due to its slowness it was soon ditched.

Turns out that there aren't many other Commodore 64 compatible languages out there with native floating point support, except https://github.com/tebe6502/Mad-Pascal.
