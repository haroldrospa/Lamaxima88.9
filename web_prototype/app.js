// MOCK DATABASE STOCKS (Simula Supabase)
let config = {
    stream_radio: "https://streaming.lamaximafm.com:8000/stream", // Streaming de audio público continuo
    stream_tv: "https://streaming.lamaximafm.com:2020/hls/lamaximatv/lamaximatv.m3u8", // Streaming HLS de prueba
    facebook: "https://www.facebook.com/share/18qKUQ9LT2/?mibextid=wwXIfr",
    instagram: "https://www.instagram.com/lamaxima88.9?igsh=MXRtZWlwampkdHFsYw==",
    youtube: "https://youtube.com/@lamaxima88?si=SzovcRt5QUwOi3ux",
    tiktok: "https://www.tiktok.com/@lamaxima889fm?_r=1&_t=ZS-97AO2ZUs2FN"
};

let programas = [
    {
        id: "p1",
        nombre: "El Mañanero Máximo",
        locutor: "Hosta Máxima",
        imagen: "https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&q=80&w=150&h=150",
        hora_inicio: "06:00",
        hora_fin: "10:00"
    },
    {
        id: "p2",
        nombre: "La Hora del Tapón",
        locutor: "DJ Máxima & Compañía",
        imagen: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150&h=150",
        hora_inicio: "17:00",
        hora_fin: "19:00"
    },
    {
        id: "p3",
        nombre: "LA MÁXIMA 88.9 FM",
        locutor: "Hosta Máxima",
        imagen: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150&h=150",
        hora_inicio: "12:00",
        hora_fin: "23:59"
    }
];

// STATE MANAGEMENT
let currentUser = null; // Simula sesión
let currentPlayingType = 'none'; // 'none', 'radio'
let isAudioPlaying = false;
let activeAdminSection = 'programs';
let editingItemId = null;
let isTvPlaying = false;

// HTML Elements
const audioElement = document.getElementById('app-audio-element');
const videoElement = document.getElementById('tv-video');
const miniPlayer = document.getElementById('mini-player');
const miniPlayBtn = document.getElementById('mini-play-btn');
const miniCloseBtn = document.getElementById('mini-close-btn');

const radioWaves = document.getElementById('radio-waves');
const vinylDisc = document.getElementById('vinyl-disc');
const giantPlayBtn = document.getElementById('giant-play-btn');
const volumeSlider = document.getElementById('radio-volume-slider');

// ON LOAD INITIALIZATION
document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    renderAllViews();
    setupListeners();
    initWeeklySchedule();
    initVideoControls();
    initAutoplayRadio();
});

// THEME MANAGEMENT
function initTheme() {
    const isDark = localStorage.getItem('theme-mode') === 'dark';
    if (isDark) {
        document.body.classList.remove('light-mode');
        document.body.classList.add('dark-mode');
        document.getElementById('theme-toggle').innerHTML = '<i class="fa-regular fa-sun"></i>';
        updateLogoImages(true);
    } else {
        updateLogoImages(false);
    }
}

document.getElementById('theme-toggle').addEventListener('click', toggleTheme);

function toggleTheme() {
    const isDark = document.body.classList.contains('dark-mode');
    if (isDark) {
        document.body.classList.remove('dark-mode');
        document.body.classList.add('light-mode');
        document.getElementById('theme-toggle').innerHTML = '<i class="fa-regular fa-moon"></i>';
        localStorage.setItem('theme-mode', 'light');
        updateLogoImages(false);
    } else {
        document.body.classList.remove('light-mode');
        document.body.classList.add('dark-mode');
        document.getElementById('theme-toggle').innerHTML = '<i class="fa-regular fa-sun"></i>';
        localStorage.setItem('theme-mode', 'dark');
        updateLogoImages(true);
    }
}

function updateLogoImages(isDark) {
    const headerLogo = document.querySelector('.logo img');
    const vinylLogo = document.querySelector('.vinyl-center img');
    const src = isDark ? 'logo_dark.png' : 'logo.png';
    if (headerLogo) headerLogo.src = src;
    if (vinylLogo) vinylLogo.src = src;
}

