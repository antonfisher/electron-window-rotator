const {ipcRenderer} = require('electron');

// All of the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.
window.addEventListener('DOMContentLoaded', () => {
  const replaceText = (selector, text) => {
    const element = document.getElementById(selector);
    if (element) element.innerText = text;
  };

  for (const type of ['chrome', 'node', 'electron']) {
    replaceText(`${type}-version`, process.versions[type]);
  }

  document.getElementById('rotate').addEventListener('click', () => {
    const duration = document.getElementById('duration').value;
    const direction = document.getElementById('direction').value;
    ipcRenderer.send('rotate', duration, direction);
  });
});
