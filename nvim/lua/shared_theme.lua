local M = {}

local default_theme = "gruvbox_material"
local module_path = debug.getinfo(1, "S").source

local function trim(value)
  return (value or ""):match("^%s*(.-)%s*$")
end

local function infer_dotfiles_root()
  if type(module_path) ~= "string" or module_path:sub(1, 1) ~= "@" then
    return nil
  end

  local path = module_path:sub(2)
  local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(path)))

  if root == "." or root == "" then
    return nil
  end

  return root
end

local function dotfiles_root()
  if vim.env.DOTFILES_ROOT and vim.env.DOTFILES_ROOT ~= "" then
    return vim.env.DOTFILES_ROOT
  end

  return infer_dotfiles_root() or (vim.env.HOME .. "/.dotfiles")
end

local function read_first_line(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local line = file:read("*l")
  file:close()
  return trim(line)
end

local function supported_theme(theme)
  if theme == "" then
    return false
  end

  local file = io.open(dotfiles_root() .. "/themes/supported-themes", "r")
  if not file then
    return false
  end

  for line in file:lines() do
    if theme == trim(line) then
      file:close()
      return true
    end
  end

  file:close()
  return false
end

function M.theme_name()
  local theme = read_first_line(dotfiles_root() .. "/themes/current-theme") or ""
  if supported_theme(theme) then
    return theme
  end

  return default_theme
end

return M
