"use client";

import { FormEvent, useState } from "react";
import { ArrowRight, CheckCircle2, LockKeyhole, Users } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import "./login.css";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent) {
    event.preventDefault(); setLoading(true); setError("");
    const supabase = createClient();
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) setError("Invalid demo credentials or this account is not authorized.");
    else if (!data.session) setError("The login succeeded, but no browser session was created. Please try again.");
    else window.location.replace("/");
    setLoading(false);
  }

  return <main className="loginPage"><section className="loginIntro"><div className="loginBrand"><span>S</span><div><b>Scale Up</b><small>Recruitment Hub</small></div></div><div className="introCopy"><p>DEMO ENVIRONMENT</p><h1>One clear view of every candidate journey.</h1><h2>Trial the workflow with synthetic candidate records before any live recruitment data is imported.</h2><ul><li><CheckCircle2/>Centralized application ownership</li><li><CheckCircle2/>Communication SLA monitoring</li><li><CheckCircle2/>Secure, role-based workflows</li></ul></div><p className="privacy"><LockKeyhole/> Demo access only · No live candidate data</p></section><section className="loginForm"><div className="loginCard"><div className="teamIcon"><Users/></div><p className="label">CONTROLLED TRIAL</p><h2>Sign in to the demo</h2><p>Use one of the approved demo accounts. Real team accounts remain inactive during the trial.</p><form onSubmit={submit}><label>Demo email<input type="email" autoComplete="username" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="demo.recruiter@scaleup.test"/></label><label>Password<input type="password" autoComplete="current-password" required value={password} onChange={e=>setPassword(e.target.value)} placeholder="Enter temporary password"/></label>{error&&<div className="loginError">{error}</div>}<button disabled={loading}>{loading?"Signing in…":<>Open demo hub <ArrowRight/></>}</button></form><small className="help">Access is limited to approved trial accounts.</small></div></section></main>
}
