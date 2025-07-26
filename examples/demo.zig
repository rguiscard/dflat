const std = @import("std");
const mp = @import("memopad");
const df = mp.df;
const message = mp.msg.Message;

var filename: [1024]u8 = undefined;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    try run_dflat_app();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stdout_file);
//    const stdout = bw.writer();

//    var filename_it = std.mem.splitScalar(u8, &filename, 0);
//    const path = try std.fs.cwd().realpathAlloc(allocator, filename_it.first());
//    try stdout.print("{s}\n", .{path});
    try bw.flush(); // Don't forget to flush!
}

fn run_dflat_app() !void {
    if (mp.msg.init_messages() == false)
        return;

    // set global allocator for all callback in dflat.zig
    mp.setGlobalAllocator(allocator);

    var win = mp.Window.create(df.APPLICATION, // Win
                        "D-Flat MemoPad",
                        0, 0, -1, -1,
                        &df.MainMenu,
                        null,
                        MainProc,
                        df.MOVEABLE  |
                        df.SIZEABLE  |
                        df.HASBORDER |
                        df.MINMAXBOX |
                        df.HASSTATUSBAR,
                        allocator);

    _ = win.sendMessage(message.SETFOCUS, df.TRUE, 0);

//    _ = mp.watch.WatchIcon();

//    Box();
    Calendar(win);

    while (mp.msg.dispatch_message()) {
    }

    return;
}

fn Calendar(win:mp.Window) void {
    _ = mp.calendar.Calendar(win.win);
}

fn Box() void {
    const bwnd = mp.Window.create(
                    df.BOX,
                    "Box",
                    4, 5, 10, 15,
                    null, null,
                    BoxProc,
                    df.VISIBLE | df.HASBORDER | df.SHADOW | df.SAVESELF,
                    allocator);
    _ = bwnd;
}

fn BoxProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    return mp.DefaultWndProc(wnd, msg, p1, p2);
}

fn MainProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (msg)    {
        df.COMMAND => {
            switch (p1)    {
                df.ID_OPEN => {
                },
                else => {
                }
            }
        },
        else => {
        }
    }
    return df.ApplicationProc(wnd, msg, p1, p2);
}

