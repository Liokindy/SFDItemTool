require("love.data")
require("love.image")

Bit = require("bit")
NativeFS = require("library.nativefs.nativefs")

require("class.instance")
require("class.io.byte_stream")
require("class.io.file_worker")
require("class.io.ini_handler")
require("class.sfd.sfd_item_part")
require("class.sfd.sfd_item")
require("class.static.path_utility")

---@type love.Channel, love.Channel, string[], string, string
local statusChannel, cancelChannel, files, inputPath, outputPath = ...

local worker = FileWorker.new()
worker.statusChannel = statusChannel
worker.cancelChannel = cancelChannel
worker.files = files

worker.onFileProcess = function (file)
    local relativeToInputPath = PathUtility.trim(PathUtility.replace(file, inputPath, ""))

    NativeFS.setWorkingDirectory(inputPath)
    local item, status = SFDItem.fromFolder(relativeToInputPath)
    if (not item) then return false, status end

    local importedItemPath = PathUtility.add(PathUtility.getDirectoryPath(PathUtility.getDirectoryPath(relativeToInputPath)), item.ID)
    NativeFS.setWorkingDirectory(outputPath)
    NativeFS.createDirectory(importedItemPath)
    local success, status = SFDItem.toBinary(item, importedItemPath)
    if (not success) then return false, status end

    return true
end

worker:start()
