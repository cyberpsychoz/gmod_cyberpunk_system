-- Автор этого плагина больной на всю голову
PLUGIN.name = "Cyberpunk RED Combat System"
PLUGIN.author = "Крыжовник#4511"
PLUGIN.description = "A plugin that implements the combat system of Cyberpunk RED tabletop RPG in Gmod Helix."

-- Здесь мы определяем некоторые константы и переменные, которые будут использоваться в плагине
local HITGROUPS = {
	[HITGROUP_HEAD] = "head",
	[HITGROUP_CHEST] = "torso",
	[HITGROUP_STOMACH] = "torso",
	[HITGROUP_LEFTARM] = "arm",
	[HITGROUP_RIGHTARM] = "arm",
	[HITGROUP_LEFTLEG] = "leg",
	[HITGROUP_RIGHTLEG] = "leg"
}

local BODY_PARTS = {
	head = {name = "Head", hp = 8, armor = 0},
	torso = {name = "Torso", hp = 10, armor = 0},
	arm = {name = "Arm", hp = 6, armor = 0},
	leg = {name = "Leg", hp = 6, armor = 0}
}

local WEAPON_TYPES = {
	pistol = {name = "Pistol", skill = "handgun", damage = "2d6", range = 50},
	rifle = {name = "Rifle", skill = "shoulder_arms", damage = "5d6", range = 400},
	shotgun = {name = "Shotgun", skill = "shoulder_arms", damage = "5d6", range = 50},
	smg = {name = "SMG", skill = "submachinegun", damage = "2d6+1", range = 150},
	melee = {name = "Melee", skill = "melee_weapons", damage = nil, range = nil}
}

local CRITICAL_INJURIES_TABLES -- здесь мы будем хранить таблицы с критическими повреждениями для каждой части тела

