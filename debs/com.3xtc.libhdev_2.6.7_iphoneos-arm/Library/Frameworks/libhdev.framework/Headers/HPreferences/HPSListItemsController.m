#include "HPSListItemsController.h"

@implementation HPSListItemsController {
  HPSRootListController *rootVC;
}

- (HPSRootListController *)getRootVC {
  if (rootVC) {
    return rootVC;
  }
  NSArray *childVCs = self.parentViewController.childViewControllers;
  if ([childVCs[0] isKindOfClass:[HPSRootListController class]]) {
    return childVCs[0];
  } else if ([childVCs[1] isKindOfClass:[HPSRootListController class]]) {
    return childVCs[1];
  }
  return nil;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  rootVC = [self getRootVC];

  if (rootVC) {
    UIColor *tintColor = [HCommon colorFromHex:rootVC.tintColorHex];
    // set switches color
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    self.view.tintColor = tintColor;
    keyWindow.tintColor = tintColor;
    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = tintColor;
    // set navigation bar color
    self.navigationController.navigationController.navigationBar.barTintColor = tintColor;
    self.navigationController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationController.navigationBar setShadowImage: [UIImage new]];
    self.navigationController.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.translucent = NO;

    [self.navigationController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.navigationController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

  // re set navigationBar color to override libCephei
  rootVC = [self getRootVC];
  if (rootVC) {
    UIColor *tintColor = [HCommon colorFromHex:rootVC.tintColorHex];
    self.navigationController.navigationController.navigationBar.barTintColor = tintColor;
    self.navigationController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

  rootVC = [self getRootVC];
  cell.textLabel.textColor = [HCommon colorFromHex:rootVC ? rootVC.labelTextColorHex?:@"#333333" : @"#333333"];

  [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  return cell;
}

@end
