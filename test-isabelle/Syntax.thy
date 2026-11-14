theory Syntax
  imports Main
begin

datatype tm =
    Var nat
  | App tm tm
  | Abs tm

primrec lift :: "tm \<Rightarrow> nat \<Rightarrow> tm" where
  "lift (Var i) k = (if i < k then Var i else Var (Suc i))"
| "lift (App s t) k = App (lift s k) (lift t k)"
| "lift (Abs t) k = Abs (lift t (Suc k))"

primrec subst :: "tm \<Rightarrow> tm \<Rightarrow> nat \<Rightarrow> tm" ("_ \<langle>_ '/ _\<rangle>" [300, 0, 0] 300) where
  "(Var i) \<langle>s / k\<rangle> = (if i < k then Var i else if i = k then s else Var (i - 1))"
| "(App t1 t2) \<langle>s / k\<rangle> = App (t1 \<langle>s / k\<rangle>) (t2 \<langle>s / k\<rangle>)"
| "(Abs t) \<langle>s / k\<rangle> = Abs (t \<langle>lift s 0 / Suc k\<rangle>)"

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

end
