#Region Public

// Handler for uploading data.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - the object being unloaded.
//   ExportingParameters - Structure - The parameters of discharge
//   XMLWriter - XMLWriter - For self-serialization.
//   ObjectCount - Number - The counter that needs to be incremented in order for the object to be unloaded
//   Cancel - Boolean - If this parameter is set to True, the object will not be unloaded,
//   				and you can serialize the object yourself, for example, using the Upload parameter.The serializer in the XML record.
//@skip-check module-empty-method - Overridable method.
Procedure OnExportObject(Object, ExportingParameters, XMLWriter, ObjectCount, Cancel) Export
EndProcedure

// Handler for when data is loaded.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - the loaded object.
//   Cancel - Boolean - if this parameter is set to True, the object will not be loaded.
//@skip-check module-empty-method - Overridable method.
Procedure OnImportObject(Object, Cancel) Export
EndProcedure

// Handler for registering changes.
//
// Parameters:
//   Source - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - 
//			the registered object.
//   Cancel - Boolean - if this parameter is set to True, the object will not be registered.
//@skip-check module-empty-method - Overridable method.
Procedure AtRegisteringObjectChanges(Source, Cancel) Export	
EndProcedure

// When determining which metadata objects are allowed to be uploaded.
// Intended use for metadata objects added in the extension that cannot be filtered from 
// Service manager.
// 
// Parameters:
//  MetadataObjects - Map of KeyAndValue - collection of metadata objects:
//   * Key - String - name of the metadata object
//   * Value - Boolean - Indicates whether it is allowed to upload this object
//@skip-check module-empty-method - Overridable method.
Procedure OnDefineMetadataObjectsAllowedForExport(MetadataObjects) Export
EndProcedure

#EndRegion
	
