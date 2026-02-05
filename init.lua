-- =============================================================================
-- 1. USER CONFIGURATION LOADER
-- =============================================================================
local default_prefs = {
  theme = "gruvbox",
  background = "dark",
  node_path_windows = nil,
  enable_neo_tree_on_startup = true
}

local config_status, user_prefs = pcall(require, "user_settings")
local prefs = vim.tbl_deep_extend("force", default_prefs, config_status and user_prefs or {})

-- =============================================================================
-- 2. CROSS-PLATFORM LOGIC
-- =============================================================================
local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

local shell_cmd
if is_windows then
  vim.opt.lazyredraw = true
  shell_cmd = 'powershell.exe -NoLogo -ExecutionPolicy Bypass'
  vim.opt.shell = "powershell.exe"
  vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy Bypass -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
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
vim.opt.scrolloff = 4
vim.opt.timeoutlen = 300
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 100
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

-- =============================================================================
-- 5. PLUGINS
-- =============================================================================
require("lazy").setup({

  rocks = { enabled = false, hererocks = false },

  { "nvim-lua/plenary.nvim" },

  -- Fuzzy Finder (Telescope)
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

  -- Mermaid Diagrams
  {
    "snrogers/mermaider.nvim",
    dependencies = { "3rd/image.nvim" },
    config = function()
      require("mermaider").setup({})
    end,
    ft = { "mmd", "mermaid" },
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
    opts = { focus = true },
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
      "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile",
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

  -- UI & Themes
  {
    "ellisonleao/gruvbox.nvim",
    lazy = (prefs.theme ~= "gruvbox"),
    priority = 1000,
    config = function()
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
        indent = { char = "│", highlight = "IblIndent" },
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

  -- Status Line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = { theme = 'gruvbox' }
      })
    end
  },

  -- Coding & Automation
  { "jiangmiao/auto-pairs" },
  { "preservim/nerdcommenter" },

  -- Copilot (Ghost Text ENABLED)
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        copilot_node_command = node_cmd,
        panel = { enabled = false },
        suggestion = {
          enabled = true,
          auto_trigger = true, -- RESTORED: Ghost text enabled by default
          keymap = {
            accept = "<M-l>",
            next = "<M-j>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
      })
    end,
  },

  -- UI Input/Select (Dressing) - Required for Avante inputs
  { "stevearc/dressing.nvim", opts = {} },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.install").compilers = { "zig", "gcc" }
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.d2 = {
        install_info = {
          url = "https://github.com/ravsii/tree-sitter-d2",
          files = { "src/parser.c" },
          branch = "main",
        },
        filetype = "d2",
      }
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "powershell", "lua", "python", "c_sharp", "go", "markdown", "markdown_inline", "json", "yaml", "bash" },
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
        ensure_installed = { "powershell_es", "lua_ls", "omnisharp" },
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
                  scriptAnalysis = { enable = true },
                },
              },
              capabilities = capabilities,
              on_attach = on_attach
            })
          end,

          ["omnisharp"] = function()
            require("lspconfig").omnisharp.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              cmd = { vim.fn.stdpath("data") .. "/mason/bin/omnisharp" },
              enable_roslyn_analyzers = true,
              organize_imports_on_format = true,
            })
          end,

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

  -- AVANTE AI CONFIGURATION (STRICTLY MANUAL APPLY)
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false",
    dependencies = {
      "stevearc/dressing.nvim",
      { "nvim-lua/plenary.nvim" },
      { "MunifTanjim/nui.nvim" },
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
    opts = {
      provider = "copilot",
      behaviour = {
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
      },
      mappings = {
        edit = "<nop>",
        ask = "<leader>aa",
        refresh = "<leader>ar",
        sidebar = {
          apply_one = "<leader>ap",
          apply_all = "<leader>aa",
          switch_windows = "<Tab>",
          reverse_switch_windows = "<S-Tab>",
        },
        suggestion = {
            accept = "<M-l>",
            next = "<M-j>",
            prev = "<M-k>",
            dismiss = "<C-]>",
        },
      },
      windows = {
        position = "right",
        width = 30,
        sidebar_header = { align = "center", rounded = true },
      },
    },
  },
})

-- =============================================================================
-- 6. KEYMAPS (Enhanced)
-- =============================================================================
vim.keymap.set("i", "jj", "<Esc>", { noremap = true })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save" })
vim.keymap.set("n", "<leader>h", ":noh<CR>", { desc = "Clear Highlights" })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Grep Text" })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find Buffers" })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = "Help Tags" })
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Window Left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Window Down' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Window Up' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Window Right' })

vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { silent = true, desc = "Toggle Explorer" })
vim.keymap.set('n', '<leader>e', ':Neotree focus<CR>', { silent = true, desc = "Focus Explorer" })
vim.keymap.set("n", "<leader>n", ":Neotree toggle<CR>", { silent = true, desc = "Toggle Explorer (Leader)" })

vim.keymap.set('n', '<F7>', '<cmd>ToggleTerm<cr>', { noremap = true, silent = true, desc = "Toggle Terminal" })
vim.keymap.set('t', '<F7>', '<cmd>ToggleTerm<cr>', { noremap = true, silent = true })

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to Def" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Doc" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })

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
