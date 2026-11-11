#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	OtherIncomeExpensesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.OtherIncomeExpenses") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextOtherIncome(Query, QueryTexts, Registers);
		QueryTextOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		
		OtherIncomeExpensesLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
	OtherIncomeExpensesLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the document "Reflection of other income and expenses".
//
// Parameters:
//  GenerationCommands - ValueTable - The description in the creation of the base is undefined.Before adding a command to create a base
//
// Returns:
// 	ValueTableRow - The description in the creation of the base is undefined.Before adding a command to create a base.Teamsreferences 
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.OtherIncomeExpenses) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.OtherIncomeExpenses.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.OtherIncomeExpenses);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAccountingOfOtherIncomeExpenses";
		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	OtherIncomeExpensesLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Currency");
	ArrayOfAllProps.Add("CompanyRecipient");
	
	ArrayOfAllProps.Add("OtherExpenses.CorExpenseItem");
	ArrayOfAllProps.Add("OtherExpenses.CorExpenditureDimension");
	ArrayOfAllProps.Add("OtherExpenses.AssetAndLiabilityItem");
	ArrayOfAllProps.Add("OtherExpenses.AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("OtherExpenses.PresentationOfRecordingInComplAccounting");
	
	ArrayOfAllProps.Add("OtherIncome.CorIncomeItem");
	ArrayOfAllProps.Add("OtherIncome.CorIncomeDimension");
	ArrayOfAllProps.Add("OtherIncome.AssetAndLiabilityItem");
	ArrayOfAllProps.Add("OtherIncome.AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("OtherIncome.PresentationOfRecordingInComplAccounting");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.OtherExpenses Then
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("OtherExpenses.AssetAndLiabilityItem");
		ArrayOfOperationDetails.Add("OtherExpenses.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("OtherExpenses.PresentationOfRecordingInComplAccounting");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.WriteOffOtherExpenses
			Or BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherExpenses Then
		ArrayOfOperationDetails.Add("OtherExpenses.AssetAndLiabilityItem");
		ArrayOfOperationDetails.Add("OtherExpenses.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("OtherExpenses.PresentationOfRecordingInComplAccounting");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ExpenseReclassification Then
		ArrayOfOperationDetails.Add("OtherExpenses.CorExpenseItem");
		ArrayOfOperationDetails.Add("OtherExpenses.CorExpenditureDimension");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OtherIncome Then
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("OtherIncome.AssetAndLiabilityItem");
		ArrayOfOperationDetails.Add("OtherIncome.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("OtherIncome.PresentationOfRecordingInComplAccounting");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherIncome Then
		ArrayOfOperationDetails.Add("OtherIncome.AssetAndLiabilityItem");
		ArrayOfOperationDetails.Add("OtherIncome.AssetsLiabilitiesDimension");
		ArrayOfOperationDetails.Add("OtherIncome.PresentationOfRecordingInComplAccounting");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.IncomeReclassification Then
		ArrayOfOperationDetails.Add("OtherIncome.CorIncomeItem");
		ArrayOfOperationDetails.Add("OtherIncome.CorIncomeDimension");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices Then
		ArrayOfOperationDetails.Add("CompanyRecipient");
		ArrayOfOperationDetails.Add("OtherExpenses.CorExpenseItem");
		ArrayOfOperationDetails.Add("OtherExpenses.CorExpenditureDimension");
		
	EndIf;
	
EndProcedure

// Fills in the table of remaining expenses for selection
//
// Parameters:
//	SelectionData_			 - Structure - fields that will be used to select balances for filling in the document
//		Data from the selection.Date-date - the cut-off date for which the remaining balances will be received
//		Data from the selection.Currency-Reference Link.Currency - the currency of the document
//		Data from the selection.Link-Document Link.Cost allocationprochie assets, Undefined-document that needs to be updated
//		Data from the selection.Organization-Reference Link.Organizations, Undefined - the Organization for which the balance will be selected
//	Expenses					 - FormDataCollection - the expense table that the data will be placed in.
//
Procedure GetBalancesOfOtherExpenses(SelectionData_, Expenses) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	// Selection parameters
	Query.SetParameter("Ref",			SelectionData_.Ref);
	Query.SetParameter("Organization",	SelectionData_.Organization);
	Query.SetParameter("Boundary",		New Boundary(EndOfDay(SelectionData_.Date), BoundaryType.Including));
	
	Query.Text =
	"SELECT
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.Department AS Department,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ExpenseItem AS ExpenseItem,
	|	NestedQuery.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(NestedQuery.Sum) AS Sum,
	|	SUM(NestedQuery.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(NestedQuery.SumMan) AS SumMan,
	|	SUM(NestedQuery.SumCompl) AS SumCompl,
	|	SUM(NestedQuery.SumCompl
	|		- NestedQuery.PermanentDifference
	|		- NestedQuery.CostTD) AS AmountFA,
	|	SUM(NestedQuery.PermanentDifference) AS PermanentDifference,
	|	SUM(NestedQuery.CostTD) AS CostTD,
	|	SUM(NestedQuery.AITAmount) AS AITAmount
	|FROM
	|	(SELECT
	|		Register.Organization AS Organization,
	|		Register.Department AS Department,
	|		Register.LineOfBusiness AS LineOfBusiness,
	|		Register.ExpenseItem AS ExpenseItem,
	|		Register.DimensionOfExpenses AS DimensionOfExpenses,
	|		Register.SumBalance AS Sum,
	|		Register.AmountExcludingVATBalance AS AmountExcludingVAT,
	|		Register.SumManBalance AS SumMan,
	|		Register.SumComplBalance AS SumCompl,
	|		Register.PermanentDifferenceBalance AS PermanentDifference,
	|		Register.CostTDBalance AS CostTD,
	|		Register.AITAmountBalance AS AITAmount
	|	FROM
	|		AccumulationRegister.OtherExpenses.Balance(&Boundary, Organization = &Organization) AS Register
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Register.Organization,
	|		Register.Department,
	|		Register.LineOfBusiness,
	|		Register.ExpenseItem,
	|		Register.DimensionOfExpenses,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.Sum
	|			ELSE -Register.Sum
	|		END,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.AmountExcludingVAT
	|			ELSE -Register.AmountExcludingVAT
	|		END AS AmountExcludingVAT,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.SumMan
	|			ELSE -Register.SumMan
	|		END AS SumMan,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.SumCompl
	|			ELSE -Register.SumCompl
	|		END,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.PermanentDifference
	|			ELSE -Register.PermanentDifference
	|		END,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.CostTD
	|			ELSE -Register.CostTD
	|		END,
	|		CASE
	|			WHEN Register.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN Register.AITAmount
	|			ELSE -Register.AITAmount
	|		END
	|	FROM
	|		AccumulationRegister.OtherExpenses AS Register
	|	WHERE
	|		Register.Recorder = &Ref
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Organization,
	|	NestedQuery.Department,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ExpenseItem,
	|	NestedQuery.DimensionOfExpenses
	|
	|HAVING
	|	SUM(NestedQuery.Sum) <> 0
	|		OR SUM(NestedQuery.AmountExcludingVAT) <> 0
	|		OR SUM(NestedQuery.SumMan) <> 0
	|		OR SUM(NestedQuery.SumCompl) <> 0
	|		OR SUM(NestedQuery.PermanentDifference) <> 0
	|		OR SUM(NestedQuery.CostTD) <> 0
	|		OR SUM(NestedQuery.AITAmount) > 0
	|
	|ORDER BY
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	ExpenseItem,
	|	DimensionOfExpenses";
	
	SamplingCosts = Query.Execute().Select();
	
	While SamplingCosts.Next() Do
		FillPropertyValues(Expenses.Add(), SamplingCosts);
	EndDo;
	
EndProcedure

// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return OtherIncomeExpensesLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return OtherIncomeExpensesLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpCorAccountToReflectOtherExpenses
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.OtherExpenses";
	SetupParameters.AssetAndLiabilityItem = "AssetAndLiabilityItem";
	SetupParameters.LedgerAccountSettingVersion = "LedgerAccountSettingVersion";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.AvailabilityByOperation =  
		(BusinessOperation = Enums.BusinessTransactions.OtherExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherExpenses
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffOtherExpenses);
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("ExpensesPresentationOfRecordingInComplAccounting");
	SetupParameters.FormItems.Add("ExpensesRepresentationOfTheReflectionInTheReglAccountingWithoutSplitting");
	SetupParameters.FormItems.Add("OtherExpensesPresentationOfRecordingInComplAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion

	#Region SettingUpCorAccountToReflectOtherIncome
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.OtherIncome";
	SetupParameters.AssetAndLiabilityItem = "AssetAndLiabilityItem";
	SetupParameters.LedgerAccountSettingVersion = "LedgerAccountSettingVersion";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.AvailabilityByOperation = 
		(BusinessOperation = Enums.BusinessTransactions.OtherIncome
		Or BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherIncome);
	
	SetupParameters.Organization = "Object.Organization";
	SetupParameters.FormItems.Add("IncomeRepresentationOfTheReflectionInTheReglAccounting");
	SetupParameters.FormItems.Add("RevenueRepresentationOfTheReflectionInTheReglAccountingWithoutSplitting");
	SetupParameters.FormItems.Add("OtherIncomePresentationOfRecordingInComplAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParametersArray = New Array;
	
	#Region OtherExpensesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.OtherExpenses";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("ItemOfExpenditureWithoutDivision");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("OtherExpensesDimensionOfExpenses");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAnalysisWithoutSplitting");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region OtherExpensesCorExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.OtherExpenses";
	ChoiceParameters.AssetRef = "CorExpenseItem";
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation = Enums.BusinessTransactions.ExpenseReclassification
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices);
		
	ChoiceParameters.RequiredFilling = (BusinessOperation = Enums.BusinessTransactions.ExpenseReclassification);
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "CorExpenditureDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("CorExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesCorExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("CorItemOfExpenditureWithoutDivision");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CorExpenditureDimension");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("OtherExpensesCorExpenditureDimension");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CorCostAnalysisWithoutSplitting");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region OtherExpensesAssetAndLiabilityItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.OtherExpenses";
	ChoiceParameters.AssetRef = "AssetAndLiabilityItem";
	ChoiceParameters.AvailabilityByOperation = 
		(BusinessOperation = Enums.BusinessTransactions.OtherExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherExpenses
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffOtherExpenses);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesItemOfAssetsLiabilitiesWithoutDivision");
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesAssetAndLiabilityItem");
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesAssetAndLiabilityItem");
	
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAnalysisOfAssetsLiabilitiesWithoutSplitting");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("OtherExpensesAssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAssetsLiabilitiesDimension");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region OtherIncomeIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.OtherIncome";
	ChoiceParameters.AssetRef = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("OtherIncomeIncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemWithoutDivision");
	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("OtherIncomeDimensionOfRevenue");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("RevenueAnalyticsWithoutPartitioning");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region OtherIncomeCorIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.OtherIncome";
	ChoiceParameters.AssetRef = "CorIncomeItem";
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation = Enums.BusinessTransactions.IncomeReclassification);
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "CorIncomeDimension";

	ChoiceParameters.FormItems.AssetRef.Add("CorIncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("OtherIncomeCorIncomeItem");
	ChoiceParameters.FormItems.AssetRef.Add("CorIncomeItemWithoutDivision");
	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("CorIncomeDimension");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("OtherIncomeCorIncomeDimension");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("CorRevenueAnalyticsWithoutPartitioning");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region OtherIncomeAssetAndLiabilityItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.OtherIncome";
	ChoiceParameters.AssetRef = "AssetAndLiabilityItem";
	ChoiceParameters.AvailabilityByOperation = 
		(BusinessOperation = Enums.BusinessTransactions.OtherIncome
		Or BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherIncome);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemOfAssetsLiabilities");
	ChoiceParameters.FormItems.AssetRef.Add("OtherIncomeAssetAndLiabilityItem");
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItemOfAssetsLiabilitiesWithoutDivision");
	
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("IncomeAssetLiabilityAnalysis");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("OtherIncomeAssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("IncomeAnalysisOfAssetsLiabilitiesWithoutSplitting");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion


#EndIf


#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If ValueIsFilled(Data.BusinessOperation) Then

		PresentationOperation = TransactionList().FindByValue(Data.BusinessOperation);
		If PresentationOperation <> Undefined Then
			PresentationOperation = PresentationOperation.Presentation;
		Else
			PresentationOperation = Data.BusinessOperation;
		EndIf;
		
		StandardProcessing = False;
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 %2 ngày %3';
				|ru = '%1 %2 от %3';
				|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
				|it = '%1 %2 del %3';
				|pl = '%1 %2 z dnia %3';
				|tr = '%3 tarihli %1 %2'"),
			PresentationOperation,
			Data.Number,
			Data.Date);
		
	EndIf;
		
EndProcedure

#EndRegion


#Region Other

Function TransactionList() Export
	
	OtherExpenses = PredefinedValue("Enum.BusinessTransactions.OtherExpenses");
	WriteOffOtherExpenses = PredefinedValue("Enum.BusinessTransactions.WriteOffOtherExpenses");
	ReversalOfOtherExpenses = PredefinedValue("Enum.BusinessTransactions.ReversalOfOtherExpenses");
	ExpenseReclassification = PredefinedValue("Enum.BusinessTransactions.ExpenseReclassification");
	TransferOfOtherExpensesBetweenBranchOffices = PredefinedValue("Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices");
	OtherIncome = PredefinedValue("Enum.BusinessTransactions.OtherIncome");
	ReversalOfOtherIncome = PredefinedValue("Enum.BusinessTransactions.ReversalOfOtherIncome");
	IncomeReclassification = PredefinedValue("Enum.BusinessTransactions.IncomeReclassification");

	TransactionList = New ValueList;
	
	TransactionList.Add(OtherExpenses, NStr("vi = 'Ghi nhận chi phí';
											|ru = 'Регистрация расходов';
											|en = 'Expense registration'; fa = 'ثبت هزینه';
											|it = 'Registrazione delle spese';
											|pl = 'Rejestracja wydatków';
											|tr = 'Giderlerin kayıtları'"));
	TransactionList.Add(WriteOffOtherExpenses, NStr("vi = 'Ghi giảm chi phí';
													|ru = 'Списание расходов';
													|en = 'Expense write-off'; fa = 'اسقاط هزینه';
													|it = 'Storno delle spese';
													|pl = 'Wyksięgowanie wydatków';
													|tr = 'Giderlerin silinmesi'"));
	TransactionList.Add(ReversalOfOtherExpenses, NStr("vi = 'Đảo ngược chi phí';
														|ru = 'Сторнирование расходов';
														|en = 'Expense reversal'; fa = 'برگشت هزینه';
														|it = 'Storno di spese';
														|pl = 'Stornowanie wydatków';
														|tr = 'Giderlerin iptali'"));
	TransactionList.Add(ExpenseReclassification, NStr("vi = 'Phân loại lại chi phí';
														|ru = 'Реклассификация расходов';
														|en = 'Expense reclassification'; fa = 'تغییر طبقه هزینه';
														|it = 'Riclassificazione delle entrate';
														|pl = 'Ponowna klasyfikacja wydatków';
														|tr = 'Giderlerin tekrar sınıflandırılması'"));
	
	TransactionList.Add(OtherIncome, NStr("vi = 'Ghi nhận thu nhập';
											|ru = 'Регистрация доходов';
											|en = 'Income registration'; fa = 'ثبت درآمد';
											|it = 'Registrazione dei ricavi';
											|pl = 'Rejestracja dochodów';
											|tr = 'Gelirlerin kayıtları'"));
	TransactionList.Add(ReversalOfOtherIncome, NStr("vi = 'Thu nhập đảo ngược';
													|ru = 'Сторнирование доходов';
													|en = 'Income reversal'; fa = 'برگشت درآمد';
													|it = 'Storno dei ricavi';
													|pl = 'Stornowanie dochodów';
													|tr = 'Gelirlerin iptali'"));
	TransactionList.Add(IncomeReclassification, NStr("vi = 'Phân loại lại thu nhập';
													|ru = 'Реклассификация доходов';
													|en = 'Income reclassification'; fa = 'تغییر طبقه درآمد';
													|it = 'Riclassificazione dei ricavi';
													|pl = 'Ponowna klasyfikacja dochodów';
													|tr = 'Gelirlerin tekrar sınıflandırılması'"));
	
	TransactionList.Add(TransferOfOtherExpensesBetweenBranchOffices, NStr("vi = 'Chuyển chi phí giữa các chi nhánh';
																			|ru = 'Передача расходов между филиалами';
																			|en = 'Expense transfer between branch offices'; fa = 'انتقال هزینه بین شعب';
																			|it = 'Trasferimento delle spese tra i file';
																			|pl = 'Przekazywanie wydatków pomiędzy filiami';
																			|tr = 'Şubeler arasında giderlerin transferi'"));
	
	Return TransactionList;

EndFunction

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                  AS Date,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.EmployeeResponsible         AS EmployeeResponsible,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.DeletionMark       AS DeletionMark,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.OtherIncomeExpenses AS DocumentData
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                          Attributes.Date);
	Query.SetParameter("Currency",                          Attributes.Currency);
	Query.SetParameter("Organization",                     Attributes.Organization);
	Query.SetParameter("CompanyRecipient",           Attributes.CompanyRecipient);
	Query.SetParameter("Number",                           Attributes.Number);
	Query.SetParameter("DeletionMark",                 Attributes.DeletionMark);
	Query.SetParameter("EmployeeResponsible",                   Attributes.EmployeeResponsible);
	Query.SetParameter("Posted",                        Attributes.Posted);
	Query.SetParameter("ManagementAccountingCurrency",      Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("BusinessOperation",           Attributes.BusinessOperation);
	Query.SetParameter("MetadataIdentifier",         Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting",                   ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	Query.SetParameter("BusinessTransactionSetting",  Attributes.BusinessTransactionSetting);
	
EndProcedure

Function QueryTextTTCurrencyConversionFactors(Query, QueryTexts)
	
	RegisterName = "TTCurrencyConversionFactors";
	
	SetQueryParameterTableCurrencyConversionFactors(Query);
	
	QueryText =
		"SELECT
		|	TTCurrencyConversionFactors.Period,
		|	TTCurrencyConversionFactors.ConversionRateToManCurrency,
		|	TTCurrencyConversionFactors.FactorOfConversionToCurrencyOfRegul
		|INTO TTCurrencyConversionFactors
		|FROM
		|	&TTCurrencyConversionFactors AS TTCurrencyConversionFactors";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetQueryParameterTableCurrencyConversionFactors(Query)
	
	RequestingCourses = New Query;
	RequestingCourses.Text =
		"SELECT DISTINCT
		|	ReflectionPeriods.Period AS Period
		|INTO TTPeriods
		|FROM
		|	(SELECT
		|		BEGINOFPERIOD(OtherExpenses.DateRecord, DAY) AS Period
		|	FROM
		|		Document.OtherIncomeExpenses.OtherExpenses AS OtherExpenses
		|	WHERE
		|		OtherExpenses.Ref = &Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BEGINOFPERIOD(OtherIncome.DateRecord, DAY)
		|	FROM
		|		Document.OtherIncomeExpenses.OtherIncome AS OtherIncome
		|	WHERE
		|		OtherIncome.Ref = &Ref) AS ReflectionPeriods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(ExchangeRates.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
		|	ISNULL(ExchangeRates.BaseCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS BaseCurrency,
		|	TTPeriods.Period AS Period,
		|	MAX(ISNULL(ExchangeRates.Period, DATETIME(1, 1, 1))) AS DateOfLastCourse
		|INTO TTDatesOfLastExchangeRates
		|FROM
		|	TTPeriods AS TTPeriods
		|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
		|		ON (ExchangeRates.Period <= TTPeriods.Period)
		|			AND (ExchangeRates.Currency = &CurrencyOfComplianceAccounting
		|				OR ExchangeRates.Currency = &CurrencyOfManAccounting
		|				OR ExchangeRates.Currency = &DocumentCurrency)
		|			AND (ExchangeRates.BaseCurrency = &CurrencyOfComplianceAccounting)
		|
		|GROUP BY
		|	TTPeriods.Period,
		|	ISNULL(ExchangeRates.Currency, VALUE(Catalog.Currencies.EmptyRef)),
		|	ISNULL(ExchangeRates.BaseCurrency, VALUE(Catalog.Currencies.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(CASE
		|			WHEN NOT ExchangeRates.Currency IS NULL
		|					AND ExchangeRates.Currency = &CurrencyOfComplianceAccounting
		|				THEN ExchangeRates.CourseNumerator
		|			ELSE 0
		|		END) AS LocalAccountingCourse,
		|	MAX(CASE
		|			WHEN NOT ExchangeRates.Currency IS NULL
		|					AND ExchangeRates.Currency = &CurrencyOfComplianceAccounting
		|				THEN ExchangeRates.CourseDenominator
		|			ELSE 0
		|		END) AS MultiplicityOfLocalAccounting,
		|	TTDatesOfLastExchangeRates.Period AS Period,
		|	MAX(CASE
		|			WHEN NOT ExchangeRates.Currency IS NULL
		|					AND ExchangeRates.Currency = &CurrencyOfManAccounting
		|				THEN ExchangeRates.CourseNumerator
		|			ELSE 0
		|		END) AS ManAccountingCourse,
		|	MAX(CASE
		|			WHEN NOT ExchangeRates.Currency IS NULL
		|					AND ExchangeRates.Currency = &CurrencyOfManAccounting
		|				THEN ExchangeRates.CourseDenominator
		|			ELSE 0
		|		END) AS MultiplicityOfManAccounting,
		|	MAX(CASE
		|			WHEN NOT ExchangeRates.Currency IS NULL
		|					AND ExchangeRates.Currency = &DocumentCurrency
		|				THEN ExchangeRates.CourseNumerator
		|			ELSE 0
		|		END) AS DocumentCourse,
		|	MAX(CASE
		|			WHEN NOT ExchangeRates.Currency IS NULL
		|					AND ExchangeRates.Currency = &DocumentCurrency
		|				THEN ExchangeRates.CourseDenominator
		|			ELSE 0
		|		END) AS DocumentMultiplicity
		|INTO TTExchangeRatesAsOfDate
		|FROM
		|	TTDatesOfLastExchangeRates AS TTDatesOfLastExchangeRates
		|		LEFT JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
		|		ON TTDatesOfLastExchangeRates.DateOfLastCourse = ExchangeRates.Period
		|			AND TTDatesOfLastExchangeRates.BaseCurrency = ExchangeRates.BaseCurrency
		|			AND TTDatesOfLastExchangeRates.Currency = ExchangeRates.Currency
		|
		|GROUP BY
		|	TTDatesOfLastExchangeRates.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTExchangeRatesAsOfDate.Period,
		|	CASE
		|		WHEN TTExchangeRatesAsOfDate.DocumentMultiplicity * TTExchangeRatesAsOfDate.ManAccountingCourse = 0
		|			THEN 1
		|		ELSE TTExchangeRatesAsOfDate.DocumentCourse * TTExchangeRatesAsOfDate.MultiplicityOfManAccounting / (TTExchangeRatesAsOfDate.DocumentMultiplicity * TTExchangeRatesAsOfDate.ManAccountingCourse)
		|	END AS ConversionRateToManCurrency,
		|	CASE
		|		WHEN TTExchangeRatesAsOfDate.DocumentMultiplicity * TTExchangeRatesAsOfDate.LocalAccountingCourse = 0
		|			THEN 1
		|		ELSE TTExchangeRatesAsOfDate.DocumentCourse * TTExchangeRatesAsOfDate.MultiplicityOfLocalAccounting / (TTExchangeRatesAsOfDate.DocumentMultiplicity * TTExchangeRatesAsOfDate.LocalAccountingCourse)
		|	END AS FactorOfConversionToCurrencyOfRegul
		|FROM
		|	TTExchangeRatesAsOfDate AS TTExchangeRatesAsOfDate";

	RequestingCourses.SetParameter("Ref", Query.Parameters.Ref);
	RequestingCourses.SetParameter("DocumentCurrency", Query.Parameters.Currency);
	RequestingCourses.SetParameter("CurrencyOfManAccounting",  Constants.ManagementAccountingCurrency.Get());
	RequestingCourses.SetParameter("CurrencyOfComplianceAccounting", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
					Common.ObjectAttributeValue(Query.Parameters.Ref, "Organization")));
	
	Query.SetParameter("TTCurrencyConversionFactors", RequestingCourses.Execute().Unload());
	
EndProcedure

Function QueryTextTTDataCosts(Query, QueryTexts) Export
	
	RegisterName = "TTDataCosts";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;	
	
	QueryTextOfAccountingPolicyForAIT = CalculationOfCostLocalization.AITSettingsQueryText("", "OtherIncomeExpenses_QueryTextTTTheseExpenses");
	QueryTexts.Add(QueryTextOfAccountingPolicyForAIT, RegisterName);
	
	QueryText = 
	"SELECT
	|	DocumentData.Organization                                 AS Organization,
	|	CASE WHEN DATEDIFF(DocumentDataExpenses.DateRecord, DocumentData.Date, DAY) = 0
	|				OR DocumentDataExpenses.DateRecord = DATETIME(1, 1, 1) THEN
	|		DocumentData.Date
	|	ELSE
	|		DocumentDataExpenses.DateRecord
	|	END                                                       AS Date,
	|	DocumentDataExpenses.LineNumber                          AS LineNumber,
	|
	|	DocumentDataExpenses.Department                        AS Department,
	|	DocumentDataExpenses.LineOfBusiness              AS LineOfBusiness,
	|	DocumentDataExpenses.ExpenseItem                       AS ExpenseItem,
	|	DocumentDataExpenses.DimensionOfExpenses                    AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN DocumentDataExpenses.DebitBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef) 
	|			THEN DocumentDataExpenses.DebitBusinessUnit
	|		ELSE DocumentDataExpenses.Department
	|	END                                                       AS DebitBusinessUnit,
	|	DocumentDataExpenses.CorLineOfBusiness           AS CorLineOfBusiness,
	|	CASE
	|		WHEN DocumentDataExpenses.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentDataExpenses.CorExpenseItem
	|		ELSE DocumentDataExpenses.ExpenseItem
	|	END                                                       AS CorExpenseItem,
	|	CASE
	|		WHEN DocumentDataExpenses.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentDataExpenses.CorExpenditureDimension
	|		ELSE DocumentDataExpenses.DimensionOfExpenses
	|	END                                                       AS CorExpenditureDimension,
	|
	|	DocumentDataExpenses.AssetAndLiabilityItem                AS AssetAndLiabilityItem,
	|	DocumentDataExpenses.AssetsLiabilitiesDimension             AS AssetsLiabilitiesDimension,
	|	DocumentDataExpenses.GLAccountSettings                 AS GLAccountSettings,
	|
	|	DocumentDataExpenses.Ref                               AS ExpenseReceiptDocument,
	|	ExpenseItems.EnteredInTaxAccounting                     AS EnteredInTaxAccounting,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses),
	|				VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses))
	|			THEN DocumentDataExpenses.Sum
	|		ELSE CAST(CAST(DocumentDataExpenses.Sum AS NUMBER(31, 2))
	|				* ISNULL(TTCurrencyConversionFactors.ConversionRateToManCurrency, 0) AS NUMBER(31, 2))
	|	END AS Sum,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses),
	|				VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses))
	|			THEN DocumentDataExpenses.AmountExcludingVAT
	|		ELSE CAST(CAST(DocumentDataExpenses.AmountExcludingVAT AS NUMBER(31, 2))
	|				* ISNULL(TTCurrencyConversionFactors.ConversionRateToManCurrency, 0) AS NUMBER(31, 2))
	|	END AS AmountExcludingVAT,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses),
	|				VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses))
	|			THEN DocumentDataExpenses.SumMan
	|		ELSE CAST(CAST(DocumentDataExpenses.SumMan AS NUMBER(31, 2))
	|				* ISNULL(TTCurrencyConversionFactors.ConversionRateToManCurrency, 0) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	DocumentDataExpenses.SumCompl AS SumCompl,
	|	CASE WHEN NOT &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses),
	|				VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices))
	|			AND NOT ExpenseItems.EnteredInTaxAccounting THEN
	|		DocumentDataExpenses.SumCompl - DocumentDataExpenses.CostTD
	|	ELSE
	|		DocumentDataExpenses.PermanentDifference
	|	END AS PermanentDifference,
	|	DocumentDataExpenses.CostTD AS CostTD,
	|	CASE 
	|		WHEN ISNULL(AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE)
	|			 AND (DocumentDataExpenses.CorExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				 OR ISNULL(CorItemsOfExpenditure.RecognizedInAITExpenses, FALSE))
	|			THEN DocumentDataExpenses.AITAmount
	|		ELSE 0
	|	END AS AITAmount,
	|
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices) 
 	|			AND NOT ISNULL(CorItemsOfExpenditure.EnteredInTaxAccounting, ExpenseItems.EnteredInTaxAccounting) THEN
	|		DocumentDataExpenses.SumCompl - DocumentDataExpenses.CostTD
	|	ELSE
	|		DocumentDataExpenses.PermanentDifference
	|	END AS CorAmountPD,
	|
	|
	|	DocumentDataExpenses.CostTD AS CorAmountTD,
	|
	|	DocumentDataExpenses.Sum               AS AmountInCurrency,
	|
	|	DocumentDataExpenses.RowID AS RowID
	|
	|INTO TTDataCosts
	|FROM
	|	Document.OtherIncomeExpenses.OtherExpenses AS DocumentDataExpenses
	|
	|	INNER JOIN
	|		Document.OtherIncomeExpenses AS DocumentData
	|	ON
	|		DocumentDataExpenses.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		DocumentDataExpenses.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS CorItemsOfExpenditure
	|	ON
	|		DocumentDataExpenses.CorExpenseItem = CorItemsOfExpenditure.Ref
	|
	|	LEFT JOIN 
	|		TTCurrencyConversionFactors AS TTCurrencyConversionFactors
	|	ON  
	|		BEGINOFPERIOD(DocumentDataExpenses.DateRecord, DAY) = TTCurrencyConversionFactors.Period
	|
	|	LEFT JOIN
	|		AITAccountingPolicy AS AITAccountingPolicy
	|	ON
	|		DocumentData.Organization = AITAccountingPolicy.Organization
	|
	|WHERE
	|	DocumentDataExpenses.Ref = &Ref
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OtherExpenses),
	|		VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses),
	|		VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses),
	|		VALUE(Enum.BusinessTransactions.ExpenseReclassification),
	|		VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices))";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataRevenue(Query, QueryTexts) Export
	
	RegisterName = "TTDataRevenue";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;	
	
	QueryText = 
	"SELECT
	|	DocumentData.Organization                      AS Organization,
	|	CASE WHEN DATEDIFF(DocumentDataIncome.DateRecord, DocumentData.Date, DAY) = 0
	|				OR DocumentDataIncome.DateRecord = DATETIME(1, 1, 1) THEN
	|		DocumentData.Date
	|	ELSE
	|		DocumentDataIncome.DateRecord
	|	END                                            AS Date,
	|	DocumentDataIncome.LineNumber                AS LineNumber,
	|
	|	DocumentDataIncome.Department              AS Department,
	|	DocumentDataIncome.LineOfBusiness    AS LineOfBusiness,
	|	DocumentDataIncome.IncomeItem              AS IncomeItem,
	|	DocumentDataIncome.DimensionOfRevenue           AS DimensionOfRevenue,
	|
	|	CASE 
	|		WHEN DocumentDataIncome.DebitBusinessUnit <> VALUE(Catalog.BusinessStructure.EmptyRef) 
	|			THEN DocumentDataIncome.DebitBusinessUnit
	|		ELSE DocumentDataIncome.Department
	|	END                                            AS DebitBusinessUnit,
	|	DocumentDataIncome.CorLineOfBusiness AS CorLineOfBusiness,
	|	CASE
	|		WHEN DocumentDataIncome.CorIncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN DocumentDataIncome.CorIncomeItem
	|		ELSE DocumentDataIncome.IncomeItem
	|	END                                            AS CorIncomeItem,
	|	CASE
	|		WHEN DocumentDataIncome.CorIncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN DocumentDataIncome.CorIncomeDimension
	|		ELSE DocumentDataIncome.DimensionOfRevenue
	|	END                                            AS CorIncomeDimension,
	|
	|	DocumentDataIncome.AssetAndLiabilityItem      AS AssetAndLiabilityItem,
	|	DocumentDataIncome.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	DocumentDataIncome.GLAccountSettings       AS GLAccountSettings,
	|
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IncomeReclassification),
	|				VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome))
	|			THEN DocumentDataIncome.Sum
	|		ELSE CAST(CAST(DocumentDataIncome.Sum AS NUMBER(31, 2))
	|				* ISNULL(TTCurrencyConversionFactors.ConversionRateToManCurrency, 0) AS NUMBER(31, 2))
	|	END AS Sum,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.IncomeReclassification),
	|				VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome))
	|			THEN DocumentDataIncome.SumMan
	|		ELSE
	|			CAST(CAST(DocumentDataIncome.SumMan AS NUMBER(31, 2))
	|				* ISNULL(TTCurrencyConversionFactors.ConversionRateToManCurrency, 0) AS NUMBER(31, 2))
	|	END AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN DocumentDataIncome.SumCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN DocumentDataIncome.PermanentDifference
	|		ELSE 0
	|	END AS PermanentDifference,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN DocumentDataIncome.CostTD
	|		ELSE 0
	|	END AS CostTD,
	|	DocumentDataIncome.Sum AS AmountInCurrency,
	|	DocumentDataIncome.RowID AS RowID
	|
	|INTO TTDataRevenue
	|FROM
	|	Document.OtherIncomeExpenses.OtherIncome AS DocumentDataIncome
	|		INNER JOIN Document.OtherIncomeExpenses AS DocumentData
	|		ON DocumentDataIncome.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTCurrencyConversionFactors AS TTCurrencyConversionFactors
	|		ON BEGINOFPERIOD(DocumentDataIncome.DateRecord, DAY) = TTCurrencyConversionFactors.Period
	|WHERE
	|	DocumentDataIncome.Ref = &Ref
	|	AND &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.OtherIncome),
	|			VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome),
	|			VALUE(Enum.BusinessTransactions.IncomeReclassification))";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.Department AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem AS ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|	TTDataCosts.AITAmount AS AITAmount,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting     AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.LineOfBusiness,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|	TTDataCosts.AITAmount AS AITAmount,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting     AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.LineOfBusiness,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|
	|	-TTDataCosts.Sum AS AmountIncludingVAT,
	|	-TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	-TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	-TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	-TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	-TTDataCosts.PermanentDifference AS PermanentDifference,
	|	-TTDataCosts.CostTD AS CostTD,
	|	-TTDataCosts.AITAmount AS AITAmount,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting     AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.LineOfBusiness,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|	TTDataCosts.AITAmount AS AITAmount,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting     AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseReclassification)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization,
	|	TTDataCosts.DebitBusinessUnit,
	|	TTDataCosts.CorLineOfBusiness,
	|	TTDataCosts.CorExpenseItem,
	|	TTDataCosts.CorExpenditureDimension,
	|	UNDEFINED AS VATActivityType,
	|
	|	-TTDataCosts.Sum AS AmountIncludingVAT,
	|	-TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	-TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	-TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	-TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	-TTDataCosts.CorAmountPD AS PermanentDifference,
	|	-TTDataCosts.CorAmountTD AS CostTD,
	|	-TTDataCosts.AITAmount AS AITAmount,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting     AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseReclassification)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	&CompanyRecipient,
	|	TTDataCosts.DebitBusinessUnit,
	|	TTDataCosts.CorLineOfBusiness,
	|	TTDataCosts.CorExpenseItem,
	|	TTDataCosts.CorExpenditureDimension,
	|	UNDEFINED AS VATActivityType,
	|
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	TTDataCosts.CorAmountPD AS PermanentDifference,
	|	TTDataCosts.CorAmountTD AS CostTD,
	|	TTDataCosts.AITAmount AS AITAmount,
	|	VALUE(Enum.BusinessTransactions.InternalExpenseReceipt) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.InternalExpenseReceipt) AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.LineOfBusiness,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|
	|	-TTDataCosts.Sum AS AmountIncludingVAT,
	|	-TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	-TTDataCosts.SumMan AS AmountExcludingVATMan,
	|	-TTDataCosts.SumCompl AS AmountIncludingVATCompl,
	|	-TTDataCosts.SumCompl AS AmountExcludingVATCompl,
	|	-TTDataCosts.PermanentDifference AS PermanentDifference,
	|	-TTDataCosts.CostTD AS CostTD,
	|	-TTDataCosts.AITAmount AS AITAmount,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting     AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	AdditionalFields = "";
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(AdditionalFields);
	
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	AdditionalFields = "";
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(AdditionalFields);
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	TTDataCosts.Date                        AS Period,
	|	TTDataCosts.Organization                 AS Organization,
	|	TTDataCosts.Department               AS Department,
	|	TTDataCosts.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	TTDataCosts.ExpenseItem              AS ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses           AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes        AS LotVendorAttributes,
	|	TTDataCosts.LineOfBusiness     AS LineOfBusiness,
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	UNDEFINED                                AS VATActivityType,
	|
	|	TTDataCosts.Sum                       AS Cost,
	|	TTDataCosts.AmountExcludingVAT                 AS CostExcludingVAT,
	|	0                                           AS VATManag,
	|	TTDataCosts.SumCompl                   AS LocalCost,
	|	TTDataCosts.PermanentDifference           AS PermanentDifference,
	|	TTDataCosts.CostTD            AS CostTD,
	|	0                                           AS VATLocal,
	|	&BusinessOperation                      AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE &BusinessTransactionSetting 
	|	END AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTDataCosts.Date,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	UNDEFINED AS ExpenseReceiptDocument,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes,
	|	TTDataCosts.LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	TTDataCosts.Sum,
	|	TTDataCosts.AmountExcludingVAT,
	|	0 AS VATManag,
	|	TTDataCosts.SumCompl,
	|	TTDataCosts.PermanentDifference,
	|	TTDataCosts.CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE &BusinessTransactionSetting 
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.ExpenseReceiptDocument,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes,
	|	TTDataCosts.LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	-TTDataCosts.Sum,
	|	-TTDataCosts.AmountExcludingVAT,
	|	0 AS VATManag,
	|	-TTDataCosts.SumCompl,
	|	-TTDataCosts.PermanentDifference,
	|	-TTDataCosts.CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE &BusinessTransactionSetting 
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.ExpenseReceiptDocument,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes,
	|	TTDataCosts.LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	TTDataCosts.Sum,
	|	TTDataCosts.AmountExcludingVAT,
	|	0 AS VATManag,
	|	TTDataCosts.SumCompl,
	|	TTDataCosts.PermanentDifference,
	|	TTDataCosts.CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE &BusinessTransactionSetting 
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseReclassification)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date,
	|	TTDataCosts.Organization,
	|	TTDataCosts.DebitBusinessUnit,
	|	UNDEFINED AS ExpenseReceiptDocument,
	|	TTDataCosts.CorExpenseItem,
	|	TTDataCosts.CorExpenditureDimension,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes,
	|	TTDataCosts.CorLineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	-TTDataCosts.Sum,
	|	-TTDataCosts.AmountExcludingVAT,
	|	0 AS VATManag,
	|	-TTDataCosts.SumCompl,
	|	-TTDataCosts.CorAmountPD AS PermanentDifference,
	|	-TTDataCosts.CorAmountTD AS CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE &BusinessTransactionSetting 
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseReclassification)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTDataCosts.Date,
	|	TTDataCosts.Organization,
	|	TTDataCosts.Department,
	|	TTDataCosts.ExpenseReceiptDocument,
	|	TTDataCosts.ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes,
	|	TTDataCosts.LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	TTDataCosts.Sum,
	|	TTDataCosts.AmountExcludingVAT,
	|	0 AS VATManag,
	|	TTDataCosts.SumCompl,
	|	TTDataCosts.PermanentDifference,
	|	TTDataCosts.CostTD,
	|	0 AS VATLocal,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE &BusinessTransactionSetting 
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Date,
	|	&CompanyRecipient,
	|	TTDataCosts.DebitBusinessUnit,
	|	TTDataCosts.ExpenseReceiptDocument,
	|	TTDataCosts.CorExpenseItem,
	|	TTDataCosts.CorExpenditureDimension,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TTDataCosts.LotVendorAttributes,
	|	TTDataCosts.CorLineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	UNDEFINED AS VATActivityType,
	|	TTDataCosts.Sum,
	|	TTDataCosts.AmountExcludingVAT,
	|	0 AS VATManag,
	|	TTDataCosts.SumCompl,
	|	TTDataCosts.PermanentDifference,
	|	TTDataCosts.CostTD,
	|	0 AS VATLocal,
	|	VALUE(Enum.BusinessTransactions.InternalExpenseReceipt) AS BusinessOperation,
	|
	|	CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN """" 
	|	     ELSE TTDataCosts.RowID 
	|	END AS FinRecordID,
	|	 CASE WHEN &CompanyRecipient <> TTDataCosts.Organization
	|		THEN UNDEFINED 
	|	     ELSE VALUE(Catalog.BusinessTransactionsSettings.InternalExpenseReceipt)  
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataRevenue", QueryTexts) Then
		QueryTextTTDataRevenue(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	TTDataRevenue.LineNumber             AS LineNumber,
	|	TTDataRevenue.Date                    AS Period,
	|	TTDataRevenue.Organization             AS Organization,
	|	TTDataRevenue.Department           AS Department,
	|	TTDataRevenue.LineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.IncomeItem           AS IncomeItem,
	|	TTDataRevenue.DimensionOfRevenue        AS DimensionOfRevenue,
	|	TTDataRevenue.Sum                   AS Sum,
	|	TTDataRevenue.SumCompl               AS SumCompl,
	|	TTDataRevenue.SumMan                AS SumMan,
	|	
	|	TTDataRevenue.RowID     AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting 
	|	
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherIncome)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.LineNumber             AS LineNumber,
	|	TTDataRevenue.Date                    AS Period,
	|	TTDataRevenue.Organization             AS Organization,
	|	TTDataRevenue.Department           AS Department,
	|	TTDataRevenue.LineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.IncomeItem           AS IncomeItem,
	|	TTDataRevenue.DimensionOfRevenue        AS DimensionOfRevenue,
	|	-TTDataRevenue.Sum                  AS Sum,
	|	-TTDataRevenue.SumCompl              AS SumCompl,
	|	-TTDataRevenue.SumMan               AS SumMan,
	|	
	|	TTDataRevenue.RowID     AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting 
	|	
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation  = VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.LineNumber             AS LineNumber,
	|	TTDataRevenue.Date                    AS Period,
	|	TTDataRevenue.Organization             AS Organization,
	|	TTDataRevenue.Department           AS Department,
	|	TTDataRevenue.LineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.IncomeItem           AS IncomeItem,
	|	TTDataRevenue.DimensionOfRevenue        AS DimensionOfRevenue,
	|	-TTDataRevenue.Sum                  AS Sum,
	|	-TTDataRevenue.SumCompl              AS SumCompl,
	|	-TTDataRevenue.SumMan               AS SumMan,
	|	
	|	TTDataRevenue.RowID     AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting 
	|	
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.IncomeReclassification)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.LineNumber                AS LineNumber,
	|	TTDataRevenue.Date                       AS Period,
	|	TTDataRevenue.Organization                AS Organization,
	|	TTDataRevenue.DebitBusinessUnit           AS Department,
	|	TTDataRevenue.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.CorIncomeItem           AS IncomeItem,
	|	TTDataRevenue.CorIncomeDimension        AS DimensionOfRevenue,
	|	TTDataRevenue.Sum                      AS Sum,
	|	TTDataRevenue.SumCompl                  AS SumCompl,
	|	TTDataRevenue.SumMan                   AS SumMan,
	|	
	|	TTDataRevenue.RowID        AS FinRecordID,
	|	&BusinessTransactionSetting           AS BusinessTransactionSetting 
	|	
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.IncomeReclassification)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataRevenue", QueryTexts) Then
		QueryTextTTDataRevenue(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	TTDataRevenue.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataRevenue.Organization AS Organization,
	|	TTDataRevenue.DebitBusinessUnit AS Department,
	|	TTDataRevenue.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.AssetAndLiabilityItem AS AssetRef,
	|	TTDataRevenue.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataRevenue.Sum AS Sum
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherIncome)
	|	AND TTDataRevenue.Sum <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataRevenue.Organization AS Organization,
	|	TTDataRevenue.DebitBusinessUnit AS Department,
	|	TTDataRevenue.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.AssetAndLiabilityItem AS AssetRef,
	|	TTDataRevenue.AssetsLiabilitiesDimension AS Dimension,
	|	-TTDataRevenue.Sum AS Sum
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome)
	|	AND TTDataRevenue.Sum <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	TTDataCosts.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataCosts.Sum AS Sum
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherExpenses)
	|	AND TTDataCosts.Sum <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	TTDataCosts.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataCosts.Sum AS Sum
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
	|	AND TTDataCosts.Sum <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	TTDataCosts.AssetsLiabilitiesDimension AS Dimension,
	|	-TTDataCosts.Sum AS Sum
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses)
	|	AND TTDataCosts.Sum <> 0
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataRevenue", QueryTexts) Then
		QueryTextTTDataRevenue(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	TTDataRevenue.Date AS Period,
	|	TTDataRevenue.Organization AS Organization,
	|	TTDataRevenue.DebitBusinessUnit AS Department,
	|	TTDataRevenue.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.AssetAndLiabilityItem AS AssetRef,
	|	TTDataRevenue.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataRevenue.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTDataRevenue.SumCompl AS SumCompl,
	|	TTDataRevenue.SumMan AS SumMan,
	|	TTDataRevenue.Sum AS AmountIncludingVAT,
	|	TTDataRevenue.Sum AS AmountExcludingVAT,
	|	TTDataRevenue.PermanentDifference AS PermanentDifference,
	|	TTDataRevenue.CostTD AS CostTD,
	|
	|	TTDataRevenue.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	TTDataRevenue.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherIncome)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0
	|		 OR TTDataRevenue.PermanentDifference <> 0 OR TTDataRevenue.CostTD <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.Date AS Period,
	|	TTDataRevenue.Organization AS Organization,
	|	TTDataRevenue.DebitBusinessUnit AS Department,
	|	TTDataRevenue.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.AssetAndLiabilityItem AS AssetRef,
	|	TTDataRevenue.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataRevenue.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	-TTDataRevenue.SumCompl AS SumCompl,
	|	-TTDataRevenue.SumMan AS SumMan,
	|	-TTDataRevenue.Sum AS AmountIncludingVAT,
	|	-TTDataRevenue.Sum AS AmountExcludingVAT,
	|	-TTDataRevenue.PermanentDifference AS PermanentDifference,
	|	-TTDataRevenue.CostTD AS CostTD,
	|
	|	TTDataRevenue.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	TTDataRevenue.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0
	|		 OR TTDataRevenue.PermanentDifference <> 0 OR TTDataRevenue.PermanentDifference <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	TTDataCosts.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataCosts.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTDataCosts.SumCompl AS SumCompl,
	|	TTDataCosts.SumMan AS SumMan,
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	TTDataCosts.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OtherExpenses)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0
	|		 OR TTDataCosts.PermanentDifference <> 0 OR TTDataCosts.CostTD <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	TTDataCosts.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataCosts.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTDataCosts.SumCompl AS SumCompl,
	|	TTDataCosts.SumMan AS SumMan,
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	TTDataCosts.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.AmountExcludingVAT <> 0 OR TTDataCosts.SumCompl <> 0 
	|		OR TTDataCosts.SumMan <> 0 OR TTDataCosts.PermanentDifference <> 0 OR TTDataCosts.CostTD <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	TTDataCosts.AssetsLiabilitiesDimension AS Dimension,
	|	TTDataCosts.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	-TTDataCosts.SumCompl AS SumCompl,
	|	-TTDataCosts.SumMan AS SumMan,
	|	-TTDataCosts.Sum AS AmountIncludingVAT,
	|	-TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	-TTDataCosts.PermanentDifference AS PermanentDifference,
	|	-TTDataCosts.CostTD AS CostTD,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	TTDataCosts.AssetAndLiabilityItem <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.AmountExcludingVAT <> 0 OR TTDataCosts.SumCompl <> 0 
	|		OR TTDataCosts.SumMan <> 0 OR TTDataCosts.PermanentDifference <> 0 OR TTDataCosts.CostTD <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.Organization AS Organization,
	|	TTDataCosts.Department AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
	|	&CompanyRecipient AS Dimension,
	|	UNDEFINED AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	TTDataCosts.SumCompl AS SumCompl,
	|	TTDataCosts.SumMan AS SumMan,
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|	AND TTDataCosts.Organization <> &CompanyRecipient
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.AmountExcludingVAT <> 0 OR TTDataCosts.SumCompl <> 0 
	|		OR TTDataCosts.SumMan <> 0 OR TTDataCosts.PermanentDifference <> 0 OR TTDataCosts.CostTD <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	&CompanyRecipient AS Organization,
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
	|	TTDataCosts.Organization AS Dimension,
	|	UNDEFINED AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	TTDataCosts.SumCompl AS SumCompl,
	|	TTDataCosts.SumMan AS SumMan,
	|	TTDataCosts.Sum AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT AS AmountExcludingVAT,
	|	TTDataCosts.PermanentDifference AS PermanentDifference,
	|	TTDataCosts.CostTD AS CostTD,
	|
	|	TTDataCosts.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.InternalExpenseReceipt) AS BusinessTransactionSetting
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|	AND TTDataCosts.Organization <> &CompanyRecipient
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.AmountExcludingVAT <> 0 OR TTDataCosts.SumCompl <> 0 
	|		OR TTDataCosts.SumMan <> 0 OR TTDataCosts.PermanentDifference <> 0 OR TTDataCosts.CostTD <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataRevenue", QueryTexts) Then
		QueryTextTTDataRevenue(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	TTDataRevenue.Date AS Period,
	|	TTDataRevenue.LineNumber,
	|	VALUE(Enum.BusinessTransactions.OtherIncomeAssetsLiabilities) AS BusinessOperation,
	|	TTDataRevenue.Organization AS Organization,
	|
	|	TTDataRevenue.Department AS Department,
	|	TTDataRevenue.LineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.IncomeItem AS AssetRef,
	|	TTDataRevenue.DimensionOfRevenue AS DimensionOfRevenue,
	|	NULL AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataRevenue.DebitBusinessUnit AS DebitBusinessUnit,
	|	TTDataRevenue.CorLineOfBusiness AS CorLineOfBusiness,
	|	TTDataRevenue.AssetAndLiabilityItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	NULL AS CorExpenditureDimension,
	|	TTDataRevenue.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataRevenue.Sum AS Sum,
	|	TTDataRevenue.SumMan AS SumMan,
	|	TTDataRevenue.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataRevenue.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherIncome)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|	
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.Date AS Period,
	|	TTDataRevenue.LineNumber,
	|	VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome) AS BusinessOperation,
	|	TTDataRevenue.Organization AS Organization,
	|
	|	TTDataRevenue.Department AS Department,
	|	TTDataRevenue.LineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.IncomeItem AS AssetRef,
	|	TTDataRevenue.DimensionOfRevenue AS DimensionOfRevenue,
	|	NULL AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataRevenue.DebitBusinessUnit AS DebitBusinessUnit,
	|	TTDataRevenue.CorLineOfBusiness AS CorLineOfBusiness,
	|	TTDataRevenue.AssetAndLiabilityItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	NULL AS CorExpenditureDimension,
	|	TTDataRevenue.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
	|
	|	-TTDataRevenue.Sum AS Sum,
	|	-TTDataRevenue.SumMan AS SumMan,
	|	-TTDataRevenue.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	-TTDataRevenue.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherIncome)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.LineNumber,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesLiabilities) AS BusinessOperation,
	|	TTDataCosts.Organization AS Organization,
	|
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	NULL AS DimensionOfRevenue,
	|	NULL AS DimensionOfExpenses,
	|	TTDataCosts.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	TTDataCosts.Department AS DebitBusinessUnit,
	|	TTDataCosts.LineOfBusiness AS CorLineOfBusiness,
	|	TTDataCosts.ExpenseItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	TTDataCosts.DimensionOfExpenses AS CorExpenditureDimension,
	|	NULL AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataCosts.Sum AS Sum,
	|	CASE
	|		WHEN TTDataCosts.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			TTDataCosts.SumMan
	|	END AS SumMan,
	|	TTDataCosts.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataCosts.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OtherExpenses)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.LineNumber,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesLiabilities) AS BusinessOperation,
	|	TTDataCosts.Organization AS Organization,
	|
	|	TTDataCosts.Department AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem AS AssetRef,
	|	NULL AS DimensionOfRevenue,
	|	TTDataCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataCosts.DebitBusinessUnit AS DebitBusinessUnit,
	|	TTDataCosts.CorLineOfBusiness AS CorLineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	NULL AS CorExpenditureDimension,
	|	TTDataCosts.AssetsLiabilitiesDimension AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataCosts.Sum AS Sum,
	|	CASE
	|		WHEN TTDataCosts.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			TTDataCosts.SumMan
	|	END AS SumMan,
	|	TTDataCosts.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataCosts.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOtherExpenses)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0)
	|	
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.LineNumber,
	|	VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses) AS BusinessOperation,
	|	TTDataCosts.Organization AS Organization,
	|
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.AssetAndLiabilityItem AS AssetRef,
	|	NULL AS DimensionOfRevenue,
	|	NULL AS DimensionOfExpenses,
	|	TTDataCosts.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	TTDataCosts.Department AS DebitBusinessUnit,
	|	TTDataCosts.LineOfBusiness AS CorLineOfBusiness,
	|	TTDataCosts.ExpenseItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	TTDataCosts.DimensionOfExpenses AS CorExpenditureDimension,
	|	NULL AS CorDimensionOfAssetsLiabilities,
	|
	|	-TTDataCosts.Sum AS Sum,
	|	CASE
	|		WHEN TTDataCosts.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			-TTDataCosts.SumMan
	|	END AS SumMan,
	|	-TTDataCosts.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	-TTDataCosts.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReversalOfOtherExpenses)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.LineNumber,
	|	&BusinessOperation AS BusinessOperation,
	|	TTDataCosts.Organization,
	|
	|	TTDataCosts.DebitBusinessUnit AS Department,
	|	TTDataCosts.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.CorExpenseItem AS AssetRef,
	|	NULL AS DimensionOfRevenue,
	|	TTDataCosts.CorExpenditureDimension AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataCosts.Department AS DebitBusinessUnit,
	|	TTDataCosts.LineOfBusiness AS CorLineOfBusiness,
	|	TTDataCosts.ExpenseItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	TTDataCosts.DimensionOfExpenses AS CorExpenditureDimension,
	|	NULL AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataCosts.Sum AS Sum,
	|	CASE
	|		WHEN TTDataCosts.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			TTDataCosts.SumMan
	|	END AS SumMan,
	|	TTDataCosts.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataCosts.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseReclassification)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0)
	|	
	|UNION ALL
	|
	|SELECT
	|	TTDataRevenue.Date AS Period,
	|	TTDataRevenue.LineNumber,
	|	&BusinessOperation AS BusinessOperation,
	|	TTDataRevenue.Organization,
	|
	|	TTDataRevenue.DebitBusinessUnit AS Department,
	|	TTDataRevenue.CorLineOfBusiness AS LineOfBusiness,
	|	TTDataRevenue.CorIncomeItem AS AssetRef,
	|	TTDataRevenue.CorIncomeDimension AS DimensionOfRevenue,
	|	NULL AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataRevenue.Department AS DebitBusinessUnit,
	|	TTDataRevenue.LineOfBusiness AS CorLineOfBusiness,
	|	TTDataRevenue.IncomeItem AS CorItem,
	|	TTDataRevenue.DimensionOfRevenue AS CorIncomeDimension,
	|	NULL AS CorExpenditureDimension,
	|	NULL AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataRevenue.Sum AS Sum,
	|	TTDataRevenue.SumMan AS SumMan,
	|	TTDataRevenue.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataRevenue.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataRevenue AS TTDataRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.IncomeReclassification)
	|	AND (TTDataRevenue.Sum <> 0 OR TTDataRevenue.SumCompl <> 0 OR TTDataRevenue.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.LineNumber,
	|	&BusinessOperation AS BusinessOperation,
	|	TTDataCosts.Organization AS Organization,
	|
	|	TTDataCosts.Department AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem AS AssetRef,
	|	NULL AS DimensionOfRevenue,
	|	TTDataCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataCosts.DebitBusinessUnit AS DebitBusinessUnit,
	|	TTDataCosts.CorLineOfBusiness AS CorLineOfBusiness,
	|	TTDataCosts.CorExpenseItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	TTDataCosts.CorExpenditureDimension AS CorExpenditureDimension,
	|	NULL AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataCosts.Sum AS Sum,
	|	CASE
	|		WHEN TTDataCosts.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			TTDataCosts.SumMan
	|	END AS SumMan,
	|	TTDataCosts.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataCosts.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	TTDataCosts.Date AS Period,
	|	TTDataCosts.LineNumber,
	|	VALUE(Enum.BusinessTransactions.InternalExpenseReceipt) AS BusinessOperation,
	|	&CompanyRecipient AS Organization,
	|
	|	TTDataCosts.Department AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem AS AssetRef,
	|	NULL AS DimensionOfRevenue,
	|	TTDataCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	NULL AS AssetsLiabilitiesDimension,
	|
	|	TTDataCosts.DebitBusinessUnit AS DebitBusinessUnit,
	|	TTDataCosts.CorLineOfBusiness AS CorLineOfBusiness,
	|	TTDataCosts.CorExpenseItem AS CorItem,
	|	NULL AS CorIncomeDimension,
	|	TTDataCosts.CorExpenditureDimension AS CorExpenditureDimension,
	|	NULL AS CorDimensionOfAssetsLiabilities,
	|
	|	TTDataCosts.Sum AS Sum,
	|	CASE
	|		WHEN TTDataCosts.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			TTDataCosts.SumMan
	|	END AS SumMan,
	|	TTDataCosts.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	TTDataCosts.AmountInCurrency AS AmountInCurrency
	|
	|FROM
	|	TTDataCosts AS TTDataCosts
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices)
	|	AND (TTDataCosts.Sum <> 0 OR TTDataCosts.SumCompl <> 0 OR TTDataCosts.SumMan <> 0)
	|	
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS BusinessOperation,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS Counterparty,
	|	UNDEFINED                            AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
	|	UNDEFINED                            AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	UNDEFINED                            AS Comment,
	|	&Currency                                 AS Currency,
	|	UNDEFINED                            AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	Return;
	OtherIncomeExpensesLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#EndRegion

#EndIf
