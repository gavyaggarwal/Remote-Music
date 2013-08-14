//
//  Exporter.m
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/25/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import "Exporter.h"

@implementation Exporter
@synthesize song = _song;
@synthesize session = _session;

- (id) initWithSong:(MPMediaItem *)song {
    self = [super init];
    if (self) {
        NSLog(@"Exporter init Called");
        self.exportQueue = dispatch_queue_create("com.aggarwalcreations.itransfer.export_queue", NULL);
        self.song = song;
        NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
        if (assetURL!=nil) {
            AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
            self.session = [[AVAssetExportSession alloc] initWithAsset:songAsset presetName:AVAssetExportPresetAppleM4A];
        } else {
            self.progress = -1;
        }
        if ([[song valueForProperty:MPMediaItemPropertyIsCloudItem] boolValue]) {
            self.progress = -2;
        }
        self.filePath = [self getExportFilePath];
    }
    return self;
}

- (void) dealloc {
    NSLog(@"Exporter dealloc Called");
    [_song release];
    [_session release];
    [super dealloc];
}

#pragma mark -

- (BOOL) start {
    if (self.session && self.progress!=100) {
        self.session.outputFileType = @"com.apple.m4a-audio";
        self.session.outputURL = [NSURL fileURLWithPath:self.filePath];
        
        //Set metadata
        NSMutableArray *metadata = [NSMutableArray array];
        NSArray *metadataKeyPairs = [NSArray arrayWithObjects:
                                     [NSArray arrayWithObjects:AVMetadataCommonKeyTitle, MPMediaItemPropertyTitle, nil],
                                     [NSArray arrayWithObjects:AVMetadataCommonKeyArtist, MPMediaItemPropertyArtist, nil],
                                     [NSArray arrayWithObjects:AVMetadataCommonKeyAlbumName, MPMediaItemPropertyAlbumTitle, nil],
                                     //[NSArray arrayWithObjects:AVMetadataCommonKeyArtwork, MPMediaItemPropertyArtwork, nil],
                                     [NSArray arrayWithObjects:AVMetadataCommonKeyDescription, MPMediaItemPropertyComments, nil],
                                     [NSArray arrayWithObjects:AVMetadataCommonKeyType, MPMediaItemPropertyMediaType, nil],
                                     nil];
        for (int i=0; i<metadataKeyPairs.count; i++) {
            AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
            item.keySpace = AVMetadataKeySpaceCommon;
            item.key = [[metadataKeyPairs objectAtIndex:i] objectAtIndex:0];
            item.value = [self.song valueForProperty:[[metadataKeyPairs objectAtIndex:i] objectAtIndex:1]];
            [metadata addObject:item];
            [item release];
        }
        
        self.session.metadata = metadata;
        
        [self.session exportAsynchronouslyWithCompletionHandler:^{
            if (self.session.status==AVAssetExportSessionStatusCompleted) {
                //Do work with file
                NSLog (@"AVAssetExportSessionStatusCompleted");
            } else if (self.session.status==AVAssetExportSessionStatusFailed) {
                NSError *exportError = self.session.error;
                NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                //Tell user there was an error exporting
                self.progress = -3;
            }
        }];
        return YES;
    }
    return NO;
}

- (NSString *) getExportFilePath {
    NSString *exportFile = [NSString stringWithFormat:@"%@/%@.m4a", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0], [self.song valueForProperty:MPMediaItemPropertyPersistentID]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:exportFile]) {
        //We don't need to export it
        NSLog(@"File Already Exported");
        self.progress = 100;
    }
    return exportFile;
}

@end
