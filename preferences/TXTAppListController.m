#import "TXTAppListController.h"

@implementation TXTAppListController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIColor *tintColor = [UIColor colorWithRed:1.00 green:0.18 blue:0.33 alpha:0.85f];
    settingsView = [[[UIApplication sharedApplication] windows] firstObject];

    settingsView.tintColor = tintColor;
    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = tintColor;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    settingsView.tintColor = nil;
}

@end
