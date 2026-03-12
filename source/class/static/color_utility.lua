ColorUtility = {}

---@overload fun(color: Color): string
---@param r number
---@param g number
---@param b number
---@param a number?
---@return string
function ColorUtility.toHEX(r, g, b, a)
    if (type(r) == "table") then
        return ColorUtility.toHEX(r[1], r[2], r[3], r[4])
    end

    return string.format("#%02x%02x%02x", math.ceil(r * 255), math.ceil(g * 255), math.ceil(b * 255)) .. (a and string.format("%02x", math.ceil(a * 255)) or "")
end

---@param hex string
---@return Color
function ColorUtility.fromHEX(hex)
    local r = 0
    local g = 0
    local b = 0
    local a = 255

    if (string.len(hex) >= 6) then
        if (string.sub(hex, 1, 1) == "#") then
            hex = string.sub(hex, 2)
        end

        r = tonumber("0x" .. string.sub(hex, 1, 2)) or 0
		g = tonumber("0x" .. string.sub(hex, 3, 4)) or 0
		b = tonumber("0x" .. string.sub(hex, 5, 6)) or 0

        if (string.len(hex) >= 8) then
            a = tonumber("0x" .. string.sub(hex, 7, 8)) or 255
        end
    end

    return {r / 255, g / 255, b / 255, a / 255}
end
