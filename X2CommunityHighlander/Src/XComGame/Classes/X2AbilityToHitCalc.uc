//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc extends Object
	dependson(XComLWTuple)
	abstract;

var array<ShotModifierInfo> HitModifiers;       // Configured in the ability template to provide always-on modifiers.

// Issue #13 - Remove protection of ShotBreakdown
var ShotBreakdown m_ShotBreakdown;    //  Temp used to calculate shot info and hit chance
var protected bool          m_bDebugModifiers;  //  Temp used to display logging in AddModifier

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext);
protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false);
function bool NoGameStateOnMiss() { return false; }

function AddHitModifier(const int ModValue, const string ModReason, optional EAbilityHitResult ModType=eHit_Success)
{
	local ShotModifierInfo Mod;
	Mod.Value = ModValue;
	Mod.Reason = ModReason;
	Mod.ModType = ModType;
	HitModifiers.AddItem(Mod);
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown kBreakdown)
{
	GetHitChance(kAbility, kTarget);
	kBreakdown = m_ShotBreakdown;
	return kBreakdown.FinalHitChance;
}

//  Inside of GetHitChance, m_ShotBreakdown should be initially reset, then all modifiers to the shot should be added via this function.
protected function AddModifier(const int ModValue, const string ModReason, optional EAbilityHitResult ModType=eHit_Success)
{
	local ShotModifierInfo Mod;

	switch(ModType)
	{
	case eHit_Miss:
		//  Miss should never be modified, only Success
		`assert(false);
		return;
	}

	if (ModValue != 0)
	{
		Mod.ModType = ModType;
		Mod.Value = ModValue;
		Mod.Reason = ModReason;
		m_ShotBreakdown.Modifiers.AddItem(Mod);
		m_ShotBreakdown.ResultTable[ModType] += ModValue;
		m_ShotBreakdown.FinalHitChance = m_ShotBreakdown.ResultTable[eHit_Success];
	}
	`log("Modifying" @ ModType @ (ModValue >= 0 ? "+" : "") $ ModValue @ "(" $ ModReason $ "), New hit chance:" @ m_ShotBreakdown.FinalHitChance, m_bDebugModifiers, 'XCom_HitRolls');
}

protected function FinalizeHitChance()
{
	local int i;
	local EAbilityHitResult HitResult;
	local float GrazeScale;
	local int FinalGraze;

	// Start Issue #14 - allow overriding of HitChance by mutating this instance
	//                   of X2AbilityToHitCalc
	local XComLWTuple OverrodeHitChanceTuple;

	//set up a Tuple for return value - true means the to-hit calcs were overridden, so you should simply exit
	OverrodeHitChanceTuple = new class'XComLWTuple';
	OverrodeHitChanceTuple.Id = 'FinalizeHitChance';
	OverrodeHitChanceTuple.Data.Add(1);
	OverrodeHitChanceTuple.Data[0].kind = XComLWTVBool;
	OverrodeHitChanceTuple.Data[0].b = false;
	`XEVENTMGR.TriggerEvent('OnFinalizeHitChance', OverrodeHitChanceTuple, self);

	if(OverrodeHitChanceTuple.Data[0].b)
	{
		return;
	}
	// End Issue #14

	`log("==" $ GetFuncName() $ "==\n", m_bDebugModifiers, 'XCom_HitRolls');
	`log("Starting values...", m_bDebugModifiers, 'XCom_HitRolls');
	for (i = 0; i < eHit_MAX; ++i)
	{
		HitResult = EAbilityHitResult(i);
		`log(HitResult $ ":" @ m_ShotBreakdown.ResultTable[i], m_bDebugModifiers, 'XCom_HitRolls');
	}

	m_ShotBreakdown.FinalHitChance = m_ShotBreakdown.ResultTable[eHit_Success];
	//  if crit goes negative, hit would get a boost, so restrict it to 0
	if (m_ShotBreakdown.ResultTable[eHit_Crit] < 0)
		m_ShotBreakdown.ResultTable[eHit_Crit] = 0;
	//  cap success at 100 so it can be fully overridden by crit
	m_ShotBreakdown.ResultTable[eHit_Success] = min(m_ShotBreakdown.ResultTable[eHit_Success], 100);
	//  Crit is folded into the chance to hit, so lower accordingly
	m_ShotBreakdown.ResultTable[eHit_Success] -= m_ShotBreakdown.ResultTable[eHit_Crit];
	//  Graze is scaled against Success - but ignored if success is 100%
	if (m_ShotBreakdown.ResultTable[eHit_Graze] > 0) 
	{
		if (m_ShotBreakdown.FinalHitChance < 100)
		{
			GrazeScale = float(m_ShotBreakdown.ResultTable[eHit_Graze]) / 100.0f;
			GrazeScale *= float(m_ShotBreakdown.FinalHitChance);
			FinalGraze = Round(GrazeScale);
			m_ShotBreakdown.ResultTable[eHit_Success] -= FinalGraze;
			m_ShotBreakdown.ResultTable[eHit_Graze] = FinalGraze;
		}
		else
		{
			m_ShotBreakdown.ResultTable[eHit_Graze] = 0;
		}
	}

	if (m_ShotBreakdown.FinalHitChance >= 100)
	{
		m_ShotBreakdown.ResultTable[eHit_Miss] = 0;
	}
	else
	{
		m_ShotBreakdown.ResultTable[eHit_Miss] = 100 - m_ShotBreakdown.FinalHitChance;
	}
	
	`log("Calculated values...", m_bDebugModifiers, 'XCom_HitRolls');
	for (i = 0; i < eHit_MAX; ++i)
	{
		HitResult = EAbilityHitResult(i);
		`log(HitResult $ ":" @ m_ShotBreakdown.ResultTable[i], m_bDebugModifiers, 'XCom_HitRolls');
	}
	`log("Final hit chance (success + crit + graze) =" @ m_ShotBreakdown.FinalHitChance, m_bDebugModifiers, 'XCom_HitRolls');

	//"Negative chance to hit" is used as a token in UI code - don't ever report that.
	if (m_ShotBreakdown.FinalHitChance < 0)
	{
		`log("FinalHitChance was less than 0 (" $ m_ShotBreakdown.FinalHitChance $ ") and was clamped to avoid confusing the UI (@btopp).", m_bDebugModifiers, 'XCom_HitRolls');
		m_ShotBreakdown.FinalHitChance = 0;
	}
}
