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
		SourceDocument_ = AttributesValues.CorrectedDocument; // DocumentRef.ConditionsOfVendorRebates
	Else
		SourceDocument_ = DocumentTermsOfRetroBonuses;
	EndIf;
	DataCompositionClientServer.SetParameter(ReportSettingsInForm, "SourceDocument_", SourceDocument_);
	
	RebateConditionsParameters = RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers(SourceDocument_);
	
	DocumentAccrual = Documents.AccrualOfVendorRebates.EmptyRef();
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
	
	MeasurementParameters = PerformanceMeasurementParameters(RebateConditionsParameters, OptionParameters);
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
	
	VendorTable = Reports.CalculateVendorRebates.PreliminaryTableOfVendors(SourceDocument_);
	QueryText = Reports.CalculateVendorRebates.QueryText(
		RebateConditionsParameters, OptionParameters, VendorTable);
	DataCompositionSchema.DataSets.CalculateVendorRebates.Query = QueryText;
	
	DataCompositionClientServer.FillInElements(
		ReportSettings.DataParameters,
		ReportSettingsInForm.DataParameters);
	
	If RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Balance Then
		
		BalanceDateParameter = DataCompositionClientServer.GetParameter(ReportSettings, "DateOfRemainingGoods");
		If BalanceDateParameter <> Undefined Then
			DateOfRemainingGoods = BalanceDateParameter.Value; // Date
		Else
			DateOfRemainingGoods = '00010101';
		EndIf;
		If Not ValueIsFilled(DateOfRemainingGoods) Then
			DateOfRemainingGoods = RebateConditionsParameters.DateOfRemainingGoods;
		EndIf;
		If FirstLayoutWhenOpened
		 Or ConditionParametersHaveChanged
		 Or OptionParameters.ThisIsTheTranscript Then
			DateOfRemainingGoods = RebateConditionsParameters.DateOfRemainingGoods;
		EndIf;
		DateOfRemainingGoods = EndOfDay(DateOfRemainingGoods);
		DataCompositionClientServer.SetParameter(ReportSettings, "DateOfRemainingGoods", DateOfRemainingGoods);
		
		DataCompositionClientServer.SetParameter(
			ReportSettings, "CounterpartySupplier", RebateConditionsParameters.Counterparty, True);
		DataCompositionClientServer.SetParameter(
			ReportSettings, "PartnerVendor", RebateConditionsParameters.Partner, True);
		
	Else
		
		If OptionParameters.ThisIsTheTranscript Then
			
			// for decryption, the period is always equal to the period of the original report
			StartDateParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, "StartDate");
			EndDateParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, "EndDate");
			ReportPeriod = New StandardPeriod(StartDateParameter.Value, EndDateParameter.Value);
			
			ParameterNames = NamesOfDecryptionParameters();
			For Each ParameterName In ParameterNames Do
				ApplyParameterFromFormSettings(ReportSettings, ReportSettingsInForm, ParameterName);
			EndDo;
			
			ApplyDecryptionParameters(RebateConditionsParameters, ReportSettings);
			
		Else
			
			ReportPeriodParameter = DataCompositionClientServer.GetParameter(ReportSettings, "ReportPeriod");
			If ReportPeriodParameter <> Undefined Then
				ReportPeriod = ReportPeriodParameter.Value; // StandardPeriod
			Else
				ReportPeriod = New StandardPeriod;
			EndIf;
			
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
		
	EndIf;
	
	CompaniesList = New ValueList(); // ValueList of CatalogRef.Companies
	CompaniesList.Add(RebateConditionsParameters.Organization);
	DataCompositionClientServer.SetParameter(
		ReportSettings, "Organization", CompaniesList);
	
	ExcludedBusinessOfOperations = Reports.CalculateVendorRebates.ExcludedBusinessOfOperations();
	DataCompositionClientServer.SetParameter(
		ReportSettings, "ExcludedBusinessOfOperations", ExcludedBusinessOfOperations);
	
	ExcludedSettingsOfBTransaction = Reports.CalculateVendorRebates.ExcludedSettingsOfBusinessTransaction();
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
	AdditionalProperties.Insert("BonusType", RebateConditionsParameters.BonusType);
	
	// At the time of generation, we enable the availability of service parameters for output to the report header
	InternalParameters = NamesOfServiceParameters(RebateConditionsParameters);
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
	
	TempTableManager = ExternalTempTablesForReport(SourceDocument_, RebateConditionsParameters, Measurement, VendorTable);
	
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
	AttributeValuesOfConditions = Undefined;
	
	OptionsForDecodingDocuments = NamesOfDecryptionOptionsForDocuments();
	DecryptionOptionsByItem = NamesOfTranscriptOptionsByNomenclature();
	CurrentVariantKey = Form.CurrentVariantKey; // String
	ThisIsTheTranscript = (OptionsForDecodingDocuments.Find(CurrentVariantKey) <> Undefined)
		Or (DecryptionOptionsByItem.Find(CurrentVariantKey) <> Undefined);
	
	If Not Parameters.Property("CommandParameter")
	   And Not Form.DetailsMode
	   And Not ThisIsTheTranscript Then
		
		Cancel = True;
		DocumentSynonym = Metadata.Documents.ConditionsOfVendorRebates.Synonym;
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
	
	TypeLinkToConditionsDocument = New TypeDescription("DocumentRef.ConditionsOfVendorRebates");
	TermsAndConditionsAttributeDocument = New FormAttribute("DocumentTermsOfRetroBonuses", TypeLinkToConditionsDocument);
	FormDetailsToAdd.Add(TermsAndConditionsAttributeDocument);
	
	TypeDocumentLinkAccrual = New TypeDescription("DocumentRef.AccrualOfVendorRebates");
	AttributeDocumentAccrual = New FormAttribute("DocumentAccrualOfRetroBonuses", TypeDocumentLinkAccrual);
	FormDetailsToAdd.Add(AttributeDocumentAccrual);
	
	AttributesToClearPeriod = New FormAttribute("ClearUserSettingsPeriod", New TypeDescription("Boolean"));
	FormDetailsToAdd.Add(AttributesToClearPeriod);
	
	AttributeIsFirstLayoutWhenOpened = New FormAttribute("FirstLayoutWhenOpened", New TypeDescription("Boolean"));
	FormDetailsToAdd.Add(AttributeIsFirstLayoutWhenOpened);
	
	TypeEnumerationTypesOfRebate = New TypeDescription("EnumRef.VendorRebateTypes");
	AttributeIsTypeOfRebate = New FormAttribute("TypeOfRebateOfRetroBonus", TypeEnumerationTypesOfRebate);
	FormDetailsToAdd.Add(AttributeIsTypeOfRebate);
	
	Form.ChangeAttributes(FormDetailsToAdd);
	
	CommonClientServer.SetFormAttributeByPath(Form, "FirstLayoutWhenOpened", True);
	
	If Parameters.Property("CommandParameter") Then
		
		DocumentAccrual = Documents.AccrualOfVendorRebates.EmptyRef();
		ParameterType = TypeOf(Parameters.CommandParameter);
		If ParameterType = Type("DocumentRef.ConditionsOfVendorRebates") Then
			
			DocumentTermsOfRetroBonuses = Parameters.CommandParameter; // DocumentRef.ConditionsOfVendorRebates
			
		ElsIf ParameterType = Type("DocumentRef.AccrualOfVendorRebates") Then
			
			DocumentAccrual = Parameters.CommandParameter; // DocumentRef.AccrualOfVendorRebates
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
		
		If ValueIsFilled(DocumentAccrual) Then
			
			AttributeValuesOfConditions = ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses);
			
			If AttributeValuesOfConditions.Patch = True Then
				SourceDocument_ = AttributeValuesOfConditions.CorrectedDocument;
			Else
				SourceDocument_ = DocumentTermsOfRetroBonuses;
			EndIf;
			ConditionParameters_ = RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers(SourceDocument_);
			CheckAccrualAttributes(ConditionParameters_, AccrualAttributes, Cancel);
			
			VariantKey = KeyOfAccrualDecryptionOption(ConditionParameters_);
			CommonClientServer.SetFormAttributeByPath(Form, "CurrentVariantKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(Form, "Parameters.VariantKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(
				Form, "ReportSettings.PredefinedOptionKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(
				Form, "ParametersForm.InitialOptionKey", VariantKey);
			CommonClientServer.SetFormAttributeByPath(
				Form, "ParametersForm.InitialKeyOfPredefinedOption", VariantKey);
			
			Filter = New Structure;
			Filter.Insert("Organization", AccrualAttributes.Organization);
			Filter.Insert("Currency", AccrualAttributes.Currency);
			If ConditionParameters_.BonusType = Enums.VendorRebateTypes.Balance Then
				
				Filter.Insert("DateOfRemainingGoods", ConditionParameters_.DateOfRemainingGoods);
				
			Else
				
				ReportPeriod = New StandardPeriod(AccrualAttributes.BeginOfPeriod, AccrualAttributes.PeriodEnding);
				Filter.Insert("ReportPeriod", ReportPeriod);
				Filter.Insert("StartDate", AccrualAttributes.BeginOfPeriod);
				Filter.Insert("EndDate", AccrualAttributes.PeriodEnding);
				
			EndIf;
			
			CommonClientServer.SetFormAttributeByPath(Form, "ParametersForm.Filter", Filter);
			
		EndIf;
		
	ElsIf Form.DetailsMode Then
		
		DetailsData = GetFromTempStorage(Form.Parameters.Details.Data); // DataCompositionDetailsData
		ConditionsDocumentParameter = DataCompositionClientServer.GetParameter(
			DetailsData.Settings, "DocumentTermsOfRetroBonuses");
		DocumentTermsOfRetroBonuses = ConditionsDocumentParameter.Value; // DocumentRef.ConditionsOfVendorRebates
		
	ElsIf ThisIsTheTranscript Then
		
		DocumentTermsOfRetroBonuses = Form.ParametersForm.Filter.DocumentTermsOfRetroBonuses; // DocumentRef.ConditionsOfVendorRebates
		
	EndIf;
	
	CommonClientServer.SetFormAttributeByPath(
		Form, "DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
	
	If AttributeValuesOfConditions = Undefined Then
		AttributeValuesOfConditions = ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses);
	EndIf;
	RebatesCalculation.CheckAttributesOfConditions(AttributeValuesOfConditions, Cancel);
	CommonClientServer.SetFormAttributeByPath(
		Form, "TypeOfRebateOfRetroBonus", AttributeValuesOfConditions.RebateKindOfBonusType);
	
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
	
	TypeOfRebateOfRetroBonus = CommonClientServer.GetFormAttributeByPath(
		Form, "TypeOfRebateOfRetroBonus");
	NewDCSettings.AdditionalProperties.Insert("TypeOfRebateOfRetroBonus", TypeOfRebateOfRetroBonus);
	
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
		
		DocumentTermsOfRetroBonuses = CommonClientServer.GetFormAttributeByPath(
			Context, "DocumentTermsOfRetroBonuses"); // DocumentRef.ConditionsOfVendorRebates
		
		FirstLayoutWhenOpened = CommonClientServer.GetFormAttributeByPath(
			Context, "FirstLayoutWhenOpened");
		If FirstLayoutWhenOpened = True Then
			NewDCUserSettings.AdditionalProperties.Insert("FirstLayoutWhenOpened", FirstLayoutWhenOpened);
		EndIf;
		
		// We determine the desired option and apply the structure settings
		
		If Not OptionParameters.DetailsMode Then
			
			AttributesValues = ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses);
			If AttributesValues.Patch = True Then
				SourceDocument_ = AttributesValues.CorrectedDocument; // DocumentRef.ConditionsOfVendorRebates
			Else
				SourceDocument_ = DocumentTermsOfRetroBonuses;
			EndIf;
			RebateConditionsParameters = RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers(SourceDocument_);
			
			CompositeVersionOfReport = VersionOfConditionsReport(RebateConditionsParameters, OptionParameters);
			SettingsByOption = CompositeVersionOfReport.Settings;
			
			If FirstLayoutWhenOpened Then
				
				RebatesCalculation.MoveLayoutSettingsStructure(NewDCSettings, SettingsByOption);
				AdjustColumnVisibility(RebateConditionsParameters, NewDCSettings, OptionParameters);
				
			EndIf;
			
			ColumnHeaders = ColumnHeaders(RebateConditionsParameters);
			DatasetFields = DataCompositionSchema.DataSets.Find("CalculateVendorRebates").Fields;
			RebatesCalculation.CustomizeHeadersOfSelectedColumns(SettingsByOption, ColumnHeaders);
			RebatesCalculation.ConfigureDataSetColumnHeaders(DatasetFields, ColumnHeaders);
			
			RebatesCalculation.ConfigureFormatOfPropertyValue(DatasetFields, RebateConditionsParameters);
			
		EndIf;
			
		If FirstLayoutWhenOpened = True
		   And Not OptionParameters.DetailsMode Then
			
			// Collapsing the grouping level by ranges
		
			OptionsWithRangesOfStrings = NamesOfVariantsByRangesInStrings();
			If OptionsWithRangesOfStrings.Find(CompositeVersionOfReport.Name) <> Undefined Then
				
				LevelOfRangeDimensions = RebatesCalculation.LevelOfGroupingByRanges(CompositeVersionOfReport);
				If LevelOfRangeDimensions <> Undefined Then
					
					CommonClientServer.SetFormAttributeByPath(
						Context, "SelectedGroupsLevel", LevelOfRangeDimensions);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		// For a contextual report, we clear the period saved in the user settings, fill it in according to the conditions of the Republic of Belarus
		
		ClearUserSettingsPeriod = CommonClientServer.GetFormAttributeByPath(
			Context, "ClearUserSettingsPeriod"); // Boolean
		Contextual = CommonClientServer.GetFormAttributeByPath(
			Context, "ReportSettings.Contextual"); // Boolean
		TypeOfRebateOfRetroBonus = CommonClientServer.GetFormAttributeByPath(
			Context, "TypeOfRebateOfRetroBonus"); // EnumRef.VendorRebateTypes
		
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
			DataCompositionClientServer.SetParameter(
				NewDCUserSettings,
				"DateOfRemainingGoods",
				DateEmpty,
				True);
			
			CommonClientServer.SetFormAttributeByPath(
				Context, "ClearUserSettingsPeriod", False);
			
		EndIf;
		
		// We remove the original selections by partner/counterparty from the form parameters, otherwise they overwrite the user settings
		
		If Not FirstLayoutWhenOpened Then
			
			ParameterNames = NamesOfDecryptionParameters();
			ParameterNames.Add("Currency");
			FilterForms = Context.ParametersForm.Filter; // Structure
			
			For Each ParameterName In ParameterNames Do
				
				If FilterForms.Property(ParameterName) Then
					FilterForms.Delete(ParameterName);
				EndIf;
				
			EndDo;
			
		EndIf;
		
		// Disabling user accessibility of parameters
		
		If Not OptionParameters.ThisIsTheTranscript Then
			
			ParameterNames = NamesOfDecryptionParameters();
			For Each ParameterName In ParameterNames Do
				DataCompositionSchema.Parameters[ParameterName].UseRestriction = True;
			EndDo;
			
		EndIf;
		
		ParameterNames = NamesOfUnavailableParameters(TypeOfRebateOfRetroBonus);
		For Each ParameterName In ParameterNames Do
			DataCompositionSchema.Parameters[ParameterName].UseRestriction = True;
		EndDo;
		
		// Limiting the availability of fields
		
		ConfigureFieldUsageRestrictions(TypeOfRebateOfRetroBonus, DataCompositionSchema);
		ConfigureLoggerTypes(TypeOfRebateOfRetroBonus, DataCompositionSchema);
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
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
	
	DetailsMode1 = CommonClientServer.StructureProperty(
		ReportSettingsInForm.AdditionalProperties, "DetailsMode", False); // Boolean
	DetailsMode2 = CommonClientServer.StructureProperty(
		Var_SettingsComposer.Settings.AdditionalProperties, "DetailsMode", False); // Boolean
	OptionParameters.DetailsMode = (DetailsMode1 Or DetailsMode2);
		
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
	
	VariantModified = CommonClientServer.StructureProperty(
		Var_SettingsComposer.UserSettings.AdditionalProperties, "VariantModified", False); // Boolean
	UserSettingsModified = CommonClientServer.StructureProperty(
		Var_SettingsComposer.UserSettings.AdditionalProperties, "UserSettingsModified", False); // Boolean
	OptionParameters.OptionIsModifiedByUser = (VariantModified Or UserSettingsModified);
	
	Return OptionParameters;
	
