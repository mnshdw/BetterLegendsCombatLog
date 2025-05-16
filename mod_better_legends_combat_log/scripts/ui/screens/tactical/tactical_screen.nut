::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {

	q.create = @(__original) function() {
		local patterns = [
			"(\\[color=#[0-9a-f]{3,6}\\].+\\[/color\\]) uses (.+) and (hits|misses) (\\[color=#[0-9a-f]{3,6}\\].+\\[/color\\]) \\(Chance: (\\d{1,2}), Rolled: (\\d{1,2})\\)",
			"(\\[color=#[0-9a-f]{3,6}\\].+\\[/color\\]) uses ([\\w ]+) and (hits|misses) (\\[color=#[0-9a-f]{3,6}\\].+\\[/color\\]) \\(Chance: (\\d{1,2}), Rolled: (\\d{1,2})\\)",
			"(\\[color=#[0-9a-f]{3,6}\\].+\\[/color\\]) uses ([\\w\\s]+) and (hits|misses) (\\[color=#[0-9a-f]{3,6}\\].+\\[/color\\]) \\(Chance: (\\d{1,2}), Rolled: (\\d{1,2})\\)"
		];
		local text1 = "[color=#1e468f]Blue Horror[/color] uses Claws and hits [color=#8f1e1e]Ancient Auxiliary[/color] (Chance: 52, Rolled: 6)";
		local text2 = "[color=#8f1e1e]Haust Jotunn[/color] uses Horn Rush and misses [color=#1e468f]Manhunter Veteran Handgonner[/color] (Chance: 63, Rolled: 93)";
		foreach (i, pattern in patterns) {
			local re = regexp(pattern);
			local match1 = re.capture(text1);
			local match2 = re.capture(text2);
			::logInfo(pattern + (match1 != null ? " matches " : " doesn't match ") + text1);
			::logInfo(pattern + (match2 != null ? " matches " : " doesn't match ") + text2);
		}

		__original();
	}

	q.log_newline = @(__original) function() {
		// We want to control this ourselves
		// m.JSHandle.asyncCall("log", "\n");
	}

	q.log = @(__original) function(_text) {
		local new_text = ::ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		m.JSHandle.asyncCall("log", new_text);
	}

	q.logEx = @(__original) function(_text) {
		local new_text = ::ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		__original(new_text);
	}

	// clear

});