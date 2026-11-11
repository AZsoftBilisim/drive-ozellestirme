////////////////////////////////////////////////////////////////////////////////
// The module "Provision in documents is redefined", contains procedures and functions
// for redefining the logic of the reservation mechanism and ensuring the needs for documents on the server.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Used to override the available balances used in the order.
// Prepares a temporary table of available data with columns similar to the incoming table of data tables.
// Parameters:
//  TempTablesManager - TempTablesManager - temporary table manager containing incoming tables:
//   * BalanceTable - QueryTempTable - table with columns:
//     ** Products - QueryTempTableColumn
//     ** Characteristic - QueryTempTableColumn
//     ** Warehouse - QueryTempTableColumn - warehouse for goods / division (for work)
//     ** Purpose - QueryTempTableColumn
//     ** Count - QueryTempTableColumn
//   * TemporaryDocumentDataTable - QueryTempTable - table with columns:
//     ** Products - QueryTempTableColumn
//     ** Characteristic - QueryTempTableColumn
//     ** Department - QueryTempTableColumn
//     ** Warehouse - QueryTempTableColumn
//     ** Purpose - QueryTempTableColumn
//     ** ShipmentOrder - QueryTempTableColumn
//     ** SupplyOption - QueryTempTableColumn
//     ** WithAssignment - QueryTempTableColumn
//     ** Count - QueryTempTableColumn
//     ** NumberOfPackages - QueryTempTableColumn
//     ** Package - QueryTempTableColumn
//     ** ReadyForSupply - QueryTempTableColumn
//     ** ReadyToShip - QueryTempTableColumn
//     ** RequestShipmentOn - QueryTempTableColumn
//     ** Series - QueryTempTableColumn
//     ** RowCode - QueryTempTableColumn
//     ** Canceled - QueryTempTableColumn
//     ** LineNumber - QueryTempTableColumn
//     ** Recorder - QueryTempTableColumn
//     ** DocumentDate - QueryTempTableColumn
//     ** GroupOfWarehouses - QueryTempTableColumn
//     ** Priority - QueryTempTableColumn
//     ** TheShipmentDateOfAllLinesIsASingleDate - QueryTempTableColumn
//  AdditionalParameters - Structure - Structure of additional parameters.
//
Procedure AddTemporaryTableAvailableBalances(TempTablesManager, AdditionalParameters) Export
	
	Return;
	
EndProcedure

#EndRegion