EndFunction

Function DocumentOfAdditionalPropertiesOrParameters(ReportSettingsInForm)
	
	DocumentTermsOfRetroBonuses = Documents.ConditionsOfVendorRebates.EmptyRef();
	ReportSettingsInForm.AdditionalProperties.Property("DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
	
	If DocumentTermsOfRetroBonuses <> Undefined
	   And Not DocumentTermsOfRetroBonuses.IsEmpty() Then
		
		DataCompositionClientServer.SetParameter(
			ReportSettingsInForm, "DocumentTermsOfRetroBonuses", DocumentTermsOfRetroBonuses);
		
	Else
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("DocumentTermsOfRetroBonuses");
		If DataParameter <> Undefined Then
			DocumentTermsOfRetroBonuses = DataParameter.Value; // DocumentRef.ConditionsOfVendorRebates
		EndIf;
		
	EndIf;
	
	Return DocumentTermsOfRetroBonuses;
	
EndFunction

Function ValuesOfDetailsOfConditionsDocument(DocumentTermsOfRetroBonuses)
	
	Attributes = "Posted, WithoutCalculation, Status, Patch, CorrectedDocument, RebateKind.BonusType";
	AttributesValues = Common.ObjectAttributesValues(DocumentTermsOfRetroBonuses, Attributes);
	Return AttributesValues;
	
EndFunction

Function ValuesOfDetailsOfAccrualDocument(DocumentAccrual)
	
	Attributes = "Posted, TermDocument, Organization, Counterparty, Partner, BeginOfPeriod, PeriodEnding, Currency";
	AttributesValues = Common.ObjectAttributesValues(DocumentAccrual, Attributes);
	Return AttributesValues;
	
EndFunction

Procedure CheckAccrualAttributes(ConditionParameters_, AccrualAttributes, Cancel, RaiseException1 = False)
	
	MessageText = "";
	
	CheckedAttributes = New Array; // Array of String
	CheckedAttributes.Add("TermDocument");
	CheckedAttributes.Add("Currency");
	
	If ConditionParameters_.BonusType <> Enums.VendorRebateTypes.Balance Then
		
		CheckedAttributes.Add("BeginOfPeriod");
		CheckedAttributes.Add("PeriodEnding");
		
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
		
		AttributeMetadata = Metadata.Documents.AccrualOfVendorRebates.Attributes.Find(AttributeToCheck);
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

Function NamesOfServiceParameters(RebateConditionsParameters)
	
	ParameterNames = New Array; // Array of String
	ParameterNames.Add("Organization");
	ParameterNames.Add("SourceDocument_");
	
	If RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Balance Then
		
		ParameterNames.Add("CounterpartySupplier");
		ParameterNames.Add("PartnerVendor");
		
	EndIf;
	
	Return ParameterNames;
	
EndFunction

Function ExternalTempTablesForReport(SourceDocument_, RebateConditionsParameters, Measurement, VendorTable)
	
	TempTableManager = Undefined;
	
	If (RebateConditionsParameters.ContentOfGoods = Enums.RebatesItems.ProductSegments)
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		CompositionOfGoodsSegments = RebatesServer.CompositionOfGoodsSegments(SourceDocument_);
		
		Query = New Query;
		If TempTableManager = Undefined Then
			TempTableManager = New TempTablesManager();
		EndIf;
		Query.TempTablesManager = TempTableManager;
		Query.SetParameter("CompositionOfSegments", CompositionOfGoodsSegments);
		
		QueryText =
		"SELECT
		|	*
		|INTO TT_CompositionOfGoodsSegments
		|FROM
		|	&CompositionOfSegments AS CompositionOfSegments";
		Query.Text = QueryText;
		
		Query.Execute();
		
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "GettingCompositionOfGoodsSegments");
		
	EndIf;
	
	If RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		Query = New Query;
		If TempTableManager = Undefined Then
			TempTableManager = New TempTablesManager();
		EndIf;
		Query.TempTablesManager = TempTableManager;
		Query.SetParameter("VendorTable", VendorTable);
		
		QueryText =
		"SELECT
		|	*
		|INTO VT_SuppliersInAdvance
		|FROM
		|	&VendorTable AS VendorTable";
		Query.Text = QueryText;
		
		Query.Execute();
		
	EndIf;
	
	If RebateConditionsParameters.CalculationByProperties
	   And Not RebateConditionsParameters.RecordingIsCompleted Then
		
		Query = New Query;
		If TempTableManager = Undefined Then
			TempTableManager = New TempTablesManager();
		EndIf;
		Query.TempTablesManager = TempTableManager;
		
		QueryText = RebatesServer.QueryTextItemsByProperty(
			False, RebateConditionsParameters.ProductItemProperty, RebateConditionsParameters.ItemItemPropertyLink);
		Query.Text = QueryText;
		
		Query.SetParameter("SourceDocument_", SourceDocument_);
		Query.SetParameter("ProductItemProperty", RebateConditionsParameters.ItemItemPropertyLink);
		
		Query.Execute();
		
		PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, 1, "GettingCompositionOfItemsByProperty");
		
	EndIf;
	
	Return TempTableManager;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers
//  OptionParameters - See OptionParameters
// 
// Returns:
//  DataCompositionSettingsVariant
//  
Function VersionOfConditionsReport(RebateConditionsParameters, OptionParameters)
	
	ReportOptions = DataCompositionSchema.SettingVariants;
	BonusType = RebateConditionsParameters.BonusType;
	BonusTypePresentation = String(BonusType);
	TypesOfBonuses = Enums.VendorRebateTypes;
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	PartyCountDetailsPresentation = String(PartyCountDetails);
	TypesOfDetailingCalculationOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If BonusType = TypesOfBonuses.Sales Then
		
		If PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterparty Then
			
			If OptionParameters.ThisIsTranscriptOfNomenclature
			 Or OptionParameters.DetailsMode = True Then
				
				CompositeVersionOfReport = VariantOfDecodingBySalesNomenclature(RebateConditionsParameters);
				OptionParameters.DetailingToItem = True;
				
			ElsIf OptionParameters.ThisIsTranscriptOfDocuments Then
				CompositeVersionOfReport = VariantOfDecodingAccordingToDocuments(RebateConditionsParameters);
			Else
				CompositeVersionOfReport = ReportOptions.SalesByCustomers;
			EndIf;
			
		ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.EmptyRef() Then
			
			If OptionParameters.ThisIsTranscriptOfNomenclature Then
				
				CompositeVersionOfReport = VariantOfDecodingBySalesNomenclature(RebateConditionsParameters);
				OptionParameters.DetailingToItem = True;
				
			ElsIf OptionParameters.ThisIsTranscriptOfDocuments Then
				
				CompositeVersionOfReport = VariantOfDecodingAccordingToDocuments(RebateConditionsParameters);
				
			Else
				
				CompositeVersionOfReport = VariantOfDecodingBySalesNomenclature(RebateConditionsParameters);
				OptionParameters.DetailingToItem = True;
				
			EndIf;
			
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
		
	ElsIf BonusType = TypesOfBonuses.Purchases Then
		
		If OptionParameters.ThisIsTranscriptOfDocuments Then
			CompositeVersionOfReport = VariantOfDecodingAccordingToDocuments(RebateConditionsParameters);
		Else
			
			CompositeVersionOfReport = VariantOfDecodingNomenclatureForPurchases(RebateConditionsParameters);
			OptionParameters.DetailingToItem = True;
			
		EndIf;
		
	ElsIf BonusType = TypesOfBonuses.Balance Then
		
		CompositeVersionOfReport = ReportOptions.Balance;
		OptionParameters.DetailingToItem = True;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Sai loại thưởng ""%1"" cho chứng từ ""%2""';
							|ru = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|en = 'Unknown rebate type (%1) for the %2 document'; fa = 'Unknown rebate type (%1) for the %2 document';
							|it = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|pl = 'Unknown rebate type (%1) for the %2 document';
							|tr = '""%2"" belgesi için ""%1"" bonus türü bilinmiyor'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			BonusTypePresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	Return CompositeVersionOfReport;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers
// 
// Returns:
//  DataCompositionSettingsVariant
//
Function VariantOfDecodingBySalesNomenclature(RebateConditionsParameters)
	
	ReportOptions = DataCompositionSchema.SettingVariants;
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	PartyCountDetailsPresentation = String(PartyCountDetails);
	TypesOfDetailingCalculationOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterparty Then
		
		If RebateConditionsParameters.CalculationScaleByRanges Then
			
			If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
				CompositeVersionOfReport = ReportOptions.SalesBreakdownByNomenclatureByCustomersByRangesTable;
			Else
				CompositeVersionOfReport = ReportOptions.SalesBreakdownByNomenclatureByCustomersByRangesByLines;
			EndIf;
			
		Else
			CompositeVersionOfReport = ReportOptions.SalesBreakdownByItemByCustomer;
		EndIf;
		
	ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.EmptyRef() Then
		
		If RebateConditionsParameters.CalculationScaleByRanges Then
			
			If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
				CompositeVersionOfReport = ReportOptions.SalesAreSummarizedByRangesInTable;
			Else
				CompositeVersionOfReport = ReportOptions.SalesAreSummarizedByRangesByLines;
			EndIf;
			
		Else
			
			CompositeVersionOfReport = ReportOptions.SalesSummary;
			
		EndIf;
		
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
	
	Return CompositeVersionOfReport;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers
// 
// Returns:
//  DataCompositionSettingsVariant
//
Function VariantOfDecodingNomenclatureForPurchases(RebateConditionsParameters)
	
	ReportOptions = DataCompositionSchema.SettingVariants;
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	
	If RebateConditionsParameters.CalculationScaleByRanges Then
		
		If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
			CompositeVersionOfReport = ReportOptions.PurchasesByRangesInTable;
		Else
			CompositeVersionOfReport = ReportOptions.PurchasesByRangesByLines;
		EndIf;
		
	Else
		
		CompositeVersionOfReport = ReportOptions.Purchases;
		
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
		
		RebatesCalculation.MoveLayoutSettingsStructure(ComposerOfSettingsByOption.Settings, ReportSettingsInForm);
		
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
	
	AdjustColumnVisibility(RebateConditionsParameters, ComposerOfSettingsByOption.Settings, OptionParameters);
	
	ColumnHeaders = ColumnHeaders(RebateConditionsParameters);
	RebatesCalculation.CustomizeHeadersOfSelectedColumns(ComposerOfSettingsByOption.Settings, ColumnHeaders);
	
EndProcedure

Function ReportHeader(RebateConditionsParameters)
	
	ReportHeader = NStr("vi = 'Tính thưởng lũy kế của nhà cung cấp';
						|ru = 'Расчет ретро-бонусов поставщика';
						|en = 'Calculate vendor rebates'; fa = 'محاسبه تخفیف‌های حجمی فروشنده';
						|it = 'Расчет ретро-бонусов поставщика';
						|pl = 'Calculate vendor rebates';
						|tr = 'Tedarikçi retro bonuslarının muhasebesi'");
	Return ReportHeader;
	
EndFunction

Procedure AdjustColumnVisibility(RebateConditionsParameters, Settings, OptionParameters)
	
	TargetValues = Enums.TargetSalesIndicatorsOfRebatesByGoods;
	BaseOfCalculation = RebateConditionsParameters.BaseOfCalculation;
	TypesOfCalculationBase = Enums.RebateCalculationBases;
	
	ColumnsVisibility = New Structure;
	ColumnsVisibility.Insert("AmountOfTurnoverWithVAT", False);
	ColumnsVisibility.Insert("AmountOfTurnoverExcludingVAT", False);
	ColumnsVisibility.Insert("AmountInBasePrices", False);
	ColumnsVisibility.Insert("SumPlan", False);
	ColumnsVisibility.Insert("CountPlan", False);
	ColumnsVisibility.Insert("BasePrice", False);
	ColumnsVisibility.Insert("NumberOfPackages_", False);
	ColumnsVisibility.Insert("CountBalance", False);
	ColumnsVisibility.Insert("BonusAmountPerUnit", False);
	ColumnsVisibility.Insert("RangeFrom", False);
	ColumnsVisibility.Insert("RangeBy", False);
	ColumnsVisibility.Insert("Products", False);
	ColumnsVisibility.Insert("Characteristic", False);
	ColumnsVisibility.Insert("UnitOfMeasure", False);
	ColumnsVisibility.Insert("PropertyValue", False);
	
	If BaseOfCalculation = TypesOfCalculationBase.RevenueBasePrices
	 Or BaseOfCalculation = TypesOfCalculationBase.PurchaseAmountBasePrices Then
		
		ColumnsVisibility.AmountInBasePrices = True;
		ColumnsVisibility.BasePrice = True;
		
	ElsIf ValueIsFilled(BaseOfCalculation) Then
		
		If RebateConditionsParameters.ConsiderVAT Then
			ColumnsVisibility.AmountOfTurnoverWithVAT = True;
		Else
			ColumnsVisibility.AmountOfTurnoverExcludingVAT = True;
		EndIf;
		
	EndIf;
	
	If RebateConditionsParameters.GoodsIndicator = TargetValues.Sum Then
		
		NumberOfCalculationPeriods = RebatesCalculation.NumberOfCalculationPeriods(
			RebateConditionsParameters.ValidOnDate,
			RebateConditionsParameters.ValidTo,
			RebateConditionsParameters.ConditionFrequency);
		
		ColumnsVisibility.SumPlan = (Not RebateConditionsParameters.CalculationScaleByRanges
			And (Not RebateConditionsParameters.ProgressiveCalculationScale
				Or OptionParameters.ThisIsTheTranscript
				Or OptionParameters.DetailingToItem
				Or NumberOfCalculationPeriods <= 1));
		
	ElsIf RebateConditionsParameters.GoodsIndicator = TargetValues.Count
	      Or RebateConditionsParameters.GoodsIndicator = TargetValues.QuantityTotal
	      Or RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer Then
		
		ColumnsVisibility.CountPlan = True;
		
	EndIf;
	
	If RebateConditionsParameters.GoodsIndicator = TargetValues.BatchOffer Then
		ColumnsVisibility.NumberOfPackages_ = True;
	EndIf;
	
	If RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Balance Then
		
		ColumnsVisibility.CountPlan = True;
		ColumnsVisibility.CountBalance = True;
		ColumnsVisibility.BonusAmountPerUnit = True;
		
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
		
		RebatesCalculation.DisableUseOfSelectedField(Settings.Selection.Items, LayoutField);
		For Each SettingsStructure In Settings.Structure Do
			RebatesCalculation.DisableUseOfField(SettingsStructure, LayoutField);
		EndDo;
		
	EndDo;
	
EndProcedure

Function ColumnHeaders(RebateConditionsParameters)
	
	BonusType = RebateConditionsParameters.BonusType;
	BonusTypePresentation = String(BonusType);
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	ColumnHeaders = New Structure;
	ColumnHeaders.Insert("AmountOfTurnoverWithVAT", "");
	ColumnHeaders.Insert("AmountOfTurnoverExcludingVAT", "");
	ColumnHeaders.Insert("AmountInBasePrices", "");
	ColumnHeaders.Insert("CharacteristicsOfSalesPurchases", "");
	ColumnHeaders.Insert("PropertyValue", RebateConditionsParameters.ItemPropertyTitle);
	
	If BonusType = TypesOfBonuses.Sales Then
		
		ColumnHeaders.AmountOfTurnoverWithVAT = NStr("vi = 'Doanh thu (gồm thuế GTGT)';
													|ru = 'Выручка (с НДС)';
													|en = 'Revenue (including VAT)'; fa = 'درآمد (با VAT)';
													|it = 'Выручка (с НДС)';
													|pl = 'Revenue (including VAT)';
													|tr = 'Gelir (KDV dahil)'");
		ColumnHeaders.AmountOfTurnoverExcludingVAT = NStr("vi = 'Doanh thu (không gồm thuế GTGT)';
															|ru = 'Выручка (без НДС)';
															|en = 'Revenue (excluding VAT)'; fa = 'درآمد (بدون VAT)';
															|it = 'Выручка (без НДС)';
															|pl = 'Revenue (excluding VAT)';
															|tr = 'Gelir (KDV hariç)'");
		ColumnHeaders.AmountInBasePrices = NStr("vi = 'Doanh thu theo đơn giá cơ bản';
												|ru = 'Выручка в базовых ценах';
												|en = 'Revenue in base prices'; fa = 'درآمد به قیمت‌های پایه';
												|it = 'Выручка в базовых ценах';
												|pl = 'Revenue in base prices';
												|tr = 'Temel fiyatlarla gelir'");
		ColumnHeaders.CharacteristicsOfSalesPurchases = NStr("vi = 'Đặc điểm bán hàng';
															|ru = 'Характеристика продаж';
															|en = 'Sales characteristics'; fa = 'مشخصات فروش';
															|it = 'Sales characteristics';
															|pl = 'Sales characteristics';
															|tr = 'Satış varyantı'");
		
	ElsIf BonusType = TypesOfBonuses.Purchases
	      Or BonusType = TypesOfBonuses.Balance Then
		
		ColumnHeaders.AmountOfTurnoverWithVAT = NStr("vi = 'Số tiền mua hàng hóa (gồm thuế GTGT)';
													|ru = 'Сумма закупки (с НДС)';
													|en = 'Purchase amount (including VAT)'; fa = 'Purchase amount (including VAT)';
													|it = 'Сумма закупки (с НДС)';
													|pl = 'Purchase amount (including VAT)';
													|tr = 'Satın alma tutarı (KDV dahil)'");
		ColumnHeaders.AmountOfTurnoverExcludingVAT = NStr("vi = 'Số tiền mua hàng hóa (không thuế GTGT)';
															|ru = 'Сумма закупки (без НДС)';
															|en = 'Purchase amount (excluding VAT)'; fa = 'Purchase amount (excluding VAT)';
															|it = 'Сумма закупки (без НДС)';
															|pl = 'Purchase amount (excluding VAT)';
															|tr = 'Satın alma tutarı (KDV hariç)'");
		ColumnHeaders.AmountInBasePrices = NStr("vi = 'Số tiền mua hàng theo đơn giá cơ bản';
												|ru = 'Сумма закупки в базовых ценах';
												|en = 'Purchase amount in base prices'; fa = 'Purchase amount in base prices';
												|it = 'Сумма закупки в базовых ценах';
												|pl = 'Purchase amount in base prices';
												|tr = 'Taban fiyatlarda satın alma tutarı'");
		ColumnHeaders.CharacteristicsOfSalesPurchases = NStr("vi = 'Đặc điểm mua hàng';
															|ru = 'Характеристика закупок';
															|en = 'Purchasing characteristics'; fa = 'Purchasing characteristics';
															|it = 'Purchasing characteristics';
															|pl = 'Purchasing characteristics';
															|tr = 'Satın alma varyantı'");
	
	Else
		
		ErrorTemplate = NStr("vi = 'Loại thưởng không xác định ""%1"" cho chứng từ ""%2""';
							|ru = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|en = 'Unknown rebate type (%1) for the %2 document'; fa = 'Unknown rebate type (%1) for the %2 document';
							|it = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|pl = 'Unknown rebate type (%1) for the %2 document';
							|tr = '""%2"" belgesi için ""%1"" bonus türü bilinmiyor'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			BonusTypePresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
	
	EndIf;
	
	Return ColumnHeaders;
	
EndFunction

Procedure ConfigureFieldUsageRestrictions(BonusType, Var_DataCompositionSchema)
	
	TypesOfBonus = Enums.VendorRebateTypes;
	
	EnabledOfColumns = New Structure;
	EnabledOfColumns.Insert("CounterpartyCustomer", False);
	EnabledOfColumns.Insert("CounterpartySupplier", False);
	EnabledOfColumns.Insert("PartnerVendor", False);
	EnabledOfColumns.Insert("Warehouse", False);
	EnabledOfColumns.Insert("DocumentRecorder", False);
	EnabledOfColumns.Insert("CharacteristicsOfSalesPurchases", False);
	
	If BonusType = TypesOfBonus.Sales Then
		
		EnabledOfColumns.CounterpartyCustomer = True;
		EnabledOfColumns.DocumentRecorder = True;
		EnabledOfColumns.CharacteristicsOfSalesPurchases = True;
		
	ElsIf BonusType = TypesOfBonus.Purchases Then
		
		EnabledOfColumns.CounterpartySupplier = True;
		EnabledOfColumns.PartnerVendor = True;
		EnabledOfColumns.DocumentRecorder = True;
		EnabledOfColumns.CharacteristicsOfSalesPurchases = True;
		
	ElsIf BonusType = TypesOfBonus.Balance Then
		
		EnabledOfColumns.CounterpartySupplier = True;
		EnabledOfColumns.PartnerVendor = True;
		EnabledOfColumns.Warehouse = True;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Sai loại thưởng ""%1""';
							|ru = 'Некорректный тип бонуса ""%1""';
							|en = 'Incorrect rebate type: ""%1""'; fa = 'Incorrect rebate type: ""%1""';
							|it = 'Некорректный тип бонуса ""%1""';
							|pl = 'Incorrect rebate type: ""%1""';
							|tr = '""%1"" bonus türü yanlış'");
		BonusTypeByString = String(BonusType);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, BonusTypeByString);
		Raise ErrorText;
		
	EndIf;
	
	DatasetFields = Var_DataCompositionSchema.DataSets.Find("CalculateVendorRebates").Fields;
	
	For Each ColumnAvailabilityElement In EnabledOfColumns Do
		
		DataSetField = DatasetFields.Find(ColumnAvailabilityElement.Key);
		If DataSetField = Undefined Then
			Continue;
		EndIf;
		
		LimitedAvailability = Not ColumnAvailabilityElement.Value;
		
		DataSetField.UseRestriction.Group = LimitedAvailability;
		DataSetField.UseRestriction.Condition = LimitedAvailability;
		DataSetField.UseRestriction.Order = LimitedAvailability;
		DataSetField.UseRestriction.Field = LimitedAvailability;
		
		DataSetField.AttributeUseRestriction.Group = LimitedAvailability;
		DataSetField.AttributeUseRestriction.Condition = LimitedAvailability;
		DataSetField.AttributeUseRestriction.Order = LimitedAvailability;
		DataSetField.AttributeUseRestriction.Field = LimitedAvailability;
		
	EndDo;
	
EndProcedure

Procedure ConfigureLoggerTypes(TypeOfRebateOfRetroBonus, Var_DataCompositionSchema)
	
	TypesOfBonus = Enums.VendorRebateTypes;
	
	If TypeOfRebateOfRetroBonus = TypesOfBonus.Sales Then
		
		TypesOfLoggers = New Array; // Array of MetadataObjectDocument
		TypesOfLoggers.Add(Metadata.Documents.CustomerInvoice);
		TypesOfLoggers.Add(Metadata.Documents.SaleAdjustment);
		TypesOfLoggers.Add(Metadata.Documents.CustomerInvoiceServices);
		TypesOfLoggers.Add(Metadata.Documents.ReturnOfGoodsFromCustomer);
		
	ElsIf TypeOfRebateOfRetroBonus = TypesOfBonus.Purchases Then
		
		TypesOfLoggers = Reports.CalculateVendorRebates.TypesOfPurchaseSampleRegistrars();
	
	ElsIf TypeOfRebateOfRetroBonus = TypesOfBonus.Balance Then
		
		TypesOfLoggers = New Array; // Array of MetadataObjectDocument
	
	Else
		
		ErrorTemplate = NStr("vi = 'Sai loại thưởng ""%1""';
							|ru = 'Некорректный тип бонуса ""%1""';
							|en = 'Incorrect rebate type: ""%1""'; fa = 'Incorrect rebate type: ""%1""';
							|it = 'Некорректный тип бонуса ""%1""';
							|pl = 'Incorrect rebate type: ""%1""';
							|tr = '""%1"" bonus türü yanlış'");
		BonusTypeByString = String(TypeOfRebateOfRetroBonus);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, BonusTypeByString);
		Raise ErrorText;
		
	EndIf;
	
	TypesOfLoggerReferences = New Array; // Array of Type
	For Each RegistrarMetadata In TypesOfLoggers Do
		
		TypeOfRegistrarReference = Type("DocumentRef." + RegistrarMetadata.Name);
		TypesOfLoggerReferences.Add(TypeOfRegistrarReference);
		
	EndDo;
	
	DescriptionOfRegistrarTypes = New TypeDescription(TypesOfLoggerReferences);
	
	DataSet = Var_DataCompositionSchema.DataSets.Find("CalculateVendorRebates");
	LoggerField_ = DataSet.Fields.Find("DocumentRecorder");
	LoggerField_.ValueType = DescriptionOfRegistrarTypes;
	
EndProcedure

Function NamesOfDecryptionOptionsForDocuments()
	
	OptionsForDecodingDocuments = New Array; // Array of String
	OptionsForDecodingDocuments.Add("SalesTranscriptOfDocumentsForCustomers");
	OptionsForDecodingDocuments.Add("SalesTranscriptOfDocumentsSummary");
	OptionsForDecodingDocuments.Add("ProcurementTranscriptOfDocuments");
	Return OptionsForDecodingDocuments;
	
EndFunction

Function NamesOfTranscriptOptionsByNomenclature()
	
	DecryptionOptionsByItem = New Array; // Array of String
	DecryptionOptionsByItem.Add("SalesBreakdownByItemByCustomer");
	DecryptionOptionsByItem.Add("SalesBreakdownByNomenclatureByCustomersByRangesTable");
	DecryptionOptionsByItem.Add("SalesBreakdownByNomenclatureByCustomersByRangesByLines");
	Return DecryptionOptionsByItem;
	
EndFunction

Function NamesOfVariantsByRangesInStrings()
	
	OptionsForDecodingDocuments = New Array; // Array of String
	OptionsForDecodingDocuments.Add("SalesAreSummarizedByRangesByLines");
	OptionsForDecodingDocuments.Add("SalesBreakdownByNomenclatureByCustomersByRangesByLines");
	OptionsForDecodingDocuments.Add("PurchasesByRangesByLines");
	Return OptionsForDecodingDocuments;
	
EndFunction

Function NamesOfDecryptionParameters()
	
	ParameterNames = New Array; // Array of String
	ParameterNames.Add("CounterpartyCustomer");
	ParameterNames.Add("CounterpartySupplier");
	ParameterNames.Add("PartnerVendor");
	ParameterNames.Add("Partner");
	ParameterNames.Add("Counterparty");
	Return ParameterNames;
	
EndFunction

Function NamesOfUnavailableParameters(BonusType)
	
	ParameterNames = New Array; // Array of String
	
	If BonusType = Enums.VendorRebateTypes.Sales Then
		
		ParameterNames.Add("Partner");
		
	EndIf;
	
	If BonusType = Enums.VendorRebateTypes.Balance Then
		
		ParameterNames.Add("ReportPeriod");
		
	Else
		
		ParameterNames.Add("DateOfRemainingGoods");
		
	EndIf;
	
	Return ParameterNames;
	
EndFunction

Function KeyOfDecryptionOptionByItem(RebateConditionsParameters)
	
	BonusType = RebateConditionsParameters.BonusType;
	BonusTypePresentation = String(BonusType);
	TypesOfBonuses = Enums.VendorRebateTypes;
	TypesOfDetailingCalculationOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	
	If BonusType = TypesOfBonuses.Sales Then
		
		If RebateConditionsParameters.PartyCountDetails = TypesOfDetailingCalculationOfParticipants.EmptyRef() Then
			
			VariantKey = "";
			
		Else
			
			ReportVariant = VariantOfDecodingBySalesNomenclature(RebateConditionsParameters);
			VariantKey = ReportVariant.Name;
			
		EndIf;
		
	ElsIf BonusType = TypesOfBonuses.Purchases Then
		
		VariantKey = "";
		
	ElsIf BonusType = TypesOfBonuses.Balance Then
		
		VariantKey = "";
		
	Else
		
		ErrorTemplate = NStr("vi = 'Loại thưởng không xác định ""%1"" cho chứng từ ""%2""';
							|ru = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|en = 'Unknown rebate type (%1) for the %2 document'; fa = 'Unknown rebate type (%1) for the %2 document';
							|it = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|pl = 'Unknown rebate type (%1) for the %2 document';
							|tr = '""%2"" belgesi için ""%1"" bonus türü bilinmiyor'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			BonusTypePresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	Return VariantKey;
	
EndFunction

// Parameters:
//  RebateConditionsParameters - See RebatesCalculation.ParametersOfTermsOfRebatesOfSuppliers
// 
// Returns:
//  DataCompositionSettingsVariant
//
Function VariantOfDecodingAccordingToDocuments(RebateConditionsParameters)
	
	BonusType = RebateConditionsParameters.BonusType;
	BonusTypePresentation = String(BonusType);
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	PartyCountDetails = RebateConditionsParameters.PartyCountDetails;
	PartyCountDetailsPresentation = String(PartyCountDetails);
	TypesOfDetailingCalculationOfParticipants = Enums.ARAPAccountingDrilldownsOfRebatesParticipants;
	ReportOptions = DataCompositionSchema.SettingVariants;
	
	If BonusType = TypesOfBonuses.Sales Then
		
		If PartyCountDetails = TypesOfDetailingCalculationOfParticipants.ByCounterparty Then
			
			CompositeVersionOfReport = ReportOptions.SalesTranscriptOfDocumentsForCustomers;
			
		ElsIf PartyCountDetails = TypesOfDetailingCalculationOfParticipants.EmptyRef() Then
			
			CompositeVersionOfReport = ReportOptions.SalesTranscriptOfDocumentsSummary;
			
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
		
	ElsIf BonusType = TypesOfBonuses.Purchases Then
		
		CompositeVersionOfReport = ReportOptions.ProcurementTranscriptOfDocuments;
		
	ElsIf BonusType = TypesOfBonuses.Balance Then
		
		CompositeVersionOfReport = Undefined;
		
	Else
		
		ErrorTemplate = NStr("vi = 'Loại thưởng không xác định ""%1"" cho chứng từ ""%2""';
							|ru = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|en = 'Unknown rebate type (%1) for the %2 document'; fa = 'Unknown rebate type (%1) for the %2 document';
							|it = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|pl = 'Unknown rebate type (%1) for the %2 document';
							|tr = '""%2"" belgesi için ""%1"" bonus türü bilinmiyor'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			BonusTypePresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	Return CompositeVersionOfReport;
	
EndFunction

Function KeyOfDecryptionOptionForDocuments(RebateConditionsParameters)
	
	If RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Balance Then
		Return "";
	EndIf;
	
	ReportVariant = VariantOfDecodingAccordingToDocuments(RebateConditionsParameters);
	VariantKey = ReportVariant.Name;
	Return VariantKey;
	
EndFunction

Function KeyOfAccrualDecryptionOption(RebateConditionsParameters)
	
	BonusType = RebateConditionsParameters.BonusType;
	BonusTypePresentation = String(BonusType);
	TypesOfBonuses = Enums.VendorRebateTypes;
	
	If RebateConditionsParameters.BonusType = TypesOfBonuses.Sales Then
		VariantKey = "SalesByCustomers";
	ElsIf RebateConditionsParameters.BonusType = TypesOfBonuses.Purchases Then
		VariantKey = "Purchases";
	ElsIf RebateConditionsParameters.BonusType = TypesOfBonuses.Balance Then
		VariantKey = "Balance";
	ElsIf RebateConditionsParameters.WithoutCalculation Then
		VariantKey = "";
	Else
		
		ErrorTemplate = NStr("vi = 'Loại thưởng không xác định ""%1"" cho chứng từ ""%2""';
							|ru = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|en = 'Unknown rebate type (%1) for the %2 document'; fa = 'Unknown rebate type (%1) for the %2 document';
							|it = 'Неизвестный тип бонуса ""%1"" для документа ""%2""';
							|pl = 'Unknown rebate type (%1) for the %2 document';
							|tr = '""%2"" belgesi için ""%1"" bonus türü bilinmiyor'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTemplate,
			BonusTypePresentation,
			RebateConditionsParameters.DocumentTermsOfRetroBonusesPresentation);
		Raise ErrorText;
		
	EndIf;
	
	Return VariantKey;
	
EndFunction

Procedure ApplyParameterFromFormSettings(ReportSettings, ReportSettingsInForm, ParameterName)
	
	DetailsParameter = DataCompositionClientServer.GetParameter(ReportSettingsInForm, ParameterName);
	ParameterValue = DetailsParameter.Value;
	If TypeOf(ParameterValue) = Type("Structure") Then
		
		DataCompositionClientServer.SetParameter(
			ReportSettings, ParameterName, ParameterValue.RightValue, True);
		
	EndIf;
	
	DataCompositionClientServer.GetParameter(ReportSettings, ParameterName).Use = True;
	
EndProcedure

Procedure ApplyDecryptionParameters(RebateConditionsParameters, ReportSettings)
	
	BonusType = RebateConditionsParameters.BonusType;
	TypesOfBonus = Enums.VendorRebateTypes;
	
	If BonusType = TypesOfBonus.Sales Then
		
		Counterparty = DataCompositionClientServer.GetParameter(ReportSettings, "CounterpartyCustomer").Value;
		Partner = Catalogs.Partners.EmptyRef();
		
	ElsIf BonusType = TypesOfBonus.Purchases Then
		
		Counterparty = DataCompositionClientServer.GetParameter(ReportSettings, "CounterpartySupplier").Value;
		Partner = DataCompositionClientServer.GetParameter(ReportSettings, "PartnerVendor").Value; // CatalogRef.Partners
		
	Else
		
		ErrorTemplate = NStr("vi = 'Sai loại thưởng ""%1""';
							|ru = 'Некорректный тип бонуса ""%1""';
							|en = 'Incorrect rebate type: ""%1""'; fa = 'Incorrect rebate type: ""%1""';
							|it = 'Некорректный тип бонуса ""%1""';
							|pl = 'Incorrect rebate type: ""%1""';
							|tr = '""%1"" bonus türü yanlış'");
		BonusTypeByString = String(BonusType);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, BonusTypeByString);
		Raise ErrorText;
		
	EndIf;
	
	DataCompositionClientServer.SetParameter(ReportSettings, "Counterparty", Counterparty, True);
	DataCompositionClientServer.SetParameter(ReportSettings, "Partner", Partner, True);
	
EndProcedure

Function PerformanceMeasurementParameters(RebateConditionsParameters, OptionParameters)
	
	Result = New Structure;
	Result.Insert("ShouldRecord", True);
	Result.Insert("Divisor", 1);
	
	NameOfBonusType = Common.EnumerationValueName(RebateConditionsParameters.BonusType);
	If OptionParameters.ThisIsTranscriptOfNomenclature Then
		
		OptionType = "LayoutOfTranscriptByItem";
		Result.Divisor = 100;
		
	ElsIf OptionParameters.ThisIsTranscriptOfDocuments Then
		
		OptionType = "LayoutOfTranscriptAccordingToDocuments";
		Result.Divisor = 1;
		
	ElsIf OptionParameters.DetailsMode Then
		
		OptionType = "LayoutOfDecryption";
		Result.ShouldRecord = False;
		Result.Divisor = 100;
		
	Else
		
		OptionType = "LayoutOfMainVersion";
		
		If RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Sales Then
			Result.Divisor = 1;
		ElsIf RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Purchases Then
			Result.Divisor = 100;
		ElsIf RebateConditionsParameters.BonusType = Enums.VendorRebateTypes.Balance Then
			Result.Divisor = 100;
		Else
			
			ErrorTemplate = NStr("vi = 'Loại thưởng không xác định ""%1""';
								|ru = 'Неизвестный тип бонуса ""%1""';
								|en = 'Unknown rebate type: %1'; fa = 'Unknown rebate type: %1';
								|it = 'Неизвестный тип бонуса ""%1""';
								|pl = 'Unknown rebate type: %1';
								|tr = '""%1"" bonus türü bilinmiyor'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,NameOfBonusType);
			Raise ErrorText;
			
		EndIf;
		
	EndIf;
	
	KeyOperation = StrTemplate(
		"Report.CalculateVendorRebates.ObjectModule.OnComposeResult.%1.%2",
		OptionType,
		NameOfBonusType);
	Result.Insert("KeyOperation", KeyOperation);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf