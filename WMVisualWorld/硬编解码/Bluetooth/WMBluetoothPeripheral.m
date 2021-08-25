//
//  WMBluetoothPeripheral.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/25.
//

#import "WMBluetoothPeripheral.h"
#import <CoreBluetooth/CoreBluetooth.h>
#define wmCBUUID @"E621E1F8-C36C-495A-93FC-0C247A3E6E5E"//theData.length ==2 || theData.length == 4 || theData.length == 16

@interface WMBluetoothPeripheral ()<CBPeripheralManagerDelegate>
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@end

@implementation WMBluetoothPeripheral
-(instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_queue_t Queue = dispatch_queue_create("wmcentralQueue",DISPATCH_QUEUE_SERIAL);

        //创建了peripheralManager对象后会自动调用回调方法didUpdateState
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:Queue];//nil表示在主线程中执行。
    }
    return self;
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state != CBManagerStatePoweredOn) {
        return;
    }
    [self configServiceAndCharacteristicForPeripheral];
}

//给外设配置服务和特征
- (void)configServiceAndCharacteristicForPeripheral {
    CBMutableCharacteristic *writeReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:wmCBUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadEncryptionRequired | CBAttributePermissionsWriteEncryptionRequired];
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:wmCBUUID] primary:YES];
    [service setCharacteristics:@[writeReadCharacteristic]];
    [self.peripheralManager addService:service];
}

-(void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error){
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }else {
        //会监听DidStartAdvertising:
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:wmCBUUID]]}];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    NSLog (@"in peripheralManagerDidStartAdvertisiong:error");
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
    
}

//当中央端连接上了此设备并订阅了特征时会回调 didSubscribeToCharacteristic:
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    CBMutableCharacteristic *writeReadCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:wmCBUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadEncryptionRequired | CBAttributePermissionsWriteEncryptionRequired];
    NSData *data = [@"我发送的数据" dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheralManager updateValue:data forCharacteristic:writeReadCharacteristic onSubscribedCentrals:nil];
}

//当中央端取消订阅时会调用didUnsubscribeFromCharacteristic:
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
}


//当接收到中央端读的请求时会调用didReceiveReadRequest:
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    } else {
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}

//当接收到中央端写的请求时会调用didReceiveWriteRequest:
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    CBATTRequest *request = requests[0];
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        CBMutableCharacteristic *c = (CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    } else {
        [self.peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


@end
