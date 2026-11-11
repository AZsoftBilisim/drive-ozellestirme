
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	AuthorizationObjectData = PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser();
	Partner = AuthorizationObjectData.Partner;
	
	If Partner = Undefined Or Partner.IsEmpty() Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("Partner", Partner);
	
	OpenForm("Report.StatusOfCustomersARAPSelfServiceWorkplace.Form",
	New Structure("Filter,GenerateOnOpen", FilterStructure1, True),
	CommandExecuteParameters.Source, 
	CommandExecuteParameters.Uniqueness,
	CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion



