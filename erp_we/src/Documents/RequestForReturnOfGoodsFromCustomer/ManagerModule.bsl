#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Giấy đề nghị trả hàng từ người mua';
		|ru = 'Заявка на возврат товаров от клиента';
		|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
		|it = 'Richiesta di reso della merce dal cliente';
		|pl = 'Wniosek o zwrot towarów od klienta';
		|tr = 'Müşteriden mal iade talebi'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Partner", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Author, BusinessOperation";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Terms", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms, BusinessOperation";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Contract", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Counterparty", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "DocumentSalesOfGoodsAndServices, Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BusinessOperation", Parameters);
	
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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("PricesAndDiscounts");
	
	RequestForReturnOfGoodsFromCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.RequestForReturnOfGoodsFromCustomer") Then
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
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers, DocumentRef);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ReflectReserve(Query, QueryTexts, Registers);
	
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
	|	Header.Warehouse             AS Warehouse,
	|	T.DeliverFully    AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		MIN(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|				ELSE FALSE
	|			END) AS DeliverFully
	|	FROM
	|		Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS T
	|	WHERE
	|		T.Ref IN (&References)
	|		AND T.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	GROUP BY
	|		T.Ref
	|	
	|	HAVING
	|		MAX(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|			END) = TRUE
	|	) AS T
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS Header
	|		ON (Header.Ref = T.Ref)";
	
	Return QueryText;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.Order = -1;
	EndIf;
	
	Documents.CustomerInvoiceServices.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.ReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	
	Command = Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReceiptFromKeeper(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReturnFromCustodian,
			DataCompositionComparisonType.Equal);
	EndIf;
		
	Command = Documents.ReceiptOfGoodsFromCustodian.AddCreateCommandBasedOnReceiptFromCommissionAgent(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReturnFromCommissionAgent,
			DataCompositionComparisonType.Equal);
	EndIf;
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.TransferOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsShipmentToCustomer.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.CustomerInvoice.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.CustomerInvoice.AddCreateBasedOnRightsTransferReportCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateBasedOnInvoiceCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	
	RequestForReturnOfGoodsFromCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the document "request for return of goods from a customer".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseRequestsForReturnOfGoodsFromCustomers";
		
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
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm";
	EndIf;
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		Reports.SalesProfitabilityAssessment2_5.AddReportCommand(ReportsCommands);
	Else
		Reports.SalesProfitabilityAssessment.AddReportCommand(ReportsCommands);
	EndIf;
	
	ReportCommand = Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer.AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddRefundRequestCompletionStateCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	// DocumentsListForm
	ReportCommand = Reports.DocumentFulfillmentStatus.AddRefundRequestCompletionStateCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm,SelfServiceWorkplaceListForm";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = DataProcessors.OrderSupplyForecast.AddCommandStateOfCustomerOrderListProvision(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "SelfServiceWorkplaceListForm";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = Reports.ResultsOfApprovalOfRequestForReturnOfGoodsFromCustomer.AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 2;
	EndIf;
	
	RequestForReturnOfGoodsFromCustomerLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

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
	
	MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("ApplicationExecutionControl") Then
		
		QueryText = SalesServer.RequestTextOrderControlAfterExecution();
		
		QueryText =
		"SELECT DISTINCT
		|	ShippingOrdersTurnover.ReferenceOrder AS SalesOrder
		|INTO
		|	TTOrderBalances_
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, ReferenceOrder IN (&DocumentsArray)) AS ShippingOrdersTurnover
		|;
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE WHEN DocumentsTable.Status = &Status
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	CASE WHEN DocumentsTable.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
		|		AND &Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS StatusChangeErrorRejected,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording,
		|	DocumentsTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
		|	CASE WHEN TTOrderBalances_.SalesOrder IS NULL
		|		THEN FALSE
		|			ELSE TRUE
		|	END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentsTable
		|LEFT JOIN
		|	TTOrderBalances_
		|ON
		|	DocumentsTable.Ref = TTOrderBalances_.SalesOrder
		|WHERE
		|	DocumentsTable.Ref IN (&DocumentsArray)
		|";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE WHEN DocumentsTable.Status = &Status
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	CASE WHEN DocumentsTable.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
		|		AND &Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS StatusChangeErrorRejected,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording,
		|	DocumentsTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	EndIf;
	
	MonitorShipment = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment");
	MonitorCalculations  = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment");
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("MonitorShipment", MonitorShipment);
	Query.SetParameter("MonitorCalculations", MonitorCalculations);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - String - Name of the new status for documents
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If ValidationSample.StatusChangeErrorRejected Then
		
		ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"" chưa được đặt. Đặt trạng thái giấy đề nghị thành ""Trả về""';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен. Присвойте заявке статус ""К возврату""';
						|en = 'Status ""%Status%"" is not set for document %Document%. Assign status ""For return"" to the request'; fa = 'Status ""%Status%"" is not set for document %Document%. Assign status ""For return"" to the request';
						|it = 'Lo stato %Status% del documento %Document% non è impostato. Attribuire alla domanda lo stato ""Per il reso""';
						|pl = 'W dokumencie  %Document% nie ustawiono statusu ""%Status%"".  Przyznaj dla wnioska status ""К возврату""';
						|tr = '%Document% belgesine ""%Status%"" durumu atanmamıştır. Talebe ""İade Edilebilir"" durumunu verin.'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	If ValidationSample.ThisIsOrderAsInvoice Then
	
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa thiết lập trạng thái ""%Status%"", bởi vì đối với yêu cầu nhận hàng bán bị trả lại mà tạo trong chế độ ""Đơn hàng như hóa đơn"" chưa áp dụng trạng thái';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. для заявок на возврат товаров от клиентов, созданных в режиме ""Заказ как счет"" статусы не применимы';
						|en = 'The %Document% document is not set to ""%Status%"" as you cannot set statuses for sales return requests created in the ""Order as a commercial invoice"" mode'; fa = 'The %Document% document is not set to ""%Status%"" as you cannot set statuses for sales return requests created in the ""Order as a commercial invoice"" mode';
						|it = 'У документа %Document% статус ""%Status%"" не установлен, т.к. для заявок на возврат товаров от клиентов, созданных в режиме ""Заказ как счет"" статусы не применимы';
						|pl = 'The %Document% document is not set to ""%Status%"" as you cannot set statuses for sales return requests created in the ""Order as a commercial invoice"" mode';
						|tr = 'Durumlar ""Fatura olarak sipariş"" modunda oluşturulan müşteri iade siparişleri için geçerli olmadığından %Document% belgesi ""%Status%"" durumuna sahip değildir'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
		
	EndIf;
	
	If AdditionalParameters = Undefined Then
		Return Not Cancel;
	EndIf;
	
	If AdditionalParameters.Property("ApplicationExecutionControl")
		And ValidationSample.ThereAreLeftoversOnOrder Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" bởi vì đơn hàng cung ứng không đầy đủ';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ поставлен не полностью';
						|en = 'Cannot change the status of %Document% to %Status%. Some items have not been delivered'; fa = 'Cannot change the status of %Document% to %Status%. Some items have not been delivered';
						|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché l''ordine non è fornito completamente';
						|pl = 'W dokumencie %Document% nie ustawiono statusu ""%Status%"", ponieważ zamówienie wysłano nie w całości';
						|tr = 'Sipariş tam olarak teslim edilmediği için ""%Document%"" belgesinin ""%Status%"" durumu yoktur'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#Region TextsOfRequestOrderOfInvoices

// Adds the key details of the order to the selection collection
// 
// Parameters:
// 	Filter - Map
//
Procedure AddSelectionBasedOnKeyOrderDetails(Filter) Export
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Organization");
	KeyAttributes.Add("Partner");
	KeyAttributes.Add("Counterparty");
	KeyAttributes.Add("Contract");
	KeyAttributes.Add("SalesOpportunity");
	KeyAttributes.Add("Terms");
	KeyAttributes.Add("Currency");
	KeyAttributes.Add("LineOfBusiness");
	KeyAttributes.Add("ToReturnReusablePackage");
	
	TMCommonUse.AddSelectionBasedOnKeyOrderDetails(KeyAttributes, Filter);
	
EndProcedure

// Returns the text of the request for orders to processors according to key and additional selections.
// 
// Parameters:
// 	Parameters - See TMCommonUse.ParametersOfRequestTextForOrdersInvoices
// Returns:
//  String - Query text
//
Function RequestTextForOrdersInvoices(Parameters) Export
	
	AddSelectionBasedOnKeyOrderDetails(Parameters.Filter);
	
	QueryText =
	"SELECT
	|	TableOfOrders.Ref AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS TableOfOrders
	|WHERE
	|	TableOfOrders.Posted
	|	AND &FilterText1
	|";
	
	If Parameters.GenerateTT Then
		QueryText = RequestSchemes.SetSelectionOfAllowedRecords(QueryText, True);
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, Parameters.TTName);
		QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "ReferenceOrder");
	EndIf;
	
	QueryText =
		StrReplace(QueryText, "&FilterText1", TMCommonUse.SelectionTextBySelectionCollection(Parameters.Filter));
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region CalculationOfStates

// Calculates the current status of the request for the return of goods from the client
//
// Parameters:
//	RequestForReturnOfGoodsFromCustomer - DocumentRef.RequestForReturnOfGoodsFromCustomer - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//  CheckTasksToReflectStateOfOrders - Boolean - indicates whether the task has been checked
//	                                                      in the taskreference register for the status of orders.
//
Procedure CalculateStatus(Val RequestForReturnOfGoodsFromCustomer,
	                          Val Contract,
	                          StateOfCalculations,
	                          CheckTasksToReflectStateOfOrders = False) Export
	
	FillPropertyValues(StateOfCalculations, ARAPAccountingClientServer.StructureOfStateOfCalculations(True));
	
	If Not ValueIsFilled(RequestForReturnOfGoodsFromCustomer) Or Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
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
	|INTO TT_DocumentRequest
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS TT
	|WHERE
	|	TT.Ref = &DocumentRequest
	|	AND NOT TT.ThisIsOrderAsInvoice
	|;
	|/////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN (NOT DocumentRequest.Posted)
	|			THEN VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.EmptyRef)
	|		WHEN NOT (SalesOrderStates.State IS NULL)
	|			THEN SalesOrderStates.State
	|		WHEN DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed)
	|			THEN VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed)
	|		WHEN DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
	|			THEN VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
	|		ELSE
	|			VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed) 
	|	END AS State,
	|	CASE
	|		WHEN (NOT DocumentRequest.Posted)
	|			THEN FALSE
	|		WHEN DocumentRequest.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
	|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
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
	|	ISNULL(SalesOrderStates.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
	|	,&FieldHasTasksToReflectStateOfOrders
	|FROM
	|	TT_DocumentRequest AS DocumentRequest
	|LEFT JOIN
	|	InformationRegister.SalesOrderStates AS SalesOrderStates
	|ON
	|	SalesOrderStates.OrderDocument = DocumentRequest.Ref
	|WHERE
	|	&CheckTasksToReflectStateOfOrders
	|";
	
	QueryTextHasJobs = "SELECT FALSE AS ThereAreTasksToReflectStateOfOrders";
	If CheckTasksToReflectStateOfOrders Then
		
		QueryText = StrReplace(QueryText,
									",&FieldHasTasksToReflectStateOfOrders",
									",	FALSE AS ThereAreTasksToReflectStateOfOrders");
		
		QueryTextHasJobs = DocumentsStates.QueryTextThereAreTasksToReflectStateOfOrders("&DocumentRequest");
		
		QueryText = StrReplace(QueryText,
									"&CheckTasksToReflectStateOfOrders",
									StrTemplate("NOT TRUE IN 
											  |		(%1)", QueryTextHasJobs));
		
	Else
		
		QueryText = StrReplace(QueryText, ",&FieldHasTasksToReflectStateOfOrders", "");
		QueryText = StrReplace(QueryText, "&CheckTasksToReflectStateOfOrders", "TRUE");
		
	EndIf;
	
	QueryTextCalculations = "SELECT 0 AS AmountToPay";
	If AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		
		QueryTextCalculations = "
		|SELECT
		|	CASE
		|		WHEN
		|			DocumentRequest.Posted
		|			AND (DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				OR DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|		THEN
		|			ISNULL(CustomersARAPAccountingBalance.AmountDueBalance,0)
		|		ELSE
		|			0
		|	END AS AmountToPay
		|FROM
		|	TT_DocumentRequest AS DocumentRequest
		|LEFT JOIN
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,
		|			ARAPObject IN (SELECT TT.ARAPObject FROM TT_DocumentRequest AS TT)
		|	) AS CustomersARAPAccountingBalance
		|ON
		|	DocumentRequest.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
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
	
	Query.SetParameter("DocumentRequest", RequestForReturnOfGoodsFromCustomer);
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	
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

// The function returns the request text for calculating the status of requests.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingOrderStates() Export
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&AnArrayOfOrders)";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = "ReferenceOrder";
	TableFormationParameters.TempTableName = "TT_RequestsForReturnsTurnoverExpanded";
	
	TT_RequestsForReturnsTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = TT_RequestsForReturnsTurnoverExpanded +
		Common.QueryBatchSeparator() + "
		|SELECT
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentRequest.Posted
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.EmptyRef)
		|// APPROVAL IS EXPECTED //////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingApproval)
		|// REJECTED ///////////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
		|// EXECUTION IS EXPECTED ////////////////////////////////////////////////////
		|	WHEN
		|		((DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
		|		OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip))
		|		AND DocumentRequest.ReplacementAmount = 0
		|		AND ISNULL(RequestsForReturnBalance.ForRegistrationOnReturnsQuantityTurnover, 0) -
		|			ISNULL(RequestsForReturnBalance.IssuedByReturnsQuantityTurnover, 0) <> 0)
		|		OR (DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		AND DocumentRequest.ReplacementAmount <> 0
		|		AND DocumentRequest.AmountPrepaymentBeforeGoodsIssue = 0
		|		AND DocumentRequest.AmountOfPrepaymentBeforeShipment = 0)
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingExecution_)
		|// AN ADVANCE PAYMENT IS EXPECTED BEFORE SECURING //////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders) AND
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply) OR
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)) AND
		|		DocumentRequest.AmountPrepaymentBeforeGoodsIssue > 0 AND
		|		ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentRequest.AmountPrepaymentBeforeGoodsIssue AND
		|		(ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingAdvanceOrReturnBeforeSupply)
		|// READY TO PROVIDE ///////////////////////////////////////////////////
		|		WHEN TTOrderAssurance.ThereIsToProvision
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_)
		|// PREPAYMENT IS EXPECTED BEFORE SHIPMENT ////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders) AND
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn) OR
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)) AND
		|		DocumentRequest.AmountOfPrepaymentBeforeShipment > 0 AND
		|		ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentRequest.AmountOfPrepaymentBeforeShipment + DocumentRequest.AmountPrepaymentBeforeGoodsIssue AND
		|		(ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPrepaymentOrReturnBeforeShipment)
		|// PROVISION IS EXPECTED ////////////////////////////////////////////////////
		|		WHEN NOT TTPartiallyInStock.Ref IS NULL
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingSupply)
		|// READY FOR SHIPMENT //////////////////////////////////////////////////////////
		|	WHEN
		|		NOT TTOrderAssurance.ShipEverything
		|			OR TTDiscrepanciesOrderInvoice.WarrantRequired
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForShipment)
		|// IN THE PROCESS OF SHIPMENT //////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|			OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|		AND DocumentRequest.ReplacementAmount > 0
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentRequest.AmountOfPrepaymentBeforeShipment + DocumentRequest.AmountPrepaymentBeforeGoodsIssue
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) - ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentRequest.AmountOfPrepaymentBeforeShipment + DocumentRequest.AmountPrepaymentBeforeGoodsIssue
		|			OR DocumentRequest.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByOrders))
		|		AND ((ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) <> 0
		|			OR ISNULL(SalesOrdersBalance.OrderedClosingBalance, 0) <> 0)
		|			OR ISNULL(GoodsForIssueBalance.ToShipBalance, 0) <> 0)
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.DuringShipment)
		|// PAYMENT IS EXPECTED ////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders) AND
		|		((DocumentRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon) AND
		|		DocumentRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected) AND
		|		DocumentRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)) ) AND
		|		DocumentRequest.ReplacementAmount - DocumentRequest.AmountPrepaymentBeforeGoodsIssue - DocumentRequest.AmountOfPrepaymentBeforeShipment > 0 AND
		|		ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPaymentOrReturnAfterShipment)
		|// EXECUTION IS EXPECTED ////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed) AND &MonitorOrderClosing
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingExecution_)
		|// COMPLETED ///////////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.Status IN
		|				(VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn), 
		|					VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|					VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|					VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|	THEN
		|		VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed)
		|END AS State,
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentRequest.Posted
		|	THEN
		|		DATETIME(1,1,1)
		|// DATE OF APPROVAL ///////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|	THEN
		|		DocumentRequest.ApprovalDate
		|// DATE OF RECEIPT ////////////////////////////////////////////////////////
		|	WHEN
		|		((DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
		|		OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip))
		|		AND DocumentRequest.ReplacementAmount = 0)
		|		OR (DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		AND DocumentRequest.AmountPrepaymentBeforeGoodsIssue = 0
		|		AND DocumentRequest.AmountOfPrepaymentBeforeShipment = 0)
		|	THEN
		|		DocumentRequest.DateOfFirstReceipt
		|// ADVANCE PAYMENT DATE /////////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders) AND
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
		|		OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn))AND
		|		DocumentRequest.AmountPrepaymentBeforeGoodsIssue > 0 AND
		|		ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentRequest.AmountPrepaymentBeforeGoodsIssue AND
		|		(ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// PREPAYMENT DATE /////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders) AND
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|		OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)) AND
		|		DocumentRequest.AmountOfPrepaymentBeforeShipment > 0 AND
		|		ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentRequest.AmountOfPrepaymentBeforeShipment + DocumentRequest.AmountPrepaymentBeforeGoodsIssue AND
		|		(ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// DATE OF SHIPMENT ///////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn) OR
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip) OR
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)) AND
		|		(ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentRequest.AmountOfPrepaymentBeforeShipment + DocumentRequest.AmountPrepaymentBeforeGoodsIssue
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) - ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentRequest.AmountOfPrepaymentBeforeShipment + DocumentRequest.AmountPrepaymentBeforeGoodsIssue
		|			OR DocumentRequest.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByOrders)) AND
		|		(ISNULL(SalesOrdersBalance.SumClosingBalance, 0) > 0 OR ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) > 0)
		|	THEN
		|		ISNULL(ShippingDatesOfCustomerOrders.MinimumShipmentDate, DocumentRequest.DateOfShipment)
		|// PAYMENT DATE AFTER SHIPMENT //////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders) AND
		|		(DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip) 
		|				OR DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)) AND
		|		DocumentRequest.ReplacementAmount - DocumentRequest.AmountPrepaymentBeforeGoodsIssue - DocumentRequest.AmountOfPrepaymentBeforeShipment > 0 AND
		|		ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) = 0 AND
		|		ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0
		|	THEN
		|		SettlementDates.UpdateDate
		|// OVERDUE REFUND ///////////////////////////////////////////////////////
		|	WHEN
		|		DocumentRequest.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|	THEN
		|		DocumentRequest.DateOfFirstReceipt
		|	ELSE
		|		DATETIME(1,1,1)
		|END AS EventDate,
		|// PAYMENT AMOUNT /////////////////////////////////////////////////////////////
		|CASE
		|	WHEN (DocumentRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|				OR DocumentRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer))
		|			AND DocumentRequest.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods)
		|		THEN ISNULL(MutualSettlementsStatus.PayAmount, 0)
		|	ELSE 0
		|END AS PayAmount,
		|// PERCENTAGE OF PAYMENT ///////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer) 
		|				OR DocumentRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer) 
		|		THEN ISNULL(MutualSettlementsStatus.PayPercentage, 0)
		|	ELSE 0
		|END AS PayPercentage,
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
		|		DocumentRequest.Posted
		|		AND DocumentRequest.Status <> VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|		AND DocumentRequest.ReplacementAmount > 0
		|	THEN
		|		ISNULL(TTDiscrepanciesOrderInvoice.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) 
		|	ELSE
		|		FALSE
		|	END AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
		|//LINK TO THE APPLICATION//////////////////////////////////////////////////////
		|	DocumentRequest.Ref AS OrderDocument
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequest
		|LEFT JOIN
		|	TTStateOfSETTLEMENTS AS MutualSettlementsStatus
		|ON
		|	DocumentRequest.Ref = MutualSettlementsStatus.OrderDocument
		|	
		|LEFT JOIN
		|	TTCustomerOrdersBalance AS SalesOrdersBalance
		|ON
		|	DocumentRequest.Ref = SalesOrdersBalance.SalesOrder
		|
		|LEFT JOIN
		|	TT_RequestsForReturnsTurnoverExpanded AS RequestsForReturnBalance
		|ON
		|	DocumentRequest.Ref = RequestsForReturnBalance.ReferenceOrder
		|
		|LEFT JOIN
		|	TTGoodsForShipmentBalance AS GoodsForIssueBalance
		|ON
		|	DocumentRequest.Ref = GoodsForIssueBalance.SalesOrder
		|
		|LEFT JOIN
		|	CustomerOrderValidityDates AS SettlementDates
		|ON
		|	DocumentRequest.ARAPObject = SettlementDates.ARAPObject
		|LEFT JOIN
		|	ShippingDatesOfCustomerOrders AS ShippingDatesOfCustomerOrders
		|ON
		|	DocumentRequest.Ref = ShippingDatesOfCustomerOrders.SalesOrder
		|LEFT JOIN
		|	TTOrderAssurance AS TTOrderAssurance
		|ON
		|	TTOrderAssurance.Ref = DocumentRequest.Ref
		|LEFT JOIN
		|	TTPartiallyInStock AS TTPartiallyInStock
		|ON
		|	TTPartiallyInStock.Ref = DocumentRequest.Ref
		|LEFT JOIN
		|	TTDiscrepanciesOrderInvoice AS TTDiscrepanciesOrderInvoice
		|ON
		|	DocumentRequest.Ref = TTDiscrepanciesOrderInvoice.SalesOrder
		|WHERE
		|	DocumentRequest.Ref IN (&AnArrayOfOrders)
		|	AND NOT DocumentRequest.ThisIsOrderAsInvoice
		|
		|";
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef - Link to the document.
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
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.ReplacementAmount AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings
	|
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
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
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation, Enums.BusinessTransactions.ReturnOfGoodsFromCustomer);
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
		DocumentAmount = 0;
		AmountARAP = 0;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	
	Return AttributesStructure1;

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
	ArrayOfAllProps.Add("Department");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("ReusablePackageReturn");
	ArrayOfAllProps.Add("DepositForPackageIsRequired");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Then
		ArrayOfOperationDetails.Add("Department");
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("ReusablePackageReturn");
		ArrayOfOperationDetails.Add("DepositForPackageIsRequired");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ArrayOfOperationDetails.Add("Contract");
		ArrayOfOperationDetails.Add("ReusablePackageReturn");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		ArrayOfOperationDetails.Add("Contract");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		ArrayOfOperationDetails.Add("Department");
	EndIf;
	
EndProcedure

// The function returns the structure of calculations for the request for return of goods from the client
//
// Parameters:
//	DocumentRef - DocumentRef.RequestForReturnOfGoodsFromCustomer - link to the document.
//
// Returns:
//	Structure - details of the selected document
//		Our debt - Number is our debt on the application.
//		The client's debt is a number - the client's debt.
//		There were calculations - Boolean - were there any calculations at all on the application.
//
Function CalculationsForApplication(DocumentRef) Export
	
	StructureOfCalculations = New Structure();
	StructureOfCalculations.Insert("AccountsPayableOfCompany",0);
	StructureOfCalculations.Insert("CustomerAccountsReceivable",0);
	StructureOfCalculations.Insert("ThereWereCalculations",False);
	
	If Not ValueIsFilled(DocumentRef) Or
		Not AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		Return StructureOfCalculations;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	SUM(CASE
	|			WHEN CustomersARAPAccounting.SumTurnover < 0
	|				THEN -CustomersARAPAccounting.SumTurnover
	|			ELSE 0
	|		END) AS AccountsPayableOfCompany,
	|	SUM(CASE
	|			WHEN CustomersARAPAccounting.SumTurnover > 0
	|				THEN CustomersARAPAccounting.SumTurnover
	|			ELSE 0
	|		END) AS CustomerAccountsReceivable,
	|	TRUE AS ThereWereCalculations
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(,
	|		&CurrentDate, Recorder, , ARAPObject.Object = &ReturnRequest) AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.SumTurnover <> 0";
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("ReturnRequest", DocumentRef);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	If Selection.Next() Then
		If Not Selection.CustomerAccountsReceivable = NULL Then
			
			FillPropertyValues(StructureOfCalculations, Selection);
			
		EndIf;
	EndIf;
	
	Return StructureOfCalculations;
	
EndFunction

#EndRegion

// Fills in empty receipt dates in the table part of the returned Goods.
//
// Parameters:
//	Object         - DocumentObject.RequestForReturnOfGoodsFromCustomer, FormDataStructure - Document to be filled in on the date of receipt
//
Procedure FillIn_BlankReceiptDates(Object) Export
	
	If Object.ReturnedGoods.Count() = 0 Then
		Return;
	EndIf;
	
	If PurchasesServerCall.ReceiptDateIsBlank(Object, "ReturnedGoods") Then
		
		If (Object.OneDateReceipt 
			And Not ValueIsFilled(Object.DateOfReceipt)) 
			Or (Not Object.OneDateReceipt) Then
			
			If ValueIsFilled(Object.RequestedDeliveryDate)
				And Object.RequestedDeliveryDate >= Object.Date Then
				Object.DateOfReceipt = Object.RequestedDeliveryDate;
			Else
				Object.DateOfReceipt = CurrentSessionDate();
			EndIf;
			
		EndIf;
			
		For Each TSRow In Object.ReturnedGoods Do
			If (Not ValueIsFilled(TSRow.DateOfReceipt))
				Or Object.OneDateReceipt Then
				TSRow.DateOfReceipt = Object.DateOfReceipt;
			EndIf;
		EndDo;
		
		StructureOfActions = New Structure();
		CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ReturnedGoods, StructureOfActions);
		
	EndIf;
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Date,Status,ThisIsOrderAsInvoice";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	Returned_ = ProductsClientServer.SeriesSpecificationParameters();
	Returned_.FullObjectName = "Document.RequestForReturnOfGoodsFromCustomer";
	
	Returned_.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
	Returned_.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	Returned_.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer);
	Returned_.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	Returned_.LinkFields.Add("ProductsRecordingAsReceived");
	Returned_.LinkFields.Add("CharacteristicRecordingAsReceived");
	Returned_.LinkFields.Add("Purpose");
	Returned_.LinkFields.Add("Warehouse");
	
	Returned_.NameTSGoods = "ReturnedGoods";
	Returned_.TSSeriesName  = "ReturnedBatch";
	
	Returned_.ThisIsAnInvoice = True;
	Returned_.Date = Object.Date;
	
	Substitutes_ = ProductsClientServer.SeriesSpecificationParameters();
	Substitutes_.FullObjectName = "Document.RequestForReturnOfGoodsFromCustomer";
	
	Substitutes_.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch
					And Not Object.ThisIsOrderAsInvoice;
	Substitutes_.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches
					And Not Object.ThisIsOrderAsInvoice;
	
	Substitutes_.LinkFields.Add("Warehouse");
	
	Substitutes_.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	Substitutes_.NameTSGoods = "SubstituteGoods";
	Substitutes_.TSSeriesName  = "SubstituteGoods";
	
	Substitutes_.ThisIsOrder = True;
	Substitutes_.ShipmentPlanning = True;
	Substitutes_.RegisterSeries = False;
	Substitutes_.Date = Object.Date;
	
	SeriesSpecificationParameters = New Structure;
	SeriesSpecificationParameters.Insert("Returned_",Returned_);
	SeriesSpecificationParameters.Insert("Substitutes_",Substitutes_);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.WarehouseTransactions[0] = Enums.WarehouseTransactions.ReceivingByReturnFromACustomer Then
		QueryText = 
		"SELECT
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.ProductsRecordingAsReceived,
		|	Goods.CharacteristicRecordingAsReceived,
		|	Goods.Series,
		|	Goods.Purpose,
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
		|	END AS BatchesIndicationStatus
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
		|	Statuses.LineNumber AS LineNumber,
		|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
		|FROM
		|	Statuses AS Statuses
		|WHERE
		|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
		|
		|ORDER BY
		|	LineNumber";
		
	Else
		
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
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Checks the completeness of the verified details.
//
// Parameters:
//  SalesOrder       - DocumentRef - The document on the basis of which the input is made
//  Status             - EnumRef - Status of the document that is used for entering data
//  ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held.
//  ForReturn          - Boolean - take into account the status of the quota.
//
// Returns:
//  Boolean - True if input based on is possible.
//
Function CheckPossibilityOfEnteringBasedOn(SalesOrder, Status = Undefined, ThereAreErrorsPosted = False,
	ForReturn = False) Export
	
	ThisIsOrderAsInvoice = Common.ObjectAttributeValue(SalesOrder, "ThisIsOrderAsInvoice");
	ArrayOfValidStatuses = ValidInputStatusesBasedOn("", ForReturn, Not ThisIsOrderAsInvoice);
	ThereAreErrorsStatus = ArrayOfValidStatuses.Find(Status) = Undefined;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		SalesOrder,
		Status,
		ThereAreErrorsPosted,
		ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
EndFunction

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//  ForReturn - Boolean - take into account the status of the quota.
//  UseAdvancedFeaturesOfSalesOrder - Boolean, Undefined - 
//										false - returns Statuses only for the "order as invoice" mode of operation,
//										true - returns Statuses for the extended mode of operation,
//										undefined returns Statuses depending on the functional option installed in the system.
//
// Returns:
//  Array of EnumRef.StatusesOfRequestsForReturnOfGoodsFromCustomers - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName = "", ForReturn = False,
	UseAdvancedFeaturesOfSalesOrder = Undefined) Export
	
	ArrayOfValidStatuses = New Array;
	
	If UseAdvancedFeaturesOfSalesOrder = Undefined Then
		UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
	If DocumentName = "ReceiptOfGoodsFromCustodian" Then
		ForReturn = True;
	EndIf;
	
	If UseAdvancedFeaturesOfSalesOrder Then
		If ForReturn Then
			ArrayOfValidStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
		EndIf;
		If GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
			ArrayOfValidStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply);
		Else
			If ForReturn Then
				ArrayOfValidStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply);
			EndIf;
			ArrayOfValidStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
		EndIf;
		If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
			Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
			ArrayOfValidStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
		EndIf;
	Else
		ArrayOfValidStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon);
	EndIf;
	
	Return ArrayOfValidStatuses;
	
EndFunction

