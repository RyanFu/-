/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"
#import <DiffMatchPatch/DiffMatchPatch.h>
#import <XHLaunchAd.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <React/RCTLinkingManager.h>
#import <SSZipArchive.h>
#import "JkFileHelper.h"
#import <Bugly/Bugly.h>
#import "RNCalliOSAction.h"
#import "JKvideoController.h"
#import "SVProgressHUD.h"
#import "EventEmitterManager.h"
//极光
// 引入JPush功能所需头文件
//#import "JPUSHService.h"
//// iOS10注册APNs所需头文件
//#ifdef NSFoundationVersionNumber_iOS_9_x_Max
//#import <UserNotifications/UserNotifications.h>
//#endif
//// 如果需要使用idfa功能所需要引入的头文件（可选）
//#import <AdSupport/AdSupport.h>

//友盟
#import <UMCommon/UMCommon.h>           // 公共组件是所有友盟产品的基础组件，必选
#import <UMAnalytics/MobClick.h>        // 统计组件
#import <UMShare/UMShare.h>    // 分享组件
#import <UMPush/UMessage.h>             // Push组件
#import <UserNotifications/UserNotifications.h>  // Push组件必须的系统库
/* 开发者可根据功能需要引入相应组件头文件，并导入相应组件库*/

/* 开发者可根据功能需要引入相应组件头文件，并导入相应组件库*/


@interface AppDelegate ()<UNUserNotificationCenterDelegate>
@property (nonatomic,strong) RCTBridge *bridge;
@property (nonatomic, strong) UINavigationController *nav;
@property (nonatomic, strong)NSArray *jslistArr;
@property (nonatomic, strong)NSString *jslistStr;
@property (nonatomic, strong)NSDictionary *AppUpdateInfo;
@property (nonatomic, strong)NSDictionary *RnUpdateInfo;


@end
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

  
  


 __block bool Isbackgrounddown=false;
  __block bool IspatchPakpage=false;
  __block NSURL *jsCodeLocation;
  //第一次打开的时候拷贝资源到沙盒，然后从沙盒中加载
  jsCodeLocation=[self getBundlePath];
  [self getJslist];
  __block RCTRootView *rootView ;
  [self setUMCompoent:launchOptions];
  [self setUpAd_show];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backToPreVersion) name:RCTJavaScriptDidFailToLoadNotification object:nil];
  

  
  
  
#if !DEBUG
//  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
 jsCodeLocation =  [[NSBundle mainBundle] URLForResource:@"main9" withExtension:@"jsbundle"];
  rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                         moduleName:@"kuaichecaifuRn"
                                  initialProperties:nil
                                      launchOptions:launchOptions];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:rootViewController];
  nav.navigationBarHidden=YES;
  self.window.rootViewController = nav;
  [self.window makeKeyAndVisible];
#else
  
  
  [self checkupdateSuccess:^(id  _Nullable responseobject) {
   
    JKLog(@"%@",responseobject);
     //原则 加载逻辑在前，更新逻辑在后
    //1 . 更新接口网络请求
    //2 遍历本地文件夹，判断是否存在可以加载的js文件，加载js
    //3 检查更新操作
//    JKLog(@"%@",[[responseobject objectForKey:@"data"] valueForKey:@"load"]);
    if ([[NSString stringWithFormat:@"%@",[responseobject objectForKey:@"code"]] isEqualToString:@"0"]) {
      Isbackgrounddown = false;
     //网络请求成功
      for (int i = 0; i<self.jslistArr.count; i++) {
        if ([[NSString stringWithFormat:@"%@",[[responseobject objectForKey:@"data"] valueForKey:@"loadRnVersion"]] isEqualToString:[self.jslistArr objectAtIndex:i]]) {
          //本地存在要加载的js文件
           NSString *jsversionCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
            NSString *txtPath = [jsversionCachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[[responseobject objectForKey:@"data"] valueForKey:@"loadRnVersion"]]];
           NSString *txtPath2 = [txtPath stringByAppendingPathComponent:@"main.jsbundle"];
          JKLog(@"%@",txtPath2);
          jsCodeLocation = [NSURL URLWithString:txtPath2];
          @try{
          rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                 moduleName:@"kuaichecaifuRn"
                                          initialProperties:nil
                                              launchOptions:launchOptions];
          rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
          self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
          UIViewController *rootViewController = [UIViewController new];
          rootViewController.view = rootView;
          UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:rootViewController];
          nav.navigationBarHidden=YES;
          self.window.rootViewController = nav;
          [self.window makeKeyAndVisible];
          }
          @catch(NSException *exception){
            //捕获的异常
             JKLog(@"js版本有问题");
            JKLog(@"%@",exception);
          }
          @finally{
            //结果处理
            JKLog(@"js版本有问题,删除了加载好的");
            
          }
        }else{
          //本地不存在要加载的js文件 加载上次加载的，加载一个不是活动页的js版本
          NSString *jsversionCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
          NSString *txtPath = [jsversionCachePath stringByAppendingPathComponent:@"180107"];
          jsCodeLocation = [NSURL URLWithString:txtPath];
          NSString *txtPath2 = [txtPath stringByAppendingPathComponent:@"main.jsbundle"];
          jsCodeLocation = [NSURL URLWithString:txtPath2];
          rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                 moduleName:@"kuaichecaifuRn"
                                          initialProperties:nil
                                              launchOptions:launchOptions];
          rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
          self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
          UIViewController *rootViewController = [UIViewController new];
          rootViewController.view = rootView;
          UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:rootViewController];
          nav.navigationBarHidden=YES;
          self.window.rootViewController = nav;
          [self.window makeKeyAndVisible];
          
          
          
          
        }
      }
      //检查更新操作 1.是否要更新。app更新还是js更新（js是增量更新还是全量更新）
      self.AppUpdateInfo =[[responseobject objectForKey:@"data"] valueForKey:@"appVersion"];
      self.RnUpdateInfo = [[responseobject objectForKey:@"data"]valueForKey:@"rnVersion"];
      JKLog(@"%@ ====%@",[self.AppUpdateInfo valueForKey:@"upgrade"],[self.AppUpdateInfo valueForKey:@"forceUpgrade"]);
      
      if ([[NSString stringWithFormat:@"%@",[self.AppUpdateInfo valueForKey:@"upgrade"]] isEqualToString:@"1"]) {
        //App更新
        if ([[NSString stringWithFormat:@"%@",[self.AppUpdateInfo valueForKey:@"forceUpgrade"]] isEqualToString:@"1"]) {
          //App是强制更新，弹窗展示更新信息，无取消按钮，升级跳转Appstore（是否需要和苹果服务器做校验）
          [self presentAlertWithtitle:@"要更新咯" message:@"" leftbutton:@"确定" rightbutton:@"升级" leftAct:^{
            
          } rightAct:^{
            
          }];
          
        }else{
          //App不强制更新， 展示弹窗
          [self presentAlertWithtitle:@"要更新咯" message:@"" leftbutton:@"取消" rightbutton:@"确定" leftAct:^{
            //App不更新, 检查rn是否需要更新
            if (!klObjectisEmpty([self.RnUpdateInfo valueForKey:@"version"]) ) {
              //需要更新
              if (!klObjectisEmpty([self.RnUpdateInfo valueForKey:@"incrementVersion"])) {
                if ([[self.RnUpdateInfo valueForKey:@"incrementVersion"] isEqualToString:@"all"]) {
                  //后台更新全量包
                  
                  [self getBackFullPackageDownurl:[self.RnUpdateInfo valueForKey:@"versionUrl"] packageName:[self.RnUpdateInfo valueForKey:@"version"]];
                  
                  
                  
                  
                }else{
                  //后台更新增量包
                }
              }
              
            }else{
              //不需要更新
              
            }
          } rightAct:^{
            
          }];
          
          
        }
      }else{
        //App不更新, 检查rn是否需要更新
        if (!klObjectisEmpty([self.RnUpdateInfo valueForKey:@"version"]) ) {
          //需要更新
          if (!klObjectisEmpty([self.RnUpdateInfo valueForKey:@"incrementVersion"])) {
            if ([[self.RnUpdateInfo valueForKey:@"incrementVersion"] isEqualToString:@"all"]) {
              //后台更新全量包
              [self getBackFullPackageDownurl:[self.RnUpdateInfo valueForKey:@"versionUrl"] packageName:[self.RnUpdateInfo valueForKey:@"version"]];
         
            }else{
              //后台更新增量包
              [self getBackpatchPackageWithBaseversion:[self.RnUpdateInfo valueForKey:@"incrementVersion"] shouldUpdatedVersion:[self.RnUpdateInfo valueForKey:@"version"] url:[self.RnUpdateInfo valueForKey:@"versionUrl"]];
            }
          }
        }else{
          //不需要更新
          
        }
        
        
        
      }
      
      
      
      
      
    }else{
      //网络请求状态码异常
      
    }
  } failure:^(NSError * _Nonnull error) {
    //网络请求失败
    JKLog(@"%@",error);
  }];

  https://ab592362-2624-4856-b5f0-ebeb70c291c0.mock.pstmn.io/test

//  //接口请求，判断bundle文件是否存在，两种情况，（后台下载，立即展现）1 补丁包 2 全包
//  if (Isbackgrounddown) {
//    if (IspatchPakpage) {
//      //后台下载补丁包
//      [self getBackpatchPackage];
//    }else{
//      //后台下载全量包
//      [self getBackFullPackage];
//
//    }
//    NSString *bundle = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"bundle.zip"];
//    BOOL bundlejsExist = [[NSFileManager defaultManager] fileExistsAtPath:bundle];
//    if (bundlejsExist) {
//
//
//      rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
//                                             moduleName:@"kuaichecaifuRn"
//                                      initialProperties:nil
//                                          launchOptions:launchOptions];
//    }else{
//
//  //jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
//    jsCodeLocation =  [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
//      rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
//                                             moduleName:@"kuaichecaifuRn"
//                                      initialProperties:nil
//                                          launchOptions:launchOptions];
//    }
//
//    rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];
//    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    UIViewController *rootViewController = [UIViewController new];
//    rootViewController.view = rootView;
//    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:rootViewController];
//    nav.navigationBarHidden=YES;
//    self.window.rootViewController = nav;
//    [self.window makeKeyAndVisible];
//
//
//  }else{
//    if (IspatchPakpage) {
//      //前台下载补丁包
//      [self getFrontpatchPackage];
//
//    }else{
//      //前台下载全量包
//      _bridge = [[RCTBridge alloc] initWithBundleURL:jsCodeLocation
//                                      moduleProvider:nil
//                                       launchOptions:launchOptions];
//
//      RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:_bridge moduleName:@"kuaichecaifuRn" initialProperties:nil];
//      rootView.backgroundColor = [UIColor yellowColor];
//      self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//      UIViewController *rootViewController = [UIViewController new];
//      rootViewController.view = rootView;
//      UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:rootViewController];
//      nav.navigationBarHidden=YES;
//      self.window.rootViewController = nav;
//      [self.window makeKeyAndVisible];
//
//      [self getFrontFullPackageSuccess:^(NSString *success) {
//
//
//
//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"监测到更细" preferredStyle:UIAlertControllerStyleAlert];
//
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
//        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//          int64_t delayInSeconds = 1.0;      // 延迟的时间
//          /*
//           *@parameter 1,时间参照，从此刻开始计时
//           *@parameter 2,延时多久，此处为秒级，还有纳秒等。10ull * NSEC_PER_MSEC
//           */
//          dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//          dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            // do something
//            JKLog(@"success ====%@",success);
//            if ([success isEqualToString:@"success"]) {
//              _bridge = [[RCTBridge alloc] initWithBundleURL:jsCodeLocation
//                                              moduleProvider:nil
//                                               launchOptions:launchOptions];
//
//              RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:_bridge moduleName:@"kuaichecaifuRn" initialProperties:nil];
//              rootView.backgroundColor = [UIColor yellowColor];
//              self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//              UIViewController *rootViewController = [UIViewController new];
//              rootViewController.view = rootView;
//              UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:rootViewController];
//              nav.navigationBarHidden=YES;
//              self.window.rootViewController = nav;
//              [self.window makeKeyAndVisible];
//            }
//
//          });
//
//        }];
//
//        [alertController addAction:cancelAction];
//         [alertController addAction:sureAction];
//
//        //显示弹出框
//
//        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
//
//
//
//
//
//      }];
//    //  jsCodeLocation =  [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
//
//    }
//  }
//
#endif
  
  [Bugly startWithAppId:@"20ed872403"];

  

#pragma mark 监听
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SendOpenUrlData) name:@"sendUrldata" object:nil];
  
  return YES;
}
#pragma mark 合并增量后jsbundle文件出现部分错误调试发现当加载jsbundle出现异常时
- (BOOL)backToPreVersion
{
  // rollback
  JKLog(@"这个js版本有问题");
  
  return YES;
}

#pragma mark 弹窗展现
-(void)presentAlertWithtitle:(NSString *)title message:(NSString *)message leftbutton:(NSString *)leftbutton rightbutton:(NSString *)rightbutton leftAct:(void(^)())leftAction rightAct:(void(^)())rightAct{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:leftbutton style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    leftAction();
  }];
  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:rightbutton style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
      
    rightAct();
  }];
  
  [alertController addAction:cancelAction];
  [alertController addAction:sureAction];
  
  //显示弹出框
  
  [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
  
  
}


#pragma mark 检查更新
-(void)checkupdateSuccess:(nonnull void (^)(id _Nullable responseobject))success failure:(nonnull void (^)(NSError * _Nonnull error))failure{
  JKLog(@"%@",self.jslistStr);
  [CommenHttpAPI klUpgradeParemeters:nil version:AppCFversion channel:@"" os:@"1" jsVersionList:self.jslistStr progress:^(NSProgress * _Nonnull progress) {
    
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseobject) {
    
    success(responseobject);
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    JKLog(@"%@",error);
    failure(error);
  }];
 
}

#pragma mark 第一次打开拷贝bundle资源
-(NSURL *)getBundlePath{
  
    NSString *jsversionCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
  //判断assets是否存在
  BOOL jsversionExist = [[NSFileManager defaultManager] fileExistsAtPath:jsversionCachePath];
  //如果已存在
  if(jsversionExist){
    NSLog(@"jsversion已存在: %@",jsversionCachePath);
    //如果不存在
  }else{
    NSString *jsversionBundlePath = [[NSBundle mainBundle] pathForResource:@"jsversion" ofType:nil];
    [[NSFileManager defaultManager] copyItemAtPath:jsversionBundlePath toPath:jsversionCachePath error:nil];
    NSLog(@"jsversion已拷贝至Document: %@",jsversionCachePath);
    
    
  }
  
  
  
  
  //#ifdef  DEBUG
  //  NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];
  //  return jsCodeLocation;
  //#else
  //需要存放和读取的document路径
  //jsbundle地址
  NSString *jsCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"main.jsbundle"];
  //assets文件夹地址
  NSString *assetsCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"assets"];
  JKLog(@"%@========%@", jsCachePath,assetsCachePath);
  //判断JSBundle是否存在
  BOOL jsExist = [[NSFileManager defaultManager] fileExistsAtPath:jsCachePath];
  //如果已存在
  if(jsExist){
    NSLog(@"js已存在: %@",jsCachePath);
    //如果不存在
  }else{
    NSString *jsBundlePath = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"jsbundle"];
    [[NSFileManager defaultManager] copyItemAtPath:jsBundlePath toPath:jsCachePath error:nil];
    NSLog(@"js已拷贝至Document: %@",jsCachePath);
  }
  
  //判断assets是否存在
  BOOL assetsExist = [[NSFileManager defaultManager] fileExistsAtPath:assetsCachePath];
  //如果已存在
  if(assetsExist){
    NSLog(@"assets已存在: %@",assetsCachePath);
    //如果不存在
  }else{
    NSString *assetsBundlePath = [[NSBundle mainBundle] pathForResource:@"assets" ofType:nil];
    [[NSFileManager defaultManager] copyItemAtPath:assetsBundlePath toPath:assetsCachePath error:nil];
    NSLog(@"assets已拷贝至Document: %@",assetsCachePath);
  }
  return [NSURL URLWithString:jsCachePath];
  //#endif
}
#pragma mark 获取本地js列表
-(void)getJslist
{
  //jsversion文件夹地址
  NSString *jsversionCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
  NSFileManager *manager =[NSFileManager defaultManager];
  BOOL jsversionExist = [manager fileExistsAtPath:jsversionCachePath];
  if (jsversionExist) {
    //js文件存在
    self.jslistArr =[manager contentsOfDirectoryAtPath:jsversionCachePath error:nil];
    JKLog(@"%@",self.jslistArr);
    NSString *str = @"";
    self.jslistStr = @"";
    for (int i = 0; i < self.jslistArr.count; i++) {
      if (i == 0) {
        str = [self.jslistArr objectAtIndex:0];
      }else{
        str= [NSString stringWithFormat:@",%@",[self.jslistArr objectAtIndex:i]];
      }
      self.jslistStr = [NSString stringWithFormat:@"%@%@",self.jslistStr,str];
      JKLog(@"%@",self.jslistStr);
    }
    
  }else{
    
    
  }
}

