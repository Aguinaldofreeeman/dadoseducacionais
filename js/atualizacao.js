// ============================================================
// atualizacao.js — data e hora da última importação de cada módulo.
//
// Uso nas páginas:
//   <p data-atualizacao="tarefa">Fonte: Escola Total.</p>
//   <script src="js/atualizacao.js" defer></script>
//
// O elemento recebe exatamente:
//   Fonte: Escola Total. Atualizado em 10/11/2026 15:42.
//
// Se a leitura falhar (offline, tabela ausente, RLS), o texto que
// já estava no HTML é preservado — nada quebra.
//
// Também reaplica o texto quando outra função da página reescreve o
// rodapé (ex.: depois de carregar os dados do Supabase).
// ============================================================
(function () {
    'use strict';

    var FONTE = 'Escola Total';
    var FORMATADOR = null;

    try {
        FORMATADOR = new Intl.DateTimeFormat('pt-BR', {
            timeZone: 'America/Sao_Paulo',
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        });
    } catch (e) {
        FORMATADOR = null;
    }

    function formatar(iso) {
        if (!iso) return null;
        var data = new Date(iso);
        if (isNaN(data.getTime())) return null;
        if (!FORMATADOR) {
            var dois = function (n) { return String(n).padStart(2, '0'); };
            return dois(data.getDate()) + '/' + dois(data.getMonth() + 1) + '/' +
                data.getFullYear() + ' ' + dois(data.getHours()) + ':' + dois(data.getMinutes());
        }
        // pt-BR devolve "10/11/2026, 15:42" — o painel usa sem a vírgula.
        return FORMATADOR.format(data).replace(',', '');
    }

    function texto(quando) {
        return 'Fonte: ' + FONTE + '. Atualizado em ' + quando + '.';
    }

    var cache = {};

    function buscar(modulo) {
        if (cache[modulo]) return cache[modulo];
        var cliente = window.supabaseClient;
        if (!cliente) return Promise.resolve(null);
        cache[modulo] = cliente
            .from('atualizacoes_dados')
            .select('atualizado_em')
            .eq('modulo', modulo)
            .maybeSingle()
            .then(function (resposta) {
                if (!resposta || resposta.error || !resposta.data) return null;
                return formatar(resposta.data.atualizado_em);
            })
            .catch(function () { return null; });
        return cache[modulo];
    }

    function aplicarEm(elemento) {
        var modulo = elemento.getAttribute('data-atualizacao');
        if (!modulo) return Promise.resolve();
        return buscar(modulo).then(function (quando) {
            if (!quando) return;
            var novo = texto(quando);
            if (elemento.textContent !== novo) elemento.textContent = novo;
        }).catch(function () { });
    }

    function aplicar() {
        var alvos = document.querySelectorAll('[data-atualizacao]');
        return Promise.all(Array.prototype.map.call(alvos, aplicarEm));
    }

    window.atualizacaoDados = {
        formatar: formatar,
        texto: texto,
        buscar: buscar,
        aplicar: aplicar
    };

    function vigiar(elemento) {
        if (!window.MutationObserver) return;
        var observador = new MutationObserver(function () {
            aplicarEm(elemento);
        });
        observador.observe(elemento, { childList: true, characterData: true, subtree: true });
    }

    function iniciar() {
        var alvos = document.querySelectorAll('[data-atualizacao]');
        Array.prototype.forEach.call(alvos, vigiar);
        aplicar();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', iniciar);
    } else {
        iniciar();
    }
})();
