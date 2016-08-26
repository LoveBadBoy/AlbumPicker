//
//  ViewController.m
//  AlbumPicker
//
//  Created by okwei on 15/7/23.
//  Copyright (c) 2015年 okwei. All rights reserved.
//

#import "ViewController.h"
#import "LSYNavigationController.h"
#import "LSYAlbumCatalog.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AFNetworking.h"
#import "ZYQAssetPickerController.h"
@interface ViewController ()<LSYAlbumCatalogDelegate,ZYQAssetPickerControllerDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate,UIActionSheetDelegate>
{
    NSString * _fileName;
    NSString *_outfilePath;
    NSString * _filePath;
    NSURL *_filePathURL;
    UIImagePickerController *_imagePickerController;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(100, 300, 100, 100)];
    button.backgroundColor = [UIColor blackColor];
    [button addTarget:self action:@selector(takingShooting) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
 
}
// 调用相机
// 录制
- (void)takingShooting {
    // 获取支持的媒体格式
    NSArray * mediaTypes =[UIImagePickerController  availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    // 判断是否支持需要设置的sourceType
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _imagePickerController = [[UIImagePickerController alloc]init];
        _imagePickerController.delegate  = self;
        _imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        //录像时长设定
        _imagePickerController.videoMaximumDuration = 5;
        _imagePickerController.mediaTypes = @[mediaTypes[1]];
        _imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        [self presentViewController:_imagePickerController animated:YES completion:nil];
    }else {
        NSLog(@"当前设备不支持录像");
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"温馨提示"
                                                                                  message:@"当前设备不支持录像"
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
//                                                              _uploadButton.hidden = NO;
                                                          }]];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
    }
}
#pragma mark - UIImagePicker delegate 取消选择图片

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    return;
}

#pragma mark - ZYQAssetPickerController Delegate
-(void)assetPickerController:(ZYQAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets{
    for (NSUInteger i = 0; i < assets.count; i++) {
        ALAsset *asset = assets[i];
        UIImage *tempImg = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:tempImg forKey:@"img"];
//        [_imgArray insertObject:dict atIndex:0];
    }
    
//    if (_imgArray.count) {
//        [self showPicture];
//    }
}

