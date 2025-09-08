const { contextBridge, ipcRenderer, clipboard } = require('electron');

contextBridge.exposeInMainWorld('api', {
  getSettings: () => ipcRenderer.invoke('settings:get'),
  saveSettings: (payload) => ipcRenderer.invoke('settings:save', payload),
  rewrite: (input) => ipcRenderer.invoke('gemini:rewrite', { input }),
  copy: (text) => clipboard.writeText(String(text || ''))
});

