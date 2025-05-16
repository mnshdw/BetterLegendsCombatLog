::ModBetterLegendsCombatLog.HooksMod.hook("scripts/ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function (q) {

	q.initNextRound = @(__original) function() {
		::ModBetterLegendsCombatLog.Log.logNextRound(this.m.CurrentRound+1);
		__original();
	}

});
