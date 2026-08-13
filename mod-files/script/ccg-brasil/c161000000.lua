--Action Field Functions
local id=161999999

if not ActionDuel then

	function Card.IsActionCard(c)
		return c:IsType(TYPE_ACTION) and not c.af and not c:IsType(TYPE_FIELD) and not c:IsOriginalCode(id)
	end

	function Card.IsActionSpell(c)
		return c:IsType(TYPE_ACTION) and c:IsSpell() and not c.af
	end

	function Card.IsActionTrap(c)
		return c:IsType(TYPE_ACTION) and c:IsTrap() and not c.af
	end

	function Card.IsActionField(c)
		return c:IsType(TYPE_ACTION) and c.af
	end

	local tableActionGeneric={
		150000024,150000033,
		150000047,150000042,
		150000011,150000044,
		150000022,150000020
	}

	ActionDuel={}

	function ActionDuel.Start()
		local e1=Effect.GlobalEffect()
		e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_NO_TURN_RESET)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_ADJUST)
		e1:SetCountLimit(1)
		e1:SetOperation(ActionDuel.op)
		Duel.RegisterEffect(e1,0)

		-- Add Action Card: Main Phase 1
		local e2=ActionDuel.createsearcheffect(ActionDuel.condition_m1,id+101)
		ActionDuel.grantsearcheffect(e2)
		local e3=e2:Clone()
		e3:SetCode(EVENT_CHAINING)
		ActionDuel.grantsearcheffect(e3)

		-- Add Action Card: Battle Phase
		local e4=ActionDuel.createsearcheffect(ActionDuel.condition_bp,id+102)
		ActionDuel.grantsearcheffect(e4)
		local e5=e4:Clone()
		e5:SetCode(EVENT_CHAINING)
		ActionDuel.grantsearcheffect(e5)

		-- Add Action Card: Main Phase 2
		local e15=ActionDuel.createsearcheffect(ActionDuel.condition_m2,id+103)
		ActionDuel.grantsearcheffect(e15)
		local e16=e15:Clone()
		e16:SetCode(EVENT_CHAINING)
		ActionDuel.grantsearcheffect(e16)

		--act ac in hand
		local e6=Effect.GlobalEffect()
		e6:SetType(EFFECT_TYPE_FIELD)
		e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_SET_AVAILABLE)
		e6:SetCode(EFFECT_BECOME_QUICK)
		e6:SetTargetRange(0xff,0xff)
		e6:SetTarget(aux.TargetBoolFunction(Card.IsActionSpell))
		Duel.RegisterEffect(e6,0)

		local e7=e6:Clone()
		e7:SetDescription(aux.Stringid(id,7))
		e7:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
		Duel.RegisterEffect(e7,0)

		local e8=e6:Clone()
		e8:SetDescription(aux.Stringid(id,7))
		e8:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		Duel.RegisterEffect(e8,0)

		--cover
		local e9=Effect.GlobalEffect()
		e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e9:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
		e9:SetCode(EVENT_ADJUST)
		e9:SetCondition(ActionDuel.covercon)
		e9:SetOperation(ActionDuel.coverop)
		Duel.RegisterEffect(e9,0)

		-- Link Summon restriction
		local e10=Effect.GlobalEffect()
		e10:SetType(EFFECT_TYPE_FIELD)
		e10:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e10:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
		e10:SetTargetRange(1,1)
		e10:SetTarget(ActionDuel.linklimit)
		Duel.RegisterEffect(e10,0)

		-- Unlock Link Summons for the turn
		local e11=Effect.GlobalEffect()
		e11:SetDescription(aux.Stringid(id,10))
		e11:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e11:SetRange(LOCATION_FZONE)
		e11:SetCode(EVENT_FREE_CHAIN)
		e11:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		e11:SetCondition(ActionDuel.linkunlockcon)
		e11:SetTarget(ActionDuel.linkunlocktg)
		e11:SetOperation(ActionDuel.linkunlockop)

		local e12=Effect.GlobalEffect()
		e12:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
		e12:SetTargetRange(LOCATION_SZONE,LOCATION_SZONE)
		e12:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		e12:SetLabelObject(e11)
		Duel.RegisterEffect(e12,0)

		-- Field Spells are unaffected by effects
		local e13=Effect.GlobalEffect()
		e13:SetType(EFFECT_TYPE_SINGLE)
		e13:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
		e13:SetCode(EFFECT_IMMUNE_EFFECT)
		e13:SetRange(LOCATION_FZONE)
		e13:SetValue(ActionDuel.fieldimmune)

		local e14=Effect.GlobalEffect()
		e14:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
		e14:SetTargetRange(LOCATION_FZONE,LOCATION_FZONE)
		e14:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		e14:SetLabelObject(e13)
		Duel.RegisterEffect(e14,0)
	end

	function ActionDuel.cfilter(c)
		return c:IsType(TYPE_ACTION) and c:GetFlagEffect(COVER_ACTION)==0
	end

	function ActionDuel.covercon(e,tp,eg,ep,ev,re,r,rp)
		return Duel.IsExistingMatchingCard(ActionDuel.cfilter,0,0xff,0xff,1,nil)
	end

	function ActionDuel.coverop(e,tp,eg,ep,ev,re,r,rp)
		for c in aux.Next(Duel.GetMatchingGroup(ActionDuel.cfilter,0,0xff,0xff,nil)) do
			c:Cover(COVER_ACTION)
			c:RegisterFlagEffect(COVER_ACTION,0,0,0)
		end
	end

	function ActionDuel.linklimit(e,c,sump,sumtype)
		return c:IsType(TYPE_LINK) and Duel.GetFlagEffect(sump,ACTION_DUEL_LINK_UNLOCK)==0
	end

	function ActionDuel.fieldimmune(e,te)
		return true
	end

	function ActionDuel.pendfilter(c)
		return c:IsMonster() and c:IsType(TYPE_PENDULUM)
	end

	function ActionDuel.pendfilter2(c,code)
		return ActionDuel.pendfilter(c) and not c:IsCode(code)
	end

	function ActionDuel.haspendpair(tp)
		local g=Duel.GetMatchingGroup(ActionDuel.pendfilter,tp,LOCATION_HAND,0,nil)
		for tc in aux.Next(g) do
			if g:IsExists(ActionDuel.pendfilter2,1,tc,tc:GetCode()) then
				return true
			end
		end
		return false
	end

	function ActionDuel.linkunlockcon(e,tp,eg,ep,ev,re,r,rp)
		return Duel.GetFlagEffect(tp,ACTION_DUEL_LINK_UNLOCK)==0
			and ActionDuel.haspendpair(tp)
	end

	function ActionDuel.linkunlocktg(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return ActionDuel.haspendpair(tp) end
	end

	function ActionDuel.linkunlockop(e,tp,eg,ep,ev,re,r,rp)
		if Duel.GetFlagEffect(tp,ACTION_DUEL_LINK_UNLOCK)>0 then return end
		if not ActionDuel.haspendpair(tp) then return end
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,11))
		local g1=Duel.SelectMatchingCard(tp,ActionDuel.pendfilter,tp,LOCATION_HAND,0,1,1,nil)
		local tc=g1:GetFirst()
		if not tc then return end
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,11))
		local g2=Duel.SelectMatchingCard(tp,ActionDuel.pendfilter2,tp,LOCATION_HAND,0,1,1,tc,tc:GetCode())
		if #g2==0 then return end
		g1:Merge(g2)
		Duel.ConfirmCards(1-tp,g1)
		Duel.ShuffleHand(tp)
		Duel.RegisterFlagEffect(tp,ACTION_DUEL_LINK_UNLOCK,RESET_PHASE|PHASE_END,0,1)
	end

	function ActionDuel.op(e,tp,eg,ep,ev,re,r,rp)
		local actionFieldToBeUsed={}
		local announceFilter={TYPE_ACTION,OPCODE_ISTYPE,TYPE_FIELD,OPCODE_ISTYPE,OPCODE_AND,OPCODE_ALLOW_ALIASES}
		while #actionFieldToBeUsed==0 do
			for p=0,1 do
				if Duel.SelectYesNo(p,aux.Stringid(id,3)) then
					Duel.Hint(HINT_SELECTMSG,p,aux.Stringid(id,4))
					local af=Duel.AnnounceCard(p,table.unpack(announceFilter))
					table.insert(actionFieldToBeUsed,af)
				end
			end
			if #actionFieldToBeUsed>0 then
				break
			else
				Duel.Hint(HINT_MESSAGE,0,aux.Stringid(id,5))
				Duel.Hint(HINT_MESSAGE,1,aux.Stringid(id,5))
			end
		end
		if #actionFieldToBeUsed>1 then
			Duel.Hint(HINT_MESSAGE,0,aux.Stringid(id,6))
			Duel.Hint(HINT_MESSAGE,1,aux.Stringid(id,6))
			local coin=Duel.TossCoin(0,1)
			table.remove(actionFieldToBeUsed,coin==COIN_HEADS and 2 or 1)
		end
		Duel.Hint(HINT_CARD,0,actionFieldToBeUsed[1])
		for p=0,1 do
			local tc=Duel.CreateToken(p,actionFieldToBeUsed[1])
			e:SetLabelObject(tc)

			local e1=Effect.CreateEffect(tc)
			e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
			e1:SetCode(EVENT_LEAVE_FIELD)
			e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetOperation(function(e) Duel.SendtoDeck(e:GetHandler(),nil,-2,REASON_RULE) end)
			tc:RegisterEffect(e1)

			local e2=Effect.CreateEffect(tc)
			e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_CHAIN_END)
			e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetLabelObject(tc)
			e2:SetOperation(ActionDuel.returnop)
			Duel.RegisterEffect(e2,0)

			local ea=Effect.CreateEffect(tc)
			ea:SetType(EFFECT_TYPE_SINGLE)
			ea:SetCode(EFFECT_CANNOT_TO_DECK)
			ea:SetRange(LOCATION_SZONE)
			ea:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
			tc:RegisterEffect(ea)

			local eb=ea:Clone()
			eb:SetCode(EFFECT_CANNOT_REMOVE)
			tc:RegisterEffect(eb)

			local ec=ea:Clone()
			ec:SetCode(EFFECT_CANNOT_TO_HAND)
			tc:RegisterEffect(ec)

			local ed=ea:Clone()
			ed:SetCode(EFFECT_CANNOT_TO_GRAVE)
			tc:RegisterEffect(ed)

			local ee=ea:Clone()
			ee:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
			ee:SetValue(1)
			tc:RegisterEffect(ee)

			if Duel.IsExistingMatchingCard(Card.IsCode,tp,0xff,0xff,1,nil,CARD_VANILLA_MODE) then
				table.insert(tc.tableAction,CARD_POTENTIAL_YELL)
				table.insert(tc.tableAction,CARD_ABILITY_YELL)
			end

			if Duel.CheckLocation(tc:GetOwner(),LOCATION_FZONE,0) then
				Duel.MoveToField(tc,tc:GetOwner(),tc:GetOwner(),LOCATION_FZONE,POS_FACEUP,true)
			else
				Duel.SendtoDeck(tc,nil,-2,REASON_RULE)
			end
		end
	end

	function ActionDuel.returnop(e)
		local c=e:GetLabelObject()
		local tp=c:GetControler()
		if Duel.CheckLocation(tp,LOCATION_FZONE,0) then
			Duel.MoveToField(c,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		end
	end

	function ActionDuel.handcheck(tp)
		if Duel.IsPlayerAffectedByEffect(tp,CARD_EARTHBOUND_TUNDRA) then
			return Duel.IsExistingMatchingCard(Card.IsActionCard,tp,LOCATION_HAND,0,2,nil)
		else
			return Duel.IsExistingMatchingCard(Card.IsActionCard,tp,LOCATION_HAND,0,1,nil)
		end
	end

	function ActionDuel.cansearch(e,tp)
		local c=e:GetHandler()
		return (not ActionDuel.handcheck(tp) or ActionDuel.fieldallowsmultiple(c))
			and not c:IsStatus(STATUS_CHAINING)
	end

	function ActionDuel.condition_m1(e,tp,eg,ep,ev,re,r,rp)
		return Duel.GetCurrentPhase()==PHASE_MAIN1 and ActionDuel.cansearch(e,tp)
	end

	function ActionDuel.condition_bp(e,tp,eg,ep,ev,re,r,rp)
		local ph=Duel.GetCurrentPhase()
		return (ph==PHASE_BATTLE_START or ph==PHASE_BATTLE_STEP or ph==PHASE_BATTLE)
			and ActionDuel.cansearch(e,tp)
	end

	function ActionDuel.condition_m2(e,tp,eg,ep,ev,re,r,rp)
		return Duel.GetCurrentPhase()==PHASE_MAIN2 and ActionDuel.cansearch(e,tp)
	end

	function ActionDuel.createsearcheffect(condition,count_code)
		local e=Effect.GlobalEffect()
		e:SetDescription(aux.Stringid(id,0))
		e:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e:SetRange(LOCATION_FZONE)
		e:SetCode(EVENT_FREE_CHAIN)
		e:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		e:SetCondition(condition)
		e:SetTarget(ActionDuel.target)
		e:SetOperation(ActionDuel.operation)
		e:SetCountLimit(1,count_code)
		return e
	end

	function ActionDuel.grantsearcheffect(search_effect)
		local ge=Effect.GlobalEffect()
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
		ge:SetTargetRange(LOCATION_SZONE,LOCATION_SZONE)
		ge:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		ge:SetLabelObject(search_effect)
		Duel.RegisterEffect(ge,0)
	end

	function ActionDuel.removepoolcard(t,code)
		for i=#t,1,-1 do
			if t[i]==code then
				table.remove(t,i)
				return
			end
		end
	end

	function ActionDuel.fieldallowsmultiple(c)
		return c and c.af and string.find(c.af,'m')
	end

	function ActionDuel.target(e,tp,eg,ep,ev,re,r,rp,chk)
		local c=e:GetHandler()
		local t=c.tableAction or tableActionGeneric
		if chk==0 then return #t>0 end
		local ac=Duel.GetRandomNumber(1,#t)
		e:SetLabel(t[ac])
	end

	function ActionDuel.operation(e,tp,eg,ep,ev,re,r,rp)
		if Duel.GetCurrentChain()>0 and not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end

		local c=e:GetHandler()
		if ActionDuel.handcheck(tp) and not ActionDuel.fieldallowsmultiple(c) then return end

		local tokenp=tp
		local send_to_grave=false
		if Duel.SelectYesNo(1-tp,aux.Stringid(id,1)) then
			if not ActionDuel.handcheck(1-tp) then
				local opt=Duel.SelectOption(1-tp,aux.Stringid(id,8),aux.Stringid(id,9))
				if opt==0 then
					tokenp=1-tp
				else
					send_to_grave=true
				end
			else
				send_to_grave=true
			end
		end

		local token=Duel.CreateToken(tokenp,e:GetLabel())
		if ActionDuel.fieldallowsmultiple(c) and c.tableAction then
			ActionDuel.removepoolcard(c.tableAction,e:GetLabel())
		end

		if send_to_grave then
			Duel.SendtoGrave(token,REASON_EFFECT)
			return
		end

		Duel.SendtoHand(token,nil,REASON_EFFECT)
		ActionDuel.chktrap(token,tokenp,e,eg,ep,ev,re,r,rp)
	end

	function ActionDuel.chktrap(tc,tp,e,eg,ep,ev,re,r,rp)
		if not (tc and tc:IsTrap()) then return end
		if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
		if not tc:CheckActivateEffect(false,false,false) then return end

		local te=tc:GetActivateEffect()
		if not te then return end

		Duel.ConfirmCards(1-tp,tc)
		local tg=te:GetTarget()
		local co=te:GetCost()
		local op=te:GetOperation()

		e:SetCategory(te:GetCategory())
		e:SetProperty(te:GetProperty())
		Duel.ClearTargetCard()
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
		Duel.Hint(HINT_CARD,0,tc:GetCode())
		tc:CreateEffectRelation(te)

		if co then co(te,tp,eg,ep,ev,re,r,rp,1) end
		if tg then tg(te,tp,eg,ep,ev,re,r,rp,1) end

		Duel.BreakEffect()

		local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
		if g then
			for etc in aux.Next(g) do
				etc:CreateEffectRelation(te)
			end
		end

		if op then op(te,tp,eg,ep,ev,re,r,rp) end

		tc:ReleaseEffectRelation(te)
		if g then
			for etc in aux.Next(g) do
				etc:ReleaseEffectRelation(te)
			end
		end

		tc:SetStatus(STATUS_LEAVE_CONFIRMED,true)
		tc:CancelToGrave(false)
		Duel.SendtoGrave(tc,REASON_RULE)
	end

	COVER_ACTION=301
	CARD_VANILLA_MODE=511004400
	CARD_POTENTIAL_YELL=511004399
	CARD_ABILITY_YELL=511004401
	CARD_EARTHBOUND_TUNDRA=150000000
	ACTION_DUEL_LINK_UNLOCK=161999999

	local OCGActionFields={
		4064256,
		59197169,
		4545854,
		2084239,
		54306223,
		23424603,
		62188962,
		82999629,
		CARD_UMI,
		86318356,
		4215636,
		32391631,
		45778932,
		94585852,
		18161786,
		50913601,
		56074358,
		80921533,
		14001430,
		CARD_UMI,
		22751868,
		75782277,
		10080320,
		7617062,
		37694547,
		33017655,
		56594520,
		87430998,
		62265044,
		78082039,
		28120197,
		85668449,
		712559,
		35956022
	}
end