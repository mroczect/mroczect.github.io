(function () {
  "use strict";

  const navItems = document.querySelectorAll(".nav-item");
  const sections = Array.from(document.querySelectorAll("section[id]"));
  const sourceToggles = document.querySelectorAll(".source-toggle");
  const toggleAllBtn = document.getElementById("toggle-all");

  let allSourcesVisible = false;

  function setActiveNav() {
    const scrollY = window.scrollY;
    let current = sections[0];
    for (const section of sections) {
      if (section.offsetTop - 100 <= scrollY) {
        current = section;
      }
    }
    navItems.forEach((item) => {
      const target = item.getAttribute("href").substring(1);
      item.classList.toggle("active", current && current.id === target);
    });
  }

  function setupSourceToggles() {
    sourceToggles.forEach((btn) => {
      btn.addEventListener("click", () => {
        const targetId = btn.getAttribute("data-target");
        const source = document.getElementById(targetId);
        if (!source) return;
        source.classList.toggle("visible");
        btn.textContent = source.classList.contains("visible")
          ? "Sembunyikan LaTeX"
          : "Lihat LaTeX";
        btn.classList.toggle("active", source.classList.contains("visible"));
      });
    });
  }

  function setupToggleAll() {
    if (!toggleAllBtn) return;
    toggleAllBtn.addEventListener("click", () => {
      allSourcesVisible = !allSourcesVisible;
      document.querySelectorAll(".latex-source").forEach((src) => {
        src.classList.toggle("visible", allSourcesVisible);
      });
      sourceToggles.forEach((btn) => {
        const targetId = btn.getAttribute("data-target");
        const source = document.getElementById(targetId);
        if (source) {
          btn.textContent = allSourcesVisible
            ? "Sembunyikan LaTeX"
            : "Lihat LaTeX";
          btn.classList.toggle("active", allSourcesVisible);
        }
      });
      toggleAllBtn.textContent = allSourcesVisible
        ? "Sembunyikan Semua Sumber"
        : "Tampilkan Semua Sumber";
    });
  }

  function setupSmoothScroll() {
    navItems.forEach((item) => {
      item.addEventListener("click", (e) => {
        e.preventDefault();
        const target = document.querySelector(item.getAttribute("href"));
        if (target) {
          target.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      });
    });
  }

  function setupKeyboard() {
    let currentIndex = 0;
    document.addEventListener("keydown", (e) => {
      if (e.target.matches("input, textarea, select")) return;

      if (e.key === "j" || e.key === "ArrowDown" && e.shiftKey) {
        e.preventDefault();
        currentIndex = Math.min(currentIndex + 1, sections.length - 1);
        scrollToSection(currentIndex);
      } else if (e.key === "k" || e.key === "ArrowUp" && e.shiftKey) {
        e.preventDefault();
        currentIndex = Math.max(currentIndex - 1, 0);
        scrollToSection(currentIndex);
      } else if (e.key === "g") {
        e.preventDefault();
        currentIndex = 0;
        scrollToSection(0);
      } else if (e.key === "G") {
        e.preventDefault();
        currentIndex = sections.length - 1;
        scrollToSection(currentIndex);
      }
    });
  }

  function scrollToSection(index) {
    const section = sections[index];
    if (section) {
      section.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  }

  window.addEventListener("scroll", setActiveNav, { passive: true });

  document.addEventListener("DOMContentLoaded", () => {
    setupSourceToggles();
    setupToggleAll();
    setupSmoothScroll();
    setupKeyboard();
    setActiveNav();
  });
})();
