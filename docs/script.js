/* =============================================================================
   Prometheus Dotfiles — docs/script.js
   ============================================================================= */

// ── Nav items ─────────────────────────────────────────────────────────────────
const navItems = [
  { id: 'overview',   icon: 'zap',          label: 'Overview' },
  { id: 'install',    icon: 'package',       label: 'Quick Install' },
  { group: 'Setup' },
  { id: 'apps',       icon: 'boxes',         label: 'Applications' },
  { id: 'symlinks',   icon: 'link',          label: 'Symlinks' },
  { group: 'Desktop' },
  { id: 'sketchybar', icon: 'palette',       label: 'SketchyBar' },
  { id: 'omniwm',     icon: 'layers-3',      label: 'OmniWM' },
  { id: 'aerospace',  icon: 'layout-grid',   label: 'AeroSpace' },
  { id: 'profiles',   icon: 'monitor',       label: 'Multi-Config' },
  { group: 'Terminal' },
  { id: 'ghostty',    icon: 'terminal',      label: 'Ghostty' },
  { id: 'starship',   icon: 'rocket',        label: 'Starship' },
  { id: 'shell',      icon: 'layers',        label: 'Shell Tools' },
  { id: 'zsh',        icon: 'settings-2',    label: 'Zsh' },
  { id: 'fish',       icon: 'waves',         label: 'Fish' },
  { id: 'customize',  icon: 'sliders-horizontal', label: 'Customization' },
  { group: 'More' },
  { id: 'commands',   icon: 'wrench',        label: 'Commands' },
  { id: 'maintenance',icon: 'refresh-cw',    label: 'Maintenance' },
  { id: 'macos',      icon: 'cog',           label: 'macOS Tweaks' },
  { id: 'gallery',    icon: 'images',        label: 'Gallery' },
];

// ── Build sidebar nav ─────────────────────────────────────────────────────────
const sidebarNav = document.getElementById('sidebar-nav');
sidebarNav.innerHTML = navItems.map(item =>
  item.group
    ? `<div class="nav-group-label">${item.group}</div>`
    : `<a href="#${item.id}" class="nav-link" data-target="${item.id}" title="${item.label}">
    <i data-lucide="${item.icon}" class="nav-icon shrink-0"></i>
    <span class="nav-label">${item.label}</span>
  </a>`
).join('');

// ── Build mobile drawer nav ───────────────────────────────────────────────────
const mobileNavLinks = document.getElementById('mobile-nav-links');
mobileNavLinks.innerHTML = navItems.map(item =>
  item.group
    ? `<div class="drawer-group-label">${item.group}</div>`
    : `<a href="#${item.id}" class="drawer-link" data-target="${item.id}">
    <i data-lucide="${item.icon}" class="w-4 h-4 shrink-0 mr-3"></i>
    <span>${item.label}</span>
  </a>`
).join('');

// ── Mobile drawer open / close ────────────────────────────────────────────────
const mobileNav   = document.getElementById('mobile-nav');
const navPanel    = document.getElementById('mobile-nav-panel');
const navBackdrop = document.getElementById('nav-backdrop');
const menuToggle  = document.getElementById('menu-toggle');
const iconMenu    = document.getElementById('icon-menu');
const iconClose   = document.getElementById('icon-close');
const drawerClose = document.getElementById('drawer-close');

let drawerOpen = false;

function openDrawer() {
  drawerOpen = true;
  mobileNav.style.display = 'block';
  mobileNav.removeAttribute('aria-hidden');
  document.body.style.overflow = 'hidden';
  requestAnimationFrame(() => {
    navBackdrop.style.opacity = '1';
    navPanel.style.transform  = 'translateX(0)';
  });
  iconMenu.classList.add('hidden');
  iconClose.classList.remove('hidden');
  menuToggle.setAttribute('aria-label', 'Close navigation');
}

