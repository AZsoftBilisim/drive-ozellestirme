//////////////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Processing on the side"
// related to the economic operation "Write-off of goods from the processor".
// 
//////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region UnifiedMethods

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
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.MaterialOfMaterialProvider,     "ByAgreementSettings");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider, "ByAgreementSettings");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.ProductsOfMaterialProvider,    "ByAgreementSettings");
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SubcontractorProducts);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
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
	
	Return ProcessingByThirdParties.ContractBusinessTransaction();
	
EndFunction

// Returns a collection of object Attribute names available of operation.
//
// Returns:
//	Array of String - collection of object Attribute names available of operation.
//
Function TransactionDetails() Export
	
	TransactionDetails = New Array;
	TransactionDetails.Add("PriceKind");
	TransactionDetails.Add("SourseOfInformationAboutPricesForPrinting");
	
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
	
	Return ProcessingByThirdParties.CustomerAgreementsAreApplicable();
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return ProcessingByThirdParties.ToUseTermsOfSales();

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
	
	Return ProcessingByThirdParties.GetDefaultContract(Object);
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	ProcessingByThirdParties.SetContractAvailability(Form, Object, Contract);

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
	
	Items.Partner.Title = NStr("vi = 'Bên nhận gia công';
								|ru = 'Переработчик';
								|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
								|it = 'Subfornitore';
								|pl = 'Subcontractor';
								|tr = 'Fason üretici'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.SourseOfInformationAboutPricesForPrinting.Visible = True;
	Items.DocumentCurrency.Visible = False;
	Items.ReduceShipmentByReference.Visible = False;
	Items.Warehouse.Visible = False;
	Items.Warehouse.AutoMarkIncomplete = False;
	
	Items.GoodsFillInPricesUnderAgreement.Visible = False;
	Items.GoodsFillInCCDNumbers.Visible = False;
	
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
	
	ProcessingByThirdParties.AdjustItemSelectionSettings(Form, Object);
	
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
	
	Return NStr("vi = 'Bảng kê ghi giảm hàng hóa của người nhận gia công';
				|ru = 'Отчет о списании товаров у переработчика';
				|en = 'Subcontractor stock adjustment'; fa = 'تعدیل موجودی نزد پیمانکار فرعی';
				|it = 'Report sulla cancellazione degli articoli presso l''elaboratore';
				|pl = 'Raport o rozchodzie towarów u przetwórcy';
				|tr = 'Fason üreticide ürünlerin gider yazılmasına ilişkin rapor'");
	
EndFunction

#EndRegion

#Region PrintForms

// Returns the synonym of the document used in the printed form "The Stock shortage Recognition certificate from the custodian".
//
// Returns:
//	String - A synonym for a printed Form document.
//
Function SynonymOfDocumentForPrintedFormReportOnWriteOffOfGoods() Export
	
	Return NStr("vi = 'Biên bản ghi giảm hàng hóa của người nhận gia công';
				|ru = 'Акт о списании товаров у переработчика';
				|en = 'Recognition of subcontractor stock adjustment'; fa = 'Recognition of subcontractor stock adjustment';
				|it = 'Atto di storno articoli presso l''elaboratore';
				|pl = 'Protokół o rozchodzie towarów u przetwórcy';
				|tr = 'Fason üreticideki stok eksiği tahakkuku'");
	
EndFunction

#EndRegion

#EndRegion

#EndRegion