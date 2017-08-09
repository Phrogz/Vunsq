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

	header = [bpm,uri.bytesize,uri].pack('eCa*')

	timeline = (preso["timeline"]||[]).map.with_index do |evts,i|
		[
			evts.length,
			evts.map do |evt|
				args = (evt['args'] || []).flat_map do |arg|
					case arg
					when Integer
						if arg>=2**32
							warn "Clamping argument #{arg} to maximum value of #{2**32-1}"
							arg=2**32-1
						end
						arg==0 ? 0 : [arg].pack('V').unpack('C*').drop_while{ |i| i==0 }
					when Float
						[arg].pack('e').unpack('C*')
					end
				end
				[
					evt['effect'] || 0,
					evt['start']  || 0,
					(evt['speed'] || 1).to_f,
					args.length,
					*args
				].pack('CVeCC*')
			end.join
		].pack('Va*')
	end

	bytes   = timeline.map(&:length)
	timeline_index_length = 1 + 6*timeline.length
	offset  = header.length + timeline_index_length
	offsets = bytes.map{ |len| offset.tap{ offset+=len } }
	timeline_index = [
		timeline.length,
		offsets.zip(bytes).map{ |o,b| [o,b].pack('Vv') }.join
	].pack('Ca*')

	[header,timeline_index,timeline.join].join
end

run! if __FILE__==$0
