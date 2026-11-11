#Region Variables

&AtClient
Var CachedValues;

&AtServer
Var CachedValues;

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
	
	DocumentCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	SetAvailabilityOfClipboardCommands();
	
	TypeProducts = Common.StringTypeDetails(Metadata.Catalogs.Products.DescriptionLength);
	TypeCharacteristic = Common.StringTypeDetails(Metadata.Catalogs.ItemsCharacteristics.DescriptionLength);
	TypeSeries = Common.StringTypeDetails(Metadata.Catalogs.ItemsBatches.DescriptionLength);
	TypeCodeProduct = Common.StringTypeDetails(Metadata.Catalogs.Products.CodeLength);
	ProductTypeItem = Metadata.Catalogs.Products.Attributes.SKU.Type;
	TypeInventoryNumber = Metadata.DefinedTypes.InventoryNumberOfInventoryInOperation.Type;
	TypeIndividual = Common.StringTypeDetails(Metadata.Catalogs.Persons.DescriptionLength);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
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
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties


	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
		
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PhysicalCountOfInventoryInOperation", WriteParameters, Object.Ref);
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
	
	If EventName = "RecordingDocumentBasedOnInventoryInventoryOfBusinessCenter" Then
		AfterRecordingDocumentCreatedOnBasisOf();
	EndIf;

	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;

	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
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
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure IndividualOnChange(Item)
	
	IndividualOnChangeAtServer()
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

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
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.GoodsGeneratedDocument Then
		StandardProcessing = False;
		If ValueIsFilled(CurrentData.GeneratedDocument) Then
			ShowValue(, CurrentData.GeneratedDocument);
		Else
			CreateDocumentBasedOn(CurrentData);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAssetIDOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	WhenChangingDataInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsAssetIDAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	PickingParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation(Object.Date, Object.Organization, Object.Department);
	PickingParameters.CurrentRegistrar = Object.Ref;
	
	If ValueIsFilled(Object.Individual) Then
		PickingParameters.Individual = Object.Individual;
	EndIf;
	
	InventoryInOperationClient.AutoSelectionByInventoryNumber(
		Text, 
		PickingParameters,
		ChoiceData,
		StandardProcessing);

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
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	WhenChangingDataInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsWhenChangingProducts(StructureOfActions, ThisObject, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);

	WhenChangingDataInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	WhenChangingDataInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);

	WhenChangingDataInRow(CurrentData);

EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);

EndProcedure

&AtClient
Procedure GoodsIndividualOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;

	WhenChangingDataInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsActualQuantityOnChange(Item)
	
	RowData = Items.Goods.CurrentData;
	
	WhenChangingDataInRow(RowData);
	
EndProcedure

&AtClient
Procedure GoodsCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	AdditionalParameters = New Structure("RowID", Items.Goods.CurrentRow);
	Notification = New CallbackDescription("GoodsCommentStartChoiceCompletion", ThisObject, AdditionalParameters);
	
	CommonClient.ShowMultilineTextEditingForm(Notification, Item.EditText);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPhysicalInventoryCountCommission

&AtClient
Procedure PhysicalInventoryCountCommissionBeforeDeleteRow(Item, Cancel)
	
	CurLineIsTS = Items.PhysicalInventoryCountCommission.CurrentData;
	If CurLineIsTS.Chairman Then
		IndexOfRowBeingDeleted = Object.PhysicalInventoryCountCommission.IndexOf(CurLineIsTS);
		RowsCount = Object.PhysicalInventoryCountCommission.Count() - 1;
		
		If RowsCount > 0 Then
			If IndexOfRowBeingDeleted <= RowsCount - 1 Then
				IndexOfNewChairman = IndexOfRowBeingDeleted + 1;
			Else
				IndexOfNewChairman = RowsCount - 1;
			EndIf;
			Object.PhysicalInventoryCountCommission[IndexOfNewChairman].Chairman = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PhysicalInventoryCountCommissionOnStartEdit(Item, NewRow, Copy)
	
	If Copy Then
		CurLineIsTS = Items.PhysicalInventoryCountCommission.CurrentData;
		CurLineIsTS.Person = Undefined;
		CurLineIsTS.Chairman = False;
	Else // Creating anew
		If Object.PhysicalInventoryCountCommission.Count() = 1 Then
			Object.PhysicalInventoryCountCommission[0].Chairman = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PhysicalInventoryCountCommissionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	Rows = Object.PhysicalInventoryCountCommission.FindRows(New Structure("Person", ValueSelected));
	
	If Rows.Count() > 0 Then
		MessageTemplate = NStr("vi = 'Đã chọn cá nhân <%1>';
								|ru = 'Физическое лицо <%1> уже подобрано';
								|en = 'Person <%1> is already picked'; fa = 'Person <%1> is already picked';
								|it = 'Persona fisica <%1> già selezionata';
								|pl = 'Osoba fizyczna jest <%1> jest już wybrana';
								|tr = '<%1> gerçek kişisi zaten eşleştirildi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ValueSelected);
		ShowMessageBox(Undefined, MessageText, 60);
	Else
		NewRow = Object.PhysicalInventoryCountCommission.Add();
		NewRow.Person = ValueSelected;
		If Object.PhysicalInventoryCountCommission.Count() = 1 Then
			NewRow.Chairman = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryFeeChairmanOnChange(Item)
	
	CurLineIsTS = Items.PhysicalInventoryCountCommission.CurrentData;
	
	If Not CurLineIsTS.Chairman Then
		// You can't uncheck the box
		CurLineIsTS.Chairman = True;
		Return;
	EndIf;
	
	For Each TSRow In Object.PhysicalInventoryCountCommission Do
		If TSRow.LineNumber <> CurLineIsTS.LineNumber Then
			TSRow.Chairman = False;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure InventoryFeeIndividualOnChange(Item)
	
	If Object.PhysicalInventoryCountCommission.Count() = 1 Then
		Object.PhysicalInventoryCountCommission[0].Chairman = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure InventoryFeeIndividualChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CurLineIsTS = Items.PhysicalInventoryCountCommission.CurrentData;
	If CurLineIsTS.Person <> ValueSelected Then
		TabularSectionRows = Object.PhysicalInventoryCountCommission.FindRows(New Structure("Person", ValueSelected));
		If TabularSectionRows.Count() > 0 Then
			StandardProcessing = False;
			MessageTemplate = NStr("vi = 'Đã đưa cá nhân <%1> vào thành phần hội đồng';
									|ru = 'Физическое лицо <%1> уже включено в состав комиссии';
									|en = 'Person <%1> is already included in the commission'; fa = 'Person <%1> is already included in the commission';
									|it = 'Persona fisica <%1> già inclusa nella composizione della commissione';
									|pl = 'Osoba fizyczna <%1> jest już włączona do zestawu komisji';
									|tr = '<%1> gerçek kişisi zaten komisyona dahil edilmiştir'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ValueSelected);
			ShowMessageBox(Undefined, MessageText, 60);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInByBalance(Command)
	
	Cancel = False;
	If Not ValueIsFilled(Object.Organization) Then
		MessageText = NStr("vi = 'Cần điền doanh nghiệp';
							|ru = 'Необходимо заполнить организацию';
							|en = 'Fill the company'; fa = 'Fill the company';
							|it = 'Compilare l''azienda';
							|pl = 'Należy wypełnić firmę';
							|tr = 'İş yerinin doldurulması gerekmektedir'");
		CommonClient.MessageToUser(MessageText, , "Organization", "Object", Cancel); 
	EndIf; 
	If Not ValueIsFilled(Object.Department) Then
		MessageText = NStr("vi = 'Cần điền bộ phận';
							|ru = 'Необходимо заполнить подразделение';
							|en = 'Fill the business unit'; fa = 'پرکردن واحد تجاری';
							|it = 'Compilare il reparto';
							|pl = 'Należy wypełnić dział';
							|tr = 'Departman alanının doldurulması gereklidir'");
		CommonClient.MessageToUser(MessageText, , "Department", "Object", Cancel); 
	EndIf; 
	
	If Cancel Then
		Return;
	EndIf; 
	
	If Object.Goods.Count() <> 0 Then
		CallbackDescription = New CallbackDescription("FillInByBalanceCompletion", ThisObject);
		FillInTabularSection(CallbackDescription);
	Else
		FillInByBalanceCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAccountingData(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInAccountingDataCompletion", ThisObject);
	FillInTabularSection(CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInActualData(Command)
	
	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInActualDataCompletion", ThisObject);
	FillInTabularSection(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();

EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfRowsChanged = GetLinesFromClipboard();
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfRowsChanged);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "PhysicalCountOfInventoryInOperation.Goods";
	ImportParameters.Title = NStr("vi = 'Kết nhập kết quả kiểm kê';
									|ru = 'Загрузка результатов инвентаризации';
									|en = 'Import physical inventory count results'; fa = 'Import physical inventory count results';
									|it = 'Download dei risultati di inventariazione';
									|pl = 'Wczytywanie wyników inwentaryzacji';
									|tr = 'Envanter sonuçlarını indirme'");
	ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsToDownload();

	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Date", Object.Date);
	AdditionalParameters.Insert("Organization", Object.Organization);
	AdditionalParameters.Insert("Department", Object.Department);
	AdditionalParameters.Insert("Individual", Object.Individual);
	ImportParameters.AdditionalParameters = AdditionalParameters;
    
    Notification = New CallbackDescription("ImportGoodsFromFileCompletion", ThisObject);
    ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);

EndProcedure

&AtClient
Procedure SetRefundAction(Command)
	
	ChangeReflectionOfInventoryResults(PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation"));

EndProcedure

&AtClient
Procedure SetLoggingAction(Command)
	
	ChangeReflectionOfInventoryResults(PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived"));

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

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

#EndRegion

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

#Region FillType

&AtClient
Procedure FillInTabularSection(CallbackDescription)

	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại sẽ được điền lại.
                         |Tiếp tục?';
                         |ru = 'При заполнении существующие данные будут перезаполнены.
                         |Продолжить?';
                         |en = 'The existing data will be repopulated upon population.
                         |Continue?'; fa = 'The existing data will be repopulated upon population.
                         |Continue?';
                         |it = 'Durante la compilazione, i dati esistenti saranno ricompilati.
                         |Continuare?';
                         |pl = 'W przypadku wypełnienia istniejące dane zostaną wypełnione ponownie.
                         |Kontynuować?';
                         |tr = 'Doldurma sırasında mevcut veriler yeniden yazılacak!
                         |Devam edilsin mi?'");
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 

EndProcedure
 
&AtClient
Procedure FillInByBalanceCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
	"PhysicalCountOfInventoryInOperation.DocumentForm.FillInByBalance");
	
	FillByBalancesOnServer();
	
EndProcedure

&AtServer
Procedure FillByBalancesOnServer()

	CurCurrentAccountingData = New FixedMap(New Map);
	
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.Department) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	InventoryInOperation.Individual AS Individual,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.AssetID AS AssetID,
	|	SUM(InventoryInOperation.CountBalance) AS QuantityAccordingToAccountingData
	|FROM
	|	AccumulationRegister.InventoryInOperation.Balance(
	|			&Date,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND (Individual = &Individual
	|					OR &Individual = VALUE(Catalog.Persons.EmptyRef))) AS InventoryInOperation
	|
	|GROUP BY
	|	InventoryInOperation.Individual,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.Series,
	|	InventoryInOperation.AssetID
	|
	|HAVING
	|	SUM(InventoryInOperation.CountBalance) > 0
	|
	|ORDER BY
	|	InventoryInOperation.Individual.LastFirstName,
	|	InventoryInOperation.Products.Presentation,
	|	InventoryInOperation.Characteristic.Presentation,
	|	InventoryInOperation.Series.Presentation,
	|	InventoryInOperation.AssetID
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Department", Object.Department);
	Query.SetParameter("Individual", Object.Individual);
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date), BegOfDay(Object.Date), BegOfDay(CurrentSessionDate())));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	AddedRows = New Array;

	SearchFields = "AssetID,Products,Characteristic,Series";
	If Not ValueIsFilled(Object.Individual) Then
		SearchFields = SearchFields + ",Individual";
	EndIf;
	TheStructureOfTheSearch = New Structure(SearchFields);
	
	GoodsSearch = Object.Goods.Unload();
	GoodsSearch.Indexes.Add(SearchFields);
	
	While Selection.Next() Do
		
		FillPropertyValues(TheStructureOfTheSearch, Selection);
		StringsList = GoodsSearch.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			
			RowData = Object.Goods.Add();
			FillPropertyValues(RowData, TheStructureOfTheSearch);
			
			AddedRows.Add(RowData);
			
			RowData = GoodsSearch.Add();
			FillPropertyValues(RowData, TheStructureOfTheSearch);
			
		EndIf;
		
	EndDo;
	
	FillInAccountingDataOnServer(AddedRows);

	FillInServiceDetailsOfTS();
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtClient
Procedure FillInAccountingDataCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccountingDataEndOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccountingDataEndOnServer()

	FillInAccountingDataOnServer(Object.Goods);
	
EndProcedure
 
&AtServer
Procedure FillInAccountingDataOnServer(RowsCollection, SetAction = True)

	Documents.PhysicalCountOfInventoryInOperation.FillInAccountingData(Object, RowsCollection, True, SetAction);

	DocumentsBasedOn = DocumentsBasedOn(Object.Ref, Object.Organization, Object.Department, Object.Individual);
		
	For Each RowData In RowsCollection Do
		
		FillInCalculatedFields(RowData);
		
		DocumentsRows = DocumentsBasedOn.FindRows(InventoryKey(Object.Organization, Object.Department, Object.Individual, RowData));
		FillInDocumentBasedOn(RowData, DocumentsRows);
		
	EndDo; 

EndProcedure

&AtClient
Procedure FillInActualDataCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInActualDataOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInActualDataOnServer()

	For Each RowID In Items.Goods.SelectedRows Do
		
		RowData = Object.Goods.FindByID(RowID);
		RowData.Quantity_Actual = RowData.QuantityAccordingToAccountingData;
		
		InventoryInOperationClientServer.FillInActionBasedOnInventory(
			RowData,
			Undefined,
			Object.Organization, 
			Object.Department,
			Object.Individual);
		
		FillInCalculatedFields(RowData);
		
	EndDo; 

EndProcedure

&AtClient
Procedure ChangeReflectionOfInventoryResults(NewAction)

	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Thay đổi';
												|ru = 'Изменить';
												|en = 'Change'; fa = 'تغییر';
												|it = 'Modificare';
												|pl = 'Change';
												|tr = 'Değiştir'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	QueryText = NStr("vi = 'Thay đổi phản ánh kết quả kiểm kê trong các dòng được chọn?';
					|ru = 'Изменить отражение результатов инвентаризации в выбранных строках?';
					|en = 'Do you want to change the record of physical inventory count results in the selected lines?'; fa = 'Do you want to change the record of physical inventory count results in the selected lines?';
					|it = 'Modificare la riflessione dei risultati di inventariazione nelle stringhe selezionate?';
					|pl = 'Zmienić wyświetlenie wyników inwentaryzacji w wybranych wierszach?';
					|tr = 'Stok sonuçlarının seçili satırlardaki yansımasını mı değiştiriyorsunuz?'");
	
	CallbackDescription = New CallbackDescription("ChangeReflectionOfInventoryResultsCompletion", ThisObject, NewAction);

	ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	
EndProcedure

&AtClient
Procedure ChangeReflectionOfInventoryResultsCompletion(QuestionResult, NewAction) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ChangeReflectionOfInventoryResultsOnServer(NewAction);
	
EndProcedure

&AtServer
Procedure ChangeReflectionOfInventoryResultsOnServer(Val NewAction)

	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;

	DocumentsBasedOn = DocumentsBasedOn(Object.Ref, Object.Organization, Object.Department, Object.Individual);

	For Each RowID In Items.Goods.SelectedRows Do
		
		RowData = Object.Goods.FindByID(RowID);
		
		If Documents.PhysicalCountOfInventoryInOperation.YouCanSetAction(RowData, NewAction) Then
			
			RowData.Action = NewAction;
			
			DocumentsRows = DocumentsBasedOn.FindRows(InventoryKey(Object.Organization, Object.Department, Object.Individual, RowData));
			FillInDocumentBasedOn(RowData, DocumentsRows);
			
		EndIf;
		
	EndDo;
	
	FillInServiceDetailsOfTS();
	
EndProcedure

#EndRegion

#Region GenerateFrom

&AtClient
Procedure CreateDocumentBasedOn(RowData)

	If Not ValueIsFilled(RowData.Action) Then
		Return;
	EndIf;
	
	If Not Object.Posted Or Modified Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		
		QueryText = NStr("vi = 'Để tạo chứng từ, trước hết cần kết chuyển chứng từ.
                             |Kết chuyển và tiếp tục?';
                             |ru = 'Для создания документа необходимо предварительно провести документ.
                             |Провести и продолжить?';
                             |en = 'To create the document, post it first.
                             |Post and continue?'; fa = 'To create the document, post it first.
                             |Post and continue?';
                             |it = 'Per la creazione del documento è necessario prima pubblicare il documento.
                             |Pubblicare e continuare?';
                             |pl = 'Aby utworzyć dokument należy wstępnie zatwierdzić dokument.
                             |Zatwierdzić i kontynuować?';
                             |tr = 'Bir belge oluşturmak için önce belgeyi çalıştırmanız gerekir. 
                             | Kaydedilsin ve Devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("HoldDocumentAndCreateBasedOnEnd", ThisObject, RowData);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList);
		
	Else
		
		CreateDocumentBasedOnCompletion(RowData);
		
	EndIf;

EndProcedure

&AtClient
Procedure HoldDocumentAndCreateBasedOnEnd(QuestionResult, RowData) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		TMCommonUseClient.Post(ThisObject);
		If Object.Posted And Not Modified Then
			CreateDocumentBasedOnCompletion(RowData);
		EndIf; 
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateDocumentBasedOnCompletion(RowData)
	
	ArrayOfLineNumbers = New Array;
	ArrayOfLineNumbers.Add(RowData.LineNumber);
	
	FillingValues = New Structure;
	FillingValues.Insert("DocumentBasis", Object.Ref);
	FillingValues.Insert("ArrayOfLineNumbers", ArrayOfLineNumbers);
	FillingValues.Insert("ReportErrors", True);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	If RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived") Then
		NameOfFormToOpen_ = "Document.RecordInventoryInOperation.ObjectForm";
	ElsIf RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation") Then
		NameOfFormToOpen_ = "Document.OtherGoodsRecordingAsReceived.ObjectForm";
	ElsIf RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		NameOfFormToOpen_ = "Document.Decomissioning.ObjectForm";
	EndIf; 
	
	OpenForm(NameOfFormToOpen_, FormParameters, ThisObject, ThisObject);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)

	If Not ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters, Text, CurrentData) Then
		Return;
	EndIf;
		
	If CurrentData = Undefined Then
		CurDataId = Items.Goods.CurrentData.GetID();
	Else
		CurDataId = CurrentData.GetID();
	EndIf;

	ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
	
	AddlParameters = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
	CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AddlParameters);
	
	OpenForm(
		ParametersOfSeriesIndicationForm.FormName,
		ParametersOfSeriesIndicationForm,
		ThisObject,,,, 
		CallbackDescription, 
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    If Result <> Undefined Then
        ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
		
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.PhysicalCountOfInventoryInOperation));
	EndIf; 
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

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

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region StandardSubsystems

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
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

// End StandardSubsystems.Properties

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Function GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns = "Products,Characteristic,Series,AssetID,Individual";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return 0;
	EndIf;
	
	AddedRows = New Array;
	
	TheStructureOfTheSearch = New Structure("AssetID,Products,Characteristic,Series");
	If Not ValueIsFilled(Object.Individual) Then
		TheStructureOfTheSearch.Insert("Individual");
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	For Each TSRow In TableOfGoods Do
		
		FillPropertyValues(TheStructureOfTheSearch, TSRow);
		StringsList = Object.Goods.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			Continue
		EndIf;
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, TSRow);
		
		AddedRows.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods);
	
	FillInAccountingDataOnServer(AddedRows);
	
	FillInServiceDetailsOfTS();
	FillInStatusesForSpecifyingSeriesServer();
	
	Return AddedRows.Count();
	
EndFunction

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

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	SearchResult = InventoryInOperationServer.FindObjectsByBarcodes(BarcodeData_5);
	
	ObjectsTable = SearchResult.ObjectsTable;
	ObjectsTable.GroupBy("AssetID,Products,Characteristic,Series,Individual");
	
	AddedRows = New Array;

	TheStructureOfTheSearch = New Structure("AssetID,Products,Characteristic,Series");
	If Not ValueIsFilled(Object.Individual) Then
		TheStructureOfTheSearch.Insert("Individual");
	EndIf;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	For Each ObjectData In ObjectsTable Do
		
		FillPropertyValues(TheStructureOfTheSearch, ObjectData);
		StringsList = Object.Goods.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			
			RowData = Object.Goods.Add();
			FillPropertyValues(RowData, TheStructureOfTheSearch);
			AddedRows.Add(RowData);
			
		Else
			
			RowData = StringsList[0];
			
		EndIf;
		
		RowData.Quantity_Actual = RowData.Quantity_Actual + 1;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object.Goods);
	
	FillInAccountingDataOnServer(AddedRows);

	FillInServiceDetailsOfTS();
	FillInStatusesForSpecifyingSeriesServer();
	
	InventoryInOperationServer.ReportBarcodeSearchResults(SearchResult);
	