// MODAL MANAGEMENT
function showModal(modalId) {
    const modalContainer = document.getElementById('modal-container');
    modalContainer.classList.remove('hidden');
    
    // Hide all modal cards first
    const cards = modalContainer.querySelectorAll('.modal-card');
    cards.forEach(card => card.classList.add('hidden'));
    
    // Show target card
    const target = document.getElementById(modalId);
    if (target) {
        target.classList.remove('hidden');
    }
}

function closeModal() {
    const modalContainer = document.getElementById('modal-container');
    modalContainer.classList.add('hidden');
    
    const cards = modalContainer.querySelectorAll('.modal-card');
    cards.forEach(card => card.classList.add('hidden'));
}

// RENDER DATA DYNAMICALLY
function renderAllViews() {
    renderHome();
}

function renderHome() {
    // Ahora al aire (Buscar programa activo)
    const now = new Date();
    const currentHourStr = now.getHours().toString().padLeft(2, '0') + ":" + now.getMinutes().toString().padLeft(2, '0');
    
    let activeProg = programas.find(p => {
        return currentHourStr >= p.hora_inicio && currentHourStr <= p.hora_fin;
    }) || programas[2] || programas[0];

    if (activeProg) {
        const hostImg = document.getElementById('now-host-img');
        const progTitle = document.getElementById('now-program-title');
        const hostName = document.getElementById('now-host-name');
        const scheduleTime = document.getElementById('now-schedule-time');
        
        if (hostImg) hostImg.src = activeProg.imagen;
        if (progTitle) progTitle.innerText = activeProg.nombre;
        if (hostName) hostName.innerText = `Locutor: ${activeProg.locutor}`;
        if (scheduleTime) scheduleTime.innerText = `${activeProg.hora_inicio} - ${activeProg.hora_fin}`;
        
        const radioNowProg = document.getElementById('radio-now-program');
        if (radioNowProg) radioNowProg.innerText = activeProg.nombre;
    }

    // Enlaces sociales
    const ig = document.getElementById('social-instagram');
    if (ig) ig.href = config.instagram || '#';
    const fb = document.getElementById('social-facebook');
    if (fb) fb.href = config.facebook || '#';
    const tt = document.getElementById('social-tiktok');
    if (tt) tt.href = config.tiktok || '#';
    const yt = document.getElementById('social-youtube');
    if (yt) yt.href = config.youtube || '#';
}

// FORMAT HELPER
String.prototype.padLeft = function(length, char) {
    return this.length >= length ? this : (char.repeat(length - this.length) + this);
};

// ACTIONS LISTENERS
function setupListeners() {
    // Tab Segment switching (Radio vs TV)
    document.getElementById('seg-radio-btn').addEventListener('click', () => switchHomeTab(true));
    document.getElementById('seg-tv-btn').addEventListener('click', () => switchHomeTab(false));

    // Radio Volume Control
    volumeSlider.addEventListener('input', (e) => {
        audioElement.volume = e.target.value / 100;
    });

    // Play/Pause Giant Button (Radio)
    giantPlayBtn.addEventListener('click', toggleLiveRadio);

    // Miniplayer controls
    miniPlayBtn.addEventListener('click', togglePlayState);
    miniCloseBtn.addEventListener('click', stopAudioPlayback);

    // Admin toggle button in header
    document.getElementById('admin-toggle').addEventListener('click', handleAdminToggle);

    // Auth listeners
    document.getElementById('auth-toggle-mode').addEventListener('click', toggleAuthMode);
    document.getElementById('auth-form').addEventListener('submit', handleAuthSubmit);
    document.getElementById('btn-logout').addEventListener('click', handleLogout);
    
    // Admin Panel routing
    document.getElementById('admin-config-form').addEventListener('submit', handleConfigSave);
}

