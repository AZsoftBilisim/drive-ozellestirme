
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Var ParameterValue;
	
	If (Parameters.Property("Node", ParameterValue)
		And ValueIsFilled(ParameterValue))
		Or (Parameters.Property("Asset", ParameterValue)
			And ValueIsFilled(ParameterValue))Then
		
		Query = New Query(
			"SELECT
			|	Assets.Class
			|FROM
			|	Catalog.Assets AS Assets
			|WHERE
			|	Assets.Ref = &Ref
			|
			|UNION ALL
			|
			|SELECT
			|	SubAssets.Class
			|FROM
			|	Catalog.SubAssets AS SubAssets
			|WHERE
			|	SubAssets.Ref = &Ref");
		
		Query.SetParameter("Ref", ParameterValue);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Parameters.Filter.Insert("Owner", Selection.Class);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion