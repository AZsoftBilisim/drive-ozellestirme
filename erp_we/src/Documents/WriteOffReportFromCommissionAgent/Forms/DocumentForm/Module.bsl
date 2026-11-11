#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();

	DefaultBusinessTransaction = Documents.WriteOffReportFromCommissionAgent.DefaultBusinessTransaction();
	
	ManagingRelationshipsOfFormDetailsSelectionParameters();
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SalesServer.SetBlankContractMark(Items, "Contract");
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffReportFromCommissionAgent.ItemsAndDimensionsSelectionParameters(DefaultBusinessTransaction);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	FillingCommands = New Array();
	FillingCommands.Add(Items.GoodsRecalculateBalancesBasedOnAccountingData);
	FillingCommands.Add(Items.GoodsSelectionByStock);
	If Object.Patch Then
		For Each FillingCommand In FillingCommands Do
			FillingCommand.Visible = False;
		EndDo;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	CashClientLocalization.AttachablePaymentVerificationViaServices(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	CashClientLocalization.DisablePaymentVerificationViaServices(ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	ClearMessages();
	
	If ChoiceSource.FormName = "CommonForm.SelectByGoodsTransferredToCommissionAgent" Then
		
		GetProductsFromStorage(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		
		GetStockTypesFromStorage(ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
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
	
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		ContractOnChange(Items[Parameter]);
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
		CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);
	EndIf;
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, Actions);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffReportFromCommissionAgent.ItemsAndDimensionsSelectionParameters(ThisForm.DefaultBusinessTransaction);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	UnlockFormDataForEdit();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_WriteOffReportFromCommissionAgent", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
		

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	ClearMessages();
	
	If QuestionResult = True Then
	
		RecalculatePrices_2 = True;
		PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	
		If RecalculatePrices_2 Then
			SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		EndIf;
		
	Else
		
		DateOnChangeServer(False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		RecalculateAmounts = PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency);
		CurrencyOnChangeServer(Object.Currency, RecalculateAmounts);
		If RecalculateAmounts Then
			PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		EndIf;
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	FillInPaymentInDefaultCurrency();
		
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If ValueIsFilled(Object.Partner) Then
		PartnerOnChangeServer();
		If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
			SalesClient.NotifyEndOfFillingInDefaultSalesConditions();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.Terms) Then
		TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = False;
		Return;
	EndIf;
	
	TermsOnChangeServer();
	SalesClient.NotifyEndOfFillingInTermsOfSale();
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.BusinessOperation       = DefaultBusinessTransaction;
	AgreementSelectionParameters.FormDataStructure        = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ClearMessages();
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	VATTaxationOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer(Undefined);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm,"Date");
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure ByPhysicalCountResultsOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	If Not ValueIsFilled(Object.IncomeItem) Then
		Object.DimensionOfRevenue = Undefined;
	EndIf;
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	FillInSubordinatePropertiesForStatistics("IncomeItem");
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	If Not ValueIsFilled(Object.ExpenseItem) Then
		Object.DimensionOfExpenses = Undefined;
	EndIf;
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	FillInSubordinatePropertiesForStatistics("ExpenseItem");

EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	ClearMessages();
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ValueIsFilled(CurrentData.PriceKind) Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	If Item.CurrentItem = Items.GoodsCCDNumber Then
		
		PurchasesClient.FillInListOfCCDNumberSelection(
			Items.Goods.CurrentData, Items.GoodsCCDNumber.ChoiceList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Goods.CurrentData;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "Goods", CurrentRow, NewRow, Copy);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	ClearMessages();

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForTheRNPTIsMaintained Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 And Not ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf CurrentRow.Count > 0 And ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	ElsIf (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesRealOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesAfterFact");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	If Object.ByPhysicalCountResults Then
		CurrentRow.NumberOfPackagesReal = CurrentRow.NumberOfPackagesAccounting - CurrentRow.NumberOfPackages;
	EndIf;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure("CCDNumber", CurrentData.CCDNumber);
	
	Actions = New Structure;
	Actions.Insert("FillInCCDNumberType", FillParameters);
	Actions.Insert("FillInCountryOfOriginForCCDNumber", FillParameters);
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.BasisOfCostOfAdmission = False;
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure SetDateIntervalExecute(Command)
	
	TMCommonUseClient.EditPeriod(Object,
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));

EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người nhận bán ký gửi';
																|ru = 'Комиссионер';
																|en = 'Consignee'; fa = 'امانت‌دار';
																|it = 'Commissionario';
																|pl = 'Komisant';
																|tr = 'Konsinye'"));
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	
	AddressOfPaymentsInTheStorage = PutProductsInStorage(
		Object.Goods,
		UUID);
		
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressOfPaymentsInTheStorage", AddressOfPaymentsInTheStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	PickingParameters.Insert("ByPhysicalCountResults", Object.ByPhysicalCountResults);
	
	OpenForm(
		"CommonForm.SelectByGoodsTransferredToCommissionAgent",
		PickingParameters, 
		ThisForm);
	
EndProcedure

&AtClient
Procedure RecalculateBalancesBasedOnAccountingData(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người nhận bán ký gửi';
																|ru = 'Комиссионер';
																|en = 'Consignee'; fa = 'امانت‌دار';
																|it = 'Commissionario';
																|pl = 'Komisant';
																|tr = 'Konsinye'"));
	Notification = New CallbackDescription("RecalculateBalancesBasedOnAccountingDataCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure RecalculateBalancesBasedOnAccountingDataCompletion(Result, AdditionalParameters) Export 
	
	RecalculateBalancesBasedOnAccountingDataServer();
	
	ShowUserNotification(
		NStr("vi = 'Hàng tồn kho (kế toán) đã điền';
			|ru = 'Остаток (учет) заполнен.';
			|en = 'Book quantity entered.'; fa = 'Book quantity entered.';
			|it = 'Saldo (contabilità) è compilato.';
			|pl = 'Saldo (ewidencja) jest wypełnione.';
			|tr = 'Bakiye (muhasebe) tamamlanmıştır.'"),
		,
		NStr("vi = 'Hàng tồn kho theo dữ liệu kế toán trong chứng từ đã điền';
			|ru = 'Остаток по данным учета в документе заполнен.';
			|en = 'Balance by accounting data is filled in the document.'; fa = 'Balance by accounting data is filled in the document.';
			|it = 'Il saldo secondo i dati contabili è compilato.';
			|pl = 'Saldo danych ewidencji w dokumencie jest wypełnione.';
			|tr = 'Belgedeki muhasebe verilerine göre bakiye doldurulur.'"),
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	ClearMessages();

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Towary';
																									|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(ExecutionResult, Var_Parameters) Export
	
	If ExecutionResult.Result Then
		ProcessBarcodes(ExecutionResult.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.ImportPrices = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.FillingDate     = Object.Date;
	ImportParameters.FilterParameters.Insert("ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

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
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure Attachable_UpdateSBPPaymentStatus(Command)

	ClearMessages();
	CashClientLocalization.UpdateStatusOfSBPPaymentByDocument(ThisObject, Object.Ref);

EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	//
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisObject);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeItem.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TotalAmountWithVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IncomeItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IncomeItem.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TotalAmountWithVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IncomeItem");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateNumberOfPackagesFactByPackages");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(Form, StructureOfActions)
	
	If Form.TheCommissionAgentDoesNotKeepRecordsOnTheRNPT Then
		Return;
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Form.Object,
		StructureOfActions,
		"Partner");
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
		RecalculateNumberOfRNPT();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	AttributesArray = New Array;
	
	If ToUseTermsOfSales Then
		FillIn_TermsOfSales();
		AttributesArray.Add("Currency");
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		AttributesArray.Add("Terms");
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	FormItemsManagement();
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	CalculateFinalIndicatorsOfCommissionAgentSReportOnWriteOff(ThisForm);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
		
EndProcedure

&AtServer
Procedure TermsOnChangeServer()

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInTermsOfSalesUnderAgreement();
	ResponsiblePersonsServer.FillInManager_(DocumentObject);
	ValueToFormAttribute(DocumentObject, "Object");
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
	DocumentCurrency = Object.Currency;
	AttributesArray = New Array;
	AttributesArray.Add("Currency");
	AttributesArray.Add("Partner");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
		
	FormItemsManagement();
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	CalculateFinalIndicatorsOfCommissionAgentSReportOnWriteOff(ThisForm);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	FillInPaymentInDefaultCurrency();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	Object.ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract,"ForeignCurrencyTransaction");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)

		
	FillInDefaultContract();

	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
		
	If RecalculateAmounts Then
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, Object.Date);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency, Object.Date);
		
		TotalAmount_5 = Object.Goods.Total("Sum");
		
		NewAmount = ProcessingOfExchangeRatesTM.ConvertAtRate(
			TotalAmount_5,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
			
		If TotalAmount_5 <> 0 Then
		
			For Each TableRow In Object.Goods Do
				
				TableRow.Sum = Round(NewAmount * TableRow.Sum / TotalAmount_5, 2, 1);
				TableRow.Price = ?(TableRow.NumberOfPackages <> 0, Round(TableRow.Sum / TableRow.NumberOfPackages, 2, 1), 0);
				TableRow.VATAmount = PriceManagementSystemClientServer.CalculateVATAmount(TableRow.Sum, TableRow.VATRate, Object.PriceIncludesVAT);
				TableRow.AmountIncludingVAT = TableRow.Sum + ?(Object.PriceIncludesVAT, 0, TableRow.VATAmount);
				
			EndDo;
			
		EndIf;
	EndIf;
	
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues = Undefined)
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If Object.Patch Then
		ParametersForFillingInVATRate.Date = Common.ObjectAttributeValue(Object.CorrectedDocument, "Date");
	EndIf;
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	CalculateFinalIndicatorsOfCommissionAgentSReportOnWriteOff(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	FillInDefaultContract();
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
		
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutProductsInStorage(Val Goods, Var_UUID)

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Goods.Unload(,"Products, Characteristic, CCDNumber, Count, QuantityByGBRN"),
		Var_UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure GetProductsFromStorage(AddressOfPaymentsInTheStorage)
	
	Object.Goods.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	
	EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		, // Array of rows or selection structure
		FillParameters);
		
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If Object.Patch Then
		ParametersForFillingInVATRate.Date = Common.ObjectAttributeValue(Object.CorrectedDocument, "Date");
	EndIf;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	RecalculateNumberOfRNPT();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	StructureOfActionsWithAddedStrings = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;

	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActionsWithAddedStrings);
	
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, StructureOfActionsWithModifiedStrings);

	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;	
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

#EndRegion

#Region CCDNumbers

&AtClient
Procedure ProcessSelectionOfCCDNumber(CalculationResult1)
	
	CurrentData = Items.Goods.CurrentData;
	
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
	
	ProcessingActions = New Structure;
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisObject, ProcessingActions);
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, Object);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	Items.GoodsNumberOfPackagesAccounting.Visible = Object.ByPhysicalCountResults;
	Items.GoodsNumberOfPackagesReal.Visible = Object.ByPhysicalCountResults;
	Items.GoodsRecalculateBalancesBasedOnAccountingData.Visible = Object.ByPhysicalCountResults;
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	ToUseTermsOfSales               = GetFunctionalOption("ToUseTermsOfSales");
	UseLinesOfBusiness            = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	UseTraceableImportedGoodsAccounting =
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Object.Date);
	
	DocumentCurrency = Object.Currency;
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	FormItemsManagement();
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	StructureCharacteristicsOfProducts.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureCharacteristicsOfProducts);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	CalculateFinalIndicatorsOfCommissionAgentSReportOnWriteOff(ThisForm);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	SetPropertiesOfOutdatedCommissionUsageComment();
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
			
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			And UseLinesOfBusiness Then
	
		Contract = SalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.TransferToCommissionAgent, 
															Object.Currency, 
															Object.LineOfBusiness,
															False);
	Else
															
		Contract = SalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.TransferToCommissionAgent, 
															Object.Currency,,
															False);
	EndIf;	
		
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	EndIf;
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
	If Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
		ErrorText = 
		NStr("vi = 'Các giá trị đã đặt cho trường ""Đơn giá gồm thuế GTGT"" trong chứng từ và thỏa thuận là khác nhau.';
			|ru = 'Установленные значения полей ""Цена включает НДС"" в документе и соглашении разные.';
			|en = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.'; fa = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.';
			|it = 'I valori impostati dei campi ""Prezzo IVA inclusa"" nel documento e nell''accordo differiscono.';
			|pl = 'Ustawione wartości pól ""Cena brutto"" w dokumencie i umową są różne.';
			|tr = 'Belgedeki ve sözleşmedeki ""KDV dahildir"" alanlarının hesaplanan değerleri farklıdır.'");
		Return False;
	EndIf;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(Object.EndOfPeriod), Object.EndOfPeriod, Object.Date));
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure RecalculateBalancesBasedOnAccountingDataServer()
	
	ConsignmentSalesServer.RecalculateBalancesBasedOnAccountingData(
		Object,
		Object.EndOfPeriod,
		False); // ThereIsSaleAmount
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfCommissionAgentSReportOnWriteOff(Form)
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;

