//
//  MusicLibrary.h
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface MusicLibrary : NSObject

@property (retain) NSMutableDictionary *exporters;
@property (assign) BOOL active;

- (NSArray *) getPlaylists;
- (NSArray *) getArtists;
- (NSArray *) getSongs;
- (NSArray *) getSongsWithPlaylist:(NSNumber *)playlistID Artist:(NSNumber *)artistID andAlbum:(NSNumber *)albumID;
- (NSArray *) getAlbums;
- (NSArray *) getSearchResultsWithQuery:(NSString *)query;
- (NSString *) exportSongWithID:(NSNumber *)songID;
- (NSData *) getSongArtwork:(NSNumber *)songID;
- (NSString *) getSongFilePathWithExportID:(NSString *)exportID;
- (NSInteger) getExportProgressWithExportID:(NSString *)exportID;
- (NSString *) downloadSongWithID:(NSNumber *)songID;

@end
