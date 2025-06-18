/* --------------- memopad.c ----------- */

#include "dflat.h"

char DFlatApplication[] = "MemoPad";

char *NameComponent(char *);
void FixTabMenu(void);

extern DBOX MsgBox;
extern DBOX FileOpen;
extern DBOX SaveAs;
extern DBOX SearchTextDB;
extern DBOX ReplaceTextDB;

/* return MESSAGEBOX */
DBOX c_MsgBox() {
    return MsgBox;
};

DBOX c_FileOpen() {
    return FileOpen;
};

DBOX c_SaveAs() {
    return SaveAs;
};

DBOX c_SearchTextDB() {
    return SearchTextDB;
};

DBOX c_ReplaceTextDB() {
    return ReplaceTextDB;
};

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

void PrepFileMenu(void *w, struct Menu *mnu)
{
	WINDOW wnd = w;
	DeactivateCommand(&MainMenu, ID_SAVE);
	DeactivateCommand(&MainMenu, ID_SAVEAS);
	DeactivateCommand(&MainMenu, ID_DELETEFILE);
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
			ActivateCommand(&MainMenu, ID_SAVE);
			ActivateCommand(&MainMenu, ID_SAVEAS);
			ActivateCommand(&MainMenu, ID_DELETEFILE);
		}
	}
}

void PrepSearchMenu(void *w, struct Menu *mnu)
{
	WINDOW wnd = w;
	DeactivateCommand(&MainMenu, ID_SEARCH);
	DeactivateCommand(&MainMenu, ID_REPLACE);
	DeactivateCommand(&MainMenu, ID_SEARCHNEXT);
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
			ActivateCommand(&MainMenu, ID_SEARCH);
			ActivateCommand(&MainMenu, ID_REPLACE);
			ActivateCommand(&MainMenu, ID_SEARCHNEXT);
		}
	}
}

void PrepEditMenu(void *w, struct Menu *mnu)
{
	WINDOW wnd = w;
	DeactivateCommand(&MainMenu, ID_CUT);
	DeactivateCommand(&MainMenu, ID_COPY);
	DeactivateCommand(&MainMenu, ID_CLEAR);
	DeactivateCommand(&MainMenu, ID_DELETETEXT);
	DeactivateCommand(&MainMenu, ID_PARAGRAPH);
	DeactivateCommand(&MainMenu, ID_PASTE);
	DeactivateCommand(&MainMenu, ID_UNDO);
	if (wnd != NULL && GetClass(wnd) == EDITBOX) {
		if (isMultiLine(wnd))	{
			if (TextBlockMarked(wnd))	{
				ActivateCommand(&MainMenu, ID_CUT);
				ActivateCommand(&MainMenu, ID_COPY);
				ActivateCommand(&MainMenu, ID_CLEAR);
				ActivateCommand(&MainMenu, ID_DELETETEXT);
			}
			ActivateCommand(&MainMenu, ID_PARAGRAPH);
			if (!TestAttribute(wnd, READONLY) &&
						Clipboard != NULL)
				ActivateCommand(&MainMenu, ID_PASTE);
			if (wnd->DeletedText != NULL)
				ActivateCommand(&MainMenu, ID_UNDO);
		}
	}
}
