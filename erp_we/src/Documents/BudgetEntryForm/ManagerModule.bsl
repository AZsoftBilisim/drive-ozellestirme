#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//  		registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Budgeting");
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.BudgetEntryForm") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableBudgetTurnovers(Query, QueryTexts, Registers);
		QueryTextTableLimitsByBudgetingData(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BudgetAdjustmentCommand = Documents.BudgetEntryForm.AddGenerateCommand(
		GenerationCommands);
	If BudgetAdjustmentCommand <> Undefined Then
		ArrayOfStatuses = New Array;
		ArrayOfStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
		ArrayOfStatuses.Add(Enums.PlanStatuses.Upholded);
		AttachableCommands.AddCommandVisibilityCondition(
			BudgetAdjustmentCommand,
			"Status",
			ArrayOfStatuses,
			DataCompositionComparisonType.InList);
	EndIf;
	
EndProcedure

// Adds a command to create a "Budget Instance" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.BudgetEntryForm) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.BudgetEntryForm.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Điều chỉnh ngân sách';
												|ru = 'Корректировка бюджета';
												|en = 'Budget adjustment'; fa = 'Budget adjustment';
												|it = 'Корректировка бюджета';
												|pl = 'Budget adjustment';
												|tr = 'Bütçeleme düzeltme'");
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Generates a verification request when changing the status of the list of documents.
//
// Parameters:
//	DocumentsArray - Array of DocumentRef.BudgetEntryForm - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PlanStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.BudgetEntryForm AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes.
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string.
//	NewStatus - EnumRef.PlanStatuses - new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the document
	
EndFunction

// Fills in a document based on saved budgeting data
// Updated PM of Operationsmetadata, Analitikacelebrated, Analyticaanacon.
//
// Parameters:
//	Object - DocumentObject.BudgetEntryForm - the document to change.
//
Procedure FillInBudgetAccordingToInformationBase(Object) Export
	Var Cancel, MessageText;
	
	Object.BudgetFlowItemsDimension.Clear();
	Object.BudgetFlowItemTurnovers.Clear();
	
	ScriptDetails = Common.ObjectAttributesValues(Object.Scenario,
		"Currency, RequireExchangeRatesSpecificationForEachPeriod");
	ScenarioCurrency = ScriptDetails.Currency;
	RequireExchangeRatesSpecificationForEachPeriod = ScriptDetails.RequireExchangeRatesSpecificationForEachPeriod;
	
	HeaderAnalystTable = Common.ObjectAttributeValue(Object.BudgetProfile, "HeaderDimensions.DimensionKind");
	HeaderDimensionList = New ValueList;
	HeaderDimensionList.LoadValues(HeaderAnalystTable.Unload().UnloadColumn("DimensionKind"));
	
	OutputParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(Object.BudgetProfile,
		Enums.ModesOfBudgetReportGeneration.FillType);
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.ObjectStructureForCellCalculation();
	ObjectAndCalculationParameters.Object = Object;
	ObjectAndCalculationParameters.ScenarioCurrency = ScenarioCurrency;
	ParametersStructure = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
		Object.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
	ItemParameterCache = BudgetingServer.FillCacheOfArticleParameters(ParametersStructure);
	ObjectAndCalculationParameters.ItemParameterCache = ItemParameterCache;
	ObjectAndCalculationParameters.RequireExchangeRatesSpecificationForEachPeriod = RequireExchangeRatesSpecificationForEachPeriod;
	ObjectAndCalculationParameters.BudgetProfileDisplayParameters = PutToTempStorage(OutputParameters);
	
	RateTable = BudgetReportingServerCall.RateTable(ObjectAndCalculationParameters,
			OutputParameters,
			Undefined,
			Cancel,
			MessageText);
	AddressOfExchangeRateTable = PutToTempStorage(RateTable);
	
	ObjectAndCalculationParameters.AddressOfExchangeRateTable = AddressOfExchangeRateTable;
	
	// filling in cells with autofill
	GenerationMode = Enums.ModesOfBudgetReportGeneration.FillType;
	If TypeOf(Object) = Type("Structure") Then
		ReportParameters = Object;
	Else
		ReportParameters = ParametersForDisplayingBudgetViewInTableDocument(Object,
			HeaderDimensionList,
			ScenarioCurrency,
			OutputParameters,
			GenerationMode);
	EndIf;
	
	BudgetInstanceData = BudgetReportingDisplayServer.BudgetInstanceData(ReportParameters);
	// When correcting a copy of the budget, the actual data of the budget itself is filled in
	If ReportParameters.Action = Enums.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm Then
		If TypeOf(ObjectAndCalculationParameters.Object) = Type("Structure") Then
			ObjectAndCalculationParameters.Object.BudgetFlowItemTurnovers = BudgetInstanceData.BudgetFlowItemTurnovers;
			ObjectAndCalculationParameters.Object.BudgetFlowItemsDimension = BudgetInstanceData.BudgetFlowItemsDimension;
		Else
			ObjectAndCalculationParameters.Object.BudgetFlowItemTurnovers.Load(
				BudgetInstanceData.BudgetFlowItemTurnovers);
			ObjectAndCalculationParameters.Object.BudgetFlowItemsDimension.Load(
				BudgetInstanceData.BudgetFlowItemsDimension);
		EndIf;
		Return;
	EndIf;
	CellData_ = BudgetInstanceData.CellData_;
	
	DataRows = CellData_.FindRows(New Structure("MainItem", True));
	
	Periodicity_ = OutputParameters.ColumnStructureOfDataTable.Periodicity_;
	DimensionKinds = OutputParameters.ColumnStructureOfDataTable.DimensionKinds;
	Dimensions = OutputParameters.ColumnStructureOfDataTable.Dimensions;
	CellParameters = OutputParameters.StructureOfReportDescription.CellParameters;
	
	PeriodParameters_ = BudgetReportingDisplayServer.ConvertDataParametersToPeriodData(
		OutputParameters.ColumnStructureOfDataTable, ReportParameters);
	
	CacheOfArticleDetails = New Map;
	
	CacheOfBudgetItemDetails = BudgetReportingCacheCalculationServer.CacheOfBudgetItemDetails(Object.BudgetProfile);
	
	OutputParameters.Insert("CacheOfBudgetItemDetails", CacheOfBudgetItemDetails);
	
	ParametersForCalculatingValue = BudgetReportingDisplayServer.TemplateForCellValueCalculationParameters();
	ParametersForCalculatingValue.CellData_ = CellData_;
	ParametersForCalculatingValue.CellParameters = CellParameters;
	ParametersForCalculatingValue.PeriodParameters_1 = PeriodParameters_;
	ParametersForCalculatingValue.CalculatingChanges = False;
	ParametersForCalculatingValue.CacheOfBudgetItemDetails = CacheOfBudgetItemDetails;
	
	ObjectAndCalculationParameters.Insert("CurCurrentNumberInOrder", 0);
	
	For Each DataString1 In DataRows Do
		
		CellParameters_ = CellParameters.Find(DataString1.RowIndex, "RowIndex");
		If CellParameters_.CalculationFilling <> "filltype"
			And CellParameters_.CalculationFilling <> "calculation" Then
			Continue;
		EndIf;
		
		Details = New Structure;
		Details.Insert("BudgetFlowItem", DataString1.BudgetFlowItem);
		Details.Insert("String", DataString1.String);
		
		For Each Periodicity In Periodicity_ Do
			FieldName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
			If ValueIsFilled(DataString1[FieldName]) Then
				Details.Insert(FieldName, DataString1[FieldName]);
			EndIf;
		EndDo;
		For Each Dimension In Dimensions Do
			If ValueIsFilled(DataString1[Dimension]) Then
				Details.Insert(Dimension, DataString1[Dimension]);
			EndIf;
		EndDo;
		
		AnalystValues = New Map;
		Details.Insert("AnalystValues", AnalystValues);
		For Each DimensionKind In DimensionKinds Do
			FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
				AnalystValues.Insert(DimensionKind, DataString1[FieldName]);
			If ValueIsFilled(DataString1[FieldName]) Then
				Details.Insert(FieldName, DataString1[FieldName]);
			EndIf;
		EndDo;
		
		WithdrawalCurrency = CurrencyForEnteringAnalytics(Details, CacheOfArticleDetails);
		If ValueIsFilled(WithdrawalCurrency) Then
			Details.Insert("Currency", WithdrawalCurrency);
		EndIf;
		
		If CellParameters_.FlagSum Then
			Details.Insert("IndicatorName", "Sum");
			
			ParametersForCalculatingValue.DataString1 = DataString1;
			ParametersForCalculatingValue.Prefix      = "Sum";
			Value = BudgetReportingDisplayServer.CalculateCellValue(ParametersForCalculatingValue);
			
			If TypeOf(Value) = Type("Number") Then
				Value = Value * ?(CellParameters_.ReverseSign, -1, 1);
			EndIf;
			
			ReflectionResult = BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Details, Value,,True);
			
			SettlementDetails = Common.CopyRecursive(Details);
			SettlementDetails.Delete("AnalystValues");
			SettlementDetails.Delete("Currency");
			ExecutionResult = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(OutputParameters,
				CellData_,
				ReportParameters,
				SettlementDetails,
				ReflectionResult);
			If ExecutionResult <> Undefined Then
				For Each Update In ExecutionResult.Result Do
					Value = ?(ValueIsFilled(Update.Value), Update.Value, Undefined);
					BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters,
							Update.Details,
							Value,,
							True);
				EndDo;
			EndIf;
		EndIf;
		
		If CellParameters_.FlagCount Then
			Details.Insert("IndicatorName", "Count");
			
			ParametersForCalculatingValue.DataString1 = DataString1;
			ParametersForCalculatingValue.Prefix      = "Count";
			Value = BudgetReportingDisplayServer.CalculateCellValue(ParametersForCalculatingValue);
			
			If TypeOf(Value) = Type("Number") Then
				Value = Value * ?(CellParameters_.ReverseSign, -1, 1);
			EndIf;
			
			ReflectionResult = BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters,
					Details,
					Value,,
					True);
			
			SettlementDetails = Common.CopyRecursive(Details);
			SettlementDetails.Delete("AnalystValues");
			ExecutionResult = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(OutputParameters,
				CellData_,
				ReportParameters,
				SettlementDetails,
				ReflectionResult);
			If ExecutionResult <> Undefined Then
				For Each Update In ExecutionResult.Result Do
					Value = ?(ValueIsFilled(Update.Value), Update.Value, Undefined);
					BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters,
							Update.Details,
							Value,,
							True);
				EndDo;
			EndIf;
		EndIf;
		
	EndDo;
	
	ObjectAndCalculationParameters.Delete("CurCurrentNumberInOrder");
	
EndProcedure

// Recalculates the associated cells of the budget instance.
//
// Parameters:
//	Object - DocumentObject.BudgetEntryForm - the document to change.
//
Procedure RecalculateRelatedBudgetInstanceCells(Object) Export
	
	ScriptDetails = Common.ObjectAttributesValues(Object.Scenario,
		"Currency, RequireExchangeRatesSpecificationForEachPeriod");
	ScenarioCurrency = ScriptDetails.Currency;
	RequireExchangeRatesSpecificationForEachPeriod = ScriptDetails.RequireExchangeRatesSpecificationForEachPeriod;
	
	HeaderAnalystTable = Common.ObjectAttributeValue(Object.BudgetProfile, "HeaderDimensions.DimensionKind");
	HeaderDimensionList = New ValueList;
	HeaderDimensionList.LoadValues(HeaderAnalystTable.Unload().UnloadColumn("DimensionKind"));
	
	OutputParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(Object.BudgetProfile,
		Enums.ModesOfBudgetReportGeneration.Document);
	
	ObjectAndCalculationParameters = BudgetReportingClientServer.ObjectStructureForCellCalculation();
	ObjectAndCalculationParameters.Object = Object;
	ObjectAndCalculationParameters.ScenarioCurrency = ScenarioCurrency;
	ParametersStructure = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
		Object.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
	ItemParameterCache = BudgetingServer.FillCacheOfArticleParameters(ParametersStructure);
	ObjectAndCalculationParameters.ItemParameterCache = ItemParameterCache;
	ObjectAndCalculationParameters.RequireExchangeRatesSpecificationForEachPeriod = RequireExchangeRatesSpecificationForEachPeriod;
	ObjectAndCalculationParameters.BudgetProfileDisplayParameters = PutToTempStorage(OutputParameters);
	
	// filling in cells with autofill
	GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	ReportParameters = ParametersForDisplayingBudgetViewInTableDocument(Object,
			HeaderDimensionList,
			ScenarioCurrency,
			OutputParameters,
			GenerationMode);
	ReportParameters.Insert("ItemParameterCache", ItemParameterCache);
	
	BudgetInstanceData = BudgetReportingDisplayServer.BudgetInstanceData(ReportParameters);
	CellData_ = BudgetInstanceData.CellData_;
	
	If Not CellData_ = Undefined Then
		ExecutionResult = BudgetReportingDisplayServer.CalculateRelatedBudgetItems(
			OutputParameters,
			CellData_,
			ReportParameters,
			Undefined,
			Undefined,
			True);
		
		If ExecutionResult <> Undefined Then
			For Each Update In ExecutionResult.Result Do
				Value = ?(ValueIsFilled(Update.Value), Update.Value, Undefined);
				BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Update.Details, Value);
			EndDo;
		EndIf;
		
		ReportParameters.Insert("CellData_", CellData_);
		ExecutionResult = BudgetReportingDisplayServer.BudgetInstanceChanges(ReportParameters);
		
		If ExecutionResult <> Undefined Then
			For Each Update In ExecutionResult.Result Do
				Value = ?(ValueIsFilled(Update.Value), Update.Value, Undefined);
				BudgetReportingClientServer.ReflectCellChange(ObjectAndCalculationParameters, Update.Details, Value);
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

