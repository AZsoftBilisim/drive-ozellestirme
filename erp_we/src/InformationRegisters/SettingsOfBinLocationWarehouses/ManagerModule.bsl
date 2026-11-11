#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure adds the default recharge setting to the register, if
// there are no settings for a warehouse (room) with address storage yet.
//
//	Parameters:
//	Warehouse - CatalogRef.Warehouses - the warehouse for which you are configuring;
//	Premise - CatalogRef.Warerooms - warehouse for which you are configuring;
//	UseBinLocationWarehousing - Boolean - True-indicates that address storage is used in a warehouse or in a room;
//	StartDateOfUsingWarehouseBinSystem - Date - the date from which the address storage 
//		of goods remaining in the warehouse / premises is used;
//	UseBinLocationWarehousingForInformation - Boolean - True-indicates the use of reference storage of goods 
//		in the address warehouse / room;
//	UseWarehouseZones - Boolean - True-indicates the use of work areas in the warehouse / room;
//	CopyOwnerSettings - Boolean - True-indicates that the warehouse settings need to be copied 
//		to the room settings.
//
Procedure ApplyDefaultSettings(Warehouse, Premise, UseBinLocationWarehousing,
										StartDateOfUsingWarehouseBinSystem, UseBinLocationWarehousingForInformation, UseWarehouseZones,
										CopyOwnerSettings = False) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	&Premise AS Premise,
		|	SettingsOfBinLocationWarehouses.*
		|FROM
		|	InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
		|WHERE
		|	SettingsOfBinLocationWarehouses.Warehouse = &Warehouse";
	If CopyOwnerSettings Then
		Query.Text = Query.Text + "
			|	AND SettingsOfBinLocationWarehouses.Premise = VALUE(Catalog.Warerooms.EmptyRef)";
	Else
		Query.Text = Query.Text + "
			|	AND SettingsOfBinLocationWarehouses.Premise = &Premise";
	EndIf;
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	
	Settings = Query.Execute().Select();
	
	Set = InformationRegisters.SettingsOfBinLocationWarehouses.CreateRecordSet();
	Set.Filter.Warehouse.Set(Warehouse);
	Set.Filter.Premise.Set(Premise);
	
	SettingsString = Set.Add();
	If Settings.Next() Then
		FillPropertyValues(SettingsString, Settings);
	Else
		SettingsString.Warehouse = Warehouse;
		SettingsString.Premise = Premise;
		Set.Fill(Undefined);
	EndIf;
	
	SettingsString.UseBinLocationWarehousing          = UseBinLocationWarehousing;
	SettingsString.StartDateOfUsingWarehouseBinSystem   = StartDateOfUsingWarehouseBinSystem;
	SettingsString.UseBinLocationWarehousingForInformation = UseBinLocationWarehousingForInformation;
	SettingsString.UseWarehouseZones            = UseWarehouseZones;
	
	Set.Write();
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf