-- https://github.com/samhocevar/portable-file-dialogs

---@alias PortableFileDialogs.Icon
---| "info" # 0
---| "warning" # 1
---| "error" # 2
---| "question" # 3

---@alias PortableFileDialogs.IconID
---| 0 # "info"
---| 1 # "warning"
---| 2 # "error"
---| 3 # "question"

---@alias PortableFileDialogs.Choice
---| "ok" # 0
---| "okcancel" # 1
---| "yesno" # 2
---| "yesnocancel" # 3
---| "retrycancel" # 4
---| "abortretryignore" # 5

---@alias PortableFileDialogs.ChoiceID
---| 0 # "ok"
---| 1 # "okcancel"
---| 2 # "yesno"
---| 3 # "yesnocancel"
---| 4 # "retrycancel"
---| 5 # "abortretryignore"

---@alias PortableFileDialogs.Button
---| "cancel" # -1
---| "ok" # 0
---| "yes" # 1
---| "no" # 2
---| "abort" # 3
---| "retry" # 4
---| "ignore" # 5

---@alias PortableFileDialogs.ButtonID
---| -1 # "cancel"
---| 0 # "ok"
---| 1 # "yes"
---| 2 # "no"
---| 3 # "abort"
---| 4 # "retry"
---| 5 # "ignore"

---@alias PortableFileDialogs.Option
---| "none"
---| "multiselect" # For file open, allow multiselect.
---| "force_overwrite" # For file save, force overwrite and disable the confirmation dialog.
---| "force_path" # For folder select, force path to be the provided argument instead of the last opened directory, which is the Microsoft-recommended, user-friendly behaviour.

---@alias PortableFileDialogs.OptionID
---| 0 # "none"
---| 1 # "multiselect"
---| 2 # "force_overwrite"
---| 4 # "force_path"

local binaryPath = love.filesystem.getWorkingDirectory() .. "/binary/portable_file_dialogs/portable-file-dialogs.dll"
local binary = FFI.load(binaryPath) -- https://github.com/samhocevar/portable-file-dialogs

FFI.cdef(
[[
    void   notify(const char *title, const char *message, int8_t icon);
    int8_t message(const char *title, const char *text, int8_t choice, int8_t icon);
    char** open_file(const char *title, const char *initial_path, const char **filters, int8_t option, uint8_t filter_size);
    char*  save_file(const char *title, const char *initial_path, const char **filters, int8_t option, uint8_t filter_size);
    char*  select_folder(const char *title, const char *default_path, int8_t option);
]])

local function convertStringArray(pointer)
    local result = {}
    local i = 0

    while (tostring(pointer[i]) ~= "cdata<char *>: NULL") do
        table.insert(result, FFI.string(pointer[i]))
        i = i + 1
    end

    return result
end

---@param icon PortableFileDialogs.Icon?
---@return PortableFileDialogs.IconID
local function getIconID(icon)
    --[[
    enum class icon
    {
        info = 0,
        warning,
        error,
        question,
    };
    ]]

    local iconID = 0

    if (icon == "warning") then
        iconID = 1
    elseif (icon == "error") then
        iconID = 2
    elseif (icon == "question") then
        iconID = 3
    end

    return iconID
end

---@param buttonID PortableFileDialogs.ButtonID
---@return PortableFileDialogs.Button
local function getButton(buttonID)
    --[[
    enum class button
    {
        cancel = -1,
        ok,
        yes,
        no,
        abort,
        retry,
        ignore,
    };
    ]]

    if (buttonID == -1) then
        return "cancel"
    elseif (buttonID == 0) then
        return "ok"
    elseif (buttonID == 1) then
        return "yes"
    elseif (buttonID == 2) then
        return "no"
    elseif (buttonID == 3) then
        return "abort"
    elseif (buttonID == 4) then
        return "retry"
    elseif (buttonID == 5) then
        return "ignore"
    end

    return "cancel"
end

---@param optionTable PortableFileDialogs.Option[]?
---@return PortableFileDialogs.OptionID
local function getOptionID(optionTable)
    --[[
    enum class opt : uint8_t
    {
        none = 0,
        // For file open, allow multiselect.
        multiselect     = 0x1,
        // For file save, force overwrite and disable the confirmation dialog.
        force_overwrite = 0x2,
        // For folder select, force path to be the provided argument instead
        // of the last opened directory, which is the Microsoft-recommended,
        // user-friendly behaviour.
        force_path      = 0x4,
    };
    ]]

    local optionID = 0

    if (not optionTable) then
        return optionID
    end

    for i=1, #optionTable do
        local option = optionTable[i]

        if (option == "warning") then
            optionID = Bit.bor(optionID, 1)
        elseif (option == "error") then
            optionID = Bit.bor(optionID, 2)
        elseif (option == "question") then
            optionID = Bit.bor(optionID, 4)
        end
    end

    return optionID
end

---@param choice PortableFileDialogs.Choice?
---@return PortableFileDialogs.ChoiceID id
local function getChoiceID(choice)
    --[[
    enum class choice
    {
        ok = 0,
        ok_cancel,
        yes_no,
        yes_no_cancel,
        retry_cancel,
        abort_retry_ignore,
    };
    ]]

    local choiceID = 0

    if (choice == "okcancel") then
        choiceID = 1
    elseif (choice == "yesno") then
        choiceID = 2
    elseif (choice == "yesnocancel") then
        choiceID = 3
    elseif (choice == "retrycancel") then
        choiceID = 4
    elseif (choice == "abortretryignore") then
        choiceID = 5
    end

    return choiceID
end

---@class PortableFileDialogs
local PortableFileDialogs = {}

---@param title string
---@param message string
---@param icon PortableFileDialogs.Icon?
function PortableFileDialogs.notify(title, message, icon)
    binary.notify(title, message, getIconID(icon))
end

---@param title string
---@param text string
---@param choice PortableFileDialogs.Choice?
---@param icon PortableFileDialogs.Icon?
---@return PortableFileDialogs.Button button
function PortableFileDialogs.message(title, text, choice, icon)
    local buttonID = binary.message(title, text, getChoiceID(choice), getIconID(icon))

    return getButton(buttonID)
end

---@param title string
---@param initialPath string?
---@param filters string[]?
---@param options PortableFileDialogs.Option[]?
---@return string[]
function PortableFileDialogs.openFile(title, initialPath, filters, options)
    local f = filters or {"All Files", "*"}
    local strPtr = FFI.new("const char*[?]", #f + 1, f)
    local path = initialPath or ""

    local ret = binary.open_file(title, path, strPtr, getOptionID(options), #f)
    return convertStringArray(ret)
end

---@param title string
---@param initialPath string?
---@param filters string[]?
---@param options PortableFileDialogs.Option[]?
---@return string
function PortableFileDialogs.saveFile(title, initialPath, filters, options)
    local f = filters or {"All Files", "*"}
    local strPtr = FFI.new("const char*[?]", #f + 1, f)
    local path = initialPath or ""

    local ret = binary.save_file(title, path, strPtr, getOptionID(options), #f)
    return FFI.string(ret)
end

---@param title string
---@param defaultPath string?
---@param options PortableFileDialogs.Option[]?
---@return string
function PortableFileDialogs.selectFolder(title, defaultPath, options)
    local path = defaultPath or ""

    local ret = binary.select_folder(title, path, getOptionID(options))
    return FFI.string(ret)
end

return PortableFileDialogs