-- Здесь мы определяем некоторые функции-помощники, которые будут использоваться в плагине
local function RollDice(dice) -- эта функция симулирует бросок костей в формате XdY, где X - количество костей, Y - количество граней на каждой кости
	local result = 0
	local parts = string.Explode("d", dice)
	local count, sides

	if (#parts == 2) then
		count, sides = tonumber(parts[1]), tonumber(parts[2])
	else
		return 0
	end

	if (count and sides) then
		for i = 1, count do
			result = result + math.random(1, sides)
		end
	end

	return result
end

local function GetWeaponType(weapon) -- эта функция возвращает тип оружия по его классу
	local class = weapon:GetClass()

	if (class:find("pistol")) then
		return WEAPON_TYPES.pistol
	elseif (class:find("rifle")) then
		return WEAPON_TYPES.rifle
	elseif (class:find("shotgun")) then
		return WEAPON_TYPES.shotgun
	elseif (class:find("smg")) then
		return WEAPON_TYPES.smg
	elseif (class:find("knife") or class:find("sword") or class:find("bat")) then
		return WEAPON_TYPES.melee
	else
		return nil -- неизвестный тип оружия
	end
end

local function GetBodyPart(hitgroup) -- эта функция возвращает часть тела по ее хитгруппе
	local part = HITGROUPS[hitgroup]

	if (part) then
		return BODY_PARTS[part]
	else
		return nil -- неизвестная часть тела
	end
end

local function GetSkillLevel(client, skill) -- эта функция возвращает уровень навыка персонажа по его имени
	local character = client:GetCharacter()

	if (character) then
		local attribute = character:GetAttribute(skill, 0)
		local modifier = character:GetData(skill .. "mod", 0)
		return attribute + modifier
	else
		return 0 -- нет персонажа или навыка
	end
end

local function GetArmorValue(client, part) -- эта функция возвращает значение брони персонажа по части тела
	local character = client:GetCharacter()

	if (character) then
		local armor = character:GetInventory():HasItem("armor") -- предположим, что броня - это предмет с классом "armor"

		if (armor) then
			local value = armor:GetData(part .. "armor", 0) -- предположим, что броня хранит значения для каждой части тела в своих данных
			return value
		else
			return 0 -- нет брони или значения для этой части тела
		end
	else
		return 0 -- нет персонажа или части тела
	end
end

local function ApplyDamage(client, attacker, damage, part) -- эта функция применяет урон персонажу по части тела и проверяет на критические повреждения и смерть
	local character = client:GetCharacter()

	if (character) then
		local hp = character:GetData(part .. "hp", part.hp) -- получаем текущее здоровье части тела
		local armor = GetArmorValue(client, part) -- получаем значение брони по части тела
		local finalDamage = math.max(damage - armor, 0) -- вычисляем финальный урон с учетом брони
		hp = hp - finalDamage -- вычитаем урон из здоровья
		character:SetData(part .. "hp", hp) -- сохраняем новое здоровье части тела

		if (hp <= 0) then -- если здоровье части тела стало нулевым или меньше
			local critical = RollDice("1d10") -- бросаем кость на критическое повреждение
			local table = CRITICAL_INJURIES_TABLES[part] -- получаем таблицу с критическими повреждениями для этой части тела
			local injury = table[critical] -- получаем критическое повреждение по результату броска

			if (injury) then -- если есть критическое повреждение
				character:SetData(part .. "injury", injury) -- сохраняем его в данных персонажа
				injury:Apply(client, attacker) -- применяем его эффекты к персонажу
			end

			if (part == "head" or part == "torso") then -- если часть тела - голова или торс
				character:Kill() -- персонаж умирает
			end
		end
	end
end

-- Здесь мы определяем некоторые хуки и события Helix, которые будут использоваться в плагине

function PLUGIN:CharacterPreCreate(character) -- этот хук вызывается перед созданием персонажа
	for part, data in pairs(BODY_PARTS) do -- для каждой части тела
		character:SetData(part .. "hp", data.hp) -- устанавливаем ее начальное здоровье
		character:SetData(part .. "armor", data.armor) -- устанавливаем ее начальную броню
	end
end

function PLUGIN:PlayerHurt(client, attacker, health, damage) -- этот хук вызывается при нанесении урона игроку
	if (IsValid(client) and IsValid(attacker) and client:IsPlayer() and attacker:IsPlayer()) then -- если оба игрока валидны
		local weapon = attacker:GetActiveWeapon() -- получаем оружие атакующего
		local hitgroup = client:LastHitGroup() -- получаем хитгруппу последнего попадания

		if (IsValid(weapon) and hitgroup != HITGROUP_GENERIC) then -- если оружие валидно и хитгруппа не общая
			local weaponType = GetWeaponType(weapon) -- получаем тип оружия по его классу
			local bodyPart = GetBodyPart(hitgroup) -- получаем часть тела по ее хитгруппе

			if (weaponType and bodyPart) then -- если тип оружия и часть тела известны
				local skillLevel = GetSkillLevel(attacker, weaponType.skill) -- получаем уровень навыка атакующего по типу оружия
								local roll = RollDice("1d10") + skillLevel -- бросаем кость на попадание и добавляем уровень навыка
				local distance = client:GetPos():Distance(attacker:GetPos()) -- получаем дистанцию между атакующим и целью
				local range = weaponType.range -- получаем дальность стрельбы оружия
				local difficulty = math.ceil(distance / range) * 10 -- вычисляем сложность попадания по формуле: дистанция / дальность * 10

				if (roll >= difficulty) then -- если бросок больше или равен сложности
					local damage = RollDice(weaponType.damage) -- бросаем кость на урон по типу оружия
					ApplyDamage(client, attacker, damage, bodyPart) -- применяем урон по части тела
				else -- если бросок меньше сложности
					-- промах
				end
			end
		end

		return false -- отменяем стандартный урон Helix
	end
end

function PLUGIN:PlayerDeath(client, inflictor, attacker) -- этот хук вызывается при смерти игрока
	if (IsValid(client) and client:IsPlayer()) then -- если игрок валиден
		local character = client:GetCharacter() -- получаем его персонажа

		if (character) then -- если персонаж существует
			for part, data in pairs(BODY_PARTS) do -- для каждой части тела
				character:SetData(part .. "hp", data.hp) -- восстанавливаем ее здоровье до начального значения
				character:SetData(part .. "injury", nil) -- удаляем критическое повреждение, если есть
			end
		end
	end
end

-- Здесь мы определяем некоторые классы и методы Helix, которые будут использоваться в плагине

ix.command.Add("Heal", { -- добавляем команду /heal для лечения персонажей
	description = "Heal a character's body part.",
	adminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.string, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, part, amount)
		if (target and target:IsPlayer()) then -- если цель - игрок
			local character = target:GetCharacter() -- получаем его персонажа

			if (character) then -- если персонаж существует
				if (part) then -- если указана часть тела
					part = part:lower() -- приводим ее к нижнему регистру

					if (BODY_PARTS[part]) then -- если такая часть тела есть в таблице
						local hp = character:GetData(part .. "hp", BODY_PARTS[part].hp) -- получаем текущее здоровье части тела

						if (amount) then -- если указано количество лечения
							hp = math.min(hp + amount, BODY_PARTS[part].hp) -- прибавляем его к здоровью с учетом максимального значения
						else -- если количество лечения не указано
							hp = BODY_PARTS[part].hp -- восстанавливаем здоровье до максимального значения
						end

						character:SetData(part .. "hp", hp) -- сохраняем новое здоровье части тела

						return string.format("You have healed %s's %s.", target:GetName(), BODY_PARTS[part].name) -- возвращаем сообщение об успехе
					else -- если такой части тела нет в таблице
						return "Invalid body part." -- возвращаем сообщение об ошибке
					end
				else -- если часть тела не указана
					for part, data in pairs(BODY_PARTS) do -- для каждой части тела
						character:SetData(part .. "hp", data.hp) -- восстанавливаем ее здоровье до максимального значения
					end

					return string.format("You have healed %s completely.", target:GetName()) -- возвращаем сообщение об успехе
				end
			else -- если персонажа не существует
				return "Invalid character." -- возвращаем сообщение об ошибке
			end
		else -- если цель не игрок
			return "Invalid target." -- возвращаем сообщение об ошибке
		end
	end
})

