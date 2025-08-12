const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var Clipboard = std.ArrayList(u8).init(allocator);

// This also clear the items.
fn getClipboard() *std.ArrayList(u8) {
    var clipboard = &Clipboard;
    clipboard.clearRetainingCapacity();
    return clipboard;
}

pub fn CopyTextToClipboard(text:[*c]u8) void {
    const txt = std.mem.span(text);
//    const ClipboardLength = txt.len;
    var clipboard = getClipboard();
    if (clipboard.appendSlice(txt)) {
    } else |_| {
        // error
    }
}

pub fn CopyToClipboard(wnd:df.WINDOW) void {
    if (df.TextBlockMarked(wnd)) {
        const begCol:usize = @intCast(wnd.*.BlkBegCol);
        const endCol:usize = @intCast(wnd.*.BlkEndCol);
        const begLine:usize = @intCast(wnd.*.BlkBegLine);
        const endLine:usize = @intCast(wnd.*.BlkEndLine);
        const bbl = df.TextLine(wnd,begLine)+begCol;
        const bel = df.TextLine(wnd,endLine)+endCol;
        const ClipboardLength = bel - bbl;
        var clipboard = getClipboard();
        if (clipboard.appendSlice(bbl[0..ClipboardLength])) {
          
        } else |_| {
            // error;
        }
    }
}

pub fn ClearClipboard() void {
    if (Clipboard) |clipboard| {
        clipboard.deinit(); // df.free(Clipboard);
        Clipboard = null;
    }
}

pub fn PasteFromClipboard(wnd:df.WINDOW) bool {
    const text:[*c]u8 = Clipboard.items.ptr;
    const len = Clipboard.items.len;
    return PasteText(wnd, text, @intCast(len));
}

pub fn PasteText(wnd:df.WINDOW, SaveTo:[*c]u8, len:c_uint) bool {
    if (SaveTo != null and len > 0)    {
        const txt = std.mem.span(wnd.*.text);
        const plen = txt.len + len;

        if (plen <= wnd.*.MaxTextLength) {
            if (plen+1 > wnd.*.textlen) {
                wnd.*.text = @ptrCast(df.DFrealloc(wnd.*.text, plen+3));
                wnd.*.textlen = @intCast(plen+1);
            }
            var win:*Window = @constCast(@fieldParentPtr("win", &wnd));
            const cp:[*c]u8 = win.CurrChar();
            _ = df.memmove(cp+len, cp, df.strlen(cp)+1);
            _ = df.memmove(cp, SaveTo, len);
//            df.memmove(df.CurrChar+len, df.CurrChar, df.strlen(df.CurrChar)+1);
//            df.memmove(df.CurrChar, SaveTo, len);
            df.BuildTextPointers(wnd);
            wnd.*.TextChanged = df.TRUE;
            return true;
        }
    }
    return false;
}