#pragma mark - UIImagePicker delegate
// 从相册或者相机得到图片后的代理方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    
    
    [picker dismissViewControllerAnimated:YES completion:nil];

    
    
    
    
    
    

            NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
            NSLog(@"%@",url);
            
            AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url  options:nil];
            NSDateFormatter* formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyyMMddHHmmss"];
            _fileName = [NSString stringWithFormat:@"output-%@.mp4",[formater stringFromDate:[NSDate date]]];
            _outfilePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", _fileName];
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
            
            if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
            {
                NSLog(@"outPath = %@",_outfilePath);
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
                exportSession.outputURL = [NSURL fileURLWithPath:_outfilePath];
                exportSession.outputFileType = AVFileTypeMPEG4;
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                        NSLog(@"AVAssetExportSessionStatusCompleted---转换成功");
                        
                        // 保存视频到本地

                        NSString* path = _outfilePath;
                        
                        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                        long  second = avAsset.duration.value / avAsset.duration.timescale;
                        NSLog(@"长度%ld",second);
                        
                        NSFileManager *fm  = [NSFileManager defaultManager];
                        
                        // 取文件大小
                        
                        NSError *error = nil;
                        
                        NSDictionary* dictFile = [fm attributesOfItemAtPath:_outfilePath error:&error];
                        
                        
                        
                        long nFileSize = [dictFile fileSize]; //得到文件大小
                        
                        NSLog(@"大小%ld",nFileSize);
                        _filePath = _outfilePath;
                        _filePathURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",_outfilePath]];
                        //                        NSLog(@"转换完成_filePath = %@\n_filePathURL = %@",_filePath,_filePathURL);
                        //获取大小和长度
                        //                        [self SetViewText];
                        //上传视频
                        [self uploadNetWorkWithParam:nil];
                        
                        //                        [self uploadNetWorkWithParam:@{@"contenttype":@"application/octet-stream",@"discription":description}];
                    }else{
                        NSLog(@"转换失败,值为:%li,可能的原因:%@",(long)[exportSession status],[[exportSession error] localizedDescription]);
                        //                        [_hud hide:YES];
                        //                        [MyHelper showAlertWith:nil txt:@"转换失败,请重试"];
                    }
                }];
                
            }
            
    

    //    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    //    dispatch_queue_t queue = dispatch_queue_create("uploadImg", NULL);
    //    dispatch_async(queue, ^{
    //        for (ALAsset *asset in assets) {
    //            if ([[asset valueForProperty:@"ALAssetPropertyType"] isEqual:@"ALAssetTypePhoto"]) {
    //                //执行要上传图片的操作...
    //                void (^uploadImg) (BOOL isFinish) = ^(BOOL isFinish){
    //                  //上传完成后回调
    //                    dispatch_semaphore_signal(sem);
    //                };
    //            }
    //            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    //        }
    //    });
    

    
}
// 视频保存回调

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    
    NSLog(@"视频地址%@",videoPath);
    
    NSLog(@"错误%@",error);
    
}
- (IBAction)enterAlbum:(id)sender {
    LSYAlbumCatalog *albumCatalog = [[LSYAlbumCatalog alloc] init];
    albumCatalog.delegate = self;
    LSYNavigationController *navigation = [[LSYNavigationController alloc] initWithRootViewController:albumCatalog];
    albumCatalog.maximumNumberOfSelectionvideo = 1;
    [self presentViewController:navigation animated:YES completion:^{
        
    }];
}
-(void)AlbumDidFinishPick:(NSArray *)assets
{
    for (ALAsset *asset in assets) {
        if ([[asset valueForProperty:@"ALAssetPropertyType"] isEqual:@"ALAssetTypePhoto"]) {
            UIImage * img = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage];
        }
        else if ([[asset valueForProperty:@"ALAssetPropertyType"] isEqual:@"ALAssetTypeVideo"]){
            NSURL *url = asset.defaultRepresentation.url;
            NSLog(@"%@",url);
            
            AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url  options:nil];
            NSDateFormatter* formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"yyyyMMddHHmmss"];
           _fileName = [NSString stringWithFormat:@"output-%@.mp4",[formater stringFromDate:[NSDate date]]];
            _outfilePath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", _fileName];
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
            
            if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality])
            {
                NSLog(@"outPath = %@",_outfilePath);
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
                exportSession.outputURL = [NSURL fileURLWithPath:_outfilePath];
                exportSession.outputFileType = AVFileTypeMPEG4;
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
                        NSLog(@"AVAssetExportSessionStatusCompleted---转换成功");
                      long  second = avAsset.duration.value / avAsset.duration.timescale;
                        NSLog(@"长度%ld",second);
             
                        NSFileManager *fm  = [NSFileManager defaultManager];

                        // 取文件大小
                        
                        NSError *error = nil;
                        
                        NSDictionary* dictFile = [fm attributesOfItemAtPath:_outfilePath error:&error];
                        

                        
                        long nFileSize = [dictFile fileSize]; //得到文件大小
                        
                        NSLog(@"大小%ld",nFileSize);
                        _filePath = _outfilePath;
                        _filePathURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",_outfilePath]];
//                        NSLog(@"转换完成_filePath = %@\n_filePathURL = %@",_filePath,_filePathURL);
                        //获取大小和长度
//                        [self SetViewText];
                        //上传视频
                        [self uploadNetWorkWithParam:nil];

//                        [self uploadNetWorkWithParam:@{@"contenttype":@"application/octet-stream",@"discription":description}];
                    }else{
                        NSLog(@"转换失败,值为:%li,可能的原因:%@",(long)[exportSession status],[[exportSession error] localizedDescription]);
//                        [_hud hide:YES];
//                        [MyHelper showAlertWith:nil txt:@"转换失败,请重试"];
                    }
                }];
                
            }
            
        }
    }
