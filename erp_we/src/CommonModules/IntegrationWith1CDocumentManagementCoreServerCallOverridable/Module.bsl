////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentworkingbazovaya functionality of the call of the service is undetectable: server, server call
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called before opening the form for creating a new IP object based on the object BEFORE.
// Allows you to redefine the parameters of the form being opened, for example, the structure containing the values
// passed to the handler for filling in the IC object.
//
// Parameters:
//   FormName - String - the name of the form of the IP object to be opened.
//   FormParameters - Structure - Parameters of the form to open:
//     * FillingValues - Structure - Key - name of the item, value-value of the item.
//     * IntegrationWith1CDocumentManagement_ObjectIdentifierDM - String - ID of the source object BEFORE.
//     * IntegrationWith1CDocumentManagement_ObjectTypeDM - String - the type of the source object BEFORE.
//     * Basis - See IntegrationWith1CDocumentManagementCore.DataForFillingInIntegratedObject
//
// Example:
//	If Formname = "Document._The buyer's demo order.Object Form" Then
//		ObjectDO = integration1documentobase functionality.Get an object(
//			integration1sdocumentobase functionsp.getProxy(),
//			Form parameters.integrations1document_t type of object_,
//			Form parameters.integration1document_identificatorobject ID,
//			"name");
//		Form parameters.The foundation.Insert("Source View", 
//	The end if;
//
Procedure BeforeOpeningFormForCreatingNewIPObjectBasedOnObjectBEFORE(FormName, FormParameters) Export
	
	
	
EndProcedure

// Called when determining the name of the Form Attribute that contains a reference to an object that is integrated with 1C:Document management.
// Allows you to specify the name of the Form Attribute that contains a link to an object that is integrated with 1C:Document management.
// Redefinition is required only if the name of the main Attribute of the Form
// differs from the standard name "Object".
//
// Parameters:
//   Form - ClientApplicationForm - the form in which the Attribute is searched.
//         - Structure - structure with Attributes:
//     * FormName - String
//     * Parameters - Structure
//                 - FormDataStructure
//                 - Undefined
//     * Object - Structure
//              - FormDataStructure
//   FormAttributes - Array of FormAttribute - list of all Attributes of the form.
//                  - Undefined - if the function call comes from the client, and it is impossible to get a list of Attributes.
//   TypeOfIntegratedObject - Type - the type of link you want to find on the form.
//   AttributeName - String - an implicitly returned value, the name of the Attribute containing a reference to the integrated with
//     1C:Document management object.
//
// Example:
//	If the Form.Formname = "Document.Version of the agreementcommercial agreement.Form.Formadocument" Then
//		ReqUisitname = "Contract object.Link";
//	The end if;
//
Procedure WhenDeterminingAttributeNameOfObjectIntegratedWith1CDocumentManagement(Val Form, Val FormAttributes,
		Val TypeOfIntegratedObject, AttributeName) Export
	
	If Form.FormName = "Document.AgreementVersionCommercialContract.Form.DocumentForm" Then
		AttributeName = "ObjectAgreement.Ref";
	EndIf;
	
EndProcedure

