
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not GetFunctionalOption("UseProduction") Then
		
		StandardProcessing = False;
		
		EnumValues = New Array;
		If Parameters.Filter.Property("Ref") Then
			EnumValues.Add(Parameters.Filter.Ref);
		Else
			EnumValues.Add(PredefinedValue("Enum.SupplyTypes.Purchase"));
			EnumValues.Add(PredefinedValue("Enum.SupplyTypes.Move"));
			EnumValues.Add(PredefinedValue("Enum.SupplyTypes.AssemblyDisassembly"));
			EnumValues.Add(PredefinedValue("Enum.SupplyTypes.ProductionByThirdParty"));
			// Production is not added because it is not used
		EndIf;
		
		ChoiceData = New ValueList; // Result
		
		For Each Value In EnumValues Do
			If Not ValueIsFilled(Parameters.SearchString)
				Or StrFind(Lower(Value), Lower(Parameters.SearchString)) = 1 Then
				ChoiceData.Add(Value);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

