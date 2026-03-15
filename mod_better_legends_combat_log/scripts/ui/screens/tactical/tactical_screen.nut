::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/topbar/tactical_screen_topbar_event_log", function (q) {

	q.create = @(__original) function () {
		__original();
	}

	q.connectUI = @(__original) function (_host) {
		__original(_host);
		if (::ModBetterLegendsCombatLog.Enabled && this.m.JSHandle != null) {
			this.changeFontFamily(::ModBetterLegendsCombatLog.FontFamily);
			this.changeFontSize(::ModBetterLegendsCombatLog.FontSize);
			this.setVisibility(!::ModBetterLegendsCombatLog.HideCombatLog);
		}
	}

	q.getCurrentFontFamily <- function () {
		return ::ModBetterLegendsCombatLog.FontFamily;
	}

	q.getCurrentFontSize <- function () {
		return ::ModBetterLegendsCombatLog.FontSize;
	}

	q.changeFontFamily <- function (_fontFamily) {
		if (this.m.JSHandle != null) {
			this.m.JSHandle.asyncCall("changeFontFamily", _fontFamily);
		}
	}

	q.changeFontSize <- function (_fontSize) {
		if (this.m.JSHandle != null) {
			this.m.JSHandle.asyncCall("changeFontSize", _fontSize);
		}
	}

	q.setVisibility <- function (_visible) {
		if (this.m.JSHandle != null) {
			this.m.JSHandle.asyncCall("setVisibility", _visible);
		}
	}

	q.log_newline = @(__original) function () {
		if (!::ModBetterLegendsCombatLog.Enabled) {
			__original();
			return;
		}
	}

	q.log = @(__original) function (_text) {
		if (!::ModBetterLegendsCombatLog.Enabled) {
			__original(_text);
			return;
		}
		local new_text = ::ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.DamageBuffered) {
			if (!::ModBetterLegendsCombatLog.Log.damageTimerScheduled) {
				::ModBetterLegendsCombatLog.Log.damageTimerScheduled = true;
				::Time.scheduleEvent(::TimeUnit.Real, 50, function (_jsHandle) {
					::ModBetterLegendsCombatLog.Log.flushDamageBuffer(_jsHandle);
				}, this.m.JSHandle);
			}
			return;
		}
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		::ModBetterLegendsCombatLog.Log.flushDamageBuffer(this.m.JSHandle);
		this.m.JSHandle.asyncCall("log", new_text);
	}

	q.logEx = @(__original) function (_text) {
		if (!::ModBetterLegendsCombatLog.Enabled) {
			__original(_text);
			return;
		}
		local new_text = ::ModBetterLegendsCombatLog.Log.intercept(_text);
		if (new_text == ::ModBetterLegendsCombatLog.Log.DamageBuffered) {
			if (!::ModBetterLegendsCombatLog.Log.damageTimerScheduled) {
				::ModBetterLegendsCombatLog.Log.damageTimerScheduled = true;
				::Time.scheduleEvent(::TimeUnit.Real, 50, function (_jsHandle) {
					::ModBetterLegendsCombatLog.Log.flushDamageBuffer(_jsHandle);
				}, this.m.JSHandle);
			}
			return;
		}
		if (new_text == ::ModBetterLegendsCombatLog.Log.SuppressOutput) {
			return;
		}
		::ModBetterLegendsCombatLog.Log.flushDamageBuffer(this.m.JSHandle);
		__original(new_text);
	}

	q.clear = @(__original) function () {
		::ModBetterLegendsCombatLog.Log.damageBuffer = [];
		::ModBetterLegendsCombatLog.Log.damageTimerScheduled = false;
		__original();
	}

});
