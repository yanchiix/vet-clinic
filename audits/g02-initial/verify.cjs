// Audit sources read-only; only verification-results.json is written.
const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'../..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
const srs=read('spec/SRS_Vet_Clinic_v0.1.tex'),matrix=read('docs/planning/traceability.md'),plan=read('docs/planning/implementation-plan.md'),risk=read('docs/planning/risk-register.md'),snap=JSON.parse(read('outputs/g02-audit/github-snapshot.json'));
const uniq=a=>[...new Set(a)],ids=(s,re)=>[...s.matchAll(re)].map(m=>m[1]),diff=(a,b)=>a.filter(x=>!b.includes(x));
function expand(s,prefix){
 const re=new RegExp('('+prefix+'(?:-(?:F|NF|DP))?)-(\\d{3})(?:[–—-](?:(?:'+prefix+')(?:-(?:F|NF|DP))?-)?(\\d{3}))?','g');
 return uniq([...s.matchAll(re)].flatMap(m=>Array.from({length:Number(m[3]||m[2])-Number(m[2])+1},(_,i)=>m[1]+'-'+String(Number(m[2])+i).padStart(3,'0')))).sort();
}
const req=ids(srs,/\\requirement\{(REQ-[A-Z]+-\d{3})\}/g),ac=ids(srs,/\\hypertarget\{(AC-[A-Z]+-\d{3})\}/g),bdd=ids(srs,/\\scenario\{(BDD-\d{3})\}/g);
const src=[...srs.matchAll(/^\\hyperlink\{(REQ-[A-Z]+-\d{3})\}.*$/gm)].map(m=>({req:m[1],ac:uniq(ids(m[0],/(AC-[A-Z]+-\d{3})/g)),bdd:uniq(ids(m[0],/(BDD-\d{3})/g)).sort()}));
const rows=matrix.split(/\r?\n/).filter(l=>/^\| REQ-(?:F|NF|DP)-\d{3} \|/.test(l)).map(l=>{const c=l.split('|').map(x=>x.trim());return {req:c[1],ac:expand(c[2],'AC'),bdd:expand(c[3],'BDD'),tickets:[...c[4].matchAll(/([A-Z]+\d{2}) \(#(\d+)\)/g)].map(m=>({id:m[1],number:Number(m[2])}))};});
const errors=[];
for(const r of rows){
 const s=src.find(x=>x.req===r.req);
 if(!s||JSON.stringify(s.ac)!==JSON.stringify(r.ac)||JSON.stringify(s.bdd)!==JSON.stringify(r.bdd))errors.push({type:'matrix',r,s});
 for(const t of r.tickets){const i=snap.issues.find(i=>i.issue_number===t.number);if(!i||!i.title.startsWith('['+t.id+']'))errors.push({type:'ticket',req:r.req,t});}
}
const comparisons=snap.issues.map(i=>{
 const expected=expand(i.body.split('### Source requirements')[1].split('### Related AC / BDD')[0],'REQ'),actual=rows.filter(r=>r.tickets.some(t=>t.number===i.issue_number)).map(r=>r.req).sort(),related=i.body.split('### Related AC / BDD')[1].split('### Dependencies')[0],expectedBDD=uniq(src.filter(r=>expected.includes(r.req)).flatMap(r=>r.bdd)).sort();
 return {number:i.issue_number,id:i.title.match(/^\[(.*?)\]/)[1],state:i.state,missing:diff(expected,actual),extra:diff(actual,expected),unknown:{req:diff(expand(i.body,'REQ'),req),ac:diff(expand(i.body,'AC'),ac),bdd:diff(expand(i.body,'BDD'),bdd)},missingRelatedBDD:diff(expectedBDD,expand(related,'BDD')),releaseWideException:i.issue_number===25};
});
const tasks=plan.split(/\r?\n/).map(l=>l.match(/^\| ([\w-]+) \| (Agent|Human) \| ([\d,]+) \| ([\d,]+) \| ([\d,]+) год \| (.*) \|$/)).filter(Boolean).map(m=>({id:m[1],resource:m[2],start:Number(m[3].replace(',','.')),end:Number(m[4].replace(',','.')),effort:Number(m[5].replace(',','.'))}));
const overlaps=[];
for(const resource of ['Agent','Human']){const ts=tasks.filter(t=>t.resource===resource).sort((a,b)=>a.start-b.start);for(let i=1;i<ts.length;i++)if(ts[i].start<ts[i-1].end)overlaps.push([ts[i-1].id,ts[i].id]);}
const fence=String.fromCharCode(96).repeat(3),chart=plan.split(fence+'mermaid')[1].split(fence)[0],nodes=[];
for(const l of chart.split(/\r?\n/)){
 const m=l.match(/^\s+([\w-]+) \[.*?\]\s+:(?:(crit), )?(\w+), (.*), (\d+)h$/);if(!m)continue;
 const preds=m[4].startsWith('after ')?m[4].slice(6).split(' '):[],start=preds.length?Math.max(...preds.map(p=>nodes.find(n=>n.key===p).end)):0;
 nodes.push({id:m[1],crit:!!m[2],key:m[3],preds,start,end:start+Number(m[5])/24,duration:Number(m[5])/24});
}
// Additional semantic prerequisites from plan sections 8, 11, 14.
const extra={intauth:['rf01','rf23','rf678'],intappt:['rf01','rf45','rf678'],intmed:['rf01','rf23','rf45','rf678','intappt'],intpet:['rf23','rf45','rf678'],g03prep:['intauth','intpet','intappt','intmed'],intops:['rf23','rf45','rf910']};
const graph=nodes.map(n=>({...n,preds:uniq([...n.preds,...(extra[n.key]||[])])}));
for(const resource of ['Agent','Human']){
 const ts=tasks.filter(t=>t.resource===resource).sort((a,b)=>a.start-b.start);
 for(let i=1;i<ts.length;i++){const n=graph.find(n=>n.id===ts[i].id),p=graph.find(n=>n.id===ts[i-1].id);n.preds=uniq([...n.preds,p.key]);}
}
const sorted=[],remaining=[...graph];
while(remaining.length){
 const ix=remaining.findIndex(n=>n.preds.every(p=>sorted.some(s=>s.key===p)));if(ix<0)break;
 const n=remaining.splice(ix,1)[0];n.es=n.preds.length?Math.max(...n.preds.map(p=>sorted.find(s=>s.key===p).ef)):0;n.ef=n.es+n.duration;sorted.push(n);
}
const horizon=Math.max(...sorted.map(n=>n.ef));
for(const n of [...sorted].reverse()){const successors=sorted.filter(s=>s.preds.includes(n.key));n.lf=successors.length?Math.min(...successors.map(s=>s.ls)):horizon;n.ls=n.lf-n.duration;n.slack=n.ls-n.es;}
const risks=risk.split(/\r?\n/).filter(l=>/^\| (TR|AI)-\d\d \|/.test(l)).map(l=>{const c=l.split('|').slice(1,-1).map(x=>x.trim());return {id:c[0],columns:c.length,empty:c.some(x=>!x),priorityCorrect:Number(c[7])*Number(c[8])===Number(c[9])};});
const result={
 counts:{requirements:req.length,uniqueREQ:uniq(req).length,ac:ac.length,uniqueAC:uniq(ac).length,bdd:bdd.length,uniqueBDD:uniq(bdd).length,srsMatrix:src.length,planningMatrix:rows.length},
 missingREQ:diff(req,rows.map(r=>r.req)),extraREQ:diff(rows.map(r=>r.req),req),matrixErrors:errors,uncovered:rows.filter(r=>!r.tickets.length).map(r=>r.req),
 functionalCoverageGaps:rows.filter(r=>/^REQ-(F|NF)-/.test(r.req)).filter(r=>!r.tickets.some(t=>/^F\d/.test(t.id))||!r.tickets.some(t=>/^(T|V|VAL|G)\d/.test(t.id))).map(r=>r.req),
 issues:comparisons,
 gantt:{tasks:tasks.length,chartTasks:nodes.length,chartDiff:tasks.filter(t=>{const n=nodes.find(n=>n.id===t.id);return !n||t.start!==n.start||t.end!==n.end;}).map(t=>t.id),overlaps,
 agentHours:tasks.filter(t=>t.resource==='Agent').reduce((s,t)=>s+t.effort,0),humanHours:tasks.filter(t=>t.resource==='Human').reduce((s,t)=>s+t.effort,0),
 effortMismatch:tasks.filter(t=>(t.end-t.start)*(t.resource==='Agent'?6:3)!==t.effort),horizon:Math.max(...tasks.map(t=>t.end)),cycleNodes:remaining.map(n=>n.id),resourceConstrainedHorizon:horizon,
 earliestScheduleMismatch:sorted.filter(n=>n.es!==n.start||n.ef!==n.end).map(n=>n.id),criticalMarksWithNonzeroSlack:sorted.filter(n=>n.crit&&n.slack>0).map(n=>({id:n.id,slack:n.slack})),
 calculatedSlack:sorted.map(n=>({id:n.id,slack:n.slack})),missingSemanticChartEdges:Object.entries(extra).flatMap(([key,preds])=>preds.filter(p=>!nodes.find(n=>n.key===key).preds.includes(p)).map(p=>({from:p,to:key})))},
 risks:{traditional:risks.filter(r=>r.id.startsWith('TR')).length,ai:risks.filter(r=>r.id.startsWith('AI')).length,invalid:risks.filter(r=>r.columns!==13||r.empty||!r.priorityCorrect)},
 limitations:['ID checks are not semantic or functional tests.','CPM assumes fixed resource order, GO decisions, ready DEP/BK-168H.','Red preparation, ongoing D01 and DEP decision effort cannot be inferred from numeric rows.']
};
fs.writeFileSync(path.join(__dirname,'verification-results.json'),JSON.stringify(result,null,2)+'\n','utf8');
console.log(JSON.stringify({...result,issues:comparisons.map(i=>({...i,missing:i.releaseWideException?'95 rows omitted for release-wide G04':i.missing})),gantt:{...result.gantt,calculatedSlack:undefined,missingSemanticChartEdges:undefined}},null,2));
