#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReportOnVMIAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReportOnVMIAdjustment") Then
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
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		
		ReportOnVMIAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//	Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	CreationCommands = New Array;
	
	Command = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	CreationCommands.Add(Command);
	
	Command = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	CreationCommands.Add(Command);
	
	Command = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	CreationCommands.Add(Command);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	SetVisibilityOfCreationCommandsBasedOn(CreationCommands);
	
	ReportOnVMIAdjustmentLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	Documents.WriteOffOfShippedGoods.AddCreateCommandBasedOnReportOnWriteOffOfGiverSGoods(GenerationCommands);
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	ReportOnVMIAdjustmentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date,BusinessOperation";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = FullObjectName();
	
	EmptyStructure = New Structure();
	UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse", EmptyStructure)
										Or GetFunctionalOption("UseItemsBatchProduction", EmptyStructure);
	UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse", EmptyStructure)
										Or GetFunctionalOption("UseCostAccountingByBatchesProduction", EmptyStructure);
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice    = True;
	
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.Date         = Object.Date;
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.AdditionalFieldNames.Add("StorageType");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Department");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Contract");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - the composition of fields is set in the function
//		Nomenclaturales.Parametrizatsii.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Series               AS Series,
	|	Goods.Count          AS Count,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Department       AS Department,
	|	Goods.Contract             AS Contract,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.StorageType    AS StorageType
	|
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber           AS LineNumber,
	|	Goods.StorageType      AS StorageType,
	|	Goods.BatchesIndicationStatus   AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN SeriesAccountingPoliciesForWarehouses.BatchAccountingPolicy IS NULL
	|				AND SeriesAccountingPoliciesByDivision.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN SeriesAccountingPoliciesForWarehouses.BatchAccountingPolicy.UseCostAccountingByBatches
	|					OR SeriesAccountingPoliciesByDivision.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|									AND ISNULL(CatContracts.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) IN(
	|										VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))
	|								OR ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|									AND ISNULL(CatContracts.BusinessOperation, VALUE(Enum.BusinessTransactions.EmptyRef)) IN(
	|										VALUE(Enum.BusinessTransactions.ProductionByToller2_5),
	|										VALUE(Enum.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5))
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatusGoodsAtPartners
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|	
	|	LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesForWarehouses
	|	ON SeriesAccountingPoliciesForWarehouses.Warehouse = Goods.Warehouse
	|	AND CAST(Goods.Products AS Catalog.Products).ProductKind = SeriesAccountingPoliciesForWarehouses.Ref
	|	
	|	LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesByDivision
	|	ON SeriesAccountingPoliciesForWarehouses.Warehouse = Goods.Department
	|	AND CAST(Goods.Products AS Catalog.Products).ProductKind = SeriesAccountingPoliciesForWarehouses.Ref
	|	
	|	LEFT JOIN Catalog.ItemKinds AS ProductKind
	|	ON CAST(Goods.Products AS Catalog.Products).ProductKind = ProductKind.Ref
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Ref = Goods.Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber         AS LineNumber,
	|	CASE
	|		WHEN Statuses.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract) THEN
	|			Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE
	|			Statuses.BatchesIndicationStatus
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract) THEN
	|			Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE
	|			Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Assignments

// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm -
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_     =
		"Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider)
		|AND Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_    =
		"Object.BusinessOperation = VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider)
		|OR Object.BusinessOperation = VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.Partner                 = "Object.Partner";
	DestinationPattern.Contract                 = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.VisibleSelectionsOnForm.Insert(
		"LineOfBusiness", NStr("vi = 'Chỉ ấn định lĩnh vực hoạt động ""%1""';
								|ru = 'Только назначения направления деятельности ""%1""';
								|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
								|it = 'Solo assegnazioni del settore di attività ""%1""';
								|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
								|tr = 'Yalnızca ""%1"" faaliyet destinasyonları '"));
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", True, "Object.Goods.Purpose");
	
	Return FormTemplate;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return ReportOnVMIAdjustmentLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//	String - Query text
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ReportOnVMIAdjustmentLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion
// Fills in an array of details that depend on the business operation.
//
// Parameters:
//	BusinessOperation		- EnumRef.BusinessTransactions	- business operation of the document.
//	ArrayOfAllProps		- Array									- Bank details that do not depend on the business transaction.
//	ArrayOfOperationDetails	- Array									- Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Currency");
	ArrayOfAllProps.Add("ARAPCurrency");
	ArrayOfAllProps.Add("ExpenseItem");
	ArrayOfAllProps.Add("DimensionOfExpenses");
	ArrayOfAllProps.Add("AssetsLiabilitiesDimension");
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("PaymentDate");
	ArrayOfAllProps.Add("PaymentMethod");
	ArrayOfAllProps.Add("ForeignCurrencyTransaction");
	ArrayOfAllProps.Add("ARAPObjectSettings");
	ArrayOfAllProps.Add("CompanyBankAccount");
	ArrayOfAllProps.Add("CounterpartyBankAccount");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses Then
		ArrayOfOperationDetails = Common.CopyRecursive(ArrayOfAllProps);
	ElsIf BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		ArrayOfOperationDetails = Common.CopyRecursive(ArrayOfAllProps);
	EndIf;
	
EndProcedure

#Region CreatingHyperlinkInProcurementDocumentLog

// Returns the text of the hyperlink from the document log to the workplace
// for processing write-offs of goods accepted for storage.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  Undefined, FormattedString - the text of the hyperlink of the transition to the workplace
//  for the registration of write-offs of goods accepted for storage.
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanyGoods) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Organization",        Parameters.Organization);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Parameters.Organization));
	
	InventoryTypes = New Array;
	GiverSGoods =
		Not Parameters.BusinessTransactionsAndDocuments.FindRows(
			New Structure(
					"FullDocumentName, BusinessOperation",
					FullObjectName(),
					Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider)).Count() = 0
		Or Not Parameters.BusinessTransactionsAndDocuments.FindRows(
				New Structure(
						"FullDocumentName, BusinessOperation",
						FullObjectName(),
						Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses)).Count() = 0;
	
	If GiverSGoods Then
		
		InventoryTypes.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		InventoryTypes.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		InventoryTypes.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
		
		HyperlinkText = NStr("vi = 'Ghi giảm';
							|ru = 'Списания';
							|en = 'Adjustments'; fa = 'Adjustments';
							|it = 'Storni';
							|pl = 'Spisania';
							|tr = 'Gider yazma'");
		
	Else
		InventoryTypes.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
		InventoryTypes.Add(Enums.InventoryTypes.GoodsStoredWithRightOfSaleTransferred);
		HyperlinkText = NStr("vi = 'Ghi giảm từ nơi cất giữ';
							|ru = 'Списание с хранения';
							|en = 'Write off from storage'; fa = 'Write off from storage';
							|it = 'Cancellazione contabile dallo stoccaggio';
							|pl = 'Rozchód z przechowywania';
							|tr = 'Depodan gider yazma'");
	EndIf;
	Query.SetParameter("InventoryTypes", InventoryTypes);
	
	Query.Text =
	"SELECT ALLOWED
	|	InventoryKinds.Ref AS InventoryOwnerAttribute
	|INTO InventoryTable
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	(&ByAllCompanies
	|		OR InventoryKinds.Organization = &Organization)
	|	AND InventoryKinds.InventoryType IN (&InventoryTypes)
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 1
	|	GoodsAcceptedBalance.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(,
	|			InventoryOwnerAttribute IN
	|				(SELECT
	|					InventoryTable.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|				FROM
	|					InventoryTable AS InventoryTable)
	|			AND (&ByAllCompanies OR Organization = &Organization)) AS GoodsAcceptedBalance
	|WHERE
	|	GoodsAcceptedBalance.ToRegisterGoodsIssueBalance > 0
	|";
	
	If Not Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText, , , ,
			"Document.ReportOnVMIAdjustment.Form.ToRegisterWriteOffsOfGoodsReceivedForStorage");
	Else
		Return New FormattedString(HyperlinkText, , StyleColors.EmptyTableField, ,
			"Document.ReportOnVMIAdjustment.Form.ToRegisterWriteOffsOfGoodsReceivedForStorage");
	EndIf;
	
EndFunction

#EndRegion

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.ReportOnVMIAdjustment - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		Repetition = Selection.Repetition;
		Rate = Selection.Rate;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = 0;
		AmountARAP = 0;
		Repetition = 1;
		Rate = 1;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(BusinessOperation)";
	
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

// Returns the parameters of the selection of articles and analyst.
// 
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The operation of the document.
// 
// Returns:
//  See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object";
	ChoiceParameters.AssetRef                = "ExpenseItem";
	ChoiceParameters.ArticleType             = "ArticleType";
	ChoiceParameters.AvailabilityByOperation = AvailabilityByOperation;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The operation of the document.
// 
// Returns:
//  See GLAccountSettingsServer.AccountingAccountSettings_
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	AvailabilityByOperation =
		BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.AvailabilityByOperation = AvailabilityByOperation;
	
	SetupParameters.DataPath = "Object";
	SetupParameters.ArticleType   = "ArticleType";
	
	SetupParameters.FormItems.Add("TransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation,
			|Contract");
		BusinessOperation = StructureFillingData.BusinessOperation;
		Contract               = StructureFillingData.Contract;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		Contract               = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		Contract               = FillingData.Contract;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsSalePurchase	= True;
	ParametersStructure.PaymentType_			= Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	If ValueIsFilled(Contract) Then
		ContractType = GeneralPurposeTMServerCall.ObjectAttributeValue(Contract, "ContractType");
		
		If ContractType = Enums.ContractTypes.CustomerInvoiceOutsourcedSale Then
			ParametersStructure.ThisIsSalePurchase	= True;
			ParametersStructure.PaymentType_			= Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		EndIf;
	EndIf;
	
	DonTShowCalculations =
		BusinessOperation = Enums.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or False;
	
	ParametersStructure.ChangesCalculationsByString =
		"DataSource.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses),
	|		VALUE(Enum.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses))";
	
	ParametersStructure.ChangesPaymentPlan =
		BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	ParametersStructure.ModifiesDeliveryShipmentPlan =
		BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage        = "";
	
	ParametersStructure.CourseNumerator                    = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                  = "Object.CourseDenominator";
	ParametersStructure.CashAccount							 = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PropsNameTSAmountWithVAT			 = "Sum";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.PaymentDate						 = "Object.PaymentDate";
	If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
		ParametersStructure.PaymentSchedule					= "Object.PaymentSchedule";
	EndIf;
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.VATTaxation               = "";
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.InvoiceForOrders               = "";
	ParametersStructure.OrderBase                   = "";
	
	ParametersStructure.FormItems.LabelCurrencies                    = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages                     = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement                      = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements            = "GoodsAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly             = DonTShowCalculations;
	ParametersStructure.DocumentCurrencyViewOnly                  = DonTShowCalculations;
	ParametersStructure.MutualSettlementsCurrencyViewOnly             = DonTShowCalculations;
	ParametersStructure.DonTShowCalculations                            = DonTShowCalculations;
	
	ParametersStructure.PathToTSDataPaymentSteps         = "";
	ParametersStructure.DocumentAmountForm              = "";
	ParametersStructure.AmountOfDepositForContainerForm           = "";
		
	Return ParametersStructure;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#EndIf
#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("BusinessOperation");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or Data.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		DocumentSynonym = TollingSchemeClientServer.SynonymOfDocumentReportOnWriteOffOfGoodsFromStorage();
	Else
		DocumentSynonym = NStr("vi = 'Báo cáo ghi giảm hàng hóa từ nơi cất giữ';
								|ru = 'Отчет о списании товаров с хранения';
								|en = 'VMI adjustment report'; fa = 'گزارش اصلاح VMI';
								|it = 'Report di storno merci dallo stoccaggio';
								|pl = 'Raport o rozchodowaniu towarów z przechowywania';
								|tr = 'Depodaki mallar için zarar raporu'");
	EndIf;
	
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), DocumentSynonym, Data.Number, Data.Date);
	
EndProcedure

#EndRegion
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.Number                    AS Number,
	|	DocumentData.Date                     AS Period,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.Terms               AS Terms,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses),
	|				VALUE(Enum.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                    AS ThisIsWriteOffAtOurExpense,
	|	CASE
	|		WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|			THEN DocumentData.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                    AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses        AS DimensionOfExpenses,
	|	CASE
	|		WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN DocumentData.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                    AS AssetAndLiabilityItem,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.GLAccountSettings     AS GLAccountSettings,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.ARAPCurrency     AS ARAPCurrency,
	|	DocumentData.Manager                 AS Manager,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Department            AS Department,
	|	DocumentData.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.PaymentDate              AS PaymentDate,
	|	DocumentData.PaymentMethod              AS PaymentMethod,
	|	DocumentData.DocumentAmount           AS DocumentAmount,
	|	DocumentData.AmountARAP      AS AmountARAP,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.Patch              AS Patch,
	|	DocumentData.ReversedDocument     AS ReversedDocument,
	|	DocumentData.CorrectedDocument     AS CorrectedDocument,
	|	DocumentData.ARAPObject           AS ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	DocumentData.DocumentID   AS DocumentID,
	|	BusinessTransactionsSettings.Ref    AS BusinessTransactionSetting,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	For Each Column In QueryResult.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	MetadataIdentifier = Common.MetadataObjectID(FullObjectName());
	NumberForPrinting           = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	ContractInformation    = "";
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier",        MetadataIdentifier);
	Query.SetParameter("NumberForPrinting",                  NumberForPrinting);
	Query.SetParameter("ContractInformation",           ContractInformation);
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                     AS Document,
	|	&Period                     AS Period,
	|	&Ref                     AS Recorder,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Count     AS Count,
	|	&Partner                    AS Sender,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord
	|FROM
	|	Document.ReportOnVMIAdjustment.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Partner                 AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	CAST(&Comment AS STRING(100)) AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Organization                             AS Organization,
	|	&Department                           AS Department,
	|	GoodsTable.LineOfBusiness    AS LineOfBusiness,
	|	&AssetAndLiabilityItem                   AS AssetRef,
	|	CASE
	|		WHEN &AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE &AssetsLiabilitiesDimension
	|	END                                    AS Dimension,
	|	
	|	SUM(GoodsTable.AmountExcludingVATMan)      AS Sum
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	&ThisIsWriteOffAtOurExpense
	|	AND &AssetAndLiabilityItem <> UNDEFINED
	|
	|GROUP BY
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.ItemsLocationAttributes";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                               AS Period,
	|	&Organization                          AS Organization,
	|	&Department                        AS Department,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	&AssetAndLiabilityItem                AS AssetRef,
	|	&AssetsLiabilitiesDimension             AS Dimension,
	|	&GLAccountSettings                 AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	
	|	GoodsTable.AmountExcludingVATCompl         AS SumCompl,
	|	GoodsTable.AmountExcludingVATMan          AS SumMan,
	|	GoodsTable.AmountExcludingVATMan          AS AmountIncludingVAT,
	|	GoodsTable.AmountExcludingVATMan          AS AmountExcludingVAT,
	|
	|	&IDARAPObject         AS FinRecordID,
	|	&BusinessTransactionSetting       AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	&ThisIsWriteOffAtOurExpense
	|	AND &AssetAndLiabilityItem <> UNDEFINED
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeTrackingAnalyticsKeysForPartners(Query);
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&ARAPObject AS ARAPObject,
	|	
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	CASE 
	|		WHEN &AssetAndLiabilityItem <> UNDEFINED
	|			THEN &AssetAndLiabilityItem
	|		ELSE &ExpenseItem
	|	END AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency
	|			THEN &AmountARAP
	|		ELSE
	|			CAST(&DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31, 2))
	|	END AS Sum,
	|	0 AS AmountExcludingVAT,
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency
	|				AND &Currency <> &LocalAccountingCurrency
	|			THEN &AmountARAP
	|		ELSE
	|			CAST(&DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2))
	|	END AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,

	|	&ARAPCurrency AS Currency,
	|	&AmountARAP AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,

	|	&ARAPCurrency AS ARAPCurrency,
	|	&AmountARAP AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	&IDARAPObject AS FinRecordID
	|WHERE
	|	&ThisIsWriteOffAtOurExpense
	|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ReportOnVMIAdjustment.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses),
	|		VALUE(Enum.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses))
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                           AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                      AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber       AS CCDNumber,
	|	&BusinessOperation            AS BusinessOperation,
	|	UNDEFINED                      AS ExpenseItem,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	UNDEFINED                      AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.Products   AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Count     AS ToRegisterGoodsIssue
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Organization                             AS Organization,
	|	&Department                           AS Department,
	|	&ExpenseItem                          AS ExpenseItem,
	|	&DimensionOfExpenses                       AS DimensionOfExpenses,
	|	GoodsTable.LineOfBusiness    AS LineOfBusiness,
	|	UNDEFINED                             AS VATActivityType,
	|	SUM(GoodsTable.AmountExcludingVATMan)      AS AmountIncludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan)      AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan)      AS AmountExcludingVATMan,
	|	SUM(GoodsTable.AmountExcludingVATCompl)     AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl)     AS AmountExcludingVATCompl,
	|	0                                        AS PermanentDifference,
	|	0                                        AS CostTD,
	|	&BusinessOperation                   AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	&IDARAPObject            AS FinRecordID,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_                     AS VariancePeriod
	|	
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON AssetRef.Ref = &ExpenseItem
	|WHERE
	|	&ThisIsWriteOffAtOurExpense
	|	AND &ExpenseItem <> UNDEFINED
	|
	|GROUP BY
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Ref.ARAPObject.UUID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	BusinessOperation = Undefined;
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		
		Return;
		
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
		Query.Parameters.ARAPCurrency, Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestForAnalytics = New Query;
	
	RequestForAnalytics.Text = "
	|SELECT DISTINCT
	|	&Organization             AS Organization,
	|	&Contract                 AS Contract,
	|	&Counterparty              AS Counterparty,
	|	&Partner                 AS Partner,
	|	&LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON &Organization = Dimension.Organization
	|			AND &Counterparty = Dimension.Counterparty
	|			AND &Partner = Dimension.Partner
	|			AND &Contract = Dimension.Contract
	|			AND &LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ThisIsWriteOffAtOurExpense
	|	AND Dimension.DimensionKey IS NULL
	|";
	
	RequestForAnalytics.SetParameter("Ref",                  Query.Parameters.Ref);
	RequestForAnalytics.SetParameter("Organization",             Query.Parameters.Organization);
	RequestForAnalytics.SetParameter("Counterparty",              Query.Parameters.Counterparty);
	RequestForAnalytics.SetParameter("Partner",                 Query.Parameters.Partner);
	RequestForAnalytics.SetParameter("Contract",                 Query.Parameters.Contract);
	RequestForAnalytics.SetParameter("ThisIsWriteOffAtOurExpense",    Query.Parameters.ThisIsWriteOffAtOurExpense);
	RequestForAnalytics.SetParameter("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	Selection = RequestForAnalytics.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	AnalyticsParameters = New Structure;
	AnalyticsParameters.Insert("Partner",                 Query.Parameters.Partner);
	AnalyticsParameters.Insert("Counterparty",              Query.Parameters.Counterparty);
	AnalyticsParameters.Insert("Organization",             Query.Parameters.Organization);
	AnalyticsParameters.Insert("Contract",                 Query.Parameters.Contract);
	AnalyticsParameters.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	Query.SetParameter("AccountingDimensionByPartners",
							InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters));
	
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber                AS LineNumber,
	|	InventoryKinds.Ref                     AS Ref,
	|	&Organization                           AS Organization,
	|	CatInventoryKinds.Currency                  AS Currency,
	|	InventoryKinds.RowID        AS RowID,
	|	InventoryKinds.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryType              AS InventoryType,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey   AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	Dimension.Products                 AS Products,
	|	Dimension.Characteristic               AS Characteristic,
	|	Dimension.Purpose                   AS Purpose,
	|	Dimension.Series                        AS Series,
	|	InventoryKinds.Count                 AS Count,
	|	InventoryKinds.Sum                      AS Sum,
	|	InventoryKinds.AmountARAP        AS AmountARAP,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	ISNULL(CatAssignments.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)      AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)     AS AmountExcludingVATCompl
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.ReportOnVMIAdjustment.InventoryKinds AS InventoryKinds
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN Catalog.Assignments AS CatAssignments
	|		ON Dimension.Purpose = CatAssignments.Ref
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON InventoryKinds.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON InventoryKinds.Ref = Amounts.Ref
	|			AND InventoryKinds.RowID = Amounts.RowID
	|WHERE
	|	InventoryKinds.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	&EmptyAssignment          AS Purpose,
	|	Keys.Series                AS Series,
	|	Keys.StorageLocation		   AS Warehouse
	|FROM
	|	Document.ReportOnVMIAdjustment.Goods AS Goods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON Goods.ItemsLocationAttributes = Keys.Ref
	|	
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Keys.Products      = Dimension.Products
	|			AND Keys.Characteristic = Dimension.Characteristic
	|			AND Keys.Series          = Dimension.Series
	|			AND Keys.StorageLocation  = Dimension.StorageLocation
	|			AND &EmptyAssignment    = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.Products IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments";
	
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = FullObjectName();
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
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
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReportOnVMIAdjustment AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReportOnVMIAdjustment.ARAPDetails AS Table
		|		LEFT JOIN Document.ReportOnVMIAdjustment AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Ref.Organization             AS Organization,
		|	Table.Ref.Partner                 AS Partner,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	
		|	Table.Ref.ARAPObject          AS ARAPObject,
		|	Table.Ref.PaymentDate             AS PaymentDate,
		|	UNDEFINED                           AS PaymentOption,
		|	UNDEFINED                           AS PurchaseOrder_,
		|	
		|	Table.Sum	                       AS Sum,
		|	Table.AmountARAP            AS AmountARAP,
		|	0                                      AS AmountARAPByPackage,
		|
		|	Table.Ref.ARAPObjectSettings         AS ARAPObjectSettings,
		|	FALSE                                   AS InvoiceForOrders,
		|	Table.Ref.ARAPCurrency    AS ARAPCurrency,
		|	Table.Ref.BusinessOperation   AS BusinessOperation,
		|	Table.Ref.PaymentMethod             AS PaymentMethod,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	Table.Ref.Date                    AS DateOfCourse,
		|	UNDEFINED                           AS LinkedDocument
		|FROM
		|	Document.ReportOnVMIAdjustment.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT &BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
		|			VALUE(Enum.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor))
		|	AND NOT Table.Ref.Contract.ContractType = VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale)
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Ref.Organization             AS Organization,
		|	Table.Ref.Partner                 AS Partner,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	Table.Ref.PaymentDate             AS PaymentDate,
		|	
		|	Table.Ref.ARAPObject          AS ARAPObject,
		|	Table.Ref.ARAPObjectSettings         AS ARAPObjectSettings,
		|	FALSE                                   AS InvoiceForOrders,
		|	FALSE                                   AS ExceedingOrder,
		|	UNDEFINED                           AS PurchaseOrder_,
		|	Table.AmountARAP            AS AmountDue,
		|	Table.Ref.ARAPCurrency    AS ARAPCurrency,
		|	Table.Ref.BusinessOperation   AS BusinessOperation,
		|	Table.Ref.PaymentMethod             AS PaymentMethod,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	UNDEFINED                           AS PaymentOption,
		|	UNDEFINED                           AS LinkedDocument
		|FROM
		|	Document.ReportOnVMIAdjustment.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT &BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
		|			VALUE(Enum.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor))
		|	AND NOT Table.Ref.Contract.ContractType = VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale)
		|";
	
	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.ReportOnVMIAdjustment.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT &BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
		|			VALUE(Enum.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor))
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	TextPaymentPlans =
		"SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.Contract.ARAPObjectSettings                                   AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Ref.BusinessOperation                                     AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate                                               AS PaymentDate,
		|	UNDEFINED                                                             AS PaymentOption,
		|	0                                                                        AS AmountDue,
		|	0                                                                        AS MeasuringGoodsVarianceAmount,
		|		
		|	TRUE                                                                   AS ExcludeDuringControl
		|	
		|FROM
		|	Document.ReportOnVMIAdjustment.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.Contract.ContractType = VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale)
		|	AND Table.Purpose.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|";
	
	TextShipmentPlans =
		"SELECT
		|	Table.Purpose.OrderDocument					AS Ref,
		|	Table.Ref.Organization                  AS Organization,
		|	Table.Ref.Partner                      AS Partner,
		|	
		|	Table.Ref.ARAPObject               AS ARAPObject,
		|	
		|	ENDOFPERIOD(Table.Ref.Date, DAY)		AS DateOfShipment,
		|	Table.Sum								AS IncreaseToBeSHIPPED,
		|	Table.Sum								AS IncreaseShipping,
		|	Table.Ref.Date							AS RecorderDate,
		|	Table.Ref.Number						AS RecorderNumber,
		|	Table.Ref.Contract.ARAPObjectSettings		AS ARAPObjectSettings,
		|	Table.Ref.Currency						AS ARAPCurrency,
		|	Table.Ref.Currency						AS DocumentCurrency,
		|	Table.Ref.BusinessOperation        AS BusinessOperation,
		|	Table.Ref.PaymentMethod					AS PaymentMethod
		|	
		|FROM
		|	Document.ReportOnVMIAdjustment.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.Contract.ContractType = VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale)
		|	AND Table.Purpose.Contract.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|";
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);

