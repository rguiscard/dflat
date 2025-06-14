void OpenPadWindow(WINDOW wnd, char *FileName);
int OurEditorProc(WINDOW, MESSAGE, PARAM, PARAM);
void FixTabMenu(void);
char *NameComponent(char *);
void ShowPosition(WINDOW);

void Calendar(WINDOW);
void BarChart(WINDOW);

DBOX c_MsgBox();
DBOX c_FileOpen();
DBOX c_SaveAs();

BOOL DlgFileOpen(char *, char *, char *, DBOX *);
int DlgFnOpen(WINDOW, MESSAGE, PARAM, PARAM);
