---@class IniHandler : Instance
---@field lines IniHandler.Line[]
---@field get fun(self: IniHandler, key: string): string?
---@field set fun(self: IniHandler, key: string, value: string)
---@field getNumber fun(self: IniHandler, key: string): number
---@field setNumber fun(self: IniHandler, key: string, value: number)
---@field getBoolean fun(self: IniHandler, key: string): boolean
---@field setBoolean fun(self: IniHandler, key: string, value: boolean)
---@field tryGet fun(self: IniHandler, key: string, backup: string): string
---@field tryGetNumber fun(self: IniHandler, key: string, backup: number): number
---@field tryGetBoolean fun(self: IniHandler, key: string, backup: boolean): boolean

---@class IniHandler.Line : table
---@field type "line"|"comment"|"section"
---@field key string
---@field value string

IniHandler = {}
IniHandler.__index = IniHandler
IniHandler.__type = "IniHandler"

---@return IniHandler
function IniHandler.new()
    local self = Instance.new(IniHandler) --[[@as IniHandler]]

    self.lines = {}

    return self
end

---@param path string
---@return IniHandler, string?
function IniHandler.fromFile(path)
    local result = IniHandler.new()

    local lines, status = NativeFS.lines(path)
    if (not lines) then
        return result, status
    end

    local i = 1
    for line in lines do
        local firstCharacter = string.sub(line, 1, 1)
        local isEmpty = (string.match(line, "^%s*$") ~= nil)

        if (not isEmpty) then
            if (firstCharacter == ";") then
                result.lines[i] = {
                    type = "comment",
                    key = line,
                    value = "",
                }

                i = i + 1
            elseif (firstCharacter == "[") then
                result.lines[i] = {
                    type = "section",
                    key = string.gsub(string.gsub(line, "^%[", ""), "%]$", ""), -- remove '[' and ']'
                    value = "",
                }

                i = i + 1
            else
                local key, value = IniHandler.splitLine(line)

                if (key and value) then
                    result.lines[i] = {
                        type = "line",
                        key = string.lower(key),
                        value = value,
                    }

                    i = i + 1
                end
            end
        end
    end

    return result
end

---@param line string
---@return string?, string?
function IniHandler.splitLine(line)
    line = string.match(line, "^%s*(.-)%s*$") -- spaces
    line = string.gsub(line, "%s*[;].*$", "") -- comments

    if (line == "") then
        return
    end

    local key, value = string.match(line, "^(.-)=(.*)$") -- first "="
    if (not key) then
        return
    end

    key = string.match(key, "^%s*(.-)%s*$") -- spaces
    value = string.match(value, "^%s*(.-)%s*$") -- spaces

    return key, value
end

---@param self IniHandler
---@param path string
---@return boolean, string?
function IniHandler.toFile(self, path)
    local data = ""

    for i, line in ipairs(self.lines) do
        if (line.type == "line") then
            data = data .. line.key .. "=" .. line.value
        elseif (line.type == "comment") then
            data = data .. line.key
        elseif (line.type == "section") then
            data = data .. "[" .. line.key .. "]"
        end

        data = data .. "\n"
    end

    local info = NativeFS.getInfo(path, "file")
    if (info) then
        local success, status = NativeFS.remove(path)
        if (not success) then return false, status end
    end

    return NativeFS.write(path, data)
end

---@param self IniHandler
---@param key string
---@return string?
function IniHandler.get(self, key)
    key = string.lower(key)

    for i, line in ipairs(self.lines) do
        if (line.type == "line" and line.key == key) then
            return line.value
        end
    end
end

---@param self IniHandler
---@param key string
---@param backup string
---@return string
function IniHandler.tryGet(self, key, backup)
    key = string.lower(key)

    return self:get(key) or backup
end

---@param self IniHandler
---@param key string
---@param backup boolean
---@return boolean
function IniHandler.tryGetBoolean(self, key, backup)
    return string.lower(self:tryGet(key, tostring(backup))) == "true"
end

---@param self IniHandler
---@param key string
---@param backup number
---@return number
function IniHandler.tryGetNumber(self, key, backup)
    return tonumber(self:tryGet(key, tostring(backup))) or backup
end

---@param self IniHandler
---@param key string
---@param value string
function IniHandler.set(self, key, value)
    key = string.lower(key)

    for i, line in ipairs(self.lines) do
        if (line.type == "line" and line.key == key) then
            line.value = value
            break
        end
    end

    table.insert(self.lines, {
        type = "line",
        key = key,
        value = value,
    })
end

---@param self IniHandler
---@param key string
---@return number?
function IniHandler.getNumber(self, key)
    return tonumber(self:get(key))
end

---@param self IniHandler
---@param key string
---@param value number
function IniHandler.setNumber(self, key, value)
    self:set(key, tostring(value))
end

---@param self IniHandler
---@param key string
---@return boolean
function IniHandler.getBoolean(self, key)
    return string.lower(self:get(key) or "") == "true"
end

---@param self IniHandler
---@param key string
---@param value boolean
function IniHandler.setBoolean(self, key, value)
    self:set(key, tostring(value))
end
