#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Clears all customer ABC classification information.
Procedure ClearABCClassification() Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.ABCXYZCustomerClassification.CreateRecordSet();
	RecordSet.Filter.ClassificationType.Set(Enums.TypesOfClassification.ABC);
	RecordSet.Write();
	
EndProcedure

// Clears all customer XYZ classification information.
Procedure ClearXYZClassification() Export
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.ABCXYZCustomerClassification.CreateRecordSet();
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
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf