
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillInServiceDetails();
	
	PopulateFormByParameters();

	FillInStageTable();
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionStages"
			Or EventName = "Write_ProductionOperation2_2" Then
		UpdateData1();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOperationStatusOnChange(Item)
	
	If FilterOperationStatus = SelectionStateOfOperationsNotStarted() Then
		AbortOperation = Undefined;
		OperationContinue = Undefined;
	EndIf;
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure CurrentProcessTechnologyOnChange(Item)
	
	FilterBOMStage = Undefined;
	
	TechnicalProcessIsCurrentOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure CurrentProcessTechnologyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ConfigureProcessSelectionParameters(ThisObject, Item, ValueSelected);
	
	If ValueIsFilled(ValueSelected)
		And TypeOf(ValueSelected) = Type("CatalogRef.BillsOfMaterials") Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", New Structure("Owner", ValueSelected));
		
		Notification = New CallbackDescription("ProcessingSelectionOfBillOfMaterialsStageOfEnd", ThisObject);
		
		OpenForm("Catalog.ProductionStages.ChoiceForm", FormParameters, ThisObject,,,, Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrentProcessTechnologyClearing(Item, StandardProcessing)
	
	CurrentProcessTechnology = Item.TypeRestriction.AdjustValue(Undefined);
	
EndProcedure

&AtClient
Procedure ProcessTechnologyIsNewOnChange(Item)
	
	ProcessIsNewOnChangeATServer();
	
EndProcedure

&AtClient
Procedure ProcessTechnologyIsNewClearing(Item, StandardProcessing)
	
	ProcessTechnologyIsNew = Item.TypeRestriction.AdjustValue(Undefined);
	
EndProcedure

&AtClient
Procedure AbortOperationOnChange(Item)
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure OperationContinueOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure FilterOnChange(Item)
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure FilterBOMStageOnChange(Item)
	
	TechnicalProcessIsCurrentOnChangeAtServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStages

&AtClient
Procedure StagesSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Undefined;
	CurrentData = Item.CurrentData;
	
	If Field.Name = "StagesStage" Then
		Value = CurrentData.Stage;
	ElsIf Field.Name = "StagesReferenceOrder" Then
		Value = CurrentData.ReferenceOrder;
	ElsIf Field.Name = "StagesProduct" Then
		Value = CurrentData.Product;
	EndIf;
	
	If ValueIsFilled(Value) Then
		StandardProcessing = False;
		ShowValue(,Value);
	EndIf;
	
EndProcedure

&AtClient
Procedure StagesOnActivateRow(Item)
	
	ConfigureStageSelectionParameters(ThisObject, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PerformAReplacement_3(Command)
	
	ClearMessages();
	
	If CheckProcessReplacementSettings() Then
		
		StartReplacingProcessTechnology();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FindStages(Command)
	
	UpdateData1();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	FormattedField = Item.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("StepsUnitOfMeasurement");
	
	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Stages.Package");
	FilterElement.ComparisonType  = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ConfigureProcessSelectionElements();
	
	ConfigureStageSelectionParameters(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Operations") Or Initialize Then
		
		Items.OperationsGroup.Visible = Form.FilterOperationStatus = SelectionStateOfOperationsStarted();
		
		CustomizeExplanationText(Form);
		
	EndIf;
	
	If AttributesStructure1.Property("TechnicalProcess") Or Initialize Then
		
		CurrentProcessBillOfMaterials = TypeOf(Form.CurrentProcessTechnology) = Type("CatalogRef.BillsOfMaterials");
		
		Items.FilterOperationStatus.ReadOnly = Not ValueIsFilled(Form.FilterDepartment)
			Or Form.DivisionParameters.UseManufacturingExecutionSystem;
		
		Items.FilterBOMStage.AutoMarkIncomplete = CurrentProcessBillOfMaterials;
		Items.FilterBOMStage.MarkIncomplete = Items.FilterBOMStage.AutoMarkIncomplete
			And Not ValueIsFilled(Form.CurrentProcessTechnology);
		Items.AbortOperation.ReadOnly = Not ValueIsFilled(Form.CurrentProcessTechnology)
			Or Not ValueIsFilled(Form.FilterBOMStage) And CurrentProcessBillOfMaterials;
		Items.OperationContinue.ReadOnly = Not ValueIsFilled(Form.ProcessTechnologyIsNew);
		
	EndIf; 
	
EndProcedure

&AtServer
Procedure ConfigureProcessSelectionElements()
	
	Types = New Array;
	
	If GetFunctionalOption("UseTechnologicalProcesses") Then
		Types.Add(Type("CatalogRef.TechnologicalProcesses"));
	EndIf;
	Items.ProcessTechnologyIsNew.TypeRestriction = New TypeDescription(Types);
	ProcessTechnologyIsNew = Items.ProcessTechnologyIsNew.TypeRestriction.AdjustValue(ProcessTechnologyIsNew);
	
	Types.Add(Type("CatalogRef.BillsOfMaterials"));
	Items.CurrentProcessTechnology.TypeRestriction = New TypeDescription(Types);
	CurrentProcessTechnology = Items.CurrentProcessTechnology.TypeRestriction.AdjustValue(CurrentProcessTechnology);
	
	ConfigureProcessSelectionParameters(ThisObject, Items.CurrentProcessTechnology, TypeOf(CurrentProcessTechnology));
	ConfigureProcessSelectionParameters(ThisObject, Items.ProcessTechnologyIsNew, TypeOf(ProcessTechnologyIsNew));
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureProcessSelectionParameters(Form, Item, ValueSelected)
	
	If TypeOf(ValueSelected) <> Type("Type") Then
		Return;
	EndIf;
	
	ChoiceParameters = New Array;
	ChoiceParameters.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	If ValueSelected = Type("CatalogRef.BillsOfMaterials") Then
		ChoiceParameters.Add(New ChoiceParameter("FilterStatus", PredefinedValue("Enum.BOMStatuses.Valid")));
	ElsIf ValueSelected = Type("CatalogRef.TechnologicalProcesses") Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.Status", PredefinedValue("Enum.TechnologicalProcessStatuses.Valid")));
	ElsIf ValueSelected = Type("CatalogRef.RouteSheets") Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.Status", PredefinedValue("Enum.StatusesOfRouteSheets.Valid")));
	EndIf;
	
	ChoiceParameters.Add(New ChoiceParameter("UnitViewOnly", True));
	ChoiceParameters.Add(New ChoiceParameter("StatusViewOnly", True));
	
	Item.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureStageSelectionParameters(Form, OnActivateRow = False)
	
	ChoiceParameters = New Array;
	ChoiceParameters.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	If ValueIsFilled(Form.CurrentProcessTechnology) And TypeOf(Form.CurrentProcessTechnology) = Type("CatalogRef.BillsOfMaterials") Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", Form.CurrentProcessTechnology));
		ChoiceParameters.Add(New ChoiceParameter("AllowChangeOfOwnership", False));
	ElsIf ValueIsFilled(Form.FilterBOMStage) And OnActivateRow Then
		Return;
	ElsIf ValueIsFilled(Form.FilterBOMStage) Then
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", BillOfMaterialsOfStage(Form.FilterBOMStage)));
		ChoiceParameters.Add(New ChoiceParameter("AllowChangeOfOwnership", True));
	ElsIf Form.Items.Stages.CurrentRow <> Undefined Then
		CurrentData = Form.Stages.FindByID(Form.Items.Stages.CurrentRow);
		ChoiceParameters.Add(New ChoiceParameter("Filter.Owner", CurrentData.BillOfMaterials));
		ChoiceParameters.Add(New ChoiceParameter("AllowChangeOfOwnership", True));
	EndIf;
	
	Form.Items.FilterBOMStage.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeExplanationText(Form)
	
	ExplanationText = "";
	
	Operation1 = AbortOperationPresentation(Form);
	Operation2 = OperationContinuePresentation(Form);
	
	If Form.FilterOperationStatus = SelectionStateOfOperationsNotStarted() Then
		ExplanationText = NStr("vi = 'Quy trình công nghệ hiện tại sẽ được thay thế hoàn toàn bằng quy trình công nghệ mới.';
								|ru = 'Текущий техпроцесс будет полностью заменен новым.';
								|en = 'The current technological process will be completely replaced with a new one.'; fa = 'The current technological process will be completely replaced with a new one.';
								|it = 'The current technological process will be completely replaced with a new one.';
								|pl = 'The current technological process will be completely replaced with a new one.';
								|tr = 'Mevcut teknolojik süreç tamamen yenisiyle değiştirilecektir.'");
	ElsIf Not ValueIsFilled(Operation1) And Not ValueIsFilled(Operation2) Then
		ExplanationText = NStr("vi = 'Sau thao tác cuối cùng của quy trình công nghệ hiện tại, việc thực hiện sẽ tiếp tục từ thao tác đầu tiên của quy trình công nghệ mới.';
								|ru = 'После последней операции текущего техпроцесса выполнение будет продолжено с первой операции нового техпроцесса.';
								|en = 'After the last operation of the current technological process, execution will continue from the first operation of the new technological process.'; fa = 'After the last operation of the current technological process, execution will continue from the first operation of the new technological process.';
								|it = 'After the last operation of the current technological process, execution will continue from the first operation of the new technological process.';
								|pl = 'After the last operation of the current technological process, execution will continue from the first operation of the new technological process.';
								|tr = 'Mevcut teknolojik sürecin son işleminden sonra, yürütme yeni teknolojik sürecin ilk işleminden itibaren devam edecektir.'");
	ElsIf ValueIsFilled(Operation1) And Not ValueIsFilled(Operation2) Then
		ExplanationText = StrTemplate(
			NStr("vi = 'Việc thực hiện quy trình công nghệ hiện tại sẽ bị ngắt sau thao tác ""%1"" và tiếp tục từ thao tác đầu tiên của quy trình công nghệ mới.';
				|ru = 'Выполнение текущего техпроцесса будет прервано после операции ""%1"" и продолжено с первой операции нового техпроцесса.';
				|en = 'The current technological process will be interrupted after the ""%1"" operation and continued from the first operation of the new technological process.'; fa = 'The current technological process will be interrupted after the ""%1"" operation and continued from the first operation of the new technological process.';
				|it = 'The current technological process will be interrupted after the ""%1"" operation and continued from the first operation of the new technological process.';
				|pl = 'The current technological process will be interrupted after the ""%1"" operation and continued from the first operation of the new technological process.';
				|tr = 'Mevcut teknolojik sürecin yürütülmesi ""%1"" işleminden sonra kesintiye uğrayacak ve yeni teknolojik sürecin ilk işleminden itibaren devam edecektir.'"),
				Operation1);
	ElsIf Not ValueIsFilled(Operation1) And ValueIsFilled(Operation2) Then
		ExplanationText = StrTemplate(
			NStr("vi = 'Sau thao tác cuối cùng của quy trình công nghệ hiện tại, việc thực hiện sẽ tiếp tục từ thao tác ""%1"" của quy trình công nghệ mới.';
				|ru = 'После последней операции текущего техпроцесса выполнение будет продолжено с операции ""%1"" нового техпроцесса.';
				|en = 'After the last operation of the current technological process, execution will continue from the ""%1"" operation of the new technological process.'; fa = 'After the last operation of the current technological process, execution will continue from the ""%1"" operation of the new technological process.';
				|it = 'After the last operation of the current technological process, execution will continue from the ""%1"" operation of the new technological process.';
				|pl = 'After the last operation of the current technological process, execution will continue from the ""%1"" operation of the new technological process.';
				|tr = 'Mevcut teknolojik sürecin son işleminden sonra, yürütme yeni teknolojik sürecin ""%1"" işleminden itibaren devam edecektir.'"),
				Operation2);
	ElsIf ValueIsFilled(Operation1) And ValueIsFilled(Operation2) Then
		ExplanationText = StrTemplate(
			NStr("vi = 'Việc thực hiện quy trình công nghệ hiện tại sẽ bị ngắt sau thao tác ""%1"" và tiếp tục từ thao tác ""%2"" của quy trình công nghệ mới.';
				|ru = 'Выполнение текущего техпроцесса будет прервано после операции ""%1"" и продолжено с операции ""%2"" нового техпроцесса.';
				|en = 'The current technological process will be interrupted after the ""%1"" operation and continued from the ""%2"" operation of the new technological process.'; fa = 'The current technological process will be interrupted after the ""%1"" operation and continued from the ""%2"" operation of the new technological process.';
				|it = 'The current technological process will be interrupted after the ""%1"" operation and continued from the ""%2"" operation of the new technological process.';
				|pl = 'The current technological process will be interrupted after the ""%1"" operation and continued from the ""%2"" operation of the new technological process.';
				|tr = 'Mevcut teknolojik sürecin yürütülmesi ""%1"" işleminden sonra kesintiye uğrayacak ve yeni teknolojik sürecin ""%2"" işleminden itibaren devam edecektir.'"),
				Operation1, Operation2);
	EndIf;
	
	Form.ExplanationText = ExplanationText;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	LongTermOperationsStructure = New Structure("ReplacingProcessTechnology");
	
	AdditionalDataAddress = PutToTempStorage(New Structure, UUID);
	
EndProcedure

&AtServer
Procedure FillInSelectionByDivision()
	
	OwnerOfOperations = OwnerOfOperationsOfCurrentTechnicalProcess(ThisObject);
	If ValueIsFilled(OwnerOfOperations) Then
		FilterDepartment = Common.ObjectAttributeValue(OwnerOfOperations, "Department");
	Else
		FilterDepartment = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(FilterDepartment);
	
	If DivisionParameters.UseManufacturingExecutionSystem Then
		FilterOperationStatus = SelectionStateOfOperationsNotStarted();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function SelectedStages(Form)
	
	Result = New Array;
	
	For Each RowID In Form.Items.Stages.SelectedRows Do
		Result.Add(Form.Stages.FindByID(RowID).Stage);
	EndDo;
	
	Return Result;

EndFunction

#Region Filters

&AtServerNoContext
Function BillOfMaterialsOfStage(BOMStage)
	
	Return Common.ObjectAttributeValue(BOMStage, "Owner");
	
EndFunction

&AtClientAtServerNoContext
Function OwnerOfOperationsOfCurrentTechnicalProcess(Form)
	
	Return ?(TypeOf(Form.CurrentProcessTechnology) = Type("CatalogRef.BillsOfMaterials"),
		Form.FilterBOMStage, Form.CurrentProcessTechnology);
	
EndFunction

&AtClient
Procedure ProcessingSelectionOfBillOfMaterialsStageOfEnd(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		
		FilterBOMStage = Result;
		
		ProcessingSelectionOfBillOfMaterialsStageIsEndedATServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfBillOfMaterialsStageIsEndedATServer()
	
	FillInSelectionByDivision();
	
	UpdateData1();
	
EndProcedure

&AtClientAtServerNoContext
Function SelectionStateOfOperationsNotStarted()
	Return 0;
EndFunction

&AtClientAtServerNoContext
Function SelectionStateOfOperationsStarted()
	Return 1;
EndFunction

&AtClientAtServerNoContext
Function SelectionTypeOfTechnicalProcessCurrent()
	Return "CurrentProcessTechnology";
EndFunction

&AtClientAtServerNoContext
Function SelectionIsNewTypeOfProcessTechnology()
	Return "ProcessTechnologyIsNew";
EndFunction

&AtClientAtServerNoContext
Function OperationSelectionElement(TypeOfTechnicalProcess)
	If TypeOfTechnicalProcess = SelectionTypeOfTechnicalProcessCurrent() Then
		Return "AbortOperation";
	ElsIf TypeOfTechnicalProcess = SelectionIsNewTypeOfProcessTechnology() Then
		Return "OperationContinue";
	Else
		Return Undefined;
	EndIf;
EndFunction

&AtClientAtServerNoContext
Function AbortOperationPresentation(Form)
	ListItem = Form.Items.AbortOperation.ChoiceList.FindByValue(Form.AbortOperation);
	Return ?(ListItem <> Undefined, ListItem.Presentation, "");
EndFunction

&AtClientAtServerNoContext
Function OperationContinuePresentation(Form)
	ListItem = Form.Items.OperationContinue.ChoiceList.FindByValue(Form.OperationContinue);
	Return ?(ListItem <> Undefined, ListItem.Presentation, "");
EndFunction

#EndRegion

#Region DataFilling

&AtServer
Procedure PopulateFormByParameters()
	
	ArrayOfSelections = New Array;
	
	Stage = Undefined;
	If Parameters.Property("Stage", Stage) Then
		ArrayOfSelections.Add("Ref = &Stage");
		ArrayOfSelections.Add("&TechnologicalProcess_.Status IN (
		|VALUE(Enum.BOMStatuses.Valid),
		|VALUE(Enum.TechnologicalProcessStatuses.Valid),
		|VALUE(Enum.StatusesOfRouteSheets.Valid))");
		ArrayOfSelections.Add("&TechnologicalProcessType_ <> VALUE(Enum.TechnologicalProcessTypesOfStage.Individual_)");
	EndIf;
	
	TechnologicalProcess = Undefined;
	If Parameters.Property("TechnologicalProcess", TechnologicalProcess) Then
		ArrayOfSelections.Add("&TechnologicalProcess_ = &CurrentProcessTechnology");
		CurrentProcessTechnology = TechnologicalProcess;
	EndIf;
	
	If ArrayOfSelections.UBound() = -1 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryTextStages(ArrayOfSelections);
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("CurrentProcessTechnology", TechnologicalProcess);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		CurrentProcessTechnology     = Selection.TechnologicalProcess;
		FilterBOMStage = Selection.TechnologicalProcessStage;
		PlaceProcessData(SelectionTypeOfTechnicalProcessCurrent(), CurrentProcessTechnology, FilterBOMStage);
		FillInSelectionByDivision();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStageTable()
	
	CurrentRow = Items.Stages.CurrentRow;
	If CurrentRow <> Undefined Then
		CurrentStep = Stages.FindByID(CurrentRow).Stage;
	EndIf;
	
	Stages.Clear();
	
	If Not ValueIsFilled(CurrentProcessTechnology) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("CurrentProcessTechnology", CurrentProcessTechnology);
	Query.SetParameter("FilterBOMStage", FilterBOMStage);
	Query.SetParameter("FilterDepartment", FilterDepartment);
	
	ArrayOfSelections = New Array;
	ArrayOfSelections.Add("NOT &TechnologicalProcessType_ = VALUE(Enum.TechnologicalProcessTypesOfStage.Individual_)");
	ArrayOfSelections.Add("NOT Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)");
	ArrayOfSelections.Add("&TechnologicalProcess_ = &CurrentProcessTechnology");
	ArrayOfSelections.Add("CASE
	|WHEN &TechnologicalProcess_ REFS Catalog.BillsOfMaterials
	|	THEN &TechnologicalProcessStage_ = &FilterBOMStage
	|WHEN &FilterBOMStage <> VALUE(Catalog.ProductionStages.EmptyRef)
	|	THEN Stages.Stage = &FilterBOMStage
	|ELSE
	|	TRUE
	|END");
	
	If ValueIsFilled(FilterProduct) Or ValueIsFilled(FilterPurpose) Then
		
		Subgroup1 = New Array;
		Subgroup2 = New Array;
		
		If ValueIsFilled(FilterProduct) Then
			Subgroup1.Add("Stages.ProductionLot.MainProductProducts = &FilterProduct");
			Subgroup2.Add("T.Products = &FilterProduct");
			Query.SetParameter("FilterProduct", FilterProduct);
		EndIf;
		
		If ValueIsFilled(FilterPurpose) Then
			Subgroup1.Add("Stages.ProductionLot.Purpose = &FilterPurpose");
			Subgroup2.Add("T.Purpose = &FilterPurpose");
			Query.SetParameter("FilterPurpose", FilterPurpose);
		EndIf;
		
		TemplateText = "((%1)
		|OR TRUE IN (
		|	SELECT TOP 1
		|		TRUE
		|	FROM
		|		Document.ProductionStage2_2.ManufacturedProducts AS T
		|	WHERE
		|		Stages.Ref = T.Ref
		|		AND %2
		|
		|	UNION ALL
		|
		|	SELECT TOP 1
		|		TRUE
		|	FROM
		|		Document.ProductionStage2_2.SideAndIntermediateRelease AS T
		|	WHERE
		|		Stages.Ref = T.Ref
		|		AND %2))
		|";
		
		ArrayOfSelections.Add(StrTemplate(TemplateText, StrConcat(Subgroup1," And "), StrConcat(Subgroup2," And ")));
		
	EndIf;
	
	If ValueIsFilled(FilterMaterial) Then
		
		ArrayOfSelections.Add("TRUE IN (
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS T
		|WHERE
		|	Stages.Ref = T.Ref
		|	AND T.Products = &FilterMaterial
		|)");
		Query.SetParameter("FilterMaterial", FilterMaterial);
		
	EndIf;
	
	If FilterOperationStatus = SelectionStateOfOperationsNotStarted() Then
		
		ArrayOfSelections.Add("NOT TRUE IN (
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.QueueOfProductionOperations AS T
		|WHERE
		|	Stages.Ref = T.Stage
		|	AND T.CreatedOn > 0
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS T
		|WHERE
		|	Stages.Ref = T.Stage
		|	AND T.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|)");
		
	Else
		
		ArrayOfSelections.Add("TRUE IN (
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.QueueOfProductionOperations AS T
		|WHERE
		|	Stages.Ref = T.Stage
		|	AND T.CreatedOn > 0
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS T
		|WHERE
		|	Stages.Ref = T.Stage
		|	AND T.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|)");
		
		If ValueIsFilled(AbortOperation) Then
			
			ArrayOfSelections.Add("NOT TRUE IN (
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	InformationRegister.QueueOfProductionOperations AS T
			|WHERE
			|	Stages.Ref = T.Stage
			|	AND T.CreatedOn > 0
			|	AND T.OperationNumber > &InterruptNumberOperation
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS T
			|WHERE
			|	Stages.Ref = T.Stage
			|	AND T.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
			|	AND T.OperationNumber > &InterruptNumberOperation)
			|");
			OperationData = DataOfOperationOfTechnicalProcessPlaced(SelectionTypeOfTechnicalProcessCurrent(), AbortOperation);
			Query.SetParameter("InterruptNumberOperation", ?(OperationData = Undefined, 0, OperationData.OperationNumber));
			
		EndIf;
		
	EndIf;
	
	Query.Text = QueryTextStages(ArrayOfSelections);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = Stages.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.Assigned_ Then
			NewRow.CurrentStateOfOperation = Enums.OperationStates.Assigned_;
		EndIf;
		
		If NewRow.Stage = CurrentStep Then
			Items.Stages.CurrentRow = NewRow.GetID();
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure TechnicalProcessIsCurrentOnChangeAtServer()
	
	AbortOperation = Undefined;
	
	FillInSelectionByDivision();
	
	ConfigureProcessSelectionParameters(ThisObject, Items.CurrentProcessTechnology, TypeOf(CurrentProcessTechnology));
	
	ConfigureStageSelectionParameters(ThisObject);
	
	PlaceProcessData(SelectionTypeOfTechnicalProcessCurrent(), CurrentProcessTechnology, FilterBOMStage);
	
	UpdateData1();
	
EndProcedure

&AtServer
Procedure ProcessIsNewOnChangeATServer()
	
	OperationContinue = Undefined;
	
	ConfigureProcessSelectionParameters(ThisObject, Items.ProcessTechnologyIsNew, TypeOf(ProcessTechnologyIsNew));
	
	PlaceProcessData(SelectionIsNewTypeOfProcessTechnology(), ProcessTechnologyIsNew);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateData1()
	
	FillInStageTable();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure PlaceProcessData(TypeOfTechnicalProcess, TechnologicalProcess, BOMStage = Undefined)
	
	Data_Stage = New Structure("TechnologicalProcess");
	
	If ValueIsFilled(TechnologicalProcess) Then
		Data_Stage.Insert("TechnologicalProcess", TechnologicalProcess);
		Data_Stage.Insert("Products",           Catalogs.Products.EmptyRef());
		Data_Stage.Insert("Characteristic",         Catalogs.ItemsCharacteristics.EmptyRef());
		Data_Stage.Insert("BOMStage",       BOMStage);
		Data_Stage.Insert("NumberOfPackagesPlan", 1);
		Data_Stage.Insert("PackagingFactor",    1);
		Data_Stage.Insert("TechnologicalProcessFactor", 1);
	EndIf;
	
	TransactionTable = InformationRegisters.QueueOfProductionOperations.ListOfOperationsAccordingToStageData(Data_Stage);
	
	Item = Items[OperationSelectionElement(TypeOfTechnicalProcess)]; // ComboBox
	Item.ChoiceList.Clear();
	For Each String In TransactionTable Do
		Item.ChoiceList.Add(Format(String.OperationID,"NG=;"), String.OperationPresentation);
	EndDo;
	
	AdditionalData = GetFromTempStorage(AdditionalDataAddress);
	TechProcessesData   = Undefined;
	If Not AdditionalData.Property("TechProcessesData", TechProcessesData) Then
		TechProcessesData = New Structure;
		AdditionalData.Insert("TechProcessesData", TechProcessesData);
	EndIf;
	TechProcessesData.Insert(TypeOfTechnicalProcess, TransactionTable);
	
	AdditionalDataAddress = PutToTempStorage(AdditionalData, UUID);
	
EndProcedure

&AtServer
Function ProcessDataPlaced(TypeOfTechnicalProcess)
	
	AdditionalData = GetFromTempStorage(AdditionalDataAddress);
	If Not AdditionalData.Property("TechProcessesData")
		Or Not AdditionalData.TechProcessesData.Property(TypeOfTechnicalProcess) Then
		Return Undefined;
	EndIf;
	
	Return AdditionalData.TechProcessesData[TypeOfTechnicalProcess];
	
EndFunction

&AtServer
Function DataOfOperationOfTechnicalProcessPlaced(TypeOfTechnicalProcess, OperationID)
	
	ProcessLine = Undefined;
	TechProcessData = ProcessDataPlaced(TypeOfTechnicalProcess); // See Catalogs.ManufacturingOperations.OperationTableConstructor
	
	If Not ValueIsFilled(TechProcessData) Then
		Return Undefined;
	EndIf;
	
	If ValueIsFilled(OperationID) Then
		ProcessLine = TechProcessData.Find(Number(OperationID), "OperationID");
	ElsIf TypeOfTechnicalProcess = SelectionTypeOfTechnicalProcessCurrent() Then
		ProcessLine = TechProcessData[TechProcessData.Count()-1];
	ElsIf TypeOfTechnicalProcess = SelectionIsNewTypeOfProcessTechnology() Then
		ProcessLine = TechProcessData[0];
	EndIf;
	
	If Not ValueIsFilled(ProcessLine) Then
		Return Undefined;
	Else
		Return Common.ValueTableRowToStructure(ProcessLine);
	EndIf;
	
EndFunction

&AtServer
Function QueryTextStages(ArrayOfSelections = Undefined)
	
	QueryText = "
	|SELECT DISTINCT
	|	Stages.Date                                             AS Date,
	|	Stages.ProductionLot.MainProductProducts   AS Product,
	|	Stages.NumberOfPackagesPlan                           AS Count,
	|	Stages.PackagePlan                                     AS Package,
	|	Stages.Ref                                           AS Stage,
	|	Stages.Status                                           AS Status,
	|	Stages.BillOfMaterials                                     AS BillOfMaterials,
	|	Stages.Stage                                             AS BOMStage,
	|	Stages.ReferenceOrder                                     AS ReferenceOrder,
	|	Queue.Operation                                       AS CurrentOperation,
	|	Queue.State                                      AS CurrentStateOfOperation,
	|	NOT Assigned.Operation IS NULL                        AS Assigned_,
	|	ISNULL(TechnicalProcess.FirstOperationID, 0)    AS FirstOperationID,
	|	ISNULL(TechnicalProcess.LastOperationID, 0) AS LastOperationID,
	|	&TechProcessParameters
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|
	|	LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|	ON Stages.Ref = TechnicalProcess.Stage
	|
	|	LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
	|	ON Stages.Ref = Queue.Stage
	|		AND Queue.MainEntry_
	|
	|	LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS Assigned
	|	ON Stages.Ref = Assigned.Stage
	|		AND Queue.Operation = Assigned.Operation
	|		AND Queue.OperationID = Assigned.OperationID
	|		AND Assigned.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
	|
	|WHERE
	|	Stages.Posted 
	|
	|	AND (Queue.Operation IS NULL
	|		OR Queue.OperationID IN (
	|				SELECT TOP 1
	|					T1.OperationID
	|				FROM
	|					InformationRegister.QueueOfProductionOperations AS T1
	|				
	|					FULL JOIN InformationRegister.OperationsToCreateShiftTasks AS T2
	|					ON T1.Stage = T2.Stage
	|						AND T1.Operation = T2.Operation
	|						AND T1.OperationID = T2.OperationID
	|						AND T2.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
	|				
	|				WHERE
	|					Stages.Ref = T1.Stage
	|					AND T1.MainEntry_
	|					AND NOT (T1.State = VALUE(Enum.OperationStates.Executed)
	|							AND T1.NextOperation > 0)
	|					AND (NOT T1.State IN (
	|							VALUE(Enum.OperationStates.PendingPredecessorCompletion),
	|							VALUE(Enum.OperationStates.PreviousOnesAreStarted))
	|						OR NOT T2.OperationID IS NULL)
	|			ORDER BY
	|				ISNULL(T2.Order, T1.Order) DESC,
	|				T1.OperationNumber DESC))
	|
	|ORDER BY
	|	Stages.PointInTime
	|";
	
	ListOfData = ProductionProcessEditor.ProcessParametersListOfData("TechnologicalProcessStage");
	QueryText = StrReplace(QueryText, "&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage("Stages",,ListOfData));
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	Package = QuerySchema.QueryBatch[0];
	
	If ValueIsFilled(ArrayOfSelections) Then
		For Each FilterText1 In ArrayOfSelections Do
			For Each PackageColumn In Package.Columns Do
				FilterText1 = StrReplace(FilterText1, "&"+PackageColumn.Alias+"_", "("+PackageColumn.Fields[0]+")");
			EndDo;
			Package.Operators[0].Filter.Add(FilterText1);
		EndDo;
	EndIf;
	
	QueryText = QuerySchema.GetQueryText();
	Return QueryText;
	
EndFunction

#EndRegion

#Region PerformingReplacement

&AtServer
Function TableOfOperationsForReplacement(ProcessLimitations = Undefined)
	
	TransactionTable1 = ProcessDataPlaced(SelectionTypeOfTechnicalProcessCurrent());
	TransactionTable2 = ProcessDataPlaced(SelectionIsNewTypeOfProcessTechnology());
	
	If Not ValueIsFilled(TransactionTable1)
		Or Not ValueIsFilled(TransactionTable2) Then
		Return Undefined;
	EndIf;
	
	OperationData1 = Undefined;
	OperationData2 = DataOfOperationOfTechnicalProcessPlaced(SelectionIsNewTypeOfProcessTechnology(), OperationContinue);
	
	If ProcessLimitations <> Undefined Then
		InformationRegisters.QueueOfProductionOperations.ApplyProcessLimitations(TransactionTable1, ProcessLimitations);
		If TransactionTable1.Count() > 0 Then
			CurrentOffset = 1 - TransactionTable1[0].OperationNumber;
			For Each RowData In TransactionTable1 Do
				RowData.OperationNumber          = RowData.OperationNumber + CurrentOffset;
				RowData.NextOperation = RowData.NextOperation + CurrentOffset;
				If OperationData1 = Undefined
						And (ValueIsFilled(AbortOperation) And RowData.OperationID = Number(AbortOperation)
							Or RowData = TransactionTable1[TransactionTable1.Count()-1]) Then
					OperationData1 = Common.ValueTableRowToStructure(RowData);
				EndIf;
			EndDo;
		EndIf;
	Else
		OperationData1 = DataOfOperationOfTechnicalProcessPlaced(SelectionTypeOfTechnicalProcessCurrent(), AbortOperation);
	EndIf;
	
	If Not ValueIsFilled(OperationData1)
			Or Not ValueIsFilled(OperationData2) Then
		Return Undefined;
	EndIf;
	
	CurrentID = 0;
	CurrentOffset = OperationData1.OperationNumber - OperationData2.OperationNumber + 1;
	TransactionTable = Catalogs.ManufacturingOperations.OperationTableConstructor();
	
	For IndexOf = 0 To TransactionTable1.Count() - 1 Do
		RowData = TransactionTable1[IndexOf];
		If RowData.OperationNumber <= OperationData1.OperationNumber Then
			NewRow = TransactionTable.Add();
			FillPropertyValues(NewRow, RowData);
			CurrentID = Max(CurrentID, RowData.OperationID);
		EndIf;
	EndDo;
	
	NewRow.NextOperation = NewRow.OperationNumber + 1;
	
	For IndexOf = 0 To TransactionTable2.Count() - 1 Do
		RowData = TransactionTable2[IndexOf];
		If RowData.OperationNumber >= OperationData2.OperationNumber Then
			CurrentID = CurrentID + 1;
			NewRow = TransactionTable.Add();
			FillPropertyValues(NewRow, RowData);
			NewRow.OperationID  = CurrentID;
			NewRow.OperationNumber          = RowData.OperationNumber + CurrentOffset;
			NewRow.NextOperation = RowData.NextOperation + CurrentOffset;
		EndIf;
	EndDo;
	
	NewRow.NextOperation = 0;
	
	Return TransactionTable;
	
EndFunction

&AtClient
Function CheckProcessReplacementSettings()
	
	If SelectedStages(ThisObject).UBound() = -1 Then
		CommonClient.MessageToUser(NStr("vi = 'Cần tách chọn công đoạn sản xuất.';
										|ru = 'Необходимо выделить этапы производства.';
										|en = 'Select production stages.'; fa = 'Select production stages.';
										|it = 'Select production stages.';
										|pl = 'Select production stages.';
										|tr = 'Üretim aşamalarının belirtilmesi gerekmektedir.'"));
		Return False;
	EndIf;
	
	If Not ValueIsFilled(CurrentProcessTechnology)
		Or Not ValueIsFilled(ProcessTechnologyIsNew) Then
		CommonClient.MessageToUser(NStr("vi = 'Cần chỉ ra quy trình công nghệ mới và hiện tại.';
										|ru = 'Необходимо указать текущий и новый техпроцессы.';
										|en = 'Specify the current and new technological processes.'; fa = 'Specify the current and new technological processes.';
										|it = 'Specify the current and new technological processes.';
										|pl = 'Specify the current and new technological processes.';
										|tr = 'Mevcut ve yeni teknolojik süreçlerin belirtilmesi gerekmektedir.'"));
		Return False;
	EndIf;
	
	If CurrentProcessTechnology = ProcessTechnologyIsNew Then
		CommonClient.MessageToUser(NStr("vi = 'Quy trình công nghệ mới và hiện tại trùng nhau.';
										|ru = 'Текущий и новый техпроцессы совпадают.';
										|en = 'The current and new technological processes match.'; fa = 'The current and new technological processes match.';
										|it = 'The current and new technological processes match.';
										|pl = 'The current and new technological processes match.';
										|tr = 'Mevcut ve yeni teknolojik süreçler aynıdır.'"));
		Return False;
	EndIf;
	
	Return CheckProcessReplacementSettingsAtServer();
	
EndFunction

&AtServer
Function CheckProcessReplacementSettingsAtServer()
	
	Cancel = False;
	
	References = New Array;
	References.Add(OwnerOfOperationsOfCurrentTechnicalProcess(ThisObject));
	References.Add(ProcessTechnologyIsNew);
	
	AttributesValues = Common.ObjectsAttributeValue(References, "Department");
	
	If AttributesValues[References[0]] <> AttributesValues[References[1]] Then
		MessageText = StrTemplate(NStr("vi = 'Không trùng bộ phận của quy trình công nghệ mới và hiện tại (""%1"", ""%2"").';
										|ru = 'Не совпадают подразделения текущего и нового техпроцессов (""%1"", ""%2"").';
										|en = 'The business units of the current and new technological processes do not match (""%1"", ""%2"").'; fa = 'The business units of the current and new technological processes do not match (""%1"", ""%2"").';
										|it = 'The business units of the current and new technological processes do not match (""%1"", ""%2"").';
										|pl = 'The business units of the current and new technological processes do not match (""%1"", ""%2"").';
										|tr = 'Mevcut ve yeni teknolojik süreçlerin (""%1"", ""%2"") departmanları eşleşmiyor.'"),
			AttributesValues[References[0]], AttributesValues[References[1]]);
		Common.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
	If Not Cancel
		And FilterOperationStatus = SelectionStateOfOperationsStarted() Then
		
		TransactionTable = TableOfOperationsForReplacement();
		
		If ValueIsFilled(TransactionTable) Then 
			
			OrderCheckTable = ProductionProcessEditor.TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner();
			
			For Each String In TransactionTable Do
				
				NewRow = OrderCheckTable.Add();
				NewRow.Object                 = String;
				NewRow.Operation               = String.Operation;
				NewRow.Presentation          = String.OperationPresentation;
				NewRow.OperationNumber          = String.OperationNumber;
				NewRow.NextOperation = String.NextOperation;
				
			EndDo;
			
			ProductionProcessEditor.CheckOrderOfProductionProcessElements(
				OrderCheckTable,
				ProductionProcessEditor.StructureOfOperationSequenceChecks(, DivisionParameters),
				Cancel);
			
		Else
			
			Common.MessageToUser(NStr("vi = 'Lỗi tạo quy trình công nghệ riêng biệt.';
										|ru = 'Ошибка формирования индивидуального техпроцесса.';
										|en = 'An error occurred when generating an individual technological process.'; fa = 'An error occurred when generating an individual technological process.';
										|it = 'An error occurred when generating an individual technological process.';
										|pl = 'An error occurred when generating an individual technological process.';
										|tr = 'Özelleştirilmiş teknolojik sürecin oluşturulmasında hata oluştu.'"),,,,Cancel);
			
		EndIf;
	
	EndIf;
	
	If Not Cancel Then
		BlockStages(Cancel, True);
	EndIf;
	
	Return Not Cancel;
	
EndFunction

&AtClientAtServerNoContext
Function BackgroundOperationProcessReplacement()
	
	Return NStr("vi = 'Thay thế quy trình công nghệ trong các công đoạn.';
				|ru = 'Замена технологического процесса в этапах.';
				|en = 'Replacing the technological process in stages.'; fa = 'Replacing the technological process in stages.';
				|it = 'Replacing the technological process in stages.';
				|pl = 'Replacing the technological process in stages.';
				|tr = 'Aşamalarda teknolojik sürecin değiştirilmesi.'");
	
EndFunction

&AtClient
Procedure StartReplacingProcessTechnology()
	
	If LongTermOperationsStructure.ReplacingProcessTechnology <> Undefined Then
		Return;
	EndIf;
	
	StartReplacingProcessAtServer();
	
	If LongTermOperationsStructure.ReplacingProcessTechnology <> Undefined Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = BackgroundOperationProcessReplacement();
		
		TimeConsumingOperationsClient.WaitCompletion(
			LongTermOperationsStructure.ReplacingProcessTechnology,
			New CallbackDescription("ReplacingProcessTechnologyCompletion", ThisObject),
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartReplacingProcessAtServer()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground    = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = BackgroundOperationProcessReplacement();
	
	LongTermOperationsStructure.ReplacingProcessTechnology = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ProductionProcessEditor.GroupSubstitutionInBackground",
		ParametersOfProcessReplacementProcedure(),
		ExecutionParameters);
	
EndProcedure

&AtServer
Function ParametersOfProcessReplacementProcedure()
	
	Result = New Structure;
	Result.Insert("CurrentProcessTechnology", CurrentProcessTechnology);
	Result.Insert("ProcessTechnologyIsNew", ProcessTechnologyIsNew);
	Result.Insert("Stages", SelectedStages(ThisObject));
	Result.Insert("TechProcessParameters", ProductionProcessEditorClientServer.ProcessParametersConstructor());
	Result.Insert("DivisionParameters", DivisionParameters);
	
	OperationData = DataOfOperationOfTechnicalProcessPlaced(SelectionTypeOfTechnicalProcessCurrent(), AbortOperation);
	Result.Insert("InterruptIdOperation", ?(OperationData = Undefined, Undefined, OperationData.OperationID));
	
	OperationData = DataOfOperationOfTechnicalProcessPlaced(SelectionIsNewTypeOfProcessTechnology(), OperationContinue);
	Result.Insert("OperationContinueId", ?(OperationData = Undefined, Undefined, OperationData.OperationID));
	
	If FilterOperationStatus = SelectionStateOfOperationsNotStarted() Then
		Result.TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.AlternateType;
		Result.TechProcessParameters.TechnologicalProcess      = ProcessTechnologyIsNew;
	Else
		Result.TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_;
		TablesOfOperations = New Map();
		TablesOfOperations.Insert(Documents.ProductionStage2_2.EmptyRef(), TableOfOperationsForReplacement());
		For Each RowID In Items.Stages.SelectedRows Do
			RowData = Stages.FindByID(RowID);
			Restrictions = InformationRegisters.TechnologicalProcessesOfProductionStages.LimitationsOfConstructorProcess();
			FillPropertyValues(Restrictions, RowData);
			If InformationRegisters.TechnologicalProcessesOfProductionStages.RecordContainsProcessLimitations(Restrictions) Then
				TablesOfOperations.Insert(RowData.Stage, TableOfOperationsForReplacement(Restrictions));
			EndIf;
		EndDo;
		Result.Insert("TablesOfOperations", TablesOfOperations);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ReplacingProcessTechnologyCompletion(TimeConsumingOperation, AdditionalParameters) Export
	
	LongTermOperationsStructure.ReplacingProcessTechnology = Undefined;
	
	If TimeConsumingOperation <> Undefined Then
		
		JobResult = ProcessReplacementEndATServer(TimeConsumingOperation.ResultAddress);
		
		If TimeConsumingOperation.Status = "Error"
				Or JobResult = Undefined
				Or JobResult.HasErrors Then
			MessageText = NStr("vi = 'Không thể thay thế quy trình công nghệ của các công đoạn được chọn. Chi tiết xem trong nhật ký sự kiện.';
								|ru = 'Не удалось заменить технологический процесс выбранных этапов. Подробности см. в журнале регистрации.';
								|en = 'Cannot replace a technological process in the selected stages. For more information, see the Event log.'; fa = 'Cannot replace a technological process in the selected stages. For more information, see the Event log.';
								|it = 'Cannot replace a technological process in the selected stages. For more information, see the Event log.';
								|pl = 'Cannot replace a technological process in the selected stages. For more information, see the Event log.';
								|tr = 'Seçilen aşamaların teknolojik süreci değiştirilemedi. Ayrıntılar için olay günlüğüne bakın.'");
			Picture = PictureLib.Error32;
			If JobResult <> Undefined And JobResult.HasErrors Then
				For Each KeyAndValue In JobResult.Unsuccessfully Do
					CommonClient.MessageToUser(KeyAndValue.Value.ErrorText, KeyAndValue.Key);
				EndDo;
			EndIf;
		Else
			MessageText = NStr("vi = 'Đã thay thế quy trình công nghệ của các công đoạn.';
								|ru = 'Технологический процесс этапов заменен.';
								|en = 'Technological process of the stages is replaced.'; fa = 'Technological process of the stages is replaced.';
								|it = 'Technological process of the stages is replaced.';
								|pl = 'Technological process of the stages is replaced.';
								|tr = 'Aşamaların teknolojik süreci değiştirildi.'");
			Picture = PictureLib.Information32;
		EndIf;
		
		ShowUserNotification(BackgroundOperationProcessReplacement(),,MessageText, Picture);
		
		Notify("ChangingProcessTechnology");
		Notify("Write_QueueOfProductionOperations", New Structure("Department", FilterDepartment));
		
		UpdateData1();
	
	EndIf;
	
EndProcedure

&AtServer
Function ProcessReplacementEndATServer(ResultAddress)
	
	UnlockStages();
	
	JobResult = GetFromTempStorage(ResultAddress);
	Return JobResult;
	
EndFunction

&AtServer
Procedure BlockStages(Cancel, OutputMessages = False)
	
	StagesAreNotBlocked = New Array;
	
	For Each Stage In SelectedStages(ThisObject) Do
		Try
			LockDataForEdit(Stage);
		Except
			StagesAreNotBlocked.Add(Stage);
		EndTry;
	EndDo;
	
	If StagesAreNotBlocked.UBound() <> -1 Then
		If OutputMessages Then
			MessageText = StrTemplate(NStr("vi = 'Không thể phong tỏa các công đoạn tiếp theo:
								|%1
								|Có thể, đang chỉnh sửa chúng.';
								|ru = 'Не удалось заблокировать следующие этапы:
								|%1
								|Возможно, они в настоящий момент редактируются.';
								|en = 'Cannot lock the following stages:
								|%1
								|They might be locked for editing.'; fa = 'Cannot lock the following stages:
								|%1
								|They might be locked for editing.';
								|it = 'Cannot lock the following stages:
								|%1
								|They might be locked for editing.';
								|pl = 'Cannot lock the following stages:
								|%1
								|They might be locked for editing.';
								|tr = 'Aşağıdaki aşamalar bloke edilmedi:
								|%1
								|Şu anda düzenleniyor olabilirler.'"), StrConcat(StagesAreNotBlocked, Chars.LF));
			Common.MessageToUser(MessageText,,,,Cancel);
		Else
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UnlockStages()
	
	For Each Stage In SelectedStages(ThisObject) Do
		UnlockDataForEdit(Stage);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
