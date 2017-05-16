theory PathRel
imports Main
begin

definition path :: "'a rel \<Rightarrow> 'a list \<Rightarrow> bool" where
"path r lst = (\<forall>i < length lst-1. (lst!i, lst!(i+1)) \<in> r)"

fun pathR :: "'a rel \<Rightarrow> 'a list \<Rightarrow> bool" where
"pathR r (a#b#rest) = ((a,b) \<in> r \<and> pathR r (b#rest))"
| "pathR r _ = True"

lemma path_defs : "pathR r lst = path r lst"
apply (simp add:path_def)
apply (induction lst; simp)
apply (case_tac lst; auto simp add:less_Suc_eq_0_disj)
done

definition tlR :: "'a list rel" where
"tlR = {(a#lst,lst) | a lst. True }"

definition push_pop :: "'a list rel" where
"push_pop = (Id \<union> tlR \<union> converse tlR)"

definition sucR :: "nat rel" where
"sucR = {(Suc n,n) | n. True }"

definition inc_dec :: "nat rel" where
"inc_dec = (Id \<union> sucR \<union> converse sucR)"

lemma inc_dec_expand : "inc_dec = {(a,b) | a b. a+1 = b \<or> a=b \<or> a = b+1}"
by (auto simp:inc_dec_def sucR_def)

type_synonym 'a lang = "'a list \<Rightarrow> bool"

fun invL :: "'a set \<Rightarrow> 'a lang" where
"invL s [] = True"
| "invL s lst = (hd lst \<in> s \<and> last lst \<in> s)"

definition seq :: "'a lang \<Rightarrow> 'a lang \<Rightarrow> 'a lang" where
"seq a b lst = (\<exists>u v. a u \<and> b v \<and> lst = u@v)"

definition star :: "'a lang \<Rightarrow> 'a lang" where
"star x lst = (\<exists>l. \<forall>el. el \<in> set l \<and> concat l = lst)"

(* *)
definition inc_decL :: "nat lang" where
"inc_decL lst = pathR inc_dec lst"

lemma test :
   "inc_decL lst \<Longrightarrow>
    i < length lst - 1 \<Longrightarrow>
    lst!i = lst!(i+1) \<or> lst!i = lst!(i+1)+1 \<or> lst!i+1 = lst!(i+1)"
by (auto simp add:inc_decL_def inc_dec_def sucR_def path_defs path_def)

definition push_popL :: "'a list lang" where
"push_popL lst = pathR push_pop lst"

lemma push_pop_inc_dec :
   "(a,b) \<in> push_pop \<Longrightarrow>
    (length a, length b) \<in> inc_dec"
by (auto simp: push_pop_def inc_dec_def sucR_def tlR_def)

definition mapR :: "'a rel \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'b rel" where
"mapR r f = {(f x,f y) | x y. (x,y) \<in> r}"

definition mapR2 :: "'a rel \<Rightarrow> ('b \<Rightarrow> 'a) \<Rightarrow> 'b rel" where
"mapR2 r f = {(x, y) | x y. (f x,f y) \<in> r}"

lemma push_pop_inc_dec_map : "mapR push_pop length \<subseteq> inc_dec"
unfolding mapR_def
using push_pop_inc_dec by fastforce

definition hd_last :: "'a list \<Rightarrow> 'a \<Rightarrow> 'a \<Rightarrow> bool" where
"hd_last lst a b = (hd lst = a \<and> last lst = b \<and> length lst > 0)"

lemma converse_rev : "pathR r lst \<Longrightarrow> pathR (converse r) (rev lst)"
unfolding path_defs path_def
  by (smt Suc_diff_Suc Suc_eq_plus1_left add.commute add.right_neutral converse.intros diff_Suc_less le_less_trans length_rev less_diff_conv not_add_less1 not_less rev_nth)

lemma sym_rev : "sym r \<Longrightarrow> pathR r lst \<Longrightarrow> pathR r (rev lst)"
  by (metis converse_rev sym_conv_converse_eq)

lemma list_all_values :
   "inc_decL lst \<Longrightarrow>
    length lst > 0 \<Longrightarrow>
    last lst \<le> hd lst \<Longrightarrow>
    {last lst .. hd lst} \<subseteq> set lst"
apply (induction lst)
apply (auto simp add:inc_decL_def inc_dec_def sucR_def)
apply (case_tac lst; auto; fastforce)
done

lemma sym_inc_dec : "sym inc_dec"
  by (simp add: inc_dec_def sup_assoc sym_Id sym_Un sym_Un_converse)


lemma list_all_values2 :
   "inc_decL lst \<Longrightarrow>
    length lst > 0 \<Longrightarrow>
    {min (hd lst) (last lst) .. max (hd lst) (last lst)} \<subseteq> set lst"
apply (cases "last lst \<le> hd lst")
  using list_all_values apply fastforce
  using list_all_values [of "rev lst"]
  by (simp add: sym_rev hd_rev inc_decL_def sym_inc_dec last_rev max_def min_def)

