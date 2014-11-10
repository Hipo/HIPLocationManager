//
//  HIPLocationManager.h
//  
//
//  Created by Taylan Pince on 11-03-18.
//  Copyright 2011 Hipo. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>


extern NSString * const HIPLocationManagerErrorDomain;
extern NSInteger const HIPLocationManagerDeniedErrorCode;
extern NSInteger const HIPLocationManagerLocationFailureErrorCode;

extern NSString * const HIPLocationManagerLocationUpdateNotification;
extern NSString * const HIPLocationManagerLocationUpdateNotificationLocationKey;


typedef NS_ENUM(NSInteger, HIPLocationManagerAuthorizationType) {
    HIPLocationManagerAuthorizationTypeWhenInUse,
    HIPLocationManagerAuthorizationTypeAlways,
};


/** A custom location manager for determining user coordinates
 
 This is a light wrapper around CLLocationManager that adds some caching 
 capabilities and intelligence to the way location results are reported. At a 
 very basic level, HIPLocationManager allows different parts of a single app to
 use the same location requests and get the most accurate data possible without 
 having to wait for too long. It also follows a graceful degradation routine in 
 order to fetch the most accurate location in as little time as possible.
 */
@interface HIPLocationManager : NSObject

/** Update location continuously
 
 If this flag is set to YES, location manager will never stop receiving new 
 location updates. By default it's NO.
 */
@property (nonatomic, assign, getter=isUpdatingContinuously) BOOL updateContinuously;

/** Desired accuracy for the location requests
 
 This value will be passed directly to the CLLocationManager instance for the 
 accuracy option. By default it's kCLLocationAccuracyNearestTenMeters.
 */
@property (nonatomic, assign) CLLocationAccuracy desiredAccuracy;

/** Interval modifier for requirement degradation
 
 Requirement degradation intervals will be multiplied by this value. The higher it 
 is, the more time it will take the manager to drop down the required accuracy level 
 to the next step. By default it's 1.0.
 */
@property (nonatomic, assign) double intervalModifier;

/** Authorization type
 
 Determines whether the app will request When In Use or Always authorization.
 On iOS7, value of this property is ignored.
 */
@property (nonatomic, assign) HIPLocationManagerAuthorizationType authorizationType;

/** Returns the shared instance of the location manager
 
 You should always use this method and never instantiate the manager yourself.
 
 @returns HIPLocationManager shared instance
 */
+ (instancetype)sharedManager;

/** Refreshes the location cache without a completion block
 */
- (void)refreshLocation;

/** Cancels all ongoing location queries
 */
- (void)cancelLocationQuery;

/** Refreshes the location cache and calls the execution block when done
 
 @param block Execution block that will get called when the query is done
 */
- (void)getLocationWithExecutionBlock:(void (^)(CLLocation *, NSError *))block;

@end
