#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	ChartOfAccountsParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ChartOfAccounts");
	OptionForGeneratingTransactions = Undefined;
	If ChartOfAccountsParameter <> Undefined And ValueIsFilled(ChartOfAccountsParameter.Value) Then
		ChartOfAccounts = ChartOfAccountsParameter.Value; // CatalogRef.FinancialAccountingChartsOfAccounts -
		OptionForGeneratingTransactions = Common.ObjectAttributeValue(ChartOfAccounts, "OptionForGeneratingTransactions");
	EndIf;
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			
		DataCompositionServer.DisableSelectedFieldInUserSettings(SettingsComposer, "DimensionDr");
		DataCompositionServer.DisableSelectedFieldInUserSettings(SettingsComposer, "DimensionCr");
		DataCompositionServer.DisableSelectedFieldInUserSettings(SettingsComposer, "AccountDr");
		DataCompositionServer.DisableSelectedFieldInUserSettings(SettingsComposer, "AccountCr");
			
		DataCompositionServer.EnableSelectedFieldInUserSettings(SettingsComposer, "Dimension");
		DataCompositionServer.EnableSelectedFieldInUserSettings(SettingsComposer, "Account");
		
		CurrencyDrResourceField = DataCompositionSchema.CalculatedFields.Find("DtCurrencyResource");
		If CurrencyDrResourceField <> Undefined And CurrencyDrResourceField.Expression <> "Currency" Then
			CurrencyDrResourceField.Expression = "Currency";
		EndIf;
		
		CurrencyCrResourceField = DataCompositionSchema.CalculatedFields.Find("CtCurrencyResource");
		If CurrencyCrResourceField <> Undefined And CurrencyCrResourceField.Expression <> "Currency" Then
			CurrencyCrResourceField.Expression = "Currency";
		EndIf;
		
	Else
		
		DataCompositionServer.EnableSelectedFieldInUserSettings(SettingsComposer, "DimensionDr");
		DataCompositionServer.EnableSelectedFieldInUserSettings(SettingsComposer, "DimensionCr");
		DataCompositionServer.EnableSelectedFieldInUserSettings(SettingsComposer, "AccountDr");
		DataCompositionServer.EnableSelectedFieldInUserSettings(SettingsComposer, "AccountCr");
		
		DataCompositionServer.DisableSelectedFieldInUserSettings(SettingsComposer, "Dimension");
		DataCompositionServer.DisableSelectedFieldInUserSettings(SettingsComposer, "Account");
		
		CurrencyDrResourceField = DataCompositionSchema.CalculatedFields.Find("DtCurrencyResource");
		If CurrencyDrResourceField <> Undefined And CurrencyDrResourceField.Expression <> "CurrencyDr" Then
			CurrencyDrResourceField.Expression = "CurrencyDr";
		EndIf;
		
		CurrencyCrResourceField = DataCompositionSchema.CalculatedFields.Find("CtCurrencyResource");
		If CurrencyCrResourceField <> Undefined And CurrencyCrResourceField.Expression <> "CurrencyCr" Then
			CurrencyCrResourceField.Expression = "CurrencyCr";
		EndIf;
		
	EndIf;
	
	If SettingsComposer.UserSettings.AdditionalProperties.VariantKey = "AccountCardFinancialAccounting" Then
		
		AccountField = New DataCompositionField("Account");
		For Each FilterElement In SettingsComposer.GetSettings().Filter.Items Do
			If FilterElement.LeftValue = AccountField And FilterElement.Use Then
				ZeroInitialRemainder = DataCompositionSchema.CalculatedFields.Find("CountOpeningBalance");
				ZeroFiniteRemainder 	= DataCompositionSchema.CalculatedFields.Find("CountClosingBalance");
				DataCompositionSchema.CalculatedFields.Delete(ZeroInitialRemainder);
				DataCompositionSchema.CalculatedFields.Delete(ZeroFiniteRemainder);
				Break;
			EndIf; 
		EndDo;
		
	EndIf;
	
	InternationalReportingServer.OnComposeResult(DataCompositionSchema, SettingsComposer, ResultDocument, DetailsData, StandardProcessing);
	
	If SettingsComposer.UserSettings.AdditionalProperties.VariantKey = "AccountCardFinancialAccounting" Then
		
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Dư đầu';
																			|ru = 'Сальдо на начало';
																			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
																			|it = 'Saldo iniziale';
																			|pl = 'Saldo na koniec';
																			|tr = 'Dönem başı bakiyesi'"));
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Dư cuối';
																			|ru = 'Сальдо на конец';
																			|en = 'Closing balance'; fa = 'مانده پایان دوره';
																			|it = 'Saldo finale';
																			|pl = 'Saldo na koniec';
																			|tr = 'Dönem sonu bakiyesi'"));
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Phát sinh bên Nợ';
																			|ru = 'Оборот Дт';
																			|en = 'Dr turnover'; fa = 'گردش بدهکار';
																			|it = 'Fatturato a debito';
																			|pl = 'Obrót Wn';
																			|tr = 'Borç Cirosu'"));
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Phát sinh bên Có';
																			|ru = 'Оборот Кт';
																			|en = 'Cr turnover'; fa = 'گردش بستانکار';
																			|it = 'Fatturato a credito';
																			|pl = 'obrót Ma';
																			|tr = 'Alacak ciro'"));
		
	ElsIf SettingsComposer.UserSettings.AdditionalProperties.VariantKey = "SummaryTransactions" Then
		
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Nợ';
																			|ru = 'Дебет';
																			|en = 'Debit'; fa = 'بدهکار';
																			|it = 'Debito';
																			|pl = 'Debet';
																			|tr = 'Borç'"));
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Có';
																			|ru = 'Кредит';
																			|en = 'Credit'; fa = 'بستانکار';
																			|it = 'Credito';
																			|pl = 'Ma';
																			|tr = 'Alacak'"));
		
	ElsIf SettingsComposer.UserSettings.AdditionalProperties.VariantKey = "TransactionReportInternational" Then
		
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Phát sinh bên Nợ';
																			|ru = 'Оборот Дт';
																			|en = 'Dr turnover'; fa = 'گردش بدهکار';
																			|it = 'Fatturato a debito';
																			|pl = 'Obrót Wn';
																			|tr = 'Borç Cirosu'"));
		InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Phát sinh bên Có';
																			|ru = 'Оборот Кт';
																			|en = 'Cr turnover'; fa = 'گردش بستانکار';
																			|it = 'Fatturato a credito';
																			|pl = 'obrót Ma';
																			|tr = 'Alacak ciro'"));
		
	EndIf;
	
