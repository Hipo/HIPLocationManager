HIPLocationManager
==================

Block based iOS framework for handling user location detection. Supports both iOS7 and iOS8 and saves you time by handling the different permission requirements. It also provides:

* Intelligent requirement degradation: If it's taking too long to determine a specific location, HIPLocationManager will degrade the accuracy requirement automatically and try to strike a balance between timely detection versus high accuracy.

* Centralized caching: If you require location checks from multiple places in your app, HIPLocationManager will use the cached location data as long as it makes sense. Since it uses a single CLLocationManager instance, it will perform better than implementing custom location logic into each view controller.

* Block based: No need to deal with CLLocationManager delegate calls or specific error cases. With a single call to HIPLocationManager you will be able to get the location data or the appropriate error. Authorization calls based on system requirements will be handled for you automatically.


Usage
-----

HIPLocationManager exposes a single method for getting location data:

    [[HIPLocationManager sharedManager]
     getLocationWithExecutionBlock:^(CLLocation *location, NSError *error) {
         // Check for errors and use the CLLocation instance as you need
     }];


Installation
------------

Copy and include the `HIPLocationManager` directory in your own project. You will also have to update your `Info.plist` file to include the following keys with location authorization descriptions:

* `NSLocationAlwaysUsageDescription`: If you require your app to have access to location information even when in background, you must provide this key and update HIPLocationManager's `authorizationType` property to `HIPLocationManagerAuthorizationTypeAlways`
* `NSLocationWhenInUseUsageDescription`
* `NSLocationUsageDescription`


Support
-------

If you find any issues, please open an issue here on GitHub, and feel free to send in pull requests with improvements and fixes. You can also get in touch
by emailing us at hello@hipolabs.com.


Credits
-------

HIPNetworking is brought to you by 
[Taylan Pince](http://taylanpince.com) and the [Hipo Team](http://hipolabs.com).


License
-------

HIPNetworking is licensed under the terms of the Apache License, version 2.0. Please see the LICENSE file for full details.
