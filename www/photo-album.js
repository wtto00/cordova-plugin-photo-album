var exec = require('cordova/exec')
var platform = require('cordova/platform')

module.exports = {
  AlbumType: {
    SMART: 'smart',
    ALBUM: 'album',
    MOMENT: 'moment'
  },
  getAlbums: function (onSuccess, onError) {
    exec(onSuccess, onError, 'PhotoAlbum', 'getAlbums', [])
  },
  getPhotoThumbnail: function (imgId, onSuccess, onError) {
    exec(onSuccess, onError, 'PhotoAlbum', 'getPhotoThumbnail', [imgId])
  },
  getPhotoData: function (imgId, imgPath, onSuccess, onError) {
    exec(onSuccess, onError, 'PhotoAlbum', 'getPhotoData', [platform.id === 'ios' ? imgId : imgPath])
  }
}
