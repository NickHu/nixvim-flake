--- Expand LaTeX commands to Unicode as you type: \mathbb{N} → ℕ, \alpha → α.
local M = {}

local map, reverse, prefixes, maxlen

local function load_table()
  if map then
    return
  end
  map, reverse, prefixes, maxlen = {}, {}, {}, 0
  local path = vim.api.nvim_get_runtime_file('lua/texunicode/table.json', false)[1]
  if not path then
    return vim.notify('texunicode: table.json is not on the runtimepath', vim.log.levels.ERROR)
  end
  local data = vim.json.decode(table.concat(vim.fn.readfile(path), '\n'))
  map, reverse = data.forward, data.reverse
  for command in pairs(map) do
    maxlen = math.max(maxlen, #command)
    for i = 1, #command - 1 do
      prefixes[command:sub(1, i)] = true
    end
  end
end

local function ending_at(s)
  for len = math.min(maxlen, #s), 1, -1 do
    local command = s:sub(#s - len + 1)
    if map[command] then
      return command
    end
  end
end

-- TeX reads a backslash and letters as one control word: \tox is not \to.
local function cut_short(command, next_char)
  return command:match('^\\%a+$') and next_char:match('%a')
end

local script_terminator = '[ $\\]'

--- The command to expand in `before`, and whether a character terminated it.
local function pending(before, closing)
  local command = ending_at(before)
  if command and (closing or (not prefixes[command] and command:sub(1, 1) == '\\')) then
    return command, 0
  end
  local last = before:sub(-1)
  command = ending_at(before:sub(1, -2))
  if
      command
      and not prefixes[command .. last]
      and not map[command .. last]
      and (command:sub(1, 1) == '\\' or last:match(script_terminator))
      and not cut_short(command, last)
  then
    return command, 1
  end
end

--- @param closing? boolean  insert mode is ending, so finish what is there
local function expand(closing)
  if not vim.b.texunicode then
    return
  end
  load_table()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local command, terminator = pending(vim.api.nvim_get_current_line():sub(1, col), closing)
  if not command then
    return
  end
  local char = map[command]
  local from = col - terminator - #command
  vim.api.nvim_buf_set_text(0, row - 1, from, row - 1, from + #command, { char })
  vim.api.nvim_win_set_cursor(0, { row, from + #char + terminator })
end

--- @param opts? { enabled?: boolean }
function M.attach(opts)
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.b[bufnr].texunicode ~= nil then
    return
  end
  vim.b[bufnr].texunicode = (opts or {}).enabled ~= false
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChangedP', 'InsertLeavePre' }, {
    group = vim.api.nvim_create_augroup('TexUnicode', { clear = false }),
    buffer = bufnr,
    desc = 'Expand LaTeX commands to Unicode',
    callback = function(ev)
      expand(ev.event == 'InsertLeavePre')
    end,
  })
end

-- Bulk conversion skips the backslash-less commands
local function to_unicode(line)
  local out, i = {}, 1
  while i <= #line do
    local hit
    for len = math.min(maxlen, #line - i + 1), 2, -1 do
      local command = line:sub(i, i + len - 1)
      if
          map[command]
          and command:sub(1, 1) == '\\'
          and not cut_short(command, line:sub(i + len, i + len))
      then
        hit = command
        break
      end
    end
    out[#out + 1] = hit and map[hit] or line:sub(i, i)
    i = i + (hit and #hit or 1)
  end
  return table.concat(out)
end

local function to_tex(line)
  return table.concat(vim.tbl_map(function(char)
    return reverse[char] or char
  end, vim.fn.split(line, '.\\zs')))
end

local function over_range(convert)
  return function(args)
    load_table()
    local lines = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
    vim.api.nvim_buf_set_lines(0, args.line1 - 1, args.line2, false, vim.tbl_map(convert, lines))
  end
end

vim.api.nvim_create_user_command('Tex2Unicode', over_range(to_unicode), {
  range = '%',
  desc = 'LaTeX commands → Unicode',
})
vim.api.nvim_create_user_command('Unicode2Tex', over_range(to_tex), {
  range = '%',
  desc = 'Unicode → LaTeX commands',
})

vim.api.nvim_create_user_command('TexUnicodeToggle', function()
  if vim.b.texunicode == nil then
    M.attach()
  else
    vim.b.texunicode = not vim.b.texunicode
  end
  vim.notify('texunicode: expansion ' .. (vim.b.texunicode and 'on' or 'off'))
end, { desc = 'Toggle LaTeX → Unicode expansion in this buffer' })

return M
