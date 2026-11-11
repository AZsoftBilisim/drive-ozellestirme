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
	
	TripParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Trip").Value;
	PresentationOfDocument = Common.SubjectString(TripParameter);
	
	TitleTemplate1 = NStr("ru = 'Сверка данных сборки по документу %1';
							|vi = 'Reconciliation of picking data for the %1 document';
							|en = 'Reconciliation of picking data for the %1 document'; fa = 'Reconciliation of picking data for the %1 document';
							|it = 'Reconciliation of picking data for the %1 document';
							|pl = 'Reconciliation of picking data for the %1 document';
							|tr = 'Belgeye göre toplama verilerinin mutabakatı %1'");
	ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, PresentationOfDocument);
	DataCompositionClientServer.SetOutputParameter(ReportSettings, "Title", ReportHeader);
	
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
	
	Settings.GenerateImmediately = True;
	Settings.EditOptionsAllowed = False;
	Settings.EditStructureAllowed = True;
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - Report form:
//      * Report - ReportObject.PickingUnderTrip
//      * Parameters - Structure:
//         ** CommandParameter - DocumentRef.Trip -
//         ** VariantKey - String -
//   Cancel - Boolean - Indicates that the form was not created.
//       See the description of the parameter of the same name "Formaclientapplications.Joining the server" in the syntax assistant.
//   StandardProcessing - Boolean - Indicates that the standard (system) event processing has been performed.
//       See the description of the parameter of the same name "Formaclientapplications.Access to the server" in the syntax assistant.
//
// See also:
//   Procedure for displaying the added Commands in the form: Server Report.Call the() command.
//   Global handler for this event: reportdetermined.Access to the Server().
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	Trip = Undefined;
	
	If Not Parameters.Property("CommandParameter", Trip)
	 Or Not ValueIsFilled(Trip) Then
		
		Cancel = True;
		DocumentSynonym = Metadata.Documents.Trip.Synonym;
		ErrorTemplate = NStr("ru = 'Отчет предназначен только для открытия из документа ""%1"".';
							|vi = 'The report is used only to be opened from the ""%1"" document.';
							|en = 'The report is used only to be opened from the ""%1"" document.'; fa = 'The report is used only to be opened from the ""%1"" document.';
							|it = 'Отчет предназначен только для открытия из документа ""%1"".';
							|pl = 'The report is used only to be opened from the ""%1"" document.';
							|tr = 'Raporun yalnızca ""%1"" belgesinde açılması amaçlandı.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, DocumentSynonym);
		
		Raise ErrorText;
		
	EndIf;
	
	If Not ValueIsFilled(Parameters.VariantKey) Then
		
		Parameters.VariantKey = TripReportOptionKey(Trip, Cancel);
		
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
			
			CommandParameter = Parameters.CommandParameter; // DocumentRef.Trip
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
	
	If CommandParameterType = Type("DocumentRef.Trip") Then
		
		DataCompositionClientServer.SetParameter(NewDCSettings, "Trip", CommandParameter);
		
	EndIf;
	
EndProcedure

Function TripReportOptionKey(Trip, Cancel)
	
	OptionParameters = Reports.PickingUnderTrip.ParametersOfTripReportOption(Trip);
	
	If Not OptionParameters.WarehouseUsesOrderScheme Then
		
		MessageTemplate = NStr("ru = 'Формирование отчета недоступно: в документе ""%1"" выбран склад отправки, на котором на дату выезда рейса не используется ордерная схема при отгрузке.';
								|vi = 'Cannot generate the report: in the ""%1"" document, a shipping warehouse is selected, where warehouse management is not used for shipment on the trip start date.';
								|en = 'Cannot generate the report: in the ""%1"" document, a shipping warehouse is selected, where warehouse management is not used for shipment on the trip start date.'; fa = 'Cannot generate the report: in the ""%1"" document, a shipping warehouse is selected, where warehouse management is not used for shipment on the trip start date.';
								|it = 'Cannot generate the report: in the ""%1"" document, a shipping warehouse is selected, where warehouse management is not used for shipment on the trip start date.';
								|pl = 'Cannot generate the report: in the ""%1"" document, a shipping warehouse is selected, where warehouse management is not used for shipment on the trip start date.';
								|tr = 'Rapor oluşturma kullanılamıyor: ""%1"" belgesinde, seferin çıkış tarihinde sevkiyatta emir şeması kullanılmayan bir çıkış ambarı seçili.'");
		PresentationOfTrip = Common.SubjectString(Trip);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, PresentationOfTrip);
		
		Cancel = True;
		Raise MessageText;
		
	EndIf;
	
	Return OptionParameters.VariantKey;
	
EndFunction

#EndRegion

#EndIf