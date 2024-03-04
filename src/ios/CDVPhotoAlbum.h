#import <Photos/Photos.h>
#import <Cordova/CDV.h>

@interface CDVPhotoAlbum:CDVPlugin

- (void)getAlbums:(CDVInvokedUrlCommand *)command;
- (void)getPhotoThumbnail:(CDVInvokedUrlCommand *)command;
- (void)getPhotoData:(CDVInvokedUrlCommand *)command;

@end
