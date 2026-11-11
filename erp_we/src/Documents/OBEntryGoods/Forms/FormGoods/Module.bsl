#Region Variables

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;

//used to pass the current line to the wait handler
&AtClient
Var CurDataId;

&AtClient
Var TimeConsumingOperationForm Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	LocalAccountingCurrency           = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency               = Constants.ManagementAccountingCurrency.Get();
	FactorOfConversionFromManCurrencyToRegulCurrency     = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	CurrencyRow                                = String(ManagementAccountingCurrency);
	InvoicesBasedOn_                  = VATAccountingERP.InvoicesReceivedOnLegalGrounds(Object.Ref);
	ThereAreTaxInvoicesForBasis              = InvoicesBasedOn_.Count() <> 0;
	UsePartnersAsCounterparties     = GetFunctionalOption("UsePartnersAsCounterparties");
	Items.PostInCostAccounting.Visible = CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Object.Date), True);
	
	TitleLine = "%1 (%2)";
	TitlePrice   = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Đơn giá';
																							|ru = 'Цена';
																							|en = 'Price'; fa = 'قیمت';
																							|it = 'Prezzo';
																							|pl = 'Cena';
																							|tr = 'Fiyat'"), CurrencyRow);
	HeaderAmount  = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Tổng số';
																							|ru = 'Сумма';
																							|en = 'Amount'; fa = 'مبلغ';
																							|it = 'Importo';
																							|pl = 'Wartość';
																							|tr = 'Tutar'"), CurrencyRow);
	VATHeader    = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Thuế GTGT';
																							|ru = 'НДС';
																							|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
																							|it = 'IVA';
																							|pl = 'VAT';
																							|tr = 'KDV'"), CurrencyRow);
	
	Items.OwnProductsPrice.Title     = TitlePrice;
	Items.TheirOwnProductsTheAmount.Title    = HeaderAmount;
	Items.OwnGoodsTheAmountOfVAT.Title = VATHeader;

	Items.ReceivedPackagePrice.Title  = TitlePrice;
	Items.ReceivedPackageSum.Title = HeaderAmount;

	Items.TransferredPackagePrice.Title  = TitlePrice;
	Items.TransferredPackageSum.Title = HeaderAmount;

	Items.ReceivedByCommissionAgentPrice.Title     = TitlePrice;
	Items.ReceivedForStoragePrice.Title     = TitlePrice;
	Items.ReceivedByCommissionAgentSum.Title    = HeaderAmount;
	Items.ReceivedForStorageSum.Title    = HeaderAmount;
	Items.ReceivedByCommissionAgentVATAmount.Title = VATHeader;
	
	Items.TransferOfTitleToGoodsPrice.Title = TitlePrice;
	Items.TransferOfTitleToGoodsSum.Title = HeaderAmount;
	
	Items.TransferredToCommissionAgentPrice.Title     = TitlePrice;
	Items.TransferredToCommission25Price.Title   = TitlePrice;
	Items.TransferredForStoragePrice.Title     = TitlePrice;
	Items.TransferredToCommissionAgentSum.Title    = HeaderAmount;
	Items.TransferredToCommission25Amount.Title  = HeaderAmount;
	Items.TransferredForStorageSum.Title    = HeaderAmount;
	Items.TransferredToCommissionAgentVATAmount.Title = VATHeader;
	Items.TransferredToCommission25VATAmount.Title = VATHeader;
	Items.TransferredForStorageVATAmount.Title  = VATHeader;
	
	Items.TransferredToTheProcessorsOfTheGoodsPrice.Title     = TitlePrice;
	Items.TransferredToTheProcessorsOfTheGoodsAmount.Title    = HeaderAmount;
	Items.TransferredToTheProcessorsOfGoodsTheAmountOfVAT.Title = VATHeader;
	
	Items.TransferredToTheManufactureOfTheGoodsAmount.Title    = HeaderAmount;
	Items.TransferredToTheManufactureOfTheGoodsTheAmountOfVAT.Title = VATHeader;
	Items.MaterialsAcceptedForProcessingPrice.Title  = TitlePrice;
	Items.MaterialsAcceptedForProcessingSum.Title = HeaderAmount;
	
	Items.SemiFinishedProductsGiverPrice.Title  = TitlePrice;
	Items.SemiFinishedProductsGiverSum.Title = HeaderAmount;
	Items.SemiFinishedProductsGiverPriceOffBalance.Title  = TitlePrice;
	Items.SemiFinishedProductsGiverSumOffBalance.Title = HeaderAmount;
	
	Items.ProductsOfMaterialProviderPrice.Title  = TitlePrice;
	Items.ProductsOfMaterialProviderSum.Title = HeaderAmount;
	Items.Basis.Visible = ValueIsFilled(Object.Basis);
	Items.OwnProductsFillInUsingBaseDocument.Visible = Items.Basis.Visible;
	
	// Headings of totals fields
	TitleLine = "%1 (%2)";
	TitleTotalTotal = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Tổng số gồm thuế GTGT';
																								|ru = 'Всего с НДС';
																								|en = 'Total including VAT'; fa = 'جمع با احتساب مالیات بر ارزش افزوده';
																								|it = 'Всего с НДС';
																								|pl = 'Suma brutto';
																								|tr = 'KDV dahil toplam'"), CurrencyRow);
	HeadingVATTotal   = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Thuế GTGT';
																								|ru = 'НДС';
																								|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
																								|it = 'НДС';
																								|pl = 'VAT';
																								|tr = 'KDV'"), CurrencyRow);
	
	Items.GoodsTotalAmountWithVAT.Title = TitleTotalTotal;
	Items.GoodsTotalVATAmount.Title  = HeadingVATTotal;
	
	SetTitleOfThisForm();
	
	If Not ValueIsFilled(Object.Ref) Then 
		
		If ValueIsFilled(Parameters.CopyingValue) Then
			Object.PriceIncludesVAT = Common.ObjectAttributeValue(Parameters.CopyingValue, "PriceIncludesVAT");			
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
			Object.PriceIncludesVAT = False;
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
			Object.PriceIncludesVAT = False;
		Else
			Object.PriceIncludesVAT = True;
		EndIf;
		
		OnReadCreateAtServer(Object);
		If ValueIsFilled(Object.Organization)
			And Not ValueIsFilled(Object.CorrectedDocument) Then
			OrganizationOnChangeServer();
		EndIf;
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		
	EndIf;
	
	ItIsMandatoryToFillInTheManager = (Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		And DivisionMaintainsSeparateAccountingForManagers(Object.Department));
	
	DivisionMustBeFilledIn = Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned;
	
	SetRequiredLotReferenceAttribute();
	
	SetAvailabilityOfClipboardCommands();
	
	TMCommonUse.CustomizePeripherals(
		ThisObject, "OwnProducts,ReceivedByCommissionAgent,ReceivedForStorage,TransferredToCommissionAgent,TransferredToCommissionAgent25,TransferredForStorage,ReceivedPackage,TransferredPackage,TransferToBinLocationWarehousing,GoodsTransferredToProduction");
	TMCommonUse.CustomizePeripherals(
		ThisObject, "MaterialsAcceptedForProcessing,GiverSSemiFinishedProducts,ProductsOfMaterialProvider");
	EstablishVisibilityOfRNPTQuantity();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If Object.Patch Then
		Items.OwnProductsFillInUsingBaseDocument.Visible = False;
		Items.OwnProductsFillInByBalance.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	ArrayOfElementsCCDNumber = New Array;
	ArrayOfElementsCCDNumber.Add("PrivateGoodsCustomsDeclarationNumber");
	ArrayOfElementsCCDNumber.Add("ReceivedByCommissionAgentCCDNumber");
	ArrayOfElementsCCDNumber.Add("TransferredToCommissionAgentCCDNumber");
	ArrayOfElementsCCDNumber.Add("ReceivedPackageCCDNumber");
	ArrayOfElementsCCDNumber.Add("TransferredPackageCCDNumber");
	ArrayOfElementsCCDNumber.Add("TransferredToTheProcessorsOfTheGoodsCustomsDeclarationNumber");
	ArrayOfElementsCCDNumber.Add("MaterialsAcceptedForProcessingCCDNumber");
	ArrayOfElementsCCDNumber.Add("GiverSSemiFinishedProductsCCDNumber");
	ArrayOfElementsCCDNumber.Add("ProductsOfMaterialProviderCCDNumber");
	ArrayOfElementsCCDNumber.Add("TransferredToCommission25CCDNumber");
	ArrayOfElementsCCDNumber.Add("TransferredForStorageCCDNumber");
	ArrayOfElementsCCDNumber.Add("ReceivedForStorageCCDNumber");
	ArrayOfElementsCCDNumber.Add("GoodsTransferredToProductionAreCCDNumber");
	ArrayOfElementsCCDNumber.Add("TransferOfTitleToGoodsCCDNumber");
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, ArrayOfElementsCCDNumber);
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer(CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		// StandardSubsystems.PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement("Document.OBEntryGoods.Form.FormGoods.Post");
		// End StandardSubsystems.PerformanceMeasurement
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	DocumentCorrectionClient.AfterWrite(Object);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	PresentationOfInvoiceReceived();
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
		New Structure("Products", "MeasuredValueType"));
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			ParametersForFillingInBankingDetails);
		
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	
	FillInDetailAttribute();
	
	SetTitleOfThisForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	FillInExcisableItemAttribute();
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues);
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		PresentationOfInvoiceReceived();
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		CurrentData = Items[NameOfTheCurrentFormTable].RowData(ValueSelected.CurrentRowID);
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource)
		And (ThisIsOwnStockBalance
			Or ThisIsRemainingReceivedPackage
			Or TheseAreRemainingTransferredPackages
			Or ThisIsStockBalanceTransferredToToller2_5
			Or ThisIsConsignedStockBalanceReceived
			Or TheseAreBalancesOfGoodsAcceptedForStorage
			Or ThisIsConsignedStockBalanceIssued
			Or ThisIsConsignedStockBalanceIssued2_5
			Or TheseAreBalancesOfGoodsTransferredForStorage
			Or TheseAreRemnantsOfShippedItems) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then
		Items.TransferToBinLocationWarehousingGoods.CurrentData.Purpose = ValueSelected;
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals

	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source)
		And (ThisIsOwnStockBalance
			Or ThisIsRemainingReceivedPackage
			Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or TheseAreBalancesOfOutputOfGiver2_5
			Or ThisIsStockBalanceTransferredToToller2_5
			Or ThisIsConsignedStockBalanceReceived
			Or TheseAreBalancesOfGoodsAcceptedForStorage
			Or ThisIsConsignedStockBalanceIssued
			Or ThisIsConsignedStockBalanceIssued2_5
			Or TheseAreBalancesOfGoodsTransferredForStorage
			Or TheseAreRemainingTransferredPackages
			Or ThisIsStockBalanceTransferredToProduction
			Or TheseAreRemnantsOfShippedItems) Then
		
		ParametersForSpecifyingCCDNumber = PurchasesClient.ParametersForSpecifyingCCDNumber();
		ParametersForSpecifyingCCDNumber.TSName = NameOfTheCurrentFormTable;
		
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, ParametersForSpecifyingCCDNumber, , Actions);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		If ByOrder And Not ValueIsFilled(Object.OrderDocument) Then
			Common.MessageToUser(NStr("vi = 'Chưa điền trường ""Đơn hàng"".';
										|ru = 'Поле ""Заказ"" не заполнено.';
										|en = 'The ""Order"" field is not filled.'; fa = 'The ""Order"" field is not filled.';
										|it = 'Campo ""Ordine"" non compilato.';
										|pl = 'Pole ""Zamówienie"" nie jest wypełnione.';
										|tr = '""Sipariş"" alanı doldurulmadı.'"),,, "Object.OrderDocument", Cancel);
		EndIf;
		
	EndIf;
	Return;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	ReflectInOperationalAccountingWhenChangesAreMadeOnServer();
EndProcedure

&AtClient
Procedure OwnProductsBatchOnChange(Item)
	OwnProductsBatchOnChangeServer();
	SetVisibility1();
EndProcedure

&AtClient
Procedure PostInCostAccountingOnChange(Item)
	ReflectCostOfChangeOnServer();
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordAITOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure ByOrderOnChange(Item)
	Items.TransferredToTheProcessorsOfGoodsTheOrderTheProcessor.Visible = ByOrder;
	If ByOrder Then
		If Object.Goods.Count() > 0
			And Not ThisIsStockBalanceTransferredToToller2_5 Then
			
			QueryText = NStr("vi = 'Sẽ xóa danh sách hàng hóa đã chuyển giao cho người nhận gia công. Tiếp tục?';
							|ru = 'Список переданных переработчику товаров будет очищен. Продолжить?';
							|en = 'External subcontracting stock will be cleared. Continue?'; fa = 'External subcontracting stock will be cleared. Continue?';
							|it = 'L''elenco delle merci consegnate al subfornitore verrà cancellato. Continuare?';
							|pl = 'Lista przekazanych do przetwórcy towarów będzie oczyszczona. Kontynuować?';
							|tr = 'Fason üreticiye transfer edilen ürünlerin listesi temizlenecektir. Devam edilsin mi?'");
			
			CallbackDescription = New CallbackDescription("ByOrderOnChangeCompletion", ThisObject);
											
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			
			Return;
				
		EndIf;
	Else
		Object.OrderDocument     = Undefined;
		OrderBeforeChange = Undefined;
		
		FillOutPurposeClientServer(ThisObject);
		
	EndIf;
	Return; // so that the method is not empty in the UT
	
EndProcedure

&AtClient
Procedure VATActivityTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = True;
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SubjectToExciseOnChange(Item)
	ExcisableGoodsAccountingClientServer.ConfigureProductionDivisionField(ThisObject);
	Return; // Not used in TM
EndProcedure

#Region TaxInvoice

&AtClient
Procedure TextInvoiceURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If ThisIsOwnStockBalance Then
		
		RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
		RegistrationParameters.Ref             = Object.Ref;
		RegistrationParameters.Date               = Object.Date;
		RegistrationParameters.Organization        = Object.Organization;
		RegistrationParameters.Counterparty         = Object.Counterparty;
		RegistrationParameters.VATTaxation = Object.VATTaxation;
		
		VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisObject, FormattedStringURL,  StandardProcessing, RegistrationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElementsPageTransferOfOwnership

&AtClient
Procedure TransferOfOwnershipDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipCompanyOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipPartnerOnChange(Item)
	
	PartnerOnChangeServer(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipContractOnChange(Item)
	
	FillInCurrencyAccordingToContract();
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipPriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipOfWarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersOwnProducts

&AtClient
Procedure OwnProductsDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	DateOnChangeServer();

EndProcedure

&AtClient
Procedure OwnProductsOrganizationOnChange(Item)

	OrganizationOnChangeServer();

EndProcedure

&AtClient
Procedure OwnProductsDivisionOnChange(Item)
	
	ItIsMandatoryToFillInTheManager = DivisionMaintainsSeparateAccountingForManagers(Object.Department);
	
EndProcedure

&AtClient
Procedure OwnProductsPartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure OwnProductsWarehouseOnChange(Item)

	WarehouseOnChangeServer();

EndProcedure

&AtClient
Procedure OwnProductsPremisesOnChange(Item)

	PremiseOnChangeServer();

EndProcedure

&AtClient
Procedure OwnProductsPriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure OwnProductsNomenclatureOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure OwnProductsNumberOfPackagesOnChange(Item)

	CountOnChange();

EndProcedure

&AtClient
Procedure OwnProductsPackagingOnChange(Item)

	PackageOnChange();

EndProcedure

&AtClient
Procedure OwnProductsPriceOnChange(Item)

	PriceOnChange();

EndProcedure

&AtClient
Procedure TheirOwnProductsTheAmountOnChange(Item)

	SumOnChange();

EndProcedure

&AtClient
Procedure OwnProductsVATRateOnChange(Item)

	VATRateOnChange();

EndProcedure

&AtClient
Procedure OwnProductsBeforeDeleteRow(Item, Cancel)

	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);

EndProcedure

&AtClient
Procedure OwnProductsAfterDeleteRow(Item)

	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure OwnProductsOnStartEdit(Item, NewRow, Copy)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);
				
	If NewRow Or Copy Then
		Item.CurrentData.RowID = New UUID;
		FillInAttributeThereIsDetailOfBatchesByLine(Item.CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnProductsOnEditEnd(Item, NewRow, CancelEdit, Cancel)

	TablePartAtEndOfEditing(Item);

EndProcedure

&AtClient
Procedure OwnProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure OwnProductsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.OwnProducts.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.OwnProducts.CurrentData.GetID();
	
	CurrentData = Items.OwnProducts.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

&AtClient
Procedure PrivateGoodsCustomsDeclarationNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure PrivateGoodsCustomsDeclarationNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OwnProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "OwnProductsBatchDetails" Then;
		
		OpenFormPartyDetails(RowSelected);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceivedPackage

&AtClient
Procedure AcceptedPackagingDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure AcceptedContainerOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ReceivedPackagePartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure AcceptedPackagingWarehouseOnChange(Item)

	WarehouseOnChangeServer();

EndProcedure

&AtClient
Procedure AcceptedPackagingRoomOnChange(Item)

	PremiseOnChangeServer();

EndProcedure

&AtClient
Procedure ReceivedPackageProductsOnChange(Item)

	ReturnablePackagingsProductsWhenChanged(Items.ReceivedPackage);

EndProcedure

&AtClient
Procedure ReceivedPackageNumberOfPackagesOnChange(Item)

	ReturnablePackagingQuantityWhenChanged(Items.ReceivedPackage);

EndProcedure

&AtClient
Procedure AcceptedPackagingPackagingOnChange(Item)

	ReturnablePackagingPackagingInCaseOfChange(Items.ReceivedPackage);

EndProcedure

&AtClient
Procedure ReceivedPackagePriceOnChange(Item)

	ReturnableTarePriceWhenChanged(Items.ReceivedPackage);

EndProcedure

&AtClient
Procedure ReceivedPackageSumOnChange(Item)

	ReturnableTareAmountWhenChanged(Items.ReceivedPackage);

EndProcedure

&AtClient
Procedure TheirOwnProductsTheAmountReglOnChange(Item)
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	
	StructureOfActions = New Structure;
	If Not (ThisIsRemainingReceivedPackage Or TheseAreRemainingTransferredPackages) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure ReceivedPackageCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure ReceivedPackageCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferredPackage

&AtClient
Procedure TransmittedContainerDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToTheTaraOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredContainerPartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure TransferredPackageProductsOnChange(Item)

	ReturnablePackagingsProductsWhenChanged(Items.TransferredPackage);

EndProcedure

&AtClient
Procedure TransferredPackageNumberOfPackagesOnChange(Item)

	CountOnChange();

EndProcedure

&AtClient
Procedure TransferredPackagingOnChange(Item)

	ReturnablePackagingPackagingInCaseOfChange(Items.TransferredPackage);

EndProcedure

&AtClient
Procedure TransferredPackagePriceOnChange(Item)

	ReturnableTarePriceWhenChanged(Items.TransferredPackage);

EndProcedure

&AtClient
Procedure TransferredPackageSumOnChange(Item)

	ReturnableTareAmountWhenChanged(Items.TransferredPackage);

EndProcedure

&AtClient
Procedure TransferredPackageCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure TransferredPackageCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceivedByCommissionAgent

&AtClient
Procedure ReceivedForCommissionDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure ReceivedForCommissionOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ReceivedForCommissionPartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure ReceivedCommissionToTheCounterpartyOnChange(Item)
	
	SetContractAvailability(Object.TermsOfConsignmentPurchase, Items.ReceivedOnTheCommissionAgreement.Enabled, Items.ReceivedOnTheCommissionAgreement.Visible, Object.Contract);
	
EndProcedure

&AtClient
Procedure ReceivedAtTheCommissionWarehouseOnChange(Item)

	WarehouseOnChangeServer();

EndProcedure

&AtClient
Procedure AgreementWithTheCommiteeReceivedForTheCommissionStartChoice(Item, ChoiceData, StandardProcessing)

	StructureOfAdditionalSelection = New Structure;
	StructureOfAdditionalSelection.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement"));
	PurchasesClient.StartSelectingSupplierAgreement(Item,
													StandardProcessing,
													Object.Partner,
													Object.TermsOfConsignmentPurchase,
													Object.Date,
													StructureOfAdditionalSelection);

EndProcedure

&AtClient
Procedure PremisesReceivedForCommissionOnChange(Item)

	PremiseOnChangeServer();

EndProcedure

&AtClient
Procedure AgreementWithTheCommiteeReceivedForTheCommissionOnChange(Item)

	FillInServerByAgreement();
	Items.CurrencyReceivedForCommission.ReadOnly = ValueIsFilled(Object.TermsOfConsignmentPurchase);
	Items.ReceivedOnCommissionVATTaxation.ReadOnly = ValueIsFilled(Object.TermsOfConsignmentPurchase);

EndProcedure

&AtClient
Procedure ThePriceReceivedForTheCommissionIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentProductsOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentPriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentSumOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentVATRateOnChange(Item)
	
	VATRateOnChange();
	
EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentBeforeDeleteRow(Item, Cancel)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);

EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);

EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentOnStartEdit(Item, NewRow, Copy)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);

EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentOnEditEnd(Item, NewRow, CancelEdit, Cancel)

	TablePartAtEndOfEditing(Item);

EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentNumberOfPackagesOnChange(Item)

	CurrentRow = Items.ReceivedByCommissionAgent.CurrentData;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If Not (ThisIsRemainingReceivedPackage Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure ReceivedForCommissionPackagingOnChange(Item)
	
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If Not (ThisIsRemainingReceivedPackage Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure ReceivedForCommissionSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure ReceivedForCommissionSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ReceivedByCommissionAgent.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ReceivedByCommissionAgent.CurrentData.GetID();
	
	CurrentData = Items.ReceivedByCommissionAgent.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure ReceivedByCommissionAgentCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferredToCommissionAgent

&AtClient
Procedure SubmittedForCommissionDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure SubmittedToTheCommissionOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToThePartnerCommissionOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure TransferredToTheCommissionCounterpartyOnChange(Item)
	
	SetContractAvailability(Object.TermsOfConsignmentSales, Items.SubmittedToTheCommissionAgreement.Enabled, Items.SubmittedToTheCommissionAgreement.Visible, Object.Contract);
	
EndProcedure

&AtClient
Procedure TransferredToTheCommissionAgreementWithTheCommissionAgentStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.TermsOfConsignmentSales;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.BusinessOperation       = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	AgreementSelectionParameters.FormDataStructure        = Object;
	AgreementSelectionParameters.ConsignmentSales25       = False;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure TransferredToTheCommissionPriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TransferredToCommissionAgentProductsOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommissionAgentNumberOfPackagesOnChange(Item)

	CountOnChange();

EndProcedure

&AtClient
Procedure SubmittedForCommissionPackagingOnChange(Item)

	PackageOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommissionAgentPriceOnChange(Item)

	PriceOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommissionAgentSumOnChange(Item)

	SumOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommissionAgentVATRateOnChange(Item)

	VATRateOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommissionAgentCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure TransferredToCommissionAgentCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TransferredToCommissionAgentSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "TransferredToCommissionAgentLotDetails" Then;
		
		OpenFormPartyDetails(RowSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferredToTheCommissionAgreementWithTheCommissionAgentOnChange(Item)
	FillInServerByAgreement();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferToBinLocationWarehousingGoods

&AtClient
Procedure SwitchingToAddressStorageDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure SwitchingToAddressableStorageWarehouseOnChange(Item)

	WarehouseOnChangeServer();

EndProcedure

&AtClient
Procedure SwitchingToAddressableStorageOnChange(Item)

	PremiseOnChangeServer();

EndProcedure

&AtClient
Procedure TheTransitionToAddressTheStorageOfGoodsNomenclatureOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure TheTransitionToAddressTheStorageOfGoodsPackagingOnChange(Item)

	CountOnChange();

EndProcedure

&AtClient
Procedure TransferToBinLocationWarehousingGoodsBeforeDeleteRow(Item, Cancel)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);

EndProcedure

&AtClient
Procedure TransferToBinLocationWarehousingGoodsOnStartEdit(Item, NewRow, Copy)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);

EndProcedure

&AtClient
Procedure TransferToBinLocationWarehousingGoodsOnEditEnd(Item, NewRow, CancelEdit, Cancel)

	TablePartAtEndOfEditing(Item);

EndProcedure

&AtClient
Procedure TransferToBinLocationWarehousingGoodsAfterDeleteRow(Item)

	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure SwitchingToAddressableStorageProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure SwitchingToAddressableStorageProductsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.TransferToBinLocationWarehousingGoods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.TransferToBinLocationWarehousingGoods.CurrentData.GetID();
	
	CurrentData = Items.TransferToBinLocationWarehousingGoods.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsTransferredToTollers

&AtClient
Procedure GoodsTransferredToTollersBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	
	Return; // so that the method is not empty in the UT
EndProcedure

&AtClient
Procedure GoodsTransferredToTollersOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToTollersOnEditEnd(Item, NewRow, CancelEdit)
	
	TablePartAtEndOfEditing(Item);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToTollersBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToTollersAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfTheGoodsDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProcessorsOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfGoodsTheOrderTheProcessorOnChange(Item)
	
	If OrderBeforeChange = Object.OrderDocument Then
		Return;
	EndIf;
		
	If Object.Goods.Count() > 0
		And Not ThisIsStockBalanceTransferredToToller2_5 Then
		
		QueryText = NStr("vi = 'Sẽ xóa danh sách hàng hóa đã chuyển giao cho người nhận gia công. Tiếp tục?';
						|ru = 'Список переданных переработчику товаров будет очищен. Продолжить?';
						|en = 'External subcontracting stock will be cleared. Continue?'; fa = 'External subcontracting stock will be cleared. Continue?';
						|it = 'L''elenco delle merci consegnate al subfornitore verrà cancellato. Continuare?';
						|pl = 'Lista przekazanych do przetwórcy towarów będzie oczyszczona. Kontynuować?';
						|tr = 'Fason üreticiye transfer edilen ürünlerin listesi temizlenecektir. Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("TransferredToTheProcessorsOfGoodsTheOrderTheProcessorOnChangeCompletion", 
										ThisObject, New Structure("ClearLines_", False));
										
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	GoodsTransferredToProcessorsOrderToProcessorWhenFragmentIsChanged(False);
	
EndProcedure

&AtClient
Procedure ProductsTransferredToProcessorsPartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfGoodsTheOrderTheProcessorOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    ClearLines_ = AdditionalParameters.ClearLines_;
    
    If QuestionResult = DialogReturnCode.No Then
        Object.OrderDocument = OrderBeforeChange;
        Return;
    Else
        ClearLines_ = True;
    EndIf;
    
    GoodsTransferredToProcessorsOrderToProcessorWhenFragmentIsChanged(ClearLines_);

EndProcedure

&AtClient
Procedure ByOrderOnChangeCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.No Then
		ByOrder = False;
		Items.TransferredToTheProcessorsOfGoodsTheOrderTheProcessor.Visible = False;
	Else
		Object.Goods.Clear();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProcessorsOrderToProcessorWhenFragmentIsChanged(Val ClearLines_)
	OrderToProcessorWhenServerChanges(ClearLines_);
	Return; // so that the method is not empty in the UT
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProcessorsSeriesOnChange(Item)
	
	CurrentData = Items.GoodsTransferredToTollers.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProcessorsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfGoodsThePriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfGoodsTheNumberOfPackagesOnChange(Item)

	CountOnChange();

EndProcedure

&AtClient
Procedure ProductsTransferredToProcessorsPackagingOnChange(Item)

	PackageOnChange();

EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfTheGoodsPriceOnChange(Item)

	PriceOnChange();

EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfTheGoodsAmountOnChange(Item)

	SumOnChange();

EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfGoodsTheVATRateOnChange(Item)
	
	VATRateOnChange();
	
EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfTheGoodsNomenclatureOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfTheGoodsCustomsDeclarationNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure TransferredToTheProcessorsOfTheGoodsCustomsDeclarationNumberCreating(Item, StandardProcessing)
	
	If ThisIsStockBalanceTransferredToToller2_5 Then
		CCDNumberCreating(Item, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsTransferredToTollersSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "TransferredToTheProcessorsOfTheGoodsDetailsOfTheParties" Then;
		
		OpenFormPartyDetails(RowSelected);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsTransferredToProduction

&AtClient
Procedure GoodsTransferredToProductionDivisionOnChange(Item)
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned") Then
		DepartmentOnChangeServer();
	EndIf; 
	Return;
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionOnEditEnd(Item, NewRow, CancelEdit)
	
	TablePartAtEndOfEditing(Item);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsTheDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsTheOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsThePriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsNomenclatureOnChange(Item)
	
	ProductsOnChange();
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsPackagingOnChange(Item)
	
	PackageOnChange();
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsAmountOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsVATRateOnChange(Item)
	
	VATRateOnChange();
	
EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsNumberOfPackagesOnChange(Item)

	CountOnChange();

EndProcedure

&AtClient
Procedure TransferredToTheManufactureOfTheGoodsPriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure ProductsTransferredToProductionSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.GoodsTransferredToProduction.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.GoodsTransferredToProduction.CurrentData.GetID();
	
	CurrentData = Items.GoodsTransferredToProduction.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsTransferredToProductionSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "TransferredToTheManufactureOfTheGoodsDetailsOfTheParties" Then;
		
		OpenFormPartyDetails(RowSelected);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAcceptedForProcessing

&AtClient
Procedure MaterialsAcceptedForProcessingDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingShouldBeReflectedInOperationalAccountingOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingReflectCostOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingReflectWorldBankAndTAOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingReflectVUOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsWarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsRoomOnChange(Item)
	
	PremiseOnChangeServer();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsPartnerOnChange(Item)
	
	PartnerOnChangeServer(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingCounterpartyOnChange(Item)
	
	CounterpartyOnChange();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingContractOnChange(Item)
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingByOrderOnChange(Item)
	
	ByOrderOnChangeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingOrderOnChange(Item)
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item, CachedValues, SeriesSpecificationParameters, Copy);
	
	If NewRow Or Copy Then
		Item.CurrentData.RowID = New UUID;
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingOnEditEnd(Item, NewRow, CancelEdit)
	
	TablePartAtEndOfEditing(Item);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingItemOnChange(Item)
	
	ProductsOnChange();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsSeriesOnChange(Item)
	
	SeriesOnChange();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure RecycledMaterialsNumberOfPackagesOnChange(Item)
	
	CountOnChange();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsPackagingOnChange(Item)
	
	PackageOnChange();
	
EndProcedure

&AtClient
Procedure RecycledMaterialsPriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingAmountOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure MaterialsAcceptedForProcessingCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionAreCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure GoodsTransferredToProductionAreCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGiverSSemiFinishedProducts

&AtClient
Procedure SemiFinishedProductsGiverDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsShouldBeReflectedInOperationalAccountingOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiveToReflectCostOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsOfGiverToReflectWBUiTAOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsOfGiverToReflectVUUOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverWarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverPremisesOnChange(Item)
	
	PremiseOnChangeServer();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverPartnerOnChange(Item)
	
	PartnerOnChangeServer(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverCounterpartyOnChange(Item)
	
	CounterpartyOnChange();
	
EndProcedure

&AtClient
Procedure GiverSSemiFinishedProductsContractOnChange(Item)
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverByOrderOnChange(Item)
	
	ByOrderOnChangeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverOrderOnChange(Item)
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure GiverSSemiFinishedProductsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item, CachedValues, SeriesSpecificationParameters, Copy);
	
	If NewRow Or Copy Then
		Item.CurrentData.RowID = New UUID;
	EndIf;
	
EndProcedure

&AtClient
Procedure GiverSSemiFinishedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	TablePartAtEndOfEditing(Item);
	
EndProcedure

&AtClient
Procedure GiverSSemiFinishedProductsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GiverSSemiFinishedProductsAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverItemOnChange(Item)
	
	ProductsOnChange();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverSeriesOnChange(Item)
	
	SeriesOnChange();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiversNumberOfPackagesOnChange(Item)
	
	CountOnChange();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiversPackagingOnChange(Item)
	
	PackageOnChange();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverPriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverSumOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverPriceOffBalanceOnChange(Item)
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSuffixAmount", "OffBalance");
	StructureOfActions.Insert("RecalculateLocalOffBalanceAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Return;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverSumOffBalanceOnChange(Item)
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateOffBalancePriceByOffBalanceAmount", "Count");
	StructureOfActions.Insert("RecalculateLocalOffBalanceAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Return;
	
EndProcedure

&AtClient
Procedure SemiFinishedProductsGiverCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure GiverSSemiFinishedProductsCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProductsOfMaterialProvider

&AtClient
Procedure GiverSProductsDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure GiverSProductsOrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure GiverSProductsAreReflectedInOperationalAccountingOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure GiverSProductsReflectCostPriceOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure ProductionOfGiverToReflectWBUiTAOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure ProductionOfGiverToReflectVUUOnChange(Item)
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure GiverSProductsWarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure GiverSProductsPremisesOnChange(Item)
	
	PremiseOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerGiverProductsOnChange(Item)
	
	PartnerOnChangeServer(Object.Partner, Object.Counterparty);
	
EndProcedure

&AtClient
Procedure GiverSProductsCounterpartyOnChange(Item)
	
	CounterpartyOnChange();
	
EndProcedure

&AtClient
Procedure GiverSProductsContractOnChange(Item)
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure GiverSProductsOnRequestOnChange(Item)
	
	ByOrderOnChangeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure GiverSProductsOrderOnChange(Item)
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure

&AtClient
Procedure ProductsOfMaterialProviderOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item, CachedValues, SeriesSpecificationParameters, Copy);
	
	If NewRow Or Copy Then
		Item.CurrentData.RowID = New UUID;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsOfMaterialProviderOnEditEnd(Item, NewRow, CancelEdit)
	
	TablePartAtEndOfEditing(Item);
	
EndProcedure

&AtClient
Procedure ProductsOfMaterialProviderBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure ProductsOfMaterialProviderAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure GiverSMANUFACTUREDProductsItemListOnChange(Item)
	
	ProductsOnChange();
	
EndProcedure

&AtClient
Procedure GiverSProductsSeriesOnChange(Item)
	
	SeriesOnChange();
	
EndProcedure

&AtClient
Procedure GiverSProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GiverSMANUFACTUREDProductsNumberOfPackagesOnChange(Item)
	
	CountOnChange();
	
EndProcedure

&AtClient
Procedure GiverSProductsPackagingOnChange(Item)
	
	PackageOnChange();
	
EndProcedure

&AtClient
Procedure GiverSMANUFACTUREDProductsPriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure GiverSManufacturingProductsAmountOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure GiverSMANUFACTUREDProductsAreCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure ProductsOfMaterialProviderCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferredToCommissionAgent2_5

&AtClient
Procedure TransferredToCommission25DateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToCommission25CompanyOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TransferredToCommission25PartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure TransferredToCommission25AgreementWithCommissionAgentStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.TermsOfConsignmentSales;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.BusinessOperation       = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	AgreementSelectionParameters.FormDataStructure        = Object;
	AgreementSelectionParameters.ConsignmentSales25       = True;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure _25TransferredToCommissionPriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TransferredToCommission25AgreementWithCommissionAgentOnChange(Item)
	FillInServerByAgreement();
EndProcedure

&AtClient
Procedure SubmittedToCommission25ItemsOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommission25NumberOfPackagingUnitsOnChange(Item)


	CountOnChange();

EndProcedure

&AtClient
Procedure TransferredForCommission25PackagingUnitsOnChange(Item)

	PackageOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommission25PriceOnChange(Item)

	PriceOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommission25AmountOnChange(Item)

	SumOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommission25VATRateOnChange(Item)

	VATRateOnChange();

EndProcedure

&AtClient
Procedure TransferredToCommission25CCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure TransferredToCommission25CCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TransferredToCommission25Choice(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "TransferredToCommissionAgentLotDetails" Then;
		
		OpenFormPartyDetails(RowSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure _25GoodsSubmittedForCommissionBatchStartOfSelection(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure _25GoodsBatchTransferredToCommissionUponChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = Items.TransferredToCommissionAgent.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.TransferredToCommissionAgent.CurrentData.GetID();
	
	CurrentData = Items.TransferredToCommissionAgent.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferredForStorage

&AtClient
Procedure DepositedDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepositedByCompanyOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepositedWithPartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure DepositedAgreementWithCustodianOnChange(Item)
	FillInServerByAgreement();
EndProcedure

&AtClient
Procedure DepositedAgreementWithCustodianStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.CustomerTermsOfSales;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.BusinessOperation       = PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	AgreementSelectionParameters.FormDataStructure        = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DepositedPriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure DepositedItemsOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure NumberOfPackagesTransferredForStorageOnChange(Item)


	CountOnChange();

EndProcedure

&AtClient
Procedure TransferredToStoragePackagingUnitsInCaseOfChange(Item)

	PackageOnChange();

EndProcedure

&AtClient
Procedure TransferredToStoragePriceOnChange(Item)

	PriceOnChange();

EndProcedure

&AtClient
Procedure DepositedAmountOnChange(Item)

	SumOnChange();

EndProcedure

&AtClient
Procedure DepositedVATRateOnChange(Item)

	VATRateOnChange();

EndProcedure

&AtClient
Procedure CCDNumberTransferredForStorageOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure TransferredForStorageCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TransferredForStorageSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "TransferredForStorageLotDetails" Then;
		
		OpenFormPartyDetails(RowSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsTransferredForStorageBatchStartOfSelection(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsTransferredForStorageBatchWhenChanged(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = Items.TransferredToCommissionAgent.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.TransferredToCommissionAgent.CurrentData.GetID();
	
	CurrentData = Items.TransferredToCommissionAgent.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReceivedForStorage

&AtClient
Procedure ReceivedForStorageDateOnChange(Item)
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure ReceivedForStorageByCompanyOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ReceivedForStorageByPartnerOnChange(Item)

	PartnerOnChangeServer(Object.Partner, Object.Counterparty);

EndProcedure

&AtClient
Procedure ReceivedForStorageWarehouseOnChange(Item)

	WarehouseOnChangeServer();

EndProcedure

&AtClient
Procedure ReceivedForSafekeepingAgreementWithCommitteeStartChoice(Item, ChoiceData, StandardProcessing)

	StructureOfAdditionalSelection = New Structure;
	StructureOfAdditionalSelection.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale"));
	PurchasesClient.StartSelectingSupplierAgreement(Item,
													StandardProcessing,
													Object.Partner,
													Object.TermsOfConsignmentPurchase,
													Object.Date,
													StructureOfAdditionalSelection);

EndProcedure

&AtClient
Procedure ReceivedForSafekeepingAgreementWithCommitteeOnChange(Item)
	
	If ValueIsFilled(Object.TermsOfConsignmentPurchase) Then
		FillInServerByAgreement();
		OnChangeCurrencyOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractReceivedForStorageOnChange(Item)
	
	FillInCurrencyAccordingToContract();
	
EndProcedure

&AtClient
Procedure ReceivedStorageSpaceOnChange(Item)

	PremiseOnChangeServer();

EndProcedure

&AtClient
Procedure CurrencyReceivedForStorageOnChange(Item)
	
	OnChangeCurrencyOnServer();
	
EndProcedure

&AtClient
Procedure ReceivedForStorageItemOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure ReceivedForStoragePriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure AmountReceivedForStorageOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure ReceivedForStorageBeforeDeleteRow(Item, Cancel)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);

EndProcedure

&AtClient
Procedure ReceivedForStorageAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);

EndProcedure

&AtClient
Procedure ReceivedForStorageOnStartEdit(Item, NewRow, Copy)

	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);

EndProcedure

&AtClient
Procedure ReceivedForStorageOnEditEnd(Item, NewRow, CancelEdit, Cancel)

	TablePartAtEndOfEditing(Item);

EndProcedure

&AtClient
Procedure NumberOfPackagesReceivedForStorageOnChange(Item)
	
	CountOnChange();
	
EndProcedure

&AtClient
Procedure ReceivedForStoragePackagingUnitsOnChange(Item)
	
	PackageOnChange();

EndProcedure

&AtClient
Procedure ReceivedForStorageBatchStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure ReceivedForStorageBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = Items.ReceivedForStorage.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ReceivedForStorage.CurrentData.GetID();
	
	CurrentData = Items.ReceivedForStorage.CurrentData;
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

&AtClient
Procedure CCDNumberReceivedForStorageOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure ReceivedForStorageCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransferOfTitleToGoods

&AtClient
Procedure TransferOfTitleToGoodsAfterDeleteRow(Item)
	
	TablePartAfterDeletion(Item);
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	TablePartAtEndOfEditing(Item);
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters,
		Copy);
	
	If NewRow Or Copy Then
		Item.CurrentData.RowCode = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsProductsOnChange(Item)

	ProductsOnChange();

EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsNumberOfPackagesOnChange(Item)
	
	CountOnChange();
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsPriceOnChange(Item)
	
	PriceOnChange();
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsSumOnChange(Item)
	
	SumOnChange();
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	CurrentData = Items.TransferOfTitleToGoods.CurrentData;
	
	ValueSelected.Value = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(
		ThisObject,
		SeriesSpecificationParameters,
		ValueSelected,
		CurrentData);
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipBatchStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure TransferOfOwnershipOfPackagingUnitOnChange(Item)
	
	PackageOnChange();
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsCCDNumberOnChange(Item)
	
	CCDNumberOnChange(Item);
	
EndProcedure

&AtClient
Procedure TransferOfTitleToGoodsCCDNumberCreating(Item, StandardProcessing)
	
	CCDNumberCreating(Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVariances

&AtClient
Procedure DeviationsDateOnChange(Item)
	DateOnChangeServer();
EndProcedure

&AtClient
Procedure DeviationsCompanyOnChange(Item)
	OrganizationOnChangeServer();
EndProcedure

&AtClient
Procedure VariancesProductsOnChange(Item)
	ProductsOnChange();
EndProcedure

&AtClient
Procedure VariancesSumOnChange(Item)
	SumOnChange();
EndProcedure

&AtClient
Procedure VariancesVATRateOnChange(Item)
	VATRateOnChange();
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
Procedure SpecifySeries(Command)

	OpenSelectionOfSeries();

EndProcedure

&AtClient
Procedure SpecifyTheSeriesReceivedForTheCommission(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SpecifyBatchesReceivedForStorage(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SpecifyTheTransitionToAddressableStorageSeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SplitRow(Command)

	FormTable  = Items[NameOfTheCurrentFormTable];
	TableData = Object.Goods;
	
	AdditionalParameters = New Structure;
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(
								FormTable.CurrentData, AdditionalParameters);
		
	EndIf;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)

	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.OBEntryGoods.FormGoods.Command.OpenSelection");
	
	Cancel = False;
	
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
	FormParameters.Insert("Terms", Object.TermsOfConsignmentSales);
	FormParameters.Insert("Currency", ManagementAccountingCurrency);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", ThisIsConsignedStockBalanceReceived Or TheseAreBalancesOfGoodsAcceptedForStorage);
	
	If TheseAreRemainingTransferredPackages
		Or ThisIsRemainingReceivedPackage Then
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		FormParameters.Insert("FilterByProductType", ArrayOfProductTypes);
		
	Else
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		
		If Not TheseAreRemnantsOfShippedItems Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		EndIf;
		
		If ThisIsStockBalanceTransferredToProduction
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or False Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		If TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or TheseAreBalancesOfOutputOfGiver2_5 Then
			FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
		EndIf;
		FormParameters.Insert("FilterByProductType", ArrayOfProductTypes);
		
	EndIf;
	
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
	FormParameters.Insert("HideManualDiscounts", True);
	FormParameters.Insert("UseShipmentDates", False);
	FormParameters.Insert("HideTheItemPricesCommand", True);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	FormParameters.Insert("ShowSelectedGoods", True);
	FormParameters.Insert("RequestQuantity", True);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Document", Object.Ref);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.OwnProducts) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.OwnProducts.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure FillOutWithStockBalanceNotInBins(Command)
	FillOutWithStockBalanceNotInBinsServer();
EndProcedure

&AtClient
Procedure FillOutAnEmptyWareroomWithStockBalance(Command)
	FillOutAnEmptyWareroomWithStockBalanceServer();
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.ImportCCD  = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	If TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
	 Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
	 Or TheseAreBalancesOfOutputOfGiver2_5 Then
		ImportParameters.AmountsRecalculate = False;
	EndIf;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
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
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	If Object.Goods.Count() Then
		AlertQuestionFillInByBalances = New CallbackDescription("AlertHandlerIssueFillInByBalances", ThisObject);
		QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại của phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'При заполнении текущие данные табличной части будут очищены. Продолжить?';
						|en = 'Current table data will be cleared. Continue?'; fa = 'Current table data will be cleared. Continue?';
						|it = 'I dati correnti della parte tabulare verranno cancellati durante la compilazione. Continuare?';
						|pl = 'Przy wypełnieniu bieżące dane części tabelarycznej będą oczyszczone. Kontynuować?';
						|tr = 'Tablo bölümünün mevcut verileri tamamlandığında silinecektir. Devam edilsin mi?'");
		ShowQueryBox(AlertQuestionFillInByBalances, QueryText, QuestionDialogMode.YesNo,,,  NStr("vi = 'Nhập số dư kế toán theo hoạt động';
																								|ru = 'Ввод остатков регл. учета по данным оперативного';
																								|en = 'Enter local accounting balance according to real-time accounting data'; fa = 'Enter local accounting balance according to real-time accounting data';
																								|it = 'Immissione delle rimanenze della contabilità regolamentare in base ai dati di contabilità operativa';
																								|pl = 'Wprowadzenie ostatków ewidencji reglamentowanej według danych operacyjnej';
																								|tr = 'Operasyonel verilere dayalı olarak yerel muhasebe bakiyelerinin girilmesi'"));
	Else
		
		// StandardSubsystems.PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.OBEntryGoods.Form.FormGoods.FillInByBalance");
		// End StandardSubsystems.PerformanceMeasurement
		
		FillByBalancesOnServer();
		
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure FillInUsingBaseDocument(Command)
	
	FillInBasedOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForCommissionPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStoragePackagingUnits.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfOwnershipOfPackagingUnit.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.AcceptedPackagingPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TheTransitionToAddressTheStorageOfGoodsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.RecycledMaterialsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.SemiFinishedProductsGiversPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiverSProductsPackaging.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.Goods.Package", Undefined, DataCompositionComparisonType.NotFilled);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.Goods.ItemsType", Enums.ItemsTypes.OwnGoods);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForCommissionPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStoragePackagingUnits.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfOwnershipOfPackagingUnit.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.AcceptedPackagingPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TheTransitionToAddressTheStorageOfGoodsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.RecycledMaterialsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.SemiFinishedProductsGiversPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiverSProductsPackaging.Name);
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "UseBinLocationWarehousing", False);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.Goods.ItemsType", 
		Enums.ItemsTypes.OwnGoods, DataCompositionComparisonType.NotEqual);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.Goods.MeasuredValueType",
		Enums.TypesOfMeasuredValues.NumberOfPieces, DataCompositionComparisonType.NotEqual);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.Goods.Package",, DataCompositionComparisonType.Filled);
		
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Removes the check mark for filling in the "Packaging" props
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.SubmittedForCommissionPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredForCommission25PackagingUnits.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToStoragePackagingUnits.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ProductsTransferredToProcessorsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheManufactureOfTheGoodsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.RecycledMaterialsPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.SemiFinishedProductsGiversPackaging.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiverSProductsPackaging.Name);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "OwnProductsFeature");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "ReceivedByCommissionAgentCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "ReceivedForStorageCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "TransferOfTitleToGoodsCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "TransferredToCommissionAgentCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "TransferredToCommission25Characteristics");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "TransferredForStorageCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "ReceivedPackageCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "TransferredPackageCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "SwitchingToAddressableStorageProductsCharacteristics");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "ProductsTransferredToProcessorsCharacteristics");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "TransferredToTheManufactureOfTheGoodsCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, "VariancesCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "MaterialsAcceptedForProcessingCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "GiverSSemiFinishedProductsCharacteristic");
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, "ProductsOfMaterialProviderCharacteristic");
	//
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "PrivateGoodsCustomsDeclarationNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ReceivedByCommissionAgentCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ReceivedForStorageCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferOfTitleToGoodsCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredToCommissionAgentCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredToCommission25CCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredForStorageCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ReceivedPackageCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredPackageCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredToTheProcessorsOfTheGoodsCustomsDeclarationNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsTransferredToProductionAreCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "MaterialsAcceptedForProcessingCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GiverSSemiFinishedProductsCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ProductsOfMaterialProviderCCDNumber";
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "PrivateGoodsCustomsDeclarationNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ReceivedByCommissionAgentCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ReceivedForStorageCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferOfTitleToGoodsCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredToCommissionAgentCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredToCommission25CCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredForStorageCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ReceivedPackageCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredToTheProcessorsOfTheGoodsCustomsDeclarationNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "TransferredPackageCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsTransferredToProductionAreCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "MaterialsAcceptedForProcessingCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GiverSSemiFinishedProductsCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "ProductsOfMaterialProviderCCDNumber";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	ConditionalDesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "TheAmountReceivedForTheCommissionUnderTheRNPT";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "ReceivedForTheCommissionNomenclatureUnitOfMeasurementTNVED";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "AmountOfProductBatchIDReceivedForStorage";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "ItemReceivedForStorageIsUnitOfFEA";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
																						
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "TransferOfOwnershipOfAmountOfProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "TransferOfOwnershipItemUnitOfCustomsCodeOfEconomicActivity";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
																						
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "GoodsTransferredToProcessorsAreQuantityAccordingToProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "GoodsTransferredToProcessorsItemUnitOfFEA";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "TheAmountTransferredToTheCommissionAccordingToTheRNPT";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "SubmittedToTheCommissionNomenclatureUnitOfMeasurementOfTheFEA";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "AmountTransferredToCommissionIs25AccordingToProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "SubmittedToCommission25ItemOfUnitOfFEA";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
																						
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "AmountTransferredForStorageAccordingToProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "TransferredToStorageItemUnitOfFEA";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
																						
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "AcceptedContainerQuantityAccordingToProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "AcceptedPackagingItemUnitOfHS";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "TransferredContainerQuantityAccordingToProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "TransferredContainerItemUnitTaxCode";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	DesignParameters = AccountingForTraceableGoodsLocalization.ParametersForSettingConditionalRegistrationOfQuantityAccordingToRNPT();
	DesignParameters.NameOfInputFieldQuantityByRNPT          = "MaterialsAcceptedForProcessingQuantityAccordingToRNPT";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "MaterialsAcceptedForProcessingProductUnitOfMeasurementOfFEA";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject, DesignParameters);
	
	DesignParameters.NameOfInputFieldQuantityByRNPT          = "SemiFinishedProductsGiversQuantityAccordingToRNPT";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "SemiFinishedProductsGiverProductUnitOfMeasurementFEA";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject, DesignParameters);
	
	DesignParameters.NameOfInputFieldQuantityByRNPT          = "GiverSProductsQuantityAccordingToRNPT";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "GiverSProductsProductUnitOfMeasurementTNVED";
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject, DesignParameters);
	ConditionalDesignParameters.NameOfInputFieldQuantityByRNPT = "GoodsPutIntoProductionQuantityAccordingToProductBatchID";
	ConditionalDesignParameters.FieldNameUnitOfMeasurementFEA = "GoodsPutIntoProductionItemUnitOfFEA";
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject,
																						ConditionalDesignParameters);
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceInDocumentEnteringItemBalances(ThisObject,
													"GoodsTransferredToProductionAreCCDNumber",
													"GoodsPutIntoProductionQuantityAccordingToProductBatchID",
													"GoodsPutIntoProductionItemUnitOfFEA");
	
	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "ReceivedForStorageItemUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TransferOfOwnershipItemUnit";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "SubmittedToCommission25ItemUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TransferredToStorageItemUnit";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "OwnProductsNomenclatureUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TheCommissionReceivedTheItemUnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TransferredToTheCommissionNomenclatureUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "ReceivedPackageProductsUnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TransferredPackagingItemUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TheTransitionToAddressTheStorageOfGoodsItemUnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "TransferredToTheProcessorsOfGoodsItemUnitOfMeasure";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GoodsTransferredToProductionNomenclatureUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAcceptedForProcessingProductUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "SemiFinishedProductsGiverProductUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "GiverSProductsProductUnitOfMeasurement";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPartner.Name);
	
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse);
	ValueList.Add(Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", ValueList, DataCompositionComparisonType.InList);

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPartner.Name);

	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.AndGroup);
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.BusinessOperation", ValueList, DataCompositionComparisonType.InList);
	DataCompositionClientServer.AddFilter(FilterGroup, "PartnersAndCounterpartiesSeparately", False);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.Partner", Undefined, DataCompositionComparisonType.NotFilled);
	DataCompositionClientServer.AddFilter(FilterGroup, "ThereAreTaxInvoicesForBasis", True);

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheCommissionCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommission25Counterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.DepositedByCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedCommissionToTheCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStorageByCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfOwnershipCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.AcceptedPackagingCounterparty.Name);

	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
	ValueList = New ValueList;
	ValueList.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse);
	ValueList.Add(Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse);
	ValueList.Add(Enums.BusinessTransactions.EnterRemainingReceivedVMI);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.BusinessOperation", ValueList, DataCompositionComparisonType.NotInList);
	DataCompositionClientServer.AddFilter(FilterGroup, "ThereAreTaxInvoicesForBasis", False);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedCommissionToTheCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStorageByCounterparty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfOwnershipCounterparty.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.Counterparty", Undefined, DataCompositionComparisonType.NotFilled);
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.BusinessOperation",
		Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse,
		DataCompositionComparisonType.Equal);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.VATTaxation", Enums.VATTaxationTypes.ByActualUsage, DataCompositionComparisonType.Equal);
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "OwnProductsSeries");	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "ReceivedForCommissionSeries");	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "ReceivedForStorageBatch");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "TransferOfOwnershipBatch");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "TransferredToCommission25Batch");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "DepositedBatches");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "SwitchingToAddressableStorageProductsSeries");	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "GoodsTransferredToProcessorsSeries");	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "ProductsTransferredToProductionSeries");	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "RecycledMaterialsSeries");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "SemiFinishedProductsGiverSeries");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False, "GiverSProductsSeries");
	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "OwnProductsStatusOfTheSpecifiedSeries");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "ReceivedTheCommissionOfTheStatusIndicationOfTheSeries");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "StatusOfBatchInstructionsReceivedForStorage");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "TransferOfOwnershipStatusOfBatchIndication");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "TheTransitionToAddressTheStorageOfGoodsStatusIndicationOfTheSeries");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "GoodsTransferredToProcessorsStatusOfSeriesIndication");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "ProductsThatHaveBeenPutIntoProductionTheStatusOfIndicatingTheSeries");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "MaterialsAcceptedForProcessingStatusOfSeriesIndication");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "SemiFinishedProductsGiverStatusIndicationOfSeries");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False, "GiverSProductsStatusOfIndicationOfSeries");
	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedPackagePrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedPackageSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedPackageSumCompl.Name);

	DataCompositionClientServer.AddFilter(Item.Filter, "Object.Goods.DepositForPackageIsRequired", False);

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedPackagePrice.Name);

	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.AndGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.Goods.DepositForPackageIsRequired", True);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.Goods.Price", Undefined, DataCompositionComparisonType.NotFilled);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedByCommissionAgentPrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedByCommissionAgentSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedByCommissionAgentSumCompl.Name);

	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse);

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//

	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStoragePrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStorageSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStorageSumCompl.Name);

	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfTitleToGoodsPrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfTitleToGoodsSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfTitleToGoodsSumCompl.Name);

	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", Enums.BusinessTransactions.EnterRemainingReceivedVMI);

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "GoodsTransferredToProductionDivision", "Object.Department", "DivisionMustBeFilledIn");
		
	SetConditionalDesignOfDivisionInHeader();

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "OwnProductsPurpose");
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "ReceivedPackagePurpose");
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "TheTransitionToAddressTheStorageOfGoodsAssignment");
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "TransferredToTheProcessorsOfTheGoodsPurpose");
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject, "TransferredToTheManufactureOfTheGoodsPurpose");
																		  
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsAmountWithVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedByCommissionAgentAmountIncludingVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommissionAgentAmountIncludingVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommission25AmountWithVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredForStorageAmountIncludingVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GoodsTransferredToProcessorsAmountWithVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheManufactureOfTheGoodsTheAmountSNDS.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.PriceIncludesVAT", True);

	Item.Appearance.SetParameterValue("Visible", False);
	
	//

	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "OwnProductsManager", "Object.Manager", "ItIsMandatoryToFillInTheManager");
		
	SetConditionalRegistrationManagerInHeader();
	
	// Removing the blank mark in the "Regulated" accounting section
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPremises.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.PremisesReceivedForCommission.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedStorageSpace.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.AcceptedPackagingRoom.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.RecycledMaterialsRoom.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.SemiFinishedProductsGiverPremises.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiverSProductsPremises.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsVATRate.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedByCommissionAgentVATRate.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommissionAgentVATRate.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommission25VATRate.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheProcessorsOfGoodsTheVATRate.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheManufactureOfTheGoodsVATRate.Name);
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPartner.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForCommissionPartner.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForStorageByPartner.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferOfOwnershipPartner.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedPackagePartner.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ProductsTransferredToProcessorsPartner.Name);
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.CurrencyReceivedForCommission.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.CurrencyReceivedForStorage.Name);
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.AgreementWithTheCommiteeReceivedForTheCommission.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedForSafekeepingAgreementWithCommittee.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheCommissionAgreementWithTheCommissionAgent.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommission25AgreementWithCommissionAgent.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.DepositedAgreementWithCustodian.Name);
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheProcessorsOfGoodsTheOrderTheProcessor.Name);
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OwnProductsPrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TheirOwnProductsTheAmount.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommissionAgentPrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommission25Price.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredForStoragePrice.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommissionAgentSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToCommission25Amount.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredForStorageSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredPackagePrice.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.RecordInOperationalAccounting", False);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The processor's contract is mandatory for version 2.5
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GoodsTransferredToProcessorsContract.Name);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"Object.BusinessOperation",
		Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"Object.Contract",,
		DataCompositionComparisonType.NotFilled);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	NamesOfTablesByOperations = New Map;
	
	NamesOfTablesByOperations.Insert(
		Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting,
		Items.MaterialsAcceptedForProcessing.Name);
	
	NamesOfTablesByOperations.Insert(
		Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider,
		Items.GiverSSemiFinishedProducts.Name);
	
	NamesOfTablesByOperations.Insert(
		Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider,
		Items.ProductsOfMaterialProvider.Name);
	
	For Each TableName In NamesOfTablesByOperations Do
		
		NameOfContractField = StrTemplate("%1Contract", TableName.Value);
		
		Item = ConditionalAppearance.Items.Add();
		
		DataCompositionClientServer.AddFieldToCreate(Item.Fields, NameOfContractField);
		
		DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", TableName.Key);
		DataCompositionClientServer.AddFilter(Item.Filter,"Object.Contract",, DataCompositionComparisonType.NotFilled);
			
		Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		//
		
		NameOfDestinationField = StrTemplate("%1Purpose", TableName.Value);
		
		Item = ConditionalAppearance.Items.Add();
		
		DataCompositionClientServer.AddFieldToCreate(Item.Fields, NameOfDestinationField);
		
		DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", TableName.Key);
		
		Item.Appearance.SetParameterValue("Text",          New DataCompositionField("Purpose"));
		Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		FieldNameOrder = StrTemplate("%1OrderDocument", TableName.Value);
		
		Item = ConditionalAppearance.Items.Add();
		
		DataCompositionClientServer.AddFieldToCreate(Item.Fields, FieldNameOrder);
		
		DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", TableName.Key);
		DataCompositionClientServer.AddFilter(Item.Filter, "ByOrder", True);
		DataCompositionClientServer.AddFilter(Item.Filter, "Object.OrderDocument",, DataCompositionComparisonType.NotFilled);
		
		Item.Appearance.SetParameterValue("MarkIncomplete", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		
		DataCompositionClientServer.AddFieldToCreate(Item.Fields, FieldNameOrder);
		
		DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", TableName.Key);
		
		SelectionGroupOr = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
		DataCompositionClientServer.AddFilter(SelectionGroupOr, "ByOrder", False);
		DataCompositionClientServer.AddFilter(SelectionGroupOr, "Object.OrderDocument",, DataCompositionComparisonType.Filled);
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndDo;
	// When separating by orders, the assignment is filled with the assignment of the order
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.TransferredToTheProcessorsOfTheGoodsPurpose.Name);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"ByOrder",
		True);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"Object.OrderDocument",,
		DataCompositionComparisonType.Filled);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"Object.BusinessOperation",
		Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"OboblyatOnAppointmentOfOrderToProcessor",
		True);
	
	Item.Appearance.SetParameterValue("Text",          New DataCompositionField("Purpose"));
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	SetConditionalAppearanceOfLotReferenceInHeader();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.RecycledMaterialsBatch.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.SemiFinishedProductsGiverParty.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.GiverSProductsBatch.Name);
	
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"CostEvaluationMethod",
		Enums.InventoryValuationMethods.FIFORollingValuation,
		DataCompositionComparisonType.NotEqual);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The off-balance sheet value of the semi-finished products of the giver is not used for work
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsGiverPriceOffBalance.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsGiverSumOffBalance.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SemiFinishedProductsGiverAmountOfLocalOffBalance.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = '<đối với hàng hóa>';
															|ru = '<для товаров>';
															|en = '<for goods>'; fa = '<for goods>';
															|it = '<per le merci>';
															|pl = '<dla towarów>';
															|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedOnTheCommissionAgreement.Name);

	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"Object.TermsOfConsignmentPurchase",,
		DataCompositionComparisonType.Filled);
		
	DataCompositionClientServer.AddFilter(
		Item.Filter,
		"Object.ReceivedOnTheCommissionAgreement",,
		DataCompositionComparisonType.NotFilled);
		
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ReceivedOnTheCommissionAgreement.Name);
	
	SelectionGroupOr = DataCompositionClientServer.AddSelectionGroup(
		Item.Filter.Items,
		DataCompositionFilterItemsGroupType.OrGroup);
		
	DataCompositionClientServer.AddFilter(
		SelectionGroupOr,
		"Object.TermsOfConsignmentPurchase",,
		DataCompositionComparisonType.NotFilled);
		
	DataCompositionClientServer.AddFilter(
		SelectionGroupOr,
		"Object.ReceivedOnTheCommissionAgreement",,
		DataCompositionComparisonType.Filled);
		
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	SetConditionalAppearanceOfContractInHeader();

