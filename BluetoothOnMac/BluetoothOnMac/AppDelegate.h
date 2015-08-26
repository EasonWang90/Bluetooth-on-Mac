//
//  AppDelegate.h
//  BluetoothOnMac
//
//  Created by Eason on 2015-07-09.
//  Copyright (c) 2015 Big data. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/pwr_mgt/IOPMLibDefs.h>
#import <IOKit/pwr_mgt/IOPMKeys.h>
#import <Availability.h>
#import <CoreFoundation/CFArray.h>
@interface AppDelegate : NSObject <NSApplicationDelegate,CBPeripheralManagerDelegate>


@end

