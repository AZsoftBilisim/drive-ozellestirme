#Region Variables

&AtClient
Var CachedValues;

&AtServer
Var CachedValues;

&AtClient
Var CurDataId;

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
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromProduction Then
		// Such documents are no longer used and are only opened for viewing
		ReadOnly = True;
	EndIf;
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.OtherGoodsRecordingAsReceived.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.OtherGoodsRecordingAsReceived.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		
	ElsIf Parameters.FillingValues.Property("FillByWarehouseDocument") Then
		
		RefillByNotes();
		Modified = True;
		
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, "GoodsCCDNumber");
	
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
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.OtherGoodsRecordingAsReceived.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.OtherGoodsRecordingAsReceived.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfTablePart();
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, False);
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	// Selection of articles and analytics.
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	InventoryInOperationServer.FillInServiceDetailsForBatchOfGoodsAndMaterials(Object.Goods);
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
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
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		Actions = New Structure;
		
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			Actions);
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, , , Actions);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	ElsIf PurchasesClient.ThisIsSelectionOfCCDNumber(ChoiceSource) Then
		
		ProcessSelectionOfCCDNumber(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.OtherGoodsRecordingAsReceived.Form.WriteOffDocumentsSelectionForm" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.LotsOfInventoryInOperation.Form.PickForm"
		Or ChoiceSource.FormName = "Catalog.LotsOfInventoryInOperation.Form.PickFormTM" Then
		
		ProcessingOfSelectionSelectionOfGoodsInOperation(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.InventoryConsumption.Form.ChoiceForm" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		If Not CurrentData.ExpenseAs = ValueSelected Then
			CurrentData.ExpenseAs = ValueSelected;
			Modified = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Setting up accounting accounts.
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		Cancel = True;
		ReusablePackageClient.OfferToPickUpMultiTurnContainer(
			ThisForm,
			"Goods",
			"Products,Characteristic,Count",
			New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
		Notify("RecordingDocumentBasedOnInventoryInventoryOfBusinessCenter",, Object.Ref);
	EndIf;
	NotifyAboutDocument(WriteParameters);
	
	DocumentCorrectionClient.AfterWrite(Object);
	
	
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
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup" And ItIsRequiredToUpdateTitleIsSubjectToExciseDuty Then
		CalculateNumberOfExcisableItemsDeferred();
		ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	ClearGoods = Object.Goods.Count() > 0;
	
	If ClearGoods Then
		CallbackDescription = New CallbackDescription("BusinessOperationOnChangeCompletion", ThisObject, ClearGoods);
		QueryText = NStr("vi = 'Danh sách ""Hàng hóa"" sẽ bị xóa. Tiếp tục?';
						|ru = 'Список ""Товары"" будет очищен. Продолжить?';
						|en = 'The Item list will be cleared. Continue?'; fa = 'The Item list will be cleared. Continue?';
						|it = 'L''elenco ""Merci"" verrà cancellato. Continuare?';
						|pl = 'Lista ""Towaty"" zostanie wyczyszczona. Kontynuować?';
						|tr = '""Ürünler"" listesi temizlenecek. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		BusinessOperationOnChangeCompletion(DialogReturnCode.Yes, ClearGoods);
	EndIf;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer(True);
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DepartmentOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.Form.DocumentForm.Item.Currency.OnChange");
	
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOnChangeServer();
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "Document.OtherGoodsRecordingAsReceived.Form.DocumentForm.Item.LineOfBusiness.OnChange");
	
	DirectionOfActivityWhenChangingOnServer();
	
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

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure DateOfReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfReceiptOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	// Setting up accounting accounts.
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return; // So that the UT is not an empty handler 
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters,Copy);

	If NewRow And Not Copy Then
		
		WhenAddingLineOfProductsOnClient_(Items.Goods.CurrentData);
		
		StructureOfActions = New Structure();
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(Items.Goods.CurrentData, StructureOfActions, Undefined);
	//Setting up accounting accounts 
	ElsIf NewRow And Copy Then
		
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters);
	
	ProductsAfterChangeServer(SeriesStatusesNeedToBeUpdated, CachedValues);
	
EndProcedure

&AtServer
Procedure ProductsAfterChangeServer(SeriesStatusesNeedToBeUpdated, CachedValues)
	
	RowID = Items.Goods.CurrentRow;
	
	If RowID = Undefined Then
		Return;
	EndIf;
	
	TableRow = Object.Goods.FindByID(RowID);
	
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(RowID, CachedValues);
		ProductsClientServer.UpdateCachedValuesToAccountForSeries(
					TableRow, CachedValues,SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters,True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(StructureOfActions, ThisObject, Object, CurrentRow);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForTheRNPTIsMaintained Then
		CurrentRow.CCDNumber = Undefined;
		CurrentRow.CCDNumberType = Undefined;
		CurrentRow.OriginCountry = Undefined;
	EndIf;
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenCharacteristicChanges(StructureOfActions, ThisObject, Object);

	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	EndIf;

	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsIndividualOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);

	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsLotOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	If Not ValueIsFilled(CurrentRow.Lot)
	 Or CurrentRow.Count > 0 And CurrentRow.NumberOfPackages > 0 Then
		Return;
	EndIf;
	
	StocktakingRecord = GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentRow.Lot, "StocktakingRecord");
	
	If StocktakingRecord Then
		CurrentRow.Count = 1;
		CurrentRow.NumberOfPackages = 1;
		CurrentRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	EndIf;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		Var_Parameters,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsExpenseAsStartChoice(Item, ChoiceData, StandardProcessing)
	
	Cancel = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	ClearMessages();
	If Not ValueIsFilled(Object.Organization) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền giá trị trường ""Doanh nghiệp"".';
												|ru = 'Не заполнено значение поля ""Организация"".';
												|en = '""Company"" is required.'; fa = '""Company"" is required.';
												|it = 'Il valore del campo ""Società"" non è compilato.';
												|pl = 'Wartość pola ""Firma"" nie jest wypełniona.';
												|tr = '""İş yeri"" alanının değeri doldurulmadı.'"),
																		,
																		"Organization",
																		"Object",
																		Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Department) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền giá trị trường ""Bộ phận"".';
												|ru = 'Не заполнено значение поля ""Подразделение"".';
												|en = '""Business unit"" is required.'; fa = '""Business unit"" is required.';
												|it = 'Il valore del campo ""Reparto"" non è compilato.';
												|pl = 'Wartość pola ""Dział"" nie jest wypełniona.';
												|tr = '""Departman"" alanının değeri doldurulmaz.'"),
																		,
																		"Department",
																		"Object",
																		Cancel);
	EndIf;
	If Not ValueIsFilled(CurrentData.Products) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền cột ""Mặt hàng"" trong dòng %1 danh sách ""Hàng hóa"".';
				|ru = 'Не заполнена колонка ""Номенклатура"" в строке %1 списка ""Товары"".';
				|en = 'Column ""Items"" in line %1 of the Item list is not filled in.'; fa = 'Column ""Items"" in line %1 of the Item list is not filled in.';
				|it = 'Non è compilata la colonna ""Nomenclatura"" nella riga %1 dell''elenco ""Merci"".';
				|pl = 'Kolumna ""Wykaz towarów"" w wierszu %1 na liście ""Wiersze pozycji"" nie jest wypełniona.';
				|tr = 'Ürün listesinin %1 satırında ""Öğe"" sütunu doldurulmadı.'"),
			CurrentData.LineNumber);
		CommonClientServer.MessageToUser(MessageText, , "Goods.Products", "Object", Cancel);
	EndIf;
	If CurrentData.ItemVariantsAreUsed And Not ValueIsFilled(CurrentData.Characteristic) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền cột ""Đặc tính"" trong dòng %1 danh sách ""Hàng hóa"".';
				|ru = 'Не заполнена колонка ""Характеристика"" в строке %1 списка ""Товары"".';
				|en = 'Column ""Variant"" in line %1 of the Item list is not filled in.'; fa = 'Column ""Variant"" in line %1 of the Item list is not filled in.';
				|it = 'Non è compilata la colonna ""Caratteristica"" nella riga %1 dell''elenco ""Merci"".';
				|pl = 'Kolumna ""Charakterystyka"" w wierszu %1 na liście ""Wiersze pozycji"" nie jest wypełniona.';
				|tr = '""Ürünler"" listesinin %1 satırında ""Varyant"" sütunu doldurulmadı.'"),
			CurrentData.LineNumber);
		CommonClientServer.MessageToUser(MessageText, , "Goods.Products", "Object", Cancel);
	EndIf; 
	If Not ValueIsFilled(CurrentData.ExpenseAndIncomeItem) Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền cột ""Dạng chi phí"" tại dòng %1 của danh sách ""Hàng hóa"".';
				|ru = 'Не заполнена колонка ""Статья расходов"" в строке %1 списка ""Товары"".';
				|en = 'Column ""Expense item"" in line %1 of the Item list is not filled in.'; fa = 'Column ""Expense item"" in line %1 of the Item list is not filled in.';
				|it = 'La colonna ""Voce di spesa"" nella riga %1 dell''elenco ""Merci"" non è compilata.';
				|pl = 'Kolumna ""Pozycja wydatków"" w wierszu %1 na liście ""Wiersze pozycji"" nie jest wypełniona.';
				|tr = 'Ürün listesinin %1 satırındaki ""Gider kalemi"" sütunu doldurulmamış.'"),
			CurrentData.LineNumber);
		CommonClientServer.MessageToUser(MessageText, , "Goods.ExpenseAndIncomeItem", "Object", Cancel);
	EndIf;
	
	StandardProcessing = False;
	
	If Cancel Then
		Return;
	EndIf;

	FilterParameters = New Structure;
	FilterParameters.Insert("Organization", Object.Organization);
	FilterParameters.Insert("Department", Object.Department);
	FilterParameters.Insert("Products", CurrentData.Products);
	FilterParameters.Insert("ExpenseItem", CurrentData.ExpenseAndIncomeItem);
	FilterParameters.Insert("Characteristic", ?(ValueIsFilled(CurrentData.Characteristic),
		CurrentData.Characteristic, Undefined));
	FilterParameters.Insert("Individual", ?(ValueIsFilled(CurrentData.Individual),
		CurrentData.Individual, Undefined));
	FilterParameters.Insert("DimensionOfExpenses", ?(ValueIsFilled(CurrentData.DimensionOfExpenses),
		CurrentData.DimensionOfExpenses, Undefined));

	ParametersStructure = New Structure("Filter,CheckForCorrections", FilterParameters, True);

	OpenForm("Document.InventoryConsumption.Form.ChoiceForm", ParametersStructure, ThisObject);
	
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
		Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, Actions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
																Item.EditText,
																AdditionalParameters);
	
	PurchasesClient.OpenFormForCreatingGTDNumber(ThisObject, CreationParameters);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsAssetIDAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	PickingParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation(Object.Date, Object.Organization, Object.Department);
	PickingParameters.CurrentRegistrar = Object.Ref;

	InventoryInOperationClient.AutoSelectionByInventoryNumber(
		Text, 
		PickingParameters,
		ChoiceData,
		StandardProcessing);
		
	Return; // the UT has an empty handler
	
EndProcedure

&AtClient
Procedure GoodsAssetIDChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;

	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	CurrentData.AssetID = ValueSelected.AssetID;
	CurrentData.Products = ValueSelected.Products;
	CurrentData.Characteristic = ValueSelected.Characteristic;
	CurrentData.Series = ValueSelected.Series;
	CurrentData.Individual = ValueSelected.Individual;
	CurrentData.Lot = ValueSelected.Lot;
	CurrentData.LineOfBusiness = ValueSelected.LineOfBusiness;
	CurrentData.StocktakingRecord = ValueSelected.StocktakingRecord;
	CurrentData.AccountingForIndividuals = ValueSelected.AccountingForIndividuals;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(StructureOfActions, ThisObject, Object, CurrentData);
	AddActionsToStructureWhenCharacteristicChanges(StructureOfActions, ThisObject, Object);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable", 
		New Structure("FormName, TabularSectionName", FormName, "Goods"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	Return; // the UT has an empty handler

EndProcedure

&AtClient
Procedure GoodsLotChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;

	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.AssetID = ValueSelected.AssetID;
	CurrentData.Lot = ValueSelected.Lot;
	CurrentData.StocktakingRecord = ValueSelected.StocktakingRecord;
	CurrentData.AccountingForIndividuals = ValueSelected.AccountingForIndividuals;

EndProcedure

&AtClient
Procedure GoodsDateOfCompletionOfOperationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Goods.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Period", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Products", CurrentData.Products);
	FormParameters.Insert("Characteristic", CurrentData.Characteristic);
	FormParameters.Insert("Series", CurrentData.Series);
	FormParameters.Insert("LineOfBusiness", CurrentData.LineOfBusiness);
	
	OpenForm("Catalog.LotsOfInventoryInOperation.Form.SelectEndDateForm", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure GoodsToControlQualityOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
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
Procedure ChangeTheQualityOfTheItem(Command)
	
	CurrentData = Items.Goods.CurrentData;
	ClearMessages();
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClient.MessageToUser(MessageText);
		Return
	EndIf;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentData.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentData.Package);
	EndIf;	
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
	SeriesVerificationParameters.SeriesSpecificationParameters = SeriesSpecificationParameters;
	SeriesVerificationParameters.Warehouse = Object.Warehouse;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	ClearMessages();
	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ không điền bảng ""Hàng hóa"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""Товары"". Цены не могут быть заполнены';
							|en = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices'; fa = 'The ""Goods"" table in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""Merci"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Wiersze pozycji"". Ceny nie mogą być wypełnione.';
							|tr = 'Belgedeki ""Ürünler"" tablosu doldurulmamıştır. Fiyatlar doldurulamıyor'");
		CommonClientServer.MessageToUser(MessageText,,"Goods","Object");
		Return;
	EndIf;
	
	If ValueIsFilled(Object.PriceKind) Then
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	Else
		MessageText = NStr("vi = 'Chưa chỉ ra dạng giá';
							|ru = 'Не указан вид цены';
							|en = 'Price type is not specified'; fa = 'Price type is not specified';
							|it = 'Il tipo di prezzo non è indicato';
							|pl = 'Nie podano rodzaju ceny';
							|tr = 'Fiyat türü belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText,,"PriceKind","Object");
	EndIf;
	
EndProcedure

&AtClient
Procedure RefillByReceiving(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.DocumentForm.Command.RefillByReceiving");
	
	RefillByNotes();
	ShowUserNotification(NStr("vi = 'Điền lại theo nhập hàng';
								|ru = 'Перезаполнение по приемке';
								|en = 'Refill by receipt'; fa = 'تکمیل مجدد بر اساس دریافت';
								|it = 'Ricompilazione in base all''accettazione';
								|pl = 'Ponowne wypełnienie odbioru';
								|tr = 'Kabul sırasında yeniden doldurma'"),,
		NStr("vi = 'Số lượng điền lại.';
			|ru = 'Количество перезаполнено.';
			|en = 'Quantity is repopulated.'; fa = 'Quantity is repopulated.';
			|it = 'La quantità è ricompilata.';
			|pl = 'Ponowne wypełnienie ilości.';
			|tr = 'Miktar yeniden dolduruldu.'"), PictureLib.Information32);

	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInExpenseItem(Command)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject,
		Items.GoodsExpenseAndIncomeItem,
		Items.Goods.SelectedRows);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	AdditionalParameters = AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfParametersForSplittingRowInTablePart(FormTable.CurrentData);
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
	AccountingForTraceableGoodsClientServerLocalization.SplitRowCompletion(NewRow, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.DocumentForm.Command.SelectGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters",       True);
	FormParameters.Insert("HideTheViewPriceColumn",                  True);
	FormParameters.Insert("HideTheItemPricesCommand",         True);
	FormParameters.Insert("FilterByProductType",                 New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	FormParameters.Insert("Title",                               NStr("vi = 'Chọn hàng hóa';
																		|ru = 'Подбор товаров';
																		|en = 'Pick goods'; fa = 'انتخاب کالاها';
																		|it = 'Selezione delle merci';
																		|pl = 'Wybór towarów';
																		|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date",                                    Object.Date);
	FormParameters.Insert("Document",                                Object.Ref);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);

EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.DocumentForm.Command.ImportDataFromPDT");
	
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
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.Count = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
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
Procedure CheckQuantityInTheDocument(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity());
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("NotUsePackages",               True);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	
	ReturnParameters = Undefined;

	
	OpenForm("CommonForm.CheckDocumentPopulation", OpeningParameters,,,,, New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
    
    ReturnParameters = Result;
    If ReturnParameters <> Undefined Then
        ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
        
        Modified = True;
        
    EndIf;

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
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"Goods",
		"Products,Characteristic,Count");
	
EndProcedure

&AtClient
Procedure AddItemsFromDebitDocuments(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.OtherGoodsRecordingAsReceived.DocumentForm.Command.AddItemsFromDebitDocuments");
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization",             Object.Organization);
	FilterStructure1.Insert("Department",           Object.Department);
	FilterStructure1.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	OpenForm("Document.OtherGoodsRecordingAsReceived.Form.WriteOffDocumentsSelectionForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure SelectTheTmtsvexploitation(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("CurrentRegistrar", Object.Ref);
	
	InventoryInOperationClient.SelectTheTmtsvexploitation(FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
	
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

&AtServer
Procedure Attachable_ExecuteOverriddenCommandOnServer(AdditionalParameters) Export
	
	FormEvents.ExecuteOverridableCommand(ThisObject, AdditionalParameters);
	
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
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False);
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	ConditionalDesignParameters = ProductsServer.ParametersForSettingConditionalAppearanceOfCCDNumber();
	ConditionalDesignParameters.NameOfFieldForEnteringCCDNumber = "GoodsOriginCountry";
	
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject);
	ProductsServer.SetConditionalAppearanceOfCCDNumber(ThisObject, ConditionalDesignParameters);
	
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfCCDNumber(ThisObject);
	AccountingForTraceableGoodsLocalization.SetConditionalAppearanceOfQuantityAccordingToRNPT(ThisObject);
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(ThisObject);
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(ThisObject);
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsExpenseAs.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets;
	
	Item.Appearance.SetParameterValue("Visible", False);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<mallar için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OperationService;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCCDNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsOriginCountry.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với hàng hóa>';
													|ru = '<для товаров>';
													|en = '<for goods>'; fa = '<for goods>';
													|it = '<per le merci>';
													|pl = '<dla towarów>';
													|tr = '<mallar için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#Region Division_MarkBlank
	OperationArray = New ValueList;
	OperationArray.LoadValues(Documents.OtherGoodsRecordingAsReceived.OperationsWhereYouDonTNeedToFillOutDivision());
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = OperationArray;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);
	#EndRegion
	
	// Conditional appearance of quality control Attributes.
	Fields = QualityControl.Fields(
		Items.GoodsToControlQuality,
		Items.GoodsQualityConfirmationDate);
	QualityControl.SetupAppearance(ConditionalAppearance, Fields);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure OnReadCreateAtServer()
	
	FillOperationSelectionList();
	
	DocumentCurrency = Object.Currency;
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Object.Date);
	
	RestrictGoodsReceiptWithoutCCDNumbers = GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers");
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OtherGoodsRecordingAsReceived));
	ProductsServer.FillInAttributeForUsingCharacteristics(Object.Goods);
	
	SetVisibilityOfSeriesElements();
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	SetVisibility1();
	FillInServiceDetailsOfTablePart();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods")
		And Object.BusinessOperation <> Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject, Object.Ref.IsEmpty());
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	ConfigureNavigationBar();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChangeCompletion(QuestionResult, ClearGoods) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Object.BusinessOperation = BusinessTransactionBeforeTheChange;
		Return;
	EndIf;
	
	BusinessOperationOnChangeServer(ClearGoods);
	BusinessTransactionBeforeTheChange = Object.BusinessOperation;
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer(ClearGoods)
	
	If ClearGoods Then
		Object.Goods.Clear();
	EndIf;
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	FillInStatusesForSpecifyingSeriesServer(True);
	SetVisibilityOfSeriesElements();
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.OtherGoodsRecordingAsReceived.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// Setting up accounting accounts.
	SetupParameters = Documents.OtherGoodsRecordingAsReceived.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods")
		And Object.BusinessOperation <> Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	SetVisibility1();
	RecalculateNumberOfRNPT();
	
	ConfigureNavigationBar();
	
	BusinessOperationWithAppointments = Enums.BusinessTransactions.ReceiptFromProduction;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer(DirectModificationOfWarehouseField = False)
	
	Object.PriceKind = Catalogs.Warehouses.AccountingPriceType(Object.Warehouse);
	Object.Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
		Catalogs.TypesOfPrices.GetPriceTypeDetails(Object.PriceKind).PriceCurrency);
	
	If QualityControl.UpdateActionParameters(
			Documents.OtherGoodsRecordingAsReceived,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer(True);
	SetVisibilityOfSeriesElements();
	RecalculateNumberOfRNPT();
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure CurrencyOnChangeClient()
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency) Then
		CurrencyOnChangeServer();
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	OldCurrency                = DocumentCurrency;
	NewCurrency                 = Object.Currency;
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate);
	
	// Recalculate the price
	PriceManagementSystem.ConvertAmountsToCurrencyProducts(
		Object,
		OldCurrency,
		NewCurrency,
		StructureOfOldCurrencyRates,
		StructureOfNewCurrencyRates,
		False);
	
	// Recalculate the amount
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()
	
	CheckToFillInBatchOfGoodsAndMaterialsInOperation();
	
	FillInStatusesForSpecifyingSeriesServer(True);
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	CheckToFillInBatchOfGoodsAndMaterialsInOperation();
	
	FillInStatusesForSpecifyingSeriesServer(True);
	SetVisibilityOfSeriesElements();
	EstablishVisibilityOfRNPTQuantity();
	SetVisibility1();
	
	If Not Items.ProductsGroupQuantityByRNPT.Visible Then
		RecalculateNumberOfRNPT();
	EndIf;
	If QualityControl.UpdateActionParameters(
			Documents.OtherGoodsRecordingAsReceived,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOfReceiptOnChangeServer()
	
	If QualityControl.UpdateActionParameters(
			Documents.OtherGoodsRecordingAsReceived,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()
	
	LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure WhenAddingLineOfProductsOnServer_(String)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, String, "Object.Goods");
	
EndProcedure

&AtClient
Procedure WhenAddingLineOfProductsOnClient_(String)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, String, "Object.Goods");
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTablePart()
	
	FillParameters = New Structure();
	FillParameters.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	FillParameters.Insert("FillInArticleAttribute",                    New Structure("Products", "SKU"));
	FillParameters.Insert("FillInProductTypeAttribute_",            New Structure("Products", "ItemsType"));
	FillParameters.Insert("FillInCCDTrackingAttribute",           New Structure("Products", "TheRecordsAreKeptByCCD"));	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(FillParameters);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillParameters);
	If Object.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		InventoryInOperationServer.FillInServiceDetailsForBatchOfGoodsAndMaterials(Object.Goods);
	EndIf;
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActionsWithAddedStrings.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActionsWithAddedStrings);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;

EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	For Each String In Object.Goods Do
		WhenAddingLineOfProductsOnServer_(String);
	EndDo;
	
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);

EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object,
		SeriesSpecificationParameters, IDCurrentRow, CachedValues);
EndProcedure

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
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text,CurrentData)Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisForm,
					,
					,
					,
					New CallbackDescription("OpenSelectionOfSeriesCompletion",
											ThisObject,
											New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)),
					FormWindowOpeningMode.LockOwnerWindow);
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
Procedure FillInStatusesForSpecifyingSeriesServer(UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.OtherGoodsRecordingAsReceived));
	EndIf; 
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible         = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	
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
		AddActionsToStructureWhenChangingPackagesNumber(ProcessingActions, ThisObject);
	Else
		AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
			Object,
			ProcessingActions);
	EndIf;
	
	PurchasesServer.ProcessIndicationOfCCDNumber(ThisObject,
												RowID,
												SelectionData_1,
												CCDNumbersFilledIn,
												Undefined,
												ProcessingActions);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()
	
	ChoiceList = Items.BusinessOperation.ChoiceList;
	ChoiceList.LoadValues(Documents.OtherGoodsRecordingAsReceived.BusinessOperationsOfDocument(Object));
	
	If GetFunctionalOption("UseProduction")
		And Object.BusinessOperation <> Enums.BusinessTransactions.ReceiptFromProduction Then
		
		ListItem = ChoiceList.FindByValue(Enums.BusinessTransactions.ReceiptFromProduction);
		If ListItem <> Undefined Then
			ChoiceList.Delete(ListItem);
		EndIf;
	EndIf;
	
	If ChoiceList.Count() = 1 Then
		Items.BusinessOperation.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure RefillByNotes()
	
	InvoicesServer.ReFillQuantityByOrders(
		Object.Goods, 
		Object.Ref, 
		Object.Ref, 
		Object.Warehouse,
		Object.BusinessOperation <> Enums.BusinessTransactions.PutOutOfOperation);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert(
		"RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInServiceDetailsOfTablePart();
	For Each String In Object.Goods Do
		WhenAddingLineOfProductsOnServer_(String);
	EndDo;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Var ArrayOfAllElements;
	Var ArrayOfOperationElements;
	
	Documents.OtherGoodsRecordingAsReceived.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	Documents.OtherGoodsRecordingAsReceived.FillInNamesOfElementsForBusinessOperation(
		Object.BusinessOperation,
		ArrayOfAllElements,
		ArrayOfOperationElements);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ArrayOfAllElements,
		"Visible",
		False);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ArrayOfOperationElements,
		"Visible",
		True);
	
	Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);
	Items.GoodsPurpose.Visible = False;
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction
		Or Object.BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		Items.GoodsPurpose.Visible = True;
	EndIf;
	
	EstablishVisibilityOfRNPTQuantity();
	
	AdvancedWarehousingOnReceiving = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date);
	Items.GoodsRefillByReceiving.Visible = AdvancedWarehousingOnReceiving
		And ArrayOfOperationElements.Find("GoodsRefillByReceiving") <> Undefined;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(StructureOfActions, Form, Object, CurrentRow)
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", Form.FormName, "Goods"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCountryOfOriginOfProduct",
								BatchProcessingOfTablePartClientServer.CountryOfOriginFillingParameters());
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, Form.SeriesSpecificationParameters));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", Form.CacheQualityControl);
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	
	StructureOfActions.Insert("CheckFillAssignment");

	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(Form, StructureOfActions);
	
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		Form,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department,
		"Object.Goods""
		|""ExpenseAndIncomeItem");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenCharacteristicChanges(StructureOfActions, Form, Object)
	
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("CheckFillAssignment");
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable", 
		New Structure("FormName, TabularSectionName", Form.FormName, "Goods"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions);
EndProcedure
 
&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	If TableOfGoods = Undefined Then
		Return;
	EndIf;
	CachedValues = Undefined;
	ThisIsSelectionBasedOnWriteOffDocuments = (TableOfGoods.Columns.Find("ExpenseAs") <> Undefined);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInSalePrice",
		New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department,
		"Object.Goods",
		"ExpenseAndIncomeItem");
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	If Not ThisIsSelectionBasedOnWriteOffDocuments Then
		LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	EndIf;
		
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	RowsToProcess = New Array();
	
	For Each TSRow In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		If ThisIsSelectionBasedOnWriteOffDocuments Then
			FillPropertyValues(CurrentRow, TSRow,
				"Products, Characteristic, Purpose, Package, DimensionOfExpenses, ExpenseAs, NumberOfPackages");
			CurrentRow.ExpenseAndIncomeItem = TSRow.ExpenseItem;
		Else
			FillPropertyValues(CurrentRow, TSRow, "Products, Characteristic, Package, Price, NumberOfPackages");
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
			
	For Each TSRow In TableOfGoods Do
		WhenAddingLineOfProductsOnServer_(CurrentRow);
		Modified = True;
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtServer
Function FillInPricesByPriceKindServer()
	
	PricesCalculated = False;
	
	If Object.Goods.Count() = 0 Then
		Return PricesCalculated;
	EndIf;
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		Object.Goods,
		, // Array of rows or selection structure
		New Structure( // The fill parameters
			"Date, Currency, PriceKind, Organization",
			Object.Date,
			Object.Currency,
			Object.PriceKind,
			Object.Organization),
		New Structure( // The structure of the action with the changed strings
			"RecalculateAmount",
			"NumberOfPackages"));
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity()
	
	TabularPartProducts = Object.Goods.Unload(,"Products, Characteristic, ItemVariantsAreUsed, Package, NumberOfPackages, Series, BatchesIndicationStatus, ItemsType");
	TabularPartProducts.GroupBy("Products, Characteristic, ItemVariantsAreUsed, Package, Series, BatchesIndicationStatus, ItemsType", "NumberOfPackages");
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete = New Array;
	ProcessedRowsFound = New Array;
	ProcessedLinesAreNew = New Array;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		For Each TSRow In FoundRows Do
			
			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.NumberOfPackages = 0 Then
				LinesToDelete.Add(TSRow);
			Else
				
				ProcessedRowsFound.Add(TSRow);
				
			EndIf;
			
		EndDo;
		If FoundRows.Count() = 0 Then
			
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			TSRow.Count = SourceRow.NumberOfPackages;
			
			WhenAddingLineOfProductsOnServer_(TSRow);
			
			ProcessedLinesAreNew.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsFound,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAreNew,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure;
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(ActionStructureModifiedStrings);
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		ActionStructureModifiedStrings);
	
	StructureOfActionsAddedLines = Common.CopyRecursive(ActionStructureModifiedStrings);
	StructureOfActionsAddedLines.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActionsAddedLines.Insert("FillInCheckQualityDateOfQualityConfirmation",
		CacheQualityControl);
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisForm, StructureOfActionsAddedLines);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	FillInServiceDetailsOfTablePart();
	
	For Each String In Object.Goods Do
		WhenAddingLineOfProductsOnServer_(String);
	EndDo;
	
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
EndProcedure

