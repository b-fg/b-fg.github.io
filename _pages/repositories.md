---
layout: article
titles:
  # @start locale config
  en      : &EN       Repositories
  en-GB   : *EN
  en-US   : *EN
  en-CA   : *EN
  en-AU   : *EN
  # @end locale config
show_title: false
---

<!-- {% if site.data.repositories.github_users %}
<div class="repo-card">
  {% for user in site.data.repositories.github_users %}
    {% include repository/repo_user.liquid username=user %}
  {% endfor %}
</div>
{% endif %} -->

{% if site.data.repositories.github_repos %}
<div class="repo-card" style="margin-top:1rem">
  {% for repo in site.data.repositories.github_repos %}
    {% include repository/repo.liquid repository=repo %}
  {% endfor %}
</div>
{% endif %}