// TAB HOME SWITCHER (Radio vs TV)
function switchHomeTab(isRadio) {
    const radioBtn = document.getElementById('seg-radio-btn');
    const tvBtn = document.getElementById('seg-tv-btn');
    const radioPanel = document.getElementById('panel-radio');
    const tvPanel = document.getElementById('panel-tv');

    if (isRadio) {
        radioBtn.classList.add('active');
        tvBtn.classList.remove('active');
        radioPanel.classList.remove('hidden');
        tvPanel.classList.add('hidden');
        
        pauseLiveTv();
        playRadioWeb();
    } else {
        radioBtn.classList.remove('active');
        tvBtn.classList.add('active');
        radioPanel.classList.add('hidden');
        tvPanel.classList.remove('hidden');
        
        // Pausar radio para evitar sonidos mezclados
        stopAudioPlayback();
        
        playLiveTv();
    }
}

// Autoplay helper for Radio
function initAutoplayRadio() {
    // Attempt autoplay immediately
    playRadioWeb();
    
    // Fallback if blocked: start play on first user interaction
    const startOnInteraction = () => {
        if (!isAudioPlaying) {
            playRadioWeb();
        }
        document.removeEventListener('click', startOnInteraction);
        document.removeEventListener('touchstart', startOnInteraction);
    };
    document.addEventListener('click', startOnInteraction);
    document.addEventListener('touchstart', startOnInteraction);
}

function playRadioWeb() {
    currentPlayingType = 'radio';
    audioElement.src = config.stream_radio;
    audioElement.volume = volumeSlider.value / 100;
    audioElement.load();
    audioElement.play()
        .then(() => {
            isAudioPlaying = true;
            updateAudioUI();
        })
        .catch(e => {
            console.log("Autoplay was prevented, waiting for interaction: ", e);
        });
}

// PLAY AUDIO / STREAMING (RADIO)
function toggleLiveRadio() {
    if (currentPlayingType === 'radio') {
        if (isAudioPlaying) {
            audioElement.pause();
            audioElement.src = ''; // Unload stream to avoid buffering outdated chunks
            isAudioPlaying = false;
        } else {
            audioElement.src = config.stream_radio;
            audioElement.load(); // Request fresh buffer
            audioElement.play().catch(e => console.log("Play failed: ", e));
            isAudioPlaying = true;
        }
        updateAudioUI();
    } else {
        stopAudioPlayback();
        currentPlayingType = 'radio';
        
        audioElement.src = config.stream_radio;
        audioElement.volume = volumeSlider.value / 100;
        audioElement.load();
        audioElement.play().catch(e => console.log("Play failed: ", e));
        
        isAudioPlaying = true;
        updateAudioUI();
    }
}

function togglePlayState() {
    if (isAudioPlaying) {
        audioElement.pause();
        audioElement.src = ''; // Unload stream to prevent latency lag on resume
        isAudioPlaying = false;
    } else {
        audioElement.src = config.stream_radio;
        audioElement.load(); // Force fresh fetch
        audioElement.play().catch(e => console.log("Play failed: ", e));
        isAudioPlaying = true;
    }
    updateAudioUI();
}

function stopAudioPlayback() {
    audioElement.pause();
    audioElement.src = '';
    isAudioPlaying = false;
    currentPlayingType = 'none';
    updateAudioUI();
}

// PLAY VIDEO STREAMING (TV)
let hlsInstance = null;

function playLiveTv() {
    isTvPlaying = true;
    
    // Explicitly set inline playback attributes for iOS Safari
    videoElement.setAttribute('playsinline', 'true');
    videoElement.setAttribute('webkit-playsinline', 'true');
    videoElement.playsInline = true;

    if (Hls.isSupported()) {
        if (!hlsInstance) {
            hlsInstance = new Hls({
                enableWorker: true,
                lowLatencyMode: true,
                backBufferLength: 0,
                maxBufferSize: 0,
                maxBufferLength: 1.5,
                maxMaxBufferLength: 3,
                liveSyncDurationCount: 1.5
            });
            hlsInstance.attachMedia(videoElement);
            hlsInstance.on(Hls.Events.MEDIA_ATTACHED, function () {
                hlsInstance.loadSource(config.stream_tv);
            });
            hlsInstance.on(Hls.Events.MANIFEST_PARSED, function () {
                videoElement.play().catch(e => console.log("Play failed: ", e));
            });
        } else {
            hlsInstance.loadSource(config.stream_tv);
            videoElement.play().catch(e => console.log("Play failed: ", e));
        }
    } else if (videoElement.canPlayType('application/vnd.apple.mpegurl')) {
        videoElement.src = config.stream_tv;
        videoElement.load(); // Call load() to apply the source in Safari properly
        videoElement.play().catch(e => console.log("Play failed: ", e));
    }
}

function pauseLiveTv() {
    if (isTvPlaying) {
        videoElement.pause();
        isTvPlaying = false;
        if (hlsInstance) {
            hlsInstance.stopLoad();
        }
    }
}

// SYNC UI WITH PLAYBACK STATES
function updateAudioUI() {
    // 1. Radio Tab UI (Giant Button, Waves, Vinyl)
    const statusText = document.getElementById('radio-status-text');

    if (currentPlayingType === 'radio' && isAudioPlaying) {
        radioWaves.classList.add('playing');
        vinylDisc.classList.add('playing');
        giantPlayBtn.innerHTML = '<i class="fa-solid fa-circle-pause"></i>';
        statusText.innerText = 'ESCUCHANDO AHORA';
        statusText.style.color = 'var(--gold)';
    } else {
        radioWaves.classList.remove('playing');
        vinylDisc.classList.remove('playing');
        giantPlayBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
        statusText.innerText = 'RADIO EN VIVO';
        statusText.style.color = 'var(--text-muted)';
    }

    // 2. Mini Player (Bottom Float)
    if (currentPlayingType === 'none') {
        miniPlayer.classList.add('hidden');
    } else {
        miniPlayer.classList.remove('hidden');
        
        const thumb = document.getElementById('mini-player-thumb');
        const title = document.getElementById('mini-player-title');
        const subtitle = document.getElementById('mini-player-subtitle');
        
        thumb.innerHTML = '<i class="fa-solid fa-radio"></i>';
        title.innerText = 'Radio En Vivo';
        subtitle.innerText = 'La Máxima 88.9 FM';

        miniPlayBtn.innerHTML = isAudioPlaying 
            ? '<i class="fa-solid fa-circle-pause"></i>' 
            : '<i class="fa-solid fa-circle-play"></i>';
    }
}

// AUTH SIMULATOR
function toggleAuthMode() {
    const btn = document.getElementById('auth-toggle-mode');
    const title = document.getElementById('auth-title');
    const submit = document.getElementById('auth-submit-btn');
    const nameGroup = document.getElementById('signup-name-group');

    if (btn.innerText.includes('Regístrate')) {
        title.innerText = 'Crear Cuenta';
        submit.innerText = 'REGISTRARSE';
        btn.innerText = '¿Ya tienes una cuenta? Inicia sesión';
        nameGroup.classList.remove('hidden');
    } else {
        title.innerText = 'Iniciar Sesión';
        submit.innerText = 'INGRESAR';
        btn.innerText = '¿No tienes cuenta? Regístrate aquí';
        nameGroup.classList.add('hidden');
    }
}

function handleAdminToggle() {
    if (currentUser && currentUser.is_admin) {
        showAdminDashboard();
    } else {
        showModal('modal-auth');
    }
}

function handleAuthSubmit(e) {
    e.preventDefault();
    const email = document.getElementById('auth-email').value;
    const name = document.getElementById('auth-name').value || 'Administrador';
    const isAdmin = email.toLowerCase() === 'admin@lamaxima.fm' || email.toLowerCase().includes('admin');

    if (!isAdmin) {
        alert("Acceso denegado. Solo administradores autorizados.");
        return;
    }

    currentUser = {
        nombre: name,
        email: email,
        is_admin: isAdmin
    };

    updateAdminUIState();
    closeModal();
    showAdminDashboard();
}

function handleLogout() {
    currentUser = null;
    updateAdminUIState();
    closeModal();
    alert("Sesión cerrada correctamente.");
}

function updateAdminUIState() {
    const adminToggle = document.getElementById('admin-toggle');
    const shieldIcon = adminToggle.querySelector('i');
    
    if (currentUser && currentUser.is_admin) {
        shieldIcon.style.color = 'var(--gold)';
        adminToggle.title = "Panel de Administración";
    } else {
        shieldIcon.style.color = '';
        adminToggle.title = "Administración";
    }
}

