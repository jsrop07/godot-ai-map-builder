@tool
extends VBoxContainer

signal prompt_submitted(prompt: String)

var prompt_input: TextEdit
var send_button: Button
var status_label: Label
var chat_history: RichTextLabel

func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var title := Label.new()
	title.text = "AI Map Builder"
	add_child(title)

	var description := Label.new()
	description.text = "AI에게 현재 맵의 수정을 요청하세요."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(description)

	chat_history = RichTextLabel.new()
	chat_history.custom_minimum_size = Vector2(0, 180)
	chat_history.fit_content = false
	chat_history.scroll_active = true
	chat_history.text = "AI Map Builder 대화 내역\n"
	add_child(chat_history)

	prompt_input = TextEdit.new()
	prompt_input.placeholder_text = "예: 테이블을 오른쪽으로 옮겨줘"
	prompt_input.custom_minimum_size = Vector2(0, 120)
	prompt_input.gui_input.connect(_on_prompt_gui_input)
	add_child(prompt_input)

	send_button = Button.new()
	send_button.text = "전송"
	send_button.pressed.connect(_on_send_pressed)
	send_button.focus_mode = Control.FOCUS_ALL
	add_child(send_button)

	status_label = Label.new()
	status_label.text = "대기 중"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

func _on_prompt_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return

		# Shift + Enter = 줄바꿈
		if event.keycode == KEY_ENTER and event.shift_pressed:
			return

		# Enter = 전송
		if event.keycode == KEY_ENTER:
			prompt_input.accept_event()
			_on_send_pressed()
			return

		# Tab = 전송 버튼으로 포커스 이동
		if event.keycode == KEY_TAB:
			prompt_input.accept_event()
			send_button.grab_focus()

func _on_send_pressed() -> void:
	prompt_input.release_focus()

	call_deferred("_send_prompt")

func _send_prompt() -> void:
	var prompt := prompt_input.text.strip_edges()

	if prompt.is_empty():
		status_label.text = "요청을 입력하세요."
		prompt_input.grab_focus()
		return

	status_label.text = "AI 요청 전송 중..."
	send_button.disabled = true

	chat_history.append_text("\n나: " + prompt)

	prompt_input.clear()

	prompt_submitted.emit(prompt)

func set_request_finished(message: String = "완료") -> void:
	status_label.text = message
	send_button.disabled = false
	chat_history.append_text("\nAI: " + message)


func set_request_failed(message: String) -> void:
	status_label.text = "오류: " + message
	send_button.disabled = false