EndProcedure

#Region CommonEventHandlersForTableParts

&AtClient
Procedure ProductsOnChange(CurrentRowID = Undefined)
	
	If CurrentRowID <> Undefined Then
		CurrentRow = Object.Goods.FindByID(CurrentRowID);
	Else
		CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	If UseExcisableGoods Then
		StructureOfActions.Insert("FillInExcisableItemAttribute",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
		
	EndIf;
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters", Object[SeriesSpecificationParameters.WarehouseFieldName], SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, NameOfTheCurrentFormTable)); 
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If Not ValueIsFilled(CurrentRow.VATRate) Or CurrentRowID = Undefined Then
		CurrentRow.VATRate = ProductItemVATRate(CurrentRow.Products, Object.Organization, Object.VATTaxation, Object.Date, Object.BusinessOperation);
	EndIf;
	
	If Not CurrentRow.TheRecordsAreKeptByCCD
		And Not CurrentRow.AccountingForTheRNPTIsMaintained Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
	EndIf;
	
	PackageOnChange(CurrentRowID);
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
EndProcedure

&AtClient
Procedure CountOnChange()

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));
	StructureOfActions.Insert("RecalculateAmount");
	If TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateSuffixAmount", "OffBalance");
	ElsIf Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
		
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateLocalOffBalanceAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	EndIf;
	If Not (ThisIsRemainingReceivedPackage
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PackageOnChange(CurrentRowID = Undefined)

	If CurrentRowID <> Undefined Then
		CurrentRow = Object.Goods.FindByID(CurrentRowID);
	Else
		CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	EndIf;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));

	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		If TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
			StructureOfActions.Insert("RecalculatePriceOffBalancePerPackage", CurrentRow.Count);
		EndIf;
	EndIf;

	StructureOfActions.Insert("RecalculateAmount");
	If TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateSuffixAmount", "OffBalance");
	ElsIf Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateLocalOffBalanceAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	EndIf;
	If Not (ThisIsRemainingReceivedPackage
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PriceOnChange()

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	If Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
	   And Not TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
	   And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	
	If Not (ThisIsRemainingReceivedPackage
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SumOnChange()

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	
	StructureOfActions = New Structure;
	If Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
	   And Not TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
	   And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	
	If Not (ThisIsRemainingReceivedPackage
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure VATRateOnChange()

	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If Not (ThisIsRemainingReceivedPackage Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure TablePartAtEndOfEditing(Item)

	CurrentData = Item.CurrentData;

	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then

		IDCurrentRow = CurrentData.GetID();

		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
	EndIf;

EndProcedure

&AtClient
Procedure TablePartAfterDeletion(Item)

	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters,True) Then

		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);

	EndIf;
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
EndProcedure

#EndRegion

#Region CommonEventHandlersForTablePartsOfReturnContainers

&AtClient
Procedure ReturnablePackagingsProductsWhenChanged(TablePart)
	
	CurrentRow = TablePart.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, TablePart.Name));
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ReturnablePackagingQuantityWhenChanged(TablePart)

	CurrentRow = TablePart.CurrentData;

	StructureOfActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");

	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If Not (ThisIsRemainingReceivedPackage Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ReturnablePackagingPackagingInCaseOfChange(TablePart)

	CurrentRow = TablePart.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	EndIf;

	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure ReturnableTarePriceWhenChanged(TablePart)

	PriceOnChange();

EndProcedure

&AtClient
Procedure ReturnableTareAmountWhenChanged(TablePart)

	CurrentRow = TablePart.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtServerNoContext
Function ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, DocumentDate)
	
	Return ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
											ManagementAccountingCurrency,
											LocalAccountingCurrency,
											?(DocumentDate = Date(1,1,1), CurrentSessionDate(), DocumentDate));
	
