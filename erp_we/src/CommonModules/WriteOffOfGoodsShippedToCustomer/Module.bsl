//////////////////////////////////////////////////////////////////////////
// Procedures and functions of the "Sales" subsystem
// related to the business transaction "Write-off of goods shipped to the customer".
//
//////////////////////////////////////////////////////////////////////////

#Region Public

#Region UnifiedMethodsForBusinessOperations

#Region Posting

// Returns parameters for filling in inventory types for the document "Write-off of shipped goods".
//
// Parameters:
//	Object - DocumentObject.WriteOffOfShippedGoods - the document for which inventory filling is performed.
//
// Returns:
//	See InventoriesServer.ParametersForFillingInventoryTypes.
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByAgreementSettings");
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business transaction of the contract.
//
// Returns:
//	EnumRef.BusinessTransactions - business transaction of the Contract.
//
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.SaleToCustomer;
	
EndFunction

// Returns a collection of object Attribute names available of operation.
//
// Returns:
//	Array of String - collection of object Attribute names available of operation.
//
Function TransactionDetails() Export
	
	TransactionDetails = New Array;
	TransactionDetails.Add("ReferenceOrder");
	TransactionDetails.Add("Currency");
	TransactionDetails.Add("DocumentAmount");
	TransactionDetails.Add("ReduceShipmentByReference");
	TransactionDetails.Add("Warehouse");
	TransactionDetails.Add("PriceKind");
	TransactionDetails.Add("SourseOfInformationAboutPricesForPrinting");
	
	TransactionDetails.Add("Goods.Price");
	TransactionDetails.Add("Goods.Sum");
	TransactionDetails.Add("Goods.Warehouse");
	
	Return TransactionDetails;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns an indication of the applicability of agreements with clients.
//
// Returns:
//	Boolean - a sign of the applicability of agreements with clients.
//
Function CustomerAgreementsAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns a flag for using agreements with clients.
//
// Returns:
//	Boolean - indicates the use of agreements with clients.
//
Function ToUseTermsOfSales() Export
	
	Return GetFunctionalOption("ToUseTermsOfSales");

EndFunction

#EndRegion

#Region Form

// Gets the default contract.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//
// Returns:
//	CatalogRef.CounterpartyContracts - the default value of the document Contract.
//
Function GetDefaultContract(Object) Export
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		Contract = SalesServer.GetDefaultContract(
					Object,
					ContractBusinessTransaction(),
					Undefined,
					Object.LineOfBusiness);
	Else
		Contract = SalesServer.GetDefaultContract(
					Object,
					ContractBusinessTransaction());
	EndIf;
	
	Return Contract;
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the client application.
//	Object - FormDataStructure - Document data.
//	Contract - CatalogRef.CounterpartyContracts, Undefined - the meaning of the Contract document.
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;
	
	SalesServer.SetContractAvailability(
		Object, Items.Contract.Enabled, Items.Contract.Visible, Contract);
	
EndProcedure

// Adjusts the form.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the client application.
//	Number - String - document number.
//	Date  - Date - document date.
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);
	
	Items.Partner.Title = NStr("vi = 'Khách hàng';
								|ru = 'Клиент';
								|en = 'Client'; fa = 'کلاینت';
								|it = 'Client';
								|pl = 'Client';
								|tr = 'Müşteri'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.SourseOfInformationAboutPricesForPrinting.Visible = True;
	Items.DocumentCurrency.Visible = True;
	Items.ReduceShipmentByReference.Visible = Form.ShipmentWithDeferredTransferOfTitle25;
	Items.Warehouse.Visible = Form.ShipmentWithDeferredTransferOfTitle25;
	Items.Warehouse.AutoMarkIncomplete = Form.ShipmentWithDeferredTransferOfTitle25;
	
	Items.GoodsFillInPricesUnderAgreement.Visible  = True;
	Items.Pages_Order.Visible           = Form.ShipmentWithDeferredTransferOfTitle25;
	Items.GoodsPickUpItemsByOrder.Visible = Form.ShipmentWithDeferredTransferOfTitle25;
	Items.GoodsUnlinkFromOrder.Visible         = Form.ShipmentWithDeferredTransferOfTitle25;
	Items.GoodsPurpose.Visible               = Not Form.ShipmentWithDeferredTransferOfTitle25;
	
	TitleText = NStr("vi = 'Chọn hàng hóa đã giao';
					|ru = 'Подобрать отгруженные товары';
					|en = 'Pick shipped goods'; fa = 'Pick shipped goods';
					|it = 'Pick shipped goods';
					|pl = 'Pick shipped goods';
					|tr = 'Sevk edilen ürünleri seç'");
	
	FormCommand = Form.Commands.Find("SelectTransferredGoods");
	FormCommand.Title = TitleText;
	FormCommand.ToolTip = TitleText;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//	Form  - ClientApplicationForm - client application.
//	Object - FormDataStructure - Document data.
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
	
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo khách hàng';
																		|ru = 'По клиенту';
																		|en = 'By customer'; fa = 'بر اساس مشتری';
																		|it = 'Per cliente';
																		|pl = 'Przez klienta';
																		|tr = 'Müşteriye göre'")));
	
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ArrayOfSelectParameterRelationships = New Array;
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("ARAPCurrency", "Object.Currency", LinkedValueChangeMode.Clear));
	
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	//Terms
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.ConsignmentSales25", False));
	
	ArrayOfSelectParameterRelationships = New Array;
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Date", "Object.Date", LinkedValueChangeMode.DontChange));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	Items.Terms.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Terms.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Products
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.ItemsType", Enums.ItemsTypes.OwnGoods));
	Items.GoodsProducts.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//	NewDocument - Boolean - indicates whether a new document has been created.
//	Number - String - document number.
//	Date - Date - Document date
//
// Returns:
//	String - title of the document form.
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluştur)'"), ObjectPresentation());
	Else
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 del %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), ObjectPresentation(), Number, Date);
	EndIf;
	
	Return Title;
	
EndFunction

// Returns the Presentation of the document.
//
// Returns:
//	String - presentation of the document.
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Ghi giảm hàng hóa đã giao cho khách';
				|ru = 'Списание товаров, отгруженных клиенту';
				|en = 'Write-off of goods shipped to customer'; fa = 'اسقاط کالاهای ارسال‌شده به مشتری';
				|it = 'Write-off of goods shipped to customer';
				|pl = 'Write-off of goods shipped to customer';
				|tr = 'Müşteriye sevk edilen ürünlerin gider yazılması'");
	
EndFunction

#EndRegion

#Region PrintForms

// Returns the synonym of the document used in the printed form "The act of debiting goods from the custodian".
//
// Returns:
//	String - A synonym for a printed Form document.
//
Function SynonymOfDocumentForPrintedFormReportOnWriteOffOfGoods() Export
	
	Return NStr("vi = 'Biên bản ghi giảm hàng hóa của khách hàng';
				|ru = 'Акт о списании товаров у клиента';
				|en = 'Stock shortage recognition at customer'; fa = 'Stock shortage recognition at customer';
				|it = 'Stock shortage recognition at customer';
				|pl = 'Stock shortage recognition at customer';
				|tr = 'Ürünlerin müşterinin tesisinden gider yazılmasına ilişkin rapor'");
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
