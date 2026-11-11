extends Node
## Global game data. Autoload name: Data

const ATTR_BEATS := {"Vaccine": "Virus", "Virus": "Data", "Data": "Vaccine"}
const TYPE_BEATS := {
	"Fire": ["Ice", "Plant"], "Light": ["Dark"], "Dark": ["Light"], "Water": ["Fire", "Earth"],
	"Plant": ["Earth", "Water"], "Steel": ["Ice", "Thunder"], "Thunder": ["Water", "Wind"],
	"Wind": ["Plant", "Steel"], "Earth": ["Steel", "Thunder"], "Ice": ["Water", "Wind"],
}
const TYPE_COLORS := {
	"Light": "#f5e27a", "Dark": "#6b3fa0", "Fire": "#ff7a3d", "Water": "#3d9bff", "Ice": "#9fe8ff",
	"Plant": "#5ccb5f", "Steel": "#aab3c2", "Thunder": "#ffd23d", "Wind": "#8ff0c8", "Earth": "#a77a4b",
}
# hp, atk, def, int, wis, crit, aspd
const CLASS_BASE := {
	"Tank": [150, 9, 14, 7, 9, 5, 1.0], "Caster": [90, 6, 6, 15, 11, 8, 1.0],
	"Attacker": [105, 15, 8, 6, 7, 8, 1.05], "Support": [110, 8, 9, 11, 13, 5, 1.0],
	"Balanced": [115, 11, 10, 10, 10, 6, 1.0], "Speedster": [70, 12, 4, 8, 4, 15, 1.35],
}
const CLASS_PASSIVE := {
	"Tank": ["Stalwart", "def", 0.10], "Caster": ["Overflow", "int", 0.10], "Attacker": ["Fervor", "atk", 0.08],
	"Support": ["Gentle Aura", "wis", 0.10], "Balanced": ["Even Keel", "hp", 0.06], "Speedster": ["Quickstep", "spd", 0.10],
}
const ROSTER := [
	{"cls": "Balanced", "attr": "Data", "type": "Steel", "stages": ["Wanyamon", "Gaomon", "Gaogamon", "MachGaogamon", "MirageGaogamon"]},
	{"cls": "Balanced", "attr": "Data", "type": "Ice", "stages": ["Tsunomon", "Gabumon", "Garurumon", "WereGarurumon", "MetalGarurumon"]},
	{"cls": "Tank", "attr": "Vaccine", "type": "Fire", "stages": ["Koromon", "Agumon", "Greymon", "MetalGreymon", "WarGreymon"]},
	{"cls": "Tank", "attr": "Virus", "type": "Ice", "stages": ["Tsunomon", "BlackGabumon", "BlackGarurumon", "BlackWereGarurumon", "BlackMetalGarurumon"]},
	{"cls": "Attacker", "attr": "Data", "type": "Fire", "stages": ["Babydmon", "Dracomon", "Coredramon", "Wingdramon", "Slayerdramon"]},
	{"cls": "Attacker", "attr": "Virus", "type": "Fire", "stages": ["Koromon", "BlackAgumon", "Greymon (Blue)", "MetalGreymon (Blue)", "BlackWarGreymon"]},
	{"cls": "Speedster", "attr": "Vaccine", "type": "Light", "stages": ["DemiVeemon", "Veemon", "Veedramon", "AeroVeedramon", "UlforceVeedramon"]},
	{"cls": "Support", "attr": "Vaccine", "type": "Light", "stages": ["Kokomon", "Lopmon", "Turuiemon", "Antylamon", "Cherubimon (Good)"]},
	{"cls": "Support", "attr": "Data", "type": "Wind", "stages": ["Viximon", "Renamon", "Kyubimon", "Taomon", "Sakuyamon"]},
	{"cls": "Support", "attr": "Vaccine", "type": "Plant", "stages": ["Budmon", "Lalamon", "Sunflowmon", "Lilamon", "Rosemon"]},
	{"cls": "Caster", "attr": "Virus", "type": "Dark", "stages": ["Kokomon", "Lopmon", "Wendigomon", "Antylamon", "Cherubimon (Evil)"]},
	{"cls": "Caster", "attr": "Virus", "type": "Dark", "stages": ["Kuramon", "Keramon", "Chrysalimon", "Infermon", "Diablomon"]},
]
const BOSSES := {
	"reppamon": {"name": "Reppamon", "attr": "Data", "type": "Wind", "hp": 1500, "atk": 14, "xp": 700},
	"sangloupmon": {"name": "Sangloupmon", "attr": "Virus", "type": "Dark", "hp": 2600, "atk": 19, "xp": 1200},
	"angemon": {"name": "Angemon", "attr": "Vaccine", "type": "Light", "hp": 3600, "atk": 22, "xp": 0},
	"devimon": {"name": "Devimon", "attr": "Virus", "type": "Dark", "hp": 6000, "atk": 30, "xp": 0},
}
const RARITIES := ["Common", "Uncommon", "Rare", "Legendary"]
# [rarity, name, description, effects]  (effect keys are explained in README.md)
const CARD_DEFS := [
	[0, "Red Memory Boost!", "Increase Attack by 5%.", {"atk": 0.05}],
	[0, "Blue Memory Boost!", "Increase Intelligence by 5%.", {"int": 0.05}],
	[0, "Green Memory Boost!", "Increase Defense by 5%.", {"def": 0.05}],
	[0, "Yellow Memory Boost!", "Increase Wisdom by 5%.", {"wis": 0.05}],
	[0, "Purple Memory Boost!", "Gain 5% more EXP from defeated enemies.", {"exp": 0.05}],
	[0, "Black Memory Boost!", "Increase maximum HP by 5%.", {"hp": 0.05}],
	[0, "Defense Plug-In C", "Reduce incoming physical damage by 5%.", {"dr_phys": 0.05}],
	[0, "Offense Plug-In A", "Increase basic attack damage by 5%.", {"basic": 0.05}],
	[0, "High-Speed Plug-In D", "Increase Attack Speed by 5%.", {"aspd": 0.05}],
	[0, "Digivolution Plug-In S", "Gain 5% more EXP while below Champion level.", {"exp_low": 0.05}],
	[0, "Digivolution Plug-In D", "Restore 5% of maximum HP upon digivolving.", {"evo_heal": 0.05}],
	[0, "A Delicate Plan", "Reduce damage taken from environmental hazards by 10%.", {"hazard": 0.10}],
	[0, "Offense Plug-In B", "Increase special damage by 5%.", {"spec": 0.05}],
	[0, "Defense Plug-In B", "Reduce incoming special damage by 5%.", {"dr_spec": 0.05}],
	[0, "Digivice", "Increase movement speed by 5%.", {"spd": 0.05}],
	[1, "Mist Memory Boost!", "Increase Wisdom by 8% and elemental resistance by 5%.", {"wis": 0.08, "dr_elem": 0.05}],
	[1, "Pride Memory Boost!", "Deal 8% more damage while above 80% HP.", {"self_hi80": 0.08}],
	[1, "Offensive Plug-In A", "Increase Critical Chance by 3%.", {"crit": 3.0}],
	[1, "Reinforcing Memory Boost!", "Increase maximum HP by 8%.", {"hp": 0.08}],
	[1, "Gravity Crush", "Deal 10% more damage to enemies above 75% HP.", {"hp_hi75": 0.10}],
	[1, "Heaven's Gate", "Deal 10% more damage to Dark-typed enemies.", {"vs_Dark": 0.10}],
	[1, "Darkness Wave", "Deal 10% more damage to Light-typed enemies.", {"vs_Light": 0.10}],
	[1, "Emergency Program Shutdown", "When HP falls below 30%, gain 10% Defense.", {"def_lo30": 0.10}],
	[1, "Smashed Potatoes", "Deal 12% more damage to enemies below 25% HP.", {"lo25": 0.12}],
	[1, "Iron-Fisted Onslaught", "Increase physical damage by 8%, but reduce Attack Speed by 3%.", {"phys": 0.08, "aspd": -0.03}],
	[1, "Ultimate Connection!", "Increase special damage by 8%, but reduce physical damage by 3%.", {"spec": 0.08, "phys": -0.03}],
	[1, "Digivolution Plug-In E", "Increase damage by 8% for 10 seconds after digivolving.", {"evo_dmg": 0.08}],
	[1, "Offensive Plug-In C", "Increase Critical Damage by 10%.", {"crit_dmg": 0.10}],
	[1, "Defense Plug-In A", "Reduce damage received from bosses by 5%.", {"dr_boss": 0.05}],
	[1, "High-Speed Plug-In A", "Increase movement speed by 8%.", {"spd": 0.08}],
	[2, "Crimson Blaze", "Increase Fire damage dealt by 12%.", {"t_Fire": 0.12}],
	[2, "Plasma Stake", "Increase Thunder damage dealt by 12%.", {"t_Thunder": 0.12}],
	[2, "Positron Laser", "Increase Critical Damage by 15%.", {"crit_dmg": 0.15}],
	[2, "Beast Cyclone", "Deal 10% more damage to Champion and higher-tier enemies.", {"champ": 0.10}],
	[2, "Atomic Inferno", "Deal 8% more damage to bosses.", {"boss": 0.08}],
	[2, "Hell's Gate", "Deal 15% more damage to enemies affected by a status ailment.", {"status": 0.15}],
	[2, "Purge of the Millennium", "Deal 12% more damage to enemies of a higher level than you.", {"higher": 0.12}],
	[2, "Brave Shield", "Reduce damage received by 12% while below 40% HP.", {"dr_lo40": 0.12}],
	[2, "Jack Raid", "Defeating an elite enemy restores 3% maximum HP and grants 5% Attack for 10 seconds.", {"jack": 1.0}],
	[2, "Trump Sword", "Increase physical damage by 15%, but take 5% more physical damage.", {"phys": 0.15, "dr_phys": -0.05}],
	[2, "Cocytus Breath", "Increase Ice damage by 18%.", {"t_Ice": 0.18}],
	[2, "Darkness Claw", "Deal 15% more damage while below 50% HP.", {"self_lo50": 0.15}],
	[2, "Breath of the Gods", "Reduce incoming special damage by 15% and increase Wisdom by 5%.", {"dr_spec": 0.15, "wis": 0.05}],
	[2, "Supreme Connection!", "Exploiting an elemental weakness increases damage dealt by 15% for 5 seconds.", {"weak": 0.15}],
	[2, "Nail Bone", "Critical hits restore 1% maximum HP, once every 2 seconds.", {"nail": 0.01}],
]
const ITEM_DEFS := [
	[0, "HP Capsule", "Restore 22% of maximum HP.", {"heal": 0.22}],
	[0, "SP Capsule", "Special meter not implemented: reduces current skill cooldowns by 15%.", {"sp": 0.15}],
	[0, "Medical Spray", "Restore 15% HP to nearby teammates (solo: heals you).", {"team": 0.15}],
	[0, "Bandage Kit", "Remove Bleed and restore 8% HP.", {"bandage": true}],
	[0, "Antidote", "Remove Poison and prevent reapplication for 3 seconds.", {"antidote": true}],
	[0, "Energy Disk", "Gain 5% attack speed for 8 seconds.", {"buff": {"aspd": 0.05}, "dur": 8.0}],
	[0, "Power Charge", "Deal +5% damage for 8 seconds.", {"buff": {"dmg": 0.05}, "dur": 8.0}],
	[0, "Defense Plug-In", "Receive 5% less damage for 8 seconds.", {"buff": {"dr": 0.05}, "dur": 8.0}],
	[1, "Speed Charge", "Gain 8% movement speed for 10 seconds.", {"buff": {"spd": 0.08}, "dur": 10.0}],
	[1, "Critical Boost", "Gain +5 percentage points of critical chance for 8 seconds.", {"buff": {"crit": 5.0}, "dur": 8.0}],
	[1, "Elemental Booster", "Increase the damage of your current element by 8% for 8 seconds.", {"buff": {"elem": 0.08}, "dur": 8.0}],
	[1, "Full HP Capsule", "Restore 42% of maximum HP.", {"heal": 0.42}],
	[1, "Team Recovery Spray", "Restore 22% HP to nearby teammates (solo: heals you).", {"team": 0.22}],
	[1, "Status Recovery Disk", "Remove all removable negative status effects from yourself.", {"cleanse": true}],
	[2, "Corruption Suppressant", "Stop Corruption-zone damage for 6 seconds. Does not protect from enemies.", {"suppress": 6.0}],
	[2, "Revival Disk", "Revive a downed teammate with 20% HP (needs multiplayer).", {"revive": true}],
	[2, "Overclock Capsule", "Gain 10% attack speed and 5% movement speed for 10 seconds.", {"buff": {"aspd": 0.10, "spd": 0.05}, "dur": 10.0}],
	[2, "Boss Buster", "Deal +10% damage to bosses for 8 seconds.", {"buff": {"boss": 0.10}, "dur": 8.0}],
	[2, "Emergency Barrier", "Create a shield equal to 15% of maximum HP for 8 seconds.", {"shield": 0.15}],
	[2, "DigiCore Elixir", "Restore 35% HP and gain 5% damage reduction for 8 seconds.", {"heal": 0.35, "buff": {"dr": 0.05}, "dur": 8.0}],
]
const EQUIP_DEFS := [
	[0, "Broad Rapier", "Damage dealt +3%.", {"dmg": 0.03}],
	[0, "Shade Mace", "Physical damage +3%.", {"phys": 0.03}],
	[0, "Crystal Sword", "Special damage +3%.", {"spec": 0.03}],
	[0, "Bronze Knuckles", "Attack speed +2%.", {"aspd": 0.02}],
	[0, "Hunter's Bow", "Critical chance +1%.", {"crit": 1.0}],
	[0, "Iron Claws", "Damage to enemies above 80% HP +4%.", {"hp_hi80": 0.04}],
	[0, "Battle Spear", "Damage to bosses +3%.", {"boss": 0.03}],
	[0, "Thunder Rod", "Thunder damage +4%.", {"t_Thunder": 0.04}],
	[0, "Flame Edge", "Fire damage +4%.", {"t_Fire": 0.04}],
	[0, "Frost Dagger", "Ice damage +4%.", {"t_Ice": 0.04}],
	[1, "Obelisk", "Critical chance +2%.", {"crit": 2.0}],
	[1, "Excalibur", "Damage dealt +5%.", {"dmg": 0.05}],
	[1, "Balmunc", "Physical damage +5%.", {"phys": 0.05}],
	[1, "Dragon's Breath", "Special damage +5%.", {"spec": 0.05}],
	[1, "Light Bringer", "Light damage +6%.", {"t_Light": 0.06}],
	[1, "Dark Reaper", "Dark damage +6%.", {"t_Dark": 0.06}],
	[1, "Twin Fangs", "Attack speed +4%.", {"aspd": 0.04}],
	[1, "Slayer's Edge", "Damage to enemies below 30% HP +6%.", {"lo30": 0.06}],
	[1, "War Drum", "Damage +4% for 5 seconds after defeating an enemy; 8-second internal cooldown.", {"war_drum": 0.04}],
	[1, "Champion's Crest", "Damage to Champion-or-higher enemies +5%.", {"champ": 0.05}],
	[2, "Heaven's Blade", "Damage dealt +7%.", {"dmg": 0.07}],
	[2, "Demon Crusher", "Damage to bosses +8%.", {"boss": 0.08}],
	[2, "Critical Lens", "Critical damage +10%.", {"crit_dmg": 0.10}],
	[2, "Dragon Slayer", "Damage to Dragon-type enemies +8% (placeholder: 10% of enemies are Dragon-type).", {"dragon": 0.08}],
	[2, "Elemental Core", "Elemental damage +7%.", {"elem": 0.07}],
	[2, "Berserker Claw", "Damage +8% while below 40% HP.", {"self_lo40": 0.08}],
	[2, "Spell Amplifier", "Special damage +8%.", {"spec": 0.08}],
	[2, "Predator's Fang", "Damage +6% against enemies affected by a status effect.", {"status": 0.06}],
	[2, "Overclock Module", "Attack speed +6%.", {"aspd": 0.06}],
	[3, "Omega Blade", "Damage dealt +10%.", {"dmg": 0.10}],
	[0, "Broad Shield", "Maximum HP +3%.", {"hp": 0.03}],
	[0, "Leather Armor", "Physical damage received -3%.", {"dr_phys": 0.03}],
	[0, "Shade Helm", "Special damage received -3%.", {"dr_spec": 0.03}],
	[0, "Iron Greaves", "Movement speed +2%.", {"spd": 0.02}],
	[0, "Mist Cape", "Water damage received -4%.", {"td_Water": 0.04}],
	[0, "Thunder Sign", "Thunder damage received -4%.", {"td_Thunder": 0.04}],
	[0, "Sylph Aegis", "Wind damage received -4%.", {"td_Wind": 0.04}],
	[0, "Antidote Charm", "Poison duration -8% (no poison yet).", {"poison_dur": 0.08}],
	[0, "Flame Guard", "Fire damage received -4%.", {"td_Fire": 0.04}],
	[0, "Ice Guard", "Ice damage received -4%.", {"td_Ice": 0.04}],
	[1, "Bane Shield", "Maximum HP +5%.", {"hp": 0.05}],
	[1, "Dark Helm", "Special damage received -5%.", {"dr_spec": 0.05}],
	[1, "Valkyrie Armor", "Physical damage received -5%.", {"dr_phys": 0.05}],
	[1, "Guardian's Belt", "Defense +4%.", {"def": 0.04}],
	[1, "Recovery Circuit", "Healing received +5%.", {"heal_in": 0.05}],
	[1, "Vitality Chip", "Maximum HP +6%.", {"hp": 0.06}],
	[1, "Aegis Ring", "Damage received from bosses -5%.", {"dr_boss": 0.05}],
	[1, "Evasion Boots", "Dodge invulnerability window +3%.", {"evade": 0.03}],
	[1, "Purity Seal", "Duration of negative status effects -12% (applies to chain stuns).", {"stat_dur": 0.12}],
	[1, "Resilience Plate", "Damage received -4% while above 70% HP.", {"dr_hi70": 0.04}],
	[2, "Gorgon Armor", "Physical damage received -7%.", {"dr_phys": 0.07}],
	[2, "Fortress Core", "Maximum HP +9%.", {"hp": 0.09}],
	[2, "Mystic Mantle", "Special damage received -7%.", {"dr_spec": 0.07}],
	[2, "Lifeline Circuit", "Healing received +8%.", {"heal_in": 0.08}],
	[2, "Elemental Barrier", "Elemental damage received -8%.", {"dr_elem": 0.08}],
	[2, "Quickstep Module", "Movement speed +5%.", {"spd": 0.05}],
	[2, "Phoenix Insignia", "Once per expedition, survive a lethal hit with 10% HP.", {"phoenix": 1.0}],
	[2, "Corruption Filter", "Damage over time from the Corruption zone -10%.", {"hazard": 0.10}],
	[2, "Sentinel Emblem", "Damage received -6% near a teammate (needs multiplayer).", {"sentinel": 0.06}],
	[3, "Aegis of Yggdrasil", "Damage received -10%.", {"dr": 0.10}],
]
var cards: Array = []
var items: Array = []
var equip := {}

func _ready() -> void:
	for c in CARD_DEFS: cards.append({"rar": c[0], "name": c[1], "desc": c[2], "fx": c[3]})
	for e in EQUIP_DEFS: equip[e[1]] = {"rar": e[0], "name": e[1], "desc": e[2], "fx": e[3]}
	for i in ITEM_DEFS:
		var d := {"rar": i[0], "name": i[1], "desc": i[2]}
		for k in i[3]: d[k] = i[3][k]
		items.append(d)

func roll_rarity(w: Array) -> int:
	var q := randf()
	var acc := 0.0
	for i in w.size():
		acc += w[i]
		if q < acc: return i
	return 0

func pick(pool: Array, w: Array) -> Dictionary:
	var r := roll_rarity(w)
	var p := pool.filter(func(x): return x.rar == r)
	if p.is_empty(): p = pool
	return p.pick_random().duplicate(true)

func random_card(w: Array) -> Dictionary: return pick(cards, w)
func random_item(w: Array) -> Dictionary: return pick(items, w)
func random_equip(w: Array) -> Dictionary: return pick(equip.values(), w)

const BIOMES := [
	{"name": "Withered Forest", "types": ["Plant", "Dark"], "color": "#16261d"},
	{"name": "Freezeland", "types": ["Ice", "Water"], "color": "#1a2634"},
	{"name": "Scorched Savanna", "types": ["Earth", "Fire"], "color": "#2e2418"},
	{"name": "Dead File City", "types": ["Steel", "Thunder"], "color": "#1f1e2e"},
	{"name": "Black Tide Marsh", "types": ["Water", "Wind"], "color": "#132a2e"},
	{"name": "Ash Volcano", "types": ["Fire", "Dark"], "color": "#2a181a"},
]

# Damage scaling is decided by the evolution LINE, never by typing. Only the Diablomon line (11) uses Intelligence so far.
const LINE_SCALING := {11: "int"}

func line_scaling(line: int) -> String:
	return LINE_SCALING.get(line, "phys")

func type_mult(a_attr: String, a_type: String, d_attr: String, d_type: String) -> float:
	var m := 1.0
	if ATTR_BEATS.get(a_attr, "") == d_attr: m *= 1.25
	elif ATTR_BEATS.get(d_attr, "") == a_attr: m *= 0.8
	if d_type in TYPE_BEATS.get(a_type, []): m *= 1.5
	elif a_type in TYPE_BEATS.get(d_type, []): m *= 0.67
	return m

func xp_needed(level: int) -> int:
	return 28 + level * level * 6 + maxi(0, level - 5) * maxi(0, level - 5) * 20

func stage_for_level(level: int) -> int:
	if level >= 15: return 4
	if level >= 12: return 3
	if level >= 6: return 2
	if level >= 3: return 1
	return 0

func damage(base: float, mult: float, defense: float, crit_mult: float = 1.0) -> float:
	return base * mult * crit_mult * 40.0 / (40.0 + defense)
