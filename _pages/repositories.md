---
layout: page
permalink: /repositories/
title: Repositories
show_title: false
---
<!-- Bootstrap & MDB -->
<link rel="stylesheet" href="{{ '/assets/css/bootstrap.min.css' | relative_url | bust_file_cache }}">
<link
  rel="stylesheet"
  href="{{ site.third_party_libraries.mdb.url.css }}"
  integrity="{{ site.third_party_libraries.mdb.integrity.css }}"
  crossorigin="anonymous"
>

<div class="mt-3"></div>

{% if site.data.repositories.github_users %}


{% if site.data.repositories.github_users %}
<div class="repositories d-md-flex flex-wrap flex-md-row flex-column justify- align-items-center">
  {% for user in site.data.repositories.github_users %} {% include repository/repo_user.liquid username=user %} {% endfor %}
</div>
{% endif %}

<!-- ---

{% if site.repo_trophies.enabled %}
{% for user in site.data.repositories.github_users %}
{% if site.data.repositories.github_users.size > 1 %}

  <h4>{{ user }}</h4>
  {% endif %}
  <div class="repositories d-flex flex-wrap flex-md-row flex-column justify-content-between align-items-center">
  {% include repository/repo_trophies.liquid username=user %}
  </div>

---

{% endfor %}
{% endif %}
{% endif %}

{% if site.data.repositories.github_repos %} -->

<div class="repositories d-flex flex-wrap flex-md-row flex-column justify-content-between align-items-center">
  {% for repo in site.data.repositories.github_repos %}
    {% include repository/repo.liquid repository=repo %}
  {% endfor %}
</div>
{% endif %}
