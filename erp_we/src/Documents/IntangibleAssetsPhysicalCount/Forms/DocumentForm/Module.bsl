
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
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations

	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);

	
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
	
	Notify("Write_IntangibleAssetsPhysicalCount", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	

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
	
	If EventName = "RecordDocumentBasedOnInventory" Then
		AfterRecordingDocumentCreatedOnBasisOf();
	EndIf;
	
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

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting,PostInAccounting");

	OnChangesInAccountingRecords();
	
EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting,RecordInTA");

	OnChangesInAccountingRecords();

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInManAccounting");

	OnChangesInAccountingRecords();

EndProcedure

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
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

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

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIA

&AtClient
Procedure IAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure IASelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.IA.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.IAActionPresentation Then
		
		StandardProcessing = False;
		
		NonCurrentAssetsClient.PerformActionBasedOnPhysicalInventoryCount(CurrentData, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IAIntangibleAssetOnChange(Item)
	
	RowData = Items.IA.CurrentData;
	
	If ValueIsFilled(RowData.IntangibleAsset) Then
		
		// You need to get accounting data for the selected IA
		NewAccountingData = New Map(CurCurrentAccountingData);
		
		PhysicalInventoryCountParameters = New Structure;
		PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
		PhysicalInventoryCountParameters.Insert("Department", Object.Department);
		PhysicalInventoryCountParameters.Insert("Date", Object.Date);
		PhysicalInventoryCountParameters.Insert("ListOfIA", CommonClientServer.ValueInArray(RowData.IntangibleAsset));
		PhysicalInventoryCountParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
		PhysicalInventoryCountParameters.Insert("PostInAccounting", Object.PostInAccounting);
		PhysicalInventoryCountParameters.Insert("RecordInTA", Object.RecordInTA);
		
		DataOfAccounting = DataOfAccounting(PhysicalInventoryCountParameters);
		
		If DataOfAccounting <> Undefined Then
			
			NonCurrentAssetsClientServer.FillInAccountingDataInLineOfInventoryOfIntangibleAssetPhysicalInventory(RowData, DataOfAccounting, PhysicalInventoryCountParameters);
			
			NewAccountingData.Insert(RowData.IntangibleAsset, CommonClient.CopyRecursive(DataOfAccounting));
			
		Else
			NewAccountingData.Delete(RowData.IntangibleAsset);
		EndIf; 
		
		CurCurrentAccountingData = New FixedMap(NewAccountingData);
		
		WhenChangingDataInRow(RowData, ThisObject);

	EndIf; 
	
EndProcedure

&AtClient
Procedure IAAvailabilityActualOnChange(Item)
	
	RowData = Items.IA.CurrentData;
	
	If RowData.AvailabilityActual Then
		
		If RowData.ActualCostAC = 0
			And Object.PostInAccounting Then
			RowData.ActualCostAC = RowData.CostByAccountingDataLA;
		EndIf;
		
		If RowData.ActualCostTA = 0
			And Object.RecordInTA Then
			RowData.ActualCostTA = RowData.CostByAccountingDataTA;
		EndIf;
		
		If RowData.CostActualMan = 0
			And Object.RecordInManAccounting Then
			RowData.CostActualMan = RowData.CostByAccountingDataMA;
		EndIf;
		
	Else
		
		RowData.ActualCostAC = 0;
		RowData.ActualCostTA = 0;
		RowData.CostActualMan = 0;
		
	EndIf; 
	
	WhenChangingDataInRow(RowData, ThisObject);
	
EndProcedure

&AtClient
Procedure IAActualCostACOnChange(Item)
	
	RowData = Items.IA.CurrentData;
	
	OnChangingCostInLine(RowData);
	WhenChangingDataInRow(RowData, ThisObject);
	
EndProcedure

&AtClient
Procedure IAActualCostTAOnChange(Item)
	
	RowData = Items.IA.CurrentData;
	
	OnChangingCostInLine(RowData);
	WhenChangingDataInRow(RowData, ThisObject);

EndProcedure

&AtClient
Procedure IACostActualManOnChange(Item)
	
	RowData = Items.IA.CurrentData;
	
	OnChangingCostInLine(RowData);
	WhenChangingDataInRow(RowData, ThisObject);

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

#Region FillType

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IAIntangibleAsset, ThisObject);
	
	OpenForm("Catalog.IntangibleAssets.ChoiceForm", 
					PickingParameters, Items.IA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

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
	
	If Object.IA.Count() <> 0 Then
		CallbackDescription = New CallbackDescription("FillInByBalanceCompletion", ThisObject);
		FillInTabularSection(CallbackDescription);
	Else
		FillInByBalanceCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAccountingData(Command)
	
	If Items.IA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInAccountingDataCompletion", ThisObject);
	FillInTabularSection(CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInActualData(Command)
	
	If Items.IA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInActualDataCompletion", ThisObject);
	FillInTabularSection(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectionOfIndividuals_(Command)
	
	FormParameters = New Structure("ChoiceMode, MultipleChoice, CloseOnChoice", True, False, False);
	OpenForm("Catalog.Persons.ChoiceForm", 
		FormParameters, 
		Items.PhysicalInventoryCountCommission, 
		UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region AttachableCommands

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

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

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

&AtServer
Procedure SelectionOnServer(Val ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IA, "IntangibleAsset", ValueSelected);

	If AddedRows.Count() <> 0 Then
		FillInAccountingDataOnServer(AddedRows);
	EndIf;
	
EndProcedure

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
		
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.Department) Then
		Return;
	EndIf;
	
	TimeConsumingOperation = FillByBalancesOnServer();
	
	CallbackOnCompletion = New CallbackDescription("ProcessResultOfFillingInBalances", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function FillByBalancesOnServer()

	FunctionParameters = New Structure;
	FunctionParameters.Insert("Organization", Object.Organization);
	FunctionParameters.Insert("Department", Object.Department);
	FunctionParameters.Insert("Date", Object.Date);
	FunctionParameters.Insert("Organization", Object.Organization);
	FunctionParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FunctionParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FunctionParameters.Insert("RecordInTA", Object.RecordInTA);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.IntangibleAssetsPhysicalCount.DataOfAccounting", FunctionParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure ProcessResultOfFillingInBalances(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ProcessResultOfFillingInBalancesAtServer(Result);
	
EndProcedure

&AtServer
Procedure ProcessResultOfFillingInBalancesAtServer(Val Result)

	Object.IA.Clear();
	
	PhysicalInventoryCountParameters = New Structure;
	PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
	PhysicalInventoryCountParameters.Insert("Department", Object.Department);

	NewAccountingData = GetFromTempStorage(Result.ResultAddress); // Map
	CurCurrentAccountingData = New FixedMap(NewAccountingData);

	For Each DataOfAccounting In NewAccountingData Do
		
		RowData = Object.IA.Add();
		FillPropertyValues(RowData, DataOfAccounting.Value);
		RowData.IntangibleAsset = DataOfAccounting.Key;
		
		NonCurrentAssetsClientServer.FillInAccountingDataInLineOfInventoryOfIntangibleAssetPhysicalInventory(
			RowData, 
			DataOfAccounting.Value,
			PhysicalInventoryCountParameters);

		WhenChangingDataInRow(RowData, ThisObject);
	
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInAccountingDataCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccountingDataEndOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccountingDataEndOnServer()

	FillInAccountingDataOnServer(Object.IA);
	
EndProcedure
 
&AtServer
Procedure FillInAccountingDataOnServer(RowsCollection)

	AccountingDataByLine = Documents.IntangibleAssetsPhysicalCount.FillInAccountingData(Object, RowsCollection, True);
	
	NewAccountingData = New Map(CurCurrentAccountingData);
	
	For Each RowData In RowsCollection Do
		
		DataOfAccounting = AccountingDataByLine.Get(RowData.IntangibleAsset);
		
		If DataOfAccounting <> Undefined Then
			NewAccountingData.Insert(RowData.IntangibleAsset, Common.CopyRecursive(DataOfAccounting));
		Else
			NewAccountingData.Delete(RowData.IntangibleAsset);
		EndIf; 

		WhenChangingDataInRow(RowData, ThisObject, DataOfAccounting);
		
	EndDo; 

	CurCurrentAccountingData = New FixedMap(NewAccountingData);
	
EndProcedure

&AtClient
Procedure FillInActualDataCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInActualDataOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInActualDataOnServer()

	For Each RowID In Items.IA.SelectedRows Do
		
		RowData = Object.IA.FindByID(RowID);
		RowData.AvailabilityActual = RowData.AvailabilityByAccountingData;
		RowData.ActualCostAC = RowData.CostByAccountingDataLA;
		RowData.ActualCostTA = RowData.CostByAccountingDataTA;
		RowData.CostActualMan = RowData.CostByAccountingDataMA;
		
		WhenChangingDataInRow(RowData, ThisObject);
		
	EndDo; 

EndProcedure
 
#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region IAActionPresentation_TextColor
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IAActionPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IA.ActionPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	ConfigureDependentFormElementsOnServer();

	ListOfIA = Object.IA.Unload(, "IntangibleAsset").UnloadColumn("IntangibleAsset");

	PhysicalInventoryCountParameters = New Structure;
	PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
	PhysicalInventoryCountParameters.Insert("Department", Object.Department);
	PhysicalInventoryCountParameters.Insert("Date", Object.Date);
	PhysicalInventoryCountParameters.Insert("ListOfIA", ListOfIA);
	PhysicalInventoryCountParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	PhysicalInventoryCountParameters.Insert("PostInAccounting", Object.PostInAccounting);
	PhysicalInventoryCountParameters.Insert("RecordInTA", Object.RecordInTA);

	AccountingDataByLine = Documents.IntangibleAssetsPhysicalCount.DataOfAccounting(PhysicalInventoryCountParameters);
								
	CurCurrentAccountingData = New FixedMap(AccountingDataByLine);
	
	FindDocumentsBasedOn();
	
	FillInServiceDetailsOfTS();

EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()

	For Each RowData In Object.IA Do
		
		FillInDocumentBasedOnLine(RowData, DocumentsBasedOn);
		NonCurrentAssetsClientServer.FillInPresentationOfAction(RowData, ThisObject);
	
	EndDo; 

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails = "")

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentDetailsOf_NMAIntangibleSAssetPhysicalInventory(
									Object, ChangedBankingDetails);
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If UpdateAll Then
			
		CurrencyOfManPresentation = FormServiceParameters.CurrencyOfManPresentation;
		
		Items.BottomLineCostIsActualMA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTQT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'MA';
																|pl = 'MA';
																|tr = 'YM'"), CurrencyOfManPresentation);
			
		Items.BottomLineCostAccordingToMAAccountingData.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'QT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità gestionale';
																|pl = 'Ewidencja zarządcza';
																|tr = 'Yönetim Muhasebesi'"), CurrencyOfManPresentation);
			
		Items.IACostActualMan.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTQT)';
																|ru = 'Стоимость (УУ)';
																|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
																|it = 'Costo contabilità gestionale';
																|pl = 'Wartość (EZ)';
																|tr = 'Maliyet (YM)'"), CurrencyOfManPresentation);
			
		Items.IACostByAccountingDataMA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTQT)';
																|ru = 'Стоимость (УУ)';
																|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
																|it = 'Costo contabilità gestionale';
																|pl = 'Wartość (EZ)';
																|tr = 'Maliyet (YM)'"), CurrencyOfManPresentation);
			
	EndIf;
		
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		ComplCurrencyPresentation = FormServiceParameters.ComplCurrencyPresentation;
		
		Items.BottomLineCostIsActualAC.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
			
		Items.BottomLineActualCostIsTA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTTh';
																|ru = 'НУ';
																|en = 'TA'; fa = 'مالیاتی';
																|it = 'Contabilità fiscale';
																|pl = 'EP';
																|tr = 'Vergi muhasebesi'"), ComplCurrencyPresentation);
			
		Items.ResultIsCostAccordingToACAccountingData.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'Ewidencja księgowa';
																|tr = 'GM'"), ComplCurrencyPresentation);
			
		Items.BottomLineCostAccordingToAccountingDataIsTA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTTh';
																|ru = 'НУ';
																|en = 'TA'; fa = 'مالیاتی';
																|it = 'Contabilità fiscale';
																|pl = 'EP';
																|tr = 'Vergi muhasebesi'"), ComplCurrencyPresentation);
			
		Items.IAActualCostAC.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTDN)';
																|ru = 'Стоимость (БУ)';
																|en = 'Cost (LA)'; fa = 'بها (محلی)';
																|it = 'Costo (contabilità)';
																|pl = 'Wartość (EK)';
																|tr = 'Maliyet (LA)'"), ComplCurrencyPresentation);
			
		Items.IACostByAccountingDataLA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTDN)';
																|ru = 'Стоимость (БУ)';
																|en = 'Cost (LA)'; fa = 'بها (محلی)';
																|it = 'Costo (contabilità)';
																|pl = 'Wartość (EK)';
																|tr = 'Maliyet (LA)'"), ComplCurrencyPresentation);
			
		Items.IAActualCostTA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTTh)';
																|ru = 'Стоимость (НУ)';
																|en = 'Cost (TA)'; fa = 'بها (مالیاتی)';
																|it = 'Costo (contabilità fiscale)';
																|pl = 'Wartość (EP)';
																|tr = 'Maliyet (VM)'"), ComplCurrencyPresentation);
			
		Items.IACostByAccountingDataTA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTTh)';
																|ru = 'Стоимость (НУ)';
																|en = 'Cost (TA)'; fa = 'بها (مالیاتی)';
																|it = 'Costo (contabilità fiscale)';
																|pl = 'Wartość (EP)';
																|tr = 'Maliyet (VM)'"), ComplCurrencyPresentation);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrencyOfMan",
			Constants.ManagementAccountingCurrency.Get(),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrencyOfManPresentation",
			String(FormServiceParameters.CurrencyOfMan),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(FormServiceParameters.ComplCurrency),
			FormServiceParameters);
			
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FindDocumentsBasedOn()

	QueryText = 
	"SELECT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Recognition) AS Action,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.IntangibleAsset AS IntangibleAsset
	|FROM
	|	Document.IntangibleAssetsInitialRecognition2_4 AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND DocumentData.GeneratedDocument
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Move),
	|	DocumentData.Ref,
	|	TabularSection.IntangibleAsset
	|FROM
	|	Document.IATransfer2_4 AS DocumentData
	|		INNER JOIN Document.IATransfer2_4.IA AS TabularSection
	|		ON (TabularSection.Ref = DocumentData.Ref)
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND DocumentData.GeneratedDocument
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff),
	|	DocumentData.Ref,
	|	TabularSection.IntangibleAsset
	|FROM
	|	Document.DisposeIntangibleAssets2_4 AS DocumentData
	|		INNER JOIN Document.DisposeIntangibleAssets2_4.IA AS TabularSection
	|		ON (TabularSection.Ref = DocumentData.Ref)
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND DocumentData.GeneratedDocument
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation),
	|	DocumentData.Ref,
	|	TabularSection.IntangibleAsset
	|FROM
	|	Document.IARevaluation2_4 AS DocumentData
	|		INNER JOIN Document.IARevaluation2_4.IA AS TabularSection
	|		ON (TabularSection.Ref = DocumentData.Ref)
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.DocumentBasis = &DocumentBasis
	|	AND DocumentData.GeneratedDocument";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", Object.Ref);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	DocumentCorrespondence = New Map;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocumentsList = DocumentCorrespondence.Get(Selection.IntangibleAsset);
		
		If DocumentsList = Undefined Then
			DocumentsList = New Structure;
			DocumentsList.Insert("Recognition", Undefined);
			DocumentsList.Insert("Move", Undefined);
			DocumentsList.Insert("WriteOff", Undefined);
			DocumentsList.Insert("Revaluation", Undefined);
		EndIf;
		
		If Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.Recognition Then
			DocumentsList.Recognition = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.Move Then
			DocumentsList.Move = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.WriteOff Then
			DocumentsList.WriteOff = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.Revaluation Then
			DocumentsList.Revaluation = Selection.Ref;
		EndIf; 
		
		DocumentCorrespondence.Insert(Selection.IntangibleAsset, DocumentsList);
	
	EndDo;
	
	DocumentsBasedOn = New FixedMap(DocumentCorrespondence);

