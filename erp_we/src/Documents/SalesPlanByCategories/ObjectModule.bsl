#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
Procedure FillInAccordingToTheFillingRule() Export 
	
	Parameters = New Structure("Ref, Scenario, CrossTable, ChangeResultTo, FilledAutomatically, RoundingPrecision, 
		|Department, Warehouse, Status, Periodicity, BeginOfPeriod, PeriodEnding");
	
	FillPropertyValues(Parameters, ThisObject);
	
	Parameters.Insert("FillInRule", True);
	Parameters.Insert("FillingRule", FillingRule.Unload());
	Parameters.Insert("UserSettings", UserSettings.Get());
	
	PopulatedTS = ProductCategories.Unload();
	If UpdateAdd = 0 Then
		PopulatedTS.Clear();
	EndIf;
	
	Parameters.Insert("PopulatedTS", PopulatedTS);
	
	StorageAddress = PutToTempStorage(Undefined);
	Documents.SalesPlanByCategories.FillInAccordingToTheFillingRule(Parameters, StorageAddress);
	
	PopulatedTS = GetFromTempStorage(StorageAddress);
	
	ProductCategories.Load(PopulatedTS);
	
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
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If CrossTable Then
		NotCheckedAttributeArray.Add("ProductCategories");
		NotCheckedAttributeArray.Add("ProductCategories.ProductCategory");
		NotCheckedAttributeArray.Add("ProductCategories.Count");
	EndIf;
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",                    "ProductCategories");
	CheckParameters.Insert("PresentationOfTS",          NStr("vi = 'Thể loại hàng hóa';
															|ru = 'Товарные категории';
															|en = 'Product categories'; fa = 'دسته‌های محصول';
															|it = 'Categorie di merci';
															|pl = 'Kategorie towarowe';
															|tr = 'Ürün kategorileri'"));
	CheckParameters.Insert("Periodicity",            Periodicity);
	CheckParameters.Insert("StartDate",               BeginOfPeriod);
	CheckParameters.Insert("EndDate",            PeriodEnding);
	CheckParameters.Insert("NameOfPeriodDateField",       "DateOfShipment");
	CheckParameters.Insert("PresentationOfPeriodDate", NStr("vi = 'Ngày giao hàng';
															|ru = 'Дата отгрузки';
															|en = 'Shipment date'; fa = 'تاریخ ارسال';
															|it = 'Data di spedizione';
															|pl = 'Data wysyłki';
															|tr = 'Sevkiyat tarihi'"));
	
	If Not CrossTable Then
		PlanningClientServer.CheckDateOfTSPeriod(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	Planning.ProcessingFillVerificationByScenarioPlanType(ThisObject, Cancel, CheckedAttributes);
	
	If Not CrossTable
		And ValueIsFilled(PlanProfile) Then
		
		Query = New Query();
		Query.Text = 
		"SELECT
		|	ProductCategories.ProductCategory,
		|	ProductCategories.SalesRank,
		|	ProductCategories.Purpose,
		|	ProductCategories.DateOfShipment,
		|	ProductCategories.Count
		|INTO ProductCategories
		|FROM
		|	&ProductCategories AS ProductCategories
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductCategories.ProductCategory,
		|	ProductCategories.SalesRank,
		|	ProductCategories.Purpose,
		|	SUM(ProductCategories.Count) AS Count
		|FROM
		|	ProductCategories AS ProductCategories
		|WHERE
		|	ProductCategories.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
		|
		|GROUP BY
		|	ProductCategories.ProductCategory,
		|	ProductCategories.SalesRank,
		|	ProductCategories.DateOfShipment,
		|	ProductCategories.Purpose
		|
		|HAVING
		|	SUM(ProductCategories.Count) = 0";
		Query.SetParameter("ProductCategories", ProductCategories.Unload());
		
		ErrorsTable = Query.Execute().Unload();
		
		DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
		TheStructureOfTheSearch = New Structure("ProductCategory,SalesRank,Purpose");
		FillInAssignmentInTabularForm = Common.ObjectAttributeValue(PlanProfile,"FillInAssignmentInTabularForm");
		
		For Each ErrorString In ErrorsTable Do
			
			MessageText = NStr("vi = 'Đối với các dòng kế hoạch với danh mục hàng hóa %ProductCategory%%SalesRank%%Purpose% không có số lượng kế hoạch trong bất kỳ giai đoạn lập kế hoạch nào.';
								|ru = 'Для строк плана с товарной категорией %ProductCategory%%SalesRank%%Purpose% не запланировано количество ни в одном периоде планирования.';
								|en = 'Quantity is not planned in any planning period for lines of plan with the %ProductCategory%%SalesRank%%Purpose% product category.'; fa = 'Quantity is not planned in any planning period for lines of plan with the %ProductCategory%%SalesRank%%Purpose% product category.';
								|it = 'Per le righe del piano con la categoria merceologica %ProductCategory%%SalesRank%%Purpose% la quantità non è stata programmata in alcun periodo di pianificazione.';
								|pl = 'W przypadku wierszy planu z kategorią towaru %ProductCategory%%SalesRank%%Purpose% ilość nie jest planowana w żadnym okresie planowania.';
								|tr = 'Ürün kategorisi ile satır planı için %ProductCategory%%SalesRank%%Purpose% hiçbir planlama döneminde miktar programlanmadı.'");
			MessageText = StrReplace(MessageText, "%ProductCategory%", ErrorString.ProductCategory);
			MessageText = StrReplace(MessageText, "%SalesRank%", ?(ValueIsFilled(ErrorString.SalesRank), NStr("vi = ', đánh giá doanh số';
																												|ru = ', рейтингом продаж';
																												|en = ', sales rank'; fa = ', sales rank';
																												|it = ', ranking delle vendite';
																												|pl = ', z rankingiem sprzedaży';
																												|tr = ',satış sıralaması'") + ErrorString.SalesRank, NStr("vi = ', không có đánh giá bán hàng';
																																									|ru = ', без рейтинга продаж';
																																									|en = ', without sales rank'; fa = ', without sales rank';
																																									|it = ', senza il ranking delle vendite';
																																									|pl = ', bez rankingu sprzedaży';
																																									|tr = ',satış sıralaması olmadan'")));
			MessageText = StrReplace(MessageText, "%Purpose%", ?(ValueIsFilled(ErrorString.Purpose)
				And FillInAssignmentInTabularForm,
				NStr("vi = ', chỉ định';
					|ru = ', назначением';
					|en = ', assignment'; fa = ', assignment';
					|it = ', destinazione';
					|pl = ', przeznaczeniem';
					|tr = ', amaç'") + ErrorString.Purpose, ""));
			
			FillPropertyValues(TheStructureOfTheSearch, ErrorString);
			SearchString = ProductCategories.FindRows(TheStructureOfTheSearch)[0];
			
			Field = CommonClientServer.PathToTabularSection("ProductCategories", SearchString.LineNumber, "Count");
			
			CommonClientServer.MessageToUser(MessageText,DataKey, Field,"Object",Cancel);
			
		EndDo;
		
		GroupFields = "ProductCategory, SalesRank, Warehouse, Purpose, DateOfShipment";
		Planning.HandlingStringDuplicationChecking(ProductCategories, "ProductCategories", GroupFields, Cancel);
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
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
	If Substitutional Then
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.PlanSubstitution");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("PlanProfile", PlanProfile);
		Block.Lock();
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	Planning.CheckApprovedStatus(ThisObject, Cancel, WriteMode, Enums.TypesOfPlans.SalesPlanByCategories);
	
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
		
		For Each String In ProductCategories Do
			String.Substituted = False;
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
	|	SubstitutedPeriods.Period
	|INTO SubstitutedPeriods
	|FROM
	|	&TimeIntervals AS SubstitutedPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesPlanByCategorySubstitute.Ref,
	|	SalesPlanByCategorySubstitute.PlanProfile,
	|	CASE
	|		WHEN &BeginOfPeriod > SalesPlanByCategorySubstitute.BeginOfPeriod
	|			THEN &BeginOfPeriod
	|		ELSE SalesPlanByCategorySubstitute.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN &PeriodEnding < SalesPlanByCategorySubstitute.PeriodEnding
	|			THEN &PeriodEnding
	|		ELSE SalesPlanByCategorySubstitute.PeriodEnding
	|	END AS PeriodEnding,
	|	SalesPlanByCategorySubstitute.Status = VALUE(Enum.PlanStatuses.Upholded)
	|		AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS SubstitutedToOrder,
	|	SalesPlanByCategorySubstitute.Status.Order >= &StatusIndex
	|		OR SalesPlanByCategorySubstitute.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|			AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS Substituted,
	|	SalesPlanByCategorySubstitute.Status AS SubstitutionStatus
	|INTO ReplacementPlans
	|FROM
	|	Document.SalesPlanByCategories AS SalesPlanByCategorySubstitute
	|WHERE
	|	SalesPlanByCategorySubstitute.PeriodEnding >= &BeginOfPeriod
	|	AND SalesPlanByCategorySubstitute.BeginOfPeriod <= &PeriodEnding
	|	AND SalesPlanByCategorySubstitute.Ref <> &Ref
	|	AND SalesPlanByCategorySubstitute.Posted
	|	AND SalesPlanByCategorySubstitute.PlanProfile = &PlanProfile
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND (SalesPlanByCategorySubstitute.Status.Order >= &StatusIndex
	|			OR SalesPlanByCategorySubstitute.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
	|	AND SalesPlanByCategorySubstitute.Date > &Date
	|	AND SalesPlanByCategorySubstitute.Department = &Department
	|	AND SalesPlanByCategorySubstitute.StoreFormat = &StoreFormat
	|	AND SalesPlanByCategorySubstitute.Purpose = &Purpose
	|	AND SalesPlanByCategorySubstitute.Warehouse = &Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
	|	SubstitutedPeriods.Period AS SubstitutedPeriod,
	|	FALSE AS ForSubstitution,
	|	FALSE AS ForSubstitutionCancellation,
	|	ReplacementPlans.Ref AS SubstitutePlan,
	|	&Ref AS SubstitutedPlan
	|INTO PlanSubstitution
	|FROM
	|	ReplacementPlans AS ReplacementPlans
	|		LEFT JOIN SubstitutedPeriods AS SubstitutedPeriods
	|		ON ReplacementPlans.BeginOfPeriod <= SubstitutedPeriods.Period
	|			AND ReplacementPlans.PeriodEnding >= SubstitutedPeriods.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanByProductCategory.DateOfShipment,
	|	CASE &Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(SalesPlanByProductCategory.DateOfShipment, YEAR)
	|		ELSE SalesPlanByProductCategory.DateOfShipment
	|	END AS Period
	|INTO SalesPlanByProductCategory
	|FROM
	|	&SalesPlanByProductCategory AS SalesPlanByProductCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SalesPlanByProductCategory.DateOfShipment
	|FROM
	|	PlanSubstitution AS PlanSubstitution
	|		INNER JOIN SalesPlanByProductCategory AS SalesPlanByProductCategory
	|		ON PlanSubstitution.SubstitutedPeriod = SalesPlanByProductCategory.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanSubstitution.PlanProfile,
	|	PlanSubstitution.SubstitutedPeriod,
	|	PlanSubstitution.ForSubstitution,
	|	PlanSubstitution.ForSubstitutionCancellation,
	|	PlanSubstitution.SubstitutePlan,
	|	PlanSubstitution.SubstitutedPlan
	|FROM
	|	PlanSubstitution AS PlanSubstitution";
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Status));
	Query.SetParameter("Status", Status);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Department", Department);
	Query.SetParameter("StoreFormat", StoreFormat);
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("SalesPlanByProductCategory", ProductCategories.Unload());
	
	RequestPackage = Query.ExecuteBatch();
	Selection = RequestPackage[4].Select();
	PlanReplacementTable = RequestPackage[5].Unload();
	
	For Each String In ProductCategories Do
		String.Substituted = False;
	EndDo;
	
	While Selection.Next() Do
		
		Filter = New Structure("DateOfShipment", Selection.DateOfShipment);
		ReplacementLines = ProductCategories.FindRows(Filter);
		For Each String In ReplacementLines Do
			String.Substituted = True;
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
	|	TimeIntervals.Period
	|INTO TimeIntervals
	|FROM
	|	&TimeIntervals AS TimeIntervals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesPlanByCategorySubstituted.Ref,
	|	SalesPlanByCategorySubstituted.PlanProfile,
	|	CASE
	|		WHEN SalesPlanByCategories.BeginOfPeriod > SalesPlanByCategorySubstituted.BeginOfPeriod
	|			THEN SalesPlanByCategories.BeginOfPeriod
	|		ELSE SalesPlanByCategorySubstituted.BeginOfPeriod
	|	END AS BeginOfPeriod,
	|	CASE
	|		WHEN SalesPlanByCategories.PeriodEnding < SalesPlanByCategorySubstituted.PeriodEnding
	|			THEN SalesPlanByCategories.PeriodEnding
	|		ELSE SalesPlanByCategorySubstituted.PeriodEnding
	|	END AS PeriodEnding
	|INTO SubstitutedPlans
	|FROM
	|	Document.SalesPlanByCategories AS SalesPlanByCategories
	|		INNER JOIN Document.SalesPlanByCategories AS SalesPlanByCategorySubstituted
	|		ON SalesPlanByCategories.PlanProfile = SalesPlanByCategorySubstituted.PlanProfile
	|			AND (SalesPlanByCategories.Status.Order >= SalesPlanByCategorySubstituted.Status.Order
	|				OR SalesPlanByCategories.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|					AND SalesPlanByCategorySubstituted.Status = VALUE(Enum.PlanStatuses.Upholded))
	|			AND SalesPlanByCategorySubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|			AND SalesPlanByCategories.Date > SalesPlanByCategorySubstituted.Date
	|			AND SalesPlanByCategories.StoreFormat = SalesPlanByCategorySubstituted.StoreFormat
	|			AND SalesPlanByCategories.Department = SalesPlanByCategorySubstituted.Department
	|			AND SalesPlanByCategories.Purpose = SalesPlanByCategorySubstituted.Purpose
	|			AND SalesPlanByCategories.Warehouse = SalesPlanByCategorySubstituted.Warehouse
	|			AND SalesPlanByCategorySubstituted.Posted
	|			AND SalesPlanByCategorySubstituted.Substitutional
	|WHERE
	|	SalesPlanByCategorySubstituted.PeriodEnding >= SalesPlanByCategories.BeginOfPeriod
	|	AND SalesPlanByCategorySubstituted.BeginOfPeriod <= SalesPlanByCategories.PeriodEnding
	|	AND SalesPlanByCategories.Ref = &Ref
	|	AND SalesPlanByCategories.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
	|	TimeIntervals.Period AS SubstitutedPeriod,
	|	ReplacementPlans.Ref AS SubstitutedPlan,
	|	&Ref AS SubstitutePlan
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
	|	TRUE,
	|	FALSE
	|FROM
	|	SubstitutedPlansByPeriod AS SubstitutedPlansByPeriod
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
	|		ON SubstitutedPlansByPeriod.PlanProfile = PlanSubstitution.PlanProfile
	|			AND SubstitutedPlansByPeriod.SubstitutedPeriod = PlanSubstitution.SubstitutedPeriod
	|			AND SubstitutedPlansByPeriod.SubstitutedPlan = PlanSubstitution.SubstitutedPlan
	|			AND SubstitutedPlansByPeriod.SubstitutePlan = PlanSubstitution.SubstitutePlan
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
	|	MIN(ISNULL(PlanSubstitution.ForSubstitutionCancellation, TRUE)) AS PerformUndoSubstitution
	|INTO PlanSubstitution
	|FROM
	|	SubstitutionOfPlansSumOfRegisteredRecords AS SubstitutionOfPlansSumOfRegisteredRecords
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution
	|		ON SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan = PlanSubstitution.SubstitutedPlan
	|			AND SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod = PlanSubstitution.SubstitutedPeriod
	|			AND (NOT PlanSubstitution.ForSubstitutionCancellation)
	|			AND (&Ref <> PlanSubstitution.SubstitutePlan)
	|		LEFT JOIN InformationRegister.PlanSubstitution AS PlanSubstitution1
	|		ON SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan = PlanSubstitution1.SubstitutedPlan
	|			AND SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod = PlanSubstitution1.SubstitutedPeriod
	|			AND (NOT PlanSubstitution1.ForSubstitution)
	|			AND (&Ref <> PlanSubstitution1.SubstitutePlan)
	|
	|GROUP BY
	|	SubstitutionOfPlansSumOfRegisteredRecords.PlanProfile,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPeriod,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutedPlan,
	|	SubstitutionOfPlansSumOfRegisteredRecords.SubstitutePlan
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
	|	PlanSubstitution.PerformUndoSubstitution
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
	For Each LineProducts_ In ProductCategories Do

		LineProducts_.Canceled = False;

	EndDo;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	EmployeeResponsible = Users.CurrentUser();
	FillInDefaultData();
	
	FillInDetailsOfPlanForScenarioTypeOfPlan();
EndProcedure

// The procedure fills the division, scenario, plan view, and cross-table attribute in the document with the default value.
//
Procedure FillInDefaultData()
	
	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	CASE
	|		WHEN BusinessStructure.DeletionMark
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE DocumentData.Department
	|	END AS Department,
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
	|	Document.SalesPlanByCategories AS DocumentData
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON DocumentData.PlanProfile = PlanProfiles.Ref
	|		LEFT JOIN Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|		ON DocumentData.Scenario = SalesOperationsPlanningScenarios.Ref
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON DocumentData.Department = BusinessStructure.Ref
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
	
	Scenario = SettingsValueCached.GetDefaultScript(Enums.TypesOfPlans.SalesPlanByCategories, Scenario);
	
EndProcedure

Procedure FillInDetailsOfPlanForScenarioTypeOfPlan()
	
	ScriptDetails = "Periodicity";
	ScriptDetails = ScriptDetails + ", BudgetingScenario";
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, ScriptDetails);
	If Not ValueIsFilled(PlanProfile) Then
		PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.SalesPlanByCategories, Scenario);
	EndIf;
	FillPropertyValues(ThisObject, ScriptParameters_);
	
	If ValueIsFilled(PlanProfile) Then
		Attributes = "FillInUsingFormula,Substitutional";
		
		PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
		StructureOfSettingsPlanView = Planning.GetDefaultSettings(Enums.TypesOfPlans.SalesPlanByCategories, PlanProfile);
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

#EndRegion

#EndIf