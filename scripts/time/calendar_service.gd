class_name CalendarService
extends RefCounted

var months: Array = []
var month_names: Array = []
var season_by_month: Dictionary = {}
var weekdays: Array = []
var day_phases: Array = []

var year: int = 1
var month: int = 1
var day: int = 1

func setup(data: Dictionary) -> void:
	months = data.get("months", [30]) as Array
	month_names = data.get("month_names", []) as Array
	season_by_month = data.get("season_by_month", {}) as Dictionary
	weekdays = data.get("weekdays", []) as Array
	day_phases = data.get("day_phases", []) as Array

func set_date(y: int, m: int, d: int) -> void:
	year = y
	month = m
	day = d

func get_date() -> Dictionary:
	return { "year": year, "month": month, "day": day }

func get_current_day() -> int:
	return day

func get_current_weekday() -> String:
	if weekdays.is_empty():
		return ""
	var idx := get_total_days() % weekdays.size()
	return str(weekdays[idx])

func get_current_season() -> String:
	return str(season_by_month.get(str(month), "spring"))

func get_day_phase(hour: float) -> String:
	for p in day_phases:
		var s := float(p.get("start", 0.0))
		var e := float(p.get("end", 24.0))
		if hour >= s and hour < e:
			return str(p.get("id", "night"))
	return "night"

func get_month_days(m: int) -> int:
	if m < 1 or m > months.size():
		return 30
	return int(months[m - 1])

func get_total_days() -> int:
	var total := (year - 1) * _days_in_year()
	for m in range(1, month):
		total += get_month_days(m)
	total += (day - 1)
	return total

func advance_days(n: int) -> Dictionary:
	var events := {}
	if n <= 0:
		return events
	var season_before := get_current_season()
	var month_before := month
	var year_before := year
	day += n
	while day > get_month_days(month):
		day -= get_month_days(month)
		month += 1
		if month > 12:
			month = 1
			year += 1
	events["day_changed"] = true
	if month != month_before:
		events["month_changed"] = true
	if year != year_before:
		events["year_changed"] = true
	if season_before != get_current_season():
		events["season_changed"] = true
	return events

func to_dict() -> Dictionary:
	return { "year": year, "month": month, "day": day }

func from_dict(d: Dictionary) -> void:
	year = int(d.get("year", 1))
	month = int(d.get("month", 1))
	day = int(d.get("day", 1))

func _days_in_year() -> int:
	var total := 0
	for m in months:
		total += int(m)
	return total
