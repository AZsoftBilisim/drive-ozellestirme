
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
	EndIf;
	
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
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();

	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
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

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInAdditionalDetailsOnPage(Object.RunningTime);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ErrorTemplate = NStr("vi = 'Cột ""tài sản đang vận hành"" không được điền vào dòng %LineNumber% của danh sách ""Sản lượng""';
						|ru = 'Не заполнена колонка ""Объект эксплуатации"" в строке %LineNumber% списка ""Наработки""';
						|en = 'The ""Asset"" column in line %LineNumber% of the ""Asset activity"" list is not filled in'; fa = 'The ""Asset"" column in line %LineNumber% of the ""Asset activity"" list is not filled in';
						|it = 'Non è compilata la colonna ""Oggetto in uso"" nella riga %LineNumber% dell''elenco ""Tempi senza guasti""';
						|pl = 'Nie jest wypełniona kolumna ""Obiekt eksploatacji"" w wierszu %LineNumber% listy ""Średni czas pracy"".';
						|tr = '""Devam eden işler"" listesinin %LineNumber% satırındaki ""Varlık"" sütunu doldurulmamış'");
	
	For Each OperatingTimeLine In Object.RunningTime Do
		
		If Not ValueIsFilled(OperatingTimeLine.FormObject) Then
			CommonClientServer.MessageToUser(
				StrReplace(ErrorTemplate, "%LineNumber%", OperatingTimeLine.LineNumber),,
				CommonClientServer.PathToTabularSection("Object.RunningTime", OperatingTimeLine.LineNumber, "FormObject"),,
				Cancel);
		EndIf;
		
	EndDo;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_AssetActivityRecord", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
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
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessingProcedure = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
			
			If UseSubAssets Then
				RMManagementClient.ProcessInputOfBarcodesOfObjectsOfOperationOrNodes(
					EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter), 
					ProcessingProcedure, 
					PickingParameters());
			Else
				NonCurrentAssetsClient.ProcessInputOfBarcodesOfObjectsOfOperation(
					EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter), 
					ProcessingProcedure, 
					PickingParameters());
			EndIf;
			
		EndIf;
	EndIf;
	// End Peripherals
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

#EndRegion

#Region FormTableItemsEventHandlersRunningTime

&AtClient
Procedure RunningTimeFormObjectOnChange(Item)
	
	CurrentData = Items.RunningTime.CurrentData;
	CurrentData.Asset = CurrentData.FormObject;
	
	If Not UseRMManagement Then
		RunningTimeOfFormObjectWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure RunningTimeFormNodeOnChange(Item)
	
	CurrentData = Items.RunningTime.CurrentData;

	If ValueIsFilled(CurrentData.FormNode) Then
		CurrentData.Asset = CurrentData.FormNode;
		If Not ValueIsFilled(CurrentData.FormObject) Then
			CurrentData.FormObject = NodeOwner(CurrentData.FormNode);
		EndIf;
	Else
		CurrentData.Asset = CurrentData.FormObject;
	EndIf;
	
EndProcedure

