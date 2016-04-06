function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

--	Strength Tanks
--	250 DEATHKNIGHT_Blood
--	73  WARRIOR_Protection
--	66  PALADIN_Protection

--		Agility Tanks
--	104 DRUID_Guardian
--	268 MONK_Brewmaster

--		Strength MDPS
--	70  PALADIN_Retribution
--	72  WARRIOR_Fury
--	71  WARRIOR_Arms
--	252 DEATHKNIGHT_Unholy
--	251 DEATHKNIGHT_Frost

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

--		Healers
--	105 DRUID_Restoration
--	257 PRIEST_Holy
--	256 PRIEST_Discipline
--	264 SHAMAN_Restoration
--	65  PALADIN_Holy
--	270 MONK_Mistweaver
	
ItemInvestigator_LoadFivePercentStatsBonus({
[Set{103,254,63,268,65,256,267,72}]	= "ITEM_MOD_CRIT_RATING_SHORT",
[Set{251,105,66,258,260,263,265}] = "ITEM_MOD_HASTE_RATING_SHORT",
[Set{102,104,253,62,70,259,264,266,71,73}] = "ITEM_MOD_MASTERY_RATING_SHORT",
[Set{252,250,255,64,270,269,257,261,262}] = "ITEM_MOD_CR_MULTISTRIKE_SHORT"		
});