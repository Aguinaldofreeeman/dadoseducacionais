(() => {
  'use strict';
  const dados = Array.isArray(window.DADOS_PRESENCA) ? window.DADOS_PRESENCA : [];
  const periodo = document.querySelector('#filtro-periodo');
  const escola = document.querySelector('#filtro-escola');
  const busca = document.querySelector('#filtro-busca');
  const tbody = document.querySelector('#tabela-resultados');
  const status = document.querySelector('#status-filtro');
  const periodos = [...new Map(dados.map(r => [r.periodo, r.periodo_label])).entries()];
  const nf = new Intl.NumberFormat('pt-BR');
  const pf = new Intl.NumberFormat('pt-BR',{style:'percent',minimumFractionDigits:1,maximumFractionDigits:1});
  const df = new Intl.NumberFormat('pt-BR',{minimumFractionDigits:1,maximumFractionDigits:1,signDisplay:'exceptZero'});
  const n = v => Number.isFinite(Number(v)) ? Number(v) : 0;
  const pct = v => (v === '' || v === null || v === undefined) ? '-' : pf.format(n(v) > 1 ? n(v)/100 : n(v));
  const evol = v => {
    if (v === '' || v === null || v === undefined) return '<span>-</span>';
    const x=n(v) > 1 ? n(v)/100 : n(v); const classe=x>0?'positivo':x<0?'negativo':'';
    return `<span class="${classe}">${df.format(x*100)} p.p.</span>`;
  };
  const esc = v => String(v ?? '').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));

  function preencherPeriodos(){
    periodo.innerHTML = periodos.map(([v,l])=>`<option value="${esc(v)}">${esc(l)}</option>`).join('');
    periodo.value='geral';
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
    return den ? lista.reduce((s,r)=>s+n(r[campo])*n(r[peso]),0)/den : 0;
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
    const lista=filtrados(); renderResumo(lista); renderTabela(lista);
    const label=periodo.options[periodo.selectedIndex]?.textContent || '';
    status.textContent=`${nf.format(lista.length)} escola(s) exibida(s) em ${label}.`;
  }
  periodo.addEventListener('change',()=>{escola.value='';busca.value='';preencherEscolas();aplicar();});
  escola.addEventListener('change',aplicar); busca.addEventListener('input',aplicar);
  document.querySelector('#limpar-filtros').addEventListener('click',()=>{periodo.value='geral';busca.value='';preencherEscolas();escola.value='';aplicar();});
  preencherPeriodos(); preencherEscolas(); aplicar();
})();