EndFunction

&AtServer
Procedure OrganizationOnChangeServer()

	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	
	If ValueIsFilled(Object.Organization) Then
		PresentationOfInvoiceReceived();
		Documents.OBEntryGoods.FillInTypeOfActivityVAT(Object, ThisObject, True);
		CompleteVATTaxation();
		VATTaxationOnChangeServer();
		GetMethodForEstimatingValueOfGoods();
		SetRequiredLotReferenceAttribute();
		RecalculateNumberOfRNPT();
		Object.Currency = LocalAccountingCurrency;
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		RecalculateNumberOfRNPT();
	ElsIf TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		  Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		  Or TheseAreBalancesOfOutputOfGiver2_5 Then
		
		If Not ValueIsFilled(Object.Organization) Then
			RecalculateNumberOfRNPT();
		EndIf;
		
		FillOutPurposeClientServer(ThisObject);
	EndIf;
	
	UpdateAvailabilityOfContractByAgreement(Object);
	FillInExcisableItemAttribute();
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
	SetVisibility1();

EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OBEntryGoods));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	SetVisibility1();
	Documents.OBEntryGoods.FillInTypeOfActivityVAT(Object, ThisObject, True);
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	GetMethodForEstimatingValueOfGoods();
	EstablishVisibilityOfRNPTQuantity();
	
	If Not Items.OwnProductsGroupQuantityByRNPT.Visible
		Or Not Items.MaterialsAcceptedForProcessingGroupQuantityAccordingToRNPT.Visible
		Or Not Items.SemiFinishedProductsGiversGroupQuantityAccordingToRNPT.Visible
		Or Not Items.GiverSProductsGroupQuantityAccordingToRNPT.Visible
		Or Not Items.ReceivedForTheCommissionGroupAmountOnTheRNPT.Visible
		Or Not Items.GroupReceivedForStorageIsAmountAccordingToProductBatchID.Visible
		Or Not Items.TransferredToTheCommissionGroupQuantityAccordingToTheRNPT.Visible
		Or Not Items.TransferredToCommission25GroupQuantityByProductBatchID.Visible
		Or Not Items.TransferredToStorageGroupQuantityAccordingToProductBatchID.Visible Then
		
		RecalculateNumberOfRNPT();
		
	EndIf;
	FillInExcisableItemAttribute();
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer(Partner, Counterparty)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	PresentationOfInvoiceReceived();

	If Object.Partner <> Partner Then
		Object.Partner = Partner;
	EndIf;
	
	If Object.Counterparty <> Counterparty Then
		Object.Counterparty = Counterparty;
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
	 	
		CounterpartyOnChangeServer();
		
	EndIf;
	UpdateAvailabilityOfContractByAgreement(Object);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange()
	If TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
	 Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
	 Or TheseAreBalancesOfOutputOfGiver2_5 Then
		
		CounterpartyOnChangeServer();
		
	EndIf;
	Return;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ByOrderOnChangeClientServer(Form)
	Object   = Form.Object;
	Items = Form.Items;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting") Then
		
		OrderElement = Items.MaterialsAcceptedForProcessingOrder;
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider") Then
		
		OrderElement = Items.SemiFinishedProductsGiverOrder;
		
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider") Then
		
		OrderElement = Items.GiverSProductsOrder;
		
	Else
		Return;
	EndIf;
	
	OrderElement.Enabled = Form.ByOrder;
	
	If Not Form.ByOrder Then
		
		Object.OrderDocument = Undefined;
		
		FillOutPurposeClientServer(Form);
		
	EndIf;
	Return;
	
EndProcedure
&AtServer
Procedure CounterpartyOnChangeServer()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	
	Object.Contract = PurchasesServer.GetDefaultContract(
						Object, TollingSchemeClientServer.ContractBusinessTransaction(), AddlParameters);
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure
&AtServer
Procedure WarehouseOnChangeServer()

	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise));
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OBEntryGoods));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	Documents.OBEntryGoods.FillInTypeOfActivityVAT(Object, ThisObject, True);
	
	If ThisIsTransitionToBinLocationWarehousing 
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		
		Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Object.Warehouse, Object.Premise, Object.ReceivingArea);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
			
			Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Object.Warehouse, Object.Premise, Object.ReceivingArea);
			
			FillOutPurposeClientServer(ThisObject);
	EndIf;
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date, True);
	
	SetVisibility1();
	SetVisibilityOfAcceptanceArea();
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure OwnProductsBatchOnChangeServer()
	
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()

	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		SetFormFunctionalOptionParameters(New Structure("Department", Object.Department));
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OBEntryGoods));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		SetVisibility1();
	EndIf; 
	
EndProcedure
&AtServer
Procedure PremiseOnChangeServer()

	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise", Object.Warehouse, Object.Premise));
	
	If ThisIsTransitionToBinLocationWarehousing
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		
		Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(Object.Warehouse, Object.Premise, Object.ReceivingArea);
		
	EndIf;
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date, True);
	
	SetVisibilityOfAcceptanceArea();
	
EndProcedure

&AtServer
Procedure FillInServerByAgreement()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
		
		DocumentBusinessTransaction = Object.BusinessOperation;
		
		Attributes = PurchasesServer.GetPurchaseTermsAndConditions(Object.TermsOfConsignmentPurchase);
		
		If ValueIsFilled(Attributes.Organization)
			And Attributes.Organization <> Object.Organization Then
			
			Object.Organization = Attributes.Organization;
			
		EndIf;
		
		If ValueIsFilled(Attributes.Warehouse)
			And Attributes.Warehouse <> Object.Warehouse Then
			Object.Warehouse = Attributes.Warehouse;
			Object.BusinessOperation = DocumentBusinessTransaction;
			SetParametersForSelectingWarehousePremises();
			SetVisibility1();
			WarehouseOnChangeServer();
		EndIf;
		
		FillPropertyValues(Object, Attributes,, "Warehouse, Organization, BusinessOperation");
		
	EndIf;
	
	UpdateAvailabilityOfContractByAgreement(Object);
	
EndProcedure

&AtServer
Procedure OrderToProcessorWhenServerChanges(ClearLines_)
	
	OrderBeforeChange = Object.OrderDocument;
	
	If Object.Goods.Count() > 0 And ClearLines_ Then
		Object.Goods.Clear();
	EndIf;
	
	FillOutPurposeClientServer(ThisObject);
	
EndProcedure
&AtServerNoContext
Function ProductItemVATRate(Products, Organization, VATTaxation, Date, BusinessOperation = Undefined)
	If BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
	 Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
	 Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		Return Catalogs.VATRates.EmptyRef();
	EndIf;
	VATRate = VATAccountingERP.VATRateForProductsAndTaxation(
							Products,
							VATTaxation,
							Organization,
							Date);
	Return VATRate;
	
EndFunction

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	StructureOfActions = New Structure;
	If Not Object.PriceIncludesVAT Then
		For Each Page1 In Object.Goods Do
			Page1.AmountExcludingVAT = Page1.Sum;
		EndDo;
	Else
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SeriesOnChange()
	
	CurrentData = Items[NameOfTheCurrentFormTable].CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value					 = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected, CurrentData);

EndProcedure

&AtServer
Procedure OnChangeCurrencyOnServer()
	
	If ValueIsFilled(Object.TermsOfConsignmentPurchase) Then
		AgreementCurrency = Common.ObjectAttributeValue(Object.TermsOfConsignmentPurchase, "Currency");
		If AgreementCurrency <> Object.Currency Then
			Object.TermsOfConsignmentPurchase = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Contract) Then
		ContractCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
		If ContractCurrency <> Object.Currency Then
			Contract = Catalogs.CounterpartyContracts.EmptyRef();
			Object.Contract = Contract;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCurrencyAccordingToContract()
	
	If ValueIsFilled(Object.Contract) Then
		ContractCurrency = Common.ObjectAttributeValue(Object.Contract, "ARAPCurrency");
		If ContractCurrency <> Object.Currency Then
			Object.Currency = ContractCurrency;
			OnChangeCurrencyOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReflectInOperationalAccountingWhenChangesAreMadeOnServer()
	SetVisibility1();
	SetRequiredLotReferenceAttribute();
	SetRequiredContractAttribute();
EndProcedure

&AtServer
Procedure ReflectCostOfChangeOnServer()
	SetVisibility1();
	SetRequiredLotReferenceAttribute();
	SetRequiredContractAttribute();
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	If Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		And Not TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes								 = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters				 = SeriesSpecificationParameters;
	AddVerificationOfAbilityToAddProducts(StructureOfActions);
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);

	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		CollectionElement = Items[NameOfTheCurrentFormTable]; // FormTable
		
		CollectionElement.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	
EndProcedure

&AtClient
Procedure AddVerificationOfAbilityToAddProducts(StructureOfActions)
	
	If ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages Then
		
		StructureOfActions.OnlyTara = True;
		
	ElsIf ThisIsStockBalanceTransferredToProduction Then
		StructureOfActions.OnlyGoodsAndWork = True;
	Else
		StructureOfActions.GoodsOnly = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	TableBox = Items[NameOfTheCurrentFormTable];
	
	If CurrentData = Undefined Then
		
		CurrentData = TableBox.CurrentData;
		If CurrentData = Undefined Then
			MessageText = NStr("vi = 'Chọn dòng sản phẩm mà bạn cần chỉ ra sê-ri.';
								|ru = 'Выберите строку товаров, для которой необходимо указать серии.';
								|en = 'Select a goods line for which the batch shall be specified.'; fa = 'Select a goods line for which the batch shall be specified.';
								|it = 'Selezionare la riga dei prodotti per la quale è necessario specificare le serie.';
								|pl = 'Wybierz wiersz towarów, dla których chcesz określić serie.';
								|tr = 'Partisini belirtmek istediğiniz mal satırını seçin.'");
			ShowMessageBox(Undefined, MessageText);
			Return;
		EndIf;
		
	EndIf;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text,CurrentData) Then
		
		CurDataId = CurrentData.GetID();
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisObject,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	ReturnValue_1 = Result;
	
	If ReturnValue_1 <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)

	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)

	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);

EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, ThisObject);
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm, StructureOfActions);
	
EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items[NameOfTheCurrentFormTable].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RowID = CurrentData.GetID();
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	CCDNumbersFilledIn = False;
	CCDNumber = Undefined;
	
	ProcessIndicationOfCCDNumberServer(RowID, CalculationResult1, CCDNumbersFilledIn, CCDNumber);
	
	PurchasesClient.NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber);
	
EndProcedure

&AtServer
Procedure ProcessIndicationOfCCDNumberServer(RowID,
											CalculationResult1,
											CCDNumbersFilledIn,
											CCDNumber)
	
	SelectionData_1	= GetFromTempStorage(CalculationResult1.AddressInTempStorage);
	CCDNumber		= ?(SelectionData_1.ResidualNumberOfCCD <> Undefined,
						CCDNumber,
						SelectionData_1.MainNumberOfCCD);
	
	CCDNumberSelectionParameters = PurchasesServer.CCDNumberSelectionParameters();
	CCDNumberSelectionParameters.FormTableName = NameOfTheCurrentFormTable;
	
	ProcessingActions = New Structure;
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, ThisObject);
	Else
		If ThisIsOwnStockBalance
			Or ThisIsRemainingReceivedPackage
			Or TheseAreRemainingTransferredPackages
			Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or TheseAreBalancesOfOutputOfGiver2_5
			Or ThisIsStockBalanceTransferredToToller2_5
			Or ThisIsConsignedStockBalanceReceived
			Or TheseAreBalancesOfGoodsAcceptedForStorage
			Or ThisIsConsignedStockBalanceIssued
			Or ThisIsConsignedStockBalanceIssued2_5
			Or TheseAreBalancesOfGoodsTransferredForStorage
			Or TheseAreRemnantsOfShippedItems Then
			
			AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
				Object,
				ProcessingActions);
			
		EndIf;
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												CCDNumberSelectionParameters,
												ProcessingActions);
	
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentRow;
	
	If CurrentRow <> Undefined Then
		FillInAttributeThereIsDetailOfBatchesByLine(CurrentRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure CCDNumberOnChange(Item)
	
	CurrentData = Items[NameOfTheCurrentFormTable].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure CCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items[NameOfTheCurrentFormTable].CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.DocumentCurrency = ManagementAccountingCurrency;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

#EndRegion

#Region Purpose

&AtClientAtServerNoContext
Procedure FillOutPurposeClientServer(Form)
	Object = Form.Object;
	
	SourceDestination     = Undefined;
	AttributeNamePurpose = "Purpose";
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5")
	 Or False Then
		
		If ValueIsFilled(Object.OrderDocument) Then
			SourceDestination = Object.OrderDocument;
		EndIf;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting")
		  Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider")
		  Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider") Then
		
		SourceDestination = ?(ValueIsFilled(Object.OrderDocument), Object.OrderDocument, Object.Contract);
		
		If ValueIsFilled(Object.OrderDocument)
		   And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting") Then
			AttributeNamePurpose = "AssignmentMaterials";
		EndIf;
	Else
		Return;
	EndIf;
	
	If ValueIsFilled(SourceDestination) Then
		Form.Purpose = GeneralPurposeTMServerCall.ObjectAttributeValue(SourceDestination, AttributeNamePurpose);
	Else
		Form.Purpose = Undefined;
	EndIf;
	Return;
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.OwnProducts.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products, Characteristic, Package, NumberOfPackages";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));
	If UseExcisableGoods Then
		StructureOfActions.Insert("FillInExcisableItemAttribute",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.VATRate = ProductItemVATRate(CurrentRow.Products,
			Object.Organization, Object.VATTaxation, Object.Date, Object.BusinessOperation);
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillParameters = New Structure();
	FillParameters.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	FillParameters.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	FillParameters.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	FillParameters.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	FillParameters.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillParameters);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("OwnProductsInsertRows");
	ItemArray.Add("OwnProductsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, 
		ItemArray,
		"Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("OwnProductsInsertRows");
	ItemArray.Add("OwnProductsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer(ObjectData)
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(
		ObjectData.Warehouse, ObjectData.Premise, ObjectData.Date, True);
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(ObjectData, Documents.OBEntryGoods));
	
	If ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned Then
		SetFormFunctionalOptionParameters(New Structure("Department", ObjectData.Department));
	Else
		SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise",ObjectData.Warehouse, ObjectData.Premise));
	EndIf;

	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
		And (ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingSentToCustomers
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
			Or ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods);
	OboblyatOnAppointmentOfOrderToProcessor =
		Constants.SubcontractorOptionOfAssignment2_5.Get() =
			Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder;
	TypesOfCommodityMovementOperations = Documents.OBEntryGoods.InitializeEconomicOperationOfCommodityMovement(ObjectData);
	FillPropertyValues(ThisObject, TypesOfCommodityMovementOperations);
	
	ByOrder         = ValueIsFilled(ObjectData.OrderDocument);
	OrderBeforeChange = ObjectData.OrderDocument;
	
	Items.GroupByOrder.Visible =
		ThisIsStockBalanceTransferredToToller2_5
			And OboblyatOnAppointmentOfOrderToProcessor
		Or False;
	
	Items.TransferredToTheProcessorsOfGoodsTheOrderTheProcessor.Visible = ByOrder;
	If GetFunctionalOption("UseMaterialProviderOrder2_5") Then
		
		Items.MaterialsAcceptedForProcessingGroupByOrder.Visible =
			TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			And Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Get() =
				Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder;
		
		Items.SemiFinishedProductsGiversGroupByOrder.Visible =
			TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			And Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Get() =
				Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder;
		
		Items.GiverSProductsAreGroupByOrder.Visible =
			TheseAreBalancesOfOutputOfGiver2_5
			And Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Get() =
				Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder;
		
		ByOrderOnChangeClientServer(ThisObject);
		
	EndIf;
	AdvancedWarehousesAreUsed = GetFunctionalOption("UseWarehouseManagementSystem");
	
	GetMethodForEstimatingValueOfGoods();
	
	SetVisibility1();
	SetParametersForSelectingWarehousePremises();
	SetStockTypeSelectionParameters();
	SetPartnerSelectionParameters();
	SetContractSelectionParameters();
	SetOrderSelectionParameters();
	LimitOrderType();
	SetProductSelectionParameters();
	
	Documents.OBEntryGoods.FillInTypeOfActivityVAT(ObjectData, ThisObject);
	CompleteVATTaxation();
	
	UpdateAvailabilityOfContractByAgreement(ObjectData);
	Items.CurrencyReceivedForCommission.ReadOnly             = ValueIsFilled(ObjectData.TermsOfConsignmentPurchase);
	Items.ReceivedOnCommissionVATTaxation.ReadOnly = ValueIsFilled(ObjectData.TermsOfConsignmentPurchase);
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
		New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
		New Structure("Products", "MeasuredValueType"));
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	
	PresentationOfInvoiceReceived();
	FillInDetailAttribute();
	AdvancedWarehousesAreUsed = GetFunctionalOption("UseWarehouseManagementSystem");
	UseExcisableGoods = ThisIsOwnStockBalance
		And GetFunctionalOption("UseExcisableGoods");
	FillInExcisableItemAttribute();
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, Object.Ref.IsEmpty());
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, CachedValues)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));
	StructureOfActions.Insert("RecalculateAmount");
	If Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		And Not TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If Not (ThisIsRemainingReceivedPackage
			Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or TheseAreBalancesOfOutputOfGiver2_5
			Or TheseAreRemainingTransferredPackages) Then
			StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	If Object.PriceIncludesVAT Then
		StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If UseExcisableGoods Then
		StructureOfActions.Insert("FillInExcisableItemAttribute",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
	EndIf;
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic, Package, NumberOfPackages, Price");
		CurrentRow.VATRate = ProductItemVATRate(CurrentRow.Products, Object.Organization, Object.VATTaxation, Object.Date, Object.BusinessOperation);

		If Not Object.PriceIncludesVAT Then
			CurrentRow.AmountExcludingVAT = CurrentRow.Sum;
		EndIf;
		RowsToProcess.Add(CurrentRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
											New Structure("Products", "MeasuredValueType"));
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	InternalInvoiceInBatch = ValueIsFilled(Object.Lot) And 
		Common.ObjectAttributeValue(Object.Lot, "SourceDocumentType") = Enums.SourceDocumentTypes.InternalInvoice;
	
	VisibilityOfAccountingGroups = Documents.OBEntryGoods.VisibilityOfAccountingGroups(Object);
	
	ThisIsInternationalVersion = Not GetFunctionalOption("LocalizationRFService");
	VisibilityOfReservesForImpairmentOfInventories = VisibilityOfReservesForImpairmentOfInventories();
	
	Items.GroupEnterBalanceBy.Visible                         = VisibilityOfAccountingGroups;
	Items.AGroupOfInputResiduesOnTheCommission.Visible                 = VisibilityOfAccountingGroups;
	Items.GroupEnteringBalancesForStorage.Visible                 = VisibilityOfAccountingGroups;
	Items.AGroupOfInputResiduesTransferredToTheCommission.Visible       = VisibilityOfAccountingGroups;
	Items.AGroupOfInputResiduesTransferredToTheCommission2_5.Visible    = VisibilityOfAccountingGroups;
	Items.GroupInputOfBalancesTransferredForStorage.Visible       = VisibilityOfAccountingGroups;
	Items.AGroupOfInputResiduesAdoptedByTara.Visible               = VisibilityOfAccountingGroups;
	Items.AGroupOfInputResiduesTransferredToTara.Visible             = GetFunctionalOption("UseLocal");
	Items.AGroupOfInputResiduesTransferredToTheProcessors.Visible   = VisibilityOfAccountingGroups;
	Items.TheGroupEnterTheBalancesTransferredToManufacturing.Visible    = VisibilityOfAccountingGroups;
	Items.GroupOfRecycledMaterialsFlagsReflect.Visible = VisibilityOfAccountingGroups;
	Items.GroupSemiFinishedProductsGiversFlagsToReflect.Visible         = VisibilityOfAccountingGroups;
	Items.GroupProductionGiverFlagsReflect.Visible             = VisibilityOfAccountingGroups;
	Items.GroupIsEnteringBalancesForTransferOfOwnership.Visible = VisibilityOfAccountingGroups;
	
	RecordsAreKeptAccordingToAIT = CalculationOfCostLocalization.RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	Object.RecordAIT             = ?(RecordsAreKeptAccordingToAIT, Object.RecordAIT, False);
	Items.RecordAIT.Visible = RecordsAreKeptAccordingToAIT;
	
	If Not VisibilityOfAccountingGroups Then
		
		// If the accounting type settings are not available, then the document can only be reflected in operational accounting.
		Object.RecordInOperationalAccounting = True;
		Object.PostInCostAccounting     = False;
		Object.PostInFinancialAndTaxAccounting            = False;
		Object.RecordInMA               = False;
		Object.RecordAIT               = False;
		
	EndIf;
	
	Items.TheGroupSOwnProducts.Visible = ThisIsOwnStockBalance;
	If Items.TheGroupSOwnProducts.Visible Then
		NameOfTheCurrentFormTable = Items.OwnProducts.Name;
	EndIf;
	
	Items.GroupReceivedForCommission.Visible = ThisIsConsignedStockBalanceReceived;
	If Items.GroupReceivedForCommission.Visible Then
		NameOfTheCurrentFormTable = Items.ReceivedByCommissionAgent.Name;
	EndIf;
	
	Items.GroupReceivedForStorage.Visible = TheseAreBalancesOfGoodsAcceptedForStorage;
	If Items.GroupReceivedForStorage.Visible Then
		NameOfTheCurrentFormTable = Items.ReceivedForStorage.Name;
	EndIf;
	
	Items.GroupTransferOfOwnership.Visible = TheseAreRemnantsOfShippedItems;
	If Items.GroupTransferOfOwnership.Visible Then
		NameOfTheCurrentFormTable = Items.TransferOfTitleToGoods.Name;
	EndIf;
	
	Items.GroupTransferredToTheCommission.Visible = ThisIsConsignedStockBalanceIssued;
	If Items.GroupTransferredToTheCommission.Visible Then
		NameOfTheCurrentFormTable = Items.TransferredToCommissionAgent.Name;
	EndIf;
	
	Items.GroupTransferredToTheCommission2_5.Visible = ThisIsConsignedStockBalanceIssued2_5;
	If Items.GroupTransferredToTheCommission2_5.Visible Then
		NameOfTheCurrentFormTable = Items.TransferredToCommissionAgent2_5.Name;
	EndIf;
	
	Items.GroupTransferredForStorage.Visible = TheseAreBalancesOfGoodsTransferredForStorage;
	If Items.GroupTransferredForStorage.Visible Then
		NameOfTheCurrentFormTable = Items.TransferredForStorage.Name;
	EndIf;
	
	Items.GroupOfProductsTransferredToProcessors.Visible =
		ThisIsStockBalanceTransferredToToller2_5
		Or False;
	If Items.GroupOfProductsTransferredToProcessors.Visible Then
		NameOfTheCurrentFormTable = Items.GoodsTransferredToTollers.Name;
	EndIf;
	Items.GroupOfMaterialsAcceptedForProcessing.Visible = TheseAreBalancesOfMaterialsTakenIntoProcessing2_5;
	If Items.GroupOfMaterialsAcceptedForProcessing.Visible Then
		NameOfTheCurrentFormTable = Items.MaterialsAcceptedForProcessing.Name;
	EndIf;
	
	Items.GroupSemiFinishedProductsGivers.Visible = TheseAreBalancesOfSemiFinishedProductsOfGiver2_5;
	If Items.GroupSemiFinishedProductsGivers.Visible Then
		NameOfTheCurrentFormTable = Items.GiverSSemiFinishedProducts.Name;
	EndIf;
	
	Items.GiverSProductsGroup.Visible = TheseAreBalancesOfOutputOfGiver2_5;
	If Items.GiverSProductsGroup.Visible Then
		NameOfTheCurrentFormTable = Items.ProductsOfMaterialProvider.Name;
	EndIf;
	Items.GroupOfGoodsTransferredToProduction.Visible = ThisIsStockBalanceTransferredToProduction;
	If Items.GroupOfGoodsTransferredToProduction.Visible Then
		NameOfTheCurrentFormTable = Items.GoodsTransferredToProduction.Name;
	EndIf;
	
	Items.GroupAcceptedPackaging.Visible = ThisIsRemainingReceivedPackage;
	If Items.GroupAcceptedPackaging.Visible Then
		NameOfTheCurrentFormTable = Items.ReceivedPackage.Name;
	EndIf;
	
	Items.GroupTransferredPackaging.Visible = TheseAreRemainingTransferredPackages;
	If Items.GroupTransferredPackaging.Visible Then
		NameOfTheCurrentFormTable = Items.TransferredPackage.Name;
	EndIf;
	
	Items.RejectionGroup.Visible = TheseAreBalancesOfDeviations;
	If Items.RejectionGroup.Visible Then
		NameOfTheCurrentFormTable = Items.Variances.Name;
		Items.DeviationsDivision.Visible = StrFind(DetailDeviations, "ByBusinessUnits");
		Items.VariancesPurpose.Visible = StrFind(DetailDeviations, "ByLinesOfBusiness");
	EndIf;
	
	Items.GroupSwitchingToAddressableStorage.Visible = ThisIsTransitionToBinLocationWarehousing Or ThisIsTransitionToWarerooms;
	If Items.GroupSwitchingToAddressableStorage.Visible Then
		NameOfTheCurrentFormTable = Items.TransferToBinLocationWarehousingGoods.Name;
		Items.TheTransitionToTheAddressStorageAreaOfAcceptance.Visible                                      = ThisIsTransitionToBinLocationWarehousing;
		Items.SwitchingToAddressableStorageProductsFillInTheRemainingItemsInTheWarehouse.Visible          = ThisIsTransitionToBinLocationWarehousing;
		Items.TransferToBinLocationWarehousingGoodsFillOutAnEmptyWareroomWithStockBalance.Visible = ThisIsTransitionToWarerooms;
	EndIf;
	
	Items.OwnProductsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.OwnProductsStatusOfTheSpecifiedSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.OwnProductsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;

	Items.StatusOfBatchInstructionsSubmittedToCommission25.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.TransferredToCommission25Batch.Visible               = SeriesSpecificationParameters.UseItemsBatch;

	Items.TransferOfOwnershipStatusOfBatchIndication.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.TransferOfOwnershipBatch.Visible = SeriesSpecificationParameters.UseItemsBatch;

	Items.DepositedStatusOfBatchIndication.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.DepositedBatches.Visible               = SeriesSpecificationParameters.UseItemsBatch;

	Items.ReceivedForCommissionSpecifyTheSeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.ReceivedTheCommissionOfTheStatusIndicationOfTheSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.ReceivedForCommissionSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.IndicateBatchesReceivedForStorage.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.StatusOfBatchInstructionsReceivedForStorage.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.ReceivedForStorageBatch.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.SwitchingToAddressableStorageProductsOfTheSpecifiedSeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.TheTransitionToAddressTheStorageOfGoodsStatusIndicationOfTheSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.SwitchingToAddressableStorageProductsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.GoodsTransferredToTollersSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsTransferredToProcessorsStatusOfSeriesIndication.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsTransferredToProcessorsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.GoodsTransferredToProductionSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.ProductsThatHaveBeenPutIntoProductionTheStatusOfIndicatingTheSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.ProductsTransferredToProductionSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	Items.MaterialsAcceptedForProcessingSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.MaterialsAcceptedForProcessingStatusOfSeriesIndication.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.RecycledMaterialsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.GiverSSemiFinishedProductsSpecifySeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	Items.SemiFinishedProductsGiverStatusIndicationOfSeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.SemiFinishedProductsGiverSeries.Visible                       = SeriesSpecificationParameters.UseItemsBatch;
	
	Items.ProductsOfMaterialProviderSpecifySeries.Visible                    = SeriesSpecificationParameters.UseItemsBatch;
	Items.GiverSProductsStatusOfIndicationOfSeries.Visible             = SeriesSpecificationParameters.UseItemsBatch;
	Items.GiverSProductsSeries.Visible                           = SeriesSpecificationParameters.UseItemsBatch;
	FillingByBalances = Not Object.RecordInOperationalAccounting 
		And (Object.PostInCostAccounting Or Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA);
		
	Items.OwnProductsFillInByBalance.Visible              = FillingByBalances;
	Items.ReceivedByCommissionAgentFillInByBalance.Visible           = FillingByBalances;
	Items.ReceivedForStorageFillInByBalance.Visible           = FillingByBalances;
	Items.TransferredToCommissionAgentFillInByBalance.Visible           = FillingByBalances;
	Items.FillIn25TransferredToCommissionOnBalance.Visible         = FillingByBalances;
	Items.TransferredForStorageFillInByBalance.Visible           = FillingByBalances;
	Items.ReceivedPackageFillInByBalance.Visible                   = FillingByBalances;
	Items.GoodsTransferredToTollersFillInByBalance.Visible = FillingByBalances;
	Items.GoodsTransferredToProductionFillInByBalance.Visible  = FillingByBalances;
	Items.MaterialsAcceptedForProcessingFillInByBalance.Visible = FillingByBalances;
	Items.GiverSSemiFinishedProductsFillInByBalance.Visible         = FillingByBalances;
	Items.ProductsOfMaterialProviderFillInByBalance.Visible             = FillingByBalances;
	VisibilityOfLocalBankingDetails = Object.RecordInOperationalAccounting Or Object.PostInCostAccounting Or Object.PostInFinancialAndTaxAccounting;
	CompanyManagementAccounting = CalculationOfCostCached.CompanyManagementAccounting(Object.Date);
	
	Items.TheirOwnProductsTheAmountRegl.Visible = VisibilityOfLocalBankingDetails;
	Items.OwnGoodsNdseg.Visible   = VisibilityOfLocalBankingDetails;
	Items.OwnProductsAmountPR.Visible   = VisibilityOfLocalBankingDetails;
	Items.TheirOwnProductsTheAmountOfBP.Visible   = VisibilityOfLocalBankingDetails;
	Items.OwnGoodsProvisionForImpairmentRegl.Visible = VisibilityOfLocalBankingDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.OwnGoodsProvisionForImpairmentOfUpr.Visible  = VisibilityOfLocalBankingDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.ReceivedByCommissionAgentSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.ReceivedByCommissionAgentVATLocal.Visible   = VisibilityOfLocalBankingDetails;
	Items.ReceivedByCommissionAgentAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.ReceivedByCommissionAgentAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	
	Items.ReceivedForStorageSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.ReceivedForStorageAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.ReceivedForStorageAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	
	Items.TransferOfTitleToGoodsSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferOfTitleToGoodsAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferOfTitleToGoodsAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	
	Items.TransferredToCommissionAgentSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferredToCommissionAgentVATLocal.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToCommissionAgentAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToCommissionAgentAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToCommissionAgentProvisionForImpairmentLocal.Visible = VisibilityOfLocalBankingDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.TransferredToCommissionAgentProvisionForImpairmentMan.Visible  = VisibilityOfLocalBankingDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items._25LocalAmountTransferredToCommission.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferredToCommission25PDAmount.Visible   = VisibilityOfLocalBankingDetails;
	Items.AmountTransferredToCommissionIs25TDAmount.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToCommission25ReserveForImpairmentOfLocal.Visible = VisibilityOfLocalBankingDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.TransferredToCommission25ReserveForImpairmentOfMan.Visible  = VisibilityOfLocalBankingDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.TransferredForStorageSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferredForStorageAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredForStorageAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredForStorageProvisionForImpairmentLocal.Visible = VisibilityOfLocalBankingDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.TransferredForStorageProvisionForImpairmentMan.Visible  = VisibilityOfLocalBankingDetails  
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.ReceivedPackageSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.ReceivedPackageAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.ReceivedPackageAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	
	Items.ReceivedPackageSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.ReceivedPackageAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.ReceivedPackageAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	
	Items.TransferredPackageSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferredPackageAmountPermanentDifferences.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredPackageAmountTemporaryDifferences.Visible   = VisibilityOfLocalBankingDetails;
	
	Items.TransferredToTheProcessorsOfTheGoodsInTheAmountRegl.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferredToProcessorsProductsNdseg.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToTheProcessorsOfTheGoodsAmountPR.Visible   = VisibilityOfLocalBankingDetails;
	Items.GoodsTransferredToProcessorsAmountOfBP.Visible   = VisibilityOfLocalBankingDetails;
	Items.GoodsTransferredToProcessorsProvisionForImpairmentOfRegl.Visible = VisibilityOfLocalBankingDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.GoodsTransferredToProcessorsProvisionForImpairmentOfUpr.Visible  = VisibilityOfLocalBankingDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.TransferredToTheManufactureOfTheGoodsTheAmountOfREP.Visible = VisibilityOfLocalBankingDetails;
	Items.TransferredToTheManufactureOfTheGoodsNdseg.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToTheManufactureOfTheGoodsAmountPR.Visible   = VisibilityOfLocalBankingDetails;
	Items.TransferredToTheManufactureOfTheGoodsTheAmountOfBP.Visible   = VisibilityOfLocalBankingDetails;
	Items.MaterialsAcceptedForProcessingSumCompl.Visible = VisibilityOfLocalBankingDetails;
	Items.SemiFinishedProductsGiverLocalAmount.Visible         = VisibilityOfLocalBankingDetails;
	Items.SemiFinishedProductsGiverSumPD.Visible           = VisibilityOfLocalBankingDetails;
	Items.SemiFinishedProductsGiverSumOfTD.Visible           = VisibilityOfLocalBankingDetails;
	Items.SemiFinishedProductsGiverAmountOfLocalOffBalance.Visible = VisibilityOfLocalBankingDetails;
	Items.ProductsOfMaterialProviderSumCompl.Visible             = VisibilityOfLocalBankingDetails;
	VisibilityOfManDetails  = Object.RecordInOperationalAccounting 
		Or Object.PostInCostAccounting Or Object.RecordInMA;
	VisibilityOfPaymentDetails = Object.PostInCostAccounting 
		Or Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA Or Object.RecordAIT;
	VisibilityOfAITDetails  = Object.RecordAIT And RecordsAreKeptAccordingToAIT;
	
	Items.OwnProductsPrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TheirOwnProductsTheAmount.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.OwnProductsVATRate.Visible       = Not InternalInvoiceInBatch;
	Items.OwnProductsAmountWithoutVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails And Not InternalInvoiceInBatch;
	Items.OwnGoodsTheAmountOfVAT.Visible        = VisibilityOfPaymentDetails And VisibilityOfManDetails And Not InternalInvoiceInBatch;
	Items.OwnProductsAmountWithVAT.Visible       = VisibilityOfPaymentDetails And Not InternalInvoiceInBatch;
	Items.TheirOwnProductsTheAmountRegl.Visible       = VisibilityOfPaymentDetails;
	Items.OwnGoodsNdseg.Visible         = VisibilityOfPaymentDetails And Not InternalInvoiceInBatch;
	Items.OwnProductsAmountPR.Visible         = VisibilityOfPaymentDetails;
	Items.TheirOwnProductsTheAmountOfBP.Visible         = VisibilityOfPaymentDetails;
	Items.OwnGoodsAmountNDD.Visible        = VisibilityOfPaymentDetails And VisibilityOfAITDetails;
	Items.OwnProductsPriceIncludesVAT.Visible = VisibilityOfPaymentDetails And Not InternalInvoiceInBatch;
	Items.OwnGoodsProvisionForImpairmentRegl.Visible = VisibilityOfPaymentDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.OwnGoodsProvisionForImpairmentOfUpr.Visible  = VisibilityOfPaymentDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.ReceivedByCommissionAgentPrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedForStoragePrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedByCommissionAgentSum.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedForStorageSum.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedByCommissionAgentAmountExcludingVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedForStorageAmountExcludingVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedByCommissionAgentVATAmount.Visible        = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedByCommissionAgentAmountIncludingVAT.Visible       = VisibilityOfPaymentDetails;
	Items.ReceivedByCommissionAgentSumCompl.Visible       = VisibilityOfPaymentDetails;
	Items.ReceivedForStorageSumCompl.Visible       = VisibilityOfPaymentDetails;
	Items.ReceivedByCommissionAgentVATLocal.Visible         = VisibilityOfPaymentDetails;
	Items.ReceivedByCommissionAgentAmountPermanentDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.ReceivedForStorageAmountPermanentDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.ReceivedByCommissionAgentAmountTemporaryDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.ReceivedForStorageAmountTemporaryDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.ThePriceReceivedForTheCommissionIncludesVAT.Visible = VisibilityOfPaymentDetails;
	
	Items.TransferOfTitleToGoodsPrice.Visible          = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferOfTitleToGoodsSum.Visible         = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferOfTitleToGoodsAmountExcludingVAT.Visible   = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferOfTitleToGoodsVATAmount.Visible      = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferOfTitleToGoodsAmountIncludingVAT.Visible     = VisibilityOfPaymentDetails;
	Items.TransferOfTitleToGoodsSumCompl.Visible     = VisibilityOfPaymentDetails;
	Items.TransferOfTitleToGoodsVATLocal.Visible       = VisibilityOfPaymentDetails;
	Items.TransferOfTitleToGoodsAmountPermanentDifferences.Visible       = VisibilityOfPaymentDetails;
	Items.TransferOfTitleToGoodsAmountTemporaryDifferences.Visible       = VisibilityOfPaymentDetails;
	Items.TransferOfOwnershipPriceIncludesVAT.Visible = VisibilityOfPaymentDetails;
	
	Items.TransferredToCommissionAgentPrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommissionAgentSum.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommissionAgentAmountExcludingVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommissionAgentVATAmount.Visible        = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommissionAgentAmountIncludingVAT.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToCommissionAgentSumCompl.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToCommissionAgentVATLocal.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredToCommissionAgentAmountPermanentDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredToCommissionAgentAmountTemporaryDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredToCommissionAgentAITAmount.Visible        = VisibilityOfPaymentDetails And VisibilityOfAITDetails;
	Items.TransferredToTheCommissionPriceIncludesVAT.Visible = VisibilityOfPaymentDetails;
	Items.TransferredToCommissionAgentProvisionForImpairmentLocal.Visible = VisibilityOfPaymentDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.TransferredToCommissionAgentProvisionForImpairmentMan.Visible  = VisibilityOfPaymentDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;

	Items.TransferredForStoragePrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredForStorageSum.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredForStorageAmountExcludingVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredForStorageVATAmount.Visible        = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredForStorageAmountIncludingVAT.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredForStorageVATLocal.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredForStorageSumCompl.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredForStorageAmountPermanentDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredForStorageAmountTemporaryDifferences.Visible         = VisibilityOfPaymentDetails;
	Items.DepositedPriceIncludesVAT.Visible = VisibilityOfPaymentDetails;
	Items.TransferredForStorageProvisionForImpairmentLocal.Visible = VisibilityOfPaymentDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.TransferredForStorageProvisionForImpairmentMan.Visible  = VisibilityOfPaymentDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;

	Items.TransferredToCommission25Price.Visible          = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommission25Amount.Visible         = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommission25VATExclusiveAmount.Visible   = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommission25VATAmount.Visible      = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToCommission25AmountWithVAT.Visible     = VisibilityOfPaymentDetails;
	Items._25LocalAmountTransferredToCommission.Visible     = VisibilityOfPaymentDetails;
	Items.TransferredToCommission25VATLocal.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToCommission25PDAmount.Visible       = VisibilityOfPaymentDetails;
	Items.AmountTransferredToCommissionIs25TDAmount.Visible       = VisibilityOfPaymentDetails;
	Items._25TransferredToCommissionPriceIncludesVAT.Visible = VisibilityOfPaymentDetails;
	Items.TransferredToCommission25ReserveForImpairmentOfLocal.Visible = VisibilityOfPaymentDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.TransferredToCommission25ReserveForImpairmentOfMan.Visible  = VisibilityOfPaymentDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.ReceivedPackagePrice.Visible      = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedPackageSum.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ReceivedPackageSumCompl.Visible = VisibilityOfPaymentDetails;
	Items.ReceivedPackageAmountPermanentDifferences.Visible   = VisibilityOfPaymentDetails;
	Items.ReceivedPackageAmountTemporaryDifferences.Visible   = VisibilityOfPaymentDetails;
	
	Items.TransferredPackagePrice.Visible      = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredPackageSum.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredPackageSumCompl.Visible = VisibilityOfPaymentDetails;
	Items.TransferredPackageAmountPermanentDifferences.Visible   = VisibilityOfPaymentDetails;
	Items.TransferredPackageAmountTemporaryDifferences.Visible   = VisibilityOfPaymentDetails;
	
	Items.TransferredToTheProcessorsOfTheGoodsPrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheProcessorsOfTheGoodsAmount.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheProcessorsOfGoodsAmountExcludingVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheProcessorsOfGoodsTheAmountOfVAT.Visible        = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.GoodsTransferredToProcessorsAmountWithVAT.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToTheProcessorsOfTheGoodsInTheAmountRegl.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToProcessorsProductsNdseg.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredToTheProcessorsOfTheGoodsAmountPR.Visible         = VisibilityOfPaymentDetails;
	Items.GoodsTransferredToProcessorsAmountOfBP.Visible         = VisibilityOfPaymentDetails;
	Items.GoodsTransferredToProcessorsAmountNDD.Visible        = VisibilityOfPaymentDetails And VisibilityOfAITDetails;
	Items.TransferredToTheProcessorsOfGoodsThePriceIncludesVAT.Visible = VisibilityOfPaymentDetails;
	Items.GoodsTransferredToProcessorsProvisionForImpairmentOfRegl.Visible = VisibilityOfPaymentDetails And VisibilityOfReservesForImpairmentOfInventories;
	Items.GoodsTransferredToProcessorsProvisionForImpairmentOfUpr.Visible  = VisibilityOfPaymentDetails 
		And CompanyManagementAccounting And VisibilityOfReservesForImpairmentOfInventories;
	
	Items.TransferredToTheManufactureOfTheGoodsPrice.Visible            = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheManufactureOfTheGoodsAmount.Visible           = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheProductionOfGoodsAmountExcludingVAT.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheManufactureOfTheGoodsTheAmountOfVAT.Visible        = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.TransferredToTheManufactureOfTheGoodsTheAmountSNDS.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToTheManufactureOfTheGoodsTheAmountOfREP.Visible       = VisibilityOfPaymentDetails;
	Items.TransferredToTheManufactureOfTheGoodsNdseg.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredToTheManufactureOfTheGoodsAmountPR.Visible         = VisibilityOfPaymentDetails;
	Items.TransferredToTheManufactureOfTheGoodsTheAmountOfBP.Visible         = VisibilityOfPaymentDetails;
	Items.GoodsPutIntoProductionAmountNDD.Visible        = VisibilityOfPaymentDetails And VisibilityOfAITDetails;
	Items.TransferredToTheManufactureOfTheGoodsThePriceIncludesVAT.Visible = VisibilityOfPaymentDetails;
	Items.MaterialsAcceptedForProcessingPrice.Visible      = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.MaterialsAcceptedForProcessingSum.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.MaterialsAcceptedForProcessingSumCompl.Visible = VisibilityOfPaymentDetails;
	
	Items.SemiFinishedProductsGiverPrice.Visible              = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.SemiFinishedProductsGiverSum.Visible             = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.SemiFinishedProductsGiverLocalAmount.Visible         = VisibilityOfPaymentDetails;
	Items.SemiFinishedProductsGiverSumPD.Visible           = VisibilityOfPaymentDetails;
	Items.SemiFinishedProductsGiverSumOfTD.Visible           = VisibilityOfPaymentDetails;
	Items.SemiFinishedProductsGiverPriceOffBalance.Visible      = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.SemiFinishedProductsGiverSumOffBalance.Visible     = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.SemiFinishedProductsGiverAmountOfLocalOffBalance.Visible = VisibilityOfPaymentDetails;
	
	Items.ProductsOfMaterialProviderPrice.Visible                  = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ProductsOfMaterialProviderSum.Visible                 = VisibilityOfPaymentDetails And VisibilityOfManDetails;
	Items.ProductsOfMaterialProviderSumCompl.Visible             = VisibilityOfPaymentDetails;
	Items.OwnProductsBatch.Visible                      = True;
	Items.OwnProductsSpecifyReceiptDocuments.Visible = Not InternalInvoiceInBatch;
	Items.OwnProductsBatchDetails.Visible           = Not InternalInvoiceInBatch;
	Items.TaxInvoicePageGroup.Visible                    = False;
	
	Items.PartyReceivedForCommission.Visible = True;
	Items.ReceivedForStorageLotReferences.Visible = True;
	Items.TransferOfOwnershipLotReference.Visible = True;
	
	Items.SubmittedToTheCommissionParty.Visible                      = True;
	Items.TransferredToCommissionAgentSpecifyReceiptDocuments.Visible = True;
	Items.TransferredToCommissionAgentLotDetails.Visible           = True;
	
	Items.SubmittedToCommissionFor25LotReferences.Visible                      = True;
	Items.SubmittedToCommission25SpecifyReceiptDocuments.Visible = True;
	Items._25SubmittedToCommissionDetailingOfLotReferences.Visible           = True;
	
	Items.DepositedLotReferences.Visible                      = True;
	Items.TransferredForStorageSpecifyReceiptDocuments.Visible = True;
	Items.TransferredForStorageLotDetails.Visible           = True;
	
	Items.AcceptedPackagingBatch.Visible = True;
	
	Items.BatchTransferredToProcessors.Visible                            = True;
	Items.GoodsTransferredToTollersSpecifyReceiptDocuments.Visible = True;
	Items.TransferredToTheProcessorsOfTheGoodsDetailsOfTheParties.Visible           = True;
	
	Items.TransferredToTheManufactureOfTheGoodsTheParty.Visible                      = True;
	Items.GoodsTransferredToProductionSpecifyReceiptDocuments.Visible = True;
	Items.TransferredToTheManufactureOfTheGoodsDetailsOfTheParties.Visible           = True;
	
	Items.GroupPartner.Visible          = False;
	Items.CounterpartyGroup.Visible       = False;
	Items.AcceptedPackagingCounterparty.Visible = False;
	
	Items.OwnProductsSpecifyReceiptDocuments.Visible                                                       = Not ThisIsInternationalVersion;
	Items.OwnProducts.ChildItems.OwnProductsBatchDetails.Visible                           = Not ThisIsInternationalVersion;
	Items.OwnProducts.ChildItems.TheirOwnProductsTheAmountOfBP.Visible                                     = Not ThisIsInternationalVersion;
	Items.ReceivedByCommissionAgent.ChildItems.ReceivedByCommissionAgentAmountTemporaryDifferences.Visible                               = Not ThisIsInternationalVersion;
	Items.ReceivedForStorage.ChildItems.ReceivedForStorageAmountTemporaryDifferences.Visible                               = Not ThisIsInternationalVersion;
	Items.TransferredToCommissionAgent.ChildItems.TransferredToCommissionAgentLotDetails.Visible                     = Not ThisIsInternationalVersion;
	Items.TransferredToCommissionAgent2_5.ChildItems._25SubmittedToCommissionDetailingOfLotReferences.Visible                = Not ThisIsInternationalVersion;
	Items.TransferredForStorage.ChildItems.TransferredForStorageLotDetails.Visible                     = Not ThisIsInternationalVersion;
	Items.TransferredToCommissionAgent.ChildItems.TransferredToCommissionAgentAmountTemporaryDifferences.Visible                               = Not ThisIsInternationalVersion;
	Items.TransferredToCommissionAgent2_5.ChildItems.AmountTransferredToCommissionIs25TDAmount.Visible                          = Not ThisIsInternationalVersion;
	Items.TransferredForStorage.ChildItems.TransferredForStorageAmountTemporaryDifferences.Visible                               = Not ThisIsInternationalVersion;
	Items.TransferredPackage.ChildItems.TransferredPackageAmountTemporaryDifferences.Visible                                           = Not ThisIsInternationalVersion;
	Items.ReceivedPackage.ChildItems.ReceivedPackageAmountTemporaryDifferences.Visible                                               = Not ThisIsInternationalVersion;
	Items.GoodsTransferredToTollers.ChildItems.TransferredToTheProcessorsOfTheGoodsDetailsOfTheParties.Visible = Not ThisIsInternationalVersion;
	Items.GoodsTransferredToTollers.ChildItems.GoodsTransferredToProcessorsAmountOfBP.Visible           = Not ThisIsInternationalVersion;
	Items.GoodsTransferredToProduction.ChildItems.TransferredToTheManufactureOfTheGoodsDetailsOfTheParties.Visible   = Not ThisIsInternationalVersion;
	Items.GoodsTransferredToProduction.ChildItems.TransferredToTheManufactureOfTheGoodsTheAmountOfBP.Visible             = Not ThisIsInternationalVersion;
	Items.TransferOfTitleToGoods.ChildItems.TransferOfTitleToGoodsAmountTemporaryDifferences.Visible = Not ThisIsInternationalVersion;
	
	Items.OwnProductsProductGroup.Visible = ValueIsFilled(Object.Warehouse)
		And Common.ObjectAttributeValue(Object.Warehouse, "ShopFloorStockroom");
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	UseTermsOfPurchases = GetFunctionalOption("UseTermsOfPurchases");
	
	Items.TransferredToCommission25AgreementWithCommissionAgent.Visible = ToUseTermsOfSales;
	Items.DepositedAgreementWithCustodian.Visible = ToUseTermsOfSales;
	Items.ReceivedForSafekeepingAgreementWithCommittee.Visible = UseTermsOfPurchases;
	
	SetVisibilityOfAcceptanceArea();
	
	SetVisibilityOfFinalIndicators();
	
EndProcedure

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfAcceptanceArea()
	
	AcceptanceAreaVisibility = False;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
	
		AcceptanceAreaVisibility = UseBinLocationWarehousing;
			
	EndIf;
	
	If Items.TheGroupSOwnProducts.Visible Then
		Items.OwnGoodsAcceptanceArea.Visible = AcceptanceAreaVisibility;
	ElsIf Items.GroupReceivedForCommission.Visible Then
		Items.ReceivedForCommissionAcceptanceZone.Visible = AcceptanceAreaVisibility;
	ElsIf Items.GroupReceivedForStorage.Visible Then
		Items.ReceivedForStorageInboundArea.Visible = AcceptanceAreaVisibility;
	ElsIf Items.GroupAcceptedPackaging.Visible Then
		Items.AcceptedPackagingAcceptanceArea.Visible = AcceptanceAreaVisibility;
	ElsIf Items.GroupOfMaterialsAcceptedForProcessing.Visible Then
		Items.RecycledMaterialsAcceptanceArea.Visible = AcceptanceAreaVisibility;
	ElsIf Items.GroupSemiFinishedProductsGivers.Visible Then
		Items.SemiFinishedProductsGiversAcceptanceArea.Visible = AcceptanceAreaVisibility;
	ElsIf Items.GiverSProductsGroup.Visible Then
		Items.GiverSProductsAcceptanceArea.Visible = AcceptanceAreaVisibility;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfFinalIndicators()
	
	VisibilityOfManDetails  = Object.RecordInOperationalAccounting 
		Or Object.PostInCostAccounting Or Object.RecordInMA;
	VisibilityOfPaymentDetails = Object.PostInCostAccounting 
		Or Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA Or Object.RecordAIT;
	
	DisplayTotalAmountOfVAT =
		Not TheseAreBalancesOfGoodsAcceptedForStorage
		And Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		And Not TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		And Not TheseAreBalancesOfOutputOfGiver2_5
		And Not ThisIsRemainingReceivedPackage
		And Not TheseAreRemainingTransferredPackages
		And VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Object.VATTaxation);
	
	CurrencyRow = String(ManagementAccountingCurrency);
	TitleTemplate1 = "%1 (%2)";
	TitleLine = ?(
		VisibilityOfPaymentDetails And VisibilityOfManDetails And DisplayTotalAmountOfVAT,
		NStr("vi = 'Tổng số gồm thuế GTGT';
			|ru = 'Всего с НДС';
			|en = 'Total including VAT'; fa = 'جمع با احتساب مالیات بر ارزش افزوده';
			|it = 'Всего с НДС';
			|pl = 'Suma brutto';
			|tr = 'KDV dahil toplam'"),
		NStr("vi = 'Tổng số';
			|ru = 'Всего';
			|en = 'Total'; fa = 'جمع کل';
			|it = 'Всего';
			|pl = 'Total';
			|tr = 'Toplam'"));
	TitleTotalTotal = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, TitleLine, CurrencyRow);
	Items.GoodsTotalAmountWithVAT.Title = TitleTotalTotal;
	
	Items.GoodsTotalAmountWithVAT.Visible = VisibilityOfPaymentDetails And VisibilityOfManDetails
		And Not (ThisIsTransitionToBinLocationWarehousing Or ThisIsTransitionToWarerooms);
	Items.GoodsTotalVATAmount.Visible  = VisibilityOfPaymentDetails And VisibilityOfManDetails And DisplayTotalAmountOfVAT
		And Not (ThisIsTransitionToBinLocationWarehousing Or ThisIsTransitionToWarerooms);
	
	Items.GoodsTotalAmountLocal.Visible = VisibilityOfPaymentDetails
		And Not (ThisIsTransitionToBinLocationWarehousing Or ThisIsTransitionToWarerooms);
	Items.GoodsTotalVATLocal.Visible   = VisibilityOfPaymentDetails And DisplayTotalAmountOfVAT
		And Not (ThisIsTransitionToBinLocationWarehousing Or ThisIsTransitionToWarerooms);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	Items.GroupCommentUsingOutdatedCommission.Visible = ThisIsConsignedStockBalanceIssued;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Form)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Form.Object.BusinessOperation));
	StructureOfActions.Insert("RecalculateAmount");
	If Form.TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateAmountWithoutVAT");
		StructureOfActions.Insert("RecalculateLocalAmount", Form.FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculateSuffixAmount", "OffBalance");
		StructureOfActions.Insert("RecalculateLocalOffBalanceAmount", Form.FactorOfConversionFromManCurrencyToRegulCurrency);
	Else
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
		If Not Form.TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			And Not Form.TheseAreBalancesOfOutputOfGiver2_5 Then
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		EndIf;
		StructureOfActions.Insert("RecalculateAmountWithoutVAT");
		StructureOfActions.Insert("RecalculateLocalAmount", Form.FactorOfConversionFromManCurrencyToRegulCurrency);
		If Not (Form.ThisIsRemainingReceivedPackage
			Or Form.TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or Form.TheseAreBalancesOfOutputOfGiver2_5
			Or Form.TheseAreRemainingTransferredPackages) Then
			StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
		EndIf;
	EndIf;
	If Form.ThisIsOwnStockBalance
		Or Form.ThisIsRemainingReceivedPackage
		Or Form.TheseAreRemainingTransferredPackages
		Or Form.TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or Form.TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or Form.TheseAreBalancesOfOutputOfGiver2_5
		Or Form.ThisIsStockBalanceTransferredToToller2_5
		Or Form.ThisIsConsignedStockBalanceReceived
		Or Form.TheseAreBalancesOfGoodsAcceptedForStorage
		Or Form.ThisIsConsignedStockBalanceIssued
		Or Form.ThisIsConsignedStockBalanceIssued2_5
		Or Form.TheseAreBalancesOfGoodsTransferredForStorage
		Or Form.ThisIsStockBalanceTransferredToProduction
		Or Form.TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Form.Object,
			StructureOfActions);
		
	EndIf;

EndProcedure

&AtServer
Procedure SetParametersForSelectingWarehousePremises()

	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors Then
		
		Return;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryWareroomAddressOfOwnedInventory Then
		ChoiceParameter = New ChoiceParameter("Filter.UseWarerooms",True);
		ParametersArray = New Array;
		ParametersArray.Add(ChoiceParameter);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		ChoiceParameter = New ChoiceParameter("DocumentPurchases", True);
		
		ParametersArray = New Array;
		ParametersArray.Add(ChoiceParameter);
	Else
		SettingsArray = New Array;
		SettingsArray.Add(Enums.SettingsOfBinLocationWarehousing.DeterminedByWareroomsSettings);
		SettingsArray.Add(Enums.SettingsOfBinLocationWarehousing.CellsBalance);
		ChoiceParameter = New ChoiceParameter("Filter.CustomizeBinLocationWarehousing",New FixedArray(SettingsArray));
		ParametersArray = New Array;
		ParametersArray.Add(ChoiceParameter);
	EndIf;

	Items.OwnProductsWarehouse.ChoiceParameters             = New FixedArray(ParametersArray);
	Items.ReceivedAtTheCommissionWarehouse.ChoiceParameters          = New FixedArray(ParametersArray);
	Items.ReceivedForStorageWarehouse.ChoiceParameters          = New FixedArray(ParametersArray);
	Items.OwnProductsPremises.ChoiceParameters         = New FixedArray(ParametersArray);
	Items.PremisesReceivedForCommission.ChoiceParameters      = New FixedArray(ParametersArray);
	Items.ReceivedStorageSpace.ChoiceParameters      = New FixedArray(ParametersArray);
	Items.AcceptedPackagingWarehouse.ChoiceParameters                  = New FixedArray(ParametersArray);
	Items.AcceptedPackagingRoom.ChoiceParameters              = New FixedArray(ParametersArray);
	Items.SwitchingToAddressableStorageWarehouse.ChoiceParameters     = New FixedArray(ParametersArray);
	Items.SwitchingToAddressableStorage.ChoiceParameters = New FixedArray(ParametersArray);
	SelectionParametersWarehouse = New FixedArray(ParametersArray);
	
	Items.RecycledMaterialsWarehouse.ChoiceParameters = SelectionParametersWarehouse;
	Items.SemiFinishedProductsGiverWarehouse.ChoiceParameters         = SelectionParametersWarehouse;
	Items.GiverSProductsWarehouse.ChoiceParameters             = SelectionParametersWarehouse;
EndProcedure

&AtServer
Procedure SetStockTypeSelectionParameters()

	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameterLink("Filter.Organization", "Object.Organization"));
	ParametersArray.Add(New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation"));

	If GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups") Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Products", "Items.OwnProducts.CurrentData.Products"));
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Partner", "Object.Partner"));
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		  Or  Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.GoodsOwner", "Object.Partner"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Counterparty",     "Object.Counterparty"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Contract",        "Object.Contract"));
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse
	 Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
		ParametersArray.Add(New ChoiceParameterLink("Filter.Consignor", "Object.Partner"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Contract", "Object.Contract"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Terms", "Object.TermsOfConsignmentPurchase"));
		ParametersArray.Add(New ChoiceParameterLink("Filter.Currency", "Object.Currency"));
		If Not Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
			ParametersArray.Add(New ChoiceParameterLink("Filter.VATTaxation", "Object.VATTaxation"));
		EndIf;
	EndIf;

	Items.OwnGoodsInventoryType.ChoiceParameterLinks		= New FixedArray(ParametersArray);
	Items.ReceivedByCommissionAgentInventoryOwnerAttribute.ChoiceParameterLinks	= New FixedArray(ParametersArray);
	Items.ReceivedForStorageInventoryOwnerAttribute.ChoiceParameterLinks	= New FixedArray(ParametersArray);
	Items.TransferredToCommissionAgentInventoryOwnerAttribute.ChoiceParameterLinks	= New FixedArray(ParametersArray);
	Items.TransferredToCommission25InventoryOwnerAttributes.ChoiceParameterLinks	= New FixedArray(ParametersArray);
	Items.TransferredForStorageInventoryOwnerAttribute.ChoiceParameterLinks	= New FixedArray(ParametersArray);
	RelationshipsOfSelectionParametersTypeOfInventory = New FixedArray(ParametersArray);
	
	Items.MaterialsAcceptedForProcessingInventoryOwnerAttribute.ChoiceParameterLinks = RelationshipsOfSelectionParametersTypeOfInventory;
	Items.GiverSSemiFinishedProductsInventoryOwnerAttribute.ChoiceParameterLinks         = RelationshipsOfSelectionParametersTypeOfInventory;
	Items.ProductsOfMaterialProviderInventoryOwnerAttribute.ChoiceParameterLinks             = RelationshipsOfSelectionParametersTypeOfInventory;
EndProcedure

&AtServer
Procedure SetPartnerSelectionParameters()
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
		Or False Then
		ParametersArray = New Array;
		ChoiceParameter = New ChoiceParameter("Filter.Vendor", True);
		ParametersArray.Add(ChoiceParameter);
		Items.ProductsTransferredToProcessorsPartner.ChoiceParameters = New FixedArray(ParametersArray);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.Client", True));
		
		PartnerSelectionParameters = New FixedArray(ParametersArray);
		
		Items.RecycledMaterialsPartner.ChoiceParameters = PartnerSelectionParameters;
		Items.SemiFinishedProductsGiverPartner.ChoiceParameters         = PartnerSelectionParameters;
		Items.PartnerGiverProducts.ChoiceParameters             = PartnerSelectionParameters;
	EndIf;
EndProcedure

