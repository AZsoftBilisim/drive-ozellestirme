#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	PrepareDataForGeneratingTasksBeforeRecording();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PrepareDataForGeneratingTasksWhenRecording();
		
EndProcedure

#EndRegion

#Region Private

Procedure PrepareDataForGeneratingTasksBeforeRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Period AS Period,
	|	TableBeforeWrite.Organization AS Organization,
	|	TableBeforeWrite.FixedAsset AS FixedAsset,
	|	TableBeforeWrite.BUState AS BUState,
	|	TableBeforeWrite.StateTa AS StateTa,
	|	TableBeforeWrite.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|	TableBeforeWrite.DepreciationAccrualTaxAccounting AS DepreciationAccrualTaxAccounting,
	|	TableBeforeWrite.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	TableBeforeWrite.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	TableBeforeWrite.DepartmentACC AS DepartmentACC,
	|	TableBeforeWrite.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	TableBeforeWrite.ExpenseItemTaxAccounting AS ExpenseItemTaxAccounting,
	|	TableBeforeWrite.ExpensesDimensionTaxAccounting AS ExpensesDimensionTaxAccounting,
	|	TableBeforeWrite.BusinessUnitTaxAccounting AS BusinessUnitTaxAccounting,
	|	TableBeforeWrite.LineOfBusinessTaxAccounting AS LineOfBusinessTaxAccounting,
	|	TableBeforeWrite.ExpenseItemOfDepreciationAllowance AS ExpenseItemOfDepreciationAllowance,
	|	TableBeforeWrite.DepreciationAllowanceExpensesDimension AS DepreciationAllowanceExpensesDimension,
	|	TableBeforeWrite.BusinessUnitBonusDepreciation AS BusinessUnitBonusDepreciation,
	|	TableBeforeWrite.LineOfBusinessBonusDepreciation AS LineOfBusinessBonusDepreciation,
	|	TableBeforeWrite.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	TableBeforeWrite.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	TableBeforeWrite.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
	|	TableBeforeWrite.DepreciationRecordMethodTA AS DepreciationRecordMethodTA,
	|	TableBeforeWrite.BonusDepreciationRecordMethod AS BonusDepreciationRecordMethod,
	|	TableBeforeWrite.DepreciationGroup AS DepreciationGroup,
	|	TableBeforeWrite.RealEstate AS RealEstate
	|
	|INTO AccountingProcedureForOSBUBeforeWrite
	|
	|FROM
	|	InformationRegister.AccountingProcedureForOSBU AS TableBeforeWrite
	|
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|	AND TableBeforeWrite.CorrectionDate = DATETIME(1,1,1)";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure PrepareDataForGeneratingTasksWhenRecording()
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	Table.Period           AS Period,
	|	Table.Organization      AS Organization,
	|	Table.FixedAsset AS FixedAsset,
	|	TRUE                   AS RecordInLocalAccounting,
	|	FALSE                     AS RecordInManAccounting,
	|	&Recorder             AS Document
	|
	|INTO AccountingProcedureForOSBUUpdate
	|
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period            AS Period,
	|		TableBeforeWrite.Organization       AS Organization,
	|		TableBeforeWrite.FixedAsset  AS FixedAsset
	|	FROM
	|		AccountingProcedureForOSBUBeforeWrite AS TableBeforeWrite
	|
	|			LEFT JOIN InformationRegister.AccountingProcedureForOSBU AS TableWhenWriting
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|				AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
	|				OR TableWhenWriting.BUState <> TableBeforeWrite.BUState
	|				OR TableWhenWriting.StateTa <> TableBeforeWrite.StateTa
	|				OR TableWhenWriting.DepreciationAccrualAccounting <> TableBeforeWrite.DepreciationAccrualAccounting
	|				OR TableWhenWriting.DepreciationAccrualTaxAccounting <> TableBeforeWrite.DepreciationAccrualTaxAccounting
	|				OR TableWhenWriting.ExpenseItemAccounting <> TableBeforeWrite.ExpenseItemAccounting
	|				OR TableWhenWriting.ExpensesDimensionAccounting <> TableBeforeWrite.ExpensesDimensionAccounting
	|				OR TableWhenWriting.DepartmentACC <> TableBeforeWrite.DepartmentACC
	|				OR TableWhenWriting.LineOfBusinessBookkeeping <> TableBeforeWrite.LineOfBusinessBookkeeping
	|				OR TableWhenWriting.ExpenseItemTaxAccounting <> TableBeforeWrite.ExpenseItemTaxAccounting
	|				OR TableWhenWriting.ExpensesDimensionTaxAccounting <> TableBeforeWrite.ExpensesDimensionTaxAccounting
	|				OR TableWhenWriting.BusinessUnitTaxAccounting <> TableBeforeWrite.BusinessUnitTaxAccounting
	|				OR TableWhenWriting.LineOfBusinessTaxAccounting <> TableBeforeWrite.LineOfBusinessTaxAccounting
	|				OR TableWhenWriting.ExpenseItemOfDepreciationAllowance <> TableBeforeWrite.ExpenseItemOfDepreciationAllowance
	|				OR TableWhenWriting.DepreciationAllowanceExpensesDimension <> TableBeforeWrite.DepreciationAllowanceExpensesDimension
	|				OR TableWhenWriting.BusinessUnitBonusDepreciation <> TableBeforeWrite.BusinessUnitBonusDepreciation
	|				OR TableWhenWriting.LineOfBusinessBonusDepreciation <> TableBeforeWrite.LineOfBusinessBonusDepreciation
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses
	|				OR TableWhenWriting.DepreciationRecordMethodLA <> TableBeforeWrite.DepreciationRecordMethodLA
	|				OR TableWhenWriting.DepreciationRecordMethodTA <> TableBeforeWrite.DepreciationRecordMethodTA
	|				OR TableWhenWriting.BonusDepreciationRecordMethod <> TableBeforeWrite.BonusDepreciationRecordMethod
	|				OR TableWhenWriting.DepreciationGroup <> TableBeforeWrite.DepreciationGroup
	|				OR TableWhenWriting.RealEstate <> TableBeforeWrite.RealEstate
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.FixedAsset
	|	FROM
	|		InformationRegister.AccountingProcedureForOSBU AS TableWhenWriting
	|
	|			LEFT JOIN AccountingProcedureForOSBUBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.FixedAsset = TableBeforeWrite.FixedAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
	|				OR TableWhenWriting.BUState <> TableBeforeWrite.BUState
	|				OR TableWhenWriting.StateTa <> TableBeforeWrite.StateTa
	|				OR TableWhenWriting.DepreciationAccrualAccounting <> TableBeforeWrite.DepreciationAccrualAccounting
	|				OR TableWhenWriting.DepreciationAccrualTaxAccounting <> TableBeforeWrite.DepreciationAccrualTaxAccounting
	|				OR TableWhenWriting.ExpenseItemAccounting <> TableBeforeWrite.ExpenseItemAccounting
	|				OR TableWhenWriting.ExpensesDimensionAccounting <> TableBeforeWrite.ExpensesDimensionAccounting
	|				OR TableWhenWriting.DepartmentACC <> TableBeforeWrite.DepartmentACC
	|				OR TableWhenWriting.LineOfBusinessBookkeeping <> TableBeforeWrite.LineOfBusinessBookkeeping
	|				OR TableWhenWriting.ExpenseItemTaxAccounting <> TableBeforeWrite.ExpenseItemTaxAccounting
	|				OR TableWhenWriting.ExpensesDimensionTaxAccounting <> TableBeforeWrite.ExpensesDimensionTaxAccounting
	|				OR TableWhenWriting.BusinessUnitTaxAccounting <> TableBeforeWrite.BusinessUnitTaxAccounting
	|				OR TableWhenWriting.LineOfBusinessTaxAccounting <> TableBeforeWrite.LineOfBusinessTaxAccounting
	|				OR TableWhenWriting.ExpenseItemOfDepreciationAllowance <> TableBeforeWrite.ExpenseItemOfDepreciationAllowance
	|				OR TableWhenWriting.DepreciationAllowanceExpensesDimension <> TableBeforeWrite.DepreciationAllowanceExpensesDimension
	|				OR TableWhenWriting.BusinessUnitBonusDepreciation <> TableBeforeWrite.BusinessUnitBonusDepreciation
	|				OR TableWhenWriting.LineOfBusinessBonusDepreciation <> TableBeforeWrite.LineOfBusinessBonusDepreciation
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses
	|				OR TableWhenWriting.DepreciationRecordMethodLA <> TableBeforeWrite.DepreciationRecordMethodLA
	|				OR TableWhenWriting.DepreciationRecordMethodTA <> TableBeforeWrite.DepreciationRecordMethodTA
	|				OR TableWhenWriting.BonusDepreciationRecordMethod <> TableBeforeWrite.BonusDepreciationRecordMethod
	|				OR TableWhenWriting.DepreciationGroup <> TableBeforeWrite.DepreciationGroup
	|				OR TableWhenWriting.RealEstate <> TableBeforeWrite.RealEstate
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|			AND TableWhenWriting.Recorder = &Recorder
	|			AND TableWhenWriting.CorrectionDate = DATETIME(1,1,1)
	|
	|	) AS Table
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP AccountingProcedureForOSBUBeforeWrite
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"AccountingProcedureForOSBUUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
