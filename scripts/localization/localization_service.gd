class_name LocalizationService
extends RefCounted

var locale: String = "zh"
var table: Dictionary = {
	"zh": {
		"menu.start": "开始游戏", "menu.load": "读取存档", "menu.settings": "设置", "menu.exit": "退出游戏", "mode.story": "故事模式", "mode.free": "自由模式", "menu.back": "返回",
		"ui.hud.hp": "生命", "ui.hud.gold": "金币", "ui.hud.time": "时间", "ui.hud.weather": "天气",
		"ui.panel.close": "关闭", "ui.panel.back": "返回", "ui.panel.confirm": "确认", "ui.panel.cancel": "取消",
		"ui.dialogue.continue": "继续", "ui.dialogue.locked": "条件不满足",
		"ui.character.title": "角色", "ui.character.level": "等级", "ui.character.xp": "经验", "ui.character.race": "种族", "ui.character.class": "职业", "ui.character.attributes": "属性", "ui.character.hp": "生命", "ui.character.mp": "法力", "ui.character.equipment": "装备", "ui.character.allocate": "加点", "ui.character.feats": "专长", "ui.character.talents": "天赋",
		"ui.party.title": "队伍", "ui.party.active": "出战", "ui.party.reserve": "后备",
		"ui.inventory.title": "背包", "ui.inventory.all": "全部", "ui.inventory.weapon": "武器", "ui.inventory.armor": "护甲", "ui.inventory.consumable": "消耗品", "ui.inventory.material": "材料", "ui.inventory.quest": "任务", "ui.inventory.misc": "杂项", "ui.inventory.use": "使用", "ui.inventory.equip": "装备", "ui.inventory.discard": "丢弃", "ui.inventory.empty": "背包为空",
		"ui.equipment.title": "装备", "ui.equipment.head": "头部", "ui.equipment.body": "身体", "ui.equipment.mainhand": "主手", "ui.equipment.offhand": "副手",
		"ui.quest.title": "任务日志", "ui.quest.active": "进行中", "ui.quest.completed": "已完成", "ui.quest.failed": "失败", "ui.quest.objectives": "目标", "ui.quest.reward": "奖励",
		"ui.shop.title": "商店", "ui.shop.buy": "购买", "ui.shop.sell": "出售", "ui.shop.insufficient": "金币不足",
		"ui.combat.title": "战斗", "ui.combat.round": "回合", "ui.combat.turn": "行动", "ui.combat.hp": "生命", "ui.combat.attack": "攻击", "ui.combat.skill": "技能", "ui.combat.wait": "等待",
		"ui.npc.title": "人物信息",
		"ui.tavern.title": "酒馆", "ui.tavern.talk": "交谈", "ui.tavern.rest": "休息", "ui.tavern.recruit": "招募",
		"ui.common.no_quests": "暂无任务", "ui.equipment.unequip": "卸下", "ui.profile.personality": "性格", "ui.profile.motivation": "动机",
		"ui.feedback.attack": "攻击", "ui.feedback.skill": "技能", "ui.feedback.wait": "等待", "ui.feedback.tavern_talk": "酒馆交谈", "ui.feedback.recruit_unavailable": "当前演示暂未开放招募", "ui.feedback.party_rested": "队伍已休息", "ui.feedback.equipped": "已装备"
	},
	"en": {
		"menu.start": "Start", "menu.load": "Load Game", "menu.settings": "Settings", "menu.exit": "Exit", "mode.story": "Story Mode", "mode.free": "Free Mode", "menu.back": "Back",
		"ui.hud.hp": "HP", "ui.hud.gold": "Gold", "ui.hud.time": "Time", "ui.hud.weather": "Weather",
		"ui.panel.close": "Close", "ui.panel.back": "Back", "ui.panel.confirm": "Confirm", "ui.panel.cancel": "Cancel",
		"ui.dialogue.continue": "Continue", "ui.dialogue.locked": "Condition not met",
		"ui.character.title": "Character", "ui.character.level": "Level", "ui.character.xp": "XP", "ui.character.race": "Race", "ui.character.class": "Class", "ui.character.attributes": "Attributes", "ui.character.hp": "HP", "ui.character.mp": "MP", "ui.character.equipment": "Equipment", "ui.character.allocate": "Add", "ui.character.feats": "Feats", "ui.character.talents": "Talents",
		"ui.party.title": "Party", "ui.party.active": "Active", "ui.party.reserve": "Reserve",
		"ui.inventory.title": "Inventory", "ui.inventory.all": "All", "ui.inventory.weapon": "Weapon", "ui.inventory.armor": "Armor", "ui.inventory.consumable": "Consumable", "ui.inventory.material": "Material", "ui.inventory.quest": "Quest", "ui.inventory.misc": "Misc", "ui.inventory.use": "Use", "ui.inventory.equip": "Equip", "ui.inventory.discard": "Discard", "ui.inventory.empty": "Inventory empty",
		"ui.equipment.title": "Equipment", "ui.equipment.head": "Head", "ui.equipment.body": "Body", "ui.equipment.mainhand": "Main Hand", "ui.equipment.offhand": "Off Hand",
		"ui.quest.title": "Quest Journal", "ui.quest.active": "Active", "ui.quest.completed": "Completed", "ui.quest.failed": "Failed", "ui.quest.objectives": "Objectives", "ui.quest.reward": "Rewards",
		"ui.shop.title": "Shop", "ui.shop.buy": "Buy", "ui.shop.sell": "Sell", "ui.shop.insufficient": "Not enough gold",
		"ui.combat.title": "Combat", "ui.combat.round": "Round", "ui.combat.turn": "Turn", "ui.combat.hp": "HP", "ui.combat.attack": "Attack", "ui.combat.skill": "Skill", "ui.combat.wait": "Wait",
		"ui.npc.title": "Profile",
		"ui.tavern.title": "Tavern", "ui.tavern.talk": "Talk", "ui.tavern.rest": "Rest", "ui.tavern.recruit": "Recruit",
		"ui.common.no_quests": "No quests", "ui.equipment.unequip": "Unequip", "ui.profile.personality": "Personality", "ui.profile.motivation": "Motivation",
		"ui.feedback.attack": "Attack", "ui.feedback.skill": "Skill", "ui.feedback.wait": "Wait", "ui.feedback.tavern_talk": "Tavern talk", "ui.feedback.recruit_unavailable": "Recruit unavailable in this demo", "ui.feedback.party_rested": "Party rested", "ui.feedback.equipped": "Equipped"
	}
}

func set_locale(l: String) -> void:
	locale = l

func t(key: String) -> String:
	var loc = table.get(locale, {})
	return str(loc.get(key, key))
