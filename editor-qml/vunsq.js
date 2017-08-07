function Vunsq( mainContext, tmpContext ) {
    this.tmpCtx = tmpContext;
    this.tmpData = tmpContext.getImageData();
	this.effects  = [];
	this.patterns = [];
	this.timeline = [];
	this.activeInstances = [];
    if (mainContext) this.displayOn(mainContext);
}

Vunsq.BLEND_MODES = ["source-over", "source-in", "source-out", "source-atop", "destination-over", "destination-in", "destination-out", "destination-atop", "lighter", "copy", "xor", "multiply", "screen", "overlay", "darken", "lighten", "color-dodge", "color-burn", "hard-light", "soft-light", "difference", "exclusion", "hue", "saturation", "color", "luminosity"];
Vunsq.BLEND_MODES.forEach(function(s,i,a){ a[s]=i });

Vunsq.prototype.loadJSONFile = function(jsonFile) {
	return this.loadJSON(require('fs').readFileSync(jsonFile));
};

Vunsq.prototype.loadJSON = function(json) {
	return this.loadFromObject(JSON.parse(json));
};

Vunsq.prototype.loadFromObject = function(object) {
    ['bpm','media','patterns','timeline'].forEach(function(s){ if (object[s]) this[s]=object[s] }, this);
    this.patterns.forEach(function(pat){ pat.events.forEach(setDefaults) });
	this.timeline.forEach(setDefaults);
	this.updateIndexes();
	return this;

	function setDefaults(inst) {
		if (!('pattern' in inst || 'effect' in inst)) inst.effect=0;
		if (!('start'   in inst)) inst.start = 0;
		if (!('length'  in inst)) inst.length = Number.MAX_SAFE_INTEGER;
		if (!('repeat'  in inst)) inst.repeat = 0;
		if (!('blend'   in inst)) inst.blend = 'source-over';
		if (!('speed'   in inst)) inst.speed = 1;
		if (!('x'       in inst)) inst.x = 0;
		if (!('y'       in inst)) inst.y = 0;
	}
};

Vunsq.prototype.effect = function(index,func) {
	this.effects[index] = func;
};

Vunsq.prototype.loadBinaryFile = function(vunsqFile) {
	return this.loadBinary(require('fs').readFileSync(vunsqFile));
};

Vunsq.prototype.loadBinary = function(buf) {
    var me = this;
    var offset=0;
	this.bpm = readFloat('bpm');

	offset=3;
	while (buf[++offset]);
    var media=Buffer.allocUnsafe(offset-4);
	buf.copy(media,0,4,offset);
	this.media = media.toString('utf8');

	offset++; // Skip over the null terminator for the string

    me.patterns = Array.from({ length:readChar('patternCt') }, function(_,i){ return {
		id: i,
		events: Array.from({ length:readShort('eventCt') }, readEventOrPattern )
    }} );

	me.timeline = Array.from({ length:readLong('instCt') }, readEventOrPattern);
	this.updateIndexes();

	return this;

	function readEventOrPattern() {
        var id = readChar('id');
        var obj = {
			start:  readLong('start'),
			length: readLong('length'),
			speed:  readFloat('speed'),
			repeat: readShort('repeat'),
			x:      readChar('x'),
			y:      readChar('y')
		};
		if (id<128) obj.pattern = id;
		else {
			obj.effect = id-128;
			obj.blend  = Vunsq.BLEND_MODES[readChar('blend')];
            obj.args   = Array.from({length:readChar('argCount')}, function(_,i){ return readChar('arg #'+i) });
		}
		return obj;
	}

	function readChar(name) {
        var v = buf.readUInt8(offset++);
		// console.log('char',name,v);
		return v;
	}

	function readShort(name) {
        var v = buf.readUInt16BE(offset); offset+=2;
		// console.log('short',name,v);
		return v;
	}

	function readLong(name) {
        var v = buf.readUInt32BE(offset); offset+=4;
		// console.log('long',name,v);
		return v;
	}

	function readFloat(name) {
        var v = buf.readFloatBE(offset); offset+=4;
		// console.log('float',name,v);
		return v;
	}
};

Vunsq.prototype.updateIndexes = function() {
    var patterns = this.patterns;

	// The length of a pattern is the end of the last event
    patterns.forEach(function(pat){
		pat.events.forEach(calculateStopTime);
        pat.length = Math.max.apply(Math,pat.events.map(function(i){ return i.stop}));
	});

	this.timeline.forEach(calculateStopTime);

	function calculateStopTime(inst) {
		if ('pattern' in inst) inst.length = patterns[inst.pattern].length;
		inst.stop = inst.start + inst.length*(inst.repeat+1);
	}
};

Vunsq.prototype.displayOn = function(context) {
    this.ctx = context;
	this.ctx.fillStyle = 'black';
    this.w = context.canvas.width;
    this.h = context.canvas.height;
	this.ctx.fillStyle = 'black';
	this.effects = [];
	this.timeline = [];
};

