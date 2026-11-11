#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

&AtClient
Var RecordingIsInProgress; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	Items.GoodsSearchByBarcode.Visible = AccessRight("Read", Metadata.InformationRegisters.ItemsBarcodes);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
		And Not Object.AccountingDataIsFilledIn 
		And Object.Goods.Count() > 0
		And Not Cancel
		And Not RecordingIsInProgress Then
		
		QueryText = NStr("vi = 'Khi kết chuyển sẽ điền lại số lượng theo kế toán tại tất cả các dòng của phần bảng. Tiếp tục?';
						|ru = 'При проведении будет перезаполнено учетное количество во всех строках табличной части. Продолжить?';
						|en = 'Accounting quantity will be refilled in all rows of the table while posting. Continue?'; fa = 'Accounting quantity will be refilled in all rows of the table while posting. Continue?';
						|it = 'Durante la registrazione la quantità registrata in contabilità verrà ricompilata in tutte le righe della parte tabulare. Continuare?';
						|pl = 'Podczas księgowania ilościowy numer rozliczeniowy zostanie uzupełniony we wszystkich wierszach tabeli. Kontynuować?';
						|tr = 'Kaydedilirken, tablo bölümünün tüm satırlarında muhasebe miktarı yeniden doldurulacaktır. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("BeforeWriteCompletion", ThisObject), 
			QueryText,
			QuestionDialogMode.OKCancel,
			,
			DialogReturnCode.OK);
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWriteCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	RecordingIsInProgress = True;
	Write(New Structure("WriteMode", DocumentWriteMode.Posting));
	RecordingIsInProgress = False;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.RecountFilter = New ValueStorage(RecountFilter.Settings, New Deflation(9));
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
		
	FillInServiceDetailsForProductRange();
	FillIn_DiscrepancyFlag();
	SetStateOfEditingByStatus();
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, SelectionResult);
		If Not Items.Goods.CurrentData.SurplusDamage Then
			Object.AccountingDataIsFilledIn = False;
		EndIf;
	ElsIf ChoiceSource.FormName = "Catalog.Assignments.Form.ChoiceForm" Then	
		Items.Goods.CurrentData.Purpose = SelectionResult;	
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_InventoryRecount", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure FormPagesOnCurrentPageChange(Item, CurrentPage)
	// StandardSubsystems.Properties
	
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
			
			PropertiesExecuteDeferredInitialization();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges(True);
	Object.AccountingDataIsFilledIn = False;
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges();
	Object.AccountingDataIsFilledIn = False;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.AccountingDataIsFilledIn = False;
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If UseBinLocationWarehousing
		And Object.Posted Then
		
		If Object.Status = PredefinedValue("Enum.InventoryRecountStatuses.EnteringResults") Then
			If Object.LockStorageBins Then
				
				MessageText = NStr("vi = 'Mở khóa ô hàng?';
									|ru = 'Снять блокировку ячеек?';
									|en = 'Remove cell lock?'; fa = 'Remove cell lock?';
									|it = 'Rimuovere il blocco delle celle?';
									|pl = 'Odblokować komórki?';
									|tr = 'Hücrelerin kilidi kaldır?'");
				
				Response = Undefined;

				
				ShowQueryBox(New CallbackDescription("StatusOnChangeCompletion", ThisObject), MessageText, QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
                Return;
			EndIf;
		EndIf;
	EndIf;
	
	StatusChangedOnServer();
EndProcedure

&AtClient
Procedure StatusOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.Yes Then
        Object.LockStorageBins = False;
        Write(New Structure("WriteMode",DocumentWriteMode.Posting));
        Return;
    EndIf;
    
    StatusChangedOnServer();

EndProcedure

&AtClient
Procedure UseTheSurplusCellOnChange(Item)
	
	Items.StorageBinForSurplusesConsolidation.Enabled = Object.MoveGoodsSurplusesIntoBin;
	
	If Not(Object.MoveGoodsSurplusesIntoBin) Then
		Object.StorageBinForSurplusesConsolidation = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseTheDamageCellOnChange(Item)
	
	Items.StorageBinForSpoiledGoodsConsolidation.Enabled = Object.MoveSpoiledGoodsIntoBin;
	
	If Not(Object.MoveSpoiledGoodsIntoBin) Then
		Object.StorageBinForSpoiledGoodsConsolidation = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	EmployeeResponsibleOnChangeServer();
	
EndProcedure

&AtClient
Procedure OnlyDiscrepanciesOnChange(Item)
	
	If OnlyDiscrepancies Then
		Items.Goods.RowFilter = New FixedStructure("Discrepancy",True);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsCellOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not CurrentData.SurplusDamage Then
		Object.AccountingDataIsFilledIn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		Items.Goods.CurrentData.Count = 0;
		Items.Goods.CurrentData.CountReal = 0;
		Items.Goods.CurrentData.NumberOfPackages = 0;
		Items.Goods.CurrentData.NumberOfPackagesReal = 0;
		Items.Goods.CurrentData.NumberOfPackagesDiscrepancy = 0;
		
		If Not Copy
			And Object.Posted Then
			Items.Goods.CurrentData.Cell = Object.StorageBinForSurplusesConsolidation;
		EndIf;
		
		If EditState = "LimitedEditing" Then
			Items.Goods.CurrentData.SurplusDamage = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Real");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActions.Insert("CheckFillAssignment");
	StructureOfActions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not ValueIsFilled(CurrentRow.Products) Then
		CurrentRow.CountReal 		 = 0;
		CurrentRow.NumberOfPackagesReal = 0;
		CurrentRow.Count 			 = 0;
		CurrentRow.NumberOfPackages	 = 0;
		CurrentRow.NumberOfPackagesDiscrepancy = 0;
	EndIf;
	
	If EditState = "LimitedEditing"
		And ValueIsFilled(CurrentRow.Products) Then
		
		CurrentRow.SurplusDamage = True;
		
	EndIf;
	
	If Not CurrentRow.SurplusDamage Then
		Object.AccountingDataIsFilledIn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsControlledLotReferenceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not CurrentData.SurplusDamage Then
		Object.AccountingDataIsFilledIn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPurposeOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	If Not CurrentData.SurplusDamage Then
		Object.AccountingDataIsFilledIn = False;
	EndIf;

EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.Goods.CurrentData = Undefined Then
		Return;
	EndIf;
		
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Real");
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.SurplusDamage Then
		Object.AccountingDataIsFilledIn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesRealOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingNumberOfPackagesReal(StructureOfActions);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);			
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ClearMessages();
	
	If EditState = "NotIsBeingEdited" Then
		
		Cancel = True;
		
	ElsIf EditState = "LimitedEditing" Then
		
		Cancel = True;
		
		SelectedRows = Items.Goods.SelectedRows;
		
		For Each Id In SelectedRows Do
			
			RowOfTables = Items.Goods.RowData(Id);
			
			If RowOfTables.SurplusDamage Then
				Object.Goods.Delete(RowOfTables);
			Else
				MessageText = NStr("vi = 'Không thể xóa bỏ dòng %LineNumber% vì dòng này đã thêm vào trước khi bắt đầu kiểm đếm.';
									|ru = 'Строку %LineNumber% удалить нельзя, т.к. она была добавлена до начала пересчета.';
									|en = 'Cannot delete line %LineNumber%, as it was added before recalculation start.'; fa = 'Cannot delete line %LineNumber%, as it was added before recalculation start.';
									|it = 'Non è possibile eliminare la riga %LineNumber% perché è stata aggiunta prima dell''inizio di ricalcolo.';
									|pl = 'Nie można usunąć wiersza %LineNumber% ponieważ został on dodany przed rozpoczęciem ponownego obliczania.';
									|tr = '%LineNumber%satırı silinmemeli, çünkü yeniden hesaplama başlamadan önce eklendi.'");
				MessageText = StrReplace(MessageText,"%LineNumber%", RowOfTables.LineNumber);
				Field = CommonClientServer.PathToTabularSection("Goods", RowOfTables.LineNumber, "LineNumber");
				CommonClientServer.MessageToUser(MessageText,,Field,"Object",Cancel);
			EndIf;
			
		EndDo;
		
	EndIf;
	
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

	If Not Items.Goods.CurrentData.SurplusDamage Then
		Object.AccountingDataIsFilledIn = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit
		And NewRow Then
		
		CurrentRow = Items.Goods.CurrentData;
		
		If CurrentRow = Undefined Then
			Return;
		EndIf;
		
		If Not CurrentRow.SurplusDamage Then
			Object.AccountingDataIsFilledIn = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	If Not WarehouseSpaceFilled() Then
		Return;
	EndIf;
	
	If Object.Goods.Count() > 0 Then
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillCompletion", ThisObject), NStr("vi = 'Trước khi điền danh sách hàng hóa sẽ bị xóa. Tiếp tục?';
																				|ru = 'Перед заполнением список товаров будет очищен. Продолжить?';
																				|en = 'The Item list will be cleared before population. Continue?'; fa = 'The Item list will be cleared before population. Continue?';
																				|it = 'Prima della compilazione, l''elenco delle merci sarà cancellato. Continuare?';
																				|pl = 'Przed wypełnieniem lista towarów zostanie wyczyszczona. Kontynuować?';
																				|tr = 'Doldurmadan önce ürün listesi temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	FillInFragment();
EndProcedure

&AtClient
Procedure FillCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response = DialogReturnCode.Yes Then
        Object.Goods.Clear();
    Else
        Return;
    EndIf;
    
    FillInFragment();

EndProcedure

&AtClient
Procedure FillInFragment()
    
    FillServer();
    Object.AccountingDataIsFilledIn = False;

EndProcedure

&AtClient
Procedure FillInActualQuantityByRecords(Command)
	
	If NumberOfFieldsFilled() Then
		
		QueryText = NStr("vi = 'Trong phần bảng đã có các dòng với số lượng thực tế đã điền.
			|Khi điền, thông tin này sẽ bị mất. Tiếp tục?';
			|ru = 'В табличной части уже есть строки с заполненным фактическим количеством.
			|При заполнении эта информация будет утеряна. Продолжить?';
			|en = 'Some rows in the table contain actual quantity data.
			|Filling will delete this information. Continue?'; fa = 'Some rows in the table contain actual quantity data.
			|Filling will delete this information. Continue?';
			|it = 'Nella parte tabulare ci sono già delle righe con la quantità effettiva compilata.
			|Durante la compilazione, queste informazioni andranno perse. Continuare?';
			|pl = 'W części tabelarycznej znajdują się już wiersze z faktyczną ilością wypełnioną.
			| Po wypełnieniu te informacje zostaną utracone. Kontynuować?';
			|tr = 'Tablo bölümü, gerçek miktarın girildiği satırları zaten içerir.
			|Bu bilgi, doldurulduğunda kaybolacaktır. Devam edilsin mi?'");
		
		Response = Undefined;

		
		ShowQueryBox(New CallbackDescription("FillInActualQuantityByRecordsCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
        Return;
		
	EndIf;
	
	FillInActualQuantityByRecordsServer();
EndProcedure

&AtClient
Procedure FillInActualQuantityByRecordsCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    FillInActualQuantityByRecordsServer();

EndProcedure

&AtClient
Procedure ChangeQuality(Command)
	
	CurrentData = Items.Goods.CurrentData;
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hãy chọn dòng của phần bảng';
							|ru = 'Выберите строку табличной части';
							|en = 'Select a table row'; fa = 'Select a table row';
							|it = 'Selezionare una riga della parte tabulare';
							|pl = 'Wybierz wiersz części tabelarycznej';
							|tr = 'Tablo bölümündeki satırı seçin'");
		CommonClientServer.MessageToUser(MessageText);
		Return
	EndIf;
	
	If Not(CurrentData.SurplusDamage) And UseInventoryRecountStatuses Then
		MessageText = NStr("vi = 'Không thể thay đổi chất lượng trong dòng đã được bổ sung trước khi bắt đầu kiểm đếm. Hãy sử dụng lệnh ""Chia dòng"".';
							|ru = 'Невозможно изменить качество в строке, добавленной до начала пересчета. Воспользуйтесь командой ""Разбить строку"".';
							|en = 'Cannot change quality in the line added before recalculation started. Use command ""Split line"".'; fa = 'Cannot change quality in the line added before recalculation started. Use command ""Split line"".';
							|it = 'Non è possibile modificare la qualità nella riga aggiunta prima dell''inizio di ricalcolo. Usare il comando ""Dividere la riga"".';
							|pl = 'Nie można zmienić jakości w wierszu dodanym przed rozpoczęciem ponownego obliczania. Użyj polecenia ""Podziel wiersz"".';
							|tr = 'Yeniden hesaplama başlamadan önce eklenen bir satırın kalitesini değiştirmek mümkün değildir. ""Satırı böl"" komutunu kullan.'");
		CommonClientServer.MessageToUser(MessageText,,"Object.Goods["+Format(CurrentData.LineNumber-1,"NG=0")+"].LineNumber",,);
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	If ValueIsFilled(CurrentData.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentData.Characteristic);
	EndIf;
	
	If ValueIsFilled(CurrentData.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentData.Package);
	EndIf;
	
	Notification = New CallbackDescription("ChangeQualityCompletion", ThisObject, New Structure("CurrentData", CurrentData));
	WarehousesClient.ChangeQuality(CurrentData, StructureOfActions, CachedValues, Notification);
	
EndProcedure

&AtClient
Procedure ChangeQualityCompletion(Result, AdditionalParameters) Export
	
	If Object.MoveSpoiledGoodsIntoBin Then
		AdditionalParameters.CurrentData.Cell = Object.StorageBinForSpoiledGoodsConsolidation;
	EndIf;
	
	If ValueIsFilled(AdditionalParameters.CurrentData.Purpose) Then
		QueryText = NStr("vi = 'Xóa cột ""Mục đích"" cho hàng hóa có thay đổi chất lượng?';
						|ru = 'Очистить колонку ""Назначение"" для товара с измененным качеством?';
						|en = 'Clear column ""Assignment"" for the product with changed quality?'; fa = 'Clear column ""Assignment"" for the product with changed quality?';
						|it = 'Cancellare la colonna ""Assegnazione"" per la merce con qualità modificata?';
						|pl = 'Wyczyść kolumnę ""Przeznaczenie"" dla towarów o zmienionej jakości?';
						|tr = 'Kalitesi değiştirilmiş bir ürün için ""Atama"" sütunu silinsin?'");
		CallbackDescription = New CallbackDescription("ChangeQualityClearDestinationCompletion", ThisForm, New Structure("CurrentData", AdditionalParameters.CurrentData));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeQualityClearDestinationCompletion(Result, AdditionalParameters) Export
	
	ClearAssignment = (Result = DialogReturnCode.Yes);
	CurrentData = AdditionalParameters.CurrentData;
	
	If ClearAssignment Then
		CurrentData.Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
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
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = "NumberOfPackagesReal";
	StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng thực tế hàng hóa trong dòng mới';
											|ru = 'Введите фактическое количество товара в новой строке';
											|en = 'Enter actual quantity of goods in a new line'; fa = 'Enter actual quantity of goods in a new line';
											|it = 'Inserire la quantità effettiva di merce nella nuova riga';
											|pl = 'Wprowadź rzeczywistą ilość towarów w nowym wierszu';
											|tr = 'Ürünün gerçek miktarını yeni bir satıra gir'");
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		If ValueIsFilled(Object.StorageBinForSurplusesConsolidation) Then
			NewRow.Cell = Object.StorageBinForSurplusesConsolidation
		EndIf;
		NewRow.SurplusDamage       = True;
		NewRow.Count         = 0;
		NewRow.NumberOfPackages = 0;
		NewRow.NumberOfPackagesDiscrepancy = 0;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingNumberOfPackagesReal(StructureOfActions);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
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
Procedure GetWeight(Command)
	
	ClearMessages();
	
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
		CurrentRow.NumberOfPackagesReal = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		
		If UseBinLocationWarehousing Then
			AddActionsToStructureWhenChangingNumberOfPackagesReal(StructureOfActions);
		Else
			CurrentRow.CountReal = ExecutionResult.Weight;
			
			StructureOfActions.Insert("FillInDiscrepancyFlag");
			StructureOfActions.Insert("RecalculateNumberOfPackagesDeviation");
		EndIf;
		
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
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
Procedure UploadVTSDData(Command)
	
	FormParameters = New Structure("FillingVariant, Recalculate", "ByRecountGoods", Object.Ref);
	OpenForm("DataProcessor.ExportGoodsDatabaseToPDT.Form", FormParameters);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties 
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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
//End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCell.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsLineNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsControlledLotReference.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EditState");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = '%1';
								|ru = '%1';
								|en = '%1'; fa = '%1';
								|it = '%1';
								|pl = '%1';
								|tr = '%1'");
	ItemFilter.RightValue = StrTemplate(ItemFilter.RightValue, "LimitedEditing");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SurplusDamage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesDiscrepancy.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesReal.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.InventoryRecountStatuses.InProgress);
	ValueList.Add(Enums.InventoryRecountStatuses.Prepared2);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<để nhập kết quả>';
													|ru = '<для внесения результата>';
													|en = '<for entering result>'; fa = '<for entering result>';
													|it = '<per inserire il risultato>';
													|pl = '<dla wprowadzenia wyniku>';
													|tr = '<sonucu girmek için>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPurpose.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCell.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesReal.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesDiscrepancy.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsLineNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsControlledLotReference.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EditState");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = '%1';
								|ru = '%1';
								|en = '%1'; fa = '%1';
								|it = '%1';
								|pl = '%1';
								|tr = '%1'");
	ItemFilter.RightValue = StrTemplate(ItemFilter.RightValue, "NotIsBeingEdited");
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.FormBackColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, "SeriesAlwaysWHGoods");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesReal.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<ô trống>';
													|ru = '<пустая ячейка>';
													|en = '<empty bin>'; fa = '<empty bin>';
													|it = '<cella vuota>';
													|pl = '<pusta komórka>';
													|tr = '<boş hücre>'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EditState");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = NStr("vi = '%1';
								|ru = '%1';
								|en = '%1'; fa = '%1';
								|it = '%1';
								|pl = '%1';
								|tr = '%1'");
	ItemFilter.RightValue = StrTemplate(ItemFilter.RightValue, "EditingWithoutStatuses");
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm);

	// Quality control.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.SubjectToUnlocking");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ControlledLotReference");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.GoodsNumberOfPackagesDiscrepancy");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ áp dụng cho hàng tồn kho dư thừa của các lô hàng cần được mở khóa>';
													|ru = '<только для излишков партий, подлежащих разблокировке>';
													|en = '<only for surpluses of lots to be unlocked>'; fa = '<only for surpluses of lots to be unlocked>';
													|it = '<only for surpluses of lots to be unlocked>';
													|pl = '<only for surpluses of lots to be unlocked>';
													|tr = '<yalnızca kilidi kaldırılacak lotların fazlalıkları için>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsQualityConfirmationDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.InventoryRecountStatuses.InProgress);
	ValueList.Add(Enums.InventoryRecountStatuses.Prepared2);
	ItemFilter.RightValue = ValueList;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<để nhập kết quả>';
													|ru = '<для внесения результата>';
													|en = '<for entering result>'; fa = '<for entering result>';
													|it = '<per inserire il risultato>';
													|pl = '<dla wprowadzenia wyniku>';
													|tr = '<sonucu girmek için>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInMeasuredValueTypeAttribute",
											New Structure("Products", "MeasuredValueType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ConfigureByWarehouseRoom();
	InitializeDataLayout(False);
	
	Items.StorageBinForSurplusesConsolidation.Enabled = Object.MoveGoodsSurplusesIntoBin;
	Items.StorageBinForSpoiledGoodsConsolidation.Enabled = Object.MoveSpoiledGoodsIntoBin;
	
	FillInServiceDetailsForProductRange();
	FillIn_DiscrepancyFlag();
	SetStateOfEditingByStatus();
	
	Items.GroupInventoryInventories.Visible = AccessRight("Update", Metadata.Documents.InventoryRecount);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryRecount));
	SetVisibilityOfSeriesElements();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WarehouseSpaceWhenServerChanges(DirectModificationOfWarehouseField = False)
	
	UseAddressStorageCur = UseBinLocationWarehousing;
	
	ConfigureByWarehouseRoom();
	
	If UseBinLocationWarehousing And Object.Status = Enums.InventoryRecountStatuses.InProgress Then
		Object.Status = Enums.InventoryRecountStatuses.Prepared2;
	ElsIf Not UseBinLocationWarehousing And Object.Status = Enums.InventoryRecountStatuses.Prepared2 Then 
		Object.Status = Enums.InventoryRecountStatuses.InProgress;
	EndIf;
	
	If UseAddressStorageCur
		And Not UseBinLocationWarehousing Then
		
		For Each RowOfTables In Object.Goods Do
			
			RowOfTables.Package               = Undefined;
			RowOfTables.NumberOfPackages     = RowOfTables.Count;
			RowOfTables.NumberOfPackagesReal = RowOfTables.CountReal;
			RowOfTables.NumberOfPackagesDiscrepancy = RowOfTables.CountReal - RowOfTables.NumberOfPackages;
			
		EndDo;
		
	EndIf;
	
	CellStructure = Documents.InventoryRecount.GetDefaultSurplusAndRejectCells(Object.Ref, Object.Warehouse, Object.Premise);
	FillPropertyValues(Object, CellStructure);
	Items.StorageBinForSurplusesConsolidation.Enabled = Object.MoveGoodsSurplusesIntoBin;
	Items.StorageBinForSpoiledGoodsConsolidation.Enabled = Object.MoveSpoiledGoodsIntoBin;
	
	InitializeDataLayout(True);
	PrepareFillSetSeriesVisibility();
	
	If QualityControl.UpdateActionParameters(
			Documents.InventoryRecount,
			Object,
			CacheQualityControl,
			DirectModificationOfWarehouseField) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ConfigureByWarehouseRoom();
	PrepareFillSetSeriesVisibility();
	If QualityControl.UpdateActionParameters(
			Documents.InventoryRecount,
			Object,
			CacheQualityControl) Then
			
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EmployeeResponsibleOnChangeServer()
	
	Object.PrintQuantityByRecords = Documents.InventoryRecount.GetValueForPrintQuantityByAccountingDefaultAttribute(Object.Ref, Object.EmployeeResponsible);
	
EndProcedure

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	EditState = StateOfDocumentEditing(Object.Status, Object.Posted, UseInventoryRecountStatuses);
	
	If Not (EditState = "FullEditing" Or EditState = "LimitedEditing") Then
		Return;
	EndIf;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm, SeriesSpecificationParameters, Text, CurrentData) Then
		ExceptionText = NStr("vi = 'Lỗi khi thử chỉ ra sê-ri - để chỉ ra sê-ri trong chứng từ này, không cần lần gọi máy chủ.';
							|ru = 'Ошибка при попытке указать серии - в этом документе для указания серий не нужен серверный вызов.';
							|en = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.'; fa = 'An error occurred when attempting to specify batch. No server call is required to specify batch in this document.';
							|it = 'Si è verificato un errore durante il tentativo di indicare le serie - in questo documento non è necessaria la chiamata al server per indicare le serie.';
							|pl = 'Błąd podczas próby określenia serii - w tym dokumencie nie jest wymagane wywołanie serwera, aby wskazać serię.';
							|tr = 'Bir parti belirtmeye çalışırken hata oluştu - bu belgede bir parti belirtmek için sunucu çağrısı gerekmez.'");
		Raise ExceptionText;
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
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	StructureOfActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	AddActionsToStructureWhenChangingNumberOfPackagesReal(StructureOfActionsWithAddedStrings);
	StructureOfActionsWithAddedStrings.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	
	If EditState = "LimitedEditing" Then
		StructureOfActionsWithAddedStrings.Insert("FillExcessSpoilageFlag");
	EndIf;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingNumberOfPackagesReal(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ColumnNameQuantity                   = "NumberOfPackagesReal";
	StructureOfActions.NotUsePackages                 = Not UseBinLocationWarehousing;
	StructureOfActions.ChangeQuantity                     = Not (EditState = "NotIsBeingEdited");
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
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure PrepareFillSetSeriesVisibility()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryRecount));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
		
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure StatusChangedOnServer()
	If Object.Status = Enums.InventoryRecountStatuses.InProgress Then
		Object.Date = CurrentSessionDate();
		Object.LockStorageBins = True;
	ElsIf Object.Status = Enums.InventoryRecountStatuses.Completed2
		Or Object.Status = Enums.InventoryRecountStatuses.Prepared2 Then
		Object.LockStorageBins = False;
	EndIf;
	
	PastStatus = Common.ObjectAttributeValue(Object.Ref, "Status");
	
	If PastStatus = Enums.InventoryRecountStatuses.Prepared2 
		And Object.Status = Enums.InventoryRecountStatuses.InProgress Then
		
		Object.AccountingDataIsFilledIn = False;
		
	EndIf;
	
	SetStateOfEditingByStatus();
	
EndProcedure

&AtServer
Procedure FillServer()
	
	SetValueOfSettingsParameter(RecountFilter.Settings, "DateOfRemainingGoods", ?(ValueIsFilled(Object.Date),
		New Boundary(Object.Date, BoundaryType.Including),
		New Boundary(CurrentSessionDate(), BoundaryType.Including)));
	
	If UseBinLocationWarehousing Then
		DataCompositionSchema = Documents.InventoryRecount.GetTemplate("RecountFilterByStorageBins");
	Else	
		DataCompositionSchema = Documents.InventoryRecount.GetTemplate("RecountFilterByWarehouse");
	EndIf;
	
	QueryText = DataCompositionSchema.DataSets.FillingBySelection.Query;
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsInStorageBins.Package", Undefined));
	DataCompositionSchema.DataSets.FillingBySelection.Query = QueryText;

	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(RecountFilter);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, RecountFilter.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Object.Goods.Load(OutputProcessor.Output(DataCompositionProcessor));
	
	FillInServiceDetailsForProductRange();
	FillIn_DiscrepancyFlag();
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

&AtServer
Procedure FillInActualQuantityByRecordsServer()
	
	For Each RowOfTables In Object.Goods Do
		
		RowOfTables.CountReal = RowOfTables.Count;
		RowOfTables.NumberOfPackagesReal = RowOfTables.NumberOfPackages;
		RowOfTables.Discrepancy = (RowOfTables.CountReal <> RowOfTables.Count) Or (RowOfTables.NumberOfPackages <> RowOfTables.NumberOfPackagesReal);
		RowOfTables.NumberOfPackagesDiscrepancy = RowOfTables.NumberOfPackagesReal - RowOfTables.NumberOfPackages;
		
	EndDo;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure ConfigureByWarehouseRoom()
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date);
	
	UseInventoryRecountStatuses = WarehousesServer.UseInventoryRecountStatuses(Object.Warehouse);
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse, Premise",Object.Warehouse,Object.Premise));
	
	UseQuality = GetFunctionalOption("UseGoodsQuality");
	
	Items.UseTheDamageCell.Visible              = UseQuality And UseBinLocationWarehousing;
	Items.StorageBinForSpoiledGoodsConsolidation.Visible = UseQuality And UseBinLocationWarehousing;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryRecount));
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
	Items.GoodsCell.Visible                         = UseBinLocationWarehousing;
	Items.GoodsPackage.Visible                       = UseBinLocationWarehousing;
	Items.LockStorageBins.Visible                    = UseBinLocationWarehousing;
	Items.UseTheSurplusCell.Visible            = UseBinLocationWarehousing;
	Items.StorageBinForSurplusesConsolidation.Visible    = UseBinLocationWarehousing;
	Items.UseTheDamageCell.Visible              = UseBinLocationWarehousing;
	Items.StorageBinForSpoiledGoodsConsolidation.Visible = UseBinLocationWarehousing;
	Items.GoodsControlledLotReference.Visible           = Not UseBinLocationWarehousing;
	
	DisplayOfSceneryThereAreGoodsForRegistrationOfWarehouseActsInventoryInventories();

