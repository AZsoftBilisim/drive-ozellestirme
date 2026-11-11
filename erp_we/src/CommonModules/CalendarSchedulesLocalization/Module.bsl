///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called when the data changes, the production of calendars.
// If partitioning is enabled, it is performed in non-partitioned mode.
//
// Calendargraphicsreadable.Purchase of productioncalendaries ().
//
Procedure OnUpdateBusinessCalendars(UpdateConditions) Export
	
EndProcedure

// Called when the data changes, dependent on the production of the calendars.
// If partitioning is enabled, it is performed in data regions.
//
// Calendargraphicsreadable.Obobnovleniyidannyhzavisimyhotproizvodstvennykhkalendariy().
//
Procedure OnUpdateDataDependentOnBusinessCalendars(UpdateConditions) Export
	
EndProcedure

// Requests a file with calendar classifier data. 
// Converts the retrieved file into a structure with calendar tables and their data.
// If the classifier file cannot be retrieved, throws an exception.
//
// Parameters:
//  ClassifierData - Structure:
//   * BusinessCalendars - Structure:
//     * TableName - String          - Table name.
//     * Data     - ValueTable - A calendar data table converted from XML.
//   * BusinessCalendarsData - Structure:
//     * TableName - String          - Table name.
//     * Data     - ValueTable - A calendar data table converted from XML.
//
Procedure WhenReceivingClassifierData(ClassifierData) Export
	
	
EndProcedure

#EndRegion