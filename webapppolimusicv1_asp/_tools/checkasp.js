/*
 * checkasp.js - Verificador estatico de bloques VBScript en archivos ASP.
 * Extrae el codigo ASP, elimina cadenas y comentarios, y comprueba que
 * todos los bloques (If/For/Do/Select/Sub/Function/Class) cierren bien.
 */
const fs = require("fs");
const path = require("path");

function walk(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.toLowerCase().endsWith(".asp")) out.push(p);
  }
  return out;
}

// Extrae solo el codigo ASP; el HTML se sustituye por saltos de linea
function extractCode(src) {
  let out = "";
  let i = 0;
  while (i < src.length) {
    const start = src.indexOf("<%", i);
    if (start === -1) { out += "\n".repeat(countLines(src.slice(i))); break; }
    out += "\n".repeat(countLines(src.slice(i, start)));
    let isExpr = src[start + 2] === "=" || src[start + 2] === "@";
    const end = src.indexOf("%>", start + 2);
    const body = end === -1 ? src.slice(start + 2) : src.slice(start + 2, end);
    if (src[start + 2] === "@") {
      out += "\n".repeat(countLines(body));           // directiva
    } else if (isExpr) {
      out += "Response.Write " + body + "\n";          // <%= expr %>
    } else {
      out += body + "\n";
    }
    i = end === -1 ? src.length : end + 2;
  }
  return out;
}

function countLines(s) { return (s.match(/\n/g) || []).length; }

// Elimina comentarios y neutraliza el contenido de las cadenas
function clean(code) {
  const lines = code.split(/\r?\n/);
  const out = [];
  for (let raw of lines) {
    let res = "";
    let inStr = false;
    for (let i = 0; i < raw.length; i++) {
      const c = raw[i];
      if (inStr) {
        if (c === '"') {
          if (raw[i + 1] === '"') { i++; continue; }
          inStr = false;
          res += " ";
        }
        continue;
      }
      if (c === '"') { inStr = true; res += " "; continue; }
      if (c === "'") { break; }                        // comentario
      if (c === "R" || c === "r") {
        if (/^rem\b/i.test(raw.slice(i)) && /^\s*$/i.test(res)) break;
      }
      res += c;
    }
    out.push(res);
  }
  // Une lineas de continuacion (terminan en _)
  const joined = [];
  let buf = "";
  for (const l of out) {
    const t = l.replace(/\s+$/, "");
    if (/_$/.test(t) && !/"[^"]*_$/.test(t)) {
      buf += t.slice(0, -1) + " ";
    } else {
      joined.push(buf + t);
      buf = "";
    }
  }
  if (buf) joined.push(buf);
  return joined;
}

const OPENERS = [
  { re: /^\s*If\b.*\bThen\s*$/i,                       close: "End If",     name: "If" },
  { re: /^\s*For\b/i,                                   close: "Next",       name: "For" },
  { re: /^\s*Do\b/i,                                    close: "Loop",       name: "Do" },
  { re: /^\s*Select\s+Case\b/i,                         close: "End Select", name: "Select" },
  { re: /^\s*With\b/i,                                  close: "End With",   name: "With" },
  { re: /^\s*(Public\s+|Private\s+)?Sub\s+\w+/i,        close: "End Sub",    name: "Sub" },
  { re: /^\s*(Public\s+|Private\s+)?Function\s+\w+/i,   close: "End Function", name: "Function" },
  { re: /^\s*Class\s+\w+/i,                             close: "End Class",  name: "Class" }
];

function checkFile(file) {
  const src = fs.readFileSync(file, "utf8");
  const code = clean(extractCode(src));
  const stack = [];
  const errs = [];
  code.forEach((line, idx) => {
    const n = idx + 1;
    // Cierres primero
    let m;
    if ((m = /^\s*End\s+(If|Select|With|Sub|Function|Class)\b/i.exec(line))) {
      const want = "End " + m[1].replace(/\b\w/g, (c) => c.toUpperCase());
      const top = stack.pop();
      if (!top) errs.push(`L${n}: "${want}" sin apertura`);
      else if (top.close.toLowerCase() !== want.toLowerCase())
        errs.push(`L${n}: se esperaba "${top.close}" (abierto en L${top.line}) pero llego "${want}"`);
      return;
    }
    if (/^\s*Next\b/i.test(line)) {
      const top = stack.pop();
      if (!top) errs.push(`L${n}: "Next" sin apertura`);
      else if (top.close !== "Next") errs.push(`L${n}: se esperaba "${top.close}" (L${top.line}) pero llego "Next"`);
      return;
    }
    if (/^\s*Loop\b/i.test(line)) {
      const top = stack.pop();
      if (!top) errs.push(`L${n}: "Loop" sin apertura`);
      else if (top.close !== "Loop") errs.push(`L${n}: se esperaba "${top.close}" (L${top.line}) pero llego "Loop"`);
      return;
    }
    if (/^\s*ElseIf\b/i.test(line) || /^\s*Else\s*$/i.test(line)) return;

    for (const o of OPENERS) {
      if (o.re.test(line)) { stack.push({ close: o.close, name: o.name, line: n }); return; }
    }
  });
  for (const s of stack) errs.push(`L${s.line}: "${s.name}" quedo sin cerrar (falta "${s.close}")`);
  return errs;
}

const root = process.argv[2];
const files = walk(root, []).sort();
let total = 0;
for (const f of files) {
  const errs = checkFile(f);
  const rel = path.relative(root, f);
  if (errs.length === 0) {
    console.log(`OK    ${rel}`);
  } else {
    total += errs.length;
    console.log(`ERROR ${rel}`);
    errs.forEach((e) => console.log(`        ${e}`));
  }
}
console.log(`\nArchivos revisados: ${files.length}  |  Problemas: ${total}`);
