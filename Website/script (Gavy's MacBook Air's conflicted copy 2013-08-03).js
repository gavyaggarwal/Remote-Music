var sessionID = null;
var processes = [];

function loadLibraryTable(data) {
	$("#library-table").empty();
	for (var i = 0; i < data.length; i++) {
		var cellData = data[i];
		var row = $('<tr></tr>');
		var cell = $('<td></td>');
		var cellHTML = '<span class="title">' + cellData.title + '</span><span class="subtitle">' + cellData.subtitle + '</span>';
		if (cellData.arrow==true) {
			cellHTML += '<img src="arrow.png">';
		}
		cellData.data.cssID = "song-" + i;
		$(cell).attr("id", cellData.data.cssID);
		$(cell).append(cellHTML);
		$(cell).click(cellData.callback);
		$(cell).data("data", cellData.data);
		$(row).append(cell);
		$("#library-table").append(row);
	}
}
function loadProcessesTable() {
	var contents = "";
	for (var i = 0; i < processes.length; i++) {
		contents += '<tr><td><span>' + processes[i].mode + ' ' + processes[i].title + '</span></td><td><div class="slider-track" style="height:4px;border-radius:4px;width:50px;"><div class="slider-head" id="' + processes[i].id + '-slider" style="width:0px;height:4px;"></div></div></td></tr>';
	}
	if(contents=="") {
		contents = '<tr><td colspan="2" style="text-align:center;width:250px;">(None)</td></tr>';
	}
	$("#processes").html(contents);
}
function loadPlaylistTable() {
	var contents = "";
	for (var i = playlist.current + 1; i < playlist.playlist.length; i++) {
		var song = playlist.playlist[i];
		contents += '<tr><td><span class="outer">' + song.title + ' • ' + song.artist + '</span></td></tr>';
	}
	if(contents=="") {
		contents = '<tr><td style="text-align:center;width:250px;">(None)</td></tr>';
	}
	$("#playlist").html(contents);
}
function deleteProcessWithID(id) {
	var tempArray = [];
	for (var i = 0; i < processes.length; i++) {
		if(processes[i].id!=id) {
			tempArray.push(processes[i]);
		}
	}
	processes = tempArray;
}
function resetSong() {
	$("#controls").animate({
		opacity:0.0
	});
}
function playSong() {
	playlist.play();
}
function pauseSong() {
	playlist.pause();
}
function previousSong() {
	playlist.previous();
}
function nextSong() {
	playlist.next();
}
function checkInternet() {
	var URL = "http://feistapps.com/app/remotemusic/availability.php";
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		if(data=="available") {
			//Load Internet Based Content
			showAds();
		}
	}).fail(function() {
		console.log("Error: Not Connected to Internet");
	});
}
function showAds() {
	console.log("Loading Ads");
}
function getSessionID() {
	var URL = "get_session_id";
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		sessionID = data;
		console.log("Session ID: " + sessionID);
		//Remove This Later
		getPlaylists();
	}).fail(function() {
		alert("There was an error communicating with the host device.");
		sessionID = null;
	});
}
function getPlaylists() {
	var URL = "get_playlists?sessionid=" + sessionID;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		updatePlaylists(data);
	}).fail(function() {
		alert("There was an error loading the playlists.");
		updatePlaylists([]);
	});
}
function getArtists() {
	var URL = "get_artists?sessionid=" + sessionID;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		updateArtists(data);
	}).fail(function() {
		alert("There was an error loading the artists.");
		updateArtists([]);
	});
}
function getSongs(options) {
	var URL = "get_songs?sessionid=" + sessionID;
	for (var key in options) {
		URL += "&" + key + "=" + options[key];
	}
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		updateSongs(data);
	}).fail(function() {
		alert("There was an error loading the songs.");
		updateSongs(null);
	});
}
function getAlbums() {
	var URL = "get_albums?sessionid=" + sessionID;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		updateAlbums(data);
	}).fail(function() {
		alert("There was an error loading the albums.");
		updateAlbums(null);
	});
}
function getSearchResults(query) {
	var URL = "get_search_results?sessionid=" + sessionID + "&query=" + query;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		if(data.length==0) {
			alert("No search results were found for your query: " + query);
		} else {
			updateSongs(data);	
		}
	}).fail(function() {
		alert("There was an error loading the search results.");
		updateSongs(null);
	});
}
function getSong(song, autostart) {
	if (autostart==true) {
		//User manually started playback
		var currentSong = playlist.playlist[playlist.current];
		if(currentSong!=undefined) {
			$("#" + currentSong.cssID).find("img").remove();
		}
	}
	getArtwork(song);
	var URL = "get_song?sessionid=" + sessionID + "&songid=" + song.id;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		song.exportID = data;
		processes.push({
			mode: "Exporting",
			id: data,
			title: song.title
		});
		loadProcessesTable();
		trackExportProgress(song, data, autostart);
	}).fail(function() {
		alert("There was an error loading " + song.title + ".");
	});
}
function downloadSong(song) {
	//Used for downloading songs from iTunes Match
	var URL = "download_song?sessionid=" + sessionID + "&songid=" + song.id;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		console.log("DOWNLOAD RESULT = "+data);
		//downloadSong(song);
	}).fail(function() {
		console.log("There was an error downloading " + song.title + " from iTunes Match.");
	});
}
function getArtwork(song) {
	var artwork = "get_artwork?sessionid=" + sessionID + "&songid=" + song.id;
	song.artwork = artwork;
	return artwork;
}
function getSongFile(song, exportID, autostart) {
	var URL = "get_song_file?sessionid=" + sessionID + "&exportid=" + exportID;
	
	song.m4a = URL;
	/*$.ajax({
		url: URL,
		cache: true,
		beforeSend: function(thisXHR) {
			console.log("BEFORE SEND");
			myTrigger = setInterval (function () {
            	if (thisXHR.readyState > 2) {
                	var totalBytes  = thisXHR.getResponseHeader('Content-length');
                	var dlBytes     = thisXHR.responseText.length;
                	
                  	//(totalBytes > 0) ? progressElem.html (Math.round ((dlBytes/ totalBytes) * 100) + "%") : progressElem.html (Math.round (dlBytes /1024) + "K");
                	console.log("DL PROGRESS: " + totalBytes +" TOTAL, LEFT: " + dlBytes);
               	}
            }, 200);
		},
		complete: function() {
			console.log("COMPLETE NIKKA");
			clearInterval (myTrigger);
		},
		success: function(data) {
			console.log("SONF FILE BITCH ARRIVED");
			var audio = $("audio");
			$(audio).find("source").attr("src", URL);
			$(audio).get(0).load();
			$(audio).get(0).play();
		}
	}).fail(function() {
		console.log("There was an error buffering the song.");
	});*/
	playlist.add(song, autostart);
	updateQueue();
	//console.log("Adding Song to Queue: \n" + getObjectString(playlist.playlist));
	$("#controls").animate({
		opacity:1.0
	});
	loadPlaylistTable();
}
function updateQueue(nextIndex) {
	//This function will check if any up the upcoming music files need to be prepared (exported and buffered) for playing
	if(playlist.current+6>playlist.playlist.length) {
		console.log("Queuing More Songs for Playing");
		var currentID = playlist.playlist[playlist.playlist.length-1].id;
		var songTable = $("#library-table  tr td");
		if(nextIndex==undefined) {
			$(songTable).each(function(index) {
				if($(this).data("data").id==currentID) {
					nextIndex = index+1;
					return false;  //Breaks out of loop
				}
			});
		}
		var song = $(songTable[nextIndex]).data("data");
		song.index = nextIndex;
		getSong(song, false);
	}
	//updateQueue();
}
function trackExportProgress(song, exportID, autostart) {
	var URL = "get_export_progress?sessionid=" + sessionID + "&exportid=" + exportID;
	$.ajax({
		url: URL,
		cache: false
	}).done(function(data) {
		console.log("Tracking Export Progress: " + data + "%");
		var progress = parseInt(data);
		$("#" + exportID + "-slider").animate({
			width: progress/2.0
		});
		if(progress==100) {
			//Download Song (it's ready)
			deleteProcessWithID(exportID);
			loadProcessesTable();
			getSongFile(song, exportID, autostart);
		} else if(progress<0) {
			//Export Error
			deleteProcessWithID(exportID);
			loadProcessesTable();
			if(progress==-1) {
				if(autostart==true) {
					alert("There was a software error retrieving the selected song from the music library.")
				}
				console.log("Unable to export file: AssetURL is nil")
			} else if(progress==-2) {
				if(autostart==true) {
					alert("The song that you selected is not stored on your device. Please verify that it is downloaded from iTunes Match before you play it.");
				} else {
					downloadSong(song);   //Attempt to download it
				}
				console.log("Unable to export file: Not downloaded from iTunes Match");
			} else if(progress==-3) {
				if(autostart==true) {
					alert("There was an internal error processing the file for playback.");
				}
				console.log("Unable to export file: Export Failed");
			}
			if(autostart==false) {
				//Auto-initiated
				updateQueue(song.index+1);
			}
		} else {
			setTimeout(function() {
				trackExportProgress(song, exportID, autostart);
			}, 400);
		}
	}).fail(function() {
		console.log("There was an error getting the song progress.");
	});
}
function updatePlaylists(playlists) {
	var data = [];
	for (var i = 0; i < playlists.length; i++) {
		data.push({
			title:playlists[i].title,
			subtitle:playlists[i].songs + " Songs",
			data:playlists[i],
			arrow:true,
			callback:function() {
				getSongs({
					playlist:$(this).data("data").id
				});
			}
		});
	}
	loadLibraryTable(data);
}
function updateArtists(artists) {
	var data = [];
	for (var i = 0; i < artists.length; i++) {
		data.push({
			title:artists[i].title,
			subtitle:artists[i].songs + " Songs",
			data:artists[i],
			arrow:true,
			callback:function() {
				getSongs({
					artist:$(this).data("data").id
				});
			}
		});
	}
	loadLibraryTable(data);
}
function updateSongs(songs) {
	var data = [];
	for (var i = 0; i < songs.length; i++) {
		data.push({
			title:songs[i].title,
			subtitle:songs[i].artist + " • " + songs[i].album,
			data:songs[i],
			arrow:false,
			callback:function() {
				getSong($(this).data("data"), true);
			}
		});
	}
	loadLibraryTable(data);
}
function updateAlbums(albums) {
	var data = [];
	for (var i = 0; i < albums.length; i++) {
		data.push({
			title:albums[i].title,
			subtitle:albums[i].artist,
			data:albums[i],
			arrow:true,
			callback:function() {
				getSongs({
					album:$(this).data("data").id
				});
			}
		});
	}
	loadLibraryTable(data);
}
function setup() {
	var searchfield = $("#searchfield");
	$(searchfield).focus(function() {
		$(this).val("");
		$(this).animate({
			width:"95%"
		});
		$(this).css("color", "#333");
		$(this).keypress(function (e) {
			if (e.which == 13) {
				getSearchResults($(this).val());
			}
		});
	});
	$(searchfield).blur(function() {
		$(this).val("Search");
		$(this).animate({
			width:"75%"
		});
		$(this).css("color", "#999");
	});
	var	jPlayer = $("#jplayer");
	jPlayer.jPlayer({
		ready: function () {
			//console.log("READY");
		},
		timeupdate: function(event) {
			$("#progress-slider").width(event.jPlayer.status.currentPercentAbsolute * 2.0);
		},
		play: function(event) {
			$("#play").css("display", "none");
			$("#pause").css("display", "");
			var song = playlist.playlist[playlist.current];
			$("#" + song.cssID).append('<img src="speaker.png" />');
			var container = $("#current-song");
			container.find("#current-title").html(song.title);
			container.find("#current-artist").html(song.artist);
			container.find("#current-album").html(song.album);
			$("#artwork-image").attr("src", song.artwork);
			loadPlaylistTable();
		},
		pause: function(event) {
			$("#play").css("display", "");
			$("#pause").css("display", "none");
		},
		ended: function(event) {
			var song = playlist.playlist[playlist.current];
			$("#" + song.cssID).find("img").remove();
			setTimeout(updateQueue, 100);
		},
		progress: function(event) {
			//Track Download Progress Using: event.jPlayer.status.seekPercent
		},
		loadstart: function(event) {
			$("#buffer-slider").width(0);
			$("#current-song #header").html("Buffering");
			$("#buffer-slider").animate({
				width: 200
			}, 60000);
		},
		loadeddata: function(event) {
			$("#current-song #header").html("Now Playing");
		},
		swfPath: "",
		supplied: "m4a",
		//errorAlerts:true,
		wmode: "window"
	});
	var cssSelector = { jPlayer: "#jplayer", cssSelectorAncestor: "#current-song" };
	var options = { swfPath: "", supplied: "m4a", playlistOptions: { autoPlay: true, enableRemoveControls: true } };
	playlist = new jPlayerPlaylist(cssSelector, [], options);
}
function getObjectString(object) {
	var queue = "";
	for(var i = 0; i < object.length; i++) {
		queue += "Song " + i + ": ";
		for(var x in object[i]) {
			queue += x + "=" + object[i][x] + " ";
		}
		queue += "\n";
	}
	return queue;
}
$(document).ready(function() {
	console.log("Starting Remote Music Version %appversion%");
	setup();
	loadProcessesTable();
	loadPlaylistTable();
	getSessionID();
	showAds();
});