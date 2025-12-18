-- LZString.lua
-- LZ-String compression library ported to Lua for WoW
-- Based on lz-string by Pieroxy (https://github.com/pieroxy/lz-string)

LZString = {}

local keyStrUriSafe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$"

local function getBaseValue(alphabet, char)
    for i = 1, #alphabet do
        if alphabet:sub(i, i) == char then
            return i - 1
        end
    end
    return nil
end

local function createCharMap(alphabet)
    local map = {}
    for i = 1, #alphabet do
        map[alphabet:sub(i, i)] = i - 1
    end
    return map
end

-- Compress function
local function _compress(uncompressed, bitsPerChar, getCharFromInt)
    if uncompressed == nil or uncompressed == "" then
        return ""
    end
    
    local context_dictionary = {}
    local context_dictionaryToCreate = {}
    local context_c = ""
    local context_wc = ""
    local context_w = ""
    local context_enlargeIn = 2
    local context_dictSize = 3
    local context_numBits = 2
    local context_data = {}
    local context_data_val = 0
    local context_data_position = 0
    
    for i = 1, #uncompressed do
        context_c = uncompressed:sub(i, i)
        
        if context_dictionary[context_c] == nil then
            context_dictionary[context_c] = context_dictSize
            context_dictSize = context_dictSize + 1
            context_dictionaryToCreate[context_c] = true
        end
        
        context_wc = context_w .. context_c
        
        if context_dictionary[context_wc] ~= nil then
            context_w = context_wc
        else
            if context_dictionaryToCreate[context_w] then
                if context_w:byte(1) < 256 then
                    for j = 1, context_numBits do
                        context_data_val = context_data_val * 2
                        if context_data_position == bitsPerChar - 1 then
                            context_data_position = 0
                            table.insert(context_data, getCharFromInt(context_data_val))
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                    end
                    local value = context_w:byte(1)
                    for j = 1, 8 do
                        context_data_val = context_data_val * 2 + (value % 2)
                        if context_data_position == bitsPerChar - 1 then
                            context_data_position = 0
                            table.insert(context_data, getCharFromInt(context_data_val))
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                        value = math.floor(value / 2)
                    end
                else
                    local value = 1
                    for j = 1, context_numBits do
                        context_data_val = context_data_val * 2 + (value % 2)
                        if context_data_position == bitsPerChar - 1 then
                            context_data_position = 0
                            table.insert(context_data, getCharFromInt(context_data_val))
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                        value = 0
                    end
                    value = context_w:byte(1)
                    for j = 1, 16 do
                        context_data_val = context_data_val * 2 + (value % 2)
                        if context_data_position == bitsPerChar - 1 then
                            context_data_position = 0
                            table.insert(context_data, getCharFromInt(context_data_val))
                            context_data_val = 0
                        else
                            context_data_position = context_data_position + 1
                        end
                        value = math.floor(value / 2)
                    end
                end
                context_enlargeIn = context_enlargeIn - 1
                if context_enlargeIn == 0 then
                    context_enlargeIn = 2 ^ context_numBits
                    context_numBits = context_numBits + 1
                end
                context_dictionaryToCreate[context_w] = nil
            else
                local value = context_dictionary[context_w]
                for j = 1, context_numBits do
                    context_data_val = context_data_val * 2 + (value % 2)
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        table.insert(context_data, getCharFromInt(context_data_val))
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = math.floor(value / 2)
                end
            end
            context_enlargeIn = context_enlargeIn - 1
            if context_enlargeIn == 0 then
                context_enlargeIn = 2 ^ context_numBits
                context_numBits = context_numBits + 1
            end
            context_dictionary[context_wc] = context_dictSize
            context_dictSize = context_dictSize + 1
            context_w = context_c
        end
    end
    
    if context_w ~= "" then
        if context_dictionaryToCreate[context_w] then
            if context_w:byte(1) < 256 then
                for j = 1, context_numBits do
                    context_data_val = context_data_val * 2
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        table.insert(context_data, getCharFromInt(context_data_val))
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                end
                local value = context_w:byte(1)
                for j = 1, 8 do
                    context_data_val = context_data_val * 2 + (value % 2)
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        table.insert(context_data, getCharFromInt(context_data_val))
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = math.floor(value / 2)
                end
            else
                local value = 1
                for j = 1, context_numBits do
                    context_data_val = context_data_val * 2 + (value % 2)
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        table.insert(context_data, getCharFromInt(context_data_val))
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = 0
                end
                value = context_w:byte(1)
                for j = 1, 16 do
                    context_data_val = context_data_val * 2 + (value % 2)
                    if context_data_position == bitsPerChar - 1 then
                        context_data_position = 0
                        table.insert(context_data, getCharFromInt(context_data_val))
                        context_data_val = 0
                    else
                        context_data_position = context_data_position + 1
                    end
                    value = math.floor(value / 2)
                end
            end
            context_enlargeIn = context_enlargeIn - 1
            if context_enlargeIn == 0 then
                context_enlargeIn = 2 ^ context_numBits
                context_numBits = context_numBits + 1
            end
            context_dictionaryToCreate[context_w] = nil
        else
            local value = context_dictionary[context_w]
            for j = 1, context_numBits do
                context_data_val = context_data_val * 2 + (value % 2)
                if context_data_position == bitsPerChar - 1 then
                    context_data_position = 0
                    table.insert(context_data, getCharFromInt(context_data_val))
                    context_data_val = 0
                else
                    context_data_position = context_data_position + 1
                end
                value = math.floor(value / 2)
            end
        end
        context_enlargeIn = context_enlargeIn - 1
        if context_enlargeIn == 0 then
            context_enlargeIn = 2 ^ context_numBits
            context_numBits = context_numBits + 1
        end
    end
    
    -- Mark end of stream
    local value = 2
    for j = 1, context_numBits do
        context_data_val = context_data_val * 2 + (value % 2)
        if context_data_position == bitsPerChar - 1 then
            context_data_position = 0
            table.insert(context_data, getCharFromInt(context_data_val))
            context_data_val = 0
        else
            context_data_position = context_data_position + 1
        end
        value = math.floor(value / 2)
    end
    
    while true do
        context_data_val = context_data_val * 2
        if context_data_position == bitsPerChar - 1 then
            table.insert(context_data, getCharFromInt(context_data_val))
            break
        else
            context_data_position = context_data_position + 1
        end
    end
    
    return table.concat(context_data)
end

function LZString.compressToEncodedURIComponent(input)
    if input == nil or input == "" then
        return ""
    end
    return _compress(input, 6, function(a)
        return keyStrUriSafe:sub(a + 1, a + 1)
    end)
end

-- Decompress function (for testing/verification)
local function _decompress(length, resetValue, getNextValue)
    local dictionary = {}
    local enlargeIn = 4
    local dictSize = 4
    local numBits = 3
    local entry = ""
    local result = {}
    local w = ""
    local c = ""
    local data_val = getNextValue(0)
    local data_position = resetValue
    local data_index = 1
    
    for i = 0, 2 do
        dictionary[i] = i
    end
    
    local bits = 0
    local maxpower = 2 ^ 2
    local power = 1
    
    while power ~= maxpower do
        local resb = data_val % 2
        data_val = math.floor(data_val / 2)
        if data_val == 0 then
            data_position = resetValue
            data_val = getNextValue(data_index)
            data_index = data_index + 1
        end
        bits = bits + (resb > 0 and power or 0)
        power = power * 2
    end
    
    local next = bits
    if next == 0 then
        bits = 0
        maxpower = 2 ^ 8
        power = 1
        while power ~= maxpower do
            local resb = data_val % 2
            data_val = math.floor(data_val / 2)
            if data_val == 0 then
                data_position = resetValue
                data_val = getNextValue(data_index)
                data_index = data_index + 1
            end
            bits = bits + (resb > 0 and power or 0)
            power = power * 2
        end
        c = string.char(bits)
    elseif next == 1 then
        bits = 0
        maxpower = 2 ^ 16
        power = 1
        while power ~= maxpower do
            local resb = data_val % 2
            data_val = math.floor(data_val / 2)
            if data_val == 0 then
                data_position = resetValue
                data_val = getNextValue(data_index)
                data_index = data_index + 1
            end
            bits = bits + (resb > 0 and power or 0)
            power = power * 2
        end
        c = string.char(bits)
    elseif next == 2 then
        return ""
    end
    
    dictionary[3] = c
    w = c
    table.insert(result, c)
    
    while true do
        if data_index > length then
            return ""
        end
        
        bits = 0
        maxpower = 2 ^ numBits
        power = 1
        while power ~= maxpower do
            local resb = data_val % 2
            data_val = math.floor(data_val / 2)
            if data_val == 0 then
                data_position = resetValue
                data_val = getNextValue(data_index)
                data_index = data_index + 1
            end
            bits = bits + (resb > 0 and power or 0)
            power = power * 2
        end
        
        local cc = bits
        if cc == 0 then
            bits = 0
            maxpower = 2 ^ 8
            power = 1
            while power ~= maxpower do
                local resb = data_val % 2
                data_val = math.floor(data_val / 2)
                if data_val == 0 then
                    data_position = resetValue
                    data_val = getNextValue(data_index)
                    data_index = data_index + 1
                end
                bits = bits + (resb > 0 and power or 0)
                power = power * 2
            end
            dictionary[dictSize] = string.char(bits)
            dictSize = dictSize + 1
            cc = dictSize - 1
            enlargeIn = enlargeIn - 1
        elseif cc == 1 then
            bits = 0
            maxpower = 2 ^ 16
            power = 1
            while power ~= maxpower do
                local resb = data_val % 2
                data_val = math.floor(data_val / 2)
                if data_val == 0 then
                    data_position = resetValue
                    data_val = getNextValue(data_index)
                    data_index = data_index + 1
                end
                bits = bits + (resb > 0 and power or 0)
                power = power * 2
            end
            dictionary[dictSize] = string.char(bits)
            dictSize = dictSize + 1
            cc = dictSize - 1
            enlargeIn = enlargeIn - 1
        elseif cc == 2 then
            return table.concat(result)
        end
        
        if enlargeIn == 0 then
            enlargeIn = 2 ^ numBits
            numBits = numBits + 1
        end
        
        if dictionary[cc] then
            entry = dictionary[cc]
        else
            if cc == dictSize then
                entry = w .. w:sub(1, 1)
            else
                return nil
            end
        end
        table.insert(result, entry)
        
        dictionary[dictSize] = w .. entry:sub(1, 1)
        dictSize = dictSize + 1
        enlargeIn = enlargeIn - 1
        
        if enlargeIn == 0 then
            enlargeIn = 2 ^ numBits
            numBits = numBits + 1
        end
        
        w = entry
    end
end

function LZString.decompressFromEncodedURIComponent(input)
    if input == nil or input == "" then
        return ""
    end
    input = input:gsub(" ", "+")
    local charMap = createCharMap(keyStrUriSafe)
    return _decompress(#input, 32, function(index)
        local char = input:sub(index + 1, index + 1)
        return charMap[char] or 0
    end)
end
