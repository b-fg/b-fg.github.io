---
layout: article
title: b-fg
show_title: false
---

<style>
  .container {
    position: absolute;
    top: 50%;
    left: 50%;
    -moz-transform: translateX(-50%) translateY(-60%);
    -webkit-transform: translateX(-50%) translateY(-60%);
    transform: translateX(-50%) translateY(-60%);
}
</style>

{%- include bio.html -%}

{%- include news.html news_limit=site.news_limit-%}

{%- include cv_and_contact.html -%}
