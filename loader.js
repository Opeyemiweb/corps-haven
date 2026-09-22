// ============================================================
// Corps Haven — Page-load progress bar (Jiji-style)
// Slim, non-blocking bar across the top. Never covers content,
// never blocks clicks, never needs a failsafe.
// ============================================================

(function () {
  const bar = document.createElement("div");
  bar.id = "ch-progress";
  document.body.prepend(bar);

  let pct = 0;
  bar.style.width = "0%";

  const grow = setInterval(() => {
    pct = Math.min(90, pct + Math.random() * 20);
    bar.style.width = pct + "%";
  }, 120);

  window.addEventListener("load", () => {
    clearInterval(grow);
    bar.style.width = "100%";
    setTimeout(() => {
      bar.style.opacity = "0";
      setTimeout(() => bar.remove(), 300);
    }, 200);
  });
})();