EndProcedure

&AtServer
Procedure InitializeDataLayout(AlwaysUseDefaultSettings)
	
	If UseBinLocationWarehousing Then
		DataCompositionSchema = Documents.InventoryRecount.GetTemplate("RecountFilterByStorageBins");
	Else
		DataCompositionSchema = Documents.InventoryRecount.GetTemplate("RecountFilterByWarehouse");
	EndIf;
	
	URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
	
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	
	RecountFilter.Initialize(SettingsSource);
	
	CurObject = FormAttributeToValue("Object");
	CurSettings = CurObject.RecountFilter.Get();
	If CurSettings = Undefined
		Or AlwaysUseDefaultSettings Then
		RecountFilter.LoadSettings(DataCompositionSchema.DefaultSettings);
	Else
		RecountFilter.LoadSettings(CurSettings);
	EndIf;
	
	RecountFilter.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	SetValueOfSettingsParameter(RecountFilter.Settings, "Warehouse" , Object.Warehouse);
	SetValueOfSettingsParameter(RecountFilter.Settings, "Premise", Object.Premise);
	
EndProcedure

&AtServer
Procedure SetValueOfSettingsParameter(Settings, ParameterName, Value)
	
	Parameter = Settings.DataParameters.Items.Find(ParameterName);
	
	If Parameter <> Undefined Then
		Parameter.Value = Value;
		Parameter.Use = True;
	EndIf;
	
EndProcedure

// Returns the editing state of the document.
//
// Parameters:
//	DocumentStatus - EnumRef.InventoryRecountStatuses - document status,
//	IndicationOfCompletion - Boolean - indicates whether the document is complete.
//
// Returns:
//	String
//
&AtClientAtServerNoContext
Function StateOfDocumentEditing(DocumentStatus, IndicationOfCompletion, UseInventoryRecountStatuses)
	
	If Not UseInventoryRecountStatuses Then
		EditState = "EditingWithoutStatuses";	
	ElsIf IndicationOfCompletion Then
		If DocumentStatus = PredefinedValue("Enum.InventoryRecountStatuses.Completed2") Then
			EditState = "NotIsBeingEdited";
		ElsIf DocumentStatus = PredefinedValue("Enum.InventoryRecountStatuses.EnteringResults") Then
			EditState = "LimitedEditing";
		ElsIf DocumentStatus = PredefinedValue("Enum.InventoryRecountStatuses.InProgress") Then
			EditState = "NotIsBeingEdited";
		ElsIf DocumentStatus = PredefinedValue("Enum.InventoryRecountStatuses.Prepared2") Then
			EditState = "FullEditing";
		EndIf;
	Else
		EditState = "FullEditing";
	EndIf;
	
	Return EditState;
	
