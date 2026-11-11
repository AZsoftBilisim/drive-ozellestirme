
#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		
		If (Parameters.Property("Basis")
			And ValueIsFilled(Parameters.Basis))
			Or (Parameters.Property("Key") And Not ValueIsFilled(Parameters.Key)) Then
			
			StandardProcessing = False;
			SelectedForm = "CWPDocumentForm";
			
		ElsIf Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
			
			StandardProcessing = False;
			SelectedForm = "DocumentForm";
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

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
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("PricesAndDiscounts");
	CashRegisterReceiptReturnLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of value table elements with data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CashRegisterReceiptReturn") Then
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
		
		QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers);
		QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers);
		QueryTextTableCashInTransit(Query, QueryTexts, Registers);
		
		CashRegisterReceiptReturnLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ArrangeShipmentAtRetail(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Status,Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.FullObjectName = "Document.CashRegisterReceiptReturn";
	
	SeriesSpecificationParameters.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer );

	If WarehousesServer.UseWarerooms(Object.Warehouse) Then
		SeriesSpecificationParameters.LinkFields.Add("Premise");
	EndIf;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.SelectionPlanning = True;	
	SeriesSpecificationParameters.FactOfSelection = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.DocumentOperation_ = Enums.BusinessTransactions.ReturnOnSameDayBasis;
	
	SeriesSpecificationParameters.ReadOnly = (Object.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	ThereArePremises = (SeriesSpecificationParameters.LinkFields.Find("Premise") <> Undefined);
	If ThereArePremises Then
		Return RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises();
	Else
		Return TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms();
	EndIf;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure


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
	|	AND ValueAllowed(CashRegister)
	|	AND ValueAllowed(Warehouse)";

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

// Returns a link to the deferred Receipt of the return KKM by the transmitted link to the Receipt of the KKM.
//
// Parameters:
//	CashRegisterReceipt - DocumentRef.CashRegisterReceipt - 
//  PresentationOfDeferredReceiptToCashRegisterRefund - String - If a deferred receipt exists, then its representation is written to this parameter.
// Returns:
//	DocumentRef.CashRegisterReceiptReturn -
Function FindDeferredReceiptCashRegisterRefundOnReceiptCashRegister(CashRegisterReceipt, PresentationOfDeferredReceiptToCashRegisterRefund = "") Export
	
	Result = Documents.CashRegisterReceiptReturn.EmptyRef();
	PresentationOfDeferredReceiptToCashRegisterRefund = "";
	
	Query = New Query;
	Query.Text = "SELECT
			|	CashRegisterReceiptReturn.Ref AS Ref,
			|	CashRegisterReceiptReturn.Presentation AS Presentation
			|FROM
			|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
			|WHERE
			|	CashRegisterReceiptReturn.CashRegisterReceipt = &CashRegisterReceipt
			|	AND CashRegisterReceiptReturn.Status <> VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)";
	Query.SetParameter("CashRegisterReceipt", CashRegisterReceipt);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
		PresentationOfDeferredReceiptToCashRegisterRefund = Selection.Presentation;
	EndIf;	
	
	Return Result;
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceiptReturn - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
	Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Warehouse;
	
	FillParameters.Retail_ = True;
	
	Return FillParameters;
	
EndFunction

// Determines the availability of the document receipt Cash register refund via the transmitted link to the Receipt Cash register.
// The Cash Register refund check must be carried out and reflected in the register of Fiscal operation information.
//
// Parameters:
//	CashRegisterReceipt - DocumentRef.CashRegisterReceipt - 
//
// Returns:
//	Boolean -
Function ThereIsRefundByReceiptCashRegister(CashRegisterReceipt) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CashRegisterReceiptReturn.Ref AS Ref
	|FROM
	|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|		INNER JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON CashRegisterReceiptReturn.Ref = FiscalTransactions.DocumentBasis
	|	
	|WHERE
	|	CashRegisterReceiptReturn.Posted
	|	AND CashRegisterReceiptReturn.CashRegisterReceipt = &CashRegisterReceipt
	|	AND (FiscalTransactions.CashRegisterReceiptNumber <> &IsBlankString)";
	Query.SetParameter("CashRegisterReceipt", CashRegisterReceipt);
	Query.SetParameter("IsBlankString", "");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef) Export
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                        AS Ref,
	|	DocumentData.Archived                                      AS Archived,
	|	DocumentData.CashRegister.Owner                             AS Organization,
	|	DocumentData.Partner                                       AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef)                 AS Counterparty,
	|	DocumentData.Date                                          AS Period,
	|	DocumentData.Currency                                        AS Currency,
	|	VALUE(Enum.BusinessTransactions.ReturnOnSameDayBasis) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.RefundToCustomer) AS CashFlowItem,
	|	DocumentData.Warehouse                                         AS Warehouse,
	|	DocumentData.PriceIncludesVAT                               AS PriceIncludesVAT,
	|	DocumentData.Status                                        AS Status,
	|	DocumentData.CashRegisterReceipt.Date                                   AS DateCashRegisterReceipt,
	|	DocumentData.CompanyUSAIS                              AS CompanyUSAIS,
	|	DocumentData.CashRegisterReceipt.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	DocumentData.CashRegister.Department                        AS Department
	|
	|FROM
	|	Document.CashRegisterReceiptReturn AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Archived",                                 Attributes.Archived);
	Query.SetParameter("Ref",                                   DocumentRef);
	Query.SetParameter("Warehouse",                                    Attributes.Warehouse);
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("Currency",                                   Attributes.Currency);
	Query.SetParameter("Organization",                              Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation",                    Attributes.BusinessOperation);
	Query.SetParameter("CashFlowItem",            Attributes.CashFlowItem);
	Query.SetParameter("ReceiptCompleted",                                Attributes.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Query.SetParameter("Partner",                                  Attributes.Partner);
	Query.SetParameter("LoyaltyProgram",              Attributes.LoyaltyProgram);
	Query.SetParameter("CompanyUSAIS",                         Attributes.CompanyUSAIS);
	Query.SetParameter("CurrentDate",                              CurrentUniversalDate());
	Query.SetParameter("StartDateOfBonusPointsMechanism_2_5", Constants.StartDateOfBonusPointsMechanism_2_5.Get());
	Query.SetParameter("Department",                            Attributes.Department);
	
EndProcedure

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableAmountByPaymentCards", QueryTexts) Then
		QueryTextTTTableAmountByPaymentCards(Query, QueryTexts);
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.CashRegister.Owner AS Organization,
	|	DocumentData.CashRegister AS CashRegister,
	|	DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0) AS Sum,
	|	CAST((DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0)) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0)) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomer) AS BusinessOperation,
	|	&CashFlowItem AS CashFlowItem
	|FROM
	|	Document.CashRegisterReceiptReturn AS DocumentData
	|		LEFT JOIN TTTableAmountByPaymentCards AS TableAmountByPaymentCards
	|		ON (TRUE)
	|WHERE
	|	DocumentData.DocumentAmount - ISNULL(TableAmountByPaymentCards.Sum, 0) <> 0
	|	AND DocumentData.Ref = &Ref
	|	AND (NOT &Archived)
	|	AND &ReceiptCompleted
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard) AS CashType,
	|	&Organization                                   AS Organization,
	|	&Currency                                        AS Currency,
	|	PaymentTable_3.POSTerminal          AS POSTerminal,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END AS Contract,
	|	PaymentTable_3.AuthorizationCode                 AS AuthorizationCode,
	|	PaymentTable_3.PaymentCardNumber            AS PaymentCardNumber,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard) AS BusinessOperation,
	|	CFItems.CashFlowItem        AS CashFlowItem,
	|	&Period                                        AS PaymentDate,
	|	PaymentTable_3.Sum                          AS Sum
	|FROM
	|	Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|WHERE
	|	PaymentTable_3.PaymentIsCanceled
	|	AND PaymentTable_3.Ref = &Ref
	|	AND (NOT &Archived)
	|	AND CASE
	|		WHEN PaymentTable_3.ConnectionContract <> VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.DetailedTransactionReconciliation
	|		ELSE ISNULL(PaymentTable_3.POSTerminal.Owner.DetailedTransactionReconciliation, TRUE)
	|	END
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCashFlowArticles", QueryTexts) Then
		QueryTextTTCashFlowArticles(QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	PaymentTable_3.LineNumber                                                          AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
	|	&Period                                                                              AS Period,
	|	&Organization                                                                         AS Organization,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.BankAccount
	|		ELSE PaymentTable_3.POSTerminal.Owner.BankAccount
	|	END                                                                                AS Recipient,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract.Counterparty
	|		ELSE PaymentTable_3.POSTerminal.Owner.Counterparty
	|	END                                                                                AS Counterparty,
	|	CASE
	|		WHEN NOT PaymentTable_3.ConnectionContract = VALUE(Catalog.AcquiringContracts.EmptyRef)
	|			THEN PaymentTable_3.ConnectionContract
	|		ELSE PaymentTable_3.POSTerminal.Owner
	|	END                                                                                AS Contract,
	|	UNDEFINED                                                                         AS PaymentDocument,
	|	&Currency                                                                              AS Currency,
	|	PaymentTable_3.Sum                                                                AS Sum,
	|	CAST(PaymentTable_3.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))    AS SumMan,
	|	CAST(PaymentTable_3.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))   AS SumCompl,
	|	VALUE(Enum.BusinessTransactions.RefundToCustomerSPaymentCard)    AS BusinessOperation,
	|	CFItems.CashFlowItem                                              AS CashFlowItem
	|FROM
	|	Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN TTCashFlowArticles AS CFItems
	|		ON PaymentTable_3.LineNumber = CFItems.LineNumber
	|WHERE
	|	PaymentTable_3.PaymentIsCanceled
	|	AND PaymentTable_3.Ref = &Ref
	|	AND (NOT &Archived)
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCashFlowArticles(QueryTexts)
	
	RegisterName = "TTCashFlowArticles";
	
	QueryText = 
	"SELECT
	|	PaymentTable_3.LineNumber AS LineNumber,
	|	CASE
	|		WHEN NOT ISNULL(InformationAboutContract.CashFlowItemReturn, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN InformationAboutContract.CashFlowItemReturn
	|		WHEN NOT ISNULL(InformationAboutContractForTerminal.CashFlowItemReturn, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|			THEN InformationAboutContractForTerminal.CashFlowItemReturn
	|		ELSE &CashFlowItem
	|	END AS CashFlowItem
	|INTO TTCashFlowArticles
	|FROM
	|	Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS PaymentTable_3
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContract
	|		ON PaymentTable_3.ConnectionContract = InformationAboutContract.Ref
	|		LEFT JOIN Catalog.AcquiringContracts AS InformationAboutContractForTerminal
	|		ON PaymentTable_3.POSTerminal.Owner = InformationAboutContractForTerminal.Ref
	|WHERE
	|	PaymentTable_3.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryTexts;
	
EndFunction

Procedure ArrangeShipmentAtRetail(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	TRUE								AS GoodsReturn
	|FROM
	|	Document.CashRegisterReceiptReturn.Goods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|	AND NOT DocumentGoods.Ref.Archived
	|	AND DocumentGoods.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)";
	
	MetadataObject	= Metadata.Documents.CashRegisterReceiptReturn;
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.SynonymForDocumentTable = "DocumentGoods";
	
	WarehousesServer.ArrangeShipmentAtRetail(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										MethodParameters);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Ref AS Document,
	|	&Partner AS Sender,
	|	&Warehouse AS Recipient,
	|	SeriesTable.Premise AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	SeriesTable.LineNumber AS LineNumber,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.CashRegisterReceiptReturn.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND (NOT &Archived)
	|	AND &ReceiptCompleted
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Ref,
	|	&Partner,
	|	&Warehouse,
	|	GoodsTable.Premise,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer),
	|	&Period,
	|	&Ref,
	|	GoodsTable.LineNumber,
	|	TRUE
	|FROM
	|	Document.CashRegisterReceiptReturn.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND NOT &Archived
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &ReceiptCompleted
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBonusPoints(Query, QueryTexts, Registers)
	
	RegisterName = "BonusPoints";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
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

Function QueryTextTTTableAmountByPaymentCards(Query, QueryTexts)
	
	RegisterName = "TTTableAmountByPaymentCards";
	
	QueryText = 
	"SELECT
	|	SUM(TabularSection.Sum) AS Sum
	|INTO TTTableAmountByPaymentCards
	|FROM
	|	Document.CashRegisterReceiptReturn.PaymentWithPaymentCards AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND TabularSection.PaymentIsCanceled
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	
	QueryText = 
	"SELECT
	|	TabularSection.AccrualDate AS Period,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS ValidityStartDate,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS Accrued,
	|	0 AS ToWriteOff
	|INTO TTBonusPoints
	|FROM
	|	Document.CashRegisterReceiptReturn.BonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND NOT &Partner = VALUE(Catalog.Partners.RetailCustomer)
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|	AND TabularSection.AccrualDate <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TabularSection.DateOfDeduction AS Period,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN TabularSection.AccrualDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN BEGINOFPERIOD(TabularSection.DateOfDeduction,
	|			DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	TabularSection.LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	0 AS Accrued,
	|	CASE
	|		WHEN TabularSection.AmountOfBonusPoints > 0
	|			THEN -TabularSection.AmountOfBonusPoints
	|		ELSE TabularSection.AmountOfBonusPoints
	|	END AS ToWriteOff
	|FROM
	|	Document.CashRegisterReceiptReturn.BonusPoints AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND NOT &Partner = VALUE(Catalog.Partners.RetailCustomer)
	|	AND &ReceiptCompleted
	|	AND NOT &Archived
	|	AND TabularSection.DateOfDeduction <> DATETIME(1, 1, 1)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(CashRegisterReceiptReturn.Date, DAY) AS Period,
	|	DATETIME(1, 1, 1),
	|	CASE
	|		WHEN BEGINOFPERIOD(&Period, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END,
	|	CASE
	|		WHEN CashRegisterReceiptReturn.AmountOfBonusPointsToReturn > 0
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&LoyaltyProgram AS LoyaltyProgram,
	|	&Partner AS Partner,
	|	CASE
	|		WHEN CashRegisterReceiptReturn.AmountOfBonusPointsToReturn > 0
	|			THEN -CashRegisterReceiptReturn.AmountOfBonusPointsToReturn
	|		ELSE CashRegisterReceiptReturn.AmountOfBonusPointsToReturn
	|	END AS Accrued,
	|	CASE
	|		WHEN BEGINOFPERIOD(&Period, DAY) >= BEGINOFPERIOD(&StartDateOfBonusPointsMechanism_2_5, DAY)
	|			THEN 0
	|		ELSE CASE
	|			WHEN CashRegisterReceiptReturn.AmountOfBonusPointsToReturn > 0
	|				THEN -CashRegisterReceiptReturn.AmountOfBonusPointsToReturn
	|			ELSE CashRegisterReceiptReturn.AmountOfBonusPointsToReturn
	|		END
	|	END
	|FROM
	|	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|WHERE
	|	CashRegisterReceiptReturn.Ref = &Ref
	|	AND NOT &Partner = VALUE(Catalog.Partners.RetailCustomer)
	|	AND &ReceiptCompleted
	|	AND NOT &Archived";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																			Query.Parameters.Currency,
																			Query.Parameters.Period,
																			Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|				&Department
		|			ELSE
		|				TabPart.Ref.Warehouse
		|		END                                    AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.CashRegisterReceiptReturn.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Archived
		|	AND TabPart.Ref.Status = VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
		|	AND TabPart.NumberOfPackages <> 0";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	CashRegisterReceiptReturnLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
EndProcedure

// The function receives data for generating the printed form of the Product receipt.
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultForTabularPart - QueryResult
// 		* DocumentTitle - String
//
Function GetDataForPrintedFormProductReceipt(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);

	Query = New Query(
	"SELECT
	|	DocReceipt.Number                     AS Number,
	|	DocReceipt.Date                      AS Date,
	|	DocReceipt.Ref                    AS Ref,
	|	DocReceipt.CashRegister                  AS CashRegister,
	|	DocReceipt.Currency                    AS Currency,
	|	DocReceipt.PriceIncludesVAT           AS PriceIncludesVAT,
	|	DocReceipt.CashRegister.Presentation    AS Customer,
	|	DocReceipt.Cashier.Individual     AS EmployeeResponsible,
	|	DocReceipt.Organization               AS Organization,
	|	DocReceipt.Organization.Prefix       AS Prefix,
	|	DocReceipt.Organization.Presentation AS Vendor,
	|	DocReceipt.DocumentAmount            AS DocumentAmount,
	|	DocReceipt.CashRegister.Department    AS Department
	|FROM
	|	Document.CashRegisterReceiptReturn AS DocReceipt
	|WHERE
	|	DocReceipt.Ref IN (&DocumentsArray)
	|ORDER BY
	|	DocReceipt.PointInTime
	|;
	|
	|SELECT
	|	Table.Ref                            AS Ref,
	|
	|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                                                 AS ProductsInSet,
	|	Table.ItemVariantOfSet                                               AS ItemVariantOfSet,
	|
	|	Table.LineNumber        AS LineNumber,
	|	Table.Products       AS Products,
	|	Table.Characteristic     AS Characteristic,
	|	Table.Count         AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Package                          AS Package,
	|	Table.Price                              AS Price,
	|	Table.NumberOfPackages * Table.Price - Table.Sum AS DiscountAmount,
	|	Table.NumberOfPackages * Table.Price                 AS AmountWithoutADiscount,
	|	Table.Sum                                             AS Sum,
	|	Table.VATAmount                                          AS VATAmount,
	|	Table.Premise                                         AS Premise
	|INTO Goods
	|FROM
	|	Document.CashRegisterReceiptReturn.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN (&DocumentsArray)
	|	AND Table.NumberOfPackages <> 0
	|;
	|
	|
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
	|	CashRegisterReceiptReturn.Ref                                                                    AS Ref,
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
	|	LEFT JOIN Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
	|	ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|	AND CashRegisterReceiptReturn.Ref IN (&DocumentsArray)
	|
	|GROUP BY
	|	CashRegisterReceiptReturn.Ref,
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
	|	TemporaryTableSetsOptional.PresentationOptionInPrintForms,
	|	TemporaryTableSetsOptional.SetPricingOption,
	
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount,
	|	Table.DiscountAmount                       AS DiscountAmount,
	|	Table.AmountWithoutADiscount                    AS AmountWithoutADiscount
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
	|
	|
	|
	|SELECT
	|	Table.Ref                            AS Ref,
	|
	|	Table.Ref                                    AS ItemKitConfiguration,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                        AS ProductsInSet,
	|	Table.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	Table.TheseAreComponents                          AS TheseAreComponents,
	|	Table.IsRecordsSet                                  AS IsRecordsSet,
	|
	|	Table.LineNumber                       AS LineNumber,
	|	Table.Products.DescriptionFull   AS FullNameOfProduct_,
	|	Table.Products.Code                  AS Code,
	|	Table.Products.SKU              AS SKU,
	|	Table.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Table.Package.Description
	|	END                      AS PackageName,
	|	Table.NumberOfPackages AS Count,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(Table.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(Table.Package)
	|	END                                     AS UnitOfMeasure,
	|	Table.Package                          AS Package,
	|	Table.Price                              AS Price,
	|	Table.NumberOfPackages * Table.Price - Table.Sum AS DiscountAmount,
	|	Table.Sum                                             AS Sum,
	|	Table.VATAmount                                          AS VATAmount,
	|	Table.Premise                                         AS Premise
	|FROM
	|(
	|	SELECT
	|		Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		Table.SetPricingOption AS SetPricingOption,
	|		Table.Ref,
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
	|		Table.Premise
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
	|	        AND Table.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.Ref,
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
	|		UNDEFINED AS Premise
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Table
	|
	|ORDER BY
	|	Table.LineNumber,
	|	IsRecordsSet DESC
	|");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	Query.SetParameter("DocumentsArray", ObjectsArray);
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure(
		"HeaderResults, ResultForTabularPart, DocumentTitle",
		RequestResultsPackage[0],
		RequestResultsPackage[RequestResultsPackage.Count() - 1],
		NStr("vi = 'Phiếu tính tiền (trả lại)';
			|ru = 'Товарный чек на возврат';
			|en = 'Refund sales receipt'; fa = 'Refund sales receipt';
			|it = 'Ricevuta di vendita da rendere';
			|pl = 'Paragon towarowy do zwrotu';
			|tr = 'Satış iadesi makbuzu'"));
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return DataStructureForPrinting;
	
EndFunction

// The function receives data for forming the KM-3 printing form.
//
// Returns:
// 	Structure:
// 		* QueryResul - QueryResult
// 		* DocumentTitle - String
//
Function GetDataForPrintedFormKM3(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	DocReceipt.Ref AS Ref,
	|	DocReceipt.Number AS Number,
	|	DocReceipt.Date AS DocumentDate,
	|	DocReceipt.CashRegister AS CashRegister,
	|	DocReceipt.CashRegister.CashRegisterType AS CashRegisterType,
	|	DocReceipt.CashRegister.Presentation AS Customer,
	|	DocReceipt.Cashier.Individual AS CashierCashRegister_,
	|	DocReceipt.Currency AS Currency,
	|	DocReceipt.Organization AS Organization,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	DocReceipt.Organization.Presentation AS Vendor,
	|	DocReceipt.CashRegister.SerialNumber AS CashRegisterSerialNumber,
	|	DocReceipt.CashRegister.RegistrationNumber AS CashRegisterRegistrationNumber,
	|	DocReceipt.CashRegister.Description AS CashRegisterPresentation
	|FROM
	|	Document.CashRegisterReceiptReturn AS DocReceipt
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON DocReceipt.Ref = TableResponsiblePersons.Ref
	|WHERE
	|	DocReceipt.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	DocReceipt.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocReceipt.Ref                                           AS Document,
	|	FiscalTransactions.CashRegisterReceiptNumber 						AS ReceiptNumber,
	|	DocReceipt.DocumentAmount                                   AS DocumentAmount
	|FROM
	|	Document.CashRegisterReceiptReturn AS DocReceipt
	|		LEFT JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON FiscalTransactions.DocumentBasis = DocReceipt.Ref
	|WHERE
	|	DocReceipt.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Document
	|TOTALS BY
	|	Document";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	QueryResult = Query.ExecuteBatch();
	
	DataStructureForPrinting    = New Structure("QueryResult, DocumentTitle",
		QueryResult, NStr("vi = 'КМ-3';
							|ru = 'КМ-3';
							|en = 'KM-3'; fa = 'KM-3';
							|it = 'KM-3';
							|pl = 'KM-3';
							|tr = 'KM-3'"));
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

// Returns the text of the query to calculate the status of the guidance series (With premises)
//	Returns:
//		String - query text.
//
Function RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises()
	
	QueryText = 
	"SELECT
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
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
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Premise = ProductsToRequest.Premise
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Premise = SeriesToRequest.Premise
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
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

// Returns the text of the query to calculate the status of the guidance series (Without spaces)
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms()
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
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
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			ON Goods.Products = ProductsToRequest.Products
	|				AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON Goods.Products = SeriesToRequest.Products
	|				AND Goods.Characteristic = SeriesToRequest.Characteristic
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
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

#EndIf
