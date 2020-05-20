#import "AblyFlutterWriter.h"
#import "Ably.h"
#import "ARTTypes.h"
#import "AblyFlutterMessage.h"
#import "AblyFlutterReader.h"
#import "AblyPlatformConstants.h"


@implementation AblyFlutterWriter

- (void)writeValue:(id)value {
    if([value isKindOfClass:[ARTErrorInfo class]]){
        [self writeErrorInfo: value];
        return;
    }else if([value isKindOfClass:[ARTConnectionStateChange class]]){
        [self writeConnectionStateChange: value];
        return;
    }else if([value isKindOfClass:[ARTChannelStateChange class]]){
        [self writeConnectionStateChange: value];
        return;
    }
    [super writeValue:value];
}

- (void) writeEnum:(UInt8) type enumValue: (int const) enumValue{
    [self writeByte:type];
    [self writeValue: [NSNumber numberWithInt:enumValue]];
}

- (void) writeErrorInfo:(ARTErrorInfo *const) e{
    [self writeByte:errorInfoCodecType];
    [self writeValue: nil];    //code - not available in ably-cocoa
    [self writeValue: [e message]];
    [self writeValue: @([e statusCode])];
    [self writeValue: nil]; //href - not available in ably-cocoa
    [self writeValue: nil]; //requestId - not available in ably-java
    [self writeValue: nil]; //cause - not available in ably-java
}

- (void) writeConnectState:(ARTRealtimeConnectionState const) state{ [self writeEnum:connectionStateCodecType enumValue:state]; }
- (void) writeConnectEvent:(ARTRealtimeConnectionEvent const) event{ [self writeEnum:connectionEventCodecType enumValue:event]; }
- (void) writeConnectionStateChange:(ARTConnectionStateChange *const) stateChange{
    [self writeByte:connectionStateChangeCodecType];
    [self writeConnectState: [stateChange current]];
    [self writeConnectState: [stateChange previous]];
    [self writeConnectEvent: [stateChange event]];
    [self writeValue: @((int)([stateChange retryIn] * 1000))];
    [self writeValue: [stateChange reason]];
}

- (void) writeChannelState:(ARTRealtimeChannelState const) state{ [self writeEnum:channelStateCodecType enumValue:state]; }
- (void) writeChannelEvent:(ARTChannelEvent const) event{ [self writeEnum:channelEventCodecType enumValue:event]; }
- (void) writeChannelStateChange:(ARTChannelStateChange *const) stateChange{
    [self writeByte:channelStateChangeCodecType];
    [self writeChannelState: [stateChange current]];
    [self writeChannelState: [stateChange previous]];
    [self writeChannelEvent: [stateChange event]];
    [self writeValue: @([stateChange resumed])];
    [self writeValue: [stateChange reason]];
}


@end
