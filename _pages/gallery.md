---
layout: articles
permalink: /gallery
title: Gallery
show_title: false
lightbox: true
---

{%- assign _articles = site.gallery | reverse -%}
<div class="gallery-grid">
  {%- for _item in _articles -%}
    {%- if _item.image -%}
      {%- capture _title_html -%}{{ _item.title | markdownify | remove: '<p>' | remove: '</p>' | strip }}{%- endcapture -%}
<div class="gallery-item" data-title="{{ _title_html | escape }}">
<img
src="{{ _item.image }}"
alt="{{ _item.title | default: '' | escape }}"
title="{{ _item.title | default: '' | escape }}"
class="img-responsive popup-image"
>
</div>
    {%- endif -%}
  {%- endfor -%}
</div>

<script>
if (typeof lightbox !== 'undefined') {
    lightbox.option({
'resizeDuration': 200,
'wrapAround': true,
'showImageNumberLabel': true
    });
  }
</script>