#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("Owner");
 	Result.Add("Premise");

	Return Result;

EndFunction

// Returns the work area if it is the only one in the reference list
//
// Parameters:
//  Warehouse		 - CatalogRef.Warehouses			 - warehouse where you need to find a work site
//  Premise	 - CatalogRef.Warerooms	 - the room to find the work area
//  	for if the warehouse is not registered for warehouse premises, you need to pass an empty link.
// 
// Returns:
//  CatalogRef.WarehouseZones - link to the default warehouse work site.
//
Function DefaultWorkArea(Warehouse,Premise) Export
	
	Query = New Query(
	"SELECT TOP 2
	|	CatAreas.Ref AS ProductionArea
	|FROM
	|	Catalog.WarehouseZones AS CatAreas
	|WHERE
	|	(NOT CatAreas.DeletionMark)
	|	AND CatAreas.Owner = &Warehouse
	|	AND CatAreas.Premise = &Premise");
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		ProductionArea = Selection.ProductionArea;
	Else
		ProductionArea = Catalogs.WarehouseZones.EmptyRef();
	EndIf;
	
	Return ProductionArea;

EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Owner");
	NotAttributesToEdit.Add("Premise");
	
	Return NotAttributesToEdit;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf