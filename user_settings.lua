-- user_settings.lua
-- This file contains user-specific overrides.
-- If this file is missing, init.lua uses built-in defaults.

local M = {}

-- Visual preferences
M.theme = "gruvbox" -- Options: gruvbox, tokyonight, catppuccin, etc.
M.background = "dark"
M.transparent_bg = false

-- Hardcoded paths (Optional overrides)
-- Set to nil to let the system auto-detect
M.node_path_windows = "C:\\Program Files\\nodejs\\node.exe" 

-- Feature flags
M.enable_neo_tree_on_startup = true

-- AI Configuration
M.gemini_api_key = "AIzaSyAsYwlV6CBEYnHAImNpfgTLDKSCs_ShJWI"

return M
