
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	SetPresentationOfFoundationDocument();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	If Object.VATAccrual.Count() = 0 Then
		
		Object.VATAccrual.Add();
		
	EndIf;
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure


&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		Notify("DocumentForCalculatingReverseVATHasBeenCreated", New Structure("DocumentBasis", Object.DocumentBasis));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	TypeOfSelectedValue = TypeOf(ValueSelected);
	
	If TypeOfSelectedValue = Type("DocumentRef.VendorInvoice")
		Or TypeOfSelectedValue = Type("DocumentRef.VendorInvoiceServicesAndAssets")
		Or TypeOfSelectedValue = Type("DocumentRef.SubcontractorReport2_5")
		Or TypeOfSelectedValue = Type("DocumentRef.RedemptionOfGoodsFromStorage")
		Or TypeOfSelectedValue = Type("DocumentRef.PurchaseAdjustment") Then
		
		ProcessingDocumentSelectionViaServer(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecryptionSwitchOnChange(Item)
	
	If DecryptionSwitch = 0 Then
		
		If Object.VATAccrual.Count() > 1 Then
			
			MessageText = NStr("vi = 'Không thể chuyển sang chế độ không chia tách nếu trong danh sách Tính thuế GTGT đã nhập nhiều hơn một dòng';
								|ru = 'Переключение в режим без разбиения невозможно, если в списке Начисления НДС введено более одной строки';
								|en = 'Cannot switch to no split mode if more than one line is entered into the list of VAT accruals'; fa = 'Cannot switch to no split mode if more than one line is entered into the list of VAT accruals';
								|it = 'Impossibile passare alla modalità senza la partizione, se nell''elenco di calcolo IVA è stata inserita più di una riga';
								|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli na liście Naliczenia VAT wprowadzono więcej niż jeden wiersz';
								|tr = 'KDV Tahakkukları listesine birden fazla satır girilmişse bölüm olmayan moda geçmek mümkün değildir'");
			CommonClient.MessageToUser(MessageText);
			DecryptionSwitch = 1;
			
			Return;
			
		EndIf;
		
		Items.GroupPages.CurrentPage = Items.PageWithoutSplitting;
		
	Else
		
		Items.GroupPages.CurrentPage = Items.ListPage;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentBasisClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		ShowValue(Undefined, Object.DocumentBasis);
		
	Else
		
		TypesList = New ValueList;
		TypesList.Add(Type("DocumentRef.SubcontractorReport2_5"));
		TypesList.Add(Type("DocumentRef.VendorInvoice"));
		TypesList.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
		TypesList.Add(Type("DocumentRef.RedemptionOfGoodsFromStorage"));
		TypesList.Add(Type("DocumentRef.PurchaseAdjustment"));
		
		CallbackDescription = New CallbackDescription("BaseDocumentPresentationClickCompletion", ThisObject);
		ShowChooseFromList(CallbackDescription, TypesList, Items.PresentationOfDocumentBasis);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClickCompletion(ValueSelected, Var_Parameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	ArrayOfBusinessTransactions = New Array;
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit"));
	ArrayOfBusinessTransactions.Add(PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt"));
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Posted", True);
	StructureFilter.Insert("BusinessOperation", ArrayOfBusinessTransactions);
	StructureFilter.Insert("VATTaxation", PredefinedValue("Enum.VATTaxationTypes.VATReverseCharge"));
	
	If ValueSelected.Value = Type("DocumentRef.VendorInvoice") Then
		ChoiceFormName = "Document.VendorInvoice.ChoiceForm";
	ElsIf ValueSelected.Value = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		ChoiceFormName = "Document.VendorInvoiceServicesAndAssets.ChoiceForm";
	ElsIf ValueSelected.Value = Type("DocumentRef.SubcontractorReport2_5") Then
		ChoiceFormName = "Document.SubcontractorReport2_5.ChoiceForm";
		StructureFilter.Insert("BusinessOperation",PredefinedValue("Enum.BusinessTransactions.ProductionByToller2_5"));
	ElsIf ValueSelected.Value = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		ChoiceFormName = "Document.RedemptionOfGoodsFromStorage.ChoiceForm";
		StructureFilter.BusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.RedemptionOfGoodsFromStorage"));
		StructureFilter.BusinessOperation.Add(PredefinedValue("Enum.BusinessTransactions.DeliveryForPrincipal"));
	ElsIf ValueSelected.Value = Type("DocumentRef.PurchaseAdjustment") Then
		ChoiceFormName = "Document.PurchaseAdjustment.ChoiceForm";
	EndIf;
	
	OpenForm(
		ChoiceFormName,
		New Structure("Filter", StructureFilter),
		ThisForm);
	
EndProcedure

&AtClient
Procedure VATRateOnChange(Item)
	
	RecalculateVATAmount(Object.VATAccrual[0]);
	
EndProcedure

&AtClient
Procedure TaxBaseOnChange(Item)
	
	RecalculateVATAmount(Object.VATAccrual[0]);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVATAccrual

&AtClient
Procedure VATAccrualVATRateOnChange(Item)
	
	RecalculateVATAmount();
	
EndProcedure


&AtClient
Procedure VATAccrualTaxBaseOnChange(Item)
	
	RecalculateVATAmount();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.VATAccrual;
	TableData = Object.VATAccrual;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.Insert("FieldNameQuantity", "TaxBase");
	StringSplittingParameters.Insert("Title", NStr("vi = 'Hãy nhập số tiền cơ sở thuế vào dòng mới';
													|ru = 'Введите сумму налоговой базы в новой строке';
													|en = 'Enter the tax base amount in a new line'; fa = 'Enter the tax base amount in a new line';
													|it = 'Inserire importo della base imponibile nella nuova riga';
													|pl = 'Wprowadź kwotę podstawy podatkowej w nowym wierszu ';
													|tr = 'Vergi matrahı tutarını yeni satıra gir'"));
	StringSplittingParameters.Insert("AllowZeroCount", False);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.VATAccrual.CurrentData;
	
	If NewRow <> Undefined Then
		
		RecalculateVATAmount(CurrentRow);
		RecalculateVATAmount(NewRow);
		
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
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
Procedure SetPresentationOfFoundationDocument()
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		BaseDocumentPresentation = Object.DocumentBasis;
		Items.PresentationOfDocumentBasis.TextColor = StyleColors.HyperlinkColor;
		
	Else
		
		BaseDocumentPresentation = NStr("vi = 'Hãy chọn chứng từ cơ sở';
										|ru = 'Выберите документ-основание';
										|en = 'Select a base document'; fa = 'Select a base document';
										|it = 'Selezionare documento base';
										|pl = 'Wybierz dokument źródłowy';
										|tr = 'Lütfen, temel belge seçin'");
		Items.PresentationOfDocumentBasis.TextColor = StyleColors.SpecialTextColor;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingDocumentSelectionViaServer(ValueSelected)
	
	Modified = True;
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(ValueSelected);
	ValueToFormAttribute(DocumentObject, "Object");
	
	Object.DocumentBasis = ValueSelected;
	SetPresentationOfFoundationDocument();
	
	If Object.VATAccrual.Count() > 1 Then
		
		Items.GroupPages.CurrentPage = Items.ListPage;
		
		
	Else
		
		Items.GroupPages.CurrentPage = Items.PageWithoutSplitting;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecalculateVATAmount(CurrentRow = Undefined)
	
	If CurrentRow = Undefined Then
		
		CurrentRow = Items.VATAccrual.CurrentData;
		
	EndIf;
	
	VATRateByPercentage = VATAccountingERPClientServer.ValueOfVATRate(CurrentRow.VATRate);
	CurrentRow.VATAmount = CurrentRow.TaxBase * (VATRateByPercentage / 100);
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.VATAccrual, StructureOfActions, CachedValues);
	
	For Each TSRow In CachedValues.ProcessedRows Do
		
		VATRateByPercentage = VATAccountingERPClientServer.ValueOfVATRate(TSRow.VATRate);
		TSRow.VATAmount = TSRow.TaxBase * (VATRateByPercentage / 100);
		
	EndDo;
	
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
