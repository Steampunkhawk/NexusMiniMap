-----------------------------------------------------------------------------------------------
-- Client Lua Script for NexusMiniMap v 0.5
-- Copyright (c) NCsoft. All rights reserved
-- Addon extending some custom filtering to the default NCsoft MiniMap
-- Created by Steampunkhawk 21 June 2014
--
-- Change log
-- v 0.1 Simple check box to see if filtering city directions is possible
-- v 0.5 Added flyout menu to hold a filtering list and updated some of the default
-- 		 vendor object to custom objects for more grainular sorting
-- v 1.0 Added a few more filters to the townies and tidied up the layouts a little bit.
--       Made the Options and Townies filter open and close a little nicer
-----------------------------------------------------------------------------------------------

require "Window"
require "DialogSys"
require "Quest"
require "QuestLib"
require "MailSystemLib"
require "Sound"
require "GameLib"
require "Tooltip"
require "XmlDoc"
require "PlayerPathLib"
require "Unit"
require "PublicEvent"
require "PublicEventObjective"
require "FriendshipLib"
require "CraftingLib"

-- TODO: Distinguish markers for different nodes from each other
local kstrMiningNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Mining"
local kcrMiningNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrRelicNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Relic"
local kcrRelicNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrFarmingNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Plant"
local kcrFarmingNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrSurvivalNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Tree"
local kcrSurvivalNode = CColor.new(0.2, 1.0, 1.0, 1.0)

local kstrFishingNodeIcon = "IconSprites:Icon_MapNode_Map_Node_Fishing"
local kcrFishingNode = CColor.new(0.2, 1.0, 1.0, 1.0)


local ktPvPZoneTypes =
{
	[GameLib.CodeEnumZonePvpRules.None] 					= "",
	[GameLib.CodeEnumZonePvpRules.ExileStronghold]			= Apollo.GetString("MiniMap_Exile"),
	[GameLib.CodeEnumZonePvpRules.DominionStronghold] 		= Apollo.GetString("MiniMap_Dominion"),
	[GameLib.CodeEnumZonePvpRules.Sanctuary] 				= Apollo.GetString("MiniMap_Sanctuary"),
	[GameLib.CodeEnumZonePvpRules.Pvp] 						= Apollo.GetString("MiniMap_PvP"),
	[GameLib.CodeEnumZonePvpRules.ExilePVPStronghold] 		= Apollo.GetString("MiniMap_Exile"),
	[GameLib.CodeEnumZonePvpRules.DominionPVPStronghold] 	= Apollo.GetString("MiniMap_Dominion"),
}

local ktInstanceSettingTypeStrings =
{
	Veteran = Apollo.GetString("MiniMap_Veteran"),
	Rallied = Apollo.GetString("MiniMap_Rallied"),
}


local knSaveVersion = 4

local NexusMiniMap = {}

function NexusMiniMap:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end


function NexusMiniMap:CreateOverlayObjectTypes()
	self.eObjectTypePublicEvent			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypePublicEventKill		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeChallenge			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypePing				= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeCityDirection		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeHazard 				= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestReward 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestReceiving 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestNew 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestNewSoon 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestTarget 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestKill	 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeTradeskills 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor 				= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeAuctioneer 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeCommodity 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeInstancePortal 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeBindPointActive 	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeBindPointInactive 	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeMiningNode 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeRelicHunterNode 	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeSurvivalistNode 	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeFarmingNode 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeFishingNode 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendorFlight 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeFlightPathNew		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeNeutral	 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeHostile	 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeFriend	 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeRival	 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeTrainer	 			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeGroupMember			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectPvPMarkers				= self.wndNexusMiniMap:CreateOverlayType()
    -- Custom Guard Minimap Objects
    self.eObjectTypeEliteHostile		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeEliteNeutral		= self.wndNexusMiniMap:CreateOverlayType()	
	self.eObjectTypeUniqueFarming		= self.wndNexusMiniMap:CreateOverlayType()	
	self.eObjectTypeUniqueMining		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeUniqueRelic			= self.wndNexusMiniMap:CreateOverlayType()	
	self.eObjectTypeUniqueSurvival		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypePathResource		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeLore				= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestItem			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypePC					= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeQuestCritter		= self.wndNexusMiniMap:CreateOverlayType()
	-- Custom Nexus Minimap Objects
	self.eObject_NMM_Bank						= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_Dye					= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_Guards					= self.wndNexusMiniMap:CreateOverlayType()
	self.eObject_NMM_GuildBank					= self.wndNexusMiniMap:CreateOverlayType()
	self.eObject_NMM_Mailbox					= self.wndNexusMiniMap:CreateOverlayType()
	self.eObject_NMM_CraftingStation			= self.wndNexusMiniMap:CreateOverlayType()	
	self.eObject_NMM_TradeskillTrainer			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_TradeskillVendor		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_VendorMount			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_VendorArmor			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_VendorWeapon			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_PvPArenaVendor			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_PvPBattlegroundsVendor	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectType_NMM_PvPWarplotsVendor		= self.wndNexusMiniMap:CreateOverlayType()		
	self.eObjectTypeVendor_NMM_Renown			= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_Reputation		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_ResourceConversion	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_ConvertItem 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_ConvertRep 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_GuildRegistrar 	= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_Consumable		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_ElderGem 		= self.wndNexusMiniMap:CreateOverlayType()
	self.eObjectTypeVendor_NMM_Housing 			= self.wndNexusMiniMap:CreateOverlayType()


	end

function NexusMiniMap:BuildCustomMarkerInfo()
	self.tMinimapMarkerInfo =
	{
		PvPExileCarry			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCarry",			bFixedSizeMedium = true	},
		PvPDominionCarry		= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCarry",			bFixedSizeMedium = true	},
		PvPNeutralCarry			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCarry",			bFixedSizeMedium = true	},
		PvPExileCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCap",			bFixedSizeMedium = true	},
		PvPDominionCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCap",			bFixedSizeMedium = true	},
		PvPNeutralCap1			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCap",			bFixedSizeMedium = true	},
		PvPExileCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_ExileCap",			bFixedSizeMedium = true	},
		PvPDominionCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_DominionCap",			bFixedSizeMedium = true	},
		PvPNeutralCap2			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_NeutralCap",			bFixedSizeMedium = true	},
		PvPBattleAlert			= { nOrder = 100,	objectType = self.eObjectPvPMarkers,			strIcon = "IconSprites:Icon_MapNode_Map_PvP_BattleAlert",	bFixedSizeMedium = true	},
		IronNode				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		TitaniumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		ZephyriteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		PlatinumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		HydrogemNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		XenociteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		ShadeslateNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		GalactiumNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		NovaciteNode			= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = kstrMiningNodeIcon,	crObject = kcrMiningNode, 	crEdge = kcrMiningNode },
		StandardRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		AcceleratedRelicNode	= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		AdvancedRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		DynamicRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		KineticRelicNode		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = kstrRelicNodeIcon, 	crObject = kcrRelicNode, 	crEdge = kcrRelicNode },
		SpirovineNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		BladeleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		YellowbellNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		PummelgranateNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SerpentlilyNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GoldleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		HoneywheatNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		CrowncornNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		CoralscaleNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LogicleafNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		StoutrootNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GlowmelonNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		FaerybloomNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode,	crEdge = kcrFarmingNode },
		WitherwoodNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode,	crEdge = kcrFarmingNode },
		FlamefrondNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		GrimgourdNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MourningstarNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		BloodbriarNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		OctopodNode				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		HeartichokeNode			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgGrowthshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgHarvestshroomNode	= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		SmlRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		MedRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		LrgRenewshroomNode		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = kstrFarmingNodeIcon, 	crObject = kcrFarmingNode, 	crEdge = kcrFarmingNode },
		AlgorocTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		CelestionTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		DeraduneTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		EllevarTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		GalerasTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		AuroriaTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		WhitevaleTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		DreadmoorTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		FarsideTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		CoralusTreeNode			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		MurkmireTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		WilderrunTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		MalgraveTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		HalonRingTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		GrimvaultTreeNode		= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = kstrSurvivalNodeIcon,	crObject = kcrSurvivalNode, crEdge = kcrSurvivalNode },
		SchoolOfFishNode		= { nOrder = 100, 	objectType = self.eObjectTypeFishingNode,		strIcon = kstrFishingNodeIcon,	crObject = kcrFishingNode,	crEdge = kcrFishingNode },
		Friend					= { nOrder = 2, 	objectType = self.eObjectTypeFriend, 			strIcon = "IconSprites:Icon_Windows_UI_CRB_Friend",	bNeverShowOnEdge = true, bShown, bFixedSizeMedium = true },
		Rival					= { nOrder = 3, 	objectType = self.eObjectTypeRival, 			strIcon = "IconSprites:Icon_MapNode_Map_Rival", 	bNeverShowOnEdge = true, bShown, bFixedSizeMedium = true },
		Trainer					= { nOrder = 4, 	objectType = self.eObjectTypeTrainer, 			strIcon = "IconSprites:Icon_MapNode_Map_Trainer", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestKill				= { nOrder = 5, 	objectType = self.eObjectTypeQuestKill, 		strIcon = "sprMM_TargetCreature", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestTarget				= { nOrder = 6,		objectType = self.eObjectTypeQuestTarget, 		strIcon = "sprMM_TargetObjective", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		PublicEventKill			= { nOrder = 7,		objectType = self.eObjectTypePublicEventKill, 	strIcon = "sprMM_TargetCreature", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		PublicEventTarget		= { nOrder = 8,		objectType = self.eObjectTypePublicEventTarget, strIcon = "sprMM_TargetObjective", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		QuestReward				= { nOrder = 9,		objectType = self.eObjectTypeQuestReward, 		strIcon = "sprMM_QuestCompleteUntracked", 	bNeverShowOnEdge = true },
		QuestRewardSoldier		= { nOrder = 10,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Soldier_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardSettler		= { nOrder = 11,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Settler_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardScientist	= { nOrder = 12,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Scientist_Accepted", 	bNeverShowOnEdge = true },
		QuestRewardExplorer		= { nOrder = 13,	objectType = self.eObjectTypeQuestReward, 		strIcon = "IconSprites:Icon_MapNode_Map_Explorer_Accepted", 	bNeverShowOnEdge = true },
		QuestNew				= { nOrder = 14,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewSoldier			= { nOrder = 15,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewSettler			= { nOrder = 16,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewScientist		= { nOrder = 17,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewExplorer		= { nOrder = 18,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewMain			= { nOrder = 19,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewMainSoldier		= { nOrder = 20,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewMainSettler		= { nOrder = 21,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewMainScientist	= { nOrder = 22,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewMainExplorer	= { nOrder = 23,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewRepeatable		= { nOrder = 24,	objectType = self.eObjectTypeQuestNew, 			strIcon = "IconSprites:Icon_MapNode_Map_Quest", 	bNeverShowOnEdge = true },
		QuestNewRepeatableSoldier = { nOrder = 25,	objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestNewRepeatableSettler = { nOrder = 26,	objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestNewRepeatableScientist = { nOrder = 27,objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestNewRepeatableExplorer = { nOrder = 28,	objectType = self.eObjectTypeQuestNew, 		strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestReceiving			= { nOrder = 29,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "sprMM_QuestCompleteOngoing", 	bNeverShowOnEdge = true },
		QuestReceivingSoldier	= { nOrder = 30,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Soldier", 	bNeverShowOnEdge = true },
		QuestReceivingSettler	= { nOrder = 31,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Settler", 	bNeverShowOnEdge = true },
		QuestReceivingScientist	= { nOrder = 32,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Scientist", 	bNeverShowOnEdge = true },
		QuestReceivingExplorer	= { nOrder = 33,	objectType = self.eObjectTypeQuestReceiving, 	strIcon = "IconSprites:Icon_MapNode_Map_Explorer", 	bNeverShowOnEdge = true },
		QuestNewSoon			= { nOrder = 34,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Disabled", 	bNeverShowOnEdge = true },
		QuestNewMainSoon		= { nOrder = 35,	objectType = self.eObjectTypeQuestNewSoon, 		strIcon = "IconSprites:Icon_MapNode_Map_Quest_Disabled", 	bNeverShowOnEdge = true },
		ConvertItem				= { nOrder = 36,	objectType = self.eObjectTypeVendor_NMM_ConvertItem, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ResourceConversion", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		ConvertRep				= { nOrder = 37,	objectType = self.eObjectTypeVendor_NMM_ConvertRep, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Reputation", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Vendor					= { nOrder = 38,	objectType = self.eObjectTypeVendor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor", 	bNeverShowOnEdge = true, bFixedSizeMedium = true, bNMMPlainVendor = true },
		Mail					= { nOrder = 39,	objectType = self.eObject_NMM_Mailbox, 			strIcon = "IconSprites:Icon_MapNode_Map_Mailbox", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CityDirections			= { nOrder = 40,	objectType = self.eObjectType_NMM_Guards, 			strIcon = "IconSprites:Icon_MapNode_Map_CityDirections", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Dye						= { nOrder = 41,	objectType = self.eObjectType_NMM_Dye, 				strIcon = "IconSprites:Icon_MapNode_Map_DyeSpecialist", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPathSettler		= { nOrder = 42,	objectType = self.eObjectTypeVendorFlight, 		strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Flight", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPath				= { nOrder = 43,	objectType = self.eObjectTypeVendorFlightPathNew, strIcon = "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered", bNeverShowOnEdge = true, bFixedSizeMedium = true },
		FlightPathNew			= { nOrder = 44,	objectType = self.eObjectTypeVendorFlight, 		strIcon = "IconSprites:Icon_MapNode_Map_Taxi", 	bNeverShowOnEdge = true },
		TalkTo					= { nOrder = 45,	objectType = self.eObjectTypeQuestTarget, 		strIcon = "IconSprites:Icon_MapNode_Map_Chat", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		InstancePortal			= { nOrder = 46,	objectType = self.eObjectTypeInstancePortal, 	strIcon = "IconSprites:Icon_MapNode_Map_Portal", 	bNeverShowOnEdge = true },
		BindPoint				= { nOrder = 47,	objectType = self.eObjectTypeBindPointInactive, strIcon = "IconSprites:Icon_MapNode_Map_Gate", 	bNeverShowOnEdge = true },
		BindPointCurrent		= { nOrder = 48,	objectType = self.eObjectTypeBindPointActive, 	strIcon = "IconSprites:Icon_MapNode_Map_Gate", 	bNeverShowOnEdge = true },
		TradeskillTrainer		= { nOrder = 49,	objectType = self.eObject_NMM_TradeskillTrainer, 		strIcon = "IconSprites:Icon_MapNode_Map_Trainer", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CraftingStation			= { nOrder = 50,	objectType = self.eObject_NMM_CraftingStation, 		strIcon = "IconSprites:Icon_MapNode_Map_Tradeskill", 	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		CommodityMarketplace	= { nOrder = 51,	objectType = self.eObjectTypeCommodities, 		strIcon = "IconSprites:Icon_MapNode_Map_CommoditiesExchange", bNeverShowOnEdge = true },
		ItemAuctionhouse		= { nOrder = 52,	objectType = self.eObjectTypeAuctioneer, 		strIcon = "IconSprites:Icon_MapNode_Map_AuctionHouse", 	bNeverShowOnEdge = true },
		SettlerImprovement		= { nOrder = 53,	objectType = GameLib.CodeEnumMapOverlayType.PathObjective, strIcon = "CRB_MinimapSprites:sprMM_SmallIconSettler", bNeverShowOnEdge = true },
		Neutral					= { nOrder = 151,	objectType = self.eObjectTypeNeutral, 			strIcon = "ClientSprites:MiniMapMarkerTiny", 	bNeverShowOnEdge = true, bShown = false, crObject = ApolloColor.new("xkcdBrightYellow") },
		Hostile					= { nOrder = 150,	objectType = self.eObjectTypeHostile, 			strIcon = "ClientSprites:MiniMapMarkerTiny", 	bNeverShowOnEdge = true, bShown = false, crObject = ApolloColor.new("xkcdBrightRed") },
		EliteHostile			= { nOrder = 40,	objectType = self.eObjectTypeEliteHostile, 		strIcon = "sprNp_Target_HostileSecondary", 	bNeverShowOnEdge = true, bFixedSizeMedium = true, crObject = ApolloColor.new("xkcdBrightRed") },	
		EliteNeutral			= { nOrder = 40,	objectType = self.eObjectTypeEliteNeutral, 		strIcon = "sprNp_Target_NeutralSecondary", 	bNeverShowOnEdge = true, bFixedSizeMedium = true, crObject = ApolloColor.new("xkcdBrightYellow") },
		GroupMember				= { nOrder = 1,		objectType = self.eObjectTypeGroupMember, 		strIcon = "IconSprites:Icon_MapNode_Map_GroupMember", 	bFixedSizeLarge = true },
		Bank					= { nOrder = 54,	objectType = self.eObject_NMM_Bank,	 			strIcon = "IconSprites:Icon_MapNode_Map_Bank", 	bNeverShowOnEdge = true, bFixedSizeLarge = true },
		GuildBank				= { nOrder = 56,	objectType = self.eObject_NMM_GuildBank, 			strIcon = "IconSprites:Icon_MapNode_Map_Bank", 	bNeverShowOnEdge = true, bFixedSizeLarge = true, crObject = ApolloColor.new("yellow") },
		GuildRegistrar			= { nOrder = 55,	objectType = self.eObjectTypeVendor_NMM_GuildRegistrar, 			strIcon = "CRB_MinimapSprites:sprMM_Group", bNeverShowOnEdge = true, bFixedSizeLarge = true, crObject = ApolloColor.new("yellow") },
		VendorGeneral			= { nOrder = 38,	objectType = self.eObjectTypeVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor",	bNeverShowOnEdge = true, bFixedSizeMedium = true, bNMMPlainVendor = true},
		VendorArmor				= { nOrder = 38,	objectType = self.eObjectType_NMM_VendorArmor, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Armor",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorConsumable		= { nOrder = 38,	objectType = self.eObjectTypeVendor_NMM_Consumable, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Consumable",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorElderGem			= { nOrder = 38,	objectType = self.eObjectTypeVendor_NMM_ElderGem, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ElderGem",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorHousing			= { nOrder = 38,	objectType = self.eObjectTypeVendor_NMM_Housing, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Housing",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorMount				= { nOrder = 38,	objectType = self.eObjectType_NMM_VendorMount, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Mount",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorRenown			= { nOrder = 38,	objectType = self.eObjectTypeVendor_NMM_Renown, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Renown",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorReputation		= { nOrder = 38,	objectType = self.eObjectTypeVendor_NMM_Reputation, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Reputation",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorResourceConversion= { nOrder = 38,	objectType = self.eObjectTypeVendor_NMM_ResourceConversion, 			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_ResourceConversion",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorTradeskill		= { nOrder = 38,	objectType = self.eObjectType_NMM_TradeskillVendor,	strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Tradeskill",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorWeapon			= { nOrder = 38,	objectType = self.eObjectType_NMM_VendorWeapon,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Weapon",		bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPArena			= { nOrder = 38,	objectType = self.eObjectType_NMM_PvPArenaVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Arena",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPBattlegrounds	= { nOrder = 38,	objectType = self.eObjectType_NMM_PvPBattlegroundsVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Battlegrounds",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		VendorPvPWarplots		= { nOrder = 38,	objectType = self.eObjectType_NMM_PvPWarplotsVendor,			strIcon = "IconSprites:Icon_MapNode_Map_Vendor_Prestige_Warplot",	bNeverShowOnEdge = true, bFixedSizeMedium = true },
		Spirovine				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Spirovine", bFixedSizeMedium  = true},
		Bladeleaf				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Bladeleaf", bFixedSizeMedium = true},
		Yellowbell				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Yellowbell", bFixedSizeMedium = true},
		Pummelgranate			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Pummelgranate", bFixedSizeMedium = true},
		Serpentlily				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Serpentlily", bFixedSizeMedium = true},
		Goldleaf				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Goldleaf", bFixedSizeMedium = true},
		Honeywheat				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Honeywheat", bFixedSizeMedium = true},
		Crowncorn				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Crowncorn", bFixedSizeMedium = true},
		Coralscale				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Coralscale", bFixedSizeMedium = true},
		Logicleaf				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Logicleaf", bFixedSizeMedium = true},
		Stoutroot				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Stoutroot", bFixedSizeMedium = true},
		Glowmelon				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Glowmelon", bFixedSizeMedium = true},
		Faerybloom				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Faerybloom", bFixedSizeMedium = true},
		Witherwood				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Witherwood", bFixedSizeMedium = true},
		Flamefrond				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Flamefrond", bFixedSizeMedium = true},
		Grimgourd				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Grimgourd", bFixedSizeMedium = true},
		Mourningstar			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Mourningstar", bFixedSizeMedium = true},
		Bloodbriar				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Bloodbriar", bFixedSizeMedium = true},
		Octopod					= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Octopod", bFixedSizeMedium = true},
		Heartichoke				= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:Heartichoke", bFixedSizeMedium = true},
		SmlGrowthshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:GrowthShroom", bFixedSizeMedium = true},
		MedGrowthshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:GrowthShroom", bFixedSizeMedium = true},
		LrgGrowthshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:GrowthShroom", bFixedSizeMedium = true},
		SmlHarvestshroom		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:HarvestShroom", bFixedSizeMedium = true},
		MedHarvestshroom		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:HarvestShroom", bFixedSizeMedium = true},
		LrgHarvestshroom		= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:HarvestShroom", bFixedSizeMedium = true},
		SmlRenewshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:BlueRenewShroom", bFixedSizeMedium = true},
		MedRenewshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:BlueRenewShroom", bFixedSizeMedium = true},
		LrgRenewshroom			= { nOrder = 100, 	objectType = self.eObjectTypeFarmingNode,		strIcon = "GMM_FarmingSprites:BlueRenewShroom", bFixedSizeMedium = true},
		Iron					= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Iron", bFixedSizeMedium = true},
		Titanium				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Titanium", bFixedSizeMedium  = true},
		Zephyrite				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Zephyrite", bFixedSizeMedium = true},
		Platinum				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Platinum", bFixedSizeMedium = true},
		Hydrogem				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Hydrogem", bFixedSizeMedium = true},
		Xenocite				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Xenocite", bFixedSizeMedium = true},
		Shadeslate				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Shadeslate", bFixedSizeMedium = true},
		Galactium				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Galactium", bFixedSizeMedium = true},
		Novacite				= { nOrder = 100, 	objectType = self.eObjectTypeMiningNode,		strIcon = "GMM_MiningSprites:Novacite", bFixedSizeMedium = true},
		StandardRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:StandardRelic", bFixedSizeMedium = true},
		AcceleratedRelic		= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:AcceleratedRelic", bFixedSizeMedium = true},
		AdvancedRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:AdvancedRelic", bFixedSizeMedium = true},
		DynamicRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:DynamicRelic", bFixedSizeMedium = true},
		KineticRelic			= { nOrder = 100, 	objectType = self.eObjectTypeRelicHunterNode,	strIcon = "GMM_RelicSprites:KineticRelic", bFixedSizeMedium = true},
		AlgorocTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},		
		CelestionTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},		
		DeraduneTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},
		EllevarTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:KnottedHeartwood", bFixedSizeMedium = true},
		GalerasTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:IronbarkWood", bFixedSizeMedium = true},
		AuroriaTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:IronbarkWood", bFixedSizeMedium = true},
		WhitevaleTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		DreadmoorTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		FarsideTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		CoralusTree				= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:AncientWood", bFixedSizeMedium = true},
		MurkmireTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		WilderrunTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		MalgraveTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		HalonRingTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		GrimvaultTree			= { nOrder = 100, 	objectType = self.eObjectTypeSurvivalistNode,	strIcon = "GMM_SurvivalSprites:PrimalHardwood", bFixedSizeMedium = true},
		SettlerResource			= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconSettler", bFixedSizeMedium = true},
		ScientistScan			= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconScientist", bFixedSizeMedium = true},
		ExplorerInterest		= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconExplorer", bFixedSizeMedium = true},
		ExplorerTrailblazer		= { nOrder = 100, 	objectType = self.eObjectTypePathResource,		strIcon = "CRB_MinimapSprites:sprMM_SmallIconExplorer", bFixedSizeMedium = true, crObject=CColor.new(1.0, 0.0, 0.0, 1.0)},
		LoreBook				= { nOrder = 100, 	objectType = self.eObjectTypeLore,				strIcon = "CRB_HUDAlerts:sprAlert_BookBase", bFixedSizeMedium = true},
		LoreDatacube			= { nOrder = 100, 	objectType = self.eObjectTypeLore,				strIcon = "GMM_OtherSprites:MinimapDatacube", bFixedSizeMedium = true},
		QuestCritter			= { nOrder = 6,		objectType = self.eObjectTypeQuestCritter, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true },
		QuestCritterNeutral		= { nOrder = 6,		objectType = self.eObjectTypeQuestCritter, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true, crObject = ApolloColor.new("xkcdBrightYellow") },
		QuestCritterHostile		= { nOrder = 6,		objectType = self.eObjectTypeQuestCritter, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true, crObject = ApolloColor.new("xkcdBrightRed") },
		QuestItemTarget			= { nOrder = 6,		objectType = self.eObjectTypeQuestItem, 		strIcon = "GMM_OtherSprites:GMM_QuestTarget", 	bNeverShowOnEdge = true, bFixedSizeSmall = true },
		FlaggedPC				= { nOrder = 150,	objectType = self.eObjectTypePC, 				strIcon = "GMM_OtherSprites:GMM_EnemyPC", crObject = ApolloColor.new("xkcdBrightRed") },
		UnflaggedPC				= { nOrder = 150,	objectType = self.eObjectTypePC, 				strIcon = "GMM_OtherSprites:GMM_EnemyPC", crObject = ApolloColor.new("xkcdBrightYellow") }
	}
end

function NexusMiniMap:Init()
	Apollo.RegisterAddon(self)
	-- Moving this event register into the init to make sure no latency spikes or load delay will
	-- cause us to miss units
	Apollo.RegisterEventHandler("UnitCreated", 							"OnUnitCreated", self)
end

function NexusMiniMap:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("NexusMiniMap.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function NexusMiniMap:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
	
	Apollo.RegisterEventHandler("CharacterCreated", 					"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("OptionsUpdated_QuestTracker", 			"OnOptionsUpdated", self)
	Apollo.RegisterEventHandler("VarChange_ZoneName", 					"OnChangeZoneName", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 						"OnChangeZoneName", self)

	Apollo.RegisterEventHandler("QuestObjectiveUpdated", 				"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("QuestStateChanged", 					"OnQuestStateChanged", self)
	Apollo.RegisterEventHandler("GenericEvent_QuestTrackerRenumbered", 	"OnQuestStateChanged", self)

	Apollo.RegisterEventHandler("FriendshipAdd", 						"OnFriendshipAdd", self)
	Apollo.RegisterEventHandler("FriendshipRemove", 					"OnFriendshipRemove", self)
	Apollo.RegisterEventHandler("FriendshipAccountFriendsRecieved",  	"OnFriendshipAccountFriendsRecieved", self)
	Apollo.RegisterEventHandler("FriendshipAccountFriendRemoved",   	"OnFriendshipAccountFriendRemoved", self)

	Apollo.RegisterEventHandler("ReputationChanged",   					"OnReputationChanged", self)

	Apollo.RegisterEventHandler("TargetUnitChanged", 					"OnTargetChanged", self)

	Apollo.RegisterEventHandler("UnitDestroyed", 						"OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("UnitActivationTypeChanged", 			"OnUnitChanged", self)
	Apollo.RegisterEventHandler("UnitMiniMapMarkerChanged", 			"OnUnitChanged", self)

	Apollo.RegisterEventHandler("ChallengeAbandon",						"OnChallengeAbandon", self)
	Apollo.RegisterEventHandler("ChallengeFailArea", 					"OnFailChallenge", self)
	Apollo.RegisterEventHandler("ChallengeFailTime", 					"OnFailChallenge", self)
	Apollo.RegisterEventHandler("ChallengeFailGeneric", 				"OnFailChallenge", self)
	Apollo.RegisterEventHandler("ChallengeAbandonConfirmed", 			"OnRemoveChallengeIcon", self)
	Apollo.RegisterEventHandler("ChallengeActivate", 					"OnAddChallengeIcon", self)
	Apollo.RegisterEventHandler("ChallengeCompleted", 					"OnChallengeCompleted", self)
	Apollo.RegisterEventHandler("ChallengeFlashStartLocation", 			"OnFlashChallengeIcon", self)

	Apollo.RegisterEventHandler("PlayerPathMissionActivate", 			"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 				"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathMissionDeactivate", 			"OnPlayerPathMissionDeactivate", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapStarted", 	"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PlayerPathExplorerPowerMapFailed", 	"OnPlayerPathMissionActivate", self)
	Apollo.RegisterEventHandler("PublicEventStart", 					"OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveUpdate", 			"OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("PublicEventEnd", 						"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventLeave",						"OnPublicEventEnd", self)
	Apollo.RegisterEventHandler("PublicEventLocationAdded", 			"OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventLocationRemoved", 			"OnPublicEventUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveLocationAdded", 	"OnPublicEventObjectiveUpdate", self)
	Apollo.RegisterEventHandler("PublicEventObjectiveLocationRemoved", 	"OnPublicEventObjectiveUpdate", self)

	Apollo.RegisterEventHandler("CityDirectionMarked",					"OnCityDirectionMarked", self)
	Apollo.RegisterEventHandler("ZoneMap_TimeOutCityDirectionEvent",	"OnZoneMap_TimeOutCityDirectionEvent", self)

	Apollo.RegisterEventHandler("MapGhostMode", 						"OnMapGhostMode", self)
	Apollo.RegisterEventHandler("ToggleGhostModeMap",					"OnToggleGhostModeMap", self) -- for key input toggle on/off
	Apollo.RegisterEventHandler("HazardShowMinimapUnit", 				"OnHazardShowMinimapUnit", self)
	Apollo.RegisterEventHandler("HazardRemoveMinimapUnit", 				"OnHazardRemoveMinimapUnit", self)
	Apollo.RegisterEventHandler("ZoneMapPing", 							"OnMapPing", self)
	Apollo.RegisterEventHandler("UnitPvpFlagsChanged", 					"OnUnitPvpFlagsChanged", self)

	Apollo.RegisterEventHandler("PlayerLevelChange",					"UpdateHarvestableNodes", self)

	Apollo.RegisterTimerHandler("ChallengeFlashIconTimer", 				"OnStopChallengeFlashIcon", self)
	Apollo.RegisterTimerHandler("OneSecTimer",							"OnOneSecTimer", self)
	
	-- Adding a taxi hook to be able to refresh the map after landing
	-- "Borrowed" from GuardMiniMap
	Apollo.RegisterEventHandler("TaxiWindowClose", 						"OnTaxiWindowClose", self)
	
	Apollo.RegisterTimerHandler("PingTimer",							"OnPingTimer", self)
	Apollo.CreateTimer("PingTimer", 1, false)
	Apollo.StopTimer("PingTimer")

	--Group Events
	Apollo.RegisterEventHandler("Group_Join", 							"OnGroupJoin", self)					-- ()
	Apollo.RegisterEventHandler("Group_Add", 							"OnGroupAdd", self)						-- ( name )
	Apollo.RegisterEventHandler("Group_Invite_Result",					"OnGroupInviteResult", self)			-- ( name, result )
	Apollo.RegisterEventHandler("Group_Remove", 						"OnGroupRemove", self)					-- ( name, result )
	Apollo.RegisterEventHandler("Group_Left", 							"OnGroupLeft", self)					-- ( reason )

	Apollo.RegisterEventHandler("Tutorial_RequestUIAnchor", 			"OnTutorial_RequestUIAnchor", self)

	Apollo.LoadSprites("GMM_FarmingSprites.xml") 	
	Apollo.LoadSprites("GMM_MiningSprites.xml") 
	Apollo.LoadSprites("GMM_RelicSprites.xml") 
	Apollo.LoadSprites("GMM_SurvivalSprites.xml") 
	Apollo.LoadSprites("GMM_OtherSprites.xml") 


	if (self.bSquareMap and self.bSquareMap == true)  then
		if (self.bHideCompass and self.bHideCompass == true) then
			Apollo.LoadSprites("SquareMapTextures_NoCompass.xml")
		else
			Apollo.LoadSprites("SquareMapTextures.xml")
		end
	else
		if (self.bHideCompass and self.bHideCompass == true) then
			Apollo.LoadSprites("CircleMapTextures_NoCompass.xml")
		else
			Apollo.LoadSprites("CircleMapTextures.xml")
		end
	end
		
	if self.bCustomPlayerArrow and self.bCustomPlayerArrow == true then
		Apollo.LoadSprites("GMM_CustomPlayerArrow.xml")
	end
	
	if self.bSquareMap and self.bSquareMap == true then	
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "SquareMinimap", "FixedHudStratum", self)
	else
	self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "Minimap", "FixedHudStratum", self)
	end
	self.wndNexusMiniMap 		= self.wndMain:FindChild("MapContent")
	self.wndZoneName 		= self.wndMain:FindChild("MapZoneName")
	self.wndPvPFlagName 	= self.wndMain:FindChild("MapZonePvPFlag")
	self.wndRangeLabel 		= self.wndMain:FindChild("RangeToTargetLabel")
	self:UpdateZoneName(GetCurrentZoneName())
	self.wndMinimapButtons 	= self.wndMain:FindChild("ButtonContainer")
	if self.fSavedZoomLevel then
		self.wndNexusMiniMap:SetZoomLevel( self.fSavedZoomLevel)
	end
	
	self.wndMinimapOptions 	= Apollo.LoadForm(self.xmlDoc , "MinimapOptions", nil, self)
	self.wndMinimapOptions:Show(false)

	self.wndFilterTownies 	= Apollo.LoadForm(self.xmlDoc , "FilterTownies", nil, self)
	self.wndFilterTownies:Show(false)

	self.wndPvPVendors 	= Apollo.LoadForm(self.xmlDoc , "PvPVendors", nil, self)
	self.wndPvPVendors:Show(false)

	self.wndNexusMiniMapOptions 	= Apollo.LoadForm(self.xmlDoc , "NexusMiniMapOptions", nil, self)
	self.wndNexusMiniMapOptions:Show(false)	 

	if self.bCustomQuestArrow and self.bCustomQuestArrow == true then
		self.wndNexusMiniMapOptions:FindChild("NexusBtnCustomQuestArrow"):SetCheck(true)
	end
		
	if self.bCustomPlayerArrow and self.bCustomPlayerArrow == true then
		self.wndNexusMiniMapOptions:FindChild("NexusBtnCustomPlayerArrow"):SetCheck(true)
	end

 	if self.bSquareMap and self.bSquareMap == true then
		self.wndNexusMiniMapOptions:FindChild("NexusBtnSquareMap"):SetCheck(true)

	else	
		self.wndNexusMiniMapOptions:FindChild("NexusBtnSquareMap"):SetCheck(false)
	end
	if not self.bHideFrame or self.bHideFrame == false then
		self.wndNexusMiniMapOptions:FindChild("NexusBtnHideMapFrame"):SetCheck(false)

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(true)
		end

		self.bHideFrame = false
	else
		self.wndNexusMiniMapOptions:FindChild("NexusBtnHideMapFrame"):SetCheck(true)

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(false)
		end
	end

	
	if GameLib.GetPlayerUnit() and GameLib.GetPlayerUnit():IsValid() then
		self.nFactionId = GameLib.GetPlayerUnit():GetFaction()
	end

		
	self.wndMain:FindChild("MapMenuButton"):AttachWindow(self.wndMinimapOptions)
	self.wndMinimapOptions:FindChild("OptionsBtnFilterTownies"):AttachWindow(self.wndFilterTownies)
	self.wndMain:SetSizingMinimum(150, 150)
	self.wndMain:SetSizingMaximum(400, 400)

	self.wndMegaMapBtnOverlay 	= self.wndMain:FindChild("MapToggleBtnOverlay")
	self.wndMegaMapBtnOverlay:Show(false)

	self:CreateOverlayObjectTypes() -- ** IMPORTANT ** This function must run before you do anything involving overlay types!
	self:BuildCustomMarkerInfo()

	self.tChallengeObjects 			= {}
	self.ChallengeFlashingIconId 	= nil
	self.tUnitsShown 				= {}	-- For Quests, PublicEvents, Vendors, Instance Portals, and Bind Points which all use UnitCreated/UnitDestroyed events
	self.tUnitsHidden 				= {}	-- Units that we're tracking but are out of the current subzone
	self.tObjectsShown 				= {} -- For Challenges which use their own events
	self.tObjectsShown.Challenges 	= {}
	self.tPingObjects 				= {}
	self.arResourceNodes			= {}

	

	self.tGroupMembers 			= {}
	self.tGroupMemberObjects 	= {}
	if not self.tQueuedUnits then
		self.tQueuedUnits = {}--necessary when characters don't have a saved file for minimap
	else
		for idx, unit in pairs(self.tQueuedUnits) do
			self.HandleUnitCreated(unit)
		end
	end

	if not self.tUnitsAll then	
		self.tUnitsAll = {}	
	end
	self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	if self.unitPlayerDisposition ~= nil then
		self:OnCharacterCreated()
	end
	self.bQuestTrackerByDistance 		= g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerByDistance or false

	if not self.tToggledIcons then
		self.tToggledIcons =
		{
			[self.eObjectTypeHostile] 						= true,
			[self.eObjectTypeNeutral] 						= true,
			[self.eObjectTypeGroupMember] 					= true,
			[self.eObjectTypeQuestReward]					= true,
			[self.eObjectTypeVendor] 						= true,
			[self.eObjectTypeBindPointActive] 				= true,
			[self.eObjectTypeInstancePortal] 				= true,
			[self.eObjectTypePublicEvent] 					= true,
			[self.eObjectTypeQuestTarget]					= true, 
			[GameLib.CodeEnumMapOverlayType.QuestObjective] = true,
			[GameLib.CodeEnumMapOverlayType.PathObjective] 	= true,
			[self.eObjectTypeChallenge] 					= true,
			[self.eObjectTypeMiningNode] 					= true,
			[self.eObjectTypeRelicHunterNode] 				= true,
			[self.eObjectTypeSurvivalistNode] 				= true,
			[self.eObjectTypeFarmingNode] 					= true,
  			[self.eObjectTypeTrainer] 						= true,
			[self.eObjectTypeFriend] 						= true,
			[self.eObjectTypeRival] 						= true,
			[self.eObject_NMM_Bank]							= true,
			[self.eObjectType_NMM_Dye]						= true,
			[self.eObjectType_NMM_Guards]					= true,
			[self.eObject_NMM_GuildBank]					= true,
			[self.eObject_NMM_Mailbox]						= true,
			[self.eObject_NMM_CraftingStation]				= true,
			[self.eObject_NMM_TradeskillTrainer]			= true,
			[self.eObjectType_NMM_VendorArmor]				= true,
			[self.eObjectType_NMM_VendorMount]				= true,
			[self.eObjectType_NMM_VendorWeapon]				= true,
			[self.eObjectType_NMM_PvPArenaVendor]			= true,
			[self.eObjectType_NMM_PvPBattlegroundsVendor]	= true,
			[self.eObjectType_NMM_PvPWarplotsVendor]		= true,
			[self.eObjectTypeVendor_NMM_Renown]				= true,
			[self.eObjectTypeVendor_NMM_Reputation]			= true,
			[self.eObjectTypeVendor_NMM_ResourceConversion]	= true,
			[self.eObjectTypeVendor_NMM_ConvertItem]		= true,
			[self.eObjectTypeVendor_NMM_ConvertRep]			= true,
			[self.eObjectTypeVendor_NMM_GuildRegistrar]		= true,
			[self.eObjectTypeVendor_NMM_Consumable]			= true,
			[self.eObjectTypeVendor_NMM_ElderGem]			= true,
			[self.eObjectTypeVendor_NMM_Housing]			= true,
			[self.eObjectTypeEliteHostile]					= true,
			[self.eObjectTypeEliteNeutral]					= true,
			[self.eObjectTypeUniqueFarming]					= false,
			[self.eObjectTypeUniqueMining]					= true,
			[self.eObjectTypeUniqueRelic]					= true,
			[self.eObjectTypeUniqueSurvival]				= true,
			[self.eObjectTypePathResource]					= true,
			[self.eObjectTypeLore]							= true,
			[self.eObjectTypeQuestItem]						= true,
			[self.eObjectTypeQuestCritter]					= false,
			[self.eObjectTypePC]							= false
		}
	end
	
	self:ReloadPublicEvents()
	self:ReloadMissions()
	self:OnQuestStateChanged()
	
	
	
	local tUIElementToType =
	{
		["OptionsBtnQuests"] 			= self.eObjectTypeQuestReward,
		["OptionsBtnTracked"] 			= GameLib.CodeEnumMapOverlayType.QuestObjective,
		["OptionsBtnMissions"] 			= GameLib.CodeEnumMapOverlayType.PathObjective,
		["OptionsBtnChallenges"] 		= self.eObjectTypeChallenge,
		["OptionsBtnPublicEvents"] 		= self.eObjectTypePublicEvent,
		["OptionsBtnVendors"] 			= self.eObjectTypeVendor,
		["OptionsBtnInstancePortals"] 	= self.eObjectTypeInstancePortal,
		["OptionsBtnBindPoints"] 		= self.eObjectTypeBindPointActive,
		["OptionsBtnMiningNodes"] 		= self.eObjectTypeMiningNode,
		["OptionsBtnRelicNodes"] 		= self.eObjectTypeRelicHunterNode,
		["OptionsBtnSurvivalistNodes"] 	= self.eObjectTypeSurvivalistNode,
		["OptionsBtnFarmingNodes"] 		= self.eObjectTypeFarmingNode,
		["OptionsBtnCreaturesN"] 		= self.eObjectTypeNeutral,
		["OptionsBtnCreaturesH"] 		= self.eObjectTypeHostile,
		["OptionsBtnFriends"]			= self.eObjectTypeFriend,
		["OptionsBtnRivals"] 			= self.eObjectTypeRival
	}
	-- Removing defaut buttons from options
	-- ["OptionsBtnGuards"] 			= self.eObjectTypeGuards,
	-- ["OptionsBtnTradeskills"] 		= self.eObjectTypeTradeskills,
	-- ["OptionsBtnTrainer"] 			= self.eObjectTypeTrainer,
	local wndOptionsWindow = self.wndMinimapOptions:FindChild("MapOptionsWindow")
	for strWindowName, eType in pairs(tUIElementToType) do
		local wndOptionsBtn = wndOptionsWindow:FindChild(strWindowName)
		wndOptionsBtn:SetData(eType)
		wndOptionsBtn:SetCheck(self.tToggledIcons[eType])
	end
	
	-- Custom hook for FilterTownies

	local tFilterTowniesUIElementToType =
	{   ["FilterTowniesBtnBank"]				= self.eObject_NMM_Bank,
		["FilterTowniesBtnDye"] 				= self.eObjectType_NMM_Dye,
		["FilterTowniesBtnGuards"]				= self.eObjectType_NMM_Guards,
		["FilterTowniesBtnGuildBank"]			= self.eObject_NMM_GuildBank,
		["FilterTowniesBtnMailBox"] 			= self.eObject_NMM_Mailbox,
		["FilterTowniesBtnCraftingStation"]		= self.eObject_NMM_CraftingStation,
		["FilterTowniesBtnTradeskillTrainer"]	= self.eObject_NMM_TradeskillTrainer,
		["FilterTowniesBtnTradeskillVendor"]	= self.eObjectType_NMM_TradeskillVendor,
		["FilterTowniesBtnVendorArmor"]			= self.eObjectType_NMM_VendorArmor,
		["FilterTowniesBtnVendorMount"]			= self.eObjectType_NMM_VendorMount,
		["FilterTowniesBtnVendorWeapon"]		= self.eObjectType_NMM_VendorWeapon,
		["FilterTowniesBtnVendorRenown"]		= self.eObjectTypeVendor_NMM_Renown,
		["FilterTowniesBtnVendorReputation"]	= self.eObjectTypeVendor_NMM_Reputation,
		["FilterTowniesBtnVendorResourceConversion"] 		= self.eObjectTypeVendor_NMM_ResourceConversion,
		["FilterTowniesBtnVendorConvertItem"]	= self.eObjectTypeVendor_NMM_ConvertItem,
		["FilterTowniesBtnVendorConvertRep"]	= self.eObjectTypeVendor_NMM_ConvertRep,
		["FilterTowniesBtnVendorGuildRegistrar"]	= self.eObjectTypeVendor_NMM_GuildRegistrar,
		["FilterTowniesBtnVendorConsumable"]	= self.eObjectTypeVendor_NMM_Consumable,
		["FilterTowniesBtnVendorElderGem"]	= self.eObjectTypeVendor_NMM_ElderGem,
		["FilterTowniesBtnVendorHousing"]	= self.eObjectTypeVendor_NMM_Housing

	}



	local wndFilterTowniesWindow = self.wndFilterTownies:FindChild("FilterTowniesWindow")
	for strWindowName, eType in pairs(tFilterTowniesUIElementToType ) do
		local wndFilterTownieBtn = wndFilterTowniesWindow:FindChild(strWindowName)
		wndFilterTownieBtn:SetData(eType)
		wndFilterTownieBtn:SetCheck(self.tToggledIcons[eType])
	end
	
		-- Custom hook for PvPVendors
		
	local tFilterPvPUIElementToType =
	{   ["FilterPvPBtnPvPArenaVendor"]			= self.eObjectType_NMM_PvPArenaVendor,
		["FilterPvPBtnPvPBattlegroundsVendor"]	= self.eObjectType_NMM_PvPBattlegroundsVendor,
		["FilterPvPBtnPvPWarplotsVendor"]		= self.eObjectType_NMM_PvPWarplotsVendor
	}	
	
	local wndPvPVendorsWindow= self.wndPvPVendors:FindChild("PvPVendorsWindow")
	for strWindowName, eType in pairs(tFilterPvPUIElementToType ) do
		local wndPvPVendorsBtn = wndPvPVendorsWindow:FindChild(strWindowName)
		wndPvPVendorsBtn:SetData(eType)
		wndPvPVendorsBtn:SetCheck(self.tToggledIcons[eType])
	end

	-- Custom hook for Nexus Custom Options
		
	local tNexusCutomizeUIElementToType =
	{   
		["NexusBtnSquareMap"]			= self.eObjectTypeUniqueFarming,
		["NexusBtnHideMapFrame"]			= self.eObjectTypeUniqueFarming,
		["NexusBtnCustomQuestArrow"]			= self.eObjectTypeUniqueFarming,
		["NexusBtnCustomPlayerArrow"]			= self.eObjectTypeUniqueFarming,
		["NexusBtnPrimeNeutral"]			= self.eObjectTypeEliteNeutral,
		["NexusBtnPrimeHostiles"]			= self.eObjectTypeEliteHostile,
		["NexusBtnEnemyPC"]			= self.eObjectTypePC,
		["NexusBtnQuestCritter"]			= self.eObjectTypeQuestCritter,
		["NexusBtnQuestItems"]			= self.eObjectTypeQuestItem,
		["NexusBtnFarmingNodes"]			= self.eObjectTypeUniqueFarming,
		["NexusBtnMininglNodes"]			= self.eObjectTypeUniqueMining,
		["NexusBtnRelicNodes"]			= self.eObjectTypeUniqueRelic,
		["NexusBtnSurvivalNodes"]			= self.eObjectTypeUniqueSurvival,
		["NexusBtnPathResources"]			= self.eObjectTypePathResource,
		["NexusBtnLoreDatacube"]			= self.eObjectTypeLore

	}	
	
	local wndNexusMiniMapOptionsWindow = self.wndNexusMiniMapOptions:FindChild("NexusMiniMapOptionsWindow")
	for strWindowName, eType in pairs(tNexusCutomizeUIElementToType ) do
		local wndNexusMiniMapOptionsBtn = wndNexusMiniMapOptionsWindow:FindChild(strWindowName)
		wndNexusMiniMapOptionsBtn:SetData(eType)
		wndNexusMiniMapOptionsBtn:SetCheck(self.tToggledIcons[eType])
	end
	
	if g_wndTheNexusMiniMap == nil then
		g_wndTheNexusMiniMap = self.wndNexusMiniMap
	end
end

function NexusMiniMap:OnCharacterCreated()
	if(not self.unitPlayerDisposition ) then
		self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	end
	local ePath = self.unitPlayerDisposition:GetPlayerPathType()

	if ePath == PlayerPathLib.PlayerPathType_Soldier then
		self.wndMinimapOptions:FindChild("Image_Soldier"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Explorer then
		self.wndMinimapOptions:FindChild("Image_Explorer"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Scientist then
		self.wndMinimapOptions:FindChild("Image_Scientist"):Show(true)
	elseif ePath == PlayerPathLib.PlayerPathType_Settler then
		self.wndMinimapOptions:FindChild("Image_Settler"):Show(true)
	end
end

function NexusMiniMap:OnOptionsUpdated()
	if g_InterfaceOptions and g_InterfaceOptions.Carbine.bQuestTrackerByDistance ~= nil then
		self.bQuestTrackerByDistance = g_InterfaceOptions.Carbine.bQuestTrackerByDistance
	else
		self.bQuestTrackerByDistance = true
	end

	self:OnQuestStateChanged()
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnSave(eType)
	if eType == GameLib.CodeEnumAddonSaveLevel.Account then
		local tAllUnits = {}
	
		if self.tUnitsAll then
			for idUnit, unit in pairs(self.tUnitsAll) do
				tAllUnits[idUnit] = idUnit
		end
	end
	
	local tSavedData =
	{
			fZoomLevel = self.wndNexusMiniMap:GetZoomLevel(),
		tToggled = self.tToggledIcons,
        tSavedAllUnits = tAllUnits,
			tHideCompass = self.bHideCompass,
			tSquareMap = self.bSquareMap,
			bCustomQuestArrow = self.bCustomQuestArrow,
			bHideFrame = self.bHideFrame,
			bShowCoords = self.bShowCoords,
			bHideCoordFrame = self.bHideCoordFrame, 
			bShowTaxisOnZoneMap = self.bShowTaxisOnZoneMap,
			nMapOpacity = self.nMapOpacity,
			bRotateMap = self.bRotateMap,
			bCustomPlayerArrow = self.bCustomPlayerArrow
	}

	return tSavedData

	elseif eType == GameLib.CodeEnumAddonSaveLevel.Character then	
		local tSavedData =
		{
			tSavedWaypoints = g_tGuardWaypoints,
			tSavedColor = self.tDefaultColor
		}

		return tSavedData
	end
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnRestore(eType, tSavedData)
	self.tSavedData = tSavedData
	if eType == GameLib.CodeEnumAddonSaveLevel.Account then
		if tSavedData.fZoomLevel then
			self.fSavedZoomLevel = tSavedData.fZoomLevel
		end

		if tSavedData.tToggled then
			self.tToggledIcons = tSavedData.tToggled
		end
	
		if tSavedData.tSquareMap then
			self.bSquareMap = tSavedData.tSquareMap
		end
	
		if tSavedData.bHideFrame then
			self.bHideFrame = tSavedData.bHideFrame
		end
	
		if tSavedData.tHideCompass then
			self.bHideCompass = tSavedData.tHideCompass
		end
	
		if tSavedData.bShowCoords then
			self.bShowCoords = tSavedData.bShowCoords
		end
	
		if tSavedData.bRotateMap then
			self.bRotateMap = tSavedData.bRotateMap
		end
	
		if tSavedData.bHideCoordFrame then
			self.bHideCoordFrame = tSavedData.bHideCoordFrame
		end
	
		if tSavedData.bShowTaxisOnZoneMap then
			self.bShowTaxisOnZoneMap = tSavedData.bShowTaxisOnZoneMap
		end
	
		if tSavedData.nMapOpacity then
			self.nMapOpacity = tSavedData.nMapOpacity 
		end
	
		if tSavedData.bCustomQuestArrow then
			self.bCustomQuestArrow = tSavedData.bCustomQuestArrow
		end	
		
		if tSavedData.bCustomPlayerArrow then
			self.bCustomPlayerArrow = tSavedData.bCustomPlayerArrow
		end

		if not self.tQueuedUnits then
			self.tQueuedUnits = {}
		end

		if not self.tUnitsAll then
			self.tUnitsAll = {}
		end
	
		if tSavedData.tSavedAllUnits then
			for idx, idUnit in pairs(tSavedData.tSavedAllUnits) do
				local unitAll = GameLib.GetUnitById(idUnit)
				if unitAll and unitAll:IsValid() then
					self.tUnitsAll[idUnit] = unitAll
					self.tQueuedUnits[idUnit] = unitAll
				end
			end
		end

	elseif eType == GameLib.CodeEnumAddonSaveLevel.Character then	

		if tSavedData.tSavedWaypoints then
			self.tGuardWaypoints = tSavedData.tSavedWaypoints
		end

		if tSavedData.tSavedColor then
			self.tDefaultColor = tSavedData.tSavedColor
		end
	end
end

function NexusMiniMap:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("MiniMap_Title")})
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:ReloadMissions()
	--self.wndNexusMiniMap:RemoveObjectsByType(GameLib.CodeEnumMapOverlayType.PathObjective)
	local epiCurrent = PlayerPathLib.GetCurrentEpisode()
	if epiCurrent then
		for idx, pmCurr in ipairs(epiCurrent:GetMissions()) do
			self:OnPlayerPathMissionActivate(pmCurr)
		end
	end
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnChangeZoneName(oVar, strNewZone)
	self:UpdateZoneName(strNewZone)

	self:RefreshMap()
end

function NexusMiniMap:DelayRefreshMap()

	-- Depending on the speed of your system, the call from ChallengeCompleted
	-- to refresh map can finish before the system registers the entire challenge is 
	-- completed, this delay resolves that issue
	if not self.RefreshTimer then
		self.RefreshTimer = ApolloTimer.Create(1, false, "RefreshMap", self)
	end

end

function NexusMiniMap:RefreshMap()
	if self.wndNexusMiniMap == nil or self.tToggledIcons == nil then
		return
	end
	-- update mission indicators
	self:ReloadMissions()

	-- update quest indicators	 self:UpdateQuestMarkers()

	-- update public events
	self:ReloadPublicEvents()

	-- update all already shown units
  	if self.tUnitsAll then
		for idx, tCurrUnit in pairs(self.tUnitsAll) do
			if tCurrUnit then
				self.wndNexusMiniMap:RemoveUnit(tCurrUnit)
				-- Switching to use the base idx in case the tCurrUnit has become invalid
				-- or lost its ID
				self.tUnitsAll[idx] = nil
				self:OnUnitCreated(tCurrUnit)
			end
		end
    end


	-- check for any units that are now back in the subzone
	if self.RefreshTimer then
		self.RefreshTimer = nil
	end

	self:OnOneSecTimer()

end

function NexusMiniMap:UpdateZoneName(strZoneName)
	if strZoneName == nil then
		return
	end

	local tInstanceSettingsInfo = GameLib.GetInstanceSettings()

	local strDifficulty = nil
	if tInstanceSettingsInfo.eWorldDifficulty == GroupLib.Difficulty.Veteran then
		strDifficulty = ktInstanceSettingTypeStrings.Veteran
	end

	local strScaled = nil
	if tInstanceSettingsInfo.bWorldForcesLevelScaling == true then
		strScaled = ktInstanceSettingTypeStrings.Rallied
	end

	local strAdjustedZoneName = strZoneName
	if strDifficulty and strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. "-" .. strScaled .. ")"
	elseif strDifficulty then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. ")"
	elseif strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strScaled .. ")"
	end

	self.wndZoneName:SetText(strAdjustedZoneName)
	self:UpdatePvpFlag()
end

function NexusMiniMap:OnUnitPvpFlagsChanged(unitChanged)
	if not unitChanged:IsThePlayer() then
		return
	end
	self:UpdatePvpFlag()
end

function NexusMiniMap:UpdatePvpFlag()
	local nZoneRules = GameLib.GetCurrentZonePvpRules()

	if GameLib.IsPvpServer() == true then
		self.wndPvPFlagName:Show(true)
	else
		self.wndPvPFlagName:Show(nZoneRules ~= GameLib.CodeEnumZonePvpRules.DominionPVPStronghold and nZoneRules ~= GameLib.CodeEnumZonePvpRules.ExilePVPStronghold)
	end

	self.wndPvPFlagName:SetText(ktPvPZoneTypes[nZoneRules] or "")
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnMenuBtn()
	if self.wndMinimapOptions:IsVisible() then
		self.wndMinimapOptions:Show(false)
		
	else
		self.wndMinimapOptions:Show(true)
		self.wndMain:ToFront()
		self.wndMinimapOptions:ToFront()
	end
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnMenuBtnToggle(wndHandler, wndControl)

	if wndControl:IsChecked() then
		local bIsMiner, bIsRelicHunter, bIsSurvivalist, bIsFarmer = false, false, false, false
		
		for idx, tTradeskill in pairs(CraftingLib.GetKnownTradeskills() or {}) do
	
			local tTradeskillInfo = CraftingLib.GetTradeskillInfo(tTradeskill.eId)
			
			if (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Mining) and tTradeskillInfo.bIsActive then
				bIsMiner = true
			elseif (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Relic_Hunter) and tTradeskillInfo.bIsActive then
				bIsRelicHunter = true
			elseif (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Survivalist) and tTradeskillInfo.bIsActive then
				bIsSurvivalist = true
			elseif (tTradeskill.eId == CraftingLib.CodeEnumTradeskill.Farmer) and tTradeskillInfo.bIsActive then
				bIsFarmer = true
			end
		
		end
		
		self.wndMinimapOptions:FindChild("OptionsBtnMiningNodes"):Enable(bIsMiner)
		self.wndMinimapOptions:FindChild("OptionsBtnRelicNodes"):Enable(bIsRelicHunter)
		self.wndMinimapOptions:FindChild("OptionsBtnSurvivalistNodes"):Enable(bIsSurvivalist)
		self.wndMinimapOptions:FindChild("OptionsBtnFarmingNodes"):Enable(bIsFarmer)
	end

	self.wndMinimapOptions:Show(wndControl:IsChecked())
end

---------------------------------------------------------------------------------------------------
--Options
---------------------------------------------------------------------------------------------------

function NexusMiniMap:OnMinusBtn()
	self.wndNexusMiniMap:ZoomOut()
	Sound.Play(Sound.PlayUI15ZoomOutPhysical)
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnPlusBtn()
	self.wndNexusMiniMap:ZoomIn()
	Sound.Play(Sound.PlayUI14ZoomInPhysical)
end

function NexusMiniMap:OnMapToggleBtn()
	Event_FireGenericEvent("ToggleZoneMap")
end

function NexusMiniMap:OnMapGhostMode(bMode) -- Turn on/off the ghost mode notice
	self.wndMegaMapBtnOverlay:Show(bMode)
end

function NexusMiniMap:OnToggleGhostModeMap() -- Turn on/off the ghost mode button (for key input toggle on and off)
	local bShow = not self.wndMegaMapBtnOverlay:IsShown()
	self.wndMegaMapBtnOverlay:Show(bShow)
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnRotateMapCheck()
	--self.wndMinimapOptions:FindChild("OptionsBtnRotate"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLPressed")
	self.wndNexusMiniMap:SetMapOrientation(2)
end

function NexusMiniMap:OnRotateMapUncheck()
	--self.wndMinimapOptions:FindChild("OptionsBtnRotate"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLNormal")
	self.wndNexusMiniMap:SetMapOrientation(0)
end

function NexusMiniMap:OnRangeFinderCheck()
	self.wndMinimapOptions:FindChild("OptionsBtnRange"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLPressed")
	self.bFindRange = true
end

function NexusMiniMap:OnRangeFinderUncheck()
	self.wndMinimapOptions:FindChild("OptionsBtnRange"):FindChild("Image"):SetSprite("CRB_UIKitSprites:btn_radioSMALLNormal")
	self.bFindRange = false
	self.wndRangeLabel:Show(false)
end

function NexusMiniMap:OnMapPing(idUnit, tPos )

	for idx, tCur in pairs(self.tPingObjects) do
		if tCur.idUnit == idUnit then
			self.wndNexusMiniMap:RemoveObject(tCur.objMapPing)
			self.tPingObjects[idx] = nil
		end
	end

	local tInfo =
	{
		strIcon = "sprMap_PlayerPulseFast",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "",
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = true,
	}
	
	table.insert(self.tPingObjects, {["idUnit"] = idUnit, ["objMapPing"] = self.wndNexusMiniMap:AddObject(self.eObjectTypePing, tPos, "", tInfo), ["nTime"] = GameLib.GetGameTime()})
	
	Apollo.StartTimer("PingTimer")

end

function NexusMiniMap:OnPingTimer()

	local nCurTime = GameLib.GetGameTime()
	local nNumUnits = 0
	for idx, tCur in pairs(self.tPingObjects) do
		if (tCur.nTime + 5) < nCurTime then
			self.wndNexusMiniMap:RemoveObject(tCur.objMapPing)
			self.tPingObjects[idx] = nil
		else
			nNumUnits = nNumUnits + 1
		end
	end
		
	if nNumUnits == 0 then
		Apollo.StopTimer("PingTimer")
	else
		Apollo.StartTimer("PingTimer")
	end

end

----------------------------------------------------------------------------------------------
-- Chat commands for range finder option
-----------------------------------------------------------------------------------------------
function NexusMiniMap:OnRangeSlashCommand(cmd, arg1)

end

function NexusMiniMap:OnMouseMove(wndHandler, wndControl, nX, nY)

end

function NexusMiniMap:OnMapClick(wndHandler, wndControl, eButton, nX, nY, bDouble)

end

function NexusMiniMap:OnMouseButtonUp(eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)

end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnFailChallenge(tChallengeData)
	self:OnRemoveChallengeIcon(tChallengeData:GetId())
end

function NexusMiniMap:OnRemoveChallengeIcon(chalOwner)
	if self.tChallengeObjects[chalOwner] ~= nil then
		self.wndNexusMiniMap:RemoveObject(self.tChallengeObjects[chalOwner])
	end
	if self.tObjectsShown.Challenges ~= nil then
		for idx, tCurr in pairs(self.tObjectsShown.Challenges) do
			self.wndNexusMiniMap:RemoveObject(idx)
		end
	end
	self.tObjectsShown.Challenges = {}
end

function NexusMiniMap:OnAddChallengeIcon(chalOwner, strDescription, tPosition)
	if self.tChallengeObjects[chalOwner:GetId()] ~= nil then
		self.wndNexusMiniMap:RemoveObject(self.tChallengeObjects[chalOwner:GetId()])
		self.tChallengeObjects[chalOwner:GetId()] = nil

		-- make sure we turn off the flash icon just in case
		self:OnStopChallengeFlashIcon()
	end

	local tInfo =
	{
		strIcon = "MiniMapObject",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "sprMM_ChallengeArrow",
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = true,
	}
	if tPosition ~= nil then
		if self.tObjectsShown.Challenges == nil then
			self.tObjectsShown.Challenges = {}
		end

		self.tChallengeObjects[chalOwner] = self.wndNexusMiniMap:AddObject(self.eObjectTypeChallenge, tPosition, strDescription, tInfo, {}, not self.tToggledIcon[self.eObjectTypeChallenge])
		self.tObjectsShown.Challenges[self.tChallengeObjects[chalOwner]] = {tPosition = tPosition, strDescription = strDescription}
	end
end

function NexusMiniMap:OnFlashChallengeIcon(chalOwner, strDescription, fDuration, tPosition)
	if self.tChallengeObjects[chalOwner] ~= nil then
		self.wndNexusMiniMap:RemoveObject(self.tChallengeObjects[chalOwner])
	end

	if self.tToggledIcons[self.eObjectTypeChallenge] ~= false then
		-- TODO: Need to change the icon to a flashing icon
		local tInfo =
		{
			strIcon 		= "sprMM_QuestZonePulse",
			crObject 		= CColor.new(1, 1, 1, 1),
			strIconEdge 	= "sprMM_PathArrowActive",
			crEdge 			= CColor.new(1, 1, 1, 1),
			bAboveOverlay 	= true,
		}

		self.tChallengeObjects[chalOwner] = self.wndNexusMiniMap:AddObject(self.eObjectTypeChallenge, tPosition, strDescription, tInfo, {}, false)
		self.ChallengeFlashingIconId = chalOwner

		-- create the timer to turn off this flashing icon
		Apollo.StopTimer("ChallengeFlashIconTimer")
		Apollo.CreateTimer("ChallengeFlashIconTimer", fDuration, false)
		Apollo.StartTimer("ChallengeFlashIconTimer")
	end
end

function NexusMiniMap:OnStopChallengeFlashIcon()

	if self.ChallengeFlashingIconId and self.tChallengeObjects[self.ChallengeFlashingIconId] then
		self.wndNexusMiniMap:RemoveObject(self.tChallengeObjects[self.ChallengeFlashingIconId])
		self.tChallengeObjects[self.ChallengeFlashingIconId] = nil
	end

	self.ChallengeFlashingIconId = nil
end

---------------------------------------------------------------------------------------------------

function NexusMiniMap:OnPlayerPathMissionActivate(pmActivated)
	if self.tToggledIcons == nil then
		return
	end

	self:OnPlayerPathMissionDeactivate(pmActivated)

	local tInfo =
	{
		strIcon 	= pmActivated:GetMapIcon(),
		crObject 	= CColor.new(1, 1, 1, 1),
		strIconEdge = "",
		crEdge 		= CColor.new(1, 1, 1, 1),
	}

	self.wndNexusMiniMap:AddPathIndicator(pmActivated, tInfo, {bNeverShowOnEdge = true, bFixedSizeSmall = false}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.PathObjective])
end

function NexusMiniMap:OnPlayerPathMissionDeactivate(pmDeactivated)
	self.wndNexusMiniMap:RemoveObjectsByUserData(GameLib.CodeEnumMapOverlayType.PathObjective, pmDeactivated)
end

---------------------------------------------------------------------------------------------------

function NexusMiniMap:ReloadPublicEvents()
	local tEvents = PublicEvent.GetActiveEvents()
	for idx, peCurr in ipairs(tEvents) do
		self:OnPublicEventUpdate(peCurr)
	end
end

function NexusMiniMap:OnPublicEventUpdate(peUpdated)
	self:OnPublicEventEnd(peUpdated)

	if not peUpdated:IsActive() or self.tToggledIcons == nil then
		return
	end

	local tInfo =
	{
		strIcon = "sprMM_POI",
		crObject = CColor.new(1, 1, 1, 1),
		strIconEdge = "sprMM_QuestArrowActive",
		crEdge = CColor.new(1, 1, 1, 1),
	}

	for idx, tPos in ipairs(peUpdated:GetLocations()) do
		self.wndNexusMiniMap:AddObject(self.eObjectTypePublicEvent, tPos, peUpdated:GetName(), tInfo, {bNeverShowOnEdge = peUpdated:ShouldShowOnMiniMapEdge(), bFixedSizeSmall = false}, not self.tToggledIcons[self.eObjectTypePublicEvent], peUpdated)
	end

	for idx, peoCurr in ipairs(peUpdated:GetObjectives()) do
		self:OnPublicEventObjectiveUpdate(peoCurr)
	end
end

function NexusMiniMap:OnPublicEventEnd(peEnding)
	self.wndNexusMiniMap:RemoveObjectsByUserData(self.eObjectTypePublicEvent, peEnding)

	for idx, peoCurr in ipairs(peEnding:GetObjectives()) do
		self:OnPublicEventObjectiveEnd(peoCurr)
	end
end

function NexusMiniMap:OnPublicEventObjectiveUpdate(peoUpdated)
	self:OnPublicEventObjectiveEnd(peoUpdated)

	if peoUpdated:GetStatus() ~= PublicEventObjective.PublicEventStatus_Active then
		return
	end

	local tInfo =
	{
		strIcon 	= "sprMM_POI",
		crObject 	= CColor.new(1, 1, 1, 1),
		strIconEdge = "MiniMapObjectEdge",
		crEdge 		= CColor.new(1,1, 1, 1),
	}

	bHideOnEdge = (peoUpdated:ShouldShowOnMinimapEdge() ~= true)

	for idx, tPos in ipairs(peoUpdated:GetLocations()) do
		self.wndNexusMiniMap:AddObject(self.eObjectTypePublicEvent, tPos, peoUpdated:GetShortDescription(), tInfo, {bNeverShowOnEdge = hideOnEdge, bFixedSizeSmall = false}, not self.tToggledIcons[self.eObjectTypePublicEvent], peoUpdated)
	end
end

function NexusMiniMap:OnPublicEventObjectiveEnd(peoUpdated)
	self.wndNexusMiniMap:RemoveObjectsByUserData(self.eObjectTypePublicEvent, peoUpdated)
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnCityDirectionMarked(tLocInfo)
	if not self.wndNexusMiniMap or not self.wndNexusMiniMap:IsValid() then
		return
	end

	local tInfo =
	{
		strIconEdge = "",
		strIcon 	= "sprMM_QuestTrackedActivate",
		crObject 	= CColor.new(1, 1, 1, 1),
		crEdge 		= CColor.new(1, 1, 1, 1),
	}

	-- Only one city direction at a time, so stomp and remove and previous
	self.wndNexusMiniMap:RemoveObjectsByUserData(self.eObjectTypeCityDirection, Apollo.GetString("ZoneMap_CityDirections"))
	self.wndNexusMiniMap:AddObject(self.eObjectTypeCityDirection, tLocInfo.tLoc, tLocInfo.strName, tInfo, {bFixedSizeSmall = false}, false, Apollo.GetString("ZoneMap_CityDirections"))
	Apollo.StartTimer("ZoneMap_TimeOutCityDirectionMarker")
end

function NexusMiniMap:OnZoneMap_TimeOutCityDirectionEvent()
	if not self.wndNexusMiniMap or not self.wndNexusMiniMap:IsValid() then
		return
	end

	self.wndNexusMiniMap:RemoveObjectsByUserData(self.eObjectTypeCityDirection, Apollo.GetString("ZoneMap_CityDirections"))
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnQuestStateChanged()
	self.tEpisodeList = QuestLib.GetTrackedEpisodes(self.bQuestTrackerByDistance)

	self:RefreshMap()
	end


function NexusMiniMap:UpdateQuestMarkers()		-- Clear episode list	self.wndNexusMiniMap:RemoveObjectsByType(GameLib.CodeEnumMapOverlayType.QuestObjective)	-- Iterate over all the episodes adding the active one	local nCount = 0	for idx, epiCurr in ipairs(self.tEpisodeList) do		-- Add entries for each quest in the episode		for idx2, queCurr in ipairs(epiCurr:GetTrackedQuests(0, self.bQuestTrackerByDistance)) do			local eQuestState = queCurr:GetState()			nCount = nCount + 1 -- number the quest
			if queCurr:IsActiveQuest() then				local tInfo =				{					strIcon 	= "ActiveQuestIcon",					crObject 	= CColor.new(1, 1, 1, 1),					strIconEdge = "sprMM_QuestArrowActivate",					crEdge 		= CColor.new(1, 1, 1, 1),				}				-- This is a C++ call on the MiniMapWindow class				self.wndNexusMiniMap:AddQuestIndicator(queCurr, tostring(nCount), tInfo, {bOnlyShowOnEdge = false, bAboveOverlay = true}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])			elseif not queCurr:IsActiveQuest() and self.tToggledIcons[self.eObjectTypeQuestReward] then				local tInfo				if self.bCustomQuestArrow and self.bCustomQuestArrow == true then					tInfo = 					{						strIcon = "sprMM_QuestTracked",						crObject = CColor.new(1, 1, 1, 1),						strIconEdge = "GMM_SolidPathArrow",						crEdge = CColor.new(1, 1, 1, 1),					}				else					tInfo = 					{						strIcon = "sprMM_QuestTracked",						crObject = CColor.new(1, 1, 1, 1),						strIconEdge = "sprMM_SolidPathArrow",						crEdge = CColor.new(1, 1, 1, 1),					}				end				-- This is a C++ call on the MiniMapWindow class				self.wndNexusMiniMap:AddQuestIndicator(queCurr, tostring(nCount), tInfo, {bOnlyShowOnEdge = false, bFixedSizeMedium = false, bAboveOverlay = true}, not self.tToggledIcons[GameLib.CodeEnumMapOverlayType.QuestObjective])			end		end	endend
---------------------------------------------------------------------------------------------------

-- "Borrowed from GuardMiniMap
-- There's some weirdness happening with taxis where the minimap is losing
-- content, the UnitCreated is properly called for everything, so this
-- lets me detect when a taxi is taken so I can redraw the map after landing
function NexusMiniMap:OnTaxiWindowClose()
	self.tTaxiTimer = ApolloTimer.Create(1, true, "OnTaxiTimer", self)
end

function NexusMiniMap:OnTaxiTimer()
	if GameLib:GetPlayerTaxiUnit() ~= nil then
		self.bOnTaxi = true
	elseif self.bOnTaxi ~= nil then
		self.tTaxiTimer:Stop()
		self.tTaxiTimer = nil
		self.bOnTaxi = nil
		self:RefreshMap()
	else
		self.tTaxiTimer:Stop()
		self.tTaxiTimer = nil
	end
end

function NexusMiniMap:OnOneSecTimer()
	if self.tQueuedUnits == nil then
		return
	end

	self.unitPlayerDisposition = GameLib.GetPlayerUnit()
	if self.unitPlayerDisposition == nil or not self.unitPlayerDisposition:IsValid() then
		return
	end

	for id,unit in pairs(self.tQueuedUnits) do
		if unit:IsValid() then
			self:HandleUnitCreated(unit)
		end
	end

	self.tQueuedUnits = {}
end

function NexusMiniMap:OnTargetChanged(unitNew)
	--if unitNew == nil or not unitNew:IsValid() then
		--return
	--end
--
	--local tAS = unitNew:GetActivationState()
	--
	--local tURI = unitNew:GetRewardInfo()
	--local nRewardCount = self:GetTableLength(tURI)
--
	--Print(nRewardCount)
--
	--if 	tAS ~= nil
		--and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
		--and tURI ~= nil 
		--and ((tAS.Collect ~= nil and tAS.Collect.bCanInteract == true) or (tAS.Interact ~= nil and tAS.Interact.bCanInteract == true)) then
--
	--
	--end
end

function NexusMiniMap:OnUnitCreated(unitNew)
	if self.nNumUnits then
		self.nNumUnits = self.nNumUnits + 1
	else
		self.nNumUnits = 1
	end

	if unitNew == nil or not unitNew:IsValid() or unitNew == GameLib.GetPlayerUnit() then
		return
	end
	
	if not self.tUnitsAll then
		self.tUnitsAll = {}
	end

	if not self.tQueuedUnits then
		self.tQueuedUnits = {}
	end

	self.tUnitsAll[unitNew:GetId()] = unitNew
	self.tQueuedUnits[unitNew:GetId()] = unitNew
end

function NexusMiniMap:GetDefaultUnitInfo()
	local tInfo =
	{
		strIcon = "",
		strIconEdge = "MiniMapObjectEdge",
		crObject = CColor.new(1, 1, 1, 1),
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = false,
	}
	return tInfo
end

function NexusMiniMap:UpdateHarvestableNodes()
	for idx, unitResource in pairs(self.arResourceNodes) do
		if unitResource:CanBeHarvestedBy(GameLib.GetPlayerUnit()) then
			self:OnUnitChanged(unitResource)
			self.arResourceNodes[unitResource:GetId()] = nil
		end
	end
end

function NexusMiniMap:GetTableLength(curTable)
	local tableLength = 0
	
	if(curTable ~= nil) then
		for key, value in pairs(curTable) do
			tableLength = tableLength + 1
		end
	end
	
	return tableLength 
end
------------
-- ***Assumption*** It appears all vendors are flagged as either Vendor or VendorGeneral
-- Purpose is to remove the default C icon on the minimap for all vendors with custom NMM objects
-- This now allows the addon to filter vendor by a grainular method
-- Updated method to check for a custom property called bNMMPlainVendor that has been
-- added to Vendor and VendorGeneral in the tMinimapMarkerInfo table at the top of the file.
-- This check is to find if the object we are working with is a vendor or not.  
-- Once we are working with a vendor we check to see if it is a custom NMM object if so
-- We add that custom object to the tTempMarkerInfos then after looping through we check
-- to see if the temp table has any data if it does we overwrite the tMarkerInfos with just
-- the temp data.
-- Steampunkhawk
------------
function NexusMiniMap:GetOrderedMarkerInfos(tMarkerStrings, unitNew)
	local tMarkerInfos = {}
	local tTempMarkerInfos = {}

			
	-- Adding logic to allow for displaying Path Resources and Lore items on the minimap
	-- Adding logic to allow for custom "Prime" mob icons to be displayed			
	local tAS = unitNew:GetActivationState()
	local strUnitType = unitNew:GetType()
	local tURI = unitNew:GetRewardInfo()
	local nRewardCount = self:GetTableLength(tURI)
	local eDisposition = unitNew:GetDispositionTo(GameLib.GetPlayerUnit())
	local bActiveChallenge = false
	local bActiveQuestTarget = false
	local bActiveQuestItem = false

	if not self.tActiveChallenges then
		self.tActiveChallenges = {}
	end

	-- Only parse through the quest critters if the option is checked
	-- save some processing time for those people who don't want to see them anyway
	if	(self.tToggledIcons[self.eObjectTypeQuestCritter] or self.tToggledIcons[self.eObjectTypeQuestItem])
		and tURI ~= nil
		and nRewardCount > 0 then

		for idx = 1, nRewardCount do

			local strRewardType = tURI[idx].strType

			if strRewardType == "Challenge" 
			   and self.tActiveChallenges[tURI[idx].idChallenge] then

				bActiveChallenge = true

			end

			-- TODO:  There is an issue here still blocking some "critters"
			-- from showing up -- they are alive but are nil level and not interactable
			-- but still needed for a quest
			if	strRewardType == "Quest"
				and (tAS == nil or tAS.Interact == nil)
				and unitNew:GetLevel() ~= nil
				and strUnitType ~= "Simple" then

				bActiveQuestTarget = true

			end

			if strRewardType == "Quest"
				and (tAS == nil or tAS.Interact == nil)
				and (tURI[idx].nNeeded ~= nil and tURI[idx].nCompleted < tURI[idx].nNeeded)
				and strUnitType == "Simple" then

				bActiveQuestItem = true

			end

			if bActiveChallenge or bActiveQuestTarget or bActiveQuestItem then
				break
			end
		end
	end

	if unitNew:IsACharacter()
	   and (not unitNew:IsRival() or not self.tToggledIcons[self.eObjectTypeRival])
	   and (eDisposition == Unit.CodeEnumDisposition.Hostile or eDisposition == Unit.CodeEnumDisposition.Neutral)
	   and self.tToggledIcons[self.eObjectTypePC] then

	   	if (unitNew:IsPvpFlagged()) then
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["FlaggedPC"])
		else
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["UnflaggedPC"])
		end

	elseif (bActiveChallenge or bActiveQuestTarget) and self.tToggledIcons[self.eObjectTypeQuestCritter] then

		if eDisposition == Unit.CodeEnumDisposition.Hostile then	
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestCritterHostile"])
		elseif eDisposition == Unit.CodeEnumDisposition.Neutral then	
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestCritterNeutral"])
		else
			table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestCritter"])
		end
	elseif bActiveQuestItem == true and self.tToggledIcons[self.eObjectTypeQuestItem] then
		table.insert(tMarkerInfos, self.tMinimapMarkerInfo["QuestItemTarget"])
	else
		for nMarkerIdx, strMarker in ipairs(tMarkerStrings) do
			if strMarker then
				local tMarkerOverride	
			
				if 	tAS ~= nil
					and strUnitType == "Collectible"
					and GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Settler
					and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
					and (tAS.Interact ~= nil and tAS.Interact.bCanInteract == true)
					and (tAS.Spell ~= nil)
					and (tAS.Collect ~= nil and tAS.Collect.bUsePlayerPath == true)
					and self.tToggledIcons[self.eObjectTypePathResource] then

					tMarkerOverride = self.tMinimapMarkerInfo["SettlerResource"]				
				elseif 	tAS ~= nil
						and GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Scientist
						and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
						and (tAS.ScientistScannable or tAS.ScientistRawScannable)
						and self.tToggledIcons[self.eObjectTypePathResource] then
					
					tMarkerOverride = self.tMinimapMarkerInfo["ScientistScan"]				
				elseif 	tAS ~= nil
						and GameLib.GetPlayerUnit():GetPlayerPathType() == PlayerPathLib.PlayerPathType_Explorer
						and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)
						and (tAS.ExplorerInterest) 
						and self.tToggledIcons[self.eObjectTypePathResource] then

					tMarkerOverride = self.tMinimapMarkerInfo["ExplorerInterest"]					
				elseif 	tAS ~= nil
					and tAS.Datacube ~= nil 
					and self.tToggledIcons[self.eObjectTypeLore] then
					
					if unitNew:GetName():find("DATA") ~= nil then					
						tMarkerOverride = self.tMinimapMarkerInfo["LoreDatacube"]
					else					
						tMarkerOverride = self.tMinimapMarkerInfo["LoreBook"]
					end	
				elseif ((self.tToggledIcons[self.eObjectTypeEliteHostile] and eDisposition == Unit.CodeEnumDisposition.Hostile) 
						or (self.tToggledIcons[self.eObjectTypeEliteNeutral] and eDisposition == Unit.CodeEnumDisposition.Neutral))
						and unitNew:GetDifficulty() >= 3 and not (unitNew:IsDead() or unitNew:IsACharacter()) then

					tMarkerOverride = self.tMinimapMarkerInfo["Elite" .. strMarker]
				elseif 	tAS ~= nil						and (tAS.Busy == nil or tAS.Busy.bCanInteract == true)						and tURI ~= nil and nRewardCount > 0						and tAS.Door == nil						and ((tAS.Collect ~= nil and tAS.Collect.bCanInteract == true) or (tAS.Interact ~= nil and tAS.Interact.bCanInteract == true))						and self.tToggledIcons[self.eObjectTypeQuestItem] then											tMarkerOverride = self.tMinimapMarkerInfo["QuestItemTarget"]										
				else
					tMarkerOverride = self.tMinimapMarkerInfo[strMarker]
				end
			
				-- Adding logic to allow for custom harvest node icons to be displayed
				if tMarkerOverride  and 
					((tMarkerOverride.objectType == self.eObjectTypeFarmingNode and self.tToggledIcons[self.eObjectTypeUniqueFarming])
					or (tMarkerOverride.objectType == self.eObjectTypeMiningNode and self.tToggledIcons[self.eObjectTypeUniqueMining])
					or (tMarkerOverride.objectType == self.eObjectTypeRelicHunterNode and self.tToggledIcons[self.eObjectTypeUniqueRelic])
					or (tMarkerOverride.objectType == self.eObjectTypeSurvivalistNode and self.tToggledIcons[self.eObjectTypeUniqueSurvival])) then
				
					tMarkerOverride = self.tMinimapMarkerInfo[strMarker:gsub("Node", "")]
				elseif tMarkerOverride then 
					if not tMarkerOverride.bNMMPlainVendor then
						table.insert(tTempMarkerInfos, tMarkerOverride)
					end
				end

				if tMarkerOverride then									
					table.insert(tMarkerInfos, tMarkerOverride)
				end
			end
		end
	end
	
	if table.getn(tTempMarkerInfos) ~= 0 then
		tMarkerInfos = tTempMarkerInfos
	end

	table.sort(tMarkerInfos, function(x, y) return x.nOrder < y.nOrder end)
	return tMarkerInfos
end


function NexusMiniMap:HandleUnitCreated(unitNew)

	if not unitNew or not unitNew:IsValid() then
		return
	end
	
	if self.tUnitsAll and self.tUnitsAll[unitNew:GetId()] then
		self.wndNexusMiniMap:RemoveUnit(unitNew)
	end

	local bShowUnit = unitNew:IsVisibleOnCurrentZoneMinimap()

	if bShowUnit == false then
		return
	end
	
	local tMarkers = unitNew:GetMiniMapMarkers()
	if tMarkers == nil then
		return
	end
	
	local tMarkerInfoList = self:GetOrderedMarkerInfos(tMarkers, unitNew)
	
	for nIdx, tMarkerInfo in ipairs(tMarkerInfoList) do
		local tInfo = self:GetDefaultUnitInfo()
		if tMarkerInfo.strIcon  then
			tInfo.strIcon = tMarkerInfo.strIcon
		end
		if tMarkerInfo.crObject then
			tInfo.crObject = tMarkerInfo.crObject
		end
		if tMarkerInfo.crEdge   then
			tInfo.crEdge = tMarkerInfo.crEdge
		end

		local tMarkerOptions = {bNeverShowOnEdge = true}
		if tMarkerInfo.bAboveOverlay then
			tMarkerOptions.bAboveOverlay = tMarkerInfo.bAboveOverlay
		end
		if tMarkerInfo.bShown then
			tMarkerOptions.bShown = tMarkerInfo.bShown
		end
		-- only one of these should be set
		if tMarkerInfo.bFixedSizeSmall then
			tMarkerOptions.bFixedSizeSmall = tMarkerInfo.bFixedSizeSmall
		elseif tMarkerInfo.bFixedSizeMedium then
			tMarkerOptions.bFixedSizeMedium = tMarkerInfo.bFixedSizeMedium
		end

		local objectType = GameLib.CodeEnumMapOverlayType.Unit
		if tMarkerInfo.objectType then
			objectType = tMarkerInfo.objectType
		end

		self.wndNexusMiniMap:AddUnit(unitNew, objectType, tInfo, tMarkerOptions, self.tToggledIcons[objectType] ~= nil and not self.tToggledIcons[objectType])
	end

end

function NexusMiniMap:OnHazardShowMinimapUnit(idHazard, unitHazard, bIsBeneficial)

	if unitHazard == nil then
		return
	end

	--local unit = GameLib.GetUnitById(unitId)
	local tInfo

	tInfo =
	{
		strIcon = "",
		strIconEdge = "",
		crObject = CColor.new(1, 1, 1, 1),
		crEdge = CColor.new(1, 1, 1, 1),
		bAboveOverlay = false,
	}


	if bIsBeneficial then
		tInfo.strIcon = "sprMM_ZoneBenefit"
	else
		tInfo.strIcon = "sprMM_ZoneHazard"
	end

	self.wndNexusMiniMap:AddUnit(unitHazard, self.eObjectTypeHazard, tInfo, {bNeverShowOnEdge = true, bFixedSizeMedium = true}, false)
end

function NexusMiniMap:OnHazardRemoveMinimapUnit(idHazard, unitHazard)
	if unitHazard == nil then
		return
	end

	self.wndNexusMiniMap:RemoveUnit(unitHazard)
end

function NexusMiniMap:OnUnitChanged(unitUpdated, eType)
	if unitUpdated == nil then
		return
	end

	self.wndNexusMiniMap:RemoveUnit(unitUpdated)
	self.tUnitsAll[unitUpdated:GetId()] = nil
	self:OnUnitCreated(unitUpdated)
end

function NexusMiniMap:OnUnitDestroyed(unitDestroyed)
	self.tUnitsAll[unitDestroyed:GetId()] = nil
	self.arResourceNodes[unitDestroyed:GetId()] = nil
end

-- GROUP EVENTS

function NexusMiniMap:OnGroupJoin()
	--for idx = 1, GroupLib.GetMemberCount() do
		--local tInfo = GroupLib.GetGroupMember(idx)
		--if tInfo.bIsOnline then
			--self:OnUnitCreated(GroupLib.GetUnitForGroupMember(idx))
		--end
	--end

	self:RefreshMap()
		end

function NexusMiniMap:OnGroupAdd(strName)
	--for idx = 1, GroupLib.GetMemberCount() do
		--local tInfo = GroupLib.GetGroupMember(idx)
		--if tInfo.bIsOnline then
			--self:OnUnitCreated(GroupLib.GetUnitForGroupMember(idx))
		--end
	--end

	self:RefreshMap()
	end

function NexusMiniMap:OnGroupInviteResult(strName, eResult)
	--for idx = 1, GroupLib.GetMemberCount() do
		--local tInfo = GroupLib.GetGroupMember(idx)
		--if tInfo.bIsOnline then
			--self:OnUnitCreated(GroupLib.GetUnitForGroupMember(idx))
		--end
	--end

	self:RefreshMap()
end

function NexusMiniMap:OnGroupRemove(strName, eReason)
	self:RefreshMap()
	-- need to filter to only that group member
end

function NexusMiniMap:OnGroupLeft(eReason)
	self:RefreshMap()
	-- need to filter to only that group member
end

---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnGenerateTooltip(wndHandler, wndControl, eType, nX, nY)
	local xml = nil
	local crWhite = CColor.new(1, 1, 1, 1)
	if eType ~= Tooltip.TooltipGenerateType_Map then
		wndControl:SetTooltipDoc(nil)
		return
	end

	local nCount = 0
	local bNeedToAddLine = true
	local tClosestObject = nil
	local nShortestDist = 0

	local tMapObjects = self.wndNexusMiniMap:GetObjectsAtPoint(nX, nY)
	if not tMapObjects or #tMapObjects == 0 then
		wndControl:SetTooltipDoc(nil)
		return
	end

	for key, tObject in pairs(tMapObjects) do
		if tObject.unit then
			local nDistSq = (nX - tObject.ptMap.x) * (nX - tObject.ptMap.x) + (nY - tObject.ptMap.y) * (nY - tObject.ptMap.y)
			if tClosestObject == nil or nDistSq < nShortestDist then
				tClosestObject = tObject
				nShortestDist = nDistSq
			end
			nCount = nCount + 1
		end
	end

	-- Merged unit tooltips does not work at all with current lua based tooltips
	-- TODO: FIXME
	--[[
	if tClosestObject then
		tClosestObject.bMarked = true
		xml = Tooltip.GetUnitTooltipForm(self, wndControl, tClosestObject.unit)
		nCount = nCount - 1
	end]]--

	if not xml then
		xml = XmlDoc.new()
		xml:StartTooltip(Tooltip.TooltipWidth)
		bNeedToAddLine = false
	end

	-- Iterate map objects
	local nObjectCount = 0
	local tStringsAdded = {}
	for key, tObject in pairs(tMapObjects) do
		if nObjectCount == 5 then
			nObjectCount = nObjectCount + 1

			local tInfo =
			{
				["name"] = Apollo.GetString("CRB_Unit"),
				["count"] = nCount
			}
			xml:AddLine(String_GetWeaselString(Apollo.GetString("MiniMap_OtherUnits"), tInfo), crWhite, "CRB_InterfaceMedium")
		elseif nObjectCount > 5 then
			-- Do nothing
		elseif tObject.strName == "" then
			-- Do nothing
		elseif tObject.strName and not tObject.bMarked then
			if bNeedToAddLine then
				xml:AddLine(" ")
			end
			bNeedToAddLine = false

			if not tStringsAdded[tObject.strName] then
				nObjectCount = nObjectCount + 1
				xml:AddLine(tObject.strName, crWhite, "CRB_InterfaceMedium")
				tStringsAdded[tObject.strName] = true
			end
		end
	end
	
	if nObjectCount > 0 then
		wndControl:SetTooltipDoc(xml)
	else
		wndControl:SetTooltipDoc(nil)
	end
end

function NexusMiniMap:OnFriendshipAccountFriendsRecieved(tFriendAccountList)
	for idx, tFriend in pairs(tFriendAccountList) do
		self:OnRefreshRadar(FriendshipLib.GetUnitById(tFriend.nId))
	end
end

function NexusMiniMap:OnFriendshipAdd(nFriendId)
	self:OnRefreshRadar(FriendshipLib.GetUnitById(nFriendId))
end

function NexusMiniMap:OnFriendshipRemove(nFriendId)
	self:OnRefreshRadar(FriendshipLib.GetUnitById(nFriendId))
end

function NexusMiniMap:OnFriendshipAccountFriendsRecieved(tFriendAccountList)
	self:OnRefreshRadar()
end

function NexusMiniMap:OnFriendshipAccountFriendRemoved(nId)
	self:OnRefreshRadar()
end

function NexusMiniMap:OnReputationChanged(tFaction)
	self:OnRefreshRadar()
end

function NexusMiniMap:OnRefreshRadar(newUnit)
	if newUnit ~= nil and newUnit:IsValid() then
		self:OnUnitCreated(newUnit)
	else
		for idx, tCur in pairs(self.tUnitsAll) do
			self:OnUnitCreated(tCur.unitObject)
		end
	end
end

function NexusMiniMap:OnMiniMapMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	self.wndMain:FindChild("ZoomInButton"):Show(true)
	self.wndMain:FindChild("ZoomOutButton"):Show(true)
	self.wndMain:FindChild("MapToggleBtn"):Show(true)
	self.wndMain:FindChild("MapMenuButton"):Show(true)
	self.wndMain:FindChild("MiniMapResizeArtForPixie"):Show(true)
end

function NexusMiniMap:OnMiniMapMouseExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	self.wndMain:FindChild("ZoomInButton"):Show(false)
	self.wndMain:FindChild("ZoomOutButton"):Show(false)
	self.wndMain:FindChild("MapToggleBtn"):Show(false)
	self.wndMain:FindChild("MapMenuButton"):Show(false)
	self.wndMain:FindChild("MiniMapResizeArtForPixie"):Show(false)
end

---------------------------------------------------------------------------------------------------
-- Tutorial anchor request
---------------------------------------------------------------------------------------------------
function NexusMiniMap:OnTutorial_RequestUIAnchor(eAnchor, idTutorial, strPopupText)
	if eAnchor ~= GameLib.CodeEnumTutorialAnchor.NexusMiniMap then
		return
	end

	local tRect = {}
	tRect.l, tRect.t, tRect.r, tRect.b = self.wndMain:GetRect()

	Event_FireGenericEvent("Tutorial_RequestUIAnchorResponse", eAnchor, idTutorial, strPopupText, tRect)
end

---------------------------------------------------------------------------------------------------
-- MinimapOptions Functions
---------------------------------------------------------------------------------------------------

function NexusMiniMap:OnFilterOptionCheck(wndHandler, wndControl, eMouseButton)
	local data = wndControl:GetData()	if data == nil then		return	end		self.tToggledIcons[data] = true	if data == self.eObjectTypeQuestReward then		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeQuestReward)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeQuestReceiving)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeQuestNew)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeQuestNewSoon)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeQuestTarget)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeQuestKill)	elseif data == self.eObjectTypeBindPointActive then		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeBindPointActive)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeBindPointInactive)	elseif data == self.eObjectTypeVendor then		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeVendor)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeAuctioneer)		self.wndNexusMiniMap:ShowObjectsByType(self.eObjectTypeCommodity)	elseif data == self.eObjectTypeEliteNeutral 			or data == self.eObjectTypeEliteHostile 			or data == self.eObjectTypeUniqueFarming			or data == self.eObjectTypeUniqueMining			or data == self.eObjectTypeUniqueRelic			or data == self.eObjectTypeUniqueSurvival			or data == self.eObjectTypeLore			or data == self.eObjectTypeQuestItem			or data == self.eObjectTypeQuestCritter			or data == self.eObjectTypePathResource then		-- update all already shown units		self:RefreshMap()	else		self.wndNexusMiniMap:ShowObjectsByType(data)	end
end

function NexusMiniMap:OnFilterOptionUncheck(wndHandler, wndControl, eMouseButton)
	local data = wndControl:GetData()
	if data == nil then
		return
	end

	self.tToggledIcons[data] = false

	if data == self.eObjectTypeQuestReward then
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeQuestReward)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeQuestReceiving)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeQuestNew)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeQuestNewSoon)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeQuestTarget)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeQuestKill)
	elseif data == self.eObjectTypeBindPointActive then
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeBindPointActive)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeBindPointInactive)
	elseif data == self.eObjectTypeVendor then
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeVendor)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeAuctioneer)
		self.wndNexusMiniMap:HideObjectsByType(self.eObjectTypeCommodity)
	elseif data == self.eObjectTypeEliteNeutral 
			or data == self.eObjectTypeEliteHostile
			or data == self.eObjectTypeUniqueFarming
			or data == self.eObjectTypeUniqueMining
			or data == self.eObjectTypeUniqueRelic
			or data == self.eObjectTypeUniqueSurvival
			or data == self.eObjectTypeLore
			or data == self.eObjectTypeQuestItem
			or data == self.eObjectTypeQuestCritter
			or data == self.eObjectTypePathResource then
		-- update all already shown units
	  	self:RefreshMap()
	else
		self.wndNexusMiniMap:HideObjectsByType(data)
	end
end

--------------------------------------------------------------------------------------------------
-- NexusMiniMapOptions Functions
---------------------------------------------------------------------------------------------------
function NexusMiniMap:openNexusMiniMapOptions( wndHandler, wndControl, x, y )
		if (self.wndFilterTownies:IsShown()) then
			self.wndFilterTownies:Show(false)
		end
		if (self.wndPvPVendors:IsShown()) then
			self.wndPvPVendors:Show(false)
		end
		self.wndMinimapOptions:RemoveStyle("CloseOnExternalClick")
		self.wndNexusMiniMapOptions:Show(true)
end

--------------------------------------------------------------------------------------------------
-- PvpVendors Functions
---------------------------------------------------------------------------------------------------
function NexusMiniMap:openPvPVendorsWindow( wndHandler, wndControl, x, y )
		if (self.wndFilterTownies:IsShown()) then
			self.wndFilterTownies:Show(false)
		end
		if(self.wndNexusMiniMapOptions:IsShown()) then
			self.wndNexusMiniMapOptions:Show(false)
		end
		self.wndMinimapOptions:RemoveStyle("CloseOnExternalClick")
		self.wndPvPVendors:Show(true)
end

--------------------------------------------------------------------------------------------------
-- FilterTownies Functions
---------------------------------------------------------------------------------------------------
function NexusMiniMap:openFilterTowniesWindow( wndHandler, wndControl, x, y )
	if (self.wndPvPVendors:IsShown()) then
		self.wndPvPVendors:Show(false)
	end
	if(self.wndNexusMiniMapOptions:IsShown()) then
		self.wndNexusMiniMapOptions:Show(false)
	end
	self.wndMinimapOptions:RemoveStyle("CloseOnExternalClick")
	self.wndFilterTownies:Show(true)
end

function NexusMiniMap:CloseFilter( wndHandler, wndControl )
	self.wndMinimapOptions:AddStyle("CloseOnExternalClick")
end

--------------------------------------------------------------------------------------------------
-- GMM Imports
--------------------------------------------------------------------------------------------------

function NexusMiniMap:OnSquareMapCheck( wndHandler, wndControl, eMouseButton )
	--self.wndMinimapOptions:Show(false)
	self.bSquareMap = true	
	--self.bHideCompass = true
	self:RebuildMapWindow()
end

function NexusMiniMap:OnSquareMapUncheck( wndHandler, wndControl, eMouseButton )
	--self.wndMinimapOptions:Show(false)

	self.bSquareMap = false
	--self.bHideCompass = false
	self:RebuildMapWindow()
end

function NexusMiniMap:OnHideCompassCheck( wndHandler, wndControl, eMouseButton )
	self.wndMinimapOptions:Show(false)

	self.bHideCompass 		= true
	
	self:RebuildMapWindow()
end

function NexusMiniMap:OnHideCompassUncheck( wndHandler, wndControl, eMouseButton )
	self.wndMinimapOptions:Show(false)
	
	self.bHideCompass 		= false
	
	self:RebuildMapWindow()
end

function NexusMiniMap:OnCustomQuestCheck( wndHandler, wndControl, eMouseButton )
	self.bCustomQuestArrow = true
	-- update all already shown units
  	self:RefreshMap()
end

function NexusMiniMap:OnCustomQuestUncheck( wndHandler, wndControl, eMouseButton )
	self.bCustomQuestArrow = false
	-- update all already shown units
  	self:RefreshMap()
end

function NexusMiniMap:OnShowCoordsCheck( wndHandler, wndControl, eMouseButton )
	self.bShowCoords = true
	self.wndMiniMapCoords:Show(true)
end

function NexusMiniMap:OnShowCoordsUncheck( wndHandler, wndControl, eMouseButton )
	self.bShowCoords = false
	self.wndMiniMapCoords:Show(false)
end

function NexusMiniMap:OnHideFrameCheck( wndHandler, wndControl, eMouseButton )

	if self.wndMain:FindChild("MapFrame") then
		self.wndMain:FindChild("MapFrame"):Show(false)
	end

	self.bHideFrame = true
end

function NexusMiniMap:OnHideFrameUncheck( wndHandler, wndControl, eMouseButton )
	if self.wndMain:FindChild("MapFrame") then
		self.wndMain:FindChild("MapFrame"):Show(true)
	end

	self.bHideFrame = false
end

function NexusMiniMap:RebuildMapWindow()
	self.wndMain:Destroy()

	if self.bSquareMap and self.bSquareMap == true then	
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "SquareMinimap", "FixedHudStratum", self)
	else
		self.wndMain 			= Apollo.LoadForm(self.xmlDoc , "Minimap", "FixedHudStratum", self)
	end
	
	if self.nMapOpacity then
		self.wndMain:SetOpacity(self.nMapOpacity)
	else
		self.nMapOpacity = 1.0
	end

	self.wndNexusMiniMap 		= self.wndMain:FindChild("MapContent")
	self.wndZoneName 		= self.wndMain:FindChild("MapZoneName")
	self.wndPvPFlagName 	= self.wndMain:FindChild("MapZonePvPFlag")
	self.wndRangeLabel 		= self.wndMain:FindChild("RangeToTargetLabel")
	self:UpdateZoneName(GetCurrentZoneName())
	self.wndMinimapButtons 	= self.wndMain:FindChild("ButtonContainer")
	
	if self.fSavedZoomLevel then
		self.wndNexusMiniMap:SetZoomLevel( self.fSavedZoomLevel)
	end
	
	self:OnWindowManagementReady()

	if self.bRotateMap and self.bRotateMap == true then
		self.wndMinimapOptions:FindChild("OptionsBtnRotate"):SetCheck(true)
		self.wndNexusMiniMap:SetMapOrientation(2)
	end 
	
	if not self.bHideFrame or self.bHideFrame == false then

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(true)
		end

		self.bHideFrame = false
	else

		if self.wndMain:FindChild("MapFrame") then
			self.wndMain:FindChild("MapFrame"):Show(false)
		end
	end

	g_wndTheMiniMap = self.wndNexusMiniMap

	self.wndMain:FindChild("MapMenuButton"):AttachWindow(self.wndMinimapOptions)
	self.wndMain:SetSizingMinimum(150, 150)
	self.wndMain:SetSizingMaximum(400, 400)
  	self:RefreshMap()
end

function NexusMiniMap:OnCustomPlayer_Check( wndHandler, wndControl, eMouseButton )
	Apollo.LoadSprites("GMM_CustomPlayerArrow.xml")

	self.bCustomPlayerArrow = true

	self:RebuildMapWindow()
end

function NexusMiniMap:OnCustomPlayer_Uncheck( wndHandler, wndControl, eMouseButton )
	Apollo.LoadSprites("GMM_DefaultPlayerArrow.xml")

	self.bCustomPlayerArrow = false

	self:RebuildMapWindow()
end

-----------------------------------------------------------------------------------------------
-- Utility / Helper functions
-- Pulled from NavMate
-----------------------------------------------------------------------------------------------

local function GetAddon(strAddonName)
	local info = Apollo.GetAddonInfo(strAddonName)

	if info and info.bRunning == 1 then 
		return Apollo.GetAddon(strAddonName)
	end
end

--------------------------------------------------------------------------------------------------
-- NexusMiniMap instance
---------------------------------------------------------------------------------------------------
local NexusMiniMapInst = NexusMiniMap:new()
NexusMiniMapInst:Init()
