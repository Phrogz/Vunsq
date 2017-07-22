#! /usr/bin/env ruby
# Encoding: utf-8

USAGE = <<-ENDUSAGE
Usage: json2bin infile.json [output.vunsq]
If no output is specified, infile.vunsq will be written.
ENDUSAGE

def run!
	require 'rationalist'
	args = Rationalist.parse(ARGV, alias:{h:'help'})
	if args[:help]
		puts USAGE
		exit
	end

	# Pop the argument off ARGV so ARGF does not try to read from the output
	output = args[:_].length==2 ? ARGV.pop : ARGF.filename.sub(/(?<=\.)[^.]+$/,'vunsq')

	json = ARGF.read
	binary = json2bin( json )

	if ARGF.filename == '-'
		print binary
	else
		puts "Converted #{json.length}-byte JSON to #{binary.length}-byte binary '#{output}'"
		File.open(output,'wb'){ |f| f.print(binary) }
	end
end

def json2bin(json)
	require 'json'
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
		[events.length].pack('n') << events.map{ |e| event2bin(e) }.compact.join
	end.join

	ins = instances.map do |pat_or_evt|
		pattern_id = pat_or_evt['pattern']
		if pattern_id
			pattern_index = pattern_index_by_id[pattern_id]
			next warn "Could not find pattern ##{pattern_id}; skipping" unless pattern_index
			[
				pattern_index,
				pat_or_evt['start']  || 0,
				pat_or_evt['length'] || 2**32-1,
				pat_or_evt['speed']  || 1.0,
				pat_or_evt['repeat'] || 0,
				pat_or_evt['x']      || 0,
				pat_or_evt['y']      || 0
			].pack('CN2gnC2')
		else
			event2bin(pat_or_evt)
		end
	end.compact.join
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
			arg==0 ? 0 : [arg].pack('N').unpack('C*').drop_while{ |i| i==0 }
		when Float
			[arg].pack('g').unpack('C*')
		end
	end
	effect_id = event['effect'] || 0
	return warn "Effect numbers must be between 0-127 (effect ##{effect_id}" if effect_id>=128
	[
		effect_id + 128,
		event['start']  || 0,
		event['length'] || 2**32-1,
		event['speed']  || 1.0,
		event['repeat'] || 0,
		event['x']      || 0,
		event['y']      || 0,
		Vunsq::BLEND_MODES[ (event['blend']  || 'source-over').downcase ],
		args.length,
		*args
	].pack('CN2gnC*')
end

module Vunsq
	BLEND_MODES = {}

	BLEND_MODES["source_over"] = BLEND_MODES["source-over"]           = 0
	BLEND_MODES["source_in"] = BLEND_MODES["source-in"]               = 1
	BLEND_MODES["source_out"] = BLEND_MODES["source-out"]             = 2
	BLEND_MODES["source_atop"] = BLEND_MODES["source-atop"]           = 3
	BLEND_MODES["destination_over"] = BLEND_MODES["destination-over"] = 4
	BLEND_MODES["destination_in"] = BLEND_MODES["destination-in"]     = 5
	BLEND_MODES["destination_out"] = BLEND_MODES["destination-out"]   = 6
	BLEND_MODES["destination_atop"] = BLEND_MODES["destination-atop"] = 7
	BLEND_MODES["lighter"]                                            = 8
	BLEND_MODES["copy"]                                               = 9
	BLEND_MODES["xor"]                                                = 10
	BLEND_MODES["multiply"]                                           = 11
	BLEND_MODES["screen"]                                             = 12
	BLEND_MODES["overlay"]                                            = 13
	BLEND_MODES["darken"]                                             = 14
	BLEND_MODES["lighten"]                                            = 15
	BLEND_MODES["color_dodge"] = BLEND_MODES["color-dodge"]           = 16
	BLEND_MODES["color_burn"] = BLEND_MODES["color-burn"]             = 17
	BLEND_MODES["hard_light"] = BLEND_MODES["hard-light"]             = 18
	BLEND_MODES["soft_light"] = BLEND_MODES["soft-light"]             = 19
	BLEND_MODES["difference"]                                         = 20
	BLEND_MODES["exclusion"]                                          = 21
	BLEND_MODES["hue"]                                                = 22
	BLEND_MODES["saturation"]                                         = 23
	BLEND_MODES["color"]                                              = 24
	BLEND_MODES["luminosity"]                                         = 25

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

run! if __FILE__==$0
