
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("ExcludeReports") Then
		ExcludeReports = Parameters.ExcludeReports;
		TypeOfSelectionComparison = DataCompositionComparisonType.NotEqual;
		If TypeOf(ExcludeReports) = Type("ValueList")
			Or TypeOf(ExcludeReports) = Type("Array") Then
			TypeOfSelectionComparison = DataCompositionComparisonType.NotInList;
		EndIf;
		ListSelectionsClientServer.SetListSelectionElement(List, "Ref", ExcludeReports, TypeOfSelectionComparison);
	EndIf;
	
	If Parameters.Property("ChartsOfAccounts") Then
		CommonClientServer.SetDynamicListParameter(List, "ChartsOfAccounts", Parameters.ChartsOfAccounts);
	EndIf;
	
EndProcedure

#EndRegion
