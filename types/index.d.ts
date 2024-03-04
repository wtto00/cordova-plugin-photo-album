declare namespace PhotoAlbum {
  interface ImageItem {
    id: number;
    /**
     * Image path
     */
    path: string;
  }

  enum AlbumType {
    /** Smart photo albums automatically created and managed by devices */
    SMART = "smart",
    /** Albums manually created by users on the device */
    ALBUM = "album",
    /** The system automatically organizes photo albums based on time and location information */
    MOMENT = "moment",
  }

  interface Album {
    id: number;
    name: string;
    /**
     * Album type
     * **Only for iOS**
     */
    type?: AlbumType;
    images: ImageItem[];
  }

  function getAlbums(onSuccess: (albums: Album[]) => void, onFail: (err: string) => void): void;

  function getPhotoThumbnail(imgId: number, onSuccess: (base64: string) => void, onFail: (err: string) => void): void;

  function getPhotoData(
    imgId: number,
    imgPath: string,
    onSuccess: (base64: string) => void,
    onFail: (err: string) => void
  ): void;
}

interface Window {
  PhotoAlbum: typeof PhotoAlbum;
}
