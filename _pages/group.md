---
layout: page
title: Group
show_title: false
---

{%- assign _articles = site.group | reverse -%}

<div class="mt-4"></div>

{%- include group-list.html
    articles=_articles
    type='grid'
    size='md'
    show_excerpt=true
    show_readmore=true
    show_info=true
-%}