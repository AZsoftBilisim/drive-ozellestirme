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
	
	DocumentMechanisms.Add("DocumentsRegistry");
	
	CustomerCommercialInvoiceLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.CustomerCommercialInvoice") Then
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
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CustomerCommercialInvoiceLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
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
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CustomerCommercialInvoice.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CustomerCommercialInvoice);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateBasedOnInvoiceCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then 
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreatePaymentInvoice";
		CreateBasedOnCommand.Id = "CreatePaymentInvoice";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Hóa đơn thanh toán';
												|ru = 'Счета на оплату';
												|en = 'Commercial invoices'; fa = 'فاکتورهای تجاری';
												|it = 'Fatture per il pagamento';
												|pl = 'Rachunki do zapłaty';
												|tr = 'Ticari faturalar'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateReportBasedOnPaymentInvoiceCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateInvoiceForPaymentImplementationReport";
		CreateBasedOnCommand.Id = "CreateInvoiceForPaymentImplementationReport";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
												|ru = 'Счет на оплату';
												|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
												|it = 'Fattura di pagamento';
												|pl = 'Rachunek do zapłaty';
												|tr = 'Ticari fatura'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateBasedOnContractInvoiceCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then 
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CommercialInvoiceDebt";
		CreateBasedOnCommand.Id = "CommercialInvoiceDebt";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (theo công nợ)';
												|ru = 'Счет на оплату (по задолженности)';
												|en = 'Commercial invoice (debt)'; fa = 'فاکتور تجاری (بدهی)';
												|it = 'Fattura di pagamento (indebitamento)';
												|pl = 'Rachunek do zapłaty (w ramach zadłużenia)';
												|tr = 'Ticari fatura (borca göre)'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateBasedOnInvoiceForPaymentPrepaymentUnderContractCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then 
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CommercialInvoicePrepayment";
		CreateBasedOnCommand.Id = "CommercialInvoicePrepayment";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (trả trước)';
												|ru = 'Счет на оплату (предоплата)';
												|en = 'Commercial invoice (prepayment)'; fa = 'فاکتور تجاری (پیش‌پرداخت)';
												|it = 'Fattura di pagamento (pagamento anticipato)';
												|pl = 'Rachunek do zapłaty (przedpłata)';
												|tr = 'Ticari fatura (ön ödeme)'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction


// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCreateMerchantOrderBasedOnInvoiceCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then 
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateInvoiceForPaymentForGiverSOrder";
		CreateBasedOnCommand.Id = "CreateInvoiceForPaymentForGiverSOrder";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
												|ru = 'Счет на оплату';
												|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
												|it = 'Fattura di pagamento';
												|pl = 'Rachunek do zapłaty';
												|tr = 'Ticari fatura'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Invoice for payment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddCommandCreateReportToGiverBasedOnInvoice2_5(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.CustomerCommercialInvoice) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler    = "GenerationByReferenceTMClient.CreateInvoiceForPaymentReportToGiver2_5";
		CreateBasedOnCommand.Id = "CreateInvoiceForPaymentReportToGiver2_5";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Hóa đơn thanh toán';
												|ru = 'Счет на оплату';
												|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
												|it = 'Fattura di pagamento';
												|pl = 'Rachunek do zapłaty';
												|tr = 'Ticari fatura'");
		CreateBasedOnCommand.WriteMode   = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerCommercialInvoices";
		
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
	
EndProcedure

