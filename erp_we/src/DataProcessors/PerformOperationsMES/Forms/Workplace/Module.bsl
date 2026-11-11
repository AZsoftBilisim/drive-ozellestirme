
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Department") Then
		Department = Parameters.Department;
	EndIf;
	
	TheProductionScheduleIsUsed = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	ActiveStates = ActiveStates();
	State.LoadValues(ActiveStates);
	
	SetTypeOfWorkCenter(ThisForm);
	SetArtistType();
	
	SetPropertiesOfDynamicListPerformOperations();
	SetDynamicOperationListProperties();
	
	SetSelectionByDivisionSection();
	SetSelectionByWorkCenter();
	SetSelectionByState();
	
	If Parameters.Property("FilterByStages") Then
		SetSelectionByStages(Parameters.FilterByStages);
	EndIf;
	
	UseAreas = ProductionServer.UseAreasInPostoperativePlanning();
	
	Items.SelectionDivisionTitle.Visible  = Not UseAreas;
	Items.SelectionDivisionTitle1.Visible = Not UseAreas;
	Items.FilterTypeDepartment.Visible  = UseAreas;
	Items.FilterTypeDepartment1.Visible = UseAreas;
	
	ConfigureDependentFormElements();
	
	InformationRegisters.JobsForCalculatingProductionOperationQueue.StartJobs();
	
	#Region StandardMechanisms
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	TypesList = Operations.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.PrintSubmenu;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.OperationCommandsGlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	// End Peripherals
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_ProductionOperation2_2"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("Department")
		And Parameter.Department = Department
		And Items.GroupPages.CurrentPage = Items.PageOperationPerformance Then
		
		Items.ExecutionOfOperations.Refresh();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Department) Then
		
		// Selections are set via parameters, saved settings are not used
		
		Settings.Delete("Department");
		Settings.Delete("ProductionArea");
		Settings.Delete("WorkCenter");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings["Department"] <> Undefined Then
		
		FilterTypeDepartment = ?(Not ProductionArea.IsEmpty() And UseAreas, 1, 0);
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenterTypes")
				Or Not ValueIsFilled(WorkCenter) Then
			FilterTypeWorkCenter = 0;
		Else
			FilterTypeWorkCenter = 1;
		EndIf;
		
		DivisionWhenChangedOnServer(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region ExecutionOfOperations

&AtClient
Procedure PerformingUpdateOperations(Command)
	
	Items.ExecutionOfOperations.Refresh();
	
EndProcedure

&AtClient
Procedure PerformingCreateOperations(Command)
	
	CurrentData = Items.ExecutionOfOperations.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow")
		Or CurrentData.WaitingForCreation = 0 Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	
	OpenAddOperationForm(CurrentData, "Create");
	
EndProcedure

&AtClient
Procedure PerformingOperationsAcceptToWork(Command)
	
	CurrentData = Items.ExecutionOfOperations.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow")
		Or CurrentData.ExecutionIsAllowed = 0 Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	
	If (CurrentData.Scheduled - CurrentData.WaitingForCreation)
		- (CurrentData.Running + CurrentData.Completed2) > 0 Then
		OpenOperationsListForm(CurrentData, "PutIntoOperation");
	Else
		OpenAddOperationForm(CurrentData, "PutIntoOperation");
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsAreToCelebrateTheExecution(Command)
	
	CurrentData = Items.ExecutionOfOperations.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Items.ExecutionOfOperations.CurrentRow) = Type("DynamicListGroupRow")
		Or (CurrentData.ExecutionIsAllowed + CurrentData.Running) = 0 Then
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho dòng đã chọn!';
								|ru = 'Команда не может быть выполнена для выбранной строки!';
								|en = 'Command cannot be executed for the selected line.'; fa = 'Command cannot be executed for the selected line.';
								|it = 'Il comando non può essere eseguito per la riga selezionata!';
								|pl = 'Polecenie nie może być wykonane dla wybranego wiersza!';
								|tr = 'Seçili satır için komut gerçekleştirilemez!'"));
		Return;
	EndIf;
	
	If CurrentData.Scheduled - CurrentData.WaitingForCreation - CurrentData.Completed2 > 0
		Or CurrentData.Running > 0 Then
		OpenOperationsListForm(CurrentData, "MarkCompletion");
	Else
		OpenAddOperationForm(CurrentData, "MarkCompletion");
	EndIf;
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure OperationToAssignAWorkCenter(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	WorkCenterType = Undefined;
	FilterByArea    = Undefined;	
	
	For Each Ref In SelectedRows Do
		
		RowData = Items.Operations.RowData(Ref);
			
		If Not RowData.WorkCenterType.IsEmpty() Then
			
			If WorkCenterType = Undefined Then
					
				WorkCenterType = RowData.WorkCenterType;
				
			ElsIf WorkCenterType <> RowData.WorkCenterType Then
				
				ShowMessageBox(, NStr("vi = 'Đã chọn các giao dịch có dạng nguồn lực sản xuất khác nhau.';
										|ru = 'Выбраны операции с различными видами рабочих центров.';
										|en = 'Operations with different work center types are selected.'; fa = 'Operations with different work center types are selected.';
										|it = 'Sono selezionate le operazioni con tipi di centri operativi diversi.';
										|pl = 'Wybrane operacje z różnymi rodzajami centrów roboczych.';
										|tr = 'Farklı türde iş merkezleri olan işlemler seçildi.'"));
				Return;
				
			EndIf;
			
		EndIf;
		
		If Not RowData.ProductionArea.IsEmpty() Then
			
			If FilterByArea = Undefined Then
				
				FilterByArea = RowData.ProductionArea;
				
			ElsIf FilterByArea <> RowData.ProductionArea Then
				
				ShowMessageBox(, NStr("vi = 'Đã chọn các giao dịch có khu vực khác nhau';
										|ru = 'Выбраны операции с различными участками.';
										|en = 'Operations with different areas are selected.'; fa = 'Operations with different areas are selected.';
										|it = 'Sono state selezionate operazioni con siti diversi.';
										|pl = 'Wybrano operacje z różnymi obszarami.';
										|tr = 'Farklı sahaları olan işlemler seçildi.'"));
				Return;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Filter = New Structure;
	Filter.Insert("Department", Department);
	If FilterByArea <> Undefined Then
		Filter.Insert("ProductionArea", FilterByArea);
	EndIf;
	If WorkCenterType <> Undefined Then
		Filter.Insert("WorkCenterType", WorkCenterType);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChooseSetupOption", True);
	FormParameters.Insert("Filter", Filter);
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	
	CallbackDescription = New CallbackDescription(
		"OperationsAssignWorkCenterCompletion",
		ThisObject, AddlParameters);
	
	OpenForm("Catalog.WorkCenters.ChoiceForm",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OperationsAssignWorkCenterCompletion(ClosingResult, AddlParameters) Export
	
	If ClosingResult <> Undefined Then
		
		If TypeOf(ClosingResult) = Type("Structure") Then
			OperationsAssignWorkCenterOnServer(AddlParameters.Operations,
				ClosingResult.WorkCenter,
				ClosingResult.SetupSettings);
		Else
			OperationsAssignWorkCenterOnServer(AddlParameters.Operations, ClosingResult);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsCancelWorkCenterAssignment(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	OperationsAssignWorkCenterOnServer(
		SelectedRows,
		PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	
EndProcedure

&AtClient
Procedure OperationsSetStatusInProgress(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các hoạt động được tô sáng trong danh sách sẽ được đặt thành ""Đang thực hiện"". Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Выполняется"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to ""In progress"". Continue?'; fa = 'Status of the operations selected in the list will be set to ""In progress"". Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""In esecuzione"". Continuare?';
					|pl = 'Dla operacji zaznaczonych na liście zostanie ustawiony status ""Trwa wykonanie"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Gerçekleştiriliyor"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "Running");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Đang thực hiện';
													|ru = 'Выполняется';
													|en = 'In progress'; fa = 'در حال انجام';
													|it = 'In esecuzione';
													|pl = 'In progress';
													|tr = 'Gerçekleştiriliyor'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusOfOperationsCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OperationsSetStatusCompleted(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các thao tác được chọn trong danh sách sẽ được đặt thành trạng thái ""Đã hoàn thành"". Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Выполнена"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to Completed. Continue?'; fa = 'Status of the operations selected in the list will be set to Completed. Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""Eseguito"". Continuare?';
					|pl = 'Dla operacji zaznaczonych na liście zostanie ustawiony status ""Wykonana"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Gerçekleştirildi"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "Executed");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Đã thực hiện';
													|ru = 'Выполнена';
													|en = 'Completed'; fa = 'تکمیل‌شده';
													|it = 'Completata';
													|pl = 'Completed';
													|tr = 'Gerçekleştirildi'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusOfOperationsCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OperationsSetStatusFailed(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Các thao tác được chọn trong danh sách sẽ được đặt thành trạng thái ""Không thành công."" Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Не выполнена"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to Failed. Continue?'; fa = 'Status of the operations selected in the list will be set to Failed. Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""Non eseguito"". Continuare?';
					|pl = 'Dla operacji zaznaczonych na liście zostanie ustawiony status ""Nie wykonana"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Gerçekleştirilmedi"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "NotExecuted");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Chưa thực hiện';
													|ru = 'Не выполнена';
													|en = 'Failed'; fa = 'ناموفق';
													|it = 'Non eseguito';
													|pl = 'Nie wykonana';
													|tr = 'Gerçekleştirilmedi'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusOfOperationsCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OperationsSetTheStatusSkipped(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.Operations);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Ref In SelectedRows Do
		
		If Not Items.Operations.RowData(Ref).Skippable Then
			ShowMessageBox(, NStr("vi = 'Không thể bỏ qua giao dịch đã chọn.';
									|ru = 'Выделенные операции не могут быть пропущены.';
									|en = 'Selected operations cannot be skipped.'; fa = 'Selected operations cannot be skipped.';
									|it = 'Le operazioni selezionate non possono essere omesse.';
									|pl = 'Wyróżnionych operacji nie można pominąć.';
									|tr = 'Belirtilen işlemler atlanamaz.'"));
			Return;
		EndIf;
		
	EndDo;
	
	QueryText = NStr("vi = 'Các hoạt động được tô sáng trong danh sách sẽ được đặt thành Bỏ qua. Tiếp tục?';
					|ru = 'У выделенных в списке операций будет установлен статус ""Пропущена"". Продолжить?';
					|en = 'Status of the operations selected in the list will be set to Skipped. Continue?'; fa = 'Status of the operations selected in the list will be set to Skipped. Continue?';
					|it = 'Alle operazioni selezionate nell''elenco verrà assegnato lo stato ""Omessa"". Continuare?';
					|pl = 'Operacje wybrane na liście zostaną ustawione na ""Pominięte"". Kontynuować?';
					|tr = 'Listede belirtilen işlemler için ""Atlandı"" durumu ayarlanacaktır. Devam edilsin mi?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", SelectedRows);
	AddlParameters.Insert("Status", "IsSkipped");
	AddlParameters.Insert("StatusPresentation", NStr("vi = 'Bỏ qua';
													|ru = 'Пропущена';
													|en = 'Skipped'; fa = 'ردشده';
													|it = 'Omessa';
													|pl = 'Skipped';
													|tr = 'Atlandı'"));
	
	CallbackDescription = New CallbackDescription(
		"SetStatusOfOperationsCompletion", 
		ThisObject, AddlParameters);
	
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusOfOperationsCompletion(QuestionResult, AddlParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
		AddlParameters.Operations,
		AddlParameters.Status);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(
		Items.Operations,
		ProcessedItemsCount,
		AddlParameters.Operations.Count(),
		AddlParameters.StatusPresentation);
	
EndProcedure

#EndRegion

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.Operations);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.Operations, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.Operations);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.Operations);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormElementHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.ThePageActivityLog Then
		Items.Operations.Refresh();
	ElsIf CurrentPage = Items.PageOperationPerformance Then
		Items.ExecutionOfOperations.Refresh();
	EndIf;
	
EndProcedure

#Region ExecutionOfOperations

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer(False);
	
EndProcedure

&AtClient
Procedure FilterProductionAreaOnChange(Item)
	
	PlotWhenChangedOnServer(False);
	
EndProcedure

&AtClient
Procedure FilterTypeDepartmentOnChange(Item)
	
	If FilterTypeDepartment = 1 Then
		
		Department = Undefined;
		DivisionWhenChangedOnServer(True);
		
	Else
		
		ProductionArea = Undefined;
		PlotWhenChangedOnServer(True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterTypeWorkCenterOnChange(Item)
	
	If ValueIsFilled(WorkCenter) Then
		SelectionValueBeforeChange = WorkCenter;
	Else
		SelectionValueBeforeChange = Undefined;
	EndIf;
	
	SetTypeOfWorkCenter(ThisForm);
	
	If SelectionValueBeforeChange <> Undefined
		And SelectionValueBeforeChange <> WorkCenter Then
		SetSelectionByWorkCenter();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterWorkCenterOnChange(Item)
	
	SetSelectionByWorkCenter();
	
EndProcedure

&AtClient
Procedure FilterStateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("FilterStateStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Enum", Type("EnumRef.OperationStates"));
	FormParameters.Insert("SelectedValues", State.UnloadValues());
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.SelectEnumerationValues",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FilterStateStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined 
		And ClosingResult <> DialogReturnCode.Cancel Then
		
		State.LoadValues(ClosingResult);
		SetSelectionByState();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionByState();
	
EndProcedure

&AtClient
Procedure FilterStateClearing(Item, StandardProcessing)
	
	If State.Count() = 0 Then
		Return;
	EndIf;
	
	State.Clear();
	
	SetSelectionByState();
	
EndProcedure

&AtClient
Procedure ExecutionOfOperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		If Field.Name = "ExecutionOfOperationsOperation" Then
			ShowValue(, CurrentData.Operation);
		ElsIf Find("ExecutionOfOperationsStage,ExecutionOfOperationsPresentationStage" ,Field.Name) Then
			ShowValue(, CurrentData.Stage);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecutionOfOperationsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure InfoMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "DisableStageSelection" Then
		
		StandardProcessing = False;
		SetSelectionByStages();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure PerformerOnChange(Item)
	
	SetSelectionByPerformer();
	
EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Undefined,
		Department,
		Performer,
		Undefined,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department);
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure PerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	SetSelectionByStatus();
	
EndProcedure

&AtClient
Procedure FilterStatusStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("FilterStatusStartChoiceCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Enum", Type("EnumRef.ProductionOperationStatuses"));
	FormParameters.Insert("SelectedValues", Status.UnloadValues());
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.SelectEnumerationValues",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FilterStatusStartChoiceCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined 
		And ClosingResult <> DialogReturnCode.Cancel Then
	
		Status.LoadValues(ClosingResult);
		SetSelectionByStatus();
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetSelectionByState()
	
	CommonClientServer.DeleteFilterItems(
		ExecutionOfOperations.Filter,, "SelectionGroupByState");
		
	SetOfStates = State.UnloadValues();
	
	If SetOfStates.UBound() <> -1 Then
		
		FilterGroup = CommonClientServer.CreateFilterItemGroup(
			ExecutionOfOperations.Filter.Items, "SelectionGroupByState", DataCompositionFilterItemsGroupType.OrGroup);
		
		For Each StateValue In SetOfStates Do
			
			If StateValue = Enums.OperationStates.PendingPredecessorCompletion Then
				CommonClientServer.SetFilterItem(FilterGroup, "PendingPredecessorCompletion", 0, DataCompositionComparisonType.Greater,, True);
			ElsIf StateValue = Enums.OperationStates.PreviousOnesAreStarted Then
				CommonClientServer.SetFilterItem(FilterGroup, "PreviousOnesStarted", 0, DataCompositionComparisonType.Greater,, True);
			ElsIf StateValue = Enums.OperationStates.ForCompletion Then
				CommonClientServer.SetFilterItem(FilterGroup, "ExecutionIsAllowed", 0, DataCompositionComparisonType.Greater,, True);
			ElsIf StateValue = Enums.OperationStates.Running Then
				CommonClientServer.SetFilterItem(FilterGroup, "Running", 0, DataCompositionComparisonType.Greater,, True);
			ElsIf StateValue = Enums.OperationStates.IsSkipped Then
				CommonClientServer.SetFilterItem(FilterGroup, "Skipped3", 0, DataCompositionComparisonType.Greater,, True);
			ElsIf StateValue = Enums.OperationStates.Executed Then
				FilterGroupExecuted = CommonClientServer.CreateFilterItemGroup(
					FilterGroup.Items, "SelectionGroupByStateCompleted", DataCompositionFilterItemsGroupType.AndGroup);
				CommonClientServer.SetFilterItem(FilterGroupExecuted, "Completed2", 0, DataCompositionComparisonType.Greater,, True);	
				CommonClientServer.SetFilterItem(FilterGroupExecuted, "PendingPredecessorCompletion", 0, DataCompositionComparisonType.Equal,, True);
				CommonClientServer.SetFilterItem(FilterGroupExecuted, "PreviousOnesStarted", 0, DataCompositionComparisonType.Equal,, True);
				CommonClientServer.SetFilterItem(FilterGroupExecuted, "ExecutionIsAllowed", 0, DataCompositionComparisonType.Equal,, True);
				CommonClientServer.SetFilterItem(FilterGroupExecuted, "Running", 0, DataCompositionComparisonType.Equal,, True);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ConfigureDependentFormElements("State");
	
EndProcedure

&AtServer
Procedure SetSelectionByPerformer()
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		Operations.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo người thực hiện';
			|ru = 'Отбор по исполнителю';
			|en = 'Filter by assignee'; fa = 'فیلتر بر اساس مجری';
			|it = 'Selezione per assegnaatrio';
			|pl = 'Filtr według wykonawcy';
			|tr = 'Atanana göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
	
	If ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()) Then
		
		Person = ?(ValueIsFilled(Performer),
			Common.ObjectAttributeValue(Performer, "Individual"),
			Undefined);
		
		Assignees = New Array;
		Assignees.Add(Performer);
		Assignees.Add(Person);
		
		CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref.Performer",
			DataCompositionComparisonType.InList,
			Assignees,
			,
			ValueIsFilled(Performer));
		
		CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref.LaborCosts.Performer",
			DataCompositionComparisonType.InList,
			Assignees,
			,
			ValueIsFilled(Performer));
		
	Else
		
		CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref.Performer",
			DataCompositionComparisonType.Equal,
			Performer,
			,
			ValueIsFilled(Performer));
		
		CommonClientServer.AddCompositionItem(
			FilterRemainingGoodsByShelfLives,
			"Ref.LaborCosts.Performer",
			DataCompositionComparisonType.Equal,
			Performer,
			,
			ValueIsFilled(Performer));
	EndIf;
	
EndProcedure

&AtClient
Procedure SetSelectionByStatus()
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations, 
		"Status", 
		Status, 
		DataCompositionComparisonType.InList,
		, 
		ValueIsFilled(Status));
	
EndProcedure

&AtServer
Procedure SetSelectionByStages(StageList = Undefined)
	
	SelectionSet = ValueIsFilled(StageList);
	
	CommonClientServer.SetDynamicListFilterItem(
			ExecutionOfOperations,
			"Stage",
			StageList,
			DataCompositionComparisonType.InList,
			,
			SelectionSet);
	
	CommonClientServer.SetDynamicListFilterItem(
			Operations,
			"Stage",
			StageList,
			DataCompositionComparisonType.InList,
			,
			SelectionSet);
	
	If SelectionSet Then
		FormInscriptionAndSelectByStages(StageList);
	Else
		ClearInformationalMessage();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByWorkCenter()
	
	SelectionSet = ValueIsFilled(WorkCenter);
	
	If SelectionSet And FilterTypeWorkCenter = 1 Then
		FilterValue = Common.ObjectAttributeValue(WorkCenter, "WorkCenterType");
	Else
		FilterValue = WorkCenter;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
			ExecutionOfOperations, 
			"WorkCenterType", 
			FilterValue, 
			DataCompositionComparisonType.Equal,
			, 
			SelectionSet);
		
	If FilterTypeWorkCenter = 1 Then
		
		CommonClientServer.SetDynamicListFilterItem(
				Operations, 
				"WorkCenter", 
				WorkCenter, 
				DataCompositionComparisonType.Equal,
				, 
				SelectionSet);
		
		CommonClientServer.SetDynamicListFilterItem(
				Operations, 
				"WorkCenterType", 
				,
				,
				,
				False);
				
		CommonClientServer.SetDynamicListFilterItem(
				ExecutionOfOperations, 
				"WorkCenter", 
				WorkCenter,
				DataCompositionComparisonType.Equal,
				,
				SelectionSet);
					
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
				Operations, 
				"WorkCenter", 
				,
				,
				,
				False);
		
		CommonClientServer.SetDynamicListFilterItem(
				Operations, 
				"WorkCenterType", 
				WorkCenter, 
				DataCompositionComparisonType.Equal,
				, 
				SelectionSet);
				
		CommonClientServer.SetDynamicListFilterItem(
				ExecutionOfOperations, 
				"WorkCenter", 
				,
				,
				,
				False);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByDivisionSection() 
	
	CommonClientServer.SetDynamicListFilterItem(
		ExecutionOfOperations,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ExecutionOfOperations,
		"ProductionArea",
		ProductionArea,
		DataCompositionComparisonType.Equal,
		, 
		FilterTypeDepartment = 1);
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations, 
		"Department", 
		Department, 
		DataCompositionComparisonType.Equal,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"ProductionArea",
		ProductionArea,
		DataCompositionComparisonType.Equal,
		, 
		FilterTypeDepartment = 1);
	
	FOParameters = New Structure(
		"Department",
		?(ValueIsFilled(Department), Department, Undefined));
	SetFormFunctionalOptionParameters(FOParameters);
	
EndProcedure

&AtServer
Procedure PlotWhenChangedOnServer(SelectionTypeChanged)
	
	Department = ?(ProductionArea.IsEmpty(),
		Undefined,
		Common.ObjectAttributeValue(ProductionArea, "Owner"));
		
	DivisionWhenChangedOnServer(SelectionTypeChanged);
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer(SelectionTypeChanged)
	
	SetTypeOfWorkCenter(ThisForm);
	SetArtistType();
	
	SetSelectionByDivisionSection();
	SetSelectionByWorkCenter();
	SetSelectionByPerformer();
	
	If SelectionTypeChanged Then
		
		ConfigureDependentFormElements("FilterTypeDepartment");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetArtistType()
	
	If ValueIsFilled(Department) Then
		
		ProductionManagementClientServer.SetArtistType(
			Performer,
			ProductionServer.ProductionBusinessUnitDescription(Department).UseTeamWorkOrders,
			ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FormInscriptionAndSelectByStages(StageList)
	
	RowsArray = New Array;
	
	If StageList.Count() > 1 Then
		
		RowsArray.Add(NStr("vi = 'Đã thiết lập lọc theo danh sách công đoạn';
							|ru = 'Установлен отбор по списку этапов';
							|en = 'Filter by stage list is set'; fa = 'Filter by stage list is set';
							|it = 'Impostata la selezione per elenco delle fasi';
							|pl = 'Ustaw zaznaczenie według listy etapów';
							|tr = 'Aşama listesine göre filtre yapılandırıldı'"));
		
	Else
		
		StageDetails = Common.ObjectAttributesValues(StageList[0], "Number, StageName"); 
		PresentationStage = Documents.ProductionStage2_2.PresentationStage(StageDetails);
		
		RowsArray.Add(NStr("vi = 'Đã thiết lập lọc theo công đoạn';
							|ru = 'Установлен отбор по этапу';
							|en = 'Stage filter is set'; fa = 'Stage filter is set';
							|it = 'Impostata la selezione per fase';
							|pl = 'Ustawiono selekcję wg etapu';
							|tr = 'Aşamaya göre filtre yapılandırıldı'"));
		RowsArray.Add(" ");
		
		RowsArray.Add(New FormattedString(
			PresentationStage,
			,
			,
			,
			GetURL(StageList[0])));
		
	EndIf;
	
	RowsArray.Add(" (");
	
	RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
											|ru = 'отключить';
											|en = 'disable'; fa = 'disable';
											|it = 'disattivare';
											|pl = 'disable';
											|tr = 'devre dışı bırak'"),,,, "DisableStageSelection"));
	
	RowsArray.Add(") ");
	
	InfoMessage = New FormattedString(RowsArray);
	
	ConfigureDependentFormElements("InfoMessage");
	
EndProcedure

&AtServer
Procedure ClearInformationalMessage()
	
	InfoMessage = Undefined;
	ConfigureDependentFormElements("InfoMessage");
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	// Color-coding of pending previous operations
	#Region PerformingOperations_WaitingForPrecedingOnes
	
	Item = ExecutionOfOperations.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Running");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ExecutionIsAllowed");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
		
	#EndRegion 
	
	// Registration of the Date field in the list of operations
	#Region Operations_Date
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisForm, "Operations.Date", Items.OperationsDate.Name);
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetDynamicOperationListProperties()
	
	QueryText = Operations.QueryText;
	
	Documents.ProductionStage2_2.ReplacePresentationField(QueryText, "&PresentationStage", "OperationsOverridable.Stage");

	ListProperties = Common.DynamicListPropertiesStructure();
	
	ListProperties.QueryText                 = QueryText;
	ListProperties.MainTable              = Operations.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.Operations, ListProperties);
	
EndProcedure

&AtServer
Procedure SetPropertiesOfDynamicListPerformOperations()
	
	QueryText = ExecutionOfOperations.QueryText;
	
	Documents.ProductionStage2_2.ReplacePresentationField(QueryText, "&PresentationStage", "QueueOverridable.Stage");
	
	FieldName = "TechnologicalProcessPresentation";
	QueryText = StrReplace(QueryText, "&"+FieldName,
		ProductionProcessEditor.RequestFieldsParametersOfTechnicalProcessOfStage(, "TechnicalProcessOverridable", FieldName)[FieldName]);

	ListProperties = Common.DynamicListPropertiesStructure();
	
	ListProperties.QueryText                 = QueryText;
	ListProperties.MainTable              = ExecutionOfOperations.MainTable;
	ListProperties.DynamicDataRead = True;
	
	Common.SetDynamicListProperties(Items.ExecutionOfOperations, ListProperties);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElements(AttributesList = "")
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Or AttributesStructure1.Property("FilterTypeDepartment") Then
	
		Items.FilterDepartment.Visible = (FilterTypeDepartment = 0);
		Items.FilterDepartment1.Visible = (FilterTypeDepartment = 0);
		Items.FilterProductionArea.Visible = (FilterTypeDepartment = 1);
		Items.FilterProductionArea1.Visible = (FilterTypeDepartment = 1);
		
		Links = New Array;
		Links.Add(New ChoiceParameterLink("Filter.Department", "Department"));
		If FilterTypeDepartment = 1 Then
			Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
		EndIf;
		
		Items.FilterWorkCenter.ChoiceParameterLinks = New FixedArray(Links);
		Items.FilterWorkCenter1.ChoiceParameterLinks = New FixedArray(Links);
		
	EndIf;
	
	If Initialize Or AttributesStructure1.Property("State") Then
		
		If ActiveStatesOnly(State) Then
			TheStatusLine = NStr("vi = 'Chưa hoàn thành';
								|ru = 'Незавершенные';
								|en = 'Unfinished'; fa = 'ناتمام';
								|it = 'Non completate';
								|pl = 'Niedokończone';
								|tr = 'Tamamlanmayanlar'");
		Else
			TheStatusLine = StrConcat(State.UnloadValues(), ";");
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("InfoMessage") Then
		
		FilledInformationMessage = ValueIsFilled(InfoMessage);
		
		Items.InfoMessage1.Visible = FilledInformationMessage;
		Items.InfoMessage2.Visible = FilledInformationMessage;
		
	EndIf;
	
EndProcedure

&AtClient
Function OpenAddOperationForm(CurrentData, WorkMode)
	
	OperationKey = ProductionManagementClientServer.ProductionOperationKey();
	FillPropertyValues(OperationKey, CurrentData);
	
	FormParameters = New Structure;
	FormParameters.Insert("OperationKey", OperationKey);
	FormParameters.Insert("WorkMode", WorkMode);
	FormParameters.Insert("WorkCenter", CurrentData.WorkCenter);
	FormParameters.Insert("ProductionArea", CurrentData.ProductionArea);
	FormParameters.Insert("LotNumber", 	CurrentData.LotNumber);
	
	NameOfFormToOpen_ = "DataProcessor.PerformOperationsMES.Form.AddOperation";
		
	OpenForm(NameOfFormToOpen_,
		FormParameters,
		ThisForm,
		,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndFunction

&AtClient
Function OpenOperationsListForm(CurrentData, WorkMode)
	
	OperationKey = ProductionManagementClientServer.ProductionOperationKey();
	FillPropertyValues(OperationKey, CurrentData);
	
	FormParameters = New Structure;
	FormParameters.Insert("OperationKey", OperationKey);
	FormParameters.Insert("WorkMode", WorkMode);
	
	FormParameters.Insert("WorkCenter", CurrentData.WorkCenter);
	FormParameters.Insert("LotNumber", 	CurrentData.LotNumber);
	
	NameOfFormToOpen_ = "DataProcessor.PerformOperationsMES.Form.TransactionList";
	
	OpenForm(NameOfFormToOpen_,
		FormParameters,
		ThisForm,
		,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndFunction

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Performer = Result;
		SetSelectionByPerformer();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Organization, Department, Date");
	FilterParameters.Department = Department;
	FilterParameters.Date = CurrentSessionDate();
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTypeOfWorkCenter(Form)
	
	If Form.FilterTypeWorkCenter = 0 Then
		ValidType_ = New TypeDescription("CatalogRef.WorkCenterTypes");
	Else
		ValidType_ = New TypeDescription("CatalogRef.WorkCenters");
	EndIf;
	
	Form.WorkCenter = ValidType_.AdjustValue(Form.WorkCenter);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		If Items.GroupPages.CurrentPage = Items.PageOperationPerformance Then
			ShowValue(Undefined, ReferencesArrray[0]);
		Else
			Items.Operations.CurrentRow = ReferencesArrray[0];
			If Items.Operations.CurrentRow = Undefined Then
				ShowValue(Undefined, ReferencesArrray[0]);
			EndIf;
		EndIf;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ProductionOperation2_2.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtServer
Procedure OperationsAssignWorkCenterOnServer(Operations, WorkCenter, SetupSettings = Undefined)
	
	Documents.ProductionOperation2_2.AssignWorkCenterToOperations(Operations, WorkCenter, SetupSettings);
	
	Items.Operations.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Function ActiveStates()
	
	States1 = New Array;
	
	States1.Add(PredefinedValue("Enum.OperationStates.PendingPredecessorCompletion"));
	States1.Add(PredefinedValue("Enum.OperationStates.PreviousOnesAreStarted"));
	States1.Add(PredefinedValue("Enum.OperationStates.ForCompletion"));
	States1.Add(PredefinedValue("Enum.OperationStates.Running"));
	
	Return States1;
	
EndFunction

&AtClientAtServerNoContext
Function ActiveStatesOnly(StatesList)
	
	ActiveStates = ActiveStates();
	
	If ActiveStates.Count() <> StatesList.Count() Then
		Return False;
	EndIf;
	
	For Each CollectionItem In StatesList Do
		If ActiveStates.Find(CollectionItem.Value) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion
