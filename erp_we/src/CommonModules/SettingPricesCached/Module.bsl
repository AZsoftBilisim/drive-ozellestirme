#Region Private

// Returns a structure with a synonym and
// a data layout scheme by the layout name.
//
// Parameters:
//	TemplateName - String - name of the layout to get the description and schema from.
//	UsePriceManagementSystem25 - Boolean - The truth is, you can use the dataset for pricing 2.5.
//
// Returns:
//	Structure - description and layout diagram of the data.
//
Function GetDescriptionAndLayoutDiagramOfDataByTemplateName(TemplateName, UsePriceManagementSystem25) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("LongDesc",                  "");
	ReturnValue.Insert("DataCompositionSchema",     Undefined);
	
	ReturnValue.LongDesc 				= Metadata.Catalogs.TypesOfPrices.Templates.Find(TemplateName).Synonym;
	ReturnValue.DataCompositionSchema 	= Catalogs.TypesOfPrices.GetTemplate(TemplateName);
	
	PriceManagementSystemServerCall.GetPricingScheme(ReturnValue.DataCompositionSchema);
	
	ParameterCountryOfVATRates = DataCompositionClientServer.GetParameter(ReturnValue.DataCompositionSchema.DefaultSettings, "CountryOfVATRates");
	If ParameterCountryOfVATRates <> Undefined And Not ValueIsFilled(ParameterCountryOfVATRates.Value) Then
		DataCompositionClientServer.SetParameter(ReturnValue.DataCompositionSchema.DefaultSettings, "CountryOfVATRates", SettingsValueClientServerCached.MainCountry());
	EndIf;
	
	Return ReturnValue;
	
EndFunction

#EndRegion