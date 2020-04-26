//
//  BMBatteryMonitor.m
//  LPDHunterKit
//
//  Created by kyson on 2019/8/20.
//

#import "BMBatteryMonitor.h"
#include <dlfcn.h>
#import <objc/runtime.h>

#import <UIKit/UIKit.h>

@interface BMBatteryMonitorItem : NSObject

@property (nonatomic,strong) NSString *batteryStatus;
@property (nonatomic,assign) NSTimeInterval timeInterval;
@property (nonatomic,assign) NSInteger level;

@end

@implementation BMBatteryMonitorItem

@end

@interface BMBatteryMonitor()


@property (nonatomic,strong) BMBatteryMonitorItem *lastTimeHunter;
@property (nonatomic,strong) BMBatteryMonitorItem *currentHunter;
@property (nonatomic,assign) double batteryDuration;

@end

@implementation BMBatteryMonitor

#pragma mark - 电池检测

-(int)hnt_frequency {
    return 40;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self hnt_hunter];
    }
    return self;
}


-(void)hnt_hunter {
    //记录当前的情况
    BMBatteryMonitorItem *lastItem = [[BMBatteryMonitorItem alloc] init];
    lastItem.level = [self dogger_batteryQuantity] * 100;
    lastItem.timeInterval = [NSDate.date timeIntervalSince1970];
    lastItem.batteryStatus = [self.class dogger_batteryState];
    self.lastTimeHunter = lastItem;

    UIDevice *device = [UIDevice currentDevice];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeBatteryLevel:) name:UIDeviceBatteryLevelDidChangeNotification object:device];
}

-(void)didChangeBatteryLevel:(NSNotification *)notification {
    //如果当前在充电状态，直接返回
    if ([self.currentHunter.batteryStatus isEqualToString:@"charging"]) {
        self.lastTimeHunter = nil;
        self.currentHunter = nil;
        return;
    }
    
    //存下来这次的hunter
    BMBatteryMonitorItem *currentItem = [[BMBatteryMonitorItem alloc] init];
    currentItem.level = [self dogger_batteryQuantity] * 100;
    currentItem.timeInterval = [NSDate.date timeIntervalSince1970];
    currentItem.batteryStatus = [self.class dogger_batteryState];
    self.currentHunter = currentItem;

    BOOL shouldNotSet = NO;
    //上次计算的比这次的大（有种情况，比如 上次计算后，骑手上了充电宝，这次计算，又没有充电宝）
    if (self.lastTimeHunter.level - self.currentHunter.level >= 1) {
        //上次和这次的电池状态一样
        if ([self.lastTimeHunter.batteryStatus isEqualToString:self.currentHunter.batteryStatus] ) {
            //都不是充电中
            if (NO == [self.lastTimeHunter.batteryStatus isEqualToString:@"charging"]) {
                //记下来
                self.batteryDuration = ( self.currentHunter.timeInterval - self.lastTimeHunter.timeInterval ) / (self.lastTimeHunter.level - self.currentHunter.level);
                //重新设置
                BMBatteryMonitorItem *lastItem = [[BMBatteryMonitorItem alloc] init];
                lastItem.level = [self dogger_batteryQuantity] * 100;
                lastItem.timeInterval = [NSDate.date timeIntervalSince1970];
                lastItem.batteryStatus = [self.class dogger_batteryState];
                self.lastTimeHunter = lastItem;
            } else {
                shouldNotSet = YES;
            }
        } else {
            shouldNotSet = YES;
        }
    } else {
        shouldNotSet = YES;
    }

    if (YES == shouldNotSet) {
        self.lastTimeHunter = self.currentHunter;
        self.currentHunter = nil;
        self.batteryDuration = 0;
    }
}

-(NSDictionary *)hnt_response {
    NSString *duration = [NSString stringWithFormat:@"%f",self.batteryDuration];
    NSDictionary *resultDict = @{@"battery_duration":duration};
    NSDictionary *response = @{@"hunter":resultDict};
    //用完了，就置为 0
    self.batteryDuration = 0;
    return response;
}

- (float)dogger_batteryQuantity {
    if (![UIDevice currentDevice].isBatteryMonitoringEnabled) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    return batteryLevel;
}

- (NSInteger )dogger_batteryQuantityFromStatusBar {
    return [self dogger_batteryQuantity] * 100;
}

+ (NSString *)dogger_batteryState {
    if (![UIDevice currentDevice].isBatteryMonitoringEnabled) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
    
    NSString *batteryStateString = nil;
    
    switch ([UIDevice currentDevice].batteryState) {
        case UIDeviceBatteryStateUnknown:
        {
            batteryStateString = @"discharging";
        }
            break;
        case UIDeviceBatteryStateUnplugged:
        {
            batteryStateString = @"discharging";
        }
            break;
        case UIDeviceBatteryStateCharging:
        {
            batteryStateString = @"charging";
        }
            break;
        case UIDeviceBatteryStateFull:
        {
            batteryStateString = @"charging";
        }
            break;
    }
    
    return batteryStateString;
}



@end