// Fills predefined expression templates in the built-in language.
//
// Parameters:
//   ExpressionTemplates - Map of KeyAndValue:
//     * Key - String - the name of the template.
//     * Value - String - expression in the built-in language.
//
Procedure WhenDefiningExpressionTemplatesInEmbeddedLanguage(ExpressionTemplates) Export
	
	ExpressionTemplates.Insert("FillingInIndefiniteVDO",
		"Parameters.Result = Not ValueIsFilled(Parameters.Source.ValidityEndDate);");
	
	ExpressionTemplates.Insert("FillingInLBOfSvTO",
		"Parameters.Result = VATAccountingERPClientServer.CalculateVATAmount(
		|	Parameters.Source.Sum,
		|	Parameters.Source.VATRate);");
	
	ExpressionTemplates.Insert("FillingInArticlesDDSvTO",
		"Parameters.Result = New ValueTable;
		|Parameters.Result.Columns.Add(""CFItem"");
		|Parameters.Result.Columns.Add(""Sum"");
		|Parameters.Result.Columns.Add(""VATAmount"");
		|For Everyone String From Parameters.Source.ARAPDetails Cycle
		|	NewRow = Parameters.Result.Add();
		|	NewRow.CFItem = String.CashFlowItem;
		|	NewRow.Sum = String.Sum;
		|	NewRow.VATAmount = String.VATAmount;
		|EndOfTheCycle;
		|Parameters.Result.GroupBy(""CFItem"", ""Sum, VATAmount"")");
	
	ExpressionTemplates.Insert("FillingInPartiesFromAgreement",
		"Parameters.Result = New ValueTable;
		|Parameters.Result.Columns.Add(""Comment"");
		|Parameters.Result.Columns.Add(""ContactPerson"");
		|Parameters.Result.Columns.Add(""Description"");
		|Parameters.Result.Columns.Add(""DescriptionID"");
		|Parameters.Result.Columns.Add(""DescriptionType"");
		|Parameters.Result.Columns.Add(""Party"");
		|Parameters.Result.Columns.Add(""Set"");
		|Parameters.Result.Columns.Add(""SignatureDate"");
		|Parameters.Result.Columns.Add(""Signed"");
		|Parameters.Result.Columns.Add(""SignedBy"");
		|
		|NewRow = Parameters.Result.Add();
		|NewRow.Party = Parameters.Source.Organization;
		|NameSellerXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
		|	""DMPartyName"", ""Seller"");
		|NewRow.Description = NameSellerXDTO.name;
		|NewRow.DescriptionID = NameSellerXDTO.objectID.ID;
		|NewRow.DescriptionType = NameSellerXDTO.objectID.type;
		|
		|NewRow = Parameters.Result.Add();
		|NewRow.Party = Parameters.Source.Counterparty;
		|NameBuyerXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
		|	""DMPartyName"", ""Customer"");
		|NewRow.Description = NameBuyerXDTO.name;
		|NewRow.DescriptionID = NameBuyerXDTO.objectID.ID;
		|NewRow.DescriptionType = NameBuyerXDTO.objectID.type;
		|If ValueIsFilled(Parameters.Source.ContactPerson) Then
		|	NewRow.ContactPerson = Parameters.Source.ContactPerson;
		|EndIf;");
	
	ExpressionTemplates.Insert("FillingInPartiesFromContract",
		"Parameters.Result = New ValueTable;
		|Parameters.Result.Columns.Add(""Comment"");
		|Parameters.Result.Columns.Add(""ContactPerson"");
		|Parameters.Result.Columns.Add(""Description"");
		|Parameters.Result.Columns.Add(""DescriptionID"");
		|Parameters.Result.Columns.Add(""DescriptionType"");
		|Parameters.Result.Columns.Add(""Party"");
		|Parameters.Result.Columns.Add(""Set"");
		|Parameters.Result.Columns.Add(""SignatureDate"");
		|Parameters.Result.Columns.Add(""Signed"");
		|Parameters.Result.Columns.Add(""SignedBy"");
		|
		|NewRow = Parameters.Result.Add();
		|NewRow.Party = Parameters.Source.Organization;
		|NameCustomerXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
		|	""DMPartyName"", ""Customer_"");
		|NewRow.Description = NameCustomerXDTO.name;
		|NewRow.DescriptionID = NameCustomerXDTO.objectID.id;
		|NewRow.DescriptionType = NameCustomerXDTO.objectID.type;
		|
		|NewRow = Parameters.Result.Add();
		|NewRow.Party = Parameters.Source.Counterparty;
		|NameArtistXDTO = IntegrationWith1CDocumentManagementCore.PredefinedValueBefore(
		|	""DMPartyName"", ""Performer"");
		|NewRow.Description = NameArtistXDTO.name;
		|NewRow.DescriptionID = NameArtistXDTO.objectID.id;
		|NewRow.DescriptionType = NameArtistXDTO.objectID.type;
		|If ValueIsFilled(Parameters.Source.ContactPerson) Then
		|	NewRow.ContactPerson = Parameters.Source.ContactPerson;
		|EndIf;");
	
	ExpressionTemplates.Insert("FillingInAmountFromOrder",
		"If Parameters.Source.PriceIncludesVAT Then
		|	Parameters.Result = Parameters.Source.DocumentAmount;
		|Else
		|	Parameters.Result = Parameters.Source.DocumentAmount - Parameters.Source.Goods.Total(""VATAmount"");
		|EndIf;");
	
	ExpressionTemplates.Insert("FillingInVATFromOrder",
		"Parameters.Result = Parameters.Source.Goods.Total(""VATAmount"");");
	
	ExpressionTemplates.Insert("FillingInAmountFromReturnRequest",
		"If Parameters.Source.PriceIncludesVAT Then
		|	Parameters.Result = Parameters.Source.DocumentAmount;
		|Else
		|	Parameters.Result = Parameters.Source.DocumentAmount - Parameters.Source.ReturnedGoods.Total(""VATAmount"");
		|EndIf;");
	
	ExpressionTemplates.Insert("FillingInVATFromReturnRequest",
		"Parameters.Result = Parameters.Source.ReturnedGoods.Total(""VATAmount"");");
	
	ExpressionTemplates.Insert("FillingInVATFromCashExpenseRequest",
		"Parameters.Result = Parameters.Source.ARAPDetails.Total(""VATAmount"");");
	
EndProcedure

// Creates integration rules for the specified type of IP object.
//
// Parameters:
//   ObjectTypeName - String, AnyRef - the full name of the IP object type, as in the metadata, or a reference to the IP object.
//   RulesForIntegration - Array of See IntegrationWith1CDocumentManagementCoreClientServer.TheseIntegrationRules
//
// Example:
//	If the Object Type name = "Document.The receipt of the " Then
//		Creating integration rules and adding them to the array
//		Integration Rules = Start automatic adjustment of Integration and access to Product services();
//	If the type name of the object = "Document.The application for the expenditure of monetary funds" Then
//		Creating integration rules and adding them to the array
//		Integration Rules = Start automatic adjustment of the integration of the Channel operation();
//	The end if;
//
Procedure WhenCreatingIntegrationRulesAutomatically(Val ObjectTypeName, RulesForIntegration) Export
	
	If Common.IsReference(TypeOf(ObjectTypeName)) Then
		ObjectTypeName = ObjectTypeName.Metadata().FullName();
	EndIf;
	
	FolderDetails = IntegrationWith1CDocumentManagement.StructureOfDetailsOfInternalDocumentsFolderToFillIn();
	FolderDetails.LongDesc = NStr("vi = 'Đã tạo tự động từ BID';
									|ru = 'Создано автоматически из БИД';
									|en = 'Generated automatically from LID'; fa = 'Generated automatically from LID';
									|it = 'Creato automaticamente da BID';
									|pl = 'Utworzono automatycznie z Biblioteki integracji z 1C:Document Management';
									|tr = '1C:Document Management ile Entegrasyon Kütüphanesinden otomatik olarak oluşturuldu'");
	InternalDocumentFolder = Undefined;
	
	DetailsOfDocumentType = IntegrationWith1CDocumentManagement.StructureOfTheAttributesOfTheFilledDocumentKindDM(
		"DMInternalDocumentType");
	DetailsOfDocumentType.Autonumbering = True;
	DocumentKind = Undefined;
	
	If ObjectTypeName = "Catalog.TermsOfSale" Then
		FolderDetails.Name = NStr("vi = 'Thỏa thuận về điều kiện bán hàng';
									|ru = 'Соглашения об условиях продаж';
									|en = 'Terms of sale'; fa = 'شرایط فروش';
									|it = 'Accordo sulle condizioni della vendita';
									|pl = 'Umowa o warunkach sprzedaży';
									|tr = 'Satış şart ve hükümleri'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Thỏa thuận về điều kiện bán hàng';
											|ru = 'Соглашение об условиях продаж';
											|en = 'Terms of sale'; fa = 'شرایط فروش';
											|it = 'Accordo sulle condizioni della vendita';
											|pl = 'Umowa o warunkach sprzedaży';
											|tr = 'Satış şart ve hükümleri'");
		DetailsOfDocumentType.UseSigning = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfParties = True;
		DetailsOfDocumentType.ConsiderExpirationDate = True;
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		
	ElsIf ObjectTypeName = "Catalog.CounterpartyContracts" Then
		FolderDetails.Name = NStr("vi = 'Hợp đồng';
									|ru = 'Договоры';
									|en = 'Contracts'; fa = 'قراردادها';
									|it = 'Contratti';
									|pl = 'Contracts';
									|tr = 'Sözleşmeler'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Hợp đồng với đối tác';
											|ru = 'Договор с контрагентом';
											|en = 'Contract'; fa = 'قرارداد';
											|it = 'Contratto con la controparte';
											|pl = 'Umowa z kontrahentem';
											|tr = 'Cari hesap ile sözleşme'");
		DetailsOfDocumentType.UseSigning = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfParties = True;
		DetailsOfDocumentType.ConsiderExpirationDate = True;
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		
	ElsIf ObjectTypeName = "Document.CommercialProposalForCustomer" Then
		FolderDetails.Name = NStr("vi = 'Báo giá cho khách hàng';
									|ru = 'Коммерческие предложения клиентам';
									|en = 'Sales quotations'; fa = 'پیشنهادهای فروش';
									|it = 'Offerte commerciali ai clienti';
									|pl = 'Oferty komercyjne do klientów';
									|tr = 'Müşterilere sunulan satış teklifleri'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Báo giá cho khách hàng';
											|ru = 'Коммерческое предложение клиенту';
											|en = 'Sales quotation'; fa = 'پیش‌فاکتور فروش';
											|it = 'Offerta commerciale al cliente';
											|pl = 'Oferta cenowa do klienta';
											|tr = 'Satış teklifi'");
		DetailsOfDocumentType.UseDueDate = True;
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		DetailsOfDocumentType.KeepRecordsOfParties = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfGoodsAndServices = True;
		DetailsOfDocumentType.UseAssertion = True;
		
	ElsIf ObjectTypeName = "Document.SalesOrder" Then
		FolderDetails.Name = NStr("vi = 'Đơn hàng của khách';
									|ru = 'Заказы клиентов';
									|en = 'Sales orders'; fa = 'سفارش‌های فروش';
									|it = 'Ordini dei clienti';
									|pl = 'Zamówienia od klientów';
									|tr = 'Satış siparişleri'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Đơn hàng của khách';
											|ru = 'Заказ клиента';
											|en = 'Sales order'; fa = 'سفارش فروش';
											|it = 'Ordine del cliente';
											|pl = 'Zamówienie klienta';
											|tr = 'Satış siparişi'");
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		DetailsOfDocumentType.KeepRecordsOfCounterparties = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfGoodsAndServices = True;
		DetailsOfDocumentType.UseAssertion = True;
		
	ElsIf ObjectTypeName = "Document.PurchaseOrder" Then
		FolderDetails.Name = NStr("vi = 'Đơn hàng đặt nhà cung cấp';
									|ru = 'Заказы поставщикам';
									|en = 'Purchase orders'; fa = 'سفارش‌های خرید';
									|it = 'Ordini ai fornitori';
									|pl = 'Zamówienia do dostawcy';
									|tr = 'Satın alma siparişleri'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Đơn hàng đặt nhà cung cấp';
											|ru = 'Заказ поставщику';
											|en = 'Purchase order'; fa = 'سفارش خرید';
											|it = 'Ordine al fornitore';
											|pl = 'Zamówienie do dostawcy';
											|tr = 'Satın alma siparişi'");
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		DetailsOfDocumentType.KeepRecordsOfCounterparties = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfGoodsAndServices = True;
		DetailsOfDocumentType.UseAssertion = True;
		
	ElsIf ObjectTypeName = "Document.RequestForReturnOfGoodsFromCustomer" Then
		FolderDetails.Name = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
									|ru = 'Заявки на возврат товаров от клиентов';
									|en = 'Sales return requests'; fa = 'درخواست‌های برگشت از فروش';
									|it = 'Domande di reso merci dai clienti';
									|pl = 'Wnioski o zwrot towarów od klientów';
									|tr = 'Müşterilerin ürün iadesi talepleri'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Giấy đề nghị trả hàng từ người mua';
											|ru = 'Заявка на возврат товаров от клиента';
											|en = 'Sales return request'; fa = 'درخواست برگشت از فروش';
											|it = 'Richiesta di reso della merce dal cliente';
											|pl = 'Wniosek o zwrot towarów od klienta';
											|tr = 'Müşteriden satış iadesi talebi'");
		DetailsOfDocumentType.UseDueDate = True;
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		DetailsOfDocumentType.KeepRecordsOfCounterparties = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfGoodsAndServices = True;
		DetailsOfDocumentType.UseAssertion = True;
		
	ElsIf ObjectTypeName = "Document.PaymentRequest" Then
		FolderDetails.Name = NStr("vi = 'Giấy đề nghị thanh toán';
									|ru = 'Заявки на расходование ДС';
									|en = 'Payment requests'; fa = 'درخواست‌های پرداخت';
									|it = 'Richieste per la spesa';
									|pl = 'Wnioski o wydatkowanie środków pieniężnych';
									|tr = 'Ödeme talepleri'");
		
		DetailsOfDocumentType.Name = NStr("vi = 'Giấy đề nghị thanh toán';
											|ru = 'Заявка на расходование денежных средств';
											|en = 'Payment request'; fa = 'درخواست پرداخت';
											|it = 'Richiesta per la spesa';
											|pl = 'Wniosek o wydatkowanie środków pieniężnych';
											|tr = 'Ödeme talebi'");
		DetailsOfDocumentType.UseDueDate = True;
		DetailsOfDocumentType.ConsiderDocumentAmount = True;
		DetailsOfDocumentType.KeepRecordsOfOrganizations = True;
		DetailsOfDocumentType.KeepRecordsOfParties = True;
		DetailsOfDocumentType.IsRequestForPayment = True;
		DetailsOfDocumentType.KeepRecordsOfGoodsAndServices = True;
		DetailsOfDocumentType.UseAssertion = True;
		DetailsOfDocumentType.KeepRecordsOfCFItem = True;
		
	EndIf;
	
	If ValueIsFilled(FolderDetails.Name) And ValueIsFilled(DetailsOfDocumentType.Name) Then
		InternalDocumentFolder = IntegrationWith1CDocumentManagement.FindCreateVDOInternalDocumentsFolder(FolderDetails);
		DocumentKind = IntegrationWith1CDocumentManagement.FindCreateVDODocumentView(DetailsOfDocumentType);
		
		// Let's create a rule
		RulesForIntegration.Add(
			IntegrationWith1CDocumentManagementERP.CreateIntegrationRule(
				ObjectTypeName,
				"DMInternalDocument",
				DocumentKind,
				InternalDocumentFolder));
	EndIf;
	
EndProcedure

#EndRegion