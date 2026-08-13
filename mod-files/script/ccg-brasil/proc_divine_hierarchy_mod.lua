-- Divine Hierarchy Rules - Mod
-- Isolated hierarchy procedure for custom cards.
if DivineHierarchyMod then return end
DivineHierarchyMod={}
DivineHierarchyMod.ranks={}
FLAG_DIVINE_HIERARCHY_MOD=161300000

function DivineHierarchyMod.Register(c,rank)
	DivineHierarchyMod.ranks[c:GetOriginalCode()]=rank
	DivineHierarchyMod.Start()
end

function DivineHierarchyMod.Start()
	if DivineHierarchyMod.started then return end
	DivineHierarchyMod.started=true
	local function rankfilter(c)
		local rank=DivineHierarchyMod.ranks[c:GetOriginalCode()]
		return c:IsFaceup() and rank and c:GetFlagEffectLabel(FLAG_DIVINE_HIERARCHY_MOD)~=rank
	end
	local function rankcon(e,tp,eg,ev,ep,re,r,rp)
		return Duel.IsExistingMatchingCard(rankfilter,tp,0xff,0xff,1,nil)
	end
	local function rankop(e,tp,eg,ev,ep,re,r,rp)
		local g=Duel.GetMatchingGroup(rankfilter,tp,0xff,0xff,nil)
		for c in aux.Next(g) do
			c:ResetFlagEffect(FLAG_DIVINE_HIERARCHY_MOD)
			c:RegisterFlagEffect(FLAG_DIVINE_HIERARCHY_MOD,0,0,0,DivineHierarchyMod.ranks[c:GetOriginalCode()])
		end
	end
	local function hrfilter(e,te,c)
		if not te then return false end
		local tc=te:GetOwner()
		return (te:IsMonsterEffect() and c~=tc
			and (not tc:GetFlagEffectLabel(FLAG_DIVINE_HIERARCHY_MOD)
				or c:GetFlagEffectLabel(FLAG_DIVINE_HIERARCHY_MOD)>tc:GetFlagEffectLabel(FLAG_DIVINE_HIERARCHY_MOD)))
			or (te:IsSpellTrapEffect() and c~=tc)
	end
	local function rellimit(e,c,tp,sumtp)
		return c:HasFlagEffect(FLAG_DIVINE_HIERARCHY_MOD) and c:IsFaceup() and c:IsControler(1-tp)
	end
	local function sumlimit(e,c)
		if not c then return false end
		return e:GetHandler():HasFlagEffect(FLAG_DIVINE_HIERARCHY_MOD)
			and e:GetHandler():IsFaceup() and not c:IsControler(e:GetHandlerPlayer())
	end
	local function reptg(e,tp,eg,ep,ev,re,r,rp,chk)
		local c=e:GetHandler()
		if chk==0 then return c:IsReason(REASON_EFFECT) and r&REASON_EFFECT~=0
			and re and re:IsSpellTrapEffect() and c:HasFlagEffect(FLAG_DIVINE_HIERARCHY_MOD) end
		return true
	end
	local function battlelevelpierce(c,hr)
		if not c or not c:IsMonster() then return false end
		local lv=c:GetOriginalLevel()
		return (hr==1 and lv>=10) or (hr==2 and lv>=12)
	end
	local function tglimit(e,c)
		if not c then return false end
		local hr=e:GetHandler():GetFlagEffectLabel(FLAG_DIVINE_HIERARCHY_MOD)
		if not hr or battlelevelpierce(c,hr) then return false end
		local other=c:GetFlagEffectLabel(FLAG_DIVINE_HIERARCHY_MOD)
		return not other or hr>other
	end
	local function stgcon(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if not c:HasFlagEffect(FLAG_DIVINE_HIERARCHY_MOD) then return false end
		local effs={c:GetCardEffect()}
		for _,eff in ipairs(effs) do
			if eff:GetOwner()~=c and not eff:GetOwner():IsCode(0)
				and not eff:IsHasProperty(EFFECT_FLAG_IGNORE_IMMUNE)
				and eff:GetCode()~=EFFECT_SPSUMMON_PROC
				and (eff:GetTarget()==aux.PersistentTargetFilter or not eff:IsHasType(EFFECT_TYPE_GRANT+EFFECT_TYPE_FIELD)) then
				return true
			end
		end
		return false
	end
	local function stgop(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local effs={c:GetCardEffect()}
		for _,eff in ipairs(effs) do
			if eff:GetOwner()~=c and not eff:GetOwner():IsCode(0)
				and not eff:IsHasProperty(EFFECT_FLAG_IGNORE_IMMUNE)
				and eff:GetCode()~=EFFECT_SPSUMMON_PROC
				and (eff:GetTarget()==aux.PersistentTargetFilter or not eff:IsHasType(EFFECT_TYPE_GRANT+EFFECT_TYPE_FIELD)) then
				eff:Reset()
			end
		end
	end
	local rank=Effect.GlobalEffect()
	rank:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	rank:SetCode(EVENT_ADJUST)
	rank:SetCondition(rankcon)
	rank:SetOperation(rankop)
	Duel.RegisterEffect(rank,0)
	local control=Effect.GlobalEffect()
	control:SetType(EFFECT_TYPE_FIELD)
	control:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	control:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	control:SetTargetRange(LOCATION_ONFIELD|LOCATION_FZONE,LOCATION_ONFIELD|LOCATION_FZONE)
	control:SetTarget(aux.TargetBoolFunction(aux.FaceupFilter(Card.HasFlagEffect,FLAG_DIVINE_HIERARCHY_MOD)))
	Duel.RegisterEffect(control,0)
	local immunity=control:Clone()
	immunity:SetCode(EFFECT_IMMUNE_EFFECT)
	immunity:SetValue(hrfilter)
	Duel.RegisterEffect(immunity,0)
	local rel=Effect.GlobalEffect()
	rel:SetType(EFFECT_TYPE_FIELD)
	rel:SetCode(EFFECT_CANNOT_RELEASE)
	rel:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	rel:SetTargetRange(1,1)
	rel:SetTarget(rellimit)
	Duel.RegisterEffect(rel,0)
	local ep=Effect.GlobalEffect()
	ep:SetDescription(aux.Stringid(421,15))
	ep:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ep:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ep:SetRange(LOCATION_ONFIELD|LOCATION_FZONE)
	ep:SetCode(EVENT_TURN_END)
	ep:SetCondition(stgcon)
	ep:SetOperation(stgop)
	local r1=Effect.GlobalEffect()
	r1:SetType(EFFECT_TYPE_SINGLE)
	r1:SetCode(EFFECT_UNRELEASABLE_SUM)
	r1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	r1:SetRange(LOCATION_MZONE)
	r1:SetValue(sumlimit)
	local dg=r1:Clone()
	dg:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	dg:SetValue(tglimit)
	local bt=dg:Clone()
	bt:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	local im=Effect.GlobalEffect()
	im:SetCode(EFFECT_SEND_REPLACE)
	im:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	im:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	im:SetRange(LOCATION_ONFIELD|LOCATION_FZONE)
	im:SetTarget(reptg)
	im:SetValue(function(e,c) return false end)
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	ge1:SetTargetRange(LOCATION_ONFIELD|LOCATION_FZONE,LOCATION_ONFIELD|LOCATION_FZONE)
	ge1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	ge1:SetTarget(aux.TargetBoolFunction(aux.FaceupFilter(Card.HasFlagEffect,FLAG_DIVINE_HIERARCHY_MOD)))
	ge1:SetLabelObject(ep)
	Duel.RegisterEffect(ge1,0)
	local ge2=ge1:Clone()
	ge2:SetLabelObject(r1)
	Duel.RegisterEffect(ge2,0)
	local ge3=ge1:Clone()
	ge3:SetLabelObject(dg)
	Duel.RegisterEffect(ge3,0)
	local ge4=ge1:Clone()
	ge4:SetLabelObject(bt)
	Duel.RegisterEffect(ge4,0)
	local ge5=ge1:Clone()
	ge5:SetLabelObject(im)
	Duel.RegisterEffect(ge5,0)
end