---
layout: page
title: Lab
show_title: false
---

{%- assign _articles = site.lab | reverse -%}

<div class="mt-4"></div>

{%- include lab-list.html
    articles=_articles
    type='grid'
    size='md'
    show_excerpt=true
    show_readmore=true
    show_info=true
-%}