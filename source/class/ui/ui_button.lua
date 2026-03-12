---@class UIButton : UILabel
---@field hovered boolean
---@field pressed boolean
---@field locked boolean
---@field onPressed fun()?

UIButton = {}
UIButton.__type = "UIButton"
UIButton.__index = UIButton

---@return UIButton
function UIButton.new()
    local self = setmetatable(UILabel.new(), setmetatable(UIButton, UILabel)) --[[@as UIButton]]

    self.hovered = false
    self.pressed = false
    self.locked = false
    self.draggable = false

    return self
end

---@param self UIButton
---@param deltaTime number
function UIButton.update(self, deltaTime)
    if (self.locked) then
        self.hovered = false
        self.pressed = false
    else
        if (self:inside(love.mouse.getPosition())) then
            self.hovered = true
            self.pressed = love.mouse.isDown(1)
    
            App.cursor = love.mouse.getSystemCursor("hand")
        else
            self.hovered = false
            self.pressed = false
        end
    end

    UILabel.update(self, deltaTime)
end

---@param self UIButton
---@param x number
---@param y number
---@param button number
function UIButton.mousereleased(self, x, y, button)
    if (not self.locked) then
        if (self.pressed and button == 1) then
            if (self.onPressed) then
                self.onPressed()
            end
        end
    end

    UIElement.mousereleased(self, x, y, button)
end


---@param self UIButton
function UIButton.drawBackground(self)
    if (not self.background) then
        return
    end

    if (self.pressed) then
        love.graphics.setColor(App.theme.accent[1], App.theme.accent[2], App.theme.accent[3], 0.1)
        love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)
    elseif (self.hovered) then
        love.graphics.setColor(App.theme.highlight)
        love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)
    elseif (self.locked) then
        love.graphics.setColor(App.theme.mute)
        love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)
    else
        love.graphics.setColor(App.theme.main)
        love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)
    end
end

---@param self UIButton
function UIButton.drawBorder(self)
    if (not self.border) then
        return
    end

    local lineWidth = love.graphics.getLineWidth()
    local lineOffset = lineWidth * 0.5

    if (self.pressed or self.hovered) then
        love.graphics.setColor(App.theme.accent[1], App.theme.accent[2], App.theme.accent[3], 0.25)
        love.graphics.rectangle("line", self:getDrawX() + lineOffset, self:getDrawY() + lineOffset, self.width - lineOffset, self.height - lineOffset)
    else
        love.graphics.setColor(App.theme.highlight)
        love.graphics.rectangle("line", self:getDrawX() + lineOffset, self:getDrawY() + lineOffset, self.width - lineOffset * 2, self.height - lineOffset * 2)
    end
end
