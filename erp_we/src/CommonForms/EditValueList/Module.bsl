
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ValueList.ValueType = Parameters.ValueType;
	ValueList.LoadValues(Parameters.Values);
	
	If ValueIsFilled(Parameters.Title) Then
		Title = Parameters.Title;
		AutoTitle = False;
	EndIf;
	
	If ValueIsFilled(Parameters.ChoiceParameters) Then
		ArrayOfSelections = New Array;
		For Each KeyAndValue In Parameters.ChoiceParameters Do
			ArrayOfSelections.Add(New ChoiceParameter("Filter." + KeyAndValue.Key, KeyAndValue.Value));
		EndDo;
		ChoiceParameters = New FixedArray(ArrayOfSelections);
		Items.ListOfValuesValue.ChoiceParameters = ChoiceParameters;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	ReturnValue = ValueList.UnloadValues();
	Close(ReturnValue);
	
EndProcedure

#EndRegion