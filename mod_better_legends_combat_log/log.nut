::ModBetterLegendsCombatLog.Log <- {

	// Cache compiled regexes for better performance
	patterns = null,
	patternCategories = null,

	m = {
		entity = "(\\[color=#[0-9a-f]+\\].+\\[/color\\])",
	}

	function init() {
		this.patterns = [];
		this.patternCategories = {
			attacks = [],
			damage = [],
			deaths = [],
			morale = [],
			status = [],
			rooted = [],
		};

		// Attack patterns with and without attack rolls, with and without a target
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and misses [color=#1e468f]Manhunter Veteran Handgonner[/color] (Chance: 63, Rolled: 93)
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and misses [color=#1e468f]Manhunter Veteran Handgonner[/color]
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and [color=#1e468f]Manhunter Veteran Handgonner[/color] evades the attack
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush
		// TODO: [color=#8f1e1e]Haust Jotunn[/color] uses Split Shield and hits [color=#1e468f]Hilligonda[/color]'s shield for [b]16[/b] damage
		// TODO: [color=#8f1e1e]Haust Jotunn[/color] uses Split Shield and destroys [color=#1e468f]Hilligonda[/color]'s shield
		this.addPattern({
			category = "attacks",
			regex = regexp(this.m.entity + " uses (.*)"),
			sub_regexes = [
				regexp("(hits|misses) " + this.m.entity + " \\(Chance: (\\d+), Rolled: (\\d+)\\)"),
				regexp("(hits|misses) " + this.m.entity),
				regexp(this.m.entity + " evades the attack")
			],
			match = function(_self, _text) {
				_self.matches <- ::ModBetterLegendsCombatLog.Log.matchRegex(_self.regex, _text);
				return _self.matches != null && _self.matches.len() == 3;
			},
			replace = function(_self, _text) {
				local attacker = _self.matches[1];
				local andPos = _self.matches[2].find(" and ");
				if (andPos == null) {
					return attacker + " [" + _self.matches[2] + "]";
				}
				local skill = _self.matches[2].slice(0, andPos);
				local sub_text = _self.matches[2].slice(andPos + 5);
				local sub_matches = null;
				local index = -1;
				for (local i = 0; i < _self.sub_regexes.len(); i++) {
					sub_matches = ::ModBetterLegendsCombatLog.Log.matchRegex(_self.sub_regexes[i], sub_text);
					if (sub_matches != null) {
						index = i;
						break;
					}
				}
				if (index == -1 || sub_matches == null) {
					::logError(format("Invalid sub matches: '%s' did not match any regex", sub_text));
					return null;
				}
				if (sub_matches.len() != 2 && sub_matches.len() != 3 && sub_matches.len() != 5) {
					::logError(format("Invalid number of sub matches: expected 2, 3 or 5 got %d", sub_matches.len()));
					return null;
				}
				if ((sub_matches[1] == "misses") && !::ModBetterLegendsCombatLog.ShowMisses) {
					return ::ModBetterLegendsCombatLog.Log.SuppressOutput;
				}
				local colorized_skill = sub_matches[1] == "hits"
					? ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorHit, skill)
					: ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorMiss, skill)
				local text = attacker + " [" + colorized_skill + "]";
				if (::ModBetterLegendsCombatLog.CombatRollsStyle != "Disabled" && sub_matches.len() == 5) {
					local chance = sub_matches[3];
					local roll = sub_matches[4];
					text += ::ModBetterLegendsCombatLog.Log.formatCombatRoll(roll, chance);
				} else if (index == 2) {
					text += " (Evade)";
				}
				local target = sub_matches.len() > 2 ? sub_matches[2] : sub_matches[1];
				return text + " → " + target;
			}
		});

		// Death patterns with a target
		// Example: [color=#8f1e1e]Xenthalus The Dauntless[/color] uses Raise Undead
		this.addPattern({
			category = "deaths",
			regex = regexp(this.m.entity + " has (killed|struck down) " + this.m.entity),
			match = function(_self, _text) {
				_self.matches <- ::ModBetterLegendsCombatLog.Log.matchRegex(_self.regex, _text);
				return _self.matches != null && _self.matches.len() == 4;
			},
			replace = function(_self, _text) {
				local attacker = _self.matches[1];
				local action = _self.matches[2];
				local victim = _self.matches[3];
				return attacker + " [" + ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorDeath, action == "killed" ? "KILLED" : "STRUCK DOWN") + "] " + victim;
			}
		});

		// Death patterns without a target
		// Example: [color=#8f1e1e]Xenthalus The Dauntless[/color] uses Raise Undead
		this.addPattern({
			category = "deaths",
			regex = regexp(this.m.entity + " (has died|is struck down)"),
			match = function(_self, _text) {
				_self.matches <- ::ModBetterLegendsCombatLog.Log.matchRegex(_self.regex, _text);
				return _self.matches != null && _self.matches.len() == 3;
			},
			replace = function(_self, _text) {
				local entity = _self.matches[1];
				local action = _self.matches[2];
				return entity + " [" + ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorDeath, action == "has died" ? "DIED" : "STRUCK DOWN") + "]";
			}
		});

		// Morale checks
		// Example: [color=#8f1e1e]Xenthalus The Dauntless[/color] is breaking
		// TODO Use:
		// - gt.Const.MoraleStateName
		// - gt.Const.MoraleStateEvent
		this.addPattern({
			category = "morale",
			regex = regexp(this.m.entity + "( is fleeing| is breaking| is wavering|'s morale is now steady| is confident| has rallied)"),
			match = function(_self, _text) {
				_self.matches <- ::ModBetterLegendsCombatLog.Log.matchRegex(_self.regex, _text);
				return _self.matches != null && _self.matches.len() == 3;
			},
			replace = function(_self, _text) {
				if (!::ModBetterLegendsCombatLog.ShowMoraleChanges) {
					return ::ModBetterLegendsCombatLog.Log.SuppressOutput;
				}
				local color;
				local text;
				switch(_self.matches[2]) {
					case " is fleeing":
						color = ::ModBetterLegendsCombatLog.ColorVeryNegativeValue;
						text = "Fleeing";
						break;
					case " is breaking":
						color = ::ModBetterLegendsCombatLog.ColorNegativeValue;
						text = "Breaking";
						break;
					case " is wavering":
						color = ::ModBetterLegendsCombatLog.ColorNegativeValue;
						text = "Wavering";
						break;
					case "'s morale is now steady":
						color = ::ModBetterLegendsCombatLog.ColorPositiveValue;
						text = "Steady";
						break;
					case " is confident":
						color = ::ModBetterLegendsCombatLog.ColorVeryPositiveValue;
						text = "Confident";
						break;
					case " has rallied":
						// This is usually followed by the new state the entity is in,
						// so we can filter this one out and let the next log do the job.
						return ::ModBetterLegendsCombatLog.Log.SuppressOutput;
					default:
						::logError("Invalid match: " + _self.matches[2]);
						return null;
				}
				return _self.matches[1] + " → [" + ::MSU.Text.color(color, text) + "]";
			}
		});

		// Damage patterns
		// Example: [color=#8f1e1e]Wiederganger[/color]'s Simple Mail Shirt on Linen Tunic Wrap is hit for [b]16[/b] damage and has been destroyed
		// Example: [color=#8f1e1e]Wiederganger[/color]'s body is hit for [b]16[/b] damage
		// Example: [color=#1e468f]Eingeliadis's Warden[/color]'s head is hit for [b]15[/b] damage
		this.addPattern({
			category = "damage",
			hit_needle = " is hit for ",
			part_needle = "'s ",
			color_needle = "[/color]",
			regex_damage = regexp("\\[b\\]([0-9]+)\\[/b\\] damage"),
			match = function(_self, _text) {
				return _text.find(_self.hit_needle) != null;
			},
			replace = function(_self, _text) {
				local hitPos = _text.find(_self.hit_needle);
				if (hitPos == null) {
					::logError(format("Invalid match: missing '%s' in '%s'", _self.hit_needle, _text));
					return null;
				}

				// Left side: [color=#8f1e1e]Wiederganger[/color]'s Simple Mail Shirt on Linen Tunic Wrap
				local entity_and_part = _text.slice(0, hitPos);
				local partPos = entity_and_part.find(_self.part_needle);
				if (partPos == null) {
					::logError(format("Invalid match: missing '%s' in '%s'", _self.part_needle, entity_and_part));
					return null;
				}
				// We have to watch out for early matches of the `'s` needle, as it can be part of
				// the entity name (eg. Eingeliadis's Warden). As an additional check we verify that
				// the match ends with [/color], if not we continue until the next occurence(s).
				local entity = entity_and_part.slice(0, partPos);
				while (entity.find(_self.color_needle) == null) {
					partPos = entity_and_part.find(_self.part_needle, partPos + 1);
					if (partPos == null) {
						::logError(format("Invalid match: missing '%s' in '%s'", _self.part_needle, entity_and_part));
						return null;
					}
					entity = entity_and_part.slice(0, partPos);
				}
				local part = entity_and_part.slice(partPos + _self.part_needle.len());

				// Right side: [b]16[/b] damage and has been destroyed
				local damage = _text.slice(hitPos + _self.hit_needle.len());

				// Has the item been destroyed?
				local destroyedPos = damage.find(" and has been destroyed");
				if (destroyedPos != null) {
					damage = damage.slice(0, destroyedPos);
				}

				// Extract damage number from "[b]16[/b] damage"
				local damage_matches = ::ModBetterLegendsCombatLog.Log.matchRegex(_self.regex_damage, damage);
				if (damage_matches == null) {
					::logError(format("Invalid match: '%s' did not match regex", damage));
					return null;
				}
				if (damage_matches.len() != 2) {
					::logError(format("Invalid number of matches: expected 2 got %d", damage_matches.len()));
					return null;
				}

				local colorized_part;
				if (part == "body" || part == "head" || part == "armor") {
					// Capitalize the first letter of special parts
					part = part.slice(0, 1).toupper() + part.slice(1);
					colorized_part = ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorHealth, part);
				} else {
					if (destroyedPos != null) {
						part = "[s]" + part + "[/s]";
					}
					colorized_part = ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorArmor, part);
				}

				return format("&nbsp;&nbsp; » %s → %s %s", damage_matches[1], entity, colorized_part);
			}
		});

		// Status patterns
		// Example: [color=#1e468f]Bandit Veteran[/color] battered [color=#1e468f]Billman[/color] leaving them baffled
		// Example: [color=#1e468f]Bandit Veteran[/color] has stunned [color=#1e468f]Billman[/color] for one turn
		// Example: [color=#1e468f]Brigand Raider[/color] feinted [color=#1e468f]Wardog[/color] leaving them exposed!
		// TODO

		// Rooted patterns
		// Example: [color=#1e468f]Bandit Veteran[/color] effortlessly breaks free (Chance: 99, Rolled: 1)
		// Example: [color=#1e468f]Brigand Raider[/color] breaks free (Chance: 99, Rolled: 1)
		// Example: [color=#1e468f]Brigand Raider[/color] fails to break free (Chance: 99, Rolled: 100)
		this.addPattern({
			category = "rooted",
			regex = regexp(this.m.entity + " (effortlessly breaks free|breaks free|fails to break free) \\(Chance: (\\d+), Rolled: (\\d+)\\)"),
			match = function(_self, _text) {
				_self.matches <- ::ModBetterLegendsCombatLog.Log.matchRegex(_self.regex, _text);
				return _self.matches != null && _self.matches.len() == 5;
			},
			replace = function(_self, _text) {
				local entity = _self.matches[1];
				local action = _self.matches[2];
				if (action == "fails to break free" && !::ModBetterLegendsCombatLog.ShowMisses) {
					return ::ModBetterLegendsCombatLog.Log.SuppressOutput;
				}
				local colorized_action = action != "fails to break free"
					? ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorHit, "Break Free")
					: ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorMiss, "Break Free")
				local text = entity + " [" + colorized_action + "]";
				if (::ModBetterLegendsCombatLog.CombatRollsStyle != "Disabled") {
					local chance = _self.matches[3];
					local roll = _self.matches[4];
					text += ::ModBetterLegendsCombatLog.Log.formatCombatRoll(roll, chance);
				}
				return text;
			}
		});

		// Special patterns
		// TODO: [color=#1e468f]Eingelias the Vala[/color] is poisoned
		// TODO: [color=#1e468f]Goblin Skirmisher[/color] tumbles away from danger

		::logInfo("Combat Log patterns initialized");
	},

	function addPattern(_pattern) {
		this.patterns.push(_pattern);

		if ("category" in _pattern && _pattern.category in this.patternCategories) {
			this.patternCategories[_pattern.category].push(_pattern);
		} else {
			::logError("Invalid pattern category: " + _pattern.category);
		}
	},

	function intercept(_text) {
		// Initialize patterns if not already done
		if (this.patterns == null) {
			this.init();
		}

		// Try patterns from guessed category
		local category = this.guessCategory(_text);
		if (category == null) {
			return _text;
		}

		local result = this.matchPatterns(_text, category);
		if (result != null) {
			return result;
		}

		// If no pattern matched, return the original text
		return _text;
	},

	// Tries to guess which pattern category to check first based on text content.
	// This avoids matching many regexes that are not relevant to the text.
	function guessCategory(_text) {
		if (_text.find(" uses ") != null) {
			return "attacks";
		} else if (_text.find(" is hit for ") != null) {
			return "damage";
		} else if (_text.find(" killed ") != null
			|| _text.find(" died") != null
			|| _text.find(" struck down") != null) {
			return "deaths";
		} else if (_text.find(" is confident") != null
			|| _text.find(" is now steady") != null
			|| _text.find(" is wavering") != null
			|| _text.find(" is breaking") != null
			|| _text.find(" is fleeing") != null
			|| _text.find(" has rallied") != null) {
			return "morale";
		} else if (_text.find(" break free") != null
			|| _text.find(" breaks free") != null) {
			return "rooted";
		}
		return null;
	},

	function matchPatterns(_text, _category) {
		if (!(_category in this.patternCategories)) {
			::logError("Invalid pattern category: " + _category);
			return null;
		}

		foreach (pattern in this.patternCategories[_category]) {
			if (pattern.match(pattern, _text)) {
				return pattern.replace(pattern, _text);
			}
		}

		return null;
	},

	function formatCombatRoll(_roll, _chance) {

	}

};