EndFunction

&AtServer
Procedure SetStateOfEditingByStatus()
	
		EditState = StateOfDocumentEditing(Object.Status, Object.Posted, UseInventoryRecountStatuses);
	
	Items.Warehouse.ReadOnly = (Not EditState = "FullEditing" And Not EditState = "EditingWithoutStatuses");
	Items.Premise.ReadOnly = (Not EditState = "FullEditing" And Not EditState = "EditingWithoutStatuses");
	Items.GoodsFill.Enabled = (EditState = "FullEditing" Or EditState = "EditingWithoutStatuses");
	
	Items.ProductsFillInAccountingFact.Enabled = (Object.Status = Enums.InventoryRecountStatuses.EnteringResults 
		Or EditState = "EditingWithoutStatuses");
	
	Items.ChangeQuality.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing" 
		Or EditState = "EditingWithoutStatuses");
	
	Items.GoodsSplitRow.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing" 
		Or EditState = "EditingWithoutStatuses");
	
	Items.GoodsContextMenuSplitRow.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing" 
		Or EditState = "EditingWithoutStatuses");
	
	Items.GoodsSearchByBarcode.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing" 
		Or EditState = "EditingWithoutStatuses");
	
	Items.GoodsImportDataFromPDT.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing"
		Or EditState = "EditingWithoutStatuses");
	
	Items.GoodsUploadVTSDData.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing"
		Or EditState = "EditingWithoutStatuses");
	
	Items.GoodsGetWeight.Enabled = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing"
		Or EditState = "EditingWithoutStatuses");
	
	Items.OnlyDiscrepancies.Enabled = EditState <> "FullEditing";
	
	Items.Goods.ChangeRowSet = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing"
		Or EditState = "EditingWithoutStatuses");
	
	Items.Goods.ChangeRowOrder = 
		(EditState = "FullEditing" 
		Or EditState = "LimitedEditing"
		Or EditState = "EditingWithoutStatuses");
		
	Items.LockStorageBins.Enabled = (Object.Status = Enums.InventoryRecountStatuses.EnteringResults);
	
	If Not Object.Posted Then
		Items.LockStorageBins.Enabled = False;
	EndIf;
	
	DisplayOfSceneryThereAreGoodsForRegistrationOfWarehouseActsInventoryInventories();
	
EndProcedure

&AtServer
Procedure FillIn_DiscrepancyFlag()
	
	For Each RowOfTables In Object.Goods Do
		RowOfTables.Discrepancy = RowOfTables.CountReal <> RowOfTables.Count Or RowOfTables.NumberOfPackages <> RowOfTables.NumberOfPackagesReal;
		RowOfTables.NumberOfPackagesDiscrepancy = RowOfTables.NumberOfPackagesReal - RowOfTables.NumberOfPackages;
	EndDo;
	
EndProcedure

&AtServer
Function NumberOfFieldsFilled()
	
	FoundRows = Object.Goods.FindRows(New Structure("CountReal", 0));
	Return FoundRows.Count() <> Object.Goods.Count();
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingNumberOfPackagesReal(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Real");
	StructureOfActions.Insert("FillInDiscrepancyFlag");
	StructureOfActions.Insert("RecalculateNumberOfPackagesDeviation");
	
EndProcedure

&AtClient
Function WarehouseSpaceFilled()

	Result = True;
	
	If ValueIsFilled(Object.Warehouse) Then
		
		If Not ValueIsFilled(Object.Premise)
			And Items.Premise.Visible Then
			
			Result = False;
			MessageText = NStr("vi = 'Chưa điền trường ""Nhà kho"".
				|Để thực hiện thao tác, cần chỉ ra nhà kho mà đang tiến hành kiểm đếm';
				|ru = 'Не заполнено поле ""Помещение"".
				|Для выполнения действия необходимо указать помещение, в котором проводится пересчет';
				|en = '""Wareroom"" is required.
				|Specify a wareroom used to recount the goods'; fa = '""Wareroom"" is required.
				|Specify a wareroom used to recount the goods';
				|it = 'Il campo ""Locale"" non è compilato.
				|Per eseguire l''azione, è necessario specificare il locale dove il ricalcolo viene eseguito';
				|pl = 'Pole ""Pomieszczenie"" nie jest wypełnione.
				|Aby wykonać czynność, musisz określić pomieszczenie, w którym przeprowadzane jest przeliczanie';
				|tr = '""Depolama alanı"" alanı doldurulmadı.
				|Eylemi gerçekleştirmek için, yeniden hesaplamanın gerçekleştirildiği alanın belirtilmesi gerekir'");
			ClearMessages();
			CommonClientServer.MessageToUser(MessageText,,"Premise","Object");
			
		EndIf;
		
	Else
		
		Result = False;
		MessageText = NStr("vi = 'Chưa điền trường ""Kho bãi"".
			|Để thực hiện thao tác, cần chỉ ra kho bãi đang tiến hành kiểm đếm';
			|ru = 'Не заполнено поле ""Склад"".
			|Для выполнения действия необходимо указать склад, на котором проводится пересчет';
			|en = '""Warehouse"" is required.
			|Specify a warehouse used to recount the goods'; fa = '""Warehouse"" is required.
			|Specify a warehouse used to recount the goods';
			|it = 'Il campo ""Magazzino"" non è compilato.
			|Per eseguire l''azione, è necessario specificare il magazzino dove il ricalcolo viene eseguito';
			|pl = 'Pole ""Magazyn"" nie jest wypełnione
			|Aby wykonać czynność, musisz określić magazyn, w którym przeprowadzane jest ponowne obliczenie';
			|tr = '""Ambar"" alanı doldurulmadı.
			|İşlemi gerçekleştirmek için yeniden hesaplamanın yapılacağı ambarın belirtilmesi gerekir'");
		ClearMessages();
		CommonClientServer.MessageToUser(MessageText,,"Warehouse","Object");
		
	EndIf;
	
	Return Result;
	
EndFunction

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
Procedure GoodsNumberOfPackagesDiscrepancyOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddDeviationToActionStructureWhenChangingNumberOfPackages(StructureOfActions);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure DisplayOfSceneryThereAreGoodsForRegistrationOfWarehouseActsInventoryInventories()

	If ValueIsFilled(Object.Warehouse)
		And Object.Posted
		And Object.Status = Enums.InventoryRecountStatuses.Completed2 Then
		
		UseWarehouseManagemantSystemForGoodsSurplusesShortages = 
			WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date); 
		
		RowsArray = New Array;
		
		If UseWarehouseManagemantSystemForGoodsSurplusesShortages 
			And AccessRight("Use", Metadata.DataProcessors.WarehouseGoodsIssueReceiptWizard) Then 
			ProductsTable = DataProcessors.WarehouseGoodsIssueReceiptWizard.GoodsForRegistrationOfWarehouseActs(Object.Warehouse,,,Object.Date);
			If ProductsTable.Count() > 0 Then
				PartOfFormattedString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không phải theo tất cả chênh lệch đã lập biên bản kho. <a href=""%1"">Đã lập</a>. ';
						|ru = 'Не по всем расхождениям оформлены складские акты. <a href=""%1"">Оформить</a>.';
						|en = 'Inventory adjustments are not registered for some discrepancies. <a href=""%1"">Register</a>.'; fa = 'Inventory adjustments are not registered for some discrepancies. <a href=""%1"">Register</a>.';
						|it = 'Не по всем расхождениям оформлены складские акты. <a href=""%1"">Оформить</a>.';
						|pl = 'Inventory adjustments are not registered for some discrepancies. <a href=""%1"">Register</a>.';
						|tr = 'Tüm tutarsızlıklar için stok düzeltmeleri düzenlenmemiştir. <a href=""%1"">Düzenle</a>.'"),
					"WarehouseGoodsIssueReceiptWizard");
				RowsArray.Add(PartOfFormattedString);
			EndIf;
		EndIf;
		
		If AccessRight("Update", Metadata.Documents.PhysicalCountReport) Then 
			GenerationParameters = PrintManagementTMServerCall.GetFormationParameters(Object.Ref);
			CreatedSheets.LoadValues(GenerationParameters.Sheets);
			SelectionOfOrganizations = GenerationParameters.Companies;
			NumberOfOrganizations = SelectionOfOrganizations.Count();
			If NumberOfOrganizations > 0 Then
				If GetFunctionalOption("UseMultipleCompanies") Then 		
					OrganizationsInDativeCase = TMCommonUseClientServer.DeclensionOfWord(
						NumberOfOrganizations,
						NStr("vi = 'doanh nghiệp, doanh nghiệp, doanh nghiệp, m';
							|ru = 'организации, организациям, организациям, м';
							|en = 'company, companies'; fa = 'company, companies';
							|it = 'организации, организациям, организациям, м';
							|pl = 'company, companies';
							|tr = 'iş yeri, iş yeri, iş yerleri, m'"));

					PartOfFormattedString = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Ghi nhận chứng từ này trong <a href=""%1"">các biên bản kiểm kê</a> theo %2 %3.';
							|ru = 'Этот документ учитывается в <a href=""%1"">инвентаризационных описях</a> по %2 %3.';
							|en = 'This document is recorded in <a href=""%1"">physical inventory registers</a> by %2 %3.'; fa = 'This document is recorded in <a href=""%1"">physical inventory registers</a> by %2 %3.';
							|it = 'Этот документ учитывается в <a href=""%1"">инвентаризационных описях</a> по %2 %3.';
							|pl = 'This document is recorded in <a href=""%1"">physical inventory registers</a> by %2 %3.';
							|tr = '%2%3 göre bu belge fiziksel stok sayımlarında <a href=""%1</a> dikkate alınıyor.'"),
						"SheetList",
						NumberOfOrganizations,
						OrganizationsInDativeCase);
					Else
					PartOfFormattedString = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Chứng từ này được ghi nhận trong <a href=""%1"">biên bản kiểm kê</a>.';
							|ru = 'Этот документ учитывается в <a href=""%1"">инвентаризационных описях</a>.';
							|en = 'This document is recorded in <a href=""%1"">physical inventory registers</a>.'; fa = 'This document is recorded in <a href=""%1"">physical inventory registers</a>.';
							|it = 'Этот документ учитывается в <a href=""%1"">инвентаризационных описях</a>.';
							|pl = 'This document is recorded in <a href=""%1"">physical inventory registers</a>.';
							|tr = 'Bu belge fiziksel stok sayımlarında <a href=""%1""> dikkate alınıyor</a>.'"),
						"SheetList");
				EndIf;
				RowsArray.Add(PartOfFormattedString);
			EndIf;
			
			Query = New Query;
			Query.SetParameter("InventoryRecount", Object.Ref);
			Query.SetParameter("Warehouse", Object.Warehouse);
			Query.SetParameter("CurRecalculationDate", BegOfDay(Object.Date));
			Query.SetParameter("EndDate", BegOfDay(Object.Date));
			Query.TempTablesManager = New TempTablesManager;
			Query.Text =
			"SELECT DISTINCT
			|	RecalculationOfGoods.Products,
			|	RecalculationOfGoods.Characteristic,
			|	RecalculationOfGoods.Series,
			|	RecalculationOfGoods.Purpose
			|INTO GoodsList
			|FROM
			|	Document.InventoryRecount.Goods AS RecalculationOfGoods
			|WHERE
			|	RecalculationOfGoods.Ref = &InventoryRecount
			|	AND NOT RecalculationOfGoods.Count = RecalculationOfGoods.CountReal
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	InventorySurplusRecognition.Ref.Date AS Date,
			|	InventorySurplusRecognition.Ref.Organization
			|INTO WarehouseActs
			|FROM
			|	Document.InventorySurplusRecognition.Goods AS InventorySurplusRecognition
			|		INNER JOIN GoodsList AS GoodsList
			|		ON (GoodsList.Products = InventorySurplusRecognition.Products)
			|			AND (GoodsList.Characteristic = InventorySurplusRecognition.Characteristic)
			|			AND InventorySurplusRecognition.Series = GoodsList.Series
			|			AND InventorySurplusRecognition.Purpose = GoodsList.Purpose
			|WHERE
			|	InventorySurplusRecognition.Ref.Posted
			|	AND InventorySurplusRecognition.Ref.Warehouse = &Warehouse
			|
			|UNION ALL
			|
			|SELECT
			|	WriteOffOfShortagesOfGoods.Ref.Date,
			|	WriteOffOfShortagesOfGoods.Ref.Organization
			|FROM
			|	Document.WriteOffOfGoodsShortages.Goods AS WriteOffOfShortagesOfGoods
			|		INNER JOIN GoodsList AS GoodsList
			|		ON (GoodsList.Products = WriteOffOfShortagesOfGoods.Products)
			|			AND (GoodsList.Characteristic = WriteOffOfShortagesOfGoods.Characteristic)
			|			AND WriteOffOfShortagesOfGoods.Series = GoodsList.Series
			|			AND WriteOffOfShortagesOfGoods.Purpose = GoodsList.Purpose
			|WHERE
			|	WriteOffOfShortagesOfGoods.Ref.Posted
			|	AND WriteOffOfShortagesOfGoods.Ref.Warehouse = &Warehouse
			|
			|UNION ALL
			|
			|SELECT
			|	GoodsMisgradingGoods.Ref.Date,
			|	GoodsMisgradingGoods.Ref.Organization
			|FROM
			|	Document.GoodsMisgrading.Goods AS GoodsMisgradingGoods
			|		INNER JOIN GoodsList AS GoodsList
			|		ON (GoodsList.Products = GoodsMisgradingGoods.Products)
			|			AND (GoodsList.Characteristic = GoodsMisgradingGoods.Characteristic)
			|			AND GoodsMisgradingGoods.Series = GoodsList.Series
			|			AND GoodsMisgradingGoods.Purpose = GoodsList.Purpose
			|WHERE
			|	GoodsMisgradingGoods.Ref.Posted
			|	AND GoodsMisgradingGoods.Ref.Warehouse = &Warehouse
			|
			|UNION ALL
			|
			|SELECT
			|	GoodsDamageGoods.Ref.Date,
			|	GoodsDamageGoods.Ref.Organization
			|FROM
			|	Document.GoodsDamage.Goods AS GoodsDamageGoods
			|		INNER JOIN GoodsList AS GoodsList
			|		ON (GoodsList.Products = GoodsDamageGoods.Products)
			|			AND (GoodsList.Characteristic = GoodsDamageGoods.Characteristic)
			|			AND GoodsDamageGoods.Series = GoodsList.Series
			|			AND GoodsDamageGoods.Purpose = GoodsList.Purpose
			|WHERE
			|	GoodsDamageGoods.Ref.Posted
			|	AND GoodsDamageGoods.Ref.Warehouse = &Warehouse
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	MAX(WarehouseActs.Date) AS Date,
			|	WarehouseActs.Organization
			|INTO OrganizationsFromActs
			|FROM
			|	WarehouseActs AS WarehouseActs
			|
			|GROUP BY
			|	WarehouseActs.Organization
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED DISTINCT
			|	OrganizationsFromActs.Organization
			|FROM
			|	OrganizationsFromActs AS OrganizationsFromActs
			|		LEFT JOIN Document.PhysicalCountReport AS PhysicalCountReport
			|		ON (PhysicalCountReport.Posted)
			|			AND (PhysicalCountReport.Warehouse = &Warehouse)
			|			AND (PhysicalCountReport.Organization = OrganizationsFromActs.Organization)
			|			AND (OrganizationsFromActs.Date BETWEEN PhysicalCountReport.StartDate AND ENDOFPERIOD(PhysicalCountReport.EndDate, DAY))
			|WHERE
			|	PhysicalCountReport.Ref IS NULL ";
			SetPrivilegedMode(True);
			SelectionOfOrganizations = Query.Execute().Unload().UnloadColumn("Organization");
			SetPrivilegedMode(False);
			CompaniesWithNoSheets.LoadValues(SelectionOfOrganizations);
			NumberOfOrganizationsWithoutInventories = SelectionOfOrganizations.Count();
			If NumberOfOrganizationsWithoutInventories > 0 Then
				OrganizationsWithoutInventoriesInDativeCase = TMCommonUseClientServer.DeclensionOfWord(
					NumberOfOrganizationsWithoutInventories,
					NStr("vi = 'doanh nghiệp, doanh nghiệp, doanh nghiệp, m';
						|ru = 'организации, организациям, организациям, м';
						|en = 'company, companies'; fa = 'company, companies';
						|it = 'организации, организациям, организациям, м';
						|pl = 'company, companies';
						|tr = 'iş yeri, iş yeri, iş yerleri, m'"));

				PartOfFormattedString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cần <a href=""%1"">tạo</a> bản kê theo %2 %3.';
						|ru = 'Необходимо <a href=""%1"">сформировать</a> описи по %2 %3.';
						|en = '<a href=""%1"">Generate</a> physical inventory registers by %2 %3.'; fa = '<a href=""%1"">Generate</a> physical inventory registers by %2 %3.';
						|it = 'Необходимо <a href=""%1"">сформировать</a> описи по %2 %3.';
						|pl = '<a href=""%1"">Generate</a> physical inventory registers by %2 %3.';
						|tr = '%2%3 göre sayımları  <a href=""%1"">oluşturmak</a> gerekir '"),
					"CreateSheets",
					NumberOfOrganizationsWithoutInventories,
					OrganizationsWithoutInventoriesInDativeCase);
				RowsArray.Add(PartOfFormattedString);
			EndIf;
			
		EndIf;
		
		InventoryPeriodOfUnformulatedWarehouseActs.StartDate = BegOfDay(Object.Date);
		InventoryPeriodOfUnformulatedWarehouseActs.EndDate = EndOfMonth(CurrentSessionDate());		
		
		If RowsArray.Count() = 0 Then 
			Items.GroupIssueWarehouseCertificates.CurrentPage = Items.TheDecorationGroupIsNotVisible;
		Else
			Items.GroupIssueWarehouseCertificates.CurrentPage = Items.TheDecorationGroupIsVisible;
			Items.DecorationsThereAreGoodsForRegistrationOfWarehouseActsInventoryLists.Title =
				StringFunctions.FormattedString(StrConcat(RowsArray, Chars.LF));
		EndIf;
	Else
		Items.GroupIssueWarehouseCertificates.CurrentPage = Items.TheDecorationGroupIsNotVisible;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddDeviationToActionStructureWhenChangingNumberOfPackages(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacksFromDeviation", "Real");
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits", "Real");
	StructureOfActions.Insert("FillInDiscrepancyFlag");
	
EndProcedure

&AtClient
Procedure DecorationsThereAreGoodsForRegistrationOfWarehouseActsInventoryListsURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	Notification = New CallbackDescription("DecorationsThereAreGoodsForRegistrationOfWarehouseActsInventoryListsURLProcessingCompletion", ThisForm);
	If Var_URL = "WarehouseGoodsIssueReceiptWizard" Then
		
		FormParameters = New Structure("Warehouse, StocktakingPeriod", Object.Warehouse, InventoryPeriodOfUnformulatedWarehouseActs);
		OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form", FormParameters, ThisForm, , , , Notification);
		
	ElsIf Var_URL = "SheetList" Then
		
		GenerationParameters = New Structure;
		GenerationParameters.Insert("StartDate",InventoryPeriodOfUnformulatedWarehouseActs.StartDate);
		GenerationParameters.Insert("EndDate",InventoryPeriodOfUnformulatedWarehouseActs.EndDate);
		GenerationParameters.Insert("Warehouse", Object.Warehouse);
		GenerationParameters.Insert("MarkOrganizations",CompaniesWithNoSheets.UnloadValues());
		GenerationParameters.Insert("Sheets",CreatedSheets.UnloadValues());
		
		OpenForm("Document.PhysicalCountReport.Form.PrintForm_2",
			GenerationParameters, ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
	ElsIf Var_URL = "CreateSheets" Then
		
		GenerationParameters = New Structure;
		GenerationParameters.Insert("StartDate",InventoryPeriodOfUnformulatedWarehouseActs.StartDate);
		GenerationParameters.Insert("EndDate",InventoryPeriodOfUnformulatedWarehouseActs.EndDate);
		GenerationParameters.Insert("Warehouse", Object.Warehouse);
		GenerationParameters.Insert("MarkOrganizations",CompaniesWithNoSheets.UnloadValues());
		
		OpenForm("Document.PhysicalCountReport.Form.FormGenerate",
			GenerationParameters, ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationsThereAreGoodsForRegistrationOfWarehouseActsInventoryListsURLProcessingCompletion(Result, AdditionalParameters) Export
	DisplayOfSceneryThereAreGoodsForRegistrationOfWarehouseActsInventoryInventories();
EndProcedure


#EndRegion

#EndRegion

#Region Initialize

RecordingIsInProgress = False;

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
