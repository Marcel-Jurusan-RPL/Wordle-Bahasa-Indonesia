extends Control

# ------------------------------------------------------
# WORDLE - BAHASA INDONESIA
# Daftar kata (14.000+ kata resmi KBBI) ada di WordList.gd
# ------------------------------------------------------

const MAX_ROWS := 6
const WORD_LEN := 5

const TILE_SIZE := 56.0
const POP_SCALE := 1.1
const FLIP_DURATION := 0.15
const FLIP_STAGGER := 0.22

const WIN_BASE_POINTS := 10
const WIN_STREAK_BONUS := 2
const LOSE_PENALTY := 15

# Warna hijau/kuning/abu-abu (hasil tebakan) SELALU sama di kedua tema,
# persis seperti Wordle asli.
const COLOR_CORRECT := Color("538d4e")
const COLOR_PRESENT := Color("b59f3b")
const COLOR_ABSENT := Color("3a3a3c")

# Warna-warna ini berubah tergantung mode gelap/terang, lihat _apply_theme().
var COLOR_BG := Color("121213")
var COLOR_EMPTY := Color("1a1a1b")
var COLOR_BORDER := Color("3a3a3c")
var COLOR_FILLED_BORDER := Color("565758")
var COLOR_KEY_DEFAULT := Color("818384")

var is_dark_mode: bool = true

var target_word: String = ""
var current_row: int = 0
var current_guess: Array = []
var game_over: bool = false
var is_animating: bool = false
var tutorial_visible: bool = true
var game_started: bool = false

var score: int = 0
var best_score: int = 0
var streak: int = 0
var best_streak: int = 0

var tile_panels: Array = []
var tile_labels: Array = []
var key_buttons: Dictionary = {}

var bg_rect: ColorRect
var title_label: Label
var message_label: Label
var score_label: Label
var theme_toggle_btn: Button
var tutorial_overlay: Control


func _ready() -> void:
	randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg_rect = bg

	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	title_label = Label.new()
	title_label.text = "WORDLE - BAHASA INDONESIA"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	main_vbox.add_child(title_label)

	_build_hud(main_vbox)

	message_label = Label.new()
	message_label.text = "Tebak kata 5 huruf dalam 6 kali percobaan!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	message_label.custom_minimum_size = Vector2(360, 0)
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", _theme_message_color())
	main_vbox.add_child(message_label)

	var grid_center := CenterContainer.new()
	main_vbox.add_child(grid_center)

	var grid := GridContainer.new()
	grid.columns = WORD_LEN
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid_center.add_child(grid)

	for r in range(MAX_ROWS):
		var row_panels := []
		var row_labels := []
		for c in range(WORD_LEN):
			var panel := Panel.new()
			panel.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			panel.pivot_offset = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
			panel.add_theme_stylebox_override("panel", _make_tile_style(COLOR_EMPTY, COLOR_BORDER))

			var label := Label.new()
			label.text = ""
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.add_theme_font_size_override("font_size", 26)
			label.add_theme_color_override("font_color", Color.WHITE)
			panel.add_child(label)

			grid.add_child(panel)
			row_panels.append(panel)
			row_labels.append(label)
		tile_panels.append(row_panels)
		tile_labels.append(row_labels)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	main_vbox.add_child(spacer)

	_build_keyboard(main_vbox)

	_update_hud()
	_apply_theme()

	# Papan "Cara Bermain" ditambahkan TERAKHIR supaya tampil di atas semua elemen lain.
	tutorial_overlay = _build_tutorial_overlay()
	add_child(tutorial_overlay)


func _build_hud(parent: VBoxContainer) -> void:
	var hud := HBoxContainer.new()
	hud.alignment = BoxContainer.ALIGNMENT_CENTER
	hud.add_theme_constant_override("separation", 14)
	parent.add_child(hud)

	theme_toggle_btn = Button.new()
	theme_toggle_btn.text = "🌙"
	theme_toggle_btn.custom_minimum_size = Vector2(36, 32)
	theme_toggle_btn.focus_mode = Control.FOCUS_NONE
	theme_toggle_btn.tooltip_text = "Ganti mode terang/gelap"
	theme_toggle_btn.pressed.connect(_on_theme_toggle_pressed)
	hud.add_child(theme_toggle_btn)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", Color("f4c95d"))
	hud.add_child(score_label)

	var help_btn := Button.new()
	help_btn.text = "?"
	help_btn.custom_minimum_size = Vector2(28, 28)
	help_btn.focus_mode = Control.FOCUS_NONE
	help_btn.tooltip_text = "Cara Bermain"
	help_btn.pressed.connect(_on_help_pressed)
	hud.add_child(help_btn)


