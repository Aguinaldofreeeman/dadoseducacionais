/* theme.js — alternador de tema compartilhado.
   Padrão: claro. A escolha do usuário é persistida em localStorage.theme.
   O script inline no <head> aplica a preferência antes do primeiro paint. */
(function () {
  'use strict';

  var KEY = 'theme';
  var root = document.documentElement;

  function current() {
    return root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
  }

  function syncButton() {
    var button = document.getElementById('btnTheme');
    if (!button) return;
    var dark = current() === 'dark';
    var label = dark ? 'Ativar tema claro' : 'Ativar tema escuro';
    button.setAttribute('aria-pressed', String(dark));
    button.setAttribute('aria-label', label);
    button.title = label;
  }

  function setTheme(theme, persist) {
    var next = theme === 'dark' ? 'dark' : 'light';
    root.setAttribute('data-theme', next);
    if (persist) {
      try { localStorage.setItem(KEY, next); } catch (e) { /* armazenamento indisponível */ }
    }
    syncButton();
    document.dispatchEvent(new CustomEvent('themechange', { detail: { theme: next } }));
  }

  document.addEventListener('DOMContentLoaded', function () {
    syncButton();
    var button = document.getElementById('btnTheme');
    if (button) {
      button.addEventListener('click', function () {
        setTheme(current() === 'dark' ? 'light' : 'dark', true);
      });
    }
  });

  window.Theme = { get: current, set: setTheme };
})();
