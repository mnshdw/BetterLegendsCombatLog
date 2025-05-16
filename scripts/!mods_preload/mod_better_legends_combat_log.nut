::ModBetterLegendsCombatLog <- {
	ID = "mod_better_legends_combat_log",
	Name = "Better Legends Combat Log",
	Version = "1.0.2",
	Enabled = true,
	ShowCombatRolls = true,
	ShowMoraleChanges = true,
	ShowMisses = true,
	// Color for successful hits.
	ColorHit = "#135213",
	// Color for misses.
	ColorMiss = "#666666",
	// Color for deaths and struck downs.
	ColorDeath = "#8e44ad",
	ColorVeryPositiveValue = "#32cd32",
	ColorPositiveValue = "#135213",
	ColorNegativeValue = "#8f1e1e",
	ColorVeryNegativeValue = "#d92e2e",
	// Color for hits to armor.
	ColorArmor = "#666666",
	// Color for hits to the body/head.
	ColorHealth = "#900c3f"
};

::ModBetterLegendsCombatLog.HooksMod <- ::Hooks.register(::ModBetterLegendsCombatLog.ID, ::ModBetterLegendsCombatLog.Version, ::ModBetterLegendsCombatLog.Name);

::ModBetterLegendsCombatLog.HooksMod.require("mod_msu >= 1.2.7", "mod_modern_hooks >= 0.5.4");

::ModBetterLegendsCombatLog.HooksMod.queue(">mod_msu", ">mod_legends", ">mod_sellswords", ">mod_ROTUC", function() {
	::ModBetterLegendsCombatLog.Mod <- ::MSU.Class.Mod(::ModBetterLegendsCombatLog.ID, ::ModBetterLegendsCombatLog.Version, ::ModBetterLegendsCombatLog.Name);

	// Register with MSU so people know to update
	::ModBetterLegendsCombatLog.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/mnshdw/BetterLegendsCombatLog");

	::ModBetterLegendsCombatLog.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);

	// MSU config page
	local page = ::ModBetterLegendsCombatLog.Mod.ModSettings.addPage("Better Legends Combat Log");
	local settingEnabled = page.addBooleanSetting(
		"Enabled",
		true,
		"Enabled",
		"When enabled, the mod will try to improve the combat log in a variety of ways. If you encounter any issues, or want vanilla behaviour, just disable this."
	);
	settingEnabled.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.Enabled = _value;
	});
	page.addDivider("divider");
	local settingShowCombatRolls = page.addBooleanSetting(
		"ShowCombatRolls",
		true,
		"Show Combat Rolls",
		"When enabled, the combat log will show the combat rolls for attacks."
	);
	settingShowCombatRolls.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.ShowCombatRolls = _value;
	});
	local settingShowMoraleChanges = page.addBooleanSetting(
		"ShowMoraleChanges",
		true,
		"Show Morale Changes",
		"When enabled, the combat log will show morale changes for both allies and enemies."
	);
	settingShowMoraleChanges.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.ShowMoraleChanges = _value;
	});
	local settingShowMisses = page.addBooleanSetting(
		"ShowMisses",
		true,
		"Show Misses",
		"When enabled, the combat log will show skills that miss their target(s)."
	);
	settingShowMoraleChanges.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.ShowMisses = _value;
	});

	::include("mod_better_legends_combat_log/log.nut");
	::include("mod_better_legends_combat_log/ui.nut");
	::include("mod_better_legends_combat_log/hooks/ui/screens/tactical/modules/turn_sequence_bar.nut");
	::include("mod_better_legends_combat_log/scripts/ui/screens/tactical/tactical_screen.nut");

}, ::Hooks.QueueBucket.Normal);