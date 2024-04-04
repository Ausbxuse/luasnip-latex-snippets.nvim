local M = {}

local ls = require("luasnip")
local f = ls.function_node
local i = ls.insert_node
local t = ls.text_node

local frac_no_parens = {
  f(function(_, snip)
    return string.format("\\frac{%s}", snip.captures[1])
  end, {}),
  t("{"),
  i(1),
  t("}"),
  i(0),
}

local binom_no_parens = {
  f(function(_, snip)
    return string.format("\\binom{%s}", snip.captures[1])
  end, {}),
  t("{"),
  i(1),
  t("}"),
  i(0),
}

local frac_node = {
  f(function(_, snip)
    local match = snip.trigger
    local stripped = match:sub(1, #match - 1)

    i = #stripped
    local depth = 0
    while i >= 0 do
      if stripped:sub(i, i) == ")" then
        depth = depth + 1
      end
      if stripped:sub(i, i) == "(" then
        depth = depth - 1
      end
      if depth == 0 then
        break
      end
      i = i - 1
    end

    if depth ~= 0 then
      return string.format("%s\\frac{}", stripped)
    else
      return string.format(
        "%s\\frac{%s}",
        stripped:sub(1, i - 1),
        stripped:sub(i + 1, #stripped - 1)
      )
    end
  end, {}),
  t("{"),
  i(1),
  t("}"),
  i(0),
}

local binom_node = {
  f(function(_, snip)
    local match = snip.trigger
    local stripped = match:sub(1, #match - 6)

    local i = #stripped
    local depth = 0
    while i >= 0 do
      if stripped:sub(i, i) == ")" then
        depth = depth + 1
      elseif stripped:sub(i, i) == "(" then
        depth = depth - 1
      end
      if depth == 0 then
        break
      end
      i = i - 1
    end

    if depth ~= 0 then
      return string.format("%s\\binom{}", stripped)
    else
      return string.format(
        "%s\\binom{%s}",
        stripped:sub(1, i - 1), -- Everything before the '('
        stripped:sub(i + 1, #stripped - 1) -- Everything between the '(' and ')'
      )
    end
  end, {}),
  t("{"),
  i(1),
  t("}"),
  i(0),
}

local subscript_node = {
  f(function(_, snip)
    return string.format("%s_{%s}", snip.captures[1], snip.captures[2])
  end, {}),
  i(0),
}

local frac_no_parens_triggers = {
  "(\\?[%w]+\\?^%w)/",
  "(\\?[%w]+\\?_%w)/",
  "(\\?[%w]+\\?^{%w*})/",
  "(\\?[%w]+\\?_{%w*})/",
  "(\\?%w+)/",
}
local binom_no_parens_triggers = {
  "(\\?[%w]+\\?^%w)choose",
  "(\\?[%w]+\\?_%w)choose",
  "(\\?[%w]+\\?^{%w*})choose",
  "(\\?[%w]+\\?_{%w*})choose",
  "(\\?%w+)choose",
}

function M.retrieve(is_math)
  local utils = require("luasnip-latex-snippets.util.utils")
  local pipe = utils.pipe

  local s = ls.extend_decorator.apply(ls.snippet, {
    wordTrig = false,
    trigEngine = "pattern",
    condition = pipe({ is_math }),
  }) --[[@as function]]

  local snippets = {
    s({
      trig = "([%a])(%d)",
      name = "auto subscript",
    }, vim.deepcopy(subscript_node)),

    s({
      trig = "([%a])_(%d%d)",
      name = "auto subscript 2",
    }, vim.deepcopy(subscript_node)),

    s({
      priority = 1000,
      trig = ".*%)/",
      name = "() frac",
      wordTrig = true,
    }, vim.deepcopy(frac_node)),
    s({
      priority = 1000,
      trig = ".*%)choose",
      name = "() choose",
      wordTrig = true,
    }, vim.deepcopy(binom_node)),
  }

  for _, trig in pairs(frac_no_parens_triggers) do
    snippets[#snippets + 1] = s({
      name = "Fraction no ()",
      trig = trig,
    }, vim.deepcopy(frac_no_parens))
  end

  for _, trig in pairs(binom_no_parens_triggers) do
    snippets[#snippets + 1] = s({
      name = "Fraction no ()",
      trig = trig,
    }, vim.deepcopy(binom_no_parens))
  end

  return snippets
end

return M
