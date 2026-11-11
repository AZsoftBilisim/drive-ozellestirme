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
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		GenerateReportParameters(Parameters.CommandParameter, Form.ParametersForm, Parameters);
			
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the report or report settings contains the following properties:
//   	* Parameters - Structure - 
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Setting up a contextual report on contracts
	ConfigureContractReport(Form, FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the report or report settings contains the following properties:
//   	* Parameters - Structure - 
//   NewDCUserSettings - DataCompositionUserSettings - settings to upload to the settings Builder.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Setting up a contextual report on contracts
	ConfigureContractReport(Form, FormSettingsComposer);
	
	NewDCUserSettings = FormSettingsComposer.UserSettings;
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateReportParameters(CommandParameter, FormParameters, Parameters)
	
	If TypeOf(CommandParameter) = Type("Array") Then
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		TheFirstControl = CommandParameter;
	EndIf;
	
	If TypeOf(TheFirstControl) = Type("CatalogRef.LeaseContract") Then
		
		FormParameters.Filter = New Structure("Contract", CommandParameter);
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		
	EndIf;
	
EndProcedure

Procedure ConfigureContractReport(Form, FormSettingsComposer)
	
	If Not Form.Parameters.Property("VariantKey")
		Or Form.Parameters.VariantKey <> "ByCustomerContract" Then
		Return;
	EndIf;
	
	CommandParameter = Form.Parameters.CommandParameter;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ListOfAgreements = CommandParameter;
	Else
		ListOfAgreements = New Array;
		ListOfAgreements.Add(CommandParameter);
	EndIf;
		
	QueryText = 
	"SELECT
	|	ISNULL(MAX(LeaseContract.HasSecurityDeposit), FALSE) AS HasSecurityDeposit,
	|	ISNULL(MAX(LeaseContract.ThereIsBuyoutOfLeasedAssets), FALSE) AS ThereIsBuyoutOfLeasedAssets
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	LeaseContract.Ref IN (&ListOfAgreements)";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfAgreements", ListOfAgreements);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	HasSecurityDeposit = False;
	ThereIsBuyoutOfLeasedAssets = False;

	If Selection.Next() Then
		HasSecurityDeposit = Selection.HasSecurityDeposit;
		ThereIsBuyoutOfLeasedAssets = Selection.ThereIsBuyoutOfLeasedAssets;
	EndIf;
	
	ItemsNames = New Array;
	
	If Not HasSecurityDeposit Then
		ItemsNames.Add("DepositPayment.AccrualsPlan");
		ItemsNames.Add("DepositPayment.AccrualsFact");
		ItemsNames.Add("DepositPayment.AccrualsDeviation");
		
		ItemsNames.Add("DepositPayment.PaymentPlan");
		ItemsNames.Add("DepositPayment.PaymentFact");
		ItemsNames.Add("DepositPayment.PaymentDeviation");
	EndIf;

	If Not ThereIsBuyoutOfLeasedAssets Then
		ItemsNames.Add("BuyoutValue.AccrualsPlan");
		ItemsNames.Add("BuyoutValue.AccrualsFact");
		ItemsNames.Add("BuyoutValue.AccrualsDeviation");
		
		ItemsNames.Add("BuyoutValue.PaymentPlan");
		ItemsNames.Add("BuyoutValue.PaymentFact");
		ItemsNames.Add("BuyoutValue.PaymentDeviation");
	EndIf;
	
	If Not LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed() Then
		ItemsNames.Add("Interests.AccrualsPlan");
		ItemsNames.Add("Interests.AccrualsFact");
		ItemsNames.Add("Interests.AccrualsDeviation");
	EndIf;
	
	If ItemsNames.Count() <> 0 Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, ItemsNames, True);
	EndIf;

EndProcedure

#EndRegion

#EndIf