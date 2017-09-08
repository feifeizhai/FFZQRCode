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
    self.label.font = [UIFont fontWithName:@"iconfont" size:44];
    self.label.text = @"\U0000e601";
    self.label.textColor = [UIColor redColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(scan) forControlEvents:UIControlEventTouchUpInside];
    
  
}

- (IBAction)scan:(id)sender {
    
    FFZQRCodeViewController *scanVC = [[FFZQRCodeViewController alloc] initWithFFZQRCodeScanResultBlock:^(NSString *result) {
      
        
    }];
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
