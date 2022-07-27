#import "TXTTwitterCell.h"
#import <Preferences/PSSpecifier.h>

@implementation TXTTwitterCell {
    NSString *_user;
}

+ (NSString *)_urlForUsername:(NSString *)user {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"aphelion://"]]) {
        return [@"aphelion://profile/" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        return [@"tweetbot:///user_profile/" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific://"]]) {
        return [@"twitterrific:///profile?screen_name=" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings://"]]) {
        return [@"tweetings:///user?screen_name=" stringByAppendingString:user];
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        return [@"twitter://user?screen_name=" stringByAppendingString:user];
    } else {
        return [@"https://mobile.twitter.com/" stringByAppendingString:user];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
    _user = [specifier.properties[@"user"] copy];

    if (self) {
        specifier.cellType = PSLinkCell;
        specifier.buttonAction = @selector(txt_openURL:);
        specifier.properties[@"url"] = [self.class _urlForUsername:_user];

        self.detailTextLabel.text = [@"@" stringByAppendingString:_user];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:142.f / 255.f alpha:1];

        CGFloat size = 36.f;

        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, [UIScreen mainScreen].scale);
        specifier.properties[@"iconImage"] = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        _avatarView = [[UIView alloc] initWithFrame:self.imageView.bounds];
        _avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _avatarView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
        _avatarView.userInteractionEnabled = NO;
        _avatarView.clipsToBounds = YES;
        _avatarView.layer.cornerRadius = size / 2;
        [self.imageView addSubview:_avatarView];

        _avatarImageView = [[UIImageView alloc] initWithFrame:_avatarView.bounds];
        _avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _avatarImageView.alpha = 0;
        _avatarImageView.userInteractionEnabled = NO;
        _avatarImageView.layer.minificationFilter = kCAFilterTrilinear;
        [_avatarView addSubview:_avatarImageView];

        [self loadAvatar];
    }

    return self;
}

- (UIImage *)avatarImage {
    return _avatarImageView.image;
}

- (void)setAvatarImage:(UIImage *)avatarImage {
    _avatarImageView.image = avatarImage;

    if (_avatarImageView.alpha == 0) {
        [UIView animateWithDuration:0.15 animations:^{
                                             _avatarImageView.alpha = 1;
                                         }];
    }
}

- (void)loadAvatar {

    NSURL *twitterURL;

    if ([_user isEqualToString:@"ryannair05"]) {
        twitterURL = [NSURL URLWithString:@"https://pbs.twimg.com/profile_images/1161080936836018176/4GUKuGlb_200x200.jpg"];
    }
    else if ([_user isEqualToString:@"d3zb6z"]) {
        twitterURL = [NSURL URLWithString:@"https://pbs.twimg.com/profile_images/1124407974577917952/ioOk_7Ej_200x200.jpg"];
    }
    else {
        return;
    }

    if (self.avatarImage) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
        NSError __block *err = NULL;
        NSData __block *data;
        BOOL __block reqProcessed = false;
        
        NSURLRequest *request = [NSURLRequest requestWithURL:twitterURL];
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData  *_data, NSURLResponse *_response, NSError *_error) {
            err = _error;
            data = _data;
            reqProcessed = true;
        }] resume];

        while (!reqProcessed) {
            [NSThread sleepForTimeInterval:0];
        }

        if (err)
            return;

        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatarImage = [UIImage imageWithData:data];
        });
    });
}

- (void)dealloc {
    [_avatarView release];
    [_avatarImageView release];
    [_user release];
    [super dealloc];
}

@end
