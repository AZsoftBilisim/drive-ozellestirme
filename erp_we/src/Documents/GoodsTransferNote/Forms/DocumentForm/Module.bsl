#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurrentStatus; //client cache of the document status (needed to be able to roll back the status change by the user)

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm, "ShippedGoods");
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	Else	
		Items.GroupPages.CurrentPage = Items.GroupOfShippedGoods;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure // Joining the Server()

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	CurrentStatus = Object.Status;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	FillInServiceDetailsForProductRange();	

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_GoodsTransferNote", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SenderWareroomOnChange(Item)
	SenderWareroomOnChangeServer();
EndProcedure

&AtClient
Procedure ReceivingWareroomOnChange(Item)
	ReceivingWareroomOnChangeServer();	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	ClearMessages();
	
	If BinLocationWarehousingSender Then 
		
		If CurrentStatus = PredefinedValue("Enum.TransferNoteStatuses.ForPicking")
			And Object.Status <> PredefinedValue("Enum.TransferNoteStatuses.ForPicking") Then
			
			If Modified
				Or Not Object.Posted Then
				NewStatus   = Object.Status;
				Object.Status = CurrentStatus;
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("NewStatus", NewStatus);
				
				QueryText = NStr("vi = 'Trước khi thay đổi trạng thái, chứng từ sẽ được kết chuyển. Tiếp tục?';
								|ru = 'Перед изменением статуса документ будет проведен. Продолжить?';
								|en = 'Document will be posted before changing the status. Continue?'; fa = 'Document will be posted before changing the status. Continue?';
								|it = 'Prima di modificare lo stato il documento verrà registrato. Continuare?';
								|pl = 'Przed zmianą statusu dokumentu zostanie zaksięgowany. Kontynuować?';
								|tr = 'Belge, durum değişikliğinden önce kaydedilecektir. Devam edilsin mi?'");
				CallbackDescription = New CallbackDescription("QuestionWhenChangingStatusEnds", ThisForm, AdditionalParameters);
				
				ShowQueryBox(CallbackDescription,
								QueryText,
								QuestionDialogMode.OKCancel,
								,
								DialogReturnCode.Cancel);
				Return;
			EndIf;
			
			ChangeStatusAtAddressWarehouse();
		Else
			StatusOnChangeServer(False, Undefined);
		EndIf;
	Else
		StatusOnChangeServer(False, Undefined);
	EndIf;
	
	CurrentStatus = Object.Status;

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseWhenChangedOnServer()
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOfShipmentOnChangeServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShippedGoods

&AtClient
Procedure ShippedGoodsProductsOnChange(Item)
	Var CurrentRow;
	Var Actions;

	CurrentRow = Items.ShippedGoods.CurrentData;

	Actions = New Structure;
	Actions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	Actions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("CheckFillAssignment");
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	Actions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "ShippedGoods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
EndProcedure

&AtClient
Procedure ShippedGoodsPackageOnChange(Item)
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	Actions = New Structure();
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateNumberOfPackages");
	Actions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,	Actions, CachedValues);
EndProcedure

&AtClient
Procedure ShippedGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	Actions = New Structure();
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,	Actions, CachedValues);
EndProcedure

&AtClient
Procedure ShippedGoodsActionOnChange(Item)
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	Actions = New Structure();
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, Actions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,	Actions, CachedValues);
EndProcedure

&AtClient
Procedure ShippedGoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ShippedGoods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ShippedGoods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
EndProcedure

&AtClient
Procedure ShippedGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.ShippedGoodsBatchesIndicationStatus Then
		OpenSelectionOfSeries();
	EndIf;
EndProcedure

&AtClient
Procedure ShippedGoodsOnEditEnd(Item, NewRow, CancelEdit)
	DisplayInformationOnUnloadedProducts();
EndProcedure

&AtClient
Procedure ShippedGoodsOnStartEdit(Item, NewRow, Copy)
	If Not Copy
		And NewRow Then
		CurrentData = Items.ShippedGoods.CurrentData;
		CurrentData.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Pick");
	EndIf;
EndProcedure

&AtClient
Procedure ShippedGoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
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
Procedure VerifyQuantity(Command)
	WarehousesClient.OpenCheckingFormPackagingAndQuantities(ThisForm, "Validation");
