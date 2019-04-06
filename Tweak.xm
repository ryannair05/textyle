#import "Tweak.h"

static BOOL enabled;
static NSArray *styles;
static NSArray *enabledStyles;
static NSDictionary *blacklist;
static BOOL menuOpen = NO;

static NSString *stylizeTextWithMap(NSString *text, NSDictionary *map) {
    NSMutableString *stylized = [NSMutableString string];
    NSUInteger length = text.length;
    unichar buffer[length+1];

    [text getCharacters:buffer range:NSMakeRange(0, length)];

    for (int i = 0; i < length; i++) {
        NSString *key = [NSString stringWithFormat:@"%C", buffer[i]];

        if ([map objectForKey:key]) {
            [stylized appendString:map[key]];
        } else {
            [stylized appendString:key];
        }
    }

    return stylized;
}

static NSString *stylizeTextSpongebob(NSString *text) {
    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
    NSMutableString *stylized = [NSMutableString string];
    NSUInteger length = text.length;
    unichar buffer[length+1];

    [text getCharacters:buffer range:NSMakeRange(0, length)];

    int j = 0;
    for (int i = 0; i < length; i++) {
        NSString *s = [NSString stringWithFormat:@"%C", buffer[i]];

        if ([letters characterIsMember:buffer[i]]) {
            [stylized appendString:(j++ % 2) ? [s localizedUppercaseString] : [s localizedLowercaseString]];
        } else {
            [stylized appendString:s];
        }
    }

    return stylized;
}

static NSString *stylizeTextWithCombiningChar(NSString *text, NSString *combiningChar) {
    NSMutableString *stylized = [NSMutableString string];
    NSUInteger length = text.length;
    unichar buffer[length+1];

    [text getCharacters:buffer range:NSMakeRange(0, length)];

    for (int i = 0; i < length; i++) {
        NSString *s = [NSString stringWithFormat:@"%C", buffer[i]];
        [stylized appendString:s];
        [stylized appendString:combiningChar];
    }

    return stylized;
}

%group Textyle

%hook UICalloutBar

%property (nonatomic, retain) UIMenuItem *txtMainMenuItem;
%property (nonatomic, retain) NSArray *txtStyleMenuItems;

- (id)initWithFrame:(CGRect)arg1 {
    self = %orig;

    if (!self.txtMainMenuItem) {
        self.txtMainMenuItem = [[UIMenuItem alloc] initWithTitle:@"Styles" action:@selector(txtOpenStyleMenu:)];
        self.txtMainMenuItem.dontDismiss = YES;
    }

    if (!self.txtStyleMenuItems) {
        NSMutableArray *items = [NSMutableArray array];

        for (NSDictionary *style in styles) {
            NSString *action = [NSString stringWithFormat:@"txt_%@", style[@"name"]];
            UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:style[@"label"] action:NSSelectorFromString(action)];

            [items addObject:item];
        }

        self.txtStyleMenuItems = items;
    }

    return self;
}

- (void)updateAvailableButtons {
    %orig;

    if (!self.extraItems) {
        self.extraItems = @[];
    }

    BOOL isSelected = NO;
    NSMutableArray *currentSystemButtons = MSHookIvar<NSMutableArray *>(self, "m_currentSystemButtons");
    for (UICalloutBarButton *btn in currentSystemButtons) {
        if (btn.action == @selector(cut:)) {
            isSelected = YES;
        }
    }

    NSMutableArray *items = [self.extraItems mutableCopy];

    if (isSelected && enabled) {
        if (![items containsObject:self.txtMainMenuItem]) {
            [items addObject:self.txtMainMenuItem];
        }
    } else {
        [items removeObject:self.txtMainMenuItem];
    }

    if (menuOpen) {
        items = [NSMutableArray array];
        for (UIMenuItem *item in self.txtStyleMenuItems) {
            if (![items containsObject:item]) {
                [items addObject:item];
            }
        }
    } else {
        for (UIMenuItem *item in self.txtStyleMenuItems) {
            [items removeObject:item];
        }
    }

    self.extraItems = items;

    %orig;

    if (menuOpen) {
        for (UICalloutBarButton *btn in currentSystemButtons) {
            [btn removeFromSuperview];
        }
        [currentSystemButtons removeAllObjects];
    }
}

%end

%hook UIResponder

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    NSString *sel = NSStringFromSelector(action);
    NSRange match = [sel rangeOfString:@"txt_"];

    if (match.location == 0) {
        NSString *name = [sel substringFromIndex:4];
        return menuOpen && [enabledStyles containsObject:name];
    }

    if (menuOpen) return NO;

    return %orig;
}

%new
- (void)txtOpenStyleMenu:(UIResponder *)sender {
    menuOpen = YES;

    UICalloutBar *calloutBar = [UICalloutBar sharedCalloutBar];
    [calloutBar resetPage];
    [calloutBar update];
}

%new
- (void)txtCloseStyleMenu {
    menuOpen = NO;
}

