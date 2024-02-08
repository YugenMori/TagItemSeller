local frame = CreateFrame("Frame", "SellTaggerFrame", UIParent)
local wowTocVersion = select(4, GetBuildInfo())

_G.SellTaggerFrame = _G.SellTaggerFrame or {}

-- Função para adicionar um ícone de moeda de ouro ao tooltip
local function AddGoldCoinToTooltip(tooltip, hyperlink)
    if SellTaggerFrame[hyperlink] then
        local texture = "Interface\\MoneyFrame\\UI-GoldIcon" 
        tooltip:AddLine("Tagged to Sell")
        tooltip:AddTexture(texture)
    end
end

local function DragonflightAddGoldCoinToTooltip(tooltip)
    local itemName, itemLink = tooltip:GetItem()
    if itemName and SellTaggerFrame[itemLink] then
        local texture = "Interface\\MoneyFrame\\UI-GoldIcon"
        tooltip:AddLine("Tagged to sell")
        tooltip:AddTexture(texture)
    end
end

-- Hook para o tooltip com base na versão do jogo
if wowTocVersion < 100000 then
    -- Para versões anteriores ao Dragonflight
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local name, hyperlink = tooltip:GetItem()
        if name and hyperlink then
            AddGoldCoinToTooltip(tooltip, hyperlink)
        end
    end)
else
    -- Para Dragonflight e versões posteriores
    TooltipDataProcessor.AddTooltipPostCall("ALL", function(tooltip, tooltipData)
        DragonflightAddGoldCoinToTooltip(tooltip)
    end)
end

-- Function to update tooltips of tagged items
local function UpdateTaggedItemTooltips()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.hyperlink and SellTaggerFrame[containerInfo.hyperlink] then
                -- Add tooltip text and coin icon to the item
                AddGoldCoinToTooltip(GameTooltip, containerInfo.hyperlink)
            end
        end
    end
end

-- Função para vender itens marcados
local function SellTaggedItems()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.hyperlink and SellTaggerFrame[containerInfo.hyperlink] then
                C_Container.UseContainerItem(bag, slot)
                --SellTaggerFrame[containerInfo.hyperlink] = nil     (remove the tag of item id after selling)           
            end
        end
    end
end

-- Hook para os botões dos itens com base na versão do jogo
if wowTocVersion < 100000 then
    -- Para versões anteriores ao Dragonflight
    hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
        if IsControlKeyDown() and button == "RightButton" then
            local bag = self:GetParent():GetID()
            local slot = self:GetID()
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.hyperlink then
                if not SellTaggerFrame[containerInfo.hyperlink] then
                    SellTaggerFrame[containerInfo.hyperlink] = true
                    print("Item tagged to sell: " .. containerInfo.hyperlink)
                else
                    SellTaggerFrame[containerInfo.hyperlink] = nil
                    print("Item untagged: " .. containerInfo.hyperlink)
                end
            end
        end
    end)      
end

if wowTocVersion > 100000 then
    -- Para Dragonflight e versões posteriores
    if ContainerFrameItemButtonMixin and ContainerFrameItemButtonMixin.OnModifiedClick then
        hooksecurefunc(ContainerFrameItemButtonMixin, "OnModifiedClick", function(self, button)
            if IsControlKeyDown() and button == "RightButton" then
                local bag = self:GetParent():GetID()
                local slot = self:GetID()
                local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
                if containerInfo and containerInfo.hyperlink then
                    if not SellTaggerFrame[containerInfo.hyperlink] then
                        SellTaggerFrame[containerInfo.hyperlink] = true
                        print("Item tagged to sell: " .. containerInfo.hyperlink)
                    else
                        SellTaggerFrame[containerInfo.hyperlink] = nil
                        print("Item untagged: " .. containerInfo.hyperlink)
                    end
                end
            end
        end)
    else
        print("ContainerFrameItemButtonMixin is not loaded or does not contain an OnModifiedClick method.")
    end
end

-- Variables to store the total money before and after selling items
local totalMoneyBefore = 0
local totalMoneyAfter = 0
local moneyPrinted = false

local function GetTaggedMoney()
    -- Wait for 1 second before getting the total money after selling items
    if not moneyPrinted then
        totalMoneyAfter = GetMoney()

        -- Calculate the money earned from selling items
        local moneyEarned = totalMoneyAfter - totalMoneyBefore

        -- Convert the money earned to gold, silver, and copper
        local gold = math.floor(moneyEarned / (100 * 100))
        local silver = math.floor((moneyEarned - (gold * 100 * 100)) / 100)
        local copper = math.floor(moneyEarned % 100)

        -- Prepare the message to be printed in the chat
        if moneyEarned > 0 then
            local message = "Money earned: "        
            if gold > 0 then
                message = message .. "|cffffd700" .. gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12|t|r "
            end
            if silver > 0 then
                message = message .. "|cffc7c7cf" .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12|t|r "
            end
            if copper > 0 then
                message = message .. "|cffeda55f" .. copper .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12|t|r"
            end
    
            -- Print the message in the chat
            DEFAULT_CHAT_FRAME:AddMessage(message)
            moneyPrinted = true
        end
    end
end

-- Evento para quando o jogador subir de nível
local function OnPlayerLevelUp()
    UpdateTaggedItemTooltips() -- Chama a função para atualizar os tooltips dos itens marcados
