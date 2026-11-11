class_name Kit extends RefCounted
## Dispatcher: sends basic attacks, skills and ultimates to the script for the current evolution line.
## Scaling is per LINE (Data.line_scaling), never per typing.

const NAMES := [
	["Charge", "Frothy Spit", "Froth Barrage"], ["Sharp Claw", "Pepper Breath", "Intense Burner"],
	["Sharp Claws", "Great Horns", "Nova Blast"], ["Cyborg Claw", "Tether Claw", "Giga Blaster"],
	["Dramon Killers", "Great Tornado", "Terra Force"],
]
const NAMES_VEE := [
	["Petite Headbutt", "Petite Tackle", "Charge!"], ["Vee Jab", "Boom-Boom Punch", "Vee Headbutt"],
	["V-Punch", "Victory Sign", "V-Nova Blast"], ["V-Claws", "V-Stream", "Dragon Impulse"],
	["Victory Sword", "Victory Stream", "Ray of Victory!"],
]
const NAMES_GARU := [
	["Tackle", "Frothy Spit", "Mammal Spiral"], ["Wild Claws", "Petite Horn", "Blue Blaster"],
	["Frost Fangs", "Beast Blitz", "Howling Blaster"], ["Beast Knuckles", "Circle Kick", "Kaiser Nail"],
	["Garuru Tomahawk", "Cocytus Breath", "Grand Cross Freezer"],
]
const NAMES_SLAYER := [
	["Petite Horn", "Petite Flame", "Baby Flame"], ["Draco Claws", "Baby Breath", "G Shurunen"],
	["Dramon Claws", "Blue Flare Breath", "G Shurunen II"], ["Dramon Claws", "Sonic Lance", "Blaze Sonic Breath"],
	["Fragarach", "Tenryu Slash", "Shoryu Slash"],
]
const NAMES_DIABLO := [
	["Light Charge", "Venomous Spit", "Virus Gaze"], ["Crazy Bullet", "Crazy Beam", "Crazy Giggle"],
	["Data Crasher", "Virus Spiral", "Misconnecting"], ["Cocoon Attack", "Single Shot", "Hell's Grenade"],
	["Paradise Lost", "Connection Terminated", "Catastrophe Cannon"],
]

static func names(line: int, stage: int) -> Array:
	match line:
		6: return NAMES_VEE[stage]
		1: return NAMES_GARU[stage]
		11: return NAMES_DIABLO[stage]
		4: return NAMES_SLAYER[stage]
	return NAMES[stage]

static func has_kit(line: int) -> bool:
	return line in [1, 2, 4, 6, 11]

static func extra(g) -> String:
	match g.P.line:
		6: return KitVeemon.extra(g)
		1: return KitGaruru.extra(g)
		11: return KitDiablo.extra(g)
		4: return KitSlayer.extra(g)
	return ""

static func tick(g, dt: float) -> void:
	match g.P.line:
		6: KitVeemon.tick(g, dt)
		1: KitGaruru.tick(g, dt)
		11: KitDiablo.tick(g, dt)
		4: KitSlayer.tick(g, dt)

static func basic(g) -> void:
	match g.P.line:
		2: KitAgumon.basic(g)
		6: KitVeemon.basic(g)
		1: KitGaruru.basic(g)
		11: KitDiablo.basic(g)
		4: KitSlayer.basic(g)

static func skill(g, n: int) -> void:
	match g.P.line:
		2: KitAgumon.skill(g, n)
		6: KitVeemon.skill(g, n)
		1: KitGaruru.skill(g, n)
		11: KitDiablo.skill(g, n)
		4: KitSlayer.skill(g, n)

static func draw(g) -> void:
	if g.P.line == 4: KitSlayer.draw(g)