function closeDrawer() {
  drawerOpen = false;
  navBackdrop.style.opacity = '0';
  navPanel.style.transform  = 'translateX(-100%)';
  document.body.style.overflow = '';
  iconMenu.classList.remove('hidden');
  iconClose.classList.add('hidden');
  menuToggle.setAttribute('aria-label', 'Open navigation');
  setTimeout(() => {
    if (!drawerOpen) {
      mobileNav.style.display = 'none';
      mobileNav.setAttribute('aria-hidden', 'true');
    }
  }, 300);
}

menuToggle.addEventListener('click', () => drawerOpen ? closeDrawer() : openDrawer());
drawerClose.addEventListener('click', closeDrawer);
navBackdrop.addEventListener('click', closeDrawer);
mobileNavLinks.querySelectorAll('.drawer-link').forEach(link => {
  link.addEventListener('click', closeDrawer);
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape' && drawerOpen) closeDrawer();
});

// ── Active section highlight ──────────────────────────────────────────────────
const sectionObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      document.querySelectorAll('.nav-link, .drawer-link').forEach(link => {
        link.classList.toggle('active', link.dataset.target === entry.target.id);
      });
    }
  });
}, { rootMargin: '-20% 0px -60% 0px' });

document.querySelectorAll('section[id]').forEach(s => sectionObserver.observe(s));

// ── Section fade-in ───────────────────────────────────────────────────────────
const fadeObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      fadeObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.06 });

document.querySelectorAll('.section-fade').forEach(el => fadeObserver.observe(el));

// ── Copy buttons ──────────────────────────────────────────────────────────────
document.querySelectorAll('.copy-btn').forEach(btn => {
  if (!btn.dataset.code) return;
  btn.addEventListener('click', () => {
    navigator.clipboard.writeText(btn.dataset.code).then(() => {
      const prev = btn.textContent;
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(() => {
        btn.textContent = prev;
        btn.classList.remove('copied');
      }, 1800);
    });
  });
});

// ── Tab switching ─────────────────────────────────────────────────────────────
document.querySelectorAll('[id$="-tabs"]').forEach(tabGroup => {
  tabGroup.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      tabGroup.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active-tab'));
      btn.classList.add('active-tab');
      const section = tabGroup.closest('section');
      section.querySelectorAll('.tab-panel').forEach(panel => {
        panel.classList.toggle('hidden', panel.id !== btn.dataset.tab);
      });
    });
  });
});

// ── Desktop sidebar collapse ──────────────────────────────────────────────────
const desktopSidebar   = document.getElementById('desktop-sidebar');
const sidebarToggleBtn = document.getElementById('sidebar-toggle');
let sidebarCollapsed = false;

