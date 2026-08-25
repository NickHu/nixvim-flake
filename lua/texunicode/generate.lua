-- nvim --clean --headless -u NONE -l generate.lua unimathsymbols.txt out.json
--
-- unimathsymbols.txt is one row per codepoint in ascending order, so where two
-- codepoints claim the same command (U+0393 Γ and U+1D6E4 𝛤 are both \Gamma)
-- the plain character sorts first and the first row to claim a command wins.
local source, out = unpack(_G.arg)

local map, reverse = {}, {}

-- Bare `A` for 𝐴 and `-` for − would turn prose into mathematics.
local function add(command, char)
  if command and char and char ~= '' and command:match('^[\\^_].') and not map[command] then
    map[command] = char
  end
end

-- code^chr^LaTeX^unicode-math^class^category^requirements^comments
for _, line in ipairs(vim.fn.readfile(source)) do
  if line:sub(1, 1) ~= '#' then
    local field = vim.split(line, '^', { plain = true })
    local char = field[2]
    -- Class D is a diacritic, whose character field is a sample rendering \hat → `x̂`
    if char and char ~= '' and field[5] ~= 'D' then
      add(field[3], char)
      add(field[4], char)
      -- The comments field lists aliases as "= \command (package)".
      for alias in (field[8] or ''):gmatch('=%s*(\\[%a@]+)') do
        add(alias, char)
      end
      -- Field 3 is the preferred spelling: \mathbb{N} rather than \BbbN.
      if not reverse[char] and (field[3] or ''):sub(1, 1) == '\\' then
        reverse[char] = field[3]
      end
    end
  end
end

-- Sub- and superscripts, which unimathsymbols leaves blank because TeX builds
-- them rather than naming them.
local scripts = {
  ['^'] = {
    [[()+-0123456789=ABDEGHIJKLMNOPRTUVWabcdefghijklmnoprstuvwxyz]],
    [[⁽⁾⁺⁻⁰¹²³⁴⁵⁶⁷⁸⁹⁼ᴬᴮᴰᴱᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᴿᵀᵁⱽᵂᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻ]],
  },
  ['_'] = {
    [[()+-0123456789=aehijklmnoprstuvx]],
    [[₍₎₊₋₀₁₂₃₄₅₆₇₈₉₌ₐₑₕᵢⱼₖₗₘₙₒₚᵣₛₜᵤᵥₓ]],
  },
}

for mark, halves in pairs(scripts) do
  local plain, script = halves[1], vim.fn.split(halves[2], '.\\zs')
  assert(#plain == #script, ('scripts["%s"] halves are different lengths'):format(mark))
  for i, char in ipairs(script) do
    add(mark .. plain:sub(i, i), char)
    add('\\' .. mark .. plain:sub(i, i), char)
    reverse[char] = reverse[char] or ('\\' .. mark .. plain:sub(i, i))
  end
end

map = vim.tbl_extend('force', map, {
  ['\\emptyset'] = '∅', -- unimathsymbols only offers \varnothing
  ['\\hbar'] = 'ℏ', -- ... only \hslash
  ['\\surd'] = '√',
  ['\\qed'] = '∎',
  ['\\Box'] = '□',
  ['\\shortmid'] = '∣',
  ['\\thicksim'] = '∼',
  ['\\setminus'] = '∖', -- U+2216 SET MINUS, not U+29F5 REVERSE SOLIDUS OPERATOR
  ['\\triangle'] = '∆', -- U+2206 INCREMENT, not U+25B3 WHITE UP-POINTING TRIANGLE
  ['\\ngeqq'] = '≱', -- no precomposed codepoint; nearest single character
  ['\\nleqq'] = '≰',
})

-- non-diacritics which are supposed to be commands
for _, command in ipairs({
  '\\cat', -- ⁀ in the oz package, a category elsewhere
  '\\dot',
  '\\mathit',
  '\\overbrace',
  '\\sqrt', -- \surd is still there for the bare √
  '\\underbrace',
}) do
  map[command] = nil
end

-- A one-byte replacement is an ASCII escape (\{ → {) rather than a symbol.
for command, char in pairs(map) do
  if #char == 1 then
    map[command] = nil
    reverse[char] = nil
  end
end

local shortest = {}
for command, char in pairs(map) do
  local best = shortest[char]
  if
      command:sub(1, 1) == '\\'
      and (not best or #command < #best or (#command == #best and command < best))
  then
    shortest[char] = command
  end
end
for char, command in pairs(shortest) do
  if not reverse[char] or not map[reverse[char]] then
    reverse[char] = command
  end
end

vim.fn.writefile({ vim.json.encode({ forward = map, reverse = reverse }) }, out)
