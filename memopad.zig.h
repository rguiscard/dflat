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

// helpbox.c
struct helps *FindHelp(char *Help);
void BuildHelpBox(WINDOW wnd);
extern struct helps *FirstHelp;
extern struct helps *ThisHelp;
extern int HelpCount;
extern char HelpFileName[9];

extern FILE *helpfp;
extern char hline [160];
extern BOOL Helping;

#define MAXHELPSTACK 100
extern int HelpStack[MAXHELPSTACK];
extern int stacked;

FILE *OpenHelpFile(const char *fn, const char *md);
int cHelpBoxProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
void ReadHelp(WINDOW);
BOOL HelpBoxKeyboardMsg(WINDOW wnd, PARAM p1);
void SelectHelp(WINDOW, struct helps *, BOOL);

// editbox.c
#define EditBufLen(wnd) (isMultiLine(wnd)>0 ? EDITLEN : ENTRYLEN)
int EditBoxCommandMsg(WINDOW wnd, PARAM p1);

int cEditorProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
int cEditBoxProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);

// text.c
void drawText(WINDOW wnd);

// editor.c
int EditorKeyboardMsg(WINDOW wnd, PARAM p1, PARAM p2);
int EditorSetTextMsg(WINDOW wnd, char *Buf);

// memnubar.c
int cMenuBarProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);

// popdown.c
int cPopDownProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);

// normal.c
int cNormalProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2);
void GetVideoBuffer(WINDOW wnd);
void PutVideoBuffer(WINDOW wnd);
void PaintOverLappers(WINDOW wnd);
void PaintUnderLappers(WINDOW wnd);
void SetFocusMsg(WINDOW wnd, PARAM p1);
void RestoreBorder(RECT);
void SaveBorder(RECT rc);
void sizeborder(WINDOW, int, int);
extern struct window dwnd;

// dialbox.c
BOOL CtlKeyboardMsg(WINDOW wnd, PARAM p1, PARAM p2);
void CtlCloseWindowMsg(WINDOW wnd);

// window.c
WINDOW cCreateWindow(
    CLASS Class,
    const char *ttl,
    int left, int top,
    int height, int width,
    void *extension,
    WINDOW parent,
    int (*wndproc)(struct window *,enum messages,PARAM,PARAM),
    int attrib);


void cClearTextBlock(WINDOW wnd);
