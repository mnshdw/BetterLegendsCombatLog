::ModBetterLegendsCombatLog.PoV <- {

	// Preprocesses text to handle nested color tags by flattening them into separate colored segments
	function preprocessNestedColorTags(_text) {
		local result = _text;
		local pos = 0;

		while (pos < result.len()) {
			local entity = this.extractColoredEntity(result, pos);
			if (entity == null) {
				break;
			}

			// Check if this entity has nested color tags
			local hasNestedTags = this.hasNestedColorTags(entity.text);
			if (hasNestedTags) {
				// Extract and flatten nested color structure
				local flattened = this.flattenNestedColorTags(entity.text);
				result = result.slice(0, entity.start) + flattened + result.slice(entity.end);
				pos = entity.start + flattened.len();
			} else {
				pos = entity.end;
			}
		}

		return result;
	}

	// Helper function to extract colored entity name, handling nested color tags
	function extractColoredEntity(_text, _startPos = 0) {
		// Look for color tag start
		local colorStartPos = _text.find("[color=", _startPos);

		if (colorStartPos == null) {
			return null;
		}

		// Find the matching [/color] tag by counting brackets
		local pos = colorStartPos;
		local bracketCount = 0;
		local endPos = null;

		while (pos < _text.len()) {
			if (_text.slice(pos, pos + 7) == "[color=") {
				bracketCount++;
				pos += 7;
				// Skip to end of color value
				local closeBracket = _text.find("]", pos);
				if (closeBracket != null) {
					pos = closeBracket + 1;
				}
			} else if (_text.slice(pos, pos + 8) == "[/color]") {
				bracketCount--;
				if (bracketCount == 0) {
					endPos = pos + 8;
					break;
				}
				pos += 8;
			} else {
				pos++;
			}
		}

		if (endPos == null) {
			return null;
		}

		return {
			text = _text.slice(colorStartPos, endPos),
			start = colorStartPos,
			end = endPos
		};
	}

	// Checks if a colored entity text has nested color tags
	function hasNestedColorTags(_text) {
		// Count opening color tags
		local colorCount = 0;
		local pos = 0;
		while (pos < _text.len()) {
			local colorPos = _text.find("[color=", pos);
			if (colorPos == null) {
				break;
			}

			colorCount++;
			pos = colorPos + 7;
		}

		return colorCount > 1;
	}

	// Flattens nested color tags into separate colored segments
	//
	// Examples:
	//
	// 1. Nested inner
	//      [color=#8f1e1e][color=#01420d]Poisonous[/color] Footman[/color]
	//   => [color=#01420d]Poisonous[/color] [color=#8f1e1e]Footman[/color]
	//
	// 2. Nested inner x2
	//      [color=#632004][color=#01420d]Hexhulk[/color] [color=#3a7f2b]Wurmblood[/color] Brigand Raider[/color]
	//   => [color=#01420d]Hexhulk[/color] [color=#3a7f2b]Wurmblood[/color] [color=#632004]Brigand Raider[/color]
	//
	// 3. Already flat
	//      [color=#632004]Hexhulk[/color] [color=#01420d]Wurmblood[/color] Brigand Raider
	//   => unchanged
	//
	// Plz Blue, stop adding layers.
	function flattenNestedColorTags(_text) {
		// Parse the structure deterministically: [color=...]{content}[/color]
		local openIdx = _text.find("[color=");
		if (openIdx == null) {
			return _text;
		}
		local closeIdx = _text.find("]", openIdx + 7);
		if (closeIdx == null) {
			return _text;
		}

		// e.g. "color=#abcd12"
		local outerColor = _text.slice(openIdx + 1, closeIdx);
		local contentStart = closeIdx + 1;
		local contentEnd = _text.len() - 8; // strip trailing [/color]
		if (contentEnd <= contentStart) {
			return _text;
		}
		local content = _text.slice(contentStart, contentEnd);

		// Helper to check for an opening color tag at position
		local isOpenColorAt = function(t, i) {
			if (i + 7 > t.len()) {
				return false;
			}
			local h = t.slice(i, i + 7);
			return h == "[color=";
		};

		// Advance to after the closing ']' of a color tag header
		local headerEnd = function(t, i) {
			local close = t.find("]", i + 7);
			return close == null ? null : close + 1;
		};

		// Find matching [/color] index using a simple bracket counter
		local findMatchingClose = function(t, iAfterHeader) {
			local pos = iAfterHeader;
			local depth = 1;
			while (pos < t.len()) {
				if (isOpenColorAt(t, pos)) {
					local he = headerEnd(t, pos);
					if (he == null) {
						return null;
					}
					depth++;
					pos = he;
				} else if (t.slice(pos, pos + 8) == "[/color]") {
					depth--;
					if (depth == 0) return pos; // position of '[' in [/color]
					pos += 8;
				} else {
					pos++;
				}
			}
			return null;
		};

		local pos = 0;
		local result = "";
		local appendedTail = false;
		while (pos < content.len()) {
			local nextOpen = content.find("[color=", pos);
			if (nextOpen == null) {
				local tail = this.trim(content.slice(pos));
				if (tail.len() > 0) {
					if (result.len() > 0) {
						result += " ";
					}
					result += "[" + outerColor + "]" + tail + "[/color]";
					appendedTail = true;
				}
				break;
			}

			// Any plain text before the inner tag belongs to the outer color
			if (nextOpen > pos) {
				local plain = this.trim(content.slice(pos, nextOpen));
				if (plain.len() > 0) {
					if (result.len() > 0) {
						result += " ";
					}
					result += "[" + outerColor + "]" + plain + "[/color]";
				}
			}

			// Process the inner colored segment, which may itself be nested
			local he = headerEnd(content, nextOpen);
			if (he == null) {
				// Likely malformed, return original text
				return _text;
			}

			// Extract the color token without brackets
			local colorToken = content.slice(nextOpen + 1, content.find("]", nextOpen));
			local matchClose = findMatchingClose(content, he);
			if (matchClose == null) {
				return _text;
			}
			local innerText = content.slice(he, matchClose);
			local innerWrapped = "[" + colorToken + "]" + innerText + "[/color]";

			// Recursively flatten in case of deeper nesting
			local flattenedInner = this.hasNestedColorTags(innerWrapped) ? this.flattenNestedColorTags(innerWrapped) : innerWrapped;
			if (flattenedInner.len() > 0) {
				if (result.len() > 0) {
					result += " ";
				}
				result += this.trim(flattenedInner);
			}

			pos = matchClose + 8; // move past [/color]
		}

		// If there is remaining plain text not yet appended, append with outer color
		if (!appendedTail && pos < content.len()) {
			local tail = this.trim(content.slice(pos));
			if (tail.len() > 0) {
				if (result.len() > 0) {
					result += " ";
				}
				result += "[" + outerColor + "]" + tail + "[/color]";
			}
		}

		return result.len() > 0 ? result : _text;
	}

	// Simple trim function to remove leading/trailing whitespace
	function trim(_text) {
		local start = 0;
		local end = _text.len();

		// Trim leading whitespace
		while (start < end && (_text[start] == ' ' || _text[start] == '\t' || _text[start] == '\n')) {
			start++;
		}

		// Trim trailing whitespace
		while (end > start && (_text[end-1] == ' ' || _text[end-1] == '\t' || _text[end-1] == '\n')) {
			end--;
		}

		return _text.slice(start, end);
	}

}
