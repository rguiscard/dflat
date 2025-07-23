const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const DialogBox = @import("DialogBox.zig");
const msg = @import("Message.zig").Message;

// -------------- generic message dialog box ---------------
const MsgBox: DialogBox.DLBox = .{
    .HelpName = "MSGBox",
    .dwnd = .{
        .title = null,
        .x = -1,
        .y = -1,
        .h = 0,
        .w = 0,
    },
};

pub fn GetMsgBox() DialogBox.DLBox {
    const box = MsgBox;
    if (box.ctl[0] == null) { // not initialized
        box.addControl(df.TEXT,   null, 1, 1, 0, 0, 0);
        box.addControl(df.BUTTON, null, 0, 0, 1, 8, df.ID_OK);
        box.addControl(0,         null, 0, 0, 1, 8, df.ID_CANCEL);
    }
    return box;
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
