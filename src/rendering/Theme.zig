const std = @import("std");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const Transparent = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
    pub const Black = Color{ .r = 0, .g = 0, .b = 0, .a = 255 };
    pub const White = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = 255 };
    }

    pub fn hex(val: u24) Color {
        return .{
            .r = @as(u8, @truncate(val >> 16)),
            .g = @as(u8, @truncate(val >> 8)),
            .b = @as(u8, @truncate(val)),
            .a = 255,
        };
    }

    pub fn lerp(a: Color, b: Color, t: f32) Color {
        return .{
            .r = @intFromFloat(@as(f32, @floatFromInt(a.r)) * (1 - t) + @as(f32, @floatFromInt(b.r)) * t),
            .g = @intFromFloat(@as(f32, @floatFromInt(a.g)) * (1 - t) + @as(f32, @floatFromInt(b.g)) * t),
            .b = @intFromFloat(@as(f32, @floatFromInt(a.b)) * (1 - t) + @as(f32, @floatFromInt(b.b)) * t),
            .a = 255,
        };
    }
};

pub const SyntaxColors = struct {
    keyword: Color,
    string: Color,
    number: Color,
    comment: Color,
    function: Color,
    type: Color,
    variable: Color,
    constant: Color,
    operator: Color,
    punctuation: Color,
    parameter: Color,
    property: Color,
    tag: Color,
    attribute: Color,
    regex: Color,
    markup_bold: Color,
    markup_italic: Color,
    markup_heading: Color,
    markup_link: Color,
    markup_list: Color,
    markup_quote: Color,
    markup_inline_code: Color,
    markup_code_block: Color,
};

