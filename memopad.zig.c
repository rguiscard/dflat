/* --------------- memopad.c ----------- */

#include "dflat.h"

char DFlatApplication[] = "MemoPad";
char **Argv;
WINDOW ApplicationWindow;

static WINDOW oldFocus;
static char *Menus[9] = {
    "~1.                      ",
    "~2.                      ",
    "~3.                      ",
    "~4.                      ",
    "~5.                      ",
    "~6.                      ",
    "~7.                      ",
    "~8.                      ",
    "~9.                      "
};

char *NameComponent(char *);
void FixTabMenu(void);

/* ------ display the row and column in the statusbar ------ */
void ShowPosition(WINDOW wnd)
{
    char status[30];
    sprintf(status, "Line:%4d  Column: %2d",
        wnd->CurrLine, wnd->CurrCol);
    SendMessage(GetParent(wnd), ADDSTATUS, (PARAM) status, 0);
}

/* -- point to the name component of a file specification -- */
char *NameComponent(char *FileName)
{
    char *Fname;
    if ((Fname = strrchr(FileName, '/')) == NULL)
        Fname = FileName-1;
    return Fname + 1;
}

void FixTabMenu(void)
{
	char *cp = GetCommandText(&MainMenu, ID_TABS);
	if (cp != NULL)	{
		cp = strchr(cp, '(');
		if (cp != NULL)	{
#if MSDOS | ELKS   /* can't overwrite .rodata */
			*(cp+1) = cfg.Tabs + '0';
#endif
			if (inFocus && (GetClass(inFocus) == POPDOWNMENU))
				SendMessage(inFocus, PAINT, 0, 0);
		}
	}
}

/* ----------- Prepare the Window menu ------------ */
void PrepWindowMenu(void *w, struct Menu *mnu)
{
    WINDOW wnd = w;
    struct PopDown *p0 = mnu->Selections;
    struct PopDown *pd = mnu->Selections + 2;
    struct PopDown *ca = mnu->Selections + 13;
    int MenuNo = 0;
    WINDOW cwnd;
    mnu->Selection = 0;
    oldFocus = NULL;
    if (GetClass(wnd) != APPLICATION)    {
        oldFocus = wnd;
        /* ----- point to the APPLICATION window ----- */
                if (ApplicationWindow == NULL)
                        return;
                cwnd = FirstWindow(ApplicationWindow);
        /* ----- get the first 9 document windows ----- */
        while (cwnd != NULL && MenuNo < 9)    {
            if (isVisible(cwnd) && GetClass(cwnd) != MENUBAR &&
                    GetClass(cwnd) != STATUSBAR) {
                /* --- add the document window to the menu --- */
#if MSDOS | ELKS
                strncpy(Menus[MenuNo]+4, WindowName(cwnd), 20);
#endif
                pd->SelectionTitle = Menus[MenuNo];
                if (cwnd == oldFocus)    {
                    /* -- mark the current document -- */
                    pd->Attrib |= CHECKED;
                    mnu->Selection = MenuNo+2;
                }
                else
                    pd->Attrib &= ~CHECKED;
                pd++;
                MenuNo++;
            }
                        cwnd = NextWindow(cwnd);
        }
    }

    if (MenuNo)
        p0->SelectionTitle = "~Close all";
    else
        p0->SelectionTitle = NULL;
    if (MenuNo >= 9)    {
        *pd++ = *ca;
        if (mnu->Selection == 0)
            mnu->Selection = 11;
    }
    pd->SelectionTitle = NULL;
}

int MsgHeight(char *msg)
{
    int h = 1;
    while ((msg = strchr(msg, '\n')) != NULL)    {
        h++;
        msg++;
    }
    return min(h, SCREENHEIGHT-10);
}

int MsgWidth(char *msg)
{
    int w = 0;
    char *cp = msg;
    while ((cp = strchr(msg, '\n')) != NULL)    {
        w = max(w, (int) (cp-msg));
        msg = cp+1;
    }
    return min(max(strlen(msg),w), SCREENWIDTH-10);
}

#ifdef INCLUDE_LOGGING

static char *message[] = {
    #undef DFlatMsg
    #define DFlatMsg(m) " " #m,
    #include "dflatmsg.h"
    NULL
};

static FILE *log = NULL;
extern DBOX Log;

void LogMessages (WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
{
    if (log != NULL && message[msg][0] != ' ')
        fprintf(log,
            "%-20.20s %-12.12s %-20.20s, %5.5ld, %5.5ld\n",
            wnd ? (GetTitle(wnd) ? GetTitle(wnd) : "") : "",
            wnd ? ClassNames[GetClass(wnd)] : "",
            message[msg]+1, p1, p2);
}
#endif

/*
#define within(p,v1,v2)   ((p)>=(v1)&&(p)<=(v2))
#define RectTop(r)        (r.tp)
#define RectBottom(r)     (r.bt)
#define RectLeft(r)       (r.lf)
#define RectRight(r)      (r.rt)
#define InsideRect(x,y,r) (within((x),RectLeft(r),RectRight(r))\
                               &&                              \
                          within((y),RectTop(r),RectBottom(r)))
*/
int cInsideRect(int x, int y, RECT r) {
    return within((x), RectLeft(r), RectRight(r)) &&
    within((y), RectTop(r), RectBottom(r));
}

void cClearTextBlock(WINDOW wnd) {
    wnd->BlkBegLine = 0;
    wnd->BlkEndLine = 0;
    wnd->BlkBegCol = 0;
    wnd->BlkEndCol = 0;
}
