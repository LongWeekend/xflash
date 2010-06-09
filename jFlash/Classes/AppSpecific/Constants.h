// Long weekend values
#define NEXT_BTN 1
#define PREV_BTN 2
#define RIGHT_BTN 3
#define WRONG_BTN 4
#define BURY_BTN 6

#define STUDY_VIEW_CONTROLLER_TAB_INDEX 0
#define DEFAULT_TAG_ID 124
#define DEFAULT_USER_ID 1
#define DEFAULT_FREQUENCY_MULTIPLIER 1
#define DEFAULT_MAX_STRUDYING 30

// Settings
extern NSString * const SET_MODE_QUIZ;
extern NSString * const SET_MODE_BROWSE;
extern NSString * const SET_J_TO_E;
extern NSString * const SET_E_TO_J;
extern NSString * const SET_READING_KANA;
extern NSString * const SET_READING_ROMAJI;
extern NSString * const SET_READING_BOTH;

// Different setting types
extern NSString * const APP_MODE;
extern NSString * const APP_HEADWORD;
extern NSString * const APP_READING;
extern NSString * const APP_THEME;
extern NSString * const APP_USER;
extern NSString * const APP_PLUGIN;
extern NSString * const APP_FREQUENCY_MULTIPLIER;
extern NSString * const APP_MAX_STUDYING;

// Study View controllers
#define kAnimationKey @"transitionViewAnimation"
#define percentCorrectLabelStartText @"100%"

#define HORIZ_SWIPE_DRAG_MIN  12.0
#define VERT_SWIPE_DRAG_MAX   4.0
#define SLIDER_HEIGHT         23.0

#define CARDCONTENT_PADDING               5.0
#define CARDCONTENT_HEADWORD_MAX_HEIGHT   55.0
#define CARDCONTENT_READING_MAX_HEIGHT    42.0
#define CARDCONTENT_MEANING_MAX_HEIGHT    99.0

extern NSString * const HTML_HEADER;
extern NSString * const HTML_FOOTER;

// algorithm controls
#define MAX_MAX_STUDYING 50
#define MIN_MAX_STUDYING 5
#define MAX_FREQUENCY_MULTIPLIER 4
#define MIN_FREQUENCY_MULTIPLIER 1

// Some layout consts
#define LAYOUT_CARD_REVEALED_Y_OFFSET 20
#define LAYOUT_CARD_HIDDEN_Y_OFFSET -20

#define FONT_SIZE_CARD_E_WORD 14
#define FONT_SIZE_CARD_J_WORD 28

#define FONT_SIZE_CARD_E_MEANING 14
#define FONT_SIZE_CARD_J_MEANING 14

// these are the various screen placement constants used across all the UIViewControllers
 
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

// image file storage root
#define DOCSFOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

// default background image for UITableViews
#define TABLEVIEW_BACKGROUND_IMAGE @"/table-background.png"

