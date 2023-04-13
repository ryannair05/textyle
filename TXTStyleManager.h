#import <UIKit/UIKit.h>

@interface TXTStyleManager : NSObject
@property (nonatomic, strong) NSDictionary *activeStyle;
@property (nonatomic, strong) NSArray *enabledStyles;
+ (instancetype)sharedManager;
- (void)initForSpringBoard;
- (void)selectStyle:(NSString *)name;
- (void)loadActiveStyle;
- (void)loadEnabledStyles;
- (NSDictionary *)styleWithName:(NSString *)name;
@end
