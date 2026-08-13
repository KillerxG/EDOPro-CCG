-- Global script overrides loaded only by EDOProMod.

RACE_ALL = RACE_ALL | RACE_YOKAI

function Auxiliary.GetCover(c, coverNum)
	return c:GetOriginalCode()
end

function Auxiliary.GetRaceStrings(v)
	local t = {
		[RACE_WARRIOR] = 1020,
		[RACE_SPELLCASTER] = 1021,
		[RACE_FAIRY] = 1022,
		[RACE_FIEND] = 1023,
		[RACE_ZOMBIE] = 1024,
		[RACE_MACHINE] = 1025,
		[RACE_AQUA] = 1026,
		[RACE_PYRO] = 1027,
		[RACE_ROCK] = 1028,
		[RACE_WINGEDBEAST] = 1029,
		[RACE_PLANT] = 1030,
		[RACE_INSECT] = 1031,
		[RACE_THUNDER] = 1032,
		[RACE_DRAGON] = 1033,
		[RACE_BEAST] = 1034,
		[RACE_BEASTWARRIOR] = 1035,
		[RACE_DINOSAUR] = 1036,
		[RACE_FISH] = 1037,
		[RACE_SEASERPENT] = 1038,
		[RACE_REPTILE] = 1039,
		[RACE_PSYCHIC] = 1040,
		[RACE_DIVINE] = 1041,
		[RACE_CREATORGOD] = 1042,
		[RACE_WYRM] = 1043,
		[RACE_CYBERSE] = 1044,
		[RACE_ILLUSION] = 1045,
		[RACE_YOKAI] = 2532
	}
	local res = {}
	for _, race in Auxiliary.BitSplit(v) do
		if t[race] then
			table.insert(res, t[race])
		end
	end
	return pairs(res)
end
