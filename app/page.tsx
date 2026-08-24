"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { AlertTriangle, ArrowUpRight, Bell, BriefcaseBusiness, CalendarDays, Check, ChevronDown, Clock3, FileText, Inbox, LayoutDashboard, Menu, MessageSquareText, MoreHorizontal, Phone, Plus, Search, Settings, ShieldCheck, Sparkles, UserRoundCheck, Users, X } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

type Application = { id:string; name:string; initials:string; role:string; source:string; received:string; owner:string; status:string; nextAction:string; due:string; lastContact:string; acknowledged:boolean; tone:string };

const applications: Application[] = [
 {id:"DEMO-0142",name:"Demo Candidate 01",initials:"D1",role:"Sales Development Representative",source:"LinkedIn",received:"Today, 9:42 AM",owner:"Recruiter A",status:"New application",nextAction:"Review application",due:"Today, 4:00 PM",lastContact:"Not yet contacted",acknowledged:false,tone:"violet"},
 {id:"DEMO-0141",name:"Demo Candidate 02",initials:"D2",role:"Medical Biller – Orthopedic",source:"JobStreet",received:"Today, 8:15 AM",owner:"Unassigned",status:"New application",nextAction:"Assign recruiter",due:"Overdue 1h",lastContact:"Auto-acknowledged 8:16 AM",acknowledged:true,tone:"blue"},
 {id:"DEMO-0138",name:"Demo Candidate 03",initials:"D3",role:"Property Investment Assistant",source:"Google Forms",received:"Yesterday, 3:28 PM",owner:"Recruiter B",status:"Phone screening",nextAction:"Send pre-call message",due:"Today, 2:30 PM",lastContact:"Yesterday, 4:02 PM",acknowledged:true,tone:"orange"},
 {id:"DEMO-0134",name:"Demo Candidate 04",initials:"D4",role:"Digital Marketing Associate",source:"Referral",received:"Aug 23, 11:05 AM",owner:"Recruiter C",status:"Awaiting client feedback",nextAction:"Send holding update",due:"Overdue 6h",lastContact:"Aug 23, 3:40 PM",acknowledged:true,tone:"green"},
 {id:"DEMO-0127",name:"Demo Candidate 05",initials:"D5",role:"Client Services Coordinator",source:"Facebook",received:"Aug 22, 7:50 PM",owner:"Recruiter A",status:"Interview scheduled",nextAction:"Buddy review invite",due:"Today, 5:00 PM",lastContact:"Yesterday, 10:14 AM",acknowledged:true,tone:"pink"},
];

const nav = [
 ["Dashboard",LayoutDashboard],["Application Inbox",Inbox],["Candidates",Users],["Vacancies",BriefcaseBusiness],["Interviews",CalendarDays],["Communications",MessageSquareText],["Active Pool",UserRoundCheck],["Offers",FileText],["Onboarding Documents",ShieldCheck],["Recruitment Tasks",Check],["Team Performance",Sparkles],["Reports",ArrowUpRight],["Templates & Settings",Settings]
] as const;

