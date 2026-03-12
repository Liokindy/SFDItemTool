---@type love.conf
function love.conf(t)
    t.identity = "DeluxeBench"
    t.version = "11.5"

    t.window.title = "DeluxeBench"
    t.window.resizable = true
    t.window.minwidth = 320
    t.window.minheight = 240
    t.window.width = 640
    t.window.height = 240

    t.modules.joystick = false
    t.modules.physics = false
end
