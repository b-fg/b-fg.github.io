document.addEventListener('DOMContentLoaded', function () {
  var base = window.location.origin;
  var LIGHT_HREF = base + '/assets/css/main.css';
  var DARK_HREF  = base + '/assets/css/dark.css';

  var btn  = document.getElementById('theme-toggle');
  var icon = document.getElementById('theme-icon');
  var link = document.getElementById('theme-stylesheet');

  var current = localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  syncIcon(current);

  if (btn) {
    btn.addEventListener('click', function () {
      var next = localStorage.getItem('theme') === 'dark' ? 'light' : 'dark';
      localStorage.setItem('theme', next);
      if (link) link.href = next === 'dark' ? DARK_HREF : LIGHT_HREF;
      syncIcon(next);
    });
  }

  function syncRepoCards(theme) {
    var cardTheme = theme === 'dark' ? 'dark' : 'default';
    document.querySelectorAll('img.repo-card').forEach(function(img) {
      img.src = img.src.replace(/&theme=\w+/, '&theme=' + cardTheme);
    });
  }

  function syncIcon(theme) {
    if (icon) icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
    var logo = document.getElementById('site-logo');
    if (logo) logo.src = theme === 'dark'
      ? '/assets/images/logo/tudelft-dark.svg'
      : '/assets/images/logo/tudelft.svg';
    syncRepoCards(theme);
  }
});