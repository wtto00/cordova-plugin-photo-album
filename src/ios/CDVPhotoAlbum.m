#import <Photos/Photos.h>
#import "CDVPhotoAlbum.h"

@implementation CDVPhotoAlbum

#pragma mark "API"
- (void)pluginInitialize {
}

- (void)getAlbums:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        NSMutableArray *albums = [[NSMutableArray alloc] init];
        
        NSArray *collectionTypes = @[
            @{@"title" : @"smart", @"type" : [NSNumber numberWithInteger: PHAssetCollectionTypeSmartAlbum]},
            @{@"title" : @"album", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum]},
            @{@"title" : @"moment", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeMoment]}
        ];
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
        
        for (NSDictionary *collectionType in collectionTypes){
            [[PHAssetCollection fetchAssetCollectionsWithType:[[collectionType objectForKey:@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
             {
                if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil)
                {
                    NSMutableArray *images = [[NSMutableArray alloc] init];
                    PHFetchResult *assetsInAlbum = [PHAsset fetchAssetsInAssetCollection:collection options:options];
                    for (int i = 0; i < assetsInAlbum.count; i++) {
                        PHAsset *img = [assetsInAlbum objectAtIndex:i];
                        NSString *directory = [img valueForKey:@"_directory"];
                        NSString *filename = [img valueForKey:@"_filename"];
                        [images addObject:@{
                            @"id": [img localIdentifier],
                            @"path": [directory stringByAppendingFormat:@"/%@",filename]
                        }];
                    }
                    
                    if (images.count > 0) {
                        [albums addObject:@{
                            @"id" : collection.localIdentifier,
                            @"name" : collection.localizedTitle,
                            @"type" : [collectionType objectForKey:@"title"],
                            @"images" : images
                        }];
                    }
                }
            }];
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:albums];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getPhotoThumbnail:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        NSString *imgId = [command.arguments objectAtIndex:0];
        if (!imgId) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"unknown imgId"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[imgId] options:nil];
        PHAsset *asset = result.firstObject;
        
        if (!asset) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"unknown img"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        PHImageManager *imageManager = [PHImageManager defaultManager];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        CGSize thumbnailSize = CGSizeMake(256, 256);
        
        [imageManager requestImageForAsset:asset
                                targetSize:thumbnailSize
                               contentMode:PHImageContentModeAspectFill
                                   options:options
                             resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                NSData *imageData = UIImageJPEGRepresentation(result, 0.7);
                CDVPluginResult *commandResult = [
                    CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[
                        [NSString alloc] initWithFormat:@"data:image/jpeg;base64,%@",
                        [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]
                    ]
                ];
                
                [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
            } else {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"unknown error"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    }];
}

- (void)getPhotoData:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        NSString *imgId = [command.arguments objectAtIndex:0];
        if (!imgId) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"unknown imgId"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[imgId] options:nil];
        PHAsset *asset = result.firstObject;
        
        if (!asset) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"unknown img"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        CGSize photoSize = CGSizeMake(1024, 1024);
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:photoSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (result) {
                NSData *imageData = UIImagePNGRepresentation(result);
                CDVPluginResult *commandResult = [
                    CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[
                        [NSString alloc] initWithFormat:@"data:image/png;base64,%@",
                        [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]
                    ]
                ];
                
                [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
            } else {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"unknown error"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    }];
}

@end
