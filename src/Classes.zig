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
const editor = @import("Editor.zig");
const editbox = @import("EditBox.zig");
const textbox = @import("TextBox.zig");
const text = @import("Text.zig");
const mb = @import("MenuBar.zig");
const popdown = @import("PopDown.zig");
const radio = @import("RadioButton.zig");
const normal = @import("Normal.zig");
const dialbox = @import("DialogBox.zig");

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
// Base Class  Processor  Attribute  Class Name
// ----------  ---------  ---------  ----------
pub const classdefs = [_]struct{
    WindowClass,
    ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
    isize,
    []const u8} {

    .{WindowClass.FORCEINTTYPE, normal.NormalProc,     0,             "NORMAL"},   // Normal
    .{WindowClass.NORMAL,       app.ApplicationProc,   df.VISIBLE   |              // Application
                                                       df.SAVESELF  |
                                                       df.CONTROLBOX, "APPLICATION"},
    .{WindowClass.NORMAL,       textbox.TextBoxProc,   0,             "TEXTBOX"},  // TEXTBOX
    .{WindowClass.TEXTBOX,      lb.ListBoxProc,        0,             "LISTBOX"},  // LISTBOX
    .{WindowClass.TEXTBOX,      editbox.EditBoxProc,   0,             "EDITBOX"},  // EDITBOX
    .{WindowClass.NORMAL,       mb.MenuBarProc,        df.NOCLIP,     "MENUBAR"},  // MENUBAR
    .{WindowClass.LISTBOX,      popdown.PopDownProc,   df.SAVESELF   |   // POPDOWNMENU
                                                       df.NOCLIP     |
                                                       df.HASBORDER,  "POPDOWNMENU"},
    .{WindowClass.TEXTBOX,      pict.PictureProc,      0,             "PICTUREBOX"},  // PICTUREBOX
    .{WindowClass.NORMAL,       dialbox.DialogProc,    df.SHADOW     |   // DIALOG
                                                       df.MOVEABLE   |
                                                       df.CONTROLBOX |
                                                       df.HASBORDER  |
                                                       df.NOCLIP,     "DIALOG"},
    .{WindowClass.NORMAL,       box.BoxProc,           df.HASBORDER,  "BOX"},  // BOX
    .{WindowClass.TEXTBOX,      bt.ButtonProc,         df.SHADOW,     "BUTTON"},  // BUTTON
    .{WindowClass.EDITBOX,      combo.ComboProc,       0,             "COMBOBOX"},  // COMBOBOX
    .{WindowClass.TEXTBOX,      text.TextProc,         0,             "TEXT"},  // TEXT
    .{WindowClass.TEXTBOX,      radio.RadioButtonProc, 0,             "RADIOBUTTON"},  // RADIOBUTTON
    .{WindowClass.TEXTBOX,      cb.CheckBoxProc,       0,             "CHECKBOX"},  // CHECKBOX
    .{WindowClass.LISTBOX,      spin.SpinButtonProc,   0,             "SPINBUTTON"},  // SPINBUTTON
    .{WindowClass.DIALOG,       null,                  df.SHADOW     |   // ERRORBOX
                                                       df.HASBORDER,  "ERRORBOX"},
    .{WindowClass.DIALOG,       null,                  df.SHADOW     |   // MESSAGEBOX
                                                       df.HASBORDER,  "MESSAGEBOX"},
    .{WindowClass.DIALOG,       hb.HelpBoxProc,        df.MOVEABLE   |   // HELPBOX
                                                       df.SAVESELF   |
                                                       df.HASBORDER  |
                                                       df.NOCLIP     |
                                                       df.CONTROLBOX, "HELPBOX"},
    .{WindowClass.TEXTBOX,      sb.StatusBarProc,      df.NOCLIP,     "STATUSBAR"},  // STATUSBAR
    .{WindowClass.EDITBOX,      editor.EditorProc,     0,             "EDITOR"},  // EDITOR

    // ========> Add new classes here <========

    // ---------- pseudo classes to create enums, etc. ----------
    .{WindowClass.FORCEINTTYPE, null,               0,             "TITLEBAR"},  // TITLEBAR
    .{WindowClass.FORCEINTTYPE, null,               df.HASBORDER,  "DUMMY"},  // DUMMY
};
