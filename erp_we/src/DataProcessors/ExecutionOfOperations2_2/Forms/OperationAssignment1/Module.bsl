
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not FillInFormDetailsByParameters() Then
		Cancel = True;
		Return;
	EndIf;
	
	IsMobileClient = Common.IsMobileClient();
	
	CustomizeFormElements();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not UseAreas Then
		NotCheckedAttributeArray.Add("ProductionArea");
	EndIf;
	
	If MultipleMode Then
		NotCheckedAttributeArray.Add("Stage");
		NotCheckedAttributeArray.Add("Operation");
		NotCheckedAttributeArray.Add("Count");
	EndIf;
	
	DivisionParameters = ProductionServerCached.ProductionBusinessUnitDescription(Department);
	If Not DivisionParameters.UseShiftTasks Then
		NotCheckedAttributeArray.Add("ShiftTask");
	EndIf;
	
	If ValueIsFilled(ProductionOperation) Then
		NotCheckedAttributeArray.Add("Operation");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CountOnChange(Item)
	
	RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
		Count,
		NumberOfPieces,
		TimePerPiece,
		SetupTime,
		ParallelLoad,
		WorkTimeFactor);
	
	ConfigureDependentFormElements(ThisObject, "Count,RunTime");
	
EndProcedure

&AtClient
Procedure RunTimeOnChange(Item)
	
	Count = ProductionAccountingClientServer.CalculateAmountOfOperationFromTime(
		RunTime,
		TimePerPiece,
		SetupTime,
		NumberOfPieces,
		WorkTimeFactor);
		
	ConfigureDependentFormElements(ThisObject, "Count,RunTime");
	
EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Organization,
		Department,
		Performer,
		Undefined,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Performer = Result;
		PerformerSelectionStartsEndsAtServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShiftTaskStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Statuses = New ValueList;
	Statuses.Add(PredefinedValue("Enum.ShiftTaskStatuses.BeingGenerated"));
	Statuses.Add(PredefinedValue("Enum.ShiftTaskStatuses.Generated_"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Department",       Department);
	FormParameters.Insert("ProductionArea",             ProductionArea);
	FormParameters.Insert("Statuses",             Statuses);
	
	OpenForm(
		"Document.ShiftTask.Form.SelectionFormByCalendar",
		FormParameters,
		ThisObject,
		UUID,,,
		New CallbackDescription("ShiftTaskStartChoiceCompletion",ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Organization, Department);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Organization, Department);
		
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
		
	CalculateDownload_();
	
EndProcedure

&AtClient
Procedure PerformerOnChange(Item)
	CalculateDownload_();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersActivityKinds

&AtClient
Procedure ActivityKindsPerformerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("ActivityKindsPerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Organization,
		Department,
		Performer,
		Undefined,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure ActivityKindsPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Organization, Department);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivityKindsPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Organization, Department);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = ProductionAccountingClientServer.ParametersOfAssignmentOfProductionOperationConstructor(MultipleMode);
	
	FillPropertyValues(Result, ThisObject);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Organization, Department)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Organization, Department, Date", Organization, Department, CurrentSessionDate());
	
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

