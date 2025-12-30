---
layout: page
permalink: /research
title: Research
show_title: false
---

{%- assign _articles = site.research | reverse -%}

{%- include research-list.html
    articles=_articles
    show_excerpt=true
-%}