// PORTAL ADMINISTRATIVO
function showAdminDashboard() {
    showModal('modal-admin');
    
    const infoContainer = document.getElementById('admin-user-info');
    if (infoContainer && currentUser) {
        infoContainer.innerText = `Conectado como: ${currentUser.nombre} (${currentUser.email})`;
    }
    
    switchAdminSection('programs');
}

function hideAdminDashboard() {
    closeModal();
}

function switchAdminSection(section) {
    activeAdminSection = section;
    
    const cards = document.querySelectorAll('.admin-grid-card');
    const sections = ['programs', 'config'];
    
    cards.forEach((card, idx) => {
        if (sections[idx] === section) {
            card.style.borderColor = 'var(--gold)';
            card.style.backgroundColor = 'var(--shadow)';
        } else {
            card.style.borderColor = 'var(--border)';
            card.style.backgroundColor = 'var(--surface)';
        }
    });

    sections.forEach(s => {
        const secEl = document.getElementById(`admin-sec-${s}`);
        if (s === section) {
            secEl.classList.remove('hidden');
        } else {
            secEl.classList.add('hidden');
        }
    });

    renderAdminLists();
}

function renderAdminLists() {
    if (activeAdminSection === 'programs') {
        const container = document.getElementById('admin-programs-list');
        container.innerHTML = '';
        programas.forEach(item => {
            container.appendChild(createAdminRow(`${item.nombre} (${item.hora_inicio})`, item.id, () => openAdminForm('programs', item)));
        });
    } else if (activeAdminSection === 'config') {
        const cfgRadio = document.getElementById('cfg-radio');
        if (cfgRadio) cfgRadio.value = config.stream_radio || '';
        const cfgTv = document.getElementById('cfg-tv');
        if (cfgTv) cfgTv.value = config.stream_tv || '';
        const cfgFacebook = document.getElementById('cfg-facebook');
        if (cfgFacebook) cfgFacebook.value = config.facebook || '';
        const cfgInstagram = document.getElementById('cfg-instagram');
        if (cfgInstagram) cfgInstagram.value = config.instagram || '';
        const cfgTiktok = document.getElementById('cfg-tiktok');
        if (cfgTiktok) cfgTiktok.value = config.tiktok || '';
        const cfgYoutube = document.getElementById('cfg-youtube');
        if (cfgYoutube) cfgYoutube.value = config.youtube || '';
    }
}

function createAdminRow(label, id, onEdit) {
    const div = document.createElement('div');
    div.className = 'admin-item-row';
    div.innerHTML = `
        <span class="admin-item-info">${label}</span>
        <div class="admin-item-actions">
            <button class="edit-btn" style="color: #1877F2;"><i class="fa-solid fa-pen"></i></button>
            <button class="del-btn" style="color: #ff3b30;"><i class="fa-solid fa-trash"></i></button>
        </div>
    `;
    div.querySelector('.edit-btn').onclick = onEdit;
    div.querySelector('.del-btn').onclick = () => deleteAdminItem(id);
    return div;
}

// CRUD FORMULARIOS
function openAdminForm(type, item = null) {
    editingItemId = item ? item.id : null;
    const title = document.getElementById('admin-form-title');
    const fieldsContainer = document.getElementById('dynamic-form-fields');
    fieldsContainer.innerHTML = '';

    if (type === 'programs') {
        title.innerText = item ? 'Editar Programa' : 'Crear Programa';
        fieldsContainer.innerHTML = `
            <div class="input-group"><label>Nombre del Programa</label><input type="text" id="frm-prog-name" value="${item ? item.nombre : ''}" required></div>
            <div class="input-group"><label>Locutor</label><input type="text" id="frm-prog-host" value="${item ? item.locutor : ''}" required></div>
            <div class="input-group"><label>Hora de Inicio</label><input type="text" id="frm-prog-start" value="${item ? item.hora_inicio : '08:00'}" required></div>
            <div class="input-group"><label>Hora de Fin</label><input type="text" id="frm-prog-end" value="${item ? item.hora_fin : '10:00'}" required></div>
            <div class="input-group"><label>URL Foto Locutor</label><input type="text" id="frm-prog-img" value="${item ? item.imagen : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150&h=150'}" required></div>
        `;
    }

    document.getElementById('admin-crud-form').onsubmit = (e) => {
        e.preventDefault();
        saveAdminItem(type);
    };

    showModal('modal-admin-form');
}