export default function Page(){
 const router=useRouter(); const [active,setActive]=useState("Dashboard"); const [query,setQuery]=useState(""); const [status,setStatus]=useState("All statuses"); const [callCandidate,setCallCandidate]=useState<Application|null>(null); const [purpose,setPurpose]=useState(""); const [messageSent,setMessageSent]=useState(false); const [ack,setAck]=useState(false); const [scheduled,setScheduled]=useState(""); const [mobile,setMobile]=useState(false); const [liveApplications,setLiveApplications]=useState<Application[]>([]); const [dataReady,setDataReady]=useState(false);
 useEffect(()=>{let mounted=true;async function load(){const supabase=createClient();const {data:{user}}=await supabase.auth.getUser();if(!user){router.replace("/login");return}const {data}=await supabase.from("application_overview").select("*").order("next_action_due",{ascending:true,nullsFirst:false});if(mounted&&data){setLiveApplications(data.map((row,index)=>({id:row.application_code,name:row.candidate_name,initials:initials(row.candidate_name),role:row.position_title,source:row.source,received:"Received",owner:row.owner_name||"Unassigned",status:row.status,nextAction:row.next_action||"Set next action",due:formatDate(row.next_action_due),lastContact:formatDate(row.last_communication_at,"Not yet contacted"),acknowledged:Boolean(row.last_communication_at),tone:["violet","blue","orange","green","pink"][index%5]})));setDataReady(true)}}load();return()=>{mounted=false}},[router]);
 const source=liveApplications.length?liveApplications:applications;
 const filtered=useMemo(()=>source.filter(a=>(a.name+a.role+a.id).toLowerCase().includes(query.toLowerCase())&&(status==="All statuses"||a.status===status)),[query,status,source]);
 const canCall=purpose&&messageSent&&scheduled;
 return <div className="shell">
  <aside className={mobile?"sidebar open":"sidebar"}>
   <div className="brand"><div className="brandmark">S</div><div><b>Scale Up</b><span>Recruitment Hub</span></div><button className="closeMobile" onClick={()=>setMobile(false)}><X size={18}/></button></div>
   <nav>{nav.map(([label,Icon])=><button key={label} className={active===label?"nav active":"nav"} onClick={()=>{setActive(label);setMobile(false)}}><Icon size={18}/><span>{label}</span>{label==="Application Inbox"&&<em>8</em>}</button>)}</nav>
   <div className="profile"><div className="avatar">RA</div><div><b>Recruiter A</b><span>Recruiter</span></div><MoreHorizontal size={18}/></div>
  </aside>
  {mobile&&<div className="shade" onClick={()=>setMobile(false)}/>} 
  <main>
   <header><button className="menu" onClick={()=>setMobile(true)}><Menu/></button><div className="search"><Search size={18}/><input placeholder="Search candidates, roles, or reference…" value={query} onChange={e=>setQuery(e.target.value)}/><kbd>⌘ K</kbd></div><button className="iconBtn"><Bell size={19}/><i/></button><button className="primary"><Plus size={18}/> New application</button></header>
   <div className="content">
    <section className="welcome"><div><p>Tuesday, August 25</p><h1>Good morning, Recruiter <span>👋</span></h1><h2>Here’s what needs your attention today.</h2></div><button className="outline"><Sparkles size={17}/> View my priorities</button></section>
    <section className="alerts">
     <Alert title="Unacknowledged" count="3" note="Oldest waiting 2h 18m" kind="red" icon={<Inbox/>}/>
     <Alert title="Missing next action" count="5" note="Requires assignment" kind="amber" icon={<AlertTriangle/>}/>
     <Alert title="Updates overdue" count="7" note="No update within 48h" kind="purple" icon={<Clock3/>}/>
     <Alert title="Awaiting buddy review" count="2" note="Next interview at 5 PM" kind="blue" icon={<CalendarDays/>}/>
    </section>
    <section className="grid">
     <div className="panel applications"><div className="panelHead"><div><h3>Application inbox</h3><p>Prioritized by SLA and next-action date</p></div><button className="link" onClick={()=>setActive("Application Inbox")}>View all <ArrowUpRight size={15}/></button></div>
      <div className="filters"><div className="miniSearch"><Search size={16}/><input placeholder="Search applications" value={query} onChange={e=>setQuery(e.target.value)}/></div><div className="select"><select value={status} onChange={e=>setStatus(e.target.value)}><option>All statuses</option>{[...new Set(source.map(a=>a.status))].map(s=><option key={s}>{s}</option>)}</select><ChevronDown size={15}/></div><span className="connectionState"><i/>{dataReady?"Supabase connected":"Connecting…"}</span></div>
      <div className="tableWrap"><table><thead><tr><th>Candidate</th><th>Status</th><th>Owner</th><th>Next action</th><th>Last contact</th><th></th></tr></thead><tbody>{filtered.map(a=><tr key={a.id} className={!a.acknowledged?"urgent":""}><td><div className="candidate"><span className={`person ${a.tone}`}>{a.initials}</span><div><b>{a.name}</b><small>{a.role}</small><small>{a.source} · {a.id}</small></div></div></td><td><span className="statusDot">{a.status}</span></td><td><span className={a.owner==="Unassigned"?"unassigned":""}>{a.owner}</span></td><td><button className="action" onClick={()=>a.nextAction.includes("call")&&setCallCandidate(a)}>{a.nextAction}<small className={a.due.includes("Overdue")?"overdue":""}>{a.due}</small></button></td><td><span className={!a.acknowledged?"noContact":""}>{a.lastContact}</span></td><td><button className="dots"><MoreHorizontal/></button></td></tr>)}</tbody></table></div>
     </div>
     <aside className="rightcol">
      <div className="panel"><div className="panelHead"><div><h3>Today’s workload</h3><p>Your assigned priorities</p></div></div><div className="workload"><Ring/><div className="legend"><p><i className="l1"/>Screenings <b>4</b></p><p><i className="l2"/>Follow-ups <b>6</b></p><p><i className="l3"/>Interviews <b>2</b></p><p><i className="l4"/>Reviews <b>3</b></p></div></div><button className="full">Open my task list</button></div>
      <div className="panel attention"><div className="panelHead"><div><h3>Needs attention</h3><p>Operational risks</p></div></div><Attention icon={<BriefcaseBusiness/>} title="2 filled vacancies" text="Still have active job posts"/><Attention icon={<ShieldCheck/>} title="1 early document request" text="Sensitive document policy flag"/><Attention icon={<Users/>} title="3 active-pool follow-ups" text="30-day reconfirmation overdue"/></div>
     </aside>
    </section>
   </div>
  </main>
  {callCandidate&&<div className="modalBackdrop"><div className="modal"><button className="modalClose" onClick={()=>setCallCandidate(null)}><X/></button><div className="modalIcon"><Phone/></div><p className="eyebrow">MESSAGE-FIRST CALL</p><h2>Prepare call with {callCandidate.name}</h2><div className="ownership"><AlertTriangle size={18}/><p>This candidate is currently assigned to <b>{callCandidate.owner}</b>. Last communication was on <b>{callCandidate.lastContact}</b>.</p></div><label>Call purpose <span>*</span><select value={purpose} onChange={e=>setPurpose(e.target.value)}><option value="">Select purpose</option><option>Phone screening</option><option>Application update</option><option>Interview coordination</option><option>Offer discussion</option></select></label><label>Confirmed phone number <span>*</span><input value="Demo number on file" readOnly/></label><div className="template"><p>Hi Candidate, this is Recruiter A from Scale Up Philippines. I’m contacting you regarding your application for the {callCandidate.role} role. May I call you within the next 5–10 minutes to discuss {purpose||"[purpose]"}? Please let me know if you are available. Thank you.</p><button onClick={()=>setMessageSent(true)}>{messageSent?<><Check/> Message recorded</>:<><MessageSquareText/> Send / record message</>}</button></div><div className="checks"><label><input type="checkbox" checked={ack} onChange={e=>setAck(e.target.checked)}/> Candidate acknowledged</label><label>Expected call time <span>*</span><input type="time" value={scheduled} onChange={e=>setScheduled(e.target.value)}/></label></div><div className="modalActions"><button className="cancel" onClick={()=>setCallCandidate(null)}>Cancel</button><button className="call" disabled={!canCall}><Phone/> Start call & log result</button></div></div></div>}
 </div>
}

function Alert({title,count,note,kind,icon}:{title:string;count:string;note:string;kind:string;icon:React.ReactNode}){return <div className={`alert ${kind}`}><div className="alertIcon">{icon}</div><div><p>{title}</p><b>{count}</b><span>{note}</span></div><ArrowUpRight className="arrow"/></div>}
function Attention({icon,title,text}:{icon:React.ReactNode;title:string;text:string}){return <div className="attentionRow"><span>{icon}</span><div><b>{title}</b><p>{text}</p></div><ChevronDown/></div>}
function Ring(){return <div className="ring"><div><b>15</b><span>open tasks</span></div></div>}
function initials(name:string){return name.split(" ").slice(0,2).map(part=>part[0]).join("").toUpperCase()}
function formatDate(value:string|null,fallback="No due date"){if(!value)return fallback;return new Intl.DateTimeFormat("en-PH",{month:"short",day:"numeric",hour:"numeric",minute:"2-digit"}).format(new Date(value))}
