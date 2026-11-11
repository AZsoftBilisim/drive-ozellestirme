
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	UseNonCurrentAssets = 
		Constants.UseNonCurrentAssets2_2.Get()
		Or Constants.UseNonCurrentAssets2_4.Get();
		
	UseRMManagement = Constants.UseRMManagement.Get();
										
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = (UseNonCurrentAssets Or UseRMManagement);
	PropertyManager.SetPropertySetParameters("Catalog_Assets_Overall", SetParameters);
	SetParameters.Used = UseRMManagement;	
	PropertyManager.SetPropertySetParameters("Catalog_RMTypes", SetParameters);
	
	SetParameters.Used = UseRMManagement;	
	PropertyManager.SetPropertySetParameters("Catalog_MaintenanceSchemes", SetParameters);
	
	SetParameters.Used = UseRMManagement;	
	PropertyManager.SetPropertySetParameters("Catalog_MaintenanceSchemeOptions", SetParameters);
	
	SetParameters.Used = UseRMManagement;	
	PropertyManager.SetPropertySetParameters("Document_RMOrder", SetParameters);
	
	SetParameters.Used = UseRMManagement;	
	PropertyManager.SetPropertySetParameters("Document_AssetActivityRecord", SetParameters);
	
	SetParameters.Used = UseRMManagement;	
	PropertyManager.SetPropertySetParameters("Document_RMRequest", SetParameters);
EndProcedure

#EndRegion

#EndIf