#pragma mark 后台下载补丁包
-(void)getBackpatchPackageWithBaseversion:(NSString *)baseVersion shouldUpdatedVersion:(NSString *)shouldUpdatedVersion url:(NSString *)downUrl
{
  //先找到baseVersion版本
 
  [self findBaseWithCopyWithbaseVersion:baseVersion];
  
  JKLog(@"%@",baseVersion);
  JKLog(@"%@",shouldUpdatedVersion);
  JKLog(@"%@",downUrl);
  
  JKLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++后台下载补丁包+++++++++++++++++++++++++++++++++++++++++++++");
    NSString *patchCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"patch"];
   NSString *filePath = [NSString stringWithFormat:@"%@/\%@",patchCachePath,[NSString stringWithFormat:@"%@",shouldUpdatedVersion]];
    [[NSFileManager defaultManager] createDirectoryAtPath:patchCachePath withIntermediateDirectories:YES attributes:nil error:nil];
  
      [[JkFileHelper shared] downloadFileWithURLString:downUrl zipName:shouldUpdatedVersion CacheLocal:@"patch" finish:^(NSInteger status, id data) {
        if(status == 1){
          NSLog(@"下载完成");
  
        NSString *zipPath =(NSString *)data;
         
          NSError *error;
          // 解压
  
       
          [SSZipArchive unzipFileAtPath:zipPath toDestination:filePath overwrite:YES password:nil error:&error];
          if(!error){
            NSLog(@"解压成功");
            [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
          
            [self combinepatchpackage:filePath baseVersion:baseVersion shouldUpdatedVersion:shouldUpdatedVersion];

          }else{
            NSLog(@"解压失败");
            JKLog(@"%@",error);
          }
          JKLog(@"%@",NSHomeDirectory());
        }else{
          JKLog(@"%d",status);
        }
      }];
   JKLog(@"++++++++++++++++++++++++++++++++++++++++++++++++++后台下载全量包结束+++++++++++++++++++++++++++++++++++++++++++++");
  
}
#pragma mark 后台下载补丁包 先找到baseVersion版本 拷贝到沙盒
-(void)findBaseWithCopyWithbaseVersion:(NSString *)baseVersion
{
  //jsversion文件夹地址
  NSString *jsversionCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
   NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSFileManager *manager =[NSFileManager defaultManager];
  NSString *filePath = [NSString stringWithFormat:@"%@/\%@",jsversionCachePath,[NSString stringWithFormat:@"%@",baseVersion]];
  BOOL jsversionExist = [manager fileExistsAtPath:jsversionCachePath];
  BOOL IsBaseversion=NO;
  if (jsversionExist) {
    //js文件存在
    self.jslistArr =[manager contentsOfDirectoryAtPath:jsversionCachePath error:nil];
   
    for (int i = 0; i < self.jslistArr.count; i++) {
      if ([baseVersion isEqualToString:[self.jslistArr objectAtIndex:i]]) {
        IsBaseversion = YES;
      }else{
        IsBaseversion = NO;
      }
     
    }
    if (IsBaseversion) {
      NSString *jsversionCachePath1 = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],baseVersion];
      //判断assets是否存在
      BOOL jsversionExist = [[NSFileManager defaultManager] fileExistsAtPath:jsversionCachePath1];
      //如果已存在
      if(jsversionExist){
        NSLog(@"jsversion已存在: %@",jsversionCachePath);
        //如果不存在
      }else{
        NSString *jsversionCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
            NSString *filePath = [NSString stringWithFormat:@"%@/\%@",jsversionCachePath,[NSString stringWithFormat:@"%@",baseVersion]];
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:jsversionCachePath1 error:nil];
        NSLog(@"file已拷贝至Document: %@",jsversionCachePath1);
      }
      
      
      [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:doc error:nil];
    }
    
    
  }else{
    
    
  }
}
#pragma mark后台合并patch包
-(void)combinepatchpackage:(NSString *)directryPath baseVersion:(NSString *)baseVersion shouldUpdatedVersion:(NSString *)shouldUpdatedVersion{
  
  JKLog(@"%@",directryPath);
  JKLog(@"%@",baseVersion);
  JKLog(@"%@",shouldUpdatedVersion);
  
  
  NSString *patchCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"patch"];
  NSString *filePath = [NSString stringWithFormat:@"%@/\%@",patchCachePath,[NSString stringWithFormat:@"%@",shouldUpdatedVersion]];
  NSString *jsversionCachePath1 = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],baseVersion];
  
  NSString *txtPath = [jsversionCachePath1 stringByAppendingPathComponent:@"main.jsbundle"];
  NSString *assetPath = [jsversionCachePath1 stringByAppendingPathComponent:@"assets"];
  // 此时仅存在路径，文件并没有真实存在
  
  NSString *text1 = [NSString stringWithContentsOfFile:txtPath encoding:NSUTF8StringEncoding error:nil];
  
  
   DiffMatchPatch *dmp = [DiffMatchPatch new];
  //输出差异文件地址
  NSString *patchPath = [filePath stringByAppendingPathComponent:@"patch.txt"];
  
// 读取差异文件
  NSString *resultStr = [NSString stringWithContentsOfFile:patchPath encoding:NSUTF8StringEncoding error:nil];
  // 读取差异文件
  NSMutableArray *patchDataArr =[dmp patch_fromText:resultStr error:nil];
  
  JKLog(@"%@===========%@",patchDataArr,resultStr);
  JKLog(@"%@",text1);
  //图片资源
  // 差异文件和原始文件合并生成新的文件
    NSArray *ResultData= [dmp patch_apply:patchDataArr toString:text1];
  NSString *txtPath3 = [filePath stringByAppendingPathComponent:@"main.jsbundle"]; // 此时仅存在路径，文件并没有真实存在
  for (int i =0; i < ResultData.count; i ++) {
        if (i ==0) {
          //bundle文件已经合成 ，下一步
          [ResultData[i] writeToFile:txtPath3 atomically:YES encoding:NSUTF8StringEncoding error:nil];
          //[self createJSlistIndoc:txtPath3 baseVersion:baseVersion shouldUpdatedVersion:shouldUpdatedVersion assets:assetPath];
          
          
        }
        JKLog(@"%@/n", ResultData[i]);
      }
  

}
#pragma mark 在沙盒生成将要移动的全部文件
-(void)createJSlistIndoc:(NSString*)bundlepath baseVersion:(NSString *)baseVersion shouldUpdatedVersion:(NSString *)shouldUpdatedVersion assets:(NSString *)assetpath
{
   NSString *patchCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],shouldUpdatedVersion];
  NSString *txtPath3 = [patchCachePath stringByAppendingPathComponent:@"main.jsbundle"];
  NSString *txtPath2 = [patchCachePath stringByAppendingPathComponent:@"assets"];
  
  NSString *jslist = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];
  NSString *jsversion = [NSString stringWithFormat:@"%@/\%@",jslist,[NSString stringWithFormat:@"%@",shouldUpdatedVersion]];;
  
  //判断assets是否存在
  BOOL jsversionExist = [[NSFileManager defaultManager] fileExistsAtPath:patchCachePath];
  //如果已存在,删除
  if(jsversionExist){
    NSLog(@"jsversion已存在: %@",patchCachePath);
       [[NSFileManager defaultManager] removeItemAtPath:patchCachePath error:nil];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:patchCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    NSLog(@"jsversion已生成Document: %@",patchCachePath);
    //将合并后的js文件和图片移动到该目录下
    
    [[NSFileManager defaultManager] copyItemAtPath:bundlepath toPath:txtPath3 error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:assetpath toPath:txtPath2 error:nil];
    
   
  }else{
     [[NSFileManager defaultManager] createDirectoryAtPath:patchCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    NSLog(@"jsversion已生成Document: %@",patchCachePath);
    //将合并后的js文件和图片移动到该目录下
    
     [[NSFileManager defaultManager] copyItemAtPath:bundlepath toPath:txtPath3 error:nil];
      [[NSFileManager defaultManager] copyItemAtPath:assetpath toPath:txtPath2 error:nil];
    
  }
  //移动文件夹到jslist
   NSString *patch = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"patch"];
   [[NSFileManager defaultManager] moveItemAtPath:patchCachePath toPath:jsversion error:nil];
   [[NSFileManager defaultManager] removeItemAtPath:patch error:nil];
  
  
  
 
  
 
  
}

#pragma mark后台下载全量包
-(void)getBackFullPackageDownurl:(NSString *)url packageName:(NSString *)packageName{
  
  NSString *docsDir = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"jsversion"];

  NSString *filePath = [NSString stringWithFormat:@"%@/\%@",docsDir,[NSString stringWithFormat:@"%@",packageName]];
//  //判断assets是否存在
//  BOOL jsversionExist = [[NSFileManager defaultManager] fileExistsAtPath:jsversionCachePath];
//  //如果已存在
//  if(jsversionExist){
//    NSLog(@"jsversion已存在: %@",jsversionCachePath);
//    //如果不存在
//  }else{
//    NSString *jsversionBundlePath = [[NSBundle mainBundle] pathForResource:@"jsversion" ofType:nil];
//    [[NSFileManager defaultManager] copyItemAtPath:jsversionBundlePath toPath:jsversionCachePath error:nil];
//    NSLog(@"jsversion已拷贝至Document: %@",jsversionCachePath);
//  }
//
//
//
//  NSString *bundle = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"bundle.zip"];
//  NSString *dbundleesPath = [NSString stringWithFormat:@"%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
  [[JkFileHelper shared] downloadFileWithURLString:url zipName:packageName CacheLocal:@"jsversion" finish:^(NSInteger status, id data) {
    if(status == 1){
      NSLog(@"下载完成");
      
     
      NSString *zipPath =(NSString *)data;
      [zipPath getFileMD5WithPath:zipPath];
      JKLog(@"%@",zipPath);
      JKLog(@"%@", [zipPath getFileMD5WithPath:zipPath]);
      //校验文件完整性
//      [[NSFileManager defaultManager] copyItemAtPath:zipPath toPath:jsversionCachePath error:nil];
//      NSLog(@"bundle已拷贝至Document: %@",jsversionCachePath);
      NSError *error;
      // 解压
      
    
      JKLog(@"%@ ======== %@", zipPath, docsDir);
      
      [SSZipArchive unzipFileAtPath:zipPath toDestination:filePath overwrite:YES password:nil error:&error];
      if(!error){
        NSLog(@"解压成功");
        [[NSFileManager defaultManager] removeItemAtPath:zipPath error:nil];
      }else{
        NSLog(@"解压失败");
        JKLog(@"%@",error);
        
        
        
        
        
      }
      JKLog(@"%@",NSHomeDirectory());
    }
  }];
}

#pragma mark前台下载补丁包
-(void)getFrontpatchPackage
{
  
}
#pragma mark前台下载全量包
-(void)getFrontFullPackageSuccess:(void (^)(NSString *success))success
{
  [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
  [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"检测有更新正在更新"]];
  NSString *bundle = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"bundle.zip"];
  NSString *dbundleesPath = [NSString stringWithFormat:@"%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]];
  [[JkFileHelper shared] downloadFileWithURLString:@"http://192.168.1.202:28080/rn-ios/bundle.zip" zipName:@"123456" CacheLocal:@"jsversion"  finish:^(NSInteger status, id data) {
    if(status == 1){
      NSLog(@"下载完成");
      
      NSString *zipPath =(NSString *)data;
      [[NSFileManager defaultManager] copyItemAtPath:zipPath toPath:bundle error:nil];
      NSLog(@"bundle已拷贝至Document: %@",bundle);
      NSError *error;
      // 解压
      
      NSString *destinationPath = dbundleesPath;
      
      
      [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath overwrite:YES password:nil error:&error];
      if(!error){
        NSLog(@"解压成功");
        success(@"success");
        [SVProgressHUD dismiss];
        
      }else{
        success(@"failure");
        NSLog(@"解压失败");
      }
      JKLog(@"%@",NSHomeDirectory());
    }
  }];
}



