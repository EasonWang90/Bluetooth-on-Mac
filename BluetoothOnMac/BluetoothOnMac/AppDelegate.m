//
//  AppDelegate.m
//  BluetoothOnMac
//
//  Created by Eason on 2015-07-09.
//  Copyright (c) 2015 Big data. All rights reserved.
//

#import "AppDelegate.h"
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) CBPeripheralManager   *peripheralManager;
@end

@implementation AppDelegate{
    NSTimer *advertiseTimer;
    NSTimer *stopAdvertiseTimer;
    int wakeByUser;
    CFDateRef wakeFromSleepAt;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    [self fileNotifications];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    //NSLog(@"%ld",(long)peripheral.state);
    [advertiseTimer invalidate];
    [stopAdvertiseTimer invalidate];
    // Opt out from any other state
    if (CBPeripheralManagerStatePoweredOn == peripheral.state) {
        NSLog(@"11");
        [self advertise];
    }
//    if (CBPeripheralManagerStatePoweredOff == peripheral.state) {
//        NSLog(@"bluetooth not open");
//    }
    else{
        [self.peripheralManager stopAdvertising];
        NSLog(@"cannot advertising right now");
    }
    
}
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
}
- (void) advertise{
    if ([self.peripheralManager isAdvertising] == FALSE) {
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataLocalNameKey: @"12345",CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:@"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"]] }];
        advertiseTimer = [NSTimer scheduledTimerWithTimeInterval: 10
                                                          target: self
                                                        selector:@selector (stopAdvertise)
                                                        userInfo: nil
                                                         repeats:NO];
    }
    
    NSLog(@"Advertising");
}
- (void) stopAdvertise{
    if ([self.peripheralManager isAdvertising] == TRUE) {
        [self.peripheralManager stopAdvertising];
        stopAdvertiseTimer = [NSTimer scheduledTimerWithTimeInterval: 50
                                                              target: self
                                                            selector:@selector (advertise)
                                                            userInfo: nil
                                                             repeats:NO];

    }
       // NSLog(@"%hhd",[self.peripheralManager isAdvertising]);
    NSLog(@"Advertising stopped!");
}
- (void) receiveSleepNote: (NSNotification*) note
{
    NSLog(@"receiveSleepNote: %@", [note name]);
    //NSTimeInterval interval = [[NSTimeZone systemTimeZone] secondsFromGMT];
    CFAbsoluteTime wakeTime = CFAbsoluteTimeGetCurrent()+30;
    wakeFromSleepAt = CFDateCreate(NULL, wakeTime);
   // CFShow(wakeFromSleepAt);
    IOReturn success = IOPMSchedulePowerEvent(wakeFromSleepAt, CFSTR("bluetoothWake"), CFSTR(kIOPMAutoWakeOrPowerOn));
   // NSLog(@"%x",success);
    if (success == kIOReturnSuccess)
    {
        //[self.peripheralManager stopAdvertising];
        NSLog(@"schedule wake up event success");
    }
}

- (void) receiveWakeNote: (NSNotification*) note
{
    NSLog(@"receiveWakeNote: %@", [note name]);
    CFArrayRef eventsArray = IOPMCopyScheduledPowerEvents();
    NSArray *eventArray = CFBridgingRelease(eventsArray);
    //CFShow(eventsArray);
    [self checkWakeEvent:eventArray];
    if (wakeByUser == 0) {
        NSLog(@"not wake up by user!");
        [NSTimer scheduledTimerWithTimeInterval: 12
                                             target: self
                                           selector:@selector (sleep)
                                           userInfo: nil
                                            repeats:NO];
    }
    else{
        NSLog(@"wake up by user!");
        IOReturn success = IOPMCancelScheduledPowerEvent(wakeFromSleepAt, CFSTR("bluetoothWake"), CFSTR(kIOPMAutoWakeOrPowerOn));
        if (success == kIOReturnSuccess) {
            NSLog(@"cancel success");
        }
        else{
            NSLog(@"%x",success);
        }
    }
    NSLog(@"%@",eventArray);
//    if (![self.peripheralManager isAdvertising]) {
//        [self advertise];
//        NSLog(@"Awake advertising 0");
//    }
//    else{
//        NSLog(@"Awake advertising 1");
//    }
//    CFAbsoluteTime sleepTime = CFAbsoluteTimeGetCurrent()+7;
//    CFDateRef sleepFromWakeAt = CFDateCreate(NULL, sleepTime);
//    CFShow(sleepFromWakeAt);
//    IOReturn success = IOPMSchedulePowerEvent(sleepFromWakeAt, NULL, CFSTR(kIOPMAutoSleep));
//    io_connect_t port = IOPMFindPowerManagement(MACH_PORT_NULL);
// 
//    IOPMSleepSystem(port);
//    IOServiceClose(port);
    
//    [NSTimer scheduledTimerWithTimeInterval: 30
//                                     target: self
//                                   selector:@selector (sleep)
//                                   userInfo: nil
//                                    repeats:NO];
   // [self sleepInMinutes];


}
- (void) checkWakeEvent:(NSArray*)array{
    NSString* content;
    NSString* key2 = (__bridge NSString *)CFSTR(kIOPMPowerEventAppNameKey);
    if (array.count == 0) {
        wakeByUser = 0; // not wake by user
    }
    else{
        for (int i = 0; i<array.count; i++) {
            content = [array[i] objectForKey:key2];
            if ([content isEqualToString:@"bluetoothWake"]) {
                wakeByUser = 1;
            }
        }
    }
}
- (void) sleep{
    NSTask  *pmsetTask = [[NSTask alloc] init];
    pmsetTask.launchPath = @"/usr/bin/pmset";
    pmsetTask.arguments = @[@"sleepnow"];
    [pmsetTask launch];
}
- (void)sleepInMinutes{
    NSTask  *pmsetTask = [[NSTask alloc] init];
    pmsetTask.launchPath = @"/usr/bin/pmset";
    pmsetTask.arguments = @[@"-b sleep 1"];
    [pmsetTask launch];
}
- (void) fileNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
}
@end