&AtClient
Procedure RunningTimeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	OperatingTimeProcessingSelectionOnServer(ValueSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	FASelectionParameters = TMCommonUseClientServer.PickingParameters(Items.RunningTimeFormObject, ThisForm);
	OpenForm("Catalog.Assets.Form.ExtendedChoiceForm", 
					FASelectionParameters, Items.RunningTime,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
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

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcode(Command)
	
	ProcessingProcedure = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	If UseSubAssets Then
		RMManagementClient.SearchForObjectsOfOperationOrNodesByBarcode(ProcessingProcedure, PickingParameters());
	Else
		NonCurrentAssetsClient.SearchForObjectsOfOperationByBarcode(ProcessingProcedure, PickingParameters());
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region Private

#Region StandardSubsystems

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeCompletion(FoundObjects, AdditionalParameters) Export
	
	AddFoundObjects(FoundObjects);
	
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
	
	If Not Result.Result Then
		EquipmentManagerTMClient.ReportError(Result);
		Return;
	EndIf;

	If UseSubAssets Then
		SearchResult = FindObjectsOfOperationOrNodesByBarcodes(Result.TableOfGoods, PickingParameters());
	Else
		SearchResult = FindObjectsOfOperationByBarcodes(Result.TableOfGoods, PickingParameters());
	EndIf;
	
	If SearchResult.ObjectsArray.Count() = 0
		Or SearchResult.DoNotFit.Count() <> 0 Then
		
		If UseSubAssets Then
			RMManagementClient.ReportResultsOfSearchForObjectsOfOperationOrNodesByBarcode(SearchResult);
		Else
			NonCurrentAssetsClient.ReportResultsOfSearchForOperationalObjectsByBarcode(SearchResult);
		EndIf;
	EndIf;
	
	AddFoundObjects(SearchResult.ObjectsArray);
	
EndProcedure

&AtServerNoContext
Function FindObjectsOfOperationByBarcodes(Val BarcodeData_5, Val PickingParameters)
	
	Return NonCurrentAssets.FindObjectsByBarcodes(BarcodeData_5, PickingParameters);
	
EndFunction

&AtServerNoContext
Function FindObjectsOfOperationOrNodesByBarcodes(Val BarcodeData_5, Val PickingParameters)
	
	Return RMManagement.FindObjectsOfOperationOrNodesByBarcodes(BarcodeData_5, PickingParameters);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeFormObject.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RunningTime.FormObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure 

&AtServer
Procedure OnReadCreateAtServer()
	
	UseSubAssets = GetFunctionalOption("UseSubAssets");
	UseRMManagement = GetFunctionalOption("UseRMManagement");
	
	FillInAdditionalDetailsOnPage(Object.RunningTime);
	
EndProcedure

&AtServer
Procedure FillInAdditionalDetailsOnPage(Val FillingData, Val Rows = Undefined)
	
	Query = New Query(
		"SELECT
		|	(CAST(FillingData.LineNumber AS NUMBER)) - 1 AS RowIndex,
		|	FillingData.Asset AS Asset
		|INTO FillingData
		|FROM
		|	&FillingData AS FillingData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FillingData.RowIndex,
		|	ISNULL(Nodes.Ref, UNDEFINED) AS FormNode,
		|	ISNULL(
		|	Objects.Ref
		|	, Nodes.Owner)
		|		AS FormObject
		|FROM
		|	FillingData AS FillingData
		|		LEFT JOIN Catalog.Assets AS Objects
		|		ON FillingData.Asset = Objects.Ref
		|		LEFT JOIN Catalog.SubAssets AS Nodes
		|		ON FillingData.Asset = Nodes.Ref AND (&UseNodes)
		|");
	
	Query.SetParameter("UseNodes", UseSubAssets);
	Query.SetParameter(
		"FillingData",
		FillingData.Unload(
			Rows,
			"LineNumber, Asset"));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		FillPropertyValues(Object.RunningTime[Selection.RowIndex], Selection);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure OperatingTimeProcessingSelectionOnServer(Val ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.RunningTime, "FormObject", ValueSelected);
	
	For Each RowData In AddedRows Do
		
		RowData.Asset = RowData.FormObject;
	
		If Not UseRMManagement Then
			RunningTimeOfFormObjectWhenChangingOnServer(RowData);
		EndIf;
		
	EndDo; 

EndProcedure

&AtServer
Procedure RunningTimeOfFormObjectWhenChangingOnServer(Val CurrentData = Undefined)
	
	If CurrentData = Undefined Then
		CurrentData = Object.RunningTime.FindByID(Items.RunningTime.CurrentRow);
	EndIf;
	
	CurrentData.RunningTimeValue = Catalogs.Assets.RunningTimeValue(
											CurrentData.Asset, Object.Date);
	
EndProcedure

&AtServerNoContext
Function NodeOwner(Val Node)

	Return Common.ObjectAttributeValue(Node, "Owner");
	
EndFunction

&AtServer
Procedure AddFoundObjects(Val FoundObjects)
	
	AddedRows = New Array;
	
	For Each ObjectRef In FoundObjects Do
		
		TheStructureOfTheSearch = New Structure("Asset", ObjectRef);
		StringsList = Object.RunningTime.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() <> 0 Then
			Continue
		EndIf;
	
		NewRow = Object.RunningTime.Add();
		NewRow.Asset = ObjectRef;
		
		If Not UseRMManagement Then
			RunningTimeOfFormObjectWhenChangingOnServer(NewRow);
		EndIf;
		
		AddedRows.Add(NewRow);

	EndDo;
	
	FillInAdditionalDetailsOnPage(Object.RunningTime, AddedRows);
	
EndProcedure

&AtClient
Function PickingParameters()
	FilterParameters = New Structure("Status", PredefinedValue("Enum.AssetStatuses.InOperation"));
	PickingParameters = New Structure;
	PickingParameters.Insert("Filter", FilterParameters);
	PickingParameters.Insert("RunningTimeRegistration", True);
	Return PickingParameters
EndFunction

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
