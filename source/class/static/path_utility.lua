PathUtility = {}

PathUtility.systemPathSeparator = string.sub(package.config, 1, 1)

---@param path string
---@return string
function PathUtility.trimStart(path)
    local s = string.gsub(string.gsub(path, "^%." .. PathUtility.systemPathSeparator, ""), "^" .. PathUtility.systemPathSeparator, "")
    return s
end

---@param path string
---@return string
function PathUtility.trimEnd(path)
    local s = string.gsub(path, PathUtility.systemPathSeparator .. "$", "")
    return s
end

---@param path string
---@return string
function PathUtility.trim(path)
    return PathUtility.trimStart(PathUtility.trimEnd(path))
end

---@param path string
---@param ... string
---@return string
function PathUtility.add(path, ...)
    path = PathUtility.trimEnd(path)

    for _, subPath in ipairs({...}) do
        path = path .. PathUtility.systemPathSeparator .. subPath
    end

    return path
end

---@param s string
---@param from string
---@param replacement string
---@return string, integer count
function PathUtility.replace(s, from, replacement)
    from = string.gsub(from, "[%W%.%+%-%*%?%^%$%(%)%[%]]", "%%%1") -- escape lua string patterns

    return string.gsub(s, from, replacement)
end

---@param path string
---@return string
function PathUtility.unixify(path)
    path = string.gsub(path, "\\", "/")
    path = string.gsub(path, "/+", "/")

    return path
end

---@param path string
---@return string
function PathUtility.osify(path)
    path = string.gsub(path, "/", PathUtility.systemPathSeparator)

    return path
end

---@param path string
---@return string
function PathUtility.getNameWithoutExtension(path)
    local s = PathUtility.getName(path)
    return string.match(s, "^(.*)%.") or s
end

---@param path string
---@return string
function PathUtility.getName(path)
    path = PathUtility.trimEnd(path)
    return string.match(path, "([^" .. PathUtility.systemPathSeparator .. "]+)$") or ""
end

---@param path string
---@return string
function PathUtility.getExtension(path)
    return string.match(path, "%.([^%.]+)$") or ""
end

---@param path string
---@return string[]
function PathUtility.getDirectories(path)
    path = PathUtility.trim(path)

    local directories = {}
    for directory in path:gmatch("[^" .. PathUtility.systemPathSeparator .. "]+") do
        table.insert(directories, directory)
    end

    return directories
end

---@param path string
---@return string
function PathUtility.getDirectoryPath(path)
    return string.match(path, "^(.*)" .. PathUtility.systemPathSeparator .. "[^" .. PathUtility.systemPathSeparator .. "]+$") or ""
end

---@param path string
function PathUtility.isFile(path)
    local info = NativeFS.getInfo(path)

    return (info and info.type == "file")
end

---@param path string
function PathUtility.isDirectory(path)
    local info = NativeFS.getInfo(path)

    return (info and info.type == "directory")
end

---@param path string
---@param namePattern string?
---@param itemTable string[]?
function PathUtility.getFiles(path, namePattern, itemTable)
    path = PathUtility.trimEnd(path)
    itemTable = itemTable or {}

	local items = NativeFS.getDirectoryItems(path)

	for i, item in ipairs(items) do
		local fullPath = PathUtility.add(path, item)
		local itemInfo = NativeFS.getInfo(fullPath)

		if (itemInfo) then
			if (itemInfo.type == "file") then
                local itemName = PathUtility.getName(item)

                if (not namePattern or (namePattern and string.match(itemName, namePattern))) then
                    table.insert(itemTable, fullPath)
                end
			elseif (itemInfo.type == "directory") then
                PathUtility.getFiles(fullPath, namePattern, itemTable)
			end
		end
	end

	return itemTable
end
