-- =============================================================================
-- 1. USER CONFIGURATION LOADER
-- =============================================================================
local default_prefs = {
  theme = "gruvbox",
  background = "dark",
  node_path_windows = nil,
  enable_copilot = true,
  enable_neo_tree_on_startup = true
}

local config_status, user_prefs = pcall(require, "user_settings")
-- Merges user_prefs on top of defaults. usage: vim.tbl_deep_extend("force", defaults, user_overrides)
local prefs = vim.tbl_deep_extend("force", default_prefs, config_status and user_prefs or {})

-- =============================================================================
-- 2. CROSS-PLATFORM LOGIC
-- =============================================================================
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local path_sep = is_windows and "\\" or "/"

local shell_cmd
if is_windows then
  shell_cmd = 'powershell.exe -NoLogo -ExecutionPolicy Bypass'
else
  if vim.fn.executable('pwsh') == 1 then
    shell_cmd = 'pwsh -NoLogo -ExecutionPolicy Bypass'
  else
    shell_cmd = 'bash'
  end
end

local node_cmd = "node"
if is_windows then
  if prefs.node_path_windows and vim.fn.filereadable(prefs.node_path_windows) == 1 then
    node_cmd = prefs.node_path_windows
  else
    local win_node = "C:\\Program Files\\nodejs\\node.exe"
    if vim.fn.filereadable(win_node) == 1 then
      node_cmd = win_node
    end
  end
end

-- =============================================================================
-- 3. BOOTSTRAP LAZY.NVIM
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- 4. CORE SETTINGS
-- =============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.scrolloff = 999
vim.opt.timeoutlen = 300
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.iskeyword:append("-") -- Treat dash as part of a word (for PowerShell cmdlets)
vim.opt.cursorcolumn = false
vim.opt.list = false

-- Native Highlight Yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

vim.keymap.set("n", "<leader>zz", function()
  if vim.opt.scrolloff:get() == 999 then
    vim.opt.scrolloff = 8
    print("Scrolling: Standard (8 lines)")
  else
    vim.opt.scrolloff = 999
    print("Scrolling: Centered (Typewriter)")
  end
end, { desc = "Toggle Centered Scroll" })

vim.api.nvim_create_user_command('D2Watch', function()
  local file = vim.fn.expand('%:p')
  if vim.fn.expand('%:e') ~= 'd2' then
    print("Not a .d2 file")
    return
  end

  print("Starting D2 Watcher for " .. vim.fn.expand('%:t') .. "...")
  
  local cmd = string.format("Start-Process -FilePath 'd2' -ArgumentList '--watch', '%s', '--browser', '1' -WindowStyle Hidden", file)
  
  vim.fn.jobstart({"powershell", "-c", cmd}, {
    on_exit = function(_, code)
      if code ~= 0 then
        print("D2 Watcher failed to start.")
      end
    end
  })
end, {})

-- =============================================================================
-- 5. PLUGINS
-- =============================================================================
require("lazy").setup({

  { "nvim-lua/plenary.nvim" },

  -- Fuzzy Finder (New Feature: Telescope)
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = { file_ignore_patterns = { "node_modules", ".git" } }
      })
    end
  },

  -- Keybinding Helper
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {}
  },

  -- Diagnostic Viewer
{
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
    },
    opts = {
    focus = true,
    },
},
  -- TODO Comments
{
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
        { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },

  -- D2 Diagramming Language Support
  {
  "terrastruct/d2-vim",
  ft = "d2",
  config = function()
    vim.g.d2_fmt_autosave = 1
  end,
   },

  -- Git Management
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.g.lazygit_floating_window_winblend = 0
      vim.g.lazygit_use_neovim_remote = 1
    end,
  },

  -- Harpoon (File Navigation)
{
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      -- Keymaps
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon Add" })
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Menu" })

      -- Fast Navigation
      vim.keymap.set("n", "<C-1>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-2>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-3>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-4>", function() harpoon:list():select(4) end)
    end,
  },

  -- Git Signs
  { "lewis6991/gitsigns.nvim", config = true },

  -- Terminal (ToggleTerm)
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        direction = 'float',
        shell = shell_cmd,
        float_opts = { border = 'curved' }
      })
    end
  },

