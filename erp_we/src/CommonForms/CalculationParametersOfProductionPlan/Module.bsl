
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CalculationParameters = CalculationOfProductionPlan.CommonSettings();
	
	FillPropertyValues(ThisForm, CalculationParameters);
	
	StandardSettingsAreUsed = Common.IdenticalCollections(CalculationParameters,
																			CalculationOfProductionPlan.StandardSettingsForCalculatingProductionPlan());
	
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
	
	If Not LimitTheNumberOfLinesInTheRecordSet Then
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure VectorizeCalculationOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "VectorizeCalculation");
	
EndProcedure

&AtClient
Procedure ThreadsCountOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "ThreadsCount");
	
EndProcedure

&AtClient
Procedure ReadingPortionFromOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "ReadingPortionFrom");
	
EndProcedure

&AtClient
Procedure ReadingPortionBeforeOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "ReadingPortionBefore");
	
EndProcedure

&AtClient
Procedure RecordPortionOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "RecordPortion");
	
EndProcedure

&AtClient
Procedure LimitTheNumberOfLinesInTheRecordSetOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	If Not LimitTheNumberOfLinesInTheRecordSet Then
		NumberOfRowsInTheRecordset = 0;
	EndIf;
	
	ConfigureDependentFormDetails(ThisForm, "LimitTheNumberOfLinesInTheRecordSet");
	
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
Procedure MaxAccountingDepthOnChange(Item)
	
	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "MaxAccountingDepth");
	
EndProcedure

&AtClient
Procedure SearchCyclesAfterOnChange(Item)

	StandardSettingsAreUsed = False;
	
	ConfigureDependentFormDetails(ThisForm, "SearchCyclesAfter");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	ConfigureDependentFormDetails(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormDetails(Form, AttributesList = "")
	
	Object = Form;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If Initialize Then
		
		Form.LimitTheNumberOfLinesInTheRecordSet = Form.NumberOfRowsInTheRecordset > 0;
		
	EndIf;
	
	If AttributesStructure1.Property("VectorizeCalculation")
		Or Initialize Then
		
		Form.Items.ThreadsCount.Enabled = Form.VectorizeCalculation;
		
	EndIf;
	
	If AttributesStructure1.Property("LimitTheNumberOfLinesInTheRecordSet")
		Or Initialize Then
		
		Form.Items.NumberOfRowsInTheRecordset.Enabled = Form.LimitTheNumberOfLinesInTheRecordSet;
		Form.Items.NumberOfRowsInTheRecordset.AutoMarkIncomplete = Form.LimitTheNumberOfLinesInTheRecordSet;
		
	EndIf;

	
	If AttributesStructure1.Property("VectorizeCalculation")
			Or AttributesStructure1.Property("ThreadsCount")
			Or AttributesStructure1.Property("ReadingPortionFrom")
			Or AttributesStructure1.Property("ReadingPortionBefore")
			Or AttributesStructure1.Property("RecordPortion")
			Or AttributesStructure1.Property("LimitTheNumberOfLinesInTheRecordSet")
			Or AttributesStructure1.Property("NumberOfRowsInTheRecordset")
			Or AttributesStructure1.Property("MaxAccountingDepth")
			Or AttributesStructure1.Property("SearchCyclesAfter")
			Or AttributesStructure1.Property("AllowRepeatedUseOfCalculatedData")
			Or Initialize Then
		
		Form.Items.FormDefaultCommand.Enabled = Not Form.StandardSettingsAreUsed;
		
	EndIf;

EndProcedure

&AtServer
Procedure ApplyDefaultSettings()
	
	CalculationParameters = CalculationOfProductionPlan.StandardSettingsForCalculatingProductionPlan();
	
	FillPropertyValues(ThisForm, CalculationParameters);
	
	StandardSettingsAreUsed = True;
	
	ConfigureDependentFormDetails(ThisForm);
	
EndProcedure

&AtServer
Procedure SaveCalculationParameterSettings()
	
	Modified = False;
	CalculationOfProductionPlan.RecordProductionPlanCalculationSettings(ThisObject);
	
EndProcedure

&AtClient
Procedure SaveAndLoad(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If CheckFilling() Then
		SaveCalculationParameterSettings();
		Close();
	EndIf;
	
EndProcedure

#EndRegion
