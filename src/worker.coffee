
importScripts('glmatrix.js', 'parser.js', 'ray.js', 'perlin.js');

log = (x...) -> postMessage ['log', x...]
copy = (obj) ->
	if Array.isArray obj
		obj.slice()
	else if obj instanceof Object and not (obj instanceof Function)
		new_obj = {}
		for key, val of obj
			new_obj[key] = copy val
		new_obj
	else
		obj

scene = null
textures = {}
textures_remaining = 0

@onmessage = (data: [type, value]) ->
	if type == 'process'
		{input} = value
		self.scene = scene = new Parser(input).parse()

		scene.global.highdef ?= []
		scene.global.highdef[0] ?= 1 # upscale
		scene.global.highdef[1] ?= 0 # randomRays
		[scene.global.upscale, scene.global.randomRays] = scene.global.highdef
		scene.global.distscreen ?= 1000
		scene.global.max_reflect ?= 10
		scene.global.l_color ?= [0, 0, 0]
		scene.global.l_intensity = (scene.global.l_intensity ? 0) / 100
		vec3.scale scene.global.l_color, scene.global.l_intensity
		scene.eye.rot = vec3.scale (scene.eye.rot ? [0, 0, 0]), Math.PI / 180

		scene.global.W = scene.global.width * scene.global.upscale
		scene.global.H = scene.global.height * scene.global.upscale
		postMessage ['resize', {
			W: scene.global.W,
			H: scene.global.H,
			realW: scene.global.width,
			realH: scene.global.height}]

		groups = {}

		for light in scene.light || []
			light.coords ?= [0, 0, 0]
			light.color ?= [1, 1, 1]

		for item in scene.item
			item.color ?= [1, 1, 1]
			item.color2 ?= item.color.map (x) -> 1 - x
			item.coords ?= [0, 0, 0]
			item.rot = vec3.scale (item.rot ? [0, 0, 0]), Math.PI / 180
			item.brightness = (item.brightness ? 0) / 100
			item.intensity = (item.intensity ? 100) / 100
			item.reflect = (item.reflect ? 0) / 100
			item.opacity = (item.opacity ? 100) / 100
			item.radius ?= 2
			item.limits ?= [0, 0, 0, 0, 0, 0]
			for i in [0 ... 3]
				if item.limits[2 * i] >= item.limits[2 * i + 1]
					item.limits[2 * i] = -Infinity
					item.limits[2 * i + 1] = Infinity

			item.pnoise ?= 0
			item.pnoise_freq ?= 1
			item.pnoise_pers ?= 1
			item.pnoise_octave ?= 1

			item.transform = mat4.identity()
			mat4.translate item.transform, item.coords
			mat4.rotateX item.transform, item.rot[0]
			mat4.rotateY item.transform, item.rot[1]
			mat4.rotateZ item.transform, item.rot[2]

			if item.group_id
				groups[item.group_id] ?= []
				groups[item.group_id].push item

		for group in scene.group || []
			group.size_mul ?= 1
			group.rot = vec3.scale (group.rot ? [0, 0, 0]), Math.PI / 180
			group.coords ?= [0, 0, 0]

			group.transform = mat4.identity()
			mat4.scale group.transform, [group.size_mul, group.size_mul, group.size_mul]
			mat4.translate group.transform, group.coords
			mat4.rotateX group.transform, group.rot[0]
			mat4.rotateY group.transform, group.rot[1]
			mat4.rotateZ group.transform, group.rot[2]

			if group.id not of groups
				continue

			for item_raw in groups[group.id]
				item = copy item_raw
				delete item.group_id

				t = mat4.create group.transform
				mat4.multiply t, item.transform
				item.transform = t

				scene.item.push item

		scene.item = scene.item.filter (item) -> not item.group_id?

		textures_remaining = 1
		for item in scene.item
			item.coords = mat4.multiplyVec3 item.transform, [0, 0, 0]
			item.inverse = mat4.inverse item.transform, mat4.create()
			item.radius2 = item.radius * item.radius

			if item.tex?
				item.tex_rep ?= 0
				item.tex_coef ?= 1
				postMessage ['texture', item.tex]
				textures_remaining++

		@onmessage data: ['texture']

	if type == 'texture'
		textures_remaining--

		if value
			{name, content} = value
			textures[name] = content

		if textures_remaining == 0
			for y in [0 ... scene.global.H]
				result = ['result']
				result.push y
				for x in [0 ... scene.global.W]
					color = process x, y, scene.global.upscale, scene.global.randomRays
					result.push ~~(color[0] * 255)
					result.push ~~(color[1] * 255)
					result.push ~~(color[2] * 255)
				postMessage result