EndProcedure

Function ConfigureDataLayoutScheme()
	
	Union = DataCompositionSchema.DataSets.Union; // DataCompositionSchemaDataSetUnion -
	SchemeHasBeenChanged = False;
	If Not GetFunctionalOption("FinancialAccountingEntriesWithCorrespondence") Then
		DataSet = Union.Items.Find("TransactionsWithCorrespondence");
		If DataSet <> Undefined Then
			Union.Items.Delete(DataSet);
			SchemeHasBeenChanged = True;
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("FinancialAccountingEntriesWithoutCorrespondence") Then
		DataSet = Union.Items.Find("TransactionsWithoutCorrespondence");
		If DataSet <> Undefined Then
			Union.Items.Delete(DataSet);
			SchemeHasBeenChanged = True;
		EndIf;
	EndIf;
	Return SchemeHasBeenChanged;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer) Export
	
	If Not GetFunctionalOption("FinancialAccountingEntriesWithCorrespondence") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "BalancedAccount");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "BalancedExtDimension1");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "BalancedExtDimension2");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "BalancedExtDimension3");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "DebitBusinessUnit");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "CorLineOfBusiness");
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "CorrespondingCurency");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Organization");
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
	
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	
EndProcedure

// Called in the report form before displaying the settings.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form.
//   SettingProperties - Structure - Description of the report settings that will be displayed in the report form:
//       * TypeDescription - TypeDescription - type of setting.
//       
//       * ValuesForSelection - ValueList - objects that will be offered to the user in
//         the selection list. Complements the list of objects already selected by the user earlier.
//       * SelectionValuesQuery - Query - returns objects that need to be supplemented with the values for the selection.
//           The first column (with the 0 index) should select the object
//           to be added to the values for the selection.Meaning.
//           To disable autofill
//           in the Request value property of the selection.The text should be written as an empty string.
//       * RestrictSelectionBySpecifiedValues - Boolean - When True, the user's choice will be
//           limited to the values specified in the value for the selection (its final state).
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	
	If TypeOf(Form) = Type("ClientApplicationForm")
	   And Form.CurrentVariantKey = "SummaryTransactions" Then
		If SettingProperties.DCField = New DataCompositionField("DataParameters.ChartOfAccounts") Then
			SettingProperties.ValuesForSelection = Catalogs.FinancialAccountingChartsOfAccounts.ChartOfAccountsWithTransactionsAndCorrespondence();
			SettingProperties.RestrictSelectionBySpecifiedValues = True;
		EndIf;
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
// See ReportsOverridable.BeforeLoadVariantAtServer.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
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
//       Used for optimization to reinitialize the linker as rarely as possible.
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings builder after its initialization.
//       It is uncertain when the user settings do not need to be loaded (already loaded earlier).
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	SchemeHasBeenChanged = ConfigureDataLayoutScheme();
	
	If SchemeHasBeenChanged Then
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
