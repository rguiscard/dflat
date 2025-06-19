const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const msg = @import("Message.zig").Message;
const msgbox = @import("MessageBox.zig");
const command = @import("Commands.zig").Command;
const Window = @import("Window.zig");

var CheckCase = true;
var Replacing = false;
var lastsize:usize = 0;
var search_box:*df.DBOX = undefined; // keep a copy of box so that values will not disappear for unknown reason

// - case-insensitive, white-space-normalized char compare -
fn SearchCmp(a:u8, b:u8) bool {
    _ = a;
    _ = b;
//    if (b == '\n')
//        b = ' ';
//    if (CheckCase)
//        return a != b;
//    return tolower(a) != tolower(b);
    return true;
}

// ----- replace a matching block of text -----
fn replacetext(wnd:df.WINDOW, cp1:[]const u8, db:*df.DBOX) void {
    _ = wnd;
    _ = cp1;
    _ = db;
//    char *cr = GetEditBoxText(db, ID_REPLACEWITH);
//    char *cp = GetEditBoxText(db, ID_SEARCHFOR);
//    int oldlen = strlen(cp); /* length of text being replaced */
//    int newlen = strlen(cr); /* length of replacing text      */
//    int dif;
//        lastsize = newlen;
//    if (oldlen < newlen)    {
//        /* ---- new text expands text size ---- */
//        dif = newlen-oldlen;
//        if (wnd->textlen < strlen(wnd->text)+dif)    {
//            /* ---- need to reallocate the text buffer ---- */
//            int offset = (int)(cp1-(char *)wnd->text);
//            wnd->textlen += dif;
//            wnd->text = DFrealloc(wnd->text, wnd->textlen+2);
//            cp1 = wnd->text + offset;
//        }
//        memmove(cp1+dif, cp1, strlen(cp1)+1);
//    }
//    else if (oldlen > newlen)    {
//        /* ---- new text collapses text size ---- */
//        dif = oldlen-newlen;
//        memmove(cp1, cp1+dif, strlen(cp1)+1);
//    }
//    strncpy(cp1, cr, newlen);
}

fn BlkEndColFromLine(wnd: df.WINDOW, cp:[*c]u8) c_int {
    const sel:usize = @intCast(wnd.*.BlkEndLine);
    return @intCast(cp-df.TextLine(wnd, sel));
}

fn BlkBegColFromLine(wnd: df.WINDOW, cp:[*c]u8) c_int {
    const sel:usize = @intCast(wnd.*.BlkBegLine);
    return @intCast(cp-df.TextLine(wnd, sel));
}

// ------- search for the occurrance of a string ------- 
fn SearchTextBox(wnd:df.WINDOW, incr:bool) void {
    // Confirm window type
    if (wnd.*.Class != df.EDITBOX) {
        _ = msgbox.ErrorMessage("Window is not a EDITBOX");
        return;
    }

    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
//    char *s1 = NULL, *s2, *cp1;
    var cp1:[*c]u8 = null;
    const cp = df.GetEditBoxText(search_box, @intFromEnum(command.ID_SEARCHFOR));
    var FoundOne = false;
    var rpl = true;
    while ((rpl == true) and (cp != null) and (df.strlen(cp) > 0)) {
        if (Replacing) {
            rpl = (df.CheckBoxSetting(search_box, @intFromEnum(command.ID_REPLACEALL)) > 0);
        } else {
            rpl = false;
        }
        if (win.TextBlockMarked()) {
            win.ClearTextBlock();
            _ = win.sendMessage(msg.PAINT, 0, 0);
        }

        cp1 = win.CurrChar();
        if (incr) {
            cp1 = cp1 + lastsize; // start past the last hit
        }
        // --- compare at each character position ---
        const zp = std.mem.span(cp);
        const zp1 = std.mem.span(cp1);
        var index:?usize = null;
        // FIXME: original code is whitespace normalized ('\n' -> ' ')
        if (CheckCase) {
            index = std.ascii.indexOfIgnoreCase(zp1, zp);
        } else {
            index = std.mem.indexOf(u8, zp1, zp);
        }
        if (index) |i| {
            // ----- match at *cp1 -------
            FoundOne = true;

            // mark a block at beginning of matching text
            cp1 = cp1+i;
            const s2 = cp1+zp.len;
            wnd.*.BlkEndLine = df.TextLineNumber(wnd, s2);
            wnd.*.BlkBegLine = df.TextLineNumber(wnd, cp1);
            if (wnd.*.BlkEndLine < wnd.*.BlkBegLine) {
                wnd.*.BlkEndLine = wnd.*.BlkBegLine;
            }
            wnd.*.BlkEndCol = BlkEndColFromLine(wnd, s2);
            wnd.*.BlkBegCol = BlkBegColFromLine(wnd, cp1);

            // position the cursor at the matching text
            wnd.*.CurrCol = wnd.*.BlkBegCol;
            wnd.*.CurrLine = wnd.*.BlkBegLine;
            wnd.*.WndRow = wnd.*.CurrLine - wnd.*.wtop;

            // -- remember the size of the matching text --
            lastsize = df.strlen(cp);

            // align the window scroll to matching text
            if (win.WndCol() > (win.ClientWidth()-1)) {
                wnd.*.wleft = wnd.*.CurrCol;
            }
            if (wnd.*.WndRow > (win.ClientHeight()-1)) {
                wnd.*.wtop = wnd.*.CurrLine;
                wnd.*.WndRow = 0;
            }

            _ = win.sendMessage(msg.PAINT, 0, 0);
            _ = win.sendMessage(msg.KEYBOARD_CURSOR, win.WndCol(), wnd.*.WndRow);

//            if (Replacing)    {
//                if (rpl || YesNoBox("Replace the text?"))  {
//                    replacetext(wnd, cp1, db);
//                    wnd->TextChanged = TRUE;
//                    BuildTextPointers(wnd);
//                        if (rpl)    {
//                        incr = TRUE;
//                        continue;
//                        }
//                }
//                win.ClearTextBlock();
//                _ = win.sendMessage(msg.PAINT, 0, 0);
//            }
            return;
        }
        break;
    }
    if (FoundOne == false) {
        _ = msgbox.MessageBox("Search/Replace Text", "No match found");
    }
}

// ------- search for the occurrance of a string,
//         replace it with a specified string -------
pub fn ReplaceText(wnd:df.WINDOW) void {
    Replacing = true;
    lastsize = 0;
    var box = df.c_ReplaceTextDB();
    search_box = &box;
    if (CheckCase) {
        df.SetCheckBox(&box, @intFromEnum(command.ID_MATCHCASE));
    }
    if (df.DialogBox(null, &box, df.TRUE, null) > 0) {
        CheckCase = (df.CheckBoxSetting(&box, @intFromEnum(command.ID_MATCHCASE)) > 0);
        SearchTextBox(wnd, false);
    }
}

// ------- search for the first occurrance of a string ------
pub fn SearchText(wnd:df.WINDOW) void {
    Replacing = false;
    lastsize = 0;
    var box = df.c_SearchTextDB();
    search_box = &box;
    if (CheckCase) {
        df.SetCheckBox(&box, @intFromEnum(command.ID_MATCHCASE));
    }
    if (df.DialogBox(null, &box, df.TRUE, null) > 0) {
        CheckCase = (df.CheckBoxSetting(&box, @intFromEnum(command.ID_MATCHCASE)) > 0);
        SearchTextBox(wnd, false);
    }
}

// ------- search for the next occurrance of a string -------
pub fn SearchNext(wnd:df.WINDOW) void {
    SearchTextBox(wnd, true);
}
