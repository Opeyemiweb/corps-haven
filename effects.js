// ============================================================
// Corps Haven — shared visual effects
// Spotlight hover, scroll-reveal, animated stat counters.
// All respect prefers-reduced-motion. Uses event delegation
// since listing cards are added to the page dynamically after
// data loads — listeners on individual cards wouldn't exist yet.
// ============================================================

(function () {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // ---------- Spotlight hover on listing cards ----------
  if (!reduceMotion) {
    document.addEventListener("mousemove", (e) => {
      const card = e.target.closest(".listing-card");
      if (!card) return;
      const rect = card.getBoundingClientRect();
      card.style.setProperty("--spot-x", (e.clientX - rect.left) + "px");
      card.style.setProperty("--spot-y", (e.clientY - rect.top) + "px");
    });
  }

  // ---------- Scroll-reveal ----------
  // Add class="reveal" to any element to have it fade/slide in
  // the first time it scrolls into view.
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add("reveal-visible");
        revealObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.15 });

  function observeReveals() {
    document.querySelectorAll(".reveal:not(.reveal-visible)").forEach(el => revealObserver.observe(el));
  }
  window.observeReveals = observeReveals;

  // Run now for static content, and again shortly after for
  // anything injected dynamically (listing cards, stats, etc.)
  document.addEventListener("DOMContentLoaded", observeReveals);
  setTimeout(observeReveals, 600);
  setTimeout(observeReveals, 1500);

  // ---------- Animated stat counters ----------
  // Add class="stat-num" and data-count-to="123" to count up
  // from 0 when it scrolls into view. Skips if reduced motion
  // is on, or if the element's text isn't a plain number.
  const countObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      const el = entry.target;
      const target = parseInt(el.dataset.countTo, 10);
      countObserver.unobserve(el);
      if (isNaN(target)) return;

      if (reduceMotion) {
        el.textContent = target;
        return;
      }

      const duration = 900;
      const start = performance.now();
      function tick(now) {
        const progress = Math.min(1, (now - start) / duration);
        const eased = 1 - Math.pow(1 - progress, 3);
        el.textContent = Math.round(target * eased);
        if (progress < 1) requestAnimationFrame(tick);
      }
      requestAnimationFrame(tick);
    });
  }, { threshold: 0.5 });

  // Call this after setting a stat element's final number and
  // data-count-to attribute, to animate it counting up.
  window.animateStatCounter = function (el, value) {
    if (value === null || value === undefined || isNaN(value)) {
      el.textContent = value ?? "—";
      return;
    }
    el.dataset.countTo = value;
    el.textContent = "0";
    countObserver.observe(el);
  };
})();
