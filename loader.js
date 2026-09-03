// ============================================================
// Corps Haven — Page-load intro (0 → 100%)
// Shared across every page. Respects reduced-motion preference.
// ============================================================

(function () {
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const overlay = document.createElement("div");
  overlay.id = "ch-loader";
  overlay.innerHTML = `
    <div class="ch-loader-inner">
      <div class="ch-loader-mark">CH</div>
      <div class="ch-loader-pct"><span id="ch-loader-num">0</span>%</div>
    </div>
  `;
  document.body.prepend(overlay);

  if (prefersReducedMotion) {
    overlay.remove();
    return;
  }

  document.body.style.overflow = "hidden";

  const numEl = overlay.querySelector("#ch-loader-num");
  let pct = 0;
  const duration = 850;
  const start = performance.now();

  function tick(now) {
    const elapsed = now - start;
    pct = Math.min(100, Math.round((elapsed / duration) * 100));
    numEl.textContent = pct;
    if (pct < 100) {
      requestAnimationFrame(tick);
    } else {
      setTimeout(() => {
        overlay.classList.add("ch-loader-hide");
        document.body.style.overflow = "";
        setTimeout(() => overlay.remove(), 500);
      }, 150);
    }
  }
  requestAnimationFrame(tick);
})();
