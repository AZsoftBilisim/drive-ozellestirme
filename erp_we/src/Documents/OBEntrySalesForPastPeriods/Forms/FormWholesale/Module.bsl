#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
		
	MultipleOrganizationsAreUsed = GetFunctionalOption("UseMultipleCompanies");
	If Not (MultipleOrganizationsAreUsed Or ValueIsFilled(Object.Organization)) Then
		Object.Organization = SettingsValueCached.GetDefaultOrganization();
	EndIf;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CurrencyRow = String(ManagementAccountingCurrency);
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	
	TitleLine = "%1 (%2)";
	TitlePrice = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Đơn giá';
																							|ru = 'Цена';
																							|en = 'Price'; fa = 'قیمت';
																							|it = 'Prezzo';
																							|pl = 'Cena';
																							|tr = 'Fiyat'"), CurrencyRow);
	HeaderAmount = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Tổng số';
																							|ru = 'Сумма';
																							|en = 'Amount'; fa = 'مبلغ';
																							|it = 'Importo';
																							|pl = 'Wartość';
																							|tr = 'Tutar'"), CurrencyRow);
	VATHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Thuế GTGT';
																						|ru = 'НДС';
																						|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
																						|it = 'IVA';
																						|pl = 'VAT';
																						|tr = 'KDV'"), CurrencyRow);
	Items.WholesaleSalesInPastPeriodsPrice.Title = TitlePrice;
	Items.WholesaleSalesInPastPeriodsSum.Title = HeaderAmount;
	Items.WholesaleSalesInPastPeriodsVATAmount.Title = VATHeader;
	
	SetTitleOfThisForm();
	SetPartnerSelectionParameters();
	NameOfTheCurrentFormTable = Items.WholesaleSalesInPastPeriods.Name;
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.WholesaleSalesInPastPeriods,ParametersForFillingInBankingDetails);
	SetConditionalAppearance();
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.WholesaleSalesInPastPeriods, ParametersForFillingInBankingDetails);
	SetTitleOfThisForm();
	
	FillInServiceDetailsForProductRange();
	WarehouseIsRequired = GetSignThatWarehouseIsFull(Object.WholesaleSalesInPastPeriods);
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CustomerTermsOfSalesStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.CustomerTermsOfSales;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.FormDataStructure        = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CustomerTermsOfSalesOnChange(Item)
	AgreementWithClientWhenChangingOnServer();
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOfChangeOnServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWholesaleSalesInPastPeriods

&AtClient
Procedure WholesaleSalesInPastPeriodsProductsOnChange(Item)
	
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, NameOfTheCurrentFormTable));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If Not ValueIsFilled(CurrentRow.VATRate) Then
		CurrentRow.VATRate = ProductItemVATRate(CurrentRow.Products);
	EndIf;
	PackageOnChange();
	
	WarehouseIsRequired = GetSignThatWarehouseIsFull(Object.WholesaleSalesInPastPeriods);
	
EndProcedure

&AtClient
Procedure WholesaleSalesInPastPeriodsPackageOnChange(Item)
	
	PackageOnChange();
	
EndProcedure

&AtClient
Procedure WholesaleQuantityOnChange(Item)

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure WholesaleSalesInPastPeriodsPriceOnChange(Item)

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure WholesaleSalesInPastPeriodsVATRateOnChange(Item)
	
	CurrentRow = Items.WholesaleSalesInPastPeriods.CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure WholesaleSalesInPastPeriodsSumOnChange(Item)

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure WholesaleSalesInPastPeriodsOnChange(Item)
	
	WarehouseIsRequired = GetSignThatWarehouseIsFull(Object.WholesaleSalesInPastPeriods);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.OBEntrySalesForPastPeriods.FormWholesale.Command.OpenSelection", True);
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'nhập số dư';
																			|ru = 'ввод остатков';
																			|en = 'balance entry'; fa = 'balance entry';
																			|it = 'inserimento dei saldi';
																			|pl = 'wpisanie zapasów';
																			|tr = 'bakiye girişleri'"));
	EndIf;

	FormParameters = New Structure;
	FormParameters.Insert("Terms",		Object.CustomerTermsOfSales);
	FormParameters.Insert("Currency",			Object.Currency);
	FormParameters.Insert("PriceIncludesVAT",	Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", False);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
	FormParameters.Insert("HideManualDiscounts", True);
	FormParameters.Insert("UseShipmentDates", False);
	FormParameters.Insert("HideTheItemPricesCommand", True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	FormParameters.Insert("ShowSelectedGoods", True);
	FormParameters.Insert("RequestQuantity", True);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date",      Object.Date);
	FormParameters.Insert("Document",  Object.Ref);
	FormParameters.Insert("WithoutFilterByVATInclusionInPrice", True);

	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetailsForProductRange();
	WarehouseIsRequired = GetSignThatWarehouseIsFull(Object.WholesaleSalesInPastPeriods);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("WhenChangingProductType", New Structure("ThereAreWorks, IsCanceled", True, False));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.WholesaleSalesInPastPeriods, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Function GetSignThatWarehouseIsFull(SalesTable)
	
	Return ?(SalesTable.Total("WarehouseIsRequired") = 0, 0, 1);
	
EndFunction

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "WholesaleSalesInPastPeriodsCharacteristic",
																			 "Object.WholesaleSalesInPastPeriods.ItemVariantsAreUsed");
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "WholesaleSalesInPastPeriodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.WholesaleSalesInPastPeriods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Counterparty.Name);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WholesaleSalesInPastPeriodsPackage.Name);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);

	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", Form.FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);

EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	RowsToProcess = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.WholesaleSalesInPastPeriods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		StringTSGoods.VATAmount = 0;
		RowsToProcess.Add(StringTSGoods);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.WholesaleSalesInPastPeriods,
		CachedValues);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.WholesaleSalesInPastPeriods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic, Package, NumberOfPackages, Price");
		CurrentRow.VATRate = ProductItemVATRate(CurrentRow.Products);
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.WholesaleSalesInPastPeriods,
		CachedValues);
		
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
											
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.WholesaleSalesInPastPeriods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServerNoContext
Function ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, DocumentDate)
	
	Return ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
											ManagementAccountingCurrency,
											LocalAccountingCurrency,
											?(DocumentDate = Date(1,1,1), CurrentSessionDate(), DocumentDate));
	
EndFunction

&AtClient
Procedure PackageOnChange()

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	EndIf;

	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtServerNoContext
Function ProductItemVATRate(Products)

	Return TMCommonUse.DefaultValuesForItemDetails(Products, "VATRate").VATRate;

EndFunction

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Object.Currency = LocalAccountingCurrency;
	
	If ValueIsFilled(Object.Organization) Then
		CompleteVATTaxation();
		VATTaxationOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	
	SettingsArray = New Array;
	SettingsArray.Add(True);
	ChoiceParameter = New ChoiceParameter("Filter.Client",New FixedArray(SettingsArray));
	ParametersArray = New Array;
	ParametersArray.Add(ChoiceParameter);
	Items.Partner.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

&AtServer
Procedure AgreementWithClientWhenChangingOnServer()
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.CustomerTermsOfSales, Object.Contract);
	EndIf;
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.WholesaleSalesInPastPeriods, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Object.Organization, Object.Date);
	Object.VATTaxation = AccountingParametersForOrganization.BasicTaxationVATSales;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
