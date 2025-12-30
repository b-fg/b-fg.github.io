---
layout: articles
permalink: /gallery
title: Gallery
show_title: false
lightbox: true
---

<style>
/* Hide titles from grid */
.gallery-grid .item__header,
.gallery-grid .item__content,
.gallery-grid .article__header {
  display: none !important;
}

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

@media (max-width: 768px) {
  .gallery-grid {
    grid-template-columns: 1fr;
  }
}

.gallery-item {
  position: relative;
  overflow: hidden;
  border-radius: 8px;
  cursor: pointer;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.gallery-item:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0,0,0,0.15);
}

.gallery-item img {
  width: 100%;
  height: auto;
  display: block;
  transition: transform 0.3s ease;
}

.gallery-item:hover img {
  transform: scale(1.05);
}

/* Remove hover in modal */
.js-page-gallery-modal .gallery-item,
.js-page-gallery-modal .gallery-item img {
  transform: none !important;
  transition: none !important;
}
</style>

{%- assign _articles = site.gallery | reverse -%}

<div class="gallery-grid">
  {%- for _item in _articles -%}
    {%- if _item.image -%}
      <div class="gallery-item">
        <img
          src="{{ _item.image }}"
          alt="{{ _item.title | escape }}"
          class="img-responsive popup-image"
        >
      </div>
    {%- endif -%}
  {%- endfor -%}
</div>

<script>
  lightbox.option({
    'resizeDuration': 200,
    'wrapAround': true,
    'showImageNumberLabel': true
  });
</script>