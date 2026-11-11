#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
//  String - Presentation Of An Object In The Main Language
//
Function PresentationOfObjectInMainLanguage() Export
	
	SynonymForInformationDatabaseEntry = NStr("vi = 'Đơn hàng của bên đặt gia công';
												|ru = 'Заказ давальца';
												|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
												|it = 'Ordine del committente';
												|pl = 'Zamówienie właściciela surowców';
												|tr = 'Sağlayıcı siparişi'", Common.DefaultLanguageCode());
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn  = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "WarehouseForReceipt", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Manager, Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn  = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize               = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways            = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn             = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize               = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Contract, BusinessOperation";
	Parameters.FillInIf.ObjectFieldsFilledIn  = "Contract";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "ProcessingService, VATRate", Parameters);
	
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
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("AcceptanceForProcessing");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	
	MaterialProviderOrder2_5Localization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.MaterialProviderOrder2_5") Then
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
		
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		QueryTextTablePurchaseOrders(Query, QueryTexts, Registers);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	ReflectReserve(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region StandardSubsystems

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
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	ObjectManager = Metadata.Documents.ProductionOrder2_2;
	If AccessRight("Insert", ObjectManager) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = ObjectManager.FullName();
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(ObjectManager);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction";
		CreateBasedOnCommand.Handler          = 
			"GenerationByReferenceTMClient.CreateProductionOrder22BasedOnGiverSOrder2_5";
		
	EndIf;
	
	Command = Documents.SubcontractOrder2_5.AddCreateSecuringOrderCommand(GenerationCommands);
	If Command <> Undefined Then
		
		ListOfBusinessTransactions = New Array;
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TollManufacturing2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation", ListOfBusinessTransactions, DataCompositionComparisonType.InList);
		
	EndIf;
	
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.GoodsReceiptForStorage.AddCreateBasedOnOrderCommand_(GenerationCommands);
	If Command <> Undefined Then
		Command.Presentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
	EndIf;
	
	Command = Documents.GoodsReceiptForStorage.AddCommandToCreateReceiptOfRepairedFINISHEDProduct(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation", Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	EndIf;
	
	Command = Documents.GoodsShipmentFromStorage.AddCommandShipmentOfGoodsFromStorageTransferToGiverCreateBasedOnOrder(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "KeepManufacturedProductsForSubcontracting", False);
		
		ListOfBusinessTransactions = New Array;
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.TollManufacturing2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.Subcontracting2_5);
		ListOfBusinessTransactions.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation", ListOfBusinessTransactions, DataCompositionComparisonType.InList);
		
	EndIf;
	
	Documents.GoodsShipmentFromStorage.AddCommandShipmentOfGoodsFromStorageRefundGiverCreateBasedOnOrder(GenerationCommands);
	
	Command = Documents.GoodsShipmentFromStorage.AddCommandShipmentOfGoodsFromStorageReturnOfRepairedFINISHEDProductBasedOnOrder(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(Command, "BusinessOperation", Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	EndIf;
	
	Documents.ReportToMaterialProvider2_5.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.GenerationOfTransferToProductionOrdersByReference.AddGenerateCommand(
		GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(
		GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateMerchantOrderBasedOnInvoiceCommand(
		GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.BackflushProduction.AddGenerateCommand(GenerationCommands);
	
	Documents.MovementOfProductsAndMaterials.AddCreateProductTransferToWarehouseCommandBasedOn(GenerationCommands);
	
	ProductionServer.AddCreateContentTransferCommandBasedOn(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	MaterialProviderOrder2_5Localization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "customer Order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//  ValueTableRow
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.MaterialProviderOrder2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.MaterialProviderOrder2_5.FullName();
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(Metadata.Documents.MaterialProviderOrder2_5);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMaterialProviderOrder2_5";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds the command to create the document "customer Order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//  ValueTableRow
//
Function AddCreateBasedOnOrderToProcessorCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.MaterialProviderOrder2_5) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.MaterialProviderOrder2_5.FullName();
		CreateBasedOnCommand.Presentation       = TMCommonUse.ObjectPresentation(Metadata.Documents.MaterialProviderOrder2_5);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions =
			"UseMultipleCompaniesAndSubcontracting25";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of report commands.
// 
// Parameters:
// 	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddGiverSOrderFulfillmentStateCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.ControlOfRawAndConsumableMaterialsDeliveryFromMaterialProvider2_5.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = Reports.ControlOfProductsTransferToMaterialProvider2_5.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 2;
	EndIf;
	
	If AccessRight("View", Metadata.Reports.OvertimeCostDrillDown) Then
		
		ReportCommand = ReportsCommands.Add();
		ReportCommand.Manager           = Metadata.Reports.OvertimeCostDrillDown.FullName();
		ReportCommand.Presentation      = NStr("vi = 'Diễn giải chi phí gia công';
												|ru = 'Расшифровка стоимости переработки';
												|en = 'Overtime cost drill-down'; fa = 'تفکیک هزینه اضافه‌کاری';
												|it = 'Trascrizione del costo di lavorazione';
												|pl = 'Szczegóły kosztów przetwarzania';
												|tr = 'İşleme maliyetlerinin dökümü'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance           = "Ordinary";
		ReportCommand.VariantKey       = "DecryptionOfCost";
		
	EndIf;
	
	MaterialProviderOrder2_5Localization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion

#Region Status

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
	|	DocumentsTable.Status = &Status      AS StatusMatches,
	|	DocumentsTable.Posted              AS Posted,
	|	DocumentsTable.DeletionMark       AS DeletionMark,
	|	TRUE                                  AS Recording
	|
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentsTable
	|
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query.SetParameter("Status",           Enums.StatusesOfMaterialProviderOrders[NewStatus]);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Generates a verification request when the status of the list of documents is automatically changed
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenCalculatingStatusAutomatically(DocumentsArray, AdditionalParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	DocumentsTable.Posted              AS Posted,
	|	DocumentsTable.DeletionMark       AS DeletionMark,
	|	TRUE                                  AS Recording
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.StatusesOfMaterialProviderOrders - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // No checks are required
	
EndFunction

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//	BusinessOperation - EnumRef.BusinessTransactions, Undefined -
//
// Returns:
//	Array of EnumRef.StatusesOfMaterialProviderOrders - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName, BusinessOperation = Undefined) Export
	
	ArrayOfValidStatuses = New Array;
	
	If DocumentName = "GoodsReceiptForStorage" Then
		
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
		
	ElsIf DocumentName = "GoodsShipmentFromStorage" Then
		
		If BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
		EndIf;
		
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
		
	ElsIf DocumentName = "ReportToMaterialProvider2_5" Then
		
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
		
	ElsIf DocumentName = "ProvideOrder" Then
		
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
		ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
		
	EndIf;
	
	Return ArrayOfValidStatuses;
	
EndFunction

#EndRegion

#Region CalculationOfStates

// Calculates the current status of the giver's order
//
// Parameters:
//	MaterialProviderOrder            - DocumentRef.MaterialProviderOrder2_5 - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//  CheckTasksToReflectStateOfOrders - Boolean - indicates whether the task has been checked
//	                                                      in the taskreference register for the status of orders.
//
Procedure CalculateStatus(
			Val MaterialProviderOrder,
			Val Contract,
			StateOfCalculations,
			CheckTasksToReflectStateOfOrders = False) Export
	
	FillPropertyValues(StateOfCalculations, ARAPAccountingClientServer.StructureOfStateOfCalculations(True));
	
	If Not ValueIsFilled(MaterialProviderOrder) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	TT.Ref AS Ref,
	|	TT.Posted AS Posted,
	|	TT.Status AS Status,
	|	TT.DocumentAmount AS DocumentAmount,
	|	TT.ARAPObjectSettings AS ARAPObjectSettings,
	|	TT.ARAPObject AS ARAPObject
	|INTO TT_DocumentOrderDocument
	|FROM
	|	Document.MaterialProviderOrder2_5 AS TT
	|WHERE
	|	TT.Ref = &MaterialProviderOrder
	|;
	|/////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NOT DocumentOrderDocument.Posted 
	|			THEN VALUE(Enum.SalesOrderStates.EmptyRef)
	|		ELSE
	|			ISNULL(SalesOrderStates.State, VALUE(Enum.SalesOrderStates.Closed)) 
	|	END AS State,
	|	CASE
	|		WHEN (NOT DocumentOrderDocument.Posted)
	|			THEN FALSE
	|		WHEN DocumentOrderDocument.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)
	|			THEN FALSE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &CurrentDate > SalesOrderStates.EventDate 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StateOverdue,
	|	ISNULL(SalesOrderStates.PayAmount,0) AS PayAmount,
	|	ISNULL(SalesOrderStates.PayPercentage,0) AS PayPercentage,
	|	ISNULL(SalesOrderStates.AmountByShipment,0) AS AmountByShipment,
	|	ISNULL(SalesOrderStates.OrderShipmentPercentage,0) AS OrderShipmentPercentage,
	|	ISNULL(SalesOrderStates.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
	|	ISNULL(SalesOrderStates.DebtPercentage,0) AS DebtPercentage
	|	,&FieldHasTasksToReflectStateOfOrders
	|FROM
	|	TT_DocumentOrderDocument AS DocumentOrderDocument
	|LEFT JOIN
	|	InformationRegister.SalesOrderStates AS SalesOrderStates
	|ON
	|	SalesOrderStates.OrderDocument = DocumentOrderDocument.Ref
	|WHERE
	|	&CheckTasksToReflectStateOfOrders
	|";

	QueryTextHasJobs = "SELECT FALSE AS ThereAreTasksToReflectStateOfOrders";
	If CheckTasksToReflectStateOfOrders Then
		
		QueryText = StrReplace(QueryText,
									",&FieldHasTasksToReflectStateOfOrders",
									",	FALSE AS ThereAreTasksToReflectStateOfOrders");
		
		QueryTextHasJobs = DocumentsStates.QueryTextThereAreTasksToReflectStateOfOrders("&MaterialProviderOrder");
		
		QueryText = StrReplace(QueryText,
									"&CheckTasksToReflectStateOfOrders",
									StrTemplate("NOT TRUE IN 
											  |		(%1)", QueryTextHasJobs));
		
	Else
		
		QueryText = StrReplace(QueryText, ",&FieldHasTasksToReflectStateOfOrders", "");
		QueryText = StrReplace(QueryText, "&CheckTasksToReflectStateOfOrders", "TRUE");
		
	EndIf;
	
	QueryTextCalculations = "SELECT 0 AS AmountOfDebt, 0 AS AmountToPay";
	If AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		
		QueryTextCalculations = "
		|SELECT // DEBT (+ WE OWE, - WE OWE)
		|	CASE
		|		WHEN
		|			DocumentOrderDocument.Posted AND
		|			((DocumentOrderDocument.Status <> VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved) AND DocumentOrderDocument.DocumentAmount > 0)
		|			OR NOT (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		THEN
		|			CAST (ISNULL(CustomersARAPAccountingBalance.SumBalance, 0) AS NUMBER(31,2))
		|		ELSE
		|			0
		|	END AS AmountOfDebt,
		|	CASE
		|		WHEN
		|			DocumentOrderDocument.Posted
		|			AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|		THEN
		|			ISNULL(CustomersARAPAccountingBalance.AmountDueBalance,0)
		|		ELSE
		|			0
		|	END AS AmountToPay
		|FROM
		|	TT_DocumentOrderDocument AS DocumentOrderDocument
		|LEFT JOIN
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,
		|			ARAPObject IN (SELECT TT.ARAPObject FROM TT_DocumentOrderDocument AS TT)
		|	) AS CustomersARAPAccountingBalance
		|ON
		|	DocumentOrderDocument.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
		|";
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryText);
	QueryTexts.Add(QueryTextCalculations);
	QueryTexts.Add(QueryTextHasJobs);
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("MaterialProviderOrder",  MaterialProviderOrder);
	Query.SetParameter("CurrentDate",    BegOfDay(CurrentSessionDate()));
	
	QueryResults = Query.ExecuteBatch();
	StatesResult = QueryResults[1];
	If Not StatesResult.IsEmpty() Then
		
		StatesSelection = StatesResult.Select();
		If StatesSelection.Next() Then
			FillPropertyValues(StateOfCalculations, StatesSelection);
		EndIf;
	
		SampleCalculations = QueryResults[2].Select();
		If SampleCalculations.Next() Then
			FillPropertyValues(StateOfCalculations, SampleCalculations);
		EndIf;
		
	ElsIf CheckTasksToReflectStateOfOrders Then
	
		SelectionThereAreTasks = QueryResults[3].Select();	
		If SelectionThereAreTasks.Next() Then
			FillPropertyValues(StateOfCalculations, SelectionThereAreTasks);
		EndIf;
		
	EndIf;
	
EndProcedure

// The function returns the text of the query to calculate the order status.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingOrderStates() Export
	
	QueryText ="
		|SELECT 
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentSalesOrder.Posted
		|	THEN
		|		VALUE(Enum.SalesOrderStates.EmptyRef)
		|// APPROVAL IS EXPECTED //////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingApproval)
		|// AN ADVANCE PAYMENT IS EXPECTED BEFORE SECURING //////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentSalesOrder.Status IN(
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.Approved),
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce))
		|		AND DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingAdvanceBeforeSupply)
		|// READY TO PROVIDE ///////////////////////////////////////////////////
		|	WHEN
		|		TTOrderAssurance.ThereIsToProvision
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Approved)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.ReadyForSupply)
		|// PREPAYMENT IS EXPECTED BEFORE SHIPMENT ////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|		AND DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingPrepaymentBeforeShipment)
		|// PROVISION IS EXPECTED ////////////////////////////////////////////////////
		|	WHEN
		|		NOT TTPartiallyInStock.Ref IS NULL
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingSupply)
		|// READY FOR SHIPMENT //////////////////////////////////////////////////////////
		|	WHEN
		|		NOT TTOrderAssurance.ShipEverything
		|			OR TTDiscrepanciesOrderInvoice.WarrantRequired
		|	THEN
		|		VALUE(Enum.SalesOrderStates.ReadyToShip)
		|// IN THE PROCESS OF SHIPMENT //////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) - ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR NOT DocumentSalesOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND (ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) <> 0 
		|			OR ISNULL(SalesOrdersBalance.OrderedClosingBalance, 0) <> 0
		|			OR ISNULL(GoodsForIssueBalance.ToShipBalance, 0) <> 0)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.DuringShipment)
		|// PAYMENT IS EXPECTED AFTER SHIPMENT /////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|		AND DocumentSalesOrder.DocumentAmount - DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue - DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0 
		|		AND ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) = 0
		|		AND ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingPaymentAfterShipment)
		|// READY TO CLOSE ////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status <> VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)
		|		AND &ControlClosingOfGiverSOrder2_5
		|	THEN
		|		VALUE(Enum.SalesOrderStates.ReadyForClosure)
		|// unopened //////////////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status IN
		|				(VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
		|				VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
		|				VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|	THEN
		|		VALUE(Enum.SalesOrderStates.Closed)
		|END AS State,
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentSalesOrder.Posted
		|	THEN
		|		DATETIME(1,1,1)
		|// DATE OF APPROVAL ///////////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
		|	THEN
		|		DocumentSalesOrder.ApprovalDate
		|// ADVANCE PAYMENT DATE /////////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Approved)
		|		AND DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// PREPAYMENT DATE /////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|		AND DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// DATE OF SHIPMENT ///////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|		AND DocumentSalesOrder.DocumentAmount > 0
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) - ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR NOT DocumentSalesOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND (ISNULL(SalesOrdersBalance.SumClosingBalance, 0) > 0 OR ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) > 0)
		|	THEN
		|		ISNULL(ShippingDatesOfCustomerOrders.MinimumShipmentDate, DocumentSalesOrder.DateOfShipment)
		|// PAYMENT DATE AFTER SHIPMENT //////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|		AND DocumentSalesOrder.DocumentAmount - DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue - DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0
		|		AND ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) = 0
		|		AND ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0
		|	THEN
		|		SettlementDates.UpdateDate
		|	ELSE
		|		DATETIME(1,1,1)
		|END AS EventDate,
		|// PAYMENT AMOUNT /////////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.PayAmount, 0) AS PayAmount,
		|// PERCENTAGE OF PAYMENT ///////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.PayPercentage, 0) AS PayPercentage,
		|// SHIPMENT AMOUNT ///////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.AmountByShipment, 0) AS AmountByShipment,
		|// PERCENTAGE OF SHIPMENT /////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.OrderShipmentPercentage, 0) AS OrderShipmentPercentage,
		|// DEBT (+ WE ARE OWED, - WE MUST)//////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.AmountOfDebt, 0) AS AmountOfDebt,
		|// percentage of debt ////////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.DebtPercentage, 0) AS DebtPercentage,
		|// DISCREPANCIES OF THE ORDER INVOICE//////////////////////////////////////////
		|CASE
		|	WHEN
		|		DocumentSalesOrder.Posted
		|		AND DocumentSalesOrder.Status <> VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
		|		AND DocumentSalesOrder.DocumentAmount > 0
		|	THEN
		|		ISNULL(TTDiscrepanciesOrderInvoice.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE)
		|	ELSE
		|		FALSE
		|	END AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
		|//LINK TO THE ORDER///////////////////////////////////////////////////////
		|	DocumentSalesOrder.Ref AS OrderDocument
		|FROM
		|	Document.MaterialProviderOrder2_5 AS DocumentSalesOrder
		|	
		|	LEFT JOIN TTStateOfSETTLEMENTS AS MutualSettlementsStatus
		|	ON DocumentSalesOrder.Ref = MutualSettlementsStatus.OrderDocument
		|
		|	LEFT JOIN TTCustomerOrdersBalance AS SalesOrdersBalance
		|	ON DocumentSalesOrder.Ref = SalesOrdersBalance.SalesOrder
		|	
		|	LEFT JOIN TTGoodsForShipmentBalance AS GoodsForIssueBalance
		|	ON DocumentSalesOrder.Ref = GoodsForIssueBalance.SalesOrder
		|	
		|	LEFT JOIN CustomerOrderValidityDates AS SettlementDates
		|	ON DocumentSalesOrder.ARAPObject = SettlementDates.ARAPObject
		|	
		|	LEFT JOIN ShippingDatesOfCustomerOrders AS ShippingDatesOfCustomerOrders
		|	ON DocumentSalesOrder.Ref = ShippingDatesOfCustomerOrders.SalesOrder
		|	
		|	LEFT JOIN TTOrderAssurance AS TTOrderAssurance
		|	ON TTOrderAssurance.Ref = DocumentSalesOrder.Ref
		|	
		|	LEFT JOIN TTPartiallyInStock AS TTPartiallyInStock
		|	ON TTPartiallyInStock.Ref = DocumentSalesOrder.Ref
		|
		|	LEFT JOIN TTDiscrepanciesOrderInvoice AS TTDiscrepanciesOrderInvoice
		|	ON DocumentSalesOrder.Ref = TTDiscrepanciesOrderInvoice.SalesOrder
		|
		|WHERE
		|	DocumentSalesOrder.Ref IN (&AnArrayOfOrders)
		|";
	Return QueryText;
	
EndFunction

#EndRegion

#Region Rounding

// Returns the parameters for rounding
// 
// Returns:
// 	Structure - LongDesc:
// 	* ManufacturedProduct - See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 	* UsedMaterials - See ProductsServer.ParametersForRoundingNumberOfUnitProducts
//
Function TSParametersForRounding() Export
	
	TSParameters = New Structure;
	
	TSName = "ManufacturedProduct";
	WarehouseFieldName = "Warehouse";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
		
	TSName = "UsedMaterials";
	WarehouseFieldName = "Warehouse";
	TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
		
	Return TSParameters;

EndFunction

#EndRegion

#Region Other

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef.MaterialProviderOrder2_5 - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date",                  Date(1,1,1));
	AttributesStructure1.Insert("Organization",           Catalogs.Companies.EmptyRef());
	AttributesStructure1.Insert("Partner",               Catalogs.Partners.EmptyRef());
	AttributesStructure1.Insert("Counterparty",            Catalogs.Counterparties.EmptyRef());
	AttributesStructure1.Insert("Contract",               Catalogs.CounterpartyContracts.EmptyRef());
	AttributesStructure1.Insert("ARAPObjectSettings",       Enums.ARAPObjectSettings.EmptyRef());
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.Subcontracting2_5);
	AttributesStructure1.Insert("Currency",                Catalogs.Currencies.EmptyRef());
	AttributesStructure1.Insert("ARAPCurrency",  Catalogs.Currencies.EmptyRef());
	AttributesStructure1.Insert("DocumentAmount",        0);
	AttributesStructure1.Insert("AmountARAP",   0);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Date            AS Date,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.Partner         AS Partner,
	|	DocumentData.Counterparty      AS Counterparty,
	|	DocumentData.Contract         AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
	|			THEN VALUE(Enum.BusinessTransactions.Subcontracting2_5)
	|		ELSE DocumentData.BusinessOperation
	|	END                           AS BusinessOperation,
	|	DocumentData.Currency          AS Currency,
	|	DocumentData.Currency          AS ARAPCurrency,
	|	DocumentData.DocumentAmount  AS DocumentAmount,
	|	DocumentData.DocumentAmount  AS AmountARAP
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef";
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(AttributesStructure1, Selection);
	EndIf;
	
	Return AttributesStructure1;
	
EndFunction

// Fills in the "time table of Materials" with data about materials according to specifications.
//
// Parameters:
//	SpecificationParameters - Structure - parameters for creating a list of materials required for production
//	TemporaryTableOfMaterials - ValueTable - the table where the calculated data will be placed.
//
Procedure MaterialsAccordingToSpecifications(SpecificationParameters, TemporaryTableOfMaterials) Export
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(
		SpecificationParameters.ListOfData,,
		Enums.ProductionSupplyFillingVariants.AsSetInTransferToProduction);
	
	SelectionParameters.GetAutoSelectionInformation          = False;
	SelectionParameters.GetPresentations               = False;
	SelectionParameters.CombineMaterialsAndIncomingProducts = True;
	SelectionParameters.MethodOfCalculationOfMaterials             = Enums.MaterialCalculationMethods.MaximumConsumption;
	
	For Each CurProducts In SpecificationParameters.ItemList Do
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		FillPropertyValues(ItemData_3, CurProducts);
		
		Result = Catalogs.BillsOfMaterials.SpecificationDataBySemiFinishedProducts(
			ItemData_3, True, SelectionParameters);
		
		For Each RowTS In Result.MaterialsAndServices Do
			
			NewRow = TemporaryTableOfMaterials.Add();
			FillPropertyValues(NewRow, RowTS);
			NewRow.BillOfMaterials       = ItemData_3.BillOfMaterials;
			NewRow.Package           = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			NewRow.NumberOfPackages = NewRow.Count;
			
		EndDo;
		
	EndDo;
	
	If TemporaryTableOfMaterials.Count() > 0 Then
		TemporaryTableOfMaterials.GroupBy(
			"Products, Characteristic, Package, ItemsType, BillOfMaterials", "NumberOfPackages, Count");
	EndIf;
	
EndProcedure

// Returns a structure with data for getting a list of materials according to the specification.
//
// Parameters:
//	OrderDetails - DocumentObject.MaterialProviderOrder2_5, Structure - contains the details of the document header
//	RowData - ValueTableRow - a string with data to fill in the structure.
//
// Returns:
//	Structure - structure with the resulting data.
//
Function ItemData_3(OrderDetails, RowData) Export
	
	ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
	
	ItemData_3.ProductionStart      = OrderDetails.Date;
	ItemData_3.LineOfBusiness = OrderDetails.LineOfBusiness;
	ItemData_3.Products            = RowData.Products;
	ItemData_3.Characteristic          = RowData.Characteristic;
	ItemData_3.Count              = RowData.Count;
	ItemData_3.BillOfMaterials            = RowData.BillOfMaterials;
	
	Return ItemData_3;
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//	Structure - The structure of the document execution status.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable",        1);
	StructureState.Insert("DisplayReceiptTables",              2);
	StructureState.Insert("DisplayTablesCanceledReceipt",      3);
	StructureState.Insert("OutputTablesSupply",              4);
	StructureState.Insert("DisplayShipmentTables",                 5);
	StructureState.Insert("DisplayTablesCanceledShipment",         6);
	StructureState.Insert("DisplayTableOfServicesToGiverForRegistration", 7);
	
	StructureState.Insert("ThisIsOrder",                          True);
	StructureState.Insert("ThereAreSummaryShipmentIndicators",    False);
	StructureState.Insert("ThereAreReasonsToCancelShipment",         GetFunctionalOption("UseReasonsForSalesOrderCancellations"));
	StructureState.Insert("NameTSGoodsShipment",               "ManufacturedProduct");
	StructureState.Insert("NameTSGoodsArrival",            "UsedMaterials");
	StructureState.Insert("NameOfAmountField",                      "Sum");
	StructureState.Insert("TextProductServiceShipment",          NStr("vi = 'Sản phẩm';
																		|ru = 'Продукция';
																		|en = 'Manufactured products'; fa = 'محصولات تولیدی';
																		|it = 'Prodotti';
																		|pl = 'Manufactured products';
																		|tr = 'İmal edilen ürünler'"));
	StructureState.Insert("TextProductServiceReceipt",       NStr("vi = 'Nguyên vật liệu';
																	|ru = 'Сырье и материалы';
																	|en = 'Raw and consumable materials'; fa = 'Raw and consumable materials';
																	|it = 'Materie prime e materiali';
																	|pl = 'Półprodukty i materiały';
																	|tr = 'Hammaddeler ve malzemeler'"));
	
	StructureOfAdditionalRequests = New Structure;
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrdersArrivalOrder", QueryTextTTGoodsOrdersArrivalOrder());
	
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	
	Return StructureState
	
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	BOMSelectionParameters.SideOutputSpecificationsAreAvailable = True;
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.ManufacturedProduct.Products";
	ChoiceParameterLinks.Characteristic          = "Object.ManufacturedProduct.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.Date";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	ChoiceParameterLinks.UnderRepairProduct   = "Object.UnderRepairProduct";
	ChoiceParameterLinks.UnderRepairVariant = "Object.UnderRepairVariant";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProduct.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("IgnoredDestinationParameters",
		CommonClientServer.ValueInArray(Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit));
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "ProductionProcessType";
	Return AttributesNames;
	
EndFunction

// Checks the completeness of the verified details.
//
// Parameters:
//  OrderDocument              - DocumentRef.MaterialProviderOrder2_5 - The document on the basis of which the input is made
//  Status             - EnumRef - Status of the document that is used for entering data
//  ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
//  DocumentName       - See ValidInputStatusesBasedOn.DocumentName
//
Procedure CheckPossibilityOfEnteringBasedOn(
			OrderDocument,
			Status,
			ThereAreErrorsPosted = False,
			DocumentName = "") Export
	
	AcceptableStatuses = ValidInputStatusesBasedOn(DocumentName);
	ThereAreErrorsStatus  = AcceptableStatuses.Find(Status) = Undefined;
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Status;
	CheckParameters.ThereAreErrorsPosted = ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = AcceptableStatuses;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(OrderDocument, CheckParameters);
	
EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "Warehouse, WarehouseForReceipt";
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - with keys:
//   *  ManufacturedProduct - See ProductsClientServer.SeriesSpecificationParameters
//   *  UsedMaterials - See ProductsClientServer.SeriesSpecificationParameters 
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = New Structure;
	
	#Region ManufacturedProduct
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.MaterialProviderOrder2_5";
	ParametersForSpecifyingTSSeries.NameTSGoods      = "ManufacturedProduct";
	ParametersForSpecifyingTSSeries.TSSeriesName       = "ManufacturedProduct";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Warehouse");
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
		
	ParametersForSpecifyingTSSeries.ThisIsOrder             = True;
	ParametersForSpecifyingTSSeries.ShipmentPlanning = True;
	
	SeriesSpecificationParameters.Insert("ManufacturedProduct", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region UsedMaterials
	
	ParametersForSpecifyingTSSeries = ProductsClientServer.SeriesSpecificationParameters();
	
	ParametersForSpecifyingTSSeries.FullObjectName = "Document.MaterialProviderOrder2_5";
	ParametersForSpecifyingTSSeries.NameTSGoods      = "UsedMaterials";
	ParametersForSpecifyingTSSeries.TSSeriesName       = "UsedMaterials";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.WarehouseForReceipt, True);
	
	ParametersForSpecifyingTSSeries.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	ParametersForSpecifyingTSSeries.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Warehouse");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Action");
	ParametersForSpecifyingTSSeries.AdditionalFieldNames.Add("Canceled");
	
	ParametersForSpecifyingTSSeries.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceiptFromVendor);
	
	SeriesSpecificationParameters.Insert("UsedMaterials", ParametersForSpecifyingTSSeries);
	
	#EndRegion
	
	#Region FinishedProductBeingRepaired
	ParametersForSpecifyingRIBatches = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingRIBatches.FullObjectName = "Document.MaterialProviderOrder2_5";
	ParametersForSpecifyingRIBatches.ProductInHeader = True;
	ParametersForSpecifyingRIBatches.UseItemsBatch = ProductionServer.UseOfSeriesInProduction22().UseItemsBatch;
	
	ParametersForSpecifyingRIBatches.WarehouseFieldName = Undefined;
	ParametersForSpecifyingRIBatches.NameTSGoods = Undefined;
	ParametersForSpecifyingRIBatches.TSSeriesName = Undefined;

	ParametersForSpecifyingRIBatches.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductRM);
	
	SeriesSpecificationParameters.Insert("FinishedProductBeingRepaired", ParametersForSpecifyingRIBatches);
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//
// Parameters:
//  SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters
//
//  Returns:
//   String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = "";
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProduct" Then
		
		QueryText = TextOfRequestToFillInStatusOfIndicationOfSeriesProducts();
		
	ElsIf SeriesSpecificationParameters.NameTSGoods = "UsedMaterials" Then
		
		QueryText = RequestTextForFillingInStatusesSpecifyingSeriesMaterials();
		
	ElsIf SeriesSpecificationParameters.ProductInHeader
		And SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ProductRM) <> Undefined Then
		
		QueryText = QueryTextForFillingInStatusesIndicatingBatchesOfFinishedProductBeingRepaired();
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for calculating the Statuses of specifying the series of the "Products" tabular part
// 
// Returns:
//  String - query text.
//
Function TextOfRequestToFillInStatusOfIndicationOfSeriesProducts() Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Series,
	|	Goods.Canceled,
	|	Goods.SupplyOption,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|				OR NOT Goods.SupplyOption IN (
	|						VALUE(Enum.SupplyOptions.FromWarehouse),
	|						VALUE(Enum.SupplyOptions.Ship))
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 11
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for calculating the Statuses of specifying the series in the "Materials" tabular section
// 
// Returns:
//  String - query text.
//
Function RequestTextForFillingInStatusesSpecifyingSeriesMaterials() Export
	
	QueryText =
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Action            AS Action,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Canceled            AS Canceled
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN Goods.Canceled
	|		  OR Goods.Action <> VALUE(Enum.ActionsOnMaterialsToSubcontract.UseAvailable)
	|		  OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END                      AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON BatchAccountingPolicies.Warehouse = Goods.Warehouse
	|		 AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber         AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the text of the request for calculating the Statuses of specifying the series in the "Materials" tabular section
// 
// Returns:
//  String - query text.
//
Function QueryTextForFillingInStatusesIndicatingBatchesOfFinishedProductBeingRepaired() Export
	
	QueryText = 
	"SELECT
	|	Goods.Series AS Series,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyWhenRepairingProducts
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 2
	|					ELSE 21
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Goods.Products = CatProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (CatProducts.ProductKind = ItemKinds.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region QualityControl

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.MaterialProviderOrder2_5 - Object.
// 
// Returns:
//  Structure - structure with fields:
// * Key - String - An identifier used when there are two or more data sources to fill in in the same object.
// * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.FullObjectName = "Document.MaterialProviderOrder2_5";
	ActionParameters.ReadableFields = "Products,Warehouse,DateOfReceipt,Action,Canceled";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	
	ActionParameters.KeyDetailsOfHeader.Insert("WarehouseForReceipt", Object.WarehouseForReceipt);
	ActionParameters.KeyDetailsOfHeader.Insert("OneDateReceipt", Object.OneDateReceipt);
	ActionParameters.QueryOptions.Insert("QualityControlDateOfReceipt", Object.DateOfReceipt);
	ActionParameters.QueryOptions.Insert("QualityControlAdmissionByOneDate", Object.OneDateReceipt);
	
	ActionParameters.QueryOptions.QualityControlContract = Object.Contract;
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	CASE
		|		WHEN &QualityControlAdmissionByOneDate
		|			THEN &QualityControlDateOfReceipt
		|		ELSE Table.DateOfReceipt
		|	END AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.Canceled
		|		OR Table.Action = VALUE(Enum.ActionsOnMaterialsToSubcontract.UseAvailable) AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.MaterialProviderOrder2_5, DocumentRef.MaterialProviderOrder2_5 - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
//
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Partner,
		|Date,
		|Number,
		|Contract,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Partner;
	Attributes.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
	
	Return Attributes;
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in VAT taxation
//
// Parameters:
//  Object		- DocumentObject.MaterialProviderOrder2_5, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInVATTaxation_(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillParameters.Organization				= Object.Organization;
	FillParameters.Date					= OrdersServer.GetMinimumDateOfShipmentOfObject(Object, "ManufacturedProduct");
	FillParameters.Warehouse					= Object.Warehouse;
	FillParameters.Contract					= Object.Contract;
	FillParameters.LineOfBusiness	= Object.LineOfBusiness;
	FillParameters.ReportToMaterialProvider			= True;
	FillParameters.ThisIsOrder				= True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region ARAPAccounting

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsOrder                         = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	ParametersStructure.PathToTSData                    = "Object.ManufacturedProduct";
	ParametersStructure.ApprovalDate                 = "Object.ApprovalDate";
	ParametersStructure.DateOfShipment                     = "Object.ManufacturedProduct.DateOfShipment"; 
	ParametersStructure.ShipInOneDay              = "Object.NotShipInInstallments";
	
	ParametersStructure.Terms                       = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.DocumentAmountForm              = "Form.AmountOrdered";
	
	// Names of form elements for the current set of parameters
	ParametersStructure.FormItems.InscriptionStages                     = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	ParametersStructure.FormItems.DebtLimitationText    = "TextAllowedCreditBalance";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	ParametersStructure.FormItems.PaymentSettlement                      = "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	ParametersStructure.IncomingDocumentNumber                        = "Object.NumberAccordingToPartnerData";
	ParametersStructure.IncomingDocumentDate                         = "Object.DateAccordingToInformationFromPartner";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	ParametersStructure.PaymentPurposes                = "Object.PaymentPurposes";
	ParametersStructure.TSP                              = "Object.Warehouse";
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
// 	Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionOptions = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath				   = "Object.ManufacturedProduct";
	ChoiceParameters.AssetRef					   = "ExpenseItem";
	ChoiceParameters.ArticleType				   = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem		   = True;
	ChoiceParameters.DimensionOfExpenses		   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.FormItems.AssetRef.Add("ManufacturedProductExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ManufacturedProductDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductAssetsLiabilitiesDimension");
	
	ArticleSelectionOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionOptions;
	
EndFunction

#EndRegion

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
	|	AND( ValueAllowed(Warehouse)
	|	OR ValueAllowed(WarehouseForReceipt)
	|	) ";

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

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.Date              AS Date,
	|	Header.Partner           AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	CASE WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|		THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE Header.DeliveryMethod
	|	END                   AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|		END               AS Address,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|		END               AS FieldValueAddress,
	|
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	Header.AdditionalDeliveryInformation
	|		                    AS AdditionalInformation,
	|	T.Warehouse                 AS Warehouse,
	|	T.DeliverFully    AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		T.Warehouse AS Warehouse,
	|		MIN(
	|			CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|				ELSE FALSE
	|			END) AS DeliverFully
	|	FROM
	|		Document.MaterialProviderOrder2_5.ManufacturedProduct AS T
	|	WHERE
	|		T.Ref IN (&References)
	|	
	|	GROUP BY
	|		T.Ref,
	|		T.Warehouse
	|	
	|	HAVING
	|		MAX(
	|			CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|				ELSE FALSE
	|			END) = TRUE
	|	) AS T
	|		INNER JOIN Document.MaterialProviderOrder2_5 AS Header
	|		ON (Header.Ref = T.Ref)";
	
	Return QueryText;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the security mechanisms.
// Parameters:
//  DocumentObject - DocumentObject.MaterialProviderOrder2_5 - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "ManufacturedProduct";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "ManufacturedProductSupplyOption";
	FormItems.Available           = "ManufacturedProductAvailable";
	FormItems.Series              = "ManufacturedProductSeries";
	FormItems.WithAssignment        = "ManufacturedProductWithAssignment";
	FormItems.Warehouse              = "ManufacturedProductWarehouse";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.ManufacturedProduct.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.ManufacturedProduct.Canceled";
	DataPaths.ItemsType = "Object.ManufacturedProduct.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.ManufacturedProduct.CurrentData.Available";
	Links.NumberOfPackages    = "Items.ManufacturedProduct.CurrentData.NumberOfPackages";
	Links.Count            = "Items.ManufacturedProduct.CurrentData.Count";
	Links.ShipIfAvailable = "Items.ManufacturedProduct.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.ManufacturedProduct.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.ManufacturedProduct.CurrentData.ItemsType";
	Links.Package              = "Items.ManufacturedProduct.CurrentData.Package";
	Links.Products          = "Items.ManufacturedProduct.CurrentData.Products";
	Links.SupplyOption    = "Items.ManufacturedProduct.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.ManufacturedProduct.CurrentData.Warehouse";
	Links.MultipleWarehouses      = "WarehouseGroup_";
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "ShipmentAndReturnReferences";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.MaterialProviderOrder2_5";
	EmbeddingParameters.TableName = "Document.MaterialProviderOrder2_5.ManufacturedProduct";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Department,
		|	TabPart.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	Attributes.Ref AS ShipmentOrder,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.Status IN(
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)
		|		) AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
		|			VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)
		|		) AS ReadyToShip,
		|	CASE
		|		WHEN Attributes.NotShipInInstallments
		|			THEN Attributes.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	CASE
		|		WHEN Attributes.NotShipInInstallments
		|			THEN Attributes.DateOfShipment
		|		ELSE UNDEFINED
		|	END AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS TabPart
		|		
		|		LEFT JOIN Document.MaterialProviderOrder2_5 AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	ManufacturedProduct = New Structure();
	ManufacturedProduct.Insert("LineNumber",        New TypeDescription("Number"));
	ManufacturedProduct.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	ManufacturedProduct.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ManufacturedProduct.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	ManufacturedProduct.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	ManufacturedProduct.Insert("WithAssignment",        New TypeDescription("Boolean"));
	ManufacturedProduct.Insert("Count",         New TypeDescription("Number"));
	ManufacturedProduct.Insert("NumberOfPackages", New TypeDescription("Number"));
	ManufacturedProduct.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	ManufacturedProduct.Insert("DateOfShipment",       New TypeDescription("Date"));
	ManufacturedProduct.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	ManufacturedProduct.Insert("Canceled",           New TypeDescription("Boolean"));
	ManufacturedProduct.Insert("RowCode",          New TypeDescription("Number"));
	ManufacturedProduct.Insert("Department",      New TypeDescription("CatalogRef.BusinessStructure"));
	
	Object = New Structure();
	Object.Insert("Purpose",         New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",             New TypeDescription("DocumentRef.MaterialProviderOrder2_5"));
	Object.Insert("Status",             New TypeDescription("EnumRef.StatusesOfMaterialProviderOrders"));
	Object.Insert("NotShipInInstallments", New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",       New TypeDescription("Date"));
	Object.Insert("Date",               New TypeDescription("Date"));
	Object.Insert("Priority",          New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("ManufacturedProduct",          ManufacturedProduct);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	Return EmbeddingParameters;
	
EndFunction

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

#EndRegion

#Region Internal

Function QueryTextDocumentGoods(Filter, Resource) Export
	
	If Resource = "ManufacturedProduct" Then
		
		QueryText = 
		"SELECT
		|	Table.Ref                       AS ReferenceOrder,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	CASE
		|		WHEN Table.WithAssignment
		|			THEN Table.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                                AS Purpose,
		|	Table.RowCode                    AS RowCode,
		|	Table.Series                        AS Series,
		|	Table.Count                   AS Count,
		|	Table.Package                     AS Package,
		|	Table.DateOfShipment                 AS DateOfShipment,
		|	Table.BatchesIndicationStatus          AS BatchesIndicationStatus,
		|	Table.Warehouse                        AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
		|	ISNULL(DataOfAccounting.ToTransfer, 0)   AS ToTransfer,
		|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Table
		|		LEFT JOIN TTAccountingData AS DataOfAccounting
		|		ON Table.Ref = DataOfAccounting.ReferenceOrder
		|		AND Table.RowCode = DataOfAccounting.RowCode
		|WHERE
		|	&Filter
		|	AND NOT DataOfAccounting.ReferenceOrder IS NULL
		|";
		
	Else
		
		QueryText = 
		"SELECT
		|	Table.Ref                       AS ReferenceOrder,
		|	Table.Products                 AS Products,
		|	Table.Characteristic               AS Characteristic,
		|	Table.Purpose                   AS Purpose,
		|	Table.RowCode                    AS RowCode,
		|	Table.Series                        AS Series,
		|	Table.BatchesIndicationStatus          AS BatchesIndicationStatus,
		|	Table.Count                   AS Count,
		|	Table.Price                         AS Price,
		|	Table.Sum                        AS Sum,
		|	Table.Package                     AS Package,
		|	Table.DateOfReceipt              AS DateOfReceipt,
		|	Table.Warehouse                        AS Warehouse,
		|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
		|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered
		|FROM
		|	Document.MaterialProviderOrder2_5.UsedMaterials AS Table
		|		LEFT JOIN TTAccountingData AS DataOfAccounting
		|		ON Table.Ref = DataOfAccounting.PurchaseOrder
		|		AND Table.RowCode = DataOfAccounting.RowCode
		|WHERE
		|	&Filter
		|	AND NOT DataOfAccounting.PurchaseOrder IS NULL
		|";
		
	EndIf;
	
	FilterText1 = TMCommonUse.SelectionTextBySelectionCollection(Filter);
	QueryText = StrReplace(QueryText, "&Filter", FilterText1);
	
	Return QueryText;

EndFunction

#Region Supply

// Parameters:
//  Ref - DocumentRef.MaterialProviderOrder2_5 - a link to an order that has built-in commands for creating an assignment adjustment
//  AdditionalParameters - Structure - structure with fields:
//  * IDInStorage - UUID - A unique identifier to put the goods of the document in the storage
//  * ThisIsWithdrawalOfReserve - Boolean - True if the data needs to be obtained for a reserve withdrawal operation, False if for a reservation operation
//  Returns:
//   Structure - Document data required to execute the create assignment adjustment command
Function DocumentDataForCreatingDestinationAdjustment(Ref, AdditionalParameters) Export
	
	Query = New Query();
	Query.SetParameter("Ref", Ref);
	Query.Text =
		"SELECT
		|	DocumentAttributes.Posted AS Posted
		|FROM
		|	Document.MaterialProviderOrder2_5 AS DocumentAttributes
		|WHERE
		|	DocumentAttributes.Ref = &Ref
		|;
		|SELECT
		|	DocumentAttributes.AssignmentMaterials AS Ref
		|FROM
		|	Document.MaterialProviderOrder2_5 AS DocumentAttributes
		|WHERE
		|	DocumentAttributes.Ref = &Ref
		|;
		|SELECT DISTINCT
		|	OrderMaterials.Products AS Products,
		|	OrderMaterials.Characteristic AS Characteristic
		|FROM
		|	Document.MaterialProviderOrder2_5.UsedMaterials AS OrderMaterials
		|WHERE
		|	OrderMaterials.Ref = &Ref
		|	AND NOT OrderMaterials.Canceled";
		
	RequestResultsPackage = Query.ExecuteBatch();
	
	Selection = RequestResultsPackage[0].Select();
	Selection.Next();
	Posted = Selection.Posted;
	
	Assignments = RequestResultsPackage[1].Unload().UnloadColumn("Ref");
	
	Goods       = RequestResultsPackage[2].Unload();
	AddressOfGoods = PutToTempStorage(Goods, AdditionalParameters.IDInStorage);
	
	ThereAreGoodsToSeparateProvision = Documents.InventoryAssignmentAdjustment.ThereAreGoodsToSeparateProvision(
		Assignments, AddressOfGoods);
	
	ThereAreGoodsToWithdrawReserve = Documents.InventoryAssignmentAdjustment.ThereAreGoodsToWithdrawReserve(
		Assignments, AddressOfGoods);
	
	DocumentData = New Structure();
	DocumentData.Insert("Posted", Posted);
	DocumentData.Insert("Assignments", Assignments);
	DocumentData.Insert("AddressOfGoods", AddressOfGoods);
	DocumentData.Insert("ThereAreGoodsToSeparateProvision", ThereAreGoodsToSeparateProvision);
	DocumentData.Insert("ThereAreGoodsToWithdrawReserve", ThereAreGoodsToWithdrawReserve);
	Return DocumentData;

EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	
	// Needs for materials in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.UsedMaterials.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.UsedMaterials.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.UsedMaterials.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.UsedMaterials.Warehouse";
	
	Return FormTemplate;
	
EndFunction

// Performs additional actions related to filling out the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.MaterialProviderOrder2_5 - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the context of the software filling.
//  FillParameters - Structure - Fill-in parameters.
//  ThereAreChangesInDateOfShipment - Boolean - it will be set to True if the shipment dates have changed
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters, ThereAreChangesInDateOfShipment = False) Export
	
	ThereAreChangesInDateOfShipment = ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.ManufacturedProduct,
		"DateOfShipment");
	
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ThereAreChangesInDateOfShipment = ThereAreChangesInDateOfShipment Or ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			Changes.UnloadColumn("String"),
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
		
	EndIf;
	
	If TypeOf(Object) <> Type("FormDataStructure") And ThereAreChangesInDateOfShipment Then
		PaymentStepsServer.AfterFillingOutCollateral(Object);
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.ManufacturedProduct);
	Attributes = "Sum, VATAmount, AmountIncludingVAT";
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, Attributes);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProduct);
	
	ThereIsShip = False;
	
	If ProvisionInDocumentsClientServer.ThisIsSoftwareChangeMode(Mode) Then
		For Each CurrentData In Changes Do
			If CurrentData.SupplyOption = Enums.SupplyOptions.Ship Then
				ThereIsShip = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If ThereIsShip
		And (Object.Status = Enums.StatusesOfMaterialProviderOrders.NotApproved
			Or Object.Status = Enums.StatusesOfMaterialProviderOrders.Approved
			Or Object.Status = Enums.StatusesOfMaterialProviderOrders.ToProduce) Then
		Object.Status = Enums.StatusesOfMaterialProviderOrders.ToShip;
	EndIf;
	
