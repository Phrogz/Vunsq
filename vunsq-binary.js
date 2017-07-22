#!/usr/bin/env node

function Vunsq() {

}

Vunsq.prototype.loadFile = function(vunsqFile) {
	return this.load(require('fs').readFileSync(vunsqFile));
};

Vunsq.prototype.load = function(buf) {
	const me = this;
	let offset=0;
	this.bpm = readFloat('bpm');

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
		const patternCount = readChar('pattern count');
		assert(patternCount <= 128);
		me.patterns = Array.from({ length:patternCount }, (_,i) => ({
			id: i,
			events: Array.from({ length:readShort('pat #'+i+' evtCt') }, readEventOrPattern )
		}) );
	}

	function readInstances() {
		me.instances = Array.from({ length:readLong('instance count') }, readEventOrPattern);
	}

	function readEventOrPattern() {
		const id = readChar('id');
		const obj = {
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
			obj.blend  = readChar('blend');
			obj.args   = Array.from({length:readChar('argCount')}, (_,i)=>readChar('arg #'+i) );
		}
		return obj;
	}

	function readChar(name) {
		const v = buf.readUInt8(offset++);
		// console.log('char',name,v);
		return v;
	}

	function readShort(name) {
		const v = buf.readUInt16BE(offset); offset+=2;
		// console.log('short',name,v);
		return v;
	}

	function readLong(name) {
		const v = buf.readUInt32BE(offset); offset+=4;
		// console.log('long',name,v);
		return v;
	}


	function readFloat(name) {
		let v = buf.readFloatBE(offset); offset+=4;
		// console.log('float',name,v);
		return v;
	}

	function assert(cond,message) {
		if (!cond) throw message;
	}

};

v = new Vunsq().loadFile('test/simple.vunsq');
console.log(JSON.stringify(v))