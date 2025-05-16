::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {

	q.log_newline = @(__original) function() {
		// We want to control this ourselves
		// m.JSHandle.asyncCall("log", "\n");
	}

	q.log = @(__original) function(_text) {
		local new_text = ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		m.JSHandle.asyncCall("log", new_text);
	}

	q.logEx = @(__original) function(_text) {
		local new_text = ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		__original(ModBetterLegendsCombatLog.Log.intercept(new_text));
	}

	// clear

});