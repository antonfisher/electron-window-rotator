const NativeExtension = require('bindings')('NativeExtension');

module.exports = {
  rotate: (windowHandle, imageHandle) => {
    if (process.platform !== 'darwin') {
      throw new Error('electron-window-rotator: platform not supported');
    }
    NativeExtension.rotate(windowHandle, imageHandle);
  }
};
