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
			status = []
		};

		// Attack patterns with and without attack rolls, with and without a target
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and misses [color=#1e468f]Manhunter Veteran Handgonner[/color] (Chance: 63, Rolled: 93)
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and misses [color=#1e468f]Manhunter Veteran Handgonner[/color]
		// Example: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush
		this.addPattern({
			category = "attacks",
			regex = this.m.entity + " uses (.*)",
			sub_regex_with_target = regexp("(hits|misses) " + this.m.entity + " \\(Chance: (\\d+), Rolled: (\\d+)\\)"),
			sub_regex_without_target = regexp("(hits|misses) " + this.m.entity),
			replace = function(matches) {
				if (matches.len() != 3) {
					::logError(format("Invalid number of matches: expected 3 got %d", matches.len()));
					return null;
				}
				local attacker = matches[1];
				local andPos = matches[2].find(" and ");
				if (andPos == null) {
					::logError("Invalid match: missing ' and ' in " + matches[2]);
					return null;
				}
				local skill = matches[2].slice(0, andPos);
				local sub_text = matches[2].slice(andPos + 5);
				local sub_matches = ::ModBetterLegendsCombatLog.Log.matchRegex(this.sub_regex_with_target, sub_text);
				if (sub_matches == null) {
					sub_matches = ::ModBetterLegendsCombatLog.Log.matchRegex(this.sub_regex_without_target, sub_text);
				}
				if (sub_matches == null) {
					::logError(format("Invalid sub matches: '" + sub_text + "' did not match any regex"));
					return null;
				}
				if (sub_matches.len() != 3 && sub_matches.len() != 5) {
					::logError(format("Invalid number of sub matches: expected 3 or 5 got %d", sub_matches.len()));
					return null;
				}
				local colorized_skill = sub_matches[1] == "hits"
					? ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorHit, skill)
					: ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorMiss, skill)
				local text = attacker + " [" + colorized_skill + "]";
				if (::ModBetterLegendsCombatLog.ShowCombatRolls && sub_matches.len() == 5) {
					local chance = sub_matches[3];
					local roll = sub_matches[4];
					local comp = roll.tointeger() <= chance.tointeger() ? "≤" : ">";
					text += " (" + roll + comp + chance + ")";
				}
				return text + " → " + sub_matches[2];
			}
		});

		// this.addPattern({
		// 	category = "attacks",
		// 	regex = "^(.+) uses (.+) and the shot goes astray and hits (.+) \\(Chance: (\\d+), Rolled: (\\d+)\\)$",
		// 	replace = function(matches) {
		// 		local attacker = matches[1];
		// 		local skill = ::MSU.Text.colorGreen(matches[2]);
		// 		local target = matches[3];
		// 		local chance = matches[4];
		// 		local roll = matches[5];

		// 		return attacker + " " + skill + "(» " + roll + "<" + chance + ") -> " + target;
		// 	}
		// });

		// this.addPattern({
		// 	category = "attacks",
		// 	regex = "^(.+) uses (.+) and the shot goes astray and misses (.+) \\(Chance: (\\d+), Rolled: (\\d+)\\)$",
		// 	replace = function(matches) {
		// 		local attacker = matches[1];
		// 		local skill = ::MSU.Text.colorRed(matches[2]);
		// 		local target = matches[3];
		// 		local chance = matches[4];
		// 		local roll = matches[5];

		// 		return attacker + " " + skill + "(» " + roll + ">" + chance + ") -!> " + target;
		// 	}
		// });

		// this.addPattern({
		// 	category = "attacks",
		// 	regex = "^(.+) uses (.+) and the shot goes astray and hits (.+)$",
		// 	replace = function(matches) {
		// 		local attacker = matches[1];
		// 		local skill = ::MSU.Text.colorGreen(matches[2]);
		// 		local target = matches[3];

		// 		return attacker + " " + skill + " » (Astray) " + target;
		// 	}
		// });

		// this.addPattern({
		// 	category = "attacks",
		// 	regex = "^(.+) uses (.+) and (.+) evades the attack$",
		// 	replace = function(matches) {
		// 		local attacker = matches[1];
		// 		local skill = ::MSU.Text.colorRed(matches[2]);
		// 		local target = matches[3];

		// 		return attacker + " " + skill + " » (Evaded) " + target;
		// 	}
		// });

		// // Lucky/Unlucky patterns
		// this.addPattern({
		// 	category = "status",
		// 	regex = "^(.+) got lucky\\.$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		return entity + " » " + ::MSU.Text.colorGreen("Got Lucky") + " (rerolled defense)";
		// 	}
		// });

		// this.addPattern({
		// 	category = "status",
		// 	regex = "^(.+) wasn\\'t lucky enough\\.$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		return entity + " » " + ::MSU.Text.colorRed("Wasn't Lucky") + " (rerolled defense failed)";
		// 	}
		// });

		// Death patterns with a target
		// Example: [color=#8f1e1e]Xenthalus The Dauntless[/color] uses Raise Undead
		this.addPattern({
			category = "deaths",
			regex = this.m.entity + " has (killed|struck down) " + this.m.entity,
			replace = function(matches) {
				if (matches.len() != 4) {
					::logError(format("Invalid number of matches: expected 4 got %d", matches.len()));
					return null;
				}
				local attacker = matches[1];
				local action = matches[2];
				local victim = matches[3];
				return attacker + " [" + ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorDeath, action == "killed" ? "KILLED" : "STRUCK DOWN") + "] " + victim;
			}
		});

		// Death patterns without a target
		// Example: [color=#8f1e1e]Xenthalus The Dauntless[/color] uses Raise Undead
		this.addPattern({
			category = "deaths",
			regex = this.m.entity + " (has died|is struck down)",
			replace = function(matches) {
				if (matches.len() != 3) {
					::logError(format("Invalid number of matches: expected 3 got %d", matches.len()));
					return null;
				}
				local entity = matches[1];
				local action = matches[2];
				return entity + " [" + ::MSU.Text.color(::ModBetterLegendsCombatLog.ColorDeath, action == "has died" ? "DIED" : "STRUCK DOWN") + "]";
			}
		});

		// Morale checks
		this.addPattern({
			category = "morale",
			// TODO Use:
			// - gt.Const.MoraleStateName
			// - gt.Const.MoraleStateEvent
			regex = this.m.entity + "( is fleeing| is breaking| is wavering|'s morale is now steady|is confident| has rallied)",
			replace = function(matches) {
				if (!::ModBetterLegendsCombatLog.ShowMoraleChanges) {
					return ::ModBetterLegendsCombatLog.Log.SuppressOutput;
				}
				if (matches.len() != 3) {
					::logError(format("Invalid number of matches: expected 3 got %d", matches.len()));
					return null;
				}
				local color;
				local text;
				switch(matches[2]) {
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
						::logError("Invalid match: " + matches[2]);
						return null;
				}
				return matches[1] + " → [" + ::MSU.Text.color(color, text) + "]";
			}
		});

		// this.addPattern({
		// 	category = "injuries",
		// 	regex = "^(.+)'s (.+) is hit for \\[b\\](.+)\\[/b\\] damage and suffers (.+)!$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		local bodyPart = matches[2];
		// 		local damage = matches[3];
		// 		local injury = matches[4];
		// 		return entity + " » " + bodyPart + " hit for " + ::MSU.Text.colorRed(damage) + " + " + ::MSU.Text.colorRed(injury);
		// 	}
		// });

		::logInfo("Combat Log patterns initialized");
	},

	function addPattern(_pattern) {
		_pattern.regexCompiled <- regexp(_pattern.regex);
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

	// Tries to guess which pattern category to check first based on text content
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
		}
		return null;
	},

	function matchPatterns(_text, _category) {
		if (!(_category in this.patternCategories)) {
			::logError("Invalid pattern category: " + _category);
			return null;
		}

		foreach (pattern in this.patternCategories[_category]) {
			local matches = ::ModBetterLegendsCombatLog.Log.matchRegex(pattern.regexCompiled, _text);
			if (matches != null) {
				return pattern.replace(matches);
			}
		}

		return null;
	},

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

::ModBetterLegendsCombatLog.Log.logNextRound <- function(_turn) {
	::Tactical.EventLog.logEx("\n===== ROUND " + _turn + "\n");
};

::ModBetterLegendsCombatLog.Log.SuppressOutput <- "ModBetterLegendsCombatLog::SUPPRESS_OUTPUT";
