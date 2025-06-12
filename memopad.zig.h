void OpenPadWindow(WINDOW wnd, char *FileName);
int OurEditorProc(WINDOW, MESSAGE, PARAM, PARAM);
void SendTextMessage(WINDOW, char *);
void FixTabMenu(void);
void SaveFile(WINDOW, int);
void DeleteFile(WINDOW);

void Calendar(WINDOW);
void BarChart(WINDOW);

DBOX c_MsgBox();
