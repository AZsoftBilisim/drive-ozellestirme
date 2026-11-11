#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Department", Department) Then
		ReadDivisionParameters();
	EndIf;
	
	InitializeCache();
	
	SetTypeOfWorkCenter(ThisObject);
	SetArtistType();
	
	SetPropertiesOfDynamicListPerformOperations();
	
	States1.LoadValues(StatesIncomplete(ThisObject));
	SetSelectionByState(ThisObject);
	
	SetSelectionByDivisionSection();
	SetSelectionByWorkCenter();
	
	SetSelectionByStages(Parameters.FilterByStages);
	
	CustomizeFormElements();
	
	InformationRegisters.JobsForCalculatingProductionOperationQueue.StartJobs();
	
	#Region StandardMechanisms
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisObject);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription("DocumentRef.ProductionOperation2_2");
	PlacementParameters.CommandBar = Items.ExecutionOfOperations.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
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
	
	If (EventName = "Write_ProductionOperation2_2"
			Or EventName = "Write_ProductionStages"
			Or EventName = "Write_ShiftTask"
			Or EventName = "Write_QueueOfProductionOperations"
			Or EventName = "Write_OperationsToCreateShiftTasks") Then
		
		UpdateList = True;
		
		If TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("Department")
			And Parameter.Department <> Department Then
			
			UpdateList = False;
			
		EndIf;
		
		If UpdateList Then
			
			UpdateTheListOnServer();
			
		EndIf;
		
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
		
		FillInServiceAttributesOfWorkCenter();
		
		DivisionWhenChangedOnServer(True);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
Procedure FilterDepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer(False);
	
EndProcedure

&AtClient
Procedure FilterProductionAreaOnChange(Item)
	
	PlotWhenChangedOnServer(False);
	
EndProcedure

&AtClient
Procedure FilterTypeWorkCenterOnChange(Item)
	
	If ValueIsFilled(WorkCenter) Then
		SelectionValueBeforeChange = WorkCenter;
	Else
		SelectionValueBeforeChange = Undefined;
	EndIf;
	
	SetTypeOfWorkCenter(ThisObject);
	
	If SelectionValueBeforeChange <> Undefined
		And SelectionValueBeforeChange <> WorkCenter Then
		WorkCenterWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterWorkCenterOnChange(Item)
	
	WorkCenterWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure FilterSetupSettingsOnChange(Item)
	
	SetSelectionByAdjustmentOption(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterPerformerOnChange(Item)
	
	ExecutorWhenChangeIsMadeOnServer();
	
EndProcedure

&AtClient
Procedure FilterPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
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
Procedure FilterPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FilterShiftOnChange(Item)
	
	SetSelectionForShiftTask(ThisObject);
	
EndProcedure

&AtClient
Procedure QuickSelection_UnfinishedClick(Item)
	
	If OnlyIncompleteStates(ThisObject) Then
		States1.Clear();
	Else
		States1.LoadValues(StatesIncomplete(ThisObject));
	EndIf;
	SetSelectionByState(ThisObject, QuickSelectionsListIncomplete());
	
EndProcedure

&AtClient
Procedure QuickSelection_CompletedClick(Item)
	
	If OnlyCompletedStates(ThisObject) Then
		States1.Clear();
	Else
		States1.LoadValues(StatesCompleted(ThisObject));
	EndIf;
	SetSelectionByState(ThisObject, QuickSelectionsListIncomplete());
	
EndProcedure

&AtClient
Procedure QuickSelection_Tap(Item)
	
	SwitchQuickSelection(ThisObject, Item.Name);
	
EndProcedure

&AtClient
Procedure QuickSelection_AllClick(Item)
	
	States1.Clear();
	
	SetSelectionByState(ThisObject, QuickSelectionsListAll());
	
EndProcedure

&AtClient
Procedure InfoMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "DisableStageSelection" Then
		
		StandardProcessing = False;
		SetSelectionByStages();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransitionRoutesOperationsClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("DepartmentFilter", Department);
	
	StepFilter = CurrentStageSelection(ThisObject);
	If StepFilter <> Undefined Then
		FormParameters.Insert("StepFilter", StepFilter);
	EndIf;
	
	OpenForm("Document.ProductionOperation2_2.ListForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure TransitionControlOfOperationsClick(Item)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("FilterTypeDepartment", FilterTypeDepartment);
	FormParameters.Insert("FilterTypeWorkCenter",  FilterTypeWorkCenter);
	FormParameters.Insert("Department",          Department);
	FormParameters.Insert("ProductionArea",                ProductionArea);
	FormParameters.Insert("WorkCenter",           WorkCenter);
	
	StepFilter = CurrentStageSelection(ThisObject);
	If StepFilter <> Undefined Then
		FormParameters.Insert("Stage", StepFilter);
	EndIf;
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.OperationExecutionControl", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExecutionOfOperations

&AtClient
Procedure ExecutionOfOperationsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ExecutionOfOperationsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		If StrFind("ExecutionOfOperationsOperation,ExecutionOfOperationsNameOfTheOperation,ExecutionOfOperationsProductionOperationNumber", Field.Name) > 0 Then
			If ValueIsFilled(CurrentData.ProductionOperation) Then
				ShowValue(, CurrentData.ProductionOperation);
			ElsIf ValueIsFilled(CurrentData.Operation) Then
				ShowValue(, CurrentData.Operation);
			EndIf;
		ElsIf StrFind("ExecutionOfOperationsStage,ExecutionOfOperationsPresentationStage", Field.Name) > 0 Then
			ShowValue(, CurrentData.Stage);
		ElsIf StrFind("ExecutionOfOperationsShiftTaskDate", Field.Name) > 0 Then
			If ValueIsFilled(CurrentData.ShiftTask) Then
				ShowValue(, CurrentData.ShiftTask);
			EndIf;
		ElsIf StrFind("ExecutionOfOperationsReferenceOrder", Field.Name) > 0 Then
			ShowValue(, CurrentData.ReferenceOrder);
		ElsIf StrFind("ExecutionOfOperationsProducts,ExecutionOfOperationsCharacteristic", Field.Name) > 0 Then
			ShowValue(, CurrentData.Products);
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ExecutionOfOperationsOnGetDataAtServer(TagName, Settings, Rows)
	
	TransactionTable = New ValueTable;
	TransactionTable.Columns.Add("LineNumber", New TypeDescription("Number"));
	TransactionTable.Columns.Add("ListLine");
	TransactionTable.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	TransactionTable.Columns.Add("Operation", New TypeDescription("CatalogRef.ManufacturingOperations"));
	TransactionTable.Columns.Add("OperationID", New TypeDescription("Number"));
	TransactionTable.Columns.Add("ProductionOperation", New TypeDescription("DocumentRef.ProductionOperation2_2"));
	TransactionTable.Columns.Add("StatusText_3", New TypeDescription("String"));
	
	For Each KeyAndValue In Rows Do
		RowData = KeyAndValue.Value.Data;
		If RowData.State = Enums.OperationStates.ToAssign
				Or RowData.State = Enums.OperationStates.PendingPredecessorCompletion
				Or RowData.State = Enums.OperationStates.Executed Then
			NewRow = TransactionTable.Add();
			FillPropertyValues(NewRow, RowData);
			NewRow.LineNumber  = TransactionTable.Count() -1;
			NewRow.ListLine = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	If TransactionTable.Count() = 0 Then
		Return;
	EndIf;
	
	If Settings.AdditionalProperties.UseShiftTasks Then
		
		QueryText = "
		|SELECT
		|	Operations.LineNumber              AS LineNumber,
		|	Operations.Stage                     AS Stage,
		|	Operations.Operation                 AS Operation,
		|	Operations.OperationID    AS OperationID,
		|	Operations.ProductionOperation AS ProductionOperation
		|INTO TTOperations
		|FROM
		|	&Operations AS Operations
		|
		|INDEX BY
		|	Stage,
		|	Operation,
		|	OperationID
		|;
		|
		|SELECT
		|	Operations.LineNumber AS LineNumber
		|FROM
		|	TTOperations AS Operations
		|WHERE
		|	TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.OperationsToCreateShiftTasks AS Register
		|		WHERE
		|			Register.Department = &Department
		|			AND Register.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|			AND Operations.Stage = Register.Stage
		|			AND Operations.Operation = Register.Operation
		|			AND Operations.OperationID = Register.OperationID)
		|";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Operations", TransactionTable);
		Query.SetParameter("Department", Settings.AdditionalProperties.Department);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			TableRow = TransactionTable[Selection.LineNumber];
			If Not ValueIsFilled(TableRow.ProductionOperation) Then
				ListLine  = TableRow.ListLine;
				TableRow.StatusText_3 = StrTemplate(NStr("vi = '%1 (đã ấn định)';
														|ru = '%1 (уже назначена)';
														|en = '%1 (already assigned)'; fa = '%1 (already assigned)';
														|it = '%1 (already assigned)';
														|pl = '%1 (already assigned)';
														|tr = '%1  (zaten atanmış)'"), ListLine.Data.State);
			EndIf;
		EndDo;
		
	EndIf;
	
	For Each TableRow In TransactionTable Do
		ListLine = TableRow.ListLine;
		If IsBlankString(TableRow.StatusText_3)
			And ListLine.Data.State = Enums.OperationStates.Executed
			And ListLine.Data.RepetitionIsRequired Then
			TableRow.StatusText_3 = StrTemplate(NStr("vi = '%1 (yêu cầu lặp lại)';
													|ru = '%1 (требует повторения)';
													|en = '%1 (requires repetition)'; fa = '%1 (requires repetition)';
													|it = '%1 (requires repetition)';
													|pl = '%1 (requires repetition)';
													|tr = '%1 (tekrar gerektirir)'"), ListLine.Data.State);
		EndIf;
		If Not IsBlankString(TableRow.StatusText_3) Then
			ListLine.Appearance["State"].SetParameterValue("Text", TableRow.StatusText_3);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformingOperations_ChangeOperation(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Documents", False);
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ShowValue(, HighlightedOperations.OperationsRefs[0]);
	
EndProcedure

&AtClient
Procedure PerformingAssignOperations(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Unassigned");
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	OpenAssignOperationsForm(HighlightedOperations.OperationKeys, "Assign");
	
EndProcedure

&AtClient
Procedure PerformingOperationsAcceptToWork(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList(?(UseShiftTasks, "Documents", ""));
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	If HighlightedOperations.RowsData.Count() <> HighlightedOperations.Counters.YouCanTakeWork Then
		ShowMessageBox(,
			ProductionProcessEditorClientServer.WarningTextCommandCannotBeExecuted(HighlightedOperations.OperationKeys));
	ElsIf HighlightedOperations.Counters.Unassigned > 0 Then
		OpenAssignOperationsForm(
			HighlightedOperations.OperationKeys, "PutIntoOperation");
	Else
		ProductionAccountingClient.SetProductionOperationStatus(
			HighlightedOperations.OperationsRefs, "Running", Department);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsAreToCelebrateTheExecution(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList(?(UseShiftTasks, "Documents", ""));
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	If HighlightedOperations.RowsData.Count() <> HighlightedOperations.Counters.YouCanMarkExecution Then
		ShowMessageBox(,
			ProductionProcessEditorClientServer.WarningTextCommandCannotBeExecuted(HighlightedOperations.OperationKeys));
	ElsIf HighlightedOperations.Counters.Unassigned > 0 Then
		OpenAssignOperationsForm(
			HighlightedOperations.OperationKeys, "MarkCompletion");
	Else
		ProductionAccountingClient.SetProductionOperationStatus(
			HighlightedOperations.OperationsRefs, "Executed", Department);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecutionOfOperations_NotPerformed(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Documents");
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	NewStatus = "NotExecuted";
	
	For Each RowData In HighlightedOperations.RowsData Do
		ConfirmationParameters = ProductionAccountingClient.ConfirmationWhenSettingStatusOfOperation(
			RowData, NewStatus, HighlightedOperations.Count() > 0);
		If ConfirmationParameters <> Undefined Then
			ConfirmationParameters.Insert("OperationKeys", HighlightedOperations.OperationKeys);
			CallbackDescription = New CallbackDescription(
				"ConfirmationWhenSettingStatusOfOperationsEnd", ThisObject, ConfirmationParameters);
			ShowQueryBox(CallbackDescription, ConfirmationParameters.QueryText, ConfirmationParameters.QuestionDialogMode);
			Return;
		EndIf;
	EndDo;
	
	GenerateSetStatusOfOperations(HighlightedOperations.OperationKeys, NewStatus);
	
EndProcedure

&AtClient
Procedure PerformingOperationsSkip(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList(?(UseShiftTasks, "Documents", ""));
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	NewStatus = "IsSkipped";
	ConfirmationParameters = Undefined;
	
	For Each RowData In HighlightedOperations.RowsData Do
		If Not RowData.Skippable
			Or (Not ValueIsFilled(RowData.ProductionOperation)
				And RowData.State <> PredefinedValue("Enum.OperationStates.ForCompletion")) Then
			ShowMessageBox(,
				ProductionProcessEditorClientServer.WarningTextCommandCannotBeExecuted(HighlightedOperations.OperationKeys));
			Return;
		EndIf;
		If ConfirmationParameters = Undefined Then
			ConfirmationParameters = ProductionAccountingClient.ConfirmationWhenSettingStatusOfOperation(
				RowData, NewStatus, HighlightedOperations.Count() > 0);
		EndIf;
	EndDo;
	
	If ConfirmationParameters <> Undefined Then
		ConfirmationParameters.Insert("OperationKeys", HighlightedOperations.OperationKeys);
		CallbackDescription = New CallbackDescription(
			"ConfirmationWhenSettingStatusOfOperationsEnd", ThisObject, ConfirmationParameters);
		ShowQueryBox(CallbackDescription, ConfirmationParameters.QueryText, ConfirmationParameters.QuestionDialogMode);
		Return;
	EndIf;
	
	GenerateSetStatusOfOperations(HighlightedOperations.OperationKeys, NewStatus);
	
EndProcedure

&AtClient
Procedure PerformingOperations_ChangeTechnicalProcess(Command)
	
	CurrentData = Items.ExecutionOfOperations.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Stage", CurrentData.Stage);
	
	CallbackDescription = New CallbackDescription(
		"OpenProcessEditingFormCompletion",
		ThisObject);
	
	OpenForm(
		"DataProcessor.ProductionProcessEditor.Form",
		FormParameters,
		ThisObject,
		CurrentData.Stage,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PerformingOperations_AssignWorkCenter(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Documents");
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	CurrentWorkCenterTypeView = Undefined;
	Current_Section           = Undefined;
	
	For Each RowData In HighlightedOperations.RowsData Do
			
		If ValueIsFilled(RowData.WorkCenterType) Then
			
			If CurrentWorkCenterTypeView = Undefined Then
				
				CurrentWorkCenterTypeView = RowData.WorkCenterType;
				
			ElsIf CurrentWorkCenterTypeView <> RowData.WorkCenterType Then
				
				ShowMessageBox(, NStr("vi = 'Đã chọn các giao dịch có dạng nguồn lực sản xuất khác nhau.';
										|ru = 'Выбраны операции с различными видами рабочих центров.';
										|en = 'Operations with different work center types are selected.'; fa = 'Operations with different work center types are selected.';
										|it = 'Sono selezionate le operazioni con tipi di centri operativi diversi.';
										|pl = 'Wybrane operacje z różnymi rodzajami centrów roboczych.';
										|tr = 'Farklı türde iş merkezleri olan işlemler seçildi.'"));
				Return;
				
			EndIf;
			
		EndIf;
		
		If ValueIsFilled(RowData.ProductionArea) Then
			
			If Current_Section = Undefined Then
				
				Current_Section = RowData.ProductionArea;
				
			ElsIf Current_Section <> RowData.ProductionArea Then
				
				ShowMessageBox(, NStr("vi = 'Đã chọn các giao dịch có khu vực khác nhau.';
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
	If Current_Section <> Undefined Then
		Filter.Insert("ProductionArea", Current_Section);
	EndIf;
	If CurrentWorkCenterTypeView <> Undefined Then
		Filter.Insert("WorkCenterType", CurrentWorkCenterTypeView);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("ChooseSetupOption", True);
	FormParameters.Insert("Filter", Filter);
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Operations", HighlightedOperations.OperationsRefs);
	
	CallbackDescription = New CallbackDescription(
		"OperationsAssignWorkCenterCompletion",
		ThisObject, AddlParameters);
	
	OpenForm("Catalog.WorkCenters.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow); 
	
EndProcedure

&AtClient
Procedure PerformingOperations_CancelAssignmentOfWorkCenter(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Documents");
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	ClearMessages();
	
	OperationsAssignWorkCenterOnServer(
		HighlightedOperations.OperationsRefs,
		PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	
EndProcedure

&AtClient
Procedure ExecutionOfOperations_Check(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Documents", False);
	
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	RowData = HighlightedOperations.RowsData[0];
	
	If RowData.FollowUp = 0 Then
		ShowMessageBox(,
			ProductionProcessEditorClientServer.WarningTextCommandCannotBeExecuted());
		Return;
	EndIf;
	
	ClearMessages();
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionOperation", RowData.ProductionOperation);
	
	NotificationParameters = New Structure("ProductionOperation", RowData.ProductionOperation);
	Notification = New CallbackDescription("To_ControlCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Document.ProductionOperation2_2.Form.OperationControl",
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	HighlightedOperations = CheckGetOperationsHighlightedInList("Documents");
		
	If HighlightedOperations = Undefined Then
		Return;
	EndIf;
	
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, HighlightedOperations.OperationsRefs);
	
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ExecutionOfOperations, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ExecutionOfOperations);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ExecutionOfOperations);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ExecutionOfOperations.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ExecutionOfOperations.PreviousOnesStarted");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ExecutionOfOperations.PendingPredecessorCompletion");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ExecutionOfOperationsTimeUnitsOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("ExecutionOfOperations.RunTime");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);

EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	UseAreas = ProductionServer.UseAreasForPostoperativeManagement();
	
	Items.SelectionDivisionTitle.Visible = Not UseAreas;
	Items.FilterTypeDepartment.Visible = UseAreas;
	
	RightToAddOperations = AccessRight("Insert", Metadata.Documents.ProductionOperation2_2);
	RightToChangeOperations  = AccessRight("Update", Metadata.Documents.ProductionOperation2_2);
	
	Items.ExecutionCommandsGroup.Enabled           = RightToAddOperations And RightToChangeOperations;
	Items.PerformingOperationsGroupAction1.Enabled = RightToAddOperations And RightToChangeOperations;
	Items.PerformingOperationsGroupAction2.Enabled = RightToAddOperations And RightToChangeOperations;
	Items.CommandGroupWorkCenter.Enabled         = RightToAddOperations And RightToChangeOperations;
	
	UseOperationExecutionControl = GetFunctionalOption("UseOperationExecutionControl");
	Items.TransitionControlOfOperations.Visible = UseOperationExecutionControl;
	
	AccountingOfLaborCostsInContextOfEmployeesIsUsed = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate());
	
	SetKeyToSaveWindowPosition();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Or AttributesStructure1.Property("Department") Then
		
		Items.ExecutionOfOperationsShiftTaskDate.Visible      = Form.UseShiftTasks;
		Items.ExecutionOfOperationsShiftTask.Visible          = Form.UseShiftTasks;
		
		Items.SelectionChangeTheTitle.Visible                       = Form.UseShiftTasks;
		Items.FilterShift.Visible                                = Form.UseShiftTasks;
		Items.QuickSelection_BYAppointment.Visible                  = Form.UseShiftTasks;
		
		Items.PerformingAssignOperations.Visible              = Not Form.UseShiftTasks;
		Items.PerformingOperationsAction_Assign.Visible      = Not Form.UseShiftTasks;
		
	EndIf;
	
	If Initialize Or AttributesStructure1.Property("FilterTypeDepartment") Then
		
		Items.FilterDepartment.Visible = (Form.FilterTypeDepartment = 0);
		Items.FilterProductionArea.Visible       = (Form.FilterTypeDepartment = 1);
		
		Links = New Array;
		Links.Add(New ChoiceParameterLink("Filter.Department", "Department"));
		If Form.FilterTypeDepartment = 1 Then
			Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
		EndIf;
		
		Items.FilterWorkCenter.ChoiceParameterLinks = New FixedArray(Links);
		Items.FilterShift.ChoiceParameterLinks = New FixedArray(Links);
		
	EndIf;
	
	If Initialize Or AttributesStructure1.Property("State") Then
		
		SetStateOfHyperlink(Form, Items.QuickSelection_Unfinished, False);
		SetStateOfHyperlink(Form, Items.QuickSelection_Completed, False);
		
		If OnlyIncompleteStates(Form) Then
			Form.StateString = StatesIncompleteString();
			SetStateOfHyperlink(Form, Items.QuickSelection_Unfinished, True);
		ElsIf OnlyCompletedStates(Form) Then
			Form.StateString = StatesCompletedString();
			SetStateOfHyperlink(Form, Items.QuickSelection_Completed, True);
		Else
			Form.StateString = StrConcat(Form.States1.UnloadValues(), ";");
		EndIf;
		
		For Each Filter In QuickSelectionGroup(Form, Form.UseShiftTasks) Do // DataCompositionFilter
			For Each FilterElement In Filter.Items Do
				SetStateOfHyperlink(Form, Items[FilterElement.Presentation], FilterElement.Use);
			EndDo;
		EndDo;
		
		SetStateOfHyperlink(Form, Items.QuickSelection_All, CurrentSelectionIsAll(Form));
		
	EndIf;
		
	If Initialize Or AttributesStructure1.Property("SetupSettings") Then
		
		ChoiceParameters = New Array();
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", Form.WorkCenterType));
		
		Items.GroupSelectionAdjustmentOption.Visible = Form.SetupSettingsAreUsed;
		Items.FilterSetupSettings.ChoiceParameters = New FixedArray(ChoiceParameters);
			
	EndIf;
	
	If AttributesStructure1.Property("InfoMessage") Then
		
		FilledInformationMessage = ValueIsFilled(Form.InfoMessage);
		
		Items.InfoMessage.Visible = FilledInformationMessage;
		
	EndIf;
	
EndProcedure

#Region PropertiesOfListPerformingOperations

&AtServer
Procedure SetPropertiesOfDynamicListPerformOperations()

	If StrFind(ExecutionOfOperations.QueryText, "&PresentationStage") <> 0
		Or StrFind(ExecutionOfOperations.QueryText, "&ProductionArea") <> 0
			And FilterTypeDepartment = 0
		Or StrFind(ExecutionOfOperations.QueryText, "&ProductionArea") = 0
			And FilterTypeDepartment = 1 Then
			
		QueryText = RequestTextForOperationsList();
		
		Documents.ProductionStage2_2.ReplacePresentationField(
			QueryText, "&PresentationStage", "Queue.Stage");
		
		ListProperties              = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = QueryText;
		Common.SetDynamicListProperties(Items.ExecutionOfOperations, ListProperties);
		
		ExecutionOfOperations.Parameters.SetParameterValue(
			"TheProductionScheduleIsUsed",
			ProductionManagementCached.TheProductionScheduleIsUsed());
			
		ExecutionOfOperations.Parameters.SetParameterValue(
			"StatusWorkingSchedule",
			InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
			
	EndIf;
	
	PerformingOperationsToCreateSelectionElements();
	
	PerformingOperationsToCreateOrderElements();

EndProcedure

&AtServer
Function RequestTextForOperationsList()
	
	QueryText =
	"SELECT
	|	Queue.ReferenceOrder                                           AS ReferenceOrder,
	|	Queue.Stage                                                   AS Stage,
	|	Queue.Operation                                               AS Operation,
	|	Queue.OperationID                                  AS OperationID,
	|	Queue.ProductionOperation                               AS ProductionOperation,
	|	Queue.ProductionOperation.Number                         AS ProductionOperationNumber,
	|	Queue.ProductionOperation.Status                        AS RoutesOperationStatus,
	|	Queue.ProductionOperation.BasedOnMasterData                AS RoutingOperationOnBasisOfNSI,
	|	Queue.ProductionOperation.OperationAsOutputReference AS RoutesOperationAsOrderOfProduction,
	|	Queue.ProductionOperation <> VALUE(Document.ProductionOperation2_2.EmptyRef) AS RoutesOperationIsAssigned,
	|	Queue.State                                              AS State,
	|	Queue.Performer                                            AS Performer,
	|	Queue.ShiftTask                                         AS ShiftTask,
	|	Queue.ShiftTask.Date                                    AS ShiftTaskDate,
	|	Queue.OperationNumber                                          AS OperationNumber,
	|	Queue.NextOperation                                 AS NextOperation,
	|
	|	Queue.Scheduled                                          AS CountPlan,
	|	Queue.Running + Queue.UnderControl + Queue.UnderRevision AS QuantityInOperation,
	|	Queue.Completed2                                              AS QuantityIsReady,
	|	Queue.DefectiveGoods                                                   AS DefectiveGoodsCount,
	|	Queue.UnderControl                                             AS FollowUp,
	|	Queue.UnderRevision                                            AS QuantityUnderRevision,
	|	Queue.ExecutionIsAllowed                                         AS ExecutionIsAllowed,
	|	Queue.PendingPredecessorCompletion                                 AS PendingPredecessorCompletion,
	|	Queue.PreviousOnesStarted                                   AS PreviousOnesStarted,
	|
	|	CASE
	|		WHEN Queue.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN Queue.WorkCenter
	|		ELSE
	|			Queue.WorkCenter.WorkCenterType
	|	END                                                          AS WorkCenterType,
	|	CASE
	|		WHEN Queue.WorkCenter REFS Catalog.WorkCenters
	|			THEN Queue.WorkCenter
	|		ELSE
	|			VALUE(Catalog.WorkCenters.EmptyRef)
	|	END                                                          AS WorkCenter,
	|	CASE
	|		WHEN Queue.ProductionOperation <> VALUE(Document.ProductionOperation2_2.EmptyRef)
	|			THEN Queue.ProductionOperation.ProductionArea
	|		WHEN Queue.WorkCenter REFS Catalog.WorkCenters
	|				AND NOT Queue.WorkCenter = VALUE(Catalog.WorkCenters.EmptyRef)
	|			THEN CAST(Queue.WorkCenter AS Catalog.WorkCenters).ProductionArea
	|		ELSE
	|			ISNULL(Queue.ProductionOperation.ProductionArea, Queue.Operation.ProductionArea)
	|	END                                                                            AS ProductionArea,
	|	ISNULL(Queue.ProductionOperation.Skippable, Queue.Operation.Skippable)    AS Skippable,
	|	ISNULL(Queue.ProductionOperation.Repeatable, Queue.Operation.Repeatable)      AS Repeatable,
	|	ISNULL(Queue.ProductionOperation.Description, Queue.Operation.Description)          AS NameOfTheOperation,
	|	ISNULL(Queue.ProductionOperation.UnitOfMeasure, Queue.Operation.UnitOfMeasure)  AS UnitOfMeasure,
	|	ISNULL(Queue.ProductionOperation.SetupSettings, Queue.Operation.SetupSettings)      AS SetupSettings,
	|
	|	ISNULL(Queue.ProductionOperation.RepetitionIsRequired, FALSE) AS RepetitionIsRequired,
	|
	|	&PresentationStage                                            AS PresentationStage,
	|	Queue.Stage.ProductionLot.MainProductProducts    AS Products,
	|	Queue.Stage.ProductionLot.MainProductCharacteristic  AS Characteristic,
	|
	|	Queue.TimeTotal                                             AS RunTime,
	|	Queue.TimeUnitsOfMeasure                                             AS TimeUnitsOfMeasure,
	|	Queue.Order                                                AS Order,
	|	Schedule.Begin                                                  AS StageStart,
	|	Schedule.NextStageStart                                   AS NextStageStart,
	|	CASE
	|		WHEN &TheProductionScheduleIsUsed
	|				AND NOT Schedule.Stage IS NULL
	|			THEN Schedule.Begin
	|		WHEN TargetOrderStructureSchedule.Begin IS NOT NULL
	|			THEN TargetOrderStructureSchedule.Begin
	|		ELSE DATEADD(Queue.ReferenceOrder.EarliestStartDate, SECOND, ISNULL(RegulatorySchedule.DurationBeforeStart, 0))
	|	END                                                                                 AS StartDate,
	|	ISNULL(RegulatorySchedule.DurationBeforeProductionIssue, Queue.Stage.DurationBeforeProductionIssue) AS DurationBeforeProductionIssue
	|FROM
	|	InformationRegister.QueueOfProductionOperations AS Queue
	|
	|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|		ON Queue.ReferenceOrder = Schedule.ProductionOrder
	|			AND Queue.Stage = Schedule.Stage
	|			AND (Schedule.ScheduleStatus = &StatusWorkingSchedule)
	|
	|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS RegulatorySchedule
	|		ON Queue.Stage = RegulatorySchedule.ProductionStage
	|
	|		LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS TargetOrderStructureSchedule
	|		ON Queue.Stage = TargetOrderStructureSchedule.Stage
	|
	|WHERE
	|	NOT Queue.InArchive
	|";
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure PerformingOperationsToCreateSelectionElements()
	
	FilterItems1 = ExecutionOfOperations.SettingsComposer.Settings.Filter.Items;
	FilterItems1.Clear();
	
	SelectionGroupRoot = CommonClientServer.CreateFilterItemGroup(
		FilterItems1,,
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		SelectionGroupRoot,
		"State",
		DataCompositionComparisonType.InList,,
		"Selection_State",
		False);
		
	SelectionGroupWithoutSZ = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupRoot,
		"QuickSelection_WithoutNW",
		DataCompositionFilterItemsGroupType.OrGroup);
		
	NWSelectionGroup = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupRoot,
		"QuickSelectionOf_SZ",
		DataCompositionFilterItemsGroupType.OrGroup);
	
	// Without SZ
	
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupWithoutSZ,
		Items.QuickSelection_TOComplete.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	StatesList = New ValueList();
	StatesList.Add(Enums.OperationStates.ForCompletion);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"State",
		DataCompositionComparisonType.InList,
		StatesList);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupWithoutSZ,
		Items.QuickSelection_INWork.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"QuantityInOperation",
		DataCompositionComparisonType.Greater,
		0);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupWithoutSZ,
		Items.QuickSelection_UnderControl.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"FollowUp",
		DataCompositionComparisonType.Greater,
		0);
	
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupWithoutSZ,
		Items.QuickSelection_UnderRevision.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"QuantityUnderRevision",
		DataCompositionComparisonType.Greater,
		0);
	
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		SelectionGroupWithoutSZ,
		Items.QuickSelection_Nonconformity.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"DefectiveGoodsCount",
		DataCompositionComparisonType.Greater,
		0);
	
	// CostsItems
	
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		NWSelectionGroup,
		Items.QuickSelection_BYAppointment.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
	
	StatesList = New ValueList();
	StatesList.Add(Enums.OperationStates.ToAssign);
	StatesList.Add(Enums.OperationStates.PendingPredecessorCompletion);
	
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"State",
		DataCompositionComparisonType.InList,
		StatesList);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"ProductionOperation",
		DataCompositionComparisonType.NotFilled);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		NWSelectionGroup,
		Items.QuickSelection_TOComplete.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	StatesList = New ValueList();
	StatesList.Add(Enums.OperationStates.Assigned_);
	StatesList.Add(Enums.OperationStates.ForCompletion);
	
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"State",
		DataCompositionComparisonType.InList,
		StatesList);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		NWSelectionGroup,
		Items.QuickSelection_INWork.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"QuantityInOperation",
		DataCompositionComparisonType.Greater,
		0);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		NWSelectionGroup,
		Items.QuickSelection_UnderControl.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"FollowUp",
		DataCompositionComparisonType.Greater,
		0);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		NWSelectionGroup,
		Items.QuickSelection_UnderRevision.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"QuantityUnderRevision",
		DataCompositionComparisonType.Greater,
		0);
		
	GroupOfFilters = CommonClientServer.CreateFilterItemGroup(
		NWSelectionGroup,
		Items.QuickSelection_Nonconformity.Name,
		DataCompositionFilterItemsGroupType.AndGroup);
		
	CommonClientServer.AddCompositionItem(
		GroupOfFilters,
		"DefectiveGoodsCount",
		DataCompositionComparisonType.Greater,
		0);
		
	ResetQuickSelections(ThisObject);
	
EndProcedure

&AtServer
Procedure PerformingOperationsToCreateOrderElements()
	
	OrderItems = ExecutionOfOperations.Order.Items;
	OrderItems.Clear();
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
	
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("Order");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("StageStart");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("NextStageStart");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("OperationNumber");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("NameOfTheOperation");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("RoutesOperationIsAssigned");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ProductionOperation.Date");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
	Else
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("Order");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ReferenceOrder.Priority");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ReferenceOrder.Department.AddlOrderingAttribute");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ReferenceOrder.Queue");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("DurationBeforeProductionIssue");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("OperationNumber");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("NameOfTheOperation");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("RoutesOperationIsAssigned");
		ListOrder.OrderType = DataCompositionSortDirection.Desc;
		ListOrder.Use = True;
		
		ListOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
		ListOrder.Field = New DataCompositionField("ProductionOperation.Date");
		ListOrder.OrderType = DataCompositionSortDirection.Asc;
		ListOrder.Use = True;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTheListOnServer()
	
	Items.ExecutionOfOperations.Refresh();
	
EndProcedure

#EndRegion

#Region SelectionsAreCommon

&AtServer
Procedure DivisionWhenChangedOnServer(SelectionTypeChanged)
	
	ReadDivisionParameters();
	
	SetSelectionByStateONChangeOfDivision(ThisObject);
	
	SetTypeOfWorkCenter(ThisObject);
	SetArtistType();
	
	SetSelectionByDivisionSection();
	SetSelectionByWorkCenter();
	SetSelectionByPerformer(ThisObject);
	SetSelectionForShiftTask(ThisObject);
	
	SetKeyToSaveWindowPosition();
	
	ConfigureDependentFormElements(ThisObject, "Department,SetupSettings,State" + ?(SelectionTypeChanged, ",FilterTypeDepartment", ""));
	
EndProcedure

&AtServer
Procedure PlotWhenChangedOnServer(SelectionTypeChanged)
	
	Department = ?(ProductionArea.IsEmpty(),
		Undefined,
		Common.ObjectAttributeValue(ProductionArea, "Owner"));
		
	DivisionWhenChangedOnServer(SelectionTypeChanged);
	
EndProcedure

&AtServer
Procedure WorkCenterWhenChangingOnServer()
	
	FillInServiceAttributesOfWorkCenter();
	
	SetSelectionByWorkCenter();
	
	SetupSettings = PredefinedValue("Catalog.SetupOptions.EmptyRef");
	SetSelectionByAdjustmentOption(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "SetupSettings");
	
EndProcedure

&AtServer
Procedure ExecutorWhenChangeIsMadeOnServer()
	
	If AccountingOfLaborCostsInContextOfEmployeesIsUsed Then
	
		PerformerPerson = ?(ValueIsFilled(Performer),
			Common.ObjectAttributeValue(Performer, "Individual"),
			Undefined);
		
	EndIf;
	
	SetSelectionByPerformer(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfWorkCenter()
	
	If Not ValueIsFilled(WorkCenter) Then
		WorkCenterType = Catalogs.WorkCenterTypes.EmptyRef();
		SetupSettingsAreUsed = False;
	ElsIf FilterTypeWorkCenter = 1 Then
		AttributesValues = Common.ObjectAttributesValues(WorkCenter,
			"WorkCenterType,WorkCenterType.SetupSettingsAreUsed");
		WorkCenterType = AttributesValues.WorkCenterType;
		SetupSettingsAreUsed = AttributesValues.WorkCenterTypeAdjustmentOptionsAreUsed;
	Else
		AttributesValues = Common.ObjectAttributesValues(WorkCenter,
			"SetupSettingsAreUsed");
		WorkCenterType = WorkCenter;
		SetupSettingsAreUsed = AttributesValues.SetupSettingsAreUsed;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByPerformer(Form)
	
	FilterByPerformer = CommonClientServer.CreateFilterItemGroup(
		Form.ExecutionOfOperations.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo người thực hiện';
			|ru = 'Отбор по исполнителю';
			|en = 'Filter by assignee'; fa = 'فیلتر بر اساس مجری';
			|it = 'Selezione per assegnaatrio';
			|pl = 'Filtr według wykonawcy';
			|tr = 'Atanana göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
		
	If Form.AccountingOfLaborCostsInContextOfEmployeesIsUsed Then
		
		Assignees = New Array;
		Assignees.Add(Form.Performer);
		Assignees.Add(Form.PerformerPerson);
		
		CommonClientServer.AddCompositionItem(
			FilterByPerformer,
			"ProductionOperation.Performer",
			DataCompositionComparisonType.InList,
			Assignees,
			,
			ValueIsFilled(Form.Performer));
		
		CommonClientServer.AddCompositionItem(
			FilterByPerformer,
			"ProductionOperation.LaborCosts.Performer",
			DataCompositionComparisonType.InList,
			Assignees,
			,
			ValueIsFilled(Form.Performer));
		
	Else
		
		CommonClientServer.AddCompositionItem(
			FilterByPerformer,
			"ProductionOperation.Performer",
			DataCompositionComparisonType.Equal,
			Form.Performer,
			,
			ValueIsFilled(Form.Performer));
		
		CommonClientServer.AddCompositionItem(
			FilterByPerformer,
			"ProductionOperation.LaborCosts.Performer",
			DataCompositionComparisonType.Equal,
			Form.Performer,
			,
			ValueIsFilled(Form.Performer));
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionForShiftTask(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.ExecutionOfOperations,
		"ShiftTask",
		Form.Shift,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.Shift));
	
EndProcedure

&AtServer
Procedure SetSelectionByStages(StageList = Undefined)
	
	SelectionSet = ValueIsFilled(StageList);
	
	If SelectionSet Then
		
		FilterValue  = ?(StageList.Count() = 1, StageList[0], StageList);
		TypeOfDCSComparison = ?(StageList.Count() = 1,
			DataCompositionComparisonType.Equal,
			DataCompositionComparisonType.InList);
			
	Else
		
		FilterValue = Undefined;
		TypeOfDCSComparison = DataCompositionComparisonType.Equal;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
			ExecutionOfOperations,
			"Stage",
			FilterValue,
			TypeOfDCSComparison,
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
	
	If FilterTypeWorkCenter = 1 Then
		
		CommonClientServer.SetDynamicListFilterItem(
				ExecutionOfOperations,
				"WorkCenter",
				WorkCenter, 
				DataCompositionComparisonType.Equal,
				,
				SelectionSet);
		
		CommonClientServer.SetDynamicListFilterItem(
				ExecutionOfOperations,
				"WorkCenterType",
				,
				,
				,
				False);
		
	Else
		
		CommonClientServer.SetDynamicListFilterItem(
				ExecutionOfOperations,
				"WorkCenter",
				,
				,
				,
				False);
		
		CommonClientServer.SetDynamicListFilterItem(
				ExecutionOfOperations,
				"WorkCenterType",
				WorkCenter,
				DataCompositionComparisonType.Equal,
				, 
				SelectionSet);
			
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByAdjustmentOption(Form)
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.ExecutionOfOperations,
		"SetupSettings",
		Form.SetupSettings,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Form.SetupSettings));
	
EndProcedure

&AtServer
Procedure SetSelectionByDivisionSection()
	
	CommonClientServer.SetDynamicListFilterItem(
		ExecutionOfOperations,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ExecutionOfOperations,
		"ProductionArea",
		ProductionArea,
		DataCompositionComparisonType.Equal,,
		FilterTypeDepartment = 1);
		
	FOParameters = New Structure(
		"Department",
		?(ValueIsFilled(Department), Department, Undefined));
	SetFormFunctionalOptionParameters(FOParameters);
	
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

&AtServer
Procedure SetArtistType()
	
	ProductionManagementClientServer.SetArtistType(Performer,
		UseTeamWorkOrders,
		AccountingOfLaborCostsInContextOfEmployeesIsUsed);
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Performer = Result;
		SetSelectionByPerformer(ThisObject);
		
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
		RowsArray.Add(New FormattedString(PresentationStage,,,, GetURL(StageList[0])));
		
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
	
	ConfigureDependentFormElements(ThisObject, "InfoMessage");
	
EndProcedure

&AtClientAtServerNoContext
Function CurrentStageSelection(Form)
	
	Result = Undefined;
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(Form.ExecutionOfOperations.Filter, "Stage");
	If FilterItems1.Count() = 1
		And TypeOf(FilterItems1[0].RightValue) = Type("DocumentRef.ProductionStage2_2") Then
		Result = FilterItems1[0].RightValue;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SelectionsAreFast

&AtClientAtServerNoContext
Function CurrentSelectionIsAll(Form)
	
	Return Form.States1.Count() = 0
		And QuickSelectionsAreReset(Form);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetSelectionByState(Form, ResetQuickSelections = Undefined)
	
	States1 = Form.States1;
	
	If ResetQuickSelections <> Undefined Then
		
		ResetQuickSelections(Form, ResetQuickSelections);
		
	EndIf;
	
	GroupOfFilters = CommonClientServer.FindFilterItemsAndGroups(
		Form.ExecutionOfOperations.SettingsComposer.Settings.Filter,, "Selection_State");
	If GroupOfFilters <> Undefined And GroupOfFilters.Count() > 0 Then
		FilterElement = GroupOfFilters[0];
		FilterElement.Use = States1.Count() > 0;
		FilterElement.RightValue = States1;
	EndIf;
	
	ConfigureDependentFormElements(Form, "State");
	 
EndProcedure

&AtClientAtServerNoContext
Function OnlyCompletedStates(Form, States1 = Undefined)
	
	If States1 = Undefined Then
		States1 = Form.States1;
	EndIf;
	
	Return StateListsAreSame(States1.UnloadValues(), StatesCompleted(Form));
	
EndFunction

&AtClientAtServerNoContext
Function OnlyIncompleteStates(Form, States1 = Undefined)
	
	If States1 = Undefined Then
		States1 = Form.States1;
	EndIf;
	
	Return StateListsAreSame(States1.UnloadValues(), StatesIncomplete(Form));
	
EndFunction

&AtClientAtServerNoContext
Function StateListsAreSame(States11, States12)
	
	If States11.Count() <> States12.Count() Then
		Return False;
	EndIf;
	
	Return CommonClientServer.ValueListsAreEqual(States11, States12);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetSelectionByStateONChangeOfDivision(Form)
	
	If Form.StateString = StatesIncompleteString() Then
		Form.States1.LoadValues(StatesIncomplete(Form));
	ElsIf Form.StateString = StatesCompletedString() Then
		Form.States1.LoadValues(StatesCompleted(Form));
	ElsIf Form.States1.Count() > 0 Then
		States1 = New Array;
		For Each State In StatesAvailable(Form) Do
			If Form.States1.FindByValue(State) <> Undefined Then
				States1.Add(State);
			EndIf;
		EndDo;
		Form.States1.LoadValues(States1);
	EndIf;
	
	SetSelectionByState(Form, QuickSelectionsListIncomplete());
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetStateOfHyperlink(Form, Item, Clicked)
	
	If Clicked Then
		Item.BackColor = Form.Cache.ColorOfPressedSelection;
	Else
		Item.BackColor = New Color();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SwitchQuickSelection(Form, FilterName)
	
	For Each GroupOfFilters In QuickSelectionGroup(Form, Form.UseShiftTasks) Do
		GroupOfFilters.Use = True;
		For Each FilterElement In GroupOfFilters.Items Do
			If FilterElement.Presentation = FilterName Then
				FilterElement.Use = Not FilterElement.Use;
			EndIf;
		EndDo;
	EndDo;
	
	If FilterName <> "QuickSelection_Nonconformity" Then
		Form.States1.Clear();
	EndIf;
	
	SetSelectionByState(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ResetQuickSelections(Form, FilterItems1 = Undefined)
	
	For It = 0 To 1 Do
		For Each GroupOfFilters In QuickSelectionGroup(Form, Boolean(It)) Do
			AllReset = True;
			For Each FilterElement In GroupOfFilters.Items Do
				If Form.UseShiftTasks = Boolean(It)
						And FilterItems1 <> Undefined
						And FilterItems1.Find(FilterElement.Presentation) = Undefined Then
					AllReset = False;
					Continue;
				EndIf;
				FilterElement.Use = False;
			EndDo;
			GroupOfFilters.Use = Not AllReset;
		EndDo;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function QuickSelectionsAreReset(Form)
	
	For It = 0 To 1 Do
		For Each GroupOfFilters In QuickSelectionGroup(Form, Boolean(It)) Do // DataCompositionFilterItemGroup
			For Each FilterElement In GroupOfFilters.Items Do
				If FilterElement.Use Then
					Return False;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return True;
	
EndFunction

&AtClientAtServerNoContext
Function QuickSelectionGroup(Form, UseShiftTasks)
	
	GroupOfFilters = CommonClientServer.FindFilterItemsAndGroups(
		Form.ExecutionOfOperations.SettingsComposer.Settings.Filter,,
		?(UseShiftTasks, "QuickSelectionOf_SZ", "QuickSelection_WithoutNW"));
	
	Return GroupOfFilters;
	
EndFunction

&AtClientAtServerNoContext
Function StatesAvailable(Form)
	
	States1 = New Array;
	
	CommonClientServer.SupplementArray(States1, StatesIncomplete(Form));
	CommonClientServer.SupplementArray(States1, StatesCompleted(Form));
	
	Return States1;
	
EndFunction

&AtClientAtServerNoContext
Function StatesIncomplete(Form)
	
	States1 = New Array;
	
	States1.Add(PredefinedValue("Enum.OperationStates.PendingPredecessorCompletion"));
	States1.Add(PredefinedValue("Enum.OperationStates.ForCompletion"));
	States1.Add(PredefinedValue("Enum.OperationStates.Running"));
	States1.Add(PredefinedValue("Enum.OperationStates.UnderControl"));
	States1.Add(PredefinedValue("Enum.OperationStates.UnderRevision"));
	
	If Form.UseShiftTasks Then
		States1.Add(PredefinedValue("Enum.OperationStates.ToAssign"));
		States1.Add(PredefinedValue("Enum.OperationStates.Assigned_"));
	EndIf;
	
	Return States1;
	
EndFunction

&AtClientAtServerNoContext
Function StatesIncompleteString()
	
	Return NStr("vi = 'Chưa hoàn thành';
				|ru = 'Незавершенные';
				|en = 'Unfinished'; fa = 'ناتمام';
				|it = 'Non completate';
				|pl = 'Niedokończone';
				|tr = 'Tamamlanmayanlar'");
	
EndFunction

&AtClientAtServerNoContext
Function StatesCompleted(Form)
	
	States1 = New Array;
	
	States1.Add(PredefinedValue("Enum.OperationStates.Executed"));
	States1.Add(PredefinedValue("Enum.OperationStates.IsSkipped"));
	States1.Add(PredefinedValue("Enum.OperationStates.RolledBack"));
	
	Return States1;
	
EndFunction

&AtClientAtServerNoContext
Function StatesCompletedString()
	
	Return NStr("vi = 'Đã hoàn thành';
				|ru = 'Завершенные';
				|en = 'Finished'; fa = 'تمام‌شده';
				|it = 'Completati';
				|pl = 'Zakończone';
				|tr = 'Tamamlananlar'");
	
EndFunction

&AtClientAtServerNoContext
Function QuickSelectionsListControl()
	
	Result = New Array;
	
	Result.Add("QuickSelection_UnderControl");
	Result.Add("QuickSelection_UnderRevision");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function QuickSelectionsListInWork()
	
	Result = QuickSelectionsListControl();
	Result.Add("QuickSelection_INWork");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function QuickSelectionsListIncomplete()
	
	Result = QuickSelectionsListInWork();
	Result.Add("QuickSelection_BYAppointment");
	Result.Add("QuickSelection_TOComplete");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function QuickSelectionsListAll()
	
	Result = QuickSelectionsListIncomplete();
	Result.Add("QuickSelection_Nonconformity");
	
	Return Result;
	
EndFunction

#EndRegion

#Region ActionsWithOperations

// Check to get the operations highlighted in the list of operations.
// 
// Parameters:
//  Variant - String - acceptable choice
//  MultipleChoice - Boolean
// 
// Returns:
//  Undefined, Structure - Check Get Operations Highlighted In The List:
// * OperationKeys - Array of InformationRegisterRecordKey.QueueOfProductionOperations
// * RowsData - Array of FormDataStructure
// * OperationsRefs - Array of DocumentRef.ProductionOperation2_2
&AtClient
Function CheckGetOperationsHighlightedInList(Variant = "", MultipleChoice = True)
	
	Result = New Structure;
	Result.Insert("OperationKeys",  New Array);
	Result.Insert("RowsData",    New Array);
	Result.Insert("OperationsRefs", New Array);
	
	Counters = New Structure;
	Counters.Insert("Regular", 0);
	Counters.Insert("RegularAppointments", 0);
	Counters.Insert("OrdinaryUnassigned", 0);
	Counters.Insert("SpecialTerms", 0);
	Counters.Insert("IndividualAssigned", 0);
	Counters.Insert("IndividualUnassigned", 0);
	Counters.Insert("Assigned", 0);
	Counters.Insert("Unassigned", 0);
	Counters.Insert("Documents", 0);
	
	Counters.Insert("YouCanTakeWork", 0);
	Counters.Insert("YouCanMarkExecution", 0);
	
	SelectedRows = Items.ExecutionOfOperations.SelectedRows;
	
	ActiveStates = ProductionAccountingClientServer.ActiveStatesOfOperations();
	
	If SelectedRows.Count() = 0 Then
		
		ShowMessageBox(, NStr("vi = 'Không có thao tác nào được chọn để hoàn thành giao dịch';
								|ru = 'Не выбраны операции для выполнения действия';
								|en = 'Operations to execute the action are not selected'; fa = 'Operations to execute the action are not selected';
								|it = 'Nessuna operazione selezionata per eseguire l''azione';
								|pl = 'Nie wybrano operacji dla wykonania czynności';
								|tr = 'Eylemin gerçekleştirilmesi için herhangi bir işlem seçilmedi'"));
		Return Undefined;
		
	ElsIf SelectedRows.Count() > 1 And Not MultipleChoice Then
		
		ShowMessageBox(, NStr("vi = 'Lệnh không thể được thực thi cho nhiều dòng.';
								|ru = 'Команда не может быть выполнена для нескольких строк.';
								|en = 'Command cannot be executed for multiple lines.'; fa = 'Command cannot be executed for multiple lines.';
								|it = 'Il comando non può essere eseguito per alcune righe.';
								|pl = 'Polecenie nie może być wykonane dla kilku wierszy.';
								|tr = 'Birden fazla satır için komut gerçekleştirilemez.'"));
		Return Undefined;
		
	EndIf;
		
	For Each OperationKey In SelectedRows Do
		
		If TypeOf(OperationKey) = Type("DynamicListGroupRow") Then
			ShowMessageBox(, NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
									|ru = 'Действие не может быть выполнено для строки группировки списка';
									|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
									|it = 'L''operazione non può essere eseguita per la riga di raggruppamento dell''elenco';
									|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
									|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
			Return Undefined;
		EndIf;
		
		RowData = Items.ExecutionOfOperations.RowData(OperationKey);
		
		If ProductionProcessEditorClientServer.ThisOperationIsIndividual(RowData) Then
			Counters.SpecialTerms = Counters.SpecialTerms + 1;
			Counters.Documents = Counters.Documents + 1;
			If RowData.RoutesOperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.BeingGenerated") Then
				Counters.Unassigned = Counters.Unassigned + 1;
				Counters.IndividualUnassigned = Counters.IndividualUnassigned + 1;
			Else
				Counters.Assigned = Counters.Assigned + 1;
				Counters.IndividualAssigned = Counters.IndividualAssigned + 1;
			EndIf;
		Else
			Counters.Regular = Counters.Regular + 1;
			If ValueIsFilled(RowData.ProductionOperation) Then
				Counters.RegularAppointments = Counters.RegularAppointments + 1;
				Counters.Assigned = Counters.Assigned + 1;
				Counters.Documents = Counters.Documents + 1;
			ElsIf ActiveStates.Find(RowData.State) <> Undefined Then
				Counters.RegularAppointments = Counters.RegularAppointments + 1;
				Counters.Assigned = Counters.Assigned + 1;
			Else
				Counters.OrdinaryUnassigned = Counters.OrdinaryUnassigned + 1;
				Counters.Unassigned = Counters.Unassigned + 1;
			EndIf;
		EndIf;
		
		If RowData.ExecutionIsAllowed > 0 Then
			Counters.YouCanTakeWork = Counters.YouCanTakeWork + 1;
		EndIf;
		
		If RowData.ExecutionIsAllowed + RowData.QuantityInOperation - RowData.FollowUp > 0 Then
			Counters.YouCanMarkExecution = Counters.YouCanMarkExecution + 1;
		EndIf;
		
		If ValueIsFilled(RowData.ProductionOperation) Then
			If OperationKey = Items.ExecutionOfOperations.CurrentRow Then
				Result.OperationsRefs.Insert(0, RowData.ProductionOperation);
			Else
				Result.OperationsRefs.Add(RowData.ProductionOperation);
			EndIf;
		EndIf;
		
		Result.RowsData.Add(RowData);
		Result.OperationKeys.Add(OperationKey);
		
	EndDo;
		
	If Not IsBlankString(Variant) Then
		
		If (Variant = "Documents" And Counters.OrdinaryUnassigned > 0)
			Or (Variant = "SpecialTerms" And Counters.Regular > 0)
			Or (Variant = "Regular" And Counters.SpecialTerms > 0)
			Or (Variant = "Assigned" And Counters.Unassigned > 0)
			Or (Variant = "Unassigned" And Counters.Assigned > 0)
			Or (Variant = "SamePurpose" And Counters.Assigned > 0 And Counters.Unassigned > 0)
			Or (Variant = "EqualType" And Counters.SpecialTerms > 0 And Counters.Regular > 0) Then
			ShowMessageBox(, ProductionProcessEditorClientServer.WarningTextCommandCannotBeExecuted(SelectedRows));
			Return Undefined;
		EndIf;
		
	EndIf;
	
	Result.Insert("Counters", Counters);
	
	Return Result;
	
EndFunction

&AtClient
Procedure ConfirmationWhenSettingStatusOfOperationsEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
		
	If AdditionalParameters.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CancellationOfIndicators()
		And QuestionResult = DialogReturnCode.Yes Then
		
		GenerateSetStatusOfOperations(AdditionalParameters.OperationKeys, AdditionalParameters.NewStatus);
		
	ElsIf AdditionalParameters.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CreatingIndividualOperation() Then
		
		If QuestionResult = DialogReturnCode.Yes Then
			For Each OperationKey In AdditionalParameters.OperationKeys Do
				RowData = Items.ExecutionOfOperations.RowData(OperationKey);
				If ProductionProcessEditorClientServer.ThisOperationIsIndividual(RowData) Then
					OpenForm("Document.ProductionOperation2_2.Form.DocumentForm",
						New Structure("CopyingValue", RowData.ProductionOperation),
						ThisObject, RowData.ProductionOperation);
				EndIf;
			EndDo;
		EndIf;
		
		GenerateSetStatusOfOperations(AdditionalParameters.OperationKeys, AdditionalParameters.NewStatus);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateSetStatusOfOperations(OperationKeys, NewStatus)
	
	CreateOperations = New Array;
	OperationsRefs  = New Array;
	
	For Each OperationKey In OperationKeys Do
		
		RowData = Items.ExecutionOfOperations.RowData(OperationKey);
		
		If ValueIsFilled(RowData.ProductionOperation) Then
			OperationsRefs.Add(RowData.ProductionOperation);
		Else
			CreateOperations.Add(OperationKey);
		EndIf;
		
	EndDo;
	
	ClearMessages();
	
	If CreateOperations.Count() > 0 Then
		ProductionAccountingClient.GenerateProductionOperations(
			Department,
			CreateOperations,
			New Structure,
			ProductionAccountingClientServer.StatusOfOperationLink(NewStatus));
	EndIf;
	
	If OperationsRefs.Count() > 0 Then
		ProductionAccountingClient.SetProductionOperationStatus(
			OperationsRefs,
			NewStatus,
			Department);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenAssignOperationsForm(OperationKeys, WorkMode)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Department", Department);
	FormParameters.Insert("WorkMode", WorkMode);
	FormParameters.Insert("OperationKeys", OperationKeys);
	
	For Each ParameterName In StrSplit("WorkCenter,SetupSettings,ProductionArea", ",") Do
		If ValueIsFilled(ThisObject[ParameterName]) Then
			FormParameters.Insert(ParameterName, ThisObject[ParameterName]);
		ElsIf OperationKeys.Count() = 1 Then
			CurrentData = Items.ExecutionOfOperations.CurrentData;
			If CurrentData <> Undefined Then
				FormParameters.Insert(ParameterName, CurrentData[ParameterName])
			EndIf;
		EndIf;
	EndDo;
	
	OperationStatus = Undefined;
	If WorkMode = "Assign" Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.CreatedOn_");
	ElsIf WorkMode = "PutIntoOperation" Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.Running");
	ElsIf WorkMode = "MarkCompletion" Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.Executed");
	EndIf;
	
	AddlParameters = New Structure;
	AddlParameters.Insert("OperationKeys", OperationKeys);
	AddlParameters.Insert("OperationStatus", OperationStatus);
	
	CallbackDescription = New CallbackDescription(
		"OpenAssignOperationsFormCompletion",
		ThisObject,
		AddlParameters);
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.OperationAssignment1",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenAssignOperationsFormCompletion(AssignmentParameters, AdditionalParameters) Export
	
	If AssignmentParameters <> Undefined Then
		
		ProductionAccountingClient.GenerateProductionOperations(
			Department,
			AdditionalParameters.OperationKeys,
			AssignmentParameters,
			AdditionalParameters.OperationStatus);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationsAssignWorkCenterCompletion(ClosingResult, AddlParameters) Export
	
	If ClosingResult <> Undefined Then
		
		ClearMessages();
		
		If TypeOf(ClosingResult) = Type("Structure") Then
			OperationsAssignWorkCenterOnServer(AddlParameters.Operations,
				ClosingResult.WorkCenter,
				ClosingResult.SetupSettings);
		Else
			OperationsAssignWorkCenterOnServer(AddlParameters.Operations, ClosingResult);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OperationsAssignWorkCenterOnServer(Operations, WorkCenter, SetupSettings = Undefined)
	
	Documents.ProductionOperation2_2.AssignWorkCenterToOperations(Operations, WorkCenter, SetupSettings);
	
	Items.ExecutionOfOperations.Refresh();
	
EndProcedure

&AtClient
Procedure To_ControlCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ProductionOperation = AdditionalParameters.ProductionOperation;
	
	ProductionAccountingServerCall.RecordResultOfOFOperationControl(
		Result.ProtocolEntries, Result.RecalculateStandards, ProductionOperation);
	
	NotifyChanged(ProductionOperation);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Department);
	NotificationParameter1.Insert("Ref",        ProductionOperation);
	Notify("Write_ProductionOperation2_2", NotificationParameter1, UUID);
	
EndProcedure

#EndRegion

#Region RecordsKeys

&AtClientAtServerNoContext
Function QueueEntryKeyConstructor(Assigned_ = False, State = False)
	
	Result = New Structure;
	
	Result.Insert("Department");
	Result.Insert("Stage");
	Result.Insert("Operation");
	Result.Insert("OperationID");
	
	If Assigned_ Then
		Result.Insert("ProductionOperation");
	EndIf;
	
	If State Then
		Result.Insert("State");
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GenerateQueueEntryKey(KeyData, Changes = Undefined)
	
	KeyStringStructure = QueueEntryKeyConstructor(True, True);
	
	Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
	For Each KeyAndValue In KeyData Do
		If KeyStringStructure.Property(KeyAndValue.Key) Then
			Set.Filter[KeyAndValue.Key].Set(KeyAndValue.Value);
		EndIf;
	EndDo;
	If Changes <> Undefined Then
		For Each KeyAndValue In Changes Do
			If KeyStringStructure.Property(KeyAndValue.Key) Then
				Set.Filter[KeyAndValue.Key].Set(KeyAndValue.Value);
			EndIf;
		EndDo;
	EndIf;
	Set.Read();
	
	If Set.Count() > 0 Then
		FillPropertyValues(KeyStringStructure, Set[0]);
		RecordKey = InformationRegisters.QueueOfProductionOperations.CreateRecordKey(KeyStringStructure);
	Else
		RecordKey = Undefined;
	EndIf;
	
	Return RecordKey;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure InitializeCache()
	
	Cache = New Structure;
	
	Cache.Insert("ColorOfPressedSelection", StyleColors.QuickFiltersHyperlinkBackground);
	Cache.Insert("CurrentRowData", Undefined);
	
EndProcedure

&AtServer
Procedure ReadDivisionParameters()
	
	If Department.IsEmpty() Then
		Return;
	EndIf;
	
	FillPropertyValues(
		ThisObject,
		ProductionServer.ProductionBusinessUnitDescription(Department),
		"UseShiftTasks,UseTeamWorkOrders");
		
	ListSettings = ExecutionOfOperations.SettingsComposer.Settings;
	ListSettings.AdditionalProperties.Insert("Department", Department);
	ListSettings.AdditionalProperties.Insert("UseShiftTasks", UseShiftTasks);
	
EndProcedure

&AtServer
Procedure SetKeyToSaveWindowPosition()
	
	WindowOptionsKey = StrTemplate("%1_%2", FormName, ?(UseShiftTasks,"COSTSITEMS","WithoutSZ"));
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		KeyData = New Structure("ProductionOperation", ReferencesArrray[0]);
		Items.ExecutionOfOperations.CurrentRow = GenerateQueueEntryKey(KeyData);
		If Items.ExecutionOfOperations.CurrentRow = Undefined Then
			ShowValue(Undefined, ReferencesArrray[0]);
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
Procedure ClearInformationalMessage()
	
	InfoMessage = Undefined;
	ConfigureDependentFormElements(ThisObject, "InfoMessage");
	
EndProcedure

&AtClient
Procedure OpenProcessEditingFormCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = True Then
		Items.ExecutionOfOperations.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion