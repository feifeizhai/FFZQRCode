//
//  ViewController.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/28.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "ViewController.h"
#import "FFZQRCodeViewController.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (strong, nonatomic) UIButton *scanBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

}

- (IBAction)scan:(id)sender {
    
    __weak ViewController *weakSelf = self;
    FFZQRCodeViewController *scanVC = [[FFZQRCodeViewController alloc] init];
    __weak FFZQRCodeViewController *weakScanVC = scanVC;
    scanVC.scanResult = ^(NSString *result) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:result preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakScanVC startRun];
            
        }];
        [alertVC addAction:okAction];
        [weakSelf presentViewController:alertVC animated:YES completion:nil];
    };
    
   
    [self.navigationController pushViewController:scanVC animated:YES];
}

+ (NSMutableArray*)fontLists
{
    //字体列表 测试ok
    NSMutableArray *fontArray = [NSMutableArray arrayWithCapacity:246];
    for (NSString * familyName in [UIFont familyNames]) {
        NSMutableDictionary *familyDic = [NSMutableDictionary dictionary];
        NSMutableArray *familyAry = [NSMutableArray array];
        [familyDic setObject:familyAry forKey:familyName];
        //NSLog(@"Font FamilyName = %@",familyName); //*输出字体族科名字
        for (NSString * fontName in [UIFont fontNamesForFamilyName:familyName]) {
            //NSLog(@"%@",fontName);
            [familyAry addObject:fontName];
            
        }
        [fontArray addObject:familyDic];
    }
    return fontArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
