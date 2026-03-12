---@class UILabel : UIElement
---@field text string
---@field textPlaceholder string
---@field textFont love.Font
---@field textColor Color
---@field textEditable boolean
---@field textFocused boolean
---@field textDoubleClickTime number
---@field textSelectionTime integer
---@field textSelectionStart integer
---@field textSelectionEnd integer
---@field textAlignment love.AlignMode
---@field textHorizontalPadding number
---@field textHorizontalScroll number
---@field setTextSelectionEnd fun(self: UILabel, value: integer)
---@field setTextSelectionStart fun(self: UILabel, value: integer)
---@field getTextSelectionLength fun(self: UILabel): integer
---@field getTextOffsetAt fun(self: UILabel, x: number): integer
---@field getTextBeforeSelection fun(self: UILabel): string
---@field getTextInSelection fun(self: UILabel): string
---@field getTextAfterSelection fun(self: UILabel): string
---@field getTextCursorX fun(self: UILabel): number
---@field drawText fun(self: UILabel)

UILabel = {}
UILabel.__type = "UILabel"
UILabel.__index = UILabel

---@return UILabel
function UILabel.new()
    local self = setmetatable(UIElement.new(), setmetatable(UILabel, UIElement)) --[[@as UILabel]]

    self.draggable = true

    self.text = ""
    self.textPlaceholder = ""
    self.textEditable = false
    self.textFocused = false
    self.textSelectionTime = 0
    self.textSelectionStart = 1
    self.textSelectionEnd = 1
    self.textDoubleClickTime = 0
    self.textFont = App.font.regular
    self.textColor = App.theme.textMain
    self.textAlignment = "left"
    self.textHorizontalPadding = 0
    self.textHorizontalScroll = 0

    return self
end

---@param self UILabel
---@param value integer
function UILabel.setTextSelectionEnd(self, value)
    self.textSelectionEnd = math.max(math.min(value, UTF8.len(self.text) + 1), 1)
    self.textSelectionTime = 0
end

---@param self UILabel
---@param value integer
function UILabel.setTextSelectionStart(self, value)
    self.textSelectionStart = math.max(math.min(value, UTF8.len(self.text) + 1), 1)
    self.textSelectionTime = 0
end

---@param self UILabel
---@return integer
function UILabel.getTextSelectionLength(self)
    return math.abs(self.textSelectionEnd - self.textSelectionStart)
end

---@param self UILabel
---@param x number
---@return number
function UILabel.getTextOffsetAt(self, x)
    local font = self.textFont
    local textWidth = font:getWidth(self.text)
    local textLength = UTF8.len(self.text)

    if (x <= self:getDrawX() + self.textHorizontalPadding - self.textHorizontalScroll) then
        return 0
    end

    if (x >= self:getDrawX() + self.textHorizontalPadding - self.textHorizontalScroll + textWidth) then
        return textLength + 1
    end

    local i = 0
    local width = 0

    for p, c in UTF8.codes(self.text) do
        local char = UTF8.char(c)
        local charWidth = font:getWidth(char)

        if (x < self:getDrawX() + self.textHorizontalPadding - self.textHorizontalScroll + width) then
            break
        end

        width = width + charWidth
        i = i + 1
    end

    return i
end

---@param self UILabel
---@return number
function UILabel.getTextCursorX(self)
    local textBeforeSelectionEnd = ""
    if (self.textSelectionEnd > 1) then
        local offset = UTF8.offset(self.text, self.textSelectionEnd)
        if (offset) then
            textBeforeSelectionEnd = string.sub(self.text, 1, offset - 1)
        end
    end

    return self.textFont:getWidth(textBeforeSelectionEnd)
end

---@param self UILabel
---@return string
function UILabel.getTextBeforeSelection(self)
    local index = math.min(self.textSelectionEnd, self.textSelectionStart)

    if (index > 1) then
        local offset = UTF8.offset(self.text, index)
        if (offset) then
            return string.sub(self.text, 1, offset - 1)
        end
    end

    return ""
end

---@param self UILabel
---@return string
function UILabel.getTextInSelection(self)
    local startIndex = math.min(self.textSelectionStart, self.textSelectionEnd)
    local endIndex = math.max(self.textSelectionStart, self.textSelectionEnd)

    if (startIndex < endIndex) then
        local startByte = UTF8.offset(self.text, startIndex)
        local nextByte = UTF8.offset(self.text, endIndex)
        if (startByte and nextByte) then
            return string.sub(self.text, startByte, nextByte - 1)
        end
    end

    return ""
end

---@param self UILabel
---@return string
function UILabel.getTextAfterSelection(self)
    local index = math.max(self.textSelectionEnd, self.textSelectionStart)

    local offset = UTF8.offset(self.text, index)
    if (offset) then
        return string.sub(self.text, offset)
    end

    return ""
end

---@param self UILabel
---@param deltaTime number
function UILabel.update(self, deltaTime)
    if (self.textEditable) then
        if (self:inside(love.mouse.getPosition())) then
            App.cursor = love.mouse.getSystemCursor("ibeam")
        end

        self.textSelectionTime = self.textSelectionTime + deltaTime
        if (self.textSelectionTime > 1) then
            self.textSelectionTime = 0
        end

        if (self.textDoubleClickTime > 0) then
            self.textDoubleClickTime = math.max(0, self.textDoubleClickTime - deltaTime)
        end
    end

    UIElement.update(self, deltaTime)
end

---@param self UILabel
---@param x number
---@param y number
---@param dx number
---@param dy number
function UILabel.mousemoved(self, x, y, dx, dy)
    if (self.textEditable and self.textFocused) then
        if (love.mouse.isDown(1)) then
            self:setTextSelectionEnd(self:getTextOffsetAt(love.mouse.getX()))
        end
    end

    UIElement.mousemoved(self, x, y, dx, dy)
end

---@param self UILabel
---@param text string
function UILabel.textinput(self, text)
    if (self.textEditable and self.textFocused) then
        self.text = self:getTextBeforeSelection() .. text .. self:getTextAfterSelection()

        self:setTextSelectionEnd(math.min(self.textSelectionStart, self.textSelectionEnd) + 1)
        self:setTextSelectionStart(self.textSelectionEnd)
    end

    UIElement.textinput(self, text)
end

---@param self UILabel
---@param key love.KeyConstant
function UILabel.keypressed(self, key)
    if (self.textEditable and self.textFocused) then
        if (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
            if (key == "c") then
                love.system.setClipboardText(self:getTextInSelection())
            elseif (key == "v") then
                local clipboardText = string.gsub(love.system.getClipboardText(), "%c", "")

                self.text = self:getTextBeforeSelection() .. clipboardText .. self:getTextAfterSelection()
                
                self:setTextSelectionEnd(string.len(self:getTextBeforeSelection() .. clipboardText) + 1)
                self:setTextSelectionStart(self.textSelectionEnd)
            elseif (key == "x") then
                love.system.setClipboardText(self:getTextInSelection())

                self.text = self:getTextBeforeSelection() .. self:getTextAfterSelection()

                self:setTextSelectionEnd(math.min(self.textSelectionStart, self.textSelectionEnd))
                self:setTextSelectionStart(self.textSelectionEnd)
            end
        end
        
        if (key == "home") then
            self:setTextSelectionEnd(1)
            self:setTextSelectionStart(self.textSelectionEnd)
        elseif (key == "end") then
            self:setTextSelectionEnd(UTF8.len(self.text) + 1)
            self:setTextSelectionStart(self.textSelectionEnd)
        elseif (key == "escape" or key == "return") then
            self.textFocused = false
        elseif (key == "backspace") then
            if (self:getTextSelectionLength() > 0) then
                self.text = self:getTextBeforeSelection() .. self:getTextAfterSelection()

                self:setTextSelectionEnd(math.min(self.textSelectionStart, self.textSelectionEnd))
                self:setTextSelectionStart(self.textSelectionEnd)
            else
                local textBeforeSelection = self:getTextBeforeSelection()
                local offset = UTF8.offset(textBeforeSelection, -1)

                if (offset) then
                    self.text = string.sub(textBeforeSelection, 1, offset - 1) .. self:getTextAfterSelection()
                    self:setTextSelectionEnd(math.min(self.textSelectionStart, self.textSelectionEnd) - 1)
                    self:setTextSelectionStart(self.textSelectionEnd)
                end
            end
        elseif (key == "left" or key == "right") then
            if (love.keyboard.isDown("lshift")) then
                self:setTextSelectionEnd(self.textSelectionEnd + (key == "left" and -1 or 1))
            else
                if (self:getTextSelectionLength() > 0) then
                    if (key == "left") then
                        self:setTextSelectionEnd(math.min(self.textSelectionStart, self.textSelectionEnd))
                        self:setTextSelectionStart(self.textSelectionEnd)
                    else
                        self:setTextSelectionStart(math.max(self.textSelectionStart, self.textSelectionEnd))
                        self:setTextSelectionEnd(self.textSelectionStart)
                    end
                else
                    self:setTextSelectionEnd(self.textSelectionEnd + (key == "left" and -1 or 1))
                    self:setTextSelectionStart(self.textSelectionEnd)
                end
            end
        end
    end

    UIElement.keypressed(self, key)
end

---@param self UILabel
---@param x number
---@param y number
---@param button number
function UILabel.mousepressed(self, x, y, button)
    if (self.textEditable) then
        if (self:inside(x, y)) then
            if (button == 1) then
                if (self.textDoubleClickTime > 0) then
                    self:setTextSelectionEnd(UTF8.len(self.text) + 1)
                    self:setTextSelectionStart(1)
                else
                    self.textDoubleClickTime = 0.5

                    self:setTextSelectionEnd(self:getTextOffsetAt(x))
                    self:setTextSelectionStart(self.textSelectionEnd)
                end

                self.textFocused = true
            end
        else
            self.textFocused = false
        end
    end

    UIElement.mousepressed(self, x, y, button)
end

---@param self UILabel
function UILabel.draw(self)
    local scissorX, scissorY, scissorWidth, scissorHeight = self:pushScissor()

    self:drawBackground()
    self:drawBorder()
    self:drawText()
    self:drawChildren()

    love.graphics.setScissor(scissorX, scissorY, scissorWidth, scissorHeight)
end

---@param self UILabel
function UILabel.drawText(self)
    local font = self.textFont
    local textWidth = font:getWidth(self.text)
    local textHeight = font:getHeight()
    local textX
    local textY = self:getDrawY() + self.height * 0.5 - textHeight * 0.5
    local textMaximumX = self.width - self.textHorizontalPadding * 2
    local textCursorX = self:getTextCursorX()

    if (self.textAlignment == "left") then
        textX = self:getDrawX() + self.textHorizontalPadding
    elseif (self.textAlignment == "center") then
        textX = self:getDrawX() + self.width * 0.5 - textWidth * 0.5
    elseif (self.textAlignment == "right") then
        textX = self:getDrawX() - self.textHorizontalPadding - textWidth
    end

    if (self.textFocused and textCursorX > textMaximumX) then
        self.textHorizontalScroll = textCursorX - textMaximumX
    else
        self.textHorizontalScroll = 0
    end

    textX = textX - self.textHorizontalScroll

    love.graphics.setFont(font)

    if (string.len(self.text) == 0) then
        love.graphics.setColor(App.theme.mute)
        love.graphics.print(self.textPlaceholder, textX, textY)
    else
        love.graphics.setColor(self.textColor)
        love.graphics.print(self.text, textX, textY)
    end

    if (self.textFocused) then
        if (self:getTextSelectionLength() > 0) then
            local textBeforeSelection = self:getTextBeforeSelection()
            local textInSelection = self:getTextInSelection()

            local selectionX = font:getWidth(textBeforeSelection)
            local selectionWidth = font:getWidth(textInSelection)

            love.graphics.setColor(App.theme.accent)
            love.graphics.rectangle("fill", textX + selectionX, textY, selectionWidth, textHeight)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(textInSelection, textX + selectionX, textY)
        end

        if (self.textSelectionTime < 0.5) then
            love.graphics.setColor(self.textColor)
            love.graphics.rectangle("fill", textX + textCursorX, textY, 2, textHeight)
        end
    end
end
