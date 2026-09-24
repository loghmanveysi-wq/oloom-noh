// نسخه به‌روزشده - trigger build
// واسط چت هوش مصنوعی علوم نهم (Cloudflare Workers AI)
const SYSTEM_PROMPT =
  "تو دستیار آموزشی درس علوم تجربی پایه نهم ایران هستی. " +
  "فقط به زبان فارسی و ساده، مثل یک معلم مهربان جواب بده. " +
  "فقط درباره‌ی علوم پایه نهم پاسخ بده؛ اگر سؤال ربطی به درس نداشت، با مهربانی بگو فقط در مورد علوم کمک می‌کنی. " +
  "جواب‌ها کوتاه و روشن باشد. اطلاعات شخصی نخواه و مطلب نامناسب نگو.";

const DEFAULT_MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

async function verifyUser(token, apiKey) {
  const res = await fetch(
    "https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=" + apiKey,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken: token }),
    }
  );
  if (!res.ok) return null;
  const data = await res.json();
  return data.users && data.users[0] ? data.users[0] : null;
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return json({ error: "method" }, 405);

    const auth = request.headers.get("Authorization") || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    if (!token) return json({ error: "no-token" }, 401);

    const user = await verifyUser(token, env.FIREBASE_API_KEY);
    if (!user) return json({ error: "bad-token" }, 401);

    let body;
    try {
      body = await request.json();
    } catch (e) {
      return json({ error: "bad-json" }, 400);
    }

    const history = Array.isArray(body.messages) ? body.messages.slice(-10) : [];
    const messages = [{ role: "system", content: SYSTEM_PROMPT }];
    for (const m of history) {
      if (!m || typeof m.content !== "string") continue;
      const role = m.role === "assistant" ? "assistant" : "user";
      messages.push({ role: role, content: m.content.slice(0, 1000) });
    }
    if (messages.length < 2) return json({ error: "empty" }, 400);

    try {
      const result = await env.AI.run(env.MODEL || DEFAULT_MODEL, {
        messages: messages,
        max_tokens: 500,
      });
      let reply = result.response;
      if (!reply && result.choices && result.choices[0]) {
        reply = result.choices[0].message.content;
      }
      return json({ reply: reply || "" });
    } catch (e) {
      return json({ error: "ai-failed", detail: String(e).slice(0, 200) }, 502);
    }
  },
};
