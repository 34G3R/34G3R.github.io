#include "HPSSubListController.h"

@implementation HPSSubListController

- (id)specifiers {
  return _specifiers;
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier {
  self.plistName = [specifier propertyForKey:@"subPlistName"];
  NSString *title = [specifier name];

  _specifiers = [self loadSpecifiersFromPlistName:self.plistName target:self];

  [self setTitle:title];
  [self.navigationItem setTitle:title];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
  [self loadFromSpecifier:specifier];
  [super setSpecifier:specifier];
}

- (BOOL)shouldReloadSpecifiersOnResume {
  return false;
}

@end
