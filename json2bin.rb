#! /usr/bin/env ruby
# Encoding: utf-8

module Vunsq
	BLEND_MODES = {}

	BLEND_MODES["SOURCE_OVER"] = BLEND_MODES["SOURCE-OVER"] = BLEND_MODES["source_over"] = BLEND_MODES["source-over"]                     = 0
	BLEND_MODES["SOURCE_IN"] = BLEND_MODES["SOURCE-IN"] = BLEND_MODES["source_in"] = BLEND_MODES["source-in"]                             = 1
	BLEND_MODES["SOURCE_OUT"] = BLEND_MODES["SOURCE-OUT"] = BLEND_MODES["source_out"] = BLEND_MODES["source-out"]                         = 2
	BLEND_MODES["SOURCE_ATOP"] = BLEND_MODES["SOURCE-ATOP"] = BLEND_MODES["source_atop"] = BLEND_MODES["source-atop"]                     = 3
	BLEND_MODES["DESTINATION_OVER"] = BLEND_MODES["DESTINATION-OVER"] = BLEND_MODES["destination_over"] = BLEND_MODES["destination-over"] = 4
	BLEND_MODES["DESTINATION_IN"] = BLEND_MODES["DESTINATION-IN"] = BLEND_MODES["destination_in"] = BLEND_MODES["destination-in"]         = 5
	BLEND_MODES["DESTINATION_OUT"] = BLEND_MODES["DESTINATION-OUT"] = BLEND_MODES["destination_out"] = BLEND_MODES["destination-out"]     = 6
	BLEND_MODES["DESTINATION_ATOP"] = BLEND_MODES["DESTINATION-ATOP"] = BLEND_MODES["destination_atop"] = BLEND_MODES["destination-atop"] = 7
	BLEND_MODES["LIGHTER"] = BLEND_MODES["lighter"]                                                                                       = 8
	BLEND_MODES["COPY"] = BLEND_MODES["copy"]                                                                                             = 9
	BLEND_MODES["XOR"] = BLEND_MODES["xor"]                                                                                               = 10
	BLEND_MODES["MULTIPLY"] = BLEND_MODES["multiply"]                                                                                     = 11
	BLEND_MODES["SCREEN"] = BLEND_MODES["screen"]                                                                                         = 12
	BLEND_MODES["OVERLAY"] = BLEND_MODES["overlay"]                                                                                       = 13
	BLEND_MODES["DARKEN"] = BLEND_MODES["darken"]                                                                                         = 14
	BLEND_MODES["LIGHTEN"] = BLEND_MODES["lighten"]                                                                                       = 15
	BLEND_MODES["COLOR_DODGE"] = BLEND_MODES["COLOR-DODGE"] = BLEND_MODES["color_dodge"] = BLEND_MODES["color-dodge"]                     = 16
	BLEND_MODES["COLOR_BURN"] = BLEND_MODES["COLOR-BURN"] = BLEND_MODES["color_burn"] = BLEND_MODES["color-burn"]                         = 17
	BLEND_MODES["HARD_LIGHT"] = BLEND_MODES["HARD-LIGHT"] = BLEND_MODES["hard_light"] = BLEND_MODES["hard-light"]                         = 18
	BLEND_MODES["SOFT_LIGHT"] = BLEND_MODES["SOFT-LIGHT"] = BLEND_MODES["soft_light"] = BLEND_MODES["soft-light"]                         = 19
	BLEND_MODES["DIFFERENCE"] = BLEND_MODES["difference"]                                                                                 = 20
	BLEND_MODES["EXCLUSION"] = BLEND_MODES["exclusion"]                                                                                   = 21
	BLEND_MODES["HUE"] = BLEND_MODES["hue"]                                                                                               = 22
	BLEND_MODES["SATURATION"] = BLEND_MODES["saturation"]                                                                                 = 23
	BLEND_MODES["COLOR"] = BLEND_MODES["color"]                                                                                           = 24
	BLEND_MODES["LUMINOSITY"] = BLEND_MODES["luminosity"]                                                                                 = 25

	BLEND_MODES[0 ] = "source-over"
	BLEND_MODES[1 ] = "source-in"
	BLEND_MODES[2 ] = "source-out"
	BLEND_MODES[3 ] = "source-atop"
	BLEND_MODES[4 ] = "destination-over"
	BLEND_MODES[5 ] = "destination-in"
	BLEND_MODES[6 ] = "destination-out"
	BLEND_MODES[7 ] = "destination-atop"
	BLEND_MODES[8 ] = "lighter"
	BLEND_MODES[9 ] = "copy"
	BLEND_MODES[10] = "xor"
	BLEND_MODES[11] = "multiply"
	BLEND_MODES[12] = "screen"
	BLEND_MODES[13] = "overlay"
	BLEND_MODES[14] = "darken"
	BLEND_MODES[15] = "lighten"
	BLEND_MODES[16] = "color-dodge"
	BLEND_MODES[17] = "color-burn"
	BLEND_MODES[18] = "hard-light"
	BLEND_MODES[19] = "soft-light"
	BLEND_MODES[20] = "difference"
	BLEND_MODES[21] = "exclusion"
	BLEND_MODES[22] = "hue"
	BLEND_MODES[23] = "saturation"
	BLEND_MODES[24] = "color"
	BLEND_MODES[25] = "luminosity"
