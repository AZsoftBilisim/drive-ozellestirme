
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// @skip-check data-exchange-load
Procedure BeforeWrite(Cancel)
	
	// Checking the value of the property is deceptive.There is no loading due to the fact that the code below
	// implements logic that must be executed, including when setting this property to True
	// (on the side of the code that attempts to write to this exchange plan).
	
	If IsNew() Then
		If Not SummaryApplicationExport And Not SummaryApplicationImport Then
			SetFlagForUsingMigration(True);
		ElsIf SummaryApplicationExport Then 	
			SetWhetherToUseUploadingDataToSummaryApplication(True);
		EndIf;
	EndIf;
	
EndProcedure

// @skip-check data-exchange-load
Procedure BeforeDelete(Cancel)
	
	// Checking the value of the property is deceptive.There is no loading due to the fact that the code below
	// implements logic that must be executed, including when setting this property to True
	// (on the side of the code that attempts to write to this exchange plan).
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Ref);
	SetPrivilegedMode(False);
	
	If Not SummaryApplicationExport And Not SummaryApplicationImport Then
		
		Query = New Query;
		Query.SetParameter("Separator", DataAreaMainData);
		Query.SetParameter("Ref", Ref);
		Query.Text =
		"SELECT TOP 1
		|	TRUE AS Validation
		|FROM
		|	ExchangePlan.ApplicationsMigration AS ApplicationsMigration
		|WHERE
		|	NOT ApplicationsMigration.ThisNode
		|	AND ApplicationsMigration.DataAreaMainData = &Separator
		|	AND ApplicationsMigration.Ref <> &Ref
		|	AND NOT ApplicationsMigration.SummaryApplicationExport
		|	AND NOT ApplicationsMigration.SummaryApplicationImport";
		Use = Not Query.Execute().IsEmpty();
		
		SetFlagForUsingMigration(Use);
		
	ElsIf SummaryApplicationExport Then
		
		Query = New Query;
		Query.SetParameter("Separator", DataAreaMainData);
		Query.SetParameter("Ref", Ref);
		Query.Text =
		"SELECT TOP 1
		|	TRUE AS Validation
		|FROM
		|	ExchangePlan.ApplicationsMigration AS ApplicationsMigration
		|WHERE
		|	NOT ApplicationsMigration.ThisNode
		|	AND ApplicationsMigration.DataAreaMainData = &Separator
		|	AND ApplicationsMigration.Ref <> &Ref
		|	AND ApplicationsMigration.SummaryApplicationExport";
		Use = Not Query.Execute().IsEmpty();
		
		SetWhetherToUseUploadingDataToSummaryApplication(Use);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetFlagForUsingMigration(Use)
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Constant.ApplicationsMigrationUsed");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		ValueManager = Constants.ApplicationsMigrationUsed.CreateValueManager();
		ValueManager.DataAreaAuxiliaryData = DataAreaMainData;
		ValueManager.Read();
		If Not ValueManager.Value = Use Then
			ValueManager.Value = Use;
			ValueManager.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure SetWhetherToUseUploadingDataToSummaryApplication(Use)

	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Constant.UseExportToSummaryApplication");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		ValueManager = Constants.UseExportToSummaryApplication.CreateValueManager();
		ValueManager.Read();
		If Not ValueManager.Value = Use Then
			ValueManager.Value = Use;
			ValueManager.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndIf