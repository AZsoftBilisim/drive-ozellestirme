#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the configuration of the control software warehouse
//
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - warehouse for which you need to get the security control setting
//	Returns:
//		Boolean - setting up warehouse security control. Undefined if there is no setting.
//
Function SettingUpWarehouse_(Warehouse) Export
	
	Query = New Query(
	"SELECT ALLOWED
	|	Setting.AvailableStockControl  AS AvailableStockControl
	|FROM
	|	InformationRegister.SetUpSupplyControl AS Setting
	|WHERE
	|	Setting.Warehouse = &Warehouse
	|	AND Setting.Products = VALUE(Catalog.Products.EmptyRef)
	|	AND Setting.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)");

	Query.SetParameter("Warehouse", Warehouse);

	Selection = Query.Execute().Select();
	Result = New Structure("AvailableStockControl");
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;

	Return Result;

EndFunction

// Saves the setting of the control software warehouse
//
//	Parameters:
//		Warehouse                           - CatalogRef.Warehouses - the warehouse for which you want to save the configuration of the control software
//		AvailableStockControl  - Boolean                  - the need to control the free stock balance, the stored value.
//                                                                  under the needs of orders with the action "To ensure".
//
Procedure SetSetting(Warehouse, AvailableStockControl) Export

	SettingUpFreeBalanceControl = SettingUpWarehouse_(Warehouse);

	If SettingUpFreeBalanceControl.AvailableStockControl <> AvailableStockControl Then

		RecordManager = InformationRegisters.SetUpSupplyControl.CreateRecordManager();
		RecordManager.Warehouse                                   = Warehouse;
		RecordManager.AvailableStockControl          = AvailableStockControl;

		RecordManager.Write();

	EndIf;

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
