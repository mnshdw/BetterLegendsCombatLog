::ModBetterLegendsCombatLog <- {
	ID = "mod_better_legends_combat_log",
	Name = "Better Legends Combat Log",
	Version = "1.0.9",
	Enabled = true,
	FontFamily = "Fira",
	FontSize = "100",
	CombatRollsStyle = "Compact",
	ShowMoraleChanges = true,
	ShowMisses = true,
	// Color for successful hits.
	ColorHit = "#135213",
	// Color for misses.
	ColorMiss = "#666666",
	// Color for deaths and struck downs.
	ColorDeath = "#8e44ad",
	ColorVeryPositiveValue = "#033303",
	ColorPositiveValue = "#135213",
	ColorNegativeValue = "#8f1e1e",
	ColorVeryNegativeValue = "#d92e2e",
	// Color for hits to armor.
	ColorArmor = "#666666",
	// Color for hits to the body/head.
	ColorHealth = "#900c3f"
};

// Converts from "19,82,19,1.0" to "#135213"
::ModBetterLegendsCombatLog.ToHex <- function(_color) {
	local arr = split(_color, ",");
	local r = format("%02x", arr[0].tointeger());
	local g = format("%02x", arr[1].tointeger());
	local b = format("%02x", arr[2].tointeger());
	return "#" + r + g + b;
}

// Converts from "#135213" to "19,82,19,1.0"
::ModBetterLegendsCombatLog.ToRgba <- function(_hex) {
	// Simple lookup table for hex digits using strings
	local hexMap = {
		"0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
		"a": 10, "b": 11, "c": 12, "d": 13, "e": 14, "f": 15,
	};
	local r = hexMap[_hex.slice(1, 2)] * 16 + hexMap[_hex.slice(2, 3)];
	local g = hexMap[_hex.slice(3, 4)] * 16 + hexMap[_hex.slice(4, 5)];
	local b = hexMap[_hex.slice(5, 6)] * 16 + hexMap[_hex.slice(6, 7)];
	return format("%d,%d,%d,1.0", r, g, b);
}

::ModBetterLegendsCombatLog.HooksMod <- ::Hooks.register(::ModBetterLegendsCombatLog.ID, ::ModBetterLegendsCombatLog.Version, ::ModBetterLegendsCombatLog.Name);

::ModBetterLegendsCombatLog.HooksMod.require("mod_msu >= 1.2.7", "mod_modern_hooks >= 0.5.4");

::ModBetterLegendsCombatLog.HooksMod.queue(">mod_msu", ">mod_legends", ">mod_sellswords", ">mod_ROTUC", ">mod_PoV", function() {
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

	page.addDivider("1");

	local settingCombatRollsStyle = page.addEnumSetting(
		"CombatRollsStyle",
		"Compact",
		["Compact", "Vanilla", "Disabled"],
		"Combat rolls style",
		"Changes the style of combat rolls shown in the battle log.\n\nCompact: x<y\nVanilla: Chance: x, Rolled: y\nDisabled: combat rolls will not be shown"
	);
	settingCombatRollsStyle.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.CombatRollsStyle = _value;
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
	settingShowMisses.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.ShowMisses = _value;
	});

	page.addDivider("2");

	local settingFontFamily = page.addEnumSetting(
		"FontFamily",
		"Fira",
		["Fira", "Julia", "JetBrains"],
		"Font Family",
		"Changes the font family of the text shown in the battle log.\n\nFira: Default font, easiest to read at both low and high resolutions.\n\nJulia: Slightly thinner font, should look a bit cleaner for most people, likely worse with high resolution displays.\n\nJetBrains: thinnest font so not for everyone, should look nicer for people with good eyesight."
	);
	settingFontFamily.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.FontFamily = _value;
		if ("Tactical" in ::getroottable() && ::Tactical != null && "EventLog" in ::Tactical && ::Tactical.EventLog != null) {
			::Tactical.EventLog.changeFontFamily(_value);
		}
	});

	local settingFontSize = page.addEnumSetting(
		"FontSize",
		"100",
		["80", "90", "100", "110", "120", "130", "140"],
		"Font Size",
		"Changes the font size of the text shown in the battle log. Values are in percent relative to the default size."
	);
	settingFontSize.addCallback(function(_value) {
		::ModBetterLegendsCombatLog.FontSize = _value;
		if ("Tactical" in ::getroottable() && ::Tactical != null && "EventLog" in ::Tactical && ::Tactical.EventLog != null) {
			::Tactical.EventLog.changeFontSize(_value);
		}
	});

	page.addDivider("3");

	local colorCallback = function(_color) {
		::ModBetterLegendsCombatLog[this.getID()] = ::ModBetterLegendsCombatLog.ToHex(_color);
	}
	local colorHitRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorHit);
	local colorHitSetting = page.addColorPickerSetting("ColorHit", colorHitRgba, "Color for successful hits");
	colorHitSetting.addCallback(colorCallback);
	local colorMissRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorMiss);
	local colorMissSetting = page.addColorPickerSetting("ColorMiss", colorMissRgba, "Color for misses");
	colorMissSetting.addCallback(colorCallback);
	local colorDeathRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorDeath);
	local colorDeathSetting = page.addColorPickerSetting("ColorDeath", colorDeathRgba, "Color for deaths and struck downs");
	colorDeathSetting.addCallback(colorCallback);
	local colorVeryPositiveValueRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorVeryPositiveValue);
	local colorVeryPositiveValueSetting = page.addColorPickerSetting("ColorVeryPositiveValue", colorVeryPositiveValueRgba, "Color for Confident morale");
	colorVeryPositiveValueSetting.addCallback(colorCallback);
	local colorPositiveValueRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorPositiveValue);
	local colorPositiveValueSetting = page.addColorPickerSetting("ColorPositiveValue", colorPositiveValueRgba, "Color for Steady morale");
	colorPositiveValueSetting.addCallback(colorCallback);
	local colorNegativeValueRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorNegativeValue);
	local colorNegativeValueSetting = page.addColorPickerSetting("ColorNegativeValue", colorNegativeValueRgba, "Color for Wavering / Breaking morale");
	colorNegativeValueSetting.addCallback(colorCallback);
	local colorVeryNegativeValueRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorVeryNegativeValue);
	local colorVeryNegativeValueSetting = page.addColorPickerSetting("ColorVeryNegativeValue", colorVeryNegativeValueRgba, "Color for Fleeing morale");
	colorVeryNegativeValueSetting.addCallback(colorCallback);
	local colorArmorRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorArmor);
	local colorArmorSetting = page.addColorPickerSetting("ColorArmor", colorArmorRgba, "Color for hits to armor");
	colorArmorSetting.addCallback(colorCallback);
	local colorHealthRgba = ::ModBetterLegendsCombatLog.ToRgba(::ModBetterLegendsCombatLog.ColorHealth);
	local colorHealthSetting = page.addColorPickerSetting("ColorHealth", colorHealthRgba, "Color for hits to the body/head");
	colorHealthSetting.addCallback(colorCallback);

	::ModBetterLegendsCombatLog.HasPoV <- ::Hooks.hasMod("mod_PoV");

	::include("mod_better_legends_combat_log/log.nut");
	::include("mod_better_legends_combat_log/pov.nut");
	::include("mod_better_legends_combat_log/ui.nut");
	::include("mod_better_legends_combat_log/hooks/ui/screens/tactical/modules/turn_sequence_bar.nut");
	::include("mod_better_legends_combat_log/scripts/ui/screens/tactical/tactical_screen.nut");

}, ::Hooks.QueueBucket.Normal);
