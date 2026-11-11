
#Region Public

// Handler for dynamically added commands.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Command - FormCommand - the command that was called.
//   Result - Boolean - True if the command call was processed.
//
Procedure HandlerCommands(ThisForm, Command, Result) Export
	
	FullReportName = ThisForm.ReportSettings.FullName;

	If FullReportName = "Report.UseAccountsAndExtraDimensionInSettings" Then
		If Command.Name = TagName(ThisForm.ReportSettings.AddlParameters.ChartOfAccounts) Then
			SetTypeOfDependentProps(ThisForm);
		EndIf;
	EndIf;
	
	FinancialAccountingUponLocalAccountingClient.HandlerCommands(ThisForm, Command, Result);
	FinancialAccountingByFinancialRegisterDataClient.HandlerCommands(ThisForm, Command, Result);

EndProcedure

// Handler for decoding a table document in a report form.
//
// Parameters:
//  ThisForm - ClientApplicationForm - report form.
//  Item     - FormField        - table document.
//  Details - Arbitrary     - the value of the decoding point, series, or chart value.
//  StandardProcessing - Boolean  - indicates whether standard (system) event processing is performed.
//
Procedure DetailProcessing(ThisForm, Item, Details, StandardProcessing) Export
	
	ReportName = StrReplace(ThisForm.ReportSettings.FullName, "Report.", "");
	CurrentVariantKey = ThisForm.CurrentVariantKey;
 
	If ThisIsStandardReport(ReportName) Then
		
		CurrentVariantKey = FinancialAccountingServerCall.KeyOfParentPredefinedVersionOfReport(
			CurrentVariantKey, ReportName);
		StandardProcessing = DecryptionOfStandardReport(ThisForm, Item, Details, ReportName, CurrentVariantKey);
		
	ElsIf ReportName = "UseAccountsAndExtraDimensionInSettings" Then
		
		DetailsParameters = FinancialAccountingServerCall.SettingsDecryptionParameters(
		Details, ThisForm.ReportDetailsData);
		If DetailsParameters.ThisIsDerivative Then
			StandardProcessing = False;
			FormParameters = New Structure;
			FormParameters.Insert("Key", DetailsParameters.ReportItem);
			
			FormParameters.Insert("ItemAddressInStorage", "");
			FormParameters.Insert("MainStorageID", ThisForm.UUID);
			FormParameters.Insert("AdditionalFormMode", PredefinedValue("Enum.AdditionalModesOfReportItems.ReportKind"));
			FormParameters.Insert("ShowRowCodeNote", True);
			FormParameters.Insert("ReadOnly", True);
			
			OpenForm("Catalog.FinancialReportItems.ObjectForm", FormParameters, ThisForm);
			
		ElsIf ValueIsFilled(DetailsParameters.ReportKind) And ValueIsFilled(DetailsParameters.ReportItem) Then
			
			StandardProcessing = False;
			FormParameters = New Structure;
			FormParameters.Insert("Key", DetailsParameters.ReportKind);
			FormParameters.Insert("CurrentReportItem", DetailsParameters.ReportItem);
			OpenForm("Catalog.FinancialReportTypes.ObjectForm",FormParameters);
			
		EndIf;
	EndIf;
	
	FinancialAccountingUponLocalAccountingClient.DetailProcessing(ThisForm, Item, Details, StandardProcessing);
	FinancialAccountingByFinancialRegisterDataClient.DetailProcessing(ThisForm, Item, Details, StandardProcessing);
	
EndProcedure

// Returns General parameters for opening transaction setup forms
//
// Returns:
// 	Structure - General opening parameters:
// 		* Organization - CatalogRef.Companies, Undefined -
// 		* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts, Undefined -
// 		* PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting, Undefined - 
Function ParametersForOpeningTransactionConfigurationForms() Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Organization");
	OpeningParameters.Insert("ChartOfAccounts");
	OpeningParameters.Insert("PostingGenerationSetting");
	
	Return OpeningParameters;
	
EndFunction

#EndRegion

#Region Private

// Called for the report " usingaccountsubcontinternational Accounting"
//
Procedure SetTypeOfDependentProps(ThisForm)
	
	AddlParameters = ThisForm.ReportSettings.AddlParameters;
	
	UserSettings = ThisForm.Report.SettingsComposer.UserSettings.Items;
	AuxProperties = ThisForm.Report.SettingsComposer.UserSettings.AdditionalProperties;
	AuxProperties.Clear();
	
	AuxProperties.Insert("ItSInternational_", ThisForm[TagName(AddlParameters.ChartOfAccounts)]);
	ChartOfAccounts = UserSettings.Find(AddlParameters.ChartOfAccounts);
	ChartOfAccounts.Value = AuxProperties.ItSInternational_;
	
	Items = ThisForm.Items;
	InvoiceElement = Items[TagName(AddlParameters.Account)];
	ElementViewExtdimension = Items[TagName(AddlParameters.ExtDimensionType)];
	
	Account = UserSettings.Find(AddlParameters.Account);
	ExtDimensionType = UserSettings.Find(AddlParameters.ExtDimensionType);
	SubContact = UserSettings.Find(AddlParameters.SubContact);
	ExtdimensionLocal = UserSettings.Find(AddlParameters.ExtdimensionLocal);
	If Not AuxProperties.ItSInternational_ Then
		
		TypeChartOfAccountsLocalAccounting = LocalAccntingClientServer.TypeChartOfAccounts();
		TypicalExtdimensionOfLocalAccounting = LocalAccntingClientServer.TypeSpeciesExtdimension();
		
		Account.Value = New(TypeChartOfAccountsLocalAccounting);
		ExtDimensionType.Value = New(TypicalExtdimensionOfLocalAccounting);
		
		TypesArray = New Array;
		TypesArray.Add(TypeChartOfAccountsLocalAccounting);
		InvoiceElement.TypeRestriction = New TypeDescription(TypesArray);
		
		TypesArray = New Array;
		TypesArray.Add(TypicalExtdimensionOfLocalAccounting);
		ElementViewExtdimension.TypeRestriction = New TypeDescription(TypesArray);
		
		Items.ExtdimensionValueGroup.CurrentPage = Items.ExtdimensionSelfFinancing;
	Else
		Account.Value = PredefinedValue("ChartOfAccounts.International.EmptyRef");
		ExtDimensionType.Value = PredefinedValue("ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef");
		
		InvoiceElement.TypeRestriction = New TypeDescription("ChartOfAccountsRef.International");
		ElementViewExtdimension.TypeRestriction = New TypeDescription("ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes");
		Items.ExtdimensionValueGroup.CurrentPage = Items.ExtdimensionInternational;
	EndIf;
	SubContact.Value = Undefined;
	ExtdimensionLocal.Value = Undefined;
	
EndProcedure

Function TagName(Id)
	
	Return "SettingParameterValue_Value_" + StrReplace(Id,"-","");
	
EndFunction

Function DecryptionOfStandardReport(ReportForm, Item, DetailsID, ReportName, CurrentVariantKey)
	
	DetailsParameters = FinancialAccountingServerCall.StandardReportDecryptionParameters(
							ReportForm.ReportDetailsData, 
							DetailsID,
							ReportName, 
							CurrentVariantKey);
							
	If DetailsParameters.PossibleDecryptions.Count() = 0 Then
		Return True; // StandardProcessing
	EndIf;
	
	SettingsComposer = ReportForm.Report.SettingsComposer;
	
	If DetailsParameters.PossibleDecryptions.Count() = 1 Then
		PrepareDecryption(
			DetailsParameters.PossibleDecryptions[0].Value,
			DetailsParameters.ExplanationFormParameters, 
			SettingsComposer);
	Else
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ExplanationFormParameters", DetailsParameters.ExplanationFormParameters);
		AdditionalParameters.Insert("SettingsComposer", SettingsComposer);
		
		Notification = New CallbackDescription("DecryptionOfStandardReportCompletion", ThisObject, AdditionalParameters);
		ReportForm.ShowChooseFromMenu(Notification, DetailsParameters.PossibleDecryptions, Item);
	EndIf;
	
	Return False;
	
EndFunction

// The selection of the decryption actions item is processed.
//
// Parameters:
//  SelectedElement - ValueListItem - Selected item from the list of decryption actions.
//  AdditionalParameters - Structure - Additional parameters include:
//		* ExplanationFormParameters - Structure - Decryption settings.
//  	* SettingsComposer - DataCompositionSettingsComposer - Linker for settings for the decrypted report.
//
Procedure DecryptionOfStandardReportCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		
		PrepareDecryption(SelectedElement.Value,
			AdditionalParameters.ExplanationFormParameters,
			AdditionalParameters.SettingsComposer);
		
	EndIf;
	
EndProcedure 

// Generates data for opening the decryption form.
//
// Parameters:
//  DetailsValue - Structure - Contains the name, version of the report, and additional parameters:
//   * AdditionalParameters - Structure - the types of elements are listed:
//     ** Key - String - 
//     ** Value - Arbitrary - 
//  ExplanationFormParameters - Structure - Contains transcript fields and selections.
//	SettingsComposer - DataCompositionSettingsComposer - Linker for settings for the decrypted report.
//
Procedure PrepareDecryption(DetailsValue, ExplanationFormParameters, Val SettingsComposer) Export
	
	If TypeOf(DetailsValue) = Type("String") Then
		If ExplanationFormParameters.Fields.Property(DetailsValue) Then
			ShowValue(, ExplanationFormParameters.Fields[DetailsValue]);
		EndIf;
		Return;
	EndIf;
	
	AccountParameters_ = New Array;
	
	If ValueIsFilled(DetailsValue.AdditionalParameters) Then
		If DetailsValue.AdditionalParameters.Property("DrCr") Then
			
			AccountSide = DetailsValue.AdditionalParameters.DrCr;
			AccountCorSide = StrReplace("DrCr", AccountSide, "");
			
			If ExplanationFormParameters.Fields.Property("Account" + AccountSide) Then
				ExplanationFormParameters.Fields.Insert("Account", ExplanationFormParameters.Fields["Account" + AccountSide]);
				ExplanationFormParameters.Fields.Delete("Account" + AccountSide);
			EndIf;
			If ExplanationFormParameters.Fields.Property("Account" + AccountCorSide) Then
				ExplanationFormParameters.Fields.Insert("BalancedAccount", ExplanationFormParameters.Fields["Account" + AccountCorSide]);
				ExplanationFormParameters.Fields.Delete("Account" + AccountCorSide);
			EndIf;
			
			If ExplanationFormParameters.Filters.Property("Account" + AccountSide) Then
				ExplanationFormParameters.Filters.Insert("Account", ExplanationFormParameters.Filters["Account" + AccountSide]);
				ExplanationFormParameters.Filters.Account.LeftValue = New DataCompositionField("Account");
				ExplanationFormParameters.Filters.Delete("Account" + AccountSide);
			EndIf;
			If ExplanationFormParameters.Filters.Property("Account" + AccountCorSide) Then
				ExplanationFormParameters.Filters.Insert("BalancedAccount", ExplanationFormParameters.Filters["Account" + AccountCorSide]);
				ExplanationFormParameters.Filters.BalancedAccount.LeftValue = New DataCompositionField("BalancedAccount");
				ExplanationFormParameters.Filters.Delete("Account" + AccountCorSide);
			EndIf;
			
			AccountField 			= New DataCompositionField("Account" + AccountSide);
			AccountCorField 	= New DataCompositionField("Account" + AccountCorSide);
			For Each ItemTheCustomSettings In SettingsComposer.UserSettings.Items Do
				If TypeOf(ItemTheCustomSettings) = Type("DataCompositionFilterItem")
						And ItemTheCustomSettings.Use
						And (ItemTheCustomSettings.LeftValue = AccountField 
							Or ItemTheCustomSettings.LeftValue = AccountCorField) Then
					ItemTheCustomSettings.Use = False;
					AccountParameters_.Add(ItemTheCustomSettings);
				EndIf;
			EndDo;
		ElsIf DetailsValue.AdditionalParameters.Property("GroupByPeriod") Then
			ExplanationFormParameters.Insert("Groups", New Structure(DetailsValue.AdditionalParameters.GroupByPeriod));
		EndIf; 
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ReportName",							DetailsValue.ReportName);
	Parameters.Insert("VariantKey", 					DetailsValue.VariantName);
	Parameters.Insert("SettingsComposer", 	SettingsComposer);
	Parameters.Insert("Filter", 										ExplanationFormParameters.Filters);
	If ExplanationFormParameters.Property("Fields") Then
		Parameters.Insert("DecryptionFields", 			ExplanationFormParameters.Fields);
	EndIf;
		
	ReportSettings1 = FinancialAccountingServerCall.ConfigureDecryptionReport(Parameters);
	
	FixedSettings = ReportSettings1.FixedSettings;
	FixedSettings.AdditionalProperties.Insert("DescriptionOption", DetailsValue.VariantName);
	
	SettingsKey = "DecryptionOfStandardReport"; 
	OpenDecryption(DetailsValue, ReportSettings1, SettingsKey, SettingsKey);
	
	For Each AccountParameter In AccountParameters_ Do
		AccountParameter.Use = True;
	EndDo;
	
EndProcedure

Function OpenDecryption(DetailsValue, ReportSettings, PurposeUseKey = Undefined, UserSettingsKey = Undefined) Export
	
	UsedSettings = New Structure("UsedSettings",ReportSettings.FixedSettings);
		
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", 									DetailsValue.VariantName);
	FormParameters.Insert("UserSettings", 	ReportSettings.UserSettings);
	FormParameters.Insert("FixedSettings", 			ReportSettings.FixedSettings);
	FormParameters.Insert("GenerateOnOpen", 		True);
	If DetailsValue.Property("AdditionalParameters") Then
		FormParameters.Insert("AdditionalParameters",		DetailsValue.AdditionalParameters);
	EndIf;
	
	If PurposeUseKey <> Undefined Then
		FormParameters.Insert("PurposeUseKey", 	PurposeUseKey);
	EndIf;
	If UserSettingsKey <> Undefined Then
		FormParameters.Insert("UserSettingsKey", UserSettingsKey);
	EndIf;
		
	OpenForm("Report." + DetailsValue.ReportName + ".Form", FormParameters,, True);
			
EndFunction

Function ThisIsStandardReport(ReportName) Export
	
	ReportsList = New Array;
	ReportsList.Add("AccountingReportFinancialAccounting");
	ReportsList.Add("AccountingReportWithCorrespondenceFinancialAccounting");
	ReportsList.Add("AccountCardFinancialAccounting");
	ReportsList.Add("ArticulationStatementFinancialAccounting");
		
	Return ReportsList.Find(ReportName) <> Undefined;
	
EndFunction

#EndRegion
