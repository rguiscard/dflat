void FixTabMenu(void);
char *NameComponent(char *);
void ShowPosition(WINDOW);

BOOL BuildFileList(WINDOW, char *);
void BuildDirectoryList(WINDOW);
void BuildPathDisplay(WINDOW);

extern DBOX Display;

extern WINDOW inFocus;

extern int foreground, background;

int cDialogProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
int ControlProc(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2);

/* used in pictbox */
typedef struct    {
    enum VectTypes vt;
    RECT rc;
} VECT;

int cInsideRect(int x, int y, RECT r);

struct helps *FindHelp(char *Help);
void BuildHelpBox(WINDOW wnd);
extern struct helps *FirstHelp;
extern struct helps *ThisHelp;
extern int HelpCount;
extern char HelpFileName[9];

extern FILE *helpfp;
extern char hline [160];
extern BOOL Helping;

FILE *OpenHelpFile(const char *fn, const char *md);
int cHelpBoxProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
void ReadHelp(WINDOW);

int cEditorProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
