// Shared, dependency-free helpers for the AETHER shell.
// Keep this file pure enough to import from singletons and components.

function isObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

function clone(v) {
  return JSON.parse(JSON.stringify(v));
}

// Deep merge where values from `override` win. Arrays are replaced, not concatenated,
// so configuration edits cannot accidentally duplicate list entries.
function deepMerge(base, override) {
  if (!isObject(base)) return clone(override);
  if (!isObject(override)) return override === undefined ? clone(base) : override;
  const out = clone(base);
  for (const key of Object.keys(override)) {
    if (isObject(out[key]) && isObject(override[key])) out[key] = deepMerge(out[key], override[key]);
    else out[key] = override[key];
  }
  return out;
}

function getPath(obj, path, fallback) {
  let cur = obj;
  for (const part of path.split(".")) {
    if (cur === null || cur === undefined || !(part in cur)) return fallback;
    cur = cur[part];
  }
  return cur === undefined ? fallback : cur;
}

// Returns a new object with `path` set. Never mutates the input.
function setPath(obj, path, value) {
  const copy = clone(obj || {});
  const parts = path.split(".");
  let cur = copy;
  for (let i = 0; i < parts.length - 1; i++) {
    const part = parts[i];
    if (!isObject(cur[part])) cur[part] = {};
    cur = cur[part];
  }
  cur[parts[parts.length - 1]] = value;
  return copy;
}

function clamp(v, lo, hi) {
  return Math.max(lo, Math.min(hi, v));
}

// Linear color mix; t=0 -> a, t=1 -> b.
function mix(a, b, t) {
  const x = clamp(t, 0, 1);
  return Qt.rgba(
    a.r + (b.r - a.r) * x,
    a.g + (b.g - a.g) * x,
    a.b + (b.b - a.b) * x,
    a.a + (b.a - a.a) * x,
  );
}

function alpha(c, a) {
  return Qt.rgba(c.r, c.g, c.b, a);
}

function luminance(c) {
  const f = (v) => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

// Readable foreground for a filled accent surface.
function onColor(c) {
  return luminance(c) > 0.42 ? Qt.rgba(0.06, 0.06, 0.09, 1) : Qt.rgba(0.98, 0.98, 1, 1);
}

function fileUrl(path) {
  if (!path) return "";
  if (path.indexOf("file://") === 0) return path;
  let p = path;
  if (p.indexOf("/") !== 0) p = "/" + p;
  // encodeURI keeps slashes readable while escaping spaces and unicode safely.
  return "file://" + encodeURI(p).replace(/#/g, "%23").replace(/\?/g, "%3F");
}

function hex(c) {
  function h(n) {
    const s = Math.round(clamp(n, 0, 1) * 255).toString(16);
    return s.length === 1 ? "0" + s : s;
  }
  return "#" + h(c.r) + h(c.g) + h(c.b);
}

// Score a fuzzy match. Higher is better; -1 means no match. Contiguous and word-start
// matches rank higher, which makes "aes" prefer "AETHER Settings" over unrelated hits.
function fuzzyScore(haystack, needle) {
  if (!needle) return 0;
  const h = String(haystack || "").toLowerCase();
  const n = String(needle || "").toLowerCase();
  let hi = 0;
  let score = 0;
  let streak = 0;
  for (let i = 0; i < n.length; i++) {
    const idx = h.indexOf(n[i], hi);
    if (idx === -1) return -1;
    streak = idx === hi ? streak + 1 : 0;
    score += 10 + streak * 4;
    if (idx === 0 || h[idx - 1] === " " || h[idx - 1] === "-") score += 8;
    hi = idx + 1;
  }
  // Prefer shorter, earlier matches when scores tie.
  return score - h.length * 0.05 - hi * 0.1;
}

function pad2(n) {
  return n < 10 ? "0" + n : String(n);
}

function formatDuration(seconds) {
  if (!isFinite(seconds) || seconds <= 0) return "0:00";
  const s = Math.floor(seconds % 60);
  const m = Math.floor((seconds / 60) % 60);
  const h = Math.floor(seconds / 3600);
  return h > 0 ? h + ":" + pad2(m) + ":" + pad2(s) : m + ":" + pad2(s);
}

function relativeTime(ms) {
  const diff = Math.max(0, Date.now() - ms);
  const min = Math.floor(diff / 60000);
  if (min < 1) return "now";
  if (min < 60) return min + "m";
  const hrs = Math.floor(min / 60);
  if (hrs < 24) return hrs + "h";
  return Math.floor(hrs / 24) + "d";
}

function sanitizeColor(value) {
  return /^#[0-9a-fA-F]{6}$/.test(String(value || "")) ? value : null;
}
