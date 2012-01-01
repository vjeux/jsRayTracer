

epsilon = 0.0001

mod = (x, n) ->
	((x % n) + n) % n

sign = (x) ->
	if x > 0
		1
	else if x == 0
		0
	else
		-1

solve_eq2 = (a, b, c) ->
	delta = b * b - 4 * a * c
	if delta < 0
		return []

	sqDelta = Math.sqrt delta
	[(-b - sqDelta) / (2 * a),
	 (-b + sqDelta) / (2 * a)]

objects = {}
objects.plane =
	solutions: (item, ray_) ->
		if ray_.dir[2] != 0
			[-ray_.origin[2] / ray_.dir[2]]
		else
			[]

	pos2d: (item, pos_, width, height) ->
		[width / 2 - pos_[1],
		 height / 2 - pos_[0]]

	normal: (item, ray_, pos_) ->
		[0, 0, -sign ray_.dir[2]]

objects.sphere =
	solutions: (item, ray_) ->
		a = vec3.dot ray_.dir, ray_.dir
		b = 2 * vec3.dot ray_.origin, ray_.dir
		c = (vec3.dot ray_.origin, ray_.origin) - item.radius2
		solve_eq2(a, b, c)

	pos2d: (item, pos_, width, height) ->
		pos_ = vec3.normalize pos_, vec3.create()
		phi = Math.acos (pos_[2])
		y = phi / Math.PI * height
		theta = Math.acos((pos_[1]) / Math.sin(phi)) / (2 * Math.PI);
		if pos_[0] > 0
			theta = 1 - theta
		x = theta * width
		[x, y]

	normal: (item, ray_, pos_) ->
		pos_

objects.cone =
	solutions: (item, ray_) ->
		a = ray_.dir[0] * ray_.dir[0] + ray_.dir[1] * ray_.dir[1] -
			item.radius * ray_.dir[2] * ray_.dir[2]
		b = 2 * (ray_.origin[0] * ray_.dir[0] + ray_.origin[1] * ray_.dir[1] -
			item.radius * ray_.origin[2] * ray_.dir[2])
		c = ray_.origin[0] * ray_.origin[0] + ray_.origin[1] * ray_.origin[1] -
			item.radius * ray_.origin[2] * ray_.origin[2]
		solve_eq2(a, b, c)

	pos2d: objects.sphere.pos2d

	normal: (item, ray_, pos_) ->
		normal = vec3.create pos_
		normal[2] = -normal[2] * Math.tan item.radius2
		normal

objects.cylinder =
	solutions: (item, ray_) ->
		a = ray_.dir[0] * ray_.dir[0] + ray_.dir[1] * ray_.dir[1]
		b = 2 * (ray_.origin[0] * ray_.dir[0] + ray_.origin[1] * ray_.dir[1])
		c = ray_.origin[0] * ray_.origin[0] + ray_.origin[1] * ray_.origin[1] - item.radius2
		solve_eq2(a, b, c)

	pos2d: objects.sphere.pos2d

	normal: (item, ray_, pos_) ->
		normal = vec3.create pos_
		normal[2] = 0
		normal

objects.portal = copy objects.plane
objects.portal.normal = (item, ray_, pos_) ->
		[0, 0, 1]


inLimits = (limits, pos_) ->
	limits[0] <= pos_[0] <= limits[1] and
	limits[2] <= pos_[1] <= limits[3] and
	limits[4] <= pos_[2] <= limits[5]

isValid = (ray, distances, item, min_distance) ->
	for distance in distances
		if not (0 < distance < min_distance)
			continue

		pos = vec3.create()
		pos = vec3.add ray.origin, (vec3.scale ray.dir, distance, pos), pos
		pos_ = mat4.multiplyVec3 item.inverse, pos, vec3.create()

		if inLimits item.limits, pos_
			return [pos, pos_, distance]

	[null, null, null, null]

intersectItem = (item, ray, min_distance) ->
	ray_ = # underscore means in the object's coordinates
		dir: (vec3.normalize mat4.multiplyDelta3 item.inverse, ray.dir)
		origin: (mat4.multiplyVec3 item.inverse, ray.origin, [0, 0, 0])

	obj = objects[item.type]

	[pos, pos_, distance] = isValid ray, (obj.solutions item, ray_), item, min_distance
	return if not pos

	color = item.color
	opacity = item.opacity
	reflect = item.reflect
	dir = ray.dir

	if item.tex?
		texture = textures[item.tex]
		pos2d = obj.pos2d item, pos_, texture.width, texture.height
		x = Math.floor pos2d[0]
		y = Math.floor pos2d[1]
		if item.tex_rep != 0
			x = mod x * item.tex_coef, texture.width
			y = mod y * item.tex_coef, texture.height
		idx = (texture.width * y + x) * 4
		opacity *= texture.data[idx + 3] / 255
		color = [texture.data[idx] / 255, texture.data[idx + 1] / 255, texture.data[idx + 2] / 255]

	if item.checkerboard?
		pos2d = obj.pos2d item, pos_, 500, 500
		if (mod(pos2d[0] / item.checkerboard, 1) > 0.5) == (mod(pos2d[1] / item.checkerboard, 1) > 0.5)
			color = item.color2

	if item.pnoise > 0
		alpha = perlin pos_, item.pnoise, item.pnoise_pers, item.pnoise_octave, item.pnoise_freq
		color = vec3.mix color, item.color2, alpha

	if item.type == 'portal'
		dist = item.radius2 - (pos_[0] * pos_[0] + 2 * pos_[1] * pos_[1])
		return if dist < 0

		opacity *= 1 - Math.exp -dist / 2000
		opacity = 1 - opacity
		pos = mat4.multiplyVec3 item.other.transform, pos_, vec3.create()
		dir = vec3.normalize mat4.multiplyDelta3 item.other.transform, vec3.create ray_.dir

	normal = obj.normal item, ray_, pos_
	normal = vec3.normalize mat4.multiplyDelta3 item.transform, vec3.create normal

	if opacity == 0
		return

	{distance, pos, normal, color, item, opacity, reflect, dir}

intersect = (ray, min_distance=Infinity) ->
	min_isect = null

	for item in self.scene.item
		isect = intersectItem item, ray, min_distance
		if isect and (not min_isect or isect.distance < min_isect.distance)
			min_isect = isect
			min_distance = isect.distance

	min_isect

lightning = (isect) ->
	if self.scene.light?
		color = [0, 0, 0]
	else
		color = vec3.create isect.color

	for light in self.scene.light || []
		dir = vec3.sub light.coords, isect.pos, vec3.create()
		min_distance = vec3.length dir
		vec3.normalize dir
		pos = vec3.create()
		pos = vec3.add isect.pos, (vec3.scale dir, epsilon, pos), pos
		ray =
			origin: vec3.create pos
			dir: vec3.create dir

		if not intersect ray, min_distance
			shade = Math.abs vec3.dot isect.normal, ray.dir
			# intensity * dot * light * (c + brightness)
			add_color = vec3.create isect.color
			add_color = vec3.plus add_color, isect.item.brightness
			add_color = vec3.mul add_color, light.color
			vec3.scale add_color, shade
			add_color = vec3.scale add_color, isect.item.intensity

			vec3.add color, add_color

	ambiant = vec3.create isect.color
	vec3.mul ambiant, self.scene.global.l_color
	vec3.add color, ambiant
	color

launchRay = (ray, count) ->
	color = [0, 0, 0]

	isect = intersect ray
	if isect
		color = lightning isect

		if count > 0 and isect.opacity < 1
			ray2 =
				origin: (vec3.add isect.pos, (vec3.scale isect.dir, epsilon, vec3.create()), vec3.create())
				dir: (vec3.normalize vec3.create isect.dir)
			color = vec3.mix color, (launchRay ray2, count - 1), 1 - isect.opacity

		if count > 0 and isect.reflect > 0
			ray2 =
				origin: (vec3.add isect.pos, (vec3.scale isect.normal, epsilon, vec3.create()), vec3.create())
				dir: (vec3.normalize vec3.reflect ray.dir, (vec3.normalize isect.normal), vec3.create())
			color = vec3.mix color, (launchRay ray2, count - 1), isect.reflect

	color

processPixel = (x, y) ->
	ray =
		origin: vec3.create self.scene.eye.coords
		dir: vec3.normalize [self.scene.global.distscreen, x, y]
	ray.dir = vec3.normalize vec3.rotateXYZ ray.dir, self.scene.eye.rot...

	launchRay ray, self.scene.global.max_reflect

self.process = (x, y, upscale, randomRays) ->
	color = [0, 0, 0]

	vec3.add color, processPixel(
		(self.scene.global.W / 2 - x) / upscale,
		(self.scene.global.H / 2 - y) / upscale)

	for i in [0 ... randomRays]
		vec3.add color, processPixel(
			(self.scene.global.W / 2 - x + Math.random() - 0.5) / upscale,
			(self.scene.global.H / 2 - y + Math.random() - 0.5) / upscale)

	vec3.scale color, 1 / (1 + randomRays)
