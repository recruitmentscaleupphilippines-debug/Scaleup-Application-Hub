"use client";

import { FormEvent, useState } from "react";
import { ArrowRight, CheckCircle2, LockKeyhole, Mail, Users } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import "./login.css";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState("");

  async function submit(event: FormEvent) {
    event.preventDefault(); setLoading(true); setError("");
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/`, shouldCreateUser: false },
    });
    if (error) setError(error.message); else setSent(true);
    setLoading(false);
  }

  return <main className="loginPage"><section className="loginIntro"><div className="loginBrand"><span>S</span><div><b>Scale Up</b><small>Recruitment Hub</small></div></div><div className="introCopy"><p>RECRUITMENT OPERATIONS</p><h1>One clear view of every candidate journey.</h1><h2>Own every next step, protect candidate experience, and keep the team aligned.</h2><ul><li><CheckCircle2/>Centralized application ownership</li><li><CheckCircle2/>Communication SLA monitoring</li><li><CheckCircle2/>Secure, role-based workflows</li></ul></div><p className="privacy"><LockKeyhole/> Internal access only</p></section><section className="loginForm"><div className="loginCard">{sent?<><div className="sentIcon"><Mail/></div><p className="label">SECURE SIGN-IN</p><h2>Check your inbox</h2><p>We sent a secure sign-in link to <b>{email}</b>. The link can only be used by an authorized team member.</p><button className="back" onClick={()=>setSent(false)}>Use another email</button></>:<><div className="teamIcon"><Users/></div><p className="label">WELCOME BACK</p><h2>Sign in to the hub</h2><p>Enter your approved Scale Up email. We’ll send you a secure, passwordless sign-in link.</p><form onSubmit={submit}><label>Work email<input type="email" required value={email} onChange={e=>setEmail(e.target.value)} placeholder="name@scaleupphilippines.com"/></label>{error&&<div className="loginError">{error}</div>}<button disabled={loading}>{loading?"Sending…":<>Continue securely <ArrowRight/></>}</button></form><small className="help">Access is limited to active Recruitment Team accounts.</small></>}</div></section></main>
}
