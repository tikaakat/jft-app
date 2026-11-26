// ポーカー旅：静的なページはそのまま配信し、/api/contact だけを処理する。
// 送られた内容は Cloudflare Email Routing で運営者のメールに転送する。
// 宛先のアドレスは、Cloudflare の画面で設定する秘密の変数 TO_ADDRESS に入れる（リポジトリには書かない）。
import { EmailMessage } from "cloudflare:email";

const FROM = "form@pokertabi.com";
const KINDS = ["掲載内容の訂正", "掲載の追加", "掲載の削除", "違法・グレーの疑いの通報", "その他"];
const MAX = { target: 200, body: 3000, source: 500, contact: 200 };

function b64(s) {
  const bytes = new TextEncoder().encode(s);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

function wrap(s, n = 76) { return s.replace(new RegExp(`(.{${n}})`, "g"), "$1\r\n"); }

function back(url, status, reason) {
  const u = new URL(`/contact/?sent=${status}`, url);
  if (reason) console.error("contact form:", reason); // 原因は公開せず、Cloudflare のログにだけ残す
  return Response.redirect(u.toString(), 303);
}

async function handleContact(request, env) {
  const url = new URL(request.url);
  const origin = request.headers.get("Origin") || "";
  if (origin && !/^https:\/\/(www\.)?pokertabi\.com$/.test(origin)) return new Response("forbidden", { status: 403 });
  const f = await request.formData();
  // 迷惑な投稿への対策：見えない入力欄に何か入っていたら捨てる。表示から 3 秒以内の送信も捨てる。
  if ((f.get("website") || "").toString().trim()) return back(url, "ok");
  const ts = Number(f.get("ts") || 0);
  if (!ts || Date.now() - ts < 3000) return back(url, "ok");
  const kind = (f.get("kind") || "").toString();
  const target = (f.get("target") || "").toString().trim().slice(0, MAX.target);
  const body = (f.get("body") || "").toString().trim().slice(0, MAX.body);
  const source = (f.get("source") || "").toString().trim().slice(0, MAX.source);
  const contact = (f.get("contact") || "").toString().trim().slice(0, MAX.contact);
  const agree = f.get("agree");
  if (!KINDS.includes(kind) || !body || !agree) return back(url, "invalid");
  if (!env.TO_ADDRESS) return back(url, "error", "no TO_ADDRESS");
  if (!env.MAILER) return back(url, "error", "no MAILER binding");
  const subject = `【ポーカー旅】${kind}：${target || "（対象の記載なし）"}`.slice(0, 120);
  const text = [
    `種類：${kind}`, `対象：${target}`, "", "内容：", body, "", `出典：${source}`, `連絡先：${contact || "（なし）"}`, "",
    `送信日時：${new Date().toISOString()}`, `国：${request.cf?.country || ""}`,
  ].join("\n");
  const raw = [
    `From: =?UTF-8?B?${b64("ポーカー旅 フォーム")}?= <${FROM}>`,
    `To: ${env.TO_ADDRESS}`,
    `Subject: =?UTF-8?B?${b64(subject)}?=`,
    `Message-ID: <${crypto.randomUUID()}@pokertabi.com>`,
    `Date: ${new Date().toUTCString()}`,
    "MIME-Version: 1.0",
    "Content-Type: text/plain; charset=UTF-8",
    "Content-Transfer-Encoding: base64",
    "",
    wrap(b64(text)),
  ].join("\r\n");
  try {
    await env.MAILER.send(new EmailMessage(FROM, env.TO_ADDRESS, raw));
  } catch (e) {
    console.error("send failed", e && e.message);
    return back(url, "error", "send: " + (e && e.message || "unknown"));
  }
  return back(url, "ok");
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/api/contact") {
      if (request.method !== "POST") return new Response("method not allowed", { status: 405 });
      return handleContact(request, env);
    }
    return env.ASSETS.fetch(request);
  },
};