--  UI & Themes 
  {
    "ellisonleao/gruvbox.nvim",
    -- If prefs.theme is somehow nil, this ensures it doesn't accidentally lazy load without a trigger
    lazy = (prefs.theme ~= "gruvbox"),
    priority = 1000,
    config = function()
      -- Set background BEFORE loading the scheme to prevent reset flashes
      vim.o.background = prefs.background
      vim.cmd("colorscheme gruvbox")
    end
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      vim.api.nvim_set_hl(0, "IblIndent", { fg = "#504945" }) 

      require("ibl").setup({
        indent = { 
          char = "│", 
          highlight = "IblIndent",
        },
        
        scope = { enabled = false },
      })
    end,
  },

  -- File Explorer (Neo-tree)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      require("neo-tree").setup({
          enable_diagnostics = false,
          close_if_last_window = true,
          filesystem = {
              hijack_netrw_behavior = "open_default",
              follow_current_file = { enabled = true },
              use_libuv_file_watcher = true,
          },
          window = { position = "right", width = 40 }
      })
    end
  },

  --  finally replaced Airline. Lualine is written in Lua, faster, and easier to configure.
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = { theme = 'gruvbox' }
      })
    end
  },

  --  Coding & Automation 
  { "jiangmiao/auto-pairs" },
  { "preservim/nerdcommenter" },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      -- Windows optimization for compilers
      require("nvim-treesitter.install").compilers = { "zig", "gcc" }
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.d2 = {
        install_info = {
          url = "https://github.com/ravsii/tree-sitter-d2", -- The repo with the grammar
          files = { "src/parser.c" },
          branch = "main",
        },
        filetype = "d2",
      }
      require("nvim-treesitter.configs").setup({
      ensure_installed = { "powershell", "lua", "python", "c_sharp", "go", "markdown", "json", "yaml", "bash"},
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

-- LSP & Mason 
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason").setup()
      local mason_lsp = require("mason-lspconfig")
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      local on_attach = function(client, bufnr)
        client.server_capabilities.semanticTokensProvider = nil
      end

      mason_lsp.setup({
        ensure_installed = { "powershell_es", "lua_ls", "omnisharp"},
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
                capabilities = capabilities,
                on_attach = on_attach
            })
          end,

["powershell_es"] = function()
            require("lspconfig").powershell_es.setup({
              bundle_path = vim.fn.stdpath("data") .. "/mason/packages/powershell-editor-services",
              
              settings = {
                powershell = {
                  codeFormatting = { preset = "OTBS" },
                  enableProfileLoading = false,
                  scriptAnalysis = {
                    enable = true,
                  },
                },
              },
	      capabilities = capabilities,
              on_attach = on_attach
            })
          end,

          -- C# Config
          ["omnisharp"] = function()
             require("lspconfig").omnisharp.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                cmd = { vim.fn.stdpath("data") .. "/mason/bin/omnisharp" },
                enable_roslyn_analyzers = true,
                organize_imports_on_format = true,
             })
          end,

          -- Lua Config
          ["lua_ls"] = function()
             require("lspconfig").lua_ls.setup({
                capabilities = capabilities,
                on_attach = on_attach,
                settings = {
                  Lua = {
                    diagnostics = { globals = { "vim" } },
                    workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                    telemetry = { enable = false },
                  },
                },
             })
          end,
        }
      })
    end
  },

  -- Completion (CMP)
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<Tab>'] = cmp.mapping.select_next_item(),
          ['<S-Tab>'] = cmp.mapping.select_prev_item(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' }
        })
      })
    end
  },

  -- Copilot 
  {
    "zbirenbaum/copilot.lua",
    cond = prefs.enable_copilot,
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
    require("copilot").setup({
    filetypes = {
          gitcommit = true,
          markdown = true,
          yaml = false,
    },
        copilot_node_command = node_cmd,
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<M-l>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
      })
    end,
  },

{
  "3rd/image.nvim",
  build = false, -- CRITICAL: This stops it from trying to compile with your system Lua
  dependencies = {
    {
      "kiyoon/magick.nvim",
      build = false -- Disable build here too just to be safe
    }
  },
  config = function()
    require("image").setup({
      backend = "kitty", -- Change this if you aren't using WezTerm/Kitty
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_width = 100,
      max_height = 12,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = false, 
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = true,
    })
  end
},

-- Copilot Chat
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    cond = prefs.enable_copilot,
    branch = "main",
    dependencies = { "zbirenbaum/copilot.lua", "nvim-lua/plenary.nvim" },
    opts = { debug = false, window = { layout = 'float' } },
    keys = {
      { "<leader>lc", "<cmd>CopilotChatToggle<cr>", mode = { "n"}, desc = "Copilot Chat" },
      { "<leader>le", "<cmd>CopilotChatExplain<cr>", mode = { "n", "v" }, desc = "Copilot Explain" },
      { "<leader>lf", "<cmd>CopilotChatFix<cr>", mode = { "n", "v" }, desc = "Copilot Fix" },
      { "<leader>lr", "<cmd>CopilotChatReview<cr>", mode = { "n", "v" }, desc = "Copilot Review" },
      { "<leader>lm", "<cmd>CopilotChatCommit<cr>", desc = "Copilot Generate Commit Message" },
    },
    },
    })
-- =============================================================================
-- 6. KEYMAPS (Enhanced)
-- =============================================================================
-- General
vim.keymap.set("i", "jj", "<Esc>", { noremap = true })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save" })
vim.keymap.set("n", "<leader>h", ":noh<CR>", { desc = "Clear Highlights" })

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Grep Text" })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find Buffers" })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Help Tags" })

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })

-- Window Movement
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Window Left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Window Down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Window Up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Window Right' })

-- Neo-tree
vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { silent = true, desc = "Toggle Explorer" })
vim.keymap.set('n', '<leader>e', ':Neotree focus<CR>', { silent = true, desc = "Focus Explorer" })

-- ToggleTerm
vim.keymap.set('n', '<F7>', '<cmd>ToggleTerm<cr>', { noremap = true, silent = true, desc = "Toggle Terminal" })
vim.keymap.set('t', '<F7>', '<cmd>ToggleTerm<cr>', { noremap = true, silent = true })

-- LSP
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Def" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Doc" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Diagnostics Navigation
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })

-- Cheat.sh Query
vim.keymap.set("n", "<leader>?", function()
  vim.ui.input({ prompt = "Cheat.sh Query: " }, function(input)
    if input and input ~= "" then
      vim.cmd("Cheat " .. input)
    end
  end)
end, { desc = "Query Cheat.sh" })

-- =============================================================================
-- 7. AUTOCOMMANDS
-- =============================================================================
if prefs.enable_neo_tree_on_startup then
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.cmd("Neotree show")
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})

-- =============================================================================
-- 8. CUSTOM COMMANDS
-- =============================================================================

-- Cheat.sh Command
vim.api.nvim_create_user_command("Cheat", function(opts)
  local query = opts.args:gsub(" ", "+")
  local cmd = string.format("powershell.exe -NoProfile -Command Invoke-RestMethod -Uri 'https://cheat.sh/%s?T'", query)
  local output = vim.fn.systemlist(cmd)

  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  vim.opt_local.buftype = "nofile"
  vim.opt_local.bufhidden = "wipe"
  vim.opt_local.swapfile = false
  vim.opt_local.filetype = "sh"
end, { nargs = "+" })

-- Cheat.sh Help Command
vim.api.nvim_create_user_command("CheatHelp", function()
  local help_text = {
    "Cheat.sh Cheatsheet",
    "===================",
    "Shortcuts:",
    "<leader>? - Prompt for a cheat.sh query",
    "",
    "Usage Examples:",
    "  :Cheat powershell/try catch",
    "  :Cheat python/reverse list",
    "  :Cheat lua/table size",
    "  :Cheat git/commit",
    "  :Cheat docker/run",
    "",
    "Press <q> or <Esc> to close"
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_text)

  local width = 40
  local height = #help_text
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded"
  })

  local close_win = function() vim.api.nvim_win_close(win, true) end
  vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })

end, {})
