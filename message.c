/* --------- message.c ---------- */

#include "dflat.h"

//static int px = -1, py = -1;
//static int pmx = -1, pmy = -1;
//static int mx, my;
static int handshaking = 0;
BOOL AllocTesting = FALSE;
jmp_buf AllocError;
BOOL AltDown = FALSE;

/* ---------- event queue ---------- */
static struct events    {
    MESSAGE event;
    int mx;
    int my;
} EventQueue[MAXMESSAGES];

/* ---------- message queue --------- */
static struct msgs {
    WINDOW wnd;
    MESSAGE msg;
    PARAM p1;
    PARAM p2;
} MsgQueue[MAXMESSAGES];

static int EventQueueOnCtr;
static int EventQueueOffCtr;
static int EventQueueCtr;

static int MsgQueueOnCtr;
static int MsgQueueOffCtr;
static int MsgQueueCtr;

static int lagdelay = FIRSTDELAY;

static volatile int keyportvalue;	/* for watching for key release */

WINDOW CaptureMouse;
WINDOW CaptureKeyboard;
static BOOL NoChildCaptureMouse;
static BOOL NoChildCaptureKeyboard;

static volatile int delaytimer  = -1;
static volatile int clocktimer  = -1;
char time_string[] = "         ";

static WINDOW Cwnd;

static void StopMsg(void)
{
#ifndef BUILD_SMALL_DFLAT
	ClearClipboard();
	ClearDialogBoxes();
#endif
	restorecursor();	
	unhidecursor();
    hide_mousecursor();
}

int ProcessMessage(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);

/* ------------ initialize the message system --------- */
BOOL init_messages(void)
{
    int cols, rows;

	AllocTesting = TRUE;
	if (setjmp(AllocError) != 0)	{
		StopMsg();
		return FALSE;
	}
    tty_init(MouseTracking|CatchISig|ExitLastLine|FullBuffer);
    if (tty_getsize(&cols, &rows) > 0) {
        SCREENWIDTH = min(cols, MAXCOLS-1);
        SCREENHEIGHT = rows - 1;
    }
    resetmouse();
	set_mousetravel(0, SCREENWIDTH-1, 0, SCREENHEIGHT-1);
	savecursor();
	hidecursor();
//    px = py = -1;
//    pmx = pmy = -1;
//    mx = my = 0;
    CaptureMouse = CaptureKeyboard = NULL;
    NoChildCaptureMouse = FALSE;
    NoChildCaptureKeyboard = FALSE;
    MsgQueueOnCtr = MsgQueueOffCtr = MsgQueueCtr = 0;
    EventQueueOnCtr = EventQueueOffCtr = EventQueueCtr = 0;
    PostMessage(NULL,START,0,0);
    lagdelay = FIRSTDELAY;
	return TRUE;
}

/* ----- post an event and parameters to event queue ---- */
void PostEvent(MESSAGE event, int p1, int p2)
{
    if (EventQueueCtr != MAXMESSAGES)    {
        EventQueue[EventQueueOnCtr].event = event;
        EventQueue[EventQueueOnCtr].mx = p1;
        EventQueue[EventQueueOnCtr].my = p2;
        if (++EventQueueOnCtr == MAXMESSAGES)
            EventQueueOnCtr = 0;
        EventQueueCtr++;
    }
}

/* ----- post a message and parameters to msg queue ---- */
void PostMessage(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    if (MsgQueueCtr != MAXMESSAGES)    {
        MsgQueue[MsgQueueOnCtr].wnd = wnd;
        MsgQueue[MsgQueueOnCtr].msg = msg;
        MsgQueue[MsgQueueOnCtr].p1 = p1;
        MsgQueue[MsgQueueOnCtr].p2 = p2;
        if (++MsgQueueOnCtr == MAXMESSAGES)
            MsgQueueOnCtr = 0;
        MsgQueueCtr++;
    }
}

/* --------- send a message to a window ----------- */
int SendMessage(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    int rtn = TRUE, x, y;

#ifdef INCLUDE_LOGGING
	LogMessages(wnd, msg, p1, p2);
#endif
    if (wnd != NULL) {
        switch (msg)    {
            case PAINT:
            case BORDER:
                /* ------- don't send these messages unless the
                    window is visible -------- */
                if (isVisible(wnd))
	                rtn = (*wnd->wndproc)(wnd, msg, p1, p2);
                break;
            case RIGHT_BUTTON:
            case LEFT_BUTTON:
            case DOUBLE_CLICK:
            case BUTTON_RELEASED:
                /* --- don't send these messages unless the
                    window is visible or has captured the mouse -- */
                if (isVisible(wnd) || wnd == CaptureMouse)
	                rtn = (*wnd->wndproc)(wnd, msg, p1, p2);
                break;
            case KEYBOARD:
            case SHIFT_CHANGED:
                /* ------- don't send these messages unless the
                    window is visible or has captured the keyboard -- */
                if (!(isVisible(wnd) || wnd == CaptureKeyboard))
	                break;
            default:
                rtn = (*wnd->wndproc)(wnd, msg, p1, p2);
                break;
        }
    }
    /* ----- window processor returned true or the message was sent
        to no window at all (NULL) ----- */
    if (rtn != FALSE)    {
        rtn = ProcessMessage(wnd, msg, p1, p2);
    }
    return rtn;
}

