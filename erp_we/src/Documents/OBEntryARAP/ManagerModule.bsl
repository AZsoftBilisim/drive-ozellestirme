#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export
	
	DateOfRemainingGoods = New Boundary(EndOfDay(Date), BoundaryType.Including);
	Return BalancesOnSettlementsWithPartners(DateOfRemainingGoods, BusinessOperation, Companies);
	
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyFieldsArray = New Array;
	KeyFieldsArray.Add("Organization");
	
	Return KeyFieldsArray;
	
EndFunction

#EndRegion
#Region Posting

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * Table_RegisterName - ValueTable - the data table to be reflected in the register (instead of the _register name, the name of the register itself is substituted).
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryARAP") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// Create a motion initialization request
	
	Query = New Query;
	FillInInitializationParameters(Query, DocumentRef);
	
	////////////////////////////////////////////////////////////////////////////
	// Let's form the request text
	
	QueryTexts = New ValueList;
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers);
	QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers);
	If Document.BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable Then
		CurrentAccountingPolicySettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy", Document.Organization, Document.Date);
		Discount_ = CurrentAccountingPolicySettings.AccountingForDiscountedAccountsPayableToVendors;
		If Discount_ Then
			QueryTextTableDiscountInterestExpense(Query, QueryTexts, Registers);
		EndIf;
	EndIf;
	OBEntryLocalization.EnteringAccountBalancesAddRequestTexts(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringSettlementBalancesAndAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

#Region GenerateFrom

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
	
	OBEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	OBEntryLocalization.EnteringSettlementBalancesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//  String - Containing the text of the request to be reflected in the registration.
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOfSettlementsForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringSettlementBalancesRequestTextTTReflectedInLocalAccounting();
EndFunction

#EndRegion
#Region InterfaceImplementation

// Adds a command to create a document based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryARAP);
	
EndFunction

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization) ";

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

