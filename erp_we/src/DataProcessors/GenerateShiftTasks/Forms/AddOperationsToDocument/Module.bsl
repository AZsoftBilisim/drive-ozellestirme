
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	LoadSettings();
	
	PickMode = Parameters.PickMode;
	
	If Not Parameters.ShiftTask.IsEmpty() Then
		
		Title = StrTemplate(
			?(PickMode, NStr("vi = 'Lựa chọn giao dịch trong %1';
							|ru = 'Подбор операций в %1';
							|en = 'Pick operations to %1'; fa = 'Pick operations to %1';
							|it = 'Selezione delle operazioni in %1';
							|pl = 'Wybór operacji w %1';
							|tr = 'İşlemlerin %1 içine seçimi'"), NStr("vi = 'Thêm giao dịch vào %1';
																	|ru = 'Добавление операции в %1';
																	|en = 'Add operation to %1'; fa = 'Add operation to %1';
																	|it = 'Aggiunta dell''operazione in %1';
																	|pl = 'Dodanie operacji do %1';
																	|tr = 'İşlemlerin %1 içine eklenmesi'")),
			Parameters.ShiftTask);
		
		FillPropertyValues(ThisForm,
			Common.ObjectAttributesValues(Parameters.ShiftTask, "Date, Department, ProductionArea"));
		
	Else
		
		Title = ?(PickMode, NStr("vi = 'Lựa chọn giao dịch';
								|ru = 'Подбор операций';
								|en = 'Pick operations'; fa = 'انتخاب عملیات';
								|it = 'Selezione operazioni';
								|pl = 'Wybór operacji';
								|tr = 'İşlem seçimi'"), NStr("vi = 'Thêm giao dịch';
																|ru = 'Добавление операции';
																|en = 'Add operations'; fa = 'افزودن عملیات';
																|it = 'Aggiungere l''operazione';
																|pl = 'Dodanie operacji';
																|tr = 'İşlem ekleme'"));
		
	EndIf;
	
	// List request text
	QueryTextList = StrReplace(
		List.QueryText,
		"&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("RegisterOverridable.Stage"));
	QueryTextList = StrReplace(
		QueryTextList,
		"&RunTime",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("RegisterOverridable"));
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryTextList;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	// Selecting a list
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Department",
		Department,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Department));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"ShiftTask",
		,
		DataCompositionComparisonType.NotFilled,,
		True);
		
	// Other
	If Not Department.IsEmpty() Then
		
		UseTeamWorkOrders = 
			ProductionServer.ProductionBusinessUnitDescription(Department).UseTeamWorkOrders;
			
		SetFormFunctionalOptionParameters(New Structure("Department", Department));
		
	EndIf;
	
	If DisplayMode = 0 Then
		DisplayMode = ViewingModeCanBeAssigned();
	EndIf;
	
	Items.PickOperations.Visible = PickMode;
	
	SelectedModeColor = StyleColors.FormTextColor;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	
	Links = CommonClientServer.ValueInArray(
		New ChoiceParameterLink("Filter.WorkCenterType", "Items.PickOperations.CurrentData.WorkCenterType"));
	If Not ProductionArea.IsEmpty() Then
		Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
	EndIf;
	Items.PickOperationsWorkCenter.ChoiceParameterLinks = New FixedArray(Links);
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(Date);
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssignmentIsAllowedClick(Item)
	
	DisplayMode = ViewingModeCanBeAssigned();
	
	ShouldSaveSettings(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "DisplayMode");
	
EndProcedure

&AtClient
Procedure AllForAssignmentClick(Item)
	
	DisplayMode = ViewAllToDestinationMode();
	
	ShouldSaveSettings(ThisForm);
	
	ConfigureDependentFormElements(ThisForm, "DisplayMode");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(RowSelected) = Type("DynamicListGroupRow") Then
		
		ShowMessageBox(, NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
								|ru = 'Действие не может быть выполнено для строки группировки списка';
								|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
								|it = 'L''operazione non può essere eseguita per la riga di raggruppamento dell''elenco';
								|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
								|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
		Return;
		
	EndIf;
	
	AddLineToOperationsSelection(RowSelected);
	
	If Not PickMode Then
		
		MoveToDocument();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPickOperations

&AtClient
Procedure PickOperationsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PickOperationsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PickOperations.CurrentData;
	
	ProductionManagementClientServer.SetArtistType(
		CurrentData.Performer,
		UseTeamWorkOrders,
		AccountingForLaborCostsByEmployees);
	
EndProcedure

&AtClient
Procedure PickOperationsPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PickOperations.CurrentData;
	
	CallbackDescription = New CallbackDescription("PickOperationsPerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Undefined,
		Department,
		CurrentData.Performer,
		Date,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PickOperationsPerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	CurrentData = Items.PickOperations.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		
		CurrentData.Performer = Result;
		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickOperationsPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department, Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickOperationsPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department, Date);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickOperationsCountOnChange(Item)
	
	CurrentData = Items.PickOperations.CurrentData;
	
	CurrentData.RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
		CurrentData.Count,
		CurrentData.NumberOfPieces,
		CurrentData.TimePerPiece,
		CurrentData.SetupTime,
		CurrentData.ParallelLoad,
		CurrentData.WorkTimeFactor);
	
EndProcedure

&AtClient
Procedure PickOperationsRunTimeOnChange(Item)
	
	CurrentData = Items.PickOperations.CurrentData;
	
	CurrentData.Count = ProductionAccountingClientServer.CalculateAmountOfOperationFromTime(
		CurrentData.RunTime,
		CurrentData.TimePerPiece,
		CurrentData.SetupTime,
		CurrentData.NumberOfPieces,
		CurrentData.WorkTimeFactor);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveCommandToTheDocument(Command)
	
	If Not PickMode Then
		
		CurrentRow = Items.List.CurrentRow;
		
		If CurrentRow = Undefined Then
			
			ShowMessageBox(, NStr("vi = 'Không có thao tác nào được chọn';
									|ru = 'Не выбрана операция';
									|en = 'Operation is not selected'; fa = 'Operation is not selected';
									|it = 'Nessuna operazione selezionata';
									|pl = 'Nie wybrano operacji';
									|tr = 'İşlem seçilmedi'"));
			Return;
			
		ElsIf TypeOf(CurrentRow) = Type("DynamicListGroupRow") Then
			
			ShowMessageBox(, NStr("vi = 'Thao tác không thể được thực hiện trên một dòng nhóm danh sách.';
									|ru = 'Действие не может быть выполнено для строки группировки списка';
									|en = 'Action cannot be executed for the list grouping row'; fa = 'Action cannot be executed for the list grouping row';
									|it = 'L''operazione non può essere eseguita per la riga di raggruppamento dell''elenco';
									|pl = 'Czynność nie może być wykonana dla wiersza grupowania listy';
									|tr = 'Liste gruplandırma satırı için eylem gerçekleştirilemez'"));
			Return;
			
		Else
			
			AddLineToOperationsSelection(CurrentRow);
			
		EndIf;
		
	EndIf;
	
	MoveToDocument();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// List - unit of execution time per Second
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Second;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giây';
																					|ru = 'сек';
																					|en = 'sec'; fa = 'ثانیه';
																					|it = 'sec';
																					|pl = 'sec';
																					|tr = 'sn.'"))); // @Format-2
	
	// List - unit of execution time per Minute
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Minute;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'phút';
																					|ru = 'мин';
																					|en = 'min'; fa = 'دقیقه';
																					|it = 'min';
																					|pl = 'min';
																					|tr = 'dk.'"))); // @Format-2
	
	// List - unit of execution time per Hour
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Hour;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'giờ';
																					|ru = 'ч';
																					|en = 'h'; fa = 'ساعت';
																					|it = 'ore';
																					|pl = 'godz.';
																					|tr = 'sa.'"))); // @Format-2
	
	// List - units of execution time per Day
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListRunTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ExecutionTimeUnitOfMeasure");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TimeMeasureUnits.Days1;
	
	Item.Appearance.SetParameterValue("Format", StrTemplate("NFD=1; NF='Ч %1'", NStr("vi = 'ngày';
																					|ru = 'сут';
																					|en = 'd'; fa = 'روز';
																					|it = '24 ore';
																					|pl = 'dob.';
																					|tr = 'gün'"))); // @Format-2
	
	// List - the lines to be assigned are highlighted in red font
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ToBeAssigned");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// List - lines unavailable for assignment are highlighted in gray font
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AssignmentIsAllowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ToBeAssigned");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// List - Stage view
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ListStage.Name);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("List.PresentationStage"));
	
	// Selection of operations - stage presentation
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PickOperationsStage.Name);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.PickOperations.PresentationStage"));
	
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.PickOperationsPerformer.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PickOperations.LaborGradeJobTitleMismatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("DisplayMode") 
		Or Initialize Then
		
		Items.AssignmentIsAllowed.Hyperlink  = Form.DisplayMode <> ViewingModeCanBeAssigned();
		Items.AssignmentIsAllowed.TextColor = ?(Form.DisplayMode <> ViewingModeCanBeAssigned(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		Items.AllForAssignment.Hyperlink  = Form.DisplayMode <> ViewAllToDestinationMode();
		Items.AllForAssignment.TextColor = ?(Form.DisplayMode <> ViewAllToDestinationMode(),
			Form.UnselectedModeColor, Form.SelectedModeColor);
		
		//
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.List,
			"AssignNotEarlierThan",
			Form.Date,
			DataCompositionComparisonType.LessOrEqual,,
			Form.DisplayMode = ViewingModeCanBeAssigned() And ValueIsFilled(Form.Date));
		
		//
		
		CommonClientServer.SetDynamicListFilterItem(
			Form.List,
			"AssignmentIsAllowed",
			True,
			DataCompositionComparisonType.Equal,,
			Form.DisplayMode = ViewingModeCanBeAssigned());
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, Date)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Organization, Department, Date");
	FilterParameters.Department = Department;
	FilterParameters.Date = Date;
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

&AtClient
Procedure AddLineToOperationsSelection(OperationKey)
	
	RowData = Items.List.RowData(OperationKey);
	
	FoundRows = Object.PickOperations.FindRows(New Structure("OperationKey", OperationKey));
	If FoundRows.UBound() <> -1 Then
		ShowMessageBox(,NStr("vi = 'Đã thêm giao dịch được chọn.';
							|ru = 'Выбранная операция уже добавлена.';
							|en = 'The selected operation is already added.'; fa = 'The selected operation is already added.';
							|it = 'The selected operation is already added.';
							|pl = 'The selected operation is already added.';
							|tr = 'Seçilen işlem zaten eklendi.'"));
		Return;
	EndIf;
	
	ExcludeProperties = "";
	If Not ProductionArea.IsEmpty() Then
		
		If ProductionArea <> RowData.SectionOfWorkCenter Then
			ExcludeProperties = "WorkCenter";
		EndIf;
		
		If ProductionArea <> RowData.ProductionArea Then
		
			If IsBlankString(ExcludeProperties) Then
				ExcludeProperties = "ProductionArea";
			Else
				ExcludeProperties = ExcludeProperties + " ,ProductionArea";
			EndIf;
			
		EndIf;
		
	EndIf;
	
	NewRow = Object.PickOperations.Add();
	FillPropertyValues(NewRow, RowData,, ExcludeProperties);
	NewRow.OperationKey = OperationKey;
	
EndProcedure

&AtClient
Procedure MoveToDocument()
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	StartWaiting = MoveToDocumentInBackground();
	
	If StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("MoveToDocumentInBackgroundCompletion", ThisObject),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		Close(True);
		
	EndIf;
	
EndProcedure

&AtServer
Function MoveToDocumentInBackground()
	
	Operations = FormAttributeToValue("Object").PickOperations.Unload();
	Operations.Columns.Delete("LineNumber");
	ProductionServer.CollapseValueTable(Operations,,"Count");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Operations", Operations);
	ProcedureParameters.Insert("ShiftTask", Parameters.ShiftTask);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Lựa chọn giao dịch trong một nhiệm vụ thay đổi';
			|ru = 'Подбор операций в сменное задание';
			|en = 'Pick operations for shift task'; fa = 'Pick operations for shift task';
			|it = 'Selezione delle operazioni nel task di turno';
			|pl = 'Wybór operacji do zadania zmianowego';
			|tr = 'Vardiyalı göreve işlem seçimi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"InformationRegisters.OperationsToCreateShiftTasks.AddToTaskInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		
		StartWaiting = True;
		
	Else
		
		ProcessResultOfBackgroundTask(TimeConsumingOperation);
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return StartWaiting;
	
EndFunction

&AtClient
Procedure MoveToDocumentInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ProcessResultOfBackgroundTask(Result);
		
		Close(True);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfBackgroundTask(Result)
	
	If Result.Status = "Error" Then
		
		ResultStructure = GetFromTempStorage(Result.ResultAddress);
		
		If TypeOf(ResultStructure) = Type("Structure") And ResultStructure.Property("Messages") Then
			
			For Each Message In ResultStructure.Messages Do
			
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ViewingModeCanBeAssigned()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function ViewAllToDestinationMode()
	
	Return 2;
	
EndFunction

&AtServer
Procedure LoadSettings()
	
	Settings = Common.CommonSettingsStorageLoad(
		"OperationsToCreateShiftTasks.PickOperations",
		Undefined);
	
	If TypeOf(Settings) = Type("Structure") Then
		
		Settings.Property("DisplayMode",  DisplayMode);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ShouldSaveSettings(Form)
	
	Settings = New Structure;
	
	Settings.Insert("DisplayMode",  Form.DisplayMode);
	
	WriteSettingsToStorage(Settings);
	
EndProcedure

&AtServerNoContext
Procedure WriteSettingsToStorage(Settings)
	
	Common.CommonSettingsStorageSave(
		"OperationsToCreateShiftTasks.PickOperations",
		Undefined,
		Settings);
	
EndProcedure


#EndRegion
