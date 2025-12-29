---
layout: page
title: Gallery
show_title: false
---

{%- assign _articles = site.gallery | reverse -%}

{%- include gallery-list.html
    articles=_articles
    type='grid'
    size='md'
-%}