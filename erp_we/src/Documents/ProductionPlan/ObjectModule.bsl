#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the tabular part of the document according to the filling rule from various sources.
//
Procedure FillInAccordingToTheFillingRule() Export 
	
	Parameters = New Structure("Ref, Scenario, CrossTable, ChangeResultTo, FilledAutomatically, RoundingPrecision, 
		|Department, Status, Periodicity, BeginOfPeriod, PeriodEnding");
	
	FillPropertyValues(Parameters, ThisObject);
	
	Parameters.Insert("FillInRule", True);
	Parameters.Insert("FillingRule", FillingRule.Unload());
	Parameters.Insert("UserSettings", UserSettings.Get());
	
	PopulatedTS = ManufacturedProduct.Unload();
	If UpdateAdd = 0 Then
		PopulatedTS.Clear();
	EndIf;
	
	Parameters.Insert("PopulatedTS", PopulatedTS);
	
	StorageAddress = PutToTempStorage(Undefined);
	Documents.ProductionPlan.FillInAccordingToTheFillingRule(Parameters, StorageAddress);
	
	PopulatedTS = GetFromTempStorage(StorageAddress);
	
	ManufacturedProduct.Load(PopulatedTS);
	
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
	
	InitializeDocument(False, FillingData);
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
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
	
	Planning.CheckApprovedStatus(ThisObject, Cancel, WriteMode, Enums.TypesOfPlans.ProductionPlan);
	
	// Fill in the launch dates, release dates
	ThisIsDisassembly = ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
	If Not CrossTable Then
		
		NameOfPeriodDateField = ?(ThisIsDisassembly, "StartDate2", "DateOfProduction");
		
		CollectionOfOrderDateCalculationLines = New Array;
		
		For Each String In ManufacturedProduct Do
			
			If Not ValueIsFilled(String[NameOfPeriodDateField]) Then
				
				String[NameOfPeriodDateField] = BeginOfPeriod;
				
			EndIf;
			
			If Not ThisIsDisassembly 
				And Not ValueIsFilled(String.StartDate2) Then
				CollectionOfOrderDateCalculationLines.Add(String);
			EndIf;
			
		EndDo;
		
		If CollectionOfOrderDateCalculationLines.Count()>0 Then
			Planning.GetDurationSpecificationsAndFillDatesOnSchedule(
				CollectionOfOrderDateCalculationLines,
				"DateOfProduction",
				"StartDate2",
				Scenario,
				False,
				DemandForMaterials);
		EndIf;
		
	EndIf;
	
	If Substitutional And Not IsNew() And Not Cancel Then
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
	
	ItIsRequiredToCalculateProductionPlan_ = ItIsRequiredToCalculateProductionPlan();
	If Not IsNew()
		And ItIsRequiredToCalculateProductionPlan_ Then
		CalculationOfProductionPlan.SetCalculationSeparator(ThisObject, WriteMode);
	EndIf;
	AdditionalProperties.Insert("PlanningScenario", Scenario);
	AdditionalProperties.Insert("ItIsRequiredToCalculateProductionPlan_", ItIsRequiredToCalculateProductionPlan_);
	
	If AutoFill
		And (Status = Enums.PlanStatuses.RolledBack_
		Or Status = Enums.PlanStatuses.UnderPreparation) Then
		AutoFill = False;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If Not Cancel Then
		
		If Substitutional
			Or Planning.ThereIsSubstitutionPlan(Ref) Then
			SetPrivilegedMode(True);
			UpdateSubstitutedPlans();
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
	If Not Cancel And AdditionalProperties.ItIsRequiredToCalculateProductionPlan_
		And DocumentsPosting.DocumentProperties(ThisObject).WriteMode = DocumentWriteMode.UndoPosting Then
		
		InformationRegisters.QueueOfProductionPlanCalculation.AddJob(Scenario, Ref);
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Status = Metadata().Attributes.Status.FillValue;
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;

	For Each LineProducts_ In ManufacturedProduct Do
		LineProducts_.Canceled = False;
	EndDo;
	
	CalculationSeparator = 0;
	
	InitializeDocument(True);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	If Not Cancel And AdditionalProperties.ItIsRequiredToCalculateProductionPlan_ Then
		InformationRegisters.QueueOfProductionPlanCalculation.AddJob(ThisObject.Scenario, Ref);
	EndIf;
	If Not Cancel 
		And Not AdditionalProperties.ItIsRequiredToCalculateProductionPlan_ 
		And Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	If Common.ObjectAttributeValue(Scenario,"PlanningProcessManagement") 
		And Not Cancel 
		And Not AdditionalProperties.ItIsRequiredToCalculateProductionPlan_ Then
		
		Planning.RunningBackgroundCheckForCalculatingDeficitInStages(Scenario, PlanProfile);
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("ManufacturedProduct");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Products");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Characteristic");
	NotCheckedAttributeArray.Add("ManufacturedProduct.NumberOfPackages");
	NotCheckedAttributeArray.Add("ManufacturedProduct.Count");
	NotCheckedAttributeArray.Add("ManufacturedProduct.BillOfMaterials");
	
	ProcessType = ?(ProductionProcessType.IsEmpty(),
		Enums.ProductionProcessTypes.Assembly,
		ProductionProcessType);
	
	TitleOfTablePart = ProductionClientServer.TitleOfTablePartByProcessType(ProcessType);
	
	FillInTheSpecification = Common.ObjectAttributeValue(
		Scenario, "UseForMaterialsPlanning") And Status = Enums.PlanStatuses.Upholded;
		
	If Not CrossTable And ManufacturedProduct.Count() = 0 Then
			
			MessageText = CommonClientServer.FillingErrorText(
				"List",
				"FillType",,,
				TitleOfTablePart);
			CommonClientServer.MessageToUser(MessageText, ThisObject, "ManufacturedProduct",, Cancel);
			
	ElsIf Not CrossTable
		And ValueIsFilled(PlanProfile)
		And Not FillInByShortage Then
			
		For Each String In ManufacturedProduct Do
			
			If String.Products.IsEmpty() Then
				
				MessageText = CommonClientServer.FillingErrorText(
					"Column",
					"FillType",
					"Products",
					Format(String.LineNumber, "NG="),
					TitleOfTablePart);
				Field = CommonClientServer.PathToTabularSection(
					"ManufacturedProduct",
					String.LineNumber,
					"Products");
				CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel);
				
			EndIf;
			
			If FillInTheSpecification And String.BillOfMaterials.IsEmpty() Then
				
				MessageText = CommonClientServer.FillingErrorText(
					"Column",
					"FillType",
					"BillOfMaterials",
					Format(String.LineNumber, "NG="),
					TitleOfTablePart);
				Field = CommonClientServer.PathToTabularSection(
					"ManufacturedProduct",
					String.LineNumber,
					"BillOfMaterials");
				CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel);
				
			EndIf;
			
		EndDo;
		
		// Checking characteristics
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "ManufacturedProduct";
		CheckParameters.PresentationOfTS = TitleOfTablePart;
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		// Checking the quantity
		CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		CheckParameters.TSName = "ManufacturedProduct";
		CheckParameters.PresentationOfTS = TitleOfTablePart;
		CheckParameters.CheckPossibilityOfRounding = False;
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
		
		// The quantity is filled in at least one period
		Query = New Query();
		Query.Text = 
		"SELECT
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.BillOfMaterials,
		|	ProductTable.Purpose,
		|	ProductTable.DateOfProduction,
		|	ProductTable.Count
		|INTO ManufacturedProduct
		|FROM
		|	&ProductTable AS ProductTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ManufacturedProduct.Products,
		|	ManufacturedProduct.Characteristic,
		|	ManufacturedProduct.BillOfMaterials,
		|	ManufacturedProduct.Purpose,
		|	SUM(ManufacturedProduct.Count) AS Count
		|FROM
		|	ManufacturedProduct AS ManufacturedProduct
		|WHERE
		|	ManufacturedProduct.Products <> VALUE(Catalog.Products.EmptyRef)
		|	AND ManufacturedProduct.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|
		|GROUP BY
		|	ManufacturedProduct.Products,
		|	ManufacturedProduct.BillOfMaterials,
		|	ManufacturedProduct.Purpose,
		|	ManufacturedProduct.DateOfProduction,
		|	ManufacturedProduct.Characteristic
		|
		|HAVING
		|	SUM(ManufacturedProduct.Count) = 0";
		Query.SetParameter("ProductTable", ManufacturedProduct.Unload());
		
		ErrorsTable = Query.Execute().Unload();
		
		DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
		TheStructureOfTheSearch = New Structure("Products,Characteristic,Purpose,BillOfMaterials");
		FillInAssignmentInTabularForm = Common.ObjectAttributeValue(PlanProfile,"FillInAssignmentInTabularForm");
		
		For Each ErrorString In ErrorsTable Do
			
			MessageText = NStr("vi = 'Đối với các dòng kế hoạch với mặt hàng %Products%%Characteristic%%Purpose%%BillOfMaterials% không có số lượng được lên kế hoạch trong bất kỳ giai đoạn lập kế hoạch nào.';
								|ru = 'Для строк плана с номенклатурой %Products%%Characteristic%%Purpose%%BillOfMaterials% не запланировано количество ни в одном периоде планирования.';
								|en = 'Quantity is not planned in any planning period for lines of plan with the %Products%%Characteristic%%Purpose%%BillOfMaterials% items.'; fa = 'Quantity is not planned in any planning period for lines of plan with the %Products%%Characteristic%%Purpose%%BillOfMaterials% items.';
								|it = 'Per le righe del piano con nomenclatura %Products%%Characteristic%%Purpose%%BillOfMaterials% la quantità non è programmata in alcun periodo di pianificazione.';
								|pl = 'W przypadku wierszy planu z pozycją %Products%%Characteristic%%Purpose% %BillOfMaterials% ilość nie jest planowana w żadnym okresie planowania.';
								|tr = 'Ürünler ile satır planı için %Products%%Characteristic%%Purpose%%BillOfMaterials% hiçbir planlama döneminde miktar programlanmadı.'");
			MessageText = StrReplace(MessageText, "%Products%", ErrorString.Products);
			MessageText = StrReplace(MessageText, "%Characteristic%", ?(ValueIsFilled(ErrorString.Characteristic), NStr("vi = ', đặc tính';
																														|ru = ', характеристикой';
																														|en = ', variants'; fa = ', variants';
																														|it = ', caratteristica';
																														|pl = ', charakterystyką';
																														|tr = ', özellik'") + ErrorString.Characteristic, ""));
			MessageText = StrReplace(MessageText, "%Purpose%", ?(ValueIsFilled(ErrorString.Purpose)
				And FillInAssignmentInTabularForm,
				NStr("vi = ', chỉ định';
					|ru = ', назначением';
					|en = ', assignment'; fa = ', assignment';
					|it = ', destinazione';
					|pl = ', przeznaczeniem';
					|tr = ', amaç'") + ErrorString.Purpose, ""));
			MessageText = StrReplace(MessageText, "%BillOfMaterials%", ?(ValueIsFilled(ErrorString.BillOfMaterials), " " + NStr("vi = 'và bảng kê nguồn lực sản xuất';
																																|ru = 'и спецификацией';
																																|en = 'and bill of materials'; fa = 'and bill of materials';
																																|it = 'e specifica';
																																|pl = 'i specyfikacją';
																																|tr = 'detayları ile'") + " " + ErrorString.BillOfMaterials, ""));
		
			FillPropertyValues(TheStructureOfTheSearch, ErrorString);
			SearchString = ManufacturedProduct.FindRows(TheStructureOfTheSearch)[0];
			
			Field = CommonClientServer.PathToTabularSection("ManufacturedProduct", SearchString.LineNumber, "NumberOfPackages");
			
			CommonClientServer.MessageToUser(MessageText,DataKey, Field,"Object",Cancel);
			
		EndDo;
		
	EndIf;
	
	If ManufacturedProduct.Count() <> 0
		And Not CrossTable
		And ValueIsFilled(PlanProfile) Then
		
		GroupFields = "Products, Characteristic, Purpose, Package, BillOfMaterials, SemiFinishedProduct, StartDate2, DateOfProduction";
		Planning.HandlingStringDuplicationChecking(ManufacturedProduct, "ManufacturedProduct", GroupFields, Cancel);
		
	EndIf;
	
	// Checking dates
	ThisIsDisassembly = ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
	
	CheckParameters = New Structure;
	CheckParameters.Insert("TSName",                    "ManufacturedProduct");
	CheckParameters.Insert("PresentationOfTS",          TitleOfTablePart);
	CheckParameters.Insert("Periodicity",            Periodicity);
	CheckParameters.Insert("StartDate",               BeginOfPeriod);
	CheckParameters.Insert("EndDate",            PeriodEnding);
	CheckParameters.Insert("NameOfPeriodDateField",       ?(ThisIsDisassembly, "StartDate2", "DateOfProduction"));
	CheckParameters.Insert("PresentationOfPeriodDate", ?(ThisIsDisassembly, NStr("vi = 'Ngày vận hành';
																				|ru = 'Дата запуска';
																				|en = 'Launch date'; fa = 'تاریخ شروع';
																				|it = 'Data di avvio';
																				|pl = 'Data uruchomienia';
																				|tr = 'Başlangıç tarihi'"), NStr("vi = 'Ngày xuất xưởng';
																											|ru = 'Дата выпуска';
																											|en = 'Release date'; fa = 'تاریخ انتشار';
																											|it = 'Data di produzione';
																											|pl = 'Data wydania';
																											|tr = 'Çıkış tarihi'")));
	
	If Not CrossTable Then
		PlanningClientServer.CheckDateOfTSPeriod(ThisObject, Cancel, CheckParameters);
	EndIf;
	
	// Universal checks of the "Planning" subsystem
	Planning.ProcessingFillVerificationByScenarioPlanType(ThisObject, Cancel, CheckedAttributes);
	
	If ValueIsFilled(Scenario)
		And (Not FillInTheSpecification
		Or Not ProductDataManagement.AvailableDescriptionOfProbabilityOfApplicationOfMaterials()) Then
		NotCheckedAttributeArray.Add("DemandForMaterials");
	EndIf;
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(ThisIsCopying, FillingData = Undefined)
	
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillingData.Property("Scenario", ThisObject.Scenario);
		FillingData.Property("PlanProfile", ThisObject.PlanProfile);
		FillingData.Property("BeginOfPeriod", ThisObject.BeginOfPeriod);
		FillingData.Property("PeriodEnding", ThisObject.PeriodEnding);
		FillingData.Property("Status", ThisObject.Status);
	ElsIf Not ThisIsCopying Then
		FillInDefaultData();
	EndIf;
	
	FillInDetailsOfPlanForScenarioTypeOfPlan(ThisIsCopying);
	
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	ProductionManagement2_2 = ProductionSettings.ProductionIsUsed22;
	
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
	|	Document.ProductionPlan AS DocumentData
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
	
	Scenario = SettingsValueCached.GetDefaultScript(Enums.TypesOfPlans.ProductionPlan, Scenario);
	
EndProcedure

Procedure FillInDetailsOfPlanForScenarioTypeOfPlan(ThisIsCopying)
	
	ScriptDetails = "Periodicity";
	ScriptDetails = ScriptDetails + ", BudgetingScenario";
	If Not ThisIsCopying Then
		ScriptDetails = ScriptDetails + ",DemandForMaterials";
	EndIf;
	ScriptParameters_ = Common.ObjectAttributesValues(Scenario, ScriptDetails);
	If Not ValueIsFilled(PlanProfile) Then
		PlanProfile = Planning.GetDefaultPlanView(Enums.TypesOfPlans.ProductionPlan, Scenario);
	EndIf;
	FillPropertyValues(ThisObject, ScriptParameters_);
	
	If ValueIsFilled(PlanProfile) Then
		Attributes = "FillInUsingFormula,Substitutional";
		Attributes = Attributes + ", ProductionProcessType";
		PlanViewParameters = Common.ObjectAttributesValues(PlanProfile, Attributes);
		
		StructureOfSettingsPlanView = Planning.GetDefaultSettings(Enums.TypesOfPlans.ProductionPlan, PlanProfile);
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

Procedure UpdateSubstitutedPlans()
	
	TimeIntervals = New ValueTable();
	TimeIntervals.Columns.Add("Period", New TypeDescription("Date"));
	
	AddingStartDate = SubstitutionPeriodStart;
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
	|	ProductionPlanSubstituted.Ref,
	|	ProductionPlanSubstituted.PlanProfile,
	|	CASE
	|		WHEN ProductionPlan.SubstitutionPeriodStart > ProductionPlanSubstituted.SubstitutionPeriodStart
	|			THEN ProductionPlan.SubstitutionPeriodStart
	|		ELSE ProductionPlanSubstituted.SubstitutionPeriodStart
	|	END AS SubstitutionPeriodStart,
	|	CASE
	|		WHEN ProductionPlan.PeriodEnding < ProductionPlanSubstituted.PeriodEnding
	|			THEN ProductionPlan.PeriodEnding
	|		ELSE ProductionPlanSubstituted.PeriodEnding
	|	END AS PeriodEnding,
	|	ProductionPlan.Status AS SubstitutionStatus
	|INTO SubstitutedPlans
	|FROM
	|	Document.ProductionPlan AS ProductionPlan
	|		INNER JOIN Document.ProductionPlan AS ProductionPlanSubstituted
	|		ON ProductionPlan.PlanProfile = ProductionPlanSubstituted.PlanProfile
	|			AND (ProductionPlan.Status.Order >= ProductionPlanSubstituted.Status.Order
	|				OR ProductionPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
	|					AND ProductionPlanSubstituted.Status = VALUE(Enum.PlanStatuses.Upholded))
	|			AND ProductionPlanSubstituted.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|			AND ProductionPlan.Date > ProductionPlanSubstituted.Date
	|			AND ProductionPlan.Department = ProductionPlanSubstituted.Department
	|			AND ProductionPlan.Purpose = ProductionPlanSubstituted.Purpose
	|			AND ProductionPlanSubstituted.Posted
	|			AND ProductionPlanSubstituted.Substitutional
	|WHERE
	|	ProductionPlanSubstituted.PeriodEnding >= ProductionPlan.SubstitutionPeriodStart
	|	AND ProductionPlanSubstituted.SubstitutionPeriodStart <= ProductionPlan.PeriodEnding
	|	AND ProductionPlan.Ref = &Ref
	|	AND ProductionPlan.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPlans.PlanProfile,
	|	TimeIntervals.Period AS SubstitutedPeriod,
	|	ReplacementPlans.Ref AS SubstitutedPlan,
	|	&Ref AS SubstitutePlan,
	|	ReplacementPlans.SubstitutionStatus AS SubstitutionStatus
	|INTO SubstitutedPlansByPeriod
	|FROM
	|	SubstitutedPlans AS ReplacementPlans
	|		LEFT JOIN TimeIntervals AS TimeIntervals
	|		ON ReplacementPlans.SubstitutionPeriodStart <= TimeIntervals.Period
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

Procedure UpdatePlanReplacement(WriteMode, IBUpdate = False) Export
	
	If WriteMode = DocumentWriteMode.UndoPosting
		Or (WriteMode = DocumentWriteMode.Write And Not Posted) Then
		
		For Each String In ManufacturedProduct Do
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
	
	AddingStartDate = SubstitutionPeriodStart;
	While AddingStartDate < EndOfDay(PeriodEnding) Do
		NewRow = TimeIntervals.Add();
		NewRow.Period = AddingStartDate;
		
		EndDateOfPeriod = PlanningClientServerCached.CalculatePeriodEndDate(AddingStartDate, Periodicity);
		AddingStartDate = EndDateOfPeriod+1;
	EndDo;
	
	QueryText =
		"SELECT
		|	TimeIntervals.Period AS Period
		|INTO TimeIntervals
		|FROM
		|	&TimeIntervals AS TimeIntervals
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReplacementProductionPlan.Ref AS Ref,
		|	ReplacementProductionPlan.PlanProfile AS PlanProfile,
		|	CASE
		|		WHEN &SubstitutionPeriodStart > ReplacementProductionPlan.SubstitutionPeriodStart
		|			THEN &SubstitutionPeriodStart
		|		ELSE ReplacementProductionPlan.SubstitutionPeriodStart
		|	END AS SubstitutionPeriodStart,
		|	CASE
		|		WHEN &PeriodEnding < ReplacementProductionPlan.PeriodEnding
		|			THEN &PeriodEnding
		|		ELSE ReplacementProductionPlan.PeriodEnding
		|	END AS PeriodEnding,
		|	ReplacementProductionPlan.Status = VALUE(Enum.PlanStatuses.Upholded)
		|		AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS SubstitutedToOrder,
		|	ReplacementProductionPlan.Status.Order >= &StatusIndex
		|		OR ReplacementProductionPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
		|			AND &Status = VALUE(Enum.PlanStatuses.Upholded) AS Substituted,
		|	ReplacementProductionPlan.Status AS SubstitutionStatus
		|INTO ReplacementPlans
		|FROM
		|	Document.ProductionPlan AS ReplacementProductionPlan
		|WHERE
		|	ReplacementProductionPlan.PeriodEnding >= &SubstitutionPeriodStart
		|	AND ReplacementProductionPlan.SubstitutionPeriodStart <= &PeriodEnding
		|	AND ReplacementProductionPlan.Ref <> &Ref
		|	AND ReplacementProductionPlan.Posted
		|	AND ReplacementProductionPlan.PlanProfile = &PlanProfile
		|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
		|	AND (ReplacementProductionPlan.Status.Order >= &StatusIndex
		|			OR ReplacementProductionPlan.Status = VALUE(Enum.PlanStatuses.AwaitingConfirmation)
		|				AND &Status = VALUE(Enum.PlanStatuses.Upholded))
		|	AND ReplacementProductionPlan.Date > &Date
		|	AND ReplacementProductionPlan.Department = &Department
		|	AND ReplacementProductionPlan.Purpose = &Purpose
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
		|		ON ReplacementPlans.SubstitutionPeriodStart <= TimeIntervals.Period
		|			AND ReplacementPlans.PeriodEnding >= TimeIntervals.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	&DateOfOrderReleaseAndProductionIssue AS Date,
		|	CASE &Periodicity
		|		WHEN VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, MONTH)
		|		WHEN VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(&DateOfOrderReleaseAndProductionIssue, YEAR)
		|		ELSE &DateOfOrderReleaseAndProductionIssue
		|	END AS Period,
		|	ManufacturedProduct.SemiFinishedProduct AS SemiFinishedProduct,
		|	ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct AS ReleaseDateOfProductsOrSemiFinishedProduct,
		|	CASE &Periodicity
		|		WHEN VALUE(Enum.Periodicity.WEEK)
		|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TENDAYS)
		|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.MONTH)
		|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, MONTH)
		|		WHEN VALUE(Enum.Periodicity.QUARTER)
		|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.YEAR)
		|			THEN BEGINOFPERIOD(ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct, YEAR)
		|		ELSE ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct
		|	END AS SemiFinishedProductProductionPeriod
		|INTO ManufacturedProduct
		|FROM
		|	&ManufacturedProduct AS ManufacturedProduct
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ManufacturedProduct.Date AS Date,
		|	ManufacturedProduct.Period AS Period,
		|	ManufacturedProduct.SemiFinishedProduct AS SemiFinishedProduct
		|INTO ProductsAssociation
		|FROM
		|	ManufacturedProduct AS ManufacturedProduct
		|WHERE
		|	NOT ManufacturedProduct.SemiFinishedProduct
		|
		|UNION ALL
		|
		|SELECT
		|	ManufacturedProduct.ReleaseDateOfProductsOrSemiFinishedProduct,
		|	ManufacturedProduct.SemiFinishedProductProductionPeriod,
		|	ManufacturedProduct.SemiFinishedProduct
		|FROM
		|	ManufacturedProduct AS ManufacturedProduct
		|WHERE
		|	ManufacturedProduct.SemiFinishedProduct
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductsAssociation.Date AS Date,
		|	MAX(PlanSubstitution.SubstitutedToOrder) AS SubstitutedToOrder,
		|	MAX(PlanSubstitution.Substituted) AS Substituted,
		|	ProductsAssociation.SemiFinishedProduct AS SemiFinishedProduct
		|FROM
		|	PlanSubstitution AS PlanSubstitution
		|		INNER JOIN ProductsAssociation AS ProductsAssociation
		|		ON PlanSubstitution.SubstitutedPeriod = ProductsAssociation.Period
		|
		|GROUP BY
		|	ProductsAssociation.Date,
		|	ProductsAssociation.SemiFinishedProduct
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
		
	ThisIsDisassembly = ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
	QueryText = StrReplace(QueryText,
		"&DateOfOrderReleaseAndProductionIssue",
		?(ThisIsDisassembly, "ManufacturedProduct.StartDate2", "ManufacturedProduct.DateOfProduction"));
	
	Query = New Query(QueryText);
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("StatusIndex", Enums.PlanStatuses.IndexOf(Status));
	Query.SetParameter("Status", Status);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Department", Department);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("SubstitutionPeriodStart", SubstitutionPeriodStart);
	Query.SetParameter("PeriodEnding", PeriodEnding);
	Query.SetParameter("TimeIntervals", TimeIntervals);
	Query.SetParameter("Periodicity", Periodicity);
	Query.SetParameter("ManufacturedProduct", ManufacturedProduct.Unload());
	
	RequestPackage = Query.ExecuteBatch();
	Selection = RequestPackage[5].Select();
	PlanReplacementTable = RequestPackage[6].Unload();
	
	For Each String In ManufacturedProduct Do
		String.Substituted = False;
		String.SubstitutedToOrder = False;
	EndDo;
	
	While Selection.Next() Do
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("SemiFinishedProduct", Selection.SemiFinishedProduct);
		
		If Selection.SemiFinishedProduct Then
			TheStructureOfTheSearch.Insert("ReleaseDateOfProductsOrSemiFinishedProduct", Selection.Date);
		Else
			TheStructureOfTheSearch.Insert(?(ThisIsDisassembly, "StartDate2", "DateOfProduction"), Selection.Date);
		EndIf;
		
		ReplacementLines = ManufacturedProduct.FindRows(TheStructureOfTheSearch);
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

Function ItIsRequiredToCalculateProductionPlan()
	
	Query = New Query(
	"SELECT
	|	TRUE
	|FROM
	|	Document.ProductionPlan AS ProductionPlan
	|		INNER JOIN Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|		ON ProductionPlan.Scenario = SalesOperationsPlanningScenarios.Ref
	|WHERE
	|	ProductionPlan.Ref = &Ref
	|	AND SalesOperationsPlanningScenarios.UseForMaterialsPlanning
	|
	|UNION ALL
	|
	|SELECT
	|	TRUE
	|FROM
	|	Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|WHERE
	|	SalesOperationsPlanningScenarios.Ref = &Scenario
	|	AND SalesOperationsPlanningScenarios.UseForMaterialsPlanning");
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Scenario", Scenario);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndIf
