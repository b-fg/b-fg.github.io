---
layout: articles
permalink: /research
title: Research
show_title: false
---

{%- assign _sorted_list = site.research | reverse -%}
{%- if include.reverse -%}
{%- assign _sorted_list = _sorted_list | reverse -%}
{%- endif -%}

<div class="research-grid">
    {%- for _article in _sorted_list -%}
    {%- include snippets/prepend-baseurl.html path=_article.url -%}
    {%- assign _article_url = __return -%}
    {%- if _article.cover -%}
    {%- include snippets/get-nav-url.html path=_article.cover -%}
    {%- assign _article_cover = __return -%}
    {%- endif -%}
    <a href="{{ _article_url }}" class="research-item">
        {%- if _article.cover -%}
        <div class="research-item__image-wrapper">
            <img src="{{ _article_cover }}" alt="{{ _article.title | escape }}" />
        </div>
        {%- endif -%}
        <div class="research-item__content">
            <h2 class="research-item__title">
                {{ _article.title }}
            </h2>
            {%- if _article.date or _article.author -%}
            <div class="research-item__meta">
                {%- if _article.date -%}
                {{ _article.date | date: "%B %Y" }}
                {%- endif -%}
                {%- if _article.author and _article.date -%} • {%- endif -%}
                {%- if _article.author -%}
                {{ _article.author }}
                {%- endif -%}
            </div>
            {%- endif -%}
        </div>
    </a>
    {%- endfor -%}
</div>