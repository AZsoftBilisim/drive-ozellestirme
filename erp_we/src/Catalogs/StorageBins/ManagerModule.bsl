#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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

// Returns a warehouse cell with the "Shipments" type, if it is the only one in the reference list
//
// Parameters:
//  Warehouse		 - CatalogRef.Warehouses			 - warehouse where you need to find the shipping zone
//  Premise	 - CatalogRef.Warerooms	 - the room to find the shipping zone
//  	for if the warehouse does not keep records of the warehouse premises, you need to pass an empty link
//  ShippingZone - CatalogRef.StorageBins		 - if this parameter is filled in and the cell belongs to the passed
//  		warehouse and room, the value of this parameter is returned.
// 
// Returns:
//  CatalogRef.StorageBins - link to the default warehouse shipping zone.
//
Function DefaultShippingZone(Warehouse,Premise,ShippingZone = Undefined) Export
	
	CellTypesShipment = WarehousesClientServer.CellTypesShipment();
	
	If ValueIsFilled(ShippingZone) Then
		CellDetails = Common.ObjectAttributesValues(ShippingZone, "Owner,Premise,StorageBinType");
		
		If CellDetails.Owner = Warehouse
			And CellDetails.Premise = Premise
			And CellTypesShipment.Find(CellDetails.StorageBinType) <> Undefined Then
			Return ShippingZone;
		EndIf;
	EndIf;
	
	Query = New Query(
	"SELECT TOP 2
	|	CatCells.Ref AS Cell
	|FROM
	|	Catalog.StorageBins AS CatCells
	|WHERE
	|	(NOT CatCells.DeletionMark)
	|	AND CatCells.StorageBinType IN (&ArrayOfCellTypes)
	|	AND CatCells.Owner = &Warehouse
	|	AND CatCells.Premise = &Premise");
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("ArrayOfCellTypes", CellTypesShipment);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		Cell = Selection.Cell;
	Else
		Cell = EmptyRef();
	EndIf;
	
	Return Cell;
	
EndFunction

// Returns a warehouse cell with the "Acceptance" type, if it is the only one in the reference list
//
// Parameters:
//  Warehouse		 - CatalogRef.Warehouses			 - warehouse where you need to find the acceptance zone
//  Premise	 - CatalogRef.Warerooms	 - the room to find the acceptance zone
//  	for if the warehouse is not registered for storage rooms, you need to pass an empty link
//  ReceivingArea	 - CatalogRef.StorageBins		 - if this parameter is filled in and the cell belongs to the passed
//  		warehouse and room, the value of this parameter is returned.
// 
// Returns:
//  CatalogRef.StorageBins - a reference to the default warehouse acceptance zone.
//
Function DefaultAcceptanceZone(Warehouse,Premise,ReceivingArea = Undefined) Export
	
	If ValueIsFilled(ReceivingArea) Then
		CellDetails = Common.ObjectAttributesValues(ReceivingArea, "Owner,Premise,StorageBinType");
		
		If CellDetails.Owner = Warehouse
			And CellDetails.Premise = Premise
			And CellDetails.StorageBinType = Enums.TypesOfStorageCells.Receiving Then
			Return ReceivingArea;
		EndIf;
	EndIf;
	
	Query = New Query(
	"SELECT TOP 2
	|	CatCells.Ref AS Cell
	|FROM
	|	Catalog.StorageBins AS CatCells
	|WHERE
	|	(NOT CatCells.DeletionMark)
	|	AND CatCells.StorageBinType = VALUE(Enum.TypesOfStorageCells.Receiving)
	|	AND CatCells.Owner = &Warehouse
	|	AND CatCells.Premise = &Premise");
	
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next() Then
		Cell = Selection.Cell;
	Else
		Cell = Catalogs.StorageBins.EmptyRef();
	EndIf;
	
	Return Cell;

EndFunction

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
		
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

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

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("View", Metadata.DataProcessors.PrintPriceTagsAndLabels) Then
		
		// Label printing
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.LabelPrintingStorageCells";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "LabelsStorageCells";
		PrintCommand.Presentation = NStr("vi = 'In nhãn tem';
										|ru = 'Печать этикеток';
										|en = 'Print labels'; fa = 'چاپ برچسب‌ها';
										|it = 'Stampa di etichette';
										|pl = 'Drukowanie etykiet';
										|tr = 'Etiketleri yazdır'");
		
	EndIf;
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf