// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// A variant of the report depending on the warehouse settings on the flight
// 
// Parameters:
//  Trip - DocumentRef.Trip
// 
// Returns:
//  CatalogRef.ReportsOptions, Undefined -
//
Function VersionOfFlightReport(Trip) Export
	
	ReportVariantParameters = ParametersOfTripReportOption(Trip);
	If Not ReportVariantParameters.WarehouseUsesOrderScheme
	 Or ReportVariantParameters.VariantKey = "" Then
		
		Variant = Catalogs.ReportsOptions.EmptyRef();
		
	Else
		
		Report = Common.MetadataObjectID(Metadata.Reports.PickingUnderTrip);
		Variant = ReportsOptions.ReportVariant(Report, ReportVariantParameters.VariantKey);
		
	EndIf;
	
	Return Variant;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PickingUnderTrip);
	ReportSettings.FunctionalOptions.Add("NotUseDeliveryManagement20");
	ReportSettings.DefineFormSettings = True;
	
	ReportSettings.ShouldShowInOptionsSubmenu = False;
	ReportSettings.Description = ReportDescription1();
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	TMReportOptionsOverridable.DisableReport(ReportSettings);
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	ReportCommand = Undefined;
	
	If AccessRight("View", Metadata.Reports.PickingUnderTrip) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PickingUnderTrip.FullName();
		ReportCommand.Presentation = ReportDescription1();
		ReportCommand.MultipleChoice = False;
		ReportCommand.IsNonContextual = False;
		ReportCommand.WriteMode = "Post";
		ReportCommand.FunctionalOptions = "NotUseDeliveryManagement20";
		ReportCommand.Importance = "Ordinary";
		
		ReportCommand.FormParameters = New Structure;
		ReportCommand.FormParameters.Insert("ReportOptionsCommandsVisibility", False);
		
	EndIf;
	
	Return ReportCommand;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  Trip - DocumentRef.Trip
// 
// Returns:
//  Structure:
// * WarehouseUsesOrderScheme - Boolean - 
// * VariantKey - String - 
//
Function ParametersOfTripReportOption(Trip) Export
	
	OptionParameters = New Structure;
	OptionParameters.Insert("WarehouseUsesOrderScheme", False);
	OptionParameters.Insert("VariantKey", "");
	
	QueryText =
	"SELECT
	|	Trip.DateOfDeparture AS DateOfDeparture,
	|	Warehouses.UseWarehouseManagemantSystemForGoodsIssue AS UseWarehouseManagemantSystemForGoodsIssue,
	|	Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue AS StartDateOfWarehouseManagemantSystemForGoodsIssue,
	|	Warehouses.StartShipmentOnceDeliveryOrderIsCreated AS KittingUpAfterDeliveryPlanning
	|FROM
	|	Document.Trip AS Trip
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON Trip.DepartureWarehouse = Warehouses.Ref
	|WHERE
	|	Trip.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Trip);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If Selection.UseWarehouseManagemantSystemForGoodsIssue
		   And Selection.StartDateOfWarehouseManagemantSystemForGoodsIssue <= Selection.DateOfDeparture Then
			
			OptionParameters.WarehouseUsesOrderScheme = True;
			If Selection.KittingUpAfterDeliveryPlanning Then
				
				OptionParameters.VariantKey = "KitAssemblyAccordingToDataOfTrip";
				
			Else
				
				OptionParameters.VariantKey = "KitIsAssembledRegardlessOfTrip";
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return OptionParameters;
	
EndFunction

#EndRegion

#Region Private

Function ReportDescription1()
	
	Return NStr("ru = 'Сборка по распоряжениям рейса';
				|vi = 'Picking under trip references';
				|en = 'Picking under trip references'; fa = 'برداشت بر اساس مراجع سفر';
				|it = 'Picking under trip references';
				|pl = 'Picking under trip references';
				|tr = 'Sefer talimatlarına göre toplama'");
	
EndFunction

#EndRegion

#EndIf