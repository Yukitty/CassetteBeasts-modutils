extends "res://global/save_state/Party.gd"


func remap_partner_tapes() -> void:
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

			# BUGFIX: Only clear bootleg in type randomizer runs
			if MonsterForms.type_rand_seed != null:
				tape.type_override = []

			tape.type_native = MonsterForms.get_type_mapping(tape.form)
			tape.assign_initial_stickers(true)
