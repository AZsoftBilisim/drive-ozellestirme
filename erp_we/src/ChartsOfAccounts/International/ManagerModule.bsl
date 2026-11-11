#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a representation of the plan in the financial statements
//
// Returns:
// 	String - Presentation of the chart of accounts in financial statements
//
Function PresentationInFinancialStatements() Export
	
	Return NStr("vi = 'Quốc tế';
				|ru = 'Международный';
				|en = 'International'; fa = 'بین‌المللی';
				|it = 'Internazionale';
				|pl = 'International';
				|tr = 'Finansal'");
	
EndFunction

// Returns an array of invoices with the subconto type set as a parameter
//
// Parameters:
// 		ExtDimensionTypes - Array, ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - An array of links or a link to a sub-account to get invoices for.
//
// Returns:
// 		Array - Array of links <plancountslink.International>, supporting the functions specified by the parameter subconto.
//
Function AccountingAccountsWithExtdimensionView(ExtDimensionTypes) Export
	
	Query = New Query(
	"SELECT ALLOWED
	|	International.Ref
	|FROM
	|	ChartOfAccounts.International AS International
	|WHERE
	|	International.ExtDimensionTypes.ExtDimensionType IN(&ExtDimensionType)");
	Query.SetParameter("ExtDimensionType", ExtDimensionTypes);
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region IsInternal
	Item = Items.Add();
	Item.PredefinedDataName = "IsInternal";
	Item.Description = NStr("vi = 'Công vụ';
							|ru = 'Служебный';
							|en = 'Internal'; fa = 'داخلی';
							|it = 'Del servizio';
							|pl = 'Internal';
							|tr = 'Dahili'", Common.DefaultLanguageCode());
	Item.ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.International;
	Item.Code = "00000";
	Item.Order = "00000";
	#EndRegion

EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - ChartOfAccountsObject.International - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// See ObjectAttributesLockOverridable.OnDefineObjectsWithLockedAttributes
// 
// Returns:
//  Array of String - Get blocked object Attributes
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
    Result.Add("RestrictUseInPostings");
    Result.Add("Currency1");
    Result.Add("Quantitative");
    Result.Add("AccountingByBusinessUnits");
    Result.Add("AccountingByLinesOfBusiness");
    Result.Add("ExtDimensionTypes"); 
    
	Return Result;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Code");
	Fields.Add("Description");
	Fields.Add("ChartOfAccounts");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	AccountsPresentation = FinancialAccountingClientServerCached.PresentationOfInvoicesOnChartOfAccounts(Data.ChartOfAccounts);
	
	If AccountsPresentation = Enums.PresentationOfFinancialAccountingAccounts.AsCode Then
		Presentation = Data.Code;
	ElsIf AccountsPresentation = Enums.PresentationOfFinancialAccountingAccounts.AsDescription Then
		Presentation = Data.Description;
	Else
		Presentation = Data.Code + ?(IsBlankString(Data.Description), "", " " + Data.Description);
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("OnlyAllowed") And Parameters.OnlyAllowed Then
		Parameters.Filter.Insert("RestrictUseInPostings", False);
	EndIf;
	
	If Parameters.Property("ExtDimensionTypes") Then
		Query = New Query(
			"SELECT ALLOWED
			|	International.Ref
			|FROM
			|	ChartOfAccounts.International AS International
			|WHERE
			|	International.ExtDimensionTypes.ExtDimensionType IN(&ExtDimensionType)");
		Query.SetParameter("ExtDimensionType", Parameters.ExtDimensionTypes);
		Result = Query.Execute();
		Parameters.Filter.Insert("Ref", Result.Unload().UnloadColumn("Ref"));
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