// This one follows SendMessage();
int ProcessMessage(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    int rtn = TRUE, x, y;
        /* --------- process messages that a window sends to the
            system itself ---------- */
        switch (msg)    {
            case STOP:
				StopMsg();
                break;
            /* ------- clock messages --------- */
            case CAPTURE_CLOCK:
				if (Cwnd == NULL)
	                set_timer(clocktimer, 0);
				wnd->PrevClock = Cwnd;
                Cwnd = wnd;
                break;
            case RELEASE_CLOCK:
                Cwnd = wnd->PrevClock;
				if (Cwnd == NULL)
	                disable_timer(clocktimer);
                break;
            /* -------- keyboard messages ------- */
            case KEYBOARD_CURSOR:
                if (wnd == NULL)
                    cursor((int)p1, (int)p2);
                else if (wnd == inFocus)
                    cursor(GetClientLeft(wnd)+(int)p1,
                                GetClientTop(wnd)+(int)p2);
                break;
            case CAPTURE_KEYBOARD:
                if (p2)
                    ((WINDOW)p2)->PrevKeyboard=CaptureKeyboard;
                else
                    wnd->PrevKeyboard = CaptureKeyboard;
                CaptureKeyboard = wnd;
                NoChildCaptureKeyboard = (int)p1;
                break;
            case RELEASE_KEYBOARD:
				if (wnd != NULL)	{
					if (CaptureKeyboard == wnd || (int)p1)
	                	CaptureKeyboard = wnd->PrevKeyboard;
					else	{
						WINDOW twnd = CaptureKeyboard;
						while (twnd != NULL)	{
							if (twnd->PrevKeyboard == wnd)	{
								twnd->PrevKeyboard = wnd->PrevKeyboard;
								break;
							}
							twnd = twnd->PrevKeyboard;
						}
						if (twnd == NULL)
							CaptureKeyboard = NULL;
					}
                	wnd->PrevKeyboard = NULL;
				}
				else
					CaptureKeyboard = NULL;
                NoChildCaptureKeyboard = FALSE;
                break;
            case CURRENT_KEYBOARD_CURSOR:
                curr_cursor(&x, &y);
                *(int*)p1 = x;
                *(int*)p2 = y;
                break;
            case SAVE_CURSOR:
                savecursor();
                break;
            case RESTORE_CURSOR:
                restorecursor();
                break;
            case HIDE_CURSOR:
                normalcursor();
                hidecursor();
                break;
            case SHOW_CURSOR:
                if (p1)
                    set_cursor_type(0x0106);
                else
                    set_cursor_type(0x0607);
                unhidecursor();
                break;
			case WAITKEYBOARD:
				waitforkeyboard();
				break;
            /* -------- mouse messages -------- */
			case RESET_MOUSE:
				resetmouse();
				set_mousetravel(0, SCREENWIDTH-1, 0, SCREENHEIGHT-1);
				break;
            case MOUSE_INSTALLED:
                rtn = mouse_installed();
                break;
			case MOUSE_TRAVEL:	{
				RECT rc;
				if (!p1)	{
        			rc.lf = rc.tp = 0;
        			rc.rt = SCREENWIDTH-1;
        			rc.bt = SCREENHEIGHT-1;
				}
				else 
					rc = *(RECT *)p1;
				set_mousetravel(rc.lf, rc.rt, rc.tp, rc.bt);
				break;
			}
            case SHOW_MOUSE:
                show_mousecursor();
                break;
            case HIDE_MOUSE:
                hide_mousecursor();
                break;
            case MOUSE_CURSOR:
                set_mouseposition((int)p1, (int)p2);
                break;
            case CURRENT_MOUSE_CURSOR:
                get_mouseposition((int*)p1,(int*)p2);
                break;
            case WAITMOUSE:
                waitformouse();
                break;
            case TESTMOUSE:
                rtn = mousebuttons();
                break;
            case CAPTURE_MOUSE:
                if (p2)
                    ((WINDOW)p2)->PrevMouse = CaptureMouse;
                else
                    wnd->PrevMouse = CaptureMouse;
                CaptureMouse = wnd;
                NoChildCaptureMouse = (int)p1;
                break;
            case RELEASE_MOUSE:
				if (wnd != NULL)	{
					if (CaptureMouse == wnd || (int)p1)
	                	CaptureMouse = wnd->PrevMouse;
					else	{
						WINDOW twnd = CaptureMouse;
						while (twnd != NULL)	{
							if (twnd->PrevMouse == wnd)	{
								twnd->PrevMouse = wnd->PrevMouse;
								break;
							}
							twnd = twnd->PrevMouse;
						}
						if (twnd == NULL)
							CaptureMouse = NULL;
					}
                	wnd->PrevMouse = NULL;
				}
				else
					CaptureMouse = NULL;
                NoChildCaptureMouse = FALSE;
                break;
            default:
                break;
        }
    return rtn;
}

