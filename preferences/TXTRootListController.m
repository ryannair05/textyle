#import "TXTRootListController.h"
#import "TXTAppListController.h"
#import <Preferences/PSSpecifier.h>

@implementation TXTRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
    }

    return _specifiers;
}

- (void)showBlacklistController {
    TXTAppListController *appListController = [[TXTAppListController alloc] initWithIdentifier:@"com.ryannair05.textyle" andKey:@"Blacklist"];

    [self.navigationController pushViewController:appListController animated:YES];
    [appListController release];
    self.navigationItem.hidesBackButton = FALSE;
}

- (void)txt_openURL:(PSSpecifier *)specifier {
    NSURL *url = [NSURL URLWithString:specifier.properties[@"url"]];

    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
