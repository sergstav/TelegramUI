#ifndef OngoingCallContext_h
#define OngoingCallContext_h

#import <Foundation/Foundation.h>

@interface OngoingCallConnectionDescription : NSObject

@property (nonatomic, readonly) int64_t connectionId;
@property (nonatomic, strong, readonly) NSString * _Nonnull ip;
@property (nonatomic, strong, readonly) NSString * _Nonnull ipv6;
@property (nonatomic, readonly) int32_t port;
@property (nonatomic, strong, readonly) NSData * _Nonnull peerTag;

- (instancetype _Nonnull)initWithConnectionId:(int64_t)connectionId ip:(NSString * _Nonnull)ip ipv6:(NSString * _Nonnull)ipv6 port:(int32_t)port peerTag:(NSData * _Nonnull)peerTag;

@end

typedef NS_ENUM(int32_t, OngoingCallState) {
    OngoingCallStateInitializing,
    OngoingCallStateConnected,
    OngoingCallStateFailed
};

typedef NS_ENUM(int32_t, OngoingCallNetworkType) {
    OngoingCallNetworkTypeWifi,
    OngoingCallNetworkTypeCellularGprs,
    OngoingCallNetworkTypeCellularEdge,
    OngoingCallNetworkTypeCellular3g,
    OngoingCallNetworkTypeCellularLte
};

@protocol OngoingCallThreadLocalContextQueue <NSObject>

- (void)dispatch:(void (^ _Nonnull)())f;
- (bool)isCurrent;

@end

@interface VoipProxyServer : NSObject

@property (nonatomic, strong, readonly) NSString * _Nonnull host;
@property (nonatomic, readonly) int32_t port;
@property (nonatomic, strong, readonly) NSString * _Nullable username;
@property (nonatomic, strong, readonly) NSString * _Nullable password;

- (instancetype _Nonnull)initWithHost:(NSString * _Nonnull)host port:(int32_t)port username:(NSString * _Nullable)username password:(NSString * _Nullable)password;

@end

@interface OngoingCallThreadLocalContext : NSObject

+ (void)setupLoggingFunction:(void (* _Nullable)(NSString * _Nullable))loggingFunction;

@property (nonatomic, copy) void (^ _Nullable stateChanged)(OngoingCallState);

- (instancetype _Nonnull)initWithQueue:(id<OngoingCallThreadLocalContextQueue> _Nonnull)queue allowP2P:(BOOL)allowP2P proxy:(VoipProxyServer * _Nullable)proxy networkType:(OngoingCallNetworkType)networkType;
- (void)startWithKey:(NSData * _Nonnull)key isOutgoing:(bool)isOutgoing primaryConnection:(OngoingCallConnectionDescription * _Nonnull)primaryConnection alternativeConnections:(NSArray<OngoingCallConnectionDescription *> * _Nonnull)alternativeConnections maxLayer:(int32_t)maxLayer;
- (void)stop;

- (void)setIsMuted:(bool)isMuted;
- (void)setNetworkType:(OngoingCallNetworkType)networkType;

@end

#endif
