local tohex, bor, lshift, rshift, band = bit.tohex, bit.bor, bit.lshift, bit.rshift, bit.band
local validate, api = vim.validate, vim.api

local lazy = require("flutter-tools.lazy")
local ui = lazy.require("flutter-tools.ui") ---@module "flutter-tools.ui"
local config = lazy.require("flutter-tools.config") ---@module "flutter-tools.config"
local utils = lazy.require("flutter-tools.utils") ---@module "flutter-tools.utils"

local M = {}

local CLIENT_NS = api.nvim_create_namespace("flutter_tools_lsp_document_color")

---@alias RGBA {r: integer, g: integer, b:integer, a: number}  with keys 'r', 'g', 'b' in [0,255] and key 'a' in [0,1]
---@alias RGB {r: integer, g: integer, b:integer} with keys 'r', 'g', 'b' in in [0,255] to use as the background color when applying the alpha
---@alias RangePos {line: number, character: number}

---@param prefix string
---@param opts {foreground: number | string, background: number | string}
---@return string
local function create_set_hl(prefix, opts)
  local hlname = prefix .. (opts.background or "") .. (opts.foreground or "")
  api.nvim_set_hl(0, hlname, {
    background = opts.background and "#" .. opts.background or nil,
    foreground = opts.foreground and "#" .. opts.foreground or nil,
  })
  return hlname
end

--- Returns a table containing the RGB values produced by applying the alpha in rgba with the background in bg_rgb.
---@param rgba RGBA
---@param bg_rgb RGB
---@return RGB rgb_table
--- FIXME: this currently does not support transparent backgrounds. Need a replacement for bg_rgb
function M.rgba_to_rgb(rgba, bg_rgb)
  validate({
    rgba = { rgba, "t", true },
    bg_rgb = { bg_rgb, "t", false },
    r = { rgba.r, "n", true },
    g = { rgba.g, "n", true },
    b = { rgba.b, "n", true },
    a = { rgba.a, "n", true },
  })

  validate({
    bg_r = { bg_rgb.r, "n", true },
    bg_g = { bg_rgb.g, "n", true },
    bg_b = { bg_rgb.b, "n", true },
  })

  local r = rgba.r * rgba.a + bg_rgb.r * (1 - rgba.a)
  local g = rgba.g * rgba.a + bg_rgb.g * (1 - rgba.a)
  local b = rgba.b * rgba.a + bg_rgb.b * (1 - rgba.a)

  return { r = r, g = g, b = b }
end

--- Returns a string containing the 6 digit hex value for a given RGB.
---@param rgb RGB with keys 'r', 'g', 'b' in [0,255]
---@return number 6 digit hex representing the rgb params
local function rgb_to_hex(rgb)
  validate({
    r = { rgb.r, "n", false },
    g = { rgb.g, "n", false },
    b = { rgb.b, "n", false },
  })
  return tohex(bor(lshift(rgb.r, 16), lshift(rgb.g, 8), rgb.b), 6)
end

--- Returns a string containing the 6 digit hex value produced by applying the alpha in
--- the @rgba with the background @bg_rgb.
---
---@param rgba RGBA
---@return number 6 digit hex
function M.rgba_to_hex(rgba, bg_rgb) return rgb_to_hex(M.rgba_to_rgb(rgba, bg_rgb)) end

--- Returns a table containing the RGB values encoded inside 24 least
--- significant bits of the number rgb_24bit
---@param rgb_24bit number 24-bit RGB value
---@return RGB
function M.decode_24bit_rgb(rgb_24bit)
  validate({ rgb_24bit = { rgb_24bit, "n", true } })
  local r = band(rshift(rgb_24bit, 16), 255)
  local g = band(rshift(rgb_24bit, 8), 255)
  local b = band(rgb_24bit, 255)
  return { r = r, g = g, b = b }
end

--- Returns the perceived lightness of the rgb value. Calculated using
--- the formula from https://stackoverflow.com/a/56678483. Can be used to
--- determine which colors have similar lightness.
---@param rgb RGB
---@return number lightness in the range [0,100]
function M.perceived_lightness(rgb)
  local function gamma_encode(v) return v / 255 end

  local function linearize(v)
    return v <= 0.04045 and v / 12.92 or math.pow((v + 0.055) / 1.055, 2.4)
  end

  -- convert from sRGB to linear values
  local r = linearize(gamma_encode(rgb.r))
  local g = linearize(gamma_encode(rgb.g))
  local b = linearize(gamma_encode(rgb.b))

  -- calculate luminance
  local L = 0.2126 * r + 0.7152 * g + 0.0722 * b

  -- calculate Y* (perceived lightness) from luminance
  return L <= (216 / 24389) and L * (24389 / 27) or math.pow(L, 1 / 3) * 116 - 16
end

---@param bufnr number
---@param namespace number
---@param hlname string
---@param start_pos number
---@param end_pos number
local function hl_range(bufnr, namespace, hlname, start_pos, end_pos)
  local hl = vim.highlight
  hl.range(bufnr, namespace, hlname, start_pos, end_pos, { priority = hl.priorities.user })
end

--- Changes the guibg to @rgb for the text in @range. Also changes the guifg to
--- either #ffffff or #000000 based on which makes the text easier to read for
--- the given guibg
---@param _ number client id
---@param bufnr number buffer handle
---@param range {start: RangePos, end: {line: number, character: number}}
---@param rgb RGB
local function color_background(_, bufnr, range, rgb)
  local hex = rgb_to_hex(rgb)
  local fghex = M.perceived_lightness(rgb) < 50 and "ffffff" or "000000"

  local hlname = create_set_hl("LspDocumentColorBackground", {
    background = hex,
    foreground = fghex,
  })
  local start_pos = { range["start"]["line"], range["start"]["character"] }
  local end_pos = { range["end"]["line"], range["end"]["character"] }
  hl_range(bufnr, CLIENT_NS, hlname, start_pos, end_pos)
end

--- Changes the guifg to @rgb for the text in @range.
---
---@param _ number client id
---@param bufnr number buffer handle
---@param range table with the structure: {start={line=<number>,character=<number>}, end={line=<number>,character=<number>}}
---@param rgb RGB
local function color_foreground(_, bufnr, range, rgb)
  local hex = rgb_to_hex(rgb)
  local hlname = create_set_hl("LspDocumentColorForeground", { foreground = hex })
  local start_pos = { range["start"]["line"], range["start"]["character"] }
  local end_pos = { range["end"]["line"], range["end"]["character"] }
  hl_range(bufnr, CLIENT_NS, hlname, start_pos, end_pos)
end

--- Adds virtual text with the color @rgb and the text virtual_text_str on  the last line of the @range.
---@param _ number client id
---@param bufnr number buffer handle
---@param range {start: RangePos, end: RangePos}
---@param rgb RGB
---@param virtual_text_str string to display as virtual text and color
local function color_virtual_text(_, bufnr, range, rgb, virtual_text_str)
  local hex = rgb_to_hex(rgb)
  local hlname = create_set_hl("LspDocumentColorVirtualText", { foreground = hex })
  local line = range["end"]["line"]
  if line <= api.nvim_buf_line_count(0) then
    api.nvim_buf_set_extmark(bufnr, CLIENT_NS, line, -1, {
      virt_text = { { virtual_text_str, hlname } },
    })
  end
end

--- Clears the previous document colors and adds the new document colors from @result.
--- Follows the same signature as :h lsp-handler
function M.on_document_color(err, result, ctx, conf)
  local client_id = ctx.client_id
  local bufnr = ctx.bufnr
  if err then return ui.notify(err, ui.ERROR) end
  if not bufnr or not client_id then return end
  M.buf_clear_color(client_id, bufnr)
  if not result then return end
  M.buf_color(client_id, bufnr, result, conf)
end

local function get_background_color()
  local normal_bg = utils.get_hl("Normal", "bg")
  if not normal_bg then return end
  return M.decode_24bit_rgb(normal_bg)
end

--- Shows a list of document colors for a certain buffer.
---
---@param client_id number client id
---@param bufnr number buffer id
---@param color_infos table of `ColorInformation` objects to highlight.
-- See https://microsoft.github.io/language-server-protocol/specification#textDocument_documentColor
function M.buf_color(client_id, bufnr, color_infos, _)
  validate({ bufnr = { bufnr, "n", false }, color_infos = { color_infos, "t", false } })
  if not color_infos or not bufnr then return end
  local c = config.lsp.color

  local background_color = c.background_color or get_background_color()
  -- FIXME: currently background_color is required to derive the rgb values for the colors
  -- till there is a good solution for this transparent backgrounds won't work with lsp colors
  if not background_color then return end

  for _, color_info in ipairs(color_infos) do
    local rgba, range = color_info.color, color_info.range
    local r, g, b, a = rgba.red * 255, rgba.green * 255, rgba.blue * 255, rgba.alpha
    local rgb = M.rgba_to_rgb({ r = r, g = g, b = b, a = a }, background_color)
    if c.background then color_background(client_id, bufnr, range, rgb) end
    if c.foreground then color_foreground(client_id, bufnr, range, rgb) end
    if c.virtual_text then color_virtual_text(client_id, bufnr, range, rgb, c.virtual_text_str) end
  end
end

---Removes document color highlights from a buffer.
---@param client_id number client id
---@param bufnr number buffer id
function M.buf_clear_color(client_id, bufnr)
  validate({ client_id = { client_id, "n", true }, bufnr = { bufnr, "n", true } })
  if api.nvim_buf_is_valid(bufnr) then api.nvim_buf_clear_namespace(bufnr, CLIENT_NS, 0, -1) end
end

return M
