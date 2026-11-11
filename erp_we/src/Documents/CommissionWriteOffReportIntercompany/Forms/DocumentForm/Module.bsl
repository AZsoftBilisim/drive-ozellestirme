#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		Object.BeginOfPeriod = BegOfMonth(Object.Date);
		Object.EndOfPeriod = EndOfMonth(Object.Date);
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CommissionWriteOffReportIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If Object.Patch Then
		Items.GoodsFillInByBalance.Visible = False;
	EndIf;
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.CommissionWriteOffReportIntercompany.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		GetStockTypesFromStorage(ValueSelected);
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		ProcessSelectionOfCCDNumber(ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		Return;
	EndIf;
	
	FormEventsClient.BeforeWrite(ThisForm, Cancel, WriteParameters);
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	WriteParameters.Insert("InvoiceData_3", Undefined);
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInLines = New Structure;
	FillInLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	FillInLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	FillInLines.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	FillInLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		FillInLines);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillInLines);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CommissionWriteOffReportIntercompany", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	VATAmount = Object.Goods.Total("VATAmount");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		ChangedPaymentServer(EventName, Parameter);
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions,
			"Organization");
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	AgreementWhenModifiedOnServer();
EndProcedure

&AtClient
Procedure SalesContractOnChange(Item)
	
	SalesContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure PurchasingContractOnChange(Item)
	
	PurchasingContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();

EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		CurrencyOnChangeServer(Object.Currency);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If ValueIsFilled(Object.PriceKind)
		And Object.Goods.Count() > 0 Then
		ShowQueryBox(
			New CallbackDescription("PriceKindOnChangeCompletion", ThisObject),
				NStr("vi = 'Điền lại giá trong phần bảng chứng từ?';
					|ru = 'Перезаполнить цены в табличной части документа?';
					|en = 'Refill prices in the table of the document?'; fa = 'Refill prices in the table of the document?';
					|it = 'Ricompilare i prezzi nella parte tabulare del documento?';
					|pl = 'Wypełnić ponowie ceny w części tabelarycznej dokumentu?';
					|tr = 'Belgenin tablo bölümündeki fiyatları yeniden doldur?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    ClearMessages();
    
    ResponseCode = QuestionResult;
    If ResponseCode = DialogReturnCode.Yes Then
        FillInPricesByPriceKindServer(Object.PriceKind);
    EndIf;

EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
	RecalculateTotalAmount_();
EndProcedure

&AtClient
Procedure ARAPAccountingViaSeparateCounterpartyOnChange(Item)
	ARAPAccountingViaSeparateCounterpartyOnChangeServer();
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();

EndProcedure

&AtClient
Procedure ConsigneeOnChange(Item)
	ConsigneeOnChangeServer();
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	CounterpartyOnChangeServer();
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);
	
	FormEventsClient.URLProcessing(ThisForm, FormattedStringURL, StandardProcessing);
	
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
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		CurrentRow = Items.Goods.CurrentData;
		CurrentRow.PriceKind = Object.PriceKind;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Organization");
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)

	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));

	If CurrentRow.Count > 0 And Not ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;

	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Organization");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
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
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If ValueIsFilled(CurrentRow.PriceKind)
	 And CurrentRow.Price <> 0 Then
		CurrentRow.PriceKind = Undefined;
	EndIf;
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	RecalculateTotalAmount_();
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
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		Actions,
		"Organization");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
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

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure SetDateIntervalExecute(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));

EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Người đặt ký gửi';
																	|ru = 'Комитент';
																	|en = 'Consignor'; fa = 'امانت‌گذار';
																	|it = 'Committente';
																	|pl = 'Komitent';
																	|tr = 'Gönderici'"));
	CheckParameters.CheckedAttributes.Insert("Consignee", NStr("vi = 'Người nhận bán ký gửi';
																|ru = 'Комиссионер';
																|en = 'Consignee'; fa = 'امانت‌دار';
																|it = 'Commissionario';
																|pl = 'Komisant';
																|tr = 'Konsinye'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	Notification = New CallbackDescription("FillInByBalanceCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Goods';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesByPriceKindCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseForIntercompanySales = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable	= Items.Goods;
	TableData	= Object.Goods;
	
	AdditionalParameters = New Structure;
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(
		FormTable.CurrentData,
		AdditionalParameters);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PaymentOffsetSender(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetSenderForm);
	
EndProcedure

&AtClient
Procedure PaymentOffsetRecipient(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetRecipientForm);
	
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

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	//
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	
	//
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	
	//
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);
	
	//
	ItemsTypes = New ValueList;
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumberOriginCountry.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue		= New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType		= DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue	= ItemsTypes;
	
	Item.Appearance.SetParameterValue("Text",				NStr("vi = '<cho hàng hóa>';
																	|ru = '<для товаров>';
																	|en = '<for goods>'; fa = '<for goods>';
																	|it = '<per le merci>';
																	|pl = '<dla towarów>';
																	|tr = '<ürünler için>'"));
	Item.Appearance.SetParameterValue("TextColor",		StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly",	True);
	
	//
	AccountingForTraceableGoodsLocalization.EstablishConditionalAppearanceOfAccountingOnGTDVDocumentsOfCommissionAgent(ThisForm);
	
	//
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
EndProcedure

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",
								BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Organization");
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If ValueIsFilled(Object.Organization) Then
		CompleteVATTaxation();
		RecalculateNumberOfRNPT();
		
		If UseLinesOfBusiness
			And Not Object.ARAPAccountingViaSeparateCounterparty Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.Contract);
		EndIf;
		
		CalculateTotalsOfCommissionReportBetweenOrganizations(ThisObject);
		
		SetCommissionAgentSelectionParameters();
		CheckAndClearCommissionAgent();
		
		FormItemsManagement();
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
																					Object.CompanyBankAccount,
																					Undefined,
																					Object.LineOfBusiness,
																					Object.ForeignCurrencyTransaction);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization,
																		Object.CashAccount,
																		Undefined,
																		Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ClearPaymentDecryption();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization");
	
EndProcedure

&AtServer
Procedure ConsigneeOnChangeServer()
	
	If UseLinesOfBusiness
		And Object.ARAPAccountingViaSeparateCounterparty Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.PurchasingContract);
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Consignee,
																					Object.RecipientCompanyBankAccount,
																					Undefined,
																					Object.LineOfBusiness,
																					Object.ForeignCurrencyTransaction);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Consignee,
																		Object.CashAccountRecipient,
																		Undefined,
																		Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Consignee");
	
	ClearPaymentDecryption();
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	Object.ARAPObjectSettings = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	If UseLinesOfBusiness
		And Not Object.ARAPAccountingViaSeparateCounterparty Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.Contract);
	EndIf;
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		Object.RecipientCompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.RecipientCompanyBankAccount);
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = ComplCurrency;
		Object.CompanyBankAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If Not ValueIsFilled(Object.RecipientCompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Consignee);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = ComplCurrency;
		Object.RecipientCompanyBankAccount =
			CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	CompleteVATTaxation();
	ClearPaymentDecryption();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency)

	SalesServer.ConvertDocumentAmountToCurrency(
			Object, 
			DocumentCurrency, 
			Object.Currency,
			False); // ThereIsSaleAmount
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	ClearPaymentDecryption();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	If Object.Patch Then
		ParametersForFillingInVATRate.Date = Common.ObjectAttributeValue(Object.CorrectedDocument, "Date");
	EndIf;
	StructureOfActions.Insert("AdjustVATRate",  ParametersForFillingInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	SetAccountingForTraceableImportedGoodsSettings();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
	CompleteVATTaxation();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If ValueIsFilled(Object.LineOfBusiness) Then
		AttributesStructure1 = Common.ObjectAttributesValues(Object.LineOfBusiness, "IncomeAccounting, CostAccounting");
		If Not AttributesStructure1.IncomeAccounting Or Not AttributesStructure1.CostAccounting Then
			Object.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		EndIf;
	EndIf;
	CompleteVATTaxation();
	ClearPaymentDecryption();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	ClearPaymentDecryption();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
		
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
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
	
	If SelectionData_1.ResidualNumberOfCCD <> Undefined Then
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, Object);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions,
			"Organization");
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisObject);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
	ShowHideIntermediary();
	
	// The availability of elements depends on the checkbox "Settlements through a separate counterparty".
	CommitteeManOrganization = (Object.Organization = Catalogs.Companies.ManagementCompany);
	Items.IncomingDocumentNumber.Enabled = Not CommitteeManOrganization;
	Items.IncomingDocumentDate.Enabled = Not CommitteeManOrganization;
EndProcedure

&AtServer
Procedure ShowHideIntermediary()
	Items.Partner.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.CounterpartyGroup.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.SalesContract.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.PurchasingContract.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.Contract.Visible = Not Object.ARAPAccountingViaSeparateCounterparty;
	Items.IncomingDocumentGroup.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	
	If Object.ARAPAccountingViaSeparateCounterparty Then
		Object.Contract = Undefined;
	Else
		Object.SalesContract = Undefined;
		Object.PurchasingContract = Undefined;
	EndIf;

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	DocumentCurrency = Object.Currency;
	FormItemsManagement();
	CheckAndClearCommissionAgent();
	
	UseLinesOfBusiness	= GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
			Or GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	FillInLines = New Structure;
	FillInLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	FillInLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	FillInLines.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	FillInLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		FillInLines);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillInLines);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisObject);
	
	SetAccountingForTraceableImportedGoodsSettings();
	
	ChangedPaymentServer(Undefined, Undefined);
	
	FillParameters = Documents.CommissionWriteOffReportIntercompany.ParametersForFillingInVATTaxation_(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
EndProcedure

&AtServer
Procedure SetAccountingForTraceableImportedGoodsSettings()
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	TheCommissionAgentDoesNotKeepRecordsOnTheRNPT = Not UseTraceableImportedGoodsAccounting;
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisObject, Object.Date);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	If ValueIsFilled(Object.Organization) Then
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object,
												"Organization");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInByBalanceServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInGoodsOnBalancesForRegistration(Object.EndOfPeriod);
	ValueToFormAttribute(DocumentObject, "Object");
	
	FillInLines = New Structure;
	FillInLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	FillInLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	FillInLines.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	FillInLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		FillInLines);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillInLines);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisObject);
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(PricesKind)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfActions = New Structure("RecalculateAmount, RecalculateAmountWithVAT, RecalculateVATAmount",
		"NumberOfPackages", StructureOfRecalculationOfAmount, StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, , FillParameters, StructureOfActions);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
	Return PricesCalculated;
EndFunction

&AtServer
Procedure PartnerOnChangeServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(
		Object.Partner,
		Object.Counterparty);
	CounterpartyOnChangeServer();
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalsOfCommissionReportBetweenOrganizations(Form)
	
	If Form.Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsNotSubjectToVAT") Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckAndClearCommissionAgent()
	
	If ValueIsFilled(Object.Organization)
		And ValueIsFilled(Object.Consignee) Then
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Object.Organization, Object.Consignee);
		If (GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets")
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.Consignee))
			Or (Not CheckStructure.CurrenciesDoNotMatch Or Not CheckStructure.CountriesMatch) Then
				Object.Consignee = Undefined;
		EndIf;
	EndIf
	
EndProcedure

&AtServer
Procedure SetCommissionAgentSelectionParameters()
	
	ParametersArray = New Array;
	
	If ValueIsFilled(Object.Organization) Then
		
		ParametersArray.Add(New ChoiceParameter("Filter.LocalAccountingCurrency",
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization)));
		ParametersArray.Add(New ChoiceParameter("Filter.RegistrationCountry",
				Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry")));
		
	EndIf;
	
	Items.Consignee.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

#EndRegion

&AtClient
Procedure RecalculateTotalAmount_()
	VATAmount = Object.Goods.Total("VATAmount");
	Object.DocumentAmount = Object.Goods.Total("AmountIncludingVAT");
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

// StandardSubsystems.AttachableCommands
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
Procedure FillInPricesByPriceKindCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesByPriceKindServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInByBalanceCompletion(Result, AdditionalParameters) Export
	
	FillInByBalanceServer();
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
		
		AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearPaymentDecryption()
	
	Object.ARAPDetailsWithCustomer.Clear();
	Object.ARAPDetailsWithVendor.Clear();
	
EndProcedure

&AtServer
Procedure SalesContractOnChangeServer()
	
	CompleteVATTaxation();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "SalesContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SalesServer.EstablishProcedureForSettlementsBetweenOrganizations(Object);
	
EndProcedure

&AtServer
Procedure PurchasingContractOnChangeServer()
	
	If UseLinesOfBusiness
		And Object.ARAPAccountingViaSeparateCounterparty Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.PurchasingContract);
	EndIf;
	
	CompleteVATTaxation();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "PurchasingContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SalesServer.EstablishProcedureForSettlementsBetweenOrganizations(Object);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()

	FillParameters = Documents.CommissionWriteOffReportIntercompany.ParametersForFillingInVATTaxation_(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure RefreshStatusServer()
		
	Documents.CommissionWriteOffReportIntercompany.CalculateRecipientState(
		Object.Ref,
		Object.Contract,
		ThisForm, 
		Object.Consignee);
			
	Documents.CommissionWriteOffReportIntercompany.CalculateSenderState(
		Object.Ref,
		Object.Contract,
		ThisForm, 
		Object.Organization);
	
EndProcedure

&AtServer
Procedure ChangedPaymentServer(EventName, Parameter)
	
	RefreshStatusServer();
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		If ChangedBankingDetails.Count() > 0 Then
			LabelPaymentStagesClickCompletionServer(ChangedBankingDetails);
		EndIf;
		
	EndIf;
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtServer
Procedure LabelPaymentStagesClickCompletionServer(ChangedBankingDetails)
	
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then	
		RefreshStatusServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure ARAPAccountingViaSeparateCounterpartyOnChangeServer()
	
	If UseLinesOfBusiness Then
		DefiningContract = ?(Object.ARAPAccountingViaSeparateCounterparty, Object.PurchasingContract, Object.Contract);
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, DefiningContract);
	EndIf;
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	ShowHideIntermediary();
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
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
