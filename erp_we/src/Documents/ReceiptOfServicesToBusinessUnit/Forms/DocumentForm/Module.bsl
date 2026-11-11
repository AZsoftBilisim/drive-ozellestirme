#Region Variables

&AtClient
Var PreviousRowDetails; //used to unlink the receipt line from the order line

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

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

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.Contract);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	
	SetAvailabilityOfClipboardCommands();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.Contract);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);	
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	
	EstablishAvailabilityOfTSServices();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.Contract);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(SelectionResult);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters,,True);
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_UninvoicedReceipt", WriteParameters, Object.Ref);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PreviousRowDetails = New Structure("Products");
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = Items.AdvancedGroup.Name
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date);

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Object.Terms = PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef");
		PartnerClearingServer();
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
	AdditionalParameters = AdditionalCompletionProcessingParameters();
	AdditionalParameters.Item = Item;
	
	QuestionUserBeforeFillingInAgreement(
		New CallbackDescription("PartnerWhenChangingQuestionEnds", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	QuestionUserBeforeFillingInAgreement(
		New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	WhenChangingAgreementServer(True);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	WhenBusinessTransactionChangesServer();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure VendorPriceKindOnChange(Item)
	
	If Not ValueIsFilled(Object.VendorPriceKind) Then
		Return;
	EndIf;
	
	QueryText       = NStr("vi = 'Điền lại đơn giá theo dạng giá?';
							|ru = 'Перезаполнить цены по виду цены?';
							|en = 'Refill prices by the price type?'; fa = 'Refill prices by the price type?';
							|it = 'Ricompilare i prezzi per tipo di prezzo?';
							|pl = 'Wypełnić ponownie wg rodzaju cen?';
							|tr = 'Fiyat türüne göre fiyatlar yeniden doldurulsun mu?'");
	CallbackDescription = New CallbackDescription("SupplierSPriceViewWhenQuestionChanges", ThisObject);
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Перезаполнить';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False,   NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription, QueryText, AnswersOptions);
	
EndProcedure

&AtClient
Procedure SupplierSPriceViewWhenQuestionChanges(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer <> Undefined
		And UserAnswer Then
		
		FillInPricesBySupplierPriceType();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification, "Services");
	
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
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATActivityTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(DocumentCurrency) Then
		DocumentCurrency = Object.Currency;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		Return;
	EndIf;
	
	If DocumentCurrency <> Object.Currency
		And Object.Services.Total("Price") > 0 Then
		
		MessageText = NStr("vi = 'Tính lại số tiền trong chứng từ theo nguyên tệ ""%Currency%""?';
							|ru = 'Пересчитать суммы в документе в валюту ""%Currency%""?';
							|en = 'Convert amounts in the document in %Currency%?'; fa = 'Convert amounts in the document in %Currency%?';
							|it = 'Ricalcolare gli importi del documento in valuta ""%Currency%""?';
							|pl = 'Przeliczyć kwoty w dokumencie na walutę ""%Currency%""?';
							|tr = 'Belgedeki tutarlar ""%Currency%"" para birimine göre yeniden hesaplansın mı?'");
		MessageText = StrReplace(MessageText, "%Currency%", Object.Currency);
		
		Notification = New CallbackDescription("RecalculateAmountsWhenChangingCurrency", ThisObject);
		ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo);
	Else
		DocumentCurrency = Object.Currency;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReferenceOrderPresentationURLProcessing(Item,
																FormattedStringURL,
																StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "Open_Order" Then
		ShowValue(, Object.ReferenceOrder)
	Else
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement("Document.ReceiptOfServicesToBusinessUnit.Form.SelectReference");
		
		OrderSelectionFormParameters = New Structure;
		OrderSelectionFormParameters.Insert("Partner",				Object.Partner);
		OrderSelectionFormParameters.Insert("Counterparty",				Object.Counterparty);
		OrderSelectionFormParameters.Insert("Terms",				Object.Terms);
		OrderSelectionFormParameters.Insert("BusinessOperation",	Object.BusinessOperation);
		OrderSelectionFormParameters.Insert("Organization",			Object.Organization);
		OrderSelectionFormParameters.Insert("Contract",				Object.Contract);
		
		CallbackDescription = New CallbackDescription("CustomerSChoice", ThisObject);
		
		OpenForm("Document.ReceiptOfServicesToBusinessUnit.Form.SelectReference",
					OrderSelectionFormParameters,
					ThisObject,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure StructuralUnitOnChange(Item)
	
	UpdateTypeOfVATActivity();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServices

&AtClient
Procedure ServicesBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousRowDetails, Items.Services.CurrentData);
	
EndProcedure

&AtClient
Procedure ServicesOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.Services.CurrentData <> Undefined Then
		
		PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "ServicesPartnerProducts", NStr("vi = 'Nhà cung cấp';
																											|ru = 'Поставщик';
																											|en = 'Vendor'; fa = 'تأمین‌کننده';
																											|it = 'Поставщик';
																											|pl = 'Dostawca';
																											|tr = 'Tedarikçi'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesPartnerProductsOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If PreviousRowDetails.Products <> CurrentRow.Products Then
		StructureOfActions = New Structure;
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
    	Or ValueIsFilled(CurrentRow.Purpose) Then  
	    CurrentRow.ToExpenseAs = False;
	    CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");      
  	ElsIf CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
    	CurrentRow.ToExpenseAs = True;
	EndIf;
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Services");
	
EndProcedure

&AtClient
Procedure ServicesProductsOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Services"));
		
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
		Or ValueIsFilled(CurrentRow.Purpose) Then
			
		CurrentRow.ToExpenseAs = False;
		CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
			
	ElsIf CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		CurrentRow.ToExpenseAs = True;
	EndIf;
	
	FillPropertyValues(PreviousRowDetails, CurrentRow);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisObject, CurrentRow, "Object.Services");
	
EndProcedure

&AtClient
Procedure ServicesProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Filter = New Structure("Filter", New Structure("ItemsType", ProductsClientServer.SelectionByServiceWork(False)));
	
	OpenForm("Catalog.Products.Form.ChoiceForm", Filter, Item);
	
EndProcedure

&AtClient
Procedure ServicesProductsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	DataGetParameters.Filter.Insert("ItemsType",ProductsClientServer.SelectionByServiceWork(False));
EndProcedure


&AtClient
Procedure ServicesOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Services.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Services");
	
EndProcedure


&AtClient
Procedure ServicesCountOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure


&AtClient
Procedure ServicesAppointmentOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	CurrentData.ToExpenseAs = False;
	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

// The constructor function of additional parameters processing is complete
// Returns:
// 	Structure - advanced setting:
// * CurrentRow - FormDataCollectionItem - 
// * Item - FormGroup, FormTable, FormField, FormButton - Form element
&AtClient
Function AdditionalCompletionProcessingParameters() 
	
	Result = New Structure;
	Result.Insert("CurrentRow");
	Result.Insert("Item");
	Return Result;
	
EndFunction

&AtClient
Procedure ServicesCharacteristicOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Services"));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesVATRateOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	SpecifiedVATRate = CurrentRow.VATRate;

EndProcedure

&AtClient
Procedure ServicesVATAmountOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesSumOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", "Count");
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesOnActivateCell(Item)
	
	If Item.CurrentItem = Undefined Then
		Return;
	ElsIf Item.CurrentItem.Name = Items.ServicesPartnerProducts.Name Then
		
		CurrentData = Items.Services.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.ServicesPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.ServicesPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Services.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);
	
	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);
	
EndProcedure

&AtClient
Procedure ServicesWriteOffForExpensesOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	If CurrentRow = Undefined Then 
		
		Return;
		
	EndIf;
	
	If Not CurrentRow.ToExpenseAs Then
		
		StructureOfActions = New Structure;
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ServicesExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsServicesOnChange(Item)
	
	CurrentRow = Items.Services.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsServicesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsServicesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseAnalyticsServicesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
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
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)

	TabularSectionName           = "Services";
	TabularSectionPresentation = NStr("vi = 'Dịch vụ';
										|ru = 'Услуги';
										|en = 'Services'; fa = 'خدمات';
										|it = 'Услуги';
										|pl = 'Services';
										|tr = 'Hizmetler'");
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, TabularSectionName, TabularSectionPresentation) Then
		
		PricesCalculated = FillThePricesByTermsOfSalesServer();
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpServicesAndJobs(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ReceiptOfServicesToBusinessUnit.DocumentForm.Command.PickUpServicesAndJobs");
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Currency) Then
		
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	FilterByProductType = New FixedArray(ProductsClientServer.SelectionByServiceWork(False));
	
	FormParameters = New Structure;
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Partner",                 Object.Partner);
	FormParameters.Insert("Terms",              Object.Terms);
	
	FormParameters.Insert("Currency",              Object.Currency);
	FormParameters.Insert("PriceIncludesVAT",     Object.PriceIncludesVAT);
	
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("HideTheViewPriceColumn", False);
	FormParameters.Insert("HideTheItemPricesCommand", False);
	FormParameters.Insert("SelectionModeWithoutAmountParameters", False);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
	
	FormParameters.Insert("HideManualDiscounts", True);
	
	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure FillInThePricesForReceipts(Command)
	
	If Not ValueIsFilled(Object.Partner) Then
		Raise NStr("vi = 'Để điền đơn giá theo những lần tiếp nhận gần nhất, cần chỉ ra nhà cung cấp';
					|ru = 'Для заполнения цен по последним поступлениям необходимо указать поставщика';
					|en = 'To fill in the prices for the latest receipts, specify the vendor'; fa = 'To fill in the prices for the latest receipts, specify the vendor';
					|it = 'Per ricompilare i prezzi in base agli ultimi arrivi, è necessario specificare il fornitore';
					|pl = 'Aby wypełnić ceny za ostatnie wpływy, należy określić dostawcę';
					|tr = 'Son tedariklerin fiyatlarını doldurmak için tedarikçi belirtilmelidir'");
	EndIf;
	
	PricesAreFilledOut = False;
	FillInPricesForLatestReceipts(PricesAreFilledOut);
	
	If PricesAreFilledOut Then
		ShowUserNotification(
			NStr("vi = 'Đã điền đơn giá';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			NStr("vi = 'Trong các dòng của chứng từ có điền đơn giá';
				|ru = 'В строках документа заполнены цены';
				|en = 'Prices are populated in the document lines'; fa = 'Prices are populated in the document lines';
				|it = 'Nelle righe del documento sono compilati i prezzi';
				|pl = 'W wierszach dokumentu wypełniono ceny';
				|tr = 'Belgedeki satırlar fiyatlarla doldurulmuştur'"),
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			NStr("vi = 'Chưa điền đơn giá vào dòng nào';
				|ru = 'Ни в одной строке цена не заполнена';
				|en = 'No lines have prices filled in'; fa = 'No lines have prices filled in';
				|it = 'Il prezzo non è compilato in alcuna riga';
				|pl = 'W żadnym wierszu nie wypełniono ceny';
				|tr = 'Hiçbir satırda fiyat doldurulmamıştır'"),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations   

	
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Services.CurrentData, NStr("vi = 'Nhà cung cấp';
																													|ru = 'Поставщик';
																													|en = 'Vendor'; fa = 'تأمین‌کننده';
																													|it = 'Поставщик';
																													|pl = 'Vendor';
																													|tr = 'Tedarikçi'"),"Services");
	
EndProcedure

&AtClient
Procedure SplitTheFactString(Command)
	
	FormTable  = Items.Services;
	TableData = Object.Services;
	
	Notification = New CallbackDescription("SplitTheFactStringCompletion", ThisObject);
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng dịch vụ trong dòng mới';
											|ru = 'Введите количество услуг в новой строке';
											|en = 'Enter the number of services in a new line'; fa = 'Enter the number of services in a new line';
											|it = 'Введите количество услуг в новой строке';
											|pl = 'Enter the number of services in a new line';
											|tr = 'Hizmet miktarını yeni bir satıra gir'");
	StringSplittingParameters.FieldNameQuantity = "Count";
	StringSplittingParameters.AllowZeroCount = True;
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItem(Command)
	
	If Not TMCommonUseClient.CheckForRowsInList(Object.Services, "Services") Then
		Return;
	EndIf;
	
	GoodsAddressInStorage = PlaceGoodsInTemporaryStorageServer("Services");
	PurchasesClient.OpenSupplierProductListForm(
		New CallbackDescription("FillInTheItemByThePartnerSItemCompletion", ThisObject),
		GoodsAddressInStorage,
		ThisObject,
		ProductsClientServer.SelectionByServiceWork(False));
	
EndProcedure

&AtClient
Procedure FillInTheItemByThePartnerSItemCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		FillInItemsFromTemporaryStorageServer(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Services.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Services.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Services) Then
		CopyLinesOnServer("Services");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Services.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Object.Organization;
	ImportParameters.FillInThePartnerSNomenclature = Object.Partner;
	ImportParameters.ImportPrices  = True;
	ImportParameters.ImportAmounts = True;
	ImportParameters.PriceIncludesVAT    = Object.PriceIncludesVAT;
	ImportParameters.VATTaxation = Object.VATTaxation;
	ImportParameters.Title = NStr("vi = 'Kết nhập dịch vụ và công việc từ tệp ngoài';
									|ru = 'Загрузка услуг и работ из внешних файлов';
									|en = 'Import services and works from external files'; fa = 'Import services and works from external files';
									|it = 'Загрузка услуг и работ из внешних файлов';
									|pl = 'Import services and works from external files';
									|tr = 'Hizmet ve işleri harici dosyalardan yükleme'");
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	ImportParameters.FilterParameters.Insert("ItemsType", ArrayOfProductTypes);
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, "Services");
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command)
	
	FillInPricesBySupplierPriceType(True);
	
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
Procedure FirstChoiceServer(ValueSelected)
	
	PropertiesToExclude = "";
	Terms = Object.Terms;
	
	If TypeOf(ValueSelected.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
		PropertiesToExclude = "Currency";
	EndIf;
	
	FillPropertyValues(Object, ValueSelected, , PropertiesToExclude);
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	WhenBusinessTransactionChangesServer(False);
	WhenChangingAgreementServer(False);
	ShowOrderPresentation();
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		PurchasesServer.SetContractAvailability(Object,
													Items.Contract.Enabled,
													Items.Contract.Visible,
													Object.Contract);
	EndIf;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(False);
	EconomicOperationOfAcceptance = PairsOfSeparatePurchaseOperations.Get(Object.BusinessOperation);
	
	If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.VendorInvoice") Then
		FillInUsingInvoice = True;
	Else
		FillInUsingInvoice = False;
	EndIf;

	FillingData = New Structure();
	FillingData.Insert("DocumentBasis", Object.ReferenceOrder);
	FillingData.Insert("PropertiesToExclude", PropertiesToExclude);
	FillingData.Insert("FillInUsingInvoice", FillInUsingInvoice);
	
	Object.Services.Clear();
	
	Value = FormAttributeToValue("Object");
	Value.Fill(FillingData);
	ValueToFormAttribute(Value, "Object");
	
	WhenChangingAgreementAtServer(Terms <> Object.Terms);
	
	DocumentCurrency = Object.Currency;
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	CalculateTotals_(ThisObject);
	
	EstablishAvailabilityOfTSServices();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Counterparty) Then
		
		FillInDefaultContract();
		
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	ClearOrder();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
        Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
		
		ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.Contract);
		IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
	EndIf;
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	ClearOrder();
	
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
        Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionCompletion(UserAnswer, AdditionalParameters) Export
	
	RecalculatePrices_2 = ValueIsFilled(Object.Terms)
						And Object.Services.Count() > 0
						And UserAnswer;
	
	WhenChangingAgreementAtServer(RecalculatePrices_2);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoice(ValueSelected, Var_Parameters) Export
	
	If ValueSelected <> Undefined Then
		Modified = True;
		
		If Object.Services.Count() > 0 Then
			QueryText = NStr("vi = 'Sẽ điền lại các dòng trong danh sách Dịch vụ theo lệnh được chọn. Tiếp tục?';
							|ru = 'Строки в списке Услуги будут перезаполнены по выбранному распоряжению. Продолжить?';
							|en = 'Lines in the Services list will be refilled according to the selected reference. Continue?'; fa = 'Lines in the Services list will be refilled according to the selected reference. Continue?';
							|it = 'Строки в списке Услуги будут перезаполнены по выбранному распоряжению. Продолжить?';
							|pl = 'Lines in the Services list will be refilled according to the selected reference. Continue?';
							|tr = 'Hizmetler listesindeki satırlar seçilen talimatına göre yeniden doldurulacaktır. Devam edilsin mi?'");
			ShowQueryBox(New CallbackDescription("CustomerSChoiceCompletion",
				ThisObject,
				New Structure("ValueSelected", ValueSelected)),
				QueryText,
				QuestionDialogMode.YesNo);
		Else
			FirstChoiceClientCallServer(ValueSelected);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerSChoiceCompletion(QuestionResult, AdditionalParameters) Export
	
	ValueSelected = AdditionalParameters.ValueSelected;
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	FirstChoiceClientCallServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure FirstChoiceClientCallServer(ValueSelected)
	
	FirstChoiceServer(ValueSelected);
	
	If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		CallbackDescription = New CallbackDescription("AgreementWhenChangingQuestionCompletion", ThisObject);
		
		QuestionUserBeforeFillingInAgreement(CallbackDescription);
	EndIf;
	
EndProcedure

// Parameters:
// 	UserAnswer - Boolean - 
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure PartnerWhenChangingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If ValueIsFilled(Object.Terms) Then
		If UserAnswer Then
			PricesCalculated = FillThePricesByTermsOfSalesServer(True);
			PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
		EndIf;
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesPartnerProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	// only view totals if Betcands = BezNDS or NDS0%
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisForm, "ServicesVATRate", "ServicesVATAmount", "ServicesAmountIncludingVAT");
	
	//
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "ServicesAmountIncludingVAT");
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, "ServicesCharacteristic", "Object.Services.ItemVariantsAreUsed");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance, "Warehouse", "Object.Warehouse", "WarehouseIsRequired");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesPurpose.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.EmptyRef();
	
	Text = NStr("vi = '<dành cho công việc>';
				|ru = '<для работ>';
				|en = '<for works>'; fa = '<for works>';
				|it = '<per i lavori>';
				|pl = '<dla robót>';
				|tr = '<iş için>'");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", Text);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	//
	
	SetConditionalAppearanceForArticlesAndAnalytics();
	
	// Removing the mark of an unfilled division if the Work on agency procurement is not written off as expenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesDepartment.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Services.Department");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		FilterGroup3 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
			ValueList = New ValueList;
			ValueList.Add(Enums.ItemsTypes.OwnGoods);
			ValueList.Add(Enums.ItemsTypes.ReusablePackage);
			ItemFilter.RightValue = ValueList;
			
			ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Services.ToExpenseAs");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = False;

		FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
		
		ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
		
		ItemFilter.LeftValue = New DataCompositionField("Object.Services.AssignmentType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// setting the mark of an unfilled division, if the Product
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesDepartment.Name);

	FilterGroup0 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup0.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
		FilterGroup1 = FilterGroup0.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
			ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Services.Department");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
			
			FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
			FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
			
				ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
				
				ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField("Object.Services.AssignmentType");
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Enums.AssignmentTypes.DeliveryForPrincipal;
		
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferenceOrderPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ResultIssueColor);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceForArticlesAndAnalytics()
	
	InvoicingOperations = New ValueList;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesToExpenseAs.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = InvoicingOperations;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionOfExecutionOfContractOfPurchases");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Work_5");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesExpenseItem.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesDimensionOfExpenses.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = InvoicingOperations;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OptionOfExecutionOfContractOfPurchases");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Work_5");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.AccountingForTheRNPTIsMaintained");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với công việc không được truy xuất>';
													|ru = '<для непрослеживаемых работ>';
													|en = '<for untraceable works>'; fa = '<for untraceable works>';
													|it = '<для непрослеживаемых работ>';
													|pl = '<for untraceable works>';
													|tr = '<izlenemeyen işler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// Only view if the job is completed and the appointment is filled
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesToExpenseAs.Name);

	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
		SelectionGroupAnd1 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd1.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.OperationService;
			
		SelectionGroupAnd2 = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
			
			ItemFilter = SelectionGroupAnd2.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField("Object.Services.Purpose");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// explanatory inscription, if the job is completed and the assignment is completed

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesExpenseItem.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesDimensionOfExpenses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Work_5");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Services.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<dành cho dịch vụ và công việc không có mục đích>';
													|ru = '<для услуг и работ без назначения>';
													|en = '<for services and works without assignment>'; fa = '<for services and works without assignment>';
													|it = '<для услуг и работ без назначения>';
													|pl = '<for services and works without assignment>';
													|tr = '<atanmamış hizmetler ve işler için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure	


#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPartnerServer()
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions(False);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	DocumentCurrency = Object.Currency;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	WhenBusinessTransactionChangesServer(False);
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Services, Object.Partner);
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	PurchasesServer.SetContractAvailability(
		Object,
		Items.Contract.Enabled,
		Items.Contract.Visible,
		Object.Contract);
	
	ClearOrder();
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
        Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
EndProcedure

&AtServer
Procedure PartnerClearingServer()
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
EndProcedure

&AtServer
Procedure ClearOrder()
	
	If Not ValueIsFilled(Object.ReferenceOrder) Then
		Return;
	EndIf;
	
	AttributesNames = "Partner, Counterparty, BusinessOperation, Organization";
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.TermsOfPurchaseFromVendors")
		And TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
		
		AttributesNames = AttributesNames + ", Terms, Contract";
	
	EndIf;
	
	If TypeOf(Object.ReferenceOrder) <> Type("CatalogRef.CounterpartyContracts") Then
		AttributesNames = AttributesNames;
	EndIf;
	
	DetailsOfOrder = Common.ObjectAttributesValues(Object.ReferenceOrder, AttributesNames);
	
	If Object.Partner <> DetailsOfOrder.Partner
			And ValueIsFilled(Object.Partner)
		
		Or Object.Counterparty <> DetailsOfOrder.Counterparty
			And ValueIsFilled(DetailsOfOrder.Counterparty)
			And ValueIsFilled(Object.Counterparty)
		
		Or Object.Organization <> DetailsOfOrder.Organization
			And ValueIsFilled(DetailsOfOrder.Organization)
			And ValueIsFilled(Object.Organization) Then
		
		Object.ReferenceOrder = Undefined;
		
	EndIf;
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		
		If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			BasicDisposalOperation = PurchasesServer.MainEconomicOperationOfSeparatePurchase(
												DetailsOfOrder.BusinessOperation);
			
			If Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery
					And BasicDisposalOperation <> Enums.BusinessTransactions.PurchaseFromSupplier  Then
				
				Object.ReferenceOrder = Undefined;
				
			EndIf;
			
			If Object.Terms <> Object.ReferenceOrder Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
		ElsIf TypeOf(Object.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
			
			PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
			
			If PairsOfSeparatePurchaseOperations.Get(Object.BusinessOperation) <> DetailsOfOrder.BusinessOperation 
				And DetailsOfOrder.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEU 
				And DetailsOfOrder.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromSupplier 
				And DetailsOfOrder.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit 
				And DetailsOfOrder.BusinessOperation <> Enums.BusinessTransactions.PurchaseByImport 
				And DetailsOfOrder.BusinessOperation <> Enums.BusinessTransactions.ImportGoodsInTransit
				And DetailsOfOrder.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit 
			Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
			If Object.Contract <> Object.ReferenceOrder Then
				Object.ReferenceOrder = Undefined;
			EndIf;
			
		Else
			
			If Object.Contract <> DetailsOfOrder.Contract
				And ValueIsFilled(Object.Contract)
				Or Object.Terms <> DetailsOfOrder.Terms
				And ValueIsFilled(DetailsOfOrder.Terms) Then
				
				Object.ReferenceOrder = Undefined;
				
			EndIf;
			
		EndIf;
		
	EndIf;     
	
	ShowOrderPresentation();
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(RecalculatePrices_2 = True)
	
	PriceIncludesVAT					= Object.PriceIncludesVAT;
	DirectionsOfActivity	= Object.LineOfBusiness;
	
	If ValueIsFilled(Object.Terms) Then
		
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Object.Terms, True, True);
		
		DocumentPurchases = FormAttributeToValue("Object");
		DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
		
		ValueToFormAttribute(DocumentPurchases, "Object");
		
		DocumentCurrency = Object.Currency;
		
		If RecalculatePrices_2 Then
			
			StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
			
			FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
			FillParameters.Insert("PopulationFields",		"Price, VATRate");
			FillParameters.Insert("Date",				Object.Date);
			FillParameters.Insert("Currency",				Object.Currency);
			FillParameters.Insert("Terms",			Object.Terms);
			FillParameters.Insert("VATTaxation",	Object.VATTaxation);
			FillParameters.Insert("Organization", Object.Organization);
			
			ActionsWithStrings = New Structure;
			ActionsWithStrings.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
			ActionsWithStrings.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
			
			PartnerPricesFillingServer.FillInPrices(Object.Services, Undefined, FillParameters, ActionsWithStrings);
			
		ElsIf PriceIncludesVAT <> Object.PriceIncludesVAT Then
			
			StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisObject);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			
			BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, Undefined);
			
		EndIf;
		
		BusinessTransactionBeforeTheChange = Object.BusinessOperation;
		WhenBusinessTransactionChangesServer(False);
		
		StructureOfNamesOfTableParts = New Structure("Services");
		FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
		
	EndIf;
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	ClearOrder();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
        Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	CalculateTotals_(ThisObject);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer(ClearingOrder)
	
	DirectionsOfActivity = Object.LineOfBusiness;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, 
			Object.Terms, Object.Contract);
		EndIf;
		
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
	FillInVATTaxationPurchases();
	
	If ClearingOrder Then
		ClearOrder();
	EndIf;
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.ReferenceOrder);
	
	OptionOfExecutionOfContractOfPurchases = PurchasesServer.GetVariantOfProcurementContract(Object.Contract);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.Contract);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure WhenBusinessTransactionChangesServer(ChallengeByCommand = True)
	
	If Object.BusinessOperation <> BusinessTransactionBeforeTheChange Then
		Object.Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	FillInBusinessPartOfAgreement();
	
	If ChallengeByCommand Then
		
		If ValueIsFilled(Object.Terms)
			And ValueIsFilled(Object.BusinessOperation) Then
			
			AgreementOperation			= Common.ObjectAttributeValue(Object.Terms,
											"BusinessOperation");
			BasicDocumentOperation_	= PurchasesServer.MainEconomicOperationOfSeparatePurchase(
											Object.BusinessOperation);
			
			Object.Terms = ?(AgreementOperation = BasicDocumentOperation_,
									Object.Terms,
									Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
			
		EndIf;
		
		FillInDefaultContract();
		ClearOrder();
		
	EndIf;
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	If Contract <> Object.Contract Then
		Contract = Object.Contract;
		Object.ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Object.Contract);
	EndIf;
	
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer(True);
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInVATTaxationPurchases();
	UpdateTypeOfVATActivity();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	
EndProcedure

&AtClient
Procedure RecalculateAmountsWhenChangingCurrency(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		RecalculateAmountsWhenChangingCurrencyServer(CachedValues);
	EndIf;
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure RecalculateAmountsWhenChangingCurrencyServer(CachedValues)
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(DocumentCurrency, DocumentDate, BaseCurrency);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency,  DocumentDate, BaseCurrency);
	
	For Each CurRow In Object.Services Do
		CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
			CurRow.Price,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates);
	EndDo;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions);
	
EndProcedure

#EndRegion

#Region PriceManagementSystem

&AtServer
Function FillThePricesByTermsOfSalesServer(OnAllLines = False)
	
	If OnAllLines Then
		RowsArray = Undefined;
	Else
		RowsArray = New Array;
		
		For Each String In Items.Services.SelectedRows Do
			RowsArray.Add(Object.Services.FindByID(String));
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",     "Price");
	FillParameters.Insert("Date",               Object.Date);
	FillParameters.Insert("Currency",             Object.Currency);
	FillParameters.Insert("Terms",         Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("Organization", Object.Organization);
	
	ActionsWithStrings = New Structure;
	
	ActionsWithStrings.Insert("RecalculateAmount", "Count");
	ActionsWithStrings.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Services, RowsArray, FillParameters, ActionsWithStrings);
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure FillInPricesBySupplierPriceType(FillSelectedLines = False)
	
	TabularSectionName           = "Services";
	TabularSectionPresentation = NStr("vi = 'Dịch vụ';
										|ru = 'Услуги';
										|en = 'Services'; fa = 'خدمات';
										|it = 'Услуги';
										|pl = 'Services';
										|tr = 'Hizmetler'");
	
	FillInPrices = PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, TabularSectionName,
		TabularSectionPresentation);
	
	If FillInPrices Then
		
		If Not ValueIsFilled(Object.VendorPriceKind) Then
			WarningText = NStr("vi = 'Chứng từ không chỉ ra dạng giá của nhà cung cấp. Không thể điền đơn giá';
								|ru = 'В документе не указан вид цены поставщика. Цены не могут быть заполнены';
								|en = 'Vendor price type is not specified in the document. Prices cannot be filled in'; fa = 'Vendor price type is not specified in the document. Prices cannot be filled in';
								|it = 'Il documento non indica il tipo di prezzo del fornitore. I prezzi non possono essere compilati';
								|pl = 'W dokumencie nie podano rodzaj ceny dostawcy. Ceny nie mogą zostać wypełnione';
								|tr = 'Belgede tedarikçi fiyat türü belirtilmemiştir. Fiyatlar doldurulamaz'");
			
			ShowMessageBox(, WarningText);
		Else
			PricesCalculated = FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(FillSelectedLines);
			
			PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Object.VendorPriceKind);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPriceServer(FillSelectedLines)
	
	RowsArray = Undefined;
	
	If FillSelectedLines Then
		RowsArray = New Array;
		
		For Each String In Items.Services.SelectedRows Do
			TableRow = Object.Services.FindByID(String);
			RowsArray.Add(TableRow);
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",    "Price");
	FillParameters.Insert("Date",              Object.Date);
	FillParameters.Insert("Currency",            Object.Currency);
	FillParameters.Insert("VendorPriceKind", Object.VendorPriceKind);
	FillParameters.Insert("Organization", Object.Organization);
	
	ActionsWithStrings = New Structure;
	ActionsWithStrings.Insert("RecalculateAmount",  "Count");
	ActionsWithStrings.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(Object.Services, RowsArray, FillParameters, ActionsWithStrings);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPricesForLatestReceipts(PricesAreFilledOut)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SourceTable.LineNumber    AS LineNumber,
	|	SourceTable.Products   AS Products,
	|	SourceTable.Characteristic AS Characteristic
	|	
	|INTO GoodsTable
	|FROM
	|	&SourceTable AS SourceTable
	|	
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorInvoice.Ref.PointInTime AS PointInTime,
	|	VendorInvoice.Products         AS Products,
	|	VendorInvoice.Characteristic       AS Characteristic,
	|	VendorInvoice.VendorPriceKind    AS VendorPriceKind,
	|	VendorInvoice.Price                 AS Price,
	|	VendorInvoice.Ref.Currency        AS Currency
	|	
	|INTO RevenuePrices
	|FROM
	|	Document.VendorInvoice.Goods AS VendorInvoice
	|	
	|	INNER JOIN
	|		GoodsTable
	|	ON
	|		VendorInvoice.Products = GoodsTable.Products
	|		AND VendorInvoice.Characteristic = GoodsTable.Characteristic
	|WHERE
	|	VendorInvoice.Ref.Posted
	|	AND VendorInvoice.Ref.Partner = &Partner
	|	AND VendorInvoice.Ref.Date   <= &Date
	|	
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RevenuePrices.Products         AS Products,
	|	RevenuePrices.Characteristic       AS Characteristic,
	|	RevenuePrices.Price                 AS Price,
	|	RevenuePrices.VendorPriceKind    AS VendorPriceKind,
	|	RevenuePrices.Currency               AS Currency
	|	
	|INTO PricesOfRecentReceipts
	|FROM
	|	RevenuePrices AS RevenuePrices 
	|	
	|	LEFT JOIN 
	|		RevenuePrices AS Filter
	|	ON
	|		RevenuePrices.Products = Filter.Products
	|		AND RevenuePrices.Characteristic = Filter.Characteristic
	|		AND RevenuePrices.PointInTime < Filter.PointInTime
	|WHERE
	|	Filter.PointInTime IS NULL
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber    AS LineNumber,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	PricesOfRecentReceipts.VendorPriceKind AS VendorPriceKind,
	|	PricesOfRecentReceipts.Price
	|	* CASE
	|		WHEN &Currency <> PricesOfRecentReceipts.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS Price
	|FROM
	|	GoodsTable AS GoodsTable
	|	
	|	LEFT JOIN 
	|		PricesOfRecentReceipts AS PricesOfRecentReceipts
	|		
	|	ON 
	|		GoodsTable.Products = PricesOfRecentReceipts.Products
	|		AND GoodsTable.Characteristic = PricesOfRecentReceipts.Characteristic
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON 
	|		PricesOfRecentReceipts.Currency = CurrencyRatesPrices.Currency
	|	
	|	LEFT JOIN 
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON
	|		TRUE";
	
	Query.SetParameter("SourceTable", Object.Services.Unload(,"LineNumber, Products, Characteristic"));
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("Partner", Object.Partner);
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TSRow = Object.Services[Selection.LineNumber - 1];
		TSRow.Price = Selection.Price;
		RowsToProcess.Add(TSRow);
		PricesAreFilledOut = True;
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services,
		CachedValues);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
										|ru = 'Поле ""Валюта"" не заполнено';
										|en = '""Currency"" is required'; fa = '""Currency"" is required';
										|it = 'Il campo ""Valuta"" non è compilato';
										|pl = 'Pole ""Waluta"" nie jest wypełnione';
										|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	
	If Item.Name = Items.Date.Name Then
		DateOnChange(Item);
	ElsIf Item.Name = Items.Partner.Name Then
		PartnerOnChange(Item);
	ElsIf Item.Name = Items.Terms.Name Then
		TermsOnChange(Item);
	ElsIf Item.Name = Items.Contract.Name Then
		ContractOnChange(Item);
	ElsIf Item.Name = Items.PriceIncludesVAT.Name Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = Items.VATTaxation.Name Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = Items.Organization.Name Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = Items.Counterparty.Name Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = Items.ServicesPartnerProducts.Name Then
		ServicesPartnerProductsOnChange(Item);
	ElsIf Item.Name = Items.ServicesPrice.Name Then
		ServicesPriceOnChange(Item);
	ElsIf Item.Name = Items.ServicesSum.Name Then
		ServicesSumOnChange(Item);
	ElsIf Item.Name = Items.ServicesVATRate.Name Then
		ServicesVATRateOnChange(Item);
	ElsIf Item.Name = Items.ServicesVATAmount.Name Then
		ServicesVATAmountOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	If Command.Name = Commands.FillThePricesByTermsOfSales.Name Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = Commands.FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice.Name Then
		FillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice(Command);
	ElsIf Command.Name = Commands.SplitTheFactString.Name Then
		SplitTheFactString(Command);
	ElsIf Command.Name = Commands.PickUpServicesAndJobs.Name Then
		PickUpServicesAndJobs(Command);
	ElsIf Command.Name = Commands.FillInTheItemByThePartnerSItem.Name Then
		FillInTheItemByThePartnerSItem(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Not Item.Name = Items.Services.Name Then
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
EndProcedure

#EndRegion

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	TMCommonUseClient.SaveAttributeValue(ThisObject, Item);
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(StructureOfActionsControlOfNonAgreedChanges.AttributesValues[Item.Name], Item.CurrentData);
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisObject) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisObject);
	
EndProcedure

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	
	Columns = "Products, Characteristic, Price, Count, Department";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersForFillingInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfActions.Insert("FillInVATRate", ParametersForFillingInVATRate);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Services.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Services");
	EndDo;
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	FillInAttributeForDebitingExpensesForServices();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("ServicesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("ServicesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtServer
Procedure FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts)
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ParametersForFillingInBankingDetails);
	
	If StructureOfNamesOfTableParts.Property("Services") Then
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.Services, ParametersForFillingInBankingDetails);
	EndIf;	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseTermsOfPurchases		= GetFunctionalOption("UseTermsOfPurchases");
	UseLinesOfBusiness		= GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	UseDebitNotes	= GetFunctionalOption("UseDebitNotes");
	UsePartnersAsCounterparties 	= GetFunctionalOption("UsePartnersAsCounterparties");
	
	DocumentCurrency = Object.Currency;
	Contract = Object.Contract;
	
	ShowOrderPresentation();
	SetAvailabilityOfItemsByStatusServer();
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	
	DocumentDateBeforeChange = Object.Date;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	Items.CounterpartyGroup.Visible = Not UsePartnersAsCounterparties;
	
	If TypeOf(Object.ReferenceOrder) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		AgreementOperation = Common.ObjectAttributeValue(Object.ReferenceOrder, "BusinessOperation");
		SeparatePurchaseOperationsByAgreement = PurchasesServer.BusinessOperationsOnMain(AgreementOperation);
		
		OperationsForDocument = PurchasesServer.EconomicOperationsOfSeparatePurchase(FullDocumentName(), Object.ReferenceOrder);
		
		TotalOperations = OperationsForDocument.Count() - 1;
		For IndexOf = 0 To TotalOperations Do
			DocumentOperation_ = OperationsForDocument[TotalOperations - IndexOf];
			If SeparatePurchaseOperationsByAgreement.Find(DocumentOperation_) = Undefined Then
				OperationsForDocument.Delete(TotalOperations - IndexOf);
			EndIf;
		EndDo;
		
	EndIf;
	
	FillInBusinessPartOfAgreement();
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	FillParameters = Documents.ReceiptOfServicesToBusinessUnit.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	UpdateTypeOfVATActivity(False);
	
	CalculateTotals_(ThisObject);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
    EstablishAvailabilityOfTSServices();
	
