// ============================================================
// config.js — Fonte única de verdade para a configuração do Supabase
// Todas as páginas carregam este arquivo depois da CDN do supabase-js.
//
// Segurança:
//   - a gravação de eventos de uso passa pela RPC analytics_registrar
//     (SECURITY DEFINER): escopo e user_id são carimbados no servidor a
//     partir do perfil real, então o cliente não consegue forjar ADM.
// ============================================================

const SUPABASE_URL = 'https://hygvdaixsqogcmcolnyx.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_RwMK19Fa7ZekiGB4uQxV5Q_QEcL6W0P';

// Cliente global disponível para todas as páginas como `supabaseClient`
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

// Expor no escopo global para páginas que leem `window.supabaseClient`
window.supabaseClient = supabaseClient;

// ------------------------------------------------------------------
// Helpers de identificação de visitante / sessão
// ------------------------------------------------------------------
function analyticsRid() {
    return (crypto.randomUUID ? crypto.randomUUID()
        : 'id-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 10));
}
function analyticsVisitanteId() {
    try {
        let v = localStorage.getItem('analytics-vid');
        if (!v) { v = analyticsRid(); localStorage.setItem('analytics-vid', v); }
        return v;
    } catch (e) { return analyticsRid(); }
}
function analyticsSessaoId() {
    try {
        let v = sessionStorage.getItem('analytics-sid');
        if (!v) { v = analyticsRid(); sessionStorage.setItem('analytics-sid', v); }
        return v;
    } catch (e) { return analyticsRid(); }
}
function analyticsNomePagina() {
    try {
        const caminho = window.location.pathname;
        const partes = caminho.split('/');
        const nome = partes[partes.length - 1] || 'index.html';
        return nome.indexOf('.') === -1 ? nome + '.html' : nome;
    } catch (e) { return 'index.html'; }
}

// ------------------------------------------------------------------
// Registro centralizado de eventos de uso (chamada segura, nunca quebra a navegação)
// ------------------------------------------------------------------
window.analyticsRegistrarEvento = async function(evento, extra) {
    extra = extra || {};
    const row = {
        evento: evento,
        pagina: extra.pagina || analyticsNomePagina(),
        modulo: extra.modulo || null,
        sessao_id: analyticsSessaoId(),
        visitante_id: analyticsVisitanteId(),
        referrer: document.referrer || null,
        user_agent: navigator.userAgent,
        metadata: extra.metadata || {}
    };
    try {
        await supabaseClient.rpc('analytics_registrar', row);
    } catch (e) { /* silencioso: nunca bloqueia a navegação */ }
    return row;
};

// Espelho local de resiliência (se a RPC falhar)
function analyticsPushLocal(row) {
    try {
        const buf = JSON.parse(localStorage.getItem('analytics-local') || '[]');
        buf.push(Object.assign({ criado_em: new Date().toISOString() }, row));
        while (buf.length > 200) buf.shift();
        localStorage.setItem('analytics-local', JSON.stringify(buf));
    } catch (e) { /* silencioso */ }
}

// ------------------------------------------------------------------
// Rastreamento automático (chamar uma vez por página após carregar)
//   - page_view: 1 vez por sessão por página
//   - heartbeat: a cada 5 minutos enquanto a aba estiver visível
//   - logout: detectado via onAuthStateChange
// ------------------------------------------------------------------
window.iniciarRastreamentoAutomatico = function() {
    // page_view único por sessão nesta página
    try {
        const chavePv = 'analytics-pv-' + analyticsNomePagina();
        if (sessionStorage.getItem(chavePv) === '1') {
            // já contou nesta sessão
        } else {
            sessionStorage.setItem(chavePv, '1');
            analyticsRegistrarEvento('page_view');
            analyticsPushLocal({ evento: 'page_view', pagina: analyticsNomePagina() });
        }
    } catch (e) { /* ignora */ }

    // heartbeat a cada 5 min (só quando a aba está visível)
    let timerH = null;
    function agendarHeartbeat() {
        if (timerH) clearTimeout(timerH);
        timerH = setTimeout(async () => {
            if (document.visibilityState === 'visible') {
                try { await analyticsRegistrarEvento('heartbeat'); } catch (e) { /* ignora */ }
            }
            agendarHeartbeat();
        }, 5 * 60 * 1000);
    }
    agendarHeartbeat();

    // parar heartbeat quando fechar a aba (best-effort)
    window.addEventListener('beforeunload', () => {
        if (timerH) clearTimeout(timerH);
    });

    // logout detectado pelo Supabase
    try {
        supabaseClient.auth.onAuthStateChange((event, session) => {
            if (event === 'SIGNED_OUT' || event === 'TOKEN_REFRESH_FAILED') {
                analyticsRegistrarEvento('logout');
            }
        });
    } catch (e) { /* ignora */ }
};

// Inicialização automática só quando houver sessão ativa (usuário logado)
// Isso evita registrar page_view de visitantes anônimos nas páginas internas.
(async function() {
    try {
        const { data: { session } } = await supabaseClient.auth.getSession();
        if (session) {
            window.iniciarRastreamentoAutomatico();
        }
    } catch (e) { /* ignora */ }
})();
