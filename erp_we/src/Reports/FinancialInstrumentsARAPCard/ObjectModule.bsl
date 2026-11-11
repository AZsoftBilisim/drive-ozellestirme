#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;
	UserSettingsModified = False;

	Period = Undefined;
	If SettingsComposer.Settings.Filter.Items.Count() > 0 Then
		DocumentsArray = SettingsComposer.Settings.Filter.Items[0].RightValue;
		Reconciliation = Undefined;
		If TypeOf(DocumentsArray) = Type("DocumentRef.ARAPReconciliation2_4") And ValueIsFilled(DocumentsArray) Then
			Reconciliation = DocumentsArray;
		ElsIf TypeOf(DocumentsArray) = Type("ValueList") And DocumentsArray.Count() = 1 Then
			Reconciliation = DocumentsArray[0].Value;
		EndIf;
		If ValueIsFilled(Reconciliation) Then
			TimeIntervals = Common.ObjectAttributesValues(Reconciliation, "BeginOfPeriod, EndOfPeriod");
			Period = New StandardPeriod();
			Period.StartDate = TimeIntervals.BeginOfPeriod;
			Period.EndDate = TimeIntervals.EndOfPeriod;
			
			DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "Period", Period);
			DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings, "Period", Period);
			UserSettingsModified = True;
		EndIf;
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "LeaseObligations", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "DepositPayment", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "BuyoutValue", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "BuyoutValuePrepayment", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "RentalServicePrepayment", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "RentalService", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "RentalService", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "VAT", Undefined);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "LeaseObligations", Enums.TypesOfLeasePayments.LeaseObligations);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "DepositPayment", Enums.TypesOfLeasePayments.DepositPayment);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "BuyoutValue", Enums.TypesOfLeasePayments.BuyoutValue);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "BuyoutValuePrepayment", Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "RentalServicePrepayment", Enums.TypesOfLeasePayments.RentalServicePrepayment);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "RentalService", Enums.TypesOfLeasePayments.RentalService);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "InterestRent", Enums.TypesOfLeasePayments.Interests);
	DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "VAT", Enums.TypesOfLeasePayments.VAT);
	TemplateComposer = New DataCompositionTemplateComposer;
	
	ComposerSettings = SettingsComposer.GetSettings();
	LayoutParameter = ComposerSettings.DataParameters.Items.Find("ProhibitedPaymentTypes");
	If LayoutParameter <> Undefined Then
		LayoutParameter.Use = True;
		LayoutParameter.Value.LoadValues(Documents.ARAPReconciliation2_5_11.ProhibitedPaymentTypes());
	EndIf;
	
	DetailsData = New DataCompositionDetailsData;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, 
		ComposerSettings,
		DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);

	OutputProcessor.Output(CompositionProcessor, True);
	
	AuxiliaryParameters = New Array;
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryParameters);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

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
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.BeforeFillQuickSettingsBar = True;
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
	
	Parameters = ThisForm.Parameters;
	ParametersForm = ThisForm.ParametersForm;
	
	If Parameters.Property("CommandParameter") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		ParametersForm.Insert("CommandParameter", Parameters.CommandParameter);
		
		ValuesOfFunctionalOptions = New Structure;
		ValuesOfFunctionalOptions.Insert("BaseVersion", GetFunctionalOption("BaseVersion"));
		ValuesOfFunctionalOptions.Insert("TradeManagement", GetFunctionalOption("TradeManagement"));
		
		CommandParameter = Parameters.CommandParameter;
		
		If TypeOf(CommandParameter) = Type("Array") Then
			If CommandParameter.Count() > 0 Then
				TheFirstControl = CommandParameter[0];
			Else
				TheFirstControl = Undefined;
			EndIf;
		Else
			TheFirstControl = CommandParameter;
		EndIf;
		
		If TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
			If ValuesOfFunctionalOptions.TradeManagement
					Or ValuesOfFunctionalOptions.BaseVersion Then
				Parameters.VariantKey = "CardOfSettlementsOnFinancialInstrumentsTMContext";
			Else
				Parameters.VariantKey = "SettlementCardForFinancialInstrumentsContext";
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	If NewDCSettings <> Undefined Then
		SettingsComposer.LoadSettings(NewDCSettings);
	EndIf;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	SetRequiredSettings(FormSettingsComposer, True);
	
	NewDCSettings = FormSettingsComposer.Settings;
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on a variant key or report parameters.
//   In order for the schema changes to take effect, the Reportserver method should be called.Connect the Schema().
//   The additional properties of the New Configuration parameter and the Configuration property of the object Settings linker
//   include the properties of the key variant, the key of the defined variant, the context variant 
//   and the form parameter Selection.
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible.
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings builder after its initialization.
//       It is uncertain when the user settings do not need to be loaded (already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm")
		And NewDCSettings <> Undefined Then
		If Context.ParametersForm.Property("CommandParameter") Then
			Parameters = Context.Parameters;
			GenerateReportParameters(Context.ParametersForm.CommandParameter, Context, Parameters, NewDCSettings);
		EndIf;
	EndIf;
	
