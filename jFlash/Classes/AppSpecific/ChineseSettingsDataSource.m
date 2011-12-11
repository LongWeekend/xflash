//
//  ChineseSettingsDataSource.m
//  jFlash
//
//  Created by Mark Makdad on 8/21/11.
//  Copyright 2011 Long Weekend LLC. All rights reserved.
//

#import "ChineseSettingsDataSource.h"
#import "Constants.h"

@implementation ChineseSettingsDataSource

@synthesize resetCardOnly;
@synthesize settingsHash, settingChanged;

- (void) dealloc
{
  [settingsHash release];
  [super dealloc];
}

#pragma mark - Settings Delegate

- (void) settingWillChange:(NSString*)key
{
  // These keys don't warrant a full tag reset, just a card reset -- for any other, this will stay NO
  if ([key isEqualToString:APP_HEADWORD] ||           // Chn<->Eng
      [key isEqualToString:APP_HEADWORD_TYPE] ||      // Trad<->Simp
      [key isEqualToString:APP_DIFFICULTY] ||
      [key isEqualToString:APP_THEME] ||
      [key isEqualToString:APP_PINYIN_COLOR]) 
  {
    self.resetCardOnly = YES;
  }
  else
  {
    self.resetCardOnly = NO;
  }
  self.settingChanged = YES;
}

- (BOOL) shouldSendCardChangeNotification
{
  return (self.settingChanged && self.resetCardOnly);
}

- (BOOL) shouldSendChangeNotification
{
  return (self.settingChanged && (self.resetCardOnly == NO));
}

- (void) settingsViewControllerWillDisappear:(SettingsViewController*)vc
{
  // we've sent the notifications, so reset to unchanged
  self.resetCardOnly = NO;
}

#pragma mark - Settings Data Source

- (CGFloat) sizeForAcknowledgementsRow
{
  return 730.0f;
}

/** Returns all the arrays to configure the settings table */
- (NSArray*) settingsArrayWithPluginManager:(PluginManager *)pluginManager
{
	NSInteger newAvailableUpdate = [pluginManager.downloadablePlugins count];
	
	//This is to set up the very top row and section in the settings table view.
	NSArray *newUpdateNames = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d Update%@ Available", newAvailableUpdate, (newAvailableUpdate>1) ? @"s" : @""], nil];
  NSArray *newUpdateKeys = [NSArray arrayWithObjects:APP_NEW_UPDATE,nil];
  NSArray *newUpdateArray = [NSArray arrayWithObjects:newUpdateNames,newUpdateKeys, [NSString stringWithFormat:@"Available Update%@", (newAvailableUpdate>1) ? @"s" : @""], nil];
	
  // The following dictionaries contain all the mappings from actual settings to how they display on the phone
  NSArray *modeObjects = [NSArray arrayWithObjects:NSLocalizedString(@"Practice",@"SettingsViewController.Practice"), NSLocalizedString(@"Browse",@"SettingsViewController.Browse"), nil];
  NSArray *modeKeys = [NSArray arrayWithObjects:SET_MODE_QUIZ,SET_MODE_BROWSE,nil];
  NSDictionary* modeDict = [NSDictionary dictionaryWithObjects:modeObjects forKeys:modeKeys];
  
  NSArray *headwordObjects = [NSArray arrayWithObjects:NSLocalizedString(@"Chinese",@"SettingsViewController.HeadwordLanguage_Chinese"), 
                              NSLocalizedString(@"English",@"SettingsViewController.HeadwordLanguage_English"), nil];
  NSArray *headwordKeys = [NSArray arrayWithObjects:SET_J_TO_E,SET_E_TO_J,nil];
  NSDictionary* headwordDict = [NSDictionary dictionaryWithObjects:headwordObjects forKeys:headwordKeys];
  
  // Source theme information from the ThemeManager
  ThemeManager *tm = [ThemeManager sharedThemeManager];
  NSDictionary* themeDict = [NSDictionary dictionaryWithObjects:[tm themeNameList] forKeys:[tm themeKeysList]];
  
  NSArray *colorObjects = [NSArray arrayWithObjects:NSLocalizedString(@"On",@"SettingsViewController.On"),
                            NSLocalizedString(@"Off",@"SettingsViewController.Off"),nil];
  NSArray *colorKeys = [NSArray arrayWithObjects:SET_PINYIN_COLOR_ON,SET_PINYIN_COLOR_OFF,nil];
  NSDictionary *colorDict = [NSDictionary dictionaryWithObjects:colorObjects forKeys:colorKeys];
  
  NSArray *hwTypeObjects = [NSArray arrayWithObjects:NSLocalizedString(@"Traditional",@"SettingsViewController.DisplayHW_Traditional"),
                            NSLocalizedString(@"Simplified",@"SettingsViewController.DisplayHW_Simplified"),nil];
  NSArray *hwTypeKeys = [NSArray arrayWithObjects:SET_HEADWORD_TYPE_TRAD,SET_HEADWORD_TYPE_SIMP,nil];
  NSDictionary *hwTypeDict = [NSDictionary dictionaryWithObjects:hwTypeObjects forKeys:hwTypeKeys];
  
  // Create a complete dictionary of all settings display names & their setting constants
  NSArray *dictObjects = [NSArray arrayWithObjects:headwordDict,themeDict,colorDict,hwTypeDict,modeDict,nil];
  NSArray *dictKeys = [NSArray arrayWithObjects:APP_HEADWORD,APP_THEME,APP_PINYIN_COLOR,APP_HEADWORD_TYPE,APP_MODE,nil];
  self.settingsHash = [NSDictionary dictionaryWithObjects:dictObjects forKeys:dictKeys];
  
  // These are the keys and display names of each row
  NSArray *cardSettingNames = [NSArray arrayWithObjects:NSLocalizedString(@"Study Mode",@"SettingsViewController.SettingNames_StudyMode"),
                               NSLocalizedString(@"Study Language",@"SettingsViewController.SettingNames_StudyLanguage"),
                               NSLocalizedString(@"Pinyin Coloring",@"SettingsViewController.SettingNames_PinyinColoring"),
                               NSLocalizedString(@"Character Style",@"SettingsViewController.SettingNames_HW_Type"),
                               NSLocalizedString(@"Difficulty",@"SettingsViewController.SettingNames_ChangeDifficulty"),nil];
  NSArray *cardSettingKeys = [NSArray arrayWithObjects:APP_MODE,APP_HEADWORD,APP_PINYIN_COLOR,APP_HEADWORD_TYPE,APP_ALGORITHM,nil];
  NSArray *cardSettingArray = [NSArray arrayWithObjects:cardSettingNames,cardSettingKeys,NSLocalizedString(@"Studying",@"SettingsViewController.TableHeader_Studying"),nil]; // Puts single section together, 3rd index is header name
  
  NSMutableArray *userSettingNames = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Theme",@"SettingsViewController.SettingNames_Theme"),
                                      NSLocalizedString(@"Study Reminders",@"SettingsViewController.SettingNames_StudyReminders"),
                                      NSLocalizedString(@"Active User",@"SettingsViewController.SettingNames_ActiveUser"),
                                      NSLocalizedString(@"Updates",@"SettingsViewController.SettingNames_DownloadExtras"),nil];
  NSMutableArray *userSettingKeys = [NSMutableArray arrayWithObjects:APP_THEME,APP_REMINDER,APP_USER,APP_PLUGIN,nil];
  NSMutableArray *userSettingArray = [NSMutableArray arrayWithObjects:userSettingNames,userSettingKeys,NSLocalizedString(@"Application",@"SettingsViewController.TableHeader_Application"),nil];
  
  NSArray *socialNames = [NSArray arrayWithObjects:NSLocalizedString(@"Follow us on Twitter",@"SettingsViewController.SettingNames_Twitter"),
                          NSLocalizedString(@"See us on Facebook",@"SettingsViewController.SettingNames_Facebook"),nil];
  NSArray *socialKeys = [NSArray arrayWithObjects:APP_TWITTER,APP_FACEBOOK,nil];
  NSArray *socialArray = [NSArray arrayWithObjects:socialNames,socialKeys,NSLocalizedString(@"Follow Us",@"SettingsViewController.TableHeader_FollowUs"),nil];
  
  NSArray *aboutNames = [NSArray arrayWithObjects:NSLocalizedString(@"Special thanks goes to Teja for helping us write and simulate the frequency algorithm.\n\nThis application uses data from CC-CEDICT, a public domain Chinese language dictionary, which is licensed under the Creative Commons Attribution-Share Alike 3.0 License.\n\nWord frequency lists are courtesy of Jun Da and Patrick Hassel Zein.\n\nTextbook names & content in the Study Sets are copyright of their respective owners.  Their inclusion neither constitutes an endorsement of Chinese Flash by those owners, or vice-versa.  Users on http://zdt.sourceforge.net/ provided these lists; Long Weekend offers no warranty regarding their accuracy.\n\nPhew, I hate legal stuff.  Shouldn't you be studying instead of reading the fine print?\n\nIf you want a break, you could write us a great review (up there on the left!).",@"SettingsViewController.Acknowledgements"),nil];
  NSArray *aboutKeys = [NSArray arrayWithObjects:APP_ABOUT,nil];
  NSArray *aboutArray = [NSArray arrayWithObjects:aboutNames,aboutKeys,NSLocalizedString(@"Acknowledgements",@"SettingsViewController.TableHeader_Acknowledgements"),nil];
  
  // Make the order
	// If there is a new available update plugin, it will show in the first section, however, if it does not have anything, it will show nothing. 
	if (newAvailableUpdate > 0)
  {
		return [NSArray arrayWithObjects:newUpdateArray,cardSettingArray,userSettingArray,socialArray,aboutArray,nil];
  }
	else 
  {
		return [NSArray arrayWithObjects:cardSettingArray,userSettingArray,socialArray,aboutArray,nil];
  }
}


@end
