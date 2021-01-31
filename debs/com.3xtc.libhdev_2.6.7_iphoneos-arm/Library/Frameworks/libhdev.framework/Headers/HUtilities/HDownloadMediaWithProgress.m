#import "HDownloadMediaWithProgress.h"

@implementation HDownloadMediaWithProgress

- (void)checkPermissionToPhotosAndDownloadURL:(NSURL *)url appendExtension:(NSString *)fileExtension mediaType:(HDownloadMediaType)mediaType toAlbum:(NSString *)albumName view:(UIView *)view {
  if (!url) {
    [HCommon showAlertMessage:@"No URL to download" withTitle:@"Error" viewController:nil];
    return;
  }

  if (!view) {
    [HCommon showAlertMessage:@"Invalid UIView to show download progress" withTitle:@"Error" viewController:nil];
    return;
  }

  self.view = view;
  self.mediaUrl = url;
  self.fileExtension = fileExtension;
  self.mediaType = mediaType;
  self.albumName = albumName;
  [self createProgressView];
  [self checkPermissionToPhotos];
}

- (void)checkPermissionToPhotosAndDownload:(NSString *)url appendExtension:(NSString *)fileExtension mediaType:(HDownloadMediaType)mediaType toAlbum:(NSString *)albumName view:(UIView *)view {
  [self checkPermissionToPhotosAndDownloadURL:[NSURL URLWithString:url] appendExtension:fileExtension mediaType:mediaType toAlbum:albumName view:view];
}

- (void)checkPermissionToPhotosAndDownloadURL:(NSURL *)url appendExtension:(NSString *)fileExtension mediaType:(HDownloadMediaType)mediaType toAlbum:(NSString *)albumName viewController:(UIViewController *)viewController {
  if (!viewController) {
    [HCommon showAlertMessage:@"Invalid UIViewController to show download progress" withTitle:@"Error" viewController:nil];
    return;
  }
  [self checkPermissionToPhotosAndDownloadURL:url appendExtension:fileExtension mediaType:mediaType toAlbum:albumName view:viewController.view];
}

- (void)checkPermissionToPhotosAndDownload:(NSString *)url appendExtension:(NSString *)fileExtension mediaType:(HDownloadMediaType)mediaType toAlbum:(NSString *)albumName viewController:(UIViewController *)viewController {
  if (!viewController) {
    [HCommon showAlertMessage:@"Invalid UIViewController to show download progress" withTitle:@"Error" viewController:nil];
    return;
  }
  [self checkPermissionToPhotosAndDownloadURL:[NSURL URLWithString:url] appendExtension:fileExtension mediaType:mediaType toAlbum:albumName view:viewController.view];
}

/**
 * Private methods
 */

- (void)checkPermissionToPhotos {
  PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
  switch (status) {
    case PHAuthorizationStatusNotDetermined: {
      [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
        if (authorizationStatus == PHAuthorizationStatusAuthorized) {
          [self downloadAndSaveMediaToPhotoLibrary];
        }
      }];
      break;
    }

    case PHAuthorizationStatusAuthorized: {
      [self downloadAndSaveMediaToPhotoLibrary];
      break;
    }

    case PHAuthorizationStatusDenied: {
      __block UIWindow* topWindow;
      topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
      topWindow.rootViewController = [UIViewController new];
      topWindow.windowLevel = UIWindowLevelAlert + 1;
      UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Permission Required" message:@"App needs permission to Photos" preferredStyle:UIAlertControllerStyleAlert];
      [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        topWindow.hidden = YES;
        topWindow = nil;
      }]];
      [alert addAction:[UIAlertAction actionWithTitle:@"Go To Settings" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        topWindow.hidden = YES;
        topWindow = nil;
      }]];
      [topWindow makeKeyAndVisible];
      [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
      break;
    }

    case PHAuthorizationStatusRestricted: {
      [HCommon showAlertMessage:@"You don't have permission to Photos" withTitle:@"Restricted!" viewController:nil];
      break;
    }
  }
}

- (void)downloadAndSaveMediaToPhotoLibrary {
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];

  NSURLSessionDownloadTask* downloadTask = [session downloadTaskWithURL:self.mediaUrl];
  [downloadTask resume];
}

- (void)createProgressView {
  self.percentageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 125.0, 125.0)];
  self.percentageLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
  self.percentageLabel.layer.masksToBounds = YES;
  self.percentageLabel.layer.cornerRadius = 12;
  self.percentageLabel.textAlignment = NSTextAlignmentCenter;
  self.percentageLabel.textColor = [UIColor whiteColor];
  self.percentageLabel.numberOfLines = 0;
  self.percentageLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.percentageLabel.text = @"Starting...";
  [self.percentageLabel setCenter:self.view.center];
  [self.view addSubview:self.percentageLabel];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
  NSString* fileName = [self.mediaUrl lastPathComponent];
  if (self.fileExtension) {
    fileName = [fileName stringByAppendingPathExtension:self.fileExtension];
  }
  [location setResourceValue:fileName forKey:NSURLNameKey error:nil];
  location = [[location URLByDeletingLastPathComponent] URLByAppendingPathComponent:fileName];

  void (^completionHandlerBlock)(BOOL success, NSError* error) = ^void(BOOL success, NSError* error) {
    [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
    if (success) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.percentageLabel.text = @"Download Success";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [self.percentageLabel removeFromSuperview];
        });
      });
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.percentageLabel removeFromSuperview];
        [HCommon showAlertMessage:[error localizedDescription] withTitle:@"Download Error" viewController:nil];
      });
    }
  };

  if (!self.albumName.length) {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      if (self.mediaType == Image) {
        [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:location];
      } else if (self.mediaType == Video) {
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:location];
      }
    } completionHandler:completionHandlerBlock];
  } else {
    void (^saveBlock)(PHAssetCollection *assetCollection) = ^void(PHAssetCollection *assetCollection) {
      [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetChangeRequest;
        if (self.mediaType == Image) {
          assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:location];
        } else if (self.mediaType == Video) {
          assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:location];
        }
        PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
      } completionHandler:completionHandlerBlock];
    };

    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"localizedTitle = %@", self.albumName];
    PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:fetchOptions];
    if (fetchResult.count > 0) {
      saveBlock(fetchResult.firstObject);
    } else {
      __block PHObjectPlaceholder *albumPlaceholder;
      [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:self.albumName];
        albumPlaceholder = changeRequest.placeholderForCreatedAssetCollection;
      } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
          PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumPlaceholder.localIdentifier] options:nil];
          if (fetchResult.count > 0) {
            saveBlock(fetchResult.firstObject);
          }
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            [self.percentageLabel removeFromSuperview];
            [HCommon showAlertMessage:[error localizedDescription] withTitle:@"Error creating album" viewController:nil];
          });
        }
      }];
    }
  }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(NSError *)error {
  if (error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.percentageLabel removeFromSuperview];
      [HCommon showAlertMessage:[error localizedDescription] withTitle:@"Download Error" viewController:nil];
    });
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
  float progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite * 100;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.percentageLabel.text = [NSString stringWithFormat:@"%.1f%%", progress];;
  });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}
@end
