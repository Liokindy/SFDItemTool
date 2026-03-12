if (os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1") then require("lldebugger").start() end
---@alias Color {[1]: number, [2]: number, [3]: number, [4]: number}

print("loading libraries")
FFI = require("ffi")
Bit = require("bit") --[[@as bitlib]]
UTF8 = require("utf8") --[[@as utf8]]
NativeFS = require("library.nativefs.nativefs")
PortableFileDialogs = require("library.portable_file_dialogs.portable_file_dialogs") --[[@as PortableFileDialogs]]

--[[
local function loadCLI(arguments)
    local startTime = love.timer.getTime()

    local outputPath = "./Output/"
    local inputPath = "./Input/"
    local action

    for i=1, #arguments do
        local argument = arguments[i]

        if (string.lower(argument) == "-input") then
            i = i + 1

            inputPath = arguments[i]
        end

        if (string.lower(argument) == "-output") then
            i = i + 1

            outputPath = arguments[i]
        end

        if (string.lower(argument) == "-to") then
            i = i + 1

            action = string.lower(arguments[i])
        end
    end

    if (not action) then
        print("help:")
        print("\t-input [path]")
        print("\t-output [path]")
        print("\t-to [item|folder|pass]")
    else
        if (not outputPath or not inputPath) then
            error("Input or Output path not set")
        end

        print(string.format("save directory: %s", love.filesystem.getSaveDirectory()))
        print(string.format("[input]: %s", inputPath))
        print(string.format("[output]: %s", outputPath))
        print(string.format("[action]: %s", action))

        outputPath = PathUtility.trimStart(PathUtility.unixify(outputPath))
        inputPath = PathUtility.trimStart(PathUtility.unixify(inputPath))

        love.filesystem.createDirectory(outputPath)
        love.filesystem.createDirectory(inputPath)

        local inputItems = PathUtility.getFiles(inputPath)

        if (action == "item") then
            print(string.format("converting FOLDERS to ITEMS...", #inputItems))

            for i, itemPath in ipairs(inputItems) do
                local status, message = pcall(function ()
                    local itemExtension = PathUtility.getExtension(itemPath)
                    local itemDirectory = PathUtility.getDirectoryPath(itemPath)

                    local itemOutputDirectories = PathUtility.getDirectories(string.gsub(itemPath, inputPath, outputPath))
                    local itemOutputDirectory = table.concat(itemOutputDirectories, "/", 1, #itemOutputDirectories - 2)

                    if (itemExtension == "ini") then
                        local sfditem = SFDItem.fromFolder(itemDirectory, itemPath)

                        love.filesystem.createDirectory(itemOutputDirectory)

                        print("SFDItem.toBinary:", itemOutputDirectory, sfditem.fileName)
                        SFDItem.toBinary(sfditem, itemOutputDirectory)
                    end
                end)

                if (not status) then
                    print("[error]")
                    print("\t" .. message)
                end
            end
        elseif (action == "folder") then
            print(string.format("converting ITEMS to FOLDERS...", #inputItems))

            for i, itemPath in ipairs(inputItems) do
                local status, message = pcall(function ()
                    local itemExtension = PathUtility.getExtension(itemPath)
                    local itemDirectory = PathUtility.getDirectoryPath(itemPath)

                    if (itemExtension == "item") then
                        local sfditem = SFDItem.fromBinary(ByteStream.fromFile(itemPath))

                        local itemOutputPath = PathUtility.add(string.gsub(itemDirectory, inputPath, outputPath), sfditem.fileName)
                        love.filesystem.createDirectory(itemOutputPath)

                        print("SFDItem.toFolder:", itemOutputPath, sfditem.fileName)
                        SFDItem.toFolder(sfditem, itemOutputPath)
                    end
                end)

                if (not status) then
                    print("[error]")
                    print("\t" .. message)
                end
            end
        elseif (action == "pass") then
            print(string.format("passing ITEMS to ITEMS...", #inputItems))

            for i, itemPath in ipairs(inputItems) do
                local status, message = pcall(function ()
                    local itemExtension = PathUtility.getExtension(itemPath)
                    local itemDirectory = PathUtility.getDirectoryPath(itemPath)

                    if (itemExtension == "item") then
                        local sfditem = SFDItem.fromBinary(ByteStream.fromFile(itemPath))

                        local itemOutputPath = string.gsub(itemDirectory, inputPath, outputPath)
                        love.filesystem.createDirectory(itemOutputPath)

                        print("SFDItem.toBinary:", itemOutputPath, sfditem.fileName)
                        SFDItem.toBinary(sfditem, itemOutputPath)
                    end
                end)

                if (not status) then
                    print("[error]")
                    print("\t" .. message)
                end
            end
        else
            print("unknown action")
        end
    end

    local endTime = love.timer.getTime()

    print(string.format("finished in %.2fms", (endTime - startTime) * 1000))
end
]]

App = {}

---@type love.load
function love.load(arguments)
    love.window.setDisplaySleepEnabled(true)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1)
    love.graphics.setBackgroundColor(1, 0, 1, 1)
    love.keyboard.setKeyRepeat(true)

    print("loading classes")
    local function getLuaFiles(path, result)
        local items = love.filesystem.getDirectoryItems(path)

        for i, item in ipairs(items) do
            local fullPath = path .. "/" .. item
            local itemInfo = love.filesystem.getInfo(fullPath)

            if (itemInfo) then
                if (itemInfo.type == "file") then
                    if (string.match(string.match(item, "([^/]+)$"), "%.lua$")) then
                        table.insert(result, fullPath)
                    end
                elseif (itemInfo.type == "directory") then
                    getLuaFiles(fullPath, result)
                end
            end
        end

        return result
    end

    local items = getLuaFiles("class", {})
    for _, path in ipairs(items) do
        -- convert the path ("folder/subFolder/file.lua") to a require path ("folder.subFolder.file")
        require(string.gsub(string.gsub(path, "/", "."), "%.lua", ""))
    end

    App = {}
    App.version = "2.0"
    App.debug = false
    App.close = false
    App.updateTime = 0
    App.drawTime = 0
    App.cursor = love.mouse.getSystemCursor("arrow")

    print("loading configuration")
    App.configuration = {}

    local handler = IniHandler.fromFile(PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "configuration.ini")))
    App.configuration.inputPath = handler:tryGet("input_path", PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "Input")))
    App.configuration.outputPath = handler:tryGet("output_path", PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "Output")))
    App.configuration.themeDark = handler:tryGetBoolean("theme_dark", false)
    App.configuration.themeAccent = ColorUtility.fromHEX(handler:tryGet("theme_accent", ColorUtility.toHEX({0.9, 0.2, 0.5, 1})))
    App.configuration.fontSize = handler:tryGetNumber("font_size", 12)
    App.configuration.useMultipleThreads = handler:tryGetBoolean("use_multiple_threads", false)
    App.configuration.languageFile = handler:tryGet("language_file", "asset/language/english.ini")

    App.theme = {} --[[@as {[string]: Color}]]
    App.theme.accent = App.configuration.themeAccent

    if (not App.configuration.themeDark) then
        App.theme.main = {1, 1, 1, 1}
        App.theme.highlight = {0, 0, 0, 0.15}
        App.theme.mute = {0, 0, 0, 0.3}
        App.theme.text = {}
        App.theme.textMain = {0, 0, 0, 0.5}
        App.theme.textHighlight = {0, 0, 0, 1}
    else
        App.theme.main = {0.1, 0.1, 0.1, 1}
        App.theme.highlight = {0.8, 0.8, 0.8, 0.15}
        App.theme.mute = {0.05, 0.05, 0.05, 0.3}
        App.theme.textMain = {0.9, 0.9, 0.9, 0.5}
        App.theme.textHighlight = {0.9, 0.9, 0.9, 1}
    end

    print("loading fonts")
    local fontRegularPath = PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "asset/font/noto_sans/NotoSans-Regular.ttf"))
    local fontRegularData = NativeFS.read("data", fontRegularPath) --[[@as string]]
    local fontBoldPath = PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "asset/font/noto_sans/NotoSans-Bold.ttf"))
    local fontBoldData = NativeFS.read("data", fontBoldPath) --[[@as string]]

    App.font = {}
    App.font.regular = love.graphics.newFont(fontRegularData, App.configuration.fontSize)
    App.font.bold = love.graphics.newFont(fontBoldData, App.configuration.fontSize)

    print("loading shaders")
    local paletteShaderPath = PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "asset/shader/palette.frag"))
    local paletteShaderCode = NativeFS.read("string", paletteShaderPath) --[[@as string]]
    local highlightShaderPath = PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "asset/shader/highlight.frag"))
    local highlightShaderCode = NativeFS.read("string", highlightShaderPath) --[[@as string]]

    App.paletteShader = love.graphics.newShader(paletteShaderCode)
    App.highlightShader = love.graphics.newShader(highlightShaderCode)

    App.items = {}
    App.animations = {}

    print("loading language")
    App.language = IniHandler.fromFile(App.configuration.languageFile)

    print("starting")
    App.ui = UIApp.new()
    App.uiFocusedDraggableElement = nil
    App.uiFocusedElement = nil
    App.uiFocusableElementUnderMouse = App.ui

    if (#arguments > 0) then
        print("reading arguments")

        for i=1, #arguments do
            local argument = arguments[i]

            if (string.lower(argument) == "-input") then
                i = i + 1

                App.configuration.inputPath = arguments[i] or App.configuration.inputPath
            end
    
            if (string.lower(argument) == "-output") then
                i = i + 1

                App.configuration.outputPath = arguments[i] or App.configuration.outputPath
            end
    
            if (string.lower(argument) == "-to") then
                i = i + 1

                local action = string.lower(arguments[i] or "")
                if (action == "import") then
                    App.ui.importButton.onPressed()
    
                    while App.ui.subMenu do
                        App.ui.subMenu:update(0.001)
                        love.timer.sleep(0.001)
                    end

                    love.event.quit(0)
                elseif (action == "export") then
                    App.ui.exportButton.onPressed()
    
                    while App.ui.subMenu do
                        App.ui.subMenu:update(0.001)
                        love.timer.sleep(0.001)
                    end

                    love.event.quit(0)
                end
            end
        end
    end
end

---@type love.quit
function love.quit()
    local handler = IniHandler.new()
    handler:set("input_path", App.configuration.inputPath)
    handler:set("output_path", App.configuration.outputPath)
    handler:setBoolean("theme_dark", App.configuration.themeDark)
    handler:set("theme_accent", ColorUtility.toHEX(App.configuration.themeAccent))
    handler:setNumber("font_size", App.configuration.fontSize)
    handler:setBoolean("use_multiple_threads", App.configuration.useMultipleThreads)
    handler:set("language_file", App.configuration.languageFile)
    IniHandler.toFile(handler, PathUtility.osify(PathUtility.add(love.filesystem.getWorkingDirectory(), "configuration.ini")))

    return false
end

---@type love.resize
function love.resize(width, height)
    App.ui.width = width
    App.ui.height = height
end

---@type love.focus
function love.focus(focus)
    if (focus) then

    end
end

---@type love.mousemoved
function love.mousemoved(x, y, dx, dy)
    if (App.uiFocusedDraggableElement) then
        App.uiFocusedDraggableElement:mousemoved(x, y, dx, dy)
        return
    end

    if (App.uiFocusableElementUnderMouse) then
        App.uiFocusableElementUnderMouse:mousemoved(x, y, dx, dy)
    end
end

---@type love.mousepressed
function love.mousepressed(x, y, button)
    if (App.uiFocusedElement and App.uiFocusableElementUnderMouse ~= App.uiFocusedElement) then
        App.uiFocusedElement:mousepressed(x, y, button)
        App.uiFocusedElement = nil
    end

    if (App.uiFocusableElementUnderMouse) then
        App.uiFocusedElement = App.uiFocusableElementUnderMouse
        App.uiFocusedElement:mousepressed(x, y, button)

        if (App.uiFocusableElementUnderMouse.draggable) then
            App.uiFocusedDraggableElement = App.uiFocusableElementUnderMouse
        end
    end

    --App.ui:mousepressed(x, y, button)
end

---@type love.mousereleased
function love.mousereleased(x, y, button)
    if (App.uiFocusedElement) then
        App.uiFocusedElement:mousereleased(x, y, button)
    end

    if (App.uiFocusedDraggableElement) then
        App.uiFocusedDraggableElement = nil
    end

    --App.ui:mousereleased(x, y, button)
end

---@type love.wheelmoved
function love.wheelmoved(x, y)
    if (App.uiFocusableElementUnderMouse) then
        App.uiFocusableElementUnderMouse:wheelmoved(x, y)
    end
end

---@type love.keypressed
function love.keypressed(key)
    if (key == "f12") then
        App.debug = not App.debug
        return
    end

    if (love.keyboard.isDown("lctrl")) then
        if (key == "z") then
            ActionStack.undo()
            return
        elseif (key == "y") then
            ActionStack.redo()
            return
        end
    end

    if (App.uiFocusedElement) then
        App.uiFocusedElement:keypressed(key)
    end
end

---@type love.keyreleased
function love.keyreleased(key)
    if (App.uiFocusedElement) then
        App.uiFocusedElement:keyreleased(key)
    end
end

---@type love.textinput
function love.textinput(text)
    if (App.uiFocusedElement) then
        App.ui:textinput(text)
    end
end

---@type love.update
function love.update(deltaTime)
    App.cursor = love.mouse.getSystemCursor("arrow")

    local startUpdateTime = love.timer.getTime()
    App.ui:update(deltaTime)
    App.updateTime = love.timer.getTime() - startUpdateTime
    App.uiFocusableElementUnderMouse = App.ui:getOverlap(love.mouse.getX(), love.mouse.getY(), true)

    love.mouse.setCursor(App.cursor)
end

---@type love.draw
function love.draw()
    local startDrawTime = love.timer.getTime()
    App.ui:draw()
    App.drawTime = love.timer.getTime() - startDrawTime

    if (App.debug) then
        if (App.uiFocusableElementUnderMouse) then
            love.graphics.setColor(1, 0, 0, 0.2)
            love.graphics.rectangle("fill", App.uiFocusableElementUnderMouse:getDrawX(), App.uiFocusableElementUnderMouse:getDrawY(), App.uiFocusableElementUnderMouse.width, App.uiFocusableElementUnderMouse.height)
        end
        
        if (App.uiFocusedDraggableElement) then
            love.graphics.setColor(0, 1, 0, 0.2)
            love.graphics.rectangle("fill", App.uiFocusedDraggableElement:getDrawX(), App.uiFocusedDraggableElement:getDrawY(), App.uiFocusedDraggableElement.width, App.uiFocusedDraggableElement.height)
        end

        if (App.uiFocusedElement) then
            love.graphics.setColor(0, 0, 1, 0.2)
            love.graphics.rectangle("fill", App.uiFocusedElement:getDrawX(), App.uiFocusedElement:getDrawY(), App.uiFocusedElement.width, App.uiFocusedElement.height)
        end

        ---@param t table
        ---@return integer
        local function tableCount(t)
            local n = 0

            for _ in pairs(t) do
                n = n + 1
            end

            return n
        end

        local font = App.font.regular

        local text = ""
        text = text .. string.rep("=", 30) .. "\n"
        text = text .. string.format("FPS: %d", love.timer.getFPS()) .. "\n"
        text = text .. string.format("Update: %fms", App.updateTime * 1000) .. "\n"
        text = text .. string.format("Draw: %fms", App.drawTime * 1000) .. "\n"

        text = text .. string.rep("=", 30) .. "\n"
        text = text .. "LOVE WorkingDirectory:" .. "\n"
        text = text .. "\t" .. love.filesystem.getWorkingDirectory() .. "\n"
        text = text .. "NativeFS WorkingDirectory:" .. "\n"
        text = text .. "\t" .. NativeFS.getWorkingDirectory() .. "\n"
        text = text .. "Source:" .. "\n"
        text = text .. "\t" .. love.filesystem.getSource() .. "\n"

        text = text .. string.rep("=", 30) .. "\n"
        text = text .. string.format("Focusable Element Under Mouse: %s (%s)", tostring(App.uiFocusableElementUnderMouse and App.uiFocusableElementUnderMouse.__type or nil), tostring(App.uiFocusableElementUnderMouse)) .. "\n"
        text = text .. string.format("Focused Draggable Element: %s (%s)", tostring(App.uiFocusedDraggableElement and App.uiFocusedDraggableElement.__type or nil), tostring(App.uiFocusedDraggableElement)) .. "\n"
        text = text .. string.format("Focused Element: %s (%s)", tostring(App.uiFocusedElement and App.uiFocusedElement.__type or nil), tostring(App.uiFocusedElement)) .. "\n"

        text = text .. string.rep("=", 30) .. "\n"
        text = text .. "UNDO" .. "\n"
        for i, command in ipairs(ActionStack.undoStack) do
            text = text .. string.format("#%d '%s'", i, command.type) .. "\n"
        end

        text = text .. string.rep("=", 30) .. "\n"
        text = text .. "REDO" .. "\n"
        for i, command in ipairs(ActionStack.redoStack) do
            text = text .. string.format("#%d '%s'", i, command.type) .. "\n"
        end

        local debugPadding = 10
        local debugMargin = 10

        local textWidth, textLines = font:getWrap(text, love.graphics.getWidth() - debugMargin * 2)
        local textHeight = font:getHeight()

        local debugWidth = textWidth + debugPadding * 2
        local debugHeight = font:getHeight() * #textLines + debugPadding * 2
        local debugX = debugMargin
        local debugY = love.graphics.getHeight() - debugHeight - debugMargin

        love.graphics.setScissor()
        love.graphics.setFont(font)
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", debugX, debugY, debugWidth, debugHeight)
        love.graphics.setColor(1, 1, 1, 1)
        for i, line in ipairs(textLines) do
            love.graphics.print(line, debugX + debugPadding, debugY + debugPadding + (i - 1) * textHeight)
        end
    end
end
