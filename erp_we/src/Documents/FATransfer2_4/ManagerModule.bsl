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
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	FATransferLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.FATransfer2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers);
		QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers);
		RequestTextTableOfMovementCompositionOfCGU(QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		FATransferLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	GetDocumentData(Query);

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	QueryTexts = New ValueList;
	
	QueryTextTableFACost(QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts);
	
	// Registers of information for which a slice of the last is used
	QueryTextTableInitialFixedAssetsInformation(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(QueryTexts, Undefined);
	QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	FATransferLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	
	FATransferLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command creation of the document "transfer of assets".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order	- Number - The order of the command.
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.FATransfer2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.FATransfer2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.FATransfer2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Order = Order;
		
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
	
	FATransferLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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

#EndRegion

#Region Internal

// Calculates the values of properties when changing the values of details.
// It is used in the document form and when checking the completion.
//
// Parameters:
//  Object					 - DocumentObject.FATransfer2_4, FormDataStructure - Document data.
//  ThereAreOwnFA        - Boolean - True if the document has its own OS.
//  ChangedBankingDetails		 - String - List of changed Bank details.
//
// Returns:
//  ValueTable - Contains new Attribute property values:
//					*AttributeName	- String	- Name of the item's details
//					*TagName	- String	- Name of the form element
//					*Property	- String	- Property, for example, "Visibility", " view Only"
//					*Value	- Boolean	- the value of the property.
//
Function PropertyValuesOfDependentProps(Object, ThereAreOwnFA, ChangedBankingDetails = "") Export

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("ThereAreOwnFA") 
		Or UpdateAll Then
		
		PropertyValue = 
			ThereAreOwnFA
			And Object.BusinessOperation <> Enums.BusinessTransactions.TransferSubAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DepreciationAccrual", 
			"DepreciationAccrual", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
	
		TMCommonUseClientServer.AddItemDetailsParameters(
			"TaxExpenseRecordingIsChanged", 
			"TaxExpenseRecordingIsChanged", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"RecipientLocationAddress", 
			"RecipientLocationAddress", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		              
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"PictureInformation", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"LabelDecoration", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
		
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("DepreciationAccrual")
		Or StructureOfChangedProps.Property("BusinessUnitAndLineOfBusinessMatchAccountingData")
		Or UpdateAll Then

		PropertyValue = 
			Object.DepreciationAccrual <> 1
			Or Object.BusinessUnitAndLineOfBusinessMatchAccountingData;

		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesBusinessUnit", 
			"ExpensesBusinessUnit", 
			"OnlyViewWithoutBlankMark", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseLineOfBusiness", 
			"ExpenseLineOfBusiness", 
			"ReadOnly", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or UpdateAll Then
		
		PropertyValue = 
			Object.BusinessOperation = Enums.BusinessTransactions.TransferSubAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FA.FixedAssetOwner", 
			"FAFixedAssetOwner", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"FAPrimaryFacilityOwnerCur", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.BusinessOperation <> Enums.BusinessTransactions.TransferSubAssets;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"FINANCIALLYLIABLEPERSON", 
			"FINANCIALLYLIABLEPERSON", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		//
		PropertyValue = 
			Object.BusinessOperation = Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"",
			"Organization", 
			"ItemVisibility", 
			Not PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"DeliveryCompany", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"CompanyRecipient", 
			"CompanyRecipient", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;
			
	If StructureOfChangedProps.Property("BusinessOperation") 
		Or StructureOfChangedProps.Property("ThereAreOwnFA") 
		Or StructureOfChangedProps.Property("DepreciationAccrual") 
		Or UpdateAll Then
			
		PropertyValue = 
			ThereAreOwnFA
			And Object.DepreciationAccrual = 1
			And Object.BusinessOperation <> Enums.BusinessTransactions.TransferSubAssets;
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesPostingMethod", 
			"ExpensesPostingMethod", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseItem", 
			"ExpenseItem", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"DimensionOfExpenses", 
			"DimensionOfExpenses", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpensesBusinessUnit", 
			"ExpensesBusinessUnit", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"ExpenseLineOfBusiness", 
			"ExpenseLineOfBusiness", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"BusinessUnitAndLineOfBusinessMatchAccountingData", 
			"BusinessUnitAndLineOfBusinessMatchAccountingData", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
		
	EndIf;

	FATransferLocalization.PropertyValuesOfDependentProps(Object, ThereAreOwnFA, StructureOfChangedProps, ItemDetailsParameters);
	
	Return ItemDetailsParameters;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.FATransfer2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("SenderInformation",  """""");
	RedefiningParameterCalculation.Insert("RecipientInformation", """""");
	
	RequestHasSource = True;
	TemporaryTableQueryTexts = New Map;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	EndIf;
				
	If QueryText = Undefined Then
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
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation,
										TemporaryTableQueryTexts);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);
	
	Query.Text =
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	DocumentData.Department AS Department,
	|	DocumentData.ReceivingBusinessUnit AS ReceivingBusinessUnit
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;

	Query.SetParameter("BorderInFrontOfDocument", New Boundary(Attributes.Period, BoundaryType.Excluding));

	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;

EndProcedure

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentsList
	|
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref                         AS Ref,
	|	DocumentData.Date                           AS Period,
	|	DocumentData.Number                          AS Number,
	|	DocumentData.Organization                    AS Organization,
	|	DocumentData.CompanyRecipient          AS CompanyRecipient,
	|	DocumentData.InventoryCustodianRecipient                  AS InventoryCustodianRecipient,
	|	DocumentData.EmployeeResponsible                  AS EmployeeResponsible,
	|	DocumentData.Comment                    AS Comment,
	|	DocumentData.Posted                       AS Posted,
	|	DocumentData.DeletionMark                AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting             AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting              AS RecordInManAccounting,
	|	DocumentData.DepreciationAccrual          AS AccrueDepreciationOrAmortization,
	|	DocumentData.ExpensesPostingMethod        AS ExpensesPostingMethod,
	|	DocumentData.ExpenseItem                 AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses              AS DimensionOfExpenses,
	|	DocumentData.ExpensesBusinessUnit          AS ExpensesBusinessUnit,
	|	DocumentData.ExpenseLineOfBusiness AS ExpenseLineOfBusiness,
	|	DocumentData.ExpenseItemForTax            AS ExpenseItemForTax,
	|	DocumentData.ExpensesDimensionTax         AS ExpensesDimensionTax,
	|	DocumentData.Department                  AS Department,
	|	DocumentData.ReceivingBusinessUnit        AS ReceivingBusinessUnit,
	|	DocumentData.BusinessOperation          AS BusinessOperation,
	|	DocumentData.DocumentBasis              AS DocumentBasis,
	|	DocumentData.FixedAssetsEvent                      AS FixedAssetsEvent,
	|	DocumentData.TaxExpenseRecordingIsChanged    AS TaxExpenseRecordingIsChanged,
	|	DocumentData.RecipientLocationAddress         AS LocationAddress,
	|	DocumentData.RecipientLocationAddressValue AS LocationAddressValue,
	|	DocumentData.CGURecipient AS CGURecipient,
	|
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.FixedAssetsCostTransferToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange)
	|	END AS HO_Cost_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetsCostFromAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange)
	|	END AS HO_Cost_Recipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.FixedAssetDepreciationTransferToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange)
	|	END AS HO_Depreciation_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetDepreciationFromAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange)
	|	END AS HO_Depreciation_Recipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost)
	|	END AS HO_CostRevaluationReserve_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost)
	|	END AS HO_CostRevaluationReserve_Recipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostTransferToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange)
	|	END AS SettingsHO_Cost_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferFixedAssetsCostFromAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsCostParameterChange)
	|	END AS SettingUpHO_Cost_Recipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationTransferToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange)
	|	END AS SetupHO_Depreciation_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferFixedAssetDepreciationFromAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange)
	|	END AS SettingHO_Depreciation_Recipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferFixedAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost)
	|	END AS SettingUpHO_ReserveForRevaluationOfCosts_Sender,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferFixedAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost)
	|	END AS SettingUpHO_ReserveForRevaluationOfCosts_Recipient
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAssetOwner AS FixedAssetOwner
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.FATransfer2_4.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FATransfer2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Điều chuyển TSCĐ hữu hình';
															|ru = 'Перемещение ОС';
															|en = 'Transfer fixed assets'; fa = 'انتقال دارایی‌های ثابت';
															|it = 'Trasferimento Capitale Fisso';
															|pl = 'Przemieszczenie środków trwałych';
															|tr = 'Sabit kıymet transferi'"));
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("Article6_ProfitLoss", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		NonCurrentAssetsInternal.SetValuesOfHoldingParametersWhenMoving(Attributes, ValuesOfHoldingParameters);
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)            AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.Date                            AS Date,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	&MetadataIdentifier                        AS RefType,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Posted                        AS Posted,
	|	FALSE                                            AS AdditionalRecord,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInTA,
	|	DocumentData.FixedAssetsEvent                       AS FixedAssetsEvent,
	|	FATable.FixedAsset                      AS FixedAsset
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|		LEFT JOIN Document.FATransfer2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(FATable.LineNumber-1, 0)            AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.Date                            AS Date,
	|	DocumentData.CompanyRecipient           AS Organization,
	|	DocumentData.ReceivingBusinessUnit         AS Department,
	|	&MetadataIdentifier                        AS RefType,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Posted                        AS Posted,
	|	TRUE                                          AS AdditionalRecord,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInTA,
	|	DocumentData.FixedAssetsEvent                       AS FixedAssetsEvent,
	|	FATable.FixedAsset                      AS FixedAsset
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|		LEFT JOIN Document.FATransfer2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.CompanyRecipient <> DocumentData.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(FATable.LineNumber-1, 0)            AS RecNo,
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.Date                            AS Date,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	&MetadataIdentifier                        AS RefType,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.Posted                        AS Posted,
	|	TRUE                                          AS AdditionalRecord,
	|	DocumentData.RecordInLocalAccounting              AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting               AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting              AS RecordInTA,
	|	DocumentData.FixedAssetsEvent                       AS FixedAssetsEvent,
	|	FATable.FixedAssetOwner              AS FixedAsset
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|		LEFT JOIN Document.FATransfer2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN Document.FATransfer2_4.FA AS FATable_
	|		ON FATable_.Ref = FATable.Ref
	|			AND FATable_.FixedAssetOwner = FATable.FixedAssetOwner
	|			AND FATable_.LineNumber < FATable.LineNumber
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferSubAssets)
	|	AND FATable.FixedAssetOwner <> VALUE(Catalog.Assets.EmptyRef)
	|	AND FATable_.Ref IS NULL
	|";	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	&RecipientInformation AS More,
	|	DocumentData.Date AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date   AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.Number,
	|	&MetadataIdentifier,
	|	DocumentData.CompanyRecipient,
	|	DocumentData.BusinessOperation,
	|	UNDEFINED,
	|	DocumentData.ReceivingBusinessUnit,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Comment,
	|	DocumentData.Posted,
	|	DocumentData.DeletionMark,
	|	TRUE,
	|	&SenderInformation,
	|	DocumentData.Date,
	|	&NumberForPrinting,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	DocumentData.Date,
	|	UNDEFINED AS Priority
	|
	|FROM
	|	Document.FATransfer2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.CompanyRecipient <> VALUE(Catalog.Companies.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|		THEN DocumentData.CompanyRecipient
	|		ELSE DocumentData.Organization
	|	END                                        AS Organization,
	|
	|	FATable.FixedAsset                   AS FixedAsset,
	|	DocumentData.InventoryCustodianRecipient                AS FinanciallyLiablePerson,
	|	DocumentData.ReceivingBusinessUnit      AS FixedAssetsLocation,
	|
	|	CASE
	|		WHEN DocumentData.LocationAddress <> """"
	|			THEN DocumentData.LocationAddress
	|		ELSE TTLocationOfFA.LocationAddress
	|	END AS LocationAddress,
	|
	|	CASE
	|		WHEN DocumentData.LocationAddress <> """"
	|			THEN DocumentData.LocationAddressValue
	|		ELSE TTLocationOfFA.LocationAddressValue
	|	END AS LocationAddressValue,
	|
	|	TTLocationOfFA.Leaseholder                      AS Leaseholder,
	|	TTLocationOfFA.LeaseholderBusinessUnit        AS LeaseholderBusinessUnit,
	|	TTLocationOfFA.LeaseholderEmployeeInCharge                  AS LeaseholderEmployeeInCharge,
	|
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS TTLocationOfFA
	|		ON TTLocationOfFA.Ref = FATable.Ref
	|			AND TTLocationOfFA.FixedAsset = FATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	
	QueryText = FATransferLocalization.QueryTextTableInitialFixedAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.CompanyRecipient AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.Counterparty AS Counterparty,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	InitialFixedAssetsInformation.DeregistrationDocumentMA AS DeregistrationDocumentMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
		|";
	
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	
	QueryText = FATransferLocalization.QueryTextTableAccountingProcedureForOSBU(QueryTexts);
	
	If QueryText = Undefined Then
	
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DocumentData.Organization AS Organization,
		|	FATable.FixedAsset AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS BUState,
		|
		|	FALSE AS DepreciationAccrualAccounting,
		|
		|	UNDEFINED AS ExpenseRecordMethodAC,
		|
		|	UNDEFINED AS ExpenseItemAccounting,
		|	UNDEFINED AS ExpensesDimensionAccounting,
		|	UNDEFINED AS DepartmentACC,
		|	UNDEFINED AS LineOfBusinessBookkeeping,
		|
		|	FALSE AS TransferExpensesToAnotherCompany,
		|	UNDEFINED AS CompanyRecipientOfExpenses,
		|
		|	UNDEFINED AS DepreciationRecordMethodLA,
		|
		|	AccountingProcedureForOSBU.VATTaxation AS VATTaxation
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTExtendedFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
		|		THEN DocumentData.CompanyRecipient
		|		ELSE DocumentData.Organization
		|	END AS Organization,
		|
		|	FATable.FixedAsset AS FixedAsset,
		|
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|
		|	CASE 
		|		WHEN DocumentData.AccrueDepreciationOrAmortization = 0 
		|			THEN AccountingProcedureForOSBU.DepreciationAccrualAccounting
		|		WHEN DocumentData.AccrueDepreciationOrAmortization = 1 
		|			AND (AccountingProcedureForOSBU.DepreciationAccrualAccounting
		|				OR InitialFixedAssetsInformation.AccountingProcedureAC IN (
		|					VALUE(Enum.FARepaymentProcedure.DepreciationAccrual),
		|					VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS DepreciationAccrualAccounting,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.ExpenseRecordMethodAC
		|		WHEN 1 THEN DocumentData.ExpensesPostingMethod
		|		WHEN 2 THEN UNDEFINED
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.ExpenseItemAccounting
		|		WHEN 1 THEN DocumentData.ExpenseItem
		|		WHEN 2 THEN UNDEFINED
		|	END AS ExpenseItemAccounting,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.ExpensesDimensionAccounting
		|		WHEN 1 THEN DocumentData.DimensionOfExpenses
		|		WHEN 2 THEN UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.DepartmentACC
		|		WHEN 1 THEN DocumentData.ExpensesBusinessUnit
		|		WHEN 2 THEN UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping
		|		WHEN 1 THEN DocumentData.ExpenseLineOfBusiness
		|		WHEN 2 THEN UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.TransferExpensesToAnotherCompany
		|		ELSE UNDEFINED
		|	END AS TransferExpensesToAnotherCompany,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.CompanyRecipientOfExpenses
		|		ELSE UNDEFINED
		|	END AS CompanyRecipientOfExpenses,
		|
		|	CASE DocumentData.AccrueDepreciationOrAmortization
		|		WHEN 0 THEN AccountingProcedureForOSBU.DepreciationRecordMethodLA
		|		ELSE UNDEFINED
		|	END AS DepreciationRecordMethodLA,
		|
		|	AccountingProcedureForOSBU.VATTaxation AS VATTaxation
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTExtendedFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND (DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
		|		OR DocumentData.AccrueDepreciationOrAmortization <> 0)
		|";
				
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	TTAccountingProcedureForOsuu.FixedAsset AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State,
	|	FALSE AS AccrueDepreciationOrAmortization,
	|	UNDEFINED AS ExpensesPostingMethod,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	TTAccountingProcedureForOsuu.DepreciationRecordMethod AS DepreciationRecordMethod,
	|	TTAccountingProcedureForOsuu.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	TTAccountingProcedureForOsuu.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|		THEN DocumentData.CompanyRecipient
	|		ELSE DocumentData.Organization
	|	END AS Organization,
	|
	|	TTAccountingProcedureForOsuu.FixedAsset AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.AccrueDepreciationOrAmortization
	|		WHEN 1 THEN TRUE
	|		WHEN 2 THEN FALSE
	|	END AS AccrueDepreciationOrAmortization,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.ExpensesPostingMethod
	|		WHEN 1 THEN DocumentData.ExpensesPostingMethod
	|		WHEN 2 THEN UNDEFINED
	|	END AS ExpensesPostingMethod,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.ExpenseItem
	|		WHEN 1 THEN DocumentData.ExpenseItem
	|		WHEN 2 THEN UNDEFINED
	|	END AS ExpenseItem,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.DimensionOfExpenses
	|		WHEN 1 THEN DocumentData.DimensionOfExpenses
	|		WHEN 2 THEN UNDEFINED
	|	END AS DimensionOfExpenses,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.Department
	|		WHEN 1 THEN DocumentData.ExpensesBusinessUnit
	|		WHEN 2 THEN UNDEFINED
	|	END AS Department,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.LineOfBusiness
	|		WHEN 1 THEN DocumentData.ExpenseLineOfBusiness
	|		WHEN 2 THEN UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.DepreciationRecordMethod
	|		ELSE UNDEFINED
	|	END AS DepreciationRecordMethod,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.TransferExpensesToAnotherCompany
	|		ELSE FALSE
	|	END AS TransferExpensesToAnotherCompany,
	|
	|	CASE DocumentData.AccrueDepreciationOrAmortization
	|		WHEN 0 THEN TTAccountingProcedureForOsuu.CompanyRecipientOfExpenses
	|		ELSE VALUE(Catalog.Companies.EmptyRef)
	|	END AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND (DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			OR DocumentData.AccrueDepreciationOrAmortization <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.CompanyRecipient AS Organization,
	|
	|	TTOsuuDepreciationParameters.FixedAsset AS FixedAsset,
	|	TTOsuuDepreciationParameters.UsefulLifeMonths AS UsefulLifeMonths,
	|	TTOsuuDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	TTOsuuDepreciationParameters.AccelerationFactor AS AccelerationFactor,
	|	TTOsuuDepreciationParameters.DepreciationMethod AS DepreciationMethod,
	|	TTOsuuDepreciationParameters.ResidualValueMan AS ResidualValueMan,
	|	TTOsuuDepreciationParameters.ResidualValueLocal AS ResidualValueLocal,
	|	TTOsuuDepreciationParameters.LastChangeDate AS LastChangeDate,
	|	TTOsuuDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	TTOsuuDepreciationParameters.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	TTOsuuDepreciationParameters.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS TTOsuuDepreciationParameters
	|		ON TTOsuuDepreciationParameters.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.RecordInManAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers)

	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.CompanyRecipient AS Organization,
	|	WDepreciationParametersOfOSBU.FixedAsset AS FixedAsset,
	|	WDepreciationParametersOfOSBU.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	WDepreciationParametersOfOSBU.UsefulLifeMonthsTA AS UsefulLifeMonthsTA,
	|	WDepreciationParametersOfOSBU.AnnualDepreciationRate AS AnnualDepreciationRate,
	|	WDepreciationParametersOfOSBU.AccelerationFactor AS AccelerationFactor,
	|	WDepreciationParametersOfOSBU.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	WDepreciationParametersOfOSBU.PermanentDifferencesUsedToCalculateDepreciation AS PermanentDifferencesUsedToCalculateDepreciation,
	|	WDepreciationParametersOfOSBU.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth,
	|	WDepreciationParametersOfOSBU.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationManag,
	|	WDepreciationParametersOfOSBU.CostForDepreciationCalculationTargetFinancing AS CostForDepreciationCalculationTargetFinancing,
	|	WDepreciationParametersOfOSBU.DepreciationSchedule AS DepreciationSchedule,
	|	WDepreciationParametersOfOSBU.SpecialFactor AS SpecialFactor,
	|	WDepreciationParametersOfOSBU.ResidualValueMan AS ResidualValueMan,
	|	WDepreciationParametersOfOSBU.LastChangeDate AS LastChangeDate
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN WDepreciationParametersOfOSBU AS WDepreciationParametersOfOSBU
	|		ON WDepreciationParametersOfOSBU.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.RecordInLocalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(QueryTexts)

	RegisterName = "FACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTLeasedFA(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.HO_Cost_Sender    AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	TTFAAccountingParameters.Leaseholder                AS Leaseholder,
	|
	|	FACost.Cost                       AS Cost,
	|	FACost.LocalCost                   AS LocalCost,
	|	FACost.CostInTaxAccounting                     AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                     AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                     AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                     AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                   AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                   AS CostTargetFinancingTD,
	|	FACost.DepreciationAllowance           AS DepreciationAllowance,
	|	FACost.TAExpenseAmountOfInvestmentTaxDeduction           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	FACost.SecurityDepositValue              AS SecurityDepositValue,
	|	FACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|	FACost.DisregardedCostTA        AS DisregardedCostTA,
	|	0                                           AS CostGainMA,
	|	0                                           AS CostGainLocal,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN DocumentData.CompanyRecipient
	|		ELSE UNDEFINED
	|	END                                       AS CorCompany,
	|
	|	DocumentData.ReceivingBusinessUnit     AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN NOT LeasedAsset.Counterparty IS NULL
	|			THEN LeasedAsset.Counterparty
	|		ELSE TTFAAccountingParameters.Leaseholder
	|	END AS CorCounterparty,
	|
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	DocumentData.SettingsHO_Cost_Sender AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS LeasedAsset
	|		ON LeasedAsset.Ref = FATable.Ref
	|			AND LeasedAsset.FixedAsset = FATable.FixedAsset
	|			AND LeasedAsset.State IN (
	|				VALUE(Enum.FixedAssetsStates.InLease),
	|				VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.HO_Cost_Recipient     AS BusinessOperation,
	|	DocumentData.CompanyRecipient       AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	DocumentData.ReceivingBusinessUnit     AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	TTFAAccountingParameters.Leaseholder                AS Leaseholder,
	|
	|	FACost.Cost                       AS Cost,
	|	FACost.LocalCost                   AS LocalCost,
	|	FACost.CostInTaxAccounting                     AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                     AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                     AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                     AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                   AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                   AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                   AS CostTargetFinancingTD,
	|	FACost.DepreciationAllowance           AS DepreciationAllowance,
	|	FACost.TAExpenseAmountOfInvestmentTaxDeduction           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	FACost.SecurityDepositValue              AS SecurityDepositValue,
	|	FACost.PreliminaryCostMan        AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal    AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve       AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal   AS CostRevaluationReserveLocal,
	|	FACost.DisregardedCostTA        AS DisregardedCostTA,
	|	0                                           AS CostGainMA,
	|	0                                           AS CostGainLocal,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|			THEN DocumentData.Organization
	|		ELSE UNDEFINED
	|	END                                       AS CorCompany,
	|
	|	DocumentData.Department               AS DebitBusinessUnit,
	|
	|	CASE
	|		WHEN NOT LeasedAsset.Counterparty IS NULL
	|			THEN LeasedAsset.Counterparty
	|		ELSE TTFAAccountingParameters.Leaseholder
	|	END AS CorCounterparty,
	|
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_Cost_Recipient AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTLeasedFA AS LeasedAsset
	|		ON LeasedAsset.Ref = FATable.Ref
	|			AND LeasedAsset.FixedAsset = FATable.FixedAsset
	|			AND LeasedAsset.State IN (
	|				VALUE(Enum.FixedAssetsStates.InLease),
	|				VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.HO_CostRevaluationReserve_Sender AS BusinessOperation,
	|	DocumentData.Organization                 AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	DocumentData.Department               AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|
	|	0                                           AS Cost,
	|	0                                           AS LocalCost,
	|	0                                           AS CostInTaxAccounting,
	|	0                                           AS CostPermanentDifference,
	|	0                                           AS CostTemporaryDifference,
	|	0                                           AS CostTargetFinancing,
	|	0                                           AS CostTargetFinancingTA,
	|	0                                           AS CostTargetFinancingPD,
	|	0                                           AS CostTargetFinancingTD,
	|	0                                           AS DepreciationAllowance,
	|	0                                           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                           AS SecurityDepositValue,
	|	0                                           AS PreliminaryCostMan,
	|	0                                           AS PreliminaryCostLocal,
	|	0                                           AS CostRevaluationReserve,
	|	0                                           AS CostRevaluationReserveLocal,
	|	0                                           AS DisregardedCostTA,
	|
	|	FACost.CostGainMA                AS CostGainMA,
	|	FACost.CostGainLocal            AS CostGainLocal,
	|
	|	DocumentData.CompanyRecipient       AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit     AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN FACost.OffBalanceSheetAccounting
	|			THEN TTFAAccountingParameters.Leaseholder
	|		ELSE UNDEFINED
	|	END                                       AS CorCounterparty,
	|
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_ReserveForRevaluationOfCosts_Sender AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = DocumentData.Ref
	|
	|WHERE
	|	(FACost.CostGainMA <> 0 
	|		OR FACost.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.HO_CostRevaluationReserve_Recipient AS BusinessOperation,
	|	DocumentData.CompanyRecipient       AS Organization,
	|	FATable.FixedAsset                  AS FixedAsset,
	|	DocumentData.ReceivingBusinessUnit     AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	UNDEFINED                                AS Leaseholder,
	|
	|	0                                           AS Cost,
	|	0                                           AS LocalCost,
	|	0                                           AS CostInTaxAccounting,
	|	0                                           AS CostPermanentDifference,
	|	0                                           AS CostTemporaryDifference,
	|	0                                           AS CostTargetFinancing,
	|	0                                           AS CostTargetFinancingTA,
	|	0                                           AS CostTargetFinancingPD,
	|	0                                           AS CostTargetFinancingTD,
	|	0                                           AS DepreciationAllowance,
	|	0                                           AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                           AS SecurityDepositValue,
	|	0                                           AS PreliminaryCostMan,
	|	0                                           AS PreliminaryCostLocal,
	|	0                                           AS CostRevaluationReserve,
	|	0                                           AS CostRevaluationReserveLocal,
	|	0                                           AS DisregardedCostTA,
	|
	|	FACost.CostGainMA                AS CostGainMA,
	|	FACost.CostGainLocal            AS CostGainLocal,
	|
	|	DocumentData.Organization                 AS CorCompany,
	|	DocumentData.Department               AS DebitBusinessUnit,
	|
	|	CASE 
	|		WHEN FACost.OffBalanceSheetAccounting
	|			THEN TTFAAccountingParameters.Leaseholder
	|		ELSE UNDEFINED
	|	END                                       AS CorCounterparty,
	|
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	UNDEFINED                                AS CorExpenseItem,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|	DocumentData.RecordInLocalAccounting          AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting           AS RecordInManAccounting,
	|	
	|	FATable.RowID               AS FinRecordID,
	|	DocumentData.SettingUpHO_ReserveForRevaluationOfCosts_Recipient AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = DocumentData.Ref
	|
	|WHERE
	|	(FACost.CostGainMA <> 0 
	|		OR FACost.CostGainLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");

	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.HO_Depreciation_Sender      AS BusinessOperation,
	|	DocumentData.Organization                     AS Organization,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	DocumentData.Department                   AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness      AS LineOfBusiness,
	|	UNDEFINED                                    AS Counterparty,
	|	FixedAssetsDepreciationCharge.Depreciation                       AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal                   AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting                     AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences                     AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD                     AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing                     AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing                   AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD                   AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD                   AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve       AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal   AS DepreciationRevaluationReserveLocal,
	|	DocumentData.CompanyRecipient           AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit         AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness      AS CorLineOfBusiness,
	|	UNDEFINED                                    AS CorExpenseItem,
	|	UNDEFINED                                    AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                    AS AccrueDepreciation,
	|	
	|	FATable.RowID                   AS FinRecordID,
	|	DocumentData.SetupHO_Depreciation_Sender AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.HO_Depreciation_Recipient       AS BusinessOperation,
	|	DocumentData.CompanyRecipient           AS Organization,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	DocumentData.ReceivingBusinessUnit         AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness      AS LineOfBusiness,
	|	UNDEFINED                                    AS Counterparty,
	|	FixedAssetsDepreciationCharge.Depreciation                       AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal                   AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting                     AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences                     AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD                     AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing                     AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing                   AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD                   AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD                   AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve       AS DepreciationRevaluationReserve,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal   AS DepreciationRevaluationReserveLocal,
	|	DocumentData.Organization                     AS CorCompany,
	|	DocumentData.Department                   AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness      AS CorLineOfBusiness,
	|	UNDEFINED                                    AS CorExpenseItem,
	|	UNDEFINED                                    AS CorExpenditureDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup       AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                    AS AccrueDepreciation,
	|	
	|	FATable.RowID                   AS FinRecordID,
	|	DocumentData.SettingHO_Depreciation_Recipient AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"// Moving depreciation for the sender
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.HO_Depreciation_Sender AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.CompanyRecipient AS CorCompany,
	|
	|	FixedAssetsDepreciationCharge.Depreciation         AS Sum,
	|	FixedAssetsDepreciationCharge.Depreciation         AS SumMan,
	|
	|	FixedAssetsDepreciationCharge.DepreciationLocal 
	|	 + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|UNION ALL
	|
	|// Moving depreciation for the recipient
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.HO_Depreciation_Recipient AS BusinessOperation,
	|	DocumentData.CompanyRecipient AS Organization,
	|
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	FixedAssetsDepreciationCharge.Depreciation         AS Sum,
	|	FixedAssetsDepreciationCharge.Depreciation         AS SumMan,
	|	FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|
	|UNION ALL
	|
	|// Moving the cost for the sender
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.HO_Cost_Sender AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.CompanyRecipient AS CorCompany,
	|
	|	FACost.Cost             AS Sum,
	|	FACost.Cost             AS SumMan,
	|
	|	FACost.LocalCost 
	|	 + FACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|UNION ALL
	|
	|// Moving the value for the recipient
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.HO_Cost_Recipient AS BusinessOperation,
	|	DocumentData.CompanyRecipient AS Organization,
	|
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	FACost.Cost             AS Sum,
	|	FACost.Cost             AS SumMan,
	|
	|	FACost.LocalCost
	|	 + FACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(QueryTexts)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.CompanyRecipient AS Dimension,
	|	UNDEFINED                      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	FACost.LocalCost + FACost.CostTargetFinancing AS SumCompl,
	|	FACost.CostPermanentDifference + FACost.CostTargetFinancingPD AS PermanentDifference,
	|	FACost.CostTemporaryDifference + FACost.CostTargetFinancingTD AS CostTD,
	|	FACost.Cost AS SumMan,
	|	FACost.Cost AS AmountIncludingVAT,
	|	FACost.Cost AS AmountExcludingVAT,
	|	
	|	FATable.RowID AS FinRecordID,
	|	DocumentData.SettingsHO_Cost_Sender AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.Organization       AS Dimension,
	|	UNDEFINED                      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	FACost.LocalCost + FACost.CostTargetFinancing AS SumCompl,
	|	FACost.CostPermanentDifference + FACost.CostTargetFinancingPD AS PermanentDifference,
	|	FACost.CostTemporaryDifference + FACost.CostTargetFinancingTD AS CostTD,
	|	FACost.Cost AS SumMan,
	|	FACost.Cost AS AmountIncludingVAT,
	|	FACost.Cost AS AmountExcludingVAT,
	|	
	|	FATable.RowID AS FinRecordID,
	|	DocumentData.SettingUpHO_Cost_Recipient AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.CompanyRecipient AS Dimension,
	|	UNDEFINED                      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences + FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD AS PermanentDifference,
	|	FixedAssetsDepreciationCharge.DepreciationTD + FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD AS CostTD,
	|	FixedAssetsDepreciationCharge.Depreciation AS SumMan,
	|	FixedAssetsDepreciationCharge.Depreciation AS AmountIncludingVAT,
	|	FixedAssetsDepreciationCharge.Depreciation AS AmountExcludingVAT,
	|	
	|	FATable.RowID AS FinRecordID,
	|	DocumentData.SetupHO_Depreciation_Sender AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.CompanyRecipient AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting) AS AssetRef,
	|	DocumentData.Organization       AS Dimension,
	|	UNDEFINED                      AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences + FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD AS PermanentDifference,
	|	FixedAssetsDepreciationCharge.DepreciationTD + FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD AS CostTD,
	|	FixedAssetsDepreciationCharge.Depreciation AS SumMan,
	|	FixedAssetsDepreciationCharge.Depreciation AS AmountIncludingVAT,
	|	FixedAssetsDepreciationCharge.Depreciation AS AmountExcludingVAT,
	|	
	|	FATable.RowID AS FinRecordID,
	|	DocumentData.SettingHO_Depreciation_Recipient AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|	AND DocumentData.Organization <> DocumentData.CompanyRecipient
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers)
	
	RegisterName = "SubAssetsComponentsOfDepreciation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	FATable.FixedAsset AS SubAssetComponent,
	|	FATable.FixedAssetOwner AS FixedAsset
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferSubAssets)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers = Undefined)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Ref AS Document,
	|	DocumentData.Organization AS Organization,
	|	BEGINOFPERIOD(DocumentData.Period, DAY) AS DateRecord,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Ref AS Document,
	|	DocumentData.CompanyRecipient AS Organization,
	|	BEGINOFPERIOD(DocumentData.Period, DAY) AS DateRecord,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfFixedAssetsToBranchOffice)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextTableOfMovementCompositionOfCGU(QueryTexts, Registers = Undefined)
	
	RegisterName = "CGUComposition";

	If Not GetFunctionalOption("UseFixedAssetImpairment") Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"// The State of FA binding to the CGU in front of the document.
	|SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
	|	CGUCompositionSliceLast.Organization AS Organization,
	|	CGUCompositionSliceLast.CGU AS CGU
	|	
	|INTO InitialStateOfCGU
	|
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|		&BorderInFrontOfDocument,
	|			NonCurrentAsset IN (
	|								SELECT 
	|									FATable.FixedAsset
	|								FROM DocumentDataFATable AS FATable
	|								)
	|			AND
	|			Organization = &Organization) AS CGUCompositionSliceLast
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|
	|// Transferring fixed assets to another CGU. If the CGU is different from the current value.
	|SELECT
	|	DocumentData.Ref         AS Recorder,
	|	DocumentData.Period         AS Period,
	|
	|	CASE
	|		WHEN DocumentData.CompanyRecipient = VALUE(Catalog.Companies.EmptyRef)
	|			THEN DocumentData.Organization
	|		ELSE DocumentData.CompanyRecipient
	|	END                       AS Organization,
	|
	|	FATable.FixedAsset         AS NonCurrentAsset,
	|	DocumentData.CGURecipient             AS CGU
	|	
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN InitialStateOfCGU AS InitialStateOfCGU
	|		ON DocumentData.CGURecipient = InitialStateOfCGU.CGU
	|		AND FATable.FixedAsset = InitialStateOfCGU.NonCurrentAsset
	|		AND CASE
	|			WHEN DocumentData.CompanyRecipient = VALUE(Catalog.Companies.EmptyRef)
	|				THEN DocumentData.Organization
	|			ELSE DocumentData.CompanyRecipient
	|			END = InitialStateOfCGU.Organization
	|WHERE
	|	InitialStateOfCGU.CGU IS NULL
	|
	|UNION
	|
	|// clearing CGU by the sending organization 
	|// when moving to a division with a dedicated balance.
	|SELECT
	|	DocumentData.Ref         AS Recorder,
	|	DocumentData.Period         AS Period,
	|	DocumentData.Organization    AS Organization,
	|	FATable.FixedAsset     AS NonCurrentAsset,
	|	VALUE(Catalog.CashGeneratingUnits.EmptyRef) AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.CompanyRecipient <> VALUE(Catalog.Companies.EmptyRef)
	|	AND DocumentData.CompanyRecipient <> DocumentData.Organization
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return FATransferLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return FATransferLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	FATransferLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	FATransferLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	//
	FATransferLocalization.AddOptionsForSelectingArticlesAndAnalytics(ItemsAndDimensionsSelectionParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

Function ThereAreOwnFA(Object) Export

	ThereAreOwnFA = True;
	
	
	Return ThereAreOwnFA;
	
EndFunction

// 
// Parameters:
//  Object - DocumentObject.FATransfer2_4 - 
//  ReportErrors - Boolean - 
//  ArrayOfLineNumbers - Array, Undefined - 
Procedure FillInBasedOnInventory(Object, ReportErrors, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return;
	EndIf;
	
	DataToFill = Documents.FixedAssetsPhysicalCount.FillingDataBasedOnInventory24(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.Move, 
							ArrayOfLineNumbers);
							
	If DataToFill.Attributes = Undefined
		Or DataToFill.Attributes.Count() = 0
		Or DataToFill.TabularSection = Undefined 
		Or DataToFill.TabularSection.Count() = 0 Then
		
		If ReportErrors Then
			ErrorText = NStr("vi = 'Trong chứng từ %1 không có dòng nào yêu cầu tạo điều chuyển';
							|ru = 'В документе %1 отсутствуют строки требующие создания перемещения';
							|en = 'There are no lines which require transfer in the %1 document'; fa = 'There are no lines which require transfer in the %1 document';
							|it = 'There are no lines which require transfer in the %1 document';
							|pl = 'There are no lines which require transfer in the %1 document';
							|tr = '%1 belgesinde transfer oluşturulması gereken satır bulunmuyor'");
			ErrorText = StrTemplate(ErrorText, Object.DocumentBasis);
			Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		EndIf;
		
		Return;
		
	EndIf;
	
	SampleBankingDetails = DataToFill.Attributes[0];
	
	Object.ReceivingBusinessUnit = SampleBankingDetails.FixedAssetsLocation;
	If ValueIsFilled(SampleBankingDetails.FinanciallyLiablePerson) Then
		Object.InventoryCustodianRecipient = SampleBankingDetails.FinanciallyLiablePerson;
	EndIf;
	
	For Each TSSampling In DataToFill.TabularSection Do
		
		If Not ValueIsFilled(Object.Organization) Then
			Object.Organization = TSSampling.LocationOrganization;
		EndIf;
		If Not ValueIsFilled(Object.Department) Then
			Object.Department = TSSampling.LocationDivision;
		EndIf;
		If Not ValueIsFilled(Object.FinanciallyLiablePerson) Then
			Object.FinanciallyLiablePerson = TSSampling.LocationOfPier;
		EndIf;
		If Not ValueIsFilled(Object.InventoryCustodianRecipient) Then
			Object.InventoryCustodianRecipient = TSSampling.InventoryCustodianRecipient;
		EndIf;
		
		If Object.Organization = TSSampling.LocationOrganization
			And Object.Department = TSSampling.LocationDivision
			And Object.FinanciallyLiablePerson = TSSampling.LocationOfPier
			And (ValueIsFilled(SampleBankingDetails.FinanciallyLiablePerson)
				Or Object.InventoryCustodianRecipient = TSSampling.InventoryCustodianRecipient) Then
			FillPropertyValues(Object.FA.Add(), TSSampling);
		EndIf;
		
	EndDo;
	
	If Object.Organization <> SampleBankingDetails.Organization
		And ValueIsFilled(Object.Organization) Then
			
		Object.CompanyRecipient = SampleBankingDetails.Organization;
		Object.BusinessOperation = Enums.BusinessTransactions.TransferOfFixedAssetsToBranchOffice;
	Else
		Object.BusinessOperation = Enums.BusinessTransactions.FATransfer;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