static RECT VisibleRect(WINDOW wnd)
{
	RECT rc = WindowRect(wnd);
	if (!TestAttribute(wnd, NOCLIP))	{
		WINDOW pwnd = GetParent(wnd);
		if (!pwnd)
			return rc;
		RECT prc;
		prc = ClientRect(pwnd);
		while (pwnd != NULL)	{
			if (TestAttribute(pwnd, NOCLIP))
				break;
			rc = subRectangle(rc, prc);
			if (!ValidRect(rc))
				break;
			if ((pwnd = GetParent(pwnd)) != NULL)
				prc = ClientRect(pwnd);
		}
	}
	return rc;
}

/* ----- find window that mouse coordinates are in --- */
static WINDOW inWindow(WINDOW wnd, int x, int y)
{
	WINDOW Hit = NULL;
	while (wnd != NULL)	{
		if (isVisible(wnd))	{
			WINDOW wnd1;
			RECT rc = VisibleRect(wnd);
			if (InsideRect(x, y, rc))
				Hit = wnd;
			if ((wnd1 = inWindow(LastWindow(wnd), x, y)) != NULL)
				Hit = wnd1;
			if (Hit != NULL)
				break;
		}
		wnd = PrevWindow(wnd);
	}
	return Hit;
}

static WINDOW MouseWindow(int x, int y)
{
    /* ------ get the window in which a
                    mouse event occurred ------ */
    WINDOW Mwnd = inWindow(ApplicationWindow, x, y);
    /* ---- process mouse captures ----- */
    if (CaptureMouse != NULL)	{
        if (NoChildCaptureMouse ||
				Mwnd == NULL 	||
					!isAncestor(Mwnd, CaptureMouse))
            Mwnd = CaptureMouse;
	}
	return Mwnd;
}

void handshake(void)
{
#if MSDOS
	/*
	handshaking++;
	dispatch_message();
	--handshaking;
	*/
#endif
}

/* ---- dispatch messages to the message proc function ---- */
BOOL dispatch_message(void)
{
    WINDOW Mwnd, Kwnd;
    /* -------- collect mouse and keyboard events ------- */
    collect_events();
    /* --------- dequeue and process events -------- */
    while (EventQueueCtr > 0)  {
        struct events ev;
			
		ev = EventQueue[EventQueueOffCtr];
        if (++EventQueueOffCtr == MAXMESSAGES)
            EventQueueOffCtr = 0;
        --EventQueueCtr;

        /* ------ get the window in which a
                        keyboard event occurred ------ */
        Kwnd = inFocus;

        /* ---- process keyboard captures ----- */
        if (CaptureKeyboard != NULL)
            if (Kwnd == NULL ||
                    NoChildCaptureKeyboard ||
						!isAncestor(Kwnd, CaptureKeyboard))
                Kwnd = CaptureKeyboard;

        /* -------- send mouse and keyboard messages to the
            window that should get them -------- */
        switch (ev.event)    {
            case SHIFT_CHANGED:
            case KEYBOARD:
				if (!handshaking)
	                SendMessage(Kwnd, ev.event, ev.mx, ev.my);
                break;
            case LEFT_BUTTON:
				if (!handshaking)	{
		        	Mwnd = MouseWindow(ev.mx, ev.my);
                	if (!CaptureMouse ||
                        	(!NoChildCaptureMouse &&
								isAncestor(Mwnd, CaptureMouse)))
                    	if (Mwnd != inFocus)
                        	SendMessage(Mwnd, SETFOCUS, TRUE, 0);
                	SendMessage(Mwnd, LEFT_BUTTON, ev.mx, ev.my);
				}
                break;
            case BUTTON_RELEASED:
            case DOUBLE_CLICK:
            case RIGHT_BUTTON:
				if (handshaking)
					break;
            case MOUSE_MOVED:
		        Mwnd = MouseWindow(ev.mx, ev.my);
                SendMessage(Mwnd, ev.event, ev.mx, ev.my);
                break;
#if MSDOS	// FIXME add MK_FP
            case CLOCKTICK:
                SendMessage(Cwnd, ev.event,
                    (PARAM) MK_FP(ev.mx, ev.my), 0);
				break;
#endif
            default:
                break;
        }
    }
    /* ------ dequeue and process messages ----- */
    while (MsgQueueCtr > 0)  {
        struct msgs mq;

		mq = MsgQueue[MsgQueueOffCtr];
        if (++MsgQueueOffCtr == MAXMESSAGES)
            MsgQueueOffCtr = 0;
        --MsgQueueCtr;
        SendMessage(mq.wnd, mq.msg, mq.p1, mq.p2);
        if (mq.msg == ENDDIALOG)
			return FALSE;
        if (mq.msg == STOP)	{
		    PostMessage(NULL, STOP, 0, 0);
			return FALSE;
		}
    }
#if VIDEO_FB
    convert_screen_to_ansi();
#endif
    return TRUE;
}
