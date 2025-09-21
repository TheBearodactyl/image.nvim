local cached_size = {
  screen_x = 0,
  screen_y = 0,
  screen_cols = 0,
  screen_rows = 0,
  cell_width = 0,
  cell_height = 0,
}

local update_size = function()
  local ffi = require("ffi")

  ffi.cdef([[
    typedef struct _COORD {
      short X;
      short Y;
    } COORD;
    
    typedef struct _SMALL_RECT {
      short Left;
      short Top;
      short Right;
      short Bottom;
    } SMALL_RECT;
    
    typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
      COORD dwSize;
      COORD dwCursorPosition;
      unsigned short wAttributes;
      SMALL_RECT srWindow;
      COORD dwMaximumWindowSize;
    } CONSOLE_SCREEN_BUFFER_INFO;
    
    void* GetStdHandle(unsigned long nStdHandle);
    int GetConsoleScreenBufferInfo(void* hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFO* lpConsoleScreenBufferInfo);
    int GetSystemMetrics(int nIndex);
  ]])

  local STD_OUTPUT_HANDLE = 0xFFFFFFF5
  local SM_CXSCREEN = 0
  local SM_CYSCREEN = 1

  local console_handle = ffi.C.GetStdHandle(STD_OUTPUT_HANDLE)
  local buffer_info = ffi.new("CONSOLE_SCREEN_BUFFER_INFO")

  if ffi.C.GetConsoleScreenBufferInfo(console_handle, buffer_info) ~= 0 then
    local cols = buffer_info.srWindow.Right - buffer_info.srWindow.Left + 1
    local rows = buffer_info.srWindow.Bottom - buffer_info.srWindow.Top + 1

    local screen_width = ffi.C.GetSystemMetrics(SM_CXSCREEN)
    local screen_height = ffi.C.GetSystemMetrics(SM_CYSCREEN)

    cached_size = {
      screen_x = screen_width,
      screen_y = screen_height,
      screen_cols = cols,
      screen_rows = rows,
      cell_width = screen_width / cols,
      cell_height = screen_height / rows,
    }
  else
    cached_size = {
      screen_x = 1920,
      screen_y = 1080,
      screen_cols = 80,
      screen_rows = 25,
      cell_width = 24,
      cell_height = 43.2,
    }
  end
end

update_size()

vim.api.nvim_create_autocmd("VimResized", {
  callback = update_size,
})

local get_tty = function()
  local handle = io.popen("echo %CD% 2>nul")
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  result = vim.fn.trim(result)
  if result == "" then return nil end
  return "CON"
end

return {
  get_size = function()
    return cached_size
  end,
  get_tty = get_tty,
}
