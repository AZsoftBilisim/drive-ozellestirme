#Region Variables

&AtClient
Var CachedValues;

&AtServer
Var CachedValues;

&AtClient
Var CurDataId;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	UseTrackingOfTraceableItems = GetFunctionalOption("UseTraceableImportedGoodsAccounting");
	Items.GoodsCCDNumber.Visible = UseTrackingOfTraceableItems;
	Items.GoodsQuantityByGBRN.Visible = UseTrackingOfTraceableItems;

	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
		Items.GoodsCCDNumber.Name);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
		
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If ValueIsFilled(Object.DocumentBasis) Then
		Notify("RecordingDocumentBasedOnInventoryInventoryOfBusinessCenter",, Object.Ref);
	EndIf;

	Notify("Write_RecordInventoryInOperation", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	

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
	

	FillInServiceDetailsOfTS();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
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
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations


EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CurrencyOnChange(Item)
	
	CurrencyOnChangeClient();
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

// StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

// End StandardSubsystems.FilesOperations

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item, CachedValues, SeriesSpecificationParameters, Copy);

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(StructureOfActions, ThisObject, CurrentRow);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenCharacteristicChanges(StructureOfActions, ThisObject);

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
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

	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
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
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
EndProcedure

&AtClient
Procedure GoodsOperationCategoryOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	WhenChangingCategoryOfOperation(CurrentRow);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);

	InventoryInOperationClient.ProcessLineWhenChangingCategoryOfOperation(CurrentRow, Object.Goods, StructureOfActions);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
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
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn", True);
	FormParameters.Insert("HideTheItemPricesCommand", True);
	FormParameters.Insert("FilterByProductType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False)));
	FormParameters.Insert("Title", NStr("vi = 'Chọn hàng hóa';
										|ru = 'Подбор товаров';
										|en = 'Pick goods'; fa = 'انتخاب کالاها';
										|it = 'Selezione delle merci';
										|pl = 'Wybór towarów';
										|tr = 'Ürünlerin seçimi'"));
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Document", Object.Ref);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);

EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure FillInInventoryNumber(Command)
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.StocktakingRecord Then
			StringsList.Add(RowID);
		EndIf;
	EndDo;
	
	If StringsList.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn các dòng có kế toán vật tư';
								|ru = 'Необходимо выбрать строки с инвентарным учетом';
								|en = 'Select lines with stocktaking record'; fa = 'Select lines with stocktaking record';
								|it = 'È necessario selezionare le righe con contabilità di inventario';
								|pl = 'Należy wybrać wiersze z ewidencją inwentarzową';
								|tr = 'Envanter satırlarını seçmeniz gerekir'"));
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Điền số kiểm kê trong các dòng đã chọn?';
					|ru = 'Заполнить инвентарный номер в выбранных строках?';
					|en = 'Do you want to fill the inventory number in the selected lines?'; fa = 'Do you want to fill the inventory number in the selected lines?';
					|it = 'Compilare il numero di inventario nelle righe selezionate?';
					|pl = 'Wypełnić numer inwentarzowy w wybranych wierszach?';
					|tr = 'Seçilen satırlardaki stok numarasını mı dolduruyorsunuz?'");
	CallbackDescription = New CallbackDescription("FillInInventoryNumberCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInCategoryOfOperation(Command)
	
	ItemSelectionOptions_ = TMCommonUseClientServer.ChoiceParameters(Items.GoodsOperationCategory, ThisObject);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("SelectedRows", Items.Goods.SelectedRows);
	CallbackDescription = New CallbackDescription("FillInCategoryOfOperationCompletion", ThisObject, AdditionalParameters);

	InventoryInOperationClient.FillInCategoryOfOperation(
		Object.Goods,
		Items.Goods.SelectedRows,
		ItemSelectionOptions_,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInIndividual(Command)
	
	InventoryInOperationClient.FillInIndividual(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(Command)
	
	ClearMessages();
	
	If Object.Goods.Count() = 0 Then
		MessageText = NStr("vi = 'Trong chứng từ chưa điền bảng ""Vật tư đang sử dụng"". Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица ""ТМЦ в эксплуатации"". Цены не могут быть заполнены';
							|en = 'The ""Inventory in operation"" table is not filled in the document. Cannot fill the prices'; fa = 'The ""Inventory in operation"" table is not filled in the document. Cannot fill the prices';
							|it = 'Nel documento non è compilata la tabella ""Beni materiali in lavorazione"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela ""Zapasy w eksploatacji"". Ceny nie mogą być wypełnione';
							|tr = '""Kullanımdaki stok"" tablosu belgede doldurulmamıştır. Fiyatlar doldurulamıyor'");
		CommonClient.MessageToUser(MessageText,,"Goods","Object");
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
		CommonClient.MessageToUser(MessageText,,"PriceKind","Object");
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

#Region AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations


#EndRegion

#EndRegion

#Region Private

#Region AttachableCommands

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
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		AdditionalParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
						ParametersOfSeriesIndicationForm,
						ThisObject,,,, 
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
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
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RecordInventoryInOperation));
	EndIf; 
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
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
	AddActionsToStructureWhenChangingProducts(StructureOfActionsWithAddedStrings, ThisObject);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
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
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
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
	
	Columns = "Products,Characteristic,Series,AssetID,OperationCategory,Individual,
	|ServiceLife,Package,NumberOfPackages,Price";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns); // ValueTable
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddActionsToStructureWhenChangingCategoryOfOperation(StructureOfActions);
	
	RowsToProcess = New Array;
	DoNotFillServiceLife = New Array;
	
	For Each TSRow In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, TSRow);
		
		If CurrentRow.ServiceLife <> 0 Then
			DoNotFillServiceLife.Add(CurrentRow);
		Else
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	StructureOfActions.FillInCategoryAttributes.FillInServiceLife = False;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		DoNotFillServiceLife,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInServiceDetailsOfTS();
	FillInStatusesForSpecifyingSeriesServer();
	
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

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	
	InventoryInOperationServer.SetConditionalRegistrationOfInventoryNumber(
		ThisObject,,, "Object.Goods.OperationCategory");
		
	InventoryInOperationServer.EstablishConditionalRegistrationOfIndividual(
		ThisObject,,, "Object.Goods.OperationCategory");
				
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	DocumentCurrency = Object.Currency;

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RecordInventoryInOperation));

	SetVisibilityOfSeriesElements();
	FillInServiceDetailsOfTS();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		Items.DocumentBasis.Visible = ValueIsFilled(Object.DocumentBasis);
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()
	
	FillParameters = New Structure;
	FillParameters.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	FillParameters.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	FillParameters.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, FillParameters);
	
	Catalogs.OperationCategories.FillInCategoryAttributes(Object.Goods);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(StructureOfActions, Form, CurrentRow = Undefined)
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", Form.FormName, "Goods"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Undefined, Form.SeriesSpecificationParameters));

	If CurrentRow <> Undefined Then
		StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	EndIf;
		
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenCharacteristicChanges(StructureOfActions, Form)
	
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable", 
		New Structure("FormName, TabularSectionName", Form.FormName, "Goods"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingCategoryOfOperation(StructureOfActions)
	
	FillParameters = InventoryInOperationClientServer.ParametersForFillingInOperationCategoryAttributes();
	FillParameters.FillInExpenseItem = False;
	FillParameters.FillInServiceLife = True;
	StructureOfActions.Insert("FillInCategoryAttributes", FillParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInInventoryNumberCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInInventoryNumberOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInInventoryNumberOnServer()
	
	TakeIntoAccountInventoryNumbers = New Array;
	For Each RowData In Object.Goods Do
		If RowData.StocktakingRecord
			And ValueIsFilled(RowData.AssetID)
			And Items.Goods.SelectedRows.Find(RowData.GetID()) = Undefined Then
			TakeIntoAccountInventoryNumbers.Add(RowData.AssetID);
		EndIf;
	EndDo;
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.StocktakingRecord Then
			StringsList.Add(RowID);
		EndIf;
	EndDo;

	NewInventoryNumbers = InventoryInOperationServer.NewInventoryNumbers(
		StringsList.Count(),
		TakeIntoAccountInventoryNumbers, 
		Object.Ref);
	
	For IndexOf = 0 To StringsList.UBound() Do
		RowData = Object.Goods.FindByID(StringsList[IndexOf]);
		RowData.AssetID = NewInventoryNumbers[IndexOf];
	EndDo;
	
EndProcedure

&AtClient
Procedure CreateGroupFACompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CreateGroupOSOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateGroupOSOnServer()
	
	StringsList = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowData = Object.Goods.FindByID(RowID);
		If RowData.AccountAsGroupFA Then
			StringsList.Add(RowData);
		EndIf;
	EndDo;

	If StringsList.Count() = 0 Then
		Return;
	EndIf;

	TabularSection = Object.Goods; // FormDataCollection
	ListOfCategories = TabularSection.Unload(StringsList, "OperationCategory").UnloadColumn("OperationCategory");
	
	QueryText = 
	"SELECT
	|	OperationCategories.Ref AS Ref,
	|	OperationCategories.OSGroup AS OSGroup,
	|	&StartDateOfOperation AS StartDateOfOperation,
	|	CASE
	|		WHEN ISNULL(OperationCategories.ServiceLife, 0) <> 0
	|			THEN BEGINOFPERIOD(ENDOFPERIOD(DATEADD(&StartDateOfOperation, MONTH, OperationCategories.ServiceLife), MONTH), DAY)
	|		ELSE DATETIME(1,1,1)
	|	END AS CompletionDate_,
	|	OperationCategories.ServiceLife AS ServiceLife
	|FROM
	|	Catalog.OperationCategories AS OperationCategories
	|WHERE
	|	OperationCategories.Ref IN (&ListOfCategories)
	|	AND OperationCategories.AccountAsGroupFA";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfCategories", ListOfCategories);
	Query.SetParameter("StartDateOfOperation", BegOfMonth(Object.Date));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	CreatedOS = New Map();
	NamingParameters = New Structure("StartDateOfOperation,CompletionDate_,ServiceLife,OperationCategory");

	While Selection.Next() Do
		
		FillPropertyValues(NamingParameters, Selection);
		NamingParameters.OperationCategory = Selection.Ref;
		
		FixedAsset = Catalogs.Assets.CreateItem();
		FixedAsset.OSType = Enums.FATypes.GroupFA;
		FixedAsset.Description = Catalogs.LotsOfInventoryInOperation.FormNameOfGroupOS(NamingParameters);
		FixedAsset.OSGroup = Selection.OSGroup;
		FixedAsset.Write();
	
		CreatedOS.Insert(Selection.Ref, FixedAsset.Ref);
		
	EndDo;

	For Each RowData In StringsList Do
		FixedAsset = CreatedOS.Get(RowData.OperationCategory);
		If FixedAsset <> Undefined Then
			RowData.FixedAsset = FixedAsset;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic,
			| ItemVariantsAreUsed, Package, NumberOfPackages, Series");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);

	FillInStatusesForSpecifyingSeriesServer();
	
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
	
	OldCurrency = DocumentCurrency;
	NewCurrency = Object.Currency;
	DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date,CurrentSessionDate());
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
Function FillInPricesByPriceKindServer()
	
	PricesCalculated = False;
	
	If Object.Goods.Count() = 0 Then
		Return PricesCalculated;
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("PriceKind", Object.PriceKind);
	FillParameters.Insert("Organization", Object.Organization);
			
	StructureOfActions = New Structure("RecalculateAmount", "NumberOfPackages");
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods,, FillParameters, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure WhenChangingCategoryOfOperation(CurrentRow)
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingCategoryOfOperation(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If Not CurrentRow.AccountingForIndividuals Then
		CurrentRow.Individual = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInCategoryOfOperationCompletion(Result, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentRow = Object.Goods.FindByID(RowID);
		WhenChangingCategoryOfOperation(CurrentRow);
		
	EndDo;
	
	InventoryInOperationClient.ProcessLineWhenChangingCategoryOfOperation(SelectedRows, Object.Goods);
	
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
