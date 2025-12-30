{%- include scripts/utils/imagesLoad.js -%}
(function () {
  var SOURCES = window.TEXT_VARIABLES.sources;
  window.Lazyload.js(SOURCES.jquery, function() {
    var $pageGalleryModal = $('.js-page-gallery-modal');
    var $images = $('.page__content').find('img:not(.lightbox-ignore)');
    var $galleryItems = $('.gallery-grid').find('.gallery-item');

    // Combine images from both sources
    if ($galleryItems.length > 0) {
      $galleryItems.each(function() {
        var $img = $(this).find('img');
        if ($img.length > 0) {
          $images = $images.add($img);
        }
      });
    }
    window.imagesLoad($images).then(function() {
      /* global Gallery */
      var pageGalleryModal = $pageGalleryModal.modal({ onChange: handleModalChange });
      var gallery = null;
      var modalVisible = false;
      var i, items = [], image, item;
      if($images && $images.length > 0) {
        for (i = 0; i < $images.length; i++) {
          image = $images.eq(i);
          if (image.get(0).naturalWidth > 200) {
            // Get HTML title from parent div's data-title attribute
            var htmlTitle = image.closest('.gallery-item').attr('data-title') || image.attr('title') || '';
            items.push({
              src: image.attr('src'),
              w: image.get(0).naturalWidth,
              h: image.get(0).naturalHeight,
              title: htmlTitle,
              $el: image
            });
          }
        }
      }
      if(items.length > 0) {
        // use the modal container instead of .gallery
        gallery = new Gallery($pageGalleryModal.find('.gallery'), items);
        gallery.setOptions({ disabled: !modalVisible });
        gallery.init();
        for (i = 0; i < items.length; i++) {
          item = items[i];
          if (item.$el) {
            item.$el.addClass('popup-image');

            // Check if image is inside a gallery-item container
            var $container = item.$el.closest('.gallery-item');
            var $clickTarget = $container.length > 0 ? $container : item.$el;

            $clickTarget.on('click', (function() {
              var index = i;
              return function() {
                pageGalleryModal.show();
                gallery.setOptions({ initialSlide: index });
                gallery.refresh(true, { animation: false });

                // Re-render MathJax after modal opens
                setTimeout(function() {
                  if (window.MathJax && window.MathJax.typesetPromise) {
                    window.MathJax.typesetPromise([$pageGalleryModal[0]]).catch(function (err) {
                      console.log('MathJax typeset failed: ' + err.message);
                    });
                  } else if (window.MathJax && window.MathJax.Hub) {
                    window.MathJax.Hub.Queue(["Typeset", window.MathJax.Hub, $pageGalleryModal[0]]);
                  }
                }, 100);
              };
            })());
          }
        }
      }
      function handleModalChange(visible) {
        modalVisible = visible;
        gallery && gallery.setOptions({ disabled: !modalVisible });
      }
      $pageGalleryModal.on('click', function() {
        pageGalleryModal.hide();
      });
    });
  });
})();