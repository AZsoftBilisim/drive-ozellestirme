
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure - may contain properties:
//				** CommandParameter -  CatalogRef.Assets, CatalogRef.ConstructionObjects, CatalogRef.IntangibleAssets, CatalogRef.RDTopicsStages -
//				** CommandDetails - Structure - may contain properties:
//					*** AdditionalParameters - Structure - 
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;

	If Parameters.Property("CommandParameter") Then 

		CommandDetails = Parameters.CommandDetails; //Structure - 
		ReportParameters = New Structure();
		ReportParameters.Insert("Object", Parameters.CommandParameter);
		If CommandDetails.Property("AdditionalParameters") Then
			AdditionalParameters = Parameters.CommandDetails.AdditionalParameters;
			ReportParameters.Insert("CommandName", AdditionalParameters.CommandName);
		EndIf;

		ThisForm.ReportSettings.Insert("ReportParameters", ReportParameters);
		ThisForm.ReportSettings.OptionSelectionAllowed = True;
		ThisForm.ReportSettings.EditOptionsAllowed = True;
	
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible).
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
//			If the type of VHF(KD element) = Type("Parameter setter values") Then
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
//	The end is here.
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		If NewDCUserSettings = Undefined Then
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, Context.Report.SettingsComposer.UserSettings);
		Else
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		EndIf;
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
		FormSettingsComposer = Context.Report.SettingsComposer;
		Parameters = Context.Parameters;
		
		If Parameters.Property("UserParameters") Then
			DataCompositionClientServer.AddParametersToUserSettings(FormSettingsComposer, Parameters.UserParameters);
			NewDCUserSettings = FormSettingsComposer.UserSettings;
		EndIf;
		
		ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	Object = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Object")).Value;
	If TypeOf(Object) = Type("CatalogRef.IntangibleAssets") Then	
		QueryText = RDExpensesAccounting.RequestTextIACapitalizationStructure();
		ConfigureSelectedDataLayoutFields(ReportSettings, True);
	Else
		QueryText = RDExpensesAccounting.QueryTextCapitalizationStructure();
		ConfigureSelectedDataLayoutFields(ReportSettings, TypeOf(Object) = Type("CatalogRef.IntangibleAssets"));
	EndIf;
	
	DataCompositionSchema.DataSets.Main.Query = QueryText;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	SpreadsheetDocument = OutputProcessor.EndOutput();
		
	// delete the service texts
	
	ReplacementTextExtended = "%1% And
						|";
	ReplacementTextWithoutExtension = "%1%";
	
	ExtendedArea = SpreadsheetDocument.FindText(ReplacementTextExtended);
	AreaWithoutExtension = SpreadsheetDocument.FindText(ReplacementTextWithoutExtension);
	If ExtendedArea <> Undefined Then
		ExtendedArea.Text = StrReplace(ExtendedArea.Text, ReplacementTextExtended, "");
	ElsIf AreaWithoutExtension <> Undefined Then
		AreaWithoutExtension.Text = StrReplace(AreaWithoutExtension.Text, ReplacementTextWithoutExtension, "");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Configures the available values for the data layout parameters, depending on the selected configuration option.
// 
// Parameters:
//	Document - Document Link.Distribution of labor costs - a decoding document.
//	NewDCSettings - DataCompositionSettings - overriding the report settings.
//	NewDCUserSettings - DataCompositionUserSettings - data layout scheme settings.
//
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
		
	OptionsKeys = KeysOfPredefinedOptions();
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	PredefinedOptionKey = Common.ObjectAttributeValue(PredefinedOption, "VariantKey");
	If Not ValueIsFilled(PredefinedOption) 
		Or OptionsKeys.Find(PredefinedOptionKey) = Undefined Then
		Return;
	EndIf;
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("DataByCost");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
		
	ChoiceList = New ValueList;

	If PredefinedOptionKey = "EnterpriseCostStructure" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	Else
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
	EndIf;
	
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	If ReportSettings.Property("ReportParameters") Then
		DataCompositionClientServer.SetParameter(NewDCUserSettings, "Object", ReportSettings.ReportParameters.Object);
		DataCompositionClientServer.SetParameter(NewDCSettings, "Object", ReportSettings.ReportParameters.Object);
	EndIf;
	
	Value_CostDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("DataByCost"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(Value_CostDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = KeysOfPredefinedOptions();
	
	While OptionsKeys.Find(Variant.VariantKey) = Undefined
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

Function KeysOfPredefinedOptions()
	
	OptionsKeys = New Array;
	OptionsKeys.Add("CostStructure_");
	OptionsKeys.Add("EnterpriseCostStructure");
	
	Return OptionsKeys;
	
EndFunction

Procedure ConfigureSelectedDataLayoutFields(ReportSettings, IAReport = False)
	
	DataByCost = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("DataByCost")).Value;
	
	IAFields = IADataFields();
	LocalFields = LocalDataFields();
	
	SelectedFields = ReportSettings.Selection.Items;

	For Each SelectedField In SelectedFields Do 
		If IAFields.Find(String(SelectedField.Field)) <> Undefined Then
			SelectedField.Use = IAReport;
		EndIf;
		If LocalFields.Find(String(SelectedField.Field)) <> Undefined Then
			SelectedField.Use = DataByCost = 3;
		EndIf;
	EndDo;
	
	Filters = ReportSettings.Filter.Items;
	For Each FilterElement In Filters Do
		If FilterElement.Presentation = "%1%" Then
			For Each Item In FilterElement.Items Do
				If LocalFields.Find(String(Item.LeftValue)) <> Undefined Then
					Item.Use = DataByCost = 3;
				EndIf;
			EndDo;
		EndIf;
	EndDo;

EndProcedure

Function IADataFields()
	
	DataFields = New Array;
	DataFields.Add("TopicStage");
	
	Return DataFields;
	
EndFunction

Function LocalDataFields()
	
	DataFields = New Array;
	DataFields.Add("AmountPermanentDifferences");
	DataFields.Add("AmountTemporaryDifferences");
	DataFields.Add("AmountFA");
	
	Return DataFields;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = LocalDataFields();
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf