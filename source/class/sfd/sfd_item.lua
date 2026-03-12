---@class SFDItem : Instance
---@field postProcessTextures fun(self: SFDItem)
---@field getPart fun(self: SFDItem, partType: number): SFDItemPart?
---@field getColorIndex fun(self: SFDItem, r: number, g: number, b: number, a: number): number?
---@field parts SFDItemPart[]
---@field fileName string
---@field gameName string
---@field equipmentLayer number
---@field itemID string
---@field jacketUnderBelt boolean
---@field canEquip boolean
---@field canScript boolean
---@field colorPalette string
---@field colors Color[]
---@field width number
---@field height number
---@field fromFolder boolean
---@field fromFolderImagesPath string
---@field fromFolderIniPath string

SFDItem = {}
SFDItem.__index = SFDItem
SFDItem.__type = "SFDItem"

SFDItem.EQUIPMENT_LAYER_COUNT = 10
SFDItem.PART_TEXTURE_RANGE = 50
SFDItem.LAYER_SKIN = 1
SFDItem.LAYER_CHEST_UNDER = 2
SFDItem.LAYER_LEGS = 3
SFDItem.LAYER_WAIST = 4
SFDItem.LAYER_FEET = 5
SFDItem.LAYER_CHEST_OVER = 6
SFDItem.LAYER_ACCESSORY = 7
SFDItem.LAYER_HANDS = 8
SFDItem.LAYER_HEAD = 9
SFDItem.LAYER_HURT_LEVEL = 10

---@return SFDItem
function SFDItem.new()
    local self = Instance.new(SFDItem) --[[@as SFDItem]]

    self.parts = {}
    self.fileName = ""
    self.gameName = ""
    self.equipmentLayer = 0
    self.itemID = ""
    self.jacketUnderBelt = false
    self.canEquip = false
    self.canScript = false
    self.colorPalette = ""
    self.fromFolder = false
    self.fromFolderImagesPath = ""
    self.fromFolderIniPath = ""

    return self
end

---@param self SFDItem
function SFDItem.postProcessTextures(self)
    ---@param r number
    ---@param g number
    ---@param b number
    ---@param a number
    ---@return integer
    local function packColor(r, g, b, a)
        return Bit.bor(Bit.lshift(r * 255, 24), Bit.lshift(g * 255, 16), Bit.lshift(b * 255, 8), a * 255)
    end

    self.colors = {}
    self.width = nil
    self.height = nil

    local packedColors = {}

    for _, part in ipairs(self.parts) do
        for _, texture in pairs(part.textures) do
            if (not self.width or not self.height) then
                self.width, self.height = texture:getDimensions()
            end

            texture:mapPixel(function (_, _, r, g, b, a)
                local packedColor = packColor(r, g, b, a)

                if (not packedColors[packedColor]) then
                    if (#self.colors < 255) then
                        table.insert(self.colors, {r, g, b, a})
                    end
                end

                packedColors[packedColor] = true
                return r, g, b, a
            end)
        end
    end
end

---@param self SFDItem
---@param partType number
---@return SFDItemPart?
function SFDItem.getPart(self, partType)
    -- the index of a part is not the same as the type
    for _, part in ipairs(self.parts) do
        if (part.typeID == partType) then
            return part
        end
    end

    return nil
end

---@param self SFDItem
---@param r number
---@param g number
---@param b number
---@param a number
---@return integer?
function SFDItem.getColorIndex(self, r, g, b, a)
    for i, color in ipairs(self.colors) do
        if (color[1] == r and color[2] == g and color[3] == b and color[4] == a) then
            return i
        end
    end

    return nil
end

---@param item SFDItem
---@param path string
---@return boolean, string?
function SFDItem.toBinary(item, path)
    path = PathUtility.add(path, item.fileName .. ".item")

    local success, status = pcall(function ()
        local stream = ByteStream.new()

        stream:writeString(item.fileName)
        stream:writeString(item.gameName)
        stream:writeInt32(item.equipmentLayer - 1)
        stream:writeString(item.itemID)
        stream:writeBoolean(item.jacketUnderBelt)
        stream:writeBoolean(item.canEquip)
        stream:writeBoolean(item.canScript)
        stream:writeString(item.colorPalette)
    
        stream:writeInt32(item.width)
        stream:writeInt32(item.height)
    
        stream:writeColorTable(item.colors)
        --[[
        stream:writeByte(#item.colors)
        for _, color in ipairs(item.colors) do
            stream:writeByte(color[1] * 255)
            stream:writeByte(color[2] * 255)
            stream:writeByte(color[3] * 255)
            stream:writeByte((color[4] or 1) * 255)
        end
        ]]
    
        stream:writeInt32(#item.parts)
        stream:writeByte(0)
    
        for _, part in ipairs(item.parts) do
            local partTextureMaxIndex = part:getTexturesMaxIndex()
    
            stream:writeInt32(part.typeID - 1)
            stream:writeInt32(partTextureMaxIndex)
    
            for j=1, partTextureMaxIndex do
                local texture = part.textures[j]
    
                if (not texture) then
                    stream:writeBoolean(false)
                else
                    stream:writeBoolean(true)
    
                    local lastColorIndex = 0
                    local lastColorR, lastColorG, lastColorB, lastColorA = nil, nil, nil, nil
                    texture:mapPixel(function (_, _, r, g, b, a)
                        if (lastColorR == r and lastColorG == g and lastColorB == b and lastColorA == a) then
                            stream:writeBoolean(true)
                        else
                            local colorIndex = item:getColorIndex(r, g, b, a)
                            if (colorIndex and colorIndex ~= lastColorIndex) then
                                stream:writeBoolean(false)
                                stream:writeByte(colorIndex - 1)
    
                                lastColorIndex = colorIndex
                            else
                                stream:writeBoolean(true)
                            end
    
                            lastColorR, lastColorG, lastColorB, lastColorA = r, g, b, a
                        end
    
                        return r, g, b, a
                    end)
    
                    stream:writeByte(0)
                end
            end
        end
    
        local success, status = NativeFS.write(path, stream.data)

        if (not success) then
            error(status)
        end
    end)

    if (not success) then
        return false, status
    end

    return true
end

---@param item SFDItem
---@param path string
---@return boolean, string?
function SFDItem.toFolder(item, path)
    local handlerPath = PathUtility.add(path, item.fileName .. ".ini")
    local handler = IniHandler.new()

    handler:set("GameName", item.gameName)
    handler:setNumber("EquipmentLayer", item.equipmentLayer - 1)
    handler:set("ItemID", item.itemID)
    handler:setBoolean("JacketUnderBelt", item.jacketUnderBelt)
    handler:setBoolean("CanEquip", item.canEquip)
    handler:setBoolean("CanScript", item.canScript)
    handler:set("ColorPalette", item.colorPalette)

    local success, status = IniHandler.toFile(handler, handlerPath)
    if (not success) then return false, status end

    for _, part in ipairs(item.parts) do
        for i, texture in pairs(part.textures) do
            local texturePath = PathUtility.add(path, string.format("%d_%d.png", part.typeID - 1, i - 1))
            local textureData = texture:encode("png")

            local success, status = NativeFS.write(texturePath, textureData)
            if (not success) then return false, status end
        end
    end

    return true
end

---@param path string
---@return SFDItem?, string?
function SFDItem.fromBinary(path)
    local stream, status = ByteStream.fromFile(path)

    if (not stream) then return nil, status end

    ---@param imageData love.ImageData
    ---@return boolean
    local function imageDataIsEmpty(imageData)
        local imageWidth, imageHeight = imageData:getDimensions()

        if (imageWidth == 0 or imageHeight == 0) then
            return true
        end

        for i=0, imageWidth * imageHeight - 1 do
            local a = select(-1, imageData:getPixel(i % imageWidth, math.floor(i / imageHeight)))

            if (a > 0) then
                return false
            end
        end

        return true
    end

    local result

    local success, status = pcall(function ()
        result = SFDItem.new()
    
        result.fileName = stream:readString()
        result.gameName = stream:readString()
        result.equipmentLayer = stream:readInt32() + 1
        result.itemID = stream:readString()
        result.jacketUnderBelt = stream:readBoolean()
        result.canEquip = stream:readBoolean()
        result.canScript = stream:readBoolean()
        result.colorPalette = stream:readString()
    
        result.width = stream:readInt32()
        result.height = stream:readInt32()
    
        local itemTexturePixelCount = result.width * result.height
    
        result.colors = stream:readColorTable()
    
        local partCount = stream:readInt32()
        stream:readByte()
    
        for i=1, partCount do
            local part = SFDItemPart.new()
            part.typeID = stream:readInt32() + 1
            part.itemID = result.itemID
            part.textures = {}
    
            local textureCount = stream:readInt32()
            local emptyPart = true
    
            for j=1, textureCount do
                if (stream:readBoolean()) then
                    local lastColor = {0, 0, 0, 0}
    
                    local texture = love.image.newImageData(result.width, result.height)
    
                    for k=0, itemTexturePixelCount - 1 do
                        if (not stream:readBoolean()) then
                            local colorIndex = stream:readByte()
                            lastColor = result.colors[colorIndex + 1]
                        end
    
                        texture:setPixel(k % result.width, math.floor(k / result.height), lastColor[1], lastColor[2], lastColor[3], lastColor[4])
                    end
    
                    stream:readByte()
    
                    if (not imageDataIsEmpty(texture)) then
                        part.textures[j] = texture
    
                        emptyPart = false
                    end
                end
            end
    
            -- prevent gaps to make table length (#) accurate
            if (not emptyPart) then
                table.insert(result.parts, part)
            end
        end
    end)

    if (success) then
        return result
    end

    return nil, status
end

---@param path string
---@return SFDItem?, string?
function SFDItem.fromFolder(path)
    local handler, status = IniHandler.fromFile(path)

    if (not handler) then return nil, status end
    if (not handler:get("gamename")) then return nil, string.format("Missing '%s' in properties ini file", "gamename") end
    if (not handler:get("equipmentlayer")) then return nil, string.format("Missing '%s' in properties ini file", "equipmentlayer") end
    if (not handler:get("itemid")) then return nil, string.format("Missing '%s' in properties ini file", "itemid") end
    if (not handler:get("jacketunderbelt")) then return nil, string.format("Missing '%s' in properties ini file", "jacketunderbelt") end
    if (not handler:get("canequip")) then return nil, string.format("Missing '%s' in properties ini file", "canequip") end
    if (not handler:get("canscript")) then return nil, string.format("Missing '%s' in properties ini file", "canscript") end
    if (not handler:get("colorpalette")) then return nil, string.format("Missing '%s' in properties ini file", "colorpalette") end

    local result = SFDItem.new()
    result.fileName = PathUtility.getNameWithoutExtension(path)
    result.gameName = handler:get("gamename") --[[@as string]]
    result.equipmentLayer = handler:getNumber("equipmentlayer") + 1 --[[@as number]]
    result.itemID = handler:get("itemid") --[[@as string]]
    result.jacketUnderBelt = handler:getBoolean("jacketunderbelt") --[[@as boolean]]
    result.canEquip = handler:getBoolean("canequip") --[[@as boolean]]
    result.canScript = handler:getBoolean("canscript") --[[@as boolean]]
    result.colorPalette = handler:get("colorpalette") --[[@as string]]
    result.fromFolder = true
    result.fromFolderImagesPath = imagesPath
    result.fromFolderIniPath = path

    for i, file in ipairs(PathUtility.getFiles(PathUtility.getDirectoryPath(path), "%.png$")) do
        local success, status = NativeFS.read("data", file) --[[@as love.FileData]]
        if (not success) then
            return nil, status --[[@as string]]
        end

        local texture = love.image.newImageData(success)

        local fileName = PathUtility.getNameWithoutExtension(file)

        local fileNameBits = {}
        for bit in string.gmatch(fileName, "([^_]+)") do
            table.insert(fileNameBits, bit)
        end

        -- assume start at 0
        local textureTypeID = tonumber(fileNameBits[1])
        local textureID = tonumber(fileNameBits[2])

        if (textureTypeID and textureID) then
            local part = result:getPart(textureTypeID + 1)

            if (not part) then
                part = SFDItemPart.new()
                table.insert(result.parts, part)

                part.typeID = textureTypeID + 1
                part.itemID = result.itemID
            end

            part.textures[textureID + 1] = texture
        end
    end

    -- calculate width, height and used colors
    result:postProcessTextures()

    return result
end