function saveAdminItem(type) {
    if (type === 'programs') {
        const item = {
            id: editingItemId || `p${Date.now()}`,
            nombre: document.getElementById('frm-prog-name').value,
            locutor: document.getElementById('frm-prog-host').value,
            hora_inicio: document.getElementById('frm-prog-start').value,
            hora_fin: document.getElementById('frm-prog-end').value,
            imagen: document.getElementById('frm-prog-img').value
        };

        if (editingItemId) {
            const idx = programas.findIndex(p => p.id === editingItemId);
            programas[idx] = item;
        } else {
            programas.push(item);
        }
    }

    closeModal();
    renderAllViews();
    renderAdminLists();
}

function deleteAdminItem(id) {
    if (!confirm('¿Seguro que deseas eliminar este elemento?')) return;

    if (activeAdminSection === 'programs') {
        programas = programas.filter(p => p.id !== id);
    }

    renderAllViews();
    renderAdminLists();
}

function handleConfigSave(e) {
    e.preventDefault();
    const cfgRadio = document.getElementById('cfg-radio');
    if (cfgRadio) config.stream_radio = cfgRadio.value;
    const cfgTv = document.getElementById('cfg-tv');
    if (cfgTv) config.stream_tv = cfgTv.value;
    const cfgFacebook = document.getElementById('cfg-facebook');
    if (cfgFacebook) config.facebook = cfgFacebook.value;
    const cfgInstagram = document.getElementById('cfg-instagram');
    if (cfgInstagram) config.instagram = cfgInstagram.value;
    const cfgTiktok = document.getElementById('cfg-tiktok');
    if (cfgTiktok) config.tiktok = cfgTiktok.value;
    const cfgYoutube = document.getElementById('cfg-youtube');
    if (cfgYoutube) config.youtube = cfgYoutube.value;
    
    alert('Configuración de enlaces actualizada correctamente.');
    renderAllViews();
    hideAdminDashboard();
}

// CLOSE MODAL ON OVERLAY CLICK
document.getElementById('modal-container').addEventListener('click', (e) => {
    if (e.target.id === 'modal-container') {
        closeModal();
    }
});

