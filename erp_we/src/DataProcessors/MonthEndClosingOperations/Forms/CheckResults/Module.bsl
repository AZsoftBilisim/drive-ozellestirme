#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Title = NStr("vi = 'Kết quả kế toán tình trạng';
				|ru = 'Результаты проверки состояния учета';
				|en = 'Month-end checklists'; fa = 'Month-end checklists';
				|it = 'I risultati del controllo di stato della contabilità';
				|pl = 'Wyniki kontroli statusu rachunkowości';
				|tr = 'Ay sonu onay listeleri sonucu'", Common.DefaultLanguageCode());
	
	VerificationParameters = Parameters.VerificationParameters;
	
	CompanyArray = New Array;
	CheckedPeriod = Date(1,1,1);
	Validation = Undefined;
	AccountingChecksContext = Undefined;
	IssueText = "";
	
	If TypeOf(VerificationParameters) = Type("Structure") Then

		If ValueIsFilled(VerificationParameters.CompanyArray) Then
			CompanyArray = VerificationParameters.CompanyArray;
		EndIf;
		If ValueIsFilled(VerificationParameters.CheckedPeriod) Then
			CheckedPeriod = VerificationParameters.CheckedPeriod;
		EndIf;
		If ValueIsFilled(VerificationParameters.Validation) Then
			Validation = VerificationParameters.Validation;
		EndIf;
		If ValueIsFilled(VerificationParameters.AccountingChecksContext) Then
			AccountingChecksContext = VerificationParameters.AccountingChecksContext;
		EndIf;
		
		IssueText = Parameters.IssueText;
		CalloutPosition = StrFind(IssueText, "(", SearchDirection.FromEnd);
		
		If CalloutPosition > 0 Then
			IssueText = TrimAll(Left(IssueText, CalloutPosition - 1)); 
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"ReadMoreText",
		MonthEndTransactionsServer.DefaultDetailsText());
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"CompanyArray",
		CompanyArray);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"CheckedPeriod",
		CheckedPeriod);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"Validation",
		Validation);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"AccountingChecksContext",
		AccountingChecksContext);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"IssueText",
		IssueText);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "UpdatingResultsOfInspectionsInFormOfClosingMonth" Then
		Return;
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	If Items.List.CurrentData = Undefined Then
		VerificationDescription = "";
	Else
		VerificationDescription = TrimAll(Items.List.CurrentData.VerificationDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.MoreDetails And Not CurrentData.ThisIsACompositeObject And ValueIsFilled(CurrentData.Object) Then
		DisplayedValue_ = CurrentData.Object;
	ElsIf Not CurrentData.ThereIsARecordOfTheObjectRegister Then
		DisplayedValue_ = GenerateSystemStateRegisterEntryKey(CurrentData);
	Else
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ShowValue(, DisplayedValue_);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GenerateSystemStateRegisterEntryKey(CurrentData)
	
	//@skip-check structure-consructor-too-many-keys
	Filter = New Structure("Validation, Organization, CheckedPeriod, Issue1");
	FillPropertyValues(Filter, CurrentData);
	
	RecordKey = InformationRegisters.SystemStatusIssues.CreateRecordKey(Filter);
	
	Return RecordKey;
	
EndFunction
	
#EndRegion
