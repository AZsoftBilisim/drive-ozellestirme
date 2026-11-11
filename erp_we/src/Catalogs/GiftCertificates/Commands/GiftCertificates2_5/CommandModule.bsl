// @strict-types

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	Filter = New Structure("GiftCardAccounting25", True);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("Catalog.GiftCertificates.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure

#EndRegion

#Region Private

#EndRegion
