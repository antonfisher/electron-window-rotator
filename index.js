const NativeExtension = require('bindings')('NativeExtension');

function rotate(electronWindow, duration = 1000, direction = 0) {
  return new Promise((resolve, reject) => {
    if (process.platform !== 'darwin') {
      reject(new Error('platform not supported'));
      return;
    }
    resolve();
  })
    .then(() => electronWindow.webContents.capturePage())
    .then((screenshot) => {
      //TODO: return promise from the native module
      NativeExtension.rotate(
        electronWindow.getNativeWindowHandle(),
        screenshot.toPNG(),
        duration,
        direction
      );
    })
    .catch((e) => {
      throw new Error(`electron-window-rotator: failed: ${e.stack || e}`);
    });
}

module.exports = {
  DIRECTION_LEFT: 0,
  DIRECTION_RIGHT: 1,
  rotate
};