func _update_hud() -> void:
	score_label.text = "Skor: %d" % score


func _on_theme_toggle_pressed() -> void:
	is_dark_mode = not is_dark_mode
	_apply_theme()


func _apply_theme() -> void:
	if is_dark_mode:
		COLOR_BG = Color("121213")
		COLOR_EMPTY = Color("1a1a1b")
		COLOR_BORDER = Color("3a3a3c")
		COLOR_FILLED_BORDER = Color("565758")
		COLOR_KEY_DEFAULT = Color("818384")
		theme_toggle_btn.text = "🌙"
	else:
		COLOR_BG = Color("ffffff")
		COLOR_EMPTY = Color("ffffff")
		COLOR_BORDER = Color("d3d6da")
		COLOR_FILLED_BORDER = Color("878a8c")
		COLOR_KEY_DEFAULT = Color("d3d6da")
		theme_toggle_btn.text = "☀️"

	var main_text_color := _theme_text_color()

	bg_rect.color = COLOR_BG
	title_label.add_theme_color_override("font_color", main_text_color)

	# Kotak huruf: kotak yang SUDAH terungkap (hijau/kuning/abu-abu) dibiarkan
	# apa adanya. Hanya kotak kosong/yang sedang diisi yang ikut berganti tema.
	for r in range(tile_panels.size()):
		for c in range(tile_panels[r].size()):
			var panel: Panel = tile_panels[r][c]
			var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
			var bgc: Color = style.bg_color if style else COLOR_EMPTY
			if bgc == COLOR_CORRECT or bgc == COLOR_PRESENT or bgc == COLOR_ABSENT:
				continue
			var has_text: bool = tile_labels[r][c].text != ""
			var border: Color = COLOR_FILLED_BORDER if has_text else COLOR_BORDER
			panel.add_theme_stylebox_override("panel", _make_tile_style(COLOR_EMPTY, border))
			tile_labels[r][c].add_theme_color_override("font_color", main_text_color)

	# Tombol keyboard: yang belum punya warna hasil tebakan ikut berganti tema.
	for letter in key_buttons.keys():
		var btn: Button = key_buttons[letter]
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		var bgc: Color = style.bg_color if style else COLOR_KEY_DEFAULT
		if bgc == COLOR_CORRECT or bgc == COLOR_PRESENT or bgc == COLOR_ABSENT:
			continue
		_style_key_button(btn, COLOR_KEY_DEFAULT, main_text_color)


func _theme_text_color() -> Color:
	return Color.WHITE if is_dark_mode else Color("1a1a1b")


func _theme_message_color() -> Color:
	return Color("cccccc") if is_dark_mode else Color("333333")


func _build_tutorial_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(340, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("1e1e20")
	card_style.corner_radius_top_left = 14
	card_style.corner_radius_top_right = 14
	card_style.corner_radius_bottom_left = 14
	card_style.corner_radius_bottom_right = 14
	card_style.content_margin_left = 24
	card_style.content_margin_right = 24
	card_style.content_margin_top = 22
	card_style.content_margin_bottom = 22
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "Cara Bermain"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var rule1 := Label.new()
	rule1.text = "Tebak kata 5 huruf dalam 6 kali percobaan. Ketik huruf, lalu tekan ENTER."
	rule1.autowrap_mode = TextServer.AUTOWRAP_WORD
	rule1.add_theme_font_size_override("font_size", 14)
	rule1.add_theme_color_override("font_color", Color("dddddd"))
	vbox.add_child(rule1)

	var legend := [
		["Hijau", "huruf benar & posisinya tepat", COLOR_CORRECT],
		["Kuning", "huruf ada, tapi posisinya salah", COLOR_PRESENT],
		["Abu-abu", "huruf tidak ada di kata", COLOR_ABSENT],
	]
	for entry in legend:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var swatch := Panel.new()
		swatch.custom_minimum_size = Vector2(26, 26)
		swatch.add_theme_stylebox_override("panel", _make_tile_style(entry[2], entry[2]))
		row.add_child(swatch)
		var desc := Label.new()
		desc.text = "%s: %s" % [entry[0], entry[1]]
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color("dddddd"))
		row.add_child(desc)
		vbox.add_child(row)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var score_info := Label.new()
	score_info.text = "Menang -> skor naik & streak bertambah (makin panjang streak, makin besar bonus poin).\nKalah -> skor berkurang & streak kembali ke 0.\nKumpulkan skor setinggi dan streak sepanjang mungkin!"
	score_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	score_info.add_theme_font_size_override("font_size", 13)
	score_info.add_theme_color_override("font_color", Color("f4c95d"))
	vbox.add_child(score_info)

	var start_btn := Button.new()
	start_btn.text = "Mulai Bermain"
	start_btn.custom_minimum_size = Vector2(0, 44)
	start_btn.focus_mode = Control.FOCUS_NONE
	start_btn.pressed.connect(_on_tutorial_close_pressed)
	vbox.add_child(start_btn)

	return overlay


