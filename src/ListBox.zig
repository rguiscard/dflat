const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

var py:c_int = -1; // the previous y mouse coordinate

//#ifdef INCLUDE_EXTENDEDSELECTIONS
// --------- SHIFT_F8 Key ------------
//static void AddModeKey(WINDOW wnd)
//{
//    if (isMultiLine(wnd))    {
//        wnd->AddMode ^= TRUE;
//        SendMessage(GetParent(wnd), ADDSTATUS,
//            wnd->AddMode ? ((PARAM) "Add Mode") : 0, 0);
//    }
//}
//#endif

// --------- UP (Up Arrow) Key ------------
//static void UpKey(WINDOW wnd, PARAM p2)
//{
//    if (wnd->selection > 0)    {
//        if (wnd->selection == wnd->wtop)    {
//            BaseWndProc(LISTBOX, wnd, KEYBOARD, UP, p2);
//            PostMessage(wnd, LB_SELECTION, wnd->selection-1,
//                isMultiLine(wnd) ? p2 : FALSE);
//        }
//        else    {
//            int newsel = wnd->selection-1;
//            if (wnd->wlines == ClientHeight(wnd))
//                while (*TextLine(wnd, newsel) == LINE)
//                    --newsel;
//            PostMessage(wnd, LB_SELECTION, newsel,
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//                isMultiLine(wnd) ? p2 :
//#endif
//                FALSE);
//        }
//    }
//}

// --------- DN (Down Arrow) Key ------------
//static void DnKey(WINDOW wnd, PARAM p2)
//{
//    if (wnd->selection < wnd->wlines-1)    {
//        if (wnd->selection == wnd->wtop+ClientHeight(wnd)-1)  {
//            BaseWndProc(LISTBOX, wnd, KEYBOARD, DN, p2);
//            PostMessage(wnd, LB_SELECTION, wnd->selection+1,
//                isMultiLine(wnd) ? p2 : FALSE);
//        }
//        else    {
//            int newsel = wnd->selection+1;
//            if (wnd->wlines == ClientHeight(wnd))
//                while (*TextLine(wnd, newsel) == LINE)
//                    newsel++;
//            PostMessage(wnd, LB_SELECTION, newsel,
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//                isMultiLine(wnd) ? p2 :
//#endif
//                FALSE);
//        }
//    }
//}

// --------- HOME and PGUP Keys ------------
//static void HomePgUpKey(WINDOW wnd, PARAM p1, PARAM p2)
//{
//    BaseWndProc(LISTBOX, wnd, KEYBOARD, p1, p2);
//    PostMessage(wnd, LB_SELECTION, wnd->wtop,
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        isMultiLine(wnd) ? p2 :
//#endif
//        FALSE);
//}

// --------- END and PGDN Keys ------------
//static void EndPgDnKey(WINDOW wnd, PARAM p1, PARAM p2)
//{
//    int bot;
//    BaseWndProc(LISTBOX, wnd, KEYBOARD, p1, p2);
//    bot = wnd->wtop+ClientHeight(wnd)-1;
//    if (bot > wnd->wlines-1)
//        bot = wnd->wlines-1;
//    PostMessage(wnd, LB_SELECTION, bot,
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        isMultiLine(wnd) ? p2 :
//#endif
//        FALSE);
//}

//#ifdef INCLUDE_EXTENDEDSELECTIONS
///* --------- Space Bar Key ------------
//static void SpacebarKey(WINDOW wnd, PARAM p2)
//{
//    if (isMultiLine(wnd))    {
//        int sel = SendMessage(wnd, LB_CURRENTSELECTION, 0, 0);
//        if (sel != -1)    {
//            if (wnd->AddMode)
//                FlipSelection(wnd, sel);
//            if (ItemSelected(wnd, sel))    {
//                if (!((int) p2 & (LEFTSHIFT | RIGHTSHIFT)))
//                    wnd->AnchorPoint = sel;
//                ExtendSelections(wnd, sel, (int) p2);
//            }
//            else
//                wnd->AnchorPoint = -1;
//            SendMessage(wnd, PAINT, 0, 0);
//        }
//    }
//}
//#endif

// --------- Enter ('\r') Key ------------
//static void EnterKey(WINDOW wnd)
//{
//    if (wnd->selection != -1)    {
//        SendMessage(wnd, LB_SELECTION, wnd->selection, TRUE);
//        SendMessage(wnd, LB_CHOOSE, wnd->selection, 0);
//    }
//}

// --------- All Other Key Presses ------------
//static void KeyPress(WINDOW wnd, PARAM p1, PARAM p2)
//{
//    int sel = wnd->selection+1;
//    while (sel < wnd->wlines)    {
//        char *cp = TextLine(wnd, sel);
//        if (cp == NULL)
//            break;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        if (isMultiLine(wnd))
//            cp++;
//#endif
//        if (tolower(*cp) == (int)p1)    {
//            SendMessage(wnd, LB_SELECTION, sel,
//                isMultiLine(wnd) ? p2 : FALSE);
//            if (!SelectionInWindow(wnd, sel))    {
//                wnd->wtop = sel-ClientHeight(wnd)+1;
//                SendMessage(wnd, PAINT, 0, 0);
//            }
//            break;
//        }
//        sel++;
//    }
//}

// --------- KEYBOARD Message ------------
//static int KeyboardMsg(WINDOW wnd, PARAM p1, PARAM p2)
//{
//    switch ((int) p1)    {
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        case SHIFT_F8:
//            AddModeKey(wnd);
//            return TRUE;
//#endif
//        case UP:
//            TestExtended(wnd, p2);
//            UpKey(wnd, p2);
//            return TRUE;
//        case DN:
//            TestExtended(wnd, p2);
//            DnKey(wnd, p2);
//            return TRUE;
//        case PGUP:
//        case HOME:
//            TestExtended(wnd, p2);
//            HomePgUpKey(wnd, p1, p2);
//            return TRUE;
//        case PGDN:
//        case END:
//            TestExtended(wnd, p2);
//            EndPgDnKey(wnd, p1, p2);
//            return TRUE;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        case ' ':
//            SpacebarKey(wnd, p2);
//            break;
//#endif
//        case '\r':
//            EnterKey(wnd);
//            return TRUE;
//        default:
//            KeyPress(wnd, p1, p2);
//            break;
//    }
//    return FALSE;
//}

// ------- LEFT_BUTTON Message --------
fn LeftButtonMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) c_int {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
    var my:c_int = @intCast(p2 - win.GetTop());
    if (my >= (wnd.*.wlines-wnd.*.wtop)) {
        my = wnd.*.wlines - wnd.*.wtop;
    }
    if (df.cInsideRect(@intCast(p1), @intCast(p2), df.ClientRect(wnd)) == 0) {
        return df.FALSE;
    }
    if ((wnd.*.wlines > 0) and (my != py)) {
        const sel = wnd.*.wtop+my-1;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        int sh = getshift();
//        if (!(sh & (LEFTSHIFT | RIGHTSHIFT)))    {
//            if (!(sh & CTRLKEY))
//                ClearAllSelections(wnd);
//            wnd->AnchorPoint = sel;
//            SendMessage(wnd, PAINT, 0, 0);
//        }
//#endif
        _ = df.SendMessage(wnd, df.LB_SELECTION, sel, df.TRUE);
        py = my;
    }
    return df.TRUE;
}

// ------------- DOUBLE_CLICK Message ------------
fn DoubleClickMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) c_int {
    if ((df.WindowMoving != 0) or (df.WindowSizing != 0))
        return df.FALSE;
    if (wnd.*.wlines > 0) {
        const rc = df.ClientRect(wnd);
        _ = root.BaseWndProc(df.LISTBOX, wnd, df.DOUBLE_CLICK, p1, p2);
        if (df.cInsideRect(@intCast(p1), @intCast(p2), rc) != 0)
            _ = df.SendMessage(wnd, df.LB_CHOOSE, wnd.*.selection, 0);
    }
    return df.TRUE;
}

// ------------ ADDTEXT Message --------------
fn AddTextMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) c_int {
    const rtn = root.BaseWndProc(df.LISTBOX, wnd, df.ADDTEXT, p1, p2);
    if (wnd.*.selection == -1)
        _ = df.SendMessage(wnd, df.LB_SETSELECTION, 0, 0);
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//    if (*(char *)p1 == LISTSELECTOR)
//        wnd->SelectCount++;
//#endif
    return rtn;
}

