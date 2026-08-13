--Procedure for Union monster equip/unequip - Mod
--c: Union monster
--f: Potential targets
--oldequip: Uses old rules for number of monster equiped (A monster can only by equipped with 1 Union monster at a time.)
--oldprotect: Uses old rules for destroy replacement (If the equipped monster would be destroyed, destroy this card instead.)
function Auxiliary.AddUnionProcedureMod(c,f,oldequip,oldprotect)
	if oldprotect == nil then oldprotect = oldequip end
	--equip
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(1068)
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e1:SetTarget(Auxiliary.UnionTargetMod(f,oldequip))
	e1:SetOperation(Auxiliary.UnionOperationMod(f))
	c:RegisterEffect(e1)
	--unequip
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(2)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	if oldequip then
		e2:SetCondition(Auxiliary.IsUnionStateMod)
	else
		e2:SetCondition(function(e) return e:GetHandler():GetEquipTarget()end)
	end
	e2:SetTarget(Auxiliary.UnionSumTargetMod(oldequip))
	e2:SetOperation(Auxiliary.UnionSumOperationMod(oldequip))
	c:RegisterEffect(e2)
	--destroy sub
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_EQUIP)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	if oldprotect then
		e3:SetCondition(Auxiliary.IsUnionStateMod)
	else
		e3:SetCondition(function(e) return e:GetHandler():GetEquipTarget()end)
	end
	e3:SetValue(Auxiliary.UnionReplaceMod(oldprotect))
	c:RegisterEffect(e3)
	--eqlimit
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_UNION_LIMIT)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e4:SetValue(Auxiliary.UnionLimitMod(f))
	c:RegisterEffect(e4)
	--auxiliary function compatibility
	if oldequip then
		local m=c:GetMetatable()
		m.old_union=true
	end
end
function Auxiliary.UnionFilterMod(c,f,oldrule)
	return c:IsFaceup() and (not f or f(c))
end
function Auxiliary.UnionTargetMod(f,oldrule)
	return function (e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		local c=e:GetHandler()
		local code=c:GetOriginalCode()
		if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and Auxiliary.UnionFilterMod(chkc,f,oldrule) end
		if chk==0 then return e:GetHandler():GetFlagEffect(code)==0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(Auxiliary.UnionFilterMod,tp,LOCATION_MZONE,0,1,c,f,oldrule) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
		local g=Duel.SelectTarget(tp,Auxiliary.UnionFilterMod,tp,LOCATION_MZONE,0,1,1,c,f,oldrule)
		Duel.SetOperationInfo(0,CATEGORY_EQUIP,g,1,0,0)
		c:RegisterFlagEffect(code,RESET_EVENT+(RESETS_STANDARD-RESET_TOFIELD-RESET_LEAVE)+RESET_PHASE+PHASE_END,0,1)
	end
end
function Auxiliary.UnionOperationMod(f)
	return function (e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local tc=Duel.GetFirstTarget()
		local fromhand=c:IsLocation(LOCATION_HAND)
		if not c:IsRelateToEffect(e) or (c:IsLocation(LOCATION_MZONE) and c:IsFacedown()) then return end
		if not tc:IsRelateToEffect(e) or (f and not f(tc)) then
			Duel.SendtoGrave(c,REASON_EFFECT)
			return
		end
		if not Duel.Equip(tp,c,tc,fromhand) then return end
		aux.SetUnionStateMod(c)
	end
end
function Auxiliary.UnionSumTargetMod(oldrule)
	return function (e,tp,eg,ep,ev,re,r,rp,chk)
		local c=e:GetHandler()
		local code=c:GetOriginalCode()
		local pos=POS_FACEUP
		if oldrule then pos=POS_FACEUP_ATTACK end
		if chk==0 then return c:GetFlagEffect(code)==0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,false,pos) end
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
		c:RegisterFlagEffect(code,RESET_EVENT+(RESETS_STANDARD-RESET_TOFIELD-RESET_LEAVE)+RESET_PHASE+PHASE_END,0,1)
	end
end
function Auxiliary.UnionSumOperationMod(oldrule)
	return function (e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if not c:IsRelateToEffect(e) then return end
		local pos=POS_FACEUP
		if oldrule then pos=POS_FACEUP_ATTACK end
		if Duel.SpecialSummon(c,0,tp,tp,true,false,pos)==0 and Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
			and c:IsCanBeSpecialSummoned(e,0,tp,true,false,pos) then
			Duel.SendtoGrave(c,REASON_RULE)
		end
	end
end
function Auxiliary.UnionReplaceMod(oldrule)
	return function (e,re,r,rp)
		if oldrule then
			return (r&REASON_BATTLE)~=0
		else
			return (r&REASON_BATTLE)~=0 or (r&REASON_EFFECT)~=0
		end
	end
end
function Auxiliary.UnionLimitMod(f)
	return function (e,c)
		return (not f or f(c)) or e:GetHandler():GetEquipTarget()==c
	end
end
function Auxiliary.IsUnionStateMod(effect)
	local c=effect:GetHandler()
	return c:IsHasEffect(EFFECT_UNION_STATUS)
end
function Auxiliary.SetUnionStateMod(c)
	local eset={c:GetCardEffect(EFFECT_UNION_LIMIT)}
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_EQUIP_LIMIT)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetValue(eset[1]:GetValue())
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e0)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UNION_STATUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
	if c.old_union then
		local e2=e1:Clone()
		e2:SetCode(EFFECT_OLDUNION_STATUS)
		c:RegisterEffect(e2)
	end
end
function Auxiliary.CheckUnionEquipMod(uc,tc)
	return tc and tc:IsFaceup()
end
