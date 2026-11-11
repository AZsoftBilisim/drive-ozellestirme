#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ValuesOfFunctionalOptions = New Structure("BaseVersion", GetFunctionalOption("BaseVersion"));
		
		CommandParameter = Parameters.CommandParameter;
		
		If TypeOf(CommandParameter) = Type("Array") Then
			ThisIsArray = True;
			If CommandParameter.Count() > 0 Then
				TheFirstControl = CommandParameter[0];
			Else
				TheFirstControl = Undefined;
			EndIf;
		Else
			ThisIsArray = False;
			TheFirstControl = CommandParameter;
		EndIf;
		
		If TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_4") Then
			ThisForm.ParametersForm.Filter = New Structure("ARAPReconciliation", TheFirstControl);
			ThisForm.ParametersForm.PurposeUseKey = "ARAPReconciliation";
			Parameters.PurposeUseKey = "ARAPReconciliation";
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ReconciliationOfSettlements", 
			                                                                     ValuesOfFunctionalOptions.BaseVersion);
		
		ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.Counterparties") Then
			ThisForm.ParametersForm.Filter = New Structure("Counterparty", CommandParameter);
			ThisForm.ParametersForm.PurposeUseKey = "Counterparty";
			Parameters.PurposeUseKey = "Counterparty";
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ByCounterpartiesContext", 
			                                                                     ValuesOfFunctionalOptions.BaseVersion);

		ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.CounterpartyContracts") Then
			ThisForm.ParametersForm.Filter = New Structure("Contract", CommandParameter);
			ThisForm.ParametersForm.PurposeUseKey = "Contract";
			Parameters.PurposeUseKey = "Contract";
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("PartnersARAPAccounting", 
			                                                                     ValuesOfFunctionalOptions.BaseVersion);
			
		ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Or
			      TypeOf(TheFirstControl) = Type("CatalogRef.PartnersSegments") Then
			
			GenerateFormParametersOnServer(CommandParameter, ThisForm.ParametersForm, Parameters, 
			                                    TheFirstControl, ThisIsArray, ValuesOfFunctionalOptions.BaseVersion);
			
		EndIf;
		
	EndIf;
	
	
	ParametersForm = ThisForm.ParametersForm;
	
	If ParametersForm.Property("Filter")
	 And ParametersForm.Filter.Property("ARAPReconciliation") Then
	   
		Attributes = Documents.ARAPReconciliation2_4.DocumentAttributes(ParametersForm.Filter.ARAPReconciliation);
		If Attributes <> Undefined Then
			If ValueIsFilled(Attributes.Organization) Then	
				ParametersForm.Filter.Insert("Organization", Attributes.Organization);
			EndIf;
			If ValueIsFilled(Attributes.Counterparty) Then
				If GetFunctionalOption("UsePartnersAndCounterparties") Then
					ParametersForm.Filter.Insert("Counterparty", Attributes.Counterparty);
				Else
					ParametersForm.Filter.Insert("Partner", Common.ObjectAttributeValue(Attributes.Counterparty,"Partner"));
				EndIf;
			EndIf;
			Period = New StandardPeriod;
			Period.Variant = StandardPeriodVariant.Custom;
			Period.StartDate = Attributes.BeginOfPeriod;
			Period.EndDate = Attributes.EndOfPeriod;
			ParametersForm.Filter.Insert("Period", Period);
		EndIf;
		ParametersForm.Filter.Delete("ARAPReconciliation");
	EndIf;

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	ConfigureDefaultSelectionParameters(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("SettlementsData");
	UserSetting = SettingsComposer.UserSettings.Items.Find(
		DataParameter.UserSettingID);
	
	If UserSetting <> Undefined Then
		If UserSetting.Value = 2 // In the currency of the accounting department
			Or UserSetting.Value = 3 // In the currency of the regl. accounting
		Then
			#Region UpdatingSettlements
			SetPrivilegedMode(True);
			FilterFields = ARAPAllocationServerCall.DefaultSelectionFields();
			AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
			ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties);
			SetPrivilegedMode(False);
			#EndRegion		
		EndIf;		
	EndIf;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	#Region CheckingSettlements
	InformationRegisters.JobsForAllocatingVendorsARAP.DisplayRelevanceOfCalculation(ResultDocument, AuxProperties);
	#EndRegion
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	AuxiliaryParameters = New Array;
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryParameters);
EndProcedure

