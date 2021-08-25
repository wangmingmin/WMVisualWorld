//
//  WMBluetoothCentral.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/25.
//

#import "WMBluetoothCentral.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define wmCBUUID @"E621E1F8-C36C-495A-93FC-0C247A3E6E5E"
@interface WMBluetoothCentral ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@end

@implementation WMBluetoothCentral
//1、初始化
-(instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_queue_t centralQueue = dispatch_queue_create("wmcentralQueue",DISPATCH_QUEUE_SERIAL);
        //CBCentralManagerOptionShowPowerAlertKey对应的BOOL值，当设为YES时，表示CentralManager初始化时，如果蓝牙没有打开，将弹出Alert提示框
        //CBCentralManagerOptionRestoreIdentifierKey对应的是一个唯一标识的字符串，用于蓝牙进程被杀掉恢复连接时用的。
        NSDictionary *dic = @{CBCentralManagerOptionShowPowerAlertKey : @(YES), CBCentralManagerOptionRestoreIdentifierKey : @"wangmm unique identifier"};
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:centralQueue options:dic];
        
    }
    return self;
}

/**
 *2、搜索扫描外围设备
 *  --  初始化成功自动调用
 *  --  必须实现的代理，用来返回创建的centralManager的状态。
 *  --  注意：必须确认当前是CBManagerStatePoweredOn状态才可以调用扫描外设的方法：
 scanForPeripheralsWithServices
 */
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
          case CBManagerStateUnknown:
              NSLog(@">>>CBManagerStateUnknown");//未知状态
              break;
          case CBManagerStateResetting:
              NSLog(@">>>CBManagerStateResetting");//重启状态
              break;
          case CBManagerStateUnsupported:
              NSLog(@">>>CBManagerStateUnsupported");//不支持
              break;
          case CBManagerStateUnauthorized:
              NSLog(@">>>CBManagerStateUnauthorized");//未授权
              break;
          case CBManagerStatePoweredOff:
              NSLog(@">>>CBManagerStatePoweredOff");//蓝牙未开启
              break;
          case CBManagerStatePoweredOn://蓝牙开启
          {
              NSLog(@">>>CBManagerStatePoweredOn");
              // 开始扫描周围的外设。
              /*
               -- 两个参数为Nil表示默认扫描所有可见蓝牙设备。
               -- 注意：第一个参数是用来扫描有指定服务的外设。然后有些外设的服务是相同的，比如都有FFF5服务，那么都会发现；而有些外设的服务是不可见的，就会扫描不到设备。
               -- 成功扫描到外设后调用didDiscoverPeripheral
               */
              //不重复扫描已发现设备
              NSDictionary *option = @{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:NO],CBCentralManagerOptionShowPowerAlertKey:@(YES)};
              //扫面方法，serviceUUIDs用于第一步的筛选，扫描此UUID的设备
              //options有两个常用参数：CBCentralManagerScanOptionAllowDuplicatesKey设置为NO表示不重复扫瞄已发现设备，为YES就是允许。CBCentralManagerOptionShowPowerAlertKey设置为YES就是在蓝牙未打开的时候显示弹框
              [self.centralManager scanForPeripheralsWithServices:nil options:option];
          }
              break;
          default:
              break;
      }
}


#pragma mark - 发现外设
//peripheral是外设类
//advertisementData是广播的值，一般携带设备名，serviceUUIDs等信息
//RSSI绝对值越大，表示信号越差，设备离的越远。如果想装换成百分比强度，（RSSI+100）/100，（这是一个约数，蓝牙信号值并不一定是-100 - 0的值，但近似可以如此表示）
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"Find device:%@", [peripheral name]);
    //连接外围设备
    if (!self.peripheral) {
        if([peripheral.identifier.UUIDString isEqualToString:wmCBUUID]){//如果搜索到有蓝牙设备名字为wangmm开头默认连接设备
            [self connectDeviceWithPeripheral:peripheral];
        }
        if([peripheral.name hasPrefix:@"wangmm"]){//如果搜索到有蓝牙设备名字为wangmm开头默认连接设备
            [self connectDeviceWithPeripheral:peripheral];
        }
    }
}

//在蓝牙于后台被杀掉时，重连之后会首先调用此方法，可以获取蓝牙恢复时的各种状态
- (void)centralManager:(CBCentralManager *)central willRestoreState:(nonnull NSDictionary<NSString *,id> *)dict
{
    
}


#pragma mark -
// 连接设备(.h中声明出去的接口, 一般在点击设备列表连接时调用)
- (void)connectDeviceWithPeripheral:(CBPeripheral *)peripheral
{
    [self.centralManager connectPeripheral:peripheral options:nil];
}


#pragma mark 连接外设--成功
//连接的状态 对应另外的CBCentralManagerDelegate代理方法 连接成功的回调
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //连接成功后停止扫描，节省内存
    [central stopScan];
    peripheral.delegate = self;
    self.peripheral = peripheral;
    //4.扫描外设的服务
    /**
     --     外设的服务、特征、描述等方法是CBPeripheralDelegate的内容，所以要先设置代理peripheral.delegate = self
     --     参数表示你关心的服务的UUID，比如我关心的是"FFE0",参数就可以为@[[CBUUID UUIDWithString:@"FFE0"]].那么didDiscoverServices方法回调内容就只有这两个UUID的服务，不会有其他多余的内容，提高效率。nil表示扫描所有服务
     --     成功发现服务，回调didDiscoverServices
     */
    [peripheral discoverServices:@[[CBUUID UUIDWithString:wmCBUUID]]];
//    if ([self.delegate respondsToSelector:@selector(didConnectBle)]) {
//       // 已经连接
//        [self.delegate didConnectBle];
//    }
}

#pragma mark 连接外设——失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@", error);
}

#pragma mark 取消与外设的连接回调
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@", peripheral);
    //连接成功之后寻找服务，传nil会寻找所有服务
    [peripheral discoverServices:nil];
    [self.centralManager connectPeripheral:peripheral options:nil];
}


#pragma mark 发现服务回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    //NSLog(@"didDiscoverServices,Error:%@",error);
    CBService * __nullable findService = nil;
    // 遍历服务
    for (CBService *service in peripheral.services)
    {
        //NSLog(@"UUID:%@",service.UUID);
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:wmCBUUID]])
        {
            findService = service;
        }
    }
    NSLog(@"Find Service:%@",findService);
    if (findService) [peripheral discoverCharacteristics:NULL forService:findService];
}


#pragma mark 发现特征回调
/**
 --  发现特征后，可以根据特征的properties进行：读readValueForCharacteristic、写writeValue、订阅通知setNotifyValue、扫描特征的描述discoverDescriptorsForCharacteristic。
 **/
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:wmCBUUID]]) {
            
            /**
             -- 读取成功回调didUpdateValueForCharacteristic
             */
            // 接收一次(是读一次信息还是数据经常变实时接收视情况而定, 再决定使用哪个)
            //            [peripheral readValueForCharacteristic:characteristic];
            // 订阅, 实时接收
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            // 发送下行指令(发送一条)
            NSData *data = [@"我已经收到你的数据" dataUsingEncoding:NSUTF8StringEncoding];
            // 将指令写入蓝牙
            [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }

        /**
         -- 当发现characteristic有descriptor,回调didDiscoverDescriptorsForCharacteristic
         */
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
}


#pragma mark - 获取值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    // characteristic.value就是蓝牙给我们的值
    NSData *videoData = characteristic.value;
    
}

#pragma mark - 中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    } else {
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        NSLog(@"%@", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


#pragma mark 数据写入成功回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"写入成功");
}
@end
