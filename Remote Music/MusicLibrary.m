//
//  MusicLibrary.m
//  Remote Music
//
//  Created by Gavy Aggarwal on 7/24/13.
//  Copyright (c) 2013 Gavy Aggarwal. All rights reserved.
//

#import "MusicLibrary.h"
#import "Exporter.h"

@implementation MusicLibrary

- (id) init {
    self = [super init];
    if (self) {
        self.exporters = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSArray *) getPlaylists {
    NSMutableArray *formattedPlaylists = [NSMutableArray array];
    MPMediaQuery *query = [MPMediaQuery playlistsQuery];
    NSArray *playlists = [query collections];
    for (MPMediaPlaylist *playlist in playlists) {
        [formattedPlaylists addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                       [playlist valueForProperty:MPMediaPlaylistPropertyName], @"title",
                                       [NSNumber numberWithInteger:playlist.count], @"songs",
                                       [[playlist valueForProperty:MPMediaPlaylistPropertyPersistentID] stringValue], @"id",
                                       nil]];
    }
    return formattedPlaylists;
}

- (NSArray *) getArtists {
    NSMutableArray *formattedArtists = [NSMutableArray array];
    MPMediaQuery *query = [MPMediaQuery artistsQuery];
    NSArray *artists = [query collections];
    for (MPMediaItemCollection *artist in artists) {
        [formattedArtists addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [artist.representativeItem valueForProperty:MPMediaItemPropertyArtist], @"title",
                                     [NSNumber numberWithInteger:artist.count], @"songs",
                                     [[artist.representativeItem valueForProperty:MPMediaItemPropertyArtistPersistentID] stringValue], @"id",
                                     nil]];
    }
    return formattedArtists;
}

- (NSArray *) getSongs {
    return [self getSongsWithPlaylist:nil Artist:nil andAlbum:nil];
}

- (NSArray *) getSongsWithPlaylist:(NSNumber *)playlistID Artist:(NSNumber *)artistID andAlbum:(NSNumber *)albumID {
    NSArray *songs = nil;
    NSMutableArray *formattedSongs = [NSMutableArray array];
    if (playlistID!=nil) {
        MPMediaPropertyPredicate *playlistPredicate = [MPMediaPropertyPredicate predicateWithValue:playlistID forProperty:MPMediaPlaylistPropertyPersistentID];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:playlistPredicate];
        songs = [query items];
        [query release];
    } else if(artistID!=nil) {
        MPMediaPropertyPredicate *artistPredicate = [MPMediaPropertyPredicate predicateWithValue:artistID forProperty:MPMediaItemPropertyArtistPersistentID];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:artistPredicate];
        songs = [query items];
        [query release];
    } else if(albumID!=nil) {
        MPMediaPropertyPredicate *albumPredicate = [MPMediaPropertyPredicate predicateWithValue:albumID forProperty:MPMediaItemPropertyAlbumPersistentID];
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate:albumPredicate];
        songs = [query items];
        [query release];
    } else {
        MPMediaQuery *query = [MPMediaQuery songsQuery];
        songs = [query items];
    }
    for (MPMediaItem *song in songs) {
        [formattedSongs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [song valueForProperty:MPMediaItemPropertyTitle], @"title",
                                   [song valueForProperty:MPMediaItemPropertyArtist], @"artist",
                                   [song valueForProperty:MPMediaItemPropertyAlbumTitle], @"album",
                                   [[song valueForProperty:MPMediaItemPropertyPersistentID] stringValue], @"id",
                                   nil]];
    }
    return formattedSongs;
}

- (NSArray *) getAlbums {
    NSMutableArray *formattedAlbums = [NSMutableArray array];
    MPMediaQuery *query = [MPMediaQuery albumsQuery];
    NSArray *albums = [query collections];
    for (MPMediaItemCollection *album in albums) {
        [formattedAlbums addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [album.representativeItem valueForProperty:MPMediaItemPropertyAlbumTitle], @"title",
                                    [album.representativeItem valueForProperty:MPMediaItemPropertyArtist], @"artist",
                                    [[album.representativeItem valueForProperty:MPMediaItemPropertyAlbumPersistentID] stringValue], @"id",
                                    nil]];
    }
    return formattedAlbums;
}