// WEEKLY SCHEDULE MANAGEMENT
const weeklySchedule = {
    "LUN": [
        { name: "El Mañanero Máximo", time: "06:00 - 10:00", host: "Hosta Máxima" },
        { name: "La Ruta de la Tarde", time: "10:00 - 14:00", host: "DJ Máxima" },
        { name: "Top 40 Hits", time: "14:00 - 18:00", host: "DJ Máster" },
        { name: "La Hora del Tapón", time: "18:00 - 22:00", host: "DJ Máxima & Co." },
        { name: "Música Máxima", time: "22:00 - 06:00", host: "Música Continuada" }
    ],
    "MAR": [
        { name: "El Mañanero Máximo", time: "06:00 - 10:00", host: "Hosta Máxima" },
        { name: "La Ruta de la Tarde", time: "10:00 - 14:00", host: "DJ Máxima" },
        { name: "Top 40 Hits", time: "14:00 - 18:00", host: "DJ Máster" },
        { name: "La Hora del Tapón", time: "18:00 - 22:00", host: "DJ Máxima & Co." },
        { name: "Música Máxima", time: "22:00 - 06:00", host: "Música Continuada" }
    ],
    "MIE": [
        { name: "El Mañanero Máximo", time: "06:00 - 10:00", host: "Hosta Máxima" },
        { name: "La Ruta de la Tarde", time: "10:00 - 14:00", host: "DJ Máxima" },
        { name: "Top 40 Hits", time: "14:00 - 18:00", host: "DJ Máster" },
        { name: "La Hora del Tapón", time: "18:00 - 22:00", host: "DJ Máxima & Co." },
        { name: "Música Máxima", time: "22:00 - 06:00", host: "Música Continuada" }
    ],
    "JUE": [
        { name: "El Mañanero Máximo", time: "06:00 - 10:00", host: "Hosta Máxima" },
        { name: "La Ruta de la Tarde", time: "10:00 - 14:00", host: "DJ Máxima" },
        { name: "Top 40 Hits", time: "14:00 - 18:00", host: "DJ Máster" },
        { name: "La Hora del Tapón", time: "18:00 - 22:00", host: "DJ Máxima & Co." },
        { name: "Música Máxima", time: "22:00 - 06:00", host: "Música Continuada" }
    ],
    "VIE": [
        { name: "El Mañanero Máximo", time: "06:00 - 10:00", host: "Hosta Máxima" },
        { name: "La Ruta de la Tarde", time: "10:00 - 14:00", host: "DJ Máxima" },
        { name: "Top 40 Hits", time: "14:00 - 18:00", host: "DJ Máster" },
        { name: "La Hora del Tapón", time: "18:00 - 22:00", host: "DJ Máxima & Co." },
        { name: "Música Máxima", time: "22:00 - 06:00", host: "Música Continuada" }
    ],
    "SAB": [
        { name: "El Calentón del Sábado", time: "08:00 - 12:00", host: "DJ Máster" },
        { name: "Los Clásicos de la Máxima", time: "12:00 - 18:00", host: "DJ Carlos" },
        { name: "Fiesta Máxima", time: "18:00 - 06:00", host: "Música Continuada" }
    ],
    "DOM": [
        { name: "Domingo de Clásicos", time: "08:00 - 14:00", host: "DJ Carlos" },
        { name: "El Solazo de la Tarde", time: "14:00 - 22:00", host: "DJ Máster" },
        { name: "Música Máxima", time: "22:00 - 06:00", host: "Música Continuada" }
    ]
};

function initWeeklySchedule() {
    const dayButtons = document.querySelectorAll('.day-btn');
    if (!dayButtons.length) return;

    dayButtons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            const day = e.currentTarget.getAttribute('data-day');
            showScheduleDay(day);
        });
    });

    // Auto-select current day
    const dayKeys = ["DOM", "LUN", "MAR", "MIE", "JUE", "VIE", "SAB"];
    const currentDayKey = dayKeys[new Date().getDay()];
    showScheduleDay(currentDayKey);
}

function showScheduleDay(dayKey) {
    // Update active button state
    const dayButtons = document.querySelectorAll('.day-btn');
    dayButtons.forEach(btn => {
        if (btn.getAttribute('data-day') === dayKey) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });

    // Populate list
    const listContainer = document.getElementById('schedule-list');
    if (!listContainer) return;

    listContainer.innerHTML = '';
    const dayPrograms = weeklySchedule[dayKey] || [];

    if (dayPrograms.length === 0) {
        listContainer.innerHTML = '<div style="text-align:center;font-size:12px;color:var(--text-muted);padding:20px;">No hay programación para este día</div>';
        return;
    }

    dayPrograms.forEach(prog => {
        const itemDiv = document.createElement('div');
        itemDiv.className = 'schedule-item';
        itemDiv.innerHTML = `
            <div class="schedule-item-info">
                <span class="schedule-item-title">${prog.name}</span>
                <span class="schedule-item-host">Locución: ${prog.host}</span>
            </div>
            <span class="schedule-item-time">${prog.time}</span>
        `;
        listContainer.appendChild(itemDiv);
    });
}

