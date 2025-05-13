::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {
	q.create = @(__original) function() {
		::logInfo("Creating Event Log");
		__original();
	};

	q.destroy = @(__original) function() {
		::logInfo("Destroying Event Log");
		__original();
	};

	q.log_newline = @(__original) function() {
		// We want to control this ourselves
	}

	// logEx
	// log
	// clear


});