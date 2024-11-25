-- We almost always start by importing the wezterm module
local wezterm = require 'wezterm'
-- Define a lua table to hold _our_ module's functions
local module = {}

module.segments_for_right_status = function(window, _)
  return {
    window:mux_window():active_pane():get_current_working_dir(),
    basename(window:mux_window():active_pane():get_foreground_process_name()),
    window:active_workspace(),
    wezterm.hostname(),
    wezterm.strftime('%a %b %-d %H:%M'),
  }
end

module.colors_for_right_status = function(window,_)
    -- wezterm.color.parse returns a ColorWrap object, which includes lighten/darken methods
    local bg = wezterm.color.parse(window:effective_config().resolved_palette.background)

    -- PowerLine uses a gradient based on two colors
    -- Our default implementation just fades to the terminal background color
    local gradient_to, gradient_from = bg, bg
    if module.is_dark() then
        gradient_from = gradient_to:lighten(0.2)
    else
        gradient_from = gradient_to:darken(0.2)
    end

    return {
        gradient_from,
        gradient_to
    }
end

-- Returns a bool based on whether the host operating system's
-- appearance is light or dark.
function module.is_dark()
  -- wezterm.gui is not always available, depending on what
  -- environment wezterm is operating in. Just return true
  -- if it's not defined.
  if wezterm.gui then
    -- Some systems report appearance like "Dark High Contrast"
    -- so let's just look for the string "Dark" and if we find
    -- it assume appearance is dark.
    return wezterm.gui.get_appearance():find("Dark")
  end
  return true
end

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end


wezterm.on('update-status', function(window, _)
    local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
    local segments = module.segments_for_right_status(window)
    local bg_colors = module.colors_for_right_status(window)

    -- Yes, WezTerm supports creating gradients, because why not?!
    -- Normally you'd use them for high fidelity gradients on your background
    -- We'll use them for PowerLine segment color we need.
    local gradient = wezterm.color.gradient(
        {
        orientation = 'Horizontal',
        colors = bg_colors
        },
        #segments -- only gives us as many colors as we have segments.
    )

    -- We'll build up the elements to send to wezterm.format in this table.
    local elements = {}
    local fg = window:effective_config().resolved_palette.foreground

    for i, seg in ipairs(segments) do
        local is_first = i == 1

        if is_first then
        table.insert(elements, { Background = { Color = 'none' } })
        end
        table.insert(elements, { Foreground = { Color = gradient[i] } })
        table.insert(elements, { Text = SOLID_LEFT_ARROW })

        table.insert(elements, { Foreground = { Color = fg } })
        table.insert(elements, { Background = { Color = gradient[i] } })
        table.insert(elements, { Text = ' ' .. seg .. ' ' })
    end

    --   table.insert(elements, { Foreground = { Color = 'none' } })
    --   table.insert(elements, { Background = { Color = gradient[#segments] } })
    --   table.insert(elements, { Text = SOLID_LEFT_ARROW })

    window:set_right_status(wezterm.format(elements))
end)



return module

