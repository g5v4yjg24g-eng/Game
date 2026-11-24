// Prüft die App-Store-Connect-Zugangsdaten aus den Umgebungsvariablen, bevor gebaut wird.
// Gibt nur Ergebnisse aus, nie Schlüssel. Aufruf: node ios/check-asc.mjs <pfad-zur-p8>
// Umgebung: ASC_KEY_ID, ASC_ISSUER_ID, APPLE_TEAM_ID, BUNDLE_ID
import { createPrivateKey, sign } from 'node:crypto';
import { readFileSync } from 'node:fs';

const { ASC_KEY_ID: kid = '', ASC_ISSUER_ID: iss = '', APPLE_TEAM_ID: team = '', BUNDLE_ID: bundle = '' } = process.env;
const pem = readFileSync(process.argv[2], 'utf8');
const lines = pem.trim().split(/\r?\n/);
const problems = [];

if (!/^[A-Z0-9]{10}$/.test(kid.trim())) problems.push(`ASC_KEY_ID hat nicht die Form von 10 Großbuchstaben/Ziffern (Länge ${kid.length})`);
if (kid !== kid.trim()) problems.push('ASC_KEY_ID enthält Leerzeichen oder Zeilenumbrüche');
if (!/^[0-9a-f-]{36}$/i.test(iss.trim())) problems.push(`ASC_ISSUER_ID ist keine UUID (Länge ${iss.length})`);
if (iss !== iss.trim()) problems.push('ASC_ISSUER_ID enthält Leerzeichen oder Zeilenumbrüche');
if (!/^[A-Z0-9]{10}$/.test(team.trim())) problems.push(`APPLE_TEAM_ID hat nicht die Form von 10 Zeichen (Länge ${team.length})`);
if (lines[0] !== '-----BEGIN PRIVATE KEY-----') problems.push('ASC_PRIVATE_KEY beginnt nicht mit -----BEGIN PRIVATE KEY-----');
if (lines.at(-1) !== '-----END PRIVATE KEY-----') problems.push('ASC_PRIVATE_KEY endet nicht mit -----END PRIVATE KEY-----');
console.log(`Schlüsseldatei: ${lines.length} Zeilen`);
// Nie Inhalte der Secrets ausgeben (auch nicht zerlegt) – nur Länge und ob die Form stimmt.
if (/BEGIN|PRIVATE/.test(kid)) problems.push('ASC_KEY_ID enthält den privaten Schlüssel statt der 10-stelligen Key-ID');
if (/BEGIN|PRIVATE/.test(iss)) problems.push('ASC_ISSUER_ID enthält den privaten Schlüssel statt der Issuer-ID');
console.log(`Längen: Key-ID ${kid.trim().length} (soll 10), Issuer-ID ${iss.trim().length} (soll 36), Team-ID ${team.trim().length} (soll 10)`);

let key;
try {
  key = createPrivateKey(pem);
  console.log(`Schlüssel lesbar: ${key.asymmetricKeyType}`);
} catch (e) {
  problems.push(`ASC_PRIVATE_KEY lässt sich nicht lesen: ${e.message}`);
}

async function tryToken(payload) {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const head = b64({ alg: 'ES256', kid: kid.trim(), typ: 'JWT' });
  const body = b64(payload);
  const sig = sign('sha256', Buffer.from(`${head}.${body}`), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  const url = `https://api.appstoreconnect.apple.com/v1/apps?filter[bundleId]=${encodeURIComponent(bundle)}`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${head}.${body}.${sig}` } });
  return { res, json: await res.json().catch(() => ({})) };
}

if (key) {
  const now = Math.floor(Date.now() / 1000);
  const base = { iat: now, exp: now + 600, aud: 'appstoreconnect-v1' };
  // Teamschlüssel: mit Issuer-ID. Individueller Schlüssel: ohne Issuer, mit sub "user".
  const asTeam = await tryToken({ ...base, iss: iss.trim() });
  console.log(`Als Teamschlüssel: HTTP ${asTeam.res.status}`);
  if (asTeam.res.ok) {
    const found = Boolean(asTeam.json.data?.length);
    console.log(`App mit Bundle-ID ${bundle} gefunden: ${found ? 'ja' : 'NEIN'}`);
    if (!found) problems.push(`Schlüssel gültig, aber keine App mit ${bundle} in App Store Connect`);
  } else {
    for (const e of asTeam.json.errors ?? []) console.log(`  ${e.status} ${e.code}: ${e.title}`);
    const indiv = await tryToken({ ...base, sub: 'user' });
    console.log(`Als individueller Schlüssel: HTTP ${indiv.res.status}`);
    problems.push(
      indiv.res.ok
        ? 'Das ist ein INDIVIDUELLER Schlüssel. Bitte unter Integrationen → App Store Connect API → Reiter „Teamschlüssel“ einen Schlüssel (Admin oder App Manager) erstellen.'
        : 'App Store Connect lehnt die Zugangsdaten ab: Key-ID, Issuer-ID und .p8 gehören nicht zusammen (oder der Schlüssel wurde widerrufen).',
    );
  }
}

if (problems.length) {
  for (const p of problems) console.log(`::error::${p}`);
  process.exit(1);
}
console.log('Zugangsdaten in Ordnung.');
