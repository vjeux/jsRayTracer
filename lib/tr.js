
CodeMirror.defineMode("tr", function() {
	return {
		startState: function () {
			return {
				column: 0,
				inBrackets: false,
				isKey: true,
			};
		},
		token: function (stream, state) {
			stream.eatSpace();
			if (stream.eol()) {
				state.isKey = true;
				return;
			}
			var ch = stream.next();
			if (ch === '#') {
				stream.skipToEnd();
				return 'comment';
			}

			if (ch === '{' || ch === '}') {
				state.inBrackets = ch === '{';
				return 'bracket';
			}

			if (!state.inBrackets) {
				stream.eatWhile(/[^\s\{}#]/);
				return 'name';
			}

			if (state.isKey) {
				stream.eatWhile(/[^\s\{}#]/);
				state.isKey = stream.eol();
				return 'key';
			}

			state.isKey = true;
			stream.eatWhile(/[^#]/);
			return 'value';
		}
	};
});

CodeMirror.defineMIME("text/x-diff", "diff");