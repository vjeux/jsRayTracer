
saved = {}
noise = (i, x, y, z) ->
	key = i + '|' + x + '|' + y + '|' + z
	val = saved[key]
	if val is undefined
		val = saved[key] = Math.random()
	val

div = (a, b) ->
	Math.floor(a / b)

clamp = (x, min, max) ->
	x = min if x < min
	x = max if x > max
	x

interpolate = (a, b, x) ->
#	x = (1 - cos(x * Math.PI)) / 2
	a * (1 - x) + b * x

interpolatedNoise = (i, x, y, z, freq) ->
	x += Math.pow 2, 30 # Hack to deal with negative modulo
	y += Math.pow 2, 30
	z += Math.pow 2, 30

	low_x = x - x % freq
	hig_x = low_x + freq
	alp_x = (x - low_x) / (hig_x - low_x)
	alp_x = alp_x * alp_x * (3 - 2 * alp_x)

	low_y = y - y % freq
	hig_y = low_y + freq
	alp_y = (y - low_y) / (hig_y - low_y)
	alp_y = alp_y * alp_y * (3 - 2 * alp_y)

	low_z = z - z % freq
	hig_z = low_z + freq
	alp_z = (z - low_z) / (hig_z - low_z)
	alp_z = alp_z * alp_z * (3 - 2 * alp_z)

	v000 = noise i, low_x, low_y, low_z
	v001 = noise i, low_x, low_y, hig_z
	v010 = noise i, low_x, hig_y, low_z
	v011 = noise i, low_x, hig_y, hig_z
	v100 = noise i, hig_x, low_y, low_z
	v101 = noise i, hig_x, low_y, hig_z
	v110 = noise i, hig_x, hig_y, low_z
	v111 = noise i, hig_x, hig_y, hig_z

	i1 = interpolate v000, v001, alp_z
	i2 = interpolate v010, v011, alp_z
	i3 = interpolate v100, v101, alp_z
	i4 = interpolate v110, v111, alp_z

	j1 = interpolate i1, i2, alp_y
	j2 = interpolate i3, i4, alp_y

	interpolate j1, j2, alp_x

self.perlin = (pos, id, persistence, octaves, frequence) ->
	pos = vec3.scale pos, 0.1 * frequence, vec3.create()
	total = 0
	frequency = 1
	amplitude = 1
	for i in [0 ... octaves]
		total += amplitude * interpolatedNoise i, pos[0], pos[1], pos[2], frequency
		frequency /= 2
		amplitude *= persistence

	if id == 2
		total *= 20
		total = total - Math.floor total
	else if id == 3
		total = Math.cos pos[1] + total

	total = clamp(total, -1, 1)
