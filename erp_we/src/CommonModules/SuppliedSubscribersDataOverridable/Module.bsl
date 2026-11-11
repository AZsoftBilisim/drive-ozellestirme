///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for the subsystem of
// supplied components the general module of supplied components is undefined.
//

#Region Public

// The handler of the received area data.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  DataStream - FileStream - data stream for processing.
//  Handler  - String - ID of the received data handler.
//  DataProcessed - Boolean - a sign of data processing. Set = True if the data has been processed.
//                     You can't set the value = False, because the sign = True can be set earlier.
//  ReturnCode - Number - return code of the handler from the values of the lead Register.Properties of tasks.Status code()
//  ErrorDescription - String - description of the data processing error, if the data is not processed.
//
Procedure ProcessReceivedData(DataStream, Handler, DataProcessed, ReturnCode, ErrorDescription) Export
EndProcedure

#EndRegion
