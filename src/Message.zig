const std = @import("std");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");

// ----------- dflatmsg.h ------------

// message foundation file
// make message changes here
// other source files will adapt

pub const Message = enum (c_int) {
    // -------------- process communication messages -----------
    START = df.START,                    // start message processing
    STOP = df.STOP,                      // stop message processing
    COMMAND = df.COMMAND,                // send a command to a window
    // -------------- window management messages ---------------
    CREATE_WINDOW = df.CREATE_WINDOW,    // create a window
    OPEN_WINDOW = df.OPEN_WINDOW,        // open a window
    SHOW_WINDOW = df.SHOW_WINDOW,        // show a window
    HIDE_WINDOW = df.HIDE_WINDOW,        // hide a window
    CLOSE_WINDOW = df.CLOSE_WINDOW,      // delete a window
    SETFOCUS = df.SETFOCUS,              // set and clear the focus
    PAINT = df.PAINT,                    // paint the window's data space
    BORDER = df.BORDER,                  // paint the window's border
    TITLE = df.TITLE,                    // display the window's title
    MOVE = df.MOVE,                      // move the window
    SIZE = df.SIZE,                      // change the window's size
    MAXIMIZE = df.MAXIMIZE,              // maximize the window
    MINIMIZE = df.MINIMIZE,              // minimize the window
    RESTORE = df.RESTORE,                // restore the window
    INSIDE_WINDOW = df.INSIDE_WINDOW,    // test x/y inside a window
    // ---------------- clock messages -------------------------
    CLOCKTICK = df.CLOCKTICK,            // the clock ticked
    CAPTURE_CLOCK = df.CAPTURE_CLOCK,    // capture clock into a window
    RELEASE_CLOCK = df.RELEASE_CLOCK,    // release clock to the system
    // -------------- keyboard and screen messages -------------
    KEYBOARD = df.KEYBOARD,                   // key was pressed
    CAPTURE_KEYBOARD = df.CAPTURE_KEYBOARD,   // capture keyboard into a window
    RELEASE_KEYBOARD = df.RELEASE_KEYBOARD,   // release keyboard to system
    KEYBOARD_CURSOR = df.KEYBOARD_CURSOR,     // position the keyboard cursor
    CURRENT_KEYBOARD_CURSOR = df.CURRENT_KEYBOARD_CURSOR, //read the cursor position
    HIDE_CURSOR = df.HIDE_CURSOR,             // hide the keyboard cursor
    SHOW_CURSOR = df.SHOW_CURSOR,             // display the keyboard cursor
    SAVE_CURSOR = df.SAVE_CURSOR,             // save the cursor's configuration
    RESTORE_CURSOR = df.RESTORE_CURSOR,       // restore the saved cursor
    SHIFT_CHANGED = df.SHIFT_CHANGED,         // the shift status changed
    WAITKEYBOARD = df.WAITKEYBOARD,           // waits for a key to be released
    // ---------------- mouse messages -------------------------
    RESET_MOUSE = df.RESET_MOUSE,             // reset the mouse
    MOUSE_TRAVEL = df.MOUSE_TRAVEL,           // set the mouse travel
    MOUSE_INSTALLED = df.MOUSE_INSTALLED,     // test for mouse installed
    RIGHT_BUTTON = df.RIGHT_BUTTON,           // right button pressed
    LEFT_BUTTON = df.LEFT_BUTTON,             // left button pressed
    DOUBLE_CLICK = df.DOUBLE_CLICK,           // left button double-clicked
    MOUSE_MOVED = df.MOUSE_MOVED,             // mouse changed position
    BUTTON_RELEASED = df.BUTTON_RELEASED,     // mouse button released
    CURRENT_MOUSE_CURSOR = df.CURRENT_MOUSE_CURSOR, // get mouse position
    MOUSE_CURSOR = df.MOUSE_CURSOR,           // set mouse position
    SHOW_MOUSE = df.SHOW_MOUSE,               // make mouse cursor visible
    HIDE_MOUSE = df.HIDE_MOUSE,               // hide mouse cursor
    WAITMOUSE = df.WAITMOUSE,                 // wait until button released
    TESTMOUSE = df.TESTMOUSE,                 // test any mouse button pressed
    CAPTURE_MOUSE = df.CAPTURE_MOUSE,         // capture mouse into a window
    RELEASE_MOUSE = df.RELEASE_MOUSE,         // release the mouse to system
    // ---------------- text box messages ----------------------
    ADDTEXT = df.ADDTEXT,                     // append text to the text box
    INSERTTEXT = df.INSERTTEXT,               // insert line of text
    DELETETEXT = df.DELETETEXT,               // delete line of text
    CLEARTEXT = df.CLEARTEXT,                 // clear the edit box
    SETTEXT = df.SETTEXT,                     // copy text to text buffer
    SCROLL = df.SCROLL,                       // vertical line scroll
    HORIZSCROLL = df.HORIZSCROLL,             // horizontal column scroll
    SCROLLPAGE = df.SCROLLPAGE,               // vertical page scroll
    HORIZPAGE = df.HORIZPAGE,                 // horizontal page scroll
    SCROLLDOC = df.SCROLLDOC,                 // scroll to beginning/end
    // ---------------- edit box messages ----------------------
    GETTEXT = df.GETTEXT,                     // get text from an edit box
    SETTEXTLENGTH = df.SETTEXTLENGTH,         // set maximum text length
    // ---------------- menubar messages -----------------------
    BUILDMENU = df.BUILDMENU,                 // build the menu display
    MB_SELECTION = df.MB_SELECTION,           // menubar selection
    // ---------------- popdown messages -----------------------
    BUILD_SELECTIONS = df.BUILD_SELECTIONS,   // build the menu display
    CLOSE_POPDOWN = df.CLOSE_POPDOWN,         // tell parent popdown is closing
    // ---------------- list box messages ----------------------
    LB_SELECTION = df.LB_SELECTION,           // sent to parent on selection
    LB_CHOOSE = df.LB_CHOOSE,                 // sent when user chooses
    LB_CURRENTSELECTION = df.LB_CURRENTSELECTION, // return the current selection
    LB_GETTEXT = df.LB_GETTEXT,               // return the text of selection
    LB_SETSELECTION = df.LB_SETSELECTION,     // sets the listbox selection
    // ---------------- dialog box messages --------------------
    INITIATE_DIALOG = df.INITIATE_DIALOG,     // begin a dialog
    ENTERFOCUS = df.ENTERFOCUS,               // tell DB control got focus
    LEAVEFOCUS = df.LEAVEFOCUS,               // tell DB control lost focus
    ENDDIALOG = df.ENDDIALOG,                 // end a dialog
    // ---------------- help box messages ----------------------
    DISPLAY_HELP = df.DISPLAY_HELP,
    // --------------- application window messages -------------
    ADDSTATUS = df.ADDSTATUS,
    // --------------- picture box messages --------------------
    DRAWVECTOR = df.DRAWVECTOR,
    DRAWBOX = df.DRAWBOX,
    DRAWBAR = df.DRAWBAR,
};

// ------------ initialize the message system ---------
pub fn init_messages() bool {
    return (df.init_messages() > 0);
}

// ---- dispatch messages to the message proc function ----
pub fn dispatch_message() bool {
    return (df.dispatch_message() > 0);
}
