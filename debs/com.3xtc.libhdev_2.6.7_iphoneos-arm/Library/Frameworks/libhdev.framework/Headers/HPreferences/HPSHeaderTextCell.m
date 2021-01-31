#import "HPSHeaderTextCell.h"

@implementation HPSHeaderTextCell {
  UILabel *label;
  UILabel *subLabel;
  NSArray *subtitles;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
  self = [super initWithReuseIdentifier:@"HPSHeaderTextCell"];
  if (self) {
    // set width of cell
    int kWidth = [[UIApplication sharedApplication] keyWindow].frame.size.width;
    if (IS_iPAD || IS_LANDSCAPE) {
      kWidth = kWidth / 2;
    }

    // tapGesture for labels
    UITapGestureRecognizer *labelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTap)];
    UITapGestureRecognizer *subLabelTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(subLabelTap)];

    // main label
    CGRect labelFrame = CGRectMake(0, 10, kWidth, 80);
    label = [[UILabel alloc] initWithFrame:labelFrame];
    [label setNumberOfLines:1];
    label.font = [UIFont systemFontOfSize:35];
    [label setText:[specifier.properties objectForKey:@"label"]];
    label.textColor = [HCommon colorFromHex:((HPSRootListController *)specifier.target).tintColorHex];
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:labelTapGesture];

    // sub label
    CGRect subLabelFrame = CGRectMake(0, 60, kWidth, 60);
    subtitles = [specifier.properties objectForKey:@"subtitles"];
    subLabel = [[UILabel alloc] initWithFrame:subLabelFrame];
    [subLabel setNumberOfLines:1];
    subLabel.font = [UIFont systemFontOfSize:15];
    [self rerollSubLabel];
    subLabel.textColor = [UIColor grayColor];
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.userInteractionEnabled = YES;
    [subLabel addGestureRecognizer:subLabelTapGesture];

    // resizing mask
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    subLabel.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);

    // add to view
    [self addSubview:label];
    [self addSubview:subLabel];
  }
  return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
  CGFloat prefHeight = 110.0;
  return prefHeight;
}

- (void)labelTap {
  [self rerollSubLabel];
}

- (void)subLabelTap {
  [self rerollSubLabel];
}

- (void)rerollSubLabel {
  uint32_t rnd = arc4random_uniform([subtitles count]);
  [subLabel setText:[subtitles objectAtIndex:rnd]];
}
@end