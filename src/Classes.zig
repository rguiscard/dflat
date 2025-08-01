// ---------------- commands.h -----------------

const df = @import("ImportC.zig").df;
const app = @import("Application.zig");
const sb = @import("StatusBar.zig");
const bt = @import("Button.zig");
const box = @import("Box.zig");
const cb = @import("CheckBox.zig");
const combo = @import("ComboBox.zig");
const pict = @import("PictBox.zig");
const lb = @import("ListBox.zig");
const spin = @import("SpinButton.zig");
const hb = @import("HelpBox.zig");

// ----------- classes.h ------------
//
//         Class definition source file
//         Make class changes to this source file
//         Other source files will adapt
//
//         You must add entries to the color tables in
//         CONFIG.C for new classes.
//
//        Class Name  Base Class   Processor       Attribute
//       ------------  --------- ---------------  -----------
//
pub const WindowClass = enum (c_int) {
    FORCEINTTYPE = -1,      // required or enum type is unsigned char
    NORMAL = 0,
    APPLICATION,
    TEXTBOX,
    LISTBOX,
    EDITBOX,
    MENUBAR,
    POPDOWNMENU,
    PICTUREBOX,
    DIALOG,
    BOX,
    BUTTON,
    COMBOBOX,
    TEXT,
    RADIOBUTTON,
    CHECKBOX,
    SPINBUTTON,
    ERRORBOX,
    MESSAGEBOX,
    HELPBOX,
    STATUSBAR,
    EDITOR,

    //  ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc.
    TITLEBAR,
    DUMMY,
};

// Probably should built this via comptime
pub const classdefs = [_]struct{WindowClass,
                            ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int, isize} {
    .{WindowClass.FORCEINTTYPE, df.NormalProc,      0             },  // Normal
//    .{WindowClass.NORMAL,       df.ApplicationProc, df.VISIBLE    |   // Application
    .{WindowClass.NORMAL,       app.ApplicationProc, df.VISIBLE   |   // Application
                                                     df.SAVESELF  |
                                                     df.CONTROLBOX},
    .{WindowClass.NORMAL,       df.TextBoxProc,     0             },  // TEXTBOX
    .{WindowClass.TEXTBOX,      lb.ListBoxProc,     0             },  // LISTBOX
    .{WindowClass.TEXTBOX,      df.EditBoxProc,     0             },  // EDITBOX
    .{WindowClass.NORMAL,       df.MenuBarProc,     df.NOCLIP     },  // MENUBAR
    .{WindowClass.LISTBOX,      df.PopDownProc,     df.SAVESELF   |   // POPDOWNMENU
                                                    df.NOCLIP     |
                                                    df.HASBORDER  },
    .{WindowClass.TEXTBOX,      pict.PictureProc,   0             },  // PICTUREBOX
    .{WindowClass.NORMAL,       df.DialogProc,      df.SHADOW     |   // DIALOG
                                                    df.MOVEABLE   |
                                                    df.CONTROLBOX |
                                                    df.HASBORDER  |
                                                    df.NOCLIP     },
    .{WindowClass.NORMAL,       box.BoxProc,        df.HASBORDER  },  // BOX
    .{WindowClass.TEXTBOX,      bt.ButtonProc,      df.SHADOW     },  // BUTTON
    .{WindowClass.EDITBOX,      combo.ComboProc,    0             },  // COMBOBOX
    .{WindowClass.TEXTBOX,      df.TextProc,        0             },  // TEXT
    .{WindowClass.TEXTBOX,      df.RadioButtonProc, 0             },  // RADIOBUTTON
    .{WindowClass.TEXTBOX,      cb.CheckBoxProc,    0             },  // CHECKBOX
    .{WindowClass.LISTBOX,      spin.SpinButtonProc,  0             },  // SPINBUTTON
    .{WindowClass.DIALOG,       null,               df.SHADOW     |   // ERRORBOX
                                                    df.HASBORDER  },
    .{WindowClass.DIALOG,       null,               df.SHADOW     |   // MESSAGEBOX
                                                    df.HASBORDER  },
//    .{WindowClass.DIALOG,       df.HelpBoxProc,     df.MOVEABLE   |   // HELPBOX
    .{WindowClass.DIALOG,       hb.HelpBoxProc,     df.MOVEABLE   |   // HELPBOX
                                                    df.SAVESELF   |
                                                    df.HASBORDER  |
                                                    df.NOCLIP     |
                                                    df.CONTROLBOX },
    .{WindowClass.TEXTBOX,      sb.StatusBarProc,   df.NOCLIP     },  // STATUSBAR
    .{WindowClass.EDITBOX,      df.EditorProc,      0             },  // EDITOR

    // ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc. ----------
    .{WindowClass.FORCEINTTYPE, null,               0             },  // TITLEBAR
    .{WindowClass.FORCEINTTYPE, null,               df.HASBORDER  },  // DUMMY
};
