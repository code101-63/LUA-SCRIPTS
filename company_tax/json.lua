-- json.lua
-- JSON encoder and decoder in Lua

local json = {}

-- Encode a Lua table to JSON string
function json.encode(obj)
    local jsonString = ""
    if type(obj) == "table" then
        local function encodeTable(t)
            jsonString = jsonString .. "{"
            local comma = false
            for k, v in pairs(t) do
                if comma then
                    jsonString = jsonString .. ","
                end
                jsonString = jsonString .. '"' .. k .. '":' .. encodeValue(v)
                comma = true
            end
            jsonString = jsonString .. "}"
        end

        local function encodeArray(arr)
            jsonString = jsonString .. "["
            local comma = false
            for i, v in ipairs(arr) do
                if comma then
                    jsonString = jsonString .. ","
                end
                jsonString = jsonString .. encodeValue(v)
                comma = true
            end
            jsonString = jsonString .. "]"
        end

        local function encodeValue(value)
            if type(value) == "table" then
                if #value > 0 then
                    encodeArray(value)
                else
                    encodeTable(value)
                end
            elseif type(value) == "string" then
                jsonString = jsonString .. '"' .. value .. '"'
            else
                jsonString = jsonString .. tostring(value)
            end
        end

        encodeTable(obj)
    end

    return jsonString
end

-- Decode a JSON string to a Lua table
function json.decode(jsonString)
    return load("return " .. jsonString)()
end

return json
