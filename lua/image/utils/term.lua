local ffi = require("ffi")

ffi.cdef([[
  typedef void* HANDLE;
  typedef uint32_t DWORD;
  typedef int BOOL;
  typedef uint16_t WORD;
  typedef int16_t SHORT;

  typedef struct {
    SHORT Left;
    SHORT Top;
    SHORT Right;
    SHORT Bottom;
  } SMALL_RECT;

  typedef struct {
    WORD X;
    WORD Y;
  } COORD;

  typedef struct {
    COORD dwSize;
    COORD dwCursorPosition;
    WORD  wAttributes;
    SMALL_RECT srWindow;
    COORD dwMaximumWindowSize;
  } CONSOLE_SCREEN_BUFFER_INFO;

  HANDLE GetStdHandle(DWORD nStdHandle);
  BOOL GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFO* lpConsoleScreenBufferInfo);

  COORD GetCurrentConsoleFont(HANDLE hConsoleOutput, BOOL bMaximumWindow);
  COORD GetConsoleFontSize(HANDLE hConsoleOutput, COORD dwFont);
]])

local STD_OUTPUT_HANDLE = -11
local cached_size = {
  screen_cols = 0,
  screen_rows = 0,
  -- pixel dims are optional / approximate
  cell_width = nil,
  cell_height = nil,
}

local update_size = function()
  local hOut = ffi.C.GetStdHandle(STD_OUTPUT_HANDLE)
  if hOut == ffi.cast("HANDLE", 0) then return end

  local csbi = ffi.new("CONSOLE_SCREEN_BUFFER_INFO")
  local ok = ffi.C.GetConsoleScreenBufferInfo(hOut, csbi)
  if ok == 0 then return end

  local cols = csbi.srWindow.Right - csbi.srWindow.Left + 1
  local rows = csbi.srWindow.Bottom - csbi.srWindow.Top + 1

  cached_size.screen_cols = cols
  cached_size.screen_rows = rows

  local font_coord = ffi.C.GetCurrentConsoleFont(hOut, false) -- FALSE for not maximum
  if font_coord.X ~= 0 and font_coord.Y ~= 0 then
    local font_size = ffi.C.GetConsoleFontSize(hOut, font_coord)
    cached_size.cell_width = font_size.X
    cached_size.cell_height = font_size.Y
  else
    cached_size.cell_width = nil
    cached_size.cell_height = nil
  end
end

update_size()

if vim and vim.api and vim.api.nvim_create_autocmd then
  vim.api.nvim_create_autocmd("VimResized", {
    callback = update_size,
  })
end

local get_tty = function()
  return "CONOUT$"
end

return {
  get_size = function()
    return {
      screen_cols = cached_size.screen_cols,
      screen_rows = cached_size.screen_rows,
      cell_width = cached_size.cell_width,
      cell_height = cached_size.cell_height,
    }
  end,
  get_tty = get_tty,
}