EndProcedure

// Is called before refilling the settings panel of the report form.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   FillParameters - Structure - Parameters to be uploaded to the report:
//   * ReportObjectOrFullName - ReportObject - report.
//
Procedure BeforeFillQuickSettingsBar(ThisForm, FillParameters) Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		If TypeOf(FillParameters.ReportObjectOrFullName) = Type("String") Then
			UserSettingsElements = SettingsComposer.Settings.Filter.Items;
		Else
			FilterReport_ = FillParameters.ReportObjectOrFullName.SettingsComposer.Settings.Filter; // DataCompositionFilter -
			UserSettingsElements = FilterReport_.Items;
		EndIf;
		
		For Each FilterElement In UserSettingsElements Do
			If FilterElement.LeftValue = New DataCompositionField("Partner") Then
				FilterElement.UserSettingPresentation = "Counterparty";
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateReportParameters(CommandParameter, ThisForm, Parameters, NewDCSettings)
	
	If TypeOf(CommandParameter) = Type("Array") Then
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		TheFirstControl = CommandParameter;
	EndIf;
	
	If TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
		Attributes = Undefined;
		Attributes = Documents.ARAPReconciliation2_5_11.DocumentAttributes(TheFirstControl);
		
		If Attributes <> Undefined Then
			If ValueIsFilled(Attributes.Organization) Then
				CommonClientServer.SetFilterItem(
					NewDCSettings.Filter, 
					"Organization",
					Attributes.Organization,
					DataCompositionComparisonType.Equal,,
					True);
			EndIf;
			If ValueIsFilled(Attributes.Counterparty) Then
				If GetFunctionalOption("UsePartnersAndCounterparties") Then
					CommonClientServer.SetFilterItem(
						NewDCSettings.Filter, 
						"Counterparty",
						Attributes.Counterparty,
						DataCompositionComparisonType.Equal,,
						True);
				Else
					CommonClientServer.SetFilterItem(
						NewDCSettings.Filter, 
						"Partner",
						Common.ObjectAttributeValue(Attributes.Counterparty,"Partner"),
						DataCompositionComparisonType.Equal,,
						True);
				EndIf;
			EndIf;
			Period = DataCompositionClientServer.GetParameter(NewDCSettings, "ReportPeriod");
			Period.Value.Variant = StandardPeriodVariant.Custom;
			Period.Value.StartDate = Attributes.BeginOfPeriod;
			Period.Value.EndDate = Attributes.EndOfPeriod;
			Period.Use = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
EndProcedure

Procedure SetRequiredSettings(Var_SettingsComposer, UserSettingsModified)
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(Var_SettingsComposer);
	
EndProcedure

#EndRegion

#EndIf
