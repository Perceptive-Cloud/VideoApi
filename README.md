VideoApi
========

A helper library for accessing the Twistage API.

Version notes
-------------
-   1.0.2

    Added ImageApi

-   1.0.3

    Added LibraryApi

    replaced account_id w/company_id (#8196)

    HttpClient: .is_trace_on -> .trace_on?, added .trace_off

-   1.1.0

    Added PlaylistApi

-   1.1.1

    Added duration parameter for authenticate_for_view and authenticate_for_update

    Added PlaylistApi#create_playlist_from_hash and #delete_playlist

    Converted create_video_assets... and create_track_assets... methods to singular, since they only create 1 at a time

-   1.1.2

    Removed references to IngestProfiles from docs for asset create methods (both Video & Track)

    Added undocumented #delete_asset to AudioApi and VideoApi

    Added #delete_many_images to ImageApi

-   1.1.3

    Fixed ImageApi#upload_image

-   1.1.4

    Added VideoApi module for namespacing

-   1.1.5

    Allowed ImageApi#update_image to not wrap params inside 'image'

-   1.1.6
    Added AlbumApi#create_album_from_hash

    Removed obscuring of Exceptions in media_api_result

-   1.1.7
    Changed 'sites' in URLs to 'libraries'

-   1.1.8

    Fixed missing json error, added dependency on json gem

-   1.1.8.1

    Fixed error whereby ingest_profile was not passed in properly for authentication

-   1.1.8.2

    Now automatically require'ing each subcomponent API class to avoid usability issues.

-   1.1.8.3

    Add support for search_libraries / Search Library API.
    
-   1.1.8.5
    Add support for create_playlists / Playlist API.
