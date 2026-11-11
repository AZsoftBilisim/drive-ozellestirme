
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
	
	DocumentCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
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

	#EndRegion
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	

	SaveDetailsValuesBeforeChanging(ThisObject);
	
	FillInServiceDetailsOfTS();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_FixedAssetsPhysicalCount", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "RecordDocumentBasedOnInventory"
		Or EventName = "Write_LeaseTermination" Then
		AfterRecordingDocumentCreatedOnBasisOf();
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations


EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
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
Procedure FinanciallyLiablePersonOnChange(Item)
	
	THEYSAYOnChangeATServer()
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	If Object.BusinessOperation = AttributesValuesBeforeChange.BusinessOperation Then
		Return;
	EndIf;
	
	If (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress")
			Or AttributesValuesBeforeChange.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress"))
		And FormServiceParameters.VNAManagementIsUsed_2_4
		And Object.FA.Count() <> 0 Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.OK, NStr("vi = 'Xóa và tiếp tục';
													|ru = 'Очистить и продолжить';
													|en = 'Clear and continue'; fa = 'Clear and continue';
													|it = 'Cancellare e continuare';
													|pl = 'Oczyść i kontynuuj';
													|tr = 'Temizle ve devam et'"));
		ButtonsList.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отменить';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Cancel';
														|pl = 'Cancel';
														|tr = 'İptal et'"));
		
		ShowQueryBox(
			New CallbackDescription("BusinessOperationOnChangeCompletion", ThisObject, True),
			NStr("vi = 'Khi thay đổi giao dịch, phần bảng của chứng từ sẽ bị xóa';
				|ru = 'При изменении операции табличная часть документа будет очищена';
				|en = 'The tabular section of the document will be cleared after changing a procedure'; fa = 'The tabular section of the document will be cleared after changing a procedure';
				|it = 'The tabular section of the document will be cleared after changing a procedure';
				|pl = 'The tabular section of the document will be cleared after changing a procedure';
				|tr = 'İşlem değiştirildiğinde belgenin tablo bölümü temizlenecektir'"),
			ButtonsList);
	Else
		BusinessOperationOnChangeCompletion(DialogReturnCode.OK, Undefined);
	EndIf; 
	
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

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FASelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.FAActionPresentation Then
		
		StandardProcessing = False;
		
		NonCurrentAssetsClient.PerformActionBasedOnPhysicalInventoryCount(CurrentData, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure FAAccountingObjectOnChange(Item)
	
	RowData = Items.FA.CurrentData;
	
	If ValueIsFilled(RowData.AccountingObject) Then
		
		OperationParametersList = New Structure;
		OperationParametersList.Insert("Organization", Object.Organization);
		OperationParametersList.Insert("Department", Object.Department);
		OperationParametersList.Insert("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
		OperationParametersList.Insert("Date", Object.Date);
		OperationParametersList.Insert("BusinessOperation", Object.BusinessOperation);
		OperationParametersList.Insert("ListOfFA", CommonClientServer.ValueInArray(RowData.AccountingObject));
		OperationParametersList.Insert("RecordInManAccounting", Object.RecordInManAccounting);
		OperationParametersList.Insert("PostInAccounting", Object.PostInAccounting);
		OperationParametersList.Insert("RecordInTA", Object.RecordInTA);
		
		DataOfAccounting = DataOfAccounting(OperationParametersList);
		
		If DataOfAccounting <> Undefined Then
			
			PhysicalInventoryCountParameters = New Structure;
			PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
			PhysicalInventoryCountParameters.Insert("Department", Object.Department);
			PhysicalInventoryCountParameters.Insert("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);

			NonCurrentAssetsClientServer.FillInAccountingDataInLineOfPhysicalInventoryCountOfFA(
				RowData, 
				DataOfAccounting,
				PhysicalInventoryCountParameters,
				False,
				True,
				FormServiceParameters.VNAManagementIsUsed_2_4);
	
		EndIf; 
		
	EndIf; 
	
	WhenChangingDataInRow(RowData, ThisObject);
	
EndProcedure

&AtClient
Procedure FAFinanciallyLiablePersonOnChange(Item)
	
	OSMOLOnChangeATServer();

EndProcedure

&AtClient
Procedure FAAvailabilityActualOnChange(Item)
	
	OnChangeActualAvailability(Items.FA.CurrentData, ThisObject);
	
EndProcedure

&AtClient
Procedure FAActualCostACOnChange(Item)
	
	RowData = Items.FA.CurrentData;
	
	OnChangingCostInLine(RowData);
	WhenChangingDataInRow(RowData, ThisObject);
	
EndProcedure

&AtClient
Procedure FAActualCostTAOnChange(Item)
	
	RowData = Items.FA.CurrentData;
	
	OnChangingCostInLine(RowData);
	WhenChangingDataInRow(RowData, ThisObject);
	
EndProcedure

&AtClient
Procedure FACostActualManOnChange(Item)
	
	RowData = Items.FA.CurrentData;

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
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAAccountingObject, ThisObject);
	
	ChoiceFormName = 
		?(Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress")
			And FormServiceParameters.VNAManagementIsUsed_2_4, 
				"Catalog.ConstructionObjects.ChoiceForm",
				"Catalog.Assets.ChoiceForm");
			
	OpenForm(ChoiceFormName, PickingParameters, Items.FA,,,,, FormWindowOpeningMode.LockOwnerWindow)
	
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

&AtClient
Procedure FillInByBalance(Command)
	
	Cancel = False;
	If Not ValueIsFilled(Object.BusinessOperation) Then
		MessageText = NStr("vi = 'Cần điền nghiệp vụ';
							|ru = 'Необходимо заполнить операцию';
							|en = 'Fill in the procedure'; fa = 'Fill in the procedure';
							|it = 'Fill in the procedure';
							|pl = 'Fill in the procedure';
							|tr = 'İşlemin doldurulması gerekir'");
		CommonClient.MessageToUser(MessageText, , "BusinessOperation", "Object", Cancel); 
	EndIf; 
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
	
	If Object.FA.Count() <> 0 Then
		CallbackDescription = New CallbackDescription("FillInByBalanceCompletion", ThisObject);
		FillInTabularSection(CallbackDescription, False);
	Else
		FillInByBalanceCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAccountingData(Command)
	
	If Items.FA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInAccountingDataCompletion", ThisObject);
	FillInTabularSection(CallbackDescription, True);
	
EndProcedure

&AtClient
Procedure FillInActualData(Command)
	
	If Items.FA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInActualDataCompletion", ThisObject);
	FillInTabularSection(CallbackDescription, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region StandardSubsystems

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

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
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

&AtServer
Procedure SelectionOnServer(Val ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "AccountingObject", ValueSelected);

	If AddedRows.Count() <> 0 Then
		FillInAccountingDataOnServer(AddedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTabularSection(CallbackDescription, OnlySelectedLines)

	QueryText = Undefined;
	If OnlySelectedLines Then
		If Items.FA.SelectedRows.Count() <> 0 Then
			QueryText = NStr(
				"vi = 'Khi điền, dữ liệu hiện có trong các dòng được chọn sẽ bị ghi đè.
				|Tiếp tục?';
				|ru = 'При заполнении существующие данные в выбранных строках будут перезаполнены.
				|Продолжить?';
				|en = 'The existing data will be repopulated in selected lines during population.
				|Continue?'; fa = 'The existing data will be repopulated in selected lines during population.
				|Continue?';
				|it = 'The existing data will be repopulated in selected lines during population.
				|Continue?';
				|pl = 'The existing data will be repopulated in selected lines during population.
				|Continue?';
				|tr = 'Doldurma sırasında seçilen satırlardaki mevcut veriler yeniden doldurulacaktır. 
				| Devam edilsin mi?'");
		EndIf; 
	ElsIf Object.FA.Count() <> 0 Then
		QueryText = NStr(
			"vi = 'Khi điền, dữ liệu hiện tại sẽ được điền lại.
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
	EndIf; 
	
	If QueryText <> Undefined Then
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continue';
													|pl = 'Continue';
													|tr = 'Devam et'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
	
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		RunCallback(CallbackDescription, DialogReturnCode.Yes);
	EndIf;

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
	FunctionParameters.Insert("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
	FunctionParameters.Insert("Date", Object.Date);
	FunctionParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FunctionParameters.Insert("Organization", Object.Organization);
	FunctionParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FunctionParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FunctionParameters.Insert("RecordInTA", Object.RecordInTA);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.FixedAssetsPhysicalCount.DataOfAccounting", FunctionParameters);
	
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

	Object.FA.Clear();
	
	PhysicalInventoryCountParameters = New Structure;
	PhysicalInventoryCountParameters.Insert("Organization", Object.Organization);
	PhysicalInventoryCountParameters.Insert("Department", Object.Department);
	PhysicalInventoryCountParameters.Insert("FINANCIALLYLIABLEPERSON", Object.FinanciallyLiablePerson);
		
	CurCurrentAccountingData = GetFromTempStorage(Result.ResultAddress);
	
	For Each DataOfAccounting In CurCurrentAccountingData Do
	
		RowData = Object.FA.Add();
		FillPropertyValues(RowData, DataOfAccounting);
		
		NonCurrentAssetsClientServer.FillInAccountingDataInLineOfPhysicalInventoryCountOfFA(
			RowData, 
			DataOfAccounting,
			PhysicalInventoryCountParameters,
			False,
			True,
			FormServiceParameters.VNAManagementIsUsed_2_4);
			
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

	FillInAccountingDataOnServer(Object.FA);
	
EndProcedure
 
&AtServer
Procedure FillInAccountingDataOnServer(RowsCollection)

	Documents.FixedAssetsPhysicalCount.FillInAccountingData(Object, RowsCollection, False, True);
	
	For Each RowData In Object.FA Do
		WhenChangingDataInRow(RowData, ThisObject);
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

	For Each RowID In Items.FA.SelectedRows Do
		
		RowData = Object.FA.FindByID(RowID);
		RowData.AvailabilityActual = RowData.AvailabilityByAccountingData;
		RowData.ActualCostAC = RowData.CostByAccountingDataLA;
		RowData.ActualCostTA = RowData.CostByAccountingDataTA;
		RowData.CostActualMan = RowData.CostByAccountingDataMA;
		
		WhenChangingDataInRow(RowData, ThisObject);
		
	EndDo; 

EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtClient
Procedure BusinessOperationOnChangeCompletion(Result, ClearTS) Export

	If Result <> DialogReturnCode.OK Then
		Object.BusinessOperation = AttributesValuesBeforeChange.BusinessOperation;
		Return;
	EndIf;
	
	If ClearTS = True Then
		Object.FA.Clear();
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "BusinessOperation");

	For Each RowData In Object.FA Do
		WhenChangingDataInRow(RowData, ThisObject);
	EndDo; 

	SaveDetailsValuesBeforeChanging(ThisObject);
	
EndProcedure
 
&AtServer
Procedure DateOfChangeOnServer()

	If Object.BusinessOperation = Enums.BusinessTransactions.PhysicalCountOfConstructionInProgress 
		And (Not FormServiceParameters.VNAManagementIsUsed_2_4
			Or Not FormServiceParameters.UseConstructionObjects) Then
		
		Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsPhysicalCount;
		Object.FA.Clear();
	EndIf;
	
	If Not FormServiceParameters.VNAManagementIsUsed_2_4
		And (Object.RecordInManAccounting
			Or Object.RecordInTA) Then
		
		Object.PostInAccounting = True;
		Object.RecordInManAccounting = False;
		Object.RecordInTA = False;
	EndIf;

	FillInAccountingDataOnServer(Object.FA);
	
	ConfigureDependentFormElementsOnServer("Date,BusinessOperation,RecordInManAccounting,PostInAccounting,RecordInTA");
	
	SaveDetailsValuesBeforeChanging(ThisObject);
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInAccountingDataOnServer(Object.FA);
	
	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()

	FillInAccountingDataOnServer(Object.FA);

EndProcedure

&AtClient
Procedure OnChangesInAccountingRecords()
	
	For Each RowData In Object.FA Do
		WhenChangingDataInRow(RowData, ThisObject);
	EndDo; 
	
EndProcedure

&AtServer
Procedure THEYSAYOnChangeATServer()

	FillInAccountingDataOnServer(Object.FA);
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "FINANCIALLYLIABLEPERSON");
	
EndProcedure

&AtServer
Procedure OSMOLOnChangeATServer()

	CurrentRow = Items.FA.CurrentRow;
	RowData = Object.FA.FindByID(CurrentRow);
	FillInAccountingDataOnServer(CommonClientServer.ValueInArray(RowData));

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
Procedure WhenChangingDataInRow(RowData, Form)

	Object = Form.Object;
	
	NonCurrentAssetsClientServer.FillInActionBasedOnFixedAssetPhysicalInventory(
		RowData, 
		Object,
		Form.FormServiceParameters.VNAManagementIsUsed_2_4);
		
	FillInDocumentBasedOnLine(RowData, Form.DocumentsBasedOn);
	
	NonCurrentAssetsClientServer.FillInPresentationOfAction(RowData, Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SaveDetailsValuesBeforeChanging(Form)

	NewPropsValuesBeforeChanges = New Structure("BusinessOperation,Date");
	FillPropertyValues(NewPropsValuesBeforeChanges, Form.Object);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(NewPropsValuesBeforeChanges);

EndProcedure

#EndRegion

#Region GenerateFrom

&AtServer
Procedure FindDocumentsBasedOn()

	If FormServiceParameters.VNAManagementIsUsed_2_4 Then
		
		QueryText = 
		"SELECT
		|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.Recognition) AS Action,
		|	DocumentData.Ref AS Ref,
		|	TabularSection.FixedAsset AS AccountingObject
		|FROM
		|	Document.FixedAssetsInitialRecognition2_4 AS DocumentData
		|
		|		INNER JOIN Document.FixedAssetsInitialRecognition2_4.FA AS TabularSection
		|		ON (TabularSection.Ref = DocumentData.Ref)
		|
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
		|	TabularSection.FixedAsset
		|FROM
		|	Document.FATransfer2_4 AS DocumentData
		|
		|		INNER JOIN Document.FATransfer2_4.FA AS TabularSection
		|		ON (TabularSection.Ref = DocumentData.Ref)
		|
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
		|	TabularSection.FixedAsset
		|FROM
		|	Document.FARevaluation2_4 AS DocumentData
		|
		|		INNER JOIN Document.FARevaluation2_4.FA AS TabularSection
		|		ON (TabularSection.Ref = DocumentData.Ref)
		|
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
		|	TabularSection.FixedAsset
		|FROM
		|	Document.DisposeFixedAssets2_4 AS DocumentData
		|
		|		INNER JOIN Document.DisposeFixedAssets2_4.FA AS TabularSection
		|		ON (TabularSection.Ref = DocumentData.Ref)
		|
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.DocumentBasis = &DocumentBasis
		|	AND DocumentData.GeneratedDocument
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets),
		|	DocumentData.Ref,
		|	TabularSection.FixedAsset
		|FROM
		|	Document.ReturnLeasedAssets AS DocumentData
		|
		|		INNER JOIN Document.ReturnLeasedAssets.FA AS TabularSection
		|		ON (TabularSection.Ref = DocumentData.Ref)
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.DocumentBasis = &DocumentBasis
		|	AND DocumentData.GeneratedDocument
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination),
		|	DocumentData.Ref,
		|	TabularSection.FixedAsset
		|FROM
		|	Document.LeaseTermination AS DocumentData
		|
		|		INNER JOIN Document.LeaseTermination.FA AS TabularSection
		|		ON (TabularSection.Ref = DocumentData.Ref)
		|WHERE
		|	DocumentData.Posted
		|	AND DocumentData.DocumentBasis = &DocumentBasis
		|";
		
	Else
		
		
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", Object.Ref);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);

	DocumentCorrespondence = New Map;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		DocumentsList = DocumentCorrespondence.Get(Selection.AccountingObject);
		
		If DocumentsList = Undefined Then
			DocumentsList = New Structure;
			DocumentsList.Insert("Recognition", Undefined);
			DocumentsList.Insert("Move", Undefined);
			DocumentsList.Insert("Revaluation", Undefined);
			DocumentsList.Insert("WriteOff", Undefined);
			DocumentsList.Insert("ReturnLeasedAssets", Undefined);
			DocumentsList.Insert("LeaseTermination", Undefined);
		EndIf;
		
		If Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.Recognition Then
			DocumentsList.Recognition = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.Move Then
			DocumentsList.Move = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.WriteOff Then
			DocumentsList.WriteOff = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets Then
			DocumentsList.ReturnLeasedAssets = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.Revaluation Then
			DocumentsList.Revaluation = Selection.Ref;
		ElsIf Selection.Action = Enums.ActionsBasedOnPhysicalInventoryCount.LeaseTermination Then
			DocumentsList.LeaseTermination = Selection.Ref;
		EndIf; 
		
		DocumentCorrespondence.Insert(Selection.AccountingObject, DocumentsList);
	
	EndDo;
	
	DocumentsBasedOn = New FixedMap(DocumentCorrespondence);

EndProcedure

&AtServer
Procedure AfterRecordingDocumentCreatedOnBasisOf()

	FindDocumentsBasedOn();
	FillInServiceDetailsOfTS();

EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PhysicalCountOfConstructionInProgress
		And FormServiceParameters.VNAManagementIsUsed_2_4 Then		
		Return; // Construction sites do not support barcodes.
	EndIf;
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAAccountingObject, ThisObject);
	ObjectsArray = NonCurrentAssets.FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters);
	
	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "AccountingObject", ObjectsArray);
	
	If AddedRows.Count() = 0 Then
		Return;
	EndIf;
	
	FillInAccountingDataOnServer(AddedRows);
	
	For Each RowData In AddedRows Do
		RowData.AvailabilityActual = True;
		OnChangeActualAvailability(RowData, ThisObject);
	EndDo; 
	
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

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
			
	#Region FAActionPresentation_TextColor
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FAActionPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FA.ActionPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	#EndRegion
			
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ConfigureDependentFormElementsOnServer();
	
	SaveDetailsValuesBeforeChanging(ThisObject);
	
	FindDocumentsBasedOn();
	
	FillInServiceDetailsOfTS();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()
	
	Documents.FixedAssetsPhysicalCount.FillInAccountingData(Object, Object.FA, True, True);
	
	For Each RowData In Object.FA Do
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
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentAttributes_FixedAssetPhysicalInventory(
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
			
		Items.FACostActualMan.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTQT)';
																|ru = 'Стоимость (УУ)';
																|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
																|it = 'Costo contabilità gestionale';
																|pl = 'Wartość (EZ)';
																|tr = 'Maliyet (YM)'"), CurrencyOfManPresentation);
			
		Items.FACostByAccountingDataMA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTQT)';
																|ru = 'Стоимость (УУ)';
																|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
																|it = 'Costo contabilità gestionale';
																|pl = 'Wartość (EZ)';
																|tr = 'Maliyet (YM)'"), CurrencyOfManPresentation);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssetsClientServer.SetVisibilityOfSelectionListValue(
			Items.BusinessOperation.ChoiceList,
			FormServiceParameters.VNAManagementIsUsed_2_4 And FormServiceParameters.UseConstructionObjects,
			PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress"));
			
		Items.RecordInManAccounting.ReadOnly = Not FormServiceParameters.VNAManagementIsUsed_2_4;
		Items.RecordInTA.ReadOnly = Not FormServiceParameters.VNAManagementIsUsed_2_4;
		
	EndIf;
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		ThisIsPHYSICALInventoryCountOfConstruction = 
			Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress");
		
		Items.FAAccountingObject.TypeRestriction = 
			?(ThisIsPHYSICALInventoryCountOfConstruction And FormServiceParameters.VNAManagementIsUsed_2_4, 
				New TypeDescription("CatalogRef.ConstructionObjects"),
				New TypeDescription("CatalogRef.Assets"));
		
		Items.FAAssetID.Visible = Not ThisIsPHYSICALInventoryCountOfConstruction Or Not FormServiceParameters.VNAManagementIsUsed_2_4;
		Items.FACode.Visible = Not ThisIsPHYSICALInventoryCountOfConstruction Or Not FormServiceParameters.VNAManagementIsUsed_2_4;
		
		Items.FAAccountingObject.Title = 
			?(ThisIsPHYSICALInventoryCountOfConstruction, NStr("vi = 'Đối tượng xây dựng cơ bản';
																|ru = 'Объект строительства';
																|en = 'Assets under construction'; fa = 'دارایی‌های در جریان ساخت';
																|it = 'Oggetto di costruzione';
																|pl = 'Obiekt budownictwa';
																|tr = 'İnşaat nesnesi'"), NStr("vi = 'Tài sản cố định hữu hình';
																										|ru = 'Основное средство';
																										|en = 'Fixed asset'; fa = 'دارایی ثابت';
																										|it = 'Capitale fisso';
																										|pl = 'Środek trwały';
																										|tr = 'Sabit kıymetler'"));
			
		Items.FixedAssetsPage.Title = 
			?(ThisIsPHYSICALInventoryCountOfConstruction, NStr("vi = 'Đối tượng xây dựng cơ bản';
																|ru = 'Объекты строительства';
																|en = 'Assets under construction'; fa = 'دارایی‌های در جریان ساخت';
																|it = 'Oggetti di costruzione';
																|pl = 'Obiekty budowy';
																|tr = 'Yapım aşamasındaki varlıklar'"), NStr("vi = 'Tài sản cố định';
																										|ru = 'Основные средства';
																										|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
																										|it = 'Capitali fissi';
																										|pl = 'Środki trwałe';
																										|tr = 'Sabit kıymetler'"));
		
		FASelectionOptions = New Array;
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfCIPAssets")
			Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PhysicalCountOfConstructionInProgress") Then
			
			Items.GroupResultsCostAccordingToAccountingData.Title = NStr("vi = 'Chi phí theo dữ liệu kế toán';
																		|ru = 'Затраты по данным учета';
																		|en = 'Costs by accounting data'; fa = 'Costs by accounting data';
																		|it = 'Costs by accounting data';
																		|pl = 'Costs by accounting data';
																		|tr = 'Muhasebe verilerine göre giderler'");
			Items.GroupResultsCostActual.Title = NStr("vi = 'Chi phí thực tế';
														|ru = 'Затраты фактические';
														|en = 'Actual expenses'; fa = 'Actual expenses';
														|it = 'Actual expenses';
														|pl = 'Actual expenses';
														|tr = 'gerçek giderler'");
			Items.FAGroupBasedOnAccountingData.ToolTip = NStr("vi = 'Chi phí theo dữ liệu kế toán';
																|ru = 'Затраты по данным учета';
																|en = 'Costs by accounting data'; fa = 'Costs by accounting data';
																|it = 'Costs by accounting data';
																|pl = 'Costs by accounting data';
																|tr = 'Muhasebe verilerine göre giderler'");
			Items.FAGroupActual.ToolTip = NStr("vi = 'Chi phí thực tế';
												|ru = 'Затраты фактические';
												|en = 'Actual expenses'; fa = 'Actual expenses';
												|it = 'Actual expenses';
												|pl = 'Actual expenses';
												|tr = 'Gerçek giderler'");
		
		Else
			
			Items.GroupResultsCostAccordingToAccountingData.Title = NStr("vi = 'Giá trị theo dữ liệu kế toán';
																		|ru = 'Стоимость по данным учета';
																		|en = 'Cost by accounting data'; fa = 'بهای تمام‌شده بر اساس داده‌های حسابداری';
																		|it = 'Стоимость по данным учета';
																		|pl = 'Cost by accounting data';
																		|tr = 'Muhasebe verilerine göre maliyet'");
			Items.GroupResultsCostActual.Title = NStr("vi = 'Giá trị thực tế';
														|ru = 'Стоимость фактическая';
														|en = 'Actual cost'; fa = 'بهای تمام‌شده واقعی';
														|it = 'Actual cost';
														|pl = 'Actual cost';
														|tr = 'Maaliyet gerçek'");
			Items.FAGroupBasedOnAccountingData.ToolTip = NStr("vi = 'Theo dữ liệu kế toán';
																|ru = 'По данным учета';
																|en = 'By accounting data'; fa = 'بر اساس داده‌های حسابداری';
																|it = 'By accounting data';
																|pl = 'By accounting data';
																|tr = 'Muhasebe verilerine göre'");
			Items.FAGroupActual.ToolTip = NStr("vi = 'Tồn kho thực tế';
												|ru = 'Фактическое наличие';
												|en = 'Actual availability'; fa = 'موجود بودن واقعی';
												|it = 'Actual availability';
												|pl = 'Actual availability';
												|tr = 'Fiili mevcudiyet'");
			
			ChoiceParameter = New ChoiceParameter("Context", "ACC,MA");
			FASelectionOptions.Add(ChoiceParameter);
			
			ArrayOfFATypes = New Array;
			ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
			ArrayOfFATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
			ChoiceParameter = New ChoiceParameter("Filter.OSType", New FixedArray(ArrayOfFATypes));
			FASelectionOptions.Add(ChoiceParameter);
			
		EndIf; 
		
		Items.FAAccountingObject.ChoiceParameters = New FixedArray(FASelectionOptions);
		
		Items.FAImportDataFromPDT.Visible = Not ThisIsPHYSICALInventoryCountOfConstruction Or Not FormServiceParameters.VNAManagementIsUsed_2_4;
		
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
			
		Items.FAActualCostAC.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTDN)';
																|ru = 'Стоимость (БУ)';
																|en = 'Cost (LA)'; fa = 'بها (محلی)';
																|it = 'Costo (contabilità)';
																|pl = 'Wartość (EK)';
																|tr = 'Maliyet (LA)'"), ComplCurrencyPresentation);
			
		Items.FACostByAccountingDataLA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTDN)';
																|ru = 'Стоимость (БУ)';
																|en = 'Cost (LA)'; fa = 'بها (محلی)';
																|it = 'Costo (contabilità)';
																|pl = 'Wartość (EK)';
																|tr = 'Maliyet (LA)'"), ComplCurrencyPresentation);
			
		Items.FAActualCostTA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTTh)';
																|ru = 'Стоимость (НУ)';
																|en = 'Cost (TA)'; fa = 'بها (مالیاتی)';
																|it = 'Costo (contabilità fiscale)';
																|pl = 'Wartość (EP)';
																|tr = 'Maliyet (VM)'"), ComplCurrencyPresentation);
			
		Items.FACostByAccountingDataTA.Title = 
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
			"UseConstructionObjects", GetFunctionalOption("UseConstructionObjects"), FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrencyOfMan",
			Constants.ManagementAccountingCurrency.Get(),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrencyOfManPresentation",
			String(FormServiceParameters.CurrencyOfMan),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date), FormServiceParameters);
		
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

&AtServerNoContext
Function DataOfAccounting(Val PhysicalInventoryCountParameters)

	AccountingDataByLine = Documents.FixedAssetsPhysicalCount.DataOfAccounting(PhysicalInventoryCountParameters);
								
	DataOfAccounting = AccountingDataByLine.Find(PhysicalInventoryCountParameters.ListOfFA[0], "AccountingObject");
	
	If DataOfAccounting = Undefined Then
		Return Undefined;
	EndIf;
	
	CurCurrentAccountingData = New Structure("OrganizationBasedOnAccountingData,AccountingDataDivision,TheySAYAccordingToAccountingData,
	|CompaniesAreInterconnected,Received_ForRent,Contract,AvailabilityByAccountingData,
	|CostByAccountingDataLA,CostByAccountingDataTA,CostByAccountingDataMA,
	|AssetID,Code,BusinessOperation");

	FillPropertyValues(CurCurrentAccountingData, DataOfAccounting);
	
	Return CurCurrentAccountingData;
	
EndFunction

&AtClientAtServerNoContext
Procedure OnChangeActualAvailability(RowData, Form)
	
	Object = Form.Object;
	
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
	
	WhenChangingDataInRow(RowData, Form);

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDocumentBasedOnLine(RowData, DocumentsBasedOn)
	
	RowData.DocumentBasedOnAC = Undefined;
	RowData.DocumentBasedOnTA = Undefined;
	RowData.DocumentBasedOnMA = Undefined;
	
	DocumentsList = DocumentsBasedOn.Get(RowData.AccountingObject);
	
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
	
	ElsIf RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets") Then
		
		RowData.DocumentBasedOnAC = DocumentsList.ReturnLeasedAssets;
	
	ElsIf RowData.LAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination") Then
		
		RowData.DocumentBasedOnAC = DocumentsList.LeaseTermination;
	
	EndIf; 
	
	// TA
	If RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.Recognition;
	
	ElsIf RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.Move;
	
	ElsIf RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.WriteOff;
	
	ElsIf RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.ReturnLeasedAssets;
	
	ElsIf RowData.TAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination") Then
		
		RowData.DocumentBasedOnTA = DocumentsList.LeaseTermination;
	
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
	
	ElsIf RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets") Then
		
		RowData.DocumentBasedOnMA = DocumentsList.ReturnLeasedAssets;
	
	ElsIf RowData.MAAction = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination") Then
		
		RowData.DocumentBasedOnMA = DocumentsList.LeaseTermination;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure PerformActionBasedOnPhysicalInventoryCountCompletion(Result, AdditionalParameters) Export

	If Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Recognition") Then
		
		If FormServiceParameters.VNAManagementIsUsed_2_4 Then
			
			NameOfFormToOpen_ = "Document.FixedAssetsInitialRecognition2_4.ObjectForm";
				
		Else
			
			
		EndIf;
			
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Move") Then
		
		If FormServiceParameters.VNAManagementIsUsed_2_4 Then
			
			NameOfFormToOpen_ = "Document.FATransfer2_4.ObjectForm";
				
		Else
			
			
		EndIf;
			
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff") Then
		
		If FormServiceParameters.VNAManagementIsUsed_2_4 Then
			
			NameOfFormToOpen_ = "Document.DisposeFixedAssets2_4.ObjectForm";
				
		Else
			
			
		EndIf;
			
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.ReturnLeasedAssets") Then
		
		NameOfFormToOpen_ = "Document.ReturnLeasedAssets.ObjectForm";
		
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.LeaseTermination") Then
		
		NameOfFormToOpen_ = "Document.LeaseTermination.ObjectForm";
		
	ElsIf Result.Action = PredefinedValue("Enum.ActionsBasedOnPhysicalInventoryCount.Revaluation") Then
		
		NameOfFormToOpen_ = "Document.FARevaluation2_4.ObjectForm";
		
	EndIf; 
	
	OpenForm(NameOfFormToOpen_, Result.FormParameters, ThisObject, ThisObject);

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
