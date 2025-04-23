vim.cmd 'let g:netrw_liststyle = 3'

local opt = vim.opt

opt.mouse = 'a'

opt.showmode = false

opt.relativenumber = true
opt.number = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true

opt.inccommand = 'split'

opt.cursorline = true

-- opt.termguicolors = true
-- opt.background = 'dark'
opt.signcolumn = 'yes'

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

opt.breakindent = true

opt.undofile = true

opt.splitright = true
opt.splitbelow = true

opt.scrolloff = 10

opt.updatetime = 250

opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
