#include "dflat.h"

/* --------------------- the main menu --------------------- */
DEFMENU(MainMenu)
    /* --------------- the File popdown menu ----------------*/
    POPDOWN( "~File",  PrepFileMenu, "Read/write/print files. Go to DOS" )
        SELECTION( "~Open...",    ID_OPEN,         0, 0 )
        SELECTION( "E~xit",       ID_EXIT,     ALT_X, 0 )
    ENDPOPDOWN
ENDMENU

/* ------------- the System Menu --------------------- */
DEFMENU(SystemMenu)
    POPDOWN("System Menu", NULL, NULL)
#ifdef INCLUDE_RESTORE
        SELECTION("~Restore",  ID_SYSRESTORE,  0,         0 )
#endif
        SELECTION("~Move",     ID_SYSMOVE,     0,         0 )
        SELECTION("~Size",     ID_SYSSIZE,     0,         0 )
#ifdef INCLUDE_MINIMIZE
        SELECTION("Mi~nimize", ID_SYSMINIMIZE, 0,         0 )
#endif
#ifdef INCLUDE_MAXIMIZE
        SELECTION("Ma~ximize", ID_SYSMAXIMIZE, 0,         0 )
#endif
        SEPARATOR
        SELECTION("~Close",    ID_SYSCLOSE,    CTRL_F4,   0 )
    ENDPOPDOWN
ENDMENU

/* --------------- file-selector.c ----------- */

char DFlatApplication[] = "MemoPad";

void SelectFile(WINDOW);
static char *NameComponent(char *);

/* --- The Open... command. Select a file  --- */
void SelectFile(WINDOW wnd)
{
    char FileName[MAXPATH];
    if (OpenFileDialogBox("*", FileName))    {
        /* --- see if the document is already in a window --- */
        WINDOW wnd1 = FirstWindow(wnd);
        while (wnd1 != NULL)    {
            if (wnd1->extension && strcasecmp(FileName, wnd1->extension) == 0)    {
                SendMessage(wnd1, SETFOCUS, TRUE, 0);
                SendMessage(wnd1, RESTORE, 0, 0);
                return;
            }
            wnd1 = NextWindow(wnd1);
        }
	PostMessage(wnd, CLOSE_WINDOW, 0, 0);
    }
}

/* -- point to the name component of a file specification -- */
static char *NameComponent(char *FileName)
{
    char *Fname;
    if ((Fname = strrchr(FileName, '/')) == NULL)
        Fname = FileName-1;
    return Fname + 1;
}

void PrepFileMenu(void *w, struct Menu *mnu)
{
	/* do nothing for now */
	WINDOW wnd = w;
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
		}
	}
}