#EndRegion

#Region Private
	
Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
EndProcedure

Procedure ConfigureDefaultSelectionParameters(FormSettingsComposer, UserSettings = False)
	FixedPeriodSetting = FixedParameterSetting(FormSettingsComposer, "Period");
	
	If FixedPeriodSetting.Use = True Then
		
		UsesPeriodSetting = CustomParameterSetting(FormSettingsComposer, "Period");
		UsesPeriodSetting.Use = True;
		StandardPeriod = UsesPeriodSetting.Value; //StandardPeriod
		FixedStandardPeriod = FixedPeriodSetting.Value; //StandardPeriod
		StandardPeriod.StartDate = FixedStandardPeriod.StartDate;
		StandardPeriod.EndDate = FixedStandardPeriod.EndDate;
		
		FixedPeriodSetting.Use = False;
		
	EndIf;
EndProcedure

// LongDesc
// 
// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer
// 	ParameterName - String - LongDesc
// Returns:
// 	DataCompositionSettingsParameterValue - LongDesc
Function FixedParameterSetting(FormSettingsComposer, ParameterName)

	DataParameter = FormSettingsComposer.FixedSettings.DataParameters.Items.Find(ParameterName);
	
	Return DataParameter;

EndFunction

// LongDesc
// 
// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer 
// 	ParameterName - String - LongDesc
// Returns:
// 	DataCompositionSettingsParameterValue - LongDesc
Function CustomParameterSetting(FormSettingsComposer, ParameterName)

	DataParameter = FormSettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		CustomSettingParameter = FormSettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
	EndIf;
	Return Undefined;

EndFunction

Procedure GenerateFormParametersOnServer(CommandParameter, FormParameters, Parameters, TheFirstControl, ThisIsArray, ThisIsBasic)
	
	If TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Then
		
		If ThisIsArray Then
			ThereAreSubordinatePartners = False;
			For Each CommandParameterElement In CommandParameter Do
				If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
					ThereAreSubordinatePartners = True;
					Break;
				EndIf;
			EndDo;
		Else
			ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameter);
		EndIf;
		
		If ThereAreSubordinatePartners Then
			FixedSettings = New DataCompositionSettings();
			FilterElement = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField("Partner");
			FilterValue = CommandParameter;
			If ThisIsArray Then
				FilterValue = New ValueList;
				FilterValue.LoadValues(CommandParameter);
				FilterElement.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
			Else
				FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy;
			EndIf;
			FilterElement.RightValue = FilterValue;
			FormParameters.FixedSettings = FixedSettings;
			Parameters.FixedSettings = FixedSettings;
			FormParameters.PurposeUseKey = "Partners_Group";
			Parameters.PurposeUseKey = "Partners_Group";
			
		Else
			FormParameters.Filter = New Structure("Partner", CommandParameter);
			FormParameters.PurposeUseKey = "Partner";
			Parameters.PurposeUseKey = "Partner";
			
		EndIf;
		
		Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ByPartnersContext", ThisIsBasic);
		
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.PartnersSegments") Then
		
		FixedSettings = New DataCompositionSettings();
		FilterElement = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("Partner");
		FilterElement.ComparisonType = DataCompositionComparisonType.InList;
		
		FilterElement.RightValue = SegmentsOfCallServer.ValueList(TheFirstControl);
		FormParameters.FixedSettings = FixedSettings;
		Parameters.FixedSettings = FixedSettings;
		
		FormParameters.PurposeUseKey = "PartnersSegment";
		Parameters.PurposeUseKey = "PartnersSegment";
		Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ByPartnersContext", ThisIsBasic);
		
	EndIf;
	
EndProcedure

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "PartnersARAPAccounting" Then
		Return "SettlementsWithPartnersAreBasic";
	ElsIf VariantKeyName = "ByCounterpartiesContext" Then
		Return "ForCounterpartiesContextBasic";
	ElsIf VariantKeyName = "ByPartnersContext" Then
		Return "ByPartnersContextBasic";
	ElsIf VariantKeyName = "ReconciliationOfSettlements" Then
		Return "ReconciliationOfMutualSettlementsContextBasic";
	EndIf;
	
EndFunction

#EndRegion

#EndIf