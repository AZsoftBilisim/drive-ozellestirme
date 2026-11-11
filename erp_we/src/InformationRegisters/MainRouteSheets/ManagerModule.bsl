#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Function MainOperationsSheet(Products, Characteristic, Department) Export
	
	Query = New Query(
	"SELECT
	|	MainRouteSheets.RouteSheet
	|FROM
	|	InformationRegister.MainRouteSheets AS MainRouteSheets
	|WHERE
	|	MainRouteSheets.Products = &Products
	|	AND MainRouteSheets.Characteristic = &Characteristic
	|	AND MainRouteSheets.Department = &Department");
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Department", Department);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Result = Selection.RouteSheet;
		
	Else
		
		Result = Undefined;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf