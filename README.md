# Vunsq
Functional Video Sequencer

Like a mod-tracker, but:

* For timing and blending 2D video instead of sound, and
* Using generative, pixel-shading functions for the 'samples' instead of pre-recorded videos

# Effects

Effects are like pixel shaders: they are functions that are given a 2D position and a time value, and produce an RGBA value for a specific pixel. Note that the 2D position fed to the effect is only the same as the actual pixel location when there is no 2D transform applied.

Effects can also be parameterized by custom values per event. For example, you could create an effect where the color of the effect is modified by each event triggering the effect.

Effects must be associated with an effect id:

```js
var video = new Vunsq(myCanvas);
vid.effect(0,fallingStripe);

function fallingStripe(t,x,y,data,offset,arg) {
	// ...
	data[offset+0] = red;     // 0-255
	data[offset+1] = green;   // 0-255
	data[offset+2] = blue;    // 0-255
	data[offset+3] = opacity; // 0-255 (0 is fully transparent)
}
```

The opacity of each pixel is set to fully transparent before calling the effect. If the effect should not modify a pixel for a particular t/x/y combination, it can simply return.


## Bounding Box

Because an effect can touch every pixel, but often do not, performance limitations dictate that we need to know which pixels to affect with an effect. Thus, each effect function needs to be paired with another function that is fed the time and a bounding box and sets the four corners of the boundary it will play within.

We do this by adding a custom `bbox` property to the effect function. This function will receive a time value and an object which must have its `x0`/`y0` (minimum) and `x1`/`y1` (maximum) properties set. For example:

```js
function fallingStripe(t,x,y,data,offset) {
	if (x>=1 || x<0) return;
	var limit = Math.round(t/10);
	if (y<=limit) {
		data[offset+0] = 255;
		data[offset+1] = 255;
		data[offset+2] = 255;
		data[offset+3] = 255 - (limit-y)*10;
	}
}
fallingStripe.bbox = function(t,bbox) {
	var limit = Math.round(t/10);
	bbox.x0 = 0;
	bbox.x1 = 1;
	bbox.y0 = limit-25;
	bbox.y1 = limit+1;
}
```

# Events

Events are instances of an effect that are triggered at a particular time. The only thing an event *must* specify is the index of the effect to use.

```js
var video = new Vunsq(myCanvas);
vid.add({ effect:0 });
```

Events may optionally also specify:

* `start`: The time (in milliseconds) to start showing the effect. This is subtracted from the time supplied to the effect; each time an event starts, the effect sees a time value of `0`. The default value for this is `0`, i.e. the event starts immediately.
* `stop`: The time (in milliseconds) to stop showing the effect. The default value for this is `Infinity`, i.e. show the event indefinitely.
* `layer`: The over/under order in which to apply the event relative to other events. Layers with higher numbers draw on top of lower-numbered layers.
* `blend`: One of the supported [compositing blend modes](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation), as a string (e.g. `"screen"`). The default for each event is `"source-over"`.
* `x`, `y`: An offset amount for the effect. Positive values shift the event right and down from the upper left corner.
* `rotate`: A 2D rotation to apply to the effect, in degrees counter-clockwise.
* `scale`, `scaleX`, `scaleY`: Uniform or non-uniform 2D scaling applied to the effect.
* `matrix`: An array of 6 values to treat as a 2×3 transformation matrix. Takes precedence over other transformation values.
* `speed`: A multiplier applied to the time value supplied to the effect.
* `arg`: An arbitrary value to pass to the effect as the sixth parameter.
* `repeat`: Number of times to repeat the effect, resetting the time. _(Not currently supported.)_

# JSON Format Example

~~~json
{
	"media" : "CHVRCHES-LeaveATrace.m4a",
	"bpm"   : 100.32,
	"patterns" : [
		{"id":0, "events":[
			{ "effect":0, "start":0, "length":592, "repeat":3, "blend":"screen", "args":[255,128,0] },
			{ "effect":1, "length":592 }
		] },
		{"id":1, "events":[
			{ "effect":0, "start":0, "length":592, "repeat":3, "blend":"screen", "args":[4.1342] },
			{ "effect":0, "start":0, "length":592, "args":[256,65535,65536,16777215,16777216,4294967295] }
		] },
	],
	"instances" : [
		{ "pattern":0, "start":0, "length":1000, "repeat":7, "x":3, "y":10 },
		{ "effect":0, "start":16777216, "length":65536, "repeat":3, "blend":"source-over" }
	]
}
~~~

# Binary Format

All multi-byte numbers are stored in big-endian format.

## Presentation

 bytes | field
-------|-----------------------------------
   4   | Presentation BPM (float)
   ~   | Media URI (null terminated UTF-8)
   ~   | Pattern Library
   4   | Effect/Pattern Instance Count (uint32)
   ~   | Effect/Pattern Instance 1
   ~   | Effect/Pattern Instance 2
   ~   | Effect/Pattern Instance …


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


## Event

 bytes | field
:-----:|-----------------------------------
   1   | Effect#    (uint8; 128-255 only)
   4   | Start      (uint32 ms)
   4   | Length     (uint32 ms)
   4   | Speed      (float)
   2   | Repeat     (uint16)
   1   | Xoffset    (uint8)
   1   | Yoffset    (uint8)
   1   | Blend Mode (uint8)
   1   | Arg Count  (uint8)
   1   | Arg 1      (uint8)
   1   | Arg 2      (uint8)
   1   | Arg …      (uint8)


## Pattern Instance

 bytes | field
:-----:|-----------------------------------
   1   | Pattern# (uint8; 0-127 only)
   4   | Start    (uint32 ms)
   4   | Length   (uint32 ms)
   4   | Speed    (float)
   2   | Repeat   (uint16)
   1   | Xoffset  (uint8)
   1   | Yoffset  (uint8)


# Known Limitations (aka TODO)

* Tests (made with Engineering Art) show that many effects pre-compute some variables that are based solely on the time value. The same code is run, with the same result, for every pixel at a given time value. It would be nice to allow effects to run this compute during the `bbox` function and then return some data that will be passed along to the effect each time it is called.
