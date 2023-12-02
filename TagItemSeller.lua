local frame = CreateFrame("Frame", "SellTaggerFrame", UIParent)
frame:RegisterEvent("MERCHANT_SHOW")

-- Function to add a gold coin icon to the tooltip
local function AddGoldCoinToTooltip(tooltip, hyperlink)
    if SellTaggerFrame[hyperlink] then
        local texture = "Interface\\MoneyFrame\\UI-GoldIcon" -- Path to the gold coin icon texture
        tooltip:AddLine("Tagged to sell")
        tooltip:AddTexture(texture)
    end
end

-- Hook into the tooltip's OnTooltipSetItem script handler
GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
    local name, hyperlink = tooltip:GetItem()
    if name and hyperlink then
        AddGoldCoinToTooltip(tooltip, hyperlink)
    end
end)

local function SellTaggedItems()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.hyperlink and SellTaggerFrame[containerInfo.hyperlink] then
                C_Container.UseContainerItem(bag, slot)
                SellTaggerFrame[containerInfo.hyperlink] = nil                
            end
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        SellTaggedItems()
    end
end)

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
    if IsControlKeyDown() and button == "RightButton" then
        local bag = self:GetParent():GetID()
        local slot = self:GetID()
        local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
        if containerInfo and containerInfo.hyperlink then
            if not SellTaggerFrame[containerInfo.hyperlink] then
                SellTaggerFrame[containerInfo.hyperlink] = true
                print("Item tagged to be sold: " .. containerInfo.hyperlink)
            else
                SellTaggerFrame[containerInfo.hyperlink] = nil
                print("Item untagged: " .. containerInfo.hyperlink)
            end
        end
    end
end)