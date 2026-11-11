
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Organization = Parameters.Organization;
	AccountToClose = Parameters.BankAccount;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SetDifferentAccountAsMainAccountOnChange(Item)
	EstablishAvailabilityOfMainBankAccount();
EndProcedure

&AtClient
Procedure CloseAccountOnChange(Item)
	EstablishAvailabilityOfMainBankAccount();
EndProcedure

&AtClient
Procedure ClearMainAccountOnChange(Item)
	EstablishAvailabilityOfMainBankAccount();
EndProcedure

&AtClient
Procedure MainBankAccountAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	StandardProcessing = False;
	ChoiceData = BankAccountsToChooseFrom(Organization, AccountToClose, Text);
EndProcedure

&AtClient
Procedure MainBankAccountStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	ChoiceData = BankAccountsToChooseFrom(Organization, AccountToClose);
EndProcedure

&AtClient
Procedure MainBankAccountTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	StandardProcessing = False;
	ChoiceData = BankAccountsToChooseFrom(Organization, AccountToClose, Text);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	ClearMessages();
	
	BankAccount = Undefined;
	If ActionWithMainAccount = 0 Then // Set A Different Account As The Main Account
		If ValueIsFilled(MainBankAccount) Then
			BankAccount = MainBankAccount;
		Else
			FieldTitle = Items.MainBankAccount.Title;
			MessageText = CommonClientServer.FillingErrorText(, , FieldTitle);
			CommonClient.MessageToUser(MessageText, , Items.MainBankAccount.Name);
			Return;
		EndIf;
	ElsIf ActionWithMainAccount = 1 Then // Clear the Main Account
		BankAccount = PredefinedValue("Catalog.CompaniesBankAccounts.EmptyRef");
	EndIf;
	
	If BankAccount <> Undefined Then
		SetUpPrimaryBankAccount(Organization, BankAccount);
		Notify("Write_Companies", BankAccount, Organization);
	EndIf;
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure EstablishAvailabilityOfMainBankAccount()
	
	AccountIsAvailable = ActionWithMainAccount = 0;
	Items.MainBankAccount.AutoMarkIncomplete = AccountIsAvailable;
	Items.MainBankAccount.Enabled = AccountIsAvailable;
	
EndProcedure

&AtServerNoContext
Procedure SetUpPrimaryBankAccount(Val Organization, Val BankAccount)
	
	Catalogs.Companies.SetUpPrimaryBankAccount(Organization, BankAccount);
	
EndProcedure

&AtServerNoContext
Function BankAccountsToChooseFrom(Val Organization, Val AccountToClose, Val SearchString = "")
	
	Query = New Query;
	Query.SetParameter("Owner", Organization);
	Query.SetParameter("Ref", AccountToClose);
	Query.Text =
	"SELECT ALLOWED
	|	Data.Ref AS Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS Data
	|WHERE
	|	Data.Owner = &Owner
	|	AND Data.Ref <> &Ref
	|	AND NOT Data.DeletionMark
	|	AND NOT Data.Closed
	|	AND &SearchCriteria_
	|
	|ORDER BY
	|	Data.Description
	|AUTOORDER";
	
	If IsBlankString(SearchString) Then
		SearchCriteria_ = "TRUE";
	Else
		SearchCriteria_ = "Data.Description LIKE &SearchString";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&SearchCriteria_", SearchCriteria_);
	Query.SetParameter("SearchString", SearchString + "%");
	
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
	Return ChoiceData;
	
EndFunction

#EndRegion
