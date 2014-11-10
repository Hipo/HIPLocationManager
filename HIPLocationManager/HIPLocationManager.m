//
//  HIPLocationManager.m
//
//
//  Created by Taylan Pince on 11-03-18.
//  Copyright 2011 Hipo. All rights reserved.
//

#import "HIPLocationManager.h"


NSString * const HIPLocationManagerErrorDomain = @"com.hipo.hiplocationmanager";
NSInteger const HIPLocationManagerDeniedErrorCode = 403;
NSInteger const HIPLocationManagerLocationFailureErrorCode = 500;

NSString * const HIPLocationManagerLocationUpdateNotification = @"HIPLocationManagerLocationUpdateNotification";
NSString * const HIPLocationManagerLocationUpdateNotificationLocationKey = @"location";

double const kMaximumAllowedLocationInterval = 60.0 * 5.0;
double const kLocationAccuracyHundredMetersTimeOut = 4.0;
double const kLocationAccuracyKilometerTimeOut = 8.0;
double const kLocationAccuracyThreeKilometersTimeOut = 12.0;
double const kLocationTimeOut = 16.0;
double const kLocationCheckInterval = 4.0;


@interface HIPLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) NSDate *queryStartTime;
@property (nonatomic, strong) NSMutableSet *executionBlocks;
@property (nonatomic, strong) CLLocationManager *locationManager;

- (void)cancelLocationCheck;
- (void)checkLocationStatus;
- (void)sendLocationToBlocks:(CLLocation *)location withError:(NSError *)error;

- (void)processNewLocation:(CLLocation *)newLocation;

@end


@implementation HIPLocationManager

@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize intervalModifier = _intervalModifier;

#pragma mark - Singleton and init management

static HIPLocationManager *_sharedManager = nil;

+ (instancetype)sharedManager {
    static HIPLocationManager *_sharedManager = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        _sharedManager = [[HIPLocationManager alloc] init];
    });

    return _sharedManager;
}

- (id)init {
	self = [super init];
	
	if (self) {
		_queryStartTime = nil;
		_executionBlocks = [[NSMutableSet alloc] init];
		_locationManager = [[CLLocationManager alloc] init];
        _desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _authorizationType = HIPLocationManagerAuthorizationTypeWhenInUse;
        _updateContinuously = NO;
        _intervalModifier = 1.0;
		
		[_locationManager setDelegate:self];
		[_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
	}
	
	return self;
}

#pragma mark - CLLocationManagerDelegate calls

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {

    switch ([error code]) {
        case kCLErrorDenied: {
            [self sendLocationToBlocks:nil 
                             withError:[NSError errorWithDomain:HIPLocationManagerErrorDomain
                                                           code:HIPLocationManagerDeniedErrorCode
                                                       userInfo:nil]];
            break;
        }
        default:
            [self cancelLocationCheck];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {

    [self processNewLocation:[locations lastObject]];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            break;
        }
        case kCLAuthorizationStatusDenied: {
            [self sendLocationToBlocks:nil
                             withError:[NSError errorWithDomain:HIPLocationManagerErrorDomain
                                                           code:HIPLocationManagerDeniedErrorCode
                                                       userInfo:nil]];
            break;
        }
        default: {
            if ([_executionBlocks count] == 0) {
                return;
            }
            
            _queryStartTime = [NSDate date];
            
            [_locationManager startUpdatingLocation];
            
            [self performSelector:@selector(checkLocationStatus)
                       withObject:nil
                       afterDelay:kLocationCheckInterval];
            break;
        }
    }
}

#pragma mark - Location update calls

- (void)refreshLocation {
	if (_queryStartTime != nil) {
        return;
    }
    
    _queryStartTime = [NSDate date];
    
    [_locationManager startUpdatingLocation];
    
    [self performSelector:@selector(checkLocationStatus) 
               withObject:nil 
               afterDelay:kLocationCheckInterval];
}

- (void)getLocationWithExecutionBlock:(void (^)(CLLocation *, NSError *))block {

    if (_queryStartTime != nil) {
		[_executionBlocks addObject:block];
	} else if (_locationManager.location == nil || 
               (_locationManager.location != nil && 
                (-1 * [_locationManager.location.timestamp timeIntervalSinceNow]) > kMaximumAllowedLocationInterval)) {

                   [_executionBlocks addObject:block];
                   
                   BOOL managerReady = YES;
                   
                   if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                       CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
                       
                       if (authStatus == kCLAuthorizationStatusNotDetermined) {
                           managerReady = NO;
                           
                           switch (_authorizationType) {
                               case HIPLocationManagerAuthorizationTypeWhenInUse:
                                   [_locationManager requestWhenInUseAuthorization];
                                   break;
                               case HIPLocationManagerAuthorizationTypeAlways:
                                   [_locationManager requestAlwaysAuthorization];
                                   break;
                           }
                       }
                   }
                   
                   if (!managerReady) {
                       return;
                   }

                   _queryStartTime = [NSDate date];
                   
                   [_locationManager startUpdatingLocation];
                   
                   [self performSelector:@selector(checkLocationStatus)
                              withObject:nil 
                              afterDelay:kLocationCheckInterval];
	} else {
		block(_locationManager.location, nil);
	}
}

- (void)checkLocationStatus {
	if (_queryStartTime == nil) {
		return;
	}
	
    NSTimeInterval interval = -1 * [_queryStartTime timeIntervalSinceNow];

    if (_locationManager.location == nil && interval < kLocationTimeOut * _intervalModifier) {
        [self performSelector:@selector(checkLocationStatus)
                   withObject:nil
                   afterDelay:(kLocationCheckInterval)];

        return;
    }
    
    CLLocationAccuracy accuracy = _locationManager.location.horizontalAccuracy;
	
	if (interval >= kLocationAccuracyHundredMetersTimeOut && interval < kLocationAccuracyKilometerTimeOut * _intervalModifier) {
		if (accuracy <= kCLLocationAccuracyHundredMeters) {
			[self sendLocationToBlocks:_locationManager.location withError:nil];
		} else {
			[self performSelector:@selector(checkLocationStatus) 
					   withObject:nil 
					   afterDelay:(kLocationCheckInterval)];
		}
	} else if (interval >= kLocationAccuracyKilometerTimeOut && interval < kLocationAccuracyThreeKilometersTimeOut * _intervalModifier) {
		if (accuracy <= kCLLocationAccuracyKilometer) {
			[self sendLocationToBlocks:_locationManager.location withError:nil];
		} else {
			[self performSelector:@selector(checkLocationStatus) 
                       withObject:nil 
                       afterDelay:(kLocationCheckInterval)];
		}
	} else if (interval >= kLocationAccuracyThreeKilometersTimeOut && interval < kLocationTimeOut * _intervalModifier) {
		if (accuracy <= kCLLocationAccuracyThreeKilometers) {
			[self sendLocationToBlocks:_locationManager.location withError:nil];
		} else {
			[self performSelector:@selector(cancelLocationCheck) 
                       withObject:nil 
                       afterDelay:(kLocationCheckInterval)];
		}
	} else if (interval >= kLocationTimeOut * _intervalModifier) {
		[self cancelLocationCheck];
	} else {
        [self performSelector:@selector(checkLocationStatus) 
				   withObject:nil 
				   afterDelay:(kLocationCheckInterval)];
    }
}

- (void)cancelLocationCheck {
	if (_queryStartTime != nil) {
		[self sendLocationToBlocks:_locationManager.location 
						 withError:[NSError errorWithDomain:HIPLocationManagerErrorDomain
													   code:HIPLocationManagerLocationFailureErrorCode
												   userInfo:nil]];
	}
}

- (void)sendLocationToBlocks:(CLLocation *)location withError:(NSError *)error {
	CLLocationAccuracy accuracy = location.horizontalAccuracy;
	NSTimeInterval interval = -1 * [_queryStartTime timeIntervalSinceNow];
    
    if (accuracy <= kCLLocationAccuracyNearestTenMeters || interval >= kLocationTimeOut) {
        _queryStartTime = nil;
        
        if (!_updateContinuously) {
            [_locationManager stopUpdatingLocation];
        }
    } else {
        [self performSelector:@selector(checkLocationStatus) 
                   withObject:nil 
                   afterDelay:(kLocationCheckInterval)];
    }

    NSSet *blocks = [_executionBlocks copy];
    for (void(^block)(CLLocation *location, NSError *error) in blocks) {
		block(location, error);
	}
	
	[_executionBlocks removeAllObjects];
}

- (void)processNewLocation:(CLLocation *)newLocation {
    if (-1 * [newLocation.timestamp timeIntervalSinceNow] > kMaximumAllowedLocationInterval) {
		return;
	}
	
	CLLocationAccuracy accuracy = newLocation.horizontalAccuracy;
	NSTimeInterval interval = -1 * [_queryStartTime timeIntervalSinceNow];
    
	if (accuracy <= _desiredAccuracy
        || accuracy <= kCLLocationAccuracyNearestTenMeters
        || (accuracy <= kCLLocationAccuracyHundredMeters
            && interval > kLocationAccuracyHundredMetersTimeOut * _intervalModifier)
        || (accuracy <= kCLLocationAccuracyKilometer
            && interval > kLocationAccuracyKilometerTimeOut * _intervalModifier)
        || (accuracy <= kCLLocationAccuracyThreeKilometers
            && interval > kLocationAccuracyThreeKilometersTimeOut * _intervalModifier)
        || interval > kLocationTimeOut * _intervalModifier) {

		[self sendLocationToBlocks:newLocation withError:nil];
	}
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:HIPLocationManagerLocationUpdateNotification
     object:self
     userInfo:@{
       HIPLocationManagerLocationUpdateNotificationLocationKey : newLocation
     }];
}

#pragma mark - Accuracy

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    if (_desiredAccuracy == desiredAccuracy) {
        return;
    }
    
    _desiredAccuracy = desiredAccuracy;
    
    if (!_updateContinuously) {
        [_locationManager setDesiredAccuracy:_desiredAccuracy];
    }
    
    [self refreshLocation];
}

#pragma mark - Cancellation

- (void)cancelLocationQuery {
    if (!_updateContinuously) {
        [_locationManager stopUpdatingLocation];
    }

    _queryStartTime = nil;
    [_executionBlocks removeAllObjects];
}

#pragma mark - Continuous updates

- (void)setUpdateContinuously:(BOOL)updateContinuously {
    if (_updateContinuously == updateContinuously) {
        return;
    }
    
    _updateContinuously = updateContinuously;
    
    if (!_updateContinuously && _queryStartTime == nil) {
        [_locationManager stopUpdatingLocation];
    } else if (_updateContinuously) {
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        
        [self refreshLocation];
    }
}

@end