ix.command.Add("Injure", { -- добавляем команду /injure для нанесения урона персонажам
	description = "Injure a character's body part.",
	adminOnly = true,
	arguments = {
		ix.type.character,
		bit.bor(ix.type.string, ix.type.optional),
		bit.bor(ix.type.number, ix.type.optional)
	},
	OnRun = function(self, client, target, part, amount)
		if (target and target:IsPlayer()) then -- если цель - игрок
			local character = target:GetCharacter() -- получаем его персонажа

			if (character) then -- если персонаж существует
				if (part) then -- если указана часть тела
					part = part:lower() -- приводим ее к нижнему регистру

					if (BODY_PARTS[part]) then -- если такая часть тела есть в таблице
						local hp = character:GetData(part .. "hp", BODY_PARTS[part].hp) -- получаем текущее здоровье части тела

						if (amount) then -- если указано количество урона
							hp = math.max(hp - amount, 0) -- вычитаем его из здоровья с учетом минимального значения
						else -- если количество урона не указано
							hp = 0 -- устанавливаем здоровье в нулевое значение
						end

						character:SetData(part .. "hp", hp) -- сохраняем новое здоровье части тела

						if (hp <= 0) then -- если здоровье части тела стало нулевым или меньше
							local critical = RollDice("1d10") -- бросаем кость на критическое повреждение
							local table = CRITICAL_INJURIES_TABLES[part] -- получаем таблицу с критическими повреждениями для этой части тела
							local injury = table[critical] -- получаем критическое повреждение по результату броска

							if (injury) then -- если есть критическое повреждение
								character:SetData(part .. "injury", injury) -- сохраняем его в данных персонажа
								injury:Apply(target, client) -- применяем его эффекты к персонажу

								return string.format("You have injured %s's %s with a critical injury: %s.", target:GetName(), BODY_PARTS[part].name, injury.name) -- возвращаем сообщение об успехе с описанием критического повреждения
							else -- если нет критического повреждения
								return string.format("You have injured %s's %s.", target:GetName(), BODY_PARTS[part].name) -- возвращаем сообщение об успехе без описания критического повреждения
							end

							if (part == "head" or part == "torso") then -- если часть тела - голова или торс
								character:Kill() -- персонаж умирает
							end
						else -- если здоровье части тела больше нуля
							return string.format("You have injured %s's %s.", target:GetName(), BODY_PARTS[part].name) -- возвращаем сообщение об успехе
						end
					else -- если такой части тела нет в таблице
						return "Invalid body part." -- возвращаем сообщение об ошибке
					end
				else -- если часть тела не указана
					return "You need to specify a body part." -- возвращаем сообщение об ошибке
				end
			else -- если персонажа не существует
				return "Invalid character." -- возвращаем сообщение об ошибке
			end
		else -- если цель не игрок
			return "Invalid target." -- возвращаем сообщение об ошибке
		end
	end
})

-- Это конец... кода?
-- Нужно будет еще добавить больше функций и классов, чтобы реализовать все аспекты системы боя Cyberpunk RED, такие как автоматический огонь, прицельная стрельба, подавляющий огонь, 
-- кибернетика, навыки и т.д. Надеюсь я не ёбнусь в край пока все это доделаю.