end

-- Registrar o evento LEVEL_UP e associá-lo à função OnPlayerLevelUp
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LEVEL_UP" then
        OnPlayerLevelUp() -- Chama a função quando o evento LEVEL_UP ocorrer
    end
end)

-- Register the frame UPDATE events
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")

-- Update the frame's script to handle the BAG_UPDATE event
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        SellTaggedItems()
        totalMoneyBefore = GetMoney()
        moneyPrinted = false
    elseif event == "MERCHANT_CLOSED" then
        GetTaggedMoney()
        UpdateTaggedItemTooltips()
    elseif event == "BAG_UPDATE" then
        UpdateTaggedItemTooltips()
    end
end)

-- Load Variables/Save
local addonName = "TagItemSeller"

local function OnAddonLoaded(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        _G.SellTaggerFrame = _G.SellTaggerFrame or {}
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)


--[[
-- Create a frame
local TagItemSeller = CreateFrame("Frame")

-- Store the item hyperlinks
local itemHyperlinks = {}

local function toggleCoinOnItem(itemButton)
    if not itemButton.coins then
        local texture = itemButton:CreateTexture(nil, "OVERLAY")
        texture:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
        texture:SetPoint("BOTTOMRIGHT", itemButton, "BOTTOMRIGHT", -3, 3)
        itemButton.coins = texture
        itemButton.coins:Show() -- Always show the coin icon when it's created
    else
        -- Toggle the visibility of the coin
        itemButton.coins:SetShown(not itemButton.coins:IsShown())
    end
end

local function hideCoinTexture(itemButton)
    if itemButton.coins then
        itemButton.coins:Hide()
    end
end

local function parseItemString(itemString)
    if not itemString then
      return
    end
  
    local _, itemID, _, _, _, _, _, suffixID = strsplit(":", itemString)
    itemID = tonumber(itemID)
    suffixID = tonumber(suffixID)
  
    if not itemID then
      return
    end
  
    local uniqueItemID = itemID
    if suffixID and suffixID ~= 0 then
      uniqueItemID = itemID .. suffixID
    end
  
    return itemID, uniqueItemID
end

local function getIsItemSoulbound(bagNumber, slotNumber)
    local item = Item:CreateFromBagAndSlot(bagNumber, slotNumber)
    local location = item:GetItemLocation()
  
    return C_Item.DoesItemExist(location) and C_Item.IsBound(location)
end

local function getUniqueItemID(bagNumber, slotNumber)
    local itemString = C_Container.GetContainerItemLink(bagNumber, slotNumber)
    local itemID, uniqueItemID = parseItemString(itemString)
    local isSoulbound = getIsItemSoulbound(bagNumber, slotNumber)
  
    return itemID, uniqueItemID, isSoulbound, itemString
end

local function checkItem(bagNumber, slotNumber, itemButton)
    local itemID, uniqueItemID, isSoulbound, itemHyperlink = getUniqueItemID(bagNumber, slotNumber)
    if itemHyperlink then
        -- If the item already has a coin, remove it from the old position
        if itemHyperlinks[itemHyperlink] then
            hideCoinTexture(itemHyperlinks[itemHyperlink].itemButton)
        end
        -- Add the coin to the new position
        toggleCoinOnItem(itemButton)
        itemHyperlinks[itemHyperlink] = {bagNumber = bag, slotNumber = slotNumber, itemButton = itemButton}
    else
        -- If the item doesn't have a coin, but the itemButton has a coin, hide it
        if itemButton.coins and itemButton.coins:IsShown() then
            hideCoinTexture(itemButton)
        end
    end
end

-- Hook into the ContainerFrameItemButton_OnModifiedClick function
hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
    if button == "RightButton" then
        local bag = self:GetParent():GetID()
        local slot = self:GetID()
        local itemID, uniqueItemID, isSoulbound, itemHyperlink = getUniqueItemID(bag, slot)
        if itemHyperlink then
            if itemHyperlinks[itemHyperlink] then
                -- If the item already has a coin, remove it
                hideCoinTexture(itemHyperlinks[itemHyperlink].itemButton)
                itemHyperlinks[itemHyperlink] = nil
            else
                -- Otherwise, add the coin
                toggleCoinOnItem(self)
                itemHyperlinks[itemHyperlink] = {bagNumber = bag, slotNumber = slot, itemButton = self}
            end
        end
    end
end)

local function handleEvent(self, event, bag)
    if event == "ADDON_LOADED" and bag == "TagItemSeller" then
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:RegisterEvent("BAG_UPDATE_DELAYED")
    elseif event == "BAG_UPDATE_DELAYED" then
        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local itemButton = _G["ContainerFrame"..bag.."Item"..slot]
                if itemButton then
                    checkItem(bag, slot, itemButton)
                end
            end
        end
    elseif event == "MERCHANT_SHOW" then
        SellTaggedItems()
    end
end

-- Register the event handler
TagItemSeller:SetScript("OnEvent", handleEvent)
TagItemSeller:RegisterEvent("ADDON_LOADED")
TagItemSeller:RegisterEvent("PLAYER_ENTERING_WORLD")
TagItemSeller:RegisterEvent("MERCHANT_SHOW")
--]]