end

require 'json'
def run!
	json = (ARGF.filename=="-" ? DATA : ARGF).read
	binary = json2bin( json )
	p binary.length, json.length, binary
end

def json2bin(json)
	preso = JSON.load(json)
	bpm = (preso["bpm"] || 0).to_f
	uri = (preso["media"] || "")

	instances = preso["instances"] || []

	pattern_index_by_id = {}
	patterns = preso["patterns"] || []
	if patterns.length>128
		warn "Only emitting the first 128 (out of #{patterns.length}) patterns"
		patterns.slice!(128..-1)
	end

	lib = patterns.map.with_index do |pattern,i|
		pattern_index_by_id[pattern["id"]] = i
		events = pattern["events"] || []
		[events.length].pack('v') << events.map{ |e| event2bin(e) }.join
	end.join

	ins = instances.map do |pat_or_evt|
		if pat_or_evt['pattern']
			[
				pattern_index_by_id[pat_or_evt['pattern']]+128,
				pat_or_evt['start']  || 0,
				pat_or_evt['length'] || 2**32-1,
				pat_or_evt['speed']  || 1.0,
				pat_or_evt['repeat'] || 0,
				pat_or_evt['x']      || 0,
				pat_or_evt['y']      || 0
			].pack('CN3nC2')
		else
			event2bin(pat_or_evt)
		end
	end.join
	[bpm,uri,patterns.length,lib,instances.length,ins].pack('ga*xCa*Na*')
end

def event2bin(event)
	args = (event['args'] || []).flat_map do |arg|
		case arg
		when Integer
			if arg>=2**32
				warn "Clamping argument #{arg} to maximum value of #{2**32-1}"
				arg=2**32-1
			end
			if arg==0
				0
			else
				[arg].pack('N').unpack('C*').drop_while{ |i| i==0 }
			end
		when Float
			[arg].pack('g').unpack('C*')
		end
	end
	[
		event['effect'],
		event['start']  || 0,
		event['length'] || 2**32-1,
		event['speed']  || 1.0,
		event['repeat'] || 0,
		event['x']      || 0,
		event['y']      || 0,
		Vunsq::BLEND_MODES[ event['blend']  || 'source-over' ],
		args.length,
		*args
	].pack('CN3nC*')
end

run! if __FILE__==$0
__END__
{
	"media" : "CHVRCHES-LeaveATrace.m4a",
	"bpm"   : 100.32,
	"patterns" : [
		{"id":0, "events":[
			{ "effect":0, "start":0, "length":592, "repeat":3, "blend":"screen", "args":[255,128,0] },
			{ "effect":1, "length":592 }
		] },
		{"id":17, "events":[
			{ "effect":0, "start":0, "length":592, "repeat":3, "blend":"screen", "args":[4.1342] },
			{ "effect":0, "start":0, "length":592, "args":[256,65535,65536,16777215,16777216,4294967295] }
		] }
	],
	"instances" : [
		{ "pattern":17, "start":0, "length":1000, "repeat":7, "x":3, "y":10 },
		{ "effect":0, "start":16777216, "length":65536, "repeat":3, "blend":"source-over" },
		{ "effect":14, "start":1, "length":2, "speed":3.0, "repeat":4, "x":5, "y":6, "blend":"destination-atop" }
	]
}
