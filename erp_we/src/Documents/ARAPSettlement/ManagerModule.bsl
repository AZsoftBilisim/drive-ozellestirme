#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ARAPSettlementLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure of KeyAndValue - a list of register names for which you want to table:
//  * Key - String - Name of the register table.
//  * Value - Undefined
//  AddlParameters - Structure of KeyAndValue - additional parameters for obtaining data that define the context of the event:
//  * Key - String - parameter name.
//  * Value - Arbitrary - parameter value.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ARAPSettlement") Then
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
		
		QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers);
		QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers);
		QueryTextRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableActivatingGiftCertificates(Query, QueryTexts, Registers);
		
		ARAPSettlementLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	ARAPSettlementLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the "debt Offset" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	Undefined - LongDesc
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ARAPSettlement) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ARAPSettlement.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ARAPSettlement);
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
	
	#Region StatementOfSettlementsWithCustomers_AddReportCommand
	ReportCommand_ = ARAPAccountingServer.StatementOfSettlementsWithCustomers_AddReportCommand(ReportsCommands);
	
	Operations = New Array;
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany);
	Operations.Add(Enums.KindsOfARAPSettlements.PaymentByGiftCard);
	Operations.Add(Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty);
	Operations.Add(Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany);
	Operations.Add(Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent);
	Operations.Add(Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent);
	
	If ReportCommand_ <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand_,"OperationKind", Operations,
			DataCompositionComparisonType.InList);
	EndIf;
	#EndRegion
	
	#Region SupplierBillingStatement_AddReportCommand
	ReportCommand_ = ARAPAccountingServer.SupplierBillingStatement_AddReportCommand(ReportsCommands);
	
	Operations = New Array;
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany);
	Operations.Add(Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty);
	Operations.Add(Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany);
	
	If ReportCommand_ <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand_,"OperationKind", Operations,
			DataCompositionComparisonType.InList);
	EndIf;
	#EndRegion
	
	#Region StatementOfSettlementsBetweenOrganizations_AddReportCommand
	ReportCommand_ = ARAPAccountingServer.StatementOfSettlementsBetweenOrganizations_AddReportCommand(ReportsCommands);
	
	Operations = New Array;
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany);
	Operations.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany);
	
	If ReportCommand_ <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand_,"OperationKind", Operations,
			DataCompositionComparisonType.InList);
	EndIf;
	#EndRegion
	
	#Region StatementOfSettlementsWithPartners_AddReportCommand
	ReportCommand_ = ARAPAccountingServer.StatementOfSettlementsWithPartners_AddReportCommand(ReportsCommands);
	
	Operations = New Array;
	Operations.Add(Enums.KindsOfARAPSettlements.Arbitrary);
	Operations.Add(Enums.KindsOfARAPSettlements.Barter);
	
	If ReportCommand_ <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand_,"OperationKind", Operations,
			DataCompositionComparisonType.InList);
	EndIf;
	#EndRegion
	
	ARAPSettlementLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The procedure fills in arrays of details that depend on the type of document operation.
//
// Parameters:
//	OperationKind - EnumRef.KindsOfARAPSettlements - The selected type of operation.
//	ArrayOfAllProps - Array of String - Array of all the names of details that depend on the type of operation.
//	ArrayOfOperationDetails - Array of String - Array of names of details used in the selected type of operation.
//
Procedure FillInNamesOfBankingDetailsByTypeOfOperation(OperationKind, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("CompanyCreditor");
	ArrayOfAllProps.Add("Creditor");
	ArrayOfAllProps.Add("CounterpartyDebtorType");
	ArrayOfAllProps.Add("CounterpartyCreditorType");
	ArrayOfAllProps.Add("AccountsReceivable.ARAPObjectMirror");
	ArrayOfAllProps.Add("AccountsPayable.ARAPObjectMirror");
	ArrayOfAllProps.Add("ARAPObjectIntercompanyMirrored");
	ArrayOfAllProps.Add("ARAPObjectDebtorCreditorMirror");
	ArrayOfAllProps.Add("IncomingDocumentNumber");
	ArrayOfAllProps.Add("IncomingDocumentDate");
	
	ArrayOfOperationDetails = New Array;
	If OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
		Or OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties
		Or OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
		Or OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties Then
		ArrayOfOperationDetails.Add("Creditor");
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany Then
		ArrayOfOperationDetails.Add("CompanyCreditor");
		ArrayOfOperationDetails.Add("AccountsReceivable.ARAPObjectMirror");
		ArrayOfOperationDetails.Add("AccountsPayable.ARAPObjectMirror");
		ArrayOfOperationDetails.Add("ARAPObjectIntercompanyMirrored");
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.Arbitrary Then //Arbitrary
		ArrayOfOperationDetails.Add("Creditor");
		ArrayOfOperationDetails.Add("CounterpartyDebtorType");
		ArrayOfOperationDetails.Add("CounterpartyCreditorType");
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
		Or OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
		
		ArrayOfOperationDetails.Add("Creditor");
		ArrayOfOperationDetails.Add("IncomingDocumentNumber");
		ArrayOfOperationDetails.Add("IncomingDocumentDate");
		
	EndIf;
	
EndProcedure

// Returns a view of Bank details depending on the type of netting operation.
//
// Parameters:
//	OperationKind - EnumRef.KindsOfARAPSettlements - The selected type of operation.
//
// Returns:
// Structure - contains a structure with keys:
//     * Organization         - String - Representation of the organization.
//     * CompanyCreditor - String - Representation of the lender organization.
//     * CounterpartyDebtor   - String - Representation of the counterparty-debtor.
//     * Creditor  - String - Representation of the counterparty-lender.
Function PresentationOfBankingDetailsByTypeOfOperation(OperationKind) Export
	
	PresentationsStructure = New Structure;
	
	PresentationsStructure.Insert("Organization", NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Azienda';
														|pl = 'Company';
														|tr = 'İş yeri'"));
	PresentationsStructure.Insert("CompanyCreditor", NStr("vi = 'Doanh nghiệp';
															|ru = 'Организация';
															|en = 'Company'; fa = 'Company';
															|it = 'Azienda';
															|pl = 'Company';
															|tr = 'İş yeri'"));
	If OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany Then
		
		PresentationsStructure.Insert("Organization",         NStr("vi = 'Doanh nghiệp để chuyển giao khoản ứng trước';
																	|ru = 'Организация для передачи аванса';
																	|en = 'Company for advance transfer'; fa = 'Company for advance transfer';
																	|it = 'Organizzazione per il trasferimento del pagamento anticipato';
																	|pl = 'Firma do przekazania zaliczki';
																	|tr = 'Avans transferi için iş yeri'"));
		PresentationsStructure.Insert("CompanyCreditor", NStr("vi = 'Doanh nghiệp đã nhận khoản ứng trước';
																|ru = 'Организация, получившая аванс';
																|en = 'Company that received advance'; fa = 'Company that received advance';
																|it = 'La società che ha ricevuto l''anticipo';
																|pl = 'Firma, która otrzymała zaliczkę';
																|tr = 'Avans alan iş yeri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany Then
		
		PresentationsStructure.Insert("Organization",         NStr("vi = 'Doanh nghiệp đã trả khoản ứng trước';
																	|ru = 'Организация, уплатившая аванс';
																	|en = 'Company that paid advance'; fa = 'Company that paid advance';
																	|it = 'La società che ha pagato l''anticipo';
																	|pl = 'Firma, która opłaciła zaliczkę';
																	|tr = 'Avansı ödeyen iş yeri'"));
		PresentationsStructure.Insert("CompanyCreditor", NStr("vi = 'Doanh nghiệp để chuyển giao khoản ứng trước';
																|ru = 'Организация для передачи аванса';
																|en = 'Company for advance transfer'; fa = 'Company for advance transfer';
																|it = 'Organizzazione per il trasferimento del pagamento anticipato';
																|pl = 'Firma do przekazania zaliczki';
																|tr = 'Avans transferi için iş yeri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany Then
		
		PresentationsStructure.Insert("Organization",         NStr("vi = 'Doanh nghiệp đã thực hiện giao hàng';
																	|ru = 'Организация, выполнившая отгрузку';
																	|en = 'Company which executed shipment'; fa = 'Company which executed shipment';
																	|it = 'La società che ha effettuato la spedizione';
																	|pl = 'Firma, która wykonała wysyłkę';
																	|tr = 'Sevkiyatı yapan iş yeri'"));
		PresentationsStructure.Insert("CompanyCreditor", NStr("vi = 'Doanh nghiệp để chuyển giao công nợ';
																|ru = 'Организация для передачи долга';
																|en = 'Company for debt transfer'; fa = 'Company for debt transfer';
																|it = 'Organizzazione per il trasferimento del debito';
																|pl = 'Firma do przekazania długu';
																|tr = 'Borç transferi için iş yeri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany Then
		
		PresentationsStructure.Insert("Organization",         NStr("vi = 'Doanh nghiệp đã lập chứng từ tiếp nhận';
																	|ru = 'Организация, оформившая поступление';
																	|en = 'Company that registered receipt'; fa = 'Company that registered receipt';
																	|it = 'La società che ha formalizzato l''arrivo';
																	|pl = 'Firma, która sporządziła wpłatę';
																	|tr = 'Girişi düzenleyen iş yeri'"));
		PresentationsStructure.Insert("CompanyCreditor", NStr("vi = 'Doanh nghiệp để chuyển giao công nợ';
																|ru = 'Организация для передачи долга';
																|en = 'Company for debt transfer'; fa = 'Company for debt transfer';
																|it = 'Organizzazione per il trasferimento del debito';
																|pl = 'Firma do przekazania długu';
																|tr = 'Borç transferi için iş yeri'"));
		
	EndIf;
	
	PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Người vay nợ';
															|ru = 'Дебитор';
															|en = 'Debtor'; fa = 'بدهکار';
															|it = 'Debitore';
															|pl = 'Dłużnik';
															|tr = 'Borçlu'"));
	PresentationsStructure.Insert("Creditor", NStr("vi = 'Người cho vay';
													|ru = 'Кредитор';
													|en = 'Creditor'; fa = 'بستانکار';
													|it = 'Creditore';
													|pl = 'Wierzyciel';
													|tr = 'Alacaklı'"));
	If OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Khách hàng';
																|ru = 'Покупатель';
																|en = 'Customer'; fa = 'مشتری';
																|it = 'Acquirente';
																|pl = 'Customer';
																|tr = 'Müşteri'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Khách hàng';
														|ru = 'Покупатель';
														|en = 'Customer'; fa = 'مشتری';
														|it = 'Acquirente';
														|pl = 'Customer';
														|tr = 'Müşteri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Doanh nghiệp-Khách hàng';
																|ru = 'Организация-Клиент';
																|en = 'Customer company'; fa = 'Customer company';
																|it = 'Организация-Клиент';
																|pl = 'Customer company';
																|tr = 'Müşteri iş yeri'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Doanh nghiệp-Khách hàng';
														|ru = 'Организация-Клиент';
														|en = 'Customer company'; fa = 'Customer company';
														|it = 'Организация-Клиент';
														|pl = 'Customer company';
														|tr = 'Müşteri iş yeri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Khách hàng-người nhận';
																|ru = 'Клиент-получатель';
																|en = 'Receiving customer'; fa = 'Receiving customer';
																|it = 'Cliente-ricevente';
																|pl = 'Receiving customer';
																|tr = 'İstemci-alıcı'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Khách hàng người cho vay';
														|ru = 'Клиент-кредитор';
														|en = 'Creditor customer'; fa = 'Creditor customer';
														|it = 'Cliente-creditore';
														|pl = 'Creditor customer';
														|tr = 'İstemci-alacaklı'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Người bán';
																|ru = 'Продавец';
																|en = 'Seller'; fa = 'فروشنده';
																|it = 'Venditore';
																|pl = 'Seller';
																|tr = 'Satıcı'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Khách hàng';
														|ru = 'Покупатель';
														|en = 'Customer'; fa = 'مشتری';
														|it = 'Acquirente';
														|pl = 'Customer';
														|tr = 'Müşteri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Khách hàng-người vay nợ';
																|ru = 'Клиент-дебитор';
																|en = 'Debtor customer'; fa = 'Debtor customer';
																|it = 'Cliente-debitore';
																|pl = 'Debtor customer';
																|tr = 'İstemci-borçlu'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Khách hàng-người nhận';
														|ru = 'Клиент-получатель';
														|en = 'Receiving customer'; fa = 'Receiving customer';
														|it = 'Cliente-ricevente';
														|pl = 'Receiving customer';
														|tr = 'İstemci-alıcı'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Khách hàng-người nhận';
																|ru = 'Клиент-получатель';
																|en = 'Receiving customer'; fa = 'Receiving customer';
																|it = 'Cliente-ricevente';
																|pl = 'Receiving customer';
																|tr = 'İstemci-alıcı'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Người nhận ký gửi-người nợ';
														|ru = 'Комиссионер-дебитор';
														|en = 'Debtor consignee'; fa = 'Debtor consignee';
														|it = 'Commissionario debitore';
														|pl = 'Debtor consignee';
														|tr = 'Konsinye-borçlu'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Khách hàng-người vay nợ';
																|ru = 'Клиент-дебитор';
																|en = 'Debtor customer'; fa = 'Debtor customer';
																|it = 'Cliente-debitore';
																|pl = 'Debtor customer';
																|tr = 'İstemci-borçlu'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Người nhận ký gửi-người nhận';
														|ru = 'Комиссионер-получатель';
														|en = 'Recipient consignee'; fa = 'Recipient consignee';
														|it = 'Commissionario destinatario';
														|pl = 'Recipient consignee';
														|tr = 'Konsinye-alıcı'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		Or OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
		Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Đối tác - Nhà cung cấp';
																|ru = 'Поставщик';
																|en = 'Vendor'; fa = 'تأمین‌کننده';
																|it = 'Fornitore';
																|pl = 'Vendor';
																|tr = 'Tedarikçi'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Đối tác - Nhà cung cấp';
														|ru = 'Поставщик';
														|en = 'Vendor'; fa = 'تأمین‌کننده';
														|it = 'Fornitore';
														|pl = 'Vendor';
														|tr = 'Tedarikçi'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies
		Or OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Doanh nghiệp-Nhà cung cấp';
																|ru = 'Организация-Поставщик';
																|en = 'Vendor company'; fa = 'Vendor company';
																|it = 'Организация-Поставщик';
																|pl = 'Vendor company';
																|tr = 'Tedarikçi iş yeri'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Doanh nghiệp-Nhà cung cấp';
														|ru = 'Организация-Поставщик';
														|en = 'Vendor company'; fa = 'Vendor company';
														|it = 'Организация-Поставщик';
														|pl = 'Vendor company';
														|tr = 'Tedarikçi iş yeri'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Nhà cung cấp-người vay nợ';
																|ru = 'Поставщик-дебитор';
																|en = 'Debtor vendor'; fa = 'Debtor vendor';
																|it = 'Fornitore-debitore';
																|pl = 'Debtor vendor';
																|tr = 'Sağlayıcı-borçlu'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Nhà cung cấp-người nhận';
														|ru = 'Поставщик-получатель';
														|en = 'Receiving vendor'; fa = 'Receiving vendor';
														|it = 'Fornitore-ricevente';
														|pl = 'Receiving vendor';
														|tr = 'Sağlayıcı-alıcı'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Nhà cung cấp-người nhận';
																|ru = 'Поставщик-получатель';
																|en = 'Receiving vendor'; fa = 'Receiving vendor';
																|it = 'Fornitore-ricevente';
																|pl = 'Receiving vendor';
																|tr = 'Sağlayıcı-alıcı'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Nhà cung cấp-người cho vay';
														|ru = 'Поставщик-кредитор';
														|en = 'Creditor vendor'; fa = 'Creditor vendor';
														|it = 'Fornitore-creditore';
														|pl = 'Creditor vendor';
														|tr = 'Sağlayıcı-alacaklı'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.Barter Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Counterparty';
																|tr = 'Cari hesap'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Đối tác';
														|ru = 'Контрагент';
														|en = 'Counterparty'; fa = 'طرف حساب';
														|it = 'Controparte';
														|pl = 'Counterparty';
														|tr = 'Cari hesap'"));
		
	ElsIf OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies Then
		
		PresentationsStructure.Insert("CounterpartyDebtor", NStr("vi = 'Doanh nghiệp / Đối tác';
																|ru = 'Организация-Контрагент';
																|en = 'Counterparty company'; fa = 'Counterparty company';
																|it = 'Организация-Контрагент';
																|pl = 'Counterparty company';
																|tr = 'Cari hesap iş yeri'"));
		PresentationsStructure.Insert("Creditor", NStr("vi = 'Doanh nghiệp / Đối tác';
														|ru = 'Организация-Контрагент';
														|en = 'Counterparty company'; fa = 'Counterparty company';
														|it = 'Организация-Контрагент';
														|pl = 'Counterparty company';
														|tr = 'Cari hesap iş yeri'"));
		
	EndIf;
	
	Return PresentationsStructure;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ARAPSettlementLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// 		String - query text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ARAPSettlementLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
// 	Restriction - See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(AccountsReceivable.Organization)
	|	OR ValueAllowed(AccountsPayable.Organization)
	|	)AND( ValueAllowed(AccountsReceivable.Partner)
	|	OR ValueAllowed(AccountsPayable.Partner)
	|	) 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(AccountsReceivable.Organization)
	|	OR ValueAllowed(AccountsPayable.Organization)
	|	)AND( ValueAllowed(AccountsReceivable.Partner)
	|	OR ValueAllowed(AccountsPayable.Partner)
	|	)AND ValueAllowed(OperationKind)";

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

#Region Posting

// Additional data sources for movements.
// 
// Parameters:
//  RegisterName - String
// 
// Returns:
//  Map of KeyAndValue - Additional data sources for movements:
//  * Key - String - the path to the props
//  * Value - Undefined
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Date               AS Period,
	|	DocumentData.Ref             AS Ref,
	|	DocumentData.Number              AS Number,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Department      AS Department,
	|	DocumentData.OperationKind        AS OperationKind,
	|	DocumentData.Currency             AS Currency,
	|	DocumentData.Creditor AS Creditor,
	|	DocumentData.CounterpartyDebtor AS CounterpartyDebtor,
	|	DocumentData.ARAPObjectIntercompany AS ARAPObjectIntercompany,
	|	DocumentData.ARAPObjectIntercompanyMirrored AS ARAPObjectIntercompanyMirrored	
	|FROM
	|	Document.ARAPSettlement  AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                           Attributes.Period);
	Query.SetParameter("Number",                            Attributes.Number);
	Query.SetParameter("Organization",                      Attributes.Organization);
	Query.SetParameter("Currency",                           Attributes.Currency);
	Query.SetParameter("LocalAccountingCurrency",   SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",       SettingsValueCached.ManagementAccountingCurrency());
	Query.SetParameter("Department",                    Attributes.Department);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.ARAPSettlement"));
	Query.SetParameter("ARAPObjectIntercompany", Attributes.ARAPObjectIntercompany);
	Query.SetParameter("ARAPObjectIntercompanyMirrored", Attributes.ARAPObjectIntercompanyMirrored);
	
	BusinessOperation = Enums.BusinessTransactions.ARAPSettlement;
	SettingUpBusinessTransaction = Catalogs.BusinessTransactionsSettings.ARAPSettlement;
	
	If Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies Then
		BusinessOperation = Enums.BusinessTransactions.SettlementOfPrepayment;
		SettingUpBusinessTransaction = Catalogs.BusinessTransactionsSettings.SettlementOfPrepayment;
		
	ElsIf Attributes.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies Then
		BusinessOperation = Enums.BusinessTransactions.DebtTransfer;
		SettingUpBusinessTransaction = Catalogs.BusinessTransactionsSettings.DebtTransfer;
	
	ElsIf Attributes.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent Then
		BusinessOperation = Enums.BusinessTransactions.RecordOfPaymentThroughTheCommissionAgent;
		SettingUpBusinessTransaction = Catalogs.BusinessTransactionsSettings.SettlementOfPrepayment;
	ElsIf Attributes.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
		BusinessOperation = Enums.BusinessTransactions.RecordOfRefundThroughTheCommissionAgent;
		SettingUpBusinessTransaction = Catalogs.BusinessTransactionsSettings.SettlementOfPrepayment;
	EndIf;
	TransferBetweenTwoCompanies = Attributes.OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
		Or Attributes.OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies;
	Query.SetParameter("TransferBetweenTwoCompanies", TransferBetweenTwoCompanies);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("SettingUpBusinessTransaction", SettingUpBusinessTransaction);
	Query.SetParameter("OperationKind", Attributes.OperationKind);
	
	Query.SetParameter("PaymentByGiftCard", Enums.KindsOfARAPSettlements.PaymentByGiftCard);
	Query.SetParameter("RetailCustomer", Catalogs.Counterparties.RetailCustomer);
	Query.SetParameter("PaymentType_", Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	Query.SetParameter("Creditor", Attributes.Creditor);
	Query.SetParameter("CounterpartyDebtor", Attributes.CounterpartyDebtor);
	Query.SetParameter("DateOfFullRepaymentOfReusablePS", CurrentSessionDate());
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query) Export
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency,
		Undefined, // ARAPCurrency
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure InitializeTTAccountsReceivableAccountsPayable(Query) Export
	
	If Query.Parameters.Property("TTAccountsReceivableAccountsPayableInitialized") Then
		Return;
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	DistributeTableParts(Query);
	TempTablesQuery = New Query;
	TempTablesQuery.TempTablesManager = Query.TempTablesManager;
	TempTablesQuery.Text = QueryTextTTAccountsReceivable() + Common.QueryBatchSeparator()
								+ QueryTextTTAccountsPayable() + Common.QueryBatchSeparator()
								+ QueryTextTTDocumentData_()  + Common.QueryBatchSeparator()
								+ QueryTextTTSettlementsWithCustomersPreliminary() + Common.QueryBatchSeparator()
								+ QueryTextTTSettlementsWithSuppliersPreliminary() + Common.QueryBatchSeparator()
								+ QueryTextTTSources() + Common.QueryBatchSeparator();
	
	TempTablesQuery.SetParameter("Ref",                            Query.Parameters.Ref);
	TempTablesQuery.SetParameter("Organization",                       Query.Parameters.Organization);
	TempTablesQuery.SetParameter("Department",                     Query.Parameters.Department);
	TempTablesQuery.SetParameter("LocalAccountingCurrency",    Query.Parameters.LocalAccountingCurrency);
	TempTablesQuery.SetParameter("ManagementAccountingCurrency",        Query.Parameters.ManagementAccountingCurrency);
	TempTablesQuery.SetParameter("TransferBetweenTwoCompanies",    Query.Parameters.TransferBetweenTwoCompanies);
	
	TempTablesQuery.ExecuteBatch();
	
	Query.SetParameter("TTAccountsReceivableAccountsPayableInitialized", True);

EndProcedure

Procedure InitializeTemporaryTablesByCalculations(Query, DebtKind = Undefined)
	
	QueryingTemporaryTable = New Query;
	QueryingTemporaryTable.TempTablesManager = Query.TempTablesManager;
	
	QueryingTemporaryTable.SetParameter("Ref",                            Query.Parameters.Ref);
	QueryingTemporaryTable.SetParameter("Organization",                       Query.Parameters.Organization);
	QueryingTemporaryTable.SetParameter("Department",                     Query.Parameters.Department);
	QueryingTemporaryTable.SetParameter("LocalAccountingCurrency",    Query.Parameters.LocalAccountingCurrency);
	QueryingTemporaryTable.SetParameter("TransferBetweenTwoCompanies",    Query.Parameters.TransferBetweenTwoCompanies);
	
	QueryText = "";
	If (DebtKind = "Customers" Or DebtKind = Undefined)
		And Not Query.Parameters.Property("TTSettlementsWithClientsInitialized") Then
		Query.SetParameter("TTSettlementsWithClientsInitialized", True);
		QueryText = QueryTextTTSettlementsWithCustomers();
	EndIf;
	
	If (DebtKind = "Vendors" Or DebtKind = Undefined)
		And Not Query.Parameters.Property("TTSettlementsWithSuppliersInitialized") Then
		Query.SetParameter("TTSettlementsWithSuppliersInitialized", True);
		If ValueIsFilled(QueryText) Then
			QueryText = QueryText + Common.QueryBatchSeparator();
		EndIf;
		QueryText = QueryText + QueryTextTTSettlementsWithSuppliers();
	EndIf;
	
	If DebtKind = Undefined Then
		If ValueIsFilled(QueryText) Then
			QueryText = QueryText + Common.QueryBatchSeparator();
		EndIf;
		QueryText = QueryText + QueryTextTTSettlementsOnDebt();
	EndIf;
	
	If ValueIsFilled(QueryText) Then
		QueryingTemporaryTable.Text = QueryText;
		QueryingTemporaryTable.ExecuteBatch();
	EndIf;

EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		InitializeTTAccountsReceivableAccountsPayable(Query);
	
		QueryTextdata_ =
		"SELECT DISTINCT
		|	""CustomersARAPAccounting"" AS DataSource,
		|	FALSE AS DistributeTotalAmount,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	RegisterRecordTable.Organization AS Organization,
		|	RegisterRecordTable.ARAPCurrency AS DocumentCurrency,
		|	RegisterRecordTable.ARAPCurrency AS ARAPCurrency,
		|	UNDEFINED AS VATBasePeriod,
		|	DocumentData.Date AS DateOfCourse,
		|
		|	0 AS LineNumber,
		|	RegisterRecordTable.IdOfTSLine AS RowID,
		|	CASE
		|		WHEN RegisterRecordTable.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN -RegisterRecordTable.AmountARAP
		|		ELSE
		|			RegisterRecordTable.AmountARAP
		|	END AS AmountExcludingVAT,
		|	UNDEFINED AS VATRate,
		|	0 AS VATAmount,
		|	CASE
		|		WHEN RegisterRecordTable.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN -RegisterRecordTable.AmountARAP
		|		ELSE
		|			RegisterRecordTable.AmountARAP
		|	END AS AmountARAP,
		|	0 AS AmountVATARAP,
		|	0 AS AmountExcludingVATCompl,
		|	0 AS AmountExcludingVATMan,
		|
		|	TRUE AS RecordedInARAPAccounting,
		|	RegisterRecordTable.ARAPObject AS ARAPObject,
		|	CASE WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
		|				OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Barter)
		|				OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies)
		|		THEN FALSE
		|		ELSE TRUE
		|	END AS RecalculateBasedOnARAPData
		|FROM
		|	TTSettlementsWithCustomersPreliminary AS RegisterRecordTable
		|		INNER JOIN TTStringCalculationObjects AS StringCalculationObjects
		|			ON RegisterRecordTable.ARAPObject = StringCalculationObjects.ARAPObject
		|		INNER JOIN TTDocumentData_ AS DocumentData
		|			ON TRUE
		|
		|UNION ALL
		|
		|	SELECT DISTINCT
		|	""VendorsARAPAccounting"" AS DataSource,
		|	FALSE AS DistributeTotalAmount,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	RegisterRecordTable.Organization AS Organization,
		|	RegisterRecordTable.ARAPCurrency AS DocumentCurrency,
		|	RegisterRecordTable.ARAPCurrency AS ARAPCurrency,
		|	UNDEFINED AS VATBasePeriod,
		|	DocumentData.Date AS DateOfCourse,
		|
		|	0 AS LineNumber,
		|	RegisterRecordTable.IdOfTSLine AS RowID,
		|	CASE WHEN RegisterRecordTable.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterRecordTable.AmountARAP
		|		ELSE RegisterRecordTable.AmountARAP
		|	END AS AmountExcludingVAT,
		|	UNDEFINED AS VATRate,
		|	0 AS VATAmount,
		|	CASE WHEN RegisterRecordTable.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -RegisterRecordTable.AmountARAP
		|		ELSE RegisterRecordTable.AmountARAP
		|	END AS AmountARAP,
		|	0 AS AmountVATARAP,
		|	0 AS AmountExcludingVATCompl,
		|	0 AS AmountExcludingVATMan,
		|
		|	TRUE AS RecordedInARAPAccounting,
		|	RegisterRecordTable.ARAPObject AS ARAPObject,
		|	CASE WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
		|				OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Barter)
		|				OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies)
		|		THEN FALSE
		|		ELSE TRUE
		|	END AS RecalculateBasedOnARAPData
		|FROM
		|	TTSettlementsWithSuppliersPreliminary AS RegisterRecordTable
		|		INNER JOIN TTStringCalculationObjects AS StringCalculationObjects
		|			ON RegisterRecordTable.ARAPObject = StringCalculationObjects.ARAPObject
		|		INNER JOIN TTDocumentData_ AS DocumentData
		|			ON TRUE
		|WHERE
		|	RegisterRecordTable.Ref IN (&Ref)
		|";
	
	Else
		QueryTextdata_ =
		"SELECT
		|	""AccountsReceivable"" AS DataSource,
		|	FALSE AS DistributeTotalAmount,
		|	DocumentTable.Ref AS Ref,
		|	DocumentTable.Ref.Date AS Date,
		|	DocumentTable.Ref.Organization AS Organization,
		|	DocumentTable.ARAPCurrency AS DocumentCurrency,
		|	DocumentTable.ARAPCurrency AS ARAPCurrency,
		|	UNDEFINED AS VATBasePeriod,
		|	DocumentTable.Ref.Date AS DateOfCourse,
		|
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RowID AS RowID,
		|	DocumentTable.AmountARAP AS AmountExcludingVAT,
		|	UNDEFINED AS VATRate,
		|	0 AS VATAmount,
		|	DocumentTable.AmountARAP AS AmountARAP,
		|	0 AS AmountVATARAP,
		|	0 AS AmountExcludingVATCompl,
		|	0 AS AmountExcludingVATMan,
		|
		|	TRUE AS RecordedInARAPAccounting,
		|	DocumentTable.ARAPObject AS ARAPObject,
		|	FALSE AS RecalculateBasedOnARAPData
		|FROM
		|	Document.ARAPSettlement.AccountsReceivable AS DocumentTable
		|WHERE
		|	DocumentTable.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|	SELECT
		|	""AccountsPayable"" AS DataSource,
		|	FALSE AS DistributeTotalAmount,
		|	DocumentTable.Ref AS Ref,
		|	DocumentTable.Ref.Date AS Date,
		|	DocumentTable.Ref.Organization AS Organization,
		|	DocumentTable.ARAPCurrency AS DocumentCurrency,
		|	DocumentTable.ARAPCurrency AS ARAPCurrency,
		|	UNDEFINED AS VATBasePeriod,
		|	DocumentTable.Ref.Date AS DateOfCourse,
		|
		|	DocumentTable.LineNumber AS LineNumber,
		|	DocumentTable.RowID AS RowID,
		|	DocumentTable.AmountARAP AS AmountExcludingVAT,
		|	UNDEFINED AS VATRate,
		|	0 AS VATAmount,
		|	DocumentTable.AmountARAP AS AmountARAP,
		|	0 AS AmountVATARAP,
		|	0 AS AmountExcludingVATCompl,
		|	0 AS AmountExcludingVATMan,
		|
		|	TRUE AS RecordedInARAPAccounting,
		|	DocumentTable.ARAPObject AS ARAPObject,
		|	FALSE AS RecalculateBasedOnARAPData
		|FROM
		|	Document.ARAPSettlement.AccountsPayable  AS DocumentTable
		|WHERE
		|	DocumentTable.Ref IN (&Ref)
		|";
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "CustomersARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTAccountsReceivableAccountsPayable(Query);
	InitializeTemporaryTablesByCalculations(Query, "Customers");
	
	QueryText = QueryTextCustomersARAPAccounting();
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "VendorsARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTAccountsReceivableAccountsPayable(Query);
	InitializeTemporaryTablesByCalculations(Query, "Vendors");
	
	QueryText = QueryTextVendorsARAPAccounting();
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

// Forms of movement to register Distichodontidae on temporary tables accounts receivable and accounts payable.
//
Procedure PrepareTableOfMovementCounterpartyCounterparty(Query)
	
	If Query.Parameters.Property("RegisteredRecordsCounterpartyCounterpartyPrepared") Then
		Return;
	EndIf;
	
	InitializeTTAccountsReceivableAccountsPayable(Query);
	InitializeTemporaryTablesByCalculations(Query);
	RequestForArrears = New Query;
	RequestForArrears.TempTablesManager = Query.TempTablesManager;
	RequestForArrears.SetParameter("Ref",                            Query.Parameters.Ref);
	RequestForArrears.SetParameter("Period",                            Query.Parameters.Period);
	RequestForArrears.SetParameter("Department",                     Query.Parameters.Department);
	RequestForArrears.SetParameter("ManagementAccountingCurrency",        Query.Parameters.ManagementAccountingCurrency);
	RequestForArrears.SetParameter("LocalAccountingCurrency",    Query.Parameters.LocalAccountingCurrency);
	RequestForArrears.SetParameter("ConversionRateToManCurrency",    Query.Parameters.ConversionRateToManCurrency);
	RequestForArrears.SetParameter("FactorOfConversionToCurrencyOfRegul",   Query.Parameters.FactorOfConversionToCurrencyOfRegul);
	
	RequestForArrears.Text = 
	"SELECT
	|	&Period                                                AS Period,
	|	Debt_.RecordType                              AS RecordType,
	|	&Ref                                                AS Recorder,
	|	&BusinessOperation                                 AS BusinessOperation,
	|	Debt_.Organization                              AS Organization,
	|	&Department                                         AS Department,
	|	
	|	Debt_.Partner                                  AS Partner,
	|	Debt_.Counterparty                               AS Counterparty,
	|	Debt_.Contract                                  AS Contract,
	|	Debt_.LineOfBusiness                  AS LineOfBusiness,
	|	Debt_.ARAPObject                           AS ARAPObject,
	|	
	|	UNDEFINED                                           AS CorPartner,
	|	UNDEFINED                                           AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS CorContract,
	|	UNDEFINED                                           AS CorLineOfBusiness,
	|	UNDEFINED                                           AS CorARAPObject,
	|	
	|	UNDEFINED                                           AS AmountType,
	|	UNDEFINED                                           AS CorAmountType,
	|	
	|	CASE WHEN Debt_.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN Debt_.AmountARAP
	|		WHEN Debt_.Sum <> 0 
	|			THEN CAST(Debt_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE Debt_.SumMan
	|	END                                                  AS Sum,
	|	0                                                      AS AmountExcludingVAT,
	|	CASE WHEN Debt_.ARAPCurrency = &LocalAccountingCurrency
	|			THEN Debt_.AmountARAP
	|		WHEN Debt_.Sum <> 0
	|			THEN CAST(Debt_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE Debt_.SumCompl
	|	END                                                  AS SumCompl,
	|	0                                                      AS LocalAmountExcludingVAT,
	|	
	|	Debt_.ARAPCurrency                     AS Currency,
	|	Debt_.AmountARAP                      AS AmountInCurrency,
	|	0                                                      AS AmountExcludingVATInCurrency,
	|	
	|	Debt_.ARAPCurrency                     AS ARAPCurrency,
	|	CASE WHEN Debt_.AmountARAP = 0 
	|		THEN 1
	|		ELSE (CASE WHEN Debt_.ARAPCurrency = &LocalAccountingCurrency
	|					THEN Debt_.AmountARAP 
	|					WHEN Debt_.Sum <> 0
	|						THEN CAST(Debt_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|					ELSE Debt_.SumCompl
	|				END) / Debt_.AmountARAP
	|	END                                                  AS MutualSettlementsExchangeRate,
	|	Debt_.AmountARAP                      AS AmountInARAPCurrency,
	|	0                                                      AS AmountExcludingVATInARAPCurrency,
	|	
	|	UNDEFINED                                           AS CorCurrencyOfARAPAccounting,
	|	0                                                      AS AdjAmountInARAPCurrency,
	|	0                                                      AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	Debt_.ARAPObject                           AS SourceOfARAPFinancialAccountingGroup,
	|	UNDEFINED                                           AS CorSourceOfARAPFinancialAccountingGroup,
	|	Debt_.Organization = Debt_.Organization.ParentCompany AS ThisIsParentOrganization,
	|	Debt_.TheseAreSettlementsWithCustomers                     AS TheseAreSettlementsWithCustomers,
	|	FALSE                                                   AS ThisIsRefundOfAdvance,
	|	FALSE                                                   AS ReversingEntry
	|FROM
	|	TTSettlementsOnDebt AS Debt_
	|WHERE
	|	Debt_.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|ORDER BY
	|	Debt_.Organization,
	|	Debt_.Sum DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period                                                AS Period,
	|	Debt_.RecordType                              AS RecordType,
	|	&Ref                                                AS Recorder,
	|	&BusinessOperation                                 AS BusinessOperation,
	|	Debt_.Organization                              AS Organization,
	|	&Department                                         AS Department,
	|	
	|	UNDEFINED                                           AS Partner,
	|	UNDEFINED                                           AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                           AS LineOfBusiness,
	|	UNDEFINED                                           AS ARAPObject,
	|	
	|	Debt_.Partner                                  AS CorPartner,
	|	Debt_.Counterparty                               AS CorCounterparty,
	|	Debt_.Contract                                  AS CorContract,
	|	Debt_.LineOfBusiness                  AS CorLineOfBusiness,
	|	Debt_.ARAPObject                           AS CorARAPObject,
	|	
	|	UNDEFINED                                           AS AmountType,
	|	UNDEFINED                                           AS CorAmountType,
	|	
	|	CASE 
	|		WHEN Debt_.ARAPCurrency = &ManagementAccountingCurrency THEN
	|			Debt_.AmountARAP
	|		WHEN Debt_.Sum <> 0 THEN
	|			CAST(Debt_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE
	|			Debt_.SumMan
	|	END                                                  AS Sum,
	|	0                                                      AS AmountExcludingVAT,
	|	CASE 
	|		WHEN Debt_.ARAPCurrency = &LocalAccountingCurrency THEN
	|			Debt_.AmountARAP
	|		WHEN Debt_.Sum <> 0 THEN
	|			CAST(Debt_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE
	|			Debt_.SumCompl
	|	END                                                  AS SumCompl,
	|	0                                                      AS LocalAmountExcludingVAT,
	|	
	|	Debt_.ARAPCurrency                     AS Currency,
	|	Debt_.AmountARAP                      AS AmountInCurrency,
	|	0                                                      AS AmountExcludingVATInCurrency,
	|	
	|	UNDEFINED                                           AS ARAPCurrency,
	|	0                                                      AS AmountInARAPCurrency,
	|	0                                                      AS AmountExcludingVATInARAPCurrency,
	|	
	|	Debt_.ARAPCurrency                     AS CorCurrencyOfARAPAccounting,
	|	CASE WHEN Debt_.AmountARAP = 0 
	|		THEN 1
	|		ELSE (CASE WHEN Debt_.ARAPCurrency = &LocalAccountingCurrency
	|					THEN Debt_.AmountARAP
	|					WHEN Debt_.Sum <> 0 THEN
	|						CAST(Debt_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|					ELSE Debt_.SumCompl
	|				END) / Debt_.AmountARAP
	|	END                                                  AS MutualSettlementsExchangeRate,
	|	Debt_.AmountARAP                      AS AdjAmountInARAPCurrency,
	|	0                                                      AS AdjAmountExcludingVATInARAPCurrency,
	|
	|	UNDEFINED                                           AS SourceOfARAPFinancialAccountingGroup,
	|	Debt_.ARAPObject                           AS CorSourceOfARAPFinancialAccountingGroup,
	|	Debt_.Organization = Debt_.Organization.ParentCompany AS ThisIsParentOrganization,
	|	Debt_.TheseAreSettlementsWithCustomers                     AS TheseAreSettlementsWithCustomers,
	|	FALSE                                                   AS ThisIsRefundOfAdvance,
	|	FALSE                                                   AS ReversingEntry
	|FROM
	|	TTSettlementsOnDebt AS Debt_
	|WHERE
	|	Debt_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|ORDER BY
	|	Debt_.Organization,
	|	Debt_.Sum DESC";
	
	RequestForArrears.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	Result = RequestForArrears.ExecuteBatch();
	
	MovementTableCounterpartyCounterparty = Undefined;
	ManagementAccountingPostingServer.CarryOutNetting(
		Result[0].Unload(),
		Result[1].Unload(),
		MovementTableCounterpartyCounterparty);
	
	RequestForArrears.SetParameter("MovementTableCounterpartyCounterparty", MovementTableCounterpartyCounterparty);
	RequestForArrears.Text = 
	"SELECT
	|	MovementTableCounterpartyCounterparty.Period,
	|	MovementTableCounterpartyCounterparty.Recorder,
	|	MovementTableCounterpartyCounterparty.LineNumber,
	|
	|	MovementTableCounterpartyCounterparty.BusinessOperation,
	|	MovementTableCounterpartyCounterparty.Organization,
	|	MovementTableCounterpartyCounterparty.Department,
	|
	|	MovementTableCounterpartyCounterparty.Partner,
	|	MovementTableCounterpartyCounterparty.Counterparty,
	|	MovementTableCounterpartyCounterparty.Contract,
	|	MovementTableCounterpartyCounterparty.LineOfBusiness,
	|	MovementTableCounterpartyCounterparty.ARAPObject,
	|
	|	MovementTableCounterpartyCounterparty.CorPartner,
	|	MovementTableCounterpartyCounterparty.CorCounterparty,
	|	MovementTableCounterpartyCounterparty.CorContract,
	|	MovementTableCounterpartyCounterparty.CorLineOfBusiness,
	|	MovementTableCounterpartyCounterparty.CorARAPObject,
	
	|	MovementTableCounterpartyCounterparty.AmountType,
	|	MovementTableCounterpartyCounterparty.CorAmountType,
	|
	|	MovementTableCounterpartyCounterparty.Sum,
	|	MovementTableCounterpartyCounterparty.AmountExcludingVAT,
	|	MovementTableCounterpartyCounterparty.SumCompl,
	|	MovementTableCounterpartyCounterparty.LocalAmountExcludingVAT,
	|
	|	MovementTableCounterpartyCounterparty.Currency,
	|	MovementTableCounterpartyCounterparty.AmountInCurrency,
	|	MovementTableCounterpartyCounterparty.AmountExcludingVATInCurrency,
	|
	|	MovementTableCounterpartyCounterparty.ARAPCurrency,
	|	MovementTableCounterpartyCounterparty.AmountInARAPCurrency,
	|	MovementTableCounterpartyCounterparty.AmountExcludingVATInARAPCurrency,
	|
	|	MovementTableCounterpartyCounterparty.CorCurrencyOfARAPAccounting,
	|	MovementTableCounterpartyCounterparty.AdjAmountInARAPCurrency,
	|	MovementTableCounterpartyCounterparty.AdjAmountExcludingVATInARAPCurrency,
	|
	|	MovementTableCounterpartyCounterparty.SourceOfARAPFinancialAccountingGroup,
	|	MovementTableCounterpartyCounterparty.CorSourceOfARAPFinancialAccountingGroup
	|INTO TTMovementCounterpartyCounterparty
	|FROM
	|	&MovementTableCounterpartyCounterparty AS MovementTableCounterpartyCounterparty";
	
	RequestForArrears.ExecuteBatch();
	
	Query.SetParameter("RegisteredRecordsCounterpartyCounterpartyPrepared", True);

EndProcedure

Function QueryTextRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	PrepareTableOfMovementCounterpartyCounterparty(Query);
	
	QueryText = 
	"SELECT
	|	MovementTableCounterpartyCounterparty.Period,
	|	MovementTableCounterpartyCounterparty.Recorder,
	|	MovementTableCounterpartyCounterparty.LineNumber,
	|
	|	MovementTableCounterpartyCounterparty.BusinessOperation,
	|	MovementTableCounterpartyCounterparty.Organization,
	|	MovementTableCounterpartyCounterparty.Department,
	|
	|	MovementTableCounterpartyCounterparty.Partner,
	|	MovementTableCounterpartyCounterparty.Counterparty,
	|	MovementTableCounterpartyCounterparty.Contract,
	|	MovementTableCounterpartyCounterparty.LineOfBusiness,
	|	MovementTableCounterpartyCounterparty.ARAPObject,
	|
	|	MovementTableCounterpartyCounterparty.CorPartner,
	|	MovementTableCounterpartyCounterparty.CorCounterparty,
	|	MovementTableCounterpartyCounterparty.CorContract,
	|	MovementTableCounterpartyCounterparty.CorLineOfBusiness,
	|	MovementTableCounterpartyCounterparty.CorARAPObject,
	|
	|	MovementTableCounterpartyCounterparty.AmountType,
	|	MovementTableCounterpartyCounterparty.CorAmountType,
	|
	|	MovementTableCounterpartyCounterparty.Sum,
	|	MovementTableCounterpartyCounterparty.AmountExcludingVAT,
	|	MovementTableCounterpartyCounterparty.SumCompl,
	|	MovementTableCounterpartyCounterparty.LocalAmountExcludingVAT,
	|
	|	MovementTableCounterpartyCounterparty.Currency,
	|	MovementTableCounterpartyCounterparty.AmountInCurrency,
	|	MovementTableCounterpartyCounterparty.AmountExcludingVATInCurrency,
	|
	|	MovementTableCounterpartyCounterparty.ARAPCurrency,
	|	MovementTableCounterpartyCounterparty.AmountInARAPCurrency,
	|	MovementTableCounterpartyCounterparty.AmountExcludingVATInARAPCurrency,
	|
	|	MovementTableCounterpartyCounterparty.CorCurrencyOfARAPAccounting,
	|	MovementTableCounterpartyCounterparty.AdjAmountInARAPCurrency,
	|	MovementTableCounterpartyCounterparty.AdjAmountExcludingVATInARAPCurrency,
	|
	|	MovementTableCounterpartyCounterparty.SourceOfARAPFinancialAccountingGroup,
	|	MovementTableCounterpartyCounterparty.CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTMovementCounterpartyCounterparty AS MovementTableCounterpartyCounterparty";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	PrepareTableOfMovementCounterpartyCounterparty(Query);
	
	QueryText = "
	|SELECT
	|	RecordsCounterpartyCounterparty.Period                     AS Period,
	|	RecordsCounterpartyCounterparty.Organization                AS Organization,
	|	CorObjectsOfCalculations.Department                        AS Department,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
	|	RecordsCounterpartyCounterparty.CorCounterparty              AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	RecordsCounterpartyCounterparty.SumCompl   AS SumCompl,
	|	RecordsCounterpartyCounterparty.Sum       AS SumMan,
	|	RecordsCounterpartyCounterparty.Sum       AS AmountIncludingVAT,
	|	RecordsCounterpartyCounterparty.AmountExcludingVAT AS AmountExcludingVAT,
	|
	|	ARAPObjects.UUID    AS FinRecordID,
	|	BusinessTransactionsSettings.Ref      AS BusinessTransactionSetting
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON RecordsCounterpartyCounterparty.ARAPObject = ARAPObjects.Ref
	|	LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|		ON RecordsCounterpartyCounterparty.CorARAPObject = CorObjectsOfCalculations.Ref
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON RecordsCounterpartyCounterparty.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	RecordsCounterpartyCounterparty.Organization.ParentCompany <> RecordsCounterpartyCounterparty.Counterparty.ParentCompany
	|	AND RecordsCounterpartyCounterparty.Organization.ParentCompany <> RecordsCounterpartyCounterparty.CorCounterparty.ParentCompany
	|	AND (RecordsCounterpartyCounterparty.Organization = RecordsCounterpartyCounterparty.CorCounterparty.ParentCompany
	|		OR RecordsCounterpartyCounterparty.Organization.ParentCompany = RecordsCounterpartyCounterparty.CorCounterparty)
	|	
	|UNION ALL
	|
	|SELECT
	|	RecordsCounterpartyCounterparty.Period                   AS Period,
	|	RecordsCounterpartyCounterparty.Organization              AS Organization,
	|	ARAPObjects.Department                         AS Department,
	|	RecordsCounterpartyCounterparty.LineOfBusiness  AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
	|	RecordsCounterpartyCounterparty.Counterparty               AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	RecordsCounterpartyCounterparty.SumCompl   AS SumCompl,
	|	RecordsCounterpartyCounterparty.Sum       AS SumMan,
	|	RecordsCounterpartyCounterparty.Sum       AS AmountIncludingVAT,
	|	RecordsCounterpartyCounterparty.AmountExcludingVAT AS AmountExcludingVAT,
	|
	|	CorObjectsOfCalculations.UUID AS FinRecordID,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON RecordsCounterpartyCounterparty.ARAPObject = ARAPObjects.Ref
	|	LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|		ON RecordsCounterpartyCounterparty.CorARAPObject = CorObjectsOfCalculations.Ref
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON RecordsCounterpartyCounterparty.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	RecordsCounterpartyCounterparty.Organization.ParentCompany <> RecordsCounterpartyCounterparty.Counterparty.ParentCompany
	|	AND RecordsCounterpartyCounterparty.Organization.ParentCompany <> RecordsCounterpartyCounterparty.CorCounterparty.ParentCompany
	|	AND (RecordsCounterpartyCounterparty.Organization = RecordsCounterpartyCounterparty.Counterparty.ParentCompany
	|		OR RecordsCounterpartyCounterparty.Organization.ParentCompany = RecordsCounterpartyCounterparty.Counterparty)
	|";
	
	QueryText = QueryText
		+ TMCommonUse.QuerySeparatorInJoin()
		+ OtherAssetsLiabilitiesServer.QueryTextSettlementWithBranches();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableActivatingGiftCertificates(Query, QueryTexts, Registers)
	
	RegisterName = "ActivatingGiftCertificates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
		"SELECT
		|	TabularSection.ARAPObject.Object AS GiftCertificate,
		|	&Period AS ValidityStartDate,
		|	CASE
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.DAY)
		|			THEN DATEADD(&Period, DAY, GiftCertificateKinds.NumberOfValidityPeriods)
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.WEEK)
		|			THEN DATEADD(&Period, WEEK, GiftCertificateKinds.NumberOfValidityPeriods)
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.MONTH)
		|			THEN DATEADD(&Period, MONTH, GiftCertificateKinds.NumberOfValidityPeriods)
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.QUARTER)
		|			THEN DATEADD(&Period, QUARTER, GiftCertificateKinds.NumberOfValidityPeriods)
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.YEAR)
		|			THEN DATEADD(&Period, YEAR, GiftCertificateKinds.NumberOfValidityPeriods)
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.TENDAYS)
		|			THEN DATEADD(&Period, TENDAYS, GiftCertificateKinds.NumberOfValidityPeriods)
		|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.HALFYEAR)
		|			THEN DATEADD(&Period, HALFYEAR, GiftCertificateKinds.NumberOfValidityPeriods)
		|		ELSE &Period
		|	END AS ValidityEndDate,
		|	&Organization AS Organization
		|FROM
		|	Document.ARAPSettlement.AccountsReceivable AS TabularSection
		|		LEFT JOIN Catalog.GiftCertificateKinds AS GiftCertificateKinds
		|		ON (GiftCertificateKinds.Ref = TabularSection.ARAPObject.Object.Owner)
		|WHERE
		|	TabularSection.Ref = &Ref
		|	AND &OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties)
		|	AND TabularSection.ARAPObject.Object REFS Catalog.GiftCertificates";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAccountsReceivable()
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.PaymentType_                     AS PaymentType_,
	|	DocumentData.ARAPObject                  AS ARAPObject,
	|	DocumentData.ARAPObjectMirror        AS ARAPObjectMirror,
	|
	|	CASE WHEN VALUETYPE(ARAPObjects.Counterparty) = TYPE(Catalog.Companies)
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE DocumentData.Partner
	|	END                                           AS Partner,
	|	ARAPObjects.Organization                     AS Organization,
	|	ARAPObjects.Contract                         AS Contract,
	|	ARAPObjects.Counterparty                      AS Counterparty,
	|	ARAPObjects.VATTaxation              AS VATTaxation,
	|	CASE WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
	|		THEN DocumentData.LineOfBusiness
	|		ELSE ARAPObjects.LineOfBusiness
	|	END                                           AS LineOfBusiness,
	|
	|	DocumentData.AmountARAP             AS Sum,
	|	DocumentData.AmountARAP             AS AmountARAP,
	|	DocumentData.ARAPCurrency            AS ARAPCurrency,
	|	DocumentData.SumCompl                       AS SumCompl,
	|	DocumentData.SumMan                        AS SumMan,
	|	ARAPObjects.Department                   AS Department,
	|
	|	UNDEFINED                                    AS CorARAPObject,
	|	UNDEFINED                                    AS CorIsARAPObjectThatIsMirrored,
	|	DocumentData.CalculationObjectReceiver          AS CalculationObjectReceiver,
	|	DocumentData.CurrencyReceiver                  AS CurrencyReceiver,
	|	DocumentData.AmountReceiver                   AS AmountReceiver,
	|	DocumentData.PartnerReceiver                 AS PartnerReceiver,
	|	DocumentData.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	DocumentData.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	DocumentData.RowID              AS RowID,
	|	DocumentData.RowID              AS IdOfTSLine,
	|	DocumentData.OperationKind                      AS OperationKind,
	|	DocumentData.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|INTO TTAccountsReceivable
	|FROM
	|	TableReceivables AS DocumentData
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = DocumentData.ARAPObject
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Barter)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.PaymentType_                     AS PaymentType_,
	|	DocumentData.ARAPObject                  AS ARAPObject,
	|	DocumentData.ARAPObjectMirror        AS ARAPObjectMirror,
	|
	|	CASE WHEN VALUETYPE(ARAPObjects.Counterparty) = TYPE(Catalog.Companies)
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE DocumentData.Partner
	|	END                                           AS Partner,
	|	ARAPObjects.Organization                     AS Organization,
	|	ARAPObjects.Contract                         AS Contract,
	|	ARAPObjects.Counterparty                      AS Counterparty,
	|	ARAPObjects.VATTaxation              AS VATTaxation,
	|	ARAPObjects.LineOfBusiness         AS LineOfBusiness,
	|
	|	0                                               AS Sum,
	|	Debts.AmountARAP                       AS AmountARAP,
	|	DocumentData.ARAPCurrency            AS ARAPCurrency,
	|	Debts.SumCompl                                 AS SumCompl,
	|	Debts.SumMan                                  AS SumMan,
	|
	|	ARAPObjects.Department                   AS Department,
	|
	|	CASE WHEN DocumentData.TransferOfCounterpartyDebtBetweenCompanies
	|		THEN UNDEFINED
	|		ELSE Debts.ARAPObject
	|	END AS                                        CorARAPObject,
	|	CASE WHEN DocumentData.TransferOfCounterpartyDebtBetweenCompanies
	|		THEN UNDEFINED
	|		ELSE Debts.ARAPObjectMirror
	|	END                                            AS CorIsARAPObjectThatIsMirrored,
	
	|	DocumentData.CalculationObjectReceiver          AS CalculationObjectReceiver,
	|	DocumentData.CurrencyReceiver                  AS CurrencyReceiver,
	|	DocumentData.AmountReceiver                   AS AmountReceiver,
	|	DocumentData.PartnerReceiver                 AS PartnerReceiver,
	|	DocumentData.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	DocumentData.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	DocumentData.CorIdOfLine          AS RowID,
	|	DocumentData.RowID             AS IdOfTSLine,
	|	DocumentData.OperationKind                      AS OperationKind,
	|	DocumentData.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|
	|FROM
	|	TableReceivables AS DocumentData
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = DocumentData.ARAPObject
	|
	|		LEFT JOIN TablePayables AS Debts
	|			ON Debts.Ref = DocumentData.Ref
	|			AND Debts.RowID = DocumentData.CorIdOfLine
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.PaymentByGiftCard)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies)
	|	)
	|	
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAccountsPayable()
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.PaymentType_                     AS PaymentType_,
	|	DocumentData.ARAPObject                  AS ARAPObject,
	|	DocumentData.ARAPObjectMirror        AS ARAPObjectMirror,
	|
	|	CASE WHEN VALUETYPE(ARAPObjects.Counterparty) = TYPE(Catalog.Companies)
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE DocumentData.Partner
	|	END                                           AS Partner,
	|	ARAPObjects.Organization                     AS Organization,
	|	ARAPObjects.Contract                         AS Contract,
	|	ARAPObjects.Counterparty                      AS Counterparty,
	|	ARAPObjects.VATTaxation              AS VATTaxation,
	|	CASE WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
	|		THEN DocumentData.LineOfBusiness
	|		ELSE ARAPObjects.LineOfBusiness
	|	END                                           AS LineOfBusiness,
	|
	|	DocumentData.AmountARAP             AS Sum,
	|	DocumentData.AmountARAP             AS AmountARAP,
	|	DocumentData.ARAPCurrency            AS ARAPCurrency,
	|	DocumentData.SumCompl                       AS SumCompl,
	|	DocumentData.SumMan                        AS SumMan,
	|
	|	ARAPObjects.Department                   AS Department,
	|
	|	UNDEFINED                                    AS CorARAPObject,
	|	UNDEFINED                                    AS CorIsARAPObjectThatIsMirrored,
	|	DocumentData.CalculationObjectReceiver          AS CalculationObjectReceiver,
	|	DocumentData.CurrencyReceiver                  AS CurrencyReceiver,
	|	DocumentData.AmountReceiver                   AS AmountReceiver,
	|	DocumentData.PartnerReceiver                 AS PartnerReceiver,
	|	DocumentData.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	DocumentData.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	DocumentData.RowID              AS RowID,
	|	DocumentData.RowID              AS IdOfTSLine,
	|	DocumentData.OperationKind                      AS OperationKind,
	|	DocumentData.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|INTO TTAccountsPayable
	|FROM
	|	TablePayables AS DocumentData
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = DocumentData.ARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|			ON Directions.Ref = ARAPObjects.LineOfBusiness
	|
	|WHERE
	|	(DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Barter)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.PaymentByGiftCard)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                          AS Ref,
	|	DocumentData.PaymentType_                     AS PaymentType_,
	|	DocumentData.ARAPObject                  AS ARAPObject,
	|	DocumentData.ARAPObjectMirror        AS ARAPObjectMirror,
	|
	|	CASE WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.PaymentByGiftCard) 
	|				AND VALUETYPE(ARAPObjects.Object) = TYPE(Catalog.GiftCertificates)
	|		THEN VALUE(Catalog.Partners.RetailCustomer)
	|		ELSE
	|			CASE WHEN VALUETYPE(ARAPObjects.Counterparty) = TYPE(Catalog.Companies)
	|				THEN VALUE(Catalog.Partners.OurEnterprise)
	|				ELSE DocumentData.Partner
	|			END
	|	END                                           AS Partner,
	|	ARAPObjects.Organization                     AS Organization,
	|	ARAPObjects.Contract                         AS Contract,
	|	CASE WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.PaymentByGiftCard) 
	|				AND VALUETYPE(ARAPObjects.Object) = TYPE(Catalog.GiftCertificates)
	|		THEN VALUE(Catalog.Counterparties.RetailCustomer)
	|		ELSE ARAPObjects.Counterparty
	|	END                                           AS Counterparty,
	|	ARAPObjects.VATTaxation              AS VATTaxation,
	|	ARAPObjects.LineOfBusiness         AS LineOfBusiness,
	|
	|	0                                               AS Sum,
	|	Debts.AmountARAP                       AS AmountARAP,
	|	DocumentData.ARAPCurrency            AS ARAPCurrency,
	|	Debts.SumCompl                                 AS SumCompl,
	|	Debts.SumMan                                  AS SumMan,
	|
	|	ARAPObjects.Department                   AS Department,
	|
	|	CASE WHEN DocumentData.TransferOfCounterpartyDebtBetweenCompanies
	|		THEN UNDEFINED
	|		ELSE Debts.ARAPObject
	|	END                                            AS CorARAPObject,
	|	CASE WHEN DocumentData.TransferOfCounterpartyDebtBetweenCompanies
	|		THEN UNDEFINED
	|		ELSE Debts.ARAPObjectMirror
	|	END                                            AS CorIsARAPObjectThatIsMirrored,
	
	|	DocumentData.CalculationObjectReceiver          AS CalculationObjectReceiver,
	|	DocumentData.CurrencyReceiver                  AS CurrencyReceiver,
	|	DocumentData.AmountReceiver                   AS AmountReceiver,
	|	DocumentData.PartnerReceiver                 AS PartnerReceiver,
	|	DocumentData.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	DocumentData.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	DocumentData.CorIdOfLine          AS RowID,
	|	DocumentData.RowID             AS IdOfTSLine,
	|	DocumentData.OperationKind                      AS OperationKind,
	|	DocumentData.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|FROM
	|	TablePayables AS DocumentData
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = DocumentData.ARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|			ON Directions.Ref = ARAPObjects.LineOfBusiness
	|
	|		LEFT JOIN TableReceivables AS Debts
	|			ON Debts.Ref = DocumentData.Ref
	|			AND Debts.RowID = DocumentData.CorIdOfLine
	|WHERE
	|	(DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany)
	|		OR DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies)
	|	)
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDocumentData_()
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref                                          AS Ref,
	|	DocumentData.Posted                                        AS Posted,
	|	DocumentData.Date                                            AS Date,
	|	DocumentData.Number                                           AS Number,
	|	DocumentData.OperationKind                                     AS OperationKind,
	|	DocumentData.SumCompl                                       AS SumCompl,
	|	DocumentData.SumMan                                        AS SumMan,
	|
	|	DocumentData.Organization                                     AS Organization,
	|	DocumentData.CompanyCreditor                             AS CompanyCreditor,
	|	DocumentData.ARAPObjectIntercompany                      AS ARAPObjectIntercompany,
	|	DocumentData.ARAPObjectIntercompanyMirrored            AS ARAPObjectIntercompanyMirrored,
	|
	|	DocumentData.CounterpartyDebtorType                                     AS CounterpartyDebtorType,
	|	DocumentData.CounterpartyCreditorType                                    AS CounterpartyCreditorType,
	|	DocumentData.CounterpartyDebtor                               AS CounterpartyDebtor,
	|	DocumentData.Creditor                              AS Creditor,
	|	DocumentData.ARAPObjectDebtorCreditor                   AS ARAPObjectDrCr,
	|	DocumentData.ARAPObjectDebtorCreditorMirror         AS ObjectOfDrCRMirrorCalculations,
	|
	|	CASE WHEN VALUETYPE(DocumentData.CounterpartyDebtor) = TYPE(Catalog.Companies)
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                                           AS DebtorOrganization,
	|	CASE WHEN VALUETYPE(DocumentData.Creditor) = TYPE(Catalog.Companies)
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                                           AS LenderOrganization
	|
	|INTO TTDocumentData_
	|FROM
	|	Document.ARAPSettlement AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Return QueryText;
	
EndFunction

// 1. Organization - Counterparty - Account objectd - Expense - Sumadt - Calculation by Client
// 2. Organization - Counterparty - Account objectCount - Expense - -Sumact - Calculation by Client
// 3. Counterpartydt(Org) - Counterpartykt - Account OBJECTTKT - Expense - Sumact - Calculation by Client
// 4. Counterpartykt(Org) - Counterpartydt(Not org) - Account OBJECTTKT - Arrival - Sumadt - Settlement by the supplier.
//
Function QueryTextTTSettlementsWithCustomersPreliminary()

	QueryText = "
	// Calculations for the main organization
	|	SELECT // the accounts receivable of the debtor-client to the organization is considered paid
	|		AccountsReceivable.Ref                           AS Ref,
	|		VALUE(AccumulationRecordType.Expense)                    AS RecordType,
	|		AccountsReceivable.Organization                      AS Organization,
	|		AccountsReceivable.Partner                          AS Partner,
	|		AccountsReceivable.Counterparty                       AS Counterparty,
	|		AccountsReceivable.Contract                          AS Contract,
	|		AccountsReceivable.LineOfBusiness          AS LineOfBusiness,
	|
	|		AccountsReceivable.ARAPObject                   AS ARAPObject,
	|		AccountsReceivable.ARAPObjectMirror         AS ARAPObjectMirror,
	|		AccountsReceivable.ARAPCurrency             AS ARAPCurrency,
	|
	|		0                                                         AS Sum,
	|		AccountsReceivable.AmountARAP              AS AmountARAP,
	|		AccountsReceivable.SumCompl                        AS SumCompl,
	|		AccountsReceivable.SumMan                         AS SumMan,
	|
	|		AccountsReceivable.CorARAPObject                AS CorARAPObject,
	|		AccountsReceivable.CorIsARAPObjectThatIsMirrored      AS CorIsARAPObjectThatIsMirrored,
	|		AccountsReceivable.CalculationObjectReceiver           AS CalculationObjectReceiver,
	|		AccountsReceivable.CurrencyReceiver                   AS CurrencyReceiver,
	|		AccountsReceivable.AmountReceiver                    AS AmountReceiver,
	|		AccountsReceivable.PartnerReceiver                  AS PartnerReceiver,
	|		AccountsReceivable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|		AccountsReceivable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		FALSE                                                      AS FillInSource,
	|		AccountsReceivable.RowID              AS RowID,
	|		AccountsReceivable.IdOfTSLine            AS IdOfTSLine,
	|		AccountsReceivable.OperationKind                      AS OperationKind,
	|		AccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|	INTO TTSettlementsWithCustomersPreliminary
	|	FROM
	|		TTAccountsReceivable AS AccountsReceivable
	|	WHERE
	|		AccountsReceivable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		AND AccountsReceivable.AmountARAP <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT // the accounts payable of the organization to the creditor-client is reversed
	|		AccountsPayable.Ref                           AS Ref,
	|		VALUE(AccumulationRecordType.Expense)                     AS RecordType,
	|		AccountsPayable.Organization                      AS Organization,
	|		AccountsPayable.Partner                          AS Partner,
	|		AccountsPayable.Counterparty                       AS Counterparty,
	|		AccountsPayable.Contract                          AS Contract,
	|		AccountsPayable.LineOfBusiness          AS LineOfBusiness,
	|
	|		AccountsPayable.ARAPObject                   AS ARAPObject,
	|		AccountsPayable.ARAPObjectMirror         AS ARAPObjectMirror,
	|		AccountsPayable.ARAPCurrency             AS ARAPCurrency,
	|
	|		0                                                          AS Sum,
	|		-AccountsPayable.AmountARAP             AS AmountARAP,
	|		-AccountsPayable.SumCompl                       AS SumCompl,
	|		-AccountsPayable.SumMan                        AS SumMan,
	|
	|		AccountsPayable.CorARAPObject                AS CorARAPObject,
	|		AccountsPayable.CorIsARAPObjectThatIsMirrored      AS CorIsARAPObjectThatIsMirrored,
	|		AccountsPayable.CalculationObjectReceiver           AS CalculationObjectReceiver,
	|		AccountsPayable.CurrencyReceiver                   AS CurrencyReceiver,
	|		AccountsPayable.AmountReceiver                    AS AmountReceiver,
	|		AccountsPayable.PartnerReceiver                  AS PartnerReceiver,
	|		AccountsPayable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|		AccountsPayable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		FALSE                                                       AS FillInSource,
	|		AccountsPayable.RowID              AS RowID,
	|		AccountsPayable.IdOfTSLine            AS IdOfTSLine,
	|		AccountsPayable.OperationKind                      AS OperationKind,
	|		AccountsPayable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|	FROM
	|		TTAccountsPayable AS AccountsPayable
	|	WHERE
	|		AccountsPayable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		AND AccountsPayable.AmountARAP <> 0
	|	
	|	UNION ALL
	|
	// 3.
	|	SELECT // transfer of the client's credit card from the debtor organization to the supplier's credit card in front of the client creditor
	|		DocumentData.Ref                                     AS Ref,
	|		VALUE(AccumulationRecordType.Expense)                     AS RecordType,
	|		DocumentData.CounterpartyDebtor                          AS Organization,
	|		DocumentData.ARAPObjectDrCr.Partner                 AS Partner,
	|		DocumentData.Creditor                         AS Counterparty,
	|		DocumentData.ARAPObjectDrCr.Contract                 AS Contract,
	|		DocumentData.ARAPObjectDrCr.LineOfBusiness AS LineOfBusiness,
	|
	|		CASE WHEN DocumentData.ARAPObjectDrCr.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN DocumentData.ARAPObjectDrCr
	|				ELSE DocumentData.ObjectOfDrCRMirrorCalculations
	|		END                                                      AS ARAPObject,
	|		CASE WHEN DocumentData.ARAPObjectDrCr.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN DocumentData.ObjectOfDrCRMirrorCalculations
	|				ELSE DocumentData.ARAPObjectDrCr
	|		END                                                      AS ARAPObjectMirror,
	|		DocumentData.ARAPObjectDrCr.ARAPCurrency    AS ARAPCurrency,
	|
	|		0                                                          AS Sum,
	|		CASE
	|			WHEN DocumentData.ARAPObjectDrCr.ARAPCurrency = &LocalAccountingCurrency
	|				THEN AccountsPayable.SumCompl
	|			//To support old documents that could have an empty settlement object with different currencies.
	|			ELSE AccountsPayable.AmountARAP
	|		END                                                      AS AmountARAP,
	|		AccountsPayable.SumCompl                        AS SumCompl,
	|		AccountsPayable.SumMan                         AS SumMan,
	|
	|		AccountsPayable.CorARAPObject                AS CorARAPObject,
	|		AccountsPayable.CorIsARAPObjectThatIsMirrored      AS CorIsARAPObjectThatIsMirrored,
	|		AccountsPayable.CalculationObjectReceiver           AS CalculationObjectReceiver,
	|		AccountsPayable.CurrencyReceiver                   AS CurrencyReceiver,
	|		AccountsPayable.AmountReceiver                    AS AmountReceiver,
	|		AccountsPayable.PartnerReceiver                  AS PartnerReceiver,
	|		AccountsPayable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|		AccountsPayable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		FALSE                                                       AS FillInSource,
	|		AccountsPayable.RowID              AS RowID,
	|		AccountsPayable.IdOfTSLine            AS IdOfTSLine,
	|		AccountsPayable.OperationKind                      AS OperationKind,
	|		AccountsPayable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|	FROM
	|		TTAccountsPayable AS AccountsPayable
	|			INNER JOIN TTDocumentData_ AS DocumentData ON TRUE
	|	WHERE
	|		DocumentData.DebtorOrganization AND DocumentData.Creditor <> DocumentData.CounterpartyDebtor
	|		AND AccountsPayable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		AND AccountsPayable.SumCompl <> 0
	|
	|	UNION ALL
	|
	// 4.
	|	SELECT // adding accounts receivable for customers from the creditor organization
	|		DocumentData.Ref                                     AS Ref,
	|		VALUE(AccumulationRecordType.Receipt)                     AS RecordType,
	|		DocumentData.Creditor                         AS Organization,
	|		DocumentData.ARAPObjectDrCr.Partner                 AS Partner,
	|		DocumentData.CounterpartyDebtor                          AS Counterparty,
	|		DocumentData.ARAPObjectDrCr.Contract                 AS Contract,
	|		DocumentData.ARAPObjectDrCr.LineOfBusiness AS LineOfBusiness,
	|
	|		DocumentData.ARAPObjectDrCr                         AS ARAPObject,
	|		DocumentData.ObjectOfDrCRMirrorCalculations               AS ARAPObjectMirror,
	|		DocumentData.ARAPObjectDrCr.ARAPCurrency    AS ARAPCurrency,
	|
	|		0                                                          AS Sum,
	|		CASE
	|			WHEN DocumentData.ARAPObjectDrCr.ARAPCurrency = &LocalAccountingCurrency
	|				THEN AccountsReceivable.SumCompl
	|			//To support old documents that could have an empty settlement object with different currencies.
	|			ELSE AccountsReceivable.AmountARAP
	|		END                                                      AS AmountARAP,
	|		AccountsReceivable.SumCompl                         AS SumCompl,
	|		AccountsReceivable.SumMan                          AS SumMan,
	|
	|		AccountsReceivable.CorARAPObject                 AS CorARAPObject,
	|		AccountsReceivable.CorIsARAPObjectThatIsMirrored       AS CorIsARAPObjectThatIsMirrored,
	|		AccountsReceivable.CalculationObjectReceiver            AS CalculationObjectReceiver,
	|		AccountsReceivable.CurrencyReceiver                    AS CurrencyReceiver,
	|		AccountsReceivable.AmountReceiver                     AS AmountReceiver,
	|		AccountsReceivable.PartnerReceiver                   AS PartnerReceiver,
	|		AccountsReceivable.ARAPObjectIsMirrorReceiver  AS ARAPObjectIsMirrorReceiver,
	|		AccountsReceivable.ByDataOfSourceARAPObject  AS ByDataOfSourceARAPObject,
	|		FALSE                                                       AS FillInSource,
	|		AccountsReceivable.RowID               AS RowID,
	|		AccountsReceivable.IdOfTSLine             AS IdOfTSLine,
	|		AccountsReceivable.OperationKind                       AS OperationKind,
	|		AccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|	FROM
	|		TTAccountsReceivable AS AccountsReceivable
	|			INNER JOIN TTDocumentData_ AS DocumentData
	|				ON TRUE
	|	WHERE
	|		DocumentData.LenderOrganization
	|		AND NOT DocumentData.DebtorOrganization 
	|		AND DocumentData.Creditor <> DocumentData.CounterpartyDebtor
	// client counter client org
	|		AND AccountsReceivable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		AND AccountsReceivable.SumCompl <> 0
	|";
	
	Return QueryText;
	
EndFunction

// 1. Organization - Counterparty - Account objectd - Arrival - -Sumadt - Settlement by the supplier 
// 2. Organization - Counterparty - Account objectCount - Arrival - Sum - Settlement by the Supplier
// 3. Counterpartydt(Org) - Counterpartykt - Account OBJECTTKT - Arrival - -Sumact - Settlement by the Supplier
// 4. Counterpartykt(Org) - Counterpartydt(Not Org) - Account OBJECTTKT - Arrival - Sumadt - Settlement by the Supplier
// 5. Organization - OrganizatioNt - objectaccountingintercampany - Parish - Amount.
//
Function QueryTextTTSettlementsWithSuppliersPreliminary()
	
	QueryText = "
	// 1. Calculations for the main organization
	|	SELECT // the accounts receivable of the supplier debtor to the organization is reversed
	|		AccountsReceivable.Ref                           AS Ref,
	|		VALUE(AccumulationRecordType.Receipt)                    AS RecordType,
	|		AccountsReceivable.Organization                      AS Organization,
	|		AccountsReceivable.Partner                          AS Partner,
	|		AccountsReceivable.Counterparty                       AS Counterparty,
	|		AccountsReceivable.Contract                          AS Contract,
	|		AccountsReceivable.LineOfBusiness          AS LineOfBusiness,
	|
	|		AccountsReceivable.ARAPObject                   AS ARAPObject,
	|		AccountsReceivable.ARAPObjectMirror         AS ARAPObjectMirror,
	|		AccountsReceivable.ARAPCurrency             AS ARAPCurrency,
	|
	|		-AccountsReceivable.Sum                           AS Sum,
	|		-AccountsReceivable.AmountARAP             AS AmountARAP,
	|		-AccountsReceivable.SumCompl                       AS SumCompl,
	|		-AccountsReceivable.SumMan                        AS SumMan,
	|
	|		AccountsReceivable.CorARAPObject                AS CorARAPObject,
	|		AccountsReceivable.CorIsARAPObjectThatIsMirrored      AS CorIsARAPObjectThatIsMirrored,
	|		AccountsReceivable.CalculationObjectReceiver           AS CalculationObjectReceiver,
	|		AccountsReceivable.CurrencyReceiver                   AS CurrencyReceiver,
	|		AccountsReceivable.AmountReceiver                    AS AmountReceiver,
	|		AccountsReceivable.PartnerReceiver                  AS PartnerReceiver,
	|		AccountsReceivable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|		AccountsReceivable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		FALSE                                                      AS FillInSource,
	|		AccountsReceivable.RowID              AS RowID,
	|		AccountsReceivable.IdOfTSLine            AS IdOfTSLine,
	|		AccountsReceivable.OperationKind                      AS OperationKind,
	|		AccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|	INTO TTSettlementsWithSuppliersPreliminary
	|	FROM
	|		TTAccountsReceivable AS AccountsReceivable
	|	WHERE
	|		AccountsReceivable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		AND AccountsReceivable.AmountARAP <> 0
	|	
	|	UNION ALL
	|	
	// 2.
	|	SELECT // the accounts payable of the organization to the supplier creditor is considered paid
	|		AccountsPayable.Ref                           AS Ref,
	|		VALUE(AccumulationRecordType.Receipt)                     AS RecordType,
	|		AccountsPayable.Organization                      AS Organization,
	|		AccountsPayable.Partner                          AS Partner,
	|		AccountsPayable.Counterparty                       AS Counterparty,
	|		AccountsPayable.Contract                          AS Contract,
	|		AccountsPayable.LineOfBusiness          AS LineOfBusiness,
	|
	|		AccountsPayable.ARAPObject                   AS ARAPObject,
	|		AccountsPayable.ARAPObjectMirror         AS ARAPObjectMirror,
	|		AccountsPayable.ARAPCurrency             AS ARAPCurrency,
	|
	|		AccountsPayable.Sum                            AS Sum,
	|		AccountsPayable.AmountARAP              AS AmountARAP,
	|		AccountsPayable.SumCompl                        AS SumCompl,
	|		AccountsPayable.SumMan                         AS SumMan,
	|
	|		AccountsPayable.CorARAPObject                AS CorARAPObject,
	|		AccountsPayable.CorIsARAPObjectThatIsMirrored      AS CorIsARAPObjectThatIsMirrored,
	|		AccountsPayable.CalculationObjectReceiver           AS CalculationObjectReceiver,
	|		AccountsPayable.CurrencyReceiver                   AS CurrencyReceiver,
	|		AccountsPayable.AmountReceiver                    AS AmountReceiver,
	|		AccountsPayable.PartnerReceiver                  AS PartnerReceiver,
	|		AccountsPayable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|		AccountsPayable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		FALSE                                                       AS FillInSource,
	|		AccountsPayable.RowID              AS RowID,
	|		AccountsPayable.IdOfTSLine            AS IdOfTSLine,
	|		AccountsPayable.OperationKind                      AS OperationKind,
	|		AccountsPayable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|	FROM
	|		TTAccountsPayable AS AccountsPayable
	|	WHERE
	|		AccountsPayable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		AND AccountsPayable.AmountARAP <> 0
	|
	|	UNION ALL
	|
	// 3.(Settlement by the Supplier, Debtor-Organization)
	|	SELECT // transfer of the supplier's creditor account from the debtor organization to the supplier's creditor account before the supplier creditor
	|		DocumentData.Ref                                     AS Ref,
	|		VALUE(AccumulationRecordType.Receipt)                     AS RecordType,
	|		DocumentData.CounterpartyDebtor                          AS Organization,
	|		DocumentData.ARAPObjectDrCr.Partner                 AS Partner,
	|		DocumentData.Creditor                         AS Counterparty,
	|		DocumentData.ARAPObjectDrCr.Contract                 AS Contract,
	|		DocumentData.ARAPObjectDrCr.LineOfBusiness AS LineOfBusiness,
	|
	|		CASE WHEN DocumentData.ARAPObjectDrCr.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				THEN DocumentData.ARAPObjectDrCr
	|				ELSE DocumentData.ObjectOfDrCRMirrorCalculations
	|		END                                                      AS ARAPObject,
	|		CASE WHEN DocumentData.ARAPObjectDrCr.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|				THEN DocumentData.ObjectOfDrCRMirrorCalculations
	|				ELSE DocumentData.ARAPObjectDrCr
	|		END                                                      AS ARAPObjectMirror,
	|		DocumentData.ARAPObjectDrCr.ARAPCurrency    AS ARAPCurrency,
	|
	|		0                                                          AS Sum,
	|		CASE
	|			WHEN DocumentData.ARAPObjectDrCr.ARAPCurrency = &LocalAccountingCurrency
	|				THEN -AccountsPayable.SumCompl
	|			//To support old documents that could have an empty settlement object with different currencies.
	|			ELSE -AccountsPayable.AmountARAP
	|		END                                                      AS AmountARAP,
	|		-AccountsPayable.SumCompl                       AS SumCompl,
	|		-AccountsPayable.SumMan                        AS SumMan,
	|
	|		AccountsPayable.CorARAPObject                AS CorARAPObject,
	|		AccountsPayable.CorIsARAPObjectThatIsMirrored      AS CorIsARAPObjectThatIsMirrored,
	|		AccountsPayable.CalculationObjectReceiver           AS CalculationObjectReceiver,
	|		AccountsPayable.CurrencyReceiver                   AS CurrencyReceiver,
	|		AccountsPayable.AmountReceiver                    AS AmountReceiver,
	|		AccountsPayable.PartnerReceiver                  AS PartnerReceiver,
	|		AccountsPayable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|		AccountsPayable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|		FALSE                                                       AS FillInSource,
	|		AccountsPayable.RowID              AS RowID,
	|		AccountsPayable.IdOfTSLine            AS IdOfTSLine,
	|		AccountsPayable.OperationKind                      AS OperationKind,
	|		AccountsPayable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|	FROM
	|		TTAccountsPayable AS AccountsPayable
	|			INNER JOIN TTDocumentData_ AS DocumentData
	|				ON TRUE
	|	WHERE
	|		DocumentData.DebtorOrganization AND DocumentData.Creditor <> DocumentData.CounterpartyDebtor
	|		AND AccountsPayable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		AND AccountsPayable.SumCompl <> 0
	|
	|	UNION ALL
	|
	// 4.(Settlement by the Supplier, Lender-Organization)
	|	SELECT // transfer of the supplier's creditor account from the debtor organization to the supplier's creditor account before the supplier creditor
	|		DocumentData.Ref                                     AS Ref,
	|		VALUE(AccumulationRecordType.Receipt)                     AS RecordType,
	|		DocumentData.Creditor                         AS Organization,
	|		DocumentData.ARAPObjectDrCr.Partner                 AS Partner,
	|		DocumentData.CounterpartyDebtor                          AS Counterparty,
	|		DocumentData.ARAPObjectDrCr.Contract                 AS Contract,
	|		DocumentData.ARAPObjectDrCr.LineOfBusiness AS LineOfBusiness,
	|
	|		DocumentData.ARAPObjectDrCr                         AS ARAPObject,
	|		DocumentData.ObjectOfDrCRMirrorCalculations               AS ARAPObjectMirror,
	|		AccountsReceivable.ARAPCurrency              AS ARAPCurrency,
	|
	|		AccountsReceivable.Sum                             AS Sum,
	|		CASE
	|			WHEN DocumentData.ARAPObjectDrCr.ARAPCurrency = &LocalAccountingCurrency
	|				THEN AccountsReceivable.SumCompl
	|			//To support old documents that could have an empty settlement object with different currencies.
	|			ELSE AccountsReceivable.AmountARAP
	|		END                                                      AS AmountARAP,
	|		AccountsReceivable.SumCompl                         AS SumCompl,
	|		AccountsReceivable.SumMan                          AS SumMan,
	|
	|		AccountsReceivable.CorARAPObject                 AS CorARAPObject,
	|		AccountsReceivable.CorIsARAPObjectThatIsMirrored       AS CorIsARAPObjectThatIsMirrored,
	|		AccountsReceivable.CalculationObjectReceiver            AS CalculationObjectReceiver,
	|		AccountsReceivable.CurrencyReceiver                    AS CurrencyReceiver,
	|		AccountsReceivable.AmountReceiver                     AS AmountReceiver,
	|		AccountsReceivable.PartnerReceiver                   AS PartnerReceiver,
	|		AccountsReceivable.ARAPObjectIsMirrorReceiver  AS ARAPObjectIsMirrorReceiver,
	|		AccountsReceivable.ByDataOfSourceARAPObject  AS ByDataOfSourceARAPObject,
	|		FALSE                                                       AS FillInSource,
	|		AccountsReceivable.RowID               AS RowID,
	|		AccountsReceivable.IdOfTSLine             AS IdOfTSLine,
	|		AccountsReceivable.OperationKind                       AS OperationKind,
	|		AccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|	FROM
	|		TTAccountsReceivable AS AccountsReceivable
	|			INNER JOIN TTDocumentData_ AS DocumentData
	|				ON TRUE
	|	WHERE
	|		DocumentData.LenderOrganization
	|		AND NOT DocumentData.DebtorOrganization
	|		AND DocumentData.Creditor <> DocumentData.CounterpartyDebtor
	|		AND AccountsReceivable.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		AND AccountsReceivable.AmountARAP <> 0
	|
	|	UNION ALL
	|
	// 5. (Inter-organizations) - cor part in the lender
	|	SELECT // transfer of accounts receivable for customers from an organization to a creditor organization
	|		DocumentData.Ref                                             AS Ref,
	|		CASE WHEN DocumentData.Organization = DocumentData.ARAPObjectIntercompany.Organization
	|				AND DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|			ELSE VALUE(AccumulationRecordType.Receipt)
	|		END                                                              AS RecordType,
	|		
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompany.Organization
	|			ELSE DocumentData.ARAPObjectIntercompany.Counterparty
	|		END                                                              AS Organization,
	|		VALUE(Catalog.Partners.OurEnterprise)                      AS Partner,
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompany.Counterparty
	|			ELSE DocumentData.ARAPObjectIntercompany.Organization
	|		END                                                              AS Counterparty,
	
	|		DocumentData.ARAPObjectIntercompany.Contract                 AS Contract,
	|		DocumentData.ARAPObjectIntercompany.LineOfBusiness AS LineOfBusiness,
	|
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompany
	|			ELSE DocumentData.ARAPObjectIntercompanyMirrored
	|		END                                                              AS ARAPObject,
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompanyMirrored
	|			ELSE DocumentData.ARAPObjectIntercompany
	|		END                                                              AS ARAPObjectMirror,
	|		AccountsPayable.ARAPCurrency                     AS ARAPCurrency,
	|
	|		0                                                                  AS Sum,
	|		CASE
	|			WHEN DocumentData.ARAPObjectIntercompany.ARAPCurrency = &LocalAccountingCurrency
	|				THEN AccountsPayable.SumCompl
	|			//To support old documents that could have an empty settlement object with different currencies.
	|			ELSE AccountsPayable.AmountARAP
	|		END                                                              AS AmountARAP,
	|		AccountsPayable.SumCompl                                AS SumCompl,
	|		AccountsPayable.SumMan                                 AS SumMan,
	|
	|		UNDEFINED                                                       AS CorARAPObject,
	|		UNDEFINED                                                       AS CorIsARAPObjectThatIsMirrored,
	|		UNDEFINED                                                       AS CalculationObjectReceiver,
	|		UNDEFINED                                                       AS CurrencyReceiver,
	|		0                                                                  AS AmountReceiver,
	|		UNDEFINED                                                       AS PartnerReceiver,
	|		UNDEFINED                                                       AS ARAPObjectIsMirrorReceiver,
	|		FALSE                                                               AS ByDataOfSourceARAPObject,
	|		TRUE                                                             AS FillInSource,
	|		AccountsPayable.RowID                      AS RowID,
	|		AccountsPayable.IdOfTSLine                    AS IdOfTSLine,
	|		AccountsPayable.OperationKind                              AS OperationKind,
	|		AccountsPayable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|	FROM 
	|		TTAccountsPayable AS AccountsPayable
	|			INNER JOIN TTDocumentData_ AS DocumentData
	|				ON TRUE
	|	WHERE
	|		DocumentData.OperationKind IN (
	|			VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany),
	|			VALUE(Enum.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany))
	|		AND AccountsPayable.SumCompl <> 0
	|
	|	UNION ALL
	|
	// 6. (Inter-organizations) - cor part in the account receivable
	|	SELECT // transfer of accounts receivable for customers from an organization to a creditor organization
	|		DocumentData.Ref                                             AS Ref,
	|		CASE WHEN DocumentData.Organization = DocumentData.ARAPObjectIntercompany.Organization
	|				// For the Transfer of operation between organizations, the Company is the recipient 
	|				// in the other three of operations, the Company is the sender
	|				AND DocumentData.ARAPObjectIntercompany.PaymentType_ = CASE
	|					WHEN DocumentData.OperationKind = VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany)
	|						THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|						ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					END
	|			THEN VALUE(AccumulationRecordType.Expense)
	|			ELSE VALUE(AccumulationRecordType.Receipt)
	|		END                                                              AS RecordType,
	|
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompany.Organization
	|			ELSE DocumentData.ARAPObjectIntercompany.Counterparty
	|		END                                                              AS Organization,
	|		VALUE(Catalog.Partners.OurEnterprise)                      AS Partner,
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompany.Counterparty
	|			ELSE DocumentData.ARAPObjectIntercompany.Organization
	|		END                                                              AS Counterparty,
	|
	|		DocumentData.ARAPObjectIntercompany.Contract                 AS Contract,
	|		DocumentData.ARAPObjectIntercompany.LineOfBusiness AS LineOfBusiness,
	|
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompany
	|			ELSE DocumentData.ARAPObjectIntercompanyMirrored
	|		END                                                              AS ARAPObject,
	|		CASE WHEN DocumentData.ARAPObjectIntercompany.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			THEN DocumentData.ARAPObjectIntercompanyMirrored
	|			ELSE DocumentData.ARAPObjectIntercompany
	|		END                                                              AS ARAPObjectMirror,
	|		AccountsReceivable.ARAPCurrency                      AS ARAPCurrency,
	|
	|		0                                                                  AS Sum,
	|		CASE
	|			WHEN DocumentData.ARAPObjectIntercompany.ARAPCurrency = &LocalAccountingCurrency
	|				THEN AccountsReceivable.SumCompl
	|			//To support old documents that could have an empty settlement object with different currencies.
	|			ELSE AccountsReceivable.AmountARAP
	|		END                                                              AS AmountARAP,
	|		AccountsReceivable.SumCompl                                 AS SumCompl,
	|		AccountsReceivable.SumMan                                  AS SumMan,
	|
	|		UNDEFINED                                                       AS CorARAPObject,
	|		UNDEFINED                                                       AS CorIsARAPObjectThatIsMirrored,
	|		UNDEFINED                                                       AS CalculationObjectReceiver,
	|		UNDEFINED                                                       AS CurrencyReceiver,
	|		0                                                                  AS AmountReceiver,
	|		UNDEFINED                                                       AS PartnerReceiver,
	|		UNDEFINED                                                       AS ARAPObjectIsMirrorReceiver,
	|		FALSE                                                               AS ByDataOfSourceARAPObject,
	|		TRUE                                                             AS FillInSource,
	|		AccountsReceivable.RowID                       AS RowID,
	|		AccountsReceivable.IdOfTSLine                     AS IdOfTSLine,
	|		AccountsReceivable.OperationKind                               AS OperationKind,
	|		AccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies 
	|	FROM 
	|		TTAccountsReceivable AS AccountsReceivable
	|			INNER JOIN TTDocumentData_ AS DocumentData
	|				ON TRUE
	|	WHERE
	|		DocumentData.OperationKind IN (
	|			VALUE(Enum.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany),
	|			VALUE(Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany))
	|		AND AccountsReceivable.SumCompl <> 0
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSources()
	
	QueryText = "
	|SELECT DISTINCT
	|	CustomersARAPAccounting.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	CustomersARAPAccounting.CalculationObjectReceiver.PaymentType_ AS TypeOfCalculationsReceiver,
	|	CustomersARAPAccounting.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	CustomersARAPAccounting.ARAPObjectIsMirrorReceiver.PaymentType_ AS TypeOfCalculationsMirrorReceiver,
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.ARAPObjectMirror AS ARAPObjectMirror,
	|	CustomersARAPAccounting.RowID AS RowID,
	|	CustomersARAPAccounting.IdOfTSLine AS IdOfTSLine,
	|	TRUE AS TheseAreSettlementsWithCustomers
	|INTO TTSources
	|FROM
	|	TTSettlementsWithCustomersPreliminary AS CustomersARAPAccounting
	|WHERE
	|	CustomersARAPAccounting.CalculationObjectReceiver <> UNDEFINED
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	VendorsARAPAccounting.CalculationObjectReceiver.PaymentType_ AS TypeOfCalculationsReceiver,
	|	VendorsARAPAccounting.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	VendorsARAPAccounting.ARAPObjectIsMirrorReceiver.PaymentType_ AS TypeOfCalculationsMirrorReceiver,
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.ARAPObjectMirror AS ARAPObjectMirror,
	|	VendorsARAPAccounting.RowID AS RowID,
	|	VendorsARAPAccounting.IdOfTSLine AS IdOfTSLine,
	|	FALSE AS TheseAreSettlementsWithCustomers
	|FROM
	|	TTSettlementsWithSuppliersPreliminary AS VendorsARAPAccounting
	|WHERE
	|	VendorsARAPAccounting.CalculationObjectReceiver <> UNDEFINED
	|";
	
	Return QueryText;
	
EndFunction

// Combine preliminary calculations with a mirror on intercompany
Function QueryTextTTSettlementsWithCustomers()

	QueryText = "
	|SELECT
	|	Debt_Preliminary.Ref                        AS Ref,
	|	Debt_Preliminary.RecordType                   AS RecordType,
	|	Debt_Preliminary.Organization                   AS Organization,
	|	Debt_Preliminary.Partner                       AS Partner,
	|	Debt_Preliminary.Counterparty                    AS Counterparty,
	|	Debt_Preliminary.ARAPObject                AS ARAPObject,
	|	Debt_Preliminary.Contract                       AS Contract,
	|	CASE
	|		WHEN ISNULL(Directions.IncomeAccounting,FALSE) AND NOT ISNULL(ARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN Debt_Preliminary.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                      AS LineOfBusiness,
	|	Debt_Preliminary.ARAPCurrency          AS ARAPCurrency,
	|
	|	Debt_Preliminary.Sum                         AS Sum,
	|	Debt_Preliminary.AmountARAP           AS AmountARAP,
	|	Debt_Preliminary.SumCompl                     AS SumCompl,
	|	Debt_Preliminary.SumMan                      AS SumMan,
	|
	|	Debt_Preliminary.CorARAPObject             AS CorARAPObject,
	|	CorObjectsOfCalculations.Partner                                 AS CorPartner,
	|	CorObjectsOfCalculations.Organization                             AS CorCompany,
	|	CorObjectsOfCalculations.Contract                                 AS CorContract,
	|	CorObjectsOfCalculations.Counterparty                              AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DirectionsCor.IncomeAccounting,FALSE) AND NOT ISNULL(CorObjectsOfCalculations.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN CorObjectsOfCalculations.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                      AS CorLineOfBusiness,
	|	Debt_Preliminary.CalculationObjectReceiver        AS CalculationObjectReceiver,
	|	Debt_Preliminary.CurrencyReceiver                AS CurrencyReceiver,
	|	Debt_Preliminary.AmountReceiver                 AS AmountReceiver,
	|	Debt_Preliminary.PartnerReceiver               AS PartnerReceiver,
	|	ReceiverARAPObjects.Organization                        AS CompanyDestination,
	|	ReceiverARAPObjects.Contract                            AS ContractDestination,
	|	ReceiverARAPObjects.Counterparty                         AS CounterpartyReceiver,
	|	CASE
	|		WHEN ISNULL(DirectionsReceiver.IncomeAccounting,FALSE) AND NOT ISNULL(ReceiverARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ReceiverARAPObjects.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                       AS FieldOfActivityReceiver,
	|	Debt_Preliminary.ByDataOfSourceARAPObject               AS ByDataOfSourceARAPObject,
	|	Debt_Preliminary.RowID                            AS RowID,
	|	Debt_Preliminary.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|INTO TTSettlementsWithCustomers
	|FROM
	|	TTSettlementsWithCustomersPreliminary AS Debt_Preliminary
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = Debt_Preliminary.ARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|			ON Directions.Ref = ARAPObjects.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|			ON CorObjectsOfCalculations.Ref = Debt_Preliminary.CorARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsCor
	|			ON DirectionsCor.Ref = CorObjectsOfCalculations.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS ReceiverARAPObjects
	|			ON ReceiverARAPObjects.Ref = Debt_Preliminary.CalculationObjectReceiver
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsReceiver
	|			ON DirectionsReceiver.Ref = ReceiverARAPObjects.LineOfBusiness
	|
	|UNION ALL
	|
	|SELECT
	|	VendorsAccountsPayable.Ref                                              AS Ref,
	|	CASE WHEN VendorsAccountsPayable.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                                                        AS RecordType,
	|	VendorsAccountsPayable.Counterparty                                          AS Organization,
	|	VALUE(Catalog.Partners.OurEnterprise)                                AS Partner,
	|	VendorsAccountsPayable.Organization                                         AS Counterparty,
	|	VendorsAccountsPayable.ARAPObjectMirror                            AS ARAPObject,
	|	ARAPObjectMirrored.Contract                                            AS Contract,
	|	CASE
	|		WHEN ISNULL(DirectionsMirrored.IncomeAccounting,FALSE) AND NOT ISNULL(ARAPObjectMirrored.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ARAPObjectMirrored.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                        AS LineOfBusiness,
	|	ARAPObjectMirrored.ARAPCurrency                               AS ARAPCurrency,
	|
	|	VendorsAccountsPayable.Sum                                               AS Sum,
	|	CASE
	|		WHEN ISNULL(ARAPObjectMirrored.ARAPCurrency, UNDEFINED) = &LocalAccountingCurrency
	|			THEN VendorsAccountsPayable.SumCompl
	|		//To support old documents that could have an empty settlement object with different currencies.
	|		ELSE VendorsAccountsPayable.AmountARAP
	|	END                                                                        AS AmountARAP,
	|	VendorsAccountsPayable.SumCompl                                           AS SumCompl,
	|	VendorsAccountsPayable.SumMan                                            AS SumMan,
	|
	|	CorObjectsOfCalculations.Ref                                                    AS CorARAPObject,
	|	CorObjectsOfCalculations.Partner                                                   AS CorPartner,
	|	CorObjectsOfCalculations.Organization                                               AS CorCompany,
	|	CorObjectsOfCalculations.Contract                                                   AS CorContract,
	|	CorObjectsOfCalculations.Counterparty                                                AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DirectionsCor.IncomeAccounting,FALSE) AND NOT ISNULL(CorObjectsOfCalculations.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN CorObjectsOfCalculations.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                        AS CorLineOfBusiness,
	|	VendorsAccountsPayable.ARAPObjectIsMirrorReceiver                    AS CalculationObjectReceiver,
	|	VendorsAccountsPayable.CurrencyReceiver                                      AS CurrencyReceiver,
	|	VendorsAccountsPayable.AmountReceiver                                       AS AmountReceiver,
	|	ARAPObjectsReceiverIsMirrored.Partner                                    AS PartnerReceiver,
	|	ARAPObjectsReceiverIsMirrored.Organization                                AS CompanyDestination,
	|	ARAPObjectsReceiverIsMirrored.Contract                                    AS ContractDestination,
	|	ARAPObjectsReceiverIsMirrored.Counterparty                                 AS CounterpartyReceiver,
	|	CASE
	|		WHEN ISNULL(DirectionsMirrorReceiver.IncomeAccounting,FALSE) AND NOT ISNULL(ARAPObjectsReceiverIsMirrored.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ARAPObjectsReceiverIsMirrored.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                        AS FieldOfActivityReceiver,
	|	VendorsAccountsPayable.ByDataOfSourceARAPObject                    AS ByDataOfSourceARAPObject,
	|	VendorsAccountsPayable.RowID                                 AS RowID,
	|	VendorsAccountsPayable.TransferOfCounterpartyDebtBetweenCompanies   AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|FROM
	|	TTSettlementsWithSuppliersPreliminary AS VendorsAccountsPayable
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectMirrored
	|			ON ARAPObjectMirrored.Ref = VendorsAccountsPayable.ARAPObjectMirror
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsMirrored
	|			ON DirectionsMirrored.Ref = ARAPObjectMirrored.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectsReceiverIsMirrored
	|			ON ARAPObjectsReceiverIsMirrored.Ref = VendorsAccountsPayable.ARAPObjectIsMirrorReceiver
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsMirrorReceiver
	|			ON DirectionsMirrorReceiver.Ref = ARAPObjectsReceiverIsMirrored.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|			ON CorObjectsOfCalculations.Ref = VendorsAccountsPayable.CorARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsCor
	|			ON DirectionsCor.Ref = CorObjectsOfCalculations.LineOfBusiness
	|
	|WHERE
	|	VALUETYPE(VendorsAccountsPayable.Counterparty) = TYPE(Catalog.Companies)
	|	AND NOT VendorsAccountsPayable.TransferOfCounterpartyDebtBetweenCompanies
	|
	|UNION ALL
	|
	|SELECT
	|	VendorsAccountsPayable.Ref                                              AS Ref,
	|	CASE WHEN VendorsAccountsPayable.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                                                        AS RecordType,
	|	VendorsAccountsPayable.Counterparty                                          AS Organization,
	|	VALUE(Catalog.Partners.OurEnterprise)                                AS Partner,
	|	VendorsAccountsPayable.Organization                                         AS Counterparty,
	|	VendorsAccountsPayable.ARAPObjectMirror                            AS ARAPObject,
	|	ARAPObjectMirrored.Contract                                            AS Contract,
	|	CASE
	|		WHEN ISNULL(DirectionsMirrored.IncomeAccounting,FALSE) AND NOT ISNULL(ARAPObjectMirrored.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ARAPObjectMirrored.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                        AS LineOfBusiness,
	|	ARAPObjectMirrored.ARAPCurrency                               AS ARAPCurrency,
	|
	|	VendorsAccountsPayable.Sum                                               AS Sum,
	|	CASE
	|		WHEN ISNULL(ARAPObjectMirrored.ARAPCurrency, UNDEFINED) = &LocalAccountingCurrency
	|			THEN VendorsAccountsPayable.SumCompl
	|		//To support old documents that could have an empty settlement object with different currencies.
	|		ELSE VendorsAccountsPayable.AmountARAP
	|	END                                                                        AS AmountARAP,
	|	VendorsAccountsPayable.SumCompl                                           AS SumCompl,
	|	VendorsAccountsPayable.SumMan                                            AS SumMan,
	|
	|	CorObjectsOfCalculations.Ref                                                    AS CorARAPObject,
	|	CorObjectsOfCalculations.Partner                                                   AS CorPartner,
	|	CorObjectsOfCalculations.Organization                                               AS CorCompany,
	|	CorObjectsOfCalculations.Contract                                                   AS CorContract,
	|	CorObjectsOfCalculations.Counterparty                                                AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DirectionsCor.IncomeAccounting,FALSE) AND NOT ISNULL(CorObjectsOfCalculations.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN CorObjectsOfCalculations.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                        AS CorLineOfBusiness,
	|	VendorsAccountsPayable.ARAPObjectIsMirrorReceiver                    AS CalculationObjectReceiver,
	|	VendorsAccountsPayable.CurrencyReceiver                                      AS CurrencyReceiver,
	|	VendorsAccountsPayable.AmountReceiver                                       AS AmountReceiver,
	|	ARAPObjectsReceiverIsMirrored.Partner                                    AS PartnerReceiver,
	|	ARAPObjectsReceiverIsMirrored.Organization                                AS CompanyDestination,
	|	ARAPObjectsReceiverIsMirrored.Contract                                    AS ContractDestination,
	|	ARAPObjectsReceiverIsMirrored.Counterparty                                 AS CounterpartyReceiver,
	|	CASE
	|		WHEN ISNULL(DirectionsMirrorReceiver.IncomeAccounting,FALSE) AND NOT ISNULL(ARAPObjectsReceiverIsMirrored.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ARAPObjectsReceiverIsMirrored.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                        AS FieldOfActivityReceiver,
	|	Sources.RowID IS NOT NULL                                   AS ByDataOfSourceARAPObject,
	|	VendorsAccountsPayable.RowID                                 AS RowID,
	|	VendorsAccountsPayable.TransferOfCounterpartyDebtBetweenCompanies   AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|FROM
	|	TTSettlementsWithSuppliersPreliminary AS VendorsAccountsPayable
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectMirrored
	|			ON ARAPObjectMirrored.Ref = VendorsAccountsPayable.ARAPObjectMirror
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsMirrored
	|			ON DirectionsMirrored.Ref = ARAPObjectMirrored.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectsReceiverIsMirrored
	|			ON ARAPObjectsReceiverIsMirrored.Ref = VendorsAccountsPayable.ARAPObjectIsMirrorReceiver
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsMirrorReceiver
	|			ON DirectionsMirrorReceiver.Ref = ARAPObjectsReceiverIsMirrored.LineOfBusiness
	|
	|		LEFT JOIN TTSources AS Sources
	|			ON VendorsAccountsPayable.ARAPObjectMirror = Sources.CalculationObjectReceiver
	|				AND VendorsAccountsPayable.RowID = Sources.RowID
	|
	|		LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|			ON Sources.ARAPObject = CorObjectsOfCalculations.Ref
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsCor
	|			ON DirectionsCor.Ref = CorObjectsOfCalculations.LineOfBusiness
	|
	|WHERE
	|	VALUETYPE(VendorsAccountsPayable.Counterparty) = TYPE(Catalog.Companies)
	|	AND VendorsAccountsPayable.TransferOfCounterpartyDebtBetweenCompanies
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSettlementsWithSuppliers()
	
	QueryText = "
	|SELECT
	|	Debt_Preliminary.Ref                  AS Ref,
	|	Debt_Preliminary.RecordType             AS RecordType,
	|	Debt_Preliminary.Organization             AS Organization,
	|	Debt_Preliminary.Partner                 AS Partner,
	|	Debt_Preliminary.Counterparty              AS Counterparty,
	|	Debt_Preliminary.ARAPObject          AS ARAPObject,
	|	Debt_Preliminary.Contract                 AS Contract,
	|	CASE
	|		WHEN Directions.VendorARAP AND NOT ISNULL(ARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN Debt_Preliminary.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                AS LineOfBusiness,
	|	Debt_Preliminary.ARAPCurrency    AS ARAPCurrency,
	|
	|	Debt_Preliminary.Sum                   AS Sum,
	|	Debt_Preliminary.AmountARAP     AS AmountARAP,
	|	Debt_Preliminary.SumCompl               AS SumCompl,
	|	Debt_Preliminary.SumMan                AS SumMan,
	|
	|	CorObjectsOfCalculations.Ref                            AS CorARAPObject,
	|	CorObjectsOfCalculations.Partner                           AS CorPartner,
	|	CorObjectsOfCalculations.Organization                       AS CorCompany,
	|	CorObjectsOfCalculations.Contract                           AS CorContract,
	|	CorObjectsOfCalculations.Counterparty                        AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DirectionsCor.VendorARAP,FALSE) AND NOT ISNULL(CorObjectsOfCalculations.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN CorObjectsOfCalculations.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                AS CorLineOfBusiness,
	|	Debt_Preliminary.CalculationObjectReceiver  AS CalculationObjectReceiver,
	|	Debt_Preliminary.CurrencyReceiver          AS CurrencyReceiver,
	|	Debt_Preliminary.AmountReceiver           AS AmountReceiver,
	|	Debt_Preliminary.PartnerReceiver         AS PartnerReceiver,
	|	ReceiverARAPObjects.Organization                  AS CompanyDestination,
	|	ReceiverARAPObjects.Contract                      AS ContractDestination,
	|	ReceiverARAPObjects.Counterparty                   AS CounterpartyReceiver,
	|	CASE
	|		WHEN ISNULL(DirectionsReceiver.VendorARAP,FALSE) AND NOT ISNULL(ReceiverARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ReceiverARAPObjects.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                AS FieldOfActivityReceiver,
	|	Debt_Preliminary.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	Debt_Preliminary.RowID     AS RowID,
	|	Debt_Preliminary.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|INTO TTSettlementsWithSuppliers
	|FROM
	|	TTSettlementsWithSuppliersPreliminary AS Debt_Preliminary
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = Debt_Preliminary.ARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|			ON Directions.Ref = ARAPObjects.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|			ON CorObjectsOfCalculations.Ref = Debt_Preliminary.CorARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsCor
	|			ON DirectionsCor.Ref = CorObjectsOfCalculations.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS ReceiverARAPObjects
	|			ON ReceiverARAPObjects.Ref = Debt_Preliminary.CalculationObjectReceiver
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsReceiver
	|			ON DirectionsReceiver.Ref = ReceiverARAPObjects.LineOfBusiness
	|WHERE
	|	NOT (Debt_Preliminary.TransferOfCounterpartyDebtBetweenCompanies
	|			AND Debt_Preliminary.FillInSource)
	|	OR NOT Debt_Preliminary.TransferOfCounterpartyDebtBetweenCompanies
	|
	|UNION ALL
	|
	//Settlement objects for receiver records in settlements between organizations
	|SELECT
	|	Debt_Preliminary.Ref                  AS Ref,
	|	Debt_Preliminary.RecordType             AS RecordType,
	|	Debt_Preliminary.Organization             AS Organization,
	|	Debt_Preliminary.Partner                 AS Partner,
	|	Debt_Preliminary.Counterparty              AS Counterparty,
	|	Debt_Preliminary.ARAPObject          AS ARAPObject,
	|	Debt_Preliminary.Contract                 AS Contract,
	|	CASE
	|		WHEN Directions.VendorARAP AND NOT ISNULL(ARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN Debt_Preliminary.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                AS LineOfBusiness,
	|	Debt_Preliminary.ARAPCurrency    AS ARAPCurrency,
	|
	|	Debt_Preliminary.Sum                   AS Sum,
	|	Debt_Preliminary.AmountARAP     AS AmountARAP,
	|	Debt_Preliminary.SumCompl               AS SumCompl,
	|	Debt_Preliminary.SumMan                AS SumMan,
	|
	|	CorObjectsOfCalculations.Ref                            AS CorARAPObject,
	|	CorObjectsOfCalculations.Partner                           AS CorPartner,
	|	CorObjectsOfCalculations.Organization                       AS CorCompany,
	|	CorObjectsOfCalculations.Contract                           AS CorContract,
	|	CorObjectsOfCalculations.Counterparty                        AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DirectionsCor.VendorARAP,FALSE) AND NOT ISNULL(CorObjectsOfCalculations.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN CorObjectsOfCalculations.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                AS CorLineOfBusiness,
	|	Debt_Preliminary.CalculationObjectReceiver  AS CalculationObjectReceiver,
	|	Debt_Preliminary.CurrencyReceiver          AS CurrencyReceiver,
	|	Debt_Preliminary.AmountReceiver           AS AmountReceiver,
	|	Debt_Preliminary.PartnerReceiver         AS PartnerReceiver,
	|	ReceiverARAPObjects.Organization                  AS CompanyDestination,
	|	ReceiverARAPObjects.Contract                      AS ContractDestination,
	|	ReceiverARAPObjects.Counterparty                   AS CounterpartyReceiver,
	|	CASE
	|		WHEN ISNULL(DirectionsReceiver.VendorARAP,FALSE) AND NOT ISNULL(ReceiverARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ReceiverARAPObjects.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                AS FieldOfActivityReceiver,
	|	Sources.RowID IS NOT NULL           AS ByDataOfSourceARAPObject,
	|	Debt_Preliminary.RowID     AS RowID,
	|	Debt_Preliminary.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|FROM
	|	TTSettlementsWithSuppliersPreliminary AS Debt_Preliminary
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Ref = Debt_Preliminary.ARAPObject
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|			ON Directions.Ref = ARAPObjects.LineOfBusiness
	|
	|		LEFT JOIN TTSources AS Sources
	|			ON Debt_Preliminary.ARAPObject = Sources.CalculationObjectReceiver
	|				AND Debt_Preliminary.RowID = Sources.RowID
	|
	|		LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|			ON Sources.ARAPObject = CorObjectsOfCalculations.Ref
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsCor
	|			ON DirectionsCor.Ref = CorObjectsOfCalculations.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS ReceiverARAPObjects
	|			ON ReceiverARAPObjects.Ref = Debt_Preliminary.CalculationObjectReceiver
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsReceiver
	|			ON DirectionsReceiver.Ref = ReceiverARAPObjects.LineOfBusiness
	|WHERE
	|	Debt_Preliminary.TransferOfCounterpartyDebtBetweenCompanies
	|	AND Debt_Preliminary.FillInSource
	|
	|UNION ALL
	|
	|SELECT
	|	CustomersAccountsReceivable.Ref                                              AS Ref,
	|	CASE WHEN CustomersAccountsReceivable.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                                                     AS RecordType,
	|	CustomersAccountsReceivable.Counterparty                                          AS Organization,
	|	VALUE(Catalog.Partners.OurEnterprise)                             AS Partner,
	|	CustomersAccountsReceivable.Organization                                         AS Counterparty,
	|	CustomersAccountsReceivable.ARAPObjectMirror                            AS ARAPObject,
	|	ARAPObjectMirrored.Contract                                         AS Contract,
	|	CASE
	|		WHEN DirectionsMirrored.VendorARAP AND NOT ISNULL(ARAPObjectMirrored.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ARAPObjectMirrored.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                     AS LineOfBusiness,
	|	ARAPObjectMirrored.ARAPCurrency                            AS ARAPCurrency,
	|
	|	CustomersAccountsReceivable.Sum                                               AS Sum,
	|	CASE
	|		WHEN ISNULL(ARAPObjectMirrored.ARAPCurrency, UNDEFINED) = &LocalAccountingCurrency
	|			THEN CustomersAccountsReceivable.SumCompl
	|		//To support old documents that could have an empty settlement object with different currencies.
	|		ELSE CustomersAccountsReceivable.AmountARAP
	|	END                                                                     AS AmountARAP,
	|	CustomersAccountsReceivable.SumCompl                                           AS SumCompl,
	|	CustomersAccountsReceivable.SumMan                                            AS SumMan,
	|
	|	CorObjectsOfCalculations.Ref                                                 AS CorARAPObject,
	|	CorObjectsOfCalculations.Partner                                                AS CorPartner,
	|	CorObjectsOfCalculations.Organization                                            AS CorCompany,
	|	CorObjectsOfCalculations.Contract                                                AS CorContract,
	|	CorObjectsOfCalculations.Counterparty                                             AS CorCounterparty,
	|	CASE
	|		WHEN ISNULL(DirectionsMirrorReceiver.IncomeAccounting,FALSE) AND NOT ISNULL(CorObjectsOfCalculations.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN CorObjectsOfCalculations.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                     AS CorLineOfBusiness,
	|	CustomersAccountsReceivable.ARAPObjectIsMirrorReceiver                    AS CalculationObjectReceiver,
	|	CustomersAccountsReceivable.CurrencyReceiver                                      AS CurrencyReceiver,
	|	CustomersAccountsReceivable.AmountReceiver                                       AS AmountReceiver,
	|	ARAPObjectsReceiverIsMirrored.Partner                                 AS PartnerReceiver,
	|	ARAPObjectsReceiverIsMirrored.Organization                             AS CompanyDestination,
	|	ARAPObjectsReceiverIsMirrored.Contract                                 AS ContractDestination,
	|	ARAPObjectsReceiverIsMirrored.Counterparty                              AS CounterpartyReceiver,
	|	CASE
	|		WHEN ISNULL(DirectionsMirrorReceiver.IncomeAccounting,FALSE) AND NOT ISNULL(ARAPObjectsReceiverIsMirrored.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness,TRUE)
	|			THEN ARAPObjectsReceiverIsMirrored.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef) 
	|	END                                                                     AS FieldOfActivityReceiver,
	|	CustomersAccountsReceivable.ByDataOfSourceARAPObject                    AS ByDataOfSourceARAPObject,
	|	CustomersAccountsReceivable.RowID                                 AS RowID,
	|	CustomersAccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies   AS TransferOfCounterpartyDebtBetweenCompanies
	|
	|FROM
	|	TTSettlementsWithCustomersPreliminary AS CustomersAccountsReceivable
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectMirrored
	|			ON ARAPObjectMirrored.Ref = CustomersAccountsReceivable.ARAPObjectMirror
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsMirrored
	|			ON DirectionsMirrored.Ref = ARAPObjectMirrored.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjectsReceiverIsMirrored
	|			ON ARAPObjectsReceiverIsMirrored.Ref = CustomersAccountsReceivable.ARAPObjectIsMirrorReceiver
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsMirrorReceiver
	|			ON DirectionsMirrorReceiver.Ref = ARAPObjectsReceiverIsMirrored.LineOfBusiness
	|
	|		LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|			ON CorObjectsOfCalculations.Ref = CustomersAccountsReceivable.CorIsARAPObjectThatIsMirrored
	|		LEFT JOIN Catalog.LinesOfBusiness AS DirectionsCor
	|			ON DirectionsCor.Ref = CorObjectsOfCalculations.LineOfBusiness
	|WHERE
	|	VALUETYPE(CustomersAccountsReceivable.Counterparty) = TYPE(Catalog.Companies)
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextCustomersARAPAccounting()

	QueryText = "
	|SELECT
	|	DocumentData.Ref         AS Recorder,
	|	DocumentData.Date   AS Period,
	|	DocumentData.Date   AS RecorderDate,
	|	DocumentData.Number  AS RecorderNumber,
	|	TabularSection.RecordType                     AS RecordType,
	|	
	|	// Dimensions
	|	ISNULL(RegisterAccountingAnalyticsForPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	TabularSection.Organization                                            AS Organization,
	|	TabularSection.Counterparty                                             AS Counterparty,
	|	TabularSection.Partner                                                AS Partner,
	|	TabularSection.Contract                                                AS Contract,
	|	TabularSection.LineOfBusiness                                AS LineOfBusiness,
	|
	|	TabularSection.ARAPObject                                         AS ARAPObject,
	|	TabularSection.ARAPCurrency                                   AS Currency,
	|	
	|	// The amount in the settlement currency.
	|	TabularSection.AmountARAP                                    AS Sum,
	|	TabularSection.AmountARAP                                    AS AmountDue,
	|	CASE 
	|		WHEN TabularSection.ARAPCurrency = &LocalAccountingCurrency THEN
	|			TabularSection.AmountARAP
	|		ELSE
	|			TabularSection.SumCompl
	|	END                                                                 AS SumCompl,
	|	CASE
	|		WHEN TabularSection.ARAPCurrency = &ManagementAccountingCurrency THEN
	|			TabularSection.AmountARAP
	|		ELSE
	|			TabularSection.SumMan
	|	END                                                                 AS SumMan,
	|	
	|	// Attributes
	|	&BusinessOperation                                                AS BusinessOperation,
	|	VALUE(Enum.PaymentForms.SettlementOfARAP)                        AS PaymentMethod,
	|	&LocalAccountingCurrency                                       AS DocumentCurrency,
	|
	|	ISNULL(CorRegisterPartnerAccountingAnalytics.DimensionKey, UNDEFINED) AS CorPartnerAccountingDimension,
	|	TabularSection.CorARAPObject                                      AS CorARAPObject,
	|	TabularSection.CorPartner                                             AS CorPartner,
	|	TabularSection.CorCompany                                         AS CorCompany,
	|	TabularSection.CorContract                                             AS CorContract,
	|	TabularSection.CorCounterparty                                          AS CorCounterparty,
	|	TabularSection.CorLineOfBusiness                             AS CorLineOfBusiness,
	|
	|	ISNULL(RegisterAnalyticsOfAccountingByPartnersReceiver.DimensionKey, UNDEFINED) AS DestinationAccountingDimensionByPartners,
	|	TabularSection.CalculationObjectReceiver                                 AS CalculationObjectReceiver,
	|	TabularSection.CurrencyReceiver                                         AS CurrencyReceiver,
	|	TabularSection.AmountReceiver                                          AS AmountReceiver,
	|	TabularSection.PartnerReceiver                                        AS PartnerReceiver,
	|	TabularSection.CompanyDestination                                    AS CompanyDestination,
	|	TabularSection.ContractDestination                                        AS ContractDestination,
	|	TabularSection.CounterpartyReceiver                                     AS CounterpartyReceiver,
	|	TabularSection.FieldOfActivityReceiver                        AS FieldOfActivityReceiver,
	|	TabularSection.ByDataOfSourceARAPObject                       AS ByDataOfSourceARAPObject,
	|
	|	CASE WHEN TabularSection.AmountARAP > 0 AND TabularSection.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		OR TabularSection.AmountARAP < 0 AND TabularSection.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN BEGINOFPERIOD(DocumentData.Date,DAY)
	|		ELSE DATETIME(1,1,1)
	|	END                                                                 AS PaymentDate,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.DebtTransfer)
	|			OR &OperationKind = VALUE(Enum.KindsOfARAPSettlements.Barter)
	|			THEN 3
	|		ELSE 1
	|	END                                                                 AS TypeOfOperationForSorting,
	|	1                                                                     AS OrderOfOperationsWithinDocument,
	|	VALUE(Enum.SettlementOperations.TransferOfSettlements)   AS SettlementTransaction,
	|	&SettingUpBusinessTransaction                                                 AS BusinessTransactionSetting,
	|	
	|	CASE
	|		WHEN TabularSection.AmountARAP = 0
	|			OR TabularSection.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE CAST(TabularSection.SumCompl / TabularSection.AmountARAP AS NUMBER(10, 4))
	|	END                                                                 AS RateARAPCurrencyNumerator,
	|	CASE
	|		WHEN TabularSection.AmountARAP = 0
	|			OR TabularSection.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS RateARAPCurrencyDenominator,
	|	CASE
	|		WHEN TabularSection.SumMan = 0
	|			OR TabularSection.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE CAST(TabularSection.SumCompl / TabularSection.SumMan AS NUMBER(10, 4))
	|	END                                                                 AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE
	|		WHEN TabularSection.SumMan = 0
	|			OR TabularSection.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	TabularSection.RowID                                    AS FinRecordID
	|	
	|FROM
	|	TTSettlementsWithCustomers AS TabularSection
	|		INNER JOIN TTDocumentData_ AS DocumentData
	|		ON TRUE
	|	
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			TabularSection.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND TabularSection.Partner     = RegisterAccountingAnalyticsForPartners.Partner
	|			AND TabularSection.Counterparty  = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND TabularSection.Contract     = RegisterAccountingAnalyticsForPartners.Contract
	|			AND TabularSection.LineOfBusiness = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|	
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS CorRegisterPartnerAccountingAnalytics
	|		ON
	|			TabularSection.CorCompany = CorRegisterPartnerAccountingAnalytics.Organization
	|			AND TabularSection.CorPartner     = CorRegisterPartnerAccountingAnalytics.Partner
	|			AND TabularSection.CorCounterparty  = CorRegisterPartnerAccountingAnalytics.Counterparty
	|			AND TabularSection.CorContract     = CorRegisterPartnerAccountingAnalytics.Contract
	|			AND TabularSection.CorLineOfBusiness = CorRegisterPartnerAccountingAnalytics.LineOfBusiness
	|	
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAnalyticsOfAccountingByPartnersReceiver
	|		ON
	|			TabularSection.CompanyDestination  = RegisterAnalyticsOfAccountingByPartnersReceiver.Organization
	|			AND TabularSection.PartnerReceiver    = RegisterAnalyticsOfAccountingByPartnersReceiver.Partner
	|			AND TabularSection.CounterpartyReceiver = RegisterAnalyticsOfAccountingByPartnersReceiver.Counterparty
	|			AND TabularSection.ContractDestination    = RegisterAnalyticsOfAccountingByPartnersReceiver.Contract
	|			AND TabularSection.FieldOfActivityReceiver = RegisterAnalyticsOfAccountingByPartnersReceiver.LineOfBusiness
	|WHERE
	|	DocumentData.Posted
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextVendorsARAPAccounting()
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref                                                 AS Recorder,
	|	DocumentData.Date                                                   AS Period,
	|	DocumentData.Date                                                   AS RecorderDate,
	|	DocumentData.Number                                                  AS RecorderNumber,
	|	TabularSection.RecordType                                             AS RecordType,
	|	
	|	ISNULL(RegisterAccountingAnalyticsForPartners.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	TabularSection.Organization                                             AS Organization,
	|	TabularSection.Counterparty                                              AS Counterparty,
	|	TabularSection.Partner                                                 AS Partner,
	|	TabularSection.Contract                                                 AS Contract,
	|	TabularSection.LineOfBusiness                                 AS LineOfBusiness,
	|
	|	TabularSection.ARAPObject                                          AS ARAPObject,
	|	TabularSection.ARAPCurrency                                    AS Currency,
	|	
	|	// Resources
	|	// Amount in the settlement currency
	|	TabularSection.AmountARAP                                     AS Sum,
	|	TabularSection.AmountARAP                                     AS AmountDue,
	|	CASE 
	|		WHEN TabularSection.ARAPCurrency = &LocalAccountingCurrency THEN
	|			TabularSection.AmountARAP
	|		ELSE
	|			TabularSection.SumCompl
	|	END                                                                  AS SumCompl,
	|	CASE 
	|		WHEN TabularSection.ARAPCurrency = &ManagementAccountingCurrency THEN
	|			TabularSection.AmountARAP
	|		ELSE
	|			TabularSection.SumMan
	|	END                                                                  AS SumMan,
	|	
	|	// Attributes
	|	&BusinessOperation                                                  AS BusinessOperation,
	|	VALUE(Enum.PaymentForms.SettlementOfARAP)                          AS PaymentMethod,
	|	&LocalAccountingCurrency                                         AS DocumentCurrency,
	|
	|	ISNULL(CorRegisterPartnerAccountingAnalytics.DimensionKey, UNDEFINED) AS CorPartnerAccountingDimension,
	|	TabularSection.CorARAPObject                                      AS CorARAPObject,
	|	TabularSection.CorPartner                                             AS CorPartner,
	|	TabularSection.CorCompany                                         AS CorCompany,
	|	TabularSection.CorContract                                             AS CorContract,
	|	TabularSection.CorCounterparty                                          AS CorCounterparty,
	|	TabularSection.CorLineOfBusiness                             AS CorLineOfBusiness,
	|
	|	ISNULL(RegisterAnalyticsOfAccountingByPartnersReceiver.DimensionKey, UNDEFINED) AS DestinationAccountingDimensionByPartners,
	|	TabularSection.CalculationObjectReceiver                                 AS CalculationObjectReceiver,
	|	TabularSection.CurrencyReceiver                                         AS CurrencyReceiver,
	|	TabularSection.AmountReceiver                                          AS AmountReceiver,
	|	TabularSection.PartnerReceiver                                        AS PartnerReceiver,
	|	TabularSection.CompanyDestination                                    AS CompanyDestination,
	|	TabularSection.ContractDestination                                        AS ContractDestination,
	|	TabularSection.CounterpartyReceiver                                     AS CounterpartyReceiver,
	|	TabularSection.FieldOfActivityReceiver                        AS FieldOfActivityReceiver,
	|	TabularSection.ByDataOfSourceARAPObject                       AS ByDataOfSourceARAPObject,
	|
	|	CASE WHEN TabularSection.AmountARAP > 0 AND TabularSection.RecordType = VALUE(AccumulationRecordType.Expense)
	|		OR TabularSection.AmountARAP < 0 AND TabularSection.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN BEGINOFPERIOD(DocumentData.Date, DAY)
	|		ELSE DATETIME(1,1,1)
	|	END                                                                 AS PaymentDate,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.DebtTransfer)
	|			OR &OperationKind = VALUE(Enum.KindsOfARAPSettlements.Barter)
	|			THEN 3
	|		ELSE 1
	|	END                                                                 AS TypeOfOperationForSorting,
	|	1                                                                     AS OrderOfOperationsWithinDocument,
	|	VALUE(Enum.SettlementOperations.TransferOfSettlements)   AS SettlementTransaction,
	|	&SettingUpBusinessTransaction                                                 AS BusinessTransactionSetting,
	|	
	|	CASE
	|		WHEN TabularSection.AmountARAP = 0
	|			OR TabularSection.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE CAST(TabularSection.SumCompl / TabularSection.AmountARAP AS NUMBER(10, 4))
	|	END                                                                 AS RateARAPCurrencyNumerator,
	|	CASE
	|		WHEN TabularSection.AmountARAP = 0
	|			OR TabularSection.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS RateARAPCurrencyDenominator,
	|	CASE
	|		WHEN TabularSection.SumMan = 0
	|			OR TabularSection.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE CAST(TabularSection.SumCompl / TabularSection.SumMan AS NUMBER(10, 4))
	|	END                                                                 AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE
	|		WHEN TabularSection.SumMan = 0
	|			OR TabularSection.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE 1
	|	END                                                                 AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	TabularSection.RowID                                    AS FinRecordID
	|	
	|FROM
	|	TTSettlementsWithSuppliers AS TabularSection
	|		INNER JOIN TTDocumentData_ AS DocumentData ON TRUE
	|	
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON
	|			TabularSection.Organization = RegisterAccountingAnalyticsForPartners.Organization
	|			AND TabularSection.Partner     = RegisterAccountingAnalyticsForPartners.Partner
	|			AND TabularSection.Counterparty  = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND TabularSection.Contract     = RegisterAccountingAnalyticsForPartners.Contract
	|			AND TabularSection.LineOfBusiness = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|	
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS CorRegisterPartnerAccountingAnalytics
	|		ON
	|			TabularSection.CorCompany = CorRegisterPartnerAccountingAnalytics.Organization
	|			AND TabularSection.CorPartner     = CorRegisterPartnerAccountingAnalytics.Partner
	|			AND TabularSection.CorCounterparty  = CorRegisterPartnerAccountingAnalytics.Counterparty
	|			AND TabularSection.CorContract     = CorRegisterPartnerAccountingAnalytics.Contract
	|			AND TabularSection.CorLineOfBusiness = CorRegisterPartnerAccountingAnalytics.LineOfBusiness
	|	
	|		LEFT JOIN
	|			InformationRegister.AccountingDimensionByPartners AS RegisterAnalyticsOfAccountingByPartnersReceiver
	|		ON
	|			TabularSection.CompanyDestination  = RegisterAnalyticsOfAccountingByPartnersReceiver.Organization
	|			AND TabularSection.PartnerReceiver    = RegisterAnalyticsOfAccountingByPartnersReceiver.Partner
	|			AND TabularSection.CounterpartyReceiver = RegisterAnalyticsOfAccountingByPartnersReceiver.Counterparty
	|			AND TabularSection.ContractDestination    = RegisterAnalyticsOfAccountingByPartnersReceiver.Contract
	|			AND TabularSection.FieldOfActivityReceiver = RegisterAnalyticsOfAccountingByPartnersReceiver.LineOfBusiness
	|WHERE
	|	DocumentData.Posted
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSettlementsOnDebt()
	
	QueryText = "
	|SELECT
	|	Debt_.RecordType AS RecordType,
	|	Debt_.Organization AS Organization,
	|	Debt_.Partner AS Partner,
	|	Debt_.Counterparty AS Counterparty,
	|	Debt_.ARAPObject AS ARAPObject,
	|	Debt_.Contract AS Contract,
	|	Debt_.ARAPCurrency AS ARAPCurrency,
	|	Debt_.Sum AS Sum,
	|	Debt_.SumCompl AS SumCompl,
	|	Debt_.SumMan AS SumMan,
	|	Debt_.AmountARAP AS AmountARAP,
	|	Debt_.LineOfBusiness AS LineOfBusiness,
	|	Debt_.TheseAreSettlementsWithCustomers AS TheseAreSettlementsWithCustomers
	|
	|INTO TTSettlementsOnDebt
	|FROM
	|	(SELECT
	|		CASE WHEN CustomersARAPAccounting.AmountARAP < 0
	|			THEN CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|						THEN VALUE(AccumulationRecordType.Receipt)
	|						ELSE VALUE(AccumulationRecordType.Expense)
	|				END
	|			ELSE CustomersARAPAccounting.RecordType
	|		END                                     AS RecordType,
	|		CustomersARAPAccounting.Organization             AS Organization,
	|		CustomersARAPAccounting.Partner                 AS Partner,
	|		CustomersARAPAccounting.Counterparty              AS Counterparty,
	|		CustomersARAPAccounting.ARAPObject          AS ARAPObject,
	|		CustomersARAPAccounting.Contract                 AS Contract,
	|		CustomersARAPAccounting.LineOfBusiness AS LineOfBusiness,
	|		CustomersARAPAccounting.ARAPCurrency    AS ARAPCurrency,
	|		CASE WHEN CustomersARAPAccounting.Sum < 0
	|			THEN -CustomersARAPAccounting.Sum
	|			ELSE CustomersARAPAccounting.Sum
	|		END                                     AS Sum,
	|		CASE WHEN CustomersARAPAccounting.SumCompl < 0
	|			THEN -CustomersARAPAccounting.SumCompl
	|			ELSE CustomersARAPAccounting.SumCompl
	|		END                                     AS SumCompl,
	|		CASE WHEN CustomersARAPAccounting.SumMan < 0
	|			THEN -CustomersARAPAccounting.SumMan
	|			ELSE CustomersARAPAccounting.SumMan
	|		END                                     AS SumMan,
	|		CASE WHEN CustomersARAPAccounting.AmountARAP < 0
	|			THEN -CustomersARAPAccounting.AmountARAP
	|			ELSE CustomersARAPAccounting.AmountARAP
	|		END                                     AS AmountARAP,
	|		TRUE                                    AS TheseAreSettlementsWithCustomers
	|	FROM
	|		TTSettlementsWithCustomers AS CustomersARAPAccounting
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE WHEN VendorsARAPAccounting.AmountARAP < 0
	|			THEN CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|						THEN VALUE(AccumulationRecordType.Receipt)
	|						ELSE VALUE(AccumulationRecordType.Expense)
	|				END
	|			ELSE VendorsARAPAccounting.RecordType
	|		END                                        AS RecordType,
	|		VendorsARAPAccounting.Organization             AS Organization,
	|		VendorsARAPAccounting.Partner                 AS Partner,
	|		VendorsARAPAccounting.Counterparty              AS Counterparty,
	|		VendorsARAPAccounting.ARAPObject          AS ARAPObject,
	|		VendorsARAPAccounting.Contract                 AS Contract,
	|		VendorsARAPAccounting.LineOfBusiness AS LineOfBusiness,
	|		VendorsARAPAccounting.ARAPCurrency    AS ARAPCurrency,
	|		CASE WHEN VendorsARAPAccounting.Sum < 0
	|			THEN -VendorsARAPAccounting.Sum
	|			ELSE VendorsARAPAccounting.Sum
	|		END                                        AS Sum,
	|		CASE WHEN VendorsARAPAccounting.SumCompl < 0
	|			THEN -VendorsARAPAccounting.SumCompl
	|			ELSE VendorsARAPAccounting.SumCompl
	|		END                                        AS SumCompl,
	|		CASE WHEN VendorsARAPAccounting.SumMan < 0
	|			THEN -VendorsARAPAccounting.SumMan
	|			ELSE VendorsARAPAccounting.SumMan
	|		END                                        AS SumMan,
	|		CASE WHEN VendorsARAPAccounting.AmountARAP < 0
	|			THEN -VendorsARAPAccounting.AmountARAP
	|			ELSE VendorsARAPAccounting.AmountARAP
	|		END                                        AS AmountARAP,
	|		FALSE                                         AS TheseAreSettlementsWithCustomers
	|	FROM
	|		TTSettlementsWithSuppliers AS VendorsARAPAccounting
	|
	|	) AS Debt_
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                                               AS RefType,
	|	VALUE(Enum.BusinessTransactions.ARAPSettlement)  AS BusinessOperation,
	|	DocumentData.Organization                                            AS Organization,
	|	UNDEFINED                                                           AS Partner,
	|	UNDEFINED                                                           AS StorageLocation,
	|	CASE WHEN DocumentData.CounterpartyDebtor = UNDEFINED
	|		THEN DocumentData.Creditor
	|		ELSE DocumentData.CounterpartyDebtor
	|	END                                                                  AS Counterparty,
	|	DocumentData.Department                                          AS Department,
	|	DocumentData.Date                                                   AS IBDocumentDate,
	|	DocumentData.Ref                                                 AS Ref,
	|	DocumentData.Number                                                  AS IBDocumentNumber,
	|	UNDEFINED                                                           AS Status,
	|	DocumentData.EmployeeResponsible                                          AS EmployeeResponsible,
	|	FALSE                                                                   AS AdditionalRecord,
	|	""""                                                                   AS More,
	|	DocumentData.Comment                                            AS Comment,
	|	DocumentData.Posted                                               AS Posted,
	|	DocumentData.DeletionMark                                        AS DeletionMark,
	|	DATETIME(1,1,1)                                                       AS SourceDocumentDate,
	|	""""                                                                   AS SourceDocumentNumber,
	|	DocumentData.SumCompl                                              AS Sum,
	|	DocumentData.Organization.LocalAccountingCurrency             AS Currency,
	|	UNDEFINED                                                           AS Contract,
	|	FALSE                                                                   AS ReverseTransactionCorrection,
	|	UNDEFINED                                                           AS ReversedDocument,
	|	UNDEFINED                                                           AS CorrectedDocument,
	|	UNDEFINED                                                           AS LineOfBusiness,
	|	DocumentData.Date                                                   AS RecordingInAccountingDate
	|FROM
	|	Document.ARAPSettlement AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Adapted text of the request for movements by case.
// 
// Parameters:
//  RegisterName - String - The name of the register to use to construct the adapted query text.
// 
// Returns:
//  Structure - Adapted Case-Sensitive Query Text:
//	 * QueryText - String -  
//	 * ParameterValues - Structure -:
//	 ** Key - String - Name of the Request Parameter
//	 ** Value - Arbitrary - The value of the request parameter.
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	SynonymForDocumentTable = "";
	
	FullDocumentName = EmptyRef().Metadata().FullName();
	
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
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	ParametersOfTheEvent = New Structure;
	ParametersOfTheEvent.Insert("MetadataIdentifier", Common.MetadataObjectID(FullDocumentName));
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParametersOfTheEvent;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Procedure DistributeTableParts(Query)
	
	TSQuery = New Query;
	#Region QueryTextByTabularParts
	TSQuery.Text = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CounterpartyDebtor AS CounterpartyDebtor,
	|	DocumentData.Creditor AS Creditor,
	|	DocumentData.CompanyCreditor AS CompanyCreditor,
	|	DocumentData.ARAPObjectIntercompany AS ARAPObjectIntercompany,
	|	DocumentData.ARAPObjectIntercompany.Organization AS IntercampanyOrganization,
	|	DocumentData.ARAPObjectIntercompanyMirrored AS ARAPObjectIntercompanyMirrored,
	|	DocumentData.ARAPObjectIntercompanyMirrored.Organization AS IntercampanyMirroredCompany,
	|	DocumentData.ARAPObjectIntercompany <> VALUE(Catalog.ARAPObjects.EmptyRef) AS IntercompanyARAP
	|INTO TTDocumentData_
	|FROM
	|	Document.ARAPSettlement AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsReceivable.Ref AS Ref,
	|	&OperationKind AS OperationKind,
	|	AccountsReceivable.LineNumber AS LineNumber,
	|	AccountsReceivable.PaymentType_ AS PaymentType_,
	|	AccountsReceivable.Partner AS Partner,
	|	AccountsReceivable.LineOfBusiness AS LineOfBusiness,
	|	AccountsReceivable.Sum AS Sum,
	|	AccountsReceivable.AmountARAP AS AmountARAP,
	|	AccountsReceivable.ARAPCurrency AS ARAPCurrency,
	|	AccountsReceivable.ARAPObject.Organization AS Organization,
	|	AccountsReceivable.SumMan AS SumMan,
	|	AccountsReceivable.SumCompl AS SumCompl,
	|	AccountsReceivable.ARAPObject AS ARAPObject,
	|	AccountsReceivable.ARAPObject.ARAPObjectType AS ARAPObjectType,
	|	AccountsReceivable.ARAPObject.Object AS Object,
	|	AccountsReceivable.ARAPObject.Contract AS Contract,
	|	AccountsReceivable.ARAPObjectMirror AS ARAPObjectMirror,
	|	AccountsReceivable.RowID AS RowID
	|INTO TTAccountsReceivable
	|FROM
	|	Document.ARAPSettlement.AccountsReceivable AS AccountsReceivable
	|WHERE
	|	AccountsReceivable.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsPayable.Ref AS Ref,
	|	&OperationKind AS OperationKind,
	|	AccountsPayable.LineNumber AS LineNumber,
	|	AccountsPayable.PaymentType_ AS PaymentType_,
	|	AccountsPayable.Partner AS Partner,
	|	AccountsPayable.LineOfBusiness AS LineOfBusiness,
	|	AccountsPayable.Sum AS Sum,
	|	AccountsPayable.AmountARAP AS AmountARAP,
	|	AccountsPayable.ARAPCurrency AS ARAPCurrency,
	|	AccountsPayable.ARAPObject.Organization AS Organization,
	|	AccountsPayable.SumMan AS SumMan,
	|	AccountsPayable.SumCompl AS SumCompl,
	|	AccountsPayable.ARAPObject AS ARAPObject,
	|	AccountsPayable.ARAPObject.ARAPObjectType AS ARAPObjectType,
	|	AccountsPayable.ARAPObject.Object AS Object,
	|	AccountsPayable.ARAPObject.Contract AS Contract,
	|	AccountsPayable.ARAPObjectMirror AS ARAPObjectMirror,
	|	AccountsPayable.RowID AS RowID
	|INTO TTAccountsPayable
	|FROM
	|	Document.ARAPSettlement.AccountsPayable AS AccountsPayable
	|WHERE
	|	AccountsPayable.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.ARAPObjectType AS ARAPObjectType,
	|	NestedQuery.ARAPObject.Object AS Object,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.ContractRateOption AS ContractRateOption,
	|	NestedQuery.ComplCurrency AS ComplCurrency,
	|	NestedQuery.ARAPCurrency AS ARAPCurrency
	|INTO TTCalculationObjects_
	|FROM
	|	(SELECT
	|		AccountsReceivable.ARAPObject AS ARAPObject,
	|		AccountsReceivable.ARAPObjectType AS ARAPObjectType,
	|		AccountsReceivable.Object AS Object,
	|		AccountsReceivable.Contract AS Contract,
	|		ISNULL(CounterpartyContracts.ContractRateOption,
	|			ISNULL(IntercampanyTreaties.ContractRateOption,
	|				VALUE(Enum.ContractRateOptions.Mutable))) AS ContractRateOption,
	|		AccountsReceivable.Organization.LocalAccountingCurrency AS ComplCurrency,
	|		AccountsReceivable.ARAPCurrency AS ARAPCurrency
	|	FROM
	|		TTAccountsReceivable AS AccountsReceivable
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|			ON AccountsReceivable.Contract = CounterpartyContracts.Ref
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercampanyTreaties
	|			ON AccountsReceivable.Contract = IntercampanyTreaties.Ref
	|
	|	UNION ALL
	|
	|	SELECT
	|		AccountsPayable.ARAPObject AS ARAPObject,
	|		AccountsPayable.ARAPObjectType AS ARAPObjectType,
	|		AccountsPayable.Object AS Object,
	|		AccountsPayable.Contract AS Contract,
	|		ISNULL(CounterpartyContracts.ContractRateOption,
	|			ISNULL(IntercampanyTreaties.ContractRateOption,
	|				VALUE(Enum.ContractRateOptions.Mutable))) AS ContractRateOption,
	|		AccountsPayable.Organization.LocalAccountingCurrency AS ComplCurrency,
	|		AccountsPayable.ARAPCurrency AS ARAPCurrency
	|	FROM
	|		TTAccountsPayable AS AccountsPayable
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|			ON AccountsPayable.Contract = CounterpartyContracts.Ref
	|		LEFT JOIN Catalog.IntercompanyContracts AS IntercampanyTreaties
	|			ON AccountsPayable.Contract = IntercampanyTreaties.Ref) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ARAPObjects.ARAPObject AS ARAPObject,
	|	ARAPObjects.ARAPObjectType AS ARAPObjectType,
	|	ARAPObjects.ARAPObject.Object AS Object,
	|	ARAPObjects.Contract AS Contract,
	|	ARAPObjects.ContractRateOption AS ContractRateOption,
	|	ARAPObjects.ComplCurrency AS ComplCurrency,
	|	ARAPObjects.ARAPCurrency AS ARAPCurrency,
	|	CASE WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseNumerator,1)
	|		WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN ISNULL(ExchangeRatesAccordingToDocuments.RateARAPCurrencyNumerator,1)
	|		ELSE 
	|			ISNULL(ExchangeRates.CourseNumerator,1)
	|	END                                                                           AS CourseNumeratorLocal,
	|	CASE WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseDenominator,1)
	|		WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN ISNULL(ExchangeRatesAccordingToDocuments.RateARAPCurrencyDenominator,1)
	|		ELSE
	|			ISNULL(ExchangeRates.CourseDenominator,1)
	|	END                                                                           AS CourseDenominatorLocal,
	|	CASE WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND ARAPObjects.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseNumerator,1)
	|		WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN 
	|				ISNULL(ExchangeRatesAccordingToDocuments.RateManagementAccountingCurrencyNumerator,1)
	|		ELSE
	|			ISNULL(ManSExchangeRate.CourseNumerator,1)
	|	END                                                                           AS CourseNumeratorMan,
	|	CASE WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
	|					AND ARAPObjects.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN ISNULL(ExchangeRatesUnderContracts.CourseDenominator,1)
	|		WHEN ARAPObjects.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
	|				AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|			THEN 
	|				ISNULL(ExchangeRatesAccordingToDocuments.RateManagementAccountingCurrencyDenominator,1)
	|		ELSE 
	|			ISNULL(ManSExchangeRate.CourseDenominator,1)
	|	END                                                                           AS CourseDenominatorMan
	|INTO TTIsPaymentARAPObjectWithCourses
	|FROM
	|	TTCalculationObjects_ AS ARAPObjects
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, Currency = &ManagementAccountingCurrency) AS ManSExchangeRate
	|			ON ARAPObjects.ComplCurrency = ManSExchangeRate.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, ) AS ExchangeRates
	|			ON ARAPObjects.ARAPCurrency = ExchangeRates.Currency
	|			AND ARAPObjects.ComplCurrency = ExchangeRates.BaseCurrency
	|		LEFT JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(&DocumentDate, ) AS ExchangeRatesUnderContracts
	|			ON ARAPObjects.Contract = ExchangeRatesUnderContracts.Contract
	|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS ExchangeRatesAccordingToDocuments
	|			ON ARAPObjects.Object = ExchangeRatesAccordingToDocuments.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	Calculations.AccountingDimensionByPartners.Partner AS Partner,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS ARAPCurrency,
	|	CASE WHEN Calculations.Sum < 0
	|		THEN -Calculations.Sum
	|		ELSE Calculations.Sum
	|	END AS Sum,
	|	CASE WHEN Calculations.SumCompl < 0
	|		THEN -Calculations.SumCompl
	|		ELSE Calculations.SumCompl
	|	END AS SumCompl,
	|	CASE WHEN Calculations.SumMan < 0
	|		THEN -Calculations.SumMan
	|		ELSE Calculations.SumMan
	|	END AS SumMan,
	|	Calculations.FinRecordID AS FinRecordID,
	|	FALSE AS Check
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Recorder = &Ref
	|	AND &AmountsOfReglUprAreIndicatedInDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.AccountingDimensionByPartners.Organization AS Organization,
	|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	Calculations.AccountingDimensionByPartners.Partner AS Partner,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS ARAPCurrency,
	|	CASE WHEN Calculations.Sum < 0
	|		THEN -Calculations.Sum
	|		ELSE Calculations.Sum
	|	END AS Sum,
	|	CASE WHEN Calculations.SumCompl < 0
	|		THEN -Calculations.SumCompl
	|		ELSE Calculations.SumCompl
	|	END AS SumCompl,
	|	CASE WHEN Calculations.SumMan < 0
	|		THEN -Calculations.SumMan
	|		ELSE Calculations.SumMan
	|	END AS SumMan,
	|	Calculations.FinRecordID AS FinRecordID,
	|	FALSE AS Check
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Recorder = &Ref
	|	AND &AmountsOfReglUprAreIndicatedInDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsReceivable.Ref AS Ref,
	|	&OperationKind AS OperationKind,
	|	AccountsReceivable.LineNumber AS LineNumber,
	|	AccountsReceivable.PaymentType_ AS PaymentType_,
	|	AccountsReceivable.Partner AS Partner,
	|	AccountsReceivable.LineOfBusiness AS LineOfBusiness,
	|	AccountsReceivable.Sum AS Sum,
	|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
	|	0 AS AmountReceiver,
	|	AccountsReceivable.AmountARAP AS AmountARAP,
	|	AccountsReceivable.ARAPCurrency AS ARAPCurrency,
	|	AccountsReceivable.Organization AS Organization,
	|	DocumentData.CounterpartyDebtor AS Counterparty,
	|	CASE
	|		WHEN NOT &AmountsOfReglUprAreIndicatedInDocument
	|				AND (ExchangeRates.ContractRateOption <> VALUE(Enum.ContractRateOptions.Mutable)
	|					OR AccountsReceivable.SumMan = 0)
	|			THEN CAST(AccountsReceivable.AmountARAP * (ExchangeRates.CourseNumeratorLocal / ExchangeRates.CourseDenominatorLocal) / (ExchangeRates.CourseNumeratorMan / ExchangeRates.CourseDenominatorMan) AS NUMBER(31,2))
	|		WHEN AccountsReceivable.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN AccountsReceivable.AmountARAP
	|		ELSE
	|			AccountsReceivable.SumMan
	|	END AS SumMan,
	|	CASE
	|		WHEN NOT &AmountsOfReglUprAreIndicatedInDocument
	|				AND (ExchangeRates.ContractRateOption <> VALUE(Enum.ContractRateOptions.Mutable)
	|					OR AccountsReceivable.SumCompl = 0)
	|			THEN CAST(AccountsReceivable.AmountARAP * ExchangeRates.CourseNumeratorLocal / ExchangeRates.CourseDenominatorLocal AS NUMBER(31,2))
	|		WHEN AccountsReceivable.ARAPCurrency = &LocalAccountingCurrency
	|			THEN AccountsReceivable.AmountARAP
	|		ELSE
	|			AccountsReceivable.SumCompl
	|	END AS SumCompl,
	|	AccountsReceivable.AmountARAP AS InitialSettlementAmount,
	|	AccountsReceivable.ARAPObject AS ARAPObject,
	|	AccountsReceivable.ARAPObjectMirror AS ARAPObjectMirror,
	|	AccountsReceivable.ARAPObject AS CalculationObjectReceiver,
	|	AccountsReceivable.Partner AS PartnerReceiver,
	|	FALSE AS ByDataOfSourceARAPObject,
	|	AccountsReceivable.ARAPObjectMirror AS ARAPObjectIsMirrorReceiver,
	|	AccountsReceivable.RowID AS RowID,
	|	AccountsReceivable.RowID AS CorIdOfLine,
	|	DocumentData.ARAPObjectIntercompany AS ARAPObjectIntercompany,
	|	DocumentData.IntercampanyOrganization AS IntercampanyOrganization,
	|	DocumentData.ARAPObjectIntercompanyMirrored AS ARAPObjectIntercompanyMirrored,
	|	DocumentData.IntercampanyMirroredCompany AS IntercampanyMirroredCompany,
	|	DocumentData.IntercompanyARAP AS TransferOfCounterpartyDebtBetweenCompanies
	|FROM
	|	TTAccountsReceivable AS AccountsReceivable
	|	LEFT JOIN TTIsPaymentARAPObjectWithCourses AS ExchangeRates
	|	ON AccountsReceivable.ARAPObject = ExchangeRates.ARAPObject
	|		AND AccountsReceivable.ARAPCurrency = ExchangeRates.ARAPCurrency
	|	LEFT JOIN TTDocumentData_ AS DocumentData
	|	ON AccountsReceivable.Ref = DocumentData.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsPayable.Ref AS Ref,
	|	&OperationKind AS OperationKind,
	|	AccountsPayable.LineNumber AS LineNumber,
	|	AccountsPayable.PaymentType_ AS PaymentType_,
	|	AccountsPayable.Partner AS Partner,
	|	AccountsPayable.LineOfBusiness AS LineOfBusiness,
	|	AccountsPayable.Sum AS Sum,
	|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
	|	0 AS AmountReceiver,
	|	AccountsPayable.AmountARAP AS AmountARAP,
	|	AccountsPayable.ARAPCurrency AS ARAPCurrency,
	|	AccountsPayable.Organization AS Organization,
	|	DocumentData.Creditor AS Counterparty,
	|	CASE 
	|		WHEN NOT &AmountsOfReglUprAreIndicatedInDocument
	|				AND (ExchangeRates.ContractRateOption <> VALUE(Enum.ContractRateOptions.Mutable)
	|					OR AccountsPayable.SumMan = 0)
	|			THEN CAST(AccountsPayable.AmountARAP * (ExchangeRates.CourseNumeratorLocal / ExchangeRates.CourseDenominatorLocal) / (ExchangeRates.CourseNumeratorMan / ExchangeRates.CourseDenominatorMan) AS NUMBER(31,2))
	|		WHEN AccountsPayable.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN AccountsPayable.AmountARAP
	|		ELSE
	|			AccountsPayable.SumMan
	|	END AS SumMan,
	|	CASE 
	|		WHEN NOT &AmountsOfReglUprAreIndicatedInDocument
	|				AND (ExchangeRates.ContractRateOption <> VALUE(Enum.ContractRateOptions.Mutable)
	|					OR AccountsPayable.SumCompl = 0)
	|			THEN CAST(AccountsPayable.AmountARAP * ExchangeRates.CourseNumeratorLocal / ExchangeRates.CourseDenominatorLocal AS NUMBER(31,2))
	|		WHEN AccountsPayable.ARAPCurrency = &LocalAccountingCurrency
	|			THEN AccountsPayable.AmountARAP
	|		ELSE
	|			AccountsPayable.SumCompl
	|	END AS SumCompl,
	|	AccountsPayable.AmountARAP AS InitialSettlementAmount,
	|	AccountsPayable.ARAPObject AS ARAPObject,
	|	AccountsPayable.ARAPObjectMirror AS ARAPObjectMirror,
	|	AccountsPayable.ARAPObject AS CalculationObjectReceiver,
	|	AccountsPayable.Partner AS PartnerReceiver,
	|	FALSE AS ByDataOfSourceARAPObject,
	|	AccountsPayable.ARAPObjectMirror AS ARAPObjectIsMirrorReceiver,
	|	AccountsPayable.RowID AS RowID,
	|	AccountsPayable.RowID AS CorIdOfLine,
	|	DocumentData.ARAPObjectIntercompany AS ARAPObjectIntercompany,
	|	DocumentData.IntercampanyOrganization AS IntercampanyOrganization,
	|	DocumentData.ARAPObjectIntercompanyMirrored AS ARAPObjectIntercompanyMirrored,
	|	DocumentData.IntercampanyMirroredCompany AS IntercampanyMirroredCompany,
	|	DocumentData.IntercompanyARAP AS TransferOfCounterpartyDebtBetweenCompanies
	|FROM
	|	TTAccountsPayable AS AccountsPayable
	|	LEFT JOIN TTIsPaymentARAPObjectWithCourses AS ExchangeRates
	|	ON AccountsPayable.ARAPObject = ExchangeRates.ARAPObject
	|		AND AccountsPayable.ARAPCurrency = ExchangeRates.ARAPCurrency
	|	LEFT JOIN TTDocumentData_ AS DocumentData
	|	ON AccountsPayable.Ref = DocumentData.Ref
	|";
	#EndRegion
	
	AmountsOfReglUprAreIndicatedInDocument = Query.Parameters.OperationKind = Enums.KindsOfARAPSettlements.Barter
		Or Query.Parameters.OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies
		Or Query.Parameters.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary
		Or Query.Parameters.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
		Or Query.Parameters.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent;
	
	TSQuery.SetParameter("Ref", Query.Parameters.Ref);
	TSQuery.SetParameter("DocumentDate", Query.Parameters.Period);
	TSQuery.SetParameter("OperationKind", Query.Parameters.OperationKind);
	TSQuery.SetParameter("AmountsOfReglUprAreIndicatedInDocument", AmountsOfReglUprAreIndicatedInDocument);
	TSQuery.SetParameter("ManagementAccountingCurrency", Query.Parameters.ManagementAccountingCurrency);
	TSQuery.SetParameter("LocalAccountingCurrency", Query.Parameters.LocalAccountingCurrency);
	TSQuery.SetParameter("TransferBetweenCompanies", ValueIsFilled(Query.Parameters.ARAPObjectIntercompany));
	
	Result = TSQuery.ExecuteBatch();
	LastIndex = Result.UBound();
	
	CustomersARAPAccounting = Result[LastIndex-3].Unload();
	VendorsARAPAccounting = Result[LastIndex-2].Unload();
	
	AccountsReceivable = Result[LastIndex-1].Unload();
	AccountsPayable = Result[LastIndex].Unload();
	
	SenderOfDebt = AccountsReceivable;
	RecipientOfDebt = AccountsPayable;
	If SenderCredit(Query.Parameters.OperationKind) Then
		SenderOfDebt = AccountsPayable;
		RecipientOfDebt = AccountsReceivable;
	EndIf;
	
	SentInCurrency = TotalInAccountingCurrencies(SenderOfDebt);
	ReceivedInForeignCurrency = TotalInAccountingCurrencies(RecipientOfDebt);
	
	ResultSender = SenderOfDebt.CopyColumns();
	ResultRecipient = RecipientOfDebt.CopyColumns();
	
	ARAPObjectIntercompany = Query.Parameters.ARAPObjectIntercompany;
	OurEnterprise = Catalogs.Partners.OurEnterprise;
	
	PropertiesOfBoxAreApplicable = "CalculationObjectReceiver,PartnerReceiver,ARAPObjectIsMirrorReceiver,ByDataOfSourceARAPObject";
	LastIndex = RecipientOfDebt.Count()-1;
	For Each Sender In SenderOfDebt Do
		IndexOf = -1;
		For Each Recipient In RecipientOfDebt Do
			IndexOf = IndexOf + 1;
			If Recipient.SumCompl = 0 Then
				Continue;
			EndIf;
			If Sender.SumCompl = 0 Then
				Break;
			EndIf;
			LastPayment = IndexOf = LastIndex;
			
			// in order to exclude unjustified discrepancies in operational calculations during repeated rechecking
			// , the identifiers by which the double-entry correspondence is constructed must be obtained from the database
			If Sender.ARAPCurrency = Recipient.ARAPCurrency 
					And Sender.AmountARAP <= Recipient.AmountARAP
				Or Sender.SumCompl < Recipient.SumCompl Then
				IDSender = Sender.RowID;
			Else
				IDSender = Recipient.RowID;
			EndIf;
			IDRecipient = New UUID;
			
			SumCompl = ARAPAccountingServer.DeductAmount(Sender.SumCompl, Recipient.SumCompl, LastPayment);
			SumMan  = ARAPAccountingServer.DeductAmount(Sender.SumMan, Recipient.SumMan, LastPayment);
			If Sender.ARAPCurrency = Recipient.ARAPCurrency Then
				AmountSender = ARAPAccountingServer.DeductAmount(Sender.AmountARAP, Recipient.AmountARAP, LastPayment);
				
			Else// we will distribute several sender currencies to several recipient currencies
				
				AmountSender = AmountARAP(SentInCurrency[Sender.ARAPCurrency], SumCompl);
				AdjustingAmountOfSettlements = Sender.AmountARAP - AmountSender;
				// we will correct the spelling, correct the sum itself and the total for the distribution of subsequent lines
				If AdjustingAmountOfSettlements < 0 Then
					AmountSender = AmountSender + AdjustingAmountOfSettlements;
					SentInCurrency[Sender.ARAPCurrency].AmountARAP = 
						SentInCurrency[Sender.ARAPCurrency].AmountARAP - AdjustingAmountOfSettlements;
					ReceivedInForeignCurrency[Recipient.ARAPCurrency].AmountARAP = 
						ReceivedInForeignCurrency[Recipient.ARAPCurrency].AmountARAP - AdjustingAmountOfSettlements;
				EndIf;
				Sender.AmountARAP = Sender.AmountARAP - AmountSender;
			
			EndIf;

			If Sender.ARAPCurrency = Recipient.ARAPCurrency Then
				AmountRecipient = AmountSender;
				
			Else// we will distribute several sender currencies to several recipient currencies
				
				AmountRecipient = AmountARAP(ReceivedInForeignCurrency[Recipient.ARAPCurrency], SumCompl);
				AdjustingAmountOfSettlements = Recipient.AmountARAP - AmountRecipient;
				// we will correct the spelling, correct the sum itself and the total for the distribution of subsequent lines
				If AdjustingAmountOfSettlements < 0 Then
					AmountRecipient = AmountRecipient + AdjustingAmountOfSettlements;
					ReceivedInForeignCurrency[Recipient.ARAPCurrency].AmountARAP = 
						ReceivedInForeignCurrency[Recipient.ARAPCurrency].AmountARAP - AdjustingAmountOfSettlements;
				EndIf;
				Recipient.AmountARAP = Recipient.AmountARAP - AmountRecipient;
			EndIf;
			
			NewSender = ResultSender.Add();
			FillPropertyValues(NewSender, Sender,,PropertiesOfBoxAreApplicable);
			NewSender.AmountARAP = AmountSender;
			NewSender.SumCompl = SumCompl;
			NewSender.SumMan = SumMan;
			If AmountsOfReglUprAreIndicatedInDocument Then
				IDSender = FindRowId(NewSender, CustomersARAPAccounting, VendorsARAPAccounting);
				If Not ValueIsFilled(IDSender) Then
					IDSender = New UUID;
				EndIf;
			EndIf;
			NewSender.RowID = IDSender;
			NewSender.CorIdOfLine = "";
			
			NewSender.ByDataOfSourceARAPObject = False;
			If Not AmountsOfReglUprAreIndicatedInDocument Then
				If Sender.TransferOfCounterpartyDebtBetweenCompanies Then
					NewSender.PartnerReceiver = OurEnterprise;
					// To comply with the double entry when transmitting between
					// organizations, the organization of the source must be equal to the organization of the receiver
					If Sender.Organization = Sender.IntercampanyOrganization Then
						NewSender.CalculationObjectReceiver = Sender.ARAPObjectIntercompany;
						NewSender.ARAPObjectIsMirrorReceiver = Sender.ARAPObjectIntercompanyMirrored;
					Else
						NewSender.CalculationObjectReceiver = Sender.ARAPObjectIntercompanyMirrored;
						NewSender.ARAPObjectIsMirrorReceiver = Sender.ARAPObjectIntercompany;
					EndIf;
				Else
					NewSender.CalculationObjectReceiver = Recipient.ARAPObject;
					NewSender.ARAPObjectIsMirrorReceiver = Recipient.ARAPObjectMirror;
					NewSender.PartnerReceiver = Recipient.Partner;
				EndIf;
				NewSender.CurrencyReceiver = Recipient.ARAPCurrency;
				NewSender.AmountReceiver = AmountRecipient;
			EndIf;
			
			NewRecipient = ResultRecipient.Add();
			FillPropertyValues(NewRecipient, Recipient,,PropertiesOfBoxAreApplicable);
			NewRecipient.AmountARAP = AmountRecipient;
			NewRecipient.SumCompl = SumCompl;
			NewRecipient.SumMan = SumMan;
			If AmountsOfReglUprAreIndicatedInDocument Then
				IDRecipient = FindRowId(NewRecipient, CustomersARAPAccounting, VendorsARAPAccounting);
				If Not ValueIsFilled(IDRecipient) Then
					IDRecipient = New UUID;
				EndIf;
			EndIf;
			NewRecipient.RowID = IDRecipient;
			NewRecipient.CorIdOfLine = NewSender.RowID;
			
			NewRecipient.ByDataOfSourceARAPObject = False;
			If Not AmountsOfReglUprAreIndicatedInDocument Then
				If ValueIsFilled(ARAPObjectIntercompany) Then
					NewRecipient.PartnerReceiver = OurEnterprise;
					// To comply with the double entry when transmitting between
					// organizations, the organization of the source must be equal to the organization of the receiver
					If Recipient.Organization = Recipient.IntercampanyMirroredCompany Then
						NewRecipient.CalculationObjectReceiver = Recipient.ARAPObjectIntercompanyMirrored;
						NewRecipient.ARAPObjectIsMirrorReceiver = Recipient.ARAPObjectIntercompany;
					Else
						NewRecipient.CalculationObjectReceiver = Recipient.ARAPObjectIntercompany;
						NewRecipient.ARAPObjectIsMirrorReceiver = Recipient.ARAPObjectIntercompanyMirrored;
					EndIf;
					NewRecipient.CurrencyReceiver = Recipient.ARAPCurrency;
					NewRecipient.AmountReceiver = AmountSender;
				Else
					NewRecipient.ByDataOfSourceARAPObject = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	#Region AdjustmentOfCurrencyAmounts
	AdjustmentOfCurrencyAmounts(SenderOfDebt, ResultSender);
	AdjustmentOfCurrencyAmounts(RecipientOfDebt, ResultRecipient);
	#EndRegion
	
	RequestTT = New Query;
	RequestTT.TempTablesManager = Query.TempTablesManager;
	#Region TempTablesQueryText
	RequestTT.Text =
	"SELECT
	|	AccountsReceivable.Ref AS Ref,
	|	AccountsReceivable.OperationKind AS OperationKind,
	|	AccountsReceivable.LineNumber AS LineNumber,
	|	AccountsReceivable.PaymentType_ AS PaymentType_,
	|	AccountsReceivable.Partner AS Partner,
	|	AccountsReceivable.Sum AS Sum,
	|	AccountsReceivable.AmountARAP AS AmountARAP,
	|	AccountsReceivable.ARAPCurrency AS ARAPCurrency,
	|	AccountsReceivable.SumCompl AS SumCompl,
	|	AccountsReceivable.SumMan AS SumMan,
	|	AccountsReceivable.ARAPObject AS ARAPObject,
	|	AccountsReceivable.LineOfBusiness AS LineOfBusiness,
	|	AccountsReceivable.ARAPObjectMirror AS ARAPObjectMirror,
	|	AccountsReceivable.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	AccountsReceivable.CurrencyReceiver AS CurrencyReceiver,
	|	AccountsReceivable.AmountReceiver AS AmountReceiver,
	|	AccountsReceivable.PartnerReceiver AS PartnerReceiver,
	|	AccountsReceivable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	AccountsReceivable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	AccountsReceivable.Organization AS Organization,
	|	AccountsReceivable.RowID AS RowID,
	|	AccountsReceivable.CorIdOfLine AS CorIdOfLine,
	|	AccountsReceivable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|INTO TableReceivables
	|FROM
	|	&AccountsReceivable AS AccountsReceivable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountsPayable.Ref AS Ref,
	|	AccountsPayable.OperationKind AS OperationKind,
	|	AccountsPayable.LineNumber AS LineNumber,
	|	AccountsPayable.PaymentType_ AS PaymentType_,
	|	AccountsPayable.Partner AS Partner,
	|	AccountsPayable.Sum AS Sum,
	|	AccountsPayable.AmountARAP AS AmountARAP,
	|	AccountsPayable.ARAPCurrency AS ARAPCurrency,
	|	AccountsPayable.SumCompl AS SumCompl,
	|	AccountsPayable.SumMan AS SumMan,
	|	AccountsPayable.ARAPObject AS ARAPObject,
	|	AccountsPayable.LineOfBusiness AS LineOfBusiness,
	|	AccountsPayable.ARAPObjectMirror AS ARAPObjectMirror,
	|	AccountsPayable.CalculationObjectReceiver AS CalculationObjectReceiver,
	|	AccountsPayable.CurrencyReceiver AS CurrencyReceiver,
	|	AccountsPayable.AmountReceiver AS AmountReceiver,
	|	AccountsPayable.PartnerReceiver AS PartnerReceiver,
	|	AccountsPayable.ByDataOfSourceARAPObject AS ByDataOfSourceARAPObject,
	|	AccountsPayable.ARAPObjectIsMirrorReceiver AS ARAPObjectIsMirrorReceiver,
	|	AccountsPayable.Organization AS Organization,
	|	AccountsPayable.RowID AS RowID,
	|	AccountsPayable.CorIdOfLine AS CorIdOfLine,
	|	AccountsPayable.TransferOfCounterpartyDebtBetweenCompanies AS TransferOfCounterpartyDebtBetweenCompanies
	|INTO TablePayables
	|FROM
	|	&AccountsPayable AS AccountsPayable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AccountsReceivable.Ref AS Ref,
	|	AccountsReceivable.LineNumber AS LineNumber,
	|	AccountsReceivable.ARAPObject AS ARAPObject,
	|	AccountsReceivable.RowID AS RowID
	|INTO TTStringCalculationObjects
	|FROM
	|	TableReceivables AS AccountsReceivable
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	AccountsPayable.Ref AS Ref,
	|	AccountsPayable.LineNumber AS LineNumber,
	|	AccountsPayable.ARAPObject AS ARAPObject,
	|	AccountsPayable.RowID AS RowID
	|FROM
	|	TablePayables AS AccountsPayable";
	#EndRegion
	
	RequestTT.SetParameter("AccountsReceivable",ResultSender);
	RequestTT.SetParameter("AccountsPayable",ResultRecipient);
	If SenderCredit(Query.Parameters.OperationKind) Then
		RequestTT.SetParameter("AccountsReceivable",ResultRecipient);
		RequestTT.SetParameter("AccountsPayable",ResultSender);
	EndIf;
	
	RequestTT.Execute();
	
EndProcedure

Procedure AdjustmentOfCurrencyAmounts(DebtTable,AllocationResult)
	
	SearchFields = "ARAPObject,Organization,Counterparty,Partner,ARAPCurrency";
	DebtTotal = DebtTable.Copy();
	DebtTotal.GroupBy(SearchFields,"InitialSettlementAmount");
	For Each Debt_ In DebtTotal Do
		Filter = New Structure(SearchFields);
		FillPropertyValues(Filter,Debt_);
		FoundRows = AllocationResult.FindRows(Filter);
		AmountARAP = 0;
		MaximumAmount = 0;
		RowWithMaximumAmount = Undefined;
		For Each Allocated In FoundRows Do
			AmountARAP = AmountARAP + Allocated.AmountARAP;
			If Allocated.AmountARAP > MaximumAmount Then
				MaximumAmount = Allocated.AmountARAP;
				RowWithMaximumAmount = Allocated;
			EndIf;
		EndDo;
		If RowWithMaximumAmount <> Undefined And Debt_.InitialSettlementAmount <> AmountARAP Then
			Adjusting = Debt_.InitialSettlementAmount - AmountARAP;
			RowWithMaximumAmount.AmountARAP = RowWithMaximumAmount.AmountARAP + Adjusting;
			If RowWithMaximumAmount.AmountReceiver <> 0 Then
				RowWithMaximumAmount.AmountReceiver = RowWithMaximumAmount.AmountARAP;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function FindRowId(OffsettingParticipant, CustomersARAPAccounting, VendorsARAPAccounting)
	
	SearchFields = "Organization,Counterparty,Partner,ARAPObject,ARAPCurrency,SumCompl,Check";
	Filter = New Structure(SearchFields);
	FillPropertyValues(Filter, OffsettingParticipant);
	Filter.Check = False;
	
	If CustomersARAPAccounting.Count() > 0 Then
		FoundRows = CustomersARAPAccounting.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			FoundRows[0].Check = True;
			Return FoundRows[0].FinRecordID;
		EndIf;
	EndIf;
	
	If VendorsARAPAccounting.Count() Then
		FoundRows = VendorsARAPAccounting.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			FoundRows[0].Check = True;
			Return FoundRows[0].FinRecordID;
		EndIf;
	EndIf;
	
	Return New UUID;
	
EndFunction

Function AmountARAP(TotalInCurrency, SumCompl)
	
	AmountARAP = TotalInCurrency.AmountARAP;
	AmountOfLocalSettlements = TotalInCurrency.SumCompl;
	
	AmountToBeDebited_ = ARAPAccountingServer.WriteOffAmountProportionally(AmountARAP, SumCompl, AmountOfLocalSettlements);
	
	TotalInCurrency.AmountARAP = TotalInCurrency.AmountARAP - AmountToBeDebited_;
	TotalInCurrency.SumCompl = TotalInCurrency.SumCompl - SumCompl;
	
	Return AmountToBeDebited_;
	
EndFunction

Function TotalInAccountingCurrencies(Debt_)
	
	Result = New Map;
	TotalDebt_ = Debt_.Copy();
	AmountNames = "AmountARAP,SumMan,SumCompl";
	TotalDebt_.GroupBy("ARAPCurrency",AmountNames);
	For Each Record In TotalDebt_ Do
		AccountingAmounts = New Structure(AmountNames,0,0,0);
		FillPropertyValues(AccountingAmounts,Record);
		Result.Insert(Record.ARAPCurrency,AccountingAmounts);
	EndDo;
	Return Result;
	
EndFunction

Function SenderCredit(OperationKind)
	
	Return
		OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty
			Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
			Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
			Or OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
			Or OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard
			Or OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
			Or OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties
			Or OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany
			Or OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies
			Or OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ARAPSettlementLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array of DocumentRef- references to the objects that you want to print.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList of DocumentRef - value - the object reference;
//                                            view - name of the area where the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
//@skip-check doc-comment-description-ends-on-dot
//@skip-check module-empty-method
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	ARAPSettlementLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

// Get print data.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef
//  TemplatesNamesArray - Array of String
// 
// Returns:
//  Structure - Get Print Data:
// * Data - See GetObjectDataByTemplate
// * Templates - See GetTemplatesAndSectionDescriptions
Function GetPrintInfo(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	SetPrivilegedMode(True);
	
	Structure = New Structure("Data, Templates",
		GetObjectDataByTemplate(DocumentsArray, TemplatesNamesArray),
		GetTemplatesAndSectionDescriptions(TemplatesNamesArray));
				
	Return Structure;
	
EndFunction

// Get object data from Templates.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef
//  TemplatesNamesArray - Array of String
// 
// Returns:
//  Map of KeyAndValue - Get Object Data By Template:
//  * Key - DocumentRef
//  * Value - Structure - Object Data By Template: 
//  	** Key - String - layout name
//  	** Value - Structure - Data of the document Attributes for the Template:
//  		*** Key - String - The name of the props
//  		*** Value - Arbitrary
Function GetObjectDataByTemplate(Val DocumentsArray, Val TemplatesNamesArray) Export
	
	DataByAllObjects = New Map;
	
	ResultsArray = GetDebtOffsetData(DocumentsArray);
	
	Selection = ResultsArray[0].Select();
	SampleAccountsReceivable = ResultsArray[1].Select(QueryResultIteration.ByGroups);
	SampleAccountsPayable = ResultsArray[2].Select(QueryResultIteration.ByGroups);
	
	While Selection.Next() Do
	
		ObjectData = New Structure;
		ObjectData.Insert("Organization",                               Selection.Organization);
		ObjectData.Insert("JobTitleExecutive",                     Selection.JobTitleExecutive);
		ObjectData.Insert("Director",                              Selection.Director);
		ObjectData.Insert("CompanyCreditor",                       Selection.CompanyCreditor);
		ObjectData.Insert("PositionOfHeadOfCreditorOrganization", Selection.PositionOfHeadOfCreditorOrganization);
		ObjectData.Insert("HeadOfLenderSOrganization",          Selection.HeadOfLenderSOrganization);
		ObjectData.Insert("Date",                                      Format(Selection.Date, "DLF=DD"));
		ObjectData.Insert("OrganizationAddress",                          PrintFormGeneration.GetAddressFromContactInformation(Selection.CompanyLink, "Legal", Selection.Date));
		ObjectData.Insert("AddressOfLenderSOrganization",                 PrintFormGeneration.GetAddressFromContactInformation(Selection.LenderOrganizationLink, "Legal", Selection.Date));
		ObjectData.Insert("SettlementOfARAP",                               Selection.SettlementOfARAP);
		ObjectData.Insert("NettingBetweenOrganizations",             Selection.NettingBetweenOrganizations);
		ObjectData.Insert("Sum", PrintFormGeneration.SumFormat(Selection.SumCompl, Selection.LocalAccountingCurrency));
		
		AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(Selection.SumCompl, Selection.LocalAccountingCurrency);
		ObjectData.Insert("AmountInWords", AmountInWords);

		ObjectData.Insert("AccountsReceivable", New Array);
		ObjectData.Insert("AccountsPayable", New Array);
		
		If TypeOf(Selection.CounterpartyDebtor) = Type("CatalogRef.Companies") Then
			ObjectData.Insert("CounterpartyDebtor",  Selection.CounterpartyDebtorCompany);
			AddressOfDebtorSCounterparty = PrintFormGeneration.GetAddressFromContactInformation(Selection.CounterpartyDebtor, "Legal", Selection.Date);
			ObjectData.Insert("AddressOfDebtorSCounterparty", AddressOfDebtorSCounterparty);
		Else
			ObjectData.Insert("CounterpartyDebtor",  Catalogs.Counterparties.AbbreviatedLegalEntityNameAsOfDate(Selection.CounterpartyDebtor, Selection.Date));
			AddressOfDebtorSCounterparty = ContactsManager.ObjectContactInformationPresentation(
				Selection.CounterpartyDebtor, Catalogs.ContactInformationKinds.LegalAddressOfCounterparty,, Selection.Date);
			ObjectData.Insert("AddressOfDebtorSCounterparty", AddressOfDebtorSCounterparty);
		EndIf;
		
		If TypeOf(Selection.Creditor) = Type("CatalogRef.Companies") Then
			ObjectData.Insert("Creditor",  Selection.CounterpartyCreditorCompany);
			AddressOfCreditorSCounterparty = PrintFormGeneration.GetAddressFromContactInformation(Selection.Creditor, "Legal", Selection.Date);
			ObjectData.Insert("AddressOfCreditorSCounterparty", AddressOfCreditorSCounterparty);
		Else
			ObjectData.Insert("Creditor",  Catalogs.Counterparties.AbbreviatedLegalEntityNameAsOfDate(Selection.Creditor, Selection.Date));
			AddressOfCreditorSCounterparty = ContactsManager.ObjectContactInformationPresentation(
				Selection.Creditor, Catalogs.ContactInformationKinds.LegalAddressOfCounterparty,, Selection.Date);
			ObjectData.Insert("AddressOfCreditorSCounterparty", AddressOfCreditorSCounterparty);
		EndIf;
		
		AddressOfLenderSOrganization = ContactsManager.ObjectContactInformationPresentation(
			Selection.Creditor, Catalogs.ContactInformationKinds.LegalAddressOfCounterparty,, Selection.Date);
		ObjectData.Insert("AddressOfLenderSOrganization", AddressOfLenderSOrganization);
		
		If SampleAccountsReceivable.FindNext(Selection.Ref, "Ref") Then 
			GenerateDebtTable(SampleAccountsReceivable, ObjectData.AccountsReceivable);
		EndIf;
		If SampleAccountsPayable.FindNext(Selection.Ref, "Ref") Then 
			GenerateDebtTable(SampleAccountsPayable, ObjectData.AccountsPayable);
		EndIf;

		ObjectDataByTemplates = New Structure;
		For Each TemplateName In TemplatesNamesArray Do
			ObjectDataByTemplates.Insert(TemplateName, ObjectData);
		EndDo;
		DataByAllObjects.Insert(Selection.Ref, ObjectDataByTemplates);
	EndDo;
	
	Return DataByAllObjects;
	
EndFunction

// Get Templates and section descriptions.
// 
// Parameters:
//  TemplatesNamesArray - Array of String - Array of Template names.
// 
// Returns:
//  Structure - Get Templates And Section Descriptions:
// 	* DescriptionOfSections - Structure of KeyAndValue -:
// 		** Key - String - name of the layout.
// 		** Value - Structure of KeyAndValue- Description of Template sections -:
// 			** Key - String - Name of the section.
// 			** Value - Structure of KeyAndValue - Section description:
// 				*** Key - String - Name of the section.
// 				*** Value - String - Type of section.
// 	* TemplatesBinaryData - Structure of KeyAndValue -:
// 		** Key - String - name of the layout.
// 		** Value - BinaryData - layout of the printed form.
//
Function GetTemplatesAndSectionDescriptions(Val TemplatesNamesArray) Export
	
	DescriptionOfSections = New Structure;
	TemplatesBinaryData = New Structure;
	
	For Each TemplateName In TemplatesNamesArray Do
		
		Template = Undefined;
		DescriptionOfTemplateSections = Undefined;
		
		If DescriptionOfTemplateSections <> Undefined And Template <> Undefined Then
			
			DescriptionOfSections.Insert(TemplateName, DescriptionOfTemplateSections);
			TemplatesBinaryData.Insert(TemplateName, Template);
			
		EndIf;
		
	EndDo;
	
	Result = New Structure("DescriptionOfSections, TemplatesBinaryData",
		DescriptionOfSections,
		TemplatesBinaryData);
	
	Return Result;
	
EndFunction

// Generates a table of debt.
// 
// Parameters:
// 	QueryResult - QueryResult - query result.
// 	RowsArray - Array of Structure - Variable array of strings
Procedure GenerateDebtTable(QueryResult, RowsArray)
	
	LineNumber = 0;
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		LineNumber = LineNumber + 1;
		TableRow = New Structure;
		TableRow.Insert("LineNumber", LineNumber);
		TableRow.Insert("Sum", Format(Selection.AmountARAP, "NFD=2"));
		TableRow.Insert("Currency", Selection.ARAPCurrency);
		
		TextDocument_ = "";
		If ValueIsFilled(Selection.NameForPrinting) Then
			TextDocument_ = Selection.NameForPrinting;
		ElsIf ValueIsFilled(Selection.DocumentType) Then
			TextDocument_ = TextDocument_
				+ ?(Not IsBlankString(TextDocument_), ", " + Chars.LF, "")
				+ TMCommonUseClientServer.GenerateDocumentTitle(Selection, String(Selection.DocumentType));
		EndIf;
		If IsBlankString(TextDocument_) Then
			TextDocument_ = NStr("vi = 'Không có chứng từ';
								|ru = 'Без документа';
								|en = 'Without document'; fa = 'Without document';
								|it = 'Senza documento';
								|pl = 'Bez dokumentu';
								|tr = 'Belge olmadan'", Common.DefaultLanguageCode());
		EndIf;
	
		TableRow.Insert("Document", TextDocument_);
		
		RowsArray.Add(TableRow);
		
	EndDo;
	
EndProcedure

// Parameters:
// 	DocumentsArray - Array of DocumentRef - array of documents.
// Returns:
// 	Array of QueryResult - 
Function GetDebtOffsetData(DocumentsArray)
	
	TempTablesManager = New TempTablesManager;
	
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(
		DocumentsArray,
		TempTablesManager);
	
	ParametersOfResponsiblePersons = ResponsiblePersonsServer.DefaultParametersOfResponsiblePersons();
	ParametersOfResponsiblePersons.CompanyAttributeName = "CompanyCreditor";
	ParametersOfResponsiblePersons.DetailsResponsiblePersons = New Structure("Director", Enums.PersonsResponsibleAndCompanies.Director);
	ParametersOfResponsiblePersons.TableNameResponsiblePersons = "TableResponsiblePersonsOfCreditorOrganization";
	
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(
		DocumentsArray,
		TempTablesManager,
		ParametersOfResponsiblePersons);
		
	Query = New Query("
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization.AbbreviatedDescription AS Organization,
	|	DocumentData.Organization AS CompanyLink,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	DocumentData.CompanyCreditor.AbbreviatedDescription AS CompanyCreditor,
	|	DocumentData.CompanyCreditor AS LenderOrganizationLink,
	|	TableResponsiblePersonsOfCreditorOrganization.DirectorDescription AS HeadOfLenderSOrganization,
	|	TableResponsiblePersonsOfCreditorOrganization.DirectorJobTitle AS PositionOfHeadOfCreditorOrganization,
	|	DocumentData.CounterpartyDebtor AS CounterpartyDebtor,
	|	DocumentData.Creditor AS Creditor,
	|	CASE WHEN DocumentData.CounterpartyDebtor REFS Catalog.Companies
	|		THEN DocumentData.CounterpartyDebtor.AbbreviatedDescription
	|		ELSE """"
	|	END AS CounterpartyDebtorCompany,
	|	CASE WHEN DocumentData.Creditor REFS Catalog.Companies
	|		THEN DocumentData.Creditor.AbbreviatedDescription
	|		ELSE """"
	|	END AS CounterpartyCreditorCompany,
	|	CASE WHEN ((NOT (DocumentData.OperationKind IN (&TypesOfTransactionsBetweenOrganizations)) AND DocumentData.CounterpartyDebtor = DocumentData.Creditor)
	|					OR (DocumentData.OperationKind IN (&TypesOfTransactionsBetweenOrganizations) AND DocumentData.Organization = DocumentData.CompanyCreditor))
	|				AND NOT DocumentData.OperationKind IN (&TypesOfCommissionOfOperations)
	|				OR DocumentData.OperationKind = &ArbitrarySettlement THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS SettlementOfARAP,
	|	CASE WHEN DocumentData.OperationKind IN (&TypesOfTransactionsBetweenOrganizations) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS NettingBetweenOrganizations,
	|	DocumentData.SumCompl AS SumCompl
	|FROM
	|	Document.ARAPSettlement AS DocumentData
	|
	|	LEFT JOIN
	|		TableResponsiblePersons AS TableResponsiblePersons
	|	ON
	|		DocumentData.Ref = TableResponsiblePersons.Ref
	|
	|	LEFT JOIN
	|		TableResponsiblePersonsOfCreditorOrganization AS TableResponsiblePersonsOfCreditorOrganization
	|	ON
	|		DocumentData.Ref = TableResponsiblePersonsOfCreditorOrganization.Ref
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Debt_.Ref AS Ref,
	|	Debt_.PaymentType_ AS PaymentType_,
	|	CASE WHEN Debt_.ARAPObject.Object = UNDEFINED THEN
	|		UNDEFINED
	|	ELSE
	|		VALUETYPE(Debt_.ARAPObject.Object)
	|	END AS DocumentType,
	|	Debt_.ARAPObject.Date AS Date,
	|	Debt_.ARAPObject.Number AS Number,
	|	CASE WHEN VALUETYPE(Debt_.ARAPObject.Object) = TYPE(Catalog.CounterpartyContracts) THEN
	|		CAST(Debt_.ARAPObject.Object AS Catalog.CounterpartyContracts).NameForPrinting
	|			WHEN VALUETYPE(Debt_.ARAPObject.Object) = TYPE(Catalog.IntercompanyContracts) THEN
	|		CAST(Debt_.ARAPObject.Object AS Catalog.IntercompanyContracts).NameForPrinting
	|	ELSE
	|		UNDEFINED
	|	END AS NameForPrinting,
	|	Debt_.AmountARAP AS AmountARAP,
	|	Debt_.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.ARAPSettlement.AccountsReceivable AS Debt_
	|WHERE
	|	Debt_.Ref IN (&DocumentsArray)
	|
	|TOTALS BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Debt_.Ref AS Ref,
	|	Debt_.PaymentType_ AS PaymentType_,
	|	CASE WHEN Debt_.ARAPObject.Object = UNDEFINED THEN
	|		UNDEFINED
	|	ELSE
	|		VALUETYPE(Debt_.ARAPObject.Object)
	|	END AS DocumentType,
	|	Debt_.ARAPObject.Date AS Date,
	|	Debt_.ARAPObject.Number AS Number,
	|	CASE WHEN VALUETYPE(Debt_.ARAPObject.Object) = TYPE(Catalog.CounterpartyContracts) THEN
	|		CAST(Debt_.ARAPObject.Object AS Catalog.CounterpartyContracts).NameForPrinting
	|			WHEN VALUETYPE(Debt_.ARAPObject.Object) = TYPE(Catalog.IntercompanyContracts) THEN
	|		CAST(Debt_.ARAPObject.Object AS Catalog.IntercompanyContracts).NameForPrinting
	|	ELSE
	|		UNDEFINED
	|	END AS NameForPrinting,
	|	Debt_.AmountARAP AS AmountARAP,
	|	Debt_.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.ARAPSettlement.AccountsPayable AS Debt_
	|WHERE
	|	Debt_.Ref IN (&DocumentsArray)
	|
	|TOTALS BY
	|	Ref
	|");
	
	OperationArray = New Array;
	OperationArray.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany);
	OperationArray.Add(Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany);
	OperationArray.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany);
	OperationArray.Add(Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany);
	
	OFOperationsOfCommissionAgent = New Array;
	OFOperationsOfCommissionAgent.Add(Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent);
	OFOperationsOfCommissionAgent.Add(Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent);
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("TypesOfTransactionsBetweenOrganizations", OperationArray);
	Query.SetParameter("TypesOfCommissionOfOperations", OFOperationsOfCommissionAgent);
	Query.SetParameter("ArbitrarySettlement", Enums.KindsOfARAPSettlements.Arbitrary);
	Query.TempTablesManager = TempTablesManager;
	
	ResultsArray = Query.ExecuteBatch();
		
	Return ResultsArray;

EndFunction

// Parameters:
// 	PrintObjectDataStructure - Structure - consists of:
// * PrimaryRecipient - String -
// * ArrayOfRecipientDetails - Array of String -
// * DataArray - Array of DocumentRef -
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "CounterpartyDebtor";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CounterpartyDebtor");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Creditor");
	
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

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.ARAPSettlement.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.32";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("d307c19a-eb0b-4bc4-830d-1e2280e401b6");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.ARAPSettlement.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Hạch toán công nợ"":';
								|ru = 'Обновление документов ""Взаимозачет задолженности"":';
								|en = 'Update the ""AR/AP offset"" documents:'; fa = 'Update the ""AR/AP offset"" documents:';
								|it = 'Update the ""AR/AP offset"" documents:';
								|pl = 'Update the ""AR/AP offset"" documents:';
								|tr = '""Alacak/Borç mahsubu"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Mảng hoạt động"" đối với giao dịch ""Đối trừ tùy ý"".';
								|ru = '- заполнение реквизита ""Направление деятельности"" для операций ""Произвольный взаимозачет"".';
								|en = '- Fill in the ""Line of business"" attribute for ""Arbitrary offset"" transactions.'; fa = '- Fill in the ""Line of business"" attribute for ""Arbitrary offset"" transactions.';
								|it = '- Fill in the ""Line of business"" attribute for ""Arbitrary offset"" transactions.';
								|pl = '- Fill in the ""Line of business"" attribute for ""Arbitrary offset"" transactions.';
								|tr = '- ""İsteğe bağlı mahsup"" işlemleri için ""İş kolu"" özniteliğinin doldurulması.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.ARAPSettlement.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.ARAPSettlement.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers documents for processing for modification.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	TSAccountsReceivable.Ref AS Ref
	|FROM
	|	Document.ARAPSettlement.AccountsReceivable AS TSAccountsReceivable
	|		INNER JOIN Document.ARAPSettlement AS HeaderAttributes
	|		ON TSAccountsReceivable.Ref = HeaderAttributes.Ref
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TSAccountsReceivable.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	HeaderAttributes.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
	|	AND TSAccountsReceivable.LineOfBusiness <> ARAPObjects.LineOfBusiness
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TSAccountsPayable.Ref AS Ref
	|FROM
	|	Document.ARAPSettlement.AccountsPayable AS TSAccountsPayable
	|		INNER JOIN Document.ARAPSettlement AS HeaderAttributes
	|		ON TSAccountsPayable.Ref = HeaderAttributes.Ref
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TSAccountsPayable.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	HeaderAttributes.OperationKind = VALUE(Enum.KindsOfARAPSettlements.Arbitrary)
	|	AND TSAccountsPayable.LineOfBusiness <> ARAPObjects.LineOfBusiness
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
		
EndProcedure

// The update handler
//
// Parameters:
//	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName	= EmptyRef().Metadata().FullName();
	UpdatedData	= InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array;
	
	For Each DataString1 In UpdatedData Do
		
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", DataString1.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			DocumentObject = DataString1.Ref.GetObject();
			If DocumentObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(DataString1.Ref);
				CommitTransaction();
				Continue;
			EndIf; 
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Kết chuyển lại chứng từ thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			// Filling in the line of business of operation Arbitrary settlement
			If DocumentObject.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary Then
				ArrayOfCalculationObjects_ = DocumentObject.AccountsReceivable.UnloadColumn("ARAPObject");
				CommonClientServer.SupplementArray(ArrayOfCalculationObjects_, DocumentObject.AccountsPayable.UnloadColumn("ARAPObject"));
				MatchingDirections = Common.ObjectsAttributeValue(ArrayOfCalculationObjects_, "LineOfBusiness");
				
				For Each Page1 In DocumentObject.AccountsReceivable Do
					If ValueIsFilled(Page1.ARAPObject) And Page1.LineOfBusiness <> MatchingDirections[Page1.ARAPObject] Then
						Page1.LineOfBusiness = MatchingDirections[Page1.ARAPObject];
					EndIf;
				EndDo;
				
				For Each Page1 In DocumentObject.AccountsPayable Do
					If ValueIsFilled(Page1.ARAPObject) And Page1.LineOfBusiness <> MatchingDirections[Page1.ARAPObject] Then
						Page1.LineOfBusiness = MatchingDirections[Page1.ARAPObject];
					EndIf;
				EndDo;
			EndIf;
			
			ExceptionReason = "Record";
			
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(DataString1.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), DataString1.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					DataString1.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(NStr("vi = 'Không thể xử lý chứng từ ""Đối trừ công nợ"".';
									|ru = 'Не удалось обработать документ ""Взаимозачет задолженности"".';
									|en = 'Cannot process the ""AR/AP offset"" document.'; fa = 'Cannot process the ""AR/AP offset"" document.';
									|it = 'Cannot process the ""AR/AP offset"" document.';
									|pl = 'Cannot process the ""AR/AP offset"" document.';
									|tr = '""Alacak/Borç mahsubu"" belgesi işlenemedi.'"), Chars.LF);
				
			EndIf;
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