- (NSArray *) getSearchResultsWithQuery:(NSString *)query {
    NSMutableArray *formattedResults = [NSMutableArray array];
    MPMediaQuery *searchQuery = [[MPMediaQuery alloc] init];
    //NSString *predicateString = [NSString stringWithFormat:@"%@ contains[cd] %@ OR %@ contains[cd] %@ OR %@ contains[cd] %@", MPMediaItemPropertyTitle, query, MPMediaItemPropertyAlbumTitle, query, MPMediaItemPropertyArtist, query];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title contains[cd] %@ OR albumTitle contains[cd] %@ OR artist contains[cd] %@", query, query, query];
    NSArray *filteredArray = [[searchQuery items] filteredArrayUsingPredicate:predicate];
    [searchQuery release];
    
    for (MPMediaItem *song in filteredArray) {
        [formattedResults addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [song valueForProperty:MPMediaItemPropertyTitle], @"title",
                                     [song valueForProperty:MPMediaItemPropertyArtist], @"artist",
                                     [song valueForProperty:MPMediaItemPropertyAlbumTitle], @"album",
                                     [[song valueForProperty:MPMediaItemPropertyPersistentID] stringValue], @"id",
                                     nil]];
    }
    
    return formattedResults;
}

- (NSString *) exportSongWithID:(NSNumber *)songID {
    MPMediaPropertyPredicate *songPredicate = [MPMediaPropertyPredicate predicateWithValue:songID forProperty:MPMediaItemPropertyPersistentID];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:songPredicate];
    NSArray *songs = [query items];
    [query release];
    MPMediaItem *song = [songs lastObject];
    
    NSInteger exportID = arc4random() % 1000000;
    NSString *exportIDString = [NSString stringWithFormat:@"%d", exportID];
    
    Exporter *exporter = [[Exporter alloc] initWithSong:song];
    [self.exporters setObject:exporter forKey:exportIDString];
    [exporter start];
    
    return exportIDString;
}

- (NSData *) getSongArtwork:(NSNumber *)songID {
    MPMediaPropertyPredicate *songPredicate = [MPMediaPropertyPredicate predicateWithValue:songID forProperty:MPMediaItemPropertyPersistentID];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:songPredicate];
    NSArray *songs = [query items];
    [query release];
    MPMediaItem *song = [songs lastObject];
    
    MPMediaItemArtwork *artwork = [song valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *artworkImage = [artwork imageWithSize:CGSizeMake(200, 200)];
    NSData *artworkData = UIImagePNGRepresentation(artworkImage);
    if (artworkData==nil) {
        NSString *defaultArtworkPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Website/no-artwork.png"];
        artworkData = [NSData dataWithContentsOfFile:defaultArtworkPath];
    }
    return artworkData;
}

- (NSString *) getSongFilePathWithExportID:(NSString *)exportID {
    Exporter *exporter = [self.exporters objectForKey:exportID];
    if (exporter) {
        return exporter.filePath;
    }
    return nil;
}

- (NSInteger) getExportProgressWithExportID:(NSString *)exportID {
    Exporter *exporter = [self.exporters objectForKey:exportID];
    int progress = exporter.progress;
    if (progress==0) {
        progress = (float)(exporter.session.progress * 100.0);
    }
    return progress;
}

- (NSString *) downloadSongWithID:(NSNumber *)songID {
    
    MPMusicPlayerController *player = [MPMusicPlayerController iPodMusicPlayer];
    
    MPMediaPropertyPredicate *songPredicate = [MPMediaPropertyPredicate predicateWithValue:songID forProperty:MPMediaItemPropertyPersistentID];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query addFilterPredicate:songPredicate];
    [player setQueueWithQuery:query];
    [query release];
    
    [player play];
    [player pause];
    
    return @"Result";
}

@end