- (BOOL)becomeFirstResponder {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(txtCloseStyleMenu) name:UIMenuControllerDidHideMenuNotification object:nil];
    return %orig;
}

%new
- (void)txtDidSelectStyle:(NSString *)name {
    menuOpen = NO;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name == %@)", name];
    NSArray *arr = [styles filteredArrayUsingPredicate:predicate];
    NSDictionary *style = [arr objectAtIndex:0];

    NSRange selectedRange = [self _selectedNSRange];
    NSString *original = [self _fullText];
    NSString *selectedText = [original substringWithRange:selectedRange];

    NSString *stylized;
    if (style[@"map"]) {
        stylized = stylizeTextWithMap(selectedText, style[@"map"]);
    } else if (style[@"combine"]) {
        stylized = stylizeTextWithCombiningChar(selectedText, style[@"combine"]);
    } else if ([style[@"function"] isEqualToString:@"spongebob"]) {
        stylized = stylizeTextSpongebob(selectedText);
    }

    UITextRange *textRange = [self _textRangeFromNSRange:selectedRange];
    [self replaceRange:textRange withText:stylized]; 
}

%end

%hook UITextField

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (%orig(sel)) {
        return %orig(sel);
    }
    return %orig(@selector(txtDidSelectStyle:));
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *sel = NSStringFromSelector([invocation selector]);
    NSRange match = [sel rangeOfString:@"txt_"];

    if (match.location == 0) {
        [self txtDidSelectStyle:[sel substringFromIndex:4]];
    } else {
        %orig(invocation);
    }
}

%end

%hook UITextView

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (%orig(sel)) {
        return %orig(sel);
    }
    return %orig(@selector(txtDidSelectStyle:));
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *sel = NSStringFromSelector([invocation selector]);
    NSRange match = [sel rangeOfString:@"txt_"];

    if (match.location == 0) {
        [self txtDidSelectStyle:[sel substringFromIndex:4]];
    } else {
        %orig(invocation);
    }
}

%end

%end

static void loadPrefs() {
    NSString *preferencesPath = @"/User/Library/Preferences/com.d11z.textyle.plist";
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:preferencesPath];

    if (!preferences) {
        preferences = [[NSMutableDictionary alloc] init];
        enabled = YES;
    } else {
        enabled = [[preferences objectForKey:@"Enabled"] boolValue];
    }
}

static void loadBlacklist() {
    NSString *blacklistPreferencesPath = @"/User/Library/Preferences/com.d11z.textyle.blacklist.plist";
    blacklist = [[NSMutableDictionary alloc] initWithContentsOfFile:blacklistPreferencesPath];

    if (!blacklist) {
        blacklist = [[NSMutableDictionary alloc] init];
    }
}

static void loadStyles() {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:kUserStylesPath]) {
        styles = [[NSArray alloc] initWithContentsOfFile:@"/Library/Application Support/Textyle/styles.plist"];
    } else {
        styles = [[NSArray alloc] initWithContentsOfFile:kUserStylesPath];
    }
}

static void loadEnabledStyles() {
    NSString *stylePreferencesPath = @"/User/Library/Preferences/com.d11z.textyle.styles.plist";
    NSMutableDictionary *stylePreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:stylePreferencesPath];

    NSMutableArray *_enabledStyles = [NSMutableArray array];
    for (NSDictionary *style in styles) {
        if (!stylePreferences) {
            [_enabledStyles addObject:style[@"name"]];
        } else {
            if ([[stylePreferences objectForKey:style[@"name"]] boolValue]) {
                [_enabledStyles addObject:style[@"name"]];
            }
        }
    }

    enabledStyles = [_enabledStyles copy]; 
}

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadPrefs();
}

static void enabledStylesNotificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    loadEnabledStyles();
}

__attribute__((always_inline)) bool check_crack() {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/com.d11z.textyle.list"];
}

%ctor {
    // Someone smarter than me invented this.
    // https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/
    bool shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                        || [processName isEqualToString:@"CoreAuthUI"]
                        || [processName isEqualToString:@"InCallService"]
                        || [processName isEqualToString:@"MessagesNotificationViewService"]
                        || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if (!isFileProvider && isApplication && !skip) {
                shouldLoad = YES;
            }
        }
    }

    loadBlacklist();

    NSString *identifier = [NSBundle mainBundle].bundleIdentifier;
    NSString *blacklistKey = [NSString stringWithFormat:@"disableTextyle-%@", identifier];

    if ([[blacklist objectForKey:blacklistKey] boolValue]) {
        shouldLoad = NO;
    }

    if (!shouldLoad || !check_crack()) {
        return;
    }

    loadStyles();

    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    notificationCallback,
                                    CFSTR("com.d11z.textyle/preferences"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce
                                    );

    loadEnabledStyles();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    enabledStylesNotificationCallback,
                                    CFSTR("com.d11z.textyle.styles/enabledStyles"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce
                                    );

    %init(Textyle);
}
