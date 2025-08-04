const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

// This seems not in use.
pub export fn TextProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message)    {
        df.SETFOCUS => {
            return df.TRUE;
        },
        df.LEFT_BUTTON => {
            return df.TRUE;
        },
        df.PAINT => {
            df.drawText(wnd);
        },
        else => {
        }
    }
    return root.BaseWndProc(df.SPINBUTTON, wnd, message, p1, p2);
}

//void drawText(WINDOW wnd) {
//    int i, len;
//    CTLWINDOW *ct = GetControl(wnd);
//    char *cp, *cp2 = ct->itext;
//    if (ct == NULL ||
//        ct->itext == NULL ||
//            GetText(wnd) != NULL)
//                return;
//    len = min(ct->dwnd.h, MsgHeight(cp2));
//    cp = cp2;
//    for (i = 0; i < len; i++)    {
//        int mlen;
//        char *txt = cp;
//        char *cp1 = cp;
//        char *np = strchr(cp, '\n');
//        mlen = strlen(cp);
//        while ((cp1=strchr(cp1,SHORTCUTCHAR)) != NULL) {
//            mlen += 3;
//            cp1++;
//        }
//        txt = DFmalloc(mlen+1);
//        CopyCommand(txt, cp, FALSE, WndBackground(wnd));
//        txt[mlen] = '\0';
//        SendMessage(wnd, ADDTEXT, (PARAM)txt, 0);
//        if ((cp = strchr(cp, '\n')) != NULL)
//            cp++;
//        free(txt);
//    }
//}
