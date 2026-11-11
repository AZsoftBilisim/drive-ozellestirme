#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

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
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	UsePartnersAsCounterparties      = GetFunctionalOption("UsePartnersAsCounterparties");

	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		CalculateRemuneration = True;
		OnReadCreateAtServer();
		Object.BeginOfPeriod = BegOfMonth(Object.Date);
		Object.EndOfPeriod = EndOfMonth(Object.Date);
	EndIf;
	
	KeepCommissionFee  = Object.KeepCommissionFee;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
	RemunerationPercentage = Object.RemunerationPercentage;
	CommissionAmount = Object.CommissionAmount;
	
	DisplayControlCreateBasedOn(Items.CreateBasedOnSubmenu, Object.KeepCommissionFee);
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_InvoiceIssued"
		And ((Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID)
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		
		UpdateInvoiceTextReward();
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		
		ChangedPaymentServer(EventName, Parameter);
		
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);

	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
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

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();

	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		UpdateInvoiceTextReward();
	ElsIf VATAccountingERPClient.FinishedEditingInvoicesToCommissionAgent(ValueSelected, ChoiceSource) Then
		ConfigureDisplayOfInvoiceDetails();
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		ConfigureIntermediaryInvoicePresentation();
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		GetStockTypesFromStorage(ValueSelected);
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		ProcessSelectionOfCCDNumber(ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		Return;
	EndIf;
	
	// If the document is carried out, the correctness of the payment schedule for the order
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		If CalculateRemuneration Then
			ConsignmentSalesClient.YouNeedToCalculateReward(
				New CallbackDescription("BeforeRecordingYouNeedToCalculateReward", ThisObject, AdditionalParameters),
				ThisForm);
		Else
			BeforeRecordingYouNeedToCalculateReward(False, AdditionalParameters);
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingYouNeedToCalculateReward(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If CalculateRemuneration And YouNeedToCalculateReward = True Then
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

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
	
	ConfigureDisplayOfInvoiceDetails();
	UpdateInvoiceTextReward();
	ConfigureIntermediaryInvoicePresentation();
	
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CommissionReportIntercompany", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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
Procedure ConsigneeOnChange(Item)
	
	If ValueIsFilled(Object.Consignee) Then
		ConsigneeOnChangeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	ConsignmentSalesClient.CheckWhetherCurrencyConversionIsNecessaryCommissionReports(
		New CallbackDescription("CurrencyWhenQuestionChangesRecalculateCurrency", ThisObject),
		Object,
		DocumentCurrency);
	
EndProcedure

&AtClient
Procedure CurrencyWhenQuestionChangesRecalculateCurrency(RecalculateCurrency, AdditionalParameters) Export
	
	If RecalculateCurrency Then
		
		CurrencyOnChangeServer(Object.Currency);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		
	Else
		
		FillInPaymentInDefaultCurrency();
		
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
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodStartListChoice(Item, StandardProcessing)

	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;

EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodOnChange(Item)
	
	If Not Object.CommissionFeeCalculationMethod = CommissionFeeCalculationMethod Then
		AdditionalParameters = New Structure("RestoreAttributes", False);
		Notification = New CallbackDescription(
			"MethodOfCalculatingRemunerationWhenChangingItIsNecessaryToCalculateRemunerationCompletion", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(Notification, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfCalculatingRemunerationWhenChangingItIsNecessaryToCalculateRemunerationCompletion(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	ElsIf AdditionalParameters.RestoreAttributes Then
		Object.CommissionFeeCalculationMethod = CommissionFeeCalculationMethod;
	EndIf;
	
	CommissionFeeCalculationMethodOnChangeServer();
	
	If Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		Object.RemunerationPercentage = 0;
		Object.CommissionAmount = 0;
		RemunerationPercentage = 0;
		CommissionAmount = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure VATRateOfRemunerationOnChange(Item)
	
	ConsignmentSalesClient.VATRateOfRemunerationOnChange(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure RemunerationPercentageOnChange(Item)
	
	If Not Object.RemunerationPercentage = RemunerationPercentage Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RestoreAttributes", False);
		AdditionalParameters.Insert("ClearCommission", False);
		CallbackDescription = New CallbackDescription(
			"PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(CallbackDescription, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionAmountOnChange(Item)

	If Not Object.CommissionAmount = CommissionAmount Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RestoreAttributes", False);
		AdditionalParameters.Insert("ClearCommission", False);
		CallbackDescription = New CallbackDescription(
			"PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(CallbackDescription, ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		
		CalculateServerCommission();

		CalculationMethodForNotification = ?(
			AdditionalParameters.ClearCommission,
			PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating"),
			Object.CommissionFeeCalculationMethod);
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(CalculationMethodForNotification);

		RemunerationPercentage = Object.RemunerationPercentage;
		CommissionAmount = Object.CommissionAmount;

	ElsIf AdditionalParameters.RestoreAttributes Then

		Object.RemunerationPercentage = RemunerationPercentage;
		Object.CommissionAmount = CommissionAmount;

	EndIf;
	
EndProcedure

&AtClient
Procedure OperationServiceOnChange(Item)
	
	OperationServiceOnChangeServer();
	
EndProcedure

&AtClient
Procedure KeepCommissionFeeOnChange(Item)
	
	Modified = True;
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
	Object.KeepCommissionFee = KeepCommissionFee;
	Items.PaymentOffsetByRemuneration.Enabled = Not Object.KeepCommissionFee;
	DisplayControlCreateBasedOn(Items.CreateBasedOnSubmenu, Object.KeepCommissionFee);
	ClearPaymentDecryption();
	
EndProcedure

&AtClient
Procedure ARAPAccountingViaSeparateCounterpartyOnChange(Item)
	
	ARAPAccountingViaSeparateCounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure TextListOfTaxInvoicesToConsigneeURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent();
	FillPropertyValues(RegistrationParameters, Object, "Ref, Organization");
	
	RegistrationParameters.Counterparty = ?(Object.ARAPAccountingViaSeparateCounterparty,
										Object.Counterparty,
										Object.Consignee);
	
	VATAccountingERPClient.ProcessingOfInvoiceNavigationLinkToCommissionAgent(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure TextInvoiceRemunerationURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, Object, "Ref, Date");
	
	RegistrationParameters.Organization = Object.Consignee;
	RegistrationParameters.Counterparty  = ?(Object.ARAPAccountingViaSeparateCounterparty,
										Object.Counterparty,
										Object.Organization);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure TextIntermediaryInvoiceURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, Object, "Ref, Date, Organization, VATTaxation");
	
	RegistrationParameters.Counterparty  = ?(Object.ARAPAccountingViaSeparateCounterparty,
										Object.Counterparty,
										Object.Consignee);
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisForm, Var_URL, StandardProcessing,
		RegistrationParameters);
	
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
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

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
		PurchasesClient.FillInListOfCCDNumberSelection(Items.Goods.CurrentData,
														Items.GoodsCCDNumber.ChoiceList);
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
	StructureOfActions.Insert("RecalculateVATAmount",
								BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
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
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
								New Structure("FormName, TabularSectionName", FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForTheRNPTIsMaintained Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
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
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	NumberOfUnitsBeforeRecalculation = CurrentRow.Count;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",
								BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	If CurrentRow.Count > 0 Then
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
	
	If NumberOfUnitsBeforeRecalculation <> 0 Then
		CurrentRow.SellingPrice = CurrentRow.SellingPrice / NumberOfUnitsBeforeRecalculation * CurrentRow.Count;
		
		RecalculateSaleAmount(CurrentRow);
	EndIf;
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateSaleAmount(CurrentRow);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
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

	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
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
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateRemuneration = True;
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);

EndProcedure

&AtClient
Procedure GoodsSellingPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	RecalculateSaleAmount(CurrentRow);
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSalesAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.CommissionAmount = 0;
	ConsignmentSalesClient.SaleAmountWhenChanged(
		CurrentRow,
		True); // ThereIsVATSaleAmount
	
	CalculateRemuneration = True;
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCommissionAmountOnChange(Item)
	
	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	TotalSalesAmount = Object.Goods.Total("SalesAmount");
	Object.RemunerationPercentage = ?(TotalSalesAmount <> 0, Object.CommissionAmount / TotalSalesAmount * 100, 0);
	ConsignmentSalesClient.CalculateCommissionFeeVAT(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure GoodsCustomerOnChange(Item)
EndProcedure

&AtClient
Procedure GoodsIssuedTaxInvoiceOfCommissionAgentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;
	
	InvoiceSelectionParameters = VATAccountingERPClient.ParametersForSelectingInvoiceToReportToCommittee();
	InvoiceSelectionParameters.Organization = Object.Consignee;
	InvoiceSelectionParameters.Date        = CurrentRow.DateOfTaxInvoiceIssuedByCommissionAgent;
	InvoiceSelectionParameters.Customer  = CurrentRow.Customer;
	InvoiceSelectionParameters.SelectedInvoice_ = CurrentRow.IssuedTaxInvoiceOfCommissionAgent;
	
	VATAccountingERPClient.StartSelectingInvoiceToReportToCommittee(Item, InvoiceSelectionParameters, StandardProcessing);
	
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

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateRemuneration = True;
	
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
	
	ClearMessages();

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
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	AdditionalParameters = New Structure;
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(
		FormTable.CurrentData,
		AdditionalParameters);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure CalculateCommissionFee(Command)
	
	ConsignmentSalesClient.YouNeedToCalculateReward(
		New CallbackDescription("CalculateRewardItIsNecessaryToCalculateRewardCompletion", ThisObject),
		ThisForm);
	
EndProcedure

&AtClient
Procedure CalculateRewardItIsNecessaryToCalculateRewardCompletion(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	EndIf;
	
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
Procedure PaymentOffsetSender(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetSenderForm);
	
EndProcedure

&AtClient
Procedure PaymentOffsetRecipient(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetSenderForm);
	
EndProcedure

&AtClient
Procedure OffsetOfPaymentWithTheCommiteeRemuneration(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.OffsetOfPaymentOnTheSideOfTheCommissionAgent);

EndProcedure

&AtClient
Procedure OffsetOfPaymentWithACommissionAgentRemuneration(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.OffsetOfPaymentOnTheSideOfTheCommitee);
	
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
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisForm);
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm,
																		"GoodsVATRate",
																		"GoodsAmountSalesVAT",
																		"GoodsSalesAmount");
	
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
		
		ConfigureDisplayOfInvoiceDetails();
		ConfigureIntermediaryInvoicePresentation();
		
		CalculateTotalsOfCommissionReportBetweenOrganizations(ThisObject);
		
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
Procedure AgreementWhenModifiedOnServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	If UseLinesOfBusiness
		And Not Object.ARAPAccountingViaSeparateCounterparty Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.Contract);
	EndIf;
	
	CompleteVATTaxation();
	Object.ARAPObjectSettings = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
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
	
	ClearPaymentDecryption();
	
EndProcedure

&AtServer
Procedure ConsigneeOnChangeServer()
	
	If UseLinesOfBusiness
		And Object.ARAPAccountingViaSeparateCounterparty Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.SalesContract);
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
	
	UpdateInvoiceTextReward();
	ClearPaymentDecryption();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Consignee");
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	ClearPaymentDecryption();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency)

	SalesServer.ConvertDocumentAmountToCurrency(
		Object,
		DocumentCurrency,
		Object.Currency,
		True, // ThereIsSaleAmount
		True); // ThereIsVATSaleAmount
	CalculateRemuneration = True;
	
	FillInPaymentInDefaultCurrency();
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	ClearPaymentDecryption();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
		
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
	CalculateRemuneration = True;
	
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
Procedure CommissionFeeCalculationMethodOnChangeServer()
	
	FormItemsManagement();
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
	UpdateInvoiceTextReward();
	ConfigureIntermediaryInvoicePresentation();
	
EndProcedure

&AtServer
Procedure OperationServiceOnChangeServer()
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure RecalculateSaleAmount(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	CalculateRemuneration = True;
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	CompleteVATTaxation();
	SetAccountingForTraceableImportedGoodsSettings();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	
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
		ProcessingActions.Insert("RecalculateSaleAmount");
		ProcessingActions.Insert("RecalculateVATSalesAmount");
		ProcessingActions.Insert("ClearRewardAmount");
		
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
	
	CalculateRemuneration = True;
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	SetCommissionAgentSelectionParameters();
	
	Documents.CommissionReportIntercompany.FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(
		Object.CommissionFeeCalculationMethod,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	CashServer.SetAvailabilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
	// The availability of elements depends on the checkbox "Settlements through a separate counterparty".
	CommitteeManOrganization = (Object.Organization = Catalogs.Companies.ManagementCompany);
	
	ShowHideIntermediary();

	Items.IncomingDocumentNumber.Enabled 	= Not CommitteeManOrganization;
	Items.IncomingDocumentDate.Enabled 	= Not CommitteeManOrganization;
	
	CalculationMethodNotCalculated = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	Items.PaymentOffsetByRemuneration.Enabled = Not Object.KeepCommissionFee And Not CalculationMethodNotCalculated;

	Items.KeepCommissionFee.Enabled = Not ReadOnly;
	
	CalculationMethodIsArbitraryAmount = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "RemunerationPercentage", "Visible", Not CalculationMethodIsArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "CommissionAmount", "ReadOnly", Not CalculationMethodIsArbitraryAmount);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ShowHideIntermediary()
		
	Items.GroupIntermediaryCheckResults.Visible = Object.ARAPAccountingViaSeparateCounterparty;
	Items.CounterpartyGroup.Visible                  = Object.ARAPAccountingViaSeparateCounterparty;
	Items.SalesContract.Visible                    = Object.ARAPAccountingViaSeparateCounterparty;
	Items.PurchasingContract.Visible                    = Object.ARAPAccountingViaSeparateCounterparty;
	Items.Contract.Visible                           = Not Object.ARAPAccountingViaSeparateCounterparty;
	Items.IncomingDocumentGroup.Visible            = Object.ARAPAccountingViaSeparateCounterparty;
	Items.IntermediarySInvoiceGroup.Visible       = Object.ARAPAccountingViaSeparateCounterparty;
	
	If Object.ARAPAccountingViaSeparateCounterparty Then
		Object.Contract = Undefined;
	Else
		Object.SalesContract = Undefined;
		Object.PurchasingContract = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	DocumentCurrency = Object.Currency;
	
	FormItemsManagement();
	CheckAndClearCommissionAgent();
	VATPercentage = PriceManagementSystemClientServer.GetVATRateAsNumber(Object.VATRateOfRemuneration);
	
	UseLinesOfBusiness = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness")
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
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
	ConfigureDisplayOfInvoiceDetails();
	UpdateInvoiceTextReward();
	ConfigureIntermediaryInvoicePresentation();
	SetAccountingForTraceableImportedGoodsSettings();
	
	ChangedPaymentServer(Undefined, Undefined);
	
	FillParameters = Documents.CommissionReportIntercompany.ParametersForFillingInVATTaxation_(Object);
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
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
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
	
	CalculateServerCommission();
	
	FillInLines = New Structure;
	FillInLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	FillInLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	FillInLines.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	FillInLines.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	FillInLines.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		FillInLines);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillInLines);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	CalculateTotalsOfCommissionReportBetweenOrganizations(ThisForm);
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(PricesKind)
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
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

// This function is used in the AutoTest of the sales process.
//
&AtServer
Procedure CalculateServerCommission()
	
	ConsignmentSalesServer.CalculateRewardAmount(Object,, True);
	CalculateRemuneration = False;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalsOfCommissionReportBetweenOrganizations(Form)
	
	If Not VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation) Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	EndIf;
	
	RemunerationIsCalculated = Not (Form.Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating"));
	
	Form.Items.TotalRemunerationAmount.Visible = RemunerationIsCalculated;
	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfInvoiceDetails()
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesToCommissionAgent(Object);
	InvoicesToCommissionAgentOnBasisOf = VATAccountingERP.InvoicesToCommissionAgentOnBasisOf(RegistrationParameters);
	
	TextListOfTaxInvoicesToConsignee = InvoicesToCommissionAgentOnBasisOf.Presentation;
	
EndProcedure

&AtServer
Procedure ConfigureIntermediaryInvoicePresentation()
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	TextIntermediaryInvoice = InvoicesReceivedOnBasisOf.Presentation;
	
EndProcedure

&AtServer
Procedure SetCommissionAgentSelectionParameters()
	
	ParametersArray = New Array;
	
	If ValueIsFilled(Object.Organization) Then
		
		ParametersArray.Add(New ChoiceParameter("Filter.LocalAccountingCurrency",
				SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization)));
		ParametersArray.Add(New ChoiceParameter("Filter.RegistrationCountry",
				Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry")));
		
		If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
			ParametersArray.Add(New ChoiceParameter("ModeForSelectingRelatedOrganizations", "JustNotInterconnected"));
		EndIf;
		
	EndIf;
	
	Items.Consignee.ChoiceParameters = New FixedArray(ParametersArray);
	
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
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInvoiceTextReward()
	
	RegistrationParameters = Documents.CommissionReportIntercompany.ParametersForRegisteringInvoicesIssued(Object);
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	
	TextInvoiceRemuneration = InvoicesIssuedOnBasisOf.Presentation;
	
EndProcedure

&AtServerNoContext
Function GetFinancialAccountingGroups(Organization, ARAPCurrency)
	
	Result = New Structure;
	
	BusinessOperation = Enums.TypesOfIntercompanyContracts.Consignment;
	Result.Insert("FinancialAccountingGroup", Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation));
	Result.Insert("FinancialAccountingGroupOfRecipient", Catalogs.FinancialAccountingGroupsOfARAP.GetDefaultFinancialAccountingGroup(Organization, ARAPCurrency, BusinessOperation, True));
	
	Return Result;
	
EndFunction

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

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
		StructureOfActions.Insert("RecalculateSaleAmount");
		StructureOfActions.Insert("RecalculateVATSalesAmount");
		StructureOfActions.Insert("ClearRewardAmount");
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateRemuneration = True;
		
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
Procedure RefreshStatusServer()
		
	Documents.CommissionReportIntercompany.CalculateRecipientState(
		Object.Ref,
		Object.Contract,
		ThisForm, 
		Object.Consignee);
			
	Documents.CommissionReportIntercompany.CalculateSenderState(
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
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	If ChangedBankingDetails.Property("ARAPObjectSettings") Then	
		RefreshStatusServer();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayControlCreateBasedOn(CreateBasedOnSubmenu, KeepCommissionFee)
	
	For Each Item In CreateBasedOnSubmenu.ChildItems Do
		
		NameToSearch1 = NStr("vi = '%Couples1%';
							|ru = '%Couples1%';
							|en = '%Couples1%'; fa = '%Couples1%';
							|it = '%Couples1%';
							|pl = '%Couples1%';
							|tr = '%Couples1%'");
		NameToSearch1 = StrReplace(NameToSearch1, "%Couples1%", "ApplicationForCashExpenditureBasedOnCommissionReport_Remuneration");
		
		NameToSearch2 = NStr("vi = '%Couples1%';
							|ru = '%Couples1%';
							|en = '%Couples1%'; fa = '%Couples1%';
							|it = '%Couples1%';
							|pl = '%Couples1%';
							|tr = '%Couples1%'");
		NameToSearch2 = StrReplace(NameToSearch2, "%Couples1%", "ReceiptOfNonCashCashPaymentsBasedOnCommissionReport_Remuneration");
		
		NameToSearch3 = NStr("vi = '%Couples1%';
							|ru = '%Couples1%';
							|en = '%Couples1%'; fa = '%Couples1%';
							|it = '%Couples1%';
							|pl = '%Couples1%';
							|tr = '%Couples1%'");
		NameToSearch3 = StrReplace(NameToSearch3, "%Couples1%", "WriteOffOfNonCashCashTransactionsBasedOnCommissionReport_Remuneration");
		
		If Find(Item.Name,NameToSearch1) > 0
			Or Find(Item.Name,NameToSearch2) > 0 
				Or Find(Item.Name,NameToSearch3) > 0 Then
			Item.Visible = Not KeepCommissionFee;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearPaymentDecryption()
	
	Object.ARAPDetailsWithCustomer.Clear();
	Object.ARAPDetailsWithVendor.Clear();
	Object.ARAPDetailsWithCustomerRemuneration.Clear();
	Object.ARAPDetailsWithVendorRemuneration.Clear();
	
EndProcedure

&AtServer
Procedure SalesContractOnChangeServer()
	
	If UseLinesOfBusiness
		And Object.ARAPAccountingViaSeparateCounterparty Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, Object.SalesContract);
	EndIf;
	
	CompleteVATTaxation();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "SalesContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SalesServer.EstablishProcedureForSettlementsBetweenOrganizations(Object);
	
EndProcedure

&AtServer
Procedure PurchasingContractOnChangeServer()
	
	CompleteVATTaxation();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "PurchasingContract");
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	SalesServer.EstablishProcedureForSettlementsBetweenOrganizations(Object);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	FillParameters = Documents.CommissionReportIntercompany.ParametersForFillingInVATTaxation_(Object);
	
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure FillInPaymentInDefaultCurrency()
	
	FinancialAccountingGroups = GetFinancialAccountingGroups(Object.Organization, Object.Currency);
	Object.FinancialAccountingGroup = FinancialAccountingGroups.FinancialAccountingGroup;
	Object.FinancialAccountingGroupOfRecipient = FinancialAccountingGroups.FinancialAccountingGroupOfRecipient;
	
EndProcedure

&AtServer
Procedure ARAPAccountingViaSeparateCounterpartyOnChangeServer()
	
	If UseLinesOfBusiness Then
		DefiningContract = ?(Object.ARAPAccountingViaSeparateCounterparty, Object.SalesContract, Object.Contract);
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Undefined, DefiningContract);
	EndIf;
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	ShowHideIntermediary();
	ConfigureIntermediaryInvoicePresentation();
	
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
