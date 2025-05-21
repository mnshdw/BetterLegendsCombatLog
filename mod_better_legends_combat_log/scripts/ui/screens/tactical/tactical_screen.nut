::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {

	q.create = @(__original) function() {
		__original();
	}

	q.log_newline = @(__original) function() {
		if (!::ModBetterLegendsTooltips.Enabled) {
			__original();
			return;
		}
		// We want to control this ourselves
		// m.JSHandle.asyncCall("log", "\n");
	}

	q.log = @(__original) function(_text) {
		if (!::ModBetterLegendsTooltips.Enabled) {
			__original(_text);
			return;
		}
		local new_text = ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		m.JSHandle.asyncCall("log", new_text);
	}

	q.logEx = @(__original) function(_text) {
		if (!::ModBetterLegendsTooltips.Enabled) {
			__original(_text);
			return;
		}
		local new_text = ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		__original(new_text);
	}

	// clear

});