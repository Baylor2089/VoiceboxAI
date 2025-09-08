const els = {
  settingsBtn: document.getElementById('settingsBtn'),
  settingsPanel: document.getElementById('settingsPanel'),
  apiKey: document.getElementById('apiKey'),
  model: document.getElementById('model'),
  temperature: document.getElementById('temperature'),
  tempVal: document.getElementById('tempVal'),
  saveSettings: document.getElementById('saveSettings'),
  input: document.getElementById('input'),
  run: document.getElementById('run'),
  clear: document.getElementById('clear'),
  copy: document.getElementById('copy'),
  result: document.getElementById('result'),
  error: document.getElementById('error')
};

els.settingsBtn.addEventListener('click', () => {
  els.settingsPanel.hidden = !els.settingsPanel.hidden;
});

els.temperature.addEventListener('input', () => {
  els.tempVal.textContent = Number(els.temperature.value).toFixed(2);
});

async function loadSettings() {
  const s = await window.api.getSettings();
  els.apiKey.value = s.apiKey || '';
  els.model.value = s.model || 'gemini-2.5-flash-lite';
  els.temperature.value = (s.temperature ?? 0.3);
  els.tempVal.textContent = Number(els.temperature.value).toFixed(2);
}

els.saveSettings.addEventListener('click', async () => {
  await window.api.saveSettings({
    apiKey: els.apiKey.value,
    model: els.model.value,
    temperature: Number(els.temperature.value)
  });
  showError('已保存', true);
});

function setBusy(b) {
  els.run.disabled = b;
}

function showError(msg, ok = false) {
  els.error.hidden = false;
  els.error.textContent = msg || '';
  els.error.style.color = ok ? 'var(--ok, #16a34a)' : '#ff453a';
  if (ok) setTimeout(() => { els.error.hidden = true; }, 1200);
}

els.run.addEventListener('click', async () => {
  setBusy(true);
  els.error.hidden = true;
  els.result.textContent = '';
  try {
    const input = els.input.value;
    const out = await window.api.rewrite(input);
    els.result.textContent = out;
  } catch (e) {
    showError(e?.message || String(e));
  } finally {
    setBusy(false);
  }
});

els.clear.addEventListener('click', () => {
  els.input.value = '';
});

els.copy.addEventListener('click', () => {
  const t = els.result.textContent || '';
  if (!t) return;
  window.api.copy(t);
  showError('已复制', true);
});

loadSettings();

