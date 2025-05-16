::ModBetterLegendsCombatLog.Log <- {

	// Cache compiled regexes for better performance
	patterns = null,
	patternCategories = null,

	entity = "(\\[color=#[0-9a-f]+\\].+\\[/color\\])",

	function init() {
		this.patterns = [];
		this.patternCategories = {
			attacks = [],
			injuries = [],
			deaths = [],
			status = []
		};

		// Attack patterns (hit, miss, evade)
		// Regex:   this.entity + " uses ([\\s.]+) and (hits|misses) " + this.entity + " \\(Chance: (\\d+), Rolled: (\\d+)\\)"
		// Matches: [color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and misses [color=#1e468f]Manhunter Veteran Handgonner[/color] (Chance: 63, Rolled: 93)
		this.addPattern({
			category = "attacks",
			regex = this.entity + " uses (.*)",
			sub_regex = regexp("(hits|misses) " + this.entity + " \\(Chance: (\\d+), Rolled: (\\d+)\\)"),
			// regex = this.entity + " uses ([\\s.]+) and (hits|misses) " + this.entity + " \\(Chance: (\\d+), Rolled: (\\d+)\\)",
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
				local sub_matches = ::ModBetterLegendsCombatLog.Log.matchRegex(this.sub_regex, sub_text);
				if (sub_matches.len() != 5) {
					::logError(format("Invalid number of sub matches: expected 5 got %d", sub_matches.len()));
					return null;
				}
				local colorized_skill = sub_matches[1] == "hits"
					? ::MSU.Text.colorGreen(skill)
					: ::MSU.Text.colorRed(skill)
				local target = sub_matches[2];
				local chance = sub_matches[3];
				local roll = sub_matches[4];
				local comp = roll.tointeger() <= chance.tointeger() ? "≤" : ">";
				return attacker + " [" + colorized_skill + "] (" + roll + comp + chance + ") → " + target;
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
		// 	regex = "^(.+) uses (.+) and hits (.+)$",
		// 	replace = function(matches) {
		// 		local attacker = matches[1];
		// 		local skill = ::MSU.Text.colorGreen(matches[2]);
		// 		local target = matches[3];

		// 		return attacker + " " + skill + " » " + target;
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

		// // Kill and death patterns
		// this.addPattern({
		// 	category = "deaths",
		// 	regex = "^(.+) has killed (.+)$",
		// 	replace = function(matches) {
		// 		local killer = matches[1];
		// 		local victim = matches[2];
		// 		return killer + " » " + ::MSU.Text.colorRed("KILLED") + " " + victim;
		// 	}
		// });

		// this.addPattern({
		// 	category = "deaths",
		// 	regex = "^(.+) has died$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		return entity + " » " + ::MSU.Text.colorRed("DIED");
		// 	}
		// });

		// this.addPattern({
		// 	category = "deaths",
		// 	regex = "^(.+) has struck down (.+)$",
		// 	replace = function(matches) {
		// 		local attacker = matches[1];
		// 		local victim = matches[2];
		// 		return attacker + " » " + ::MSU.Text.colorRed("STRUCK DOWN") + " " + victim;
		// 	}
		// });

		// this.addPattern({
		// 	category = "deaths",
		// 	regex = "^(.+) is struck down$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		return entity + " » " + ::MSU.Text.colorRed("STRUCK DOWN");
		// 	}
		// });

		// // Theriantrophy infection patterns
		// this.addPattern({
		// 	category = "status",
		// 	regex = "^(.+) is infected with ([a-z]+)$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		local infection = matches[2];
		// 		return entity + " » " + ::MSU.Text.colorRed("INFECTED WITH " + infection.toupper());
		// 	}
		// });

		// // Hit part and damage patterns - FIX for injury pattern
		// this.addPattern({
		// 	category = "injuries",
		// 	regex = "^(.+)'s (.+) is hit for \\[b\\](.+)\\[/b\\] damage$",
		// 	replace = function(matches) {
		// 		local entity = matches[1];
		// 		local bodyPart = matches[2];
		// 		local damage = matches[3];
		// 		return entity + " » " + bodyPart + " hit for " + ::MSU.Text.colorRed(damage);
		// 	}
		// });

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
			return "injuries";
		} else if (_text.find(" killed ") != null || _text.find(" died") != null || _text.find(" struck down") != null) {
			return "deaths";
		} else {
			return null;
			// return "status";
		}
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

	function action(_entity, _targetEntity, _action, _roll, _roll_target) {
		local success = _roll < _roll_target;
		local action =
			::Const.UI.getColorizedEntityName(_entity)
			+ " "
			+ success("[" + _action + "]", _roll < _roll_target)
			+ " "
			+ roll(_roll, _roll_target)
			+ " "
			+ (_targetEntity != null ? " " + ::Const.UI.getColorizedEntityName(_targetEntity) : "");
		::Tactical.EventLog.logEx(action);
	},

	function success(_text, _success) {
		return _success ? ::MSU.Text.colorGreen(_text) : ::MSU.Text.colorRed(_text)
	},

	function roll(_roll, _roll_target) {
		return "» (" + _roll + " < " + ::Math.min(95, ::Math.max(5, _roll_target)) + ")";
	}

}

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
}

::ModBetterLegendsCombatLog.Log.logNextRound <- function(_turn) {
	::Tactical.EventLog.logEx("\n===== ROUND " + _turn + "\n");
};
