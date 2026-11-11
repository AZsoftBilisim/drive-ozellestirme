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
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);	
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
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	RedemptionOfGoodsFromStorageLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.RedemptionOfGoodsFromStorage") Then
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
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		RedemptionOfGoodsFromStorageLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
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

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	RedemptionOfGoodsFromStorageLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	Documents.ReverseVATAccrual.AddGenerateCommand(GenerationCommands);
	Documents.RedemptionOfGoodsByCustodian.AddCommandToCreateBasedOnRedemptionOfGiverSGoods(GenerationCommands);
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	RedemptionOfGoodsFromStorageLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef - link to the document.
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
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
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
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation,
			Enums.BusinessTransactions.RedemptionOfGoodsFromStorage);
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
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = 0;
		AmountARAP = 0;
		Repetition = 1;
		Rate = 1;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date",                    Date);
	AttributesStructure1.Insert("Partner",                 Partner);
	AttributesStructure1.Insert("Counterparty",              Counterparty);
	AttributesStructure1.Insert("Organization",             Organization);
	AttributesStructure1.Insert("Contract",                 Contract);
	AttributesStructure1.Insert("Currency",                  Currency);
	AttributesStructure1.Insert("Rate",                    Rate);
	AttributesStructure1.Insert("Repetition",               Repetition);
	AttributesStructure1.Insert("ARAPCurrency",    ARAPCurrency);
	AttributesStructure1.Insert("ARAPObjectSettings",         ARAPObjectSettings);
	AttributesStructure1.Insert("DocumentAmount",          DocumentAmount);
	AttributesStructure1.Insert("AmountARAP",     AmountARAP);
	AttributesStructure1.Insert("BusinessOperation",   BusinessOperation);
	
	Return AttributesStructure1;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Mua lại hàng hóa được nhận để bảo quản';
							|ru = 'Выкуп принятых на хранение товаров';
							|en = 'Redemption of VMI'; fa = 'Redemption of VMI';
							|it = 'Riscatto delle merci accettate in deposito';
							|pl = 'Wykup przyjętych do przechowywania towarów';
							|tr = 'Depoya alınan malların itfası'"));
	RedemptionOfGoodsFromStorageLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return RedemptionOfGoodsFromStorageLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return RedemptionOfGoodsFromStorageLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

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
	SeriesSpecificationParameters.FullObjectName = "Document.RedemptionOfGoodsFromStorage";
	
	EmptyStructure = New Structure();
	UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse", EmptyStructure)
										Or GetFunctionalOption("UseItemsBatchProduction", EmptyStructure);
	UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse", EmptyStructure)
										Or GetFunctionalOption("UseCostAccountingByBatchesProduction", EmptyStructure);
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice    = True;
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.Date = Object.Date;
	
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
	|	Goods.Purpose          AS Purpose,
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
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.StorageType    AS StorageType,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN SeriesAccountingPoliciesForWarehouses.BatchAccountingPolicy IS NULL
	|				AND SeriesAccountingPoliciesByDivision.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN SeriesAccountingPoliciesForWarehouses.BatchAccountingPolicy.UseCostAccountingByBatches
	|						OR SeriesAccountingPoliciesByDivision.BatchAccountingPolicy.UseCostAccountingByBatches
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
	|								OR FALSE THEN
	|									CASE
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
	|	ON SeriesAccountingPoliciesByDivision.Warehouse = Goods.Department
	|	AND CAST(Goods.Products AS Catalog.Products).ProductKind = SeriesAccountingPoliciesByDivision.Ref
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
	|	Statuses.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Statuses.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract) THEN
	|			Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE
	|			Statuses.BatchesIndicationStatus
	|	END               AS BatchesIndicationStatus
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

#Region CreatingHyperlinkInProcurementDocumentLog

// Returns the text of the hyperlink for the transition from the document log to the workplace for processing purchases.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//	FormattedString - the text of the hyperlink of the transition to the workplace of registration of ransoms.
//
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanySafeStock)
		Or Not AccessRight("Update", Metadata.Documents.RedemptionOfGoodsFromStorage) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Mua lại';
						|ru = 'Выкупы';
						|en = 'Redemptions'; fa = 'Redemptions';
						|it = 'Riscatti';
						|pl = 'Wykupy';
						|tr = 'İtfalar'");
	
	Query = New Query;
	Query.SetParameter("IssueRansoms", True); 
	
	Query.SetParameter("Recipient", Parameters.Organization);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	SelectionByFullDocumentName = New Structure("FullDocumentName", "Document.RedemptionOfGoodsFromStorage");
	RowsArray = Parameters.BusinessTransactionsAndDocuments.FindRows(SelectionByFullDocumentName);
	If RowsArray.Count() > 0 Then
		
		TypesOfRedemptionStocks = New Array;
		TypesOfRedemptionStocks.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
		
		If RowsArray[0].BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
			TypesOfRedemptionStocks.Clear();
			TypesOfRedemptionStocks.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
			TypesOfRedemptionStocks.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
			TypesOfRedemptionStocks.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
		EndIf;
		
		Query.SetParameter("TypesOfRedemptionStocks", TypesOfRedemptionStocks);
		
	EndIf;
	Query.Text = InventoriesServer.TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query, "SamplingPresenceOfRecords");
		
	If Not Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText, , , ,
			"DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions");
	Else
		Return New FormattedString(HyperlinkText, , StyleColors.EmptyTableField, ,
			"DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions");
	EndIf;
	
EndFunction

#EndRegion

// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	// Goods accepted for storage
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ = "Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)";
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|AND Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterials22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterialsForStage22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway2_5));
	// Delivery under the principal
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.Contract  = "Object.Contract";
	
	DestinationPattern.AssignmentTypes = New Array;
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.DeliveryForPrincipal);
	
	// Giveaway goods
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_    =
		"Object.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.Partner                 = "Object.Partner";
	DestinationPattern.Contract                 = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ ấn định lĩnh vực hoạt động ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Yalnızca ""%1"" faaliyet destinasyonları '"));
	// In stock
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "WarehouseSupport");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)";
	
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse          = "Object.Goods.Warehouse";
	
	// Available in the division
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "ProvisionByDivision");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.StorageType = VALUE(Enum.StorageLocationTypes.Department)";
	
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse          = "Object.Goods.Department";
	
	// Available from the keeper
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", True, "Object.Goods.Purpose", "ContractCollateral");
	
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)";
	
	Return FormTemplate;
	
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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.RedemptionOfGoodsFromStorage, DocumentObject.RedemptionOfGoodsFromStorage - document for the purchase of goods from storage.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the tax levy of the Purchase order().
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	DocumentAttributes = New Structure("Counterparty, Contract, Date");
	
	If TypeOf(Document) = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillPropertyValues(FillParameters, DocumentAttributes);
	FillParameters.Period = DocumentAttributes.Date;
	
	FillParameters.PurchaseOfGoods = True;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.RedemptionOfGoodsFromStorage, DocumentObject.RedemptionOfGoodsFromStorage - document for the purchase of goods from storage.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Contract, LineOfBusiness, Department");
	
	If TypeOf(Document) = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes, "Date, Organization, Contract, LineOfBusiness, Department");
	
	FillParameters.PurchaseOfGoods = True;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for registering received invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.RedemptionOfGoodsFromStorage, DocumentObject.RedemptionOfGoodsFromStorage - document for the purchase of goods from storage.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of invoices received().
//
Function ParametersForRegisteringInvoicesReceived(Document) Export
	
	DocumentAttributes = New Structure("Ref, Date, Organization, Counterparty, VATTaxation");
	
	If TypeOf(Document) = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, Organization, Counterparty, VATTaxation");
	
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters- Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase	= True;
	ParametersStructure.PaymentType_			= Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	If Not FillingData = Undefined
		And FillingData.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	EndIf;
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.ARAPObject                              = "Object.ARAPObject";
	ParametersStructure.PathToTSData                    			= "Object.Goods";
	
	ParametersStructure.ARAPCurrency             			= "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              			= "Object.AmountARAP";
	
	ParametersStructure.FormItems.AmountOfTSSettlements         = "GoodsAmountARAP";
	
	ParametersStructure.PathToTSDataPaymentDecryption  			= "Object.ARAPDetails";
	ParametersStructure.CashAccount                            			= "";
	
	ParametersStructure.Manager                         			= "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          			= "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           			= "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  			= "Object.ExternalDocumentName";
	ParametersStructure.FormItems.PaymentSettlement        			= "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup  		= "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness 		= "LineOfBusiness";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	ParametersStructure.CourseNumerator                               = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                             = "Object.CourseDenominator";
	ParametersStructure.FormItems.LabelCurrencies      			= "CurrencyDecoration";
	
	#EndRegion

	#Region ScheduledPaymentScheduleAndPaymentDate
	
	ParametersStructure.PaymentDate                      			= "Object.PaymentDate";
	
	#EndRegion
		
	#Region MutualSettlementsStatus
	
	ParametersStructure.FormItems.LabelCurrencies        			= "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages         			= "DecorationPaymentSteps";
	ParametersStructure.PaymentStepsText                 			= "Form.PaymentStepsText";
	ParametersStructure.FormItems.InscriptionCalculations       			= "DecorationSettlementState";
	
	#EndRegion
	
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

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	If Data.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
		DocumentSynonym = TollingSchemeClientServer.SynonymForDocumentRedemptionOfGoodsAcceptedForStorage();
	Else
		DocumentSynonym = NStr("vi = 'Mua lại hàng hóa từ kho';
								|ru = 'Выкуп товаров с хранения';
								|en = 'Purchase invoice — VMI'; fa = 'فاکتور خرید — VMI';
								|it = 'Riscatto delle merci dal deposito';
								|pl = 'Wykup towarów z depozytu';
								|tr = 'Satın alma faturası - VMI'");
	EndIf;
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), DocumentSynonym, Data.Number, Data.Date);
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "RedemptionOfGoodsFromStorage");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("BusinessOperation");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                   AS ContractSettlements,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Department           AS Department,
	|	DocumentData.VendorPriceKind       AS VendorPriceKind,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.VATTaxation      AS VATTaxation,
	|	DocumentData.PaymentMethod             AS PaymentMethod,
	|	DocumentData.PaymentDate             AS PaymentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate  AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.RedemptionForActivity    AS RedemptionForActivity,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	CASE
	|		WHEN DocumentData.Contract.ContractType = VALUE(Enum.ContractTypes.CustomerInvoiceOutsourcedSale)
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                    AS ExecutionOfRedemptionOfGoodsOfPrincipal,
	|	DocumentData.ARAPObject          AS ARAPObject,
	|	ISNULL(BusinessTransactionsSettings.Ref,
	|		VALUE(Catalog.BusinessTransactionsSettings.RedemptionOfGoodsFromStorage)) AS BusinessTransactionSetting
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
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
	ContractInformation    = "";
	
	UseAccountingOfOtherIncomeExpenses = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	GenerateInventoryOwnerAttributesByFinancialAccountingGroups = GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups");
	
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
	Query.SetParameter("ContractInformation",           ContractInformation);
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", UseAccountingOfOtherIncomeExpenses);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GenerateInventoryOwnerAttributesByFinancialAccountingGroups);
	Query.SetParameter("UseSeparateAccountingByTaxation",
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Attributes.Organization, Attributes.Period));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	HeaderData_.Date                    AS Period,
	|	InventoryTable.Ref               AS Ref,
	|	HeaderData_.BusinessOperation   AS BusinessOperation,
	|	HeaderData_.Organization             AS Organization,
	|	HeaderData_.Department           AS Department,
	|	HeaderData_.Counterparty              AS Counterparty,
	|	HeaderData_.Contract                 AS Contract,
	|	UNDEFINED                        AS Shipper,
	|	InventoryTable.Ref               AS DocumentAcquisitions,
	|	InventoryTable.Ref               AS OriginalTradeDocument,
	|	FALSE                                AS ErrorCorrection,
	|	FALSE                                AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                AS ReduceAmountVATDeduction,
	|	UNDEFINED                        AS PurchaseAdjustmentDocument,
	|	HeaderData_.VATTaxation      AS VATTaxation,
	|	HeaderData_.RedemptionForActivity    AS VATActivityType,
	|	Dimension.Products              AS Products,
	|	Dimension.Characteristic            AS Characteristic,
	|	InventoryTable.VATRate            AS VATRate,
	|	InventoryTable.RedeemedInventoryOwnerAttributes AS InventoryOwnerAttribute,
	|	InventoryTable.CCDNumber             AS CCDNumber,
	|	InventoryTable.RowID  AS RowID,
	|	UNDEFINED                        AS AccountingDivision,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	FALSE                                AS PurchasePerBatchOfProduction,
	|	UNDEFINED                        AS LineOfBusinessOfProductionParty,
	|	UNDEFINED 						AS ToExpenseAs,
	|	UNDEFINED                        AS ExpenseItem,
	|	UNDEFINED                        AS DimensionOfExpenses,
	|	UNDEFINED                        AS ItemOfOtherAssets,
	|	UNDEFINED                        AS AnalyticsOfOtherAssets,
	|	Dimension.Purpose                AS Purpose,
	|	HeaderData_.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.InventoryKinds AS InventoryTable
	|		LEFT JOIN Document.RedemptionOfGoodsFromStorage AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                                           AS Document,
	|	&Period                                                           AS Period,
	|	&Ref                                                           AS Recorder,
	|	SeriesTable.Products                                         AS Products,
	|	SeriesTable.Characteristic                                       AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                             AS Purpose,
	|	SeriesTable.Series                                                AS Series,
	|	SeriesTable.Count                                           AS Count,
	|	&Partner                                                          AS Sender,
	|	CASE
	|		WHEN SeriesTable.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN SeriesTable.Warehouse
	|		WHEN SeriesTable.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN SeriesTable.Custodian
	|		WHEN SeriesTable.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN SeriesTable.Department
	|		ELSE
	|			UNDEFINED
	|	END                                                             AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)              AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	TRUE                                                            AS ThisIsWarehouseRecord
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	DocumentTable.AmountVATARAP AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
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
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	&Period                                       AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|			THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
	|		ELSE &BusinessOperation
	|	END                                         AS BusinessOperation,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	&VATTaxation                           AS VATTaxation,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes       AS CorInventoryOwnerAttribute,
	|	FALSE                                          AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&Period                                       AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes       AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|			THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
	|		ELSE &BusinessOperation
	|	END                                         AS BusinessOperation,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	UNDEFINED                                  AS VATTaxation,
	|	UNDEFINED                                  AS CorInventoryOwnerAttribute,
	|	FALSE                                          AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	MIN(GoodsTable.LineNumber)        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	GoodsTable.RedeemedInventoryOwnerAttributes        AS InventoryOwnerAttribute,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	&Ref                                   AS DocumentInflow,
	|
	|	SUM(GoodsTable.Count)           AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan)         AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan)       AS CostExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl)      AS LocalCost,
	|	SUM(CASE 
	|			WHEN GoodsTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|				THEN 0 
	|			ELSE GoodsTable.VATAmountCompl
	|		END)                                AS VATLocal,
	|	
	|	GoodsTable.LotVendorAttributes        AS LotVendorAttributes,
	|	GoodsTable.Products                AS Products,
	|	GoodsTable.Characteristic              AS Characteristic,
	|
	|	&BusinessOperation                    AS BusinessOperation,
	|	TRUE                                    AS Primary,
	|	UNDEFINED                              AS DocumentSource
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	&BatchAccountingVersion21
	|
	|GROUP BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.RedeemedInventoryOwnerAttributes,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
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
	|	CASE
	|		WHEN DocumentData.NumberOfStorageLocations = 1
	|			THEN DocumentData.StorageLocation
	|		ELSE UNDEFINED
	|	END                    AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&IncomingDocumentDate  AS SourceDocumentDate,
	|	&IncomingDocumentNumber AS SourceDocumentNumber,
	|	&ExternalDocumentName AS SourceDocumentName,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	TempTableName = "TTTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber                   AS LineNumber,
	|	Dimension.Products                           AS Products,
	|	Dimension.Characteristic                         AS Characteristic,
	|	Dimension.Series                                  AS Series,
	|	Dimension.StorageType                       AS StorageType,
	|	Dimension.WarehouseArea					 AS Warehouse,
	|	Dimension.StorageLocation							 AS StorageLocation,
	|	Dimension.Contract                                AS Contract,
	|	Dimension.Department                          AS Department,
	|	Dimension.Partner                                AS Partner,
	|	Dimension.Counterparty                             AS Counterparty,
	|	Dimension.WarehouseArea.ShopFloorStockroom    AS ShopFloorStockroom,
	|	Dimension.Purpose                             AS Purpose,
	|	ISNULL(Dimension.Purpose.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	KeysWithoutAssignment.DimensionKey                 AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes          AS RedeemedInventoryOwnerAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType         AS InventoryType,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes.InventoryType AS InventoryTypeRedeemable,
	|	TableTypesOfStocks_.CCDNumber                      AS CCDNumber,
	|	TableTypesOfStocks_.Count                    AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN              AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATAmount                      AS VATAmount,
	|	TableTypesOfStocks_.VATRate                     AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT                     AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountARAP           AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP        AS AmountVATARAP,
	|	TableTypesOfStocks_.RowID           AS RowID,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass           AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation    AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes  AS LotVendorAttributes,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                  AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)               AS AmountExcludingVATCompl,
	|
	|	ISNULL(Amounts.VATAmountCompl, 0)                  AS VATAmountCompl,
	|	ISNULL(Amounts.VATAmountMan, 0)                   AS VATAmountMan,
	|	ISNULL(Amounts.VATBaseLocal, 0)                   AS VATBaseLocal,
	|
	|	TableTypesOfStocks_.Ref.ARAPObject.UUID AS FinRecordID
	|INTO TTTypesOfStocks
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS KeysWithoutAssignment
	|		ON Dimension.Products = KeysWithoutAssignment.Products
	|			AND Dimension.Characteristic = KeysWithoutAssignment.Characteristic
	|			AND Dimension.Series = KeysWithoutAssignment.Series
	|			AND VALUE(Catalog.Assignments.EmptyRef) = KeysWithoutAssignment.Purpose
	|			AND Dimension.StorageLocation = KeysWithoutAssignment.StorageLocation
	|			AND Dimension.ProductCostElement = KeysWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableTypesOfStocks_.Ref = Amounts.Ref
	|			AND TableTypesOfStocks_.RowID = Amounts.RowID
	|	
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = TableTypesOfStocks_.LineNumber
	|			AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref        AS Ref,
	|	MAX(CASE
	|				WHEN ISNULL(GoodsTable.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Warehouse)
	|					THEN VALUE(Catalog.Warehouses.EmptyRef)
	|				WHEN ISNULL(GoodsTable.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|					THEN VALUE(Catalog.Partners.EmptyRef)
	|				WHEN ISNULL(GoodsTable.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Department)
	|					THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|				ELSE
	|					UNDEFINED
	|			END) AS StorageLocation,
	|	COUNT(DISTINCT CASE
	|				WHEN ISNULL(GoodsTable.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Warehouse)
	|					THEN VALUE(Catalog.Warehouses.EmptyRef)
	|				WHEN ISNULL(GoodsTable.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|					THEN VALUE(Catalog.Partners.EmptyRef)
	|				WHEN ISNULL(GoodsTable.StorageType, UNDEFINED) = VALUE(Enum.StorageLocationTypes.Department)
	|					THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|				ELSE
	|					UNDEFINED
	|			END) AS NumberOfStorageLocations
	|INTO TTBases
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
	|		LEFT JOIN Document.RedemptionOfGoodsFromStorage.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.RedemptionOfGoodsFromStorage.Name,
		"InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds""                      AS TabularSectionName,
	|	DocumentTable.LineNumber         AS LineNumber,
	|	DocumentData.Partner              AS Vendor,
	|	DocumentData.Counterparty           AS Counterparty,
	|	DocumentTable.VATRate           AS VATRate,
	|	DocumentData.RedemptionForActivity AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) AS AssetTaxClass,
	|	LineCodes.RowCode					 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.RedemptionOfGoodsFromStorage AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(
					TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Keys.Products   AS Products,
	|	Keys.Characteristic AS Characteristic,
	|	&EmptyAssignment    AS Purpose,
	|	Keys.Series          AS Series,
	|	Keys.StorageLocation	 AS Warehouse
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.InventoryKinds AS Goods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON Goods.ItemsLocationAttributes = Keys.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Keys.Products = Dimension.Products
	|			AND Keys.Characteristic = Dimension.Characteristic
	|			AND Keys.Series = Dimension.Series
	|			AND Keys.StorageLocation = Dimension.StorageLocation
	|			AND Keys.ProductCostElement = Dimension.ProductCostElement
	|			AND &EmptyAssignment = Dimension.Purpose
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

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
#Region RedemptionOfAcceptedGoods
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	&Manager AS Manager,
	|
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.InventoryTypeRedeemable AS InventoryType,
	|	GoodsTable.RedeemedInventoryOwnerAttributes AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE WHEN &ContractSettlements THEN
	|		&Contract
	|	ELSE
	|		&Ref
	|	END AS OrderDocument,
	|	UNDEFINED AS AdvanceHolder,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
	|		ELSE SUM(GoodsTable.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.RedeemedInventoryOwnerAttributes
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Department,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.Warehouse,
	|	GoodsTable.InventoryTypeRedeemable,
	|	GoodsTable.RedeemedInventoryOwnerAttributes,
	|	CASE WHEN &ContractSettlements THEN
	|		&Contract
	|	ELSE
	|		&Ref
	|	END,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.RedeemedInventoryOwnerAttributes
	|		ELSE GoodsTable.Products
	|	END,
	|	GoodsTable.VATActivityType
	|";
#EndRegion
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period AS DateOfReceipt,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Series AS Series,
	|	TableTypesOfStocks_.Purpose AS Purpose,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND TableTypesOfStocks_.Products = UninvoicedReceipts.Products
	|			AND TableTypesOfStocks_.Characteristic = UninvoicedReceipts.Characteristic
	|			AND TableTypesOfStocks_.Series = UninvoicedReceipts.Series
	|			AND TableTypesOfStocks_.Purpose = UninvoicedReceipts.Purpose
	|			AND TableTypesOfStocks_.CCDNumber = UninvoicedReceipts.CCDNumber
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON TableTypesOfStocks_.Products = CatProducts.Ref
	|WHERE
	|	CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (UninvoicedReceipts.DateOfReceipt IS NULL
	|			OR UninvoicedReceipts.DateOfReceipt < &Period)
	|
	|ORDER BY
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.Series,
	|	TableTypesOfStocks_.Purpose,
	|	TableTypesOfStocks_.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.RedemptionOfGoodsFromStorage";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
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
		|	Document.RedemptionOfGoodsFromStorage AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
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
		|	Table.AmountIncludingVAT                      AS Sum,
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
		|	Document.RedemptionOfGoodsFromStorage.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
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
		|	Table.Ref.Date                    AS PaymentDate,
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
		|	Document.RedemptionOfGoodsFromStorage.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|";

	#EndRegion
		
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_);
	
	TextReturn = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Ref.Organization             AS Organization,
		|	Table.Ref.Partner                 AS Partner,
		|	Table.Ref.ARAPObject          AS ARAPObject,
		|	Table.Ref.ARAPCurrency    AS ARAPCurrency,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	Table.AmountARAP            AS AmountARAP,
		|	Table.AmountIncludingVAT                      AS Sum,
		|	CASE
		|		WHEN Table.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			THEN 0
		|		ELSE Table.AmountIncludingVAT
		|	END                                  AS AmountDue,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	Table.Ref.Date                    AS DateOfCourse,
		|	Table.Ref.BusinessOperation   AS BusinessOperation,
		|	UNDEFINED                           AS CashFlowItem
		|FROM
		|	Document.RedemptionOfGoodsFromStorage.Goods AS Table
		|WHERE
		|	Table.Ref IN(&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|";
	
	TextTranscriptOfPayment = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Ref.Organization             AS Organization,
		|	Table.Ref.Partner                 AS Partner,
		|	Table.Ref.ARAPObject          AS CalculationObjectSource,
		|	Table.Ref.ARAPObject          AS CalculationObjectReceiver,
		|	Table.Sum                          AS Sum,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	Table.AmountARAP            AS AmountARAP,
		|	Table.Ref.ARAPCurrency    AS ARAPCurrency,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	Table.Ref.Date                    AS DateOfCourse
		|FROM
		|	Document.RedemptionOfGoodsFromStorage.Goods AS Table
		|WHERE
		|	Table.Ref IN(&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|";
	
	ARAPAccountingPostingCustomers.CarryingOutReturnOfGoodsFromCustomer(Query, QueryTexts, Registers, TextReturn, TextTranscriptOfPayment);
	
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
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Ref.BusinessOperation   AS BusinessOperation,
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
		|	Document.RedemptionOfGoodsFromStorage.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|	AND Table.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|";
	
	TextShipmentPlans =
		"SELECT
		|	Table.Purpose.OrderDocument					AS Ref,
		|	Table.Ref.Organization                  AS Organization,
		|	Table.Ref.Partner                      AS Partner,
		|	Table.Ref.ARAPObject				AS ARAPObject,
		|	
		|	ENDOFPERIOD(Table.Ref.Date, DAY)		AS DateOfShipment,
		|	Table.Sum								AS IncreaseToBeSHIPPED,
		|	Table.Sum								AS IncreaseShipping,
		|	Table.Ref.Date							AS RecorderDate,
		|	Table.Ref.Number						AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings				AS ARAPObjectSettings,
		|	Table.Ref.Currency						AS ARAPCurrency,
		|	Table.Ref.Currency						AS DocumentCurrency,
		|	Table.Ref.BusinessOperation		AS BusinessOperation,
		|	Table.Ref.PaymentMethod					AS PaymentMethod
		|	
		|FROM
		|	Document.RedemptionOfGoodsFromStorage.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|	AND Table.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|";
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	
EndProcedure

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
	
	#Region Sales_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	UNDEFINED 									AS VATActivityType,
	|	DocumentTable.VATTaxation				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	CASE WHEN &BatchAccountingVersion22 AND NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END											AS LotVendorAttributesCorr,
	|	UNDEFINED									AS AccountingDimensionByPartners,
	|	UNDEFINED 									AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID  AS RowID,
	|
	// Other fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|		THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
	|		ELSE DocumentTable.BusinessOperation
	|	END																		 AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 									 AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.WriteOffGoodsFromStorage) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region WriteOffToOtherConsignments_GiverSProduct
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.VATTaxation					AS VATActivityType,
	|	DocumentTable.RedemptionForActivity				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	DocumentTable.Ref								AS CorLot,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes				AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count			AS Count,
	|	TableTypesOfStocks_.RowID  AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation				AS BusinessOperation,
	|	TableTypesOfStocks_.RowID				AS FinRecordID,
	|	&BusinessTransactionSetting						AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);
		
	#EndRegion

	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	UNDEFINED		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.RedeemedInventoryOwnerAttributes				AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	DocumentTable.RedemptionForActivity				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID  		AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan					AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END											AS VATLocal,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountMan
	|	END											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	CASE
	|		WHEN TableTypesOfStocks_.StorageType = VALUE(Enum.StorageLocationTypes.Department)
	|		  OR TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN TableTypesOfStocks_.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			AND (TableTypesOfStocks_.Contract.ContractType = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|				OR TableTypesOfStocks_.Contract.ContractType = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN TableTypesOfStocks_.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END															AS AccountingSection,
	|
	// Other fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
	|		THEN VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage)
	|		ELSE DocumentTable.BusinessOperation
	|	END															AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			 			AS FinRecordID,
	|	&BusinessTransactionSetting                 				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
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

	// Receipt of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Mua lại hàng hóa được nhận để bảo quản';
									|ru = 'Выкуп принятых на хранение товаров';
									|en = 'Redemption of VMI'; fa = 'Redemption of VMI';
									|it = 'Riscatto delle merci accettate in deposito';
									|pl = 'Wykup przyjętych do przechowywania towarów';
									|tr = 'Depoya alınan malların itfası'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Mua lại hàng hóa được nhận để bảo quản';
											|ru = 'Выкуп принятых на хранение товаров';
											|en = 'Redemption of VMI'; fa = 'Redemption of VMI';
											|it = 'Riscatto delle merci accettate in deposito';
											|pl = 'Wykup przyjętych do przechowywania towarów';
											|tr = 'Depoya alınan malların itfası'");
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.RedemptionOfProviderGoods,
													  ComparisonType.NotEqual);
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "BillOfLading";
	PrintCommand.Presentation = TollingSchemeClientServer.SynonymForDocumentRedemptionOfGoodsAcceptedForStorage();
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Người đặt gia công mua lại hàng hóa';
											|ru = 'Выкуп товаров давальца';
											|en = 'Redemption of provider goods'; fa = 'Redemption of provider goods';
											|it = 'Riscatto articoli del fornitore';
											|pl = 'Wykup towarów właściciela surowców';
											|tr = 'Malların sağlayıcıdan itfası'");
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.RedemptionOfProviderGoods,
													  ComparisonType.Equal);
	
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
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Báo cáo về sản phẩm và nguyên vật liệu';
											|ru = 'Отчет о продукции и материалах';
											|en = 'Report on manufactured products and materials'; fa = 'گزارش محصولات تولیدی و مواد';
											|it = 'Report su prodotti e materiali';
											|pl = 'Raport o produkcji i materiałach';
											|tr = 'Ürün ve malzeme raporu'");
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
													  "BusinessOperation",
													  Enums.BusinessTransactions.RedemptionOfProviderGoods,
													  ComparisonType.Equal);
	RedemptionOfGoodsFromStorageLocalization.AddPrintCommands(PrintCommands);

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Invoice", NStr("vi = 'Phiếu nhập kho';
																									|ru = 'Накладная';
																									|en = 'Invoice'; fa = 'فاکتور';
																									|it = 'Lettera di vettura';
																									|pl = 'Invoice';
																									|tr = 'İrsaliye'"), FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "BillOfLading") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"BillOfLading",
			NStr("vi = 'Phiếu nhập kho';
				|ru = 'Накладная';
				|en = 'Invoice'; fa = 'فاکتور';
				|it = 'Lettera di vettura';
				|pl = 'Invoice';
				|tr = 'İrsaliye'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReportOnProductsAndMaterials") Then
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_RedemptionOfProviderGoods_ReportOnProductsAndMaterials";
		
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
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	RedemptionOfGoodsFromStorage.Ref AS Ref,
	|	RedemptionOfGoodsFromStorage.Number AS Number,
	|	RedemptionOfGoodsFromStorage.Date AS Date,
	|	RedemptionOfGoodsFromStorage.BusinessOperation AS BusinessOperation,
	|	RedemptionOfGoodsFromStorage.Manager AS Manager,
	|	RedemptionOfGoodsFromStorage.Counterparty AS Depository,
	|	RedemptionOfGoodsFromStorage.Organization AS Organization,
	|	RedemptionOfGoodsFromStorage.Organization.Prefix AS Prefix,
	|	RedemptionOfGoodsFromStorage.Currency AS Currency,
	|	RedemptionOfGoodsFromStorage.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN RedemptionOfGoodsFromStorage.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConsiderVAT
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS RedemptionOfGoodsFromStorage
	|WHERE
	|	RedemptionOfGoodsFromStorage.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentGoods.Ref AS Ref,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Products.DescriptionFull AS ProductNameFull_,
	|	DocumentGoods.Products.Code AS Code,
	|	DocumentGoods.Products.SKU AS SKU,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DocumentGoods.Products.UnitOfMeasure.Description
	|		ELSE DocumentGoods.Package.Description
	|	END AS UnitPrice,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DocumentGoods.Products.UnitOfMeasure
	|		ELSE DocumentGoods.Package
	|	END AS UnitOfMeasure,
	|	DocumentGoods.Characteristic.DescriptionFull AS Characteristic,
	|	DocumentGoods.Series.Description AS Series,
	|	DocumentGoods.VATRate AS VATRate,
	|	DocumentGoods.Price AS Price,
	|	DocumentGoods.Count AS Count,
	|	DocumentGoods.Sum AS Sum,
	|	DocumentGoods.VATAmount AS VATAmount,
	|	DocumentGoods.LineNumber
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&DocumentsArray)
	|	AND DocumentGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|ORDER BY
	|	DocumentGoods.Ref,
	|	DocumentGoods.LineNumber";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_RedemptionOfGoodsFromStorage_Invoice";
	
	ResultsArray 			= Query.ExecuteBatch();
	
	ResultPrintData		= ResultsArray[0]; // QueryResult
	ResultSampleByProduct	= ResultsArray[1]; // QueryResult
	
	PrintData				= ResultPrintData.Select();
	ProductSelection_1			= ResultSampleByProduct.Select();
	
	FirstDocument = True;
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While PrintData.Next() Do
				
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate("Document.RedemptionOfGoodsFromStorage.PF_MXL_RedemptionOfGoods");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		BarcodeArea_ = Template.GetArea("BarcodeArea_");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, BarcodeArea_, PrintData.Ref);
		SpreadsheetDocument.Put(BarcodeArea_);
		
		TitleText = NStr("vi = 'Mua lại hàng hóa được nhận để bảo quản';
						|ru = 'Выкуп принятых на хранение товаров';
						|en = 'Redemption of VMI'; fa = 'Redemption of VMI';
						|it = 'Riscatto delle merci accettate in deposito';
						|pl = 'Wykup przyjętych do przechowywania towarów';
						|tr = 'Depoya alınan malların itfası'");
		If PrintData.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
			TitleText = TollingSchemeClientServer.SynonymForDocumentRedemptionOfGoodsAcceptedForStorage();
		EndIf;
		TitleArea = Template.GetArea("Title");
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert(
			"TitleText",
			TMCommonUseClientServer.GenerateDocumentTitle(PrintData, TitleText));
		TitleArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TitleArea);
		
		TemplateArea = Template.GetArea("Depository");
		DataStructureDepositor = New Structure;
		PresentationOfDepositor = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Depository, PrintData.Date), "FullDescr");
		DataStructureDepositor.Insert("PresentationOfDepositor", PresentationOfDepositor);
		
		NameOfCounterpartyField = "Depository:";
		If PrintData.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods Then
			NameOfCounterpartyField = "MaterialProvider:";
		EndIf;
		DataStructureDepositor.Insert("NameOfCounterpartyField", NameOfCounterpartyField);
		
		TemplateArea.Parameters.Fill(DataStructureDepositor);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Recipient");
		RecipientDataStructure = New Structure;
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		RecipientDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		
		TemplateArea.Parameters.Fill(RecipientDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
							
		If OutputCodes Then
			
			Area_TableHeader 	= Template.GetArea("TableHeader");
			AreaTableRow 	= Template.GetArea("TableRow");
			TableBasementArea 	= Template.GetArea("TableFooter");
			
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			Area_TableHeader.Parameters.Fill(DataStructureCodes);
			
		Else
			
			Area_TableHeader 	= Template.GetArea("TableHeaderWithoutAdditionalColumn");
			AreaTableRow 	= Template.GetArea("TableRowWithoutAdditionalColumn");
			TableBasementArea 	= Template.GetArea("TableBasementWithoutAdditionalColumn");
			
		EndIf;
			
		SpreadsheetDocument.Put(Area_TableHeader);
			
		Sum          = 0;
		VATAmount       = 0;
		LineNumber    = 0;
		
		// Output the rows of the Goods table
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
			
		While ProductSelection_1.FindNext(TheStructureOfTheSearch) Do
			
			LineNumber = LineNumber + 1;
			
			StructureOfData = New Structure;
			StructureOfData.Insert("LineNumber", LineNumber);
			
			If OutputCodes Then
				StructureOfData.Insert("SKU", ProductSelection_1[NameOfCodeColumn]);
			EndIf;			
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				ProductSelection_1.Series,
				AdditionalParametersProductPresentation);
			StructureOfData.Insert("OwnGoods", OwnGoods);
			
			StructureOfData.Insert("Count", ProductSelection_1.Count);
			StructureOfData.Insert("UnitPrice", ProductSelection_1.UnitPrice);
			StructureOfData.Insert("Price", ProductSelection_1.Price);
			StructureOfData.Insert("Sum", ProductSelection_1.Sum);
			
			AreaTableRow.Parameters.Fill(StructureOfData);
			SpreadsheetDocument.Join(AreaTableRow);
			
			Sum = Sum + ProductSelection_1.Sum;
			VATAmount = VATAmount + ProductSelection_1.VATAmount;
			
		EndDo;
		
		TotalDataStructure = New Structure("Total", PrintFormGeneration.SumFormat(Sum));
		
		TableBasementArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Join(TableBasementArea);
		
		// We output the total of the ADS
		
		If PrintData.ConsiderVAT Then
			
			VATTableBasementArea  = Template.GetArea("VATTableBasement");
						
			VATDataStructure = New Structure;
			VATDataStructure.Insert("TotalVAT", PrintFormGeneration.SumFormat(VATAmount));
			VATDataStructure.Insert("VAT", 
				?(PrintData.PriceIncludesVAT, NStr("vi = 'Trong đó thuế GTGT:';
													|ru = 'В том числе НДС:';
													|en = 'Including VAT:'; fa = 'Including VAT:';
													|it = 'IVA compresa:';
													|pl = 'W tym VAT';
													|tr = 'KDV dahil:'", Common.DefaultLanguageCode()), NStr("vi = 'Thuế GTGT:';
																												|ru = 'Сумма НДС:';
																												|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
																												|it = 'Importo IVA:';
																												|pl = 'Wartość VAT';
																												|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			VATTableBasementArea.Parameters.Fill(VATDataStructure);
			SpreadsheetDocument.Join(VATTableBasementArea);
			
		EndIf;
		
		// We output the Amount in words
		
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số %1, thành tiền %2';
				|ru = 'Всего наименований %1, на сумму %2';
				|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
				|it = 'Totale articoli %1, per importo di %2';
				|pl = 'Razem pozycji %1, na kwotę %2';
				|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
			ProductSelection_1.Count(),
			PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
	
		DataStructureSummaryRow = New Structure;
		DataStructureSummaryRow.Insert("TotalString", TotalString);
		DataStructureSummaryRow.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
		TemplateArea.Parameters.Fill(DataStructureSummaryRow);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.Manager) Then
			DataStructureGettingProduced = New Structure;
			DataStructureGettingProduced.Insert("Manager", PersonsTM.IndividualShortName(PrintData.Manager, PrintData.Date));
			TemplateArea.Parameters.Fill(DataStructureGettingProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

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
	|	DocumentData.Ref                        AS Ref,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Date                          AS Date,
	|	DocumentData.Partner                       AS Partner,
	|	DocumentData.Counterparty                    AS Counterparty,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Organization.Prefix           AS Prefix,
	|	DocumentData.Currency                        AS Currency,
	|	DocumentData.PriceIncludesVAT               AS PriceIncludesVAT,
	|	CASE
	|		WHEN DocumentData.VATTaxation =
	|									VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                         AS ConsiderVAT,
	|	""""                                          AS AdditionalInformation,
	|	""""                                          AS AdditionalInformationOfHeader,
	|	DocumentData.CompanyBankAccount     AS BankAccountOfCompany,
	|	DocumentData.CounterpartyBankAccount     AS AccountOfCounterparty,
	|	&ProcessingService                          AS ProcessingService
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.Ref                                                       AS Ref,
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
	|	VALUE(Catalog.VATRates.EmptyRef)                              AS VATRate,
	|	0                                                                        AS Sum,
	|	0                                                                        AS VATAmount,
	|	0                                                                        AS AmountIncludingVAT
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&DocumentsArray)
	|	AND InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|ORDER BY
	|	InventoryKinds.Ref,
	|	InventoryKinds.LineNumber
	|TOTALS BY
	|	Ref";
	
	Query.SetParameter("DocumentsArray",    ObjectsArray);
	Query.SetParameter("ProcessingService", NStr("vi = 'Chuyển nguyên vật liệu gia công';
												|ru = 'Переработка давальческих материалов';
												|en = 'Sales orders — Subcontracting'; fa = 'Sales orders — Subcontracting';
												|it = 'Elaborazione dei materiali del fornitore';
												|pl = 'Przetworzenie materiałów właścicieli surowców';
												|tr = 'Sağlayıcı malzemelerinin yeniden işlenmesi'"));
	
	ResultsArray = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",          ResultsArray[0]);
	DataStructureForPrinting.Insert("ResultForTabularPart", ResultsArray[1]);
	
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
	|	Document.RedemptionOfGoodsFromStorage AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref";
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Return Query.Execute().Select();
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
EndProcedure

#EndRegion

#Region Other

Function FullObjectName()
	Return "Document.RedemptionOfGoodsFromStorage";
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

#Region Posting

#EndRegion

#EndRegion

#EndIf
