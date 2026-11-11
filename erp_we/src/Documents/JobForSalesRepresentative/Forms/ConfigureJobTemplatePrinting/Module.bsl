
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	RestoreSettings();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	WhenChangingOutputOfPaymentSchedule();
	WhenChangingOutputOfNotes();
	WhenChangingOutputOfExpenses();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DisplayPaymentScheduleOnChange(Item)
	
	WhenChangingOutputOfPaymentSchedule();
	
EndProcedure

&AtClient
Procedure DisplayNotesOnChange(Item)
	
	WhenChangingOutputOfNotes();
	
EndProcedure

&AtClient
Procedure DisplayExpensesOnChange(Item)
	
	WhenChangingOutputOfExpenses();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	CommonSettingsStorageSave();
	Close();
	
EndProcedure

&AtServer
Procedure CommonSettingsStorageSave()
	
	ObjectName = "Document.JobForSalesRepresentative.SettingsForPrintingTaskForms";
	
	Common.CommonSettingsStorageSave(ObjectName, "OutputTasksInASummaryTask", OutputTasksInASummaryTask);
	Common.CommonSettingsStorageSave(ObjectName, "DisplayPaymentSchedule", DisplayPaymentSchedule);
	Common.CommonSettingsStorageSave(ObjectName, "OutputTasks", OutputTasks);
	Common.CommonSettingsStorageSave(ObjectName, "DisplayNotes", DisplayNotes);
	Common.CommonSettingsStorageSave(ObjectName, "DisplayExpenses", DisplayExpenses);
	Common.CommonSettingsStorageSave(ObjectName, "NumberOfPaymentScheduleLines", NumberOfPaymentScheduleLines);
	Common.CommonSettingsStorageSave(ObjectName, "NumberOfProductsLines", NumberOfProductsLines);
	Common.CommonSettingsStorageSave(ObjectName, "NumberOfNoteLines", NumberOfNoteLines);
	Common.CommonSettingsStorageSave(ObjectName, "NumberOfExpenseLines", NumberOfExpenseLines);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure WhenChangingOutputOfPaymentSchedule()
	
	Items.NumberOfPaymentScheduleLines.Enabled = DisplayPaymentSchedule;
	
EndProcedure

&AtClient
Procedure WhenChangingOutputOfNotes()
	
	Items.NumberOfNoteLines.Enabled = DisplayNotes;
	
EndProcedure

&AtClient
Procedure WhenChangingOutputOfExpenses()
	
	Items.NumberOfExpenseLines.Enabled = DisplayExpenses;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure RestoreSettings()
	
	ObjectName = "Document.JobForSalesRepresentative.SettingsForPrintingTaskForms";
	StructureOfDefaultParameterValues = DefaultParameterValues();
	
	OutputTasksInASummaryTask = GetSettingParameterValue(ObjectName, "OutputTasksInASummaryTask", StructureOfDefaultParameterValues);
	DisplayPaymentSchedule = GetSettingParameterValue(ObjectName, "DisplayPaymentSchedule", StructureOfDefaultParameterValues);
	OutputTasks = GetSettingParameterValue(ObjectName, "OutputTasks", StructureOfDefaultParameterValues);
	DisplayNotes = GetSettingParameterValue(ObjectName, "DisplayNotes", StructureOfDefaultParameterValues);
	DisplayExpenses = GetSettingParameterValue(ObjectName, "DisplayExpenses", StructureOfDefaultParameterValues);
	
	NumberOfPaymentScheduleLines = GetSettingParameterValue(ObjectName, "NumberOfPaymentScheduleLines", StructureOfDefaultParameterValues);
	NumberOfProductsLines = GetSettingParameterValue(ObjectName, "NumberOfProductsLines", StructureOfDefaultParameterValues);
	NumberOfNoteLines = GetSettingParameterValue(ObjectName, "NumberOfNoteLines", StructureOfDefaultParameterValues);
	NumberOfExpenseLines = GetSettingParameterValue(ObjectName, "NumberOfExpenseLines", StructureOfDefaultParameterValues);
	
EndProcedure

&AtServer
// Gets and returns the value of the setting parameter.
//
// Parameters:
//  The name of the object is the name of the configuration object.
//  Parameter name is the name of the setting parameter.
//  The Default parameter value structure is a structure containing default parameter values.
//
// Returns:
//  parameter value.
//
Function GetSettingParameterValue(ObjectName, ParameterName, StructureOfDefaultParameterValues)
	
	ParameterValue = Common.CommonSettingsStorageLoad(ObjectName, ParameterName);
	
	If ParameterValue <> Undefined Then
		Return ParameterValue;
	Else
		DefaultValue = Undefined;
		StructureOfDefaultParameterValues.Property(ParameterName, DefaultValue);
		Return DefaultValue;
	EndIf;
	
EndFunction

&AtServer
// Generates and returns a structure containing default parameter values.
//
// Returns:
//  A structure containing default parameter values.
//
Function DefaultParameterValues()
	
	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("OutputTasksInASummaryTask", False);
	ParametersStructure.Insert("DisplayPaymentSchedule", True);
	ParametersStructure.Insert("OutputTasks", True);
	ParametersStructure.Insert("DisplayNotes", True);
	ParametersStructure.Insert("DisplayExpenses", True);
	
	ParametersStructure.Insert("NumberOfPaymentScheduleLines", 3);
	ParametersStructure.Insert("NumberOfProductsLines", 5);
	ParametersStructure.Insert("NumberOfNoteLines", 5);
	ParametersStructure.Insert("NumberOfExpenseLines", 5);
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#EndRegion