EndProcedure

&AtServer
Procedure ShowOrderPresentation()
	
	RowsArray = New Array;
	
	If ValueIsFilled(Object.ReferenceOrder) Then
		ReferenceOrderPresentation = StringFunctions.FormattedString("<a href='Open_Order'>%1</a>  <a href='SelectReference'>Change</a>",String(Object.ReferenceOrder));
	Else
		ReferenceOrderPresentation = StringFunctions.FormattedString("‹%1›  <a href='SelectReference'>%2</a>",NStr("vi = 'chưa chọn';
																													|ru = 'не выбрано';
																													|en = 'not selected'; fa = 'not selected';
																													|it = 'не выбрано';
																													|pl = 'not selected';
																													|tr = 'seçilmedi'"),NStr("vi = 'Chọn';
																																				|ru = 'Выбрать';
																																				|en = 'Select'; fa = 'انتخاب';
																																				|it = 'Выбрать';
																																				|pl = 'Select';
																																				|tr = 'Seç'")); 
	EndIf;

EndProcedure

&AtServer
Function PlaceGoodsInTemporaryStorageServer(CollectionName)
	
	Return PurchasesServer.PlaceGoodsInTemporaryStorage(Object[CollectionName]);
	
EndFunction

&AtServer
Procedure FillInItemsFromTemporaryStorageServer(AddressInTempStorage)
	
	TableOfGoods = GetFromTempStorage(AddressInTempStorage); // DocumentTabularSection.ReceiptOfServicesToBusinessUnit.Services
	
	FillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	FillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", FillInVATRate);
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
	
	RowsToProcess = New Array;
	
	For Each CurRow In TableOfGoods Do
		
		ArrayOfCollectionRows = Object.Services.FindRows(New Structure("LineNumber", CurRow.LineNumber));
		If ArrayOfCollectionRows.Count() <> 1 Then
			Continue;
		Else
			CollectionRow = ArrayOfCollectionRows[0];
		EndIf;
		
		FillPropertyValues(CollectionRow, CurRow, "Products, Characteristic");
		RowsToProcess.Add(CollectionRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services);
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	FillInAttributeForDebitingExpensesForServices();
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	
	Object.Contract = PurchasesServer.GetDefaultContract(Object, ContractBusinessTransaction, AddlParameters);
	
	ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation, Object.Contract);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	FillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	FillInVATRate.SpecifiedVATRate = SpecifiedVATRate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", FillInVATRate);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Services.Add();
		FillPropertyValues(CurrentRow, RowOfProduct,
			"PartnerProducts, Products, Characteristic, Price, Count");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Services);
		
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Services");
	EndDo;
	
	StructureOfNamesOfTableParts = New Structure("Services");
	FillInServiceDetailsForProductRange(StructureOfNamesOfTableParts);
	FillInAttributeForDebitingExpensesForServices();
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage, TSName)
	
	ItemsFromStorage = GetFromTempStorage(GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	RowsToProcess = New Array();
	
	If TSName = "Services" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
	
	TSServiceObject = Object[TSName]; // DocumentTabularSection.ReceiptOfServicesToBusinessUnit.Services
	For Each ServiceLine_ In ItemsFromStorage Do
		NewRow = TSServiceObject.Add();
		FillPropertyValues(NewRow, ServiceLine_);
		If TSName = "Services" Then
			RowsToProcess.Add(NewRow);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TSServiceObject);
		
	For Each ServiceLine_ In ItemsFromStorage Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, NewRow, "Object.Services");
	EndDo;
		
	FillInAttributeForDebitingExpensesForServices();
	
EndProcedure

&AtClient
Procedure QuestionUserBeforeFillingInAgreement(CallbackDescription)
	
	If Object.Services.Count() = 0
		Or Not ValueIsFilled(Object.Terms) Then
		
		RunCallback(CallbackDescription, False);
		
		Return;
		
	EndIf;
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True,	NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Перезаполнить';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False,		NStr("vi = 'Không điền lại';
											|ru = 'Не перезаполнять';
											|en = 'Do not refill'; fa = 'Do not refill';
											|it = 'Non ricompilare';
											|pl = 'Nie wypełniaj ponownie';
											|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(CallbackDescription,
					NStr("vi = 'Điền lại giá theo thỏa thuận?';
						|ru = 'Перезаполнить цены по соглашению?';
						|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
						|it = 'Ricompilare i prezzi in base all''accordo?';
						|pl = 'Wypełnić ceny ponownie wg porozumienia?';
						|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'"),
					AnswersOptions);
	
EndProcedure

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInBusinessPartOfAgreement()
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
	ContractBusinessTransaction = PairsOfSeparatePurchaseOperations.Get(Object.BusinessOperation);
	
	ThisIsAnImport = (ContractBusinessTransaction = Enums.BusinessTransactions.ImportGoodsInTransit);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForRecalculatingNDSWTCHAmount(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForConvertingAmountOfNDSVToTS(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure FillInAttributeForDebitingExpensesForServices()
	
	// filling in the write-off attribute for expenses
	FilterStructure1 = New Structure("ItemsType", Enums.ItemsTypes.OperationService);
	FoundRows = Object.Services.FindRows(FilterStructure1);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	StructureOfActions = New Structure;
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department);
		
	For Each String In FoundRows Do
		String.ToExpenseAs = True;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		FoundRows,
		StructureOfActions,
		Object.Services);
		
	For Each CurrentRow In FoundRows Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Services");
	EndDo;
		
EndProcedure

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	RecalculatePrices_2 = False;
	
	If QuestionResult  Then
		RecalculatePrices_2 = True;
	EndIf;
	
	PricesCalculated = DateOnChangeServer(RecalculatePrices_2);
	DocumentDateBeforeChange = Object.Date;
	
	If RecalculatePrices_2 Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
EndProcedure

&AtClient
Procedure SplitTheFactStringCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Services.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfRecalculationOfAmount = ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmount", "Count");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If Not UserRightsCached.VarianceFromPurchaseConditions() Then
		
		ItemArray = New Array;
		
		// Header Controls
		ItemArray.Add("Partner");
		ItemArray.Add("Terms");
		ItemArray.Add("Contract");
		ItemArray.Add("PriceIncludesVAT");
		ItemArray.Add("VATTaxation");
		ItemArray.Add("VATActivityType");
		ItemArray.Add("Organization");
		ItemArray.Add("Counterparty");
		ItemArray.Add("BusinessOperation");
		ItemArray.Add("Manager");
		ItemArray.Add("SalesOpportunity");
		ItemArray.Add("Department");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", True);
		
	EndIf;
	
EndProcedure

&AtServer
Function FullDocumentName()
	
	Return "Document.ReceiptOfServicesToBusinessUnit";
	
EndFunction

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.ReceiptOfServicesToBusinessUnit.ParametersForFillingInVATTaxationPurchases(Object);
	
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation,
												FillParameters,
												VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
															Object.VATTaxation,
															FillParameters,
															VATAccountingCachedParameterValues);
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Services,
		CachedValues);
	
	CalculateTotals_(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateTypeOfVATActivity(FillInTypeOfActivity = True)
	
	FillParameters = Documents.ReceiptOfServicesToBusinessUnit.ParametersForFillingInVATActivityType(Object);
	
	If FillInTypeOfActivity Then
		VATAccountingERP.FillInTypeOfActivityVAT(Object.VATActivityType, FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(Items.VATActivityType,
														Object.VATActivityType,
														FillParameters,
														VATAccountingCachedParameterValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotals_(Form)
	
	If VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation) Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	ServicesPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServer
Procedure EstablishAvailabilityOfTSServices()
	
	ItemArray = New Array;
	ItemArray.Add("ServicesToSelectItem");
	ItemArray.Add("ServicesCopyRows");
	ItemArray.Add("ServicesInsertRows");
	ItemArray.Add("ServicesToSplitTheString");
	ItemArray.Add("ServicesFillInTheItemByThePartnerSItem");
	ItemArray.Add("ServicesImportFromExternalFile");
	ItemArray.Add("ServicesFillThePricesByTermsOfSales");
	ItemArray.Add("ServicesFillInThePricesOfTheSelectedLinesByTheTypeOfSupplierSPrice");
	ItemArray.Add("ServicesFillInThePricesForReceipts");
	ItemArray.Add("ServicesContextMenuSplitTheFactString");
	ItemArray.Add("ServicesContextMenuShowSupplierProducts");
	
	ServicesAvailability = ValueIsFilled(Object.ReferenceOrder);
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", ServicesAvailability);
	Items.Services.ChangeRowSet = ServicesAvailability;
	
EndProcedure

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
