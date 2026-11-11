///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
// @strict-types

#Region Public

// Called when the data area is deleted.
// In the procedure, it is necessary to delete the data of the data area that cannot be deleted by the standard mechanism.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   DataArea - Number - the value of the delimiter of the data area to delete.
//
Procedure OnDeleteDataArea(Val DataArea) Export
EndProcedure

// Generates a list of information security parameters.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ParametersTable - See SaaSOperations.IBParameters
//
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	SaaSOperationsLocalization.OnFillIIBParametersTable(ParametersTable);
EndProcedure

// Called before trying to get the IB parameter values from the constants of the same name.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ParameterNames - Array - the names of the parameters whose values you want to get.
//     							If the parameter value is obtained in this procedure, 
//     							you must delete the name of the processed parameter from the array.
//   ParameterValues - Structure - Parameter values.
//
Procedure OnGetIBParameterValues(Val ParameterNames, Val ParameterValues) Export
EndProcedure

// Called before attempting to write the values of the IB parameters to the constants of the same name.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   ParameterValues - Structure - the values of the parameters to be set.
//     If the parameter value is set in this procedure, the corresponding
//     key-value pair must be removed from the structure.
//
Procedure OnSetIBParametersValues(Val ParameterValues) Export
EndProcedure

// It is called when data separation by data areas is enabled,
// when the configuration is started for the first time with the parameter "InitializeSeparatedIB" ("InitializeSeparatedIB").
// In particular, a code should be placed here to enable routine tasks that are used only when 
// data separation is enabled, and, accordingly, to disable tasks that are used only when data separation is disabled.
// @skip-warning EmptyMethod - Overridable method.
//
Procedure OnEnableSeparationByDataAreas() Export
	SaaSOperationsLocalization.OnEnableSeparationByDataAreas();
EndProcedure

// Sets the user's default rights.
// It is called when working in the service model, if the user's rights are updated in
// the service manager without administrative rights.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  User - CatalogRef.Users - the user who
//   needs to set the default permissions.
//
Procedure SetDefaultRights(User) Export
EndProcedure

// Called when filling out exceptions for clearing database data 
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  CleanupExceptions - Array of String - full name of the metadata object
//
Procedure OnFillClearingDBDataExceptions(CleanupExceptions) Export
EndProcedure

#EndRegion
