---@class ByteStream : Instance
---@field data string
---@field index number
---@field setData fun(self: ByteStream, newData: string)
---@field write fun(self: ByteStream, byteData: string)
---@field read fun(self: ByteStream, byteCount: number): string
---@field writeUInt32 fun(self: ByteStream, value: number)
---@field readUInt32 fun(self: ByteStream): number
---@field writeInt32 fun(self: ByteStream, value: number)
---@field readInt32 fun(self: ByteStream): number
---@field writeFloat fun(self: ByteStream, value: number)
---@field readFloat fun(self: ByteStream): number
---@field writeBoolean fun(self: ByteStream, value: boolean)
---@field readBoolean fun(self: ByteStream): boolean
---@field writeByte fun(self: ByteStream, value: number)
---@field readByte fun(self: ByteStream): number
---@field writeString fun(self: ByteStream, value: string)
---@field readString fun(self: ByteStream): string
---@field write7BitEncodedInt fun(self: ByteStream, value: number)
---@field read7BitEncodedInt fun(self: ByteStream): number
---@field writeColorTable fun(self: ByteStream, value: Color[])
---@field readColorTable fun(self: ByteStream): Color[]
---@field writeColor fun(self: ByteStream, value: Color)
---@field readColor fun(self: ByteStream): Color

ByteStream = {}
ByteStream.__type = "ByteStream"
ByteStream.__index = ByteStream

---@return ByteStream
function ByteStream.new()
    local self = Instance.new(ByteStream) --[[@as ByteStream]]

    self.data = ""
    self.index = 0

    return self
end

---@param path string
---@return ByteStream?, string?
function ByteStream.fromFile(path)
    local self = ByteStream.new()


    local fileData, fileSize = NativeFS.read("string", path, nil)

    if (fileData and fileSize) then
        self:setData(fileData --[[@as string]])
    else
        return nil, fileSize --[[@as string]]
    end

    return self
end

---@param self ByteStream
---@param data string
function ByteStream.setData(self, data)
    self.data = data
    self.index = 1
end

---@param self ByteStream
---@param data string
function ByteStream.write(self, data)
    self.data = self.data .. data
    self.index = self.index + #data
end

---@param self ByteStream
---@param byteCount number
---@return string
function ByteStream.read(self, byteCount)
    local byteData = string.sub(self.data, self.index, self.index + byteCount - 1)
    self.index = self.index + byteCount

    return byteData
end

---@param self ByteStream
---@param value number
function ByteStream.writeUInt32(self, value)
    self:write(love.data.pack("string", "I4", value) --[[@as string]])
end

---@param self ByteStream
---@return number
function ByteStream.readUInt32(self)
    local value, _ = love.data.unpack("I4", self:read(love.data.getPackedSize("I4")))
    return value --[[@as number]]
end

---@param self ByteStream
---@param value number
function ByteStream.writeInt32(self, value)
    self:write(love.data.pack("string", "i4", value) --[[@as string]])
end

---@param self ByteStream
---@return number
function ByteStream.readInt32(self)
    local value, _ = love.data.unpack("i4", self:read(love.data.getPackedSize("i4")))
    return value --[[@as number]]
end

---@param self ByteStream
---@param value Color[]
function ByteStream.writeColorTable(self, value)
    self:writeByte(#value)

    for i=1, math.min(255, #value) do
        self:writeColor(value[i])
    end
end

---@param self ByteStream
---@return Color[]
function ByteStream.readColorTable(self)
    local length = self:readByte()
    local value = {}

    for i=1, length do
        value[i] = self:readColor()
    end

    return value
end

---@param self ByteStream
---@param value Color
function ByteStream.writeColor(self, value)
    self:writeByte(value[1] * 255)
    self:writeByte(value[2] * 255)
    self:writeByte(value[3] * 255)
    self:writeByte((value[4] or 1) * 255)
end

---@param self ByteStream
---@return Color
function ByteStream.readColor(self)
    local mult = 1 / 255
    return {self:readByte() * mult, self:readByte() * mult, self:readByte() * mult, self:readByte() * mult}
end

---@param self ByteStream
---@param value number
function ByteStream.writeFloat(self, value)
    self:write(love.data.pack("string", "f", value) --[[@as string]])
end

---@param self ByteStream
---@return number
function ByteStream.readFloat(self)
    local value, _ = love.data.unpack("f", self:read(love.data.getPackedSize("f"))) 
    return value --[[@as number]]
end

---@param self ByteStream
---@param value boolean
function ByteStream.writeBoolean(self, value)
    self:writeByte((value == true and 1 or 0))
end

---@param self ByteStream
---@return boolean
function ByteStream.readBoolean(self)
    return (self:readByte() ~= 0)
end

---@param self ByteStream
---@param value number
function ByteStream.writeByte(self, value)
    self:write(love.data.pack("string", "B", value) --[[@as string]])
end

---@param self ByteStream
---@return number
function ByteStream.readByte(self)
    local value, _ = love.data.unpack("B", self:read(love.data.getPackedSize("B"))) 
    return value --[[@as number]]
end

---@param self ByteStream
---@param value string
function ByteStream.writeString(self, value)
    self:write7BitEncodedInt(#value)
    self:write(value)
end

---@param self ByteStream
---@return string
function ByteStream.readString(self)
    local length = self:read7BitEncodedInt()
    local str = self:read(love.data.getPackedSize(string.format("c%d", length)))

    return str
end

---@param self ByteStream
---@param value number
function ByteStream.write7BitEncodedInt(self, value)
    local num = love.data.unpack("i4", love.data.pack("string", "i4", value)) --[[@as number]]
    while (num >= 128) do
        self:writeByte(Bit.bor(num, 128))

        num = Bit.rshift(num, 7)
    end

    self:writeByte(num)
end

---@param self ByteStream
---@return number
function ByteStream.read7BitEncodedInt(self)
    local count = 0
    local shift = 0
    local b

    while (true) do
        b = love.data.unpack("B", self.data, self.index) --[[@as number]]
        self.index = self.index + love.data.getPackedSize("B")

        if (b == -1) then
            return 0
        end

        count = Bit.bor(count, Bit.lshift(Bit.band(b, 0x7F), shift))
        shift = shift + 7

        if (Bit.band(b, 0x80) == 0) then
            return count
        end

        if (shift >= 35) then
            return 0
        end
    end
end
