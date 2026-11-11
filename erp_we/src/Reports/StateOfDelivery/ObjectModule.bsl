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
	
	SetReportTitle(ReportSettings);
	
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
	
	Settings.GenerateImmediately = False;
	Settings.EditOptionsAllowed = True;
	Settings.EditStructureAllowed = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
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
			
			CommandParameter = Parameters.CommandParameter; // DefinedType.DeliveryReferenceOrder25
			FillInParametersByContext(CommandParameter, NewDCSettings);
			
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
//
Procedure FillInParametersByContext(CommandParameter, NewDCSettings)
	
	CommandParameterType = TypeOf(CommandParameter);
	
	If Metadata.DefinedTypes.DeliveryReferenceOrder25.Type.ContainsType(CommandParameterType) Then
		
		SourceDocument_ = CommandParameter;
		ReferenceOrder = CommandParameter;
		
		If CommandParameterType = Type("DocumentRef.GoodsShipmentToCustomer") Then
			
			NamesOfShipmentDetails = New Array; // Array of String
			NamesOfShipmentDetails.Add("Patch");
			NamesOfShipmentDetails.Add("CorrectedDocument");
			
			AttributesValues = Common.ObjectAttributesValues(CommandParameter, NamesOfShipmentDetails);
			
			If AttributesValues.Patch Then
				
				ReferenceOrder = AttributesValues.CorrectedDocument;
				
			EndIf;
			
		EndIf;
		
		DataCompositionClientServer.SetParameter(NewDCSettings, "ReferenceOrder", ReferenceOrder);
		DataCompositionClientServer.SetParameter(NewDCSettings, "SourceDocument_", SourceDocument_);
		
	EndIf;
	
EndProcedure

Procedure SetReportTitle(ReportSettings)
	
	VariantKey = "";
	ReportSettings.AdditionalProperties.Property("VariantKey", VariantKey);
	
	If StrCompare(VariantKey, "DeliveryStateContext") = 0 Then
		
		ReferenceOrder = DataCompositionClientServer.GetParameter(ReportSettings, "SourceDocument_").Value; // DefinedType.DeliveryReferenceOrder25
		PresentationOfDocument = Common.SubjectString(ReferenceOrder);
		TitleTemplate1 = NStr("ru = 'Состояние доставки по документу %1';
								|vi = 'Delivery state according to the %1 document';
								|en = 'Delivery state according to the %1 document'; fa = 'Delivery state according to the %1 document';
								|it = 'Delivery state according to the %1 document';
								|pl = 'Delivery state according to the %1 document';
								|tr = 'Belgeye göre teslimat durumu %1'");
		ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, PresentationOfDocument);
		DataCompositionClientServer.SetOutputParameter(ReportSettings, "Title", ReportHeader);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf