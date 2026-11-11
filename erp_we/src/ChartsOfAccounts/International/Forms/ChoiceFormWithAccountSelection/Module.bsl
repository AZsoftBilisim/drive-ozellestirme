
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	Organization = Parameters.Organization;
	RecordType = Parameters.RecordType;
	Account = Parameters.Account;
	
	Items.AccountingByLinesOfBusiness.Visible = Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed();
	FillInUsedInvoices();
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "ChartOfAccounts", ChartOfAccounts, , , , DataCompositionSettingsItemViewMode.Inaccessible);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region TableEventHandlersList 

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Item.RowData(Value).RestrictUseInPostings Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region TableEventHandlersUsedAccounts

&AtClient
Procedure UsedAccountsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.UsedAccountsDocument Then
		StandardProcessing = False;
		ShowValue(, Item.CurrentData.Document);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedAccountsValueChoice(Item, Value, StandardProcessing)
	
	NotifyChoice(Item.CurrentData.Account);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure FillInUsedInvoices()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(DocumentReflection.Recorder) AS Document,
	|	CASE
	|		WHEN &RecordType = VALUE(Enum.AccountingMovementKinds.Debit)
	|			THEN AccountingRegister.AccountDr
	|		ELSE AccountingRegister.AccountCr
	|	END AS Account
	|INTO TableOfAccounts
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|	INNER JOIN
	|		AccountingRegister.International AS AccountingRegister
	|	ON
	|		DocumentReflection.Recorder = AccountingRegister.Recorder
	|WHERE
	|	DocumentReflection.ChartOfAccounts = &ChartOfAccounts
	|	AND DocumentReflection.Organization = &Organization
	|	AND DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting)
	|	AND ((&RecordType = VALUE(Enum.AccountingMovementKinds.Debit) AND AccountingRegister.AccountCr = &Account)
	|		OR (&RecordType = VALUE(Enum.AccountingMovementKinds.Credit) AND AccountingRegister.AccountDr = &Account))
	|GROUP BY
	|	CASE
	|		WHEN &RecordType = VALUE(Enum.AccountingMovementKinds.Debit)
	|			THEN AccountingRegister.AccountDr
	|		ELSE AccountingRegister.AccountCr
	|	END
	|	
	|UNION ALL
	|
	|SELECT
	|	MAX(DocumentReflection.Recorder) AS Document,
	|	AccountingRegister.Account AS Account
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|	INNER JOIN
	|		AccountingRegister.InternationalWithoutCorrespondence AS AccountingRegister
	|	ON
	|		DocumentReflection.Recorder = AccountingRegister.Recorder
	|WHERE
	|	DocumentReflection.ChartOfAccounts = &ChartOfAccounts
	|	AND DocumentReflection.Organization = &Organization
	|	AND DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting)
	|	AND AccountingRegister.Account = &Account 
	|GROUP BY
	|	AccountingRegister.Account
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAccounts.Document AS Document,
	|	TableOfAccounts.Account AS Account
	|FROM
	|	TableOfAccounts AS TableOfAccounts
	|	INNER JOIN
	|		ChartOfAccounts.International AS International
	|	ON
	|		NOT International.RestrictUseInPostings
	|		AND TableOfAccounts.Account = International.Ref
	|		AND International.ChartOfAccounts = &ChartOfAccounts
	|";
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("RecordType", RecordType);
	Query.SetParameter("Account", Account);
	UsedAccounts.Load(Query.Execute().Unload());
	NumberOfUsedAccounts = UsedAccounts.Count();

EndProcedure

#EndRegion
