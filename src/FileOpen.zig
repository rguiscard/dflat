const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

// Dialog Box to select a file to open
pub fn OpenFileDialogBox(Fspec:[]const u8, Fname:[*c]u8) bool {
    var fBox = df.c_FileOpen();
    return DlgFileOpen(Fspec, Fspec, Fname, &fBox);
}

// Dialog Box to select a file to save as
pub fn SaveAsDialogBox(Fspec:[]const u8, Sspec:?[]const u8, Fname:[*c]u8) bool {
    var sBox = df.c_SaveAs();
    return DlgFileOpen(Fspec, Sspec orelse Fspec, Fname, &sBox);
}

// --------- generic file open ----------
pub fn DlgFileOpen(Fspec: []const u8, Sspec: []const u8, Fname:[*c]u8, db: *df.DBOX) bool {
    const fspec = @constCast(Fspec.ptr);
    const sspec = @constCast(Sspec.ptr);
    const result = df.DlgFileOpen(fspec, sspec, Fname, db);
    return (result > 0);
}
