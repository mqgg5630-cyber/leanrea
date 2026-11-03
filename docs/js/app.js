/* ==== 恋爱小屋 · 逻辑 ====
 * 数据保存在浏览器 localStorage，支持导出 / 导入 JSON 备份。
 */

const LS = {
  config: "lh_config",
  timeline: "lh_timeline",
  notes: "lh_notes",
};

function load(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch { return fallback; }
}
function save(key, val) { localStorage.setItem(key, JSON.stringify(val)); }

let config = Object.assign({}, DEFAULT_CONFIG, load(LS.config, {}));
let timeline = load(LS.timeline, DEFAULT_TIMELINE.slice());
let notes = load(LS.notes, []);

const $ = (s) => document.querySelector(s);
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

/* ---------- 基础信息渲染 ---------- */
function renderBasics() {
  document.title = config.siteTitle;
  $("#nav-title").textContent = config.siteTitle.replace(/^我们的/, "");
  $("#name-a").textContent = config.nameA;
  $("#name-b").textContent = config.nameB;
  $("#who-a").textContent = config.nameA;
  $("#who-b").textContent = config.nameB;
  $("#slogan").textContent = config.slogan;
  $("#since-date").textContent = config.togetherDate.replace(/-/g, " . ");
  $("#footer-names").textContent = `${config.nameA} & ${config.nameB}`;
}

/* ---------- 计时器 ---------- */
function tick() {
  const start = new Date(config.togetherDate + "T00:00:00");
  let diff = Math.max(0, Date.now() - start.getTime());
  const d = Math.floor(diff / 86400000); diff -= d * 86400000;
  const h = Math.floor(diff / 3600000); diff -= h * 3600000;
  const m = Math.floor(diff / 60000); diff -= m * 60000;
  const s = Math.floor(diff / 1000);
  $("#c-days").textContent = d;
  $("#c-hours").textContent = String(h).padStart(2, "0");
  $("#c-mins").textContent = String(m).padStart(2, "0");
  $("#c-secs").textContent = String(s).padStart(2, "0");
}

/* ---------- 纪念日 ---------- */
function renderMilestones() {
  const start = new Date(config.togetherDate + "T00:00:00");
  const now = new Date(); now.setHours(0, 0, 0, 0);
  const dayMs = 86400000;
  const passed = Math.floor((now - start) / dayMs);

  const list = [];
  // 整百天
  [100, 200, 300, 520, 1000, 1314, 2000, 3000, 5000, 10000].forEach((n) => {
    const date = new Date(start.getTime() + n * dayMs);
    list.push({ emoji: "💯", name: `在一起 ${n} 天`, date, left: n - passed });
  });
  // 周年
  for (let y = 1; y <= 50; y++) {
    const date = new Date(start); date.setFullYear(start.getFullYear() + y);
    list.push({ emoji: "🎉", name: `${y} 周年`, date, left: Math.round((date - now) / dayMs) });
  }
  // 固定节日（每年）
  const fests = [
    { emoji: "💘", name: "情人节", m: 1, d: 14 },
    { emoji: "💞", name: "520", m: 4, d: 20 },
    { emoji: "🎄", name: "圣诞节", m: 11, d: 25 },
  ];
  fests.forEach((f) => {
    let date = new Date(now.getFullYear(), f.m, f.d);
    if (date < now) date = new Date(now.getFullYear() + 1, f.m, f.d);
    list.push({ emoji: f.emoji, name: f.name, date, left: Math.round((date - now) / dayMs) });
  });

  const upcoming = list
    .filter((x) => x.left >= 0)
    .sort((a, b) => a.left - b.left)
    .slice(0, 6);

  $("#milestones").innerHTML = upcoming
    .map((x) => {
      const dateStr = `${x.date.getFullYear()}-${String(x.date.getMonth() + 1).padStart(2, "0")}-${String(x.date.getDate()).padStart(2, "0")}`;
      const leftHtml = x.left === 0 ? "🎊 就是今天！" : `还有 <b>${x.left}</b> 天`;
      return `<div class="milestone ${x.left === 0 ? "today" : ""}">
        <div class="m-emoji">${x.emoji}</div>
        <div class="m-name">${esc(x.name)}</div>
        <div class="m-date">${dateStr}</div>
        <div class="m-left">${leftHtml}</div>
      </div>`;
    })
    .join("");
}

