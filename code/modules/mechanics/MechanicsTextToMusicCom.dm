TYPEINFO(/obj/item/mechanics/text_to_music)
	mats = list("metal"      = 20,
				"conductive" = 10,
				"crystal"    = 10)

/obj/item/mechanics/text_to_music // modified from playable_piano.dm and PR #21051 (Player Piano Notes Rework V2)
	name = "Text to Music Component"
	desc = "Converts text to music."
	icon_state = "comp_text_to_music"
	cabinet_banned = TRUE // no walking music machines
	var/datum/text_to_music/mech_comp/music_player = null

	New()
		..()

		src.music_player = new(src)

		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_INPUT, "play", PROC_REF(mechcompPlay))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_INPUT, "set notes", PROC_REF(mechcompNotes))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_INPUT, "set timing", PROC_REF(mechcompTiming))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_INPUT, "set instrument", PROC_REF(mechcompInstrument))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_INPUT, "stop", PROC_REF(mechcompStop))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_INPUT, "reset", PROC_REF(mechcompReset))

		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "play", PROC_REF(mechcompConfigPlay))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "set notes", PROC_REF(mechcompConfigNotes))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "set timing", PROC_REF(mechcompConfigTiming))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "set instrument", PROC_REF(mechcompConfigInstrument))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "stop", PROC_REF(mechcompConfigStop))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "reset", PROC_REF(mechcompConfigReset))
		SEND_SIGNAL(src, COMSIG_MECHCOMP_ADD_CONFIG, "view errors", PROC_REF(mechcompConfigViewErrors))

	get_desc()
		. = ..() // Please don't remove this again, thanks.
		. += "<br>[SPAN_NOTICE("Instrument: [src.music_player.instrument_name] | Timing: [src.music_player.timing] | Has Notes: [length(src.music_player.note_input) ? "Yes" : "No"]")]"

	// ----------------------------------------------------------------------------------------------------

	// requires it's own proc because else the mechcomp input will be taken as first argument of ready_piano()
	proc/mechcompPlay(var/datum/mechanicsMessage/input)
		if (src.anchored)
			src.music_player.ready_piano()

	proc/mechcompNotes(var/datum/mechanicsMessage/input)
		if (input.signal)
			src.music_player.set_notes(input.signal)

	proc/mechcompTiming(var/datum/mechanicsMessage/input)
		var/new_timing = text2num(input.signal)
		if (new_timing)
			src.music_player.set_timing(new_timing)

	proc/mechcompInstrument(var/datum/mechanicsMessage/input)
		if (input.signal)
			src.music_player.set_instrument(input.signal)

	proc/mechcompStop(var/datum/mechanicsMessage/input)
		if (src.music_player.is_busy)
			src.music_player.is_stop_requested = TRUE

	proc/mechcompReset(var/datum/mechanicsMessage/input)
		src.music_player.reset_piano(0)

	// ----------------------------------------------------------------------------------------------------

	proc/mechcompConfigPlay(obj/item/W as obj, mob/user as mob)
		if (src.anchored)
			src.music_player.ready_piano()

	proc/mechcompConfigNotes(obj/item/W as obj, mob/user as mob)
		var/given_notes = tgui_input_text(user, "Input notes to play.", "Set Notes", src.music_player.note_input)
		src.music_player.set_notes(given_notes)

	proc/mechcompConfigTiming(obj/item/W as obj, mob/user as mob)
		// `tgui_input_number` behaves oddly when dealing with floats
		// so I'm using the text input instead, unless timing is counted is centiseconds
		var/new_timing = tgui_input_text(
			user,
			"Input a new timing between [src.music_player.MIN_TIMING] and [src.music_player.MAX_TIMING] seconds.",
			"Set Timing",
			src.music_player.timing
		)
		new_timing = text2num(new_timing)
		if (new_timing)
			src.music_player.set_timing(new_timing)

	proc/mechcompConfigInstrument(obj/item/W as obj, mob/user as mob)
		var/new_instrument = tgui_input_list(user, "Input new instrument.", "Set Instrument", src.music_player.allow_list, src.music_player.instrument_sound_path)
		src.music_player.set_instrument(new_instrument)

	proc/mechcompConfigStop(obj/item/W as obj, mob/user as mob)
		if (src.music_player.is_busy)
			src.music_player.is_stop_requested = TRUE

	proc/mechcompConfigReset(obj/item/W as obj, mob/user as mob)
		src.music_player.reset_piano(0)

	proc/mechcompConfigViewErrors(obj/item/W as obj, mob/user as mob)
		if (length(src.music_player.error_messages) > 0)
			var/message = jointext(src.music_player.error_messages, "<br><hr>")
			tgui_message(user, message, "T2M Error Messages")

	// ----------------------------------------------------------------------------------------------------

	disposing() //just to clear up ANY funkiness
		src.music_player.reset_piano(1)
		..()

	attackby(obj/item/W, mob/user)
		if(iswrenchingtool(W) && src.anchored && src.music_player.is_busy)
			src.music_player.is_stop_requested = TRUE

		return ..()

	update_icon(var/active) //1: active, 0: inactive
		if (active)
			src.icon_state = "comp_text_to_music1"
			return
		src.icon_state = "comp_text_to_music"
		return
