function Vunsq(mainContext, tmpContext) {
    this.tmpCtx = tmpContext;
    this.tmpData = tmpContext.getImageData();
	this.effects  = [];
	this.timeline = [];
    this.displayOn(mainContext);
}

Vunsq.prototype.toJSON = function() {
    return JSON.stringify({
        bpm:this.bpm,
        length:this.length,
        media:this.media,
        timeline:this.timeline
    });
};

Vunsq.prototype.loadJSONFile = function(jsonFile) {
	return this.loadJSON(require('fs').readFileSync(jsonFile));
};

Vunsq.prototype.loadJSON = function(json) {
	return this.loadFromObject(JSON.parse(json));
};

Vunsq.prototype.loadFromObject = function(object) {
    ['bpm','length','media','timeline'].forEach(function(s){ if (object[s]) this[s]=object[s] }, this);
    this.timeline.forEach(function(evts){ evts.forEach(setDefaults) });
	return this;

	function setDefaults(inst) {
		if (!('pattern' in inst || 'effect' in inst)) inst.effect=0;
		if (!('start'   in inst)) inst.start = 0;
		if (!('speed'   in inst)) inst.speed = 1;
	}
};

Vunsq.prototype.effect = function(funcData) {
    funcData._code = funcData.code;
    Object.defineProperty(funcData, 'code', {
        get:function(){ return funcData._code },
        set:function(newCode){
            try {
                funcData.ƒ = new Function('effectTime', 'strandIndex', 'strandLength', 'bpm', 'data', 'args', newCode);
                funcData._code = newCode;
            } catch(e) {}
        }
    });
    funcData.code = funcData.code;
    this.effects[funcData.index] = funcData;
};

Vunsq.prototype.loadBinaryFile = function(vunsqFile) {
	return this.loadBinary(require('fs').readFileSync(vunsqFile));
};

Vunsq.prototype.loadBinary = function(buf) {
	var me = this;
	var offset=0;
	this.bpm = readFloat('bpm');

	offset=3;
	while (buf[++offset]); // Loop until we hit a null value
	var media=Buffer.allocUnsafe(offset-4);
	buf.copy(media,0,4,offset);
	this.media = media.toString('utf8');

	offset++; // Skip over the null terminator for the string

	me.timeline = [];
	while (offset<buf.length) {
		var idx = readChar('strandIndex');
		me.timeline[idx] = Array.from({ length:readLong('eventCount') }, readEvent);
	}
	return this;

	function readEvent() {
		return {
			event: readChar('eventId'),
			start: readLong('eventStart'),
			speed: readFloat('eventSpeed'),
            args:  Array.from({length:readChar('eventArgCount')}, function(_,i){ return readChar('arg#'+i) } )
		};
	}

	function readChar(name) {
		var v = buf.readUInt8(offset++);
		if (process.env.VUNSQDEBUG) console.log('char',name,v);
		return v;
	}

	function readShort(name) {
		var v = buf.readUInt16BE(offset); offset+=2;
		if (process.env.VUNSQDEBUG) console.log('short',name,v);
		return v;
	}

	function readLong(name) {
		var v = buf.readUInt32BE(offset); offset+=4;
		if (process.env.VUNSQDEBUG) console.log('long',name,v);
		return v;
	}

	function readFloat(name) {
		var v = buf.readFloatBE(offset); offset+=4;
		if (process.env.VUNSQDEBUG) console.log('float',name,v);
		return v;
	}
};

Vunsq.prototype.resetPlayback = function() {
    this.nextEventIndex = this.timeline.map(function(){ return 0 });
};

Vunsq.prototype.displayOn = function(context) {
    this.ctx = context;
	this.ctx.fillStyle = 'black';
    this.w = context.canvas.width;
    this.h = context.canvas.height;
};

// Draw according to a particular time
Vunsq.prototype.update = function(t) {
    this.ctx.fillRect(0,0,this.w,this.h);
    var data = this.tmpData.data;

    if (this.lastTime===undefined || t<this.lastTime)
        this.nextEventIndex = this.timeline.map(function(){ return 0 });

    this.timeline.forEach(function(strandEvents,strandIndex){
        var nextEvent = strandEvents[this.nextEventIndex[strandIndex]];
        while (nextEvent && nextEvent.start<=t) nextEvent = strandEvents[++this.nextEventIndex[strandIndex]];
        var evt = strandEvents[this.nextEventIndex[strandIndex]-1];
        if (evt && evt.effect && this.effects[evt.effect] && this.effects[evt.effect].ƒ) {
            var effect = this.effects[evt.effect];
            var effectTime = (t-evt.start)*evt.speed;

            // Make all pixels transparent
            for (var y=this.h;y--;) data[y*4+3] = 0;

            effect.ƒ(effectTime, strandIndex, this.h, this.bpm, data, evt.args);

            // Copy result from temporary context to correct row in main context
            this.tmpCtx.putImageData(this.tmpData,0,0);
            this.ctx.drawImage(this.tmpCtx.canvas,strandIndex,0);
        }
    }.bind(this));

    this.lastTime = t;
	return this;
};

function rand(n) { return Math.random()*n << 0 }
