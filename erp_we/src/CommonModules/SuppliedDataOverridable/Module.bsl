///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for the supplied data subsystem The
// general module supplied is undefined.
//

// Register handlers for the supplied data.
// @skip-warning EmptyMethod - Overridable method.
//
// When a notification is received about the availability of new shared data, the procedure is called.
// Available data from modules registered through getprocesserssuppliable Data.
// A descriptor, the xdto Descriptor Object, is passed to the procedure.
// 
// If the available Data sets the Load argument to True, 
// the data is loaded, and the handle and path to the data file are passed to the procedure.
// Process the new data. The file will be automatically deleted after the procedure is completed.
// If the file was not specified in the service Manager, the argument value is Undefined.
//
// Parameters: 
//   Handlers - ValueTable - table for adding handlers with columns:
//     * DataKind - String - code of the data type processed by the handler.
//     * HandlerCode - String - it will be used when restoring data processing after a failure.
//     * Handler - CommonModule - a module containing the following procedures:
//		  	Available New Data(Descriptor, Upload) Export  
//			Process New data(Descriptor, File path) Export
//			Processing Data is changed (Descriptor) Export
//
Procedure GetHandlersForSuppliedData(Handlers) Export
	SuppliedDataLocalization.GetHandlersForSuppliedData(Handlers);
	
EndProcedure

#EndRegion
