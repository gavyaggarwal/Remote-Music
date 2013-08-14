//
//  WebServer.h
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import "GCDWebServerConnection.h"

@class WebServer;

@protocol WebServerDelegate <NSObject>
- (void) webServerDidStart:(WebServer*)server;
- (void) webServerDidStop:(WebServer*)server;
- (void) webServerFailedToStart:(WebServer*)server;
- (void) webServerRequestingToConnect:(WebServer *)server withClientName:(NSString *)name;
@end

@interface WebServer : GCDWebServer {
    id<WebServerDelegate> _delegate;
}
@property (nonatomic, assign) id<WebServerDelegate> delegate;
@property (retain) NSMutableDictionary *musicLibraries;
@property (retain) NSMutableDictionary *sessionNames;

- (NSString *) getServerIP;

@end

@interface WebServerConnection : GCDWebServerConnection
@end