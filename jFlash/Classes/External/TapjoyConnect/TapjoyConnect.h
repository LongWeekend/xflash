//
//  TapjoyConnect.h
//
//  Created by Tapjoy.
//  Copyright 2010 Tapjoy.com All rights reserved.


/*! \mainpage Tapjoy iOS SDK
 *
 * The Tapjoy iOS SDK.
 */


#define TJC_SERVICE_URL						@"https://ws.tapjoyads.com/"
#define TJC_SERVICE_URL_ALTERNATE			@"https://ws1.tapjoyads.com/"

#define TJC_DEVICE_TAG_NAME					@"udid"			/*!< The unique device identifier. */
#define TJC_DEVICE_NAME						@"device_name"	/*!< This is the specific device name ("iPhone1,1", "iPod1,1"...) */
#define TJC_DEVICE_TYPE_NAME				@"device_type"	/*!< The model name of the device. This is less descriptive than the device name. */
#define TJC_DEVICE_OS_VERSION_NAME			@"os_version"	/*!< The device system version. */
#define TJC_DEVICE_COUNTRY_CODE				@"country_code"	/*!< The country code is retrieved from the locale object, from user data (not device). */
#define TJC_DEVICE_LANGUAGE					@"language_code"/*!< The language is retrieved from the locale object, from user data (not device). */
#define TJC_DEVICE_LAD						@"lad"			/*!< Little Alien Dude. */
#define TJC_APP_ID_NAME						@"app_id"		/*!< The application id is set by the developer, and is a unique id provided by Tapjoy. */
#define TJC_APP_VERSION_NAME				@"app_version"	/*!< The application version is retrieved from the application plist file, from the bundle version. */
#define TJC_CONNECT_LIBRARY_VERSION_NAME	@"library_version"	/*!< The library version is the SDK version number. */	
#define TJC_LIBRARY_VERSION_NUMBER			@"7.4.0"		/*!< The SDK version number. */


/*!	\interface TapjoyConnect
 *	\brief The Tapjoy Connect Main class.
 *
 */
@interface TapjoyConnect :  NSObject
#if __IPHONE_4_0
<NSXMLParserDelegate>
#endif
{
@private
	NSString *appId_;				/*!< The application ID unique to this app. */
	NSData *data_;					/*!< Holds data for any data that comes back from a URL request. */
	NSURLConnection *connection_;	/*!< Used to provide support to perform the loading of a URL request. Delegate methods are defined to handle when a response is recieve with associated data. This is used for asynchronous requests only. */
	NSTimeInterval timeStamp_;		/*!< Contains the current time when a URL request is made. This value is used to help generate a unique md5sum key. */
	NSString *currentXMLElement_;	/*!< Contains @"Success when a connection is successfully made, nil otherwise. */
	int connectAttempts_;			/*!< The connect attempts is used to determine whether the alternate URL will be used. */
	BOOL isInitialConnect_;			/*!< Used to keep track of an initial connect call to prevent multiple repeated calls. */
}

@property (nonatomic,readonly) NSString* appId;
@property (nonatomic) BOOL isInitialConnect;

/*!	\fn requestTapjoyConnectWithAppId:(NSString*)appId
 *	\brief This method is called to initialize the TapjoyConnect system.
 *
 * This method should be called upon app delegate initialization in the applicationDidFinishLaunching method.
 *	\param appId The application ID.
 *	\return The globally accessible #TapjoyConnect object.
 */
+ (TapjoyConnect*) requestTapjoyConnectWithAppId:(NSString*)appId;

/*!	\fn actionComplete:(NSString*)actionId
 *	\brief This is called when an action is completed.
 *
 * Actions are much like connects, except that this method is only called when a user completes an in-game action.
 *	\param actionId The action Id.
 *	\return The globally accessible #TapjoyConnect object.
 */
+ (TapjoyConnect*) actionComplete:(NSString*)actionId;

/*!	\fn sharedTapjoyConnect
 *	\brief Retrieves the globally accessible #TapjoyConnect singleton object.
 *
 *	\param n/a
 *	\return The globally accessible #TapjoyConnect singleton object.
 */
+ (TapjoyConnect*) sharedTapjoyConnect;

/*!	\fn connect
 *	\brief Initiates a URL request with the application identifier data.
 *	\deprecated Updated for version 7.0.0. Do not use this method, requestTapjoyConnectWithAppId will automatically initiate a URL request.
 *	\param n/a
 *	\return n/a
 */
+ (void) connect;

/*!
 *	\brief Simple check to detect jail broken devices/apps.
 *
 * Note that this is NOT guaranteed to be accurate! There are very likely going to be ways to circumvent this check in the future.
 *	\param n/a
 *	\return YES for indicating that the device/app has been jailbroken, NO otherwise.
 */ 
- (BOOL) isJailBroken;

/*!
 *	\brief Simple check to detect jail broken devices/apps.
 *
 * Note that this is NOT guaranteed to be accurate! There are very likely going to be ways to circumvent this check in the future.
 *	\param n/a
 *	\return A string "YES" for indicating that the device/app has been jailbroken, "NO" otherwise.
 */ 
- (NSString*) isJailBrokenStr;

// Declared here to prevent warnings.
#pragma mark TapjoyConnect NSXMLParser Delegate Methods
- (void) startParsing:(NSData*) myData;
- (NSMutableDictionary*) genericParameters;
- (NSString*) createQueryStringFromDict:(NSDictionary*) paramDict;

#pragma mark Deprecated Methods

/*!	\fn requestTapjoyConnectWithAppId:(NSString*)appId
 *	\brief This method is called to initialize the TapjoyConnect system.
 *
 * This method should be called upon app delegate initialization in the applicationDidFinishLaunching method.
 *	\param appId The application ID.
  *	\param password The application password.
  *	\param version The application version.
 *	\return The globally accessible #TapjoyConnect object.
 */
+ (TapjoyConnect*) requestTapjoyConnectWithAppId:(NSString*)appId WithPassword:(NSString*)password WithVersion:(NSString*)version	__deprecated;

/*!	\brief Initiates a URL request with the application identifier data.
 *	\deprecated Updated for version 7.0.0. Use + (void) connect;
 *	\param n/a
 *	\return n/a
 */
- (void) connect	__deprecated;

@end

#import "TapjoyConnectConstants.h"