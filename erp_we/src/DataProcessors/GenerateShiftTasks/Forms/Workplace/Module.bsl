
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.FilterByStep.IsEmpty() Then
		LoadSettings();
	Else
		Departments = ProductionManagementServerCall.DivisionsPerformers(
			TMCommonUseClientServer.Array(Parameters.FilterByStep));
		Department = Departments[Parameters.FilterByStep];
		
		PresentationStage = Documents.ProductionStage2_2.PresentationStage(
			Common.ObjectAttributesValues(Parameters.FilterByStep, "Number, StageName"));
			
		RowsArray = New Array;
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
			GetURL(Parameters.FilterByStep)));
		RowsArray.Add(" (");
		RowsArray.Add(New FormattedString(NStr("vi = 'ngắt kết nối';
												|ru = 'отключить';
												|en = 'disable'; fa = 'disable';
												|it = 'disattivare';
												|pl = 'disable';
												|tr = 'devre dışı bırak'"),,,, "DisableStageSelection"));
		RowsArray.Add(") ");
			
		InfoMessage = New FormattedString(RowsArray);
	EndIf;
	
	TheProductionScheduleIsPlanned = ProductionManagementCached.TheProductionScheduleIsUsed();
	
	If AssignmentMode = 0 Then
		AssignmentMode = AssignmentModeForPerformers();
	EndIf;
	
	If DisplayMode = 0 Then
		DisplayMode = ViewingModeCanBeAssigned();
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Department", Department));
	ThereAreAreas = GetFormFunctionalOption("UseProductionSites");
	
	DepartmentBeforeChange = Department;
	SelectedModeColor = StyleColors.FormTextColor;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	AssignmentParameters = InformationRegisters.OperationsToCreateShiftTasks.ParametersForAssigningOperations();
	
	SelectConfigureShiftCompositionButton();
	ConfigureDependentFormElements(ThisObject);
	
	QueryTextOperations = StrReplace(
		Operations.QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("RegisterOverridable.Stage"));
	QueryTextOperations = StrReplace(
		QueryTextOperations,
		"&RunTime",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("RegisterOverridable"));
	
	StringIsEmptyLink = "NULL";
	
	QueryTextOperations = StrReplace(
		QueryTextOperations,
		"&EmptyRef",
		StringIsEmptyLink);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryTextOperations;
	Common.SetDynamicListProperties(Items.Operations, ListProperties);
	Operations.Parameters.SetParameterValue("FilterByArea", False);
	Operations.Parameters.SetParameterValue("ProductionArea", Undefined);
	
	SetUpListOfShiftTasks();
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = ShiftJobs.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters.CommandBar = Items.ShiftJobs.CommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
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
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.GenerateShiftTasks.Form.SelectAssignees" Then
		
		StringCache = CacheExpandedTreeLines();
		
		If TypeOf(ValueSelected) = Type("Structure") Then
			
			If ValueSelected.AdditionalParameters.Mode = "NewArtist" Then
				
				AddPerformers(ValueSelected.ShiftTask, ValueSelected.References);
				
			ElsIf ValueSelected.AdditionalParameters.Mode = "AssignmentToNewExecutor" Then
				
				ParametersStructure = ValueSelected.AdditionalParameters.AssignmentParameters;
				ParametersStructure.Dimensions.Performer = ValueSelected.References[0];
				
				AssignOperations(
					ValueSelected.AdditionalParameters.OperationKeys,
					ValueSelected.ShiftTask,
					ParametersStructure);
				
				NotifyAboutChangeOfOperationsAssignment();
				
			EndIf;
		
		EndIf;
		
		ExpandTreeRowsFromCache(StringCache);
		
	EndIf;
	
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
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	If Department = DepartmentBeforeChange Then
		Return;
	EndIf;
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	ShiftContent.Clear();
	ProductionArea.Clear();
	Shifts.GetItems().Clear();
	SelectConfigureShiftCompositionButton();
	
	ShouldSaveSettings(ThisObject);
	
	SetFormFunctionalOptionParameters(New Structure("Department", Department));
	ThereAreAreas = GetFormFunctionalOption("UseProductionSites");
	
	ConfigureDependentFormElements(ThisObject, "Department");
	
	DepartmentBeforeChange = Department;
	
EndProcedure

&AtClient
Procedure AssignPerformers_3Click(Item)
	
	AssignmentMode = AssignmentModeForPerformers();
	
	WhenChangingDestinationMode();
	
EndProcedure

&AtClient
Procedure AssignToWorkCentersClick(Item)
	
	AssignmentMode = AssignmentModeForWorkCenters();
	
	WhenChangingDestinationMode();
	
EndProcedure

&AtClient
Procedure ToAssignTheTypesOfRTSClick(Item)
	
	AssignmentMode = ModeOfAssignmentToTypesOfRC();
	
	WhenChangingDestinationMode();
	
EndProcedure

&AtClient
Procedure WhenChangingDestinationMode()
	
	ConfigureDependentFormElements(ThisObject, "AssignmentMode");
	
	SaveSettingsAndFillShifts();
	
	ExpandAllTreeRows();
	
EndProcedure

&AtClient
Procedure AssignmentIsAllowedClick(Item)
	
	DisplayMode = ViewingModeCanBeAssigned();
	
	WhenChangingViewingMode();
	
EndProcedure

&AtClient
Procedure AllForAssignmentClick(Item)
	
	DisplayMode = ViewAllToDestinationMode();
	
	WhenChangingViewingMode();
	
EndProcedure

&AtClient
Procedure AssignedClick(Item)
	
	DisplayMode = ViewModeAssigned();
	
	WhenChangingViewingMode();
	
EndProcedure

&AtClient
Procedure WhenChangingViewingMode()
	
	ConfigureDependentFormElements(ThisObject, "DisplayMode");
	
	ShouldSaveSettings(ThisObject);
	
	ConfigureOperationSelection();
	
EndProcedure

&AtClient
Procedure InfoMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "DisableStageSelection" Then
		
		StandardProcessing = False;
		
		Parameters.FilterByStep = Undefined;
		
		SetUpListOfShiftTasks();
		
		ConfigureDependentFormElements(ThisObject, "FilterByStep");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If StartDate > EndDate And EndDate <> '000101010000' Then
		EndDate = StartDate;
	EndIf;
	
	ConfigureOperationSelection();
	
EndProcedure

&AtClient
Procedure EndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If EndDate < StartDate And StartDate <> '000101010000' Then
		StartDate = EndDate;
	EndIf;
	
	ConfigureOperationSelection();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShifts

&AtClient
Procedure ShiftsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Shifts.FindByID(RowSelected);
	If CurrentData.RowType = LineTypeChange() Then
		
		ShowValue(, CurrentData.ShiftTask);
		
	ElsIf CurrentData.RowType = LineTypeObject() Then
		
		ShowValue(, CurrentData.RelatedObject);
		
	ElsIf CurrentData.RowType = LineTypeNewArtist() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Department", Department);
		FormParameters.Insert("ShiftTask", CurrentData.ShiftTask);
		FormParameters.Insert("ProductionArea", CurrentData.ProductionArea);
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
		FormParameters.Insert("Date", CurrentData.Date);
		FormParameters.Insert("AdditionalParameters",
			New Structure("Mode", "NewArtist"));
		
		OpenForm("DataProcessor.GenerateShiftTasks.Form.SelectAssignees",
			FormParameters,
			ThisObject,
			UUID,,,,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftsOnActivateRow(Item)
	
	ConfigureOperationSelection();
	
	ConfigureDependentFormElements(ThisObject, "ThisIsActiveLine");
	
EndProcedure

&AtClient
Procedure ShiftsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	If String = Undefined Then
		DragParameters.Action = DragAction.Cancel;
	Else
		DragParameters.Action = DragAction.Move;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.GenerateShiftTasks.Form.Workplace.AssignOperations");
	
	AssignOperationsToSelectedRow(
		DragParameters.Value,
		Shifts.FindByID(String));
	
EndProcedure

&AtClient
Procedure ShiftsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ShiftsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ShiftsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If AssignmentMode = AssignmentModeForPerformers()
		And Shifts.FindByID(Items.Shifts.CurrentRow).RowType = LineTypeObject() Then
		
		DeleteCurArtist();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.Shifts.CurrentData = Undefined Then
		
		ShowWarningShiftNotSelected();
		
	Else
		
		OperationKeys = CheckGetOperationsForAssignment(
			CommonClientServer.ValueInArray(RowSelected));
		
		If OperationKeys = Undefined Then
			Return;
		EndIf;
		
		String = Items.Shifts.CurrentData;
		
		FormParameters = New Structure;
		
		FormParameters.Insert("Department", Department);
		FormParameters.Insert("ShiftTask", String.ShiftTask);
		FormParameters.Insert("OperationKeys", OperationKeys);
		
		If AssignmentMode = AssignmentModeForPerformers() Then
			
			FormParameters.Insert("SelectAssignee", True);
			
			If String.RowType = LineTypeObject() Then
				FormParameters.Insert("Performer", String.RelatedObject);
			EndIf;
			
		ElsIf AssignmentMode = AssignmentModeForWorkCenters() Then
			
			FormParameters.Insert("ChoosingARC", True);
			
			If String.RowType = LineTypeObject() Then
				FormParameters.Insert("WorkCenter", String.RelatedObject);
				FormParameters.Insert("WorkCenterType", String.WorkCenterType);	
			EndIf;
			
		ElsIf AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
			
			FormParameters.Insert("SelectingTheTypeOfRC", True);
			
			If String.RowType = LineTypeObject() Then
				FormParameters.Insert("WorkCenterType", String.RelatedObject);
			EndIf;
			
		EndIf;
		
		FormParameters.Insert("AssignThePart",
			DisplayMode = ViewingModeCanBeAssigned()
			Or DisplayMode = ViewAllToDestinationMode());
		
		OpenForm("DataProcessor.GenerateShiftTasks.Form.OperationAssignment1",
			FormParameters,
			ThisObject,
			UUID,,,
			New CallbackDescription("AssignmentInSeparateFormEnds", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsOnActivateRow(Item)
	
	ConfigureDependentFormElements(ThisObject, "OperationsActiveLine");
	
EndProcedure

&AtClient
Procedure OperationsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure OperationsDragStart(Item, DragParameters, Perform)
	
	For Each Item In DragParameters.Value Do
		
		If TypeOf(Item) = Type("DynamicListGroupRow") Then
			
			Perform = False;
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShiftJobs

&AtClient
Procedure ShiftJobsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureTheCompositionOfShifts(Command)
	
	If Department.IsEmpty() Then
		
		ClearMessages();
		MessageText = CommonClientServer.FillingErrorText(,, NStr("vi = 'Bộ phận';
																	|ru = 'Подразделение';
																	|en = 'Business unit'; fa = 'Business unit';
																	|it = 'Reparto';
																	|pl = 'Dział';
																	|tr = 'Departman'"));
		CommonClientServer.MessageToUser(MessageText,, "Department");
		
		Return;
		
	EndIf;
	
	Statuses = New ValueList;
	Statuses.Add(PredefinedValue("Enum.ShiftTaskStatuses.BeingGenerated"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Department",       Department);
	FormParameters.Insert("ProductionArea",             ProductionArea);
	FormParameters.Insert("Statuses",             Statuses);
	FormParameters.Insert("PreviouslySelectedShifts", ShiftContent);
	FormParameters.Insert("MultipleChoice",  True);
	
	OpenForm(
		"Document.ShiftTask.Form.SelectionFormByCalendar",
		FormParameters,
		ThisObject,
		UUID,,,
		New CallbackDescription("ConfigureTheCompositionOfShiftsCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ConfigureTheCompositionOfShiftsCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		ShiftContent.LoadValues(ClosingResult.Jobs);
		ProductionArea = ClosingResult.ProductionArea;
		
		ConfigureCompositionOfShiftsCompletionOnServer();
		
		ExpandAllTreeRows();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureCompositionOfShiftsCompletionOnServer()
	
	ShouldSaveSettings(ThisForm);
	FillOutShifts();
	
EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	For Each String In Shifts.GetItems() Do
		Items.Shifts.Collapse(String.GetID());
	EndDo;
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	ExpandAllTreeRows();
	
EndProcedure

&AtClient
Procedure Assign(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.GenerateShiftTasks.Form.Workplace.AssignOperations");
	
	If Items.Shifts.CurrentData = Undefined Then
		
		ShowWarningShiftNotSelected();
		
	Else
		
		OperationKeys = CheckGetOperationsForAssignment(Items.Operations.SelectedRows);
		
		If OperationKeys <> Undefined Then
			
			AssignOperationsToSelectedRow(OperationKeys, Items.Shifts.CurrentData);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignThePart(Command)
	
	If Items.Shifts.CurrentData = Undefined Then
		
		ShowWarningShiftNotSelected();
		
	Else
		
		OperationKeys = CheckGetOperationsForAssignment(Items.Operations.SelectedRows);
		
		If OperationKeys = Undefined Then
			Return;
		ElsIf OperationKeys.Count() > 1 Then
			ShowMessageBox(, NStr("vi = 'Một giao dịch chỉ có thể được thực hiện trên một dòng.';
									|ru = 'Действие может быть выполнено только для одной строки';
									|en = 'Action can be performed only for one line'; fa = 'Action can be performed only for one line';
									|it = 'L''azione può essere eseguita solo per una singola riga';
									|pl = 'Czynność może być wykonana tylko dla jednego wiersza';
									|tr = 'Eylem sadece bir satır için gerçekleştirilebilir'"));
			Return;
		EndIf;
		
		String = Items.Shifts.CurrentData;
		
		FormParameters = New Structure;
		
		FormParameters.Insert("Department", Department);
		FormParameters.Insert("ShiftTask", String.ShiftTask);
		FormParameters.Insert("OperationKeys", OperationKeys);
		
		If String.RowType = LineTypeObject() Then
			If AssignmentMode = AssignmentModeForPerformers() Then
				
				FormParameters.Insert("Performer", String.RelatedObject);
				
			ElsIf AssignmentMode = AssignmentModeForWorkCenters() Then
				
				FormParameters.Insert("WorkCenter", String.RelatedObject);
				FormParameters.Insert("WorkCenterType", String.WorkCenterType);	
				
			ElsIf AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
				
				FormParameters.Insert("WorkCenterType", String.RelatedObject);
				
			EndIf;
		EndIf;
		
		FormParameters.Insert("EnterQuantity", True);
		FormParameters.Property("AssignThePart", True);
		
		If ThereAreAreas Then
			
			If ThereAreInappropriateSections(String.ProductionArea, OperationKeys) Then 
				
				QueryText = StrTemplate(NStr("vi = 'Trong các giao dịch được chỉ định có các khu vực không tương ứng với khu vực ""%1"". Tiếp tục?';
											|ru = 'В назначаемых операциях есть участки не соответствующие участку ""%1"". Продолжить?';
											|en = 'Operations to assign contain sites that do not match the ""%1"" site. Continue?'; fa = 'Operations to assign contain sites that do not match the ""%1"" site. Continue?';
											|it = 'Nelle operazioni assegnate vi sono siti che non corrispondono al sito ""%1"". Continuare?';
											|pl = 'W przeznaczanych operacjach są obszary nie zgodne z obszarem ""%1"". Kontynuować?';
											|tr = 'Atanan işlemlerde ""%1"" sahasına karşılık gelmeyen sahalar mevcut. Devam edilsin mi?'"), String(String.ProductionArea));
				
				Mode = New ValueList;
				Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Chỉ định';
													|ru = 'Назначить';
													|en = 'Assign'; fa = 'تخصیص';
													|it = 'Assegnare';
													|pl = 'Assign';
													|tr = 'Ata'"));
				Mode.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
				
				ShowQueryBox(New CallbackDescription("AssignPartToNewPerformerEnd", ThisObject, FormParameters), QueryText, Mode);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		OpenForm("DataProcessor.GenerateShiftTasks.Form.OperationAssignment1",
			FormParameters,
			ThisObject,
			UUID,,,
			New CallbackDescription("AssignmentInSeparateFormEnds", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

// Notification handler
&AtClient
Procedure AssignPartToNewPerformerEnd(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	OpenForm("DataProcessor.GenerateShiftTasks.Form.OperationAssignment1",
		AdditionalParameters,
		ThisObject,
		UUID,,,
		New CallbackDescription("AssignmentInSeparateFormEnds", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ToInstallRemoveTheSelectionOnTheSite(Command)
	
	FilterByArea = Not FilterByArea;
	
	ConfigureDependentFormElements(ThisObject, "FilterByArea");
	
	ShouldSaveSettings(ThisObject);
	
	ConfigureOperationSelection();
	
EndProcedure

&AtClient
Procedure Change(Command)
	
	OperationKeys = CheckGetOperationsForAssignment(Items.Operations.SelectedRows);
		
	If OperationKeys = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("OperationKeys", OperationKeys);
	
	If Items.Shifts.CurrentData <> Undefined Then
		FormParameters.Insert("ShiftTask", Items.Shifts.CurrentData.ShiftTask);
	EndIf;
	
	String = Undefined;
	If Items.Shifts.CurrentData <> Undefined
		And Items.Shifts.CurrentData.RowType = LineTypeObject() Then
		String = Items.Shifts.CurrentData;
	EndIf;
	
	If AssignmentMode = AssignmentModeForPerformers() Then
			
		FormParameters.Insert("SelectAssignee", True);
		
		If String <> Undefined Then
			FormParameters.Insert("Performer", String.RelatedObject);
		EndIf;
		
	ElsIf AssignmentMode = AssignmentModeForWorkCenters() Then
		
		FormParameters.Insert("ChoosingARC", True);
		
		If String <> Undefined Then
			FormParameters.Insert("WorkCenter", String.RelatedObject);
			FormParameters.Insert("WorkCenterType", String.WorkCenterType);	
		EndIf;
		
	ElsIf AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
		
		FormParameters.Insert("SelectingTheTypeOfRC", True);
		
		If String <> Undefined Then
			FormParameters.Insert("WorkCenterType", String.RelatedObject);
		EndIf;
		
	EndIf;
	
	OpenForm("DataProcessor.GenerateShiftTasks.Form.OperationAssignment1",
		FormParameters,
		ThisObject,
		UUID,,,
		New CallbackDescription("AssignmentInSeparateFormEnds", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Delete(Command)
	
	OperationKeys = CheckGetOperationsForAssignment(Items.Operations.SelectedRows);
		
	If OperationKeys <> Undefined Then
		
		ClearMessages();
		
		StringCache = CacheExpandedTreeLines();
		
		DeleteOperationsOnServer(OperationKeys);
		
		ExpandTreeRowsFromCache(StringCache);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignmentInSeparateFormEnds(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		StringCache = CacheExpandedTreeLines();
		
		UpdateFormAfterAssigningOperations(
			ClosingResult.OperationKeys,
			ClosingResult.ShiftTask);
		
		ExpandTreeRowsFromCache(StringCache);
		
		NotifyAboutChangeOfOperationsAssignment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateShifts(Command)
	
	If ShiftContent.Count() = 0 Then
		Return;
	EndIf;
	
	UpdateShiftsOnServer();
	
	ExpandAllTreeRows();
	
EndProcedure

&AtClient
Procedure OpenJob(Command)
	
	If Items.Shifts.CurrentData = Undefined Then
		
		ShowMessageBox(, NStr("vi = 'Không có ca làm việc được chọn';
								|ru = 'Не выбрана смена';
								|en = 'Shift is not selected'; fa = 'Shift is not selected';
								|it = 'Nessun turno selezionato';
								|pl = 'Nie wybrano zmiany';
								|tr = 'Vardiya seçilmedi'"));
		
	Else
		
		ShowValue(, Items.Shifts.CurrentData.ShiftTask);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetTheGeneratedStatusForTheJob(Command)
	
	If Items.Shifts.CurrentData = Undefined Then
		
		ShowMessageBox(, NStr("vi = 'Không có ca làm việc được chọn';
								|ru = 'Не выбрана смена';
								|en = 'Shift is not selected'; fa = 'Shift is not selected';
								|it = 'Nessun turno selezionato';
								|pl = 'Nie wybrano zmiany';
								|tr = 'Vardiya seçilmedi'"));
		Return;
		
	EndIf;
	
	ClearMessages();
	
	StringCache = CacheExpandedTreeLines();
	
	StartWaiting = SetStatusInBackground(Items.Shifts.CurrentData.ShiftTask);
	
	If StartWaiting Then
		
		CallbackDescription = New CallbackDescription(
			"SetStatusInBackgroundCompletion",
			ThisObject,
			New Structure("Ref, StringCache", Items.Shifts.CurrentData.ShiftTask, StringCache));
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackDescription,
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		ExpandTreeRowsFromCache(StringCache);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - Structure - LongDesc:
// * Status           - String - "Completed" if the task was completed successfully;
//	                                  "Error" if the task was completed with an error.
// * ResultAddress  - String - address of the temporary storage where
//	                                  the result of the procedure will be placed (or already placed).
// * AdditionalResultAddress - String - if the additional Result parameter is set, 
//	                                     it contains the address of the additional temporary storage
//	                                     where the result of the procedure will be placed (or has already been placed).
// * BriefErrorDescription   - String - brief information about the exception if the Status = "Error".
// * DetailErrorDescription - String - detailed information about the exception if the Status = "Error".
// * Messages        - FixedArray, Undefined - array of user Message objects 
//                                                generated in the handler procedure for a long operation.
// 	AddlParameters - Structure - LongDesc:
// * Ref - DocumentRef.ShiftTask - 
// * StringCache - Array of FormDataTreeItem - 
&AtClient
Procedure SetStatusInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ProcessResultOfSettingStatusInBackground(Result, AddlParameters.Ref);
		
		ExpandTreeRowsFromCache(AddlParameters.StringCache);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ThisObject, 
		New Structure("StartDate, EndDate", "StartDate", "EndDate"), Notification);
		
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	ConfigureOperationSelection();
	
EndProcedure

&AtClient
Procedure DeleteAssignee(Command)
	
	DeleteCurArtist();
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.ShiftJobs.SelectedRows);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ShiftJobs);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ShiftJobs, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ShiftJobs);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ShiftJobs);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

#Region ManagingElements

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Shifts - show hyperlink
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeNewArtist();
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	// Shifts - hide the row view
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsLinePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeNewArtist();
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Shifts - hide hyperlink
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsAction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = LineTypeNewArtist();
	
	Item.Appearance.SetParameterValue("Visible", False);
		
	// Shifts - show the row view
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsLinePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = LineTypeNewArtist();
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	// Shifts - red overload
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsLoad.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = LineTypeObject();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.Load");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("Shifts.Duration");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Shifts - mismatch of position/category
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ShiftsLinePresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Shifts.LaborGradeJobTitleMismatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Operations - unit of execution time per Second
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Second;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giây';
																					|ru = 'сек';
																					|en = 'sec'; fa = 'ثانیه';
																					|it = 'sec';
																					|pl = 'sec';
																					|tr = 'sn.'"))); // @Format-2
	
	// Operations - units of execution time per Minute
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Minute;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'phút';
																					|ru = 'мин';
																					|en = 'min'; fa = 'دقیقه';
																					|it = 'min';
																					|pl = 'min';
																					|tr = 'dk.'"))); // @Format-2
	
	// Operations - units of execution time per Hour
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Hour;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giờ';
																					|ru = 'ч';
																					|en = 'h'; fa = 'ساعت';
																					|it = 'ore';
																					|pl = 'godz.';
																					|tr = 'sa.'"))); // @Format-2
	
	// Operations - units of execution time per Day
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Days1;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'ngày';
																					|ru = 'сут';
																					|en = 'd'; fa = 'روز';
																					|it = '24 ore';
																					|pl = 'dob.';
																					|tr = 'gün'"))); // @Format-2
	
	// Operations - highlight in red the lines that need to be assigned or the assignment order is broken
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Operations.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ToBeAssigned");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.AssignmentProcedureIsViolated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Operations - lines that are not available for assignment should be highlighted in gray
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.Operations.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ShiftTask");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.AssignmentIsAllowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Operations.ToBeAssigned");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// Operations - Stage representation
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.OperationsStage.Name);
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Operations.PresentationStage"));
	
	// Start date
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "Operations", "OperationsStageStart");
	
	// completion date
	ProductionManagement.SetConditionalAppearanceOfProductionDateField(ThisObject, "Operations", "OperationsStageEnd");
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("AssignmentMode") 
		Or Initialize Then
		
		Items.AssignPerformers_3.Hyperlink = Form.AssignmentMode <> AssignmentModeForPerformers();
		Items.AssignPerformers_3.TextColor = ?(Form.AssignmentMode <> AssignmentModeForPerformers(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.AssignToWorkCenters.Hyperlink = Form.AssignmentMode <> AssignmentModeForWorkCenters();
		Items.AssignToWorkCenters.TextColor = ?(Form.AssignmentMode <> AssignmentModeForWorkCenters(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.ToAssignTheTypesOfRTS.Hyperlink = Form.AssignmentMode <> ModeOfAssignmentToTypesOfRC();
		Items.ToAssignTheTypesOfRTS.TextColor = ?(Form.AssignmentMode <> ModeOfAssignmentToTypesOfRC(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.ShiftsContextMenuDeleteAssignee.Visible = Form.AssignmentMode = AssignmentModeForPerformers();
		
	EndIf;
	
	If AttributesStructure1.Property("Department")
		Or Initialize Then
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.Operations,
			"Department",
			Form.Department,
			DataCompositionComparisonType.Equal,,
			True);
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.ShiftJobs,
			"Department",
			Form.Department,
			DataCompositionComparisonType.Equal,,
			True);
		
	EndIf;
	
	If AttributesStructure1.Property("FilterByStep")
		Or Initialize Then
		
		HasFilter = Not Form.Parameters.FilterByStep.IsEmpty();
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.Operations,
			"Stage",
			Form.Parameters.FilterByStep,
			DataCompositionComparisonType.Equal,,
			HasFilter);
		
		Items.Department.ReadOnly                    = HasFilter;
		Items.InformationMessageOfTheOperation.Visible       = HasFilter;
		Items.InformationalMessageChangeableTasks.Visible = HasFilter;
		
	EndIf;
	
	If AttributesStructure1.Property("AssignmentMode") 
		Or AttributesStructure1.Property("Department")
		Or Initialize Then
		
		If Form.AssignmentMode = AssignmentModeForPerformers() Then
			RelatedObject = NStr("vi = 'Người thực hiện';
								|ru = 'Исполнитель';
								|en = 'Assignee'; fa = 'Assignee';
								|it = 'Esecutore';
								|pl = 'Wykonawca';
								|tr = 'Atanan'");
		ElsIf Form.AssignmentMode = AssignmentModeForWorkCenters() Then
			RelatedObject = NStr("vi = 'Nguồn lực sản xuất';
								|ru = 'Рабочий центр';
								|en = 'Work center'; fa = 'مرکز کاری';
								|it = 'Centro di lavoro';
								|pl = 'Centrum pracy';
								|tr = 'İş merkezi'");
		ElsIf Form.AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
			RelatedObject = NStr("vi = 'Dạng nguồn lực sản xuất';
								|ru = 'Вид РЦ';
								|en = 'Work center type'; fa = 'نوع مرکز کاری';
								|it = 'Tipo dei centri di lavoro';
								|pl = 'Rodzaj CP';
								|tr = 'İM türü'");
		EndIf;
		
		If Form.ThereAreAreas Then
			Items.ShiftsGroupPresentation.Title = StrTemplate(NStr("vi = 'Ca làm việc, Khu, %1';
																	|ru = 'Смена, Участок, %1';
																	|en = 'Shift, Site, %1'; fa = 'Shift, Site, %1';
																	|it = 'Turno, Reparto, %1';
																	|pl = 'Zmiana, Działka, %1';
																	|tr = 'Vardiya, Saha, %1'"), RelatedObject);
		Else
			Items.ShiftsGroupPresentation.Title = StrTemplate(NStr("vi = 'Ca làm việc, %1';
																	|ru = 'Смена, %1';
																	|en = 'Shift, %1'; fa = 'Shift, %1';
																	|it = 'Turno, %1';
																	|pl = 'Zmiana, %1';
																	|tr = 'Vardiya, %1'"), RelatedObject);
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("DisplayMode") 
		Or Initialize Then
		
		Items.AssignmentIsAllowed.Hyperlink  = Form.DisplayMode <> ViewingModeCanBeAssigned();
		Items.AssignmentIsAllowed.TextColor = ?(Form.DisplayMode <> ViewingModeCanBeAssigned(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.AllForAssignment.Hyperlink  = Form.DisplayMode <> ViewAllToDestinationMode();
		Items.AllForAssignment.TextColor = ?(Form.DisplayMode <> ViewAllToDestinationMode(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.Assigned.Hyperlink  = Form.DisplayMode <> ViewModeAssigned();
		Items.Assigned.TextColor = ?(Form.DisplayMode <> ViewModeAssigned(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.OperationToAssign.Visible = Form.DisplayMode = ViewingModeCanBeAssigned()
			Or Form.DisplayMode = ViewAllToDestinationMode();
		Items.OperationsContextMenuAssign.Visible = Form.DisplayMode = ViewingModeCanBeAssigned()
			Or Form.DisplayMode = ViewAllToDestinationMode();
			
		Items.OperationToAssignAPartOf.Visible = Form.DisplayMode = ViewingModeCanBeAssigned()
			Or Form.DisplayMode = ViewAllToDestinationMode();
		Items.OperationsContextMenuAssignThePart.Visible = Form.DisplayMode = ViewingModeCanBeAssigned()
			Or Form.DisplayMode = ViewAllToDestinationMode();
		
		Items.OperationsChange.Visible = Form.DisplayMode = ViewModeAssigned();
		Items.OperationsContextMenuChange.Visible = Form.DisplayMode = ViewModeAssigned();
		
		Items.DeleteOperations_3.Visible = Form.DisplayMode = ViewModeAssigned();
		Items.OperationsContextMenuDelete.Visible = Form.DisplayMode = ViewModeAssigned();
		
	EndIf;
	
	If AttributesStructure1.Property("DisplayMode")
		Or AttributesStructure1.Property("Department")
		Or Initialize Then
		
		Items.OperationsSelectionBySite.Visible = Form.ThereAreAreas
			And (
				Form.DisplayMode = ViewingModeCanBeAssigned()
				Or Form.DisplayMode = ViewAllToDestinationMode()
				);
		
	EndIf;
	
	If AttributesStructure1.Property("OperationsActiveLine") 
		Or Initialize Then
		
		CommandsAvailability = Items.Operations.CurrentRow <> Undefined;
		
		Items.OperationToAssign.Enabled = CommandsAvailability;
		Items.OperationsContextMenuAssign.Enabled = CommandsAvailability;
		
		Items.OperationToAssignAPartOf.Enabled = CommandsAvailability;
		Items.OperationsContextMenuAssignThePart.Enabled = CommandsAvailability;
		
		Items.OperationsChange.Enabled = CommandsAvailability;
		Items.OperationsContextMenuChange.Enabled = CommandsAvailability;
		
		Items.DeleteOperations_3.Enabled = CommandsAvailability;
		Items.OperationsContextMenuDelete.Enabled = CommandsAvailability;
		
	EndIf;
	
	If AttributesStructure1.Property("ThisIsActiveLine") 
		Or Initialize Then
		
		CommandsAvailability = Items.Shifts.CurrentRow <> Undefined;
		
		Items.ShiftsContextMenuOpenJob.Enabled = CommandsAvailability;
		Items.ShiftsContextMenuSetTheGeneratedStatusForTheJob.Enabled = CommandsAvailability;
		Items.ShiftsContextMenuDeleteAssignee.Enabled = CommandsAvailability
			And Form.AssignmentMode = AssignmentModeForPerformers()
			And Form.Shifts.FindByID(Items.Shifts.CurrentRow).RowType = LineTypeObject();
		
	EndIf;
	
	If AttributesStructure1.Property("FilterByArea") 
		Or Initialize Then
		
		Items.OperationsSelectionBySite.Check = Form.FilterByArea;
		
	EndIf;
	
	If Initialize Then
		
		Items.Period.Visible = Form.TheProductionScheduleIsPlanned;
		Items.OperationsStageStart.Visible = Form.TheProductionScheduleIsPlanned;
		Items.OperationsStageEnd.Visible = Form.TheProductionScheduleIsPlanned;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpandAllTreeRows()
	
	For Each String In Shifts.GetItems() Do
		
		Items.Shifts.Expand(String.GetID());
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ConfigureOperationSelection()
	
	Source = Items.Shifts.CurrentData;
	HasSource = Source <> Undefined;
	
	//
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"AssignNotEarlierThan",
		?(HasSource, Source.Date, Undefined),
		DataCompositionComparisonType.LessOrEqual,,
		HasSource And DisplayMode = ViewingModeCanBeAssigned());
	
	//
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"AssignmentIsAllowed",
		True,
		DataCompositionComparisonType.Equal,,
		DisplayMode = ViewingModeCanBeAssigned());
	
	//
	
	Value = Undefined;
	TypeOfDCSComparison = DataCompositionComparisonType.Equal;
	
	If DisplayMode = ViewAllToDestinationMode() Then
		Value = PredefinedValue("Document.ShiftTask.EmptyRef");
	ElsIf DisplayMode = ViewModeAssigned() Then
		If HasSource Then
			Value = Source.ShiftTask;
		Else
			Value = PredefinedValue("Document.ShiftTask.EmptyRef");
			TypeOfDCSComparison = DataCompositionComparisonType.Filled;
		EndIf;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"ShiftTask",
		Value,
		TypeOfDCSComparison,,
		Value <> Undefined);
	
	//
	
	FilterByObject = HasSource
		And DisplayMode = ViewModeAssigned()
		And (Source.RowType = LineTypeObject()
			Or Source.RowType = StringTypeObjectNotAssigned());
	
	//
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"Performer",
		?(HasSource, Source.RelatedObject, Undefined),
		DataCompositionComparisonType.Equal,,
		FilterByObject And AssignmentMode = AssignmentModeForPerformers());
		
	//
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"WorkCenter",
		?(HasSource, Source.RelatedObject, Undefined),
		DataCompositionComparisonType.Equal,,
		FilterByObject And AssignmentMode = AssignmentModeForWorkCenters());
		
	//
	
	Value = Undefined;
	TypeOfDCSComparison = DataCompositionComparisonType.Equal;
	
	If FilterByObject And AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
		
		Value = Source.RelatedObject;
		
	ElsIf HasSource
		And Source.RowType = LineTypeObject()
		And (DisplayMode = ViewingModeCanBeAssigned()
			Or DisplayMode = ViewAllToDestinationMode())
		And (AssignmentMode = AssignmentModeForWorkCenters()
			Or AssignmentMode = ModeOfAssignmentToTypesOfRC()) Then
		
		Value = New ValueList;
		Value.Add(Source.WorkCenterType);
		Value.Add(PredefinedValue("Catalog.WorkCenterTypes.EmptyRef"));
		Value.Add(PredefinedValue("Catalog.WorkCenters.EmptyRef"));
		Value.Add(Undefined);
		
		TypeOfDCSComparison = DataCompositionComparisonType.InList;
		
	EndIf;
		
	CommonClientServer.SetDynamicListFilterItem(
		Operations,
		"WorkCenterType",
		Value,
		TypeOfDCSComparison,,
		Value <> Undefined);
	
	//
	
	SetSelectionBySite = FilterByArea
		And HasSource
		And Not Source.ProductionArea.IsEmpty()
		And (DisplayMode = ViewingModeCanBeAssigned()
			Or DisplayMode = ViewAllToDestinationMode());
	
	Operations.Parameters.SetParameterValue("FilterByArea", SetSelectionBySite);
	
	Operations.Parameters.SetParameterValue("ProductionArea",
		?(SetSelectionBySite, Source.ProductionArea, Undefined));
		
	Operations.Parameters.SetParameterValue("BeginOfPeriod", StartDate);
	Operations.Parameters.SetParameterValue("EndOfPeriod", EndDate);
	Operations.Parameters.SetParameterValue("TheProductionScheduleIsPlanned", TheProductionScheduleIsPlanned);
	
EndProcedure

&AtClient
Function CacheExpandedTreeLines()
	
	StringCache = New Array;
	
	For Each String In Shifts.GetItems() Do
		
		If Items.Shifts.Expanded(String.GetID()) Then
			
			StringCache.Add(String.ShiftTask);
			
		EndIf;
		
	EndDo;
	
	Return StringCache;
	
EndFunction

&AtClient
Procedure ExpandTreeRowsFromCache(StringCache)
	
	For Each String In Shifts.GetItems() Do
		
		If StringCache.Find(String.ShiftTask) <> Undefined Then
			
			Items.Shifts.Expand(String.GetID());
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function CacheCurTreeLine()
	
	If Items.Shifts.CurrentRow = Undefined Then
		Return Undefined;
	EndIf;
	
	CurLineData = Shifts.FindByID(Items.Shifts.CurrentRow);
	
	CacheCurLines = New Structure;
	CacheCurLines.Insert("ShiftTask", CurLineData.ShiftTask);
	
	If CurLineData.RowType = LineTypeObject() Then
		
		CacheCurLines.Insert("RelatedObject", CurLineData.RelatedObject);
		
	ElsIf CurLineData.RowType = StringTypeObjectNotAssigned()
		Or CurLineData.RowType = LineTypeNewArtist() Then
		
		CacheCurLines.Insert("RowType", CurLineData.RowType);
		
	EndIf;
	
	Return CacheCurLines;
	
EndFunction

&AtServer
Procedure SetCurTreeStringFromCache(CacheCurLines, Tree)
	
	If CacheCurLines = Undefined Then
		Return;
	EndIf;
	
	LineChange = Tree.Rows.Find(CacheCurLines.ShiftTask, "ShiftTask");
	If LineChange <> Undefined Then
		
		ShiftIndex = Tree.Rows.IndexOf(LineChange);
		
		If CacheCurLines.Count() = 1 Then
			
			Items.Shifts.CurrentRow = Shifts.GetItems()[ShiftIndex].GetID();
			
		Else
			
			DescendantString = Undefined;
			If CacheCurLines.Property("RelatedObject") Then
				DescendantString = LineChange.Rows.Find(CacheCurLines.RelatedObject, "RelatedObject");
			ElsIf CacheCurLines.Property("RowType") Then
				DescendantString = LineChange.Rows.Find(CacheCurLines.RowType, "RowType");
			EndIf;
			
			If DescendantString <> Undefined Then
				
				DescendantIndex = LineChange.Rows.IndexOf(DescendantString);
				Items.Shifts.CurrentRow = Shifts.GetItems()[ShiftIndex].GetItems()[DescendantIndex].GetID();
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpListOfShiftTasks()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	
	If Parameters.FilterByStep.IsEmpty() Then
		
		ListProperties.QueryText = 
			"SELECT
			|	DocumentOverridable.Ref        AS Ref,
			|	DocumentOverridable.Number         AS Number,
			|	DocumentOverridable.Date          AS Date,
			|	DocumentOverridable.Status        AS Status,
			|	DocumentOverridable.Department AS Department,
			|	DocumentOverridable.ProductionArea       AS ProductionArea,
			|	DocumentOverridable.Shift         AS Shift,
			|	DocumentOverridable.EmployeeResponsible AS EmployeeResponsible,
			|	DocumentOverridable.Comment   AS Comment
			|FROM
			|	Document.ShiftTask AS DocumentOverridable";
		
		Common.SetDynamicListProperties(Items.ShiftJobs, ListProperties);
		
	Else
		
		ListProperties.QueryText = 
			"SELECT
			|	DocumentOverridable.Ref        AS Ref,
			|	DocumentOverridable.Number         AS Number,
			|	DocumentOverridable.Date          AS Date,
			|	DocumentOverridable.Status        AS Status,
			|	DocumentOverridable.Department AS Department,
			|	DocumentOverridable.ProductionArea       AS ProductionArea,
			|	DocumentOverridable.Shift         AS Shift,
			|	DocumentOverridable.EmployeeResponsible AS EmployeeResponsible,
			|	DocumentOverridable.Comment   AS Comment
			|FROM
			|	Document.ShiftTask AS DocumentOverridable
			|WHERE
			|	(TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			InformationRegister.OperationsToCreateShiftTasks AS Operations
			|		WHERE
			|			Operations.ShiftTask = DocumentOverridable.Ref
			|			AND Operations.Stage = &Stage)
			|	OR TRUE IN
			|		(SELECT TOP 1
			|			TRUE
			|		FROM
			|			Document.ProductionOperation2_2 AS Operations
			|		WHERE
			|			Operations.ShiftTask = DocumentOverridable.Ref
			|			AND Operations.Stage = &Stage
			|			AND Operations.Posted))";
			
		Common.SetDynamicListProperties(Items.ShiftJobs, ListProperties);
		
		ShiftJobs.Parameters.SetParameterValue("Stage", Parameters.FilterByStep);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Read

&AtServer
Procedure FillOutShifts()
	
	ActivateLine = Items.Shifts.CurrentRow = Undefined;
	
	Shifts.GetItems().Clear();
	SelectConfigureShiftCompositionButton();
	
	If Department.IsEmpty() Or ShiftContent.Count() = 0 Then
		Return;
	EndIf;
	
	SeveralShiftsInDepartment = ProductionServer.DivisionWorkSchedules(Department).Count() > 1;
	
	// Reading the composition of shifts
	Query = New Query(QueryTextShifts());
	Query.SetParameter("Department", Department);
	Query.SetParameter("Jobs", ShiftContent.UnloadValues());
	Query.SetParameter("AssignPerformers_3", AssignmentMode = AssignmentModeForPerformers());
	Query.SetParameter("AssignToWorkCenters", AssignmentMode = AssignmentModeForWorkCenters());
	Query.SetParameter("ToAssignTheTypesOfRTS", AssignmentMode = ModeOfAssignmentToTypesOfRC());
	
	QueryResult = Query.Execute();
	
	SampleResults = QueryResult.Select(QueryResultIteration.ByGroups);
	If Not SampleResults.Next() Then
		Return;
	EndIf;
	NWSampling = SampleResults.Select(QueryResultIteration.ByGroups);
	
	ShiftTable = QueryResult.Unload();
	
	
	// Reading the schedule
	AllCharts = CommonClientServer.CollapseArray(ShiftTable.UnloadColumn("Shift"));
	AllLinks = Undefined;
	RCCharts = Undefined;
	If AssignmentMode <> AssignmentModeForPerformers() Then
		AllLinks = CommonClientServer.CollapseArray(ShiftTable.UnloadColumn("RelatedObject"));
		RCCharts = ProductionServer.WorkCenterSchedules(AllLinks, AssignmentMode = AssignmentModeForWorkCenters());
		RCCharts.Indexes.Add("Ref, WorkScheduleCalendar");
		RCCharts.Indexes.Add("Ref");
		CommonClientServer.SupplementArray(AllCharts, RCCharts.UnloadColumn("WorkScheduleCalendar"), True);
	EndIf;
	
	Schedule = ProductionPlanning.ScheduleOfWorkOnSchedule(
		AllCharts,
		BegOfDay(SampleResults.DateMin),
		EndOfDay(SampleResults.Date));
	Schedule.Indexes.Add("ScheduleDate, WorkScheduleCalendar");
	TheStructureOfTheSearch1 = New Structure("ScheduleDate, WorkScheduleCalendar");
	
	CompositionOfVRC = Undefined;
	TheStructureOfTheSearch2 = Undefined;
	If AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
		Query = New Query(
			"SELECT
			|	WorkCenterTypes.Ref AS RelatedObject,
			|	WorkCenters.ProductionArea     AS ProductionArea,
			|	ISNULL(WorkCenters.Ref, VALUE(Catalog.WorkCenters.EmptyRef)) AS WorkCenter
			|FROM
			|	Catalog.WorkCenterTypes AS WorkCenterTypes
			|		INNER JOIN Catalog.WorkCenters AS WorkCenters
			|		ON WorkCenterTypes.Ref = WorkCenters.WorkCenterType
			|			AND (WorkCenters.DeletionMark = FALSE)
			|WHERE
			|	WorkCenterTypes.Ref IN(&References)");
		Query.SetParameter("References", AllLinks);
		CompositionOfVRC = Query.Execute().Unload();
		CompositionOfVRC.Indexes.Add("RelatedObject, ProductionArea");
		TheStructureOfTheSearch2 = New Structure("RelatedObject, ProductionArea");
	EndIf;
	
	ShiftsWithEmployees = New Array;
	
	// Filling in the tree
	Tree = FormAttributeToValue("Shifts");
	While NWSampling.Next() Do
		
		// Line - change
		LineChange = Tree.Rows.Add();
		
		FillPropertyValues(LineChange, NWSampling, "ShiftTask, Date, ProductionArea, OperationsCount");
		
		LineChange.RowType = LineTypeChange();
		LineChange.RelatedObject = NWSampling.ShiftTask;
		
		LineChange.ObjectPresentation = ProductionManagementClientServer.ShiftTaskPresentation_(
			NWSampling.Shift, NWSampling.Date, NWSampling.ProductionArea, SeveralShiftsInDepartment);
		
		// Duration
		TheStructureOfTheSearch1.ScheduleDate = BegOfDay(NWSampling.Date);
		TheStructureOfTheSearch1.WorkScheduleCalendar = NWSampling.Shift;
		ShiftSchedule = Schedule.FindRows(TheStructureOfTheSearch1);
		
		SumOfSeconds = 0;
		For Each String In ShiftSchedule Do
			SumOfSeconds = SumOfSeconds + String.Duration;
		EndDo;
		
		LineChange.Duration = Round(
			ProductionPlanningClientServer.GetTimeInUnit(
				SumOfSeconds,
				Enums.TimeMeasureUnits.Hour),
			1);
		
		// Presentation
		FillInShiftRowPresentation(LineChange);
		
		Selection = NWSampling.Select();
		While Selection.Next() Do
			
			If Selection.OperationsCount = 0 And Selection.RelatedObject.IsEmpty() Then
				Continue;
			EndIf;
			
			// String - destination object
			StringObject = LineChange.Rows.Add();
			
			FillPropertyValues(StringObject, Selection, "ShiftTask, Date, ProductionArea, RelatedObject, WorkCenterType, OperationsCount");
			
			If Selection.RelatedObject.IsEmpty() Then
				StringObject.RowType = StringTypeObjectNotAssigned();
				StringObject.ObjectPresentation = ?(AssignmentMode = AssignmentModeForPerformers(),
					NStr("vi = '<người thực hiện không được chỉ định>';
						|ru = '<исполнитель не назначен>';
						|en = '<no assignee>'; fa = '<no assignee>';
						|it = '<l''esecutore non è stato assegnato>';
						|pl = '<nie wyznaczono wykonawcy>';
						|tr = '<atanan atanmadı>'"),
					?(AssignmentMode = AssignmentModeForWorkCenters(),
						NStr("vi = '<chưa chỉ định nguồn lực sản xuất>';
							|ru = '<рабочий центр не назначен>';
							|en = '<work center is not specified>'; fa = '<work center is not specified>';
							|it = '<centro di lavoro non è assegnato>';
							|pl = '<nie wyznaczono centrum pracy>';
							|tr = '<iş merkezi atanmadı>'"),
						NStr("vi = '<chưa chỉ định dạng nguồn lực sản xuất>';
							|ru = '<вид РЦ не назначен>';
							|en = '<work center type is not specified>'; fa = '<work center type is not specified>';
							|it = '<il tipo dei centri di lavoro non è assegnato>';
							|pl = '<nie wyznaczono rodzaju centrum pracy>';
							|tr = '<İM türü atanmadı>'")));
			Else
				StringObject.RowType = LineTypeObject();
				StringObject.ObjectPresentation = Selection.ObjectPresentation;
				
				If AssignmentMode = AssignmentModeForPerformers() Then
					StringObject.Duration = LineChange.Duration;
					
					
				Else
					
					If AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
						
						FillPropertyValues(TheStructureOfTheSearch2, Selection, "RelatedObject, ProductionArea");
						CompositionLines = CompositionOfVRC.FindRows(TheStructureOfTheSearch2);
						For Each String In CompositionLines Do
							StringObject.Duration = StringObject.Duration
								+ CalculateDuration_(
									String.WorkCenter,
									RCCharts,
									Schedule,
									NWSampling.Shift,
									LineChange.Duration,
									BegOfDay(NWSampling.Date),
									ShiftSchedule);
						EndDo;
						
					Else
						
						StringObject.Duration = CalculateDuration_(
							Selection.RelatedObject,
							RCCharts,
							Schedule,
							NWSampling.Shift,
							LineChange.Duration,
							BegOfDay(NWSampling.Date),
							ShiftSchedule);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			StringObject.Load = Round(
				ProductionPlanningClientServer.GetTimeInUnit(
					Selection.LoadSeconds,
					Enums.TimeMeasureUnits.Hour),
				1);
			StringObject.AvailableForInventoryAllocation = ?(StringObject.Duration > StringObject.Load,
				StringObject.Duration - StringObject.Load, 0);
			
			LineChange.Load = LineChange.Load + StringObject.Load;
			LineChange.AvailableForInventoryAllocation = LineChange.AvailableForInventoryAllocation + StringObject.AvailableForInventoryAllocation;
			
			FillInShiftRowPresentation(StringObject);
			
		EndDo;
		
		// Line - add performers
		If AssignmentMode = AssignmentModeForPerformers() Then
			
			StringCommand = LineChange.Rows.Add();
			
			FillPropertyValues(StringCommand, NWSampling, "ShiftTask, Date, ProductionArea");
			
			StringCommand.RowType = LineTypeNewArtist();
			StringCommand.Action = NStr("vi = '<thêm người thực hiện>';
										|ru = '<добавить исполнителей>';
										|en = '<add assignees>'; fa = '<add assignees>';
										|it = '<aggiungere esecutori>';
										|pl = '<dodaj wykonawców>';
										|tr = '<atanan ekle>'");
			
		EndIf;
		
	EndDo;
	
	
	ValueToFormAttribute(Tree, "Shifts");
	SelectConfigureShiftCompositionButton();
	
	If ActivateLine And Tree.Rows.Count() <> 0 Then
		Items.Shifts.CurrentRow = Shifts.GetItems()[0].GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateShiftsAfterAssigningOperations(ArrayOfShifts)
	
	If ArrayOfShifts.UBound() = -1 Then
		Return;
	EndIf;
	
	CacheCurLines = CacheCurTreeLine();
	
	Tree = FormAttributeToValue("Shifts");
	
	// The sample changes
	Query = New Query(TextOfShiftUpdateRequest());
	Query.SetParameter("Jobs", ArrayOfShifts);
	Query.SetParameter("AssignPerformers_3", AssignmentMode = AssignmentModeForPerformers());
	Query.SetParameter("AssignToWorkCenters", AssignmentMode = AssignmentModeForWorkCenters());
	Query.SetParameter("ToAssignTheTypesOfRTS", AssignmentMode = ModeOfAssignmentToTypesOfRC());
	
	CompositionOfTasks = Query.Execute().Unload();
	CompositionOfTasks.Indexes.Add("ShiftTask, RelatedObject");
	TheStructureOfTheSearch = New Structure("ShiftTask, RelatedObject");
	
	CompleteRecalculation = False;
	
	For Each ShiftTask In ArrayOfShifts Do
		
		// Updating the shift line
		LineChange = Tree.Rows.Find(ShiftTask, "ShiftTask");
		
		If LineChange = Undefined Then
			Continue;
		EndIf;
		
		LineChange.OperationsCount = 0;
		LineChange.Load = 0;
		LineChange.AvailableForInventoryAllocation = 0;
		
		CountObjects = 0;
		
		For Each StringObject In LineChange.Rows Do
			
			If StringObject.RowType = LineTypeNewArtist() Then
				Continue;
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, StringObject);
			FoundRows = CompositionOfTasks.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.UBound() = -1 Then
				
				StringObject.OperationsCount = 0;
				StringObject.Load = 0;
				StringObject.AvailableForInventoryAllocation = StringObject.Duration;
				StringObject.LaborGradeJobTitleMismatch = False;
				
				LineChange.AvailableForInventoryAllocation = LineChange.AvailableForInventoryAllocation + StringObject.AvailableForInventoryAllocation;
				
			Else
				
				StringObject.OperationsCount = FoundRows[0].OperationsCount;
				StringObject.Load = Round(
					ProductionPlanningClientServer.GetTimeInUnit(
						FoundRows[0].LoadSeconds,
						Enums.TimeMeasureUnits.Hour),
					1);
				StringObject.AvailableForInventoryAllocation = ?(StringObject.Duration > StringObject.Load,
					StringObject.Duration - StringObject.Load, 0);
				
				LineChange.OperationsCount = LineChange.OperationsCount + StringObject.OperationsCount;
				LineChange.Load = LineChange.Load + StringObject.Load;
				LineChange.AvailableForInventoryAllocation = LineChange.AvailableForInventoryAllocation + StringObject.AvailableForInventoryAllocation;
				
				CountObjects = CountObjects + 1;
				
			EndIf;
			
			FillInShiftRowPresentation(StringObject);
			
		EndDo;
		
		If CountObjects <> CompositionOfTasks.FindRows(New Structure("ShiftTask", ShiftTask)).Count() Then
			
			CompleteRecalculation = True;
			Break;
			
		Else
			
			FillInShiftRowPresentation(LineChange);
			
			StringObjectNotAssigned = LineChange.Rows.Find(StringTypeObjectNotAssigned(), "RowType");
			If StringObjectNotAssigned <> Undefined
				And StringObjectNotAssigned.OperationsCount = 0 Then
				
				LineChange.Rows.Delete(StringObjectNotAssigned);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If CompleteRecalculation Then
		
		FillOutShifts();
		
		SetCurTreeStringFromCache(CacheCurLines, FormAttributeToValue("Shifts"));
		
	Else
		
		
		ValueToFormAttribute(Tree, "Shifts");
		
		SetCurTreeStringFromCache(CacheCurLines, Tree);
		
	EndIf;
	
EndProcedure

&AtServer
Function QueryTextShifts()
	
	Result =
		"SELECT
		|	NestedQuery.ShiftTask            AS ShiftTask,
		|	NestedQuery.Shift                     AS Shift,
		|	NestedQuery.Date                      AS DateMin,
		|	NestedQuery.Date                      AS Date,
		|	NestedQuery.ProductionArea                   AS ProductionArea,
		|	NestedQuery.RelatedObject          AS RelatedObject,
		|	NestedQuery.ObjectPresentation      AS ObjectPresentation,
		|	NestedQuery.WorkCenterType         AS WorkCenterType,
		|	SUM(NestedQuery.OperationsCount) AS OperationsCount,
		|	SUM(NestedQuery.LoadSeconds)    AS LoadSeconds
		|FROM
		|	(SELECT
		|		Operations.ShiftTask AS ShiftTask,
		|		Job.Shift           AS Shift,
		|		Job.Date            AS Date,
		|		Job.ProductionArea         AS ProductionArea,
		|		CASE
		|			WHEN &AssignPerformers_3
		|				THEN Operations.Performer
		|			WHEN &AssignToWorkCenters
		|				THEN Operations.WorkCenter
		|			WHEN &ToAssignTheTypesOfRTS
		|				THEN Operations.WorkCenterType
		|		END                   AS RelatedObject,
		|		CASE
		|			WHEN &AssignPerformers_3
		|				THEN Operations.Performer.Description
		|			WHEN &AssignToWorkCenters
		|				THEN Operations.WorkCenter.Description
		|			WHEN &ToAssignTheTypesOfRTS
		|				THEN Operations.WorkCenterType.Description
		|		END                   AS ObjectPresentation,
		|		CASE
		|			WHEN &AssignPerformers_3
		|				THEN UNDEFINED
		|			WHEN &AssignToWorkCenters
		|					AND Operations.WorkCenter = VALUE(Catalog.WorkCenters.EmptyRef)
		|				THEN UNDEFINED
		|			ELSE Operations.WorkCenterType
		|		END AS WorkCenterType,
		|		1                       AS OperationsCount,
		|		&OperationTime_
		|			* CASE Operations.TimeUnitsOfMeasure
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|					THEN 86400
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN 86400
		|				ELSE 1
		|			END               AS LoadSeconds
		|	FROM
		|		InformationRegister.OperationsToCreateShiftTasks AS Operations
		|			LEFT JOIN Document.ShiftTask AS Job
		|			ON Operations.ShiftTask = Job.Ref
		|	WHERE
		|		Operations.Department = &Department
		|		AND Operations.ShiftTask IN(&Jobs)
		|		AND Job.Status = VALUE(Enum.ShiftTaskStatuses.BeingGenerated)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ShiftTask.Ref,
		|		ShiftTask.Shift,
		|		ShiftTask.Date,
		|		ShiftTask.ProductionArea,
		|		ISNULL(ShiftTaskAssignees.Performer, VALUE(Catalog.Persons.EmptyRef)),
		|		ShiftTaskAssignees.Performer.Description,
		|		UNDEFINED,
		|		0,
		|		0
		|	FROM
		|		Document.ShiftTask AS ShiftTask
		|			LEFT JOIN Document.ShiftTask.Assignees AS ShiftTaskAssignees
		|			ON ShiftTask.Ref = ShiftTaskAssignees.Ref
		|	WHERE
		|		&AssignPerformers_3
		|		AND ShiftTask.Ref IN(&Jobs)
		|		AND ShiftTask.Status = VALUE(Enum.ShiftTaskStatuses.BeingGenerated)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ShiftTask.Ref,
		|		ShiftTask.Shift,
		|		ShiftTask.Date,
		|		ShiftTask.ProductionArea,
		|		ISNULL(WorkCenters.Ref, VALUE(Catalog.WorkCenters.EmptyRef)),
		|		WorkCenters.Description,
		|		WorkCenters.WorkCenterType,
		|		0,
		|		0
		|	FROM
		|		Document.ShiftTask AS ShiftTask
		|			LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
		|			ON ShiftTask.Department = WorkCenterTypes.Department
		|			LEFT JOIN Catalog.WorkCenters AS WorkCenters
		|			ON (WorkCenterTypes.Ref = WorkCenters.WorkCenterType)
		|				AND (ShiftTask.ProductionArea = WorkCenters.ProductionArea
		|					OR WorkCenters.ProductionArea = VALUE(Catalog.ProductionSites.EmptyRef))
		|				AND (WorkCenters.DeletionMark = FALSE)
		|	WHERE
		|		&AssignToWorkCenters
		|		AND ShiftTask.Ref IN(&Jobs)
		|		AND ShiftTask.Status = VALUE(Enum.ShiftTaskStatuses.BeingGenerated)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ShiftTask.Ref,
		|		ShiftTask.Shift,
		|		ShiftTask.Date,
		|		ShiftTask.ProductionArea,
		|		ISNULL(WorkCenterTypes.Ref, VALUE(Catalog.WorkCenterTypes.EmptyRef)),
		|		WorkCenterTypes.Description,
		|		WorkCenterTypes.Ref,
		|		0,
		|		0
		|	FROM
		|		Document.ShiftTask AS ShiftTask
		|			LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
		|			ON ShiftTask.Department = WorkCenterTypes.Department
		|				AND (WorkCenterTypes.DeletionMark = FALSE)
		|	WHERE
		|		&ToAssignTheTypesOfRTS
		|		AND ShiftTask.Ref IN(&Jobs)
		|		AND ShiftTask.Status = VALUE(Enum.ShiftTaskStatuses.BeingGenerated)
		|		AND (ShiftTask.ProductionArea = VALUE(Catalog.ProductionSites.EmptyRef)
		|				OR TRUE IN
		|					(SELECT TOP 1
		|						TRUE
		|					FROM
		|						Catalog.WorkCenters AS T
		|					WHERE
		|						T.WorkCenterType = WorkCenterTypes.Ref
		|						AND T.ProductionArea = ShiftTask.ProductionArea))) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Shift,
		|	NestedQuery.ShiftTask,
		|	NestedQuery.Date,
		|	NestedQuery.ProductionArea,
		|	NestedQuery.RelatedObject,
		|	NestedQuery.WorkCenterType,
		|	NestedQuery.ObjectPresentation,
		|	NestedQuery.Date
		|
		|ORDER BY
		|	Date,
		|	Shift,
		|	ProductionArea,
		|	ObjectPresentation
		|TOTALS
		|	MAX(Shift),
		|	MIN(DateMin),
		|	MAX(Date),
		|	MAX(ProductionArea),
		|	SUM(OperationsCount)
		|BY
		|	OVERALL,
		|	ShiftTask";
	
	Result = StrReplace(
		Result,
		"&OperationTime_",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("Operations"));
	
	Return Result;
	
EndFunction

&AtServer
Function TextOfShiftUpdateRequest()
	
	Result =
		"SELECT
		|	Operations.ShiftTask AS ShiftTask,
		|	CASE
		|		WHEN &AssignPerformers_3
		|			THEN Operations.Performer
		|		WHEN &AssignToWorkCenters
		|			THEN Operations.WorkCenter
		|		WHEN &ToAssignTheTypesOfRTS
		|			THEN Operations.WorkCenterType
		|	END                   AS RelatedObject,
		|	SUM(1)                AS OperationsCount,
		|	SUM(
		|		&OperationTime_
		|			* CASE Operations.TimeUnitsOfMeasure
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|					THEN 86400
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN 86400
		|				ELSE 1
		|			END
		|		)                   AS LoadSeconds
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|WHERE
		|	Operations.ShiftTask IN(&Jobs)
		|
		|GROUP BY
		|	Operations.ShiftTask,
		|	CASE
		|		WHEN &AssignPerformers_3
		|			THEN Operations.Performer
		|		WHEN &AssignToWorkCenters
		|			THEN Operations.WorkCenter
		|		WHEN &ToAssignTheTypesOfRTS
		|			THEN Operations.WorkCenterType
		|	END";
	
	Result = StrReplace(
		Result,
		"&OperationTime_",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("Operations"));
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInShiftRowPresentation(String);
	
	If String.OperationsCount = 0 Then
		String.LinePresentation = String.ObjectPresentation;
	Else
		String.LinePresentation = StrTemplate("%1 (%2)", String.ObjectPresentation, String.OperationsCount);
	EndIf;
	
EndProcedure

&AtServer
Function CalculateDuration_(Ref, Schedules, Schedule, Shift, ShiftDuration, ShiftDate, ShiftSchedule)
	
	Result = 0;
	
	If Schedules.FindRows(New Structure("Ref, WorkScheduleCalendar", Ref, Shift)).UBound() <> -1 Then
		Result = ShiftDuration;
	Else
		
		SumOfSeconds = 0;
		LinesOfGraphics = Schedules.FindRows(New Structure("Ref", Ref));
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("ScheduleDate", ShiftDate);
		
		For Each String In LinesOfGraphics Do
			
			TheStructureOfTheSearch.Insert("WorkScheduleCalendar", String.WorkScheduleCalendar);
			RCSchedule = Schedule.FindRows(TheStructureOfTheSearch);
			
			For Each Interval1 In ShiftSchedule Do
				For Each Interval2 In RCSchedule Do
					
					IntervalsIntersect = Interval2.BeginTime < Interval1.EndTime
						And Interval2.EndTime > Interval1.BeginTime;
					
					If IntervalsIntersect Then
						
						SumOfSeconds = SumOfSeconds
							+ (
								Min(Interval1.EndTime, Interval2.EndTime)
								- Max(Interval1.BeginTime, Interval2.BeginTime)
							);
						
					EndIf;
					
				EndDo;
			EndDo;
		EndDo;
		
		Result = Round(
			ProductionPlanningClientServer.GetTimeInUnit(
				SumOfSeconds,
				Enums.TimeMeasureUnits.Hour),
			1);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure UpdateShiftsOnServer()
	
	CacheCurLines = CacheCurTreeLine();
	
	FillOutShifts();
	
	SetCurTreeStringFromCache(CacheCurLines, FormAttributeToValue("Shifts"));
	
EndProcedure


#EndRegion

#Region Record

&AtClient
Function CheckGetOperationsForAssignment(Rows)
	
	If Rows.Count() = 0 Then
		
		Result = Undefined;
		
		ShowMessageBox(, NStr("vi = 'Không có thao tác nào được chọn để hoàn thành giao dịch';
								|ru = 'Не выбраны операции для выполнения действия';
								|en = 'Operations to execute the action are not selected'; fa = 'Operations to execute the action are not selected';
								|it = 'Nessuna operazione selezionata per eseguire l''azione';
								|pl = 'Nie wybrano operacji dla wykonania czynności';
								|tr = 'Eylemin gerçekleştirilmesi için herhangi bir işlem seçilmedi'"));
		
	Else
		
		Result = New Array;
		
		For Each String In Rows Do
			
			If TypeOf(String) = Type("DynamicListGroupRow") Then
				
				ShowMessageBox(, NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
										|ru = 'Действие не может быть выполнено для строки группировки списка';
										|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
										|it = 'L''operazione non può essere eseguita per la riga di raggruppamento dell''elenco';
										|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
										|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
				
				Result = Undefined;
				Break;
				
			Else
				
				Result.Add(String);
				
			EndIf;
		
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AssignOperationsToSelectedRow(OperationKeys, String)
	
	ClearMessages();
	
	ParametersStructure = CommonClientServer.CopyStructure(AssignmentParameters);
	ParametersStructure.Dimensions.ShiftTask = String.ShiftTask;
	
	If String.RowType = LineTypeNewArtist() Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Department", Department);
		FormParameters.Insert("ShiftTask", String.ShiftTask);
		FormParameters.Insert("CloseOnChoice", True);
		FormParameters.Insert("MultipleChoice", False);
		FormParameters.Insert("Date", String.Date);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Mode", "AssignmentToNewExecutor");
		AdditionalParameters.Insert("OperationKeys", OperationKeys);
		AdditionalParameters.Insert("AssignmentParameters", ParametersStructure);
		
		FormParameters.Insert("AdditionalParameters", AdditionalParameters);

		If ThereAreAreas Then
			
			If ThereAreInappropriateSections(String.ProductionArea, OperationKeys) Then 
				
				QueryText = StrTemplate(NStr("vi = 'Trong các giao dịch được chỉ định có các khu vực không tương ứng với khu vực ""%1"". Tiếp tục?';
											|ru = 'В назначаемых операциях есть участки не соответствующие участку ""%1"". Продолжить?';
											|en = 'Operations to assign contain sites that do not match the ""%1"" site. Continue?'; fa = 'Operations to assign contain sites that do not match the ""%1"" site. Continue?';
											|it = 'Nelle operazioni assegnate vi sono siti che non corrispondono al sito ""%1"". Continuare?';
											|pl = 'W przeznaczanych operacjach są obszary nie zgodne z obszarem ""%1"". Kontynuować?';
											|tr = 'Atanan işlemlerde ""%1"" sahasına karşılık gelmeyen sahalar mevcut. Devam edilsin mi?'"), String(String.ProductionArea));
				
				Mode = New ValueList;
				Mode.Add(DialogReturnCode.Yes, NStr("vi = 'Chỉ định';
													|ru = 'Назначить';
													|en = 'Assign'; fa = 'تخصیص';
													|it = 'Assegnare';
													|pl = 'Assign';
													|tr = 'Ata'"));
				Mode.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
				
				ShowQueryBox(New CallbackDescription("AssignOperationsOfOperationsToNewExecutorEnd", ThisObject, FormParameters), QueryText, Mode);
				
				Return;
				
			EndIf;
			
		EndIf;

		OpenForm("DataProcessor.GenerateShiftTasks.Form.SelectAssignees",
			FormParameters,
			ThisObject,
			UUID,,,,
			FormWindowOpeningMode.LockOwnerWindow);

	Else
		
		If String.RowType = LineTypeObject() Then
			
			If AssignmentMode = AssignmentModeForPerformers() Then
				
				ParametersStructure.Dimensions.Performer = String.RelatedObject;
				
			ElsIf AssignmentMode = AssignmentModeForWorkCenters() Then
				
				ParametersStructure.Dimensions.WorkCenter = String.RelatedObject;
				ParametersStructure.Dimensions.WorkCenterType = String.WorkCenterType;
				
			ElsIf AssignmentMode = ModeOfAssignmentToTypesOfRC() Then
				
				ParametersStructure.Dimensions.WorkCenterType = String.RelatedObject;
				
			EndIf;
		EndIf;
		
		If ThereAreAreas Then
			
			If ThereAreInappropriateSections(String.ProductionArea, OperationKeys) Then 
				
				QueryText = StrTemplate(NStr("vi = 'Trong các giao dịch được chỉ định có các khu vực không tương ứng với khu vực ""%1"". Tiếp tục?';
											|ru = 'В назначаемых операциях есть участки не соответствующие участку ""%1"". Продолжить?';
											|en = 'Operations to assign contain sites that do not match the ""%1"" site. Continue?'; fa = 'Operations to assign contain sites that do not match the ""%1"" site. Continue?';
											|it = 'Nelle operazioni assegnate vi sono siti che non corrispondono al sito ""%1"". Continuare?';
											|pl = 'W przeznaczanych operacjach są obszary nie zgodne z obszarem ""%1"". Kontynuować?';
											|tr = 'Atanan işlemlerde ""%1"" sahasına karşılık gelmeyen sahalar mevcut. Devam edilsin mi?'"), String(String.ProductionArea));
				
				Mode = New ValueList;
				Mode.Add(DialogReturnCode.Yes,NStr("vi = 'Chỉ định';
													|ru = 'Назначить';
													|en = 'Assign'; fa = 'تخصیص';
													|it = 'Assegnare';
													|pl = 'Assign';
													|tr = 'Ata'"));
				Mode.Add(DialogReturnCode.No,NStr("vi = 'Hủy bỏ';
													|ru = 'Отменить';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annullare';
													|pl = 'Cancel';
													|tr = 'İptal et'"));
				
				AddlParameters = New Structure;
				AddlParameters.Insert("OperationKeys",        OperationKeys);
				AddlParameters.Insert("ShiftTask",       String.ShiftTask);
				AddlParameters.Insert("ParametersStructure",  ParametersStructure);
				
				ShowQueryBox(New CallbackDescription("AssignOperationsCompletion", ThisObject, AddlParameters), QueryText,Mode);
				
				Return;
				
			EndIf;
			
		EndIf;
		
		StringCache = CacheExpandedTreeLines();
		
		AssignOperations(OperationKeys, String.ShiftTask, ParametersStructure);
		
		ExpandTreeRowsFromCache(StringCache);
		
		NotifyAboutChangeOfOperationsAssignment();
		
	EndIf;
	
EndProcedure

// Notification handler
&AtClient
Procedure AssignOperationsOfOperationsToNewExecutorEnd(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	OpenForm("DataProcessor.GenerateShiftTasks.Form.SelectAssignees",
		AdditionalParameters,
		ThisObject,
		UUID,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServerNoContext
Function ThereAreInappropriateSections(ProductionArea, OperationKeys)
	
	KeyOfOperations = New Array;
	For Each OperationKey In OperationKeys Do
		KeyOfOperations.Add(OperationKey.Operation);
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT TOP 1
	|	TRUE AS ThereAreOperationsOfOperationsOfAnotherSite
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.Ref IN(&Operations)
	|	AND ManufacturingOperations.ProductionArea <> VALUE(Catalog.ProductionSites.EmptyRef)
	|	AND ManufacturingOperations.ProductionArea <> &ProductionArea";
	
	Query.SetParameter("ProductionArea", ProductionArea);
	Query.SetParameter("Operations", KeyOfOperations);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Notification handler
&AtClient
Procedure AssignOperationsCompletion(QuestionResult, AdditionalParameters) Export
	
	OperationKeys = AdditionalParameters.OperationKeys;
	ShiftTask = AdditionalParameters.ShiftTask;
	ParametersStructure = AdditionalParameters.ParametersStructure;
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.No Then
		Return;
	EndIf;
	
	StringCache = CacheExpandedTreeLines();
	
	AssignOperations(OperationKeys, ShiftTask, ParametersStructure);
	
	ExpandTreeRowsFromCache(StringCache);
	
	NotifyAboutChangeOfOperationsAssignment();
	
EndProcedure

&AtServer
Procedure AssignOperations(OperationKeys, ShiftTask, ParametersStructure)
	
	InformationRegisters.OperationsToCreateShiftTasks.AssignOperations(
		OperationKeys,
		ParametersStructure);
	
	UpdateFormAfterAssigningOperations(OperationKeys, ShiftTask);
	
EndProcedure

&AtServer
Procedure AddPerformers(ShiftTask, References)
	
	CacheCurLines = CacheCurTreeLine();
	
	Tree = FormAttributeToValue("Shifts");
	
	LineChange = Tree.Rows.Find(ShiftTask, "ShiftTask");
	If LineChange = Undefined Then
		Return;
	EndIf;
	
	NewArtists = New Array;
	For Each Ref In References Do
		If LineChange.Rows.Find(Ref, "RelatedObject") = Undefined Then
			NewArtists.Add(Ref);
		EndIf;
	EndDo;
	If NewArtists.UBound() = -1 Then
		Return;
	EndIf;
	
	
	Documents.ShiftTask.AddPerformers(ShiftTask, NewArtists);
	
	For Each Ref In NewArtists Do
		
		StringObject = LineChange.Rows.Add();
		
		FillPropertyValues(StringObject, LineChange, "ShiftTask, Date, ProductionArea, Duration");
		
		StringObject.RowType = LineTypeObject();
		StringObject.RelatedObject = Ref;
		StringObject.ObjectPresentation = Ref;
		StringObject.AvailableForInventoryAllocation = StringObject.Duration;
		
		
		LineChange.AvailableForInventoryAllocation = LineChange.AvailableForInventoryAllocation + StringObject.AvailableForInventoryAllocation;
		
		FillInShiftRowPresentation(StringObject);
		
	EndDo;
	
	LineChange.Rows.Sort("RowType, ObjectPresentation");
	
	ValueToFormAttribute(Tree, "Shifts");
	
	SetCurTreeStringFromCache(CacheCurLines, Tree);
	
EndProcedure

&AtClient
Procedure DeleteCurArtist()
	
	StringObject = Items.Shifts.CurrentData;
	If StringObject = Undefined Then
		
		ShowMessageBox(, NStr("vi = 'Không có người thực hiện được chọn';
								|ru = 'Не выбран исполнитель';
								|en = 'Assignee is not selected'; fa = 'Assignee is not selected';
								|it = 'Nessun esecutore selezionato';
								|pl = 'Nie wybrano wykonawcy';
								|tr = 'Atanan seçilmedi'"));
		Return;
		
	ElsIf StringObject.Load > 0 Then
		
		ShowMessageBox(, NStr("vi = 'Nhà thầu được phân công hoạt động, không thể xóa';
								|ru = 'Исполнителю назначены операции, удаление невозможно';
								|en = 'The assignee has operations assigned. Cannot delete assignee.'; fa = 'The assignee has operations assigned. Cannot delete assignee.';
								|it = 'All''operatore sono assegnate le operazioni, la cancellazione è impossibile';
								|pl = 'Dla wykonawcy wyznaczono operacje, usunięcie jest niemożliwe';
								|tr = 'Atanana işlem atandı, silinmesi mümkün değil'"));
		Return;
		
	EndIf;
	
	DeleteArtistOnServer(StringObject.ShiftTask, StringObject.RelatedObject);
	
	LineChange = StringObject.GetParent();
	LineChange.AvailableForInventoryAllocation = LineChange.AvailableForInventoryAllocation - StringObject.AvailableForInventoryAllocation;
	
	LineChange.GetItems().Delete(StringObject);
	
EndProcedure

&AtServerNoContext
Procedure DeleteArtistOnServer(ShiftTask, Ref)
	
	Documents.ShiftTask.DeleteAssignee(ShiftTask, Ref);
	
EndProcedure

&AtServer
Procedure DeleteOperationsOnServer(OperationKeys)
	
	InformationRegisters.OperationsToCreateShiftTasks.DeleteKeyOperations(OperationKeys);
	
	UpdateFormAfterAssigningOperations(OperationKeys, Documents.ShiftTask.EmptyRef());
	
EndProcedure

&AtServer
Procedure UpdateFormAfterAssigningOperations(OperationKeys, ShiftTask)
	
	ArrayOfShifts = New Array;
	
	If Not ShiftTask.IsEmpty()
		And ArrayOfShifts.Find(ShiftTask) = Undefined
		And ShiftContent.FindByValue(ShiftTask) <> Undefined Then
		
		ArrayOfShifts.Add(ShiftTask);
		
	EndIf;
	
	For Each Var_Key In OperationKeys Do
		
		If Not Var_Key.ShiftTask.IsEmpty()
			And ArrayOfShifts.Find(Var_Key.ShiftTask) = Undefined
			And ShiftContent.FindByValue(Var_Key.ShiftTask) <> Undefined Then
			
			ArrayOfShifts.Add(Var_Key.ShiftTask);
			
		EndIf;
	EndDo;
	
	UpdateShiftsAfterAssigningOperations(ArrayOfShifts);
	
EndProcedure

&AtServer
Function SetStatusInBackground(Ref)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Ref", Ref);
	ProcedureParameters.Insert("Status", Enums.ShiftTaskStatuses.Generated_);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Đặt trạng thái của một công việc thay đổi';
			|ru = 'Установка статуса сменному заданию';
			|en = 'Set status for shift task'; fa = 'Set status for shift task';
			|it = 'Impostazione dello stato del task di turno';
			|pl = 'Ustawienie statusu dla zadania zmianowego';
			|tr = 'Vardiyalı göreve durumun yapılandırılması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ShiftTask.SetStatusInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartWaiting = True;
		
	Else
		
		ProcessResultOfSettingStatusInBackground(TimeConsumingOperation, Ref);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtServer
Procedure ProcessResultOfSettingStatusInBackground(Result, Ref)
	
	If Result.Status = "Error" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(ResultStructure) = Type("Structure") And ResultStructure.Property("Messages") Then
			
			For Each Message In ResultStructure.Messages Do
			
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
		Raise Result.BriefErrorDescription;
		
	Else
		
		ShiftContent.Delete(ShiftContent.FindByValue(Ref));
		
		FillOutShifts();
		
		Items.Operations.Refresh();
	
		Items.ShiftJobs.Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Constants

&AtClientAtServerNoContext
Function LineTypeChange()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function StringTypeObjectNotAssigned()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeObject()
	
	Return 3;
	
EndFunction

&AtClientAtServerNoContext
Function LineTypeNewArtist()
	
	Return 4;
	
EndFunction

&AtClientAtServerNoContext
Function AssignmentModeForPerformers()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function AssignmentModeForWorkCenters()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function ModeOfAssignmentToTypesOfRC()
	
	Return 3;
	
EndFunction

&AtClientAtServerNoContext
Function ViewingModeCanBeAssigned()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function ViewAllToDestinationMode()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function ViewModeAssigned()
	
	Return 3;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure LoadSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		"DataProcessor.GenerateShiftTasks.WorkplaceSettings",
		Undefined);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		Settings.Property("Department",   Department);
		Settings.Property("ProductionArea",         ProductionArea);
		Settings.Property("AssignmentMode", AssignmentMode);
		Settings.Property("DisplayMode",  DisplayMode);
		Settings.Property("FilterByArea",  FilterByArea);
	
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ShouldSaveSettings(Form)
	
	Settings = New Structure;
	
	Settings.Insert("Department",   Form.Department);
	Settings.Insert("ProductionArea",         Form.ProductionArea);
	Settings.Insert("AssignmentMode", Form.AssignmentMode);
	Settings.Insert("DisplayMode",  Form.DisplayMode);
	Settings.Insert("FilterByArea",  Form.FilterByArea);
	
	WriteSettingsToStorage(Settings);
	
EndProcedure

&AtServerNoContext
Procedure WriteSettingsToStorage(Settings)
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.GenerateShiftTasks.WorkplaceSettings",
		Undefined,
		Settings);
	
EndProcedure

&AtServer
Procedure SaveSettingsAndFillShifts()
	
	ShouldSaveSettings(ThisObject);
	
	FillOutShifts();
	
EndProcedure

&AtClient
Procedure ShowWarningShiftNotSelected()
	
	ShowMessageBox(, NStr("vi = 'Không có ca làm việc được chọn';
							|ru = 'Не выбрана смена для назначения';
							|en = 'Shift for assignment not selected'; fa = 'Shift for assignment not selected';
							|it = 'Nessun turno selezionato per l''assegnazione';
							|pl = 'Nie wybrano zmiany do przeznaczenia';
							|tr = 'Atama için vardiya seçilmedi'"));
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.ShiftJobs.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ShiftTask.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtServer
Procedure SelectConfigureShiftCompositionButton()
	
	Items.ConfigureTheCompositionOfShifts.BackColor = ?(Shifts.GetItems().Count() > 0,
		New Color,
		New Color(253, 250, 165));
	
EndProcedure

&AtClient
Procedure NotifyAboutChangeOfOperationsAssignment()
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Department);
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		NotificationSource = FormOwner.UUID;
	Else
		NotificationSource = UUID;
	EndIf;
	
	Notify("Write_OperationsToCreateShiftTasks", NotificationParameter1, NotificationSource);
	
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
	If Item.Name = "sh_ShamsiInput_F_StartDate" Then
		StartDateOnChange(Items.StartDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndDate" Then
		EndDateOnChange(Items.EndDate);
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
