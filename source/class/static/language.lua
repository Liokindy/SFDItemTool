Language = {}

function Language.get(key, ...)
    key = string.lower(key)

    return string.format(App.language:tryGet(key, "?" .. key), ...)
end
