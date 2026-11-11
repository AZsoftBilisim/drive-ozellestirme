
#Region Public

// Called when defining services that support migration.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Services - ValueList - the value is the address of the service, and the representation is the representation of the service.
//
Procedure OnDefineServices(Services) Export
EndProcedure

// Handler for uploading data.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - the object being unloaded.
//   Cancel - Boolean - if this parameter is set to True, the object will not be unloaded.
//
Procedure OnExportObject(Object, Cancel) Export
EndProcedure

// Handler for when data is loaded.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//   Object - ConstantValueManager, CatalogObject, DocumentObject, ChartOfAccountsObject -
//			- ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//          - AccumulationRegisterRecordSet, AccountingRegisterRecordSet, CalculationRegisterRecordSet -
//			- SequenceRecordSet, RecalculationRecordSet, BusinessProcessObject, TaskObject - the loaded object.
//   Cancel - Boolean - if this parameter is set to True, the object will not be loaded.
//
Procedure OnImportObject(Object, Cancel) Export
EndProcedure

#EndRegion
	
