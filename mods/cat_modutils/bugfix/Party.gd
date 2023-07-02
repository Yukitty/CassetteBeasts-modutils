extends "res://global/save_state/Party.gd"


func remap_partner_tapes() -> void:
	var randomize_dog_bootleg: bool = DLC.mods_by_id.cat_modutils.setting_randomize_dog_bootleg

	for partner in partners:
		if is_partner_unlocked(partner.partner_id):
			continue

		# BUGFIX: Set partner levels for new custom partners
		if initial_partner_levels.has(partner.partner_id):
			partner.level = initial_partner_levels[partner.partner_id]

		assert (partner.tapes.size() == 1)
		if partner.tapes.size() != 1:
			continue
		var tape = partner.tapes[0]
		if tape.form == partner.partner_signature_species:
			tape.form = MonsterForms.get_species_mapping(tape.form)

			# BUGFIX: Instead of clearing bootleg types, make a fresh copy of the array
			# (I have no idea what replacing the array with an empty one is trying to fix, aaa.)
			tape.type_override.duplicate()

			# Force Barkley to have an Ice bootleg if needed,
			# because previous official releases messed it up. Guh.
			if partner.partner_id == "dog" and tape.type_override.empty():
				tape.type_override = [preload("res://data/elemental_types/ice.tres")]

			# Randomize bootleg types to match the type_rand_seed
			# An original idea of the mod author, sorry if it trips anyone up!
			if MonsterForms.type_rand_seed != null and not tape.type_override.empty() and (partner.partner_id != "dog" or randomize_dog_bootleg):
				tape.type_override = [BattleSetupUtil.random_type(Random.new(int(MonsterForms.type_rand_seed) ^ partner.name.hash()))]

			tape.type_native = MonsterForms.get_type_mapping(tape.form)
			tape.assign_initial_stickers(true)
