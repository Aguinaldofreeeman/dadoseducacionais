// ============================================================
// config.js — Fonte única de verdade para a configuração do Supabase
// Todas as páginas carregam este arquivo depois da CDN do supabase-js.
// Nota: a publishable key é pública por design (a segurança real vem
// das políticas de Row Level Security no Supabase).
// ============================================================

const SUPABASE_URL = 'https://hygvdaixsqogcmcolnyx.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_RwMK19Fa7ZekiGB4uQxV5Q_QEcL6W0P';

// Cliente global disponível para todas as páginas como `supabaseClient`
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
