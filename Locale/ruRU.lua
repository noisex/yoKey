local _, ns = ...

if ns:IsSameLocale("ruRU") then
	local L = ns.L or ns:NewLocale()

	L.LOCALE_NAME = "ruRU"

	L["yoFrame"]		= "yoFrame"
	L["completion1"] = "Закрыли вовремя |cff8787ED%s [%s]|r за |cff00ffff%s|r. Осталось %s от таймера, и отстали от +2 на %s."
	L["completion2"] = "Закрыли вовремя |cff8787ED%s [%s]|r +2 за |cff00ffff%s|r. Осталось %s от +2 таймера, и отстали от +3 на %s."
	L["completion3"] = "Закрыли вовремя |cff8787ED%s [%s]|r +3 за |cff00ffff%s|r. Осталось %s от +3 таймера."

	L["completion0"] = "|cff8787ED[%s] %s|r окончили за |cffff0000%s|r, вы отстали на %s от общего лимита времени."

	L["Schedule"] 	= "Расписание"
	L["Rewards"] 	= "Награды"
	L["WeekLeader"] = "Лидеры недели"

	ns[1] = L
end