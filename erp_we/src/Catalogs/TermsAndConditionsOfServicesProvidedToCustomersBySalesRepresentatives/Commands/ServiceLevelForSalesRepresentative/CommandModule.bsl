#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterStructure1 = New Structure("Owner", CommandParameter);
	FormParameters = New Structure("Filter", FilterStructure1);
	
	OpenForm("Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.ListForm",
					FormParameters,
					CommandExecuteParameters.Source,
					CommandExecuteParameters.Uniqueness,
					CommandExecuteParameters.Window);
	
EndProcedure
				
#EndRegion