// Prepares parameters required for creating a budget in tabular form
//
// Parameters:
//	Object - DocumentObject.BudgetEntryForm - instance for which a table document is generated
//	HeaderDimensionList - ValueList of ChartOfCharacteristicTypesRef.BudgetFlowItemDimensions
//	ScenarioCurrency - CatalogRef.Currencies -
//	BudgetProfileDisplayParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
//	GenerationMode - EnumRef.ModesOfBudgetReportGeneration -
//	CellData_ - ValueTable, Undefined - (optional)
//
// Returns:
//	Structure - parameter structure:
//	*Organization - CatalogRef.Companies - This property exists only if the enter plan for organizations flag is set in the budget model.
//	*Department - CatalogRef.BusinessStructure - This property exists only if the enter plan by division flag is set in the budget model.
//	*Currency - CatalogRef.Currencies -
//	*Scenario - CatalogRef.BudgetingScenarios -
//	*Document - DocumentRef.BudgetEntryForm -
//	*BudgetFlowItemsDimension - ValueTable -
//	*BudgetFlowItemTurnovers - ValueTable -
//	*DimensionValues_ - ValueTable -
//	*UpdateDate - Date -
//	*QueryTextDocumentTables - String -
//	*ReportCurrency - CatalogRef.Currencies -
//	*ScenarioCurrency - CatalogRef.Currencies -
//	*MaximumNumberInOrder - Number -
//	*Status - ValueList of EnumRef.PlanStatuses -
//	*BudgetProfile - CatalogRef.BudgetProfiles -
//	*BudgetProfileDisplayParameters - See BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView
//	*CellData_ - ValueTable, Undefined -
//	*AdditionalFiltersForAnalytics - Structure -
//	*UseToEnterPlan - Boolean - True if redefined during formation.
//	*GenerationMode - EnumRef.ModesOfBudgetReportGeneration - output to a report, output to a document, fill in a document, and print a budget.
//	*ShowItemHierarchy - Boolean - True if you display a hierarchy of analytics values.
//	*ConsiderAdditionalSelectionByHierarchy - Boolean - True if you take into account the selection of analytics values by hierarchy.
//
Function ParametersForDisplayingBudgetViewInTableDocument(Object,
													HeaderDimensionList,
													ScenarioCurrency,
													BudgetProfileDisplayParameters,
													GenerationMode,
													CellData_ = Undefined) Export
	
	DataParameters = New Structure;
	If GetFunctionalOption("GenerateBudgetsByCompanies",
			New Structure("BudgetingModel", Object.BudgetingModel)) Then
		DataParameters.Insert("Organization", Object.Organization);
	EndIf;
	If GetFunctionalOption("GenerateBudgetsByBusinessUnits",
			New Structure("BudgetingModel", Object.BudgetingModel)) Then
		DataParameters.Insert("Department", Object.Department);
	EndIf;
	DataParameters.Insert("Currency",      ScenarioCurrency);
	DataParameters.Insert("Scenario",    Object.Scenario);
	DataParameters.Insert("Document",    Object.Ref);
	DataParameters.Insert("Action", Object.Action);
	DataParameters.Insert("BudgetFlowItemsDimension", Object.BudgetFlowItemsDimension.Unload());
	DataParameters.Insert("BudgetFlowItemTurnovers", Object.BudgetFlowItemTurnovers.Unload());
	DataParameters.Insert("DimensionValues_", Object.DimensionValues_.Unload());
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TMCommonUse.RequestTextObjectTSData(Object.Ref, "BudgetFlowItemsDimension",
		False, "RowID"));
	QueriesTexts.Add(TMCommonUse.RequestTextObjectTSData(Object.Ref, "BudgetFlowItemTurnovers",
		False, "RowID"));
	QueriesTexts.Add(TMCommonUse.RequestTextObjectTSData(Object.Ref, "DimensionValues_",
		False, "RowID"));
	DataParameters.Insert("QueryTextDocumentTables", StrConcat(QueriesTexts,
		Common.QueryBatchSeparator()));
	
	If TypeOf(Object) = Type("QueryResultSelection") Then
		DataParameters.Insert("UpdateDate", EndOfDay(Object.DocumentDate));
	Else
		DataParameters.Insert("UpdateDate", EndOfDay(?(ValueIsFilled(Object.Ref), Object.Date,
			CurrentSessionDate())));
	EndIf;
	DataParameters.Insert("ReportCurrency", ScenarioCurrency);
	DataParameters.Insert("ScenarioCurrency", ScenarioCurrency);
	MaxNumber = 0;
	For Each RowOfRevolutions In DataParameters.BudgetFlowItemTurnovers Do
		MaxNumber = Max(RowOfRevolutions.SerialNumber, MaxNumber);
	EndDo;
	DataParameters.Insert("MaximumNumberInOrder", MaxNumber);
	
	DataStatuses = New ValueList;
	DataStatuses.Add(Enums.PlanStatuses.Upholded);
	DataStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
	DataStatuses.Add(Enums.PlanStatuses.UnderPreparation);
	DataParameters.Insert("Status", DataStatuses);
	
	DataParameters.Insert("BudgetProfile", Object.BudgetProfile);
	
	DataParameters.Insert("BudgetProfileDisplayParameters", BudgetProfileDisplayParameters);
	
	DataParameters.Insert("CellData_", CellData_);
	
	BudgetReportingClientServer.PeriodParameters_(Object, DataParameters);
	
	AdditionalFiltersForAnalytics = New Structure;
	For Each DimensionKind In HeaderDimensionList Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind.Value);
		AdditionalFiltersForAnalytics.Insert(FieldName);
		DataParameters.Insert(FieldName, Object["Dimension" + (HeaderDimensionList.IndexOf(DimensionKind) + 1)]);
	EndDo;
	
	DataParameters.Insert("AdditionalFiltersForAnalytics", AdditionalFiltersForAnalytics);
	
	DataParameters.Insert("UseToEnterPlan", True);
	DataParameters.Insert("GenerationMode", GenerationMode);
	
	DataParameters.Insert("ShowItemHierarchy", True);
	DataParameters.Insert("ConsiderAdditionalSelectionByHierarchy", False);
	
	Return DataParameters;
	
EndFunction

Function BudgetInstanceDataWithTabularParts(BudgetParameters) Export
	
	FillInBudgetAccordingToInformationBase(BudgetParameters);
	
	BudgetParameters.GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	BudgetParameters.ConsiderAdditionalSelectionByHierarchy = True;
	
	CalculationResult2 = BudgetReportingDisplayServer.BudgetInstanceData(BudgetParameters);
	CalculationResult2.Insert("BudgetFlowItemsDimension", BudgetParameters.BudgetFlowItemsDimension);
	CalculationResult2.Insert("BudgetFlowItemTurnovers", BudgetParameters.BudgetFlowItemTurnovers);
	CalculationResult2.Insert("DimensionValues_", BudgetParameters.DimensionValues_);
	
	Return CalculationResult2;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN Catalog.BudgetProfiles.ItemAndIndicatorCache AS T1 
	|	ON T.BudgetProfile = T1.Ref AND T1.PrivilegedMode = FALSE
	|;
	|AllowReadUpdate
	|WHERE
	|	ForAllRows( ValueAllowed(T1.ItemIndicator, NULL AS TRUE)
	|	) AND ValueAllowed(T.Organization)
	|	AND ValueAllowed(T.Department)
	|	AND ValueAllowed(T.Scenario)
	|	AND ValueAllowed(T.BudgetProfile)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// Returns the values of the Company, default Business Unit dimensions for the budgeting model and the user
//
// Parameters:
//  BudgetingModel - CatalogRef.BudgetingModels - budgeting model
//  EmployeeResponsible - CatalogRef.Users - user.
//
// Returns:
//  Structure - parameter structure:
//   *Organization - CatalogRef.Companies - Default company
//   *Department - CatalogRef.BusinessStructure - default division
//
Function DefaultBudgetMeasurements(BudgetingModel, EmployeeResponsible) Export
	
	Dimensions = New Structure;
	If Not ValueIsFilled(BudgetingModel) Then
		Return Dimensions;
	EndIf;
	
	BudgetingModelData = Common.ObjectAttributesValues(BudgetingModel, "BudgetsByCompanies, BudgetsByBusinessUnits");
	
	AttributesNames = New Array;
	If BudgetingModelData.BudgetsByCompanies Then
		AttributesNames.Add("Organization");
	EndIf;
	If BudgetingModelData.BudgetsByBusinessUnits Then
		AttributesNames.Add("Department");
	EndIf;
	
	If AttributesNames.Count() > 0 Then
		
		AttributesDetails1 = New Structure;
		Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
		Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "BudgetingModel,EmployeeResponsible";
		DetailsForSelection = New Structure("BudgetingModel,EmployeeResponsible", BudgetingModel, EmployeeResponsible);
		ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization, Department", Parameters);
		Dimensions = ObjectsFillingByStatistics.GetBankingDetailsValues(
			Documents.BudgetEntryForm.EmptyRef(), AttributesDetails1, DetailsForSelection);
		
	EndIf;
	
	Return Dimensions;
	
EndFunction

// The procedure generates data for the contextual report "Budget adjustments and corrections"
//
// Parameters:
//  BudgetParameters - Structure
//  StorageAddress - String
//
Procedure GetDataOnBudgetAdjustmentsCorrections(BudgetParameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.BudgetEntryForm.ManagerModule.GetDataOnBudgetAdjustmentsCorrections");
	
	ResultDocument = New SpreadsheetDocument;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DetailsData = New DataCompositionDetailsData;
	CompositionTemplate = TemplateComposer.Execute(BudgetParameters.DataCompositionSchema,
		BudgetParameters.DataCompositionSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	BudgetData = New Structure("ResultDocument, DetailsData");
	BudgetData.ResultDocument = ResultDocument;
	BudgetData.DetailsData = DetailsData;
	
	PutToTempStorage(BudgetData, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Int(ResultDocument.TableHeight
		/ 100)); // The specific calculation time is 100 lines, to reduce the error
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Printing the budget.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PrintBudget";
	PrintCommand.Presentation = NStr("vi = 'In ngân sách';
									|ru = 'Печать бюджета';
									|en = 'Print budget'; fa = 'چاپ بودجه';
									|it = 'Stampa del budget';
									|pl = 'Wydruk budżetu';
									|tr = 'Bütçeyi yazdır'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Printing the budget as a list.
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PrintBudgetAsAList";
	PrintCommand.Presentation = NStr("vi = 'In danh sách ngân sách';
									|ru = 'Печать бюджета списком';
									|en = 'Print budget as a list'; fa = 'Print budget as a list';
									|it = 'Stampa del budget in forma dell''elenco';
									|pl = 'Wydruk budżetu w formie listy';
									|tr = 'Bütçeyi liste olarak yazdır'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PrintBudget") Then
		SpreadsheetDocument = CreatePrintedBudgetForm(ObjectsArray, PrintObjects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"PrintBudget",
			NStr("vi = 'In ngân sách';
				|ru = 'Печать бюджета';
				|en = 'Print budget'; fa = 'چاپ بودجه';
				|it = 'Stampa del budget';
				|pl = 'Wydruk budżetu';
				|tr = 'Bütçeyi yazdır'"),
			SpreadsheetDocument);
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PrintBudgetAsAList") Then
		SpreadsheetDocument = CreatePrintedBudgetFormAsList(ObjectsArray, PrintObjects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PrintBudgetAsAList",
			NStr("vi = 'In danh sách ngân sách';
				|ru = 'Печать бюджета списком';
				|en = 'Print budget as a list'; fa = 'Print budget as a list';
				|it = 'Stampa del budget in forma dell''elenco';
				|pl = 'Wydruk budżetu w formie listy';
				|tr = 'Bütçeyi liste olarak yazdır'"),
			SpreadsheetDocument);
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreatePrintedBudgetForm(ObjectsArray, PrintObjects)
	
	Result = New SpreadsheetDocument;
	Result.FitToPage = True;
	Result.PrintParametersKey = "PRINT_OPTIONS_PrintBudget";
	
	Query = GetRequestForReportOutputData(ObjectsArray);
	
	SelectionOfDocuments = Query.Execute().Select();
	
	While SelectionOfDocuments.Next() Do
		
		HeaderDimensionList = New ValueList;
		HeaderDimensionList.LoadValues(SelectionOfDocuments.HeaderDimensions.Unload().UnloadColumn("DimensionKind"));
		
		GenerationMode = Enums.ModesOfBudgetReportGeneration.PrintBudget;
		
		BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
			SelectionOfDocuments.BudgetProfile, GenerationMode);
			
		ReportParameters = ParametersForDisplayingBudgetViewInTableDocument(SelectionOfDocuments,
			HeaderDimensionList,
			SelectionOfDocuments.ScenarioCurrency,
			BudgetProfileDisplayParameters,
			GenerationMode);
		
		BudgetReport = BudgetReportingDisplayServer.BudgetInstanceData(ReportParameters);
		
		Result.Put(BudgetReport.Result);
		Result.PutHorizontalPageBreak();
		
		//@skip-check query-in-loop
		AnalyticalNote = FormPrintedFormOfAnalyticalNote(ReportParameters,
			BudgetProfileDisplayParameters.ColumnStructureOfDataTable,
			BudgetReport.Remarks);
		
		If AnalyticalNote <> Undefined Then
			Result.Put(AnalyticalNote);
			Result.PutHorizontalPageBreak();
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function FormPrintedFormOfAnalyticalNote(ReportParameters, ColumnStructureOfDataTable, Remarks)
	
	Result = New SpreadsheetDocument;
	
	If Remarks = Undefined Then
		Return Undefined;
	EndIf;
	
	DataTable = Remarks.DataTable;
	
	If Not DataTable.Count() Then
		Return Undefined;
	EndIf;
	
	// To get in the report the groupings by budget items in ascending order of the table number and the number of the note.
	DataTable.Sort("TableNumber, NoteNumber");
	BudgetFlowItems = DataTable.UnloadColumn("BudgetFlowItem");
	BudgetFlowItems = CommonClientServer.CollapseArray(BudgetFlowItems);
	
	Query = New Query;
	QueryText = "SELECT
		|	BudgetFlowItems.Ref AS Ref,
		|	BudgetFlowItems.Ref.Presentation AS Presentation,
		|	BudgetFlowItems.NumberOfUsedDimensions AS NumberOfAnalysts,
		|	&TextAnalyst_1,
		|	&TextPresentationOfTypesOfAnalytics,
		|	BudgetFlowItems.RecordByCurrency AS RecordByCurrency,
		|	BudgetFlowItems.RecordByQuantity AS RecordByQuantity
		|FROM
		|	Catalog.BudgetFlowItems AS BudgetFlowItems
		|WHERE
		|	BudgetFlowItems.Ref IN(&BudgetFlowItems)
		|
		|ORDER BY
		|	Presentation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BudgetEntryForm.EmployeeResponsible.Presentation AS Presentation
		|FROM
		|	Document.BudgetEntryForm AS BudgetEntryForm
		|WHERE
		|	BudgetEntryForm.Ref = &BudgetInstanceLink";
		
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	TextAnalyst_1 = "";
	TextPresentationOfTypesOfAnalytics = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst_1 = TextAnalyst_1
			+ ?(TextAnalyst_1 = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItems.DimensionKind%1 AS DimensionKind%1",
				DimensionNumber);
		
		TextPresentationOfTypesOfAnalytics = TextPresentationOfTypesOfAnalytics
			+ ?(TextPresentationOfTypesOfAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItems.DimensionKind%1.Presentation AS AnalyticsPresentation%1",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalyst_1", TextAnalyst_1);
	QueryText = StrReplace(QueryText, "&TextPresentationOfTypesOfAnalytics", TextPresentationOfTypesOfAnalytics);
	Query.Text = QueryText;
	
	Query.SetParameter("BudgetFlowItems", BudgetFlowItems);
	Query.SetParameter("BudgetInstanceLink", ReportParameters.Document);
	
	QueryResult  = Query.ExecuteBatch();
	QueryResult0 = QueryResult[0]; // QueryResult
	QueryResult1 = QueryResult[1]; // QueryResult
	
	SelectionOfBudgetItems = QueryResult0.Select();
	
	FinReports = FinancialReportingServer;
	
	DCS = Documents.BudgetEntryForm.GetTemplate("DataCompositionSchemaOfAnAnalyticalSheet");
	Settings = DCS.DefaultSettings;
	
	ReportHeader = NStr("vi = 'Tóm tắt ngân sách';
						|ru = 'Аналитическая записка к бюджету';
						|en = 'Analytical note to the budget'; fa = 'Analytical note to the budget';
						|it = 'Nota integrativa al budget';
						|pl = 'Notatka anlityczna do budżetu';
						|tr = 'Bütçeye boyutsal not'") + Chars.LF + """%1""%2";
	ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(ReportHeader, ReportParameters.BudgetProfile,
		TMReportFunctionsClientServer.GetPeriodPresentation(ReportParameters.BeginOfPeriod, ReportParameters.EndOfPeriod));
	
	FinReports.SetParameter(Settings.OutputParameters, "Title", ReportHeader);
	
	// Period.
	Periodicity_ = ColumnStructureOfDataTable.Periodicity_;
	
	If Periodicity_.Count() Then
		
		OrderedPeriodicities = Enums.Periodicity.OrderedPeriodicities();
		
		FieldExpression = "CASE ";  //@Query-part
		
		For Each FollowingPeriodicity In OrderedPeriodicities Do
			
			If Periodicity_.Find(FollowingPeriodicity) = Undefined Then
				Continue;
			EndIf;
			
			SetFieldName = FinancialReportingClientServer.PeriodStrings(FollowingPeriodicity).Period;
			
			FinReports.NewSetField(DCS.DataSets[0], SetFieldName);
			
			FieldExpression = FieldExpression + "
				|	WHEN ValueIsFilled(" + SetFieldName + ")
				|		THEN " + SetFieldName + "
				|";
				
		EndDo;
			
		FieldExpression = FieldExpression + "
			|	ELSE &BeginOfPeriod
			|END";
			
	Else
		
		FieldExpression = "&BeginOfPeriod";
		
	EndIf;
	
	FieldToEval = FinReports.NewCalculatedField(DCS, "Period", FieldExpression);
	FieldToEval.ValueType = New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date));
	FinReports.SetParameter(FieldToEval.Appearance, "Format","DLF=D" );
	FinReports.NewOrder(Settings, "Period");
	
	FinReports.SetParameter(Settings.DataParameters, "BeginOfPeriod", ReportParameters.BeginOfPeriod, True);
	
	// Analysts.
	DimensionKinds = ColumnStructureOfDataTable.DimensionKinds;
	
	For Each DimensionKind In DimensionKinds Do
		SetField = FinReports.NewSetField(DCS.DataSets[0],
				FinancialReportingCached.NameOfBudgetReportField(DimensionKind));
		FinReports.SetParameter(SetField.Appearance, "MinimumWidth", 30);
		FinReports.SetParameter(SetField.Appearance, "MaxWidth", 30);
	EndDo;
	
	ItemsRecordByCurrency = New Array;
	
	// The order of budget items will correspond to the increasing number of the table and the number of the note.
	For Each BudgetFlowItem In BudgetFlowItems Do
		
		SelectionOfBudgetItems.FindNext(BudgetFlowItem, "Ref");
		
		GroupingByBudgetItem = FinReports.NewGrouping(Settings.Structure); // DataCompositionGroup -
		GroupingByBudgetItem.Selection.Items.Clear();
		
		GroupingByBudgetItem.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
		
		FinReports.NewFilter(GroupingByBudgetItem.Filter, "BudgetFlowItem", SelectionOfBudgetItems.Ref);
		
		Presentation = NStr("vi = 'Khoản mục ngân sách ""%1""';
							|ru = 'Статья бюджета ""%1""';
							|en = 'Budget flow item ""%1""'; fa = 'Budget flow item ""%1""';
							|it = 'Voce di bilancio ""%1""';
							|pl = 'Pozycja budżetu ""%1""';
							|tr = '""%1"" bütçe kalemi'");
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			Presentation,
			SelectionOfBudgetItems.Presentation);
		FinReports.SetParameter(GroupingByBudgetItem.OutputParameters, "Title", Presentation);
		FinReports.SetParameter(GroupingByBudgetItem.OutputParameters, "FilterOutput", DataCompositionTextOutputType.DontOutput);
		
		Presentation = NStr("vi = 'N';
							|ru = 'N';
							|en = 'N'; fa = 'ش';
							|it = 'N';
							|pl = 'N';
							|tr = 'N'");
		FinReports.NewSelectionField(GroupingByBudgetItem, "Address", Presentation);
		
		Presentation = NStr("vi = 'Kỳ';
							|ru = 'Период';
							|en = 'Period'; fa = 'دوره';
							|it = 'Periodo';
							|pl = 'Okres';
							|tr = 'Dönem'");
		FinReports.NewSelectionField(GroupingByBudgetItem, "Period", Presentation);
		
		For DimensionNumber = 1 To SelectionOfBudgetItems.NumberOfAnalysts Do
			DimensionKind = SelectionOfBudgetItems["DimensionKind"+DimensionNumber];
			NameOfAnalytics = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
			If DimensionKinds.Find(DimensionKind) <> Undefined Then
				AnalyticsPresentation = SelectionOfBudgetItems["AnalyticsPresentation"+DimensionNumber];
				FinReports.NewSelectionField(GroupingByBudgetItem, NameOfAnalytics, AnalyticsPresentation);
			EndIf;
		EndDo;
		
		If SelectionOfBudgetItems.RecordByQuantity Then
			Presentation = NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'");
			FinReports.NewSelectionField(GroupingByBudgetItem, "Count", Presentation);
		EndIf;
		
		Presentation = NStr("vi = 'Tổng số';
							|ru = 'Сумма';
							|en = 'Amount'; fa = 'مبلغ';
							|it = 'Importo';
							|pl = 'Wartość';
							|tr = 'Tutar'");
		FinReports.NewSelectionField(GroupingByBudgetItem, "ReportAmount", Presentation);
		
		If SelectionOfBudgetItems.RecordByCurrency Then
			Presentation = NStr("vi = 'Tiền tệ';
								|ru = 'Валюта';
								|en = 'Currency'; fa = 'ارز';
								|it = 'Valuta';
								|pl = 'Waluta';
								|tr = 'Para birimi'");
			FinReports.NewSelectionField(GroupingByBudgetItem, "Currency", Presentation);
			ItemsRecordByCurrency.Add(BudgetFlowItem);
		EndIf;
		
		Presentation = NStr("vi = 'Ghi chú';
							|ru = 'Примечание';
							|en = 'Note'; fa = 'یادداشت';
							|it = 'Nota';
							|pl = 'Adnotacja';
							|tr = 'Not'");
		FinReports.NewSelectionField(GroupingByBudgetItem, "Note", Presentation);
		
		SelectionOfBudgetItems.Reset();
		
	EndDo;
	
	FinReports.SetParameter(Settings.DataParameters, "ItemsRecordByCurrency", ItemsRecordByCurrency);
	
	SamplingResponsible = QueryResult1.Select();
	EmployeeResponsiblePresentation = ?(SamplingResponsible.Next(), SamplingResponsible.Presentation, "");
	
	FinReports.SetParameter(Settings.DataParameters, "EmployeeResponsiblePresentation", EmployeeResponsiblePresentation);
	
	GroupingByBudgetItem = FinReports.NewGrouping(Settings.Structure); // DataCompositionGroup -
	GroupingByBudgetItem.Name = "EmployeeResponsiblePresentation";
	GroupingByBudgetItem.Selection.Items.Clear();
	
	// Layout.
	ExternalSources = New Structure("DataTable", DataTable);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	LayoutTemplateParameter = Settings.OutputParameters.Items.Find("AppearanceTemplate");
	LayoutTemplateParameter.Value = "ReportingBeige";
	LayoutTemplateParameter.Use = True;
	
	CompositionTemplate = TemplateComposer.Execute(DCS, Settings);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalSources);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(Result);
	
	OutputProcessor.Output(DataCompositionProcessor);
	
	Result.FitToPage = True;
	
	Return Result;
	
EndFunction

Function CreatePrintedBudgetFormAsList(ObjectsArray, PrintObjects)
	
	Result = New SpreadsheetDocument;
	Result.FitToPage = True;
	Result.PrintParametersKey = "PRINT_OPTIONS_PrintBudgetAsAList";
	
	Query = GetRequestForReportOutputData(ObjectsArray);
	
	SelectionOfDocuments = Query.Execute().Select();
	
	While SelectionOfDocuments.Next() Do
		
		HeaderDimensionList = New ValueList;
		HeaderDimensionList.LoadValues(SelectionOfDocuments.HeaderDimensions.Unload().UnloadColumn("DimensionKind"));
		
		BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
			SelectionOfDocuments.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
		
		GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
		ReportParameters = ParametersForDisplayingBudgetViewInTableDocument(SelectionOfDocuments,
			HeaderDimensionList,
			SelectionOfDocuments.ScenarioCurrency,
			BudgetProfileDisplayParameters,
			GenerationMode);
		ReportParameters.ShowItemHierarchy = False;
		
		BudgetReport = BudgetReportingDisplayServer.BudgetInstanceData(ReportParameters);
		
		ReportHeader = NStr("vi = '%1 trong kỳ từ %2 đến %3';
							|ru = '%1 за период с %2 по %3';
							|en = '%1 for the period from %2 to %3'; fa = '%1 for the period from %2 to %3';
							|it = '%1 per il periodo dal %2 al %3';
							|pl = '%1 na okres od %2 do %3';
							|tr = '%1 %2 tarihinden %3 tarihine kadarki dönemi için'");
		ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(ReportHeader,
			SelectionOfDocuments.BudgetProfile,
			Format(SelectionOfDocuments.BeginOfPeriod, "DLF=D"),
			Format(SelectionOfDocuments.PeriodEnding, "DLF=D"));
		
		TitleResponsible = NStr("vi = 'Chịu trách nhiệm: %1';
								|ru = 'Ответственный: %1';
								|en = 'Person responsible: %1'; fa = 'Person responsible: %1';
								|it = 'Responsabile: %1';
								|pl = 'Odpowiedzialny: %1';
								|tr = 'Sorumlu: %1'");
		TitleResponsible = StringFunctionsClientServer.SubstituteParametersToString(TitleResponsible,
			SelectionOfDocuments.EmployeeResponsible);
		
		BudgetReport.BudgetProfileDisplayParameters.Insert("ReportHeader", ReportHeader);
		BudgetReport.BudgetProfileDisplayParameters.Insert("TitleResponsible", TitleResponsible);
		
		BudgetItemTree = BudgetReport.TreeOfEditListRows;
		
		If BudgetItemTree <> Undefined Then
			
			For Each BudgetTreeLine In BudgetItemTree.Rows Do
			
				ParametersList	= BudgetReport.BudgetProfileDisplayParameters.InputListDescriptionStructure;
				ColumnsByDimension = Undefined;
				If Not CompositionOfRootElementColumns(BudgetTreeLine, ParametersList, ColumnsByDimension) Then
					Continue;
				EndIf;
				
				TableID = BudgetTreeLine.TableID;
				TreeDepth = Undefined;
				//@skip-check query-in-loop
				AnalystPresentationsOther = GetAnalystOtherPresentations(ColumnsByDimension.BaseLines);
				DataCompositionSchema = GetDCSForPrintingDocumentWithoutDimensions(TableID,
					ColumnsByDimension,
					TreeDepth,
					BudgetReport.BudgetProfileDisplayParameters,
					AnalystPresentationsOther,
					True); // DataCompositionSchema -
				
				// Output of the layout result to the report.
				
				Settings = DataCompositionSchema.DefaultSettings;
				DetailsData = New DataCompositionDetailsData;
				TemplateComposer = New DataCompositionTemplateComposer;
				
				LayoutTemplateParameter = Settings.OutputParameters.Items.Find("AppearanceTemplate");
				LayoutTemplateParameter.Value = "ReportingBeige";
				LayoutTemplateParameter.Use = True;
			
				CompositionTemplate = TemplateComposer.Execute(
					DataCompositionSchema, Settings, DetailsData);
				
				ExternalData = New Structure("CellData_", BudgetReport.CellData_);
				StructureOfReportDescription = BudgetReport.BudgetProfileDisplayParameters.StructureOfReportDescription;
				ExternalData.Insert("CellParameters", StructureOfReportDescription.CellParameters);
				
				DataCompositionProcessor = New DataCompositionProcessor;
				DataCompositionProcessor.Initialize(
					CompositionTemplate, ExternalData, DetailsData);
				
				SpreadsheetDocument = New SpreadsheetDocument;
				
				// We output the result in a tabular document.
				OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
				OutputProcessor.SetDocument(SpreadsheetDocument);
				
				OutputProcessor.Output(DataCompositionProcessor);
				
				Result.Put(SpreadsheetDocument);
				If SpreadsheetDocument.PageHeight Then
					BudgetReport.BudgetProfileDisplayParameters.ReportHeader = "";
					BudgetReport.BudgetProfileDisplayParameters.TitleResponsible = "";
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function GenerateTabularBudgetInstanceDocument(DocumentRef) Export
	
	Query = GetRequestForReportOutputData(DocumentRef);
	
	SelectionOfDocuments = Query.Execute().Select();
	SelectionOfDocuments.Next();
	
	If Not ValueIsFilled(SelectionOfDocuments.BudgetProfile)
		Or Not ValueIsFilled(SelectionOfDocuments.Scenario)
		Or Not ValueIsFilled(SelectionOfDocuments.BeginOfPeriod)
		Or Not ValueIsFilled(SelectionOfDocuments.PeriodEnding) Then
		Return New SpreadsheetDocument;
	EndIf;
	
	HeaderDimensionList = New ValueList;
	HeaderDimensionList.LoadValues(SelectionOfDocuments.HeaderDimensions.Unload().UnloadColumn("DimensionKind"));
	
	BudgetProfileDisplayParameters = BudgetReportingCacheCalculationServer.GetParametersForDisplayingBudgetView(
		SelectionOfDocuments.BudgetProfile, Enums.ModesOfBudgetReportGeneration.Document);
	
	GenerationMode = Enums.ModesOfBudgetReportGeneration.Document;
	ReportParameters = ParametersForDisplayingBudgetViewInTableDocument(SelectionOfDocuments,
		HeaderDimensionList,
		SelectionOfDocuments.ScenarioCurrency,
		BudgetProfileDisplayParameters,
		GenerationMode);
	
	BudgetReport = BudgetReportingDisplayServer.BudgetInstanceData(ReportParameters);
	
	Return BudgetReport.Result;

EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Action");
	Fields.Add("BudgetProfile");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	Data.Insert("DocumentName3", TrimAll(Data.Action));
	Data.Insert("NameOfBudget", TrimAll(Data.BudgetProfile));
	Data.Delete("Action");
	Data.Delete("BudgetProfile");
	
	StandardProcessing = False;
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2 %3 ngày %4';
				|ru = '%1 %2 %3 от %4';
				|en = '%1 %2 %3 dated %4'; fa = '%1 %2 %3 dated %4';
				|it = '%1 %2 %3 dated %4';
				|pl = '%1 %2 %3 dated %4';
				|tr = '%4 itibarıyla %3 %2 %1'"), Data.DocumentName3, Data.NameOfBudget, Data.Number, Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

// Fills in the text and parameters of the initialization request.
// 
// Parameters:
// 	Query - Query - 
// 	DocumentRef - DocumentRef.BudgetEntryForm - 
Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	BudgetEntryForm.Ref AS Ref,
	|	BudgetEntryForm.Date AS Date,
	|	BudgetEntryForm.Status AS Status,
	|	BudgetEntryForm.Organization AS Organization,
	|	BudgetEntryForm.Department AS Department,
	|	BudgetEntryForm.Scenario AS Scenario,
	|	BudgetEntryForm.Scenario.Currency AS ScenarioCurrency,
	|	BudgetEntryForm.BudgetingModel AS BudgetingModel,
	|	BudgetEntryForm.BeginOfPeriod AS BeginOfPeriod,
	|	BudgetEntryForm.PeriodEnding AS PeriodEnding,
	|	BudgetEntryForm.Action AS Action
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|WHERE
	|	BudgetEntryForm.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	ParametersStructure = New Structure("BudgetingModel", Attributes.BudgetingModel);
	GenerateBudgetsByCompanies = GetFunctionalOption("GenerateBudgetsByCompanies", ParametersStructure);
	GenerateBudgetsByBusinessUnits = GetFunctionalOption("GenerateBudgetsByBusinessUnits", ParametersStructure);
	
	Query.SetParameter("Ref", Attributes.Ref);
	Query.SetParameter("Date", Attributes.Date);
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("Scenario", Attributes.Scenario);
	Query.SetParameter("BudgetingModel", Attributes.BudgetingModel);
	Query.SetParameter("BeginOfPeriod", Attributes.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Attributes.PeriodEnding);
	If Attributes.Action = Enums.TypesOfBudgetEntryFormActions.CorrectBudgetEntryForm Then
		Query.SetParameter("PointInTime", Attributes.Date-1);//New Moment (Attributes.Date, Attributes.Link));
	EndIf;
	
	Query.SetParameter("Organization", ?(GenerateBudgetsByCompanies, Attributes.Organization, Undefined));
	Query.SetParameter("Department", ?(GenerateBudgetsByBusinessUnits, Attributes.Department, Undefined));
	
	Query.SetParameter("ScenarioCurrency", Attributes.ScenarioCurrency);
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());

	If GenerateBudgetsByCompanies Then
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);
	Else
		LocalAccountingCurrency = Constants.LocalAccountingCurrency.Get();
	EndIf;
	Query.SetParameter("LocalAccountingCurrency", LocalAccountingCurrency);
	Query.SetParameter("FillInLocalAmount", ValueIsFilled(LocalAccountingCurrency));
	Query.SetParameter("LimitsRegisterIsUsed", LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed());
	
EndProcedure

Function QueryTextTableBudgetTurnovers(Query, QueryTexts, Registers)
	
	RegisterName = "BudgetTurnovers";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentSummaryTable", QueryTexts) Then
		QueryTextTTDocumentSummaryTable(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTotalAnalystValues", QueryTexts) Then
		QueryTextTTTotalAnalystValues(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Date AS Period,
	|	&BudgetingModel AS BudgetingModel,
	|	&Status AS Status,
	|	DocumentSummaryTable.PlanningPeriod AS PlanningPeriod,
	|	DocumentSummaryTable.BudgetFlowItem AS BudgetFlowItem,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Scenario AS Scenario,
	|	DocumentSummaryTable.Currency AS Currency,
	|	&TextAnalyst,
	|	DocumentSummaryTable.Count AS Count,
	|	DocumentSummaryTable.ScenarioAmount AS ScenarioAmount,
	|	DocumentSummaryTable.SumMan AS SumMan,
	|	DocumentSummaryTable.SumCompl AS SumCompl,
	|	DocumentSummaryTable.AmountInCurrency AS AmountInCurrency
	|FROM
	|	TTDocumentSummaryTable AS DocumentSummaryTable
	|		LEFT JOIN TTTotalAnalystValues AS CommonAnalystValues
	|		ON DocumentSummaryTable.BudgetFlowItem = CommonAnalystValues.BudgetFlowItem
	|WHERE
	|	(DocumentSummaryTable.Count <> 0
	|			OR DocumentSummaryTable.ScenarioAmount <> 0
	|			OR DocumentSummaryTable.SumMan <> 0
	|			OR DocumentSummaryTable.SumCompl <> 0
	|			OR DocumentSummaryTable.AmountInCurrency <> 0)";
	
	TextAnalyst = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"ISNULL(CommonAnalystValues.DimensionCaps%1, DocumentSummaryTable.Dimension%1) AS Dimension%1",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDocumentSummaryTable(Query, QueryTexts)

	RegisterName = "TTDocumentSummaryTable"; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates_", QueryTexts) Then
		QueryTextTTExchangeRates_(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAnalysisOfBudgetItems", QueryTexts) Then
		QueryTextTTAnalysisOfBudgetItems(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	BudgetFlowItemTurnovers.PlanningPeriod AS PlanningPeriod,
	|	BudgetFlowItemTurnovers.RowID AS RowID,
	|	BudgetFlowItemTurnovers.Sum AS ScenarioAmount,
	|	CAST(CASE
	|			WHEN &ScenarioCurrency = BudgetFlowItemsDimension.Currency
	|				THEN BudgetFlowItemTurnovers.Sum
	|			ELSE BudgetFlowItemTurnovers.Sum * CAST(ISNULL(ScriptCurrencyRates.Rate, 1) AS NUMBER(10, 4)) / CAST(ISNULL(ExchangeRatesCurrencies.Rate, 1) AS NUMBER(10, 4))
	|		END AS NUMBER(31,2)) AS AmountInCurrency,
	|	CAST(CASE
	|			WHEN NOT &FillInLocalAmount
	|				THEN 0
	|			WHEN &ScenarioCurrency = &LocalAccountingCurrency
	|				THEN BudgetFlowItemTurnovers.Sum
	|			ELSE BudgetFlowItemTurnovers.Sum * CAST(ISNULL(ScriptCurrencyRates.Rate, 1) AS NUMBER(10, 4)) / CAST(ISNULL(LocalCurrencyRates.Rate, 1) AS NUMBER(10, 4))
	|		END AS NUMBER(31,2)) AS SumCompl,
	|	CAST(CASE
	|			WHEN &ScenarioCurrency = &ManagementAccountingCurrency
	|				THEN BudgetFlowItemTurnovers.Sum
	|			ELSE BudgetFlowItemTurnovers.Sum * CAST(ISNULL(ScriptCurrencyRates.Rate, 1) AS NUMBER(10, 4)) / CAST(ISNULL(ManSExchangeRates.Rate, 1) AS NUMBER(10, 4))
	|		END AS NUMBER(31,2)) AS SumMan,
	|	BudgetFlowItemTurnovers.Count AS Count,
	|	BudgetFlowItemsDimension.BudgetFlowItem AS BudgetFlowItem,
	|	BudgetFlowItemsDimension.Currency AS Currency,
	|	&TextAnalyst
	|INTO TTDocumentSummaryTable
	|FROM
	|	Document.BudgetEntryForm.BudgetFlowItemTurnovers AS BudgetFlowItemTurnovers
	|		INNER JOIN TTAnalysisOfBudgetItems AS BudgetFlowItemsDimension
	|		ON (BudgetFlowItemsDimension.RowID = BudgetFlowItemTurnovers.RowID)
	|		LEFT JOIN TTExchangeRates_ AS ExchangeRatesCurrencies
	|		ON ExchangeRatesCurrencies.Scenario = &Scenario
	|			AND (ExchangeRatesCurrencies.Currency = BudgetFlowItemsDimension.Currency)
	|			AND (ExchangeRatesCurrencies.Period IN
	|				(SELECT
	|					MAX(CoursesFilter.Period)
	|				FROM
	|					TTExchangeRates_ AS CoursesFilter
	|				WHERE
	|					CoursesFilter.Currency = BudgetFlowItemsDimension.Currency
	|					AND CoursesFilter.Period <= BudgetFlowItemTurnovers.PlanningPeriod))
	|		LEFT JOIN TTExchangeRates_ AS ManSExchangeRates
	|		ON ManSExchangeRates.Scenario = &Scenario
	|			AND (ManSExchangeRates.Currency = &ManagementAccountingCurrency)
	|			AND (ManSExchangeRates.Period IN
	|				(SELECT
	|					MAX(CoursesFilter.Period)
	|				FROM
	|					TTExchangeRates_ AS CoursesFilter
	|				WHERE
	|					CoursesFilter.Currency = &ManagementAccountingCurrency
	|					AND CoursesFilter.Period <= BudgetFlowItemTurnovers.PlanningPeriod))
	|		LEFT JOIN TTExchangeRates_ AS ScriptCurrencyRates
	|		ON ScriptCurrencyRates.Scenario = &Scenario
	|			AND (ScriptCurrencyRates.Currency = &ScenarioCurrency)
	|			AND (ScriptCurrencyRates.Period IN
	|				(SELECT
	|					MAX(CoursesFilter.Period)
	|				FROM
	|					TTExchangeRates_ AS CoursesFilter
	|				WHERE
	|					CoursesFilter.Currency = &ScenarioCurrency
	|					AND CoursesFilter.Period <= BudgetFlowItemTurnovers.PlanningPeriod))
	|		LEFT JOIN TTExchangeRates_ AS LocalCurrencyRates
	|		ON LocalCurrencyRates.Scenario = &Scenario
	|			AND (LocalCurrencyRates.Currency = &LocalAccountingCurrency)
	|			AND (LocalCurrencyRates.Period IN
	|				(SELECT
	|					MAX(CoursesFilter.Period)
	|				FROM
	|					TTExchangeRates_ AS CoursesFilter
	|				WHERE
	|					CoursesFilter.Currency = &LocalAccountingCurrency
	|					AND CoursesFilter.Period <= BudgetFlowItemTurnovers.PlanningPeriod))
	|WHERE
	|	BudgetFlowItemTurnovers.Ref = &Ref
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)";
	
	TextAnalyst = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetFlowItemsDimension.Dimension%1 AS Dimension%1",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
	
	If Query.Parameters.Property("PointInTime") Then
		
		QueryText = QueryText + "
		|
		|INDEX BY
		|	BudgetFlowItemTurnovers.PlanningPeriod,
		|	BudgetFlowItemsDimension.BudgetFlowItem,
		|	BudgetFlowItemsDimension.Currency,
		|	&TextAnalyst";
		
		TextAnalyst = "";
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"BudgetFlowItemsDimension.Dimension%1",
					DimensionNumber);
		EndDo;
		QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
		
		SubqueryTexts_ = New Array;
		QueryText = StrReplace(QueryText, "INTO TTDocumentSummaryTable", "INTO TTDocumentSummaryTablePreliminary"); // Query-part
		SubqueryTexts_.Add(QueryText);
		
		QueryText = "
		|SELECT
		|	TurnoversAndTurnovers.PlanningPeriod AS PlanningPeriod,
		|	TurnoversAndTurnovers.Currency AS Currency,
		|	&TextAnalyticsWithPseudonym,
		|	TurnoversAndTurnovers.BudgetFlowItem AS BudgetFlowItem,
		|	TurnoversAndTurnovers.CountTurnover AS Count,
		|	TurnoversAndTurnovers.SumManTurnover AS SumMan,
		|	TurnoversAndTurnovers.ScenarioAmountTurnover AS ScenarioAmount,
		|	TurnoversAndTurnovers.SumComplTurnover AS SumCompl,
		|	TurnoversAndTurnovers.AmountInCurrencyTurnover AS AmountInCurrency
		|INTO TTInitialBudgetTurnover
		|FROM
		|	AccumulationRegister.BudgetTurnovers.Turnovers(
		|			,
		|			&PointInTime,
		|			,
		|			Organization = &Organization
		|				AND Department = &Department
		|				AND Scenario = &Scenario
		|				AND (PlanningPeriod, BudgetFlowItem, Currency, &TextOfDimensionsFields) IN
		|					(SELECT
		|						TT_SummaryTable.PlanningPeriod,
		|						TT_SummaryTable.BudgetFlowItem,
		|						TT_SummaryTable.Currency,
		|						&TextAnalyst
		|					FROM
		|						TTDocumentSummaryTablePreliminary AS TT_SummaryTable)) AS TurnoversAndTurnovers
		|
		|INDEX BY
		|	PlanningPeriod,
		|	BudgetFlowItem,
		|	Currency,
		|	&TextOfDimensionsFields";
		TextOfDimensionsFields = "";
		TextAnalyticsWithPseudonym = "";
		TextAnalyst = "";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			TextOfDimensionsFields = TextOfDimensionsFields + ?(TextOfDimensionsFields = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString("Dimension%1", DimensionNumber);
			TextAnalyticsWithPseudonym = TextAnalyticsWithPseudonym + ?(TextAnalyticsWithPseudonym = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"TurnoversAndTurnovers.Dimension%1 AS Dimension%1", DimensionNumber);
			TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"TT_SummaryTable.Dimension%1", DimensionNumber);
		EndDo;
		QueryText = StrReplace(QueryText, "&TextOfDimensionsFields", TextOfDimensionsFields);
		QueryText = StrReplace(QueryText, "&TextAnalyticsWithPseudonym", TextAnalyticsWithPseudonym);
		QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
		If Query.Parameters.Organization = Undefined Then
			QueryText = StrReplace(QueryText, "Organization = &Organization", "TRUE"); // Query-part
		EndIf;
		If Query.Parameters.Department = Undefined Then
			QueryText = StrReplace(QueryText, "Department = &Department", "TRUE"); // Query-part
		EndIf;
		SubqueryTexts_.Add(QueryText);
		
		QueryText =
		"SELECT
		|	TT_SummaryTable.PlanningPeriod AS PlanningPeriod,
		|	TT_SummaryTable.RowID AS RowID,
		|	TT_SummaryTable.ScenarioAmount - ISNULL(TTInitialBudgetTurnover.ScenarioAmount, 0) AS ScenarioAmount,
		|	TT_SummaryTable.AmountInCurrency - ISNULL(TTInitialBudgetTurnover.AmountInCurrency, 0) AS AmountInCurrency,
		|	TT_SummaryTable.SumCompl - ISNULL(TTInitialBudgetTurnover.SumCompl, 0) AS SumCompl,
		|	TT_SummaryTable.SumMan - ISNULL(TTInitialBudgetTurnover.SumMan, 0) AS SumMan,
		|	TT_SummaryTable.Count - ISNULL(TTInitialBudgetTurnover.Count, 0) AS Count,
		|	TT_SummaryTable.BudgetFlowItem AS BudgetFlowItem,
		|	TT_SummaryTable.Currency AS Currency,
		|	&TextAnalyst
		|INTO TTDocumentSummaryTable
		|FROM
		|	TTDocumentSummaryTablePreliminary AS TT_SummaryTable
		|		LEFT JOIN TTInitialBudgetTurnover AS TTInitialBudgetTurnover
		|		ON TT_SummaryTable.PlanningPeriod = TTInitialBudgetTurnover.PlanningPeriod
		|			AND TT_SummaryTable.BudgetFlowItem = TTInitialBudgetTurnover.BudgetFlowItem
		|			AND TT_SummaryTable.Currency = TTInitialBudgetTurnover.Currency
		|			AND (&DimensionsJoinText)
		|WHERE
		|	(TT_SummaryTable.ScenarioAmount - ISNULL(TTInitialBudgetTurnover.ScenarioAmount, 0) <> 0
		|			OR TT_SummaryTable.AmountInCurrency - ISNULL(TTInitialBudgetTurnover.AmountInCurrency, 0) <> 0
		|			OR TT_SummaryTable.SumCompl - ISNULL(TTInitialBudgetTurnover.SumCompl, 0) <> 0
		|			OR TT_SummaryTable.SumMan - ISNULL(TTInitialBudgetTurnover.SumMan, 0) <> 0
		|			OR TT_SummaryTable.Count - ISNULL(TTInitialBudgetTurnover.Count, 0) <> 0)
		|
		|INDEX BY
		|	TT_SummaryTable.RowID";
		TextAnalyst = "";
		DimensionsJoinText = "";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			DimensionsJoinText = DimensionsJoinText + ?(DimensionsJoinText = "", "", Chars.LF + Chars.Tab + "And ")
				+ StringFunctionsClientServer.SubstituteParametersToString("TT_SummaryTable.Dimension%1 = TTInitialBudgetTurnover.Dimension%1", DimensionNumber);
			TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
				+ StringFunctionsClientServer.SubstituteParametersToString(
					"TT_SummaryTable.Dimension%1 AS Dimension%1", DimensionNumber);
		EndDo;
		QueryText = StrReplace(QueryText, "&DimensionsJoinText", DimensionsJoinText);
		QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
		SubqueryTexts_.Add(QueryText);
		
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(SubqueryTexts_, "TTDocumentSummaryTablePreliminary");
		FinancialAccountingByBalanceSheetRegisterData.AddRequestToDeleteTemporaryTable(SubqueryTexts_, "TTInitialBudgetTurnover");
		QueryText = StrConcat(SubqueryTexts_, Common.QueryBatchSeparator());
		
	Else
		
		QueryText = QueryText + "
		|
		|INDEX BY
		|	BudgetFlowItemTurnovers.RowID";
	
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates_(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates_";
	
	QueryText = Catalogs.BudgetingScenarios.QueryTextScriptCourseTable(RegisterName);
	QueryText = StrReplace(QueryText, "&ScenarioCondition", "BudgetingScenarios.Ref IN (&Scenario)");
	QueryText = StrReplace(QueryText, "&ConditionByCurrency1", "TRUE");
	QueryText = StrReplace(QueryText, "&ConditionByCurrency2", "TRUE");
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTTAnalysisOfBudgetItems(Query, QueryTexts)
	
	RegisterName = "TTAnalysisOfBudgetItems";
	
	QueryText =
	"SELECT
	|	CopyOfBudgetAnalysisOfBudgetItems.BudgetFlowItem AS BudgetFlowItem,
	|	&TextAnalyst,
	|	CopyOfBudgetAnalysisOfBudgetItems.Currency AS Currency,
	|	CopyOfBudgetAnalysisOfBudgetItems.RowID AS RowID
	|INTO TTAnalysisOfBudgetItems
	|FROM
	|	Document.BudgetEntryForm.BudgetFlowItemsDimension AS CopyOfBudgetAnalysisOfBudgetItems
	|WHERE
	|	CopyOfBudgetAnalysisOfBudgetItems.Ref = &Ref
	|	AND &Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|
	|INDEX BY
	|	RowID";
	
	TextAnalyst = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CopyOfBudgetAnalysisOfBudgetItems.Dimension%1 AS Dimension%1",
				DimensionNumber);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTTTotalAnalystValues(Query, QueryTexts)
	
	RegisterName = "TTTotalAnalystValues";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAnalystFlagsFromHeader", QueryTexts) Then
		QueryTextTTAnalystFlagsFromHeader(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	AnalystFlagsFromHeader.BudgetFlowItem,
	|	&HeaderAnalyticsText
	|INTO TTTotalAnalystValues
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|		LEFT JOIN TTAnalystFlagsFromHeader AS AnalystFlagsFromHeader
	|		ON (TRUE)
	|WHERE
	|	BudgetEntryForm.Ref = &Ref";
	
	HeaderAnalyticsText = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	ConditionTemplateInsideField =
	"		WHEN AnalystFlagsFromHeader.SourceAnalyticsCap%1 = %2
	|			THEN BudgetEntryForm.Dimension%2";
	For FieldNumber = 1 To MaximumNumberOfAnalysts Do
		FieldText = 
		"	CASE
		|%1
		|	END AS DimensionCaps%2";
		
		ConditionTextInsideField = "";
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ConditionInsideField = StringFunctionsClientServer.SubstituteParametersToString(
				ConditionTemplateInsideField,
				FieldNumber,
				DimensionNumber);
			ConditionTextInsideField = ConditionTextInsideField + ?(ConditionTextInsideField = "", "", Chars.LF)
				+ ConditionInsideField;
		EndDo;
		FieldText = StringFunctionsClientServer.SubstituteParametersToString(
			FieldText,
			ConditionTextInsideField,
			FieldNumber);
			
		HeaderAnalyticsText = HeaderAnalyticsText + ?(HeaderAnalyticsText = "", "", "," + Chars.LF) + FieldText;
	EndDo;
	
	QueryText = StrReplace(QueryText, "&HeaderAnalyticsText", HeaderAnalyticsText);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTTAnalystFlagsFromHeader(Query, QueryTexts)
	
	RegisterName = "TTAnalystFlagsFromHeader";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAnalyticsCaps", QueryTexts) Then
		QueryTextTTAnalyticsCaps(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBudgetItems", QueryTexts) Then
		QueryTextTTBudgetItems(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	BudgetItems.BudgetFlowItem,
	|	&TextOfAnalyticsSourceFields
	|INTO TTAnalystFlagsFromHeader
	|FROM
	|	TTBudgetItems AS BudgetItems";
	
	TextOfAnalyticsSourceFields = "";
	HeaderAnalyticsConnectionText = "";
	SampleFieldDescriptionTemplate = "DimensionCaps%1.LineNumber AS SourceAnalyticsCap%1";
	HeaderAnalyticsConnectionTemplate =
	"		LEFT JOIN TTAnalyticsCaps AS DimensionCaps%1
	|		ON BudgetItems.BudgetFlowItem.DimensionKind%1 = DimensionCaps%1.DimensionKind";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfAnalyticsSourceFields = TextOfAnalyticsSourceFields + ?(TextOfAnalyticsSourceFields = "", "", ",
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				SampleFieldDescriptionTemplate,
				DimensionNumber);
		
		HeaderAnalyticsConnectionText = HeaderAnalyticsConnectionText + ?(HeaderAnalyticsConnectionText = "", "", "
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				HeaderAnalyticsConnectionTemplate,
				DimensionNumber);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&TextOfAnalyticsSourceFields", TextOfAnalyticsSourceFields);
	QueryText = QueryText + Chars.LF + HeaderAnalyticsConnectionText;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAnalyticsCaps(Query, QueryTexts)
	
	RegisterName = "TTAnalyticsCaps";
	
	QueryText = 
	"SELECT
	|	BudgetProfilesHeaderDimensions.LineNumber,
	|	BudgetProfilesHeaderDimensions.DimensionKind
	|INTO TTAnalyticsCaps
	|FROM
	|	Document.BudgetEntryForm AS BudgetEntryForm
	|		LEFT JOIN Catalog.BudgetProfiles.HeaderDimensions AS BudgetProfilesHeaderDimensions
	|		ON (BudgetProfilesHeaderDimensions.Ref = BudgetEntryForm.BudgetProfile)
	|WHERE
	|	BudgetEntryForm.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBudgetItems(Query, QueryTexts)
	
	RegisterName = "TTBudgetItems";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentSummaryTable", QueryTexts) Then
		QueryTextTTDocumentSummaryTable(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentSummaryTable.BudgetFlowItem
	|INTO TTBudgetItems
	|FROM
	|	TTDocumentSummaryTable AS DocumentSummaryTable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLimitsByBudgetingData(Query, QueryTexts, Registers)
	
	RegisterName = "LimitsByBudgetingData";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDocumentSummaryTable", QueryTexts) Then
		QueryTextTTDocumentSummaryTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTotalAnalystValues", QueryTexts) Then
		QueryTextTTTotalAnalystValues(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLimitRules", QueryTexts) Then
		QueryTextTTLimitRules(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date AS Period,
	|	CASE LimitRules.Periodicity
	|		WHEN VALUE(Enum.Periodicity.WEEK)
	|			THEN BEGINOFPERIOD(DocumentSummaryTable.PlanningPeriod, WEEK)
	|		WHEN VALUE(Enum.Periodicity.TENDAYS)
	|			THEN BEGINOFPERIOD(DocumentSummaryTable.PlanningPeriod, TENDAYS)
	|		WHEN VALUE(Enum.Periodicity.MONTH)
	|			THEN BEGINOFPERIOD(DocumentSummaryTable.PlanningPeriod, MONTH)
	|		WHEN VALUE(Enum.Periodicity.QUARTER)
	|			THEN BEGINOFPERIOD(DocumentSummaryTable.PlanningPeriod, QUARTER)
	|		WHEN VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN BEGINOFPERIOD(DocumentSummaryTable.PlanningPeriod, HALFYEAR)
	|		WHEN VALUE(Enum.Periodicity.YEAR)
	|			THEN BEGINOFPERIOD(DocumentSummaryTable.PlanningPeriod, YEAR)
	|		ELSE DocumentSummaryTable.PlanningPeriod
	|	END AS LimitationPeriod,
	|	LimitRules.LimitsRule AS LimitsRule,
	|	LimitRules.Organization AS Organization,
	|	LimitRules.Department AS Department,
	|	DocumentSummaryTable.Currency AS Currency,
	|	&TextAnalyst,
	|	DocumentSummaryTable.AmountInCurrency AS Limit
	|FROM
	|	TTDocumentSummaryTable AS DocumentSummaryTable
	|		LEFT JOIN TTTotalAnalystValues AS CommonAnalystValues
	|		ON DocumentSummaryTable.BudgetFlowItem = CommonAnalystValues.BudgetFlowItem
	|		INNER JOIN TTLimitRules AS LimitRules
	|		ON DocumentSummaryTable.BudgetFlowItem = LimitRules.BudgetFlowItem
	|WHERE
	|	&LimitsRegisterIsUsed
	|	AND &Status = VALUE(Enum.PlanStatuses.Upholded)
	|	AND DocumentSummaryTable.AmountInCurrency <> 0";
	
	TextAnalyst = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"CASE
				|	WHEN LimitRules.DimensionKind%1 = UNDEFINED
				|		THEN UNDEFINED
				|	ELSE ISNULL(CommonAnalystValues.DimensionCaps%1, DocumentSummaryTable.Dimension%1)
				|END AS Dimension%1",
				DimensionNumber);
	EndDo;
	QueryText = StrReplace(QueryText, "&TextAnalyst", TextAnalyst);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfAnalyticsOfBudgetItems(Query, QueryTexts)
	
	RegisterName = "TTTypesOfAnalyticsOfBudgetItems";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBudgetItems", QueryTexts) Then
		QueryTextTTBudgetItems(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	BudgetItems.BudgetFlowItem,
	|	&TextOfAnalyticsViewFields
	|INTO TTTypesOfAnalyticsOfBudgetItems
	|FROM
	|	TTBudgetItems AS BudgetItems
	|	LEFT JOIN Catalog.BudgetFlowItems AS BudgetFlowItems
	|	ON BudgetItems.BudgetFlowItem = BudgetFlowItems.Ref";
	
	TextOfAnalyticsViewFields = "";
	SampleFieldDescriptionTemplate = "BudgetFlowItems.DimensionKind%1 AS DimensionKind%1";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfAnalyticsViewFields = TextOfAnalyticsViewFields + ?(TextOfAnalyticsViewFields = "", "", ",
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				SampleFieldDescriptionTemplate,
				DimensionNumber);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&TextOfAnalyticsViewFields", TextOfAnalyticsViewFields);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLimitRules(Query, QueryTexts)

	RegisterName = "TTLimitRules"; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfAnalyticsOfBudgetItems", QueryTexts) Then
		QueryTextTTTypesOfAnalyticsOfBudgetItems(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	LimitRules.Ref AS LimitsRule,
	|	LimitRules.BudgetFlowOrBalanceItem AS BudgetFlowItem,
	|	LimitRules.Periodicity AS Periodicity,
	|	CASE
	|		WHEN CompanyLimitRules.Ref IS NULL
	|			THEN VALUE(Catalog.Companies.EmptyRef)
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN DivisionLimitRules.Ref IS NULL
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE &Department
	|	END AS Department,
	|	&FieldTextTypesOfRuleAnalytics
	|INTO TTLimitRules
	|FROM
	|	Catalog.BudgetingLimits AS LimitRules
	|		INNER JOIN TTTypesOfAnalyticsOfBudgetItems AS TypesOfBudgetItemAnalytics
	|		ON LimitRules.BudgetFlowOrBalanceItem = TypesOfBudgetItemAnalytics.BudgetFlowItem
	|		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS CompanyLimitRules
	|		ON LimitRules.Ref = CompanyLimitRules.Ref
	|			AND (CompanyLimitRules.Used)
	|			AND CompanyLimitRules.DimensionName = ""Organization""
	|		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS DivisionLimitRules
	|		ON LimitRules.Ref = DivisionLimitRules.Ref
	|			AND (DivisionLimitRules.Used)
	|			AND DivisionLimitRules.DimensionName = ""Department""
	|		AND &TextOfRuleAnalystTypesConnection
	|
	|WHERE
	|	&LimitsRegisterIsUsed
	|	AND LimitRules.Owner = &BudgetingModel
	|	AND (LimitRules.Scenario = &Scenario
	|			OR LimitRules.Scenario = VALUE(Catalog.BudgetingScenarios.EmptyRef))
	|	AND NOT LimitRules.DeletionMark";
	
	TextOfFieldsOfTypesOfRuleAnalytics = "";
	TextOfRuleAnalystTypesConnection = "";
	TemplateForDescriptionOfRuleAnalyticsTypeField = "ISNULL(LimitRulesTypesOfAnalytics%1.DimensionKind, UNDEFINED) AS DimensionKind%1";
	TemplateForConnectingTypesOfRuleAnalytics =
	"		LEFT JOIN Catalog.BudgetingLimits.DimensionsHierarchy AS LimitRulesTypesOfAnalytics%1
	|		ON LimitRules.Ref = LimitRulesTypesOfAnalytics%1.Ref
	|			AND (LimitRulesTypesOfAnalytics%1.Used)
	|			AND LimitRulesTypesOfAnalytics%1.DimensionKind = TypesOfBudgetItemAnalytics.DimensionKind%1
	|			AND (LimitRulesTypesOfAnalytics%1.DimensionKind <> VALUE(ChartOfCharacteristicTypes.BudgetFlowItemDimensions.EmptyRef))";
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfFieldsOfTypesOfRuleAnalytics = TextOfFieldsOfTypesOfRuleAnalytics + ?(TextOfFieldsOfTypesOfRuleAnalytics = "", "", ",
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				TemplateForDescriptionOfRuleAnalyticsTypeField,
				DimensionNumber);
		
		TextOfRuleAnalystTypesConnection = TextOfRuleAnalystTypesConnection + ?(TextOfRuleAnalystTypesConnection = "", "", "
			|	")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				TemplateForConnectingTypesOfRuleAnalytics,
				DimensionNumber);
	EndDo;
	
	QueryText = StrReplace(QueryText, "&FieldTextTypesOfRuleAnalytics", TextOfFieldsOfTypesOfRuleAnalytics);
	QueryText = StrReplace(QueryText, "AND &TextOfRuleAnalystTypesConnection", TextOfRuleAnalystTypesConnection);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

// Returns a header or representation of other values in the user's language based on the header generation parameters.
//
// Parameters:
//  ParametersForCreatingInputList - See BudgetReportingCacheCalculationServer.InputListItemParameters.
//
// Returns:
//  Structure - Parameters Of The Value Entry Element In The User's Language:
//   *Title - String - item header.
//   *PresentationOfOtherValues - String - Hint for entering values.
//   *Format - String - format string for entering the period.
//   		 - Undefined - format string is not applied.
//
Function ParametersOfValueEntryElementInUserSLanguage(ParametersForCreatingInputList) Export
	ParametersForCreatingInputList = ParametersForCreatingInputList;
	
	Result = New Structure("Title, PresentationOfOtherValues, Format");
	
	If ParametersForCreatingInputList.ItemKind = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		Result.Title = NStr("vi = 'Khoản mục / chỉ tiêu ngân sách';
							|ru = 'Статья/показатель бюджетов';
							|en = 'Budget flow item/indicator'; fa = 'قلم جریان بودجه/شاخص';
							|it = 'Voce/indicatore di bilancio';
							|pl = 'Pozycja/wskaźnik budżetów';
							|tr = 'Kalem/bütçe kalemi'");
		Result.PresentationOfOtherValues = NStr("vi = '<các mục / chỉ tiêu ngân sách khác>';
												|ru = '<прочие статьи/показатели бюджетов>';
												|en = '<other budget flow items/budget balance items>'; fa = '<other budget flow items/budget balance items>';
												|it = '<altri voci /indici di bilancio>';
												|pl = '<inne pozycje/wskaźniki budżetów>';
												|tr = '<diğer kalemler/bütçe dengesi kalemleri>'");
	ElsIf ParametersForCreatingInputList.ItemKind = Enums.FinancialReportItemKinds.Dimension
		And ParametersForCreatingInputList.DimensionType = Enums.TypesOfBudgetReportDimensions.Currency Then
		Result.Title = BudgetReportingClientServer.PresentationOfBudgetingDimension("Currency");
		Result.PresentationOfOtherValues = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
			"Currency", "OtherItems");
	ElsIf ParametersForCreatingInputList.ItemKind = Enums.FinancialReportItemKinds.Dimension
		And ParametersForCreatingInputList.DimensionType = Enums.TypesOfBudgetReportDimensions.Period Then
		
		Result.Title = String(ParametersForCreatingInputList.Periodicity);
		Result.PresentationOfOtherValues = "";
		
		Periodicity = ParametersForCreatingInputList.Periodicity;
		If Periodicity = Enums.Periodicity.Year Then
			Format = NStr("vi = 'ДФ=yyyy';
							|ru = 'ДФ=гггг';
							|en = 'DF=yyyy'; fa = 'DF=yyyy';
							|it = 'DF=yyyy';
							|pl = 'DF=yyyy';
							|tr = 'DF=yyyy'");
		ElsIf Periodicity = Enums.Periodicity.HalfYear Then
			Format = NStr("vi = 'ДФ=''""Nửa năm từ"" ММММ гггг''';
							|ru = 'ДФ=''""Полугодие с"" ММММ гггг''';
							|en = 'DF=''""Half-year from"" MMMM yyyy'''; fa = 'DF=''""Half-year from"" MMMM yyyy''';
							|it = 'DF=""''Semestre da"" MMMM yyyy''';
							|pl = 'DF=''""Półrocze z"" MMMM yyyy''';
							|tr = 'DF=''""İtibarıyla yarıyıl"" AAAA yyyy'''");
		ElsIf Periodicity = Enums.Periodicity.Quarter Then
			Format = NStr("vi = 'ДФ=''theo ""quý""''';
							|ru = 'ДФ=''к ""квартал""''';
							|en = 'DF=''""Q""q'''; fa = 'DF=''""Q""q''';
							|it = 'ДФ=''к ""квартал""''';
							|pl = 'ДФ(LD)=''k ""kwartał""''';
							|tr = 'DF=''q ""çeyrek""'''")
		ElsIf Periodicity = Enums.Periodicity.Month Then
			Format = NStr("vi = 'ДФ=''""tháng"" MM ""năm"" yyyy''';
							|ru = 'ДФ=''MMMM yyyy''';
							|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
							|it = 'DF=''MMMM yyyy''';
							|pl = 'DF=''MMMM yyyy''';
							|tr = 'DF=''AAAA yyyy'''");
		ElsIf Periodicity = Enums.Periodicity.TenDays Then
			Format = StrTemplate(NStr("vi = 'ДФ=''""10 ngày từ"" %1''';
										|ru = 'ДФ=''""Декада с"" %1''';
										|en = 'DF=''""Ten-day period from"" %1'''; fa = 'DF=''""Ten-day period from"" %1''';
										|it = 'DF=""''Decade da"" %1''';
										|pl = 'DF=''""Dekada z"" %1''';
										|tr = 'DF=''""10 gün itibarıyla"" %1'''"), "dd.MM.yy");
		ElsIf Periodicity = Enums.Periodicity.Week Then
			Format = StrTemplate(NStr("vi = 'ДФ=''""Tuần từ"" %1''';
										|ru = 'ДФ=''""Неделя с"" %1''';
										|en = 'DF=''""Week from"" %1'''; fa = 'DF=''""Week from"" %1''';
										|it = 'DF=""''Settimana da"" %1''';
										|pl = 'DF=''""Tydzień z"" %1''';
										|tr = 'DF=''""Bir hafta itibarıyla"" %1'''"), "dd.MM.yy");
		ElsIf Periodicity = Enums.Periodicity.Day Then
			Format = "DLF=D";
		EndIf;
		
		Result.Format = Format;
	Else
		// this is a type of analytics. 
		Result.Title = String(ParametersForCreatingInputList.DimensionKind);
		Result.PresentationOfOtherValues = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
			ParametersForCreatingInputList.DimensionKind, "OtherItems");
	EndIf;
	
	Return Result;
EndFunction

// LongDesc
// 
// Parameters:
// 	ItemsToAdd1 - Array of FormAttribute -
// 	ColumnsToAdd - Array of FormAttribute -
// 	ColumnsByDimension - Structure -
// 	FixedValues - Undefined, Structure - LongDesc
Procedure CalculateBudgetListItemsToAdd(ItemsToAdd1, ColumnsToAdd, 
												ColumnsByDimension, FixedValues = Undefined) Export
	
	For Each Dimension In ColumnsByDimension.Dimensions Do
		
		ReportItem = ColumnsByDimension.ColumnSettings[Dimension];
		
		ItemParameters = ParametersOfValueEntryElementInUserSLanguage(
			ReportItem.ParametersForCreatingInputList);
		
		AttributeName = Dimension;
		NewAttribute = New FormAttribute(AttributeName,
				ReportItem.ValueType,
				"BudgetEditList",
				ItemParameters.Title);
		
		ItemsToAdd1.Add(NewAttribute);
		
		NewColumn = New Structure();
		NewColumn.Insert("Name", AttributeName);
		NewColumn.Insert("Type", "FormField");
		NewColumn.Insert("Parent", "BudgetEditList");
		NewColumn.Insert("Title", ItemParameters.Title);
		
		If ReportItem.Property("ChoiceParameterLinks") Then
			NewColumn.Insert("ChoiceParameterLinks", ReportItem.ChoiceParameterLinks);
		EndIf;
		
		If ReportItem.Property("ChoiceParameters") Then
			NewColumn.Insert("ChoiceParameters", ReportItem.ChoiceParameters);
		EndIf;
		
		If Not ItemParameters.Format = Undefined Then
			NewColumn.Insert("Format", ItemParameters.Format);
		EndIf;
		
		SelectionSettings_ = ColumnsByDimension.InputSettings[Dimension];
		If SelectionSettings_ <> Undefined Then
			NewColumn.Insert("ChoiceList", SelectionSettings_);
			If FixedValues <> Undefined Then
				If SelectionSettings_.Count() = 1 Then
					FixedValues.Insert(Dimension, SelectionSettings_[0].Value);
				EndIf;
			EndIf;
		EndIf;
		
		If Not StrFind(Dimension, "Period") Then
			NewColumn.Insert("OthersAreRequired");
			NewColumn.Insert("PresentationOfOther", ItemParameters.PresentationOfOtherValues);
		EndIf;
		
		ColumnsToAdd.Add(NewColumn);
		
	EndDo;
	
EndProcedure

Function TemplateForParametersForAddingColumnsToBudgetList() Export
	
	Parameters = New Structure;
	Parameters.Insert("ItemsToAdd1");
	Parameters.Insert("ColumnsToAdd");
	Parameters.Insert("ColumnsByDimension");
	Parameters.Insert("ColumnStructure1");
	Parameters.Insert("StructureAnalogDecryption");
	
	Return Parameters;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	ParametersForAddingColumns  - Structure - LongDesc:
// * StructureAnalogDecryption - Structure -
// * ColumnStructure1 - ValueTree, ValueTreeRow -
// * ColumnsByDimension - Structure -
// * ColumnsToAdd - Array of FormAttribute -
// * ItemsToAdd1 - Array of FormAttribute -
// 	ArrayOfLevels - Undefined, Structure - LongDesc
// 	ParentColumn_ - String, Structure - LongDesc:
// * Format - String -
// * ReadOnly - Boolean -
// * Type - String -
// * Name - String -
Procedure AddBudgetListColumnsByTable(ParametersForAddingColumns, ArrayOfLevels = Undefined, ParentColumn_ = "") Export
	
	ItemsToAdd1 = ParametersForAddingColumns.ItemsToAdd1;
	ColumnsToAdd = ParametersForAddingColumns.ColumnsToAdd;
	ColumnsByDimension = ParametersForAddingColumns.ColumnsByDimension;
	ColumnStructure1 = ParametersForAddingColumns.ColumnStructure1;
	StructureAnalogDecryption = ParametersForAddingColumns.StructureAnalogDecryption;
	
	If ArrayOfLevels = Undefined Then
		ArrayOfLevels = New Structure;
	EndIf;
	
	For Each BudgetColumn In ColumnStructure1.Rows Do
		
		If ValueIsFilled(BudgetColumn.FixedValue) Then
			ArrayOfLevels.Insert(BudgetColumn.DimensionName, BudgetColumn.FixedValue);
		EndIf;
		
		LocalParent = ParentColumn_;
		ReadOnly = ?(ValueIsFilled(LocalParent), LocalParent.ReadOnly, False);
		
		NonInputColumn = ReadOnly
			Or BudgetColumn.ItemKind = Enums.FinancialReportItemKinds.DerivedItem
			Or BudgetColumn.ItemKind = Enums.FinancialReportItemKinds.GroupFormula
			Or BudgetColumn.ItemKind = Enums.FinancialReportItemKinds.NonFinancialItem;
			
		AttributeName = "Column_" + Format(ColumnsToAdd.Count(), "NG=");
		If Not BudgetColumn.Rows.Count() Then
			
			ColumnPath = New Structure;
			For Each KeyAndValue In ArrayOfLevels Do
				ColumnPath.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
			
			ColumnReportElement = Undefined;
			If ValueIsFilled(BudgetColumn.ReportItem) Then
				ColumnPath.Insert("Column", BudgetColumn.ReportItem);
				ColumnReportElement = BudgetColumn.ReportItem;
			ElsIf ValueIsFilled(ParentColumn_) Then
				ColumnPath.Insert("Column", ParentColumn_.ReportItem);
				ColumnReportElement = ParentColumn_.ReportItem;
			EndIf;
			
			If StrFind(BudgetColumn.DimensionName, "#Factor") Then
				ColumnPath.Insert("IndicatorName", StrReplace(BudgetColumn.DimensionName, "#Factor_", ""));
				If ColumnPath.IndicatorName = "Value" 
					And Not ColumnPath.Property("EditedValue") Then
					NonInputColumn = True;
				EndIf;
			EndIf;
			
			EditedValueType = "Number"; 
			TypesOfMetricValues = New Map;
			If ColumnsByDimension.ColumnSettings.Property("TypesOfMetricValues", TypesOfMetricValues) Then
				EditedValueType = TypesOfMetricValues[ColumnReportElement];
			EndIf;
			
			If EditedValueType = "String" Then
				TypeOfColumnToEdit = New TypeDescription("String");
			ElsIf EditedValueType = "Boolean" Then
				TypeOfColumnToEdit = New TypeDescription("Boolean");
			ElsIf EditedValueType = "Date" Then
				TypeOfColumnToEdit = New TypeDescription("Date");
			ElsIf EditedValueType = "VATRate" Then
				TypeOfColumnToEdit = New TypeDescription("CatalogRef.VATRates");
			Else
				TypeOfColumnToEdit = TMCommonUse.MoneyFieldTypeDescription();
			EndIf;
				
			NewAttribute = New FormAttribute(AttributeName,
					TypeOfColumnToEdit, 
					"BudgetEditList",
					BudgetColumn.NameForPrinting);
			
			ItemsToAdd1.Add(NewAttribute);
			ColumnType = "FormField";
			
			BudgetFlowItems = Undefined;
			If ColumnsByDimension.Property("BudgetFlowItems", BudgetFlowItems) Then
				DetailsStructure1 = BudgetFlowItems[ColumnPath.Column];
				If DetailsStructure1 = Undefined Then
					NonInputColumn = True;
				Else
					BudgetFlowItem = DetailsStructure1.BudgetFlowItem;
					EditedValue = DetailsStructure1.EditedValue;
					IndicatorName = DetailsStructure1.IndicatorName;
					If Not ValueIsFilled(BudgetFlowItem)
						And Not ValueIsFilled(EditedValue) Then
						NonInputColumn = True;
					ElsIf ValueIsFilled(BudgetFlowItem) Then
						ColumnPath.Insert("BudgetFlowItem", BudgetFlowItem);
					ElsIf ValueIsFilled(EditedValue) Then
						ColumnPath.Insert("EditedValue", EditedValue);
					EndIf;
					ColumnPath.Insert("IndicatorName", IndicatorName);
				EndIf;
			EndIf;
			
			If NonInputColumn Then
				ColumnPath.Insert("Calculated", True);
			EndIf;
			
			StructureAnalogDecryption.Insert(AttributeName, ColumnPath);
			
			StringType = New TypeDescription("String", , New StringQualifiers(1000));
			NewAttribute = New FormAttribute(AttributeName + "Note", StringType, "BudgetEditList");
			ItemsToAdd1.Add(NewAttribute);
			
			TypePicture = New TypeDescription("Picture");
			NewAttribute = New FormAttribute(AttributeName + "PictureNote",
					TypePicture,
					"BudgetEditList");
			ItemsToAdd1.Add(NewAttribute);
			
			If Not NonInputColumn Then
				
				ParentName = ?(ValueIsFilled(LocalParent), LocalParent.Name, "BudgetEditList");
				ColumnDetails = New Structure();
				ColumnDetails.Insert("Name", AttributeName + "InputGroup"); 
				ColumnDetails.Insert("Type", "FormGroup");
				ColumnDetails.Insert("Parent", ParentName);
				ColumnDetails.Insert("ReadOnly", False);
				ColumnDetails.Insert("Title", NStr("vi = 'Ô nhập';
													|ru = 'Ячейка ввода';
													|en = 'Input cell'; fa = 'Input cell';
													|it = 'Casella di inserimento';
													|pl = 'Komórka wprowadzenia';
													|tr = 'Giriş hücresi'"));
				ColumnDetails.Insert("Group", ColumnsGroup.InCell);
				
				ColumnsToAdd.Add(ColumnDetails);
				
				LocalParent = ColumnDetails;
				
				ParentName = LocalParent.Name;
				
				ColumnTitle = BudgetColumn.NameForPrinting + " (%1)";
				ColumnTitle = StringFunctionsClientServer.SubstituteParametersToString(
					ColumnTitle,
					NStr("vi = 'bình luận hình ảnh';
						|ru = 'картинка комментария';
						|en = 'comment picture'; fa = 'comment picture';
						|it = 'immagine del commento';
						|pl = 'obrazek komentarza';
						|tr = 'yorum resmi'"));
				ColumnDetails = New Structure();
				ColumnDetails.Insert("Name", AttributeName + "PictureNote"); 
				ColumnDetails.Insert("Type", "FormField");
				ColumnDetails.Insert("Parent", ParentName);
				ColumnDetails.Insert("ReadOnly", False);
				ColumnDetails.Insert("Title", ColumnTitle);
				ColumnDetails.Insert("Kind", FormFieldType.PictureField);
					
				ColumnsToAdd.Add(ColumnDetails);
				
			EndIf;
			
		Else
			ColumnType = "FormGroup";
		EndIf;
		
		ParentName = ?(ValueIsFilled(LocalParent), LocalParent.Name, "BudgetEditList");
		ColumnDetails = New Structure();
		ColumnDetails.Insert("Name", AttributeName);
		ColumnDetails.Insert("Type", ColumnType); 
		ColumnDetails.Insert("Parent", ParentName);
		ColumnDetails.Insert("ReadOnly", NonInputColumn);
		ColumnDetails.Insert("Title", BudgetColumn.NameForPrinting); 
	
		ColumnsToAdd.Add(ColumnDetails);
		
		If NonInputColumn Then
			ColumnDetails.Insert("ReadOnly", True);
		EndIf;
		
		If ColumnType = "FormGroup" Then
			ColumnDetails.Insert("Title", BudgetColumn.NameForPrinting);
		Else
			ColumnDetails.Insert("Format", "NFD=2");
		EndIf;
		
		ColumnDetails.Insert("ReportItem", BudgetColumn.ReportItem);
		
		ParametersForAddingColumns = TemplateForParametersForAddingColumnsToBudgetList();
		ParametersForAddingColumns.ItemsToAdd1 = ItemsToAdd1;
		ParametersForAddingColumns.ColumnsToAdd = ColumnsToAdd;
		ParametersForAddingColumns.ColumnsByDimension = ColumnsByDimension;
		ParametersForAddingColumns.ColumnStructure1 = BudgetColumn;
		ParametersForAddingColumns.StructureAnalogDecryption = StructureAnalogDecryption;
		AddBudgetListColumnsByTable(ParametersForAddingColumns,
				ArrayOfLevels,
				ColumnDetails);
		
		If ValueIsFilled(BudgetColumn.FixedValue) Then
			ArrayOfLevels.Delete(BudgetColumn.DimensionName);
		EndIf;
		
	EndDo;
	
EndProcedure

// Reflects changes to the budget list columns on the form
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	ItemsToAdd1 - Array of FormAttribute - 
// 	ColumnsToAdd  - Array of Structure:
// 	  * Name - String
// 	  * Type - String
// 	  * Kind - FormFieldType
// 	FixedValues - Undefined, Structure -
Procedure ReflectChangesToBudgetListColumnsOnForm(Form, ItemsToAdd1, ColumnsToAdd, FixedValues = Undefined) Export
	
	Items = Form.Items;
	ConditionalAppearance = Form.ConditionalAppearance; // ConditionalAppearance -
	
	ItemsToRemove = New Array;
	For Each AttributeToDelete In Form.GetAttributes("BudgetEditList") Do
		If AttributeToDelete.Name = "RowIndex"
			Or AttributeToDelete.Name = "ToImport" Then
			Continue;
		EndIf;
		ItemsToRemove.Add(AttributeToDelete.Path + "." + AttributeToDelete.Name);
	EndDo;
	
	Form.ChangeAttributes(ItemsToAdd1, ItemsToRemove);
	
	ItemsList = Items.BudgetEditList.ChildItems; // FormItems - 
	ThereIsSomethingToDelete = True;
	While ThereIsSomethingToDelete Do
		For Each Item In ItemsList Do
			If Item.Name = "BudgetEditListToImport" Then
				Continue;
			EndIf;
			Items.Delete(Item);
		EndDo;
		ItemsList = Items.BudgetEditList.ChildItems;
		If ItemsList.Count() = 1 Then
			SubordinateFormElement = ItemsList[0]; // FormField -
			If SubordinateFormElement.Name = "BudgetEditListToImport" Then
				ThereIsSomethingToDelete = False;
			EndIf;
		ElsIf Not ItemsList.Count() Then
			ThereIsSomethingToDelete = False;
		EndIf;
	EndDo;
	
	ConditionalAppearanceForDeletion = New Array;
	For Each UOElement In ConditionalAppearance.Items Do
		If StrFind(UOElement.Presentation, "AddedConditionalAppearance_") Then
			ConditionalAppearanceForDeletion.Add(UOElement);
		EndIf;
	EndDo;
	
	For Each UOElement In ConditionalAppearanceForDeletion Do
		ConditionalAppearance.Items.Delete(UOElement);
	EndDo;
	
	For Each Attribute In ColumnsToAdd Do
		Item = Items.Add(Attribute.Name, Type(Attribute.Type), Items[Attribute.Parent]); // FormField -
		If Attribute.Type = "FormField" Then
			
			Item.DataPath = "BudgetEditList." + Attribute.Name;
			
			If Attribute.Property("Kind") Then
				Item.Type = Attribute.Kind;
				Item.TitleLocation = FormItemTitleLocation.None;
			Else
				Item.Type = FormFieldType.InputField;
				SetAvailabilityColumnSelectionList(Item, Attribute, FixedValues);
				Item.Title = Attribute.Title;
			EndIf;
			
			If Attribute.Property("ChoiceParameterLinks") Then
			
				NewLink = New ChoiceParameterLink("Filter." + Attribute.ChoiceParameterLinks.Filter,
					Attribute.ChoiceParameterLinks.DataPath);
				NewArray = New Array();
				NewArray.Add(NewLink);
				NewLinks = New FixedArray(NewArray);
				Item.ChoiceParameterLinks = NewLinks;
			
			EndIf;
			
			If Attribute.Property("ChoiceParameters") Then
			
				NewLink = New ChoiceParameter("Filter." + Attribute.ChoiceParameters.Filter,
					Attribute.ChoiceParameters.Value);
				NewArray = New Array();
				NewArray.Add(NewLink);
				NewLinks = New FixedArray(NewArray);
				Item.ChoiceParameters = NewLinks;
			
			EndIf;
			
			If Attribute.Property("Format") Then
				Item.Format = Attribute.Format;
				Item.EditFormat = "DLF=D";
			EndIf;
			
			If Attribute.Property("OthersAreRequired") Then
				
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				
				FilterElement = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				FilterElement.LeftValue = New DataCompositionField(Item.DataPath);
				FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
				
				Field = ConditionalAppearanceItem.Fields.Items.Add();
				Field.Field = New DataCompositionField(Item.Name);
				
				ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Gray);
				ConditionalAppearanceItem.Appearance.SetParameterValue("Text", Attribute.PresentationOfOther);
				ConditionalAppearanceItem.Presentation = "AddedConditionalAppearance_Text" + Item.Name;
				
			EndIf;
			
			Item.SetAction("OnChange", "Attachable_BudgetEditingListMainColumnForChanges");
			
			If Item.ReadOnly Then
				Continue;
			EndIf;
			
			If Attribute.Property("ReadOnly") And Attribute.ReadOnly Then
				
				Item.ReadOnly = True;
				
				ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
				
				Field = ConditionalAppearanceItem.Fields.Items.Add();
				Field.Field = New DataCompositionField(Item.Name);
				
				ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", New Color(237, 237, 237));
				ConditionalAppearanceItem.Presentation = "AddedConditionalAppearance_Background" + Item.Name;
				
			EndIf;
			
		Else
			
			If Attribute.Property("Group") Then
				
				Item.Group = Attribute.Group;
				
			Else
			
				Item.Title = Attribute.Title;
				Item.ShowInHeader = True;
				Item.Group = ColumnsGroup.Horizontal;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	Item - FormTable, FormDecoration, FormField, FormButton, FormGroup - LongDesc
// 	Attribute - Arbitrary, FormAttribute -
// 	FixedValues - Structure, Undefined -
Procedure SetAvailabilityColumnSelectionList(Item, Attribute, FixedValues) Export
	
	Item.ReadOnly = False;
	Item.ChoiceButton = False;
	Item.ListChoiceMode = False;
	Item.ChoiceList.Clear();
	
	If Attribute.Property("ChoiceList") Then
		For Each ListItem In Attribute.ChoiceList Do
			Item.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
	EndIf;
	
	If FixedValues <> Undefined Then
		If FixedValues.Property(Attribute.Name) Then
			Item.ReadOnly = True;
			Return;
		EndIf;
	EndIf;
	
	Item.ChoiceButton = True;
	
	If Attribute.Property("ChoiceList") Then
		Item.ChoiceButton = False;
		Item.ListChoiceMode = True;
	EndIf;
	
EndProcedure

Function CurrencyForEnteringAnalytics(Details, CacheOfArticleDetails) Export
	
	ObjectOfCurrencyAccounting = Undefined;
	If Not Details.Property("BudgetFlowItem", ObjectOfCurrencyAccounting) 
			Or Not ValueIsFilled(ObjectOfCurrencyAccounting) Then
		Return Undefined;
	EndIf;
	
	CurrencyAccountingDetails = CacheOfArticleDetails[ObjectOfCurrencyAccounting];
	
	If CurrencyAccountingDetails = Undefined Or Not CurrencyAccountingDetails.RecordByCurrency Then
		Return Undefined;
	EndIf;
	
	If CurrencyAccountingDetails = Undefined Or Not CurrencyAccountingDetails.CurrencyIsDeterminedByDimension Then
		Return Undefined;
	EndIf;
	
	CurrencyAnalyticsValue = Details.AnalystValues[CurrencyAccountingDetails.TypeOfAnalyticsCurrency];
	
	If Not ValueIsFilled(CurrencyAnalyticsValue) Then
		Return Undefined;
	EndIf;
	
	Simple = CacheOfArticleDetails[CurrencyAnalyticsValue];
	Currency = Undefined;
	If Simple = Undefined Then
		Simple = New Structure;
		Currency = Common.ObjectAttributeValue(CurrencyAnalyticsValue, CurrencyAccountingDetails.PathToCurrencyAnalytics);
		Simple.Insert(CurrencyAccountingDetails.PathToCurrencyAnalytics, Currency);
		CacheOfArticleDetails.Insert(CurrencyAnalyticsValue, Simple);
	Else
		If Not Simple.Property(CurrencyAccountingDetails.PathToCurrencyAnalytics, Currency) Then
			Currency = Common.ObjectAttributeValue(CurrencyAnalyticsValue, CurrencyAccountingDetails.PathToCurrencyAnalytics);
			Simple.Insert(CurrencyAccountingDetails.PathToCurrencyAnalytics, Currency);
		EndIf;
	EndIf;
	
	Return Currency;
	
EndFunction

Function GetAnalystOtherPresentations(BaseLines)
	
	Result = New Map;
	
	Query = New Query("SELECT
		|	FinancialReportItems.Ref AS Ref,
		|	FinancialReportItems.NameForPrinting AS NameForPrinting,
		|	FinancialReportItems.ItemKindAttributes.(
		|		Attribute,
		|		Value
		|	) AS ItemKindAttributes
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Ref IN(&BaseLines)
		|	AND FinancialReportItems.DimensionValue = UNDEFINED");
	Query.SetParameter("BaseLines", BaseLines);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		FixedDimension = False;
		ThisIsDimensionOther = False;
		DimensionKind = Undefined;
		
		ResultOfElementAppearanceSpecification = Selection.ItemKindAttributes; // QueryResult
		SelectingBankingDetails_ = ResultOfElementAppearanceSpecification.Select();
		While SelectingBankingDetails_.Next() Do
			
			If SelectingBankingDetails_.Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionType 
				And SelectingBankingDetails_.Value = Enums.TypesOfBudgetReportDimensions.FixedDimension Then
				FixedDimension = True;
			EndIf;
			
			If SelectingBankingDetails_.Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.ThisIsDimensionOther Then
				ThisIsDimensionOther = SelectingBankingDetails_.Value;
			EndIf;
			
			If SelectingBankingDetails_.Attribute = ChartsOfCharacteristicTypes.ItemAttributesOfFinancialReports.DimensionKind Then
				DimensionKind = SelectingBankingDetails_.Value;
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(DimensionKind) And FixedDimension And ThisIsDimensionOther Then
			ResultItem = Result.Get(DimensionKind); // See NewAnalyticsPresentationStructureOther
			If ResultItem = Undefined Then
				Result.Insert(DimensionKind,
								NewAnalyticsPresentationStructureOther(Selection.NameForPrinting));
				ResultItem = Result.Get(DimensionKind); // See NewAnalyticsPresentationStructureOther
			EndIf;
			ResultItem.ArrayOfBaseStrings.Add(Selection.Ref);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Function-constructor of the Analytics view structure (other)
// 
// Parameters:
// 	NameForPrinting - String -
// Returns:
// 	Structure - LongDesc:
// * NameForPrinting - String -
// * ArrayOfBaseStrings - Array -
Function NewAnalyticsPresentationStructureOther(NameForPrinting = "")
	
	Result = New Structure;
	
	Result.Insert("ArrayOfBaseStrings",  New Array);
	Result.Insert("NameForPrinting", NameForPrinting);
	
	Return Result;
	
EndFunction

Function GetDCSForPrintingDocumentWithoutDimensions(TableID, ColumnsByDimension, TreeDepth,
		BudgetProfileDisplayParameters, AnalystPresentationsOther = Undefined, ForPrinting=False) Export
	
	FinReports = FinancialReportingServer;
	
	DCS = DataCompositionServer.EmptyCircuit(); // DataCompositionSchema -
	Set = DataCompositionServer.AddEmptyDataSet(DCS,
		Type("DataCompositionSchemaDataSetObject"),
		"CellData_");
	Set.ObjectName = "CellData_";
	
	BudgetInstanceParameters = BudgetProfileDisplayParameters;
	TableColumns = BudgetInstanceParameters.TableColumns;
	ColumnTree = TableColumns[TableID];
	
	ColumnDescriptionStructure = BudgetInstanceParameters.ColumnStructureOfDataTable;
	
	Presentation = NStr("vi = 'Khoản mục ngân sách';
						|ru = 'Статья бюджетов';
						|en = 'Budget flow item'; fa = 'قلم جریان بودجه';
						|it = 'Voce di bilanci';
						|pl = 'Pozycja budżetowa';
						|tr = 'Bütçe kalemi'");
	FinReports.NewSetField(Set, "BudgetFlowItem",,Presentation);
	Presentation = NStr("vi = 'Chỉ tiêu ngân sách';
						|ru = 'Показатель бюджетов';
						|en = 'Budget balance item'; fa = 'قلم مانده بودجه';
						|it = 'Indice dei bilanci';
						|pl = 'Wskaźnik budżetowy';
						|tr = 'Bütçe kalemi'");
	FinReports.NewSetField(Set, "BudgetBalanceItem",,Presentation);
	Presentation = NStr("vi = 'Chỉ tiêu phi tài chính';
						|ru = 'Нефинансовый показатель';
						|en = 'Non-financial item'; fa = 'قلم غیرمالی';
						|it = 'Indicatore non finanziario';
						|pl = 'Wskaźnik niefinansowany';
						|tr = 'Finansal olmayan gösterge'");
	FinReports.NewSetField(Set, "NonFinancialItem",,Presentation);
	Presentation = NStr("vi = 'Giá trị có thể chỉnh sửa';
						|ru = 'Редактируемое значение';
						|en = 'Edited value'; fa = 'مقدار ویرایش‌شده';
						|it = 'Valore modificato';
						|pl = 'Edytowana wartość';
						|tr = 'Düzenlenebilir değer'");
	FinReports.NewSetField(Set, "EditedValue",,Presentation);
	FinReports.NewSetField(Set, "MainItem");
	FinReports.NewSetField(Set, "ItemKind");
	FinReports.NewSetField(Set, "String");
	FinReports.NewSetField(Set, "MinimumNumberInOrder");
	FinReports.NewSetField(Set, "Column");
	FinReports.NewSetField(Set, "RowIndex");
	
	AuxiliaryKit = DataCompositionServer.AddEmptyDataSet(DCS,
		Type("DataCompositionSchemaDataSetObject"),
		"CellParameters");
	AuxiliaryKit.ObjectName = "CellParameters";
	
	FinReports.NewSetField(AuxiliaryKit, "RowIndex");
	FinReports.NewSetField(AuxiliaryKit, "ReverseSign");
	
	FinReports.NewConnection(DCS, "CellData_", "CellParameters", "RowIndex");
	
	ExpressionText = "MIN(CASE WHEN ItemKind = VALUE(Enum.FinancialReportItemKinds.BudgetFlowItem)
						|THEN MinimumNumberInOrder ELSE 99999999999 END)";
	
	FinReports.NewResource(DCS, "MinimumNumberInOrder", , ExpressionText);
	
	For Each Dimension In ColumnDescriptionStructure.Dimensions Do
		FinReports.NewSetField(Set, Dimension,, Dimension);
	EndDo;
		
	For Each Dimension In ColumnDescriptionStructure.DimensionKinds Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(Dimension);
		SetField = FinReports.NewSetField(Set, FieldName,, String(Dimension)); // DataCompositionSchemaDataSetField -
		If AnalystPresentationsOther <> Undefined Then
			Presentation = AnalystPresentationsOther.Get(Dimension);
			If Presentation <> Undefined Then
				
				ParameterName = "ArrayOfBaseStrings_" + StrReplace(New UUID, "-", "_");
				
				// Parameter for comparison.
				Parameter = DCS.Parameters.Add();
				Parameter.Name		= ParameterName;
				Parameter.Value	= Presentation.ArrayOfBaseStrings;
				Parameter.UseRestriction = True;
				
				// Representation expression.
				// Representation in the report for analytics <other>.
				SetField.PresentationExpression = 
					"CASE
					|	WHEN STRING IN (&"	+ ParameterName + ")
					|		AND NOT ValueIsFilled(" + FieldName + ")
					|		THEN """		+ Presentation.NameForPrinting + """
					|		ELSE "			+ FieldName + "
					|	END ";
					
				// An ordering expression.
				// Analytics <other> should go after analytics with filled values.
				OrderField = SetField.OrderExpressions.Add();
				OrderField.OrderType = DataCompositionSortDirection.Asc;
				OrderField.Expression = 
					"CASE
					|	WHEN STRING IN (&"	+ ParameterName + ")
					|		AND NOT ValueIsFilled(" + FieldName + ")
					|		THEN 1
					|		ELSE 0
					|	END ";
				
				OrderField = SetField.OrderExpressions.Add();
				OrderField.OrderType	= DataCompositionSortDirection.Asc;
				OrderField.Expression			= FieldName;
				OrderField.AutoOrder	= True;
			EndIf;
		EndIf;
		
	EndDo;
		
	For Each Periodicity In ColumnDescriptionStructure.Periodicity_ Do
		PeriodName = FinancialReportingClientServer.PeriodStrings(Periodicity).Period;
		FieldTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kỳ (%1)';
				|ru = 'Период (%1)';
				|en = 'Period (%1)'; fa = 'Period (%1)';
				|it = 'Periodo (%1)';
				|pl = 'Okres (%1)';
				|tr = 'Dönem (%1)'"),
			Periodicity);
		FinReports.NewSetField(Set, PeriodName, , FieldTitle);
	EndDo;
	
	FinReports.NewSetField(Set, "Sum");
	FinReports.NewSetField(Set, "SumCurr");
	FinReports.NewSetField(Set, "Count");
	FinReports.NewSetField(Set, "Value");
	
	GroupingPrintedForm = Undefined;
	For Each Dimension In ColumnsByDimension.Dimensions Do
		If GroupingPrintedForm = Undefined Then
			GroupingPrintedForm = FinReports.NewGrouping(DCS.DefaultSettings.Structure, Dimension);
		Else
			FinReports.NewDimensionField(GroupingPrintedForm, Dimension);
		EndIf;
		If ForPrinting <> Undefined Then
			FinReports.NewOrder(DCS.DefaultSettings, Dimension);
		EndIf;
	EndDo;
	
	If GroupingPrintedForm = Undefined Then
		FinReports.NewGrouping(DCS.DefaultSettings.Structure);
	ElsIf ForPrinting Then
		GroupingPrintedForm = FinReports.NewGrouping(DCS.DefaultSettings.Structure); // DataCompositionGroup -
		GroupingPrintedForm.Selection.Items.Clear();
	EndIf;
	
	If ForPrinting And Not IsBlankString(BudgetProfileDisplayParameters.TitleResponsible) Then
		FinReports.SetParameter(DCS.DefaultSettings.Structure[0].OutputParameters,
			"Title", BudgetProfileDisplayParameters.TitleResponsible);
	EndIf;	
	
	FinReports.NewFilter(DCS.DefaultSettings.Filter, "MainItem", True);
	Filter = FinReports.NewFilter(DCS.DefaultSettings.Filter, "String", ColumnsByDimension.BaseLines);
	Filter.ComparisonType = DataCompositionComparisonType.InList;
	
	ParametersForCreatingFields = TemplateForParametersForCreatingFieldsInColumnTree();
	ParametersForCreatingFields.ColumnTree = ColumnTree;
	ParametersForCreatingFields.ColumnsByDimension = ColumnsByDimension;
	ParametersForCreatingFields.AddingElements  = DCS.DefaultSettings.Selection.Items;
	
	TreeDepth = CreateSelectionFieldsByColumnTree(DCS, ParametersForCreatingFields);
	
	FinReports.SetOutputParameter(DCS.DefaultSettings,
		"HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCS.DefaultSettings,
		"VerticalOverallPlacement", DataCompositionTotalPlacement.None);
	FinReports.SetOutputParameter(DCS.DefaultSettings,
		"FilterOutput", DataCompositionTextOutputType.DontOutput);
	FinReports.SetOutputParameter(DCS.DefaultSettings,
		"OutputParameters_", DataCompositionTextOutputType.DontOutput);
	
	DSCParameter = DCS.Parameters.Add();
	DSCParameter.Name = "ForPrinting";
	DSCParameter.ValueType = New TypeDescription("Boolean");
	DSCParameter.Value = ForPrinting;
	DSCParameter.UseRestriction = True;
	
	FinReports.NewOrder(DCS.DefaultSettings, "MinimumNumberInOrder");
	
	If ForPrinting And Not IsBlankString(BudgetProfileDisplayParameters.ReportHeader) Then
		FinReports.SetParameter(DCS.DefaultSettings.OutputParameters,
			"Title", BudgetProfileDisplayParameters.ReportHeader);
	EndIf;	
	
	Return DCS;
	
EndFunction

Function GetRequestForReportOutputData(ObjectsArray)
	
	Query = New Query;
	Query.Text = "SELECT
		|	BudgetEntryForm.Ref AS Ref,
		|	BudgetEntryForm.Number AS DocumentNumber,
		|	BudgetEntryForm.Date AS DocumentDate,
		|	BudgetEntryForm.BudgetingModel AS BudgetingModel,
		|	BudgetEntryForm.BudgetingModel.BudgetsByCompanies AS BudgetsByCompanies,
		|	BudgetEntryForm.BudgetingModel.BudgetsByBusinessUnits AS BudgetsByBusinessUnits,
		|	BudgetEntryForm.Organization AS Organization,
		|	BudgetEntryForm.Department AS Department,
		|	BudgetEntryForm.EmployeeResponsible.Presentation AS EmployeeResponsible,
		|	BudgetEntryForm.Scenario AS Scenario,
		|	BudgetEntryForm.Scenario.Currency AS ScenarioCurrency,
		|	BudgetEntryForm.BudgetProfile AS BudgetProfile,
		|	BudgetEntryForm.BudgetProfile.Presentation AS BudgetProfilePresentation,
		|	BudgetEntryForm.Action AS Action,
		|	BudgetEntryForm.BeginOfPeriod AS BeginOfPeriod,
		|	BudgetEntryForm.PeriodEnding AS PeriodEnding,
		|	BudgetEntryForm.ActualDataLimit AS ActualDataLimit,
		|	&TextAnalyst,
		|	BudgetEntryForm.BudgetProfile.HeaderDimensions AS HeaderDimensions,
		|	BudgetEntryForm.BudgetFlowItemsDimension AS BudgetFlowItemsDimension,
		|	BudgetEntryForm.BudgetFlowItemTurnovers AS BudgetFlowItemTurnovers,
		|	BudgetEntryForm.DimensionValues_ AS DimensionValues_
		|FROM
		|	Document.BudgetEntryForm AS BudgetEntryForm
		|WHERE
		|	BudgetEntryForm.Ref IN(&ObjectsArray)";
	
	TextAnalyst = "";
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextAnalyst = TextAnalyst + ?(TextAnalyst = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetEntryForm.Dimension%1 AS Dimension%1",
				DimensionNumber);
	EndDo;
	Query.Text = StrReplace(Query.Text, "&TextAnalyst", TextAnalyst);
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Return Query;
	
EndFunction

Function TemplateForParametersForCreatingFieldsInColumnTree()
	ParametersForCreatingFields = New Structure;
	
	// Required fields.
	ParametersForCreatingFields.Insert("ColumnTree");
	ParametersForCreatingFields.Insert("ColumnsByDimension");
	ParametersForCreatingFields.Insert("AddingElements");
	
	// Optional fields.
	ParametersForCreatingFields.Insert("GroupValues", Undefined);
	ParametersForCreatingFields.Insert("ForPrinting", False);
	
	Return ParametersForCreatingFields;
EndFunction

Function CreateSelectionFieldsByColumnTree(DCS, ParametersForCreatingFields, CurDepth = 1)
	
	ColumnTree = ParametersForCreatingFields.ColumnTree;
	ColumnsByDimension = ParametersForCreatingFields.ColumnsByDimension;
	AddingElements  = ParametersForCreatingFields.AddingElements; // DataCompositionSelectedFieldCollection
	GroupValues = ParametersForCreatingFields.GroupValues;
	
	FinReports = FinancialReportingServer;
	
	If GroupValues = Undefined Then
		GroupValues = New Structure;
	EndIf;
	
	LevelDepth = CurDepth;
	For Each TreeRow In ColumnTree.Rows Do
		
		InsertedKey = "";
		If ValueIsFilled(TreeRow.FixedValue) Then
			GroupValues.Insert(TreeRow.DimensionName, TreeRow.FixedValue);
			InsertedKey = TreeRow.DimensionName;
		EndIf;
		
		ColumnValue = TreeRow.ReportItem;
		If StrFind(TreeRow.DimensionName, "#Factor_") Then
			IndicatorName = StrReplace(TreeRow.DimensionName, "#Factor_", "");
			GroupValues.Insert("IndicatorName", IndicatorName);
			InsertedKey = IndicatorName;
			If ValueIsFilled(TreeRow.Parent) Then
				ColumnValue = TreeRow.Parent.ReportItem;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(ColumnValue) Then
			ColumnValue = Catalogs.FinancialReportItems.EmptyRef();
		EndIf;
		
		If TreeRow.Rows.Count() Then
			
			Item = AddingElements.Add(Type("DataCompositionSelectedFieldGroup"));
			Item.Title = TreeRow.NameForPrinting;
			Item.Placement = DataCompositionFieldPlacement.Horizontally;
			
			ParametersForCreatingFields = TemplateForParametersForCreatingFieldsInColumnTree();
			ParametersForCreatingFields.ColumnTree = TreeRow;
			ParametersForCreatingFields.ColumnsByDimension = ColumnsByDimension;
			ParametersForCreatingFields.AddingElements = Item.Items;
			ParametersForCreatingFields.GroupValues = GroupValues;
			
			NewDepth = CreateSelectionFieldsByColumnTree(DCS,
					ParametersForCreatingFields,
					CurDepth + 1);
			LevelDepth = Max(LevelDepth, NewDepth);
			
		Else
			
			BudgetFlowItems = Undefined;
			If ColumnsByDimension.Property("BudgetFlowItems", BudgetFlowItems) Then
				// Cell parameters in a complex table.
				DetailsStructure1 = BudgetFlowItems[TreeRow.ReportItem];
				If DetailsStructure1 <> Undefined Then
					// There may not be an article on the level.
					IndicatorName = DetailsStructure1.IndicatorName;
					GroupValues.Insert("IndicatorName", IndicatorName);
				EndIf;
			EndIf;
			
			ResourceField = "";
			IndicatorName = "Sum";
			
			ParameterName = "Column_" + StrReplace(New UUID, "-", "_");
			ResourceField = "Column = &" + ParameterName;
			
			Parameter = DCS.Parameters.Find(ParameterName);
			If Parameter = Undefined Then
				Parameter = DCS.Parameters.Add();
				Parameter.Name = ParameterName;
				Parameter.Value = ColumnValue;
				Parameter.UseRestriction = True;
			EndIf;
			
			For Each KeyAndValue In GroupValues Do
				
				If KeyAndValue.Key = "IndicatorName" Then
					IndicatorName = KeyAndValue.Value;
					Continue;
				EndIf;
				
				ParameterName = KeyAndValue.Key + "_" + StrReplace(New UUID, "-", "_");
				ResourceField = ResourceField + " And " + KeyAndValue.Key + " = &" + ParameterName;
				
				Parameter = DCS.Parameters.Find(ParameterName);
				If Parameter = Undefined Then
					Parameter = DCS.Parameters.Add();
					Parameter.Name = ParameterName;
					Parameter.Value = KeyAndValue.Value;
					Parameter.UseRestriction = True;
				EndIf;
				
			EndDo;
			
			IndicatorExpression = IndicatorName;
			If IndicatorName = "Sum" Then
				IndicatorExpression = "CASE WHEN VALUETYPE(Sum) = TYPE(""Number"") THEN Sum ELSE 0 END";
				If DCS.DataSets.CellData_.Fields.Find("Currency") <> Undefined Then
					IndicatorExpression = "CASE 
									|	WHEN ValueIsFilled(Currency) 
									|	THEN CASE WHEN VALUETYPE(SumCurr) = TYPE(""Number"") THEN SumCurr ELSE 0 END
									|	ELSE CASE WHEN VALUETYPE(Sum) = TYPE(""Number"") THEN Sum ELSE 0 END 
									|END";
				EndIf;
				IndicatorExpression = "CASE 
									|	WHEN &ForPrinting = FALSE AND ISNULL(ReverseSign, FALSE) = TRUE 
									|	THEN -1 
									|	ELSE 1 
									|END * " + IndicatorExpression;
			EndIf;
			
			If IndicatorName = "Value" Then
				ResourceField = "MIN(CASE WHEN " + ResourceField + " THEN " + IndicatorExpression + " END)";
			Else
				ResourceField = "SUM(CASE WHEN " + ResourceField + " THEN " + IndicatorExpression + " END)";
			EndIf;
			
			FieldName = "Resource_" + StrReplace(New UUID, "-", "_");
			FinReports.NewCalculatedResource(DCS,
					FieldName,,,
					ResourceField);
			
			Item = AddingElements.Add(Type("DataCompositionSelectedField"));
			Item.Title = TreeRow.NameForPrinting;
			Item.Field = New DataCompositionField(FieldName);
			
		EndIf;
		
		If Not IsBlankString(InsertedKey) Then
			GroupValues.Delete(InsertedKey);
		EndIf;
		
	EndDo;
	
	Return LevelDepth;
	
EndFunction

Function CompositionOfRootElementColumns(CurrentRow, ParametersList, ColumnsByDimension) Export
	
	ItemArray = GetParametersOfSubordinateRows(CurrentRow, ParametersList, ColumnsByDimension);
	
	For Cnt = 1 To ItemArray.UBound() Do
		If ItemArray[Cnt] = Undefined
			Or ItemArray[Cnt-1] = Undefined Then
			Return False;
		EndIf;
		Value1 = StrConcat(ItemArray[Cnt].Dimensions, ",");
		Value2 = StrConcat(ItemArray[Cnt-1].Dimensions, ",");
		If Value1 <> Value2 Then
			Return False;
		EndIf;
		If ItemArray[Cnt].Property("BudgetFlowItems") Then
			For Each KeyAndValue In ItemArray[Cnt].BudgetFlowItems Do
				If ItemArray[Cnt-1].BudgetFlowItems[KeyAndValue.Key].BudgetFlowItem <> KeyAndValue.Value.BudgetFlowItem
					Or ItemArray[Cnt-1].BudgetFlowItems[KeyAndValue.Key].IndicatorName <> KeyAndValue.Value.IndicatorName Then
					Return False;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If ColumnsByDimension = Undefined Then
		Return False;
	EndIf;
	
	BudgetFlowItems = Undefined;
	ColumnsByDimension.Property("BudgetFlowItems", BudgetFlowItems);
	
	CopyOfMeasurementColumn = New Structure();
	CopyOfMeasurementColumn.Insert("Dimensions", ColumnsByDimension.Dimensions);
	CopyOfMeasurementColumn.Insert("ColumnSettings", ColumnsByDimension.ColumnSettings);
	CopyOfMeasurementColumn.Insert("InputSettings", New Structure);
	CopyOfMeasurementColumn.Insert("BaseLines", New Array);
	
	ColumnsByDimension = CopyOfMeasurementColumn;
	
	If BudgetFlowItems <> Undefined Then
		ColumnsByDimension.Insert("BudgetFlowItems", BudgetFlowItems);
	EndIf;
	
	For Each SettingItem In ColumnsByDimension.Dimensions Do
		
		ResultingList_ = New ValueList;
		For Each ArrayElement In ItemArray Do
			Values = ArrayElement.InputSettings[SettingItem];
			If Values = Undefined Then
				ResultingList_ = Undefined;
				Break;
			Else
				For Each ListItem In Values Do
					If ResultingList_.FindByValue(ListItem.Value) = Undefined Then
						ResultingList_.Add(ListItem.Value, ListItem.Presentation);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
		ColumnsByDimension.InputSettings.Insert(SettingItem, ResultingList_);
		
	EndDo;
	
	For Each ArrayElement In ItemArray Do
		CommonClientServer.SupplementArray(ColumnsByDimension.BaseLines,
				ArrayElement.BaseLines,
				True);
	EndDo;
	
	Return True;
	
EndFunction

// LongDesc
// 
// Parameters:
// 	CurrentRow - FormDataTreeItem, ValueTree - LongDesc:
// 		* String  - Arbitrary -
// 		* Column - Arbitrary -
// 		* Item - Arbitrary -
// 	ParametersList - Map -
// 	ColumnsByDimension - Structure - LongDesc
// Returns:
// 	Array of Structure - LongDesc
Function GetParametersOfSubordinateRows(CurrentRow, ParametersList, ColumnsByDimension)
	
	ItemArray = New Array();
	
	If TypeOf(CurrentRow) = Type("FormDataTreeItem") Then
		SubordinateRows = CurrentRow.GetItems();
	Else
		SubordinateRows = CurrentRow.Rows;
	EndIf;
	
	For Each SubordinateRow In SubordinateRows Do
		
		ColumnsByCurRowDimensions = ParametersList[SubordinateRow.String];
		If Not ColumnsByCurRowDimensions = Undefined Then
			ColumnsByDimension = ColumnsByCurRowDimensions;
			ItemArray.Add(ColumnsByDimension);
		EndIf;
		
		AdditionalArrayOfElements = GetParametersOfSubordinateRows(SubordinateRow,
				ParametersList,
				ColumnsByDimension);
		CommonClientServer.SupplementArray(ItemArray, AdditionalArrayOfElements);
		
	EndDo;
	
	Return ItemArray;
	
EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = ReportsCommands.Add();
	
	ReportCommand.FormName = "Document.BudgetEntryForm.Form.BudgetAdjustmentsAndCorrections";
	ReportCommand.Presentation = NStr("vi = 'Điều chỉnh và chỉnh sửa ngân sách';
										|ru = 'Корректировки и исправления бюджета';
										|en = 'Budget adjustments and corrections'; fa = 'تعدیلات و اصلاحات بودجه';
										|it = 'Корректировки и исправления бюджета';
										|pl = 'Budget adjustments and corrections';
										|tr = 'Bütçe değiştirme ve düzeltme'");
	
	ReportCommand.MultipleChoice = False;
	ReportCommand.Importance = "Ordinary";
	ReportCommand.VariantKey = "BudgetAdjustmentsAndCorrections";
	ReportCommand.IsNonContextual = False;
	ReportCommand.WriteMode = "Post";
	
EndProcedure

#EndRegion

#EndIf