EndProcedure

&AtClient
Procedure OnChangingCostInLine(RowData)
	
	If Not RowData.AvailabilityActual
		And (RowData.ActualCostAC <> 0
				And Object.PostInAccounting 
			Or RowData.ActualCostTA <> 0
				And Object.RecordInTA
			Or RowData.CostActualMan <> 0
				And Object.RecordInManAccounting) Then
		
		RowData.AvailabilityActual = True;
		
	ElsIf RowData.AvailabilityActual
		And (RowData.ActualCostAC = 0
			Or Not Object.PostInAccounting) 
		And (RowData.ActualCostTA = 0
			Or Not Object.RecordInTA)
		And (RowData.CostActualMan = 0
			Or Not Object.RecordInManAccounting) Then
		
		RowData.AvailabilityActual = False;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenChangingDataInRow(RowData, Form, DataOfAccounting = Undefined)

	Object = Form.Object;

	If DataOfAccounting = Undefined Then
		DataOfAccounting = Form.CurCurrentAccountingData.Get(RowData.IntangibleAsset);
	EndIf;
	
	NonCurrentAssetsClientServer.FillInActionBasedOnIntangibleAssetPhysicalInventory(RowData, Object, DataOfAccounting);
		
	NonCurrentAssetsClientServer.FillInPresentationOfAction(RowData, Form);
	
EndProcedure
 
&AtServerNoContext
Function DataOfAccounting(Val PhysicalInventoryCountParameters)

	AccountingDataByLine = Documents.IntangibleAssetsPhysicalCount.DataOfAccounting(PhysicalInventoryCountParameters);
	
	Return AccountingDataByLine.Get(PhysicalInventoryCountParameters.ListOfIA[0]);
	
EndFunction

&AtServer
Procedure AfterRecordingDocumentCreatedOnBasisOf()

	FindDocumentsBasedOn();
	FillInServiceDetailsOfTS();

EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInAccountingDataOnServer(Object.IA);
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()

	FillInAccountingDataOnServer(Object.IA);

EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	FillInAccountingDataOnServer(Object.IA);

EndProcedure

&AtClient
Procedure OnChangesInAccountingRecords()
	
	For Each RowData In Object.IA Do
		WhenChangingDataInRow(RowData, ThisObject);
	EndDo; 
	
EndProcedure

&AtClient
Procedure PerformActionBasedOnPhysicalInventoryCountCompletion(Result, AdditionalParameters) Export

	If Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
		
		NameOfFormToOpen_ = "Document.IntangibleAssetsInitialRecognition2_4.ObjectForm";
			
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
		
		NameOfFormToOpen_ = "Document.IATransfer2_4.ObjectForm";
			
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		
		NameOfFormToOpen_ = "Document.DisposeIntangibleAssets2_4.ObjectForm";
			
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation") Then
		
		NameOfFormToOpen_ = "Document.IARevaluation2_4.ObjectForm";
		
	EndIf; 
	
	OpenForm(NameOfFormToOpen_, Result.FormParameters, ThisObject, ThisObject);

