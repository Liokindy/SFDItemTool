---@class UIElement : Instance
---@field parent UIElement?
---@field children UIElement[]
---@field x number
---@field y number
---@field width number
---@field height number
---@field background boolean
---@field border boolean
---@field focusable boolean
---@field draggable boolean
---@field addChild fun(self: UIElement, ...: UIElement)
---@field removeChild fun(self: UIElement, ...: UIElement)
---@field getDrawX fun(self: UIElement): number
---@field getDrawY fun(self: UIElement): number
---@field getOverlap fun(self: UIElement, x: number, y: number, focusable: boolean): UIElement?
---@field textinput fun(self: UIElement, text: string)
---@field keypressed fun(self: UIElement, key: love.KeyConstant)
---@field keyreleased fun(self: UIElement, key: love.KeyConstant)
---@field mousepressed fun(self: UIElement, x: number, y: number, button: number)
---@field mousereleased fun(self: UIElement, x: number, y: number, button: number)
---@field mousemoved fun(self: UIElement, x: number, y: number, dx: number, dy: number)
---@field wheelmoved fun(self: UIElement, x: number, y: number)
---@field update fun(self: UIElement, deltaTime: number)
---@field draw fun(self: UIElement)
---@field drawChildren fun(self: UIElement)
---@field drawBackground fun(self: UIElement)
---@field drawBorder fun(self: UIElement)
---@field inside fun(self: UIElement, x: number, y: number): boolean
---@field pushScissor fun(self: UIElement): number, number, number, number

UIElement = {}
UIElement.__type = "UIElement"
UIElement.__index = UIElement

---@return UIElement
function UIElement.new()
    local self = Instance.new(UIElement) --[[@as UIElement]]

    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.children = {}
    self.focusable = true
    self.draggable = false
    self.border = true
    self.background = true
    return self
end

---@param self UIElement
---@param ... UIElement
function UIElement.addChild(self, ...)
    local children = {...}

    for i, child in ipairs(children) do
        table.insert(self.children, child)
        child.parent = self
    end
end

---@param self UIElement
---@param ... UIElement
function UIElement.removeChild(self, ...)
    local children = {...}

    for i, existingChild in ipairs(self.children) do
        for j, removingChild in ipairs(children) do
            if (existingChild == removingChild) then
                existingChild.parent = nil
                self.children[i] = nil
            end
        end
    end
end

---@param self UIElement
---@param x number
---@param y number
---@param focusable boolean
---@return UIElement?
function UIElement.getOverlap(self, x, y, focusable)
    for i=#self.children, 1, -1 do
        local child = self.children[i]

        if (((focusable and child.focusable) or not focusable) and child:inside(x, y)) then
            return child:getOverlap(x, y, focusable)
        end
    end

    if (((focusable and self.focusable) or not focusable) and self:inside(x, y)) then
        return self
    end

    return nil
end

---@param self UIElement
---@param x number
---@param y number
function UIElement.inside(self, x, y)
    return (self:getDrawX() < x and self:getDrawX() + self.width > x and self:getDrawY() < y and self:getDrawY() + self.height > y)
end

---@param self UIElement
---@return number
function UIElement.getDrawX(self)
    if (self.parent) then
        return self.parent:getDrawX() + self.x
    end

    return self.x
end

---@param self UIElement
---@return number
function UIElement.getDrawY(self)
    if (self.parent) then
        return self.parent:getDrawY() + self.y
    end

    return self.y
end

---@param self UIElement
---@param key love.KeyConstant
function UIElement.keypressed(self, key)
    for i, child in ipairs(self.children) do
        child:keypressed(key)
    end
end

---@param self UIElement
---@param key love.KeyConstant
function UIElement.keyreleased(self, key)
    for i, child in ipairs(self.children) do
        child:keyreleased(key)
    end
end

---@param self UIElement
---@param text string
function UIElement.textinput(self, text)
    for i, child in ipairs(self.children) do
        child:textinput(text)
    end
end

---@param self UIElement
---@param x number
---@param y number
---@param button number
function UIElement.mousepressed(self, x, y, button)
    for i, child in ipairs(self.children) do
        child:mousepressed(x, y, button)
    end
end

---@param self UIElement
---@param x number
---@param y number
---@param button number
function UIElement.mousereleased(self, x, y, button)
    for i, child in ipairs(self.children) do
        child:mousereleased(x, y, button)
    end
end

---@param self UIElement
---@param x number
---@param y number
---@param dx number
---@param dy number
function UIElement.mousemoved(self, x, y, dx, dy)
    for i, child in ipairs(self.children) do
        child:mousemoved(x, y, dx, dy)
    end
end

---@param self UIElement
---@param x number
---@param y number
function UIElement.wheelmoved(self, x, y)
    for i, child in ipairs(self.children) do
        child:wheelmoved(x, y)
    end
end

---@param self UIElement
---@param deltaTime number
function UIElement.update(self, deltaTime)
    for i, child in ipairs(self.children) do
        child:update(deltaTime)
    end
end

---@param self UIElement
---@return number, number, number, number
function UIElement.pushScissor(self)
    local scissorX, scissorY, scissorWidth, scissorHeight = love.graphics.getScissor()

    if (scissorWidth) then scissorWidth = math.max(scissorWidth, 0) end
    if (scissorHeight) then scissorHeight = math.max(scissorHeight, 0) end

    love.graphics.intersectScissor(self:getDrawX(), self:getDrawY(), math.max(self.width, 0), math.max(self.height, 0))
    return scissorX, scissorY, scissorWidth, scissorHeight
end

---@param self UIElement
function UIElement.draw(self)
    local scissorX, scissorY, scissorWidth, scissorHeight = self:pushScissor()

    self:drawBackground()
    self:drawBorder()
    self:drawChildren()

    love.graphics.setScissor(scissorX, scissorY, scissorWidth, scissorHeight)
end

---@param self UIElement
function UIElement.drawBackground(self)
    if (not self.background) then
        return
    end

    love.graphics.setColor(App.theme.main)
    love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)
end

---@param self UIElement
function UIElement.drawBorder(self)
    if (not self.border) then
        return
    end

    local lineWidth = love.graphics.getLineWidth()
    local lineOffset = lineWidth * 0.5

    love.graphics.setColor(App.theme.highlight)
    love.graphics.rectangle("line", self:getDrawX() + lineOffset, self:getDrawY() + lineOffset, self.width - lineOffset * 2, self.height - lineOffset * 2)
end

---@param self UIElement
function UIElement.drawChildren(self)
    for i, child in ipairs(self.children) do
        child:draw()
    end
end