func _on_help_pressed() -> void:
	tutorial_overlay.visible = true
	tutorial_visible = true


func _on_tutorial_close_pressed() -> void:
	tutorial_overlay.visible = false
	tutorial_visible = false
	if not game_started:
		game_started = true
		start_new_game()


func _make_tile_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	return style


func _build_keyboard(parent: VBoxContainer) -> void:
	var rows := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
	for i in range(rows.size()):
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 4)
		var center := CenterContainer.new()
		center.add_child(hbox)
		parent.add_child(center)

		if i == 2:
			var enter_btn := Button.new()
			enter_btn.text = "ENTER"
			enter_btn.custom_minimum_size = Vector2(58, 44)
			enter_btn.focus_mode = Control.FOCUS_NONE
			enter_btn.pressed.connect(_on_enter_pressed)
			hbox.add_child(enter_btn)

		for letter in rows[i]:
			var btn := Button.new()
			btn.text = letter
			btn.custom_minimum_size = Vector2(34, 44)
			btn.pressed.connect(_on_letter_key_pressed.bind(letter))
			_style_key_button(btn, COLOR_KEY_DEFAULT, _theme_text_color())
			key_buttons[letter] = btn
			hbox.add_child(btn)

		if i == 2:
			var back_btn := Button.new()
			back_btn.text = "<-"
			back_btn.custom_minimum_size = Vector2(58, 44)
			back_btn.focus_mode = Control.FOCUS_NONE
			back_btn.pressed.connect(_on_backspace_pressed)
			hbox.add_child(back_btn)


func _style_key_button(btn: Button, color: Color, text_color: Color = Color.WHITE) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)


func start_new_game() -> void:
	target_word = WordList.WORDS[randi() % WordList.WORDS.size()]
	current_row = 0
	current_guess.clear()
	game_over = false
	is_animating = false
	message_label.text = "Tebak kata 5 huruf dalam 6 kali percobaan!"
	message_label.add_theme_color_override("font_color", _theme_message_color())

	for r in range(MAX_ROWS):
		for c in range(WORD_LEN):
			tile_labels[r][c].text = ""
			tile_labels[r][c].add_theme_color_override("font_color", _theme_text_color())
			tile_panels[r][c].scale = Vector2.ONE
			tile_panels[r][c].add_theme_stylebox_override("panel", _make_tile_style(COLOR_EMPTY, COLOR_BORDER))

	for letter in key_buttons.keys():
		_style_key_button(key_buttons[letter], COLOR_KEY_DEFAULT, _theme_text_color())

	_update_hud()


func _blocked() -> bool:
	return game_over or is_animating or tutorial_visible


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	if _blocked():
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		_on_enter_pressed()
	elif key_event.keycode == KEY_BACKSPACE:
		_on_backspace_pressed()
	elif key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		var letter := char(key_event.keycode)
		_on_letter_key_pressed(letter)


func _on_letter_key_pressed(letter: String) -> void:
	if _blocked():
		return
	if current_guess.size() >= WORD_LEN:
		return
	current_guess.append(letter)
	var col := current_guess.size() - 1
	var panel: Panel = tile_panels[current_row][col]
	tile_labels[current_row][col].text = letter
	panel.add_theme_stylebox_override("panel", _make_tile_style(COLOR_EMPTY, COLOR_FILLED_BORDER))
	_pop_tile(panel)


func _pop_tile(panel: Panel) -> void:
	panel.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(POP_SCALE, POP_SCALE), 0.06) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.08) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_backspace_pressed() -> void:
	if _blocked():
		return
	if current_guess.size() == 0:
		return
	var col := current_guess.size() - 1
	current_guess.remove_at(col)
	tile_labels[current_row][col].text = ""
	tile_panels[current_row][col].add_theme_stylebox_override("panel", _make_tile_style(COLOR_EMPTY, COLOR_BORDER))


