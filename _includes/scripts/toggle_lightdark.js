document.addEventListener('DOMContentLoaded', function () {
  var base = window.location.origin;
  var LIGHT_HREF = base + '/assets/css/main.css';
  var DARK_HREF  = base + '/assets/css/dark.css';

  var toggles = [
    { btn: document.getElementById('theme-toggle'),        icon: document.getElementById('theme-icon') },
    { btn: document.getElementById('theme-toggle-mobile'), icon: document.getElementById('theme-icon-mobile') }
  ];
  var link = document.getElementById('theme-stylesheet');

  var current = localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  syncIcons(current);

  toggles.forEach(function (t) {
    if (!t.btn) return;
    t.btn.addEventListener('click', function () {
      var next = localStorage.getItem('theme') === 'dark' ? 'light' : 'dark';
      localStorage.setItem('theme', next);
      if (link) link.href = next === 'dark' ? DARK_HREF : LIGHT_HREF;
      syncIcons(next);
    });
  });

  function syncIcons(theme) {
    toggles.forEach(function (t) {
      if (t.icon) t.icon.className = theme === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
    });
  }
});