EndProcedure

&AtServer
Procedure FillIn_TermsOfSales()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInDefaultSalesConditions();
	ValueToFormAttribute(DocumentObject, "Object");
	
	DocumentCurrency = Object.Currency;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(ThisForm, StructureOfActions);
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	RowsToProcess = New Array;
	
	For Each RowOfGoods In ItemsFromStorage Do
		
		StringTSGoods = Object.Goods.Add();
		FillPropertyValues(StringTSGoods, RowOfGoods);
		RowsToProcess.Add(StringTSGoods);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	CalculateFinalIndicatorsOfCommissionAgentSReportOnWriteOff(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure FillInPaymentInDefaultCurrency()
	
	Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(DocumentCurrency, Object.Organization);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AddSBPPaymentStatusUpdateCommand();
	EndIf;
		
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CommandParameters.Parent = Items.CreditPaymentForm;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

&AtClient
Procedure Attachable_SBPPaymentVerification()

	CashClientLocalization.CheckSBPPayment(ThisObject, Object.Ref, Object.Counterparty);

EndProcedure

#EndRegion

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	// Subsystem "Properties"
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure ManagingRelationshipsOfFormDetailsSelectionParameters()
	
	//Agreement, we add a link with the details of the business operation form to silence
	FormItem = Items.Terms;
	NewSelectionParameterRelationships = New Array;
	For Each RelationshipOfSelectionParameters In FormItem.ChoiceParameterLinks Do
		If Not RelationshipOfSelectionParameters.Name = "Filter.BusinessOperation" Then
			NewSelectionParameterRelationships.Add(RelationshipOfSelectionParameters);
		EndIf;
	EndDo;
	ChoiceParameter = New ChoiceParameterLink("Filter.BusinessOperation", "DefaultBusinessTransaction", LinkedValueChangeMode.DontChange);
	NewSelectionParameterRelationships.Add(ChoiceParameter);
	FormItem.ChoiceParameterLinks = New FixedArray(NewSelectionParameterRelationships);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure FillInCommissionAgentDoesNotKeepRecordsOfRPTOnServer()
	
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT =
		Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Object.Terms);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If Not TheCommissionAgentDoesNotKeepRecordsOnTheRNPT
		And ValueIsFilled(Object.Organization) Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Partner");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

EndProcedure

&AtServer
Procedure SetPropertiesOfOutdatedCommissionUsageComment()
	
	Items.CommentUsingOutdatedCommission.Title = ConsignmentSalesServer.CommentUsingOutdatedCommission();
	
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
