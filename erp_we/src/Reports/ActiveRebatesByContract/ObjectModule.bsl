//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// When composing the result.
// 
// Parameters:
//  ResultDocument - SpreadsheetDocument - Result document
//  DetailsData - DataCompositionDetailsData - decryption data
//  StandardProcessing - Boolean - Standard treatment
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ReportSettings = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	
	ContractParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Contract");
	Contract = ContractParameter.Value;  // CatalogRef.CounterpartyContracts
	
	If Contract = Undefined Then
		
		ErrorText = NStr("vi = 'Chưa chọn hợp đồng';
						|ru = 'Не выбран договор';
						|en = 'Contract is not selected'; fa = 'Contract is not selected';
						|it = 'Не выбран договор';
						|pl = 'Contract is not selected';
						|tr = 'Sözleşme seçilmedi'");
		Raise ErrorText;
		
	EndIf;
	
	Attributes = "Counterparty, Partner";
	ContractDetails_ = Common.ObjectAttributesValues(Contract, Attributes);
	
	Counterparty = ContractDetails_.Counterparty;
	Partner = ContractDetails_.Partner;
	
	DataCompositionClientServer.SetParameter(ReportSettings, "Counterparty", Counterparty);
	DataCompositionClientServer.SetParameter(ReportSettings, "Partner", Partner);
	
	SetReportTitle(ReportSettings, Contract);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form or report settings form.
//       Undefined when a call is without context.
//   VariantKey - String, Undefined - the name of the predefined
//       or unique identifier of the custom version of the report.
//       Undefined when a call is without context.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export 
	
	If VariantKey = "CurrentRetroRebatesUnderContractContext" Then
		
		Settings.GenerateImmediately = True;
		Settings.EditOptionsAllowed = False;
		Settings.EditStructureAllowed = False;
		
	EndIf;
	
	Settings.Events.OnCreateAtServer = True; 
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		Form.ReportSettings.OptionSelectionAllowed = False;
		
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - See CommonForm.ReportForm
//   SchemaKey - String -
//       ID of the current configuration Composer schema.
//       By default, it is not filled in (this means that the Composer is initialized based on the main schema).
//       It is used for optimization in order to reinitialize the Composer as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       The name of a predefined or unique identifier of a custom version of the report.
//       It is undefined when the call is for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings Composer after it is initialized.
//       Undefined when user settings do not need to be loaded (already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		Parameters = Context.Parameters;
		If Parameters.Property("CommandParameter") Then
			
			CommandParameter = Parameters.CommandParameter; // CatalogRef.Partners, CatalogRef.Counterparties
			FillInParametersByContext(CommandParameter, NewDCSettings, NewDCUserSettings);
			
		EndIf;
		
	EndIf;
	
	SchemaKey = VariantKey;
	
EndProcedure

#EndRegion

#Region Private

// Fills in parameters from the passed context.
// 
// Parameters:
//  CommandParameter - AnyRef
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings Composer after it is initialized.
//       Undefined when user settings do not need to be loaded (already loaded earlier).
//
Procedure FillInParametersByContext(CommandParameter, NewDCSettings, NewDCUserSettings)
	
	CommandParameterType = TypeOf(CommandParameter);
	
	If CommandParameterType = Type("CatalogRef.CounterpartyContracts") Then
		
		DataCompositionClientServer.SetParameter(NewDCSettings, "Contract", CommandParameter);
		If NewDCUserSettings <> Undefined Then
			
			DataCompositionClientServer.SetParameter(
				NewDCUserSettings,
				"Contract", 
				CommandParameter);
			
		EndIf;
		
		DateEmpty = Date(1, 1, 1);
		
		Period = New StandardPeriod;
		Period.Variant = StandardPeriodVariant.Custom;
		Period.StartDate = DateEmpty;
		Period.EndDate = DateEmpty;
		
		DataCompositionClientServer.SetParameter(
			NewDCSettings,
			"Period",
			Period,
			False);
		
		If NewDCUserSettings <> Undefined Then
			
			DataCompositionClientServer.SetParameter(
				NewDCUserSettings,
				"Period",
				Period,
				False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ReportSettings - DataCompositionSettings - report settings
//  Contract - CatalogRef.CounterpartyContracts
//
Procedure SetReportTitle(ReportSettings, Contract)

	Template = NStr("vi = 'Thưởng lũy kế đang có hiệu lực theo hợp đồng ""%1""';
					|ru = 'Действующие ретро-бонусы по договору ""%1""';
					|en = 'Active rebates by the ""%1"" contract'; fa = 'Active rebates by the ""%1"" contract';
					|it = 'Действующие ретро-бонусы по договору ""%1""';
					|pl = 'Active rebates by the ""%1"" contract';
					|tr = 'Sözleşme üzerinde etkin retro-bonuslar'");
	ContractByLine = String(Contract);
	ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		ContractByLine);
		
	DataCompositionClientServer.SetOutputParameter(ReportSettings, "Title", ReportHeader);
	
EndProcedure

#EndRegion

#EndIf