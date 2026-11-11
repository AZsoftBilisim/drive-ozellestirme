
#Region Public

// Opens the selection settings form for the cost item allocation rules.
// Parameters:
//	Form - ClientApplicationForm - the owner form that opens the selection setup.
//	OpeningParameters - See ParametersForOpeningSelectionSettingsForm
Procedure OpenSelectionSettingsForm(Form, OpeningParameters) Export

	AddlParameters = AllocationRulesServerCall.AdditionalSelectionSettings(OpeningParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", True);
	FormParameters.Insert("DoNotConfigureSettings", AddlParameters.DoNotConfigureSettings);
	FormParameters.Insert("NotEditDataCompositionSchema", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", OpeningParameters.UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddlParameters.AddressOfDataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", AddlParameters.AddressOfDataCompositionSettings);
	FormParameters.Insert("Title", OpeningParameters.FormCaption);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("EditDataCompositionSchemaCompletion",
			Form,
			OpeningParameters),
		FormWindowOpeningMode.LockWholeInterface);

EndProcedure

// Constructor of parameters for opening the form for setting up item-by-item cost selections.
// Returns:
//	Structure - opening parameters.
Function ParametersForOpeningSelectionSettingsForm() Export
	
	Parameters = New Structure;
	Parameters.Insert("AllocationBase", Undefined);
	Parameters.Insert("NameOfComposerSettings", "");
	Parameters.Insert("SettingsComposer", Undefined);
	Parameters.Insert("FormCaption", "");
	Parameters.Insert("UUID", "");
	Parameters.Insert("UnavailableSelectionFields", New Array);
	
	Return Parameters;
	
EndFunction

#EndRegion
