(() => {
  'use strict';
  let dados = Array.isArray(window.DADOS_PRESENCA) ? window.DADOS_PRESENCA : [];
  const periodo = document.querySelector('#filtro-periodo');
  const escola = document.querySelector('#filtro-escola');
  const busca = document.querySelector('#filtro-busca');
  const tbody = document.querySelector('#tabela-resultados');
  const status = document.querySelector('#status-filtro');
  let periodos = [];
  let avisoFonte = '';
  const nf = new Intl.NumberFormat('pt-BR');
  const pf = new Intl.NumberFormat('pt-BR',{style:'percent',minimumFractionDigits:1,maximumFractionDigits:1});
  const df = new Intl.NumberFormat('pt-BR',{minimumFractionDigits:1,maximumFractionDigits:1,signDisplay:'exceptZero'});
  const n = v => Number.isFinite(Number(v)) ? Number(v) : 0;
  const taxa = v => n(v) > 2 ? n(v)/100 : n(v);
  const pct = v => (v === '' || v === null || v === undefined) ? '-' : pf.format(taxa(v));
  const evol = v => {
    if (v === '' || v === null || v === undefined) return '<span>-</span>';
    const x=n(v) > 1 ? n(v)/100 : n(v); const classe=x>0?'positivo':x<0?'negativo':'';
    return `<span class="${classe}">${df.format(x*100)} p.p.</span>`;
  };
  const esc = v => String(v ?? '').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));

  function preencherPeriodos(){
    periodo.innerHTML = periodos.map(([v,l])=>`<option value="${esc(v)}">${esc(l)}</option>`).join('');
    periodo.value=periodos.some(([valor])=>valor==='geral')?'geral':(periodos[0]?.[0] || '');
  }
  function escolasDoPeriodo(){
    const p=periodo.value;
    return [...new Map(dados.filter(r=>r.periodo===p).map(r=>[r.codigo_escola || r.escola,r])).values()].sort((a,b)=>a.escola.localeCompare(b.escola,'pt-BR'));
  }
  function preencherEscolas(){
    const anterior=escola.value;
    const lista=escolasDoPeriodo();
    escola.innerHTML='<option value="">Todas as escolas</option>'+lista.map(r=>`<option value="${esc(r.codigo_escola || r.escola)}">${esc(r.escola)}${r.codigo_escola?' - '+esc(r.codigo_escola):''}</option>`).join('');
    if ([...escola.options].some(o=>o.value===anterior)) escola.value=anterior;
  }
  function filtrados(){
    const termo=busca.value.trim().toLocaleLowerCase('pt-BR');
    return dados.filter(r=>r.periodo===periodo.value)
      .filter(r=>!escola.value || (r.codigo_escola || r.escola)===escola.value)
      .filter(r=>!termo || `${r.escola} ${r.codigo_escola}`.toLocaleLowerCase('pt-BR').includes(termo));
  }
  function ponderada(lista,campo,peso){
    const den=lista.reduce((s,r)=>s+n(r[peso]),0);
    return den ? lista.reduce((s,r)=>s+taxa(r[campo])*n(r[peso]),0)/den : 0;
  }
  function renderResumo(lista){
    const set=(id,v)=>document.querySelector(id).textContent=v;
    set('#kpi-escolas',nf.format(new Set(lista.map(r=>r.codigo_escola || r.escola)).size));
    set('#kpi-matriculas',nf.format(lista.reduce((s,r)=>s+n(r.matriculas_ativas),0)));
    set('#kpi-presenca',lista.length?pct(ponderada(lista,'presenca','matriculas_ativas')):'-');
    set('#kpi-aulas',lista.length?pct(ponderada(lista,'aulas_dadas','aulas_previstas')):'-');
    set('#kpi-turmas',nf.format(lista.reduce((s,r)=>s+n(r.total_turmas),0)));
    set('#kpi-pei',nf.format(lista.filter(r=>String(r.pei)==='1').length));
  }
  function renderGraficoPeriodo(id,serie,selecionado,cor){
    const container=document.querySelector(id);
    if(!serie.length){
      container.innerHTML='<div class="chart-empty">Não há períodos suficientes para exibir a evolução.</div>';
      return;
    }

    const valores=serie.map(item=>item.valor);
    const escala=Math.max(1,Math.ceil(Math.max(...valores)*2)/2);
    const largura=680,altura=245,esquerda=54,direita=18,topo=16,base=205;
    const larguraGrafico=largura-esquerda-direita,alturaGrafico=base-topo;
    const pontos=serie.map((item,indice)=>{
      const x=serie.length===1?esquerda+larguraGrafico/2:esquerda+indice*larguraGrafico/(serie.length-1);
      const y=base-Math.max(0,Math.min(escala,item.valor))*alturaGrafico/escala;
      return {...item,x,y};
    });
    const linhasGrade=[];
    for(let valor=0;valor<=escala;valor+=0.5){
      const y=base-valor*alturaGrafico/escala;
      linhasGrade.push(`<line class="chart-gridline" x1="${esquerda}" y1="${y}" x2="${largura-direita}" y2="${y}"></line><text class="chart-axis-label" x="${esquerda-8}" y="${y+4}" text-anchor="end">${pct(valor)}</text>`);
    }
    const caminho=pontos.map((ponto,indice)=>`${indice?'L':'M'} ${ponto.x} ${ponto.y}`).join(' ');
    const marcadores=pontos.map(ponto=>{
      const atual=ponto.periodo===selecionado;
      return `<circle class="chart-point${atual?' chart-point-current':''}" cx="${ponto.x}" cy="${ponto.y}" r="${atual?6:4}"><title>${esc(ponto.rotulo)}: ${pct(ponto.valor)}</title></circle><text class="chart-axis-label" x="${ponto.x}" y="${base+22}" text-anchor="middle">${esc(ponto.periodo)}</text>`;
    }).join('');
    const acessivel=serie.map(item=>`${item.rotulo}: ${pct(item.valor)}`).join('; ');
    container.innerHTML=`<svg class="chart-svg" viewBox="0 0 ${largura} ${altura}" role="img" aria-label="${esc(acessivel)}" style="--chart-color:${cor}"><title>${esc(acessivel)}</title>${linhasGrade.join('')}<line class="chart-baseline" x1="${esquerda}" y1="${base}" x2="${largura-direita}" y2="${base}"></line><path class="chart-line" d="${caminho}"></path>${marcadores}</svg><p class="chart-footnote">Marcador preenchido destaca o período selecionado. Passe o cursor sobre os pontos para ver o rótulo completo.</p>`;
  }
  function renderRanking(id,lista,campo,cor){
    const container=document.querySelector(id);
    if(!lista.length){
      container.innerHTML='<div class="chart-empty">Nenhuma escola disponível para este recorte.</div>';
      return;
    }

    const ordenados=lista.slice().sort((a,b)=>taxa(b[campo])-taxa(a[campo])||a.escola.localeCompare(b.escola,'pt-BR')).slice(0,6);
    const escala=Math.max(1,Math.ceil(Math.max(...ordenados.map(item=>taxa(item[campo])))*4)/4);
    container.innerHTML=ordenados.map(item=>{
      const valor=taxa(item[campo]);
      const nome=item.escola+(item.codigo_escola?` · ${item.codigo_escola}`:'');
      return `<div class="ranking-row"><span class="ranking-name" title="${esc(nome)}">${esc(nome)}</span><strong class="ranking-value">${pct(item[campo])}</strong><div class="ranking-track" role="img" aria-label="${esc(nome)}: ${pct(item[campo])}"><div class="ranking-fill" style="width:${Math.max(0,Math.min(100,valor/escala*100))}%;--bar-color:${cor}"></div></div></div>`;
    }).join('');
  }
  function renderDashboard(lista){
    const termo=busca.value.trim().toLocaleLowerCase('pt-BR');
    const escolasSelecionadas=new Set(dados
      .filter(r=>!escola.value||String(r.codigo_escola||r.escola)===escola.value)
      .filter(r=>!termo||`${r.escola} ${r.codigo_escola}`.toLocaleLowerCase('pt-BR').includes(termo))
      .map(r=>String(r.codigo_escola||r.escola)));
    const historico=dados.filter(r=>escolasSelecionadas.has(String(r.codigo_escola||r.escola)));
    let periodosGrafico=[...new Map(historico.map(r=>[String(r.periodo),String(r.periodo_label||r.periodo)])).entries()];
    if(periodosGrafico.some(([valor])=>valor!=='geral')){
      periodosGrafico=periodosGrafico.filter(([valor])=>valor!=='geral');
    }
    periodosGrafico.sort(([a],[b])=>a.localeCompare(b,'pt-BR',{numeric:true}));

    const definicoes=[
      {campo:'presenca',peso:'matriculas_ativas',grafico:'#chart-presenca',resumo:'#resumo-presenca',variacao:'#delta-presenca',cor:'#17365d'},
      {campo:'aulas_dadas',peso:'aulas_previstas',grafico:'#chart-aulas',resumo:'#resumo-aulas',variacao:'#delta-aulas',cor:'#0d9488'}
    ];
    definicoes.forEach(({campo,peso,grafico,resumo,variacao,cor})=>{
      const serie=periodosGrafico.map(([periodoKey,rotulo])=>{
        const registros=historico.filter(r=>String(r.periodo)===periodoKey);
        const pesoTotal=registros.reduce((total,r)=>total+n(r[peso]),0);
        return {periodo:periodoKey,rotulo,valor:pesoTotal?ponderada(registros,campo,peso):null};
      }).filter(item=>item.valor!==null);
      const resumoEl=document.querySelector(resumo);
      const variacaoEl=document.querySelector(variacao);
      if(serie.length){
        const indiceSelecionado=serie.findIndex(item=>item.periodo===periodo.value);
        const indiceAtual=indiceSelecionado>=0?indiceSelecionado:serie.length-1;
        const atual=serie[indiceAtual];
        resumoEl.textContent=pct(atual.valor);
        if(indiceAtual>0){
          const anterior=serie[indiceAtual-1];
          const diferenca=(atual.valor-anterior.valor)*100;
          variacaoEl.textContent=`${atual.periodo}: ${df.format(diferenca)} p.p. vs. ${anterior.periodo}`;
          variacaoEl.className=diferenca>0?'positivo':diferenca<0?'negativo':'';
        }else{
          variacaoEl.textContent=`${atual.periodo} · Sem período anterior para comparar`;
          variacaoEl.className='';
        }
      }else{
        resumoEl.textContent='-';
        variacaoEl.textContent='';
      }
      renderGraficoPeriodo(grafico,serie,periodo.value,cor);
    });

    renderRanking('#ranking-presenca',lista,'presenca','#17365d');
    renderRanking('#ranking-aulas',lista,'aulas_dadas','#0d9488');
  }
  function renderTabela(lista){
    if(!lista.length){tbody.innerHTML='<tr><td class="vazio" colspan="12">Nenhum resultado encontrado para os filtros selecionados.</td></tr>';return;}
    tbody.innerHTML=lista.map(r=>`<tr>
      <td><strong>${esc(r.escola)}</strong></td><td>${esc(r.codigo_escola)||'-'}</td>
      <td><span class="badge ${String(r.pei)==='1'?'badge-sim':'badge-nao'}">${String(r.pei)==='1'?'Sim':'Não'}</span></td>
      <td>${nf.format(n(r.matriculas_ativas))}</td><td>${pct(r.presenca)}</td><td>${evol(r.evolucao_presenca)}</td>
      <td>${nf.format(n(r.aulas_previstas))}</td><td>${pct(r.aulas_dadas)}</td><td>${evol(r.evolucao_aulas)}</td>
      <td>${nf.format(n(r.total_turmas))}</td><td>${nf.format(n(r.total_matrizes))}</td><td>${esc(r.supervisor)||'-'}</td>
    </tr>`).join('');
  }
  function aplicar(){
    const lista=filtrados(); renderResumo(lista); renderDashboard(lista); renderTabela(lista);
    const label=periodo.options[periodo.selectedIndex]?.textContent || '';
    status.textContent=`${nf.format(lista.length)} escola(s) exibida(s) em ${label}.${avisoFonte}`;
  }
  periodo.addEventListener('change',()=>{escola.value='';busca.value='';preencherEscolas();aplicar();});
  escola.addEventListener('change',aplicar); busca.addEventListener('input',aplicar);
  document.querySelector('#limpar-filtros').addEventListener('click',()=>{periodo.value=periodos.some(([valor])=>valor==='geral')?'geral':(periodos[0]?.[0] || '');busca.value='';preencherEscolas();escola.value='';aplicar();});

  function atualizarDados(novosDados) {
    dados = novosDados;
    periodos = [...new Map(dados.map(r => [r.periodo, r.periodo_label])).entries()];
    preencherPeriodos();
    preencherEscolas();
    aplicar();
  }

  atualizarDados(dados);
  async function carregarDadosSupabase(){
    const tamanhoPagina=1000;
    const todos=[];
    for(let inicio=0;;inicio+=tamanhoPagina){
      const {data,error}=await supabaseClient
        .from('resultados_presenca')
        .select('periodo, periodo_label, escola, codigo_escola, pei, matriculas_ativas, presenca, evolucao_presenca, aulas_previstas, aulas_dadas, evolucao_aulas, total_turmas, total_matrizes, tipo_escola, supervisor')
        .order('periodo')
        .order('codigo_escola')
        .range(inicio,inicio+tamanhoPagina-1);
      if(error) throw error;
      todos.push(...(data||[]));
      if(!data||data.length<tamanhoPagina) return todos;
    }
  }

  if (typeof supabaseClient !== 'undefined') {
    carregarDadosSupabase()
      .then(data => {
        if (data?.length) {
          avisoFonte = ' Dados carregados do Supabase.';
          atualizarDados(data);
        } else {
          avisoFonte = ' Tabela no Supabase vazia; exibindo os dados locais.';
          aplicar();
        }
      })
      .catch(erro => {
        console.error('Erro ao carregar resultados de presença do Supabase:', erro);
        avisoFonte = ' Não foi possível consultar o Supabase; exibindo os dados locais.';
        aplicar();
      });
  }
})();
