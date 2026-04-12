const express = require('express');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT || 3000);
const DATA_FILE = process.env.PHONECALL_DATA_FILE || path.join(__dirname, '..', 'data', 'store.json');
const DEFAULT_DEVICE_PREFIX = 'PhoneCall device';

const app = express();
app.disable('x-powered-by');
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: false }));

let store = loadStore();

app.get('/health', (_request, response) => {
  response.json({ ok: true });
});

app.get('/api/devices', (_request, response) => {
  response.json({ devices: listDevices() });
});

app.get('/api/devices/:deviceId', (request, response) => {
  const device = getDevice(request.params.deviceId);
  if (!device) {
    response.status(404).json({ error: 'Device not found' });
    return;
  }

  response.json(withDeviceStats(device));
});

app.put('/api/devices/:deviceId', (request, response) => {
  const device = upsertDevice(request.params.deviceId, request.body || {}, true);
  response.json(withDeviceStats(device));
});

app.patch('/api/devices/:deviceId', (request, response) => {
  const device = upsertDevice(request.params.deviceId, request.body || {}, false);
  if (!device) {
    response.status(404).json({ error: 'Device not found' });
    return;
  }
  response.json(withDeviceStats(device));
});

app.post('/api/devices/:deviceId/register', (request, response) => {
  const device = upsertDevice(request.params.deviceId, request.body || {}, true);
  response.json(withDeviceStats(device));
});

app.post('/api/devices/:deviceId/call-logs', (request, response) => {
  const deviceId = request.params.deviceId;
  const body = request.body || {};
  const logs = Array.isArray(body.logs) ? body.logs : [];

  const normalizedLogs = logs
    .map((entry) => normalizeLogEntry(deviceId, entry))
    .filter(Boolean);

  const device = touchDevice(deviceId);
  for (const log of normalizedLogs) {
    upsertCallLog(deviceId, log);
  }
  saveStore();

  response.json({
    device: withDeviceStats(device),
    storedLogs: normalizedLogs.length,
  });
});

app.get('/api/devices/:deviceId/call-logs', (request, response) => {
  const deviceId = request.params.deviceId;
  const logs = getCallLogsForDevice(deviceId);
  response.json({ deviceId, logs });
});

app.get('/', (_request, response) => {
  response.redirect('/admin');
});

app.get('/admin', (_request, response) => {
  response.type('html').send(renderAdminPage());
});

app.post('/admin/devices/:deviceId/name', (request, response) => {
  const device = upsertDevice(
    request.params.deviceId,
    { deviceName: request.body.deviceName || '' },
    false,
  );
  if (!device) {
    response.status(404).send('Device not found');
    return;
  }
  saveStore();
  response.redirect('/admin');
});

app.use((error, _request, response, _next) => {
  console.error(error);
  response.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  ensureDataDirectory();
  console.log(`PhoneCall server listening on port ${PORT}`);
});

function loadStore() {
  try {
    if (!fs.existsSync(DATA_FILE)) {
      return { devices: [], callLogs: [] };
    }

    const raw = fs.readFileSync(DATA_FILE, 'utf8');
    const parsed = JSON.parse(raw);
    return {
      devices: Array.isArray(parsed.devices) ? parsed.devices : [],
      callLogs: Array.isArray(parsed.callLogs) ? parsed.callLogs : [],
    };
  } catch (error) {
    console.error('Failed to load store, starting fresh:', error);
    return { devices: [], callLogs: [] };
  }
}

function saveStore() {
  ensureDataDirectory();
  fs.writeFileSync(DATA_FILE, `${JSON.stringify(store, null, 2)}\n`, 'utf8');
}

function ensureDataDirectory() {
  fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });
}

function listDevices() {
  return [...store.devices]
    .sort((left, right) => compareDates(right.updatedAt, left.updatedAt))
    .map(withDeviceStats);
}

function getDevice(deviceId) {
  return store.devices.find((device) => device.deviceId === deviceId) || null;
}

function touchDevice(deviceId) {
  const device = getDevice(deviceId);
  if (!device) {
    return upsertDevice(deviceId, {}, true);
  }

  device.lastSeenAt = new Date().toISOString();
  device.updatedAt = device.lastSeenAt;
  return device;
}

function upsertDevice(deviceId, body, allowCreate) {
  const normalizedDeviceId = String(deviceId || '').trim();
  if (!normalizedDeviceId) {
    throw new Error('deviceId is required');
  }

  let device = getDevice(normalizedDeviceId);
  if (!device) {
    if (!allowCreate) {
      return null;
    }

    const now = new Date().toISOString();
    device = {
      deviceId: normalizedDeviceId,
      deviceName: '',
      createdAt: now,
      updatedAt: now,
      lastSeenAt: now,
      platform: '',
      appVersion: '',
    };
    store.devices.push(device);
  }

  if (typeof body.deviceName === 'string' && body.deviceName.trim()) {
    device.deviceName = body.deviceName.trim();
  } else if (!device.deviceName) {
    device.deviceName = makeDefaultDeviceName(normalizedDeviceId);
  }

  if (typeof body.platform === 'string' && body.platform.trim()) {
    device.platform = body.platform.trim();
  }

  if (typeof body.appVersion === 'string' && body.appVersion.trim()) {
    device.appVersion = body.appVersion.trim();
  }

  const now = new Date().toISOString();
  device.updatedAt = now;
  device.lastSeenAt = now;
  saveStore();
  return device;
}

function withDeviceStats(device) {
  if (!device) {
    return null;
  }

  const logs = getCallLogsForDevice(device.deviceId);
  return {
    ...device,
    callLogCount: logs.length,
    missedCallCount: logs.filter((log) => log.type === 'missed').length,
    latestCallAt: logs[0]?.timestampMillis ?? null,
  };
}

function getCallLogsForDevice(deviceId) {
  return store.callLogs
    .filter((log) => log.deviceId === deviceId)
    .sort((left, right) => (right.timestampMillis || 0) - (left.timestampMillis || 0));
}

function upsertCallLog(deviceId, log) {
  const existingIndex = store.callLogs.findIndex(
    (entry) => entry.deviceId === deviceId && entry.id === log.id,
  );

  const record = {
    ...log,
    deviceId,
    syncedAt: new Date().toISOString(),
  };

  if (existingIndex >= 0) {
    store.callLogs[existingIndex] = record;
  } else {
    store.callLogs.push(record);
  }
}

function normalizeLogEntry(deviceId, entry) {
  if (!entry || typeof entry !== 'object') {
    return null;
  }

  const id = normalizeString(entry.id);
  if (!id) {
    return null;
  }

  return {
    id,
    number: normalizeString(entry.number),
    displayName: normalizeString(entry.displayName),
    photoUri: normalizeString(entry.photoUri),
    contactId: normalizeString(entry.contactId),
    timestampMillis: normalizeInteger(entry.timestampMillis),
    durationSeconds: normalizeInteger(entry.durationSeconds),
    type: normalizeString(entry.type),
    accountId: normalizeString(entry.accountId),
    occurrences: normalizeInteger(entry.occurrences),
    deviceId,
  };
}

