// Long weekend values
#define NEXT_BTN 1
#define PREV_BTN 2
#define RIGHT_BTN 3
#define WRONG_BTN 4
#define BURY_BTN 6

#define STUDY_VIEW_CONTROLLER_TAB_INDEX     0
#define STUDY_SET_VIEW_CONTROLLER_TAB_INDEX 1
#define SEARCH_VIEW_CONTROLLER_TAB_INDEX    2
#define SETTINGS_VIEW_CONTROLLER_TAB_INDEX  3

#define DEFAULT_USER_ID 1
#define DEFAULT_FREQUENCY_MULTIPLIER 1
#define DEFAULT_MAX_STUDYING 30
#define DEFAULT_DIFFICULTY 1

#define LWE_PLUGIN_UPDATE_PERIOD		14

// Settings - do not change
extern NSString * const SET_MODE_QUIZ;
extern NSString * const SET_MODE_BROWSE;
extern NSString * const SET_J_TO_E;
extern NSString * const SET_E_TO_J;

// Different setting types
// DO NOT edit these
extern NSString * const APP_MODE;
extern NSString * const APP_THEME;
extern NSString * const APP_ALGORITHM;
extern NSString * const APP_USER;
extern NSString * const APP_HEADWORD;
extern NSString * const APP_PLUGIN;
extern NSString * const APP_FREQUENCY_MULTIPLIER;
extern NSString * const APP_MAX_STUDYING;
extern NSString * const APP_DIFFICULTY;
extern NSString * const APP_DATA_VERSION;
extern NSString * const APP_SETTINGS_VERSION;
extern NSString * const APP_HIDE_BURIED_CARDS;

extern NSString * const PLUGIN_LAST_UPDATE;

extern const NSInteger FAVORITES_TAG_ID;

// Talk to MMA about these - do NOT edit them
extern NSString * const LWE_CURRENT_VERSION;
extern NSString * const LWE_CURRENT_CARD_DATABASE;
extern NSString * const LWE_CURRENT_USER_DATABASE;

extern NSString * const LWE_BAD_DATA_EMAIL;

#if defined(LWE_JFLASH)

  // LWE Favorites - JFlash
  #define DEFAULT_TAG_ID 124

  extern NSString * const APP_READING;
  extern NSString * const SET_READING_KANA;
  extern NSString * const SET_READING_ROMAJI;
  extern NSString * const SET_READING_BOTH;

  extern NSString * const LWE_JF_VERSION_1_0;
  extern NSString * const LWE_JF_VERSION_1_1;
  extern NSString * const LWE_JF_VERSION_1_2;
  extern NSString * const LWE_JF_VERSION_1_3;
  extern NSString * const LWE_JF_VERSION_1_4;
  extern NSString * const LWE_JF_VERSION_1_5;
  extern NSString * const LWE_JF_10_USER_DATABASE;
  extern NSString * const LWE_JF_10_TO_11_SQL_FILENAME;
  extern NSString * const LWE_JF_12_TO_13_SQL_FILENAME;
  extern NSString * const LWE_JF_13_TO_14_SQL_FILENAME;

#elif defined(LWE_CFLASH)

  // "Politics" (for now) - CFlash
  #define DEFAULT_TAG_ID 42

  extern NSString * const APP_HEADWORD_TYPE;
  extern NSString * const SET_HEADWORD_TYPE_TRAD;
  extern NSString * const SET_HEADWORD_TYPE_SIMP;

  extern NSString * const APP_PINYIN_COLOR;
  extern NSString * const SET_PINYIN_COLOR_ON;
  extern NSString * const SET_PINYIN_COLOR_OFF;

  extern NSString * const LWE_CF_VERSION_1_0;
#endif 

// PLugins
extern NSString * const LWE_DOWNLOADED_PLUGIN_PLIST;
extern NSString * const LWE_PLUGIN_SERVER_LIST;
extern NSString * const LWE_AVAILABLE_PLUGIN_PLIST;

extern NSString *const CARD_DB_KEY;       //! Dictionary key to refer to main card database
extern NSString *const FTS_DB_KEY;        //! Dictionary key to refer to FTS database filename
extern NSString *const EXAMPLE_DB_KEY;    //! Dictionary key to refer to example database filename

extern NSString *const LWE_APP_SPLASH_IMAGE; // App splash image - different between the flashes

// Study View controllers
#define kAnimationKey @"transitionViewAnimation"
#define percentCorrectLabelStartText @"100%"

#define HORIZ_SWIPE_DRAG_MIN  12.0
#define VERT_SWIPE_DRAG_MAX   4.0
#define SLIDER_HEIGHT         23.0

extern NSString * const SENTENCES_HTML_HEADER;

// algorithm controls
#define MAX_MAX_STUDYING 50
#define MIN_MAX_STUDYING 5
#define MAX_FREQUENCY_MULTIPLIER 4
#define MIN_FREQUENCY_MULTIPLIER 1
#define NUM_CARDS_IN_NOT_NEXT_QUEUE 5

// Some layout consts
#define LAYOUT_CARD_REVEALED_Y_OFFSET 20
#define LAYOUT_CARD_HIDDEN_Y_OFFSET -20

#define FONT_SIZE_CARD_E_WORD 14
#define FONT_SIZE_CARD_J_WORD 28

#define FONT_SIZE_CARD_E_MEANING 14
#define FONT_SIZE_CARD_J_MEANING 14

// these are the various screen placement constants used across all the UIViewControllers
 

// COMMENTED OUT BY MMA on JUNE 1 2011 -- project find doesn't seem to reveal that any 
// of these are used anywhere??!
/**

// padding for margins
#define kLeftMargin				20.0
#define kTopMargin				20.0
#define kRightMargin			20.0
#define kBottomMargin			20.0
#define kTweenMargin			10.0

// control dimensions
#define kStdButtonWidth			106.0
#define kStdButtonHeight		40.0
#define kSegmentedControlHeight 40.0
#define kPageControlHeight		20.0
#define kPageControlWidth		160.0
#define kSliderHeight			7.0
#define kSwitchButtonWidth		94.0
#define kSwitchButtonHeight		27.0
#define kTextFieldHeight		30.0
#define kSearchBarHeight		40.0
#define kLabelHeight			20.0
#define kProgressIndicatorSize	40.0
#define kToolbarHeight			40.0
#define kUIProgressBarWidth		160.0
#define kUIProgressBarHeight	24.0

// specific font metrics used in our text fields and text views
#define kFontName				@"Arial"
#define kTextFieldFontSize		18.0
#define kTextViewFontSize		18.0

// UITableView row heights
#define kUIRowHeight			50.0
#define kUIRowLabelHeight		22.0

// table view cell content offsets
#define kCellLeftOffset			8.0
#define kCellTopOffset			12.0

 */
 
// default background image for UITableViews
#define TABLEVIEW_BACKGROUND_IMAGE @"/table-background.jpg"