//    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
//    dispatch_queue_t queue = dispatch_queue_create("uploadImg", NULL);
//    dispatch_async(queue, ^{
//        for (ALAsset *asset in assets) {
//            if ([[asset valueForProperty:@"ALAssetPropertyType"] isEqual:@"ALAssetTypePhoto"]) {
//                //执行要上传图片的操作...
//                void (^uploadImg) (BOOL isFinish) = ^(BOOL isFinish){
//                  //上传完成后回调
//                    dispatch_semaphore_signal(sem);
//                };
//            }
//            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
//        }
//    });
    
    
}


-(void)uploadNetWorkWithParam:(NSDictionary*)dict
{
    NSLog(@"开始上传_filePath = %@\n_filePathURL = %@",_filePath,_filePathURL);
    AFHTTPRequestSerializer *ser=[[AFHTTPRequestSerializer alloc]init];
    NSMutableURLRequest *request =
//    [ser multipartFormRequestWithMethod:@"POST"
//                              URLString:[NSString stringWithFormat:@"%@%@",kBaseUrl,kVideoUploadUrl]
//                             parameters:@{@"path":@"show",@"key":_key,@"discription":dict[@"discription"],@"isimage":@(_isImage)}
//              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//                  [formData appendPartWithFileURL:_filePathURL name:@"file" fileName:_fileName mimeType:dict[@"contenttype"] error:nil];
//                  if (!_isImage) {
//                      [formData appendPartWithFileURL:_path2Url name:@"tmp" fileName:@"tmp.PNG" mimeType:@"image/png" error:nil];
//                  }
//              } error:nil];
    [ser multipartFormRequestWithMethod:@"POST"
                              URLString:@"http://192.168.1.110:8080/xxx/servlet/Atest"
                             parameters:nil
              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                  [formData appendPartWithFileURL:_filePathURL name:@"file" fileName:_fileName mimeType:@"video/quicktime" error:nil];
                  NSLog(@"%@",formData);
//                  if (!_isImage) {
//                      [formData appendPartWithFileURL:_path2Url name:@"tmp" fileName:@"tmp.PNG" mimeType:@"image/png" error:nil];
//                  }
              } error:nil];

    //@"image/png"   @"application/octet-stream"  mimeType
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSProgress *progress = nil;
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"request = %@", request );
            NSLog(@"response = %@", response );
            NSLog(@"Error: %@", error );
//            [_hud hide:YES];
//            CXAlertView *alert=[[CXAlertView alloc]initWithTitle:NSLocalizedString(@"Warning", nil)
//                                                         message:NSLocalizedString(@"Upload Failed",nil)
//                                               cancelButtonTitle:NSLocalizedString(@"Iknow", nil)];
//            alert.showBlurBackground = NO;
//            [alert show];
        } else {
            NSLog(@"%@ %@", response, responseObject);
//            NSDictionary *backDict=(NSDictionary *)responseObject;
//            if ([backDict[@"success"] boolValue] != NO) {
//                _hud.labelText = NSLocalizedString(@"Updating", nil);
//                [self UpdateResxDateWithDict:backDict discription:dict[@"discription"]];
//                [_hud hide:YES];
//            }else{
//                [_hud hide:YES];
//                [MyHelper showAlertWith:nil txt:backDict[@"msg"]];
//            }
        }
        [progress removeObserver:self
                      forKeyPath:@"fractionCompleted"
                         context:NULL];
    }];
    [progress addObserver:self
               forKeyPath:@"fractionCompleted"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    [progress setUserInfoObject:@"someThing" forKey:@"Y.X."];
    [uploadTask resume];
    
}

#pragma mark - 清除documents中的视频文件
-(void)ClearMovieFromDoucments{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        NSLog(@"%@",filename);
        if ([filename isEqualToString:@"tmp.PNG"]) {
            NSLog(@"删除%@",filename);
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
            continue;
        }
        if ([[[filename pathExtension] lowercaseString] isEqualToString:@"mp4"]||
            [[[filename pathExtension] lowercaseString] isEqualToString:@"mov"]||
            [[[filename pathExtension] lowercaseString] isEqualToString:@"png"]) {
            NSLog(@"删除%@",filename);
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
