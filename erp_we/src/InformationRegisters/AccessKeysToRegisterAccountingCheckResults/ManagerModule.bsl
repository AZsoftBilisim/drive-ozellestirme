///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// CloudTechnology.ExportImportData

// Attached in ExportImportDataOverridable.OnRegisterDataExportHandlers.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//   Serializer - XDTOSerializer
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	ItemsToDelete = New Array;
	For Each Record In Object Do
		If Record.Field1 = Undefined Then
			Continue;
		EndIf;
		
		IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(Record.Field1.Metadata());
		If Not IsSeparatedMetadataObject Then
			ItemsToDelete.Add(Record);
		EndIf;
	EndDo;
	
	For Each ToBeDeleted In ItemsToDelete Do
		Object.Delete(ToBeDeleted);
	EndDo;
	
EndProcedure

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf