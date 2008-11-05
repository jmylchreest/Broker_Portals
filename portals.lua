if not LibStub then return end

local dewdrop 		= LibStub("Dewdrop-2.0", true)
local L 			= LibStub("AceLocale-3.0"):GetLocale("Broker_Portals", true)
local icon			= LibStub("LibDBIcon-1.0")

local defaultIcon 		= "Interface\\Icons\\INV_Misc_Rune_06"
local hearthstoneIcon 	= "Interface\\Icons\\INV_Misc_Rune_01"

obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("Broker_Portals", {
	type = "data source",
	text = "Broker_Portals",
	icon = defaultIcon,
})
local obj 		= obj
local methods 	= {}
local portals	= nil
local frame 	= CreateFrame("frame")

frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SKILL_LINES_CHANGED")


local function pairsByKeys(t)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a)
	
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

local function findSpell(spellname)
	for i = 1,180 do
		local s = GetSpellName(i, BOOKTYPE_SPELL)
		if s == spellname then
			return i
		end
	end
end

local function SetupSpells()
	local spells = {
		Alliance = {
			3561,  --TP:Stormwind
			3562,  --TP:Ironforge
			3565,  --TP:Darnassus
			32271, --TP:Exodar
			49359, --TP:Theramore
			33690, --TP:Shattrath
			10059, --P:Stormwind
			11416, --P:Ironforge
			11419, --P:Darnassus
			32266, --P:Exodar
			49360, --P:Theramore
			33691, --P:Shattrath
		},
		Horde = {
			3563,  --TP:Undercity
			3566,  --TP:Thunder Bluff
			3567,  --TP:Orgrimmar
			32272, --TP:Silvermoon
			49358, --TP:Stonard
			35715, --TP:Shattrath
			11418, --P:Undercity
			11420, --P:Thunder Bluff
			11417, --P:Orgrimmar
			32267, --P:Silvermoon
			49361, --P:Stonard
			35717, --P:Shattrath
		}
	}
	
	local _, class = UnitClass("player")
	if class == "MAGE" then
		portals = spells[UnitFactionGroup("player")]
	end

	spells = nil
end

local function UpdateSpells()
	if not portals then
		SetupSpells()
	end
	
	if portals then
		for _,unTransSpell in ipairs(portals) do
			
			local spell, _, spellIcon = GetSpellInfo(unTransSpell)
			local spellid = findSpell(spell)
			
			if spellid then	
				methods[spell] = {
					spellid 	= spellid,
					text 		= spell,
					spellIcon 	= spellIcon,
					secure 		= {
						type 		= 'spell',
						spell 		= spell,
					}
				}
			end
		end
	end
end

local function ShowHearthstone()
	local text, secure
	local bindLoc = GetBindLocation()
	if bindLoc then
		text 	= L["Inn: "]..bindLoc
		secure 	= {
			type 	= 'item',
			item 	= L["Hearthstone"],
		}
		return text, secure
	else
		return nil
	end
end

local function ToggleMinimap()
	local hide = not PortalsDB.minimap.hide
	PortalsDB.minimap.hide = hide
	if hide then
		icon:Hide("Broker_Portals")
	else
		icon:Show("Broker_Portals")
	end
end

local function UpdateIcon(icon)
	obj.icon = icon
end

local function UpdateMenu()
	dewdrop:AddLine(
		'text', 	"Broker_Portals",
		'isTitle', 	true
	)
	dewdrop:AddLine()

	for k,v in pairsByKeys(methods) do
		if v.secure then
			dewdrop:AddLine(
				'text', 			v.text,
				'secure', 			v.secure,
				'icon', 			v.spellIcon,
				'func', 			function() UpdateIcon(v.spellIcon) end,
				'closeWhenClicked', true
			)
		end
	end
	
	dewdrop:AddLine()
	local bindText, bindSecure = ShowHearthstone()
	if bindText then
		dewdrop:AddLine(
			'text', 			bindText,
			'secure', 			bindSecure,
			'icon', 			hearthstoneIcon,
			'func', 			function() UpdateIcon(hearthstoneIcon) end,
			'closeWhenClicked', true
		)
		dewdrop:AddLine()
	end
	
	dewdrop:AddLine(
		'text', 			L["Attach to minimap"],
		'checked', 			not PortalsDB.minimap.hide,
		'func', 			function() ToggleMinimap() end,
		'closeWhenClicked', true
	)
	
	dewdrop:AddLine(
		'text', 			CLOSE,
		'tooltipTitle', 	CLOSE,
		'tooltipText', 		CLOSE_DESC,
		'closeWhenClicked', true
	)
end

function frame:PLAYER_LOGIN()
	-- PortalsDB.minimap is there for smooth upgrade of SVs from old version
	if (not PortalsDB) or (PortalsDB.version ~= 1) then
		PortalsDB 				= {}
		PortalsDB.minimap 		= {}
		PortalsDB.minimap.hide 	= false
		PortalsDB.version 		= 1
	end
	if icon then
		icon:Register("Broker_Portals", obj, PortalsDB.minimap)
	end

	self:UnregisterEvent("PLAYER_LOGIN")
end

function frame:SKILL_LINES_CHANGED()
	UpdateSpells()
end

-- All credit for this func goes to Tekkub and his picoGuild!
local function GetTipAnchor(frame)
		local x,y = frame:GetCenter()
		if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
		local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
		local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
		return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

function obj.OnClick(self, button)
	if button == "RightButton" then
		dewdrop:Open(self, "children", function() UpdateMenu() end)
	end
end

function obj.OnLeave() 
	GameTooltip:Hide() 
end

function obj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("Broker Portals")
	GameTooltip:AddDoubleLine(L["Right-Click"], L["to see list of spells"], 0.9, 0.6, 0.2, 0.2, 1, 0.2)

	GameTooltip:Show()
end
