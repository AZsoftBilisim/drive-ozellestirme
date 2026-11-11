//////////////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Commission sales"
// related to the economic operation "Write-off of shortfalls at the expense of the commitee".
// 
//////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethodsForBusinessOperations

#Region Posting

// Returns parameters for filling in inventory types for the document "Write-off of shipped goods".
//
// Parameters:
// 	Object - DocumentObject.WriteOffOfShippedGoods
// Returns:
// 	See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByAgreementSettings");
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	
	AvailableStockTypes = New Array;
	AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
	AvailableStockTypes.Add(Enums.InventoryTypes.ConsignedGoods);
	
	SelectionOfStockTypes_.InventoryType = AvailableStockTypes;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToCommissionAgent;
	
EndFunction

// Returns a collection of object Attribute names available of operation.
//
// Returns:
//	Array of String - collection of object Attribute names available of operation.
//
Function TransactionDetails() Export
	
	TransactionDetails = New Array;
	TransactionDetails.Add("Currency");
	TransactionDetails.Add("DocumentAmount");
	TransactionDetails.Add("PriceKind");
	TransactionDetails.Add("SourseOfInformationAboutPricesForPrinting");
	TransactionDetails.Add("Goods.Price");
	TransactionDetails.Add("Goods.Sum");
	
	Return TransactionDetails;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return GetFunctionalOption("ToUseTermsOfSales");

EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//  Object - FormDataStructure - 
//
// Returns:
//  CatalogRef.CounterpartyContracts - 
//
Function GetDefaultContract(Object) Export
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		Contract = SalesServer.GetDefaultContract(
					Object, ContractBusinessTransaction(),Object.Currency, Object.LineOfBusiness, True);
	Else
		Contract = SalesServer.GetDefaultContract(
					Object, ContractBusinessTransaction(),Object.Currency,, True);
	EndIf;
	
	Return Contract;
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;
	Items.Contract.Enabled = True;
	Items.Contract.Visible = True;
	
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

	Items.Partner.Title = NStr("vi = 'Người nhận bán ký gửi';
								|ru = 'Комиссионер';
								|en = 'Consignee'; fa = 'امانت‌دار';
								|it = 'Commissionario';
								|pl = 'Consignee';
								|tr = 'Konsinye'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.SourseOfInformationAboutPricesForPrinting.Visible = False;
	Items.DocumentCurrency.Visible = True;
	Items.ReduceShipmentByReference.Visible = False;
	Items.Warehouse.Visible = False;
	Items.Warehouse.AutoMarkIncomplete = False;
	
	Items.GoodsFillInPricesUnderAgreement.Visible  = True;
	Items.Pages_Order.Visible           = False;
	Items.GoodsPickUpItemsByOrder.Visible = False;
	Items.GoodsUnlinkFromOrder.Visible         = False;
	
	TitleText = NStr("vi = 'Chọn hàng đã chuyển';
					|ru = 'Подобрать переданные товары';
					|en = 'Pick customer stock'; fa = 'انتخاب موجودی مشتری';
					|it = 'Selezionare le merci consegnate';
					|pl = 'Odbierz przeniesione wiersze pozycji';
					|tr = 'Transfer edilen malları seç'");
	
	FormCommand = Form.Commands.Find("SelectTransferredGoods");
	FormCommand.Title = TitleText;
	FormCommand.ToolTip = TitleText;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
			
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo người nhận ký gửi';
																		|ru = 'По комиссионеру';
																		|en = 'By consignee'; fa = 'By consignee';
																		|it = 'Per commissionario';
																		|pl = 'Według komisanta';
																		|tr = 'Konsinye üzerine'")));
			
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.ConsignmentSales25", True));

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
		New ChoiceParameter("Filter.ConsignmentSales25", True));
		
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
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//  NewDocument - Boolean - 
//  Number - Number - 
//  Date - Date - 
//
// Returns:
//  String - 
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluşturma)'"), ObjectPresentation());
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

// Returns the presentation of the document transfer of goods to the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Ghi giảm hàng hóa đã giao cho người nhận ký gửi';
				|ru = 'Списание товаров, отгруженных комиссионеру';
				|en = 'Write-off of goods shipped to consignee'; fa = 'Write-off of goods shipped to consignee';
				|it = 'Write-off of goods shipped to consignee';
				|pl = 'Write-off of goods shipped to consignee';
				|tr = 'Konsinyeye sevk edilen ürünlerin gider yazılması'");
	
EndFunction

#EndRegion

#Region PrintForms

// Returns the synonym of the document used in the written form "The act of writing off goods from the custodian"
//
// Returns:
//	String - A synonym for a printed Form document.
//
Function SynonymOfDocumentForPrintedFormReportOnWriteOffOfGoods() Export
	
	Return NStr("vi = 'Biên bản ghi giảm hàng hóa của người nhận ký gửi';
				|ru = 'Акт о списании товаров у комиссионера';
				|en = 'Stock adjustment recognition at consignee'; fa = 'Stock adjustment recognition at consignee';
				|it = 'Atto di storno articoli presso il commissionario';
				|pl = 'Protokół o rozchodzie towarów u komisanta';
				|tr = 'Konsinyeden malların silinmesine ilişkin rapor'");
	
EndFunction

#EndRegion

#EndRegion

#EndRegion
