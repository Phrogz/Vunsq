function Vunsq( canvas ) {
	this.effects  = [];
	this.timeline = []; // Array of events indexed by strand
	this.activeInstances = [];
	if (canvas) this.displayOn(canvas);
}

Vunsq.BLEND_MODES = ["source-over", "source-in", "source-out", "source-atop", "destination-over", "destination-in", "destination-out", "destination-atop", "lighter", "copy", "xor", "multiply", "screen", "overlay", "darken", "lighten", "color-dodge", "color-burn", "hard-light", "soft-light", "difference", "exclusion", "hue", "saturation", "color", "luminosity"];
Vunsq.BLEND_MODES.forEach((s,i,a) => { a[s]=i });

Vunsq.prototype.loadJSONFile = function(jsonFile) {
	return this.loadJSON(require('fs').readFileSync(jsonFile));
};

Vunsq.prototype.loadJSON = function(json) {
	return this.loadFromObject(JSON.parse(json));
};

Vunsq.prototype.loadFromObject = function(object) {
	['bpm','media','patterns','timeline'].forEach( s => { if (object[s]) this[s]=object[s] } );
	this.patterns.forEach(pat => pat.events.forEach(setDefaults));
	this.timeline.forEach(setDefaults);
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
	let offset=0;

	// Header
	this.bpm = readFloat('bpm');
	let uriBytes = readChar('uriBytes');
	let media=Buffer.allocUnsafe(uriBytes);
	console.log('media is',media.length);
	buf.copy(media,0,5,uriBytes+5);
	this.media = media.toString('utf8');
	if (process.env.VUNSQDEBUG) {
		console.log('media buffer',media);
		console.log('@'+offset+' read media as',this.media);
	}
	offset += uriBytes;

	// Timeline header
	let strandCount = readChar('strandCount');
	for (let i=0;i<strandCount;++i) {
		readLong('Strand #'+i+" Offset");
		readShort('Strand #'+i+" Bytes");
	}

	// Timeline
	this.timeline = [];
	for (var idx=0;idx<strandCount;++idx) {
		this.timeline[idx] = Array.from({ length:readLong('Strand #'+idx+' eventCount') }, readEvent);
	}

	return this;

	function readEvent() {
		return {
			event: readChar('eventId'),
			start: readLong('eventStart'),
			speed: readFloat('eventSpeed'),
			args:  Array.from({length:readChar('eventArgCount')}, (_,i)=>readChar('arg#'+i) )
		};
	}

	function readChar(name) {
		const v = buf.readUInt8(offset++);
		if (process.env.VUNSQDEBUG) console.log('@'+(offset-1)+' char',name,v);
		return v;
	}

	function readShort(name) {
		const v = buf.readUInt16LE(offset); offset+=2;
		if (process.env.VUNSQDEBUG) console.log('@'+(offset-2)+' short',name,v);
		return v;
	}

	function readLong(name) {
		const v = buf.readUInt32LE(offset); offset+=4;
		if (process.env.VUNSQDEBUG) console.log('@'+(offset-4)+' long',name,v);
		return v;
	}

	function readFloat(name) {
		let v = buf.readFloatLE(offset); offset+=4;
		if (process.env.VUNSQDEBUG) console.log('@'+(offset-4)+' float',name,v);
		return v;
	}
};

Vunsq.prototype.displayOn = function(canvas) {
	this.can = canvas;
	this.ctx = canvas.getContext('2d');
	this.ctx.fillStyle = 'black';
	this.w = canvas.width;
	this.h = canvas.height;
	this.ctx.fillStyle = 'black';
	this.effects = [];
	this.timeline = [];
	this.tmpCanvas = document.createElement('canvas');
	this.tmpCanvas.width  = this.w;
	this.tmpCanvas.height = this.h;
	this.tmpCtx = this.tmpCanvas.getContext('2d');
	this.tmpData = this.tmpCtx.getImageData(0,0,this.w,this.h);
};

// Draw according to a particular time
Vunsq.prototype.update = function(t) {
	const me=this;
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
		delete me.nextInstIndex;
		if (startIndex!==undefined) {
			for (let i=startIndex;i<me.timeline.length;++i) {
				const inst = me.timeline[i];
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
			let ct = 0;
			me.activeInstances.forEach( (inst,_,a) => { if (inst.stop>t) a[ct++]=inst } );
			me.activeInstances.length = ct;
		}
	}
};

Vunsq.prototype.draw = function(t) {
	const me=this, bbox={}, d=this.tmpData.data;
	this.ctx.globalCompositeOperation = 'source-over';
	this.ctx.fillRect(0,0,this.w,this.h);
	this.activeInstances.forEach( inst => ('effect' in inst) ? drawEvent(inst,t) : drawPattern(inst) );

	function drawPattern(inst) {
		const pattern = me.patterns[inst.pattern];
		const patternTime = ((t-inst.start) % inst.length)*inst.speed;

		// TODO: figure out a more efficient way to keep track of a pattern's active list
		for (let i=0;i<pattern.events.length;++i) {
			const evt = pattern.events[i];
			if (evt.start<patternTime && evt.stop>patternTime) {
				drawEvent(evt, patternTime, inst.x, inst.y);
			}
		}
	}

	function drawEvent(evt, t, xOffset, yOffset) {
		if (xOffset===undefined) xOffset=0;
		if (yOffset===undefined) yOffset=0;

		const effect = me.effects[evt.effect];
		const effectTime = ((t-evt.start) % evt.length)*evt.speed;
		effect.bbox(effectTime, bbox);

		if (evt.x || xOffset) {
			bbox.x0 += evt.x + xOffset;
			bbox.x1 += evt.x + xOffset;
		}
		if (evt.y || yOffset) {
			bbox.y0 += evt.y + yOffset;
			bbox.y1 += evt.y + yOffset;
		}

		// Floor minimums && ceil maximums to integers (without function call)
		// TODO: if we require bbox to be integer values, me can be removed (now that we don't have 2D scale/rotate/matrix)
		let n;
		bbox.x0 = bbox.x0<0 ? (n=bbox.x0<<0, n==bbox.x0 ? n : n-1) : (bbox.x0<<0);
		bbox.y0 = bbox.y0<0 ? (n=bbox.y0<<0, n==bbox.y0 ? n : n-1) : (bbox.y0<<0);
		bbox.x1 = bbox.x1<0 ? (bbox.x1<<0) : (n=bbox.x1<<0, n==bbox.x1 ? n : n+1);
		bbox.y1 = bbox.y1<0 ? (bbox.y1<<0) : (n=bbox.y1<<0, n==bbox.y1 ? n : n+1);

		// Clamp values to within canvas
		if (bbox.x0<0) bbox.x0=0; else if (bbox.x0>=me.w) bbox.x0=me.w-1;
		if (bbox.x1<0) bbox.x1=0; else if (bbox.x1>=me.w) bbox.x1=me.w-1;
		if (bbox.y0<0) bbox.y0=0; else if (bbox.y0>=me.h) bbox.y0=me.h-1;
		if (bbox.y1<0) bbox.y1=0; else if (bbox.y1>=me.h) bbox.y1=me.h-1;

		bbox.w = bbox.x1-bbox.x0;
		bbox.h = bbox.y1-bbox.y0;

		for (let x=bbox.x0;x<=bbox.x1;++x) {
			for (let y=bbox.y0;y<=bbox.y1;++y) {
				// Start index for RGBA values in the data
				const offset = (y*me.w+x)*4;

				// set pixel fully transparent before calling the effect
				d[offset+3] = 0;

				effect(effectTime, x-evt.x-xOffset, y-evt.y-yOffset, d, offset, evt.args);
			}
		}

		me.tmpCtx.putImageData(me.tmpData,0,0,bbox.x0,bbox.y0,bbox.w,bbox.h);
		me.ctx.globalCompositeOperation = evt.blend;
		me.ctx.drawImage(me.tmpCanvas,bbox.x0,bbox.y0,bbox.w,bbox.h,bbox.x0,bbox.y0,bbox.w,bbox.h);
	}
};

Vunsq.prototype.go = function(fpsEl) {
	let me = this;
	if (fpsEl) {
		var msPerFrame=1000/60, lastUpdate=0;
		setInterval(function(){
			fpsEl.innerHTML = (1000/msPerFrame).toFixed(1)+' fps';
		},500);
	}
	crank(0);
	function crank(t){
		me.update(t);
		requestAnimationFrame(crank);
		if (fpsEl) {
			msPerFrame += (t-lastUpdate-msPerFrame)/8;
			lastUpdate = t;
		}
	}
};

v = new Vunsq;
v.loadBinaryFile('./test/simple.vunsq');
console.log(JSON.stringify(v));