// Filling in the list of details according to the form parameters.
//
&AtServer
Function FillInFormDetailsByParameters()
	
	If Not ValueIsFilled(Parameters.Department) Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(Parameters.OperationKeys) Then
		Return False;
	EndIf;
	
	If Not Parameters.Property("WorkMode", WorkMode) Then
		Return False;
	EndIf;
	
	Department       = Parameters.Department;
	UseAreas = GetFunctionalOption("UseProductionSites", New Structure("Department", Department));
	
	If Parameters.Property("Performer") Then
		Performer = Parameters.Performer;
	EndIf;
	
	If Parameters.Property("WorkCenter") Then
		WorkCenter = Parameters.WorkCenter;
	EndIf;
	
	If Parameters.Property("SetupSettings") Then
		SetupSettings = Parameters.SetupSettings;
	EndIf;
	
	CalculateDownload_();
	
	If Parameters.Property("ProductionArea") Then
		ProductionArea = Parameters.ProductionArea;
	EndIf;
	
	MultipleMode = Parameters.OperationKeys.Count() > 1;
	
	If Not MultipleMode Then
		
		OperationData = ProductionAccountingServerCall.OperationDataFromQueue(Parameters.OperationKeys[0]);
		
		If OperationData <> Undefined Then
			FillPropertyValues(
				ThisObject,
				OperationData,
				"Organization,Stage,OperationID,Operation,ProductionOperation,WorkCenterType,UnitOfMeasure,TimePerPiece,SetupTime,TimeUnitsOfMeasure,NumberOfPieces,ParallelLoad,WorkTimeFactor");
		EndIf;
		
		If WorkCenter.IsEmpty() Then
			WorkCenter = OperationData.WorkCenter;
		EndIf;
		
		If ProductionArea.IsEmpty() Then
			ProductionArea = OperationData.ProductionArea;
		EndIf;
		If SetupSettings.IsEmpty() Then
			SetupSettings = Common.ObjectAttributeValue(OperationData.Operation, "SetupSettings");
		EndIf;
		
		QuantityPlanned = OperationData.Scheduled;
		
		If ProductionProcessEditorClientServer.ThisOperationIsIndividual(ThisObject) Then
			QuantityIsAvailable = QuantityPlanned;
		ElsIf WorkMode = AssignOperatingMode() Then
			QuantityIsAvailable = OperationData.WaitingForCreation;
		Else
			QuantityIsAvailable = OperationData.ExecutionIsAllowed;
		EndIf;
		
		If QuantityIsAvailable <> 0 Then
			Count = QuantityIsAvailable;
		EndIf;
		
		RunTime = ProductionAccountingClientServer.CalculateOperationTimeFromQuantity(
			Count,
			NumberOfPieces,
			TimePerPiece,
			SetupTime,
			ParallelLoad,
			WorkTimeFactor);
			
		RouteDetails = Catalogs.ManufacturingOperations.DetailsOfOperationRoute(OperationData.OperationOwner);
		Route = RouteDetails.Route;
		Items.Route.Hyperlink = RouteDetails.RouteAvailable;
		
		DivisionParameters = ProductionServerCached.ProductionBusinessUnitDescription(Department);
		
		
	Else
		
		CommonValue_ViewOfWorkCenter = Undefined;
		GeneralMeaning_Organization = Undefined;
		
		OperationData_ = ProductionAccountingServerCall.OperationDataFromQueue_(Parameters.OperationKeys);
		
		For Each OperationData In OperationData_ Do
			
			If CommonValue_ViewOfWorkCenter = Undefined Then
				CommonValue_ViewOfWorkCenter = OperationData.WorkCenterType;
			ElsIf CommonValue_ViewOfWorkCenter <> OperationData.WorkCenterType
				And CommonValue_ViewOfWorkCenter <> Catalogs.WorkCenterTypes.EmptyRef() Then
				CommonValue_ViewOfWorkCenter = Catalogs.WorkCenterTypes.EmptyRef();
				SeveralWorkCenterTypes = True
			EndIf;
			
			If GeneralMeaning_Organization = Undefined Then
				GeneralMeaning_Organization = OperationData.Organization;
			ElsIf GeneralMeaning_Organization <> OperationData.Organization
				And GeneralMeaning_Organization <> Catalogs.Companies.EmptyRef() Then
				GeneralMeaning_Organization = Catalogs.Companies.EmptyRef()
			EndIf;
			
		EndDo;
		
		WorkCenterType = CommonValue_ViewOfWorkCenter;
		Organization = GeneralMeaning_Organization;
		
	EndIf;
	
	If UseAreas And Not WorkCenter.IsEmpty() Then
		
		RCSection = Common.ObjectAttributeValue(WorkCenter, "ProductionArea");
		
		If ProductionArea.IsEmpty()  Then
			ProductionArea = RCSection;
		ElsIf ProductionArea <> RCSection Then
			WorkCenter = Undefined;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure CustomizeFormElements() 
	
	// Relationships of work center selection parameters
	#Region WorkCenter 
	
	If SeveralWorkCenterTypes Then
		Items.WorkCenter.Enabled = False;
		Items.SetupSettings.Visible = False;
	Else
		
		ParametersArray = New Array;
		
		If WorkCenterType.IsEmpty() Then
			ParametersArray.Add(New ChoiceParameterLink("Filter.Department", "Department"));
		Else
			ParametersArray.Add(New ChoiceParameterLink("Filter.WorkCenterType", "WorkCenterType"));
		EndIf;
		If UseAreas Then
			ParametersArray.Add(New ChoiceParameterLink("Filter.ProductionArea", "ProductionArea"));
		EndIf;
		
		Items.WorkCenter.ChoiceParameterLinks = New FixedArray(ParametersArray);
	
	EndIf;
	
	#EndRegion
	
	SetArtistType();
	
	ConfigureDependentFormElements(ThisObject);
	
	SetFormElementHeaders();
	
	Items.ProductionArea.Visible = UseAreas;
	
	Items.TimeTheNumber.Visible            = Not MultipleMode;
	Items.GroupInformationOnImport.Visible = Not MultipleMode;
	Items.OperationInformationGroup_.Visible = Not MultipleMode;
	
	Items.RunTime.ReadOnly = ParallelLoad;
	
	DivisionParameters = ProductionServerCached.ProductionBusinessUnitDescription(Department);
	Items.ShiftTask.Visible = DivisionParameters.UseShiftTasks;
	
	Items.SetupSettings.Visible = Not WorkCenterType.IsEmpty()
		And Common.ObjectAttributeValue(WorkCenterType, "SetupSettingsAreUsed");
	
	Items.GroupTypesOfWork.Visible       = ActivityKinds.Count() > 1;
	Items.GroupJobTitleLaborGrade.Visible = ActivityKinds.Count() = 1;
	Items.Performer.Visible           = Not ActivityKinds.Count() > 1;
	
	If Common.IsMobileClient() Then
		
		//Replacing the button text with an image
		Items.FormWriteAndClose.Representation = ButtonRepresentation.Picture;
		Items.FormWriteAndClose.Picture = PictureLib.WriteAndClose;
		
		//Moving an operation and a route map
		Items.Move(Items.LeftGroup1, ThisObject, Items.TheGroupAddOperation);
		
		//Setting up the RC and the performer
		Items.WorkCenter.TitleLocation = FormItemTitleLocation.None;
		Items.Performer.TitleLocation = FormItemTitleLocation.None;
		
		Items.WorkCenter.InputHint = NStr("vi = '<Nguồn lực sản xuất>';
											|ru = '<Рабочий центр>';
											|en = '<Work center>'; fa = '<مرکز کار>';
											|it = '< Centro di lavoro>';
											|pl = '<Stanowisko pracy>';
											|tr = '<İş merkezi>'");
		Items.Performer.InputHint = NStr("vi = '<người thực hiện>';
										|ru = '<Исполнитель>';
										|en = '<Assignee>'; fa = '<مجری>';
										|it = '<Assegnatario>';
										|pl = '<Assignee>';
										|tr = '<Atanan>'");
		
		//Setting the width of the fields
		Items.UnitOfMeasurePresentation.MaxWidth              = 4;
		Items.TimeUnitsOfMeasure.MaxWidth                                 = 4;
		Items.UnitOfMeasurementPlannedView.MaxWidth = 4;
		Items.UnitOfMeasurementViewAvailable.MaxWidth      = 4;
		
		Items.GroupPlanned.Group = ChildFormItemsGroup.AlwaysHorizontal;
		Items.TheGroupIsAvailable.Group      = ChildFormItemsGroup.AlwaysHorizontal;
		
		Items.QuantityPlanned.AutoMaxWidth   = True;
		Items.QuantityPlanned.HorizontalStretch = True;
		Items.QuantityPlanned.Type                      = FormFieldType.InputField;
		
		Items.QuantityIsAvailable.AutoMaxWidth   = True;
		Items.QuantityIsAvailable.HorizontalStretch = True;
		Items.QuantityIsAvailable.Type                      = FormFieldType.InputField;
		
		Items.WorkCenterLoad.HorizontalStretch          = True;
		Items.ImportAssignee.HorizontalStretch = True;
		
	EndIf;
	
	If ProductionProcessEditorClientServer.ThisOperationIsIndividual(ThisObject) Then
		
		Items.Operation.Visible                 = False;
		Items.Route.Visible                  = False;
		Items.ProductionOperation.Visible = True;
		Items.Count.ReadOnly          = True;
		Items.RunTime.ReadOnly     = True;
		Items.TheGroupIsAvailable.Visible           = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormElementHeaders()
	
	// Setting the Form header
	#Region FormCaption
	
	If MultipleMode Then
		If WorkMode = AssignOperatingMode() Then
			TextTitle_ = NStr("vi = 'Chỉ định các thao tác được chọn';
								|ru = 'Назначить выбранные операции';
								|en = 'Assign the selected operations'; fa = 'Assign the selected operations';
								|it = 'Assegnare le operazioni selezionate';
								|pl = 'Przydziel wybrane operacje';
								|tr = 'Seçili işlemleri ata'");
		ElsIf WorkMode = OperatingModeAcceptToWork() Then
			TextTitle_ = NStr("vi = 'Thực hiện các thao tác được chọn';
								|ru = 'Принять в работу выбранные операции';
								|en = 'Accept selected operations for processing'; fa = 'Accept selected operations for processing';
								|it = 'Prendere in carico le operazioni selezionate';
								|pl = 'Przyjmij do wykonania wybrane operacje';
								|tr = 'Seçili işlemleri işe kabul et'");
		ElsIf WorkMode = ModeOfOperationMarkExecution() Then
			TextTitle_ = NStr("vi = 'Đánh dấu thực hiện các hoạt động được chọn';
								|ru = 'Отметить выполнение выбранных операций';
								|en = 'Mark the selected operations as performed'; fa = 'Mark the selected operations as performed';
								|it = 'Segnare l''esecuzione delle operazioni selezionate';
								|pl = 'Zaznacz wykonanie wybranych operacji';
								|tr = 'Seçili işlemlerin gerçekleştirilmesi işaretle'");
		EndIf;
	Else
		If WorkMode = AssignOperatingMode() Then
			TextTitle_ = NStr("vi = 'Chỉ định một hoạt động';
								|ru = 'Назначить операцию';
								|en = 'Assign operation'; fa = 'تخصیص عملیات';
								|it = 'Assegna l''operazione';
								|pl = 'Przydziel operację';
								|tr = 'İşlem ata'");
		ElsIf WorkMode = OperatingModeAcceptToWork() Then
			TextTitle_ = NStr("vi = 'Tiếp nhận vào làm việc giao dịch';
								|ru = 'Принять в работу операцию';
								|en = 'Starting operation'; fa = 'Starting operation';
								|it = 'Prendere operazione in carico';
								|pl = 'Akceptuj operację do pracy';
								|tr = 'İşlemi işe kabul et'");
		ElsIf WorkMode = ModeOfOperationMarkExecution() Then
			TextTitle_ = NStr("vi = 'Đánh dấu thực hiện giao dịch';
								|ru = 'Отметить выполнение операции';
								|en = 'Mark operation execution'; fa = 'Mark operation execution';
								|it = 'Segnare l''esecuzione dell''operazione';
								|pl = 'Anuluj wykonanie operacji';
								|tr = 'İşlemin gerçekleştirilmesini işaretle'");
		EndIf;
		If Not Common.IsMobileClient() Then
			StageDetails = Common.ObjectAttributesValues(Stage, "Number,StageName"); 
			PresentationStage = Documents.ProductionStage2_2.PresentationStage(StageDetails);
			If ValueIsFilled(Operation) Then
				TextTitle_ = TextTitle_ + " (" + PresentationStage + ", " + Operation + ")";
			Else
				TextTitle_ = TextTitle_ + " (" + PresentationStage + ")";
			EndIf;
		EndIf;
	EndIf;
	
	AutoTitle = False;
	Title = TextTitle_;
	
	#EndRegion
	
	// Setting the header of the "Quantity available" field
	#Region QuantityIsAvailable
	
	If WorkMode = AssignOperatingMode() Then
		Items.QuantityIsAvailable.Title = NStr("vi = 'Đang chờ chỉ định';
												|ru = 'Ожидает назначения';
												|en = 'Pending assignment'; fa = 'در انتظار تخصیص';
												|it = 'In attesa di assegnazione';
												|pl = 'Oczekuje przeznaczenia';
												|tr = 'Atama bekleniyor'");
	Else
		Items.QuantityIsAvailable.Title = NStr("vi = 'Có thể thực hiện';
												|ru = 'Можно выполнять';
												|en = 'Can be completed'; fa = 'قابل تکمیل';
												|it = 'L''esecuzione è consentita';
												|pl = 'Można wykonywać';
												|tr = 'Gerçekleştirilebilir'");
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetArtistType()
	
	If ValueIsFilled(Department) Then
		
		DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
		
		ProductionManagementClientServer.SetArtistType(Performer,
			DivisionParameters.UseTeamWorkOrders,
			ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(CurrentSessionDate()));
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Setting up the Quantity element
	If Initialize
		Or AttributesStructure1.Property("QuantityIsAvailable") Then
		
		If Form.WorkMode <> ModeOfOperationMarkExecution() Then
			Form.Items.Count.MaxValue = Form.QuantityIsAvailable;
		Else
			Form.Items.Count.MaxValue = Undefined;
		EndIf;
		
	EndIf;
	
	// Setting up the Unit of Measurement element Representation
	If Initialize
		Or AttributesStructure1.Property("Count") Then
		
		Form.UnitOfMeasurePresentation = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Form.UnitOfMeasure,
			Form.Count,
			Form.IsMobileClient);
		
	EndIf;
	
	// Setting up the Unit of Measurement element of the Planned Representation
	If Initialize
		Or AttributesStructure1.Property("QuantityPlanned") Then
		
		Form.UnitOfMeasurementPlannedView = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Form.UnitOfMeasure,
			Form.QuantityPlanned,
			Form.IsMobileClient);
		
	EndIf;
	
	// Setting up the Unit of Measurement element Accessibility
	If Initialize
		Or AttributesStructure1.Property("QuantityIsAvailable") Then
		
		Form.UnitOfMeasurementViewAvailable = ProductionManagementClientServer.PresentationOfUnitOfOperation(
				Form.UnitOfMeasure,
				Form.QuantityIsAvailable,
				Form.IsMobileClient);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function AssignOperatingMode()
	
	Return "Assign";
	
EndFunction

&AtClientAtServerNoContext
Function OperatingModeAcceptToWork()
	
	Return "PutIntoOperation";
	
EndFunction

&AtClientAtServerNoContext
Function ModeOfOperationMarkExecution()
	
	Return "MarkCompletion";
	
EndFunction

&AtServer
Procedure CalculateDownload_()
	
	Load = ProductionAccounting.CalculateDownload(WorkCenter, Performer, Department);
	
	WorkCenterLoad          = Load.WorkCenter;
	ImportAssignee = Load.Performer;
	
EndProcedure

&AtClient
Procedure ShiftTaskStartChoiceCompletion(Result, AdditionalPrameters) Export
	If ValueIsFilled(Result) Then
		ShiftTask = Result.Jobs[0];
	EndIf;
EndProcedure

&AtServerNoContext
Function WorkTimeFactor(WorkCenter)
	
	If Not WorkCenter.IsEmpty() Then
		WorkTimeFactor = Common.ObjectAttributeValue(WorkCenter, "WorkTimeFactor");
	Else
		WorkTimeFactor = 1;
	EndIf;
	
	Return WorkTimeFactor;
	
EndFunction

&AtServer
Procedure PerformerSelectionStartsEndsAtServer()
	CalculateDownload_();
EndProcedure

&AtClient
Procedure ActivityKindsPerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Items.ActivityKinds.CurrentData.Performer = Result;
		
	EndIf;
	
EndProcedure

#EndRegion