// --------- GETTEXT Message ------------
fn GetTextMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) void {
    if (p2 != -1) {
        const p2_addr:usize = @intCast(p2);
        const cp2 = df.TextLine(wnd, p2_addr);
        const cp1:[:0]u8 = @ptrCast(std.mem.sliceTo(cp2, '\n'));
        const p1_addr:usize = @intCast(p1);
        const dst:*[1024]u8 = @ptrFromInt(p1_addr);
        _ = df.strncpy(dst, cp1.ptr, cp1.len);
        // FIXME: this is not safe:
        // 1. it assume buffer is 1024
        // 2. it assume buffer is zeroed
    }
//    if ((int)p2 != -1)    {
//        char *cp1 = (char *)p1;
//        char *cp2 = TextLine(wnd, (int)p2);
//        while (cp2 && *cp2 && *cp2 != '\n')
//            *cp1++ = *cp2++;
//        *cp1 = '\0';
//    }
}

// --------- LISTBOX Window Processing Module ------------
pub export fn ListBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
//    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
    switch (message)    {
        df.CREATE_WINDOW => {
            _ = root.BaseWndProc(df.LISTBOX, wnd, message, p1, p2);
            wnd.*.selection = -1;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//            wnd->AnchorPoint = -1;
//#endif
            return df.TRUE;
        },
        df.KEYBOARD => {
//            if (WindowMoving || WindowSizing)
//                break;
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
	},
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(wnd, p1, p2) == df.TRUE)
                return df.TRUE;
        },
        df.DOUBLE_CLICK => {
            if (DoubleClickMsg(wnd, p1, p2) == df.TRUE)
                return df.TRUE;
	},
        df.BUTTON_RELEASED => {
            if ((df.WindowMoving > 0) or (df.WindowSizing > 0) or (df.VSliding > 0)) {
//                break;
            } else {
                py = -1;
                return df.TRUE;
            }
	},
        df.ADDTEXT => {
            return AddTextMsg(wnd, p1, p2);
	},
        df.LB_GETTEXT => {
            GetTextMsg(wnd, p1, p2);
            return df.TRUE;
	},
        df.CLEARTEXT => {
            wnd.*.selection = -1;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//            wnd->AnchorPoint = -1;
//#endif
            wnd.*.SelectCount = 0;
	},
        df.PAINT => {
            _ = root.BaseWndProc(df.LISTBOX, wnd, message, p1, p2);
            if (p1 != 0) {
                const p1_addr:usize = @intCast(p1);
                const rect_ptr:*df.RECT = @ptrFromInt(p1_addr);
                WriteSelection(wnd, wnd.*.selection, df.TRUE, rect_ptr);
            } else {
                WriteSelection(wnd, wnd.*.selection, df.TRUE, null);
            }
            return df.TRUE;
	},
        df.SETFOCUS => {
            _ = root.BaseWndProc(df.LISTBOX, wnd, message, p1, p2);
            if (p1 != 0) {
                WriteSelection(wnd, wnd.*.selection, df.TRUE, null);
            }
            return df.TRUE;
	},
        df.SCROLL, df.HORIZSCROLL, df.SCROLLPAGE, df.HORIZPAGE, df.SCROLLDOC => {
            _ = root.BaseWndProc(df.LISTBOX, wnd, message, p1, p2);
            WriteSelection(wnd,wnd.*.selection,df.TRUE,null);
            return df.TRUE;
	},
        df.LB_CHOOSE => {
            _ = df.SendMessage(df.GetParent(wnd), df.LB_CHOOSE, p1, p2);
            return df.TRUE;
	},
        df.LB_SELECTION => {
            ChangeSelection(wnd, @intCast(p1), @intCast(p2));
            _ = df.SendMessage(df.GetParent(wnd), df.LB_SELECTION, wnd.*.selection, 0);
            return df.TRUE;
        },
        df.LB_CURRENTSELECTION => {
            return wnd.*.selection;
	},
        df.LB_SETSELECTION => {
            ChangeSelection(wnd, @intCast(p1), 0);
            return df.TRUE;
	},
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        case CLOSE_WINDOW:
//            if (isMultiLine(wnd) && wnd->AddMode)    {
//                wnd->AddMode = FALSE;
//                SendMessage(GetParent(wnd), ADDSTATUS, 0, 0);
//            }
//            break;
//#endif
        else => {
        }
    }
    return root.BaseWndProc(df.LISTBOX, wnd, message, p1, p2);
}

fn SelectionInWindow(wnd:df.WINDOW, sel:c_int) df.BOOL {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
    if ((wnd.*.wlines != 0) and (sel >= wnd.*.wtop) and
            (sel < wnd.*.wtop+win.ClientHeight())) {
        return df.TRUE;
    } else {
        return df.FALSE;
    }
}

fn WriteSelection(wnd:df.WINDOW, sel:c_int, reverse:c_int, rc:?*df.RECT) void {
    if (df.isVisible(wnd) > 0) {
        if (SelectionInWindow(wnd, sel) > 0) {
            df.WriteTextLine(wnd, rc, sel, @intCast(reverse));
        }
    }
}

//#ifdef INCLUDE_EXTENDEDSELECTIONS
// ----- Test for extended selections in the listbox -----
//static void TestExtended(WINDOW wnd, PARAM p2)
//{
//    if (isMultiLine(wnd) && !wnd->AddMode &&
//            !((int) p2 & (LEFTSHIFT | RIGHTSHIFT)))    {
//        if (wnd->SelectCount > 1)    {
//            ClearAllSelections(wnd);
//            SendMessage(wnd, PAINT, 0, 0);
//        }
//    }
//}

// ----- Clear selections in the listbox -----
//static void ClearAllSelections(WINDOW wnd)
//{
//    if (isMultiLine(wnd) && wnd->SelectCount > 0)    {
//        int sel;
//        for (sel = 0; sel < wnd->wlines; sel++)
//            ClearSelection(wnd, sel);
//    }
//}

// ----- Invert a selection in the listbox -----
//static void FlipSelection(WINDOW wnd, int sel)
//{
//    if (isMultiLine(wnd))    {
//        if (ItemSelected(wnd, sel))
//            ClearSelection(wnd, sel);
//        else
//            SetSelection(wnd, sel);
//    }
//}

//static int ExtendSelections(WINDOW wnd, int sel, int shift)
//{    
//    if (shift & (LEFTSHIFT | RIGHTSHIFT) &&
//                        wnd->AnchorPoint != -1)    {
//        int i = sel;
//        int j = wnd->AnchorPoint;
//        int rtn;
//        if (j > i)
//            swap(i,j);
//        rtn = i - j;
//        while (j <= i)
//            SetSelection(wnd, j++);
//        return rtn;
//    }
//    return 0;
//}

//static void SetSelection(WINDOW wnd, int sel)
//{
//    if (isMultiLine(wnd) && !ItemSelected(wnd, sel))    {
//        char *lp = TextLine(wnd, sel);
//        *lp = LISTSELECTOR;
//        wnd->SelectCount++;
//    }
//}

//static void ClearSelection(WINDOW wnd, int sel)
//{
//    if (isMultiLine(wnd) && ItemSelected(wnd, sel))    {
//        char *lp = TextLine(wnd, sel);
//        *lp = ' ';
//        --wnd->SelectCount;
//    }
//}

//BOOL ItemSelected(WINDOW wnd, int sel)
//{
//    if (sel != -1 && isMultiLine(wnd) && sel < wnd->wlines)    {
//        char *cp = TextLine(wnd, sel);
//        return (int)((*cp) & 255) == LISTSELECTOR;
//    }
//    return FALSE;
//}
//#endif

fn ChangeSelection(wnd:df.WINDOW, sel:c_int, shift:c_int) void {
    if (sel != wnd.*.selection) {
        _ = shift;
//#ifdef INCLUDE_EXTENDEDSELECTIONS
//        if (sel != -1 && isMultiLine(wnd))        {
//            int sels;
//            if (!wnd->AddMode)
//                ClearAllSelections(wnd);
//            sels = ExtendSelections(wnd, sel, shift);
//            if (sels > 1)
//                SendMessage(wnd, PAINT, 0, 0);
//            if (sels == 0 && !wnd->AddMode)    {
//                ClearSelection(wnd, wnd->selection);
//                SetSelection(wnd, sel);
//                wnd->AnchorPoint = sel;
//            }
//        }
//#endi
        WriteSelection(wnd, wnd.*.selection, df.FALSE, null);
        wnd.*.selection = sel;
        if (sel != -1) {
            WriteSelection(wnd, sel, df.TRUE, null);
        }
    }
}
