{%- include scripts/utils/imagesLoad.js -%}
(function () {
  var SOURCES = window.TEXT_VARIABLES.sources;
  window.Lazyload.js(SOURCES.jquery, function() {
    var $pageGalleryModal = $('.js-page-gallery-modal');

    function init($images) {
      if (!$images || $images.length < 1) { return; }
      /* global Gallery */
      var pageGalleryModal = $pageGalleryModal.modal({ onChange: handleModalChange });
      var gallery = null;
      var modalVisible = false;
      var i, items = [], image, item;
      for (i = 0; i < $images.length; i++) {
        image = $images.eq(i);
        // Get HTML title from parent div's data-title attribute
        var htmlTitle = image.closest('.gallery-item').attr('data-title') || image.attr('title') || '';
        item = {
          src: image.attr('data-full-src') || image.attr('src'),
          video: image.attr('data-video') || null,
          // full-res watermarked copy, not the 1200px grid thumb
          poster: image.attr('data-full-src') || image.attr('src'),
          w: image.get(0).naturalWidth,
          h: image.get(0).naturalHeight,
          title: htmlTitle,
          $el: image
        };
        items.push(item);
        if (item.w === 0) {
          // Lazy thumb not loaded yet: fill in real dimensions when it
          // arrives so the open-time refresh() sizes the slide correctly.
          image.one('load', (function(it, el) {
            return function() {
              it.w = el.naturalWidth;
              it.h = el.naturalHeight;
              if (gallery && modalVisible) { gallery.refresh(); }
            };
          })(item, image.get(0)));
        }
      }
      // use the modal container instead of .gallery
      gallery = new Gallery($pageGalleryModal.find('.gallery'), items);
      gallery.setOptions({ disabled: !modalVisible });
      gallery.init();
      for (i = 0; i < items.length; i++) {
        item = items[i];
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
      function handleModalChange(visible) {
        modalVisible = visible;
        gallery && gallery.setOptions({ disabled: !modalVisible });
      }
      $pageGalleryModal.on('click', function() {
        pageGalleryModal.hide();
      });
    }

    var $galleryImages = $('.gallery-grid .gallery-item img');
    if ($galleryImages.length > 0) {
      // Gallery grid: thumbs are loading="lazy", so waiting for all of them
      // (imagesLoad) would leave every item unclickable until the page has
      // been scrolled to the bottom — on mobile the first taps do nothing.
      // The grid is curated (no decorative images to filter out), so bind
      // immediately and let each thumb report its dimensions as it loads.
      init($galleryImages);
    } else {
      var $images = $('.page__content').find('img:not(.lightbox-ignore)');
      window.imagesLoad($images).then(function() {
        // Skip small decorative images (badges, icons).
        init($images.filter(function() { return this.naturalWidth > 200; }));
      });
    }
  });
})();
