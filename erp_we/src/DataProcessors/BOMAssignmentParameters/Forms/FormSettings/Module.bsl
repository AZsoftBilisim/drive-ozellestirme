
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ReadSettings();
	
	CustomizeFormElements();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		
		NewRow = ParametersTable.Add();
		NewRow.ParameterKind          = ValueSelected.ParameterKind;
		NewRow.Attribute              = ValueSelected.Attribute;
		NewRow.ParameterPresentation = PresentationOfDestinationParameter(NewRow.ParameterKind, NewRow.Attribute);
		
		Modified = True;
		
		ConfigureDependentFormElements(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersParametersTable

&AtClient
Procedure ParametersTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Not Copy Then
		AddParameter();
	EndIf;
	
EndProcedure

&AtClient
Procedure ParametersTableBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ParametersTableAfterDeleteRow(Item)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Add(Command)
	
	AddParameter();
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AddParameter()
	
	If Not AddingParameterIsAvailable(ThisObject) Then
		Return;
	EndIf;
	
	ExcludedAttributes = New Array;
	For Each String In ParametersTable Do
		Parameter = New Structure("ParameterKind,Attribute");
		FillPropertyValues(Parameter, String);
		ExcludedAttributes.Add(Parameter);
	EndDo;
	
	FormParameters = New Structure("ExcludedAttributes", ExcludedAttributes);
	
	OpenForm("DataProcessor.BOMAssignmentParameters.Form.AvailableParameterForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	
	WriteSettings();
	
	Modified = False;
	Close();
	
EndProcedure

&AtServer
Procedure ReadSettings()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	T.ParameterKind AS ParameterKind,
	|	T.Attribute     AS Attribute
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS T
	|
	|ORDER BY
	|	T.Priority DESC";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = ParametersTable.Add();
		NewRow.ParameterKind          = Selection.ParameterKind;
		NewRow.Attribute              = Selection.Attribute;
		NewRow.ParameterPresentation = PresentationOfDestinationParameter(Selection.ParameterKind, Selection.Attribute);
	EndDo;
	
EndProcedure

&AtServer
Procedure WriteSettings()
	
	RecordSet = InformationRegisters.BOMAssignmentParameters.CreateRecordSet();
	
	Priority = ParametersTable.Count();
	For Each String In ParametersTable Do
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, String);
		NewRecord.Priority = Pow(2, Priority);
		Priority = Priority - 1;
	EndDo;
	
	RecordSet.Write();
	
	RefreshReusableValues();
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ReadOnly = Not (GetFunctionalOption("UseProductionManagement2_2") 
		And Not GetFunctionalOption("UseProductionManagement"));
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form)
	
	Form.Items.ParametersTableAdd.Enabled = AddingParameterIsAvailable(Form);
	
EndProcedure

&AtClientAtServerNoContext
Function AddingParameterIsAvailable(Form)
	
	Return Form.ParametersTable.Count() < 10;
	
EndFunction

&AtServerNoContext
Function PresentationOfDestinationParameter(ParameterKind, Attribute)
	
	Return ProductDataManagement.PresentationOfDestinationParameter(ParameterKind, Attribute);
	
EndFunction

#EndRegion