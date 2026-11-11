#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);
			
	If Not DataSelectionValues.ShowACCalculation
		And Not DataSelectionValues.DisplayMACalculation Then
		MessageText = NStr("vi = 'Chọn những dữ liệu cần nhận: KTDN, KTQT.';
							|ru = 'Необходимо выбрать какие данные нужно получить: БУ, УУ.';
							|en = 'Select which data you need to get: LA, MA.'; fa = 'Select which data you need to get: LA, MA.';
							|it = 'È necessario selezionare i dati da ricevere: Contabilità, Contabilità Gestionale.';
							|pl = 'Należy wybrać jakie dane należy otrzymać: Ewidencja księgowa, Ewidencja zarządcza.';
							|tr = 'Hangi verilerin alınacağının seçilmesi gereklidir: GM, YM.'");
		Common.MessageToUser(MessageText,,,, Cancel); 
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	SetQueryText(DataCompositionSchema);
	
	DataSelectionValues = GetDataSelectionValues(MainCircuitSettings);
	
	SetReportParameters(DataSelectionValues, MainCircuitSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);	
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, Undefined, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	AddInformationalMessageToHeader(ResultDocument, DataSelectionValues);
	
EndProcedure

#EndRegion

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
	Settings.Events.OnLoadVariantAtServer = True;
	
	Settings.EditStructureAllowed = False;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure - may contain properties:
//				** CommandParameter - Arbitrary -
//				** CommandDetails - Structure - 
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters; 
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		Parameters.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "ReferenceCalculationOfIa" Then
			ThisForm.ParametersForm.Filter.Insert("IntangibleAsset", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ReferenceCalculationAccordingToDocumentDepreciationIA" Then
			ThisForm.ParametersForm.Filter.Insert("DepreciationCalculationDocument", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCSettings - DataCompositionSettings - Settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form extension for the report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer - 
	
	SetReportPeriod(Form, FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

#EndRegion

#Region Private

Function GetDataSelectionValues(MainCircuitSettings)

	FilterItems1 = MainCircuitSettings.Filter.Items;
	
	DataSelectionValues = New Structure;
	
	DataSelectionValues.Insert("CompaniesList", TMReportsServer.FilterValue("Organization", FilterItems1));
	If DataSelectionValues.CompaniesList.Count() = 0 Then
		DataSelectionValues.CompaniesList = NonCurrentAssetsInternal.ListOfAllowedOrganizations();
	EndIf;
	
	DataSelectionValues.Insert("ListOfIA", TMReportsServer.FilterValue("IntangibleAsset", FilterItems1));
	DataSelectionValues.Insert("DepreciationCalculationDocument", TMReportsServer.FilterValue("DepreciationCalculationDocument", FilterItems1));
	
	TMReportsServer.ReportPeriod(MainCircuitSettings, DataSelectionValues);
	
	ShowACCalculation = TMReportsServer.ParameterValue(MainCircuitSettings, "ShowACCalculation", False);
	DisplayMACalculation = TMReportsServer.ParameterValue(MainCircuitSettings, "DisplayMACalculation", False);
	
	DataSelectionValues.Insert("ShowACCalculation", ShowACCalculation);
	DataSelectionValues.Insert("DisplayMACalculation", DisplayMACalculation);
	
	Return DataSelectionValues;
	
EndFunction

Procedure SetReportParameters(DataSelectionValues, MainCircuitSettings)

	If ValueIsFilled(DataSelectionValues.BeginOfPeriod) Then
		BegOfYear = BegOfYear(DataSelectionValues.BeginOfPeriod);
	Else
		BegOfYear = '000101010000';
	EndIf;
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "BegOfYear", BegOfYear);
	
	If ValueIsFilled(DataSelectionValues.PeriodEnding) Then
		EndOfYear = EndOfYear(DataSelectionValues.PeriodEnding);
	Else
		EndOfYear = '000101010000';
	EndIf;
	DataCompositionClientServer.SetParameter(MainCircuitSettings, "EndOfYear", EndOfYear);
	
EndProcedure

Procedure SetQueryText(Var_DataCompositionSchema)

	ListOfRequests = New Array;
	
	#Region TT_Depreciation
	QueryText = 
	"SELECT ALLOWED
	|	TabDepreciation.Period AS Period,
	|	BEGINOFPERIOD(TabDepreciation.Period, YEAR) AS BegOfYear,
	|	BEGINOFPERIOD(TabDepreciation.Period, MONTH) AS BegOfMonth,
	|	TabDepreciation.Recorder AS DepreciationCalculationDocument,
	|
	|	TabDepreciation.Organization AS Organization,
	|	TabDepreciation.Department AS Department,
	|	TabDepreciation.Organization.ParentCompany AS ParentCompany,
	|
	|	TabDepreciation.IntangibleAsset AS IntangibleAsset,
	|
	|	TabDepreciation.Depreciation AS DepreciationManagementAccounting,
	|	TabDepreciation.DepreciationLocal + TabDepreciation.FixedAssetDepreciationTargetFinancing AS DepreciationInAccounting,
	|	TabDepreciation.DepreciationInTaxAccounting + TabDepreciation.DepreciationTaxAccountingTargetFinancing AS DepreciationInTaxAccounting,
	|	TabDepreciation.DepreciationPermanentDifferences + TabDepreciation.DepreciationTargetFinancingPD AS DepreciationPermanentDifferences,
	|	TabDepreciation.DepreciationTD + TabDepreciation.DepreciationOfTargetFinancingTD AS DepreciationTD,
	|
	|	TabDepreciation.LifeSpentPastPeriod AS ResourceDevelopedOverPastPeriodMA,
	|	TabDepreciation.LifeSpentCurrentPeriod AS ResourceDevelopedForCurPeriodMA,
	|
	|	TabDepreciation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	TabDepreciation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|
	|	TabDepreciation.CostUsedToCalculateDepreciationManag AS CostUsedToCalculateDepreciationInManagementAccounting,
	|	TabDepreciation.CostUsedToCalculateDepreciationLocal AS CostUsedToCalculateDepreciationInAccounting,
	|
	|	TabDepreciation.AccountingProcedureMA AS AccountingProcedureMA,
	|	TabDepreciation.AccountingProcedureAC AS AccountingProcedureAC,
	|
	|	TabDepreciation.ProcedureForCalculatingDepreciationOfMa AS ProcedureForCalculatingDepreciationOfMa,
	|	TabDepreciation.ProcedureForCalculatingDepreciationAC AS ProcedureForCalculatingDepreciationAC,
	|
	|	TabDepreciation.DepreciationMethodVersionMA AS DepreciationMethodVersionMA,
	|	TabDepreciation.DepreciationMethodVersionLA AS DepreciationMethodVersionLA,
	|	TabDepreciation.ThisIsAnAdditionalAccrual AS ThisIsAdditionalChargeMA,
	|	TabDepreciation.ThisIsAdditionalChargeAccounting AS ThisIsAdditionalChargeAccounting
	|
	|INTO TT_Depreciation
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge AS TabDepreciation
	|
	|WHERE
	|	(TabDepreciation.Period >= &BeginOfPeriod
	|			OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (TabDepreciation.Period <= &EndOfPeriod
	|			OR &EndOfPeriod = DATETIME(1, 1, 1))
	|	AND TabDepreciation.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4
	|	AND TabDepreciation.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|{WHERE
	|	TabDepreciation.Organization.* AS Organization,
	|	TabDepreciation.Department.* AS Department,
	|	TabDepreciation.IntangibleAsset.* AS IntangibleAsset,
	|	CAST(TabDepreciation.Recorder AS Document.IntangibleAssetsAmortizationCharge2_4) AS DepreciationCalculationDocument,
	|	TabDepreciation.Depreciation AS DepreciationManagementAccounting,
	|	(TabDepreciation.DepreciationLocal + TabDepreciation.FixedAssetDepreciationTargetFinancing) AS DepreciationInAccounting,
	|	(TabDepreciation.DepreciationInTaxAccounting + TabDepreciation.DepreciationTaxAccountingTargetFinancing) AS DepreciationInTaxAccounting,
	|	(TabDepreciation.DepreciationPermanentDifferences + TabDepreciation.DepreciationTargetFinancingPD) AS DepreciationPermanentDifferences,
	|	(TabDepreciation.DepreciationTD + TabDepreciation.DepreciationOfTargetFinancingTD) AS DepreciationTD}
	|
	|UNION ALL
	|
	|SELECT
	|	TabDepreciation.Period,
	|	BEGINOFPERIOD(TabDepreciation.Period, YEAR),
	|	BEGINOFPERIOD(TabDepreciation.Period, MONTH),
	|	TabDepreciation.Recorder AS DepreciationCalculationDocument,
	|	TabDepreciation.Organization,
	|	TabDepreciation.Department,
	|	TabDepreciation.Organization.ParentCompany,
	|	TabDepreciation.IntangibleAsset,
	|
	|	TabDepreciation.Cost,
	|	TabDepreciation.LocalCost + TabDepreciation.CostTargetFinancing,
	|	TabDepreciation.CostInTaxAccounting + TabDepreciation.CostTargetFinancingTA,
	|	TabDepreciation.CostPermanentDifference + TabDepreciation.CostTargetFinancingPD,
	|	TabDepreciation.CostTemporaryDifference + TabDepreciation.CostTargetFinancingTD,
	|
	|	TabDepreciation.LifeSpentPastPeriod,
	|	TabDepreciation.LifeSpentCurrentPeriod,
	|
	|	0,
	|	0,
	|
	|	TabDepreciation.CostUsedToCalculateDepreciationManag,
	|	0,
	|
	|	TabDepreciation.AccountingProcedureMA AS AccountingProcedureMA,
	|	VALUE(Enum.AccountingPolicyForFixedAssets.ByLocalAccountingStandards) AS AccountingProcedureAC,
	|
	|	VALUE(Enum.DepreciationProcedure.StartingNextMonth) AS ProcedureForCalculatingDepreciationOfMa,
	|	VALUE(Enum.DepreciationProcedure.StartingNextMonth) AS ProcedureForCalculatingDepreciationAC,
	|
	|	0 AS DepreciationMethodVersionMA,
	|	0 AS DepreciationMethodVersionLA,
	|	TabDepreciation.ThisIsAnAdditionalAccrual AS ThisIsAnAdditionalAccrual,
	|	FALSE AS ThisIsAdditionalChargeAccounting
	|
	|FROM
	|	AccumulationRegister.IACost AS TabDepreciation
	|
	|WHERE
	|	(TabDepreciation.Period >= &BeginOfPeriod
	|			OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (TabDepreciation.Period <= &EndOfPeriod
	|			OR &EndOfPeriod = DATETIME(1, 1, 1))
	|	AND TabDepreciation.Recorder REFS Document.IntangibleAssetsAmortizationCharge2_4
	|	AND TabDepreciation.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|{WHERE
	|	TabDepreciation.Organization.* AS Organization,
	|	TabDepreciation.Department.* AS Department,
	|	TabDepreciation.IntangibleAsset.* AS IntangibleAsset,
	|	CAST(TabDepreciation.Recorder AS Document.IntangibleAssetsAmortizationCharge2_4) AS DepreciationCalculationDocument,
	|	TabDepreciation.Cost AS DepreciationManagementAccounting,
	|	(TabDepreciation.LocalCost + TabDepreciation.CostTargetFinancing) AS DepreciationInAccounting,
	|	(TabDepreciation.CostInTaxAccounting + TabDepreciation.CostTargetFinancingTA) AS DepreciationInTaxAccounting,
	|	(TabDepreciation.CostPermanentDifference + TabDepreciation.CostTargetFinancingPD) AS DepreciationPermanentDifferences,
	|	(TabDepreciation.CostTemporaryDifference + TabDepreciation.CostTargetFinancingTD) AS DepreciationTD}
	|
	|INDEX BY
	|	Period,
	|	IntangibleAsset,
	|	Organization
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region AccountingPolicy
	QueryText =
	"SELECT
	|	TT_Depreciation.Period AS Period,
	|	TT_Depreciation.Organization AS Organization,
	|	MAX(TableLastPeriod.Period) AS CutOffPeriodOfLatter
	|
	|INTO AccountingPolicyUu_SliceOfLatest
	|
	|FROM
	|	TT_Depreciation AS TT_Depreciation
	|
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS TableLastPeriod
	|		ON (TableLastPeriod.Organization = TT_Depreciation.Organization)
	|			AND (TableLastPeriod.Period <= TT_Depreciation.Period)
	|
	|GROUP BY
	|	TT_Depreciation.Period,
	|	TT_Depreciation.Organization
	|
	|INDEX BY
	|	Period,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SliceTable.Period AS Period,
	|	SliceTable.Organization AS Organization,
	|	RegisterTableAsOfDate.ProcedureOfIntangibleAssetAmortizationCharge AS DepreciationProcedure,
	|	RegisterTableAsOfDate.ProcedureOfIntangibleAssetAmortizationChargeLocal AS DepreciationChargeProcedureLocal
	|
	|INTO AccountingPolicyOfMa
	|
	|FROM
	|	AccountingPolicyUu_SliceOfLatest AS SliceTable
	|
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS RegisterTableAsOfDate
	|		ON (RegisterTableAsOfDate.Organization = SliceTable.Organization)
	|			AND (RegisterTableAsOfDate.Period = SliceTable.CutOffPeriodOfLatter)
	|
	|INDEX BY
	|	Organization,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AccountingPolicyUu_SliceOfLatest";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region PeriodsOfACParameters
	QueryText =
	"SELECT DISTINCT
	|	CASE
	|		WHEN (Depreciation.ProcedureForCalculatingDepreciationAC = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|				OR Depreciation.ProcedureForCalculatingDepreciationAC = VALUE(Enum.DepreciationProcedure.EmptyRef)
	|					 AND ISNULL(AccountingPolicyOfMa.DepreciationChargeProcedureLocal, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|			THEN Depreciation.Period
	|		ELSE ENDOFPERIOD(DATEADD(Depreciation.Period, MONTH, -1), MONTH)
	|	END AS ParameterPeriod,
	|	ENDOFPERIOD(Depreciation.Period, MONTH) AS EndOfParameterPeriod,
	|	Depreciation.Period AS Period,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.ParentCompany AS ParentCompany,
	|	Depreciation.IntangibleAsset AS IntangibleAsset
	|
	|INTO PeriodsOfACParameters
	|
	|FROM
	|	TT_Depreciation AS Depreciation
	|
	|		LEFT JOIN AccountingPolicyOfMa AS AccountingPolicyOfMa
	|		ON AccountingPolicyOfMa.Organization = Depreciation.Organization
	|			AND AccountingPolicyOfMa.Period = Depreciation.Period
	|WHERE
	|	(Depreciation.DepreciationInAccounting <> 0
	|			OR Depreciation.DepreciationInTaxAccounting <> 0
	|			OR Depreciation.DepreciationPermanentDifferences <> 0
	|			OR Depreciation.DepreciationTD <> 0)
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	ParentCompany,
	|	ParameterPeriod";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region PeriodsOfMaParameters
	QueryText =
	"SELECT DISTINCT
	|	CASE
	|		WHEN (Depreciation.ProcedureForCalculatingDepreciationOfMa = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)
	|				OR Depreciation.ProcedureForCalculatingDepreciationOfMa = VALUE(Enum.DepreciationProcedure.EmptyRef)
	|						AND ISNULL(AccountingPolicy.DepreciationProcedure, VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting)) = VALUE(Enum.DepreciationProcedure.FromDateOfRecognitionInAccounting))
	|			THEN Depreciation.Period
	|		ELSE ENDOFPERIOD(DATEADD(Depreciation.Period, MONTH, -1), MONTH)
	|	END AS ParameterPeriod,
	|
	|	ENDOFPERIOD(Depreciation.Period, MONTH) AS EndOfParameterPeriod,
	|	Depreciation.Period AS Period,
	|	Depreciation.Organization AS Organization,
	|	Depreciation.IntangibleAsset AS IntangibleAsset
	|
	|INTO PeriodsOfMaParameters
	|
	|FROM
	|	TT_Depreciation AS Depreciation
	|
	|		LEFT JOIN AccountingPolicyOfMa AS AccountingPolicy
	|		ON AccountingPolicy.Organization = Depreciation.Organization
	|			AND AccountingPolicy.Period = Depreciation.Period
	|WHERE
	|	Depreciation.DepreciationManagementAccounting <> 0
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	ParameterPeriod";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region CalculationParameters
	
	// MA
	NonCurrentAssetsInternal.AddQueryTextHelpTablesDepreciationCalculation(
		"InitialIntangibleAssetsInformation", "InitialInformationMA", "PeriodsOfMaParameters", "IntangibleAsset", ListOfRequests);
	
	NonCurrentAssetsInternal.AddQueryTextHelpTablesDepreciationCalculation(
		"IntangibleAssetsAccountingProcedure", "ManSAccountingProcedure", "PeriodsOfMaParameters", "IntangibleAsset", ListOfRequests);
		
	NonCurrentAssetsInternal.AddQueryTextHelpTablesDepreciationCalculation(
		"IntangibleAssetAmortizationParametersManagementAccounting", "MaDepreciationParameters", "PeriodsOfMaParameters", "IntangibleAsset", ListOfRequests);
		
	// ACC
	NonCurrentAssetsInternal.AddQueryTextHelpTablesDepreciationCalculation(
		"InitialIntangibleAssetsInformation", "InitialInformationAC", "PeriodsOfACParameters", "IntangibleAsset", ListOfRequests);
	
	NonCurrentAssetsInternal.AddQueryTextHelpTablesDepreciationCalculation(
		"IntangibleAssetsAccountingProcedure", "LocalAccountingProcedure", "PeriodsOfACParameters", "IntangibleAsset", ListOfRequests);
		
	NonCurrentAssetsInternal.AddQueryTextHelpTablesDepreciationCalculation(
		"IADepreciationParametersBookkeepingAndTaxAccounting", "ACDepreciationParameters", "PeriodsOfACParameters", "IntangibleAsset", ListOfRequests);
		
	#EndRegion

	#Region Development_1
	QueryText = 
	"SELECT DISTINCT
	|	Depreciation.Organization AS Organization,
	|	Depreciation.IntangibleAsset AS IntangibleAsset,
	|
	|	CASE
	|		WHEN MONTH(InitialInformationAC.DateOfRecognitionAccounting) = MONTH(&BegOfMonth) - 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TakenIntoAccountLastMonth
	|
	|INTO VT_ListOfIa_Development
	|
	|FROM
	|	TT_Depreciation AS Depreciation
	|
	|		LEFT JOIN InitialInformationAC AS InitialInformationAC
	|		ON (InitialInformationAC.Organization = Depreciation.Organization)
	|			AND (InitialInformationAC.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (InitialInformationAC.Period = Depreciation.Period)
	|
	|		LEFT JOIN MaDepreciationParameters AS MaDepreciationParameters
	|		ON (MaDepreciationParameters.Organization = Depreciation.Organization)
	|			AND (MaDepreciationParameters.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (MaDepreciationParameters.Period = Depreciation.BegOfMonth)
	|
	|WHERE
	|	(InitialInformationAC.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction)
	|			OR MaDepreciationParameters.DepreciationMethod = VALUE(Enum.AccrualMethodOfIntangibleAssetDepreciation.ByUnitsOfProduction))
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(IntangibleAssetsOperatingTime.Period, MONTH) AS Period,
	|	IntangibleAssetsOperatingTime.IntangibleAsset AS IntangibleAsset,
	|	IntangibleAssetsOperatingTime.CountTurnover AS OutputVolume
	|
	|INTO IntangibleAssetsOperatingTime
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsOperatingTime.Turnovers(
	|			&BeginOfPeriod,
	|			&EndOfPeriod,
	|			Month,
	|			IntangibleAsset IN
	|				(SELECT
	|					ListOfIA.IntangibleAsset
	|				FROM
	|					VT_ListOfIa_Development AS ListOfIA)) AS IntangibleAssetsOperatingTime
	|
	|INDEX BY
	|	IntangibleAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VT_ListOfIa_Development
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region CostDepreciation_AtBeginningOfMonth
	QueryText = 
	"SELECT
	|	IACost.Period AS Period,
	|	IACost.Organization AS Organization,
	|	IACost.IntangibleAsset AS IntangibleAsset,
	|	IACost.CostClosingBalance AS CostInManagementAccounting,
	|	IACost.LocalCostClosingBalance + IACost.CostTargetFinancingClosingBalance AS CostInAccounting,
	|	IACost.CostInTaxAccountingClosingBalance + IACost.CostTargetFinancingTAClosingBalance AS CostInTaxAccounting
	|
	|INTO VT_CostOfNMA_ForPeriod
	|
	|FROM
	|	AccumulationRegister.IACost.BalanceAndTurnovers(
	|			&BeginningOfTheLastPeriod {(&BeginningOfTheLastPeriod)},
	|			&EndOfPeriod {(&EndOfPeriod)},
	|			Month,
	|			,
	|			IntangibleAsset IN
	|				(SELECT
	|					Depreciation.IntangibleAsset
	|				FROM
	|					TT_Depreciation AS Depreciation)) AS IACost
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Depreciation.Period AS Period,
	|	TT_Depreciation.Organization AS Organization,
	|	TT_Depreciation.IntangibleAsset AS IntangibleAsset,
	|	MAX(VT_CostOfNMA_ForPeriod.Period) AS CutOffPeriodOfLatter
	|
	|INTO VT_CostOfNMA_AtBeginningOfMonth_CrossSectionOfLast
	|
	|FROM
	|	TT_Depreciation AS TT_Depreciation
	|
	|		INNER JOIN VT_CostOfNMA_ForPeriod AS VT_CostOfNMA_ForPeriod
	|		ON (VT_CostOfNMA_ForPeriod.IntangibleAsset = TT_Depreciation.IntangibleAsset)
	|			AND (VT_CostOfNMA_ForPeriod.Organization = TT_Depreciation.Organization)
	|			AND (VT_CostOfNMA_ForPeriod.Period < TT_Depreciation.BegOfMonth)
	|
	|GROUP BY
	|	TT_Depreciation.Period,
	|	TT_Depreciation.Organization,
	|	TT_Depreciation.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	CutOffPeriodOfLatter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableLastPeriod.Period AS Period,
	|	TableLastPeriod.Organization AS Organization,
	|	TableLastPeriod.IntangibleAsset AS IntangibleAsset,
	|	RegisterTableAsOfDate.CostInManagementAccounting AS CostInManagementAccounting,
	|	RegisterTableAsOfDate.CostInAccounting AS CostInAccounting,
	|	RegisterTableAsOfDate.CostInTaxAccounting AS CostInTaxAccounting
	|
	|INTO VT_CostOfNMA_AtBeginningOfMonth
	|
	|FROM
	|	VT_CostOfNMA_AtBeginningOfMonth_CrossSectionOfLast AS TableLastPeriod
	|
	|		INNER JOIN VT_CostOfNMA_ForPeriod AS RegisterTableAsOfDate
	|		ON (RegisterTableAsOfDate.IntangibleAsset = TableLastPeriod.IntangibleAsset)
	|			AND (RegisterTableAsOfDate.Organization = TableLastPeriod.Organization)
	|			AND (RegisterTableAsOfDate.Period = TableLastPeriod.CutOffPeriodOfLatter)
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VT_CostOfNMA_ForPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VT_CostOfNMA_AtBeginningOfMonth_CrossSectionOfLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IntangibleAssetsAmortizationCharge.Period AS Period,
	|	IntangibleAssetsAmortizationCharge.Organization AS Organization,
	|	IntangibleAssetsAmortizationCharge.IntangibleAsset AS IntangibleAsset,
	|	-IntangibleAssetsAmortizationCharge.DepreciationClosingBalance AS DepreciationManagementAccounting,
	|	-(IntangibleAssetsAmortizationCharge.DepreciationLocalClosingBalance + IntangibleAssetsAmortizationCharge.FixedAssetDepreciationTargetFinancingClosingBalance) AS DepreciationInAccounting,
	|	-(IntangibleAssetsAmortizationCharge.DepreciationInTaxAccountingClosingBalance + IntangibleAssetsAmortizationCharge.DepreciationTaxAccountingTargetFinancingClosingBalance) AS DepreciationInTaxAccounting
	|
	|INTO VT_DepreciationOfNMA_ForPeriod
	|
	|FROM
	|	AccumulationRegister.IntangibleAssetsAmortizationCharge.BalanceAndTurnovers(
	|			&BeginningOfTheLastPeriod {(&BeginningOfTheLastPeriod)},
	|			&EndOfPeriod {(&EndOfPeriod)},
	|			Month,
	|			,
	|			IntangibleAsset IN
	|				(SELECT
	|					Depreciation.IntangibleAsset
	|				FROM
	|					TT_Depreciation AS Depreciation)) AS IntangibleAssetsAmortizationCharge
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Depreciation.Period AS Period,
	|	TT_Depreciation.Organization AS Organization,
	|	TT_Depreciation.IntangibleAsset AS IntangibleAsset,
	|	MAX(VT_DepreciationOfNMA_ForPeriod.Period) AS CutOffPeriodOfLatter
	|
	|INTO VT_DepreciationOfNMA_AtBeginningOfMonth_CutOfLast
	|
	|FROM
	|	TT_Depreciation AS TT_Depreciation
	|
	|		INNER JOIN VT_DepreciationOfNMA_ForPeriod AS VT_DepreciationOfNMA_ForPeriod
	|		ON (VT_DepreciationOfNMA_ForPeriod.IntangibleAsset = TT_Depreciation.IntangibleAsset)
	|			AND (VT_DepreciationOfNMA_ForPeriod.Organization = TT_Depreciation.Organization)
	|			AND (VT_DepreciationOfNMA_ForPeriod.Period < TT_Depreciation.BegOfMonth)
	|
	|GROUP BY
	|	TT_Depreciation.Period,
	|	TT_Depreciation.Organization,
	|	TT_Depreciation.IntangibleAsset
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	CutOffPeriodOfLatter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableLastPeriod.Period AS Period,
	|	TableLastPeriod.Organization AS Organization,
	|	TableLastPeriod.IntangibleAsset AS IntangibleAsset,
	|	RegisterTableAsOfDate.DepreciationManagementAccounting AS DepreciationManagementAccounting,
	|	RegisterTableAsOfDate.DepreciationInAccounting AS DepreciationInAccounting,
	|	RegisterTableAsOfDate.DepreciationInTaxAccounting AS DepreciationInTaxAccounting
	|
	|INTO VT_DepreciationOfNMA_AtBeginningOfMonth
	|
	|FROM
	|	VT_DepreciationOfNMA_AtBeginningOfMonth_CutOfLast AS TableLastPeriod
	|
	|		INNER JOIN VT_DepreciationOfNMA_ForPeriod AS RegisterTableAsOfDate
	|		ON (RegisterTableAsOfDate.IntangibleAsset = TableLastPeriod.IntangibleAsset)
	|			AND (RegisterTableAsOfDate.Organization = TableLastPeriod.Organization)
	|			AND (RegisterTableAsOfDate.Period = TableLastPeriod.CutOffPeriodOfLatter)
	|
	|INDEX BY
	|	IntangibleAsset,
	|	Organization,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VT_DepreciationOfNMA_ForPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP VT_DepreciationOfNMA_AtBeginningOfMonth_CutOfLast
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	#Region Depreciation
	QueryText =
	"SELECT
	|	Depreciation.Period AS Period,
	|	Depreciation.Period AS MAPEriOd,
	|	Depreciation.Period AS ACPeriod,
	|	Depreciation.DepreciationCalculationDocument AS DepreciationCalculationDocument,
	|
	|	Depreciation.ThisIsAdditionalChargeMA OR Depreciation.ThisIsAdditionalChargeAccounting AS ThisIsAnAdditionalAccrual,
	|	Depreciation.DepreciationMethodVersionMA AS DepreciationMethodVersionMA,
	|	Depreciation.DepreciationMethodVersionLA AS DepreciationMethodVersionLA,
	|
	|	Depreciation.Organization AS Organization,
	|	Depreciation.Department AS Department,
	|	Depreciation.IntangibleAsset AS IntangibleAsset,
	|
	|	ISNULL(IntangibleAssetsOperatingTime.OutputVolume, 0) AS OutputPerMonth,
	|	ISNULL(ManSAccountingProcedure.EstimatedRunningTime, LocalAccountingProcedure.EstimatedRunningTime) AS EstimatedRunningTime,
	|
	// Ma parameters
	|	Depreciation.DepreciationManagementAccounting AS DepreciationManagementAccounting,
	|
	|	Depreciation.ThisIsAdditionalChargeMA AS ThisIsAdditionalChargeMA,
	|	Depreciation.AccountingProcedureMA AS AccountingProcedureMA,
	|
	|	Depreciation.ResourceDevelopedOverPastPeriodMA AS ResourceDevelopedOverPastPeriodMA,
	|	Depreciation.ResourceDevelopedForCurPeriodMA AS ResourceDevelopedForCurPeriodMA,
	|	Depreciation.CostUsedToCalculateDepreciationInManagementAccounting AS CostUsedToCalculateDepreciationInManagementAccounting,
	|
	|	MaDepreciationParameters.DepreciationMethod AS DepreciationAccrualMethodManagementAccounting,
	|	InitialInformationMA.InitialCostMA AS InitialCostMA,
	|	MaDepreciationParameters.UsefulLifeMonths AS UsefulLifeOfMa,
	|	MaDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth AS ThePeriodOfUseForCalculatingTheDepreciationOfTheUU,
	|	MaDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS ScopeOfProductionWorksToCalculateMaDepreciation,
	|	MaDepreciationParameters.AccelerationFactor AS AccelerationFactorManagementAccounting,
	|
	|	CASE
	|		WHEN Depreciation.ThisIsAdditionalChargeMA
	|			THEN 0
	|		ELSE MaDepreciationParameters.ResidualValueMan
	|	END AS ResidualValueMan,
	|
	|	ISNULL(CostAtBeginningOfMonth.CostInManagementAccounting, 0) - ISNULL(DepreciationAtBeginningOfMonth.DepreciationManagementAccounting, 0) AS NetBookValueMan,
	|
	|	(YEAR(Depreciation.Period) - YEAR(BEGINOFPERIOD(InitialInformationMA.DateOfRecognitionManagementAccounting, MONTH))) * 12 
	|		+ MONTH(Depreciation.Period) - MONTH(BEGINOFPERIOD(InitialInformationMA.DateOfRecognitionManagementAccounting, MONTH)) AS ActualPeriodOfUseOfMa,
	|
	// BU Parameters
	|	Depreciation.DepreciationInAccounting AS DepreciationInAccounting,
	|	Depreciation.DepreciationPermanentDifferences AS DepreciationPermanentDifferences,
	|	Depreciation.DepreciationTD AS DepreciationTD,
	|
	|	Depreciation.ThisIsAdditionalChargeAccounting AS ThisIsAdditionalChargeAccounting,
	|	Depreciation.AccountingProcedureAC AS AccountingProcedureAC,
	|
	|	Depreciation.LifeSpentPastPeriodAccounting AS LifeSpentPastPeriodAccounting,
	|	Depreciation.LifeSpentCurrentPeriodAccounting AS LifeSpentCurrentPeriodAccounting,
	|	Depreciation.CostUsedToCalculateDepreciationInAccounting AS CostUsedToCalculateDepreciationInAccounting,
	|
	|	InitialInformationAC.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	InitialInformationAC.InitialCostLocalAccounting AS InitialCostLocalAccounting,
	|	ACDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
	|	ACDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth AS ThePeriodOfUseForCalculatingTheDepreciationOfTheBU,
	|	ACDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductionWorksForCalculatingDepreciationOfBU,
	|	ACDepreciationParameters.DepreciationAccrualFactor AS DepreciationAccrualFactor,
	|
	|	CASE
	|		WHEN Depreciation.ThisIsAdditionalChargeAccounting
	|			THEN 0
	|		ELSE ACDepreciationParameters.ResidualValueMan
	|	END AS ResidualValueLocal,
	|
	|	ISNULL(CostAtBeginningOfMonth.CostInAccounting, 0) - ISNULL(DepreciationAtBeginningOfMonth.DepreciationInAccounting, 0) AS ACResidualValue,
	|
	|	(YEAR(Depreciation.Period) - YEAR(BEGINOFPERIOD(InitialInformationAC.DateOfRecognitionAccounting, MONTH))) * 12 
	|		+ MONTH(Depreciation.Period) - MONTH(BEGINOFPERIOD(InitialInformationAC.DateOfRecognitionAccounting, MONTH)) AS ActualPeriodOfUseOfBU,
	|
	|	CASE
	|		WHEN YEAR(InitialInformationAC.DateOfRecognitionAccounting) <> YEAR(Depreciation.BegOfMonth)
	|			THEN 13 - MONTH(InitialInformationAC.DateOfRecognitionAccounting) + 12 * (YEAR(Depreciation.BegOfMonth) - YEAR(InitialInformationAC.DateOfRecognitionAccounting) - 1)
	|		ELSE 0
	|	END AS WorkedMonthsFullYears
	|
	|FROM
	|	TT_Depreciation AS Depreciation
	|
	|		LEFT JOIN Catalog.IntangibleAssets AS IntangibleAssets
	|		ON (IntangibleAssets.Ref = Depreciation.IntangibleAsset)
	|
	|		LEFT JOIN InitialInformationMA AS InitialInformationMA
	|		ON (InitialInformationMA.Period = Depreciation.Period)
	|			AND (InitialInformationMA.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (InitialInformationMA.Organization = Depreciation.Organization)
	|
	|		LEFT JOIN InitialInformationAC AS InitialInformationAC
	|		ON (InitialInformationAC.Period = Depreciation.Period)
	|			AND (InitialInformationAC.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (InitialInformationAC.Organization = Depreciation.Organization)
	|
	|		LEFT JOIN MaDepreciationParameters AS MaDepreciationParameters
	|		ON (MaDepreciationParameters.Period = Depreciation.Period)
	|			AND (MaDepreciationParameters.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (MaDepreciationParameters.Organization = Depreciation.Organization)
	|
	|		LEFT JOIN ACDepreciationParameters AS ACDepreciationParameters
	|		ON (ACDepreciationParameters.Period = Depreciation.Period)
	|			AND (ACDepreciationParameters.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (ACDepreciationParameters.Organization = Depreciation.Organization)
	|
	|		LEFT JOIN ManSAccountingProcedure AS ManSAccountingProcedure
	|		ON (ManSAccountingProcedure.Period = Depreciation.Period)
	|			AND (ManSAccountingProcedure.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (ManSAccountingProcedure.Organization = Depreciation.Organization)
	|
	|		LEFT JOIN LocalAccountingProcedure AS LocalAccountingProcedure
	|		ON (LocalAccountingProcedure.Period = Depreciation.Period)
	|			AND (LocalAccountingProcedure.IntangibleAsset = Depreciation.IntangibleAsset)
	|			AND (LocalAccountingProcedure.Organization = Depreciation.Organization)
	|
	|		LEFT JOIN IntangibleAssetsOperatingTime AS IntangibleAssetsOperatingTime
	|		ON (IntangibleAssetsOperatingTime.Period = Depreciation.BegOfMonth)
	|			AND (IntangibleAssetsOperatingTime.IntangibleAsset = Depreciation.IntangibleAsset)
	|
	|		LEFT JOIN VT_CostOfNMA_AtBeginningOfMonth AS CostAtBeginningOfMonth
	|		ON (CostAtBeginningOfMonth.Period = Depreciation.Period)
	|			AND (CostAtBeginningOfMonth.Organization = Depreciation.Organization)
	|			AND (CostAtBeginningOfMonth.IntangibleAsset = Depreciation.IntangibleAsset)
	|
	|		LEFT JOIN VT_DepreciationOfNMA_AtBeginningOfMonth AS DepreciationAtBeginningOfMonth
	|		ON (DepreciationAtBeginningOfMonth.Period = Depreciation.Period)
	|			AND (DepreciationAtBeginningOfMonth.Organization = Depreciation.Organization)
	|			AND (DepreciationAtBeginningOfMonth.IntangibleAsset = Depreciation.IntangibleAsset)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Var_DataCompositionSchema.DataSets.Depreciation.Query = QueryText;
	
EndProcedure

Procedure SetReportPeriod(Form, FormSettingsComposer)

	PeriodParameter = DataCompositionClientServer.GetParameter(FormSettingsComposer, "ReportPeriod"); 
	PeriodParameter = PeriodParameter.Value; // StandardPeriod - 
		
	If Form.Parameters.PurposeUseKey = "ReferenceCalculationAccordingToDocumentDepreciationIA" Then
		
		DepreciationCalculationDocument = TMReportsServer.FilterValue(
										"DepreciationCalculationDocument", 
										FormSettingsComposer.Settings.Filter.Items);
										
		If ValueIsFilled(DepreciationCalculationDocument) Then
			DocumentDate = Common.ObjectAttributeValue(DepreciationCalculationDocument[0], "Date");
			PeriodParameter.StartDate = BegOfMonth(DocumentDate);
			PeriodParameter.EndDate = EndOfMonth(DocumentDate);
		EndIf; 
		
	EndIf; 
	
EndProcedure

Procedure AddInformationalMessageToHeader(TabDoc, DataSelectionValues)

	IssuesList = New Array;
	
	CheckRelevanceOfDepreciationCalculation(DataSelectionValues, IssuesList);
	
	If IssuesList.Count() = 0 Then
		Return;
	EndIf; 
	
	IssuesList = TMCommonUse.DeleteDuplicateElementsFromArray(IssuesList);
	
	MessageText = StrConcat(IssuesList, Chars.LF);

	TabDoc.Area("R1C1").Text = MessageText;
	TabDoc.Area("R1C1").TextColor = Metadata.StyleItems.TextColorIssue.Value;
	TabDoc.Area(1, 1, 1, ).RowHeight = 0;
	
EndProcedure

Procedure CheckRelevanceOfDepreciationCalculation(DataSelectionValues, IssuesList)

	InformationRegisters.IntangibleAssetAmortizationPackages.CreateDepreciationPackages(DataSelectionValues.CompaniesList);
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentDepreciation.Organization.Presentation AS OrganizationPresentation
	|FROM
	|	Document.IntangibleAssetsAmortizationCharge2_4 AS DocumentDepreciation
	|		INNER JOIN InformationRegister.JobsForCalculatingIntangibleAssetAmortization AS JobsForCalculating
	|		ON (JobsForCalculating.Organization = DocumentDepreciation.Organization)
	|			AND (JobsForCalculating.Month <= DocumentDepreciation.Date)
	|		LEFT JOIN InformationRegister.IntangibleAssetAmortizationPackages AS IntangibleAssetAmortizationPackages
	|		ON IntangibleAssetAmortizationPackages.Organization = JobsForCalculating.Organization
	|			AND IntangibleAssetAmortizationPackages.PackageNumber = JobsForCalculating.PackageNumber
	|			AND &FilterAccordingToIAList
	|WHERE
	|	DocumentDepreciation.Organization IN(&CompaniesList)
	|	AND (NOT &FilterAccordingToIAList OR IntangibleAssetAmortizationPackages.IntangibleAsset IN(&ListOfIA))
	|	AND (NOT &FilterByDocument OR DocumentDepreciation.Ref IN(&DepreciationCalculationDocument))
	|	AND DocumentDepreciation.Posted
	|	AND (DocumentDepreciation.Date >= &BeginOfPeriod
	|			OR &BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (DocumentDepreciation.Date <= &PeriodEnding
	|			OR &PeriodEnding = DATETIME(1, 1, 1))";
	
	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", DataSelectionValues.CompaniesList);
	Query.SetParameter("BeginOfPeriod", DataSelectionValues.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", DataSelectionValues.PeriodEnding);
	Query.SetParameter("ListOfIA", DataSelectionValues.ListOfIA);
	Query.SetParameter("FilterAccordingToIAList", ValueIsFilled(DataSelectionValues.ListOfIA));
	Query.SetParameter("DepreciationCalculationDocument", DataSelectionValues.DepreciationCalculationDocument);
	Query.SetParameter("FilterByDocument", ValueIsFilled(DataSelectionValues.DepreciationCalculationDocument));
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf; 
	
	IssuesList.Add(NStr("vi = 'Tính toán khấu hao không liên quan:';
						|ru = 'Расчет амортизации не актуален:';
						|en = 'Amortization calculation is not relevant:'; fa = 'Amortization calculation is not relevant:';
						|it = 'Il calcolo dell''ammortamento è obsoleto:';
						|pl = 'Obliczanie amortyzacji jest nieaktualne:';
						|tr = 'Amortisman hesabı alakasız:'"));
	
	Selection = Result.Select();
	While Selection.Next() Do
		MessageText = NStr("vi = '- đối với doanh nghiệp ""%1"" cần hoàn thành việc đóng tháng';
							|ru = '- для организации ""%1"" необходимо выполнить закрытие месяца';
							|en = '- for the company ""%1"" you must perform a month-end closing'; fa = '- for the company ""%1"" you must perform a month-end closing';
							|it = '- per l''azienda ""%1"" è necessario effettuare la chiusura di fine periodo';
							|pl = '- dla firmy ""%1"" należy wykonać zamknięcie miesiąca';
							|tr = '- ""%1"" iş yeri için ay sonu kapanışı işleminin gerçekleştirilmesi gerekmektedir'");
		MessageText = StrTemplate(MessageText, Selection.OrganizationPresentation);
		IssuesList.Add(MessageText); 
	EndDo;
	
EndProcedure

#EndRegion

#EndIf 