// List of types of the type-selection AR/AP object for the type-selection form available to the current user for creation
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - the Operation of entering the Balance of calculations.
//  TheseAreSettlementsBetweenOrganizations - Boolean
//  ThisIsRetailBuyer - Boolean
// 
// Returns:
//  ValueList of String - The List Of Available Types Of AR/AP Object
Function ListOfAvailableTypesOfARAPObject(BusinessOperation, TheseAreSettlementsBetweenOrganizations, ThisIsRetailBuyer) Export
	
	TypesList = New ValueList;
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer Then
	
		If TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Catalogs.IntercompanyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.IntercompanyContracts.FullName(),
				NStr("vi = 'Hợp đồng giữa các doanh nghiệp';
					|ru = 'Договор между организациями';
					|en = 'Intercompany contract'; fa = 'قرارداد بین‌شرکتی';
					|it = 'Accordo tra le società';
					|pl = 'Kontrakt między firmami';
					|tr = 'Şirketler arası sözleşme'"));
		ElsIf GetFunctionalOption("UseCustomerContracts")
			And AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.CounterpartyContracts.FullName(),
				NStr("vi = 'Hợp đồng với đối tác';
					|ru = 'Договор с контрагентом';
					|en = 'Contract'; fa = 'قرارداد';
					|it = 'Contratto con la controparte';
					|pl = 'Umowa z kontrahentem';
					|tr = 'Cari hesap sözleşmesi'"));
		EndIf;
		If GetFunctionalOption("UseSalesOrders")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.SalesOrder) Then
			TypesList.Add(
				Metadata.Documents.SalesOrder.FullName(),
				NStr("vi = 'Đơn hàng của khách';
					|ru = 'Заказ клиента';
					|en = 'Sales order'; fa = 'سفارش فروش';
					|it = 'Ordine del cliente';
					|pl = 'Zamówienie klienta';
					|tr = 'Satış siparişi'"));
		EndIf;
		If GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
			TypesList.Add(
				Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName(),
				NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
					|ru = 'Заявка на возврат товаров от клиента';
					|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
					|it = 'Richiesta di reso della merce dal cliente';
					|pl = 'Wniosek o zwrot towarów od klienta';
					|tr = 'Satış iadesi talebi'"));
		EndIf;
		
		If GetFunctionalOption("UseMaterialProviderOrder2_5")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.MaterialProviderOrder2_5) Then
			TypesList.Add(
				Metadata.Documents.MaterialProviderOrder2_5.FullName(),
				NStr("vi = 'Đơn hàng của bên đặt gia công';
					|ru = 'Заказ давальца';
					|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
					|it = 'Ordine del committente';
					|pl = 'Zamówienie dostawcy';
					|tr = 'Tedarikçi siparişi'"));
		EndIf;
		If AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			TypesList.Add(
				New Structure("MetadataObjectName, SourceDocumentType",
					Metadata.Documents.SourceDocument.FullName(),
					Enums.SourceDocumentTypes.PaymentFromCustomer),
				NStr("vi = 'Thanh toán từ khách hàng';
					|ru = 'Оплата от клиента';
					|en = 'Payment from customer'; fa = 'دریافت از مشتری';
					|it = 'Pagamento dal cliente';
					|pl = 'Płatność od klienta';
					|tr = 'Müşteriden gelen ödeme'"));
		EndIf;
		If GetFunctionalOption("UseGiftCards")
				And ThisIsRetailBuyer
			And AccessRight("Insert", Metadata.Catalogs.GiftCertificates) Then
			TypesList.Add(
				Metadata.Catalogs.GiftCertificates.FullName(),
				NStr("vi = 'Phiếu quà tặng';
					|ru = 'Подарочный сертификат';
					|en = 'Gift card'; fa = 'کارت هدیه';
					|it = 'Buono regalo';
					|pl = 'Certyfikat podarunkowy';
					|tr = 'Hediye kartı'"));
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		
		If TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Catalogs.IntercompanyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.IntercompanyContracts.FullName(),
				NStr("vi = 'Hợp đồng giữa các doanh nghiệp';
					|ru = 'Договор между организациями';
					|en = 'Intercompany contract'; fa = 'قرارداد بین‌شرکتی';
					|it = 'Accordo tra le società';
					|pl = 'Kontrakt między firmami';
					|tr = 'Şirketler arası sözleşme'"));
		ElsIf GetFunctionalOption("UseContractsWithVendors")
			And AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.CounterpartyContracts.FullName(),
				NStr("vi = 'Hợp đồng với đối tác';
					|ru = 'Договор с контрагентом';
					|en = 'Contract'; fa = 'قرارداد';
					|it = 'Contratto con la controparte';
					|pl = 'Umowa z kontrahentem';
					|tr = 'Cari hesap sözleşmesi'"));
		EndIf;
		If GetFunctionalOption("UsePurchaseOrders")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.PurchaseOrder) Then
			TypesList.Add(
				Metadata.Documents.PurchaseOrder.FullName(),
				NStr("vi = 'Đơn hàng đặt nhà cung cấp';
					|ru = 'Заказ поставщику';
					|en = 'Purchase order'; fa = 'سفارش خرید';
					|it = 'Ordine al fornitore';
					|pl = 'Zamówienie do dostawcy';
					|tr = 'Satın alma siparişi'"));
		EndIf;
		If GetFunctionalOption("UseProductionByThirdParty2_5")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.SubcontractOrder2_5) Then
			TypesList.Add(
				Metadata.Documents.SubcontractOrder2_5.FullName(),
				NStr("vi = 'Đơn đặt hàng gia công';
					|ru = 'Заказ переработчику';
					|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
					|it = 'Ordine al subfornitore';
					|pl = 'Zamówienie do przetwórcy';
					|tr = 'Fason satın alma siparişi '"));
		EndIf;
		If AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			TypesList.Add(
				New Structure("MetadataObjectName, SourceDocumentType",
					Metadata.Documents.SourceDocument.FullName(),
					Enums.SourceDocumentTypes.PaymentToVendor),
				NStr("vi = 'Trả tiền cho nhà cung cấp';
					|ru = 'Оплата поставщику';
					|en = 'Payment to vendor'; fa = 'پرداخت به تأمین‌کننده';
					|it = 'Pagamento al fornitore';
					|pl = 'Płatność dla dostawcy';
					|tr = 'Tedarikçiye ödeme'"));
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable Then
		
		If TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Catalogs.IntercompanyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.IntercompanyContracts.FullName(),
				NStr("vi = 'Hợp đồng giữa các doanh nghiệp';
					|ru = 'Договор между организациями';
					|en = 'Intercompany contract'; fa = 'قرارداد بین‌شرکتی';
					|it = 'Accordo tra le società';
					|pl = 'Kontrakt między firmami';
					|tr = 'Şirketler arası sözleşme'"));
		ElsIf GetFunctionalOption("UseCustomerContracts")
			And AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.CounterpartyContracts.FullName(),
				NStr("vi = 'Hợp đồng với đối tác';
					|ru = 'Договор с контрагентом';
					|en = 'Contract'; fa = 'قرارداد';
					|it = 'Contratto con la controparte';
					|pl = 'Umowa z kontrahentem';
					|tr = 'Cari hesap sözleşmesi'"));
		EndIf;
		If GetFunctionalOption("UseSalesOrders")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.SalesOrder) Then
			TypesList.Add(
				Metadata.Documents.SalesOrder.FullName(),
				NStr("vi = 'Đơn hàng của khách';
					|ru = 'Заказ клиента';
					|en = 'Sales order'; fa = 'سفارش فروش';
					|it = 'Ordine del cliente';
					|pl = 'Zamówienie klienta';
					|tr = 'Satış siparişi'"));
		EndIf;
		If GetFunctionalOption("UseRequestsForReturnOfGoodsFromCustomers")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.RequestForReturnOfGoodsFromCustomer) Then
			TypesList.Add(
				Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName(),
				NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
					|ru = 'Заявка на возврат товаров от клиента';
					|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
					|it = 'Richiesta di reso della merce dal cliente';
					|pl = 'Wniosek o zwrot towarów od klienta';
					|tr = 'Satış iadesi talebi'"));
		EndIf;
		
		If GetFunctionalOption("UseMaterialProviderOrder2_5")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.MaterialProviderOrder2_5) Then
			TypesList.Add(
				Metadata.Documents.MaterialProviderOrder2_5.FullName(),
				NStr("vi = 'Đơn hàng của bên đặt gia công';
					|ru = 'Заказ давальца';
					|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
					|it = 'Ordine del committente';
					|pl = 'Zamówienie dostawcy';
					|tr = 'Tedarikçi siparişi'"));
		EndIf;
		If AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			TypesList.Add(
				New Structure("MetadataObjectName, SourceDocumentType",
					Metadata.Documents.SourceDocument.FullName(),
					Enums.SourceDocumentTypes.SaleToCustomer),
				NStr("vi = 'Bán hàng cho khách';
					|ru = 'Реализация клиенту';
					|en = 'Customer sales'; fa = 'فروش به مشتری';
					|it = 'Vendita al cliente';
					|pl = 'Sprzedaż klientowi';
					|tr = 'Müşteriye satış'"));
		EndIf;
		If GetFunctionalOption("UseMaterialProviderOrder2_5")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			TypesList.Add(
				New Structure("MetadataObjectName, SourceDocumentType",
					Metadata.Documents.SourceDocument.FullName(),
					Enums.SourceDocumentTypes.ReportToMaterialProvider),
				NStr("vi = 'Bảng kê dành cho bên đặt gia công';
					|ru = 'Отчет давальцу';
					|en = 'Consumption report — Subcontracting services delivered'; fa = 'گزارش مصرف — خدمات پیمانکاری فرعی ارائه‌شده';
					|it = 'Report al committente di materie prime';
					|pl = 'Raport dla właściciela surowców';
					|tr = 'Tüketim raporu-Verilen fason hizmetleri'"));
		EndIf;
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable Then
		
		If TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Catalogs.IntercompanyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.IntercompanyContracts.FullName(),
				NStr("vi = 'Hợp đồng giữa các doanh nghiệp';
					|ru = 'Договор между организациями';
					|en = 'Intercompany contract'; fa = 'قرارداد بین‌شرکتی';
					|it = 'Accordo tra le società';
					|pl = 'Kontrakt między firmami';
					|tr = 'Şirketler arası sözleşme'"));
		ElsIf GetFunctionalOption("UseContractsWithVendors")
			And AccessRight("Insert", Metadata.Catalogs.CounterpartyContracts) Then
			TypesList.Add(
				Metadata.Catalogs.CounterpartyContracts.FullName(),
				NStr("vi = 'Hợp đồng với đối tác';
					|ru = 'Договор с контрагентом';
					|en = 'Contract'; fa = 'قرارداد';
					|it = 'Contratto con la controparte';
					|pl = 'Umowa z kontrahentem';
					|tr = 'Cari hesap sözleşmesi'"));
		EndIf;
		If GetFunctionalOption("UsePurchaseOrders")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.PurchaseOrder) Then
			TypesList.Add(
				Metadata.Documents.PurchaseOrder.FullName(),
				NStr("vi = 'Đơn hàng đặt nhà cung cấp';
					|ru = 'Заказ поставщику';
					|en = 'Purchase order'; fa = 'سفارش خرید';
					|it = 'Ordine al fornitore';
					|pl = 'Zamówienie do dostawcy';
					|tr = 'Satın alma siparişi'"));
		EndIf;
		If GetFunctionalOption("UseProductionByThirdParty2_5")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.SubcontractOrder2_5) Then
			TypesList.Add(
				Metadata.Documents.SubcontractOrder2_5.FullName(),
				NStr("vi = 'Đơn đặt hàng gia công';
					|ru = 'Заказ переработчику';
					|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
					|it = 'Ordine al subfornitore';
					|pl = 'Zamówienie do przetwórcy';
					|tr = 'Fason satın alma siparişi '"));
		EndIf;
		If AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			TypesList.Add(
				New Structure("MetadataObjectName, SourceDocumentType",
					Metadata.Documents.SourceDocument.FullName(),
					Enums.SourceDocumentTypes.PurchaseFromVendor),
				NStr("vi = 'Mua hàng của nhà cung cấp';
					|ru = 'Приобретение у поставщика';
					|en = 'Purchase from vendor'; fa = 'خرید از تأمین‌کننده';
					|it = 'Acquisto dal fornitore';
					|pl = 'Zakup u dostawcy';
					|tr = 'Tedarikçiden satın alma'"));
		EndIf;
		If GetFunctionalOption("UseProductionByThirdParty2_5")
			And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			TypesList.Add(
				New Structure("MetadataObjectName, SourceDocumentType",
					Metadata.Documents.SourceDocument.FullName(),
					Enums.SourceDocumentTypes.SubcontractorReport),
				NStr("vi = 'Bảng kê hàng hóa của bên nhận gia công';
					|ru = 'Отчет переработчика';
					|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
					|it = 'Report subfornitore';
					|pl = 'Raport przetwórcy';
					|tr = 'Fason üretici bildirimi'"));
		EndIf;
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerBonuses Then
		
		If AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			
			TypeName = NStr("vi = 'Thông báo thưởng cho khách hàng';
							|ru = 'Акт премии клиенту';
							|en = 'Customer bonus certificate'; fa = 'گواهی پاداش مشتری';
							|it = 'Акт премии клиенту';
							|pl = 'Customer bonus certificate';
							|tr = 'TİS müşteriye ödül verilmesi'");
			
			TypeStructure = New Structure;
			TypeStructure.Insert("MetadataObjectName", Metadata.Documents.SourceDocument.FullName());
			TypeStructure.Insert("SourceDocumentType", Enums.SourceDocumentTypes.CustomerBonusCertificate);
			
			TypesList.Add(
				TypeStructure,
				TypeName);
			
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryVendorBonuses Then
		
		If AccessRight("Insert", Metadata.Documents.SourceDocument) Then
			
			TypeName = NStr("vi = 'Biên bản thưởng của nhà cung cấp';
							|ru = 'Акт премии поставщика';
							|en = 'Vendor bonus certificate'; fa = 'گواهی پاداش تأمین‌کننده';
							|it = 'Акт премии поставщика';
							|pl = 'Vendor bonus certificate';
							|tr = 'Tedarikçiye ödül verilmesi'");
			
			TypeStructure = New Structure;
			TypeStructure.Insert("MetadataObjectName", Metadata.Documents.SourceDocument.FullName());
			TypeStructure.Insert("SourceDocumentType", Enums.SourceDocumentTypes.VendorBonusCertificate);
			
			TypesList.Add(
				TypeStructure,
				TypeName);
			
		EndIf;
		
	EndIf;
	
	If GetFunctionalOption("RecordComplaints")
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryCustomerBonuses
		And BusinessOperation <> Enums.BusinessTransactions.OBEntryVendorBonuses
		And Not TheseAreSettlementsBetweenOrganizations
			And AccessRight("Insert", Metadata.Catalogs.Complaints) Then
		TypesList.Add(
			Metadata.Catalogs.Complaints.FullName(),
			NStr("vi = 'Khiếu nại';
				|ru = 'Претензия';
				|en = 'Complaint'; fa = 'شکایت';
				|it = 'Претензия';
				|pl = 'Complaint';
				|tr = 'Şikayet'"));
	EndIf;
	
	Return TypesList;
	
EndFunction

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

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	SelectedOperation = Undefined;
	
	If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		
		SelectedOperation = Parameters.Key.BusinessOperation;
		
	ElsIf Parameters.Property("FillingValues") Then
		
		Parameters.FillingValues.Property("BusinessOperation", SelectedOperation);
		
	ElsIf Parameters.Property("CopyingValue") Then
		
		SelectedOperation = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.CopyingValue,"BusinessOperation");
		
	ElsIf Parameters.Property("FilterByTransactionTypes") And Parameters.FilterByTransactionTypes.Count() = 1 Then
		
		SelectedOperation = Parameters.FilterByTransactionTypes[0].Value;
		
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", SelectedOperation);
		
		Parameters.Insert("FillingValues", FillingValues);
		
		If Parameters.Property("Organization") Then
			FillingValues.Insert("Organization", Parameters.Organization);
		EndIf;
		
		If Parameters.Property("RecordInOperationalAccounting") Then
			FillingValues.Insert("RecordInOperationalAccounting", Parameters.RecordInOperationalAccounting);
		EndIf;
		
		If Parameters.Property("PostInFinancialAndTaxAccounting") Then
			FillingValues.Insert("PostInFinancialAndTaxAccounting", Parameters.PostInFinancialAndTaxAccounting);
		EndIf;
		
		If Parameters.Property("RecordInMA") Then
			FillingValues.Insert("RecordInMA", Parameters.RecordInMA);
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(SelectedOperation) Then
		
		StandardProcessing = False;
		
		MatchingOperationTypesToForms = New Map;
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable"),                   "PartnersARAPAccountingForm");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryVendorAccountsPayable"),                "PartnersARAPAccountingForm");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses"),                          "PartnersARAPAccountingForm");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryVendorBonuses"),                       "PartnersARAPAccountingForm");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer"),                         "PartnersARAPAccountingForm");
		MatchingOperationTypesToForms.Insert(PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor"),                      "PartnersARAPAccountingForm");
		
		SelectedForm = MatchingOperationTypesToForms[SelectedOperation];
		
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If Data.Ref <> Undefined Then
		Presentation = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Data,
			Data.Number,
			Data.Date,
			Data.BusinessOperation);
	EndIf;
	
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
	Query.Text = "SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	SourceDocument.LineOfBusiness AS LineOfBusiness,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(TabularDataSettlementsWithPartners.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntryARAP AS DocumentData
		|		LEFT JOIN Document.OBEntryARAP.PartnersARAPAccounting AS TabularDataSettlementsWithPartners
		|		ON DocumentData.Ref = TabularDataSettlementsWithPartners.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|		LEFT JOIN Document.SourceDocument AS SourceDocument
		|		ON TabularDataSettlementsWithPartners.DocumentOfARAPAccounting = SourceDocument.Ref
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	DocumentData.EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.DeletionMark,
		|	SourceDocument.LineOfBusiness, 
		|	DocumentData.Posted,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Number",  Attributes.Number);
	Query.SetParameter("Ref", Attributes.Ref);
	
	ListOfOrderTypes = New ValueList;
	ListOfOrderTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ListOfOrderTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	ListOfOrderTypes.Add(Type("DocumentRef.SalesOrder"));
	ListOfOrderTypes.Add(Type("DocumentRef.PurchaseOrder"));
	ListOfOrderTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	ListOfOrderTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	ListOfOrderTypes.Add(Type("DocumentRef.SubcontractOrder2_5"));
	Query.SetParameter("ListOfOrderTypes", ListOfOrderTypes);
	
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                 Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                    Attributes.RecordInMA);
	Query.SetParameter("EmployeeResponsible",                  Attributes.EmployeeResponsible);
	Query.SetParameter("Comment",                    Attributes.Comment);
	Query.SetParameter("DeletionMark",                Attributes.DeletionMark);
	Query.SetParameter("Posted",                       Attributes.Posted);
	Query.SetParameter("Patch",                    Attributes.Patch);
	Query.SetParameter("ReversedDocument",           Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",           Attributes.CorrectedDocument);
	Query.SetParameter("DocumentAmount",                 Attributes.DocumentAmount);
	Query.SetParameter("BusinessTransactionSetting", Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document."+Metadata.Documents.OBEntryARAP.Name));
	
EndProcedure

Procedure InitializeAnalyticsKeysForPartners(Query)
	
	If Query.TempTablesManager.Tables.Find("TTTableOfCalculationObjects") <> Undefined Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref"     ,               Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization",               Query.Parameters.Organization);
	QueryAnalyst.SetParameter("BusinessOperation",     Query.Parameters.BusinessOperation);
	QueryAnalyst.SetParameter("RecordInOperationalAccounting", Query.Parameters.RecordInOperationalAccounting);
	QueryAnalyst.SetParameter("PostInFinancialAndTaxAccounting",            Query.Parameters.PostInFinancialAndTaxAccounting);
	
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	TableSettlementsWithPartners.ARAPObject AS ARAPObject,
	|	TableSettlementsWithPartners.ARAPObjectSender AS ARAPObjectSender,
	|	CASE
	|		WHEN ARAPObjects.Organization.ParentCompany = &Organization
	|			THEN ARAPObjects.Organization
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN (&BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable), VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor), VALUE(Enum.BusinessTransactions.OBEntryVendorBonuses))
	|					AND ISNULL(Directions.VendorARAP, FALSE)
	|				OR &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable), VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer), VALUE(Enum.BusinessTransactions.OBEntryCustomerBonuses))
	|					AND ISNULL(Directions.IncomeAccounting, FALSE))
	|				AND NOT ARAPObjects.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN TableSettlementsWithPartners.ARAPObjectSender.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness
	|INTO TTTableOfCalculationObjects
	|FROM
	|	Document.OBEntryARAP.PartnersARAPAccounting AS TableSettlementsWithPartners
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TableSettlementsWithPartners.ARAPObjectSender = ARAPObjects.Ref
	|		LEFT JOIN Catalog.LinesOfBusiness AS Directions
	|		ON TableSettlementsWithPartners.ARAPObjectSender.LineOfBusiness = Directions.Ref
	|WHERE
	|	TableSettlementsWithPartners.Ref = &Ref
	|	AND (&RecordInOperationalAccounting OR &PostInFinancialAndTaxAccounting)
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable), VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer), VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable), VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor), VALUE(Enum.BusinessTransactions.OBEntryCustomerBonuses), VALUE(Enum.BusinessTransactions.OBEntryVendorBonuses))
	|
	|INDEX BY
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfCalculationObjects.Organization AS Organization,
	|	TableSettlementsWithPartners.Partner AS Partner,
	|	TableSettlementsWithPartners.Counterparty AS Counterparty,
	|	CASE
	|		WHEN TableSettlementsWithPartners.ARAPObject REFS Catalog.CounterpartyContracts
	|				OR TableSettlementsWithPartners.ARAPObject REFS Catalog.IntercompanyContracts
	|			THEN TableSettlementsWithPartners.ARAPObject
	|		WHEN TableSettlementsWithPartners.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN ISNULL(TableSettlementsWithPartners.ARAPObject.Contract, VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|		ELSE ISNULL(TableSettlementsWithPartners.ARAPObject.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|	END AS Contract,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.OBEntryARAP.PartnersARAPAccounting AS TableSettlementsWithPartners
	|		INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|		ON TableSettlementsWithPartners.ARAPObject = TableOfCalculationObjects.ARAPObject
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|		ON (TableOfCalculationObjects.Organization = RegisterAccountingAnalyticsForPartners.Organization)
	|			AND TableSettlementsWithPartners.Partner = RegisterAccountingAnalyticsForPartners.Partner
	|			AND TableSettlementsWithPartners.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|			AND (CASE
	|				WHEN TableSettlementsWithPartners.ARAPObject REFS Catalog.CounterpartyContracts
	|						OR TableSettlementsWithPartners.ARAPObject REFS Catalog.IntercompanyContracts
	|					THEN TableSettlementsWithPartners.ARAPObject
	|				WHEN TableSettlementsWithPartners.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|					THEN ISNULL(TableSettlementsWithPartners.ARAPObject.Contract, VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|				ELSE ISNULL(TableSettlementsWithPartners.ARAPObject.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|			END = RegisterAccountingAnalyticsForPartners.Contract)
	|			AND (TableOfCalculationObjects.LineOfBusiness = RegisterAccountingAnalyticsForPartners.LineOfBusiness)
	|WHERE
	|	TableSettlementsWithPartners.Ref = &Ref
	|	AND RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable), VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer), VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable), VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor), VALUE(Enum.BusinessTransactions.OBEntryCustomerBonuses), VALUE(Enum.BusinessTransactions.OBEntryVendorBonuses))
	|";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		// The function is called to verify and create an analytics key
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Selection);
	EndDo;
	
EndProcedure

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates";
	
	QueryText =
	"SELECT
	|	CurrencyRatesCut.Currency,
	|	CurrencyRatesCut.CourseNumerator / CurrencyRatesCut.CourseDenominator AS ConversionFactor_,
	|	CurrencyRatesCut.CourseNumerator AS CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator AS CourseDenominator
	|	
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			Currency IN
	|				(SELECT
	|					&ManagementAccountingCurrency
	|				
	|				UNION ALL
	|				
	|				SELECT DISTINCT
	|					EnteringBalancesSettlementsWithPartners.ARAPCurrency
	|				FROM
	|					Document.OBEntryARAP.PartnersARAPAccounting AS EnteringBalancesSettlementsWithPartners
	|				WHERE
	|					EnteringBalancesSettlementsWithPartners.Ref = &Ref
	|				) AND BaseCurrency = &LocalAccountingCurrency
	|	) AS CurrencyRatesCut";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSettlementsWithPartners(Query, QueryTexts)
	
	RegisterName = "TTSettlementsWithPartners";
	
	InitializeAnalyticsKeysForPartners(Query);
	
	QueryText =
	"SELECT
	|	TableSettlementsWithPartners.LineNumber AS LineNumber,
	|	TableSettlementsWithPartners.PaymentDate AS PaymentDate,
	|	TableSettlementsWithPartners.ARAPObjectSender AS ARAPObject,
	|	TableSettlementsWithPartners.Sum AS Sum,
	|	TableSettlementsWithPartners.ARAPCurrency AS ARAPCurrency,
	|	TableSettlementsWithPartners.SumCompl AS SumCompl,
	|	TableSettlementsWithPartners.SumMan AS SumMan,
	|	TableSettlementsWithPartners.DiscountingAmount AS DiscountingAmount,
	|	TableSettlementsWithPartners.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	TableSettlementsWithPartners.DiscountingAmountMan AS DiscountingAmountMan,
	|	TableSettlementsWithPartners.DeferredIncomeTA AS DeferredIncomeTA,
	|	TableSettlementsWithPartners.DeferredExpenseTA AS DeferredExpenseTA,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS DimensionKey,
	|	TableSettlementsWithPartners.DocumentOfARAPAccounting AS ARAPDocument,
	|	ISNULL(PrimaryDocumentTable.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	ISNULL(TableSettlementsWithPartners.DocumentOfARAPAccounting.Date, &Period) AS DateSettlementDocument
	|INTO TTSettlementsWithPartners
	|FROM
	|	Document.OBEntryARAP.PartnersARAPAccounting AS TableSettlementsWithPartners
	|		LEFT JOIN Document.SourceDocument AS PrimaryDocumentTable
	|		ON TableSettlementsWithPartners.DocumentOfARAPAccounting = PrimaryDocumentTable.Ref
	|		INNER JOIN TTTableOfCalculationObjects AS TableOfCalculationObjects
	|		ON TableSettlementsWithPartners.ARAPObject = TableOfCalculationObjects.ARAPObject
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON TableOfCalculationObjects.Organization = Dimension.Organization
	|		AND TableSettlementsWithPartners.Counterparty = Dimension.Counterparty
	|		AND TableSettlementsWithPartners.Partner = Dimension.Partner
	|		AND (CASE
	|			WHEN TableSettlementsWithPartners.ARAPObject REFS Catalog.CounterpartyContracts
	|			OR TableSettlementsWithPartners.ARAPObject REFS Catalog.IntercompanyContracts
	|				THEN TableSettlementsWithPartners.ARAPObject
	|			WHEN TableSettlementsWithPartners.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|				THEN ISNULL(TableSettlementsWithPartners.ARAPObject.Contract,
	|					VALUE(Catalog.IntercompanyContracts.EmptyRef))
	|			ELSE ISNULL(TableSettlementsWithPartners.ARAPObject.Contract,
	|				VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|		END) = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	TableSettlementsWithPartners.Ref = &Ref
	|	AND (&RecordInOperationalAccounting OR &PostInFinancialAndTaxAccounting)
	|	AND TableSettlementsWithPartners.ARAPObjectSender <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|
	|INDEX BY
	|	ARAPDocument,
	|	ARAPObject,
	|	DimensionKey,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "CustomersARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSettlementsWithPartners", QueryTexts) Then
		QueryTextTTSettlementsWithPartners(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	1                                              AS Order,
	|	TableSettlementsWithCustomers.LineNumber           AS LineNumber,
	|	&Period                                        AS Period,
	|	TableSettlementsWithCustomers.DateSettlementDocument AS RecorderDate,
	|	&Number                                         AS RecorderNumber,
	|	TableSettlementsWithCustomers.PaymentDate           AS PaymentDate,
	|	VALUE(AccumulationRecordType.Receipt)         AS RecordType,
	|	&Organization                                   AS Organization,
	|	TableSettlementsWithCustomers.ARAPObject        AS ARAPObject,
	|	TableSettlementsWithCustomers.ARAPCurrency  AS Currency,
	|	TableSettlementsWithCustomers.DimensionKey         AS AccountingDimensionByPartners,
	|	TableSettlementsWithCustomers.DimensionKey.Contract AS Contract,
	|	TRUE                                         AS ExcludeDuringControl,
	|	TableSettlementsWithCustomers.Sum                 AS Sum,
	|	0                                              AS AmountDue,
	|	TableSettlementsWithCustomers.SumCompl             AS SumCompl,
	|	CASE
	|		WHEN TableSettlementsWithCustomers.SumMan <> 0
	|			THEN TableSettlementsWithCustomers.SumMan
	|		WHEN TableSettlementsWithCustomers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithCustomers.Sum
	|		ELSE
	|			TableSettlementsWithCustomers.Sum * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END AS SumMan,
	|	TableSettlementsWithCustomers.ARAPDocument AS ARAPDocument,
	|	VALUE(Enum.SettlementOperations.Shipment) AS SettlementTransaction,
	|	VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable) AS BusinessOperation,
	|	&LocalAccountingCurrency AS DocumentCurrency,
	|	TableSettlementsWithCustomers.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting               AS BusinessTransactionSetting,
	|	
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseNumerator
	|	END AS RateARAPCurrencyNumerator,
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseDenominator
	|	END AS RateARAPCurrencyDenominator,
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseNumerator
	|	END AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseDenominator
	|	END AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	1 AS TypeOfOperationForSorting,
	|	4 AS OrderOfOperationsWithinDocument,
	|	TableSettlementsWithCustomers.LineOfBusiness AS LineOfBusiness
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithCustomers
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfMutualSettlements
	|		ON ExchangeRatesOfMutualSettlements.Currency = TableSettlementsWithCustomers.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                                               AS Order,
	|	TableSettlementsWithCustomers.LineNumber                                            AS LineNumber,
	|	CASE WHEN ENDOFPERIOD(TableSettlementsWithCustomers.PaymentDate, DAY) < &Period
	|		THEN &Period
	|		ELSE ENDOFPERIOD(TableSettlementsWithCustomers.PaymentDate, DAY)
	|	END                                                                           AS Period,
	|	TableSettlementsWithCustomers.DateSettlementDocument                                  AS RecorderDate,
	|	&Number                                                                          AS RecorderNumber,
	|	TableSettlementsWithCustomers.PaymentDate                                            AS PaymentDate,
	|	VALUE(AccumulationRecordType.Receipt)                                          AS RecordType,
	|	&Organization                                                                    AS Organization,
	|	TableSettlementsWithCustomers.ARAPObject                                         AS ARAPObject,
	|	TableSettlementsWithCustomers.ARAPCurrency                                   AS Currency,
	|	TableSettlementsWithCustomers.DimensionKey                                          AS AccountingDimensionByPartners,
	|	TableSettlementsWithCustomers.DimensionKey.Contract AS Contract,
	|	TRUE                                                                          AS ExcludeDuringControl,
	|	0                                                                               AS Sum,
	|	TableSettlementsWithCustomers.Sum                                                  AS AmountDue,
	|	0                                                                               AS SumCompl,
	|	0                                                                               AS SumMan,
	|	TableSettlementsWithCustomers.ARAPDocument                                      AS ARAPDocument,
	|	VALUE(Enum.SettlementOperations.EmptyRef)                      AS SettlementTransaction,
	|	VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)  AS BusinessOperation,
	|	&LocalAccountingCurrency                                                 AS DocumentCurrency,
	|	TableSettlementsWithCustomers.ARAPObject.UUID                 AS FinRecordID,
	|	&BusinessTransactionSetting                                                 AS BusinessTransactionSetting,
	|	
	|	0                                                                               AS RateARAPCurrencyNumerator,
	|	0                                                                               AS RateARAPCurrencyDenominator,
	|	0                                                                               AS ExchangeRateNumeratorOfManSCurrency,
	|	0                                                                               AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	1 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument,
	|	TableSettlementsWithCustomers.LineOfBusiness AS LineOfBusiness
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithCustomers
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	3                                              AS Order,
	|	TableSettlementsWithCustomers.LineNumber           AS LineNumber,
	|	&Period                                        AS Period,
	|	TableSettlementsWithCustomers.DateSettlementDocument AS RecorderDate,
	|	&Number                                         AS RecorderNumber,
	|	TableSettlementsWithCustomers.PaymentDate           AS PaymentDate,
	|	VALUE(AccumulationRecordType.Expense)         AS RecordType,
	|	&Organization                                   AS Organization,
	|	TableSettlementsWithCustomers.ARAPObject        AS ARAPObject,
	|	TableSettlementsWithCustomers.ARAPCurrency  AS ARAPCurrency,
	|	TableSettlementsWithCustomers.DimensionKey         AS AccountingDimensionByPartners,
	|	TableSettlementsWithCustomers.DimensionKey.Contract AS Contract,
	|	TRUE                                         AS ExcludeDuringControl,
	|	TableSettlementsWithCustomers.Sum                 AS Sum,
	|	TableSettlementsWithCustomers.Sum                 AS AmountDue,
	|	TableSettlementsWithCustomers.SumCompl             AS SumCompl,
	|	CASE
	|		WHEN TableSettlementsWithCustomers.SumMan <> 0
	|			THEN TableSettlementsWithCustomers.SumMan
	|		WHEN TableSettlementsWithCustomers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithCustomers.Sum
	|		ELSE
	|			TableSettlementsWithCustomers.Sum * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END                                         AS SumMan,
	|	TableSettlementsWithCustomers.ARAPDocument    AS ARAPDocument,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer)
	|		THEN VALUE(Enum.SettlementOperations.Payment)
	|		ELSE VALUE(Enum.SettlementOperations.ARAPAdjustment)
	|	END AS BusinessOperation,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer)
	|		THEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer)
	|		ELSE VALUE(Enum.BusinessTransactions.OBEntryCustomerBonuses)
	|	END AS SettlementTransaction,
	|	&LocalAccountingCurrency               AS DocumentCurrency,
	|	TableSettlementsWithCustomers.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting               AS BusinessTransactionSetting,
	|	
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseNumerator
	|	END AS RateARAPCurrencyNumerator,
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseDenominator
	|	END AS RateARAPCurrencyDenominator,
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseNumerator
	|	END AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE WHEN TableSettlementsWithCustomers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseDenominator
	|	END AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	1 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument,
	|	TableSettlementsWithCustomers.LineOfBusiness AS LineOfBusiness
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithCustomers
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfMutualSettlements
	|		ON ExchangeRatesOfMutualSettlements.Currency = TableSettlementsWithCustomers.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|WHERE
	|	(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer)
	|	OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerBonuses))
	|	AND &RecordInOperationalAccounting
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetParameterSettlementAnalyticsProvider(Query)
	
	If Query.Parameters.Property("SettlementAnalyticsSupplier") Then
		Return;
	EndIf;
	
	InitializeAnalyticsKeysForPartners(Query);
	
	SettlementAnalyticsSupplier = Undefined;
	
	Query.SetParameter("SettlementAnalyticsSupplier", SettlementAnalyticsSupplier);
	
EndProcedure

Function QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "VendorsARAPAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSettlementsWithPartners", QueryTexts) Then
		QueryTextTTSettlementsWithPartners(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	SetParameterSettlementAnalyticsProvider(Query);
	
	QueryText =
	"SELECT
	|	1                                                 AS Order,
	|	TableSettlementsWithSuppliers.LineNumber           AS LineNumber,
	|	&Period                                           AS Period,
	|	TableSettlementsWithSuppliers.DateSettlementDocument AS RecorderDate,
	|	&Number                                            AS RecorderNumber,
	|	TableSettlementsWithSuppliers.PaymentDate           AS PaymentDate,
	|	VALUE(AccumulationRecordType.Expense)            AS RecordType,
	|	TableSettlementsWithSuppliers.ARAPObject        AS ARAPObject,
	|	TableSettlementsWithSuppliers.DimensionKey         AS AccountingDimensionByPartners,
	|	TableSettlementsWithSuppliers.DimensionKey.Contract AS Contract,
	|	TableSettlementsWithSuppliers.ARAPCurrency  AS Currency,
	|	TableSettlementsWithSuppliers.Sum                 AS Sum,
	|	0                                                 AS AmountDue,
	|	TableSettlementsWithSuppliers.SumCompl             AS SumCompl,
	|	CASE
	|		WHEN TableSettlementsWithSuppliers.SumMan <> 0
	|			THEN TableSettlementsWithSuppliers.SumMan
	|		WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithSuppliers.Sum
	|		ELSE
	|			TableSettlementsWithSuppliers.Sum * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END                                            AS SumMan,
	|	TableSettlementsWithSuppliers.ARAPDocument    AS ARAPDocument,
	|	VALUE(Enum.SettlementOperations.Shipment) AS SettlementTransaction,
	|	VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable) AS BusinessOperation,
	|	&LocalAccountingCurrency                 AS DocumentCurrency,
	|	TableSettlementsWithSuppliers.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting,
	|	
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseNumerator
	|	END AS RateARAPCurrencyNumerator,
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseDenominator
	|	END AS RateARAPCurrencyDenominator,
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseNumerator
	|	END AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseDenominator
	|	END AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	1 AS TypeOfOperationForSorting,
	|	4 AS OrderOfOperationsWithinDocument
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithSuppliers
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfMutualSettlements
	|		ON ExchangeRatesOfMutualSettlements.Currency = TableSettlementsWithSuppliers.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                           AS Order,
	|	TableSettlementsWithSuppliers.LineNumber                     AS LineNumber,
	|	CASE WHEN ENDOFPERIOD(TableSettlementsWithSuppliers.PaymentDate, DAY) < &Period
	|		THEN &Period
	|		ELSE ENDOFPERIOD(TableSettlementsWithSuppliers.PaymentDate, DAY)
	|	END                                                       AS Period,
	|	TableSettlementsWithSuppliers.DateSettlementDocument           AS RecorderDate,
	|	&Number                                                      AS RecorderNumber,
	|	TableSettlementsWithSuppliers.PaymentDate                     AS PaymentDate,
	|	VALUE(AccumulationRecordType.Expense)                      AS RecordType,
	|	TableSettlementsWithSuppliers.ARAPObject                  AS ARAPObject,
	|	TableSettlementsWithSuppliers.DimensionKey                   AS AccountingDimensionByPartners,
	|	TableSettlementsWithSuppliers.DimensionKey.Contract AS Contract,
	|	TableSettlementsWithSuppliers.ARAPCurrency            AS Currency,
	|	0                                                           AS Sum,
	|	TableSettlementsWithSuppliers.Sum                           AS AmountDue,
	|	0                                                           AS SumCompl,
	|	0                                                           AS SumMan,
	|	TableSettlementsWithSuppliers.ARAPDocument               AS ARAPDocument,
	|	VALUE(Enum.SettlementOperations.EmptyRef)  AS SettlementTransaction,
	|	VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable) AS BusinessOperation,
	|	&LocalAccountingCurrency                             AS DocumentCurrency,
	|	TableSettlementsWithSuppliers.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting                             AS BusinessTransactionSetting,
	|	
	|	0                                                           AS RateARAPCurrencyNumerator,
	|	0                                                           AS RateARAPCurrencyDenominator,
	|	0                                                           AS ExchangeRateNumeratorOfManSCurrency,
	|	0                                                           AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	1 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithSuppliers
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	3                                                 AS Order,
	|	TableSettlementsWithSuppliers.LineNumber           AS LineNumber,
	|	&Period                                           AS Period,
	|	TableSettlementsWithSuppliers.DateSettlementDocument AS RecorderDate,
	|	&Number                                            AS RecorderNumber,
	|	TableSettlementsWithSuppliers.PaymentDate           AS PaymentDate,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	TableSettlementsWithSuppliers.ARAPObject        AS ARAPObject,
	|	TableSettlementsWithSuppliers.DimensionKey         AS AccountingDimensionByPartners,
	|	TableSettlementsWithSuppliers.DimensionKey.Contract AS Contract,
	|	TableSettlementsWithSuppliers.ARAPCurrency  AS ARAPCurrency,
	|	TableSettlementsWithSuppliers.Sum                 AS Sum,
	|	TableSettlementsWithSuppliers.Sum                 AS AmountDue,
	|	TableSettlementsWithSuppliers.SumCompl             AS SumCompl,
	|	CASE
	|		WHEN TableSettlementsWithSuppliers.SumMan <> 0
	|			THEN TableSettlementsWithSuppliers.SumMan
	|		WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithSuppliers.Sum
	|		ELSE
	|			TableSettlementsWithSuppliers.Sum * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END                                            AS SumMan,
	|	TableSettlementsWithSuppliers.ARAPDocument    AS ARAPDocument,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
	|		THEN VALUE(Enum.SettlementOperations.Payment)
	|		ELSE VALUE(Enum.SettlementOperations.ARAPAdjustment)
	|	END AS SettlementTransaction,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
	|		THEN VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
	|		ELSE VALUE(Enum.BusinessTransactions.OBEntryVendorBonuses)
	|	END AS BusinessOperation,
	|	&LocalAccountingCurrency                  AS DocumentCurrency,
	|	TableSettlementsWithSuppliers.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting                  AS BusinessTransactionSetting,
	|	
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseNumerator
	|	END AS RateARAPCurrencyNumerator,
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &LocalAccountingCurrency
	|			THEN 0
	|		ELSE ExchangeRatesOfMutualSettlements.CourseDenominator
	|	END AS RateARAPCurrencyDenominator,
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseNumerator
	|	END AS ExchangeRateNumeratorOfManSCurrency,
	|	CASE WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN 0
	|		ELSE ManExchangeRates.CourseDenominator
	|	END AS ExchangeRateDenominatorCurrencyMan,
	|	
	|	1 AS TypeOfOperationForSorting,
	|	1 AS OrderOfOperationsWithinDocument
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithSuppliers
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfMutualSettlements
	|		ON ExchangeRatesOfMutualSettlements.Currency = TableSettlementsWithSuppliers.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|WHERE
	|	(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor)
	|	OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorBonuses))
	|	AND &RecordInOperationalAccounting
	|
	|ORDER BY
	|	Order,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDiscountInterestExpense(Query, QueryTexts, Registers)

	RegisterName = "DiscountInterestExpense";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSettlementsWithPartners", QueryTexts) Then
		QueryTextTTSettlementsWithPartners(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	SetParameterSettlementAnalyticsProvider(Query);
	
	QueryText =
	"SELECT
	|	1                                                 AS Order,
	|	&Period                                           AS Period,
	|	TableSettlementsWithSuppliers.DateSettlementDocument AS RecorderDate,
	|	&Number                                            AS RecorderNumber,
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	TableSettlementsWithSuppliers.ARAPObject        AS ARAPObject,
	|	TableSettlementsWithSuppliers.DimensionKey         AS AccountingDimensionByPartners,
	|	TableSettlementsWithSuppliers.ARAPCurrency  AS Currency,
	|	SUM(TableSettlementsWithSuppliers.DiscountingAmount) AS DiscountingAmount,
	|	SUM(TableSettlementsWithSuppliers.DiscountingAmountCompl) AS DiscountingAmountCompl,
	|	SUM(CASE
	|		WHEN TableSettlementsWithSuppliers.DiscountingAmountMan <> 0
	|			THEN TableSettlementsWithSuppliers.DiscountingAmountMan
	|		WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithSuppliers.DiscountingAmount
	|		ELSE
	|			TableSettlementsWithSuppliers.DiscountingAmount * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END)                                           AS DiscountingAmountMan,
	|	TableSettlementsWithSuppliers.ARAPDocument    AS ARAPDocument,
	|	VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting) AS BusinessOperation,
	|	&LocalAccountingCurrency                 AS DocumentCurrency,
	|	TableSettlementsWithSuppliers.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting) AS BusinessTransactionSetting,
	|	""1""                                           AS Kind,
	|	CounterpartyContracts.DiscountRate      AS DiscountRate,
	|	SUM(TableSettlementsWithSuppliers.Sum / (1 + ISNULL(VATRates.Rate1, 0) / 100)) AS ActualDebtWithoutVAT,
	|	SUM(TableSettlementsWithSuppliers.Sum / (1 + ISNULL(VATRates.Rate1, 0) / 100) - TableSettlementsWithSuppliers.DiscountingAmount) AS DiscountedDebtWithoutVAT,
	|	SUM(TableSettlementsWithSuppliers.DiscountingAmount) AS CalculatedInterestBalance,
	|	SUM(TableSettlementsWithSuppliers.SumCompl / (1 + ISNULL(VATRates.Rate1, 0) / 100)) AS ActualDebtWithoutVATCompl,
	|	SUM(TableSettlementsWithSuppliers.SumCompl / (1 + ISNULL(VATRates.Rate1, 0) / 100) - TableSettlementsWithSuppliers.DiscountingAmountCompl) AS DiscountedDebtWithoutVATCompl,
	|	SUM(TableSettlementsWithSuppliers.DiscountingAmountCompl) AS CalculatedInterestBalanceCompl,
	|	SUM(CASE
	|		WHEN TableSettlementsWithSuppliers.SumMan <> 0
	|			THEN TableSettlementsWithSuppliers.SumMan / (1 + ISNULL(VATRates.Rate1, 0) / 100)
	|		WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithSuppliers.Sum / (1 + ISNULL(VATRates.Rate1, 0) / 100)
	|		ELSE
	|			TableSettlementsWithSuppliers.Sum * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1) / (1 + ISNULL(VATRates.Rate1, 0) / 100)
	|	END) AS ActualDebtWithoutVATMan,
	|	SUM(CASE
	|		WHEN TableSettlementsWithSuppliers.DiscountingAmountMan <> 0 AND TableSettlementsWithSuppliers.SumMan <> 0 
	|			THEN TableSettlementsWithSuppliers.SumMan / (1 + ISNULL(VATRates.Rate1, 0) / 100) - TableSettlementsWithSuppliers.DiscountingAmountMan
	|		WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithSuppliers.Sum / (1 + ISNULL(VATRates.Rate1, 0) / 100) - TableSettlementsWithSuppliers.DiscountingAmount
	|		ELSE
	|			TableSettlementsWithSuppliers.Sum / (1 + ISNULL(VATRates.Rate1, 0) / 100) - TableSettlementsWithSuppliers.DiscountingAmount * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END) AS DiscountedDebtWithoutVATMan,
	|	SUM(CASE
	|		WHEN TableSettlementsWithSuppliers.DiscountingAmountMan <> 0
	|			THEN TableSettlementsWithSuppliers.DiscountingAmountMan
	|		WHEN TableSettlementsWithSuppliers.ARAPCurrency = &ManagementAccountingCurrency
	|			THEN TableSettlementsWithSuppliers.DiscountingAmount
	|		ELSE
	|			TableSettlementsWithSuppliers.DiscountingAmount * ISNULL(ExchangeRatesOfMutualSettlements.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END) AS CalculatedInterestBalanceMan
	|FROM
	|	TTSettlementsWithPartners AS TableSettlementsWithSuppliers
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfMutualSettlements
	|		ON ExchangeRatesOfMutualSettlements.Currency = TableSettlementsWithSuppliers.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|			ON DimensionKeysOfAccountingByPartners.Contract = CounterpartyContracts.Ref
	|				LEFT JOIN Catalog.VATRates AS VATRates
	|				ON CounterpartyContracts.VATRate = VATRates.Ref
	|		ON TableSettlementsWithSuppliers.DimensionKey = DimensionKeysOfAccountingByPartners.Ref
	|		
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
	|	AND &RecordInOperationalAccounting
	|
	|GROUP BY
	|	CounterpartyContracts.DiscountRate,
	|	TableSettlementsWithSuppliers.ARAPObject.UUID,
	|	TableSettlementsWithSuppliers.ARAPDocument,
	|	TableSettlementsWithSuppliers.ARAPCurrency,
	|	TableSettlementsWithSuppliers.DimensionKey,
	|	TableSettlementsWithSuppliers.ARAPObject,
	|	TableSettlementsWithSuppliers.DateSettlementDocument
	|
	|ORDER BY
	|	Order";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	SUM(ISNULL(TabularDataSettlementsWithPartners.Sum, 0)) AS Sum,
	|	ISNULL(Companies.LocalAccountingCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Period AS RecordingInAccountingDate,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryARAP AS DocumentData
	|		LEFT JOIN Document.OBEntryARAP.PartnersARAPAccounting AS TabularDataSettlementsWithPartners
	|		ON DocumentData.Ref = TabularDataSettlementsWithPartners.Ref
	|		LEFT JOIN Catalog.Companies AS Companies
	|			ON DocumentData.Organization = Companies.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref,
	|	ISNULL(Companies.LocalAccountingCurrency, VALUE(Catalog.Currencies.EmptyRef))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntryARAP";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryARAP));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Function BusinessTransactionOfAgreementByTypeOfOperation(BusinessOperation) Export
	
	ContractBusinessTransaction = Enums.BusinessTransactions.EmptyRef();
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer Then
		ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer;
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryVendorAccountsPayable
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor Then
		ContractBusinessTransaction = Enums.BusinessTransactions.PurchaseFromSupplier;
	EndIf;
	
	Return ContractBusinessTransaction;
	
EndFunction

// Determines the visibility of the form group that contains the accounting types checkboxes.
// Used in forms where all types of accounting are available.
// 
// Parameters:
// 	Object - DocumentObject - Document for entering initial balances.
// Returns:
// 	Boolean - determines the visibility of the group of the type of accounting (operational, regulated and managerial)
Function VisibilityOfAccountingGroups(Object) Export
	
	VisibilityOfAccountingGroups = GetFunctionalOption("UseLocal")
		Or CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Object.Date), True);
	
	Return VisibilityOfAccountingGroups;
	
EndFunction

Function TypeOfSettlementDocumentForBusinessTransaction(BusinessOperation) Export
	
	ARAPObject = Undefined;
	
	Return ARAPObject;
	
EndFunction

Function NameOfTabularPartOfCalculationsForBusinessTransaction(BusinessOperation) Export
	
	Return "PartnersARAPAccounting";
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	OBEntryLocalization.EnteringSettlementBalancesAddPrintCommands(PrintCommands);
	
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

#EndRegion

#Region ServiceProceduresForFillingInAccordingToOperationalAccountingData

Procedure UpdateSettlementsWithPartners(Date, CompanyArray, NameOfOperationalRegister)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	RelevantBalance.AccountingDimensionByPartners
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(&DateOfRemainingGoods, AccountingDimensionByPartners.Organization IN (&CompanyArray)) AS RelevantBalance";
	
	If NameOfOperationalRegister = "VendorsARAPAccounting" Then
		Query.Text = StrReplace(Query.Text, "CustomersARAPAccounting", NameOfOperationalRegister);
	EndIf;
	
	Query.SetParameter("DateOfRemainingGoods", Date);
	Query.SetParameter("CompanyArray", CompanyArray);
	
	ArrayAnalytics = Query.Execute().Unload().UnloadColumn("AccountingDimensionByPartners");
	If ArrayAnalytics.Count() > 0 Then
		If NameOfOperationalRegister = "VendorsARAPAccounting" Then
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayAnalytics;
			Try
				ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(Date.Value, CalculationAnalysts);
			Except
				MessageText = NStr("vi = 'Đã tạo mẫu in theo dữ liệu không hiện thời.
				|Cần cập nhật hạch toán công nợ một cách thủ công và lập lại mẫu in.';
				|ru = 'Печатная форма сформирована по неактуальным данным.
				|Необходимо актуализировать взаиморасчеты вручную и переформировать печатную форму.';
				|en = 'Print form is generated according to irrelevant data. 
				|Update AR/AP accounting manually, and then create the print form again.'; fa = 'Print form is generated according to irrelevant data. 
				|Update AR/AP accounting manually, and then create the print form again.';
				|it = 'La versione di stampa è stata creata in base ai dati obsoleti.
				| È necessario attualizzare manualmente le regolazioni reciproche dei conti e creare una nuova versione stampa.';
				|pl = 'Formularz wydruku jest tworzony na podstawie nieaktualnych danych.
				|Konieczna jest ręczna aktualizacja wzajemnych rozliczeń i ponowne drukowanie formularza wydruku.';
				|tr = 'Çıktı alakasız veriler kullanılarak oluşturulmuştur.
				| Hesapları manuel olarak güncellemeniz ve çıktıyı yeniden oluşturmanız gerekecektir.'");
				Common.MessageToUser(MessageText);
			EndTry;
		Else
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayAnalytics;
			Try
				ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(Date.Value, CalculationAnalysts);
			Except
				MessageText = NStr("vi = 'Đã tạo mẫu in theo dữ liệu không hiện thời.
				|Cần cập nhật hạch toán công nợ một cách thủ công và lập lại mẫu in.';
				|ru = 'Печатная форма сформирована по неактуальным данным.
				|Необходимо актуализировать взаиморасчеты вручную и переформировать печатную форму.';
				|en = 'Print form is generated according to irrelevant data. 
				|Update AR/AP accounting manually, and then create the print form again.'; fa = 'Print form is generated according to irrelevant data. 
				|Update AR/AP accounting manually, and then create the print form again.';
				|it = 'La versione di stampa è stata creata in base ai dati obsoleti.
				| È necessario attualizzare manualmente le regolazioni reciproche dei conti e creare una nuova versione stampa.';
				|pl = 'Formularz wydruku jest tworzony na podstawie nieaktualnych danych.
				|Konieczna jest ręczna aktualizacja wzajemnych rozliczeń i ponowne drukowanie formularza wydruku.';
				|tr = 'Çıktı alakasız veriler kullanılarak oluşturulmuştur.
				| Hesapları manuel olarak güncellemeniz ve çıktıyı yeniden oluşturmanız gerekecektir.'");
				Common.MessageToUser(MessageText);
			EndTry;
		EndIf;
	EndIf;
	
EndProcedure

Function BalancesOnSettlementsWithPartners(DateOfRemainingGoods, BusinessOperation, CompanyArray)
	
	Query = New Query;
	Query.Parameters.Insert("CompanyArray",     CompanyArray);
	Query.Parameters.Insert("BusinessOperation", BusinessOperation);
	Query.Parameters.Insert("Date",                  DateOfRemainingGoods);
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		If BusinessOperation = Enums.BusinessTransactions.OBEntryCustomerAccountsReceivable
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer Then
			UpdateSettlementsWithPartners(DateOfRemainingGoods, CompanyArray, "CustomersARAPAccounting");
		Else
			UpdateSettlementsWithPartners(DateOfRemainingGoods, CompanyArray, "VendorsARAPAccounting");
		EndIf;
		
		Query.Text = 
		"SELECT
		|	AnalyticsData.DimensionKey AS DimensionKey
		|INTO TTAnalyticsKeys
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|WHERE
		|	AnalyticsData.Organization IN (&CompanyArray)
		|INDEX BY
		|	DimensionKey
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""PartnersARAPAccounting"" AS TablePartToFillIn,
		|	AnalyticsData.Partner,
		|	AnalyticsData.Counterparty,
		|	AnalyticsData.Organization AS Organization,
		|	&BusinessOperation AS BusinessOperation,
		|	AnalyticsData.Contract,
		|	AnalyticsData.LineOfBusiness,
		|	BalanceData.SalesOrder AS ARAPObjectSender,
		|	BalanceData.SalesOrder.Object AS ARAPObject,
		|	BalanceData.ARAPDocument AS DocumentOfARAPAccounting,
		|	BalanceData.Currency AS ARAPCurrency,
		|	SUM(CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|				THEN BalanceData.DebtBalance
		|			ELSE -BalanceData.PrepaymentBalance
		|		END) AS Sum,
		|	SUM(CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|				THEN BalanceData.DebtLocalBalance
		|			ELSE -BalanceData.PrepaymentLocalBalance
		|		END) AS SumCompl,
		|	SUM(CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|				THEN BalanceData.ARAPManBalance
		|			ELSE -BalanceData.PrepaymentManBalance
		|		END) AS SumMan
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
		|			&Date,
		|			(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer))
		|			AND AccountingDimensionByPartners IN (SELECT DimensionKey FROM TTAnalyticsKeys)) AS BalanceData
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|		ON BalanceData.AccountingDimensionByPartners = AnalyticsData.DimensionKey
		|WHERE
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|			THEN BalanceData.DebtBalance
		|		ELSE -BalanceData.PrepaymentBalance
		|	END > 0
		|		
		|GROUP BY
		|	BalanceData.Currency,
		|	BalanceData.SalesOrder,
		|	BalanceData.ARAPDocument,
		|	AnalyticsData.LineOfBusiness,
		|	AnalyticsData.Counterparty,
		|	AnalyticsData.Contract,
		|	AnalyticsData.Organization,
		|	AnalyticsData.Partner
		|
		|UNION ALL
		|
		|SELECT
		|	""PartnersARAPAccounting"",
		|	AnalyticsData.Partner,
		|	AnalyticsData.Counterparty,
		|	AnalyticsData.Organization,
		|	&BusinessOperation,
		|	AnalyticsData.Contract,
		|	AnalyticsData.LineOfBusiness,
		|	BalanceData.PurchaseOrder,
		|	BalanceData.PurchaseOrder.Object,
		|	BalanceData.ARAPDocument,
		|	BalanceData.Currency,
		|	SUM(CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|				THEN -BalanceData.DebtBalance
		|			ELSE BalanceData.PrepaymentBalance
		|		END),
		|	SUM(CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|				THEN -BalanceData.DebtLocalBalance
		|			ELSE BalanceData.PrepaymentLocalBalance
		|		END),
		|	SUM(CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|				THEN -BalanceData.ARAPManBalance
		|			ELSE BalanceData.PrepaymentManBalance
		|		END)
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
		|			&Date,
		|			(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor))
		|			AND AccountingDimensionByPartners IN (SELECT DimensionKey FROM TTAnalyticsKeys)) AS BalanceData
		|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|		ON BalanceData.AccountingDimensionByPartners = AnalyticsData.DimensionKey
		|WHERE
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|			THEN -BalanceData.DebtBalance
		|		ELSE BalanceData.PrepaymentBalance
		|	END > 0
		|
		|GROUP BY
		|	AnalyticsData.Partner,
		|	AnalyticsData.Organization,
		|	AnalyticsData.Counterparty,
		|	AnalyticsData.Contract,
		|	AnalyticsData.LineOfBusiness,
		|	BalanceData.PurchaseOrder,
		|	BalanceData.ARAPDocument,
		|	BalanceData.Currency
		|
		|ORDER BY
		|	Organization";
		
	Else
		
		Query.Text = 
		"SELECT
		|	AnalyticsData.DimensionKey AS DimensionKey
		|INTO TTAnalyticsKeys
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|WHERE
		|	AnalyticsData.Organization IN(&CompanyArray)
		|
		|INDEX BY
		|	DimensionKey
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""PartnersARAPAccounting"" AS TablePartToFillIn,
		|	AnalyticsData.Partner AS Partner,
		|	AnalyticsData.Counterparty AS Counterparty,
		|	AnalyticsData.Organization AS Organization,
		|	&BusinessOperation AS BusinessOperation,
		|	AnalyticsData.Contract AS Contract,
		|	AnalyticsData.LineOfBusiness AS LineOfBusiness,
		|	BalanceData.ARAPObject.Object AS ARAPObject,
		|	BalanceData.ARAPObject AS ARAPObjectSender,
		|	BalanceData.ARAPDocument AS DocumentOfARAPAccounting,
		|	BalanceData.Currency AS ARAPCurrency,
		|	BalanceData.PlannedRepaymentDate AS PaymentDate,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|			THEN BalanceData.DebtBalance
		|		ELSE BalanceData.PrepaymentBalance
		|	END AS Sum,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|			THEN BalanceData.DebtLocalBalance
		|		ELSE BalanceData.PrepaymentLocalBalance
		|	END AS SumCompl,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|			THEN BalanceData.ARAPManBalance
		|		ELSE BalanceData.PrepaymentManBalance
		|	END AS SumMan
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
		|			&Date,
		|			(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer))
		|				AND AccountingDimensionByPartners IN
		|					(SELECT
		|						TTAnalyticsKeys.DimensionKey
		|					FROM
		|						TTAnalyticsKeys)) AS BalanceData
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|		ON BalanceData.AccountingDimensionByPartners = AnalyticsData.DimensionKey
		|WHERE
		|	CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable)
		|				THEN BalanceData.DebtBalance
		|			ELSE BalanceData.PrepaymentBalance
		|		END > 0
		|
		|UNION ALL
		|
		|SELECT
		|	""PartnersARAPAccounting"",
		|	AnalyticsData.Partner,
		|	AnalyticsData.Counterparty,
		|	AnalyticsData.Organization,
		|	&BusinessOperation,
		|	AnalyticsData.Contract,
		|	AnalyticsData.LineOfBusiness,
		|	BalanceData.ARAPObject.Object,
		|	BalanceData.ARAPObject,
		|	BalanceData.ARAPDocument,
		|	BalanceData.Currency,
		|	BalanceData.PlannedRepaymentDate,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|			THEN BalanceData.DebtBalance
		|		ELSE BalanceData.PrepaymentBalance
		|	END,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|			THEN BalanceData.DebtLocalBalance
		|		ELSE BalanceData.PrepaymentLocalBalance
		|	END,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|			THEN BalanceData.ARAPManBalance
		|		ELSE BalanceData.PrepaymentManBalance
		|	END
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|			&Date,
		|			(&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|				OR &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor))
		|				AND AccountingDimensionByPartners IN
		|					(SELECT
		|						TTAnalyticsKeys.DimensionKey
		|					FROM
		|						TTAnalyticsKeys)) AS BalanceData
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|		ON BalanceData.AccountingDimensionByPartners = AnalyticsData.DimensionKey
		|WHERE
		|	CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryVendorAccountsPayable)
		|				THEN BalanceData.DebtBalance
		|			ELSE BalanceData.PrepaymentBalance
		|		END > 0
		|
		|ORDER BY
		|	Organization";
		
		If InformationRegisters.JobsForARAPAllocating.CurrentPeriodOfCalculatedDataOnMutualSettlements() <> Undefined Then
			Common.MessageToUser(ARAPAccountingServer.TextOfWarningOfAssignmentOfDistributionOfMutualSettlements());
		EndIf;
		
	EndIf;
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
