// ========================================================
//  恋爱小屋 · 配置文件
//  改这里就能换名字、纪念日、相册图片，无需改其它代码
// ========================================================

const DEFAULT_CONFIG = {
  // 两个人的名字
  nameA: "小树",
  nameB: "小熊",

  // 在一起的日子（年-月-日）
  togetherDate: "2024-05-20",

  // 网站标题
  siteTitle: "我们的恋爱小屋",
  slogan: "把每一天的喜欢，都好好记下来",
};

// 相册：直接引用 Google Drive 里的插画（已设为"知道链接可查看"）
// 想换图：把自己 Drive 图片的文件 ID 填进来即可
const GALLERY = [
  { id: "1SNfB65K4dPGX8a86wibzgOm7iSmOblF5", caption: "贴着红脸彩绘 · 一起傻笑的日子" },
  { id: "1qhGVw0tsBtxgJBimM3Uk3gVXZ6Z1r76a", caption: "橱窗前 · 看见喜欢的就走不动" },
  { id: "1lAnHqxEPS91gpO3H8zBvyzlhGcJIgk9z", caption: "靠墙合影 · 黑帽子是他的标志" },
  { id: "1G8tPEYVq9tbz8oFPEDiWxdJ8RZ8PaZiJ", caption: "第一张自拍 · 卷发和长直发" },
  { id: "1N1cp2MQ4tCH7T_gNkNVzflrp3F7jf6lF", caption: "秋天 · 一起穿夹克的季节" },
  { id: "1JGhXDi-RFrM8mkKKgjHgptpF_IGFMeqO", caption: "酒红卫衣 · 情侣装第一套" },
  { id: "1nl4WvRq6miL70kk5d8CH1N0hl6iGWJcr", caption: "夏日草帽 · 防晒全靠它" },
  { id: "1QvoKnkicQtvcKdU0wFJOWSqKTw5yHYAh", caption: "近景 · 凑在一起拍的" },
  { id: "1E4KTBbd_o-dXdhIdiRpREdTbHk0027Qf", caption: "海滩 · 第一次一起看海" },
  { id: "1asMUJWRYu6MdZxZDYEgo8jPNuBhp6h7b", caption: "厨房 · 背后抱着看你做饭" },
  { id: "15XeJ5f0mcmeM3pjFYaB2KgRYzjSrBLal", caption: "夜景 · 深色大衣的冬天" },
  { id: "1d0aKauf4OBEJzMrebDHuu-2dtLhrYe40", caption: "咖啡馆 · 周末的固定节目" },
];

// 时光轴默认事件（可在网页上直接增删改，保存在浏览器里）
const DEFAULT_TIMELINE = [
  { date: "2024-05-20", title: "在一起啦", text: "从今天起，我们是我们了。" },
  { date: "2024-08-01", title: "第一次旅行", text: "一起看了海，晒黑了也开心。" },
  { date: "2025-01-01", title: "跨年", text: "倒数的时候偷偷许愿：年年有今日。" },
];

// 出游指南（Google Drive 文件）
const GUIDE_FILES = [
  { id: "1nrzmo3BlLdyf0HOIvdQ3yMcba8-O8a2i", label: "PDF 版", icon: "📕" },
  { id: "1OkBHzKhdTZUFhLNRqe0Zzab0TMUZCQRq", label: "网页版（离线单文件）", icon: "🌐" },
  { id: "19k7Ms1mAbGt4AKriwJ43IJI-iT5rySbE", label: "EPUB 电子书", icon: "📖" },
];

// Google Drive 图片直链（公开文件可用）
function driveImg(id, w = 1600) {
  return `https://drive.google.com/thumbnail?id=${id}&sz=w${w}`;
}
function driveImgFallback(id, w = 1600) {
  return `https://lh3.googleusercontent.com/d/${id}=w${w}`;
}
function driveView(id) {
  return `https://drive.google.com/file/d/${id}/view`;
}