EndProcedure

&AtClientAtServerNoContext
Procedure FillInDocumentBasedOnLine(RowData, DocumentsBasedOn)
	
	RowData.DocumentBasedOnAC = Undefined;
	RowData.DocumentBasedOnTA = Undefined;
	RowData.DocumentBasedOnMA = Undefined;
	
	DocumentsList = DocumentsBasedOn.Get(RowData.IntangibleAsset);
	
	If DocumentsList = Undefined Then
		Return;
	EndIf;
	
	// ACC
	If RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
		
		RowData.DocumentBasedOnAC = DocumentsList.Recognition;
	
	ElsIf RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
		
		RowData.DocumentBasedOnAC = DocumentsList.Move;
	
	ElsIf RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation") Then
		
		RowData.DocumentBasedOnAC = DocumentsList.Revaluation;
	
	ElsIf RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		
		RowData.DocumentBasedOnAC = DocumentsList.WriteOff;
	
	EndIf; 
	
	// TA
	If RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.Recognition;
	
	ElsIf RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.Move;
	
	ElsIf RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.WriteOff;
	
	EndIf; 
	
	// MA
	If RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
		
		RowData.DocumentBasedOnMA = DocumentsList.Recognition;
	
	ElsIf RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
		
		RowData.DocumentBasedOnMA = DocumentsList.Move;
	
	ElsIf RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation") Then
		
		RowData.DocumentBasedOnMA = DocumentsList.Revaluation;
	
	ElsIf RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		
		RowData.DocumentBasedOnMA = DocumentsList.WriteOff;
	
	EndIf; 
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

#EndRegion

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