&AtServer
Procedure SetContractSelectionParameters()
	
	ParametersArray = New Array;
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
		ChoiceParameter = New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.ProductionByToller2_5);
		ParametersArray.Add(ChoiceParameter);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
		  Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
			
			ParametersArray = New Array;
			ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
			
			ParametersArray.Add(
				New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
			
			ParametersArray.Add(
				New ChoiceParameter(
						"Filter.BusinessOperation", TollingSchemeClientServer.ContractBusinessTransaction()));
			
			ArrayOfSelectParameterRelationships = New Array;
			ArrayOfSelectParameterRelationships.Add(
				New ChoiceParameterLink(
						"Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
			
			ArrayOfSelectParameterRelationships.Add(
				New ChoiceParameterLink(
						"Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
			
			ArrayOfSelectParameterRelationships.Add(
				New ChoiceParameterLink(
						"Partner", "Object.Partner", LinkedValueChangeMode.Clear));
			
			RelationsOfContractSelectionParameters = New FixedArray(ArrayOfSelectParameterRelationships);
			
			Items.MaterialsAcceptedForProcessingContract.ChoiceParameterLinks = RelationsOfContractSelectionParameters;
			Items.GiverSSemiFinishedProductsContract.ChoiceParameterLinks         = RelationsOfContractSelectionParameters;
			Items.GiverSProductsContract.ChoiceParameterLinks             = RelationsOfContractSelectionParameters;
	EndIf;
	Items.GoodsTransferredToProcessorsContract.ChoiceParameters = New FixedArray(ParametersArray);
	ContractSelectionParameters = New FixedArray(ParametersArray);
	
	Items.MaterialsAcceptedForProcessingContract.ChoiceParameters = ContractSelectionParameters;
	Items.GiverSSemiFinishedProductsContract.ChoiceParameters         = ContractSelectionParameters;
	Items.GiverSProductsContract.ChoiceParameters             = ContractSelectionParameters;
EndProcedure
&AtServer
Procedure SetOrderSelectionParameters()
	
	ChoiceParametersOrder       = New Array;
	RelationshipsOfOrderSelectionParameters = New Array;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
		
		OrderElement = Items.MaterialsAcceptedForProcessingOrder;
		
		RelationshipsOfOrderSelectionParameters.Add(
			New ChoiceParameterLink("Filter.WarehouseForReceipt", "Object.Warehouse", LinkedValueChangeMode.Clear));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
		
		OrderElement = Items.SemiFinishedProductsGiverOrder;
		
		RelationshipsOfOrderSelectionParameters.Add(
			New ChoiceParameterLink("Filter.Warehouse", "Object.Warehouse", LinkedValueChangeMode.Clear));
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		OrderElement = Items.GiverSProductsOrder;
		
		RelationshipsOfOrderSelectionParameters.Add(
			New ChoiceParameterLink("Filter.Warehouse", "Object.Warehouse", LinkedValueChangeMode.Clear));
		
	Else
		Return;
	EndIf;
	
	ChoiceParametersOrder.Add(New ChoiceParameter("Filter.Posted", True));
	
	RelationshipsOfOrderSelectionParameters.Add(
		New ChoiceParameterLink("Filter.Contract", "Object.Contract", LinkedValueChangeMode.Clear));
	
	OrderElement.ChoiceParameters       = New FixedArray(ChoiceParametersOrder);
	OrderElement.ChoiceParameterLinks = New FixedArray(RelationshipsOfOrderSelectionParameters);
	
EndProcedure
&AtServer
Procedure LimitOrderType()
	
	TypeRestriction = Undefined;
	OrderElement = Undefined;
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5 Then
		TypeRestriction = New TypeDescription("DocumentRef.SubcontractOrder2_5");
		OrderElement = Items.TransferredToTheProcessorsOfGoodsTheOrderTheProcessor;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting Then
		
		TypeRestriction = New TypeDescription("DocumentRef.MaterialProviderOrder2_5");
		
		OrderElement = Items.MaterialsAcceptedForProcessingOrder;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider Then
		
		TypeRestriction = New TypeDescription("DocumentRef.MaterialProviderOrder2_5");
		
		OrderElement = Items.SemiFinishedProductsGiverOrder;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		
		TypeRestriction = New TypeDescription("DocumentRef.MaterialProviderOrder2_5");
		
		OrderElement = Items.GiverSProductsOrder;
	EndIf;
	
	If ValueIsFilled(TypeRestriction) Then
		
		OrderElement.TypeRestriction = TypeRestriction;
		TypeRestriction.AdjustValue(Object.OrderDocument);
		OrderBeforeChange = Object.OrderDocument;
		
		FillOutPurposeClientServer(ThisObject);
		
	EndIf;
	
EndProcedure
&AtServer
Procedure SetProductSelectionParameters()
	
	If TheseAreRemainingTransferredPackages Or ThisIsRemainingReceivedPackage Then
		ArrayOfValues = New Array;
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfValues)));
		ProductSelectionParameters = New FixedArray(ParametersArray);
		Items.ReceivedPackageProducts.ChoiceParameters = ProductSelectionParameters;
		Items.TransferredPackageProducts.ChoiceParameters = ProductSelectionParameters;
	ElsIf ThisIsStockBalanceTransferredToProduction Then
		ArrayOfValues = New Array;
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfValues)));
		ProductSelectionParameters = New FixedArray(ParametersArray);
		Items.TransferredToTheManufactureOfTheGoodsNomenclature.ChoiceParameters = ProductSelectionParameters;
	ElsIf TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		ArrayOfValues = New Array;
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfValues.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfValues)));
		ProductSelectionParameters = New FixedArray(ParametersArray);
		Items.GiverSSemiFinishedProductsProducts.ChoiceParameters = ProductSelectionParameters;
	Else
		ParametersArray = New Array;
		ChoiceParameter = New ChoiceParameter("Filter.ItemsType",New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
		ParametersArray.Add(ChoiceParameter);
		Items.OwnProductsNomenclature.ChoiceParameters = New FixedArray(ParametersArray);
		Items.ReceivedByCommissionAgentProducts.ChoiceParameters = New FixedArray(ParametersArray);
		Items.ReceivedForStorageProducts.ChoiceParameters = New FixedArray(ParametersArray);
		Items.TransferredToCommissionAgentProducts.ChoiceParameters = New FixedArray(ParametersArray);
		Items.SubmittedToCommission25Items.ChoiceParameters = New FixedArray(ParametersArray);
		Items.TransferredForStorageProducts.ChoiceParameters = New FixedArray(ParametersArray);
		SelectionParametersProduct = New FixedArray(ParametersArray);
		
		Items.MaterialsAcceptedForProcessingProducts.ChoiceParameters = SelectionParametersProduct;
		Items.GiverSSemiFinishedProductsProducts.ChoiceParameters         = SelectionParametersProduct;
		Items.ProductsOfMaterialProviderProducts.ChoiceParameters             = SelectionParametersProduct;
	EndIf;

EndProcedure

&AtServer
Procedure FillOutWithStockBalanceNotInBinsServer()
	
	Object.Goods.Clear();
	Object.SetOfSeries.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DifferenceInBalances.Products AS Products,
	|	DifferenceInBalances.Characteristic AS Characteristic,
	|	DifferenceInBalances.Purpose AS Purpose,
	|	DifferenceInBalances.Series,
	|	SUM(DifferenceInBalances.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DifferenceInBalances.Count) AS Count
	|INTO DifferenceInBalancesForQuery
	|FROM
	|	(SELECT
	|		ProductStockBalance.Products AS Products,
	|		ProductStockBalance.Characteristic AS Characteristic,
	|		ProductStockBalance.Purpose AS Purpose,
	|		ProductStockBalance.Series AS Series,
	|		ProductStockBalance.InStockBalance AS NumberOfPackages,
	|		ProductStockBalance.InStockBalance AS Count
	|	FROM
	|		AccumulationRegister.ProductStock.Balance(
	|				&DateOfRemainingGoods,
	|				Warehouse = &Warehouse
	|					AND Premise = &Premise) AS ProductStockBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInStorageBinsBalance.Products,
	|		GoodsInStorageBinsBalance.Characteristic,
	|		GoodsInStorageBinsBalance.Purpose,
	|		GoodsInStorageBinsBalance.Series,
	|		-GoodsInStorageBinsBalance.InStockBalance * ISNULL(&QueryTextPackagingFactor1, 1),
	|		-GoodsInStorageBinsBalance.InStockBalance * ISNULL(&QueryTextPackagingFactor1, 1)
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins.Balance(
	|				&DateOfRemainingGoods,
	|				Cell.Owner = &Warehouse
	|					AND Cell.Premise = &Premise) AS GoodsInStorageBinsBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInStorageBins.Products,
	|		GoodsInStorageBins.Characteristic,
	|		GoodsInStorageBins.Purpose,
	|		GoodsInStorageBins.Series,
	|		GoodsInStorageBins.InStock,
	|		GoodsInStorageBins.InStock
	|	FROM
	|		AccumulationRegister.GoodsInStorageBins AS GoodsInStorageBins
	|	WHERE
	|		GoodsInStorageBins.Recorder = &Ref
	|		AND GoodsInStorageBins.Cell.Owner = &Warehouse
	|		AND GoodsInStorageBins.Cell.Premise = &Premise) AS DifferenceInBalances
	|
	|GROUP BY
	|	DifferenceInBalances.Products,
	|	DifferenceInBalances.Characteristic,
	|	DifferenceInBalances.Purpose,
	|	DifferenceInBalances.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DifferenceInBalancesForQuery.Products,
	|	SUM(CASE
	|			WHEN NOT ProductPackages.Ref IS NULL 
	|				THEN 1
	|			ELSE 0
	|		END) AS NumberOfSinglePackages
	|INTO TableOfQuantitiesOfSinglePackages
	|FROM
	|	DifferenceInBalancesForQuery AS DifferenceInBalancesForQuery
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (CASE
	|				WHEN DifferenceInBalancesForQuery.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN DifferenceInBalancesForQuery.Products = ProductPackages.Owner
	|				WHEN DifferenceInBalancesForQuery.Products.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN DifferenceInBalancesForQuery.Products.PackagingGroup = ProductPackages.Owner
	|				ELSE FALSE
	|			END)
	|			AND (&QueryTextPackagingFactor2 = 1)
	|
	|GROUP BY
	|	DifferenceInBalancesForQuery.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DifferenceInBalances.Products,
	|	DifferenceInBalances.Characteristic,
	|	DifferenceInBalances.Purpose,
	|	DifferenceInBalances.Series,
	|	DifferenceInBalances.NumberOfPackages,
	|	DifferenceInBalances.Count,
	|	TableOfQuantitiesOfSinglePackages.NumberOfSinglePackages
	|INTO DifferenceInBalances
	|FROM
	|	DifferenceInBalancesForQuery AS DifferenceInBalances
	|		INNER JOIN TableOfQuantitiesOfSinglePackages AS TableOfQuantitiesOfSinglePackages
	|		ON DifferenceInBalances.Products = TableOfQuantitiesOfSinglePackages.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DifferenceInBalances.Products AS Products,
	|	DifferenceInBalances.Characteristic AS Characteristic,
	|	DifferenceInBalances.Purpose AS Purpose,
	|	ISNULL(ProductPackages.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	DifferenceInBalances.Series,
	|	DifferenceInBalances.NumberOfPackages,
	|	DifferenceInBalances.Count
	|FROM
	|	DifferenceInBalances AS DifferenceInBalances
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (CASE
	|				WHEN CAST(DifferenceInBalances.Products AS Catalog.Products).PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					THEN DifferenceInBalances.Products = ProductPackages.Owner
	|				WHEN CAST(DifferenceInBalances.Products AS Catalog.Products).PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
	|					THEN CAST(DifferenceInBalances.Products AS Catalog.Products).PackagingGroup = ProductPackages.Owner
	|				ELSE FALSE
	|			END)
	|			AND (&QueryTextPackagingFactor2 = 1)
	|			AND (DifferenceInBalances.NumberOfSinglePackages = 1)
	|WHERE
	|	DifferenceInBalances.NumberOfPackages <> 0
	|
	|ORDER BY
	|	DifferenceInBalances.Products.Description,
	|	DifferenceInBalances.Characteristic.Description,
	|	DifferenceInBalances.Purpose.Description";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsInStorageBinsBalance.Package",
		"GoodsInStorageBinsBalance.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages", Undefined));
		
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.SetParameter("Premise", Object.Premise);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("DateOfRemainingGoods", EndOfDay(Object.Date));
	
	Selection = Query.Execute().Select();
	
	CurrentProducts   = Undefined;
	CurrentCharacteristic = Undefined;
	CurAssignment	  = Undefined;

	While Selection.Next() Do
		
		If CurrentProducts <> Selection.Products
			Or CurrentCharacteristic <> Selection.Characteristic
			Or CurAssignment <> Selection.Purpose Then	
			NewProductRow = Object.Goods.Add();
			FillPropertyValues(NewProductRow, Selection);
			
			CurrentProducts   = Selection.Products;
			CurrentCharacteristic = Selection.Characteristic;
			CurAssignment	  = Selection.Purpose;
		Else
			NewProductRow.NumberOfPackages = NewProductRow.NumberOfPackages + Selection.NumberOfPackages;
			NewProductRow.Count         = NewProductRow.NumberOfPackages;
		EndIf;
		
		If ValueIsFilled(Selection.Series) Then
			NewSeriesLine = Object.SetOfSeries.Add();
			FillPropertyValues(NewSeriesLine, Selection);
		EndIf;
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
											New Structure("Products", "MeasuredValueType"));
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure FillOutAnEmptyWareroomWithStockBalanceServer()
	
	Object.Goods.Clear();
	Object.SetOfSeries.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductsToRequest.Products,
	|	ProductsToRequest.Characteristic,
	|	ProductsToRequest.Purpose,
	|	ProductsToRequest.Series,
	|	SUM(ProductsToRequest.Count) AS NumberOfPackages,
	|	SUM(ProductsToRequest.Count) AS Count
	|FROM
	|	(SELECT
	|		ProductStockBalance.Products AS Products,
	|		ProductStockBalance.Characteristic AS Characteristic,
	|		ProductStockBalance.Purpose AS Purpose,
	|		ProductStockBalance.Series AS Series,
	|		ProductStockBalance.InStockBalance AS Count
	|	FROM
	|		AccumulationRegister.ProductStock.Balance(
	|				&DateOfRemainingGoods,
	|				Warehouse = &Warehouse
	|					AND Premise = VALUE(Catalog.Warerooms.EmptyRef)) AS ProductStockBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInWarehousesTurnover.Products,
	|		GoodsInWarehousesTurnover.Characteristic,
	|		GoodsInWarehousesTurnover.Purpose,
	|		GoodsInWarehousesTurnover.Series,
	|		GoodsInWarehousesTurnover.InStockReceipt
	|	FROM
	|		AccumulationRegister.ProductStock.Turnovers(, , Recorder, ) AS GoodsInWarehousesTurnover
	|	WHERE
	|		GoodsInWarehousesTurnover.Recorder = &Ref) AS ProductsToRequest
	|
	|GROUP BY
	|	ProductsToRequest.Products,
	|	ProductsToRequest.Characteristic,
	|	ProductsToRequest.Purpose,
	|	ProductsToRequest.Series
	|
	|HAVING
	|	SUM(ProductsToRequest.Count) > 0
	|
	|ORDER BY
	|	ProductsToRequest.Products.Description,
	|	ProductsToRequest.Characteristic.Description,
	|	ProductsToRequest.Purpose.Description,
	|	ProductsToRequest.Series.Description";
	
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.SetParameter("DateOfRemainingGoods", EndOfDay(Object.Date));
	Query.SetParameter("Ref", Object.Ref);
	
	Selection = Query.Execute().Select();
	
	CurrentProducts   = Undefined;
	CurrentCharacteristic = Undefined;
	CurAssignment	  = Undefined;
	
	While Selection.Next() Do
		
		If CurrentProducts <> Selection.Products
			Or CurrentCharacteristic <> Selection.Characteristic
			Or CurAssignment <> Selection.Purpose Then	
			NewProductRow = Object.Goods.Add();
			FillPropertyValues(NewProductRow, Selection);
			
			CurrentProducts   = Selection.Products;
			CurrentCharacteristic = Selection.Characteristic;
			CurAssignment	  = Selection.Purpose;
		Else
			NewProductRow.NumberOfPackages = NewProductRow.NumberOfPackages + Selection.NumberOfPackages;
			NewProductRow.Count         = NewProductRow.NumberOfPackages;
		EndIf;
		
		If ValueIsFilled(Selection.Series) Then
			NewSeriesLine = Object.SetOfSeries.Add();
			FillPropertyValues(NewSeriesLine, Selection);
		EndIf;
	EndDo;
	
	RecalculateQuantityByRNPT = ThisIsOwnStockBalance
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or ThisIsStockBalanceTransferredToToller2_5
		Or TheseAreRemnantsOfShippedItems;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,
		StructureOfActionsForUpdatingAuxiliaryRowDetails(RecalculateQuantityByRNPT));
	
	RecalculateNumberOfRNPT();
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		Return;
	EndIf;
	InternalInvoiceInBatch = ValueIsFilled(Object.Lot) And 
		Common.ObjectAttributeValue(Object.Lot, "SourceDocumentType") = Enums.SourceDocumentTypes.InternalInvoice;
		
	If InternalInvoiceInBatch
		And Not Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		And Not Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		And Not Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI Then
		Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse Then
		FillParameters = Documents.OBEntryGoods.InitializeVATTaxParametersConsignmentProcurement(Object);
		VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
		VATAccountingERP.FillInListOfVATTaxChoices(Items.ReceivedOnCommissionVATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI Then
		Object.VATTaxation = Enums.VATTaxationTypes.EmptyRef();
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
		Object.VATTaxation = VATAccountingERP.AccountingParametersForOrganization(Object.Organization, Object.Date).BasicTaxationVATSales;
		Object.VATActivityType = Object.VATTaxation;
	Else
		FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(Object);
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters);
	EndIf;
		
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryShippedGoods Then
		
		ParametersArray = New Array;
		ParametersArray.Add(New ChoiceParameterLink("Organization", "Object.Organization", LinkedValueChangeMode.DontChange));
		
		ChoiceParametersArray = New Array;
		ChoiceParameter = New ChoiceParameter("VATTaxation", Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		ChoiceParametersArray.Add(ChoiceParameter);
		ChoiceParameter = New ChoiceParameter("WithoutFilterByDate", True);
		ChoiceParametersArray.Add(ChoiceParameter);
		
		Items.TransferredToCommissionAgentVATRate.ChoiceParameterLinks = New FixedArray(ParametersArray);
		Items.TransferredToCommission25VATRate.ChoiceParameterLinks = New FixedArray(ParametersArray);
		Items.TransferredForStorageVATRate.ChoiceParameterLinks = New FixedArray(ParametersArray);
		Items.TransferredToCommissionAgentVATRate.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		Items.TransferredToCommission25VATRate.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		Items.TransferredForStorageVATRate.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
		Items.TransferOfTitleToGoodsVATRate.ChoiceParameterLinks = New FixedArray(ParametersArray);
		Items.TransferOfTitleToGoodsVATRate.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
		
	If ValueIsFilled(Object.VATTaxation) And TheseAreBalancesOfGoodsTransferredForStorage Then
		
		ItemTypeOfActivityVAT = Items.DepositedVATTaxation;
		ToCompleteListOfVATTaxationChoices(Object.VATTaxation, ItemTypeOfActivityVAT);
		
	EndIf;
	
	SetVisibilityOfFinalIndicators();
	
EndProcedure

&AtServerNoContext
Procedure ToCompleteListOfVATTaxationChoices(VATTaxation, ItemTypeOfActivityVAT)
	
	ValueSelected = ItemTypeOfActivityVAT.ChoiceList.FindByValue(VATTaxation);
	If ValueSelected = Undefined Then
		Presentations = VATAccountingERPInternal.ApplicableVATActivities();
		PresentationElement = Presentations.FindByValue(VATTaxation);
		If PresentationElement <> Undefined Then
			ItemTypeOfActivityVAT.ChoiceList.Add(VATTaxation, PresentationElement.Presentation);
		Else
			ItemTypeOfActivityVAT.ChoiceList.Add(VATTaxation);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	If Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
	 Or Object.BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider Then
		Return;
	EndIf;
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	If Not (ThisIsRemainingReceivedPackage Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.LotDetails, StructureOfActions, CachedValuesInternal);
	
	For Each String In CachedValuesInternal.ProcessedRows Do
		String.VATLocal = PriceManagementSystemClientServer.CalculateVATAmount(String.SumCompl, String.VATRate, False);
		String.VATManag = PriceManagementSystemClientServer.CalculateVATAmount(String.SumMan, String.VATRate, False);
	EndDo;
	
	SetVisibilityOfFinalIndicators();
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, CachedValues)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	
	ExcludeProperties = Undefined;
	If TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
	 Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
	 Or TheseAreBalancesOfOutputOfGiver2_5 Then
		ExcludeProperties = "VATRate";
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));
	StructureOfActions.Insert("RecalculateAmount");
	If Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
	   And Not TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
	   And Not TheseAreBalancesOfOutputOfGiver2_5 Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or ThisIsStockBalanceTransferredToProduction
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
			StructureOfActions);
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			StructureOfActions);
		
	EndIf;
	
	PostProcessingActionStructure = New Structure;
	If Object.PriceIncludesVAT Then
		PostProcessingActionStructure.Insert("RecalculateAmountWithoutVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	PostProcessingActionStructure.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	
	If Not (ThisIsRemainingReceivedPackage
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or TheseAreRemainingTransferredPackages) Then
		PostProcessingActionStructure.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If UseExcisableGoods Then
		PostProcessingActionStructure.Insert("FillInExcisableItemAttribute",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
	EndIf;
	RowsToProcess = New Array();
	
	For Each RowOfGoods In ItemsFromStorage Do
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods,, ExcludeProperties);
		RowsToProcess.Add(StringTSGoods);
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
			
	If Not Object.PriceIncludesVAT Then
		For Each RowOfGoods In RowsToProcess Do
			RowOfGoods.AmountExcludingVAT = RowOfGoods.Sum;
		EndDo;
	EndIf;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		PostProcessingActionStructure,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillParameters = PurchasesServer.ParametersForFillingInServiceAttributesOfCCDNumber();
	FillParameters.FillInCountryOfOrigin = False;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods, FillParameters);
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
EndProcedure


&AtClientAtServerNoContext
Function StructureOfActionsForUpdatingAuxiliaryRowDetails(RecalculateQuantityByRNPT)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute",           New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute",      New Structure("Products", "MeasuredValueType"));
	
	If RecalculateQuantityByRNPT Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	EndIf;
	
	Return StructureOfActions;
	
EndFunction

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export
	
	CurrentRow = Items[NameOfTheCurrentFormTable].CurrentData;
	
	If NewRow <> Undefined Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits(Object.BusinessOperation));
		StructureOfActions.Insert("RecalculateAmount");
		If TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
			StructureOfActions.Insert("RecalculateAmountWithoutVAT");
			StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
			StructureOfActions.Insert("RecalculateSuffixAmount", "OffBalance");
			StructureOfActions.Insert("RecalculateLocalOffBalanceAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
		Else
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
			If Not TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
				And Not TheseAreBalancesOfOutputOfGiver2_5 Then
				StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
				StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			EndIf;
			StructureOfActions.Insert("RecalculateAmountWithoutVAT");
			StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
			If Not (ThisIsRemainingReceivedPackage
				Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
				Or TheseAreBalancesOfOutputOfGiver2_5
				Or TheseAreRemainingTransferredPackages) Then
				StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
			EndIf;
		EndIf;
		If TheseAreRemnantsOfShippedItems Then
			NewRow.RowCode = 0;
		EndIf;
		
		If ThisIsOwnStockBalance
			Or ThisIsRemainingReceivedPackage
			Or TheseAreRemainingTransferredPackages
			Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or TheseAreBalancesOfOutputOfGiver2_5
			Or ThisIsStockBalanceTransferredToToller2_5
			Or ThisIsConsignedStockBalanceReceived
			Or TheseAreBalancesOfGoodsAcceptedForStorage
			Or ThisIsConsignedStockBalanceIssued
			Or ThisIsConsignedStockBalanceIssued2_5
			Or TheseAreBalancesOfGoodsTransferredForStorage
			Or ThisIsStockBalanceTransferredToProduction
			Or TheseAreRemnantsOfShippedItems Then
			
			AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
				Object,
				StructureOfActions);
			
		EndIf;
		If UseExcisableGoods Then
			StructureOfActions.Insert("FillInExcisableItemAttribute",
				BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
		EndIf;
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		NewRow.RowID = New UUID; 
		FillInAttributeThereIsDetailOfBatchesByLine(NewRow.GetID());
	EndIf;
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
		
	EndIf;
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
EndProcedure

&AtServer
Function DivisionMaintainsSeparateAccountingForManagers(Department)
	
	Query = New Query("
		|SELECT
		|	TRUE
		|FROM
		|	Catalog.BusinessStructure AS T
		|WHERE
		|	T.Ref = &Department
		|	AND T.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
		|");
	
	Query.SetParameter("Department", Department);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForRecalculatingNumberOfUnits(BusinessOperation)

	NeedToRoundUpQuantity = True;
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned") Then
		NeedToRoundUpQuantity = False;
	EndIf; 
	
	If Not NeedToRoundUpQuantity Then
		RecalculationParameters = New Structure("MustBeRoundOff", False);
		Return RecalculationParameters;
	EndIf; 
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If (ValueIsFilled(Object.Warehouse)
			And ValueIsFilled(Object.Organization))
		And (ThisIsOwnStockBalance
			Or ThisIsRemainingReceivedPackage
			Or TheseAreRemainingTransferredPackages
			Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
			Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
			Or TheseAreBalancesOfOutputOfGiver2_5
			Or ThisIsStockBalanceTransferredToToller2_5
			Or ThisIsConsignedStockBalanceReceived
			Or TheseAreBalancesOfGoodsAcceptedForStorage
			Or ThisIsConsignedStockBalanceIssued
			Or ThisIsConsignedStockBalanceIssued2_5
			Or TheseAreBalancesOfGoodsTransferredForStorage
			Or TheseAreRemnantsOfShippedItems) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	If ThisIsOwnStockBalance Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"OwnProductsGroupQuantityByRNPT");
	ElsIf ThisIsRemainingReceivedPackage Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"AcceptedPackagingGroupQuantityAccordingToProductBatchID");
	ElsIf ThisIsStockBalanceTransferredToToller2_5 Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"GoodsTransferredToProcessorsGroupQuantityAccordingToProductBatchID");
	ElsIf TheseAreRemainingTransferredPackages Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"TransferredContainerGroupQuantityAccordingToProductBatchID");
	ElsIf ThisIsConsignedStockBalanceReceived Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"ReceivedForTheCommissionGroupAmountOnTheRNPT");
	ElsIf TheseAreBalancesOfGoodsAcceptedForStorage Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"GroupReceivedForStorageIsAmountAccordingToProductBatchID");
	ElsIf ThisIsConsignedStockBalanceIssued Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"TransferredToTheCommissionGroupQuantityAccordingToTheRNPT");
	ElsIf ThisIsConsignedStockBalanceIssued2_5 Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"TransferredToCommission25GroupQuantityByProductBatchID");
	ElsIf TheseAreBalancesOfGoodsTransferredForStorage Then
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"TransferredToStorageGroupQuantityAccordingToProductBatchID");
	ElsIf TheseAreBalancesOfMaterialsTakenIntoProcessing2_5 Then
		
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(
			ThisObject,
			Object.Date,
			"MaterialsAcceptedForProcessingGroupQuantityAccordingToRNPT");
		
	ElsIf TheseAreBalancesOfSemiFinishedProductsOfGiver2_5 Then
		
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(
			ThisObject,
			Object.Date,
			"SemiFinishedProductsGiversGroupQuantityAccordingToRNPT");
		
	ElsIf TheseAreBalancesOfOutputOfGiver2_5 Then
		
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(
			ThisObject,
			Object.Date,
			"GiverSProductsGroupQuantityAccordingToRNPT");
	ElsIf ThisIsStockBalanceTransferredToProduction Then
		
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"GoodsPutIntoProductionGroupQuantityAccordingToProductBatchID");
		
	ElsIf TheseAreRemnantsOfShippedItems Then
		
		AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject,
			Object.Date,
			"TransferOfOwnershipGroupQuantityAccordingToProductBatchID");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillByBalancesOnServer()
	
	TabPart = FormAttributeToValue("Object.Goods");
	TabPart.Clear();
	KeyFields = Documents.OBEntryGoods.KeyFieldsOfLocalAccountingByTypeOfOperation(Object.BusinessOperation);
	Filter = New Structure;
	For Each KeyField In KeyFields Do
		If Not KeyField = "Organization" And ValueIsFilled(Object[KeyField]) Then
			Filter.Insert(KeyField, Object[KeyField]);
		EndIf;
	EndDo;
	
	ParametersForFillingBalances = New Structure("PostInCostAccounting", Object.PostInCostAccounting);
	
	Balance = Documents.OBEntryGoods.BalancesByTypeOfOperation(Object.Date, Object.BusinessOperation, Object.Organization, Filter, ParametersForFillingBalances);
	
	For Each Var_286_Balance In Balance Do
		Page1 = TabPart.Add();
		FillPropertyValues(Page1, Var_286_Balance);
	EndDo;
	
	// We will update the service details
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInCCDTrackingAttribute",
											New Structure("Products", "TheRecordsAreKeptByCCD"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
											New Structure("Products", "MeasuredValueType"));
	
	If ThisIsOwnStockBalance
		Or ThisIsRemainingReceivedPackage
		Or TheseAreRemainingTransferredPackages
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or ThisIsStockBalanceTransferredToToller2_5
		Or ThisIsConsignedStockBalanceReceived
		Or TheseAreBalancesOfGoodsAcceptedForStorage
		Or ThisIsConsignedStockBalanceIssued
		Or ThisIsConsignedStockBalanceIssued2_5
		Or TheseAreBalancesOfGoodsTransferredForStorage
		Or TheseAreRemnantsOfShippedItems Then
		AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfRecalculationOfAmount.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT");
	
	StructureOfActions = New Structure;
	
	If Not (ThisIsRemainingReceivedPackage
		Or TheseAreBalancesOfMaterialsTakenIntoProcessing2_5
		Or TheseAreBalancesOfSemiFinishedProductsOfGiver2_5
		Or TheseAreBalancesOfOutputOfGiver2_5
		Or TheseAreRemainingTransferredPackages) Then
		StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	EndIf;
	If UseExcisableGoods Then
		StructureOfActions.Insert("FillInExcisableItemAttribute",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
	EndIf;
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	RecalculateNumberOfRNPT();
	SetFieldTitleIsSubjectToExciseDuty(ThisObject);
	
EndProcedure

&AtClient
Procedure AlertHandlerIssueFillInByBalances(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		// StandardSubsystems.PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.OBEntryGoods.Form.FormGoods.FillInByBalance");
		// End StandardSubsystems.PerformanceMeasurement
		
		FillByBalancesOnServer();
		
	EndIf;
	
EndProcedure


// The procedure starts after selecting the batches.
// 
// Parameters:
// 	TempStorageAddress - UUID - Aders in a temporary charlise
// 	AddlParameters             - Structure - Structure containing additional parameters passed before opening the form:
//  * String - LineOfATabularSection - the row of the tabular part of the form for which the batch detail form opens.
//
&AtClient
Procedure FormDetailingBatchesAtClosing(TempStorageAddress, AddlParameters) Export
	
	If TempStorageAddress = Undefined Then
		Return;
	EndIf;
	
	UpdateBatchDetailData(AddlParameters.String, TempStorageAddress)
	
EndProcedure

&AtServer
Procedure UpdateBatchDetailData(String, TempStorageAddress)
	
	Modified = True;
	
	LineDataProducts = Object.Goods.FindByID(String);
	
	Filter = New Structure;
	Filter.Insert("RowID", LineDataProducts.RowID);
	DetailLinesAreReadyToBeDeleted = Object.LotDetails.FindRows(Filter);
	For Each BatchDetailLine In DetailLinesAreReadyToBeDeleted Do
		Object.LotDetails.Delete(BatchDetailLine);
	EndDo;
	
	DetailLinesAreReadyToBeAdded = GetFromTempStorage(TempStorageAddress);
	For Each BatchDetailLine In DetailLinesAreReadyToBeAdded Do
		NewRow = Object.LotDetails.Add();
		NewRow.RowID = LineDataProducts.RowID;
		FillPropertyValues(NewRow, BatchDetailLine);
	EndDo;
	
	FillInAttributeThereIsDetailOfBatchesByLine(String);
	
EndProcedure

&AtServer
Procedure GetMethodForEstimatingValueOfGoods()
	
	Period = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Object.Organization,
		BegOfMonth(Period));
		
	If AccountingPolicyParameters <> Undefined Then
		CostEvaluationMethod = AccountingPolicyParameters.InventoryValuationMethod;
		If CostEvaluationMethod = Enums.InventoryValuationMethods.MovingAverage Then
			DeviationDetailFields = "ByLinesOfBusiness,ByBusinessUnits,ByWarehouses";
			DeviationDetailArray = New Array;
			For Each DetailField In StrSplit(DeviationDetailFields, ",") Do
				If AccountingPolicyParameters["DetailDeviations" + DetailField] Then
					DeviationDetailArray.Add(DetailField);
				EndIf;
			EndDo;
			DetailDeviations = StrConcat(DeviationDetailArray, ",");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyReceiptDocuments(Command)
	
	CurrentRow = Undefined;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse") Then
		CurrentRow = Items.OwnProducts.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse") Then 
		CurrentRow = Items.TransferredToCommissionAgent.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5") Then 
		CurrentRow = Items.TransferredToCommissionAgent2_5.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterRemainingGoodsTransferredToVMI") Then 
		CurrentRow = Items.TransferredForStorage.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors") Then 
		CurrentRow = Items.ReceivedPackage.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned") Then 
		CurrentRow = Items.GoodsTransferredToProduction.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5") Then 
		CurrentRow = Items.GoodsTransferredToTollers.CurrentRow;
	ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryShippedGoods") Then
		CurrentRow = Items.TransferOfTitleToGoods.CurrentRow;
		
	EndIf;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	OpenFormPartyDetails(CurrentRow);
	
EndProcedure

&AtClient
Procedure OpenFormPartyDetails(String)
	
	RowData = Object.Goods.FindByID(String);
	
	FormParameters = New Structure;
	FormParameters.Insert("Date",                  Object.Date);
	FormParameters.Insert("Organization",           Object.Organization);
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("SumCompl",             RowData.SumCompl);
	FormParameters.Insert("VATLocal",               RowData.VATLocal);
	
	TempStorageAddress =  PutBatchGranularityInTemporaryStorage(RowData.RowID);
	FormParameters.Insert("TempStorageAddress", TempStorageAddress);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("String", String);
	CallbackDescription = New CallbackDescription("FormDetailingBatchesAtClosing", ThisObject, AdditionalParameters);
	
	OpenForm("Document.OBEntryGoods.Form.LotDetailsForm", FormParameters, ThisObject, ,  , , CallbackDescription);
	
EndProcedure

&AtServer
Function PutBatchGranularityInTemporaryStorage(RowID)
	
	BatchData_ = Object.LotDetails.Unload(New Structure("RowID", RowID));
	
	Return PutToTempStorage(BatchData_, UUID);
	
EndFunction

&AtServer
Procedure FillInAttributeThereIsDetailOfBatchesByLine(String)
	
	CurrentRow = Object.Goods.FindByID(String); 
	
	Filter = New Structure("RowID", CurrentRow.RowID);
	BatchDetailLines = Object.LotDetails.FindRows(Filter);
	CurrentRow.LotDetails = BatchDetailLines.Count() > 0;
	
EndProcedure

&AtServer
Procedure FillInDetailAttribute()
	
	For Each CurrentRow In Object.Goods Do
		FillInAttributeThereIsDetailOfBatchesByLine(CurrentRow.GetID());
	EndDo;
	
EndProcedure

&AtServer
Procedure SetContractAvailability(Terms, ElementAvailability, ItemVisibility, Contract = Undefined)
	
	SetPrivilegedMode(True);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	ContractsAreUsed     = GetFunctionalOption("UseCustomerContracts");
	
	InfluenceFieldsFilledIn = 
		ValueIsFilled(Object.Partner)
		And (ValueIsFilled(Object.Counterparty) Or UsePartnersAsCounterparties)
		And ValueIsFilled(Object.Organization);
		
	If TypeOf(Terms) = Type ("CatalogRef.TermsOfPurchaseFromVendors") Then
		If GetFunctionalOption("UseTermsOfPurchases")
			And ValueIsFilled(Terms) Then
			ContractsAreUsed =
				ContractsAreUsed
				And Common.ObjectAttributeValue(Terms, "ContractsAreUsed");
		EndIf;
	Else
		InfluenceFieldsFilledIn = InfluenceFieldsFilledIn And ValueIsFilled(Terms);
		ContractsAreUsed =
			ContractsAreUsed
			And ValueIsFilled(Terms)
			And Common.ObjectAttributeValue(Terms, "ContractsAreUsed");
	EndIf;
		
	ElementAvailability = InfluenceFieldsFilledIn And ContractsAreUsed;
	
	ItemVisibility = ContractsAreUsed;
	
	If Not ElementAvailability And ValueIsFilled(Object.Contract) Then
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
Procedure PresentationOfInvoiceReceived()
	
	If ThisIsOwnStockBalance Then
		
		RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
		RegistrationParameters.Ref                        = Object.Ref;
		RegistrationParameters.Date                          = Object.Date;
		RegistrationParameters.Organization                   = Object.Organization;
		RegistrationParameters.Counterparty                    = Object.Counterparty;
		RegistrationParameters.VATTaxation            = Object.VATTaxation;
		RegistrationParameters.PurchaseOfGoodsWorksServices = True;
		
		InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
		
		InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBasedOnServer()
	
	Object.Goods.Clear();
	
	If Not ValueIsFilled(Object.Basis) Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("ReconciliationDocument", Object.Basis);
	FillingData.Insert("NextPeriodDocument", False);
	
	Documents.ReconcileOpeningBalancesByWarehouses.FillInBalanceOfGoodsBasedOnReconciliation(Object, FillingData, True);
	
EndProcedure

&AtServer
Procedure SetConditionalRegistrationManagerInHeader()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["OwnProductsManager"].Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItIsMandatoryToFillInTheManager");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Items["OwnProductsManager"].DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["OwnProductsManager"].Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ItIsMandatoryToFillInTheManager");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetConditionalDesignOfDivisionInHeader()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["GoodsTransferredToProductionDivision"].Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DivisionMustBeFilledIn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(Items["GoodsTransferredToProductionDivision"].DataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["GoodsTransferredToProductionDivision"].Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DivisionMustBeFilledIn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfContractByAgreement(ObjectData)
	
	If ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse Then
		SetContractAvailability(ObjectData.TermsOfConsignmentPurchase, Items.ReceivedOnTheCommissionAgreement.Enabled, Items.ReceivedOnTheCommissionAgreement.Visible, ObjectData.Contract);
	ElsIf ObjectData.BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse Then
		SetContractAvailability(ObjectData.TermsOfConsignmentSales, Items.SubmittedToTheCommissionAgreement.Enabled, Items.SubmittedToTheCommissionAgreement.Visible, ObjectData.Contract);
	EndIf;
	SetRequiredContractAttribute();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfLotReferenceInHeader()
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OwnProductsBatch.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartyReceivedForCommission.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubmittedToTheCommissionParty.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AcceptedPackagingBatch.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BatchTransferredToProcessors.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferredToTheManufactureOfTheGoodsTheParty.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivedForStorageLotReferences.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubmittedToCommissionFor25LotReferences.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepositedLotReferences.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferOfOwnershipLotReference.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LotReferenceIsRequiredToBeFilledIn");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Lot");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OwnProductsBatch.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PartyReceivedForCommission.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubmittedToTheCommissionParty.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AcceptedPackagingBatch.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BatchTransferredToProcessors.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferredToTheManufactureOfTheGoodsTheParty.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivedForStorageLotReferences.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubmittedToCommissionFor25LotReferences.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepositedLotReferences.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferOfOwnershipLotReference.Name);
	
	FilterGroup0 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
		ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("LotReferenceIsRequiredToBeFilledIn");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
	
		ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Lot");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetRequiredLotReferenceAttribute()
	
	BusinessOperation = Object.BusinessOperation;
	RecordInOperationalAccounting = Object.RecordInOperationalAccounting;
	PostInCostAccounting = Object.PostInCostAccounting;
	VATTaxation = Object.VATTaxation;
	
	LotReferenceIsRequiredToBeFilledIn = True;
	
	If (RecordInOperationalAccounting Or PostInCostAccounting)
		And (BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse 
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse 
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse2_5
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingGoodsTransferredToVMI
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingReceivedVMI
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfReturnablePackagingReceivedFromVendors
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
			Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
			
			Or BusinessOperation = Enums.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5
			Or BusinessOperation = Enums.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse) Then
		
		If (CostEvaluationMethod <> Enums.InventoryValuationMethods.FIFORollingValuation)
			And (VATTaxation <> Enums.VATTaxationTypes.ByActualUsage
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingMaterialsReceivedForSubcontracting
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingSemiFinishedProductsOfProvider
				Or BusinessOperation = Enums.BusinessTransactions.EnterRemainingManufacturedProductsOfProvider
				Or False) Then
			LotReferenceIsRequiredToBeFilledIn = False;
		EndIf;
		
	Else
		
		If BusinessOperation <> Enums.BusinessTransactions.OBEntryShippedGoods Then
			LotReferenceIsRequiredToBeFilledIn = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfContractInHeader()
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferredToCommission25Contract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubmittedToTheCommissionAgreement.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivedOnTheCommissionAgreement.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferredToProcessorsContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepositedContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GiverSProductsContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractReceivedForStorage.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAcceptedForProcessingContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GiverSSemiFinishedProductsContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferOfOwnershipContract.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ContractMustBeCompleted");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferredToCommission25Contract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SubmittedToTheCommissionAgreement.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivedOnTheCommissionAgreement.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTransferredToProcessorsContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DepositedContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GiverSProductsContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ContractReceivedForStorage.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAcceptedForProcessingContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GiverSSemiFinishedProductsContract.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransferOfOwnershipContract.Name);
	
	FilterGroup0 = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
		ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ContractMustBeCompleted");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
	
		ItemFilter = FilterGroup0.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetRequiredContractAttribute()
	
	ContractMustBeCompleted = Documents.OBEntryGoods.ContractMustBeCompleted(Object);
	
EndProcedure
&AtServer
Procedure FillInExcisableItemAttribute()
	
	If Not UseExcisableGoods Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInExcisableItemAttribute",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFieldTitleIsSubjectToExciseDuty(Form)
	
	NumberOfExcisableItems = Form.Object.Goods.Total("ExcisableGoods");
	Form.Items.SubjectToExcise.Title =
		ExcisableGoodsAccountingClientServer.FieldHeaderIsSubjectToExciseDuty(NumberOfExcisableItems);
	
EndProcedure
&AtServerNoContext
Function VisibilityOfReservesForImpairmentOfInventories()
	
	VisibilityOfReservesForImpairmentOfInventories = False;
	VisibilityOfReservesForImpairmentOfInventories = GetFunctionalOption("AccualInventoryImpairmentProvision");
	Return VisibilityOfReservesForImpairmentOfInventories;
EndFunction

#EndRegion

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
		OwnProductsDateOnChange(Items.OwnProductsDate);
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
