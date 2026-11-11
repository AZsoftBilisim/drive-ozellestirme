#Region Variables

&AtClient
Var FormModified; // it is used to work out the form modification change event

&AtClient
Var ResponseBeforeWrite;

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	EmbeddingParameters = Documents.SubcontractOrder2_5.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisForm, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			
			StructureOfActions = New Structure();
			AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
			
			StructureOfActions = New Structure();
			AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
			
		EndIf;
		ProductsServer.FillInStatusesForSpecifyingSeries(
			Object,
			SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		
		If ValueIsFilled(Object.Partner) Then
			FillInDeliveryDetailsOnServer("Partner");
		EndIf;
		
	EndIf;
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisForm, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.DeliveryTimeFrom);
	ElementsToFillIn.Add(Items.DeliveryTimeTo);
	ElementsToFillIn.Add(Items.DeliveryTimeFrom1);
	ElementsToFillIn.Add(Items.DeliveryTimeTo1);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	
	#Region StandardMechanisms
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// The connected equipment
	TMCommonUse.CustomizePeripherals(ThisForm, "ManufacturedProducts,SideAndIntermediateRelease,SupplyWithMaterialsAndWorks");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisForm, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	UnblockOrdersOnServer();
	EmbeddingParameters = Documents.SubcontractOrder2_5.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisForm, EmbeddingParameters);
	
	OnReadCreateAtServer();
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.SubcontractOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisForm, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisForm, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		If Object.DeletionMark Then
			Common.MessageToUser(NStr("vi = 'Không thể kết chuyển chứng từ đã đặt dấu xóa!';
										|ru = 'Помеченный на удаление документ не может быть проведен!';
										|en = 'You cannot post a document marked for deletion.'; fa = 'You cannot post a document marked for deletion.';
										|it = 'Il documento segnato per l''eliminazione non può essere registrato!';
										|pl = 'You cannot post a document marked for deletion.';
										|tr = 'Silinmek üzere işaretlenmiş belge kaydedilemez!'"), Object.Ref,,, Cancel);
			Return;
		EndIf;
		
		OrderData_3 = OrderDataForRecording();
		// redefining the Cur flag of the event, since this is a check before the event.
		OrderData_3.OrderDetailsForProcessor.Posted = True;
		
		If ValueIsFilled(Object.Department) Then
			CheckComplianceOfUnitWithOrders(OrderData_3, Cancel);
		EndIf;
		
		TempTablesManager =
			Documents.ProductionStage2_2.TemporaryObjectDataTables(OrderData_3);
		
		Documents.ProductionStage2_2.CheckObjectFilling(
			OrderData_3,
			TempTablesManager,
			Cancel,
			CheckedAttributes);
		
		// Replace the names of the details
		UserMessages = GetUserMessages(True);
		For Each CurrMessage In UserMessages Do
			
			If Not StrFind(CurrMessage.Field, "SupplyWithMaterialsAndWorks") = 0 Then
				CurrMessage.Text =
					StrReplace(
						CurrMessage.Text,
						NStr("vi = '""Đảm bảo""';
							|ru = '""Обеспечение""';
							|en = '""Supply""'; fa = '""Supply""';
							|it = '""Обеспечение""';
							|pl = '""Supply""';
							|tr = '""Tedarik""'"),
						NStr("vi = '""Nguyên vật liệu và công việc""';
							|ru = '""Материалы и работы""';
							|en = '""Materials and works""'; fa = '""Materials and works""';
							|it = '""Материалы и работы""';
							|pl = '""Materials and works""';
							|tr = '""Malzemeler ve işler""'"));
			EndIf;
			
			If Not StrFind(CurrMessage.Field, "CancellationReason") = 0
				And StrFind(CurrMessage.Field, "Services") = 0 Then
				CurrMessage.Field = StrReplace(CurrMessage.Field, "CancellationReason", "ReasonForCancellationOfProduction");
			EndIf;
			
			If Not StrFind(CurrMessage.Field, "ProductionDate") = 0 Then
				CurrMessage.Field = StrReplace(CurrMessage.Field, "ProductionDate", "DateOfReceipt");
				CurrMessage.Text =
					StrReplace(
						CurrMessage.Text,
						NStr("vi = 'Ngày sản xuất';
							|ru = 'Дата производства';
							|en = 'Production date'; fa = 'تاریخ تولید';
							|it = 'Data di produzione';
							|pl = 'Data produkcji';
							|tr = 'Üretim tarihi'"),
						NStr("vi = 'Ngày tiếp nhận';
							|ru = 'Дата поступления';
							|en = 'Date of receipt'; fa = 'تاریخ دریافت';
							|it = 'Data di ricezione';
							|pl = 'Data wpływu';
							|tr = 'Giriş tarihi'"));
			EndIf;
			
			CurrMessage.Message();
			
		EndDo;
		
		CheckSharesOfCostOfOutputProducts(OrderData_3, Cancel);
		
	EndIf;
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		// We will offer the user to adjust the desired date of receipt
		If ValueIsFilled(Object.RequestedDeliveryDate) Then
			
			MaxAdvanceDate = MaximumAdvancePaymentDate();
			
			If Not ResponseBeforeWrite
				And ValueIsFilled(MaxAdvanceDate)
				And MaxAdvanceDate > Object.RequestedDeliveryDate Then
				
				Cancel = True;
				
				QueryText = NStr("vi = 'Ngày tiếp nhận mong muốn nhỏ hơn ngày của các công đoạn trả trước. Ngày sẽ được điều chỉnh trước %MaxAdvanceDate%';
								|ru = 'Желаемая дата поступления меньше даты этапов предоплаты. Дата будет скорректирована до %MaxAdvanceDate%';
								|en = 'Requested delivery date is less than the prepayment milestone date. The date will be adjusted to %MaxAdvanceDate%'; fa = 'Requested delivery date is less than the prepayment milestone date. The date will be adjusted to %MaxAdvanceDate%';
								|it = 'La data di consegna desiderata è inferiore alla data delle fasi di pagamento anticipato. La data verrà rettificata al %MaxAdvanceDate%';
								|pl = 'Planowana data wpłaty jest mniejsza niż daty etapów przedpłaty. Data będzie skorygowana do %MaxAdvanceDate%';
								|tr = 'İstenen giriş tarihi, ön ödeme aşamalarının tarihinden daha öncedir. Tarih, %MaxAdvanceDate% kadar düzeltilecektir'");
				QueryText = StrReplace(QueryText, "%MaxAdvanceDate%", Format(MaxAdvanceDate,"DLF=DD"));
				
				AdditionalParameters.Insert("MaxAdvanceDate", MaxAdvanceDate);
				
				ShowQueryBox(
					New CallbackDescription("BeforeWriteCompletion", ThisForm, AdditionalParameters),
					QueryText,
					QuestionDialogMode.OKCancel);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		If Not Object.NotShipInInstallments Then
			
			PaymentStepsClient.AskQuestionAboutResettingScheduleONChangesInShippingDate(
				ThisObject,
				New CallbackDescription(
					"BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd", 
					ThisObject, 
					AdditionalParameters),
				Cancel);
			
			If Cancel Then
				Return;
			EndIf;
			
		EndIf;
	
		BeforeWriteAtClientServer();
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisForm, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer()

	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
	
	If Object.OneDateReceipt
			And ValueIsFilled(Object.DateOfReceipt)
		Or Object.ManufacturedProducts.Count() = 0
			And Object.SideAndIntermediateRelease.Count() = 0 Then
			Return;
	EndIf;
	
	If Object.Status = PredefinedValue("Enum.TollingOrderStatuses.ForFulfillment")
		Or Object.Status = PredefinedValue("Enum.TollingOrderStatuses.Closed") Then
			
			If Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
				FillInReceiptDateWithDesiredDateOnServer();
			EndIf;
			
			FillInEmptyDatesOfWorkOnServer();
			
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If CurrentObject.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		CurrentObject.AdditionalProperties.Insert("OrderData_3", OrderDataForRecording());
	EndIf;
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	If WriteParameters.Property("DisablePostWriteProcessingOnServer")
		And WriteParameters.DisablePostWriteProcessingOnServer Then
		Return;
	EndIf;
	
	ReadOrderData();
	UnblockOrdersOnServer();
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisForm);
	
	FillInServiceDetails();
	FillInDependentServiceAttributes(ThisForm);
	FillInDependentServiceDetailsOnServer();
	FillInServiceDetailsOfTableParts();
	UpdateCostGroups();
	UpdateTextDocumentsBasedOn();
	
	CustomizeFormElements();
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		And WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		RoundingParameters = Documents.SubcontractOrder2_5.TSParametersForRounding();
		
		ProductsServer.RoundUpNumberOfUnitItems(
			Object, , RoundingParameters.ManufacturedProducts);
		
		ProductsServer.RoundUpNumberOfUnitItems(
			Object, , RoundingParameters.SideAndIntermediateRelease);
		
		ProductsServer.RoundUpNumberOfUnitItems(
			Object, , RoundingParameters.SupplyWithMaterialsAndWorks);
		
	EndIf;
	RefreshStatusServer();
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesServer.AfterWriteAtServer(ThisForm);
	// End ItemsAndDimensionsSelectionParameters
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm);
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	
	NotificationParameters = New Array;
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		NotificationParameters = ListOfOrders_.UnloadValues();
	EndIf;
	Notify("Write_SubcontractOrder2_5", NotificationParameters, Object.Ref);
	NotifyChanged(Object.Ref);
	
	ProvisionInDocumentsClient.AfterWrite(ThisForm, "Attachable_CheckCompletionOfInventoryAllocationTask");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisForm, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	HideCancelledRowsOutputItems = Settings.Get("HideCancelledRowsOutputItems");
	
	If HideCancelledRowsOutputItems Then
		Items.ManufacturedProducts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProducts.RowFilter = Undefined;
	EndIf;
	
	HideCancelledRowsByProducts = Settings.Get("HideCancelledRowsByProducts");
	
	If HideCancelledRowsByProducts Then
		Items.SideAndIntermediateRelease.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SideAndIntermediateRelease.RowFilter = Undefined;
	EndIf;
	
	HideCancelledLinesSupplyWithMaterialsAndLabor =
		Settings.Get("HideCancelledLinesSupplyWithMaterialsAndLabor");
	
	If HideCancelledLinesSupplyWithMaterialsAndLabor Then
		Items.SupplyWithMaterialsAndWorks.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SupplyWithMaterialsAndWorks.RowFilter = Undefined;
	EndIf;
	
	HideCanceledServiceLines = Settings.Get("HideCanceledServiceLines");
	
	If HideCanceledServiceLines Then
		Items.Services.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.Services.RowFilter = Undefined;
	EndIf;
	
	Items.FinishedProductsHideCanceledLines.Check = HideCancelledRowsOutputItems;
	Items.SideProductsHideCanceledLines.Check = HideCancelledRowsByProducts;
	Items.ProvidingMaterialsAndWorksToHideCancelledRows.Check =
		HideCancelledLinesSupplyWithMaterialsAndLabor;
	Items.ServicesHideCancelledRows.Check = HideCanceledServiceLines;
	
	If Not Object.Ref.IsEmpty()
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Settings.Delete("Object.NotShipInInstallments");
		Settings.Delete("Object.OneDateReceipt");
		Settings.Delete("Object.WorkPerformanceAsOneDay");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ConfigureDependentFormElements(ThisForm, "OneDateReceipt, NotShipInInstallments, WorkPerformanceAsOneDay");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisForm);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisForm);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisForm, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter);
			
			If Items.GroupPages.CurrentPage = Items.ServicesPage Then
				TSName = "Services";
			ElsIf Items.GroupPages.CurrentPage = Items.PageProvidingMaterialsAndWorks Then
				TSName = "SupplyWithMaterialsAndWorks";
			Else
				If TypeOf(CurrentItem) = Type("FormTable")
					And Items.GroupPages.CurrentPage = Items.OutputProductsPage Then
					
					TSName = CurrentItem.Name;
					
				Else
					TSName = "ManufacturedProducts";
				EndIf;
			EndIf;
			
			ProcessBarcodes(BarcodeData_5, TSName);
			
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
		
		ProcessBarcodes(BarcodeData_5, Parameter.TSName);
		
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisObject, EventName, Parameter) Then
		ProcessingAndSettlementsOnServer(EventName, Parameter);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		ConfigureClipboardCommands(ThisObject, True);
	EndIf;
	
	If EventName = "Recording_NotificationOfSpecialTaxRegimes" Then
		
		UpdateTextDocumentsBasedOn();
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable =
			FillInCollateralFromCollateralStateForm(
				ValueSelected.ActionCode,
				ValueSelected.AddressAnalyst,
				ValueSelected.FillParameters);
		
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
	
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		HandlingSelectionSelectionOnClient(ValueSelected, "SupplyWithMaterialsAndWorks");
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectGoodsToPurchaseDocument.Form.Form" Then
		HandlingSelectionSelectionOnClient(ValueSelected, "Services");
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		CancellationResult = AdjustOrderLines(ValueSelected);
		ShowUserNotification(NStr("vi = 'Hủy bỏ các dòng chưa được xử lý';
									|ru = 'Отмена неотработанных строк';
									|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
									|it = 'Annullamento delle righe non elaborate';
									|pl = 'Anulowanie nieprzetworzonych wierzszy';
									|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
		
	ElsIf ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then 
			Return;
		EndIf;
		
		ProcessingInputOfFractionOfCost(CurrentItem, CurrentData, ValueSelected);
		
	EndIf;
	
	FillInDependentServiceDetailsSupply(ThisForm);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisForm, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
	If Not Exit 
		And ValueIsFilled(Object.Ref)
		And NotifyAboutCreationOfCalculationObject Then
		ARAPAccountingClient.FormWhenClosing(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region IsMain

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisForm);
	EndIf;
	// End StandardSubsystems.Properties
	
	ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	StatusChangedOnServer();
	
EndProcedure

&AtClient
Procedure HeaderOrdersTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "#AddOrders" Then
		StandardProcessing = False;
		OpenSelectionOfOrders();
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer(Undefined, True);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	BusinessOperationWhenChangingOnServer();
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ProcessingServicesOnChange(Item)
	
	RecyclingServicesWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure GroupCostsOnChange(Item)
	
	If GroupCostsBeforeChange = Object.GroupCosts Then
		Return;
	EndIf;
	GroupByStagesOfProduction =
		PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
	
	ThereAreRowsInTableParts =
		Object.ManufacturedProducts.Count() > 0
		Or Object.SideAndIntermediateRelease.Count() > 0
		Or Object.SupplyWithMaterialsAndWorks.Count() > 0
		Or Object.Services.Count() > 0;
	
	If ThereAreRowsInTableParts
		And (Object.GroupCosts = GroupByStagesOfProduction
			Or GroupCostsBeforeChange = GroupByStagesOfProduction) Then
		
		QueryText =
			NStr("vi = 'Sản phẩm đầu ra, sản phẩm phụ, nguyên vật liệu và công việc, dịch vụ sẽ bị xóa.
				|Thay đổi gom nhóm chi phí?';
				|ru = 'Выходные изделия, побочные изделия, материалы и работы, услуги будут очищены.
				|Изменить группировку затрат?';
				|en = 'Finished products, by-products, materials and works, services will be cleared.
				|Change the cost grouping?'; fa = 'Finished products, by-products, materials and works, services will be cleared.
				|Change the cost grouping?';
				|it = 'Prodotti in uscita, sottoprodotti, materiali e lavori, servizi saranno cancellati.
				|Modificare raggruppamento spese?';
				|pl = 'Wyroby wyjściowe, wyroby poboczne, materiały i prace, usługi zostaną wyczyszczone.
				|Zmienić grupowanie kosztów?';
				|tr = 'Üretilen nihai ürünler, yan nihai ürünler, malzemeler ve işler, hizmetler temizlenecektir.
				|Maliyet gruplandırması değiştirilsin mi?'");
		
		CallbackDescription = New CallbackDescription("GroupCostsOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.SubcontractOrder2_5.Form.DocumentForm.GroupCostsOnChange");
		
		GroupingCostsForChangesOnServer();
	EndIf;
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ManufacturedProductsWarehouseOnChange(Item)
	ProductWarehouseWhenChangedOnServer();
EndProcedure

&AtClient
Procedure MaterialsWarehouseOnChange(Item)
	StorageOfMaterialsWhenChangingOnServer();
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisForm);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
	
EndProcedure

&AtClient
Procedure DecorationSettlementStateClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	ReportsTMClientOverridable.OpenPaymentCardWithSuppliersReport("PaymentCardWithSuppliersAccordingToDocumentsContext", Object.Ref);
	
EndProcedure

&AtClient
Procedure TextDocumentsBasedOnURLProcessing(Item, Var_URL, StandardProcessing)
	
	ClearMessages();
	StandardProcessing = False;
	DPPSelectionParameters = New Structure();
	DPPSelectionParameters.Insert("Organization", Object.Organization);
	DPPSelectionParameters.Insert("Basis",   Object.Ref);
	DPPSelectionParameters.Insert("Date",        Object.Date);
	
	VATAccountingERPClient.ProcessingOfNavigationLinkDOPP(ThisObject, DPPSelectionParameters, Var_URL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Products_1

&AtClient
Procedure LeaveProductsAtSubcontractorOnChange(Item)
	
	LeaveItemsWithProcessorWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure LeaveItemsWithProcessorWhenChangingOnServer()
	
	If Object.LeaveProductsAtSubcontractor Then
		Object.ManufacturedProductsWarehouse = Undefined;
	EndIf;
	
	ProductWarehouseWhenChangedOnServer();
	
	If QualityControl.UpdateActionParameters(Documents.SubcontractOrder2_5, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "LeaveProductsAtSubcontractor");
	
EndProcedure

&AtClient
Procedure RequestedDeliveryDateStartListChoice(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	MaxAdvanceDate = MaximumAdvancePaymentDate();
	
	If ValueIsFilled(MaxAdvanceDate) Then
		
		PresentationMaxAdvanceDate =
			StrReplace(NStr("vi = '%MaxAdvanceDate%';
							|ru = '%MaxAdvanceDate%';
							|en = '%MaxAdvanceDate%'; fa = '%MaxAdvanceDate%';
							|it = '%MaxAdvanceDate%';
							|pl = '%MaxAdvanceDate%';
							|tr = '%MaxAdvanceDate%'"), "%MaxAdvanceDate%", Format(MaxAdvanceDate,"DLF=DD"));
		
		ChoiceList = New ValueList;
		ChoiceList.Add(MaxAdvanceDate, PresentationMaxAdvanceDate);
		
		ShowChooseFromList(
			New CallbackDescription("RequestedDeliveryDateStartListChoiceCompletion", ThisForm),
			ChoiceList,
			Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RequestedDeliveryDateStartListChoiceCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected <> Undefined Then
		Object.RequestedDeliveryDate = ValueSelected.Value;
		If Object.Status = PredefinedValue("Enum.TollingOrderStatuses.ForFulfillment")
			Or Object.Status = PredefinedValue("Enum.TollingOrderStatuses.Closed") Then
			If Not Object.GroupCosts =
						PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
				FillInReceiptDateWithDesiredDate();
			EndIf;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure OneDateReceiptOnChange(Item)
	If Not BlockOrders() Then
		Object.OneDateReceipt = Not Object.OneDateReceipt;
		Return;
	EndIf;
	FlagOneDateWhenChangingOnServer(
		"ManufacturedProducts,SideAndIntermediateRelease",
		"OneDateReceipt",
		"DateOfReceipt");
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	TotalDateWhenChangedOnServer(
		"ManufacturedProducts,SideAndIntermediateRelease",
		"DateOfReceipt");
	
EndProcedure

#EndRegion

#Region UsedMaterials

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	If Not BlockOrders() Then
		Object.NotShipInInstallments = Not Object.NotShipInInstallments;
		Return;
	EndIf;
	FlagOneDateWhenChangingOnServer("SupplyWithMaterialsAndWorks", "NotShipInInstallments", "DateOfShipment");
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	FillInWHDate("SupplyWithMaterialsAndWorks", Object.DateOfShipment);
EndProcedure

&AtClient
Procedure StateOfSoftwareDynamicStructureClick(Item)
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		FormParameters.OrdersMotionRecorders = ListOfOrders_.UnloadValues();
	EndIf;
	
	FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
	FormParameters.AcceptableSecurityOptions.Delete(PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
	
	FormParameters.StageOfDynamicOrderStructure = True;
		
	FormParameters.ContextOfUse = "TABLE";
	FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();

	OpenForm(
		"DataProcessor.OrderSupplyForecast.Form",
		FormParameters,
		ThisObject,
		UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
	Return; // there is an empty handler in the SC
	
EndProcedure

#EndRegion

#Region Services

&AtClient
Procedure WorkPerformanceAsOneDayOnChange(Item)
	
	FlagOneDateWhenChangingOnServer(
		"Services",
		"WorkPerformanceAsOneDay",
		"ExecutionDate");
	
EndProcedure

&AtClient
Procedure ExecutionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	TotalDateWhenChangedOnServer(
		"Services",
		"ExecutionDate");
	
EndProcedure

#EndRegion

#Region Delivery

&AtClient
Procedure MethodPlaceOfDeliveryCarrierIfChanged(Item)
	
	FillInDeliveryDetailsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddress");
	
EndProcedure

&AtClient
Procedure DeliveryAddressClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddress");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierOnChange(Item)
	
	ProcessAddressChange(Item, "DeliveryAddressOfCarrier");
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.ClearAddressPresentation(
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfDetailsOfDeliveryAddress],
		Object[NamesOfDetailsOfDeliveryAddresses.AttributeNameOfDeliveryAddressFieldValues],
		Object[NamesOfDetailsOfDeliveryAddresses.NameOfAttributeOfDeliveryAddressValue]);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierStartChoice(Item, ChoiceData, StandardProcessing)
	
	NamesOfDetailsOfDeliveryAddresses = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses("DeliveryAddressOfCarrier");
	
	GoodsDeliveryClient.OpenAddressSelectionFormAndProcessResult(
		Item,
		Object,
		NamesOfDetailsOfDeliveryAddresses,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DeliveryAddressOfCarrierChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	GoodsDeliveryClient.DeliveryAddressChoiceProcessing(Items, Object, Item.Name, ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	SpecialTransportationConditionsOnChangeServer();
	
EndProcedure

#EndRegion

#Region More

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure IncomingDocumentNumberTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	ListOfOrdersByNumber = OrdersAccordingToProcessorData(Object.Ref, Object.Counterparty, Text);
	
	If ListOfOrdersByNumber.Count() = 0 Then
		Return;
	EndIf;
		
	ButtonsList = New ValueList;
	If ListOfOrdersByNumber.Count() = 1 Then
		QueryText = NStr("vi = 'Trong cơ sở thông tin đã tồn tại đơn hàng có số như vậy theo dữ liệu của bên nhận gia công. Tiếp tục?';
						|ru = 'В информационной базе уже существует заказ с таким же номером по данным переработчика. Продолжить?';
						|en = 'Order with the same number by subcontractor data already exists in the infobase. Continue?'; fa = 'Order with the same number by subcontractor data already exists in the infobase. Continue?';
						|it = 'Nel database informatico esiste già un ordine con stesso numero in base ai dati del subfornitore. Continuare?';
						|pl = 'W bazie informacyjnej już istnieje zamówienie o takim samym numerze według danych przetwórcy. Kontynuować?';
						|tr = 'Bilgi tabanında, fason üreticiye göre aynı numaraya sahip bir sipariş zaten mevcut. Devam edilsin mi?'");
		ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở đơn hàng';
												|ru = 'Открыть заказ';
												|en = 'Open order'; fa = 'Open order';
												|it = 'Aprire ordine';
												|pl = 'Otwórz zamówienie';
												|tr = 'Siparişi aç'"));
	Else
		QueryText = NStr("vi = 'Trong cơ sở thông tin đã tồn tại các đơn hàng có số như vậy theo dữ liệu của bên nhận gia công. Tiếp tục?';
						|ru = 'В информационной базе уже существуют заказы с таким же номером по данным переработчика. Продолжить?';
						|en = 'Orders with the same number by subcontractor data already exist in the infobase. Continue?'; fa = 'Orders with the same number by subcontractor data already exist in the infobase. Continue?';
						|it = 'Nel database informatico esistono già gli ordini con stesso numero in base ai dati del subfornitore. Continuare?';
						|pl = 'W bazie informacyjnej już istnieją zamówienia o takim samym numerze według danych przetwórcy. Kontynuować?';
						|tr = 'Bilgi tabanında, fason üreticiye göre aynı numaraya sahip siparişler zaten mevcut. Devam edilsin mi?'");
		ButtonsList.Add("OpenOrderList", NStr("vi = 'Mở danh sách đơn hàng';
												|ru = 'Открыть список заказов';
												|en = 'Open order list'; fa = 'باز کردن فهرست سفارش‌ها';
												|it = 'Aprire elenco ordini';
												|pl = 'Otwórz listę zamówień';
												|tr = 'Sipariş listesini aç'"));
	EndIf;
	
	ButtonsList.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Continue';
									|tr = 'Devam et'"));
	
	CallbackDescription =
		New CallbackDescription(
			"IncomingDocumentNumberTextEditEndCompletion",
			ThisForm,
			New Structure("OrderList", ListOfOrdersByNumber));
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If DocumentCurrency = Object.Currency Then
		Return;
	EndIf;
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "SideAndIntermediateRelease")
		Or PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "SupplyWithMaterialsAndWorks")
		Or PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "Services") Then
		
		QueryText = NStr("vi = 'Tính lại số tiền trong chứng từ theo nguyên tệ ""%Currency%""?';
						|ru = 'Пересчитать суммы в документе в валюту ""%Currency%""?';
						|en = 'Convert amounts in the document in %Currency%?'; fa = 'Convert amounts in the document in %Currency%?';
						|it = 'Ricalcolare gli importi del documento in valuta ""%Currency%""?';
						|pl = 'Przeliczyć kwoty w dokumencie na walutę ""%Currency%""?';
						|tr = 'Belgedeki tutarlar ""%Currency%"" para birimine göre yeniden hesaplansın mı?'");
		QueryText = StrReplace(QueryText, "%Currency%", Object.Currency);
		CallbackDescription = New CallbackDescription("QuestionRecalculateAmountsEnd", ThisForm);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		CurrencyOnChangeCompletion(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	PriceIncludesVATWhenChangedOnServer(CachedValues);
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	TaxationOfVATWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If ValueIsFilled(Object.PriceKind)
		And (Object.SideAndIntermediateRelease.Count()
			Or Object.SupplyWithMaterialsAndWorks.Count()) Then
		
		CallbackDescription = New CallbackDescription("PriceKindOnChangeCompletion", ThisForm);
		QueryText = NStr("vi = 'Điền lại đơn giá vào các phần bảng?';
						|ru = 'Перезаполнить цены в табличных частях?';
						|en = 'Refill prices in tables?'; fa = 'Refill prices in tables?';
						|it = 'Ricompilare i prezzi nelle parti tabellari?';
						|pl = 'Wypełnić ponownie ceny w sekcjach tabelarycznych?';
						|tr = 'Tablo bölümlerinde fiyatlar yeniden doldurulsun mu?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	DirectionOfActivityWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ApprovalDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ApprovalDateForChangesOnServer();
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("ManufacturedProducts", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ProcessingSelectionOfSelectionOnServer(ValueSelected, "ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	TableBeforeAdding("ManufacturedProducts", Cancel);
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeRowChange(Item, Cancel)
	TableBeforeStartingChange(Cancel);
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("ManufacturedProducts", NewRow, Copy);
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	TableBeforeDeletion("ManufacturedProducts", Item, Cancel);
	ARAPAccountingClient.SaveShipmentDatesInParameters(ThisObject);
EndProcedure

&AtServer
Procedure OutputItemsBeforeDeletingOnServer()
	
	For Each CurID_ In Items.ManufacturedProducts.SelectedRows Do
		DeleteCostGroup(CurID_);
	EndDo;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnChange(Item)
	TableWhenModified("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	ThereIsChangeInShippingDates = ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject);
	TableAfterDeletion("ManufacturedProducts", ThereIsChangeInShippingDates);
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("ManufacturedProducts", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("ManufacturedProducts", StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("ManufacturedProducts", StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	TableProductsWhenChanged("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	PackingTableWhenChanging("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	TableNumberOfPackagesWhenChanged("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsCanceledOnChange(Item)
	TableUndoneByChange("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsRecipientOnChange(Item)
	TableWarehouseWhenModified("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsDateOfReceiptOnChange(Item)
	TableDateOfReceiptONChange("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsToExpenseAsOnChange(Item)
	TableChargeToExpensesWhenChangesAreMade("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	TableItemOfExpenditureSelection(Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemOnChange(Item)
	TableItemOfExpenditureInCaseOfChange(Item);
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ManufacturedProductsToControlQualityOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSideAndIntermediateRelease

&AtClient
Procedure SideAndIntermediateReleaseChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ProcessingSelectionOfSelectionOnServer(ValueSelected, "SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	TableBeforeAdding("SideAndIntermediateRelease", Cancel);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeRowChange(Item, Cancel)
	TableBeforeStartingChange(Cancel);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("SideAndIntermediateRelease", NewRow, Copy);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnChange(Item)
	TableWhenModified("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeDeleteRow(Item, Cancel)
	TableBeforeDeletion("SideAndIntermediateRelease", Item, Cancel);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseAfterDeleteRow(Item)
	TableAfterDeletion("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("SideAndIntermediateRelease", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("SideAndIntermediateRelease", StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("SideAndIntermediateRelease", StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductsOnChange(Item)
	TableProductsWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePackageOnChange(Item)
	PackingTableWhenChanging("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseNumberOfPackagesOnChange(Item)
	TableNumberOfPackagesWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePriceOnChange(Item)
	TablePriceWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSumOnChange(Item)
	TableAmountWhenChanged("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCanceledOnChange(Item)
	TableUndoneByChange("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseRecipientOnChange(Item)
	TableWarehouseWhenModified("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDateOfReceiptOnChange(Item)
	TableDateOfReceiptONChange("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseToExpenseAsOnChange(Item)
	TableChargeToExpensesWhenChangesAreMade("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	TableItemOfExpenditureSelection(Item, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemOnChange(Item)
	TableItemOfExpenditureInCaseOfChange(Item);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseToControlQualityOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyWithMaterialsAndWorks

&AtClient
Procedure SupplyWithMaterialsAndWorksSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("SupplyWithMaterialsAndWorks", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	TableBeforeAdding("SupplyWithMaterialsAndWorks", Cancel);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeRowChange(Item, Cancel)
	TableBeforeStartingChange(Cancel);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("SupplyWithMaterialsAndWorks", NewRow, Copy);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnChange(Item)
	TableWhenModified("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("SupplyWithMaterialsAndWorks", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	TableBeforeDeletion("SupplyWithMaterialsAndWorks", Item, Cancel);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksAfterDeleteRow(Item)
	TableAfterDeletion("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("SupplyWithMaterialsAndWorks", StandardProcessing);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("SupplyWithMaterialsAndWorks", StandardProcessing);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProductsOnChange(Item)
	TableProductsWhenChanged("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText, Items.SupplyWithMaterialsAndWorks.CurrentData);
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSeriesOnChange(Item)
	
	CurrentData     = Items.SupplyWithMaterialsAndWorks.CurrentData;
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, ValueSelected);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionOnChange(Item)
	
	Var FormParameters;
	If ProvisionInDocumentsClient.OpenWarehouseAndSeriesSelectionForm(ThisObject) Then
		OptionForGettingParameters = ProvisionInDocumentsClientServer.ActionSelectionMode();
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(OptionForGettingParameters); // A call to the server
	EndIf;
	
	ProvisionInDocumentsClient.SupplyOptionOnChange(
		ThisObject,
		FormParameters,
		"ProcessWarehouseAndBatchSelection",
		True,
		"SupplyWithMaterialsAndWorksSupplyOptionOnChangeCompletion");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisForm,
		Items.SupplyWithMaterialsAndWorks.CurrentData,
		ValueSelected);

EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWithAssignmentOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	ProvisionInDocumentsClient.WithAssignmentOnChange(CurrentData);
	
	ProvisionOfMaterialsAndWorksSeparatelyWhenChangingOnServer(CurrentData.GetID(), CachedValues);
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksSeparatelyWhenChangingOnServer(CurrentID, CachedValues)
	
	CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(CurrentID);
	If Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		CostGroupDescription = CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber);
		CurrentData.Purpose =
			?(CurrentData.WithAssignment,
			CostGroupDescription.SupplyAssignment,
			Undefined);
	Else
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInAssignmentInProductionPhase");
		BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	UpdateColumnIsAvailableOnServer();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.WarehouseSelectionMode());
	
	If TypeOf(FormParameters) = Type("Structure") Then
		
		StandardProcessing = False;
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisForm,,,,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisForm, FormParameters));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWarehouseOnChange(Item)
	
	TableWarehouseWhenModified("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksPackageOnChange(Item)
	PackingTableWhenChanging("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksNumberOfPackagesOnChange(Item)
	TableNumberOfPackagesWhenChanged("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProducedOnChange(Item)
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurrentData.BillOfMaterials = Undefined;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInPurposeOfProvisionInProductionPhase",
		CurrentData.ParametersForFillingAssignments);
	
	MethodParameters = New Structure;
	MethodParameters.Insert("ProductionOrder",           CurrentData.OrderDocument);
	MethodParameters.Insert("Department",                 Object.Department);
	MethodParameters.Insert("Ref",                        CurrentData.ReferenceOrder);
	MethodParameters.Insert("SubcontractOrder",            Object.Ref);
	MethodParameters.Insert("SeriesSpecificationParameters",        SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	MethodParameters.Insert("Form",                         ThisForm);
	
	ProductionManagementClientServer.AddToStructureActionsCheckSoftwareInProductionPhase(
		StructureOfActions,
		MethodParameters);
	
	AddCollateralActions(ThisForm, "SupplyWithMaterialsAndWorks", StructureOfActions, "AvailableInOtherLines");
	AddActionsCheckFillSpecification(ThisForm, "SupplyWithMaterialsAndWorks", StructureOfActions, CurrentData);
	AddActionsWhenChangingWarehouse(ThisForm, "SupplyWithMaterialsAndWorks", StructureOfActions, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateColumnIsAvailableOnClient("SupplyWithMaterialsAndWorks", StructureOfActions, CurrentData);
	Return;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBillOfMaterialsOnChange(Item)
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("ProductionOrder",           CurrentData.OrderDocument);
	MethodParameters.Insert("Department",                 Object.Department);
	MethodParameters.Insert("Ref",                        CurrentData.ReferenceOrder);
	MethodParameters.Insert("SubcontractOrder",            Object.Ref);
	MethodParameters.Insert("SeriesSpecificationParameters",        SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	MethodParameters.Insert("Form",                         ThisForm);
	
	ProductionManagementClientServer.AddToStructureActionsCheckSoftwareInProductionPhase(
		StructureOfActions,
		MethodParameters);
	
	AddCollateralActions(ThisForm, "SupplyWithMaterialsAndWorks", StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateColumnIsAvailableOnClient("SupplyWithMaterialsAndWorks", StructureOfActions, CurrentData);
	Return;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksPriceOnChange(Item)
	TablePriceWhenChanged("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSumOnChange(Item)
	TableAmountWhenChanged("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCanceledOnChange(Item)
	TableUndoneByChange("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	TSName = "SupplyWithMaterialsAndWorks";
	
	StructureOfActions = New Structure();
	
	AddCollateralActions(ThisForm, TSName, StructureOfActions, "AvailableInOtherLines");
	
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData);
	
	Return; // there is an empty handler in the SC
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersServices

&AtClient
Procedure ServicesSelection(Item, RowSelected, Field, StandardProcessing)
	TableSelection("Services", Field, StandardProcessing);
EndProcedure

&AtClient
Procedure ServicesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	TableBeforeAdding("Services", Cancel);
EndProcedure

&AtClient
Procedure ServicesOnStartEdit(Item, NewRow, Copy)
	TableAtBeginningOfEditing("Services", NewRow, Copy);
EndProcedure

&AtClient
Procedure ServicesOnChange(Item)
	TableWhenModified("Services");
EndProcedure

&AtClient
Procedure ServicesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	TableBeforeEndOfEditing("Services", Item, NewRow, CancelEdit, Cancel);
EndProcedure

&AtClient
Procedure ServicesExpenseGroupClearing(Item, StandardProcessing)
	TableCostGroupCleaning("Services");
EndProcedure

&AtClient
Procedure ServicesExpenseGroupOpening(Item, StandardProcessing)
	TableCostGroupDiscovery("Services", StandardProcessing);
EndProcedure

&AtClient
Procedure ServicesExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	TableCostGroupStartOfSelection("Services", StandardProcessing);
EndProcedure

&AtClient
Procedure ServicesProductsOnChange(Item)
	TableProductsWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesCharacteristicOnChange(Item)
	TableCharacteristicsWhenChanging("Services");
EndProcedure

&AtClient
Procedure ServicesCountOnChange(Item)
	TableNumberOfPackagesWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	TablePriceWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesVendorPriceKindOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsFillInPrice(ThisForm, "Services", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);	
	
EndProcedure

&AtClient
Procedure ServicesSumOnChange(Item)
	TableAmountWhenChanged("Services");
EndProcedure

&AtClient
Procedure ServicesVATRateOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisForm, "Services", StructureOfActions, "VATAmount, AmountIncludingVAT");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesVATAmountOnChange(Item)
	
	CurrentData = Items.Services.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisForm, "Services", StructureOfActions, "AmountIncludingVAT");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ServicesCanceledOnChange(Item)
	TableUndoneByChange("Services");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyWithMaterialsAndWorks

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	If Object.GroupCosts <> PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		SupplyClient.AddPreviouslyPassedActionToOptionsForSelectingSoftwareOption(Item, CurrentData);
	Else
		
		NewArray = New Array();
		
		// The provision option Reserve as received is not available
		If DynamicStructure <> Undefined And DynamicStructure Then
			ActionsArray = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
			IndexOf = ActionsArray.Find(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
			If IndexOf <> Undefined Then
				ActionsArray.Delete(IndexOf);
			EndIf;
			
			AllowedActions = New FixedArray(ActionsArray);
			NewParameter1 = New ChoiceParameter("AllowedActions", AllowedActions);
			
			NewArray.Add(NewParameter1);
		EndIf;
		
		Item.ChoiceParameters = New FixedArray(NewArray);
		
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCommon

&AtClient
Procedure TableSelection(TSName, Field, StandardProcessing)
	
	CurrentData = Items[TSName].CurrentData;
	
	If TSName = "ManufacturedProducts"
		And (Field = Items[TSName + "CostShare"]
			Or Field = Items[TSName + "CostSharePercentage"]
			Or Field = Items[TSName + "ThereAreErrorsOfFillingInCostShare"])
		And Not CurrentData.Canceled Then
		
		OpenCostShareEntryForm(CurrentData, StandardProcessing);
		
	ElsIf Field = Items.SupplyWithMaterialsAndWorksAvailable
		And Not ReadOnly Then
		
		StandardProcessing = False;
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
			
		If FormParameters <> Undefined Then
			OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisForm);
		EndIf;
	ElsIf Field = Items[TSName + "ExpenseGroup"]
		And Field.ReadOnly Then
		TableCostGroupDiscovery(TSName, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableBeforeAdding(TSName, Cancel)
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And Object.References.Count() = 0 Then
		Cancel = True;
		OpenSelectionOfOrders();
		Return;
	EndIf;
	
	If Not TSName = "Services" Then
		BlockOrders(Cancel);
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure TableBeforeStartingChange(Cancel)
	BlockOrders(Cancel);
	Return;
	
EndProcedure

&AtClient
Procedure TableAtBeginningOfEditing(TSName, NewRow, Copy)
	
	CurrentData = Items[TSName].CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items[TSName], ThisForm);
	
	StructureOfActions = New Structure;
	
	If NewRow Then
		
		CurrentData.RowCode = 0;
		
		AddActionsCheckFillWarehouse(ThisForm, TSName, StructureOfActions);
		
		If Not Copy Then
			
			If (TSName = "ManufacturedProducts"
					Or TSName = "SideAndIntermediateRelease")
				And Object.OneDateReceipt Then
				CurrentData.DateOfReceipt = Object.DateOfReceipt;
			ElsIf TSName = "SupplyWithMaterialsAndWorks"
				And Object.NotShipInInstallments Then
				CurrentData.DateOfShipment = Object.DateOfShipment;
			EndIf;
			
			AddActionsFillInPriceView(ThisForm, TSName, StructureOfActions);
			AddActionsInitializeArticleAndAnalytics(ThisForm, TSName, StructureOfActions);
			
		EndIf;
		
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		RestrictRecipientType(TSName, CurrentData);
	EndIf;
	If TSName = "Services" Then
		SpecifyTypeOfReasonForCancelingServices(CurrentData);
	EndIf;
	If Copy Then
		
		AddCollateralActions(
			ThisForm,
			TSName,
			StructureOfActions,
			"SupplyOption, Available, WarehouseIsRequired, DateOfShipmentRequired_");
		
		AddActionsCheckSeriesCalculateStatus(ThisForm, TSName, StructureOfActions, CurrentData);
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		If Copy Then
			
			If Not CurrentData.WithAssignment Then
				CurrentData.Purpose = Undefined;
			EndIf;
			
			FillInDependentServiceDetailsSupply(ThisForm);
			
		EndIf;
		
		WarehousesClient.UpdateCachedValues(
			Items.SupplyWithMaterialsAndWorks,
			CachedValues,
			SeriesSpecificationParameters.SupplyWithMaterialsAndWorks,
			Copy);
		FillInServiceDetailsOfStageSupportInLine(ThisForm, CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableBeforeDeletion(TSName, Item, Cancel)
	If Not BlockOrders(Cancel) Then
		Return;
	EndIf;
	ProcessingOfTabularFormsClient.CacheCurLine(Items[TSName], ThisForm);
	
	If TSName = "ManufacturedProducts"
		And Not Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		Then
		OutputItemsBeforeDeletingOnServer();
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,
			CachedValues,
			SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		BeforeDeletingRowsIncludedInSets();
	EndIf;
	
EndProcedure

&AtClient
Procedure TableAfterDeletion(TSName, ThereIsChangeInShippingDates = False)
	
	TableAfterDeletionOnServer(TSName, ThereIsChangeInShippingDates);
	
EndProcedure

&AtServer
Procedure TableAfterDeletionOnServer(TSName, ThereIsChangeInShippingDates)
	
	For Each CurrentData In CostGroups Do
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
	EndDo;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts();
		If ThereIsChangeInShippingDates Then
			ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProducts.DateOfShipment");
		EndIf;
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		UpdateColumnIsAvailableOnServer();
		FillInDependentServiceDetailsSupply(ThisForm);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or VTCHProductWarehouse Then
		TableChangesWhenChangedOnServer(TSName);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableBeforeEndOfEditing(TSName, Item, NewRow, CancelEdit, Cancel)
	
	If NewRow
		And CancelEdit Then
		Return;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	
	If NewRow Then
		FillDateInTSLineWithTotalDate(ThisObject, TSName, CurrentData);
	EndIf;
	
	TableBeforeEndOfEditingOnServer(
		TSName,
		CurrentData.GetID(),
		NewRow,
		CancelEdit,
		Cancel);
	
EndProcedure

&AtServer
Procedure TableBeforeEndOfEditingOnServer(TSName, CurrentID, NewRow, CancelEdit, Cancel)
	
	CurrentData = Object[TSName].FindByID(CurrentID);
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items[TSName], ThisObject);
	
	If TSName = "ManufacturedProducts" Then
		If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			AddChangeCostGroup(CurrentData);
		Else
			SetDefaultCostGroupNumber(TSName, CurrentID);
			TableFillInDependentServiceDetailsOfCostGroup(TSName, LineCache.CostGroupNumber);
			TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
		EndIf;
		Groups = New Array;
		Groups.Add(LineCache.CostGroupNumber);
		Groups.Add(CurrentData.CostGroupNumber);
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
	Else
		
		SetDefaultCostGroupNumber(TSName, CurrentID);
		TableFillInDependentServiceDetailsOfCostGroup(TSName, LineCache.CostGroupNumber);
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		UpdateColumnIsAvailableOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure TableWhenModified(TSName)
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		AttributesList = "NumberOfProducts";
	ElsIf TSName = "Services" Then
		AttributesList = "AmountOfServices";
	Else
		AttributesList = "DepositValue";
	EndIf;
	
	CalculateDocumentTotals(ThisForm, AttributesList);
	
EndProcedure

&AtClient
Procedure TableCostGroupCleaning(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	CostGroupNumberBeforeChange = CurrentData.CostGroupNumber;
	
	CurrentData.CostGroupNumber = 0;
	CurrentData.ExpenseGroup = "";
	CurrentData.ReferenceOrder = Undefined;
	
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And TSName = "ManufacturedProducts" Then
		
		CurrentData.BillOfMaterials = Undefined;
		CurrentData.Stage = Undefined;
		CurrentData.MethodOfAllocatingFinishedProductCosts = Undefined;
		
	EndIf;
	If TSName = "SupplyWithMaterialsAndWorks" Then
		CurrentData.OrderDocument = Undefined;
		
		If Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
			CurrentData.ParametersForFillingAssignments = Undefined;
			CurrentData.AppointmentSelectionList.Clear();
		EndIf;
		CurrentData.Purpose = Undefined;
		UpdateColumnIsAvailableOnServer();
		
	EndIf;
	
	TableFillInDependentServiceDetailsOfCostGroup(TSName, CostGroupNumberBeforeChange);
	
EndProcedure

&AtClient
Procedure TableCostGroupDiscovery(TSName, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items[TSName].CurrentData;
	
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And ValueIsFilled(CurrentData.ReferenceOrder) Then
		ShowValue(, CurrentData.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableCostGroupStartOfSelection(TSName, StandardProcessing = False)
	
	StandardProcessing = False;
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	If Items[TSName].SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng mà nhóm chi phí sẽ được điền.';
							|ru = 'Необходимо выбрать строки, для которых будет заполнена группа затрат.';
							|en = 'Select the lines for which a cost group will be populated.'; fa = 'Select the lines for which a cost group will be populated.';
							|it = 'È necessario selezionare le righe per le quali sarà compilato il gruppo delle spese.';
							|pl = 'Należy wybrać wiersze, dla których będzie wypełniona grupa kosztów.';
							|tr = 'Maliyet grubunun doldurulacağı satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("GroupCosts",         Object.GroupCosts);
	FormParameters.Insert("CostGroupNumber",         Items[TSName].CurrentData.CostGroupNumber);
	FormParameters.Insert("CostGroupStorageAddress", PutCostGroupDataInStorage(TSName));
	
	FormParameters.Insert(
		"CostGroupFields_",
		ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(Object.GroupCosts));
	
	CallbackDescription = New CallbackDescription("TableCostGroupStartOfSelectionCompletion", ThisForm, TSName);
	OpenForm("CommonForm.SelectExpenseGroupTransferringToProcessing", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtServer
Procedure TableFillInDependentServiceDetailsOfCostGroup(TSName, CostGroupNumber)
	
	If TSName = "ManufacturedProducts"
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "SideAndIntermediateRelease"
		Then
		
		If Not CostGroupNumber = 0 Then
			FillInDependentServiceDetailsOfCostGroup(
				CostGroupDataByCostGroupNumber(CostGroupNumber));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableProductsWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActions);
	AddActionsCheckFillSpecification(ThisObject, TSName, StructureOfActions, CurrentData);
	AddActionsCheckSeriesCalculateStatus(ThisObject, TSName, StructureOfActions, CurrentData);
	AddActionsCheckFillWarehouse(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	
	AddCollateralActions(
		ThisObject,
		TSName,
		StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		RestrictRecipientType(TSName, CurrentData)
	EndIf;
	
	UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		FillInDependentServiceDetailsSupply(ThisObject);
		WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet();
	EndIf;
	
EndProcedure

&AtClient
Procedure TableCharacteristicsWhenChanging(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingCharacteristic(ThisObject, TSName, StructureOfActions);
	AddActionsCheckFillSpecification(ThisObject, TSName, StructureOfActions, CurrentData);
	AddActionsCheckFillShareCost(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	
	AddCollateralActions(
		ThisObject,
		TSName,
		StructureOfActions,
		"SupplyOption,AvailableInOtherLines,WarehouseIsRequired,DateOfShipmentRequired_");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		FillInDependentServiceDetailsSupply(ThisObject);
		WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet();
	EndIf;
	
EndProcedure

&AtClient
Procedure PackingTableWhenChanging(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingPackaging(ThisForm, TSName, StructureOfActions, CurrentData);
	AddCollateralActions(ThisForm, TSName, StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData);
	
EndProcedure

&AtClient
Procedure TableNumberOfPackagesWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingQuantity(ThisForm, TSName, StructureOfActions);
	AddCollateralActions(ThisForm, TSName, StructureOfActions, "AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData);
	
EndProcedure

&AtClient
Procedure TablePriceWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "Services" Then
		AttributesList = "Sum, VATAmount, AmountIncludingVAT";
	Else
		AttributesList = "Sum";
	EndIf;
	
	AddActionsForRecalculatingAmounts(ThisForm, TSName, StructureOfActions, AttributesList);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableAmountWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "Services" Then
		AttributesList = "Price, VATAmount, AmountIncludingVAT";
	Else
		AttributesList = "Price";
	EndIf;
	
	AddActionsForRecalculatingAmounts(ThisForm, TSName, StructureOfActions, AttributesList);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableWarehouseWhenModified(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingWarehouse(ThisForm, TSName, StructureOfActions);
	
	AddCollateralActions(
		ThisForm,
		TSName,
		StructureOfActions,
		"AvailableInOtherLines");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData);
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or VTCHProductWarehouse Then
		TableChangesWhenChangedOnServer(TSName);
	EndIf;
	
EndProcedure

&AtServer
Procedure TableChangesWhenChangedOnServer(TSName)
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		FillInDependentServiceDetailsSupply(ThisForm);
		
		UpdateInventoryTable();
		UpdateWarehouseGroupImage(
			TableOfWarehousesMaterials,
			InscriptionSeveralWarehousesMaterials,
			Items.ThereAreSeveralWarehousesMaterials);
		
	Else
		
		UpdateProductWarehouseTable();
		UpdateWarehouseGroupImage(
			TableOfProductWarehouses,
			InscriptionSeveralWarehousesOfProduct,
			Items.ThereAreSeveralWarehousesWares);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure TableDateOfReceiptONChange(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableChargeToExpensesWhenChangesAreMade(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	If CurrentData.ToExpenseAs Then
		CurrentData.Purpose = Undefined;
	EndIf;
	
	RestrictRecipientType(TSName, CurrentData);
	
	StructureOfActions = New Structure;
	AddActionsCheckFillWarehouse(ThisForm, TSName, StructureOfActions);
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	IncomeAndExpensesClientServer.WhenChangingArticleAvailabilityDetailsInLine(ThisForm, CurrentData, "Object." + TSName);
	
EndProcedure

&AtClient
Procedure TableItemOfExpenditureSelection(Item, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableItemOfExpenditureInCaseOfChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisForm, Item);
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisForm, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisForm, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure TableUndoneByChange(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	If Not CurrentData.Canceled Then
		If Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
			And Not TSName = "Services" Then
			CurrentData.ReasonForCancellationOfProduction = Undefined;
		ElsIf Not TSName = "SupplyWithMaterialsAndWorks" Then
			CurrentData.CancellationReason = Undefined;
		EndIf;
	EndIf;
	
	ThereIsChangeInShippingDates = ARAPAccountingClient.ThereIsChangeInShippingDates(ThisObject);
	TableReversedWhenModifiedOnServer(TSName, CurrentData.GetID(), ThereIsChangeInShippingDates);
	
EndProcedure

&AtServer
Procedure TableReversedWhenModifiedOnServer(TSName, CurrentID, ThereIsChangeInShippingDates=False)
	
	CurrentData = Object[TSName].FindByID(CurrentID);
	TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
	
	If TSName = "ManufacturedProducts"
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "SideAndIntermediateRelease"
		Then
		
		SelectedRows = New Array;
		SelectedRows.Add(CurrentID);
		
		UndoCostGroupRows(TSName, SelectedRows);
		
		If ThereIsChangeInShippingDates Then
			ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ManufacturedProducts.DateOfShipment");
		EndIf;
		
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsCheckSeriesCalculateStatus(ThisForm, TSName, StructureOfActions, CurrentData);
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	AddCollateralActions(
		ThisForm,
		TSName,
		StructureOfActions,
		"WarehouseIsRequired, DateOfShipmentRequired_");
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "Services" Then
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails(TSName));
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		UpdateColumnIsAvailableOnServer();
		FillInDependentServiceDetailsSupply(ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region IsMain

&AtClient
Procedure CloseOrder(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(
			New CallbackDescription("CloseOrderCompletion", ThisForm),
			NStr("vi = 'Cần kết chuyển chứng từ để hoàn thành giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
	Else
		CloseOrderFragment();
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.CreditPaymentForm);
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure ManufacturedProductsPickUpProducts(Command)
	TablePickUpProducts("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputProductsShouldBeSelectedByStagesOfProduction(Command)
	Table1ByStagesOfProduction("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputProductsToBeRefilledAccordingToSpecifications(Command)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Trong bảng ""Sản phẩm đầu ra"" chưa chọn dòng nào.
									|Không thể điền.';
									|ru = 'В таблице ""Выходные изделия"" не выбрано ни одной строки.
									|Заполнение невозможно.';
									|en = 'No rows were selected in the ""Finished products"" table.
									|Cannot fill in the table.'; fa = 'No rows were selected in the ""Finished products"" table.
									|Cannot fill in the table.';
									|it = 'Nella tabella ""Prodotti in uscita"" non è selezionata nessuna riga.
									|La compilazione non è possibile.';
									|pl = 'W tabeli ""Wyroby wyjściowe"" nie wybrano ani jednego wiersza.
									|Wypełnienie jest niemożliwe.';
									|tr = '""Üretilen Nihai Ürünler"" tablosunda herhangi bir satır seçilmedi.
									|Doldurulması mümkün değildir.'"));
		Return;
	EndIf;
	
	ListOfGroups = New Array;
	For Each RowID In Items.ManufacturedProducts.SelectedRows Do
		
		CurrentData = Object.ManufacturedProducts.FindByID(RowID);
		
		If CurrentData.Canceled Then
			Continue;
		ElsIf ValueIsFilled(CurrentData.BillOfMaterials) Then
			ListOfGroups.Add(CurrentData.CostGroupNumber);
		EndIf;
		
	EndDo;
	ListOfGroups = CommonClientServer.CollapseArray(ListOfGroups);
	
	If ListOfGroups.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng mà có thể điền lại bảng kê chi tiết các nguồn lực sản xuất.';
							|ru = 'Необходимо выбрать строки, для которых возможно перезаполнение по спецификации.';
							|en = 'Select lines that can be overwritten by BOM.'; fa = 'Select lines that can be overwritten by BOM.';
							|it = 'È necessario selezionare le righe per le quali è possibile effettuare la ricompilazione in base alla specifica.';
							|pl = 'Należy wybrać wiersze, dla których jest możliwe ponowne wypełnienie według specyfikacji materiałowej.';
							|tr = 'Ürün reçetesine göre yeniden doldurulabilecek satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	If Object.SideAndIntermediateRelease.Count() = 0
		And Object.SupplyWithMaterialsAndWorks.Count() = 0
		And Object.Services.Count() = 0 Then
		ReFillAccordingToSpecificationsOnServer(ListOfGroups);
	Else
		
		QueryText = NStr("vi = 'Sản phẩm phụ, nguyên vật liệu và công việc, dịch vụ theo các dòng đã chọn sẽ bị xóa.
								|Tiếp tục?';
								|ru = 'Побочные изделия, материалы и работы, услуги по выбранным строкам будут очищены.
								|Продолжить?';
								|en = 'By-products, materials and works, services of the selected lines will be cleared.
								|Continue?'; fa = 'By-products, materials and works, services of the selected lines will be cleared.
								|Continue?';
								|it = 'Sottoprodotti, materiali e lavori, servizi per le righe selezionate saranno cancellati.
								|Continuare?';
								|pl = 'Wyroby poboczne, materiały i pracy, usługi według wybranych wierszy zostaną wyczyszczone.
								|Kontynuować?';
								|tr = 'Seçili satırlardaki yan nihai ürünler, malzemeler ve işler, hizmetler temizlenecektir.
								|Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("OutputProductsToBeRefilledAccordingToSpecificationsCompletion", ThisForm, ListOfGroups);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputItemsFillCostGroup(Command)
	TableFillCostGroup("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputProductsFillInReceiptDate(Command)
	TableFillDate("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputProductsFromRecipient(Command)
	TableFillWarehouseDivision("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputItemsFillInReasonForCancellation(Command)
	TableFillInReasonForCancellation("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputItemsUndoHighlightedRows(Command)
	TableUndoSelectedRows("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputItemsUndoUndeliveredRows(Command)
	TableUndoRawRows("ManufacturedProducts");
EndProcedure

&AtClient
Procedure FinishedProductsHideCanceledLines(Command)
	TableHideCanceledRows("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsCopyLines(Command)
	TableCopyRows("ManufacturedProducts");
EndProcedure

&AtClient
Procedure ManufacturedProductsInsertRows(Command)
	InsertRowsTable("ManufacturedProducts");
EndProcedure

&AtClient
Procedure OutputItemsSplitLine(Command)
	TableSplitRow("ManufacturedProducts");
EndProcedure

&AtClient
Procedure FinishedProductsSearchByBarcode(Command)
	BarcodeSearchTable("ManufacturedProducts");
EndProcedure

#EndRegion

#Region SideAndIntermediateRelease

&AtClient
Procedure ByProductsPickUpProducts(Command)
	TablePickUpProducts("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillTSAccordingToSpecification(Command)
	TableOfTSParametersAccordingToSpecification("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillInPricesByPriceType(Command)
	
	ClearMessages();
	
	PricesCalculated = FillInPricesByPriceKindServer("SideAndIntermediateRelease", Items.SideAndIntermediateRelease.SelectedRows);
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	
EndProcedure

&AtClient
Procedure ByProductsFillInTheCostGroup(Command)
	TableFillCostGroup("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillInDateOfReceipt(Command)
	TableFillDate("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillRecipient(Command)
	TableFillWarehouseDivision("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillOutTheCalculationArticle(Command)
	TableFillArticleCalculation("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsFillInReasonForCancellation(Command)
	TableFillInReasonForCancellation("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsUndoHighlightedRows(Command)
	TableUndoSelectedRows("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsCancelUndeliveredStrings(Command)
	TableUndoRawRows("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure SideProductsHideCanceledLines(Command)
	TableHideCanceledRows("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsCopyLines(Command)
	TableCopyRows("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsInsertRows(Command)
	InsertRowsTable("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsSplitString(Command)
	TableSplitRow("SideAndIntermediateRelease");
EndProcedure

&AtClient
Procedure ByProductsBarcodeSearch(Command)
	BarcodeSearchTable("SideAndIntermediateRelease");
EndProcedure

#EndRegion

#Region SupplyWithMaterialsAndWorks

&AtClient
Procedure ProvisionOfMaterialsAndWorksToPickUpGoods(Command)
	TablePickUpProducts("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksForTSAccordingToSpecification(Command)
	TableOfTSParametersAccordingToSpecification("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksFillPricesByTypeOfPrices(Command)
	
	ClearMessages();
	
	PricesCalculated = FillInPricesByPriceKindServer("SupplyWithMaterialsAndWorks", Items.SupplyWithMaterialsAndWorks.SelectedRows);
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksForFEFOSeries(Command)
	
	If ThereAreFilledSeriesByFEFO() Then
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(
			New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisForm));
	ElsIf Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksToFillCostGroup(Command)
	TableFillCostGroup("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksOnDateOfShipment(Command)
	TableFillDate("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksToFillWarehouse(Command)
	TableFillWarehouseDivision("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksToFillArticleCalculation(Command)
	TableFillArticleCalculation("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksFillInReasonForCancellation(Command)
	TableFillInReasonForCancellation("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksToUndoHighlightedLines(Command)
	TableUndoSelectedRows("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorkToUndoUnprocessedRows(Command)
	TableUndoRawRows("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksToHideCancelledRows(Command)
	TableHideCanceledRows("SupplyWithMaterialsAndWorks");
EndProcedure

#Region Supply

&AtClient
Procedure ProvisionOfMaterialsAndWorksIncludeSeparateProvision(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksTurnOffSeparateProvision(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksShouldBeReservedAsSoonAsTheyAreReceived(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksToEnsure(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksShouldNotBeProvided(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksShip(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetActionWithQuestion("ACTION_LOAD");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksReserve(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetActionWithQuestion("ACTION_RESERVE");
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksTransferredEarlier(Command)
	If Not BlockOrders(Undefined) Then
		Return;
	EndIf;
	ProvidingSetActionWithQuestion("ACTION_TRANSMITTED");
	
EndProcedure

&AtClient
Procedure CreateAnAssignmentAdjustmentReservation(Command)
	
	DocumentData = SupplyInDocumentsServerCall.DocumentDataForCreatingDestinationAdjustment(Object.Ref,
		New Structure("IDInStorage,ThisIsWithdrawalOfReserve", UUID, False));
	
	If Object.Status = PredefinedValue("Enum.TollingOrderStatuses.NotApproved") Then
		MinimumStatus = PredefinedValue("Enum.TollingOrderStatuses.ForFulfillment");
		SupplyClient.ReportRequiredMinimumDocumentStatus(False, MinimumStatus);
	ElsIf Modified Or Not DocumentData.Posted Then
		ShowMessageBox(, NStr("vi = 'Để lập dự phòng theo mục đích, trước tiên cần kết chuyển chứng từ.';
								|ru = 'Для резервирования под назначение необходимо предварительно провести документ.';
								|en = 'To reserve for assignment, post the document first.'; fa = 'To reserve for assignment, post the document first.';
								|it = 'Per prenotare per l''assegnazione è innanzitutto necessario registrare il documento in contabilità.';
								|pl = 'Aby zarezerwować dokument do przeznaczenia, należy najpierw zaksięgować dokument.';
								|tr = 'Atama rezervinin yapılması için önce belgeyi kaydetmeniz gerekmektedir.'"));
	Else
		
		CommandDetails = New Structure();
		CommandDetails.Insert("ObjectsOfBases", CommonClientServer.ValueInArray(Object.Ref));
		CommandDetails.Insert("Form", ThisObject);
		CommandDetails.Insert("AddressOfGoods", DocumentData.AddressOfGoods);
		If DocumentData.ThereAreGoodsToSeparateProvision Then
			If DocumentData.Assignments.Count() = 1 Then
				CommandDetails.Insert("Purpose", DocumentData.Assignments[0]);
				GenerationByReferenceTMClient.OpenBackupWizard(CommandDetails);
			Else
				CommandDetails.Insert("Assignments", DocumentData.Assignments);
				GenerationByReferenceTMClient.OpenMassBackupWizard(CommandDetails);
			EndIf;
		Else
			SupplyClient.ReportAbsenceOfGoodsForSeparateProvision();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateAssignmentAdjustmentRemoveFromReserve(Command)
	
	DocumentData = SupplyInDocumentsServerCall.DocumentDataForCreatingDestinationAdjustment(Object.Ref,
		New Structure("IDInStorage,ThisIsWithdrawalOfReserve", UUID, True));
	
	If Object.Status = PredefinedValue("Enum.TollingOrderStatuses.NotApproved") Then
		MinimumStatus = PredefinedValue("Enum.TollingOrderStatuses.ForFulfillment");
		SupplyClient.ReportRequiredMinimumDocumentStatus(False, MinimumStatus);
	ElsIf Modified Or Not DocumentData.Posted Then
		ShowMessageBox(, NStr("vi = 'Để hoàn nhập dự phòng theo mục đích, trước hết cần kết chuyển chứng từ.';
								|ru = 'Для снятия резерва под назначение необходимо предварительно провести документ.';
								|en = 'To unreserve inventory, please post the document.'; fa = 'To unreserve inventory, please post the document.';
								|it = 'Per annullare la prenotazione per l''assegnazione è innanzitutto necessario registrare il documento in contabilità.';
								|pl = 'Aby anulować rezerwę do przeznaczenia, należy najpierw zaksięgować dokument.';
								|tr = 'Atama rezervinin kaldırılması için önce belgeyi kaydetmeniz gerekmektedir.'"));
	Else
		
		CommandDetails = New Structure();
		CommandDetails.Insert("ObjectsOfBases", CommonClientServer.ValueInArray(Object.Ref));
		CommandDetails.Insert("Form", ThisObject);
		CommandDetails.Insert("AddressOfGoods", DocumentData.AddressOfGoods);
		If DocumentData.ThereAreGoodsToWithdrawReserve Then
			If DocumentData.Assignments.Count() = 1 Then
				CommandDetails.Insert("Purpose", DocumentData.Assignments[0]);
				GenerationByReferenceTMClient.OpenReserveWithdrawalWizard(CommandDetails);
			Else
				CommandDetails.Insert("Assignments", DocumentData.Assignments);
				GenerationByReferenceTMClient.OpenMassReserveWithdrawalWizard(CommandDetails);
			EndIf;
		Else
			SupplyClient.ReportAbsenceOfGoodsForWithdrawalOfReserve();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SecurityStatusHyperlinkClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIsBeingShippedClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIssueClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

#EndRegion

&AtClient
Procedure ProvisionOfMaterialsAndWorksCopyLines(Command)
	TableCopyRows("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksInsertLines(Command)
	InsertRowsTable("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksToBreakUpRow(Command)
	TableSplitRow("SupplyWithMaterialsAndWorks");
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksBarcodeSearch(Command)
	BarcodeSearchTable("SupplyWithMaterialsAndWorks");
EndProcedure

#EndRegion

#Region Services

&AtClient
Procedure ServicesPickUpProducts(Command)
	TablePickUpProducts("Services");
EndProcedure

&AtClient
Procedure ServicesFillTSAccordingToSpecification(Command)
	TableOfTSParametersAccordingToSpecification("Services");
EndProcedure

&AtClient
Procedure ServicesFillInPricesBySupplierPriceType(Command)

	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Services", NStr("vi = 'Dịch vụ';
																													|ru = 'Услуги';
																													|en = 'Services'; fa = 'خدمات';
																													|it = 'Servizi';
																													|pl = 'Services';
																													|tr = 'Hizmetler'")) Then
		
		CurrentData = Items.Services.CurrentData;
		
		If Not CurrentData = Undefined
			And Not ValueIsFilled(CurrentData.VendorPriceKind) Then
			PartnerPricesFillingClient.SelectVendorsPriceType(
				New CallbackDescription("ServicesFillInPricesBySupplierPriceTypeCompletion", ThisForm),
				Object.Partner,
				Object.PriceIncludesVAT);
		Else
			ServicesFillInPricesBySupplierPriceTypeCompletion(CurrentData.VendorPriceKind, Undefined);
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure ServicesSelectAndCompleteService(Command)
	
	If Items.Services.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Để điền dịch vụ, cần chọn các dòng.';
								|ru = 'Для заполнения услуги необходимо выбрать строки.';
								|en = 'To fill in the service, select lines.'; fa = 'To fill in the service, select lines.';
								|it = 'Per compilare il servizio è necessario selezionare le righe.';
								|pl = 'Aby wypełnić usługę, musisz wybrać wiersz.';
								|tr = 'Hizmetin doldurulması için satırları seçmeniz gerekmektedir.'"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ServicesSelectAndCompleteServiceCompletion", ThisForm);
	FilterParameters = New Structure("ItemsType", PredefinedValue("Enum.ItemsTypes.Work_5"));
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	OpenForm("Catalog.Products.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ServicesFillCostGroup(Command)
	TableFillCostGroup("Services");
EndProcedure

&AtClient
Procedure ServicesFillInDueDate(Command)
	TableFillDate("Services");
EndProcedure

&AtClient
Procedure ServicesFillOutCalculationArticle(Command)
	TableFillArticleCalculation("Services");
EndProcedure

&AtClient
Procedure ServicesFillInReasonForCancellation(Command)
	TableFillInReasonForCancellation("Services");
EndProcedure

&AtClient
Procedure ServicesHideCancelledRows(Command)
	TableHideCanceledRows("Services");
EndProcedure

&AtClient
Procedure ServicesUndoHighlightedRows(Command)
	TableUndoSelectedRows("Services");
EndProcedure

&AtClient
Procedure ServicesUndoUnprocessedRows(Command)
	TableUndoRawRows("Services");
EndProcedure

&AtClient
Procedure ServicesCopyRows(Command)
	TableCopyRows("Services");
EndProcedure

&AtClient
Procedure ServicesInsertRows(Command)
	InsertRowsTable("Services");
EndProcedure

&AtClient
Procedure ServicesToSplitTheString(Command)
	TableSplitRow("Services");
EndProcedure

&AtClient
Procedure BarcodeSearchServices(Command)
	BarcodeSearchTable("Services");
EndProcedure

#EndRegion

#Region TableCommandHandlers

&AtClient
Procedure TablePickUpProducts(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	PickUpProduct(TSName);
	
EndProcedure

&AtClient
Procedure Table1ByStagesOfProduction(TSName)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractOrder2_5.Form.DocumentForm.Command." + TSName + "SelectByStagesOfProduction");
	
	OpenSelectionOfOrders();
	Return;
	
EndProcedure

&AtClient
Procedure TableOfTSParametersAccordingToSpecification(TSName)
	
	If Not Object[TSName].Count() = 0 Then
			
			CallbackDescription = New CallbackDescription("TableOfTSParametersAccordingToSpecificationCompletion", ThisForm, TSName);
			
			QueryText = NStr("vi = 'Phần bảng sẽ được điền lại theo bảng kê chi tiết. Tiếp tục?';
							|ru = 'Табличная часть будет перезаполнена по спецификациям. Продолжить?';
							|en = 'The table will be refilled by the bills of materials. Continue?'; fa = 'The table will be refilled by the bills of materials. Continue?';
							|it = 'La parte tabellare sarà ricompilata in base alle specifiche. Continuare?';
							|pl = 'Sekcja tabelaryczna będzie ponownie wypełniona według specyfikacji. Kontynuować?';
							|tr = 'Tablo bölümü, ürün reçetesine göre yeniden doldurulacaktır. Devam edilsin mi?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			
	Else
		TableOfTSParametersAccordingToSpecificationCompletion(DialogReturnCode.Yes, TSName);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableFillCostGroup(TSName)
	TableCostGroupStartOfSelection(TSName);
EndProcedure

// Parameters:
// 	Command - Button Forms
// 	TSName - String
//
&AtClient
Procedure TableFillDate(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() > 0 Then
		
		DateOfReceipt = Object.RequestedDeliveryDate;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("TSName", TSName);
		AdditionalParameters.Insert("SelectedRows", SelectedRows);
		
		Notification = New CallbackDescription("TableFillDateCompletion", ThisForm, AdditionalParameters);
		
		If (TSName = "ManufacturedProducts"
				Or TSName = "SideAndIntermediateRelease")
			And Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
			TitleOfInputForm = NStr("vi = 'Hãy nhập ngày sản xuất';
									|ru = 'Введите дату производства';
									|en = 'Enter production date'; fa = 'Enter production date';
									|it = 'Inserire data di produzione';
									|pl = 'Wprowadź datę produkcji';
									|tr = 'Üretim tarihini girin'");
		ElsIf TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease"
			Then
			TitleOfInputForm = NStr("vi = 'Hãy nhập ngày tiếp nhận';
									|ru = 'Введите дату поступления';
									|en = 'Enter date of receipt'; fa = 'Enter date of receipt';
									|it = 'Inserire la data di arrivo';
									|pl = 'Wprowadź datę wpłaty';
									|tr = 'Teslim alma tarihini girin'");
		ElsIf TSName = "Services" Then
			TitleOfInputForm = NStr("vi = 'Hãy nhập ngày thực hiện công việc';
									|ru = 'Введите дату выполнения работ';
									|en = 'Enter work completion date'; fa = 'Enter work completion date';
									|it = 'Inserire data di esecuzione lavori';
									|pl = 'Wpisz datę wykonania prac';
									|tr = 'İşin gerçekleştirilme tarihini girin'");
		Else
			TitleOfInputForm = NStr("vi = 'Hãy nhập ngày giao hàng';
									|ru = 'Введите дату отгрузки';
									|en = 'Enter shipment date'; fa = 'Enter shipment date';
									|it = 'Inserire la data di spedizione';
									|pl = 'Wprowadź datę wysyłki';
									|tr = 'Sevkiyat tarihini girin'");
		EndIf;
		
		TMCommonUseClient.EnterDateWithControlOfEmptyValue(
			DateOfReceipt,
			TitleOfInputForm,
			DateFractions.Date,
			Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableFillWarehouseDivision(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm"  , TSName);
	TSParameters.Insert("NameTsObject" , TSName);
	
	If TSName = "ManufacturedProducts" Then
		TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm đầu ra';
														|ru = 'Выходные изделия';
														|en = 'Finished products'; fa = 'Finished products';
														|it = 'Prodotti finiti';
														|pl = 'Wyroby gotowe';
														|tr = 'Üretilen nihai ürünler'"));
	ElsIf TSName = "SideAndIntermediateRelease" Then
		TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm phụ';
														|ru = 'Побочные изделия';
														|en = 'By-products'; fa = 'By-products';
														|it = 'Sottoprodotti';
														|pl = 'Produkty uboczne';
														|tr = 'Yan nihai ürünler'"));
	Else
		TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Nguyên vật liệu và công việc';
														|ru = 'Материалы и работы';
														|en = 'Materials and works'; fa = 'Materials and works';
														|it = 'Materiali e lavori';
														|pl = 'Materiały i prace';
														|tr = 'Malzemeler ve işler'"));
	EndIf;
	
	If (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease")
		And Not VTCHProductWarehouse Then
		TSParameters.Insert("WarehouseInHeader", True);
	ElsIf TSName = "SupplyWithMaterialsAndWorks"
		And Not WarehouseMaterialsVHF Then
		TSParameters.Insert("WarehouseInHeader", True);
	Else
		TSParameters.Insert("WarehouseInHeader", False);
	EndIf;
	
	TSParameters.Insert("Filter", New Structure("IsFolder", False));
	
	If (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease")
		And ProductWarehouseGroup Then
		TSParameters.Insert("GroupOfWarehouses", Object.ManufacturedProductsWarehouse);
	ElsIf TSName = "SupplyWithMaterialsAndWorks"
		And WarehouseMaterialsGroup Then
		TSParameters.Insert("GroupOfWarehouses", Object.MaterialsWarehouse);
	EndIf;
	
	CallbackDescription =
		New CallbackDescription(
			"FillWarehouseDivisionCompletion",
			ThisForm,
			New Structure("TSParameters", TSParameters));
	
	ProductionClient.OpenRecipientSelectionForm(ThisForm, Object, TSParameters,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableFillArticleCalculation(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	If Items[TSName].SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các dòng để điền dạng tính giá thành.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	CostTypes = New Array;
	CostTypes.Add(PredefinedValue("Enum.CostTypes.Material_"));
	If TSName = "SideAndIntermediateRelease" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.RecyclableWaste"));
	ElsIf TSName = "Services" Then
		CostTypes.Add(PredefinedValue("Enum.CostTypes.Other"));
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ExpenseType", CostTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisForm, AdditionalParameters);
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableFillInReasonForCancellation(TSName)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	
	Notification = New CallbackDescription("TableFillInReasonForCancellationCompletion", ThisForm, AdditionalParameters);
	
	OpenFormForSelectingCancellationReasons(TSName, Notification);
	
EndProcedure

&AtClient
Procedure TableUndoSelectedRows(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	If Not SalesClient.YouMustFillInReasonsForCancelingSelectedLines(
				Object[TSName],
				Items[TSName].Title,
				Items[TSName].SelectedRows) Then
		Return;
	EndIf;
	
	If Not UseReasonsForPurchaseOrderCancellations
		And Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		Then
		CancelSelectedLines(TSName, Undefined);
	Else
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("TSName", TSName);
		
		Notification = New CallbackDescription("TableUndoSelectedRowsCompletion", ThisForm, AdditionalParameters);
		
		OpenFormForSelectingCancellationReasons(TSName, Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableUndoRawRows(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	If Object[TSName].Count() = 0 Then
		
		FormTable = Items[TSName]; // FormTable
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền danh sách %1. Không thể hủy các dòng.';
							|ru = 'В документе не заполнен список ""%1"". Строки не могут быть отменены.';
							|en = 'The ""%1"" list in the document is not filled in. Cannot cancel the lines.'; fa = 'The ""%1"" list in the document is not filled in. Cannot cancel the lines.';
							|it = 'Nel documento non è compilato l''elenco ""%1"". Le righe non possono essere annullate.';
							|pl = 'Dokument nie zawiera wypełnionej listy ""%1"". Terminy nie mogą być anulowane.';
							|tr = 'Belgedeki ""%1"" listesi doldurulmadı. Satırlar iptal edilemez.'");
		WarningText = StrTemplate(WarningText, FormTable.Title);
		ShowMessageBox(,WarningText);
		
		Return;
		
	EndIf;
	
	UndoneRows = Object[TSName].FindRows(New Structure("Canceled", False));
	If UndoneRows.Count() = 0 Then
		
		FormTable = Items[TSName]; // FormTable
		
		WarningText = NStr("vi = 'Trong chứng từ đối với danh sách ""%1"" tất cả các dòng đã bị hủy.';
							|ru = 'В документе для списка ""%1"" все строки уже отменены.';
							|en = 'All lines are already canceled in the document for the ""%1"" list.'; fa = 'All lines are already canceled in the document for the ""%1"" list.';
							|it = 'Nel documento sono state già annullate tutte le righe per l''elenco ""%1"".';
							|pl = 'W dokumencie dla listy ""%1"" wszystkie wiersze są już anulowane.';
							|tr = 'Belgedeki ""%1"" listesinin tüm satırları artık iptal edildi.'");
		WarningText = StrTemplate(WarningText, FormTable.Title);
		ShowMessageBox(,WarningText);
		
		Return;
		
	EndIf;
	
	If Not UseReasonsForPurchaseOrderCancellations
		And Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		Then
		CancellationResult = CancelUndeliveredLines(TSName, Undefined);
		ShowUserNotification(NStr("vi = 'Hủy các dòng chưa xử lý';
									|ru = 'Отмена неотработанных строк';
									|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
									|it = 'Annullamento delle righe non elaborate';
									|pl = 'Anulowanie nieprzetworzonych wierzszy';
									|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
	Else
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("TSName", TSName);
		
		Notification = New CallbackDescription("TableUndoRawRowsCompletion", ThisForm, AdditionalParameters);
		
		OpenFormForSelectingCancellationReasons(TSName, Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableHideCanceledRows(TSName)
	
	If TSName = "ManufacturedProducts" Then
		FlagName    = "HideCancelledRowsOutputItems";
		TagName = "FinishedProductsHideCanceledLines";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		FlagName    = "HideCancelledRowsByProducts";
		TagName = "SideProductsHideCanceledLines";
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		FlagName    = "HideCancelledLinesSupplyWithMaterialsAndLabor";
		TagName = "ProvidingMaterialsAndWorksToHideCancelledRows";
	Else
		FlagName    = "HideCanceledServiceLines";
		TagName = "ServicesHideCancelledRows";
	EndIf;
	
	ThisForm[FlagName] = Not ThisForm[FlagName];
	
	If ThisForm[FlagName] Then
		Items[TSName].RowFilter = New FixedStructure("Canceled", False);
	Else
		Items[TSName].RowFilter = Undefined;
	EndIf;
	
	Items[TagName].Check = ThisForm[FlagName];
	
EndProcedure

&AtClient
Procedure TableCopyRows(TSName)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRowsTable(TSName)
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And Object.References.Count() = 0 Then
		OpenSelectionOfOrders();
		Return;
	EndIf;
	
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	NumberOfProductsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboard(TSName);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		FillInDependentServiceDetailsSupply(ThisForm);
	EndIf;
	
	NumberOfInserted = Object[TSName].Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure TableSplitRow(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	FormTable  = Items[TSName];
	TableData = Object[TSName];
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	Notification = New CallbackDescription("TableSplitRowCompletion", ThisForm, AdditionalParameters);
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	If TSName = "Services" Then
		StringSplittingParameters.FieldNameQuantity = "Count";
		StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng công việc trong dòng mới';
												|ru = 'Введите количество работ в новой строке';
												|en = 'Enter quantity of works in a new line'; fa = 'Enter quantity of works in a new line';
												|it = 'Inserire la quantità di lavori nella nuova riga';
												|pl = 'Wprowadź ilość prac w nowym wierszu';
												|tr = 'Yeni satırdaki iş miktarını girin'");
	EndIf;
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure BarcodeSearchTable(TSName)
	If Not TSName = "Services"
		And Not BlockOrders() Then
		Return;
	EndIf;
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	Notification = New CallbackDescription("BarcodeSearchTableCompletion", ThisObject, AdditionalParameters);
	
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

#EndRegion

#Region Delivery

&AtClient
Procedure SupplementDeliveryInformationWithContacts(Command)
	
	SupplementDeliveryInformationWithContactsServer();
	
EndProcedure

#EndRegion

#Region ObjectCommands_

&AtClient
Procedure PostAndClose(Command)
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		
		ClearMessages();
		
		ForceCloseTheForm = True;
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode",                            DocumentWriteMode.Posting);
		WriteParameters.Insert("PostingMode",                        DocumentPostingMode.Regular);
		WriteParameters.Insert("ForceCloseTheForm",              True);
		WriteParameters.Insert("NewObject",                            Not ValueIsFilled(Object.Ref));
		WriteParameters.Insert("DisablePostWriteProcessingOnServer", True);
		
		If PostAtServer(WriteParameters) Then
			AfterWrite(WriteParameters);
		Else
			ExceptionText = StrTemplate(
				NStr("vi = 'Không thể kết chuyển ""%1""';
					|ru = 'Не удалось провести ""%1""';
					|en = 'Cannot post ""%1""'; fa = 'Cannot post ""%1""';
					|it = 'Impossibile registrare ""%1""';
					|pl = 'Nie udało się zatwierdzić ""%1""';
					|tr = '""%1"" kaydedilemedi'"),
				?(ValueIsFilled(Object.Ref), Object.Ref, NStr("vi = 'Đơn đặt hàng gia công';
																|ru = 'Заказ переработчику';
																|en = 'Purchase order — Subcontracting'; fa = 'Purchase order — Subcontracting';
																|it = 'Ordine al subfornitore';
																|pl = 'Zamówienie do przetwórcy';
																|tr = 'Fason satın alma siparişi'")));
			Raise ExceptionText;
		EndIf;
		
	Else
		TMCommonUseClient.PostAndClose(ThisForm, True);
	EndIf;
EndProcedure

&AtClient
Procedure PostDocument(Command)
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		
		ClearMessages();
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode",                            DocumentWriteMode.Posting);
		WriteParameters.Insert("PostingMode",                        DocumentPostingMode.Regular);
		WriteParameters.Insert("ForceCloseTheForm",              False);
		WriteParameters.Insert("NewObject",                            Not ValueIsFilled(Object.Ref));
		WriteParameters.Insert("DisablePostWriteProcessingOnServer", True);
		
		If PostAtServer(WriteParameters) Then
			AfterWrite(WriteParameters);
		Else
			ExceptionText = StrTemplate(
				NStr("vi = 'Không thể kết chuyển ""%1""';
					|ru = 'Не удалось провести ""%1""';
					|en = 'Cannot post ""%1""'; fa = 'Cannot post ""%1""';
					|it = 'Impossibile registrare ""%1""';
					|pl = 'Nie udało się zatwierdzić ""%1""';
					|tr = '""%1"" kaydedilemedi'"),
				?(ValueIsFilled(Object.Ref), Object.Ref, NStr("vi = 'Đơn đặt hàng gia công';
																|ru = 'Заказ переработчику';
																|en = 'Purchase order — Subcontracting'; fa = 'Purchase order — Subcontracting';
																|it = 'Ordine al subfornitore';
																|pl = 'Zamówienie do przetwórcy';
																|tr = 'Fason satın alma siparişi'")));
			Raise ExceptionText;
		EndIf;
		
	Else
		TMCommonUseClient.Post(ThisObject, True);
	EndIf;
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure DeletionMark(Command)
	
	QueryText = NStr("vi = 'Đặt dấu xóa ""%1""?';
					|ru = 'Пометить ""%1"" на удаление?';
					|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
					|it = 'Contrassegnare ""%1"" per cancellazione?';
					|pl = 'Zaznaczyć ""%1"" do usunięcia?';
					|tr = '""%1"" silinmek üzere işaretlensin mi?'");
	If Object.DeletionMark Then
		QueryText = NStr("vi = 'Bỏ dấu xóa ""%1""?';
						|ru = 'Снять с ""%1"" пометку на удаление?';
						|en = 'Do you want to clear the deletion mark from ""%1""?'; fa = 'Do you want to clear the deletion mark from ""%1""?';
						|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
						|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
						|tr = '""%1"" için silme işareti kaldırılsın mı?'");
	EndIf;
	
	QueryText = StrTemplate(QueryText, Object.Ref);
	
	ShowQueryBox(
		New CallbackDescription("FlagDeletionAlertHandler", ThisObject),
		QueryText,
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FlagDeletionAlertHandler(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Object.DeletionMark = Not Object.DeletionMark;
	
	ForceCloseTheForm = False;
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.UndoPosting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("ForceCloseTheForm", False);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	Try
		Write(WriteParameters);
	Except
		Object.DeletionMark = Not Object.DeletionMark;
	EndTry;
	
EndProcedure

#EndRegion

#Region StandardCommands

#Region FilesOperations

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisForm, Command);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisForm, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisForm, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisForm, Item, StandardProcessing);
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisForm, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisForm, Context, Object, Result);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisForm, Object);
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisForm, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisForm);
EndProcedure

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
#Region IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

#EndRegion
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#EndRegion

#Region Private

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region StandardHeaderDesign
	
	TMCommonUse.SetConditionalAppearanceOfPriority(ThisForm);
	
	#EndRegion
	
	#Region StandardLayoutTabularParts

	EstablishConditionalAppearanceOfProductCharacteristics("ManufacturedProducts");
	EstablishConditionalAppearanceOfProductCharacteristics("SideAndIntermediateRelease");
	EstablishConditionalAppearanceOfProductCharacteristics("Services");
	
	SetConditionalAppearanceOfUnitsOfMeasurement("ManufacturedProducts");
	SetConditionalAppearanceOfUnitsOfMeasurement("SideAndIntermediateRelease");
	
	SetConditionalAppearanceOfProductAssignment("ManufacturedProducts");
	SetConditionalAppearanceOfProductAssignment("SideAndIntermediateRelease");
	SetConditionalAppearanceOfProductAssignment("SupplyWithMaterialsAndWorks");
	
	SetAppearanceOfCanceledLine("ManufacturedProducts", "CancellationReason");
	SetAppearanceOfCanceledLine("SideAndIntermediateRelease", "CancellationReason");
	SetAppearanceOfCanceledLine("Services", "CancellationReason", "ServicesPrice", "ServicesSum");
	SetAppearanceOfCanceledLine("ManufacturedProducts", "ReasonForCancellationOfProduction");
	SetAppearanceOfCanceledLine("SideAndIntermediateRelease", "ReasonForCancellationOfProduction");
	#Region VATAccounting
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(
		ThisForm,
		"ServicesVATRate",
		"ServicesVATAmount",
		"ServicesAmountIncludingVAT");
	
	VATAccountingERP.SetConditionalAppearanceOfVATAmountsAtPurchaseVATRate(
		ThisForm,
		"ServicesVATRate",
		"ServicesVATAmount");
	
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm, "ServicesAmountIncludingVAT");
	
	#EndRegion
	
	#EndRegion
	
	#Region Header
	
	#Region DateOfReceipt
	
	// Mark blank depending on the status
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfReceipt.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TollingOrderStatuses.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Mark blank depending on the status
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfReceipt.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TollingOrderStatuses.NotApproved;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DateOfReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	#EndRegion
	
	#Region DateOfShipment
	
	TMCommonUse.SetUncheckBlank(
		ConditionalAppearance,
		"DateOfShipment",
		"Object.DateOfShipment",
		"DateOfShipmentRequired_");
	
	#EndRegion
	
	#EndRegion
	
	#Region GroupCosts
	
	#Region CostGroups
	
	// Setting the visibility of the cost group column of output items from the type of grouping
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsExpenseGroup.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Setting the visibility of the cost group column from the number of groups
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsExpenseGroup.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseExpenseGroup.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksExpenseGroup.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesExpenseGroup.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfCostGroups");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 1;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	#Region BillOfMaterials
	
	// The specification is required only for the "By specifications" and "By specifications and assignments" groups
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsBillOfMaterials.Name);
	
	Groups = New ValueList;
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOM);
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = Groups;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The specification is not edited when grouped by production stages
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsBillOfMaterials.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region DateOfReceipt
	
	SetConditionalAppearanceOfWHDate("ManufacturedProducts", "OneDateReceipt", "DateOfReceipt");
	
	#EndRegion
	
	#Region CostShare
	
	// Setting the percentage registration
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(ThisForm, "Object", "ManufacturedProducts");
	ProductionServer.SetConditionalAppearanceOfShareOfCostOfCanceledRowsField(
		ThisForm,
		"Object",
		"ManufacturedProducts");
	
	// Setting the visibility of the Cost Share column by cost grouping
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostShare.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostSharePercentage.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsThereAreErrorsOfFillingInCostShare.Name);
	
	Groups = New ValueList;
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProducts);
	Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = Groups;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region ExpenseAs
	
	SetConditionalAppearanceWriteOffForExpenses_("ManufacturedProducts");
	
	#EndRegion
	
	#Region Recipient
	
	SetConditionalAppearanceRecipient("ManufacturedProducts");
	
	#EndRegion
	
	#Region QualityControl
	
	SetConditionalAppearanceOfQualityControlDetails("ManufacturedProducts");
	
	#EndRegion
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	#Region DateOfReceipt
	
	SetConditionalAppearanceOfWHDate("SideAndIntermediateRelease", "OneDateReceipt", "DateOfReceipt");
	
	#EndRegion
	
	#Region ProductCostElement
	
	SetConditionalAppearanceForCalculation("SideAndIntermediateRelease");
	
	#EndRegion
	
	#Region ExpenseAs
	
	SetConditionalAppearanceWriteOffForExpenses_("SideAndIntermediateRelease");
	
	#EndRegion
	
	#Region Recipient
	
	SetConditionalAppearanceRecipient("SideAndIntermediateRelease");
	
	#EndRegion
	
	#Region QualityControl
	
	SetConditionalAppearanceOfQualityControlDetails("SideAndIntermediateRelease");
	
	#EndRegion
	
	#EndRegion
	
	#Region SupplyWithMaterialsAndWorks
	
	DataPaths = New Structure;
	DataPaths.Insert("DynamicStructure", "DynamicStructure");
	
	ItemsNames = ProductionFormManagement.NamesOfMaterialAndWorkSupportElements();
	ItemsNames.TSName = Items.SupplyWithMaterialsAndWorks.Name;
	ItemsNames.DateOfShipment = Items.DateOfShipment.Name;
	ItemsNames.TSCharacteristic = Items.SupplyWithMaterialsAndWorksCharacteristic.Name;
	ItemsNames.TSSeries = Items.SupplyWithMaterialsAndWorksSeries.Name;
	ItemsNames.TSProductsUnitOfMeasure = Items.SupplyWithMaterialsAndWorksProductsUnitOfMeasure.Name;
	ItemsNames.TSNumberOfPackages = Items.SupplyWithMaterialsAndWorksNumberOfPackages.Name;
	ItemsNames.TSDateOfShipment = Items.SupplyWithMaterialsAndWorksDateOfShipment.Name;
	ItemsNames.TSWithAssignment = Items.SupplyWithMaterialsAndWorksWithAssignment.Name;
	ItemsNames.TSWarehouse = Items.SupplyWithMaterialsAndWorksWarehouse.Name;
	ItemsNames.TSBillOfMaterials = Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name;
	ItemsNames.TSProductCostElement = Items.SupplyWithMaterialsAndWorksProductCostElement.Name;
	ItemsNames.TSCanceled = Items.SupplyWithMaterialsAndWorksCanceled.Name;
	ItemsNames.TSPrice = Items.SupplyWithMaterialsAndWorksPrice.Name;
	ItemsNames.TSSum = Items.SupplyWithMaterialsAndWorksSum.Name;
	ItemsNames.TSCancellationReason = Items.SupplyWithMaterialsAndWorksReasonForCancellationOfProduction.Name;
	ItemsNames.TSPurpose = Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name;
	ItemsNames.TSProduced = Items.SupplyWithMaterialsAndWorksProduced.Name;
	
	ProductionFormManagement.EstablishConditionalAppearanceOfProvisionOfMaterialsAndWorks(
		ThisForm, "Object", "SupplyWithMaterialsAndWorks", ItemsNames, DataPaths);
	
	ProductionFormManagement.SetConditionalAppearanceOfSecurityFields(
		ThisForm, "Object", "SupplyWithMaterialsAndWorks");
	
	ProductionFormManagement.EstablishConditionalAppearanceOfShipmentDate(
		ThisForm, "Object", "SupplyWithMaterialsAndWorks");
	
	#Region PriceAmount
	
	// Visibility of fields depending on processing by order
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	Item.Appearance.SetParameterValue("Visible", False);
	// The price and amount are not specified for works and materials transferred earlier
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksPrice.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSum.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.SupplyOption");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SupplyOptions.TransferedEarlier;
	
	Item.Appearance.SetParameterValue("TextColor",     StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text",          NStr("vi = '<không cần>';
															|ru = '<не требуется>';
															|en = '<not required>'; fa = '<الزامی نیست>';
															|it = '<non richiesto>';
															|pl = '<nie jest wymagane>';
															|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region Warehouse
	
	// Field visibility depending on the warehouse in the header
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WarehouseMaterialsVHF");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region ProducedInProcess
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksProduced.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#EndRegion
	
	#Region Services
	
	#Region ExecutionDate
	
	SetConditionalAppearanceOfWHDate("Services", "WorkPerformanceAsOneDay", "ExecutionDate");
	
	#EndRegion
	
	#Region ProductCostElement
	
	SetConditionalAppearanceForCalculation("Services");
	
	#EndRegion
	
	#EndRegion
	
	#Region Other
	
	#Region State
	
	// Expired document
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StateOverdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDocument);
	
	//Classified document
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.State.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatesOfTollingOrders.Closed;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
	#EndRegion
	
	#Region LinesOfBusiness
	
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	#EndRegion
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfProductCharacteristics(TSName)
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm, 
		TSName + "Characteristic",
		"Object." + TSName + ".ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfUnitsOfMeasurement(TSName)
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = TSName + "ProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object." + TSName + ".Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfProductAssignment(TSName)
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		ThisForm,
		TSName + "Purpose",
		"Object." + TSName + ".ItemsType",
		False);
	
	If TSName = "ManufacturedProducts" Then
		
		// assignment is not necessary if it does not participate in cost grouping
		Item = ConditionalAppearance.Items.Add();
		
		DestinationField_ = Items[TSName + "Purpose"]; // FormField
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(DestinationField_.Name);
		
		Groups = New ValueList;
		Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments);
		Groups.Add(Enums.CostGroupingsInTollingOrder.ByProductBOMAndAssignments);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField("Object.GroupCosts");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.NotInList;
		ItemFilter.RightValue = Groups;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceForCalculation(TSName)
	
	CalculationArticleField = Items[TSName + "ProductCostElement"]; // FormField
	
	// The calculation article is not required until the order is approved
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(CalculationArticleField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TollingOrderStatuses.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete" , False);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfWHDate(TSName, FlagName, NameDate)
	
	DateElement = Items[TSName + NameDate]; // FormField
	
	// Field visibility depending on the general flag
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(DateElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + FlagName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Mark blank for the canceled line
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(DateElement.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Mark blank depending on the status
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(DateElement.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TollingOrderStatuses.NotApproved;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceWriteOffForExpenses_(TSName)
	
	// the purpose is not indicated when writing off expenses
	Item = ConditionalAppearance.Items.Add();
	
	DestinationField_ = Items[TSName + "Purpose"]; // FormField
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(DestinationField_.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<không sử dụng để ghi giảm vào chi phí>';
																	|ru = '<не используется при списании на расходы>';
																	|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
																	|it = '<non viene usato durante storno sulle spese>';
																	|pl = '<nie używane podczas rozchodu na wydatki>';
																	|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceRecipient(TSName)
	
	RecipientField = Items[TSName + "Recipient"]; // FormField
	
	// The recipient, if the flag is set, is charged for expenses
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Recipient");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text",                 New DataCompositionField("Object.Department"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Multiple warehouses are not used for the goods / multi-turn packaging types
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UseSeveralWarehouses");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue  = New DataCompositionField("Object.LeaveProductsAtSubcontractor");
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text",                 New DataCompositionField("DefaultWarehouse"));
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	// The warehouse is indicated in the header
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue  = New DataCompositionField("VTCHProductWarehouse");
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue  = New DataCompositionField("Object.LeaveProductsAtSubcontractor");
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	// The products remain for further processing
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue  = New DataCompositionField("Object.LeaveProductsAtSubcontractor");
	Filter.ComparisonType   = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<không cần>';
																	|ru = '<не требуется>';
																	|en = '<not required>'; fa = '<الزامی نیست>';
																	|it = '<non richiesto>';
																	|pl = '<nie jest wymagane>';
																	|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor" ,           StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	// Canceled lines
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object." + TSName + ".Canceled");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetAppearanceOfCanceledLine(TSName, FieldNameReasonForCancellation = "", NameOfPriceInputField = "", NameOfAmountInputField = "")
	
	ItemCanceled = Items[TSName + "Canceled"]; // FormField
	
	ElementNameReasonForCancellation = "";
	If ValueIsFilled(FieldNameReasonForCancellation) Then
		ReasonForCancellationElement = Items[TSName + FieldNameReasonForCancellation]; // FormField
		ElementNameReasonForCancellation = ReasonForCancellationElement.Name;
	EndIf;
	
	OrdersServer.SetAppearanceOfCanceledLine(ConditionalAppearance,
		Items[TSName],
		ItemCanceled.Name,
		ElementNameReasonForCancellation,
		NameOfPriceInputField,
		NameOfAmountInputField);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfQualityControlDetails(TSName)
	
	Fields = QualityControl.Fields(
		Items[TSName + "ToControlQuality"],
		Items[TSName + "QualityConfirmationDate"]);
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	Statuses = Enums.TollingOrderStatuses;
	ItemsTypes = Enums.ItemsTypes;
	QualityControl.AddFilter(FlagDisabled, "Object." + TSName + ".Canceled", True);
	QualityControl.AddFilter(FlagDisabled, "Object." + TSName + ".ToExpenseAs", True);
	QualityControl.AddFilter(FlagDisabled, "Object." + TSName + ".ItemsType", ItemsTypes.Work_5);
	QualityControl.AddFilter(FlagDisabled, "Object.LeaveProductsAtSubcontractor", True);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.NotApproved);
	QualityControl.AddFilter(DateIsOptional, "Object.Status", Statuses.ToSupply);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
EndProcedure

#EndRegion

#Region ConfiguringFormElements

&AtServer
Procedure CustomizeFormElements()
	
	UpdateOrderInformation();
	
	ConfigureDependentFormElements(ThisForm);
	ConfigureDependentFormElementsOnServer();
	
	UpdateWarehouseGroupImage(
		TableOfProductWarehouses,
		InscriptionSeveralWarehousesOfProduct,
		Items.ThereAreSeveralWarehousesWares);
	
	UpdateWarehouseGroupImage(
		TableOfWarehousesMaterials,
		InscriptionSeveralWarehousesMaterials,
		Items.ThereAreSeveralWarehousesMaterials);
	
	FillInCostGroupingSelectionList();
	ConfigureClipboardCommands(ThisForm, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	ProductDataManagement.SetSpecificationSelectionParameters(
		Items.ManufacturedProductsBillOfMaterials,
		BOMSelectionParameters.ManufacturedProducts);
	
	Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);
	Items.CloseOrder.Enabled = AccessRight("Update", Metadata.Documents.SubcontractOrder2_5);
	
	Items.SupplyWithMaterialsAndWorksSeries.Visible =
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch;
	Items.ProvisionOfMaterialsAndWorksForFEFOSeries.Visible =
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch;
	
	#Region Supply
	
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.CreateAssignmentAdjustmentRemoveFromReserve.Visible = False;
		Items.CreateAnAssignmentAdjustmentReservation.Visible = False;
	EndIf;
	
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisForm);
	
	#EndRegion
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	AttributesList - String
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	GroupingByStages = False;
	GroupingByStages =
		Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
	SpecifiedOrder =
		GroupingByStages
		And Not Object.References.Count() = 0;
	
	If Initialize
		Or AttributesList.Property("References")
		Or AttributesList.Property("ProcessingByOrder") Then
		
		Items.Status.Visible = Form.UseStatuses;
		Items.HeaderOrdersText.Visible = GroupingByStages;
		
		Items.OutputProductsShouldBeSelectedByStagesOfProduction.Visible = GroupingByStages;
		
		#Region ReasonsForCancellation
		If GroupingByStages Then
			Items.ServicesCancellationReason.TypeRestriction =
				New TypeDescription("CatalogRef.ReasonsForProductionCancellation");
		Else
			Items.ServicesCancellationReason.TypeRestriction =
				New TypeDescription("CatalogRef.ReasonsForPurchaseOrderCancellation");
		EndIf;
		UseCancellationReasons =
			Not GroupingByStages
				And Form.UseReasonsForPurchaseOrderCancellations
			Or GroupingByStages;
		
		Items.OutputItemsCancelledCancellationReasonsNotUsed.Visible = Not UseCancellationReasons;
		Items.ByProductsCancelledReasonsForCancellationNotUsed.Visible = Not UseCancellationReasons;
		Items.ProvisionOfMaterialsAndWorksCancelledReasonsForCancellationNotUsed.Visible = Not GroupingByStages;
		Items.ServicesCancelledCancellationReasonsNotUsed.Visible = Not UseCancellationReasons;
		
		Items.OutputProductsGroupCanceled.Visible = UseCancellationReasons;
		Items.ByProductsGroupCanceled.Visible = UseCancellationReasons;
		Items.ProvisionOfMaterialsAndWorksToTheGroupHasBeenCanceled.Visible = GroupingByStages;
		Items.ServicesGroupCancelled.Visible = UseCancellationReasons;
		
		Items.OutputItemsFillInReasonForCancellation.Visible = UseCancellationReasons;
		Items.ByProductsFillInReasonForCancellation.Visible = UseCancellationReasons;
		Items.ProvisionOfMaterialsAndWorksFillInReasonForCancellation.Visible = UseCancellationReasons;
		Items.ServicesFillInReasonForCancellation.Visible = UseCancellationReasons;
		
		UseSupplierCancellationReasons = 
			Form.UseReasonsForPurchaseOrderCancellations
			And Not GroupingByStages;
		
		Items.ManufacturedProductsCancellationReason.Visible = UseSupplierCancellationReasons;
		Items.SideAndIntermediateReleaseCancellationReason.Visible = UseSupplierCancellationReasons;
		
		Items.ManufacturedProductsReasonForCancellationOfProduction.Visible = GroupingByStages;
		Items.SideAndIntermediateReleaseReasonForCancellationOfProduction.Visible = GroupingByStages;
		Items.SupplyWithMaterialsAndWorksReasonForCancellationOfProduction.Visible = GroupingByStages;
		
		#EndRegion
		Items.GroupFinishedProducts.Visible =
			Form.ThereIsReleaseStage
			Or Not Object.ProcessingByOrder;
		
		If Form.ThereIsReleaseStage
			Or Not Object.ProcessingByOrder Then
			Items.GroupByProducts_2.Behavior = UsualGroupBehavior.Collapsible;
		Else
			Items.GroupByProducts_2.Behavior = UsualGroupBehavior.Usual;
		EndIf;
		
		Items.Organization.ReadOnly = SpecifiedOrder;
		Items.CloseOrder.Visible     = Not GroupingByStages;
		
		Items.Department.ReadOnly           = SpecifiedOrder;
		Items.PurchaseForActivity.ReadOnly  = SpecifiedOrder;
		Items.LineOfBusiness.ReadOnly = SpecifiedOrder;
		
		Items.OutputProductsToBeRefilledAccordingToSpecifications.Visible =
			Not GroupingByStages
			And Form.UseProduction;
		
		Items.ByProductsFillTSAccordingToSpecification.Visible =
			Not GroupingByStages
			And Form.UseProduction;
		
		Items.ProvisionOfMaterialsAndWorksForTSAccordingToSpecification.Visible =
			Not GroupingByStages
			And Form.UseProduction;
		
		Items.ServicesFillTSAccordingToSpecification.Visible =
			Form.UseProduction;
		
		Items.ProvisionOfMaterialsAndWorksFillPricesByTypeOfPrices.Visible = Not GroupingByStages;
		
		PriceViewHeader = NStr("vi = 'Dạng đơn giá (sản phẩm/nguyên vật liệu)';
								|ru = 'Вид цены (изделия/материалы)';
								|en = 'Price type (products/materials)'; fa = 'نوع قیمت (محصولات/مواد)';
								|it = 'Tipo di prezzo (prodotto/materiali)';
								|pl = 'Rodzaj ceny (wyroby/materiały)';
								|tr = 'Fiyat türü (nihai ürün/malzeme)'");
		If GroupingByStages Then
			PriceViewHeader = NStr("vi = 'Dạng đơn giá (sản phẩm)';
									|ru = 'Вид цены (изделия)';
									|en = 'Price type (finished products)'; fa = 'نوع قیمت (محصولات نهایی)';
									|it = 'Tipo di prezzo (produzione)';
									|pl = 'Rodzaj ceny (wyroby)';
									|tr = 'Fiyat türü (nihai ürünler)'");
		EndIf;
		
		ElementsPriceView = Items.PriceKind; // FormField
		ElementsPriceView.Title = PriceViewHeader;
		
		Items.DepositValue.Visible =
			Not GroupingByStages;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("GroupCosts") Then
		
		#Region Contract
		
		ArrayOfSelectParameterRelationships = New Array;
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
		
		ArrayOfSelectParameterRelationships.Add(
			New ChoiceParameterLink("Filter.BusinessOperation", "Object.BusinessOperation", LinkedValueChangeMode.DontChange));
		If GroupingByStages Then
			ArrayOfSelectParameterRelationships.Add(
				New ChoiceParameterLink("LineOfBusiness", "Object.LineOfBusiness", LinkedValueChangeMode.Clear));
		EndIf;
		Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
		
		#EndRegion
		Items.LeaveProductsAtSubcontractor.Visible = Not GroupingByStages;
		Items.ProvisionOfMaterialsAndWorksTransferredEarlier.Visible = Not GroupingByStages;
		Items.MethodOfAllocatingFinishedProductCosts.Visible =
			Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.NoGrouping")
			Or Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOM")
			Or Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments");
		
		Items.SupplyWithMaterialsAndWorksIncludedInSet.Visible = GroupingByStages;
		Items.SupplyWithMaterialsAndWorksSupplyAssignment.Visible = GroupingByStages;
		Items.SupplyWithMaterialsAndWorksPurpose.Visible = Not GroupingByStages;
		
		ConfigureCostGroupElements(Form);
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("MaterialsWarehouse")
		Or AttributesList.Property("ProcessingByOrder") Then
		Items.ProvisionOfMaterialsAndWorksToFillWarehouse.Visible =
			Form.WarehouseMaterialsVHF;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ProcessingServices") Then
		
		UseServices = 
			Object.ProcessingServices =
				PredefinedValue("Enum.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder");
		
		Items.PaymentGroup_2.Visible             = UseServices;
		Items.PageGroupAmountOfServices.Visible = UseServices;
		Items.DocumentCurrency.Visible          = UseServices;
		Items.ServicesPage.Visible           = UseServices;
		Items.BankAccount.Visible           = UseServices;
		Items.FinancialAccountingGroup.Visible   = UseServices;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("VATTaxation") Then
		
		If VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Object.VATTaxation) Then
			Items.PageGroupAmountOfServices.CurrentPage = Items.PageVAT;
		Else
			Items.PageGroupAmountOfServices.CurrentPage = Items.PageExcludingVAT;
		EndIf;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("OneDateReceipt") Then
		
		Items.DateOfReceipt.Visible = Object.OneDateReceipt;
		
		Items.OutputProductsFillInReceiptDate.Visible = Not Object.OneDateReceipt;
		Items.ByProductsFillInDateOfReceipt.Visible = Not Object.OneDateReceipt;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("References")
		Or AttributesList.Property("ProcessingByOrder")
		Or AttributesList.Property("LeaveProductsAtSubcontractor") Then
		
		Items.ManufacturedProductsWarehouse.Visible  =
			Not GroupingByStages
			And Not Object.LeaveProductsAtSubcontractor;
		
		Items.MaterialsWarehouse.Visible = Not GroupingByStages;
		
		TitleDateOfReceipt = NStr("vi = 'Ngày tiếp nhận';
									|ru = 'Дату поступления';
									|en = 'Date of receipt'; fa = 'تاریخ دریافت';
									|it = 'La data di arrivo';
									|pl = 'Datę wpływu';
									|tr = 'Giriş tarihini'");
		If GroupingByStages
			Or Object.LeaveProductsAtSubcontractor Then
			TitleDateOfReceipt = NStr("vi = 'Ngày sản xuất';
										|ru = 'Дату производства';
										|en = 'Production date'; fa = 'تاریخ تولید';
										|it = 'Data di produzione';
										|pl = 'Datę produkcji';
										|tr = 'Üretim tarihini'");
		EndIf;
		
		ElementDateOfReceipt = Items.OutputProductsFillInReceiptDate; // FormField
		ElementDateOfReceipt.Title = TitleDateOfReceipt;
		
		ElementDateOfReceipt = Items.ByProductsFillInDateOfReceipt; // FormField
		ElementDateOfReceipt.Title = TitleDateOfReceipt;
		
		Items.RequestedDeliveryDate.Visible =
			Not GroupingByStages;
		
		TitleDesiredReceiptDate = NStr("vi = 'Ngày tiếp nhận dự kiến';
										|ru = 'Желаемая дата поступления';
										|en = 'Requested delivery date'; fa = 'تاریخ تحویل درخواستی';
										|it = 'Data preferibile di arrivo';
										|pl = 'Planowana data wpływu';
										|tr = 'İstenen giriş tarihi'");
		If Object.LeaveProductsAtSubcontractor Then
			TitleDesiredReceiptDate = NStr("vi = 'Ngày sản xuất theo dự kiến';
											|ru = 'Желаемая дата производства';
											|en = 'Requested production date'; fa = 'Requested production date';
											|it = 'Data di produzione auspicabile';
											|pl = 'Pożądana data produkcji';
											|tr = 'İstenen üretim tarihi'");
		EndIf;
		
		ElementDateOfReceipt = Items.RequestedDeliveryDate; // FormField
		ElementDateOfReceipt.Title = TitleDesiredReceiptDate;
		
		TitleDateOfReceipt = NStr("vi = 'Tiếp nhận một ngày';
									|ru = 'Поступление одной датой';
									|en = 'Single day receipt'; fa = 'دریافت یک‌روزه';
									|it = 'Arrivo entro la stessa data';
									|pl = 'Wpływ w jednym dniu';
									|tr = 'Aynı tarihte giriş'");
		If GroupingByStages
			Or Object.LeaveProductsAtSubcontractor Then
			TitleDateOfReceipt = NStr("vi = 'Sản xuất một ngày';
										|ru = 'Производство одной датой';
										|en = 'Production in one day'; fa = 'تولید در یک روز';
										|it = 'Produzione entro la stessa data';
										|pl = 'Produkcja jednego dnia';
										|tr = 'Aynı tarihte üretim'");
		EndIf;
		
		ElementDateOfReceipt = Items.OneDateReceipt; // FormField
		ElementDateOfReceipt.Title = TitleDateOfReceipt;
		
		TitleDateOfReceipt = NStr("vi = 'Ngày tiếp nhận';
									|ru = 'Дату поступления';
									|en = 'Date of receipt'; fa = 'تاریخ دریافت';
									|it = 'La data di arrivo';
									|pl = 'Datę wpływu';
									|tr = 'Giriş tarihini'");
		If GroupingByStages
			Or Object.LeaveProductsAtSubcontractor Then
			TitleDateOfReceipt = NStr("vi = 'Ngày sản xuất';
										|ru = 'Дату производства';
										|en = 'Production date'; fa = 'تاریخ تولید';
										|it = 'Data di produzione';
										|pl = 'Datę produkcji';
										|tr = 'Üretim tarihini'");
		EndIf;
		
		ElementDateOfReceipt = Items.DateOfReceipt; // FormField
		ElementDateOfReceipt.Title = TitleDateOfReceipt;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("NotShipInInstallments") Then
		
		Items.DateOfShipment.Visible = Object.NotShipInInstallments;
		Items.ProvisionOfMaterialsAndWorksOnDateOfShipment.Visible = Not Object.NotShipInInstallments;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("WorkPerformanceAsOneDay") Then
		
		Items.ExecutionDate.Visible = Object.WorkPerformanceAsOneDay;
		Items.ServicesFillInDueDate.Visible = Not Object.WorkPerformanceAsOneDay;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("References") Then
		
		Items.PagesHyperlinkSoftwareStatus.Visible = Form.ThereIsRightToViewStateOfSoftware
			And (Form.DynamicStructure = Undefined Or Not Form.DynamicStructure);
		
		Items.SupportStateGroupDynamicStructure.Visible =
			Form.ThereIsRightToViewStateOfSoftware
			And Form.DynamicStructure <> Undefined
			And Form.DynamicStructure;
		
		Items.SupplyWithMaterialsAndWorksProduced.Visible = 
			Form.DynamicStructure = Undefined Or Not Form.DynamicStructure;
		
		Items.ProvisionOfMaterialsAndWorksShouldBeReservedAsSoonAsTheyAreReceived.Visible =
			Form.DynamicStructure = Undefined Or Not Form.DynamicStructure;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("Partner")
		Or AttributesList.Property("Counterparty") 
		Or AttributesList.Property("Organization") Then
		ConfigureCounterpartyAgreementElement();
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ManufacturedProductsWarehouse") Then
		Items.GroupWarehouseProductsInformation.Visible = ProductWarehouseGroup;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("MaterialsWarehouse") Then
		
		Items.GroupWarehouseMaterialsInformation.Visible = WarehouseMaterialsGroup;
		
		Items.SupplyWithMaterialsAndWorksWarehouse.ChoiceParameters = New FixedArray(New Array);
		TMCommonUseClientServer.AddSelectionParameter(
			Items.SupplyWithMaterialsAndWorksWarehouse,
			"Ref",
			WarehouseSelectionData(Object.MaterialsWarehouse));
		
	EndIf;
	If Initialize
		Or AttributesList.Property("DeletionMark")
		Or AttributesList.Property("ProcessingByOrder") Then
		
		CanEdit1 =
			Not(Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
				And Object.DeletionMark);
		
		EditingIsNotAvailable =
			Not CanEdit1;
		
		Items.ManufacturedProducts.ReadOnly = EditingIsNotAvailable;
		Items.SideAndIntermediateRelease.ReadOnly = EditingIsNotAvailable;
		Items.SupplyWithMaterialsAndWorks.ReadOnly = EditingIsNotAvailable;
		Items.OneDateReceipt.ReadOnly = EditingIsNotAvailable;
		Items.DateOfReceipt.ReadOnly = EditingIsNotAvailable;
		Items.NotShipInInstallments.ReadOnly = EditingIsNotAvailable;
		Items.DateOfShipment.ReadOnly = EditingIsNotAvailable;
		Items.WorkPerformanceAsOneDay.ReadOnly = EditingIsNotAvailable;
		Items.ExecutionDate.ReadOnly = EditingIsNotAvailable;
		
		Items.ManufacturedProductsInsertRows.Enabled = CanEdit1;
		Items.ByProductsInsertRows.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksInsertLines.Enabled = CanEdit1;
		Items.OutputItemsContextMenuInsertLines.Enabled = CanEdit1;
		Items.ByProductsContextMenuInsertLines.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksContextMenuInsertLines.Enabled = CanEdit1;
		
		Items.OutputItemsSplitLine.Enabled = CanEdit1;
		Items.ByProductsSplitString.Enabled = CanEdit1;
		Items.ProvidingMaterialsAndWorksToBreakUpRow.Enabled = CanEdit1;
		Items.OutputItemsContextMenuSplitLine.Enabled = CanEdit1;
		Items.SideProductsContextMenuSplitLine.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksContextMenuSplitLine.Enabled = CanEdit1;
		
		Items.FinishedProductsSearchByBarcode.Enabled = CanEdit1;
		Items.ByProductsBarcodeSearch.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksBarcodeSearch.Enabled = CanEdit1;
		
		Items.ManufacturedProductsPickUpProducts.Enabled = CanEdit1;
		Items.ByProductsPickUpProducts.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksToPickUpGoods.Enabled = CanEdit1;
		
		Items.OutputProductsShouldBeSelectedByStagesOfProduction.Enabled = CanEdit1;
		Items.OutputProductsToBeRefilledAccordingToSpecifications.Enabled = CanEdit1;
		
		Items.ByProductsFillInPricesByPriceType.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksFillPricesByTypeOfPrices.Enabled = CanEdit1;
		
		Items.OutputItemsFillCostGroup.Enabled = CanEdit1;
		Items.ByProductsFillInTheCostGroup.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksToFillCostGroup.Enabled = CanEdit1;
		
		Items.OutputProductsFillInReceiptDate.Enabled = CanEdit1;
		Items.ByProductsFillInDateOfReceipt.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksOnDateOfShipment.Enabled = CanEdit1;
		
		Items.OutputProductsFromRecipient.Enabled = CanEdit1;
		Items.ByProductsFillRecipient.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksToFillWarehouse.Enabled = CanEdit1;
		
		Items.ByProductsFillOutTheCalculationArticle.Enabled = CanEdit1;
		Items.ProvisionOfMaterialsAndWorksToFillArticleCalculation.Enabled = CanEdit1;
		
		Items.OutputItemsUndoHighlightedRows.Enabled = CanEdit1;
		Items.ByProductsUndoHighlightedRows.Enabled = CanEdit1;
		Items.ProvidingMaterialsAndWorksToUndoHighlightedLines.Enabled = CanEdit1;
		
		Items.OutputItemsUndoUndeliveredRows.Enabled = CanEdit1;
		Items.ByProductsCancelUndeliveredStrings.Enabled = CanEdit1;
		Items.ProvidingMaterialsAndWorkToUndoUnprocessedRows.Enabled = CanEdit1;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("References")
		Or AttributesList.Property("ProcessingByOrder") Then
		
		ProductDataManagement.SetSpecificationSelectionParameters(
			Items.SupplyWithMaterialsAndWorksBillOfMaterials,
			BOMSelectionParameters.SupplyWithMaterialsAndWorks);
		
	EndIf;
	If Initialize
		Or AttributesList.Property("Organization")
		Or AttributesList.Property("BusinessOperation")
		Or AttributesList.Property("Partner")
		Or AttributesList.Property("Counterparty")
		Or AttributesList.Property("GroupCosts")
		Or AttributesList.Property("Contract") Then
		SetLBEditingOption();
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	List of Requirements - Line
&AtClientAtServerNoContext
Procedure ConfigureCostGroupElements(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.NoGrouping") Then
		
		GroupTitle =
			ProcessingByThirdPartiesClientServer.CostGroupFieldHeader2_5(
				ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(
					Object.GroupCosts));
		
		Item = Items.ManufacturedProductsExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		Item = Items.SideAndIntermediateReleaseExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		Item = Items.SupplyWithMaterialsAndWorksExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		Item = Items.ServicesExpenseGroup; // FormField
		Item.Title  = GroupTitle;
		
		TooltipTemplate = ProcessingByThirdPartiesClientServer.CostGroupFieldHintTemplate2_5(Object.GroupCosts);
			
		Items.ManufacturedProductsExpenseGroup.ToolTip = StrTemplate(TooltipTemplate, NStr("vi = 'sản phẩm';
																							|ru = 'изделие';
																							|en = 'finished product'; fa = 'finished product';
																							|it = 'prodotto';
																							|pl = 'finished product';
																							|tr = 'nihai ürün'"));
		Items.SideAndIntermediateReleaseExpenseGroup.ToolTip = StrTemplate(TooltipTemplate, NStr("vi = 'sản phẩm';
																								|ru = 'изделие';
																								|en = 'finished product'; fa = 'finished product';
																								|it = 'prodotto';
																								|pl = 'finished product';
																								|tr = 'nihai ürün'"));
		Items.ServicesExpenseGroup.ToolTip          = StrTemplate(TooltipTemplate, NStr("vi = 'dịch vụ';
																						|ru = 'услуга';
																						|en = 'service'; fa = 'service';
																						|it = 'servizio';
																						|pl = 'service';
																						|tr = 'hizmet'"));
		Items.SupplyWithMaterialsAndWorksExpenseGroup.ToolTip = StrTemplate(TooltipTemplate, NStr("vi = 'nguyên vật liệu/công việc';
																									|ru = 'материал/работа';
																									|en = 'material/work'; fa = 'material/work';
																									|it = 'materiale/lavoro';
																									|pl = 'material/work';
																									|tr = 'malzeme/iş'"));
		
	EndIf;
	
	OpenButton =
		Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
	
	Items.ManufacturedProductsExpenseGroup.OpenButton = OpenButton;
	Items.SideAndIntermediateReleaseExpenseGroup.OpenButton = OpenButton;
	Items.ServicesExpenseGroup.OpenButton          = OpenButton;
	Items.SupplyWithMaterialsAndWorksExpenseGroup.OpenButton = OpenButton;
	
EndProcedure

&AtServer
Procedure ConfigureCounterpartyAgreementElement()
	
	ObjectParameters = New Structure("Partner, Counterparty, Organization, Contract");
	FillPropertyValues(ObjectParameters, Object);
	
	PurchasesServer.SetContractAvailability(
		ObjectParameters,
		Items.Contract.Enabled,
		False,
		Object.Contract);
	
EndProcedure

&AtServer
Procedure UpdateOrderInformation()
	
	If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Return;
	EndIf;
	
	ListOfOrders_.Clear();
	
	For Each CurRow In CostGroups Do
		
		PresentationOfOrder = CurRow.ExpenseGroup;
		ListOfOrders_.Add(CurRow.ReferenceOrder, PresentationOfOrder);
		
	EndDo;
	
	RowsArray = New Array;
	
	If ListOfOrders_.Count() = 0 Then
		
		If Not Object.DeletionMark
			And Not ReadOnly Then
			LabelPattern = NStr("vi = 'Thêm công đoạn';
								|ru = 'Добавить этапы';
								|en = 'Add stages'; fa = 'Add stages';
								|it = 'Aggiungere le fasi';
								|pl = 'Dodaj etapy';
								|tr = 'Aşamaları ekle'");
			RowsArray.Add(New FormattedString(LabelPattern,,,, "#AddOrders"));
		EndIf;
		
	ElsIf ListOfOrders_.Count() = 1 Then
		
		LabelPattern = NStr("vi = 'Cơ sở:';
							|ru = 'Основание:';
							|en = 'Base document:'; fa = 'سند مبنا:';
							|it = 'Causale:';
							|pl = 'Podstawa:';
							|tr = 'Temel:'");
		RowsArray.Add(LabelPattern);
		RowsArray.Add(" ");
		
		TextOfOrder = New FormattedString(ListOfOrders_[0].Presentation,,,, GetURL(ListOfOrders_[0].Value));
		RowsArray.Add(TextOfOrder);
		
		RowsArray.Add(" ");
		LabelPattern = NStr("vi = 'thay đổi';
							|ru = 'изменить';
							|en = 'edit'; fa = 'edit';
							|it = 'modificare';
							|pl = 'zmień';
							|tr = 'değiştir'");
		RowsArray.Add(New FormattedString(LabelPattern,,,, "#AddOrders"));
		
	Else
		LabelPattern = NStr("vi = 'Tổng số công đoạn: %1';
							|ru = 'Всего этапов: %1';
							|en = 'Total stages: %1'; fa = 'Total stages: %1';
							|it = 'Totale fasi: %1';
							|pl = 'Łącznie etapów: %1';
							|tr = 'Toplam aşamalar: %1'");
		TextOfOrder = StrTemplate(LabelPattern, Format(ListOfOrders_.Count(), "NG=0"));
		RowsArray.Add(New FormattedString(TextOfOrder,,,, "#AddOrders"));
		
	EndIf;
	
	HeaderOrdersText = New FormattedString(RowsArray);
	
EndProcedure

&AtServer
Procedure UpdateWarehouseGroupImage(WarehouseTable, SeveralWarehousesText, PictureMultipleWarehouses)
	
	TotalWarehouses_ = WarehouseTable.Count();
	WarehousesClientServer.UpdateWarehouseGroupImage(
		SeveralWarehousesText,
		PictureMultipleWarehouses,
		TotalWarehouses_);
	
EndProcedure

&AtServer
Procedure FillInCostGroupingSelectionList()
	
	UsageParameters = Enums.CostGroupingsInTollingOrder.UsageParameters();
	
	UsageParameters.ByProductBOM             = UseProduction;
	
	If GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		UsageParameters.ByProductsAndAssignments     = True;
		UsageParameters.ByProductBOMAndAssignments = UseProduction;
	EndIf;
	
	Enums.CostGroupingsInTollingOrder.FillInSelectionData(
		Items.GroupCosts.ChoiceList,
		UsageParameters);
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	ItemsAvailability - Boolean
&AtClientAtServerNoContext
Procedure ConfigureClipboardCommands(Form, ItemsAvailability)
	
	Items = Form.Items;
	
	Item = Items.ManufacturedProductsInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.OutputItemsContextMenuInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ByProductsInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ByProductsContextMenuInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ProvisionOfMaterialsAndWorksInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ProvisionOfMaterialsAndWorksContextMenuInsertLines; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ServicesInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
	Item = Items.ServicesContextMenuInsertRows; // FormButton
	Item.Enabled = ItemsAvailability;
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisForm);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisForm);
EndProcedure

&AtClient
Procedure RestrictRecipientType(TSName, CurrentData)
	
	RestrictTypeToDivision =
		CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
		Or CurrentData.ToExpenseAs;
	
	Items[TSName + "Recipient"].ChoiceParameters = New FixedArray(New Array);
	If Not RestrictTypeToDivision Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(
			New ChoiceParameter(
				"Filter.Ref",
				New FixedArray(ProductWarehouseSelectionData.UnloadValues())));
		
		NewSelectionOptions = New FixedArray(ChoiceParametersArray);
		
		Items[TSName + "Recipient"].ChoiceParameters = NewSelectionOptions;
		
	EndIf;
	
	Items[TSName + "Recipient"].TypeRestriction =
		?(RestrictTypeToDivision,
			New TypeDescription("CatalogRef.BusinessStructure"),
			New TypeDescription("CatalogRef.Warehouses"));
	
	CurrentData.Recipient = Items[TSName + "Recipient"].TypeRestriction.AdjustValue(CurrentData.Recipient);
	
EndProcedure
&AtClient
Procedure SpecifyTypeOfReasonForCancelingServices(CurrentData)
	
	CurrentData.CancellationReason =
		Items.ServicesCancellationReason.TypeRestriction.AdjustValue(CurrentData.CancellationReason);
	
EndProcedure
&AtServer
Procedure SetLBEditingOption()
	
	LBAvailabilityParameters = LinesOfBusinessServer.ParametersLBEditingCapability();
	
	LBAvailabilityParameters.ThisIsOrder          = True;
	LBAvailabilityParameters.Contract           = Object.Contract;
	LBAvailabilityParameters.ARAPObjectSettings   = Common.ObjectAttributeValue(Object.Contract, "ARAPObjectSettings");
	
	// If the order is in stages, then it is forbidden to change the line of business in it
	LBAvailabilityParameters.OrderAsAProformaInvoice =
		Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	LinesOfBusinessServer.SetLBEditingOption(ThisObject, LBAvailabilityParameters);
	
EndProcedure

#EndRegion

#Region FormEventHandlers

#Region FormEvents

&AtServer
Procedure OnReadCreateAtServer()
	ReadOrderData();
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		UpdateColumnIsAvailableOnServer();
	EndIf;
	FillInServiceDetails();
	FillInDependentServiceAttributes(ThisObject);
	FillInDependentServiceDetailsOnServer();
	FillInServiceDetailsOfTableParts();
	UpdateCostGroups();
	UpdateProductWarehouseTable();
	UpdateInventoryTable();
	
	CustomizeFormElements();
	
	UpdatePurchaseForActivity(, False);
	UpdateVATTaxation_(, False);
	
	GoodsDelivery.WhenReadingCreatingOrdersOnServer(Items, Object);
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	RefreshStatusServer();
	UpdateTextDocumentsBasedOn();
	
	CalculateDocumentTotals(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWriteCompletion(QuestionResult, AdditionalParameters) Export
	
	MaxAdvanceDate = AdditionalParameters.MaxAdvanceDate;
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.OK Then
		ResponseBeforeWrite = True;
		Object.RequestedDeliveryDate = MaxAdvanceDate;
	EndIf;
	
	If Not Object.NotShipInInstallments Then
		
		Cancel = False;
		
		PaymentStepsClient.AskQuestionAboutResettingScheduleONChangesInShippingDate(
			ThisObject,
			New CallbackDescription(
				"BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd", 
				ThisObject, 
				AdditionalParameters),
			Cancel);
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisForm, AdditionalParameters.WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.PaymentScheduleSteps.Clear();
	EndIf;
	ARAPAccountingClient.QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(ThisObject);
	
	BeforeWriteAtClientServer();
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected, TSName)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterSelection(
			ThisForm,
			ValueSelected,
			"HandlingSelectionSelectionOnClientCompletion");
	Else
		ProcessingSelectionOfSelectionOnServer(ValueSelected, TSName);
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlingSelectionSelectionOnClientCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Response = DialogReturnCode.Yes Then
		Object.NotShipInInstallments = False;
		ConfigureDependentFormElements(ThisForm, "NotShipInInstallments");
	EndIf;
	
	ProcessingSelectionOfSelectionOnServer(AdditionalParameters, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected, TSName)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	DocumentTable = Object[TSName]; // FormDataCollection
	
	If TSName = "ManufacturedProducts" Then
		ListOfProperties = "Products, Characteristic, Package, NumberOfPackages";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		ListOfProperties = "Products, Characteristic, Package, Price, NumberOfPackages";
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		ListOfProperties = "Products, Characteristic, Package, Warehouse, Price, NumberOfPackages, DeliveryPeriodDays,
						|SupplyOption, WithAssignment, Series, DateOfShipment";
	ElsIf TSName = "Services" Then
		ListOfProperties = "Products, Characteristic, VendorPriceKind, Price, Count";
	EndIf;
	
	BegOfDay = BegOfDay(CurrentSessionDate());
	
	ChangedDimensions_ = New Array;
	NewGroupings = New Array;
	DimensionsToFillIn = New Array;
	RowsToProcess = New Array;
	ProductData_2 = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentData = DocumentTable.Add();
		FillPropertyValues(CurrentData, RowOfProduct, ListOfProperties);
		RowsToProcess.Add(CurrentData);
		
		FillDateInTSLineWithTotalDate(ThisObject, TSName, CurrentData);
		
		If TSName = "ManufacturedProducts"
				And Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
			Or TSName = "SupplyWithMaterialsAndWorks"
				And CurrentData.Produced Then
			
			ProductData_2.Add(
				ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, CurrentData, BOMSelectionParameters[TSName], ThisObject));
			
		EndIf;
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActions);
	AddActionsCheckFillWarehouse(ThisObject, TSName, StructureOfActions);
	AddCollateralActions(ThisObject, TSName, StructureOfActions, "WarehouseIsRequired,DateOfShipmentRequired_");
	AddActionsFillInPriceView(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	AddActionsInitializeArticleAndAnalytics(ThisObject, TSName, StructureOfActions);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert(
			"CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
				Object.MaterialsWarehouse, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, RowsToProcess));
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		DocumentTable,
		CachedValues);
	
	If TSName = "ManufacturedProducts"
			And Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		Or TSName = "SupplyWithMaterialsAndWorks"
			And CurrentData.Produced Then
		
		ProductDataManagement.FillInSpecificationInLines(
			RowsToProcess, ProductData_2, BOMSelectionParameters[TSName]);
		
	EndIf;
	
	For Each CurrentData In RowsToProcess Do
		
		If TSName = "ManufacturedProducts" Then
			
			NumberOfGroupsBeforeChange = CostGroups.Count();
			If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				AddChangeCostGroup(CurrentData, True);
			Else
				SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			EndIf;
			ChangedDimensions_.Add(CurrentData.CostGroupNumber);
			
			If Not NumberOfGroupsBeforeChange = CostGroups.Count() Then
				NewGroupings.Add(CurrentData.CostGroupNumber);
			EndIf;
			
		EndIf;
		
		If Not TSName = "ManufacturedProducts" Then
			
			SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			
			If TSName = "SupplyWithMaterialsAndWorks" Then
				
				CurrentData.DateOfShipment =
					ProvisionInDocumentsServer.ShipmentDateProcessingSelectionSelection(
						RowOfProduct.DateOfShipment,
						CurrentData.SupplyOption,
						BegOfDay);
				
			EndIf;
			
		EndIf;
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
	EndDo;
	
	If TSName = "ManufacturedProducts" Then
		ReFillAccordingToSpecificationsOnServer(NewGroupings);
		CalculatePercentageOfCostAllocationForOutputProducts(ChangedDimensions_);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		ProvisionInDocumentsServer.UpdateShipmentDateWithSingleDate(
			Object.NotShipInInstallments,
			Object.DateOfShipment,
			Object.SupplyWithMaterialsAndWorks,
			"DateOfShipment");
		
		UpdateColumnIsAvailableOnServer();
		FillInDependentServiceDetailsSupply(ThisForm);
		
	EndIf;
	
	If Not DimensionsToFillIn.Count() = 0 Then
		For Each CurGroup In DimensionsToFillIn Do
			TableFillInDependentServiceDetailsOfCostGroup(TSName, CurGroup);
		EndDo;
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		AttributesList = "NumberOfProducts, AmountOfServices, DepositValue";
	ElsIf TSName = "SideAndIntermediateRelease" Then
		AttributesList = "NumberOfProducts";
	ElsIf TSName = "Services" Then
		AttributesList = "AmountOfServices";
	Else
		AttributesList = "DepositValue";
	EndIf;
	
	CalculateDocumentTotals(ThisForm, AttributesList);
	
EndProcedure

&AtServer
Procedure CheckComplianceOfUnitWithOrders(OrderData_3, Cancel)

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TableStages.Department.Presentation AS DepartmentPresentation
	|FROM
	|	Document.ProductionStage2_2 AS TableStages
	|WHERE
	|	TableStages.Ref IN (&References)
	|	AND NOT TableStages.Department = &Department
	|";
	
	Query.SetParameter("References",  OrderData_3.Attributes.UnloadColumn("Ref"));
	Query.SetParameter("Department", Object.Department);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		MessageText = StrTemplate(NStr("vi = 'Bộ phận phải tương ứng với bộ phận của công đoạn ""%1""';
										|ru = 'Подразделение должно соответствовать подразделению этапа ""%1""';
										|en = 'Business unit should conform to the business unit of stage ""%1""'; fa = 'Business unit should conform to the business unit of stage ""%1""';
										|it = 'Il reparto deve corrispondere al reparto della fase ""%1""';
										|pl = 'Dział powinien odpowiadać działowi etapu ""%1""';
										|tr = 'Departman, ""%1"" aşamasındaki departmanla eşleşmelidir'"), Selection.DepartmentPresentation);
		Common.MessageToUser(MessageText, Object.Ref, "Department", , Cancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckSharesOfCostOfOutputProducts(OrderData_3, Cancel)
	
	StageCostAllocationParameters = Documents.ProductionStage2_2.CostAllocationParameters(
		Documents.ProductionStage2_2.EmptyRef());
	
	LinkFields        = StageCostAllocationParameters.LinkFields;
	CostGroupField_ = "ProductionLot";
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text =
		Documents.ProductionStage2_2.QueryTextCheckCOSTShares(
			OrderData_3,
			LinkFields,
			CostGroupField_);
	
	Query.SetParameter("SourceTable1", OrderData_3.ManufacturedProducts);
	
	ResultsArray = Query.ExecuteBatch();
	
	Result = ResultsArray[ResultsArray.UBound()];
	If Not Result.IsEmpty() Then
		
		MessageText = NStr("vi = 'Mục tin ""Phương pháp phân bổ chi phí cho sản phẩm đầu ra""
									|phải có giá trị như nhau đối với tất cả công đoạn xuất xưởng lô hàng:
									|%1';
									|ru = 'Реквизит ""Способ распределения затрат на выходные изделия""
									|должен иметь одинаковое значение для всех выпускающих этапов партии:
									|%1';
									|en = 'The ""Method of allocating finished product costs"" attribute
									|must have the same value for all lot release stages:
									|%1'; fa = 'The ""Method of allocating finished product costs"" attribute
									|must have the same value for all lot release stages:
									|%1';
									|it = 'Il requisito ""Metodo di allocazione dei costi di prodotti in uscita""
									|deve avere lo stesso valore per tutte le fasi produttive del lotto:
									|%1';
									|pl = 'Rekwizyt ""Sposób podziału kosztów na produkowane wyroby""
									|musi mieć taką samą wartość dla wszystkich produkujących etapów partii:
									|%1';
									|tr = '""Üretilen nihai ürünlere yönelik maliyet dağıtım yöntemi"" özniteliği,
									|lotun tüm ürün çıkış aşamaları için aynı değere sahip olmalıdır:
									|%1'");
		
		PartyMessageText = "";
		
		Selection = Result.Select();
		While Selection.Next() Do
			PartyMessageText =
				PartyMessageText + Chars.LF + "%1";
			PartyMessageText = StrTemplate(PartyMessageText, Selection.ProductionLot);
		EndDo;
		
		MessageText = StrTemplate(MessageText, PartyMessageText);
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
	Result = ResultsArray[ResultsArray.UBound() - 1];
	If Not Result.IsEmpty() Then
		
		Template = NStr("vi = 'Khi xuất xưởng một số mặt hàng của sản phẩm đầu ra, cần phải chỉ ra tỷ lệ giá trị của chúng (dòng %1 %2).';
						|ru = 'При выпуске нескольких наименований выходных изделий требуется указать их долю стоимости (строка %1%2).';
						|en = 'When releasing several names of finished products, you should specify their cost share (line %1%2).'; fa = 'When releasing several names of finished products, you should specify their cost share (line %1%2).';
						|it = 'In caso di emissione di diversi tipi di prodotti è necessario indicare la loro parte nel costo (riga %1%2).';
						|pl = 'W wypadku produkcji kilku pozycji produktów wychodzących trzeba wskazać ich udział wartości (wiersz %1%2).';
						|tr = 'Üretilen nihai ürünlerin birden fazla öğesinin çıkışı esnasında, bunların maliyet paylarının belirtilmesi gerekmektedir (%2%1 satırı).'");
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			LineNumber    = Format(Selection.LineNumber, "NG=");
			MessageText = StrTemplate(Template, LineNumber, ?(Selection.Ref = Undefined, "", ", " + Selection.Ref));
			
			Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", Selection.LineNumber, "CostShare");
			
			Common.MessageToUser(
				MessageText,
				Selection.Ref,
				Field,
				?(Selection.Ref = Undefined, "Object", ""),
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormItems

#Region IsMain

&AtServer
Procedure StatusChangedOnServer()
	
	If Object.Status = PredefinedValue("Enum.TollingOrderStatuses.ForFulfillment")
		Or Object.Status = PredefinedValue("Enum.TollingOrderStatuses.Closed") Then
		
		If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			FillInReceiptDateWithDesiredDateOnServer();
		EndIf;
		
		FillInEmptyDatesOfWorkOnServer();
		
	EndIf;
	
	If QualityControl.UpdateActionParameters(Documents.SubcontractOrder2_5, Object, CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "Status");
	
	FillInDependentServiceDetailsSupply(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfOrders()
	
	FormParameters = New Structure("Organization, Partner, Department, LineOfBusiness");
	FillPropertyValues(FormParameters, Object);
	
	FormParameters.Insert("ProcessorOrder",       Object.Ref);
	FormParameters.Insert("OrderReferences",       ListOfOrders_);
	FormParameters.Insert("PurchaseForActivity",   Object.PurchaseForActivity);
	FormParameters.Insert("ReadOnly",           ReadOnly);
	FormParameters.Insert("CannotSelectNewStages", Object.DeletionMark);
	FormParameters.Insert("DynamicStructure",    DynamicStructure);
	
	CallbackDescription = New CallbackDescription("OpenSelectionOfOrdersCompletion", ThisForm);
	OpenForm("Document.SubcontractOrder2_5.Form.SelectionOfReferences", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfOrdersCompletion(FillingData, AdditionalParameters) Export

	If Not FillingData = Undefined Then
		OpenSelectionOfCompletionOrdersOnServer(FillingData);
	EndIf;
	
EndProcedure

&AtServer
Procedure OpenSelectionOfCompletionOrdersOnServer(FillingData)
	
	ChangesTakenIntoAccount = New Structure;
	
	If Not ValueIsFilled(Object.Organization)
		And ValueIsFilled(FillingData.HeaderAttributes.Organization) Then
		Object.Organization = FillingData.HeaderAttributes.Organization;
		OrganizationWhenChangedOnServer(ChangesTakenIntoAccount);
	EndIf;
	
	If Not ValueIsFilled(Object.Partner)
		And ValueIsFilled(FillingData.HeaderAttributes.Partner) Then
		Object.Partner = FillingData.HeaderAttributes.Partner;
		PartnerWhenChangesAreMadeOnServer(ChangesTakenIntoAccount);
	EndIf;
	
	If Not ValueIsFilled(Object.Department)
		And ValueIsFilled(FillingData.HeaderAttributes.Department) Then
		Object.Department = FillingData.HeaderAttributes.Department;
	EndIf;
	
	If Not ValueIsFilled(Object.PurchaseForActivity)
		And ValueIsFilled(FillingData.HeaderAttributes.PurchaseForActivity) Then
		Object.PurchaseForActivity = FillingData.HeaderAttributes.PurchaseForActivity;
	EndIf;
	
	If Not ValueIsFilled(Object.LineOfBusiness)
		And ValueIsFilled(FillingData.HeaderAttributes.LineOfBusiness) Then
		Object.LineOfBusiness = FillingData.HeaderAttributes.LineOfBusiness;
		DirectionOfActivityWhenChangingOnServer(ChangesTakenIntoAccount);
	EndIf;
	
	// We will clear the excluded orders
	RemovalInstructions = New Array;
	For Each CurrentData In Object.References Do
		
		If Not FillingData.References.Find(CurrentData.ReferenceOrder) = Undefined Then
			Continue;
		EndIf;
		
		RemovalInstructions.Add(CurrentData);
		
		ClearTSByCostGroup("ManufacturedProducts", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("SideAndIntermediateRelease", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("SupplyWithMaterialsAndWorks", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("MaterialsAndWorksSets", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("Services", CurrentData.CostGroupNumber);
		
	EndDo;
	
	For Each CurrentData In RemovalInstructions Do
		Object.References.Delete(CurrentData);
	EndDo;
	
	// We will add new orders
	NewOrders = New Array;
	ListOfGroups = New Array;
	For Each ReferenceOrder In FillingData.References Do
		
		FilterStructure1 = New Structure("ReferenceOrder", ReferenceOrder);
		
		FoundRows = Object.References.FindRows(FilterStructure1);
		If FoundRows.Count() = 0 Then
			
			Object.MaximumNumberOfCostGroup = 
				Object.MaximumNumberOfCostGroup + 1;
			
			NewRow = Object.References.Add();
			NewRow.ReferenceOrder = ReferenceOrder;
			NewRow.CostGroupNumber = Object.MaximumNumberOfCostGroup;
			
			NewOrders.Add(ReferenceOrder);
			ListOfGroups.Add(NewRow.CostGroupNumber);
			
		EndIf;
		
	EndDo;
	
	If Not NewOrders.Count() = 0 Then
		
		ReadOrderData(NewOrders);
		FillInServiceDetailsOfTableParts("References, ManufacturedProducts, SideAndIntermediateRelease, SupplyWithMaterialsAndWorks");
		UpdateCostGroups();
		
		ProcessedLinesOutputProducts = New Array;
		ProcessedStringsByProducts = New Array;
		For Each CurrentOrder In NewOrders Do
			
			FilterStructure1 = New Structure("ReferenceOrder", CurrentOrder);
			
			For Each CurrentData In Object.ManufacturedProducts.FindRows(FilterStructure1) Do
				ProcessedLinesOutputProducts.Add(CurrentData);
			EndDo;
			
			For Each CurrentData In Object.SideAndIntermediateRelease.FindRows(FilterStructure1) Do
				ProcessedStringsByProducts.Add(CurrentData);
			EndDo;
			
		EndDo;
		
		If ValueIsFilled(ProcessedLinesOutputProducts) Then
			StructureOfActions = New Structure;
			AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
			BatchProcessingOfTablePartServer.ProcessTSStrings(ProcessedLinesOutputProducts, StructureOfActions, Object.ManufacturedProducts);
		EndIf;
		
		If ValueIsFilled(ProcessedStringsByProducts) Then
			StructureOfActions = New Structure;
			AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
			BatchProcessingOfTablePartServer.ProcessTSStrings(ProcessedStringsByProducts, StructureOfActions, Object.SideAndIntermediateRelease);
		EndIf;
		
		ReFillAccordingToSpecificationsOnServer(ListOfGroups, "Services");
		FillInServiceDetailsOfTableParts("Services");
		
		ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisForm); // stages have been added, you need to get the leftovers again
		
		// ItemsAndDimensionsSelectionParameters
		ItemsAndDimensionsSelectionParameters = Documents.SubcontractOrder2_5.ItemsAndDimensionsSelectionParameters();
		IncomeAndExpensesServer.OnReadAtServer(ThisForm, ItemsAndDimensionsSelectionParameters);
		// End ItemsAndDimensionsSelectionParameters
		
	Else
		UpdateCostGroups();
	EndIf;
	
	FillInDependentServiceDetailsOnServer("References");
	
	UpdateOrderInformation();
	CalculateDocumentTotals(ThisForm);
	ConfigureDependentFormElements(ThisForm, "References");
	ConfigureDependentFormElementsOnServer("References");
	Modified = True;
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	UpdatePurchaseForActivity();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	
	If Not ValueIsFilled(Object.Partner) Then
		GoodsDeliveryClientServer.ClearDeliveryDetails(Items, Object);
		Return;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	If TheCounterpartyPriorToTheChange <> Object.Counterparty Then
		FillInDefaultContract(ChangesTakenIntoAccount);
	EndIf;
	
	CounterpartyWhenChangesAreMadeOnServer(ChangesTakenIntoAccount);
	AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	
	FillInDependentServiceDetailsOnServer("Partner");
	FillInDeliveryDetailsOnServer("Partner");
	
	GroupingByStages = False;
	GroupingByStages =
		Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
	SpecifiedOrder =
		GroupingByStages
		And Not Object.References.Count() = 0;
	
	If UseLinesOfBusiness
		And Not ChangesTakenIntoAccount.Property("LineOfBusiness")
		And Not SpecifiedOrder Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, , Object.Contract);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("PurchaseForActivity") Then
		UpdatePurchaseForActivity(ChangesTakenIntoAccount);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("VATTaxation") Then
		UpdateVATTaxation_(ChangesTakenIntoAccount);
	EndIf;
	
	ConfigureDependentFormElementsOnServer("Partner");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Partner");
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisForm);
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("Counterparty") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract(ChangesTakenIntoAccount);
	EndIf;
	
	AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	ConfigureDependentFormElementsOnServer("Counterparty");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisForm);
	
	ChangesTakenIntoAccount.Insert("Counterparty");
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer(ChangesTakenIntoAccount = Undefined, DirectModificationOfContractField = False)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("Contract") Then
		Return;
	EndIf;
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	ContractDetails_ = "Department, Manager, ContactPerson";
	ContractDetails_ = New Structure(ContractDetails_);
	ContractDetails_.Insert("Currency", "ARAPCurrency");
	ContractDetails_.Insert("ForeignCurrencyTransaction");
	
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, ContractDetails_);
	For Each CurrentAttribute In ContractDetails_ Do
		If ValueIsFilled(CurrentAttribute.Value)
			And (Not CurrentAttribute.Key = "Department"
				Or CurrentAttribute.Key = "Department"
					And (Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
						Or Object.References.Count() = 0)) Then
			Object[CurrentAttribute.Key] = CurrentAttribute.Value;
		EndIf;
	EndDo;
	
	If Not DocumentCurrency = Object.Currency Then
		ConvertDocumentAmountsToCurrency();
		DocumentCurrency = Object.Currency;
	EndIf;
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	
	If Not ValueIsFilled(Object.BankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	GroupingByStages = False;
	GroupingByStages =
		Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
	SpecifiedOrder =
		GroupingByStages
		And Not Object.References.Count() = 0;
	
	If UseLinesOfBusiness
		And Not ChangesTakenIntoAccount.Property("LineOfBusiness")
		And Not SpecifiedOrder Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, , Object.Contract);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("PurchaseForActivity") Then
		UpdatePurchaseForActivity(ChangesTakenIntoAccount);
	EndIf;
	
	ContractDetails_ = "ContractType, PurchaseRegistrationOption";
	ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, ContractDetails_);
	Object.BusinessOperation = Catalogs.CounterpartyContracts.BusinessOperation(ContractDetails_.ContractType, ContractDetails_.PurchaseRegistrationOption);
	If Not ValueIsFilled(Object.BusinessOperation) Then
		Object.BusinessOperation = Enums.BusinessTransactions.ProductionByToller2_5;
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("VATTaxation") Then
		UpdateVATTaxation_(ChangesTakenIntoAccount);
	EndIf;
	
	ConfigureCounterpartyAgreementElement();
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	ConfigureDependentFormElementsOnServer("Contract");
	
	If QualityControl.UpdateActionParameters(
			Documents.SubcontractOrder2_5,
			Object,
			CacheQualityControl,
			DirectModificationOfContractField) Then
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisObject);
	
	UpdateTextDocumentsBasedOn();
	
	ChangesTakenIntoAccount.Insert("Contract");
	
EndProcedure

&AtServer
Procedure BusinessOperationWhenChangingOnServer()
	
	ConfigureDependentFormElementsOnServer("BusinessOperation");
	
	UpdateTextDocumentsBasedOn();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("Organization") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract(ChangesTakenIntoAccount);
	EndIf;
	
	AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	
	CashServer.CheckFillInOrganizationSBankAccountByOwner(
		Object.Organization, 
		Object.BankAccount, 
		Object.PaymentMethod, 
		Object.LineOfBusiness,
		Object.ForeignCurrencyTransaction);
	
	CashServer.CheckOrganizationSSalesRegisterByOwner(
		Object.Organization, 
		Object.CashAccount, 
		Object.PaymentMethod, 
		Object.LineOfBusiness);
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisForm);
	
	ConfigureDependentFormElementsOnServer("Organization");
	
	ChangesTakenIntoAccount.Insert("Organization");
	
EndProcedure

&AtServer
Procedure RecyclingServicesWhenChangesAreMadeOnServer()
	
	UseServices = 
		Object.ProcessingServices =
			PredefinedValue("Enum.OptionsOfRegisteringProcessingDocumentServices.SpecifiedInOrder");
	
	If Not UseServices Then
		
		Object.Services.Clear();
		Object.PaymentScheduleSteps.Clear();
		Object.BankAccount = PredefinedValue("Catalog.CompaniesBankAccounts.EmptyRef");
		Object.FinancialAccountingGroup = PredefinedValue("Catalog.FinancialAccountingGroupsOfARAP.EmptyRef");
		
		CalculateDocumentTotals(ThisForm, "AmountOfServices");
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "ProcessingServices");
	
EndProcedure

&AtServer
Procedure MethodForAllocatingCostsForOutputProductsWhenChangingOnServer()
	
	CostAllocationParametersStructure = Documents.SubcontractOrder2_5.CostAllocationParameters(Object);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	If Object.GroupCosts <> Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	EndIf;
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtServer
Procedure ProductWarehouseWhenChangedOnServer()
	
	FillInDependentServiceDetailsOnServer("ManufacturedProductsWarehouse");
	ConfigureDependentFormElements(ThisForm, "ManufacturedProductsWarehouse");
	ConfigureDependentFormElementsOnServer("ManufacturedProductsWarehouse");
	
	ParametersForFillingTSWarehouse = ParametersForFillingTSWarehouse("ManufacturedProducts");
	FillTSWarehouseOnServer(ParametersForFillingTSWarehouse);
	
	ParametersForFillingTSWarehouse.TSName = "SideAndIntermediateRelease";
	FillTSWarehouseOnServer(ParametersForFillingTSWarehouse);
	
	UpdateProductWarehouseTable();
	UpdateWarehouseGroupImage(
		TableOfProductWarehouses,
		InscriptionSeveralWarehousesOfProduct,
		Items.ThereAreSeveralWarehousesWares);
	
EndProcedure

&AtServer
Procedure StorageOfMaterialsWhenChangingOnServer()
	
	FillInDependentServiceDetailsOnServer("MaterialsWarehouse");
	ConfigureDependentFormElements(ThisForm, "MaterialsWarehouse");
	ConfigureDependentFormElementsOnServer("MaterialsWarehouse");
	
	ParametersForFillingTSWarehouse = ParametersForFillingTSWarehouse("SupplyWithMaterialsAndWorks");
	FillTSWarehouseOnServer(ParametersForFillingTSWarehouse);
	
	UpdateInventoryTable();
	UpdateWarehouseGroupImage(
		TableOfWarehousesMaterials,
		InscriptionSeveralWarehousesMaterials,
		Items.ThereAreSeveralWarehousesMaterials);
	
EndProcedure

&AtClient
Procedure GroupCostsOnChangeCompletion(Response, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractOrder2_5.Form.DocumentForm.GroupCostsOnChange");
	
	If Response = DialogReturnCode.Yes Then
		GroupingCostsForChangesOnServer();
	Else
		Object.GroupCosts = GroupCostsBeforeChange;
	EndIf;
	
EndProcedure
&AtServer
Procedure GroupingCostsForChangesOnServer()
	
	If Not ValueIsFilled(Object.GroupCosts) Then
		Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping;
	EndIf;
	Object.ProcessingByOrder =
		Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages;
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Or GroupCostsBeforeChange = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Object.References.Clear();
		ListOfOrders_.Clear();
		Object.ManufacturedProducts.Clear();
		Object.SideAndIntermediateRelease.Clear();
		Object.SupplyWithMaterialsAndWorks.Clear();
		Object.Services.Clear();
	EndIf;
	CostGroups.Clear();
	Object.MaximumNumberOfCostGroup = 0;
	NumberOfCostGroups = 0;
	
	For Each CurrentData In Object.ManufacturedProducts Do
		AddChangeCostGroup(CurrentData, True);
	EndDo;
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.NoGrouping Then
		CostGroupIndex = 1;
	ElsIf NumberOfCostGroups = 1 Then
		CostGroupIndex = Object.MaximumNumberOfCostGroup;
	Else
		CostGroupIndex = 0;
	EndIf;
	
	For Each CurrentData In Object.SideAndIntermediateRelease Do
		CurrentData.CostGroupNumber = CostGroupIndex;
		CurrentData.ExpenseGroup = "";
	EndDo;
	
	UpdateDependentDetails = False;
	For Each CurrentData In Object.SupplyWithMaterialsAndWorks Do
		
		CurrentData.CostGroupNumber = CostGroupIndex;
		CurrentData.ExpenseGroup = "";
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And (Not CurrentData.Price = 0
				Or Not CurrentData.Sum = 0) Then
			
			CurrentData.Price = 0;
			CurrentData.Sum = 0;
			
			UpdateDependentDetails = True;
			
		EndIf;
	EndDo;
	
	For Each CurrentData In Object.Services Do
		CurrentData.CostGroupNumber = CostGroupIndex;
		CurrentData.ExpenseGroup = "";
	EndDo;
	
	For Each CurGroup In CostGroups Do
		TableFillInDependentServiceDetailsOfCostGroup("ManufacturedProducts", CurGroup.CostGroupNumber);
	EndDo;
	
	UpdateCostGroupPresentation();
	
	If UpdateDependentDetails Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails("SupplyWithMaterialsAndWorks"));
		BatchProcessingOfTablePartServer.TreatTS(Object.SupplyWithMaterialsAndWorks, StructureOfActions, Undefined);
	EndIf;
	
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProducts
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductsAndAssignments Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.EmptyRef();
	ElsIf Not ValueIsFilled(Object.MethodOfAllocatingFinishedProductCosts) Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
	FillInDependentServiceAttributes(ThisForm, "GroupCosts,ProcessingByOrder,References");
	FillInDependentServiceDetailsOnServer("GroupCosts,ProcessingByOrder,References");
	ConfigureDependentFormElements(ThisForm, "GroupCosts,ProcessingByOrder,References");
	ConfigureDependentFormElementsOnServer("GroupCosts,ProcessingByOrder,References");
	
	UpdateOrderInformation();
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisForm);
	
	CalculateDocumentTotals(ThisForm);
	
	GroupCostsBeforeChange = Object.GroupCosts;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		PaymentStagesForChangesOnServer(ChangedBankingDetails);
	EndIf;
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure OpenCostShareEntryForm(CurrentData, StandardProcessing)
	
	If Not Object.GroupCosts =
				PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		If Object.MethodOfAllocatingFinishedProductCosts =
				PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
			Return;
		EndIf;
	EndIf;
	
	StandardProcessing = False;
	
	NoErrors_ = ProductionClient.CheckFillingBeforeEnteringCostFraction(CurrentData, CostAllocationParameters);
	
	If NoErrors_ Then
		
		FormParameters =
			ParametersOfCostShareEntryForm_(
				CostAllocationParameters,
				CurrentData.GetID());
		
		OpenForm(
			"CommonForm.EnterCostShare",
			FormParameters,
			ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(Item, CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(CurrentData, ValueSelected);
		
		Groups = New Array;
		Groups.Add(CurrentData.CostGroupNumber);
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SupplyWithMaterialsAndWorks

#Region Supply

&AtClient
Procedure Attachable_WhenChangingModifiabilityOfForm()
	
	If FormModified <> Modified Then
		ProvisionInDocumentsClient.ConfigureHyperlinkedSoftwareState(ThisForm);
		FormModified = Modified;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_CheckCompletionOfInventoryAllocationTask()
	
	Error = False;
	If ProvisionInDocumentsClient.NeedToUpdateAvailabilityAfterRecording(ThisObject,
		"Attachable_CheckCompletionOfInventoryAllocationTask", Error) Then
		ProvisionInDocumentsClient.ConfigureHyperlinksSupplyForecastAfterRecording(ThisObject, Error);
		UpdateColumn = ProvisionInDocumentsClient.ToUpdateColumnAvailableAfterInventoryAllocation(ThisObject);
		If UpdateColumn Then
			UpdateColumnAvailableAfterInventoryAllocation();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableAfterInventoryAllocation()
	ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisObject);
EndProcedure

&AtServer
Procedure Attachable_CheckCompletionOfInventoryAllocationTaskOnServer()
	
	ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisForm);
	ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisForm);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionOnChangeCompletion(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	ProvisionOfMaterialsAndWorksSoftwareOptionWhenChangedOnServer(FillParameters);
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksSoftwareOptionWhenChangedOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisForm,
		Items.SupplyWithMaterialsAndWorks.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(CurDataId);
	OpenSelectionOfSeries(, CurrentData);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	FormParameters =
		ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.SeriesSelectionMode());
	
	If FormParameters <> Undefined Then
		
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisForm, FormParameters));
			
	EndIf;
	
EndProcedure

&AtServer
Function ThereAreFilledSeriesByFEFO()
	
	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.SupplyWithMaterialsAndWorks);
	
EndFunction

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;
	
EndProcedure

&AtServer
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.SupplyWithMaterialsAndWorks) Then
		
		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);	
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region More

&AtClient
Procedure IncomingDocumentNumberTextEditEndCompletion(QuestionResult, AdditionalParameters) Export
	
	ListOfOrdersByNumber = AdditionalParameters.OrderList;
	
	If QuestionResult = "OpenOrderList" Then
		If ListOfOrdersByNumber.Count() > 1 Then
			FormParameters = New Structure;
			FormParameters.Insert("DocumentsList", ListOfOrdersByNumber);
			FormParameters.Insert("Title", NStr("vi = 'Đơn đặt hàng gia công (%DocumentsCount%)';
												|ru = 'Заказы переработчикам (%DocumentsCount%)';
												|en = 'Subcontracting purchase orders (%DocumentsCount%)'; fa = 'Subcontracting purchase orders (%DocumentsCount%)';
												|it = 'Ordini ai trasformatori (%DocumentsCount%)';
												|pl = 'Zamówienia dla przetwórców (%DocumentsCount%)';
												|tr = 'Fason üretici satın alma siparişleri (%DocumentsCount%)'"));
			OpenForm("CommonForm.ViewingListOfDocuments", FormParameters);
		Else
			FormParameters = New Structure("Key", ListOfOrdersByNumber.Get(0).Value);
			OpenForm("Document.SubcontractOrder2_5.ObjectForm", FormParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionRecalculateAmountsEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CurrencyOnChangeCompletion(True);
	Else
		CurrencyOnChangeCompletion(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChangeCompletion(RecalculateAmounts)
	
	CurrencyWhenChangedOnServer(RecalculateAmounts);
	
	If RecalculateAmounts Then
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure CurrencyWhenChangedOnServer(RecalculateAmounts)
	
	FillInDefaultContract(Undefined);
	
	If RecalculateAmounts Then
		ConvertDocumentAmountsToCurrency();
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Currency");
	
EndProcedure

&AtServer
Procedure PriceIncludesVATWhenChangedOnServer(CachedValues)
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisForm, "Services", StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, CachedValues);
	
	FillInDependentServiceDetailsOnServer("PriceIncludesVAT");
	
	CalculateDocumentTotals(ThisForm, "AmountOfServices");
	
EndProcedure

&AtServer
Procedure TaxationOfVATWhenChangingOnServer()
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	AddActionsForRecalculatingAmounts(ThisForm, "Services", StructureOfActions);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisForm,
		"Products",
		StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Services, StructureOfActions, Undefined);
	
	CalculateDocumentTotals(ThisForm, "AmountOfServices");
	
	ConfigureDependentFormElements(ThisForm, "VATTaxation");
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		// &PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.SubcontractOrder2_5.Form.DocumentForm.PriceKindOnChange");
		
		PricesCalculated = ViewOfPriceWhenChangingEndOnServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
		
	EndIf;
	
EndProcedure

&AtServer
Function ViewOfPriceWhenChangingEndOnServer()
	
	PricesCalculated = FillInPricesByPriceKindServer("SideAndIntermediateRelease");
	PricesCalculated = FillInPricesByPriceKindServer("SupplyWithMaterialsAndWorks") Or PricesCalculated;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer(ChangesTakenIntoAccount = Undefined)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	If ChangesTakenIntoAccount.Property("LineOfBusiness") Then
		Return;
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("PurchaseForActivity") Then
		UpdatePurchaseForActivity(ChangesTakenIntoAccount);
	EndIf;
	
	If Not ChangesTakenIntoAccount.Property("VATTaxation") Then
		UpdateVATTaxation_(ChangesTakenIntoAccount);
	EndIf;
	
	ProcessChangeOfDirection(ChangesTakenIntoAccount);
	
	ProvisionInDocumentsServer.WhenChangingDocumentDetails(ThisForm);
	
	ChangesTakenIntoAccount.Insert("LineOfBusiness");
	
EndProcedure

&AtServer
Procedure ApprovalDateForChangesOnServer()
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "ApprovalDate");
EndProcedure

#EndRegion

#Region Delivery

&AtServer
Procedure SpecialTransportationConditionsOnChangeServer()
	
	GoodsDelivery.SpecialTransportationConditionsOnChange(Items, Object);
	
EndProcedure

&AtServer
Procedure SupplementDeliveryInformationWithContactsServer()
	
	GoodsDelivery.SupplementDeliveryInformationWithContacts(Object);
	
EndProcedure

#EndRegion

#Region CostGroups

&AtClient
Procedure TableCostGroupStartOfSelectionCompletion(Result, TSName) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	TableCostGroupStartSelectionEndOnServer(Result, TSName, Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure TableCostGroupStartSelectionEndOnServer(Result, TSName, Val SelectedRows)

	If TableCostGroupStartSelectionCheckResult(Result, TSName) Then
		Return;
	EndIf;
	
	Groups = New Array;
	Groups.Add(Result.CostGroupNumber);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	
	For Each RowID In SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(RowID);
		
		If Groups.Find(CurrentData.CostGroupNumber) = Undefined Then
			Groups.Add(CurrentData.CostGroupNumber);
		EndIf;
		
		CurrentData.CostGroupNumber = Result.CostGroupNumber;
		CurrentData.ExpenseGroup      = Result.ExpenseGroup;
		CurrentData.ReferenceOrder = Result.ReferenceOrder;
		
		If Object.GroupCosts =
				Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "ManufacturedProducts" Then
			
			CurrentData.BillOfMaterials = Result.BillOfMaterials;
			CurrentData.MethodOfAllocatingFinishedProductCosts = Result.MethodOfAllocatingFinishedProductCosts;
			CurrentData.Stage = Result.Stage;
			
		EndIf;
		If TSName = "SupplyWithMaterialsAndWorks" Then
			CurrentData.OrderDocument = Result.OrderDocument;
			
			If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				CurrentData.ParametersForFillingAssignments = Result.ParametersForFillingAssignments;
				CurrentData.AppointmentSelectionList = Result.AppointmentSelectionList;
			EndIf;
			
			If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				CurrentData.Purpose =
					?(CurrentData.WithAssignment,
					Result.SupplyAssignment,
					Undefined);
			Else
				
				RowsToProcess.Add(CurrentData);
				
			EndIf;
		EndIf;
		
	EndDo;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert(
			"FillInPurposeOfProvisionInProductionPhase",
			Result.ParametersForFillingAssignments);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object[TSName],
			CachedValues);
		
		For Each CurrentData In RowsToProcess Do
			FillInServiceDetailsOfStageSupportInLine(ThisObject, CurrentData);
		EndDo;
		UpdateColumnIsAvailableOnServer();
		
	EndIf;
	
	For Each CostGroupNumber In Groups Do
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CostGroupNumber);
	EndDo;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
	EndIf;
	
EndProcedure

&AtServer
Function TableCostGroupStartSelectionCheckResult(Result, TSName)
	
	Cancel = False;
	
	CostGroupDescription = CostGroupDataByCostGroupNumber(Result.CostGroupNumber);
	
	If Not TSName = CostGroupDescription.ProductTableName
		And CostGroupDescription.AllProductLinesAreCancelled Then
		Cancel = True;
		Text = NStr("vi = 'Đã hủy tất cả dòng sản phẩm nhóm chi phí. Không thể chọn nhóm chi phí này.';
					|ru = 'Все строки продукции группы затрат отменены. Выбор такой группы затрат невозможен.';
					|en = 'All lines of manufactured products of the cost group are canceled. Cannot select such cost group.'; fa = 'All lines of manufactured products of the cost group are canceled. Cannot select such cost group.';
					|it = 'Tutte le righe di produzione del gruppo di spesa sono state annullate. Impossibile selezionare questo gruppo di spesa.';
					|pl = 'Wszystkie wiersze grupa kosztów są anulowane. Wybór takiej grupy kosztów jest niemożliwe.';
					|tr = 'Maliyet grubunun tüm ürün satırları iptal edildi. Böyle bir maliyet grubunun seçimi mümkün değildir.'");
		Common.MessageToUser(Text);
	EndIf;
	
	Return Cancel;
	
EndFunction

#EndRegion

#Region SupportingProcedures

#Region VATAccounting

&AtServer
Procedure UpdatePurchaseForActivity(ChangesTakenIntoAccount = Undefined, Fill = True)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	FillParameters = Documents.SubcontractOrder2_5.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.PurchaseForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	ChangesTakenIntoAccount.Insert("PurchaseForActivity");
	
EndProcedure

&AtServer
Procedure UpdateVATTaxation_(ChangesTakenIntoAccount = Undefined, Fill = True)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	FillParameters = Documents.SubcontractOrder2_5.ParametersForFillingInVATTaxationPurchases(Object);
	
	If Fill Then
		
		VATAccountingERP.FillInVATTaxationPurchases(
			Object.VATTaxation,
			FillParameters,
			VATAccountingCachedParameterValues);
		
		TaxationOfVATWhenChangingOnServer();
		
	EndIf;
	
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
	ChangesTakenIntoAccount.Insert("VATTaxation");
	
EndProcedure

#EndRegion

#Region ARAPAccounting

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtServer
Procedure PaymentStagesForChangesOnServer(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure ProcessingAndSettlementsOnServer(EventName, Parameter)
	
	RefreshStatusServer();
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

#EndRegion

&AtServer
Procedure ProcessChangeOfDirection(ChangesTakenIntoAccount)
	
	If Not ChangesTakenIntoAccount.Property("LineOfBusiness") Then
		
		LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisForm);
		
		For Each CurrentData In Object.ManufacturedProducts Do
			If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				AddChangeCostGroup(CurrentData, True);
			EndIf;
		EndDo;
		
		For Each CurGroup In CostGroups Do
			TableFillInDependentServiceDetailsOfCostGroup("ManufacturedProducts", CurGroup.CostGroupNumber);
		EndDo;
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
		ChangesTakenIntoAccount.Insert("LineOfBusiness");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FlagOneDateWhenChangingOnServer(NamesOfTS, FieldNameWithOneDate, FieldNameDate)
	
	// Calculate the maximum date of receipt and bring PM to it
	If Object[FieldNameWithOneDate] Then
		
		Object[FieldNameDate] = MaximumTSDate(NamesOfTS, FieldNameDate);
		
		TabularSections = StrSplit(NamesOfTS, ",");
		For Each TSName In TabularSections Do
			FillInWHDate(TSName, Object[FieldNameDate]);
		EndDo;
		
	EndIf;
	
	If FieldNameWithOneDate = "OneDateReceipt"
		And QualityControl.UpdateActionParameters(Documents.SubcontractOrder2_5, Object, CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, FieldNameWithOneDate);
	
EndProcedure

&AtServer
Procedure TotalDateWhenChangedOnServer(NamesOfTS, FieldNameDate)
	
	TabularSections = StrSplit(NamesOfTS, ",");
	For Each TSName In TabularSections Do
		FillInWHDate(TSName, Object[FieldNameDate]);
	EndDo;
	
	If FieldNameDate = "DateOfReceipt"
		And QualityControl.UpdateActionParameters(Documents.SubcontractOrder2_5, Object, CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Function MaximumTSDate(NamesOfTS, FieldNameDate)
	
	MaxDate = Date(1,1,1);
	
	TabularSections = StrSplit(NamesOfTS, ",");
	For Each TSName In TabularSections Do
		For Each RowData In Object[TSName] Do
			If RowData.Property("Canceled")
				And RowData.Canceled Then
				Continue;
			EndIf;
			MaxDate = Max(MaxDate, RowData[FieldNameDate]);
		EndDo;
	EndDo;
	
	Return MaxDate
	
EndFunction

&AtServer
Procedure RefreshStatusServer()
	
	Documents.SubcontractOrder2_5.CalculateStatus(
		Object.Ref,
		Object.Contract,
		ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateProductWarehouseTable()
	
	TableOfProductWarehouses.Clear();
	
	If Not ProductWarehouseGroup Then
		Return;
	EndIf;
	
	Warehouses = New Map();
	
	For Each CurRow In Object.ManufacturedProducts Do
		
		If ValueIsFilled(CurRow.Recipient)
			And TypeOf(CurRow.Recipient) = Type("CatalogRef.Warehouses")
			And Not CurRow.Canceled Then
			
			NumberOfWarehouses = Warehouses.Get(CurRow.Recipient);
			If NumberOfWarehouses = Undefined Then
				NumberOfWarehouses = 0;
			EndIf;
			
			Warehouses.Insert(CurRow.Recipient, NumberOfWarehouses + 1);
			
		EndIf;
		
	EndDo;
	
	For Each CurRow In Object.SideAndIntermediateRelease Do
		
		If ValueIsFilled(CurRow.Recipient)
			And TypeOf(CurRow.Recipient) = Type("CatalogRef.Warehouses")
			And Not CurRow.Canceled Then
			
			NumberOfWarehouses = Warehouses.Get(CurRow.Recipient);
			If NumberOfWarehouses = Undefined Then
				NumberOfWarehouses = 0;
			EndIf;
			
			Warehouses.Insert(CurRow.Recipient, NumberOfWarehouses + 1);
			
		EndIf;
		
	EndDo;
	
	For Each Item In Warehouses Do
		NewRow = TableOfProductWarehouses.Add();
		NewRow.Warehouse = Item.Key;
		NewRow.RowsCount = Item.Value;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateInventoryTable()
	
	TableOfWarehousesMaterials.Clear();
	
	If Not WarehouseMaterialsGroup Then
		Return;
	EndIf;
	
	Warehouses = New Map();
	
	For Each CurRow In Object.SupplyWithMaterialsAndWorks Do
		If ValueIsFilled(CurRow.Warehouse)
			And Not CurRow.Canceled Then
			NumberOfWarehouses = Warehouses.Get(CurRow.Warehouse);
			If NumberOfWarehouses = Undefined Then
				NumberOfWarehouses = 0;
			EndIf;
			Warehouses.Insert(CurRow.Warehouse, NumberOfWarehouses + 1);
		EndIf;
	EndDo;
	
	For Each Item In Warehouses Do
		NewRow = TableOfWarehousesMaterials.Add();
		NewRow.Warehouse = Item.Key;
		NewRow.RowsCount = Item.Value;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function OrdersAccordingToProcessorData(CurrentOrder, Counterparty, IncomingDocumentNumber)
	
	OrderDetails = Common.ObjectAttributesValues(CurrentOrder, "DateAccordingToInformationFromPartner, Date");
	IncomingDocumentDate =
		?(ValueIsFilled(OrderDetails.DateAccordingToInformationFromPartner),
			OrderDetails.DateAccordingToInformationFromPartner,
			?(ValueIsFilled(OrderDetails.Date), OrderDetails.Date, CurrentSessionDate()));

	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	SubcontractOrder.Ref AS Ref
	|FROM
	|	Document.SubcontractOrder2_5 AS SubcontractOrder
	|WHERE
	|	NOT SubcontractOrder.Ref = &CurrentOrder
	|	AND SubcontractOrder.Date BETWEEN
	|		BEGINOFPERIOD(&IncomingDocumentDate, YEAR)
	|		AND ENDOFPERIOD(&IncomingDocumentDate, YEAR)
	|	AND SubcontractOrder.NumberAccordingToPartnerData = &NumberAccordingToPartnerData
	|	AND SubcontractOrder.Counterparty = &Counterparty
	|	AND NOT SubcontractOrder.DeletionMark
	|";

	Query.SetParameter("IncomingDocumentDate", IncomingDocumentDate);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("CurrentOrder", CurrentOrder);
	Query.SetParameter("NumberAccordingToPartnerData", IncomingDocumentNumber);

	ListOfOrdersByNumber = New ValueList;
	ListOfOrdersByNumber.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));

	Return ListOfOrdersByNumber;

EndFunction

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts(Groups = Undefined)
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters, Groups);
	
EndProcedure

&AtServer
Procedure ConvertDocumentAmountsToCurrency()
	
	OldCurrency  = DocumentCurrency;
	NewCurrency   = Object.Currency;
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisObject, OldCurrency, NewCurrency, BaseCurrency, DocumentDate);
	StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
	StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
	
	// Recalculate the prices
	For Each CurRow In Object.SideAndIntermediateRelease Do
		CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(CurRow.Price,
			StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	EndDo;
	
	If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		For Each CurRow In Object.SupplyWithMaterialsAndWorks Do
			CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(CurRow.Price,
				StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		EndDo;
	EndIf;
	
	// Recalculate the amount
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisObject, "SideAndIntermediateRelease", StructureOfActions, "Sum");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions, CachedValues);
	
	If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		StructureOfActions = New Structure;
		AddActionsForRecalculatingAmounts(ThisObject, "SupplyWithMaterialsAndWorks", StructureOfActions, "Sum");
		BatchProcessingOfTablePartServer.TreatTS(Object.SupplyWithMaterialsAndWorks, StructureOfActions, CachedValues);
	EndIf;
	
	RecalculationParameters = PriceManagementSystem.ParametersForConvertingTableAmountsToCurrency(Object.PriceIncludesVAT, OldCurrency, NewCurrency);
	RecalculationParameters.StructureOfOldCurrencyRates = StructureOfOldCurrencyRates;
	RecalculationParameters.StructureOfNewCurrencyRates  = StructureOfNewCurrencyRates;
	RecalculationParameters.QuantityName               = "Count";
	
	PriceManagementSystem.ConvertTableAmountsToCurrency(Object.Services, RecalculationParameters);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Services, DependentDetails("Services"));
	
	CalculateDocumentTotals(ThisObject, "AmountOfServices, DepositValue");
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateDocumentTotals(Form, AttributesList = "")
	
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("AmountOfServices") Then
		Object.DocumentAmount =
			Object.Services.Total("AmountIncludingVAT")
			- Object.Services.Total("AmountIncludingVATCanceled");
		Form.DocumentVATAmount =
			Object.Services.Total("VATAmount")
			- Object.Services.Total("VATAmountCanceled");
	EndIf;
	
	If Initialize
		Or AttributesList.Property("DepositValue") Then
		Object.DepositValue =
			Object.SupplyWithMaterialsAndWorks.Total("Sum")
			- Object.SupplyWithMaterialsAndWorks.Total("SumCanceled");
	EndIf;
	
	If Initialize
		Or AttributesList.Property("NumberOfProducts") Then
		Form.QuantityOfFinishedProducts = 
			Object.ManufacturedProducts.Count()
			+ Object.SideAndIntermediateRelease.Count();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region IsMain

&AtClient
Procedure CloseOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	CallbackDescription = New CallbackDescription("CloseOrderFragment", ThisForm);
	WriteParameters = New Structure;
	WriteParameters.Insert("ActionAfterRecording", CallbackDescription);
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	
	If Not QuestionResult = DialogReturnCode.No Then
		Write(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseOrderFragment(Result = Undefined, AdditionalParameters = Undefined) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractOrder2_5.DocumentForm.Command.CloseOrder");
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.Ref);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm(
		"DataProcessor.OrderClosureWizard.Form.ClosureForm",
		ClosureStructure,
		ThisForm,,,,
		Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region TableCommandHandlers

&AtClient
Procedure TableFillDateCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	TSName = AdditionalParameters.TSName;
	SelectedRows = AdditionalParameters.SelectedRows;
	
	FillInWHDate(TSName, Result,, SelectedRows);
	
EndProcedure

&AtClient
Procedure TableSplitRowCompletion(Result, AdditionalParameters) Export 
	
	TSName = AdditionalParameters.TSName;
	CurrentRow = Items[TSName].CurrentData;
	
	If Result <> Undefined Then
		
		Result.RowCode = 0;
		
		StructureOfActions = New Structure;
		
		AddActionsWhenChangingQuantity(ThisForm, TSName, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(Result, StructureOfActions, CachedValues);
		
		If TSName = "ManufacturedProducts" Then
			
			ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(
				Result,
				CurrentRow,
				Object.MethodOfAllocatingFinishedProductCosts);
			
			Groups = New Array;
			Groups.Add(CurrentRow.CostGroupNumber);
			CalculatePercentageOfCostAllocationForOutputProducts(Groups);
			
		EndIf;
		If TSName = "SupplyWithMaterialsAndWorks" Then
			ProcessSplitOfStringIncludedInSet(Result);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BarcodeSearchTableCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2, AdditionalParameters.TSName);
	
EndProcedure

&AtClient
Procedure PickUpProduct(TSName)
	
	If Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tiền tệ""';
				|ru = 'Поле ""Валюта"" не заполнено';
				|en = '""Currency"" is required'; fa = '""Currency"" is required';
				|it = 'Il campo ""Valuta"" non è compilato';
				|pl = 'Pole ""Waluta"" nie jest wypełnione';
				|tr = '""Para Birimi"" alanı doldurulmadı'"),
			Object.Ref,
			"Object.Currency");
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("HideManualDiscounts",    True);
	FormParameters.Insert("PriceIncludesVAT",         Object.PriceIncludesVAT);
	FormParameters.Insert("Currency",                  Object.Currency);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Document",                Object.Ref);
	
	If TSName = "Services" Then
		FormParameters.Insert("FilterByProductType", ProductsClientServer.JobSelection(False));
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
		FormParameters.Insert("Department", Object.Department);
	Else
		
		FormParameters.Insert("FilterByProductType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
		
		If TSName = "SupplyWithMaterialsAndWorks" Then
			FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", WarehouseMaterialsVHF);
		Else
			FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", VTCHProductWarehouse);
		EndIf;
		
		If Not FormParameters.SelectionModeUseWarehousesInTabularSection Then
			If TSName = "SupplyWithMaterialsAndWorks" Then
				FormParameters.Insert("Warehouse", Object.MaterialsWarehouse);
			Else
				FormParameters.Insert("Warehouse", Object.ManufacturedProductsWarehouse);
			EndIf;
		EndIf;
		
		FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
		
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		FormParameters.Insert("UseShipmentDates",   True);
		FormParameters.Insert("SeriesSpecificationParameters",     SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		FormParameters.Insert("Purpose",                 Object.Purpose);
		FormParameters.Insert("Department",              Object.Department);
		FormParameters.Insert("SelectSupplyOptions", True);
		FormParameters.Insert(
			"AvailableRemainingDocumentParameters",
			ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisForm));
		
		FormParameters.Insert("AllWarehouseBalance", WarehouseMaterialsVHF);
		FormParameters.Insert("UseAdvancedFeaturesOfSalesOrder", True);
		
		ProductSelectionForm = "DataProcessor.SelectGoodsToSalesDocument.Form";
		
		FormOwner = ThisForm;
		
	Else
		
		FormParameters.Insert("Partner", Object.Partner);
		
		ProductSelectionForm = "DataProcessor.SelectGoodsToPurchaseDocument.Form";
		
		If TSName = "Services" Then
			FormOwner = ThisForm;
		Else
			FormOwner = Items[TSName];
		EndIf;
		
	EndIf;
	
	OpenForm(ProductSelectionForm, FormParameters, FormOwner, UUID);
	
EndProcedure

&AtClient
Procedure OpenFormForSelectingCancellationReasons(TSName, Notification)
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		CancellationReasonForm = "Catalog.ReasonsForProductionCancellation.ChoiceForm";
	Else
		CancellationReasonForm = "Catalog.ReasonsForPurchaseOrderCancellation.ChoiceForm";
	EndIf;
	OpenForm(CancellationReasonForm,,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TableUndoSelectedRowsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CancelSelectedLines(AdditionalParameters.TSName, Result);
	
EndProcedure

&AtClient
Procedure CancelSelectedLines(TSName, CancellationReason)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractOrder2_5.Form.DocumentForm.Command." + TSName + "CancelSelectedLines");
	
	StructureOfActions = New Structure;
	
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "Services" Then
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails(TSName));
	EndIf;
	
	FieldNameReasonForCancellation = "CancellationReason";
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And Not TSName = "Services" Then
		FieldNameReasonForCancellation = "ReasonForCancellationOfProduction";
	EndIf;
	CancellationStructure = New Structure(FieldNameReasonForCancellation, CancellationReason);
	
	For Each Id In Items[TSName].SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(Id);
		
		If CurrentData <> Undefined Then
			
			CurrentData.Canceled = True;
			FillPropertyValues(CurrentData, CancellationStructure);
			
			AddCollateralActions(ThisForm, TSName, StructureOfActions, "WarehouseIsRequired, DateOfShipmentRequired_");
			AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
			
			If ValueIsFilled(StructureOfActions) Then
				BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	UndoSelectedRowsOnServer(TSName);
	
	ShowUserNotification(
		NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
			|ru = 'Выделенные строки отменены';
			|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
			|it = 'Righe selezionate annullate';
			|pl = 'Zaznaczone wiersze anulowano';
			|tr = 'Belirtilen satırlar iptal edildi'"),,
		NStr("vi = 'Các dòng đã chọn bị hủy bỏ.';
			|ru = 'Выделенные строки отменены.';
			|en = 'Selected lines are canceled.'; fa = 'Selected lines are canceled.';
			|it = 'Righe selezionate annullate.';
			|pl = 'Anulowano wydzielone wiersze.';
			|tr = 'Belirtilen satırlar iptal edildi.'"),
		PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure UndoSelectedRowsOnServer(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If TSName = "ManufacturedProducts"
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "SideAndIntermediateRelease"
		Then
		
		For Each CurID_ In SelectedRows Do
			
			CurrentData = Object[TSName].FindByID(CurID_);
			If Not CurrentData.CostGroupNumber = 0 Then
				FillInDependentServiceDetailsOfCostGroup(
					CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber));
			EndIf;
			
		EndDo;
		
		UndoCostGroupRows(TSName, SelectedRows);
		
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, SelectedRows);
	
EndProcedure

&AtClient
Procedure TableUndoRawRowsCompletion(Result, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractOrder2_5.Form.DocumentForm.Command." + AdditionalParameters.TSName + "UndoRawRows");
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CancellationResult = CancelUndeliveredLines(AdditionalParameters.TSName, Result);
	ShowUserNotification(NStr("vi = 'Hủy bỏ các dòng chưa xử lý';
								|ru = 'Отмена неотработанных строк';
								|en = 'Cancel unfulfilled lines'; fa = 'Cancel unfulfilled lines';
								|it = 'Annullamento delle righe non elaborate';
								|pl = 'Anulowanie nieprzetworzonych wierzszy';
								|tr = 'İşlenmemiş satır iptali'"), , CancellationResult.Notification);
	
EndProcedure

&AtServer
Function CancelUndeliveredLines(TSName, CancellationReason)
	
	OrderLineAdjustmentStructure = OrdersServer.OrderLineAdjustmentStructure();
	OrderLineAdjustmentStructure.CancelUnprocessedLines = True;
	OrderLineAdjustmentStructure.CancelUnprocessedLines = True;
	OrderLineAdjustmentStructure.TabularSectionName = TSName;
	OrderLineAdjustmentStructure.CancellationReason = CancellationReason;
	
	Result = AdjustOrderLines(OrderLineAdjustmentStructure);
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillWarehouseDivisionCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	TSParameters = AdditionalParameters.TSParameters;
	
	FillWarehouseDivisionOnServer(TSParameters, Items[TSParameters.NameTSForm].SelectedRows, Result);
	
	ShowUserNotification(
		NStr("vi = 'Đã điền kho bãi/bộ phận';
			|ru = 'Склад/подразделение заполнено';
			|en = 'Warehouse/business unit is filled in'; fa = 'Warehouse/business unit is filled in';
			|it = 'Magazzino/reparto compilato';
			|pl = 'Magazyn/dział jest wypełniony';
			|tr = 'Ambar/departman dolduruldu'"),,
		NStr("vi = 'Đối với các dòng được chọn đã điền kho bãi/bộ phận';
			|ru = 'Для выделенных строк выполнено заполнение склада/подразделения';
			|en = 'Warehouse/business unit is filled in for the selected lines'; fa = 'Warehouse/business unit is filled in for the selected lines';
			|it = 'Per le righe evidenziate è completata la compilazione del magazzino/reparto';
			|pl = 'Dla wybranych wierszy wykonano wypełnienie magazynu/działu';
			|tr = 'Belirtilen satırlar için ambar/departman dolduruldu'"),
		PictureLib.Information32);
	
EndProcedure	

&AtServer
Procedure FillWarehouseDivisionOnServer(TSParameters, Val SelectedRows, ValueSelected)
	
	TSName = TSParameters.NameTsObject;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		WarehouseFieldName = "Warehouse";
	Else
		WarehouseFieldName = "Recipient";
	EndIf;
	
	StructureOfActions = New Structure;
	
	AddActionsWhenChangingWarehouse(ThisObject, TSName, StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	For Each RowID In SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(RowID);
		CurrentData[WarehouseFieldName] = ValueSelected;
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName],
		CachedValues);
		
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	TSName = AdditionalParameters.TSName;
	
	For Each RowID In Items[TSName].SelectedRows Do
		RowData = Object[TSName].FindByID(RowID);
		RowData.ProductCostElement = Result;
	EndDo;
	
EndProcedure

&AtClient
Procedure TableFillInReasonForCancellationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TSName = AdditionalParameters.TSName;
	
	FieldNameReasonForCancellation = "CancellationReason";
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		And Not TSName = "Services" Then
		FieldNameReasonForCancellation = "ReasonForCancellationOfProduction";
	EndIf;
	CancellationStructure = New Structure(FieldNameReasonForCancellation, Result);
	
	For Each Id In Items[TSName].SelectedRows Do
		CurrentData = Object[TSName].FindByID(Id);
		If CurrentData <> Undefined
			And CurrentData.Canceled Then
			FillPropertyValues(CurrentData, CancellationStructure);
		EndIf;
	EndDo;
	
EndProcedure

#Region Supply

&AtClient
Procedure ProvidingSetActionWithQuestion(ActionCode)
	
	Result = ProvidingSetAction(ActionCode);
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisForm,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		"ProvisionAfterIssueOfFillingProvisionWithWholePackages");
		
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisForm,
			Object.SupplyWithMaterialsAndWorks,
			Result,
			"EnsuringAfterQuestionRemoveFlagToShipByOneDate");
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ProvisionAfterIssueOfFillingProvisionWithWholePackages(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisForm,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		Response,
		"EnsuringAfterQuestionRemoveFlagToShipByOneDate");
		
	If Not QuestionAsked Then
		EnsuringToSetActionAfterQuestion(Response, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnsuringAfterQuestionRemoveFlagToShipByOneDate(Response, Result) Export
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
EndProcedure

&AtServer
Procedure EnsuringToSetActionAfterQuestion(Response, Result)
	
	ResultStructure1 = ProvisionInDocumentsServer.SetActionAfterQuestion(Response, Result, ThisForm);
	
	AfterFillingOutCollateral(
		ResultStructure1.ChangesTable,
		ProvisionInDocumentsClientServer.ActionSelectionMode(),
		ResultStructure1);
	
EndProcedure

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisForm);
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		FormParameters.OrdersMotionRecorders = ListOfOrders_.UnloadValues();
	EndIf;
	If Object.Status = PredefinedValue("Enum.TollingOrderStatuses.NotApproved") Then
		
		FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
		FormParameters.AcceptableSecurityOptions.Delete(
			PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
		
	EndIf;
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	OpenForm(
		"DataProcessor.OrderSupplyForecast.Form",
		FormParameters,
		ThisForm,
		UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function FillInCollateralFromCollateralStateForm(ActionCode, AddressAnalyst, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.FillInCollateralFromCollateralStateForm(
		ActionCode,
		AddressAnalyst,
		ThisForm);
	
	Mode = ProvisionInDocumentsClientServer.SoftwareStateMode();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	AddressOfTheMovementTable = AddressOfMovementTableInRepository();
	
	Return AddressOfTheMovementTable;
	
EndFunction

&AtClient
Procedure ProcessWarehouseAndBatchSelection(ValueSelected, FormParameters) Export
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDateAfterSelectingCollateral(
		ThisForm,
		ValueSelected,
		FormParameters,
		"ProcessSelectionWarehouseAndBatchAfterQuestion");
		
EndProcedure

&AtClient
Procedure ProcessSelectionWarehouseAndBatchAfterQuestion(Response, Var_Parameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(
		Var_Parameters.ValueSelected,
		Var_Parameters.FormParameters,
		FillParameters);
	
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(Var_Parameters.FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);
	
EndProcedure

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters, FillParameters)
	
	Modified = True;
	
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisForm,
		Items.SupplyWithMaterialsAndWorks.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode, FillParameters);
	
	UpdateInventoryTable();
	UpdateWarehouseGroupImage(TableOfWarehousesMaterials, InscriptionSeveralWarehousesMaterials, Items.ThereAreSeveralWarehousesMaterials);
	
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtServer
Function ProvidingSetAction(ActionCode)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	If ActionCode = "FLAG_UNITED"
		Or ActionCode = "FLAG_NOTABLE" Then
		
		IDs = New Array;
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			
			For Each Id In Items.SupplyWithMaterialsAndWorks.SelectedRows Do
				
				CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(Id);
				If ActionCode = "FLAG_NOTABLE"
					And CurrentData.Produced Then
					Continue;
				EndIf;
				
				IDs.Add(Id);
				
			EndDo;
			
		Else
			IDs = Items.SupplyWithMaterialsAndWorks.SelectedRows;
		EndIf;
		Changes = ProvisionInDocumentsServer.SetActionApart(
			ActionCode,
			ThisForm,
			IDs);
		
		If Changes.ChangesTable <> Undefined Then
			If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				StructureOfActions = New Structure;
				StructureOfActions.Insert("FillInAssignmentInProductionPhase");
				CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			EndIf;
			
			RowsToProcess = New Array();
			For Each Update In Changes.ChangesTable Do
				
				CurrentData = Update.String;
				If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
					CostGroupDescription = CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber);
					CurrentData.Purpose =
						?(CurrentData.WithAssignment,
						CostGroupDescription.SupplyAssignment,
						Undefined);
				Else
					RowsToProcess.Add(CurrentData);
				EndIf;
			EndDo;
			
			CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(
				ThisObject, AvailableRemainingEmbeddingOptions);
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				CollectionOnForm,
				CachedValues);
				
			UpdateColumnIsAvailableOnServer();
			
		EndIf;
		
	Else
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisForm,
			Items.SupplyWithMaterialsAndWorks.SelectedRows);
		
		FillPropertyValues(Result, Changes);
		
		If Changes.ChangesTable <> Undefined Then
			AfterFillingOutCollateral(
				Changes.ChangesTable,
				ProvisionInDocumentsClientServer.ActionSelectionMode(),
				Result);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

&AtClient
Procedure ServicesFillInPricesBySupplierPriceTypeCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		PricesCalculated = FillInPricesBySupplierPriceTypeOnServer(Result, Items.Services.SelectedRows);
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, Result);
	EndIf;
	
	CalculateDocumentTotals(ThisForm, "AmountOfServices");
	
EndProcedure

&AtClient
Procedure ServicesSelectAndCompleteServiceCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsFillInPrice(ThisObject, "Services", StructureOfActions);
	
	For Each RowID In Items.Services.SelectedRows Do
		
		CurrentData = Object.Services.FindByID(RowID);
		CurrentData.Products = ClosingResult;
		AddActionsWhenChangingProducts(ThisObject, "Services", StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
	EndDo;
	
	CalculateDocumentTotals(ThisForm, "AmountOfServices");
	
EndProcedure

&AtClient
Procedure TableOfTSParametersAccordingToSpecificationCompletion(Result, TSName) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.SubcontractOrder2_5.Form.DocumentForm.Command." + TSName + "FillInTSAccordingToSpecification");
	
	If Result = DialogReturnCode.Yes Then
		TableFillInTSBySpecificationOnServer(TSName);
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputProductsToBeRefilledAccordingToSpecificationsCompletion(Result, ListOfGroups) Export
	
	If Result = DialogReturnCode.Yes Then
		ReFillAccordingToSpecificationsOnServer(ListOfGroups);
	EndIf;
	
EndProcedure

#Region StandardCommands

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard(TSName) 
	
	FilterParameters = New Map;
	If TSName = "Services" Then
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.JobSelection(False));
	Else
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingWork(False));
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,DateOfReceipt,DateOfShipment,
		|VendorPriceKind,Price,VATRate,BillOfMaterials,ProductCostElement,Recipient,Warehouse";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	TabularSection = Object[TSName]; // FormDataCollection
	SelectedRows = New Array;
	
	DimensionsToFillIn = New Array;
	RowsToProcess = New Array;
	ProductData_2 = New Array;
	For Each RowOfProduct In TableOfGoods Do
	
		CurrentData = TabularSection.Add();
		FillPropertyValues(CurrentData, RowOfProduct);
		RowsToProcess.Add(CurrentData);
		
		FillDateInTSLineWithTotalDate(ThisObject, TSName, CurrentData);
		
		If TSName = "ManufacturedProducts"
				And Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
			Or TSName = "SupplyWithMaterialsAndWorks"
				And CurrentData.Produced Then
			
			ProductData_2.Add(
				ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, CurrentData, BOMSelectionParameters[TSName], ThisObject));
			
		EndIf;
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActions);
	AddActionsCheckFillWarehouse(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPriceView(ThisObject, TSName, StructureOfActions);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActions);
	AddActionsInitializeArticleAndAnalytics(ThisObject, TSName, StructureOfActions);
	
	AddCollateralActions(
		ThisObject,
		TSName,
		StructureOfActions,
		"SupplyOption, WarehouseIsRequired, DateOfShipmentRequired_");
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert(
			"CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
				Object.MaterialsWarehouse, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, RowsToProcess));
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection,
		CachedValues);
	
	If TSName = "ManufacturedProducts"
			And Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages")
		Or TSName = "SupplyWithMaterialsAndWorks"
			And CurrentData.Produced Then
		
		ProductDataManagement.FillInSpecificationInLines(
			RowsToProcess, ProductData_2, BOMSelectionParameters[TSName]);
		
	EndIf;
	
	For Each CurrentData In RowsToProcess Do
	
		If TSName = "ManufacturedProducts" Then
			If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				AddChangeCostGroup(CurrentData, True);
			Else
				SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			EndIf;
			SelectedRows.Add(CurrentData.GetID());
			
		Else
			SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
		EndIf;
		
		DimensionsToFillIn.Add(CurrentData.CostGroupNumber);
		
	EndDo;
	If TSName = "SupplyWithMaterialsAndWorks" Then
		For Each CurrentData In RowsToProcess Do
			FillInServiceDetailsOfStageSupportInLine(ThisObject, CurrentData);
		EndDo;
	EndIf;
	For Each CurGroup In DimensionsToFillIn Do
		TableFillInDependentServiceDetailsOfCostGroup(TSName, CurGroup);
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, SelectedRows);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region ObjectCommandHandlers
&AtServer
Function PostAtServer(WriteParameters)
	
	RecordingResult = False;
	
	BeginTransaction();
	Try
		
		Documents.SubcontractOrder2_5.SetInteractiveEditingMark(Object);
		RecordingResult = Write(WriteParameters);
		
		If RecordingResult Then
			Documents.SubcontractOrder2_5.UncheckInteractiveEditing(Object);
			CommitTransaction();
		Else
			RollbackTransaction();
		EndIf;
		
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		Common.MessageToUser(ErrorText);
		
		WriteLogEvent(
			NStr("vi = 'Kết chuyển chứng từ';
				|ru = 'Проведение документа';
				|en = 'Document posting'; fa = 'ثبت سند';
				|it = 'Registrazione documento';
				|pl = 'Zatwierdzenie dokumentu';
				|tr = 'Belgenin kaydedilmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		Return False;
		
	EndTry;
	
	If RecordingResult Then
		WriteParameters.DisablePostWriteProcessingOnServer = False;
		AfterWriteAtServer(Object, WriteParameters);
	EndIf;
	
	Return RecordingResult;
	
EndFunction
#EndRegion

#EndRegion

#Region FillType

#Region ServiceDetails_

&AtServer
Procedure FillInServiceDetails()
	
	GroupCostsBeforeChange = Object.GroupCosts;
	DocumentCurrency = Object.Currency;
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	
	UseTollingOrderStatuses =
		GetFunctionalOption("UseTollingOrderStatuses2_5");
	
	UseReasonsForPurchaseOrderCancellations =
		GetFunctionalOption("UseReasonsForPurchaseOrderCancellations");
	
	UseProduction =
		GetFunctionalOption("UseProduction");
	
	UseLinesOfBusiness =
		GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	
	CostAllocationParameters =
		New FixedStructure(Documents.SubcontractOrder2_5.CostAllocationParameters(Object));
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.SubcontractOrder2_5));
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.SubcontractOrder2_5);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProducts);
	ProcessingOfTabularForms.InitializeRowCache(Items.SideAndIntermediateRelease);
	ProcessingOfTabularForms.InitializeRowCache(Items.SupplyWithMaterialsAndWorks);
	ProcessingOfTabularForms.InitializeRowCache(Items.Services);
	
	ThereIsRightToViewStateOfSoftware = ProvisionInDocumentsServer.HaveRightToViewStateHyperlink();

EndProcedure

// Parameters:
// 	Form - ClientApplicationForm
// 	AttributesList - String
&AtClientAtServerNoContext
Procedure FillInDependentServiceAttributes(Form, AttributesList = "")
	
	Object = Form.Object;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("ProcessingByOrder") Then
		
		Form.UseStatuses =
			Form.UseTollingOrderStatuses
			Or Object.GroupCosts =
					PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDependentServiceDetailsSupply(Form)
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
		Form.Object.SupplyWithMaterialsAndWorks,
		Form.DateOfShipmentRequired_,
		Form.WarehouseMaterialsRequired);
	
EndProcedure

&AtServer
Procedure FillInDependentServiceDetailsOnServer(AttributesList = "")
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	If Initialize
		Or AttributesList.Property("Partner")
		Or AttributesList.Property("PriceIncludesVAT") Then
		FillInDefaultVendorPriceView();
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ManufacturedProductsWarehouse")
		Or AttributesList.Property("GroupCosts")
		Or AttributesList.Property("LeaveProductsAtSubcontractor") Then
		
		ProductWarehouseGroup = Catalogs.Warehouses.IsFolder(Object.ManufacturedProductsWarehouse);
		
		VTCHProductWarehouse =
			Not Object.LeaveProductsAtSubcontractor
			And (ProductWarehouseGroup
				Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages);
		
		ProductWarehouseSelectionData.LoadValues(WarehouseSelectionData(Object.ManufacturedProductsWarehouse));
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("MaterialsWarehouse")
		Or AttributesList.Property("GroupCosts") Then
		
		WarehouseMaterialsGroup = Catalogs.Warehouses.IsFolder(Object.MaterialsWarehouse);
		
		WarehouseMaterialsVHF =
			WarehouseMaterialsGroup
			Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("References") Then
		DynamicStructure =
			?(Object.References.Count() > 0,
				Common.ObjectAttributeValue(Object.References[0].ReferenceOrder, "DynamicStructure"),
				Undefined);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts(ListOfTS = "")
	
	StructureOfTS = New Structure(ListOfTS);
	Initialize = Not ValueIsFilled(StructureOfTS);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	If Initialize
		Or StructureOfTS.Property("ManufacturedProducts") Then
		
		StructureOfTSActions = Common.CopyRecursive(StructureOfActions);
		
		ActionParameters = New Structure("WarehouseFieldName", "Recipient");
		StructureOfTSActions.Insert("FillInShopPantryAttribute", ActionParameters);
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.ManufacturedProducts,
			StructureOfTSActions,
			Undefined);
		
		If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(
				Object, CostAllocationParameters);
		EndIf;
		
	EndIf;
	
	If Initialize
		Or StructureOfTS.Property("SideAndIntermediateRelease") Then
		
		StructureOfTSActions = Common.CopyRecursive(StructureOfActions);
		
		ActionParameters = New Structure("WarehouseFieldName", "Recipient");
		StructureOfTSActions.Insert("FillInShopPantryAttribute", ActionParameters);
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.SideAndIntermediateRelease,
			StructureOfTSActions,
			Undefined);
		
	EndIf;
			
	If Initialize
		Or StructureOfTS.Property("SupplyWithMaterialsAndWorks") Then
		
		StructureOfTSActions = Common.CopyRecursive(StructureOfActions);
		
		StructureOfTSActions.Insert("FillInShopPantryAttribute");
		StructureOfTSActions.Insert("FillInDuplicateDependentDetails", DependentDetails("SupplyWithMaterialsAndWorks"));
		
		AddCollateralActions(
			ThisForm,
			"SupplyWithMaterialsAndWorks",
			StructureOfTSActions,
			"WarehouseIsRequired, DateOfShipmentRequired_");
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.SupplyWithMaterialsAndWorks,
			StructureOfTSActions,
			Undefined);
		
		FillInDependentServiceDetailsSupply(ThisForm);
		ProductDataManagement.FillInDetailsIncludedInSet(Object);
	EndIf;
	
	If Initialize
		Or StructureOfTS.Property("Services") Then
		
		StructureOfTSActions = Common.CopyRecursive(StructureOfActions);
		StructureOfTSActions.Insert("FillInDuplicateDependentDetails", DependentDetails("Services"));
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.Services,
			StructureOfTSActions,
			Undefined);
		
	EndIf;
	FillInServiceDetailsOfTabularPartsByOrder(ListOfTS);
EndProcedure	

&AtServer
Procedure FillInServiceDetailsOfTabularPartsByOrder(ListOfTS = "")
	
	StructureOfTS = New Structure(ListOfTS);
	ProcessedTS = New Structure;
	
	Initialize = Not ValueIsFilled(StructureOfTS);
	
	If Object.References.Count() = 0 Then
		Return;
	EndIf;
	
	StageStructure = New Structure;
	StageStructure.Insert("ReferenceOrder");
	StageStructure.Insert("ProductionLot");
	StageStructure.Insert("Purpose");
	StageStructure.Insert("AssignmentProducts");
	StageStructure.Insert("DynamicStructure");
	StageStructure.Insert("WorkPlanning", False);
	
	Query = New Query;
	QueryTexts = New Array;
	
	Query.SetParameter("References", Object.References.Unload(, "LineNumber, ReferenceOrder, CostGroupNumber"));
	QueryTexts.Add(
	"SELECT
	|	References.LineNumber,
	|	References.ReferenceOrder,
	|	References.CostGroupNumber
	|INTO TT_Orders
	|FROM
	|	&References AS References
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.LineNumber AS LineNumber,
	|	References.CostGroupNumber AS CostGroupNumber,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	StageDetails.DataVersion AS DataVersion,
	|	StageDetails.ReferenceOrder AS OrderDocument,
	|	StageDetails.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
	|	StageDetails.Status AS Status,
	|	StageDetails.BillOfMaterials AS BillOfMaterials,
	|	StageDetails.NextStageNo AS NextStageNo,
	|	StageDetails.Stage AS Stage,
	|	StageDetails.LeaveProductsAtSubcontractor AS LeaveProductsAtSubcontractor,
	|	StageDetails.ProductionLot AS ProductionLot,
	|	StageDetails.Purpose AS Purpose,
	|	StageDetails.ActualStageStart AS ActualStageStart,
	|	StageDetails.ActualStageEnd AS ActualStageEnd,
	|	StageDetails.BusinessOperation AS BusinessOperation,
	|	StageDetails.AssignmentProducts AS AssignmentProducts,
	|	StageDetails.DynamicStructure AS DynamicStructure
	|INTO TTOrderData
	|FROM
	|	TT_Orders AS References
	|	
	|	LEFT JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.Ref = References.ReferenceOrder
	|");
	
	CurTableNumber = 1;
	
	#Region References
	
	If Initialize
		Or StructureOfTS.Property("References") Then
		
		QueryTexts.Add(
		"SELECT
		|	OrderData_3.LineNumber AS LineNumber,
		|	OrderData_3.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
		|	OrderData_3.DataVersion AS DataVersion,
		|	OrderData_3.OrderDocument AS OrderDocument,
		|	OrderData_3.Status AS Status,
		|	OrderData_3.BillOfMaterials AS BillOfMaterials,
		|	OrderData_3.NextStageNo AS NextStageNo,
		|	OrderData_3.Stage AS Stage,
		|	OrderData_3.LeaveProductsAtSubcontractor AS LeaveProductsAtSubcontractor,
		|	OrderData_3.ProductionLot AS ProductionLot,
		|	OrderData_3.Purpose AS Purpose,
		|	OrderData_3.ActualStageStart AS ActualStageStart,
		|	OrderData_3.ActualStageEnd AS ActualStageEnd,
		|	OrderData_3.BusinessOperation AS BusinessOperation,
		|	OrderData_3.AssignmentProducts AS AssignmentProducts,
		|	OrderData_3.DynamicStructure AS DynamicStructure
		|FROM
		|	TTOrderData AS OrderData_3
		|");
		
		CurTableNumber = CurTableNumber + 1;
		ProcessedTS.Insert("References", CurTableNumber);
		
	EndIf;
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	If Initialize
		Or StructureOfTS.Property("ManufacturedProducts") Then
		
		Query.SetParameter("ManufacturedProducts", Object.ManufacturedProducts.Unload(, "LineNumber, CostGroupNumber"));
		QueryTexts.Add(
		"SELECT
		|	Table.LineNumber,
		|	Table.CostGroupNumber
		|INTO TTOutputProducts
		|FROM
		|	&ManufacturedProducts AS Table
		|
		|INDEX BY
		|	CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber,
		|	OrderData_3.ReferenceOrder AS ReferenceOrder,
		|	OrderData_3.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
		|	OrderData_3.BillOfMaterials AS BillOfMaterials,
		|	OrderData_3.Stage AS Stage
		|FROM
		|	TTOutputProducts AS Table
		|	
		|	LEFT JOIN TTOrderData AS OrderData_3
		|	ON OrderData_3.CostGroupNumber = Table.CostGroupNumber
		|");
		
		CurTableNumber = CurTableNumber + 2;
		ProcessedTS.Insert("ManufacturedProducts", CurTableNumber);
		
	EndIf;
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	If Initialize
		Or StructureOfTS.Property("SideAndIntermediateRelease") Then
		
		Query.SetParameter("SideAndIntermediateRelease", Object.SideAndIntermediateRelease.Unload(, "LineNumber, CostGroupNumber"));
		QueryTexts.Add(
		"SELECT
		|	Table.LineNumber,
		|	Table.CostGroupNumber
		|INTO TTByProducts
		|FROM
		|	&SideAndIntermediateRelease AS Table
		|
		|INDEX BY
		|	CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber,
		|	OrderData_3.ReferenceOrder AS ReferenceOrder
		|FROM
		|	TTByProducts AS Table
		|	
		|	LEFT JOIN TTOrderData AS OrderData_3
		|	ON OrderData_3.CostGroupNumber = Table.CostGroupNumber
		|");
		
		CurTableNumber = CurTableNumber + 2;
		ProcessedTS.Insert("SideAndIntermediateRelease", CurTableNumber);
		
	EndIf;
	
	#EndRegion
	
	#Region SupplyWithMaterialsAndWorks
	
	If Initialize
		Or StructureOfTS.Property("SupplyWithMaterialsAndWorks") Then
		
		Query.SetParameter("SupplyWithMaterialsAndWorks", Object.SupplyWithMaterialsAndWorks.Unload(, "LineNumber, CostGroupNumber"));
		QueryTexts.Add(
		"SELECT
		|	Table.LineNumber,
		|	Table.CostGroupNumber
		|INTO TTProvisionOfMaterialsAndWorks
		|FROM
		|	&SupplyWithMaterialsAndWorks AS Table
		|
		|INDEX BY
		|	CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber,
		|	OrderData_3.ReferenceOrder AS ReferenceOrder,
		|	OrderData_3.OrderDocument AS OrderDocument
		|FROM
		|	TTProvisionOfMaterialsAndWorks AS Table
		|	
		|	LEFT JOIN TTOrderData AS OrderData_3
		|	ON OrderData_3.CostGroupNumber = Table.CostGroupNumber
		|");
		
		CurTableNumber = CurTableNumber + 2;
		ProcessedTS.Insert("SupplyWithMaterialsAndWorks", CurTableNumber);
		
	EndIf;
	
	#EndRegion
	
	#Region Services
	
	If Initialize
		Or StructureOfTS.Property("Services") Then
		
		Query.SetParameter("Services", Object.Services.Unload(, "LineNumber, CostGroupNumber"));
		QueryTexts.Add(
		"SELECT
		|	Table.LineNumber,
		|	Table.CostGroupNumber
		|INTO TTServices
		|FROM
		|	&Services AS Table
		|
		|INDEX BY
		|	CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber,
		|	OrderData_3.ReferenceOrder AS ReferenceOrder
		|FROM
		|	TTServices AS Table
		|	
		|	LEFT JOIN TTOrderData AS OrderData_3
		|	ON OrderData_3.CostGroupNumber = Table.CostGroupNumber
		|");
		
		CurTableNumber = CurTableNumber + 2;
		ProcessedTS.Insert("Services", CurTableNumber);
		
	EndIf;
	
	#EndRegion
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Result = Query.ExecuteBatch();
	
	If Initialize
		Or StructureOfTS.Property("References") Then
		ThereIsReleaseStage = False;
		For Each CurTS In ProcessedTS Do
			Table = Result[CurTS.Value].Unload(); // ValueTable
			For Each CurRow In Table Do
				
				FillPropertyValues(Object[CurTS.Key][CurRow.LineNumber - 1], CurRow);
				
				If CurTS.Key = "References" Then
					ThereIsReleaseStage =
						ThereIsReleaseStage
						Or ProductionManagementClientServer.ThisIsAProductionIssueStage(CurRow);
					
					FillPropertyValues(StageStructure, CurRow,
						"ProductionLot, Purpose, AssignmentProducts, DynamicStructure");
					StageStructure.ReferenceOrder = CurRow.OrderDocument;
					
					Object[CurTS.Key][CurRow.LineNumber - 1].ParametersForFillingAssignments = 
						ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
							StageStructure, Undefined);
					
					ProductionSupply.FillInListOfSelectedAssignmentsInProductionPhase(
						StageStructure,
						Undefined,
						Object[CurTS.Key][CurRow.LineNumber - 1].AppointmentSelectionList);
				EndIf;
				
			EndDo;
		EndDo;
		
		If Initialize
			Or StructureOfTS.Property("SupplyWithMaterialsAndWorks") Then
			FilterStructure1 = New Structure("CostGroupNumber");
			For Each String In Object.References Do
				FilterStructure1.CostGroupNumber = String.CostGroupNumber;
				For Each FoundRow In Object.SupplyWithMaterialsAndWorks.FindRows(FilterStructure1) Do
					FoundRow.ParametersForFillingAssignments = String.ParametersForFillingAssignments;
					FoundRow.AppointmentSelectionList = String.AppointmentSelectionList;
				EndDo;
			EndDo;
		EndIf;
	EndIf;
	
	If Initialize
		Or StructureOfTS.Property("ManufacturedProducts") Then
		ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(
			Object, CostAllocationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultVendorPriceView()
	
	DefaultVendorPriceView = Catalogs.VendorPriceTypes.EmptyRef();
	
	SelectingTypeOfPrices = New Structure("Owner, PriceIncludesVAT", Object.Partner, Object.PriceIncludesVAT);
	DefaultVendorPriceView = Catalogs.VendorPriceTypes.DefaultPriceType(DefaultVendorPriceView, SelectingTypeOfPrices);
	
EndProcedure

#EndRegion

#Region StructureOfActions

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingProducts(Form, TSName, StructureOfActions)
	
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	If Not TSName = "Services" Then
		StructureOfActions.Insert("CheckFillPackageByOwner");
	EndIf;
	
	ActionParameters = New Structure;
	ActionParameters.Insert("FormName", Form.FormName);
	ActionParameters.Insert("TabularSectionName", TSName);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ActionParameters);
	
	If Not TSName = "Services" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions);
	EndIf;
	
	If TSName = "Services" Then
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Form.Object));
	EndIf;
	
	AddActionsWhenChangingCharacteristic(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingCharacteristic(Form, TSName, StructureOfActions)
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable",
		New Structure("FormName, TabularSectionName", Form.FormName, TSName));
	
	If Not TSName = "Services" Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions);
	EndIf;
	
	AddActionsClearFillArticleAnalytics(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckFillWarehouse(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease"
		And Not TSName = "SupplyWithMaterialsAndWorks" Then
		Return;
	EndIf;
	
	Object = Form.Object;
	
	NameOfChargeToExpensesField = "";
	If TSName = "SupplyWithMaterialsAndWorks" Then
		WarehouseFieldName = "Warehouse";
		NameOfObjectWarehouseField = "MaterialsWarehouse";
	Else
		WarehouseFieldName = "Recipient";
		NameOfObjectWarehouseField = "ManufacturedProductsWarehouse";
		NameOfChargeToExpensesField = "ToExpenseAs";
	EndIf;
	
	If Object.GroupCosts =
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			Object.Department,
			StructureOfActions,
			WarehouseFieldName);
	Else
		
		WarehouseGroup_ =
			?(TSName = "SupplyWithMaterialsAndWorks",
				Form.WarehouseMaterialsGroup,
				Form.ProductWarehouseGroup);
		
		ActionParameters =
			BatchProcessingOfTablePartClientServer.GetWarehouseFillStructureInTSLine(
				Object,
				WarehouseGroup_,
				NameOfObjectWarehouseField,
				WarehouseFieldName,
				NameOfChargeToExpensesField);
		
		If Not Form.UseSeveralWarehouses Then
			ActionParameters.DefaultWarehouse = Form.DefaultWarehouse;
		EndIf;
		
		StructureOfActions.Insert("CheckFillWarehouse" , ActionParameters);
		
	EndIf;
	
	AddActionsWhenChangingWarehouse(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingWarehouse(Form, TSName, StructureOfActions, CurrentData = Undefined)
	
	ActionParameters = Undefined;
	If Not TSName = "SupplyWithMaterialsAndWorks" Then
		ActionParameters = New Structure("WarehouseFieldName", "Recipient");
	EndIf;
	StructureOfActions.Insert("FillInShopPantryAttribute", ActionParameters);
	
	AddActionsCheckSeriesCalculateStatus(Form, TSName, StructureOfActions, CurrentData);
	AddActionsWhenChangingQuantity(Form, TSName, StructureOfActions);
	AddQualityControlActionsToStructure(TSName, StructureOfActions, Form.CacheQualityControl);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingPackaging(Form, TSName, StructureOfActions, CurrentData)
	
	If TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
	EndIf;
	
	AddActionsWhenChangingQuantity(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckSeriesCalculateStatus(Form, TSName, StructureOfActions, CurrentData)
	
	If Not TSName = "SupplyWithMaterialsAndWorks"
		Or CurrentData = Undefined Then
		Return;
	EndIf;
	
	ActionParameters = New Structure;
	ActionParameters.Insert("Warehouse", CurrentData.Warehouse);
	ActionParameters.Insert("SeriesSpecificationParameters", Form.SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", ActionParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingQuantity(Form, TSName, StructureOfActions)
	
	If Not TSName = "Services" Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	EndIf;
	
	AddActionsCheckFillShareCost(Form, TSName, StructureOfActions);
	AddActionsForRecalculatingAmounts(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckFillSpecification(Form, TSName, StructureOfActions, CurrentData)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If (Not TSName = "ManufacturedProducts"
			Or TSName = "ManufacturedProducts"
				And Form.Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages"))
		And Not (TSName = "SupplyWithMaterialsAndWorks"
			And CurrentData.Produced)
		Then
		Return;
	EndIf;
	
	FillParameters =
		ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
			Form.Object,
			CurrentData,
			Form.BOMSelectionParameters[TSName]);
	
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsClearFillArticleAnalytics(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease" Then
		Return;
	EndIf;
	
	IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
		StructureOfActions,
		Form,
		"Object." + TSName);
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		Form,
		PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
		Form.Object.Organization,
		Form.Object.Department,
		"Object." + TSName);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsInitializeArticleAndAnalytics(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease" Then
		Return;
	EndIf;
	
	IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine(
		StructureOfActions,
		Form,
		"Object." + TSName);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsCheckFillShareCost(Form, TSName, StructureOfActions)
	
	If Not TSName = "ManufacturedProducts" Then
		Return;
	EndIf;
	
	StructureOfActions.Insert("CheckFillInCostShare", Form.CostAllocationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsFillInPriceView(Form, TSName, StructureOfActions)
	
	If TSName = "Services" Then
		ActionParameters = New Structure;
		ActionParameters.Insert("NameOfPriceTypeField", "VendorPriceKind");
		ActionParameters.Insert("PriceKind", Form.DefaultVendorPriceView);
		StructureOfActions.Insert("FillInPriceView", ActionParameters);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsFillInPrice(Form, TSName, StructureOfActions)
	
	If Not TSName = "SupplyWithMaterialsAndWorks"
		And Not TSName = "SideAndIntermediateRelease"
		And Not TSName = "Services" Then
		Return;
	EndIf;
	
	If TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks" Then
		ActionName = "FillInSalePrice";
	ElsIf TSName = "Services" Then
		ActionName = "FillInPurchasePrice";
	EndIf;
	
	StructureOfActions.Insert(ActionName, ParametersForFillingInPriceInTSLine(TSName, Form.Object));
	AddActionsForRecalculatingAmounts(Form, TSName, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsForRecalculatingAmounts(Form, TSName, StructureOfActions, AttributesList = "")
	
	If Not TSName = "SupplyWithMaterialsAndWorks"
		And Not TSName = "SideAndIntermediateRelease"
		And Not TSName = "Services" Then
		Return;
	EndIf;
	
	AttributesList = New Structure(AttributesList);
	Initialize = Not ValueIsFilled(AttributesList);
	
	FieldNameQuantity = "NumberOfPackages";
	If TSName = "Services" Then
		FieldNameQuantity = "Count";
	EndIf;
	
	If TSName = "Services"
		And (Initialize
			Or AttributesList.Property("VATAmount")
			Or AttributesList.Property("AmountIncludingVAT")) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Form.Object);
	EndIf;
	
	// The price is recalculated only when the amount changes, so its recalculation is not added by default
	If AttributesList.Property("Price") Then
		StructureOfActions.Insert("RecalculatePriceByAmount", FieldNameQuantity);
	EndIf;
	
	If Initialize
		Or AttributesList.Property("Sum") Then
		StructureOfActions.Insert("RecalculateAmount", FieldNameQuantity);
	EndIf;
	
	If TSName = "Services"
		And (Initialize
			Or AttributesList.Property("VATAmount")) Then
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	EndIf;
	
	If TSName = "Services"
		And (Initialize
			Or AttributesList.Property("AmountIncludingVAT")) Then
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks"
			And (Initialize
				Or AttributesList.Property("Sum"))
		Or TSName = "Services"
			And (Initialize
				Or AttributesList.Property("AmountIncludingVAT")
				Or AttributesList.Property("VATAmount")) Then
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails(TSName));
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddCollateralActions(Form, TSName, StructureOfActions, StringFields_)
	
	If Not TSName = "SupplyWithMaterialsAndWorks" Then
		Return;
	EndIf;
	
	DocumentParameters = DocumentParametersForSoftwareActions(Form);
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl)
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
EndProcedure

#EndRegion

#Region ObjectAttributes

&AtServer
Procedure FillInDefaultContract(ChangesTakenIntoAccount)
	
	If ChangesTakenIntoAccount = Undefined Then
		ChangesTakenIntoAccount = New Structure;
	EndIf;
	
	ObjectParameters = New Structure("Partner, Contract, Counterparty, Organization");
	FillPropertyValues(ObjectParameters, Object);
	ObjectParameters.Insert("Terms", Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Object.Currency;
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
			And UseLinesOfBusiness Then
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
	EndIf;	
	
	Contract =
		PurchasesServer.GetDefaultContract(
			ObjectParameters,
			Object.BusinessOperation, 
			AddlParameters);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer(ChangesTakenIntoAccount);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
EndProcedure

&AtServer
Procedure FillInDeliveryDetailsOnServer(FormItemName)
	
	GoodsDelivery.FillInDeliveryDetails(Items, FormItemName, Object);
	
EndProcedure

&AtServer
Procedure FillTSWarehouseOnServer(FillParameters, Val SelectedRows = Undefined)
	
	ItemsTypes =
		Common.ObjectsAttributeValue(
			Object[FillParameters.TSName].Unload(, "Products").UnloadColumn("Products"),
			"ItemsType");
	
	WarehouseGroups = New Map;
	
	If FillParameters.WarehouseGroup_ Then
		TSWarehouses = Object[FillParameters.TSName].Unload(, FillParameters.WarehouseFieldName).UnloadColumn(FillParameters.WarehouseFieldName);
		For Each CurWarehouse In TSWarehouses Do
			If WarehouseGroups.Get(CurWarehouse) = Undefined Then
				WarehouseGroups.Insert(CurWarehouse, Catalogs.Warehouses.FolderHierarchy(CurWarehouse));
			EndIf;
		EndDo;
	EndIf;
	
	HasChanges = False;
	
	If SelectedRows = Undefined Then
		StringSource_ = Object[FillParameters.TSName];
		OnlySelectedItems = False;
	Else
		StringSource_ = SelectedRows;
		OnlySelectedItems = True;
	EndIf;
	
	For Each CurRow In StringSource_ Do
		
		If OnlySelectedItems Then
			RowData = Object[FillParameters.TSName].FindByID(CurRow);
		Else
			RowData = CurRow;
		EndIf;
		
		If ItemsTypes.Get(RowData.Products) = Enums.ItemsTypes.Work_5
			Or ValueIsFilled(FillParameters.NameOfChargeToExpensesField)
				And RowData[FillParameters.NameOfChargeToExpensesField] Then
			Continue;
		EndIf;
		
		If Not FillParameters.WarehouseGroup_
			And Not RowData[FillParameters.WarehouseFieldName] = FillParameters.Warehouse Then
			RowData[FillParameters.WarehouseFieldName] = FillParameters.Warehouse;
			HasChanges = True;
		ElsIf FillParameters.WarehouseGroup_ Then
			CurGroups = WarehouseGroups.Get(RowData[FillParameters.WarehouseFieldName]);
			If CurGroups.Find(FillParameters.Warehouse) = Undefined Then
				RowData[FillParameters.WarehouseFieldName] = Catalogs.Warehouses.EmptyRef();
				HasChanges = True;
			EndIf;
		EndIf;
		
	EndDo;
	
	If HasChanges Then
		
		StructureOfActions = New Structure;
		AddActionsWhenChangingWarehouse(ThisForm, FillParameters.TSName, StructureOfActions);
		BatchProcessingOfTablePartServer.TreatTS(Object[FillParameters.TSName], StructureOfActions, Undefined);
		
		UpdateColumnIsAvailableOnServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInReceiptDateWithDesiredDate()
	
	If Object.OneDateReceipt
			And ValueIsFilled(Object.DateOfReceipt)
		Or Object.ManufacturedProducts.Count() = 0
			And Object.SideAndIntermediateRelease.Count() = 0 Then
			Return;
	EndIf;
	
	FillInReceiptDateWithDesiredDateOnServer();
	
EndProcedure

&AtServer
Procedure FillInReceiptDateWithDesiredDateOnServer()
	
	If Object.OneDateReceipt
			And ValueIsFilled(Object.DateOfReceipt)
		Or Object.ManufacturedProducts.Count() = 0
			And Object.SideAndIntermediateRelease.Count() = 0 Then
			Return;
	EndIf;
	
	DateOfReceipt = Undefined;
	If ValueIsFilled(Object.RequestedDeliveryDate)
		And Object.RequestedDeliveryDate > Object.Date Then
		DateOfReceipt = Object.RequestedDeliveryDate;
	Else
		DateOfReceipt = CurrentSessionDate();
	EndIf;
	
	If Object.OneDateReceipt
		And Not ValueIsFilled(Object.DateOfReceipt) Then
		Object.DateOfReceipt = DateOfReceipt;
	EndIf;
	
	FillInWHDate("ManufacturedProducts", DateOfReceipt, Object.OneDateReceipt);
	FillInWHDate("SideAndIntermediateRelease", DateOfReceipt, Object.OneDateReceipt);
	
	If QualityControl.UpdateActionParameters(Documents.SubcontractOrder2_5, Object, CacheQualityControl) Then
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		
		StructureOfActions = New Structure();
		AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInEmptyDatesOfWorkOnServer()
	
	If Object.Services.Count() = 0 Then
		Return;
	EndIf;
	
	If Not Object.WorkPerformanceAsOneDay Then
		ExecutionDate = CurrentSessionDate();
	Else
		If Not ValueIsFilled(Object.ExecutionDate) Then
			Object.ExecutionDate = CurrentSessionDate();
		EndIf;
		ExecutionDate = Object.ExecutionDate;
	EndIf;
	
	FillInWHDate("Services", ExecutionDate, False);
	
EndProcedure

&AtServer
Procedure FillInWHDate(TSName, NewDate, ReFill_ = True, Val SelectedRows = Undefined)
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		FieldNameDate = "DateOfReceipt";
	ElsIf TSName = "Services" Then
		FieldNameDate = "ExecutionDate";
	Else
		FieldNameDate = "DateOfShipment";
	EndIf;
	
	If SelectedRows = Undefined Then
		StringSource_ = Object[TSName];
		OnlySelectedItems = False;
	Else
		StringSource_ = SelectedRows;
		OnlySelectedItems = True;
	EndIf;
	
	RowsToProcess = New Array;
	For Each CurRow In StringSource_ Do
		
		If OnlySelectedItems Then
			RowData = Object[TSName].FindByID(CurRow);
		Else
			RowData = CurRow;
		EndIf;
		
		If TSName = "SupplyWithMaterialsAndWorks"
			And RowData.SupplyOption = Enums.SupplyOptions.TransferedEarlier Then
				RowData[FieldNameDate] = '00010101';
		ElsIf ReFill_
			Or Not ValueIsFilled(RowData[FieldNameDate]) Then
			
			RowData[FieldNameDate] = NewDate;
			
			If TSName = "ManufacturedProducts"
				Or TSName = "SideAndIntermediateRelease" Then
				RowsToProcess.Add(RowData);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(RowsToProcess) Then
		
		StructureOfActions = New Structure;
		AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object[TSName]);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillDateInTSLineWithTotalDate(Form, TSName, CurrentData)
	
	Object = Form.Object;
	UseCommonDate = False;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		FieldNameDate = "DateOfReceipt";
		UseCommonDate = Object.OneDateReceipt;
		SingleDate = Object.DateOfReceipt;
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		FieldNameDate = "DateOfShipment";
		UseCommonDate = Object.NotShipInInstallments;
		SingleDate = Object.DateOfShipment;
	ElsIf TSName = "Services" Then
		FieldNameDate = "ExecutionDate";
		UseCommonDate = Object.WorkPerformanceAsOneDay;
		SingleDate = Object.ExecutionDate;
	EndIf;
	
	If UseCommonDate Then
		CurrentData[FieldNameDate] = SingleDate;
	EndIf;
	
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer(TSName, Val SelectedRows = Undefined)
	
	Cancel = False;
	LinesToBeRefilled = Undefined;
	
	If Not SelectedRows = Undefined Then
		
		If SelectedRows.Count() = 0 Then
			
			If TSName = "SideAndIntermediateRelease" Then
				MessageText = NStr("vi = 'Trong bảng ""Phế liệu thu hồi"" chưa chọn dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Возвратные отходы"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the ""Recyclable waste"" table. 
										|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Recyclable waste"" table. 
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Scarti restituibili"" non è selezionata nessuna riga. 
										|I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Odpady zwrotne"" nie wybrano ani jednego wiersza. 
										|Ceny nie mogą być wypełnione.';
										|tr = '""Geri Dönüştürülebilir Atıklar"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			Else
				MessageText = NStr("vi = 'Trong bảng ""Nguyên vật liệu và công việc"" chưa chọn một dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Материалы и работы"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the ""Materials and works"" table. 
										|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Materials and works"" table. 
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Materiali e lavori"" non è stata selezionata alcuna riga. 
										|I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Materiały i prace"" nie wybrano ani jednego wiersza. 
										|Ceny nie mogą być wypełnione.';
										|tr = '""Malzemeler ve İşler"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			EndIf;
			
			Common.MessageToUser(MessageText,, TSName, "Object", Cancel);
			
			If Not ValueIsFilled(Object.PriceKind) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Dạng giá"".';
									|ru = 'Не заполнено поле ""Вид цены"".';
									|en = '""Price type"" is required.'; fa = '""Price type"" is required.';
									|it = 'Il campo ""Tipo di prezzo"" non è compilato.';
									|pl = 'Nie wypełniono pole ""Rodzaj ceny""';
									|tr = '""Fiyat Türü"" alanı doldurulmadı.'");
				Common.MessageToUser(MessageText,, "PriceKind", "Object", Cancel);
			EndIf;
			
		EndIf;
		
		If Cancel Then
			Return False;
		EndIf;
		
		LinesToBeRefilled = New Array;
		For Each RowID In SelectedRows Do
			LinesToBeRefilled.Add(Object[TSName].FindByID(RowID));
		EndDo;
		
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",			Object.Date);
	FillParameters.Insert("Organization",		Object.Organization);
	FillParameters.Insert("Currency",			Object.Currency);
	FillParameters.Insert("PriceKind",			Object.PriceKind);
	FillParameters.Insert("PopulationFields",	"Price");
	
	StructureOfActions = New Structure;
	
	AddActionsForRecalculatingAmounts(ThisForm, TSName, StructureOfActions, "Sum");
	
	PricesCalculated =
		EnterprisePricesFillingServer.FillInPrices(
			Object[TSName],
			LinesToBeRefilled,
			FillParameters,
			StructureOfActions);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		CalculateDocumentTotals(ThisForm, "DepositValue");
	EndIf;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function FillInPricesBySupplierPriceTypeOnServer(VendorPriceKind, Val SelectedRows = Undefined)
	
	LinesToBeRefilled = Undefined;
	
	If Not SelectedRows = Undefined Then
		
		If SelectedRows.Count() = 0 Then
			
			MessageText = NStr("vi = 'Chưa chọn dòng nào trong bảng ""Dịch vụ"". 
									|Không thể điền đơn giá.';
									|ru = 'В таблице ""Услуги"" не выбрано ни одной строки. 
									|Цены не могут быть заполнены.';
									|en = 'No rows were selected in the ""Services"" table. 
									|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Services"" table. 
									|Prices cannot be filled in.';
									|it = 'Nella tabella ""Servizi"" non è stata selezionata alcuna riga. 
									|I prezzi non possono essere compilati.';
									|pl = 'W tabeli ""Usługi"" nie wybrano ani jednego wiersza. 
									|Ceny nie mogą być wypełnione.';
									|tr = '""Hizmetler"" tablosunda herhangi bir satır seçilmedi.
									|Fiyatlar doldurulamaz.'");
			Common.MessageToUser(MessageText,, "Services", "Object");
			
			Return False;
			
		EndIf;
		
		LinesToBeRefilled = New Array;
		For Each CurRow In SelectedRows Do
			LinesToBeRefilled.Add(Object.Services.FindByID(CurRow));
		EndDo;
		
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsForRecalculatingAmounts(ThisForm, "Services", StructureOfActions);
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields", "Price, VendorPriceKind");
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("VendorPriceKind", VendorPriceKind);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Services,
		LinesToBeRefilled,
		FillParameters,
		StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure TableFillInTSBySpecificationOnServer(TSName)
	
	ListOfGroups = CostGroups.Unload(,"CostGroupNumber").UnloadColumn("CostGroupNumber");
	ReFillAccordingToSpecificationsOnServer(ListOfGroups, TSName);
	
EndProcedure

&AtServer
Procedure ReFillAccordingToSpecificationsOnServer(ListOfGroups, ListOfTS = "")
	
	// &PerformanceMeasurement
	Measurement =
		PerformanceMonitor.StartTimeConsumingOperationMeasurement(
			"Document.SubcontractOrder2_5.Form.DocumentForm.Command.OutputProductsToBeRefilledAccordingToSpecifications");
	
	NamesOfTS         = New Structure(ListOfTS);
	FillInAll_    = NamesOfTS.Count() = 0;
	ProductList_ = New Array;
	
	Filter = New Structure("CostGroupNumber");
	For Each CurGroup In ListOfGroups Do
		
		Filter.CostGroupNumber = CurGroup;
		
		FoundRows = Object.ManufacturedProducts.FindRows(Filter);
		For Each CurRow In FoundRows Do
			If Not CurRow.Canceled Then
				ProductList_.Add(CurRow);
			EndIf;
		EndDo;
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			
			CostGroupDescription = CostGroupDataByCostGroupNumber(CurGroup);
			
			If CostGroupDescription.ProductTableName = "SideAndIntermediateRelease" Then
				For Each String In OutputProductsOfIntermediateStage(CostGroupDescription) Do
					ProductList_.Add(String);
				EndDo;
			EndIf;
			
		EndIf;
		If FillInAll_
			Or NamesOfTS.Property("SideAndIntermediateRelease") Then
			ClearTSByCostGroup("SideAndIntermediateRelease", CurGroup);
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("SupplyWithMaterialsAndWorks") Then
			ClearTSByCostGroup("SupplyWithMaterialsAndWorks", CurGroup);
		EndIf;
		
		If FillInAll_
			Or NamesOfTS.Property("Services") Then
			ClearTSByCostGroup("Services", CurGroup);
		EndIf;
		
	EndDo;
	
	Documents.SubcontractOrder2_5.FillInByProductsMaterialsServicesAccordingToSpecification(ProductList_, Object, ListOfTS);
	
	UpdateCostGroupPresentation();
	
	If FillInAll_ Then
		ListOfTS = "SideAndIntermediateRelease, SupplyWithMaterialsAndWorks, Services";
	EndIf;
	
	FillInServiceDetailsOfTableParts(ListOfTS);
	
	If FillInAll_
		Or NamesOfTS.Property("SideAndIntermediateRelease") Then
		UpdateProductWarehouseTable();
		UpdateWarehouseGroupImage(
			TableOfProductWarehouses,
			InscriptionSeveralWarehousesOfProduct,
			Items.ThereAreSeveralWarehousesWares);
	EndIf;
	
	If FillInAll_
		Or NamesOfTS.Property("SupplyWithMaterialsAndWorks") Then
		UpdateColumnIsAvailableOnServer();
		UpdateInventoryTable();
		UpdateWarehouseGroupImage(
			TableOfWarehousesMaterials,
			InscriptionSeveralWarehousesMaterials,
			Items.ThereAreSeveralWarehousesMaterials);
	EndIf;
	
	CalculateDocumentTotals(ThisForm);
	
	// &PerformanceMeasurement
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ProductList_.Count());
	
EndProcedure
&AtServer
Function OutputProductsOfIntermediateStage(CostGroupDescription)
	
	Query = New Query(Documents.SubcontractOrder2_5.RequestTextOutputProductsOfStages(False));
	
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("StageList", CostGroupDescription.ReferenceOrder);
	Query.SetParameter("CostGroupNumber", CostGroupDescription.CostGroupNumber);
	
	Return Query.Execute().Unload();
	
EndFunction
#EndRegion

#Region Barcodes

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, TSName)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	TheseAreServices = TSName = "Services";
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsWhenChangingQuantity(ThisObject, TSName, StructureOfActionsWithModifiedStrings);
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsWhenChangingProducts(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsCheckFillWarehouse(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsFillInPriceView(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsFillInPrice(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	AddActionsInitializeArticleAndAnalytics(ThisObject, TSName, StructureOfActionsWithAddedStrings);
	
	If Not TheseAreServices Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	EndIf;
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.TSName                                  = TSName;
	StructureOfActions.NotUsePackages                 = TheseAreServices;
	StructureOfActions.OnlyWorks                           = TheseAreServices;
	StructureOfActions.OnlyGoodsAndWork                    = Not TheseAreServices;
	
	If TheseAreServices Then
		StructureOfActions.ColumnNameQuantity = "Count";
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.SeriesSpecificationParameters = SeriesSpecificationParameters[TSName];
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
			CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
			
			AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
		EndIf;
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		FormTable = Items[TSName]; // FormTable
		FormTable.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	CalculateDocumentTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	TSName = StructureOfActionParameters.TSName;
	NumberOfRowsBeforeChange = Object[TSName].Count();
	
	AddCollateralActions(
		ThisObject,
		TSName,
		StructureOfActionParameters.StructureOfActionsWithAddedStrings,
		"SupplyOption, WarehouseIsRequired, DateOfShipmentRequired_");
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProvisionInDocumentsClientServer.RemoveCollateralActions(StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	EndIf;
	
	RowsCount = Object[TSName].Count();
	
	If Not RowsCount = NumberOfRowsBeforeChange Then
		
		ProductData_2 = New Array;
		RowsToProcess = New Array;
		For IndexOf = NumberOfRowsBeforeChange + 1 To RowsCount Do
			
			CurrentData = Object[TSName][IndexOf - 1];
			
			If (TSName = "ManufacturedProducts"
					And Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages"))
				Or (TSName = "SupplyWithMaterialsAndWorks"
					And CurrentData.Produced) Then
				
				ProductData_2.Add(
					ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
						Object, CurrentData, BOMSelectionParameters[TSName], ThisObject));
				
			EndIf;
			
			FillDateInTSLineWithTotalDate(ThisObject, TSName, CurrentData);
			
			RowsToProcess.Add(CurrentData);
			
		EndDo;
		
		If (TSName = "ManufacturedProducts"
				And Not Object.GroupCosts = PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages"))
			Or (TSName = "SupplyWithMaterialsAndWorks"
				And CurrentData.Produced) Then
			ProductDataManagement.FillInSpecificationInLines(RowsToProcess, ProductData_2, BOMSelectionParameters[TSName]);
		EndIf;
		
		If ValueIsFilled(RowsToProcess) Then
			
			StructureOfActions = New Structure;
			AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
			If ValueIsFilled(StructureOfActions) Then
				BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object[TSName]);
			EndIf;
			
		EndIf;
		
		For Each CurrentData In RowsToProcess Do
			
			If TSName = "ManufacturedProducts" Then
				If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
					AddChangeCostGroup(CurrentData, True);
				Else
					SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
				EndIf;
			Else
				SetDefaultCostGroupNumber(TSName, CurrentData.GetID());
			EndIf;
			
			TableFillInDependentServiceDetailsOfCostGroup(TSName, CurrentData.CostGroupNumber);
			
		EndDo;
		
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		UpdateColumnIsAvailableOnServer();
		FillInDependentServiceDetailsSupply(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region SupportingProcedures

&AtServer
Function ParametersForFillingTSWarehouse(TSName)
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		WarehouseFieldName = "Warehouse";
		Warehouse = Object.MaterialsWarehouse;
		WarehouseGroup_ = WarehouseMaterialsGroup;
		NameOfChargeToExpensesField = "";
	Else
		WarehouseFieldName = "Recipient";
		Warehouse = Object.ManufacturedProductsWarehouse;
		WarehouseGroup_ = ProductWarehouseGroup;
		NameOfChargeToExpensesField = "ToExpenseAs";
	EndIf;
	
	Result = New Structure;
	Result.Insert("TSName", TSName);
	Result.Insert("WarehouseFieldName", WarehouseFieldName);
	Result.Insert("Warehouse", Warehouse);
	Result.Insert("WarehouseGroup_", WarehouseGroup_);
	Result.Insert("NameOfChargeToExpensesField", NameOfChargeToExpensesField);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForFillingInPriceInTSLine(TSName, Object)
	
	PriceFillingParameters_ = Undefined;
	
	If TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks" Then
		PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	ElsIf TSName = "Services" Then
		PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object);
		//Installing an empty link to the packaging, since there is no record of work on packaging
		PriceFillingParameters_.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	EndIf;
	
	Return PriceFillingParameters_;
	
EndFunction

&AtServer
Function AdjustOrderLines(StructureOfAdditionalParameters)
	
	TSName = StructureOfAdditionalParameters.TabularSectionName;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease"
			And Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		Then
		
		SelectedRows = New Array;
		
		FilterStructure1 = New Structure("Canceled", False);
		For Each CurrentData In Object[TSName].FindRows(FilterStructure1) Do
			SelectedRows.Add(CurrentData.GetID());
		EndDo;
		
	EndIf;
	
	StructureOfAdditionalParameters.CheckBalance = Not (Object.Status = Enums.TollingOrderStatuses.NotApproved);
	ResultStructure1 = Documents.SubcontractOrder2_5.AdjustOrderLines(Object, StructureOfAdditionalParameters);
	
	If StructureOfAdditionalParameters.CloseOrders Then
		Object.Status = Enums.TollingOrderStatuses.Closed;
		If Not Object.OneDateReceipt Then
			FillInReceiptDateWithDesiredDateOnServer();
		EndIf;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		And TSName = "SideAndIntermediateRelease"
		Then
		
		For Each CurrentID In SelectedRows Do
			CurrentData = Object[TSName].FindByID(CurrentID);
			FillInDependentServiceDetailsOfCostGroup(
				CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber));
		EndDo;
		
		CancelledRowsCount =
			ResultStructure1.RowsCount
			+ UndoCostGroupRows(TSName, SelectedRows);
		
		ResultStructure1 = OrdersServer.ResultOfUndoingUnprocessedRows(CancelledRowsCount);
		
	EndIf;
	
	StructureOfActions = New Structure;
	
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "Services" Then
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails(TSName));
		AddCollateralActions(ThisObject, TSName, StructureOfActions, "WarehouseIsRequired, DateOfShipmentRequired_");
	EndIf;
	
	If ValueIsFilled(StructureOfActions) Then
		BatchProcessingOfTablePartServer.TreatTS(Object[TSName], StructureOfActions, Undefined);
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName);
	
	ConfigureDependentFormElements(ThisForm, "Status");
	
	Modified = True;
	
	Return ResultStructure1;
	
EndFunction

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

// This procedure should be used if the rows were added programmatically (not interactively), for example, when pasting from
// a buffer, or when filling in according to the specification. The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(TSName, Val SelectedRows = Undefined)
	
	If TSName = "ManufacturedProducts" Then
	
		ArrayOfDimensions = New Array;
		If SelectedRows <> Undefined Then
			For Each RowID In SelectedRows Do
				RowData = Object.ManufacturedProducts.FindByID(RowID);
				ArrayOfDimensions.Add(RowData.CostGroupNumber);
			EndDo;
		EndIf;
	
		CalculatePercentageOfCostAllocationForOutputProducts(ArrayOfDimensions);
	
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		RowsArray = Undefined;
		If SelectedRows <> Undefined Then
			RowsArray = New Array;
			For Each RowID In SelectedRows Do
				RowsArray.Add(Object[TSName].FindByID(RowID));
			EndDo;
		EndIf;
		
		ProductsServer.FillInStatusesForSpecifyingSeries(
			Object,
			SeriesSpecificationParameters.SupplyWithMaterialsAndWorks,
			RowsArray);
		
		UpdateColumnIsAvailableOnServer();
		FillInDependentServiceDetailsSupply(ThisForm);
		
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		AttributesList = "NumberOfProducts";
	ElsIf TSName = "Services" Then
		AttributesList = "AmountOfServices";
	Else
		AttributesList = "DepositValue";
	EndIf;
	
	CalculateDocumentTotals(ThisForm, AttributesList);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(StageCostAllocationParameters, CurrentID)
	
	FormParameters =
		ProductionServer.ParametersOfCostShareEntryForm(
			Object,
			StageCostAllocationParameters,
			CurrentID);
	
	Return FormParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region GroupCosts

&AtServer
Procedure AddChangeCostGroup(CurrentData, BatchMode = False)
	
	FilterStructure1 = CostGroupSelectionStructure(CurrentData);
	CostGroupPresentation = CostGroupPresentation(FilterStructure1);
	
	GroupNumberBeforeChange = CurrentData.CostGroupNumber;
	
	CostGroupDescription = CostGroupData(FilterStructure1);
	If CostGroupDescription.CostGroupNumber = 0 Then
		
		NewCostGroup = CostGroups.Add();
		FillPropertyValues(NewCostGroup, FilterStructure1);
		
		Object.MaximumNumberOfCostGroup = Object.MaximumNumberOfCostGroup + 1;
		NumberOfCostGroups = NumberOfCostGroups + 1;
		
		NewCostGroup.CostGroupNumber = Object.MaximumNumberOfCostGroup;
		NewCostGroup.ExpenseGroup = CostGroupPresentation;
		
		FillPropertyValues(CostGroupDescription, NewCostGroup);
		
	EndIf;
	
	AssignmentOfCollateralBeforeChange = CostGroupDescription.SupplyAssignment;
	
	FillInServiceDetailsOfCostGroup(CostGroupDescription);
	
	If Not GroupNumberBeforeChange = CostGroupDescription.CostGroupNumber
		Or Not AssignmentOfCollateralBeforeChange = CostGroupDescription.SupplyAssignment Then
		
		NumberOfIdentifyingRows = 0;
		If Not GroupNumberBeforeChange = CostGroupDescription.CostGroupNumber Then
			NumberOfIdentifyingRows = NumberOfIdentifyingRows(CostGroupDataByCostGroupNumber(GroupNumberBeforeChange));
		EndIf;
		
		If Not AssignmentOfCollateralBeforeChange = CostGroupDescription.SupplyAssignment
			Or Not GroupNumberBeforeChange = CostGroupDescription.CostGroupNumber
				And NumberOfIdentifyingRows = 1 Then
			
			UpdateLinksToCostGroup(GroupNumberBeforeChange, CostGroupDescription);
			
			If Not GroupNumberBeforeChange = CostGroupDescription.CostGroupNumber
				And NumberOfIdentifyingRows = 1 Then
				
				FilterStructure1 = New Structure("CostGroupNumber", GroupNumberBeforeChange);
				
				FoundRows = CostGroups.FindRows(FilterStructure1);
				For Each CurGroup In FoundRows Do
					CostGroups.Delete(CurGroup);
					NumberOfCostGroups = NumberOfCostGroups - 1;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
	CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
	
	If Not BatchMode Then
		
		FillInDependentServiceDetailsOfCostGroup(CostGroupDescription);
		
		CostGroupDescription = CostGroupDataByCostGroupNumber(GroupNumberBeforeChange);
		If Not CostGroupDescription.CostGroupNumber = 0 Then
			FillInDependentServiceDetailsOfCostGroup(CostGroupDescription);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteCostGroup(CurrentID)
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurrentID);
	
	CostGroupDescription = CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber);
	
	If NumberOfIdentifyingRows(CostGroupDescription) = 1 Then
		
		CostGroupDescription = CostGroupDescription();
		ClearTSByCostGroup("SideAndIntermediateRelease", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("SupplyWithMaterialsAndWorks", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("MaterialsAndWorksSets", CurrentData.CostGroupNumber);
		ClearTSByCostGroup("Services", CurrentData.CostGroupNumber);
		
		CalculateDocumentTotals(ThisObject, "AmountOfServices, DepositValue");
		
		FilterStructure1 = New Structure("CostGroupNumber", CurrentData.CostGroupNumber);
		FoundRows = CostGroups.FindRows(FilterStructure1);
		For Each CurGroup In FoundRows Do
			CostGroups.Delete(CurGroup);
			NumberOfCostGroups = NumberOfCostGroups - 1;
		EndDo;
		
	Else
		Return;
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - formaclient applications
// 	TSName - String
//
&AtServer
Procedure SetDefaultCostGroupNumber(TSName, CurrentID)
	
	CurrentData = Object[TSName].FindByID(CurrentID);
	
	If Not CurrentData = Undefined
		And CurrentData.CostGroupNumber = 0
		And NumberOfCostGroups = 1 Then
		
		CurrentData.ExpenseGroup = CostGroups[0].ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroups[0].CostGroupNumber;
		CurrentData.ReferenceOrder = CostGroups[0].ReferenceOrder;
		
		If Object.GroupCosts =
				Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "ManufacturedProducts" Then
			
			CurrentData.BillOfMaterials = CostGroups[0].BillOfMaterials;
			CurrentData.MethodOfAllocatingFinishedProductCosts = CostGroups[0].MethodOfAllocatingFinishedProductCosts;
			CurrentData.Stage = CostGroups[0].Stage;
			
		EndIf;
		If TSName = "SupplyWithMaterialsAndWorks" Then
			CurrentData.OrderDocument = CostGroups[0].OrderDocument;
			
			If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
				CurrentData.Purpose =
					?(CurrentData.WithAssignment,
					CostGroups[0].SupplyAssignment,
					Undefined);
			Else
				
				CurrentData.ParametersForFillingAssignments = CostGroups[0].ParametersForFillingAssignments;
				CurrentData.AppointmentSelectionList = CostGroups[0].AppointmentSelectionList;
				
				StructureOfActions = New Structure;
				StructureOfActions.Insert(
					"FillInPurposeOfProvisionInProductionPhase",
					CostGroups[0].ParametersForFillingAssignments);
				BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
				
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfCostGroup(CostGroupDescription)
	
	Documents.SubcontractOrder2_5.FillInServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription);
	
EndProcedure

&AtServer
Procedure FillInDependentServiceDetailsOfCostGroup(CostGroupDescription)
	
	Documents.SubcontractOrder2_5.FillInDependentServiceDetailsOfCostGroup(Object, CostGroups, CostGroupDescription);
	
EndProcedure

&AtServer
Procedure UpdateCostGroups()
	
	Documents.SubcontractOrder2_5.UpdateCostGroups(Object, CostGroups, NumberOfCostGroups);
	
	UpdateCostGroupPresentation();
	
EndProcedure

&AtServer
Procedure UpdateCostGroupPresentation()
	
	Documents.SubcontractOrder2_5.UpdateCostGroupPresentation(Object, CostGroups);
	
	FilterStructure1 = New Structure("CostGroupNumber");
	
	For Each CurGroup In CostGroups Do
		
		FillPropertyValues(FilterStructure1, CurGroup);
		Rows = Object.References.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		Rows = Object.ManufacturedProducts.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
		Rows = Object.SideAndIntermediateRelease.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
		Rows = Object.SupplyWithMaterialsAndWorks.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
		Rows = Object.Services.FindRows(FilterStructure1);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateLinksToCostGroup(CurrentGroupNumber, CostGroupDescription)
	
	If CurrentGroupNumber = 0
		And Not CostGroups.Count() = 1 Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("CostGroupNumber", CurrentGroupNumber);
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		
		Rows = Object.ManufacturedProducts.FindRows(FilterStructure1);
		For Each CurrentData In Rows Do
			
			CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
			CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
			CurrentData.ReferenceOrder = CostGroupDescription.ReferenceOrder;
			CurrentData.BillOfMaterials = CostGroupDescription.BillOfMaterials;
			CurrentData.MethodOfAllocatingFinishedProductCosts = CostGroupDescription.MethodOfAllocatingFinishedProductCosts;
			CurrentData.Stage = CostGroupDescription.Stage;
			
		EndDo;
		
	EndIf;
	Rows = Object.SideAndIntermediateRelease.FindRows(FilterStructure1);
	For Each CurrentData In Rows Do
		
		CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
		CurrentData.ReferenceOrder = CostGroupDescription.ReferenceOrder;
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	Rows = Object.SupplyWithMaterialsAndWorks.FindRows(FilterStructure1);
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInPurposeOfProvisionInProductionPhase",
		CostGroupDescription.ParametersForFillingAssignments);
	
	RowsToProcess = New Array();
	
	For Each CurrentData In Rows Do
		
		CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
		CurrentData.ReferenceOrder = CostGroupDescription.ReferenceOrder;
		CurrentData.OrderDocument = CostGroupDescription.OrderDocument;
		If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			CurrentData.ParametersForFillingAssignments = CostGroupDescription.ParametersForFillingAssignments;
			CurrentData.AppointmentSelectionList = CostGroupDescription.AppointmentSelectionList;
		EndIf;
		If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
			CurrentData.Purpose =
				?(CurrentData.WithAssignment,
				CostGroupDescription.SupplyAssignment,
				Undefined);
		Else
			
			RowsToProcess.Add(CurrentData);
			
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.SideAndIntermediateRelease,
		CachedValues);
	
	If Not Rows.Count() = 0 Then
		UpdateColumnIsAvailableOnServer();
	EndIf;
	
	Rows = Object.Services.FindRows(FilterStructure1);
	For Each CurrentData In Rows Do
		
		CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
		CurrentData.ReferenceOrder = CostGroupDescription.ReferenceOrder;
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearTSByCostGroup(TSName, CurrentGroupNumber)
	
	Table = Object[TSName].Unload(); // ValueTable
	Table.Indexes.Add("CostGroupNumber");
	
	Filter = New Structure("CostGroupNumber", CurrentGroupNumber);
	FoundRows = Table.FindRows(Filter);
	For Each CurRow In FoundRows Do
		Table.Delete(CurRow);
	EndDo;
	
	Object[TSName].Load(Table);
	
EndProcedure

&AtServer
Function UndoCostGroupRows(TSName, Val SelectedRows)
	
	FieldNameReasonForCancellation = "CancellationReason";
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		FieldNameReasonForCancellation = "ReasonForCancellationOfProduction";
	EndIf;
	GroupsToCancel = New Map;
	For Each CurRow In SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(CurRow);
		
		If CurrentData.Canceled Then
			
			CostGroupDescription = CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber);
			
			If CostGroupDescription.ProductTableName = TSName
				And CostGroupDescription.AllProductLinesAreCancelled Then
				
				GroupToCancel = GroupsToCancel.Get(CurrentData.CostGroupNumber);
				If GroupToCancel = Undefined
					Or ValueIsFilled(CurrentData[FieldNameReasonForCancellation]) Then
					
					CancellationStructure = New Structure;
					CancellationStructure.Insert("CostGroupDescription", CostGroupDescription);
					CancellationStructure.Insert("CancellationReason", CurrentData[FieldNameReasonForCancellation]);
					
					GroupsToCancel.Insert(CurrentData.CostGroupNumber, CancellationStructure);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	CancelledRowsCount = 0;
	For Each CurGroup In GroupsToCancel Do
		
		CancelledRowsCount =
			CancelledRowsCount
			+ CancelTSRowsByCostGroup("SideAndIntermediateRelease", CurGroup.Key, CurGroup.Value);
		
		CancelledRowsCount =
			CancelledRowsCount
			+ CancelTSRowsByCostGroup("SupplyWithMaterialsAndWorks", CurGroup.Key, CurGroup.Value);
		
		CancelledRowsCount =
			CancelledRowsCount
			+ CancelTSRowsByCostGroup("Services", CurGroup.Key, CurGroup.Value);
		
	EndDo;
	
	If Not CancelledRowsCount = 0 Then
		
		UpdateColumnIsAvailableOnServer();
		FillInDependentServiceDetailsSupply(ThisForm);
		
		CalculateDocumentTotals(ThisForm);
		
	EndIf;
	
	Return CancelledRowsCount;
	
EndFunction

&AtServer
Function CancelTSRowsByCostGroup(TSName, CurrentGroupNumber, CancellationStructure)
	
	CancelledRowsCount = 0;
	
	If TSName = CancellationStructure.CostGroupDescription.ProductTableName Then
		Return CancelledRowsCount;
	EndIf;
	
	FieldNameReasonForCancellation = "CancellationReason";
	If Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
		And Not TSName = "Services" Then
		FieldNameReasonForCancellation = "ReasonForCancellationOfProduction";
	EndIf;
	StructureOfReasonForCancellation = New Structure(FieldNameReasonForCancellation, CancellationStructure.CancellationReason);
	
	Table = Object[TSName].Unload(); // ValueTable
	Table.Indexes.Add("CostGroupNumber, Canceled");
	
	Filter = New Structure("CostGroupNumber, Canceled", CurrentGroupNumber, False);
	FoundRows = Table.FindRows(Filter);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each CurrentData In FoundRows Do
		
		If TSName = "SupplyWithMaterialsAndWorks"
			And CurrentData.SupplyOption = Enums.SupplyOptions.Ship Then
			Continue;
		EndIf;
		
		CancelledRowsCount = CancelledRowsCount + 1;
		
		CurrentData.Canceled = True;
		FillPropertyValues(CurrentData, StructureOfReasonForCancellation);
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	If TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "Services" Then
		
		StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails(TSName));
		
		AddCollateralActions(
			ThisObject,
			TSName,
			StructureOfActions,
			"WarehouseIsRequired, DateOfShipmentRequired_");
		
		If TSName = "SupplyWithMaterialsAndWorks" Then
			
			StructureOfActions.Insert(
				"CheckSeriesCalculateStatus",
				New Structure("Warehouse, SeriesSpecificationParameters, TableOfGoods",
					Object.MaterialsWarehouse, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, Table));
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(StructureOfActions) Then
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			FoundRows,
			StructureOfActions,
			Table,
			CachedValues);
	EndIf;
	
	Object[TSName].Load(Table);
	
	Return CancelledRowsCount;
	
EndFunction

&AtServer
Function CostGroupDescription()
	
	CostGroupDescription = New Structure;
	
	Columns = CostGroups.Unload(New Array).Columns; // ValueTableColumnCollection
	For Each Column In Columns Do
		CostGroupDescription.Insert(Column.Name, Column.ValueType.AdjustValue());
	EndDo;
	
	Return CostGroupDescription;
	
EndFunction

&AtServer
Function CostGroupDataByCostGroupNumber(CurrentGroupNumber)
	
	FilterStructure1 = New Structure("CostGroupNumber", CurrentGroupNumber);
	Return CostGroupData(FilterStructure1);

EndFunction

&AtServer
Function CostGroupData(FilterStructure1)
	
	CostGroupDescription = CostGroupDescription();
	
	FoundRows = CostGroups.FindRows(FilterStructure1);
	If Not FoundRows.Count() = 0 Then
		FillPropertyValues(CostGroupDescription, FoundRows[0]);
	EndIf;
	
	Return CostGroupDescription;

EndFunction

&AtServer
Function CostGroupSelectionStructure(CurrentData)
	
	FieldList =
		ProcessingByThirdPartiesClientServer.ListOfOrderCostGroupFieldsForProcessor(Object.GroupCosts);
	FilterStructure1 = ProcessingByThirdPartiesClientServer.CostGroupSelectionStructure(FieldList);
	
	If Not CurrentData = Undefined Then
		FillPropertyValues(FilterStructure1, CurrentData);
	EndIf;
	
	Return FilterStructure1;
	
EndFunction

&AtServer
Function NumberOfIdentifyingRows(CostGroupDescription)
	
	FilterStructure1 = New Structure("CostGroupNumber", CostGroupDescription.CostGroupNumber);
	FoundRows = Object.ManufacturedProducts.FindRows(FilterStructure1);
	
	Return FoundRows.Count();
	
EndFunction

&AtServer
Function CostGroupPresentation(Var_Group)
	
	Return Documents.SubcontractOrder2_5.CostGroupPresentation(Var_Group, Object.GroupCosts);
	
EndFunction

&AtServer
Function PutCostGroupDataInStorage(TSName)
	
	If TSName = "ManufacturedProducts"
		Or Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages
			And TSName = "SideAndIntermediateRelease"
		Then
		FilterStructure1 = Undefined;
	Else
		FilterStructure1 = New Structure("AllProductLinesAreCancelled", False);
	EndIf;
	
	Table = CostGroups.Unload(FilterStructure1);
	Return PutToTempStorage(Table, UUID);
	
EndFunction

#EndRegion
#Region References

&AtServer
Procedure ReadOrderData(NewOrders = Undefined)
	
	If Not Object.GroupCosts = Enums.CostGroupingsInTollingOrder.ByProductionStages Then
		Return;
	EndIf;
	
	Query = New Query;
	
	QueryTexts = New Array;
	
	#Region References
	
	QueryText =
	"SELECT
	|	References.CostGroupNumber AS CostGroupNumber,
	|	References.ReferenceOrder      AS ReferenceOrder
	|INTO TT_Orders
	|FROM
	|	&References AS References
	|WHERE
	|	&FilterByReferences
	|
	|INDEX BY
	|	ReferenceOrder
	|";
	
	If NewOrders = Undefined Then
		QueryText = StrReplace(QueryText, "&FilterByReferences", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&FilterByReferences", "References.ReferenceOrder IN(&FilterByReferences)");
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	QueryText =
	"SELECT
	|	References.CostGroupNumber          AS CostGroupNumber,
	|	References.ReferenceOrder               AS ReferenceOrder,
	|	TableOfStage.LineNumber                AS LineNumber,
	|	TableOfStage.Products               AS Products,
	|	TableOfStage.Characteristic             AS Characteristic,
	|	TableOfStage.NumberOfPackages         AS NumberOfPackages,
	|	TableOfStage.Count                 AS Count,
	|	TableOfStage.Package                   AS Package,
	|	TableOfStage.Recipient                 AS Recipient,
	|	TableOfStage.Purpose                 AS Purpose,
	|	TableOfStage.ProductionDate           AS DateOfReceipt,
	|	TableOfStage.CostShare              AS CostShare,
	|	TableOfStage.CostSharePerUnit     AS CostSharePerUnit,
	|	TableOfStage.ToExpenseAs           AS ToExpenseAs,
	|	TableOfStage.ExpenseItem             AS ExpenseItem,
	|	TableOfStage.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableOfStage.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableOfStage.RowID        AS RowID,
	|	TableOfStage.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfStage.RowCode                  AS RowCode,
	|	TableOfStage.Canceled                   AS Canceled,
	|	TableOfStage.CancellationReason              AS ReasonForCancellationOfProduction,
	|	TableOfStage.Period                     AS Period,
	|	TableOfStage.ToControlQuality  AS ToControlQuality,
	|	TableOfStage.QualityConfirmationDate  AS QualityConfirmationDate
	|FROM
	|	TT_Orders AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TableOfStage
	|	ON TableOfStage.Ref = References.ReferenceOrder
	|
	|ORDER BY
	|	References.ReferenceOrder,
	|	TableOfStage.LineNumber
	|";
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	QueryText =
	"SELECT
	|	References.CostGroupNumber          AS CostGroupNumber,
	|	References.ReferenceOrder               AS ReferenceOrder,
	|	TableOfStage.LineNumber                AS LineNumber,
	|	TableOfStage.Products               AS Products,
	|	TableOfStage.Characteristic             AS Characteristic,
	|	TableOfStage.NumberOfPackages         AS NumberOfPackages,
	|	TableOfStage.Count                 AS Count,
	|	TableOfStage.Package                   AS Package,
	|	TableOfStage.Recipient                 AS Recipient,
	|	TableOfStage.Purpose                 AS Purpose,
	|	TableOfStage.ProductionDate           AS DateOfReceipt,
	|	TableOfStage.ToExpenseAs           AS ToExpenseAs,
	|	TableOfStage.ExpenseItem             AS ExpenseItem,
	|	TableOfStage.DimensionOfExpenses          AS DimensionOfExpenses,
	|	TableOfStage.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
	|	TableOfStage.RowID        AS RowID,
	|	TableOfStage.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfStage.RowCode                  AS RowCode,
	|	TableOfStage.Canceled                   AS Canceled,
	|	TableOfStage.CancellationReason              AS ReasonForCancellationOfProduction,
	|	TableOfStage.Price                       AS Price,
	|	TableOfStage.Sum                      AS Sum,
	|	TableOfStage.ProductCostElement          AS ProductCostElement,
	|	TableOfStage.Period                     AS Period,
	|	TableOfStage.ToControlQuality  AS ToControlQuality,
	|	TableOfStage.QualityConfirmationDate  AS QualityConfirmationDate
	|FROM
	|	TT_Orders AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS TableOfStage
	|	ON TableOfStage.Ref = References.ReferenceOrder
	|
	|ORDER BY
	|	References.ReferenceOrder,
	|	TableOfStage.LineNumber
	|";
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region SupplyWithMaterialsAndWorks
	
	QueryText =
	"SELECT
	|	References.CostGroupNumber             AS CostGroupNumber,
	|	References.ReferenceOrder                  AS ReferenceOrder,
	|	TableOfStage.Ref.ReferenceOrder           AS OrderDocument,
	|	TableOfStage.LineNumber                   AS LineNumber,
	|	TableOfStage.Products                  AS Products,
	|	TableOfStage.Characteristic                AS Characteristic,
	|	TableOfStage.Series                         AS Series,
	|	TableOfStage.Package                      AS Package,
	|	TableOfStage.NumberOfPackages            AS NumberOfPackages,
	|	TableOfStage.Count                    AS Count,
	|	TableOfStage.SupplyOption            AS SupplyOption,
	|	TableOfStage.WithAssignment                   AS WithAssignment,
	|	TableOfStage.DateOfShipment                  AS DateOfShipment,
	|	TableOfStage.Warehouse                         AS Warehouse,
	|	TableOfStage.Produced                  AS Produced,
	|	TableOfStage.BillOfMaterials                  AS BillOfMaterials,
	|	TableOfStage.Purpose                    AS Purpose,
	|	TableOfStage.SupplyAssignment         AS SupplyAssignment,
	|	TableOfStage.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	TableOfStage.RowCode                     AS RowCode,
	|	TableOfStage.ProductCostElement             AS ProductCostElement,
	|	TableOfStage.Canceled                      AS Canceled,
	|	TableOfStage.CancellationReason                 AS ReasonForCancellationOfProduction,
	|	TableOfStage.Period                        AS Period,
	|	TableOfStage.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	TableOfStage.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TableOfStage.RowID           AS RowID,
	|	TableOfStage.MaterialApplication           AS MaterialApplication,
	|	TableOfStage.CommunicationKeySet                AS CommunicationKeySet
	|FROM
	|	TT_Orders AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TableOfStage
	|	ON TableOfStage.Ref = References.ReferenceOrder
	|
	|ORDER BY
	|	References.ReferenceOrder,
	|	TableOfStage.LineNumber
	|";
	QueryTexts.Add(QueryText);
	
	QueryText =
	"SELECT
	|	References.CostGroupNumber             AS CostGroupNumber,
	|	References.ReferenceOrder                  AS ReferenceOrder,
	|	TableOfStage.Ref.ReferenceOrder           AS OrderDocument,
	|	TableOfStage.LineNumber                   AS LineNumber,
	|	TableOfStage.ConnectionKey                     AS ConnectionKey,
	|	TableOfStage.BillOfMaterials                  AS BillOfMaterials,
	|	TableOfStage.ParentCommunicationKey             AS ParentCommunicationKey,
	|	TableOfStage.ParentSpecification          AS ParentSpecification,
	|	TableOfStage.RowsCount               AS RowsCount,
	|	TableOfStage.LinkKeyBOM         AS LinkKeyBOM
	|FROM
	|	TT_Orders AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.MaterialsAndWorksSets AS TableOfStage
	|	ON TableOfStage.Ref = References.ReferenceOrder
	|
	|ORDER BY
	|	References.ReferenceOrder,
	|	TableOfStage.LineNumber
	|";
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.SetParameter("References", Object.References.Unload());
	Query.SetParameter("FilterByReferences", NewOrders);
	
	Result = Query.ExecuteBatch();
	
	UBound = Result.UBound();
	
	// Tables are supplemented if orders have been added, otherwise they are refilled
	If NewOrders = Undefined Then
		Object.ManufacturedProducts.Clear();
		Object.SideAndIntermediateRelease.Clear();
		Object.SupplyWithMaterialsAndWorks.Clear();
		Object.MaterialsAndWorksSets.Clear();
	EndIf;
	
	For Each CurRow In Result[UBound - 3].Unload() Do
		
		NewRow = Object.ManufacturedProducts.Add();
		FillPropertyValues(NewRow, CurRow);
		
		If NewRow.DateOfReceipt = '00010101' Then
			If Object.OneDateReceipt Then
				NewRow.DateOfReceipt = Object.DateOfReceipt;
			Else
				NewRow.DateOfReceipt = Documents.ProductionStage2_2.PlannedDateOfReceipt(CurRow.ReferenceOrder);
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each CurRow In Result[UBound - 2].Unload() Do
		
		NewRow = Object.SideAndIntermediateRelease.Add();
		FillPropertyValues(NewRow, CurRow);
		
		If NewRow.DateOfReceipt = '00010101' Then
			If Object.OneDateReceipt Then
				NewRow.DateOfReceipt = Object.DateOfReceipt;
			Else
				NewRow.DateOfReceipt = Documents.ProductionStage2_2.PlannedDateOfReceipt(CurRow.ReferenceOrder);
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each CurRow In Result[UBound - 1].Unload() Do
		
		NewRow = Object.SupplyWithMaterialsAndWorks.Add();
		FillPropertyValues(NewRow, CurRow);
		
		If NewRow.DateOfShipment = '00010101'
			And Object.NotShipInInstallments Then
			NewRow.DateOfShipment = Object.DateOfShipment;
		EndIf;
		
	EndDo;
	
	For Each CurRow In Result[UBound].Unload() Do
		
		NewRow = Object.MaterialsAndWorksSets.Add();
		FillPropertyValues(NewRow, CurRow);
		
	EndDo;
	
EndProcedure

&AtServer
Function OrderDataForRecording()
	
	OrderData_3 = ProductionManagement.DataStructureOfProductionStages();
	
	OrderData_3.Insert("SubcontractOrder", Object.Ref);
	
	#Region OrderDetailsForProcessor
	
	OrderData_3.OrderDetailsForProcessor = OrderDetailsForProcessor();
	
	#EndRegion
	
	#Region References
	
	TabularSection = Object.References.Unload();
	
	Column = TabularSection.Columns.ReferenceOrder; // ValueTableColumn
	Column.Name = "Ref";
	
	Column = TabularSection.Columns.OrderDocument; // ValueTableColumn
	Column.Name = "ReferenceOrder";
	
	For Each CurRow In TabularSection Do
		FillPropertyValues(OrderData_3.Attributes.Add(), CurRow);
	EndDo;
	
	OrderData_3.Attributes.FillValues(True,                       "ProductionByThirdParty");
	OrderData_3.Attributes.FillValues(True,                       "ProductionByThirdParty2_5");
	OrderData_3.Attributes.FillValues(Object.Ref,                "SubcontractOrder");
	OrderData_3.Attributes.FillValues(Object.OneDateReceipt, "ProductionInOneDay");
	OrderData_3.Attributes.FillValues(Object.DateOfReceipt,       "ProductionDate");
	OrderData_3.Attributes.FillValues(Object.NotShipInInstallments,    "NotShipInInstallments");
	OrderData_3.Attributes.FillValues(Object.DateOfShipment,          "DateOfShipment");
	OrderData_3.Attributes.FillValues(Object.LeaveProductsAtSubcontractor, "LeaveProductsAtSubcontractor");
	
	OrderData_3.Attributes.Indexes.Add("Ref");
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	TabularSection = Object.ManufacturedProducts.Unload();
	
	Column = TabularSection.Columns.ReferenceOrder; // ValueTableColumn
	Column.Name = "Ref";
	
	Column = TabularSection.Columns.BillOfMaterials; // ValueTableColumn
	Column.Name = "SpecificationOfOrderToProcessor";
	
	Column = TabularSection.Columns.Stage; // ValueTableColumn
	Column.Name = "StageOfOrderToProcessor";
	
	Column = TabularSection.Columns.DateOfReceipt; // ValueTableColumn
	Column.Name = "ProductionDate";
	
	Column = TabularSection.Columns.CancellationReason; // ValueTableColumn
	Column.Name = "ReasonForCancellationOfOrderToProcessor";
	
	Column = TabularSection.Columns.ReasonForCancellationOfProduction; // ValueTableColumn
	Column.Name = "CancellationReason";
	
	For Each CurRow In TabularSection Do
		
		NewRow = OrderData_3.ManufacturedProducts.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.Department = Object.Department;
		
	EndDo;
	
	OrderData_3.ManufacturedProducts.Indexes.Add("Ref");
	
	#EndRegion
	
	#Region SideAndIntermediateRelease
	
	TabularSection = Object.SideAndIntermediateRelease.Unload();
	
	Column = TabularSection.Columns.ReferenceOrder; // ValueTableColumn
	Column.Name = "Ref";
	
	Column = TabularSection.Columns.DateOfReceipt; // ValueTableColumn
	Column.Name = "ProductionDate";
	
	Column = TabularSection.Columns.CancellationReason; // ValueTableColumn
	Column.Name = "ReasonForCancellationOfOrderToProcessor";
	
	Column = TabularSection.Columns.ReasonForCancellationOfProduction; // ValueTableColumn
	Column.Name = "CancellationReason";
	
	For Each CurRow In TabularSection Do
		
		NewRow = OrderData_3.SideAndIntermediateRelease.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.Department = Object.Department;
		
	EndDo;
	
	OrderData_3.SideAndIntermediateRelease.Indexes.Add("Ref");
	
	#EndRegion
	
	#Region SupplyWithMaterialsAndWorks
	
	TabularSection = Object.SupplyWithMaterialsAndWorks.Unload();
	
	Column = TabularSection.Columns.ReferenceOrder; // ValueTableColumn
	Column.Name = "Ref";
	
	Column = TabularSection.Columns.ReasonForCancellationOfProduction; // ValueTableColumn
	Column.Name = "CancellationReason";
	
	For Each CurRow In TabularSection Do
		
		NewRow = OrderData_3.SupplyWithMaterialsAndWorks.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.Department = Object.Department;
		
	EndDo;
	
	OrderData_3.SupplyWithMaterialsAndWorks.Indexes.Add("Ref");
	
	#EndRegion
	
	#Region MaterialsAndWorksSets
	
	TabularSection = Object.MaterialsAndWorksSets.Unload();
	
	Column = TabularSection.Columns.ReferenceOrder; // ValueTableColumn
	Column.Name = "Ref";
	
	For Each CurRow In TabularSection Do
		
		NewRow = OrderData_3.MaterialsAndWorksSets.Add();
		FillPropertyValues(NewRow, CurRow);
		
	EndDo;
	
	OrderData_3.MaterialsAndWorksSets.Indexes.Add("Ref");
	
	#EndRegion
	
	OrderData_3.CheckingTSManufacturedProducts = True;
	OrderData_3.CheckingTSSideAndIntermediateRelease = True;
	OrderData_3.CheckingTSSupplyWithMaterialsAndWorks = True;
	
	Return OrderData_3;
	
EndFunction

&AtServer
Function OrderDetailsForProcessor()
	
	OrderDetailsForProcessor = New Structure;
	
	OrderDetailsForProcessor.Insert("SubcontractOrder",    Object.Ref);
	OrderDetailsForProcessor.Insert("Posted",              Object.Posted);
	OrderDetailsForProcessor.Insert("Status",                Object.Status);
	OrderDetailsForProcessor.Insert("OneDateReceipt", Object.OneDateReceipt);
	OrderDetailsForProcessor.Insert("DateOfReceipt",       Object.DateOfReceipt);
	OrderDetailsForProcessor.Insert("NotShipInInstallments",    Object.NotShipInInstallments);
	OrderDetailsForProcessor.Insert("DateOfShipment",          Object.DateOfShipment);
	
	OrderDetailsForProcessor.Insert(
		"LeaveProductsAtSubcontractor",
		Object.LeaveProductsAtSubcontractor);
	
	Return OrderDetailsForProcessor;
	
EndFunction

&AtClient
Function BlockOrders(Cancel = Undefined)
	
	If OrdersBlocked
		Or Object.References.Count() = 0 Then
		Return True;
	EndIf;
	
	StageList = New Array;
	For Each CurRow In Object.References Do
		StageList.Add(New Structure("Ref,DataVersion", CurRow.ReferenceOrder, CurRow.DataVersion));
	EndDo;
	
	WarningText = BlockOrdersOnServer(StageList, UUID);
	If WarningText <> Undefined Then
		Cancel = True;
		ShowMessageBox(, WarningText);
		Return False;
	EndIf;
	
	OrdersBlocked = True;
	Return True;
	
EndFunction

&AtServerNoContext
Function BlockOrdersOnServer(Val StageList, Val FormIdentifier)

	For Each ParametersOfStage In StageList Do
		Try
			LockDataForEdit(ParametersOfStage.Ref, ParametersOfStage.DataVersion, FormIdentifier);
		Except
			BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			WarningText =
				NStr("vi = 'Không thể phong tỏa đối tượng %1, do nguyên nhân:
					|%2';
					|ru = 'Не удалось заблокировать объект %1, по причине:
					|%2';
					|en = 'Cannot lock the %1 object. Reason:
					|%2'; fa = 'Cannot lock the %1 object. Reason:
					|%2';
					|it = 'Non è stato possibile bloccare l''oggetto %1, a causa di:
					|%2';
					|pl = 'Nie udało się zablokować obiekt %1, z powodu:
					|%2';
					|tr = '%1 nesnesinin bloke edilememe nedeni:
					|%2'");
			Return StrTemplate(WarningText, ParametersOfStage.Ref, BriefErrorDescription);
		EndTry;
	EndDo;
	
	Return Undefined;

EndFunction

&AtServer
Procedure UnblockOrdersOnServer()

	If Not OrdersBlocked Then
		Return;
	EndIf;
	
	For Each Stage In Object.References Do
		UnlockDataForEdit(Stage.ReferenceOrder, UUID);
	EndDo;
	
	OrdersBlocked = False;

EndProcedure

#EndRegion

#Region MaterialsAndWorksSets

&AtClient
Procedure BeforeDeletingRowsIncludedInSets()
	
	SelectedRows = Items.SupplyWithMaterialsAndWorks.SelectedRows;
	
	If ProductDataManagementClient.ThereAreLinesIncludedInSet(Object, SelectedRows) Then
		
		ProcessDeletionOfRowsIncludedInSets(SelectedRows);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet()
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If ValueIsFilled(CurrentData.CommunicationKeySet) Then
		
		RowsIDs = CommonClientServer.ValueInArray(Items.SupplyWithMaterialsAndWorks.CurrentRow);
		ProcessDeletionOfRowsIncludedInSets(RowsIDs);
		
		CurrentData.CommunicationKeySet = Undefined;
		CurrentData.IncludedInSet   = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessDeletionOfRowsIncludedInSets(RowsIDs)
	
	ProductDataManagement.ProcessDeletionOfRowsIncludedInSets(Object, RowsIDs);
	
EndProcedure

&AtClient
Procedure ProcessSplitOfStringIncludedInSet(NewRow)
	
	If ValueIsFilled(NewRow.CommunicationKeySet) Then
		ProcessSplitOfStringIncludedInSetServer(NewRow.CommunicationKeySet);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSplitOfStringIncludedInSetServer(CommunicationKeySet)
	
	ProductDataManagement.AdjustTableSetsOfMaterialsAndWorks(
		Object.MaterialsAndWorksSets, CommunicationKeySet, 1);
	
EndProcedure

#EndRegion

#Region Supply

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.SupplyWithMaterialsAndWorks);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	
	Return DocumentParameters;
	
EndFunction

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	Return
		ProvisionInDocumentsServer.SoftwareSelectionParameters(
			ThisObject,
			Items.SupplyWithMaterialsAndWorks.CurrentRow,
			Mode);
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters =
		SupplyClientServer.InitializeFillVerificationParameters(
			"SupplyWithMaterialsAndWorks",
			NStr("vi = 'Đảm bảo';
				|ru = 'Обеспечение';
				|en = 'Supply'; fa = 'Supply';
				|it = 'Approvvigionamento';
				|pl = 'Zaopatrzenie';
				|tr = 'Tedarik'"));
	
	CheckParameters.Fields.Delete("Warehouse");
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.SupplyWithMaterialsAndWorks, 
				Items.SupplyWithMaterialsAndWorks.CurrentRow,
				CheckParameters,
				Undefined,
				Mode) Then
		Return Undefined;
	EndIf;
	
	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks;
	
	Return FormParameters;
	
EndFunction

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisForm);
	
EndFunction

&AtClient
Procedure UpdateColumnIsAvailableOnClient(TSName, StructureOfActions, CurrentData)
	
	If Not TSName = "SupplyWithMaterialsAndWorks" Then
		Return;
	EndIf;
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnIsAvailableOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnIsAvailableOnServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisForm);
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	Documents.SubcontractOrder2_5.AfterFillingOutCollateral(Object, Changes, Mode, FillParameters);
	
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(
		Changes,
		"SumCanceled");
	
	// Updating the mandatory filling signs.
	StructureOfActions = New Structure;
	
	CostGroupPresentations = New Map;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	AddCollateralActions(
		ThisObject,
		"SupplyWithMaterialsAndWorks",
		StructureOfActions,
		"WarehouseIsRequired,DateOfShipmentRequired_");
	
	RowsToProcess = New Array();
	
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(
		ThisObject, AvailableRemainingEmbeddingOptions);
	
	For Each Update In Changes Do
		
		CurrentData = Update.String;
		
		If CostGroupPresentations.Get(CurrentData.CostGroupNumber) = Undefined Then
			
			CurrentData.ExpenseGroup =
				CostGroupPresentation(CostGroupDataByCostGroupNumber(CurrentData.CostGroupNumber));
			
			CostGroupPresentations.Insert(CurrentData.CostGroupNumber, CurrentData.ExpenseGroup);
			
		EndIf;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		CollectionOnForm,
		CachedValues);
	
	ConfigureDependentFormElements(ThisObject, "NotShipInInstallments");
	
	CalculateDocumentTotals(ThisObject);
	
	FillInDependentServiceDetailsSupply(ThisObject);
	
	UpdateColumnIsAvailableOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInServiceDetailsOfStageSupportInLine(Form, CurrentData)
	
	If Form.Object.GroupCosts <>
			PredefinedValue("Enum.CostGroupingsInTollingOrder.ByProductionStages") Then
		Return;
	EndIf;
	
	Form.Items.SupplyWithMaterialsAndWorksSupplyAssignment.ChoiceList.LoadValues(
		CurrentData.AppointmentSelectionList.UnloadValues());
	
	Form.RefsFilterInSelectionOfAssignmentsForm.LoadValues(
		CurrentData.AppointmentSelectionList.UnloadValues());
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function DependentDetails(TSName)
	
	Result = New Structure;
	If TSName = "SupplyWithMaterialsAndWorks" Then
		Result.Insert("Canceled", "Sum");
	ElsIf TSName = "Services" Then
		Result.Insert("Canceled", "AmountIncludingVAT, VATAmount");
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function MaximumAdvancePaymentDate()
	
	MaxAdvanceDate = '00010101';
	
	For Each CurStage In Object.PaymentScheduleSteps Do
		If CurStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt")
			Or CurStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation") Then
			MaxAdvanceDate = Max(MaxAdvanceDate, CurStage.PaymentDate);
		EndIf;
	EndDo;
	
	Return MaxAdvanceDate;
	
EndFunction

&AtServerNoContext
Function WarehouseSelectionData(Warehouse)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Warehouses.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
	|	AND Warehouses.IsFolder = FALSE
	|	AND Warehouses.SelectGroup <> VALUE(Enum.SelectWarehouseGroup.Disable)
	|";
	Query.SetParameter("GroupOfWarehouses", Warehouse);
	
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return WarehouseArray;
	
EndFunction

&AtClient
Procedure ProcessAddressChange(Item, NameOfAddressDetails)
	
	AttributesNames = GoodsDeliveryClientServer.NamesOfDetailsOfDeliveryAddresses(NameOfAddressDetails);
	
	If IsBlankString(Object[AttributesNames.NameOfDetailsOfDeliveryAddress]) Then
		
		GoodsDeliveryClient.ClearAddressPresentation(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
	Else
		
		GoodsDeliveryClient.WhenChangingAddressPresentation(
			Item,
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue]);
		
		DeliveryAddressOnChangeATServer(
			Object[AttributesNames.NameOfDetailsOfDeliveryAddress],
			Object[AttributesNames.NameOfAttributeOfDeliveryAddressValue],
			Object[AttributesNames.AttributeNameOfDeliveryAddressFieldValues]);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryAddressOnChangeATServer(Address, AddressValue, FieldValueAddress)
	
	CustomFormatAddress = ContactsManager.AddressEnteredInFreeFormat(AddressValue);
	If Not CustomFormatAddress Then
		
		CountryData1 = ContactsManager.ContactInformationAddressCountry(AddressValue);
		
		NewAddressStructure = ContactsManager.InfoAboutAddress();
		NewAddressStructure.Presentation = Address;
		NewAddressStructure.Country = CountryData1.Description;
		NewAddressStructure.CountryCode = CountryData1.Code;
		
		AddressValue = ContactsManager.ContactInformationInJSON(
			NewAddressStructure,
			Enums.ContactInformationTypes.Address);
		
		SetAddressTypeInFreeForm(AddressValue);
		
	EndIf;
	
	FieldValueAddress = ContactsManager.ContactInformationToXML(
		AddressValue,
		Address,
		Enums.ContactInformationTypes.Address);
	
EndProcedure

&AtServerNoContext
Procedure SetAddressTypeInFreeForm(DeliveryAddressValue)
	
	StringTypeToReplace = """addressType"": ""Administrative-territorial""";
	StringIsFreeType = """addressType"": ""FreeForm""";
	DeliveryAddressValue = StrReplace(DeliveryAddressValue, StringTypeToReplace, StringIsFreeType);
	
EndProcedure

&AtServer
Procedure UpdateTextDocumentsBasedOn()
	
	ProcessingOfEAEU = Object.BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5;
	
	If ValueIsFilled(Object.Ref) And ProcessingOfEAEU Then
		TextDocumentsBasedOn = VATAccountingLocalization.EventDocumentsOnPreliminaryDeliveries(Object, Object.DocumentAmount);
		If ValueIsFilled(TextDocumentsBasedOn) Then
			Items.GroupDocumentsAboutUpcomingDelivery.Visible = True;
		Else
			Items.GroupDocumentsAboutUpcomingDelivery.Visible = False;
		EndIf;
	Else
		Items.GroupDocumentsAboutUpcomingDelivery.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ResponseBeforeWrite = False;

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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	ElsIf Item.Name = "sh_ShamsiInput_ExecutionDate" Then
		ExecutionDateOnChange(Items.ExecutionDate);
	ElsIf Item.Name = "sh_ShamsiInput_ApprovalDate" Then
		ApprovalDateOnChange(Items.ApprovalDate);
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
