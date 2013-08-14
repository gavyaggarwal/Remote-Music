//
//  Exporter.h
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/25/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTType.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <dispatch/dispatch.h>

@interface Exporter : NSObject

@property (retain) dispatch_queue_t exportQueue;
@property (retain) MPMediaItem *song;
@property (retain) AVAssetExportSession *session;
@property (retain) NSString *filePath;
@property (assign) NSInteger progress;

- (id) initWithSong:(MPMediaItem *)song;
- (BOOL) start;
- (NSString *) getExportFilePath;

@end
