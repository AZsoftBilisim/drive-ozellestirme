#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	EmployeeResponsible = Users.CurrentUser();
	Owner = SettingsValueCached.GetDefaultOrganization(Owner);
EndProcedure

Procedure OnCopy(CopiedObject)
	EmployeeResponsible = Users.CurrentUser();
	VersionOfSelectionSettings = 0;
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#EndIf