// This function checks the order document when creating an expense order
//
// Parameters:
//	ReferenceOrder - DocumentRef - Document-order
//	Warehouse - CatalogRef.Warehouses - element of the Warehouses reference list.
//
// Returns:
//	Structure - verification results:
//	* Operation 						- String - Type of operation. "Failure" if the checks passed with errors
//	* ErrorText 					- String - Must be filled in when Failure = True
//	* GroupOfWarehousesAtYourDisposal 	- Boolean - A group of warehouses is selected at the disposal
//	* DateOfShipment 					- Date
//	* UseAdvancedWarehousing 	- Boolean - The warehouse uses an order scheme.
//
Function PerformOrderChecks(ReferenceOrder, Warehouse) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Operation", "");
	ReturnStructure.Insert("ErrorText", "");
	ReturnStructure.Insert("GroupOfWarehousesAtYourDisposal", False);
	ReturnStructure.Insert("DateOfShipment");
	ReturnStructure.Insert("UseAdvancedWarehousing");
	
	If Not ValueIsFilled(Common.ObjectAttributeValue(ReferenceOrder, "Warehouse")) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi"" trong chứng từ ""%ReferenceOrder%"". Không thể tạo phiếu.';
						|ru = 'Не заполнено поле ""Склад"" в документе ""%ReferenceOrder%"". Невозможно создать ордер.';
						|en = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.'; fa = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.';
						|it = 'Il campo ""Magazzino"" nel documento ""%ReferenceOrder%"" non è stato compilato. Impossibile creare un mandato.';
						|pl = 'Nie jest wypełnione pole ""Magazyn"" w dokumencie ""%ReferenceOrder%"". Nie można utworzyć zlecenia.';
						|tr = '""%ReferenceOrder%"" belgesindeki ""Ambar"" alanı doldurulmamış. Giriş fişi oluşturulamaz.'");
		ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
		ReturnStructure.ErrorText = ErrorText;
		ReturnStructure.Operation = "Cancel";
		
		Return ReturnStructure
		
	EndIf;
	
	WarehouseGroupStructure     = New Structure("IsFolder", "Warehouse.IsFolder");
	WarehouseGroupValue      = Common.ObjectAttributesValues(ReferenceOrder, WarehouseGroupStructure);
	GroupOfWarehousesAtYourDisposal = WarehouseGroupValue.IsFolder;
	
	ReturnStructure.GroupOfWarehousesAtYourDisposal = GroupOfWarehousesAtYourDisposal; 
	
	Attributes = New Structure("DateOfShipment, Warehouse, UseAdvancedWarehousing", "Date");
		 	
	If Not GroupOfWarehousesAtYourDisposal Then
		
		Attributes.Warehouse = "Warehouse";
		Attributes.UseAdvancedWarehousing ="
		|CASE
		|	WHEN ISNULL(Warehouse.UseWarehouseManagemantSystemForGoodsIssue, FALSE)
		|			AND DATE >= ISNULL(Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1))
		|		THEN TRUE
		|	ELSE FALSE
		|END";
		
		AttributesValues = Common.ObjectAttributesValues(ReferenceOrder, Attributes);
		UseAdvancedWarehousing = AttributesValues.UseAdvancedWarehousing;
		
		ReturnStructure.UseAdvancedWarehousing = UseAdvancedWarehousing;
		
		If UseAdvancedWarehousing Then
			
			Warehouse = AttributesValues.Warehouse;
			FillPropertyValues(ReturnStructure, AttributesValues, "DateOfShipment");
			
		Else
			
			ErrorText = NStr("vi = 'Đối với kho bãi ""%Warehouse%"" không cần lập phiếu xuất kho.
				|Chưa điền chứng từ.';
				|ru = 'Для склада ""%Warehouse%"" оформление расходных ордеров не требуется.
				|Заполнение документа не выполнено.';
				|en = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
				|The document is not completed.'; fa = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
				|The document is not completed.';
				|it = 'Per il magazzino, ""%Warehouse%"" non è richiesta la formalizzazione dei mandati di pagamento.
				|La compilazione del documento non è eseguita.';
				|pl = 'W przypadku magazynu ""%Warehouse%"" sporządzenie zleceń wydania nie jest wymagane.
				|Dokument nie został wypełniony.';
				|tr = '""%Warehouse%"" ambarı için herhangi bir ambar çıkış fişlerini düzenleme gerekmemektedir.
				| Belge tamamlanmamıştır.'");
			ReturnStructure.ErrorText = StrReplace(ErrorText, "%Warehouse%", String(AttributesValues.Warehouse));
			ReturnStructure.Operation = "Cancel";
			Return ReturnStructure;
			
		EndIf;	
	EndIf;
	
	Status = Common.ObjectAttributeValue(ReferenceOrder, "Status");
	
	CheckPossibilityOfEnteringBasedOn(ReferenceOrder, Status);
	
	If GroupOfWarehousesAtYourDisposal Then
		If Not ValueIsFilled(Warehouse) Then
			WarehouseArray = Documents.GoodsIssueNote.OrderWarehousesDuringShipment(ReferenceOrder, Undefined);
			If WarehouseArray.Count() = 0 Then
				ErrorText = NStr("vi = 'Đối với các kho bãi của chứng từ ""%ReferenceOrder%"" không cần lập phiếu nhập kho.
										|Chưa điền chứng từ.';
										|ru = 'Для складов документа ""%ReferenceOrder%"" оформление приходных ордеров не требуется.
										|Заполнение документа не выполнено.';
										|en = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
										|The document is not populated.'; fa = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
										|The document is not populated.';
										|it = 'Per i magazzini del documento ""%ReferenceOrder%"" non è richiesta la formalizzazione dei reversali d’incasso.
										|La compilazione del documento non è eseguita.';
										|pl = 'W przypadku magazynów dokumentu ""%ReferenceOrder%"" sporządzenie zleceń wydania nie jest wymagane.
										|Dokument nie został wypełniony.';
										|tr = '""%ReferenceOrder%"" belgesindeki depolar için ambar giriş fişlerinin düzenlemesi gerekmemektedir.
										| Belge tamamlanmamıştır.'");
				ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
				ReturnStructure.ErrorText = ErrorText;
				ReturnStructure.Operation = "Cancel";
				Return ReturnStructure;
			ElsIf WarehouseArray.Count() = 1 Then
				Warehouse = WarehouseArray[0];
			Else
				ReturnStructure.Operation = "Return";
				Return ReturnStructure;
			EndIf;
		Else
			ReturnStructure.Operation = "Return";
			Return ReturnStructure;
		EndIf;
	EndIf;
	
	Return ReturnStructure
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//  Structure - a structure with the necessary fields.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable", 1);
	StructureState.Insert("OutputTablesReturn", 3);
	StructureState.Insert("DisplayTablesCanceledReceipt", 4);
	
	StructureState.Insert("OutputTablesSupply", 5);
	StructureState.Insert("DisplayShipmentTables", 6);
	StructureState.Insert("DisplayTablesCanceledShipment", 7);
	
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("WarehouseInHeader", True);
	StructureState.Insert("ThereAreSummaryShipmentIndicators", True);
	StructureState.Insert("ThereAreSummaryIndicatorsOfReceipt", True);
	StructureState.Insert("ThereAreReasonsToCancelShipment", True);
	StructureState.Insert("NameTSGoodsShipment", "SubstituteGoods");
	StructureState.Insert("NameTSGoodsArrival", "ReturnedGoods");
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Hàng hóa thay thế';
															|ru = 'Заменяющие товары';
															|en = 'Exchange goods'; fa = 'کالای تعویضی';
															|it = 'Merci sostitutive';
															|pl = 'wiersze pozycji zastępcze';
															|tr = 'İkame ürünler'"));
	StructureState.Insert("TextProductServiceReceipt", NStr("vi = 'Hàng hóa trả lại';
															|ru = 'Возвращаемые товары';
															|en = 'Goods pending return'; fa = 'کالای در انتظار برگشت';
															|it = 'Merci da rendere';
															|pl = 'Zwracane wiersze pozycji';
															|tr = 'İade edilen ürünler'"));
	StructureState.Insert("RegisterNameShipmentOfServices", "ShipmentAndReturnReferences");
	
	Return StructureState
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.RequestForReturnOfGoodsFromCustomer - the document to generate parameters for.
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
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Or
		Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer  Then
		
		FillParameters.ReturnOfGoodsFromCustomer = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		FillParameters.ReturnOfGoodsFromCommissionAgent = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		
		FillParameters.ReturnFromStorage = True;
		
	EndIf;
	
	Return FillParameters;
	
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
			|CompensationMethod,
			|ThisIsOrderAsInvoice");
		BusinessOperation = StructureFillingData.BusinessOperation;
		CompensationMethod     = StructureFillingData.CompensationMethod;
		ThisIsOrderAsInvoice       = StructureFillingData.ThisIsOrderAsInvoice;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		CompensationMethod     = Undefined;
		ThisIsOrderAsInvoice       = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		CompensationMethod     = FillingData.CompensationMethod;
		ThisIsOrderAsInvoice       = FillingData.ThisIsOrderAsInvoice;
	EndIf;
	
	UseAdvancedFeaturesOfSalesOrder = ?(ThisIsOrderAsInvoice = Undefined,
														GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
														Not ThisIsOrderAsInvoice);
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsOrder                         = CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods; 
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesCalculationsByString           =
	"((DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|	OR DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian))
	|	AND DataSource.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods)
	|		OR DataSource.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ReturnCash))";

	ParametersStructure.ChangesPaymentPlan               = (BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
															Or BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer)
															And (CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods
																Or CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ReturnCash);
	
	ParametersStructure.ModifiesDeliveryShipmentPlan     = (BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
															Or BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer)
															And CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods
															And UseAdvancedFeaturesOfSalesOrder;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	ParametersStructure.PaymentSchedule                     = "";
	
	ParametersStructure.PathToTSData                    = "Object.SubstituteGoods";
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	ParametersStructure.DateOfShipment                     = "Object.SubstituteGoods.DateOfShipment";
	ParametersStructure.OrderAsAProformaInvoice                     = Not UseAdvancedFeaturesOfSalesOrder;
	ParametersStructure.ShipInOneDay              = "Object.NotShipInInstallments";
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.DocumentAmountForm              = "Form.AmountOfReplacementProducts";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	
	//Names of form elements for the current set of parameters
	ParametersStructure.FormItems.InscriptionStages                     = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	ParametersStructure.FormItems.DebtLimitationText    = "DecorationDebtLimitation";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	ParametersStructure.FormItems.PaymentSettlement                      = "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.ToReturnReusablePackage        = "Object.ToReturnReusablePackage";
	ParametersStructure.PackageDepositIsRequired             = "Object.PackageDepositIsRequired";
	
	ParametersStructure.TSP                              = "Object.Warehouse";
	
	Return ParametersStructure;
	
EndFunction

// Parameters:
//  Orders - Array of AnyRef -
//  ActionCode - String -
//  UserMessages - Array of Structure
Procedure BeforePerformingActionsInOrderList(Orders, ActionCode, UserMessages) Export
	
	Query = New Query();
	Query.SetParameter("Orders", Orders);
	Query.Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|		AND NOT Table.ThisIsOrderAsInvoice
		|;
		|SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|	AND Table.ThisIsOrderAsInvoice";
	QueryBatch = Query.ExecuteBatch();
	OrdersAsInvoice = QueryBatch[1].Unload().UnloadColumn("Ref");
	Text = NStr("vi = 'Đối với %1 chưa thể thực hiện lệnh, bởi vì đã tạo chứng từ trong chế độ ""Đơn hàng như hóa đơn""';
				|ru = 'Для %1 команда не может быть выполнена, так как документ был создан в режиме ""Заказ как счет""';
				|en = 'The command cannot be performed for %1 as the document was created in the ""Order as a commercial invoice"" mode'; fa = 'The command cannot be performed for %1 as the document was created in the ""Order as a commercial invoice"" mode';
				|it = 'Для %1 команда не может быть выполнена, так как документ был создан в режиме ""Заказ как счет""';
				|pl = 'The command cannot be performed for %1 as the document was created in the ""Order as a commercial invoice"" mode';
				|tr = '%1 için komut çalıştırılamaz çünkü belge ""Fatura olarak sipariş"" modunda oluşturulmuştur'");
	For Each Ref In OrdersAsInvoice Do 
		UserMessages.Add(New Structure("Text,Ref", StrTemplate(Text, Ref), Ref));
	EndDo;
	If OrdersAsInvoice.Count() > 0 Then
		Orders = QueryBatch[0].Unload().UnloadColumn("Ref");
	EndIf;
	
EndProcedure

// Forms the structure of the document parameters for embedding the document in the software algorithms.
// Parameters:
//  DocumentObject - DocumentObject.RequestForReturnOfGoodsFromCustomer - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.UseEventSubscriptions.BeforePerformingActionsInOrderList = True;
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "SubstituteGoods";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "SubstituteGoodsSupplyOption";
	FormItems.Available           = "SubstituteGoodsAvailable";
	FormItems.Series              = "SubstituteGoodsSeries";
	FormItems.WithAssignment        = "SubstituteGoodsWithAssignment";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.SubstituteGoods.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.SubstituteGoods.Canceled";
	DataPaths.ItemsType = "Object.SubstituteGoods.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.SubstituteGoods.CurrentData.Available";
	Links.NumberOfPackages    = "Items.SubstituteGoods.CurrentData.NumberOfPackages";
	Links.Count            = "Items.SubstituteGoods.CurrentData.Count";
	Links.ShipIfAvailable = "Items.SubstituteGoods.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.SubstituteGoods.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.SubstituteGoods.CurrentData.ItemsType";
	Links.Package              = "Items.SubstituteGoods.CurrentData.Package";
	Links.Products          = "Items.SubstituteGoods.CurrentData.Products";
	Links.SupplyOption    = "Items.SubstituteGoods.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.SubstituteGoods.CurrentData.Warehouse";
	Links.MultipleWarehouses      = "WarehouseGroup_";
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "ShipmentAndReturnReferences";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.RequestForReturnOfGoodsFromCustomer";
	EmbeddingParameters.TableName = "Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Department,
		|	TabPart.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.Status IN(
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
		|		) AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)
		|		) AS ReadyToShip,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				TabPart.DateOfShipment
		|		END AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				UNDEFINED
		|		END AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TabPart
		|		
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	SubstituteGoods = New Structure();
	SubstituteGoods.Insert("LineNumber",        New TypeDescription("Number"));
	SubstituteGoods.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	SubstituteGoods.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	SubstituteGoods.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	SubstituteGoods.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	SubstituteGoods.Insert("WithAssignment",        New TypeDescription("Boolean"));
	SubstituteGoods.Insert("Count",         New TypeDescription("Number"));
	SubstituteGoods.Insert("NumberOfPackages", New TypeDescription("Number"));
	SubstituteGoods.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	SubstituteGoods.Insert("DateOfShipment",       New TypeDescription("Date"));
	SubstituteGoods.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	SubstituteGoods.Insert("Canceled",           New TypeDescription("Boolean"));
	SubstituteGoods.Insert("RowCode",          New TypeDescription("Number"));
	SubstituteGoods.Insert("Department",      New TypeDescription("CatalogRef.BusinessStructure"));
	
	Object = New Structure();
	Object.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Purpose",         New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",             New TypeDescription("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	Object.Insert("Status",             New TypeDescription("EnumRef.StatusesOfRequestsForReturnOfGoodsFromCustomers"));
	Object.Insert("NotShipInInstallments", New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",       New TypeDescription("Date"));
	Object.Insert("Date",               New TypeDescription("Date"));
	Object.Insert("Priority",          New TypeDescription("CatalogRef.Priorities"));
	
	Object.Insert("SubstituteGoods", SubstituteGoods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	Return EmbeddingParameters;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.RequestForReturnOfGoodsFromCustomer, DocumentRef.RequestForReturnOfGoodsFromCustomer - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|BusinessOperation,
		|Date,
		|Number,
		|Partner,
		|Contract,
		|LineOfBusiness,
		|Counterparty,
		|Organization");
		
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
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.RequestForReturnOfGoodsFromCustomer - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,ProductsRecordingAsReceived,Damage,Warehouse,DateOfReceipt,Canceled";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.KeyDetailsOfHeader.Insert("Warehouse", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = Object.DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlAdmissionByOneDate", Object.OneDateReceipt);
	
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
		|	CASE
		|		WHEN &QualityControlAdmissionByOneDate
		|			THEN &QualityControlDateOfReceipt
		|		ELSE Table.DateOfReceipt
		|	END AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.Canceled AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
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
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Partner)";
	
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

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		StandardProcessing = False;
		If FormType = "ObjectForm" Then
			SelectedForm = "SelfServiceWorkplaceDocumentForm";
		ElsIf FormType = "ListForm" Then
			SelectedForm = "SelfServiceWorkplaceListForm";
		EndIf;
	Else
		If FormType = "ListForm" Then
			If Not AccessRight("Read", Metadata.InformationRegisters.SalesOrderStates) Then
				StandardProcessing = False;
				SelectedForm = "ListForm";
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		DocumentNameTemplate = NStr("vi = 'Giấy đề nghị trả hàng từ người nhận ký gửi %1 từ %2';
									|ru = 'Заявка на возврат товаров от комиссионера %1 от %2';
									|en = 'Consignment pick-up request %1 dated %2'; fa = 'Consignment pick-up request %1 dated %2';
									|it = 'Richiesta di reso articoli dal commissionario %1 di %2';
									|pl = 'Wniosek o zwrot towarów od komisanta %1 z dnia %2';
									|tr = '%1 komisyoncudan %2 tarihli malların iadesine ilişkin talep'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		DocumentNameTemplate = NStr("vi = 'Giấy đề nghị trả hàng từ người trông hộ %1 từ %2';
									|ru = 'Заявка на возврат товаров от хранителя %1 от %2';
									|en = 'VMI pick-up request %1 dated %2'; fa = 'VMI pick-up request %1 dated %2';
									|it = 'Richiesta di reso articoli dal magazzino %1 di %2';
									|pl = 'Wniosek o zwrot towarów od opiekuna %1 z dnia %2';
									|tr = '%2 tarihli %1 saklayanından VMI teslimi talebi'");
	Else
		DocumentNameTemplate = NStr("vi = 'Giấy đề nghị trả hàng từ người mua %1 từ %2';
									|ru = 'Заявка на возврат товаров от клиента %1 от %2';
									|en = 'Sales return request %1 dated %2'; fa = 'Sales return request %1 dated %2';
									|it = 'Richiesta di reso articoli dal cliente %1 di %2';
									|pl = 'Wniosek o zwrot towarów od nabywcy %1 z dnia %2';
									|tr = '%1 müşteriden %2 tarihli mal iadesine ilişkin talep'");
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(DocumentNameTemplate,
		Data.Number,
		Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Internal

#Region Supply

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.RequestForReturnOfGoodsFromCustomer - the document for which you need to get the goods
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
	
	Attributes = Common.ObjectAttributesValues(Ref, "Status,Posted,CompensationMethod");
	CheckPossibilityOfEnteringBasedOn(Ref, Attributes.Status, Not Attributes.Posted);
	If Attributes.CompensationMethod <> Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		ErrorText = NStr("vi = 'Có thể nhập trên cơ sở đối với giấy đề nghị trả lại với phương thức ""Đổi hàng"".';
						|ru = 'Ввод на основании возможен для заявок на возврат со способом компенсации ""Заменить товары"".';
						|en = 'You can generate documents only from the Return Requests whose compensation method is ""Replace items"".'; fa = 'You can generate documents only from the Return Requests whose compensation method is ""Replace items"".';
						|it = 'Inserimento in base alla causale è possibile solo per le domande di reso con modalità di compensazione ""Sostituire i prodotti"".';
						|pl = 'Wprowadzenie na podstawie jest możliwe do zleceń na zwrot ze sposobem kompensacji ""Заменить товары"".';
						|tr = '""Ürünleri Değiştir"" telafi yöntemi ile iade talepleri için temelde giriş mümkündür.'");
		Raise ErrorText;
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	Query.Text =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN Goods.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.DateOfShipment AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	
	Query.Execute();
	
EndProcedure

Function DocumentParametersForSoftwareActions(Object, DateOfShipment = Undefined) Export
	
	SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(Object.Terms, Object.Status, , Not Object.ThisIsOrderAsInvoice);
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("EmbeddingParameters",                  AvailableRemainingEmbeddingOptions());
	DocumentParameters.Insert("Object",                                Object);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately",    SecurityOptionAndFlagSeparately);
	
	ProvisionInDocumentsServer.FillInEmbeddingServiceParameters(DocumentParameters);
	Return DocumentParameters;
	
EndFunction

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.RequestForReturnOfGoodsFromCustomer - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	ThereAreChangesInDateOfShipment = ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.SubstituteGoods,
		"DateOfShipment");
		
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ThereAreChangesInDateOfShipment = ThereAreChangesInDateOfShipment Or ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			Changes.UnloadColumn("String"),
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
			
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.SubstituteGoods);
	Attributes = "Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount";
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, Attributes);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Substitutes_);
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "ReturnedGoods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("ReturnedGoods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  Structure - See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Data on the implementation document.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "ImplementationData",, "Object.ReturnedGoods.Purpose");
	DescriptionOfColumns.TermsOfUse_ = "Object.ReturnedGoods.DocumentSalesOfGoodsAndServices <> UNDEFINED
		|	AND Object.ReturnedGoods.DocumentSalesOfGoodsAndServices <> VALUE(Document.CustomerInvoice.EmptyRef)
		|	AND Object.ReturnedGoods.DocumentSalesOfGoodsAndServices <> VALUE(Document.TransferOfGoodsToBailee.EmptyRef)
		|	AND Object.ReturnedGoods.DocumentSalesOfGoodsAndServices <> VALUE(Document.RetailSalesReport.EmptyRef)";
	
	DescriptionOfColumns.DataPaths.Products       = "Object.ReturnedGoods.Products";
	DescriptionOfColumns.DataPaths.Characteristic     = "Object.ReturnedGoods.Characteristic";
	DescriptionOfColumns.DataPaths.DocumentSalesOfGoodsAndServices = "Object.ReturnedGoods.DocumentSalesOfGoodsAndServices";
	
	Return FormTemplate;
	
EndFunction

#EndRegion

#EndRegion

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	RequestForReturnOfGoodsFromCustomer.Date                    AS Period,
	|	RequestForReturnOfGoodsFromCustomer.Currency                  AS Currency,
	|	RequestForReturnOfGoodsFromCustomer.Status                  AS Status,
	|	RequestForReturnOfGoodsFromCustomer.Warehouse                   AS Warehouse,
	|	RequestForReturnOfGoodsFromCustomer.Partner                 AS Partner,
	|	RequestForReturnOfGoodsFromCustomer.Counterparty              AS Counterparty,
	|	RequestForReturnOfGoodsFromCustomer.Organization             AS Organization,
	|	RequestForReturnOfGoodsFromCustomer.PriceIncludesVAT         AS PriceIncludesVAT,
	|	RequestForReturnOfGoodsFromCustomer.BusinessOperation   AS BusinessOperation,
	|	RequestForReturnOfGoodsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	RequestForReturnOfGoodsFromCustomer.Purpose              AS Purpose,
	|	RequestForReturnOfGoodsFromCustomer.Priority               AS Priority,
	|	ISNULL(RequestForReturnOfGoodsFromCustomer.Purpose.RecordsInWarehouseRegisters,FALSE) AS RecordsInWarehouseRegisters,
	|	CASE
	|		WHEN RequestForReturnOfGoodsFromCustomer.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND RequestForReturnOfGoodsFromCustomer.Date >= RequestForReturnOfGoodsFromCustomer.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnGoodsReceipt,
	|	RequestForReturnOfGoodsFromCustomer.Contract AS Contract,
	|	PRESENTATION(RequestForReturnOfGoodsFromCustomer.Contract) AS ContractPresentation,
	|	RequestForReturnOfGoodsFromCustomer.RefundDate AS RefundDate,
	|	RequestForReturnOfGoodsFromCustomer.CompensationMethod AS CompensationMethod,
	|	CASE
	|		WHEN RequestForReturnOfGoodsFromCustomer.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND RequestForReturnOfGoodsFromCustomer.Date >= RequestForReturnOfGoodsFromCustomer.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	
	|	RequestForReturnOfGoodsFromCustomer.Department            AS Department,
	|	RequestForReturnOfGoodsFromCustomer.Manager                 AS Manager,
	|	RequestForReturnOfGoodsFromCustomer.Author                    AS Author,
	|	RequestForReturnOfGoodsFromCustomer.Comment              AS Comment,
	|	RequestForReturnOfGoodsFromCustomer.DocumentAmount           AS DocumentAmount,
	|	RequestForReturnOfGoodsFromCustomer.Posted                 AS Posted,
	|	RequestForReturnOfGoodsFromCustomer.DeletionMark          AS DeletionMark,
	|	RequestForReturnOfGoodsFromCustomer.Number                    AS Number,
	|	RequestForReturnOfGoodsFromCustomer.GoodsReceiptOption    AS GoodsReceiptOption,
	|	RequestForReturnOfGoodsFromCustomer.ThisIsOrderAsInvoice          AS ThisIsOrderAsInvoice,
	|	RequestForReturnOfGoodsFromCustomer.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	CASE
	|		WHEN RequestForReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                    AS ThisIsRefundFromCommissionAgent,
	|	CASE
	|		WHEN RequestForReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                    AS ThisIsReturnFromKeeper
	|
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|WHERE
	|	RequestForReturnOfGoodsFromCustomer.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                               Attributes.Period);
	Query.SetParameter("Currency",                               Attributes.Currency);
	Query.SetParameter("Status",                               Attributes.Status);
	Query.SetParameter("Warehouse",                                Attributes.Warehouse);
	Query.SetParameter("Partner",                              Attributes.Partner);
	Query.SetParameter("RequestForReturnOfGoodsFromCustomer",      DocumentRef);
	Query.SetParameter("Organization",                          Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",                      Attributes.PriceIncludesVAT);
	Query.SetParameter("BusinessOperation",                Attributes.BusinessOperation);
	Query.SetParameter("AdvancedWarehousingOnGoodsReceipt",          Attributes.AdvancedWarehousingOnGoodsReceipt);
	Query.SetParameter("PriceIncludesVAT",                      Attributes.PriceIncludesVAT);
	Query.SetParameter("Contract",                              Attributes.Contract);
	Query.SetParameter("UseShipmentByRowsInSalesOrder",   
		GetFunctionalOption("UseShipmentByRowsInSalesOrder"));
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", Not Attributes.ThisIsOrderAsInvoice);
	Query.SetParameter("RefundDate",          Attributes.RefundDate);
	Query.SetParameter("CompensationMethod",                    Attributes.CompensationMethod);  
	Query.SetParameter("Purpose",                           Attributes.Purpose);
	Query.SetParameter("Priority",                            Attributes.Priority);
	Query.SetParameter("RecordsInWarehouseRegisters",		  Attributes.RecordsInWarehouseRegisters);
	Query.SetParameter("AdvancedWarehousingOnShipment",		      Attributes.AdvancedWarehousingOnShipment);
	Query.SetParameter("Department",                        Attributes.Department);
	Query.SetParameter("Manager",                             Attributes.Manager);
	Query.SetParameter("Author",                                Attributes.Author);
	Query.SetParameter("Comment",                          Attributes.Comment);
	Query.SetParameter("DocumentAmount",                       Attributes.DocumentAmount);
	Query.SetParameter("Posted",                             Attributes.Posted);
	Query.SetParameter("DeletionMark",                      Attributes.DeletionMark);
	Query.SetParameter("Number",                                Attributes.Number);
	Query.SetParameter("GoodsReceiptOption",                Attributes.GoodsReceiptOption);
	Query.SetParameter("Counterparty",                           Attributes.Counterparty);
	Query.SetParameter("LineOfBusiness",              Attributes.LineOfBusiness);	
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("LoyaltyProgram",          Attributes.LoyaltyProgram);
	Query.SetParameter("CurrentDate",                          CurrentUniversalDate());
	Query.SetParameter("ThisIsRefundFromCommissionAgent",             Attributes.ThisIsRefundFromCommissionAgent);
	Query.SetParameter("ThisIsReturnFromKeeper",                Attributes.ThisIsReturnFromKeeper);
	Query.SetParameter("ManagementAccountingCurrency",           SettingsValueCached.ManagementAccountingCurrency());
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	
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
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""ReturnedGoods"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DATETIME(1,1,1) AS VATBasePeriod,
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
	|		WHEN DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND DocumentTable.Ref.ToReturnReusablePackage
	|			AND NOT DocumentTable.Ref.PackageDepositIsRequired
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	""SubstituteGoods"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DATETIME(1,1,1) AS VATBasePeriod,
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
	|		WHEN DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND DocumentTable.Ref.ToReturnReusablePackage
	|			AND NOT DocumentTable.Ref.PackageDepositIsRequired
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Canceled
	|"; 
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextBonusPoints(Query, QueryTexts, Registers, Document)
	
	If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
		Return "";
	EndIf;
	
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
	
	QueryText = 
	"SELECT
	|	BonusPoints.Period                      AS Period,
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
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING 
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	QueryText = 
	"SELECT
	|	BEGINOFPERIOD(&Period, DAY)                AS Period,
	|	&CurrentDate                                AS DateToProcess,
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&LoyaltyProgram                AS LoyaltyProgram,
	|	&Partner                                    AS Partner,
	|	TabularSection.AmountOfBonusPointsToDeduction AS Accrued,
	|	0                                           AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.AmountOfBonusPointsToDeduction <> 0
	|	AND NOT TabularSection.Canceled
	|	AND NOT TabularSection.Ref.ThisIsOrderAsInvoice
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	UNDEFINED                                 AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.Ref                        AS OrderDocument,
	|	UNDEFINED                                 AS Contract,
	|	UNDEFINED                                 AS Terms,
	|	DataSource.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	DataSource.DateOfReceipt               AS Date,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE DataSource.Products
	|	END                                        AS Products,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE DataSource.Characteristic
	|	END                                        AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                 AS ControlledLotReference,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DataSource.Series                         AS Series,
	|	FALSE                                         AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	DataSource.Ref.Partner                AS Sender,
	|	DataSource.Ref.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	FALSE                                         AS ThisIsAnInvoice,
	|	FALSE                                         AS ReceiptUnderOrders
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND NOT DataSource.Canceled
	|	AND DataSource.Ref.Status IN (
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))";
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.ItIsRequiredToTakeIntoAccountRequirementsForIssuingInvoicesByOrder = True;
	
	WarehousesServer.ScheduleDeliveryOfProductsWithSettings(Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		MethodParameters);
	
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
	|	&Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|					VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					)
	|			OR GoodsTable.BatchesIndicationStatus IN(10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	CASE
	|		WHEN GoodsTable.Canceled
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Canceled)
	|		ELSE VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
	|	END AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS Sum,
	|	CASE
	|		WHEN GoodsTable.Canceled
	|			THEN GoodsTable.CancellationReason
	|		ELSE VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef)
	|	END AS CancellationReason
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.DateOfShipment AS Period,
	|	&Ref AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|			THEN CASE
	|				WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|					THEN GoodsTable.Warehouse
	|				ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|			END
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|					VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|					)
	|			OR TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|				AND GoodsTable.BatchesIndicationStatus IN(10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.AmountIncludingVAT AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip))
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
	|	AND NOT GoodsTable.Canceled
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|UNION ALL
	|
	|SELECT
	|	TableReturnedItems.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	TableReturnedItems.Ref AS ReferenceOrder,
	|	CASE
	|		WHEN TableReturnedItems.Damage
	|			THEN TableReturnedItems.ProductsRecordingAsReceived
	|		ELSE TableReturnedItems.Products
	|	END AS Products,
	|	CASE
	|		WHEN TableReturnedItems.Damage
	|			THEN TableReturnedItems.CharacteristicRecordingAsReceived
	|		ELSE TableReturnedItems.Characteristic
	|	END AS Characteristic,
	|	TableReturnedItems.RowCode AS RowCode,
	|	CASE
	|		WHEN TableReturnedItems.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN TableReturnedItems.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	TableReturnedItems.Count AS Count,
	|	TableReturnedItems.AmountIncludingVAT AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS TableReturnedItems
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RequestedForReturn),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving))
	|WHERE
	|	TableReturnedItems.Ref = &Ref
	|	AND NOT TableReturnedItems.Canceled
	|	AND &Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|	AND &BusinessOperation NOT IN (VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|		VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|
	|UNION ALL
	|
	|SELECT
	|	TableReturnedItems.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	TableReturnedItems.Ref AS ReferenceOrder,
	|	TableReturnedItems.Products AS Products,
	|	TableReturnedItems.Characteristic AS Characteristic,
	|	TableReturnedItems.RowCode AS RowCode,
	|	CASE
	|		WHEN TableReturnedItems.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN TableReturnedItems.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Canceled) AS Factor,
	|	TableReturnedItems.Count AS Count,
	|	TableReturnedItems.AmountIncludingVAT AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS TableReturnedItems
	|WHERE
	|	TableReturnedItems.Ref = &Ref
	|	AND TableReturnedItems.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	TableReturnedItems.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	TableReturnedItems.Ref AS ReferenceOrder,
	|	CASE
	|		WHEN TableReturnedItems.Damage
	|			THEN TableReturnedItems.ProductsRecordingAsReceived
	|		ELSE TableReturnedItems.Products
	|	END AS Products,
	|	CASE
	|		WHEN TableReturnedItems.Damage
	|			THEN TableReturnedItems.CharacteristicRecordingAsReceived
	|		ELSE TableReturnedItems.Characteristic
	|	END AS Characteristic,
	|	CASE
	|		WHEN &ThisIsRefundFromCommissionAgent
	|		AND NOT CounterpartyContracts.Ref IS NULL
	|		AND CounterpartyContracts.ConsignmentSales25
	|			THEN 0
	|		WHEN &ThisIsReturnFromKeeper
	|			THEN 0
	|		ELSE TableReturnedItems.RowCode
	|	END AS RowCode,
	|	CASE
	|		WHEN TableReturnedItems.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN TableReturnedItems.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	TableReturnedItems.Count AS Count,
	|	TableReturnedItems.AmountIncludingVAT AS Sum,
	|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS TableReturnedItems
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON CounterpartyContracts.Ref = TableReturnedItems.Ref.Contract
	|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RequestedForReturn),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving))
	|WHERE
	|	TableReturnedItems.Ref = &Ref
	|	AND NOT TableReturnedItems.Canceled
	|	AND &Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|		VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPaymentControl(Query, QueryTexts)
	
	RegisterName = "TTPaymentControl";
	
	QueryText = 
		"SELECT
		|    MIN(
		|        CASE
		|            WHEN HeaderData_.Status  IN(
		|                VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|                VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)) THEN
		|                   
		|                    NOT GoodsTable.SupplyOption IN(
		|                        VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|                        VALUE(Enum.SupplyOptions.ToSupply),
		|                        VALUE(Enum.SupplyOptions.Ship))
		|                ELSE
		|                    TRUE
		|            END) AS ExcludeAdvancePaymentDuringControl,
		|    MIN(
		|        CASE
		|            WHEN HeaderData_.Status  IN(
		|                VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|                VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)) THEN
		|                   
		|                    GoodsTable.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|                ELSE
		|                    TRUE
		|            END) AS ExcludePrepaymentDuringControl
		|INTO TTPaymentControl
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
		|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS HeaderData_
		|		ON GoodsTable.Ref = HeaderData_.Ref
		|WHERE
		|	GoodsTable.Ref IN (&Ref)";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref							AS Ref,
	|	HeaderData_.Date								AS Period,
	|	DocumentGoods.Ref							AS OrderDocument,
	|	UNDEFINED									AS Invoice,
	|	FALSE											AS Patch,
	|	UNDEFINED									AS CorrectedDocument,
	|	HeaderData_.Partner								AS Recipient,
	|	DocumentGoods.Warehouse							AS Warehouse,
	|	DocumentGoods.Products					AS Products,
	|	DocumentGoods.Characteristic					AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END											AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series							AS Series,
	|	DocumentGoods.BatchesIndicationStatus				AS BatchesIndicationStatus,
	|	DocumentGoods.Count						AS Count,
	|	FALSE											AS ExceedingOrder,
	|	FALSE											AS Canceled,
	|	FALSE											AS ThisIsAnInvoice,
	|	FALSE											AS ShipmentByOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS DocumentGoods
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND NOT DocumentGoods.Canceled
	|	AND (DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|			OR DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
	|	AND HeaderData_.Status IN(
	|				VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
	|				VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn))
	|	AND DocumentGoods.Count <> 0";
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.DateOfShipment		AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS DocumentGoods
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND NOT DocumentGoods.Canceled
	|	AND HeaderData_.Status IN (
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.RequestForReturnOfGoodsFromCustomer";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("RecordsInWarehouseRegisters",
		"ISNULL(GoodsTable.Ref.Purpose.RecordsInWarehouseRegisters, FALSE)");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnGoodsReceipt",
		"	CASE
		|		WHEN GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND GoodsTable.Ref.Date >= GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("ThisIsRefundFromCommissionAgent",
		"	CASE
		|		WHEN TableReturnedItems.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("ThisIsReturnFromKeeper",
		"	CASE
		|		WHEN TableReturnedItems.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
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

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

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
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	FALSE                     AS ReverseTransactionCorrection,
	|	UNDEFINED             AS ReversedDocument,
	|	UNDEFINED             AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	&Priority               AS Priority";
	
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
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	If Not DocumentsPosting.ThereIsQueryTable("TTPaymentControl", QueryTexts) Then
		QueryTextTTPaymentControl(Query, QueryTexts);
	EndIf;
	
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
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	Table.DateOfShipment                                                     AS DateOfShipment,
		|	Table.PaymentOption                                                    AS PaymentOption,
		|	Table.PaymentAmount + Table.PackageDepositValue                         AS AmountDue,
		|	Table.MeasuringGoodsVarianceAmount                                     AS MeasuringGoodsVarianceAmount,
		|	CASE
		|		WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
		|			THEN PaymentControl.ExcludeAdvancePaymentDuringControl
		|		WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|			THEN PaymentControl.ExcludePrepaymentDuringControl
		|		WHEN Table.Ref.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|				VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|			THEN TRUE
		|		ELSE TRUE
		|	END                                                                   AS ExcludeDuringControl
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS Table
		|		LEFT JOIN TTPaymentControl AS PaymentControl
		|		ON TRUE
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
		|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|	AND Table.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)";
	
	TextShipmentPlans =
		"SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	ENDOFPERIOD(Table.DateOfShipment, DAY)                                 AS DateOfShipment,
		|	Table.AmountIncludingVAT                                                        AS IncreaseToBeSHIPPED,
		|	CASE WHEN Table.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|			THEN Table.AmountIncludingVAT
		|		ELSE 0
		|	END                                                                    AS IncreaseShipping,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod
		|	
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Canceled
		|	AND Table.Ref.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
		|				VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|				VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|				VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|	AND NOT Table.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR Table.Ref.PackageDepositIsRequired
		|		OR NOT Table.Ref.ToReturnReusablePackage)
		|	AND Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND Table.Ref.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods)";
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans);
	
	TextReturn = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Ref.Organization             AS Organization,
		|	Table.Ref.Partner                 AS Partner,
		|	
		|	Table.Ref.ARAPObject          AS ARAPObject,
		|	Table.Ref.Currency                  AS ARAPCurrency,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	0                                      AS AmountARAP,
		|	0                                      AS Sum,
		|	Table.AmountIncludingVAT                      AS AmountDue,
		|	
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	Table.Ref.Date                    AS DateOfCourse,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder)  AS BusinessOperation,
		|	UNDEFINED                           AS CashFlowItem
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|	AND Table.Ref.CompensationMethod = VALUE(Enum.CompensationMethodsForReturnsOfGoods.ReturnCash)
		|	AND Table.Ref.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR Table.Ref.PackageDepositIsRequired
		|		OR NOT Table.Ref.ToReturnReusablePackage)
		|	AND NOT Table.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
		
	ARAPAccountingPostingCustomers.CarryingOutReturnOfGoodsFromCustomer(Query, QueryTexts, Registers, TextReturn); 
	
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
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
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
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|		AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
	
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
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn))
		|		AND TabPart.SupplyOption IN(
		|			VALUE(Enum.SupplyOptions.Ship),
		|			VALUE(Enum.SupplyOptions.FromWarehouse))";
	
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
		|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|			VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
		|	AND NOT TabPart.Canceled";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If UserRightsCached.ThisIsPartner() Then
		
		// Request for refund
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ReturnRequest";
		PrintCommand.Presentation = NStr("vi = 'Giấy đề nghị trả hàng';
										|ru = 'Заявка на возврат';
										|en = 'Return request'; fa = 'درخواست برگشت';
										|it = 'Domanda di reso';
										|pl = 'Wniosek o zwrot pieniędzy';
										|tr = 'İade talebi'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax';
										|ru = 'Счет на оплату с факсимиле';
										|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
										|it = 'Fattura di pagamento in facsimile';
										|pl = 'Rachunek do płatności z faksymile';
										|tr = 'Kaşeli ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		
		Return;
		
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Request for refund
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ReturnRequest";
		PrintCommand.Presentation = NStr("vi = 'Giấy đề nghị trả hàng';
										|ru = 'Заявка на возврат';
										|en = 'Return request'; fa = 'درخواست برگشت';
										|it = 'Domanda di reso';
										|pl = 'Wniosek o zwrot pieniędzy';
										|tr = 'İade talebi'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Request for a refund (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "RequestForRefundWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Giấy đề nghị trả hàng (không hiển thị chiết khấu)';
										|ru = 'Заявка на возврат (не выводить скидки)';
										|en = 'Return request (do not display discounts)'; fa = 'Return request (do not display discounts)';
										|it = 'Domanda di reso (non visualizzare gli sconti)';
										|pl = 'Zlecenie na zwrot (nie wyprowadzaj rabaty)';
										|tr = 'İade talebi (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Request for a refund (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "ReturnRequest";
		PrintCommand.Presentation = NStr("vi = 'Giấy đề nghị trả hàng (hiển thị chiết khấu)';
										|ru = 'Заявка на возврат (выводить скидки)';
										|en = 'Return request (display discounts)'; fa = 'Return request (display discounts)';
										|it = 'Domanda di reso (visualizzare gli sconti)';
										|pl = 'Zlecenie na zwrot (wyprowadzaj rabaty)';
										|tr = 'İade talebi (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
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
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceForPaymentWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
										|ru = 'Счет на оплату (не выводить скидки)';
										|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
										|it = 'Fattura di pagamento (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
										|ru = 'Счет на оплату (выводить скидки)';
										|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
										|it = 'Fattura di pagamento (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax';
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
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceWithFacsimileWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
										|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
										|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (выводить скидки)';
										|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
										|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If Constants.UseInternationalPrintingForms.Get() Then
			
		// Proforma invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceEn";
		PrintCommand.Presentation = NStr("vi = 'Proforma invoice (en)';
										|ru = 'Proforma invoice (en)';
										|en = 'Proforma invoice (en)'; fa = 'Proforma invoice (en)';
										|it = 'Proforma invoice (en)';
										|pl = 'Proforma invoice (en)';
										|tr = 'Proforma invoice (en)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;
	
	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
	StatusOfApplication = New Array;
	StatusOfApplication.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply);
	StatusOfApplication.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip);
	StatusOfApplication.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed);
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														StatusOfApplication,
														DataCompositionComparisonType.InList);
	
	RequestForReturnOfGoodsFromCustomerLocalization.AddPrintCommands(PrintCommands);
	
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
	
	SynonymForReturnRequestTemplate = NStr("vi = 'Giấy đề nghị trả hàng';
											|ru = 'Заявка на возврат';
											|en = 'Return request'; fa = 'درخواست برگشت';
											|it = 'Domanda di reso';
											|pl = 'Wniosek o zwrot pieniędzy';
											|tr = 'İade talebi'");
	If CommonClientServer.StructureProperty(PrintParameters, "UseSynonymForKit", False) Then
		SynonymForReturnRequestTemplate = PrintParameters.SynonymForTemplateForKit;
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReturnRequest") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ReturnRequest",
			SynonymForReturnRequestTemplate,
			GeneratePrintedRefundRequestForm(ObjectsArray, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"Document.RequestForReturnOfGoodsFromCustomer.PF_MXL_ReturnRequest");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("ReturnRequest"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "RequestForRefundWithoutDiscounts") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"RequestForRefundWithoutDiscounts",
			SynonymForReturnRequestTemplate,
			GeneratePrintedRefundRequestForm(ObjectsArray, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"Document.RequestForReturnOfGoodsFromCustomer.PF_MXL_ReturnRequest");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("ReturnRequest"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
		
	RequestForReturnOfGoodsFromCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function GeneratePrintedRefundRequestForm(ObjectsArray, PrintObjects, PrintParameters, LanguageCode = Undefined)
	
	SetPrivilegedMode(True);
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Query = New Query;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	Query.Text = 
	"SELECT
	|	ReturnRequest.Ref AS Ref,
	|	ReturnRequest.Number AS Number,
	|	ReturnRequest.Date AS Date,
	|	ReturnRequest.Organization AS Organization,
	|	CASE
	|		WHEN ReturnRequest.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR ReturnRequest.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|				OR ReturnRequest.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	ReturnRequest.Organization.Prefix AS Prefix,
	|	ReturnRequest.Counterparty AS Counterparty,
	|	ReturnRequest.BankAccount AS BankAccount,
	|	ReturnRequest.BankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	ReturnRequest.PriceIncludesVAT AS PriceIncludesVAT,
	|	ReturnRequest.Currency AS Currency,
	|	ReturnRequest.Manager.Individual AS Manager,
	|	ReturnRequest.AdditionalInformation AS AdditionalInformation,
	|	ReturnRequest.DocumentAmount AS AmountToReturn,
	|	CASE
	|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ReturnFromCommissionAgent,
	|	CASE
	|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ReturnFromRetailCustomer
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
	|WHERE
	|	ReturnRequest.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                                                 AS ProductsInSet,
	|	Table.ItemVariantOfSet                                               AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.Damage AS Damage,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Canceled AS Canceled,
	|	Table.Price AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	CASE
	|		WHEN
	|			Table.Ref.ToReturnReusablePackage
	|			AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|INTO Goods
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|	AND NOT Table.Canceled	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)                       AS Sum,
	|	SUM(Table.VATAmount)                    AS VATAmount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
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
	|	Goods.VATRate AS VATRate,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                                AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	NULL AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
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
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE null
	|		END) AS VATRate,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
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
	|
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                                 AS Sum,
	|	Table.VATAmount                              AS VATAmount,
	|	TemporaryTableSetsOptional.VATRate AS VATRate
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
	|	Table.Ref                            AS Ref,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                        AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Table.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Table.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Table.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Table.TheseAreComponents                          AS TheseAreComponents,
	|	Table.IsRecordsSet                                  AS IsRecordsSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	CASE
	|		WHEN Table.Damage
	|			THEN Table.ProductsRecordingAsReceived
	|		ELSE Table.Products
	|	END AS Products,
	|	CASE
	|		WHEN Table.Damage
	|			THEN ISNULL(CharacteristicsOfProductDescriptionOfPresentation.DescriptionFull, ISNULL(Table.CharacteristicRecordingAsReceived.DescriptionFull, """"))
	|		ELSE ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Table.Characteristic.DescriptionFull, """"))
	|	END AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Table.Package
	|	END AS Package,
	|	Table.Products.Code AS Code,
	|	Table.Products.SKU AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Table.Products.DescriptionFull) AS DescriptionFull,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Table.Products.UnitOfMeasure)
	|					ELSE Table.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Table.Package)
	|					ELSE Table.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|	Table.NumberOfPackages AS Count,
	|	Table.Price AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	Table.ThisIsReusablePackage AS ThisIsReusablePackage
	|FROM
	|(
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
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
	|		Table.Products,
	|		Table.ProductsRecordingAsReceived,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATAmount,
	|		Table.VATRate,
	|		Table.Characteristic,
	|		Table.CharacteristicRecordingAsReceived,
	|		Table.Package,
	|		Table.ThisIsReusablePackage,
	|		Table.Damage
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
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		UNDEFINED,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|				(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE
	|				0
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.VATRate,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		UNDEFINED,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		FALSE,
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Table
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Table.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Table.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Table.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Table.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductDescriptionOfPresentation
	|	ON (Table.CharacteristicRecordingAsReceived = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Table.LineNumber,
	|	IsRecordsSet DESC
	|;
	|DROP Goods
	|;
	|DROP TemporaryTableSets
	|;
	|DROP TemporaryTableSetsPreparation
	|;
	|DROP TemporaryTableSetsOptionalPartOne
	|;
	|DROP TemporaryTableSetsOptionalPartTwo
	|;
	|DROP TemporaryTableSetsOptional
	|;
	|DROP	VariousGoods_
	|;
	|
	|SELECT
	|
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                                                 AS ProductsInSet,
	|	Table.ItemVariantOfSet                                               AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Price
	|		ELSE Table.Sum/Table.NumberOfPackages 
	|	END AS Price,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Table.ManualDiscount + Table.DiscountMarkupAmount
	|		ELSE 0 
	|	END AS DiscountAmount,
	|	Table.Sum + Table.ManualDiscount + Table.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	Table.Package,
	|	Table.DateOfShipment,
	|	Table.Canceled AS Canceled,
	|	Table.Content AS Content,
	|	CASE
	|		WHEN
	|			Table.Ref.ToReturnReusablePackage
	|			AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|INTO Goods
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|	AND NOT Table.Canceled
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)                       AS Sum,
	|	SUM(Table.VATAmount)                    AS VATAmount,
	|	SUM(Table.DiscountAmount)                 AS DiscountAmount,
	|	SUM(Table.Sum - Table.DiscountAmount) AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
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
	|	Goods.VATRate AS VATRate,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|
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
	|	NULL AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
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
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE null
	|		END) AS VATRate,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
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
	|
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                                 AS Sum,
	|	Table.VATAmount                              AS VATAmount,
	|	Table.DiscountAmount                           AS DiscountAmount,
	|	Table.AmountWithoutADiscount                        AS AmountWithoutADiscount,
	|	TemporaryTableSetsOptional.VATRate AS VATRate
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
	|	Table.Ref                            AS Ref,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                        AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Table.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Table.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Table.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Table.TheseAreComponents                          AS TheseAreComponents,
	|	Table.IsRecordsSet                                  AS IsRecordsSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Products.Code AS Code,
	|	Table.Products.SKU AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Table.Products.DescriptionFull) AS DescriptionFull,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Table.Products.UnitOfMeasure)
	|					ELSE Table.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Table.Package)
	|					ELSE Table.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|	Table.NumberOfPackages AS Count,
	|	Table.Price,
	|	Table.DiscountAmount,
	|	Table.AmountWithoutADiscount,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	Table.DateOfShipment AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Table.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Table.Package.Description
	|	END AS Package,
	|	Table.Canceled AS Canceled,
	|	Table.Content AS Content,
	|	Table.ThisIsReusablePackage
	|FROM
	|(
	|	SELECT
	|		Table.Ref,
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
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
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
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.ThisIsReusablePackage,
	|		Table.VATRate,
	|		Table.DateOfShipment,
	|		Table.Canceled,
	|		Table.Content
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
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|			TemporaryTableSets.AmountWithoutADiscount / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|		ELSE
	|			0
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		FALSE,
	|		TemporaryTableSets.VATRate,
	|		UNDEFINED,
	|		FALSE,
	|		""""
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Table
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Table.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Table.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Table.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Table.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Table.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Table.Package",
		"Table.Products"));
	
	FillInTabularDocumentOfReturnRequest(SpreadsheetDocument, Query, PrintObjects, LanguageCode);
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure FillInTabularDocumentOfReturnRequest(SpreadsheetDocument, Query, PrintObjects, LanguageCode)
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_RequestForReturnOfGoodsFromCustomer_ReturnRequest";
	
	RequestResultsPackage = Query.ExecuteBatch();
	QueryResult = RequestResultsPackage[0]; // QueryResult
	PrintData = QueryResult.Select();
	ResultsForReturnedProductsTabularSection = RequestResultsPackage[8];
	ResultForTablePartReplacementProducts   = RequestResultsPackage[RequestResultsPackage.Count() - 1];
	
	UseManualDiscounts         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UseAutomaticDiscounts = GetFunctionalOption("UseDiscountsMarkupsInSales");
	
	FirstDocument = True;
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Template = PrintManagement.PrintFormTemplate("Document.RequestForReturnOfGoodsFromCustomer.PF_MXL_ReturnRequest", LanguageCode);
	
	AreaTitleReplacementCorrection = Template.GetArea("TitleReplacementCorrection");
	AreaTitleReturnCorrection = Template.GetArea("TitleReturnCorrection");
	AreaHeaderReplacement = Template.GetArea("TitleReplacement");
	AreaHeaderReturn = Template.GetArea("TitleRefund");
	
	ScopeOfApplication_6 = Template.GetArea("Vendor");
	ScopeOfApplication_5 = Template.GetArea("Customer");
	AreaAdditionalInformation = Template.GetArea("AdditionalInformation");
	OrderBasementArea = Template.GetArea("BasementOfOrder");
	
	If Not ValueIsFilled(NameOfCodeColumn) Then
		// If it is not necessary to display a column for displaying codes
		// 		, we will expand the column of goods by the width of the column of codes.
		AreaOfFirstColumnOfProduct = Template.Area("FirstColumnOfGoods");
		AreaOfFirstColumnOfProduct.ColumnWidth = AreaOfFirstColumnOfProduct.ColumnWidth + 12;
	EndIf;
	
	While PrintData.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		Else
			FirstDocument = False;
		EndIf;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		TheStructureOfTheSearch      = New Structure("Ref", PrintData.Ref);
		SubstituteGoodsTS   = ResultForTablePartReplacementProducts.Unload();
		ReturnedGoodsTS = ResultsForReturnedProductsTabularSection.Unload();
		
		ThereAreMargins = False;
		ThereAreDiscounts  = False;
		Goods = SubstituteGoodsTS.FindRows(TheStructureOfTheSearch);
		
		Discounts = New Structure;
		
		If UseManualDiscounts Or UseAutomaticDiscounts Then
			
			If TypeOf(Goods) = Type("ValueTable") Or TypeOf(Goods) = Type("Array") Then
				
				For Each RowOfGoods In Goods Do
					If RowOfGoods.DiscountAmount>0 Then
						ThereAreDiscounts = True;
						Break;
					EndIf;
				EndDo;
				
				For Each RowOfGoods In Goods Do
					If RowOfGoods.DiscountAmount<0 Then
						ThereAreMargins = True;
						Break;
					EndIf;
				EndDo;
				
			ElsIf TypeOf(Goods) = Type("QueryResultSelection") Then
				
				While Goods.Next() Do
					If Goods.DiscountAmount>0 Then
						ThereAreDiscounts = True;
					ElsIf Goods.DiscountAmount<0 Then
						ThereAreMargins = True;
					EndIf;
				EndDo;
				
			EndIf;
			
			If ThereAreMargins And ThereAreDiscounts Then
				Discounts.Insert("ColumnPostfix", "DiscountMarkup");
			ElsIf ThereAreMargins And Not ThereAreDiscounts Then
				Discounts.Insert("ColumnPostfix", "Markup");
			ElsIf ThereAreDiscounts Then
				Discounts.Insert("ColumnPostfix", "Discount");
			EndIf;
			
		EndIf;
		
		Discounts.Insert("ThereAreDiscounts", ThereAreMargins Or ThereAreDiscounts);
		Discounts.Insert("ThereIsDiscount", ThereAreDiscounts);
		Discounts.Insert("ThereIsMarkUp", ThereAreMargins);
		
		ThereAreDiscounts = Discounts.ThereAreDiscounts;
		
		DataCorrection = New Structure("NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
		FillPropertyValues(DataCorrection, PrintData);
		CorrectiveDocument = ValueIsFilled(DataCorrection.NumberOfDocumentBeingCorrected) 
								And ValueIsFilled(DataCorrection.DateOfDocumentBeingCorrected);
		
		NumberForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(PrintData.Number);
		If CorrectiveDocument Then
			NumberOfDocumentToBeCorrectedForPrinting = ObjectsPrefixesClientServer.NumberForPrinting(
			DataCorrection.NumberOfDocumentBeingCorrected);
		EndIf;
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("DocumentNumber", NumberForPrinting);
		HeaderDataStructure_1.Insert("DocumentDate", Format(PrintData.Date, StrTemplate("L=%1;DLF=DD", LanguageCode)));
		
		ThereAreReplacementProducts = SubstituteGoodsTS.FindRows(New Structure("Canceled, Ref", False, PrintData.Ref)).Count() > 0;
		If CorrectiveDocument Then
			
			HeaderDataStructure_1.Insert("NumberOfDocumentBeingCorrected", NumberOfDocumentToBeCorrectedForPrinting);
			HeaderDataStructure_1.Insert("DateOfDocumentBeingCorrected", Format(DataCorrection.DateOfDocumentBeingCorrected, StrTemplate("L=%1;DLF=DD", LanguageCode)));
			
			HeaderAreaForOutput = ?(ThereAreReplacementProducts, AreaTitleReplacementCorrection, AreaTitleReturnCorrection);
			
		Else
			
			HeaderAreaForOutput = ?(ThereAreReplacementProducts, AreaHeaderReplacement, AreaHeaderReturn);
			
		EndIf;
		
		HeaderAreaForOutput.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderAreaForOutput, PrintData.Ref);
		SpreadsheetDocument.Put(HeaderAreaForOutput);
		
		// Output of the supplier area
		InformationAboutLegalEntity = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date);
		
		If Not ValueIsFilled(LanguageCode)
			Or LanguageCode = Common.DefaultLanguageCode() Then
			
			NameOfAttributeOfName = "FullDescr";
			AttributeNameAddress = "LegalAddress";
			
		Else
			
			NameOfAttributeOfName = ?(ValueIsFilled(InformationAboutLegalEntity.DescriptionInternational), 
											"DescriptionInternational",
											"FullDescr");
											
			AttributeNameAddress = ?(ValueIsFilled(InformationAboutLegalEntity.International_Address),
									"International_Address",
									"LegalAddress");
			
		EndIf;
		
		Attributes = StrTemplate("%1,TIN,CRTR,%2,Phones,", NameOfAttributeOfName, AttributeNameAddress);
		
		DataStructureProvider = New Structure;
		DataStructureProvider.Insert("SupplierPresentation", 
			PrintFormGeneration.OrganizationDescription(InformationAboutLegalEntity, Attributes));
		ScopeOfApplication_6.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(ScopeOfApplication_6);
		
		// Output of the buyer's area
		InformationAboutLegalEntity = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date);
		
		If Not ValueIsFilled(LanguageCode)
			Or LanguageCode = Common.DefaultLanguageCode() Then
			
			NameOfAttributeOfName = "FullDescr";
			AttributeNameAddress = "LegalAddress";
			
		Else
			
			NameOfAttributeOfName = ?(ValueIsFilled(InformationAboutLegalEntity.DescriptionInternational), 
											"DescriptionInternational",
											"FullDescr");
											
			AttributeNameAddress = ?(ValueIsFilled(InformationAboutLegalEntity.International_Address),
									"International_Address",
									"LegalAddress");
			
		EndIf;
		
		Attributes = StrTemplate("%1,TIN,CRTR,%2,Phones,", NameOfAttributeOfName, AttributeNameAddress);
		
		CustomerDataStructure = New Structure;
		CustomerDataStructure.Insert("BuyerPresentation",
			PrintFormGeneration.OrganizationDescription(InformationAboutLegalEntity, Attributes));
		ScopeOfApplication_5.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(ScopeOfApplication_5);
		
		// Output of the returned goods table area
		OutputParameters = New Structure;
		OutputParameters.Insert("OutputCodes", OutputCodes);
		OutputParameters.Insert("OnlyQuantity", PrintData.ReturnFromCommissionAgent);
		OutputParameters.Insert("ConsiderVAT", PrintData.ConsiderVAT);
		OutputParameters.Insert("PriceIncludesVAT", PrintData.PriceIncludesVAT);
		OutputParameters.Insert("OutputBasementVAT", False);
		OutputParameters.Insert("ThereAreDiscounts", False);
		OutputParameters.Insert("LanguageCode", LanguageCode);
		
		DisplayTableOfProductsInTableDocumentOfReturnRequest(
			SpreadsheetDocument,
			Template,
			ReturnedGoodsTS,
			NameOfCodeColumn,
			"ReturnedProduct",
			PrintData,
			OutputParameters
		);
		
		// Output of the replacement goods table area
		If ThereAreReplacementProducts Then
			
			OutputParameters = New Structure;
			OutputParameters.Insert("OutputCodes", OutputCodes);
			OutputParameters.Insert("OnlyQuantity", False);
			OutputParameters.Insert("ConsiderVAT", PrintData.ConsiderVAT);
			OutputParameters.Insert("PriceIncludesVAT", PrintData.PriceIncludesVAT);
			OutputParameters.Insert("OutputBasementVAT", True);
			OutputParameters.Insert("ThereAreDiscounts", Not PrintData.ReturnFromCommissionAgent And ThereAreDiscounts);
			OutputParameters.Insert("Discounts", Discounts);
			OutputParameters.Insert("LanguageCode", LanguageCode);
			
			DisplayTableOfProductsInTableDocumentOfReturnRequest(
				SpreadsheetDocument,
				Template,
				SubstituteGoodsTS,
				NameOfCodeColumn,
				"ReplacementProduct",
				PrintData,
				OutputParameters
			);
			
		EndIf;
		
		// Output of additional information
		If ValueIsFilled(PrintData.AdditionalInformation) Then
			AreaAdditionalInformation.Parameters.Fill(PrintData);
			SpreadsheetDocument.Put(AreaAdditionalInformation);
		EndIf;
		
		// Output of the order basement
		DataStructureManager = New Structure;
		DataStructureManager.Insert("Manager", PersonsTM.IndividualShortName(PrintData.Manager, PrintData.Date));
		OrderBasementArea.Parameters.Fill(DataStructureManager);
		SpreadsheetDocument.Put(OrderBasementArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
EndProcedure

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

// Adds a table of products to the return request table document
//
// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument
//	Template - SpreadsheetDocument
//	Table - ValueTable - Table of values from the request for the document requesterreferences from the Client
//	NameOfCodeColumn - String - Name of the additional code column, "Undefined" if the column does not need to be output
//	ProductColumnName - String - Name of the item column
//	PrintData - QueryResultSelection - Selection based on document data
//	OutputParameters - Structure - The structure of the output parameters. Keys: "Vivaticket", "Tollcollect, Acetylating, Enablecheats, Vivalicious", "Elskede".
//
Procedure DisplayTableOfProductsInTableDocumentOfReturnRequest(SpreadsheetDocument,
	Template, Table, NameOfCodeColumn, ProductColumnName,
	PrintData, OutputParameters)
	
	Currency = PrintData.Currency;
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();	
	
	TheseAreDiscountedVATLines = False;
	TheseAreDiscountedLines = False;
	
	If OutputParameters.OnlyQuantity Then
		
		TableHeader = ?(ProductColumnName = "ReturnedProduct", "HeaderOfTableWithoutAmountsReturned", "HeaderOfTableWithoutAmountsReplacing");
		
		TableFooter = "BasementTablesWithoutSums";
		TableRow = "TableRowWithoutSums";
		TableRowSet = "TableRowWithoutSumsSet";
		TableRowComponents = "TableRowWithoutSumsComponents";
	Else
		If OutputParameters.ConsiderVAT And ShowVAT And OutputParameters.ThereAreDiscounts Then
			
			TableHeader = ?(ProductColumnName = "ReturnedProduct", "TableHeaderWithVATWithDiscountRefundable", "TableHeaderWithVATWithDiscountReplacement");
			
			TableFooter = "BasementTableWithVATAtDiscount";
			TableRow = "RowOfTableWithVATAtDiscount";
			TableRowSet = "RowOfTableWithVATAtDiscountSet";
			TableRowComponents = "RowOfTableWithVATAtDiscountComponents";
			
			TheseAreDiscountedVATLines = True;
			
		ElsIf OutputParameters.ConsiderVAT And ShowVAT And Not OutputParameters.ThereAreDiscounts Then
			
			TableHeader = ?(ProductColumnName = "ReturnedProduct", "TableHeaderWithVATReturnable", "TableHeaderWithVATReplacement");
			
			TableFooter = "BasementTableWithVAT";
			TableRow = "TableRowWithVAT";
			TableRowSet = "TableRowWithVATSet";
			TableRowComponents = "TableRowWithVATComponents";
			
		ElsIf Not (OutputParameters.ConsiderVAT And ShowVAT) And OutputParameters.ThereAreDiscounts Then
			
			TableHeader = ?(ProductColumnName = "ReturnedProduct", "TableHeaderWithDiscountRefundable", "TableHeaderWithDiscountReplacement");
			
			TableFooter = "BasementTablesAtDiscount";
			TableRow = "TableRowWithDiscount";
			TableRowSet = "TableRowWithDiscountSet";
			TableRowComponents = "TableRowWithDiscountComponents";
			
			TheseAreDiscountedLines = True;
			
		Else // without VAT and without discount
			
			TableHeader = ?(ProductColumnName = "ReturnedProduct", "TableHeaderReturnable", "TableHeaderReplacement");
			
			TableFooter = "TableFooter";
			TableRow = "TableRow";
			TableRowSet = "TableRowSet";
			TableRowComponents = "TableRowComponents";
			
		EndIf;
	EndIf;
	
	// Getting the flag of the need to account for cancelled items
	ConsiderCancellations = (Table.Columns.Find("Canceled") <> Undefined);
	
	If TheseAreDiscountedVATLines Then
		
		ColumnLineNumber = "VATColumnLineNumber";
		ColumnArticle = "VATColumnArticle";
		ColumnCode = "VATCodeColumn";
		ColumnDataProductQuantity = "ColumnVATDataProductQuantityPrice";
		ColumnVATDataDiscountMarkUp = "VATDataDiscountMarkUp";
		ColumnDataVATMarkUp = "VATDataExtraCharge";
		ColumnDataVATDiscount = "VATDataDiscount";
		ColumnDataAmount = "VATColumnDataAmount";
		FirstColumnOfProductIsVAT = "FirstColumnOfProductIsVAT";
		
		AreaHeaderNumber  = Template.GetArea(TableHeader + "|" + ColumnLineNumber);
		AreaBasementRoom = Template.GetArea(TableFooter + "|" + ColumnLineNumber);
		VATAreaNumber    = Template.GetArea("VATTableBasement|" + ColumnLineNumber);
		
		AreaCodeHeader  = Template.GetArea(TableHeader + "|" + ColumnCode);
		AreaHeaderArticle  = Template.GetArea(TableHeader + "|" + ColumnArticle);
		
		AreaBasementCode = Template.GetArea(TableFooter + "|" + ColumnCode);
		VATAreaCode    = Template.GetArea("VATTableBasement|" + ColumnCode);
		
		HeaderAreaData = New Structure;
		HeaderAreaData.Insert("AmountPrice", Template.GetArea(TableHeader + "|ColumnVATDataProductQuantityPrice"));
		HeaderAreaData.Insert("Discount", Template.GetArea(TableHeader + "|VATData" + OutputParameters.Discounts.ColumnPostfix));
		HeaderAreaData.Insert("Sum", Template.GetArea(TableHeader + "|VATColumnDataAmount"));
		
		AreaBasementData = New Structure;
		AreaBasementData.Insert("AmountPrice", Template.GetArea(TableFooter + "|ColumnVATDataProductQuantityPrice"));
		AreaBasementData.Insert("Discount", Template.GetArea(TableFooter + "|VATData" + OutputParameters.Discounts.ColumnPostfix));
		AreaBasementData.Insert("Sum", Template.GetArea(TableFooter + "|VATColumnDataAmount"));
		
		RegionWithoutVATData    = Template.GetArea("BasementTableVATWithoutVAT|ColumnData_");
		VTCHNDSDataArea    = Template.GetArea("BasementOfVTCHNDSTable|ColumnData_");
		VATAreaData    = Template.GetArea("VATTableBasement|ColumnData_");
		
		RegionAmountInWords = Template.GetArea("AmountInWords");
		AreaAmountInWordsQuantityOnly = Template.GetArea("AmountInWordsQuantityOnly");
		
		AreaLineNumberStandard  = Template.GetArea(TableRow + "|" + ColumnLineNumber);
		ScopeStringDataStandard = New Structure;
		ScopeStringDataStandard.Insert("AmountPrice", Template.GetArea(TableRow + "|ColumnVATDataProductQuantityPrice"));
		ScopeStringDataStandard.Insert("Discount", Template.GetArea(TableRow + "|VATData" + OutputParameters.Discounts.ColumnPostfix));
		ScopeStringDataStandard.Insert("Sum", Template.GetArea(TableRow + "|VATColumnDataAmount"));
		
		ScopeStringCodeStandard    = Template.GetArea(TableRow + "|" + ColumnCode);
		
		UseSets = False;
		If Table.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			Area_LineNumberSet  = Template.GetArea(TableRowSet + "|" + ColumnLineNumber);
			AreaStringDataSet = New Structure;
			AreaStringDataSet.Insert("AmountPrice", Template.GetArea(TableRowSet + "|ColumnVATDataProductQuantityPrice"));
			AreaStringDataSet.Insert("Discount", Template.GetArea(TableRowSet + "|VATData" + OutputParameters.Discounts.ColumnPostfix));
			AreaStringDataSet.Insert("Sum", Template.GetArea(TableRowSet + "|VATColumnDataAmount"));
			
			AreaStringCodeSet    = Template.GetArea(TableRowSet + "|" + ColumnCode);
			
			Area_LineNumberComponents  = Template.GetArea(TableRowComponents + "|" + ColumnLineNumber);
			AreaStringDataComponents = New Structure;
			AreaStringDataComponents.Insert("AmountPrice", Template.GetArea(TableRowComponents + "|ColumnVATDataProductQuantityPrice"));
			AreaStringDataComponents.Insert("Discount", Template.GetArea(TableRowComponents + "|VATData" + OutputParameters.Discounts.ColumnPostfix));
			AreaStringDataComponents.Insert("Sum", Template.GetArea(TableRowComponents + "|VATColumnDataAmount"));
			
			AreaStringCodeComponents    = Template.GetArea(TableRowComponents + "|" + ColumnCode);
		
		EndIf;
		
	ElsIf TheseAreDiscountedLines Then
		
		ColumnLineNumber = "DiscountColumnLineNumber";
		ColumnArticle = "ColumnDiscountArticle";
		ColumnCode = "ColumnDiscountCode";
		ColumnDataProductQuantity = "ColumnDiscountDataProductQuantityPrice";
		ColumnVATDataDiscountMarkUp = "DataDiscountMarkUp";
		ColumnDataVATMarkUp = "DataMarkup";
		ColumnDataVATDiscount = "DataDiscount";
		ColumnDataAmount = "ColumnDiscountDataAmount";
		FirstColumnOfProductIsVAT = "FirstColumnOfProductIsDiscount";
		
		AreaHeaderNumber  = Template.GetArea(TableHeader + "|" + ColumnLineNumber);
		AreaBasementRoom = Template.GetArea(TableFooter + "|" + ColumnLineNumber);
		VATAreaNumber    = Template.GetArea("VATTableBasement|" + ColumnLineNumber);
		
		AreaCodeHeader  = Template.GetArea(TableHeader + "|" + ColumnCode);
		AreaHeaderArticle  = Template.GetArea(TableHeader + "|" + ColumnArticle);
		
		AreaBasementCode = Template.GetArea(TableFooter + "|" + ColumnCode);
		VATAreaCode    = Template.GetArea("VATTableBasement|" + ColumnCode);
		
		HeaderAreaData = New Structure;
		HeaderAreaData.Insert("AmountPrice", Template.GetArea(TableHeader + "|ColumnDiscountDataProductQuantityPrice"));
		HeaderAreaData.Insert("Discount", Template.GetArea(TableHeader + "|Data" + OutputParameters.Discounts.ColumnPostfix));
		HeaderAreaData.Insert("Sum", Template.GetArea(TableHeader + "|ColumnDiscountDataAmount"));
		
		AreaBasementData = New Structure;
		AreaBasementData.Insert("AmountPrice", Template.GetArea(TableFooter + "|ColumnDiscountDataProductQuantityPrice"));
		AreaBasementData.Insert("Discount", Template.GetArea(TableFooter + "|Data" + OutputParameters.Discounts.ColumnPostfix));
		AreaBasementData.Insert("Sum", Template.GetArea(TableFooter + "|ColumnDiscountDataAmount"));
		
		RegionWithoutVATData    = Template.GetArea("BasementTableVATWithoutVAT|ColumnData_");
		VTCHNDSDataArea    = Template.GetArea("BasementOfVTCHNDSTable|ColumnData_");
		VATAreaData    = Template.GetArea("VATTableBasement|ColumnData_");
		
		RegionAmountInWords = Template.GetArea("AmountInWords");
		AreaAmountInWordsQuantityOnly = Template.GetArea("AmountInWordsQuantityOnly");
		
		AreaLineNumberStandard  = Template.GetArea(TableRow + "|" + ColumnLineNumber);
		ScopeStringDataStandard = New Structure;
		ScopeStringDataStandard.Insert("AmountPrice", Template.GetArea(TableRow + "|ColumnDiscountDataProductQuantityPrice"));
		ScopeStringDataStandard.Insert("Discount", Template.GetArea(TableRow + "|Data" + OutputParameters.Discounts.ColumnPostfix));
		ScopeStringDataStandard.Insert("Sum", Template.GetArea(TableRow + "|ColumnDiscountDataAmount"));
		
		ScopeStringCodeStandard    = Template.GetArea(TableRow + "|" + ColumnCode);
		
		UseSets = False;
		If Table.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			Area_LineNumberSet  = Template.GetArea(TableRowSet + "|" + ColumnLineNumber);
			AreaStringDataSet = New Structure;
			AreaStringDataSet.Insert("AmountPrice", Template.GetArea(TableRowSet + "|ColumnDiscountDataProductQuantityPrice"));
			AreaStringDataSet.Insert("Discount", Template.GetArea(TableRowSet + "|Data" + OutputParameters.Discounts.ColumnPostfix));
			AreaStringDataSet.Insert("Sum", Template.GetArea(TableRowSet + "|ColumnDiscountDataAmount"));
			
			AreaStringCodeSet    = Template.GetArea(TableRowSet + "|" + ColumnCode);
			
			Area_LineNumberComponents  = Template.GetArea(TableRowComponents + "|" + ColumnLineNumber);
			AreaStringDataComponents = New Structure;
			AreaStringDataComponents.Insert("AmountPrice", Template.GetArea(TableRowComponents + "|ColumnDiscountDataProductQuantityPrice"));
			AreaStringDataComponents.Insert("Discount", Template.GetArea(TableRowComponents + "|Data" + OutputParameters.Discounts.ColumnPostfix));
			AreaStringDataComponents.Insert("Sum", Template.GetArea(TableRowComponents + "|ColumnDiscountDataAmount"));
			
			AreaStringCodeComponents    = Template.GetArea(TableRowComponents + "|" + ColumnCode);
		
		EndIf;
		
	Else
		
		AreaHeaderNumber  = Template.GetArea(TableHeader + "|ColumnLineNumber");
		AreaBasementRoom = Template.GetArea(TableFooter + "|ColumnLineNumber");
		VATAreaNumber    = Template.GetArea("VATTableBasement|ColumnLineNumber");
		
		AreaCodeHeader  = Template.GetArea(TableHeader + "|ColumnCode");
		AreaHeaderArticle  = Template.GetArea(TableHeader + "|ColumnArticle");
		
		AreaBasementCode = Template.GetArea(TableFooter + "|ColumnCode");
		VATAreaCode    = Template.GetArea("VATTableBasement|ColumnCode");
		
		HeaderAreaData  = Template.GetArea(TableHeader + "|ColumnData_");
		AreaBasementData = Template.GetArea(TableFooter + "|ColumnData_");
		RegionWithoutVATData    = Template.GetArea("BasementTableVATWithoutVAT|ColumnData_");
		VTCHNDSDataArea    = Template.GetArea("BasementOfVTCHNDSTable|ColumnData_");
		VATAreaData    = Template.GetArea("VATTableBasement|ColumnData_");
		
		RegionAmountInWords = Template.GetArea("AmountInWords");
		AreaAmountInWordsQuantityOnly = Template.GetArea("AmountInWordsQuantityOnly");
		
		AreaLineNumberStandard  = Template.GetArea(TableRow + "|ColumnLineNumber");
		ScopeStringDataStandard = Template.GetArea(TableRow + "|ColumnData_");
		ScopeStringCodeStandard    = Template.GetArea(TableRow + "|ColumnCode");
		
		UseSets = False;
		If Table.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			Area_LineNumberSet  = Template.GetArea(TableRowSet + "|ColumnLineNumber");
			AreaStringDataSet = Template.GetArea(TableRowSet + "|ColumnData_");
			AreaStringCodeSet    = Template.GetArea(TableRowSet + "|ColumnCode");
			
			Area_LineNumberComponents  = Template.GetArea(TableRowComponents + "|ColumnLineNumber");
			AreaStringDataComponents = Template.GetArea(TableRowComponents + "|ColumnData_");
			AreaStringCodeComponents    = Template.GetArea(TableRowComponents + "|ColumnCode");
		
		EndIf;
		
	EndIf;
	
	BlankData = SetsServer.BlankData();
	
	// The output of the table header
	SpreadsheetDocument.Put(AreaHeaderNumber);
	If OutputParameters.OutputCodes Then
		
		If NameOfCodeColumn = "Code" Then
			
			SpreadsheetDocument.Join(AreaCodeHeader);
			
		ElsIf NameOfCodeColumn = "SKU" Then
			
			SpreadsheetDocument.Join(AreaHeaderArticle);
			
		EndIf;
		
	EndIf;
	
	If TypeOf(HeaderAreaData) = Type("Structure") Then
		
		SpreadsheetDocument.Join(HeaderAreaData.AmountPrice);
		SpreadsheetDocument.Join(HeaderAreaData.Discount);
		SpreadsheetDocument.Join(HeaderAreaData.Sum);
		
	Else
		
		SpreadsheetDocument.Join(HeaderAreaData);
		
	EndIf;
	
	// Creating a summary structure for a table of values
	StructureOfResults = New Structure;
	If Not OutputParameters.OnlyQuantity Then
		StructureOfResults.Insert("Total", 0);
	EndIf;
	If OutputParameters.ConsiderVAT Then
		StructureOfResults.Insert("TotalVAT", 0);
	EndIf;
	If OutputParameters.ThereAreDiscounts Then
		StructureOfResults.Insert("TotalWithoutDiscount", 0);
		StructureOfResults.Insert("TotalDiscount", 0);
	EndIf;
	
	// Getting compliance with VAT rates
	If OutputParameters.ConsiderVAT Then
		ComplianceWithVATRates = PrintFormGeneration.ComplianceOfVATRatesAndAmounts();
	EndIf;
	
	TheStructureOfTheSearch      = New Structure("Ref", PrintData.Ref);
	TS = Table.FindRows(TheStructureOfTheSearch);
	
	// Output of product table rows
	LineNumber = 0;
	For Each String In TS Do
		
		If ConsiderCancellations And String.Canceled Then
			Continue;
		EndIf;
	
		If SetsServer.UseSetArea(String, UseSets) Then
			Area_LineNumber  = Area_LineNumberSet;
			AreaStringData = AreaStringDataSet;
			AreaStringCode    = AreaStringCodeSet;
		ElsIf SetsServer.UseScope(String, UseSets) Then
			Area_LineNumber  = Area_LineNumberComponents;
			AreaStringData = AreaStringDataComponents;
			AreaStringCode    = AreaStringCodeComponents;
		Else
			Area_LineNumber  = AreaLineNumberStandard;
			AreaStringData = ScopeStringDataStandard;
			AreaStringCode    = ScopeStringCodeStandard;
		EndIf;
		
		If SetsServer.DisplayOnlyTitle(String, UseSets) Then
			SetParameter(Area_LineNumber, "LineNumber", Undefined);
		Else
			LineNumber = LineNumber + 1;
			SetParameter(Area_LineNumber, "LineNumber", LineNumber);
		EndIf;
		SpreadsheetDocument.Put(Area_LineNumber);
		
		// Output of the code/article column
		If OutputParameters.OutputCodes Then
			DataStructureArticle = New Structure("SKU", String[NameOfCodeColumn]);
			AreaStringCode.Parameters.Fill(DataStructureArticle);
			SpreadsheetDocument.Join(AreaStringCode);
		EndIf;
		
		If TypeOf(AreaStringData) = Type("Structure") Then
			
			If SetsServer.DisplayOnlyTitle(String, UseSets) Then
				DataToFill = BlankData;
			Else
				DataToFill = String;
			EndIf;
			
			AreaStringData.AmountPrice.Parameters.Fill(DataToFill);
			AreaStringData.Discount.Parameters.Fill(DataToFill);
			AreaStringData.Sum.Parameters.Fill(DataToFill);
			
			If OutputParameters.ThereAreDiscounts Then
				
				DiscountAmount = ?(DataToFill.DiscountAmount = "", 0, DataToFill.DiscountAmount);
				
			EndIf;
			
		Else
			
			If SetsServer.DisplayOnlyTitle(String, UseSets) Then
				AreaStringData.Parameters.Fill(BlankData);
			Else
				AreaStringData.Parameters.Fill(String);
			EndIf;
			
			If OutputParameters.ThereAreDiscounts Then
				
				DiscountAmount = AreaStringData.Parameters.DiscountAmount;
				
			EndIf;
			
		EndIf;
		
		PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(String, UseSets);
		
		StringDataStructure = New Structure;
		If ProductColumnName = "ReplacementProduct" Then
			ParametersPresentationOfProductsForPrinting = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			ParametersPresentationOfProductsForPrinting.ReturnContainers = String.ThisIsReusablePackage;
			ParametersPresentationOfProductsForPrinting.Content = String.Content;
			ParametersPresentationOfProductsForPrinting.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
				String.DescriptionFull,
				String.Characteristic,
				,
				,
				ParametersPresentationOfProductsForPrinting) + PrefixAndPostfix.Postfix;
			StringDataStructure.Insert("OwnGoods", OwnGoods);
			If OutputParameters.ThereAreDiscounts Then
				StringDataStructure.Insert("DiscountAmount", 
					?(OutputParameters.Discounts.ThereIsMarkUp And Not OutputParameters.Discounts.ThereIsDiscount,
					- DiscountAmount,
					DiscountAmount));
			EndIf; 
		Else
			
			ParametersPresentationOfProductsForPrinting = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			ParametersPresentationOfProductsForPrinting.ReturnContainers = String.ThisIsReusablePackage;
			ParametersPresentationOfProductsForPrinting.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
				String.DescriptionFull,
				String.Characteristic,
				,
				,
				ParametersPresentationOfProductsForPrinting) + PrefixAndPostfix.Postfix;
			StringDataStructure.Insert("OwnGoods", OwnGoods);
		EndIf;	
		
		If TypeOf(AreaStringData) = Type("Structure") Then
			
			AreaStringData.AmountPrice.Parameters.Fill(StringDataStructure);
			SpreadsheetDocument.Join(AreaStringData.AmountPrice);
			AreaStringData.Discount.Parameters.Fill(StringDataStructure);
			SpreadsheetDocument.Join(AreaStringData.Discount);
			AreaStringData.Sum.Parameters.Fill(StringDataStructure);
			SpreadsheetDocument.Join(AreaStringData.Sum);
			
		Else
			
			AreaStringData.Parameters.Fill(StringDataStructure);
			SpreadsheetDocument.Join(AreaStringData);
			
		EndIf;
		
		// Accumulation of results
		If Not SetsServer.UseScope(String, UseSets) Then
			If Not OutputParameters.OnlyQuantity Then
				StructureOfResults.Total = StructureOfResults.Total + String.Sum;
				If OutputParameters.ConsiderVAT Then
					StructureOfResults.TotalVAT = StructureOfResults.TotalVAT + String.VATAmount;
					
					AmountAtCurVATRate = ComplianceWithVATRates[String.VATRate];
					If AmountAtCurVATRate <> Undefined Then
						ComplianceWithVATRates[String.VATRate] = AmountAtCurVATRate + String.VATAmount;
					EndIf;
					
				EndIf;
				If OutputParameters.ThereAreDiscounts Then
					StructureOfResults.TotalWithoutDiscount = StructureOfResults.TotalWithoutDiscount + String.AmountWithoutADiscount;
					StructureOfResults.TotalDiscount = StructureOfResults.TotalDiscount + String.DiscountAmount;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	// Output of the table basement
	SpreadsheetDocument.Put(AreaBasementRoom);
	If OutputParameters.OutputCodes Then
		SpreadsheetDocument.Join(AreaBasementCode);
	EndIf;
	
	If TypeOf(AreaBasementData) = Type("Structure") Then
		
		SpreadsheetDocument.Join(AreaBasementData.AmountPrice);
		
		DataStructureBasementDiscounts = New Structure;
		DataStructureBasementDiscounts.Insert("TotalDiscount", ?(OutputParameters.Discounts.ThereIsMarkUp And Not OutputParameters.Discounts.ThereIsDiscount,-StructureOfResults.TotalDiscount, StructureOfResults.TotalDiscount));
		DataStructureBasementDiscounts.Insert("TotalWithoutDiscount", StructureOfResults.TotalWithoutDiscount);
		AreaBasementData.Discount.Parameters.Fill(DataStructureBasementDiscounts);
		SpreadsheetDocument.Join(AreaBasementData.Discount);
		
		AreaBasementData.Sum.Parameters.Fill(StructureOfResults);
		SpreadsheetDocument.Join(AreaBasementData.Sum);
		
	Else
		
		AreaBasementData.Parameters.Fill(StructureOfResults);
		If OutputParameters.ThereAreDiscounts Then
			BasementDataStructure = New Structure;
			BasementDataStructure.Insert("TotalDiscount", ?(OutputParameters.Discounts.ThereIsMarkUp And Not OutputParameters.Discounts.ThereIsDiscount,-StructureOfResults.TotalDiscount, StructureOfResults.TotalDiscount));
			BasementDataStructure.Insert("TotalWithoutDiscount", StructureOfResults.TotalWithoutDiscount);
			AreaBasementData.Parameters.Fill(BasementDataStructure);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementData);
		
	EndIf;
	
	// VAT basement withdrawal
	If OutputParameters.OutputBasementVAT And Not OutputParameters.OnlyQuantity Then
		If OutputParameters.ConsiderVAT Then
			For Each Rate1 In ComplianceWithVATRates Do
				
				If Rate1.Value = 0 Then 
					Continue;
				EndIf;
				
				SpreadsheetDocument.Put(VATAreaNumber);
				If OutputParameters.OutputCodes Then
					SpreadsheetDocument.Join(VATAreaCode);
				EndIf;
				VATDataStructure = New Structure;
				VATDataStructure.Insert("NameOfVATRate", Rate1.Key);
				VATDataStructure.Insert("TotalVAT", Rate1.Value);
				
				VATAreaOutputData = ?(OutputParameters.PriceIncludesVAT, VTCHNDSDataArea, VATAreaData);
				VATAreaOutputData.Parameters.Fill(VATDataStructure);
				SpreadsheetDocument.Join(VATAreaOutputData);
				
			EndDo;
		Else
			SpreadsheetDocument.Put(VATAreaNumber);
			If OutputParameters.OutputCodes Then
				SpreadsheetDocument.Join(VATAreaCode);
			EndIf;
			SpreadsheetDocument.Join(RegionWithoutVATData);
		EndIf;
	EndIf;
	
	// Withdrawal of the total amount
	If OutputParameters.OnlyQuantity Then
		
		AreaIsAmountInWordsForWithdrawal = AreaAmountInWordsQuantityOnly;
		
		Sum = "";
		AmountInWords = "";
		
	Else
		
		AreaIsAmountInWordsForWithdrawal = RegionAmountInWords;
		
		AmountToBeRegistered = StructureOfResults.Total + ?(OutputParameters.ConsiderVAT And Not OutputParameters.PriceIncludesVAT, StructureOfResults.TotalVAT, 0);
		Sum = PrintFormGeneration.SumFormat(AmountToBeRegistered, Currency,,,OutputParameters.LanguageCode);
		AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, Currency,,OutputParameters.LanguageCode);
		
	EndIf;
	
	DataStructureSummaryRow = New Structure;
	DataStructureSummaryRow.Insert("Count", LineNumber);
	DataStructureSummaryRow.Insert("Sum", Sum);
	DataStructureSummaryRow.Insert("AmountInWords", AmountInWords);
	
	AreaIsAmountInWordsForWithdrawal.Parameters.Fill(DataStructureSummaryRow);
	SpreadsheetDocument.Put(AreaIsAmountInWordsForWithdrawal);
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
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
	"
	|SELECT
	|	Table.Ref AS Ref,
	|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.AmountIncludingVAT AS Sum,
	|	CASE
	|		WHEN
	|			Table.Ref.ToReturnReusablePackage
	|			AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|INTO Goods
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	NOT Table.Canceled
	|	AND Table.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
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
	|
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
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
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
	|			ELSE null
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
	
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum
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
	|	ReturnRequest.Ref AS Ref,
	|	ReturnRequest.Date AS Date,
	|	ReturnRequest.DocumentAmount AS Sum,
	|	ReturnRequest.Currency AS Currency,
	|	ReturnRequest.Organization AS Organization,
	|	ReturnRequest.ReasonForReturn AS ReasonForReturn,
	|	ReturnRequest.Customer AS Customer,
	|	ReturnRequest.CashRegisterReceipt.Number AS CashRegisterReceiptNumber,
	|	ReturnRequest.CashRegisterReceipt.Date AS CashRegisterReceiptDate,
	|	ReturnRequest.CustomerSDateOfBirth AS BirthDate,
	|	ReturnRequest.CustomerDocumentKind AS DocumentKind,
	|	ReturnRequest.CustomerDocumentSeries AS Series,
	|	ReturnRequest.CustomerDocumentNumber AS Number,
	|	ReturnRequest.DateOfCustomerDocumentIssue AS DateOfIssue1,
	|	ReturnRequest.CustomerDocumentValidityPeriod AS ValidityPeriod,
	|	ReturnRequest.IssuingAuthorityOfCustomerDocument AS IssuedBy,
	|	ReturnRequest.CustomerDocumentBusinessUnitCode AS BusinessUnitCode
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
	|WHERE
	|	ReturnRequest.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet                        AS ProductsInSet,
	|	Goods.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	Goods.IsRecordsSet                                  AS IsRecordsSet,
	|	Goods.TheseAreComponents                          AS TheseAreComponents,
	
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
	|
	|FROM (
	|
	|	SELECT
	|		Table.Ref AS Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
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
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Sum,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.ThisIsReusablePackage
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
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC	
	|";
	
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

// Returns the document data structure used for printing the printed form of the product selection (placement) Task.
//
// Parameters:
//	PrintParameters - Structure - additional print options.
//	ObjectsArray  - Array of DocumentRef.RequestForReturnOfGoodsFromCustomer - links to objects that need to be printed.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- QueryResult	- errors in document data that make it impossible
//															to print the document.
//		*ResultOnOrders	- Undefined		- information about orders for document shipment.
//		*HeaderResults			- QueryResult	- data of the document header used for printing the Task
//															for selecting (placing) products.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Tasks for selecting (placing) products.
//		*ResultForPackages		- QueryResult		- data about product packages in the table part of the document
//															used for printing the Task for selecting (placing) products.
//		*ResultBySeries			- Undefined		- data about product series in the table part of the document
//															used for printing the Task for selecting (placing) products.
//
Function GetDataForPrintedFormForProductPlacement(PrintParameters, ObjectsArray) Export
	
	QueryText =
	"SELECT DISTINCT
	|	TaskData_.Ref	AS Ref,
	|	TaskData_.Number		AS Number,
	|	TaskData_.Date		AS Date,
	|	UNDEFINED			AS NumberOfDocumentBeingCorrected,
	|	UNDEFINED			AS DateOfDocumentBeingCorrected,
	|	DocumentGoods.Warehouse	AS Warehouse,
	|	&DefaultRoom	AS Premise,
	|	TRUE					AS ThisIsAnInvoice,
	|	FALSE					AS BinLocationWarehousingIsUsed,
	|	CASE
	|		WHEN DocumentGoods.Warehouse.UseBinLocationWarehousingForInformation
	|				AND (NOT DocumentGoods.Warehouse.UseBinLocationWarehousing
	|					OR TaskData_.Date < DocumentGoods.Warehouse.StartDateOfUsingWarehouseBinSystem)
	|			THEN TRUE
	|		ELSE FALSE
	|	END					AS ReferenceStorageIsUsed,
	|	ISNULL(DocumentGoods.Warehouse.WarehouseZoneUsage, FALSE) AS WarehouseZoneUsage,
	|	CASE
	|		WHEN DocumentGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND TaskData_.Date >= DocumentGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END					AS AdvancedWarehousingIsUsed
	|INTO TaskData_
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS TaskData_
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS DocumentGoods
	|		ON TaskData_.Ref = DocumentGoods.Ref
	|
	|WHERE
	|	TaskData_.Ref IN(&ObjectsArray)
	|	AND DocumentGoods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND TaskData_.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply),
	|								VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
	|								VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed))
	|
	|INDEX BY
	|	Ref,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsForIssue.DocumentShipments	AS Ref,
	|	GoodsForIssue.Products		AS Products,
	|	GoodsForIssue.Characteristic		AS Characteristic,
	|	GoodsForIssue.Series				AS Series,
	|	GoodsForIssue.Warehouse				AS Warehouse,
	|	GoodsForIssue.ToShipBalance	AS Count
	|INTO GoodsForIssue
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|			,
	|			(Warehouse, DocumentShipments) IN
	|				(SELECT
	|					TaskData_.Warehouse  AS Warehouse,
	|					TaskData_.Ref AS DocumentShipments
	|				FROM
	|					TaskData_ AS TaskData_
	|				WHERE
	|					NOT TaskData_.AdvancedWarehousingIsUsed)) AS GoodsForIssue
	|
	|INDEX BY
	|	Ref,
	|	Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	MIN(GoodsTable.LineNumber)	AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	GoodsTable.Series					AS Series,
	|	GoodsTable.Warehouse					AS Warehouse
	|INTO GoodsReturnRequests
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsTable
	|		INNER JOIN TaskData_ AS TaskData_
	|		ON GoodsTable.Ref = TaskData_.Ref
	|			AND GoodsTable.Warehouse = TaskData_.Warehouse
	|WHERE
	|	NOT GoodsTable.Canceled
	|	AND NOT TaskData_.AdvancedWarehousingIsUsed
	|	AND GoodsTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Warehouse
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	GoodsReturnRequests.LineNumber	AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	GoodsTable.Series					AS Series,
	|	CAST(GoodsTable.Products AS Catalog.Products).PackagingGroup AS PackagingGroup,
	|	GoodsTable.Warehouse					AS Warehouse,
	|	GoodsTable.Count			AS Count
	|INTO TaskItems_
	|FROM
	|	GoodsForIssue AS GoodsTable
	|		INNER JOIN GoodsReturnRequests AS GoodsReturnRequests
	|		ON GoodsTable.Ref = GoodsReturnRequests.Ref
	|			AND GoodsTable.Products = GoodsReturnRequests.Products
	|			AND GoodsTable.Characteristic = GoodsReturnRequests.Characteristic
	|			AND GoodsTable.Series = GoodsReturnRequests.Series
	|			AND GoodsTable.Warehouse = GoodsReturnRequests.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	GoodsTable.Warehouse					AS Warehouse,
	|	TaskData_.Premise				AS Premise,
	|	MIN(GoodsTable.LineNumber)	AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END								AS Series,
	|	Goods.PackagingGroup				AS PackagingGroup,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN Goods.UnitOfMeasure
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END								AS Package,
	|	MIN(GoodsTable.Count)	AS Count
	|INTO TableOfGoodsSummarized
	|FROM
	|	TaskItems_ AS GoodsTable
	|		LEFT JOIN TaskData_ AS TaskData_
	|		ON GoodsTable.Ref = TaskData_.Ref
	|		
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON GoodsTable.Products = Goods.Ref
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Warehouse,
	|	TaskData_.Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END,
	|	Goods.PackagingGroup,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN Goods.UnitOfMeasure
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END
	|
	|INDEX BY
	|	Products,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|		LEFT JOIN TaskData_ AS TaskData_
	|		ON DocumentData.Ref = TaskData_.Ref
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND TaskData_.Ref IS NULL
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	TaskData_.Ref							AS Ref,
	|	PRESENTATION(TaskData_.Ref)				AS RefPresentation,
	|	TaskData_.Number								AS Number,
	|	TaskData_.Date								AS Date,
	|	TaskData_.NumberOfDocumentBeingCorrected		AS NumberOfDocumentBeingCorrected,
	|	TaskData_.DateOfDocumentBeingCorrected		AS DateOfDocumentBeingCorrected,
	|	TaskData_.Warehouse								AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)				AS WarehousePresentation,
	|	TaskData_.Premise							AS Premise,
	|	PRESENTATION(&DefaultRoom)			AS PremisePresentation,
	|	TaskData_.ThisIsAnInvoice						AS ThisIsAnInvoice,
	|	TaskData_.BinLocationWarehousingIsUsed		AS BinLocationWarehousingIsUsed,
	|	TaskData_.ReferenceStorageIsUsed	AS ReferenceStorageIsUsed,
	|	TaskData_.WarehouseZoneUsage		AS WarehouseZoneUsage,
	|	TaskData_.AdvancedWarehousingIsUsed			AS AdvancedWarehousingIsUsed
	|FROM
	|	TaskData_ AS TaskData_
	|
	|ORDER BY
	|	TaskData_.Ref,
	|	TaskData_.Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	TableOfGoods.Ref								AS Ref,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	PRESENTATION(MainStorageBins.Cell.WarehouseZone)	AS PresentationOfWorkArea,
	|	ISNULL(MainStorageBins.Cell.TabIndex, 0)	AS TabIndex,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS MainStorageBin,
	|	ISNULL(MainStorageBins.Cell.Code, """")			AS MainStorageBinPresentation,
	|	ISNULL(OtherCells.Cell.TabIndex, 0)	AS TraversalOrderAdditionalCell,
	|	ISNULL(OtherCells.Cell.Code, """")			AS CellPresentation,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	Goods.Code											AS Code,
	|	Goods.SKU										AS SKU,
	|	TableOfGoods.Products							AS Products,
	|	Goods.DescriptionFull							AS ProductPresentation,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull	AS CharacteristicPresentation,
	|	Goods.ProductKind.BatchUsageSettings	AS BatchUsageSettings,
	|	TableOfGoods.Series								AS Series,
	|	PRESENTATION(TableOfGoods.Series)					AS BatchPresentation,
	|	TableOfGoods.Package								AS Package,
	|	PRESENTATION(TableOfGoods.Package)				AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.UnitOfMeasure)				AS PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.Count							AS NumberOfPackages
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS OtherCells
	|		ON TableOfGoods.Products = OtherCells.Products
	|			AND NOT OtherCells.MainStorageBin
	|			AND TableOfGoods.Warehouse = OtherCells.Warehouse
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series
	|
	|TOTALS BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT DISTINCT
	|	TableOfGoods.Ref					AS Ref,
	|	TableOfGoods.Warehouse					AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea) AS WarehouseZone,
	|	TableOfGoods.LineNumber				AS LineNumber,
	|	TableOfGoods.Products				AS Products,
	|	TableOfGoods.Characteristic			AS Characteristic,
	|	TableOfGoods.Series					AS Series,
	|	ISNULL(ProductPackages.Ref, &DefaultPackaging)	AS Package,
	|	ISNULL(PRESENTATION(ProductPackages.Ref), PRESENTATION(TableOfGoods.Products.UnitOfMeasure)) AS PresentationOfPackingUnit,
	|	ISNULL(&PackingCoefficientText, 1)	AS QuantityPerPackage
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (TableOfGoods.Products = ProductPackages.Owner
	|				OR TableOfGoods.PackagingGroup = ProductPackages.Owner)
	|			AND NOT ProductPackages.DeletionMark
	|			AND TableOfGoods.Count >= &PackingCoefficientText
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series,
	|	QuantityPerPackage DESC";
	
	PackingCoefficientText = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
								"ProductPackages",
								"TableOfGoods.Products");
	
	QueryText = StrReplace(QueryText,
								"&DefaultRoom",
								"VALUE(Catalog.Warerooms.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&BatchUsageSettings",
								"VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)");
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultCell",
								"VALUE(Catalog.StorageBins.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultPackaging",
								"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	QueryText = StrReplace(QueryText, "&PackingCoefficientText", PackingCoefficientText);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ObjectsArray", ObjectsArray); 
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Results.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Results[MaxIndex - 3]);
	TaskData_.Insert("ResultOnOrders",	Undefined);
	TaskData_.Insert("HeaderResults",			Results[MaxIndex - 2]);
	TaskData_.Insert("ResultForTabularPart",	Results[MaxIndex - 1]);
	TaskData_.Insert("ResultForPackages",		Results[MaxIndex]);
	TaskData_.Insert("ResultBySeries",			Undefined);
	
	Return TaskData_;
	
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
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	EndIf;
	
EndProcedure

// The function receives data for generating a printed form " Notification"
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultsByPaymentStages - QueryResult
// 		* ResultForTabularPart - QueryResult
//
Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	Documents.Organization AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription  AS Director,
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
	|	Documents.BankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.BankAccount.ForeignBank
	|		OR Documents.BankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.BankAccount.CashCurrency AS CashCurrency,
	|	
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankNameInt
	|		ELSE Documents.BankAccount.Bank.InternationalDescription END AS BankNameInt,
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankNameForPaymentsInt
	|		ELSE Documents.BankAccount.TransferBank.InternationalDescription END AS BankNameForPaymentsInt,
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankSWIFTCode
	|		ELSE Documents.BankAccount.Bank.SWIFTBIC END AS BankSWIFTCode,
	|	CASE WHEN Documents.BankAccount.TransferBankDetailsManualEdit THEN Documents.BankAccount.BankSWIFTCodeForPayments
	|		ELSE Documents.BankAccount.TransferBank.SWIFTBIC END AS BankSWIFTCodeForPayments,
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankAddressInt
	|		ELSE Documents.BankAccount.Bank.InternationalAddress END AS BankAddress,
	|	CASE WHEN Documents.BankAccount.TransferBankDetailsManualEdit THEN Documents.BankAccount.BankAddressForPaymentInt
	|		ELSE Documents.BankAccount.TransferBank.InternationalAddress END AS TransferBankAddress,
	|	
	|	Documents.BankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.BankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.BankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.BankAccount.DigitalRoubleAccountID
	|		ELSE Documents.BankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.BankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.AdditionalInformation AS AdditionalInformation,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	Documents.ReplacementAmount AS DocumentAmount,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	TRUE AS InvoiceToBeRefunded
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Documents
	|	LEFT JOIN
	|		TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
 	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.BankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.BankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
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
	|	1 AS Order,
	|	PaymentScheduleSteps.Ref AS Ref,
	|	PaymentScheduleSteps.LineNumber AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
	|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
	|	PaymentScheduleSteps.PaymentAmount AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.PaymentAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	2														AS Order,
	|	PaymentScheduleSteps.Ref								AS Ref,
	|	PaymentScheduleSteps.LineNumber							AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate							AS PaymentDate,
	|	PaymentScheduleSteps.PackageDepositPercentage					AS PaymentPercentage,
	|	PaymentScheduleSteps.PackageDepositValue					AS PaymentAmount,
	|	TRUE													AS ThisIsDepositForPackage
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.Ref.PackageDepositIsRequired
	|	AND PaymentScheduleSteps.PackageDepositValue <> 0
	|
	|ORDER BY
	|	LineNumber,
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
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
	|	Goods.NumberOfPackages AS Count,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.Price
	|		ELSE Goods.Sum/Goods.NumberOfPackages 
	|	END AS Price,
	|	Goods.Sum AS Sum,
	|	Goods.VATRate AS VATRate,
	|	Goods.VATAmount AS VATAmount,
	|	Goods.DateOfShipment AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END AS Package,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.ManualDiscount + Goods.DiscountMarkupAmount
	|		ELSE 0 
	|	END AS DiscountAmount,
	|	Goods.Sum + Goods.ManualDiscount + Goods.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	CASE
	|		WHEN
	|			Goods.Ref.ToReturnReusablePackage
	|			AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	Goods.Content AS Content
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|	AND Goods.Canceled = FALSE
	|	AND (Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND (NOT Goods.Ref.ToReturnReusablePackage OR Goods.Ref.PackageDepositIsRequired))
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
EndFunction

#EndRegion

#Region PrintKits

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ReturnRequest", NStr("vi = 'Giấy đề nghị trả hàng (hiển thị chiết khấu)';
																											|ru = 'Заявка на возврат (выводить скидки)';
																											|en = 'Return request (display discounts)'; fa = 'Return request (display discounts)';
																											|it = 'Domanda di reso (visualizzare gli sconti)';
																											|pl = 'Zlecenie na zwrot (wyprowadzaj rabaty)';
																											|tr = 'İade talebi (indirimleri göster)'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "RequestForRefundWithoutDiscounts", NStr("vi = 'Giấy đề nghị trả hàng (không hiển thị chiết khấu)';
																															|ru = 'Заявка на возврат (не выводить скидки)';
																															|en = 'Return request (do not display discounts)'; fa = 'Return request (do not display discounts)';
																															|it = 'Domanda di reso (non visualizzare gli sconti)';
																															|pl = 'Zlecenie na zwrot (nie wyprowadzaj rabaty)';
																															|tr = 'İade talebi (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
																											|ru = 'Счет на оплату (выводить скидки)';
																											|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
																											|it = 'Fattura di pagamento (visualizzare gli sconti)';
																											|pl = 'Rachunek do płatności (wyświetlać zniżki)';
																											|tr = 'Ticari fatura (indirimleri göster)'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceForPaymentWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату (не выводить скидки)';
																																|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
																																|it = 'Fattura di pagamento (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
																																|tr = 'Ticari fatura (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
																														|ru = 'Счет на оплату с факсимиле (выводить скидки)';
																														|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
																														|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
																														|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
																														|tr = 'Kaşeli ticari fatura (indirimleri göster)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceWithFacsimileWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
																																|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
																																|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
																																|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'"), 0);
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ReturnRequest", NStr("vi = 'Giấy đề nghị trả hàng';
																											|ru = 'Заявка на возврат';
																											|en = 'Return request'; fa = 'درخواست برگشت';
																											|it = 'Domanda di reso';
																											|pl = 'Wniosek o zwrot pieniędzy';
																											|tr = 'İade talebi'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán';
																											|ru = 'Счет на оплату';
																											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
																											|it = 'Fattura di pagamento';
																											|pl = 'Rachunek do zapłaty';
																											|tr = 'Ticari fatura'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax';
																														|ru = 'Счет на оплату с факсимиле';
																														|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
																														|it = 'Fattura di pagamento in facsimile';
																														|pl = 'Rachunek do płatności z faksymile';
																														|tr = 'Kaşeli ticari fatura'"), 0);
	EndIf;
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
		"ApplicationForReturnOfGoodsFromClient", 
		NStr("vi = 'Giấy đề nghị trả hàng';
			|ru = 'Заявление на возврат товаров';
			|en = 'Goods return request'; fa = 'درخواست مرجوعی کالا';
			|it = 'Domanda di reso delle merci';
			|pl = 'Oświadczenie zwrotu towarów';
			|tr = 'Mal iadesi için başvuru'"),0);
		
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
		"GoodsPickingPlacementJob", 
		NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
			|ru = 'Задание на отбор товаров';
			|en = 'Picking job'; fa = 'کار برداشت';
			|it = 'Task per selezione prodotti';
			|pl = 'Zadanie na selekcję towarów';
			|tr = 'Mal seçimi görevi'"),0);

	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceEn", NStr("vi = 'Proforma invoice';
																												|ru = 'Proforma invoice';
																												|en = 'Proforma invoice'; fa = 'پیش‌فاکتور';
																												|it = 'Proforma invoice';
																												|pl = 'Proforma invoice';
																												|tr = 'Proforma invoice'"), 1);
	EndIf;
	
	RequestForReturnOfGoodsFromCustomerLocalization.PrintFormsSet(PrintFormsSet);
		
	Return PrintFormsSet;
	
EndFunction

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	StructureOfTypes = New Map;
	StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", ObjectsArray);
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ReturnRequest");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			GeneratePrintedRefundRequestForm(PrintKit.Objects, PrintObjects, PrintParameters));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"RequestForRefundWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			GeneratePrintedRefundRequestForm(PrintKit.Objects, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoice");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceForPaymentWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceWithFacsimile");
	PrintParameters.Delete("DisplayDiscounts_");
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
			
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceWithFacsimileWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
		
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceEn");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ApplicationForReturnOfGoodsFromClient");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintApplicationForReturnOfGoodsFromCustomer.GeneratePrintedApplicationFormForReturnOfGoodsFromClient(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"GoodsPickingPlacementJob");
	PrintParameters.Insert("JobType", "SelectionTask");
	PrintParameters.Insert("PrintingFromDocumentData", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.RequestForReturnOfGoodsFromCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.CreateTaskForProductSelectionAndPlacement(StructureOfTypes,
				PrintObjects, PrintParameters));
	EndDo;
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.RequestForReturnOfGoodsFromCustomer",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
		
				
	RequestForReturnOfGoodsFromCustomerLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet); 
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//     ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentsListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.RequestForReturnOfGoodsFromCustomer))
		And AccessRight("Insert", Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
		And AccessRight("Read",     Metadata.AccumulationRegisters.CustomersARAPAccounting)
		And AccessRight("Read",     Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
		And GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT DocumentRequest.Ref) AS RequestsForReturnOfGoodsFromCustomersAreStillInProgress,
	|	COUNT(DISTINCT CASE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate >= SalesOrderStates.EventDate THEN
	|			SalesOrderStates.OrderDocument
	|		END) AS RequestsForReturnOfGoodsFromCustomersForToday,
	|	COUNT(DISTINCT CASE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate > SalesOrderStates.EventDate 
	|				AND SalesOrderStates.State IN (
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingAdvanceOrReturnBeforeSupply),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPrepaymentOrReturnBeforeShipment),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPaymentOrReturnAfterShipment)) THEN
	|			SalesOrderStates.OrderDocument
	|		END) AS RequestsForReturnOfGoodsFromCustomersOverduePayment,
	|	COUNT(DISTINCT CASE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate > SalesOrderStates.EventDate 
	|				AND SalesOrderStates.State IN (
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingApproval),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingExecution_),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForReturn),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingSupply),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForShipment),
	|					VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.DuringShipment)) THEN
	|			SalesOrderStates.OrderDocument
	|		END) AS RequestsForReturnOfGoodsFromCustomersOverdueExecution
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequest
	|		{LEFT JOIN InformationRegister.SalesOrderStates AS SalesOrderStates
	|		ON (SalesOrderStates.OrderDocument = DocumentRequest.Ref)}
	|WHERE
	|	((NOT (SalesOrderStates.OrderDocument IS NULL)
	|	AND NOT SalesOrderStates.State IN (VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed),
	|									 VALUE(Enum.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected)))
	|	OR NOT DocumentRequest.Posted)
	|	AND DocumentRequest.Manager = &User
	|	AND NOT DocumentRequest.DeletionMark";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Application for the return of the clients' goods
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "RequestsForReturnOfGoodsFromCustomers";
	UserTaskParent.Presentation  = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
										|ru = 'Заявки на возврат товаров от клиентов';
										|en = 'Sales return requests'; fa = 'درخواست‌های برگشت از فروش';
										|it = 'Domande di reso merci dai clienti';
										|pl = 'Wnioski o zwrot towarów od klientów';
										|tr = 'Müşteriden mal iadesi talebi'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// RequestsForReturnOfGoodsFromCustomersAreStillInProgress
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllOpened");
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "RequestsForReturnOfGoodsFromCustomersAreStillInProgress";
	ToDoItem.HasToDoItems       = Result.RequestsForReturnOfGoodsFromCustomersAreStillInProgress > 0;
	ToDoItem.Presentation  = NStr("vi = 'Tổng số trong giấy đề nghị hiện tại';
									|ru = 'Всего заявок в работе';
									|en = 'Total requests in process'; fa = 'Total requests in process';
									|it = 'Totale domande in esecuzione';
									|pl = 'Łącznie wniosków w pracy';
									|tr = 'Devam eden tüm talepler'");
	ToDoItem.Count     = Result.RequestsForReturnOfGoodsFromCustomersAreStillInProgress;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "RequestsForReturnOfGoodsFromCustomers";
	
	// RequestsForReturnOfGoodsFromCustomersForToday
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllOpened");
	FilterParameters.Insert("Relevance", "Today");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "RequestsForReturnOfGoodsFromCustomersForToday";
	ToDoItem.HasToDoItems       = Result.RequestsForReturnOfGoodsFromCustomersForToday > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hôm nay';
									|ru = 'На сегодня';
									|en = 'As of today'; fa = 'As of today';
									|it = 'Ad oggi';
									|pl = 'Na dzisiaj';
									|tr = 'Bugün itibarıyla'");
	ToDoItem.Count     = Result.RequestsForReturnOfGoodsFromCustomersForToday;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "RequestsForReturnOfGoodsFromCustomers";
	
	// RequestsForReturnOfGoodsFromCustomersOverduePayment
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllPaymentPending");
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "RequestsForReturnOfGoodsFromCustomersOverduePayment";
	ToDoItem.HasToDoItems       = Result.RequestsForReturnOfGoodsFromCustomersOverduePayment > 0;
	ToDoItem.Presentation  = NStr("vi = 'Đã quá hạn thanh toán theo giấy đề nghị';
									|ru = 'Просрочена оплата по заявкам';
									|en = 'Payment by requests is overdue'; fa = 'Payment by requests is overdue';
									|it = 'Pagamento scaduto per le domande';
									|pl = 'Zaległa płatność według wniosków';
									|tr = 'Taleplere ilişkin gecikmiş ödemeler'");
	ToDoItem.Count     = Result.RequestsForReturnOfGoodsFromCustomersOverduePayment;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "RequestsForReturnOfGoodsFromCustomers";
	
	// RequestsForReturnOfGoodsFromCustomersOverdueExecution
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllExecutionPending");
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "RequestsForReturnOfGoodsFromCustomersOverdueExecution";
	ToDoItem.HasToDoItems       = Result.RequestsForReturnOfGoodsFromCustomersOverdueExecution > 0;
	ToDoItem.Presentation  = NStr("vi = 'Đã quá hạn thực hiện giấy đề nghị trả hàng';
									|ru = 'Просрочено исполнение заявок';
									|en = 'Overdue request execution'; fa = 'Overdue request execution';
									|it = 'Esecuzione delle domande scaduta';
									|pl = 'Zaległe wykonanie wniosków';
									|tr = 'Süresi geçmiş talepler'");
	ToDoItem.Count     = Result.RequestsForReturnOfGoodsFromCustomersOverdueExecution;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "RequestsForReturnOfGoodsFromCustomers";
	
	If Result.RequestsForReturnOfGoodsFromCustomersAreStillInProgress > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

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

// Returns the Query Text of the document's goods when filling in based on.
//
// Parameters:
// 	Filter - String
// 	JoinText - String
// 	SupplementSeriesTable - Boolean
//
// Returns:
// 	String
//
Function QueryTextDocumentGoods(Filter, JoinText = "", SupplementSeriesTable = False) Export
	
	QueryTextJoiningTables =
	"Table.Ref = DataOfAccounting.PurchaseOrder
	|		AND Table.RowCode = DataOfAccounting.RowCode";
	
	If ValueIsFilled(JoinText) Then
		QueryTextJoiningTables = JoinText;
	EndIf;
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.Products AS Products,
	|	Table.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Table.Characteristic AS Characteristic,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	CASE
	|		WHEN Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|			THEN 1
	|		ELSE 0
	|	END AS SetIndex,
	|	Table.Package AS Package,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.DateOfReceipt AS DateOfReceipt,
	|	Table.Count AS Count,
	|	Table.Price AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	Table.AmountIncludingVAT AS AmountIncludingVAT,
	|	Table.RowCode AS RowCode,
	|	Table.Damage AS Damage,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.Series AS Series,
	|	Table.Purpose AS Purpose,
	|	Table.Warehouse AS Warehouse
	|INTO GoodsSelectionTable
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS Table
	|WHERE
	|	NOT Table.Canceled
	|	AND &Filter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	&TextOfBatchField AS Series,
	|	Table.RowCode AS RowCode,
	|	Table.DateOfReceipt AS DateOfReceipt,
	|	&TextOfQuantityField AS Count,
	|	Table.Package AS Package,
	|	Table.Price AS Price,
	|	Table.VATRate AS VATRate,
	|	Table.Warehouse AS Warehouse,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.SetIndex AS SetIndex,
	|	Table.Damage AS Damage,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.AmountIncludingVAT AS AmountIncludingVAT
	|INTO GoodsTable
	|FROM
	|	GoodsSelectionTable AS Table
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.ReturnedBatch AS SeriesTable
	|		ON &TextOfBatchConnectionCondition
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsSelectionTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS PurchaseOrder,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	Table.RowCode AS RowCode,
	|	Table.DateOfReceipt AS DateOfReceipt,
	|	Table.Count AS Count,
	|	DataOfAccounting.ToRegister AS ToRegister,
	|	Table.Package AS Package,
	|	Table.Price AS Price,
	|	Table.VATRate AS VATRate,
	|	Table.Warehouse AS Warehouse,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.SetIndex AS SetIndex,
	|	Table.Damage AS Damage,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.AmountIncludingVAT AS AmountIncludingVAT
	|FROM
	|	GoodsTable AS Table
	|		INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON &ConnectionMethod
	|WHERE
	|	Table.Ref.ThisIsOrderAsInvoice = FALSE
	|	AND NOT DataOfAccounting.Products IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS PurchaseOrder,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Series AS Series,
	|	Table.RowCode AS RowCode,
	|	Table.DateOfReceipt AS DateOfReceipt,
	|	Table.Count AS Count,
	|	Table.Count AS ToRegister,
	|	Table.Package AS Package,
	|	Table.Price AS Price,
	|	Table.VATRate AS VATRate,
	|	Table.Warehouse AS Warehouse,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Table.ProductsInSet AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.SetIndex AS SetIndex,
	|	Table.Damage AS Damage,
	|	Table.Sum AS Sum,
	|	Table.VATAmount AS VATAmount,
	|	Table.AmountIncludingVAT AS AmountIncludingVAT
	|FROM
	|	GoodsTable AS Table
	|WHERE
	|	Table.Ref.ThisIsOrderAsInvoice = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP GoodsTable";
	
	If SupplementSeriesTable Then
		
		TextOfBatchField =
		"CASE
		|		WHEN NOT SeriesTable.Products IS NULL
		|		THEN SeriesTable.Series
		|		ELSE Table.Series
		|	END";
		
		TextOfQuantityField =
		"CASE
		|		WHEN NOT SeriesTable.Products IS NULL
		|		THEN SeriesTable.Count
		|		ELSE Table.Count
		|	END";
		
		TextOfBatchConnectionCondition =
		"Table.Ref = SeriesTable.Ref
		|		AND Table.Products = SeriesTable.Products
		|		AND Table.Characteristic = SeriesTable.Characteristic
		|		AND Table.ProductsRecordingAsReceived = SeriesTable.ProductsRecordingAsReceived
		|		AND Table.CharacteristicRecordingAsReceived = SeriesTable.CharacteristicRecordingAsReceived
		|		AND Table.Purpose = SeriesTable.Purpose
		|		AND Table.Warehouse = SeriesTable.Warehouse";
		
	Else
		
		TextOfBatchField = "Table.Series";
		TextOfQuantityField = "Table.Count";
		TextOfBatchConnectionCondition = "FALSE";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&TextOfBatchField",
		TextOfBatchField);
	
	QueryText = StrReplace(QueryText,
		"&TextOfQuantityField",
		TextOfQuantityField);
	
	QueryText = StrReplace(QueryText,
		"&TextOfBatchConnectionCondition",
		TextOfBatchConnectionCondition);
	
	QueryText = StrReplace(QueryText,
		"&ConnectionMethod",
		QueryTextJoiningTables);
	
	QueryText = StrReplace(QueryText,
		"&Filter",
		TMCommonUse.SelectionTextBySelectionCollection(Filter));
	
	Return QueryText;
	
EndFunction

// The Query Text of the goods transmitted.
// 
// Returns:
//  See Documents.ReceiptOfGoodsFromCustodian.QueryTextGoodsTransferred
//
Function QueryTextGoodsTransferred() Export
	
	Return Documents.ReceiptOfGoodsFromCustodian.QueryTextGoodsTransferred();
	
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.RequestForReturnOfGoodsFromCustomer - The document for which you want to get the data.
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
	|	&Ref                    AS OrderDocument,
	|	&Date                      AS Date,
	|	&ApprovalDate          AS ApprovalDate,
	|	Goods.DateOfShipment        AS DateOfShipment,
	|	Goods.AmountIncludingVAT           AS Sum,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	Goods.Canceled            AS Canceled,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|SELECT 
	|	Goods.OrderDocument                            AS OrderDocument,
	|	Goods.Date                             AS Date,
	|	Goods.ApprovalDate                 AS ApprovalDate,
	|	Goods.DateOfShipment                     AS DateOfShipment,
	|	FALSE                                    AS ExceedingOrder,
	|	SUM(CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END)                              AS PaymentAmount,
	|	0                                       AS AmountARAP,
	|	SUM(CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END)                              AS PackageDepositValue,
	|	0                                       AS AmountARAPByPackage
	|FROM TTProducts_1 AS Goods
	|WHERE
	|	NOT Goods.Canceled
	|GROUP BY
	|	Goods.DateOfShipment,
	|	Goods.OrderDocument,
	|	Goods.Date,
	|	Goods.ApprovalDate
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods");
		Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", "Goods.Ref.ToReturnReusablePackage");
		Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", "Goods.Ref.PackageDepositIsRequired");
		Query.Text = StrReplace(Query.Text, "&Date", "Goods.Ref.Date");
		Query.Text = StrReplace(Query.Text, "&ApprovalDate", "Goods.Ref.ApprovalDate");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInSalesDocumentsJournal

Function TextOfOrdersInProgressRequest()

	QueryText = 
	"SELECT ALLOWED TOP 1
	|	OrderStates.OrderDocument,
	|	OrderStates.State
	|FROM
	|	InformationRegister.SalesOrderStates AS OrderStates
	|WHERE
	|	OrderStates.State <> VALUE(Enum.SalesOrderStates.Closed)";
	
	Return QueryText
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.SalesOrderStates)
			And AccessRight("Update", Metadata.Documents.RequestForReturnOfGoodsFromCustomer)
			And GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")
			And GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Giấy đề nghị trả hàng';
						|ru = 'Заявки на возврат';
						|en = 'Return requests'; fa = 'درخواست‌های برگشت';
						|it = 'Richieste di reso';
						|pl = 'Zgłoszenia do zwrotu';
						|tr = 'İade talepleri'");
	Query = New Query(TextOfOrdersInProgressRequest());
	
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameWorkplace());
	Else
		Return New FormattedString(HyperlinkText,,,,
			FormNameWorkplace());
	EndIf;
	
EndFunction

Function FormNameWorkplace() Export
	
	Return "Document.RequestForReturnOfGoodsFromCustomer.Form.DocumentsListForm";
	
EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.RequestForReturnOfGoodsFromCustomer, FormDataStructure - a refund request for which you need to get a destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfGoodsAssignmentInSales.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfGoodsAssignmentInSales.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