EndProcedure

&AtClient
Procedure LoadDataFromTSD()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ImportGoodsFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
    
    If ImportedDataAddress <> Undefined Then 
	    UploadProductsFromFileOnServer(ImportedDataAddress);
    EndIf;
    
EndProcedure

&AtServer
Procedure UploadProductsFromFileOnServer(Val ImportedDataAddress)
    
    ImportedData = GetFromTempStorage(ImportedDataAddress); // ValueTable
    
	AddedRows = New Array;
    ProductsAdded_ = False;

	TheStructureOfTheSearch = New Structure("AssetID,Products,Characteristic,Series");
	If Not ValueIsFilled(Object.Individual) Then
		TheStructureOfTheSearch.Insert("Individual");
	EndIf;

    For Each TableRow In ImportedData Do 
        
        If Not ValueIsFilled(TableRow.Products) Then 
            Continue;
        EndIf;
        
		FillPropertyValues(TheStructureOfTheSearch, TableRow);
		StringsList = Object.Goods.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			
			RowData = Object.Goods.Add();
			FillPropertyValues(RowData, TheStructureOfTheSearch);
			
			AddedRows.Add(RowData);
			
		Else
			RowData = StringsList[0];
		EndIf;
        
        RowData.Quantity_Actual = TableRow.Quantity_Actual;
        RowData.Action = TableRow.Action;
        
        ProductsAdded_ = True;
        
    EndDo;
 	
 	FillInAccountingDataOnServer(AddedRows, False);
	
	FillInServiceDetailsOfTS();
	FillInStatusesForSpecifyingSeriesServer();
    
    If ProductsAdded_ Then
        Modified = True;
    EndIf;
    
EndProcedure

&AtClient
Function DescriptionOfTemplateColumnsToDownload()
	
 	TemplateColumns = New Array;
 	
 	Column = ImportDataFromFileClientServer.TemplateColumnDetails("AssetID", TypeInventoryNumber, NStr("vi = 'Số kiểm kê';
																										|ru = 'Инв. №';
																										|en = 'Inv. No.'; fa = 'شماره اموال';
																										|it = '№ d''Inventario ';
																										|pl = 'Nr inwentarzowy';
																										|tr = 'Env. No.'"), 10);
	Column.Parent = "AssetID";
	TemplateColumns.Add(Column);
	
 	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductsAndServicesCode", TypeCodeProduct, NStr("vi = 'Mã mặt hàng';
																													|ru = 'Код номенклатуры';
																													|en = 'Items code'; fa = 'کد اقلام';
																													|it = 'Codice dell''elenco articoli';
																													|pl = 'Kod towaru';
																													|tr = 'Öğe kodu'"), 15);
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
 	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductIDOfItems", ProductTypeItem, NStr("vi = 'Mã hiệu mặt hàng';
																											|ru = 'Артикул номенклатуры';
																											|en = 'Item ID'; fa = 'شناسه قلم';
																											|it = 'ID articolo';
																											|pl = 'Artykuł towaru';
																											|tr = 'Ürün numarası'"), 15);
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
 	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Products", TypeProducts, NStr("vi = 'Mặt hàng';
																									|ru = 'Номенклатура';
																									|en = 'Item'; fa = 'قلم';
																									|it = 'Nomenclatura';
																									|pl = 'Produkt';
																									|tr = 'Öğe'"), 20);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Characteristic", TypeCharacteristic, NStr("vi = 'Đặc tính';
																											|ru = 'Характеристика';
																											|en = 'Variant'; fa = 'گونه';
																											|it = 'Caratteristica';
																											|pl = 'Charakterystyka';
																											|tr = 'Varyant'"), 20);
	TemplateColumns.Add(Column);

	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Series", TypeSeries, NStr("vi = 'Sê-ri';
																							|ru = 'Серия';
																							|en = 'Batch'; fa = 'بچ';
																							|it = 'Serie';
																							|pl = 'Seria';
																							|tr = 'Parti'"), 15);
	TemplateColumns.Add(Column);

	If Object.Individual.IsEmpty() Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Individual", TypeIndividual, NStr("vi = 'Cá nhân';
																										|ru = 'Физическое лицо';
																										|en = 'Person'; fa = 'شخص';
																										|it = 'Persona fisica';
																										|pl = 'Osoba fizyczna';
																										|tr = 'Gerçek kişi'"), 20);
		TemplateColumns.Add(Column);
	EndIf;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Quantity_Actual", TMCommonUseClientServer.TypeDescriptionNumber(15,3), NStr("vi = 'Số lượng';
																																				|ru = 'Количество';
																																				|en = 'Quantity'; fa = 'مقدار';
																																				|it = 'Quantità';
																																				|pl = 'Ilość';
																																				|tr = 'Miktar'"), 10);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Comment", TMCommonUseClientServer.StringTypeDetails(150), NStr("vi = 'Ghi chú';
																																	|ru = 'Комментарий';
																																	|en = 'Comment'; fa = 'توضیحات';
																																	|it = 'Commento';
																																	|pl = 'Uwagi';
																																	|tr = 'Yorum'"), 25);
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ActionName", TMCommonUseClientServer.StringTypeDetails(25), NStr("vi = 'Làm thế nào để lập chứng từ ghi nhận hàng thừa';
																																	|ru = 'Как оформить излишек';
																																	|en = 'How to register surplus'; fa = 'How to register surplus';
																																	|it = 'Come formalizzare le eccedenze';
																																	|pl = 'Jak zarejestrować nadwyżkę';
																																	|tr = 'Bir fazlalık nasıl düzenlenir'"), 30);
	TemplateColumns.Add(Column);
	
	For Position = 1 To TemplateColumns.Count() Do
		TemplateColumns[Position-1].Position = Position;
	EndDo;

	Return TemplateColumns;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, "SeriesAlwaysWHGoods");
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, True);
	
	#Region ProductsDocumentBasedOn_TextColor
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsGeneratedDocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.GeneratedDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	#Region ProductsAction_Text
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.GeneratedDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	#EndRegion

	#Region ProductsAction_TextColor
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
	#Region ProductsAction_Display
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.GeneratedDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
		
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.PhysicalCountOfInventoryInOperation));

	SetVisibilityOfSeriesElements();

	FillInServiceDetailsOfTS();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	DataOfAccounting = Documents.PhysicalCountOfInventoryInOperation.DataOfAccounting(
		Object.Ref, Object.Date, Object.Organization, Object.Department, Object.Goods);
	
	DocumentsBasedOn = DocumentsBasedOn(Object.Ref, Object.Organization, Object.Department, Object.Individual);
								
	For Each RowData In Object.Goods Do
		
		LineAccountingData = Documents.PhysicalCountOfInventoryInOperation.LineAccountingData(
			Object.Organization, Object.Department, Object.Individual, RowData, DataOfAccounting);
		
		DocumentsRows = DocumentsBasedOn.FindRows(InventoryKey(Object.Organization, Object.Department, Object.Individual, RowData));
		FillInDocumentBasedOn(RowData, DocumentsRows);
		
		If LineAccountingData <> Undefined Then
			RowData.OrganizationBasedOnAccountingData = LineAccountingData.Organization;
			RowData.AccountingDataDivision = LineAccountingData.Department;
			RowData.IndividualAccordingToAccountingData = LineAccountingData.Individual;
		EndIf; 
		
		FillInCalculatedFields(RowData);
		
	EndDo; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsWhenChangingProducts(StructureOfActions, Form, CurrentRow)
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	CheckSeriesCalculateStatus = New Structure("SeriesSpecificationParameters, Warehouse", Form.SeriesSpecificationParameters, Undefined);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
EndProcedure