func _on_enter_pressed() -> void:
	if _blocked():
		return
	if current_guess.size() < WORD_LEN:
		message_label.text = "Huruf kurang! Lengkapi 5 huruf dulu."
		message_label.add_theme_color_override("font_color", Color("ff6b6b"))
		return
	message_label.add_theme_color_override("font_color", _theme_message_color())

	var guess_word := ""
	for l in current_guess:
		guess_word += l

	if not WordList.WORDS.has(guess_word):
		message_label.text = "'%s' tidak ada di kamus KBBI." % guess_word
		message_label.add_theme_color_override("font_color", Color("ff6b6b"))
		return
	message_label.add_theme_color_override("font_color", _theme_message_color())

	is_animating = true
	await _evaluate_guess(guess_word)
	is_animating = false

	if guess_word == target_word:
		streak += 1
		if streak > best_streak:
			best_streak = streak
		var points := WIN_BASE_POINTS + (streak - 1) * WIN_STREAK_BONUS
		score += points
		if score > best_score:
			best_score = score
		_update_hud()
		message_label.text = "Benar! Kata: %s\nSkor: %d (Terbaik: %d)  |  Streak: %d (Terbaik: %d)" % \
			[target_word, score, best_score, streak, best_streak]
		message_label.add_theme_color_override("font_color", Color("6bc46d"))
		game_over = true
		await get_tree().create_timer(2.2).timeout
		start_new_game()
		return

	current_row += 1
	current_guess.clear()

	if current_row >= MAX_ROWS:
		streak = 0
		score = max(0, score - LOSE_PENALTY)
		if score > best_score:
			best_score = score
		_update_hud()
		message_label.text = "Kalah. Kata yang benar: %s\nSkor: %d (Terbaik: %d)  |  Streak: %d (Terbaik: %d)" % \
			[target_word, score, best_score, streak, best_streak]
		message_label.add_theme_color_override("font_color", Color("ff6b6b"))
		game_over = true
		await get_tree().create_timer(2.6).timeout
		start_new_game()
	else:
		message_label.text = "Tebak kata 5 huruf dalam 6 kali percobaan!"


func _evaluate_guess(guess_word: String) -> void:
	var target_chars: Array = []
	var guess_chars: Array = []
	for i in range(WORD_LEN):
		target_chars.append(target_word[i])
		guess_chars.append(guess_word[i])

	var result: Array = []
	result.resize(WORD_LEN)
	for i in range(WORD_LEN):
		result[i] = "absent"

	var target_remaining: Array = target_chars.duplicate()

	# Tahap 1: tandai huruf yang posisinya benar (hijau)
	for i in range(WORD_LEN):
		if guess_chars[i] == target_chars[i]:
			result[i] = "correct"
			target_remaining[i] = null

	# Tahap 2: tandai huruf yang ada di kata tapi salah posisi (kuning)
	for i in range(WORD_LEN):
		if result[i] == "correct":
			continue
		var idx: int = target_remaining.find(guess_chars[i])
		if idx != -1:
			result[i] = "present"
			target_remaining[idx] = null

	# Ubah tiap hasil jadi warna, lalu jalankan animasi flip kartu
	# bertahap (kotak paling kiri duluan, lalu menyusul ke kanan).
	var last_tween: Tween = null
	for i in range(WORD_LEN):
		var color: Color
		match result[i]:
			"correct":
				color = COLOR_CORRECT
			"present":
				color = COLOR_PRESENT
			_:
				color = COLOR_ABSENT

		var panel: Panel = tile_panels[current_row][i]
		var letter: String = guess_chars[i]

		var tween := create_tween()
		tween.tween_interval(i * FLIP_STAGGER)
		tween.tween_property(panel, "scale:y", 0.0, FLIP_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_callback(_reveal_tile_color.bind(panel, letter, color))
		tween.tween_property(panel, "scale:y", 1.0, FLIP_DURATION) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		last_tween = tween

	if last_tween:
		await last_tween.finished


func _reveal_tile_color(panel: Panel, letter: String, color: Color) -> void:
	panel.add_theme_stylebox_override("panel", _make_tile_style(color, color))

	if key_buttons.has(letter):
		var btn: Button = key_buttons[letter]
		var current_style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		var already_correct := current_style != null and current_style.bg_color == COLOR_CORRECT
		if not already_correct:
			_style_key_button(btn, color)
