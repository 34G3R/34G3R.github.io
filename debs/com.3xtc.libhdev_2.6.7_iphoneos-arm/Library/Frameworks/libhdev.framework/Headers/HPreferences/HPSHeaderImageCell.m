#import "HPSHeaderImageCell.h"

#define DEFAULT_HEIGHT 200.0

@implementation HPSHeaderImageCell {
  double height;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
  self = [super initWithReuseIdentifier:@"HPSHeaderImageCell"];

  height = [specifier.properties[@"height"] doubleValue] ?: DEFAULT_HEIGHT;

  if (self) {
    UIView *headerImageViewContainer = [self prepareHeaderImage:specifier];
    [self addSubview:headerImageViewContainer];
    self.layer.masksToBounds = TRUE;
  }
  return self;
}

- (UIView *)prepareHeaderImage:(PSSpecifier *)specifier {
  int width = [[UIApplication sharedApplication] keyWindow].frame.size.width;
  if (IS_iPAD || IS_LANDSCAPE) {
    width = width / 2;
  }
  UIView *headerImageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];

  NSString *imagePath = specifier.properties[@"image"];
  if (imagePath) {
    UIImageView *headerImageView = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithContentsOfFile:imagePath]];
    headerImageView.frame = CGRectMake(0, 0, width, height);
    headerImageView.contentMode = UIViewContentModeScaleAspectFill;
    [headerImageViewContainer addSubview:headerImageView];
  }

  if (IS_iPAD || IS_LANDSCAPE) {
    headerImageViewContainer.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
  }

  return headerImageViewContainer;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
  return (CGFloat)height;
}

@end
