
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();

	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	Asset = Object.Asset;
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_RMRequest", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");

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
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			PickingParameters = TMCommonUseClientServer.PickingParameters(Items.DefectiveSubAssetsNode, ThisObject);
			ProcessingProcedure = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
			
			RMManagementClient.ProcessInputOfBarcodes(
				EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter), 
				ProcessingProcedure, 
				PickingParameters);
				
		EndIf;
	EndIf;
	// End Peripherals

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
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
Procedure AssetOnChange(Item)
	
	If Object.DefectiveSubAssets.Count() <> 0 Then
		
		QueryText = NStr("vi = 'tài sản đang vận hành ""%Asset%"", bảng lỗi bộ phận được điền';
						|ru = 'Для объекта эксплуатации ""%Asset%"" заполнена таблица дефектов узлов';
						|en = 'Failure table is populated for ""%Asset%""'; fa = 'Failure table is populated for ""%Asset%""';
						|it = 'Per l''oggetto d''uso ""%Asset%"" è stata compilata la tabella dei difetti dei nodi';
						|pl = 'Dla obiektu eksploatacji ""%Asset%"" wypełniono tabelę wad węzłów';
						|tr = 'İşlem nesnesi için ""%Asset%"" alt varlığı kusur tablosu doldurulur'");
		QueryText = StrReplace(QueryText, "%Asset%", Asset);
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.OK, NStr("vi = 'Xóa bảng';
													|ru = 'Очистить таблицу';
													|en = 'Clear table'; fa = 'Clear table';
													|it = 'Cancella la tabella';
													|pl = 'Wyczyść tabelę';
													|tr = 'Tabloyu temizle'"));
		AnswersOptions.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отменить';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annullare';
														|pl = 'Cancel';
														|tr = 'İptal et'"));
		
		ShowQueryBox(New CallbackDescription("AssetOnChangeCompletion", ThisObject), QueryText, AnswersOptions);
        
        Return;
	EndIf;
	
    ObjectOfOperationWhenChangedOnServer();
    
EndProcedure

&AtClient
Procedure FailureDetailsStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.FailureDetails",
		NStr("vi = 'Mô tả ngắn gọn hư hỏng';
			|ru = 'Краткое описание дефекта';
			|en = 'Failure details'; fa = 'Failure details';
			|it = 'Descrizione breve del difetto';
			|pl = 'Krótki opis wady';
			|tr = 'Kusurun kısa açıklaması'"));

EndProcedure

&AtClient
Procedure ObjectDefectPageGroupOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
	        And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
	    
	    PropertiesExecuteDeferredInitialization();
	    PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SearchByBarcode(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.DefectiveSubAssetsNode, ThisObject);
	ProcessingProcedure = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	RMManagementClient.SearchForNodesByBarcode(ProcessingProcedure, PickingParameters);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#Region StandardSubsystems

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

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

#EndRegion

#EndRegion

#Region Private

#Region StandardSubsystems

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

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
    PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure LoadDataFromTSD()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Not Result.Result Then
		EquipmentManagerTMClient.ReportError(Result);
		Return;
	EndIf;

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.DefectiveSubAssetsNode, ThisObject);
	SearchResult = FindNodesByBarcodes(Result.TableOfGoods, PickingParameters);
	
	If SearchResult.ObjectsArray.Count() = 0
		Or SearchResult.DoNotFit.Count() <> 0 Then
		RMManagementClient.ReportResultsOfSearchForNodesByBarcode(SearchResult);
	EndIf;
	
	AddFoundNodes(SearchResult.ObjectsArray);
	
EndProcedure

&AtServerNoContext
Function FindNodesByBarcodes(Val BarcodeData_5, Val PickingParameters)
	
	Return RMManagement.FindNodesByBarcodes(BarcodeData_5, PickingParameters);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure OnCreatReadAtServer()
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillUnitSelectionList();
	Asset = Object.Asset;
	
EndProcedure

&AtServer
Procedure FillUnitSelectionList()
	
	List = Items.Department.ChoiceList;
	List.Clear();
	
	DetailsOfObjectOfOperation = Common.ObjectAttributesValues(
		Object.Asset,
		"OperatingBusinessUnit, RMBusinessUnit");
	
	If ValueIsFilled(DetailsOfObjectOfOperation.OperatingBusinessUnit) Then
		List.Add(DetailsOfObjectOfOperation.OperatingBusinessUnit, NStr("vi = 'Bộ phận vận hành';
																		|ru = 'Эксплуатирующее подразделение';
																		|en = 'Operating business unit'; fa = 'واحد تجاری بهره‌بردار';
																		|it = 'Reparto operativo';
																		|pl = 'Dział eksploatacyjny';
																		|tr = 'İşlem alt departmanı'"));
	EndIf;
	
	If ValueIsFilled(DetailsOfObjectOfOperation.RMBusinessUnit) Then
		List.Add(DetailsOfObjectOfOperation.RMBusinessUnit, NStr("vi = 'Bộ phận sửa chữa';
																|ru = 'Ремонтирующее подразделение';
																|en = 'R&M business unit'; fa = 'واحد تجاری تعمیر و نگهداری';
																|it = 'Reparto di riparazione';
																|pl = 'Dział remontowy';
																|tr = 'Onarım departmanı'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure AssetOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    
    If Response = DialogReturnCode.OK Then
        Object.DefectiveSubAssets.Clear();
        Asset = Object.Asset;
    Else
        Object.Asset = Asset;
    EndIf;
    
    ObjectOfOperationWhenChangedOnServer();

EndProcedure

&AtServer
Procedure ObjectOfOperationWhenChangedOnServer()
	
    Asset = Object.Asset;
	
	FillUnitSelectionList();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(FoundNodes, AdditionalParameters) Export
	
	AddFoundNodes(FoundNodes);
	
EndProcedure

&AtClient
Procedure AddFoundNodes(FoundNodes)
	
	For Each NodeRef1 In FoundNodes Do
		TheStructureOfTheSearch = New Structure("Node", NodeRef1);
		StringsList = Object.DefectiveSubAssets.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			NewRow = Object.DefectiveSubAssets.Add();
			NewRow.Node = NodeRef1;
		EndIf;
	EndDo;
	
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
