::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function(q) {

	q.create = @(__original) function() {
		__original();
	}

	q.connectUI = @(__original) function(_host) {
		__original(_host);
		if (::ModBetterLegendsCombatLog.Enabled && m.JSHandle != null) {
			q.changeFontFamily(::ModBetterLegendsCombatLog.FontFamily);
		}
	}

	q.getCurrentFontFamily <- function() {
		return ::ModBetterLegendsCombatLog.FontFamily;
	}

	q.changeFontFamily <- function(_fontFamily) {
		if (m.JSHandle != null) {
			m.JSHandle.asyncCall("changeFontFamily", _fontFamily);
		}
	}

	q.log_newline = @(__original) function() {
		if (!::ModBetterLegendsCombatLog.Enabled) {
			__original();
			return;
		}
	}

	q.log = @(__original) function(_text) {
		if (!::ModBetterLegendsCombatLog.Enabled) {
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
		if (!::ModBetterLegendsCombatLog.Enabled) {
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