definition takeLast :: "nat \<Rightarrow> 'a list \<Rightarrow> 'a list" where
"takeLast n lst = rev (take n (rev lst))"

lemma takeLast_drop :
  "takeLast n lst = drop (length lst - n) lst"
apply (induction lst arbitrary:n)
apply (auto simp add:takeLast_def)
  by (metis length_Cons length_rev rev.simps(2) rev_append rev_rev_ident take_append take_rev)

(* unchanged *)
lemma next_unchanged :
  "(st1, st2) \<in> push_pop \<Longrightarrow>
   l \<le> length st2 \<Longrightarrow>
   l \<le> length st1 \<Longrightarrow>
   takeLast l st2 = takeLast l st1"
by (auto simp:push_pop_def tlR_def takeLast_def)

lemma pathR2 : "pathR r [a, b] = ((a,b) \<in> r)"
by auto

lemma pathR3 :
 "pathR r (a # b # list) = ((a,b) \<in> r \<and> pathR r (b#list))"
by auto

declare pathR.simps [simp del]

lemma stack_unchanged :
  "push_popL lst \<Longrightarrow>
   length lst > 0 \<Longrightarrow>
   (* hd_last lst a b \<Longrightarrow> *)
   \<forall>sti \<in> set lst. l \<le> length sti \<Longrightarrow>
   takeLast l (hd lst) = takeLast l (last lst)"
apply (induction lst)
apply (auto simp:push_popL_def hd_last_def)
by (metis (no_types, lifting) hd_conv_nth list.set_cases list.set_sel(1) next_unchanged nth_Cons_0 pathR.simps(1))

lemma take_all [simp] : "takeLast (length a) a = a"
by (simp add:takeLast_def)

lemma find_return :
   "push_popL lst \<Longrightarrow>
    length lst > 0 \<Longrightarrow>
    length (last lst) \<le> length (hd lst) \<Longrightarrow>
    takeLast (length (last lst)) (hd lst) \<in> set lst"
apply (induction lst; auto simp:push_pop_def push_popL_def)
apply (case_tac lst; auto)
  apply (metis PathRel.take_all le_refl next_unchanged pathR.simps(1) push_pop_def)
apply (auto simp:pathR.simps)
  apply (smt Nitpick.size_list_simp(2) PathRel.take_all basic_trans_rules(31) inf_sup_aci(5) le_SucE list.sel(3) mem_Collect_eq next_unchanged prod.sel(1) prod.sel(2) push_pop_def sup.cobounded2 tlR_def zero_order(2))
  by (smt Suc_leD Suc_leI inf_sup_aci(5) inf_sup_ord(3) le_imp_less_Suc length_Cons mem_Collect_eq next_unchanged prod.inject push_pop_def subset_eq tlR_def)

definition monoI :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) \<Rightarrow> bool" where
"monoI iv v = (\<forall>i < length (snd v). iv (snd v!i) \<longrightarrow> iv ((fst v#snd v)!i))"

definition mono_same :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) rel" where
"mono_same iv = {((g1,lst), (g2,lst)) | lst g1 g2. iv g1 \<longrightarrow> iv g2}"

definition mono_pop :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) rel" where
"mono_pop iv =
   {((g1,a#lst), (g2,lst)) | lst g1 g2 a. iv g1 \<longrightarrow> iv a \<longrightarrow> iv g2}"

definition mono_push :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) rel" where
"mono_push iv =
   {((g1,lst), (g2,a#lst)) | lst g1 g2 a. iv g1 \<longrightarrow> iv a} \<inter>
   {((g1,lst), (g2,a#lst)) | lst g1 g2 a. iv a \<longrightarrow> iv g2}"

definition mono_rules :: "('a \<Rightarrow> bool) \<Rightarrow> ('a * 'a list) rel" where
"mono_rules iv = mono_same iv \<union> mono_pop iv \<union> mono_push iv"

lemma mono_same :
   "monoI iv a \<Longrightarrow>
    (a,b) \<in> mono_same iv \<Longrightarrow>
    monoI iv b"
unfolding monoI_def mono_same_def
  using less_SucI less_Suc_eq_0_disj by fastforce

lemma mono_push :
   "monoI iv (v1,lst) \<Longrightarrow>
    ((v1, lst), (v2,a#lst)) \<in> mono_push iv \<Longrightarrow>
    monoI iv (v2,a#lst)"
unfolding monoI_def mono_push_def
apply auto
  apply (metis diff_Suc_1 less_Suc_eq_0_disj nth_Cons')
  apply (metis diff_Suc_1 less_Suc_eq_0_disj nth_Cons')
  apply (metis diff_Suc_1 less_Suc_eq_0_disj nth_Cons')
done

lemma mono_pop :
   "monoI iv (v1,a#lst) \<Longrightarrow>
    ((v1,a#lst), (v2,lst)) \<in> mono_pop iv \<Longrightarrow>
    monoI iv (v2,lst)"
unfolding monoI_def mono_pop_def
apply auto
  apply (metis Suc_mono length_Cons less_SucI list.sel(3) nth_Cons' nth_tl)
  apply (metis Suc_mono length_Cons less_SucI list.sel(3) nth_Cons' nth_tl)
  apply (metis Suc_mono length_Cons less_SucI list.sel(3) nth_Cons' nth_tl)
done

lemma mono_works :
   "monoI iv (v1,lst1) \<Longrightarrow>
    ((v1,lst1), (v2,lst2)) \<in> mono_rules iv \<Longrightarrow>
    (lst1, lst2) \<in> push_pop \<Longrightarrow>
    monoI iv (v2,lst2)"
apply (auto simp add: push_pop_def)
using mono_same [of iv "(v1,lst2)" "(v2,lst2)"]
  apply (smt Int_iff Pair_inject UnE mem_Collect_eq mono_pop mono_pop_def mono_push_def mono_rules_def)
  apply (smt Int_iff UnE fst_conv mem_Collect_eq mono_pop mono_push mono_push_def mono_rules_def mono_same snd_conv tlR_def)
  by (smt UnE fst_conv mem_Collect_eq mono_pop mono_pop_def mono_push mono_rules_def mono_same snd_conv tlR_def)

definition first :: "('a \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> 'a list \<Rightarrow> bool" where
"first P k lst ==
   k < length lst \<and> P (lst!k) \<and> (\<forall>k2 < k. \<not>P (lst!k2))"

definition first_smaller :: "nat \<Rightarrow> nat list \<Rightarrow> bool" where
"first_smaller k lst = first (\<lambda>b. b < hd lst) k lst"

definition first_one_smaller :: "nat \<Rightarrow> nat list \<Rightarrow> bool" where
"first_one_smaller k lst = first (\<lambda>b. Suc b = hd lst) k lst"

lemma pathR_take : "pathR r lst \<Longrightarrow> pathR r (take k lst)"
by (simp add:path_defs path_def)

lemma pathR_drop : "pathR r lst \<Longrightarrow> pathR r (drop k lst)"
by (simp add:path_defs path_def)

definition clip :: "nat \<Rightarrow> nat \<Rightarrow> 'a list \<Rightarrow> 'a list" where
"clip k k3 lst = take (k - k3 + 1) (drop k3 lst)"

lemma pathR_clip : "pathR r lst \<Longrightarrow> pathR r (clip k1 k2 lst)"
by (simp add:pathR_drop pathR_take clip_def)

lemma hd_clip :
   "k3 < k \<Longrightarrow> k < length lst \<Longrightarrow>
    hd (clip k k3 lst) = lst!k3"
unfolding clip_def
  by (metis Cons_nth_drop_Suc Nat.add_0_right One_nat_def add_Suc_right list.sel(1) order.strict_trans take_Suc_Cons)

lemma last_index :
   "length lst > 0 \<Longrightarrow> last lst = lst!(length lst-1)"
  using last_conv_nth by auto

lemma last_clip :
   "k3 < k \<Longrightarrow> k < length lst \<Longrightarrow>
    last (clip k k3 lst) = lst!k"
unfolding clip_def
by (auto simp add: last_conv_nth min.absorb2)

lemma hd_take : "hd (take (Suc k3) lst) = hd lst"
  by (metis list.sel(1) take_Nil take_Suc)

lemma last_take :
  "length lst > k3 \<Longrightarrow>
   last (take (Suc k3) lst) = lst!k3"
  by (simp add: take_Suc_conv_app_nth)


lemma first_smaller1 :
   "inc_decL lst \<Longrightarrow>
    first_one_smaller k lst \<Longrightarrow>
    first_smaller k lst"
apply (cases "length lst > 0")
apply (auto simp:first_one_smaller_def first_def first_smaller_def)
subgoal for k3
using list_all_values [of "take (Suc k3) lst"]
apply (auto simp:inc_decL_def pathR_take hd_clip last_clip
  hd_take last_take)
apply (cases "lst!k \<in> set (take (Suc k3) lst)")
  apply (smt Suc_leI in_set_conv_nth le_neq_implies_less length_take min.absorb2 nth_take order.strict_trans)
  by (simp add: less_Suc_eq_le set_mp)
done

lemma inc_dec_too_large :
"z \<ge> y \<Longrightarrow>
 (z, x) \<in> inc_dec \<Longrightarrow>  
 Suc x < y \<Longrightarrow> False"
by (auto simp add:inc_dec_def sucR_def)

lemma first_smaller2 :
   "inc_decL lst \<Longrightarrow>
    first_smaller k lst \<Longrightarrow>
    first_one_smaller k lst"
apply (cases "length lst > 0")
apply (auto simp:first_one_smaller_def first_def first_smaller_def)
using list_all_values [of "take (Suc k) lst"]
apply (auto simp:inc_decL_def pathR_take hd_clip last_clip
  hd_take last_take)
apply (cases "Suc (lst ! k) < hd lst"; auto)
apply (cases "length lst > 1"; auto)
defer
apply (cases "length lst = 1"; auto)
  apply (simp add: hd_conv_nth)
apply (rule inc_dec_too_large [of "hd lst" "lst!(k-1)" "lst!k"])
apply auto
  apply (metis diff_is_0_eq diff_less dual_order.strict_implies_order hd_conv_nth less_Suc_eq_le not_le)
apply (auto simp add:path_defs path_def)
  by (smt One_nat_def Suc_eq_plus1 Suc_lessI Suc_n_not_le_n diff_less hd_conv_nth less_diff_conv less_or_eq_imp_le neq0_conv)

definition minList :: "nat list \<Rightarrow> nat" where
"minList lst = foldr min lst (hd lst)"

definition maxList :: "nat list \<Rightarrow> nat" where
"maxList lst = foldr max lst (hd lst)"

lemma min_exists_aux :
   "n < length lst \<Longrightarrow>
    0 < length lst \<Longrightarrow>
    foldr min lst (x::nat) \<le> lst!n"
apply (induction lst arbitrary:n x; auto)
  using less_Suc_eq_0_disj min.coboundedI2 by fastforce

lemma max_exists_aux :
   "n < length lst \<Longrightarrow>
    0 < length lst \<Longrightarrow>
    foldr max lst (x::nat) \<ge> lst!n"
apply (induction lst arbitrary:n x; auto)
  using less_Suc_eq_0_disj max.coboundedI2 by fastforce

lemma min_exists :
   "length lst > 0 \<Longrightarrow> n < length lst \<Longrightarrow>
    minList lst \<le> lst!n"
unfolding minList_def
using min_exists_aux by simp

lemma max_exists :
   "length lst > 0 \<Longrightarrow> n < length lst \<Longrightarrow>
    maxList lst \<ge> lst!n"
unfolding maxList_def
using max_exists_aux by simp


lemma min_max :
  "length lst > 0 \<Longrightarrow>
   set lst \<subseteq> {minList lst .. maxList lst}"
by (metis atLeastAtMost_iff in_set_conv_nth max_exists min_exists subsetI)

lemma minList_one : "minList [a] = a"
by (simp add:minList_def)

lemma min_aux : "foldr min lst (x::nat) \<le> x"
by (induction lst arbitrary:x; auto simp add: min.coboundedI2)

lemma max_aux : "foldr max lst (x::nat) \<ge> x"
by (induction lst arbitrary:x; auto simp add: max.coboundedI2)

lemma minlist1 : "a \<le> b \<Longrightarrow> minList (a # b # list) = minList (a#list)"
by (simp add: minList_def)

lemma maxlist1 : "a \<ge> b \<Longrightarrow> maxList (a # b # list) = maxList (a#list)"
by (simp add: maxList_def)

lemma min_smaller :
   "x \<le> y \<Longrightarrow> foldr min lst (x::nat) \<le> foldr min lst y"
by (induction lst arbitrary:x; auto simp add: min.coboundedI2)

lemma min_min : "a \<ge> (b::nat) \<Longrightarrow> min a (min b c) = min b c"
by simp

lemma min_min2 : "a \<le> (b::nat) \<Longrightarrow> min a (min b c) = min a c"
by simp

lemma min_simp : "a < (b::nat) \<Longrightarrow> min b a = a"
by simp

lemma min_of_min :
   "b \<le> (a::nat) \<Longrightarrow> min b (foldr min lst a) = min b (foldr min lst b)"
by (induction lst; auto)

lemma max_of_max :
   "b \<ge> (a::nat) \<Longrightarrow> max b (foldr max lst a) = max b (foldr max lst b)"
by (induction lst; auto)

lemma minlist_swap :
   "minList (a # b # list) = minList (b # a # list)"
apply (simp add: minList_def)
apply (cases "a \<ge> b")
apply (auto simp add:min_min min_min2)
apply (rule min_of_min; auto)
using min_of_min [of a b list]
  by auto

lemma maxlist_swap :
   "maxList (a # b # list) = maxList (b # a # list)"
by (simp add: maxList_def;cases "a \<le> b"; metis linear max.left_commute max_of_max)

lemma minlist2 : "a \<ge> b \<Longrightarrow> minList (a # b # list) = minList (b#list)"
  using minlist1 minlist_swap by fastforce

lemma maxlist2 : "a \<le> b \<Longrightarrow> maxList (a # b # list) = maxList (b#list)"
  using maxlist1 maxlist_swap by fastforce

lemma find_min :
  "length lst > 0 \<Longrightarrow> \<exists>k. minList lst = lst!k"
apply (induction lst; auto)
apply (case_tac lst; auto simp add:minList_one)
  apply (metis nth_Cons_0)
apply (case_tac "aa \<le> a")
apply (simp add:minlist2)
  apply (metis nth_Cons_Suc)
apply (case_tac "a \<le> aa")
apply (case_tac k)
apply auto
apply (simp add:minList_def min_min2)
apply (rule exI[where x = 0])
apply auto
  apply (metis min_absorb2 min_aux min_def min_of_min)
apply (case_tac "a \<le> minList (aa#list)")
apply auto
apply (rule exI[where x = 0])
apply auto
apply (simp add:minList_def min_min2)
  apply (metis min.absorb2 min_aux min_def min_of_min)
subgoal for a b list nat
apply (rule exI[where x = "nat+2"])
apply auto
apply (simp add:minList_def min_min2)
  by (metis min_def min_of_min)
done

lemma find_max :
  "length lst > 0 \<Longrightarrow> \<exists>k. maxList lst = lst!k"
apply (induction lst; auto)
apply (case_tac lst; auto)
apply (simp add:maxList_def)
  apply (metis nth_Cons_0)
apply (case_tac "aa \<ge> a")
apply (simp add:maxlist2)
  apply (metis nth_Cons_Suc)
apply (case_tac "a \<ge> aa")
apply (case_tac k)
apply auto
apply (rule exI[where x = 0])
  apply (metis foldr.simps(2) list.sel(1) max.orderE maxList_def max_of_max nth_Cons_0 o_apply)
apply (case_tac "a \<ge> maxList (aa#list)")
apply auto
apply (rule exI[where x = 0])
apply auto
  apply (metis foldr.simps(2) list.sel(1) max.orderE maxList_def max_of_max o_apply)
subgoal for a b list nat
apply (rule exI[where x = "nat+2"])
apply auto
apply (simp add:maxList_def)
  by (smt inf_sup_aci(5) max_def max_of_max sup_nat_def)
done

lemma find_max2 :
  "length lst > 0 \<Longrightarrow> \<exists>k < length lst. maxList lst = lst!k"
apply (induction lst; auto)
apply (case_tac lst; auto)
apply (simp add:maxList_def)
apply (case_tac "aa \<ge> a")
apply (simp add:maxlist2)
  apply auto[1]
apply (case_tac "a \<ge> aa")
apply (case_tac k)
apply auto
apply (rule exI[where x = 0])
subgoal for a b list
apply auto
  apply (metis foldr.simps(2) list.sel(1) max.orderE maxList_def max_of_max o_apply)
done
apply (case_tac "a \<ge> maxList (aa#list)")
apply auto
apply (rule exI[where x = 0])
apply auto
  apply (metis foldr.simps(2) list.sel(1) max.orderE maxList_def max_of_max o_apply)
subgoal for a b list nat
apply (rule exI[where x = "nat+2"])
apply auto
apply (simp add:maxList_def)
  by (smt inf_sup_aci(5) max_def max_of_max sup_nat_def)
done

lemma find_min2 :
  "length lst > 0 \<Longrightarrow> \<exists>k < length lst. minList lst = lst!k"
apply (induction lst; auto)
apply (case_tac lst; auto)
apply (simp add:minList_def)
apply (case_tac "aa \<le> a")
apply (simp add:minlist2)
  apply auto[1]
apply (case_tac "a \<le> aa")
apply (case_tac k)
apply auto
apply (rule exI[where x = 0])
subgoal for a b list
apply auto
  apply (metis foldr.simps(2) list.sel(1) min.orderE minList_def min_of_min o_apply)
done
apply (case_tac "a \<le> minList (aa#list)")
apply auto
apply (rule exI[where x = 0])
apply auto
  apply (metis foldr.simps(2) list.sel(1) min.orderE minList_def min_of_min o_apply)
subgoal for a b list nat
apply (rule exI[where x = "nat+2"])
apply auto
apply (simp add:minList_def)
  by (smt inf_sup_aci(5) min_def min_of_min sup_nat_def)
done

lemma clip_set : "set (clip imin imax lst) \<subseteq> set lst"
  by (metis clip_def dual_order.trans set_drop_subset set_take_subset)

lemma min_max_all_values :
   "inc_decL lst \<Longrightarrow>
    length lst > 0 \<Longrightarrow>
    {minList lst .. maxList lst} \<subseteq> set lst"
using find_min2 [of lst] find_max2 [of lst]
apply clarsimp
subgoal for x imin imax
apply (case_tac "imax = imin")
apply simp

apply (case_tac "imax < imin")
using list_all_values [of "clip imin imax lst"]
apply (simp add:hd_clip last_clip inc_decL_def
  pathR_clip)
apply (cases "clip imin imax lst = []"; auto)
apply (simp add:clip_def)
using clip_set [of imin imax lst]
  using atLeastAtMost_iff apply blast

apply (case_tac "imin < imax"; auto)
using list_all_values2 [of "clip imax imin lst"]
apply (simp add:hd_clip last_clip inc_decL_def
  pathR_clip)
apply (cases "clip imax imin lst = []"; auto)
apply (simp add:clip_def)
using clip_set [of imax imin lst]
  by fastforce
done

lemma min_max_all_values2 :
   "inc_decL lst \<Longrightarrow>
    length lst > 0 \<Longrightarrow>
    {minList lst .. maxList lst} = set lst"
  by (simp add: antisym min_max min_max_all_values)

lemma push_popL_inc_decL :
   "push_popL lst \<Longrightarrow> inc_decL (map length lst)"
by (auto simp add:push_popL_def inc_decL_def path_defs path_def
                     push_pop_inc_dec)

definition first_return :: "nat \<Rightarrow> 'a list list \<Rightarrow> bool" where
"first_return k lst =
    first (\<lambda>b. (hd lst,b) \<in> tlR) k lst"

lemma takeLast_cons :
  "takeLast (length lst) (a # lst) = lst"
by (simp add:takeLast_def)

(* *)
lemma first_return_smaller :
   "push_popL lst \<Longrightarrow>
    first_return k lst \<Longrightarrow>
    first_one_smaller k (map length lst)"
apply (cases "length lst > 0")
apply (auto simp:first_one_smaller_def first_def
   first_return_def tlR_def hd_map)
subgoal for a k1
using find_return [of "take (Suc k1) lst"]
apply (simp add:hd_take last_take)
apply (cases "push_popL (take (Suc k1) lst)")
apply (auto simp add:takeLast_cons push_popL_def pathR_take)
apply (smt in_set_conv_nth length_take less_SucE less_imp_le_nat less_trans_Suc min.absorb2 nth_take order.strict_trans)
done
done

lemma first_smaller_return :
   "push_popL lst \<Longrightarrow>
    first_smaller k (map length lst) \<Longrightarrow>
    first_one_smaller k (map length lst) \<Longrightarrow>
    first_return k lst"
apply (cases "length lst > 0")
apply (auto simp:first_one_smaller_def
   first_smaller_def first_def
   first_return_def tlR_def hd_map)
apply (cases "hd lst"; auto)
subgoal for a list
using stack_unchanged [of "take (Suc k) lst" "length list"]
apply (simp add:push_popL_def pathR_take hd_take last_take
  takeLast_def)
  by (smt Suc_leD in_set_conv_nth length_take less_SucE less_or_eq_imp_le min.absorb2 not_le nth_take)
done

(* call includes enter and exit *)
definition call :: "'a list list \<Rightarrow> bool" where
"call lst = (
   length lst > 2 \<and>
   (lst!1, lst!0) \<in> tlR \<and>
   push_popL lst \<and>
   first_return (length lst-2) (tl lst))"

definition ncall :: "nat list \<Rightarrow> bool" where
"ncall lst = (
   length lst > 2 \<and>
   (lst!1, lst!0) \<in> sucR \<and>
   inc_decL lst \<and>
   first_one_smaller (length lst-2) (tl lst))"

(* a call is a kind of a cycle...
   perhaps cycles have useful features *)
lemma call_stack_length :
  "call lst \<Longrightarrow> hd lst = last lst"
apply (auto simp add:call_def first_return_def first_def tlR_def)
  by (metis One_nat_def Suc_diff_Suc Suc_lessD hd_conv_nth last_conv_nth length_tl less_numeral_extra(2) list.inject list.size(3) nth_tl numeral_2_eq_2 zero_less_diff)

lemma ncall_stack_length :
  "ncall lst \<Longrightarrow> hd lst = last lst"
apply (auto simp add:ncall_def first_one_smaller_def first_def sucR_def)
  by (metis (no_types, hide_lams) One_nat_def Suc_1 Suc_diff_Suc diff_Suc_1 gr_implies_not_zero hd_conv_nth in_set_conv_nth last_index length_pos_if_in_set length_tl less_trans_Suc list.size(3) nth_tl zero_less_numeral)

lemma pathR_tl : "pathR r lst \<Longrightarrow> pathR r (tl lst)"
apply (auto simp add:path_defs path_def)
  by (simp add: nth_tl)


lemma call_ncall : "call lst \<Longrightarrow> ncall (map length lst)"
apply (auto simp add:call_def ncall_def tlR_def sucR_def)
  apply (metis Suc_lessD nth_map numeral_2_eq_2)
  using push_popL_inc_decL apply auto[1]
using first_return_smaller [of "tl lst" "length lst - 2"]
by (simp add:push_popL_def pathR_tl map_tl)

lemma ncall_call :
   "ncall (map length lst) \<Longrightarrow>
    push_popL lst \<Longrightarrow>
    call lst"
apply (auto simp add:call_def ncall_def tlR_def sucR_def)
apply (cases "lst!1"; auto)
apply (subst (asm) nth_map)
apply auto
apply (simp add:push_popL_def path_defs path_def push_pop_def
  tlR_def)
subgoal for a list proof -
  fix a :: 'a and list :: "'a list"
  assume a1: "\<forall>i<length lst - Suc 0. lst ! i = lst ! Suc i \<or> (\<exists>a. lst ! i = a # lst ! Suc i) \<or> (\<exists>a. lst ! Suc i = a # lst ! i)"
  assume a2: "2 < length lst"
  assume a3: "length list = length (lst ! 0)"
  assume a4: "lst ! Suc 0 = a # list"
  have "[] \<noteq> tl lst"
    using a2 by (metis (no_types) One_nat_def Suc_pred length_tl less_Suc_eq less_trans_Suc list.size(3) nat_neq_iff zero_less_numeral)
  then show "list = lst ! 0"
  using a4 a3 a1 by (metis (no_types) One_nat_def length_Cons length_greater_0_conv length_tl less_Suc_eq list.sel(3) nat_neq_iff)
qed
apply (rule first_smaller_return)
apply (simp add:push_popL_def pathR_tl)
apply (rule first_smaller1)
apply (auto simp add:inc_decL_def pathR_tl map_tl)
done

(* extended call might have some stuff around it *)
definition ecall :: "'a list list \<Rightarrow> 'a list \<Rightarrow> bool" where
"ecall lst s = (\<exists>k1 k2.
   k1 < k2 \<and> k2 < length lst \<and> call (clip k2 k1 lst) \<and>
   set (take (Suc k1) lst) = {s} \<and>
   set (drop k2 lst) = {s})"

definition scall :: "'a list list \<Rightarrow> 'a list \<Rightarrow> bool" where
"scall lst s = (call lst \<and> hd lst = s)"

definition sncall :: "nat list \<Rightarrow> nat \<Rightarrow> bool" where
"sncall lst s = (ncall lst \<and> hd lst = s)"

definition const_seq :: "'a list \<Rightarrow> 'a \<Rightarrow> bool" where
"const_seq lst s = (set lst = {s})"

lemma const_single : "const_seq [x] x"
by (simp add:const_seq_def)

(* perhaps naturals can be divided into sequences easier? *)

definition call_end :: "nat list \<Rightarrow> nat \<Rightarrow> bool" where
"call_end lst s = (
   length lst > 1 \<and>
   Suc s = hd lst \<and>
   inc_decL lst \<and>
   first_one_smaller (length lst-1) lst)"

(*

find index

fun split_at :: "nat \<Rightarrow> nat list \<Rightarrow> nat list * nat list" where
"split_at a [] = [[]]"
""
*)

fun decompose :: "nat list \<Rightarrow> nat \<Rightarrow> nat list list" where
"decompose lst n = (
   let l1 = takeWhile (%k. k > n) lst in
   let rest = dropWhile (%k. k > n) lst in
   if length rest = 0 then [l1] else
   if length rest = 1 \<or> length (tl rest) \<ge> length lst
      then [l1@[hd rest]] else
   (l1@[hd rest]) # decompose (tl rest) n
)"

lemma concat_decompose_base :
   "dropWhile pred lst = [] \<Longrightarrow> takeWhile pred lst = lst"
by (induction lst; auto; metis list.distinct(1))

lemma concat_decompose_base2 :
   "dropWhile pred lst = [a] \<Longrightarrow> takeWhile pred lst @ [a] = lst"
by (induction lst; auto; metis list.distinct(1))

lemma concat_decompose_step :
   "dropWhile pred lst = a#rest \<Longrightarrow>
    takeWhile pred lst @ [a] @ rest = lst"
  by (metis append_Cons append_Nil takeWhile_dropWhile_id)

fun findIndices :: "'a list \<Rightarrow> 'a \<Rightarrow> nat list" where
"findIndices (b#rest) a =
   (if a = b then [0] else []) @ map Suc (findIndices rest a)"
| "findIndices [] a = []"

lemma get_index :
   "i \<in> set (findIndices lst a) \<Longrightarrow> lst!i = a"
by (induction lst arbitrary:i; auto)

lemma do_find :
   "length (findIndices lst a) > 0 \<Longrightarrow>
    take (hd (findIndices lst a)) lst @ [a] @
    drop (hd (findIndices lst a)+1) lst = lst"
by (induction lst; auto simp add: hd_map)

lemma tl_map_suc :
   "tl lst = map f lst2 \<Longrightarrow>
    tl (map g lst) = map (%x. g (f x)) lst2"
by (induction lst arbitrary:lst2; auto)

lemma split_findIndices :
   "length (findIndices lst a) > 0 \<Longrightarrow>
    tl (findIndices lst a) =
    map (%i. i + (hd (findIndices lst a)) + 1)
    (findIndices (drop (hd (findIndices lst a)+1) lst) a)"
by (induction lst; auto simp add: hd_map tl_map_suc)

lemma sorted_indices_aux :
  "findIndices lst a = i1 # i2 # ilst \<Longrightarrow>
   i1 < i2"
using split_findIndices [of lst a]
by auto

lemma tl_suc_rule :
   "length lst > 1 \<Longrightarrow>
    tl lst! i < tl lst ! Suc i \<Longrightarrow>
    lst! Suc i < lst ! Suc (Suc i)"
by (cases lst; auto)

lemma map_suc_rule :
"n < length lst \<Longrightarrow> m < length lst \<Longrightarrow>
 lst!n < lst!m \<Longrightarrow>
 map (\<lambda>i. Suc (i + x)) lst ! n < map (\<lambda>i. Suc (i + x)) lst ! m"
  by simp

lemma sorted_again :
   "i + 1 < length (findIndices lst a) \<Longrightarrow>
    findIndices lst a ! i < findIndices lst a ! (i+1)"
apply (induction i arbitrary:lst)
apply auto
apply (case_tac "findIndices lst a"; auto)
apply (case_tac "list"; auto)
using sorted_indices_aux apply force
apply (rule tl_suc_rule)
apply auto
subgoal for i lst
using split_findIndices [of lst a]
apply simp
apply (cases "findIndices lst a = []"; auto)
apply (rule map_suc_rule)
  apply (metis Suc_lessD Suc_lessE diff_Suc_1 length_map length_tl)
  apply (metis Suc_lessE diff_Suc_1 length_map length_tl)
  by (metis Nitpick.size_list_simp(2) Suc_less_eq length_map)
done

(*
lemma nth_split_findIndices :
   "length (findIndices lst a) > n \<Longrightarrow>
    drop (Suc n) (findIndices lst a) =
    map (%i. i + (findIndices lst a!n) + 1)
    (findIndices (drop ((findIndices lst a!n)+1) lst) a)"
apply (induction n arbitrary:lst)
apply auto
subgoal for lst
using split_findIndices [of lst a]
apply auto
by (simp add: drop_Suc hd_conv_nth)
apply (case_tac lst)
apply auto

*)

lemma weird_mono_aux :
   "(\<forall>n. Suc n < limit \<longrightarrow> f n < f (Suc n)) \<Longrightarrow> k+m < limit \<Longrightarrow> (f k::nat) \<le> f (k+m)"
by (induction m; auto)

lemma weird_mono :
   "(\<forall>n. Suc n < limit \<longrightarrow> f n < f (Suc n)) \<Longrightarrow>
   k < limit \<Longrightarrow> m < limit \<Longrightarrow> m \<le> k \<Longrightarrow> (f m::nat) \<le> f k"
using weird_mono_aux [of limit f]
  by (metis le_add_diff_inverse)


lemma sorted_indices : "sorted (findIndices lst a)"
apply (rule sorted_nth_monoI)
apply (rule weird_mono [of "length (findIndices lst a)"
  "%i. findIndices lst a ! i"])
apply auto
using sorted_again by force

(* do splitting based on indexes *)
fun indexSplit :: "nat list \<Rightarrow> 'a list \<Rightarrow> 'a list list" where
"indexSplit (i1#ilst) lst =
   take (Suc i1) lst # indexSplit (map (%x. x-i1-1) ilst) (drop (Suc i1) lst)"
| "indexSplit [] lst = [lst]"

value "findIndices [a,a] a"

value "((\<lambda>x. x - Suc 0) \<circ> Suc) 0"

lemma funext : "(\<forall>x. f x = g x) \<Longrightarrow> f = g"
by auto

lemma inc_dec : "((\<lambda>x. x - Suc 0) \<circ> Suc) = id"
by (rule funext; auto)

lemma duh : "map ((\<lambda>x. x - Suc 0) \<circ> Suc) lst = lst"
by (simp add:inc_dec)

lemma empty_split :
   "set (indexSplit ilst []) = {[]}"
by (induction ilst "[]" rule:indexSplit.induct; auto)

lemma empty_length : "set lst = {[]} \<Longrightarrow> concat lst = []"
  by (simp add: empty_split)

lemma empty_split2 : "concat (indexSplit ilst []) = []"
  by (simp add: empty_split)

lemma split_combine_step :
   "concat (indexSplit (map Suc ilst) (aa # lst)) =
    aa # concat (indexSplit ilst lst)"
apply (induction ilst lst rule:indexSplit.induct)
apply auto
  by (metis comp_apply diff_Suc_Suc)

lemma split_and_combine :
   "concat (indexSplit (findIndices lst a) lst) = lst"
by (induction lst; auto simp add:duh split_combine_step)

lemma decompose_ncall :
  "ncall lst \<Longrightarrow>
   \<exists>pieces. concat pieces = clip (length lst-3) 1 lst \<and>
   (\<forall>x \<in> set pieces. call_end x (hd lst) \<or> const_seq x (hd lst))"


(* decompose call to sub calls ...
   cycle could also be split into subcycles *)
lemma decompose_call :
  "call lst \<Longrightarrow>
   \<exists>pieces. concat pieces = clip (length lst-3) 1 lst \<and>
   (\<forall>x \<in> set pieces. scall x (hd lst) \<or> const_seq x (hd lst))"



lemma call_invariant :
  "push_popL (map snd lst) \<Longrightarrow>
   first_return k (map snd lst) \<Longrightarrow>
   monoI iv (hd lst) \<Longrightarrow>
   pathR (mono_rules iv) lst \<Longrightarrow>
   iv (fst (hd lst)) \<Longrightarrow>
   length lst > 1 \<Longrightarrow>
   (snd (hd lst), snd (lst!1)) \<in> tlR
  "


end
