---@class YChat
local M = {}

M.send = function ()
  local message = vim.fn.input("Message: ")
  if message == "" then
    return
  end

  local handle

  local function onexit(code, signal)
    handle:close()
  end

  handle = vim.loop.spawn("node", {
    args = { "client/index.js", "write", message },
    stdio = { nil, nil, nil },
    cwd = "~/Documents/ychat.nvim",
  }, onexit)
end

M.toggle_chat = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "yChat")

  vim.api.nvim_command("vsplit")
  vim.api.nvim_win_set_buf(0, buf)

  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  local handle

  local function onexit(code, signal)
    stdout:close()
    stderr:close()
    handle:close()
    print("Process exited with code", code, "and signal", signal)
  end

  local function onread(err, data)
    if err then
      print("Error: ", err)
    elseif data then
      vim.schedule(function()
        local lines = {}
        for s in data:gmatch("[^\r\n]+") do
          table.insert(lines, s)
        end
        if #lines > 0 then
          local is_initial = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
          local line_count = vim.api.nvim_buf_line_count(buf)

          -- If it's the initial blank line, replace it, otherwise append
          if is_initial and line_count == 1 then
            vim.api.nvim_buf_set_lines(buf, 0, 1, false, lines)
          else
            vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)
          end
        end
      end)
    end
  end

  handle = vim.loop.spawn("node", {
    args = { "client/index.js", "read" },
    stdio = { nil, stdout, stderr },
    cwd = "~/Documents/ychat.nvim/client",
  }, onexit)

  vim.loop.read_start(stdout, onread)
  vim.loop.read_start(stderr, onread)
end

M.setup = function()
end

return M