&AtClient
Procedure NotifyAboutDocument(WriteParameters)
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("WriteMode", WriteParameters.WriteMode);
	NotificationParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	
	Notify("Write_OtherGoodsRecordingAsReceived", NotificationParameters, Object.Ref);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CheckToFillInBatchOfGoodsAndMaterialsInOperation();
	RecalculateNumberOfRNPT();
	ExcisableGoodsAccounting.UpdateElementsOfAccountingForExcisableItems(ThisObject);
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfRNPTQuantity()
	
	ExcludedTransactions = New Array;
	ExcludedTransactions.Add(Enums.BusinessTransactions.EmptyRef());
	ExcludedTransactions.Add(Enums.BusinessTransactions.InventoryConsumptionReverseTransaction);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(ThisForm, Object.Date);
	
	Items.ProductsGroupQuantityByRNPT.Visible = Items.ProductsGroupQuantityByRNPT.Visible
														And ExcludedTransactions.Find(Object.BusinessOperation) = Undefined;
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfRNPT()
	
	ExcludedTransactions = New Array;
	ExcludedTransactions.Add(Enums.BusinessTransactions.EmptyRef());
	ExcludedTransactions.Add(Enums.BusinessTransactions.InventoryConsumptionReverseTransaction);
	
	If ValueIsFilled(Object.Warehouse)
		And ValueIsFilled(Object.Organization)
		And ExcludedTransactions.Find(Object.BusinessOperation) = Undefined Then
		
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												Object);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Object.Goods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureNavigationBar()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseMaterialsInOperation",
		Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation
		Or Object.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation);
	
	TMCommonUse.ConfigureFormByParameters(ThisObject, SettingsStructure);
	
