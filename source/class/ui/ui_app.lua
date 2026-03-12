---@class UIApp : UIElement
---@field subMenu UIElement
---@field inputFolderLabel UILabel
---@field inputFolderPathLabel UILabel
---@field inputFolderPathButton UIButton
---@field outputFolderLabel UILabel
---@field outputFolderPathLabel UILabel
---@field outputFolderPathButton UIButton
---@field exportButton UIButton
---@field importButton UIButton
---@field closeSubMenu fun(self: UIApp)
---@field openSubMenu fun(self: UIApp, menu: UIElement)

UIApp = {}
UIApp.__index = UIApp
UIApp.__type = "UIApp"

---@return UIApp
function UIApp.new()
    local self = setmetatable(UIElement.new(), setmetatable(UIApp, UIElement)) --[[@as UIApp]]

    self.width = love.graphics.getWidth()
    self.height = love.graphics.getHeight()

    self.inputFolderLabel = UILabel.new()
    self.inputFolderLabel.background = false
    self.inputFolderLabel.border = false
    self.inputFolderLabel.text = Language.get("ui.input_folder")
    self.inputFolderLabel.textAlignment = "center"

    self.inputFolderPathLabel = UILabel.new()
    self.inputFolderPathLabel.text = App.configuration.inputPath
    self.inputFolderPathLabel.textEditable = true

    self.inputFolderPathButton = UIButton.new()
    self.inputFolderPathButton.text = Language.get("ui.button.browse")
    self.inputFolderPathButton.textAlignment = "center"
    self.inputFolderPathButton.onPressed = function ()
        local selectedFolder = PortableFileDialogs.selectFolder(self.inputFolderLabel.text, self.inputFolderPathLabel.text)

        if (string.len(selectedFolder) > 0) then
            self.inputFolderPathLabel.text = selectedFolder
        end
    end

    self:addChild(self.inputFolderLabel)
    self:addChild(self.inputFolderPathLabel)
    self:addChild(self.inputFolderPathButton)

    self.outputFolderLabel = UILabel.new()
    self.outputFolderLabel.background = false
    self.outputFolderLabel.border = false
    self.outputFolderLabel.text = Language.get("ui.output_folder")
    self.outputFolderLabel.textAlignment = "center"

    self.outputFolderPathLabel = UILabel.new()
    self.outputFolderPathLabel.text = App.configuration.outputPath
    self.outputFolderPathLabel.textEditable = true

    self.outputFolderPathButton = UIButton.new()
    self.outputFolderPathButton.text = Language.get("ui.button.browse")
    self.outputFolderPathButton.textAlignment = "center"
    self.outputFolderPathButton.onPressed = function ()
        local selectedFolder = PortableFileDialogs.selectFolder(self.outputFolderLabel.text, self.outputFolderPathLabel.text)

        if (string.len(selectedFolder) > 0) then
            self.outputFolderPathLabel.text = selectedFolder
        end
    end

    self:addChild(self.outputFolderLabel)
    self:addChild(self.outputFolderPathLabel)
    self:addChild(self.outputFolderPathButton)

    -- TODO: move this elsewhere, improve/refactor
    local function createWorkerMenu(name, code, files)
        print("[" .. name .. " start]")
        print("input: ", App.configuration.inputPath)
        print("output: ", App.configuration.outputPath)

        print(string.format("found %d item files", #files))

        print("creating worker")
        local worker = {}
        worker.files = {}
        worker.threads = {}
        worker.statusChannels = {}
        worker.cancelChannels = {}

        print("creating threads")
        local totalFileCount = #files
        
        --TODO: fix bugs when using multiple threads
        local threadCount = App.configuration.useMultipleThreads and love.system.getProcessorCount() or 1

        local perThreadFileCount = math.ceil(totalFileCount / threadCount)

        for i=1, threadCount do
            worker.threads[i] = love.thread.newThread(code)
            worker.statusChannels[i] = love.thread.newChannel()
            worker.cancelChannels[i] = love.thread.newChannel()
            worker.files[i] = {}
    
            for j=1, math.min(perThreadFileCount, #files) do
                local file = table.remove(files)
                table.insert(worker.files[i], file)
    
                print("-", i, j, file)
            end
    
            if (#files == 0) then break end
        end

        print("starting threads")
        for i=1, #worker.threads do
            worker.threads[i]:start(worker.statusChannels[i], worker.cancelChannels[i], worker.files[i], App.configuration.inputPath, App.configuration.outputPath)
        end

        local menu = UIElement.new()
        menu.worker = worker
        menu.filesTotalCount = totalFileCount
        menu.filesSuccessCount = 0
        menu.filesFailCount = 0
        menu.progressBars = {}
        for i=1, #worker.threads do
            menu.progressBars[i] = UIBar.new()
            menu.progressBars[i].barTotal = #worker.files[i]
            menu:addChild(menu.progressBars[i])
        end
        menu.cancelButton = UIButton.new()
        menu.cancelButton.text = "Cancel"
        menu.cancelButton.textAlignment = "center"
        menu.cancelButton.onPressed = function ()
            print("cancelling threads")

            for i=1, #worker.threads do
                worker.cancelChannels[i]:supply(true)
                worker.threads[i]:wait()
            end
                            
            print("remaning: ", menu.filesTotalCount - (menu.filesFailCount + menu.filesSuccessCount))
            print("success: ", menu.filesSuccessCount)
            print("fail: ", menu.filesFailCount)

            print("[" .. name .. "cancel]")
            self:closeSubMenu()
        end
        menu:addChild(menu.cancelButton)

        menu.update = function (_, deltaTime)
            local padding = 10

            menu.x = 0
            menu.y = menu.parent.height * 0.25
            menu.width = menu.parent.width
            menu.height = menu.parent.height * 0.5

            menu.cancelButton.x = menu.width * 0.75 + padding
            menu.cancelButton.y = menu.height * 0.5 + padding
            menu.cancelButton.width = menu.width * 0.25 - padding * 2
            menu.cancelButton.height = menu.height * 0.5 - padding * 2

            if (menu.filesSuccessCount + menu.filesFailCount >= menu.filesTotalCount) then
                if (worker.threads) then
                    print("stopping threads")
                    menu.cancelButton.locked = true
                    
                    for i=1, #worker.threads do
                        worker.threads[i]:wait()
                    end
                end
                
                print("success: ", menu.filesSuccessCount)
                print("fail: ", menu.filesFailCount)

                print("[" .. name .. " finish]")
                self:closeSubMenu()
            else
                local barHeight = (menu.height * 0.5 - padding * 2) / #worker.threads

                for i=1, #worker.threads do
                    while (worker.statusChannels[i]:peek() ~= nil) do
                        local status = worker.statusChannels[i]:pop()
                        
                        if (status == true) then
                            menu.filesSuccessCount = menu.filesSuccessCount + 1
                        else
                            print("error: ", status)

                            menu.filesFailCount = menu.filesFailCount + 1
                        end

                        menu.progressBars[i].barCurrent = menu.progressBars[i].barCurrent + 1
                    end

                    menu.progressBars[i].x = padding
                    menu.progressBars[i].y = padding + barHeight * (i - 1)
                    menu.progressBars[i].width = menu.width - padding * 2
                    menu.progressBars[i].height = barHeight
                end
            end

            UIElement.update(menu, deltaTime)
        end

        self:openSubMenu(menu)
    end

    self.exportButton = UIButton.new()
    self.exportButton.text = Language.get("ui.button.export")
    self.exportButton.textAlignment = "center"
    self.exportButton.onPressed = function ()
        createWorkerMenu("export", "code/thread/export.lua", PathUtility.getFiles(App.configuration.inputPath, "%.item$"))
    end

    self.importButton = UIButton.new()
    self.importButton.text = Language.get("ui.button.import")
    self.importButton.textAlignment = "center"
    self.importButton.onPressed = function ()
        createWorkerMenu("import", "code/thread/import.lua", PathUtility.getFiles(App.configuration.inputPath, "%.ini$"))
    end

    self:addChild(self.exportButton)
    self:addChild(self.importButton)
    return self
end

---@param self UIApp
function UIApp.closeSubMenu(self)
    if (App.uiFocusableElementUnderMouse == self.subMenu) then
        App.uiFocusableElementUnderMouse = nil
    end

    if (App.uiFocusedDraggableElement == self.subMenu) then
        App.uiFocusedDraggableElement = nil
    end

    if (App.uiFocusedElement == self.subMenu) then
        App.uiFocusedElement = nil
    end

    self.subMenu = nil
end

---@param self UIApp
---@param menu UIElement
function UIApp.openSubMenu(self, menu)
    if (App.uiFocusableElementUnderMouse) then
        App.uiFocusableElementUnderMouse = nil
    end

    if (App.uiFocusedDraggableElement) then
        App.uiFocusedDraggableElement = nil
    end

    if (App.uiFocusedElement) then
        App.uiFocusedElement = menu
    end

    menu.parent = self

    self.subMenu = menu
end

---@param self UIApp
---@param x number
---@param y number
---@param button number
function UIApp.mousepressed(self, x, y, button)
    if (self.subMenu) then
        self.subMenu:mousepressed(x, y, button)
        return
    end

    UIElement.mousepressed(self, x, y, button)
end

---@param self UIApp
---@param x number
---@param y number
---@param focusable boolean
function UIApp.getOverlap(self, x, y, focusable)
    if (self.subMenu) then
        return self.subMenu:getOverlap(x, y, focusable) or self
    end

    return UIElement.getOverlap(self, x, y, focusable)
end

---@param self UIApp
---@param x number
---@param y number
---@param button number
function UIApp.mousereleased(self, x, y, button)
    if (self.subMenu) then
        self.subMenu:mousereleased(x, y, button)
        return
    end

    UIElement.mousereleased(self, x, y, button)
end

---@param self UIApp
---@param deltaTime number
function UIApp.update(self, deltaTime)
    if (self.subMenu) then
        self.subMenu:update(deltaTime)
        return
    end

    local padding = 8

    self.inputFolderLabel.x = 0
    self.inputFolderLabel.y = 0
    self.inputFolderLabel.width = math.ceil(self.width)
    self.inputFolderLabel.height = math.ceil(self.height * 0.125)

    self.inputFolderPathLabel.x = math.ceil(padding)
    self.inputFolderPathLabel.y = math.ceil(self.height * 0.125)
    self.inputFolderPathLabel.width = math.ceil(self.width * 0.8 - padding * 2)
    self.inputFolderPathLabel.height = math.ceil(self.height * 0.125)
    self.inputFolderPathLabel.textHorizontalPadding = math.ceil(padding)

    self.inputFolderPathButton.x = math.ceil(self.width * 0.8 + padding)
    self.inputFolderPathButton.y = math.ceil(self.height * 0.125)
    self.inputFolderPathButton.width = math.ceil(self.width * 0.2 - padding * 2)
    self.inputFolderPathButton.height = math.ceil(self.height * 0.125)

    self.outputFolderLabel.x = 0
    self.outputFolderLabel.y = math.ceil(self.height * 0.25)
    self.outputFolderLabel.width = math.ceil(self.width)
    self.outputFolderLabel.height = math.ceil(self.height * 0.125)

    self.outputFolderPathLabel.x = math.ceil(padding)
    self.outputFolderPathLabel.y = math.ceil(self.height * 0.375)
    self.outputFolderPathLabel.width = math.ceil(self.width * 0.8 - padding * 2)
    self.outputFolderPathLabel.height = math.ceil(self.height * 0.125)
    self.outputFolderPathLabel.textHorizontalPadding = math.ceil(padding)
    self.outputFolderPathLabel.textPlaceholder = self.inputFolderPathLabel.text

    self.outputFolderPathButton.x = math.ceil(self.width * 0.8 + padding)
    self.outputFolderPathButton.y = math.ceil(self.height * 0.375)
    self.outputFolderPathButton.width = math.ceil(self.width * 0.2 - padding * 2)
    self.outputFolderPathButton.height = math.ceil(self.height * 0.125)

    self.exportButton.x = math.ceil(padding)
    self.exportButton.y = math.ceil(self.height * 0.5 + padding)
    self.exportButton.width = math.ceil(self.width * 0.5 - padding * 2)
    self.exportButton.height = math.ceil(self.height * 0.5 - padding * 2)

    self.importButton.x = math.ceil(self.width * 0.5 + padding)
    self.importButton.y = math.ceil(self.height * 0.5 + padding)
    self.importButton.width = math.ceil(self.width * 0.5 - padding * 2)
    self.importButton.height = math.ceil(self.height * 0.5 - padding * 2)

    App.configuration.inputPath = self.inputFolderPathLabel.text
    App.configuration.outputPath = self.outputFolderPathLabel.text

    UIElement.update(self, deltaTime)
end

---@param self UIApp
function UIApp.draw(self)
    UIElement.draw(self)

    if (self.subMenu) then
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", self:getDrawX(), self:getDrawY(), self.width, self.height)
        self.subMenu:draw()
        return
    end
end
