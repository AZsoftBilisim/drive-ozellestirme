#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		SetParameters = ModulePropertyManager.PropertySetParametersStructure();
		SetParameters.Used = Constants.UseUserNotificationsOfSystemEvents.Get();
		
		ModulePropertyManager.SetPropertySetParameters("Catalog_UserNotificationKinds", SetParameters);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#EndIf