pub const Theme = struct {
    name: []const u8,
    kind: enum { dark, light },

    background: Color,
    foreground: Color,
    caret: Color,
    selection_background: Color,
    selection_foreground: Color,
    line_highlight: Color,
    gutter_background: Color,
    gutter_foreground: Color,
    gutter_active_foreground: Color,
    indent_guide: Color,
    whitespace: Color,

    panel_background: Color,
    panel_border: Color,
    panel_foreground: Color,
    tab_active_background: Color,
    tab_inactive_background: Color,
    tab_active_foreground: Color,
    tab_inactive_foreground: Color,
    statusbar_background: Color,
    statusbar_foreground: Color,
    sidebar_background: Color,
    sidebar_foreground: Color,
    sidebar_selection: Color,

    button_background: Color,
    button_foreground: Color,
    button_hover: Color,
    button_active: Color,

    input_background: Color,
    input_foreground: Color,
    input_border: Color,
    input_focus_border: Color,

    scrollbar_background: Color,
    scrollbar_thumb: Color,
    scrollbar_thumb_hover: Color,

    syntax: SyntaxColors,

    pub fn default() Theme {
        return qimingDark();
    }

    pub fn qimingDark() Theme {
        return Theme{
            .name = "Qiming Dark",
            .kind = .dark,
            .background = Color.hex(0x1e1e2e),
            .foreground = Color.hex(0xcdd6f4),
            .caret = Color.hex(0xf5e0dc),
            .selection_background = Color.hex(0x585b70),
            .selection_foreground = Color.hex(0xcdd6f4),
            .line_highlight = Color.hex(0x313244),
            .gutter_background = Color.hex(0x181825),
            .gutter_foreground = Color.hex(0x6c7086),
            .gutter_active_foreground = Color.hex(0xcdd6f4),
            .indent_guide = Color.hex(0x313244),
            .whitespace = Color.hex(0x45475a),
            .panel_background = Color.hex(0x181825),
            .panel_border = Color.hex(0x313244),
            .panel_foreground = Color.hex(0xcdd6f4),
            .tab_active_background = Color.hex(0x1e1e2e),
            .tab_inactive_background = Color.hex(0x181825),
            .tab_active_foreground = Color.hex(0xcdd6f4),
            .tab_inactive_foreground = Color.hex(0x6c7086),
            .statusbar_background = Color.hex(0x181825),
            .statusbar_foreground = Color.hex(0xa6adc8),
            .sidebar_background = Color.hex(0x181825),
            .sidebar_foreground = Color.hex(0xcdd6f4),
            .sidebar_selection = Color.hex(0x313244),
            .button_background = Color.hex(0x45475a),
            .button_foreground = Color.hex(0xcdd6f4),
            .button_hover = Color.hex(0x585b70),
            .button_active = Color.hex(0x6c7086),
            .input_background = Color.hex(0x313244),
            .input_foreground = Color.hex(0xcdd6f4),
            .input_border = Color.hex(0x45475a),
            .input_focus_border = Color.hex(0x89b4fa),
            .scrollbar_background = Color.hex(0x181825),
            .scrollbar_thumb = Color.hex(0x45475a),
            .scrollbar_thumb_hover = Color.hex(0x585b70),
            .syntax = .{
                .keyword = Color.hex(0xcba6f7),
                .string = Color.hex(0xa6e3a1),
                .number = Color.hex(0xfab387),
                .comment = Color.hex(0x6c7086),
                .function = Color.hex(0x89b4fa),
                .type = Color.hex(0xf9e2af),
                .variable = Color.hex(0xcdd6f4),
                .constant = Color.hex(0xfab387),
                .operator = Color.hex(0x89dceb),
                .punctuation = Color.hex(0x6c7086),
                .parameter = Color.hex(0xf2cdcd),
                .property = Color.hex(0x89dceb),
                .tag = Color.hex(0xf38ba8),
                .attribute = Color.hex(0xf9e2af),
                .regex = Color.hex(0xf5c2e7),
                .markup_bold = Color.hex(0xcdd6f4),
                .markup_italic = Color.hex(0xcdd6f4),
                .markup_heading = Color.hex(0xf38ba8),
                .markup_link = Color.hex(0x89b4fa),
                .markup_list = Color.hex(0xfab387),
                .markup_quote = Color.hex(0x6c7086),
                .markup_inline_code = Color.hex(0xa6e3a1),
                .markup_code_block = Color.hex(0xa6e3a1),
            },
        };
    }

    pub fn qimingLight() Theme {
        return Theme{
            .name = "Qiming Light",
            .kind = .light,
            .background = Color.hex(0xeff1f5),
            .foreground = Color.hex(0x4c4f69),
            .caret = Color.hex(0xdc8a78),
            .selection_background = Color.hex(0xacd0f5),
            .selection_foreground = Color.hex(0x4c4f69),
            .line_highlight = Color.hex(0xe6e9ef),
            .gutter_background = Color.hex(0xe6e9ef),
            .gutter_foreground = Color.hex(0x9ca0b0),
            .gutter_active_foreground = Color.hex(0x4c4f69),
            .indent_guide = Color.hex(0xccd0da),
            .whitespace = Color.hex(0xccd0da),
            .panel_background = Color.hex(0xe6e9ef),
            .panel_border = Color.hex(0xccd0da),
            .panel_foreground = Color.hex(0x4c4f69),
            .tab_active_background = Color.hex(0xeff1f5),
            .tab_inactive_background = Color.hex(0xe6e9ef),
            .tab_active_foreground = Color.hex(0x4c4f69),
            .tab_inactive_foreground = Color.hex(0x9ca0b0),
            .statusbar_background = Color.hex(0xe6e9ef),
            .statusbar_foreground = Color.hex(0x5c5f77),
            .sidebar_background = Color.hex(0xe6e9ef),
            .sidebar_foreground = Color.hex(0x4c4f69),
            .sidebar_selection = Color.hex(0xccd0da),
            .button_background = Color.hex(0xccd0da),
            .button_foreground = Color.hex(0x4c4f69),
            .button_hover = Color.hex(0xbcc0cc),
            .button_active = Color.hex(0xacb0be),
            .input_background = Color.hex(0xffffff),
            .input_foreground = Color.hex(0x4c4f69),
            .input_border = Color.hex(0xccd0da),
            .input_focus_border = Color.hex(0x1e66f5),
            .scrollbar_background = Color.hex(0xe6e9ef),
            .scrollbar_thumb = Color.hex(0xccd0da),
            .scrollbar_thumb_hover = Color.hex(0xbcc0cc),
            .syntax = .{
                .keyword = Color.hex(0x8839ef),
                .string = Color.hex(0x40a02b),
                .number = Color.hex(0xfe640b),
                .comment = Color.hex(0x9ca0b0),
                .function = Color.hex(0x1e66f5),
                .type = Color.hex(0xdf8e1d),
                .variable = Color.hex(0x4c4f69),
                .constant = Color.hex(0xfe640b),
                .operator = Color.hex(0x04a5e5),
                .punctuation = Color.hex(0x9ca0b0),
                .parameter = Color.hex(0xd20f39),
                .property = Color.hex(0x04a5e5),
                .tag = Color.hex(0xd20f39),
                .attribute = Color.hex(0xdf8e1d),
                .regex = Color.hex(0xea76cb),
                .markup_bold = Color.hex(0x4c4f69),
                .markup_italic = Color.hex(0x4c4f69),
                .markup_heading = Color.hex(0xd20f39),
                .markup_link = Color.hex(0x1e66f5),
                .markup_list = Color.hex(0xfe640b),
                .markup_quote = Color.hex(0x9ca0b0),
                .markup_inline_code = Color.hex(0x40a02b),
                .markup_code_block = Color.hex(0x40a02b),
            },
        };
    }
};
