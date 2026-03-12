---@class UIMenu : UIElement

UIMenu = {}
UIMenu.__index = UIMenu
UIMenu.__type = "UIMenu"

---@return UIMenu
function UIMenu.new()
    local self = setmetatable(UIElement.new(), setmetatable(UIMenu, UIElement)) --[[@as UIMenu]]

    return self
end

---@param self UIMenu
function UIMenu.update(self, deltaTime)
    local itemX = 0
    local itemY = 0

    for i, child in ipairs(self.children) do
        child.width = self.width

        child.x = itemX
        child.y = itemY

        itemY = itemY + child.height
    end

    UIElement.update(self, deltaTime)
end
