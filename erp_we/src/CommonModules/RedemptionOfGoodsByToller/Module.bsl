//////////////////////////////////////////////////////////////////////
// Procedures and functions of the subsystem "Processing on the side"
// related to the economic operation "Repurchase of goods by the processor".
// 
//////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Returns parameters for filling in inventory types for the document "Transfer of goods to the custodian".
//
// Parameters:
//  Object - DocumentObject.RedemptionOfGoodsByCustodian - 
//
// Returns:
//  See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.MaterialOfMaterialProvider,     "Never");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider, "Never");
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.ProductsOfMaterialProvider,    "Never");
	FillParameters.SelectionOfStockTypes_.Organization = Object.Organization;
	
	FillParameters.SelectionOfStockTypes_.InventoryType = New Array;
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
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
//  Form - ClientApplicationForm - 
//  Number - Number - 
//  Date  - Date - 
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
	Items.GoodsFillThePricesByTermsOfSales.Visible = Items.Terms.Visible;
	Items.GoodsFillInCCDNumbers.Visible = False;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	ProcessingByThirdParties.AdjustItemSelectionSettings(Form, Object);
	
	// FAG
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.SettlementsWithSubcontractor", True));
	
	Form.Items.FinancialAccountingGroup.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
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

// Returns the document view
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Người nhận gia công mua lại hàng hóa';
				|ru = 'Выкуп товаров переработчиком';
				|en = 'Sales invoice — External subcontracting'; fa = 'فاکتور فروش — پیمانکاری فرعی خارجی';
				|it = 'Rimborso dei materiali da parte dell''elaboratore';
				|pl = 'Wykup towarów przez przetwórcę';
				|tr = 'Ürünlerin fason üretici tarafından geri alınması'");
	
EndFunction

#EndRegion

#EndRegion