/* ---------- 时光轴 ---------- */
function renderTimeline() {
  const sorted = timeline.slice().sort((a, b) => b.date.localeCompare(a.date));
  $("#timeline-list").innerHTML = sorted.length
    ? sorted
        .map(
          (ev, i) => `<div class="tl-item">
            <div class="tl-card">
              <button class="tl-del" data-del="${esc(ev.date)}|${esc(ev.title)}" title="删除">✕ 删除</button>
              <div class="tl-date">${esc(ev.date)}</div>
              <div class="tl-title">${esc(ev.title)}</div>
              <div class="tl-text">${esc(ev.text || "")}</div>
            </div>
          </div>`
        )
        .join("")
    : `<p class="section-sub">还没有记录，点上面的"+ 记一笔"开始吧～</p>`;

  document.querySelectorAll(".tl-del").forEach((btn) => {
    btn.onclick = () => {
      if (!confirm("确定删除这条记录吗？")) return;
      const [d, t] = btn.dataset.del.split("|");
      timeline = timeline.filter((ev) => !(ev.date === d && ev.title === t));
      save(LS.timeline, timeline);
      renderTimeline();
    };
  });
}

/* ---------- 相册 ---------- */
function renderGallery() {
  $("#gallery-grid").innerHTML = GALLERY.map(
    (g, i) => `<figure class="g-item" data-i="${i}">
      <img loading="lazy" src="${driveImg(g.id, 800)}"
           onerror="if(!this.dataset.fb){this.dataset.fb=1;this.src='${driveImgFallback(g.id, 800)}'}"
           alt="${esc(g.caption)}" />
      <figcaption class="g-caption">${esc(g.caption)}</figcaption>
    </figure>`
  ).join("");

  document.querySelectorAll(".g-item").forEach((el) => {
    el.onclick = () => {
      const g = GALLERY[+el.dataset.i];
      const img = $("#lightbox-img");
      img.src = driveImg(g.id, 1600);
      img.onerror = () => { img.onerror = null; img.src = driveImgFallback(g.id, 1600); };
      $("#lightbox-caption").textContent = g.caption;
      $("#lightbox").hidden = false;
      document.body.style.overflow = "hidden";
    };
  });
}
function closeLightbox() {
  $("#lightbox").hidden = true;
  document.body.style.overflow = "";
}

/* ---------- 悄悄话 ---------- */
function renderNotes() {
  $("#notes-list").innerHTML = notes
    .slice()
    .reverse()
    .map(
      (n, idx) => `<div class="note from-${n.who === "A" ? "a" : "b"}">
        <button class="n-del" data-i="${notes.length - 1 - idx}" title="删除">✕</button>
        ${esc(n.text)}
        <span class="n-meta">${n.who === "A" ? esc(config.nameA) : esc(config.nameB)} · ${esc(n.time)}</span>
      </div>`
    )
    .join("");

  document.querySelectorAll(".n-del").forEach((btn) => {
    btn.onclick = () => {
      notes.splice(+btn.dataset.i, 1);
      save(LS.notes, notes);
      renderNotes();
    };
  });
}

/* ---------- 出游指南 ---------- */
function renderGuides() {
  $("#guide-cards").innerHTML = GUIDE_FILES.map(
    (g) => `<a class="guide-card" href="${driveView(g.id)}" target="_blank" rel="noopener">
      <span class="g-icon">${g.icon}</span>
      <span><span class="g-label">${esc(g.label)}</span><br/><span class="g-hint">在 Google Drive 中打开 ↗</span></span>
    </a>`
  ).join("");
}

/* ---------- 飘落爱心 ---------- */
function spawnHeart() {
  const el = document.createElement("span");
  el.className = "float-heart";
  el.textContent = ["💗", "💕", "🌸", "💖", "✨"][Math.floor(Math.random() * 5)];
  el.style.left = Math.random() * 100 + "vw";
  el.style.fontSize = 10 + Math.random() * 16 + "px";
  el.style.animationDuration = 7 + Math.random() * 8 + "s";
  $("#hearts-bg").appendChild(el);
  setTimeout(() => el.remove(), 16000);
}

/* ---------- 事件绑定 ---------- */
function bindEvents() {
  // 灯箱
  $("#lightbox-close").onclick = closeLightbox;
  $("#lightbox").onclick = (e) => { if (e.target.id === "lightbox") closeLightbox(); };
  document.addEventListener("keydown", (e) => { if (e.key === "Escape") closeLightbox(); });

  // 设置
  $("#btn-settings").onclick = () => {
    $("#set-name-a").value = config.nameA;
    $("#set-name-b").value = config.nameB;
    $("#set-date").value = config.togetherDate;
    $("#set-slogan").value = config.slogan;
    $("#modal-settings").hidden = false;
  };
  $("#set-cancel").onclick = () => ($("#modal-settings").hidden = true);
  $("#set-save").onclick = () => {
    config.nameA = $("#set-name-a").value.trim() || config.nameA;
    config.nameB = $("#set-name-b").value.trim() || config.nameB;
    config.togetherDate = $("#set-date").value || config.togetherDate;
    config.slogan = $("#set-slogan").value.trim() || config.slogan;
    save(LS.config, config);
    $("#modal-settings").hidden = true;
    renderBasics(); renderMilestones(); renderNotes(); tick();
  };

  // 记一笔
  $("#btn-add-event").onclick = () => {
    $("#ev-date").value = new Date().toISOString().slice(0, 10);
    $("#ev-title").value = ""; $("#ev-text").value = "";
    $("#modal-event").hidden = false;
  };
  $("#ev-cancel").onclick = () => ($("#modal-event").hidden = true);
  $("#ev-save").onclick = () => {
    const date = $("#ev-date").value, title = $("#ev-title").value.trim();
    if (!date || !title) { alert("日期和标题都要填哦"); return; }
    timeline.push({ date, title, text: $("#ev-text").value.trim() });
    save(LS.timeline, timeline);
    $("#modal-event").hidden = true;
    renderTimeline();
  };

  // 悄悄话
  $("#btn-add-note").onclick = () => {
    const text = $("#note-input").value.trim();
    if (!text) return;
    const who = document.querySelector('input[name="who"]:checked').value;
    const now = new Date();
    notes.push({
      who, text,
      time: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")} ${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`,
    });
    save(LS.notes, notes);
    $("#note-input").value = "";
    renderNotes();
  };

  // 导出 / 导入
  $("#btn-export").onclick = () => {
    const blob = new Blob(
      [JSON.stringify({ config, timeline, notes, exportedAt: new Date().toISOString() }, null, 2)],
      { type: "application/json" }
    );
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = `恋爱小屋备份_${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(a.href);
  };
  $("#file-import").onchange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const data = JSON.parse(reader.result);
        if (data.config) { config = Object.assign({}, DEFAULT_CONFIG, data.config); save(LS.config, config); }
        if (Array.isArray(data.timeline)) { timeline = data.timeline; save(LS.timeline, timeline); }
        if (Array.isArray(data.notes)) { notes = data.notes; save(LS.notes, notes); }
        renderBasics(); renderMilestones(); renderTimeline(); renderNotes(); tick();
        alert("导入成功 💕");
      } catch { alert("文件格式不对，导入失败"); }
    };
    reader.readAsText(file);
    e.target.value = "";
  };
}

/* ---------- 启动 ---------- */
renderBasics();
renderMilestones();
renderTimeline();
renderGallery();
renderNotes();
renderGuides();
bindEvents();
tick();
setInterval(tick, 1000);
setInterval(spawnHeart, 900);
for (let i = 0; i < 6; i++) setTimeout(spawnHeart, i * 300);
