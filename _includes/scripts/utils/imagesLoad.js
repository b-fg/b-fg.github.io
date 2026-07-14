(function() {
  window.imagesLoad = function(images) {
    images = images || document.getElementsByTagName('img');
    var imagesCount = images.length, loadedCount = 0, image;
    var i, j, loaded = false, cbs = [];
    imagesCount < 1 && (loaded = true);
    for (i = 0; i < imagesCount; i++) {
      image = images[i];
      if (image.complete) {
        handleImageLoad();
      } else {
        // Count failures too, or one broken image stalls the whole batch.
        image.addEventListener('load', handleImageLoad);
        image.addEventListener('error', handleImageLoad);
      }
    }
    function handleImageLoad() {
      loadedCount++;
      if (loadedCount === imagesCount) {
        loaded = true;
        if (cbs.length > 0) {
          for (j = 0; j < cbs.length; j++) {
            cbs[j]();
          }
        }
      }
    }
    return {
      then: function(cb) {
        cb && (loaded ? cb() : (cbs.push(cb)));
      }
    };
  };
})();
