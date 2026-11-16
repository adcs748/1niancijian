const express = require('express');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT || 8787);
const TOKEN = process.env.TOKEN || '';
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');

if (!TOKEN) {
  console.error('缺少 TOKEN 环境变量。示例：TOKEN=change-me npm start');
  process.exit(1);
}

fs.mkdirSync(DATA_DIR, { recursive: true });

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  if (header !== `Bearer ${TOKEN}`) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  next();
}

function safeBatchId(value) {
  const cleaned = String(value || '').replace(/[^A-Za-z0-9_-]/g, '').slice(0, 64);
  return cleaned || 'batch';
}

function safeFileName(value) {
  const base = path.basename(String(value || 'file'));
  const cleaned = base.replace(/[^\w.\-()\u4e00-\u9fa5 ]/g, '_').slice(0, 140);
  return cleaned || 'file';
}

function batchDir(batchId) {
  return path.join(DATA_DIR, batchId);
}

function manifestPath(batchId) {
  return path.join(batchDir(batchId), 'manifest.json');
}

function readManifest(batchId) {
  try {
    return JSON.parse(fs.readFileSync(manifestPath(batchId), 'utf8'));
  } catch (error) {
    return [];
  }
}

function writeManifest(batchId, items) {
  fs.mkdirSync(batchDir(batchId), { recursive: true });
  fs.writeFileSync(manifestPath(batchId), JSON.stringify(items, null, 2), 'utf8');
}

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 200 * 1024 * 1024 }
});

app.post('/api/backups/:batchId/files', auth, upload.single('file'), (req, res) => {
  const batchId = safeBatchId(req.params.batchId);
  if (!req.file) {
    return res.status(400).json({ error: 'file required' });
  }

  const name = safeFileName(req.file.originalname);
  const target = path.join(batchDir(batchId), name);
  fs.mkdirSync(batchDir(batchId), { recursive: true });
  fs.writeFileSync(target, req.file.buffer);

  const manifest = readManifest(batchId);
  manifest.push({
    name,
    size: req.file.size,
    mime: req.file.mimetype || 'application/octet-stream',
    uploadedAt: new Date().toISOString()
  });
  writeManifest(batchId, manifest);

  res.json({ ok: true, batchId, name, size: req.file.size });
});

app.get('/api/backups', auth, (req, res) => {
  const items = [];
  for (const name of fs.readdirSync(DATA_DIR)) {
    const dir = path.join(DATA_DIR, name);
    let stat;
    try {
      stat = fs.statSync(dir);
    } catch (error) {
      continue;
    }
    if (!stat.isDirectory()) continue;

    const manifest = readManifest(name);
    const totalBytes = manifest.reduce((sum, file) => sum + Number(file.size || 0), 0);
    items.push({
      id: name,
      fileCount: manifest.length,
      totalBytes,
      updatedAt: stat.mtime.toISOString()
    });
  }

  items.sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
  res.json(items);
});

app.get('/api/backups/:batchId', auth, (req, res) => {
  const batchId = safeBatchId(req.params.batchId);
  res.json({ id: batchId, files: readManifest(batchId) });
});

app.get('/api/backups/:batchId/files/:name', auth, (req, res) => {
  const batchId = safeBatchId(req.params.batchId);
  const name = safeFileName(req.params.name);
  const target = path.join(batchDir(batchId), name);
  if (!fs.existsSync(target)) {
    return res.status(404).json({ error: 'not found' });
  }
  res.sendFile(target);
});

app.get('/', (req, res) => {
  res.json({ ok: true, service: '一念词间备份服务', dataDir: DATA_DIR });
});

app.listen(PORT, () => {
  console.log(`一念词间备份服务已启动: http://localhost:${PORT}`);
  console.log(`数据目录: ${DATA_DIR}`);
  console.log('请通过 HTTPS 反向代理对外提供服务，并妥善保管 TOKEN。');
});