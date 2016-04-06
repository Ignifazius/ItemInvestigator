function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- Disabled the primary stats because it works a little weird with the new items
-- Items both have Int and Str for instance but the activated is the stat is the one
-- for the spec of the player not the one for the target.
	
ItemInvestigator_LoadWrongStatsForSpec({
--	Strength Tanks
--	250 DEATHKNIGHT_Blood
--	73  WARRIOR_Protection
--	66  PALADIN_Protection
[Set{250, 73, 66}]	=
{ 	--"ITEM_MOD_INTELLECT_SHORT",
	--"ITEM_MOD_AGILITY_SHORT", 
	"ITEM_MOD_SPIRIT_SHORT",
	"ITEM_MOD_SPELL_POWER_SHORT"},

--		Agility Tanks
--	104 DRUID_Guardian
--	268 MONK_Brewmaster
[Set{104, 268}] = 	
{ 	--"ITEM_MOD_INTELLECT_SHORT",
	--"ITEM_MOD_STRENGTH_SHORT", 
	"ITEM_MOD_SPIRIT_SHORT",
	"ITEM_MOD_SPELL_POWER_SHORT"},
	
--		Strength MDPS
--	70  PALADIN_Retribution
--	72  WARRIOR_Fury
--	71  WARRIOR_Arms
--	252 DEATHKNIGHT_Unholy
--	251 DEATHKNIGHT_Frost
[Set{70, 72, 71, 252, 251}]=	
{	--"ITEM_MOD_INTELLECT_SHORT",
	--"ITEM_MOD_AGILITY_SHORT", 
	"ITEM_MOD_SPIRIT_SHORT",
	"ITEM_MOD_SPELL_POWER_SHORT",
	"RESISTANCE0_NAME"},

--		Agility MDPS
--	103 DRUID_Feral
--	260 ROGUE_Combat
--	259 ROGUE_Assassination
--	261 ROGUE_Subtlety
--	254 HUNTER_Marksmanship
--	255 HUNTER_Survival
--	253 HUNTER_Beast Mastery
--	263 SHAMAN_Enhancement
--	269 MONK_Windwalker
[Set{103, 260, 259, 259, 261, 254, 255, 253, 263, 269}] = 		
{ 	--"ITEM_MOD_INTELLECT_SHORT",
	--"ITEM_MOD_STRENGTH_SHORT", 
	"ITEM_MOD_SPIRIT_SHORT",
	"ITEM_MOD_SPELL_POWER_SHORT",
	"RESISTANCE0_NAME"},
	
--		RDPS
--	63  MAGE_Fire
--	64  MAGE_Frost
--	62  MAGE_Arcane
--	266 WARLOCK_Demonology
--	267 WARLOCK_Destruction
--	265 WARLOCK_Affliction
--	102 DRUID_Balance
--	258 PRIEST_Shadow
--	262 SHAMAN_Elemental
[Set{63, 64, 62, 266, 267, 265, 102, 258, 262, 102, 258, 262}] = 		
{ 	--"ITEM_MOD_STRENGTH_SHORT",
	--"ITEM_MOD_AGILITY_SHORT", 
	"ITEM_MOD_SPIRIT_SHORT",
	"RESISTANCE0_NAME"},

--		Healers
--	105 DRUID_Restoration
--	257 PRIEST_Holy
--	256 PRIEST_Discipline
--	264 SHAMAN_Restoration
--	65  PALADIN_Holy
--	270 MONK_Mistweaver
[Set{105, 257, 256, 264, 65, 270}] = 
{ 	--"ITEM_MOD_STRENGTH_SHORT", 
	--"ITEM_MOD_AGILITY_SHORT",
	"RESISTANCE0_NAME"}
});