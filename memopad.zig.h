void FixTabMenu(void);
char *NameComponent(char *);
void ShowPosition(WINDOW);

void Calendar(WINDOW);
void BarChart(WINDOW);

DBOX c_MsgBox();
DBOX c_FileOpen();
DBOX c_SaveAs();
DBOX c_SearchTextDB();
DBOX c_ReplaceTextDB();

BOOL BuildFileList(WINDOW, char *);
void BuildDirectoryList(WINDOW);
void BuildPathDisplay(WINDOW);

extern DBOX Display;

extern WINDOW inFocus;

extern int foreground, background;