function initVideoControls() {
    const video = document.getElementById('tv-video');
    const playBtn = document.getElementById('video-play-btn');
    const muteBtn = document.getElementById('video-mute-btn');
    const volumeSlider = document.getElementById('video-volume');
    const fullscreenBtn = document.getElementById('video-fullscreen-btn');
    const pipBtn = document.getElementById('video-pip-btn');

    if (!video || !playBtn || !muteBtn || !volumeSlider || !fullscreenBtn) return;

    // Play/Pause toggle
    playBtn.addEventListener('click', () => {
        if (video.paused) {
            video.play();
            playBtn.innerHTML = '<i class="fa-solid fa-pause"></i>';
        } else {
            video.pause();
            playBtn.innerHTML = '<i class="fa-solid fa-play"></i>';
        }
    });

    // Mute/Unmute toggle
    muteBtn.addEventListener('click', () => {
        video.muted = !video.muted;
        updateVolumeUI();
    });

    // Volume slider change
    volumeSlider.addEventListener('input', (e) => {
        video.volume = e.target.value;
        video.muted = e.target.value == 0;
        updateVolumeUI();
    });

    function updateVolumeUI() {
        volumeSlider.value = video.muted ? 0 : video.volume;
        if (video.muted || video.volume == 0) {
            muteBtn.innerHTML = '<i class="fa-solid fa-volume-xmark"></i>';
        } else if (video.volume < 0.5) {
            muteBtn.innerHTML = '<i class="fa-solid fa-volume-low"></i>';
        } else {
            muteBtn.innerHTML = '<i class="fa-solid fa-volume-high"></i>';
        }
    }

    // Fullscreen toggle
    fullscreenBtn.addEventListener('click', () => {
        const parent = video.parentElement;
        if (parent.requestFullscreen) {
            if (!document.fullscreenElement) {
                parent.requestFullscreen().catch(err => {
                    console.error(`Error al activar pantalla completa: ${err.message}`);
                });
                fullscreenBtn.innerHTML = '<i class="fa-solid fa-compress"></i>';
            } else {
                document.exitFullscreen();
                fullscreenBtn.innerHTML = '<i class="fa-solid fa-expand"></i>';
            }
        } else if (video.webkitEnterFullscreen) {
            // Fallback for iOS iPhone Safari where standard requestFullscreen is not supported on elements, but webkitEnterFullscreen is supported on video
            video.webkitEnterFullscreen();
        } else if (video.webkitRequestFullscreen) {
            video.webkitRequestFullscreen();
        }
    });

    // Listen to exit fullscreen changes (esc key)
    document.addEventListener('fullscreenchange', () => {
        if (!document.fullscreenElement) {
            fullscreenBtn.innerHTML = '<i class="fa-solid fa-expand"></i>';
        }
    });

    // iOS specific end fullscreen listener
    video.addEventListener('webkitendfullscreen', () => {
        fullscreenBtn.innerHTML = '<i class="fa-solid fa-expand"></i>';
    });

    // Picture-in-Picture toggle
    if (pipBtn) {
        const isPipSupported = 
            document.pictureInPictureEnabled || 
            (video.webkitSupportsPresentationMode && typeof video.webkitSetPresentationMode === 'function');

        if (!isPipSupported) {
            pipBtn.style.display = 'none';
        } else {
            pipBtn.addEventListener('click', async () => {
                try {
                    if (document.pictureInPictureEnabled) {
                        if (document.pictureInPictureElement !== video) {
                            await video.requestPictureInPicture();
                        } else {
                            await document.exitPictureInPicture();
                        }
                    } else if (video.webkitSupportsPresentationMode && typeof video.webkitSetPresentationMode === 'function') {
                        const newMode = video.webkitPresentationMode === 'picture-in-picture' ? 'inline' : 'picture-in-picture';
                        video.webkitSetPresentationMode(newMode);
                    }
                } catch (err) {
                    console.error(`Error al activar Picture-in-Picture: ${err.message}`);
                }
            });
        }
    }

    // Automatic Picture-in-Picture fallback when exiting the app (visibility change)
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') {
            if (isTvPlaying && !video.paused) {
                if (document.pictureInPictureEnabled && document.pictureInPictureElement !== video) {
                    video.requestPictureInPicture().catch(() => {});
                } else if (video.webkitSupportsPresentationMode && typeof video.webkitSetPresentationMode === 'function') {
                    if (video.webkitPresentationMode !== 'picture-in-picture') {
                        video.webkitSetPresentationMode('picture-in-picture');
                    }
                }
            }
        }
    });

    // Initial setup sync
    video.volume = 0.5;
    video.muted = true;
    updateVolumeUI();
}
