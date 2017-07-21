function Vunsq() {
	
}

Vunsq.prototype.loadFile = function(vunsqFile) {
	return this.load(require('fs').readFileSync(vunsqFile));
};

Vunsq.prototype.load = function(buf) {
	const me = this;
	let offset=0;
	this.bpm = readFloat();

	offset=3;
	while (buf[++offset]);
	let media=Buffer.allocUnsafe(offset-4);
	buf.copy(media,0,4,offset);
	this.media = media.toString('utf8');

	offset++; // Skip over the null terminator for the string

	readPatterns();
	readInstances();

	return this;

	function readPatterns() {
		const patternCount = readChar();
		assert(patternCount <= 128);
		me.patterns = [];
		for (let i=0; i<patternCount; ++i) {
			const pattern = { id:i, events:[] }
			const eventCount = readShort();
			console.log('pattern',i,eventCount);
			for (let j=0; j<eventCount; ++j) {
				pattern.events.push(readEvent());
			}
			me.patterns.push(pattern);
		}
	}

	function readInstances() {

	}

	function readEvent() {
		return {
			effect: readChar()-128,
			start:  readLong(),
			length: readLong(),
			speed:  readFloat(),
			repeat: readShort(),
			x:      readChar(),
			y:      readChar(),
			blend:  readChar(),
			args:   new Array(readChar()).map(readChar)
		};
	}

	function readChar() {
		const v = buf.readUInt8(offset++);
		console.log('char',v);
		return v;
	}

	function readShort() {
		const v = buf.readUInt16BE(offset); offset+=2;
		console.log('short',v)
		return v;
	}

	function readLong() {
		const v = buf.readUInt32BE(offset); offset+=4;
		console.log('long',v);
		return v;
	}


	function readFloat() {
		const v = buf.readFloatBE(offset); offset+=4;
		console.log('float',v);
		return v;
	}

	function assert(cond,message) {
		if (!cond) throw message;
	}

};

v = new Vunsq().loadFile('test/simple.vunsq');
console.log(v.patterns)