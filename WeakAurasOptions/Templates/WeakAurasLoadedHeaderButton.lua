if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local L = WeakAuras.L

local function Hide_Tooltip()
  GameTooltip:Hide()
end

local function Show_Tooltip(owner, line1, line2)
  GameTooltip:SetOwner(owner, "ANCHOR_NONE")
  GameTooltip:SetPoint("LEFT", owner, "RIGHT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine(line1)
  GameTooltip:AddLine(line2, 1, 1, 1, 1)
  GameTooltip:Show()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self:SetWidth(1000)
    self:SetHeight(20)
  end,
  ["SetClick"] = function(self, func)
    self:SetScript("OnClick", func)
  end,
  ["Pick"] = function(self)
    self:LockHighlight()
  end,
  ["ClearPick"] = function(self)
    self:UnlockHighlight()
  end,
  ["Expand"] = function(self, reloadTooltip)
    self.expand:Enable()
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-MinusButton-Up.blp")
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-MinusButton-Down.blp")
    self.expand.title = L["Collapse"]
    self.expand.desc = self.expand.collapsedesc
    self.expand:SetScript("OnClick", function() self:Collapse(true) end)
    self.expand.func(self)
    if(reloadTooltip) then
      Hide_Tooltip()
      Show_Tooltip(self, self.expand.title, self.expand.desc)
    end
    self.node:SetCollapsed(false)
  end,
  ["Collapse"] = function(self, reloadTooltip)
    self.expand:Enable()
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Up.blp")
    self.expand:SetPushedTexture("Interface\\BUTTONS\\UI-PlusButton-Down.blp")
    self.expand.title = L["Expand"]
    self.expand.desc = self.expand.expanddesc
    self.expand:SetScript("OnClick", function() self:Expand(true) end)
    self.expand.func(self)
    if(reloadTooltip) then
      Hide_Tooltip()
      Show_Tooltip(self, self.expand.title, self.expand.desc)
    end
    self.node:SetCollapsed(true)
  end,
  ["GetExpanded"] = function(self)
    return not self.node:IsCollapsed()
  end,
  ["DisableExpand"] = function(self)
    self.expand:Disable()
    self.expand.disabled = true
    self.expand:SetNormalTexture("Interface\\BUTTONS\\UI-PlusButton-Disabled.blp")
  end,
  ["EnableExpand"] = function(self)
    self.expand.disabled = false
    if(self:GetExpanded()) then
      self:Expand()
    else
      self:Collapse()
    end
  end,
  ["PriorityShow"] = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.view.visibility and self.view.visibility ~= priority) then
      self.view.visibility = priority;
      self:UpdateViewTexture()
    end
  end,
  ["PriorityHide"] = function(self, priority)
    if (not WeakAuras.IsOptionsOpen()) then
      return;
    end
    if(priority >= self.view.visibility and self.view.visibility ~= 0) then
      self.view.visibility = 0
      self:UpdateViewTexture()
    end
  end,
  ["UpdateViewTexture"] = function(self)
    local visibility = self.view.visibility
    if(visibility == 2) then
      self.view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking0.blp")
    elseif(visibility == 1) then
      self.view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking2.blp")
    else
      self.view.texture:SetTexture("Interface\\LFGFrame\\BattlenetWorking4.blp")
    end
  end,
  ["SetViewDescription"] = function(self, desc)
    self.view.desc = desc;
  end,
  ["SetExpandDescription"] = function(self, desc)
    self.expand.expanddesc = desc;
  end,
  ["SetCollapseDescription"] = function(self, desc)
    self.expand.collapsedesc = desc;
    self.expand.desc = desc;
  end,
  ["RecheckVisibility"] = function(self)
    local none, all = true, true
    for _, child in ipairs(self.childButtons) do
      if child:GetVisibility() ~= 2 then
        all = false
      end
      if child:GetVisibility() ~= 0 then
        none = false
      end
    end
    local newVisibility
    if all then
      newVisibility = 2
    elseif none then
      newVisibility = 0
    else
      newVisibility = 1
    end
    if newVisibility ~= self.view.visibility then
      self.view.visibility = newVisibility
      self:UpdateViewTexture()
    end
  end,
  ["OnViewClick"] = function(self)
    local suspended = OptionsPrivate.Private.PauseAllDynamicGroups()
    if self.view.visibility == 2 then
      for _, child in ipairs(self.childButtons) do
        if child:IsLoaded() then
          child:PriorityHide(2)
        end
      end
      self:PriorityHide(2)
    else
      for _, child in ipairs(self.childButtons) do
        if child:IsLoaded() then
          child:PriorityShow(2)
        end
      end
      self:PriorityShow(2)
    end
    OptionsPrivate.Private.ResumeAllDynamicGroups(suspended)
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]

WeakAurasLoadedHeaderButtonMixin = {}

function WeakAurasLoadedHeaderButtonMixin:Init(node)
  self.node = node
  local nodeData = node:GetData()
  self:SetText(" " .. nodeData.text)
  self.expand.disabled = true
  self.expand.func = nodeData.OnExpandCollapse
  self.expand:Disable()
  self.expand.title = L["Disabled"]
  self.expand.desc = L["Expansion is disabled because this group has no children"]
  self.expand.expanddesc = nodeData.expandDescription
  self.expand.collapsedesc = nodeData.collapseDescription
  self.expand:SetScript("OnEnter", function() Show_Tooltip(self, self.expand.title, self.expand.desc) end)
  self.expand:SetScript("OnLeave", Hide_Tooltip)
  self.view.desc = nodeData.viewDescription
  self.view:SetScript("OnEnter", function() Show_Tooltip(self, L["View"], self.view.desc) end)
  self.view:SetScript("OnLeave", Hide_Tooltip)
  self.view:SetScript("OnClick", self.OnViewClick)
  self.view.visibility = 0
  for method, func in pairs(methods) do
    self[method] = func
  end

  self:Disable()
  self:EnableExpand()

  self.childButtons = {} -- dummy for now
end