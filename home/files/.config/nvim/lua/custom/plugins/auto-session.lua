return {
  'rmagatti/auto-session',
  config = function()
    vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'
    local auto_session = require 'auto-session'

    auto_session.setup {
      auto_restore = false,
      suppressed_dirs = { '~/' },
    }

    local keymap = vim.keymap

    keymap.set('n', '<leader>wr', '<cmd>SessionRestore<CR>', { desc = '[W]orkspace [R]estore' })
    keymap.set('n', '<leader>ww', '<cmd>SessionSave<CR>', { desc = '[W]orkspace [W]rite' })
  end,
}
