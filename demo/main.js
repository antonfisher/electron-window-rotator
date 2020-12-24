// Demo application for electron-window-rotator module.

const {app, BrowserWindow, ipcMain} = require('electron');
const path = require('path');
const rotator = require('../');

function createWindow() {
  // create the browser window
  const mainWindow = new BrowserWindow({
    width: 400,
    height: 300,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js')
    }
  });

  // load the index.html of the app
  mainWindow.loadFile('index.html');

  // "Rotate" button handler
  ipcMain.on('rotate', (event, duration) => {
    mainWindow.webContents.capturePage().then((img) => {
      const d = Math.min(Number.MAX_SAFE_INTEGER, Math.max(1, duration || 1));
      // call with native window handle and webview screenshot
      rotator.rotate(mainWindow.getNativeWindowHandle(), img.toPNG(), d);
    });
  });
}

app.whenReady().then(() => createWindow());
app.on('window-all-closed', () => app.quit());
