document.addEventListener('DOMContentLoaded', function () {
  var base = window.location.origin;
  var LIGHT_HREF = base + '/assets/css/main.css';
  var DARK_HREF  = base + '/assets/css/dark.css';
  var toggle = document.getElementById('theme-toggle');
  var link   = document.getElementById('theme-stylesheet');

  var current = localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  applyTheme(current);

  if (toggle) {
    toggle.addEventListener('change', function () {
      var next = toggle.checked ? 'dark' : 'light';
      localStorage.setItem('theme', next);
      if (link) link.href = next === 'dark' ? DARK_HREF : LIGHT_HREF;
      applyTheme(next);
    });
  }

  var darkMQ = window.matchMedia('(prefers-color-scheme: dark)');
  function handleMQChange(e) {
    if (!localStorage.getItem('theme')) {
      applyTheme(e.matches ? 'dark' : 'light');
    }
  }
  if (darkMQ.addEventListener) {
    darkMQ.addEventListener('change', handleMQChange);
  } else if (darkMQ.addListener) {
    darkMQ.addListener(handleMQChange);
  }

  function syncRepoCards(theme) {
    var cardTheme = theme === 'dark' ? 'dark' : 'default';
    document.querySelectorAll('img.repo-card').forEach(function (img) {
      img.src = img.src.replace(/&theme=\w+/, '&theme=' + cardTheme);
    });
  }

  function applyTheme(theme) {
    document.documentElement.dataset.theme = theme;
    if (toggle) toggle.checked = theme === 'dark';
    if (link) link.href = theme === 'dark' ? DARK_HREF : LIGHT_HREF;
    syncRepoCards(theme);
  }
});