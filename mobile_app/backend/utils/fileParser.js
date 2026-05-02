const fs = require('fs');
const path = require('path');
const csvParser = require('csv-parser');
const XLSX = require('xlsx');

const toCellText = (value) => {
  if (value === null || value === undefined) return '';
  return String(value).trim();
};

const looksLikeHeader = (row) => {
  const joined = row.map(toCellText).join(' ').toLowerCase();
  return joined.includes('name') && (
    joined.includes('phone') ||
    joined.includes('mobile') ||
    joined.includes('contact')
  );
};

const looksLikeSerial = (value) => /^\d+$/.test(toCellText(value));

const normalizeRows = (rawRows) => {
  const rows = rawRows
    .map(row => Array.isArray(row) ? row.map(toCellText) : Object.values(row).map(toCellText))
    .filter(row => row.some(Boolean));

  if (rows.length === 0) {
    throw new Error('File is empty or could not be parsed.');
  }

  const startIndex = looksLikeHeader(rows[0]) ? 1 : 0;
  const leads = [];

  for (let i = startIndex; i < rows.length; i += 1) {
    const row = rows[i];
    if (row.length < 2) continue;

    const hasSerialColumn = row.length >= 3 && looksLikeSerial(row[0]);
    const name = hasSerialColumn ? row[1] : row[0];
    const phone = hasSerialColumn ? row[2] : row[1];

    if (name && phone) {
      leads.push({ name, phone });
    }
  }

  if (leads.length === 0) {
    throw new Error('No valid lead data found in file. Expected columns: Name, Phone Number.');
  }

  return leads;
};

const parseCsv = (filePath) => new Promise((resolve, reject) => {
  const rows = [];

  fs.createReadStream(filePath)
    .pipe(csvParser({ headers: false, skipComments: true }))
    .on('data', row => rows.push(Object.values(row)))
    .on('end', () => {
      try {
        resolve(normalizeRows(rows));
      } catch (error) {
        reject(error);
      }
    })
    .on('error', reject);
});

const parseExcel = (filePath) => {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });
  return normalizeRows(rows);
};

const parseLeadFile = async (filePath) => {
  const ext = path.extname(filePath).toLowerCase();

  if (ext === '.csv') {
    return parseCsv(filePath);
  }

  if (ext === '.xlsx' || ext === '.xls') {
    return parseExcel(filePath);
  }

  // Unknown extension — detect by file content (Google Drive / Sheets files)
  try {
    const buffer = Buffer.alloc(4);
    const fd = fs.openSync(filePath, 'r');
    fs.readSync(fd, buffer, 0, 4, 0);
    fs.closeSync(fd);

    // XLSX files are ZIP archives starting with PK (0x50 0x4B)
    if (buffer[0] === 0x50 && buffer[1] === 0x4B) {
      return parseExcel(filePath);
    }

    // Otherwise try as CSV (plain text)
    return parseCsv(filePath);
  } catch (err) {
    // Last resort: try Excel then CSV
    try {
      return parseExcel(filePath);
    } catch {
      return parseCsv(filePath);
    }
  }
};

module.exports = { parseLeadFile, normalizeRows };