// Draw according to a particular time
Vunsq.prototype.update = function(t) {
    var me=this;
	if (!this.lastTime || t<this.lastTime) {
		this.activeInstances.length=0;
		updateActive(0);
	} else {
		updateActive(this.nextInstIndex);
	}
    this.lastTime = t;
	this.draw(t);
	return this;

	function updateActive(startIndex) {
        me.nextInstIndex = undefined;
        if (startIndex!==undefined) {
            for (var i=startIndex; i<me.timeline.length; ++i) {
                var inst = me.timeline[i];
                //console.log(i,t,inst.start,inst.start>t,inst.stop,inst.stop>t);
				if (inst.start>t) {
					me.nextInstIndex = i;
					break;
				} else if (inst.stop>t) {
					me.activeInstances.push(inst);
				}
			}
		}

		// Compact the active list
		if (me.activeInstances.length) {
            var ct = 0;
            me.activeInstances.forEach( function(inst,_,a){ if (inst.stop>t) a[ct++]=inst } );
			me.activeInstances.length = ct;
        }
    }
};

Vunsq.prototype.draw = function(t) {
    var me=this, bbox={x0:0,y0:0,x1:this.w,y1:this.h,w:this.w,h:this.h}, d=this.tmpData.data;
	this.ctx.globalCompositeOperation = 'source-over';
    this.ctx.fillStyle = 'black';
    this.ctx.fillRect(0,0,this.w,this.h);
    this.activeInstances.forEach( function(inst){
        if ('effect' in inst) drawEvent(inst,t);
        else                  drawPattern(inst)
    });

	function drawPattern(inst) {
        var pattern = me.patterns[inst.pattern];
        var patternTime = ((t-inst.start) % inst.length)*inst.speed;

		// TODO: figure out a more efficient way to keep track of a pattern's active list
        for (var i=0;i<pattern.events.length;++i) {
            var evt = pattern.events[i];
			if (evt.start<patternTime && evt.stop>patternTime) {
				drawEvent(evt, patternTime, inst.x, inst.y);
			}
		}
	}

	function drawEvent(evt, t, xOffset, yOffset) {
		if (xOffset===undefined) xOffset=0;
		if (yOffset===undefined) yOffset=0;

        var effect = me.effects[evt.effect];
        var effectTime = ((t-evt.start) % evt.length)*evt.speed;

        // FIXME: once https://bugreports.qt.io/browse/QTBUG-62346 is fixed, re-use bbox again
        // effect.bbox(effectTime, bbox);
        //
        // if (evt.x || xOffset) {
        //	bbox.x0 += evt.x + xOffset;
        //	bbox.x1 += evt.x + xOffset;
        // }
        // if (evt.y || yOffset) {
        // 	bbox.y0 += evt.y + yOffset;
        // 	bbox.y1 += evt.y + yOffset;
        // }
        //
		// Floor minimums && ceil maximums to integers (without function call)
		// TODO: if we require bbox to be integer values, me can be removed (now that we don't have 2D scale/rotate/matrix)
        // var n;
        // bbox.x0 = bbox.x0<0 ? (n=bbox.x0<<0, n===bbox.x0 ? n : n-1) : (bbox.x0<<0);
        // bbox.y0 = bbox.y0<0 ? (n=bbox.y0<<0, n===bbox.y0 ? n : n-1) : (bbox.y0<<0);
        // bbox.x1 = bbox.x1<0 ? (bbox.x1<<0) : (n=bbox.x1<<0, n===bbox.x1 ? n : n+1);
        // bbox.y1 = bbox.y1<0 ? (bbox.y1<<0) : (n=bbox.y1<<0, n===bbox.y1 ? n : n+1);
        //
		// Clamp values to within canvas
        // if (bbox.x0<0) bbox.x0=0; else if (bbox.x0>=me.w) bbox.x0=me.w-1;
        // if (bbox.x1<0) bbox.x1=0; else if (bbox.x1>=me.w) bbox.x1=me.w-1;
        // if (bbox.y0<0) bbox.y0=0; else if (bbox.y0>=me.h) bbox.y0=me.h-1;
        // if (bbox.y1<0) bbox.y1=0; else if (bbox.y1>=me.h) bbox.y1=me.h-1;
        //
        // bbox.w = bbox.x1-bbox.x0;
        // bbox.h = bbox.y1-bbox.y0;

        for (var x=bbox.x0;x<=bbox.x1;++x) {
            for (var y=bbox.y0;y<=bbox.y1;++y) {
				// Start index for RGBA values in the data
                var offset = (y*me.w+x)*4;

				// set pixel fully transparent before calling the effect
				d[offset+3] = 0;

                effect(effectTime, x-evt.x-xOffset, y-evt.y-yOffset, d, offset, evt.args);
			}
		}

        me.tmpCtx.putImageData(me.tmpData,0,0,bbox.x0,bbox.y0,bbox.w,bbox.h);
        me.ctx.globalCompositeOperation = evt.blend;
//        me.ctx.drawImage(me.tmpCtx.canvas,bbox.x0,bbox.y0,bbox.w,bbox.h,bbox.x0,bbox.y0,bbox.w,bbox.h);
        me.ctx.drawImage(me.tmpCtx.canvas,0,0);
    }
};

function rand(n) { return Math.random()*n << 0 }