EndProcedure
&AtServer
Procedure CalculateNumberOfExcisableItemsDeferred()
	
	DataForCalculatingNumberOfExcisableGoods =
		ExcisableGoodsAccounting.StartCalculatingNumberOfExcisableItems(Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateFieldHeaderIsSubjectToExciseDuty()
	
	ExcisableGoodsAccountingClient.AfterCalculatingNumberOfExcisableItems(ThisObject);
	
EndProcedure
#EndRegion

#Region InventoryInOperation

&AtServer
Procedure CheckToFillInBatchOfGoodsAndMaterialsInOperation()
	
	StructureOfActions = New Structure;
	AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionToFillInBatchOfInventoryItemsInOperation(StructureOfActions, Object)

	If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.PutOutOfOperation") Then
		Return;
	EndIf;
	
	ChoiceParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	ChoiceParameters.Date = Object.Date;
	ChoiceParameters.Organization = Object.Organization;
	ChoiceParameters.Department = Object.Department;
	ChoiceParameters.CurrentRegistrar = Object.Ref;
	
	StructureOfActions.Insert("FillInBatchOfTMTSV", ChoiceParameters);
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionSelectionOfGoodsInOperation(Val ArrayOfSelected)
	
	Modified = True;
	
	AddedRows = New Array;
	For Each ArrayElement In ArrayOfSelected Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, ArrayElement);
		AddedRows.Add(NewRow);
	EndDo;
	
	If AddedRows.Count() = 0 Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInCCDTrackingAttribute", New Structure("Products", "TheRecordsAreKeptByCCD"));
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind",
		Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department,
		"Object.Goods""
		|""ExpenseAndIncomeItem");
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(StructureOfActions);
	
	For Each NewRow In AddedRows Do
		WhenAddingLineOfProductsOnServer_(NewRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods);
	
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,Price,CCDNumber,Individual";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	StructureOfActions.Insert("FillInSalePrice", New Structure("Date, Currency, PriceKind", Object.Date, Object.Currency, Object.PriceKind));
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		ThisObject,
		Object.BusinessOperation,
		Object.Organization,
		Object.Department,
		"Object.Goods""
		|""ExpenseAndIncomeItem");
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	AccountingForTraceableGoodsClientServerLocalization.CompleteDescriptionOfSettingsForFillingInServiceDetailsOfTablePart(
		StructureOfActions);
	
	LinesOfBusinessClientServer.StructureOfInsertActionsWhenAddingRow(ThisObject, StructureOfActions);
	RowsToProcess = New Array;
	
	For Each TSRow In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, TSRow);
		WhenAddingLineOfProductsOnServer_(CurrentRow);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsOfTablePart();
	FillInStatusesForSpecifyingSeriesServer();
	PurchasesServer.FillInServiceAttributesOfCCDNumber(Object.Goods);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = UseExcisableGoods;
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

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfReceipt" Then
		DateOfReceiptOnChange(Items.DateOfReceipt);
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
