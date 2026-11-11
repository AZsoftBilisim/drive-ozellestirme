#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
Procedure FillInAccordingToTheFillingRule() Export 
	
	Parameters = New Structure("Ref, Scenario, CrossTable, ChangeResultTo, FilledAutomatically, RoundingPrecision, 
		|Warehouse, Status, Periodicity, BeginOfPeriod, PeriodEnding");
	
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
	Documents.PlanOfGoodsStock.FillInAccordingToTheFillingRule(Parameters, StorageAddress);
	
	PopulatedTS = GetFromTempStorage(StorageAddress);
	
	Goods.Load(PopulatedTS);
	
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
	// Fill in the balance dates
	If Not CrossTable Then
		For Each String In Goods Do
			If Not ValueIsFilled(String.BalanceDate) Then
				String.BalanceDate = BeginOfPeriod;
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
	
	Planning.CheckApprovedStatus(ThisObject, Cancel, WriteMode, Enums.TypesOfPlans.PlanOfGoodsStock);
	
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
	|	TimeIntervals.Period
	|INTO TimeIntervals
	|FROM
	|	&TimeIntervals AS TimeIntervals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResidueReplacementPlan.Ref,
	|	ResidueReplacementPlan.PlanProfile,
	|	CASE
	|		WHEN &BeginOfPeriod > ResidueReplacementPlan.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE ResidueReplacementPlan.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < ResidueReplacementPlan.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE ResidueReplacementPlan.PeriodEnding
	|	END AS PeriodEnding,
	|	ResidueReplacementPlan.Status = VALUE(Enum.PlanStatuses.Upholded)
	|		AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS SubstitutedToOrder,
	|	ResidueReplacementPlan.Status.Order >= &StatusIndex
	|		OR ResidueReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|			AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS Substituted,
	|	ResidueReplacementPlan.Status AS SubstitutionStatus
	|INTO ReplacementPlans
	|FROM
	|	Document.PlanOfGoodsStock AS ResidueReplacementPlan
	|WHERE
	|	ResidueReplacementPlan.PeriodEnding >= &BeginOfPeriod
	|	AND ResidueReplacementPlan.BeginOfPeriod <= &PeriodEnding
	|	AND ResidueReplacementPlan.Ref <> &Ref
	|	AND ResidueReplacementPlan.Posted
	|	AND ResidueReplacementPlan.PlanProfile = &PlanProfile
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (ResidueReplacementPlan.Status.Order >= &StatusIndex
	|			OR ResidueReplacementPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND ResidueReplacementPlan.Date > &Date
	|	AND ResidueReplacementPlan.Purpose = &Purpose
	|	AND ResidueReplacementPlan.Warehouse = &Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
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
	|	ProductBalancePlan.BalanceDate,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(ProductBalancePlan.BalanceDate, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(ProductBalancePlan.BalanceDate, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(ProductBalancePlan.BalanceDate, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(ProductBalancePlan.BalanceDate, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(ProductBalancePlan.BalanceDate, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(ProductBalancePlan.BalanceDate, YEAR)
	|		ELSE ProductBalancePlan.BalanceDate
	|	END AS Period
	|INTO ProductBalancePlan
	|FROM
	|	&ProductBalancePlan AS ProductBalancePlan
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductBalancePlan.BalanceDate,
	|	MAX(PlanSubstitution.SubstitutedToOrder) AS SubstitutedToOrder,
	|	MAX(PlanSubstitution.Substituted) AS Substituted
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|		INNER JOIN ProductBalancePlan AS ProductBalancePlan
	|		ON PlanSubstitution.SubstitutedPeriod = ProductBalancePlan.Period
	|
	|GROUP BY
	|	ProductBalancePlan.BalanceDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.PlanProfile,
	|	PlanSubstitution.SubstitutedPeriod,
	|	PlanSubstitution.ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation,
	|	PlanSubstitution.SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan,
	|	PlanSubstitution.SubstitutionStatus AS SubstitutionStatus
	|FROM
	|	PlanSubstitution AS PlanSubstitution";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Status));
	Query.SetParameter("Status", Status);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("ProductBalancePlan", Goods.Unload());
	
	RequestPackage = Query.ExecuteBatch();
	Selection = RequestPackage[4].Select();
	PlanReplacementTable = RequestPackage[5].Unload();
	
	For Each String In Goods Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	While Selection.Next() Do
		
		Filter = New Structure("BalanceDate", Selection.BalanceDate);
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
	
	If Not Cancel
		And (Substitutional Or Planning.ThereIsSubstitutionPlan(Ref)) Then
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
	|	SubstitutedPeriods.Period
	|INTO SubstitutedPeriods
	|FROM
	|	&TimeIntervals AS SubstitutedPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResiduesPlanSubstituted.Ref,
	|	ResiduesPlanSubstituted.PlanProfile,
	|	CASE
	|		WHEN PlanOfGoodsStock.BeginOfPeriod > ResiduesPlanSubstituted.BeginOfPeriod
	|			THEN PlanOfGoodsStock.BeginOfPeriod
	|		ELSE ResiduesPlanSubstituted.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN PlanOfGoodsStock.PeriodEnding < ResiduesPlanSubstituted.PeriodEnding
	|			THEN PlanOfGoodsStock.PeriodEnding
	|		ELSE ResiduesPlanSubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	PlanOfGoodsStock.Status AS SubstitutionStatus
	|INTO SubstitutedPlans
	|FROM
	|	Document.PlanOfGoodsStock AS PlanOfGoodsStock
	|		INNER JOIN Document.PlanOfGoodsStock AS ResiduesPlanSubstituted
	|		ON PlanOfGoodsStock.PlanProfile = ResiduesPlanSubstituted.PlanProfile
	|			AND (PlanOfGoodsStock.Status.Order >= ResiduesPlanSubstituted.Status.Order
	|				OR PlanOfGoodsStock.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|					AND ResiduesPlanSubstituted.Status = VALUE(Enum.PlanStatuses.Upholded))
	|			AND ResiduesPlanSubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|			AND PlanOfGoodsStock.Date > ResiduesPlanSubstituted.Date
	|			AND PlanOfGoodsStock.Purpose = ResiduesPlanSubstituted.Purpose
	|			AND PlanOfGoodsStock.Warehouse = ResiduesPlanSubstituted.Warehouse
	|			AND ResiduesPlanSubstituted.Posted
	|			AND ResiduesPlanSubstituted.Substitutional
	|WHERE
	|	ResiduesPlanSubstituted.PeriodEnding >= PlanOfGoodsStock.BeginOfPeriod
	|	AND ResiduesPlanSubstituted.BeginOfPeriod <= PlanOfGoodsStock.PeriodEnding
	|	AND PlanOfGoodsStock.Ref = &Ref
	|	AND PlanOfGoodsStock.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
	|	SubstitutedPeriods.Period AS SubstitutedPeriod,
	|	ReplacementPlans.Ref AS SubstitutedPlan,
	|	&Ref AS SubstitutePlan,
	|	ReplacementPlans.SubstitutionStatus AS SubstitutionStatus
	|INTO SubstitutedPlansByPeriod
	|FROM
	|	SubstitutedPlans AS ReplacementPlans
	|		LEFT JOIN SubstitutedPeriods AS SubstitutedPeriods
	|		ON ReplacementPlans.BeginOfPeriod <= SubstitutedPeriods.Period
	|			AND ReplacementPlans.PeriodEnding >= SubstitutedPeriods.Period
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
	|	&Ref = PlanSubstitution.SubstitutePlan
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
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutePlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod,
	|	SubstitutionOfPlansSumOfRegisteredRecords.PlanProfile,
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
	|	PlanSubstitution.SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan AS SubstitutedPlan,
	|	PlanSubstitution.SubstitutedPeriod,
	|	PlanSubstitution.PlanProfile,
	|	PlanSubstitution.ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation,
	|	PlanSubstitution.PerformUndoSubstitution,
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
	
	Query = New Query;
	Query.Text =  
		"SELECT DISTINCT
		|	Goods.BalanceDate AS Period,
		|	&Scenario AS Scenario,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.NumberOfPackages <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DocumentRegisterRecords.Period AS Period,
		|	DocumentRegisterRecords.Scenario AS Scenario,
		|	DocumentRegisterRecords.Products AS Products,
		|	DocumentRegisterRecords.Characteristic AS Characteristic,
		|	CASE
		|		WHEN DocumentRegisterRecords.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS SpecifyingWarehouse
		|INTO DocumentRegisterRecords
		|FROM
		|	Goods AS DocumentRegisterRecords
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentRegisterRecords.Period,
		|	DocumentRegisterRecords.Scenario,
		|	DocumentRegisterRecords.Products,
		|	DocumentRegisterRecords.Characteristic,
		|	CASE
		|		WHEN PlansOfGoodsStock.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN FALSE
		|		ELSE TRUE
		|	END
		|FROM
		|	Goods AS DocumentRegisterRecords
		|		INNER JOIN AccumulationRegister.PlansOfGoodsStock AS PlansOfGoodsStock
		|		ON DocumentRegisterRecords.Period = PlansOfGoodsStock.Period
		|			AND DocumentRegisterRecords.Products = PlansOfGoodsStock.Products
		|			AND DocumentRegisterRecords.Characteristic = PlansOfGoodsStock.Characteristic
		|			AND DocumentRegisterRecords.Scenario = PlansOfGoodsStock.Scenario
		|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
		|			ON PlansOfGoodsStock.PlanOfGoodsStock = PlanSubstitution.SubstitutePlan
		|WHERE
		|	CASE
		|			WHEN PlanSubstitution.SubstitutePlan IS NULL
		|				THEN PlansOfGoodsStock.Recorder <> &Ref
		|			ELSE TRUE
		|		END
		|	AND PlansOfGoodsStock.Count <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentRegisterRecords.Period AS Period,
		|	DocumentRegisterRecords.Scenario AS Scenario,
		|	DocumentRegisterRecords.Products AS Products,
		|	DocumentRegisterRecords.Characteristic AS Characteristic,
		|	COUNT(DISTINCT DocumentRegisterRecords.SpecifyingWarehouse) AS SpecifyingWarehouse
		|FROM
		|	DocumentRegisterRecords AS DocumentRegisterRecords
		|
		|GROUP BY
		|	DocumentRegisterRecords.Period,
		|	DocumentRegisterRecords.Scenario,
		|	DocumentRegisterRecords.Products,
		|	DocumentRegisterRecords.Characteristic
		|
		|HAVING
		|	COUNT(DISTINCT DocumentRegisterRecords.SpecifyingWarehouse) > 1";

	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("Goods", Goods.Unload(, "BalanceDate, Products, Characteristic,
		|Warehouse, NumberOfPackages"));
	Query.SetParameter("Ref", Ref);
	QueryResult = Query.Execute();
	
	MessageTemplate1 = NStr("vi = 'Đối với mặt hàng %ProductsCharacteristic% 
		|không thể sử dụng đồng thời trong một kỳ và một bộ phận các kế hoạch có giá trị trống và các kế hoạch có điền giá trị trường:';
		|ru = 'Для номенклатуры %ProductsCharacteristic% 
		|нельзя одновременно использовать в одном периоде и подразделении планы с пустым и планы с заполненным значением поля:';
		|en = 'Cannot use plans with an empty field value and plans with a populated field value simultaneously for items %ProductsCharacteristic%
		| in one period and business unit:'; fa = 'Cannot use plans with an empty field value and plans with a populated field value simultaneously for items %ProductsCharacteristic%
		| in one period and business unit:';
		|it = 'Per gli articoli %ProductsCharacteristic% 
		| non si può utilizzare contemporaneamente nello stesso periodo e nello stesso reparto i piani con i valori del campo sia vuoto sia compilato:';
		|pl = 'W przypadku pozycji %ProductsCharacteristic%
		| nie można jednocześnie używać planów ze spacją i planuje z wypełnioną wartością pola w tym samym okresie i przedziale:';
		|tr = '%ProductsCharacteristic% ürünleri için 
		|aynı dönemde ve departmanda boş ve dolu alan değerlerine sahip şu planları aynı anda kullanamazsınız:'") + " ";
	MessageTemplate2 = NStr("vi = '%Field%';
							|ru = '%Field%';
							|en = '%Field%'; fa = '%Field%';
							|it = '%Field%';
							|pl = '%Field%';
							|tr = '%Field%'");
	
	Selection = QueryResult.Select();
	While Selection.Next() Do

		MessageText = StrReplace(MessageTemplate1, "%ProductsCharacteristic%",
						ProductsClientServer.ProductPresentation(Selection.Products, Selection.Characteristic));
		
		If Selection.SpecifyingWarehouse > 1 Then
			MessageText = MessageText + StrReplace(MessageTemplate2, "%Field%", "Warehouse");
		EndIf; 
		
		CommonClientServer.MessageToUser(MessageText, ThisObject, ,, Cancel);

	EndDo;

	If CrossTable Then
		NotCheckedAttributeArray.Add("Goods");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Goods.Count");
	Else
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.CheckPossibilityOfRounding = False;
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	EndIf; 
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",                    "Goods");
	CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Hàng hóa';
															|ru = 'Товары';
															|en = 'Goods'; fa = 'کالاها';
															|it = 'Merci';
															|pl = 'Towary';
															|tr = 'Ürünler'"));
	CheckParameters.Insert("Periodicity",            Periodicity);
	CheckParameters.Insert("StartDate",               BeginOfPeriod);
	CheckParameters.Insert("EndDate",            PeriodEnding);
	CheckParameters.Insert("NameOfPeriodDateField",       "BalanceDate");
	CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày tiếp nhận';
															|ru = 'Дата поступления';
															|en = 'Date of receipt'; fa = 'تاریخ دریافت';
															|it = 'Data di ricezione';
															|pl = 'Data wpływu';
															|tr = 'Giriş tarihi'"));
	
	If Not CrossTable Then
		PlanningClientServer.CheckDateOfTSPeriod(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	If CrossTable Then
		NotCheckedAttributeArray.Add("Goods.Characteristic");
	Else
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	EndIf; 
	
	Planning.ProcessingFillVerificationByScenarioPlanType(ThisObject, Cancel, CheckedAttributes);
	
	If Not CrossTable
		And ValueIsFilled(PlanProfile) Then
		
		DetailsTypeOfPlan = Common.ObjectAttributesValues(PlanProfile,"FillInAssignmentInTabularForm, FillInWarehouse");
		
		Query = New Query();
		Query.Text = 
		"SELECT
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Warehouse,
		|	GoodsTable.Purpose,
		|	GoodsTable.BalanceDate,
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
		|	Goods.BalanceDate,
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
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

// The procedure fills the division, scenario, plan view, and cross-table attribute in the document with the default value.
//
Procedure FillInDefaultData()
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
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
	|	Document.PlanOfGoodsStock AS DocumentData
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON DocumentData.PlanProfile = PlanProfiles.Ref
	|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|		ON DocumentData.Scenario = SalesOperationsPlanningScenarios.Ref
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
	
	Scenario = SettingsValueCached.GetDefaultScript(Enums.TypesOfPlans.PlanOfGoodsStock, Scenario);
	
EndProcedure

Procedure FillInDetailsOfPlanForScenarioTypeOfPlan()
	
	ScriptDetails = "Periodicity";
	ScriptDetails = ScriptDetails + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, ScriptDetails);
	If Not ValueIsFilled(PlanProfile) Then
		PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.PlanOfGoodsStock, Scenario);
	EndIf;
	FillPropertyValues(ThisObject, ScriptParameters_);
	
	If ValueIsFilled(PlanProfile) Then
		Attributes = "FillInPaymentPlan,FillInUsingFormula,Substitutional";
		
		PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
		StructureOfSettingsPlanView = Planning.GetDefaultSettings(Enums.TypesOfPlans.PlanOfGoodsStock, PlanProfile);
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

#EndRegion

#EndIf
