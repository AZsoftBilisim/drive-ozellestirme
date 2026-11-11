//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	PeriodIsSpecified = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Period").Use;
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "PeriodIsSpecified", PeriodIsSpecified, PeriodIsSpecified);
	
	CommentCompleted = NStr("vi = 'Việc tính toán theo điều kiện bị đóng, thì sẽ không tính chênh lệch vào cuối kỳ';
							|ru = 'Расчеты по условию закрыты, расхождение на конец периода не рассчитывается';
							|en = 'Settlement on the condition are closed, the discrepancy at the end of the period is not calculated'; fa = 'Settlement on the condition are closed, the discrepancy at the end of the period is not calculated';
							|it = 'Расчеты по условию закрыты, расхождение на конец периода не рассчитывается';
							|pl = 'Settlement on the condition are closed, the discrepancy at the end of the period is not calculated';
							|tr = 'Şartlara göre alacak/borç muhasebeleri kapalıdır, dönem sonu tutarsızlığı hesaplanamamaktadır'");
	DataCompositionClientServer.SetParameter(
		MainCircuitSettings,
		"CommentCompleted",
		CommentCompleted);
	
	CommentEmptyCondition = NStr("vi = 'Biên bản không có điều kiện, không tính chênh lệch';
								|ru = 'Акты без условий, расхождения не рассчитываются';
								|en = 'Certificates without conditions, discrepancies are not calculated'; fa = 'Certificates without conditions, discrepancies are not calculated';
								|it = 'Акты без условий, расхождения не рассчитываются';
								|pl = 'Certificates without conditions, discrepancies are not calculated';
								|tr = 'Şartsız eylemler, tutarsızlıklar hesaplanmıyor'");
	DataCompositionClientServer.SetParameter(
		MainCircuitSettings,
		"CommentEmptyCondition",
		CommentEmptyCondition);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert(
			"UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
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
	
	If VariantKey = "ListOfSuppliersRebatesContext" Then
		
		Settings.GenerateImmediately = True;
		Settings.EditOptionsAllowed = False;
		
	EndIf;
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnDefineSettingsFormItemsProperties = True;
	Settings.Events.BeforeFormationReport = True;
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	DisplayCommentInHeader = True;
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ConditionsOfVendorRebates") Then
			
			DisplayCommentInHeader = False;
			ConditionsOfVendorRebates = Parameters.CommandParameter; // DocumentRef.ConditionsOfVendorRebates
			
			Attributes = "Patch, CorrectedDocument";
			AttributesValues = Common.ObjectAttributesValues(ConditionsOfVendorRebates, Attributes);
			
			If AttributesValues.Patch = True Then
				SourceDocument_ = AttributesValues.CorrectedDocument;
			Else
				SourceDocument_ = ConditionsOfVendorRebates;
			EndIf;
			
			Form.ParametersForm.Filter = New Structure("TermDocument", SourceDocument_);
			Form.ReportSettings.OptionSelectionAllowed = False;
			
		ElsIf TypeOf(Parameters.CommandParameter) = Type("DocumentRef.VendorBonusCertificate") Then
			
			VendorBonusCertificate = Parameters.CommandParameter; // DocumentRef.VendorBonusCertificate
			SetSelectionsBasedOnAct(Form, VendorBonusCertificate);
			FormDetailsToAdd = New Array(); // Array of FormAttribute
			
			AttributeType = New TypeDescription("DocumentRef.VendorBonusCertificate");
			AttributeName = "VendorBonusCertificate";
			
			NewAttribute = New FormAttribute(AttributeName, AttributeType);
			FormDetailsToAdd.Add(NewAttribute);
			
			Form.ChangeAttributes(FormDetailsToAdd);
			
			CommonClientServer.SetFormAttributeByPath(Form, AttributeName, VendorBonusCertificate);
			
		EndIf;
		
	EndIf;
	
	If DisplayCommentInHeader Then
		
		FormDetailsToAdd = New Array(); // Array of FormAttribute
		
		StringType = New TypeDescription("String");
		AttributeName = "CommentInHeader";
		
		AttributeOfCommentInHeader = New FormAttribute(AttributeName, StringType);
		FormDetailsToAdd.Add(AttributeOfCommentInHeader);
		
		Form.ChangeAttributes(FormDetailsToAdd);
		CommentInHeader = LineCalculationsAreRelevant();
		
		CommonClientServer.SetFormAttributeByPath(Form, AttributeName, CommentInHeader);
		
		Items = Form.Items;
		
		If Items.Find("CommandsAndIndicators") <> Undefined Then
			NewItem = Items.Insert(AttributeName, Type("FormField"),, Items.CommandsAndIndicators);
		Else
			NewItem = Items.Insert(AttributeName, Type("FormField"));
		EndIf;
		NewItem.Type = FormFieldType.LabelField;
		NewItem.DataPath = AttributeName;
		NewItem.TitleLocation = FormItemTitleLocation.None;
		NewItem.AutoMaxWidth = False;
		NewItem.TextColor = StyleColors.HyperlinkColor;
		
	EndIf;
	
EndProcedure

// Called after defining the properties of form elements associated with user settings.
// See ReportsServer.SettingsFormItemsProperties()
// Allows you to override properties for the purpose of personalization of the report.
//
// Parameters:
//  FormType - ReportFormType - see Syntax Assistant
//  ItemsProperties - See ReportsServer.SettingsFormItemsProperties
//  UserSettings - DataCompositionUserSettingsItemCollection - elements of current
//                              user settings that affect the creation of related form elements.
//
Procedure OnDefineSettingsFormItemsProperties(FormType, ItemsProperties, UserSettings) Export
	
	If FormType <> ReportFormType.Main Then 
		Return;
	EndIf;
	
	DataCompositionField = New DataCompositionField("Partner");
	
	FieldTable = ItemsProperties.Fields;
	FieldTable.Columns.Add("ChoiceParameters", New TypeDescription("FixedArray"));
	
	For Each FieldProperties In FieldTable Do
		
		If TypeOf(FieldProperties.SettingDetails) = Type("DataCompositionFilterAvailableField")
		   And FieldProperties.SettingDetails.Field = DataCompositionField Then
			
			ChoiceParameters = New Array; // Array of ChoiceParameter
			Parameter = New ChoiceParameter("Filter.Vendor", True); 
			ChoiceParameters.Add(Parameter);
			
			FieldProperties.ChoiceParameters = New FixedArray(ChoiceParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  ReportForm - ClientApplicationForm
//  AdditionalParameters - Structure:
//   * WarningText - String
//   * StorageParameterNameWarningDisclaimer - String
//
Procedure BeforeFormationReport(ReportForm, AdditionalParameters) Export
	
	If CommonClientServer.HasAttributeOrObjectProperty(ReportForm, "CommentInHeader") Then
		
		CommentInHeader = LineCalculationsAreRelevant();
		
		CommonClientServer.SetFormAttributeByPath(
			ReportForm, "CommentInHeader", CommentInHeader);
		
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(ReportForm, "VendorBonusCertificate") Then
		
		VendorBonusCertificate = ReportForm.VendorBonusCertificate; // DocumentRef.VendorBonusCertificate
		SetSelectionsBasedOnAct(ReportForm, VendorBonusCertificate);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function LineCalculationsAreRelevant()
	
	TooltipText = NStr("vi = 'Đã cập nhật trạng thái hạch toán theo chứng từ ""Điều kiện thưởng lũy kế của nhà cung cấp""';
						|ru = 'Данные статусов расчетов по документам ""Условия ретро-бонусов поставщиков"" актуальны';
						|en = 'Data on settlement statuses for the ""Conditions of vendor rebates"" documents are relevant'; fa = 'Data on settlement statuses for the ""Conditions of vendor rebates"" documents are relevant';
						|it = 'Данные статусов расчетов по документам ""Условия ретро-бонусов поставщиков"" актуальны';
						|pl = 'Data on settlement statuses for the ""Conditions of vendor rebates"" documents are relevant';
						|tr = '""Tedarikçi retro bonuslarının şartları"" belgeleri için alacak/borç muhasebesi durum verileri günceldir'");
	
	Return TooltipText;
	
EndFunction

// Parameters:
//  Form - ClientApplicationForm
//  VendorBonusCertificate - DocumentRef.VendorBonusCertificate
//
Procedure SetSelectionsBasedOnAct(Form, VendorBonusCertificate)
	
	Filter = New Structure;
	Filter.Insert("Organization", Catalogs.Companies.EmptyRef());
	Filter.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	
	DataForFilter = ActData(VendorBonusCertificate);
	HeaderData_ = DataForFilter.HeaderData_;
	TermsDocuments = DataForFilter.TermsDocuments;
	
	ConditionDocumentsList = New ValueList;
	ConditionDocumentsList.LoadValues(TermsDocuments);
	If HeaderData_.Next() Then
		
		FillPropertyValues(Filter, HeaderData_);
		
	EndIf;
	Filter.Insert("TermDocument", ConditionDocumentsList);
	
	Form.ParametersForm.Filter = Filter;
	Form.ReportSettings.OptionSelectionAllowed = False;
	
	NewSettings1 = SettingsComposer.GetSettings();
	CommonClientServer.SetFilterItem(
		NewSettings1.Filter,
		"Counterparty",
		Filter.Counterparty,
		DataCompositionComparisonType.Equal,
		,
		True);
		
	CommonClientServer.SetFilterItem(
		NewSettings1.Filter,
		"Organization",
		Filter.Organization,
		DataCompositionComparisonType.Equal,
		,
		True);
		
	CommonClientServer.SetFilterItem(
		NewSettings1.Filter,
		"TermDocument",
		ConditionDocumentsList,
		DataCompositionComparisonType.InList,
		,
		True);
		
	SettingsComposer.LoadSettings(NewSettings1);
	
EndProcedure

// Act data.
// 
// Parameters:
//  VendorBonusCertificate - DocumentRef.VendorBonusCertificate - 
// 
// Returns:
//  Structure - Act Data:
// * HeaderData_ - QueryResultSelection:
//   ** Organization - CatalogRef.Companies
//   ** Counterparty - CatalogRef.Counterparties
// * TermsDocuments - Array of DocumentRef.ConditionsOfVendorRebates
// 
Function ActData(VendorBonusCertificate)
	
	Query = New Query;
	Query.SetParameter("Ref", VendorBonusCertificate);
	Query.Text = 
	"SELECT
	|	VendorBonusCertificate.Organization AS Organization,
	|	VendorBonusCertificate.Counterparty AS Counterparty
	|FROM
	|	Document.VendorBonusCertificate AS VendorBonusCertificate
	|WHERE
	|	VendorBonusCertificate.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorBonusCertificateRebates.TermDocument AS TermDocument
	|FROM
	|	Document.VendorBonusCertificate.Rebates AS VendorBonusCertificateRebates
	|WHERE
	|	VendorBonusCertificateRebates.Ref = &Ref";
	
	Result = Query.ExecuteBatch();
	
	HeaderData_ = Result[0].Select();
	TermsDocuments = Result[1].Unload().UnloadColumn("TermDocument");
	
	Data = New Structure;
	Data.Insert("HeaderData_", HeaderData_);
	Data.Insert("TermsDocuments", TermsDocuments);
	
	Return Data;
	
EndFunction

#EndRegion

#EndIf