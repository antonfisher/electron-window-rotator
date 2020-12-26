const NativeExtension = require('bindings')('NativeExtension');

async function rotate(electronWindow, duration = 1000, direction = 0) {
  try {
    if (process.platform !== 'darwin') {
      throw new Error('platform not supported');
    }

    const screenshot = await electronWindow.webContents.capturePage();

    //TODO: return promise from the native module to use `await`
    NativeExtension.rotate(
      electronWindow.getNativeWindowHandle(),
      screenshot.toPNG(),
      duration,
      direction
    );
  } catch (e) {
    throw new Error(`electron-window-rotator: failed: ${e.stack || e}`);
  }
}

module.exports = {
  DIRECTION_LEFT: 0,
  DIRECTION_RIGHT: 1,
  rotate
};
