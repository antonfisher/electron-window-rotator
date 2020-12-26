# electron-window-rotator

Rotate native Electron window on macOS.

[![npm](https://img.shields.io/npm/v/electron-window-rotator.svg?colorB=brightgreen)](https://www.npmjs.com/package/electron-window-rotator)
[![npm](https://img.shields.io/npm/dt/electron-window-rotator.svg?colorB=brightgreen)](https://www.npmjs.com/package/electron-window-rotator)
[![GitHub license](https://img.shields.io/github/license/antonfisher/electron-window-rotator.svg)](https://github.com/antonfisher/electron-window-rotator/blob/master/LICENSE)

![Demo gif](https://raw.githubusercontent.com/antonfisher/electron-window-rotator/docs/images/demo-1.0.0.gif)

>**Note:** this is a silly proof-of-concept npm module that demonstrates using Nodejs N-API.

## Run demo locally:

```shell
git clone https://github.com/antonfisher/electron-window-rotator.git
cd electron-window-rotator
npm install
cd demo && npm install && cd -
xcode-select --install
npm start
```

## Usage:

```shell
xcode-select --install
npm install electron-window-rotator
```

```js
const Rotator = require('electron-window-rotator');
const mainWindow = new BrowserWindow({ ... });

setInterval(() => {
  Rotator.rotate(
    mainWindow,             // Electron's BrowserWindow instance
    1000,                   // animation duration [ms]
    Rotator.DIRECTION_LEFT  // rotation direction
  );
}, 3000);
```
