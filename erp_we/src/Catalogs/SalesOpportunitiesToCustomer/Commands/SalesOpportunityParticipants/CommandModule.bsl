
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	
	DealSource = CommandExecuteParameters.Source.Object;
	UUID = CommandExecuteParameters.Source.UUID;
	
	OpenForm(
		"Catalog.SalesOpportunitiesToCustomer.Form.SalesOpportunityParticipants",
		New Structure("AddressParticipants,Partner",
		       CommandAddressInTemporaryStorage(DealSource, UUID),
		       DealSource.Partner),
		    CommandExecuteParameters.Source,
		    CommandExecuteParameters.Uniqueness,
		    CommandExecuteParameters.Window);

EndProcedure

#EndRegion

#Region Private

&AtServer
Function CommandAddressInTemporaryStorage(DealSource, UUID)

	Return PutToTempStorage(DealSource.PartnersAndContactPersons.Unload(),UUID)

EndFunction

#EndRegion
