document.addEventListener('DOMContentLoaded', function () {
  var toggle = document.getElementById('theme-toggle');
  var lightLink = document.getElementById('theme-light');
  var darkLink  = document.getElementById('theme-dark');

  var current = localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  applyTheme(current);

  if (toggle) {
    toggle.addEventListener('change', function () {
      var next = toggle.checked ? 'dark' : 'light';
      localStorage.setItem('theme', next);
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

  function swapStylesheets(theme) {
    var on  = theme === 'dark' ? darkLink : lightLink;
    var off = theme === 'dark' ? lightLink : darkLink;
    if (!on || !off) { return; }
    var disableOld = function () {
      // Re-check before disabling: a quick toggle back while the incoming
      // sheet was downloading would otherwise turn off the active sheet.
      var active = document.documentElement.dataset.theme === 'dark' ? darkLink : lightLink;
      if (off !== active) { off.media = 'not all'; }
    };
    on.media = 'all';
    if (on.sheet) {
      // Already loaded (normal case): the swap is atomic.
      disableOld();
    } else {
      // Still downloading: keep the old theme applied until the new sheet
      // is ready — a delayed switch, never an unstyled page.
      on.addEventListener('load', disableOld, { once: true });
    }
  }

  function applyTheme(theme) {
    document.documentElement.dataset.theme = theme;
    if (toggle) toggle.checked = theme === 'dark';
    swapStylesheets(theme);
    syncRepoCards(theme);
  }
});
