
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	FillPropertyValues(ThisObject, Parameters, Parameters.ParametersString1);
	
	ChoiceList = Items.ViewOption.ChoiceList;
	
	ChoiceList.Clear();
	
	ChoiceList.Add(DisplayOptionBriefly);
	ChoiceList.Add(DisplayOptionChart);
	
	If AnalysisType = TypeOfAnalysisComponentByComponentComparison Then
		ChoiceList.Add(DisplayOptionTable);
	EndIf;
	
	SetVisibility1(ThisForm);
EndProcedure

#EndRegion


#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AnalysisOptionOnChange(Item)
	AnalysisOptionOnChangeServer();
EndProcedure

&AtClient
Procedure ViewOptionOnChange(Item)
	Details_3 = False;
	TableSummary = False;
	SetVisibility1(ThisForm);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
 
&AtClient
Procedure CompleteEditing(Command)
	StringDataStructure = New Structure("AnalysisOption,ViewOption,Details_3,TableSummary,AnalysisType");
	FillPropertyValues(StringDataStructure, ThisForm);
	Close(StringDataStructure);
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure AnalysisOptionOnChangeServer()
	
	AnalysisType = Common.ObjectAttributeValue(AnalysisOption, "AnalysisType");
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibility1(Form)
	
	Form.Items.Details_3.Visible = (Form.ViewOption = Form.DisplayOptionBriefly);
	Form.Items.TableSummary.Visible = (Form.ViewOption = Form.DisplayOptionTable);
	
EndProcedure

#EndRegion

#EndRegion