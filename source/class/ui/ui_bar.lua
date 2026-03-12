---@class UIBar : UILabel
---@field barCurrent number
---@field barTotal number
---@field getFullness fun(self: UIBar): number

UIBar = {}
UIBar.__type = "UIBar"
UIBar.__index = UIBar

---@return UIBar
function UIBar.new()
    local self = setmetatable(UILabel.new(), setmetatable(UIBar, UILabel)) --[[@as UIBar]]

    self.barCurrent = 0
    self.barTotal = 1
    self.textAlignment = "center"

    return self
end

---@param self UIBar
---@return number
function UIBar.getFullness(self)
    if (self.barTotal == 0) then
        return 1
    end

    return self.barCurrent / self.barTotal
end

---@param self UIBar
function UIBar.drawBackground(self)
    if (not self.background) then
        return
    end

    love.graphics.setColor(App.theme.main)
    love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)

    local fullness = self:getFullness()

    if (fullness > 0) then
        love.graphics.setColor(App.theme.accent[1], App.theme.accent[2], App.theme.accent[3])
        love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width * fullness, self.height)
    end
end
