
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TypesOfMeasuredValues.Ref,
	|	TypesOfMeasuredValues.Order AS Order
	|FROM
	|	Enum.TypesOfMeasuredValues AS TypesOfMeasuredValues
	|WHERE
	|	TypesOfMeasuredValues.Ref <> VALUE(Enum.TypesOfMeasuredValues.Package)
	|
	|ORDER BY
	|	Order";
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref); 
	EndDo;

EndProcedure

#EndRegion