EndProcedure

&AtClient
Procedure CorrectQuantity(Command)
	WarehousesClient.OpenCheckingFormPackagingAndQuantities(ThisForm, "Patch");
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInByFilteredGoods(Command)

	If (Modified Or Not Object.Posted) And Object.ShippedGoods.Count() > 0 Then
				
		QueryText = NStr("vi = 'Trước khi điền vào chứng từ sẽ được giữ và phần bảng - đã bị xóa. Tiếp tục?';
						|ru = 'Перед заполнением документ будет проведен, а табличная часть - очищена. Продолжить?';
						|en = 'The table will be refilled. The document will be posted. Do you want to continue?'; fa = 'The table will be refilled. The document will be posted. Do you want to continue?';
						|it = 'Prima della compilazione il documento verrà registrato e la tabella verrà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem dokument zostanie zaksięgowany, część tabelaryczna zostanie oczyszczona. Kontynuować?';
						|tr = 'Doldurmadan önce belge kaydedilecek ve tablo bölümü temizlenecektir. Devam edilsin mi?'");
			CallbackDescription = New CallbackDescription("CompletionOfWorkOnSelectedProducts", ThisForm);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	FillInFollowingSnippetForSelectedProducts();
		
EndProcedure

&AtClient
Procedure CompletionOfWorkOnSelectedProducts(Response, AdditionalParameters) Export
		
	If Response <> DialogReturnCode.Yes Then
		Return;
	Else
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
		
		FillInFragmentForSelectedProducts();
		
	EndIf;
	    
EndProcedure

&AtClient
Procedure FillInFollowingSnippetForSelectedProducts()
    
    If Object.ShippedGoods.Count() > 0 Then

		QueryText = NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Điền?';
						|ru = 'Перед заполнением табличная часть будет очищена. Заполнить?';
						|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
						|it = 'Prima della compilazione, la tabella sarà cancellata. Compilare?';
						|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Wypełnić?';
						|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Doldur?'");
		
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillInByFilteredGoodsCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
        Return;

	EndIf;

	FillInFragmentForSelectedProducts();

EndProcedure

&AtClient
Procedure FillInByFilteredGoodsCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
       
    FillInFragmentForSelectedProducts();

EndProcedure

&AtClient
Procedure FillInFragmentForSelectedProducts()
    
    FillInByFilteredGoodsServer(False, Undefined);
    DisplayInformationOnUnloadedProducts();
	
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
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	
	If ThereAreFilledSeriesByFEFO() Then
		
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(
			New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisObject));
		Return;
		
	EndIf;
	
	FillInSeriesByFEFOServer();
	
EndProcedure

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	FillInSeriesByFEFOServer();
	
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
Procedure SplitRow(Command)
	
	FormTable  = Items.ShippedGoods;
	TableData = Object.ShippedGoods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	If NewRow <> Undefined Then
		
		Actions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(ThisObject, Actions);		
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, Actions, CachedValues);
		
	EndIf;
	
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
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivingArea.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceivingArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddressableStorageRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TransferNoteStatuses.Accepted;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReceivingArea.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TransferNoteStatuses.Accepted;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReceivingArea");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	WarehousesServer.SetConditionalAppearanceForActionInLine(ThisObject);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm,
																			"ShippedGoodsCharacteristic",
																			"Object.ShippedGoods.ItemVariantsAreUsed");
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																			"ShippedGoodsPurpose",
																			"Object.ShippedGoods.ItemsType");
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm,
																	"SeriesAlwaysWHGoods",
																	"ShippedGoodsSeries",
																	"Object.ShippedGoods.BatchesIndicationStatus",
																	"Object.ShippedGoods.ItemsType");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsBatchesIndicationStatus.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ShippedGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ShippedGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsPackage.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup1 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	FilterGroup1 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BinLocationWarehousingSender");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddressableStorageRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsPackage.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup1 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;
	
	FilterGroup1 = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
	
	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BinLocationWarehousingSender");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ActionsWithGoodsIssueNoteRows.Pick;
	
	FilterGroup3 = FilterGroup2.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup3.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AddressableStorageRecipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup3.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TransferNoteStatuses.Accepted;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SenderWareroomOnChangeServer();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsTransferNote));
	
	ParametersStructure = New Structure("Warehouse,Premise",Object.Warehouse, Object.ReceivingWareroom);
	
	AddressableStorageRecipient = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.ReceivingWareroom,Object.DateOfShipment);
	
	Items.ReceivingArea.Visible = AddressableStorageRecipient;
	
	If AddressableStorageRecipient Then
		Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(
			Object.Warehouse, Object.ReceivingWareroom, Object.ReceivingArea);
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsTransferNote));
	
	Items.ShippedGoodsSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	FillInServiceDetailsForProductRange();	
	
	Items.InformationGroup.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	SetAvailability();
	
	DisplayInformationOnUnloadedProducts();

EndProcedure

#Region OnChangeAttributes

&AtClient
Procedure ChangeStatusAtAddressWarehouse()
	NewStatus   = Object.Status;
	Object.Status = CurrentStatus;
	StatusOnChangeServer(True,NewStatus);
EndProcedure

&AtClient
Procedure QuestionWhenChangingStatusEnds(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.OK Then
		Return;
	Else
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	
	Modified = True;
	
	Object.Status = AdditionalParameters.NewStatus;
	
	ChangeStatusAtAddressWarehouse();
	
	CurrentStatus = Object.Status;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer(FillInForSelectedProducts, NewStatus)
	
	If FillInForSelectedProducts 
		And WarehousesServer.CheckOrdersForStatusChanges(Object.Ref).Count() = 0 Then
		Object.Status = Common.ObjectAttributeValue(Object.Ref, "Status");
		Return;
	EndIf;
	
	If FillInForSelectedProducts Then
		FillInByFilteredGoodsServer(True, NewStatus);
	Else
		Documents.GoodsTransferNote.FillInActionInLines(Object);
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsTransferNote));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	EndIf;
	
	If Object.Status = Enums.TransferNoteStatuses.Accepted Then
		Object.DateOfShipment = CurrentSessionDate();
	EndIf;
	
	SetAvailability();
	DisplayInformationOnUnloadedProducts();

EndProcedure

&AtServer
Procedure SenderWareroomOnChangeServer()
	
	BinLocationWarehousingSender = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.SenderWareroom,Object.DateOfShipment);
	
	Items.ShippingZone.Visible = BinLocationWarehousingSender;
	
	If BinLocationWarehousingSender Then
		Object.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(
			Object.Warehouse, Object.SenderWareroom, Object.ShippingZone);
	EndIf;
	SetAvailabilityForSelectedProducts();
	
EndProcedure

&AtServer
Procedure ReceivingWareroomOnChangeServer()
	
	AddressableStorageRecipient = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.ReceivingWareroom,Object.DateOfShipment);
	
	Items.ReceivingArea.Visible = AddressableStorageRecipient;
	
	If AddressableStorageRecipient Then
		Object.ReceivingArea = Catalogs.StorageBins.DefaultAcceptanceZone(
			Object.Warehouse, Object.ReceivingWareroom, Object.ReceivingArea);
	EndIf;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsTransferNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure FillInByFilteredGoodsServer(StatusChange, NewStatus)

	FillParameters = WarehousesServer.ParametersForFillingOrdersWithSelectedGoods();
	FillParameters.FillMode   = "Singular_";	
	FillParameters.StatusChange  = StatusChange;	
	FillParameters.DocumentObject    = Object;	
	If ValueIsFilled(NewStatus) Then
		FillParameters.DocumentStatus   = Common.EnumerationValueName(NewStatus);
	EndIf;
	
	WarehousesServer.FillOrders_WithSelectedProducts(FillParameters, Modified);	

	FillInServiceDetailsForProductRange();	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsTransferNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);	
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsTransferNote));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	Items.ShippedGoodsSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
	SetAvailabilityForSelectedProducts();
	
EndProcedure

&AtServer
Procedure DateOfShipmentOnChangeServer()
	
	SenderWareroomOnChangeServer();
	ReceivingWareroomOnChangeServer();
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ActionsWithAddedLines = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, ActionsWithAddedLines);
	ActionsWithAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionsWithAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionsWithAddedLines.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ActionsWithAddedLines.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ActionsWithAddedLines.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ActionsWithAddedLines.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ActionsWithAddedLines.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, ActionsWithModifiedStrings);

	Actions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	Actions.Barcodes                              = BarcodeData_5;
	Actions.StructureOfActionsWithAddedStrings = ActionsWithAddedLines;
	Actions.StructureOfActionsWithModifiedStrings  = ActionsWithModifiedStrings;
	Actions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	Actions.GoodsOnly                           = True;
	Actions.TSName                                  = "ShippedGoods";
	
	ProcessBarcodesServer(Actions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(Actions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(Actions) Then
		CurDataId = Actions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	If Actions.CurrentRow <> Undefined Then
		Items.ShippedGoods.CurrentRow = Actions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ShippedGoods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, CachedValues)
	
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters",
																				Object.Warehouse, SeriesSpecificationParameters));
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");

	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,Actions, CachedValues);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters, Text, CurrentData) Then		
		If CurrentData = Undefined Then
			CurDataId = Items.ShippedGoods.CurrentData.GetID();
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
					New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm))
					,
					FormWindowOpeningMode.LockWholeInterface);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, CachedValues);
    EndIf;

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ParametersForFillingInBankingDetails.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ParametersForFillingInBankingDetails.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ParametersForFillingInBankingDetails.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ParametersForFillingInBankingDetails.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ShippedGoods,ParametersForFillingInBankingDetails);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ShippedGoods, StructureOfActions);

EndProcedure

&AtServer
Procedure FillInSeriesByFEFOServer()
	ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters);	
EndProcedure

&AtServer
Function ThereAreFilledSeriesByFEFO()
	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.ShippedGoods);
EndFunction

&AtServer
Procedure SetAvailability()
	
	Items.ShippedGoodsFillInSeriesByFEFO.Enabled = SeriesSpecificationParameters.ShipmentPlanning
		Or SeriesSpecificationParameters.SelectionPlanning;
	Items.CorrectQuantity.Visible = (Object.Status = PredefinedValue("Enum.TransferNoteStatuses.ToShip"));
	Items.VerifyQuantity.Visible = (Object.Status = PredefinedValue("Enum.TransferNoteStatuses.ForChecking"));
	SetAvailabilityForSelectedProducts();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(Form, Actions)
	
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Form.Object.Warehouse, Form.SeriesSpecificationParameters));
		
	
EndProcedure

&AtServer
Procedure DisplayInformationOnUnloadedProducts()
	
	QuantityNotToShip =
		Object.ShippedGoods.FindRows(New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip)).Count();
	
	If QuantityNotToShip > 0 Then
		
		Items.Decoration2.Visible = False;
		Items.PictureInformation.Visible = True;
		Items.TextLeave.Visible = True;
		
		LabelText = NStr("vi = 'Trong khu vực giao hàng cần đặt %NumberOfRows% hàng hóa.';
						|ru = 'В зоне отгрузки необходимо оставить %NumberOfRows% товаров.';
						|en = '%NumberOfRows% of goods should be left in the outbound area.'; fa = '%NumberOfRows% of goods should be left in the outbound area.';
						|it = 'Nella area di spedizione, è necessario lasciare %NumberOfRows% prodotti.';
						|pl = 'W strefie wysyłki należy zostawić %NumberOfRows% towarów.';
						|tr = 'Ürünler yükleme alanında %NumberOfRows% bırakılmalıdır.'");
		NumberOfRows = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(QuantityNotToShip,
																								NStr("vi = 'vị trí,vị trí,vị trí';
																									|ru = 'позицию,позиции,позиций';
																									|en = 'position,positions,positions'; fa = 'position,positions,positions';
																									|it = 'posizione, posizioni, posizioni';
																									|pl = 'pozycję,pozycji,pozycji  ';
																									|tr = 'pozisyonu, pozisyonlar, pozisyonun'"));
		
		LabelText = StrReplace(LabelText,  "%NumberOfRows%", NumberOfRows);
		TextLeave = LabelText;
		
	Else
		
		Items.Decoration2.Visible = True;
		Items.PictureInformation.Visible = False;
		Items.TextLeave.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityForSelectedProducts()
	Items.ShippedGoodsFillInByFilteredGoods.Enabled = BinLocationWarehousingSender;
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
Procedure ShippedGoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure ShippedGoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

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
	If Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
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
