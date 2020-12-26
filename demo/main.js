// Demo application for electron-window-rotator module.

const {app, BrowserWindow, ipcMain} = require('electron');
const path = require('path');
const Rotator = require('../');

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

  // "Rotate" event handler
  ipcMain.on('rotate', async (event, duration, direction) => {
    duration = Math.min(Number.MAX_SAFE_INTEGER, Math.max(1, duration || 1));
    direction =
      direction === 'left' ? Rotator.DIRECTION_LEFT : Rotator.DIRECTION_RIGHT;

    try {
      await Rotator.rotate(mainWindow, duration, direction);
    } catch (e) {
      console.error('Failed to rotate windows:', e.stack || e);
    }
  });
}

app.whenReady().then(() => createWindow());
app.on('window-all-closed', () => app.quit());
