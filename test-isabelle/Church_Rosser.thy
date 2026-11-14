theory Church_Rosser
  imports Reduction
begin

inductive par_beta :: "tm \<Rightarrow> tm \<Rightarrow> bool" (infix "\<Rightarrow>\<^sub>p" 50) where
  par_var[intro]:  "Var i \<Rightarrow>\<^sub>p Var i"
| par_abs[intro]:  "t \<Rightarrow>\<^sub>p t' \<Longrightarrow> Abs t \<Rightarrow>\<^sub>p Abs t'"
| par_app[intro]:  "t \<Rightarrow>\<^sub>p t' \<Longrightarrow> u \<Rightarrow>\<^sub>p u' \<Longrightarrow> App t u \<Rightarrow>\<^sub>p App t' u'"
| par_beta[intro]: "t \<Rightarrow>\<^sub>p t' \<Longrightarrow> u \<Rightarrow>\<^sub>p u' \<Longrightarrow> App (Abs t) u \<Rightarrow>\<^sub>p (t' [u' / 0])"

abbreviation par_beta_reds :: "tm \<Rightarrow> tm \<Rightarrow> bool" (infix "\<Rightarrow>\<^sub>p\<^sup>*" 50) where
  "s \<Rightarrow>\<^sub>p\<^sup>* t \<equiv> par_beta\<^sup>*\<^sup>* s t"

lemma par_beta_refl[simp]: "t \<Rightarrow>\<^sub>p t"
  by (induction t) auto

lemma par_abs_inv[dest]: "Abs t \<Rightarrow>\<^sub>p Abs t' \<Longrightarrow> t \<Rightarrow>\<^sub>p t'"
  by (auto elim: par_beta.cases)

lemma beta_imp_par_beta:
  "s \<rightarrow>\<^sub>\<beta> t \<Longrightarrow> s \<Rightarrow>\<^sub>p t"
  by (induction rule: beta.induct) auto

lemma par_beta_imp_beta_reds:
  "s \<Rightarrow>\<^sub>p t \<Longrightarrow> s \<rightarrow>\<^sub>\<beta>\<^sup>* t"
  by (induction rule: par_beta.induct)
     (auto intro: beta_reds_abs beta_reds_app rtranclp.rtrancl_into_rtrancl)

lemma par_beta_lift:
  "s \<Rightarrow>\<^sub>p t \<Longrightarrow> lift s k \<Rightarrow>\<^sub>p lift t k"
  by (induction arbitrary: k rule: par_beta.induct) (auto simp: lift_subst_ge)

lemma par_beta_subst:
  "t \<Rightarrow>\<^sub>p t' \<Longrightarrow> s \<Rightarrow>\<^sub>p s' \<Longrightarrow> t [s / k] \<Rightarrow>\<^sub>p t' [s' / k]"
  by (induction arbitrary: s s' k rule: par_beta.induct) (auto simp: par_beta_lift subst_subst)

fun cd :: "tm \<Rightarrow> tm" where
  "cd (Var i) = Var i"
| "cd (Abs t) = Abs (cd t)"
| "cd (App (Abs t) u) = (cd t) [cd u / 0]"
| "cd (App t u) = App (cd t) (cd u)"

lemma cd_triangle:
  "s \<Rightarrow>\<^sub>p t \<Longrightarrow> t \<Rightarrow>\<^sub>p cd s"
proof (induction rule: par_beta.induct)
  case (par_app t t' u u')
  then show ?case
    by (cases t) (auto elim: par_beta.cases)
qed (auto simp: par_beta_subst)

lemma par_beta_diamond:
  "s \<Rightarrow>\<^sub>p t1 \<Longrightarrow> s \<Rightarrow>\<^sub>p t2 \<Longrightarrow> \<exists>u. t1 \<Rightarrow>\<^sub>p u \<and> t2 \<Rightarrow>\<^sub>p u"
  by (blast intro: cd_triangle)

lemma par_beta_strip:
  "s \<Rightarrow>\<^sub>p t1 \<Longrightarrow> s \<Rightarrow>\<^sub>p\<^sup>* t2 \<Longrightarrow> \<exists>u. t1 \<Rightarrow>\<^sub>p\<^sup>* u \<and> t2 \<Rightarrow>\<^sub>p u"
proof -
  assume "s \<Rightarrow>\<^sub>p\<^sup>* t2" and "s \<Rightarrow>\<^sub>p t1"
  then show ?thesis
  proof (induction arbitrary: t1 rule: rtranclp.induct)
    case rtrancl_refl
    then show ?case by auto
  next
    case rtrancl_into_rtrancl
    then show ?case
      by (meson par_beta_diamond rtranclp.rtrancl_into_rtrancl)
  qed
qed

lemma par_beta_confluent:
  "s \<Rightarrow>\<^sub>p\<^sup>* t1 \<Longrightarrow> s \<Rightarrow>\<^sub>p\<^sup>* t2 \<Longrightarrow> \<exists>u. t1 \<Rightarrow>\<^sub>p\<^sup>* u \<and> t2 \<Rightarrow>\<^sub>p\<^sup>* u"
proof (induction arbitrary: t2 rule: rtranclp.induct)
  case rtrancl_refl
  then show ?case by auto
next
  case rtrancl_into_rtrancl
  then show ?case
    by (meson par_beta_strip rtranclp.rtrancl_into_rtrancl)
qed

lemma beta_reds_iff_par_beta_reds:
  "s \<rightarrow>\<^sub>\<beta>\<^sup>* t \<longleftrightarrow> s \<Rightarrow>\<^sub>p\<^sup>* t"
proof
  assume "s \<rightarrow>\<^sub>\<beta>\<^sup>* t"
  then show "s \<Rightarrow>\<^sub>p\<^sup>* t"
    by (induction rule: rtranclp.induct) (auto intro: beta_imp_par_beta rtranclp.rtrancl_into_rtrancl)
next
  assume "s \<Rightarrow>\<^sub>p\<^sup>* t"
  then show "s \<rightarrow>\<^sub>\<beta>\<^sup>* t"
    by (induction rule: rtranclp.induct) (auto intro: par_beta_imp_beta_reds rtranclp_trans)
qed

theorem church_rosser:
  "s \<rightarrow>\<^sub>\<beta>\<^sup>* t1 \<Longrightarrow> s \<rightarrow>\<^sub>\<beta>\<^sup>* t2 \<Longrightarrow> \<exists>u. t1 \<rightarrow>\<^sub>\<beta>\<^sup>* u \<and> t2 \<rightarrow>\<^sub>\<beta>\<^sup>* u"
  using beta_reds_iff_par_beta_reds par_beta_confluent by blast

end
