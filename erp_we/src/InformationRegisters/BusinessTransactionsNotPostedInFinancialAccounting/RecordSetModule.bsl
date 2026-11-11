#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// If a business transaction is excluded from the accounting policy,
	// then it is necessary to exclude from the accounting policy all transaction templates
	// related to this business transaction.
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BusinessTransactions.PostingGenerationSetting AS PostingGenerationSetting,
	|	BusinessTransactions.Operation AS Operation
	|INTO BusinessTransactions
	|FROM 
	|	&BusinessTransactions AS BusinessTransactions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	AccountingRules.PostingGenerationSetting AS PostingGenerationSetting,
	|	AccountingRules.PostingTemplate AS PostingTemplate
	|FROM
	|	BusinessTransactions AS BusinessTransactions
	|	INNER JOIN
	|		InformationRegister.RulesOfPostingsInFinancialAccounting AS AccountingRules
	|	ON
	|		BusinessTransactions.PostingGenerationSetting = AccountingRules.PostingGenerationSetting
	|		AND BusinessTransactions.Operation = AccountingRules.PostingTemplate.Operation
	|";
	
	Query.SetParameter("BusinessTransactions", ThisObject.Unload());
	
	Selection = Query.Execute().Select();
	
	RecordSet = InformationRegisters.RulesOfPostingsInFinancialAccounting.CreateRecordSet();
	
	While Selection.Next() Do
		RecordSet.Filter.PostingGenerationSetting.Set(Selection.PostingGenerationSetting);
		RecordSet.Filter.PostingTemplate.Set(Selection.PostingTemplate);
		RecordSet.Write();
	EndDo;
	
EndProcedure

#EndRegion

#EndIf