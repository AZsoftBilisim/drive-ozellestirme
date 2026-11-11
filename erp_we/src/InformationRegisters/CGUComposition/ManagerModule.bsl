
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	Return;
EndProcedure

// Registers data for processing when switching to a new version.
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	Return;
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	Return;
EndProcedure

#EndRegion

#EndRegion

#EndIf
