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
	|	TableBeforeWrite.IntangibleAsset AS IntangibleAsset,
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
	|	TableBeforeWrite.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	TableBeforeWrite.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	TableBeforeWrite.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
	|	TableBeforeWrite.DepreciationRecordMethodTA AS DepreciationRecordMethodTA
	|
	|INTO IABookkeepingProcedureBookkeepingAndTaxAccountingBeforeWrite
	|
	|FROM
	|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Recorder = &Recorder
	|";
	
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
	|	Table.Period              AS Period,
	|	Table.Organization         AS Organization,
	|	Table.IntangibleAsset AS IntangibleAsset,
	|	TRUE                      AS RecordInLocalAccounting,
	|	FALSE                        AS RecordInManAccounting,
	|	&Recorder                AS Document
	|
	|INTO IABookkeepingProcedureBookkeepingAndTaxAccountingUpdate
	|
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period               AS Period,
	|		TableBeforeWrite.Organization          AS Organization,
	|		TableBeforeWrite.IntangibleAsset  AS IntangibleAsset
	|	FROM
	|		IABookkeepingProcedureBookkeepingAndTaxAccountingBeforeWrite AS TableBeforeWrite
	|
	|			LEFT JOIN InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS TableWhenWriting
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|				AND TableWhenWriting.Recorder = &Recorder
	|		WHERE
	|			(TableWhenWriting.Period IS NULL
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
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses
	|				OR TableWhenWriting.DepreciationRecordMethodLA <> TableBeforeWrite.DepreciationRecordMethodLA
	|				OR TableWhenWriting.DepreciationRecordMethodTA <> TableBeforeWrite.DepreciationRecordMethodTA
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Period,
	|		TableWhenWriting.Organization,
	|		TableWhenWriting.IntangibleAsset
	|	FROM
	|		InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting AS TableWhenWriting
	|
	|			LEFT JOIN IABookkeepingProcedureBookkeepingAndTaxAccountingBeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.IntangibleAsset = TableBeforeWrite.IntangibleAsset
	|				AND TableWhenWriting.Organization = TableBeforeWrite.Organization
	|		WHERE
	|			(TableBeforeWrite.Period IS NULL
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
	|				OR TableWhenWriting.TransferExpensesToAnotherCompany <> TableBeforeWrite.TransferExpensesToAnotherCompany
	|				OR TableWhenWriting.CompanyRecipientOfExpenses <> TableBeforeWrite.CompanyRecipientOfExpenses
	|				OR TableWhenWriting.DepreciationRecordMethodLA <> TableBeforeWrite.DepreciationRecordMethodLA
	|				OR TableWhenWriting.DepreciationRecordMethodTA <> TableBeforeWrite.DepreciationRecordMethodTA
	|				OR BEGINOFPERIOD(TableWhenWriting.Period, MONTH) <> BEGINOFPERIOD(TableBeforeWrite.Period, MONTH))
	|			AND TableWhenWriting.Recorder = &Recorder
	|
	|	) AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP IABookkeepingProcedureBookkeepingAndTaxAccountingBeforeWrite
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Selection = Query.ExecuteBatch()[0].Select();
	DocumentsPosting.RegisterControlTable(AdditionalProperties,
		"IABookkeepingProcedureBookkeepingAndTaxAccountingUpdate", Selection.Next() And Selection.Count > 0);
	
EndProcedure

#EndRegion

#EndIf
