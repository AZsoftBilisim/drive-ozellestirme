
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If TypeOf(Parameters.OperationKeys) <> Type("Array")
		Or Parameters.OperationKeys.UBound() = -1 Then
		
		Raise NStr("vi = 'Không có giao dịch chuyển nhượng';
					|ru = 'Не переданы операции для назначения';
					|en = 'Operations to assign are not transferred'; fa = 'Operations to assign are not transferred';
					|it = 'Nessuna operazione trasmessa per assegnazione';
					|pl = 'Nie przekazano operacji do przeznaczenia';
					|tr = 'Atama için işlem aktarılmadı'");
		
	EndIf;
	
	OperationKeys = Parameters.OperationKeys;
	Department = Parameters.Department;
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	UseIndividuals = DivisionParameters.UsePersonalWorkOrders;
	UseAreas = DivisionParameters.UseAreas;
	OperationData = Undefined;
	
	If Not Parameters.ShiftTask.IsEmpty() And UseAreas Then
		ProductionArea = Common.ObjectAttributeValue(Parameters.ShiftTask, "ProductionArea");
	EndIf;
	
	GroupAssignment = OperationKeys.Count() > 1;
	
	If GroupAssignment Then
		
		Title = StrTemplate(NStr("vi = 'Chỉ định giao dịch (%1 chiếc)';
								|ru = 'Назначение операций (%1 шт)';
								|en = 'Operation assignment (%1 pcs)'; fa = 'Operation assignment (%1 pcs)';
								|it = 'Assegnazione delle operazioni (%1 pz)';
								|pl = 'Przeznaczenie operacji (%1 szt)';
								|tr = 'İşlemlerin ataması (%1 adet)'"), OperationKeys.Count());
		
		OnePerformer = True;
		OneKindOfRC       = True;
		OneRC          = True;
		
		For IndexOf = 1 To OperationKeys.UBound() Do
			
			OnePerformer = OnePerformer And OperationKeys[0].Performer = OperationKeys[IndexOf].Performer;
			OneKindOfRC       = OneKindOfRC And OperationKeys[0].WorkCenterType = OperationKeys[IndexOf].WorkCenterType;
			OneRC          = OneRC And OperationKeys[0].WorkCenter = OperationKeys[IndexOf].WorkCenter;
			
		EndDo;
		
		If OnePerformer And Not OperationKeys[0].Performer.IsEmpty() Then
			AssignAssignee = True;
			Performer = OperationKeys[0].Performer;
		EndIf;
		
		If OneKindOfRC And Not OperationKeys[0].WorkCenterType.IsEmpty() Then
			AssignWorkCenterKind = True;
			WorkCenterType = OperationKeys[0].WorkCenterType;
		EndIf;
		
		If OneRC
			And Not OperationKeys[0].WorkCenter.IsEmpty()
			And (ProductionArea.IsEmpty() Or Common.ObjectAttributeValue(OperationKeys[0].WorkCenter, "ProductionArea") = ProductionArea) Then
			AssignWorkCenter = True;
			WorkCenter = OperationKeys[0].WorkCenter;
		EndIf;
		
	Else
		
		Title = NStr("vi = 'Chỉ định giao dịch';
					|ru = 'Назначение операции';
					|en = 'Operation assignment'; fa = 'تخصیص عملیات';
					|it = 'Assegnazione dell''operazione';
					|pl = 'Przeznaczenie operacji';
					|tr = 'İşlem ataması'");
		
		OperationData = KeyOperationData(OperationKeys[0], UseIndividuals);
		
		If OperationData <> Undefined Then
			
			ExcludeProperties = "";
			If Not ProductionArea.IsEmpty()
				And Common.ObjectAttributeValue(OperationData.WorkCenter, "ProductionArea") <> ProductionArea Then
				ExcludeProperties = "WorkCenter";
			EndIf;
			
			FillPropertyValues(ThisObject, OperationData,, ExcludeProperties);
			
			StagePresentation = Documents.ProductionStage2_2.PresentationStage(Stage);
			
			RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
				Count,
				NumberOfPieces,
				TimePerPiece,
				SetupTime,
				ParallelLoad,
				WorkTimeFactor);
				
			RouteDetails = Catalogs.ManufacturingOperations.DetailsOfOperationRoute(OperationData.OperationOwner);
			FillPropertyValues(ThisObject, RouteDetails, "Route,RoutePresentation");
			Items.PageRoute.CurrentPage = ?(RouteDetails.RouteAvailable, Items.RouteAvailable, Items.RouteIsUnavailable);
			
		EndIf;
		
		AssignAssignee       = True;
		AssignWorkCenterKind = True;
		AssignWorkCenter      = True;
		
		AssignThePart = Parameters.AssignThePart;
		
	EndIf;
	
	CustomizeFormElements();
	ConfigureDependentFormElements(ThisForm);
	
	If Not Parameters.ShiftTask.IsEmpty() Then
		ShiftTask = Parameters.ShiftTask;
	EndIf;
	
	If ValueIsFilled(ShiftTask) Then
		DateOfShiftTask = Common.ObjectAttributeValue(ShiftTask, "Date");
	EndIf;
	
	Date = ?(ValueIsFilled(DateOfShiftTask), DateOfShiftTask, CurrentSessionDate());
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(Date);
	
	If ValueIsFilled(Parameters.Performer) Then
		Performer = Parameters.Performer;
	ElsIf Performer = Undefined Then
		If UseIndividuals Then
			Performer = Catalogs.Persons.EmptyRef();
		Else
			Performer = Catalogs.Teams.EmptyRef();
		EndIf;
	EndIf;
	
	If Not Parameters.WorkCenter.IsEmpty()
		And (ProductionArea.IsEmpty() Or Common.ObjectAttributeValue(Parameters.WorkCenter, "ProductionArea") = ProductionArea) Then
		WorkCenter = Parameters.WorkCenter;
	EndIf;
	
	If Not Parameters.WorkCenterType.IsEmpty() Then
		WorkCenterType = Parameters.WorkCenterType;
	EndIf;
	
	AddressOperationKeys = PutToTempStorage(OperationKeys, UUID);
	
	If Parameters.SelectAssignee Then
		CurrentItem = Items.Performer;
	ElsIf Parameters.ChoosingARC Then
		CurrentItem = Items.WorkCenter;
	ElsIf Parameters.SelectingTheTypeOfRC Then
		CurrentItem = Items.WorkCenterType;
	ElsIf Parameters.EnterQuantity Then
		CurrentItem = Items.Count;
	Else
		CurrentItem = Items.ShiftTask;
	EndIf;
	
	Links = CommonClientServer.ValueInArray(
		New ChoiceParameterLink("Filter.WorkCenterType", "WorkCenterType"));
	If UseAreas Then
		Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
	EndIf;
	Items.WorkCenter.ChoiceParameterLinks = New FixedArray(Links);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If GroupAssignment Then
		
		IndexOf = CheckedAttributes.Find("Count");
		If IndexOf <> Undefined Then
			CheckedAttributes.Delete(IndexOf);
		EndIf;
		
	EndIf;
	
	If Not AssignAssignee
		And Not AssignWorkCenterKind
		And Not AssignWorkCenter Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Điểm đến không được chỉ định';
				|ru = 'Не указан объект назначения';
				|en = 'Destination object is not specified'; fa = 'Destination object is not specified';
				|it = 'Nessun oggetto di assegnazione specificato';
				|pl = 'Nie wskazano obiektu przeznaczenia';
				|tr = 'Atama nesnesi belirtilmedi'"),,,,
			Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShiftTaskOnChange(Item)
	
	If UseAreas Then
		
		WorkCenter = Undefined;
		
		If Not ShiftTask.IsEmpty() Then
			
			ObjectAttributes = ObjectAttributesValues(ShiftTask, "ProductionArea, Date");
			ProductionArea = ObjectAttributes.ProductionArea;
			DateOfShiftTask = ObjectAttributes.Date;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Undefined,
		Department,
		Performer,
		DateOfShiftTask,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Performer = Result;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department, DateOfShiftTask);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Department, DateOfShiftTask);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
		Count,
		NumberOfPieces,
		TimePerPiece,
		SetupTime,
		ParallelLoad,
		WorkTimeFactor);
		
	ConfigureDependentFormElements(ThisForm, "Count");
	
EndProcedure

&AtClient
Procedure RunTimeOnChange(Item)
	WorkTimeFactor = WorkTimeFactor(WorkCenter);
	Count = ProductionAccountingClientServer.CalculateAmountOfOperationFromTime(
		RunTime,
		TimePerPiece,
		SetupTime,
		NumberOfPieces,
		WorkTimeFactor);
	
	ConfigureDependentFormElements(ThisForm, "Count");
	
EndProcedure

&AtClient
Procedure AssignAssigneeOnChange(Item)
	
	Items.Performer.Enabled = AssignAssignee;
	
	If Not AssignAssignee Then
		If UseIndividuals Then
			Performer = PredefinedValue("Catalog.Persons.EmptyRef");
		Else
			Performer = PredefinedValue("Catalog.Teams.EmptyRef");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignWorkCenterKindOnChange(Item)
	
	Items.WorkCenterType.Enabled = AssignWorkCenterKind;
	
	If Not AssignWorkCenterKind Then
		
		WorkCenterType = Undefined;
		
		If AssignWorkCenter Then
			
			AssignWorkCenter = False;
			Items.WorkCenter.Enabled = False;
			WorkCenter = Undefined;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignWorkCenterOnChange(Item)
	
	Items.WorkCenter.Enabled = AssignWorkCenter;
	
	If Not AssignWorkCenter Then
		WorkCenter = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure StagePresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, Stage);
	
EndProcedure

&AtClient
Procedure WorkCenterTypeOnChange(Item)
	
	If Not GroupAssignment
		And Not WorkCenterType.IsEmpty() Then
		
		ParallelLoad = ParallelLoad(WorkCenterType);
		WorkTimeFactor = WorkTimeFactor(WorkCenter);
		RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
			Count,
			NumberOfPieces,
			TimePerPiece,
			SetupTime,
			ParallelLoad,
			WorkTimeFactor);
			
		ConfigureDependentFormElements(ThisForm, "ParallelLoad");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkCenterOnChange(Item)
	
	WorkTimeFactor = WorkTimeFactor(WorkCenter);

	RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
		Count,
		NumberOfPieces,
		TimePerPiece,
		SetupTime,
		ParallelLoad,
		WorkTimeFactor);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Close(AssignOnServer());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements() 
	
	Items.AssignAssignee.Visible       = GroupAssignment;
	Items.AssignWorkCenterKind.Visible = GroupAssignment;
	Items.AssignWorkCenter.Visible      = GroupAssignment;
	
	ShowTitle_ = ?(GroupAssignment,
		FormItemTitleLocation.None, FormItemTitleLocation.Auto);
	Items.Performer.TitleLocation       = ShowTitle_;
	Items.WorkCenterType.TitleLocation = ShowTitle_;
	Items.WorkCenter.TitleLocation      = ShowTitle_;
	
	Items.Performer.InputHint       = ?(GroupAssignment, NStr("vi = 'Người thực hiện';
																|ru = 'Исполнитель';
																|en = 'Assignee'; fa = 'Assignee';
																|it = 'Esecutore';
																|pl = 'Assignee';
																|tr = 'Atanan'"), "");
	Items.WorkCenterType.InputHint = ?(GroupAssignment, NStr("vi = 'Dạng nguồn lực sản xuất';
															|ru = 'Вид рабочего центра';
															|en = 'Work center type'; fa = 'نوع مرکز کاری';
															|it = 'Tipo di centro di lavoro';
															|pl = 'Rodzaj centrum wykonania pracy';
															|tr = 'İş merkezi türü'"), "");
	Items.WorkCenter.InputHint      = ?(GroupAssignment, NStr("vi = 'Nguồn lực sản xuất';
																|ru = 'Рабочий центр';
																|en = 'Work center'; fa = 'مرکز کاری';
																|it = 'Centro di lavoro';
																|pl = 'Centrum pracy';
																|tr = 'İş merkezi'"), "");
	
	Items.Performer.Enabled       = AssignAssignee;
	Items.WorkCenterType.Enabled = AssignWorkCenterKind;
	Items.WorkCenter.Enabled      = AssignWorkCenter;
	
	Items.Count.Visible                    = Not GroupAssignment;
	Items.UnitOfMeasurePresentation.Visible = Not GroupAssignment;
	Items.RunTime.Visible               = Not GroupAssignment;
	Items.ExecutionTimeUnitOfMeasure.Visible          = Not GroupAssignment;
	Items.Operation.Visible                      = Not GroupAssignment;
	Items.Route.Visible                       = Not GroupAssignment;
	Items.StagePresentation.Visible             = Not GroupAssignment;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Setting up the Quantity element
	If Initialize
		Or AttributesStructure1.Property("Count") Then
		
		Form.UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Form.UnitOfMeasure,
			Form.Count);
		
	EndIf;
		
	If Initialize
		Or AttributesStructure1.Property("ParallelLoad") Then
		
		Form.Items.RunTime.ReadOnly = Form.ParallelLoad;
		
	EndIf;
	
EndProcedure

&AtServer
Function KeyOperationData(OperationKey, UseIndividuals)
	
	Query = New Query(
		"SELECT
		|	Operations.ShiftTask                                     AS ShiftTask,
		|	Operations.Stage                                               AS Stage,
		|	CASE
		|		WHEN (Operations.Performer = VALUE(Catalog.Persons.EmptyRef)
		|				)
		|				AND NOT &UseIndividuals
		|			THEN VALUE(Catalog.Teams.EmptyRef)
		|		ELSE Operations.Performer
		|	END                                                       AS Performer,
		|	Operations.WorkCenter                                       AS WorkCenter,
		|	Operations.WorkCenterType                                  AS WorkCenterType,
		|	Operations.WorkCenterType.ParallelLoad             AS ParallelLoad,
		|	Operations.Operation                                           AS Operation,
		|	Operations.Count                                         AS Count,
		|	Operations.TimeUnitsOfMeasure                                         AS ExecutionTimeUnitOfMeasure,
		|	Operations.TimePerPiece                                       AS TimePerPiece,
		|	Operations.SetupTime                                            AS SetupTime,
		|	Operations.Operation.Owner                                  AS OperationOwner,
		|	ISNULL(Operations.Operation.Description, Queue.ProductionOperation.Description)         AS Description,
		|	ISNULL(Operations.Operation.Count, 1)                                                       AS NumberOfPieces,
		|	ISNULL(Operations.Operation.UnitOfMeasure, Queue.ProductionOperation.UnitOfMeasure) AS UnitOfMeasure,
		|	ISNULL(Operations.WorkCenter.WorkTimeFactor, 1)                                     AS WorkTimeFactor
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
		|		ON Operations.Stage = Queue.Stage
		|		AND Operations.Operation = Queue.Operation
		|		AND Operations.OperationID = Queue.OperationID
		|		AND Queue.MainEntry_
		|WHERE
		|	Operations.Department = &Department
		|	AND Operations.Stage = &Stage
		|	AND Operations.Operation = &Operation
		|	AND Operations.OperationID = &OperationID
		|	AND Operations.ShiftTask = &ShiftTask
		|	AND Operations.Performer = &Performer
		|	AND Operations.WorkCenter = &WorkCenter
		|	AND Operations.WorkCenterType = &WorkCenterType
		|	AND Operations.AssignNotEarlierThan = &AssignNotEarlierThan");
	
	Query.SetParameter("Department", OperationKey.Department);
	Query.SetParameter("Stage", OperationKey.Stage);
	Query.SetParameter("Operation", OperationKey.Operation);
	Query.SetParameter("OperationID", OperationKey.OperationID);
	Query.SetParameter("ShiftTask", OperationKey.ShiftTask);
	Query.SetParameter("Performer", OperationKey.Performer);
	Query.SetParameter("WorkCenter", OperationKey.WorkCenter);
	Query.SetParameter("WorkCenterType", OperationKey.WorkCenterType);
	Query.SetParameter("AssignNotEarlierThan", OperationKey.AssignNotEarlierThan);
	Query.SetParameter("UseIndividuals", UseIndividuals);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function AssignOnServer()
	
	OperationKeys = GetFromTempStorage(AddressOperationKeys);
	
	AssignmentParameters = InformationRegisters.OperationsToCreateShiftTasks.ParametersForAssigningOperations();
	
	AssignmentParameters.Dimensions.ShiftTask = ShiftTask;
	If AssignAssignee Then
		AssignmentParameters.Dimensions.Performer = Performer;
	EndIf;
	If AssignWorkCenter Then
		AssignmentParameters.Dimensions.WorkCenter = WorkCenter;
	EndIf;
	If AssignWorkCenterKind Then
		AssignmentParameters.Dimensions.WorkCenterType = WorkCenterType;
	EndIf;
	
	If Not GroupAssignment Then
		AssignmentParameters.Count = Count;
		AssignmentParameters.AssignThePart = AssignThePart;
	EndIf;
	
	InformationRegisters.OperationsToCreateShiftTasks.AssignOperations(
		OperationKeys,
		AssignmentParameters);
	
	Result = New Structure;
	Result.Insert("ShiftTask", ShiftTask);
	Result.Insert("Performer", Performer);
	Result.Insert("WorkCenter", WorkCenter);
	Result.Insert("WorkCenterType", WorkCenterType);
	Result.Insert("OperationKeys", OperationKeys);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, DateOfShiftTask)
	
	ChoiceData = New ValueList;
	
	FillParameters = New Structure;
	FillParameters.Insert("Department", Department);
	FillParameters.Insert("Organization", Undefined);
	FillParameters.Insert("Date", DateOfShiftTask);
	
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FillParameters);
	
EndProcedure

&AtServerNoContext
Function ObjectAttributesValues(Ref, AttributesNames)
	
	Return Common.ObjectAttributesValues(Ref, AttributesNames);
	
EndFunction

&AtServerNoContext
Function WorkTimeFactor(WorkCenter)
	
	If Not WorkCenter.IsEmpty() Then
		WorkTimeFactor = Common.ObjectAttributeValue(WorkCenter, "WorkTimeFactor");
	Else
		WorkTimeFactor = 1;
	EndIf;
	
	Return WorkTimeFactor;
	
EndFunction

&AtServerNoContext
Function ParallelLoad(WorkCenterType)
	
	Return Common.ObjectAttributeValue(WorkCenterType, "ParallelLoad");
	
EndFunction

#EndRegion
