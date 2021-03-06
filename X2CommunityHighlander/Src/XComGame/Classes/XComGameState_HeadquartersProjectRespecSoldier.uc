//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersProjectRespecSoldier.uc
//  AUTHOR:  Joe Weinhoffer  --  06/05/2015
//  PURPOSE: This object represents the instance data for an XCom HQ respec soldier project
//           Will eventually be a component
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersProjectRespecSoldier extends XComGameState_HeadquartersProject native(Core);

//---------------------------------------------------------------------------------------
// Call when you start a new project, NewGameState should be none if not coming from tactical
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local XComGameState_Unit UnitState;

	// Variables for Issue #79
	local XComLWTuple OverrideTuple; // LWS  added

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility
	
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	//UnitState.PsiTrainingRankReset();
	UnitState.SetStatus(eStatus_Training);
	
	// Start Issue #79
	// Allow mods to listen to SolderRespecced and alter the project duration.
	ProjectPointsRemaining = CalculatePointsToRespec();

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideRespecTimes';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVInt;
	OverrideTuple.Data[0].i = UnitState.GetRank();
	OverrideTuple.Data[1].kind = XComLWTVInt;
	OverrideTuple.Data[1].i = ProjectPointsRemaining;

	//LW add hook for mods to change outcome of CPTR function
	`XEVENTMGR.TriggerEvent('SoldierRespecced', OverrideTuple, self, NewGameState);

	ProjectPointsRemaining = OverrideTuple.Data[1].i;
	// End Issue #79
	InitialProjectPoints = ProjectPointsRemaining;

	UpdateWorkPerHour(NewGameState);
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if (MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculatePointsToRespec()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	return XComHQ.GetRespecSoldierDays() * 24;
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	return 1;
}

//---------------------------------------------------------------------------------------
// Remove the project
function OnProjectCompleted()
{
	local HeadquartersOrderInputContext OrderInput;
	
	OrderInput.OrderType = eHeadquartersOrderType_RespecSoldierCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	`HQPRES.UITrainingComplete(ProjectFocus);
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