EndProcedure

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.SalesOrder - the document for which you need to get the goods
//  CreationParameters - See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
//  TempTablesManager - TempTablesManager - temporary table manager where a table with columns will be created:
//   * LineNumber - Number - Line number
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Department - CatalogRef.BusinessStructure - Department
//   * Purpose - CatalogRef.Assignments - Purpose
//   * SupplyOption - EnumRef.SupplyOptions - security option
//   * WithAssignment - Boolean - WithAssignment
//   * QuantityOfUnits - Number - number of units
//   * CountByDocument - Number - Number of packages
Procedure GoodsOfDocumentForCreatingSecuringOrder(Ref, CreationParameters, TempTablesManager) Export
	
	Attributes = Common.ObjectAttributesValues(Ref, "Status,Posted");
	CheckPossibilityOfEnteringBasedOn(Ref, Attributes.Status, Not Attributes.Posted, "ProvideOrder");
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	
	If CreationParameters.NameOfDocumentManager = "SubcontractOrder2_5" Then
		
		Query.Text =
		"SELECT ALLOWED
		|	Goods.Ref AS Ref,
		|	CASE
		|		WHEN
		|			NOT SUM(CASE
		|				WHEN NOT Goods.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|					THEN 1
		|				ELSE 0
		|			END) = 0
		|			AND NOT SUM(CASE
		|				WHEN Goods.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|					THEN 1
		|				ELSE 0
		|			END) = 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END         AS ThereIsErrorBillOfMaterials
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|	AND NOT Goods.Canceled
		|	AND Goods.Products.ItemsType IN(&ItemsTypes)
		|
		|GROUP BY
		|	Goods.Ref
		|";
		
		Selection = Query.Execute().Select();
		If Selection.Next()
			And Selection.ThereIsErrorBillOfMaterials Then
			Raise NStr("vi = 'Để nhập đơn hàng gia công, yêu cầu điền đầy đủ hoặc để trống bảng kê chi tiết sản phẩm tại tất cả các dòng.
									|Không hỗ trợ nhập trên cơ sở đơn hàng có trạng thái điền bảng kê chi tiết hỗn hợp.';
									|ru = 'Для ввода заказа переработчику необходимо чтобы спецификация продукции во всех строках была заполнена, либо не заполнена.
									|Ввод на основании заказа со смешанным заполнением спецификации не поддерживается.';
									|en = 'To generate a subcontracting purchase order, either fill bills of materials in all lines or clear bills of materials in all lines.
									|Generation based on orders with partially specified bills of materials is not supported.'; fa = 'To generate a subcontracting purchase order, either fill bills of materials in all lines or clear bills of materials in all lines.
									|Generation based on orders with partially specified bills of materials is not supported.';
									|it = 'To generate a subcontracting purchase order, either fill bills of materials in all lines or clear bills of materials in all lines.
									|Generation based on orders with partially specified bills of materials is not supported.';
									|pl = 'To generate a subcontracting purchase order, either fill bills of materials in all lines or clear bills of materials in all lines.
									|Generation based on orders with partially specified bills of materials is not supported.';
									|tr = 'Fason üretici satın alma siparişi girişi için tüm satırlarda ürün reçetesi doldurulmuş veya doldurulmamış olmalıdır.
									|Karışık ürün reçeteli sipariş temelinde giriş desteklenmemektedir.'");
		EndIf;
		
	EndIf;
	
	Query.Text =
	"SELECT ALLOWED
	|	Goods.LineNumber        AS LineNumber,
	|	Goods.Products       AS Products,
	|	Goods.Characteristic     AS Characteristic,
	|	Goods.Package           AS Package,
	|	Goods.Warehouse              AS Warehouse,
	|	Goods.Department      AS Department,
	|	CASE
	|		WHEN Goods.WithAssignment
	|			THEN Goods.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                     AS Purpose,
	|	Goods.SupplyOption AS SupplyOption,
	|	Goods.WithAssignment        AS WithAssignment,
	|	Goods.DateOfShipment       AS DateOfShipment,
	|	Goods.Count         AS NumberOfUnitsPerDocument,
	|	Goods.NumberOfPackages AS CountByDocument
	|INTO DocumentGoods
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND NOT Goods.Canceled
	|	AND Goods.Products.ItemsType IN(&ItemsTypes)
	|";
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region InputOnBasis

Function CreateProductionOrder22BasedOnGiverSOrderCheckingGrounds(ObjectsOfBases) Export
	
	Return New Structure("ObjectsOfBases, ErrorText", ObjectsOfBases);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

#Region DataPreparation

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text =
	"SELECT
	|	OrderDocument.Number                        AS Number,
	|	OrderDocument.Date                         AS Period,
	|	OrderDocument.NumberAccordingToPartnerData        AS NumberAccordingToPartnerData,
	|	OrderDocument.DateAccordingToInformationFromPartner         AS DateAccordingToInformationFromPartner,
	|	OrderDocument.Currency                       AS Currency,
	|	OrderDocument.Status                       AS Status,
	|	OrderDocument.Partner                      AS Partner,
	|	OrderDocument.Contract                      AS Contract,
	|	PRESENTATION(OrderDocument.Contract)       AS ContractPresentation,
	|	OrderDocument.Purpose                   AS Purpose,
	|	OrderDocument.Counterparty                   AS Counterparty,
	|	OrderDocument.Organization                  AS Organization,
	|	OrderDocument.Warehouse                        AS Warehouse,
	|	OrderDocument.Department                AS Department,
	|	OrderDocument.PriceIncludesVAT              AS PriceIncludesVAT,
	|	OrderDocument.BusinessOperation        AS BusinessOperation,
	|	OrderDocument.LineOfBusiness      AS LineOfBusiness,
	|	OrderDocument.GoodsReceiptOption        AS GoodsReceiptOption,
	|	OrderDocument.KeepManufacturedProductsForSubcontracting  AS KeepManufacturedProductsForSubcontracting,
	|	OrderDocument.PriceTypeMaterials             AS PriceTypeMaterials,
	|	OrderDocument.RegisterVendorPrices AS RegisterVendorPrices,
	|	OrderDocument.DocumentAmount               AS DocumentAmount,
	|	OrderDocument.Manager                     AS Manager,
	|	OrderDocument.Author                        AS Author,
	|	OrderDocument.Comment                  AS Comment,
	|
	|	CASE
	|		WHEN OrderDocument.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|			THEN OrderDocument.Purpose.RecordsInWarehouseRegisters
	|		ELSE FALSE
	|	END                              AS RecordsInWarehouseRegisters,
	|	
	|	OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) AS ContractSettlements,
	|	OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)             AS CalculationsOnInvoices,
	|	
	|	OrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|	AND ISNULL(OrderDocument.Contract.ExecutionScheduleIsSpecified, FALSE)                AS ExecutionScheduleInContract,
	|
	|	OrderDocument.Status IN (
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))       AS ProductionStatusOrHigher,
	|	OrderDocument.Status IN (
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|			VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))       AS ShippingStatusOrHigher,
	|	OrderDocument.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.Closed) AS TheClosedStatus,
	|	
	|	OrderDocument.Posted                     AS Posted,
	|	OrderDocument.DeletionMark              AS DeletionMark,
	|	OrderDocument.Priority                    AS Priority
	|FROM
	|	Document.MaterialProviderOrder2_5 AS OrderDocument
	|WHERE
	|	OrderDocument.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Attributes.GoodsReceiptOption);
	
	Query.SetParameter("BegOfDay",                      BegOfDay(Attributes.Period));
	Query.SetParameter("UseStatuses",            GetFunctionalOption("UseStatusesOfMaterialProviderOrders2_5"));
	Query.SetParameter("MetadataIdentifier",        Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("InvoiceIsOrder", InvoiceIsOrder);
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		ContractInformation = NStr("vi = 'Theo hợp đồng ""%Contract%""';
									|ru = 'По договору ""%Contract%""';
									|en = 'Under the ""%Contract%"" contract'; fa = 'Under the ""%Contract%"" contract';
									|it = 'In base al contratto ""%Contract%""';
									|pl = 'Według umowy ""%Contract%""';
									|tr = '""%Contract%"" Sözleşmesi kapsamında'", Common.DefaultLanguageCode());
		ContractInformation = StrReplace(ContractInformation, "%Contract%", Attributes.ContractPresentation);
	EndIf;
	
	Query.SetParameter("ContractInformation", ContractInformation);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.MaterialProviderOrder2_5";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",  """""");
	RedefiningParameterCalculation.Insert("NumberAccordingToPartnerData", """""");
	RedefiningParameterCalculation.Insert("ShippingStatusOrHigher",
		"CASE WHEN GoodsTable.Ref.Status IN(
		|	VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
		|	VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)) THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END");
	RedefiningParameterCalculation.Insert("ProductionStatusOrHigher",
		"CASE WHEN GoodsTable.Ref.Status IN(
		|	VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
		|	VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
		|	VALUE(Enum.StatusesOfMaterialProviderOrders.Closed)) THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END");
	RedefiningParameterCalculation.Insert("RecordsInWarehouseRegisters",
		"ISNULL(GoodsTable.Ref.Purpose.RecordsInWarehouseRegisters, FALSE)");
	RedefiningParameterCalculation.Insert("Purpose","GoodsTable.Ref.Purpose");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	
	If RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
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

#EndRegion

#Region QueriesTexts

