--[[
  skills.lua: turns  [Name]{.skill level=3 logo=r note="extra text"}  into a skill row
  with a monochrome logo and a 5-step level meter.

  level  1–5   (1 Basic · 2 Familiar · 3 Proficient · 4 Advanced · 5 Expert)
  logo   file name (without .svg) in images/logos/  e.g. logo=python
  icon   Bootstrap icon name instead of a logo       e.g. icon=microscope
  note   optional small grey text under the name
  If neither logo nor icon is given (or the logo file is missing), a monogram is shown.
]]

local LABELS = { "Basic", "Familiar", "Proficient", "Advanced", "Expert" }

local function project_dir()
  if quarto and quarto.project and quarto.project.directory then
    return quarto.project.directory
  end
  return "."
end

local svg_cache = {}
local function read_logo(name)
  if svg_cache[name] ~= nil then return svg_cache[name] end
  local path = project_dir() .. "/images/logos/" .. name .. ".svg"
  local f = io.open(path, "r")
  if not f then
    svg_cache[name] = false
    return false
  end
  local svg = f:read("a")
  f:close()
  svg = svg:gsub("<title>.-</title>", "")
  svg = svg:gsub("<svg ", '<svg aria-hidden="true" focusable="false" ', 1)
  svg_cache[name] = svg
  return svg
end

local function esc(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function monogram(name)
  local letters = {}
  for word in name:gmatch("[%w]+") do
    letters[#letters + 1] = word:sub(1, 1):upper()
    if #letters == 2 then break end
  end
  if #letters == 1 and #name > 1 then letters[2] = name:sub(2, 2):lower() end
  return table.concat(letters)
end

function Span(el)
  if not el.classes:includes("skill") then return nil end
  if not quarto.doc.is_format("html") then return nil end

  local name = pandoc.utils.stringify(el.content)
  local level = tonumber(el.attributes["level"] or "0") or 0
  level = math.max(0, math.min(5, math.floor(level)))
  local note = el.attributes["note"]

  local mark
  local logo = el.attributes["logo"]
  local icon = el.attributes["icon"]
  local svg = logo and read_logo(logo)
  if svg then
    mark = '<span class="hv-skill-mark logo">' .. svg .. "</span>"
  elseif icon then
    mark = '<span class="hv-skill-mark"><i class="bi bi-' .. esc(icon) .. '"></i></span>'
  else
    mark = '<span class="hv-skill-mark mono">' .. esc(monogram(name)) .. "</span>"
  end

  local meter = ""
  if level > 0 then
    local cells = {}
    for i = 1, 5 do
      cells[#cells + 1] = (i <= level) and '<i class="on"></i>' or "<i></i>"
    end
    meter = '<span class="hv-meter" role="img" aria-label="' .. LABELS[level] .. ', level ' .. level
      .. ' of 5" title="' .. LABELS[level] .. '">' .. table.concat(cells) .. "</span>"
      .. '<span class="hv-level">' .. LABELS[level] .. "</span>"
  end

  local html = '<span class="hv-skill">' .. mark
    .. '<span class="hv-skill-text"><span class="hv-skill-name">' .. esc(name) .. "</span>"
    .. (note and ('<span class="hv-skill-note">' .. esc(note) .. "</span>") or "")
    .. "</span>" .. meter .. "</span>"
  return pandoc.RawInline("html", html)
end
