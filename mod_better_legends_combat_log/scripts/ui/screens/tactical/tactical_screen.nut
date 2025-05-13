::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {
	q.create = @(__original) function() {
		::logInfo("BLCL: create");
		__original();
	};

	q.destroy = @(__original) function() {
		::logInfo("BLCL: destroy");
		__original();
	};

	q.log_newline = @(__original) function() {
		// We want to control this ourselves
	}

	q.log = @(__original) function(_text) {
		::logInfo("BLCL: log=" + _text);
		m.JSHandle.asyncCall("log", _text);
	}

	q.logEx = @(__original) function(_text) {
		::logInfo("BLCL: logEx=" + _text);
		__original(_text);
	}

	// logEx
	// clear

});