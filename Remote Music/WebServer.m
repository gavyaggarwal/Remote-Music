//
//  WebServer.m
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import "WebServer.h"
#import "MusicLibrary.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

static NSString* _serverName = nil;

@implementation WebServer

@synthesize delegate = _delegate;
@synthesize musicLibraries = _musicLibraries;

+ (void) initialize {
    if (_serverName == nil) {
        _serverName = [[NSString alloc] initWithString:@"Remote Music Server"];
    }
}

+ (Class) connectionClass {
    return [GCDWebServerConnection class];
}

+ (NSString *) serverName {
    return _serverName;
}

- (BOOL) start {
    NSLog(@"Configuring Custom Web Server %@", self);
    self.musicLibraries = [NSMutableDictionary dictionary];
    self.sessionNames = [NSMutableDictionary dictionary];
    NSString* websitePath = [[NSBundle mainBundle] pathForResource:@"Website" ofType:nil];
    NSDictionary* baseVariables = [NSDictionary dictionaryWithObjectsAndKeys:@"footer", @"footer", nil];
    
    [self addHandlerForBasePath:@"/" localPath:websitePath indexFilename:nil cacheAge:3600];
    
    [self addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        GCDWebServerResponse *response = [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
        return response;
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/index.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        [variables setObject:UIDevice.currentDevice.name forKey:@"devicename"];
        [variables setObject:[NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"] forKey:@"appversion"];
        
        GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        return response;
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/script.js" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        // Called from GCD thread
        NSMutableDictionary* variables = [NSMutableDictionary dictionaryWithDictionary:baseVariables];
        [variables setObject:[NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"] forKey:@"appversion"];
        
        GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithHTMLTemplate:[websitePath stringByAppendingPathComponent:request.path] variables:variables];
        [response setValue:@"text/javascript" forAdditionalHeader:@"Content-Type"];
        return response;
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_session_id" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *deviceName = [request.query objectForKey:@"devicename"];
        
        NSInteger sessionID = arc4random() % 1000000;
        NSString* sessionIDString = [NSString stringWithFormat:@"%d", sessionID];
        MusicLibrary *library = [[MusicLibrary alloc] init];
        [self.musicLibraries setObject:library forKey:sessionIDString];
        [self.sessionNames setObject:deviceName forKey:sessionIDString];
        //[library release];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate webServerRequestingToConnect:self withClientName:deviceName];
        });
        
        return [GCDWebServerDataResponse responseWithText:sessionIDString];
    }];
    [self addHandlerForMethod:@"GET" path:@"/verify_session_id" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionIDString = [request.query objectForKey:@"sessionid"];
        
        NSString *responseText = @"Unknown";
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionIDString];
        if (library==nil) {
            //Denied Connection
            responseText = @"Denied";
        } else if (library.active==YES) {
            //Accepted Connection
            responseText = @"Accepted";
        } else {
            //Waiting Response
            responseText = @"Waiting";
        }
        
        return [GCDWebServerDataResponse responseWithText:responseText];
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_playlists" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSArray *playlists = [library getPlaylists];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:playlists options:0 error:nil];
        //NSLog([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        
        return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_artists" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSArray *artists = [library getArtists];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:artists options:0 error:nil];
        
        return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_songs" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSString *playlistID = [request.query objectForKey:@"playlist"];
        NSString *artistID = [request.query objectForKey:@"artist"];
        NSString *albumID = [request.query objectForKey:@"album"];
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterNoStyle];
        NSNumber *playlistIDNumber = [formatter numberFromString:playlistID];
        NSNumber *artistIDNumber = [formatter numberFromString:artistID];
        NSNumber *albumIDNumber = [formatter numberFromString:albumID];
        [formatter release];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSArray *songs = [library getSongsWithPlaylist:playlistIDNumber Artist:artistIDNumber andAlbum:albumIDNumber];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:songs options:0 error:nil];
        
        return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_albums" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSArray *albums = [library getAlbums];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:albums options:0 error:nil];
        
        return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_search_results" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        NSString *query = [request.query objectForKey:@"query"];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSArray *albums = [library getSearchResultsWithQuery:query];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:albums options:0 error:nil];
        
        return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_song" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        NSString *songID = [request.query objectForKey:@"songid"];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *songIDNumber = [formatter numberFromString:songID];
        [formatter release];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        if (library) {
            NSString *exportID = [library exportSongWithID:songIDNumber];
            return [GCDWebServerDataResponse responseWithText:exportID];
        } else {
            return [GCDWebServerDataResponse response];
        }
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_export_progress" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        NSString *exportID = [request.query objectForKey:@"exportid"];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSInteger progress = [library getExportProgressWithExportID:exportID];
        NSString *progressString = [NSString stringWithFormat:@"%d", progress];
        
        return [GCDWebServerDataResponse responseWithText:progressString];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_artwork" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        NSString *songID = [request.query objectForKey:@"songid"];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *songIDNumber = [formatter numberFromString:songID];
        [formatter release];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSData *songArtwork = [library getSongArtwork:songIDNumber];
        
        return [GCDWebServerDataResponse responseWithData:songArtwork contentType:@"image/png"];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/get_song_file" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        NSString *exportID = [request.query objectForKey:@"exportid"];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        if(library) {
            NSString* songPath = [library getSongFilePathWithExportID:exportID];
            GCDWebServerFileResponse *response = [GCDWebServerFileResponse responseWithFile:songPath];
            [response setValue:@"max-age=3600, public" forAdditionalHeader:@"Cache-Control"];
            return response;
        }
        return [GCDWebServerResponse responseWithStatusCode:401];
        
    }];
    [self addHandlerForMethod:@"GET" path:@"/download_song" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        NSString *sessionID = [request.query objectForKey:@"sessionid"];
        NSString *songID = [request.query objectForKey:@"songid"];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSNumber *songIDNumber = [formatter numberFromString:songID];
        [formatter release];
        
        MusicLibrary *library = [self.musicLibraries objectForKey:sessionID];
        NSString *result = [library downloadSongWithID:songIDNumber];
        
        return [GCDWebServerDataResponse responseWithText:result];
        
    }];
    
    if (![self startWithRunloop:[NSRunLoop mainRunLoop] port:80 bonjourName:nil]) {
        [self removeAllHandlers];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate webServerFailedToStart:self];
        });
        
        return NO;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate webServerDidStart:self];
    });
    
    return YES;
}

- (void) stop {
    [super stop];
    
    [self removeAllHandlers];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate webServerDidStop:self];
    });
}

- (NSString *) getServerIP {
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                if (address!=nil && ![address isEqualToString:@"127.0.0.1"] && ![[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    NSLog(@"Probable IP: %@ on %@", address, [NSString stringWithUTF8String:temp_addr->ifa_name]);
                    break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    if(address==nil) {
        NSLog(@"IP Address Not Found");
    }
    return address;
}

@end
