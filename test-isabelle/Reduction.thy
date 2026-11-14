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

lemma wf_beta:
  "s \<rightarrow>\<^sub>\<beta> t \<Longrightarrow> wf n s \<Longrightarrow> wf n t"
proof (induction arbitrary: n rule: beta.induct)
  case (beta_step t s)
  then show ?case
    by (auto intro: wf_subst)
qed auto

lemma wf_beta_reds:
  "s \<rightarrow>\<^sub>\<beta>\<^sup>* t \<Longrightarrow> wf n s \<Longrightarrow> wf n t"
  by (induction rule: rtranclp.induct) (auto intro: wf_beta)

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

lift_definition closed_beta :: "closed_tm \<Rightarrow> closed_tm \<Rightarrow> bool" (infix "\<rightarrow>\<^sub>c" 50) is beta .

abbreviation closed_beta_reds :: "closed_tm \<Rightarrow> closed_tm \<Rightarrow> bool" (infix "\<rightarrow>\<^sub>c\<^sup>*" 50) where
  "s \<rightarrow>\<^sub>c\<^sup>* t \<equiv> closed_beta\<^sup>*\<^sup>* s t"

lemma beta_reds_imp_closed_beta_reds:
  "Rep_closed_tm s \<rightarrow>\<^sub>\<beta>\<^sup>* u \<Longrightarrow> s \<rightarrow>\<^sub>c\<^sup>* Abs_closed_tm u"
proof (induction u rule: rtranclp.induct)
  case rtrancl_refl
  show ?case
    by (simp add: Rep_closed_tm_inverse)
next
  case (rtrancl_into_rtrancl y z)
  have cy: "closed y"
    using rtrancl_into_rtrancl.hyps(1) wf_beta_reds by blast
  have cz: "closed z"
    using cy rtrancl_into_rtrancl.hyps(2) wf_beta by blast
  have ry: "Rep_closed_tm (Abs_closed_tm y) = y"
    by (rule Abs_closed_tm_inverse) (simp add: cy)
  have rz: "Rep_closed_tm (Abs_closed_tm z) = z"
    by (rule Abs_closed_tm_inverse) (simp add: cz)
  have "Abs_closed_tm y \<rightarrow>\<^sub>c Abs_closed_tm z"
    using rtrancl_into_rtrancl.hyps(2)
    by (simp add: closed_beta.rep_eq ry rz)
  with rtrancl_into_rtrancl.IH show ?case
    by (rule rtranclp.rtrancl_into_rtrancl)
qed

lemma closed_beta_reds_iff:
  "s \<rightarrow>\<^sub>c\<^sup>* t \<longleftrightarrow> Rep_closed_tm s \<rightarrow>\<^sub>\<beta>\<^sup>* Rep_closed_tm t"
proof
  assume "s \<rightarrow>\<^sub>c\<^sup>* t"
  then show "Rep_closed_tm s \<rightarrow>\<^sub>\<beta>\<^sup>* Rep_closed_tm t"
    by (induction rule: rtranclp.induct) (auto simp: closed_beta.rep_eq intro: rtranclp.rtrancl_into_rtrancl)
next
  assume "Rep_closed_tm s \<rightarrow>\<^sub>\<beta>\<^sup>* Rep_closed_tm t"
  from beta_reds_imp_closed_beta_reds[OF this]
  show "s \<rightarrow>\<^sub>c\<^sup>* t"
    by (simp add: Rep_closed_tm_inverse)
qed

end