#Region TemporaryTable

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRates.Currency          AS Currency,
	|	RelativeExchangeRates.CourseNumerator   AS CourseNumerator,
	|	RelativeExchangeRates.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			BaseCurrency IN
	|				(SELECT
	|					DefaultBaseCurrency.Value AS Value
	|				FROM
	|					Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS RelativeExchangeRates
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableOfGoods_(Query, QueryTexts)
	
	RegisterName = "TemporaryTableOfGoods_";
	
	QueryText =
	"SELECT
	|	Goods.PartnerProducts   AS PartnerProducts,
	|	Goods.Products           AS Products,
	|	Goods.Characteristic         AS Characteristic,
	|	&PriceTypeMaterials             AS VendorPriceKind,
	|	Goods.Package               AS Package,
	|	Goods.Price                   AS Price
	|INTO TemporaryTableOfGoods_
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND NOT Goods.Canceled
	|	AND &RegisterVendorPrices
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts)
	
	RegisterName = "ProductsWithDifferentPackagingPrices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	Goods.Products                   AS Products,
	|	Goods.Characteristic                 AS Characteristic,
	|	&PriceTypeMaterials                     AS VendorPriceKind,
	|	AVG(Goods.Price / CASE
	|							WHEN Goods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|								THEN &QueryTextPackagingFactor
	|							ELSE 1
	|						  END)          AS PricePerBaseUnit,
	|	COUNT(DISTINCT Goods.Package) AS NumberOfDifferentPackages
	|INTO ProductsWithDifferentPackagingPrices
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|GROUP BY
	|	Products,
	|	Characteristic
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|";
	
	QueryText = StrReplace(QueryText,
						"&QueryTextPackagingFactor",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
							"Goods.Package", "Goods.Products"));
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""ManufacturedProduct""                                          AS DataSource,
	|	FALSE                                                   AS DistributeTotalAmount,
	|	DocumentTable.Ref                                AS Ref,
	|	DocumentTable.Ref.Date                           AS Date,
	|	DocumentTable.Ref.Organization                    AS Organization,
	|	DocumentTable.Ref.Currency                         AS DocumentCurrency,
	|	UNDEFINED                                           AS ARAPCurrency,
	|	DATETIME(1,1,1)                                       AS VATBasePeriod,
	|	DocumentTable.Ref.Date                           AS DateOfCourse,
	|
	|	DocumentTable.LineNumber                           AS LineNumber,
	|	DocumentTable.RowID                   AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate                             AS VATRate,
	|	DocumentTable.VATAmount                              AS VATAmount,
	|	0                                                      AS AmountARAP,
	|	0                                                      AS AmountVATARAP,
	|	0                                                      AS AmountExcludingVATCompl,
	|	0                                                      AS AmountExcludingVATMan,
	|	
	|	TRUE                                                 AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject                 AS ARAPObject,
	|	FALSE                                                   AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Canceled";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	GoodsTable.Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus IN (14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.Canceled
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Canceled)
	|		ELSE VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|	END AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum,
	|	CASE
	|		WHEN GoodsTable.Canceled
	|			THEN GoodsTable.CancellationReason
	|		ELSE UNDEFINED
	|	END AS CancellationReason
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	GoodsTable.Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus IN (14)
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister) AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND &ShippingStatusOrHigher
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.DateOfShipment AS Period,
	|	GoodsTable.Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip) AS Factor,
	|	GoodsTable.Count AS Count,
	|	0 AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND &ShippingStatusOrHigher
	|	AND NOT &KeepManufacturedProductsForSubcontracting
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	GoodsTable.Count               AS Ordered,
	|	0                                      AS ToRegister,
	|	UNDEFINED                           AS CancellationReason
	|
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Action = VALUE(Enum.ActionsOnMaterialsToSubcontract.AcceptVMI)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	-GoodsTable.Count              AS Ordered,
	|	0                                      AS ToRegister,
	|	UNDEFINED                           AS CancellationReason
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|	AND GoodsTable.Action = VALUE(Enum.ActionsOnMaterialsToSubcontract.AcceptVMI)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	0                                      AS Ordered,
	|	GoodsTable.Count               AS ToRegister,
	|	UNDEFINED                           AS CancellationReason
	|
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.Canceled
	|	AND &ProductionStatusOrHigher
	|	AND GoodsTable.Action = VALUE(Enum.ActionsOnMaterialsToSubcontract.AcceptVMI)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref				AS Ref,
	|	CASE WHEN SourceData.DateOfShipment <> DATETIME(1, 1, 1) THEN
	|				SourceData.DateOfShipment
	|			ELSE
	|				SourceData.Ref.Date
	|		END                           AS Period,
	|	SourceData.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	SourceData.Ref.Partner		AS Recipient,
	|	SourceData.Warehouse				AS Warehouse,
	|	SourceData.Products		AS Products,
	|	SourceData.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN SourceData.WithAssignment
	|			THEN SourceData.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series				AS Series,
	|	SourceData.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	SourceData.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	SourceData.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS SourceData
	|
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND SourceData.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|	AND NOT SourceData.Canceled";
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                                                 AS Ref,
	|	UNDEFINED                                                          AS Invoice,
	|	DataSource.Ref                                                 AS OrderDocument,
	|	FALSE                                                                  AS Patch,
	|	UNDEFINED                                                          AS CorrectedDocument,
	|	DataSource.Ref.Contract                                         AS Contract,
	|	UNDEFINED                                                          AS Terms,
	|	DataSource.Ref.GoodsReceiptOption                           AS GoodsReceiptOption,
	|	DataSource.DateOfReceipt                                        AS Date,
	|	DataSource.Products                                           AS Products,
	|	DataSource.Characteristic                                         AS Characteristic,
	|	DataSource.Purpose                                             AS Purpose,
	|	DataSource.ToControlQuality                              AS ToControlQuality,
	|	FALSE                                                                  AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                                          AS ControlledLotReference,
	|	DataSource.BatchesIndicationStatus                                    AS BatchesIndicationStatus,
	|	DataSource.Series                                                  AS Series,
	|	FALSE                                                                  AS ExceedingOrder,
	|	DataSource.Warehouse                                                  AS Warehouse,
	|	DataSource.Ref.Partner                                         AS Sender,
	|	VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5) AS BusinessOperation,
	|	DataSource.Count                                             AS Count,
	|	FALSE                                                                  AS ThisIsAnInvoice,
	|	FALSE                                                                  AS ReceiptUnderOrders
	|
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS DataSource
	|
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND NOT DataSource.Canceled
	|	AND NOT DataSource.Action = VALUE(Enum.ActionsOnMaterialsToSubcontract.UseAvailable)
	|	AND DataSource.Ref.Status IN (
	|								VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|								VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|								VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref              AS Ref,
	|	SourceData.DateOfShipment        AS Period,
	|	SourceData.Ref              AS OrderDocument,
	|	UNDEFINED                        AS Invoice,
	|	FALSE                                AS Patch,
	|	UNDEFINED                        AS CorrectedDocument,
	|	SourceData.Ref.Partner      AS Recipient,
	|	SourceData.Warehouse               AS Warehouse,
	|	SourceData.Products        AS Products,
	|	SourceData.Characteristic      AS Characteristic,
	|	CASE
	|		WHEN SourceData.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE SourceData.Ref.Purpose
	|	END                               AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series               AS Series,
	|	SourceData.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SourceData.Count          AS Count,
	|	FALSE                                AS ExceedingOrder,
	|	SourceData.Canceled            AS Canceled,
	|	FALSE                                AS ThisIsAnInvoice,
	|	TRUE                              AS ShipmentByOrder
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS SourceData
	|
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND NOT SourceData.Canceled
	|	AND SourceData.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness = 
		"SELECT
		|	DocumentDataHeader.ARAPObject AS ARAPObject
		|FROM
		|	Document.MaterialProviderOrder2_5 AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
	QueryTextLinesOfBusiness = ARAPAccountingPosting.GetTableOfLinesOfBusiness(QueryTextLinesOfBusiness);

	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	TextPaymentPlans =
	"SELECT
	|	Table.Ref                                                           AS Ref,
	|	Table.Ref.Organization                                               AS Organization,
	|	Table.Ref.Partner                                                   AS Partner,
	|
	|	Table.Ref.ARAPObject                                            AS ARAPObject,
	|	Table.Ref.Date                                                      AS RecorderDate,
	|	Table.Ref.Number                                                     AS RecorderNumber,
	|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
	|	Table.Ref.Currency                                                    AS ARAPCurrency,
	|	Table.Ref.Currency                                                    AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
	|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
	|	
	|	Table.PaymentDate                                                      AS PaymentDate,
	|	Table.DateOfShipment                                                     AS DateOfShipment,
	|	Table.PaymentOption                                                    AS PaymentOption,
	|	Table.PaymentAmount                                                     AS AmountDue,
	|	0                                                                        AS MeasuringGoodsVarianceAmount,
	|	
	//	We check the advance payment before production
	|	CASE
	|		WHEN NOT &UseStatuses
	|			THEN TRUE
	|		WHEN Table.Ref.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
	|			AND Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
	|			THEN FALSE
	//	We check the prepayment before shipment
	|		WHEN &UseStatuses
	|			AND Table.Ref.Status IN (
	|								VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|								VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
	|			AND Table.PaymentOption IN (
	|						VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment),
	|						VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision))
	|				THEN FALSE
	//	We believe that everything is fine
	|		ELSE TRUE
	|	END                                                                    AS ExcludeDuringControl
	|
	|FROM
	|	Document.MaterialProviderOrder2_5.PaymentScheduleSteps AS Table
	|
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND Table.Ref.Status IN (
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.Approved),
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|						VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
	|";
	
	TextShipmentPlans =
	"SELECT
	|	Table.Ref                                                           AS Ref,
	|	Table.Ref.Organization                                               AS Organization,
	|	Table.Ref.Partner                                                   AS Partner,
	|	
	|	Table.Ref.ARAPObject                                            AS ARAPObject,
	|	ENDOFPERIOD(Table.DateOfShipment, DAY)                                 AS DateOfShipment,
	|
	|	Table.AmountIncludingVAT                                                        AS IncreaseToBeSHIPPED,
	|	Table.AmountIncludingVAT                                                        AS IncreaseShipping,
	|	Table.Ref.Date                                                      AS RecorderDate,
	|	Table.Ref.Number                                                     AS RecorderNumber,
	|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
	|	Table.Ref.Currency                                                    AS ARAPCurrency,
	|	Table.Ref.Currency                                                    AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
	|	Table.Ref.PaymentMethod                                               AS PaymentMethod
	|	
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Table
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND NOT Table.Canceled
	|	AND NOT &KeepManufacturedProductsForSubcontracting
	|	AND Table.Ref.Status IN (
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.Approved),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
	|";
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND TabPart.Ref.Status IN(
		|		VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
		|		VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|	AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	CASE
		|		WHEN TabPart.Ref.NotShipInInstallments
		|			THEN TabPart.Ref.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND NOT TabPart.Ref.Status IN (VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved),
		|		VALUE(Enum.StatusesOfMaterialProviderOrders.Approved))
		|	AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND TabPart.WithAssignment
		|			THEN VALUE(Enum.SupplyOptions.ToSupply)
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND NOT TabPart.WithAssignment
		|			THEN VALUE(Enum.SupplyOptions.NotRequired)
		|		ELSE VALUE(Enum.SupplyOptions.FromWarehouse)
		|	END AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	CASE
		|		WHEN TabPart.Ref.NotShipInInstallments
		|			THEN TabPart.Ref.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND TabPart.Ref.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce)
		|	AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.DateOfReceipt AS DateOfReceipt,
		|	TRUE AS AvailableForConsumption,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.MaterialProviderOrder2_5.UsedMaterials AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN (VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
		|		VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip), VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
		|	AND NOT TabPart.Canceled
		|	AND TabPart.Action <> VALUE(Enum.ActionsOnMaterialsToSubcontract.UseAvailable)";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("ProductsWithDifferentPackagingPrices", QueryTexts) Then
		QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	MAX(Goods.PartnerProducts)    AS PartnerProducts,
	|	Goods.Products                      AS Products,
	|	Goods.Characteristic                    AS Characteristic,
	|	Goods.VendorPriceKind                 AS VendorPriceKind,
	|	Goods.VendorPriceKind.Currency          AS Currency,
	|	&Period                                  AS Period,
	|	&Partner                                 AS Partner,
	|	MIN(CASE
	|				WHEN ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|					THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				ELSE Goods.Package
	|			END)                           AS Package,
	|	CAST(AVG(CASE
	|						WHEN ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|							THEN ProductsWithDifferentPackagingPrices.PricePerBaseUnit
	|						ELSE Goods.Price
	|					END
	|					* CASE
	|						WHEN &Currency <> Goods.VendorPriceKind.Currency
	|							THEN CASE
	|									WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|										AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|										AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|										AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|											THEN Currency_Rates.CourseNumerator
	|													* CurrencyRatesPrices.CourseDenominator
	|													/ (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|									ELSE 0
	|								END
	|						ELSE 1
	|					END) AS NUMBER(31, 2)) AS Price
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|		
	|		LEFT JOIN ProductsWithDifferentPackagingPrices AS ProductsWithDifferentPackagingPrices
	|		ON Goods.Products   = ProductsWithDifferentPackagingPrices.Products
	|		 AND Goods.Characteristic = ProductsWithDifferentPackagingPrices.Characteristic
	|
	|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|		ON Currency_Rates.Currency = &Currency
	|
	|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|		ON CurrencyRatesPrices.Currency = Goods.VendorPriceKind.Currency
	|WHERE
	|	NOT Goods.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|	AND Goods.Price > 0
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.VendorPriceKind,
	|	Goods.VendorPriceKind.Currency";
	
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
	|	&Warehouse                   AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	&Status                  AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&DateAccordingToInformationFromPartner    AS SourceDocumentDate,
	|	&NumberAccordingToPartnerData   AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	FALSE                     AS ReverseTransactionCorrection,
	|	UNDEFINED             AS ReversedDocument,
	|	UNDEFINED             AS CorrectedDocument,
	|	&Priority               AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Sales order
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
	PrintCommand.Id  = "OrderingGiverForServices";
	PrintCommand.Presentation  = NStr("vi = 'Đơn hàng của người đặt gia công đối với dịch vụ xuất xưởng sản phẩm';
										|ru = 'Заказ давальца на услуги по выпуску продукции';
										|en = 'Subcontracting sales order for product release services'; fa = 'Subcontracting sales order for product release services';
										|it = 'Ordine del committente per servizi di emissione prodotti';
										|pl = 'Zamówienie właścicielowi surowców na usługi dotyczące wypuszczenia produkcji';
										|tr = 'Ürün üretim hizmetleri için sağlayıcı siparişi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Order to supplier
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
	PrintCommand.Id  = "OrderToGiverOnRawMaterials";
	PrintCommand.Presentation  = NStr("vi = 'Đơn hàng của người đặt gia công đối với nguyên vật liệu';
										|ru = 'Заказ давальцу на сырье и материалы';
										|en = 'Material provider order for raw and consumable materials'; fa = 'Material provider order for raw and consumable materials';
										|it = 'Ordine al committente di materie prime e i materiali';
										|pl = 'Zamówienie właścicielowi surowców na materiały';
										|tr = 'Sağlayıcıya hammadde ve malzeme siparişi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	If GetFunctionalOption("DoNotUseCommercialInvoicesAndSelectDiscountDisplayOption")
	 Or GetFunctionalOption("DoNotUseCommercialInvoicesAndDoNotSelectDiscountDisplayOption") Then
		
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id  = "ProformaInvoice";
		PrintCommand.Presentation  = NStr("vi = 'Hóa đơn thanh toán';
											|ru = 'Счет на оплату';
											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
											|it = 'Fattura di pagamento';
											|pl = 'Rachunek do zapłaty';
											|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// An invoice for payment with facsimile
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id  = "ProformaInvoice";
		PrintCommand.Presentation  = NStr("vi = 'Hóa đơn thanh toán có dấu chữ ký';
											|ru = 'Счет на оплату с факсимиле';
											|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
											|it = 'Fattura di pagamento in facsimile';
											|pl = 'Rachunek do płatności z faksymile';
											|tr = 'Kaşeli ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		
	EndIf;
	
	MaterialProviderOrder2_5Localization.AddPrintCommands(PrintCommands);

EndProcedure

// Create printed forms of objects
//
// Parameters:
//  ObjectsArray  - Array    - references to the objects that you want to print.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated tabular documents (output parameter).
//  PrintObjects         - ValueList  - value - reference to the object
//                                            view - name of the area in which the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	MaterialProviderOrder2_5Localization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure


Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function GetDataForPrintedOrderFormForRawMaterials(ObjectsArray, PrintParameters, LanguageCode = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Documents.Ref                               AS Ref,
	|	Documents.Number                                AS Number,
	|	Documents.Date                                 AS Date,
	|	Documents.Organization                          AS Organization,
	|	Documents.Organization                          AS Customer_,
	|
	|	FALSE                                           AS ConsiderVAT,
	|	FALSE                                           AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|
	|	Documents.Organization.Prefix                  AS Prefix,
	|	Documents.Counterparty                           AS Counterparty,
	|	Documents.Counterparty                           AS Performer,
	|	Documents.BankAccount                       AS BankAccount,
	|	Documents.BankAccount.CorrespondentText   AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT                      AS PriceIncludesVAT,
	|	Documents.Currency                               AS Currency,
	|	Documents.Manager.Individual.Description AS Manager,
	|	Documents.AdditionalInformation             AS AdditionalInformation,
	|
	|	Documents.DeliveryAddress                        AS DeliveryAddress,
	|	Documents.Shipper                     AS Shipper,
	|	Documents.GoodsRecipient                      AS GoodsRecipient,
	// Parameters for selecting report layout areas
	|	FALSE                                           AS ShowNDSInRows,
	|	FALSE                                           AS UseAutoDiscounts,
	|	""OrderToGiverOnRawMaterials""                       AS Type,
	|	&PresentationInError                          AS PresentationInError
	|
	|FROM
	|	Document.MaterialProviderOrder2_5 AS Documents
	|
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	UNDEFINED AS PaymentOption,
	|	UNDEFINED AS PaymentPercentage,
	|	UNDEFINED AS PaymentAmount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                            AS Ref,
	|	Goods.LineNumber                       AS LineNumber,
	|	UNDEFINED                             AS TypeOfContractorSPrice,
	|	Goods.Products                      AS Products,
	|	Goods.Products.Code                  AS Code,
	|	Goods.Products.SKU              AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfReceipt                   AS DateOfReceipt,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""                                     AS Content,
	|
	|	Goods.NumberOfPackages                AS Count,
	|
	|	Goods.Price                              AS Price,
	|	0                                        AS DiscountAmount,
	|	Goods.Sum                             AS AmountWithoutADiscount,
	|	Goods.Sum                             AS Sum,
	|	UNDEFINED                             AS VATRate,
	|	0                                        AS VATAmount,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END                                    AS Package,
	|	FALSE                                     AS ThisIsReusablePackage
	|
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS Goods
	|	
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON Goods.Products = ProductsPresentations.Ref
	|	AND ProductsPresentations.LanguageCode = &LanguageCode
	|	
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|	AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode
	|
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|	AND NOT Goods.Canceled
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.SetParameter("ObjectsArray",			ObjectsArray);
	Query.SetParameter("PresentationInError",	NStr("vi = 'đơn hàng bên đặt gia công';
														|ru = 'заказа давальцу';
														|en = 'material provider order'; fa = 'material provider order';
														|it = 'ordine al committente';
														|pl = 'zamówienia właściciela surowców';
														|tr = 'sağlayıcıya siparişler'"));
	Query.SetParameter("LanguageCode",				LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",			RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages",	RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart",	RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function GetDataForPrintedServiceOrderForm(ObjectsArray, PrintParameters, LanguageCode = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Documents.Ref                               AS Ref,
	|	Documents.Number                                AS Number,
	|	Documents.Date                                 AS Date,
	|	""""                                           AS DeliveryAddress,
	|	Documents.Organization                          AS Organization,
	|	Documents.Organization                          AS Performer,
	|	NOT Documents.VATTaxation IN (
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))   AS ConsiderVAT,
	|	Documents.VATTaxation =
	|		VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	FALSE                                           AS UseAutoDiscounts,
	|	&DisplayAdditionalVATColumns                         AS ShowNDSInRows,
	|	""OrderingGiverForServices""                      AS Type,
	|	&PresentationInError                          AS PresentationInError,
	|	Documents.Organization.Prefix                  AS Prefix,
	|	Documents.Counterparty                           AS Counterparty,
	|	Documents.Counterparty                           AS Customer_,
	|	Documents.BankAccount                       AS BankAccount,
	|	Documents.BankAccount.CorrespondentText   AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT                      AS PriceIncludesVAT,
	|	Documents.Currency                               AS Currency,
	|	Documents.Manager.Individual.Description AS Manager,
	|	Documents.AdditionalInformation             AS AdditionalInformation,
	|	UNDEFINED                                   AS Shipper,
	|	UNDEFINED                                   AS GoodsRecipient
	|FROM
	|	Document.MaterialProviderOrder2_5 AS Documents
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentScheduleSteps.Ref         AS Ref,
	|	PaymentScheduleSteps.LineNumber    AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate    AS PaymentDate,
	|	PaymentScheduleSteps.PaymentOption  AS PaymentOption,
	|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
	|	PaymentScheduleSteps.PaymentAmount   AS PaymentAmount
	|FROM
	|	Document.MaterialProviderOrder2_5.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                            AS Ref,
	|	Goods.LineNumber                       AS LineNumber,
	|	Goods.Products                      AS Products,
	|	Goods.Products.Code                  AS Code,
	|	Goods.Products.SKU              AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfShipment                      AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""                                     AS Content,
	|
	|	UNDEFINED                             AS TypeOfContractorSPrice,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	Goods.NumberOfPackages                AS Count,
	|
	|	Goods.Price                              AS Price,
	|	Goods.Sum                             AS Sum,
	|	Goods.VATAmount                          AS VATAmount,
	|	0                                        AS DiscountAmount,
	|	Goods.Sum                             AS AmountWithoutADiscount,
	|
	|	Goods.VATRate                         AS VATRate,
	|
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END                                    AS Package,
	|
	|	FALSE                                     AS ThisIsReusablePackage
	|
	|FROM
	|	Document.MaterialProviderOrder2_5 AS OrderDocument
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS Goods
	|	ON OrderDocument.Ref = Goods.Ref
	|	AND NOT Goods.Canceled
	|	
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON Goods.Products = ProductsPresentations.Ref
	|	AND ProductsPresentations.LanguageCode = &LanguageCode
	|	
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|	AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode
	|
	|WHERE
	|	OrderDocument.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	LineNumber
	|";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.SetParameter("ObjectsArray",			ObjectsArray);
	Query.SetParameter("PresentationInError",	NStr("vi = 'đơn hàng bên đặt gia công';
														|ru = 'заказа давальца';
														|en = 'subcontracting sales order'; fa = 'subcontracting sales order';
														|it = 'ordine del committente';
														|pl = 'zamówienia właściciela surowca';
														|tr = 'Sağlayıcı siparişleri'"));
	Query.SetParameter("DisplayAdditionalVATColumns",	Constants.DisplayAdditionalVATColumns.Get());
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",		   RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages",   RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(
		ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref                                                           AS Ref,
	|	Documents.Number                                                            AS Number,
	|	Documents.Date                                                             AS Date,
	|	UNDEFINED                                                               AS DocumentBasis,
	|	ISNULL(Documents.BankAccount.Owner, Documents.Organization)         AS Organization,
	|	Documents.Organization                                                      AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription                          AS Director,
	|	TableResponsiblePersons.DirectorJobTitle                             AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription                      AS ChiefAccountant,
	|	NOT Documents.VATTaxation IN (
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))   AS ConsiderVAT,
	|	Documents.VATTaxation =
	|		VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty                                                       AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual                                             AS CounterpartyLegEntInd,
	|	Documents.BankAccount                                                   AS BankAccount,
	|	
	|	CASE
	|		WHEN Documents.BankAccount.ForeignBank
	|		  OR Documents.BankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		  OR Documents.BankAccount.ForeignBank
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                      AS PaymentAbroad,
	|	Documents.BankAccount.CashCurrency                             AS CashCurrency,
	|	
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankNameInt
	|		ELSE Documents.BankAccount.Bank.InternationalDescription
	|	END                                                                      AS BankNameInt,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankNameForPaymentsInt
	|		ELSE Documents.BankAccount.TransferBank.InternationalDescription
	|	END                                                                      AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankSWIFTCode
	|		ELSE Documents.BankAccount.Bank.SWIFTBIC
	|	END                                                                      AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankSWIFTCodeForPayments
	|		ELSE Documents.BankAccount.TransferBank.SWIFTBIC
	|	END                                                                      AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankAddressInt
	|		ELSE Documents.BankAccount.Bank.InternationalAddress
	|	END                                                                      AS BankAddress,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankAddressForPaymentInt
	|		ELSE Documents.BankAccount.TransferBank.InternationalAddress
	|	END                                                                      AS TransferBankAddress,
	|	
	|	Documents.BankAccount.BankAccountForPayments                             AS BankAccountForPayments,
	|	ISNULL(Documents.BankAccount.DigitalRoubleAccount, FALSE)                AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.BankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.BankAccount.DigitalRoubleAccountID
	|		ELSE Documents.BankAccount.AccountNumber
	|	END                                                                      AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END                                                                      AS BICBank,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END                                                                      AS BankDescription,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END                                                                      AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END                                                                      AS BankCity,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END                                                                      AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END                                                                      AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END                                                                      AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END                                                                      AS TransferBankCity,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END                                                                      AS BankCityInt,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END                                                                      AS CountryOfBank,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END                                                                      AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END                                                                      AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END                                                                      AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END                                                                      AS NameOfBankSRCCForSettlements,
	|	Documents.BankAccount.CorrespondentText                               AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT                                                  AS PriceIncludesVAT,
	|	Documents.Currency                                                           AS Currency,
	|	Documents.Manager.Individual                                          AS Manager,
	|	Documents.AdditionalInformation                                         AS AdditionalInformation,
	|	Documents.DocumentAmount                                                   AS AmountToReturn,
	|	FALSE                                                                       AS PartialPayment,
	|	Documents.PaymentPurposes                                                AS PaymentPurposes,
	|	100                                                                        AS PayPercentage,
	|	Documents.DocumentAmount                                                   AS DocumentAmount,
	|	Documents.Shipper                                                 AS Shipper,
	|	Documents.GoodsRecipient                                                  AS GoodsRecipient,
	|	Documents.PaymentID                                             AS PaymentID,
	|	FALSE                                                                       AS InvoiceToBeRefunded
	|FROM
	|	Document.MaterialProviderOrder2_5 AS Documents
	|
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.BankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.BankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentScheduleSteps.Ref         AS Ref,
	|	PaymentScheduleSteps.LineNumber    AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate    AS PaymentDate,
	|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
	|	PaymentScheduleSteps.PaymentAmount	  AS PaymentAmount,
	|	FALSE                              AS ThisIsDepositForPackage
	|FROM
	|	Document.MaterialProviderOrder2_5.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.PaymentAmount <> 0
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductTable.LineNumber                       AS LineNumber,
	|	ProductTable.Ref                            AS Ref,
	|	ProductTable.Products                      AS Products,
	|	ProductTable.Products.Code                  AS Code,
	|	ProductTable.Products.SKU              AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, ProductTable.Products.DescriptionFull) AS DescriptionFull,
	|	ProductTable.VATRate                         AS VATRate,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(ProductTable.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""                                               AS Content,
	|	ProductTable.Price                              AS Price,
	|	ProductTable.Sum                             AS Sum,
	|	ProductTable.VATAmount                          AS VATAmount,
	|	ProductTable.Sum                             AS AmountWithoutADiscount,
	|	0                                                  AS DiscountAmount,
	|	ProductTable.NumberOfPackages                AS Count,
	|	ProductTable.Package                          AS Package,
	|	&QueryTextUnitOfMeasureDescription          AS UnitOfMeasure,
	|	FALSE                                               AS ThisIsReusablePackage
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS ProductTable
	|	
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON ProductTable.Products = ProductsPresentations.Ref
	|	AND ProductsPresentations.LanguageCode = &LanguageCode
	|	
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON ProductTable.Characteristic = ItemsCharacteristicsPresentations.Ref
	|	AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode
	|WHERE
	|	ProductTable.Ref IN(&ObjectsArray)
	|	AND NOT ProductTable.Canceled
	|
	|ORDER BY
	|	LineNumber
	|";
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&QueryTextUnitOfMeasureDescription",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description", "ProductTable.Package", "ProductTable.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode",       LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",			RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages",	RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart",	RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
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
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
EndProcedure

#EndRegion

#Region ARAPAccounting

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.MaterialProviderOrder2_5 - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	&Ref             AS Ref,
	|	Goods.AmountIncludingVAT    AS Sum,
	|	Goods.Products AS Products,
	|	Goods.DateOfShipment AS DateOfShipment,
	|	Goods.Canceled     AS Canceled
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE
	|	&LinkCondition_
	|;
	|SELECT 
	|	Goods.Ref       AS OrderDocument,
	|	&Date               AS Date,
	|	&ApprovalDate   AS ApprovalDate,
	|	Goods.DateOfShipment AS DateOfShipment,
	|	SUM(Goods.Sum) AS PaymentAmount,
	|	0                   AS AmountARAP,
	|	0                   AS PackageDepositValue,
	|	0                   AS AmountARAPByPackage
	|FROM TTProducts_1 AS Goods
	|WHERE
	|	NOT Goods.Canceled
	|GROUP BY
	|	Goods.Ref,
	|	Goods.DateOfShipment
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.MaterialProviderOrder2_5.ManufacturedProduct");
		Query.Text = StrReplace(Query.Text, "&Date", "Goods.Ref.Date");
		Query.Text = StrReplace(Query.Text, "&ApprovalDate", "Goods.Ref.ApprovalDate");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.SetParameter("Ref", ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text,      "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region Other

// Returns the default material assignment. Used to fill in the rows of the tabular part "Materials"
// of the giver's order.
// Parameters:
//  MaterialProviderOrder - DocumentRef.MaterialProviderOrder2_5 - an order that is an order for the receipt of material,
//                                                    the purpose of which must be received.
//  Returns:
//   CatalogRef.Assignments, Undefined - the purpose of the tolling material.
//
Function AssignmentMaterials(MaterialProviderOrder) Export
	
	Result = Undefined;
	SetPrivilegedMode(True);
	Result = Common.ObjectAttributeValue(MaterialProviderOrder, "AssignmentMaterials");
	
	Return Result;
	
EndFunction

// Returns a template for generating a product assignment in a document.
// 
// Parameters:
//  Object - DocumentObject.MaterialProviderOrder2_5, FormDataStructure - OrderDocument
//
// Returns:
//  See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DestinationPattern.Partner       = Object.Partner;
	DestinationPattern.Contract       = Object.Contract;
	DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
	
	OptionOfAssignment = Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Get();
	If OptionOfAssignment = Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder Then
		DestinationPattern.OrderDocument     = Object.Ref;
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

// Returns a template for generating the assignment of materials in the document.
// 
// Parameters:
//  Object - DocumentObject.MaterialProviderOrder2_5, FormDataStructure - OrderDocument
//
// Returns:
//  See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationTemplateMaterials(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	DestinationPattern.Partner       = Object.Partner;
	DestinationPattern.Contract       = Object.Contract;
	DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
	
	OptionOfAssignment = Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Get();
	If OptionOfAssignment = Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder Then
		DestinationPattern.OrderDocument     = Object.Ref;
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

Function QueryTextTTGoodsOrdersArrivalOrder()
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products              AS Products,
	|	DocumentGoods.Characteristic            AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DocumentGoods.Products.UnitOfMeasure
	|		ELSE DocumentGoods.Package
	|	END                                    AS Package,
	|	SUM(DocumentGoods.Count)         AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DocumentGoods.Sum)              AS AmountIncludingVAT,
	|	DocumentGoods.Warehouse                     AS Warehouse,
	|	TTDocuments.DocumentRef               AS Ref
	|INTO TTGoodsNewArrival
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|WHERE
	|	TTDocuments.Posted
	|	AND NOT DocumentGoods.Canceled
	|	AND DocumentGoods.Ref.Status IN (
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.ToProduce),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.ToShip),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.Closed))
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Package,
	|	DocumentGoods.Warehouse,
	|	TTDocuments.DocumentRef,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DocumentGoods.Products.UnitOfMeasure
	|		ELSE DocumentGoods.Package
	|	END
	|
	|;";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ProductionByOrderOfGiver

Procedure CreateTTWaysToReceiveMaterialsForOrder(TempTablesManager, OrderDocument) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableMaterials.BillOfMaterials        AS ReferenceOrder,
	|	MaterialProviderOrder2_5.AssignmentMaterials AS Purpose,
	|	TableMaterials.Products        AS Products,
	|	TableMaterials.Characteristic      AS Characteristic,
	|	MAX(TableMaterials.Warehouse)     AS Warehouse,
	|	TRUE                               AS WithAssignment
	|INTO TTMethodsOfObtainingMaterials
	|FROM
	|	Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|		LEFT JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS TableMaterials
	|		ON MaterialProviderOrder2_5.Ref = TableMaterials.Ref
	|		 AND NOT TableMaterials.Canceled
	|WHERE
	|	MaterialProviderOrder2_5.Ref = &OrderDocument
	|	AND MaterialProviderOrder2_5.Posted
	|	
	|GROUP BY
	|	TableMaterials.BillOfMaterials,
	|	MaterialProviderOrder2_5.AssignmentMaterials,
	|	TableMaterials.Products,
	|	TableMaterials.Characteristic
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Purpose,
	|	Products,
	|	Characteristic,
	|	Warehouse
	|";
		
	Query.SetParameter("OrderDocument", OrderDocument);
		
	SetPrivilegedMode(True);
	Query.Execute();
	
EndProcedure

#EndRegion

// Returns a table of acceptable deviations of measured items from the list of orders.
//
//	Parameters:
//		ListOfOrders_ - ValueList, DocumentRef.InventoryConsumptionOrder - the list of orders to determine the allowable deviations
//		InventoryMovementType - EnumRef.InventoryMovementTypes -
//	Returns:
//		ValueTable - table of permissible deviations:
//		* OrderDocument                - DocumentRef.MaterialProviderOrder2_5 -
//		* Products         - CatalogRef.Products -
//		* Characteristic       - CatalogRef.ItemsCharacteristics -
//		* Series                - CatalogRef.ItemsBatches -
//		* AllowableVariance - Number -
//
Function PermissibleDeviationsOfMeasuredGoods(ListOfOrders_, InventoryMovementType) Export
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If Not ValueIsFilled(ListOfOrders_) Or AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		
		Table = New ValueTable;
		Table.Columns.Add("OrderDocument");
		Table.Columns.Add("Products");
		Table.Columns.Add("Characteristic");
		Table.Columns.Add("Warehouse");
		
		If InventoryMovementType = Enums.InventoryMovementTypes.Shipment Then
			Table.Columns.Add("Series");
		EndIf;
		
		Table.Columns.Add("AllowableVariance");
		
		Return Table;
		
	EndIf;
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		ReferenceArray = New Array;
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ReferenceArray", ReferenceArray);
	
	If InventoryMovementType = Enums.InventoryMovementTypes.Inpayment Then
		
		Query.Text =
			"SELECT
			|	GoodsToReceive.PurchaseOrder                               AS OrderDocument,
			|	GoodsToReceive.Products                                  AS Products,
			|	GoodsToReceive.Characteristic                                AS Characteristic,
			|	GoodsToReceive.Warehouse                                         AS Warehouse,
			|	SUM(GoodsToReceive.ToRegisterReceipt
			|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
			|FROM
			|	AccumulationRegister.PurchaseOrders.Turnovers(
			|		&StartPeriod_,
			|		&ConPeriod,
			|		,
			|		PurchaseOrder IN (&ReferenceArray)
			|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)) AS GoodsToReceive
			|GROUP BY
			|	GoodsToReceive.Products,
			|	GoodsToReceive.Characteristic,
			|	GoodsToReceive.PurchaseOrder,
			|	GoodsToReceive.Warehouse";
		
		SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns(
												"PurchaseOrders",
												"PurchaseOrder IN (&ReferenceArray)",
												Query.Parameters);
		
	Else
		
		Query.Text =
			"SELECT
			|	GoodsForIssue.ReferenceOrder AS OrderDocument,
			|	GoodsForIssue.Products AS Products,
			|	GoodsForIssue.Characteristic AS Characteristic,
			|	GoodsForIssue.Series AS Series,
			|	GoodsForIssue.Warehouse AS Warehouse,
			|	SUM(GoodsForIssue.ForRegistrationQuantityTurnover * (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS
			|		AllowableVariance
			|FROM
			|	#ShipmentOrdersTurnoverExpanded AS GoodsForIssue
			|GROUP BY
			|	GoodsForIssue.ReferenceOrder,
			|	GoodsForIssue.Products,
			|	GoodsForIssue.Characteristic,
			|	GoodsForIssue.Series,
			|	GoodsForIssue.Warehouse";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.BeginOfPeriod = "&StartPeriod_";
		TableFormationParameters.EndOfPeriod = "&ConPeriod";
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&ReferenceArray)
			|		AND Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
		TableFormationParameters.Indicators = "ToRegister";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns(
			"ShipmentAndReturnReferences",
			"ReferenceOrder IN (&ReferenceArray)",
			Query.Parameters);
		
	EndIf;
	
	Query.SetParameter(
		"DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
		
	Query.SetParameter(
		"AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

#Region CreatingHyperlinkInJournalDocumentsProcessing

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.SalesOrderStates)
		And AccessRight("Update", Metadata.Documents.MaterialProviderOrder2_5)
		And GetFunctionalOption("UseTollManufacturing2_5")) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	OrderStates.OrderDocument AS OrderDocument
	|FROM
	|	InformationRegister.SalesOrderStates AS OrderStates
	|WHERE
	|	VALUETYPE(OrderStates.OrderDocument) = TYPE(Document.MaterialProviderOrder2_5)
	|	AND OrderStates.State <> VALUE(Enum.SalesOrderStates.Closed)";
	
	TextColor = ?(Query.Execute().IsEmpty(), StyleColors.EmptyTableField, Undefined);
	
	Return New FormattedString(NStr("vi = 'Đơn hàng bên đặt gia công';
									|ru = 'Заказы давальцев';
									|en = 'Subcontracting sales orders'; fa = 'سفارش‌های فروش پیمانکاری فرعی';
									|it = 'Ordini dei prestatori';
									|pl = 'Zamówienia właścicieli surowców';
									|tr = 'Sağlayıcı siparişleri'"),, TextColor,, FormNameWorkplace());
	
EndFunction

Function FormNameWorkplace() Export
	
	Return "Document.MaterialProviderOrder2_5.Form.ListForm";
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.MaterialProviderOrder2_5.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.14";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("94a86318-d13f-4488-9e91-9b77b0a5ef64");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.MaterialProviderOrder2_5.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Đơn hàng của người đặt gia công"":';
								|ru = 'Обновление документов ""Заказ давальца"":';
								|en = 'Update the ""Subcontracting sales order"" documents:'; fa = 'Update the ""Subcontracting sales order"" documents:';
								|it = 'Обновление документов ""Заказ давальца"":';
								|pl = 'Update the ""Subcontracting sales order"" documents:';
								|tr = '""Satıcıdan sipariş"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("ru = '- переносит значение ставки НДС из шапки в табличную часть ""Выпускаемая продукция"".';
								|vi = '- Transfers the VAT rate value from the header to the ""Released products"" table.';
								|en = '- Transfers the VAT rate value from the header to the ""Released products"" table.'; fa = '- Transfers the VAT rate value from the header to the ""Released products"" table.';
								|it = '- Transfers the VAT rate value from the header to the ""Released products"" table.';
								|pl = '- Transfers the VAT rate value from the header to the ""Released products"" table.';
								|tr = '- KDV oranı değerini üst bilgilerinden ""Üretilen Ürünler"" tablo bölümüne aktarır.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.MaterialProviderOrder2_5";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.MaterialProviderOrder2_5 AS DocumentAttributes
	|WHERE
	|	NOT DocumentAttributes.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|	AND TRUE IN(
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Document.MaterialProviderOrder2_5.ManufacturedProduct AS TableOfGoods
	|		WHERE
	|			TableOfGoods.Ref = DocumentAttributes.Ref
	|			AND TableOfGoods.VATRate = VALUE(Catalog.VATRates.EmptyRef))
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.MaterialProviderOrder2_5";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref        AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN Document.MaterialProviderOrder2_5 AS DocumentAttributes
	|	ON UpdatedData.Ref = DocumentAttributes.Ref
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			If DocumentObject <> Undefined Then
				
				For Each CurrentData In DocumentObject.ManufacturedProduct Do
					
					If ValueIsFilled(CurrentData.VATRate) Then
						Continue;
					EndIf;
					
					CurrentData.VATRate = DocumentObject.VATRate;
					
				EndDo;
				
			EndIf;
			
			ExceptionReason = "Record";
			
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "Record" Then
				Raise NStr("vi = 'Không thể xử lý cập nhật chứng từ ""Đơn hàng của người đặt gia công"".';
							|ru = 'Не удалось обработать обновление документов ""Заказ давальца"".';
							|en = 'Cannot process the update of the ""Subcontracting sales order"" documents.'; fa = 'Cannot process the update of the ""Subcontracting sales order"" documents.';
							|it = 'Cannot process the update of the ""Subcontracting sales order"" documents.';
							|pl = 'Cannot process the update of the ""Subcontracting sales order"" documents.';
							|tr = '""Sağlayıcı siparişi"" belgelerinin güncellenmesi gerçekleştirilemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