if (sidebarToggleBtn) {
  sidebarToggleBtn.addEventListener('click', () => {
    sidebarCollapsed = !sidebarCollapsed;
    desktopSidebar.classList.toggle('collapsed', sidebarCollapsed);
    sidebarToggleBtn.setAttribute('aria-label', sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar');
    sidebarToggleBtn.title = sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar';
  });
}

// ── Theme toggle ──────────────────────────────────────────────────────────────
const THEME_KEY = 'prometheus-theme';
let isLight = localStorage.getItem(THEME_KEY) === 'light';

function applyTheme(light) {
  document.documentElement.classList.toggle('light-mode', light);
  document.body.classList.toggle('light-mode', light);
  const icon = light ? 'sun' : 'moon';
  ['theme-icon-mobile', 'theme-icon-desktop'].forEach(id => {
    const el = document.getElementById(id);
    if (el) { el.setAttribute('data-lucide', icon); lucide.createIcons({ nodes: [el] }); }
  });
}

applyTheme(isLight);

function toggleTheme() {
  isLight = !isLight;
  localStorage.setItem(THEME_KEY, isLight ? 'light' : 'dark');
  applyTheme(isLight);
}

document.getElementById('theme-toggle-mobile')?.addEventListener('click', toggleTheme);
document.getElementById('theme-toggle-desktop')?.addEventListener('click', toggleTheme);

// ── Reading progress bar ──────────────────────────────────────────────────────
const progressBar = document.getElementById('progress-bar');
if (progressBar) {
  window.addEventListener('scroll', () => {
    const scrollTop = window.scrollY;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    progressBar.style.width = docHeight > 0 ? (scrollTop / docHeight * 100) + '%' : '0%';
  }, { passive: true });
}

// ── Back to top ───────────────────────────────────────────────────────────────
const backToTop = document.getElementById('back-to-top');
if (backToTop) {
  window.addEventListener('scroll', () => {
    backToTop.classList.toggle('visible', window.scrollY > 400);
  }, { passive: true });
  backToTop.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
}

// ── Gallery lightbox ──────────────────────────────────────────────────────────
const lightbox        = document.getElementById('lightbox');
const lightboxInner   = document.getElementById('lightbox-inner');
const lightboxCaption = document.getElementById('lightbox-caption');
const lightboxClose   = document.getElementById('lightbox-close');
const lightboxPrev    = document.getElementById('lightbox-prev');
const lightboxNext    = document.getElementById('lightbox-next');

if (lightbox) {
  const thumbs = Array.from(document.querySelectorAll('.gallery-thumb'));
  let currentIndex = 0;

  function openLightbox(index) {
    currentIndex = index;
    const thumb = thumbs[index];
    const img = thumb.querySelector('img');
    const previewEl = thumb.querySelector('.gallery-preview');
    const title = thumb.dataset.title || '';
    const sub   = thumb.dataset.sub   || '';

    lightboxInner.innerHTML = '';

    if (img) {
      // Real image — show at full size
      const el = document.createElement('img');
      el.src = img.src;
      el.alt = img.alt || title;
      el.style.cssText = 'width:100%;height:100%;object-fit:contain;display:block;background:#1a1b26;';
      lightboxInner.appendChild(el);
    } else if (previewEl) {
      // CSS gradient placeholder — copy computed background
      const div = document.createElement('div');
      div.style.cssText = 'width:100%;height:100%;';
      div.style.background = window.getComputedStyle(previewEl).background;
      lightboxInner.appendChild(div);
    }

    lightboxCaption.innerHTML = `${title}<span>${sub}</span>`;
    lightbox.classList.add('open');
    document.body.style.overflow = 'hidden';
  }

  function closeLightbox() {
    lightbox.classList.remove('open');
    document.body.style.overflow = '';
  }

  function showPrev() {
    currentIndex = (currentIndex - 1 + thumbs.length) % thumbs.length;
    openLightbox(currentIndex);
  }

  function showNext() {
    currentIndex = (currentIndex + 1) % thumbs.length;
    openLightbox(currentIndex);
  }

  thumbs.forEach((thumb, i) => {
    thumb.addEventListener('click', () => openLightbox(i));
  });

  lightboxClose?.addEventListener('click', closeLightbox);
  lightboxPrev?.addEventListener('click', showPrev);
  lightboxNext?.addEventListener('click', showNext);

  lightbox.addEventListener('click', e => {
    if (e.target === lightbox) closeLightbox();
  });

  document.addEventListener('keydown', e => {
    if (!lightbox.classList.contains('open')) return;
    if (e.key === 'Escape')      closeLightbox();
    if (e.key === 'ArrowLeft')   showPrev();
    if (e.key === 'ArrowRight')  showNext();
  });
}

// ── Wallpaper definitions ─────────────────────────────────────────────────────
// type: 'gradient' → generated via Canvas (4K PNG download)
// type: 'image'    → served from docs/images/wallpapers/ (direct download)
const WALLPAPERS = [
  // ── Real images (shown first) ──────────────────────────────────────────────
  {
    type: 'image',
    title: 'Tokyo Night',
    sub: 'tokyonight_original.png',
    src: 'images/wallpapers/tokyonight_original.png',
  },
  {
    type: 'image',
    title: 'Geisha',
    sub: 'geisha_original.png',
    src: 'images/wallpapers/geisha_original.png',
  },
  {
    type: 'image',
    title: 'JavaScript',
    sub: 'js_original.png',
    src: 'images/wallpapers/js_original.png',
  },
  {
    type: 'image',
    title: 'AI Art',
    sub: 'ChatGPT generated',
    src: 'images/wallpapers/ChatGPT Image Dec 11, 2025, 02_03_20 AM.png',
  },
  {
    type: 'image',
    title: 'Photo 1',
    sub: '',
    src: 'images/wallpapers/517272501_17915469006134992_7411283482441444015_n.webp',
  },
  {
    type: 'image',
    title: 'Photo 2',
    sub: '',
    src: 'images/wallpapers/521601423_17916950979134992_992477360667174056_n.webp',
  },
  // ── Generated gradients (shown after images) ───────────────────────────────
  {
    type: 'gradient',
    title: 'Tokyo Night Storm',
    sub: 'Muted blue · slate',
    stops: [['#1a1b26', 0], ['#1e2030', 0.3], ['#414868', 0.7], ['#6b7fba', 1]],
  },
  {
    type: 'gradient',
    title: 'Aurora',
    sub: 'Blue · purple · cyan',
    stops: [['#1a1b26', 0], ['#2a3d7a', 0.3], ['#7847bd', 0.65], ['#7dcfff', 1]],
  },
  {
    type: 'gradient',
    title: 'Forest Glow',
    sub: 'Dark · emerald',
    stops: [['#0d1117', 0], ['#1a2a1a', 0.35], ['#2a4a2a', 0.65], ['#9ece6a', 1]],
  },
  {
    type: 'gradient',
    title: 'Sunset Horizon',
    sub: 'Orange · rose · purple',
    stops: [['#1a1b26', 0], ['#6b2200', 0.3], ['#f7768e', 0.65], ['#bb9af7', 1]],
  },
  {
    type: 'gradient',
    title: 'Midnight Ocean',
    sub: 'Deep navy · teal',
    stops: [['#040810', 0], ['#0a1628', 0.35], ['#0d3b5a', 0.65], ['#7dcfff', 1]],
  },
  {
    type: 'gradient',
    title: 'Cherry Blossom',
    sub: 'Dark · rose · pink',
    stops: [['#0d0a10', 0], ['#2d0f20', 0.35], ['#8b2252', 0.65], ['#f7768e', 1]],
  },
  {
    type: 'gradient',
    title: 'Neon Rain',
    sub: 'Black · electric cyan',
    stops: [['#030a10', 0], ['#051a2a', 0.35], ['#0a4a6a', 0.65], ['#7aa2f7', 1]],
  },
  {
    type: 'gradient',
    title: 'Ember',
    sub: 'Dark · warm amber',
    stops: [['#0d0800', 0], ['#2a1200', 0.35], ['#8a4a00', 0.65], ['#ff9e64', 1]],
  },
  {
    type: 'gradient',
    title: 'Deep Space',
    sub: 'Near-black · indigo',
    stops: [['#030305', 0], ['#0d0b1a', 0.3], ['#2a1a4a', 0.65], ['#7aa2f7', 1]],
  },
  {
    type: 'gradient',
    title: 'Monochrome',
    sub: 'Graphite · blue-grey',
    stops: [['#080808', 0], ['#141414', 0.3], ['#2a2a2a', 0.65], ['#565f89', 1]],
  },
];

// ── Canvas gradient wallpaper download (4K PNG) ───────────────────────────────
function downloadGradientWallpaper(wp) {
  const W = 3840, H = 2160;
  const canvas = document.createElement('canvas');
  canvas.width = W;
  canvas.height = H;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createLinearGradient(0, 0, W, H);
  wp.stops.forEach(([color, pos]) => grad.addColorStop(pos, color));
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, W, H);
  const a = document.createElement('a');
  a.download = wp.title.toLowerCase().replace(/\s+/g, '-') + '.png';
  a.href = canvas.toDataURL('image/png');
  a.click();
}

// ── Build wallpaper carousel ──────────────────────────────────────────────────
function buildWallpaperCarousel() {
  const carousel = document.getElementById('wp-carousel');
  if (!carousel) return;

  carousel.innerHTML = WALLPAPERS.map((wp, i) => {
    const gradientCSS = wp.type === 'gradient'
      ? `linear-gradient(135deg,${wp.stops.map(([c, p]) => `${c} ${p * 100}%`).join(',')})`
      : '';

    const preview = wp.type === 'image'
      ? `<img class="wp-card-img" src="${wp.src}" alt="${wp.title}" loading="lazy" />`
      : `<div class="wp-card-gradient" style="background:${gradientCSS}"></div>`;

    const dlBtn = wp.type === 'image'
      ? `<a class="wp-dl-btn" href="${wp.src}" download aria-label="Download ${wp.title}">
           <i data-lucide="download" class="w-3 h-3"></i> Download
         </a>`
      : `<button class="wp-dl-btn" data-wp-idx="${i}" aria-label="Download ${wp.title}">
           <i data-lucide="download" class="w-3 h-3"></i> Download
         </button>`;

    return `<div class="wp-card">
      <div class="wp-card-preview">${preview}</div>
      <div class="wp-card-footer">
        <div>
          <div class="wp-title">${wp.title}</div>
          ${wp.sub ? `<div class="wp-sub">${wp.sub}</div>` : ''}
        </div>
        ${dlBtn}
      </div>
    </div>`;
  }).join('');

  // Gradient download handlers
  carousel.querySelectorAll('.wp-dl-btn[data-wp-idx]').forEach(btn => {
    btn.addEventListener('click', () => {
      const original = btn.innerHTML;
      btn.innerHTML = '<i data-lucide="loader-2" class="w-3 h-3"></i> Generating...';
      btn.disabled = true;
      lucide.createIcons({ nodes: [btn] });
      setTimeout(() => {
        downloadGradientWallpaper(WALLPAPERS[parseInt(btn.dataset.wpIdx)]);
        btn.innerHTML = original;
        btn.disabled = false;
        lucide.createIcons({ nodes: [btn] });
      }, 50);
    });
  });

  lucide.createIcons({ nodes: Array.from(carousel.querySelectorAll('[data-lucide]')) });
  initCarouselControls();
}

