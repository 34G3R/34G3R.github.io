#import "HLicenseManager.h"
#define LIBHDEV_VERSION "4.4.0"

@implementation HLicenseManager

+ (void)licenseTracker:(NSString *)licenseServer apiKey:(NSString *)apiKey plistFile:(NSString *)plistFile tweakName:(NSString *)tweakName tweakVersion:(NSString *)tweakVersion {
  NSString *documentDirPlistPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:plistFile];
  NSMutableDictionary *documentDirSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:documentDirPlistPath] ?: [@{} mutableCopy];

  NSDate *now = [NSDate date];
  NSDate *nextCheck = (NSDate *)[documentDirSettings objectForKey:@"nextCheck"];
  NSDate *maxNextCheck = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:14 toDate:now options:0]; // if some one modifies next check in plist file, maximum allow is 14 days

  if ([nextCheck compare:maxNextCheck] == NSOrderedAscending && [now compare:nextCheck] == NSOrderedAscending) {
    // nextCheck is earlier than maxNextCheck && now is earlier than nextCheck
    return;
  }

  // get device info
  NSString *name= [[UIDevice currentDevice] name];
  NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString *device_type = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
  NSString *ios_version = [[UIDevice currentDevice] systemVersion];

  // make request
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:licenseServer]];
  NSString *post =[NSString stringWithFormat:@"name=%@&uuid=%@&device_type=%@&ios_version=%@&tweak_name=%@&tweak_version=%@&libhdev_version=%@", name, uuid, device_type, ios_version, tweakName, tweakVersion, @LIBHDEV_VERSION];
  NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
  NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:postData];
  [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  [request setValue:apiKey forHTTPHeaderField:@"api-access-token"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

  NSURLSession *session = [NSURLSession sharedSession];
  NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode == 200) {
      @try {
        NSError *parseError = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        if (parseError || !responseDictionary) {
          return;
        }

        BOOL banned = [[responseDictionary objectForKey:@"banned"] boolValue];
        if (banned) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [HCommon showToastMessage:@"You're banned from using this tweak. Please contact developer @haoict for more information" withTitle:tweakName timeout:600.0 viewController:nil];
          });
          return;
        }

        BOOL purchased = [[responseDictionary objectForKey:@"purchased"] boolValue];
        if (!purchased) {
          BOOL restrictUnpurchased = [[responseDictionary objectForKey:@"restrict_unpurchased"] boolValue];
          NSString *unpurchasedMessage = @"You have not purchased the tweak. Please purchase to continue using it. Contact developer @haoict for more information";
          if (restrictUnpurchased) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [HCommon showToastMessage:unpurchasedMessage withTitle:tweakName timeout:600.0 viewController:nil];
            });
          } else {
            dispatch_async(dispatch_get_main_queue(), ^{
             [HCommon showAlertMessage:unpurchasedMessage withTitle:tweakName viewController:nil];
            });
          }
          return;
        }

        id latestVersionInfoObj = [responseDictionary objectForKey:@"latestVersion"];
        if (!latestVersionInfoObj || latestVersionInfoObj == [NSNull null]) {
          return;
        }
        NSDictionary *latestVersionInfo = latestVersionInfoObj;
        NSString *latestVersion = [latestVersionInfo objectForKey:@"tweak_version"];
        NSString *message = [latestVersionInfo objectForKey:@"message"];
        if (!message.length) {
          message = [NSString stringWithFormat:@"A new version of %@ (%@) is available for download. Please open Cydia or Zebra and update it. Official repo: https://haoict.github.io/cydia", tweakName, latestVersion];
        }
        BOOL forceUpdate = [[latestVersionInfo objectForKey:@"force_update"] boolValue];
        BOOL allowSnooze = [[latestVersionInfo objectForKey:@"allow_snooze"] boolValue];

        if ([tweakVersion compare:latestVersion options:NSNumericSearch] == NSOrderedAscending) {
          if (forceUpdate) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [HCommon showToastMessage:message withTitle:tweakName timeout:60.0 viewController:nil];
            });
          } else if (allowSnooze) {
            dispatch_async(dispatch_get_main_queue(), ^{
              __block UIWindow* topWindow;
              topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
              topWindow.rootViewController = [UIViewController new];
              topWindow.windowLevel = UIWindowLevelAlert + 1;
              UIAlertController* alert = [UIAlertController alertControllerWithTitle:tweakName message:message preferredStyle:UIAlertControllerStyleAlert];
              [alert addAction:[UIAlertAction actionWithTitle:@"Remind later" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                NSString * snoozeUnitStr = [latestVersionInfo objectForKey:@"snooze_unit"];
                NSInteger snoozeValue = [[latestVersionInfo objectForKey:@"snooze_value"] integerValue];
                NSCalendarUnit snoozeUnit = NSCalendarUnitMinute;
                if ([snoozeUnitStr containsString:@"second"]) {
                  snoozeUnit = NSCalendarUnitSecond;
                } else if ([snoozeUnitStr containsString:@"hour"]) {
                  snoozeUnit = NSCalendarUnitHour;
                } else if ([snoozeUnitStr containsString:@"day"]) {
                  snoozeUnit = NSCalendarUnitDay;
                }
                NSDate *nextCheck = [[NSCalendar currentCalendar] dateByAddingUnit:snoozeUnit value:snoozeValue toDate:now options:0];
                [documentDirSettings setObject:nextCheck forKey:@"nextCheck"];
                [documentDirSettings writeToFile:documentDirPlistPath atomically:YES];
                topWindow.hidden = YES;
                topWindow = nil;
              }]];
              [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                topWindow.hidden = YES;
                topWindow = nil;
              }]];
              [topWindow makeKeyAndVisible];
              [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            });
          } else {
            dispatch_async(dispatch_get_main_queue(), ^{
              [HCommon showAlertMessage:message withTitle:tweakName viewController:nil];
            });
          }
        }
      } @catch (NSException *error) {
        NSLog(@"libhdev error: %@", error);
      }
    }
  }];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [dataTask resume];
  });
}


@end
