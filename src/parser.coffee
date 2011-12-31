
Array::contains = (x) -> (@indexOf x) != -1

class self.Parser
	objectify: (pairs) ->
		hash = {}
		for [key, value] in pairs
			if @multiple.contains key
				if key not of hash
					hash[key] = []
				hash[key].push value
			else
				hash[key] = value
		hash

	multiple: ['light', 'item', 'group']
	convert:
		[{ # Color
			func: (input) -> input[0].match(/(..)/g).map (hex) -> (parseInt hex, 16) / 255
			fields: ['color', 'color2', 'l_color', 'tex_color_cut']
		}, { # String
			func: (input) -> input[0]
			fields: ['tex', 'type']
		}, { # Number
			func: (input) -> +input[0]
			fields: ['radius', 'width', 'height', 'checkerboard', 'distscreen', 'brightness',
			'group_id', 'id', 'max_reflect', 'tex_rep', 'tex_coef', 'size_mul', 'reflect',
			'l_intensity', 'pnoise', 'pnoise_octave', 'pnoise_freq', 'pnoise_pers', 'bump', 'opacity']
		}, { # Array of Number
			func: (input) -> input.map (x) -> +x
			fields: ['highdef', 'coords', 'limits', 'rot']
		}]

	constructor: (str) ->
		@lines = str
			.replace(/\#[^\n]*/g, '')
			.replace(/\{/g, '\n{')
			.split('\n')
			.map((line) -> line.trim())
			.filter((line) -> line)

	parse: ->
		@objectify(while block = @parseBlock()
			block
		)

	parseBlock: ->
		name = @lines.shift()
		return if not name
		@lines.shift() # {
		params = @objectify(while line = @lines.shift()
			break if line == '}'
			[key, values...] = line.split /\s+/
			for convert in @convert
				if convert.fields.contains key
					values = convert.func values
			[key, values]
		)
		[name, params]
