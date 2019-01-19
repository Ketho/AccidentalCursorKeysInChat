--[[
            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                    Version 2, December 2004

 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

 Everyone is permitted to copy and distribute verbatim or modified
 copies of this license document, and changing it is allowed as long
 as the name is changed.

            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

  0. You just DO WHAT THE FUCK YOU WANT TO.
]]

local MIN_LENGTH = 7

local QWERTY = "[wasd12345]"
local AZERTY = "[zqsd12345]"
local keys = GetLocale() == "frFR" and AZERTY or QWERTY

local TEMP_CHAR = 'w'
local isInCombat

-- source https://gist.github.com/Badgerati/3261142
local function levenshtein(str1, str2)
	local len1 = strlen(str1)
	local len2 = strlen(str2)
	local matrix = {}
	local cost = 0
	
	-- sanitize
	if len1 == 0 then
		return len2
	elseif len2 == 0 then
		return len1
	elseif str1 == str2 then
		return 0
	end
	
	-- init matrix
	for i = 0, len1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end
	
	-- levenshtein
	for i = 1, len1 do
		for j = 1, len2 do
			cost = (strbyte(str1, i) == strbyte(str2, j)) and 0 or 1
			matrix[i][j] = min( matrix[i-1][j]+1, matrix[i][j-1]+1, matrix[i-1][j-1]+cost )
		end
	end
	
	return matrix[len1][len2] -- return distance
end

local function ChatFrameFocus(self, userInput)
	local text = self:GetText()
	local str1_len = strlen(text)
	
	if userInput and str1_len >= MIN_LENGTH and isInCombat then
		local str1 = text:lower():gsub(keys, TEMP_CHAR)	-- case insensitive
		local str2 = strrep(TEMP_CHAR, str1_len) -- same length but with w's
		
		-- if at least half of the characters are [wasd12345]
		if levenshtein(str1, str2) < str1_len/2 then
			-- sadly the player wont automatically move after focus is cleared
			self:ClearFocus()
		end
	end
end

-- replace any wasd12345 keys to w's and compare against another string with w's
for i = 1, NUM_CHAT_WINDOWS do
	_G["ChatFrame"..i].editBox:HookScript("OnTextChanged", ChatFrameFocus)
end

local f = CreateFrame("Frame")

function f:OnEvent(event)
	-- update combat state
	isInCombat = (event == "PLAYER_REGEN_DISABLED")
end

f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:SetScript("OnEvent", f.OnEvent)