EndProcedure

#EndRegion

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region RecogniseAsExpensesAssets
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	UNDEFINED 			 						AS VATActivityType,
	|	UNDEFINED			 						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    			AS CorCompany,
	|	UNDEFINED   												AS CorItemsLocationAttributes,
	|	UNDEFINED												AS CorInventoryOwnerAttribute,
	|	DocumentTable.ExpenseItem 			    			AS ExpenseItemAssets,
	|	CASE WHEN DocumentTable.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN DocumentTable.DimensionOfExpenses                
	|		ELSE DocumentTable.AssetsLiabilitiesDimension
	|	END    						  			    			AS AssetExpenseAnalytics,
	|	UNDEFINED												AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Act on the write-off of goods accepted for storage
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id                  = "ActOfWritingOffGoodsAcceptedForStorage";
	PrintCommand.Presentation                  = NStr("vi = 'Biên bản ghi giảm hàng hóa đã nhận vào nơi cất giữ';
														|ru = 'Акт о списании принятых на хранение товаров';
														|en = 'VMI adjustment'; fa = 'تعدیل VMI';
														|it = 'Verbale di accettazione delle merci accettate in custodia';
														|pl = 'Akt odpisu przyjętych na przechowywanie towarów';
														|tr = 'Depoya alınan malların gider yazma raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider);
	TransactionList.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses);
	
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  TransactionList,
													  ComparisonType.NotInList);
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id                  = "ActOfWritingOffGiverSGoods";
	PrintCommand.Presentation                  = NStr("vi = 'Biên bản ghi giảm hàng hóa của bên đặt gia công';
														|ru = 'Акт о списании товаров давальца';
														|en = 'Provider stock shortage recognition'; fa = 'Provider stock shortage recognition';
														|it = 'Atto di storno delle merci del fornitore';
														|pl = 'Protokół o rozchodowaniu towarów właściciela surowców';
														|tr = 'Sağlayıcı mallarının gider yazma raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  TransactionList,
													  ComparisonType.InList);
	
	// Report On Products And Materials
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ReportOnProductsAndMaterials";
	PrintCommand.Presentation = NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
									|ru = 'Отчет о продукции и материалах';
									|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
									|it = 'Report su prodotti e materiali';
									|pl = 'Raport o produkcji i materiałach';
									|tr = 'Ürün ve malzeme raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  TransactionList,
													  ComparisonType.InList);
	ReportOnVMIAdjustmentLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Forms printed forms of the object.
//
// Parameters:
//	ObjectsArray        - Array           - an array of references to objects which need to print,
//	PrintParameters       - Structure        - structure of additional print parameters,
//	PrintFormsCollection - ValueTable  - generated table documents,
//	PrintObjects         - ValueList   - list of print objects,
//	OutputParameters       - Structure        - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfWritingOffGoodsAcceptedForStorage") Then
		TemplateName     = "ActOfWritingOffGoodsAcceptedForStorage";
		TemplateSynonym = NStr("vi = 'Biên bản ghi giảm hàng hóa đã nhận vào nơi cất giữ';
								|ru = 'Акт о списании принятых на хранение товаров';
								|en = 'VMI adjustment'; fa = 'تعدیل VMI';
								|it = 'Verbale di accettazione delle merci accettate in custodia';
								|pl = 'Akt odpisu przyjętych na przechowywanie towarów';
								|tr = 'Depoya alınan malların gider yazma raporu'");
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, TemplateName, TemplateSynonym,
		GeneratePrintedFormOfActOfWritingOffGoodsAcceptedForStorage(ObjectsArray, PrintObjects));
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfWritingOffGiverSGoods") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ActOfWritingOffGiverSGoods",
			NStr("vi = 'Biên bản ghi giảm hàng hóa của bên đặt gia công';
				|ru = 'Акт о списании товаров давальца';
				|en = 'Provider stock shortage recognition'; fa = 'Provider stock shortage recognition';
				|it = 'Atto di storno delle merci del fornitore';
				|pl = 'Protokół o rozchodowaniu towarów właściciela surowców';
				|tr = 'Sağlayıcı mallarının gider yazma raporu'"),
			GeneratePrintedFormOfActOfWritingOffGoodsAcceptedForStorage(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReportOnProductsAndMaterials") Then
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReportOnVMIAdjustment_ReportOnProductsAndMaterials";
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReportOnProductsAndMaterials",
			NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
				|ru = 'Отчет о продукции и материалах';
				|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
				|it = 'Report su prodotti e materiali';
				|pl = 'Raport o produkcji i materiałach';
				|tr = 'Ürün ve malzeme raporu'"),
			Documents.ReportToMaterialProvider2_5.ToFormPrintedFormOfReportOnProductsAndMaterials(
				PrintingDataOfMaterialsReport(ObjectsArray),
				PrintObjects,
				SpreadsheetDocument));
		
	EndIf;
	ReportOnVMIAdjustmentLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// The function generates a printed form of documents for debiting goods accepted for storage.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - printed form of documents for writing off goods accepted for storage.
//
Function GeneratePrintedFormOfActOfWritingOffGoodsAcceptedForStorage(ObjectsArray, PrintObjects)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsConsumption.Ref                       AS Ref,
	|	GoodsConsumption.Number                        AS Number,
	|	GoodsConsumption.Date                         AS Date,
	|	GoodsConsumption.CorrectedDocument.Number   AS NumberOfDocumentBeingCorrected,
	|	GoodsConsumption.CorrectedDocument.Date    AS DateOfDocumentBeingCorrected,
	|	GoodsConsumption.Counterparty                   AS Vendor,
	|	GoodsConsumption.Organization                  AS Organization,
	|	GoodsConsumption.Organization.Prefix          AS Prefix,
	|	GoodsConsumption.Currency                       AS Currency,
	|	GoodsConsumption.BusinessOperation        AS BusinessOperation,
	|	GoodsConsumption.Department                AS Department,
	|	PRESENTATION(GoodsConsumption.Department) AS DepartmentPresentation,
	|	GoodsConsumption.Manager.Individual      AS EmployeeResponsible
	|FROM
	|	Document.ReportOnVMIAdjustment AS GoodsConsumption
	|WHERE
	|	GoodsConsumption.Ref IN (&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ItemsToBeDebited.Ref               AS Ref,
	|	ItemsToBeDebited.LineNumber          AS LineNumber,
	|	ItemsToBeDebited.Products.Code     AS Code,
	|	ItemsToBeDebited.Products.SKU AS SKU,
	|	ItemsToBeDebited.Products         AS Products,
	|	ItemsToBeDebited.Products.DescriptionFull   AS ProductsPresentation,
	|	ItemsToBeDebited.Characteristic.DescriptionFull AS Characteristic,
	|	PRESENTATION(ItemsToBeDebited.Series) AS SeriesPresentation,
	|	CASE
	|		WHEN ItemsToBeDebited.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN ItemsToBeDebited.Products.UnitOfMeasure.Description
	|		ELSE ItemsToBeDebited.Package.Description
	|	END                                AS UnitOfMeasure,
	|	ItemsToBeDebited.NumberOfPackages   AS Count,
	|	ItemsToBeDebited.Price                 AS Price,
	|	ItemsToBeDebited.Sum                AS Sum
	|FROM
	|	Document.ReportOnVMIAdjustment.Goods AS ItemsToBeDebited
	|WHERE
	|	ItemsToBeDebited.Ref IN (&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	FirstDocument = True;
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes   = ValueIsFilled(NameOfCodeColumn);
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReportOnVMIAdjustment_Invoice";

	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate(
					"Document.ReportOnVMIAdjustment.PF_MXL_RetirementCertificateOfGoodsReceivedForStorage");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		If UseBusinessUnits Then
			TemplateArea = Template.GetArea("Title");
		Else
			TemplateArea = Template.GetArea("TitleWithoutDivision");
		EndIf;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea,
			PrintData.Ref);
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
			And PrintData.BusinessOperation <> Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
			CaptionPresentation =
				NStr("vi = 'Biên bản ghi giảm hàng hóa đã nhận vào nơi cất giữ';
					|ru = 'Акт о списании принятых на хранение товаров';
					|en = 'VMI adjustment'; fa = 'تعدیل VMI';
					|it = 'Verbale di accettazione delle merci accettate in custodia';
					|pl = 'Akt odpisu przyjętych na przechowywanie towarów';
					|tr = 'Depoya alınan malların gider yazma raporu'", Common.DefaultLanguageCode());
		Else
			CaptionPresentation = NStr("vi = 'Biên bản ghi giảm hàng hóa của bên đặt gia công';
										|ru = 'Акт о списании товаров давальца';
										|en = 'Provider stock shortage recognition'; fa = 'Provider stock shortage recognition';
										|it = 'Atto di storno delle merci del fornitore';
										|pl = 'Protokół o rozchodowaniu towarów właściciela surowców';
										|tr = 'Sağlayıcı mallarının gider yazma raporu'", Common.DefaultLanguageCode());
		EndIf;
		TitleText            = TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData,
			CaptionPresentation);
		OrganizationPresentation  = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		VendorPresentation    = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Vendor, PrintData.Date), "FullDescr");
		SubsectionView = PrintData.DepartmentPresentation;
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText",           TitleText);
		HeaderDataStructure_1.Insert("Organization",              PrintData.Organization);
		HeaderDataStructure_1.Insert("OrganizationPresentation", OrganizationPresentation);
		HeaderDataStructure_1.Insert("Vendor",                PrintData.Vendor);
		HeaderDataStructure_1.Insert("VendorPresentation",   VendorPresentation);
		
		If UseBusinessUnits Then
			HeaderDataStructure_1.Insert("Department",              PrintData.Department);
			HeaderDataStructure_1.Insert("DepartmentPresentation", SubsectionView);
		EndIf;
		
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		WriteOffAtOurExpense =
			PrintData.BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
			Or PrintData.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
			Or False;
		
		NamesOfRegions = NamesOfRegions(WriteOffAtOurExpense);
		
		ProductColumnArea = Template.Area("FirstColumnOfGoods");
		ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
											+ ?(OutputCodes, 0, Template.Area("ColumnOfCodes").ColumnWidth);
		
		RoomArea = Template.GetArea(NamesOfRegions.TableHeader + "|LineNumber");
		AreaCodes  = Template.GetArea(NamesOfRegions.TableHeader + "|ColumnOfCodes");
		ProductArea  = Template.GetArea(NamesOfRegions.TableHeader + "|" + NamesOfRegions.OwnGoods);
		DataArea = Template.GetArea(NamesOfRegions.TableHeader + "|" + NamesOfRegions.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		LineNumberArea = Template.GetArea(NamesOfRegions.String + "|LineNumber");
		StringCodeArea  = Template.GetArea(NamesOfRegions.String + "|ColumnOfCodes");
		ProductAreaRows  = Template.GetArea(NamesOfRegions.String + "|" + NamesOfRegions.OwnGoods);
		RowDataArea = Template.GetArea(NamesOfRegions.String + "|" + NamesOfRegions.Data);
		
		Sum       = 0;
		LineNumber = 0;
		
		// Output the rows of the Goods table
		ProductSelection_1 = SelectionByDocuments.Select();
		
		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			
			SetParameter(LineNumberArea, "LineNumber", LineNumber);
			SpreadsheetDocument.Put(LineNumberArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				
				StringCodeArea.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(StringCodeArea);
			EndIf;
			
			ProductAreaRows.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(ProductSelection_1.ProductsPresentation,
																				ProductSelection_1.Characteristic,
																				Undefined,
																				ProductSelection_1.SeriesPresentation,
																				AdditionalParametersProductPresentation);
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductAreaRows.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductAreaRows);
			
			RowDataArea.Parameters.Fill(ProductSelection_1);
			
			SpreadsheetDocument.Join(RowDataArea);
			
			Sum = Sum + ProductSelection_1.Sum;
			
		EndDo;
		
		// We output the basement
		RoomArea = Template.GetArea(NamesOfRegions.TableFooter + "|LineNumber");
		AreaCodes  = Template.GetArea(NamesOfRegions.TableFooter + "|ColumnOfCodes");
		ProductArea  = Template.GetArea(NamesOfRegions.TableFooter + "|" + NamesOfRegions.OwnGoods);
		DataArea = Template.GetArea(NamesOfRegions.TableFooter + "|" + NamesOfRegions.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		If WriteOffAtOurExpense Then
			TotalDataStructure = New Structure;
			TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
			
			DataArea.Parameters.Fill(TotalDataStructure);
		EndIf;
		
		SpreadsheetDocument.Join(DataArea);
		
		// We output the Amount in words
		TemplateArea = Template.GetArea(NamesOfRegions.TotalCount1);
		
		DataStructureSumInWords = New Structure;
		
		If WriteOffAtOurExpense Then
			AmountToBeRegistered = Sum;
			AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
			
			TotalString = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Tổng số mục: %1, thành tiền %2';
									|ru = 'Всего наименований: %1, на сумму %2';
									|en = 'Total items: %1, to the amount %2'; fa = 'Total items: %1, to the amount %2';
									|it = 'Totale articoli: %1, per importo di %2';
									|pl = 'Razem pozycji: %1, na wartość %2';
									|tr = 'Toplam tanım: %1, tutar %2'", Common.DefaultLanguageCode()),
								LineNumber,
								PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
			
			DataStructureSumInWords.Insert("AmountInWords", AmountInWords);
		Else
			TotalString = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Tổng số mặt hàng: %1';
									|ru = 'Всего наименований: %1';
									|en = 'Total items: %1'; fa = 'Total items: %1';
									|it = 'Totale articoli: %1';
									|pl = 'Razem pozycji: %1';
									|tr = 'Toplam tanım: %1'", Common.DefaultLanguageCode()),
								LineNumber);
		EndIf;
		
		DataStructureSumInWords.Insert("TotalString", TotalString);
		
		TemplateArea.Parameters.Fill(DataStructureSumInWords);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.EmployeeResponsible) Then
			EmployeeResponsible = PersonsTM.IndividualShortName(PrintData.EmployeeResponsible, PrintData.Date);
			
			DataStructureResponsible = New Structure;
			DataStructureResponsible.Insert("EmployeeResponsible", EmployeeResponsible);
			
			TemplateArea.Parameters.Fill(DataStructureResponsible);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

Function NamesOfRegions(WriteOffAtOurExpense)
	
	ReturnStructure = New Structure("TableFooter, OwnGoods, Data, String, TableHeader, TotalCount1");
	
	If WriteOffAtOurExpense Then
		ReturnStructure.TableFooter = "BasementTableWithSum";
		ReturnStructure.OwnGoods = "ProductWithAmount";
		ReturnStructure.Data = "DataWithAmount";
		ReturnStructure.String = "SumLine";
		ReturnStructure.TableHeader = "HeaderOfTableWithAmount";
		ReturnStructure.TotalCount1 = "TotalQuantityWithSum";
	Else
		ReturnStructure.TableFooter = "TableFooter";
		ReturnStructure.OwnGoods = "OwnGoods";
		ReturnStructure.Data = "Data";
		ReturnStructure.String = "String";
		ReturnStructure.TableHeader = "TableHeader";
		ReturnStructure.TotalCount1 = "TotalCount1";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Receives the print data
// 
// Parameters:
//  ObjectsArray - Array - array of print objects
//  PrintParameters - Structure - print options
// 
// Returns:
//  Structure - LongDesc:
//    * HeaderResults - QueryResult - the sample on the cap
//    * ResultForTabularPart - QueryResult - table-based selection
//
Function GetDataToPrint(ObjectsArray, PrintParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryKinds.Ref                                                       AS Ref,
	|	InventoryKinds.Ref.Date                                                  AS Date,
	|	InventoryKinds.Ref.Organization.RegistrationCountry                         AS RegistrationCountry,
	|	InventoryKinds.LineNumber                                                  AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products                      AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Products.DescriptionFull   AS ProductFullName,
	|	InventoryKinds.ItemsLocationAttributes.Products.Code                  AS Code,
	|	InventoryKinds.ItemsLocationAttributes.Products.SKU              AS SKU,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic                    AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic.DescriptionFull AS CharacteristicFullName,
	|	InventoryKinds.NumberOfPackages                                           AS Count,
	|	CASE
	|		WHEN InventoryKinds.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN InventoryKinds.Package.DescriptionFull
	|		ELSE InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure.DescriptionFull
	|	END                                                                    AS UnitOfMeasure,
	|	0                                                                        AS Price,
	|	0                                                                        AS Sum,
	|	0                                                                        AS VATAmount,
	|	0                                                                        AS AmountIncludingVAT
	|INTO InventoryKinds
	|FROM
	|	Document.ReportOnVMIAdjustment.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&DocumentsArray)
	|	AND InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|
	|INDEX BY
	|	RegistrationCountry,
	|	Date,
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryKinds.Date              AS Date,
	|	InventoryKinds.RegistrationCountry AS RegistrationCountry,
	|	InventoryKinds.Products      AS Products
	|INTO VATRatesProductDataLinks
	|FROM
	|	InventoryKinds AS InventoryKinds
	|	
	|INDEX BY
	|	RegistrationCountry,
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRatesProductDataLinks.Date              AS Date,
	|	VATRatesProductDataLinks.RegistrationCountry AS RegistrationCountry,
	|	VATRatesProductDataLinks.Products      AS Products,
	|	MAX(ProductsVATRates.Period)             AS Period
	|INTO ProductsVATRatesPeriod
	|FROM
	|	VATRatesProductDataLinks AS VATRatesProductDataLinks
	|	LEFT JOIN InformationRegister.ProductsVATRates AS ProductsVATRates
	|	ON VATRatesProductDataLinks.RegistrationCountry = ProductsVATRates.Country
	|	 AND VATRatesProductDataLinks.Products      = ProductsVATRates.Products
	|	 AND VATRatesProductDataLinks.Date             >= ProductsVATRates.Period
	|
	|GROUP BY
	|	VATRatesProductDataLinks.Date,
	|	VATRatesProductDataLinks.RegistrationCountry,
	|	VATRatesProductDataLinks.Products
	|
	|INDEX BY
	|	RegistrationCountry,
	|	Products,
	|	Date,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryKinds.Date              AS Date,
	|	InventoryKinds.RegistrationCountry AS RegistrationCountry
	|INTO BasicVATRatesCommunicationData
	|FROM
	|	InventoryKinds AS InventoryKinds
	|	
	|INDEX BY
	|	RegistrationCountry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRatesCommunicationData.Date              AS Date,
	|	BasicVATRatesCommunicationData.RegistrationCountry AS RegistrationCountry,
	|	MAX(BasicVATRates.Period)             AS Period
	|INTO BasicVATRatesPeriod
	|FROM
	|	BasicVATRatesCommunicationData AS BasicVATRatesCommunicationData
	|	LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
	|	ON BasicVATRatesCommunicationData.RegistrationCountry = BasicVATRates.Country
	|	 AND BasicVATRatesCommunicationData.Date             >= BasicVATRates.Period
	|
	|GROUP BY
	|	BasicVATRatesCommunicationData.Date,
	|	BasicVATRatesCommunicationData.RegistrationCountry
	|
	|INDEX BY
	|	RegistrationCountry,
	|	Date,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Ref                                              AS Ref,
	|	InventoryKinds.LineNumber                                         AS LineNumber,
	|	InventoryKinds.Products                                        AS Products,
	|	InventoryKinds.ProductFullName                      AS ProductFullName,
	|	InventoryKinds.Code                                                 AS Code,
	|	InventoryKinds.SKU                                             AS SKU,
	|	InventoryKinds.Characteristic                                      AS Characteristic,
	|	InventoryKinds.CharacteristicFullName                    AS CharacteristicFullName,
	|	InventoryKinds.Count                                          AS Count,
	|	InventoryKinds.UnitOfMeasure                                    AS UnitOfMeasure,
	|	InventoryKinds.Price                                                AS Price,
	|	InventoryKinds.Sum                                               AS Sum,
	|	InventoryKinds.VATAmount                                            AS VATAmount,
	|	InventoryKinds.AmountIncludingVAT                                           AS AmountIncludingVAT,
	|	ISNULL(ProductsVATRates.VATRate,
	|	         ISNULL(BasicVATRates.VATRate,
	|	                  VALUE(Catalog.VATRates.EmptyRef))) AS VATRate
	|FROM
	|	InventoryKinds AS InventoryKinds
	|		
	|		LEFT JOIN ProductsVATRatesPeriod AS ProductsVATRatesPeriod
	|		ON InventoryKinds.RegistrationCountry = ProductsVATRatesPeriod.RegistrationCountry
	|		 AND InventoryKinds.Products      = ProductsVATRatesPeriod.Products
	|		 AND InventoryKinds.Date              = ProductsVATRatesPeriod.Date
	|
	|		LEFT JOIN InformationRegister.ProductsVATRates AS ProductsVATRates
	|		ON ProductsVATRatesPeriod.RegistrationCountry = ProductsVATRates.Country
	|		 AND ProductsVATRatesPeriod.Products      = ProductsVATRates.Products
	|		 AND ProductsVATRatesPeriod.Period            = ProductsVATRates.Period
	|		
	|		LEFT JOIN BasicVATRatesPeriod AS BasicVATRatesPeriod
	|		ON InventoryKinds.RegistrationCountry = BasicVATRatesPeriod.RegistrationCountry
	|		 AND InventoryKinds.Date              = BasicVATRatesPeriod.Date
	|
	|		LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
	|		ON BasicVATRatesPeriod.RegistrationCountry = BasicVATRates.Country
	|		 AND BasicVATRatesPeriod.Period            = BasicVATRates.Period
	|
	|ORDER BY
	|	InventoryKinds.Ref,
	|	InventoryKinds.LineNumber
	|TOTALS BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref                        AS Ref,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	DocumentData.Partner                       AS Partner,
	|	DocumentData.Counterparty                    AS Counterparty,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Currency                        AS Currency,
	|	FALSE                                          AS PriceIncludesVAT,
	|	TRUE                                        AS ConsiderVAT,
	|	""""                                          AS AdditionalInformation,
	|	""""                                          AS AdditionalInformationOfHeader,
	|	DocumentData.CompanyBankAccount     AS BankAccountOfCompany,
	|	DocumentData.CounterpartyBankAccount     AS AccountOfCounterparty,
	|	&ProcessingService                          AS ProcessingService
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|";
	
	Query.SetParameter("DocumentsArray",    ObjectsArray);
	Query.SetParameter("ProcessingService", NStr("vi = 'Chuyển nguyên vật liệu gia công';
												|ru = 'Переработка давальческих материалов';
												|en = 'Sales orders — Subcontracting'; fa = 'Sales orders — Subcontracting';
												|it = 'Elaborazione dei materiali del fornitore';
												|pl = 'Przetworzenie materiałów właścicieli surowców';
												|tr = 'Sağlayıcı malzemelerinin yeniden işlenmesi'"));
	
	ResultsArray = Query.ExecuteBatch();
	
	UBound = ResultsArray.UBound();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",          ResultsArray[UBound]);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultsArray[UBound - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function PrintingDataOfMaterialsReport(ObjectsArray)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentData.Ref              AS Ref,
	|	DocumentData.Number               AS Number,
	|	DocumentData.Date                AS Date,
	|	DocumentData.Partner             AS Partner,
	|	DocumentData.Counterparty          AS Counterparty,
	|	DocumentData.Organization         AS Organization,
	|	DocumentData.Organization.Prefix AS Prefix
	|FROM
	|	Document.ReportOnVMIAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Return Query.Execute().Select();
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

Function FullObjectName()
	
	Return "Document.ReportOnVMIAdjustment";
	
EndFunction

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
	
EndProcedure

Procedure SetVisibilityOfCreationCommandsBasedOn(CreationCommands)
	
	TransactionList = New ValueList;
	TransactionList.Add(Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses);
	TransactionList.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses);
	For Each Command In CreationCommands Do
		If Command <> Undefined Then
			AttachableCommands.AddCommandVisibilityCondition(
				Command,
				"BusinessOperation",
				TransactionList,
				DataCompositionComparisonType.InList);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf