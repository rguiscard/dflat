const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

// ----- set focus to the next sibling -----
pub export fn SetNextFocus() callconv(.c) void {
    if (inFocus != NULL)    {
        WINDOW wnd1 = inFocus, pwnd;
        while (TRUE)    {
			pwnd = GetParent(wnd1);
            if (NextWindow(wnd1) != NULL)
				wnd1 = NextWindow(wnd1);
			else if (pwnd != NULL)
                wnd1 = FirstWindow(pwnd);
            if (wnd1 == NULL || wnd1 == inFocus)	{
				wnd1 = pwnd;
				break;
			}
			if (GetClass(wnd1) == STATUSBAR || GetClass(wnd1) == MENUBAR)
				continue;
            if (isVisible(wnd1))
                break;
        }
        if (wnd1 != NULL)	{
			while (wnd1->childfocus != NULL)
				wnd1 = wnd1->childfocus;
            if (wnd1->condition != ISCLOSING)
	            SendMessage(wnd1, SETFOCUS, TRUE, 0);
		}
    }
}

// ----- set focus to the previous sibling -----
pub export fn SetPrevFocus() callconv(.c) void {
    if (inFocus != NULL)    {
        WINDOW wnd1 = inFocus, pwnd;
        while (TRUE)    {
			pwnd = GetParent(wnd1);
            if (PrevWindow(wnd1) != NULL)
				wnd1 = PrevWindow(wnd1);
			else if (pwnd != NULL)
                wnd1 = LastWindow(pwnd);
            if (wnd1 == NULL || wnd1 == inFocus)	{
				wnd1 = pwnd;
				break;
			}
			if (GetClass(wnd1) == STATUSBAR)
				continue;
            if (isVisible(wnd1))
                break;
        }
        if (wnd1 != NULL)	{
			while (wnd1->childfocus != NULL)
				wnd1 = wnd1->childfocus;
            if (wnd1->condition != ISCLOSING)
	            SendMessage(wnd1, SETFOCUS, TRUE, 0);
		}
    }
}

// ------- move a window to the end of its parents list -----
pub export fn ReFocus(wnd:df.WINDOW) callconv(.c) void {
	if (GetParent(wnd) != NULL)	{
		RemoveWindow(wnd);
		AppendWindow(wnd);
		ReFocus(GetParent(wnd));
	}
}

// ---- remove a window from the linked list ----
pub export fn RemoveWindow(wnd:df.WINDOW) callconv(.c) void {
{
    if (wnd != NULL)    {
		WINDOW pwnd = GetParent(wnd);
        if (PrevWindow(wnd) != NULL)
            NextWindow(PrevWindow(wnd)) = NextWindow(wnd);
        if (NextWindow(wnd) != NULL)
            PrevWindow(NextWindow(wnd)) = PrevWindow(wnd);
		if (pwnd != NULL)	{
        	if (wnd == FirstWindow(pwnd))
            	FirstWindow(pwnd) = NextWindow(wnd);
        	if (wnd == LastWindow(pwnd))
            	LastWindow(pwnd) = PrevWindow(wnd);
		}
    }
}

// ---- append a window to the linked list ----
pub export fn AppendWindow(wnd:df.WINDOW) callconv(.c) void {
{
    if (wnd != null) {
        var pwnd = df.GetParent(wnd);
        if (pwnd != null) {
            if (pwnd.*.firstchild == null) {
            	pwnd.*.firstchild = wnd;
            }
            if (pwnd.*.lastchild != null) {
                const lw = pwnd.*.lastchild;
		lw.*.nextsibling = wnd;
//            	NextWindow(LastWindow(pwnd)) = wnd;
            }
        	PrevWindow(wnd) = LastWindow(pwnd);
	        LastWindow(pwnd) = wnd;
        }
	wnd.*.nextsibling = null;
    }
}

// ----- if document windows and statusbar or menubar get the focus,
//              pass it on -------
pub export fn SkipApplicationControls() callconv(.c) void {
    var EmptyAppl = false;
    var ct:isize = 0;
    while (!EmptyAppl and (df.inFocus != null))	{
        const cl = df.GetClass(df.inFocus);
        if (cl == df.MENUBAR or cl == df.STATUSBAR) {
	    SetPrevFocus();
            EmptyAppl = ((cl == df.MENUBAR) and (ct > 0));
	    ct += 1;
        } else {
            break;
        }
    }
}
