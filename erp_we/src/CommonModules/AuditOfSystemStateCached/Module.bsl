// @strict-types

#Region Public

// Fill in the verification groups for registration.
// 
// Returns:
//  ValueTable - See AccountingAuditInternalCached.ChecksGroupsNewTable
Function FillInVerificationGroupsForRegistration() Export

	TableOfInspectionGroups = AuditOfSystemState.TableOfSystemStateCheckGroups();
	AuditOfSystemStateOverridable.FillInVerificationGroupsForRegistration(TableOfInspectionGroups);
	
	ChecksGroups = AccountingAuditInternalCached.ChecksGroupsNewTable().CopyColumns();
	
	For Each CurrRow In TableOfInspectionGroups Do
		
		NwRw = ChecksGroups.Add();
		FillPropertyValues(NwRw, CurrRow);
		
		NwRw.GroupID = CurrRow.ParentID;
		
	EndDo;
	
	Return ChecksGroups;
	
EndFunction

// Fill out the checks for registration.
// 
// Returns:
//  ValueTable - See AccountingAuditInternalCached.NewChecksTable
Function FillOutChecksForRegistration() Export

	TableOfChecks = AuditOfSystemState.SystemStateCheckTable();
	AuditOfSystemStateOverridable.FillOutChecksForRegistration(TableOfChecks);
	
	Checks = AccountingAuditInternalCached.NewChecksTable().CopyColumns();
	Checks.Columns.Add("ExecutedOnlyInContext", New TypeDescription("Boolean"));
	Checks.Columns.Add("IssueSeverity",  New TypeDescription("EnumRef.AccountingIssueSeverity"));
	Checks.Columns.Add("Use",  New TypeDescription("Boolean"));
	Checks.Columns.Add("RunMethod",  New TypeDescription("EnumRef.CheckMethod"));
	Checks.Columns.Add("Handler",  New TypeDescription("String"));
	Checks.Columns.Add("DetailsByCompany",  New TypeDescription("Boolean"));
	Checks.Columns.Add("DetailsByPeriod",  New TypeDescription("Boolean"));
	Checks.Columns.Add("SourceHandler",  New TypeDescription("String"));
	
	If Common.SeparatedDataUsageAvailable() Then
		IssuesLimit = MonthEndTransactionsServer.NumberOfRegisteredErrorsOfSameType();
	Else
		IssuesLimit = 100; // default value
	EndIf;
	
	UniversalHandler = "AuditOfSystemState.UniversalHandlerForMonthClosingChecks";
	
	For Each CurrRow In TableOfChecks Do
		
		NwRw = Checks.Add();
		FillPropertyValues(NwRw, CurrRow);
		
		NwRw.GroupID = CurrRow.ParentID;
		
		NwRw.NoCheckHandler = IsBlankString(CurrRow.Handler);
		NwRw.SourceHandler = CurrRow.Handler;
		NwRw.HandlerChecks = ?(NwRw.NoCheckHandler, "", UniversalHandler);
		NwRw.Handler = ?(NwRw.NoCheckHandler, "", UniversalHandler);
		NwRw.ImportanceChangeDenied = Not CurrRow.CanEditImportance;
		NwRw.ParentID = "";
		
		NwRw.IssueSeverity   = CurrRow.IssueSeverity;
		NwRw.CheckStartDate = CurrRow.CheckStartDate;
		NwRw.Use 	= True;
		NwRw.RunMethod = Enums.CheckMethod.DuringEstimation;
		NwRw.IssuesLimit 	= IssuesLimit;
		
	EndDo;
	
	Return Checks;
	
EndFunction

#EndRegion

#Region Internal

// Code of procedures and functions

#EndRegion

#Region Private

// Code of procedures and functions

#EndRegion
