#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InfobaseUpdate

Procedure FillInUnits() Export
	
	QueryText =
	"SELECT
	|	T.Ref
	|FROM
	|	Catalog.StandardSizesOfPackages AS T
	|WHERE
	|	T.HeightUnitOfMeasure = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
	
	UnitsOfMeasurement = Catalogs.PackagesAndUnitsOfMeasure.BasicUnitsOfMeasure();
		
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatObject = Selection.Ref.GetObject();
		FillPropertyValues(CatObject,UnitsOfMeasurement);
		InfobaseUpdate.WriteObject(CatObject);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf