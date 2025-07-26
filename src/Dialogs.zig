const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const DialogBox = @import("DialogBox.zig");
const msg = @import("Message.zig").Message;

// -------------- the File Open dialog box --------------- 
pub const FileOpen:df.DBOX = buildDialog(
    "FileOpen",
    .{"Open File", -1, -1, 19, 57},
    .{
        .{df.TEXT,     "~Filename:",    3, 1, 1, 9, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.EDITBOX,  null,           13, 1, 1,40, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.TEXT,     null        ,    3, 3, 1,50, df.ID_PATH,      "ID_PATH"     },
        .{df.TEXT,     "~Directories:", 3, 5, 1,12, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.LISTBOX,  null,            3, 6,10,14, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.TEXT,     "F~iles:",      19, 5, 1, 6, df.ID_FILES,     "ID_FILES"    },
        .{df.LISTBOX,  null,           19, 6,10,24, df.ID_FILES,     "ID_FILES"    },
        .{df.BUTTON,   "   ~OK   ",    46, 7, 1, 8, df.ID_OK,        "ID_OK"       },
        .{df.BUTTON,   " ~Cancel ",    46,10, 1, 8, df.ID_CANCEL,    "ID_CANCEL"   },
        .{df.BUTTON,   "  ~Help  ",    46,13, 1, 8, df.ID_HELP,      "ID_HELP"     },
    },
);

// -------------- the Save As dialog box ---------------
pub const SaveAs:df.DBOX = buildDialog(
    "SaveAs",
    .{"Save As", -1, -1, 19, 57},
    .{
        .{df.TEXT,     "~Filename:",    3, 1, 1, 9, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.EDITBOX,  null,           13, 1, 1,40, df.ID_FILENAME,  "ID_FILENAME" },
        .{df.TEXT,     null        ,    3, 3, 1,50, df.ID_PATH,      "ID_PATH"     },
        .{df.TEXT,     "~Directories:", 3, 5, 1,12, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.LISTBOX,  null,            3, 6,10,14, df.ID_DIRECTORY, "ID_DIRECTORY"},
        .{df.TEXT,     "F~iles:",      19, 5, 1, 6, df.ID_FILES,     "ID_FILES"    },
        .{df.LISTBOX,  null,           19, 6,10,24, df.ID_FILES,     "ID_FILES"    },
        .{df.BUTTON,   "   ~OK   ",    46, 7, 1, 8, df.ID_OK,        "ID_OK"       },
        .{df.BUTTON,   " ~Cancel ",    46,10, 1, 8, df.ID_CANCEL,    "ID_CANCEL"   },
        .{df.BUTTON,   "  ~Help  ",    46,13, 1, 8, df.ID_HELP,      "ID_HELP"     },
    },
);
//DIALOGBOX( SaveAs )
//    DB_TITLE(        "Save As",    -1,-1,19,57)
//    CONTROL(TEXT,    "~Filename:",    3, 1, 1, 9, ID_FILENAME)
//    CONTROL(EDITBOX, NULL,           13, 1, 1,40, ID_FILENAME)
//    CONTROL(TEXT,    NULL,            3, 3, 1,50, ID_PATH )
//    CONTROL(TEXT,    "~Directories:", 3, 5, 1,12, ID_DIRECTORY )
//    CONTROL(LISTBOX, NULL,            3, 6,10,14, ID_DIRECTORY )
//    CONTROL(TEXT,    "F~iles:",      19, 5, 1, 6, ID_FILES )
//    CONTROL(LISTBOX, NULL,           19, 6,10,24, ID_FILES )
//    CONTROL(BUTTON,  "   ~OK   ",    46, 7, 1, 8, ID_OK)
//    CONTROL(BUTTON,  " ~Cancel ",    46,10, 1, 8, ID_CANCEL)
//    CONTROL(BUTTON,  "  ~Help  ",    46,13, 1, 8, ID_HELP)
//ENDDB

// -------------- the Search Text dialog box ---------------
pub const SearchTextDB:df.DBOX = buildDialog(
    "SearchTextDB",
    .{"Search Text", -1, -1, 9, 48},
    .{
        .{df.TEXT,     "~Search for:",             2, 1, 1, 11, df.ID_SEARCHFOR, "ID_SEARCHFOR"},
        .{df.EDITBOX,  null,                      14, 1, 1, 29, df.ID_SEARCHFOR, "ID_SEARCHFOR"},
        .{df.TEXT,     "~Match upper/lower case:", 2, 3, 1, 23, df.ID_MATCHCASE, "ID_MATCHCASE"},
        .{df.CHECKBOX, null,                      26, 3, 1,  3, df.ID_MATCHCASE, "ID_MATCHCASE"},
        .{df.BUTTON,   "   ~OK   ",                7, 5, 1,  8, df.ID_OK,        "ID_OK"       },
        .{df.BUTTON,   " ~Cancel ",               19, 5, 1,  8, df.ID_CANCEL,    "ID_CANCEL"   },
        .{df.BUTTON,   "  ~Help  ",               31, 5, 1,  8, df.ID_HELP,      "ID_HELP"     },
    },
);

// -------------- the Replace Text dialog box ---------------
pub const ReplaceTextDB:df.DBOX = buildDialog(
    "ReplaceTextDB",
    .{"Replace Text", -1, -1, 12, 50},
    .{
        .{df.TEXT,     "~Search for:",              2, 1, 1, 11, df.ID_SEARCHFOR,   "ID_SEARCHFOR"  },
        .{df.EDITBOX,  null,                       16, 1, 1, 29, df.ID_SEARCHFOR,   "ID_SEARCHFOR"  },
        .{df.TEXT,     "~Replace for:",             2, 3, 1, 13, df.ID_REPLACEWITH, "ID_REPLACEWITH"},
        .{df.EDITBOX,  null,                       16, 3, 1, 29, df.ID_REPLACEWITH, "ID_REPLACEWITH"},
        .{df.TEXT,     "~Match upper/lower case:",  2, 5, 1, 23, df.ID_MATCHCASE,   "ID_MATCHCASE"  },
        .{df.CHECKBOX, null,                       26, 5, 1,  3, df.ID_MATCHCASE,   "ID_MATCHCASE"  },
        .{df.TEXT,     "Replace ~Every Match:",     2, 6, 1, 23, df.ID_REPLACEALL,  "ID_REPLACEALL" },
        .{df.CHECKBOX, null,                       26, 6, 1,  3, df.ID_REPLACEALL,  "ID_REPLACEALL" },
        .{df.BUTTON,   "   ~OK   ",                 7, 8, 1,  8, df.ID_OK,          "ID_OK"         },
        .{df.BUTTON,   " ~Cancel ",                20, 8, 1,  8, df.ID_CANCEL,      "ID_CANCEL"     },
        .{df.BUTTON,   "  ~Help  ",                33, 8, 1,  8, df.ID_HELP,        "ID_HELP"       },
    },
);

// -------------- generic message dialog box ---------------
pub const MsgBox:df.DBOX = buildDialog(
    "MsgBox",
    .{null, -1, -1, 0, 0},
    .{
        .{df.TEXT,   null, 1, 1, 0, 0, 0,            null       },
        .{df.BUTTON, null, 0, 0, 1, 8, df.ID_OK,     "ID_OK"    },
        .{0,         null, 0, 0, 1, 8, df.ID_CANCEL, "ID_CANCEL"},
    },
);

fn buildDialog(comptime help:[]const u8, comptime window:anytype, comptime controls:anytype) df.DBOX {
    var result:df.DBOX = undefined;

    var ttl: ?[]const u8 = undefined;
    var x: c_int = undefined;
    var y: c_int = undefined;
    var h: c_int = undefined;
    var w: c_int = undefined;
    ttl, x, y, h, w = window;

    result = .{
        .HelpName = @constCast(help.ptr),
        .dwnd = .{
            .title = if (ttl) |t| @constCast(t.ptr) else null,
            .x = x,
            .y = y,
            .h = h,
            .w = w,
        },
        .ctl = buildControls(controls),
    };

    return result;
}

fn buildControls(comptime controls:anytype) [df.MAXCONTROLS+1]df.CTLWINDOW {
    var result:[df.MAXCONTROLS+1]df.CTLWINDOW = undefined;
    inline for(0..(df.MAXCONTROLS+1)) |idx| {
        result[idx] = .{
            .Class = 0, // it use Class == 0 to indicate end of available controls
        };
    }
    inline for(controls, 0..) |control, idx| {
        var ty: c_int = undefined ;
        var tx: ?[]const u8 = undefined;
        var x: c_int = undefined;
        var y: c_int = undefined;
        var h: c_int = undefined;
        var w: c_int = undefined;
        var c: c_int = undefined;
        var help: ?[]const u8 = undefined;
        ty, tx, x, y, h, w, c, help = control;

        const itext = if ((ty == df.EDITBOX) or (ty == df.COMBOBOX)) null else if (tx) |t| @constCast(t.ptr) else null;
        result[idx] = .{
            .dwnd = .{.title = null, .x = x, .y = y, .h = h, .w = w},
            .Class = ty,
            .itext = itext,
            .command = c,
            .help = if (help) |name| @constCast(name.ptr) else null,
            .isetting = if (ty == df.BUTTON) df.ON else df.OFF,
            .setting = df.OFF,
            .wnd = null,
        };
    }

    return result;
}

//#define CONTROL(ty,tx,x,y,h,w,c)                                                \
//                                {{NULL,x,y,h,w},ty,                                             \
//                                (ty==EDITBOX||ty==COMBOBOX?NULL:tx),    \
//                                c,#c,(ty==BUTTON?ON:OFF),OFF,NULL},
//
//DIALOGBOX( MsgBox )
//    DB_TITLE(       NULL,  -1,-1, 0, 0)
//    CONTROL(TEXT,   NULL,   1, 1, 0, 0, 0)
//    CONTROL(BUTTON, NULL,   0, 0, 1, 8, ID_OK)
//    CONTROL(0,      NULL,   0, 0, 1, 8, ID_CANCEL)
//ENDDB

//const msgHelpName = "MsgBox";
//const MsgBox: df.DBOX = .{
//    .HelpName = @constCast(msgHelpName.ptr),
//    .dwnd = .{
//        .title = null,
//        .x = -1,
//        .y = -1,
//        .h = 0,
//        .w = 0,
//    },
//    .ctl = buildControls(.{
//        .{df.TEXT,   null, 1, 1, 0, 0, 0,            null       },
//        .{df.BUTTON, null, 0, 0, 1, 8, df.ID_OK,     "ID_OK"    },
//        .{0,         null, 0, 0, 1, 8, df.ID_CANCEL, "ID_CANCEL"},
//    }),
//};

