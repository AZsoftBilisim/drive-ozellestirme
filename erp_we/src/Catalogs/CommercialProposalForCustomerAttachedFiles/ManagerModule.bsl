#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See ElectronicInteraction.OnFillMetadataObjectsAccessRestrictionKinds
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	CommercialProposalsDocumentsOverridable.OnFillMetadataObjectsAccessRestrictionKinds(
		"Catalog.CommercialProposalForCustomerAttachedFiles", LongDesc);
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	
	CommercialProposalsDocumentsOverridable.OnFillAccessRestriction(
		"Catalog.CommercialProposalForCustomerAttachedFiles", Restriction);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf
