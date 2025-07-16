---@class vxvim.util.ui
local M = {}

-- optimized treesitter foldexpr for Neovim >= 0.10.0
function M.foldexpr()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].ts_folds == nil then
    -- as long as we don't have a filetype, don't bother
    -- checking if treesitter is available (it won't)
    if vim.bo[buf].filetype == "" then
      return "0"
    end
    if vim.bo[buf].filetype:find("dashboard") then
      vim.b[buf].ts_folds = false
    else
      vim.b[buf].ts_folds = pcall(vim.treesitter.get_parser, buf)
    end
  end
  return vim.b[buf].ts_folds and vim.treesitter.foldexpr() or "0"
end

function M.fold_virt_text(result, start_text, lnum)
  local text = ''
  local hl
  for i = 1, #start_text do
    local char = start_text:sub(i, i)
    local new_hl

    -- if semantic tokens unavailable, use treesitter hl
    local sem_tokens = vim.lsp.semantic_tokens.get_at_pos(0, lnum, i - 1)
    if sem_tokens and #sem_tokens > 0 then
      new_hl = '@' .. sem_tokens[#sem_tokens].type
    else
      local captured_highlights = vim.treesitter.get_captures_at_pos(0, lnum, i - 1)
      if captured_highlights[#captured_highlights] then
        new_hl = '@' .. captured_highlights[#captured_highlights].capture
      end
    end

    if new_hl then
      if new_hl ~= hl then
        -- as soon as new hl appears, push substring with current hl to table
        table.insert(result, { text, hl })
        text = ''
        hl = nil
      end
      text = text .. char
      hl = new_hl
    else
      text = text .. char
    end
  end
  table.insert(result, { text, hl })
end

function M.foldtext()
  local start_text = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
  local nline = vim.v.foldend - vim.v.foldstart
  local result = {}
  M.fold_virt_text(result, start_text, vim.v.foldstart - 1)
  table.insert(result, { ' ', nil })
  table.insert(result, { '◖', '@comment.warning.gitcommit' })
  table.insert(result, { '↙ ' .. nline .. ' lines', '@comment.warning' })
  table.insert(result, { '◗', '@comment.warning.gitcommit' })
  return result
end

return M