// ── Carousel prev / next ──────────────────────────────────────────────────────
function initCarouselControls() {
  const carousel = document.getElementById('wp-carousel');
  const prev     = document.getElementById('wp-prev');
  const next     = document.getElementById('wp-next');
  if (!carousel || !prev || !next) return;

  const STEP = 292; // card width (280) + gap (12)
  const counter = document.getElementById('wp-counter');

  function updateCounter() {
    if (!counter) return;
    const idx = Math.min(Math.round(carousel.scrollLeft / STEP), WALLPAPERS.length - 1);
    counter.textContent = `${idx + 1} / ${WALLPAPERS.length}`;
  }

  function updateButtons() {
    prev.disabled = carousel.scrollLeft <= 0;
    next.disabled = carousel.scrollLeft >= carousel.scrollWidth - carousel.clientWidth - 4;
    updateCounter();
  }

  prev.addEventListener('click', () => carousel.scrollBy({ left: -STEP, behavior: 'smooth' }));
  next.addEventListener('click', () => carousel.scrollBy({ left:  STEP, behavior: 'smooth' }));
  carousel.addEventListener('scroll', updateButtons, { passive: true });
  updateButtons();
}

buildWallpaperCarousel();

// ── Init Lucide icons (must be last) ──────────────────────────────────────────
lucide.createIcons();
