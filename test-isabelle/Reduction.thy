theory Reduction
  imports Syntax
begin

inductive beta :: "tm \<Rightarrow> tm \<Rightarrow> bool" (infix "\<rightarrow>\<^sub>\<beta>" 50) where
  beta_step[intro]: "(App (Abs t) s) \<rightarrow>\<^sub>\<beta> (t \<langle>s / 0\<rangle>)"
| beta_appL[intro]: "t \<rightarrow>\<^sub>\<beta> t' \<Longrightarrow> App t u \<rightarrow>\<^sub>\<beta> App t' u"
| beta_appR[intro]: "u \<rightarrow>\<^sub>\<beta> u' \<Longrightarrow> App t u \<rightarrow>\<^sub>\<beta> App t u'"
| beta_abs[intro]:  "t \<rightarrow>\<^sub>\<beta> t' \<Longrightarrow> Abs t \<rightarrow>\<^sub>\<beta> Abs t'"

abbreviation beta_reds :: "tm \<Rightarrow> tm \<Rightarrow> bool" (infix "\<rightarrow>\<^sub>\<beta>\<^sup>*" 50) where
  "s \<rightarrow>\<^sub>\<beta>\<^sup>* t \<equiv> beta\<^sup>*\<^sup>* s t"

lemma beta_reds_appL:
  "t \<rightarrow>\<^sub>\<beta>\<^sup>* t' \<Longrightarrow> App t u \<rightarrow>\<^sub>\<beta>\<^sup>* App t' u"
  by (induction rule: rtranclp.induct) (auto intro: rtranclp.rtrancl_into_rtrancl)

lemma beta_reds_appR:
  "u \<rightarrow>\<^sub>\<beta>\<^sup>* u' \<Longrightarrow> App t u \<rightarrow>\<^sub>\<beta>\<^sup>* App t u'"
  by (induction rule: rtranclp.induct) (auto intro: rtranclp.rtrancl_into_rtrancl)

lemma beta_reds_abs:
  "t \<rightarrow>\<^sub>\<beta>\<^sup>* t' \<Longrightarrow> Abs t \<rightarrow>\<^sub>\<beta>\<^sup>* Abs t'"
  by (induction rule: rtranclp.induct) (auto intro: rtranclp.rtrancl_into_rtrancl)

lemma beta_reds_app:
  "t \<rightarrow>\<^sub>\<beta>\<^sup>* t' \<Longrightarrow> u \<rightarrow>\<^sub>\<beta>\<^sup>* u' \<Longrightarrow> App t u \<rightarrow>\<^sub>\<beta>\<^sup>* App t' u'"
  by (meson beta_reds_appL beta_reds_appR rtranclp_trans)

end
