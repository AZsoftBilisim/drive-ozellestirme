#If Not MobileStandaloneServer Then
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
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReturnOfGoodsFromCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReturnOfGoodsFromCustomer") Then
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
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableBonusPoints(Query, QueryTexts, Registers, DocumentRef);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentRef);
		
		ReturnOfGoodsFromCustomerLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	
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
	
	If GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance")
		And AccessRight("Update", Metadata.Documents.ReturnOfGoodsFromCustomer) Then
		
		CreationCommand = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
		If CreationCommand <> Undefined Then
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi nhận trả lại từ khách';
												|ru = 'Акт о расхождениях после возврата от клиента';
												|en = 'Discrepancy report following return from customer'; fa = 'Discrepancy report following return from customer';
												|it = 'Atto sulle discrepanze dopo il reso dal cliente';
												|pl = 'Protokół o odchyleniu po zwrocie od klienta';
												|tr = 'Müşteriden iade sonrası tutarsızlık raporu'");
		EndIf;
		
	EndIf;
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsShipmentToCustomer.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerInvoice.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ReturnOfGoodsFromCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "Return of goods from a customer".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//	 ValueTableRow, Undefined - the command to output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ReturnOfGoodsFromCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReturnOfGoodsFromCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReturnOfGoodsFromCustomer);
		CreateBasedOnCommand.WriteMode = "Post";

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
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingProvided.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	// DocumentsListForm
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingProvided.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Important";
		ReportCommand.Order = 3;
	EndIf;
	
	ReturnOfGoodsFromCustomerLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Date,BusinessOperation";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.ReturnOfGoodsFromCustomer";
	
	ReturnOfGoodsViaCommissionAgent = ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(Object.BusinessOperation);
	
	If ReturnOfGoodsViaCommissionAgent Then
		SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																New Structure());
		SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																New Structure());
	Else
		WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
		SeriesSpecificationParameters.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
		SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	EndIf;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer);
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;

	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText =
		"SELECT
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived,
		|	Goods.Purpose,
		|	Goods.Series,
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
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived,
		|	Goods.Purpose,
		|	SUM(Goods.Count) AS Count,
		|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
		|INTO ProductsToRequest
		|FROM
		|	Goods AS Goods
		|
		|GROUP BY
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived,
		|	Goods.Purpose,
		|	CAST(Goods.Products AS Catalog.Products).ProductKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Warehouse,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.ProductsRecordingAsReceived,
		|	SetOfSeries.CharacteristicRecordingAsReceived,
		|	SetOfSeries.Purpose,
		|	SetOfSeries.Count
		|INTO SetOfSeries
		|FROM
		|	&SetOfSeries AS SetOfSeries
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.Warehouse,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.ProductsRecordingAsReceived,
		|	SetOfSeries.CharacteristicRecordingAsReceived,
		|	SetOfSeries.Purpose,
		|	SUM(SetOfSeries.Count) AS Count
		|INTO SeriesToRequest
		|FROM
		|	SetOfSeries AS SetOfSeries
		|
		|GROUP BY
		|	SetOfSeries.Warehouse,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.ProductsRecordingAsReceived,
		|	SetOfSeries.CharacteristicRecordingAsReceived,
		|	SetOfSeries.Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
		|	CASE
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
		|			THEN 0
		|		ELSE CASE
		|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
		|					THEN CASE
		|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|								THEN 14
		|							ELSE 13
		|						END
		|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
		|					THEN CASE
		|							WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|									OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|								THEN CASE
		|										WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|												AND ProductsToRequest.Count > 0
		|											THEN 10
		|										ELSE 9
		|									END
		|							ELSE 0
		|						END
		|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
		|					THEN CASE
		|							WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|									OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|								THEN CASE
		|										WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|												AND ProductsToRequest.Count > 0
		|											THEN 8
		|										ELSE 7
		|									END
		|							ELSE 0
		|						END
		|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
		|						AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|							OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
		|						AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByReturnFromCustomer
		|					THEN CASE
		|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
		|								THEN CASE
		|										WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|												AND ProductsToRequest.Count > 0
		|											THEN 4
		|										ELSE 3
		|									END
		|							ELSE CASE
		|									WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|											AND ProductsToRequest.Count > 0
		|										THEN 2
		|									ELSE 1
		|								END
		|						END
		|				ELSE 0
		|			END
		|	END AS BatchesIndicationStatus,
		|	CASE
		|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
		|			THEN 0
		|		ELSE
		|			CASE
		|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
		|					THEN
		|						CASE
		|							WHEN &DocumentOperation_ = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
		|									AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
		|								THEN
		|									CASE
		|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|											THEN 18
		|										ELSE 17
		|									END
		|								ELSE 0
		|						END
		|					ELSE 0
		|			END
		|	END AS BatchesIndicationStatusOfGoodsTransferred
		|INTO Statuses
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN ProductsToRequest AS ProductsToRequest
		|		ON Goods.Products = ProductsToRequest.Products
		|			AND Goods.Characteristic = ProductsToRequest.Characteristic
		|			AND Goods.ProductsRecordingAsReceived = ProductsToRequest.ProductsRecordingAsReceived
		|			AND Goods.CharacteristicRecordingAsReceived = ProductsToRequest.CharacteristicRecordingAsReceived
		|			AND Goods.Purpose = ProductsToRequest.Purpose
		|			AND Goods.Warehouse = ProductsToRequest.Warehouse
		|		LEFT JOIN SeriesToRequest AS SeriesToRequest
		|		ON ProductsToRequest.Products = SeriesToRequest.Products
		|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
		|			AND ProductsToRequest.ProductsRecordingAsReceived = SeriesToRequest.ProductsRecordingAsReceived
		|			AND ProductsToRequest.CharacteristicRecordingAsReceived = SeriesToRequest.CharacteristicRecordingAsReceived
		|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
		|			AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
		|			AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Statuses.LineNumber                          AS LineNumber,
		|	CASE
		|		WHEN Statuses.BatchesIndicationStatus = 0
		|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
		|		ELSE Statuses.BatchesIndicationStatus
		|	END                                        AS BatchesIndicationStatus
		|FROM
		|	Statuses AS Statuses
		|WHERE
		|	CASE
		|		WHEN Statuses.BatchesIndicationStatus = 0
		|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
		|		ELSE Statuses.BatchesIndicationStatus
		|	END <> Statuses.OldStatusOfSpecifyingSeries
		|
		|ORDER BY
		|	LineNumber";
		
	Return QueryText;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ReturnOfGoodsFromCustomerLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReturnOfGoodsFromCustomerLocalization.RequestTextTTReflectedInLocalAccounting();

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

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.ReturnOfGoodsFromCustomer, DocumentRef.ReturnOfGoodsFromCustomer - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Contract,
		|Partner,
		|Ref,
		|Date,
		|DateOfReceipt,
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Partner;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.ReturnOfGoodsFromCustomer - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,ProductsRecordingAsReceived,Damage,Warehouse";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.KeyDetailsOfHeader.Insert("Warehouse", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	CASE
		|		WHEN Table.Damage
		|			THEN Table.ProductsRecordingAsReceived
		|		ELSE Table.Products
		|	END AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("ReusablePackageReturn");
	ArrayOfAllProps.Add("DepositForPackageIsRequired");
	ArrayOfAllProps.Add("CompensationMethod");
	ArrayOfAllProps.Add("Warehouse");
	ArrayOfAllProps.Add("CustomerCounterparty");
	ArrayOfAllProps.Add("CustomerPartner");
	ArrayOfAllProps.Add("CustomerContract");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Then
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("ReusablePackageReturn");
		ArrayOfOperationDetails.Add("DepositForPackageIsRequired");
		ArrayOfOperationDetails.Add("CompensationMethod");
		ArrayOfOperationDetails.Add("Warehouse");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("ReusablePackageReturn");
		ArrayOfOperationDetails.Add("Warehouse");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent Then
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("ReusablePackageReturn");
		ArrayOfOperationDetails.Add("DepositForPackageIsRequired");
		ArrayOfOperationDetails.Add("CustomerCounterparty");
		ArrayOfOperationDetails.Add("CustomerPartner");
		ArrayOfOperationDetails.Add("CustomerContract");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		ArrayOfOperationDetails.Add("CompensationMethod");
		ArrayOfOperationDetails.Add("Warehouse");
		
	EndIf;
	
EndProcedure

// Generates the query result for the unloaded part of the request
//
// Parameters:
//	RequestForReturnOfGoods - DocumentRef.RequestForReturnOfGoodsFromCustomer - 
//			link to the customer's order (refund request) for which balances are required.
//	ReturnOfGoodsFromCustomer - DocumentRef - a link to the sale of goods or services (or an empty link).
//
// Returns:
//	QueryResult - the result of the request for the unloaded part of the order\request.
//
Function GetResultOfRequestForRefundRequestBalances(RequestForReturnOfGoods, ReturnOfGoodsFromCustomer) Export

	SetPrivilegedMode(True);

	Query = New Query;
	Query.SetParameter("RequestForReturnOfGoods", RequestForReturnOfGoods);
	Query.SetParameter("Recorder", ReturnOfGoodsFromCustomer);
	Query.Text =
	"
	|SELECT
	|	OrdersTable.Products                     AS Products,
	|	OrdersTable.Characteristic                   AS Characteristic,
	|	OrdersTable.RowCode                        AS RowCode,
	|	SUM(OrdersTable.ToRegister)               AS Count
	|
	|INTO TableBalance
	|
	|FROM
	|	(SELECT
	|		OrdersBalance.Products                     AS Products,
	|		OrdersBalance.Characteristic                   AS Characteristic,
	|		OrdersBalance.RowCode                        AS RowCode,
	|		OrdersBalance.ForRegistrationOnReturnsQuantityTurnover -
	|			OrdersBalance.IssuedByReturnsQuantityTurnover AS ToRegister
	|	FROM
	|		#RequestsForReturnsTurnoverExpanded AS OrdersBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		TrafficOrders.Products,
	|		TrafficOrders.Characteristic,
	|		TrafficOrders.RowCode,
	|		-TrafficOrders.Count
	|	FROM
	|		AccumulationRegister.ShipmentAndReturnReferences AS TrafficOrders
	|	WHERE
	|		TrafficOrders.Recorder = &Recorder
	|		AND TrafficOrders.ReferenceOrder = &RequestForReturnOfGoods
	|		AND Factor IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns))
	|		AND TrafficOrders.Active
	|	
	|	UNION ALL
	|
	|	SELECT
	|		ApplicationProducts.Products,
	|		ApplicationProducts.Characteristic,
	|		ApplicationProducts.RowCode,
	|		ApplicationProducts.Count
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS ApplicationProducts
	|	WHERE
	|		ApplicationProducts.Ref = &RequestForReturnOfGoods
	|		AND ApplicationProducts.Ref.ThisIsOrderAsInvoice
	|	) AS OrdersTable
	|	
	|	GROUP BY
	|		OrdersTable.Products,
	|		OrdersTable.Characteristic,
	|		OrdersTable.RowCode
	|	
	|	HAVING
	|		SUM(OrdersTable.ToRegister) > 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.ProductsInSet                   AS ProductsInSet,
	|	Goods.ItemVariantOfSet                 AS ItemVariantOfSet,
	|	CASE WHEN Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef) THEN 1 ELSE 0 END AS SetIndex,
	|	Goods.Products                         AS Products,
	|	Goods.Characteristic                       AS Characteristic,
	|	Goods.Series                                AS Series,
	|	Goods.Purpose                           AS Purpose,
	|	Goods.DocumentSalesOfGoodsAndServices                   AS DocumentSalesOfGoodsAndServices,
	|	TableBalance.RowCode                    AS RowCode,
	|	TableBalance.Count                   AS Count,
	|	TableBalance.Products.ItemsType AS ItemsType,
	|	Goods.DateOfReceipt                      AS DateOfReceipt,
	|	Goods.Count                           AS QuantityInApplication,
	|	CASE WHEN Goods.Damage
	|		THEN TableBalance.Products
	|	ELSE
	|		VALUE(Catalog.Products.EmptyRef)
	|	END AS ProductsRecordingAsReceived,
	|	CASE WHEN Goods.Damage
	|		THEN TableBalance.Characteristic
	|	ELSE
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END AS CharacteristicRecordingAsReceived,
	|	Goods.Damage                                AS Damage,
	|	Goods.PriceKind                              AS PriceKind,
	|	Goods.Package                             AS Package,
	|	Goods.Price                                 AS Price,
	|	Goods.Sum                                AS Sum,
	|	Goods.VATRate                            AS VATRate,
	|	Goods.LineNumber                          AS LineNumber,
	|	CASE WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor
	|	END                                    AS ZoomRatio
	|
	|INTO OrderBalancesTable
	|
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Goods
	|		ON  CASE WHEN Goods.Damage THEN
	|				TableBalance.Products     = Goods.ProductsRecordingAsReceived
	|			ELSE
	|				TableBalance.Products     = Goods.Products
	|			END
	|			AND CASE WHEN Goods.Damage THEN
	|				TableBalance.Characteristic     = Goods.CharacteristicRecordingAsReceived
	|			ELSE
	|				TableBalance.Characteristic     = Goods.Characteristic
	|			END
	|			AND TableBalance.RowCode      = Goods.RowCode
	|			AND Goods.Ref = &RequestForReturnOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|FROM 
	|	OrderBalancesTable AS Table
	|
	|ORDER BY Table.LineNumber
	|";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &RequestForReturnOfGoods";
	TableFormationParameters.Group = "Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	
	RequestsForReturnsTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#RequestsForReturnsTurnoverExpanded",
		RequestsForReturnsTurnoverExpanded);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Return Query.Execute();
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Trả hàng';
							|ru = 'Возврат товаров';
							|en = 'Return of goods'; fa = 'برگشت کالا';
							|it = 'Restituzione della merce';
							|pl = 'Zwrot towarów';
							|tr = 'Ürün iadesi'"));
	ReturnOfGoodsFromCustomerLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
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

// Determines the availability of the document Return of goods from the customer by the transmitted link to the Receipt Cash register.
// The document Return of goods from the customer must be carried out.
//
// Parameters:
//	CashRegisterReceipt - DocumentRef.CashRegisterReceipt - 
//
// Returns:
//	Boolean -
Function ThereIsReturnOfGoodsFromClientByReceiptCashRegister(CashRegisterReceipt) Export

	Query = New Query;
	Query.Text =
	"SELECT
	|	ReturnOfGoodsFromCustomer.Ref AS Ref
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|WHERE
	|	ReturnOfGoodsFromCustomer.Posted
	|	AND ReturnOfGoodsFromCustomer.CashRegisterReceipt = &CashRegisterReceipt";
	Query.SetParameter("CashRegisterReceipt", CashRegisterReceipt);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region VATAccounting

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.ReturnOfGoodsFromCustomer - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Object.Warehouse;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer 
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent Then
		FillParameters.ReturnOfGoodsFromCustomer = True;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		FillParameters.ReturnOfGoodsFromCommissionAgent = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.ReturnOfGoodsFromCustomer, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	
	RegistrationParameters.Ref				= Object.Ref;
	RegistrationParameters.Organization		= Object.Organization;
	RegistrationParameters.Counterparty			= Object.Counterparty;
	RegistrationParameters.VATTaxation	= Object.VATTaxation;
	
	If Not ValueIsFilled(Object.Date) Then
		RegistrationParameters.Date = CurrentSessionDate();
	Else
		RegistrationParameters.Date = Object.Date;
	EndIf;
	
	RegistrationParameters.ReturnOfGoodsFromVATPayer  = 
		Not Object.CustomerVATExempt And Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
	RegistrationParameters.ReturnOfGoodsFromVATDefaulter = 
		Object.CustomerVATExempt Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer;
	
	Return RegistrationParameters;
	
EndFunction

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.ReturnOfGoodsFromCustomer, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref             = Object.Ref;
	RegistrationParameters.Organization        = Object.Organization;
	RegistrationParameters.Counterparty         = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	
	If Not ValueIsFilled(Object.Date) Then
		RegistrationParameters.Date = CurrentSessionDate();
	Else
		RegistrationParameters.Date = Object.Date;
	EndIf;
	
	RegistrationParameters.ReturnOfGoodsToVendor = 
		Not Object.CustomerVATExempt 
		And (Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
			Or Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent);
	RegistrationParameters.AdjustmentUnderApprovalOfParties = RegistrationParameters.ReturnOfGoodsToVendor;
	RegistrationParameters.SalesViaCommissionAgent = ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(Object.BusinessOperation);
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Return
//	value: Array - names of blocked details.
// Returns:
// Array
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	//Header
	Result.Add("Organization");
	Result.Add("Partner");
	Result.Add("Counterparty");
	Result.Add("Terms");
	Result.Add("Currency");
	Result.Add("Warehouse");
	Result.Add("PriceIncludesVAT");
	Result.Add("DocumentSalesOfGoodsAndServices");
	Result.Add("VATTaxation");
	Result.Add("BusinessOperation");
	Result.Add("CashRegisterReceipt");
	Result.Add("RequestForReturnOfGoodsFromCustomer");
	
	//TS
	Result.Add("Goods");
	Result.Add("ExciseStamps");
	
	Return Result;
	
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
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

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
			|CompensationMethod,
			|Contract");
		BusinessOperation = StructureFillingData.BusinessOperation;
		CompensationMethod     = StructureFillingData.CompensationMethod;
		Contract               = StructureFillingData.Contract;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		CompensationMethod     = Undefined;
		Contract               = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		CompensationMethod     = FillingData.CompensationMethod;
		Contract               = FillingData.Contract;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
		|OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)";
	ParametersStructure.ChangesPaymentPlan               = BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PaymentMethod                      = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	
	If CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment Then
		ParametersStructure.ARAPObjectSettings                        = Enums.ARAPObjectSettings.ByARAPDocuments;
	Else
		ParametersStructure.ARAPObjectSettings                            = "Object.ARAPObjectSettings";
	EndIf;
	ParametersStructure.ConditionalOrderOfCalculations          = 
		"CASE WHEN DataSource.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment) THEN
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|ELSE
		|	DataSource.ARAPObjectSettings
		|END
		|";
	
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "";

	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	ParametersStructure.OrderBase                   = "Object.RequestForReturnOfGoodsFromCustomer";
	
	ReturnOfGoodsViaCommissionAgent = ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(BusinessOperation);
	ConductARAPAccountingThroughEndCustomers = False;
	
	If ReturnOfGoodsViaCommissionAgent Then
		ParametersStructure.Contract = "Object.CustomerContract";
		If ValueIsFilled(Contract) Then
			ConductARAPAccountingThroughEndCustomers = Common.ObjectAttributeValue(Contract, "ConductARAPAccountingThroughEndCustomers");
		EndIf;
		If ConductARAPAccountingThroughEndCustomers Then
			ParametersStructure.Partner = "Object.CustomerPartner";
			ParametersStructure.Counterparty = "Object.CustomerCounterparty";
		EndIf;
		ParametersStructure.CommissionAgentSAgreement = "Object.Contract";
	EndIf;
	
	ParametersStructure.FormItems.HyperlinkPaymentDecryption = "ReducedDebtByLine";
	ParametersStructure.FormItems.LineOfBusiness       = "LineOfBusiness";
	
	ParametersStructure.DocumentAmountForm              = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	
	ParametersStructure.SelectAccountsReceivable   = True;
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.ReturnOfGoodsFromCustomer, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.ReturnOfGoodsFromCustomer - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export

	PartsOfQueryText = New Array;
	TextOfRequestPart =
	"SELECT
	|	GoodsTable.RowID AS RowID,
	|	DimensionKeys.Products AS Products,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.ExciseTaxAmount AS ExciseTaxAmount,
	|	ISNULL(TableTypesOfStocks_.SubjectToExcise, FALSE) AS SubjectToExcise,
	|	TableTypesOfStocks_.BusinessUnitProduction AS BusinessUnitProduction,
	|	GoodsTable.CostDefiningMethod AS CostDefiningMethod,
	|	TheseGrounds.Date AS DateOfImplementationDocument,
	|	ISNULL(TheseGrounds.Date, &Period) AS Date
	|INTO TTTableOfGoods
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS GoodsTable
	|		LEFT JOIN Document.CustomerInvoice AS TheseGrounds
	|		ON GoodsTable.DocumentSalesOfGoodsAndServices = TheseGrounds.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON GoodsTable.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN Catalog.InventoryKinds AS TableTypesOfStocks_
	|		ON GoodsTable.InventoryOwnerAttribute = TableTypesOfStocks_.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|INDEX BY
	|	Products,
	|	Date";
	
	PartsOfQueryText.Add(TextOfRequestPart);
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.SelectingCategoriesByDate = False;
	RequestTextParameters.ProductTableName_ = "TTTableOfGoods";
	RequestTextParameters.FieldNamePeriod = "Date";
	
	TextOfRequestPart = ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters);
	PartsOfQueryText.Add(TextOfRequestPart);
	
	TextOfRequestPart =
	"SELECT
	|	InventoryKinds.Count                                              AS Count,
	|	InventoryKinds.Products                                            AS Products,
	|	InventoryKinds.ExciseTaxAmount                                             AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan  AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	TableExciseCategories.ItemCategory                         AS ExcisableGoodsCategory,
	|	CASE WHEN ISNULL(InventoryKinds.SubjectToExcise, FALSE)
	|		THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * InventoryKinds.Count
	|		ELSE 0
	|	END                                                               AS QuantityInExcisableCategoryUOM,
	|	InventoryKinds.BusinessUnitProduction                               AS BusinessUnitProduction,
	|	InventoryKinds.RowID                                     AS RowID,
	|	CASE WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND InventoryKinds.DateOfImplementationDocument < &BeginningOfMonthOfPeriod
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsViaCommissionAgent)
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND InventoryKinds.DateOfImplementationDocument < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END                                                               AS BusinessTransactionSetting
	|INTO TTTableTypesOfStocks
	|FROM
	|	TTTableOfGoods AS InventoryKinds
	|
	|	INNER JOIN TTExciseCategoriesOfItems AS TableExciseCategories
	|		ON InventoryKinds.Products = TableExciseCategories.Products
	|		AND InventoryKinds.Date = TableExciseCategories.Period
	|
	|WHERE
	|	TableExciseCategories.ExcisableGoods
	|	AND TableExciseCategories.ItemCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.Return) AS KindOfTransactionWithExcisableGoods,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	-TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	-TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|		OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|		OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0
	|";
	PartsOfQueryText.Add(TextOfRequestPart);

	Query = New Query;
	Query.Text = StrConcat(PartsOfQueryText, Common.QueryBatchSeparator());
	
	DocumentAttributes = Common.ObjectAttributesValues(DocumentRef, "Organization, BusinessOperation,
		|Date , LineOfBusiness"); 
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(DocumentAttributes.Organization);
	
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("Period", DocumentAttributes.Date);
	Query.SetParameter("Organization", DocumentAttributes.Organization);
	Query.SetParameter("LineOfBusiness", DocumentAttributes.LineOfBusiness);
	Query.SetParameter("BusinessOperation", DocumentAttributes.BusinessOperation);
	Query.SetParameter("Country", RegistrationCountry);
	Query.SetParameter("BeginningOfMonthOfPeriod", BegOfMonth(DocumentAttributes.Date));
	Query.SetParameter("UseExcisableGoods", ExcisableGoodsAreUsed(DocumentAttributes));
	
	SetRequestParametersCurrencyCoefficients(Query);

	Return Query.Execute();
		
EndFunction

#EndRegion
#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "ReturnOfGoodsFromCustomer");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT
	|	DimensionShipments.StorageLocation AS Warehouse,
	|	DimensionShipments.Products AS Products,
	|	DimensionShipments.Characteristic AS Characteristic,
	|	DimensionShipments.Series AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|INTO GoodsTable
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS DimensionShipments
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributesShipment = DimensionShipments.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND DimensionShipments.StorageLocation <> &Warehouse
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|UNION ALL
	|
	|SELECT
	|	Dimension.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived AS Products,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND NOT &RefundViaCommissionAgent
	|
	|UNION ALL
	|
	|SELECT
	|	&Partner AS Warehouse,
	|	GoodsTable.ProductsRecordingAsReceived  AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND &ThisIsRefundFromCommissionAgent
	|
	|UNION ALL
	|
	|SELECT
	|	&Partner AS Warehouse,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS GoodsTable
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|	AND &ThisIsRefundFromCommissionAgent
	|
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS GoodsTable
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND NOT &ThisIsRefundFromCommissionAgent
	|
	|UNION ALL
	|
	|SELECT
	|	Dimension.StorageLocation AS Warehouse,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|UNION ALL
	|
	|SELECT
	|	&Contract AS Warehouse,
	|	GoodsTable.ProductsRecordingAsReceived  AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND &RefundViaCommissionAgent
	|;
	|///////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	GoodsTable.Warehouse          AS Warehouse,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	GoodsTable.Purpose     AS Purpose
	|FROM
	|	GoodsTable AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Series = Dimension.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|WHERE
	|    Dimension.DimensionKey IS NULL
	|");
	
	QueryAnalyst.SetParameter("Ref",                   Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Warehouse",                    Query.Parameters.Warehouse);
	QueryAnalyst.SetParameter("Partner",                  Query.Parameters.Partner);
	QueryAnalyst.SetParameter("ThisIsRefundFromCommissionAgent", Query.Parameters.ThisIsRefundFromCommissionAgent);
	QueryAnalyst.SetParameter("RefundViaCommissionAgent", Query.Parameters.RefundViaCommissionAgent);
	QueryAnalyst.SetParameter("Contract",                  Query.Parameters.Contract);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
		Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure
Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRatioFromLocalToMan") Then
		Return;
	EndIf;
	
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	RatePeriod = Query.Parameters.Period;

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	
EndProcedure
Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 

	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS ShipmentCompany,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END AS Organization,
	|	TableTypesOfStocks_.DimensionReturnPolicy AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.OwnerSInventoryOwnersAttributeTypeOfInventory
	|		ELSE TableTypesOfStocks_.InventoryType
	|	END AS InventoryOwnerAttributeIsTypeOfInventory,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType AS CCDNumberCCDNumberType,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation AS VATTaxation,
	|	CASE
	|		WHEN TableTypesOfStocks_.TransferredMultiTurnPackaging
	|			THEN TableTypesOfStocks_.DimensionSalesOfGoodsAndServices
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		ELSE TableTypesOfStocks_.DimensionSalesOfGoodsAndServices
	|	END AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|	END AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Primary
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END,
	|	TableTypesOfStocks_.LogInAnalytics,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND NOT TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN CASE
	|					WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef)
	|						THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|					ELSE TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|				END
	|		ELSE CASE
	|				WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|					THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|				ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|			END
	|	END,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND NOT TableTypesOfStocks_.InventoryOwnerAttributeSaleOfAnotherCompanySInventory
	|			THEN CASE
	|					WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef)
	|						THEN TableTypesOfStocks_.InventoryType
	|					ELSE TableTypesOfStocks_.InventoryOwnerAttributeOfShipmentIsTypeOfInventory
	|				END
	|		ELSE CASE
	|				WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|					THEN TableTypesOfStocks_.OwnerSInventoryOwnersAttributeTypeOfInventory
	|				ELSE TableTypesOfStocks_.InventoryType
	|			END
	|	END,
	|	TableTypesOfStocks_.VATRate,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType,
	|	-TableTypesOfStocks_.Count,
	|	-TableTypesOfStocks_.QuantityByGBRN,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END,
	|	&BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|	END,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
		
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers) Export
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 

	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
		
	QueryText = 
	"SELECT
	|	TTProductsOfOrganizations.LineNumber AS LineNumber,
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TTProductsOfOrganizations.Primary AS Primary
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	&Period                                            AS Period,
	|	&Organization                                       AS Organization,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts AS ItemsLocationAttributes,
	|	&Terms                                        AS Terms,
	|	TableTypesOfStocks_.Products                    AS Products,
	|	TableTypesOfStocks_.Characteristic                  AS Characteristic,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute END) AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(&Period, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|			THEN TableTypesOfStocks_.QuantityByGBRN
	|		ELSE 0
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices              AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation                             AS BusinessOperation,
	|	(CASE TableTypesOfStocks_.ProductsRecordingAsReceived 
	|		WHEN VALUE(Catalog.Products.EmptyRef) THEN TableTypesOfStocks_.DimensionReturnPolicy
	|		ELSE TableTypesOfStocks_.LogInAnalytics END) AS CorItemsLocationAttributes
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND (TableTypesOfStocks_.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR (TableTypesOfStocks_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND NOT &ReusablePackageReturn))
	|	AND NOT &RefundViaCommissionAgent
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction 

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                      AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	&Period                                             AS Period,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization  AS CompanyOwner,
	|	TableTypesOfStocks_.DimensionReturnPolicy                AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                       AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                         AS CCDNumber,
	|	TableTypesOfStocks_.Count                       AS Returned,
	|	TableTypesOfStocks_.Products                     AS Products,
	|	TableTypesOfStocks_.Characteristic                   AS Characteristic,
	|	&BusinessOperation                              AS BusinessOperation
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber                      AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	&Period                                             AS Period,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization  AS CompanyOwner,
	|	TableTypesOfStocks_.LogInAnalytics           AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                       AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                         AS CCDNumber,
	|	TableTypesOfStocks_.Count                       AS Returned,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived        AS Products,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived      AS Characteristic,
	|	&BusinessOperation                              AS BusinessOperation
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParameterCorInventoryView(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ExchangeRates", QueryTexts) Then
		QueryTextExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&Period											AS Period,
	|	&Organization									AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|	END											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeImplementationAnalytics	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Currency						AS Currency,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	(-TableTypesOfStocks_.Count)				AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.Currency = &Currency
	|			THEN -TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE -TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END											AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN -TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END											AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN -TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END											AS RevenueAmountMan,
	|	0												AS QuantityConsumed,
	|	(-TableTypesOfStocks_.Count)				AS QuantityToRegister,
	|	(-TableTypesOfStocks_.QuantityByGBRN)			AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.Currency = &Currency
	|			THEN -TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE -TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END											AS RevenueAmountToRegister,
	|	0												AS QuantityConsumedForIncoiceRegistration,
	|	0												AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&BusinessOperation							AS BusinessOperation,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.Products					AS Products,
	|	TableTypesOfStocks_.Characteristic				AS Characteristic,
	|	&IDARAPObject					AS FinRecordID,
	|	&BusinessTransactionSetting					AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID			AS RowID
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute.Currency = ExchangeRates.Currency
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT &ReusablePackageReturn))
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	&Period											AS Period,
	|	&Organization									AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeImplementationAnalytics	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Currency						AS Currency,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	0												AS Count,
	|	0												AS RevenueAmount,
	|	0												AS RevenueAmountExclVATLocal,
	|	0												AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count					AS QuantityConsumed,
	|	0												AS QuantityToRegister,
	|	0												AS QuantityForRegistrationByProductBatchID,
	|	0												AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.Count					AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&BusinessOperation							AS BusinessOperation,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.Products					AS Products,
	|	TableTypesOfStocks_.Characteristic				AS Characteristic,
	|	&IDARAPObject					AS FinRecordID,
	|	&BusinessTransactionSetting					AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID			AS RowID
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND NOT TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|	AND (TableTypesOfStocks_.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT &ReusablePackageReturn))
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetParameterForPartnerAccountingAnalyticsRequest(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|			VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument),
	|			VALUE(Enum.WaysToCalculateReturnCost.Manually))
	|		 AND &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.DimensionReturnPolicy
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|			VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument),
	|			VALUE(Enum.WaysToCalculateReturnCost.Manually))
	|		 AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ReturnAnalyticsWithoutAssignment
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.DimensionSalesOfGoodsAndServices
	|		ELSE InventoryKinds.UnassignedImplementationAnalytics
	|	END AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryType AS InventoryType,
	|
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|			InventoryKinds.InventoryOwnerAttributeShipment
	|		ELSE
	|			InventoryKinds.InventoryOwnerAttribute
	|		END AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		 AND &BatchAccountingVersion22 AND &FIFORollingValuation
	|			THEN InventoryKinds.Ref
	|		ELSE UNDEFINED END) AS Lot,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		 AND &BatchAccountingVersion22 AND &FIFORollingValuation
	|			THEN InventoryKinds.LotVendorAttributes
	|		ELSE UNDEFINED END) AS LotVendorAttributes,
	|	(CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	// If the return is not based on the implementation document, the return warehouse is indicated in the inventory tracking analytics, so
	// the sign of the shop storeroom of the return warehouse is checked. 
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|			VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument),
	|			VALUE(Enum.WaysToCalculateReturnCost.Manually))
	|		 AND InventoryKinds.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	// When returning according to the sales document, the sign of the shop pantry of the shipment warehouse is checked.
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		 AND InventoryKinds.ShopPantryShipment 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) 
	|	END) AS AccountingSection,
	|	InventoryKinds.VATTaxation AS VATActivityType,
	|	
	|	&Manager AS Manager,
	|	
	|	CASE WHEN InventoryKinds.OrderingImplementation <> UNDEFINED THEN
	|		InventoryKinds.OrderingImplementation
	|	ELSE
	|		InventoryKinds.DocumentSalesOfGoodsAndServices
	|	END AS SalesOrder,
	|
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionSalesOfGoodsAndServices.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|
	|	&AccountingDimensionByPartners          AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod IN (
	|			VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument),
	|			VALUE(Enum.WaysToCalculateReturnCost.Manually))
	|			THEN &Department
	|		ELSE InventoryKinds.ImplementationDivision
	|	END AS Department,
	|	- InventoryKinds.Count            AS Count,
	|	- InventoryKinds.AmountIncludingVATMan          AS RevenueAmount,
	|	- InventoryKinds.AmountExcludingVATMan        AS RevenueAmountExcludingVAT,
	|	- InventoryKinds.AmountExcludingVATCompl       AS RevenueAmountExclVATLocal,
	|	- (InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATAmountCompl) AS RevenueAmountIncludingVATLocal,
	|
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountIncludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.Cost_
	|		ELSE 0 END AS Cost,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountExcludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.CostExcludingVAT_
	|		ELSE 0 END AS CostExcludingVAT,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountExcludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.CostExcludingVAT_
	|		ELSE 0 END AS CostMan,
	|
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountExcludingVATCompl
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.CostLocal
	|		ELSE 0 END AS LocalCost,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	InventoryKinds.OriginWarehouse AS Warehouse,
	|	CASE WHEN &RefundViaCommissionAgent
	|		THEN &CustomerContract
	|		ELSE &Contract
	|	END AS Contract,
	|	&Terms AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	-InventoryKinds.AmountIncludingVAT AS AmountInARAPCurrency,
	|	-(InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	-InventoryKinds.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	-(InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|	-InventoryKinds.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	-InventoryKinds.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|
	|	InventoryKinds.VATTaxation,
	|
	|	CASE 
	|	WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		AND InventoryKinds.SalePeriod < &BeginningOfMonthOfPeriod
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|	THEN
	|		VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|	WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		AND InventoryKinds.SalePeriod < &BeginningOfMonthOfPeriod
	|	THEN
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|		THEN &BusinessOperation
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
	|		THEN &BusinessOperation
	|	WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		CASE WHEN InventoryKinds.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|			InventoryKinds.InventoryOwnerAttributeShipment
	|		ELSE
	|			InventoryKinds.InventoryOwnerAttribute
	|		END
	|	ELSE
	|		InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	InventoryKinds.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND InventoryKinds.SalePeriod >= &BeginningOfMonthOfPeriod
	|			AND InventoryKinds.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),VALUE(Enum.InventoryTypes.ConsignedGoods))
	|			AND (InventoryKinds.OriginWarehouse <> InventoryKinds.ReturnWarehouse
	|			OR InventoryKinds.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|			OR InventoryKinds.InventoryOwnerAttributeShipment <> InventoryKinds.InventoryOwnerAttribute
	|			OR InventoryKinds.Purpose <> InventoryKinds.PurposeOfShipment AND &KeepRecordsOfInventoryCostByAssignments)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE InventoryKinds.BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	InventoryKinds.VATRate AS VATRate
	|	
	|FROM
	|	TTTableTypesOfStocks AS InventoryKinds
	|WHERE
	|	NOT (InventoryKinds.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) AND &ReusablePackageReturn)
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|
	|ORDER BY
	|	LineNumber
	|";
	
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
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	CASE
	|		WHEN DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN FALSE
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND DocumentTable.Ref.ReusablePackageReturn
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                       AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)               AS RecordType,
	|	&Period                                              AS Period,
	|	&Organization                                         AS Organization,
	|	TableTypesOfStocks_.DimensionReturnPolicy                 AS ItemsLocationAttributes,
	|	&Ref                                              AS DocumentInflow,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                        AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes              AS LotVendorAttributes,
	|
	|	-TableTypesOfStocks_.Count                       AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.Cost_
	|		ELSE -TableTypesOfStocks_.AmountIncludingVATMan
	|	END                                                AS Cost,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE -TableTypesOfStocks_.AmountExcludingVATMan
	|	END                                                AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.CostLocal
	|		ELSE -TableTypesOfStocks_.AmountExcludingVATCompl
	|	END AS LocalCost,
	|	0                                                    AS VATLocal,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.CDCost
	|		ELSE 0
	|	END                                                AS PermanentDifference,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.TDCost
	|		ELSE 0
	|	END                                                AS CostTD,
	|
	|	TableTypesOfStocks_.Characteristic                    AS Characteristic, 
	|	TableTypesOfStocks_.Products                      AS Products,
	|	UNDEFINED                                         AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.VATTaxation                AS VATTaxation,
	|	&BusinessOperation                               AS BusinessOperation,
	|	TRUE                                               AS Primary,
	|	UNDEFINED                                         AS DocumentSource
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|	AND TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|		VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer))
	|	AND &BatchAccountingVersion21
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber                       AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)               AS RecordType,
	|	&Period                                              AS Period,
	|	&Organization                                         AS Organization,
	|	TableTypesOfStocks_.LogInAnalytics            AS ItemsLocationAttributes,
	|	&Ref                                              AS DocumentInflow,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND NOT TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN CASE
	|					WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef)
	|						THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|					ELSE TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|				END
	|		ELSE CASE
	|				WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|					THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|				ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|			END
	|	END                                                AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes              AS LotVendorAttributes,
	|
	|	-TableTypesOfStocks_.Count                       AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.Cost_
	|		ELSE -TableTypesOfStocks_.AmountIncludingVATMan
	|	END                                                AS Cost,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE -TableTypesOfStocks_.AmountExcludingVATMan
	|	END                                                AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.CostLocal
	|		ELSE -TableTypesOfStocks_.AmountExcludingVATCompl
	|	END AS LocalCost,
	|	0                                                    AS VATLocal,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.CDCost
	|		ELSE 0
	|	END                                                AS PermanentDifference,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -TableTypesOfStocks_.TDCost
	|		ELSE 0
	|	END                                                AS CostTD,
	|
	|	TableTypesOfStocks_.Characteristic                    AS Characteristic,
	|	TableTypesOfStocks_.Products                      AS Products,
	|	TableTypesOfStocks_.DimensionReturnPolicy                 AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.VATTaxation                AS VATTaxation,
	|	&BusinessOperation                               AS BusinessOperation,
	|	TRUE                                               AS Primary,
	|	UNDEFINED                                         AS DocumentSource
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|		VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer))
	|	AND &BatchAccountingVersion21
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts
	|		ELSE TableTypesOfStocks_.AnalysisOfTransmittedProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.AnalysisOfTransmittedProducts.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	&Partner AS Warehouse,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|			TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE
	|			TableTypesOfStocks_.InventoryOwnerAttribute
	|		END AS InventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.DimensionReturnPolicy AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.DimensionReturnPolicy.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	TableTypesOfStocks_.ReturnWarehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.InventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.Count AS CorQuantity,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|			ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|			ELSE TableTypesOfStocks_.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&ThisIsRefundFromCommissionAgent
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReturnOfGoodsFromCustomer";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("UseAdvancedFeaturesOfSalesOrder",
		GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("RefundOnRequest",
		"	CASE
		|		WHEN GoodsTable.Ref.RequestForReturnOfGoodsFromCustomer = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|			THEN FALSE
		|		ELSE TRUE
		|	END");
	RedefiningParameterCalculation.Insert("UseWarehouseManagemantSystemForGoodsReceipt",
		"	CASE
		|		WHEN GoodsTable.Ref.Date >= GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|				AND GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("UseAdvancedFeaturesOfSalesOrder",
		"	CASE
		|		WHEN GoodsTable.Ref.RequestForReturnOfGoodsFromCustomer = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|			THEN &UseAdvancedFeaturesOfSalesOrder
		|		ELSE NOT GoodsTable.Ref.RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice
		|	END");
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Date                             AS Period,
	|	DocumentData.Ref                           AS Ref,
	|	DocumentData.Counterparty                       AS Counterparty,
	|	ISNULL(DocumentData.Counterparty.LegalEntityIndividual, VALUE(Enum.LegalEntityIndividual.EmptyRef)) AS CounterpartyLegEntInd,
	|	DocumentData.Partner                          AS Partner,
	|	DocumentData.CustomerPartner                    AS CustomerPartner,
	|	DocumentData.CustomerCounterparty                 AS CustomerCounterparty,
	|	DocumentData.CustomerContract                    AS CustomerContract,
	|	DocumentData.Organization                      AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Currency                           AS Currency,
	|	DocumentData.PriceIncludesVAT                  AS PriceIncludesVAT,
	|	DocumentData.Warehouse                            AS Warehouse,
	|	DocumentData.ControlledLotReference             AS ControlledLotReference,
	|	DocumentData.Department                    AS Department,
	|	DocumentData.BusinessOperation            AS BusinessOperation,
	|	DocumentData.Terms                       AS Terms,
	|	DocumentData.Contract                          AS Contract,
	|	ISNULL(DocumentData.Contract.ConductARAPAccountingThroughEndCustomers, FALSE) AS ConductARAPAccountingThroughEndCustomers,
	|	DocumentData.Comment                      AS Comment,
	|	DocumentData.DocumentAmount                   AS DocumentAmount,
	|	DocumentData.RequestForReturnOfGoodsFromCustomer  AS RequestForReturnOfGoodsFromCustomer,
	|	DocumentData.ReturnOfSpoiledGoods                     AS ReturnOfSpoiledGoods,
	|	DocumentData.VATTaxation               AS VATTaxation,
	|	DocumentData.ReusablePackageReturn AS ReusablePackageReturn,
	|	DocumentData.DepositForPackageIsRequired             AS DepositForPackageIsRequired,
	|	DocumentData.CashIssued           AS CashIssued,
	|	DocumentData.Manager                         AS Manager,
	|	DocumentData.Posted                         AS Posted,
	|	DocumentData.DeletionMark                  AS DeletionMark,
	|	DocumentData.IncomingDocumentDate           AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber          AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName   AS ExternalDocumentName,
	|	DocumentData.Number                            AS Number,
	|	DocumentData.GoodsReceiptOption            AS GoodsReceiptOption,
	|	DocumentData.SalesOpportunity                           AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarehouseManagemantSystemForGoodsReceipt,
	|	
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ThisIsRefundFromCommissionAgent,
	|	
	|	CASE WHEN DocumentData.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ReturnCash) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ReturnCash,
	|	
	|	DocumentData.CustomerVATExempt AS CustomerVATExempt,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	PRESENTATION(DocumentData.Contract) AS ContractPresentation,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	DocumentData.Author AS Author,
	|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting,
	|	ISNULL(DocumentData.RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice, UNDEFINED) AS ThisIsOrderAsInvoice,
	|	UNDEFINED AS AdjustmentPeriod_
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;

	Query.SetParameter("BeginningOfMonthOfPeriod",                         BegOfMonth(Attributes.Period));
	Query.SetParameter("PriceIncludesVAT",                             ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("LocalAccountingCurrency",              Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",                  Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RefundOnRequest",                             ValueIsFilled(Attributes.RequestForReturnOfGoodsFromCustomer));
	Query.SetParameter("ReturnWarehouse",                               Attributes.Warehouse);
	Query.SetParameter("TaxationOfOrganization",                  AccountingParametersForOrganization.BasicTaxationVATSales);	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("MetadataIdentifier",       			     Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",             Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("CurrentDate",                                 CurrentUniversalDate());
	Query.SetParameter("RefundViaCommissionAgent",                    ConsignmentSalesServer.ReturnOfGoodsViaCommissionAgent(Attributes.BusinessOperation));
	
	If Attributes.ThisIsOrderAsInvoice = Undefined Then
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	Else
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", Not Attributes.ThisIsOrderAsInvoice);
	EndIf;
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.ContractPresentation);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref									AS Ref,
	|	DataSource.Ref									AS Invoice,
	|	FALSE                                                    AS Patch,
	|	UNDEFINED                                            AS CorrectedDocument,
	|	DataSource.Ref.RequestForReturnOfGoodsFromCustomer	AS OrderDocument,
	|	DataSource.Ref.Contract							AS Contract,
	|	DataSource.Ref.Terms						AS Terms,
	|	DataSource.Ref.GoodsReceiptOption				AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE DataSource.Products
	|	END													AS Products,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE DataSource.Characteristic
	|	END													AS Characteristic,
	|	DataSource.Purpose								AS Purpose,
	|	DataSource.ToControlQuality                AS ToControlQuality,
	|	FALSE                                                    AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference              AS ControlledLotReference,
	|	DataSource.Series									AS Series,
	|	DataSource.BatchesIndicationStatus						AS BatchesIndicationStatus,
	|	DataSource.Ref.RequestForReturnOfGoodsFromCustomer <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|		AND DataSource.RowCode = 0						AS ExceedingOrder,
	|	DataSource.Warehouse									AS Warehouse,
	|	DataSource.Ref.Partner							AS Sender,
	|	DataSource.Ref.BusinessOperation				AS BusinessOperation,
	|	DataSource.Count								AS Count,
	|	TRUE													AS ThisIsAnInvoice,
	|	CASE
	|		WHEN DataSource.Ref.RequestForReturnOfGoodsFromCustomer = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|			THEN FALSE
	|		ELSE NOT DataSource.Ref.RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice
	|	END AS ReceiptUnderOrders
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND NOT DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref									AS Ref,
	|	DataSource.Ref									AS Invoice,
	|	FALSE                                                    AS Patch,
	|	UNDEFINED                                            AS CorrectedDocument,
	|   DataSource.Ref.RequestForReturnOfGoodsFromCustomer	AS OrderDocument,
	|	DataSource.Ref.Contract							AS Contract,
	|	DataSource.Ref.Terms						AS Terms,
	|	DataSource.Ref.GoodsReceiptOption				AS GoodsReceiptOption,
	|	DataSource.Ref.Date								AS Date,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE DataSource.Products
	|	END													AS Products,
	|	DataSource.Products								AS ItemsForConnection,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE DataSource.Characteristic
	|	END													AS Characteristic,
	|	DataSource.Characteristic							AS CharacteristicForConnection,
	|	DataSource.Purpose								AS Purpose,
	|	DataSource.ToControlQuality                AS ToControlQuality,
	|	FALSE                                                    AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference              AS ControlledLotReference,
	|	DataSource.Series									AS Series,
	|	DataSource.BatchesIndicationStatus						AS BatchesIndicationStatus,
	|	DataSource.Ref.RequestForReturnOfGoodsFromCustomer <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|		AND DataSource.RowCode = 0						AS ExceedingOrder,
	|	DataSource.Warehouse									AS Warehouse,
	|	DataSource.Ref.Partner							AS Sender,
	|	DataSource.Ref.BusinessOperation				AS BusinessOperation,
	|	DataSource.Count								AS Count,
	|	TRUE													AS ThisIsAnInvoice,
	|	CASE
	|		WHEN DataSource.Ref.RequestForReturnOfGoodsFromCustomer = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|			THEN FALSE
	|		ELSE NOT DataSource.Ref.RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice
	|	END AS ReceiptUnderOrders,
	|	FALSE													AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND NOT DataSource.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)";
	
	CurrentMetadataObject1 = Metadata.Documents.ReturnOfGoodsFromCustomer;
	
	AdditionalSeriesConnectionFields = New Array;
	AdditionalSeriesConnectionFields.Add("ProductsRecordingAsReceived");
	AdditionalSeriesConnectionFields.Add("CharacteristicRecordingAsReceived");
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Products", "ItemsForConnection");
	RedefinedSeriesConnectionFields.Insert("Characteristic", "CharacteristicForConnection");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
	ParametersOfModularHolding.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	
	WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(Query,
														QueryTexts,
														Registers,
														QueryTextDocument_,
														CurrentMetadataObject1,
														ParametersOfModularHolding);

EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentRef)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	ValueText_ = 
	"SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	InventoryKinds.Ref.Counterparty AS Counterparty,
	|	InventoryKinds.Ref.Contract AS Contract,
	|	UNDEFINED AS Shipper,
	|	InventoryKinds.Ref.CustomerVATExempt AS CustomerVATExempt,
	|	CASE 
	|		WHEN InventoryKinds.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS RetailCustomer,
	|	InventoryKinds.Ref.CustomerCounterparty AS ConsignedGoodsCustomer,
	|	CASE 
	|		WHEN InventoryKinds.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ReturnOfGoodsViaCommissionAgent,
	|	InventoryKinds.Ref.CashIssued AS FundsReturnedToRetailBuyer,
	|	InventoryKinds.Ref.CashAccountIssueNoteNumber AS CashReturnDocumentNumberToRetailBuyer,
	|	InventoryKinds.Ref.CashAccountIssueNoteDate AS DateOfDocumentOfReturnOfCashToRetailBuyer,
	|	InventoryKinds.Ref AS DocumentReturnPolicy,
	|	InventoryKinds.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	InventoryKinds.Ref.ARAPObject AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.Ref.VATTaxation AS VATActivityType,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.Products AS Products,
	|	InventoryKinds.Characteristic AS Characteristic,
	|	InventoryKinds.Series AS Series,
	|	InventoryKinds.ProductsInSet AS ProductsInSet,
	|	InventoryKinds.ItemVariantOfSet AS ItemVariantOfSet,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|				OR InventoryKinds.NumberOfPackages = 0
	|			THEN InventoryKinds.Count
	|		ELSE InventoryKinds.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryKinds.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.ExciseTaxAmount AS ExciseTaxAmount,
	|	InventoryKinds.Products.FEACNCode AS FEACNCode,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.Ref.LineOfBusiness AS LineOfBusiness,
	|	InventoryKinds.Purpose AS Purpose,
	|	InventoryKinds.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND InventoryKinds.SalePeriod >= &BeginningOfMonthOfPeriod
	|			AND InventoryKinds.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),VALUE(Enum.InventoryTypes.ConsignedGoods))
	|			AND (InventoryKinds.OriginWarehouse <> InventoryKinds.ReturnWarehouse
	|			OR InventoryKinds.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|			OR InventoryKinds.InventoryOwnerAttributeShipment <> InventoryKinds.InventoryOwnerAttribute
	|			OR InventoryKinds.Purpose <> InventoryKinds.PurposeOfShipment AND &KeepRecordsOfInventoryCostByAssignments)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE InventoryKinds.BusinessTransactionSetting
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfStocks AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|			VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|	AND (CASE WHEN InventoryKinds.Ref.ReusablePackageReturn THEN
	|			InventoryKinds.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|";

	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryKinds.Package",
			"InventoryKinds.Products"));

	VATAccountingERP.ReflectReturnOfGoodsFromBuyer(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

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
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
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
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.ReturnOfGoodsFromCustomer AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.ARAPDetails AS Table
		|		LEFT JOIN Document.ReturnOfGoodsFromCustomer AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	Table.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.ARAPDetails AS Table
		|		LEFT JOIN Document.ReturnOfGoodsFromCustomer AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	TextReturn = "
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Organization             AS Organization,
		|	CASE WHEN &BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent),
		|					VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods))
		|				AND &ConductARAPAccountingThroughEndCustomers
		|			THEN Table.CustomerPartner
		|		ELSE Table.Partner
		|	END                           AS Partner,
		|	
		|	Table.ARAPObject          AS ARAPObject,
		|	Table.Currency                  AS ARAPCurrency,
		|	Table.Currency                  AS DocumentCurrency,
		|	Table.DocumentAmount          AS AmountARAP,
		|	Table.DocumentAmount          AS Sum,
		|	CASE
		|		WHEN Table.RequestForReturnOfGoodsFromCustomer <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|			AND Table.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|			AND Table.RequestForReturnOfGoodsFromCustomer.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ReturnCash)
		|				THEN 0
		|		ELSE Table.DocumentAmount
		|	END                           AS AmountDue,
		|	
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.Date                    AS DateOfCourse,
		|	Table.BusinessOperation   AS BusinessOperation,
		|	UNDEFINED                    AS CashFlowItem
		|FROM
		|	Document.ReturnOfGoodsFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)";
	
	TextTranscriptOfPayment = "
		|SELECT
		|	Table.Ref                                                        AS Ref,
		|	Table.Ref.Organization                                            AS Organization,
		|	CASE WHEN &BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent),
		|					VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods))
		|				AND &ConductARAPAccountingThroughEndCustomers
		|			THEN Table.Ref.CustomerPartner
		|		ELSE Table.Ref.Partner
		|	END                                                                 AS Partner,
		|
		|	Table.Ref.ARAPObject                                         AS CalculationObjectSource,
		|	Table.ARAPObject                                                AS CalculationObjectReceiver,
		|	
		|	Table.Sum                                                         AS Sum,
		|	Table.Ref.Currency                                                 AS DocumentCurrency,
		|	Table.AmountARAP                                           AS AmountARAP,
		|	Table.ARAPCurrency                                          AS ARAPCurrency,
		|	Table.Ref.Date                                                   AS RecorderDate,
		|	Table.Ref.Date                                                   AS DateOfCourse,
		|	Table.Ref.Number                                                  AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.ARAPDetails AS Table
		|WHERE
		|	Table.ARAPObject <> Table.Ref.ARAPObject
		|	AND Table.Ref IN (&Ref)";
	
	ARAPAccountingPostingCustomers.CarryingOutReturnOfGoodsFromCustomer(Query, QueryTexts, Registers, TextReturn, TextTranscriptOfPayment);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingDimensionByPartners");
	AdditionalParameters.Add("CorInventoryOwnerAttribute");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalyticsRequest(Query);
		SetRequestParameterCorInventoryView(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product_CostManually
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	CASE WHEN TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef) THEN
	|		TableTypesOfStocks_.LogInAnalytics
	|	ELSE TableTypesOfStocks_.DimensionReturnPolicy
	|	END 												AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	&TaxationOfOrganization							AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation				AS DocumentVATActivityType,
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
	|	UNDEFINED 					AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.Cost_
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS Cost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostLocal
	|		ELSE CASE
	|			WHEN TableTypesOfStocks_.VATTaxation IN (
	|			  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|				THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|				ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|			END
	|	END 											AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END AS VATLocal,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE CASE
	|			WHEN TableTypesOfStocks_.VATTaxation IN (
	|			  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|				THEN TableTypesOfStocks_.AmountIncludingVATMan
	|				ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|			END
	|	END 											AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountMan
	|	END AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CDCost
	|		ELSE 0
	|	END 											AS PermanentDifference,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.TDCost
	|		ELSE 0
	|	END 											AS CostTD,
	|	0 												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn) 		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID			 							AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region Sales_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 			 AS Period,
	|	DocumentTable.Ref 		 AS Ref,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END 							 AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod AS SourceDocumentPeriod,
	|	UNDEFINED 					 AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	         AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|		THEN TableTypesOfStocks_.LogInAnalytics
	|		ELSE TableTypesOfStocks_.DimensionReturnPolicy
	|	END 											AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices   		AS CorItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.OrderingImplementation <> UNDEFINED
	|		THEN TableTypesOfStocks_.OrderingImplementation
	|		ELSE TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN &RefundViaCommissionAgent AND TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse)
	|	END AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN TableTypesOfStocks_.BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		ELSE VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|	END AS EntryType,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod IN (VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|																	VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN DATETIME(1,1,1)
	|		WHEN SaleOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		 AND SaleOfGoodsAndServices.DateOfTransferOfTitleToGoods <> DATETIME(1,1,1)
	|			THEN SaleOfGoodsAndServices.DateOfTransferOfTitleToGoods
	|		ELSE ISNULL(RegisterOfDocumentsImplementation.IBDocumentDate, DATETIME(1,1,1))
	|	END AS SalePeriod
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Document.CustomerInvoice AS SaleOfGoodsAndServices
	|		ON SaleOfGoodsAndServices.Ref = TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsImplementation
	|		ON TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = RegisterOfDocumentsImplementation.Ref
	|			AND NOT RegisterOfDocumentsImplementation.AdditionalRecord
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND (TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	//Conditions for returning to another warehouse (BT cancellation and refund of another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|		OR TableTypesOfStocks_.OriginWarehouse <> TableTypesOfStocks_.ReturnWarehouse
	|		OR TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|		OR TableTypesOfStocks_.InventoryOwnerAttributeShipment <> TableTypesOfStocks_.InventoryOwnerAttribute
	|		OR TableTypesOfStocks_.Purpose <> TableTypesOfStocks_.PurposeOfShipment
	|			AND &KeepRecordsOfInventoryCostByAssignments)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND NOT TableTypesOfStocks_.TransferredMultiTurnPackaging";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region Sales_Goods_Storno
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 			 AS Period,
	|	DocumentTable.Ref 		 AS Ref,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END 							 AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod AS SourceDocumentPeriod,
	|	UNDEFINED 					 AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	         AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices			AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices   		AS CorItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN TableTypesOfStocks_.OrderingImplementation <> UNDEFINED
	|		THEN TableTypesOfStocks_.OrderingImplementation
	|		ELSE TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.ImplementationDivision	AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	CASE
	|		WHEN &RefundViaCommissionAgent
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.ReversingEntry) AS EntryType,
	|	CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod IN (VALUE(Enum.WaysToCalculateReturnCost.Manually),
	|																	VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument))
	|			THEN DATETIME(1,1,1)
	|		WHEN SaleOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|		 AND SaleOfGoodsAndServices.DateOfTransferOfTitleToGoods <> DATETIME(1,1,1)
	|			THEN SaleOfGoodsAndServices.DateOfTransferOfTitleToGoods
	|		ELSE ISNULL(RegisterOfDocumentsImplementation.IBDocumentDate, DATETIME(1,1,1))
	|	END AS SalePeriod
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Document.CustomerInvoice AS SaleOfGoodsAndServices
	|		ON SaleOfGoodsAndServices.Ref = TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsImplementation
	|		ON TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = RegisterOfDocumentsImplementation.Ref
	|			AND NOT RegisterOfDocumentsImplementation.AdditionalRecord
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND TableTypesOfStocks_.SalePeriod >= &BeginningOfMonthOfPeriod
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND NOT TableTypesOfStocks_.TransferredMultiTurnPackaging
	//Conditions for no return to another warehouse (BT cancellation of a refund to another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|	AND TableTypesOfStocks_.OriginWarehouse = TableTypesOfStocks_.ReturnWarehouse
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|	AND TableTypesOfStocks_.InventoryOwnerAttributeShipment = TableTypesOfStocks_.InventoryOwnerAttribute
	|	AND (TableTypesOfStocks_.Purpose = TableTypesOfStocks_.PurposeOfShipment
	|				OR NOT &KeepRecordsOfInventoryCostByAssignments)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region DisposalAtFixedCost_Tare
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 			 AS Period,
	|	DocumentTable.Ref 		 AS Ref,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END 							 AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod AS SourceDocumentPeriod,
	|	UNDEFINED 					 AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_             AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	CASE WHEN TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|		THEN TableTypesOfStocks_.LogInAnalytics
	|		ELSE TableTypesOfStocks_.DimensionReturnPolicy
	|	END 											AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices   		AS CorItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner 						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods)  AS IncomeItem,
	|	DocumentTable.Partner 						AS DimensionOfRevenue,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.Cost_
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 									AS Cost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END					 				AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostLocal
	|		ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 									AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 									AS CostMan,
	|	0 										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse)
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN &DepositForPackageIsRequired
	|		THEN &IDARAPObject
	|		ELSE TableTypesOfStocks_.RowID
	|	END AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnPackageFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.TransferredPackageReverseTransactionReturnToAnotherWarehouse)
	|	END AS BusinessTransactionSetting,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		ELSE VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|	END AS EntryType
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND (TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	//Conditions for returning to another warehouse (BT to the other warehouse that was not returned). For this BT, the Registered Records will be used similar to the return in the previous period
	|		OR TableTypesOfStocks_.OriginWarehouse <> TableTypesOfStocks_.ReturnWarehouse
	|		OR TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|		OR TableTypesOfStocks_.InventoryOwnerAttributeShipment <> TableTypesOfStocks_.InventoryOwnerAttribute
	|		OR TableTypesOfStocks_.Purpose <> TableTypesOfStocks_.PurposeOfShipment
	|			AND &KeepRecordsOfInventoryCostByAssignments)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND TableTypesOfStocks_.TransferredMultiTurnPackaging";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion

	#Region DisposalAtFixedCost_Tare_Storno
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 			 AS Period,
	|	DocumentTable.Ref 		 AS Ref,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		THEN TableTypesOfStocks_.DocumentSalesOfGoodsAndServices
	|		ELSE UNDEFINED
	|	END 							 AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod AS SourceDocumentPeriod,
	|	UNDEFINED 					 AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_             AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices			AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.DimensionSalesOfGoodsAndServices   		AS CorItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	DocumentTable.Partner 						AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods)  AS IncomeItem,
	|	DocumentTable.Partner 						AS DimensionOfRevenue,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN -TableTypesOfStocks_.Cost_
	|		ELSE -TableTypesOfStocks_.AmountIncludingVATMan
	|	END 									AS Cost,
	|	-CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END									AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN -TableTypesOfStocks_.CostLocal
	|		ELSE -TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 									AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN -TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE -TableTypesOfStocks_.AmountExcludingVATMan
	|	END 									AS CostMan,
	|	0 										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransaction) AS BusinessOperation,
	|	CASE
	|		WHEN &DepositForPackageIsRequired
	|		THEN &IDARAPObject
	|		ELSE TableTypesOfStocks_.RowID
	|	END AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.TransferredPackageReverseTransaction) AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.ReversingEntry) AS EntryType
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|	AND TableTypesOfStocks_.SalePeriod >= &BeginningOfMonthOfPeriod
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND TableTypesOfStocks_.TransferredMultiTurnPackaging
	//Conditions for no return to another warehouse (BT of a non-returned return card to another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|	AND TableTypesOfStocks_.OriginWarehouse = TableTypesOfStocks_.ReturnWarehouse
	|	AND TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|	AND TableTypesOfStocks_.InventoryOwnerAttributeShipment = TableTypesOfStocks_.InventoryOwnerAttribute
	|	AND (TableTypesOfStocks_.Purpose = TableTypesOfStocks_.PurposeOfShipment
	|				OR NOT &KeepRecordsOfInventoryCostByAssignments)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion
	
	#Region Moving_Goods_Commission
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.AnalysisOfTransmittedProducts	AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.InventoryOwnerAttributeShipment
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 												AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			 	AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	CASE WHEN TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|		THEN TableTypesOfStocks_.LogInAnalytics
	|		ELSE TableTypesOfStocks_.DimensionReturnPolicy
	|	END 												AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.Manager				AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	AND NOT TableTypesOfStocks_.TransferredMultiTurnPackaging
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.VHFWarehouses				= True;
	
	Return JobPrintingRules;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("View", Metadata.Documents.ReturnOfGoodsFromCustomer) Then
		// Refund from the customer
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ReturnFromCustomer";
		PrintCommand.Presentation = NStr("vi = 'Nhận hàng bán bị trả lại';
										|ru = 'Возврат от клиента';
										|en = 'Return from customer'; fa = 'برگشت از مشتری';
										|it = 'Reso dal cliente';
										|pl = 'Zwrot od klienta';
										|tr = 'Müşteriden iade'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Nhận hàng bán bị trả lại';
												|ru = 'Возврат от клиента';
												|en = 'Return from customer'; fa = 'برگشت از مشتری';
												|it = 'Reso dal cliente';
												|pl = 'Zwrot od klienta';
												|tr = 'Müşteriden iade'");
	EndIf;
	
	If Not UserRightsCached.ThisIsPartner() And Constants.UseInternationalPrintingForms.Get() Then
		
		VisibilityCondition = New Structure;
		VisibilityCondition.Insert("Attribute", Metadata.Documents.ReturnOfGoodsFromCustomer.Attributes.BusinessOperation.Name);
		VisibilityCondition.Insert("ComparisonType", ComparisonType.NotEqual);
		VisibilityCondition.Insert("Value", Enums.BusinessTransactions.ReturnFromRetailCustomer);
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CreditNote";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Credit Note';
										|ru = 'Credit Note';
										|en = 'Credit Note'; fa = 'Credit Note';
										|it = 'Credit Note';
										|pl = 'Credit Note';
										|tr = 'Credit Note'");
		PrintCommand.CheckPostingBeforePrint = True; 
		PrintCommand.Order = 3;
		PrintCommand.VisibilityConditions.Add(VisibilityCondition);
		
	EndIf;
	
	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	
	// Application for the return of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintApplicationForReturnOfGoodsFromCustomer";
	PrintCommand.Id = "ApplicationForReturnOfGoodsFromClient";
	PrintCommand.Presentation = NStr("vi = 'Giấy đề nghị trả hàng';
									|ru = 'Заявление на возврат товаров';
									|en = 'Goods return request'; fa = 'درخواست مرجوعی کالا';
									|it = 'Domanda di reso delle merci';
									|pl = 'Oświadczenie zwrotu towarów';
									|tr = 'Mal iadesi için başvuru'");
	PrintCommand.CheckPostingBeforePrint = True;

	ReturnOfGoodsFromCustomerLocalization.AddPrintCommands(PrintCommands);

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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReturnFromCustomer") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ReturnFromCustomer", NStr("vi = 'Nhận hàng bán bị trả lại';
																												|ru = 'Возврат от клиента';
																												|en = 'Return from customer'; fa = 'برگشت از مشتری';
																												|it = 'Reso dal cliente';
																												|pl = 'Zwrot od klienta';
																												|tr = 'Müşteriden iade'"), GeneratePrintedReturnFormFromCustomer(ObjectsArray, PrintObjects));
	EndIf;
	
	ReturnOfGoodsFromCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

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
	
EndProcedure

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

Function GeneratePrintedReturnFormFromCustomer(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query("SELECT
	                      |	ReturnOfGoodsFromCustomer.Ref AS Ref,
	                      |	ReturnOfGoodsFromCustomer.Number AS Number,
	                      |	ReturnOfGoodsFromCustomer.Date AS Date,
	                      |	ReturnOfGoodsFromCustomer.Partner AS Partner,
	                      |	ReturnOfGoodsFromCustomer.Counterparty AS Recipient,
	                      |	ReturnOfGoodsFromCustomer.Organization AS Organization,
	                      |	ReturnOfGoodsFromCustomer.Organization.Prefix AS Prefix,
	                      |	ReturnOfGoodsFromCustomer.Currency AS Currency,
	                      |	ReturnOfGoodsFromCustomer.PriceIncludesVAT AS PriceIncludesVAT,
	                      |	ReturnOfGoodsFromCustomer.BusinessOperation AS BusinessOperation,
	                      |	CASE
	                      |		WHEN ReturnOfGoodsFromCustomer.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	                      |			THEN TRUE
	                      |		ELSE FALSE
	                      |	END AS ConsiderVAT,
	                      |	ReturnOfGoodsFromCustomer.Warehouse.CurrentEmployeeInChargeTypes AS GettingProduced
	                      |FROM
	                      |	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	                      |WHERE
	                      |	ReturnOfGoodsFromCustomer.Ref IN(&DocumentsArray)
	                      |	AND ReturnOfGoodsFromCustomer.Posted
	                      |
	                      |ORDER BY
	                      |	Ref
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Table.Ref AS Ref,
	                      |	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	                      |	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	                      |	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	                      |	Table.ProductsInSet AS ProductsInSet,
	                      |	Table.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	CASE
	                      |		WHEN Table.Damage
	                      |			THEN Table.ProductsRecordingAsReceived
	                      |		ELSE Table.Products
	                      |	END AS Products,
	                      |	CASE
	                      |		WHEN Table.Damage
	                      |			THEN Table.CharacteristicRecordingAsReceived
	                      |		ELSE Table.Characteristic
	                      |	END AS Characteristic,
	                      |	Table.Package AS Package,
	                      |	Table.VATRate AS VATRate,
	                      |	Table.Price AS Price,
	                      |	Table.NumberOfPackages AS NumberOfPackages,
	                      |	Table.Count AS Count,
	                      |	Table.Sum AS Sum,
	                      |	Table.VATAmount AS VATAmount,
	                      |	Table.LineNumber AS LineNumber,
	                      |	CASE
	                      |		WHEN Table.Ref.ReusablePackageReturn
	                      |				AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	                      |			THEN TRUE
	                      |		ELSE FALSE
	                      |	END AS ThisIsReusablePackage
	                      |INTO Goods
	                      |FROM
	                      |	Document.ReturnOfGoodsFromCustomer.Goods AS Table
	                      |		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	                      |		ON (ProductKitConfigurations.Owner = Table.ProductsInSet)
	                      |			AND (ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet)
	                      |			AND (ProductKitConfigurations.Main)
	                      |WHERE
	                      |	Table.Ref IN(&DocumentsArray)
	                      |	AND Table.Ref.Posted
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT DISTINCT
	                      |	TableOfGoods.Ref AS Ref
	                      |INTO VariousGoods_
	                      |FROM
	                      |	Goods AS TableOfGoods
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Table.Ref AS Ref,
	                      |	Table.ProductsInSet AS ProductsInSet,
	                      |	Table.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	MIN(Table.LineNumber) AS LineNumber,
	                      |	SUM(Table.Sum) AS Sum,
	                      |	SUM(Table.VATAmount) AS VATAmount
	                      |INTO TemporaryTableSetsPreparation
	                      |FROM
	                      |	Goods AS Table
	                      |WHERE
	                      |	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	                      |
	                      |GROUP BY
	                      |	Table.Ref,
	                      |	Table.ProductsInSet,
	                      |	Table.ItemVariantOfSet
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Goods.Ref AS Ref,
	                      |	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	                      |	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	                      |	Goods.SetPricingOption AS SetPricingOption,
	                      |	Goods.ProductsInSet AS ProductsInSet,
	                      |	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	Goods.Products AS Products,
	                      |	Goods.Characteristic AS Characteristic,
	                      |	CASE
	                      |		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	                      |				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	                      |			THEN TRUE
	                      |		ELSE FALSE
	                      |	END AS MainComponent,
	                      |	Goods.VATRate AS VATRate,
	                      |	0 AS DefaultQuantity,
	                      |	Goods.Count AS Count
	                      |INTO TemporaryTableSetsOptionalPartOne
	                      |FROM
	                      |	Goods AS Goods
	                      |WHERE
	                      |	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	VariousGoods_.Ref,
	                      |	ConfigurationOptionsForProductRange.Ref,
	                      |	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	                      |	ConfigurationOptionsForProductRange.Ref.SetPricingOption,
	                      |	ConfigurationOptionsForProductRange.Ref.Owner,
	                      |	ConfigurationOptionsForProductRange.Ref.Characteristic,
	                      |	ConfigurationOptionsForProductRange.Products,
	                      |	ConfigurationOptionsForProductRange.Characteristic,
	                      |	FALSE,
	                      |	NULL,
	                      |	SUM(ConfigurationOptionsForProductRange.Count),
	                      |	0
	                      |FROM
	                      |	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	                      |		LEFT JOIN VariousGoods_ AS VariousGoods_
	                      |		ON (TRUE)
	                      |WHERE
	                      |	ConfigurationOptionsForProductRange.Ref IN
	                      |			(SELECT DISTINCT
	                      |				T.ItemKitConfiguration
	                      |			FROM
	                      |				Goods AS T)
	                      |
	                      |GROUP BY
	                      |	VariousGoods_.Ref,
	                      |	ConfigurationOptionsForProductRange.Ref,
	                      |	ConfigurationOptionsForProductRange.Ref.Owner,
	                      |	ConfigurationOptionsForProductRange.Ref.Characteristic,
	                      |	ConfigurationOptionsForProductRange.Products,
	                      |	ConfigurationOptionsForProductRange.Characteristic,
	                      |	ConfigurationOptionsForProductRange.Package,
	                      |	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	                      |	ConfigurationOptionsForProductRange.Ref.SetPricingOption
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Table.Ref AS Ref,
	                      |	Table.ItemKitConfiguration AS ItemKitConfiguration,
	                      |	Table.SetPricingOption AS SetPricingOption,
	                      |	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	                      |	Table.ProductsInSet AS ProductsInSet,
	                      |	Table.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	Table.Products AS Products,
	                      |	Table.Characteristic AS Characteristic,
	                      |	MAX(Table.VATRate) AS VATRate,
	                      |	MAX(Table.MainComponent) AS MainComponent,
	                      |	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	                      |	SUM(Table.Count) AS Count
	                      |INTO TemporaryTableSetsOptionalPartTwo
	                      |FROM
	                      |	TemporaryTableSetsOptionalPartOne AS Table
	                      |
	                      |GROUP BY
	                      |	Table.Ref,
	                      |	Table.ItemKitConfiguration,
	                      |	Table.SetPricingOption,
	                      |	Table.PresentationOptionInPrintForms,
	                      |	Table.ProductsInSet,
	                      |	Table.ItemVariantOfSet,
	                      |	Table.Products,
	                      |	Table.Characteristic
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Result.Ref AS Ref,
	                      |	Result.ItemKitConfiguration AS ItemKitConfiguration,
	                      |	Result.SetPricingOption AS SetPricingOption,
	                      |	Result.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	                      |	Result.ProductsInSet AS ProductsInSet,
	                      |	Result.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	MAX(CASE
	                      |			WHEN Result.MainComponent
	                      |				THEN Result.VATRate
	                      |			ELSE NULL
	                      |		END) AS VATRate,
	                      |	(CAST(MIN(CASE
	                      |				WHEN Result.DefaultQuantity <> 0
	                      |						AND Result.MainComponent
	                      |					THEN Result.Count / Result.DefaultQuantity
	                      |				ELSE NULL
	                      |			END) + 0.5 AS NUMBER(10, 0))) - 1 AS Count
	                      |INTO TemporaryTableSetsOptional
	                      |FROM
	                      |	TemporaryTableSetsOptionalPartTwo AS Result
	                      |
	                      |GROUP BY
	                      |	Result.Ref,
	                      |	Result.ItemKitConfiguration,
	                      |	Result.SetPricingOption,
	                      |	Result.PresentationOptionInPrintForms,
	                      |	Result.ProductsInSet,
	                      |	Result.ItemVariantOfSet
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	TemporaryTableSetsOptional.ItemKitConfiguration AS ItemKitConfiguration,
	                      |	CASE
	                      |		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	                      |			THEN CASE
	                      |					WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = 
						  |							VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	                      |						THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	                      |					ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	                      |				END
	                      |		ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	                      |	END AS PresentationOptionInPrintForms,
	                      |	CASE
	                      |		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	                      |			THEN CASE
	                      |					WHEN CASE
	                      |								WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = 
						  |										VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	                      |									THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	                      |								ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	                      |							END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	                      |							AND TemporaryTableSetsOptional.SetPricingOption IN 
						  |								(VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices), 
						  |									VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	                      |						THEN VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	                      |					ELSE TemporaryTableSetsOptional.SetPricingOption
	                      |				END
	                      |		ELSE TemporaryTableSetsOptional.SetPricingOption
	                      |	END AS SetPricingOption,
	                      |	Table.Ref AS Ref,
	                      |	Table.ProductsInSet AS ProductsInSet,
	                      |	Table.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	Table.LineNumber AS LineNumber,
	                      |	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	                      |	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	                      |	Table.Sum AS Sum,
	                      |	Table.VATAmount AS VATAmount,
	                      |	TemporaryTableSetsOptional.VATRate AS VATRate
	                      |INTO TemporaryTableSets
	                      |FROM
	                      |	TemporaryTableSetsPreparation AS Table
	                      |		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	                      |		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	                      |			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Table.Ref AS Ref,
	                      |	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	                      |	Table.SetPricingOption AS SetPricingOption,
	                      |	Table.ProductsInSet AS ProductsInSet,
	                      |	Table.ItemVariantOfSet AS ItemVariantOfSet,
	                      |	Table.TheseAreComponents AS TheseAreComponents,
	                      |	Table.IsRecordsSet AS IsRecordsSet,
	                      |	Table.Products AS Products,
	                      |	Table.Products.DescriptionFull AS ProductNameFull_,
	                      |	Table.Products.Code AS Code,
	                      |	Table.Products.SKU AS SKU,
	                      |	CASE
	                      |		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	                      |			THEN 1
	                      |		ELSE &QueryTextPackagingFactor
	                      |	END AS ZoomRatio,
	                      |	CASE
	                      |		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	                      |			THEN Table.Products.UnitOfMeasure
	                      |		ELSE Table.Package
	                      |	END AS UnitOfMeasure,
	                      |	CASE
	                      |		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	                      |			THEN Table.Products.UnitOfMeasure.Description
	                      |		ELSE Table.Package.Description
	                      |	END AS UnitPrice,
	                      |	Table.Characteristic.DescriptionFull AS Characteristic,
	                      |	CASE
	                      |		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	                      |			THEN UNDEFINED
	                      |		ELSE Table.Package.Description
	                      |	END AS Package,
	                      |	Table.VATRate AS VATRate,
	                      |	Table.Price AS Price,
	                      |	Table.NumberOfPackages AS Count,
	                      |	Table.Sum AS Sum,
	                      |	Table.VATAmount AS VATAmount,
	                      |	Table.LineNumber AS LineNumber,
	                      |	Table.ThisIsReusablePackage AS ThisIsReusablePackage
	                      |FROM
	                      |	(SELECT
	                      |		Table.Ref AS Ref,
	                      |		CASE
	                      |			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	                      |				THEN TemporaryTableSets.PresentationOptionInPrintForms
	                      |			ELSE VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	                      |		END AS PresentationOptionInPrintForms,
	                      |		CASE
	                      |			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	                      |				THEN TemporaryTableSets.SetPricingOption
	                      |			ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	                      |		END AS SetPricingOption,
	                      |		Table.ProductsInSet AS ProductsInSet,
	                      |		Table.ItemVariantOfSet AS ItemVariantOfSet,
	                      |		CASE
	                      |			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	                      |				THEN TRUE
	                      |			ELSE FALSE
	                      |		END AS TheseAreComponents,
	                      |		FALSE AS IsRecordsSet,
	                      |		CASE
	                      |			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	                      |				THEN TemporaryTableSets.LineNumber
	                      |			ELSE Table.LineNumber
	                      |		END AS LineNumber,
	                      |		Table.Products AS Products,
	                      |		Table.Count AS Count,
	                      |		Table.NumberOfPackages AS NumberOfPackages,
	                      |		Table.Price AS Price,
	                      |		Table.Sum AS Sum,
	                      |		Table.VATAmount AS VATAmount,
	                      |		Table.VATRate AS VATRate,
	                      |		Table.Characteristic AS Characteristic,
	                      |		Table.Package AS Package,
	                      |		Table.ThisIsReusablePackage AS ThisIsReusablePackage
	                      |	FROM
	                      |		Goods AS Table
	                      |			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	                      |			ON (TemporaryTableSets.ProductsInSet = Table.ProductsInSet)
	                      |				AND (TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet)
	                      |				AND (TemporaryTableSets.Ref = Table.Ref)
	                      |	WHERE
	                      |		(Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	                      |				OR Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	                      |					AND TemporaryTableSets.PresentationOptionInPrintForms IN 
						  |						(VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents), 
						  |							VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	                      |	
	                      |	UNION ALL
	                      |	
	                      |	SELECT
	                      |		TemporaryTableSets.Ref,
	                      |		TemporaryTableSets.PresentationOptionInPrintForms,
	                      |		TemporaryTableSets.SetPricingOption,
	                      |		TemporaryTableSets.ProductsInSet,
	                      |		TemporaryTableSets.ItemVariantOfSet,
	                      |		FALSE,
	                      |		TRUE,
	                      |		TemporaryTableSets.LineNumber,
	                      |		TemporaryTableSets.ProductsInSet,
	                      |		TemporaryTableSets.Count,
	                      |		TemporaryTableSets.NumberOfPackages,
	                      |		CASE
	                      |			WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	                      |				THEN TemporaryTableSets.Sum / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	                      |			ELSE 0
	                      |		END,
	                      |		TemporaryTableSets.Sum,
	                      |		TemporaryTableSets.VATAmount,
	                      |		TemporaryTableSets.VATRate,
	                      |		TemporaryTableSets.ItemVariantOfSet,
	                      |		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	                      |		FALSE
	                      |	FROM
	                      |		TemporaryTableSets AS TemporaryTableSets
	                      |	WHERE
	                      |		TemporaryTableSets.PresentationOptionInPrintForms IN 
						  |			(VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet), 
						  |				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS Table
	                      |
	                      |ORDER BY
	                      |	Table.Ref,
	                      |	IsRecordsSet DESC");
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Table.Package",
		"Table.Products"));
		
	Query.SetParameter("DocumentsArray", ObjectsArray);
		
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReturnOfGoodsFromCustomer_Invoice";
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	ResultsArray   = Query.ExecuteBatch();
	PrintData        = ResultsArray[0].Select();
	Goods              = ResultsArray[ResultsArray.Count() - 1].Unload();
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.ReturnOfGoodsFromCustomer.PF_MXL_ReturnFromCustomer");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			
			ProductColumnArea = Template.Area("OwnGoods");
			If Not OutputCodes Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
			EndIf;
			
		Else
			
			ProductColumnArea = Template.Area("ProductWithoutAmounts");
			If Not OutputCodes Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.125;
			EndIf;
			
		EndIf;
		
		TemplateArea = Template.GetArea("Title");
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData, 
			NStr("vi = 'Nhận hàng bán bị trả lại';
				|ru = 'Возврат от клиента';
				|en = 'Return from customer'; fa = 'برگشت از مشتری';
				|it = 'Reso dal cliente';
				|pl = 'Zwrot od klienta';
				|tr = 'Müşteriden iade'", Common.DefaultLanguageCode())));
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Organization);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Recipient);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			
			RoomArea     = Template.GetArea("TableHeader|LineNumber");
			AreaCodes      = Template.GetArea("TableHeader|ColumnOfCodes");
			ProductArea      = Template.GetArea("TableHeader|OwnGoods");
			DataArea     = Template.GetArea("TableHeader|Data");
			
		Else
			
			RoomArea     = Template.GetArea("HeaderOfTableWithoutAmounts|LineNumberWithoutSums");
			AreaCodes      = Template.GetArea("HeaderOfTableWithoutAmounts|ColumnOfCodesWithoutSums");
			ProductArea      = Template.GetArea("HeaderOfTableWithoutAmounts|ProductWithoutAmounts");
			DataArea     = Template.GetArea("HeaderOfTableWithoutAmounts|DataWithoutAmounts");
			
		EndIf;
			
		SpreadsheetDocument.Put(RoomArea);
			
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
			
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			AreaName              = "TableRow";
			AreaNameSet         = "TableRowSet";
			AreaNameComponents = "TableRowComponents";
		Else
			AreaName              = "TableRowWithoutSums";
			AreaNameSet         = "TableRowWithoutSumsSet";
			AreaNameComponents = "TableRowWithoutSumsComponents";
		EndIf;
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			
			StandardRoomArea  = Template.GetArea(AreaName+"|LineNumber");
			AreaCodesStandard   = Template.GetArea(AreaName+"|ColumnOfCodes");
			ScopeOfApplicationStandard_   = Template.GetArea(AreaName+"|OwnGoods");
			DataAreaStandard  = Template.GetArea(AreaName+"|Data");
			
		Else
			
			StandardRoomArea  = Template.GetArea(AreaName+"|LineNumberWithoutSums");
			AreaCodesStandard   = Template.GetArea(AreaName+"|ColumnOfCodesWithoutSums");
			ScopeOfApplicationStandard_   = Template.GetArea(AreaName+"|ProductWithoutAmounts");
			DataAreaStandard  = Template.GetArea(AreaName+"|DataWithoutAmounts");
			
		EndIf;
		
		UseSets = False;
		If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
						
				RoomAreaSet = Template.GetArea(AreaNameSet+"|LineNumber");
				AreaCodesSet  = Template.GetArea(AreaNameSet+"|ColumnOfCodes");
				ProductAreaSet  = Template.GetArea(AreaNameSet+"|OwnGoods");
				DataAreaSet = Template.GetArea(AreaNameSet+"|Data");
				
				RoomAreaComponents = Template.GetArea(AreaNameComponents+"|LineNumber");
				AreaCodesComponents  = Template.GetArea(AreaNameComponents+"|ColumnOfCodes");
				ProductAreaComponents  = Template.GetArea(AreaNameComponents+"|OwnGoods");
				DataAreaComponents = Template.GetArea(AreaNameComponents+"|Data");
				
			Else
				
				RoomAreaSet = Template.GetArea(AreaNameSet+"|LineNumberWithoutSums");
				AreaCodesSet  = Template.GetArea(AreaNameSet+"|ColumnOfCodesWithoutSums");
				ProductAreaSet  = Template.GetArea(AreaNameSet+"|ProductWithoutAmounts");
				DataAreaSet = Template.GetArea(AreaNameSet+"|DataWithoutAmounts");
				
				RoomAreaComponents = Template.GetArea(AreaNameComponents+"|LineNumberWithoutSums");
				AreaCodesComponents  = Template.GetArea(AreaNameComponents+"|ColumnOfCodesWithoutSums");
				ProductAreaComponents  = Template.GetArea(AreaNameComponents+"|ProductWithoutAmounts");
				DataAreaComponents = Template.GetArea(AreaNameComponents+"|DataWithoutAmounts");
				
			EndIf;
			
		EndIf;
		
		BlankData = SetsServer.BlankData();
		
		Sum          = 0;
		VATAmount       = 0;
		LineNumber    = 0;
		
		For Each ProductSelection_1 In GoodsTable Do
			
			If SetsServer.UseSetArea(ProductSelection_1, UseSets) Then
				RoomArea = RoomAreaSet;
				AreaCodes  = AreaCodesSet;
				ProductArea  = ProductAreaSet;
				DataArea = DataAreaSet;
			ElsIf SetsServer.UseScope(ProductSelection_1, UseSets) Then
				RoomArea = RoomAreaComponents;
				AreaCodes  = AreaCodesComponents;
				ProductArea  = ProductAreaComponents;
				DataArea = DataAreaComponents;
			Else
				RoomArea = StandardRoomArea;
				AreaCodes  = AreaCodesStandard;
				ProductArea  = ScopeOfApplicationStandard_;
				DataArea = DataAreaStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				SetParameter(RoomArea, "LineNumber", Undefined);
			Else
				LineNumber = LineNumber + 1;
				SetParameter(RoomArea, "LineNumber", LineNumber);
			EndIf;
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(ProductSelection_1, UseSets);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint) + PrefixAndPostfix.Postfix;
				
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			ProductArea.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductArea);

			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				DataArea.Parameters.Fill(BlankData);
			Else
				DataArea.Parameters.Fill(ProductSelection_1);
			EndIf;
			SpreadsheetDocument.Join(DataArea);
			
			If Not SetsServer.UseScope(ProductSelection_1, UseSets) Then
				If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
					
					Sum    = Sum    + ProductSelection_1.Sum;
					VATAmount = VATAmount + ProductSelection_1.VATAmount;
					
				EndIf;
			EndIf;
			
		EndDo;
		
		// We output the basement
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
			RoomArea = Template.GetArea("TableFooter|LineNumber");
			AreaCodes  = Template.GetArea("TableFooter|ColumnOfCodes");
			ProductArea  = Template.GetArea("TableFooter|OwnGoods");
			DataArea = Template.GetArea("TableFooter|Data");
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			
			TotalDataStructure = New Structure;
			TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
			DataArea.Parameters.Fill(TotalDataStructure);
			SpreadsheetDocument.Join(DataArea);
			
		EndIf;
		
		// We output the total of the ADS
		
		If PrintData.ConsiderVAT And PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
			
			RoomArea = Template.GetArea("VATTableBasement|LineNumber");
			AreaCodes  = Template.GetArea("VATTableBasement|ColumnOfCodes");
			ProductArea  = Template.GetArea("VATTableBasement|OwnGoods");
			DataArea = Template.GetArea("VATTableBasement|Data");
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			
			VATDataStructure = New Structure;
			VATDataStructure.Insert("VAT", ?(PrintData.PriceIncludesVAT,
													NStr("vi = 'Trong đó thuế GTGT:';
														|ru = 'В том числе НДС:';
														|en = 'Including VAT:'; fa = 'Including VAT:';
														|it = 'IVA compresa:';
														|pl = 'W tym VAT';
														|tr = 'KDV dahil:'", Common.DefaultLanguageCode()),
													NStr("vi = 'Thuế GTGT:';
														|ru = 'Сумма НДС:';
														|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
														|it = 'Importo IVA:';
														|pl = 'Wartość VAT';
														|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			VATDataStructure.Insert("TotalVAT", PrintFormGeneration.SumFormat(VATAmount));
			DataArea.Parameters.Fill(VATDataStructure);
			SpreadsheetDocument.Join(DataArea);
			
		EndIf;
		
		If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
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
				LineNumber,
				PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
			
			DataStructureSummaryRow = New Structure;
			DataStructureSummaryRow.Insert("TotalString", TotalString);
			DataStructureSummaryRow.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
			TemplateArea.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			
			TemplateArea = Template.GetArea("BasementTablesWithoutSums");
			TotalString = NStr("vi = 'Số lượng các dòng là: %NumberOfTitles%';
								|ru = 'Всего наименований %NumberOfTitles%';
								|en = 'Total items %NumberOfTitles%'; fa = 'Total items %NumberOfTitles%';
								|it = 'Totale articoli %NumberOfTitles%';
								|pl = 'Łącznie nazw %NumberOfTitles%';
								|tr = 'Toplam tanım %NumberOfTitles%'", Common.DefaultLanguageCode());
			TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
			DataStructureSummaryRow = New Structure("TotalString", TotalString);
			TemplateArea.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf;
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.GettingProduced) Then
			DataStructureGettingProduced =
				New Structure("GettingProduced", PersonsTM.IndividualShortName(PrintData.GettingProduced, PrintData.Date));
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

// Returns the data required for the printed form "application for return of torov from the client".
// 
// Parameters:
// 	ObjectsArray - Array - references to objects that should be printed
//
// Returns:
// 	Structure - Contains data on the header of the document and the tabular part:
// 	* HeaderResults - QueryResult - 
// 	* ResultForTabularPart - QueryResult -
// 
Function GetDataForPrintedReturnApplicationFormFromCustomer(ObjectsArray) Export
		
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Ref AS Ref,
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.AmountIncludingVAT AS Sum,
	|	CASE
	|		WHEN Table.Ref.ReusablePackageReturn
	|				AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReusablePackage
	|INTO Goods
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS Table
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON (ProductKitConfigurations.Owner = Table.ProductsInSet)
	|			AND (ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet)
	|			AND (ProductKitConfigurations.Main)
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	MIN(Table.LineNumber) AS LineNumber,
	|	SUM(Table.Sum) AS Sum
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	FALSE,
	|	SUM(ConfigurationOptionsForProductRange.Count),
	|	0
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON (TRUE)
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN
	|			(SELECT DISTINCT
	|				T.ItemKitConfiguration
	|			FROM
	|				Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.ItemKitConfiguration AS ItemKitConfiguration,
	|	Table.SetPricingOption AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref AS Ref,
	|	Result.ItemKitConfiguration AS ItemKitConfiguration,
	|	Result.SetPricingOption AS SetPricingOption,
	|	Result.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Result.ProductsInSet AS ProductsInSet,
	|	Result.ItemVariantOfSet AS ItemVariantOfSet,
	|	(CAST(MIN(CASE
	|				WHEN Result.DefaultQuantity <> 0
	|						AND Result.MainComponent
	|					THEN Result.Count / Result.DefaultQuantity
	|				ELSE NULL
	|			END) + 0.5 AS NUMBER(10, 0))) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ItemKitConfiguration,
	|	CASE
	|		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN CASE
	|					WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = 
	|							VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|						THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|					ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|				END
	|		ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	CASE
	|		WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN CASE
	|					WHEN CASE
	|								WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = 
	|										VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|									THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|								ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|							END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|							AND TemporaryTableSetsOptional.SetPricingOption IN 
	|								(VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices), 
	|									VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|						THEN VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|					ELSE TemporaryTableSetsOptional.SetPricingOption
	|				END
	|		ELSE TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|	Table.Ref AS Ref,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum AS Sum
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|			AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReturnOfGoodsFromCustomer.Ref AS Ref,
	|	ReturnOfGoodsFromCustomer.Date AS Date,
	|	ReturnOfGoodsFromCustomer.DocumentAmount AS Sum,
	|	ReturnOfGoodsFromCustomer.Currency AS Currency,
	|	ReturnOfGoodsFromCustomer.Organization AS Organization,
	|	ReturnOfGoodsFromCustomer.ReasonForReturn AS ReasonForReturn,
	|	ReturnOfGoodsFromCustomer.Customer AS Customer,
	|	ReturnOfGoodsFromCustomer.CashRegisterReceipt.Number AS CashRegisterReceiptNumber,
	|	ReturnOfGoodsFromCustomer.CashRegisterReceipt.Date AS CashRegisterReceiptDate,
	|	ReturnOfGoodsFromCustomer.CustomerSDateOfBirth AS BirthDate,
	|	ReturnOfGoodsFromCustomer.CustomerDocumentKind AS DocumentKind,
	|	ReturnOfGoodsFromCustomer.CustomerDocumentSeries AS Series,
	|	ReturnOfGoodsFromCustomer.CustomerDocumentNumber AS Number,
	|	ReturnOfGoodsFromCustomer.DateOfCustomerDocumentIssue AS DateOfIssue1,
	|	ReturnOfGoodsFromCustomer.CustomerDocumentValidityPeriod AS ValidityPeriod,
	|	ReturnOfGoodsFromCustomer.IssuingAuthorityOfCustomerDocument AS IssuedBy,
	|	ReturnOfGoodsFromCustomer.CustomerDocumentBusinessUnitCode AS BusinessUnitCode
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products.DescriptionFull AS FullNameOfProduct_,
	|	Goods.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package
	|	END AS PackageName,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(Goods.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(Goods.Package)
	|	END AS UnitOfMeasure,
	|	Goods.NumberOfPackages AS Count,
	|	Goods.Sum AS Sum,
	|	Goods.ThisIsReusablePackage AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		Table.Ref AS Ref,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.PresentationOptionInPrintForms
	|			ELSE VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.SetPricingOption
	|			ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products AS Products,
	|		Table.Count AS Count,
	|		Table.NumberOfPackages AS NumberOfPackages,
	|		Table.Sum AS Sum,
	|		Table.Characteristic AS Characteristic,
	|		Table.Package AS Package,
	|		Table.ThisIsReusablePackage AS ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON (TemporaryTableSets.ProductsInSet = Table.ProductsInSet)
	|				AND (TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet)
	|				AND (TemporaryTableSets.Ref = Table.Ref)
	|	WHERE
	|		(Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|				OR Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|					AND TemporaryTableSets.PresentationOptionInPrintForms IN 
	|						(VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents), 
	|							VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE,
	|		TRUE,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		TemporaryTableSets.Sum,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN 
	|			(VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet), 
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS Goods
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.SetParameter("ObjectsArray", ObjectsArray);
	SetPrivilegedMode(True);
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[7]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

// Returns the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting
// (placing) products.
//
// Returns:
//	String - the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting (placing) goods.
//
Function TextOfGoodsRequestDocumentForPrintingTaskForSelectingPlacingGoods() Export
	
	RequestText_1 =
	"SELECT
	|	DocumentGoods.Ref					AS Ref,
	|	MIN(DocumentGoods.LineNumber)	AS LineNumber,
	|	DocumentGoods.Warehouse					AS Warehouse,
	|	&Premise								AS Premise,
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.ProductsRecordingAsReceived
	|		ELSE DocumentGoods.Products
	|	END									AS Products,
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.CharacteristicRecordingAsReceived
	|		ELSE DocumentGoods.Characteristic
	|	END									AS Characteristic,
	|	DocumentGoods.Series					AS Series
	|INTO DocumentGoods
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS DocumentGoods
	|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS DocumentData
	|		ON DocumentGoods.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	DocumentGoods.Ref,
	|	DocumentGoods.Warehouse,
	|	&Premise,
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.ProductsRecordingAsReceived
	|		ELSE DocumentGoods.Products
	|	END,
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.CharacteristicRecordingAsReceived
	|		ELSE DocumentGoods.Characteristic
	|	END,
	|	DocumentGoods.Series";
	
	RequestText_1 = StrReplace(RequestText_1, "&Premise", "VALUE(Catalog.Warerooms.EmptyRef)");
	
	Return RequestText_1;
	
EndFunction

Function PrintDataDebitCreditNote(PrintParameters, ObjectsArray, DebitCreditNote, LanguageCode) Export
	
	Query = New Query;
	Query.Text =
	"SELECT 
	|	ISNULL(CustomerInvoice.Ref, VALUE(Document.CustomerInvoice.EmptyRef)) AS Ref
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON (ReturnOfGoodsFromCustomer.DocumentSalesOfGoodsAndServices = CustomerInvoice.Ref)
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref IN (&ObjectsArray)";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	ArrayOfImplementations = Query.Execute().Unload().UnloadColumn("Ref");
	
	If ArrayOfImplementations.Count() = 0 Then
		
		ArrayOfImplementations.Add(Documents.CustomerInvoice.EmptyRef());
		
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ArrayOfImplementations, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT 
	|	ReturnOfGoodsFromCustomer.Ref AS Ref,
	|	CustomerInvoice.CompanyBankAccount AS CompanyBankAccount,
	|	CustomerInvoice.CounterpartyBankAccount AS CounterpartyBankAccount
	|INTO TT_DetailsOfSalesDocument
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON (ReturnOfGoodsFromCustomer.DocumentSalesOfGoodsAndServices = CustomerInvoice.Ref)
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref IN (&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	Documents.DocumentSalesOfGoodsAndServices AS DocumentBasis,
	|	Documents.Organization AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	TT_DetailsOfSalesDocument.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.ForeignBank
	|		OR TT_DetailsOfSalesDocument.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR TT_DetailsOfSalesDocument.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	TT_DetailsOfSalesDocument.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	TT_DetailsOfSalesDocument.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(TT_DetailsOfSalesDocument.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(TT_DetailsOfSalesDocument.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE TT_DetailsOfSalesDocument.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN ISNULL(TT_DetailsOfSalesDocument.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.ManualBankDetailsChange
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN ISNULL(TT_DetailsOfSalesDocument.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.ManualBankDetailsChange
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN ISNULL(TT_DetailsOfSalesDocument.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.ManualBankDetailsChange
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.ManualBankDetailsChange
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN TT_DetailsOfSalesDocument.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	TT_DetailsOfSalesDocument.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS DocumentAmount
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN TT_DetailsOfSalesDocument AS TT_DetailsOfSalesDocument
	|		ON Documents.Ref = TT_DetailsOfSalesDocument.Ref
	|			LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|			ON TT_DetailsOfSalesDocument.CompanyBankAccount.Bank = BankClassifier.Ref
	|			LEFT JOIN Catalog.WorldCountries AS BankCountries
	|			ON BankClassifier.CountryCode = BankCountries.Code
	|			LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|			ON TT_DetailsOfSalesDocument.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|			LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|			ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	"""" AS Content,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN NOT &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN CASE WHEN Table.NumberOfPackages <> 0 THEN Table.Sum / Table.NumberOfPackages ELSE 0 END
	|		ELSE CASE WHEN Table.Count <> 0 THEN Table.Sum / Table.Count ELSE 0 END
	|	END AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount
	|
	|INTO Goods
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN (&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, ISNULL(Goods.Products.DescriptionFull, Goods.Content)) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription AS UnitOfMeasure,
	|	Goods.NumberOfPackages AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum AS Sum,
	|	Goods.VATRate AS VATRate,
	|	Goods.VATAmount AS VATAmount,
	|	UNDEFINED AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END AS Package,
	|	Goods.Content AS Content
	|		
	|FROM (
	|	SELECT
	|		Table.Ref AS Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products AS Products,
	|		Table.Count AS Count,
	|		Table.NumberOfPackages AS NumberOfPackages,
	|		Table.Price AS Price,
	|		Table.Sum AS Sum,
	|		Table.VATRate AS VATRate,
	|		Table.VATAmount AS VATAmount,
	|		Table.Characteristic AS Characteristic,
	|		Table.Package AS Package,
	|		"""" AS Content
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref AS Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet AS ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet AS ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber AS LineNumber,
	|		TemporaryTableSets.ProductsInSet AS Products,
	|		TemporaryTableSets.Count AS Count,
	|		TemporaryTableSets.NumberOfPackages AS NumberOfPackages,
	|		CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|				(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE
	|				0
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ProductsInSet.VATRate AS VATRate,
	|		TemporaryTableSets.VATAmount AS VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet AS Characteristic,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		"""" AS Content
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Ref AS Ref,
	|		VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef) AS PresentationOptionInPrintForms,
	|		VALUE(Enum.SetPriceCalculationOptions.EmptyRef) AS SetPricingOption,
	|		UNDEFINED AS ProductsInSet,
	|		UNDEFINED AS ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		Table.LineNumber AS LineNumber,
	|		UNDEFINED AS Products,
	|		0 AS Count,
	|		0 AS NumberOfPackages,
	|		0 AS Price,
	|		Table.AdjustmentSum AS Sum,
	|		Table.VATRate AS VATRate,
	|		Table.SumOfVATAdjustments AS VATAmount,
	|		UNDEFINED AS Characteristic,
	|		UNDEFINED AS Package,
	|		Table.ReasonForAdjustment AS Content
	|	FROM
	|		Document.SaleAdjustment.ARAPAdjustment AS Table
	|	WHERE
	|		Table.Ref IN(&ObjectsArray)
	|		
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Goods.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Goods.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	Query.SetParameter("DebitNote", DebitCreditNote = "DebitNote");
	Query.SetParameter("CreditNote", DebitCreditNote = "CreditNote");
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

#Region Other

Procedure SetParameterForPartnerAccountingAnalyticsRequest(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsViaCommissionAgent Then
		StructureOfAnalytics = New Structure();
		StructureOfAnalytics.Insert("Organization", Query.Parameters.Organization);
		StructureOfAnalytics.Insert("Contract", Query.Parameters.CustomerContract);
		StructureOfAnalytics.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		If Common.ObjectAttributeValue(Query.Parameters.Contract, "ConductARAPAccountingThroughEndCustomers") Then
			StructureOfAnalytics.Insert("Partner", Query.Parameters.CustomerPartner);
			StructureOfAnalytics.Insert("Counterparty", Query.Parameters.CustomerCounterparty);
		Else
			StructureOfAnalytics.Insert("Partner", Query.Parameters.Partner);
			StructureOfAnalytics.Insert("Counterparty", Query.Parameters.Counterparty);
		EndIf;
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureOfAnalytics);
	Else
		AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters);
	EndIf;
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	
EndProcedure

Procedure SetRequestParameterCorInventoryView(Query)
	
	If Query.Parameters.Property("CorInventoryOwnerAttribute") Then
		Return;
	EndIf;
	
	Query.SetParameter("CorInventoryOwnerAttribute",
		Catalogs.InventoryKinds.DocumentInventoryView(Query.Parameters.Organization, Query.Parameters.BusinessOperation,
			Undefined));
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&RequestForReturnOfGoodsFromCustomer AS ReferenceOrder,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS Sum
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.AcceptedOnReturns))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &RefundOnRequest
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&RequestForReturnOfGoodsFromCustomer AS ReferenceOrder,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.ProductsRecordingAsReceived
	|		ELSE GoodsTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN GoodsTable.CharacteristicRecordingAsReceived
	|		ELSE GoodsTable.Characteristic
	|	END AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS Sum
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RequestedForReturn),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &RefundOnRequest
	|	AND GoodsTable.RowCode = 0
	|	AND &UseAdvancedFeaturesOfSalesOrder
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	SeriesTable.Products         AS Products,
	|	SeriesTable.Characteristic       AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                             AS Purpose,
	|	SeriesTable.Series                AS Series,
	|	SeriesTable.Count           AS Count,
	|	&Partner                          AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfSender,
	|	SeriesTable.Warehouse                AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Ref                           AS Document,
	|	&Period                           AS Period,
	|	&Ref                           AS Recorder,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt AS ThisIsWarehouseRecord
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.ProductsRecordingAsReceived,
	|	SeriesTable.CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	&Partner,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	SeriesTable.Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Partner,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	GoodsTable.Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND GoodsTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.ProductsRecordingAsReceived,
	|	GoodsTable.CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Partner,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	GoodsTable.Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND GoodsTable.Count <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.ReturnOfGoodsFromCustomer.Name,
		"InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds"" 							AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	DocumentData.Partner						AS Vendor,
	|	DocumentData.Counterparty					AS Counterparty,
	|	DocumentTable.VATRate 					AS VATRate,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN DocumentData.ReusablePackageReturn
	|		 AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN DocumentTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE DocumentData.VATTaxation
	|	END AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.ReturnOfGoodsFromCustomer AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON DocumentTable.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DimensionOfProductItem.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks"; 
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAnalysisKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber                                             AS LineNumber,
	|	InventoryKinds.Ref                                                  AS Ref,
	|	
	|	CASE WHEN Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND &ReusablePackageReturn THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                                               AS TransferredMultiTurnPackaging,
	|	
	|	InventoryKinds.ItemsLocationAttributes                              AS DimensionReturnPolicy,
	|	KeysWithoutAssignment.DimensionKey                                    AS ReturnAnalyticsWithoutAssignment,
	|	KeysOfTransmittedProductList.DimensionKey                           AS AnalysisOfTransmittedProducts,
	|	KeysOfTransmittedProductList.DimensionKey                           AS AnalysisOfTransmittedProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributesShipment                      AS DimensionSalesOfGoodsAndServices,
	|	ISNULL(ShipmentKeysWithoutDestination.DimensionKey,
	|		KeysWithoutAssignment.DimensionKey)                               AS UnassignedImplementationAnalytics,
	|	ShippingKeysToCommittee.DimensionKey                                AS CommitteeImplementationAnalytics,
	|	CASE 
	|		WHEN &RefundViaCommissionAgent THEN KeysForRegisteringViaCommissionAgent.DimensionKey
	|		ELSE RegistrationKeys.DimensionKey
	|	END                                                               AS LogInAnalytics,
	|	Dimension.Products                                              AS Products,
	|	Dimension.Products.ItemsType                              AS ItemsType,
	|	Dimension.Characteristic                                            AS Characteristic,
	|	Dimension.Series                                                     AS Series,
	|	Dimension.Purpose                                                AS Purpose,
	|	CASE 
	|		WHEN &RefundViaCommissionAgent THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE Dimension.StorageLocation
	|	END																AS ReturnWarehouse,
	|	Dimension.WarehouseArea.ShopFloorStockroom                       AS ShopFloorStockroom,
	|	InventoryKinds.ProductsRecordingAsReceived                               AS ProductsRecordingAsReceived,
	|	InventoryKinds.CharacteristicRecordingAsReceived                             AS CharacteristicRecordingAsReceived,
	|	InventoryKinds.SetAccountingDimension.ProductsInSet                AS ProductsInSet,
	|	InventoryKinds.SetAccountingDimension.ItemVariantOfSet              AS ItemVariantOfSet,
	|	InventoryKinds.Count                                              AS Count,
	|	InventoryKinds.QuantityByGBRN                                        AS QuantityByGBRN,
	|	InventoryKinds.NumberOfPackages                                      AS NumberOfPackages,
	|	InventoryKinds.Package                                                AS Package,
	|	InventoryKinds.InventoryOwnerAttribute                                              AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType                                   AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory           AS InventoryOwnerAttributeSaleOfAnotherCompanySInventory,
	|	Catalog.SaleOfAnotherCompanyInventory                       AS SaleOfAnotherCompanyInventory,
	|	Catalog.InventoryOwnerAttributeOfCompanyGoodsOwner                                      AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	Catalog.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType                           AS OwnerSInventoryOwnersAttributeTypeOfInventory,
	|	Catalog.Currency                                                   AS Currency,
	|	DimensionShipments.Purpose                                        AS PurposeOfShipment,
	|	CASE 
	|		WHEN &RefundViaCommissionAgent THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE DimensionShipments.StorageLocation
	|	END AS OriginWarehouse,
	|	DimensionShipments.StorageLocation.ShopFloorStockroom                     AS ShopPantryShipment,
	|	InventoryKinds.InventoryOwnerAttributeShipment                                      AS InventoryOwnerAttributeShipment,
	|	InventoryKinds.InventoryOwnerAttributeShipment.InventoryType                           AS InventoryOwnerAttributeOfShipmentIsTypeOfInventory,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.DocumentSalesOfGoodsAndServices END)                     AS DocumentSalesOfGoodsAndServices,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN DATETIME(1,1,1)
	|		ELSE InventoryKinds.DocumentSalesOfGoodsAndServices.Date END)                AS SalePeriod,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN InventoryKinds.CostDefiningMethod
	|		ELSE VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument) END) AS CostDefiningMethod,
	|	InventoryKinds.CCDNumber                                                AS CCDNumber,
	|	InventoryKinds.CCDNumber.CCDNumberType                                   AS CCDNumberCCDNumberType,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass								AS AssetTaxClass,
	|	CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale) THEN
	|			CASE InventoryKinds.VATRate
	|			WHEN &ExportVATRate THEN 
	|				CASE WHEN InventoryKinds.ItemsLocationAttributes.Products.FEACNCode.Commodity
	|					THEN VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|					ELSE VALUE(Enum.VATTaxationTypes.ExportOfNonResourceGoods)
	|				END
	|			WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			ELSE
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			END
	|		ELSE TableOfBatchAccountingAnalysts.VATTaxation
	|	END																AS VATTaxation,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes 					AS LotVendorAttributes,
	|	(CASE
	|		WHEN &GenerateInventoryOwnerAttributesBySalesOpportunities AND &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &SalesOpportunity
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|		 AND &Manager <> VALUE(Catalog.Users.EmptyRef)
	|			THEN &Manager
	|		WHEN &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN &Department
	|		ELSE UNDEFINED
	|	END) AS FinancialAccountingDimension,
	|	CASE WHEN ISNULL(InventoryKinds.DocumentSalesOfGoodsAndServices.OrderSales, FALSE) THEN
	|		ISNULL(InventoryKinds.DocumentSalesOfGoodsAndServices.SalesOrder, UNDEFINED)
	|	ELSE
	|		UNDEFINED
	|	END AS OrderingImplementation,
	|
	|	ISNULL(
	|		InventoryKinds.DocumentSalesOfGoodsAndServices.Department,
	|		&Department
	|	) AS ImplementationDivision,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                     AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                   AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)                                      AS VATAmountMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                                  AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                    AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0)                                      AS VATBaseLocal,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                     AS VATAmountCompl,
	|	InventoryKinds.ExciseTaxAmount                                             AS ExciseTaxAmount,
	|	InventoryKinds.ExciseTaxAmount                                             AS ExciseAmountInCurrencyLocal,
	|	CAST(InventoryKinds.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|
	|	InventoryKinds.AmountIncludingVAT                                               AS AmountIncludingVAT,
	|	InventoryKinds.VATAmount                                                AS VATAmount,
	|	InventoryKinds.VATRate                                               AS VATRate,
	|	InventoryKinds.Cost_                                           AS Cost_,
	|	(CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN InventoryKinds.Cost_
	|		ELSE InventoryKinds.CostExcludingVAT_ END)                    AS CostExcludingVAT_,
	|	InventoryKinds.CostLocal                                       AS CostLocal,
	|	InventoryKinds.CDCost                                         AS CDCost,
	|	InventoryKinds.TDCost                                         AS TDCost,
	|	InventoryKinds.RowID                                     AS RowID,
	|	InventoryKinds.RowID                                     AS FinRecordID,
	|	CASE WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND InventoryKinds.DocumentSalesOfGoodsAndServices.Date < &BeginningOfMonthOfPeriod
	|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReturnViaCommissionAgentOfPreviousPeriods)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsViaCommissionAgent)
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			AND InventoryKinds.DocumentSalesOfGoodsAndServices.Date < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		WHEN InventoryKinds.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END AS BusinessTransactionSetting
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.InventoryKinds AS InventoryKinds
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS KeysWithoutAssignment
	|	ON 
	|		Dimension.Products = KeysWithoutAssignment.Products
	|		AND Dimension.Characteristic = KeysWithoutAssignment.Characteristic
	|		AND Dimension.Series = KeysWithoutAssignment.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysWithoutAssignment.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = KeysWithoutAssignment.Purpose
	|		AND  Dimension.StorageLocation = KeysWithoutAssignment.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS KeysOfTransmittedProductList
	|	ON 
	|		&ThisIsRefundFromCommissionAgent
	|		AND Dimension.Products = KeysOfTransmittedProductList.Products
	|		AND Dimension.Characteristic = KeysOfTransmittedProductList.Characteristic
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysOfTransmittedProductList.ProductCostElement
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = KeysOfTransmittedProductList.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = KeysOfTransmittedProductList.Purpose
	|		AND &Partner = KeysOfTransmittedProductList.StorageLocation
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS DimensionShipments
	|	ON
	|		InventoryKinds.ItemsLocationAttributesShipment = DimensionShipments.Ref
	|	
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS ShipmentKeysWithoutDestination
	|	ON
	|		DimensionShipments.Products = ShipmentKeysWithoutDestination.Products
	|		AND DimensionShipments.Characteristic = ShipmentKeysWithoutDestination.Characteristic
	|		AND DimensionShipments.Series = ShipmentKeysWithoutDestination.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = ShipmentKeysWithoutDestination.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = ShipmentKeysWithoutDestination.Purpose
	|		AND DimensionShipments.StorageLocation = ShipmentKeysWithoutDestination.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS ShippingKeysToCommittee
	|	ON
	|		Dimension.Products = ShippingKeysToCommittee.Products
	|		AND Dimension.Characteristic = ShippingKeysToCommittee.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = ShippingKeysToCommittee.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = ShippingKeysToCommittee.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = ShippingKeysToCommittee.Purpose
	|		AND InventoryKinds.InventoryOwnerAttribute.GoodsOwner = ShippingKeysToCommittee.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS RegistrationKeys
	|	ON
	|		InventoryKinds.ProductsRecordingAsReceived = RegistrationKeys.Products
	|		AND InventoryKinds.CharacteristicRecordingAsReceived = RegistrationKeys.Characteristic
	|		AND Dimension.Purpose = RegistrationKeys.Purpose
	|		AND Dimension.Series = RegistrationKeys.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = RegistrationKeys.ProductCostElement
	|		AND Dimension.StorageLocation = RegistrationKeys.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS KeysForRegisteringViaCommissionAgent
	|	ON
	|		InventoryKinds.ProductsRecordingAsReceived = KeysForRegisteringViaCommissionAgent.Products
	|		AND InventoryKinds.CharacteristicRecordingAsReceived = KeysForRegisteringViaCommissionAgent.Characteristic
	|		AND Dimension.Purpose = KeysForRegisteringViaCommissionAgent.Purpose
	|		AND Dimension.Series = KeysForRegisteringViaCommissionAgent.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysForRegisteringViaCommissionAgent.ProductCostElement
	|		AND &Contract = KeysForRegisteringViaCommissionAgent.StorageLocation
	|
	|	INNER JOIN
	|		Catalog.InventoryKinds AS Catalog
	|	ON
	|		InventoryKinds.InventoryOwnerAttribute = Catalog.Ref
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= InventoryKinds.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		InventoryKinds.Ref = Amounts.Ref
	|		AND InventoryKinds.RowID = Amounts.RowID
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers)
	RegisterName = "TransferredReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TTTableTypesOfStocks.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	&Period                                       AS Period,
	|	TTTableTypesOfStocks.Products             AS Products,
	|	TTTableTypesOfStocks.Characteristic           AS Characteristic,
	|	TTTableTypesOfStocks.Count               AS Count,
	|	TTTableTypesOfStocks.QuantityByGBRN         AS QuantityByGBRN,
	|	TTTableTypesOfStocks.AmountIncludingVAT                AS Sum,
	|	TTTableTypesOfStocks.DocumentSalesOfGoodsAndServices       AS DocumentTransfers_,
	|	CASE WHEN TTTableTypesOfStocks.InventoryOwnerAttributeShipment = VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|		TTTableTypesOfStocks.InventoryOwnerAttribute
	|	ELSE
	|		TTTableTypesOfStocks.InventoryOwnerAttributeShipment
	|	END                                         AS InventoryOwnerAttribute,
	|	TTTableTypesOfStocks.CCDNumber                 AS CCDNumber,
	|	&Partner                                      AS Partner,
	|	&DepositForPackageIsRequired                      AS DepositIsRequired,
	|	CASE
	|		WHEN &DepositForPackageIsRequired
	|			THEN &IDOfUnusedFinRecord
	|		ELSE TTTableTypesOfStocks.RowID
	|	END                                         AS FinRecordID,
	|	CASE
	|		WHEN TTTableTypesOfStocks.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|		WHEN TTTableTypesOfStocks.SalePeriod < &BeginningOfMonthOfPeriod
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnPackageFromCustomerOfPreviousPeriods)
	|		WHEN (TTTableTypesOfStocks.OriginWarehouse <> TTTableTypesOfStocks.ReturnWarehouse
	|			OR TTTableTypesOfStocks.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|			OR (TTTableTypesOfStocks.InventoryOwnerAttributeShipment <> TTTableTypesOfStocks.InventoryOwnerAttribute
	|				AND &KeepRecordsOfInventoryCostByAssignments)
	|			OR (TTTableTypesOfStocks.Purpose <> TTTableTypesOfStocks.PurposeOfShipment
	|				AND &KeepRecordsOfInventoryCostByAssignments))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferredPackageReverseTransactionReturnToAnotherWarehouse)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.TransferredPackageReverseTransaction)
	|	END                                         AS BusinessTransactionSetting
	|FROM
	|	TTTableTypesOfStocks AS TTTableTypesOfStocks
	|WHERE
	|	TTTableTypesOfStocks.Ref = &Ref
	|	AND TTTableTypesOfStocks.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ReusablePackageReturn
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextExchangeRates(Query, QueryTexts)
	
	RegisterName = "ExchangeRates"; 
	
	QueryText = "
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|
	|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
	|  / (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
	|
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|		Currency IN (
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS Currency
	|			FROM
	|				Document.ReturnOfGoodsFromCustomer.InventoryKinds AS TableTypesOfStocks_
	|
	|			WHERE
	|				TableTypesOfStocks_.Ref = &Ref
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			) AND BaseCurrency = &LocalAccountingCurrency
	|	) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &Currency AND BaseCurrency = &LocalAccountingCurrency) AS DocumentExchangeRate
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints"; 
	
	QueryText = 
	"SELECT
	|	TabularSection.AccrualDate                            AS Period,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END                                                     AS ValidityStartDate,
	|	CASE
	|		WHEN TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END                                                     AS DateToProcess,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END                                                     AS RecordType,
	|	TabularSection.LoyaltyProgram                AS LoyaltyProgram,
	|	&Partner                                                  AS Partner,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS Accrued,
	|	0                                                         AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.AccrualDate <> DATETIME(1,1,1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction                              AS Period,
	|	TabularSection.AccrualDate                            AS ValidityStartDate,
	|	&CurrentDate                                             AS DateToProcess,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	TabularSection.LoyaltyProgram               AS LoyaltyProgram,
	|	&Partner                                                 AS Partner,
	|	0                                                        AS Accrued,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS ToWriteOff
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.BonusPointAccrual AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.DateOfDeduction <> DATETIME(1,1,1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.PayDate AS Period,
	|	DATETIME(1, 1, 1),
	|	&CurrentDate,
	|	VALUE(AccumulationRecordType.Expense)                   AS RecordType,
	|	TabularSection.LoyaltyProgram               AS LoyaltyProgram,
	|	&Partner                                                 AS Partner,
	|	TabularSection.AmountOfBonusPoints AS Accrued,
	|	0 AS ToWriteOff
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.PaymentWithBonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableBonusPoints(Query, QueryTexts, Registers, Document)
	
	RegisterName = "BonusPoints";
	
	If Not BonusPointsServer.ItIsRequiredToAddRegisterRegisteredRecordsBonusPoints(Document) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	BonusPoints.Period                      AS Period,
	|	BonusPoints.ValidityStartDate          AS ValidityStartDate,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType                 AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner                     AS Partner,
	|	SUM(BonusPoints.Accrued)            AS Accrued,
	|	SUM(BonusPoints.ToWriteOff)            AS ToWriteOff
	|FROM
	|	TTBonusPoints AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period,
	|	BonusPoints.ValidityStartDate,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING 
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
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
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Data on the implementation document.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "ImplementationData",, "Object.Goods.Purpose");
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.DocumentSalesOfGoodsAndServices <> UNDEFINED
		|	AND Object.Goods.DocumentSalesOfGoodsAndServices <> VALUE(Document.CustomerInvoice.EmptyRef)
		|	AND Object.Goods.DocumentSalesOfGoodsAndServices <> VALUE(Document.RetailSalesReport.EmptyRef)";
	
	DescriptionOfColumns.DataPaths.Products       = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic     = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.DocumentSalesOfGoodsAndServices = "Object.Goods.DocumentSalesOfGoodsAndServices";
	
	Return FormTemplate;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	CASE
		|		WHEN TabPart.Damage
		|			THEN TabPart.ProductsRecordingAsReceived
		|		ELSE TabPart.Products
		|	END AS Products,
		|	CASE
		|		WHEN TabPart.Damage
		|			THEN TabPart.CharacteristicRecordingAsReceived
		|		ELSE TabPart.Characteristic
		|	END AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	&ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.RowCode <> 0
		|		AND TabPart.Ref.RequestForReturnOfGoodsFromCustomer <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef) AS OnSchedule,
		|	TabPart.Ref.RequestForReturnOfGoodsFromCustomer AS OrderInSchedule
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	OR TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
		|	OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	CASE
		|		WHEN TabPart.Damage
		|			THEN TabPart.ProductsRecordingAsReceived
		|		ELSE TabPart.Products
		|	END AS Products,
		|	CASE
		|		WHEN TabPart.Damage
		|			THEN TabPart.CharacteristicRecordingAsReceived
		|		ELSE TabPart.Characteristic
		|	END AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|	AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	CASE
		|		WHEN TabPart.Damage
		|			THEN TabPart.ProductsRecordingAsReceived
		|		ELSE TabPart.Products
		|	END AS Products,
		|	CASE
		|		WHEN TabPart.Damage
		|			THEN TabPart.CharacteristicRecordingAsReceived
		|		ELSE TabPart.Characteristic
		|	END AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE TabPart.Purpose
		|	END AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	CASE
		|		WHEN
		|			TabPart.Ref.RequestForReturnOfGoodsFromCustomer <> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|		AND TabPart.Ref.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN TabPart.Ref.RequestForReturnOfGoodsFromCustomer
		|		ELSE TabPart.Ref
		|	END AS OrderDocument,
		|	CASE
		|		WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1)
		|			THEN TabPart.Ref.DateOfReceipt
		|		ELSE TabPart.Ref.Date
		|	END AS DateOfReceipt,
		|	TRUE AS AvailableForConsumption,
		|	TabPart.RowCode <> 0
		|		AND TabPart.Ref.RequestForReturnOfGoodsFromCustomer
		|			<> VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef) AS OnSchedule,
		|	TabPart.Ref.RequestForReturnOfGoodsFromCustomer AS OrderInSchedule,
		|	TabPart.Count AS QuantityInGraph
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS TabPart
		|WHERE
		|	TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND (TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			OR TabPart.RowCode = 0
		|			OR TabPart.Ref.RequestForReturnOfGoodsFromCustomer
		|				= VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
EndProcedure

// Returns the return flag after the transfer of ownership
// 
// Parameters:
// 	DocumentReturnPolicy - DocumentRef.ReturnOfGoodsFromCustomer - document being checked
// Returns:
// 	Boolean - the sign of return after the transfer of ownership
//
Function ThisIsReturnAfterTransferOfOwnership(DocumentReturnPolicy) Export
	
	DocumentSalesOfGoodsAndServices = Common.ObjectAttributeValue(DocumentReturnPolicy, "DocumentSalesOfGoodsAndServices");
	
	Return TypeOf(DocumentSalesOfGoodsAndServices) = Type("DocumentRef.CustomerInvoice")
			And Common.ObjectAttributeValue(DocumentSalesOfGoodsAndServices, "BusinessOperation") = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
EndFunction

#EndRegion

#EndRegion

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	FillParameters.Insert("FormIsOpen",          False);
	FillParameters.Insert("FillByWarehouseDocument",     False);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	FillParameters.Insert("Warehouse",                 Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("Organization",           Catalogs.Companies.EmptyRef());
	FillParameters.Insert("Department",         Catalogs.BusinessStructure.EmptyRef());
	FillParameters.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	
	FillParameters.Insert("DocumentName",          "ReturnOfGoodsFromCustomer");
	FillParameters.Insert("RegisterNameOrder",      "GoodsToReceive");
	FillParameters.Insert("FieldNameOrder",          "ReferenceOrder");
	
	FillParameters.Insert("KeyFields",          "Products, Characteristic, Series, Purpose");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters by header details and orders
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders			= AnArrayOfOrders;
	
	FillParameters.HeaderAttributes			= HeaderAttributes;
	FillParameters.Warehouse					= HeaderAttributes.Warehouse;
	FillParameters.Organization				= HeaderAttributes.Organization;
	FillParameters.Department			= HeaderAttributes.Department;
	FillParameters.BusinessOperation	= HeaderAttributes.BusinessOperation;
	
EndProcedure

// Returns the Products table
//
// Parameters:
//  Invoice	 - DocumentRef - Link to the invoice, the table part of the Goods to be returned
//
// Returns:
//  ValueTable - contains significant columns of the tabular part of the Goods of the document.
//
Function TableDataAndDocument(Invoice) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Table.LineNumber                AS LineNumber,
	|	Table.Products               AS Products,
	|	Table.Characteristic             AS Characteristic,
	|	Table.Series                      AS Series,
	|	Table.Package                   AS Package,
	|	Table.Purpose                 AS Purpose,
	|	Table.Warehouse                      AS Warehouse,
	|	Table.RowCode                  AS RowCode,
	|	Table.NumberOfPackages         AS NumberOfPackages,
	|	Table.Count                 AS Count,
	|	Table.Price                       AS Price,
	|	Table.VATRate                  AS VATRate,
	|	Table.BatchesIndicationStatus        AS BatchesIndicationStatus,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.SetAccountingDimension      AS SetAccountingDimension,
	|	Table.Barcode                   AS Barcode,
	|	Table.DocumentSalesOfGoodsAndServices         AS DocumentSalesOfGoodsAndServices,
	|	Table.ProductsRecordingAsReceived  AS ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.Damage                       AS Damage,
	|	Table.Sum                       AS Sum,
	|	Table.VATAmount                    AS VATAmount,
	|	Table.AmountIncludingVAT                   AS AmountIncludingVAT
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS Table
	|WHERE
	|	Table.Ref = &Invoice";
	
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Fills in the passed parameter table for orders and warehouse orders
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.ReceiptOfGoodsFromCustodian - Link to the current invoice
//  FillParameters	 - Structure - The default settings defined in the method of Parametrization()
//  PackageBarcodes	 - ValueTable, Undefined - Table of barcodes of packages for returning stamp data
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	SeparatorText = InvoicesServer.QuerySeparatorText();
	
	FilterByWarehouse = ValueIsFilled(FillParameters.Warehouse);
	
	// If you do not need to fill in an order, we pass empty request parameters - an empty table will be returned for orders
	If FillParameters.FillByWarehouseDocument Then
		ReferencesForOrders = FillParameters.AnArrayOfOrders;
		RegistrarForOrders  = Recorder;
	Else
		ReferencesForOrders = Undefined;
		RegistrarForOrders  = Undefined;
	EndIf;
	
	// Orders
	
	Filter = New Structure();
	Filter.Insert("ReferenceOrder", "References");
	
	RequestTextForOrders = AccumulationRegisters.ShipmentAndReturnReferences.QueryTextBalancesOnReturns(
		"TTAccountingData",
		Filter,
		"ToRegister <> 0");
		
	Filter = New Structure();
	Filter.Insert("Ref", "References");
	If FilterByWarehouse Then
		TMCommonUse.AddSelectionItemToCollection(
		Filter,
		"TRUE",
		"Warehouse = &Warehouse OR Warehouse IN HIERARCHY (&Warehouse)",
		"=");
	EndIf;
	
	QueryTextOrderDocument = Documents.RequestForReturnOfGoodsFromCustomer.QueryTextDocumentGoods(Filter);
	
	QueryText = RequestTextForOrders
					+ SeparatorText
					+ QueryTextOrderDocument;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder",  Recorder);
	If FilterByWarehouse Then
		Query.SetParameter("Warehouse", FillParameters.Warehouse);
	EndIf;
	
	SetPrivilegedMode(True);
	
	OrdersTable = Query.Execute().Unload();
	
	TableOrdersColumnsToCheckout = OrdersTable.Columns.ToRegister; // ValueTableColumn
	TableOrdersColumnsOrderToSupplier = OrdersTable.Columns.PurchaseOrder; // ValueTableColumn
	
	TableOrdersColumnsToCheckout.Name = "QuantityInOrder";
	TableOrdersColumnsOrderToSupplier.Name = "ReferenceOrder";
	
	// Orders_3
	Query = New Query();
	
	Filter = New Map;
	If FilterByWarehouse Then
		TMCommonUse.AddSelectionItemToCollection(
		Filter,
		"TRUE",
		"Warehouse = &Warehouse OR Warehouse IN HIERARCHY (&Warehouse)",
		"=");
	EndIf;
	
	TextOfRequestRemainsToIssue = AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders(False, Filter);
	
	Query.Text = TextOfRequestRemainsToIssue;
	
	Query.SetParameter("References", ReferencesForOrders);
	Query.SetParameter("Recorder",  RegistrarForOrders);
	If FilterByWarehouse Then
		Query.SetParameter("Warehouse", FillParameters.Warehouse);
	EndIf;
	
	TableOrders = Query.Execute().Unload();

	OrderTableQuantityColumns = TableOrders.Columns.Count; // ValueTableColumn
	OrderTableQuantityColumns.Name = "NoteQuantity";
	
	// Distribution of the resulting tables
	
	Goods.Indexes.Add(FillParameters.KeyFields);
	
	// Adding the number of orders
	Var_Key = "RowCode";
	
	Condition = "On [Count]";
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
	// Adding the number of orders.
	Var_Key = FillParameters.KeyFields;
	
	// There are invoices and orders
	Condition = "[Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are orders, no invoices
	Condition = "NOT [Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are invoices, no orders
	Condition = "[Count], NOT [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
	
	If ReferencesForOrders <> Undefined Then
		TableOfBarcodesOfPackages = New ValueTable;
		ReturnOfGoodsFromCustomerLocalization.GenerateBarcodesOfPackages(ReferencesForOrders, TableOfBarcodesOfPackages);
		If TableOfBarcodesOfPackages.Count() > 0 Then
			FillInBarcodesOfPackages(Goods, TableOfBarcodesOfPackages, PackageBarcodes);
		EndIf;
	EndIf;
	
EndProcedure

// The procedure fills in the object fields
//
// Parameters:
//  Object				 - DocumentObject.ReceiptOfGoodsFromCustodian	 - object to fill in
//  FillParameters	 - Structure									 - structure containing keys RequisitePro, Iaregistry, Imabalances
//  AnArrayOfOrders		 - Array										 - an array of orders
//
Procedure FillInHeaderOfOrderDocument(Object, FillParameters, AnArrayOfOrders) Export
	
	FillPropertyValues(Object, FillParameters.HeaderAttributes);
	
	// Filling in the series.
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.ReturnOfGoodsFromCustomer);
	ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters, False);
	
	Object.RequestForReturnOfGoodsFromCustomer = AnArrayOfOrders[0];
	
	If ValueIsFilled(Object.RequestForReturnOfGoodsFromCustomer) Then
		Object.Warehouse = Common.ObjectAttributeValue(Object.RequestForReturnOfGoodsFromCustomer, "Warehouse");
	EndIf;
	
EndProcedure

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//  Goods				 - FormDataCollection - Table part " Products"
//  FillParameters	 - Structure
//  RecalculateAmount_	 - Boolean
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters, RecalculateAmount_ = True) Export
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(FillParameters.HeaderAttributes);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	If RecalculateAmount_ Then
		StructureOfActions.Insert("RecalculateAmount");
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	For Each String In Goods Do
		
		If Not ValueIsFilled(String.CostDefiningMethod) Then
			String.CostDefiningMethod = ?(ValueIsFilled(String.DocumentSalesOfGoodsAndServices),
				Enums.WaysToCalculateReturnCost.FromSalesDocument,
				Enums.WaysToCalculateReturnCost.FromCurrentDocument);
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the stamp data
// 
// Parameters:
// 	Goods - ValueTable - product data
// 	TableOfBarcodesOfPackages - ValueTable - found shipped stamps
// 	PackageBarcodes - ValueTable - result.
Procedure FillInBarcodesOfPackages(Goods, TableOfBarcodesOfPackages, PackageBarcodes)
EndProcedure

#EndRegion

#EndIf
#EndIf
