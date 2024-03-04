# cordova-plugin-photo-album

Cordova plugin for getting photo album.

## Install

```shell
cordova plugin add cordova-plugin-photo-album
```

## Before use

Before calling this plugin's method, you should first use the [cordova.plugins.diagnostic](https://www.npmjs.com/package/cordova.plugins.diagnostic) plugin to determine the request permission. This plugin does not contain permission related logic.

## Usage

### Get albums

```typescript
window.PhotoAlbum.getAlbums(
  (albums) => {
    // type is PhotoAlbum.Album[]
    console.log(albums);
  },
  (err) => {
    console.log(err);
  }
);
```

### Get thumbnail

```ts
window.PhotoAlbum.getPhotoThumbnail(
  imgId,
  (base64) => {
    console.log(base64);
  },
  (err) => {
    console.log(err);
  }
);
```

### Get origin picture data

On Android, using imgPath yields the original image without compression.

On iOS, the image obtained using imgId is a cropped image with a maximum width and height of 1024.

```ts
window.PhotoAlbum.getPhotoData(
  imgId,
  imgPath,
  (base64) => {
    console.log(base64);
  },
  (err) => {
    console.log(err);
  }
);
```
