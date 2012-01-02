
$ ->
	$canvas = $('canvas')
	canvas = $canvas[0]
	context = canvas.getContext '2d'
	W = H = canvasData = worker = 0

	throttle = 100


	editor = CodeMirror.fromTextArea $('textarea')[0],
		lineNumbers: true

	$('#selection img').click ->
		title = $(this).attr('title')
		document.location.hash = title
		$.get 'examples/' + title + '.rt', (file) ->
			editor.setValue '# ' + title + '.rt\n\n' + file.trim()

	default_img = $('#selection [title=' + document.location.hash[1...] + ']')
	if default_img.length == 0
		default_img = $('#selection img')
	default_img.eq(0).click()

	$('#stop').click ->
		worker.terminate() if worker

	$('#save').click ->
		window.open canvas.toDataURL "image/png"

	$('#generate').click ->
		worker.terminate() if worker
		worker = new Worker 'src/worker.js'
		worker.postMessage ['process', {input: editor.getValue()}]

		count = 0
		t = +new Date()

		fillRect = (X, Y, size, r, g, b) ->
			for y in [0 ... size]
				idxData = ((Y + y) * W + X) * 4
				for x in [0 ... size]
					canvasData.data[idxData++] = r
					canvasData.data[idxData++] = g
					canvasData.data[idxData++] = b
					canvasData.data[idxData++] = 255

		worker.onmessage = (msg) ->
			if msg.data[0] == 'result'
				size = msg.data[1]
				y = msg.data[2]
				idxMsg = 3
				idxData = y * W * 4
				for x in [0 ... W] by size
					if size == 32 or not (x % (size * 2) == 0 and y % (size * 2) == 0)
						fillRect x, y, size, msg.data[idxMsg++], msg.data[idxMsg++], msg.data[idxMsg++]

				context.putImageData canvasData, 0, 0

#				if size == 1 and ++count == H
				$('#time').html(Math.round((+new Date() - t) / 1000) + 's')

			else if msg.data[0] == 'texture'
				texture = msg.data[1]
				img = $('<img>')
					.imageLoad(->
						cv = $('<canvas>')[0]
						cv.width = @.width
						cv.height = @.height
						ctx = cv.getContext '2d'
						ctx.drawImage @, 0, 0
						worker.postMessage ['texture',
							name: texture
							content: ctx.getImageData 0, 0, @.width, @.height])
					.attr src: texture

			else if msg.data[0] == 'resize'
				{W, H, realW, realH} = msg.data[1]
				context = canvas.getContext '2d'
				canvas.width = W
				canvas.height = H
				canvasData = context.createImageData W, H
				$canvas.css width: realW, height: realH
				$('#save').show()

			else if msg.data[0] == 'log'
				if throttle-- > 0
					console.log inspect msg.data[1...]...
				if throttle == 0
					console.log 'Throttled!'

`
$.fn.imageLoad = function(fn){
    this.load(fn);
    this.each( function() {
        if ( this.complete && this.naturalWidth !== 0 ) {
            $(this).trigger('load');
        }
    });
	return this;
}
`