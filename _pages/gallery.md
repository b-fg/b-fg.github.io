---
layout: articles
permalink: /gallery
title: Gallery
show_title: false
lightbox: true
---

<div class="mt-2"></div>

{%- assign _articles = site.gallery | reverse -%}
<div class="gallery-grid">
  {%- for _item in _articles -%}
    {%- if _item.image -%}
      {%- capture _title_html -%}{{ _item.title | markdownify | remove: '<p>' | remove: '</p>' | strip }}{%- endcapture -%}
      {%- assign _thumb = _item.thumb | default: _item.image -%}
<div class="gallery-item" data-title="{{ _title_html | escape }}">
<img
src="{{ _thumb | relative_url }}"
data-full-src="{{ _item.full | default: _item.image | relative_url }}"
{% if _item.video %}data-video="{{ _item.video }}"{% endif %}
alt="{{ _item.title | default: '' | escape }}"
title="{{ _item.title | default: '' | escape }}"
class="img-responsive popup-image"
loading="lazy"
decoding="async"
>
{%- assign _ext = _item.image | split: '.' | last | downcase -%}
{%- if _item.video or _ext == 'gif' %}<div class="gallery-item__play fas fa-play"></div>{% endif -%}
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