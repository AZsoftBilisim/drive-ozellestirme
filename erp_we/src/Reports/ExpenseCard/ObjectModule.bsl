// @strict-types


#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

#EndRegion

#Region Public

// Code of procedures and functions

#EndRegion

#Region EventHandlers

// Code of procedures and functions

#EndRegion

#Region Internal

// Code of procedures and functions

#EndRegion

#Region Private

// Code of procedures and functions
// Settings of the general report form of the "Report Options" subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.DefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary								- parameters of the context in which the report is used.
//	SchemaKey							- String									- ID of the current configuration Builder schema.
//	VariantKey						- String									- name of the predefined or unique ID of the custom
//																						version of the report.
//										- Undefined 								- a call for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		ReportDataParameter = DataCompositionSchema.Parameters.Find("ReportData");
		ChoiceList = New ValueList;
		ChoiceList.Add(0, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị';
								|ru = 'В валюте упр. учета';
								|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
								|it = 'В валюте упр. учета';
								|pl = 'W walucie ewidencji zarządczej';
								|tr = 'Yönetim muhasebesi para biriminde'"));
		ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán doanh nghiệp';
								|ru = 'В валюте бух. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'В валюте бух. учета';
								|pl = 'In local accounting currency';
								|tr = 'Genel muhasebe para biriminde'"));
		
		ReportDataParameter.SetAvailableValues(ChoiceList);
		
		If NewDCSettings = Undefined
			Or NewDCUserSettings = Undefined Then
			Return;
		EndIf;
		
		ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ReportData"));
		ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
		If Not ConfiguringReportData = Undefined
			And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
			ConfiguringReportData.Value = ChoiceList[0].Value;
		EndIf;
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Initialize

#EndRegion

#EndIf
