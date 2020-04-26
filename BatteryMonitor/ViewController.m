//
//  ViewController.m
//  BatteryMonitor
//
//  Created by 程薇 on 2020/4/26.
//  Copyright © 2020 kyson. All rights reserved.
//

#import "ViewController.h"
#import "BMBatteryMonitor.h"

@interface ViewController ()

@property (nonatomic, strong) BMBatteryMonitor *batteryMonitor;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.batteryMonitor = [[BMBatteryMonitor alloc] init];
    
    [self printCurrentBatteryMonitor];
    
}

-(void) printCurrentBatteryMonitor {
    NSDictionary * level = [self.batteryMonitor hnt_response];
    NSLog(@"battery duration :%@",level[@"battery_duration"]);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self batteryMonitor];
    });
}

@end
