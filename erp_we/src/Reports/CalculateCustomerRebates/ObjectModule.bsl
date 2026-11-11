//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	SetPrivilegedMode(True);
	
	ReportSettingsInForm = SettingsComposer.GetSettings();
	DocumentTermsOfRetroBonuses = DocumentOfAdditionalPropertiesOrParameters(ReportSettingsInForm);
	
	If Not ValueIsFilled(DocumentTermsOfRetroBonuses) Then
		Return;
	EndIf;
	
	AttributesValues = ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses);
	Cancel = False;
	RebatesCalculation.CheckAttributesOfConditions(AttributesValues, Cancel, True);
	
	If AttributesValues.Patch = True Then
		SourceDocument_ = AttributesValues.CorrectedDocument; // DocumentRef.ConditionsOfCustomerRebates
	Else
		SourceDocument_ = DocumentTermsOfRetroBonuses;
	EndIf;
	DataCompositionClientServer.SetParameter(ReportSettingsInForm, "SourceDocument_", SourceDocument_);
	
	RebateConditionsParameters = RebatesCalculation.ParametersOfTermsOfRebatesForCustomers(SourceDocument_);
	
	DocumentAccrual = Documents.AccrualOfCustomerRebates.EmptyRef();
	ReportSettingsInForm.AdditionalProperties.Property("DocumentAccrualOfRetroBonuses", DocumentAccrual);
	If ValueIsFilled(DocumentAccrual) Then
		
		Cancel = False;
		AccrualAttributes = ValuesOfDetailsOfAccrualDocument(DocumentAccrual);
		CheckAccrualAttributes(RebateConditionsParameters, AccrualAttributes, Cancel, True);
		
	EndIf;
	
	AdditionalProperties = SettingsComposer.UserSettings.AdditionalProperties;
	
	FirstLayoutWhenOpened = CommonClientServer.StructureProperty(
		AdditionalProperties, "FirstLayoutWhenOpened", False);
	
	OptionParameters = OptionParameters(ReportSettingsInForm, SettingsComposer);
	
	PreviousParametersOfConditionsForRebates = CommonClientServer.StructureProperty(
		AdditionalProperties, "RebateConditionsParameters", RebateConditionsParameters); // Structure
	If FirstLayoutWhenOpened Then
		PreviousParametersOfConditionsForRebates = RebateConditionsParameters;
	EndIf;
	ConditionParametersHaveChanged = RebatesCalculation.ParametersOfRebatesConditionsHaveChanged(
		PreviousParametersOfConditionsForRebates, RebateConditionsParameters);
	If ConditionParametersHaveChanged
	   And OptionParameters.OptionIsModifiedByUser Then
		
		Raise NStr("vi = 'Đã thay đổi mục tin của chứng từ điều kiện thưởng lũy kế. Để cập nhật tùy chọn và tùy chỉnh, cần mở lại báo cáo.';
					|ru = 'Изменились реквизиты документа условий ретро-бонусов. Для актуализации варианта и настроек необходимо открыть отчет заново.';
					|en = 'Attributes of the rebate condition document changed. To update the option and settings, open the report again.'; fa = 'Attributes of the rebate condition document changed. To update the option and settings, open the report again.';
					|it = 'Изменились реквизиты документа условий ретро-бонусов. Для актуализации варианта и настроек необходимо открыть отчет заново.';
					|pl = 'Attributes of the rebate condition document changed. To update the option and settings, open the report again.';
					|tr = 'Retro-bonus koşulları belgesinin ayrıntıları değişmiştir. Varyantı ve ayarları güncellemek için raporu yeniden açmanız gerekir.'");
		
	EndIf;
	
	MeasurementParameters = PerformanceMeasurementParameters(OptionParameters);
	If MeasurementParameters.ShouldRecord Then
		Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(MeasurementParameters.KeyOperation);
	EndIf;
	
	If FirstLayoutWhenOpened
	 Or ConditionParametersHaveChanged Then
		
		ComposerOfSettingsByOption = New DataCompositionSettingsComposer;
		ConfigureDataLayoutScheme(
			RebateConditionsParameters,
			DataCompositionSchema,
			ComposerOfSettingsByOption,
			ReportSettingsInForm,
			OptionParameters);
		ReportSettings = ComposerOfSettingsByOption.GetSettings();
		
		RebatesCalculation.TransferUsedSelections(ReportSettings, ReportSettingsInForm);
		RebatesCalculation.SaveParametersOfRebatesTermsAndConditions(RebateConditionsParameters, AdditionalProperties);
		
	Else
		
		ReportSettings = SettingsComposer.GetSettings();
		
		// To fill in the flags in the parameter of the variant
		VersionOfConditionsReport(RebateConditionsParameters, OptionParameters);
		
	EndIf;
	
	QueryText = Reports.CalculateCustomerRebates.QueryText(RebateConditionsParameters, OptionParameters);
	DataCompositionSchema.DataSets.CalculateCustomerRebates.Query = QueryText;
	
	DataCompositionClientServer.FillInElements(
		ReportSettings.DataParameters,
		ReportSettingsInForm.DataParameters);
	
	If OptionParameters.ThisIsTheTranscript Then
		
		// for decryption, the period is always equal to the period of the original report
		StartDateParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, "StartDate");
		EndDateParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, "EndDate");
		ReportPeriod = New StandardPeriod(StartDateParameter.Value, EndDateParameter.Value);
		
		DecryptionCounterpartyParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, "Counterparty");
		DecryptionCounterparty = DecryptionCounterpartyParameter.Value;
		If TypeOf(DecryptionCounterparty) = Type("Structure") Then
			DataCompositionClientServer.SetParameter(
				ReportSettings, "Counterparty", DecryptionCounterparty.RightValue, True);
		EndIf;
		DataCompositionClientServer.GetParameter(ReportSettings, "Counterparty").Use = True;
		
		DecryptionPartnerParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, "Partner");
		DecryptionPartner = DecryptionPartnerParameter.Value;
		If TypeOf(DecryptionPartner) = Type("Structure") Then
			DataCompositionClientServer.SetParameter(
				ReportSettings, "Partner", DecryptionPartner.RightValue, True);
		EndIf;
		DataCompositionClientServer.GetParameter(ReportSettings, "Partner").Use = True;
		
	Else
		
		ReportPeriodParameter = DataCompositionClientServer.GetParameter(
			SettingsComposer.UserSettings,
			"ReportPeriod");
		ReportPeriod = ReportPeriodParameter.Value; // StandardPeriod
		
		RebatesCalculation.CheckCorrectReportPeriod(ReportPeriod, RebateConditionsParameters);
		
	EndIf;
	
	DataCompositionClientServer.SetParameter(
		SettingsComposer.UserSettings, "ReportPeriod", ReportPeriod);
	
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ReportPeriod", ReportPeriod);
	
	DataCompositionClientServer.SetParameter(
		ReportSettings, "StartDate", ReportPeriod.StartDate);
	
	DataCompositionClientServer.SetParameter(
		ReportSettings, "EndDate", EndOfDay(ReportPeriod.EndDate));
	
	CompaniesList = New ValueList(); // ValueList of CatalogRef.Companies
	CompaniesList.Add(RebateConditionsParameters.Organization);
	DataCompositionClientServer.SetParameter(
		ReportSettings, "Organization", CompaniesList);
	
	ExcludedBusinessOfOperations = Reports.CalculateCustomerRebates.ExcludedBusinessOfOperations();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedBusinessOfOperations", ExcludedBusinessOfOperations);
	
	ExcludedSettingsOfBTransaction = Reports.CalculateCustomerRebates.ExcludedSettingsOfBusinessTransaction();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedSettingsOfBusinessTransaction", ExcludedSettingsOfBTransaction);
	
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ProductItemProperty", RebateConditionsParameters.ItemItemPropertyLink);
	
	If FirstLayoutWhenOpened
	 Or ConditionParametersHaveChanged Then
		
		SettingsComposer.LoadSettings(ReportSettings);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		AdditionalProperties.Insert("VariantModified", True);
		AdditionalProperties.Insert("UserSettingsModified", True);
		If ConditionParametersHaveChanged Then
			AdditionalProperties.Insert("FirstLayoutWhenOpened", True);
		EndIf;
		
	EndIf;
	
	KeyOfDecryptionOptionByItem = KeyOfDecryptionOptionByItem(RebateConditionsParameters);
	AdditionalProperties.Insert("KeyOfDecryptionOptionByItem", KeyOfDecryptionOptionByItem);
	KeyOfDecryptionOptionForDocuments = KeyOfDecryptionOptionForDocuments(RebateConditionsParameters);
	AdditionalProperties.Insert("KeyOfDecryptionOptionForDocuments", KeyOfDecryptionOptionForDocuments);
	
	// At the time of generation, we enable the availability of service parameters for output to the report header
	InternalParameters = NamesOfServiceParameters();
	For Each ParameterName In InternalParameters Do
		DataCompositionSchema.Parameters[ParameterName].UseRestriction = False;
	EndDo;
	
	If MeasurementParameters.ShouldRecord Then
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 0, "Setting");
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	DetailsData = New DataCompositionDetailsData;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	
	TempTableManager = ExternalTempTablesForReport(SourceDocument_, RebateConditionsParameters, Measurement);
	
	If MeasurementParameters.ShouldRecord Then
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 0, "DataPreparation");
	EndIf;
	
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True,, TempTableManager);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// disabling the availability of service parameters to hide settings from the form
	For Each ParameterName In InternalParameters Do
		DataCompositionSchema.Parameters[ParameterName].UseRestriction = True;
	EndDo;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
	If MeasurementParameters.ShouldRecord Then
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(
			Measurement, ResultDocument.TableHeight / MeasurementParameters.Divisor, "Layout");
	EndIf;
	
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
	Settings.EditStructureAllowed = True;
	Settings.SelectAndEditOptionsWithoutSavingAllowed = True;
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - See CommonForm.ReportForm
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
	OptionsForDecodingDocuments = NamesOfDecryptionOptionsForDocuments();
	DecryptionOptionsByItem = NamesOfTranscriptOptionsByNomenclature();
	CurrentVariantKey = Form.CurrentVariantKey; // String
	ThisIsTheTranscript = (OptionsForDecodingDocuments.Find(CurrentVariantKey) <> Undefined)
		Or (DecryptionOptionsByItem.Find(CurrentVariantKey) <> Undefined);
	
	If Not Parameters.Property("CommandParameter")
	   And Not Form.DetailsMode
	   And Not ThisIsTheTranscript Then
		
		Cancel = True;
		DocumentSynonym = Metadata.Documents.ConditionsOfCustomerRebates.Synonym;
		ErrorTemplate = NStr("vi = 'Báo cáo được sử dụng chỉ để mở từ chứng từ ""%1"".';
							|ru = 'Отчет предназначен только для открытия из документа ""%1"".';
							|en = 'The report is used only to be opened from the ""%1"" document.'; fa = 'The report is used only to be opened from the ""%1"" document.';
							|it = 'Отчет предназначен только для открытия из документа ""%1"".';
							|pl = 'The report is used only to be opened from the ""%1"" document.';
							|tr = 'Raporun yalnızca ""%1"" belgesinde açılması amaçlandı.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, DocumentSynonym);
		Raise ErrorText;
		
	EndIf;
	
	// We put the parameters in the Attributes of the report form
	FormDetailsToAdd = New Array(); // Array of FormAttribute
	
	TypeLinkToConditionsDocument = New TypeDescription("DocumentRef.ConditionsOfCustomerRebates");
	TermsAndConditionsAttributeDocument = New FormAttribute("DocumentTermsOfRetroBonuses", TypeLinkToConditionsDocument);
	FormDetailsToAdd.Add(TermsAndConditionsAttributeDocument);
	
	TypeDocumentLinkAccrual = New TypeDescription("DocumentRef.AccrualOfCustomerRebates");
	AttributeDocumentAccrual = New FormAttribute("DocumentAccrualOfRetroBonuses", TypeDocumentLinkAccrual);
	FormDetailsToAdd.Add(AttributeDocumentAccrual);
	
	AttributesLinkToDocument = New FormAttribute("ClearUserSettingsPeriod", New TypeDescription("Boolean"));
	FormDetailsToAdd.Add(AttributesLinkToDocument);
	
	AttributeIsFirstLayoutWhenOpened = New FormAttribute("FirstLayoutWhenOpened", New TypeDescription("Boolean"));
	FormDetailsToAdd.Add(AttributeIsFirstLayoutWhenOpened);
	
	Form.ChangeAttributes(FormDetailsToAdd);
	
	CommonClientServer.SetFormAttributeByPath(Form, "FirstLayoutWhenOpened", True);
	
	If Parameters.Property("CommandParameter") Then
		
		DocumentAccrual = Documents.AccrualOfCustomerRebates.EmptyRef();
		ParameterType = TypeOf(Parameters.CommandParameter);
		If ParameterType = Type("DocumentRef.ConditionsOfCustomerRebates") Then
			
			DocumentTermsOfRetroBonuses = Parameters.CommandParameter; // DocumentRef.ConditionsOfCustomerRebates
			
		ElsIf ParameterType = Type("DocumentRef.AccrualOfCustomerRebates") Then
			
			DocumentAccrual = Parameters.CommandParameter; // DocumentRef.AccrualOfCustomerRebates
			CommonClientServer.SetFormAttributeByPath(
				Form, "DocumentAccrualOfRetroBonuses", DocumentAccrual);
			AccrualAttributes = ValuesOfDetailsOfAccrualDocument(DocumentAccrual);
			DocumentTermsOfRetroBonuses = AccrualAttributes.TermDocument;
			
		Else
			
			ErrorTemplate = NStr("vi = 'Sai kiểu tham số lệnh ""%1""';
								|ru = 'Некорректный тип параметра команды ""%1""';
								|en = 'Incorrect parameter type of the ""%1"" command'; fa = 'Incorrect parameter type of the ""%1"" command';
								|it = 'Некорректный тип параметра команды ""%1""';
								|pl = 'Incorrect parameter type of the ""%1"" command';
								|tr = '“%1” komut parametresinin yanlış türü'");
			ParameterTypeAsString = String(ParameterType);
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ParameterTypeAsString);
			Raise ErrorText;
			
		EndIf;
		
		CommonClientServer.SetFormAttributeByPath(
			Form, "ClearUserSettingsPeriod", True);
		
		AttributesValues = ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses);
		RebatesCalculation.CheckAttributesOfConditions(AttributesValues, Cancel);
		
		If ValueIsFilled(DocumentAccrual) Then
			
			If AttributesValues.Patch = True Then
				SourceDocument_ = AttributesValues.CorrectedDocument;
			Else
				SourceDocument_ = DocumentTermsOfRetroBonuses;
			EndIf;
			ConditionParameters_ = RebatesCalculation.ParametersOfTermsOfRebatesForCustomers(SourceDocument_);
			CheckAccrualAttributes(ConditionParameters_, AccrualAttributes, Cancel);
			
			VariantKey = KeyOfDecryptionOptionByItem(ConditionParameters_);
			CommonClientServer.SetFormAttributeByPath(Form, "CurrentVariantKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(Form, "Parameters.VariantKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(Form, "ReportSettings.PredefinedOptionKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(Form, "ParametersForm.InitialOptionKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(Form, "ParametersForm.InitialKeyOfPredefinedOption", VariantKey);
			
			Filter = New Structure;
			Filter.Insert("Organization", AccrualAttributes.Organization);
			Filter.Insert("Currency", AccrualAttributes.Currency);
			Filter.Insert("StartDate", AccrualAttributes.BeginOfPeriod);
			Filter.Insert("EndDate", AccrualAttributes.PeriodEnding);
			If ValueIsFilled(AccrualAttributes.Counterparty) Then
				Filter.Insert("Counterparty", AccrualAttributes.Counterparty);
			EndIf;
			If ValueIsFilled(AccrualAttributes.Partner) Then
				Filter.Insert("Partner", AccrualAttributes.Partner);
			EndIf;
			CommonClientServer.SetFormAttributeByPath(Form, "ParametersForm.Filter", Filter);
			
		EndIf;
		
	ElsIf Form.DetailsMode Then
		
		DetailsData = GetFromTempStorage(Form.Parameters.Details.Data); // DataCompositionDetailsData
		ConditionsDocumentParameter = DataCompositionClientServer.GetParameter(
			DetailsData.Settings, "DocumentTermsOfRetroBonuses");
		DocumentTermsOfRetroBonuses = ConditionsDocumentParameter.Value; // DocumentRef.ConditionsOfCustomerRebates
		
	ElsIf ThisIsTheTranscript Then
		
		DocumentTermsOfRetroBonuses = Form.ParametersForm.Filter.DocumentTermsOfRetroBonuses; // DocumentRef.ConditionsOfCustomerRebates
		
	EndIf;
	
	CommonClientServer.SetFormAttributeByPath(
		Form, "DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
	
	// Disabling user accessibility of decryption parameters in the main options
	
	If Not ThisIsTheTranscript Then
		
		ParameterNames = NamesOfDecryptionParameters();
		For Each ParameterName In ParameterNames Do
			DataCompositionSchema.Parameters[ParameterName].UseRestriction = True;
		EndDo;
		
		ValueToFormData(ThisObject, Form.Report);
		
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - Settings to upload to the Settings Composer.
//
// See also:
//   "Managed Form Extension for Report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	DocumentTermsOfRetroBonuses = CommonClientServer.GetFormAttributeByPath(
		Form, "DocumentTermsOfRetroBonuses");
	NewDCSettings.AdditionalProperties.Insert("DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
	
	DocumentAccrual = CommonClientServer.GetFormAttributeByPath(
		Form, "DocumentAccrualOfRetroBonuses");
	NewDCSettings.AdditionalProperties.Insert("DocumentAccrualOfRetroBonuses", DocumentAccrual);
	
	DetailsMode = CommonClientServer.GetFormAttributeByPath(
		Form, "DetailsMode");
	NewDCSettings.AdditionalProperties.Insert("DetailsMode", DetailsMode);
	
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
	
	OptionParameters = OptionParameters(NewDCSettings, SettingsComposer);
	
	If TypeOf(Context) = Type("ClientApplicationForm")
	   And Context.ReportFormType = ReportFormType.Main Then
		
		FirstLayoutWhenOpened = CommonClientServer.GetFormAttributeByPath(
			Context, "FirstLayoutWhenOpened");
		If FirstLayoutWhenOpened = True Then
			NewDCUserSettings.AdditionalProperties.Insert("FirstLayoutWhenOpened", FirstLayoutWhenOpened);
		EndIf;
		
		DocumentTermsOfRetroBonuses = CommonClientServer.GetFormAttributeByPath(
			Context, "DocumentTermsOfRetroBonuses"); // DocumentRef.ConditionsOfCustomerRebates
		
		If Not OptionParameters.DetailsMode Then
			
			AttributesValues = ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses);
			If AttributesValues.Patch = True Then
				SourceDocument_ = AttributesValues.CorrectedDocument; // DocumentRef.ConditionsOfCustomerRebates
			Else
				SourceDocument_ = DocumentTermsOfRetroBonuses;
			EndIf;
			RebateConditionsParameters = RebatesCalculation.ParametersOfTermsOfRebatesForCustomers(SourceDocument_);
		
			ColumnHeaders = ColumnHeaders(RebateConditionsParameters);
			DatasetFields = DataCompositionSchema.DataSets.Find("CalculateCustomerRebates").Fields;
			RebatesCalculation.ConfigureDataSetColumnHeaders(DatasetFields, ColumnHeaders);
			
			RebatesCalculation.ConfigureFormatOfPropertyValue(DatasetFields, RebateConditionsParameters);
			
		EndIf;
		
		// For a contextual report, we clear the period saved in the user settings, fill it in according to the conditions of the Republic of Belarus 
		
		ClearUserSettingsPeriod = CommonClientServer.GetFormAttributeByPath(
			Context, "ClearUserSettingsPeriod");
		Contextual = CommonClientServer.GetFormAttributeByPath(
			Context, "ReportSettings.Contextual");
		
		If Contextual
		   And ClearUserSettingsPeriod Then
			
			DateEmpty = '00010101';
			
			ReportPeriod = New StandardPeriod;
			ReportPeriod.StartDate = DateEmpty;
			ReportPeriod.EndDate = DateEmpty;
			
			DataCompositionClientServer.SetParameter(
				NewDCUserSettings,
				"ReportPeriod",
				ReportPeriod,
				True);
			
			CommonClientServer.SetFormAttributeByPath(
				Context, "ClearUserSettingsPeriod", False);
			
		EndIf;
		
		// We remove the original selections by partner/counterparty from the form parameters, otherwise they overwrite the user settings
		
		If Not FirstLayoutWhenOpened Then
			
			ParameterNames = NamesOfDecryptionParameters();
			ParameterNames.Add("Currency");
			
			For Each ParameterName In ParameterNames Do
				
				If Context.ParametersForm.Filter.Property(ParameterName) Then
					Context.ParametersForm.Filter.Delete(ParameterName);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		// Collapsing the grouping level by ranges
		
		If OptionParameters.VariantKey = "DecodingByNomenclatureByRangesByLines" Then
			
			Variant = DataCompositionSchema.SettingVariants[OptionParameters.VariantKey];
			LevelOfRangeDimensions = RebatesCalculation.LevelOfGroupingByRanges(Variant);
			If LevelOfRangeDimensions <> Undefined Then
				
				CommonClientServer.SetFormAttributeByPath(
					Context, "SelectedGroupsLevel", LevelOfRangeDimensions);
				
			EndIf;
			
		EndIf;
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
	EndIf;
	
	// disabling user selection by counterparty and partner in decryption
	
	If OptionParameters.ThisIsTheTranscript Then
		
		CounterpartyLayoutField = New DataCompositionField("Counterparty");
		PartnerLayoutField = New DataCompositionField("Partner");
		
		For Each Item In NewDCSettings.Filter.Items Do
			
			If Item.LeftValue = PartnerLayoutField
			 Or Item.LeftValue = CounterpartyLayoutField Then
				
				Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
				
				SettingID = Item.UserSettingID;
				Filter = NewDCUserSettings.Items.Find(SettingID);
				If Filter <> Undefined Then
					
					Filter.Use = False;
					Filter.RightValue = Undefined;
					Filter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// disabling the user setting of the period in the decryption
	
	If OptionParameters.ThisIsTheTranscript
	 Or OptionParameters.DetailsMode = True Then
		
		PeriodParameter = DataCompositionClientServer.GetParameter(NewDCSettings, "ReportPeriod");
		If PeriodParameter <> Undefined Then
			PeriodParameter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		
		PeriodParameter = DataCompositionClientServer.GetParameter(NewDCUserSettings, "ReportPeriod");
		If PeriodParameter <> Undefined Then
			PeriodParameter.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function DocumentOfAdditionalPropertiesOrParameters(ReportSettingsInForm)
	
	DocumentTermsOfRetroBonuses = Documents.ConditionsOfCustomerRebates.EmptyRef();
	DataParameter = Undefined;
	ReportSettingsInForm.AdditionalProperties.Property("DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
	
	If DocumentTermsOfRetroBonuses <> Undefined
	   And Not DocumentTermsOfRetroBonuses.IsEmpty() Then
		
		DataCompositionClientServer.SetParameter(
			ReportSettingsInForm, "DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
		
	Else
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("DocumentTermsOfRetroBonuses");
		
	EndIf;
	
	If DataParameter <> Undefined Then
		
		DocumentTermsOfRetroBonuses = DataParameter.Value; // DocumentRef.ConditionsOfCustomerRebates
		
	EndIf;
	
	Return DocumentTermsOfRetroBonuses;
	
EndFunction

Function ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses)
	
	Attributes = "Posted, WithoutCalculation, Status, Patch, CorrectedDocument";
	AttributesValues = Common.ObjectAttributesValues(DocumentTermsOfRetroBonuses, Attributes);
	Return AttributesValues;
	
EndFunction

Function ValuesOfDetailsOfAccrualDocument(DocumentAccrual)
	
	Attributes = "Posted, TermDocument, Organization, Counterparty, Partner, BeginOfPeriod, PeriodEnding, Currency";
	AttributesValues = Common.ObjectAttributesValues(DocumentAccrual, Attributes);
	Return AttributesValues;
	
EndFunction

Function OptionParameters(ReportSettingsInForm, Var_SettingsComposer)
	
	OptionParameters = RebatesCalculation.NewOptionParameters();
	VariantKey = ReportSettingsInForm.AdditionalProperties.VariantKey; // String
	OptionParameters.VariantKey = VariantKey;
	
	OptionsForDecodingDocuments = NamesOfDecryptionOptionsForDocuments();
	DecryptionOptionsByItem = NamesOfTranscriptOptionsByNomenclature();
	
	OptionParameters.ThisIsTranscriptOfDocuments = (OptionsForDecodingDocuments.Find(VariantKey) <> Undefined);
	OptionParameters.ThisIsTranscriptOfNomenclature = (DecryptionOptionsByItem.Find(VariantKey) <> Undefined);
	OptionParameters.ThisIsTheTranscript = (OptionParameters.ThisIsTranscriptOfNomenclature
		Or OptionParameters.ThisIsTranscriptOfDocuments);
	
	OptionParameters.DetailsMode = CommonClientServer.StructureProperty(
		ReportSettingsInForm.AdditionalProperties, "DetailsMode", False);
		
	If OptionParameters.DetailsMode Then
		
		For Each StructureItem In ReportSettingsInForm.Structure Do
			
			If TypeOf(StructureItem) <> Type("DataCompositionGroup") Then
				Continue;
			EndIf;
			
			For Each GroupingField In StructureItem.GroupFields.Items Do
				OptionParameters.DecryptionFields.Add(GroupingField.Field);
			EndDo;
			
		EndDo;
		
	EndIf;
	
	OptionParameters.OptionIsModifiedByUser = (CommonClientServer.StructureProperty(
		Var_SettingsComposer.UserSettings.AdditionalProperties, "VariantModified", False)
		Or CommonClientServer.StructureProperty(
		Var_SettingsComposer.UserSettings.AdditionalProperties, "UserSettingsModified", False));
	
	Return OptionParameters;
	
EndFunction

Function NamesOfDecryptionOptionsForDocuments()
	
	OptionsForDecodingDocuments = New Array; // Array of String
	OptionsForDecodingDocuments.Add("DecryptionOfDocuments");
	Return OptionsForDecodingDocuments;
	
EndFunction

Function NamesOfTranscriptOptionsByNomenclature()
	
	DecryptionOptionsByItem = New Array; // Array of String
	DecryptionOptionsByItem.Add("DecodingByNomenclature");
	DecryptionOptionsByItem.Add("DecodingByNomenclatureByRangesInTable");
	DecryptionOptionsByItem.Add("DecodingByNomenclatureByRangesByLines");
	Return DecryptionOptionsByItem;
	
EndFunction

Function ReportHeader(RebateConditionsParameters)
	
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	PartyCountDetailsPresentation = String(PartyCountDetails);
	TypesOfDetailingCalculationOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCustomer Then
		
		ReportHeader = NStr("vi = 'Tính thưởng lũy kế cho khách hàng (theo khách hàng)';
							|ru = 'Расчет ретро-бонусов клиентов (по клиенту)';
							|en = 'Calculate customer rebates (by customer)'; fa = 'Calculate customer rebates (by customer)';
							|it = 'Расчет ретро-бонусов клиентов (по клиенту)';
							|pl = 'Calculate customer rebates (by customer)';
							|tr = 'Müşterilerin retro-bonuslarının hesaplanması (müşteriye göre)'");
		
	ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterparty Then
		
		ReportHeader = NStr("vi = 'Tính thưởng lũy kế cho khách hàng (theo đối tác)';
							|ru = 'Расчет ретро-бонусов клиентов (по контрагенту)';
							|en = 'Calculate customer rebates (by counterparty)'; fa = 'Calculate customer rebates (by counterparty)';
							|it = 'Расчет ретро-бонусов клиентов (по контрагенту)';
							|pl = 'Calculate customer rebates (by counterparty)';
							|tr = 'Müşterilerin retro-bonusların hesaplanması (cari hesaba göre)'");
		
	ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterpartyAndCustomer Then
		
		ReportHeader = NStr("vi = 'Tính thưởng lũy kế cho khách hàng (theo đối tác và khách hàng)';
							|ru = 'Расчет ретро-бонусов клиентов (по контрагенту и клиенту)';
							|en = 'Calculate customer rebates (by counterparty and customer)'; fa = 'محاسبه تخفیف‌های حجمی مشتری (بر اساس طرف حساب و مشتری)';
							|it = 'Расчет ретро-бонусов клиентов (по контрагенту и клиенту)';
							|pl = 'Calculate customer rebates (by counterparty and customer)';
							|tr = 'Müşterilerin retro-bonuslarının hesaplanması (cari hesap ve müşteriye göre)'");
		
	Else
		
		ErrorTemplate = NStr("vi = 'Chi tiết hóa tính toán không xác định theo người tham gia ""%1"" đối với chứng từ ""%2""';
							|ru = 'Неизвестная детализация расчета по участникам ""%1"" для документа ""%2""';
							|en = 'Unknown ""%1"" AR/AP item by participants for the ""%2"" document'; fa = 'Unknown ""%1"" AR/AP item by participants for the ""%2"" document';
							|it = 'Неизвестная детализация расчета по участникам ""%1"" для документа ""%2""';
							|pl = 'Unknown ""%1"" AR/AP item by participants for the ""%2"" document';
							|tr = '“%2” belgesi için ""%1"" katılımcısı tarafından yapılan hesaplamanın bilinmeyen detayı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			PartyCountDetailsPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	Return ReportHeader;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesForCustomers
//  OptionParameters - See OptionParameters
// 
// Returns:
//  DataCompositionSettingsVariant
//  
Function VersionOfConditionsReport(RebateConditionsParameters, OptionParameters)
	
	ReportOptions = DataCompositionSchema.SettingVariants;
	
	If OptionParameters.ThisIsTranscriptOfNomenclature Then
		
		CompositeVersionOfReport = VariantOfDecodingByNomenclature(RebateConditionsParameters);
		OptionParameters.DetailingToItem = True;
		
	ElsIf OptionParameters.ThisIsTranscriptOfDocuments Then
		
		CompositeVersionOfReport = ReportOptions.DecryptionOfDocuments;
		
	Else
		
		CompositeVersionOfReport = ReportOptions.CalculationOfCustomerRebatesForPartnersCounterparties;
		
	EndIf;
	
	Return CompositeVersionOfReport;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesForCustomers
// 
// Returns:
//  DataCompositionSettingsVariant
//  
Function VariantOfDecodingByNomenclature(RebateConditionsParameters)
	
	ReportOptions = DataCompositionSchema.SettingVariants;
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
			CompositeVersionOfReport = ReportOptions.DecodingByNomenclatureByRangesInTable;
		Else
			CompositeVersionOfReport = ReportOptions.DecodingByNomenclatureByRangesByLines;
		EndIf;
		
	Else
		
		CompositeVersionOfReport = ReportOptions.DecodingByNomenclature;
		
	EndIf;
	
	Return CompositeVersionOfReport;
	
EndFunction

Procedure ConfigureDataLayoutScheme(RebateConditionsParameters, Var_DataCompositionSchema, ComposerOfSettingsByOption, ReportSettingsInForm, OptionParameters)
	
	CompositeVersionOfReport = VersionOfConditionsReport(RebateConditionsParameters, OptionParameters);
	
	ComposerOfSettingsByOption.LoadSettings(CompositeVersionOfReport.Settings);
	
	SourceOfAvailableCDSettings = New DataCompositionAvailableSettingsSource(Var_DataCompositionSchema);
	ComposerOfSettingsByOption.Initialize(SourceOfAvailableCDSettings);
	OutputParameters = ComposerOfSettingsByOption.Settings.OutputParameters;
	
	RebatesCalculation.ConfigureConditionalAppearanceOfReport(ComposerOfSettingsByOption.Settings.ConditionalAppearance);
	
	// transferring the set output parameters from the report settings in the form
	
	For Each DefaultOutputParameter In ReportSettingsInForm.OutputParameters.Items Do
		
		If Not DefaultOutputParameter.Use Then
			Continue;
		EndIf;
		
		OutputParameter = OutputParameters.FindParameterValue(DefaultOutputParameter.Parameter);
		If OutputParameter = Undefined Then
			Continue;
		EndIf;
		FillPropertyValues(OutputParameter, DefaultOutputParameter);
		
	EndDo;
	
	// transferring the structure setting from the form layout settings to the Cur settings
	
	If OptionParameters.OptionIsModifiedByUser
	 Or OptionParameters.DetailsMode Then
		
		ComposerOfSettingsByOption.Settings.Structure.Clear();
		For Each SourceGrouping In ReportSettingsInForm.Structure Do
			
			GroupingReceiver = DataCompositionClientServer.AddGrouping(ComposerOfSettingsByOption.Settings);
			DataCompositionClientServer.CopyDataLayoutSettings(GroupingReceiver, SourceGrouping);
			
		EndDo;
		
	EndIf;
	
	// setting up the title
	
	OutputParameter = OutputParameters.Items.Find("Title");
	If OptionParameters.ThisIsTheTranscript Then
		OutputParameter.Value = "";
		OutputParameter.Use = False;
	Else
		OutputParameter.Value = ReportHeader(RebateConditionsParameters);
		OutputParameter.Use = True;
	EndIf;
	
	AdjustColumnVisibility(RebateConditionsParameters, ComposerOfSettingsByOption, OptionParameters);
	
	ColumnHeaders = ColumnHeaders(RebateConditionsParameters);
	RebatesCalculation.CustomizeHeadersOfSelectedColumns(ComposerOfSettingsByOption.Settings, ColumnHeaders);
	DatasetFields = Var_DataCompositionSchema.DataSets.Find("CalculateCustomerRebates").Fields;
	RebatesCalculation.ConfigureDataSetColumnHeaders(DatasetFields, ColumnHeaders);
	
	RebatesCalculation.ConfigureFormatOfPropertyValue(DatasetFields, RebateConditionsParameters);
	
	// disabling totals for settlement in the currency of mutual settlements
	
	TypesOfSalesCalculationBase = Enums.RebateCalculationBases;
	If RebateConditionsParameters.BaseOfCalculation = TypesOfSalesCalculationBase.RevenueARAPAccounting Then
		
		VerticalOverallPlacement = OutputParameters.Items.Find("VerticalOverallPlacement");
		VerticalOverallPlacement.Value = DataCompositionTotalPlacement.None;
		VerticalOverallPlacement.Use = True;
		
	EndIf;
	
EndProcedure

Procedure AdjustColumnVisibility(RebateConditionsParameters, ComposerOfSettingsByOption, OptionParameters)
	
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	LineUpsOfParticipants = Enums.RebatesParticipants;
	SalesCalculationBase = RebateConditionsParameters.BaseOfCalculation;
	SalesCalculationBasePresentation = String(SalesCalculationBase);
	TypesOfSalesCalculationBase = Enums.RebateCalculationBases;
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	PartyCountDetailsPresentation = String(PartyCountDetails);
	TypesOfDetailingCalculationOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	ColumnsVisibility = New Structure;
	ColumnsVisibility.Insert("RevenueAmount", False);
	ColumnsVisibility.Insert("RevenueAmountExcludingVAT", False);
	ColumnsVisibility.Insert("AmountInBasePrices", False);
	ColumnsVisibility.Insert("SumPlan", False);
	ColumnsVisibility.Insert("CountPlan", False);
	ColumnsVisibility.Insert("BasePrice", False);
	ColumnsVisibility.Insert("PackagesSold", False);
	ColumnsVisibility.Insert("Contract", False);
	ColumnsVisibility.Insert("Terms", False);
	ColumnsVisibility.Insert("RangeFrom", False);
	ColumnsVisibility.Insert("RangeBy", False);
	ColumnsVisibility.Insert("Counterparty", False);
	ColumnsVisibility.Insert("Partner", False);
	ColumnsVisibility.Insert("Products", False);
	ColumnsVisibility.Insert("Characteristic", False);
	ColumnsVisibility.Insert("UnitOfMeasure", False);
	ColumnsVisibility.Insert("PropertyValue", False);
	
	If SalesCalculationBase = TypesOfSalesCalculationBase.RevenueManagementAccounting
	 Or SalesCalculationBase = TypesOfSalesCalculationBase.RevenueLocalAccounting
	 Or SalesCalculationBase = TypesOfSalesCalculationBase.RevenueARAPAccounting Then
		
		If RebateConditionsParameters.ConsiderVAT Then
			ColumnsVisibility.RevenueAmount = True;
		Else
			ColumnsVisibility.RevenueAmountExcludingVAT = True;
		EndIf;
		
	ElsIf SalesCalculationBase = TypesOfSalesCalculationBase.RevenueBasePrices Then
		
		ColumnsVisibility.AmountInBasePrices = True;
		ColumnsVisibility.BasePrice = True;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Cơ sở tính toán doanh thu không xác định ""%1"" đối với chứng từ ""%2""';
							|ru = 'Неизвестная база расчета продаж ""%1"" для документа ""%2""';
							|en = 'Unknown ""%1"" sales calculation base for the ""%2"" document'; fa = 'Unknown ""%1"" sales calculation base for the ""%2"" document';
							|it = 'Неизвестная база расчета продаж ""%1"" для документа ""%2""';
							|pl = 'Unknown ""%1"" sales calculation base for the ""%2"" document';
							|tr = '“%2” belgesi için bilinmeyen satış hesaplama tabanı ”%1”'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			SalesCalculationBasePresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
		
		NumberOfCalculationPeriods = RebatesCalculation.NumberOfCalculationPeriods(
			RebateConditionsParameters.ValidOnDate,
			RebateConditionsParameters.ValidTo,
			RebateConditionsParameters.ConditionFrequency);
		
		ColumnsVisibility.SumPlan = (Not RebateConditionsParameters.CalculationScaleByRanges
			And (Not RebateConditionsParameters.ProgressiveCalculationScale
				Or OptionParameters.ThisIsTranscriptOfNomenclature
				Or NumberOfCalculationPeriods <= 1));
		
	ElsIf RebateConditionsParameters.GoodsIndicator = TargetValues.Count
	      Or RebateConditionsParameters.GoodsIndicator = TargetValues.QuantityTotal
	      Or RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer Then
		
		ColumnsVisibility.CountPlan = True;
		
	EndIf;
	
	If RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer Then
		ColumnsVisibility.PackagesSold = True;
	EndIf;
	
	If RebateConditionsParameters.PartyList = LineUpsOfParticipants.Contracts Then
		ColumnsVisibility.Contract = True;
	EndIf;
	If RebateConditionsParameters.PartyList = LineUpsOfParticipants.Terms1 Then
		ColumnsVisibility.Terms = True;
	EndIf;
	
	If PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCustomer Then
		
		ColumnsVisibility.Partner = True;
		
	ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterparty Then
		
		ColumnsVisibility.Counterparty = True;
		
	ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterpartyAndCustomer Then
		
		ColumnsVisibility.Partner = True;
		ColumnsVisibility.Counterparty = True;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Chi tiết hóa tính toán không xác định theo người tham gia ""%1"" đối với chứng từ ""%2""';
							|ru = 'Неизвестная детализация расчета по участникам ""%1"" для документа ""%2""';
							|en = 'Unknown ""%1"" AR/AP item by participants for the ""%2"" document'; fa = 'Unknown ""%1"" AR/AP item by participants for the ""%2"" document';
							|it = 'Неизвестная детализация расчета по участникам ""%1"" для документа ""%2""';
							|pl = 'Unknown ""%1"" AR/AP item by participants for the ""%2"" document';
							|tr = '“%2” belgesi için ""%1"" katılımcısı tarafından yapılan hesaplamanın bilinmeyen detayı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			PartyCountDetailsPresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	ColumnsVisibility.RangeFrom = RebateConditionsParameters.CalculationScaleByRanges;
	ColumnsVisibility.RangeBy = RebateConditionsParameters.CalculationScaleByRanges;
	
	If RebateConditionsParameters.CalculationByProperties
	   And RebateConditionsParameters.Goods = Enums.RebatesLists.Selected_ Then
		
		ColumnsVisibility.Products = False;
		ColumnsVisibility.Characteristic = False;
		ColumnsVisibility.UnitOfMeasure = False;
		ColumnsVisibility.PropertyValue = True;
		
	Else
		
		ColumnsVisibility.Products = True;
		ColumnsVisibility.Characteristic = True;
		ColumnsVisibility.UnitOfMeasure = True;
		ColumnsVisibility.PropertyValue = False;
		
	EndIf;
	
	For Each ColumnVisibilityElement In ColumnsVisibility Do
		
		If ColumnVisibilityElement.Value Then
			Continue;
		EndIf;
		
		LayoutField = New DataCompositionField(ColumnVisibilityElement.Key);
		
		If RebatesCalculation.ThisIsDecryptionField(OptionParameters, LayoutField) Then
			Continue;
		EndIf;
		
		RebatesCalculation.DisableUseOfSelectedField(ComposerOfSettingsByOption.Settings.Selection.Items, LayoutField);
		For Each SettingsStructure In ComposerOfSettingsByOption.Settings.Structure Do
			RebatesCalculation.DisableUseOfField(SettingsStructure, LayoutField);
		EndDo;
		
	EndDo;
	
EndProcedure

Function KeyOfDecryptionOptionByItem(RebateConditionsParameters)
	
	Variant = VariantOfDecodingByNomenclature(RebateConditionsParameters);
	VariantKey = Variant.Name;
	
	Return VariantKey;
	
EndFunction

Function KeyOfDecryptionOptionForDocuments(RebateConditionsParameters)
	
	VariantKey = "DecryptionOfDocuments";
	Return VariantKey;
	
EndFunction

Function ExternalTempTablesForReport(SourceDocument_, RebateConditionsParameters, Measurement)
	
	TempTableManager = Undefined;
	
	QueryTemplate =
	"SELECT
	|	*
	|INTO AssignmentTable
	|FROM
	|	&CompositionOfSegments AS CompositionOfSegments";
	
	If RebateConditionsParameters.ContentOfGoods = Enums.RebatesItems.ProductSegments
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		CompositionOfGoodsSegments = RebatesServer.CompositionOfGoodsSegments(SourceDocument_);
		Query = New Query;
		If TempTableManager = Undefined Then
			TempTableManager = New TempTablesManager();
		EndIf;
		Query.TempTablesManager = TempTableManager;
		Query.SetParameter("CompositionOfSegments", CompositionOfGoodsSegments);
		
		QueryText = QueryTemplate;
		QueryText = StrReplace(QueryText, "AssignmentTable", "TT_CompositionOfGoodsSegments");
		Query.Text = QueryText;
		
		Query.Execute();
		
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "GettingCompositionOfGoodsSegments");
		
	EndIf;
	
	If RebateConditionsParameters.PartyList = Enums.RebatesParticipants.PartnersSegments
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		CompositionOfCustomerSegments = RebatesServer.CompositionOfPartnerSegments(SourceDocument_);
		Query = New Query;
		If TempTableManager = Undefined Then
			TempTableManager = New TempTablesManager();
		EndIf;
		Query.TempTablesManager = TempTableManager;
		Query.SetParameter("CompositionOfSegments", CompositionOfCustomerSegments);
		
		QueryText = QueryTemplate;
		QueryText = StrReplace(QueryText, "AssignmentTable", "TT_CompositionOfCustomerSegments");
		Query.Text = QueryText;
		
		Query.Execute();
		
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "GettingCompositionOfPartnerSegments");
		
	EndIf;
	
	If RebateConditionsParameters.CalculationByProperties
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		QueryText = RebatesServer.QueryTextItemsByProperty(
			True, RebateConditionsParameters.ProductItemProperty, RebateConditionsParameters.ItemItemPropertyLink);
		
		Query = New Query;
		If TempTableManager = Undefined Then
			TempTableManager = New TempTablesManager();
		EndIf;
		Query.TempTablesManager = TempTableManager;
		Query.Text = QueryText;
		
		Query.SetParameter("SourceDocument_", SourceDocument_);
		Query.SetParameter("ProductItemProperty", RebateConditionsParameters.ItemItemPropertyLink);
		
		Query.Execute();
		
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "GettingCompositionOfItemsByProperty");
		
	EndIf;
	
	Return TempTableManager;
	
EndFunction

Procedure CheckAccrualAttributes(ConditionParameters_, AccrualAttributes, Cancel, RaiseException1 = False)
	
	MessageText = "";
	DetailsOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	CheckedAttributes = New Array; // Array of String
	CheckedAttributes.Add("TermDocument");
	CheckedAttributes.Add("Organization");
	CheckedAttributes.Add("BeginOfPeriod");
	CheckedAttributes.Add("PeriodEnding");
	CheckedAttributes.Add("Currency");
	
	If ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCustomer
	 Or ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCounterpartyAndCustomer Then
		CheckedAttributes.Add("Partner");
	EndIf;
	
	If ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCounterparty
	 Or ConditionParameters_.PartyCountDetails = DetailsOfParticipants.ByCounterpartyAndCustomer Then
		CheckedAttributes.Add("Counterparty");
	EndIf;
	
	ErrorTemplate = NStr("vi = 'Chưa điền trường ""%1""';
						|ru = 'Не заполнено поле ""%1""';
						|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
						|it = 'Не заполнено поле ""%1""';
						|pl = 'Nie wypełniono pola ""%1""';
						|tr = '""%1"" alanı doldurulmadı'");
	
	For Each AttributeToCheck In CheckedAttributes Do
		
		If ValueIsFilled(AccrualAttributes[AttributeToCheck]) Then
			Continue;
		EndIf;
		
		AttributeMetadata = Metadata.Documents.AccrualOfCustomerRebates.Attributes.Find(AttributeToCheck);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, AttributeMetadata.Synonym);
		
	EndDo;
	
	If ValueIsFilled(MessageText) Then
		
		If RaiseException1 Then
			Raise MessageText;
		Else
			Common.MessageToUser(MessageText,,,, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Function NamesOfServiceParameters()
	
	ParameterNames = New Array; // Array of String
	ParameterNames.Add("Organization");
	ParameterNames.Add("SourceDocument_");
	
	Return ParameterNames;
	
EndFunction

Function NamesOfDecryptionParameters()
	
	ParameterNames = New Array; // Array of String
	ParameterNames.Add("Counterparty");
	ParameterNames.Add("Partner");
	Return ParameterNames;
	
EndFunction

Function PerformanceMeasurementParameters(OptionParameters)
	
	Result = New Structure;
	Result.Insert("ShouldRecord", True);
	Result.Insert("Divisor", 1);
	
	If OptionParameters.ThisIsTranscriptOfNomenclature Then
		
		OptionType = "LayoutOfTranscriptByItem";
		
	ElsIf OptionParameters.ThisIsTranscriptOfDocuments Then
		
		OptionType = "LayoutOfTranscriptAccordingToDocuments";
		
	ElsIf OptionParameters.DetailsMode Then
		
		OptionType = "LayoutOfDecryption";
		Result.ShouldRecord = False;
		
	Else
		
		OptionType = "LayoutOfMainVersion";
		
	EndIf;
	
	KeyOperation = StrTemplate(
		"Report.CalculateCustomerRebates.ObjectModule.OnComposeResult.%1", OptionType);
	Result.Insert("KeyOperation", KeyOperation);
	
	Return Result;
	
EndFunction

Function ColumnHeaders(RebateConditionsParameters)
	
	ColumnHeaders = New Structure;
	ColumnHeaders.Insert("PropertyValue", RebateConditionsParameters.ItemPropertyTitle);
	Return ColumnHeaders;
	
EndFunction

#EndRegion

#EndIf