// Returns the amount of the invoice base document
//
// Parameters:
//	DocumentBasis - DocumentRef.SalesOrder, DocumentRef.CustomerInvoice - 
//
// Returns:
//	Number - The amount of the document is the basis, if the document is not an empty link, 0 otherwise.
//
Function GetAmountOfFoundationDocument(DocumentBasis) Export
	
	DocumentAmount = 0;
	
	If ValueIsFilled(DocumentBasis) Then
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.SalesOrder") Then
			QueryText = "
			|SELECT ALLOWED
			|	CASE WHEN DocumentSales.PackageDepositIsRequired THEN
			|		DocumentSales.DocumentAmount + DocumentSales.ReturnablePackagingAmount
			|	ELSE
			|		DocumentSales.DocumentAmount
			|	END AS DocumentAmount
			|FROM
			|	Document.SalesOrder AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|	AND DocumentSales.BusinessOperation <> VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
			|	
			|	UNION ALL
			|
			|SELECT
			|	SettlementsWithCustomersTurnover.SumReceipt + SettlementsWithCustomersTurnover.AmountDueReceipt AS DocumentAmount
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Turnovers AS SettlementsWithCustomersTurnover
			|WHERE
			|	SettlementsWithCustomersTurnover.ARAPObject.Object = &Ref
			|	AND SettlementsWithCustomersTurnover.ARAPObject.Object REFS Document.SalesOrder
			|	AND SettlementsWithCustomersTurnover.ARAPObject.Object.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
			|";
			
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			QueryText = "
			|SELECT
			|	CASE WHEN DocumentSales.PackageDepositIsRequired THEN
			|		DocumentSales.ReplacementAmount + DocumentSales.ReturnablePackagingAmount
			|	ELSE
			|		DocumentSales.ReplacementAmount
			|	END AS DocumentAmount
			|FROM
			|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
			QueryText = "
			|SELECT TOP 1
			|	DocumentData.DocumentBasis AS DocumentBasis,
			|	DocumentData.DocumentAmount AS DocumentAmount
			|INTO Adjusting
			|FROM
			|	Document.SaleAdjustment AS DocumentData
			|WHERE
			|	DocumentData.DocumentBasis = &Ref
			|	AND DocumentData.Posted
			|
			|ORDER BY
			|	DocumentData.PointInTime DESC
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(Adjusting.DocumentAmount, DocumentSales.DocumentAmount) AS DocumentAmount
			|FROM
			|	Document.CustomerInvoice AS DocumentSales
			|		LEFT JOIN Adjusting AS Adjusting
			|		ON DocumentSales.Ref = Adjusting.DocumentBasis
			|WHERE
			|	DocumentSales.Ref = &Ref";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
			QueryText = "
			|SELECT
			|	DocumentSales.DocumentAmount AS DocumentAmount
			|FROM
			|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
			QueryText = 
			"SELECT TOP 1
			|	DocumentData.DocumentBasis AS DocumentBasis,
			|	DocumentData.DocumentAmount AS DocumentAmount
			|INTO Adjusting
			|FROM
			|	Document.SaleAdjustment AS DocumentData
			|WHERE
			|	DocumentData.DocumentBasis = &Ref
			|	AND DocumentData.Posted
			|
			|ORDER BY
			|	DocumentData.PointInTime DESC
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(Adjusting.DocumentAmount, DocumentSales.DocumentAmount) AS DocumentAmount
			|FROM
			|	Document.CustomerInvoiceServices AS DocumentSales
			|		LEFT JOIN Adjusting AS Adjusting
			|		ON DocumentSales.Ref = Adjusting.DocumentBasis
			|WHERE
			|	DocumentSales.Ref = &Ref";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor") Then
			QueryText = "
			|SELECT
			|	ConsignmentReportToVendor.CommissionAmount AS DocumentAmount
			|FROM
			|	Document.ConsignmentReportToVendor AS ConsignmentReportToVendor
			|WHERE
			|	ConsignmentReportToVendor.Ref = &Ref
			|";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			QueryText = "
			|SELECT
			|	DocumentSales.DocumentAmount AS DocumentAmount
			|FROM
			|	Document.ConsignmentReportFromCustomer AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
			QueryText = "
			|SELECT
			|	DocumentSales.DocumentAmount AS DocumentAmount
			|FROM
			|	Document.WriteOffReportFromCommissionAgent AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";	
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5") Then
			QueryText = "
			|SELECT
			|	DocumentSales.DocumentAmount AS DocumentAmount
			|FROM
			|	Document.MaterialProviderOrder2_5 AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";	
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
			QueryText = "
			|SELECT
			|	DocumentSales.DocumentAmount AS DocumentAmount
			|FROM
			|	Document.ReportToMaterialProvider2_5 AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.RedemptionOfGoodsByCustodian") Then
			QueryText = "
			|SELECT
			|	DocumentSales.DocumentAmount AS DocumentAmount
			|FROM
			|	Document.RedemptionOfGoodsByCustodian AS DocumentSales
			|WHERE
			|	DocumentSales.Ref = &Ref
			|";	
		
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
			QueryText = "
			|SELECT
			|	PurchasingReportToConsignorPrincipal.DocumentAmount+PurchasingReportToConsignorPrincipal.CommissionAmount AS DocumentAmount
			|FROM
			|	Document.PurchasingReportToConsignorPrincipal AS PurchasingReportToConsignorPrincipal
			|WHERE
			|	PurchasingReportToConsignorPrincipal.Ref = &Ref
			|";	
		Else
			QueryText = "";
		EndIf;
	
		If Not IsBlankString(QueryText) Then
			
			Query = New Query(QueryText);
			Query.SetParameter("Ref", DocumentBasis);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				DocumentAmount  = Selection.DocumentAmount;
			EndIf;
			
		EndIf;
		
	EndIf;
		
	Return DocumentAmount;
	
EndFunction

// Sets the Canceled invoices for payment to customers flag
//
// Parameters:
//  ProformaInvoices - Array - references of invoices for payment.
//
// Returns:
//  Number - the number of documents that have the Canceled attribute set.
//
Function SetInvalidFlag(Val ProformaInvoices) Export
	
	ReferencesArrray = New Array();
	ProcessedItemsCount = 0;
	
	For Each ProformaInvoice In ProformaInvoices Do
	
		If TypeOf(ProformaInvoice) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(ProformaInvoice);
		
	EndDo;
	
	If ReferencesArrray = 0 Then
		Return ProcessedItemsCount;
	EndIf;
	
	Query = New Query("
		|SELECT
		|	CustomerCommercialInvoice.Ref AS Ref
		|FROM
		|	Document.CustomerCommercialInvoice AS CustomerCommercialInvoice
		|WHERE
		|	CustomerCommercialInvoice.Ref IN(&ReferencesArrray)
		|	AND NOT CustomerCommercialInvoice.Canceled_
		|");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Selection = Query.Execute().Select();
		
	BeginTransaction();
	
	Try
	
		While Selection.Next() Do
			
			Try
				LockDataForEdit(Selection.Ref);
			Except
				
				ErrorText = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
								|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
								|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
								|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
								|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
								|tr = '%Document% engellenemedi. %ErrorDescription%'");
				ErrorText = StrReplace(ErrorText, "%Document%",       Selection.Ref);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
				Raise ErrorText;
					
			EndTry;
			
			Object = Selection.Ref.GetObject();
			Object.Canceled_ = True;
			
			NoErrors_ = True;
			
			If Object.Posted Then
				NoErrors_ = Object.CheckFilling();
			EndIf;
				
			If Not NoErrors_ Then
				Continue;
			EndIf;

			Try
				
				Object.Write(?(Object.Posted, DocumentWriteMode.Posting, DocumentWriteMode.Write));
				ProcessedItemsCount = ProcessedItemsCount + 1;
				
			Except
				
				ErrorText = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
								|ru = 'Не удалось записать %Document%. %ErrorDescription%';
								|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
								|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
								|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
								|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
				ErrorText = StrReplace(ErrorText, "%Document%",       Selection.Ref);
				ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
				CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
				Raise ErrorText;
				
			EndTry

		EndDo;
	
		CommitTransaction();
	
	Except
	
		RollbackTransaction();
		WriteLogEvent(
			NStr("vi = 'Ghi hóa đơn thanh toán';
				|ru = 'Запись счетов на оплату';
				|en = 'Save commercial invoices'; fa = 'Save commercial invoices';
				|it = 'Registrazione delle fatture di pagamento';
				|pl = 'Zapisywanie rachunków do zapłaty';
				|tr = 'Ticari faturaların kaydı'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	
	EndTry;
	
	Return ProcessedItemsCount;

EndFunction

// Generates a payment assignment for the invoice for payment to the client
//
// Parameters:
//	Number - String - the number of the document Foundation
//	DocumentBasis - DocumentRef - the document that is the basis of the invoice for payment.
//	Date - Date - the date of foundation, if not specified, is taken by the Documentation parameter
//
// Returns:
//  String - the text of the payment purpose.
//
Function GeneratePaymentPurpose(Val Number, Val DocumentBasis, Val Date = Undefined) Export
	
	TextPurposeOfPayment = "";
	
	If Date = Undefined Then
		Date = Common.ObjectAttributeValue(DocumentBasis, "Date");
	EndIf;
	
	NumberOfBaseDocument = ObjectsPrefixesClientServer.NumberForPrinting(Number, False, True);
	ReferenceDocumentDateForCertificate = Format(Date, "DLF=D");
		
	If TypeOf(DocumentBasis) = Type("DocumentRef.SalesOrder") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по заказу клиента №%Number% от %Date%';
									|vi = 'Payment against sales order No.%Number% dated %Date%';
									|en = 'Payment against sales order No.%Number% dated %Date%'; fa = 'Payment against sales order No.%Number% dated %Date%';
									|it = 'Payment against sales order No.%Number% dated %Date%';
									|pl = 'Payment against sales order No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı müşteri siparişine göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("CatalogRef.TermsOfSale") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по соглашению №%Number% от %Date%';
									|vi = 'Payment by agreement No.%Number% dated %Date%';
									|en = 'Payment by agreement No.%Number% dated %Date%'; fa = 'Payment by agreement No.%Number% dated %Date%';
									|it = 'Payment by agreement No.%Number% dated %Date%';
									|pl = 'Payment by agreement No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı sözleşmeye göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по заявке на возврат №%Number% от %Date%';
									|vi = 'Payment by return request No.%Number% dated %Date%';
									|en = 'Payment by return request No.%Number% dated %Date%'; fa = 'Payment by return request No.%Number% dated %Date%';
									|it = 'Payment by return request No.%Number% dated %Date%';
									|pl = 'Payment by return request No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı iade talebine göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по отчету комиссионера о списании №%Number% от %Date%';
									|vi = 'Payment by consignment stock adjustment No.%Number% dated %Date%';
									|en = 'Payment by consignment stock adjustment No.%Number% dated %Date%'; fa = 'Payment by consignment stock adjustment No.%Number% dated %Date%';
									|it = 'Payment by consignment stock adjustment No.%Number% dated %Date%';
									|pl = 'Payment by consignment stock adjustment No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı konsinye kayıttan düşme raporuna göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по отчету комитенту №%Number% от %Date%';
									|vi = 'Payment by consignment notification No.%Number% dated %Date%';
									|en = 'Payment by consignment notification No.%Number% dated %Date%'; fa = 'Payment by consignment notification No.%Number% dated %Date%';
									|it = 'Payment by consignment notification No.%Number% dated %Date%';
									|pl = 'Payment by consignment notification No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı konsinye bildirimi raporuna göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по отчету комиссионера о продажах №%Number% от %Date%';
									|vi = 'Payment by consignment issue notification No.%Number% dated %Date%';
									|en = 'Payment by consignment issue notification No.%Number% dated %Date%'; fa = 'Payment by consignment issue notification No.%Number% dated %Date%';
									|it = 'Payment by consignment issue notification No.%Number% dated %Date%';
									|pl = 'Payment by consignment issue notification No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı konsinye satış raporuna göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по реализации товаров и услуг №%Number% от %Date%';
									|vi = 'Payment by customer invoice No.%Number% dated %Date%';
									|en = 'Payment by customer invoice No.%Number% dated %Date%'; fa = 'Payment by customer invoice No.%Number% dated %Date%';
									|it = 'Payment by customer invoice No.%Number% dated %Date%';
									|pl = 'Payment by customer invoice No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı ürün ve hizmet satışına göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по выкупу возвратной тары клиентом №%Number% от %Date%';
									|vi = 'Payment under Customer invoice — returnable packaging No.%Number% dated %Date%';
									|en = 'Payment under Customer invoice — returnable packaging No.%Number% dated %Date%'; fa = 'Payment under Customer invoice — returnable packaging No.%Number% dated %Date%';
									|it = 'Payment under Customer invoice — returnable packaging No.%Number% dated %Date%';
									|pl = 'Payment under Customer invoice — returnable packaging No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı müşteri tarafından geri dönüşlü ambalaj satın alımına göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по акту выполненных работ №%Number% от %Date%';
									|vi = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|en = 'Payment by Customer invoice —Services No.%Number% dated %Date%'; fa = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|it = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|pl = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı yapılan iş tutanağına göre ödeme'");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.MaterialProviderOrder2_5")
		  Or TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по акту выполненных работ №%Number% от %Date%';
									|vi = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|en = 'Payment by Customer invoice —Services No.%Number% dated %Date%'; fa = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|it = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|pl = 'Payment by Customer invoice —Services No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı yapılan iş tutanağına göre ödeme'");
	ElsIf TypeOf(DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
		
		TextPurposeOfPayment = Common.ObjectAttributeValue(DocumentBasis, "NameForPrinting");
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.PurchasingReportToConsignorPrincipal") Then
		
		TextPurposeOfPayment = NStr("ru = 'Оплата по отчету комитенту о закупках №%Number% от %Date%';
									|vi = 'Payment by purchase notification No.%Number% dated %Date%';
									|en = 'Payment by purchase notification No.%Number% dated %Date%'; fa = 'Payment by purchase notification No.%Number% dated %Date%';
									|it = 'Payment by purchase notification No.%Number% dated %Date%';
									|pl = 'Payment by purchase notification No.%Number% dated %Date%';
									|tr = '%Date% tarihli %Number% numaralı konsinyatör satın alma raporuna göre ödeme'");
		
	EndIf;
		
	TextPurposeOfPayment = StrReplace(TextPurposeOfPayment, "%Number%", NumberOfBaseDocument);
	TextPurposeOfPayment = StrReplace(TextPurposeOfPayment, "%Date%", ReferenceDocumentDateForCertificate);
		
	Return TextPurposeOfPayment;
	
EndFunction

// Returns paths to invoice Attributes.
// 
// Parameters:
//  FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for calculating settlement parameters.
// 
// Returns:
//  See ARAPAccountingServer.MechanismParameters
Function SettlementParameters_(FillingData = Undefined) Export

	AttributesStructure1 = ARAPAccountingServer.MechanismParameters();
	
	AttributesStructure1.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	AttributesStructure1.ModifiesDeliveryShipmentPlan = False;
	
	AttributesStructure1.LineOfBusiness =   "";
	AttributesStructure1.ARAPObjectSettings =           "";
	AttributesStructure1.Terms =                "";
	AttributesStructure1.CompanyBankAccount = "Object.BankAccount";
	AttributesStructure1.CounterpartyBankAccount = "";
	AttributesStructure1.CashAccount =                     "";
	AttributesStructure1.ForeignCurrencyTransaction =             "";
	AttributesStructure1.VATTaxation =        "";
	AttributesStructure1.FinancialAccountingGroup =    "";
	AttributesStructure1.PathToTSDataPaymentSteps =  "Object.PaymentScheduleSteps";
	AttributesStructure1.Department =             "";
	AttributesStructure1.DateOfShipment =              "";
	
	AttributesStructure1.DocumentBasis =         "Object.DocumentBasis";
	AttributesStructure1.PaymentPurposes =         "Object.PaymentPurposes";
	AttributesStructure1.TSP =                       "";
	
	Return AttributesStructure1;

EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
EndProcedure

#Region FormPrintingProceduresAndFunctions

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ThisIsPartner = UserRightsCached.ThisIsPartner();
	
	If Not ThisIsPartner
		 And GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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

	If ThisIsPartner
		 And GetFunctionalOption("UseCustomerCommercialInvoices") Then
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

	If Not ThisIsPartner
		 And GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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

	If Not ThisIsPartner
		 And GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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

	If ThisIsPartner
		 And GetFunctionalOption("UseCustomerCommercialInvoices") Then
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
	
	If Not ThisIsPartner
		And Constants.UseInternationalPrintingForms.Get() Then
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
	
	CustomerCommercialInvoiceLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Create printed forms of objects
//
// Parameters:
//  ObjectsArray        - Array          - Array of links to objects to be printed (incoming)
//  PrintParameters       - Structure       - Structure of additional print parameters (incoming)
//  PrintFormsCollection - ValueTable - Generated tabular documents (outgoing)
//  PrintObjects         - ValueList  - list of print objects.
//  OutputParameters       - Structure       - Parameters of generated table documents (outgoing).
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	CustomerCommercialInvoiceLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// The function receives data for generating the printed form " Invoice for payment"
//
// Parameters:
//	PrintParameters - Structure - 
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
//
// Returns:
//	Structure - The structure with the fields: "Resultposhapke", "Resultpotamplat", "resultpotableparty".
//
Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

// Generates a set of printed forms based on the passed array of objects
// An array of objects can include various types of objects that support bundled printing.
// 
// Parameters:
//  ObjectsArray - Array - objects for which you need to create sets of printed forms
//  PrintParameters - Structure - print options
//  PrintFormsCollection - ValueTable - Collection of printed forms
//  PrintObjects - ValueList   - list of print objects.
// 
// Returns:
//	Undefined - If it was not possible to form a set of printed forms.
Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.CustomerCommercialInvoice.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
	
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoice");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerCommercialInvoice", PrintKit.Objects);
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
		StructureOfTypes.Insert("Document.CustomerCommercialInvoice", PrintKit.Objects);
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
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.CustomerCommercialInvoice", PrintKit.Objects);
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
		StructureOfTypes.Insert("Document.CustomerCommercialInvoice", PrintKit.Objects);
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
		StructureOfTypes.Insert("Document.CustomerCommercialInvoice", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.CustomerCommercialInvoice",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
		
	CustomerCommercialInvoiceLocalization.CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, PrintFormsSet);
	
EndFunction

// Returns the settings for the set of printing forms used for the object
//
// Returns:
// ValueTable - The returned function prepare a set of printable forms().
//
Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
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
	Else
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
	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceEn", NStr("vi = 'Proforma invoice';
																												|ru = 'Proforma invoice';
																												|en = 'Proforma invoice'; fa = 'پیش‌فاکتور';
																												|it = 'Proforma invoice';
																												|pl = 'Proforma invoice';
																												|tr = 'Proforma invoice'"), 1);
	EndIf;
	CustomerCommercialInvoiceLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
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
	
EndProcedure

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
	|	AND ValueAllowed(Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)";

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

#Region Private

Procedure CheckCorrectnessOfBusinessTransactionOfFoundationDocument(ThereAreErrorsEconomicOperation, BusinessOperation) Export

	If ThereAreErrorsEconomicOperation Then
		
		ErrorText = NStr("vi = 'Không thể nhập trên cơ sở chứng từ có giao dịch kinh tế %BusinessOperation%.';
						|ru = 'Ввод на основании документа с хозяйственной операцией %BusinessOperation% невозможен.';
						|en = 'Generation from a base document with business transaction %BusinessOperation% is not allowed.'; fa = 'Generation from a base document with business transaction %BusinessOperation% is not allowed.';
						|it = 'Inserimento in base al documento con operazione commerciale %BusinessOperation% non è possibile.';
						|pl = 'Wprowadzenie na podstawie dokumentu z operacją gospodarczą %BusinessOperation%nie jest możliwe.';
						|tr = 'Ticari işlem ile temel belgenin girişi %BusinessOperation% imkansız'");
		ErrorText = StrReplace(ErrorText, "%BusinessOperation%", BusinessOperation);
		
		Raise ErrorText;
		
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
	|	Documents.DocumentBasis AS DocumentBasis
	|INTO DocumentsTable
	|FROM
	|	Document.CustomerCommercialInvoice AS Documents
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|INDEX BY
	|	Ref,
	|	DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	Documents.DocumentBasis AS DocumentBasis,
	|	ISNULL(Documents.BankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.BankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.BankAccount.ForeignBank
	|		OR Documents.BankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency THEN
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
	|	CASE
	|		WHEN Documents.DocumentBasis REFS Document.ConsignmentReportToVendor
	|			THEN TRUE
	|		WHEN Documents.DocumentBasis REFS Document.ConsignmentReportFromCustomer
	|			THEN TRUE
	|		WHEN Documents.DocumentBasis REFS Catalog.CounterpartyContracts
	|			THEN TRUE
	|		ELSE Documents.DocumentBasis.PriceIncludesVAT
	|	END AS PriceIncludesVAT,
	|	Documents.DocumentBasis.DocumentAmount AS AmountToReturn,
	|	CASE
	|		WHEN Documents.DocumentBasis.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.DocumentBasis.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.AdditionalInformation AS AdditionalInformation,
	|	Documents.PartialPayment AS PartialPayment,
	|	Documents.PaymentPurposes AS PaymentPurposes,
	|	CASE WHEN Documents.DocumentBasis REFS Document.ConsignmentReportToVendor
	|				AND Documents.DocumentBasis.CommissionAmount = 0 THEN
	|		0
	|	WHEN Documents.DocumentBasis REFS Document.ConsignmentReportToVendor THEN // Summation of the reward <> 0
	|		Documents.DocumentAmount * 100 / Documents.DocumentBasis.CommissionAmount
	|	WHEN Documents.DocumentBasis.DocumentAmount = 0 THEN
	|		0
	|	WHEN Documents.DocumentBasis REFS Catalog.CounterpartyContracts THEN
	|		100
	|	WHEN (Documents.DocumentBasis REFS Document.SalesOrder
	|				OR Documents.DocumentBasis REFS Document.RequestForReturnOfGoodsFromCustomer)
	|				AND Documents.DocumentBasis.PackageDepositIsRequired THEN
	|		Documents.DocumentAmount * 100 / (Documents.DocumentBasis.DocumentAmount + Documents.DocumentBasis.ReturnablePackagingAmount)
	|	WHEN Documents.DocumentBasis REFS Document.PurchasingReportToConsignorPrincipal THEN
	|		Documents.DocumentAmount * 100 / (Documents.DocumentBasis.DocumentAmount + Documents.DocumentBasis.CommissionAmount)
	|	WHEN Documents.DocumentBasis REFS Document.RequestForReturnOfGoodsFromCustomer THEN
	|		Documents.DocumentAmount * 100 / Documents.DocumentBasis.ReplacementAmount
	|	ELSE
	|		Documents.DocumentAmount * 100 / Documents.DocumentBasis.DocumentAmount
	|	END AS PayPercentage,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	UNDEFINED AS Shipper,
	|	UNDEFINED AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	CASE
	|		WHEN RequestForReturnOfGoodsFromCustomer.Ref IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS InvoiceToBeRefunded,
	|	CASE
	|		WHEN Documents.DocumentBasis REFS Catalog.CounterpartyContracts 
	|			THEN Documents.DocumentBasis.VATRate
	|		ELSE UNDEFINED
	|	END AS VATRate,
	|	CASE
	|		WHEN Documents.DocumentBasis REFS Catalog.CounterpartyContracts 
	|			THEN (CAST(Documents.DocumentAmount * (Documents.DocumentBasis.VATRate.Rate1 / 100) / ((Documents.DocumentBasis.VATRate.Rate1 + 100) / 100) AS NUMBER(31, 2)))
	|		ELSE 0
	|	END AS VATAmount
	|FROM
	|	Document.CustomerCommercialInvoice AS Documents
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|		ON Documents.DocumentBasis = RequestForReturnOfGoodsFromCustomer.Ref
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
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
	|	Documents.Ref IN
	|			(SELECT
	|				DocumentsTable.Ref
	|			FROM
	|				DocumentsTable)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentScheduleSteps.Ref AS Ref,
	|	PaymentScheduleSteps.LineNumber AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate AS PaymentDate,
	|	PaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
	|	PaymentScheduleSteps.PaymentAmount AS PaymentAmount,
	|	PaymentScheduleSteps.ThisIsDepositForPackage AS ThisIsDepositForPackage
	|FROM
	|	Document.CustomerCommercialInvoice.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN
	|			(SELECT
	|				DocumentsTable.Ref
	|			FROM
	|				DocumentsTable)
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Ref AS Ref,
	|	DocumentsTable.DocumentBasis.BusinessOperation AS BusinessOperation,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.Count AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.Price
	|		ELSE Goods.Sum/Goods.NumberOfPackages 
	|	END AS Price,
	|	Goods.Sum AS Sum,
	|	Goods.VATRate AS VATRate,
	|	Goods.VATAmount AS VATAmount,
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
	|INTO GoodsPreparation
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.SalesOrder.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|			AND (Goods.Canceled = FALSE)
	|			AND (Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|				OR Goods.Ref.PackageDepositIsRequired
	|				OR NOT Goods.Ref.ToReturnReusablePackage)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref                                     AS Ref,
	|	UNDEFINED                                                 AS BusinessOperation,
	|	Goods.LineNumber                                           AS LineNumber,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	Goods.Products                                          AS Products,
	|	Goods.Characteristic                                        AS Characteristic,
	|	Goods.Package                                              AS Package,
	|	Goods.Count                                            AS Count,
	|	Goods.NumberOfPackages                                    AS NumberOfPackages,
	|	Goods.Price                                                  AS Price,
	|	Goods.Sum                                                 AS Sum,
	|	Goods.VATRate                                             AS VATRate,
	|	Goods.VATAmount                                              AS VATAmount,
	|	0                                                            AS DiscountAmount,
	|	Goods.AmountIncludingVAT - Goods.VATAmount                           AS AmountWithoutADiscount,
	|	FALSE                                                         AS ThisIsReusablePackage,
	|	OrderDocument.ProcessingService                                    AS Content
	|FROM
	|	DocumentsTable AS DocumentsTable
	|	
	|		INNER JOIN Document.MaterialProviderOrder2_5 AS OrderDocument
	|		ON DocumentsTable.DocumentBasis = OrderDocument.Ref
	|	
	|		INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|		 AND NOT Goods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref                                     AS Ref,
	|	UNDEFINED                                                 AS BusinessOperation,
	|	Goods.LineNumber                                           AS LineNumber,
	|	VALUE(Catalog.Products.EmptyRef)               AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	Goods.Products                                          AS Products,
	|	Goods.Characteristic                                        AS Characteristic,
	|	Goods.Package                                              AS Package,
	|	Goods.Count                                            AS Count,
	|	Goods.NumberOfPackages                                    AS NumberOfPackages,
	|	Goods.Price                                                  AS Price,
	|	Goods.Sum                                                 AS Sum,
	|	Report.VATRate                                              AS VATRate,
	|	Goods.VATAmount                                              AS VATAmount,
	|	0                                                            AS DiscountAmount,
	|	Goods.AmountIncludingVAT - Goods.VATAmount                           AS AmountWithoutADiscount,
	|	FALSE                                                         AS ThisIsReusablePackage,
	|	Report.ProcessingService                                    AS Content
	|FROM
	|	DocumentsTable AS DocumentsTable
	|
	|		INNER JOIN Document.ReportToMaterialProvider2_5 AS Report
	|		ON DocumentsTable.DocumentBasis = Report.Ref
	|
	|		INNER JOIN Document.ReportToMaterialProvider2_5.ManufacturedProduct AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	DocumentsTable.DocumentBasis.BusinessOperation AS BusinessOperation,
	|	Goods.LineNumber,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.Price
	|		ELSE Goods.Sum/Goods.NumberOfPackages 
	|	END,
	|	Goods.Sum,
	|	Goods.VATRate,
	|	Goods.VATAmount,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.ManualDiscount + Goods.DiscountMarkupAmount
	|		ELSE 0 
	|	END,
	|	Goods.Sum + Goods.ManualDiscount + Goods.DiscountMarkupAmount,
	|	CASE
	|		WHEN
	|			Goods.Ref.ToReturnReusablePackage
	|			AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	Goods.Content
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|			AND (Goods.Canceled = FALSE)
	|			AND (Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|				OR Goods.Ref.PackageDepositIsRequired
	|				OR NOT Goods.Ref.ToReturnReusablePackage)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	DocumentsTable.DocumentBasis.BusinessOperation AS BusinessOperation,
	|	Goods.LineNumber,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.Price
	|		ELSE Goods.Sum/Goods.NumberOfPackages 
	|	END,
	|	Goods.Sum,
	|	Goods.VATRate,
	|	Goods.VATAmount,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Goods.ManualDiscount + Goods.DiscountMarkupAmount
	|		ELSE 0 
	|	END,
	|	Goods.Sum + Goods.ManualDiscount + Goods.DiscountMarkupAmount,
	|	CASE
	|		WHEN
	|			Goods.Ref.ToReturnReusablePackage
	|			AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.CustomerInvoice.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|			AND (Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|				OR Goods.Ref.PackageDepositIsRequired
	|				OR NOT Goods.Ref.ToReturnReusablePackage)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	Goods.LineNumber,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	Goods.Price,
	|	Goods.Sum,
	|	Goods.VATRate,
	|	Goods.VATAmount,
	|	0,
	|	0,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.ReturnablePackagingRedemptionByCustomer.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	DocumentsTable.DocumentBasis.BusinessOperation AS BusinessOperation,
	|	Services.LineNumber,
	|	Services.ProductsInSet,
	|	Services.ItemVariantOfSet,
	|	Services.Products,
	|	Services.Characteristic,
	|	NULL,
	|	Services.Count,
	|	Services.Count,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Services.Price
	|		ELSE Services.Sum/Services.Count 
	|	END,
	|	Services.Sum,
	|	Services.VATRate,
	|	Services.VATAmount,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Services.ManualDiscount + Services.DiscountMarkupAmount
	|		ELSE 0 
	|	END,
	|	Services.Sum + Services.ManualDiscount + Services.DiscountMarkupAmount,
	|	FALSE,
	|	Services.Content
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.CustomerInvoiceServices.Services AS Services
	|		ON DocumentsTable.DocumentBasis = Services.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	1,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Basis.OperationService,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	NULL,
	|	1,
	|	1,
	|	Basis.CommissionAmount,
	|	Basis.CommissionAmount,
	|	Basis.VATRateOfRemuneration,
	|	Basis.AmountVATRemuneration,
	|	0,
	|	Basis.CommissionAmount,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.ConsignmentReportToVendor AS Basis
	|		ON DocumentsTable.DocumentBasis = Basis.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	Goods.LineNumber,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	Goods.SellingPrice,
	|	Goods.SalesAmount,
	|	Goods.VATRate,
	|	Goods.AmountSalesVAT,
	|	0,
	|	Goods.SalesAmount,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.ConsignmentReportFromCustomer.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|WHERE
	|	Goods.Count <> 0
	|	AND Goods.SalesAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	Goods.LineNumber,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	Goods.Price,
	|	Goods.Sum,
	|	Goods.VATRate,
	|	Goods.VATAmount,
	|	0,
	|	Goods.Sum,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.WriteOffReportFromCommissionAgent.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	Goods.LineNumber,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	Goods.Price,
	|	Goods.Sum,
	|	Goods.VATRate,
	|	Goods.VATAmount,
	|	0,
	|	0,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.RedemptionOfGoodsByCustodian.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	Goods.LineNumber,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
	|	Goods.Count,
	|	Goods.NumberOfPackages,
	|	Goods.Price,
	|	Goods.Sum,
	|	Goods.VATRate,
	|	Goods.VATAmount,
	|	0,
	|	0,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.PurchasingReportToConsignorPrincipal.Goods AS Goods
	|		ON DocumentsTable.DocumentBasis = Goods.Ref
	|UNION ALL
	|
	
	|SELECT
	|	DocumentsTable.Ref,
	|	UNDEFINED AS BusinessOperation,
	|	1,
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	Basis.OperationService,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	NULL,
	|	1,
	|	1,
	|	Basis.CommissionAmount-Basis.AmountVATRemuneration,
	|	Basis.CommissionAmount-Basis.AmountVATRemuneration,
	|	Basis.VATRateOfRemuneration,
	|	Basis.AmountVATRemuneration,
	|	0,
	|	Basis.CommissionAmount,
	|	FALSE,
	|	NULL
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.PurchasingReportToConsignorPrincipal AS Basis
	|		ON DocumentsTable.DocumentBasis = Basis.Ref
	|	WHERE
	|	Basis.CommissionFeeCalculationMethod <> VALUE(Enum.CommissionFeeCalculationMethods.NotCalculating)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.BusinessOperation,
	|	
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate,
	|	Table.VATAmount,
	|	Table.DiscountAmount,
	|	Table.AmountWithoutADiscount,
	|	Table.ThisIsReusablePackage AS ThisIsReusablePackage,
	|	Table.Content AS Content
	|INTO Goods
	|FROM
	|	GoodsPreparation AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.BusinessOperation,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.BusinessOperation,
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
	|	CASE WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	
	|	CASE WHEN Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
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
	|	Table.BusinessOperation,
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
	|	Goods.Ref AS Ref,
	|	
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	
	|	Goods.ProductsInSet    AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet  AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet         AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|	
	|	Goods.LineNumber                     AS LineNumber,
	|	Goods.Products                    AS Products,
	|	Goods.Products.Code                AS Code,
	|	Goods.Products.SKU            AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.Content                      AS Content,
	|	&QueryTextUnitOfMeasureDescription 				 AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|	
	|	Goods.AmountWithoutADiscount                                    AS AmountWithoutADiscount,
	|	
	|	Goods.ThisIsReusablePackage                                 AS ThisIsReusablePackage	
	|	
	|FROM (
	|	
	|	SELECT
	|		Table.Ref,
	|		
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
	|		
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
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.ThisIsReusablePackage,
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
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		FALSE,
	|		""""
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
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
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[2]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.CustomerCommercialInvoice";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("NumberAccordingToCustomerData", """""");
	
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
	|	UNDEFINED             AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	UNDEFINED             AS LineOfBusiness,
	|	UNDEFINED             AS StorageLocation,
	|	UNDEFINED             AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	UNDEFINED             AS SourceDocumentDate,
	|	FALSE                     AS ReverseTransactionCorrection,
	|	UNDEFINED             AS ReversedDocument,
	|	UNDEFINED             AS CorrectedDocument,
	|	UNDEFINED             AS SourceDocumentNumber,
	|	UNDEFINED             AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref          AS Ref,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.Partner         AS Partner,
	|	DocumentData.Counterparty      AS Counterparty,
	|	DocumentData.Date            AS Period,
	|	DocumentData.Number           AS Number,
	|	DocumentData.Currency          AS Currency,
	|	DocumentData.Contract         AS Contract,
	|	DocumentData.Manager        AS Manager,
	|	DocumentData.Comment     AS Comment,
	|	DocumentData.DocumentAmount  AS DocumentAmount,
	|	DocumentData.Posted        AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark
	|FROM
	|	Document.CustomerCommercialInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("Number",                                    Attributes.Number);
	Query.SetParameter("Currency",                                   Attributes.Currency);
	Query.SetParameter("Organization",                              Attributes.Organization);
	Query.SetParameter("Partner",                                  Attributes.Partner);
	Query.SetParameter("Counterparty",                               Attributes.Counterparty);
	Query.SetParameter("Contract",                                  Attributes.Contract);
	Query.SetParameter("Manager",                                 Attributes.Manager);
	Query.SetParameter("MetadataIdentifier",                  Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("Comment",                              Attributes.Comment);
	Query.SetParameter("DocumentAmount",                           Attributes.DocumentAmount);
	Query.SetParameter("Posted",                                 Attributes.Posted);
	Query.SetParameter("DeletionMark",                          Attributes.DeletionMark);
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		ContractInformation = NStr("vi = 'Theo hợp đồng ""%Contract%""';
									|ru = 'По договору ""%Contract%""';
									|en = 'Under the ""%Contract%"" contract'; fa = 'Under the ""%Contract%"" contract';
									|it = 'In base al contratto ""%Contract%""';
									|pl = 'Według umowy ""%Contract%""';
									|tr = '""%Contract%"" sözleşmesi kapsamında'", CommonClientServer.DefaultLanguageCode());
		ContractInformation = StrReplace(ContractInformation, "%Contract%", Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
EndProcedure

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
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

#Region Other

#EndRegion

#EndRegion

#EndIf
