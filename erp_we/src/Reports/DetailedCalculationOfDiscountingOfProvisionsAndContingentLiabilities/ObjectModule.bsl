
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	LoggerParameter = ReportSettings.DataParameters.Items.Find("Recorder");
	
	If ValueIsFilled(LoggerParameter.Value) Then
		DocumentDate = Common.ObjectAttributeValue(LoggerParameter.Value, "Date");
		DataCompositionClientServer.SetParameter(ReportSettings, "Period", DocumentDate);
		
		For Each GroupingField In ReportSettings.Selection.Items Do
			If GroupingField.Title = NStr("vi = 'Giá trị hiện tại';
											|ru = 'Приведенная стоимость';
											|en = 'Present value'; fa = 'ارزش فعلی';
											|it = 'Valore attuale';
											|pl = 'Sprowadzona wartość';
											|tr = 'Bugünkü değeri'") Then
				GroupingField.Title = StrTemplate(NStr("vi = 'Giá trị hiện tại của %1';
														|ru = 'Приведенная стоимость на %1';
														|en = 'Present value as of %1'; fa = 'Present value as of %1';
														|it = 'Приведенная стоимость на %1';
														|pl = 'Present value as of %1';
														|tr = '%1 başına bugünkü değer '"),
					Format(DocumentDate, "DF=dd.MM.yyyy; DLF=D;"));
			EndIf;
			If GroupingField.Title = NStr("vi = 'Số tiền lãi';
											|ru = 'Сумма процентов';
											|en = 'Interest amount'; fa = 'مبلغ بهره';
											|it = 'Importo degli interessi';
											|pl = 'Wartość odsetek';
											|tr = 'Faiz tutarı'") Then
				GroupingField.Title = StrTemplate(NStr("vi = 'Số tiền phần trăm của %1';
														|ru = 'Сумма процентов на %1';
														|en = 'Interest amount as of %1'; fa = 'Interest amount as of %1';
														|it = 'Сумма процентов на %1';
														|pl = 'Interest amount as of %1';
														|tr = '%1 başına faiz tutarı'"),
					Format(DocumentDate, "DF=dd.MM.yyyy; DLF=D;"));
			EndIf;
		EndDo;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure - see the return value of the Clientserver report.Get a setup report for silence().
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		If Not ThisForm.ParametersForm.Filter.Property("Recorder") Then
			ThisForm.ParametersForm.Filter.Insert("Recorder", Parameters.CommandParameter);
		EndIf;
		DocumentDate = Common.ObjectAttributeValue(Parameters.CommandParameter, "Date");
		ThisForm.ParametersForm.Filter.Insert("Period", DocumentDate);
	EndIf;
	
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
//       User settings that will be loaded into the Settings Composer after it is initialized.
//       It is uncertain when user settings do not need to be loaded (already loaded earlier).
//
// Examples:
// 1. The Composer of the report is initialized based on the scheme from the general Templates:
//	If the key of the scheme <> is "1" Then
//		Schema Key = "1";
//		SCHEMACD = Get a Public package("My Public Schemacompositions");
//		Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//	The end if;
//
// 2. The scheme depends on the value of the parameter displayed in the user settings of the report:
//	If the type of ID is(New usersenastroykid) = Type("Custom setups of Data components") Then
//		Full Data objectName = "";
//		For Each Cd element From The New Userenastroykid.Elements of the Cycle
//			If the type of ID is (CD element) = Type("Parameter setter values") Then
//				Parameter Name = String(element).Parameter);
//				If Parameter Name = "Data objectmethod" Then
//					Full Data objectName = Data element.Value;
//				The end if;
//			The end if;
//		The end of the cycle;
//		If the Schema key <> is the full Data objectName, then
//			Schema Key = Full Data objectname;
//			Schemacd = New schemacomposedata;
//			Filling in the schema...
//			Server report.Connect a schema(This is an Object, Context, Schema, Schema Key);
//		The end if;
//	The end if;
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	ReportSettings = SettingsComposer.GetSettings();
	PeriodParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Period");
	LoggerParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Recorder");
	
	If ValueIsFilled(LoggerParameter.Value) Then
		DataCompositionClientServer.SetParameter(NewDCSettings, "Period",
			Common.ObjectAttributeValue(LoggerParameter.Value, "Date"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateReport(SpreadsheetDocument, ProvisionObject, Period, ThereIsDataToDisplay) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Clear();
	
	DCSDecryption = GetTemplate("DrilldownTemplate");
	
	DecryptionSettingsComposer = New DataCompositionSettingsComposer();
	DecryptionSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSDecryption));
	DecryptionSettingsComposer.LoadSettings(DCSDecryption.DefaultSettings);
	ReportSettings = DecryptionSettingsComposer.GetSettings();
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ProvisionObject"));
	If Parameter <> Undefined Then
		Parameter.Value = ProvisionObject;
		Parameter.Use = True;
	EndIf;
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Period"));
	If Parameter <> Undefined Then
		Parameter.Value = Period;
		Parameter.Use = True;
	EndIf;
	
	ESDDetails = Common.ObjectAttributesValues(ProvisionObject, "Organization, ReserveKind");
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Organization"));
	If Parameter <> Undefined Then
		Parameter.Value = ESDDetails.Organization;
		Parameter.Use = True;
	EndIf;
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ReserveKind"));
	If Parameter <> Undefined Then
		Parameter.Value = ESDDetails.ReserveKind;
		Parameter.Use = True;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DCSDecryption, ReportSettings);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,,, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(SpreadsheetDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	ThereIsDataToDisplay = SpreadsheetDocument.TableHeight <> 0;
	
EndProcedure

#EndRegion

#EndIf
