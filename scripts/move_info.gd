class_name MoveInfo extends RefCounted
## Move names and descriptions shown in the hub (Mercenary Digimon tab). Keyed by roster index.

const MOVES := {
	4: [
		[["Petite Horn", "Horn hit, close range. Each enemy hit stacks +3% Attack (up to 10) and refreshes the buff timer."], ["Petite Flame", "Small flame that explodes on the first enemy or terrain, damaging nearby enemies. 20% chance to burn."], ["Baby Flame", "3 second continuous fire breath that burns enemies and refreshes your attack buff timers. Long range."]],
		[["Draco Claws", "Claw hit, close range. Stacks +3% Attack per enemy hit (up to 10) and refreshes the timer."], ["Baby Breath", "3 second continuous fire breath that burns enemies and refreshes your attack buff timers. Mid range."], ["G Shurunen", "Shoots 3 draconic energy spheres in a row. Each sphere that deals damage makes the next one hit harder."]],
		[["Dramon Claws", "Heavy claw slash, close range. Stacks +3% Attack per enemy hit (up to 10) and refreshes the timer."], ["Blue Flare Breath", "3 second intense blue flame breath that burns enemies and refreshes your attack buff timers. Mid range."], ["G Shurunen II", "3 large spheres in a row that explode on terrain or the first enemy. Each sphere that deals damage empowers the next."]],
		[["Dramon Claws", "Heavy claw slash, close range. Stacks +3% Attack per enemy hit (up to 10) and refreshes the timer."], ["Sonic Lance", "Rapid piercing dash with the back blade. Leaves a draconic trail that damages enemies every 0.3s. Refreshes your attack buff timers."], ["Blaze Sonic Breath", "3 second blazing blue breath that burns enemies. You can move at full speed while using it. Refreshes your attack buff timers."]],
		[["Fragarach", "Greatsword cut, mid range. Stacks +3% Attack per enemy hit (up to 15) and refreshes the timer."], ["Tenryu Slash", "Spinning strike with a short dash that leaves a draconic trail damaging enemies every 0.3s. Refreshes your attack buff timers."], ["Shoryu Slash", "Violent sword flames in a long cone. Burns enemies and refreshes your attack buff timers."]],
	],
	1: [
		[["Tackle", "Throws its whole body at the enemy. Close range."], ["Frothy Spit", "Acidic bubbles in a cone. Lowers the defense of every enemy hit."], ["Mammal Spiral", "Spirals forward with its horn, piercing every enemy in the path and lowering their defense."]],
		[["Wild Claws", "Quick claw slash. Close range."], ["Petite Horn", "Dash that damages every enemy it passes through. Each enemy hit gives a short Attack and Defense boost."], ["Blue Blaster", "Fires a blue fire spiral that burns the target for a few seconds."]],
		[["Frost Fangs", "Icy bite. 5% chance to freeze (stun) the target."], ["Beast Blitz", "Dash forward with a shockwave on arrival. Recast within 3s to dash back to where you started for a second hit. 10% chance per hit to lower defense."], ["Howling Blaster", "A bigger, stronger blue fire spiral that burns the target."]],
		[["Beast Knuckles", "Punches with a 10% chance to lower defense."], ["Circle Kick", "Jumping backflip kick in front of you. Recast within 5s, twice, to dash forward and kick again."], ["Kaiser Nail", "Jumps and clashes golden knuckles for a shockwave around you. 15% chance to stun."]],
		[["Garuru Tomahawk", "Wide slash with huge claws."], ["Cocytus Breath", "Large piercing frost beam. 20% chance to freeze for 3 seconds."], ["Grand Cross Freezer", "Fires 20 missiles at random nearby enemies over about 2s with no movement slowdown. Each has a 10% chance to freeze; all can hit one target."]],
	],
	2: [
		[["Charge", "Rams the enemy with its whole body. Close range."], ["Frothy Spit", "Acidic bubbles in a cone, mid range."], ["Froth Barrage", "Stronger bubble cone that also lowers defense."]],
		[["Sharp Claw", "Quick claw slash. Close range."], ["Pepper Breath", "Fireball that explodes on the first enemy hit (area damage, chance to Burn). No explosion if it misses."], ["Intense Burner", "2.5s stream of flames in a cone. Gives you a defense and regeneration boost."]],
		[["Sharp Claws", "Claw slash. Close range."], ["Great Horns", "Dash that knocks enemies up and stuns them briefly (bosses are stunned for half as long)."], ["Nova Blast", "Short charge, then a giant fireball that explodes on impact or at max range. Boosts your defense."]],
		[["Cyborg Claw", "Heavy metal arm swing."], ["Tether Claw", "Launches a claw that pulls normal enemies to you and lowers defense. Bosses only lose defense."], ["Giga Blaster", "Two missiles that explode, burn targets, and boost your defense."]],
		[["Dramon Killers", "Giant claw slashes."], ["Great Tornado", "Invulnerable spiral dash that hits all enemies nearby."], ["Terra Force", "Charges a giant fire sphere that explodes on the first enemy, burns, and boosts your attack and defense."]],
	],
	6: [
		[["Petite Headbutt", "Quick headbutt. Close range."], ["Petite Tackle", "Dash through enemies. Each enemy hit lowers this skill's cooldown."], ["Charge!", "Dash that stops at the first enemy and sends out a shockwave that spreads damage to nearby enemies."]],
		[["Vee Jab", "Fast jab. Close range."], ["Boom-Boom Punch", "Heavy punch with 3 charges. Chained punches hit harder."], ["Vee Headbutt", "Long dash that stops at the first enemy with a damaging shockwave."]],
		[["V-Punch", "Forceful punch. Close range."], ["Victory Sign", "+30% attack speed for 8s and +30% damage on your next Ultimate."], ["V-Nova Blast", "V-shaped energy arrow that explodes on the first enemy or terrain. Each enemy hit gives attack speed and lowers this ultimate's cooldown."]],
		[["V-Claws", "Sharp claw slashes."], ["V-Stream", "Leaps and rains dark energy in a cone. Each enemy hit raises your attack speed."], ["Dragon Impulse", "Roars, then dashes through enemies, stripping defense from survivors and gaining attack speed and crit per enemy hit."]],
		[["Victory Sword", "Wide slash with the excalibur in its arm."], ["Victory Stream", "Blinks forward, then dashes through nearby enemies, hitting harder for each one. Invulnerable during the move."], ["Ray of Victory!", "Hold R to charge, release to fire a long V beam. More charge means more damage. Each enemy hit boosts attack speed and crit."]],
	],
	11: [
		[["Light Charge", "Tackles the enemy. Close range."], ["Venomous Spit", "Toxin cone that poisons enemies."], ["Virus Gaze", "Instant thin beam that pierces every enemy in a line."]],
		[["Crazy Bullet", "Projectile. 25% chance to lower Wisdom by 10%."], ["Crazy Beam", "Instant piercing dark beam, mid range."], ["Crazy Giggle", "Fires 3 projectiles that deal damage on impact and again in an explosion."]],
		[["Data Crasher", "Tentacles pierce through enemies. 15% chance to lower Wisdom."], ["Virus Spiral", "Spin attack around you. Each enemy hit lowers your ultimate cooldown."], ["Misconnecting", "Long dash while channeling dark energy. Explodes on the first enemy, or where the dash ends, in a wide blast."]],
		[["Cocoon Attack", "Propels forward in a tackle. 20% chance to lower Wisdom."], ["Single Shot", "Quick blast that explodes on impact."], ["Hell's Grenade", "Hold R to charge (raises Intelligence for 5s), release for a bigger, stronger blast."]],
		[["Paradise Lost", "Palm strike. 30% chance to lower Wisdom and lowers your ultimate cooldown."], ["Connection Terminated", "+Intelligence and attack speed for 8s, and +30% damage on your next Ultimate."], ["Catastrophe Cannon", "Charges, then fires a wide piercing beam."]],
	],
}

static func get_moves(line: int, stage: int) -> Array:
	if not MOVES.has(line): return []
	return MOVES[line][stage]
