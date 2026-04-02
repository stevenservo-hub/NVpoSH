-- =============================================================================
-- 1. USER CONFIGURATION LOADER
-- =============================================================================
local default_prefs = {
  theme = "gruvbox",
  background = "dark",
  node_path_windows = nil,
  enable_neo_tree_on_startup = false,
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
  shell_cmd = "powershell.exe -NoLogo -ExecutionPolicy Bypass"
  vim.opt.shell = "powershell.exe"
  vim.opt.shellcmdflag = "-NoLogo -ExecutionPolicy Bypass -Command"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
else
  if vim.fn.executable("pwsh") == 1 then
    shell_cmd = "pwsh -NoLogo -ExecutionPolicy Bypass"
  else
    shell_cmd = "bash"
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
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
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
vim.opt.iskeyword:append("-")
vim.opt.cursorcolumn = false
vim.opt.list = false
vim.opt.clipboard = "unnamedplus"

pcall(function()
  vim.loader.enable()
end)

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

vim.keymap.set("n", "zz", function()
  if vim.opt.scrolloff:get() == 999 then
    vim.opt.scrolloff = 8
    print("Scrolling: Standard (8 lines)")
  else
    vim.opt.scrolloff = 999
    print("Scrolling: Centered (Typewriter)")
  end
end, { desc = "Toggle Centered Scroll" })

-- Block visual mode for Windows terminals
vim.keymap.set("n", "<C-q>", "<C-v>", { noremap = true, silent = true, desc = "Block Visual Mode" })

-- Hard-disable legacy auto-pairs behavior if somehow present
vim.g.AutoPairsLoaded = 1
vim.g.loaded_auto_pairs = 1

-- =============================================================================
-- 5. PLUGINS
-- =============================================================================
require("lazy").setup({
  rocks = { enabled = false, hererocks = false },

  -- Explicitly disable legacy auto-pairs if it exists anywhere
  { "jiangmiao/auto-pairs", enabled = false },

  { "nvim-lua/plenary.nvim", lazy = true },

  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = prefs.background
      vim.cmd("colorscheme gruvbox")
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end, desc = "Grep Text" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end, desc = "Find Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end, desc = "Help Tags" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      defaults = {
        file_ignore_patterns = { "node_modules", ".git" },
      },
    },
  },

  {
    "snrogers/mermaider.nvim",
    ft = { "mmd", "mermaid" },
    dependencies = { "3rd/image.nvim" },
    config = function()
      require("mermaider").setup({})
    end,
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { focus = true },
  },

  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },

  {
    "terrastruct/d2-vim",
    ft = "d2",
    config = function()
      vim.g.d2_fmt_autosave = 1
    end,
  },

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

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    keys = {
      { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon Add" },
      { "<leader>hm", function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end, desc = "Harpoon Menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal" },
    },
    config = function()
      require("toggleterm").setup({
        size = 20,
        hide_numbers = true,
        direction = "float",
        shell = shell_cmd,
        float_opts = { border = "curved" },
      })
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPre", "BufNewFile" },
    main = "ibl",
    config = function()
      vim.api.nvim_set_hl(0, "IblIndent", { fg = "#504945" })
      require("ibl").setup({
        indent = { char = "│", highlight = "IblIndent" },
        scope = { enabled = false },
      })
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    keys = {
      { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
      { "<leader>e", "<cmd>Neotree focus<cr>", desc = "Focus Explorer" },
    },
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
          use_libuv_file_watcher = false,
        },
        window = { position = "right", width = 40 },
      })
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "gruvbox" },
      })
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup({
        check_ts = false,
        disable_filetype = { "TelescopePrompt", "vim", "Avante" },
        fast_wrap = {},
      })

      local ok_cmp, cmp = pcall(require, "cmp")
      if ok_cmp then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },

  {
    "preservim/nerdcommenter",
    keys = {
      { "<leader>/", "<Plug>NERDCommenterToggle", desc = "Toggle Comment", mode = { "n", "v" } },
    },
  },

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
          auto_trigger = true,
        },
      })
    end,
  },

  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
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
        ensure_installed = {
          "powershell",
          "lua",
          "python",
          "c_sharp",
          "go",
          "markdown",
          "markdown_inline",
          "json",
          "yaml",
          "bash",
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()

      local mason_lsp = require("mason-lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(client, _)
        client.server_capabilities.semanticTokensProvider = nil
      end

      mason_lsp.setup({
        ensure_installed = { "powershell_es", "lua_ls", "omnisharp" },
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
              on_attach = on_attach,
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
              on_attach = on_attach,
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
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
  },

  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
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
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  {
    "yetone/avante.nvim",
    cmd = {
      "AvanteAsk",
      "AvanteBuild",
      "AvanteChat",
      "AvanteEdit",
      "AvanteFocus",
      "AvanteRefresh",
      "AvanteShowRepoMap",
      "AvanteSwitchProvider",
      "AvanteToggle",
      "AvanteClear",
    },
    keys = {
      { "<leader>aa", "<cmd>AvanteAsk<cr>", desc = "Avante Ask" },
      { "<leader>ae", "<cmd>AvanteEdit<cr>", desc = "Avante Edit" },
      { "<leader>ar", "<cmd>AvanteRefresh<cr>", desc = "Avante Refresh" },
      { "<leader>ah", "<cmd>AvanteToggle<cr>", desc = "Avante Toggle" },
    },
    build = is_windows
      and "powershell.exe -NoProfile -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or nil,
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      {
        "HakonHarnes/img-clip.nvim",
        ft = { "markdown", "Avante" },
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
        ft = { "markdown", "Avante" },
        opts = { file_types = { "markdown", "Avante" } },
      },
    },
    opts = {
      provider = "copilot",
      behaviour = {
        auto_approve_tool_permissions = false,
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = false,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = true,
        minimize_diff = false,
      },
      mappings = {
        edit = "<leader>ae",
        ask = "<leader>aa",
        refresh = "<leader>ar",
        sidebar = {
          history = "<leader>ah",
          apply_one = "<leader>ap",
          apply_all = "<leader>aA",
        },
      },
      windows = {
        position = "right",
        width = 30,
        sidebar_header = { align = "center", rounded = true },
      },
    },
  },
}, {
  defaults = {
    lazy = true,
  },
  install = {
    colorscheme = { "gruvbox" },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- =============================================================================
-- 6. KEYMAPS
-- =============================================================================
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, desc = "Escape insert" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>h", "<cmd>noh<cr>", { desc = "Clear Highlights" })
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window Left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window Down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window Up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window Right" })

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
      vim.schedule(function()
        vim.cmd("Neotree show")
      end)
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
  local cmd

  if is_windows then
    cmd = string.format(
      "powershell.exe -NoProfile -Command Invoke-RestMethod -Uri 'https://cheat.sh/%s?T'",
      query
    )
  else
    cmd = string.format("curl -fsSL 'https://cheat.sh/%s?T'", query)
  end

  local output = vim.fn.systemlist(cmd)
  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  vim.opt_local.buftype = "nofile"
  vim.opt_local.bufhidden = "wipe"
  vim.opt_local.swapfile = false
  vim.opt_local.filetype = "sh"
end, { nargs = "+" })