&AtServerNoContext
Function DocumentsBasedOn(Ref, Organization, Department, Individual, StringDataByStructure = Undefined)

	DocumentsBasedOn = New ValueTable();
	DocumentsBasedOn.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DocumentsBasedOn.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	DocumentsBasedOn.Columns.Add("AssetID", Metadata.DefinedTypes.InventoryNumberOfInventoryInOperation.Type);
	DocumentsBasedOn.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	DocumentsBasedOn.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	DocumentsBasedOn.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	DocumentsBasedOn.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	DocumentsBasedOn.Columns.Add("RecordingAsReceived", New TypeDescription("DocumentRef.RecordInventoryInOperation"));
	DocumentsBasedOn.Columns.Add("WriteOff", New TypeDescription("DocumentRef.Decomissioning"));
	DocumentsBasedOn.Columns.Add("PutOutOfOperation", New TypeDescription("DocumentRef.OtherGoodsRecordingAsReceived"));

	QueryText = 
	"SELECT DISTINCT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived) AS Action,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Ref AS Ref,
	|	GoodsTable.AssetID AS AssetID,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Individual AS Individual
	|FROM
	|	Document.RecordInventoryInOperation AS DocumentData
	|
	|		INNER JOIN Document.RecordInventoryInOperation.Goods AS GoodsTable
	|		ON GoodsTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND &DocumentBasis <> VALUE(Document.PhysicalCountOfInventoryInOperation.EmptyRef)
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Department = &Department
	|
	|	AND (NOT &FilterByLine
	|		OR GoodsTable.Products = &Products
	|			AND GoodsTable.Characteristic = &Characteristic
	|			AND GoodsTable.Series = &Series
	|
	|			AND (GoodsTable.AssetID = &AssetID
	|				OR &AssetID = """" AND &QuantityAccordingToAccountingData = 0))
	|
	|			AND (GoodsTable.Individual = &Individual
	|				OR &Individual = VALUE(Catalog.Persons.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation) AS Action,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Ref AS Ref,
	|	GoodsTable.AssetID AS AssetID,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Individual AS Individual
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentData
	|
	|		INNER JOIN Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|		ON GoodsTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND &DocumentBasis <> VALUE(Document.PhysicalCountOfInventoryInOperation.EmptyRef)
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Department = &Department
	|
	|	AND (NOT &FilterByLine
	|		OR GoodsTable.Products = &Products
	|			AND GoodsTable.Characteristic = &Characteristic
	|			AND GoodsTable.Series = &Series
	|
	|			AND (GoodsTable.AssetID = &AssetID
	|				OR &AssetID = """" AND &QuantityAccordingToAccountingData = 0))
	|
	|			AND (GoodsTable.Individual = &Individual
	|				OR &Individual = VALUE(Catalog.Persons.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff),
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Ref,
	|	GoodsTable.AssetID AS AssetID,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Individual AS Individual
	|FROM
	|	Document.Decomissioning AS DocumentData
	|
	|		INNER JOIN Document.Decomissioning.Goods AS GoodsTable
	|		ON (GoodsTable.Ref = DocumentData.Ref)
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND &DocumentBasis <> VALUE(Document.PhysicalCountOfInventoryInOperation.EmptyRef)
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Department = &Department
	|
	|	AND (NOT &FilterByLine
	|		OR GoodsTable.Products = &Products
	|			AND GoodsTable.Characteristic = &Characteristic
	|			AND GoodsTable.Series = &Series
	|			AND GoodsTable.AssetID = &AssetID
	|			AND (GoodsTable.Individual = &Individual
	|				OR &Individual = VALUE(Catalog.Persons.EmptyRef))
	|	)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", Ref);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	
	If StringDataByStructure <> Undefined Then
		Query.SetParameter("FilterByLine", True);
		Query.SetParameter("AssetID", StringDataByStructure.AssetID);
		Query.SetParameter("Products", StringDataByStructure.Products);
		Query.SetParameter("Characteristic", StringDataByStructure.Characteristic);
		Query.SetParameter("Series", StringDataByStructure.Series);
		Query.SetParameter("Individual", Individual);
		Query.SetParameter("QuantityAccordingToAccountingData", StringDataByStructure.QuantityAccordingToAccountingData);
	Else
		Query.SetParameter("FilterByLine", False);
		Query.SetParameter("AssetID", "");
		Query.SetParameter("Products", Undefined);
		Query.SetParameter("Characteristic", Undefined);
		Query.SetParameter("Series", Undefined);
		Query.SetParameter("Individual", Catalogs.Persons.EmptyRef());
		Query.SetParameter("QuantityAccordingToAccountingData", 0);
	EndIf;
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	Selection = Result.Select();
	While Selection.Next() Do
		
		NewDocument = DocumentsBasedOn.Add();
		FillPropertyValues(NewDocument, Selection);
		
		If Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived Then
			NewDocument.RecordingAsReceived = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation Then
			NewDocument.PutOutOfOperation = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.WriteOff Then
			NewDocument.WriteOff = Selection.Ref;
		EndIf; 
		
		// When registering, the inventory number may not be specified in the inventory, but it is specified in the registration.
		If Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived
			And ValueIsFilled(NewDocument.AssetID) Then
				
			NewDocument = DocumentsBasedOn.Add();
			FillPropertyValues(NewDocument, Selection);
			NewDocument.AssetID = "";
			
		EndIf;
		
	EndDo;
	
	DocumentsBasedOn.Indexes.Add("Organization,Department,AssetID,Products,Characteristic,Series,Individual");

	Return DocumentsBasedOn;

EndFunction

&AtClient
Procedure WhenChangingDataInRow(RowData)

	StringDataByStructure = New Structure("AssetID,Products,Characteristic,Series,Individual,QuantityAccordingToAccountingData");
	FillPropertyValues(StringDataByStructure, RowData);
	
	LineAccountingData = LineAccountingData(
		Object.Ref, Object.Date, Object.Organization, Object.Department, Object.Individual, StringDataByStructure);
	
	InventoryInOperationClientServer.FillInInventoryLineBasedOnAccountingData(Object, RowData, LineAccountingData, True);
	
	DocumentsRows = DocumentsRows(Object.Ref, Object.Organization, Object.Department, Object.Individual, StringDataByStructure);
	FillInDocumentBasedOn(RowData, DocumentsRows);
	
	FillInCalculatedFields(RowData);

EndProcedure

&AtClientAtServerNoContext
Procedure FillInDocumentBasedOn(RowData, DocumentsRows)
	
	RowData.GeneratedDocument = Undefined;
	
	If DocumentsRows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In DocumentsRows Do
		
		If RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived") Then
			RowData.GeneratedDocument = Item.RecordingAsReceived;
		ElsIf RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation") Then
			RowData.GeneratedDocument = Item.PutOutOfOperation;
		ElsIf RowData.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
			RowData.GeneratedDocument = Item.WriteOff;
		EndIf;
		
		If ValueIsFilled(RowData.GeneratedDocument) Then
			Break;
		EndIf;
		 
	EndDo;
		
EndProcedure

&AtServerNoContext
Function InventoryKey(Val Organization, Val Department, Val Individual, Val RowData)
	Return Documents.PhysicalCountOfInventoryInOperation.InventoryKey(Organization, Department, Individual, RowData);
EndFunction

&AtClientAtServerNoContext
Procedure FillInCalculatedFields(RowData)
	
	Difference = RowData.Quantity_Actual - RowData.QuantityAccordingToAccountingData;

	RowData.ExcessQuantity = ?(Difference > 0, Difference, 0);
	RowData.QuantityShortage_ = ?(Difference < 0, -Difference, 0);

EndProcedure

&AtServerNoContext
Function LineAccountingData(Val Ref, Val Date, Val Organization, Val Department, Val Individual, Val StringDataByStructure)

	DataOfAccounting = Documents.PhysicalCountOfInventoryInOperation.DataOfAccounting(
		Ref, Date, Organization, Department, CommonClientServer.ValueInArray(StringDataByStructure));
								
	Return Documents.PhysicalCountOfInventoryInOperation.LineAccountingData(
			Organization, Department, Individual, StringDataByStructure, DataOfAccounting);
	
EndFunction

&AtServerNoContext
Function DocumentsRows(Val Ref, Val Organization, Val Department, Val Individual, Val StringDataByStructure)

	DocumentsBasedOn = DocumentsBasedOn(Ref, Organization, Department, Individual, StringDataByStructure);
	DocumentsRows = DocumentsBasedOn.FindRows(InventoryKey(Organization, Department, Individual, StringDataByStructure));
	
	Result = New Array;
	For Each Item In DocumentsRows Do
		
		DocumentsWithStructure = New Structure;
		DocumentsWithStructure.Insert("RecordingAsReceived", Item.RecordingAsReceived);
		DocumentsWithStructure.Insert("WriteOff", Item.WriteOff);
		DocumentsWithStructure.Insert("PutOutOfOperation", Item.PutOutOfOperation);
		
		Result.Add(DocumentsWithStructure);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure AfterRecordingDocumentCreatedOnBasisOf()

	FillInServiceDetailsOfTS();

EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	DocumentCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	FillInAccountingDataOnServer(Object.Goods);
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()

	FillInAccountingDataOnServer(Object.Goods);

EndProcedure

&AtServer
Procedure IndividualOnChangeAtServer()

	FillInAccountingDataOnServer(Object.Goods);
	
		
	For Each RowData In Object.Goods Do
			
		If ValueIsFilled(Object.Individual) Then
		
			RowData.Individual = Catalogs.Persons.EmptyRef();
			
		Else

			RowData.Individual = RowData.IndividualAccordingToAccountingData;
			
			InventoryInOperationClientServer.FillInActionBasedOnInventory(
				RowData,
				Undefined, 
				Object.Organization, 
				Object.Department,
				Object.Individual);
			
			FillInCalculatedFields(RowData);
			
		EndIf;
			
	EndDo;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "Individual");
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	FillInAccountingDataOnServer(Object.Goods);

EndProcedure

&AtClient
Procedure GoodsCommentStartChoiceCompletion(Val EnteredText, Val AdditionalParameters) Export
	
	If EnteredText = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(AdditionalParameters.RowID);
	CurrentData.Comment = EnteredText;

	Modified = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)
	
	Object = Form.Object;
	Items = Form.Items;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Individual")
		Or UpdateAll Then
		Items.GoodsIndividual.Visible = Not ValueIsFilled(Object.Individual);
	EndIf;
	
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
