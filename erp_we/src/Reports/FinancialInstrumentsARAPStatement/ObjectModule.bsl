#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.Filter = New Structure;
		ThisForm.ParametersForm.Filter.Insert("Contract", Parameters.CommandParameter);
		
		ThisForm.ParametersForm.PurposeUseKey = "Contract";
		Parameters.PurposeUseKey = "Contract";
		
		Query = New Query;
		Query.Text = "
		|SELECT DISTINCT
		|	ContractKind
		|FROM
		|	Catalog.LoanAndDepositContracts
		|WHERE
		|	Ref IN (&Contracts)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ContractKind
		|FROM
		|	Catalog.LeaseContract
		|WHERE
		|	Ref IN (&Contracts)
		|";
		
		Query.SetParameter("Contracts", Parameters.CommandParameter);
		
		ListOfFinancialInstruments = New ValueList;
		ListOfFinancialInstruments.LoadValues(Query.Execute().Unload().UnloadColumn("ContractKind"));
		
		ThisForm.ParametersForm.Filter.Insert("FinancialInstrument", ListOfFinancialInstruments);
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	ConfigureDefaultSelectionParameters(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region EventHandlers

#EndRegion

#Region Private

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	AvailableCDParameters = FormSettingsComposer.Settings.DataParameters.AvailableParameters; // DataCompositionAvailableParameters 
	
	FinancialInstrumentParameter = AvailableCDParameters.Items.Find("FinancialInstrument");
	If FinancialInstrumentParameter <> Undefined Then
		
		ListOfFinancialInstruments = FinancialInstrumentParameter.AvailableValues;
		ListOfFinancialInstruments.Clear();
		
		If GetFunctionalOption("UseLoanAndDepositContracts") Then
			ListOfFinancialInstruments.Add(
				Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing, NStr("vi = 'Nhận tín dụng hoặc các khoản vay';
																				|ru = 'Кредиты или займы полученные';
																				|en = 'Received credits or loans'; fa = 'اعتبارات یا وام‌های دریافتی';
																				|it = 'Crediti o prestiti ricevuti';
																				|pl = 'Otrzymane kredyty lub pożyczki';
																				|tr = 'Alınan borç ve krediler'"));
			ListOfFinancialInstruments.Add(
				Enums.ContractKindsOfFinancialInstruments.Deposit, NStr("vi = 'Tiền gửi (deposit)';
																		|ru = 'Депозит';
																		|en = 'Deposit'; fa = 'ودیعه';
																		|it = 'Deposito';
																		|pl = 'Deposit';
																		|tr = 'Mevduat'"));
			ListOfFinancialInstruments.Add(
				Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing, NStr("vi = 'Cho vay';
																				|ru = 'Займы выданные';
																				|en = 'Issued loans'; fa = 'وام‌های اعطایی';
																				|it = 'Prestiti emessi';
																				|pl = 'Wyemitowane pożyczki';
																				|tr = 'Verilen borçlar'"));
		EndIf;
		If NonCurrentAssets.VNAManagementIsUsed() Then
			ListOfFinancialInstruments.Add(Enums.ContractKindsOfFinancialInstruments.Lease);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ConfigureDefaultSelectionParameters(FormSettingsComposer, UserSettings = False)
	
	FixedPeriodSetting = FixedParameterSetting(FormSettingsComposer, "Period");
	
	If FixedPeriodSetting.Use = True Then
		
		FixedSettingStandardPeriod = FixedPeriodSetting.Value; // StandardPeriod
		
		UsesPeriodSetting = CustomParameterSetting(FormSettingsComposer, "Period");
		UsesPeriodSetting.Use = True;
		
		UsesPeriodSettingStandardPeriod = UsesPeriodSetting.Value; // StandardPeriod
		
		UsesPeriodSettingStandardPeriod.StartDate = FixedSettingStandardPeriod.StartDate;
		UsesPeriodSettingStandardPeriod.EndDate = FixedSettingStandardPeriod.EndDate;
		
		FixedPeriodSetting.Use = False;
	EndIf;
	
EndProcedure

Function FixedParameterSetting(FormSettingsComposer, ParameterName)
	
	CDDataParameters = FormSettingsComposer.FixedSettings.DataParameters; // DataCompositionDataParameterValues
	
	Return CDDataParameters.Items.Find(ParameterName);
	
EndFunction

Function CustomParameterSetting(FormSettingsComposer, ParameterName)
	
	Result = Undefined;
	
	CDDataParameters = FormSettingsComposer.Settings.DataParameters; // DataCompositionDataParameterValues
	
	DataParameter = CDDataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		DCUserSettings = FormSettingsComposer.UserSettings; // DataCompositionUserSettings
		CustomSettingParameter = DCUserSettings.Items.Find(DataParameter.UserSettingID);
		If CustomSettingParameter <> Undefined Then
			Result = CustomSettingParameter;
		Else
			Result = DataParameter;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf