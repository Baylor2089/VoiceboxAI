const { app, BrowserWindow, ipcMain, shell, Menu } = require('electron');
const path = require('path');
const Store = require('electron-store');

const store = new Store({
  name: 'settings',
  defaults: {
    apiKey: '',
    model: 'gemini-2.5-flash-lite',
    temperature: 0.3
  }
});

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 720,
    height: 520,
    alwaysOnTop: true,
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 12, y: 12 },
    backgroundColor: '#00000000',
    transparent: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));

  const template = [
    {
      label: app.name,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    },
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
        { role: 'selectAll' }
      ]
    }
  ];
  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('settings:get', () => {
  return {
    apiKey: store.get('apiKey'),
    model: store.get('model'),
    temperature: store.get('temperature')
  };
});

ipcMain.handle('settings:save', (event, payload) => {
  const { apiKey, model, temperature } = payload;
  if (typeof apiKey === 'string') store.set('apiKey', apiKey);
  if (typeof model === 'string' && model.length > 0) store.set('model', model);
  if (typeof temperature === 'number') store.set('temperature', temperature);
  return { ok: true };
});

ipcMain.handle('gemini:rewrite', async (event, payload) => {
  const { input } = payload || {};
  const apiKey = store.get('apiKey');
  const model = store.get('model');
  const temperature = store.get('temperature');

  if (!apiKey || !String(apiKey).trim()) {
    throw new Error('请先在设置中填写 Google Gemini API Key');
  }
  const text = String(input || '').trim();
  if (!text) return '';

  const systemPrompt = `あなたは熟練の日本語コミュニケーションアシスタントです。以下の指示に厳密に従って、入力内容を「職場の Slack にそのまま投稿できる自然な日本語」に整えてください。\n\nルール：\n- 口調：丁寧すぎず、くだけすぎず。親しみやすく、プロフェッショナル。\n- 文体：簡潔・自然・読みやすい。過剰な敬語や硬さを避ける。\n- 意図：元の意味・重要情報・ニュアンスを正確に保持。\n- 混在入力：英語・中国語・和訳済みの混在を許容し、必要に応じ自然な日本語に統一。\n- Slack：箇条書き・コード・URL などは壊さず保持。顔文字や絵文字は控えめに。\n- 過度な言い換えは禁止。襟を正すほどではないが失礼にならない距離感。\n- すでに日本語の場合は、自然さ・簡潔さ・仕事場向けの調整のみ行い大きく変えない。\n\n返答は日本語のみ。前置き・説明・「以下です」等は不要。必要に応じて適切に段落・箇条書きを使ってよい。`;

  const body = {
    systemInstruction: { role: 'system', parts: [{ text: systemPrompt }] },
    contents: [{ role: 'user', parts: [{ text }] }],
    generationConfig: { temperature: Number(temperature) || 0.3, topK: 50, topP: 0.95 }
  };

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });

  const data = await res.json();
  if (!res.ok) {
    const msg = data?.error?.message || `HTTP ${res.status}`;
    throw new Error(msg);
  }
  const textOut = data?.candidates?.[0]?.content?.parts?.map(p => p.text).filter(Boolean).join('') || '';
  if (!textOut) throw new Error('未返回有效文本');
  return textOut;
});

