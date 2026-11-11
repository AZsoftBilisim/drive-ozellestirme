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
	
	Terms = DataCompositionClientServer.GetParameter(ReportSettings, "Terms").Value;  // CatalogRef.TermsOfSale
	
	If Terms = Undefined Then
		
		ErrorText = NStr("vi = 'Chưa chọn thỏa thuận';
						|ru = 'Не выбрано соглашение';
						|en = 'Terms of sales are not selected'; fa = 'Terms of sales are not selected';
						|it = 'Не выбрано соглашение';
						|pl = 'Terms of sales are not selected';
						|tr = 'Anlaşma seçilmedi'");
		Raise ErrorText;
		
	EndIf;
	
	AddParametersByAgreement(ReportSettings, Terms);
	SetReportTitle(ReportSettings, Terms);
	
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
	
	If VariantKey = "CurrentRetroRebatesByAgreementContext" Then
		
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
//   DCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//   UserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings Composer after it is initialized.
//       Undefined when user settings do not need to be loaded (already loaded earlier).
//
Procedure FillInParametersByContext(CommandParameter, DCSettings, UserSettings = Undefined)
	
	CommandParameterType = TypeOf(CommandParameter);
	
	If CommandParameterType = Type("CatalogRef.TermsOfSale") Then
		
		DataCompositionClientServer.SetParameter(DCSettings, "Terms", CommandParameter);
		If UserSettings <> Undefined Then
			
			DataCompositionClientServer.SetParameter(
				UserSettings,
				"Terms", 
				CommandParameter);
			
		EndIf;
		
		DateEmpty = Date(1, 1, 1);
		
		Period = New StandardPeriod;
		Period.Variant = StandardPeriodVariant.Custom;
		Period.StartDate = DateEmpty;
		Period.EndDate = DateEmpty;
		
		DataCompositionClientServer.SetParameter(
			DCSettings,
			"Period",
			Period,
			False);
		If UserSettings <> Undefined Then
			
			DataCompositionClientServer.SetParameter(
				UserSettings,
				"Period",
				Period,
				False);
				
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the parameters by agreement.
// 
// Parameters:
//  DCSettings - DataCompositionSettings
//  Terms - CatalogRef.TermsOfSale
//
Procedure AddParametersByAgreement(DCSettings, Terms)
	
	Query = New Query;
	Query.SetParameter("Ref", Terms);
	Query.Text =
	"SELECT ALLOWED
	|	TermsOfSale.Standard_ AS StandardAgreement,
	|	TermsOfSale.Terms AS ParentAgreement,
	|	ISNULL(AgreementsWithClientsParent.Standard_, FALSE) AS ParentStandardAgreement,
	|	TermsOfSale.Counterparty AS Counterparty,
	|	TermsOfSale.Partner AS Partner
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		LEFT JOIN Catalog.TermsOfSale AS AgreementsWithClientsParent
	|		ON TermsOfSale.Terms = AgreementsWithClientsParent.Ref
	|WHERE
	|	TermsOfSale.Ref = &Ref"; 
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	StandardAgreement = Selection.StandardAgreement;
	ParentAgreement = Selection.ParentAgreement;
	ParentStandardAgreement = Selection.ParentStandardAgreement;
	Counterparty = Selection.Counterparty;
	Partner = Selection.Partner;
	
	DataCompositionClientServer.SetParameter(DCSettings, "StandardAgreement", StandardAgreement);
	DataCompositionClientServer.SetParameter(DCSettings, "ParentAgreement", ParentAgreement);
	DataCompositionClientServer.SetParameter(DCSettings, "ParentStandardAgreement", ParentStandardAgreement);
	DataCompositionClientServer.SetParameter(DCSettings, "Counterparty", Counterparty);
	DataCompositionClientServer.SetParameter(DCSettings, "Partner", Partner);
	
	SetFieldsUsage(DCSettings, StandardAgreement);
	
EndProcedure

Procedure SetFieldsUsage(DCSettings, Standard_)
	
	FieldsProcessed = New Array;  // Array of DataCompositionField
	FieldsProcessed.Add(New DataCompositionField("Counterparty"));
	FieldsProcessed.Add(New DataCompositionField("Partner"));
	FieldsProcessed.Add(New DataCompositionField("Terms"));
	
	For Each Item In DCSettings.Selection.Items Do
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			
			If FieldsProcessed.Find(Item.Field) <> Undefined Then
				Item.Use = Not Standard_;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets the title of the report.
// 
// Parameters:
//  ReportSettings - DataCompositionSettings - report settings
//  Terms - CatalogRef.TermsOfSale
//
Procedure SetReportTitle(ReportSettings, Terms)

	Template = NStr("vi = 'Thưởng lũy kế đang có hiệu lực theo thỏa thuận ""%1""';
					|ru = 'Действующие ретро-бонусы по соглашению ""%1""';
					|en = 'Active rebates by the ""%1"" terms of sales'; fa = 'Active rebates by the ""%1"" terms of sales';
					|it = 'Действующие ретро-бонусы по соглашению ""%1""';
					|pl = 'Active rebates by the ""%1"" terms of sales';
					|tr = 'Anlaşmaya göre geçerli retro-bonuslar ""%1""'");
	StringAgreement = String(Terms);
	ReportHeader = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		StringAgreement);
		
	DataCompositionClientServer.SetOutputParameter(ReportSettings, "Title", ReportHeader);
	
EndProcedure 

#EndRegion

#EndIf