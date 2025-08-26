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
		// Look for color tag start - handle both [color and [Color
		local colorStartPos = _text.find("[color=", _startPos);
		local colorStartPosUpper = _text.find("[Color=", _startPos);

		if (colorStartPos == null && colorStartPosUpper == null) {
			return null;
		}

		// Use whichever appears first
		if (colorStartPos == null || (colorStartPosUpper != null && colorStartPosUpper < colorStartPos)) {
			colorStartPos = colorStartPosUpper;
		}

		// Find the matching [/color] tag by counting brackets
		local pos = colorStartPos;
		local bracketCount = 0;
		local endPos = null;

		while (pos < _text.len()) {
			if (_text.slice(pos, pos + 7) == "[color=" || _text.slice(pos, pos + 7) == "[Color=") {
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
			local colorPosUpper = _text.find("[Color=", pos);

			if (colorPos == null && colorPosUpper == null) {
				break;
			}

			if (colorPos == null || (colorPosUpper != null && colorPosUpper < colorPos)) {
				colorPos = colorPosUpper;
			}

			colorCount++;
			pos = colorPos + 7;
		}

		return colorCount > 1;
	}

	// Flattens nested color tags into separate colored segments
	// Example: "[color=#8f1e1e][Color=#01420d]Poisonous[/color] Footman[/color]"
	//       -> "[color=#01420d]Poisonous[/color] [color=#8f1e1e]Footman[/color]"
	function flattenNestedColorTags(_text) {
		// Parse the structure: outer[inner_content]remaining[/outer]
		local outerColorMatch = regexp("\\[([Cc]olor=#[0-9a-f]+)\\]").capture(_text);
		if (!outerColorMatch || outerColorMatch.len() < 2) {
			return _text;
		}

		local outerColor = _text.slice(outerColorMatch[1].begin, outerColorMatch[1].end);
		local contentStart = outerColorMatch[0].end;
		local contentEnd = _text.len() - 8; // Remove [/color] at end
		local content = _text.slice(contentStart, contentEnd);

		// Check if content has inner color tags
		local innerColorMatch = regexp("\\[([Cc]olor=#[0-9a-f]+)\\]").capture(content);
		if (!innerColorMatch || innerColorMatch.len() < 2) {
			return _text; // No nested structure
		}

		local innerColor = content.slice(innerColorMatch[1].begin, innerColorMatch[1].end);
		local innerContentStart = innerColorMatch[0].end;
		local innerEndPos = content.find("[/color]");

		if (innerEndPos == null) {
			return _text; // Malformed nested structure
		}

		local innerText = content.slice(innerContentStart, innerEndPos);
		local remainingText = content.slice(innerEndPos + 8); // After [/color]

		// Reconstruct as separate colored segments
		local result = "[" + innerColor + "]" + innerText + "[/color]";
		if (remainingText.len() > 0) {
			// Trim leading/trailing spaces for better formatting
			remainingText = this.trim(remainingText);
			if (remainingText.len() > 0) {
				result += " [" + outerColor + "]" + remainingText + "[/color]";
			}
		}

		return result;
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
