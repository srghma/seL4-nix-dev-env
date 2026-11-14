theory Syntax
  imports Main
begin

datatype tm =
    Var nat
  | App tm tm
  | Abs tm

primrec wf :: "nat \<Rightarrow> tm \<Rightarrow> bool" where
  "wf n (Var i) = (i < n)"
| "wf n (App s t) = (wf n s \<and> wf n t)"
| "wf n (Abs t) = wf (Suc n) t"

abbreviation closed :: "tm \<Rightarrow> bool" where
  "closed t \<equiv> wf 0 t"

primrec lift :: "tm \<Rightarrow> nat \<Rightarrow> tm" where
  "lift (Var i) k = (if i < k then Var i else Var (Suc i))"
| "lift (App s t) k = App (lift s k) (lift t k)"
| "lift (Abs t) k = Abs (lift t (Suc k))"

primrec subst :: "tm \<Rightarrow> tm \<Rightarrow> nat \<Rightarrow> tm" ("_ \<langle>_ '/ _\<rangle>" [300, 0, 0] 300) where
  "(Var i) \<langle>s / k\<rangle> = (if i < k then Var i else if i = k then s else Var (i - 1))"
| "(App t1 t2) \<langle>s / k\<rangle> = App (t1 \<langle>s / k\<rangle>) (t2 \<langle>s / k\<rangle>)"
| "(Abs t) \<langle>s / k\<rangle> = Abs (t \<langle>lift s 0 / Suc k\<rangle>)"

lemma wf_mono:
  "wf n t \<Longrightarrow> n \<le> m \<Longrightarrow> wf m t"
  by (induction t arbitrary: n m) auto

lemma wf_lift:
  "wf n t \<Longrightarrow> wf (Suc n) (lift t k)"
  by (induction t arbitrary: n k) auto

lemma lift_wf_id:
  "wf n t \<Longrightarrow> n \<le> k \<Longrightarrow> lift t k = t"
  by (induction t arbitrary: n k) auto

lemma wf_subst:
  "wf (Suc n) t \<Longrightarrow> wf n s \<Longrightarrow> k \<le> n \<Longrightarrow> wf n (t \<langle>s / k\<rangle>)"
  by (induction t arbitrary: n s k) (auto simp: wf_lift)

lemma lift_lift:
  "i \<le> j \<Longrightarrow> lift (lift t i) (Suc j) = lift (lift t j) i"
  by (induction t arbitrary: i j) auto

lemma lift_subst_lt:
  "i \<le> j \<Longrightarrow> lift (t \<langle>s / j\<rangle>) i = (lift t i) \<langle>lift s i / Suc j\<rangle>"
  by (induction t arbitrary: s i j) (auto simp: lift_lift)

lemma lift_subst_ge:
  "j \<le> i \<Longrightarrow> lift (t \<langle>s / j\<rangle>) i = (lift t (Suc i)) \<langle>lift s i / j\<rangle>"
  by (induction t arbitrary: s i j) (auto simp: lift_lift)

lemma subst_lift_id:
  "(lift t k) \<langle>s / k\<rangle> = t"
  by (induction t arbitrary: s k) auto

lemma subst_subst:
  "i \<le> j \<Longrightarrow> (t \<langle>u / i\<rangle>) \<langle>v / j\<rangle> = (t \<langle>lift v i / Suc j\<rangle>) \<langle>u \<langle>v / j\<rangle> / i\<rangle>"
  by (induction t arbitrary: u v i j) (auto simp: lift_lift lift_subst_lt subst_lift_id)

typedef closed_tm = "{t :: tm. closed t}"
  by (rule exI[of _ "Abs (Var 0)"]) simp

setup_lifting type_definition_closed_tm

lemma closed_Rep_closed_tm[simp]:
  "closed (Rep_closed_tm t)"
  using Rep_closed_tm by simp

lift_definition closed_app :: "closed_tm \<Rightarrow> closed_tm \<Rightarrow> closed_tm" is App
  by simp

end
