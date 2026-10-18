// Independent repeat audit. No writes to sources or historical audit files.
// Feed the b1a6cd8 implementation-plan.md on stdin (UTF-8) for historical replay.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),vm=require('vm');
const root=path.resolve(__dirname,'../..');
const read=p=>fs.readFileSync(path.resolve(root,p),'utf8');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const plan=read('docs/planning/implementation-plan.md'),lines=plan.split(/\r?\n/);
const cells=l=>l.split('|').slice(1,-1).map(x=>x.trim());
const num=s=>Number(s.replace(',','.').replace(/\s*год.*$/,''));
const tasks=lines.filter(l=>/^\| [\w-]+ \| (Agent|Human) \|/.test(l)).map(l=>{
 const c=cells(l);return {id:c[0],role:c[1],start:num(c[2]),end:num(c[3]),hours:num(c[4])};
});
const taskMap=new Map(tasks.map(t=>[t.id,t]));
const nodes=lines.map(l=>l.match(/^\s+([\w-]+) \[.*?\]\s+:(crit,\s*)?(\w+),\s*(.+),\s*(\d+)h$/)).filter(Boolean).map(m=>({id:m[1],key:m[3],crit:!!m[2],pred:m[4].startsWith('after ')?m[4].slice(6).split(/\s+/):[],duration:Number(m[5])/24}));
const byKey=new Map(nodes.map(n=>[n.key,n]));
function solve(addResourceOrder){
 const graph=nodes.map(n=>({...n,pred:[...n.pred]}));
 if(addResourceOrder)for(const role of ['Agent','Human']){
  const seq=tasks.filter(t=>t.role===role).sort((a,b)=>a.start-b.start);
  for(let i=1;i<seq.length;i++){
   const n=graph.find(n=>n.id===seq[i].id),p=graph.find(n=>n.id===seq[i-1].id);
   if(!n.pred.includes(p.key))n.pred.push(p.key);
  }
 }
 const order=[],pending=[...graph];
 while(pending.length){
  const ready=pending.filter(n=>n.pred.every(p=>order.some(o=>o.key===p)));
  if(!ready.length)break;
  for(const n of ready){n.es=Math.max(0,...n.pred.map(p=>order.find(o=>o.key===p).ef));n.ef=n.es+n.duration;order.push(n);pending.splice(pending.indexOf(n),1);}
 }
 const horizon=Math.max(...order.map(n=>n.ef));
 for(const n of [...order].reverse()){const next=order.filter(s=>s.pred.includes(n.key));n.lf=next.length?Math.min(...next.map(s=>s.ls)):horizon;n.ls=n.lf-n.duration;n.slack=n.ls-n.es;}
 return {horizon,unresolved:pending.map(n=>n.id),nodes:order};
}
const mermaid=solve(false),resource=solve(true),overlaps=[];
for(const role of ['Agent','Human']){
 const ts=tasks.filter(t=>t.role===role);
 for(let i=0;i<ts.length;i++)for(let j=i+1;j<ts.length;j++)if(Math.max(ts[i].start,ts[j].start)<Math.min(ts[i].end,ts[j].end))overlaps.push([ts[i].id,ts[j].id]);
}
const semantic={intauth:['rf01','rf23','rf678'],intappt:['rf01','rf45','rf678'],intmed:['rf01','rf23','rf45','rf678','intappt'],intpet:['rf23','rf45','rf678'],g03prep:['intauth','intpet','intappt','intmed'],intops:['rf23','rf45','rf910'],testinfra:['g02'],f01:['testinfra'],v02pre:['g03','intops'],valfix:['valexec','evidpre']};
const semanticMissing=Object.entries(semantic).flatMap(([k,ps])=>ps.filter(p=>!byKey.get(k).pred.includes(p)).map(p=>p+' -> '+k));
const featureRows=lines.filter(l=>/^\| F\d{2}-LG \| (T\d|Issue-local)/.test(l)).map(l=>{
 const c=cells(l),parts=c.slice(2,6).map(num),total=num(c[6]),t=taskMap.get(c[0]),date=c[7].match(/D(\d+,\d+)/);
 return {id:c[0],parts,total,sum:parts.reduce((a,b)=>a+b,0),scheduleHours:t.hours,earliestCodeDay:t.start+parts[0]/6,printedCodeDay:date?num(date[1]):null};
});
const intRows=lines.filter(l=>/^\| INT-[A-Z]+ \|/.test(l)).map(cells).filter(c=>c.length===6&&/^\d+(?:,\d+)? год$/.test(c[2])&&c[1]!=='Agent').map(c=>({id:c[0],parts:c.slice(2,5).map(num),total:num(c[5])}));
const infraRows=lines.slice(lines.findIndex(l=>l.startsWith('| Склад')),lines.findIndex(l=>l.startsWith('| Склад'))+9).filter(l=>/^\|/.test(l)&&/^\d+ год$/.test(cells(l)[1]||'')).map(cells).map(c=>({work:c[0],hours:num(c[1])}));
const archiveFiles=fs.readdirSync(path.join(root,'audits/g02-initial')).filter(f=>fs.statSync(path.join(root,'audits/g02-initial',f)).isFile());
const pairs=archiveFiles.map(f=>{const a=fs.readFileSync(path.join(root,'audits/g02-initial',f)),b=fs.readFileSync(path.join(root,'outputs/g02-audit',f));return {file:f,bytes:a.length,sha256:sha(a),equal:a.equals(b)};});
const links=[];
for(const f of ['audits/g02-initial/report.md','logs/plan-gate.md','logs/project-journal.md']){
 for(const m of read(f).matchAll(/\]\(([^)]+)\)/g)){if(!/^https?:/.test(m[1]))links.push({source:f,target:m[1],exists:fs.existsSync(path.resolve(root,path.dirname(f),m[1]))});}
}
const secretPatterns=[/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/g,/\bgh[pousr]_[A-Za-z0-9]{20,}\b/g,/\bgithub_pat_[A-Za-z0-9_]{20,}\b/g,/\bAKIA[0-9A-Z]{16}\b/g];
const secretCandidates=archiveFiles.flatMap(f=>secretPatterns.map((p,i)=>({file:f,pattern:i,count:[...read('audits/g02-initial/'+f).matchAll(p)].length}))).filter(x=>x.count);
const sourceFiles=['docs/planning/implementation-plan.md','logs/plan-gate.md','logs/project-journal.md','spec/SRS_Vet_Clinic_v0.1.tex','spec/SRS_Vet_Clinic_v0.1_addendum_001.md','docs/planning/traceability.md','docs/planning/risk-register.md','docs/planning/v02-planning-audit.md'];
const code=read('audits/g02-initial/verify.cjs');
function replay(planOverride){
 let captured;
 const virtualFs={
  readFileSync(p,enc){const rel=path.relative(root,p).split(path.sep).join('/');if(rel==='docs/planning/implementation-plan.md'&&planOverride!==undefined)return planOverride;if(rel==='outputs/g02-audit/github-snapshot.json')return read('audits/g02-initial/github-snapshot.json');return fs.readFileSync(p,enc);},
  writeFileSync(p,data){if(path.basename(p)!=='verification-results.json')throw Error('Unexpected write');captured=JSON.parse(data);}
 };
 vm.runInNewContext(code,{require:n=>{if(n==='fs')return virtualFs;if(n==='path')return path;throw Error('Unexpected module '+n);},__dirname:path.join(root,'audits/g02-initial'),console:{log(){}}},{timeout:10000});
 return captured;
}
const historicalPlan=fs.readFileSync(0,'utf8').replace(/^\uFEFF/,'');
const oldResult=JSON.parse(read('audits/g02-initial/verification-results.json'));
const replayOld=historicalPlan.trim()?replay(historicalPlan):null,replayCurrent=replay();
const snapshot=JSON.parse(read('audits/g02-initial/github-snapshot.json'));
const result={
 sourceHashes:sourceFiles.map(f=>({file:f,sha256:sha(fs.readFileSync(path.join(root,f)))})),
 schedule:{tasks:tasks.length,uniqueTasks:taskMap.size,mermaidTasks:nodes.length,agentHours:tasks.filter(t=>t.role==='Agent').reduce((s,t)=>s+t.hours,0),humanHours:tasks.filter(t=>t.role==='Human').reduce((s,t)=>s+t.hours,0),horizon:resource.horizon,overlaps,cycles:resource.unresolved,
 tableVsMermaid:mermaid.nodes.filter(n=>{const t=taskMap.get(n.id);return !t||t.start!==n.es||t.end!==n.ef;}).map(n=>n.id),
 resourceOrderChanges:resource.nodes.filter(n=>{const t=taskMap.get(n.id);return t.start!==n.es||t.end!==n.ef;}).map(n=>n.id),
 effortMismatches:tasks.filter(t=>(t.end-t.start)*(t.role==='Agent'?6:3)!==t.hours),semanticMissing,
 critMismatch:resource.nodes.filter(n=>n.crit!==(n.slack===0)).map(n=>({id:n.id,slack:n.slack,crit:n.crit})),
 slack:resource.nodes.map(n=>({id:n.id,slack:n.slack})),infrastructure:tasks.find(t=>t.id==='TEST-INFRA'),f01:tasks.find(t=>t.id==='F01-LG')},
 budgets:{infrastructure:infraRows,infrastructureTotal:infraRows.reduce((s,r)=>s+r.hours,0),features:featureRows,featureColumnTotals:[0,1,2,3].map(i=>featureRows.reduce((s,r)=>s+r.parts[i],0)),integration:intRows,integrationColumnTotals:[0,1,2].map(i=>intRows.reduce((s,r)=>s+r.parts[i],0))},
 archive:{copies:pairs,brokenRelativeLinks:links.filter(x=>!x.exists),relativeLinksChecked:links.length,secretPatternCandidates:secretCandidates,issueSnapshotCount:snapshot.issues.length,nonNullEmails:snapshot.issues.filter(i=>i.user?.email).length,
 historicalReplayMatches:replayOld?JSON.stringify(replayOld)===JSON.stringify(oldResult):null,historicalReplayGantt:replayOld?{tasks:replayOld.gantt.tasks,hours:replayOld.gantt.agentHours,horizon:replayOld.gantt.horizon}:null,
 currentReplayGantt:{tasks:replayCurrent.gantt.tasks,hours:replayCurrent.gantt.agentHours,horizon:replayCurrent.gantt.horizon},replayMethod:'Unmodified archived source executed in VM; reads remapped, writes captured in memory; old plan supplied from Git on stdin. No historical files overwritten.'},
 baselineChecks:{counts:replayCurrent.counts,matrixErrors:replayCurrent.matrixErrors,coverageGaps:replayCurrent.functionalCoverageGaps},
 limits:['Fixed resource order; ready external prerequisites assumed.','Estimation confidence is a qualitative audit judgement, not established by sums.','Secret scan is pattern-based and supplemented by content review.','Current source SHA-256 anchors uncommitted input.']
};
fs.writeFileSync(path.join(__dirname,'results.json'),JSON.stringify(result,null,2)+'\n','utf8');
console.log(JSON.stringify(result,null,2));