#pragma mark 像js传递列表
-(void)SendOpenUrlData{
 // [[RNCalliOSAction shareManager] senddata];
  EventEmitterManager *manager = [EventEmitterManager allocWithZone:nil];
  [manager sendNoticeWithEventName:@"HttpResult" Dict:@{@"code":@"6"}];
}
#pragma mark 友盟相关组件
-(void)setUMCompoent:(NSDictionary *)launchOptions
{
  //友盟
  // 配置友盟SDK产品并并统一初始化
  // [UMConfigure setEncryptEnabled:YES]; // optional: 设置加密传输, 默认NO.
   [UMConfigure setLogEnabled:YES]; // 开发调试时可在console查看友盟日志显示，发布产品必须移除。
  [UMConfigure initWithAppkey:@"5a31d36f8f4a9d60530001d9" channel:@"App Store"];
  /* appkey: 开发者在友盟后台申请的应用获得（可在统计后台的 “统计分析->设置->应用信息” 页面查看）*/
  
  /* Share init */
  [self setupUSharePlatforms];   // required: setting platforms on demand
  [self setupUShareSettings];
  
  
  // 统计组件配置
  [MobClick setScenarioType:E_UM_NORMAL];
  // [MobClick setScenarioType:E_UM_GAME];  // optional: 游戏场景设置
  
  // Push's basic setting
  UMessageRegisterEntity * entity = [[UMessageRegisterEntity alloc] init];
  //type是对推送的几个参数的选择，可以选择一个或者多个。默认是三个全部打开，即：声音，弹窗，角标
  entity.types = UMessageAuthorizationOptionBadge|UMessageAuthorizationOptionAlert;
  [UNUserNotificationCenter currentNotificationCenter].delegate=self;
  
  [UMessage registerForRemoteNotificationsWithLaunchOptions:launchOptions Entity:entity completionHandler:^(BOOL granted, NSError * _Nullable error) {
    if (granted) {
    } else {
    }
  }];
  
  
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  //1.2.7版本开始不需要用户再手动注册devicetoken，SDK会自动注册
  [UMessage registerDeviceToken:deviceToken];
  NSString *umtoken = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""]
                        stringByReplacingOccurrencesOfString: @">" withString: @""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
  JKLog(@"umtoken %@", umtoken);
  if (!klObjectisEmpty(umtoken)) {
    [[NSUserDefaults standardUserDefaults] setObject:umtoken forKey:@"UMtoken"];
  }
  //
  
  //下面这句代码只是在demo中，供页面传值使用。
  
}

- (void)setupUShareSettings
{
  /*
   * 打开图片水印
   */
  //[UMSocialGlobal shareInstance].isUsingWaterMark = YES;
  
  /*
   * 关闭强制验证https，可允许http图片分享，但需要在info.plist设置安全域名
   <key>NSAppTransportSecurity</key>
   <dict>
   <key>NSAllowsArbitraryLoads</key>
   <true/>
   </dict>
   */
  [UMSocialGlobal shareInstance].isUsingHttpsWhenShareContent = NO;
  
}

- (void)setupUSharePlatforms
{
  /*
   设置微信的appKey和appSecret
   [微信平台从U-Share 4/5升级说明]http://dev.umeng.com/social/ios/%E8%BF%9B%E9%98%B6%E6%96%87%E6%A1%A3#1_1
   */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:@"wxdc1e388c3822c80b" appSecret:@"3baf1193c85774b3fd9d18447d76cab0" redirectURL:nil];
  /*
   * 移除相应平台的分享，如微信收藏
   */
  //[[UMSocialManager defaultManager] removePlatformProviderWithPlatformTypes:@[@(UMSocialPlatformType_WechatFavorite)]];
  
  /* 设置分享到QQ互联的appID
   * U-Share SDK为了兼容大部分平台命名，统一用appKey和appSecret进行参数设置，而QQ平台仅需将appID作为U-Share的appKey参数传进即可。
   100424468.no permission of union id
   [QQ/QZone平台集成说明]http://dev.umeng.com/social/ios/%E8%BF%9B%E9%98%B6%E6%96%87%E6%A1%A3#1_3
   */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ appKey:@"1105821097"/*设置QQ平台的appID*/  appSecret:nil redirectURL:nil];
  
  /*
   设置新浪的appKey和appSecret
   [新浪微博集成说明]http://dev.umeng.com/social/ios/%E8%BF%9B%E9%98%B6%E6%96%87%E6%A1%A3#1_2
   */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:@"3921700954"  appSecret:@"04b48b094faeb16683c32669824ebdad" redirectURL:@"https://sns.whalecloud.com/sina2/callback"];
  
  /* 设置Twitter的appKey和appSecret */
//  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Twitter appKey:@"fB5tvRpna1CKK97xZUslbxiet"  appSecret:@"YcbSvseLIwZ4hZg9YmgJPP5uWzd4zr6BpBKGZhf07zzh3oj62K" redirectURL:nil];
  
  /* 设置Facebook的appKey和UrlString */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Facebook appKey:@"506027402887373"  appSecret:nil redirectURL:@"http://www.umeng.com/social"];
}

#pragma mark - Share And url navigation
//#define __IPHONE_10_0    100000
#if __IPHONE_OS_VERSION_MAX_ALLOWED > 100000
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
  //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响。
  BOOL result = [[UMSocialManager defaultManager]  handleOpenURL:url options:options];
  if (!result) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sendUrldata" object:nil];
    // 其他如支付等SDK的回调
  }
  return result;
}
#endif


-(BOOL)application:(UIApplication *)app openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation
{
  return [RCTLinkingManager application:app openURL:url
                      sourceApplication:sourceApplication annotation:annotation];
}
#pragma mark - Push
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
  //关闭友盟自带的弹出框
  [UMessage setAutoAlert:NO];
  [UMessage didReceiveRemoteNotification:userInfo];
  
  //    self.userInfo = userInfo;
  //    //定制自定的的弹出框
  //    if([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
  //    {
  //        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"标题"
  //                                                            message:@"Test On ApplicationStateActive"
  //                                                           delegate:self
  //                                                  cancelButtonTitle:@"确定"
  //                                                  otherButtonTitles:nil];
  //
  //        [alertView show];
  //
  //    }
}

//iOS10新增：处理前台收到通知的代理方法
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
  NSDictionary * userInfo = notification.request.content.userInfo;
  if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    
    //应用处于前台时的远程推送接受
    //关闭友盟自带的弹出框
    [UMessage setAutoAlert:NO];
    //必须加这句代码
    [UMessage didReceiveRemoteNotification:userInfo];
    
  }else{
    //应用处于前台时的本地推送接受
  }
  completionHandler(UNNotificationPresentationOptionSound|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionAlert);
}

//iOS10新增：处理后台点击通知的代理方法
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler{
  NSDictionary * userInfo = response.notification.request.content.userInfo;
  if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
    
    //应用处于后台时的远程推送接受
    //必须加这句代码
    [UMessage didReceiveRemoteNotification:userInfo];
    
  }else{
    //应用处于后台时的本地推送接受
  }
}
#pragma mark 广告页
- (void)setUpAd_show
{
  [XHLaunchAd setWaitDataDuration:3];//请求广告数据前,必须设置
  [CommenHttpAPI klgetguidepageParemeters:nil os:@"1" prod:@"1" res:@"2" progress:^(NSProgress * _Nonnull progress) {
    
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseobject) {
    JKLog(@"%@", responseobject);
    
    if ([[NSString stringWithFormat:@"%@",[responseobject valueForKey:@"code"]] isEqualToString:@"0"]) {
      NSDictionary *urlDic = [responseobject valueForKey:@"data"];
      _actionUrl = [urlDic valueForKey:@"actionUrl"];
      //配置广告数据
      XHLaunchImageAdConfiguration *imageAdconfiguration = [XHLaunchImageAdConfiguration new];
      //广告停留时间
      imageAdconfiguration.duration = 5;
      //广告frame
      imageAdconfiguration.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, self.window.bounds.size.height*0.82);
      //广告图片URLString/或本地图片名(.jpg/.gif请带上后缀)
      imageAdconfiguration.imageNameOrURLString = [urlDic valueForKey:@"imgUrl"];
      //缓存机制(仅对网络图片有效)
      imageAdconfiguration.imageOption = XHLaunchAdImageDefault;
      //图片填充模式
      imageAdconfiguration.contentMode = UIViewContentModeScaleToFill;
      //广告点击打开链接
      imageAdconfiguration.openURLString = _actionUrl;
      //广告显示完成动画
      imageAdconfiguration.showFinishAnimate =ShowFinishAnimateFadein;
      //跳过按钮类型
      imageAdconfiguration.skipButtonType = SkipTypeTimeText;
      //后台返回时,是否显示广告
      imageAdconfiguration.showEnterForeground = NO;
      //显示开屏广告
      [XHLaunchAd imageAdWithImageAdConfiguration:imageAdconfiguration delegate:self];
      
      
    }
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    JKLog(@"%@", error);
    
  }];
}



@end
