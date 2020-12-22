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
  ipcMain.on('rotate', () => {
    mainWindow.webContents.capturePage().then((img) => {
      // call with native window handle and webview screenshot
      rotator.rotate(mainWindow.getNativeWindowHandle(), img.toPNG());
    });
  });
}

app.whenReady().then(() => createWindow());
app.on('window-all-closed', () => app.quit());
