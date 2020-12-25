const NativeExtension = require('bindings')('NativeExtension');

module.exports = {
  DIRECTION_LEFT: 0,
  DIRECTION_RIGHT: 1,
  rotate: (windowHandle, screenShotData, duration = 1000, direction = 0) => {
    if (process.platform !== 'darwin') {
      throw new Error('electron-window-rotator: platform not supported');
    }
    NativeExtension.rotate(windowHandle, screenShotData, duration, direction);
  }
};
