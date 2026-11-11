#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
Procedure FillInAccordingToTheFillingRule() Export 
	
	Parameters = New Structure("Ref, Scenario, CrossTable, ChangeResultTo, FilledAutomatically, RoundingPrecision, 
		|Warehouse, MaximumRowCodeGoods, Status, Periodicity, BeginOfPeriod, PeriodEnding");
	
	FillPropertyValues(Parameters, ThisObject);
	
	Parameters.Insert("FillInRule", True);
	Parameters.Insert("FillingRule", FillingRule.Unload());
	Parameters.Insert("UserSettings", UserSettings.Get());
	
	PopulatedTS = Goods.Unload();
	If UpdateAdd = 0 Then
		PopulatedTS.Clear();
	EndIf;
	
	Parameters.Insert("PopulatedTS", PopulatedTS);
	
	StorageAddress = PutToTempStorage(Undefined);
	Documents.AssemblyDisassemblyPlan.FillInAccordingToTheFillingRule(Parameters, StorageAddress);
	
	PopulatedTS = GetFromTempStorage(StorageAddress);
	
	Goods.Load(PopulatedTS);
	
	MaximumRowCodeGoods = Parameters.MaximumRowCodeGoods;
	
	FilledAutomatically = True;
	
EndProcedure

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	// Skip the processing to ensure that the shape of the object is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillingData.Property("Scenario", ThisObject.Scenario);
		FillingData.Property("PlanProfile", ThisObject.PlanProfile);
		FillingData.Property("BeginOfPeriod", ThisObject.BeginOfPeriod);
		FillingData.Property("PeriodEnding", ThisObject.PeriodEnding);
		FillingData.Property("Status", ThisObject.Status);
	Else
		FillInDefaultData();
	EndIf;
	
	FillInDetailsOfPlanForScenarioTypeOfPlan();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode <> DocumentWriteMode.Write 
		And Not AdditionalProperties.Property("SkipPeriodClosingCheck") Then
		
		DataToCheck = PeriodClosingDates.DataToCheckTemplate();
		NewRow = DataToCheck.Add();
		NewRow.Date   = BeginOfPeriod;
		NewRow.Section = "Planning";
		NewRow.Object = Scenario;
		
		If ValueIsFilled(BudgetingScenario) Then
			NewRow = DataToCheck.Add();
			NewRow.Date   = BeginOfPeriod;
			NewRow.Section = "Budgeting";
			NewRow.Object = BudgetingScenario;
		EndIf;
		
		DataDetails = New Structure;
		DataDetails.Insert("NewVersion", True);
		DataDetails.Insert("Data",      Ref);
		
		ErrorDescription = "";
		If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, DataDetails, ErrorDescription) Then
			Common.MessageToUser(
				ErrorDescription,
				ThisObject,
				, // Field
				, // DataPath
				Cancel);
		EndIf;
			
	EndIf;
	Planning.CheckIfBudgetIssueExists(Cancel, Ref, ThisObject);
	// Fill in the receipt dates
	If Not CrossTable Then
		For Each String In Goods Do
			If Not ValueIsFilled(String.DateOfAssemblyDisassembly) Then
				String.DateOfAssemblyDisassembly = BeginOfPeriod;
			EndIf;
		EndDo;
	EndIf;
	
	If Substitutional Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PlanSubstitution");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("PlanProfile", PlanProfile);
		Block.Lock();
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	Planning.CheckApprovedStatus(ThisObject, Cancel, WriteMode, Enums.TypesOfPlans.AssemblyDisassemblyPlan);
	
	For Each TSRow In Goods Do
		If ValueIsFilled(Warehouse) Then
			TSRow.Warehouse = Warehouse;
		EndIf; 
	EndDo;
	
	If Substitutional 
		And Not IsNew()
		And Not Cancel Then
		SetPrivilegedMode(True);
		UpdatePlanReplacement(WriteMode);
		SetPrivilegedMode(False);
	EndIf;
	
	If Not Substitutional
		And Not IsNew()
		And Not Cancel
		And Planning.ThereIsSubstitutionPlan(Ref) Then
		RecordSet = InformationRegisters.PlanSubstitution.CreateRecordSet();
		RecordSet.Filter.SubstitutedPlan.Set(Ref);
		
		RecordSet.Write();
	EndIf;
	
	If AutoFill
		And (Status = Enums.PlanStatuses.RolledBack_
		Or Status = Enums.PlanStatuses.UnderPreparation) Then
		AutoFill = False;
	EndIf;
	
EndProcedure

Procedure UpdatePlanReplacement(WriteMode, IBUpdate = False) Export
	
	If WriteMode = DocumentWriteMode.UndoPosting
		Or (WriteMode = DocumentWriteMode.Write And Not Posted) Then
		
		For Each String In Goods Do
			String.Substituted = False;
			String.SubstitutedToOrder = False;
		EndDo;
		
		RecordSet = InformationRegisters.PlanSubstitution.CreateRecordSet();
		RecordSet.Filter.SubstitutedPlan.Set(Ref);
		
		RecordSet.Write();
		Return;
	EndIf;
		
	TimeIntervals = New ValueTable();
	TimeIntervals.Columns.Add("Period", New TypeDescription("Date"));
	
	AddingStartDate = BeginOfPeriod;
	While AddingStartDate < EndOfDay(PeriodEnding) Do
		NewRow = TimeIntervals.Add();
		NewRow.Period = AddingStartDate;
		
		EndDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Periodicity);
		AddingStartDate = EndDateOfPeriod+1;
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TimeIntervals.Period AS Period
	|INTO TimeIntervals
	|FROM
	|	&TimeIntervals AS TimeIntervals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssemblyDisassemblyReplacementPlan.Ref AS Ref,
	|	AssemblyDisassemblyReplacementPlan.PlanProfile AS PlanProfile,
	|	CASE
	|		WHEN &BeginOfPeriod > AssemblyDisassemblyReplacementPlan.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE AssemblyDisassemblyReplacementPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < AssemblyDisassemblyReplacementPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE AssemblyDisassemblyReplacementPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	AssemblyDisassemblyReplacementPlan.Status = VALUE(Enum.PlanStatuses.Upholded)
	|		AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS SubstitutedToOrder,
	|	AssemblyDisassemblyReplacementPlan.Status.Order >= &StatusIndex
	|		OR AssemblyDisassemblyReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|			AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS Substituted,
	|	AssemblyDisassemblyReplacementPlan.Status AS SubstitutionStatus
	|INTO ReplacementPlans
	|FROM
	|	Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyReplacementPlan
	|WHERE
	|	AssemblyDisassemblyReplacementPlan.PeriodEnding >= &BeginOfPeriod
	|	AND AssemblyDisassemblyReplacementPlan.BeginOfPeriod <= &PeriodEnding
	|	AND AssemblyDisassemblyReplacementPlan.Ref <> &Ref
	|	AND AssemblyDisassemblyReplacementPlan.Posted
	|	AND AssemblyDisassemblyReplacementPlan.PlanProfile = &PlanProfile
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (AssemblyDisassemblyReplacementPlan.Status.Order >= &StatusIndex
	|			OR AssemblyDisassemblyReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND AssemblyDisassemblyReplacementPlan.Date > &Date
	|	AND AssemblyDisassemblyReplacementPlan.Purpose = &Purpose
	|	AND AssemblyDisassemblyReplacementPlan.BusinessOperation = &BusinessOperation
	|	AND AssemblyDisassemblyReplacementPlan.Warehouse = &Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile AS PlanProfile,
	|	TimeIntervals.Period AS SubstitutedPeriod,
	|	FALSE AS ForSubstitution,
	|	FALSE AS ForSubstitutionCancellation,
	|	ReplacementPlans.Ref AS SubstitutePlan,
	|	&Ref AS SubstitutedPlan,
	|	ReplacementPlans.SubstitutedToOrder AS SubstitutedToOrder,
	|	ReplacementPlans.Substituted AS Substituted,
	|	ReplacementPlans.SubstitutionStatus AS SubstitutionStatus
	|INTO PlanSubstitution
	|FROM
	|	ReplacementPlans AS ReplacementPlans
	|		LEFT JOIN TimeIntervals AS TimeIntervals
	|		ON ReplacementPlans.BeginOfPeriod <= TimeIntervals.Period
	|			AND ReplacementPlans.PeriodEnding >= TimeIntervals.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly AS DateOfAssemblyDisassembly,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly, YEAR)
	|		ELSE AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly
	|	END AS Period
	|INTO AssemblyDisassemblyPlanProducts
	|FROM
	|	&AssemblyDisassemblyPlanProducts AS AssemblyDisassemblyPlanProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly AS DateOfAssemblyDisassembly,
	|	MAX(PlanSubstitution.SubstitutedToOrder) AS SubstitutedToOrder,
	|	MAX(PlanSubstitution.Substituted) AS Substituted
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|		INNER JOIN AssemblyDisassemblyPlanProducts AS AssemblyDisassemblyPlanProducts
	|		ON PlanSubstitution.SubstitutedPeriod = AssemblyDisassemblyPlanProducts.Period
	|
	|GROUP BY
	|	AssemblyDisassemblyPlanProducts.DateOfAssemblyDisassembly
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.PlanProfile AS PlanProfile,
	|	PlanSubstitution.SubstitutedPeriod AS SubstitutedPeriod,
	|	PlanSubstitution.ForSubstitution AS ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation AS ForSubstitutionCancellation,
	|	PlanSubstitution.SubstitutePlan AS SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan,
	|	PlanSubstitution.SubstitutionStatus AS SubstitutionStatus
	|FROM
	|	PlanSubstitution AS PlanSubstitution";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Status));
	Query.SetParameter("Status", Status);
	Query.SetParameter("Status", Status);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("AssemblyDisassemblyPlanProducts", Goods.Unload());
	
	RequestPackage = Query.ExecuteBatch();
	Selection = RequestPackage[4].Select();
	PlanReplacementTable = RequestPackage[5].Unload();
	
	For Each String In Goods Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	While Selection.Next() Do
		
		Filter = New Structure("DateOfAssemblyDisassembly", Selection.DateOfAssemblyDisassembly);
		ReplacementLines = Goods.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = Selection.Substituted;
			String.SubstitutedToOrder = Selection.SubstitutedToOrder;
		EndDo;
		
	EndDo;
	
	RecordSet = InformationRegisters.PlanSubstitution.CreateRecordSet();
	RecordSet.Filter.SubstitutedPlan.Set(Ref);
		
	RecordSet.Load(PlanReplacementTable);
	
	If IBUpdate Then
		RecordSet.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", Undefined);
		RecordSet.DataExchange.Load = True;
		RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		RecordSet.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If Not Cancel And (Substitutional 
		Or Planning.ThereIsSubstitutionPlan(Ref)) Then
		SetPrivilegedMode(True);
		UpdateSubstitutedPlans();
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Procedure UpdateSubstitutedPlans()
	
	TimeIntervals = New ValueTable();
	TimeIntervals.Columns.Add("Period", New TypeDescription("Date"));
	
	AddingStartDate = BeginOfPeriod;
	While AddingStartDate < EndOfDay(PeriodEnding) Do
		NewRow = TimeIntervals.Add();
		NewRow.Period = AddingStartDate;
		
		EndDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Periodicity);
		AddingStartDate = EndDateOfPeriod+1;
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TimeIntervals.Period AS Period
	|INTO TimeIntervals
	|FROM
	|	&TimeIntervals AS TimeIntervals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssemblyDisassemblySubstitutedPlan.Ref AS Ref,
	|	AssemblyDisassemblySubstitutedPlan.PlanProfile AS PlanProfile,
	|	CASE
	|		WHEN AssemblyDisassemblyPlan.BeginOfPeriod > AssemblyDisassemblySubstitutedPlan.BeginOfPeriod
	|			THEN AssemblyDisassemblyPlan.BeginOfPeriod
	|		ELSE AssemblyDisassemblySubstitutedPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN AssemblyDisassemblyPlan.PeriodEnding < AssemblyDisassemblySubstitutedPlan.PeriodEnding
	|			THEN AssemblyDisassemblyPlan.PeriodEnding
	|		ELSE AssemblyDisassemblySubstitutedPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	AssemblyDisassemblyPlan.Status AS SubstitutionStatus
	|INTO SubstitutedPlans
	|FROM
	|	Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
	|		INNER JOIN Document.AssemblyDisassemblyPlan AS AssemblyDisassemblySubstitutedPlan
	|		ON AssemblyDisassemblyPlan.PlanProfile = AssemblyDisassemblySubstitutedPlan.PlanProfile
	|			AND (AssemblyDisassemblyPlan.Status.Order >= AssemblyDisassemblySubstitutedPlan.Status.Order
	|				OR AssemblyDisassemblyPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|					AND AssemblyDisassemblySubstitutedPlan.Status = VALUE(Enum.PlanStatuses.Upholded))
	|			AND AssemblyDisassemblySubstitutedPlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|			AND AssemblyDisassemblyPlan.Date > AssemblyDisassemblySubstitutedPlan.Date
	|			AND AssemblyDisassemblyPlan.Purpose = AssemblyDisassemblySubstitutedPlan.Purpose
	|			AND AssemblyDisassemblyPlan.BusinessOperation = AssemblyDisassemblySubstitutedPlan.BusinessOperation
	|			AND AssemblyDisassemblyPlan.Warehouse = AssemblyDisassemblySubstitutedPlan.Warehouse
	|			AND (AssemblyDisassemblySubstitutedPlan.Posted)
	|			AND (AssemblyDisassemblySubstitutedPlan.Substitutional)
	|WHERE
	|	AssemblyDisassemblySubstitutedPlan.PeriodEnding >= AssemblyDisassemblyPlan.BeginOfPeriod
	|	AND AssemblyDisassemblySubstitutedPlan.BeginOfPeriod <= AssemblyDisassemblyPlan.PeriodEnding
	|	AND AssemblyDisassemblyPlan.Ref = &Ref
	|	AND AssemblyDisassemblyPlan.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile AS PlanProfile,
	|	TimeIntervals.Period AS SubstitutedPeriod,
	|	ReplacementPlans.Ref AS SubstitutedPlan,
	|	&Ref AS SubstitutePlan,
	|	ReplacementPlans.SubstitutionStatus AS SubstitutionStatus
	|INTO SubstitutedPlansByPeriod
	|FROM
	|	SubstitutedPlans AS ReplacementPlans
	|		LEFT JOIN TimeIntervals AS TimeIntervals
	|		ON ReplacementPlans.BeginOfPeriod <= TimeIntervals.Period
	|			AND ReplacementPlans.PeriodEnding >= TimeIntervals.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.SubstitutePlan AS SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan,
	|	PlanSubstitution.SubstitutedPeriod AS SubstitutedPeriod,
	|	PlanSubstitution.PlanProfile AS PlanProfile,
	|	CASE
	|		WHEN SubstitutedPlansByPeriod.SubstitutionStatus IS NULL
	|			THEN PlanSubstitution.SubstitutionStatus
	|		ELSE SubstitutedPlansByPeriod.SubstitutionStatus
	|	END AS SubstitutionStatus,
	|	PlanSubstitution.ForSubstitution AS ForSubstitution,
	|	CASE
	|		WHEN SubstitutedPlansByPeriod.SubstitutedPeriod IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ForSubstitutionCancellation
	|INTO SubstitutionOfPlansSumOfRegisteredRecords
	|FROM
	|	InformationRegister.PlanSubstitution AS PlanSubstitution
	|		LEFT JOIN SubstitutedPlansByPeriod AS SubstitutedPlansByPeriod
	|		ON PlanSubstitution.PlanProfile = SubstitutedPlansByPeriod.PlanProfile
	|			AND PlanSubstitution.SubstitutedPeriod = SubstitutedPlansByPeriod.SubstitutedPeriod
	|			AND PlanSubstitution.SubstitutePlan = SubstitutedPlansByPeriod.SubstitutePlan
	|			AND PlanSubstitution.SubstitutedPlan = SubstitutedPlansByPeriod.SubstitutedPlan
	|			AND PlanSubstitution.SubstitutionStatus = SubstitutedPlansByPeriod.SubstitutionStatus
	|WHERE
	|	PlanSubstitution.SubstitutePlan = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	SubstitutedPlansByPeriod.SubstitutePlan,
	|	SubstitutedPlansByPeriod.SubstitutedPlan,
	|	SubstitutedPlansByPeriod.SubstitutedPeriod,
	|	SubstitutedPlansByPeriod.PlanProfile,
	|	SubstitutedPlansByPeriod.SubstitutionStatus,
	|	TRUE,
	|	FALSE
	|FROM
	|	SubstitutedPlansByPeriod AS SubstitutedPlansByPeriod
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
	|		ON SubstitutedPlansByPeriod.PlanProfile = PlanSubstitution.PlanProfile
	|			AND SubstitutedPlansByPeriod.SubstitutedPeriod = PlanSubstitution.SubstitutedPeriod
	|			AND SubstitutedPlansByPeriod.SubstitutedPlan = PlanSubstitution.SubstitutedPlan
	|			AND SubstitutedPlansByPeriod.SubstitutePlan = PlanSubstitution.SubstitutePlan
	|			AND SubstitutedPlansByPeriod.SubstitutionStatus = PlanSubstitution.SubstitutionStatus
	|WHERE
	|	PlanSubstitution.SubstitutedPeriod IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutePlan AS SubstitutePlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan AS SubstitutedPlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod AS SubstitutedPeriod,
	|	SubstitutionOfPlansSumOfRegisteredRecords.PlanProfile AS PlanProfile,
	|	MIN(ISNULL(PlanSubstitution1.ForSubstitution, SubstitutionOfPlansSumOfRegisteredRecords.ForSubstitution)) AS ForSubstitution,
	|	MIN(SubstitutionOfPlansSumOfRegisteredRecords.ForSubstitutionCancellation) AS ForSubstitutionCancellation,
	|	MIN(ISNULL(PlanSubstitution.ForSubstitutionCancellation, TRUE)) AS PerformUndoSubstitution,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus
	|INTO PlanSubstitution
	|FROM
	|	SubstitutionOfPlansSumOfRegisteredRecords AS SubstitutionOfPlansSumOfRegisteredRecords
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
	|		ON SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan = PlanSubstitution.SubstitutedPlan
	|			AND SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod = PlanSubstitution.SubstitutedPeriod
	|			AND (NOT PlanSubstitution.ForSubstitutionCancellation)
	|			AND (&Ref <> PlanSubstitution.SubstitutePlan)
	|			AND (SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus = PlanSubstitution.SubstitutionStatus)
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution1
	|		ON SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan = PlanSubstitution1.SubstitutedPlan
	|			AND SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod = PlanSubstitution1.SubstitutedPeriod
	|			AND (NOT PlanSubstitution1.ForSubstitution)
	|			AND (SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus = PlanSubstitution1.SubstitutionStatus)
	|			AND (&Ref <> PlanSubstitution1.SubstitutePlan)
	|
	|GROUP BY
	|	SubstitutionOfPlansSumOfRegisteredRecords.PlanProfile,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutePlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutionStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.SubstitutePlan AS SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan,
	|	PlanSubstitution.SubstitutedPeriod AS SubstitutedPeriod,
	|	PlanSubstitution.PlanProfile AS PlanProfile,
	|	PlanSubstitution.ForSubstitution AS ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation AS ForSubstitutionCancellation,
	|	PlanSubstitution.PerformUndoSubstitution AS PerformUndoSubstitution,
	|	PlanSubstitution.SubstitutionStatus
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|TOTALS BY
	|	SubstitutedPlan";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	
	RequestPackage = Query.ExecuteBatch(); 
	SampleSubstitutedPlan = RequestPackage[5].Select(QueryResultIteration.ByGroups);
	UpdatePlanReplacement = False;
	
	While SampleSubstitutedPlan.Next() Do
		
		QueueRecordset = InformationRegisters.PlanSubstitution.CreateRecordSet();
		QueueRecordset.Filter.SubstitutePlan.Set(Ref);
		QueueRecordset.Filter.SubstitutedPlan.Set(SampleSubstitutedPlan.SubstitutedPlan); 
		
		Selection = SampleSubstitutedPlan.Select(QueryResultIteration.ByGroups);
		While Selection.Next() Do
			
			If (Selection.ForSubstitution And Selection.ForSubstitutionCancellation)Then
				UpdatePlanReplacement = True;
			ElsIf Selection.ForSubstitutionCancellation And Not Selection.PerformUndoSubstitution Then
				Continue;
			ElsIf Selection.ForSubstitution Or Selection.ForSubstitutionCancellation Then
				UpdatePlanReplacement = True;
				QueueRecording = QueueRecordset.Add();
				FillPropertyValues(QueueRecording, Selection);
			ElsIf Posted Then
				QueueRecording = QueueRecordset.Add();
				FillPropertyValues(QueueRecording, Selection);
			EndIf;
			
		EndDo;
		
		QueueRecordset.Write();
		
	EndDo;
	
	If UpdatePlanReplacement Then
		Planning.StartingBackgroundExecutionOfPlan();
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Status = Metadata().Attributes.Status.FillValue;
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	FillInDetailsOfPlanForScenarioTypeOfPlan();
	For Each LineProducts_ In Goods Do

		LineProducts_.Canceled = False;

	EndDo;

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	If Not Cancel
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Not Cancel
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If CrossTable Then
		NotCheckedAttributeArray.Add("Goods");
		NotCheckedAttributeArray.Add("Goods.Products");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Goods.Count");
		NotCheckedAttributeArray.Add("Goods.ProductKit");
	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.CheckPossibilityOfRounding = False;
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	EndIf;
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",                    "Goods");
	CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Bộ đóng gói';
															|ru = 'Комплекты';
															|en = 'Kits'; fa = 'کیت‌ها';
															|it = 'Kit';
															|pl = 'Kits';
															|tr = 'Ürün setleri'"));
	CheckParameters.Insert("Periodicity",            Periodicity);
	CheckParameters.Insert("StartDate",               BeginOfPeriod);
	CheckParameters.Insert("EndDate",            PeriodEnding);
	CheckParameters.Insert("NameOfPeriodDateField",       "DateOfAssemblyDisassembly");
	CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày đóng bộ (tách bộ)';
															|ru = 'Дата сборки (разборки)';
															|en = 'Date of kitting'; fa = 'تاریخ کیت‌سازی';
															|it = 'Data di assemblaggio (disassemblaggio)';
															|pl = 'Data montażu (demontażu)';
															|tr = 'Montaj (demontaj) tarihi'"));
	
	If Not CrossTable Then
		PlanningClientServer.CheckDateOfTSPeriod(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	If CrossTable Then
		NotCheckedAttributeArray.Add("Goods.Characteristic");
	Else
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	EndIf; 	
	
	Planning.ProcessingFillVerificationByScenarioPlanType(ThisObject, Cancel, CheckedAttributes);
	
	If Not CrossTable
		And ValueIsFilled(PlanProfile)
		And Not FillInByShortage Then
		
		DetailsTypeOfPlan = Common.ObjectAttributesValues(PlanProfile,"FillInAssignmentInTabularForm, FillInTermsOfSales, FillInWarehouse, FillInPartner");
		
		Query = New Query();
		Query.Text = 
		"SELECT
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Warehouse,
		|	GoodsTable.Purpose,
		|	GoodsTable.DateOfAssemblyDisassembly,
		|	GoodsTable.Count
		|INTO Goods
		|FROM
		|	&GoodsTable AS GoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Warehouse,
		|	Goods.Purpose,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Products <> VALUE(Catalog.Products.EmptyRef)
		|	AND (NOT &FillInWarehouse OR Goods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef))
		|
		|GROUP BY
		|	Goods.Products,
		|	Goods.Warehouse,
		|	Goods.Purpose,
		|	Goods.DateOfAssemblyDisassembly,
		|	Goods.Characteristic
		|
		|HAVING
		|	SUM(Goods.Count) = 0";
		Query.SetParameter("GoodsTable", Goods.Unload());
		Query.SetParameter("FillInWarehouse", DetailsTypeOfPlan.FillInWarehouse);
		DetailsTypeOfPlan = Common.ObjectAttributesValues(PlanProfile,"FillInAssignmentInTabularForm, FillInWarehouse, FillInWarehouseInTabularForm");
		
		ErrorsTable = Query.Execute().Unload();
		
		DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
		TheStructureOfTheSearch = New Structure("Products,Characteristic,Purpose,Warehouse");
		
		For Each ErrorString In ErrorsTable Do
			
			MessageText = NStr("vi = 'Đối với các dòng kế hoạch với mặt hàng %Products%%Characteristic%%Purpose%%Warehouse% chưa dự tính số lượng trong bất kỳ giai đoạn lập kế hoạch nào.';
								|ru = 'Для строк плана с номенклатурой %Products%%Characteristic%%Purpose%%Warehouse% не запланировано количество ни в одном периоде планирования.';
								|en = 'Quantity is not planned in any planning period for lines of plan with the %Products%%Characteristic%%Purpose%%Warehouse% items.'; fa = 'Quantity is not planned in any planning period for lines of plan with the %Products%%Characteristic%%Purpose%%Warehouse% items.';
								|it = 'Per le righe del piano con elenco merci %Products%%Characteristic%%Purpose%%Warehouse% la quantità non è programmata in alcun periodo di pianificazione.';
								|pl = 'W przypadku wiersza planu z pozycją %Products%%Characteristic%%Purpose%%Warehouse% ilość nie jest planowana w żadnym okresie planowania.';
								|tr = 'Ürünler ile satır planı için %Products%%Characteristic%%Purpose%%Warehouse% hiçbir planlama döneminde miktar programlanmadı.'");
			MessageText = StrReplace(MessageText, "%Products%", ErrorString.Products);
			MessageText = StrReplace(MessageText, "%Characteristic%", ?(ValueIsFilled(ErrorString.Characteristic), NStr("vi = ', đặc tính';
																														|ru = ', характеристикой';
																														|en = ', variants'; fa = ', variants';
																														|it = ', caratteristica';
																														|pl = ', charakterystyką';
																														|tr = ', özellik'") + " " + ErrorString.Characteristic, ""));
			MessageText = StrReplace(MessageText, "%Purpose%", ?(ValueIsFilled(ErrorString.Purpose)
				And DetailsTypeOfPlan.FillInAssignmentInTabularForm,
				NStr("vi = ', chỉ định';
					|ru = ', назначением';
					|en = ', assignment'; fa = ', assignment';
					|it = ', destinazione';
					|pl = ', przeznaczeniem';
					|tr = ', amaç'") + " " + ErrorString.Purpose, ""));
			MessageText = StrReplace(MessageText, "%Warehouse%", ?(ValueIsFilled(ErrorString.Warehouse)
				And DetailsTypeOfPlan.FillInWarehouseInTabularForm , NStr("vi = ', kho';
																			|ru = ', складом';
																			|en = ', warehouse'; fa = ', warehouse';
																			|it = ', magazzino';
																			|pl = ', magazynem';
																			|tr = ', ambar'") + " " + ErrorString.Warehouse, ""));
			
			FillPropertyValues(TheStructureOfTheSearch, ErrorString);
			SearchString = Goods.FindRows(TheStructureOfTheSearch)[0];
			
			Field = CommonClientServer.PathToTabularSection("Goods", SearchString.LineNumber, "NumberOfPackages");
			
			CommonClientServer.MessageToUser(MessageText,DataKey, Field,"Object",Cancel);
			
		EndDo;
		
	EndIf;
	
	If Not CrossTable
		And ValueIsFilled(PlanProfile) Then
		
		GroupFields = "Products,Characteristic,Purpose,Package,Warehouse,ProductKit,RowCodeGoods,DateOfAssemblyDisassembly";
		Planning.HandlingStringDuplicationChecking(Goods, "Goods", GroupFields, Cancel);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

// The procedure fills in the details in the document with the default value.
//
Procedure FillInDefaultData()
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	CASE
	|		WHEN Warehouses.DeletionMark
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE DocumentData.Warehouse
	|	END AS Warehouse,
	|	CASE
	|		WHEN SalesOperationsPlanningScenarios.DeletionMark
	|			THEN VALUE(Catalog.SalesOperationsPlanningScenarios.EmptyRef)
	|		ELSE DocumentData.Scenario
	|	END AS Scenario,
	|	CASE
	|		WHEN PlanProfiles.DeletionMark
	|			THEN VALUE(Catalog.PlanProfiles.EmptyRef)
	|		ELSE DocumentData.PlanProfile
	|	END AS PlanProfile,
	|	DocumentData.FillInUsingFormula AS FillInUsingFormula,
	|	DocumentData.CrossTable AS CrossTable
	|FROM
	|	Document.AssemblyDisassemblyPlan AS DocumentData
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON DocumentData.PlanProfile = PlanProfiles.Ref
	|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|		ON DocumentData.Scenario = SalesOperationsPlanningScenarios.Ref
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON DocumentData.Warehouse = Warehouses.Ref
	|WHERE
	|	DocumentData.EmployeeResponsible = &EmployeeResponsible
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	DocumentData.Date DESC");
	
	Query.SetParameter("EmployeeResponsible", EmployeeResponsible);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		FillPropertyValues(ThisObject, Selection);
		
	EndIf;
	
	Scenario = SettingsValueCached.GetDefaultScript(Enums.TypesOfPlans.AssemblyDisassemblyPlan, Scenario);
	
EndProcedure

Procedure FillInDetailsOfPlanForScenarioTypeOfPlan()
	
	ScriptDetails = "Periodicity";
	ScriptDetails = ScriptDetails + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, ScriptDetails);
	If Not ValueIsFilled(PlanProfile) Then
		PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.AssemblyDisassemblyPlan, Scenario);
	EndIf;
	FillPropertyValues(ThisObject, ScriptParameters_);
	
	If ValueIsFilled(PlanProfile) Then
		Attributes = "FillInPaymentPlan,FillInUsingFormula,Substitutional";
		
		PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
		StructureOfSettingsPlanView = Planning.GetDefaultSettings(Enums.TypesOfPlans.AssemblyDisassemblyPlan, PlanProfile);
		If StructureOfSettingsPlanView.Property("Formula") Then
			PlanViewParameters.Insert("SettingsStructure", StructureOfSettingsPlanView);
		EndIf;
		For Each Item In StructureOfSettingsPlanView Do
			PlanViewParameters.Insert(Item.Key, Item.Value);
		EndDo;
		
		FillPropertyValues(ThisObject, PlanViewParameters);
		ThisObject.SettingsStructure  = New ValueStorage(StructureOfSettingsPlanView);
	EndIf;
	
EndProcedure

Procedure DetermineConfigurationOption(ListOfProductLines = Undefined, GoodsByDates = Undefined) Export

	If CrossTable Then
		GoodsTable = GoodsByDates.Unload(ListOfProductLines, "Products,Characteristic, ProductKit");
	Else
		GoodsTable = Goods.Unload(ListOfProductLines, "Products,Characteristic, ProductKit");
	EndIf;
	
	If ListOfProductLines <> Undefined Then
		ListOfRowsReadyForProcessing = ListOfProductLines;
	Else
		If CrossTable Then
			ListOfRowsReadyForProcessing = GoodsByDates;
		Else
			ListOfRowsReadyForProcessing = Goods;
		EndIf;
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	CAST(GoodsTable.ProductKit AS Catalog.ProductKitConfigurations) AS ProductKit
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	GoodsTable.Products                           AS Products,
	|	GoodsTable.Characteristic                         AS Characteristic,
	|	ProductKitConfigurations.Ref              AS ProductKit,
	|	ProductKitConfigurations.Main            AS Main
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON GoodsTable.Products = ProductKitConfigurations.Owner
	|			AND GoodsTable.Characteristic = ProductKitConfigurations.Characteristic
	|			AND (GoodsTable.ProductKit = ProductKitConfigurations.Ref
	|				OR GoodsTable.ProductKit = VALUE(Catalog.ProductKitConfigurations.EmptyRef)
	|				OR GoodsTable.ProductKit.Owner <> GoodsTable.Products)
	|			AND (NOT ProductKitConfigurations.DeletionMark)";
	
	Query.SetParameter("GoodsTable", GoodsTable);
	
	TableConfigurationOptions = Query.Execute().Unload();
	TableConfigurationOptions.Indexes.Add("Products,Characteristic");
	
	DetailsToFillIn = "ProductKit,PackagingEquipment,QuantityEquipment,NumberOfPackagesCompleteSet";
	
	For Each RowGoods In ListOfRowsReadyForProcessing Do
		TheStructureOfTheSearch = New Structure("Products,Characteristic", RowGoods.Products, RowGoods.Characteristic);
  		ListOfConfigurationOptions = TableConfigurationOptions.FindRows(TheStructureOfTheSearch);
		KitConfigurations = New Array;
		For Each StringConfigurationOption In ListOfConfigurationOptions Do
			If StringConfigurationOption.Main Then
				KitConfigurations.Clear();
				KitConfigurations.Add(StringConfigurationOption);
				Break;
			Else
				KitConfigurations.Add(StringConfigurationOption);
			EndIf;
		EndDo;
		
		If KitConfigurations.Count() = 1 Then
			// The configuration option should be the main or the only one
			RowGoods.ProductKit = KitConfigurations[0].ProductKit;
		Else
			RowGoods.ProductKit = Catalogs.ProductKitConfigurations.EmptyRef();
		EndIf; 
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
