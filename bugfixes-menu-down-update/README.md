# Dark Area Expedition (Godot 4.3+ starter project)

Open: Godot Project Manager > Import > select `project.godot`. Press F5.
Everything is drawn with placeholder circles (type = fill color, attribute = outline). This project was written
without being run in Godot, so expect to fix a few small errors; the Output/Debugger panels show the exact line.

## Controls
WASD move, mouse aim, hold left click or J attack, Q skill, R ultimate (Koromon line only), Space dodge,
E digivolve, 1-3 use item, right-click an item/card slot to drop it, Esc abandon run, L debug level-up.

## Files
- scripts/data.gd      autoload `Data`: type chart, roster, bosses, option cards, items, equipment (all your lists)
- scripts/save.gd      autoload `Save`: Digicore, owned/equipped equipment, .mon files (user://save.json)
- scripts/run_state.gd autoload `Run`: settings passed hub -> expedition, last result
- scripts/hub.gd       Mallow hub (built in code). scenes/hub.tscn is the main scene
- scripts/run.gd       the expedition (map gen, nights, corruption, combat, bosses, rewards). scenes/run.tscn
- scripts/kit.gd       Koromon > WarGreymon moves
- scripts/hud.gd       in-run HUD and minimap

## Effect keys used in data.gd (all values are additive fractions unless noted)
Stats: hp atk def int wis aspd spd (x stat), crit (percentage points).
Damage dealt: dmg phys spec basic boss champ status higher hp_hi75 hp_hi80 lo25 lo30 vs_Dark vs_Light dragon
self_hi80 self_lo50 self_lo40 elem t_<Type> crit_dmg weak(5s after exploiting a weakness) war_drum(5s after a kill, 8s cd).
Damage taken: dr dr_phys dr_spec dr_boss dr_elem td_<Type> dr_hi70 dr_lo40 def_lo30 (negative = take more).
Other: exp exp_low evo_heal evo_dmg(10s) hazard heal_in stat_dur evade jack nail phoenix.
No effect yet (need systems that do not exist): poison_dur, sentinel (needs teammates).
Team items (Medical Spray, Team Recovery Spray) heal you in solo; Revival Disk needs multiplayer and is not consumed.

## Boss moves
- Reppamon: fan, light pillars, dash.
- Sangloupmon: ring, 3 big blades that heal him, dash, fan, volley.
- Angemon: fan, light pillars, golden fist, ring, chains of light (2s stun if you stand in the closing ring), volley.
- Devimon: ring, dark claw (drags you to him), volley, dash, fan; a poison DoT patch appears every 30s of the fight and stays.

## Added in this version
- scripts/kit_veemon.gd : DemiVeemon > Veemon > V-dramon > AeroV-dramon > UlforceV-dramon moves (roster index 6)
- scripts/bosses.gd     : Reppamon, Sangloupmon, Angemon, Devimon move sets + hazards (beams, chains, claws, trails, corruption)
- kit.gd dispatches to kit_veemon.gd for line 6; run.gd boss_ai() now calls Bosses; hud.gd shows the new skill names
- scripts/kit_garuru.gd : Tsunomon > MetalGarurumon moves (roster index 1, physical)
- scripts/kit_diablo.gd : Kuramon > Diablomon moves (roster index 11, intelligence)
- Light of Heaven / Dark Area Influence beams now erupt 1 second after their warning (same rate as before)

## Latest additions
- Title screen (scenes/title.tscn, scripts/title.gd) is now the main scene; hub has tabs (scripts/hub.gd) with move descriptions from scripts/move_info.gd
- Inventory in expedition: press I (input action `inventory`), use/drop items and cards, read descriptions
- Dodge uses a stamina bar (locks until full when emptied); shorter dodge
- 6 overworld mini bosses per night (gold ring, "MINI BOSS"): ~13x HP, ~3x damage, ~21x XP, drop 4 items/cards
- Basic enemies no longer heal while returning home; leash radius 480 (camps) / 380 (roaming groups)
- Final night circle radius 520 (was 300)
- scripts/kit_slayer.gd : Babydmon > Slayerdramon (roster index 4, physical). Esc now asks "End the run?" Yes/No (game pauses)
- Scaling rule: damage stat is decided by the evolution LINE (Data.LINE_SCALING; only line 11, Diablomon, is Intelligence). Typing only gives
  type advantage and elemental bonuses to moves tagged "elem" (Fire/Ice/etc. damage cards and equipment apply on top of the line's scaling).
- scripts/kit_agumon.gd : Koromon line moves moved out of kit.gd; kit.gd is now only the dispatcher
- Esc (or I) opens the pause menu: Inventory (equipment / items / option cards, drop items & cards), Moves (click an evolution tier), Quit Game (Yes/No)
- Death rules (scripts/run.gd on_zero_hp/update_down): single player = instant death -> respawn at a safe spot (50% HP); in night-boss / False Drasil fights
  one revive per fight at 50% HP where you fell, then the expedition is lost. Multiplayer rules (45s downed, 5s hold-click revive, last player dies = loss) are coded but dormant until Run.players > 1.
- Items stack to 3 per slot. Boss/mini-boss HP x Run.players. Bosses are stunned for half as long and statuses wear off twice as fast on them.
- Boss AI: weighted random move choice by distance, random strafing/keeping range, extra pressure on stunned/statused/low-HP/healing targets (scripts/bosses.gd)
