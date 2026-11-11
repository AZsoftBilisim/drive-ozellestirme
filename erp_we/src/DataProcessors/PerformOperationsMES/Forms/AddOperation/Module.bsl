
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
	
	CustomizeFormElements();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not UseAreas Then
		NotCheckedAttributeArray.Add("ProductionArea");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure CountOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "Count");
	
EndProcedure

&AtClient
Procedure HideErrorMessageClick(Item)
	
	Items.ErrorMessageGroup.Visible = False;
	
EndProcedure

&AtClient
Procedure LabelErrorMessageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FillingValues = ValuesForFillingInNewOperation();
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	FormParameters.Insert("CheckWhenOpening", True);
	
	OpenForm("Document.ProductionOperation2_2.ObjectForm",
		FormParameters,
		ThisObject,
		,
		,
		,
		,
		FormWindowOpeningMode.Independent);
		
	Close();
	
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

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ManualFillingIsRequired = False;
	
	If Not WriteData(ManualFillingIsRequired) Then
		
		ClearMessages();
		
		MessageText = NStr("vi = 'Lỗi tạo hoạt động sản xuất!';
							|ru = 'Ошибка создания производственной операции!';
							|en = 'An error occurred when creating a routing operation.'; fa = 'An error occurred when creating a routing operation.';
							|it = 'Errore creazione dell''operazione di produzione!';
							|pl = 'Błąd podczas tworzenia operacji produkcyjnych!';
							|tr = 'Rota işlemi oluşturulurken hata oluştu!'");
		CommonClientServer.MessageToUser(MessageText);
		
		Items.ErrorMessageGroup.Visible = ManualFillingIsRequired;
		
		Return;
		
	EndIf;
	
	NotifyChanged(Type("InformationRegisterRecordKey.PostOperativeSchedule2_2"));
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function WriteData(ManualFillingIsRequired = False)
	
	FillingValues = ValuesForFillingInNewOperation();
	
	OperationObject = Documents.ProductionOperation2_2.CreateDocument();
	OperationObject.Fill(FillingValues);
	
	If Not OperationObject.CheckFilling() Then
		ManualFillingIsRequired = True;
		Return False;
	EndIf;
	
	HasErrors = False;
	BeginTransaction();
	Try
		
		InformationRegisters.QueueOfProductionOperations.BlockQueueForWritingByKey(FillingValues.OperationKey);
		
		InformationRegisters.PostOperativeSchedule2_2.BlockScheduleForRecordingByKey(FillingValues.OperationKey, FillingValues.LotNumber);
		
		If PerformBalanceControlWhenAddingOperation(FillingValues) Then
			
			OperationObject.Write(DocumentWriteMode.Posting);
			
		Else
			
			FillInFormDetailsForOperationData();
			HasErrors =  True;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Thực hiện giao dịch';
				|ru = 'Выполнение операции';
				|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
				|it = 'Svolgimento dell''operazione';
				|pl = 'Wykonanie operacji';
				|tr = 'İşlemin gerçekleştirilmesi'",
				CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo()));
		
		HasErrors = True;
		
	EndTry;
	
	Return Not HasErrors;
	
EndFunction

// Filling in the list of details according to the form parameters.
//
&AtServer
Function FillInFormDetailsByParameters()
	
	Stage     = Parameters.OperationKey.Stage; 
	Operation = Parameters.OperationKey.Operation;
	
	If Stage.IsEmpty() Or Operation.IsEmpty() Then
		Return False;
	EndIf;
	
	If Not Parameters.Property("WorkMode", WorkMode) Then
		Return False;
	EndIf;
	
	If Parameters.Property("LotNumber") Then
		LotNumber = Parameters.LotNumber;
	EndIf;
	
	If Parameters.Property("WorkCenter") Then
		WorkCenter = Parameters.WorkCenter;
	EndIf;
	
	If Parameters.Property("ProductionArea") Then
		ProductionArea = Parameters.ProductionArea;
	EndIf;
	
	FillInFormDetailsForOperationData();
	If QuantityIsAvailable = 0 Then
		Return False;
	EndIf;
	
	Count = QuantityIsAvailable;
	Organization = Common.ObjectAttributeValue(Stage, "Organization");
	
	UseAreas = GetFunctionalOption(
		"UseProductionSites",
		New Structure("Department", Department));
	
	ConfigureDependentFormElements(ThisForm, "Count");
	
	Return True;
	
EndFunction

&AtServer
Procedure FillInFormDetailsForOperationData()
	
	OperationData = InformationRegisters.PostOperativeSchedule2_2.ScheduleOperationData(Parameters.OperationKey, LotNumber, WorkCenter);
	
	If OperationData = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(
		ThisForm, 
		OperationData,
		"Department,
		|TechnologicalProcess,
		|WorkCenter,
		|LotNumber,
		|WorkCenterType,
		|UnitOfMeasure");
	
	
	
	If WorkCenter.IsEmpty() Then
		WorkCenter = OperationData.WorkCenter;
	EndIf;
	
	QuantityPlanned = OperationData.Scheduled;
	
	If WorkMode = ModeOfOperationCreate() Then
		QuantityIsAvailable = OperationData.WaitingForCreation;
	Else
		QuantityIsAvailable = OperationData.ExecutionIsAllowed;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm);

EndProcedure

&AtServer
Function PerformBalanceControlWhenAddingOperation(FillingData)
	
	OperationData = InformationRegisters.PostOperativeSchedule2_2.ScheduleOperationData(FillingData.OperationKey, FillingData.LotNumber, FillingData.WorkCenter);
	
	If OperationData = Undefined Then
		Return False;
	EndIf;
	
	If FillingData.Status = Enums.ProductionOperationStatuses.CreatedOn_
			And FillingData.Count > OperationData.WaitingForCreation
		Or FillingData.Status = Enums.ProductionOperationStatuses.Running
			And FillingData.Count > OperationData.ExecutionIsAllowed Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

// The function returns data for filling in operations on the "Add operation" form.
//
&AtServer
Function ValuesForFillingInNewOperation()
	
	OperationStatus = Undefined;
	If WorkMode = ModeOfOperationCreate() Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.CreatedOn_");
	ElsIf WorkMode = OperatingModeAcceptToWork() Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.Running");
	ElsIf WorkMode = ModeOfOperationMarkExecution() Then
		OperationStatus = PredefinedValue("Enum.ProductionOperationStatuses.Executed");
	EndIf;
	
	RCView = ?(WorkCenterType.IsEmpty(),
		?(WorkCenter.IsEmpty(),
			WorkCenterType,
			Common.ObjectAttributeValue(WorkCenter, "WorkCenterType")),
		WorkCenterType);
	
	FillingData = New Structure;
	
	FillingData.Insert("FillingMethod", "FillInByOperation");
	FillingData.Insert("Status", OperationStatus);
	FillingData.Insert("Department", Department);
	FillingData.Insert("OperationKey", Parameters.OperationKey);
	FillingData.Insert("LotNumber", LotNumber);
	FillingData.Insert("BasedOnPlanning", True);
	FillingData.Insert("Performer", Performer);
	FillingData.Insert("WorkCenterType", RCView);
	FillingData.Insert("WorkCenter", WorkCenter);
	FillingData.Insert("ProductionArea", ProductionArea);
	FillingData.Insert("Count", Count);
	
	Return FillingData;

EndFunction

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Performer = Result;
		
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
Procedure CustomizeFormElements() 
	
	// Relationships of work center selection parameters
	#Region WorkCenter 
	
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
	
	#EndRegion
	
	SetArtistType();
	
	ConfigureDependentFormElements(ThisForm);
	
	SetFormElementHeaders();
	
	Items.ProductionArea.Visible = UseAreas;
	
EndProcedure

&AtServer
Procedure SetFormElementHeaders()
	
	// Setting the Form header
	#Region FormCaption
	
	If WorkMode = ModeOfOperationCreate() Then
		TextTitle_ = NStr("vi = 'Tạo giao dịch';
							|ru = 'Создать операцию';
							|en = 'Create operation'; fa = 'Create operation';
							|it = 'Creare un''operazione';
							|pl = 'Utwórz operację';
							|tr = 'İşlem oluştur'");
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
	
	StageDetails = Common.ObjectAttributesValues(Stage, "Number,StageName"); 
	PresentationStage = Documents.ProductionStage2_2.PresentationStage(StageDetails);
	
	TextTitle_ = TextTitle_ + " (" + PresentationStage + ", " + Operation + ")";
	
	AutoTitle = False;
	Title = TextTitle_;
	
	#EndRegion
	
	// Setting the header of the "Quantity available" field
	#Region QuantityIsAvailable
	
	If WorkMode = ModeOfOperationCreate() Then
		TextTitle_ = NStr("vi = 'Đang chờ tạo';
							|ru = 'Ожидает создания';
							|en = 'Awaiting creation'; fa = 'Awaiting creation';
							|it = 'In attesa della creazione';
							|pl = 'Oczekuje na stworzenie';
							|tr = 'Oluşturma bekleniyor'");
	Else
		TextTitle_ = NStr("vi = 'Có thể thực hiện';
							|ru = 'Можно выполнять';
							|en = 'Can be completed'; fa = 'قابل تکمیل';
							|it = 'L''esecuzione è consentita';
							|pl = 'Można wykonywać';
							|tr = 'Gerçekleştirilebilir'");
	EndIf;
	
	Items.QuantityIsAvailable.Title = TextTitle_;
	
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
			Form.Count);
		
	EndIf;
	
	// Setting up the Unit of Measurement element of the Planned Representation
	If Initialize
		Or AttributesStructure1.Property("QuantityPlanned") Then
			
		Form.UnitOfMeasurementPlannedView = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Form.UnitOfMeasure,
			Form.QuantityPlanned);
			
	EndIf;
	
	// Setting up the Unit of Measurement element Accessibility
	If Initialize
		Or AttributesStructure1.Property("QuantityIsAvailable") Then
		
		Form.UnitOfMeasurementViewAvailable = ProductionManagementClientServer.PresentationOfUnitOfOperation(
			Form.UnitOfMeasure,
			Form.QuantityIsAvailable);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ModeOfOperationCreate()
	
	Return "Create";
	
EndFunction

&AtClientAtServerNoContext
Function OperatingModeAcceptToWork()
	
	Return "PutIntoOperation";
	
EndFunction

&AtClientAtServerNoContext
Function ModeOfOperationMarkExecution()
	
	Return "MarkCompletion";
	
EndFunction

#EndRegion
