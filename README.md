# Vunsq
Functional Video Sequencer

Like a mod-tracker, but:

* For timing and blending 2D video instead of sound, and
* Using generative, pixel-shading functions for the 'samples' instead of pre-recorded videos


# Core Concepts and Terminology

An **Effect** is a function like a pixel shader: it gets fed an x coordinate, a time, and (optionally) custom arguments, and it produces RGBA values for an entire light strand.
You can have a maximum of 128 different Effects.

An **Event** is an instance of an Effect. It specifies a time to start, a the strands it affects, and optional custom arguments.
Events reference Effects by numeric identifier.

<!--
A **Pattern** is a re-usable grouping of Events.
You can have a maximum of 128 defined Patterns in a **Pattern Library**.

An **Instance** is (surprise!) an instance of a pattern. Like an Event, it specifies a time to start and a strand offset.
-->

A **Presentation** is the entire ‘movie'. It specifies a BPM it is associated with, and an ideal reference song to play with it.
A Presentation has <!-- a Pattern Library and --> a **Timeline** that groups together all Events <!-- and Instances --> to display.
Presentations can be played by the runtime along with a different song at a different BPM, speeding them up or slowing them down.

_Note: Effects are code in the host runtime, and not stored within a Presentation._

# JSON Example

{
   "media" : "CHVRCHES-LeaveATrace.m4a",
   "bpm"   : 100.32,
   "timeline" : [
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[255,0,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[255,0,0] }],
      [{ "effect":2, "speed":2.5 }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[255,0,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":2, "speed":2.5 }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[255,0,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[255,0,0] }],
      [{ "effect":2, "speed":2.5 }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[255,0,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":0, "start":0 }, { "effect":1, "start":598, "args":[0,255,0] }],
      [{ "effect":2, "speed":2.5 }]
   ]
}

# Binary Format

All multi-byte numbers are stored in big-endian format.

## Presentation

 bytes | field
:-----:|-----------------------------------
   4   | Presentation BPM (float)
   ~   | Media URI (null terminated UTF-8)
   ~   | Timeline Index
   ~   | Timeline


<!--
## Pattern Library

 bytes | field
:-----:|-----------------------------------
   1   | Pattern Count (uint8; max:128)
   2   | Pattern 128 Event Count (uint16)
   ~   | Pattern 128 Event 1
   ~   | Pattern 128 Event 2
   ~   | Pattern 128 Event …
   2   | Pattern 129 Event Count (uint16)
   ~   | Pattern 129 Event 1
   ~   | Pattern 129 Event 2
   ~   | Pattern 129 Event …
   2   | Pattern … Event Count (uint16)
   ~   | Pattern … Event 1
   ~   | Pattern … Event 2
   ~   | Pattern … Event …
-->

## Timeline Index

 bytes | field
:-----:|-----------------------------------------
   1   | Strand Count                    (uint8)
   4   | Offset to Strand 1 Timeline     (uint32)
   2   | Byte count of Strand 1 Timeline (uint16)
   4   | Offset to Strand 2 Timeline     (uint32)
   2   | Byte count of Strand 2 Timeline (uint16)
   4   | Offset to Strand … Timeline     (uint32)
   2   | Byte count of Strand … Timeline (uint16)
   ~   | (repeat for all strands)


## Timeline

 bytes | field
:-----:|-----------------------------------
   4   | Strand 1 Event Count (uint32)
   ~   | Event 1
   ~   | Event 2
   ~   | Event …
   4   | Strand 2 Event Count (uint32)
   ~   | Event 1
   ~   | Event 2
   ~   | Event …
   4   | Strand … Event Count (uint32)
   ~   | Event 1
   ~   | Event 2
   ~   | Event …


## Event

 bytes | field
:-----:|-----------------------------------
   1   | Effect#    (uint8; 128-255 only)
   4   | Start      (uint32 ms)
   4   | Speed      (float)
   1   | Arg Count  (uint8)
   1   | Arg 1      (uint8)
   1   | Arg 2      (uint8)
   1   | Arg …      (uint8)

<!--
## Instance

 bytes | field
:-----:|-----------------------------------
   1   | Pattern# (uint8; 0-127 only)
   4   | Start    (uint32 ms)
   4   | Speed    (float)
-->