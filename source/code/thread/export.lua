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
    local directoryPath = PathUtility.getDirectoryPath(relativeToInputPath)

    NativeFS.setWorkingDirectory(inputPath)
    local item, status = SFDItem.fromBinary(relativeToInputPath)
    if (not item) then return false, status end

    local exportedItemPath = PathUtility.add(directoryPath, item.itemID)
    NativeFS.setWorkingDirectory(outputPath)
    NativeFS.createDirectory(exportedItemPath)
    local success, status = SFDItem.toFolder(item, exportedItemPath)
    if (not success) then return false, status end

    return true
end

worker:start()
