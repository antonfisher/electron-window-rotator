const NativeExtension = require('bindings')('NativeExtension');

module.exports = {
  rotate: (windowHandle, screenShotData, duration) => {
    if (process.platform !== 'darwin') {
      throw new Error('electron-window-rotator: platform not supported');
    }
    NativeExtension.rotate(windowHandle, screenShotData, duration);
  }
};