function renderAdminPage() {
  const devices = listDevices();
  const totalLogs = store.callLogs.length;
  const body = devices
    .map((device) => {
      const logs = getCallLogsForDevice(device.deviceId).slice(0, 8);
      const logRows =
        logs.length === 0
          ? '<tr><td colspan="4" class="muted">No logs yet</td></tr>'
          : logs
              .map(
                (log) => `
                  <tr>
                    <td>${escapeHtml(formatTimestamp(log.timestampMillis))}</td>
                    <td>${escapeHtml(log.displayName || log.number || 'Unknown')}</td>
                    <td>${escapeHtml(log.type || 'unknown')}</td>
                    <td>${escapeHtml(String(log.durationSeconds || 0))}s</td>
                  </tr>
                `,
              )
              .join('');

      return `
        <section class="device">
          <div class="device__head">
            <div>
              <h2>${escapeHtml(device.deviceName || makeDefaultDeviceName(device.deviceId))}</h2>
              <p>${escapeHtml(device.deviceId)}</p>
            </div>
            <form method="post" action="/admin/devices/${encodeURIComponent(device.deviceId)}/name" class="rename-form">
              <input name="deviceName" value="${escapeAttr(device.deviceName || '')}" placeholder="Device name" />
              <button type="submit">Save name</button>
            </form>
          </div>
          <div class="meta">
            <span>Last seen: ${escapeHtml(formatIso(device.lastSeenAt))}</span>
            <span>Calls: ${device.callLogCount}</span>
            <span>Missed: ${device.missedCallCount}</span>
            <span>Version: ${escapeHtml(device.appVersion || 'unknown')}</span>
          </div>
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Caller</th>
                  <th>Type</th>
                  <th>Duration</th>
                </tr>
              </thead>
              <tbody>${logRows}</tbody>
            </table>
          </div>
        </section>
      `;
    })
    .join('');

  return `<!doctype html>
  <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>PhoneCall Server</title>
      <style>
        :root {
          color-scheme: light;
          --bg: #0f172a;
          --panel: #111827;
          --card: #ffffff;
          --muted: #64748b;
          --border: #dbe4f0;
          --accent: #2563eb;
        }
        body {
          margin: 0;
          font-family: Inter, Segoe UI, Arial, sans-serif;
          background: linear-gradient(180deg, #eff6ff 0%, #f8fafc 36%, #ffffff 100%);
          color: #0f172a;
        }
        .container { max-width: 1180px; margin: 0 auto; padding: 32px 20px 56px; }
        .hero {
          background: rgba(255,255,255,0.86);
          border: 1px solid var(--border);
          border-radius: 24px;
          padding: 24px;
          box-shadow: 0 20px 60px rgba(15, 23, 42, 0.06);
          backdrop-filter: blur(10px);
        }
        h1 { margin: 0 0 8px; font-size: 34px; }
        .hero p { margin: 0; color: var(--muted); line-height: 1.55; }
        .stats { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 18px; }
        .stat {
          background: white;
          border: 1px solid var(--border);
          border-radius: 16px;
          padding: 12px 14px;
          min-width: 150px;
        }
        .stat strong { display: block; font-size: 18px; margin-bottom: 4px; }
        .device {
          margin-top: 22px;
          background: rgba(255,255,255,0.92);
          border: 1px solid var(--border);
          border-radius: 24px;
          padding: 20px;
          box-shadow: 0 14px 40px rgba(15, 23, 42, 0.05);
        }
        .device__head {
          display: flex;
          justify-content: space-between;
          gap: 16px;
          align-items: flex-start;
          flex-wrap: wrap;
        }
        h2 { margin: 0 0 6px; font-size: 24px; }
        .device p { margin: 0; color: var(--muted); word-break: break-all; }
        .meta { display: flex; gap: 12px; flex-wrap: wrap; margin: 16px 0 0; color: var(--muted); }
        .meta span {
          background: #f8fafc;
          border: 1px solid var(--border);
          border-radius: 999px;
          padding: 8px 12px;
        }
        .rename-form { display: flex; gap: 8px; flex-wrap: wrap; }
        .rename-form input {
          min-width: 240px;
          padding: 12px 14px;
          border-radius: 14px;
          border: 1px solid var(--border);
          font: inherit;
        }
        .rename-form button {
          border: none;
          border-radius: 14px;
          padding: 12px 16px;
          background: var(--accent);
          color: white;
          font: inherit;
          font-weight: 700;
          cursor: pointer;
        }
        .table-wrap { overflow-x: auto; margin-top: 16px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 12px 10px; border-bottom: 1px solid #e5edf6; white-space: nowrap; }
        th { font-size: 12px; letter-spacing: 0.04em; text-transform: uppercase; color: var(--muted); }
        .muted { color: var(--muted); }
        .footer { margin-top: 20px; color: var(--muted); font-size: 14px; }
      </style>
    </head>
    <body>
      <div class="container">
        <section class="hero">
          <h1>PhoneCall Server</h1>
          <p>Devices sync their call logs here by device ID. Rename any device below and the app will pick up the updated name on the next profile refresh.</p>
          <div class="stats">
            <div class="stat"><strong>${devices.length}</strong><span>Devices</span></div>
            <div class="stat"><strong>${totalLogs}</strong><span>Call logs</span></div>
          </div>
        </section>
        ${body || '<section class="device"><p class="muted">No devices have synced yet.</p></section>'}
        <div class="footer">API base: <code>/api/devices/:deviceId</code></div>
      </div>
    </body>
  </html>`;
}

function makeDefaultDeviceName(deviceId) {
  const suffix = String(deviceId).replace(/[^a-zA-Z0-9]/g, '').slice(0, 6).toUpperCase();
  return suffix ? `${DEFAULT_DEVICE_PREFIX} ${suffix}` : DEFAULT_DEVICE_PREFIX;
}

function normalizeString(value) {
  if (typeof value !== 'string') {
    return '';
  }
  return value.trim();
}

function normalizeInteger(value) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

function compareDates(left, right) {
  return new Date(left || 0).getTime() - new Date(right || 0).getTime();
}

function formatIso(value) {
  if (!value) {
    return 'unknown';
  }
  return new Date(value).toLocaleString();
}

function formatTimestamp(value) {
  if (!value) {
    return 'Unknown';
  }
  return new Date(value).toLocaleString();
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function escapeAttr(value) {
  return escapeHtml(value).replaceAll('\n', ' ');
}
