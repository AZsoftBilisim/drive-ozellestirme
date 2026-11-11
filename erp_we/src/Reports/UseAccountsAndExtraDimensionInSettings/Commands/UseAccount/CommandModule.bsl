
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ReportSettings = ReportSettings(CommandParameter);
	SettingsKey = "UsingContextualReportInvoice";
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "AccountUsageContext");
	FormParameters.Insert("PurposeUseKey", SettingsKey);
	FormParameters.Insert("UserSettingsKey", SettingsKey);
	FormParameters.Insert("UserSettings", ReportSettings.UserSettings);
	FormParameters.Insert("FixedSettings", ReportSettings.FixedSettings);
	FormParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.UseAccountsAndExtraDimensionInSettings.Form", 
					FormParameters, 
					CommandExecuteParameters.Source, 
					CommandExecuteParameters.Uniqueness, 
					CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ReportSettings(Account)
	
	// Context Report Settings
	SettingsComposer = New DataCompositionSettingsComposer;
	SchemaName = Metadata.Reports.UseAccountsAndExtraDimensionInSettings.MainDataCompositionSchema.Name;
	ReportSchema = Reports.UseAccountsAndExtraDimensionInSettings.GetTemplate(SchemaName);
	OptionSettings = ReportSchema.SettingVariants.AccountUsageContext.Settings;
	SettingsComposer.LoadSettings(OptionSettings);
	UserSettings = SettingsComposer.UserSettings;
	UserSettings.AdditionalProperties.Insert("ItSInternational_", True);
	
	// Let's set the parameters of the contextual report
	DataCompositionClientServer.SetParameter(UserSettings, "GLAccount_", Account);
	
	Return SettingsComposer;
	
EndFunction

#EndRegion