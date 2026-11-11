
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Service_Settings = OrderStructure.Service_Settings();
	
	FillPropertyValues(ThisForm, Service_Settings);
	
	StandardSettingsAreUsed = Common.IdenticalCollections(Service_Settings,
																			OrderStructure.StandardSettingsForCalculatingOrderStructure());
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("SaveAndLoad", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not PortionSelection Then
		NotCheckedAttributeArray.Add("SelectionSize");
	EndIf;
	
	If Not BatchRecording Then
		NotCheckedAttributeArray.Add("NumberOfRowsInTheRecordset");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ApplyCommand(Command)
	
	SaveAndLoad();
	
EndProcedure

&AtClient
Procedure DefaultCommand(Command)
	
	ApplyDefaultSettings();
	
EndProcedure

&AtClient
Procedure SetUpScheduleForLocalTasksRegisterConvolutionOrderStructure(Command)
	
	CallbackDescription = New CallbackDescription("ChangeScheduleOfLocalTasksRegisterConvolutionOrderStructure", ThisObject);
	
	If LocalTaskScheduleRegisterConvolutionOrderStructure = Undefined Then
		JobSchedule = New JobSchedule;
	Else
		JobSchedule = LocalTaskScheduleRegisterConvolutionOrderStructure;
	EndIf;
	
	Dialog = New ScheduledJobDialog(JobSchedule);
	Dialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure ChangeScheduleOfLocalTasksRegisterConvolutionOrderStructure(TaskSchedule, AdditionalParameters) Export
	
	If TaskSchedule = Undefined Then
		Return;
	EndIf;
	
	LocalTaskScheduleRegisterConvolutionOrderStructure = TaskSchedule;
	
	SetScheduleTextLocalTasksRegisterConvolutionOrderStructure();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure VectorizeCalculationOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	BatchRecording = True;
	NumberOfRowsInTheRecordset = ?(VectorizeCalculation, 2500, 100000);
	
	ConfigureDependentFormDetails(ThisForm, "VectorizeCalculation");
	
EndProcedure

&AtClient
Procedure ThreadsCountOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "ThreadsCount");
	
EndProcedure

&AtClient
Procedure PortionSelectionOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	If Not PortionSelection Then
		SelectionSize = 0;
	EndIf;
	
	ConfigureDependentFormDetails(ThisForm, "PortionSelection");

EndProcedure

&AtClient
Procedure SelectionSizeOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "SelectionSize");
	
EndProcedure

&AtClient
Procedure BatchRecordingOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	If Not BatchRecording Then
		NumberOfRowsInTheRecordset = 0;
	EndIf;
	
	ConfigureDependentFormDetails(ThisForm, "BatchRecording");
	
EndProcedure

&AtClient
Procedure NumberOfRowsInTheRecordsetOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "NumberOfRowsInTheRecordset");
	
EndProcedure

&AtClient
Procedure AllowRepeatedUseOfCalculatedDataOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "AllowRepeatedUseOfCalculatedData");
	
EndProcedure

&AtClient
Procedure CalculateChanges_OnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "CalculateChanges_");
	
EndProcedure

&AtClient
Procedure MaxAccountingDepthOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "MaxAccountingDepth");
	
EndProcedure

&AtClient
Procedure SearchCyclesAfterOnChange(Item)

	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "SearchCyclesAfter");
	
EndProcedure

&AtClient
Procedure AdditionalParametersOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "AdditionalParameters");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()

	Items.GroupParallelizeCalculation.Visible = (VectorizeCalculation Or Not Common.DataSeparationEnabled());

	Filter = New Structure();
	Filter.Insert("Metadata", Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister.Name);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	If Jobs.Count() = 1 Then
		LocalTaskScheduleRegisterConvolutionOrderStructure = Jobs[0].Schedule;
	EndIf;
	
	ConfigureDependentFormDetails(ThisForm);
	
	SetScheduleTextLocalTasksRegisterConvolutionOrderStructure();
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormDetails(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("VectorizeCalculation") Or Initialize Then
		Items.ThreadsCount.Enabled = Form.VectorizeCalculation;
	EndIf;
	
	If AttributesStructure1.Property("PortionSelection") Or AttributesStructure1.Property("VectorizeCalculation") Or Initialize Then
		
		Items.SelectionSize.Enabled = Form.PortionSelection;
		Items.SelectionSize.AutoMarkIncomplete = Form.PortionSelection;
		
	EndIf;
	
	If AttributesStructure1.Property("BatchRecording") Or AttributesStructure1.Property("VectorizeCalculation") Or Initialize Then
		
		Items.NumberOfRowsInTheRecordset.Enabled = Form.BatchRecording;
		Items.NumberOfRowsInTheRecordset.AutoMarkIncomplete = Form.BatchRecording;
		
	EndIf;
	
	If AttributesStructure1.Property("CalculateChanges_") Or Initialize Then
		
		Items.SetUpScheduleForLocalTasksRegisterConvolutionOrderStructure.Enabled = Form.CalculateChanges_;
		
	EndIf;
	
	Items.FormDefaultCommand.Enabled = Not Form.StandardSettingsAreUsed;

EndProcedure

&AtServer
Procedure SetScheduleTextLocalTasksRegisterConvolutionOrderStructure()
	
	If LocalTaskScheduleRegisterConvolutionOrderStructure = Undefined Then
		
		ScheduleText = NStr("vi = '<Chưa đặt lịch biểu>';
							|ru = '<Расписание не задано>';
							|en = '<Schedule is not specified>'; fa = '<زمان‌بندی مشخص نشده است>';
							|it = '<Расписание не задано>';
							|pl = '<Harmonogram nie jest zadany>';
							|tr = '<Plan ayarlanmadı>'");
		
	Else
		
		ScheduleText = String(LocalTaskScheduleRegisterConvolutionOrderStructure);
		
	EndIf;
	
	Items.SetUpScheduleForLocalTasksRegisterConvolutionOrderStructure.Title = ScheduleText;
	
EndProcedure

&AtServer
Procedure ApplyDefaultSettings()
	
	Service_Settings = OrderStructure.StandardSettingsForCalculatingOrderStructure();
	
	FillPropertyValues(ThisForm, Service_Settings);
	
	StandardSettingsAreUsed = True;
	
	ConfigureDependentFormDetails(ThisForm);
	
EndProcedure

&AtServer
Procedure RecordSettingsForCalculatingOrderStructure()
	
	Modified = False;
	
	OrderStructure.RecordSettingsForCalculatingOrderStructure(ThisObject);
	
	OrderStructureInternal.SetScheduleOfLocalTasksRegisterConvolutionOrderStructure(LocalTaskScheduleRegisterConvolutionOrderStructure);
	
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure SaveAndLoad(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If CheckFilling() Then
		RecordSettingsForCalculatingOrderStructure();
		Close();
	EndIf;
	
EndProcedure


#EndRegion
