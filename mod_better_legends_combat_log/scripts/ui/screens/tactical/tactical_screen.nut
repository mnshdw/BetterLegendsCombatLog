::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {

	q.log_newline = @(__original) function() {
		// We want to control this ourselves
		// m.JSHandle.asyncCall("log", "\n");
	}

	q.log = @(__original) function(_text) {
		m.JSHandle.asyncCall("log", ModBetterLegendsCombatLog.Log.intercept(_text));
	}

	q.logEx = @(__original) function(_text) {
		__original(ModBetterLegendsCombatLog.Log.intercept(_text));
	}

	// clear

});