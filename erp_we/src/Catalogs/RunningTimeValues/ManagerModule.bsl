
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Var AttributeValue;
	
	If Not GetFunctionalOption("UseRMManagement")
		And (Parameters.Property("DepreciationIndicator") And Parameters.DepreciationIndicator) Then
		
		Return;
		
	EndIf;
	
	If Parameters.Property("Class", AttributeValue)
		Or (Parameters.Property("Node", AttributeValue) And ValueIsFilled(AttributeValue))
		Or Parameters.Property("Asset", AttributeValue) Then
		
		StandardProcessing = False;
		ChoiceData = NonCurrentAssetsServerCall.DataOnSelectionOfOperatingTimeIndicatorsForSelection(
			AttributeValue,
			(Parameters.Property("RunningTimeRegistration") And Parameters.RunningTimeRegistration),
			(Parameters.Property("DepreciationIndicator") And Parameters.DepreciationIndicator));
		
	EndIf;
	
EndProcedure

#EndRegion