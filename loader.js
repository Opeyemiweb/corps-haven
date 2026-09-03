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

  function finish() {
    if (!document.body.contains(overlay)) return; // already removed
    overlay.classList.add("ch-loader-hide");
    document.body.style.overflow = "";
    setTimeout(() => overlay.remove(), 500);
  }

  // Hard failsafe: no matter what goes wrong above, never let the
  // overlay block the page for more than 2 seconds.
  const failsafe = setTimeout(finish, 2000);

  try {
    const numEl = overlay.querySelector("#ch-loader-num");
    let pct = 0;
    const duration = 850;
    const start = performance.now();

    function tick(now) {
      const elapsed = now - start;
      pct = Math.min(100, Math.round((elapsed / duration) * 100));
      if (numEl) numEl.textContent = pct;
      if (pct < 100) {
        requestAnimationFrame(tick);
      } else {
        clearTimeout(failsafe);
        setTimeout(finish, 150);
      }
    }
    requestAnimationFrame(tick);
  } catch (e) {
    clearTimeout(failsafe);
    finish();
  }
})();