::ModBetterLegendsCombatLog.Log.formatCombatRoll <- function(_roll, _chance) {
	switch (::ModBetterLegendsCombatLog.CombatRollsStyle) {
		case "Compact":
			local comp = _roll.tointeger() <= _chance.tointeger() ? "≤" : ">";
			return " (" + _roll + "<" + _chance + ")";
		case "Vanilla":
			return " (Chance: " + _chance + ", Rolled: " + _roll + ")";
		case "Disabled":
			return "";
		default:
			::logError(format("Unspported CombatRollsStyle: %s", ::ModBetterLegendsCombatLog.CombatRollsStyle));
			return "";
	}
};

::ModBetterLegendsCombatLog.Log.matchRegex <- function(_regex, _text) {
	local result = _regex.capture(_text);
	if (result) {
		local matches = [];
		foreach (i, val in result) {
			matches.push(_text.slice(val.begin, val.end));
		}
		return matches;
	}
	return null;
};

::ModBetterLegendsCombatLog.Log.addSuccessColor <- function (_text, _success) {
	return _success ? ::MSU.Text.colorGreen(_text) : ::MSU.Text.colorRed(_text)
};

::ModBetterLegendsCombatLog.Log.padWith <- function (_text, _length, _with) {
	local padded = _text;
	for (local i = 0; i < _length - _text.len(); i++) {
		padded = _with + padded;
	}
	return padded;
};

::ModBetterLegendsCombatLog.Log.logNextRound <- function(_turn) {
	::Tactical.EventLog.logEx("\n===== ROUND " + _turn + "\n");
};

::ModBetterLegendsCombatLog.Log.SuppressOutput <- "ModBetterLegendsCombatLog::SUPPRESS_OUTPUT";
