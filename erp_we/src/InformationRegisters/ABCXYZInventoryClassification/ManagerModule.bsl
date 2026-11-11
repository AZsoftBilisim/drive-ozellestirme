#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Clears all information about the ABC classification of the item.
Procedure ClearABCClassification() Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.ABCXYZInventoryClassification.CreateRecordSet();
	RecordSet.Filter.ClassificationType.Set(Enums.TypesOfClassification.ABC);
	RecordSet.Write();
	
EndProcedure

// Clears all XYZ classification information for the item.
Procedure ClearXYZClassification() Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.ABCXYZInventoryClassification.CreateRecordSet();
	RecordSet.Filter.ClassificationType.Set(Enums.TypesOfClassification.XYZ);
	RecordSet.Write();
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Products)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf