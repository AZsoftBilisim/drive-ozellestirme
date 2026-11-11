#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var PreviousAttributesOfTSItemsLine;

&AtClient
Var PreviousDetailsOfTSLineDiscrepancies;



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
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	UsePartnersAsCounterparties      = GetFunctionalOption("UsePartnersAsCounterparties");
	UsePriceManagementSystem25             = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Goods);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Discrepancies);
	EndIf;
	CalculateFinalImplementationIndicators(ThisObject);
	SetAvailabilityOfClipboardCommands();
	SetTitleOfPrintDetails();
	GenerateHeaderAndSetVisibilityOfElementsBasedOnGiverSReport();
	SalesServer.SetBlankContractMark(Items, "Contract");
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);

	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	ThisIsAdjustmentOfReportToGiver = False;
	ThisIsAdjustmentOfReportToGiver =
		Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
	Items.GroupEDIState.Visible = Items.GroupEDIState.Visible And Not ThisIsAdjustmentOfReportToGiver;
	Items.EDOSubmenu.Visible = Items.EDOSubmenu.Visible And Not ThisIsAdjustmentOfReportToGiver;
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties")
		And Not ThisIsAdjustmentOfReportToGiver;
	


	

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	EstablishRelationshipOfSelectionParametersForUnitsOfMeasurement();
		
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents 

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);
	
	AddSBPPaymentStatusUpdateCommand();

	sh_ShamsiInit(); // sh_ShamsiInit
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
	CalculateFinalImplementationIndicators(ThisForm);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	CalculateFinalImplementationIndicators(ThisForm);
	
	DiscrepanciesAreUsed = 
		(Object.AdjustmentKind <> PredefinedValue("Enum.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated")
		And Object.AdjustmentKind <> PredefinedValue("Enum.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated"));
		
	If DiscrepanciesAreUsed And Not DiscrepanciesAreRelevant Then
		
		If Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.SaleOfOverdeliveredGoods")
			Or Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods") Then
			
			FillInTheDiscrepanciesServer();
			
		Else
			
			ButtonsList = New ValueList;
			ButtonsList.Add(DialogReturnCode.Yes,	NStr("vi = 'Điền lại';
															|ru = 'Перезаполнить';
															|en = 'Refill'; fa = 'پرکردن مجدد';
															|it = 'Ricompilare';
															|pl = 'Refill';
															|tr = 'Yeniden doldur'"));
			ButtonsList.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
			
			Cancel = True;
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("WriteParameters", WriteParameters);
			ShowQueryBox(
				New CallbackDescription("BeforeRecordingQuestionCompletion", ThisObject, AdditionalParameters),
				NStr("vi = 'Phần bảng ""Hàng hóa"" đã thay đổi. Điền lại chênh lệch?';
					|ru = 'Табличная часть ""Товары"" была изменена. Перезаполнить расхождения?';
					|en = 'The Goods table was changed. Refill the discrepancies?'; fa = 'The Goods table was changed. Refill the discrepancies?';
					|it = 'La parte tabulare ""Merci"" è stata modificata. Ricompilare le discrepanze?';
					|pl = 'Sekcja tabelaryczna ""Wiersze pozycji"" została zmieniona. Wypełnić odchylenie ponownie?';
					|tr = '""Ürünler"" tablo kısmı değiştirilmiştir. Tutarsızlıklar yeniden doldurulsun mu?'"),
				ButtonsList, , DialogReturnCode.Yes);
			Return;
			
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateServiceDetailsOfTableParts();
	EstablishCostPresentation();
	SetAvailabilityOfItemsByStatusServer();
	GenerateHeaderAndSetVisibilityOfElementsBasedOnGiverSReport();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalImplementationIndicators(ThisForm);
	
	UpdateTextDocumentsBasedOn();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	


	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False, ReferenceDocumentDateForCertificate);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "ChangedStatusDependentBankingDetails"
		And Parameter.UUID = UUID Then
		If Object.Approved Then
			Object.Approved = False;
		EndIf;
		AttachIdleHandler("Attachable_WhenChangingDetailsDependingOnStatus", 0.1, True);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns());
		If Parameter.Property("SalesOrder") Then
			KitParameters.Insert("SalesOrder", Parameter.SalesOrder);
		EndIf;
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("Partner", Object.Partner);
		OpeningParameters.Insert("Terms", Object.Terms);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
			OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
		Else
			OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		EndIf;
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
		
	EndIf;
	
	If EventName = "Write_InvoiceIssued"
		And (Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextDocumentsBasedOn();
	EndIf;
	
	If EventName = "SBPStatusHasBeenChanged" Then
		AddSBPPaymentStatusUpdateCommand();
	EndIf;
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	NotificationProcessingLocalization(EventName, Parameter, Source);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.SaleAdjustment.Form.SelectionOfGoodsFromOrderForm" Then
		ProcessingProductSelectionFromOrder(ValueSelected.GoodsAddressInStorage);
	ElsIf ChoiceSource.FormName = "Document.ReportToMaterialProvider2_5.Form.FormPickReleasedGoods" Then
		ProcessingProductSelectionFromOrder(ValueSelected.AddressInStorage);
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ClearMessages();
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		
		UpdateTextDocumentsBasedOn();
		
	ElsIf ChoiceSource.FormName = "Document.SaleAdjustment.Form.SalesDocumentsPickForm" Then
		
		AddImplementationDocumentToDebtAdjustmentTable(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.SaleAdjustment.Form.ChoiceFormOfCorrectedDocument" Then
		
		ProcessingSelectionOfDocumentBeingCorrected(ValueSelected);
	
	ElsIf TypeOf(ValueSelected) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(ValueSelected) = Type("DocumentRef.CustomerInvoiceServices")
		Or TypeOf(ValueSelected) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		Or TypeOf(ValueSelected) = Type("DocumentRef.ReportToMaterialProvider2_5")
		Then
		
		ProcessingDocumentSelectionViaServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "CommonForm.PrintingDetailsOfSales" Then
		
		If ValueSelected <> Undefined Then
			Modified = True;
			FillPropertyValues(Object, ValueSelected);
			UpdateTextDocumentsBasedOn();
		EndIf;
	
	ElsIf ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
	
		SalesClient.ProcessingUnitSelection(Object.Goods, Items.Goods.SelectedRows, ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject,
													SeriesSpecificationParameters[ValueSelected.TSName],
													ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("DocumentBasis", Object.DocumentBasis);
	Notify("Write_SaleAdjustment", WriteParameters, Object.Ref);
	
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PreviousDetailsOfTSLineDiscrepancies = New Structure;
	PreviousDetailsOfTSLineDiscrepancies.Insert("Warehouse");

	PreviousAttributesOfTSItemsLine = New Structure;
	PreviousAttributesOfTSItemsLine.Insert("Warehouse");
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	If Not ValueIsFilled(Object.Ref) Then
		FillInCostAccountingAttribute();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)

	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	

	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	

	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	

	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseOnChangeServer();
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		ShowValue(Undefined, Object.DocumentBasis);
		
	Else
		
		TypesList = New ValueList;
		BasisType = TypeOf(Object.DocumentBasis);
		If Not BasisType = Type("Undefined") Then
			TypesList.Add(BasisType);
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer") Then
			TypesList.Add(Type("DocumentRef.CustomerInvoice"));
			TypesList.Add(Type("DocumentRef.CustomerInvoiceServices"));
			TypesList.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
			TypesList.Add(Type("DocumentRef.CustomerInvoice"));
		Else
			TypesList.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
		EndIf;
		
		CallbackDescription = New CallbackDescription("BaseDocumentPresentationClickCompletion", ThisObject);
		ShowChooseFromList(CallbackDescription, TypesList, Items.BaseDocumentPresentation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClickCompletion(ValueSelected, Var_Parameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Posted", True);
	
	ListBusinessOperation = New ValueList;
	StructureFilter.Insert("BusinessOperation", ListBusinessOperation);
	ListBusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
		
	If ValueSelected.Value = Type("DocumentRef.CustomerInvoice") Then
		ChoiceFormName = "Document.CustomerInvoice.ChoiceForm";
		StructureFilter.Insert("Status", PredefinedValue("Enum.StatusesOfCustomerInvoices.Shipped"));
		ListBusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent"));
		ListBusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit"));
		
		ListBusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle"));
		ListBusinessOperation.Add(
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
		
	ElsIf ValueSelected.Value = Type("DocumentRef.CustomerInvoiceServices") Then
		ChoiceFormName = "Document.CustomerInvoiceServices.ChoiceForm";
		
	ElsIf ValueSelected.Value = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		ChoiceFormName = "Document.CustomerInvoiceServicesAndAssets.ChoiceForm";
	ElsIf ValueSelected.Value = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		ChoiceFormName = "Document.ReportToMaterialProvider2_5.ChoiceForm";
	EndIf;
	
	OpenForm(
		ChoiceFormName,
		New Structure("Filter", StructureFilter),
		ThisForm);
	
EndProcedure

&AtClient
Procedure SubmissionOfTheDocumentOfTheBasisOfTheAcceptanceCertificateClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DiscrepancyReportFollowingShipmentBaseDocument) Then
		ShowValue(,Object.DiscrepancyReportFollowingShipmentBaseDocument);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);	
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure OperationOnChange(Item)
	OperationWhenChangingOnServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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
Procedure AdditionalCostAnalysisStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AdditionalCostAnalysisAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);

EndProcedure

&AtClient
Procedure AdditionalCostAnalysisTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);	
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		If ChangedBankingDetails.Count() > 0 Then
			LabelCurrenciesClickCompletionServer(ClosingResult);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
	If Object.Currency <> CurrentCurrency
		Or Object.ARAPCurrency <> CurCurrencyOfSettlements Then
		CurrentCurrency = Object.Currency;
		CurCurrencyOfSettlements =  Object.ARAPCurrency;
		ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	EndIf;
	
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
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	If Object.BusinessOperation =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
		
		ShowMessageBox(, NStr("vi = 'Đối với chứng từ có giao dịch ""Chuyển giao quyền sở hữu"", không xem xét thao tác gửi/nhận theo hệ thống quản lý chứng từ điện tử.';
								|ru = 'Для документа с операцией ""Переход права собственности"" отправка/получение по ЭДО не предусмотрено.';
								|en = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.'; fa = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.';
								|it = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.';
								|pl = 'Documents with the ""Transfer of title to goods"" transaction do not support sending/receiving by EDI.';
								|tr = '""Mülkiyet hakkının devri"" işlemini içeren belgeler için EBY aracılığıyla sevkiyat/alım öngörülmemiştir.'"));
		Return;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RegistrationParameters = InvoiceRegistrationParameters();
	
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm,
																		FormattedStringURL,
																		StandardProcessing,
																		RegistrationParameters.Issued);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(ThisForm,
																		FormattedStringURL,
																		StandardProcessing,
																		RegistrationParameters.Received);
	
	FiscalOperationNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing);
	
	TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisForm,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure CustomerPartnerOnChange(Item)
	
	PartnerClientWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure CustomerCounterpartyOnChange(Item)
	
	ClientCounterpartyWhenChangingOnServer();
	
EndProcedure


&AtClient
Procedure UISStateContractStepStartChoice(Item, ChoiceData, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure UISStateContractStepClearing(Item, StandardProcessing)

	Object.UISStateContractStep = "";

EndProcedure

&AtClient
Procedure DecorationEISFilesClick(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure PresentationOfCorrectedDocumentClick(Item, StandardProcessing)
		
	StandardProcessing = False;
	
	If ValueIsFilled(Object.CorrectedDocument) Then
		ShowValue(, Object.CorrectedDocument);	
	Else
		PickUpDocumentToBeCorrected();		
	EndIf;

EndProcedure

&AtClient
Procedure SubjectToExciseOnChange(Item)
	ExcisableGoodsAccountingClientServer.ConfigureProductionDivisionField(ThisObject);
	Return; // Not used in TM
EndProcedure

&AtClient
Procedure FeaturesOfReflectionONChange(Item)
	FeaturesOfReflectionONChangeServer();
EndProcedure

&AtClient
Procedure TransferDocumentToNewOrderOfReflectionInAccountingClick(Item)
	TransferDocumentToNewOrderOfReflectionInAccountingServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Field = Items.GoodsSum Then
		
		If ValueIsFilled(CurrentRow.PriceKind) And Not Object.Approved Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn số tiền, hãy xóa dạng giá';
					|ru = 'Для редактирования суммы очистите вид цены';
					|en = 'To edit the amount, clear the price type'; fa = 'To edit the amount, clear the price type';
					|it = 'Для редактирования суммы очистите вид цены';
					|pl = 'To edit the amount, clear the price type';
					|tr = 'Tutarı düzenlemek için fiyat türünü temizle'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PriceKind"),);
		EndIf;
	
	ElsIf Field = Items.GoodsAmountIncludingVAT Then
		
		If ValueIsFilled(CurrentRow.PriceKind) And Not Object.Approved Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn số tiền gồm thuế GTGT, hãy xóa dạng giá';
					|ru = 'Для редактирования суммы с НДС очистите вид цены';
					|en = 'To edit the amount including VAT, clear the price type'; fa = 'To edit the amount including VAT, clear the price type';
					|it = 'Для редактирования суммы с НДС очистите вид цены';
					|pl = 'To edit the amount including VAT, clear the price type';
					|tr = 'KDV''li tutarın düzenlenmesi için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PriceKind"),);
		EndIf;

	ElsIf Field = Items.GoodsSalesOrder Then
		
		If ValueIsFilled(CurrentRow.SalesOrder) Then
			ShowValue(Undefined, CurrentRow.SalesOrder);
		EndIf;
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
		
	ElsIf Field = Items.GoodsPrice Then
		
		If ValueIsFilled(CurrentRow.PriceKind) And Not Object.Approved Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "PriceKind"),);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	CurrentRow = Items.Goods.CurrentData;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisObject, "Goods", CurrentRow, NewRow, Copy);
	
	If NewRow And Not Copy Then
		
		FillCustomerOrder(ThisObject, CurrentRow);
		
		If Not WarehouseGroup_ Then
			CurrentRow.Warehouse = Object.Warehouse;
		EndIf;
		
		CurrentRow.Department = Object.Department;
		
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Goods");	
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	DiscrepanciesAreRelevant = False;
	CalculateFinalImplementationIndicators(ThisForm);
	
	GoodsAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	TableRow = Items.Goods.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem <> Undefined
		And Item.CurrentItem = Items.GoodsPostingOption Then
		
		AddReturnToPath =
			UseShipmentWithDeferredTransferOfTitle2_5
			And Not SalesViaCommissionAgent
			And (Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
				Or Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
		
		ChoiceList = Items.GoodsPostingOption.ChoiceList;
		ChoiceList.Clear();
		
		If Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.SaleOfOverdeliveredGoods") Then
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			If TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock"));
			EndIf;
		Else
			ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			If TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
			EndIf;
			If AddReturnToPath Then
				ChoiceList.Add(
					PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit"));
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)

	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel, True);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "Goods", Cancel);
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateFinalImplementationIndicators(ThisObject);
	CurrentData = Items.Goods.CurrentData;
	If Not CancelEdit Then
		LineCache = ?(NewRow, Undefined, ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject));
		WarehousesClient.UpdateWarehouseTable(WarehouseTable, CurrentData, LineCache, WarehouseGroup_, False);
		TotalWarehouses_ = WarehouseTable.Count();
		WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);
		
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") And
			  (Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.SaleOfOverdeliveredGoods")
			   Or Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods")) Then
		
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
			
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			
			ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
		ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		
			If ValueIsFilled(CurrentData.SalesOrder)
				And Not CurrentData.RowCode = 0 Then
				
				CurrentData.Purpose   =
					GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentData.SalesOrder, "Purpose");
					
			ElsIf Not ValueIsFilled(CurrentData.Purpose)
				And ValueIsFilled(Object.DocumentBasis) Then
					
				CurrentData.Purpose   = GetContractAssignment(Object);
				
			EndIf;
		ElsIf ValueIsFilled(CurrentData.PostingOption)
			And Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods") Then
			
			ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
			
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.Goods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousAttributesOfTSItemsLine, Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5") Then
		CurrentRow.VATRate = VATRate;
	Else
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	EndIf;
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters",
												CurrentRow.Warehouse, SeriesSpecificationParameters.Goods));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
								New Structure("FormName, TabularSectionName", FormName, "Goods"));
	
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);

EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters",
												CurrentRow.Warehouse, SeriesSpecificationParameters.Goods));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	StructureOfActions.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisObject);

EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

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
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	If Not OtherAssetServiceAdjustment Then
		StructureOfActions.Insert("RecalculateNumberOfUnits");
	EndIf;
	
	If CurrentRow.Count > 0 And Not ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf CurrentRow.Count > 0 And ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	ElsIf (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("VATAmountCompl",                CurrentData.VATAmountCompl);
	CurrentRow.Insert("VATAmountMan",                 CurrentData.VATAmountMan);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("WithoutReusablePackages",           CurrentData.WithoutReusablePackages);
	CurrentRow.Insert("SumWithoutReusablePackages",      CurrentData.SumWithoutReusablePackages);
	CurrentRow.Insert("AmountIncludingVATWithoutReusablePackages",  CurrentData.AmountIncludingVATWithoutReusablePackages);
	CurrentRow.Insert("VATAmountWithoutReusablePackages",   CurrentData.VATAmountWithoutReusablePackages);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If CurrentData.NumberOfPackages = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	Else
		FillPropertyValues(CurrentData, CurrentRow);
	EndIf;
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCountOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("VATAmountCompl", CurrentData.VATAmountCompl);
	CurrentRow.Insert("VATAmountMan", CurrentData.VATAmountMan);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("WithoutReusablePackages",           CurrentData.WithoutReusablePackages);
	CurrentRow.Insert("SumWithoutReusablePackages",      CurrentData.SumWithoutReusablePackages);
	CurrentRow.Insert("AmountIncludingVATWithoutReusablePackages",  CurrentData.AmountIncludingVATWithoutReusablePackages);
	CurrentRow.Insert("VATAmountWithoutReusablePackages",   CurrentData.VATAmountWithoutReusablePackages);

	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	If CurrentData.Count = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	ElsIf CurrentData.NumberOfPackages = 0 Then
		FillPropertyValues(CurrentData, CurrentRow, , "NumberOfPackages");
	Else
		FillPropertyValues(CurrentData, CurrentRow);
	EndIf;
	CalculateFinalImplementationIndicators(ThisForm);

EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("VATAmountCompl", CurrentData.VATAmountCompl);
	CurrentRow.Insert("VATAmountMan", CurrentData.VATAmountMan);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("WithoutReusablePackages",           CurrentData.WithoutReusablePackages);
	CurrentRow.Insert("SumWithoutReusablePackages",      CurrentData.SumWithoutReusablePackages);
	CurrentRow.Insert("AmountIncludingVATWithoutReusablePackages",  CurrentData.AmountIncludingVATWithoutReusablePackages);
	CurrentRow.Insert("VATAmountWithoutReusablePackages",   CurrentData.VATAmountWithoutReusablePackages);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");

	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("VATAmountCompl", CurrentData.VATAmountCompl);
	CurrentRow.Insert("VATAmountMan", CurrentData.VATAmountMan);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("WithoutReusablePackages",           CurrentData.WithoutReusablePackages);
	CurrentRow.Insert("SumWithoutReusablePackages",      CurrentData.SumWithoutReusablePackages);
	CurrentRow.Insert("AmountIncludingVATWithoutReusablePackages",  CurrentData.AmountIncludingVATWithoutReusablePackages);
	CurrentRow.Insert("VATAmountWithoutReusablePackages",   CurrentData.VATAmountWithoutReusablePackages);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateFinalImplementationIndicators(ThisForm);
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products",                CurrentData.Products);
	CurrentRow.Insert("Package",                    CurrentData.Package);
	CurrentRow.Insert("Count",                  ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("NumberOfPackages",          ?(CurrentData.NumberOfPackages <> 0, CurrentData.NumberOfPackages, 1));
	CurrentRow.Insert("Price",                        CurrentData.Price);
	CurrentRow.Insert("Sum",                       CurrentData.Sum);
	CurrentRow.Insert("VATRate",                   CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",                    CurrentData.VATAmount);
	CurrentRow.Insert("VATAmountCompl", CurrentData.VATAmountCompl);
	CurrentRow.Insert("VATAmountMan", CurrentData.VATAmountMan);
	CurrentRow.Insert("AmountIncludingVAT",                   CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("WithoutReusablePackages",           CurrentData.WithoutReusablePackages);
	CurrentRow.Insert("SumWithoutReusablePackages",      CurrentData.SumWithoutReusablePackages);
	CurrentRow.Insert("AmountIncludingVATWithoutReusablePackages",  CurrentData.AmountIncludingVATWithoutReusablePackages);
	CurrentRow.Insert("VATAmountWithoutReusablePackages",   CurrentData.VATAmountWithoutReusablePackages);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	FillPropertyValues(CurrentData, CurrentRow, , "Count,NumberOfPackages");
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsWarehouseOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
								New Structure("Warehouse, SeriesSpecificationParameters",
												CurrentRow.Warehouse, SeriesSpecificationParameters.Goods));
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	DetailsOfFoundationDocument = DetailsOfFoundationDocument(Object.DocumentBasis);
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow <> Undefined Then
		
		SelectionForVATTaxation = DetailsOfFoundationDocument.VATTaxation;
		
		BusinessTransactionParameter =
			PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
		
		If Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then

			BusinessTransactionParameter = Object.BusinessOperation;
		EndIf;
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Currency",                Object.Currency);
		FilterParameters.Insert("Counterparty",            Object.Counterparty);
		FilterParameters.Insert("Contract",               Object.Contract);
		FilterParameters.Insert("VATTaxation",    SelectionForVATTaxation);
		FilterParameters.Insert("Organization",           Object.Organization);
		FilterParameters.Insert("Partner",               Object.Partner);
		FilterParameters.Insert("Terms",            Object.Terms);
		FilterParameters.Insert("BusinessOperation", BusinessTransactionParameter);
		FilterParameters.Insert("PriceIncludesVAT",       DetailsOfFoundationDocument.PriceIncludesVAT);
		
		OpenForm(
			"Document.SaleAdjustment.Form.ReferenceChoiceForm",
			New Structure("Filter,Warehouse,DocumentBasis", FilterParameters, Object.Warehouse, Object.DocumentBasis),
			Item,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSalesOrderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.SalesOrder = ValueSelected;
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Items.Goods.Name, Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	SeriesOnChange(Items.Goods.Name);
	
EndProcedure

&AtClient
Procedure GoodsPostingOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.CreditNoteRecordingOptions") Then
		
		CurrentRow.PostingOption = ValueSelected;
		
	Else
		
		CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.EmptyRef");
		
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure GoodsIncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure GoodsToExpenseAsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(
		ThisForm, CurrentData, "Object.Goods");
	GLAccountSettingsClientServer.WhenChangingAccountAvailabilityDetailsInLine(
		ThisForm, CurrentData, "Object.Goods");
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
		
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisForm, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisForm, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisForm, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDiscrepancies

&AtClient
Procedure DiscrepanciesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	If Field = Items.DiscrepanciesSalesOrder Then
		
		If ValueIsFilled(CurrentRow.SalesOrder) Then
			ShowValue(Undefined, CurrentRow.SalesOrder);
		EndIf;
		
	ElsIf Field = Items.DiscrepanciesMethodForDeterminingTheCostOfALine Then
		
		FillInCostInTable();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnActivateCell(Item)
	
	TableRow = Items.Discrepancies.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem <> Undefined
		And Item.CurrentItem = Items.DiscrepanciesPostingOption Then
		
		AddReturnToPath =
			UseShipmentWithDeferredTransferOfTitle2_5
			And Not SalesViaCommissionAgent
			And (Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
				Or Object.BusinessOperation = 
					PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
		
		ChoiceList = Items.DiscrepanciesPostingOption.ChoiceList;
		ChoiceList.Clear();
		
		If TableRow.NumberOfPackages > 0 Then
			
			If Not TableRow.Sum = 0
				And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
				And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
				And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
				And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
				And Not Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5")
				And True Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			
			If TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5")
				Or TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
			ElsIf TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount"));
			Else
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock"));
			EndIf;
			
		ElsIf TableRow.NumberOfPackages < 0 Then
			
			If TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
				Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5")
				Or False Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
			ElsIf TableRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
				If Not TableRow.Sum = 0 Then
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
				EndIf;
			Else
				If Not TableRow.Sum = 0 Then
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
				EndIf;
				If TableRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
				Else
					ChoiceList.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
				EndIf;
				If AddReturnToPath Then
					ChoiceList.Add(
						PredefinedValue(
							"Enum.CreditNoteRecordingOptions.ReturnToTransit"));
				EndIf;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesBeforeRowChange(Item, Cancel)
	
	FillPropertyValues(PreviousDetailsOfTSLineDiscrepancies, Items.Discrepancies.CurrentData);
	
EndProcedure

&AtClient
Procedure DiscrepanciesSeriesOnChange(Item)
	
	SeriesOnChange(Items.Discrepancies.Name);
	
EndProcedure

&AtClient
Procedure DiscrepanciesSeriesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenSelectionOfSeries(Items.Discrepancies.Name, Item.EditText);
	
EndProcedure

&AtClient
Procedure DiscrepanciesWarehouseOnChange(Item)
	
	CurrentData = Items.Discrepancies.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.UseWarehouseManagemantSystemForGoodsSurplusesShortages =
		UseWarehouseManagemantSystemForGoodsSurplusesShortages(CurrentData.Warehouse, Object.Date);
	
	If CurrentData.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
		
		If CurrentData.PostingOption =
			PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock") Then
			
			CurrentData.PostingOption =
				PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount");
			
		ElsIf CurrentData.PostingOption =
			PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock") Then
			
			CurrentData.PostingOption =
				PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount");
			
		EndIf;
		
	Else
		
		If CurrentData.PostingOption =
			PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount") Then
			
			CurrentData.PostingOption =
				PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock");
			
		ElsIf CurrentData.PostingOption =
			PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount") Then
			
			CurrentData.PostingOption =
				PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock");
			
		EndIf;
		
	EndIf;
		
	If UseShipmentWithDeferredTransferOfTitle2_5
		And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")) Then
		
		BatchAccountingWarehouse = ?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"),
							Object.Contract,
							CurrentData.Warehouse);
							
		StructureOfActions = New Structure;
		StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters",
				BatchAccountingWarehouse,
				SeriesSpecificationParameters.Discrepancies));
		
		BatchProcessingOfTablePartClient.ProcessTSString(
			CurrentData,
			StructureOfActions,
			CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesPostingOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	If TypeOf(ValueSelected) = Type("EnumRef.CreditNoteRecordingOptions") Then
		
		CurrentRow.PostingOption = ValueSelected;
		
		If ValueIsFilled(CurrentRow.CostDefiningMethod) Then
			CurrentRow.MethodForDeterminingTheCostOfALine = "";
			CurrentRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.EmptyRef");
		EndIf;
		
	Else
		
		CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.EmptyRef");
		
	EndIf;
	
	If UseShipmentWithDeferredTransferOfTitle2_5
		And (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods")) Then
		
		ProcessSelectionOfOptionToReflectDiscrepancy();
		
	Else
		ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesReturnValue_OnChange(Item)
	
	CurrentRow = Items.Discrepancies.CurrentData;
	
	If CurrentRow.ReturnValue_ Then
		CurrentRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit");
	Else
		CurrentRow.PostingOption = ?(CurrentRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages,
			PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"),
			PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesIncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);	
	
EndProcedure

&AtClient
Procedure DiscrepanciesIncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DiscrepanciesOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Discrepancies.CurrentData;	
	If NewRow And Not Copy Then
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.Discrepancies");
		SetCostPresentationInLine(CurrentRow);
	EndIf;	
	
EndProcedure

&AtClient
Procedure DiscrepanciesAreWayToDetermineCostOfLineOnChange(Item)
	
	EstablishCostPresentation();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPAdjustment

&AtClient
Procedure ARAPAdjustmentAdjustmentSumOnChange(Item)
	
	CurrentRow = Items.ARAPAdjustment.CurrentData;
	CurrentRow.SumOfVATAdjustments =
		PriceManagementSystemClientServer.CalculateVATAmount(
			CurrentRow.AdjustmentSum, 
			CurrentRow.VATRate,
			True,
			Object.VATTaxation);
	CurrentRow.AmountARAP = 0;
	
EndProcedure

&AtClient
Procedure ARAPAdjustmentSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.ARAPAdjustmentDocumentSalesOfGoodsAndServices
		Or Field = Items.ARAPAdjustmentARAPObject
		Or Field = Items.ARAPAdjustmentAmountIncludingVAT Then
		ShowValue(, Items.ARAPAdjustment.CurrentData.DocumentSalesOfGoodsAndServices);
	EndIf;
EndProcedure

&AtClient
Procedure ARAPAdjustmentOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	EndIf;
EndProcedure

&AtClient
Procedure ARAPAdjustmentBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure ARAPAdjustmentVATRateOnChange(Item)
	
	CurrentRow = Items.ARAPAdjustment.CurrentData;
	
	CurrentRow.VATAmount =
		PriceManagementSystemClientServer.CalculateVATAmount(
			CurrentRow.AmountIncludingVAT, 
			CurrentRow.VATRate,
			True,
			Object.VATTaxation);
	
	CurrentRow.SumOfVATAdjustments =
		PriceManagementSystemClientServer.CalculateVATAmount(
			CurrentRow.AdjustmentSum, 
			CurrentRow.VATRate,
			True,
			Object.VATTaxation);
	CurrentRow.AmountARAP = 0;
	
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
Procedure FillInBySourceData(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("FillInBySourceDataCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);

EndProcedure

&AtClient
Procedure SelectGoodsFromOrder(Command)
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5") Then
		OpenServiceSelection();
	Else
		SelectionOfGoodsAndServicesFromOrder();
	EndIf;
EndProcedure

&AtClient
Procedure GoodsSplitRow(Command)
	
	BreakTSString(Items.Goods.Name);
	
EndProcedure

&AtClient
Procedure DiscrepanciesSplitString(Command)
	
	BreakTSString(Items.Discrepancies.Name);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)
	
	ClearMessages();
	
	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		DiscrepanciesAreRelevant = False;
		
	EndIf;
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Goods.SelectedRows;
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(Object, Object.Goods, NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'"), SelectedRows) Then
		
		FilterStructure1 = New Structure("SelectGroup,IsFolder", PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"), False);
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Filter", FilterStructure1);
		ParametersStructure.Insert("GroupOfWarehouses", Object.Warehouse);
		ParametersStructure.Insert("TableRepresentation", TableRepresentation.List);

		OpenForm("Catalog.Warehouses.ChoiceForm", ParametersStructure, ThisForm,,,, New CallbackDescription("FillInTheWarehouseInSelectedLinesCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DiscrepanciesFillWarehouseInSelectedLines(Command)
	
	SelectedRows = Items.Discrepancies.SelectedRows;
	
	ItIsPossibleToFillWarehouse = WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
		Object,
		Object.Discrepancies,
		NStr("vi = 'Chênh lệch';
			|ru = 'Расхождения';
			|en = 'Discrepancies'; fa = 'مغایرت‌ها';
			|it = 'Discrepancies';
			|pl = 'Discrepancies';
			|tr = 'Tutarsızlıklar'"),
		SelectedRows);
	
	If ItIsPossibleToFillWarehouse Then
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("IsFolder", False);
		FilterStructure1.Insert("SelectGroup",
			PredefinedValue("Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices"));
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("Filter", FilterStructure1);
		ParametersStructure.Insert("GroupOfWarehouses", Object.Warehouse);
		ParametersStructure.Insert("TableRepresentation", TableRepresentation.List);
		
		CallbackDescription = New CallbackDescription(
			"DiscrepanciesFillWarehouseInSelectedLinesCompletion",
			ThisObject,
			New Structure("SelectedRows", SelectedRows));
		
		OpenForm(
			"Catalog.Warehouses.ChoiceForm",
			ParametersStructure,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
    
    SelectedRows = AdditionalParameters.SelectedRows;
    
    
    SelectedWarehouse = Result;
    
    If ValueIsFilled(SelectedWarehouse) Then
        
        FilledWithRows = FillWarehouseInSelectedLinesOnServer("Goods", SelectedRows, SelectedWarehouse);
        WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
        DiscrepanciesAreRelevant = False;
        
    EndIf;

EndProcedure

&AtClient
Procedure DiscrepanciesFillWarehouseInSelectedLinesCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	SelectedWarehouse = Result;
	
	If ValueIsFilled(SelectedWarehouse) Then
		
		FilledWithRows = FillWarehouseInSelectedLinesOnServer("Discrepancies", SelectedRows, SelectedWarehouse);
		
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(
			SelectedWarehouse,
			FilledWithRows,
			SelectedRows.Count());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure FillInTheDiscrepancies(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Discrepancies;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("FillInTheDiscrepanciesCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisObject, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure ToSetTheOptionsForAddressingGoods(Command)
	
	SetRecordingOptions("Goods");
	DiscrepanciesAreRelevant = False;
	
EndProcedure

&AtClient
Procedure ToSetTheOptionsForAddressingTheDiscrepancy(Command)
	
	SetRecordingOptions("Discrepancies");
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True, 
		"Document.SaleAdjustment.DocumentForm.Command.OpenSelection");
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
		Or Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'điều chỉnh bán hàng';
																			|ru = 'корректировку реализации';
																			|en = 'sales adjustment'; fa = 'sales adjustment';
																			|it = 'rettifica di realizzo';
																			|pl = 'zapis korygujący realizacji';
																			|tr = 'satış düzeltmesi'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("Title", HeaderParameter_);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("SelectionModeExcludeGroupsAvailableInOrders", True);
	FormParameters.Insert("Document", Object.Ref);
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		FormParameters.Insert("FilterByProductType", ArrayOfProductTypes);
		FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	Else
		FormParameters.Insert("Warehouse", Object.Warehouse);
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		FormParameters.Insert("HideExcisableGoods", Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
		FormParameters.Insert("DisplayTheHideExcisableGoodsFlag", Object.VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToUTII"));
		FormParameters.Insert("HideManualDiscounts", True);
		FormParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.Goods);
	EndIf;
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure PrintDetails(Item)
	
	OpenPrintDetails();
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	ClearMessages();
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)

	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInByReceivingNote(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("FillInByReceivingNoteCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Set kompozisyonunun açılması sadece bir set için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	KitParameters.Insert("DialColumns", DialColumns());
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("SalesOrder", CurrentRow.SalesOrder);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("Partner", Object.Partner);
	OpeningParameters.Insert("Terms", Object.Terms);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", True);
	Else
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	EndIf;
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If "IssueCashReceipt" = Var_URL Then
		
		StandardProcessing = False;
		
		ClearMessages();
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf "OpenRecordOfFiscalTransaction" = Left(Var_URL, 31) Then
				
		StandardProcessing = False;
		RecordID = Mid(Var_URL, 32);
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, RecordID);
		
	ElsIf "ConfigureHardware_" = Var_URL Then
		
		StandardProcessing = False;
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	UpdateTextDocumentsBasedOn();
	
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
Procedure PickUpDocuments(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Currency", Object.Currency);
	FormParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	
	SelectedDocuments = New Array();
	For Each TableRow In Object.ARAPAdjustment Do
		SelectedDocuments.Add(TableRow.DocumentSalesOfGoodsAndServices);
	EndDo;
	FormParameters.Insert("SelectedDocuments", SelectedDocuments);
	
	OpenForm("Document.SaleAdjustment.Form.SalesDocumentsPickForm", FormParameters, ThisForm);
	
EndProcedure


&AtClient
Procedure FillInReasonForDebtAdjustment(Command)
	CallbackDescription = New CallbackDescription("InputReasonsForDebtAdjustmentCompletion", ThisObject);
	TitleOfInputForm = NStr("vi = 'Hãy nhập lý do điều chỉnh';
							|ru = 'Введите причину корректировки';
							|en = 'Enter adjustment reason'; fa = 'Enter adjustment reason';
							|it = 'Inserire motivo rettifica';
							|pl = 'Wprowadź przyczynę korekty';
							|tr = 'Düzeltme nedenini girin'");
	ShowInputString(CallbackDescription, , TitleOfInputForm, 500);
EndProcedure

&AtClient
Procedure DistributeTotalAmountOfAdjustment(Command)
	CallbackDescription = New CallbackDescription("EnteringAdjustmentAmountCompletion", ThisObject);
	TitleOfInputForm = NStr("vi = 'Hãy nhập số tiền điều chỉnh';
							|ru = 'Введите сумму корректировки';
							|en = 'Enter adjustment amount'; fa = 'Enter adjustment amount';
							|it = 'Inserire importo rettifica';
							|pl = 'Wprowadź kwotę korekty';
							|tr = 'Düzeltme tutarını girin'");
	ShowInputNumber(CallbackDescription, 0, TitleOfInputForm, 31, 2);
EndProcedure

&AtClient
Procedure CalculateAmountOfAdjustmentByPercentage(Command)
	CallbackDescription = New CallbackDescription("EnteringPercentageAdjustmentsCompletion", ThisObject);
	TitleOfInputForm = NStr("vi = 'Hãy nhập phần trăm điều chỉnh';
							|ru = 'Введите процент корректировки';
							|en = 'Enter adjustment interest'; fa = 'Enter adjustment interest';
							|it = 'Inserire percentuale rettifica';
							|pl = 'Wprowadź procent korekty';
							|tr = 'Düzeltme yüzdesini girin'");
	ShowInputNumber(CallbackDescription, 0, TitleOfInputForm, 5, 2);
EndProcedure

&AtClient
Procedure AllCorrections(Command)
		
	CorrectedDocument = CorrectedDocument();	
	
	DocumentCorrectionClient.OpenListOfFixes(CorrectedDocument, Object.Ref);	

EndProcedure

&AtClient
Procedure EditDocumentBeingCorrected(Command)
		
	PickUpDocumentToBeCorrected();
	
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
Procedure GoodsAfterDeleteRowServer()
	
	WhenChangingWarehouseInTablePartServer();
	FormEvents.WhenChangingElement(ThisObject, "Goods");

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	GiverOperations = New ValueList;
	GiverOperations.Add(Enums.BusinessTransactions.ReportToMaterialProvider2_5);
	GiverOperations.Add(Enums.BusinessTransactions.Subcontracting2_5);
	GiverOperations.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	GiverOperations.Add(Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5);
	GiverOperations.Add(Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5);
	
	BidOperationsInHeader = New ValueList;
	BidOperationsInHeader.Add(Enums.BusinessTransactions.ReportToMaterialProvider2_5);
	BidOperationsInHeader.Add(Enums.BusinessTransactions.Subcontracting2_5);
	BidOperationsInHeader.Add(Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5);
	//
	VATAccountingERP.EstablishConditionalAppearanceOfHSCodeForTaxationOfSales(ThisObject);
	VATAccountingERP.EstablishConditionalAppearanceOfHSCodeForTaxationOfSales(ThisObject, "Discrepancies");
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsFEACNCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AdjustmentKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ErrorCorrection;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject);
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,
		"DiscrepanciesVATRate",
		"DiscrepanciesVATAmount",
		"DiscrepanciesAmountIncludingVAT");
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,,
		"DiscrepanciesVATAmountMan");
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisObject,,
		"DiscrepanciesVATAmountCompl");
	
	//
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject);
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "DiscrepanciesAmountIncludingVAT");
	
	//
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "DiscrepanciesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Discrepancies.Package";
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	// Warehouse in TS Goods
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject);
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Warehouse in TS Discrepancies
	
	WarehousesServer.SetConditionalAppearanceOfVTCHWarehouse(ThisObject, "DiscrepanciesWarehouse");
	
	//
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.DiscrepanciesWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "Object.Discrepancies.ItemsType";
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	//
	
	ReflectionsOptionsWithMandatoryWarehouse = Documents.SaleAdjustment.ReflectionsOptionsWithMandatoryWarehouse();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ReflectionsOptionsWithMandatoryWarehouse;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	//Departments
	
	// Goods for TS
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject);
	
	// For TS Discrepancies
	WarehousesServer.EstablishConditionalAppearanceOfVTCHDivision(ThisObject, "Discrepancies");
	
	//
	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisObject);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesSalesOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesRowCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SaleByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesSalesOrder.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesRowCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SaleByOrders");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSalesOrder.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOrdersInTabularSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesPostingOption.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = GiverOperations;
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SaleAdjustment2_5");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPostingOption.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsRowCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesRowCode.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.RowCode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.SalesOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối chiếu đơn hàng>';
													|ru = '<сверх заказа>';
													|en = '<exceeding the order>'; fa = '<exceeding the order>';
													|it = '<oltre ordine>';
													|pl = '<przewyższa zamówienie>';
													|tr = '<sipariş fazlası>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToReturnReusablePackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = GiverOperations;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Sum");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.OperationService);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToReturnReusablePackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = GiverOperations;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = BidOperationsInHeader;
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToReturnReusablePackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
																	"SeriesAlwaysWHGoods",
																	Items.DiscrepanciesSeries.Name,
																	"Object.Discrepancies.BatchesIndicationStatus",
																	"Object.Discrepancies.ItemsType");
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.DiscrepanciesSeries.Name);
		
		SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods");
		
		ValuesOfReflectionOptions = New ValueList;
		ValuesOfReflectionOptions.Add(
			PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
		ValuesOfReflectionOptions.Add(
			PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
		ValuesOfReflectionOptions.Add(
			PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount"));
		ValuesOfReflectionOptions.Add(
			PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock"));
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.PostingOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = ValuesOfReflectionOptions;
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.BatchesIndicationStatusInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
		ItemFilter.RightValue = 0;
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.BatchesIndicationStatusOfGoodsTransferred");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		
		SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
		SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.PostingOption");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit");
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.BatchesIndicationStatusInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = 0;
		
		ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.BatchesIndicationStatusOfGoodsTransferred");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
		ItemFilter.RightValue = 0;
		
		Item.Appearance.SetParameterValue("ReadOnly", False);
	EndIf;
	
	//
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCount.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OtherAssetServiceAdjustment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesMethodForDeterminingTheCostOfALine.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ValueList.Add(Enums.ItemsTypes.Work_5);
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.Count");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.PostingOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs");
	
	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<khi điều chỉnh hàng hóa/công việc trừ số lượng không ghi giảm>';
													|ru = '<при корректировке товара/работы в минус по количеству без списания>';
													|en = '<when adjusting goods/works in minus quantity without write-off>'; fa = '<when adjusting goods/works in minus quantity without write-off>';
													|it = '<alla correzione della merce/lavoro in meno per quantità senza storno>';
													|pl = '<przy korekcie towaru/pracy na minus według ilości bez rozchodu>';
													|tr = '<malların/işin miktar olarak eksik düzenlenmesi durumunda, herhangi bir gider yazma yapılmaksızın>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesReturnValue_.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Discrepancies.Count");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.GreaterOrEqual;
	ItemFilter.RightValue = 0;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Discrepancies.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesMethodForDeterminingTheCostOfALine.Name);
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseCostAccounting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CostAccountingAtBase");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesVATAmountCompl.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DiscrepanciesVATAmountMan.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue =
		PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);
	DiscrepanciesAreRelevant = False;

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);

	RowsToDelete = New Array;
	For Each LineOfATabularSection In SelectedRows Do
		If LineOfATabularSection.ItemsType = Enums.ItemsTypes.ReusablePackage And ToReturnReusablePackage Then
			RowsToDelete.Add(LineOfATabularSection);
			Continue;
		EndIf;
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	For Each LineToDelete In RowsToDelete Do
		SelectedRows.Delete(SelectedRows.Find(LineToDelete));
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	CalculateFinalImplementationIndicators(ThisObject);

EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()

	GoodsAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "Goods");

EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	If Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		Return;
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, ToReturnReusablePackage));
	
	CachedDiscrepancyValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Discrepancies, StructureOfActions, CachedDiscrepancyValues);
	
	CachedValuesOfProducts = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesOfProducts);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedDiscrepancyValues.ProcessedRows,
		StructureOfActions,
		Object.Discrepancies,
		Undefined);
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesOfProducts.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		Undefined);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateFinalImplementationIndicators(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		SetPrivilegedMode(True);
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
			FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(Object.DocumentBasis);
		ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
			FillParameters = Documents.CustomerInvoiceServices.ParametersForFillingInSalesVATTaxation(Object.DocumentBasis);
		ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
			FillParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForFillingInSalesVATTaxation(Object.DocumentBasis);
		ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
			FillParameters = Documents.ReportToMaterialProvider2_5.ParametersForFillingInVATTaxation_(Object.DocumentBasis);
		EndIf;
		SetPrivilegedMode(False);
		VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
		VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	EndIf;
	
EndProcedure


&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalImplementationIndicators(ThisForm);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	AdjustmentOfPreviousPeriodBeforeChange = LastPeriodAdjustment;
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
	
	AdjustTaxBaseOfPreviousPeriod = Not SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Object.Organization, DocumentDate);
		
	If AdjustmentOfPreviousPeriodBeforeChange <> LastPeriodAdjustment Then
		If OtherAssetServiceAdjustment Then
			DiscrepanciesAreRelevant = False;
		EndIf;
	EndIf;
	
	SetVisibilityOfElementsByBase();
	
	If Object.SaleAdjustment2_5 Then
		
		SaleAdjustmentLocalization.FillInReflectionInAccountingByDefault(ThisObject);
		UpdateReflectionInAccountingByDocumentAttributes();
		SetPropertiesOfElementsAccordingToAccountingPolicy();
		UpdateTrackingReflectionHeader();
		
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Date");
	UseCostAccounting = CalculationOfCostCached.CostCalculationIsPossible(Object.Date);
	
EndProcedure

&AtServer
Procedure OperationWhenChangingOnServer()
	
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(Operation);
	
	UpdateLabelsByOperation();
	SetVisibilityByOperation();
	EstablishVisibilityOfGroupOfOtherIncomeExpenses();
	UpdatePresentationElementsOfDocumentBeingCorrected();
	
	UpdateTextDocumentsBasedOn();

	DiscrepanciesAreRelevant = False;
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or Object.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		For Each TSRow In Object.Goods Do
			TSRow.PostingOption = Enums.CreditNoteRecordingOptions.EmptyRef();
		EndDo;
	EndIf;
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		Object.Goods.Clear();
		Object.Discrepancies.Clear();
		If ValueIsFilled(Object.DocumentBasis) Then
			AddImplementationDocumentToDebtAdjustmentTable(Object.DocumentBasis);
			Object.DocumentBasis = Undefined;
		EndIf;
		Object.Terms = Undefined;
		Object.Contract = Undefined;
		Object.Warehouse = Undefined;
	Else
		Object.ARAPAdjustment.Clear();
	EndIf;
	
	If Object.AdjustmentKind <> Enums.BusinessTransactions.ErrorCorrection Then
		Object.CorrectedDocument = Undefined;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
	SetPresentationOfFoundationDocument();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
	
EndProcedure

&AtServer
Procedure PartnerClientWhenChangingOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.CustomerPartner, Object.CustomerCounterparty);
	ClientCounterpartyWhenChangingOnServer();

EndProcedure

&AtServer
Procedure ClientCounterpartyWhenChangingOnServer()
	
	FillInDefaultEndClientContract();

EndProcedure


&AtServer
Procedure FillInCostAccountingAttribute()
	
	UseCostAccounting = CalculationOfCostCached.CostCalculationIsPossible(Object.Date);
	
EndProcedure

&AtClient
Procedure FillInCostInTable()
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Partner", Object.Partner);
	FormParameters.Insert("Counterparty", Object.Counterparty);
	FormParameters.Insert("Contract", Object.Contract);
	FormParameters.Insert("Terms", Object.Terms);
	FormParameters.Insert("DocumentCurrency", Object.Currency);
	FormParameters.Insert("TaxationType", Object.VATTaxation);
		
	SelectedRows = Items.Discrepancies.SelectedRows;
	RowsOfProductsTable = New Array();
	
	For Each CurRowId_ In SelectedRows Do
		
		TableRow = Object.Discrepancies.FindByID(CurRowId_);
		RowParameters = New Structure();
		
		RowParameters.Insert("Id", CurRowId_);
		RowParameters.Insert("CostDefiningMethod", TableRow.CostDefiningMethod);
		RowParameters.Insert("PriceKind", TableRow.CostPriceKind);
		RowParameters.Insert("DateOfCostFillingByPriceType", TableRow.DateOfCostFillingByPriceType);
		RowParameters.Insert("NumberOfPackages", ?(TableRow.NumberOfPackages > 0,
			TableRow.NumberOfPackages, -TableRow.NumberOfPackages));
		RowParameters.Insert("Package", TableRow.Package);
		RowParameters.Insert("Products", TableRow.Products);
		RowParameters.Insert("Characteristic", TableRow.Characteristic);
		RowParameters.Insert("VATRate", TableRow.VATRate);
		RowParameters.Insert("AmountIncludingVAT", TableRow.Cost_);
		RowParameters.Insert("AmountExcludingVAT", TableRow.CostExcludingVAT_);
		RowParameters.Insert("SumCompl", TableRow.CostLocal);
		RowParameters.Insert("AmountPermanentDifferences", TableRow.CDCost);
		RowParameters.Insert("AmountTemporaryDifferences", TableRow.TDCost);
		RowsOfProductsTable.Add(RowParameters);
		
	EndDo;
	
	FormParameters.Insert("RowsOfProductsTable", RowsOfProductsTable);
	
	OpenForm("Document.SaleAdjustment.Form.SelectionFormOfCostDefiningMethod",
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("ChoosingMethodForDeterminingCostOfProduction",
				ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

// Parameters:
// 	SelectionResult - Structure - goods row data:
// 		* RowsOfProductsTable - Array of See TMCommonUseClient.NewElementArrayProducts
// 	AdditionalParameters - Undefined - not analyzed
&AtClient
Procedure ChoosingMethodForDeterminingCostOfProduction(SelectionResult, AdditionalParameters) Export
	
	If TypeOf(SelectionResult) = Type("Structure") Then
		Rows = SelectionResult.RowsOfProductsTable;
		For Each String In Rows Do
			TableRow = Object.Discrepancies.FindByID(String.Id);
			If TableRow <> Undefined Then
				FillPropertyValues(TableRow, String);
			EndIf;
		EndDo;
		EstablishCostPresentation();
		Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure TransferDocumentToNewOrderOfReflectionInAccountingServer()
	
	Modified = True;
	Object.SaleAdjustment2_5 = True;
	
	EstablishVisibilityOfGroupOfOtherIncomeExpenses();
	SetVisibilityOfElementsByAdjustingImplementation2_5();
	UpdateOptionsForReflectingDiscrepancies2_5();
	
	SaleAdjustmentLocalization.FillInReflectionInAccountingByDefault(ThisObject);
	UpdateReflectionInAccountingByDocumentAttributes();
	SetPropertiesOfElementsAccordingToAccountingPolicy();
	UpdateTrackingReflectionHeader();

EndProcedure

&AtServer
Procedure FeaturesOfReflectionONChangeServer()
	
	UpdateAttributesOfAccountingDocument();
	UpdateTrackingReflectionHeader();
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region FillType

&AtServer
Procedure FillInBySourceDataServer()
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Chứng từ-cơ sở""';
				|ru = 'Поле ""Документ-основание"" не заполнено';
				|en = '""Base document"" is required'; fa = '""Base document"" is required';
				|it = 'Поле ""Документ-основание"" не заполнено';
				|pl = '""Base document"" is required';
				|tr = '""Temel belge"" alanı doldurulmamış'"),
			,
			"BaseDocumentPresentation");
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(
		Object.DocumentBasis,
		Object.Goods,
		Object.Discrepancies,
		Object.Ref);
	SetPrivilegedMode(False);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		StructureOfActions);
	SetsServer.FillInServiceDetails(ThisForm, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In Object.Goods Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
	WhenChangingWarehouseInTablePartServer();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, ToReturnReusablePackage);
	
	DiscrepanciesAreRelevant = (Object.Discrepancies.Count() = 0);
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInByReceivingNoteServer()
	
	DocumentObject = FormDataToValue(Object, Type("DocumentObject.SaleAdjustment"));
	Documents.SaleAdjustment.FillInGoodsAccordingToAcceptanceCertificate(DocumentObject);
	ValueToFormData(DocumentObject, Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods,
		StructureOfActions);
	SetsServer.FillInServiceDetails(ThisForm, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In Object.Goods Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
	WhenChangingWarehouseInTablePartServer();
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, ToReturnReusablePackage);
	
	DiscrepanciesAreRelevant = True;
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Partner", Object.Partner);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("Organization", Object.Organization);
	
	If SalesViaCommissionAgent Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Object.Contract, "SalesPriceType"));
	Else
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
	EndIf;
	
	If Not NumberOfPackagesIsUsed Then
		FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalImplementationIndicators(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	SetsServerCall.AddToFullSet(Object.Goods, RowsArray);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", ?(NumberOfPackagesIsUsed, "NumberOfPackages", "Count"));
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
		
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Organization", Object.Organization);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", PricesKind);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	If Not NumberOfPackagesIsUsed Then
		FillParameters.Insert("ColumnsByValue", New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef()));
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		RowsArray,
		FillParameters,
		StructureOfActions);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalImplementationIndicators(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillWarehouseInSelectedLinesOnServer(TSName, Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object[TSName], ArrayOfSelectedRows, Warehouse);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Goods);
	WhenChangingWarehouseInTablePartServer();
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In Object[TSName] Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
	If Object.SaleAdjustment2_5 And TSName = "Discrepancies" Then
		UpdateOptionsForReflectingDiscrepancies2_5();
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServer
Procedure FillInTheDiscrepanciesServer()
	
	If Not ValueIsFilled(Object.DocumentBasis) Then
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Chứng từ-cơ sở""';
				|ru = 'Поле ""Документ-основание"" не заполнено';
				|en = '""Base document"" is required'; fa = '""Base document"" is required';
				|it = 'Поле ""Документ-основание"" не заполнено';
				|pl = '""Base document"" is required';
				|tr = '""Temel belge"" alanı doldurulmamış'"),
			,
			"BaseDocumentPresentation");
		Return;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		ArrayOfCurrencies = New Array();
		
		If Object.ARAPCurrency <> LocalAccountingCurrency Then
			ArrayOfCurrencies.Add(NStr("ru = 'регл.';
										|vi = 'local';
										|en = 'local'; fa = 'local';
										|it = 'local';
										|pl = 'local';
										|tr = 'yerel'"));
		EndIf;
		
		If Object.ARAPCurrency <> ManagementAccountingCurrency Then
			ArrayOfCurrencies.Add(NStr("ru = 'упр.';
										|vi = 'mgmt';
										|en = 'mgmt'; fa = 'mgmt';
										|it = 'mgmt';
										|pl = 'mgmt';
										|tr = 'yönetim'"));
		EndIf;
		
		If ArrayOfCurrencies.Count() Then
			
			Common.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Суммы НДС %1 были рассчитаны приблизительно. Необходимо проверить корректность их заполнения.';
						|vi = '%1 VAT amounts were calculated approximately. Check if they are filled correctly.';
						|en = '%1 VAT amounts were calculated approximately. Check if they are filled correctly.'; fa = '%1 VAT amounts were calculated approximately. Check if they are filled correctly.';
						|it = '%1 VAT amounts were calculated approximately. Check if they are filled correctly.';
						|pl = '%1 VAT amounts were calculated approximately. Check if they are filled correctly.';
						|tr = 'KDV tutarları %1 yaklaşık olarak hesaplandı. Doğru dolduruldukları kontrol edilmelidir.'"),
					StrConcat(ArrayOfCurrencies, " " + NStr("ru = 'и';
															|vi = 'and';
															|en = 'and'; fa = 'و';
															|it = 'and';
															|pl = 'and';
															|tr = 've'") + " ")));
			
		EndIf;
		
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(Object);
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInTheDiscrepancies();
	Object.Goods.Load(DocumentObject.Goods.Unload());
	Object.Discrepancies.Load(DocumentObject.Discrepancies.Unload());
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Discrepancies, True);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Discrepancies);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Discrepancies, StructureOfActions, CachedValues);
	
	UpdateServiceDetailsOfTableParts();
	
	DiscrepanciesAreRelevant = True;
	CalculateFinalImplementationIndicators(ThisObject);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns()
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");

	Return Columns;
	
EndFunction

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisForm, "Goods", AdditionalParameter);
		DiscrepanciesAreRelevant = False;
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
		DiscrepanciesAreRelevant = False;
	EndIf;
	
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	DiscrepanciesAreRelevant = False;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	// The warehouse will be inserted later
	StructureOfActionsWithModifiedStrings.Insert("CheckSeriesCalculateStatus",
													New Structure("SeriesSpecificationParameters",
																	SeriesSpecificationParameters.Goods));
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",
													New Structure("SeriesSpecificationParameters",
																	SeriesSpecificationParameters.Goods));
	StructureOfActionsWithAddedStrings.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("CheckFillPackageByOwner", Undefined);
	StructureOfActionsWithAddedStrings.Insert("CheckFillWarehouse", BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActionsWithAddedStrings.Insert("FillInSubdivisionInTSLine", New Structure("Department", Object.Department));
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns());
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

#EndRegion
#Region Assignments

&AtServerNoContext
Function GetContractAssignment(Val Object)
	
	If ValueIsFilled(Object.Contract) Then
		
		DestinationPattern   = Documents.ReportToMaterialProvider2_5.DestinationPattern(Object.DocumentBasis);
		PurposeOfContract = Catalogs.Assignments.FindByTemplate(DestinationPattern);
		
	Else
		
		PurposeOfContract = Catalogs.Assignments.EmptyRef();
		
	EndIf;
		
	Return PurposeOfContract;
	
EndFunction

#EndRegion
#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalImplementationIndicators(Form)
	
	If Form.PackageDepositIsRequired Then
		Form.AmountTotal = Form.Object.Goods.Total("AmountIncludingVAT");
		Form.VATAmount = Form.Object.Goods.Total("VATAmount");
	Else
		Form.AmountTotal = Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages");
		Form.VATAmount = Form.Object.Goods.Total("VATAmountWithoutReusablePackages");
	EndIf;
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ToUseTermsOfSales =
		True
		And Not Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		And Not Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		And Not Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		And Not Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		And Not Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		And GetFunctionalOption("ToUseTermsOfSales");
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	UseLinesOfBusiness  = GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness");
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	UseLocal = GetFunctionalOption("UseLocal");
	
	AdjustTaxBaseOfPreviousPeriod = Not SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Object.Organization, DocumentDate);
		
	// Enabled FO use of the load without transition_2_5 means enabled
	// To use the agreement by customers, and the mandatory use of the Contract in the agreement.
	// We check the jackdaws [Contracts of counterparties are used] and [possible sale without transfer of ownership]
	// in the agreement in case we make an adjustment based on the implementation with the business transaction Sale to the client.
	If ToUseTermsOfSales Then
		
		AttributesValues = Common.ObjectAttributesValues(
			Object.Terms,
			"ContractsAreUsed, SaleWithDeferredTransferOfTitleIsAllowed");
		
		UseShipmentWithDeferredTransferOfTitle2_5 =
			GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5")
				And AttributesValues.ContractsAreUsed = True
				And AttributesValues.SaleWithDeferredTransferOfTitleIsAllowed = True;
		
	Else
		
		UseShipmentWithDeferredTransferOfTitle2_5 =
			GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");

	EndIf;
	
	FillInCostAccountingAttribute();
	
	If Not ValueIsFilled(Object.DocumentBasis)
		And Parameters.Property("Basis") Then
			Parameters.Property("Basis",Object.DocumentBasis);
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		SetPrivilegedMode(True);
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(Object.DocumentBasis, "Date");
		SetPrivilegedMode(False);
		DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
		OtherAssetServiceAdjustment = TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets");
	Else
		LastPeriodAdjustment = False;
		OtherAssetServiceAdjustment = False;
		ReferenceDocumentDateForCertificate = Object.Date;
	EndIf;
	
	FillInBusinessTransactionOfFoundationDocument();
	SalesViaCommissionAgent = ConsignmentSalesServer.SalesViaCommissionAgent(Operation);
	
	SetVisibilityOfElementsByAdjustingImplementation2_5();
	If Object.SaleAdjustment2_5 Then
		UpdateReflectionInAccountingByDocumentAttributes();
		SetPropertiesOfElementsAccordingToAccountingPolicy();
		UpdateTrackingReflectionHeader();
	EndIf;
	
	CostAccountingAtBase = CalculationOfCostCached.CostCalculationIsPossible(ReferenceDocumentDateForCertificate);
	
	If Not GetFunctionalOption("UseConsolidatedDebtAdjustmentOperationsForSales") Then
		
		OperationSelectionList = Items.Operation.ChoiceList;
		IncreaseInDebt = OperationSelectionList.FindByValue(
				Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated);
		If IncreaseInDebt <> Undefined
			And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
			OperationSelectionList.Delete(IncreaseInDebt);
		EndIf;
		
		DebtReduction_ = OperationSelectionList.FindByValue(
				Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated);
		If DebtReduction_ <> Undefined 
			And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
			OperationSelectionList.Delete(DebtReduction_);
		EndIf;
	EndIf;
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	SetPresentationOfFoundationDocument();
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetVisibilityOfElementsByBase();
	
	SetAvailabilityOfItemsByStatusServer();
	
	SetVisibilityByOrders();
	
	FillOperationSelectionList();
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	
	MarkEmptyWarehouse();
	
	If Not GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments") And Not GetFunctionalOption("UseBusinessUnits") Then
		Items.ProductsGroupSender.Visible      = False;
		Items.DiscrepanciesGroupSender.Visible = False;
	ElsIf Not WarehouseGroup_ Then
		Items.ProductsGroupSender.Title      = NStr("vi = 'Bộ phận gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Reparto-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen birim'");
		Items.DiscrepanciesGroupSender.Title = NStr("vi = 'Bộ phận gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Reparto-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen departman'");
	EndIf;
	
	Items.GroupPictureAndLabelMultipleWarehouses.Visible = WarehouseGroup_;
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.SaleAdjustment);
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.Goods.UseItemsBatch;
	Items.DiscrepanciesSeries.Visible           = SeriesSpecificationParameters.Discrepancies.UseItemsBatch;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
	WhenChangingWarehouseInTablePartServer();
	Items.GoodsFillInTheWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	Items.DiscrepanciesFillWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	
	SetParametersForSelectingProductsWarehouse();
	SetItemSelectionParameters();
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible);
	
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	
	UpdateTextDocumentsBasedOn();
	If Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		
		UseOrdersInTabularSection = 
			GetFunctionalOption("UseReportToMaterialProviderBySeveralOrders2_5");
		
		If ValueIsFilled(Object.DocumentBasis)
			And (Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5) Then
			VATRate = Common.ObjectAttributeValue(Object.DocumentBasis, "VATRate");
		EndIf;
		
	Else
		UseOrdersInTabularSection = GetFunctionalOption("UseSaleByMultipleOrders")
			Or GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	EndIf;

	UpdateServiceDetailsOfTableParts();
	
	BasisChanged = False;
	If AccessRight("Update", Metadata.Documents.SaleAdjustment) And ValueIsFilled(Object.Basis) Then
		If ValueIsFilled(Object.Basis) Then
			BaseStructure = Documents.SaleAdjustment.StructureOfBaseForPrinting(Object);
			BasisChanged = (TrimAll(Object.Basis) <> BaseStructure.Basis) 
				Or (TrimAll(Object.BaseDocumentNumber) <> BaseStructure.BaseDocumentNumber)
				Or (Object.ReferenceDocumentDateForPrintForms <> BaseStructure.ReferenceDocumentDateForPrintForms);
		EndIf;
	EndIf;
	PrintBasisTable.Load(Documents.SaleAdjustment.PrintBasisTable(Object));
	
	DiscrepanciesAreRelevant = True;
	
	ToReturnReusablePackage = False;
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		SetPrivilegedMode(True);
		ToReturnReusablePackage = Common.ObjectAttributeValue(Object.DocumentBasis,"ToReturnReusablePackage");
		PackageDepositIsRequired = Common.ObjectAttributeValue(Object.DocumentBasis,"PackageDepositIsRequired");
		SetPrivilegedMode(False);
	EndIf;
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, ToReturnReusablePackage);
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateFinalImplementationIndicators(ThisObject);
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ChoiceParameter = New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes));
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(ChoiceParameter);
		Items.GoodsProducts.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ChoiceParameter = New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes));
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(ChoiceParameter);
		Items.GoodsProducts.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	EndIf;
	
	UpdateLabelsByOperation();
	SetVisibilityByOperation();
	EstablishVisibilityOfGroupOfOtherIncomeExpenses();
	UpdatePresentationElementsOfDocumentBeingCorrected();
	EstablishCostPresentation();
	
	Items.SaleRegistrationOption.Visible = TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice");
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	ProcessingOfTabularForms.InitializeRowCache(Items.Discrepancies);
	
	FillParameters = Documents.SaleAdjustment.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	CurrentCompany = Object.Organization;
	CurrentCurrency = Object.Currency;
	CurCurrencyOfSettlements = Object.ARAPCurrency;
	CurrentCounterparty = Object.Counterparty;
	CurPartner = Object.Partner;
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
			BaseDocumentPresentation = String(Object.DocumentBasis) + " (" + Operation + ")";
		Else
			BaseDocumentPresentation = Object.DocumentBasis;
		EndIf;
		Items.BaseDocumentPresentation.TextColor = StyleColors.HyperlinkColor;
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		BaseDocumentPresentation = NStr("vi = 'Giao hàng và cung cấp dịch vụ <chưa chọn>';
										|ru = 'Реализация товаров и услуг <не выбран>';
										|en = 'Customer invoice <not selected>'; fa = 'Customer invoice <not selected>';
										|it = 'Realizzo delle merci e servizi <non selezionato>';
										|pl = 'Realizacja towarów i usług <не выбран>';
										|tr = 'Müşteri faturası <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		BaseDocumentPresentation = NStr("vi = 'Biên bản nghiệm thu công việc <không chọn>';
										|ru = 'Акт выполненных работ <не выбран>';
										|en = 'Customer invoice — Services <not selected>'; fa = 'Customer invoice — Services <not selected>';
										|it = 'Verbale di consegna dei lavori effettuati <non selezionato>';
										|pl = 'Protokół odbioru wykonania prac <nie wybrano>';
										|tr = 'Gerçekleştirilen işler raporu <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		BaseDocumentPresentation = NStr("vi = 'Giao hàng và cung cấp dịch vụ và bán tài sản khác <chưa chọn>';
										|ru = 'Реализация услуг и прочих активов <не выбран>';
										|en = '""Customer invoice — Services and Assets"" <not selected>'; fa = '""Customer invoice — Services and Assets"" <not selected>';
										|it = 'Realizzo dei servizi e altri attivi <non selezionato>';
										|pl = 'Realizacja usług i innych aktywów <nie wybrano>';
										|tr = 'Hizmet ve diğer varlıkların satışı <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5")
		Or Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		BaseDocumentPresentation = NStr("vi = 'Bảng kê dành cho bên thuê gia công <chưa chọn>';
										|ru = 'Отчет давальцу <не выбран>';
										|en = 'Consumption report — Subcontracting services delivered <is not selected>'; fa = 'Consumption report — Subcontracting services delivered <is not selected>';
										|it = 'Report al datore <non selezionato>';
										|pl = 'Raport dla właściciela surowców <nie wybrano>';
										|tr = 'Tüketim raporu-Verilen fason hizmetleri <seçilmemiş>'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
	Else
		BaseDocumentPresentation = NStr("vi = 'Hãy chọn chứng từ cơ sở';
										|ru = 'Выберите документ-основание';
										|en = 'Select a base document'; fa = 'Select a base document';
										|it = 'Selezionare documento base';
										|pl = 'Wybierz dokument źródłowy';
										|tr = 'Lütfen, temel belge seçin.'");
		Items.BaseDocumentPresentation.TextColor = StyleColors.SpecialTextColor;
	EndIf;
	
	If ValueIsFilled(Object.DiscrepancyReportFollowingShipmentBaseDocument) Then
		SubmissionOfTheDocumentOfTheBasisOfTheAcceptanceCertificate = Object.DiscrepancyReportFollowingShipmentBaseDocument;
		Items.BaseDocumentPresentation.TextColor = StyleColors.HyperlinkColor;
	Else
		Items.GoodsFillInByReceivingNote.Visible = False;
		Items.GroupOfGroundsForTheActOfDiscrepancies.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByBase()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.SaleAdjustment.FillInNamesOfDetailsOnBasis(
		Object.DocumentBasis, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	NumberOfPackagesIsUsed = Items.GoodsNumberOfPackages.Visible;
	UsedPackaging = Items.GoodsPackage.Visible;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsCount", "Visible", Not UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsNumberOfPackages", "Visible", UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsProductsUnitOfMeasure", "Visible", Items.GoodsProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsOpenSelection", "Visible", Items.GoodsProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillThePricesByTermsOfSales", "Visible", ToUseTermsOfSales And Items.GoodsProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsFillInPricesOfSelectedRowsByPriceType", "Visible", Items.GoodsProducts.Visible);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesCount", "Visible", Not UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesNumberOfPackages", "Visible", UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesPackage", "Visible", UsedPackaging);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DiscrepanciesProductsUnitOfMeasure", "Visible", Items.DiscrepanciesProducts.Visible);
	
	If OtherAssetServiceAdjustment Then
		
		If LastPeriodAdjustment Then
			
			ArrayOfElementNames = New Array;
			ArrayOfElementNames.Add("TextForOtherExpenses");
			TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", True);
			
		Else
			
			ArrayOfElementNames = New Array;
			ArrayOfElementNames.Add("TextForOtherExpenses");
			ArrayOfElementNames.Add("BusinessUnit");
			ArrayOfElementNames.Add("BusinessUnitExpenses");
			TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", False);
			
		EndIf;
		
		ArrayOfElementNames = New Array;
		ArrayOfElementNames.Add("GoodsSetComposition");
		ArrayOfElementNames.Add("GoodsSetIndex");
		ArrayOfElementNames.Add("GoodsProductsInSet");
		ArrayOfElementNames.Add("GoodsItemVariantOfSet");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", False);
		
	EndIf;
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("PictureMultipleWarehouses");
	ArrayOfElementNames.Add("SeveralWarehousesText");
	ArrayOfElementNames.Add("GoodsFillInTheWarehouseInSelectedLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible", Items.GoodsWarehouse.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("DiscrepanciesFillWarehouseInSelectedLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible",
		Items.DiscrepanciesWarehouse.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("AmountForOtherExpenses");
	ArrayOfElementNames.Add("CurrencyForOtherExpenses");
	ArrayOfElementNames.Add("AllowanceForOtherExpenses");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible",
		Items.ExpenseItem.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("AmountForOtherExpensesInAddition");
	ArrayOfElementNames.Add("CurrencyForOtherExpensesInAddition");
	ArrayOfElementNames.Add("OffsetForOtherExpensesInAddition");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible",
		Items.ItemOfExpenditureAdditional.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("AmountForOtherIncomeInAddition");
	ArrayOfElementNames.Add("CurrencyForOtherIncomeInAddition");
	ArrayOfElementNames.Add("OtherIncomeTaxInAddition");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible",
		Items.SourceOfIncomeAdditionally.Visible);
	
	ArrayOfElementNames = New Array;
	ArrayOfElementNames.Add("AmountForOtherIncomeInAddition");
	ArrayOfElementNames.Add("CurrencyForOtherIncomeInAddition");
	ArrayOfElementNames.Add("OtherIncomeTaxInAddition");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ArrayOfElementNames, "Visible",
		Items.SourceOfIncomeAdditionally.Visible);
	
	Items.PriceIncludesVAT.WarningOnEditRepresentation = ?(Items.GoodsPriceKind.Visible,
		WarningOnEditRepresentation.Show,
		WarningOnEditRepresentation.DontShow);
		
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	ItemArray.Add("Date");
	ItemArray.Add("Operation");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("SubjectToExcise");
	ItemArray.Add("Goods;BeforeAddRow,BeforeDeleteRow,BeforeRowChange;GoodsIncomeItem,GoodsDimensionOfRevenue");
	ItemArray.Add("Discrepancies;;DiscrepanciesReturnValue_,DiscrepanciesIncomeItem,DiscrepanciesDimensionOfRevenue");
	ItemArray.Add("GoodsFill");
	ItemArray.Add("GoodsOpenSelection");
	ItemArray.Add("GoodsSelectGoodsFromOrder");
	ItemArray.Add("GoodsSplitRow");
	ItemArray.Add("GoodsFillThePricesByTermsOfSales");
	ItemArray.Add("GoodsFillInPricesOfSelectedRowsByPriceType");
	ItemArray.Add("GoodsFillInTheWarehouseInSelectedLines");
	ItemArray.Add("HowToSetReflectionOptions");
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsFillInByReceivingNote");
	ItemArray.Add("GoodsFillInVATRate");
	ItemArray.Add("GoodsSetComposition");
	ItemArray.Add("DiscrepanciesSplitString");
	ItemArray.Add("DiscrepanciesFillInTheDiscrepancies");
	ItemArray.Add("DiscrepanciesSetRecordingOptions");
	ItemArray.Add("DiscrepanciesFillWarehouseInSelectedLines");
	ItemArray.Add("ARAPAdjustment");
	ItemArray.Add("FillInReasonForDebtAdjustment");
	ItemArray.Add("ARAPAdjustmentPickUpDocuments");
	ItemArray.Add("DistributeTotalAmountOfAdjustment");
	ItemArray.Add("CalculateAmountOfAdjustmentByPercentage");
	ItemArray.Add("EditDocumentBeingCorrected");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServer
Procedure SetVisibilityByOrders()
	
	If Object.SaleByOrders Then
		Items.GoodsAdd.Title = NStr("vi = 'Thêm hàng hóa bên phía trên đơn hàng ';
									|ru = 'Добавить товары сверх заказа';
									|en = 'Add goods exceeding the order'; fa = 'افزودن کالای مازاد بر سفارش';
									|it = 'Aggiungere le merci oltre l''ordine';
									|pl = 'Dodaj wiersze pozycji ponad zamówienia';
									|tr = 'Sipariş fazlası ürünleri ekle'");
	Else
		Items.GoodsAdd.Title = NStr("vi = 'Thêm';
									|ru = 'Добавить';
									|en = 'Add'; fa = 'افزودن';
									|it = 'Aggiungere';
									|pl = 'Add';
									|tr = 'Ekle'");
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "GoodsSelectGoodsFromOrder", "Visible", Object.SaleByOrders);
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or Object.SaleAdjustment2_5 Then
		
		ListItem = Items.Operation.ChoiceList.FindByValue(Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
		If ListItem <> Undefined Then
			Items.Operation.ChoiceList.Delete(ListItem);
		EndIf;
		ListItem = Items.Operation.ChoiceList.FindByValue(Enums.BusinessTransactions.SaleOfOverdeliveredGoods);
		If ListItem <> Undefined Then
			Items.Operation.ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function OptionsForSelectingArticlesAndAnalytics()
	
	OptionsForSelection = Documents.SaleAdjustment.ParametersForDeterminingAvailabilityOfSelectionOfArticlesAndAnalytics();
	OptionsForSelection.BusinessOperation	= Object.AdjustmentKind;
	OptionsForSelection.DocumentBasis		= Object.DocumentBasis;
	OptionsForSelection.DocumentDate			= Object.Date;
	
	RecordInOtherIncome	= False;
	ToExpenseAs		= False;

	If Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		RecordInOtherIncome	= False;
		ToExpenseAs		= True;
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
		RecordInOtherIncome	= True;
		ToExpenseAs		= False;
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or Object.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		
		RecordInOtherIncome	= AmountForOtherIncome > 0;
		ToExpenseAs		= AmountForOtherExpenses > 0;
		
	Else
		RecordInOtherIncome	= AmountForOtherIncome > 0;
		ToExpenseAs		= AmountForOtherExpenses > 0;
	EndIf;
	
	OptionsForSelection.RecordInOtherIncome	= RecordInOtherIncome;
	OptionsForSelection.ToExpenseAs			= ToExpenseAs;
	
	OptionsForSelection.SaleAdjustment2_5 = Object.SaleAdjustment2_5;
	OptionsForSelection.RecordInProfitLossOfPreviousYears = Object.RecordInProfitLossOfPreviousYears;
	OptionsForSelection.AdjustTaxBaseOfPreviousPeriod = Object.AdjustTaxBaseOfPreviousPeriod;
	
	Return OptionsForSelection;
	
EndFunction

&AtServer
Procedure ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies()
	
	AmountForOtherIncome  = 0;
	AmountForOtherExpenses = 0;
	TotalAmountShovelcharge = 0;
	TotalAmountZhamanshina = 0;
	TotalAmountJavelina = 0;
	TotalAmountOfNDSUReduction = 0;
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		CalculateTotalsFromDebtAdjustmentTable();
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
		CalculateTotalsFromDebtAdjustmentTable();
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or Object.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		CalculateTotalsOnGoodsTable_(Object.Goods);
	Else
		CalculateTotalsOnGoodsTable_(Object.Discrepancies);
	EndIf;
	
	OptionsForSelection = OptionsForSelectingArticlesAndAnalytics();
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);

	TextForOtherExpenses = StrTemplate(NStr("vi = 'Các chi phí khác: %1 %2';
											|ru = 'Прочие расходы: %1 %2';
											|en = 'Other expenses: %1 %2'; fa = 'Other expenses: %1 %2';
											|it = 'Altre spese: %1 %2';
											|pl = 'Inne rozchody: %1 %2';
											|tr = 'Diğer giderler: %1 %2'"), 
		Format(AmountForOtherExpenses, "NFD=2; NZ="), 
		Object.Currency);
		
	TextForOtherIncome = StrTemplate(NStr("vi = 'Thu nhập khác: %1 %2';
											|ru = 'Прочие доходы:  %1 %2';
											|en = 'Income: %1 %2'; fa = 'Income: %1 %2';
											|it = 'Altri ricavi: %1 %2';
											|pl = 'Inne dochody:  %1 %2';
											|tr = 'Diğer gelirler: %1 %2'"), 
		Format(AmountForOtherIncome, "NFD=2; NZ="), 
		Object.Currency);
		
	AvailabilityCosts = ValueIsFilled(AmountForOtherExpenses);
	Items.BusinessUnitExpenses.Enabled				= AvailabilityCosts;
	Items.AdditionalExpensesDivision.Enabled	= AvailabilityCosts;
	
	AvailabilityOfIncome = ValueIsFilled(AmountForOtherIncome);
	Items.BusinessUnit.Enabled				= AvailabilityOfIncome;
	Items.TheDivisionOfIncomeInAddition.Enabled	= AvailabilityOfIncome;
	TheseGrounds = New Structure("BusinessOperation", Operation);
	UseExcisableGoods = TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice")
									And Documents.CustomerInvoice.ExcisableGoodsAreUsed(TheseGrounds);
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, , ReferenceDocumentDateForCertificate);
	
EndProcedure

&AtServer
Procedure CalculateTotalsOnGoodsTable_(TabularSection)
		
	For Each TSRow In TabularSection Do
		
		TotalAmountShovelcharge = TotalAmountShovelcharge + ?(TSRow.AmountIncludingVAT > 0, TSRow.AmountIncludingVAT, 0);
		TotalAmountZhamanshina = TotalAmountZhamanshina + ?(TSRow.AmountIncludingVAT < 0, -TSRow.AmountIncludingVAT, 0);
		
		TotalAmountJavelina = TotalAmountJavelina + ?(TSRow.VATAmount > 0, TSRow.VATAmount, 0);
		TotalAmountOfNDSUReduction = TotalAmountOfNDSUReduction + ?(TSRow.VATAmount < 0, -TSRow.VATAmount, 0);
		
		If TSRow.PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome Then
			If OtherAssetServiceAdjustment And Not LastPeriodAdjustment  Then
				AmountForOtherIncome = AmountForOtherIncome + TSRow.AmountIncludingVAT;
			Else
				AmountForOtherIncome = AmountForOtherIncome + ?(TSRow.AmountIncludingVAT<0, -TSRow.AmountIncludingVAT, TSRow.AmountIncludingVAT);
			EndIf;
		ElsIf TSRow.PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs
			Or TSRow.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleWriteOffForExpenses Then
			AmountForOtherExpenses = AmountForOtherExpenses + ?(TSRow.AmountIncludingVAT<0, -TSRow.AmountIncludingVAT, TSRow.AmountIncludingVAT);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateTotalsFromDebtAdjustmentTable()
	
	For Each TSRow In Object.ARAPAdjustment Do
		
		If Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
			TotalAmountZhamanshina = TotalAmountZhamanshina + TSRow.AdjustmentSum;
			TotalAmountOfNDSUReduction = TotalAmountOfNDSUReduction + TSRow.SumOfVATAdjustments;
			AmountForOtherExpenses = AmountForOtherExpenses + TSRow.AdjustmentSum - TSRow.SumOfVATAdjustments;
		ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
			TotalAmountShovelcharge = TotalAmountShovelcharge + TSRow.AdjustmentSum;
			TotalAmountJavelina = TotalAmountJavelina + TSRow.SumOfVATAdjustments;
			AmountForOtherIncome = AmountForOtherIncome + TSRow.AdjustmentSum - TSRow.SumOfVATAdjustments;
		EndIf
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfTableParts()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	SetsServer.FillInServiceDetails(ThisForm, "Goods");
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In Object.Goods Do
		
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
		
	EndDo;
	
	UpdateServiceDetailsOfTablePartOfDiscrepancy(WarehouseData_2);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, ToReturnReusablePackage);
	
EndProcedure

&AtServer
Procedure WhenChangingWarehouseInTablePartServer()

	WarehousesServer.WhenChangingWarehouseInTablePart(Object.Goods, WarehouseTable, WarehouseGroup_, False);
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(SeveralWarehousesText, Items.PictureMultipleWarehouses, TotalWarehouses_);

EndProcedure

&AtServer
Procedure UpdateServiceDetailsOfTablePartOfDiscrepancy(WarehouseData_2)
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInProductTypeAttribute_",	New Structure("Products", "ItemsType"));

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Discrepancies, StructureCharacteristicsOfProducts);
			
	SetsServer.FillInServiceDetails(ThisForm, "Discrepancies");
	
	For Each LineOfDiscrepancies In Object.Discrepancies Do
		
		WarehouseData_1 = WarehouseData_2.Find(LineOfDiscrepancies.Warehouse);
		If WarehouseData_1 <> Undefined Then
			LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
		
	EndDo;
	
	If Object.SaleAdjustment2_5 Then
		UpdateOptionsForReflectingDiscrepancies2_5();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingDocumentSelectionViaServer(ValueSelected)
	
	Modified = True;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(ValueSelected);
	ValueToFormAttribute(DocumentObject, "Object");
	
	Object.DocumentBasis = ValueSelected;
	
	OnReadCreateAtServer();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Goods);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessingProductSelectionFromOrder(GoodsAddressInStorage)
	
	GoodsTable = GetFromTempStorage(GoodsAddressInStorage);
	FillInReportOfGiver =
		?(Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5,
			True,
			False);
	
	RateOfGoodsVAT = Catalogs.VATRates.EmptyRef();
	If FillInReportOfGiver
		And ValueIsFilled(Object.DocumentBasis)
		And (Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5) Then
		RateOfGoodsVAT = Common.ObjectAttributeValue(Object.DocumentBasis, "VATRate");
	EndIf;
	ProductSearchStructure_ = New Structure("RowCode, SalesOrder");
	For Each RowOfGoods In GoodsTable Do
		
		// PM goods processing.
		ProductSearchStructure_.RowCode = RowOfGoods.RowCode;
		If FillInReportOfGiver Then
			ProductSearchStructure_.SalesOrder = RowOfGoods.MaterialProviderOrder;
		Else
			ProductSearchStructure_.SalesOrder = RowOfGoods.SalesOrder;
		EndIf;
		ArrayOfTSRows = Object.Goods.FindRows(ProductSearchStructure_);
		
		If ArrayOfTSRows.Count() = 0 Then
			
			StringTSGoods = Object.Goods.Add();
			
		ElsIf ArrayOfTSRows.Count() = 1 Then
			
			StringTSGoods = ArrayOfTSRows[0];
			
		ElsIf ArrayOfTSRows.Count() > 1 Then
			
			For Each RowToDelete In ArrayOfTSRows Do
				
				Object.Goods.Delete(RowToDelete);
				
			EndDo;
			
			StringTSGoods = Object.Goods.Add();
			
		EndIf;
		
		FillPropertyValues(StringTSGoods, RowOfGoods);
		StringTSGoods.SalesOrder = ProductSearchStructure_.SalesOrder;
		StringTSGoods.SetIndex = ?(ValueIsFilled(StringTSGoods.ProductsInSet),1,0);
		If FillInReportOfGiver
			And (Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
				Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5) Then
			StringTSGoods.VATRate = RateOfGoodsVAT;
		EndIf;
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisForm, "Goods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, ToReturnReusablePackage);
	
	WhenChangingWarehouseInTablePartServer();
	DiscrepanciesAreRelevant = False;
	
	FillBaseForPrinting();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Goods);
	
EndProcedure

&AtServerNoContext
Function DetailsOfFoundationDocument(DocumentBasis)
	
	Return Common.ObjectAttributesValues(DocumentBasis, "VATTaxation, PriceIncludesVAT");
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure CheckForAdjustments(Ref, Basis, ThereAreAdjustingEntries) Export
	
	SalesServer.CheckForAdjustments(Ref, Basis, ThereAreAdjustingEntries)
	
EndProcedure

&AtServerNoContext
Function CheckForCorrectionsAfterDocumentDate(Document)
	
	AttributesNames = "Date, AdjustmentKind, DocumentBasis, CorrectedDocument";
	DocumentAttributes = Common.ObjectAttributesValues(Document, AttributesNames);
	
	CheckParameters = InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters();
	CheckParameters.Ref = Document;
	CheckParameters.Date = DocumentAttributes.Date;
	CheckParameters.CorrectedDocument = Documents.SaleAdjustment.CorrectedDocument(DocumentAttributes);
	
	SetPrivilegedMode(True);
	Patch = DocumentCorrection.CorrectionAfterDocumentDate(CheckParameters);
	Patch = ?(ValueIsFilled(Patch), String(Patch), "");
	Return Patch;
	
EndFunction

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
												|ru = 'Поле ""Соглашение"" не заполнено';
												|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
												|it = 'Il campo ""Accordo"" non è compilato';
												|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
												|tr = '""Anlaşma"" alanı doldurulmamış'"), Object.Ref, "Object.Terms",,Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Currency) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
												|ru = 'Поле ""Валюта"" не заполнено';
												|en = '""Currency"" is required'; fa = '""Currency"" is required';
												|it = 'Il campo ""Valuta"" non è compilato';
												|pl = 'Pole ""Waluta"" nie jest wypełnione';
												|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent",
		BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(
			Object, True));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	StructureOfActions.Insert("CheckFillWarehouse", 
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInSubdivisionInTSLine",
		New Structure("Department", Object.Department));
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, 
			"ProductsInSet,
			|ItemVariantOfSet,
			|Products,
			|Characteristic,
			|Package,
			|Warehouse,
			|PriceKind,
			|Price,
			|NumberOfPackages,
			|Series");
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet),1,0);
		
		FillCustomerOrder(ThisObject, CurrentRow);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	SetsServer.FillInServiceDetails(ThisObject, "Goods");
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In Object.Goods Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
	WhenChangingWarehouseInTablePartServer();
	DiscrepanciesAreRelevant = False;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Goods);
	
EndProcedure

&AtClient
Procedure OpenPrintDetails()
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	ParametersStructure = New Structure();
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
		ParametersStructure.Insert("DeliveryAddressValue",          Object.DeliveryAddressValue);
		ParametersStructure.Insert("DeliveryAddressFieldValues",     Object.DeliveryAddressFieldValues);
		ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
		ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
		ParametersStructure.Insert("Shipper",               Object.Shipper);
		ParametersStructure.Insert("GoodsRecipient",                Object.GoodsRecipient);
		ParametersStructure.Insert("LetterOfAuthorityIssuedBy",             Object.LetterOfAuthorityIssuedBy);
		ParametersStructure.Insert("PowerOfAttorneyDate",               Object.PowerOfAttorneyDate);
		ParametersStructure.Insert("PowerOfAttorneyPerson",               Object.PowerOfAttorneyPerson);
		ParametersStructure.Insert("PowerOfAttorneyNumber",              Object.PowerOfAttorneyNumber);
		ParametersStructure.Insert("IssuiedBy",                       Object.IssuiedBy);
		ParametersStructure.Insert("IssuiedByJobTitle",              Object.IssuiedByJobTitle);
		ParametersStructure.Insert("ObjectType",                     "SaleAdjustment");
		
	ElsIf TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		ParametersStructure.Insert("ObjectType",                     "CustomerInvoiceServices");
		
	EndIf;
	
	ParametersStructure.Insert("DeliveryAddress",                  Object.DeliveryAddress);
	ParametersStructure.Insert("DeliveryAddressValue",          Object.DeliveryAddressValue);
	ParametersStructure.Insert("DeliveryAddressFieldValues",     Object.DeliveryAddressFieldValues);
	ParametersStructure.Insert("ShipperBankAccount", Object.ShipperBankAccount);
	ParametersStructure.Insert("GoodsRecipientBankAccount",  Object.GoodsRecipientBankAccount);
	ParametersStructure.Insert("CounterpartyBankAccount",      Object.CounterpartyBankAccount);
	ParametersStructure.Insert("Contract",                        Object.Contract);
	ParametersStructure.Insert("Basis",                      Object.Basis);
	ParametersStructure.Insert("ReferenceDocumentDateForPrintForms",                  Object.ReferenceDocumentDateForPrintForms);
	ParametersStructure.Insert("BaseDocumentNumber",                 Object.BaseDocumentNumber);
	ParametersStructure.Insert("Partner",                        Object.Partner);
	ParametersStructure.Insert("BusinessOperation",          PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
	ParametersStructure.Insert("Counterparty",                     Object.Counterparty);
	ParametersStructure.Insert("ReadOnly",                 ReadOnly);
	ParametersStructure.Insert("SaleByOrders",               Object.SaleByOrders);
	ParametersStructure.Insert("CompanyBankAccount",      Object.CompanyBankAccount);
	ParametersStructure.Insert("Organization",                    Object.Organization);
	ParametersStructure.Insert("Date",                           Object.Date);
	ParametersStructure.Insert("Director",                   Object.Director);
	ParametersStructure.Insert("ChiefAccountant",               Object.ChiefAccountant);
	ParametersStructure.Insert("PrintBasisTable",      PrintBasisTable);
	
	OpenForm("CommonForm.PrintingDetailsOfSales", ParametersStructure, ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function GetDataOnWarehouses()
	
	WarehousesOfDiscrepancies = Object.Discrepancies.Unload(,"Warehouse");
	WarehousesOfDiscrepancies.GroupBy("Warehouse");
	WarehousesOfDiscrepancies.Columns.Add("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
		New TypeDescription("Boolean"));
	
	For Each Page1 In WarehousesOfDiscrepancies Do
		If ValueIsFilled(Page1.Warehouse) Then
			Page1.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Page1.Warehouse, Object.Date);
		EndIf;
	EndDo;
	
	WarehousesOfGoods = Object.Goods.Unload(,"Warehouse");
	WarehousesOfGoods.GroupBy("Warehouse");
	
	For Each Page1 In WarehousesOfGoods Do
		If ValueIsFilled(Page1.Warehouse)
			And WarehousesOfDiscrepancies.Find(Page1.Warehouse,"Warehouse") = Undefined Then
			WarehouseLine_ = WarehousesOfDiscrepancies.Add();
			WarehouseLine_.Warehouse = Page1.Warehouse;
			WarehouseLine_.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Page1.Warehouse, Object.Date);
		EndIf;
	EndDo;
	
	Return WarehousesOfDiscrepancies;
	
EndFunction

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages",
		"Sum,VATAmount,AmountIncludingVAT");
	
EndFunction

&AtServer
Procedure UpdateLabelsByOperation()
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods Then
		Text = NStr("vi = '(giao quá)';
					|ru = '(перепоставка)';
					|en = '(overdelivery)'; fa = '(overdelivery)';
					|it = '(fornitura in eccesso)';
					|pl = '(ponowna dostawa)';
					|tr = '(yeniden teslimat)'");
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		Text = NStr("vi = '(không giao hàng)';
					|ru = '(недопоставка)';
					|en = '(underdelivery)'; fa = '(underdelivery)';
					|it = '(fornitura incompleta)';
					|pl = '(dostawa niekompletna)';
					|tr = '(eksik teslimat)'");
	Else
		Text = NStr("vi = '(sau khi điều chỉnh)';
					|ru = '(после корректировки)';
					|en = '(after adjustment)'; fa = '(after adjustment)';
					|it = '(dopo la rettifica)';
					|pl = '(po zapisie korygującym)';
					|tr = '(düzeltme sonrası)'");
	EndIf;
	Items.GroupGoods.Title = NStr("vi = 'Hàng hóa';
									|ru = 'Товары';
									|en = 'Goods'; fa = 'کالاها';
									|it = 'Merci';
									|pl = 'Goods';
									|tr = 'Ürünler'") + " " + Text;
	
	If Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		Items.GroupDebtAdjustment.Title = NStr("vi = 'Giảm nợ';
												|ru = 'Уменьшение задолженности';
												|en = 'Receivables decrease'; fa = 'Receivables decrease';
												|it = 'Riduzione debito';
												|pl = 'Zmniejszenie zadłużenia';
												|tr = 'Borçlarda azalma'");
		Items.ARAPAdjustmentAdjustmentSum.Title = NStr("vi = 'Số tiền giảm';
														|ru = 'Сумма уменьшения';
														|en = 'Decrease amount'; fa = 'مبلغ کاهش';
														|it = 'Importo ridotto';
														|pl = 'Suma zmniejszenia';
														|tr = 'Azalma miktarı'");
		Items.ARAPAdjustmentSumOfVATAdjustments.Title = NStr("vi = 'Số tiền thuế GTGT giảm';
															|ru = 'Сумма НДС уменьшения';
															|en = 'Decrease VAT amount'; fa = 'Decrease VAT amount';
															|it = 'Importo IVA di riduzione';
															|pl = 'Kwota VAT zmniejszenia';
															|tr = 'KDV indirimi miktarı'");
		Items.DebtAdjustmentGroupFill.Title = NStr("vi = 'Điền số tiền giảm';
													|ru = 'Заполнить сумму уменьшения';
													|en = 'Fill in decrease amount'; fa = 'Fill in decrease amount';
													|it = 'Compilare importo riduzione';
													|pl = 'Wypełnij kwotę zmniejszenia';
													|tr = 'Azalma miktarını doldur'")
	ElsIf Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
		Items.GroupDebtAdjustment.Title = NStr("vi = 'Tăng nợ';
												|ru = 'Увеличение задолженности';
												|en = 'Receivables increase'; fa = 'Receivables increase';
												|it = 'Aumento debito';
												|pl = 'Zwiększenie zadłużenia';
												|tr = 'Borçlarda artış'");
		Items.ARAPAdjustmentAdjustmentSum.Title = NStr("vi = 'Số tiền tăng';
														|ru = 'Сумма увеличения';
														|en = 'Increase amount'; fa = 'مبلغ افزایش';
														|it = 'Importo aumentato';
														|pl = 'Wartość wzrostu';
														|tr = 'Artış miktarı'");
		Items.ARAPAdjustmentSumOfVATAdjustments.Title = NStr("vi = 'Số tiền GTGT tăng';
															|ru = 'Сумма НДС увеличения';
															|en = 'Increase VAT amount'; fa = 'Increase VAT amount';
															|it = 'Importo IVA di aumento';
															|pl = 'Kwota VAT zwiększenia';
															|tr = 'KDV artışı miktarı'");
		Items.DebtAdjustmentGroupFill.Title = NStr("vi = 'Điền số tiền tăng';
													|ru = 'Заполнить сумму увеличения';
													|en = 'Fill in increase amount'; fa = 'Fill in increase amount';
													|it = 'Compilare l''importo di aumento';
													|pl = 'Wypełnij kwotę zmniejszenia';
													|tr = 'Artış miktarını doldur'")
	Else
		Items.GroupDebtAdjustment.Title = NStr("vi = 'Điều chỉnh công nợ';
												|ru = 'Корректировка задолженности';
												|en = 'AR/AP adjustment'; fa = 'اصلاح دریافتنی/پرداختنی';
												|it = 'Rettifica dell''indebitamento';
												|pl = 'Korekta zadłużenia';
												|tr = 'Borçların düzenlenmesi'");
		Items.ARAPAdjustmentAdjustmentSum.Title = NStr("vi = 'Số tiền điều chỉnh';
														|ru = 'Сумма корректировки';
														|en = 'Adjustment amount'; fa = 'مبلغ تعدیل';
														|it = 'Importo di rettifica';
														|pl = 'Wartość zapisu korygującego';
														|tr = 'Düzeltme tutarı'");
		Items.ARAPAdjustmentSumOfVATAdjustments.Title = NStr("vi = 'Số tiền thuế GTGT điều chỉnh';
															|ru = 'Сумма НДС корректировки';
															|en = 'Adjustment VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده تعدیل';
															|it = 'Importo IVA di rettifica';
															|pl = 'Kwota VAT korekty';
															|tr = 'KDV düzeltme tutarı'");
		Items.DebtAdjustmentGroupFill.Title = NStr("vi = 'Điền số tiền điều chỉnh';
													|ru = 'Заполнить сумму корректировки';
													|en = 'Fill in adjustment amount'; fa = 'تکمیل مبلغ تعدیل';
													|it = 'Compilare importo di rettifica';
													|pl = 'Wypełnij kwotę korekty';
													|tr = 'Düzeltme tutarını doldur'")
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityByOperation()
	
	VisibilityProducts = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
		
	Items.GroupGoods.Visible = VisibilityProducts;
	
	VisibilityOfElements = Object.AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or Object.AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods;
	
	Items.GoodsPostingOption.Visible = VisibilityOfElements;
	Items.HowToSetReflectionOptions.Visible = VisibilityOfElements;
	Items.GroupOtherIncomeExpensesAdditional.Visible = (TypeOf(Object.DocumentBasis) <> Type("DocumentRef.CustomerInvoiceServicesAndAssets") And VisibilityOfElements);
	
	VisibilityOfElements = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
		
	Items.Discrepancies.Visible = VisibilityOfElements;
	
	Items.GroupClientData.Visible						= SalesViaCommissionAgent;
	Items.Warehouse.Visible									= Not SalesViaCommissionAgent;
	Items.GoodsFillInTheWarehouseInSelectedLines.Visible	= Not SalesViaCommissionAgent;
	
	ThereAreTotalsOfDiscrepancies = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
	
	ThereAreTotalsOfDiscrepanciesDecrease = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
		
	Items.TotalAmountShovelcharge.Visible = ThereAreTotalsOfDiscrepancies;
	Items.TotalAmountZhamanshina.Visible = ThereAreTotalsOfDiscrepanciesDecrease;
	Items.SummaryTheTotalIncreaseInVAT.Visible = ThereAreTotalsOfDiscrepancies;
	Items.TotalAmountOfTotalReductionWithoutVAT.Visible = ThereAreTotalsOfDiscrepanciesDecrease;
	Items.TotalAmountJavelina.Visible = ThereAreTotalsOfDiscrepancies;
	Items.TotalAmountOfNDSUReduction.Visible = ThereAreTotalsOfDiscrepanciesDecrease;
	
	ThereAreTotals = 
		Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
		
	Items.TotalAmountWithVAT.Visible = ThereAreTotals;
	Items.GroupTotalVATAmount_3.Visible = ThereAreTotals;
	Items.GroupTotalTotalAmountWithoutVAT.Visible = ThereAreTotals;
	
	ThisIsDebtAdjustment = 
		Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
		
	UseAgreement = True;
	UseAgreement =
		?(Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5,
			False,
			True);
	Items.GroupDebtAdjustment.Visible = ThisIsDebtAdjustment;
	Items.Partner.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Counterparty.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Organization.ReadOnly = Not ThisIsDebtAdjustment;
	Items.VATTaxation.ReadOnly = Not ThisIsDebtAdjustment;
	
	Items.SalesOpportunity.ReadOnly = Not ThisIsDebtAdjustment;
	Items.Department.ReadOnly = Not ThisIsDebtAdjustment;
	
	Items.Terms.Visible = Not ThisIsDebtAdjustment And UseAgreement;
	Items.Contract.Visible = Not ThisIsDebtAdjustment;
	Items.Warehouse.Visible = Not ThisIsDebtAdjustment;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		Items.Warehouse.ReadOnly = False;
		Items.Warehouse.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		
	EndIf;
	
	Items.BaseDocumentGroup.Visible = Not ThisIsDebtAdjustment;
	Items.PrintGroup.Visible = Not ThisIsDebtAdjustment;
	Items.PriceIncludesVAT.Visible = Not ThisIsDebtAdjustment;
	Items.DiscrepanciesSplitString.Visible = Items.DiscrepanciesSeries.Visible
													And UseShipmentWithDeferredTransferOfTitle2_5
													And (Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
														Or Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
	Items.DiscrepanciesContextMenuSplitLine.Visible = Items.DiscrepanciesSplitString.Visible;
	Items.DiscrepanciesFillWarehouseInSelectedLines.Visible =
		Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	ThisIsReductionInDebt =
		Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
	Items.GroupOtherExpensesDebtAdjustment.Visible = ThisIsReductionInDebt;
	
	ThisIsIncreaseInDebt =
		Object.AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
	Items.GroupOtherIncomeDebtAdjustment.Visible = ThisIsIncreaseInDebt;

	TMCommonUseClientServer.SetFormItemProperty(Items, "GroupDocumentBeingCorrected", 
		"Visible", ValueIsFilled(Object.DocumentBasis) And Object.AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection);
	
EndProcedure

&AtClient
Procedure SetRecordingOptions(TSName)
	
	AdjustingGiver = False;
	AdjustingGiver =
		Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReportToMaterialProvider2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.Subcontracting2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5");
	ThereIsIncreaseInNumberOfOrdersInWarehouse = False;
	ThereIsIncreaseInQuantityWithoutInventory = False;
	ThereIsDecreaseInNumberOfOrdersInWarehouse = False;
	ThereIsDecreaseInQuantityWithoutInventory = False;
	ThereIsIncreaseInRevenue                     = False;
	ThereIsIncreaseInRevenueWithoutReflection         = False;
	ThereIsDecreaseInRevenue                     = False;
	ThereIsDecreaseInRevenueWithoutWriteOff          = False;
	
	AddReturnToPath =
		UseShipmentWithDeferredTransferOfTitle2_5
		And Not SalesViaCommissionAgent
		And (Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
			Or Object.BusinessOperation = 
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	AddWriteOffToExpenses        = Not Object.SaleAdjustment2_5;
	AddReflectOnOtherIncome = Not Object.SaleAdjustment2_5;
	
	For Each TSRow In Object[TSName] Do
		
		If (TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
			Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")) Then
			
			If (TSRow.Count > 0 And Object.AdjustmentKind <> PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods")) Then
				If TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
					Or AdjustingGiver Then
					If Not TSRow.Sum = 0 Then
						ThereIsIncreaseInRevenue = True;
					Else
						ThereIsIncreaseInRevenueWithoutReflection = True;
					EndIf;
				ElsIf TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
					ThereIsIncreaseInNumberOfOrdersInWarehouse = True;
				Else
					ThereIsIncreaseInQuantityWithoutInventory = True;
				EndIf; 
				
			ElsIf (TSRow.Count < 0 Or Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods")) Then
				If AdjustingGiver
					Or TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
					If Not TSRow.Sum = 0 Then
						ThereIsDecreaseInRevenue = True;
					Else
						ThereIsDecreaseInRevenueWithoutWriteOff = True;
					EndIf;
				ElsIf TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
					ThereIsDecreaseInNumberOfOrdersInWarehouse = True;
				Else
					ThereIsDecreaseInQuantityWithoutInventory = True;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ThereIsIncreaseInNumberOfOrdersInWarehouse
		Or ThereIsIncreaseInQuantityWithoutInventory
		Or ThereIsDecreaseInNumberOfOrdersInWarehouse
		Or ThereIsDecreaseInQuantityWithoutInventory
		Or ThereIsIncreaseInRevenue
		Or ThereIsIncreaseInRevenueWithoutReflection
		Or ThereIsDecreaseInRevenue
		Or ThereIsDecreaseInRevenueWithoutWriteOff Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("TSName",                                                 TSName);
		AdditionalParameters.Insert("ListOfOptionsToChooseFrom",                              New Array);
		AdditionalParameters.Insert("PropertyNameForSelectionResult",                        Undefined);
		
		AdditionalParameters.Insert("ReflectionOptionIncreasingQuantityByOrderWarehouse", Undefined);
		AdditionalParameters.Insert("ReflectionOptionIncreaseQuantityWithoutInventory", Undefined);
		AdditionalParameters.Insert("ReflectionOptionReductionOfQuantityByOrderWarehouse", Undefined);
		AdditionalParameters.Insert("ReflectionOptionReducingQuantityWithoutInventory", Undefined);
		AdditionalParameters.Insert("ReflectionOptionRevenueIncrease",                     Undefined);
		AdditionalParameters.Insert("ReflectionOptionRevenueIncreaseWithoutReflection",         Undefined);
		AdditionalParameters.Insert("ReflectionOptionDecreaseInRevenue",                     Undefined);
		AdditionalParameters.Insert("ReflectionOptionRevenueReductionWithoutWriteOff",          Undefined);
		
		If ThereIsIncreaseInNumberOfOrdersInWarehouse Then
			
			ListOfReflectionOptions = New ValueList;
			If AddReflectOnOtherIncome Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount"));
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIncreasingQuantityByOrderWarehouse", ListOfReflectionOptions));
				
		EndIf;
		If ThereIsIncreaseInQuantityWithoutInventory Then
			ListOfReflectionOptions = New ValueList;
			If AddReflectOnOtherIncome Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock"));

			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionIncreaseQuantityWithoutInventory", ListOfReflectionOptions));
			
		EndIf;
		If ThereIsIncreaseInRevenue Then
			ListOfReflectionOptions = New ValueList;
			If AddReflectOnOtherIncome Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.RecordInOtherIncome"));
			EndIf;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionRevenueIncrease", ListOfReflectionOptions));
			
		EndIf;                                      
		If ThereIsIncreaseInRevenueWithoutReflection Then
			ListOfReflectionOptions = New ValueList;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSale"));
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionRevenueIncreaseWithoutReflection", ListOfReflectionOptions));
			
		EndIf;                                      
		If ThereIsDecreaseInNumberOfOrdersInWarehouse Then
			ListOfReflectionOptions = New ValueList;
			If AddWriteOffToExpenses Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			EndIf;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
			If AddReturnToPath Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit"));
			EndIf;
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionReductionOfQuantityByOrderWarehouse", ListOfReflectionOptions));
				
		EndIf;
		If ThereIsDecreaseInQuantityWithoutInventory Then
			ListOfReflectionOptions = New ValueList;
			If AddWriteOffToExpenses Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			EndIf;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
			If AddReturnToPath Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit"));
			EndIf;
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionReducingQuantityWithoutInventory", ListOfReflectionOptions));
			
		EndIf;
		If ThereIsDecreaseInRevenue Then
			ListOfReflectionOptions = New ValueList;
			If AddWriteOffToExpenses Then
				ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs"));
			EndIf;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionDecreaseInRevenue", ListOfReflectionOptions));
			
		EndIf;
		If ThereIsDecreaseInRevenueWithoutWriteOff Then
			ListOfReflectionOptions = New ValueList;
			ListOfReflectionOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSale"));
			
			AdditionalParameters.ListOfOptionsToChooseFrom.Add(New Structure("PropertyNameForSelectionResult, ListOfReflectionOptions", "ReflectionOptionRevenueReductionWithoutWriteOff", ListOfReflectionOptions));
			
		EndIf;
		
		SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(AdditionalParameters);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Không có dòng, trong đó có thể thay đổi phương án hiển thị.';
							|ru = 'Нет строк, в которых доступно изменение варианта отражения.';
							|en = 'No lines in which posting options can be changed.'; fa = 'No lines in which posting options can be changed.';
							|it = 'Non ci sono righe nelle quali fosse disponibile la modifica della variante di visualizzazione.';
							|pl = 'Brak wierszy, w których jest dostępna zmiana wariantu odzwierciedlenia.';
							|tr = 'Yansıtma seçeneği değişikliğinin mevcut olduğu hiçbir satır yoktur.'"));
		
	EndIf;
	
	Return;
EndProcedure

&AtClient
Procedure SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(AdditionalParameters);

	If AdditionalParameters.ListOfOptionsToChooseFrom.Count() > 0 Then
		
		ListOfReflectionOptions = AdditionalParameters.ListOfOptionsToChooseFrom[0].ListOfReflectionOptions;
		StructureFilter = New Structure("Ref", ListOfReflectionOptions);
		AdditionalParameters.PropertyNameForSelectionResult = AdditionalParameters.ListOfOptionsToChooseFrom[0].PropertyNameForSelectionResult;
		AdditionalParameters.ListOfOptionsToChooseFrom.Delete(0);
		If ListOfReflectionOptions.Count() > 1 Then
			OpenForm(
				"Enum.CreditNoteRecordingOptions.ChoiceForm", 
				New Structure("Filter", StructureFilter),,,,,
				New CallbackDescription("SelectOptionsForReflectingImplementationAdjustmentsInteractively", ThisObject, AdditionalParameters), FormWindowOpeningMode.LockOwnerWindow);
			Return;
		Else
			SelectOptionsForReflectingImplementationAdjustmentsInteractively(ListOfReflectionOptions[0].Value, AdditionalParameters);
		EndIf;
	Else
		
		// PM processing based on the results of the user's choice of reflection options.
		SetRecordingOptionsCompletion(AdditionalParameters);
		
	EndIf;
		
EndProcedure

&AtClient
Procedure SelectOptionsForReflectingImplementationAdjustmentsInteractively(PostingOption, AdditionalParameters) Export
	
	PropertyNameForSelectionResult = Undefined;
	If AdditionalParameters.Property("PropertyNameForSelectionResult", PropertyNameForSelectionResult) Then
		AdditionalParameters.Insert(PropertyNameForSelectionResult, PostingOption);
	EndIf;
	SelectInteractivelyOptionsForReflectingAdjustmentsToImplementationsFragment(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SetRecordingOptionsCompletion(AdditionalParameters)
	
	If ValueIsFilled(AdditionalParameters.ReflectionOptionIncreasingQuantityByOrderWarehouse)
		Or	ValueIsFilled(AdditionalParameters.ReflectionOptionIncreaseQuantityWithoutInventory)
		Or ValueIsFilled(AdditionalParameters.ReflectionOptionRevenueIncrease)
		Or ValueIsFilled(AdditionalParameters.ReflectionOptionRevenueIncreaseWithoutReflection)
		Or ValueIsFilled(AdditionalParameters.ReflectionOptionReductionOfQuantityByOrderWarehouse)
		Or ValueIsFilled(AdditionalParameters.ReflectionOptionReducingQuantityWithoutInventory)
		Or ValueIsFilled(AdditionalParameters.ReflectionOptionDecreaseInRevenue)
		Or ValueIsFilled(AdditionalParameters.ReflectionOptionRevenueReductionWithoutWriteOff)Then
		
		For Each TSRow In Object[AdditionalParameters.TSName] Do
			
			If TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
				Continue;
			EndIf;
			
			If (TSRow.Count > 0 And Object.AdjustmentKind <> PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods")) Then
				If TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages And ValueIsFilled(AdditionalParameters.ReflectionOptionIncreasingQuantityByOrderWarehouse) Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionIncreasingQuantityByOrderWarehouse;
				ElsIf TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
					And ValueIsFilled(AdditionalParameters.ReflectionOptionRevenueIncrease)
					And Not TSRow.Sum = 0 Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionRevenueIncrease;
				ElsIf ValueIsFilled(AdditionalParameters.ReflectionOptionIncreaseQuantityWithoutInventory) Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionIncreaseQuantityWithoutInventory;
				ElsIf TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
					And ValueIsFilled(AdditionalParameters.ReflectionOptionRevenueIncreaseWithoutReflection)
					And TSRow.Sum = 0 Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionRevenueIncreaseWithoutReflection;
				EndIf;
			ElsIf (TSRow.Count < 0 Or Object.AdjustmentKind = PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods")) Then	
				If TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages And ValueIsFilled(AdditionalParameters.ReflectionOptionReductionOfQuantityByOrderWarehouse) Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionReductionOfQuantityByOrderWarehouse;
					TSRow.ReturnValue_ = TSRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit");
				ElsIf TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
					And Not TSRow.Sum = 0 Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionDecreaseInRevenue;
				ElsIf ValueIsFilled(AdditionalParameters.ReflectionOptionReducingQuantityWithoutInventory) Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionReducingQuantityWithoutInventory;
					TSRow.ReturnValue_ = TSRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit");
				ElsIf TSRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
					And ValueIsFilled(AdditionalParameters.ReflectionOptionRevenueReductionWithoutWriteOff)
					And TSRow.Sum = 0 Then
					TSRow.PostingOption = AdditionalParameters.ReflectionOptionRevenueReductionWithoutWriteOff;
				EndIf;
				If TSRow.PostingOption = PredefinedValue("Enum.CreditNoteRecordingOptions.ToExpenseAs")
					And CommonClientServer.HasAttributeOrObjectProperty(TSRow,
						"CostDefiningMethod")
					And ValueIsFilled(TSRow.CostDefiningMethod) Then
					TSRow.CostDefiningMethod = PredefinedValue("Enum.WaysToCalculateReturnCost.EmptyRef");
					TSRow.MethodForDeterminingTheCostOfALine = "";
				EndIf;
			EndIf;
			
		EndDo;
		
		SetRecordingOptionsServer(AdditionalParameters.TSName)
	EndIf;
	
EndProcedure

&AtServer
Procedure SetRecordingOptionsServer(TSName)
	
	If TSName = Items.Discrepancies.Name Then
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Discrepancies);
	EndIf;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	MarkEmptyWarehouse();
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfOptionToReflectDiscrepancy()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Discrepancies);
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
	MarkEmptyWarehouse();
	
EndProcedure

&AtServer
Procedure FillBaseForPrinting()
	
	If Not BasisChanged Then
		BaseStructure = Documents.SaleAdjustment.StructureOfBaseForPrinting(Object);
		FillPropertyValues(Object, BaseStructure);
	EndIf;
	PrintBasisTable.Load(Documents.SaleAdjustment.PrintBasisTable(Object));
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillCustomerOrder(ThisForm, CurrentRow)
	
	Object = ThisForm.Object;
	
	If Not Object.SaleByOrders Then
		Return;
	EndIf;
	
	OrderDocument = Undefined;
	
	If ThisForm.UseOrdersInTabularSection And Object.Goods.Count() > 0 Then
	
		For Each LineProducts_ In Object.Goods Do
			If Not ValueIsFilled(LineProducts_.SalesOrder) Then
				Continue;
			ElsIf ValueIsFilled(OrderDocument) And LineProducts_.SalesOrder <> OrderDocument Then
				// sale by multiple orders
				OrderDocument = Undefined;
				Break;
			Else
				OrderDocument = LineProducts_.SalesOrder;
			EndIf;
		EndDo
		
	ElsIf ValueIsFilled(Object.DocumentBasis) Then
		FieldOfOrder = "SalesOrder";
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
			FieldOfOrder = "MaterialProviderOrder";
		EndIf;
		OrderDocument = GeneralPurposeTMServerCall.ObjectAttributeValue(Object.DocumentBasis, FieldOfOrder);
	EndIf;
	
	CurrentRow.SalesOrder = OrderDocument;
	
EndProcedure

&AtServer
Procedure SetTitleOfPrintDetails()
	
	If GetFunctionalOption("UseDeedsOfTransfer") Then
		Items.PrintDetails.Title = 
			NStr("vi = 'Chi tiết in / chứng nhận chuyển nhượng quyền';
				|ru = 'Реквизиты печати / Акта на передачу прав';
				|en = 'Print details / Deed of transfer'; fa = 'Print details / Deed of transfer';
				|it = 'Requisiti di stampa / Atto sul trasferimento di diritti';
				|pl = 'Atrybuty wydruku / Protokołu przeniesienia praw';
				|tr = 'Yazdırma öznitelikleri / Transfer hakkı raporu'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	TextsFieldsDocumentsBasedOn.Clear();
	
	UpdateTextOfInvoiceIssued();
	UpdateTextDocumentsBasedOnLocalization();
	
	TMCommonUseClientServer.UpdateTextDocumentsBasedOn(ThisObject);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	If Object.Organization = CurrentCompany Then
		Return;
	EndIf;
	
	CurrentCompany = Object.Organization;
	
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	AdjustTaxBaseOfPreviousPeriod = Not SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Object.Organization, DocumentDate);
	
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.Organization) Then
		
		UpdateTextDocumentsBasedOn();
		
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
		
	EndIf;
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization, Object.CompanyBankAccount, , Object.LineOfBusiness);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	If Object.SaleAdjustment2_5 Then
		SetPropertiesOfElementsAccordingToAccountingPolicy();
		UpdateTrackingReflectionHeader();
	EndIf;


	
EndProcedure

&AtServer
Procedure FillInDefaultEndClientContract()
	
	If SalesViaCommissionAgent Then
		Object.CustomerContract = ConsignmentSalesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.SalesViaCommissionAgent);
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()

	If Object.Counterparty = CurrentCounterparty Then
		Return;
	EndIf;
	
	CurrentCounterparty = Object.Counterparty;
	
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();

	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.ContractGroup.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		SalesServer.PartnerOnChange(Object);
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	UpdateTextDocumentsBasedOn();
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()

	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If Object.Partner = CurPartner Then
		Return;
	EndIf;
	
	CurPartner = Object.Partner;
	
	ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails();
	
	AttributesArray = New Array;
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	AttributesArray.Add("Partner");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SalesServer.PartnerOnChange(Object);
	ResponsiblePersonsServer.FillInManagerSelectionList_(Items.Manager, Object);
	ResponsiblePersonsServer.InstallManager(Object, Object.DocumentBasis);

	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	


	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	If Object.SaleAdjustment2_5 Then
		UpdateOptionsForReflectingDiscrepancies2_5();
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	Warehouse       = Object.Warehouse;
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Object.Warehouse);
	
	If WarehouseGroup_ Then
		Items.ProductsGroupSender.Title      = NStr("vi = 'Người gửi';
													|ru = 'Отправитель';
													|en = 'Sender'; fa = 'فرستنده';
													|it = 'Sender';
													|pl = 'Sender';
													|tr = 'Gönderici'");
		Items.DiscrepanciesGroupSender.Title = NStr("vi = 'Người gửi';
													|ru = 'Отправитель';
													|en = 'Shipper'; fa = 'فرستنده';
													|it = 'Mittente';
													|pl = 'Shipper';
													|tr = 'Gönderen'");
	Else
		Items.ProductsGroupSender.Title      = NStr("vi = 'Bộ phận-người gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Reparto-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen departman'");
		Items.DiscrepanciesGroupSender.Title = NStr("vi = 'Bộ phận gửi';
													|ru = 'Подразделение-отправитель';
													|en = 'Shipping business unit'; fa = 'واحد تجاری ارسال‌کننده';
													|it = 'Reparto-mittente';
													|pl = 'Shipping business unit';
													|tr = 'Gönderen departman'");
	EndIf;
	
	Items.DiscrepanciesFillWarehouseInSelectedLines.Enabled = WarehouseGroup_;
	WarehousesServer.FillInWarehousesInTablePart(Object.Warehouse, WarehouseGroup_, Object.Discrepancies, True);
	
	If Not WarehouseGroup_ Then
		
		UseWarehouseManagemantSystemForGoodsSurplusesShortages =
			UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
		
		For Each TSRow In Object.Discrepancies Do
			
			If UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
				
				If TSRow.PostingOption =
					PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock") Then
					
					TSRow.PostingOption =
						PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount");
					
				ElsIf TSRow.PostingOption =
					PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock") Then
					
					TSRow.PostingOption =
						PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount");
					
				EndIf;
				
			Else
				
				If TSRow.PostingOption =
					PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount") Then
					
					TSRow.PostingOption =
						PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock");
					
				ElsIf TSRow.PostingOption =
					PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount") Then
					
					TSRow.PostingOption =
						PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock");
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	UpdateServiceDetailsOfTableParts();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Discrepancies);
	
	SetParametersForSelectingProductsWarehouse();
	MarkEmptyWarehouse();
	
EndProcedure
&AtServer
Procedure GenerateHeaderAndSetVisibilityOfElementsBasedOnGiverSReport()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or Object.BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		
		If Not ValueIsFilled(Object.Ref) Then
			AutoTitle = False;
			Title = NStr("vi = 'Điều chỉnh bảng kê dành cho bên thuê gia công (tạo mới)';
						|ru = 'Корректировка отчета давальцу (создание)';
						|en = 'Adjust ""Consumption report — Subcontracting services delivered"" (create)'; fa = 'Adjust ""Consumption report — Subcontracting services delivered"" (create)';
						|it = 'Correzione del report al fornitore (creazione)';
						|pl = 'Korekta raportu do właściciela surowców (tworzenie)';
						|tr = 'Tüketim raporu-Verilen fason hizmetlerini düzeltme (oluşturma)'");
		Else
			Title = "";
			AutoTitle = True;
		EndIf;
		
		Items.Partner.Title = NStr("vi = 'Người gia công';
									|ru = 'Давалец';
									|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
									|it = 'Fornitore';
									|pl = 'Material provider';
									|tr = 'Malzeme tedarikçisi'");
		
		SelectionListItemsToDelete = New Array();
		SelectionListItemsToDelete.Add(Enums.BusinessTransactions.SaleOfOverdeliveredGoods);
		SelectionListItemsToDelete.Add(Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
		
		For Each ItemToRemove In SelectionListItemsToDelete Do
			
			SelectListItem = Items.Operation.ChoiceList.FindByValue(ItemToRemove);
			If Not SelectListItem = Undefined Then
				Items.Operation.ChoiceList.Delete(SelectListItem);
			EndIf;
			
		EndDo;
		
		Items.DiscrepanciesSetRecordingOptions.Visible = False;
		Items.TextForOtherExpenses.Visible = False;
		Items.TextForOtherIncome.Visible = False;
		
	EndIf;
	
EndProcedure
&AtClient
Procedure PickUpDocumentToBeCorrected()

	CorrectionDate = Object.Date;
	
	If Not ValueIsFilled(Object.Ref) Then
		CorrectionDate = Undefined;	
	EndIf;	

	ListParameters = New Structure;
	ListParameters.Insert("DocumentBasis", Object.DocumentBasis);
	ListParameters.Insert("CorrectionDate", CorrectionDate);
		
	OpenForm("Document.SaleAdjustment.Form.ChoiceFormOfCorrectedDocument", ListParameters, ThisObject);
	
EndProcedure

&AtServer
Procedure EstablishCostPresentation()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(Object.Discrepancies, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure SetCostPresentationInLine(CurrentRow)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCostDeterminationMethodWithLine", CostDeterminationParameters(ThisObject));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Function CostDeterminationParameters(Form)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("VATTaxation", Form.Object.VATTaxation);
	ParametersStructure.Insert("ManagementAccountingCurrency", Form.ManagementAccountingCurrency);
	ParametersStructure.Insert("LocalAccountingCurrency", Form.LocalAccountingCurrency);
	ParametersStructure.Insert("UseLocal",  Form.UseLocal);
	
	Return ParametersStructure
	
EndFunction

&AtServerNoContext
Function UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse, OnDate)
	Return WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse, OnDate);
EndFunction

&AtServer
Procedure EstablishRelationshipOfSelectionParametersForUnitsOfMeasurement()
	
	NewArray = New Array();
	
	If Not OtherAssetServiceAdjustment Then
		NewLink = New ChoiceParameterLink("Products",	"Items.Goods.CurrentData.Products");
		NewArray.Add(NewLink);	
	EndIf;
	
	Items.GoodsPackage.ChoiceParameterLinks = New FixedArray(NewArray);
	
EndProcedure

&AtServer
Procedure AddSBPPaymentStatusUpdateCommand()

	CommandParameters = CashServerLocalization.NewParametersOfSBPPaymentStatusUpdateCommand();
	CommandParameters.Parent = Items.PaymentGroup_2;
	CashServerLocalization.AddSBPPaymentStatusUpdateCommand(ThisObject, CommandParameters);

EndProcedure

#EndRegion

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	ParametersForRegisteringIssuedSF = Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(Object);
	ParametersForRegisteringReceivedSF = Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(Object);
	InvoiceBasedOn = VATAccountingERP.InvoicesGeneralOnBasisOf(ParametersForRegisteringIssuedSF, ParametersForRegisteringReceivedSF);
	
	TextDocumentsBasedOnFooter = SalesServer.CreatePresentationOfInvoiceGenerationCommandsBasedOn(Object.Ref, InvoiceBasedOn);
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, TextDocumentsBasedOnFooter);
	
	TextsFieldsDocumentsBasedOn.Add(TextDocumentsBasedOnFooter);

EndProcedure

#Region ControlOfInconsistentChanges

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Operation" Then
		OperationOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "GoodsProducts" Then
		GoodsProductsOnChange(Item);
	ElsIf Item.Name = "GoodsCharacteristic" Then
		GoodsCharacteristicOnChange(Item);
	ElsIf Item.Name = "GoodsSeries" Then
		GoodsSeriesOnChange(Item);
	ElsIf Item.Name = "GoodsNumberOfPackages" Then
		GoodsNumberOfPackagesOnChange(Item);
	ElsIf Item.Name = "GoodsPackage" Then
		GoodsPackageOnChange(Item);
	ElsIf Item.Name = "GoodsCount" Then
		GoodsCountOnChange(Item);
	ElsIf Item.Name = "GoodsPriceKind" Then
		GoodsPriceKindOnChange(Item);
	ElsIf Item.Name = "GoodsPrice" Then
		GoodsPriceOnChange(Item);
	ElsIf Item.Name = "GoodsSum" Then
		GoodsSumOnChange(Item);
	ElsIf Item.Name = "GoodsVATAmount" Then
		GoodsVATAmountOnChange(Item);
	ElsIf Item.Name = "GoodsVATRate" Then
		GoodsVATRateOnChange(Item);
	ElsIf Item.Name = "GoodsWarehouse" Then
		GoodsWarehouseOnChange(Item);
	ElsIf Item.Name = "GoodsToExpenseAs" Then
		GoodsToExpenseAsOnChange(Item);
	ElsIf Item.Name = "GoodsExpenseItem" Then
		GoodsExpenseItemOnChange(Item);
	ElsIf Item.Name = "DiscrepanciesWarehouse" Then
		DiscrepanciesWarehouseOnChange(Item);
	ElsIf Item.Name = "DiscrepanciesSeries" Then
		DiscrepanciesSeriesOnChange(Item);
	ElsIf Item.Name = Items.SubjectToExcise.Name Then
		SubjectToExciseOnChange(Item);
	ElsIf Item.Name = Items.ARAPAdjustmentVATRate.Name Then
		ARAPAdjustmentVATRateOnChange(Item);
	ElsIf Item.Name = Items.ARAPAdjustmentAdjustmentSum.Name Then
		ARAPAdjustmentAdjustmentSumOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "FillInBySourceData" Then
		FillInBySourceData(Command);
	ElsIf Command.Name = "OpenSelection" Then
		OpenSelection(Command);
	ElsIf Command.Name = "SelectGoodsFromOrder" Then
		SelectGoodsFromOrder(Command);
	ElsIf Command.Name = "GoodsSplitRow" Then
		GoodsSplitRow(Command);
	ElsIf Command.Name = "InsertRows" Then
		InsertRows(Command);
	ElsIf Command.Name = "FillInByReceivingNote" Then
		FillInByReceivingNote(Command);
	ElsIf Command.Name = "FillInVATRate" Then
		FillInVATRate(Command);
	ElsIf Command.Name = "SetComposition" Then
		SetComposition(Command);
	ElsIf Command.Name = "FillThePricesByTermsOfSales" Then
		FillThePricesByTermsOfSales(Command);
	ElsIf Command.Name = "FillInPricesOfSelectedRowsByPriceType" Then
		FillInPricesOfSelectedRowsByPriceType(Command);
	ElsIf Command.Name = "FillInTheWarehouseInSelectedLines" Then
		FillInTheWarehouseInSelectedLines(Command);
	ElsIf Command.Name = "ToSetTheOptionsForAddressingGoods" Then
		ToSetTheOptionsForAddressingGoods(Command);
	ElsIf Command.Name = "DiscrepanciesSplitString" Then
		DiscrepanciesSplitString(Command);
	ElsIf Command.Name = "FillInTheDiscrepancies" Then
		FillInTheDiscrepancies(Command);
	ElsIf Command.Name = "ToSetTheOptionsForAddressingTheDiscrepancy" Then
		ToSetTheOptionsForAddressingTheDiscrepancy(Command);
	ElsIf Command.Name = "DiscrepanciesFillWarehouseInSelectedLines" Then
		DiscrepanciesFillWarehouseInSelectedLines(Command);
	ElsIf Command.Name = "PickUpDocuments" Then
		PickUpDocuments(Command);
	ElsIf Command.Name = "CalculateAmountOfAdjustmentByPercentage" Then
		CalculateAmountOfAdjustmentByPercentage(Command);
	ElsIf Command.Name = "DistributeTotalAmountOfAdjustment" Then
		DistributeTotalAmountOfAdjustment(Command);
	ElsIf Command.Name = "FillInReasonForDebtAdjustment" Then
		FillInReasonForDebtAdjustment(Command);
	ElsIf Command.Name = "EditDocumentBeingCorrected" Then
		EditDocumentBeingCorrected(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Command);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	If Item.Name = "Discrepancies" Then
		DiscrepanciesBeforeRowChange(Item, Cancel);
	ElsIf Item.Name = "Goods" Then
		GoodsBeforeRowChange(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	If Item.Name = "Goods" Then
		GoodsBeforeDeleteRow(Item, Cancel);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Item.Name = "Goods" Then
		GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter);
	ElsIf Item.Name = "ARAPAdjustment" Then
		ARAPAdjustmentBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
EndProcedure

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreAdjustingEntries;
	
	PropsCanBeChanged = False;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription(
			"QuestionResultCompletion", ThisObject, AdditionalParameters);
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	ClearMessages();
	
	CheckForAdjustments(Object.Ref, Object.DocumentBasis, ThereAreAdjustingEntries);
	CorrectionAfterDocumentDate = CheckForCorrectionsAfterDocumentDate(Object.Ref);
	
	If ThereAreAdjustingEntries Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzeltme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh giao hàng.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка реализации.
				|Изменение исходного документа запрещено.';
				|en = 'Sales adjustment is generated from base document.
				|Editing the original document is not allowed.'; fa = 'Sales adjustment is generated from base document.
				|Editing the original document is not allowed.';
				|it = 'In base al documento è stata inserita una rettifica di realizzo.
				|La modifica del documento originale non è consentita.';
				|pl = 'Na podstawie dokumentu wprowadzono korektę sprzedaży.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Temel belgeye bir satış düzeltmesi  girilmiştir.
				|Orijinal belge değiştirilemez.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	ElsIf ValueIsFilled(CorrectionAfterDocumentDate) Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzeltme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Nếu chỉnh sửa muộn hơn ngày của chứng từ hiện tại.
				|Đã cấm thay đổi chứng từ.';
				|ru = 'Есть исправление позднее даты текущего документа.
				|Изменение документа запрещено.';
				|en = 'There is a correction later than the current document date.
				|Cannot edit the document.'; fa = 'There is a correction later than the current document date.
				|Cannot edit the document.';
				|it = 'Есть исправление позднее даты текущего документа.
				|Изменение документа запрещено.';
				|pl = 'There is a correction later than the current document date.
				|Cannot edit the document.';
				|tr = 'Mevcut belgenin tarihinden daha sonra düzeltme mevcut.
				|Belgenin değiştirilmesi yasaktır.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	Else
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingStatus() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisForm, Item);
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisForm, Item);
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
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
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
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
	
	If Not PerformChecksBeforeChangingStatus() Then
		Cancel = True;
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group, Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisForm);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	If TypeOf(Object.DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	Else
		FilterParameters = Undefined;
	EndIf;
	
	Columns = "Products,Characteristic,Content,Package,NumberOfPackages,Count,PriceKind,Price,Warehouse,
		|Department,ProductsInSet,ItemVariantOfSet";

	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);

	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
	ParametersFillInVATRate.Date = ReferenceDocumentDateForCertificate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	StructureOfActions.Insert("FillInHSCode", Object.VATTaxation);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", ToReturnReusablePackage);
	StructureOfActions.Insert("CheckFillWarehouse",
		BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(Object, WarehouseGroup_));
	StructureOfActions.Insert("FillInOptionToReflectImplementationAdjustment", Object.AdjustmentKind);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
		Object.Currency,
		LocalAccountingCurrency,
		ManagementAccountingCurrency);
	
	StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
	
	If NumberOfPackagesIsUsed Then
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	Else
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
		
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	DataToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
		
		DataToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		DataToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	SetsServer.FillInServiceDetails(ThisObject, "Goods");
	
	WarehouseData_2 = GetDataOnWarehouses();
	For Each TSRow In Object.Goods Do
		WarehouseData_1 = WarehouseData_2.Find(TSRow.Warehouse);
		If WarehouseData_1 <> Undefined Then
			TSRow.UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehouseData_1.UseWarehouseManagemantSystemForGoodsSurplusesShortages;
		EndIf;
	EndDo;
	
	WhenChangingWarehouseInTablePartServer();
	DiscrepanciesAreRelevant = False;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.Goods);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure SeriesOnChange(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value						= CurrentData.Series;
	ValueSelected.CurrentRowID	= CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters[TSName], ValueSelected);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "")
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters[TSName], Text) Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần gọi ra Server.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		
		Raise ExceptionText;
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

&AtClient
Procedure BeforeRecordingQuestionCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		
		CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
		CheckParameters.CheckForPromiscuity = False;
		Notification = New CallbackDescription("BeforeRecordingCheckPossibilityOfFillingInTablePart",
			ThisObject, AdditionalParameters);
		ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRecordingCheckPossibilityOfFillingInTablePart(Result, AdditionalParameters) Export
	
	If Result Then
		FillInTheDiscrepanciesServer();
		ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.DiscrepancyGroup;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	ClearMessages();
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		DiscrepanciesAreRelevant = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionResultCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then
		OpenForm("Document.SaleAdjustment.ObjectForm", New Structure("Basis", Object.DocumentBasis));
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInBySourceDataCompletion(Result, AdditionalParameters) Export 
	
	FillInBySourceDataServer();
	CalculateFinalImplementationIndicators(ThisForm);
	
EndProcedure

&AtClient
Procedure BreakTSString(TSName)
	
	FormTable	= Items[TSName];
	TableData	= Object[TSName];
	
	If TSName = Items.Discrepancies.Name Then
		CurrentData = Items[TSName].CurrentData;
		
		If CurrentData <> Undefined Then
			AcceptableOptions = New Array;
			
			If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods") Then
				AcceptableOptions.Add(
					PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount"));
				AcceptableOptions.Add(
					PredefinedValue("Enum.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock"));
				AcceptableOptions.Add(
					PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount"));
				AcceptableOptions.Add(
					PredefinedValue("Enum.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock"));
				
				NameOfBasicStatusField	= "BatchesIndicationStatusOfGoodsTransferred";
				FieldNameCorStatus		= "BatchesIndicationStatusInWarehouses";
			Else
				AcceptableOptions.Add(PredefinedValue("Enum.CreditNoteRecordingOptions.ReturnToTransit"));
				
				NameOfBasicStatusField	= "BatchesIndicationStatusInWarehouses";
				FieldNameCorStatus		= "BatchesIndicationStatusOfGoodsTransferred";
			EndIf;
			
			If Not (CurrentData[FieldNameCorStatus] > 0
				And CurrentData[NameOfBasicStatusField] = 0
				And AcceptableOptions.Find(CurrentData.PostingOption) <> Undefined) Then
				
				WarningText = NStr("vi = 'Không thể tách dòng.
					|Thao tác này không hợp lệ đối với các dòng mà trong đó cho phép chỉ định sê-ri.';
					|ru = 'Невозможно разбить строку.
					|Действие допустимо для строк, в которых доступно указание серии.';
					|en = 'Cannot split the line.
					|You can only do it for lines where batches can be specified.'; fa = 'Cannot split the line.
					|You can only do it for lines where batches can be specified.';
					|it = 'Cannot split the line.
					|You can only do it for lines where batches can be specified.';
					|pl = 'Cannot split the line.
					|You can only do it for lines where batches can be specified.';
					|tr = 'Satır bölünememektedir.
					|Bu işlem, parti numarasının belirtilebildiği satırlar için geçerlidir.'");
				
				ShowMessageBox(, WarningText);
				
				Return;
				
			EndIf;
		EndIf;
		
	EndIf;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = ?(Not NumberOfPackagesIsUsed,"Count","NumberOfPackages");
	
	If TSName = Items.Discrepancies.Name Then
		StringSplittingParameters.AllowZeroCount = False;
	EndIf;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, TSName);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, TSName) Export
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = Items.Goods.Name Then
		
		DiscrepanciesAreRelevant = False;
		
		ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS(
			Object.Currency,
			LocalAccountingCurrency,
			ManagementAccountingCurrency);
		
		StructureOfActions.Insert("SetVATAmountLocalMans", ParametersForFillingInVATAmountLocalManSManSManSManSManSManSManSManS);
		
		If NumberOfPackagesIsUsed Then
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		Else
			AddActionsToStructureWhenQuantityChanges(StructureOfActions, Object);
		EndIf;
		
		WhenChangingWarehouseInTablePartServer();
		
	Else
		
		If NumberOfPackagesIsUsed Then
			StructureOfActions.Insert("RecalculateNumberOfUnits");
		Else
			StructureOfActions.Insert("RecalculateNumberOfPackages");
		EndIf;
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	If TSName = Items.Discrepancies.Name Then
		InitialQuantity_ = CurrentRow.NumberOfPackages + NewRow.NumberOfPackages;
		
		If InitialQuantity_ <> 0 Then
			
			AttributesNames	= "Sum, VATAmount, AmountIncludingVAT";
			FieldsCollection	= New Structure(AttributesNames);
			
			For Each KeyAndValue In FieldsCollection Do
				
				CurrentRow[KeyAndValue.Key] =
					CurrentRow.NumberOfPackages
						* CurrentRow[KeyAndValue.Key]
						/ InitialQuantity_;
				
				NewRow[KeyAndValue.Key] = NewRow[KeyAndValue.Key] - CurrentRow[KeyAndValue.Key];
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheDiscrepanciesCompletion(Result, AdditionalParameters) Export 
	
	FillInTheDiscrepanciesServer();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	CalculateFinalImplementationIndicators(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInByReceivingNoteCompletion(Result, AdditionalParameters) Export 
	
	FillInByReceivingNoteServer();
	
EndProcedure

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)

	Query = New Query(
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)");

	Query.SetParameter("GroupOfWarehouses", Warehouse);
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	Return WarehouseArray;

EndFunction

&AtServer
Procedure SetParametersForSelectingProductsWarehouse()
	
	Items.GoodsWarehouse.ChoiceParameters = New FixedArray(New Array);
	Items.DiscrepanciesWarehouse.ChoiceParameters = New FixedArray(New Array);
	
	WarehouseSelectionData = WarehouseSelectionData(Object.Warehouse);
	
	TMCommonUseClientServer.AddSelectionParameter(Items.GoodsWarehouse, "Ref", WarehouseSelectionData);
	TMCommonUseClientServer.AddSelectionParameter(Items.DiscrepanciesWarehouse, "Ref", WarehouseSelectionData);
	
EndProcedure

&AtServer
Procedure SetItemSelectionParameters()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		Items.GoodsProducts.ChoiceParameters = New FixedArray(New Array);
		Items.DiscrepanciesProducts.ChoiceParameters = New FixedArray(New Array);
		
		AllowedItemTypes = New Array;
		AllowedItemTypes.Add(Enums.ItemsTypes.OwnGoods);
		
		TMCommonUseClientServer.AddSelectionParameter(
			Items.GoodsProducts,
			"Filter.ItemsType",
			AllowedItemTypes);
		
		TMCommonUseClientServer.AddSelectionParameter(
			Items.DiscrepanciesProducts,
			"Filter.ItemsType",
			AllowedItemTypes);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure MarkEmptyWarehouse()
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then
		Return;
	EndIf;
	
	AutoMarkingOfEmptyWarehouse = False;
	ReflectionsOptionsWithMandatoryWarehouse = Documents.SaleAdjustment.ReflectionsOptionsWithMandatoryWarehouse();
	
	If Object.AdjustmentKind =
			PredefinedValue("Enum.BusinessTransactions.SaleOfOverdeliveredGoods")
			Or Object.AdjustmentKind =
				PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods") Then
		
		ReflectionOptions = Object.Goods.Unload(, "PostingOption");
		ReflectionOptions.GroupBy("PostingOption");
		
		For Each TableRow In ReflectionOptions Do
			
			If ReflectionsOptionsWithMandatoryWarehouse.FindByValue(TableRow.PostingOption) <>
				Undefined Then
				AutoMarkingOfEmptyWarehouse = True;
				Break;
			EndIf;
			
		EndDo;
		
	Else
		
		ReflectionOptions = Object.Discrepancies.Unload(, "PostingOption");
		ReflectionOptions.GroupBy("PostingOption");
		
		For Each TableRow In ReflectionOptions Do
			
			If ReflectionsOptionsWithMandatoryWarehouse.FindByValue(TableRow.PostingOption) <>
				Undefined Then
				AutoMarkingOfEmptyWarehouse = True;
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.Warehouse.AutoMarkIncomplete = AutoMarkingOfEmptyWarehouse;
	If Not ValueIsFilled(Object.Warehouse) Then
		Items.Warehouse.MarkIncomplete = AutoMarkingOfEmptyWarehouse;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBusinessTransactionOfFoundationDocument()
	
	Operation = Documents.SaleAdjustment.EconomicOperationOfFoundationDocument(Object.DocumentBasis);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Function InvoiceRegistrationParameters()
	
	Result = New Structure;
	Result.Insert("Issued", Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(Object)); 	
	Result.Insert("Received", Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(Object)); 	
	
	Return Result;
EndFunction

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	AddSBPPaymentStatusUpdateCommand();
	
EndProcedure

&AtClient
Function CorrectedDocument()
	
	CorrectedDocument = Undefined;
	
	If ValueIsFilled(Object.CorrectedDocument) Then
		CorrectedDocument = Object.CorrectedDocument;
	ElsIf Object.Posted Then
		CorrectedDocument = DocumentCorrectionServerCall.CorrectedDocument(Object.Ref);
	Else
		CorrectedDocument = Object.DocumentBasis;			
	EndIf;	
	
	Return CorrectedDocument;
	
EndFunction

&AtServer
Procedure UpdatePresentationElementsOfDocumentBeingCorrected()
	
	PresentationOfCorrectedDocument = DocumentCorrection.PresentationOfCorrectedDocument(Object.CorrectedDocument);	
		
	If Not ValueIsFilled(PresentationOfCorrectedDocument) Then
		PresentationOfCorrectedDocument = NStr("vi = 'Hãy chọn chứng từ được chỉnh sửa';
												|ru = 'Выберите исправляемый документ';
												|en = 'Select the document to correct'; fa = 'Select the document to correct';
												|it = 'Выберите исправляемый документ';
												|pl = 'Select the document to correct';
												|tr = 'Düzeltme belgesini seçin'");	
	EndIf;	
	
	CustomizeElementsOfDocumentBeingCorrected();
		
EndProcedure

&AtServer
Procedure CustomizeElementsOfDocumentBeingCorrected()
	
	DocumentBeingCorrectedIsDisplayed = Items.GroupDocumentBeingCorrected.Visible;
	
	If Not DocumentBeingCorrectedIsDisplayed Then
		Return;	
	EndIf;	
		
	DocumentBeingCorrectedHasBeenFilledIn = ValueIsFilled(Object.CorrectedDocument);
	WidthOfDocumentBeingCorrectedElement = 0;
	TextColorChangeDocumentBeingCorrected = New Color;

	If DocumentBeingCorrectedHasBeenFilledIn Then
		WidthOfDocumentBeingCorrectedElement = 15;			
	Else
		WidthOfDocumentBeingCorrectedElement = 22;			
		TextColorChangeDocumentBeingCorrected = StyleColors.SpecialTextColor;
	EndIf;

	TMCommonUseClientServer.SetFormItemProperty(Items, "PresentationOfCorrectedDocument", 
		"Width", WidthOfDocumentBeingCorrectedElement);	
	TMCommonUseClientServer.SetFormItemProperty(Items, "PresentationOfCorrectedDocument", 
		"TextColor", TextColorChangeDocumentBeingCorrected);
	TMCommonUseClientServer.SetFormItemProperty(Items, "EditDocumentBeingCorrected", 
		"Visible", DocumentBeingCorrectedHasBeenFilledIn);
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfDocumentBeingCorrected(Val ValueSelected)
	
	If ValueIsFilled(ValueSelected) Then
		Modified = True;
		Object.CorrectedDocument = ValueSelected;
	EndIf;
	
	UpdatePresentationElementsOfDocumentBeingCorrected();
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfGroupOfOtherIncomeExpenses()
	
	Items.OtherIncomeExpensesGroup.Visible =
		Object.AdjustmentKind <> Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated
		And Object.AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		And Not Object.SaleAdjustment2_5;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByAdjustingImplementation2_5()
	
	Items.TransferDocumentToNewOrderOfReflectionInAccounting.Visible = Not Object.SaleAdjustment2_5;
	Items.ReflectionInAccounting_.Visible = Object.SaleAdjustment2_5;
	
	Items.DiscrepanciesPostingOption.Visible = Not Object.SaleAdjustment2_5;
	Items.DiscrepanciesSetRecordingOptions.Visible = Not Object.SaleAdjustment2_5;
	
	Items.DiscrepanciesReturnValue_.Visible =
		Object.SaleAdjustment2_5
		And UseShipmentWithDeferredTransferOfTitle2_5
		And Not SalesViaCommissionAgent
		And (Object.BusinessOperation =
			PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
			Or Object.BusinessOperation =
				PredefinedValue("Enum.BusinessTransactions.TransferOfTitleToGoods"));
	
EndProcedure

&AtServer
Procedure SetPropertiesOfElementsAccordingToAccountingPolicy()

	Items.RecordInProfitLossOfPreviousYears.Enabled = LastPeriodAdjustment;
	
EndProcedure

&AtServer
Procedure UpdateOptionsForReflectingDiscrepancies2_5()
	
	ThereIsContract = ValueIsFilled(Object.Contract);
	ThisIsAdjustmentOfReportToGiver = Object.BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5;
	ItemTypesWithoutTakingIntoAccountOrderScheme = New Array;
	ItemTypesWithoutTakingIntoAccountOrderScheme.Add(Enums.ItemsTypes.OperationService);
	ItemTypesWithoutTakingIntoAccountOrderScheme.Add(Enums.ItemsTypes.Work_5);
	
	For Each LineOfDiscrepancies In Object.Discrepancies Do
		
		If ThereIsContract
			And LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ReturnToTransit Then
			LineOfDiscrepancies.ReturnValue_ = True;
		Else
			If LineOfDiscrepancies.Count > 0 Then
				If ItemTypesWithoutTakingIntoAccountOrderScheme.Find(LineOfDiscrepancies.ItemsType) <> Undefined
					Or ThisIsAdjustmentOfReportToGiver
					Or False Then
					LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSale;
				Else
					If LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
						LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount;
					Else
						LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock;
					EndIf;
				EndIf;
			ElsIf LineOfDiscrepancies.Count < 0 Then
				If ItemTypesWithoutTakingIntoAccountOrderScheme.Find(LineOfDiscrepancies.ItemsType) <> Undefined
					Or ThisIsAdjustmentOfReportToGiver
					Or False Then
					LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSale;
				Else
					If LineOfDiscrepancies.UseWarehouseManagemantSystemForGoodsSurplusesShortages Then
						LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount;
					Else
						LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock;
					EndIf;
				EndIf;
			EndIf;
			LineOfDiscrepancies.ReturnValue_ = False;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateAttributesOfAccountingDocument()
	
	If OrderOfReflection = "Revenue" And Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = False;
	ElsIf OrderOfReflection = "OtherIncome" And Not Object.RecordInProfitLossOfPreviousYears Then
		Object.RecordInProfitLossOfPreviousYears = True;
	EndIf;
	
	
EndProcedure

&AtServer
Procedure UpdateReflectionInAccountingByDocumentAttributes()
	
	If Object.RecordInProfitLossOfPreviousYears Then
		OrderOfReflection = "OtherIncome";
	Else
		OrderOfReflection = "Revenue";
	EndIf;
	
	
EndProcedure

&AtServer
Procedure UpdateTrackingReflectionHeader()
	
	TitleReflectionInAccounting = NStr("ru = 'Отражение в учете: %1%2';
										|vi = 'Accounting attributes: %1%2';
										|en = 'Accounting attributes: %1%2'; fa = 'Accounting attributes: %1%2';
										|it = 'Accounting attributes: %1%2';
										|pl = 'Accounting attributes: %1%2';
										|tr = 'Muhasebeye yansıtma: %1%2'");
	
	If Object.RecordInProfitLossOfPreviousYears Then
		ReflectionOfAC = NStr("ru = 'БУ - прочие доходы';
								|vi = 'LA - other income';
								|en = 'LA - other income'; fa = 'LA - other income';
								|it = 'LA - other income';
								|pl = 'LA - other income';
								|tr = 'Genel Muhasebe - diğer gelirler'");
	Else
		ReflectionOfAC = NStr("ru = 'БУ - выручка';
								|vi = 'LA - revenue';
								|en = 'LA - revenue'; fa = 'LA - revenue';
								|it = 'LA - revenue';
								|pl = 'LA - revenue';
								|tr = 'Genel Muhasebe - gelir'");
	EndIf;
	
	ReflectionTA = "";
	
	
	Items.ReflectionInAccounting_.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TitleReflectionInAccounting,
		ReflectionOfAC,
		ReflectionTA);
	
EndProcedure

#Region ARAPAdjustment

&AtServer
Procedure AddImplementationDocumentToDebtAdjustmentTable(DocumentSalesOfGoodsAndServices)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentAmountsInAccountingCurrency.Recorder AS DocumentSalesOfGoodsAndServices,
	|	DocumentAmountsInAccountingCurrency.VATRate AS VATRate,
	|	DocumentAmountsInAccountingCurrency.ARAPObject AS ARAPObject,
	|	SUM(DocumentAmountsInAccountingCurrency.VATAmount) AS VATAmount,
	|	SUM(DocumentAmountsInAccountingCurrency.AmountExcludingVAT + DocumentAmountsInAccountingCurrency.VATAmount) AS AmountIncludingVAT
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	|	DocumentAmountsInAccountingCurrency.Recorder IN (&Recorder)
	|	AND DocumentAmountsInAccountingCurrency.PaymentType_ = &PaymentType_
	|GROUP BY
	|	DocumentAmountsInAccountingCurrency.Recorder,
	|	DocumentAmountsInAccountingCurrency.VATRate,
	|	DocumentAmountsInAccountingCurrency.ARAPObject
	|";
	Query.SetParameter("Recorder", DocumentSalesOfGoodsAndServices);
	Query.SetParameter("PaymentType_", Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	While Selection.Next() Do
		
		Filter = New Structure();
		Filter.Insert("DocumentSalesOfGoodsAndServices", Selection.DocumentSalesOfGoodsAndServices);
		Filter.Insert("ARAPObject", Selection.ARAPObject);
		Filter.Insert("VATRate", Selection.VATRate);
		
		SearchResult = Object.ARAPAdjustment.FindRows(Filter);
		If SearchResult.Count() > 0 Then
			TableRow = SearchResult[0];
			FillPropertyValues(TableRow, Selection);
		Else
			NewRow = Object.ARAPAdjustment.Add();
			FillPropertyValues(NewRow, Selection);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure InputReasonsForDebtAdjustmentCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	For Each SelectedRow In Items.ARAPAdjustment.SelectedRows Do
		CurrentRow = Object.ARAPAdjustment.FindByID(SelectedRow);
		CurrentRow.ReasonForAdjustment = Result;
	EndDo;
	
EndProcedure

&AtClient
Procedure EnteringAdjustmentAmountCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ArrayOfCoefficients = New Array;
	For Each CurrentRow In Object.ARAPAdjustment Do
		ArrayOfCoefficients.Add(CurrentRow.AmountIncludingVAT);
	EndDo;
	
	AllocationResult = CommonClientServer.DistributeAmountInProportionToCoefficients(Result, ArrayOfCoefficients);
	IndexOf = 0;
	For Each CurrentRow In Object.ARAPAdjustment Do
		CurrentRow.AdjustmentSum = AllocationResult[IndexOf];
		CurrentRow.SumOfVATAdjustments =
			PriceManagementSystemClientServer.CalculateVATAmount(
				CurrentRow.AdjustmentSum, 
				CurrentRow.VATRate,
				True,
				Object.VATTaxation);
		CurrentRow.AmountARAP = 0;
		IndexOf = IndexOf + 1; 
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtClient
Procedure EnteringPercentageAdjustmentsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each RowID In Items.ARAPAdjustment.SelectedRows Do
		
		CurrentRow = Object.ARAPAdjustment.FindByID(RowID);
		CurrentRow.AdjustmentSum = CurrentRow.AmountIncludingVAT * Result / 100;
		CurrentRow.SumOfVATAdjustments =
			PriceManagementSystemClientServer.CalculateVATAmount(
				CurrentRow.AdjustmentSum, 
				CurrentRow.VATRate,
				True,
				Object.VATTaxation);
		CurrentRow.AmountARAP = 0;
	EndDo;
	
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

&AtServer
Procedure ClearTablePartsOfDocumentWhenChangingKeyHeaderDetails()
	
	Object.DocumentBasis = Undefined;
	Object.Goods.Clear();
	Object.Discrepancies.Clear();
	Object.PackageBarcodes.Clear();
	Object.ARAPAdjustment.Clear();
	ConfigureDisplayOfElementsBasedOnResultsOfDiscrepancies();
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure SelectionOfGoodsAndServicesFromOrder()
	
	DetailsOfFoundationDocument = DetailsOfFoundationDocument(Object.DocumentBasis);
	
	ArrayOfStringCodes = New Array;
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.SalesOrder) Then
			ArrayOfStringCodes.Add(New Structure("RowCode,SalesOrder", TSRow.RowCode, TSRow.SalesOrder));
		EndIf;
		
	EndDo;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("DocumentCurrency", Object.Currency);
	PickingParameters.Insert("Document", Object.Ref);
	PickingParameters.Insert("DocumentBasis", Object.DocumentBasis);
	PickingParameters.Insert("Warehouse", Object.Warehouse);
	PickingParameters.Insert("ArrayOfStringCodes", ArrayOfStringCodes);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("SalesOpportunity", Object.SalesOpportunity);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("BusinessOperation", Object.BusinessOperation);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	PickingParameters.Insert("VATTaxation", DetailsOfFoundationDocument.VATTaxation);
	PickingParameters.Insert("PriceIncludesVAT", DetailsOfFoundationDocument.PriceIncludesVAT);
	PickingParameters.Insert("Date", Object.Date);
	
	OpenForm("Document.SaleAdjustment.Form.SelectionOfGoodsFromOrderForm",
		PickingParameters,
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
&AtClient
Procedure OpenServiceSelection()
	
	ArrayOfStringCodes = New Array;
	For Each TSRow In Object.Goods Do
		
		If TSRow.RowCode <> 0 And ValueIsFilled(TSRow.SalesOrder) Then
			ArrayOfStringCodes.Add(New Structure("RowCode, MaterialProviderOrder", TSRow.RowCode, TSRow.SalesOrder));
		EndIf;
		
	EndDo;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("DocumentCurrency",		Object.Currency);
	PickingParameters.Insert("Currency",					Object.Currency);
	PickingParameters.Insert("Ref",					Object.DocumentBasis);
	PickingParameters.Insert("ArrayOfStringCodes",		ArrayOfStringCodes);
	PickingParameters.Insert("Partner",				Object.Partner);
	PickingParameters.Insert("Counterparty",				Object.Counterparty);
	PickingParameters.Insert("Contract",				Object.Contract);
	PickingParameters.Insert("Organization",			Object.Organization);
	PickingParameters.Insert("ARAPCurrency",	Object.ARAPCurrency);
	PickingParameters.Insert("VATTaxation",		Object.VATTaxation);
	PickingParameters.Insert("PriceIncludesVAT",		Object.PriceIncludesVAT);
	PickingParameters.Insert("ARAPObjectSettings",		Object.ARAPObjectSettings);
	PickingParameters.Insert("Date",					Object.Date);
	PickingParameters.Insert("SalesOpportunity",					Object.SalesOpportunity);
	PickingParameters.Insert("Warehouse",					Object.Warehouse);
	PickingParameters.Insert("LineOfBusiness",Object.LineOfBusiness);
	PickingParameters.Insert("VATRate",              VATRate);
	
	OpenForm(
		"Document.ReportToMaterialProvider2_5.Form.FormPickReleasedGoods",
		PickingParameters,
		ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
#EndRegion

#EndRegion

#Region Localization

&AtClient
Procedure NotificationProcessingLocalization(EventName, Parameter, Source)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOnLocalization()
	
	
	Return;
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessingLocalization(FormattedStringURL, StandardProcessing)
	

	Return;
	
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
