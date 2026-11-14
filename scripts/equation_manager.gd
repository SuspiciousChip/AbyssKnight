extends Node

# Every possible question in this first algebra set is shuffled once.
# Removing a question when used guarantees no repeats during this run.
var questions: Dictionary = {}
var topic: String = "arithmetic"


func _ready() -> void:
	reset_questions()


func reset_questions() -> void:
	questions.clear()
	questions["arithmetic"] = []
	questions["algebra"] = []
	questions["geometry"] = []
	for answer in range(1, 6):
		for left in range(answer + 1):
			questions["arithmetic"].append({
				"text": "%d + %d = ?" % [left, answer - left],
				"answer": answer
			})
	for answer in range(1, 6):
		for multiplier in range(2, 10):
			for added in range(1, 13):
				questions["algebra"].append({
					"text": "%dx + %d = %d" % [multiplier, added, multiplier * answer + added],
					"answer": answer
				})
		for height in range(2, 11):
			questions["geometry"].append({
				"text": "Rect P=%d, h=%d. w=?" % [2 * (answer + height), height],
				"answer": answer
			})
	for pool in questions.values():
		pool.shuffle()


func next_question() -> Dictionary:
	var pool: Array = questions[topic]
	if pool.is_empty():
		push_error("All %s questions have been used in this run." % topic)
		return {}
	return pool.pop_back()
