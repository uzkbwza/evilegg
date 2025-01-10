-- The MIT License (MIT)
--
-- Copyright (c) 2013 DelusionalLogic
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local deflate = require("lib.png.deflatelua")
local requiredDeflateVersion = "0.3.20111128"

if (deflate._VERSION ~= requiredDeflateVersion) then
    error("Incorrect deflate version: must be "..requiredDeflateVersion..", not "..deflate._VERSION)
end

local function bsRight(num, pow)
    return math.floor(num / 2^pow)
end

local function bsLeft(num, pow)
    return math.floor(num * 2^pow)
end

local function bytesToNum(bytes)
    local n = 0
    for k,v in ipairs(bytes) do
        n = bsLeft(n, 8) + v
    end
    if (n > 2147483647) then
        return (n - 4294967296)
    else
        return n
    end
end

local function readInt(stream, bps)
    local bytes = {}
    bps = bps or 4
    for i=1,bps do
        bytes[i] = stream:read(1):byte()
    end
    return bytesToNum(bytes)
end

local function readChar(stream, num)
    num = num or 1
    return stream:read(num)
end

local function readByte(stream)
    return stream:read(1):byte()
end

local function getDataIHDR(stream, length)
    local data = {}
    data["width"] = readInt(stream)
    data["height"] = readInt(stream)
    data["bitDepth"] = readByte(stream)
    data["colorType"] = readByte(stream)
    data["compression"] = readByte(stream)
    data["filter"] = readByte(stream)
    data["interlace"] = readByte(stream)
    return data
end

local function getDataIDAT(stream, length, oldData)
    local data = {}
    if (oldData == nil) then
        data.data = readChar(stream, length)
    else
        data.data = oldData.data .. readChar(stream, length)
    end
    return data
end

local function getDataPLTE(stream, length)
    local data = {}
    data["numColors"] = math.floor(length/3)
    data["colors"] = {}
    for i = 1, data["numColors"] do
        data.colors[i] = {
            R = readByte(stream),
            G = readByte(stream),
            B = readByte(stream),
            A = 255
        }
    end
    return data
end

local function getDatatRNS(stream, length, palette)
    local data = {}
    data["numColors"] = length
    data["colors"] = {}
    for i = 1, length do
        palette.colors[i].A = readByte(stream)
    end
    return data
end

local function extractChunkData(stream)
    local chunkData = {}
    local length
    local chunkType
    local crc

    while chunkType ~= "IEND" do
        length = readInt(stream)
        chunkType = readChar(stream, 4)
        if (chunkType == "IHDR") then
            chunkData[chunkType] = getDataIHDR(stream, length)
        elseif (chunkType == "IDAT") then
            chunkData[chunkType] = getDataIDAT(stream, length, chunkData[chunkType])
        elseif (chunkType == "PLTE") then
            chunkData[chunkType] = getDataPLTE(stream, length)
        elseif (chunkType == "tRNS") then
            chunkData[chunkType] = getDatatRNS(stream, length, chunkData["PLTE"])
        else
            readChar(stream, length)
        end
        crc = readChar(stream, 4)
    end

    return chunkData
end

local function makePixel(stream, depth, colorType, palette)
    local bps = math.floor(depth/8)
    local pixelData = { R = 0, G = 0, B = 0, A = 0, I = 0 }
    local grey
    local index
    local color

    if colorType == 0 then
        grey = readInt(stream, bps)
        pixelData.R = grey
        pixelData.G = grey
        pixelData.B = grey
        pixelData.A = 255
    elseif colorType == 2 then
        pixelData.R = readInt(stream, bps)
        pixelData.G = readInt(stream, bps)
        pixelData.B = readInt(stream, bps)
        pixelData.A = 255
    elseif colorType == 3 then
        index = readInt(stream, bps) + 1
        color = palette.colors[index]
        pixelData.R = color.R
        pixelData.G = color.G
        pixelData.B = color.B
        pixelData.A = color.A
        pixelData.I = index
    elseif colorType == 4 then
        grey = readInt(stream, bps)
        pixelData.R = grey
        pixelData.G = grey
        pixelData.B = grey
        pixelData.A = readInt(stream, bps)
    elseif colorType == 6 then
        pixelData.R = readInt(stream, bps)
        pixelData.G = readInt(stream, bps)
        pixelData.B = readInt(stream, bps)
        pixelData.A = readInt(stream, bps)
    end

    return pixelData
end

local function bitFromColorType(colorType)
    if colorType == 0 then return 1 end
    if colorType == 2 then return 3 end
    if colorType == 3 then return 1 end
    if colorType == 4 then return 2 end
    if colorType == 6 then return 4 end
    error('Invalid colortype')
end

local function paethPredict(a, b, c)
    local p = a + b - c
    local varA = math.abs(p - a)
    local varB = math.abs(p - b)
    local varC = math.abs(p - c)

    if varA <= varB and varA <= varC then 
        return a 
    elseif varB <= varC then 
        return b 
    else
        return c
    end
end

local prevPixelRow = {}
local function getPixelRow(stream, depth, colorType, palette, length)
    local pixelRow = {}
    local bpp = math.floor(depth/8) * bitFromColorType(colorType)
    local filterType = readByte(stream)

    if filterType == 0 then
        for x = 1, length do
            pixelRow[x] = makePixel(stream, depth, colorType, palette)
        end
    elseif filterType == 1 then
        local curPixel
        local lastPixel
        local newPixel
        for x = 1, length do
            curPixel = makePixel(stream, depth, colorType, palette)
            lastPixel = prevPixelRow[x]
            newPixel = {}
            for fieldName, curByte in pairs(curPixel) do
                local lastByte = lastPixel and lastPixel[fieldName] or 0
                newPixel[fieldName] = (curByte + lastByte) % 256
            end
            pixelRow[x] = newPixel
        end
    else
        error("Unsupported filter type: " .. tostring(filterType))
    end
    prevPixelRow = pixelRow

    return pixelRow
end

local function pngImage(path, progCallback, verbose, memSave, palette_only)
    local file = love.filesystem.newFile(path)
    local success = file:open("r")
    if not success then
        error("Unable to open file: " .. path)
    end

    local function printV(msg)
        if (verbose) then
            print(msg)
        end
    end

    local signature = file:read(8)
    if signature ~= "\137\080\078\071\013\010\026\010" then
        file:close()
        error("Not a png")
    end

    printV("Parsing Chunks...")
    local chunkData = extractChunkData(file)

    local width = chunkData.IHDR.width
    local height = chunkData.IHDR.height
    local depth = chunkData.IHDR.bitDepth
    local colorType = chunkData.IHDR.colorType
	
	if not palette_only then
		printV("Deflating...")
		local output = {}
		deflate.inflate_zlib {
			input = chunkData.IDAT.data,
			output = function(byte)
				output[#output + 1] = string.char(byte)
			end,
			disable_crc = true
		}
		file:close()

		local dataString = table.concat(output)
		local StringStream = {
			str = dataString,
			read = function(self, num)
				local toreturn = self.str:sub(1, num)
				self.str = self.str:sub(num + 1)
				return toreturn
			end
		}

		printV("Creating pixelmap...")
		local pixels = {}

		for i = 1, height do
			local pixelRow = getPixelRow(StringStream, depth, colorType, chunkData.PLTE, width)
			if progCallback ~= nil then
            	progCallback(i, height, pixelRow)
			end
			if not memSave then
				pixels[i] = pixelRow
			end
		end
	end

    local palette = {}
	
    for _, color in ipairs(chunkData.PLTE.colors) do
        if color.A <= 0.01 then
            goto continue
        end
		
		local color = Color(color.R / 255, color.G / 255, color.B / 255, 1)
        table.insert(palette, color)
		
		::continue::
	end

    printV("Done.")
    return {
        width = width,
        height = height,
        depth = depth,
        colorType = colorType,
        pixels = pixels,
		palette = palette
    }
end

return pngImage
