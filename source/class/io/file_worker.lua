---@class FileWorker : Instance
---@field files string[]
---@field statusChannel love.Channel
---@field cancelChannel love.Channel
---@field onFileProcess fun(file: string): boolean, string?
---@field start fun(self: FileWorker)

FileWorker = {}
FileWorker.__index = FileWorker

function FileWorker.new()
    local self = Instance.new(FileWorker) --[[@as FileWorker]]

    return self
end

---@param self FileWorker
function FileWorker.start(self)
    for i, file in ipairs(self.files) do
        if (self.cancelChannel:pop() ~= nil) then
            return
        end

        local success, status = self.onFileProcess(file)

        if (success) then
            self.statusChannel:push(true)
        else
            self.statusChannel:push(tostring(status))
        end
    end
end

return FileWorker
