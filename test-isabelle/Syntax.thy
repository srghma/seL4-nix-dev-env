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

primrec subst :: "tm \<Rightarrow> tm \<Rightarrow> nat \<Rightarrow> tm" ("_ [_ '/ _]" [300, 0, 0] 300) where
  "(Var i) [s / k] = (if i < k then Var i else if i = k then s else Var (i - 1))"
| "(App t1 t2) [s / k] = App (t1 [s / k]) (t2 [s / k])"
| "(Abs t) [s / k] = Abs (t [lift s 0 / Suc k])"

lemma lift_lift:
  "i \<le> j \<Longrightarrow> lift (lift t i) (Suc j) = lift (lift t j) i"
  by (induction t arbitrary: i j) auto

lemma lift_subst_lt:
  "i \<le> j \<Longrightarrow> lift (t [s / j]) i = (lift t i) [lift s i / Suc j]"
  by (induction t arbitrary: s i j) (auto simp: lift_lift)

lemma lift_subst_ge:
  "j \<le> i \<Longrightarrow> lift (t [s / j]) i = (lift t (Suc i)) [lift s i / j]"
  by (induction t arbitrary: s i j) (auto simp: lift_lift)

lemma subst_lift_id:
  "(lift t k) [s / k] = t"
  by (induction t arbitrary: s k) auto

lemma subst_subst:
  "i \<le> j \<Longrightarrow> (t [u / i]) [v / j] = (t [lift v i / Suc j]) [u [v / j] / i]"
  by (induction t arbitrary: u v i j) (auto simp: lift_lift lift_subst_lt subst_lift_id)

end
